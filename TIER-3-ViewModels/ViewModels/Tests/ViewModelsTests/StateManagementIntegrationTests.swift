import Foundation
import Testing
@testable import ViewModels
@testable import StateManagement

// MARK: - Upload State Observer Tests

@Suite("Upload State Observer Tests")
struct UploadStateObserverTests {

    @Test("Handle uploading state updates progress")
    @MainActor
    func handleUploadingStateUpdatesProgress() {
        let observer = MockUploadObserver()

        observer.handleUploadState(.uploading(progress: 0.5))

        #expect(observer.uploadState == .uploading(progress: 0.5))
        #expect(observer.uploadProgress == 0.5)
        #expect(observer.uploadError == nil)
    }

    @Test("Handle ready state triggers callback")
    @MainActor
    func handleReadyStateTriggersCallback() {
        let observer = MockUploadObserver()

        observer.handleUploadState(.ready)

        #expect(observer.uploadState == .ready)
        #expect(observer.uploadProgress == 1.0)
        #expect(observer.uploadError == nil)
        #expect(observer.completedCalled == true)
    }

    @Test("Handle error state sets error")
    @MainActor
    func handleErrorStateSetsError() {
        let observer = MockUploadObserver()
        let error = UploadError.networkError(reason: "Test error")

        observer.handleUploadState(.error(error))

        #expect(observer.uploadState == .error(error))
        #expect(observer.uploadError == error)
    }
}

// MARK: - Assessment State Observer Tests

@Suite("Assessment State Observer Tests")
struct AssessmentStateObserverTests {

    @Test("Handle inProgress state updates counts")
    @MainActor
    func handleInProgressStateUpdatesCounts() {
        let observer = MockAssessmentObserver()

        observer.handleAssessmentState(.inProgress(answeredCount: 5, totalQuestions: 10))

        #expect(observer.assessmentState == .inProgress(answeredCount: 5, totalQuestions: 10))
        #expect(observer.answeredCount == 5)
        #expect(observer.totalQuestions == 10)
        #expect(observer.assessmentError == nil)
    }

    @Test("Handle completed state triggers callback with score")
    @MainActor
    func handleCompletedStateTriggersCallback() {
        let observer = MockAssessmentObserver()

        observer.handleAssessmentState(.completed(score: 0.85))

        #expect(observer.assessmentState == .completed(score: 0.85))
        #expect(observer.finalScore == 0.85)
        #expect(observer.assessmentError == nil)
        #expect(observer.completedScore == 0.85)
    }

    @Test("Handle error state sets error")
    @MainActor
    func handleErrorStateSetsError() {
        let observer = MockAssessmentObserver()
        let error = AssessmentError.timeout

        observer.handleAssessmentState(.error(error))

        #expect(observer.assessmentState == .error(error))
        #expect(observer.assessmentError == error)
    }
}

// MARK: - Dashboard State Observer Tests

@Suite("Dashboard State Observer Tests")
struct DashboardStateObserverTests {

    @Test("Handle loading state sets isLoading")
    @MainActor
    func handleLoadingStateSetsIsLoading() {
        let observer = MockDashboardObserver()
        let progress = LoadingProgress(userLoaded: true, unitsLoaded: false, materialsLoaded: false)

        observer.handleDashboardState(.loading(progress: progress))

        #expect(observer.isLoadingDashboard == true)
        #expect(observer.dashboardError == nil)
    }

    @Test("Handle partiallyLoaded state keeps partial data")
    @MainActor
    func handlePartiallyLoadedStateKeepsPartialData() {
        let observer = MockDashboardObserver()
        let partialData = PartialDashboardData(
            user: UserData(id: "1", name: "Test", email: "test@example.com"),
            units: nil,
            materials: nil
        )

        observer.handleDashboardState(.partiallyLoaded(data: partialData))

        #expect(observer.isLoadingDashboard == true)
        #expect(observer.partialData == partialData)
        #expect(observer.dashboardError == nil)
    }

    @Test("Handle ready state triggers callback with data")
    @MainActor
    func handleReadyStateTriggersCallback() {
        let observer = MockDashboardObserver()
        let dashboardData = DashboardData(
            user: UserData(id: "1", name: "Test", email: "test@example.com"),
            units: [],
            materials: []
        )

        observer.handleDashboardState(.ready(data: dashboardData))

        #expect(observer.isLoadingDashboard == false)
        #expect(observer.dashboardData == dashboardData)
        #expect(observer.partialData == nil)
        #expect(observer.dashboardError == nil)
        #expect(observer.loadedData != nil)
    }

    @Test("Handle error state sets error")
    @MainActor
    func handleErrorStateSetsError() {
        let observer = MockDashboardObserver()
        let error = DashboardError.timeout

        observer.handleDashboardState(.error(error))

        #expect(observer.isLoadingDashboard == false)
        #expect(observer.dashboardError == error)
    }
}

// MARK: - Upload State Computed Properties Tests

@Suite("Upload State Computed Properties Tests")
struct UploadStateComputedPropertiesTests {

    @Test("isValidating returns true for validating state")
    func isValidatingReturnsTrue() {
        let state = UploadState.validating
        #expect(state.isValidating == true)
        #expect(state.isCreating == false)
        #expect(state.isUploading == false)
    }

