//
//  SketchSiteUITestsLaunchTests.swift
//  SketchSiteUITests
//
//  Created by Tyler Schmidt on 6/15/25.
//

import XCTest

/// UI launch tests for the SketchSite app.
final class SketchSiteUITestsLaunchTests: XCTestCase {

    /// Indicates whether the test runs for each UI configuration.
    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// Tests app launch and captures a screenshot.
    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
