import Foundation
import PencilKit

// MARK: - Diagnostics Runner
class DiagnosticsRunner {
    static func runAll() {
        print("\n--- SketchSite Startup Diagnostics ---")
        // Run a subset of diagnostics synchronously for startup validation
        // ExportService
        let url = ExportService.shared.export(code: "<h1>Hello</h1>", filename: "test.html")
        print("ExportService: Export HTML file URL: \(url?.absoluteString ?? "nil")")
        // RectangleComponentDetector
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let comps = RectangleComponentDetector.detectComponents(rects: [rect], canvasSize: CGSize(width: 200, height: 200))
        print("RectangleComponentDetector: Detected \(comps.count) component(s)")
        // LayoutDescriptor
        let comp = DetectedComponent(rect: rect, type: .ui(.button), label: "Button")
        let desc = LayoutDescriptor.describe(components: [comp], canvasSize: CGSize(width: 200, height: 200))
        print("LayoutDescriptor: \(desc)")
        // AnnotationProcessor
        let annotationResult = AnnotationProcessor.extractAnnotations(from: [])
        print("AnnotationProcessor: Extracted \(annotationResult.count) annotation(s)")
        // CanvasSnapshot
        let canvas = PKCanvasView()
        let image = canvas.snapshotImage()
        print("CanvasSnapshot: Snapshot image is \(image == nil ? "nil" : "not nil")")
        print("--- Diagnostics Complete ---\n")
    }
} 