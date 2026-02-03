import XCTest
@testable import EduAccessibility

@MainActor
final class AccessibilityLabelsTests: XCTestCase {

    // MARK: - Basic Label Creation

    func testTextLabel() {
        let label = AccessibilityLabel.text("Save button")
        XCTAssertEqual(label.value, "Save button")
    }

    func testLocalizedLabel() {
        // Note: En tests, NSLocalizedString retorna la key si no hay localización
        let label = AccessibilityLabel.localized("save_button")
        XCTAssertEqual(label.value, "save_button")
    }

    func testFormatLabel() {
        let label = AccessibilityLabel.format("Delete %@ item", "photo")
        XCTAssertEqual(label.value, "Delete photo item")
    }

    // MARK: - Contextual Labels

    func testContextualLabel() {
        let label = AccessibilityLabel.contextual(
            action: "Delete",
            target: "photo",
            context: "from album"
        )
        XCTAssertEqual(label.value, "Delete photo from album")
    }

    func testContextualLabelWithoutTarget() {
        let label = AccessibilityLabel.contextual(action: "Save")
        XCTAssertEqual(label.value, "Save")
    }

    func testContextualLabelWithoutContext() {
        let label = AccessibilityLabel.contextual(action: "Delete", target: "item")
        XCTAssertEqual(label.value, "Delete item")
    }

    // MARK: - Specific Component Labels

    func testButtonLabel() {
        let label = AccessibilityLabel.button(action: "Save")
        XCTAssertEqual(label.value, "Save button")
    }

    func testButtonLabelWithTarget() {
        let label = AccessibilityLabel.button(action: "Delete", target: "photo")
        XCTAssertEqual(label.value, "Delete photo button")
    }

    func testLinkLabel() {
        let label = AccessibilityLabel.link(destination: "Settings page")
        XCTAssertEqual(label.value, "Link to Settings page")
    }

    func testHeaderLabel() {
        let label = AccessibilityLabel.header("Main Title")
        XCTAssertEqual(label.value, "Main Title heading")
    }

    func testTextFieldLabel() {
        let label = AccessibilityLabel.textField(name: "Email")
        XCTAssertEqual(label.value, "Email text field")
    }

    func testTextFieldLabelWithHint() {
        let label = AccessibilityLabel.textField(name: "Email", hint: "Enter your email")
        XCTAssertEqual(label.value, "Email text field, Enter your email")
    }

    func testToggleLabel() {
        let onLabel = AccessibilityLabel.toggle(name: "Notifications", state: true)
        XCTAssertEqual(onLabel.value, "Notifications, on")

        let offLabel = AccessibilityLabel.toggle(name: "Notifications", state: false)
        XCTAssertEqual(offLabel.value, "Notifications, off")
    }

    func testAdjustableLabel() {
        let label = AccessibilityLabel.adjustable(name: "Volume", value: "75%")
        XCTAssertEqual(label.value, "Volume slider, 75%")
    }

    func testProgressLabel() {
        let label = AccessibilityLabel.progress(value: 50)
        XCTAssertEqual(label.value, "Progress, 50 percent")
    }

    func testLoadingLabel() {
        let genericLabel = AccessibilityLabel.loading()
        XCTAssertEqual(genericLabel.value, "Loading")

        let contextLabel = AccessibilityLabel.loading("photos")
        XCTAssertEqual(contextLabel.value, "Loading photos")
    }

    func testErrorLabel() {
        let label = AccessibilityLabel.error("Network connection failed")
        XCTAssertEqual(label.value, "Error: Network connection failed")
    }

    func testEmptyLabel() {
        let defaultLabel = AccessibilityLabel.empty()
        XCTAssertEqual(defaultLabel.value, "No content available")

        let customLabel = AccessibilityLabel.empty("photos")
        XCTAssertEqual(customLabel.value, "No photos available")
    }

    // MARK: - Label Builder

    func testLabelBuilder() {
        let label = AccessibilityLabelBuilder()
            .add("Delete")
            .add("photo")
            .add("button")
            .build()

        XCTAssertEqual(label.value, "Delete photo button")
    }

