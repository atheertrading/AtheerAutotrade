import Combine
import Foundation

/// Owns workspace layout and panel presentation state.
/// It must never be used as an authority for connectivity, automation, risk, or execution state.
final class WorkspaceManager: ObservableObject {
    @Published private(set) var workspaces: [AtheerWorkspace] = []
    @Published private(set) var activeWorkspaceID: UUID
    @Published private(set) var persistenceError: String?

    private let persistence: WorkspacePersistence

    var activeWorkspace: AtheerWorkspace? {
        workspaces.first { $0.id == activeWorkspaceID }
    }

    init(persistence: WorkspacePersistence? = nil) {
        let resolvedPersistence: WorkspacePersistence
        do {
            resolvedPersistence = try persistence ?? FileWorkspacePersistence()
        } catch {
            resolvedPersistence = InMemoryWorkspacePersistence()
        }
        self.persistence = resolvedPersistence
        if let document = try? resolvedPersistence.load(),
           document.schemaVersion == WorkspaceDocument.currentSchemaVersion,
           !document.workspaces.isEmpty,
           document.workspaces.contains(where: { $0.id == document.activeWorkspaceID }) {
            self.workspaces = document.workspaces
            self.activeWorkspaceID = document.activeWorkspaceID
        } else {
            let initial = AtheerWorkspace(name: "Primary Trading")
            self.workspaces = [initial]
            self.activeWorkspaceID = initial.id
            persist()
        }
    }

    func selectWorkspace(_ id: UUID) {
        guard workspaces.contains(where: { $0.id == id }) else { return }
        activeWorkspaceID = id
        persist()
    }

    @discardableResult
    func createWorkspace(name: String) -> UUID? {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        let workspace = AtheerWorkspace(name: normalized)
        workspaces.append(workspace)
        activeWorkspaceID = workspace.id
        persist()
        return workspace.id
    }

    @discardableResult
    func duplicateActiveWorkspace(name: String? = nil) -> UUID? {
        guard let source = activeWorkspace else { return nil }
        let copyName = name ?? "\(source.name) Copy"
        let copiedPanels = source.panels.map { panel in
            WorkspacePanel(
                kind: panel.kind,
                title: panel.title,
                region: panel.region,
                visibility: panel.visibility,
                sortOrder: panel.sortOrder,
                sizeFraction: panel.sizeFraction,
                tabGroupID: panel.tabGroupID,
                isMaximized: false,
                configuration: panel.configuration
            )
        }
        let copy = AtheerWorkspace(name: copyName, layout: source.layout, panels: copiedPanels)
        workspaces.append(copy)
        activeWorkspaceID = copy.id
        persist()
        return copy.id
    }

