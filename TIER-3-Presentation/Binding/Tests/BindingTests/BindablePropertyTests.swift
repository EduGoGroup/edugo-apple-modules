import Foundation
import os
import Testing
@testable import Binding

/// Thread-safe counter for testing callbacks using os_unfair_lock
final class TestCounter: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: (count: 0, lastValue: String?.none))

    var count: Int {
        lock.withLock { $0.count }
    }

    var lastValue: String? {
        lock.withLock { $0.lastValue }
    }

    func increment() {
        lock.withLock { $0.count += 1 }
    }

    func setValue(_ value: String) {
        lock.withLock { $0.lastValue = value }
    }
}

@Suite("BindableProperty Tests")
struct BindablePropertyTests {

    // MARK: - Basic Functionality

    @Test("Initial value is set correctly")
    @MainActor
    func initialValueIsSetCorrectly() {
        let property = BindableProperty(wrappedValue: "test")

        #expect(property.wrappedValue == "test")
    }

    @Test("Value can be updated")
    @MainActor
    func valueCanBeUpdated() {
        var property = BindableProperty(wrappedValue: "initial")

        property.wrappedValue = "updated"

        #expect(property.wrappedValue == "updated")
    }

    @Test("Validation state is initially valid")
    @MainActor
    func validationStateIsInitiallyValid() {
        let property = BindableProperty(
            wrappedValue: "",
            validation: Validators.email()
        )

        #expect(property.validationState.isValid == true)
        #expect(property.validationState.errorMessage == nil)
    }

    // MARK: - Validation

    @Test("Invalid email triggers validation error")
    @MainActor
    func invalidEmailTriggersValidationError() {
        var property = BindableProperty(
            wrappedValue: "",
            validation: Validators.email()
        )

        property.wrappedValue = "invalid-email"

        #expect(property.validationState.isValid == false)
        #expect(property.validationState.errorMessage != nil)
    }

    @Test("Valid email passes validation")
    @MainActor
    func validEmailPassesValidation() {
        var property = BindableProperty(
            wrappedValue: "",
            validation: Validators.email()
        )

        property.wrappedValue = "user@example.com"

        #expect(property.validationState.isValid == true)
        #expect(property.validationState.errorMessage == nil)
    }

    @Test("Password validation checks minimum length")
    @MainActor
    func passwordValidationChecksMinimumLength() {
        var property = BindableProperty(
            wrappedValue: "",
            validation: Validators.password(minLength: 8)
        )

        property.wrappedValue = "short"
        #expect(property.validationState.isValid == false)

        property.wrappedValue = "longenoughpassword"
        #expect(property.validationState.isValid == true)
    }

    @Test("Manual validation triggers on current value")
    @MainActor
    func manualValidationTriggersOnCurrentValue() {
        var property = BindableProperty(
            wrappedValue: "invalid-email",
            validation: Validators.email()
        )

        // Initial state is valid (not yet validated)
        #expect(property.validationState.isValid == true)

        // Manual validation
        property.validate()

        #expect(property.validationState.isValid == false)
    }

    @Test("Reset validation clears error state")
    @MainActor
    func resetValidationClearsErrorState() {
        var property = BindableProperty(
            wrappedValue: "",
            validation: Validators.email()
        )

        property.wrappedValue = "invalid"
        #expect(property.validationState.isValid == false)

        property.resetValidation()

        #expect(property.validationState.isValid == true)
        #expect(property.validationState.errorMessage == nil)
    }

    // MARK: - onChange Callback

    @Test("onChange callback is triggered on value change")
    @MainActor
    func onChangeCallbackIsTriggeredOnValueChange() {
        let counter = TestCounter()
        var property = BindableProperty(
            wrappedValue: "",
            onChange: { [counter] _ in counter.increment() }
        )

        property.wrappedValue = "test1"
        property.wrappedValue = "test2"
        property.wrappedValue = "test3"

        #expect(counter.count == 3)
    }

    @Test("onChange receives the new value")
    @MainActor
    func onChangeReceivesNewValue() {
        let counter = TestCounter()
        var property = BindableProperty(
            wrappedValue: "",
            onChange: { [counter] value in counter.setValue(value) }
        )

        property.wrappedValue = "expected"

        #expect(counter.lastValue == "expected")
    }
}

@Suite("Validators Tests")
struct ValidatorsTests {

    // MARK: - Email Validator

    @Test("Email validator rejects empty string")
    func emailValidatorRejectsEmptyString() {
        let validator = Validators.email()
        let result = validator("")

        #expect(result.isValid == false)
        #expect(result.errorMessage?.contains("requerido") == true)
    }

    @Test("Email validator rejects invalid format")
    func emailValidatorRejectsInvalidFormat() {
        let validator = Validators.email()

        let testCases = ["invalid", "no@", "@domain.com", "spaces here@test.com"]

        for testCase in testCases {
            let result = validator(testCase)
            #expect(result.isValid == false, "Expected \(testCase) to be invalid")
        }
    }

    @Test("Email validator accepts valid emails")
    func emailValidatorAcceptsValidEmails() {
        let validator = Validators.email()

        let testCases = ["user@example.com", "test.user@domain.co", "a@b.io"]

        for testCase in testCases {
            let result = validator(testCase)
            #expect(result.isValid == true, "Expected \(testCase) to be valid")
        }
    }

    // MARK: - Password Validator

    @Test("Password validator rejects empty password")
    func passwordValidatorRejectsEmptyPassword() {
        let validator = Validators.password(minLength: 8)
        let result = validator("")

        #expect(result.isValid == false)
    }

    @Test("Password validator rejects short passwords")
    func passwordValidatorRejectsShortPasswords() {
        let validator = Validators.password(minLength: 8)
        let result = validator("short")

        #expect(result.isValid == false)
        #expect(result.errorMessage?.contains("8") == true)
    }

