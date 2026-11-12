import Foundation

/// Owns the backend child process and its anonymous stdio pipes.
///
/// Expected signed bundle layout:
/// - Contents/Helpers/AtheerNodeRuntime/bin/node
/// - Contents/Resources/Backend/dist/server.js
///
/// The runtime is resolved only from the app bundle. PATH lookup and shell
/// invocation are deliberately prohibited. The credential provider is not
/// part of this component.
final class BackendProcessSupervisor {
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

        childOutput.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard !data.isEmpty else {
                handle.readabilityHandler = nil
                self?.queue.async {
                    self?.handleOutputClosed()
                }
                return
            }

            self?.queue.async {
                self?.consume(data)
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
                self?.handleTermination(status: terminatedProcess.terminationStatus)
            }
        }

        do {
            try child.run()
            send(
                method: "system.hello",
                payload: ["clientVersion": LocalIPCProtocol.clientVersion],
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
                        capabilities.contains("system.ping")
                    else {
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

    private func consume(_ data: Data) {
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

    private func handleOutputClosed() {
        guard !isStopping else { return }
        terminateChild(with: LocalIPCError.processTerminated)
    }

    private func handleTermination(status: Int32) {
        isStopping = true
        isReady = false
        failAll(with: LocalIPCError.processTerminated)
        detachHandlers()
        closePipes()
        process = nil
        decoder.reset()
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