    @Test("isUploading returns true for uploading state")
    func isUploadingReturnsTrue() {
        let state = UploadState.uploading(progress: 0.5)
        #expect(state.isUploading == true)
        #expect(state.isValidating == false)
    }

    @Test("canCancel returns true for active states")
    func canCancelReturnsTrueForActiveStates() {
        #expect(UploadState.validating.canCancel == true)
        #expect(UploadState.creating.canCancel == true)
        #expect(UploadState.uploading(progress: 0.5).canCancel == true)
        #expect(UploadState.processing.canCancel == true)
        #expect(UploadState.ready.canCancel == false)
        #expect(UploadState.error(.cancelled).canCancel == false)
    }

    @Test("canRetry returns true for error state")
    func canRetryReturnsTrueForErrorState() {
        #expect(UploadState.error(.cancelled).canRetry == true)
        #expect(UploadState.ready.canRetry == false)
        #expect(UploadState.uploading(progress: 0.5).canRetry == false)
    }
}

// MARK: - Assessment State Computed Properties Tests

@Suite("Assessment State Computed Properties Tests")
struct AssessmentStateComputedPropertiesTests {

    @Test("isIdle returns true for idle state")
    func isIdleReturnsTrue() {
        let state = AssessmentState.idle
        #expect(state.isIdle == true)
        #expect(state.isLoading == false)
    }

    @Test("isInProgress returns true for inProgress state")
    func isInProgressReturnsTrue() {
        let state = AssessmentState.inProgress(answeredCount: 3, totalQuestions: 10)
        #expect(state.isInProgress == true)
        #expect(state.isIdle == false)
    }

    @Test("canSubmit returns true for inProgress state")
    func canSubmitReturnsTrueForInProgress() {
        #expect(AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10).canSubmit == true)
        #expect(AssessmentState.idle.canSubmit == false)
        #expect(AssessmentState.completed(score: 0.8).canSubmit == false)
    }

    @Test("canAnswer returns true for ready and inProgress states")
    func canAnswerReturnsTrueForReadyAndInProgress() {
        #expect(AssessmentState.ready.canAnswer == true)
        #expect(AssessmentState.inProgress(answeredCount: 0, totalQuestions: 10).canAnswer == true)
        #expect(AssessmentState.idle.canAnswer == false)
        #expect(AssessmentState.submitting.canAnswer == false)
    }
}

// MARK: - Dashboard State Computed Properties Tests

@Suite("Dashboard State Computed Properties Tests")
struct DashboardStateComputedPropertiesTests {

    @Test("isIdle returns true for idle state")
    func isIdleReturnsTrue() {
        let state = DashboardState.idle
        #expect(state.isIdle == true)
        #expect(state.isActivelyLoading == false)
    }

    @Test("isActivelyLoading returns true for loading states")
    func isActivelyLoadingReturnsTrue() {
        let progress = LoadingProgress()
        #expect(DashboardState.loading(progress: progress).isActivelyLoading == true)
        #expect(DashboardState.aggregating.isActivelyLoading == true)
        #expect(DashboardState.idle.isActivelyLoading == false)
    }

    @Test("canRefresh returns true for ready and error states")
    func canRefreshReturnsTrueForReadyAndError() {
        let dashboardData = DashboardData(
            user: UserData(id: "1", name: "Test", email: "test@example.com"),
            units: [],
            materials: []
        )
        #expect(DashboardState.ready(data: dashboardData).canRefresh == true)
        #expect(DashboardState.error(.timeout).canRefresh == true)
        #expect(DashboardState.idle.canRefresh == false)
    }

    @Test("hasDisplayableData returns true when data available")
    func hasDisplayableDataReturnsTrue() {
        let dashboardData = DashboardData(
            user: UserData(id: "1", name: "Test", email: "test@example.com"),
            units: [],
            materials: []
        )
        let partialData = PartialDashboardData(
            user: UserData(id: "1", name: "Test", email: "test@example.com")
        )
        #expect(DashboardState.ready(data: dashboardData).hasDisplayableData == true)
        #expect(DashboardState.partiallyLoaded(data: partialData).hasDisplayableData == true)
        #expect(DashboardState.idle.hasDisplayableData == false)
    }
}

// MARK: - Mock Observers

@MainActor
final class MockUploadObserver: UploadStateObserver {
    var uploadState: UploadState = .validating
    var uploadProgress: Double = 0.0
    var uploadError: UploadError?
    var completedCalled = false

    func onUploadCompleted() {
        completedCalled = true
    }
}

@MainActor
final class MockAssessmentObserver: AssessmentStateObserver {
    var assessmentState: AssessmentState = .idle
    var answeredCount: Int = 0
    var totalQuestions: Int = 0
    var finalScore: Double?
    var assessmentError: AssessmentError?
    var completedScore: Double?

    func onAssessmentCompleted(score: Double) {
        completedScore = score
    }
}

@MainActor
final class MockDashboardObserver: DashboardStateObserver {
    var dashboardState: DashboardState = .idle
    var isLoadingDashboard: Bool = false
    var dashboardData: DashboardData?
    var partialData: PartialDashboardData?
    var dashboardError: DashboardError?
    var loadedData: DashboardData?

    func onDashboardLoaded(_ data: DashboardData) {
        loadedData = data
    }
}
