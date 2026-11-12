import SwiftUI
import Security

private enum CapitalComEnvironment: String, CaseIterable, Identifiable {
    case demo = "Demo"
    case live = "Live"

    var id: String { rawValue }

    var baseURL: URL {
        switch self {
        case .demo:
            return URL(string: "https://demo-api-capital.backend-capital.com")!
        case .live:
            return URL(string: "https://api-capital.backend-capital.com")!
        }
    }
}

private struct CapitalComCredentials: Codable {
    let identifier: String
    let apiKey: String
    let password: String
}

private enum CapitalComKeychain {
    private static let service = "com.atheerautotrade.capital-com"

    static func save(_ credentials: CapitalComCredentials, environment: CapitalComEnvironment) throws {
        let data = try JSONEncoder().encode(credentials)
        let account = environment.rawValue.lowercased()
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let update: [String: Any] = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
        if status == errSecItemNotFound {
            var insertion = query
            insertion[kSecValueData as String] = data
            insertion[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            let addStatus = SecItemAdd(insertion as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError(status: addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError(status: status)
        }
    }

    static func load(environment: CapitalComEnvironment) throws -> CapitalComCredentials? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: environment.rawValue.lowercased(),
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else {
            throw KeychainError(status: status)
        }
        return try JSONDecoder().decode(CapitalComCredentials.self, from: data)
    }

    static func delete(environment: CapitalComEnvironment) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: environment.rawValue.lowercased()
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    struct KeychainError: LocalizedError {
        let status: OSStatus
        var errorDescription: String? {
            "Keychain operation failed (status \(status))."
        }
    }
}

@MainActor
private final class CapitalComConnectionModel: ObservableObject {
    @Published var environment: CapitalComEnvironment = .demo {
        didSet { loadSavedCredentials() }
    }
    @Published var identifier = ""
    @Published var apiKey = ""
    @Published var password = ""
    @Published var isTesting = false
    @Published var connectionState = "Not connected"
    @Published var connectionMessage = "Enter your Capital.com API credentials to test the connection."
    @Published var lastTest: Date?

    init() {
        loadSavedCredentials()
    }

    var canTest: Bool {
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty && !isTesting
    }

    func loadSavedCredentials() {
        do {
            guard let credentials = try CapitalComKeychain.load(environment: environment) else {
                identifier = ""
                apiKey = ""
                password = ""
                connectionState = "Credentials not saved"
                connectionMessage = "Credentials are stored separately for Demo and Live."
                return
            }
            identifier = credentials.identifier
            apiKey = credentials.apiKey
            password = credentials.password
            connectionState = "Credentials available"
            connectionMessage = "Credentials were retrieved from macOS Keychain. Connection has not yet been tested."
        } catch {
            connectionState = "Keychain error"
            connectionMessage = error.localizedDescription
        }
    }

    func testConnection() {
        guard canTest else { return }
        isTesting = true
        connectionState = "Connecting"
        connectionMessage = "Authenticating with Capital.com \(environment.rawValue)."

        let selectedEnvironment = environment
        let credentials = CapitalComCredentials(
            identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines),
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )

        Task {
            defer { isTesting = false }
            do {
                try CapitalComKeychain.save(credentials, environment: selectedEnvironment)
                var request = URLRequest(
                    url: selectedEnvironment.baseURL.appendingPathComponent("api/v1/session"),
                    timeoutInterval: 15
                )
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue(credentials.apiKey, forHTTPHeaderField: "X-CAP-API-KEY")
                request.httpBody = try JSONSerialization.data(withJSONObject: [
                    "identifier": credentials.identifier,
                    "password": credentials.password,
                    "encryptedPassword": false
                ])

                let (_, response) = try await URLSession.shared.data(for: request)
                guard let http = response as? HTTPURLResponse else {
                    throw ConnectionError.invalidResponse
                }
                guard http.statusCode == 200,
                      http.value(forHTTPHeaderField: "CST") != nil,
                      http.value(forHTTPHeaderField: "X-SECURITY-TOKEN") != nil else {
                    throw ConnectionError.authenticationFailed(http.statusCode)
                }

                connectionState = "REST connected"
                connectionMessage = "Capital.com accepted the credentials and returned an authenticated session. Session tokens were not persisted."
                lastTest = Date()
            } catch {
                connectionState = "Connection failed"
                connectionMessage = error.localizedDescription
                lastTest = Date()
            }
        }
    }

    func removeCredentials() {
        do {
            try CapitalComKeychain.delete(environment: environment)
            identifier = ""
            apiKey = ""
            password = ""
            connectionState = "Credentials removed"
            connectionMessage = "Saved credentials were removed from macOS Keychain."
        } catch {
            connectionState = "Keychain error"
            connectionMessage = error.localizedDescription
        }
    }

    private enum ConnectionError: LocalizedError {
        case invalidResponse
        case authenticationFailed(Int)

        var errorDescription: String? {
            switch self {
            case .invalidResponse:
                return "Capital.com returned an invalid HTTP response."
            case .authenticationFailed(let status):
                return "Capital.com authentication failed (HTTP \(status)). Verify the selected environment and API credentials."
            }
        }
    }
}

struct CapitalComSettingsView: View {
    @StateObject private var model = CapitalComConnectionModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                environmentCard
                credentialsCard
                connectionCard
                securityNote
            }
            .padding(30)
            .frame(maxWidth: 860, alignment: .leading)
        }
        .background(AtheerColors.canvas)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Capital.com")
                .font(.system(size: 25, weight: .semibold, design: .rounded))
                .foregroundColor(AtheerColors.textPrimary)
            Text("Broker connection and API credential management")
                .font(.system(size: 12))
                .foregroundColor(AtheerColors.textSecondary)
        }
    }

    private var environmentCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle("Connection environment", subtitle: "Demo and Live credentials are stored independently.")
            Picker("Environment", selection: $model.environment) {
                ForEach(CapitalComEnvironment.allCases) { environment in
                    Text(environment.rawValue).tag(environment)
                }
            }
            .pickerStyle(.segmented)
            if model.environment == .live {
                Label("Live environment selected. This screen only authenticates; it cannot place or modify orders.", systemImage: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(AtheerColors.warning)
            }
        }
        .padding(18)
        .background(AtheerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.large))
    }

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardTitle("API credentials", subtitle: "Credentials are saved in macOS Keychain, not in application preferences or source files.")
            credentialField("Account identifier", text: $model.identifier)
            credentialField("API key", text: $model.apiKey)
            VStack(alignment: .leading, spacing: 6) {
                Text("API key password")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AtheerColors.textSecondary)
                SecureField("Enter API key password", text: $model.password)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Button("Test & Save Credentials") {
                    model.testConnection()
                }
                .buttonStyle(.borderedProminent)
                .tint(AtheerColors.accent)
                .disabled(!model.canTest)

                if model.isTesting {
                    ProgressView()
                        .controlSize(.small)
                }

                Spacer()

                Button("Remove Saved Credentials", role: .destructive) {
                    model.removeCredentials()
                }
                .disabled(model.isTesting)
            }
        }
        .padding(18)
        .background(AtheerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.large))
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardTitle("Connection status", subtitle: "REST authentication status for the selected environment.")
            HStack(spacing: 9) {
                Circle()
                    .fill(model.connectionState == "REST connected" ? AtheerColors.positive : AtheerColors.warning)
                    .frame(width: 8, height: 8)
                Text(model.connectionState)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)
                Spacer()
                if let lastTest = model.lastTest {
                    Text(lastTest.formatted(date: .abbreviated, time: .standard))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(AtheerColors.textTertiary)
                }
            }
            Text(model.connectionMessage)
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textSecondary)
                .textSelection(.enabled)
        }
        .padding(18)
        .background(AtheerColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.large))
    }

    private var securityNote: some View {
        Label("This first connection slice validates REST authentication only. WebSocket feed status, account data, and order execution are not represented as connected or available here.", systemImage: "lock.shield")
            .font(.system(size: 11))
            .foregroundColor(AtheerColors.textTertiary)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func cardTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)
            Text(subtitle)
                .font(.system(size: 10))
                .foregroundColor(AtheerColors.textSecondary)
        }
    }

    private func credentialField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AtheerColors.textSecondary)
            TextField(title, text: text)
                .textFieldStyle(.roundedBorder)
                .textContentType(.username)
        }
    }
}
