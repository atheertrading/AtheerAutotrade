import SwiftUI

struct CapitalComBrokerView: View {
    @EnvironmentObject private var marketDataStore: MarketDataStore
    @State private var apiKey = ""
    @State private var identifier = ""
    @State private var password = ""
    @State private var hasSavedCredentials = CapitalComCredentialStore.hasSavedCredentials
    @State private var isConnecting = false
    @State private var isConnected = false
    @State private var connectionDetail = "No active broker session"
    @State private var marketSearchTerm = ""
    @State private var marketResults: [MarketRow] = []
    @State private var isSearchingMarkets = false
    @State private var feedback: Feedback?
    @State private var showingDeleteConfirmation = false

    private enum Feedback {
        case success(String)
        case error(String)
    }

    private struct MarketRow: Identifiable {
        let id: String
        let name: String
        let instrumentType: String
        let status: String
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                pageHeader

                // Keep connection state prominent and full-width. The previous
                // three-metric strip was compressed into a 350-point column.
                connectionOverview

                // Prefer a two-column workstation layout when it genuinely
                // fits; fall back to a single column rather than compressing
                // credentials, status text, or market results.
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        VStack(spacing: 18) {
                            credentialsCard
                            securityNotice
                        }
                        .frame(width: 350)

                        VStack(spacing: 18) {
                            marketDiscoveryCard
                            integrationStatus
                        }
                        .frame(minWidth: 400, maxWidth: .infinity)
                    }

                    VStack(spacing: 18) {
                        credentialsCard
                        securityNotice
                        marketDiscoveryCard
                        integrationStatus
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: 1280, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.vertical, 26)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(AtheerColors.canvas)
        .onAppear {
            restoreCredentials()
            refreshConnectionStatus()
        }
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
                    title: isConnected ? "DEMO CONNECTED" : (isConnecting ? "CONNECTING" : "NOT CONNECTED"),
                    color: isConnected ? AtheerColors.positive : AtheerColors.warning,
                    symbol: isConnected ? "checkmark.circle.fill" : (isConnecting ? "arrow.triangle.2.circlepath" : "circle.dashed")
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
                value: isConnected ? "AUTHENTICATED" : (hasSavedCredentials ? "CREDENTIALS SAVED" : "NOT CONFIGURED"),
                detail: isConnected ? connectionDetail : (hasSavedCredentials ? "Stored in macOS Keychain" : "API credentials required"),
                symbol: isConnected ? "checkmark.shield" : "key.horizontal",
                tint: isConnected ? AtheerColors.positive : (hasSavedCredentials ? AtheerColors.accent : AtheerColors.warning)
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

