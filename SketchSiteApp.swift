import SwiftUI

/// The main entry point for the SketchSite app.
@main
struct SketchSiteApp: App {
    init() {
        DiagnosticsRunner.runAll()
    }
    var body: some Scene {
        WindowGroup {
            NavigationView {
                CanvasContainerView()
            }
        }
    }
}
