import XCTest
@testable import UseCases

// MARK: - Mock Local Progress Repository

actor MockLocalProgressRepository: LocalProgressRepositoryProtocol {
    var unsyncedItems: [ProgressItem] = []
    var savedItems: [ProgressItem] = []
    var syncState: SyncState = SyncState()
    var markedAsSyncedIds: [UUID] = []
    var getUnsyncedError: Error?
    var saveError: Error?

    func setUnsyncedItems(_ items: [ProgressItem]) {
        self.unsyncedItems = items
    }

    func setSyncState(_ state: SyncState) {
        self.syncState = state
    }

    func setGetUnsyncedError(_ error: Error?) {
        self.getUnsyncedError = error
    }

    func setSaveError(_ error: Error?) {
        self.saveError = error
    }

    func getUnsyncedItems(userId: UUID, since: Date?) async throws -> [ProgressItem] {
        if let error = getUnsyncedError {
            throw error
        }
        return unsyncedItems
    }

    func saveItems(_ items: [ProgressItem]) async throws {
        if let error = saveError {
            throw error
        }
        savedItems.append(contentsOf: items)
    }

    func markAsSynced(itemIds: [UUID]) async throws {
        markedAsSyncedIds.append(contentsOf: itemIds)
    }

    func getSyncState(userId: UUID) async -> SyncState {
        syncState
    }

    func saveSyncState(_ state: SyncState, userId: UUID) async throws {
        syncState = state
    }
}

// MARK: - Mock Remote Progress Repository

actor MockRemoteProgressRepository: RemoteProgressRepositoryProtocol {
    var remoteItems: [ProgressItem] = []
    var pushedItems: [ProgressItem] = []
    var fetchError: Error?
    var pushError: Error?
    var fetchCallCount = 0
    var pushCallCount = 0

    func setRemoteItems(_ items: [ProgressItem]) {
        self.remoteItems = items
    }

    func setFetchError(_ error: Error?) {
        self.fetchError = error
    }

    func setPushError(_ error: Error?) {
        self.pushError = error
    }

    func fetchItems(userId: UUID, since: Date?) async throws -> [ProgressItem] {
        fetchCallCount += 1
        if let error = fetchError {
            throw error
        }
        return remoteItems
    }

    func pushItems(_ items: [ProgressItem]) async throws -> [ProgressItem] {
        pushCallCount += 1
        if let error = pushError {
            throw error
        }
        pushedItems.append(contentsOf: items)
        return items.map { $0.markSynced() }
    }
}

// MARK: - Mock Conflict Resolver

actor MockConflictResolver: ConflictResolverProtocol {
    var resolutions: [UUID: ConflictResolution] = [:]
    var resolveCallCount = 0

    func setResolution(for materialId: UUID, resolution: ConflictResolution) {
        resolutions[materialId] = resolution
    }

    nonisolated func resolve(
        conflict: ProgressConflict,
        strategy: ConflictResolutionStrategy
    ) -> ConflictResolution {
        // Usar estrategia por defecto para tests
        let defaultResolver = DefaultConflictResolver()
        return defaultResolver.resolve(conflict: conflict, strategy: strategy)
    }
}

// MARK: - Test Errors

enum SyncTestError: Error {
    case networkError
    case serverError
    case storageError
}

// MARK: - Test Fixtures

enum SyncProgressTestFixtures {
    static func createProgressItem(
        id: UUID = UUID(),
        materialId: UUID = UUID(),
        userId: UUID = UUID(),
        percentage: Int = 50,
        lastUpdated: Date = Date(),
        isSynced: Bool = false
    ) -> ProgressItem {
        ProgressItem(
            id: id,
            materialId: materialId,
            userId: userId,
            percentage: percentage,
            lastUpdated: lastUpdated,
            isSynced: isSynced
        )
    }

