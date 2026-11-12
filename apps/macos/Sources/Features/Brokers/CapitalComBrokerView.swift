import SwiftUI

struct CapitalComBrokerView: View {
    @State private var apiKey = ""
    @State private var identifier = ""
    @State private var password = ""
    @State private var hasSavedCredentials = CapitalComCredentialStore.hasSavedCredentials
    @State private var feedback: Feedback?
    @State private var showingDeleteConfirmation = false

    private enum Feedback {
        case success(String)
        case error(String)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                pageHeader
                connectionOverview
                credentialsCard
                securityNotice
                integrationStatus
            }
            .frame(maxWidth: 1040, alignment: .leading)
            .padding(.horizontal, 34)
            .padding(.vertical, 30)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(AtheerColors.canvas)
        .onAppear(perform: restoreCredentials)
        .alert("Remove saved credentials?", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Remove Credentials", role: .destructive) {
                deleteCredentials()
            }
        } message: {
            Text("The Capital.com API key, identifier, and password will be removed from this Mac's Keychain.")
        }
    }

    private var pageHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("BROKER CONNECTIONS")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(AtheerColors.accent)

                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(AtheerColors.textTertiary)

                Text("CAPITAL.COM")
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .tracking(1.2)
                    .foregroundColor(AtheerColors.textSecondary)
            }

            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AtheerColors.accent.opacity(0.24),
                                    AtheerColors.accent.opacity(0.07)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 27, weight: .semibold))
                        .foregroundColor(AtheerColors.accent)
                }
                .frame(width: 62, height: 62)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Capital.com")
                        .font(.system(size: 27, weight: .semibold, design: .rounded))
                        .foregroundColor(AtheerColors.textPrimary)

                    Text("Broker account, API credentials and connection controls")
                        .font(.system(size: 12))
                        .foregroundColor(AtheerColors.textSecondary)
                }

                Spacer(minLength: 12)

                statusPill(
                    title: "NOT CONNECTED",
                    color: AtheerColors.warning,
                    symbol: "circle.dashed"
                )
            }
        }
    }

    private var connectionOverview: some View {
        HStack(spacing: 0) {
            overviewMetric(
                title: "ENVIRONMENT",
                value: "DEMO",
                detail: "Selected account environment",
                symbol: "testtube.2",
                tint: AtheerColors.accent
            )

            metricDivider

            overviewMetric(
                title: "AUTHENTICATION",
                value: hasSavedCredentials ? "CREDENTIALS SAVED" : "NOT CONFIGURED",
                detail: hasSavedCredentials ? "Stored in macOS Keychain" : "API credentials required",
                symbol: "key.horizontal",
                tint: hasSavedCredentials ? AtheerColors.positive : AtheerColors.warning
            )

            metricDivider

            overviewMetric(
                title: "TRADING PERMISSION",
                value: "DISABLED",
                detail: "Execution is not available",
                symbol: "lock.shield",
                tint: AtheerColors.warning
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 22)
        .background(AtheerColors.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AtheerRadius.large, style: .continuous)
                .stroke(AtheerColors.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.large, style: .continuous))
    }

    private var credentialsCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text("API CREDENTIALS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundColor(AtheerColors.textPrimary)

                    Text("Enter the credentials issued in your Capital.com account.")
                        .font(.system(size: 11))
                        .foregroundColor(AtheerColors.textSecondary)
                }

                Spacer()

                statusPill(
                    title: "KEYCHAIN STORAGE",
                    color: AtheerColors.positive,
                    symbol: "lock.fill"
                )
            }

            HStack(spacing: 8) {
                environmentOption(title: "DEMO", selected: true)
                environmentOption(title: "LIVE", selected: false, disabled: true)

                Spacer()

                Text("LIVE ACCESS LOCKED")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundColor(AtheerColors.warning)
            }

            VStack(alignment: .leading, spacing: 7) {
                fieldLabel("API KEY", required: true)
                SecureField("Paste your Capital.com API key", text: $apiKey)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, design: .monospaced))
                    .padding(.horizontal, 13)
                    .frame(height: 42)
                    .background(AtheerColors.canvas)
                    .overlay {
                        RoundedRectangle(cornerRadius: AtheerRadius.small)
                            .stroke(AtheerColors.borderStrong, lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 7) {
                fieldLabel("IDENTIFIER / EMAIL", required: true)
                TextField("Your Capital.com account identifier", text: $identifier)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 13)
                    .frame(height: 42)
                    .background(AtheerColors.canvas)
                    .overlay {
                        RoundedRectangle(cornerRadius: AtheerRadius.small)
                            .stroke(AtheerColors.borderStrong, lineWidth: 1)
                    }
            }

            VStack(alignment: .leading, spacing: 7) {
                fieldLabel("PASSWORD", required: true)
                SecureField("Your Capital.com account password", text: $password)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .padding(.horizontal, 13)
                    .frame(height: 42)
                    .background(AtheerColors.canvas)
                    .overlay {
                        RoundedRectangle(cornerRadius: AtheerRadius.small)
                            .stroke(AtheerColors.borderStrong, lineWidth: 1)
                    }
            }

            HStack(alignment: .center, spacing: 12) {
                Button(action: saveCredentials) {
                    HStack(spacing: 8) {
                        Image(systemName: "lock.shield")
                        Text("Save Credentials Securely")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AtheerColors.canvas)
                    .padding(.horizontal, 17)
                    .frame(height: 40)
                    .background(AtheerColors.accent)
                    .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.small))
                }
                .buttonStyle(.plain)
                .disabled(!canSave)
                .opacity(canSave ? 1 : 0.48)

                Button {
                } label: {
                    HStack(spacing: 7) {
                        Image(systemName: "link")
                        Text("Connect to Capital.com")
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AtheerColors.textSecondary)
                    .padding(.horizontal, 15)
                    .frame(height: 40)
                    .background(AtheerColors.elevated)
                    .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.small))
                }
                .buttonStyle(.plain)
                .disabled(true)
                .help("Connection will be enabled after the signed backend runtime and secure credential handoff are verified.")

                if hasSavedCredentials {
                    Button("Remove Saved Credentials", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AtheerColors.negative)
                }

                Spacer()
            }

            if let feedback {
                feedbackView(feedback)
            }
        }
        .padding(24)
        .background(AtheerColors.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AtheerRadius.large, style: .continuous)
                .stroke(AtheerColors.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.large, style: .continuous))
    }

    private var securityNotice: some View {
        HStack(alignment: .top, spacing: 13) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 18))
                .foregroundColor(AtheerColors.positive)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 5) {
                Text("Credential protection")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)

                Text("Credentials are stored as an encrypted macOS Keychain item. They are not written to project files, preferences, application logs, process arguments, or environment variables.")
                    .font(.system(size: 11))
                    .foregroundColor(AtheerColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .background(AtheerColors.positive.opacity(0.07))
        .overlay {
            RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous)
                .stroke(AtheerColors.positive.opacity(0.18), lineWidth: 1)
        }
    }

    private var integrationStatus: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("CONNECTION READINESS")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(AtheerColors.textSecondary)

            readinessRow(
                title: "Credential entry and Keychain storage",
                detail: "Available in this screen",
                complete: true
            )
            readinessRow(
                title: "Secure desktop-to-backend session handoff",
                detail: "Pending IPC packaging and verification",
                complete: false
            )
            readinessRow(
                title: "Capital.com authentication and account handshake",
                detail: "Not yet enabled",
                complete: false
            )
            readinessRow(
                title: "Trading and order execution",
                detail: "Disabled by system safety policy",
                complete: false
            )
        }
        .padding(22)
        .background(AtheerColors.surface)
        .overlay {
            RoundedRectangle(cornerRadius: AtheerRadius.large, style: .continuous)
                .stroke(AtheerColors.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.large, style: .continuous))
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(AtheerColors.border)
            .frame(width: 1, height: 48)
            .padding(.horizontal, 20)
    }

    private var canSave: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !identifier.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    private func overviewMetric(
        title: String,
        value: String,
        detail: String,
        symbol: String,
        tint: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 6) {
                Image(systemName: symbol)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(tint)
                Text(title)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundColor(AtheerColors.textTertiary)
            }

            Text(value)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(detail)
                .font(.system(size: 10))
                .foregroundColor(AtheerColors.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func environmentOption(
        title: String,
        selected: Bool,
        disabled: Bool = false
    ) -> some View {
        HStack(spacing: 6) {
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
            }
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.7)
        }
        .foregroundColor(disabled ? AtheerColors.textTertiary : (selected ? AtheerColors.accent : AtheerColors.textSecondary))
        .padding(.horizontal, 12)
        .frame(height: 30)
        .background(selected ? AtheerColors.accentMuted : AtheerColors.elevated.opacity(0.65))
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .stroke(selected ? AtheerColors.accent.opacity(0.35) : AtheerColors.border, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .opacity(disabled ? 0.55 : 1)
        .help(disabled ? "LIVE connection is not enabled in this milestone." : "Capital.com Demo environment")
    }

    private func fieldLabel(_ title: String, required: Bool) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(AtheerColors.textSecondary)
            if required {
                Text("*")
                    .foregroundColor(AtheerColors.warning)
            }
        }
    }

    private func statusPill(title: String, color: Color, symbol: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: symbol)
                .font(.system(size: 9, weight: .bold))
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.7)
        }
        .foregroundColor(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(color.opacity(0.10))
        .overlay {
            Capsule().stroke(color.opacity(0.20), lineWidth: 1)
        }
        .clipShape(Capsule())
    }

    private func readinessRow(title: String, detail: String, complete: Bool) -> some View {
        HStack(alignment: .center, spacing: 11) {
            Image(systemName: complete ? "checkmark.circle.fill" : "circle.dashed")
                .font(.system(size: 14))
                .foregroundColor(complete ? AtheerColors.positive : AtheerColors.warning)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AtheerColors.textPrimary)
                Text(detail)
                    .font(.system(size: 10))
                    .foregroundColor(AtheerColors.textSecondary)
            }

            Spacer()
        }
    }

    @ViewBuilder
    private func feedbackView(_ feedback: Feedback) -> some View {
        switch feedback {
        case .success(let message):
            Label(message, systemImage: "checkmark.circle.fill")
                .foregroundColor(AtheerColors.positive)
                .font(.system(size: 11, weight: .medium))
        case .error(let message):
            Label(message, systemImage: "exclamationmark.triangle.fill")
                .foregroundColor(AtheerColors.negative)
                .font(.system(size: 11, weight: .medium))
        }
    }

    private func saveCredentials() {
        let credentials = CapitalComCredentials(
            apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
            identifier: identifier.trimmingCharacters(in: .whitespacesAndNewlines),
            password: password
        )

        do {
            try CapitalComCredentialStore.save(credentials)

            guard let storedCredentials = try CapitalComCredentialStore.load(),
                  storedCredentials == credentials else {
                throw CapitalComCredentialStoreError.verificationFailed
            }

            apiKey = storedCredentials.apiKey
            identifier = storedCredentials.identifier
            password = storedCredentials.password
            hasSavedCredentials = true
            feedback = .success("Credentials saved and verified in macOS Keychain.")
        } catch {
            feedback = .error(error.localizedDescription)
        }
    }

    private func restoreCredentials() {
        do {
            guard let credentials = try CapitalComCredentialStore.load() else {
                hasSavedCredentials = false
                return
            }

            apiKey = credentials.apiKey
            identifier = credentials.identifier
            password = credentials.password
            hasSavedCredentials = true
        } catch {
            hasSavedCredentials = false
            feedback = .error("Unable to read saved Keychain credentials: \\(error.localizedDescription)")
        }
    }

    private func deleteCredentials() {
        do {
            try CapitalComCredentialStore.delete()
            apiKey = ""
            identifier = ""
            password = ""
            hasSavedCredentials = false
            feedback = .success("Saved Capital.com credentials were removed.")
        } catch {
            feedback = .error(error.localizedDescription)
        }
    }
}
