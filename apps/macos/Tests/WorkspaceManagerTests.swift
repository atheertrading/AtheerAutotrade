import XCTest
@testable import AtheerAutotrade

final class WorkspaceManagerTests: XCTestCase {

    func testMovingPanelCompactsSourceAndDestinationRegions() throws {
        let manager = makeManager()
        let workspace = try XCTUnwrap(manager.activeWorkspace)
        let marketWatch = try XCTUnwrap(
            workspace.panels.first { $0.kind == .marketWatch }
        )
        let orderEntryID = try XCTUnwrap(
            workspace.panels.first { $0.kind == .orderEntry }?.id
        )
        let chartID = try XCTUnwrap(
            workspace.panels.first { $0.kind == .chart }?.id
        )

        manager.movePanel(marketWatch.id, to: .center, at: 0)

        let updated = try XCTUnwrap(manager.activeWorkspace)
        let sourcePanel = try XCTUnwrap(
            updated.panels.first { $0.id == orderEntryID }
        )
        let movedPanel = try XCTUnwrap(
            updated.panels.first { $0.id == marketWatch.id }
        )
        let existingCenterPanel = try XCTUnwrap(
            updated.panels.first { $0.id == chartID }
        )

        XCTAssertEqual(sourcePanel.region, .right)
        XCTAssertEqual(sourcePanel.sortOrder, 0)
        XCTAssertEqual(movedPanel.region, .center)
        XCTAssertEqual(movedPanel.sortOrder, 0)
        XCTAssertEqual(existingCenterPanel.sortOrder, 1)
    }

    func testAddingPanelUsesHighestExistingSortOrder() throws {
        let manager = makeManager()
        let workspace = try XCTUnwrap(manager.activeWorkspace)
        let marketWatchID = try XCTUnwrap(
            workspace.panels.first { $0.kind == .marketWatch }?.id
        )

        manager.closePanel(marketWatchID)
        let newPanelID = try XCTUnwrap(manager.addPanel(.news, region: .right))

        let newPanel = try XCTUnwrap(
            manager.activeWorkspace?.panels.first { $0.id == newPanelID }
        )

        XCTAssertEqual(newPanel.sortOrder, 2)
    }

    func testReorderingWithinSameRegionProducesContiguousSortOrder() throws {
        let manager = makeManager()
        let workspace = try XCTUnwrap(manager.activeWorkspace)
        let marketWatchID = try XCTUnwrap(
            workspace.panels.first { $0.kind == .marketWatch }?.id
        )
        let orderEntryID = try XCTUnwrap(
            workspace.panels.first { $0.kind == .orderEntry }?.id
        )

        manager.movePanel(orderEntryID, to: .right, at: 0)

        let updated = try XCTUnwrap(manager.activeWorkspace)
        let orderedPanels = updated.panels
            .filter { $0.region == .right }
            .sorted { $0.sortOrder < $1.sortOrder }

        XCTAssertEqual(orderedPanels.map(\.id), [orderEntryID, marketWatchID])
        XCTAssertEqual(orderedPanels.map(\.sortOrder), [0, 1])
    }

    func testWorkspaceChangesPersistAndRestore() throws {
        let persistence = InMemoryWorkspacePersistence()
        let firstManager = WorkspaceManager(persistence: persistence)

        let newPanelID = try XCTUnwrap(
            firstManager.addPanel(.news, region: .center)
        )
        firstManager.setSidebarWidth(300)

        let restoredManager = WorkspaceManager(persistence: persistence)
        let restoredWorkspace = try XCTUnwrap(restoredManager.activeWorkspace)
        let restoredPanel = try XCTUnwrap(
            restoredWorkspace.panels.first { $0.id == newPanelID }
        )

        XCTAssertEqual(restoredWorkspace.layout.sidebarWidth, 300)
        XCTAssertEqual(restoredPanel.kind, .news)
        XCTAssertEqual(restoredPanel.region, .center)
    }

    private func makeManager() -> WorkspaceManager {
        WorkspaceManager(persistence: InMemoryWorkspacePersistence())
    }
}
