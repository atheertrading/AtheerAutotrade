
import SwiftUI

struct DashboardView: View {

    private let statusItems: [DashboardStatusItem] = [
        DashboardStatusItem(
            title: "MARKET DATA",
            symbol: "waveform.path.ecg",
            status: "Not configured",
            detail: "No market data provider is connected."
        ),
        DashboardStatusItem(
            title: "BROKER CONNECTION",
            symbol: "building.2",
            status: "Not configured",
            detail: "No broker account is connected."
        ),
        DashboardStatusItem(
            title: "AUTOMATION",
            symbol: "slider.horizontal.3",
            status: "Disabled",
            detail: "Automated trading is not available in this build."
        )
    ]

    private let statusColumns = [
        GridItem(
            .adaptive(minimum: 190),
            spacing: AtheerSpacing.medium,
            alignment: .top
        )
    ]

    var body: some View {
        GeometryReader { geometry in
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: AtheerSpacing.large) {
                    header

                    foundationNotice

                    LazyVGrid(
                        columns: statusColumns,
                        alignment: .leading,
                        spacing: AtheerSpacing.medium
                    ) {
                        ForEach(statusItems) { item in
                            DashboardStatusCard(item: item)
                        }
                    }

                    activityPanel

                    Spacer(minLength: 0)
                }
                .padding(AtheerSpacing.extraLarge)
                .frame(
                    maxWidth: .infinity,
                    minHeight: geometry.size.height,
                    alignment: .topLeading
                )
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height
            )
            .background(AtheerColors.canvas)
        }
        .background(AtheerColors.canvas)
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: AtheerSpacing.medium) {
            VStack(alignment: .leading, spacing: 7) {
                Text("Workspace Overview")
                    .font(.system(size: 27, weight: .semibold, design: .rounded))
                    .foregroundColor(AtheerColors.textPrimary)

                Text("System readiness and connected service status")
                    .font(.system(size: 13))
                    .foregroundColor(AtheerColors.textSecondary)
            }

            Spacer(minLength: AtheerSpacing.small)

            HStack(spacing: 8) {
                Circle()
                    .fill(AtheerColors.warning)
                    .frame(width: 7, height: 7)

                Text("FOUNDATION BUILD")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(0.8)
                    .foregroundColor(AtheerColors.textSecondary)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 9)
            .background(AtheerColors.surface)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AtheerColors.border, lineWidth: 1)
            )
            .accessibilityElement(children: .combine)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Foundation Notice

    private var foundationNotice: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15))
                .foregroundColor(AtheerColors.accent)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 4) {
                Text("Trading services are not connected")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)

                Text(
                    "This foundation build does not retrieve live market, broker, account, or execution data."
                )
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AtheerColors.accent.opacity(0.07))
        .clipShape(
            RoundedRectangle(
                cornerRadius: AtheerRadius.medium,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AtheerRadius.medium,
                style: .continuous
            )
            .stroke(AtheerColors.accent.opacity(0.16), lineWidth: 1)
        }
    }

    // MARK: - System Activity

    private var activityPanel: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("System Activity")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)

                Spacer()

                Text("No events")
                    .font(.system(size: 11))
                    .foregroundColor(AtheerColors.textSecondary)
            }

            Rectangle()
                .fill(AtheerColors.border)
                .frame(height: 1)

            VStack(spacing: 9) {
                Image(systemName: "tray")
                    .font(.system(size: 23, weight: .light))
                    .foregroundColor(AtheerColors.textTertiary)

                Text("No system activity to display")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AtheerColors.textSecondary)

                Text(
                    "Events will appear here when application services are implemented and connected."
                )
                .font(.system(size: 11))
                .foregroundColor(AtheerColors.textTertiary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 34)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .background(AtheerColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AtheerRadius.large,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AtheerRadius.large,
                style: .continuous
            )
            .stroke(AtheerColors.border, lineWidth: 1)
        }
    }
}

// MARK: - Dashboard Models

private struct DashboardStatusItem: Identifiable {
    let title: String
    let symbol: String
    let status: String
    let detail: String

    var id: String { title }
}

// MARK: - Dashboard Status Card

private struct DashboardStatusCard: View {
    let item: DashboardStatusItem

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: item.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AtheerColors.accent)

                Spacer()

                Circle()
                    .fill(AtheerColors.warning)
                    .frame(width: 6, height: 6)
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .tracking(1.1)
                    .foregroundColor(AtheerColors.textSecondary)

                Text(item.status)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AtheerColors.textPrimary)

                Text(item.detail)
                    .font(.system(size: 10))
                    .foregroundColor(AtheerColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(17)
        .frame(
            maxWidth: .infinity,
            minHeight: 142,
            alignment: .leading
        )
        .background(AtheerColors.surface)
        .clipShape(
            RoundedRectangle(
                cornerRadius: AtheerRadius.medium,
                style: .continuous
            )
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: AtheerRadius.medium,
                style: .continuous
            )
            .stroke(AtheerColors.border, lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
    }
}

