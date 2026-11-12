import Foundation

/// Owns the backend child process and its anonymous stdio pipes.
///
/// Expected signed bundle layout:
/// - Contents/Helpers/AtheerNodeRuntime/bin/node
/// - Contents/Resources/Backend/dist/server.js
///
/// The runtime is resolved only from the app bundle. PATH lookup and shell
/// invocation are deliberately prohibited. Keychain credentials are encrypted
/// with a per-process ephemeral key before crossing the supervised IPC pipe.
final class BackendProcessSupervisor {
    static let shared = BackendProcessSupervisor()

    typealias Completion = (Result<[String: Any], Error>) -> Void
    typealias StartCompletion = (Result<Void, Error>) -> Void

    private struct PendingRequest {
        let completion: Completion
        let timeout: DispatchWorkItem
    }

    private let queue = DispatchQueue(label: "com.atheertrading.backend-ipc")
    private var process: Process?
    private var inputPipe: Pipe?
    private var outputPipe: Pipe?
    private var errorPipe: Pipe?
    private var decoder = LocalIPCFrameDecoder()
    private var pending: [String: PendingRequest] = [:]
    private var startCompletions: [StartCompletion] = []
    private var isReady = false
    private var isStopping = false
    private var secretChannel: IPCSecretChannel?

    func start(completion: @escaping StartCompletion) {
        queue.async {
            if self.isReady {
                completion(.success(()))
                return
            }

            self.startCompletions.append(completion)
            guard self.process == nil else { return }
            self.launchChild()
        }
    }

    func request(
        method: String,
        payload: [String: Any] = [:],
        timeout: TimeInterval = 10,
        completion: @escaping Completion
    ) {
        queue.async {
            guard self.isReady, self.process?.isRunning == true else {
                completion(.failure(LocalIPCError.processNotReady))
                return
            }

            self.send(
                method: method,
                payload: payload,
                timeout: timeout,
                completion: completion
            )
        }
    }

    func stop() {
        queue.async {
            self.terminateChild(with: LocalIPCError.processTerminated)
        }
    }