    func renameActiveWorkspace(_ name: String) {
        let normalized = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return }
        updateActiveWorkspace { $0.name = normalized }
    }

    func removeWorkspace(_ id: UUID) {
        guard workspaces.count > 1, let index = workspaces.firstIndex(where: { $0.id == id }) else { return }
        workspaces.remove(at: index)
        if activeWorkspaceID == id {
            activeWorkspaceID = workspaces[min(index, workspaces.count - 1)].id
        }
        persist()
    }

    @discardableResult
    func addPanel(_ kind: WorkspacePanelKind, region: WorkspacePanelRegion? = nil) -> UUID? {
        guard let workspace = activeWorkspace else { return nil }
        let destination = region ?? defaultRegion(for: kind)
        let order = (workspace.panels
            .filter { $0.region == destination }
            .map(\\.sortOrder)
            .max() ?? -1) + 1
        let panel = WorkspacePanel(kind: kind, region: destination, sortOrder: order)
        updateActiveWorkspace { $0.panels.append(panel) }
        return panel.id
    }

    func setVisibility(_ visibility: WorkspacePanelVisibility, for panelID: UUID) {
        updatePanel(panelID) { panel in
            panel.visibility = visibility
            if visibility != .visible { panel.isMaximized = false }
        }
    }

    func hidePanel(_ panelID: UUID) { setVisibility(.hidden, for: panelID) }
    func showPanel(_ panelID: UUID) { setVisibility(.visible, for: panelID) }
    func closePanel(_ panelID: UUID) { setVisibility(.closed, for: panelID) }

    func removePanel(_ panelID: UUID) {
        updateActiveWorkspace { workspace in
            workspace.panels.removeAll { $0.id == panelID }
        }
    }

    func movePanel(_ panelID: UUID, to region: WorkspacePanelRegion, at index: Int? = nil) {
        updateActiveWorkspace { workspace in
            guard let sourceIndex = workspace.panels.firstIndex(where: { $0.id == panelID }) else {
                return
            }

            let sourceRegion = workspace.panels[sourceIndex].region
            workspace.panels[sourceIndex].region = region
            workspace.panels[sourceIndex].visibility = .visible
            workspace.panels[sourceIndex].isMaximized = false

            func orderedPanelIndices(in targetRegion: WorkspacePanelRegion) -> [Int] {
                workspace.panels.indices
                    .filter { workspace.panels[$0].region == targetRegion }
                    .sorted {
                        let left = workspace.panels[$0]
                        let right = workspace.panels[$1]

                        if left.sortOrder == right.sortOrder {
                            return left.id.uuidString < right.id.uuidString
                        }

                        return left.sortOrder < right.sortOrder
                    }
            }

            // Compact the source region so future additions cannot collide with gaps.
            if sourceRegion != region {
                for (order, panelIndex) in orderedPanelIndices(in: sourceRegion).enumerated() {
                    workspace.panels[panelIndex].sortOrder = order
                }
            }

            let targetIndices = orderedPanelIndices(in: region)
                .filter { workspace.panels[$0].id != panelID }
            let insertion = min(max(index ?? targetIndices.count, 0), targetIndices.count)
            var orderedIDs = targetIndices.map { workspace.panels[$0].id }
            orderedIDs.insert(panelID, at: insertion)

            for (order, id) in orderedIDs.enumerated() {
                guard let panelIndex = workspace.panels.firstIndex(where: { $0.id == id }) else {
                    continue
                }
                workspace.panels[panelIndex].sortOrder = order
            }
        }
    }

    func setOrientation(_ orientation: WorkspaceSplitOrientation, primary: Bool) {
        updateActiveWorkspace { workspace in
            if primary {
                workspace.layout.primaryOrientation = orientation
            } else {
                workspace.layout.secondaryOrientation = orientation
            }
        }
    }

    func setSidebarVisible(_ visible: Bool) {
        updateActiveWorkspace { $0.layout.sidebarVisible = visible }
    }

    func setSidebarWidth(_ width: Double) {
        updateActiveWorkspace { $0.layout.sidebarWidth = min(max(width, 180), 360) }
    }

    func setBottomPanelHeight(_ height: Double) {
        updateActiveWorkspace { $0.layout.bottomPanelHeight = min(max(height, 120), 520) }
    }

    func setPanelSize(_ fraction: Double, for panelID: UUID) {
        updatePanel(panelID) { $0.sizeFraction = min(max(fraction, 0.15), 1.0) }
    }

    func toggleMaximize(_ panelID: UUID) {
        updatePanel(panelID) { panel in
            if panel.isMaximized {
                if let previousRegion = panel.restoreRegion { panel.region = previousRegion }
                panel.restoreRegion = nil
                panel.isMaximized = false
            } else {
                panel.restoreRegion = panel.region
                panel.region = .center
                panel.visibility = .visible
                panel.isMaximized = true
            }
        }
    }

    func resetActiveWorkspaceLayout() {
        updateActiveWorkspace { workspace in
            workspace.layout = WorkspaceLayout()
            workspace.panels = WorkspacePanel.defaultPanels
        }
    }

    private func defaultRegion(for kind: WorkspacePanelKind) -> WorkspacePanelRegion {
        switch kind {
        case .chart: return .center
        case .marketWatch, .orderEntry, .news, .systemStatus: return .right
        case .positions, .orders, .history, .journal, .performance: return .bottom
        }
    }

    private func updatePanel(_ id: UUID, mutation: (inout WorkspacePanel) -> Void) {
        updateActiveWorkspace { workspace in
            guard let index = workspace.panels.firstIndex(where: { $0.id == id }) else { return }
            mutation(&workspace.panels[index])
        }
    }

    private func updateActiveWorkspace(_ mutation: (inout AtheerWorkspace) -> Void) {
        guard let index = workspaces.firstIndex(where: { $0.id == activeWorkspaceID }) else { return }
        mutation(&workspaces[index])
        workspaces[index].updatedAt = Date()
        persist()
    }

    private func persist() {
        let document = WorkspaceDocument(
            schemaVersion: WorkspaceDocument.currentSchemaVersion,
            activeWorkspaceID: activeWorkspaceID,
            workspaces: workspaces
        )
        do {
            try persistence.save(document)
            persistenceError = nil
        } catch {
            persistenceError = error.localizedDescription
        }
    }
}


final class InMemoryWorkspacePersistence: WorkspacePersistence {

    private var storedDocument: WorkspaceDocument?

    init() {}

    func load() throws -> WorkspaceDocument {
        guard let document = storedDocument else {
            throw CocoaError(.fileNoSuchFile)
        }

        try document.validate()
        return document
    }

    func save(_ document: WorkspaceDocument) throws {
        try document.validate()
        storedDocument = document
    }
}
