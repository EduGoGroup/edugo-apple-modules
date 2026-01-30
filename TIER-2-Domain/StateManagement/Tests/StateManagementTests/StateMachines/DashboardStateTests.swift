import Testing
import Foundation
@testable import StateManagement

// MARK: - DashboardState Tests

@Suite("DashboardState")
struct DashboardStateTests {

    @Test("Idle state is initial state")
    func idleStateIsInitial() {
        let state: DashboardState = .idle
        #expect(state == .idle)
        #expect(!state.isLoading)
        #expect(!state.isTerminal)
    }

    @Test("Loading state tracks progress")
    func loadingStateTracksProgress() {
        let progress = LoadingProgress(userLoaded: true, unitsLoaded: false, materialsLoaded: false)
        let state = DashboardState.loading(progress: progress)

        #expect(state.isLoading)
        #expect(state.loadingProgress?.userLoaded == true)
        #expect(state.loadingProgress?.completionPercentage == 1.0/3.0)
    }

    @Test("Ready state is terminal")
    func readyStateIsTerminal() {
        let data = DashboardData(
            user: UserData(id: "1", name: "Test", email: "test@test.com"),
            units: [],
            materials: []
        )
        let state = DashboardState.ready(data: data)

        #expect(state.isTerminal)
        #expect(state.dashboardData != nil)
    }

    @Test("Error state is terminal")
    func errorStateIsTerminal() {
        let state = DashboardState.error(.timeout)
        #expect(state.isTerminal)
        #expect(state.dashboardError == .timeout)
    }

    @Test("Description provides human-readable text")
    func descriptionProvidesHumanReadableText() {
        #expect(DashboardState.idle.description == "Dashboard not loaded")
        #expect(DashboardState.aggregating.description == "Preparing dashboard...")

        let progress = LoadingProgress(userLoaded: true, unitsLoaded: true, materialsLoaded: false)
        let loadingState = DashboardState.loading(progress: progress)
        #expect(loadingState.description.contains("66%"))
    }
}

// MARK: - LoadingProgress Tests

@Suite("LoadingProgress")
struct LoadingProgressTests {

    @Test("Initial progress is zero")
    func initialProgressIsZero() {
        let progress = LoadingProgress()
        #expect(progress.completionPercentage == 0.0)
        #expect(!progress.isComplete)
        #expect(progress.loadedCount == 0)
    }

    @Test("Complete when all loaded")
    func completeWhenAllLoaded() {
        let progress = LoadingProgress(userLoaded: true, unitsLoaded: true, materialsLoaded: true)
        #expect(progress.isComplete)
        #expect(progress.completionPercentage == 1.0)
        #expect(progress.loadedCount == 3)
    }

    @Test("Partial loading progress")
    func partialLoadingProgress() {
        let progress = LoadingProgress(userLoaded: true, unitsLoaded: false, materialsLoaded: true)
        #expect(!progress.isComplete)
        #expect(progress.loadedCount == 2)
        #expect(abs(progress.completionPercentage - 2.0/3.0) < 0.01)
    }
}

// MARK: - PartialDashboardData Tests

@Suite("PartialDashboardData")
struct PartialDashboardDataTests {

    @Test("Empty partial data has no data")
    func emptyPartialDataHasNoData() {
        let partial = PartialDashboardData()
        #expect(!partial.hasAnyData)
        #expect(partial.loadingProgress.loadedCount == 0)
    }

    @Test("Partial data with user only")
    func partialDataWithUserOnly() {
        let partial = PartialDashboardData(
            user: UserData(id: "1", name: "Test", email: "test@test.com")
        )
        #expect(partial.hasAnyData)
        #expect(partial.loadingProgress.userLoaded)
        #expect(!partial.loadingProgress.unitsLoaded)
    }

    @Test("IsFromCache flag is preserved")
    func isFromCacheFlagIsPreserved() {
        let partial = PartialDashboardData(isFromCache: true)
        #expect(partial.isFromCache)
    }
}

// MARK: - DashboardData Tests

@Suite("DashboardData")
struct DashboardDataTests {

    @Test("Creates from complete partial data")
    func createsFromCompletePartialData() {
        let partial = PartialDashboardData(
            user: UserData(id: "1", name: "Test", email: "test@test.com"),
            units: [UnitData(id: "u1", title: "Unit 1", progress: 0.5)],
            materials: [MaterialData(id: "m1", title: "Material 1", type: .video)]
        )

        let dashboard = DashboardData(from: partial)
        #expect(dashboard != nil)
        #expect(dashboard?.user.name == "Test")
        #expect(dashboard?.units.count == 1)
        #expect(dashboard?.materials.count == 1)
    }

