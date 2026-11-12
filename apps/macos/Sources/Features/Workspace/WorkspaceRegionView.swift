import SwiftUI

/// Displays the visible panels belonging to one workspace region.
///
/// Panel heights are allocated proportionally using each panel's sizeFraction.
/// When minimum usable panel heights cannot fit, the region scrolls instead of
/// forcing its content outside the available workspace bounds.
struct WorkspaceRegionView: View {

    @ObservedObject var workspaceManager: WorkspaceManager

    let region: WorkspacePanelRegion

    private let panelSpacing: CGFloat = 8
    private let regionInset: CGFloat = 8

    private var regionPanels: [WorkspacePanel] {
        guard let workspace = workspaceManager.activeWorkspace else {
            return []
        }

        return workspace.panels
            .filter {
                $0.region == region &&
                $0.visibility == .visible
            }
            .sorted {
                if $0.sortOrder == $1.sortOrder {
                    return $0.id.uuidString < $1.id.uuidString
                }

                return $0.sortOrder < $1.sortOrder
            }
    }

    var body: some View {
        GeometryReader { geometry in
            let panels = regionPanels
            let totalWeight = panels.reduce(0.0) {
                $0 + max($1.sizeFraction, 0.15)
            }
            let interPanelSpacing = panelSpacing * CGFloat(max(panels.count - 1, 0))
            let availableHeight = max(
                geometry.size.height - (regionInset * 2) - interPanelSpacing,
                0
            )

            Group {
                if panels.isEmpty {
                    emptyRegion
                } else {
                    ScrollView(.vertical) {
                        VStack(spacing: panelSpacing) {
                            ForEach(panels) { panel in
                                WorkspacePanelView(
                                    panel: panel,
                                    onHide: {
                                        workspaceManager.hidePanel(panel.id)
                                    },
                                    onClose: {
                                        workspaceManager.closePanel(panel.id)
                                    },
                                    onToggleMaximize: {
                                        workspaceManager.toggleMaximize(panel.id)
                                    }
                                )
                                .frame(maxWidth: .infinity)
                                .frame(
                                    height: allocatedHeight(
                                        for: panel,
                                        availableHeight: availableHeight,
                                        totalWeight: totalWeight
                                    )
                                )
                            }
                        }
                        .padding(regionInset)
                        .frame(minHeight: geometry.size.height, alignment: .top)
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(AtheerColors.canvas)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtheerColors.canvas)
    }

    // MARK: - Panel Allocation

    private func allocatedHeight(
        for panel: WorkspacePanel,
        availableHeight: CGFloat,
        totalWeight: Double
    ) -> CGFloat {
        let weight = max(panel.sizeFraction, 0.15)
        let normalizedWeight = CGFloat(weight / max(totalWeight, 0.0001))
        let proportionalHeight = availableHeight * normalizedWeight
        let minimumHeight: CGFloat = panel.kind == .chart ? 180 : 112

        return max(minimumHeight, proportionalHeight)
    }

    // MARK: - Empty Region

    private var emptyRegion: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.dashed")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(AtheerColors.textSecondary.opacity(0.6))

            Text("Empty Workspace Region")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AtheerColors.textSecondary)

            Text("Add a panel to this region to begin.")
                .font(.system(size: 10))
                .foregroundColor(AtheerColors.textSecondary.opacity(0.75))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtheerColors.surface.opacity(0.35))
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(
                    AtheerColors.border,
                    style: StrokeStyle(
                        lineWidth: 1,
                        dash: [5, 4]
                    )
                )
        }
        .padding(regionInset)
    }
}
