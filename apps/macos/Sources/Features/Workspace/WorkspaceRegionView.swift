
import SwiftUI

/// Displays the visible panels belonging to one workspace region.
///
/// This view coordinates panel presentation only.
/// It does not access broker, market-data, risk, or execution services.
struct WorkspaceRegionView: View {

    @ObservedObject var workspaceManager: WorkspaceManager

    let region: WorkspacePanelRegion

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
        Group {
            if regionPanels.isEmpty {
                emptyRegion
            } else {
                panelStack
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtheerColors.canvas)
    }

    // MARK: - Panel Stack

    private var panelStack: some View {
        VStack(spacing: 8) {
            ForEach(regionPanels) { panel in
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
                .frame(
                    maxWidth: .infinity,
                    minHeight: panel.kind == .chart ? 240 : 150
                )
                .layoutPriority(
                    panel.kind == .chart ? 1 : 0
                )
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
        .padding(8)
    }
}

