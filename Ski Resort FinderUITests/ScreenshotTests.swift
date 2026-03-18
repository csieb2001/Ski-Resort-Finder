import XCTest

final class ScreenshotTests: XCTestCase {

    var app: XCUIApplication!
    let screenshotDir = "/Users/christophersiebert/Documents/Ski resort Finder/Ski Resort Finder/screenshots/raw"

    override func setUpWithError() throws {
        continueAfterFailure = true
        app = XCUIApplication()
        app.launchArguments = ["-hasSeenWelcome", "true"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func saveScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to disk
        let imageData = screenshot.pngRepresentation
        let filePath = "\(screenshotDir)/\(name).png"
        let url = URL(fileURLWithPath: filePath)
        try? imageData.write(to: url)
    }

    @MainActor
    func test01_HomeScreen() throws {
        // Wait for main screen to fully load
        sleep(5)
        saveScreenshot(name: "01_home")
    }

    @MainActor
    func test02_ResortPicker() throws {
        sleep(3)

        // Tap on the resort selection area
        let resortButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Tippen' OR label CONTAINS[c] 'auswählen' OR label CONTAINS[c] 'auszuwählen'")).firstMatch

        if resortButton.waitForExistence(timeout: 5) {
            resortButton.tap()
            sleep(2)
            saveScreenshot(name: "04_resort_picker")
            return
        }

        // Try alternative: look for the Skigebiet row
        let skigebietText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Skigebiet' OR label CONTAINS[c] 'Tippen'")).firstMatch
        if skigebietText.waitForExistence(timeout: 3) {
            skigebietText.tap()
            sleep(2)
            saveScreenshot(name: "04_resort_picker")
            return
        }

        // Fallback: try tapping any element that looks like a resort selector
        let anyButton = app.buttons.allElementsBoundByIndex
        for button in anyButton {
            if button.label.contains("Skigebiet") || button.label.contains("Tippen") || button.label.contains("auswähl") {
                button.tap()
                sleep(2)
                saveScreenshot(name: "04_resort_picker")
                return
            }
        }
    }

    @MainActor
    func test03_Top3Categories() throws {
        sleep(3)

        // Switch to Pisten tab in Top 3 card
        let pistenButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Pisten'")).firstMatch
        if pistenButton.waitForExistence(timeout: 5) {
            pistenButton.tap()
            sleep(1)
            saveScreenshot(name: "05_top3_pisten")
        }

        // Switch to Hotels tab
        let hotelsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Hotels'")).firstMatch
        if hotelsButton.waitForExistence(timeout: 3) {
            hotelsButton.tap()
            sleep(1)
            saveScreenshot(name: "05b_top3_hotels")
        }
    }

    @MainActor
    func test04_ResortDetail() throws {
        sleep(3)

        // Try to tap on a resort from the Top 3 list
        let resortNames = ["Val d'Isère", "Les Arcs", "Courchevel", "Chamonix", "St. Anton", "Verbier", "Zermatt", "Kitzbühel"]

        for name in resortNames {
            let resortText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", name)).firstMatch
            if resortText.waitForExistence(timeout: 2) {
                resortText.tap()
                sleep(3)
                saveScreenshot(name: "06_resort_detail")

                // Try to scroll down to see more detail
                let scrollViews = app.scrollViews.firstMatch
                if scrollViews.exists {
                    scrollViews.swipeUp()
                    sleep(1)
                    saveScreenshot(name: "06b_resort_detail_scrolled")
                }
                return
            }
        }
    }

    @MainActor
    func test05_ScrolledHome() throws {
        sleep(3)

        // Scroll down on home screen to see more content
        let scrollView = app.scrollViews.firstMatch
        if scrollView.exists {
            scrollView.swipeUp()
            sleep(1)
            saveScreenshot(name: "03_home_scrolled")
        }
    }

    @MainActor
    func test06_AboutScreen() throws {
        sleep(3)

        // Look for the info/about button (i icon in the header)
        let infoButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'info' OR label CONTAINS[c] 'about' OR label CONTAINS[c] 'Info'")).firstMatch

        if infoButton.waitForExistence(timeout: 5) {
            infoButton.tap()
            sleep(2)
            saveScreenshot(name: "07_about")
        }
    }

    @MainActor
    func test07_AllRankings() throws {
        sleep(3)

        // Look for "Alle Rankings anzeigen" button
        let allRankingsButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Rankings' OR label CONTAINS[c] 'Alle'")).firstMatch

        if !allRankingsButton.waitForExistence(timeout: 3) {
            // Try static texts
            let allRankingsText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Rankings'")).firstMatch
            if allRankingsText.waitForExistence(timeout: 3) {
                allRankingsText.tap()
                sleep(2)
                saveScreenshot(name: "08_all_rankings")
                return
            }
        } else {
            allRankingsButton.tap()
            sleep(2)
            saveScreenshot(name: "08_all_rankings")
        }
    }
}