    private var marketDiscoveryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MARKET DISCOVERY")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(1.1)
                        .foregroundColor(AtheerColors.textPrimary)
                    Text("Search instruments directly from Capital.com.")
                        .font(.system(size: 11))
                        .foregroundColor(AtheerColors.textSecondary)
                }
                Spacer()
                statusPill(
                    title: isConnected ? "BROKER API" : "SESSION REQUIRED",
                    color: isConnected ? AtheerColors.positive : AtheerColors.textTertiary,
                    symbol: "magnifyingglass"
                )
            }

            HStack(spacing: 10) {
                TextField("Search markets, e.g. EUR/USD or Gold", text: $marketSearchTerm)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!isConnected || isSearchingMarkets)
                    .onSubmit(searchMarkets)

                Button(action: searchMarkets) {
                    HStack(spacing: 7) {
                        if isSearchingMarkets {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "magnifyingglass")
                        }
                        Text("Search")
                    }
                }
                .disabled(!isConnected || isSearchingMarkets || marketSearchTerm.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            if !marketDataStore.watchlist.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("LIVE MARKET WATCH")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .tracking(0.8)
                            .foregroundColor(AtheerColors.textTertiary)
                        Spacer()
                        Text(marketDataStore.streamStatus.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(marketDataStore.streamStatus == "connected" ? AtheerColors.positive : AtheerColors.warning)
                    }
                    MarketWatchTableView(compact: true)
                    if let streamError = marketDataStore.streamError {
                        Text(streamError)
                            .font(.system(size: 10))
                            .foregroundColor(AtheerColors.negative)
                            .textSelection(.enabled)
                    }
                }
            }

            if !marketResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(marketResults) { market in
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(market.name)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(AtheerColors.textPrimary)
                                Text(market.id)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(AtheerColors.textTertiary)
                            }
                            Spacer()
                            Text(market.instrumentType)
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AtheerColors.textSecondary)
                            Text(market.status)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(market.status == "TRADEABLE" ? AtheerColors.positive : AtheerColors.textSecondary)

                            Button(marketDataStore.contains(epic: market.id) ? "Added" : "Add to Watchlist") {
                                marketDataStore.addInstrument(
                                    MarketWatchInstrument(
                                        epic: market.id,
                                        name: market.name,
                                        instrumentType: market.instrumentType,
                                        marketStatus: market.status
                                    )
                                )
                            }
                            .buttonStyle(.plain)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(marketDataStore.contains(epic: market.id) ? AtheerColors.textTertiary : AtheerColors.accent)
                            .disabled(!isConnected || marketDataStore.contains(epic: market.id) || marketDataStore.watchlist.count >= 40)
                        }
                        .padding(.vertical, 9)
                        if market.id != marketResults.last?.id {
                            Divider().overlay(AtheerColors.border)
                        }
                    }
                }
            } else if isConnected {
                Text("No instruments loaded. Enter a market name or symbol to search.")
                    .font(.system(size: 10))
                    .foregroundColor(AtheerColors.textTertiary)
            } else {
                Text("Market discovery becomes available after the Demo API session is authenticated.")
                    .font(.system(size: 10))
                    .foregroundColor(AtheerColors.textTertiary)
            }
        }
        .padding(22)
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

            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Button(action: saveCredentials) {
                        Label("Save Credentials", systemImage: "lock.shield")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AtheerColors.canvas)
                            .padding(.horizontal, 13)
                            .frame(height: 40)
                            .frame(maxWidth: .infinity)
                            .background(AtheerColors.accent)
                            .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.small))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave || isConnected)
                    .opacity(canSave && !isConnected ? 1 : 0.48)
                    .help(isConnected ? "Disconnect before changing stored credentials." : "Save credentials in macOS Keychain.")

                    Button(action: isConnected ? disconnectFromCapitalCom : connectToCapitalCom) {
                        Label(
                            isConnected ? "Disconnect" : (isConnecting ? "Connecting…" : "Connect"),
                            systemImage: isConnecting ? "arrow.triangle.2.circlepath" : (isConnected ? "link.slash" : "link")
                        )
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isConnected ? AtheerColors.negative : AtheerColors.canvas)
                        .padding(.horizontal, 13)
                        .frame(height: 40)
                        .frame(maxWidth: .infinity)
                        .background(isConnected ? AtheerColors.negative.opacity(0.12) : AtheerColors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.small))
                    }
                    .buttonStyle(.plain)
                    .disabled(isConnecting || (!isConnected && !hasSavedCredentials))
                    .help(isConnected ? "Close the current Capital.com Demo session." : "Authenticate with Capital.com Demo using credentials stored in Keychain.")
                }

                if hasSavedCredentials {
                    Button("Remove Saved Credentials", role: .destructive) {
                        showingDeleteConfirmation = true
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(AtheerColors.negative)
                }
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

                Text("Credentials are encrypted at rest by macOS Keychain, encrypted again with an ephemeral X25519-derived AES-256-GCM key while crossing the private app-to-backend pipe, and sent to Capital.com over HTTPS/TLS. Broker session tokens remain in backend memory only; secrets are never placed in files, logs, process arguments, or environment variables.")
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
                title: "Encrypted local credential handoff",
                detail: "Implemented with ephemeral X25519 key agreement and AES-256-GCM credential transfer",
                complete: true
            )
            readinessRow(
                title: "Capital.com Demo API session",
                detail: isConnected ? connectionDetail : "Connect to authenticate and verify the REST session",
                complete: isConnected
            )
            readinessRow(
                title: "Broker quote stream",
                detail: marketDataStore.streamStatus == "connected"
                    ? "\(marketDataStore.quotes.count) instruments have received broker quotes"
                    : "Subscription and quote delivery are tracked separately from REST authentication",
                complete: marketDataStore.streamStatus == "connected" && !marketDataStore.quotes.isEmpty
            )
            readinessRow(
                title: "Order execution",
                detail: "Not implemented. No broker dealing endpoint is exposed.",
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

    private func refreshConnectionStatus() {
        BackendProcessSupervisor.shared.capitalComStatus { result in
            DispatchQueue.main.async {
                if case .success(let response) = result {
                    isConnected = response["connected"] as? Bool == true
                    marketDataStore.setBrokerConnectionState(isConnected)
                    connectionDetail = isConnected
                        ? "Demo API session authenticated"
                        : "No active broker session"
                    if isConnected {
                        marketDataStore.startStreamingIfNeeded()
                    } else {
                        marketResults = []
                    }
                } else {
                    isConnected = false
                    marketDataStore.setBrokerConnectionState(false)
                    connectionDetail = "Backend unavailable"
                }
            }
        }
    }

    private func connectToCapitalCom() {
        guard !isConnecting, hasSavedCredentials else { return }
        isConnecting = true
        feedback = nil

        BackendProcessSupervisor.shared.connectCapitalCom { result in
            DispatchQueue.main.async {
                isConnecting = false
                switch result {
                case .success(let response):
                    isConnected = response["connected"] as? Bool == true
                    marketDataStore.setBrokerConnectionState(isConnected)
                    connectionDetail = "Demo API session authenticated"
                    marketDataStore.startStreamingIfNeeded(forceRestart: true)
                    feedback = .success("Capital.com Demo session established and verified with an authenticated ping.")
                case .failure(let error):
                    isConnected = false
                    marketDataStore.setBrokerConnectionState(false)
                    connectionDetail = "Connection failed"
                    marketResults = []
                    feedback = .error(error.localizedDescription)
                }
            }
        }
    }

    private func searchMarkets() {
        guard isConnected, !isSearchingMarkets else { return }
        let term = marketSearchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !term.isEmpty else { return }
        isSearchingMarkets = true

        BackendProcessSupervisor.shared.searchCapitalComMarkets(term) { result in
            DispatchQueue.main.async {
                isSearchingMarkets = false
                switch result {
                case .success(let response):
                    let records = response["markets"] as? [[String: Any]] ?? []
                    marketResults = records.compactMap { item in
                        guard let epic = item["epic"] as? String, !epic.isEmpty else { return nil }
                        return MarketRow(
                            id: epic,
                            name: (item["instrumentName"] as? String) ?? epic,
                            instrumentType: (item["instrumentType"] as? String) ?? "MARKET",
                            status: (item["marketStatus"] as? String) ?? "UNKNOWN"
                        )
                    }
                    feedback = .success("Capital.com returned \(marketResults.count) matching instruments.")
                case .failure(let error):
                    marketResults = []
                    feedback = .error(error.localizedDescription)
                }
            }
        }
    }

    private func disconnectFromCapitalCom() {
        guard isConnected else { return }
        BackendProcessSupervisor.shared.disconnectCapitalCom { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    isConnected = false
                    marketDataStore.setBrokerConnectionState(false)
                    connectionDetail = "No active broker session"
                    marketResults = []
                    feedback = .success("Capital.com session closed. Keychain credentials remain saved.")
                case .failure(let error):
                    feedback = .error(error.localizedDescription)
                }
            }
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
            feedback = .error("Unable to read saved Keychain credentials: \(error.localizedDescription)")
        }
    }

    private func deleteCredentials() {
        if isConnected {
            BackendProcessSupervisor.shared.disconnectCapitalCom { result in
                DispatchQueue.main.async {
                    switch result {
                    case .failure(let error):
                        feedback = .error("Disconnect before removing credentials: \(error.localizedDescription)")
                    case .success:
                        isConnected = false
                        marketResults = []
                        removeCredentialsFromKeychain()
                    }
                }
            }
        } else {
            removeCredentialsFromKeychain()
        }
    }

    private func removeCredentialsFromKeychain() {
        do {
            try CapitalComCredentialStore.delete()
            apiKey = ""
            identifier = ""
            password = ""
            hasSavedCredentials = false
            marketDataStore.setBrokerConnectionState(false)
            feedback = .success("Saved Capital.com credentials were removed.")
        } catch {
            feedback = .error(error.localizedDescription)
        }
    }
}