    @Test("Returns nil from incomplete partial data")
    func returnsNilFromIncompletePartialData() {
        let partial = PartialDashboardData(
            user: UserData(id: "1", name: "Test", email: "test@test.com")
            // Missing units and materials
        )

        let dashboard = DashboardData(from: partial)
        #expect(dashboard == nil)
    }
}

// MARK: - UserData Tests

@Suite("UserData")
struct UserDataTests {

    @Test("Creates with all properties")
    func createsWithAllProperties() {
        let user = UserData(
            id: "123",
            name: "John Doe",
            email: "john@example.com",
            avatarURL: "https://example.com/avatar.png"
        )

        #expect(user.id == "123")
        #expect(user.name == "John Doe")
        #expect(user.email == "john@example.com")
        #expect(user.avatarURL == "https://example.com/avatar.png")
    }

    @Test("AvatarURL is optional")
    func avatarURLIsOptional() {
        let user = UserData(id: "123", name: "John", email: "john@example.com")
        #expect(user.avatarURL == nil)
    }
}

// MARK: - UnitData Tests

@Suite("UnitData")
struct UnitDataTests {

    @Test("Progress is clamped to valid range")
    func progressIsClampedToValidRange() {
        let unit1 = UnitData(id: "1", title: "Unit", progress: 1.5)
        #expect(unit1.progress == 1.0)

        let unit2 = UnitData(id: "2", title: "Unit", progress: -0.5)
        #expect(unit2.progress == 0.0)
    }

    @Test("IsLocked defaults to false")
    func isLockedDefaultsToFalse() {
        let unit = UnitData(id: "1", title: "Unit", progress: 0.5)
        #expect(!unit.isLocked)
    }
}

// MARK: - MaterialData Tests

@Suite("MaterialData")
struct MaterialDataTests {

    @Test("All material types are supported")
    func allMaterialTypesAreSupported() {
        #expect(MaterialType.video.rawValue == "video")
        #expect(MaterialType.document.rawValue == "document")
        #expect(MaterialType.audio.rawValue == "audio")
        #expect(MaterialType.quiz.rawValue == "quiz")
        #expect(MaterialType.interactive.rawValue == "interactive")
    }

    @Test("Duration is optional")
    func durationIsOptional() {
        let material = MaterialData(id: "1", title: "Doc", type: .document)
        #expect(material.duration == nil)

        let video = MaterialData(id: "2", title: "Video", type: .video, duration: 120)
        #expect(video.duration == 120)
    }
}

// MARK: - DashboardError Tests

@Suite("DashboardError")
struct DashboardErrorTests {

    @Test("All error types are equatable")
    func allErrorTypesAreEquatable() {
        #expect(DashboardError.timeout == DashboardError.timeout)
        #expect(DashboardError.cancelled == DashboardError.cancelled)
        #expect(DashboardError.userLoadFailed(reason: "test") == DashboardError.userLoadFailed(reason: "test"))
    }

    @Test("Different errors are not equal")
    func differentErrorsAreNotEqual() {
        #expect(DashboardError.timeout != DashboardError.cancelled)
    }
}

// MARK: - Codable Tests

@Suite("DashboardState Codable")
struct DashboardStateCodableTests {

    @Test("Idle state encodes and decodes")
    func idleStateEncodesAndDecodes() throws {
        let state = DashboardState.idle
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DashboardState.self, from: encoded)
        #expect(decoded == state)
    }

    @Test("Loading state encodes and decodes")
    func loadingStateEncodesAndDecodes() throws {
        let progress = LoadingProgress(userLoaded: true, unitsLoaded: false, materialsLoaded: true)
        let state = DashboardState.loading(progress: progress)
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DashboardState.self, from: encoded)
        #expect(decoded == state)
    }

    @Test("Ready state encodes and decodes")
    func readyStateEncodesAndDecodes() throws {
        let data = DashboardData(
            user: UserData(id: "1", name: "Test", email: "test@test.com"),
            units: [UnitData(id: "u1", title: "Unit", progress: 0.5)],
            materials: [MaterialData(id: "m1", title: "Mat", type: .video)]
        )
        let state = DashboardState.ready(data: data)
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DashboardState.self, from: encoded)
        #expect(decoded == state)
    }

    @Test("Error state encodes and decodes")
    func errorStateEncodesAndDecodes() throws {
        let state = DashboardState.error(.timeout)
        let encoded = try JSONEncoder().encode(state)
        let decoded = try JSONDecoder().decode(DashboardState.self, from: encoded)
        #expect(decoded == state)
    }
}
