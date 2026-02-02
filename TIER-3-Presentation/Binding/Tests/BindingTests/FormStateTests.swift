import Foundation
import os
import Testing
@testable import Binding

/// Thread-safe holder for test values using os_unfair_lock
final class TestValue<T: Sendable>: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: Optional<T>.none)

    var value: T? {
        get { lock.withLock { $0 } }
        set { lock.withLock { $0 = newValue } }
    }

    init(_ initial: T? = nil) {
        lock.withLock { $0 = initial }
    }
}

/// Thread-safe boolean flag for testing
final class TestFlag: @unchecked Sendable {
    private let lock = OSAllocatedUnfairLock(initialState: false)

    var value: Bool {
        get { lock.withLock { $0 } }
        set { lock.withLock { $0 = newValue } }
    }
}

@Suite("FormState Tests")
struct FormStateTests {

    // MARK: - Initial State

    @Test("Initial state is not valid and not submitting")
    @MainActor
    func initialStateIsNotValidAndNotSubmitting() {
        let formState = FormState()

        #expect(formState.isValid == false)
        #expect(formState.isSubmitting == false)
        #expect(formState.errors.isEmpty)
    }

    // MARK: - Field Validation

    @Test("Field validation adds error when invalid")
    @MainActor
    func fieldValidationAddsErrorWhenInvalid() {
        let formState = FormState()

        formState.registerField("email") {
            .invalid("Email is required")
        }

        formState.validate()

        #expect(formState.isValid == false)
        #expect(formState.errors["email"] == "Email is required")
    }

    @Test("Field validation passes when valid")
    @MainActor
    func fieldValidationPassesWhenValid() {
        let formState = FormState()

        formState.registerField("email") {
            .valid()
        }

        formState.validate()

        #expect(formState.isValid == true)
        #expect(formState.errors.isEmpty)
    }

    @Test("Multiple fields are validated")
    @MainActor
    func multipleFieldsAreValidated() {
        let formState = FormState()

        formState.registerField("email") {
            .invalid("Email is required")
        }

        formState.registerField("password") {
            .invalid("Password is required")
        }

        formState.validate()

        #expect(formState.isValid == false)
        #expect(formState.errors["email"] != nil)
        #expect(formState.errors["password"] != nil)
    }

    @Test("Validate single field updates errors")
    @MainActor
    func validateSingleFieldUpdatesErrors() {
        let formState = FormState()
        let emailValue = TestValue("")

        formState.registerField("email") { [emailValue] in
            (emailValue.value ?? "").isEmpty ? .invalid("Email is required") : .valid()
        }

        let result1 = formState.validateField("email")
        #expect(result1.isValid == false)
        #expect(formState.errors["email"] != nil)

        emailValue.value = "test@example.com"
        let result2 = formState.validateField("email")
        #expect(result2.isValid == true)
        #expect(formState.errors["email"] == nil)
    }

    @Test("Unregister field removes validator")
    @MainActor
    func unregisterFieldRemovesValidator() {
        let formState = FormState()

        formState.registerField("email") {
            .invalid("Error")
        }

        formState.validate()
        #expect(formState.errors["email"] != nil)

        formState.unregisterField("email")
        formState.validate()
        #expect(formState.errors["email"] == nil)
    }

    // MARK: - Cross-Field Validation

    @Test("Cross-field validation runs after field validation")
    @MainActor
    func crossFieldValidationRunsAfterFieldValidation() {
        let formState = FormState()
        let password = TestValue("password123")
        let confirmation = TestValue("different")

        formState.registerCrossValidator { [password, confirmation] in
            CrossValidators.passwordMatch(password.value ?? "", confirmation.value ?? "")
        }

        formState.validate()

        #expect(formState.isValid == false)
        #expect(formState.errors["form"] != nil)

        confirmation.value = "password123"
        formState.validate()

        #expect(formState.isValid == true)
        #expect(formState.errors.isEmpty)
    }

    @Test("Multiple cross-validators are combined")
    @MainActor
    func multipleCrossValidatorsAreCombined() {
        let formState = FormState()

        formState.registerCrossValidator {
            .invalid("Error 1")
        }

        formState.registerCrossValidator {
            .invalid("Error 2")
        }

        formState.validate()

        #expect(formState.isValid == false)
        #expect(formState.errors["form"]?.contains("Error 1") == true)
        #expect(formState.errors["form"]?.contains("Error 2") == true)
    }

    @Test("Clear cross validators removes all")
    @MainActor
    func clearCrossValidatorsRemovesAll() {
        let formState = FormState()

        formState.registerCrossValidator {
            .invalid("Error")
        }

        formState.validate()
        #expect(formState.errors["form"] != nil)

        formState.clearCrossValidators()
        formState.validate()
        #expect(formState.errors["form"] == nil)
    }

