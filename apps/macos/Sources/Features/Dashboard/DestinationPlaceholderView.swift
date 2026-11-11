import SwiftUI

struct DestinationPlaceholderView: View {
    let section: WorkspaceSection

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: section.symbol)
                .font(.system(size: 27, weight: .light))
                .foregroundColor(AtheerColors.accent)
                .frame(width: 64, height: 64)
                .background(AtheerColors.accentMuted)
                .clipShape(RoundedRectangle(cornerRadius: AtheerRadius.large, style: .continuous))
                .accessibilityHidden(true)

            Text(section.rawValue)
                .font(.system(size: 23, weight: .semibold, design: .rounded))
                .foregroundColor(AtheerColors.textPrimary)

            Text(section.availabilityDescription)
                .font(.system(size: 12))
                .foregroundColor(AtheerColors.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 360)

            Text("NOT IMPLEMENTED")
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .tracking(1.0)
                .foregroundColor(AtheerColors.warning)
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .background(AtheerColors.warning.opacity(0.10))
                .clipShape(Capsule())
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AtheerSpacing.extraLarge)
        .background(AtheerColors.canvas)
    }
}
