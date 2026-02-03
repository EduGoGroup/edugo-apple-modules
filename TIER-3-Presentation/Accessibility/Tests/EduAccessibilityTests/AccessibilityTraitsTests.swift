import XCTest
@testable import EduAccessibility

@MainActor
final class AccessibilityTraitsTests: XCTestCase {

    // MARK: - Basic Traits

    func testBasicTraitCreation() {
        let buttonTrait = AccessibilityTraits.button
        XCTAssertTrue(buttonTrait.contains(.button))
        XCTAssertFalse(buttonTrait.contains(.link))
    }

    func testMultipleTraits() {
        let combinedTraits: AccessibilityTraits = [.button, .selected]
        XCTAssertTrue(combinedTraits.contains(.button))
        XCTAssertTrue(combinedTraits.contains(.selected))
        XCTAssertFalse(combinedTraits.contains(.link))
    }

    func testPredefinedCombinations() {
        let selectedButton = AccessibilityTraits.selectedButton
        XCTAssertTrue(selectedButton.contains(.button))
        XCTAssertTrue(selectedButton.contains(.selected))
    }

    // MARK: - Trait Modifications

    func testInsertTrait() {
        var traits = AccessibilityTraits.button
        traits.insert(.selected)

        XCTAssertTrue(traits.contains(.button))
        XCTAssertTrue(traits.contains(.selected))
    }

    func testRemoveTrait() {
        var traits: AccessibilityTraits = [.button, .selected]
        traits.remove(.selected)

        XCTAssertTrue(traits.contains(.button))
        XCTAssertFalse(traits.contains(.selected))
    }

    func testUnion() {
        let traits1 = AccessibilityTraits.button
        let traits2 = AccessibilityTraits.selected
        let combined = traits1.union(traits2)

        XCTAssertTrue(combined.contains(.button))
        XCTAssertTrue(combined.contains(.selected))
    }

    // MARK: - Helper Properties

    func testIsInteractive() {
        XCTAssertTrue(AccessibilityTraits.button.isInteractive)
        XCTAssertTrue(AccessibilityTraits.link.isInteractive)
        XCTAssertTrue(AccessibilityTraits.adjustable.isInteractive)
        XCTAssertFalse(AccessibilityTraits.staticText.isInteractive)
        XCTAssertFalse(AccessibilityTraits.header.isInteractive)
    }

    func testShouldAnnounceChanges() {
        XCTAssertTrue(AccessibilityTraits.updatesFrequently.shouldAnnounceChanges)
        XCTAssertFalse(AccessibilityTraits.button.shouldAnnounceChanges)
    }

    func testDescription() {
        let buttonTrait = AccessibilityTraits.button
        XCTAssertEqual(buttonTrait.description, "button")

        let combinedTraits: AccessibilityTraits = [.button, .selected]
        XCTAssertTrue(combinedTraits.description.contains("button"))
        XCTAssertTrue(combinedTraits.description.contains("selected"))
    }

    // MARK: - Builder Pattern

    func testBuilder() {
        let traits = AccessibilityTraits.builder()
            .asButton()
            .selected(true)
            .build()

        XCTAssertTrue(traits.contains(.button))
        XCTAssertTrue(traits.contains(.selected))
    }

    func testBuilderDisabled() {
        let traits = AccessibilityTraits.builder()
            .asButton()
            .disabled(true)
            .build()

        XCTAssertTrue(traits.contains(.button))
        XCTAssertTrue(traits.contains(.notEnabled))
    }

    func testBuilderConditional() {
        let isSelected = false
        let traits = AccessibilityTraits.builder()
            .asButton()
            .selected(isSelected)
            .build()

        XCTAssertTrue(traits.contains(.button))
        XCTAssertFalse(traits.contains(.selected))
    }

    func testBuilderCustomTraits() {
        let traits = AccessibilityTraits.builder()
            .asButton()
            .with(.playsSound)
            .build()

        XCTAssertTrue(traits.contains(.button))
        XCTAssertTrue(traits.contains(.playsSound))
    }

    // MARK: - Platform Mapping

    #if os(iOS) || os(tvOS)
    func testUITraitsMapping() {
        let traits: AccessibilityTraits = [.button, .selected]
        let uiTraits = traits.uiTraits

        XCTAssertTrue(uiTraits.contains(.button))
        XCTAssertTrue(uiTraits.contains(.selected))
    }

    func testUITraitsRoundTrip() {
        let originalTraits: AccessibilityTraits = [.button, .header, .adjustable]
        let uiTraits = originalTraits.uiTraits
        let reconstructed = AccessibilityTraits(uiTraits: uiTraits)

        XCTAssertEqual(originalTraits, reconstructed)
    }
    #endif

    #if os(macOS)
    func testMacOSRoleMapping() {
        XCTAssertEqual(AccessibilityTraits.button.macOSRoleName, "AXButton")
        XCTAssertEqual(AccessibilityTraits.link.macOSRoleName, "AXLink")
        XCTAssertEqual(AccessibilityTraits.image.macOSRoleName, "AXImage")
    }

    func testIsEnabledMacOS() {
        XCTAssertTrue(AccessibilityTraits.button.isEnabled)
        XCTAssertFalse(AccessibilityTraits.notEnabled.isEnabled)

        let disabledButton: AccessibilityTraits = [.button, .notEnabled]
        XCTAssertFalse(disabledButton.isEnabled)
    }
    #endif

    // MARK: - Common Combinations

    func testExternalLink() {
        let externalLink = AccessibilityTraits.externalLink
        XCTAssertTrue(externalLink.contains(.link))
        XCTAssertTrue(externalLink.contains(.causesPageTurn))
    }

    func testSearchInput() {
        let searchInput = AccessibilityTraits.searchInput
        XCTAssertTrue(searchInput.contains(.searchField))
        XCTAssertTrue(searchInput.contains(.allowsDirectInteraction))
    }

    func testLiveAdjustable() {
        let liveAdjustable = AccessibilityTraits.liveAdjustable
        XCTAssertTrue(liveAdjustable.contains(.adjustable))
        XCTAssertTrue(liveAdjustable.contains(.updatesFrequently))
        XCTAssertTrue(liveAdjustable.shouldAnnounceChanges)
    }

    // MARK: - Edge Cases

    func testEmptyTraits() {
        let empty = AccessibilityTraits()
        XCTAssertEqual(empty.description, "none")
        XCTAssertFalse(empty.isInteractive)
        XCTAssertFalse(empty.shouldAnnounceChanges)
    }

    func testAllTraitsCombined() {
        let allTraits: AccessibilityTraits = [
            .button, .link, .searchField, .image, .selected,
            .keyboardKey, .staticText, .header, .playsSound,
            .updatesFrequently, .startsMediaSession, .adjustable,
            .allowsDirectInteraction, .causesPageTurn, .tabBar,
            .summaryElement, .notEnabled
        ]

        XCTAssertTrue(allTraits.contains(.button))
        XCTAssertTrue(allTraits.contains(.notEnabled))
        XCTAssertTrue(allTraits.isInteractive)
        XCTAssertTrue(allTraits.shouldAnnounceChanges)
    }
}
