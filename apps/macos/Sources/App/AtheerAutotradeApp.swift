import SwiftUI

@main
struct AtheerAutotradeApp: App {
    var body: some Scene {
        WindowGroup {
            ApplicationShellView()
                .frame(minWidth: 1040, minHeight: 680)
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
    }
}