    // MARK: - Error Management

    @Test("Error for key returns correct error")
    @MainActor
    func errorForKeyReturnsCorrectError() {
        let formState = FormState()

        formState.registerField("email") {
            .invalid("Email error")
        }

        formState.validate()

        #expect(formState.error(for: "email") == "Email error")
        #expect(formState.error(for: "nonexistent") == nil)
    }

    @Test("Clear error removes specific error")
    @MainActor
    func clearErrorRemovesSpecificError() {
        let formState = FormState()

        formState.registerField("email") {
            .invalid("Error")
        }

        formState.validate()
        #expect(formState.errors["email"] != nil)

        formState.clearError(for: "email")
        #expect(formState.errors["email"] == nil)
    }

    @Test("Reset clears all state")
    @MainActor
    func resetClearsAllState() {
        let formState = FormState()

        formState.registerField("email") {
            .invalid("Error")
        }

        formState.validate()

        formState.reset()

        #expect(formState.errors.isEmpty)
        #expect(formState.isValid == false)
        #expect(formState.isSubmitting == false)
    }

    // MARK: - Submission

    @Test("Submit validates before action")
    @MainActor
    func submitValidatesBeforeAction() async {
        let formState = FormState()
        let actionExecuted = TestFlag()

        formState.registerField("email") {
            .invalid("Error")
        }

        let result = await formState.submit { [actionExecuted] in
            actionExecuted.value = true
        }

        #expect(result == false)
        #expect(actionExecuted.value == false)
    }

    @Test("Submit executes action when valid")
    @MainActor
    func submitExecutesActionWhenValid() async {
        let formState = FormState()
        let actionExecuted = TestFlag()

        formState.registerField("email") {
            .valid()
        }

        let result = await formState.submit { [actionExecuted] in
            actionExecuted.value = true
        }

        #expect(result == true)
        #expect(actionExecuted.value == true)
    }

    @Test("Submit catches errors from action")
    @MainActor
    func submitCatchesErrorsFromAction() async {
        let formState = FormState()

        struct TestError: Error, LocalizedError {
            var errorDescription: String? { "Test error" }
        }

        let result = await formState.submit {
            throw TestError()
        }

        #expect(result == false)
        #expect(formState.errors["form"]?.contains("Test error") == true)
        #expect(formState.isValid == false)
    }
}

@Suite("CrossValidators Tests")
struct CrossValidatorsTests {

    // MARK: - Password Match

    @Test("Password match validates matching passwords")
    func passwordMatchValidatesMatchingPasswords() {
        let result = CrossValidators.passwordMatch("password", "password")
        #expect(result.isValid == true)
    }

    @Test("Password match rejects non-matching passwords")
    func passwordMatchRejectsNonMatchingPasswords() {
        let result = CrossValidators.passwordMatch("password", "different")
        #expect(result.isValid == false)
    }

    // MARK: - Date Range

    @Test("Date range validates valid range")
    func dateRangeValidatesValidRange() {
        let start = Date()
        let end = Date().addingTimeInterval(3600)

        let result = CrossValidators.dateRange(start: start, end: end)
        #expect(result.isValid == true)
    }

    @Test("Date range rejects invalid range")
    func dateRangeRejectsInvalidRange() {
        let start = Date()
        let end = Date().addingTimeInterval(-3600)

        let result = CrossValidators.dateRange(start: start, end: end)
        #expect(result.isValid == false)
    }

    @Test("Date range requires both dates")
    func dateRangeRequiresBothDates() {
        let result1 = CrossValidators.dateRange(start: Date(), end: nil)
        #expect(result1.isValid == false)

        let result2 = CrossValidators.dateRange(start: nil, end: Date())
        #expect(result2.isValid == false)
    }

    @Test("Optional date range allows nil values")
    func optionalDateRangeAllowsNilValues() {
        let result = CrossValidators.optionalDateRange(start: nil, end: nil)
        #expect(result.isValid == true)
    }

    @Test("Optional date range requires both when one is set")
    func optionalDateRangeRequiresBothWhenOneIsSet() {
        let result = CrossValidators.optionalDateRange(start: Date(), end: nil)
        #expect(result.isValid == false)
    }

    // MARK: - Collection Validation

    @Test("At least one selected validates non-empty set")
    func atLeastOneSelectedValidatesNonEmptySet() {
        let items: Set<Int> = [1, 2, 3]
        let result = CrossValidators.atLeastOneSelected(items)
        #expect(result.isValid == true)
    }

