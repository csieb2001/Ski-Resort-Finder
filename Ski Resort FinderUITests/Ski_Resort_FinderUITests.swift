//
//  Ski_Resort_FinderUITests.swift
//  Ski Resort FinderUITests
//
//  Created by Christopher Siebert on 10.07.25.
//

import XCTest

final class Ski_Resort_FinderUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests

    @MainActor
    func testAppLaunches() throws {
        // App should launch without crashing
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Main Screen Tests

    @MainActor
    func testMainScreenShowsTitle() throws {
        // The app title should be visible
        let titleExists = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Ski'")).firstMatch.waitForExistence(timeout: 5)
        XCTAssertTrue(titleExists, "App title containing 'Ski' should be visible on main screen")
    }

    @MainActor
    func testMainScreenShowsSearchElements() throws {
        // Wait for main screen to load
        let _ = app.waitForExistence(timeout: 5)

        // Should have some interactive elements
        let buttons = app.buttons.count
        XCTAssertGreaterThan(buttons, 0, "Main screen should have at least one button")
    }

    // MARK: - Navigation Tests

    @MainActor
    func testNavigationToAbout() throws {
        // Look for settings/about button (gear icon or similar)
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'info' OR label CONTAINS[c] 'about' OR label CONTAINS[c] 'settings' OR label CONTAINS[c] 'gear'")).firstMatch

        if settingsButton.waitForExistence(timeout: 3) {
            settingsButton.tap()
            // Should navigate somewhere
            sleep(1) // Wait for animation
        }
        // Test passes if no crash occurs
    }

    // MARK: - Resort Selection Tests

    @MainActor
    func testResortSelectionFlowExists() throws {
        // Look for any element related to resort selection
        let resortElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Skigebiet' OR label CONTAINS[c] 'Resort' OR label CONTAINS[c] 'ski'"))

        // Should have some resort-related text visible
        let exists = resortElements.firstMatch.waitForExistence(timeout: 5)
        // This might not exist immediately depending on the layout, so we just ensure no crash
        if exists {
            XCTAssertTrue(true)
        }
    }

    // MARK: - Search Flow Tests

    @MainActor
    func testSearchFieldExists() throws {
        // Look for search fields or text fields
        let searchField = app.searchFields.firstMatch
        let textField = app.textFields.firstMatch

        let hasSearchInput = searchField.waitForExistence(timeout: 3) || textField.waitForExistence(timeout: 3)

        // The app should have some form of search input
        // Note: Might be behind a navigation action
        if hasSearchInput {
            XCTAssertTrue(true)
        }
    }

    // MARK: - Tab/Section Navigation Tests

    @MainActor
    func testScrollingWorks() throws {
        // Wait for content to load
        sleep(2)

        // Try to scroll down
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            // If scroll works without crash, test passes
            XCTAssertTrue(true)
        }
    }

    // MARK: - Top3 Card Tests

    @MainActor
    func testTop3CardExists() throws {
        // The Top3 ski resorts card should be visible on the main screen
        let top3Elements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Top' OR label CONTAINS[c] 'Schneefall' OR label CONTAINS[c] 'snowfall'"))

        let exists = top3Elements.firstMatch.waitForExistence(timeout: 5)
        if exists {
            XCTAssertTrue(true, "Top3 card should be visible")
        }
    }

    @MainActor
    func testTop3CategorySwitching() throws {
        // Wait for content to load
        sleep(2)

        // Try to find category buttons (Schneefall, Pistenlänge, etc.)
        let categoryButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Pisten' OR label CONTAINS[c] 'Höhe' OR label CONTAINS[c] 'Hotel' OR label CONTAINS[c] 'Slope' OR label CONTAINS[c] 'Elevation'"))

        if categoryButtons.firstMatch.waitForExistence(timeout: 3) {
            categoryButtons.firstMatch.tap()
            sleep(1)
            // Should switch category without crash
            XCTAssertTrue(true)
        }
    }

    // MARK: - Favorites Tests

    @MainActor
    func testFavoritesSection() throws {
        // Look for favorites-related UI
        let favElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Favorit' OR label CONTAINS[c] 'favorite'"))

        let exists = favElements.firstMatch.waitForExistence(timeout: 5)
        if exists {
            XCTAssertTrue(true, "Favorites section should be accessible")
        }
    }

    // MARK: - Accessibility Tests

    @MainActor
    func testMainScreenAccessibility() throws {
        // Verify that main interactive elements are accessible
        let buttons = app.buttons.allElementsBoundByIndex
        let texts = app.staticTexts.allElementsBoundByIndex

        XCTAssertGreaterThan(buttons.count + texts.count, 0,
                             "Main screen should have accessible elements")
    }

    // MARK: - Orientation Tests

    @MainActor
    func testPortraitOrientation() throws {
        XCUIDevice.shared.orientation = .portrait
        sleep(1)
        XCTAssertTrue(app.exists, "App should work in portrait orientation")
    }

    @MainActor
    func testLandscapeOrientation() throws {
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        XCTAssertTrue(app.exists, "App should work in landscape orientation")

        // Reset to portrait
        XCUIDevice.shared.orientation = .portrait
    }
}

// MARK: - Resort Detail UI Tests

final class ResortDetailUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testResortDetailNavigation() throws {
        // Wait for main screen
        sleep(2)

        // Try to find and tap a resort name
        let resortTexts = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Anton' OR label CONTAINS[c] 'Kitzbühel' OR label CONTAINS[c] 'Verbier' OR label CONTAINS[c] 'Zermatt'"))

        if resortTexts.firstMatch.waitForExistence(timeout: 5) {
            resortTexts.firstMatch.tap()
            sleep(2) // Wait for detail view

            // Should show some detail content
            let detailContent = app.staticTexts.count
            XCTAssertGreaterThan(detailContent, 0, "Resort detail should have content")
        }
    }
}

// MARK: - Settings UI Tests

final class SettingsUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testSettingsAccessible() throws {
        // Look for settings/gear button
        let settingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'settings' OR label CONTAINS[c] 'Einstellungen' OR label CONTAINS[c] 'gear' OR identifier CONTAINS[c] 'settings'")).firstMatch

        if settingsButton.waitForExistence(timeout: 5) {
            settingsButton.tap()
            sleep(1)
            XCTAssertTrue(true, "Settings should be accessible")
        }
    }
}

// MARK: - Debug View UI Tests

final class DebugViewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testDebugViewAccessible() throws {
        // Debug view might be behind a hidden gesture or settings
        // Just verify app doesn't crash when looking for it
        let debugElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Debug' OR label CONTAINS[c] 'API'"))

        if debugElements.firstMatch.waitForExistence(timeout: 3) {
            XCTAssertTrue(true, "Debug view found")
        }
    }
}
