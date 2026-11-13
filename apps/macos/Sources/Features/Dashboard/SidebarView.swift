import SwiftUI

struct SidebarView: View {
    @Binding var selection: WorkspaceSection

    private let workspaceSections: [WorkspaceSection] = [
        .dashboard, .tradingWorkspace, .markets, .strategies, .positions, .orders, .portfolio
    ]

    private let intelligenceSections: [WorkspaceSection] = [
        .riskManagement, .analytics, .intelligence, .activity
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            brandHeader

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    sectionLabel("WORKSPACE")
                    sectionList(workspaceSections)

                    sectionLabel("INTELLIGENCE")
                        .padding(.top, 24)
                    sectionList(intelligenceSections)
                }
                .padding(.bottom, 18)
            }

            Spacer(minLength: 8)

            Rectangle()
                .fill(AtheerColors.border)
                .frame(height: 1)
                .padding(.horizontal, 18)
                .padding(.bottom, 10)

            sectionList([.settings])
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(AtheerColors.sidebar)
    }

    private var brandHeader: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: AtheerRadius.medium, style: .continuous)
                .fill(AtheerColors.accentMuted)
                .frame(width: 38, height: 38)
                .overlay {
                    Image(systemName: "waveform.path")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AtheerColors.accent)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text("ATHEER")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundColor(AtheerColors.textPrimary)

                Text("AUTOTRADE")
                    .font(.system(size: 9, weight: .medium, design: .rounded))
                    .tracking(1.8)
                    .foregroundColor(AtheerColors.textSecondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 28)
    }

    private func sectionLabel(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 9, weight: .semibold, design: .rounded))
            .tracking(1.4)
            .foregroundColor(AtheerColors.textTertiary)
            .padding(.horizontal, 22)
            .padding(.bottom, 9)
    }

    private func sectionList(_ sections: [WorkspaceSection]) -> some View {
        VStack(spacing: 3) {
            ForEach(sections) { section in
                sectionButton(for: section)
            }
        }
    }

    private func sectionButton(for section: WorkspaceSection) -> some View {
        let isSelected = selection == section

        return Button {
            selection = section
        } label: {
            HStack(spacing: 12) {
                Image(systemName: section.symbol)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 18)
                    .accessibilityHidden(true)

                Text(section.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                    .lineLimit(1)

                Spacer(minLength: 0)
            }
            .foregroundColor(isSelected ? AtheerColors.textPrimary : AtheerColors.textSecondary)
            .padding(.horizontal, 12)
            .frame(height: 36)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: AtheerRadius.small, style: .continuous)
                    .fill(isSelected ? AtheerColors.elevated : Color.clear)
            }
            .overlay(alignment: .leading) {
                if isSelected {
                    Capsule()
                        .fill(AtheerColors.accent)
                        .frame(width: 2, height: 17)
                        .offset(x: -1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: AtheerRadius.small, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(section.availabilityDescription)
        .accessibilityLabel(section.rawValue)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .padding(.horizontal, 12)
    }
}
