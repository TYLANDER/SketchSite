//
//  SketchSiteTests.swift
//  SketchSiteTests
//
//  Created by Tyler Schmidt on 6/15/25.
//

import Testing
import XCTest
@testable import SketchSite

/// Unit tests for the SketchSite app.
final class SketchSiteTests: XCTestCase {
    // MARK: - ChatGPTService
    func testChatGPTServiceHandlesInvalidAPIKey() async {
        let exp = expectation(description: "Completion called")
        ChatGPTService.shared.generateCode(prompt: "Test", model: "gpt-4o", conversation: nil) { result in
            switch result {
            case .success(_):
                XCTFail("Should not succeed with invalid API key")
            case .failure(let error):
                XCTAssertNotNil(error)
            }
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 10)
    }

    // MARK: - VisionAnalysisService
    func testVisionAnalysisHandlesNilImage() async {
        let service = VisionAnalysisService()
        let exp = expectation(description: "Completion called")
        service.detectRectangles(in: UIImage()) { rects in
            XCTAssertNotNil(rects)
            exp.fulfill()
        }
        await fulfillment(of: [exp], timeout: 5)
    }

    // MARK: - ExportService
    func testExportServiceExportsHTML() {
        let url = ExportService.shared.export(code: "<h1>Hello</h1>", filename: "test.html")
        XCTAssertNotNil(url)
    }

    // MARK: - RectangleComponentDetector
    func testRectangleComponentDetectorDetectsSingle() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let comps = RectangleComponentDetector.detectComponents(rects: [rect], canvasSize: CGSize(width: 200, height: 200))
        XCTAssertEqual(comps.count, 1)
    }

    // MARK: - LayoutDescriptor
    func testLayoutDescriptorDescribes() {
        let rect = CGRect(x: 0, y: 0, width: 100, height: 50)
        let comp = DetectedComponent(rect: rect, type: .ui(.button), label: "Button")
        let desc = LayoutDescriptor.describe(components: [comp], canvasSize: CGSize(width: 200, height: 200))
        XCTAssertTrue(desc.contains("Button"))
    }

    // MARK: - AnnotationProcessor
    func testAnnotationProcessorExtracts() {
        // Simulate a VNRecognizedTextObservation array if possible, or just check empty
        let result = AnnotationProcessor.extractAnnotations(from: [])
        XCTAssertEqual(result.count, 0)
    }

    // MARK: - CanvasSnapshot
    func testCanvasSnapshotReturnsImage() {
        let canvas = PKCanvasView()
        let image = canvas.snapshotImage()
        XCTAssertNotNil(image)
    }
}

// MARK: - Diagnostics Runner
class DiagnosticsRunner {
    static func runAll() {
        print("\n--- SketchSite Startup Diagnostics ---")
        // Run a subset of tests synchronously for startup validation
        let tests = SketchSiteTests()
        tests.testExportServiceExportsHTML()
        tests.testRectangleComponentDetectorDetectsSingle()
        tests.testLayoutDescriptorDescribes()
        tests.testAnnotationProcessorExtracts()
        tests.testCanvasSnapshotReturnsImage()
        print("--- Diagnostics Complete ---\n")
    }
}