    @Test("Password validator accepts valid passwords")
    func passwordValidatorAcceptsValidPasswords() {
        let validator = Validators.password(minLength: 8)
        let result = validator("validpassword123")

        #expect(result.isValid == true)
    }

    // MARK: - NonEmpty Validator

    @Test("NonEmpty validator rejects empty string")
    func nonEmptyValidatorRejectsEmptyString() {
        let validator = Validators.nonEmpty(fieldName: "Nombre")
        let result = validator("")

        #expect(result.isValid == false)
        #expect(result.errorMessage?.contains("Nombre") == true)
    }

    @Test("NonEmpty validator rejects whitespace only")
    func nonEmptyValidatorRejectsWhitespaceOnly() {
        let validator = Validators.nonEmpty()
        let result = validator("   ")

        #expect(result.isValid == false)
    }

    @Test("NonEmpty validator accepts non-empty string")
    func nonEmptyValidatorAcceptsNonEmptyString() {
        let validator = Validators.nonEmpty()
        let result = validator("valid")

        #expect(result.isValid == true)
    }

    // MARK: - Range Validator

    @Test("Range validator rejects out of range values")
    func rangeValidatorRejectsOutOfRangeValues() {
        let validator = Validators.range(1...10, fieldName: "Cantidad")

        #expect(validator(0).isValid == false)
        #expect(validator(11).isValid == false)
    }

    @Test("Range validator accepts in range values")
    func rangeValidatorAcceptsInRangeValues() {
        let validator = Validators.range(1...10)

        #expect(validator(1).isValid == true)
        #expect(validator(5).isValid == true)
        #expect(validator(10).isValid == true)
    }

    // MARK: - Composition

    @Test("All validator combines multiple validators")
    func allValidatorCombinesMultipleValidators() {
        let validator = Validators.all([
            Validators.nonEmpty(),
            Validators.minLength(3)
        ])

        #expect(validator("").isValid == false)
        #expect(validator("ab").isValid == false)
        #expect(validator("abc").isValid == true)
    }

    @Test("When validator applies conditionally")
    func whenValidatorAppliesConditionally() {
        let validator = Validators.when(
            { (value: String) in !value.isEmpty },
            then: Validators.email()
        )

        // Empty string should pass (condition not met)
        #expect(validator("").isValid == true)

        // Non-empty should be validated
        #expect(validator("invalid").isValid == false)
        #expect(validator("user@example.com").isValid == true)
    }
}

@Suite("DebouncedProperty Tests")
struct DebouncedPropertyTests {

    @Test("Initial value is set correctly")
    @MainActor
    func initialValueIsSetCorrectly() {
        let property = DebouncedProperty(wrappedValue: "test")

        #expect(property.wrappedValue == "test")
    }

    @Test("Value updates immediately")
    @MainActor
    func valueUpdatesImmediately() {
        var property = DebouncedProperty(
            wrappedValue: "",
            debounceInterval: 1.0
        )

        property.wrappedValue = "updated"

        #expect(property.wrappedValue == "updated")
    }

    @Test("Debounced callback executes after interval")
    @MainActor
    func debouncedCallbackExecutesAfterInterval() async throws {
        let counter = TestCounter()
        var property = DebouncedProperty(
            wrappedValue: "",
            debounceInterval: 0.1,
            onDebouncedChange: { [counter] _ in counter.increment() }
        )

        property.wrappedValue = "test"

        // Should not have executed yet
        #expect(counter.count == 0)

        // Wait for debounce
        try await Task.sleep(for: .seconds(0.2))

        // Should have executed once
        #expect(counter.count == 1)
    }

    @Test("Rapid changes result in single callback")
    @MainActor
    func rapidChangesResultInSingleCallback() async throws {
        let counter = TestCounter()
        var property = DebouncedProperty(
            wrappedValue: "",
            debounceInterval: 0.1,
            onDebouncedChange: { [counter] value in
                counter.increment()
                counter.setValue(value)
            }
        )

        // Rapid changes
        property.wrappedValue = "a"
        property.wrappedValue = "ab"
        property.wrappedValue = "abc"

        // Wait for debounce
        try await Task.sleep(for: .seconds(0.2))

        // Should have executed only once with the last value
        #expect(counter.count == 1)
        #expect(counter.lastValue == "abc")
    }

    @Test("Cancel stops pending callback")
    @MainActor
    func cancelStopsPendingCallback() async throws {
        let counter = TestCounter()
        var property = DebouncedProperty(
            wrappedValue: "",
            debounceInterval: 0.2,
            onDebouncedChange: { [counter] _ in counter.increment() }
        )

        property.wrappedValue = "test"
        property.cancel()

        // Wait past the debounce interval
        try await Task.sleep(for: .seconds(0.3))

        // Should not have executed
        #expect(counter.count == 0)
    }
}

@Suite("ValidationResult Tests")
struct ValidationResultTests {

    @Test("Valid result has correct properties")
    func validResultHasCorrectProperties() {
        let result = ValidationResult.valid()

        #expect(result.isValid == true)
        #expect(result.errorMessage == nil)
    }

    @Test("Invalid result has correct properties")
    func invalidResultHasCorrectProperties() {
        let result = ValidationResult.invalid("Error message")

        #expect(result.isValid == false)
        #expect(result.errorMessage == "Error message")
    }

    @Test("ValidationResult is equatable")
    func validationResultIsEquatable() {
        let result1 = ValidationResult.valid()
        let result2 = ValidationResult.valid()
        let result3 = ValidationResult.invalid("error")

        #expect(result1 == result2)
        #expect(result1 != result3)
    }
}
