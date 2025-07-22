import SwiftUI

/// The main entry point for the SketchSite app.
@main
struct SketchSiteApp: App {
    init() {
        DiagnosticsRunner.runAll()
        
        // TEMPORARY: Uncomment the line below, add your real API keys, build, and check console output
        // ProductionAPIKeys.generateObfuscatedArrays(openAIKey: "your-openai-key-here", anthropicKey: "your-anthropic-key-here")
    }
    var body: some Scene {
        WindowGroup {
            CanvasContainerView()
        }
    }
} 