    func testLabelBuilderConditional() {
        let hasTarget = true
        let label = AccessibilityLabelBuilder()
            .add("Save")
            .addIf(hasTarget, "document")
            .add("button")
            .build()

        XCTAssertEqual(label.value, "Save document button")
    }

    func testLabelBuilderOptional() {
        let target: String? = "photo"
        let label = AccessibilityLabelBuilder()
            .add("Delete")
            .addOptional(target)
            .build()

        XCTAssertEqual(label.value, "Delete photo")
    }

    func testLabelBuilderWithNilOptional() {
        let target: String? = nil
        let label = AccessibilityLabelBuilder()
            .add("Delete")
            .addOptional(target)
            .build()

        XCTAssertEqual(label.value, "Delete")
    }

    func testLabelBuilderCustomSeparator() {
        let label = AccessibilityLabelBuilder()
            .add("Save")
            .add("document")
            .build(separator: "-")

        XCTAssertEqual(label.value, "Save-document")
    }

    // MARK: - Common Labels

    func testCommonActionLabels() {
        XCTAssertEqual(AccessibilityLabel.Common.save.value, "Save button")
        XCTAssertEqual(AccessibilityLabel.Common.cancel.value, "Cancel button")
        XCTAssertEqual(AccessibilityLabel.Common.delete.value, "Delete button")
    }

    func testCommonStateLabels() {
        XCTAssertEqual(AccessibilityLabel.Common.loading.value, "Loading")
        XCTAssertEqual(AccessibilityLabel.Common.emptyState.value, "No content available")
    }

    func testCommonFieldLabels() {
        XCTAssertEqual(AccessibilityLabel.Common.emailField.value, "Email text field")
        XCTAssertEqual(AccessibilityLabel.Common.passwordField.value, "Password text field")
    }

    // MARK: - Validation

    func testValidLabel() {
        let label = AccessibilityLabel.text("Save button")
        XCTAssertTrue(label.isValid)
    }

    func testInvalidEmptyLabel() {
        let label = AccessibilityLabel.text("")
        XCTAssertFalse(label.isValid)
    }

    func testInvalidWhitespaceOnlyLabel() {
        let label = AccessibilityLabel.text("   ")
        XCTAssertFalse(label.isValid)
    }

    func testInvalidTooLongLabel() {
        let longText = String(repeating: "a", count: 101)
        let label = AccessibilityLabel.text(longText)
        XCTAssertFalse(label.isValid)
    }

    func testInvalidSymbolsOnlyLabel() {
        let label = AccessibilityLabel.text("!@#$%")
        XCTAssertFalse(label.isValid)
    }

    func testValidLabelWithNumbers() {
        let label = AccessibilityLabel.text("Delete item 5")
        XCTAssertTrue(label.isValid)
    }

    func testRecommendedLength() {
        let goodLabel = AccessibilityLabel.text("Save the document button")
        XCTAssertTrue(goodLabel.hasRecommendedLength) // 24 caracteres - en rango 15-50

        let tooShortLabel = AccessibilityLabel.text("Save")
        XCTAssertFalse(tooShortLabel.hasRecommendedLength) // 4 caracteres

        let tooLongLabel = AccessibilityLabel.text(String(repeating: "a", count: 60))
        XCTAssertFalse(tooLongLabel.hasRecommendedLength)
    }

    // MARK: - String Extension

    func testStringAsAccessibilityLabel() {
        let label = "Save button".asAccessibilityLabel
        XCTAssertEqual(label.value, "Save button")
    }

    // MARK: - Protocol Conformance

    func testAccessibilityLabelProvider() {
        struct TestComponent: AccessibilityLabelProvider {
            var accessibilityLabel: String {
                "Test component button"
            }
        }

        let component = TestComponent()
        XCTAssertEqual(component.accessibilityLabel, "Test component button")
    }

    // MARK: - Edge Cases

    func testLabelWithSpecialCharacters() {
        let label = AccessibilityLabel.text("Save & Continue")
        XCTAssertTrue(label.isValid)
    }

    func testLabelWithEmoji() {
        let label = AccessibilityLabel.text("Delete 🗑️ button")
        XCTAssertTrue(label.isValid)
    }

    func testLabelWithLineBreaks() {
        let label = AccessibilityLabel.text("First line\nSecond line")
        XCTAssertTrue(label.isValid)
    }
}
