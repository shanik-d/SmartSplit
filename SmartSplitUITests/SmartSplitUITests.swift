//
//  SmartSplitUITests.swift
//  SmartSplitUITests
//
//  Created by Shanik Dassenaike on 19/11/2023.
//

import XCTest

final class SmartSplitUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testNextButtonEnablesAfterEnteringPrice() throws {
        let app = XCUIApplication()
        app.launch()

        let nextButton = app.buttons["Next"]
        XCTAssertFalse(nextButton.isEnabled, "Next should be disabled before any price is entered")

        let priceField = app.textFields.element(boundBy: 1) // first price field in the list
        XCTAssertTrue(priceField.waitForExistence(timeout: 2), "Price field should exist on launch")

        priceField.tap()
        priceField.typeText("12.50")

        XCTAssertTrue(nextButton.isEnabled, "Next should enable once a valid price is entered")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
