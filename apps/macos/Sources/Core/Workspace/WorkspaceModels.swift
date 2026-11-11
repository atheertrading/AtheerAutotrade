
import Foundation

/// Stable identifiers and presentation state for user-configurable workspaces.
/// This model deliberately contains no broker, order, strategy, or execution state.

struct AtheerWorkspace: Codable, Identifiable, Equatable {
    let id: UUID
    var name: String
    var layout: WorkspaceLayout
    var panels: [WorkspacePanel]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        layout: WorkspaceLayout = WorkspaceLayout(),
        panels: [WorkspacePanel] = WorkspacePanel.defaultPanels,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.layout = layout
        self.panels = panels
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

enum WorkspaceSplitOrientation: String, Codable, CaseIterable, Identifiable {
    case horizontal
    case vertical

    var id: String { rawValue }

    var title: String {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        }
    }

    var symbol: String {
        switch self {
        case .horizontal: return "rectangle.split.2x1"
        case .vertical: return "rectangle.split.1x2"
        }
    }
}

enum WorkspacePanelRegion: String, Codable, CaseIterable, Identifiable {
    case left
    case center
    case right
    case bottom
    case floating

    var id: String { rawValue }
}

enum WorkspacePanelVisibility: String, Codable {
    case visible
    case hidden
    case closed
}

enum WorkspacePanelKind: String, Codable, CaseIterable, Identifiable {
    case chart
    case marketWatch
    case orderEntry
    case positions
    case orders
    case history
    case journal
    case news
    case performance
    case systemStatus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .chart: return "Chart"
        case .marketWatch: return "Market Watch"
        case .orderEntry: return "Order Entry"
        case .positions: return "Positions"
        case .orders: return "Orders"
        case .history: return "History"
        case .journal: return "Journal"
        case .news: return "News"
        case .performance: return "Performance"
        case .systemStatus: return "System Status"
        }
    }

    var symbol: String {
        switch self {
        case .chart: return "chart.xyaxis.line"
        case .marketWatch: return "list.bullet.rectangle"
        case .orderEntry: return "arrow.left.arrow.right"
        case .positions: return "rectangle.stack"
        case .orders: return "list.bullet.clipboard"
        case .history: return "clock.arrow.circlepath"
        case .journal: return "book.closed"
        case .news: return "newspaper"
        case .performance: return "chart.bar.xaxis"
        case .systemStatus: return "waveform.path"
        }
    }
}

struct WorkspaceLayout: Codable, Equatable {
    var primaryOrientation: WorkspaceSplitOrientation
    var secondaryOrientation: WorkspaceSplitOrientation
    var sidebarVisible: Bool
    var sidebarWidth: Double
    var bottomPanelHeight: Double

    init(
        primaryOrientation: WorkspaceSplitOrientation = .horizontal,
        secondaryOrientation: WorkspaceSplitOrientation = .vertical,
        sidebarVisible: Bool = true,
        sidebarWidth: Double = 248,
        bottomPanelHeight: Double = 220
    ) {
        self.primaryOrientation = primaryOrientation
        self.secondaryOrientation = secondaryOrientation
        self.sidebarVisible = sidebarVisible
        self.sidebarWidth = sidebarWidth
        self.bottomPanelHeight = bottomPanelHeight
    }
}

struct WorkspacePanel: Codable, Identifiable, Equatable {
    let id: UUID
    var kind: WorkspacePanelKind
    var title: String
    var region: WorkspacePanelRegion
    var visibility: WorkspacePanelVisibility
    var sortOrder: Int
    var sizeFraction: Double
    var tabGroupID: UUID?
    var isMaximized: Bool

    var restoreRegion: WorkspacePanelRegion?
    var restoreSortOrder: Int?
    var restoreSizeFraction: Double?
    var restoreTabGroupID: UUID?

    var configuration: [String: String]

    init(
        id: UUID = UUID(),
        kind: WorkspacePanelKind,
        title: String? = nil,
        region: WorkspacePanelRegion,
        visibility: WorkspacePanelVisibility = .visible,
        sortOrder: Int = 0,
        sizeFraction: Double = 1,
        tabGroupID: UUID? = nil,
        isMaximized: Bool = false,
        restoreRegion: WorkspacePanelRegion? = nil,
        restoreSortOrder: Int? = nil,
        restoreSizeFraction: Double? = nil,
        restoreTabGroupID: UUID? = nil,
        configuration: [String: String] = [:]
    ) {
        self.id = id
        self.kind = kind
        self.title = title ?? kind.title
        self.region = region
        self.visibility = visibility
        self.sortOrder = sortOrder
        self.sizeFraction = sizeFraction
        self.tabGroupID = tabGroupID
        self.isMaximized = isMaximized
        self.restoreRegion = restoreRegion
        self.restoreSortOrder = restoreSortOrder
        self.restoreSizeFraction = restoreSizeFraction
        self.restoreTabGroupID = restoreTabGroupID
        self.configuration = configuration
    }

