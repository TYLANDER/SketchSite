import SwiftUI

/// The main entry point for the SketchSite app.
@main
struct SketchSiteApp: App {
    init() {
        DiagnosticsRunner.runAll()
        
        #if DEBUG
        // PRODUCTION API KEY GENERATOR
        // Uncomment the line below after adding your real API keys to GenerateAPIKeys.swift
        // GenerateAPIKeys.generateProductionKeys()
        #endif
    }
    var body: some Scene {
        WindowGroup {
            CanvasContainerView()
        }
    }
} 