    static func createConflict(
        materialId: UUID = UUID(),
        localPercentage: Int = 50,
        remotePercentage: Int = 75,
        localDate: Date = Date().addingTimeInterval(-3600),
        remoteDate: Date = Date()
    ) -> (local: ProgressItem, remote: ProgressItem) {
        let userId = UUID()
        let local = ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: localPercentage,
            lastUpdated: localDate,
            isSynced: false
        )
        let remote = ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: remotePercentage,
            lastUpdated: remoteDate,
            isSynced: true
        )
        return (local, remote)
    }
}

// MARK: - Tests

final class SyncProgressUseCaseTests: XCTestCase {

    var localRepo: MockLocalProgressRepository!
    var remoteRepo: MockRemoteProgressRepository!
    var conflictResolver: MockConflictResolver!
    var sut: SyncProgressUseCase!

    override func setUp() async throws {
        try await super.setUp()
        localRepo = MockLocalProgressRepository()
        remoteRepo = MockRemoteProgressRepository()
        conflictResolver = MockConflictResolver()
        sut = SyncProgressUseCase(
            localRepository: localRepo,
            remoteRepository: remoteRepo,
            conflictResolver: DefaultConflictResolver()
        )
    }

    override func tearDown() async throws {
        localRepo = nil
        remoteRepo = nil
        conflictResolver = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Basic Sync Tests

    func testExecute_SyncsLocalItemsToRemote() async throws {
        // Arrange
        let userId = UUID()
        let localItem = SyncProgressTestFixtures.createProgressItem(userId: userId)
        await localRepo.setUnsyncedItems([localItem])

        let input = SyncProgressInput(userId: userId)

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(output.syncedItems.count, 1)
        XCTAssertEqual(output.metadata.pushedCount, 1)
        XCTAssertEqual(output.metadata.pulledCount, 0)
        XCTAssertTrue(output.conflicts.isEmpty)
    }

    func testExecute_PullsRemoteItemsToLocal() async throws {
        // Arrange
        let userId = UUID()
        let remoteItem = SyncProgressTestFixtures.createProgressItem(userId: userId)
        await remoteRepo.setRemoteItems([remoteItem])

        let input = SyncProgressInput(userId: userId)

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(output.syncedItems.count, 1)
        XCTAssertEqual(output.metadata.pulledCount, 1)
        XCTAssertEqual(output.metadata.pushedCount, 0)

        let savedItems = await localRepo.savedItems
        XCTAssertEqual(savedItems.count, 1)
    }

    func testExecute_SyncsBothDirections() async throws {
        // Arrange
        let userId = UUID()
        let localMaterialId = UUID()
        let remoteMaterialId = UUID()

        let localItem = SyncProgressTestFixtures.createProgressItem(
            materialId: localMaterialId,
            userId: userId
        )
        let remoteItem = SyncProgressTestFixtures.createProgressItem(
            materialId: remoteMaterialId,
            userId: userId
        )

        await localRepo.setUnsyncedItems([localItem])
        await remoteRepo.setRemoteItems([remoteItem])

        let input = SyncProgressInput(userId: userId)

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(output.syncedItems.count, 2)
        XCTAssertEqual(output.metadata.pushedCount, 1)
        XCTAssertEqual(output.metadata.pulledCount, 1)
    }

    // MARK: - Conflict Detection Tests

    func testExecute_DetectsConflict_WhenSameMaterialDifferentData() async throws {
        // Arrange
        let userId = UUID()
        let materialId = UUID()
        let (localItem, remoteItem) = SyncProgressTestFixtures.createConflict(
            materialId: materialId,
            localPercentage: 30,
            remotePercentage: 70
        )

        await localRepo.setUnsyncedItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 30,
            lastUpdated: Date().addingTimeInterval(-3600)
        )])
        await remoteRepo.setRemoteItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 70,
            lastUpdated: Date()
        )])

        let input = SyncProgressInput(
            userId: userId,
            conflictStrategy: .manual
        )

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(output.conflicts.count, 1)
        XCTAssertEqual(output.conflicts.first?.materialId, materialId)
    }

    // MARK: - Conflict Resolution Tests

    func testExecute_ResolvesConflict_WithMostRecentStrategy() async throws {
        // Arrange
        let userId = UUID()
        let materialId = UUID()
        let olderDate = Date().addingTimeInterval(-3600)
        let newerDate = Date()

        await localRepo.setUnsyncedItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 30,
            lastUpdated: olderDate
        )])
        await remoteRepo.setRemoteItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 70,
            lastUpdated: newerDate
        )])

        let input = SyncProgressInput(
            userId: userId,
            conflictStrategy: .mostRecent
        )

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertTrue(output.conflicts.isEmpty)
        XCTAssertEqual(output.metadata.autoResolvedCount, 1)
    }

    func testExecute_ResolvesConflict_WithLocalWinsStrategy() async throws {
        // Arrange
        let userId = UUID()
        let materialId = UUID()

        await localRepo.setUnsyncedItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 30,
            lastUpdated: Date()
        )])
        await remoteRepo.setRemoteItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 70,
            lastUpdated: Date()
        )])

        let input = SyncProgressInput(
            userId: userId,
            conflictStrategy: .localWins
        )

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertTrue(output.conflicts.isEmpty)
        XCTAssertEqual(output.metadata.autoResolvedCount, 1)
    }

    func testExecute_ResolvesConflict_WithRemoteWinsStrategy() async throws {
        // Arrange
        let userId = UUID()
        let materialId = UUID()

        await localRepo.setUnsyncedItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 30,
            lastUpdated: Date()
        )])
        await remoteRepo.setRemoteItems([ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 70,
            lastUpdated: Date()
        )])

        let input = SyncProgressInput(
            userId: userId,
            conflictStrategy: .remoteWins
        )

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertTrue(output.conflicts.isEmpty)
        XCTAssertEqual(output.metadata.autoResolvedCount, 1)
    }

    // MARK: - Error Handling Tests

    func testExecute_HandlesRemoteError_WithRetryQueue() async throws {
        // Arrange
        let userId = UUID()
        let localItem = SyncProgressTestFixtures.createProgressItem(userId: userId)
        await localRepo.setUnsyncedItems([localItem])
        await remoteRepo.setFetchError(SyncTestError.networkError)

        let input = SyncProgressInput(userId: userId)

        // Act & Assert
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch {
            // Expected - verify items were saved for retry
            let syncState = await localRepo.syncState
            XCTAssertEqual(syncState.pendingRetryItems.count, 1)
        }
    }

    func testExecute_HandlesPushError_AddsToPendingRetry() async throws {
        // Arrange
        let userId = UUID()
        let localItem = SyncProgressTestFixtures.createProgressItem(userId: userId)
        await localRepo.setUnsyncedItems([localItem])
        await remoteRepo.setPushError(SyncTestError.serverError)

        let input = SyncProgressInput(userId: userId)

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(output.pendingRetry.count, 1)
        XCTAssertEqual(output.syncedItems.count, 0)
    }

    // MARK: - Incremental Sync Tests

    func testExecute_UsesIncrementalSync_WhenNotForced() async throws {
        // Arrange
        let userId = UUID()
        let lastSync = Date().addingTimeInterval(-3600)
        await localRepo.setSyncState(SyncState(lastSyncTimestamp: lastSync))

        let input = SyncProgressInput(userId: userId, forceFullSync: false)

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertTrue(output.metadata.wasIncremental)
    }

    func testExecute_UsesFullSync_WhenForced() async throws {
        // Arrange
        let userId = UUID()
        let lastSync = Date().addingTimeInterval(-3600)
        await localRepo.setSyncState(SyncState(lastSyncTimestamp: lastSync))

        let input = SyncProgressInput(userId: userId, forceFullSync: true)

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertFalse(output.metadata.wasIncremental)
    }

    // MARK: - No Items Tests

    func testExecute_ReturnsEmpty_WhenNoItemsToSync() async throws {
        // Arrange
        let userId = UUID()
        let input = SyncProgressInput(userId: userId)

        // Act
        let output = try await sut.execute(input: input)

        // Assert
        XCTAssertTrue(output.syncedItems.isEmpty)
        XCTAssertTrue(output.conflicts.isEmpty)
        XCTAssertEqual(output.metadata.pushedCount, 0)
        XCTAssertEqual(output.metadata.pulledCount, 0)
    }

    // MARK: - Model Tests

    func testSyncProgressInput_Equatable() {
        let userId = UUID()

        let input1 = SyncProgressInput(userId: userId, forceFullSync: false)
        let input2 = SyncProgressInput(userId: userId, forceFullSync: false)
        let input3 = SyncProgressInput(userId: userId, forceFullSync: true)

        XCTAssertEqual(input1, input2)
        XCTAssertNotEqual(input1, input3)
    }

    func testProgressItem_MarkSynced() {
        let item = SyncProgressTestFixtures.createProgressItem(isSynced: false)
        let synced = item.markSynced()

        XCTAssertFalse(item.isSynced)
        XCTAssertTrue(synced.isSynced)
        XCTAssertEqual(item.materialId, synced.materialId)
    }

    func testConflictResolutionStrategy_RawValues() {
        XCTAssertEqual(ConflictResolutionStrategy.localWins.rawValue, "local_wins")
        XCTAssertEqual(ConflictResolutionStrategy.remoteWins.rawValue, "remote_wins")
        XCTAssertEqual(ConflictResolutionStrategy.mostRecent.rawValue, "most_recent")
        XCTAssertEqual(ConflictResolutionStrategy.manual.rawValue, "manual")
    }

    func testSyncProgressError_LocalizedDescriptions() {
        let errors: [SyncProgressError] = [
            .noItemsToSync,
            .partialSyncFailure(synced: 5, failed: 2),
            .networkUnavailable,
            .serverConflict(materialId: UUID()),
            .invalidSyncState,
            .batchSizeExceeded(max: 50)
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testDefaultConflictResolver_MostRecent_LocalNewer() {
        let resolver = DefaultConflictResolver()
        let materialId = UUID()
        let userId = UUID()

        let localItem = ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 80,
            lastUpdated: Date() // Newer
        )
        let remoteItem = ProgressItem(
            materialId: materialId,
            userId: userId,
            percentage: 50,
            lastUpdated: Date().addingTimeInterval(-3600) // Older
        )
        let conflict = ProgressConflict(
            materialId: materialId,
            localItem: localItem,
            remoteItem: remoteItem
        )

        let resolution = resolver.resolve(conflict: conflict, strategy: .mostRecent)

        XCTAssertEqual(resolution.resolvedItem?.percentage, 80)
        XCTAssertFalse(resolution.requiresManualDecision)
    }

    func testDefaultConflictResolver_Manual_RequiresDecision() {
        let resolver = DefaultConflictResolver()
        let materialId = UUID()
        let userId = UUID()

        let conflict = ProgressConflict(
            materialId: materialId,
            localItem: ProgressItem(materialId: materialId, userId: userId, percentage: 50, lastUpdated: Date()),
            remoteItem: ProgressItem(materialId: materialId, userId: userId, percentage: 75, lastUpdated: Date())
        )

        let resolution = resolver.resolve(conflict: conflict, strategy: .manual)

        XCTAssertNil(resolution.resolvedItem)
        XCTAssertTrue(resolution.requiresManualDecision)
    }

    func testSyncMetadata_DefaultValues() {
        let metadata = SyncMetadata()

        XCTAssertEqual(metadata.pushedCount, 0)
        XCTAssertEqual(metadata.pulledCount, 0)
        XCTAssertEqual(metadata.autoResolvedCount, 0)
        XCTAssertEqual(metadata.durationSeconds, 0)
        XCTAssertTrue(metadata.wasIncremental)
    }

    func testSyncState_DefaultValues() {
        let state = SyncState()

        XCTAssertNil(state.lastSyncTimestamp)
        XCTAssertTrue(state.syncedItemIds.isEmpty)
        XCTAssertTrue(state.pendingRetryItems.isEmpty)
    }
}
