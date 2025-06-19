import SwiftUI

/// The main entry point for the SketchSite app.
@main
struct SketchSiteApp: App {
    var body: some Scene {
        WindowGroup {
            NavigationView {
                CanvasContainerView()
            }
        }
    }
}