    static var defaultPanels: [WorkspacePanel] {
        [
            WorkspacePanel(kind: .chart, region: .center, sortOrder: 0, sizeFraction: 0.72),
            WorkspacePanel(kind: .marketWatch, region: .right, sortOrder: 0, sizeFraction: 0.55),
            WorkspacePanel(kind: .orderEntry, region: .right, sortOrder: 1, sizeFraction: 0.45),
            WorkspacePanel(kind: .positions, region: .bottom, sortOrder: 0)
        ]
    }
}

struct WorkspaceDocument: Codable {
    var schemaVersion: Int
    var activeWorkspaceID: UUID
    var workspaces: [AtheerWorkspace]

    static let currentSchemaVersion = 1

    func validate() throws {
        guard schemaVersion == Self.currentSchemaVersion else {
            throw WorkspaceDocumentError.unsupportedSchemaVersion(
                schemaVersion,
                supported: Self.currentSchemaVersion
            )
        }

        guard !workspaces.isEmpty else {
            throw WorkspaceDocumentError.emptyWorkspaceCollection
        }

        let workspaceIDs = workspaces.map(\.id)

        guard Set(workspaceIDs).count == workspaceIDs.count else {
            throw WorkspaceDocumentError.duplicateWorkspaceIdentifier
        }

        guard workspaces.contains(where: { $0.id == activeWorkspaceID }) else {
            throw WorkspaceDocumentError.activeWorkspaceNotFound
        }

        for workspace in workspaces {
            guard !workspace.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw WorkspaceDocumentError.emptyWorkspaceName(workspace.id)
            }

            guard workspace.layout.sidebarWidth.isFinite,
                  (180...360).contains(workspace.layout.sidebarWidth) else {
                throw WorkspaceDocumentError.invalidSidebarWidth(workspace.id)
            }

            guard workspace.layout.bottomPanelHeight.isFinite,
                  (120...520).contains(workspace.layout.bottomPanelHeight) else {
                throw WorkspaceDocumentError.invalidBottomPanelHeight(workspace.id)
            }

            let panelIDs = workspace.panels.map(\.id)

            guard Set(panelIDs).count == panelIDs.count else {
                throw WorkspaceDocumentError.duplicatePanelIdentifier(workspace.id)
            }

            for panel in workspace.panels {
                guard panel.sortOrder >= 0 else {
                    throw WorkspaceDocumentError.invalidPanelSortOrder(panel.id)
                }

                guard panel.sizeFraction.isFinite,
                      (0.15...1.0).contains(panel.sizeFraction) else {
                    throw WorkspaceDocumentError.invalidPanelSize(panel.id)
                }

                if let order = panel.restoreSortOrder, order < 0 {
                    throw WorkspaceDocumentError.invalidPanelSortOrder(panel.id)
                }

                if let size = panel.restoreSizeFraction,
                   (!size.isFinite || !(0.15...1.0).contains(size)) {
                    throw WorkspaceDocumentError.invalidPanelSize(panel.id)
                }

                if panel.isMaximized && panel.restoreRegion == nil {
                    throw WorkspaceDocumentError.missingMaximizeRestoreState(panel.id)
                }
            }
        }
    }
}

enum WorkspaceDocumentError: LocalizedError {
    case unsupportedSchemaVersion(Int, supported: Int)
    case emptyWorkspaceCollection
    case duplicateWorkspaceIdentifier
    case activeWorkspaceNotFound
    case emptyWorkspaceName(UUID)
    case invalidSidebarWidth(UUID)
    case invalidBottomPanelHeight(UUID)
    case duplicatePanelIdentifier(UUID)
    case invalidPanelSortOrder(UUID)
    case invalidPanelSize(UUID)
    case missingMaximizeRestoreState(UUID)

    var errorDescription: String? {
        switch self {
        case let .unsupportedSchemaVersion(found, supported):
            return "Unsupported workspace schema version \(found). Supported: \(supported)."
        case .emptyWorkspaceCollection:
            return "The workspace document contains no workspaces."
        case .duplicateWorkspaceIdentifier:
            return "Duplicate workspace identifiers were found."
        case .activeWorkspaceNotFound:
            return "The active workspace does not exist in the document."
        case let .emptyWorkspaceName(id):
            return "Workspace \(id.uuidString) has an empty name."
        case let .invalidSidebarWidth(id):
            return "Workspace \(id.uuidString) has an invalid sidebar width."
        case let .invalidBottomPanelHeight(id):
            return "Workspace \(id.uuidString) has an invalid bottom panel height."
        case let .duplicatePanelIdentifier(id):
            return "Workspace \(id.uuidString) contains duplicate panel identifiers."
        case let .invalidPanelSortOrder(id):
            return "Panel \(id.uuidString) has an invalid sort order."
        case let .invalidPanelSize(id):
            return "Panel \(id.uuidString) has an invalid size fraction."
        case let .missingMaximizeRestoreState(id):
            return "Maximized panel \(id.uuidString) has no restore region."
        }
    }
}