    /// Loads credentials from Keychain, encrypts them with the per-process
    /// X25519/AES-GCM channel, and requests a read-only Capital.com Demo session.
    func connectCapitalCom(completion: @escaping Completion) {
        let credentials: CapitalComCredentials
        do {
            guard let saved = try CapitalComCredentialStore.load() else {
                completion(.failure(LocalIPCError.credentialsNotFound))
                return
            }
            credentials = saved
        } catch {
            completion(.failure(error))
            return
        }

        start { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.queue.async {
                    guard let channel = self.secretChannel else {
                        completion(.failure(LocalIPCError.handshakeRejected))
                        return
                    }

                    do {
                        var plaintext = try JSONEncoder().encode(credentials)
                        defer { plaintext.resetBytes(in: 0..<plaintext.count) }
                        let envelope = try channel.encrypt(plaintext)
                        self.send(
                            method: "broker.credentials.submit",
                            payload: ["envelope": envelope],
                            timeout: 10
                        ) { submitResult in
                            switch submitResult {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success:
                                self.send(
                                    method: "broker.connect",
                                    payload: ["environment": "demo"],
                                    timeout: 30
                                ) { connectResult in
                                    if case .failure(let error) = connectResult {
                                        completion(.failure(error))
                                        self.stop()
                                    } else {
                                        completion(connectResult)
                                    }
                                }
                            }
                        }
                    } catch {
                        completion(.failure(error))
                    }
                }
            }
        }
    }

    func disconnectCapitalCom(completion: @escaping Completion) {
        request(method: "broker.disconnect", payload: [:], timeout: 10) { result in
            completion(result)
            self.stop()
        }
    }

    func capitalComStatus(completion: @escaping Completion) {
        start { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success:
                self.request(method: "broker.status", payload: [:], timeout: 10, completion: completion)
            }
        }
    }

    func getCapitalComHistoricalPrices(
        epic: String,
        resolution: String = "MINUTE",
        max: Int = 100,
        completion: @escaping Completion
    ) {
        request(
            method: "broker.historicalPrices",
            payload: ["epic": epic, "resolution": resolution, "max": max],
            timeout: 20,
            completion: completion
        )
    }

    func searchCapitalComMarkets(
        _ searchTerm: String,
        completion: @escaping Completion
    ) {
        request(
            method: "broker.marketSearch",
            payload: ["searchTerm": searchTerm],
            timeout: 20,
            completion: completion
        )
    }

    private func launchChild() {
        let resources = Bundle.main.bundleURL
            .appendingPathComponent("Contents", isDirectory: true)

        let nodeURL = resources
            .appendingPathComponent("Helpers/AtheerNodeRuntime/bin/node")
        let backendURL = resources
            .appendingPathComponent("Resources/Backend/dist/server.js")

        guard FileManager.default.isExecutableFile(atPath: nodeURL.path) else {
            finishStart(.failure(LocalIPCError.runtimeNotBundled))
            return
        }

        guard FileManager.default.fileExists(atPath: backendURL.path) else {
            finishStart(.failure(LocalIPCError.backendNotBundled))
            return
        }

        let child = Process()
        let childInput = Pipe()
        let childOutput = Pipe()
        let childError = Pipe()

        child.executableURL = nodeURL
        child.arguments = [backendURL.path, "--transport=stdio"]
        child.environment = ["NODE_ENV": "production"]
        child.currentDirectoryURL = backendURL.deletingLastPathComponent()
        child.standardInput = childInput
        child.standardOutput = childOutput
        child.standardError = childError

        process = child
        inputPipe = childInput
        outputPipe = childOutput
        errorPipe = childError
        decoder.reset()
        let channel = IPCSecretChannel()
        secretChannel = channel

        childOutput.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                self?.queue.async {
                    self?.handleOutputClosed(for: child)
                }
                return
            }

            self?.queue.async {
                self?.consume(data, from: child)
            }
        }

        // Drain stderr to prevent the child from blocking. Diagnostics are
        // intentionally discarded until a separately reviewed redaction policy exists.
        childError.fileHandleForReading.readabilityHandler = { handle in
            if handle.availableData.isEmpty {
                handle.readabilityHandler = nil
            }
        }

        child.terminationHandler = { [weak self] terminatedProcess in
            self?.queue.async {
                self?.handleTermination(terminatedProcess, status: terminatedProcess.terminationStatus)
            }
        }

        do {
            try child.run()
            send(
                method: "system.hello",
                payload: [
                    "clientVersion": LocalIPCProtocol.clientVersion,
                    "clientPublicKey": channel.clientPublicKey
                ],
                timeout: 5
            ) { result in
                switch result {
                case .success(let response):
                    let capabilities = response["capabilities"] as? [String] ?? []
                    let protocolVersion = response["protocolVersion"] as? Int
                    let service = response["service"] as? String

                    guard
                        protocolVersion == LocalIPCProtocol.version,
                        service == "atheerautotrade-backend",
                        capabilities.contains("system.ping"),
                        capabilities.contains("broker.credentials.submit"),
                        capabilities.contains("broker.connect"),
                        capabilities.contains("broker.status"),
                        capabilities.contains("broker.marketSearch"),
                        let keyAgreement = response["keyAgreement"] as? [String: Any],
                        keyAgreement["algorithm"] as? String == "X25519-HKDF-SHA256-AES-256-GCM",
                        let serverPublicKey = keyAgreement["publicKey"] as? String,
                        let salt = keyAgreement["salt"] as? String
                    else {
                        self.stopAfterProtocolFailure()
                        self.finishStart(.failure(LocalIPCError.handshakeRejected))
                        return
                    }

                    do {
                        try channel.establish(serverPublicKey: serverPublicKey, salt: salt)
                    } catch {
                        self.stopAfterProtocolFailure()
                        self.finishStart(.failure(LocalIPCError.handshakeRejected))
                        return
                    }

                    self.isReady = true
                    self.finishStart(.success(()))

                case .failure(let error):
                    self.stopAfterProtocolFailure()
                    self.finishStart(.failure(error))
                }
            }
        } catch {
            detachHandlers()
            closePipes()
            process = nil
            secretChannel?.reset()
            secretChannel = nil
            finishStart(.failure(LocalIPCError.processLaunchFailed(error.localizedDescription)))
        }
    }

    private func send(
        method: String,
        payload: [String: Any],
        timeout: TimeInterval,
        completion: @escaping Completion
    ) {
        guard process?.isRunning == true, let writer = inputPipe?.fileHandleForWriting else {
            completion(.failure(LocalIPCError.processTerminated))
            return
        }

        let requestID = UUID().uuidString.lowercased()
        do {
            let frame = try LocalIPCProtocol.request(
                id: requestID,
                method: method,
                payload: payload
            )

            let timeoutWork = DispatchWorkItem { [weak self] in
                guard let self, let pendingRequest = self.pending.removeValue(forKey: requestID) else {
                    return
                }
                pendingRequest.completion(.failure(LocalIPCError.requestTimedOut))
                self.stopAfterProtocolFailure()
            }

            pending[requestID] = PendingRequest(
                completion: completion,
                timeout: timeoutWork
            )

            try writer.write(contentsOf: frame)
            queue.asyncAfter(
                deadline: .now() + max(0.1, timeout),
                execute: timeoutWork
            )
        } catch {
            pending.removeValue(forKey: requestID)?.timeout.cancel()
            completion(.failure(error))
        }
    }

    private func consume(_ data: Data, from child: Process) {
        guard process === child else { return }
        do {
            let frames = try decoder.append(data)
            for frame in frames {
                let response = try LocalIPCProtocol.response(from: frame)
                guard let pendingRequest = pending.removeValue(forKey: response.id) else {
                    throw LocalIPCError.invalidResponse
                }

                pendingRequest.timeout.cancel()
                if let remoteError = response.remoteError {
                    pendingRequest.completion(.failure(
                        LocalIPCError.remote(
                            code: remoteError.code,
                            message: remoteError.message
                        )
                    ))
                } else {
                    pendingRequest.completion(.success(response.result ?? [:]))
                }
            }
        } catch {
            stopAfterProtocolFailure()
            finishStart(.failure(error))
        }
    }

    private func handleOutputClosed(for child: Process) {
        guard process === child, !isStopping else { return }
        terminateChild(with: LocalIPCError.processTerminated)
    }

    private func handleTermination(_ child: Process, status: Int32) {
        guard process === child else { return }
        isStopping = true
        isReady = false
        failAll(with: LocalIPCError.processTerminated)
        detachHandlers()
        closePipes()
        process = nil
        decoder.reset()
        secretChannel?.reset()
        secretChannel = nil
        isStopping = false
        finishStart(.failure(LocalIPCError.processTerminated))
        _ = status
    }

    private func stopAfterProtocolFailure() {
        terminateChild(with: LocalIPCError.invalidResponse)
    }

    /// Keeps the process reference until termination is observed, preventing a
    /// caller from launching a second child while the previous child is exiting.
    private func terminateChild(with error: Error) {
        guard !isStopping else { return }
        isStopping = true
        isReady = false
        failAll(with: error)
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil

        if let child = process, child.isRunning {
            child.terminate()
            return
        }

        detachHandlers()
        closePipes()
        process = nil
        decoder.reset()
        secretChannel?.reset()
        secretChannel = nil
        isStopping = false
        finishStart(.failure(error))
    }

    private func finishStart(_ result: Result<Void, Error>) {
        let callbacks = startCompletions
        startCompletions.removeAll()
        callbacks.forEach { $0(result) }
    }

    private func failAll(with error: Error) {
        let requests = Array(pending.values)
        pending.removeAll()
        requests.forEach {
            $0.timeout.cancel()
            $0.completion(.failure(error))
        }
    }

    private func detachHandlers() {
        outputPipe?.fileHandleForReading.readabilityHandler = nil
        errorPipe?.fileHandleForReading.readabilityHandler = nil
        process?.terminationHandler = nil
    }

    private func closePipes() {
        try? inputPipe?.fileHandleForWriting.close()
        try? outputPipe?.fileHandleForReading.close()
        try? errorPipe?.fileHandleForReading.close()
        inputPipe = nil
        outputPipe = nil
        errorPipe = nil
    }
}
