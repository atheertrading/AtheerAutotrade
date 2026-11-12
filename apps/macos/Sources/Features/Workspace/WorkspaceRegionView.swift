import SwiftUI
import UniformTypeIdentifiers

/// Displays the visible panels belonging to one workspace region.
/// Panel heights are allocated proportionally using each panel's sizeFraction.
struct WorkspaceRegionView: View {

    @ObservedObject var workspaceManager: WorkspaceManager

    let region: WorkspacePanelRegion
    let isPanelArrangementEnabled: Bool

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
                            ForEach(Array(panels.enumerated()), id: \.element.id) { index, panel in
                                panelCard(panel, visibleIndex: index)
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
            .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
                guard isPanelArrangementEnabled else { return false }
                return receiveDrop(providers, before: nil)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtheerColors.canvas)
    }

    // MARK: - Panel Card and Drag-and-Drop

    @ViewBuilder
    private func panelCard(
        _ panel: WorkspacePanel,
        visibleIndex: Int
    ) -> some View {
        let card = WorkspacePanelView(
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

        if isPanelArrangementEnabled {
            card
                .overlay {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(
                            AtheerColors.accent.opacity(0.65),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 3])
                        )
                }
                .onDrag {
                    NSItemProvider(object: panel.id.uuidString as NSString)
                }
                .onDrop(of: [UTType.plainText], isTargeted: nil) { providers in
                    receiveDrop(providers, before: panel)
                }
                .help("Drag this panel to another workspace region or panel position")
        } else {
            card
        }
    }

    private func receiveDrop(
        _ providers: [NSItemProvider],
        before targetPanel: WorkspacePanel?
    ) -> Bool {
        guard isPanelArrangementEnabled,
              let provider = providers.first,
              provider.canLoadObject(ofClass: NSString.self) else {
            return false
        }

        _ = provider.loadObject(ofClass: NSString.self) { object, _ in
            guard let identifier = object as? String,
                  let draggedPanelID = UUID(uuidString: identifier) else {
                return
            }

            DispatchQueue.main.async {
                guard draggedPanelID != targetPanel?.id else { return }

                let insertionIndex: Int?

                if let targetPanel,
                   let workspace = workspaceManager.activeWorkspace {
                    let targetPanels = workspace.panels
                        .filter {
                            $0.region == region &&
                            $0.id != draggedPanelID
                        }
                        .sorted {
                            if $0.sortOrder == $1.sortOrder {
                                return $0.id.uuidString < $1.id.uuidString
                            }

                            return $0.sortOrder < $1.sortOrder
                        }

                    insertionIndex = targetPanels.firstIndex {
                        $0.id == targetPanel.id
                    } ?? targetPanels.count
                } else {
                    insertionIndex = nil
                }

                workspaceManager.movePanel(
                    draggedPanelID,
                    to: region,
                    at: insertionIndex
                )
            }
        }

        return true
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

    // MARK: - Empty State

    private var emptyRegion: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.dashed")
                .font(.system(size: 18, weight: .light))
                .foregroundColor(AtheerColors.textSecondary.opacity(0.6))

            Text("Empty Workspace Region")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AtheerColors.textSecondary)

            Text(
                isPanelArrangementEnabled
                    ? "Drop a panel here to move it into this region."
                    : "Add a panel to this region to begin."
            )
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
