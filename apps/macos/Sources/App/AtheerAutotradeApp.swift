import AppKit
import SwiftUI

@main
struct AtheerAutotradeApp: App {
    @NSApplicationDelegateAdaptor(AtheerAutotradeAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ApplicationShellView()
                .frame(minWidth: 1040, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}

private final class AtheerAutotradeAppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillTerminate(_ notification: Notification) {
        BackendProcessSupervisor.shared.stopForApplicationTermination()
    }
}
