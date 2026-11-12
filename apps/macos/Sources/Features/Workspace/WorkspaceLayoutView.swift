import SwiftUI

/// Composes the active workspace into its primary trading regions.
/// Presentation only: no broker, market-data, risk, or execution access.
struct WorkspaceLayoutView: View {

    @ObservedObject var workspaceManager: WorkspaceManager

    @State private var sidebarDragStartWidth: CGFloat?
    @State private var bottomDragStartHeight: CGFloat?

    private let spacing: CGFloat = 8

    private var activeWorkspace: AtheerWorkspace? {
        workspaceManager.activeWorkspace
    }

    private var restorablePanels: [WorkspacePanel] {
        guard let workspace = activeWorkspace else { return [] }

        return workspace.panels
            .filter { $0.visibility != .visible }
            .sorted {
                if $0.region == $1.region {
                    return $0.sortOrder < $1.sortOrder
                }
                return regionOrder($0.region) < regionOrder($1.region)
            }
    }

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let workspace = activeWorkspace {
                    workspaceContent(workspace, availableSize: geometry.size)
                } else {
                    emptyWorkspaceState
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AtheerColors.canvas)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AtheerColors.canvas)
    }

    // MARK: - Workspace Content

    private func workspaceContent(
        _ workspace: AtheerWorkspace,
        availableSize: CGSize
    ) -> some View {
        VStack(spacing: spacing) {
            workspaceHeader(workspace)

            primaryLayout(workspace, availableSize: availableSize)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(spacing)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Primary Layout

    @ViewBuilder
    private func primaryLayout(
        _ workspace: AtheerWorkspace,
        availableSize: CGSize
    ) -> some View {
        let layout = workspace.layout
        let sidebarWidth = min(
            CGFloat(layout.sidebarWidth),
            max(180, availableSize.width * 0.34)
        )
        let leftRegionHeight = min(
            max(availableSize.height * 0.24, 140),
            220
        )

        if layout.sidebarVisible {
            if layout.primaryOrientation == .horizontal {
                HStack(spacing: spacing) {
                    leftRegion
                        .frame(width: sidebarWidth)

                    WorkspaceResizeHandle(
                        axis: .horizontal,
                        onDragChanged: { translation in
                            let initialWidth = sidebarDragStartWidth
                                ?? CGFloat(workspace.layout.sidebarWidth)

                            if sidebarDragStartWidth == nil {
                                sidebarDragStartWidth = initialWidth
                            }

                            workspaceManager.setSidebarWidth(
                                Double(initialWidth + translation)
                            )
                        },
                        onDragEnded: {
                            sidebarDragStartWidth = nil
                        }
                    )
                    .frame(maxHeight: .infinity)

                    mainLayout(
                        workspace,
                        availableSize: CGSize(
                            width: max(availableSize.width - sidebarWidth - spacing - 8, 0),
                            height: availableSize.height
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                VStack(spacing: spacing) {
                    leftRegion
                        .frame(height: leftRegionHeight)

                    mainLayout(
                        workspace,
                        availableSize: CGSize(
                            width: availableSize.width,
                            height: max(availableSize.height - leftRegionHeight - spacing, 0)
                        )
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        } else {
            mainLayout(workspace, availableSize: availableSize)
        }
    }

    // MARK: - Main Layout

    private func mainLayout(
        _ workspace: AtheerWorkspace,
        availableSize: CGSize
    ) -> some View {
        let bottomPanelHeight = min(
            max(CGFloat(workspace.layout.bottomPanelHeight), 120),
            max(140, availableSize.height * 0.36)
        )
        let upperRegionHeight = max(
            availableSize.height - bottomPanelHeight - spacing,
            0
        )

        return VStack(spacing: spacing) {
            secondaryLayout(
                workspace,
                availableSize: CGSize(
                    width: availableSize.width,
                    height: upperRegionHeight
                )
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            WorkspaceResizeHandle(
                axis: .vertical,
                onDragChanged: { translation in
                    let initialHeight = bottomDragStartHeight
                        ?? CGFloat(workspace.layout.bottomPanelHeight)

                    if bottomDragStartHeight == nil {
                        bottomDragStartHeight = initialHeight
                    }

                    workspaceManager.setBottomPanelHeight(
                        Double(initialHeight + translation)
                    )
                },
                onDragEnded: {
                    bottomDragStartHeight = nil
                }
            )
            .frame(maxWidth: .infinity)

            WorkspaceRegionView(
                workspaceManager: workspaceManager,
                region: .bottom
            )
            .frame(height: bottomPanelHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Secondary Layout

    @ViewBuilder
    private func secondaryLayout(
        _ workspace: AtheerWorkspace,
        availableSize: CGSize
    ) -> some View {
        let rightPanelWidth = min(
            max(availableSize.width * 0.27, 210),
            320
        )
        let rightRegionHeight = min(
            max(availableSize.height * 0.32, 150),
            280
        )

        if workspace.layout.secondaryOrientation == .horizontal {
            HStack(spacing: spacing) {
                centerRegion
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                rightRegion
                    .frame(width: rightPanelWidth)
            }
        } else {
            VStack(spacing: spacing) {
                centerRegion
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                rightRegion
                    .frame(height: rightRegionHeight)
            }
        }
    }

    // MARK: - Regions

    private var leftRegion: some View {
        WorkspaceRegionView(
            workspaceManager: workspaceManager,
            region: .left
        )
    }

    private var centerRegion: some View {
        WorkspaceRegionView(
            workspaceManager: workspaceManager,
            region: .center
        )
    }

    private var rightRegion: some View {
        WorkspaceRegionView(
            workspaceManager: workspaceManager,
            region: .right
        )
    }

    // MARK: - Header and Panel Management

    private func workspaceHeader(
        _ workspace: AtheerWorkspace
    ) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(workspace.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AtheerColors.textPrimary)

                Text("TRADING WORKSPACE")
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(1.2)
                    .foregroundColor(AtheerColors.textSecondary)
            }

            Spacer()

            Menu {
                panelRegionMenu(.left)
                panelRegionMenu(.center)
                panelRegionMenu(.right)
                panelRegionMenu(.bottom)
            } label: {
                Label("Add Panel", systemImage: "plus")
                    .font(.system(size: 11, weight: .semibold))
            }
            .menuStyle(.borderlessButton)
            .help("Add a panel to the selected workspace region")

            Menu {
                if restorablePanels.isEmpty {
                    Button("No Hidden or Closed Panels") {}
                        .disabled(true)
                } else {
                    ForEach(restorablePanels) { panel in
                        Button {
                            workspaceManager.showPanel(panel.id)
                        } label: {
                            Label(
                                "\(panel.title) — \(regionTitle(panel.region))",
                                systemImage: panel.kind.symbol
                            )
                        }
                    }
                }
            } label: {
                Label("Restore Panels", systemImage: "arrow.uturn.backward")
                    .font(.system(size: 11, weight: .medium))
            }
            .menuStyle(.borderlessButton)
            .disabled(restorablePanels.isEmpty)
            .help("Restore hidden or closed panels")

            HStack(spacing: 7) {
                Circle()
                    .fill(AtheerColors.unavailable)
                    .frame(width: 7, height: 7)

                Text("Services not connected")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(AtheerColors.textSecondary)
            }
            .padding(.horizontal, 11)
            .padding(.vertical, 7)
            .background(AtheerColors.surface)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(AtheerColors.border, lineWidth: 1)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func panelRegionMenu(_ region: WorkspacePanelRegion) -> some View {
        Menu(regionTitle(region)) {
            ForEach(WorkspacePanelKind.allCases) { kind in
                Button {
                    workspaceManager.addPanel(kind, region: region)
                } label: {
                    Label(kind.title, systemImage: kind.symbol)
                }
            }
        }
    }

    private func regionTitle(_ region: WorkspacePanelRegion) -> String {
        switch region {
        case .left: return "Left Sidebar"
        case .center: return "Main Workspace"
        case .right: return "Right Sidebar"
        case .bottom: return "Bottom Workspace"
        case .floating: return "Floating"
        }
    }

    private func regionOrder(_ region: WorkspacePanelRegion) -> Int {
        switch region {
        case .left: return 0
        case .center: return 1
        case .right: return 2
        case .bottom: return 3
        case .floating: return 4
        }
    }

    // MARK: - Empty State

    private var emptyWorkspaceState: some View {
        VStack(spacing: 10) {
            Image(systemName: "rectangle.split.3x1")
                .font(.system(size: 30, weight: .regular))
                .foregroundColor(AtheerColors.textSecondary)

            Text("No Active Workspace")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AtheerColors.textPrimary)

            Text("Select or create a workspace to continue.")
                .font(.system(size: 12))
                .foregroundColor(AtheerColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
