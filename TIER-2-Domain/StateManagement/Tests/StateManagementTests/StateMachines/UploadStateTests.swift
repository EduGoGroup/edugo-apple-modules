import Testing
@testable import StateManagement

@Suite("UploadState")
struct UploadStateTests {

    // MARK: - Equality Tests

    @Test("Same states are equal")
    func sameStatesAreEqual() {
        #expect(UploadState.validating == UploadState.validating)
        #expect(UploadState.creating == UploadState.creating)
        #expect(UploadState.processing == UploadState.processing)
        #expect(UploadState.ready == UploadState.ready)
    }

    @Test("Uploading states with same progress are equal")
    func uploadingStatesWithSameProgressAreEqual() {
        #expect(UploadState.uploading(progress: 0.5) == UploadState.uploading(progress: 0.5))
        #expect(UploadState.uploading(progress: 0.0) == UploadState.uploading(progress: 0.0))
        #expect(UploadState.uploading(progress: 1.0) == UploadState.uploading(progress: 1.0))
    }

    @Test("Uploading states with different progress are not equal")
    func uploadingStatesWithDifferentProgressAreNotEqual() {
        #expect(UploadState.uploading(progress: 0.5) != UploadState.uploading(progress: 0.6))
        #expect(UploadState.uploading(progress: 0.0) != UploadState.uploading(progress: 0.1))
    }

    @Test("Uploading states with similar progress within threshold are equal")
    func uploadingStatesSimilarProgressAreEqual() {
        // Within 0.001 threshold
        #expect(UploadState.uploading(progress: 0.5) == UploadState.uploading(progress: 0.5005))
    }

    @Test("Error states with same error are equal")
    func errorStatesWithSameErrorAreEqual() {
        let error1 = UploadError.cancelled
        let error2 = UploadError.cancelled
        #expect(UploadState.error(error1) == UploadState.error(error2))
    }

    @Test("Error states with different errors are not equal")
    func errorStatesWithDifferentErrorsAreNotEqual() {
        let error1 = UploadError.cancelled
        let error2 = UploadError.networkError(reason: "Timeout")
        #expect(UploadState.error(error1) != UploadState.error(error2))
    }

    @Test("Different state types are not equal")
    func differentStateTypesAreNotEqual() {
        #expect(UploadState.validating != UploadState.creating)
        #expect(UploadState.creating != UploadState.uploading(progress: 0.0))
        #expect(UploadState.uploading(progress: 1.0) != UploadState.processing)
        #expect(UploadState.processing != UploadState.ready)
    }

    // MARK: - Progress Property Tests

    @Test("Progress returns value for uploading state")
    func progressReturnsValueForUploadingState() {
        let state = UploadState.uploading(progress: 0.75)
        #expect(state.progress == 0.75)
    }

    @Test("Progress returns nil for non-uploading states")
    func progressReturnsNilForNonUploadingStates() {
        #expect(UploadState.validating.progress == nil)
        #expect(UploadState.creating.progress == nil)
        #expect(UploadState.processing.progress == nil)
        #expect(UploadState.ready.progress == nil)
        #expect(UploadState.error(.cancelled).progress == nil)
    }

    // MARK: - Error Property Tests

    @Test("UploadError returns value for error state")
    func uploadErrorReturnsValueForErrorState() {
        let error = UploadError.networkError(reason: "Connection lost")
        let state = UploadState.error(error)
        #expect(state.uploadError == error)
    }

    @Test("UploadError returns nil for non-error states")
    func uploadErrorReturnsNilForNonErrorStates() {
        #expect(UploadState.validating.uploadError == nil)
        #expect(UploadState.creating.uploadError == nil)
        #expect(UploadState.uploading(progress: 0.5).uploadError == nil)
        #expect(UploadState.processing.uploadError == nil)
        #expect(UploadState.ready.uploadError == nil)
    }

    // MARK: - Terminal State Tests

    @Test("Ready and error are terminal states")
    func readyAndErrorAreTerminalStates() {
        #expect(UploadState.ready.isTerminal == true)
        #expect(UploadState.error(.cancelled).isTerminal == true)
    }

    @Test("Other states are not terminal")
    func otherStatesAreNotTerminal() {
        #expect(UploadState.validating.isTerminal == false)
        #expect(UploadState.creating.isTerminal == false)
        #expect(UploadState.uploading(progress: 0.5).isTerminal == false)
        #expect(UploadState.processing.isTerminal == false)
    }

    // MARK: - Active State Tests

    @Test("Active states return true for isActive")
    func activeStatesReturnTrueForIsActive() {
        #expect(UploadState.validating.isActive == true)
        #expect(UploadState.creating.isActive == true)
        #expect(UploadState.uploading(progress: 0.5).isActive == true)
        #expect(UploadState.processing.isActive == true)
    }

    @Test("Terminal states return false for isActive")
    func terminalStatesReturnFalseForIsActive() {
        #expect(UploadState.ready.isActive == false)
        #expect(UploadState.error(.cancelled).isActive == false)
    }

    // MARK: - Description Tests

    @Test("Description provides human-readable text")
    func descriptionProvidesHumanReadableText() {
        #expect(UploadState.validating.description == "Validating file...")
        #expect(UploadState.creating.description == "Creating upload session...")
        #expect(UploadState.uploading(progress: 0.5).description == "Uploading (50%)")
        #expect(UploadState.processing.description == "Processing file...")
        #expect(UploadState.ready.description == "Upload complete")
    }
}

// MARK: - UploadError Tests

@Suite("UploadError")
struct UploadErrorTests {

    @Test("UploadError cases are Equatable")
    func uploadErrorCasesAreEquatable() {
        #expect(UploadError.cancelled == UploadError.cancelled)
        #expect(UploadError.validationFailed(reason: "Too large") == UploadError.validationFailed(reason: "Too large"))
        #expect(UploadError.validationFailed(reason: "Too large") != UploadError.validationFailed(reason: "Invalid type"))
    }

    @Test("UploadError is Sendable")
    func uploadErrorIsSendable() async {
        let error = UploadError.networkError(reason: "Timeout")

        let result = await Task {
            error
        }.value

        #expect(result == error)
    }
}