    @Test("At least one selected rejects empty set")
    func atLeastOneSelectedRejectsEmptySet() {
        let items: Set<Int> = []
        let result = CrossValidators.atLeastOneSelected(items)
        #expect(result.isValid == false)
    }

    @Test("At least one selected validates non-empty array")
    func atLeastOneSelectedValidatesNonEmptyArray() {
        let items = [1, 2, 3]
        let result = CrossValidators.atLeastOneSelected(items)
        #expect(result.isValid == true)
    }

    @Test("Exact count validates correct count")
    func exactCountValidatesCorrectCount() {
        let items = [1, 2, 3]
        let result = CrossValidators.exactCount(items, count: 3)
        #expect(result.isValid == true)
    }

    @Test("Exact count rejects incorrect count")
    func exactCountRejectsIncorrectCount() {
        let items = [1, 2]
        let result = CrossValidators.exactCount(items, count: 3)
        #expect(result.isValid == false)
    }

    @Test("Count in range validates within range")
    func countInRangeValidatesWithinRange() {
        let items = [1, 2, 3]
        let result = CrossValidators.countInRange(items, range: 1...5)
        #expect(result.isValid == true)
    }

    @Test("Count in range rejects outside range")
    func countInRangeRejectsOutsideRange() {
        let items = [1, 2, 3, 4, 5, 6]
        let result = CrossValidators.countInRange(items, range: 1...5)
        #expect(result.isValid == false)
    }

    // MARK: - Conditional Validation

    @Test("Conditional required validates when condition false")
    func conditionalRequiredValidatesWhenConditionFalse() {
        let result = CrossValidators.conditionalRequired(
            condition: false,
            value: "",
            fieldName: "Field"
        )
        #expect(result.isValid == true)
    }

    @Test("Conditional required requires when condition true")
    func conditionalRequiredRequiresWhenConditionTrue() {
        let result = CrossValidators.conditionalRequired(
            condition: true,
            value: "",
            fieldName: "Field"
        )
        #expect(result.isValid == false)
    }

    @Test("Required when present validates when dependency empty")
    func requiredWhenPresentValidatesWhenDependencyEmpty() {
        let result = CrossValidators.requiredWhenPresent(
            dependsOn: "",
            value: "",
            fieldName: "Field"
        )
        #expect(result.isValid == true)
    }

    @Test("Required when present requires when dependency present")
    func requiredWhenPresentRequiresWhenDependencyPresent() {
        let result = CrossValidators.requiredWhenPresent(
            dependsOn: "value",
            value: "",
            fieldName: "Field"
        )
        #expect(result.isValid == false)
    }

    // MARK: - Comparison Validation

    @Test("Equal validates matching values")
    func equalValidatesMatchingValues() {
        let result = CrossValidators.equal(5, 5, errorMessage: "Not equal")
        #expect(result.isValid == true)
    }

    @Test("Equal rejects non-matching values")
    func equalRejectsNonMatchingValues() {
        let result = CrossValidators.equal(5, 10, errorMessage: "Not equal")
        #expect(result.isValid == false)
    }

    @Test("Not equal validates different values")
    func notEqualValidatesDifferentValues() {
        let result = CrossValidators.notEqual(5, 10, errorMessage: "Equal")
        #expect(result.isValid == true)
    }

    @Test("Less than validates smaller value")
    func lessThanValidatesSmallerValue() {
        let result = CrossValidators.lessThan(5, 10)
        #expect(result.isValid == true)
    }

    @Test("Less than rejects larger value")
    func lessThanRejectsLargerValue() {
        let result = CrossValidators.lessThan(10, 5)
        #expect(result.isValid == false)
    }

    @Test("Greater than validates larger value")
    func greaterThanValidatesLargerValue() {
        let result = CrossValidators.greaterThan(10, 5)
        #expect(result.isValid == true)
    }

    // MARK: - Composition

    @Test("All returns first failure")
    func allReturnsFirstFailure() {
        let result = CrossValidators.all([
            { .valid() },
            { .invalid("Error 1") },
            { .invalid("Error 2") }
        ])

        #expect(result.isValid == false)
        #expect(result.errorMessage == "Error 1")
    }

    @Test("All returns valid when all pass")
    func allReturnsValidWhenAllPass() {
        let result = CrossValidators.all([
            { .valid() },
            { .valid() }
        ])

        #expect(result.isValid == true)
    }

    @Test("All collecting errors combines all errors")
    func allCollectingErrorsCombinesAllErrors() {
        let result = CrossValidators.allCollectingErrors([
            { .invalid("Error 1") },
            { .valid() },
            { .invalid("Error 2") }
        ])

        #expect(result.isValid == false)
        #expect(result.errorMessage?.contains("Error 1") == true)
        #expect(result.errorMessage?.contains("Error 2") == true)
    }
}
