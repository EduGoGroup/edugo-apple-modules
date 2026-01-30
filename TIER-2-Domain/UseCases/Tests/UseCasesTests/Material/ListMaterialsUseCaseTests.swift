import XCTest
@testable import UseCases
import Models

// MARK: - Mock Repository

actor MockListMaterialsRepository: ListMaterialsRepositoryProtocol {
    var mockResponse: MaterialsRepositoryResponse?
    var mockError: Error?
    var callCount = 0
    var lastQuery: MaterialsQuery?
    var delay: TimeInterval = 0

    func setResponse(_ response: MaterialsRepositoryResponse?) {
        self.mockResponse = response
    }

    func setError(_ error: Error?) {
        self.mockError = error
    }

    func setDelay(_ delay: TimeInterval) {
        self.delay = delay
    }

    func list(query: MaterialsQuery) async throws -> MaterialsRepositoryResponse {
        callCount += 1
        lastQuery = query

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse else {
            throw ListMaterialsTestError.noMockData
        }

        return response
    }
}

enum ListMaterialsTestError: Error {
    case noMockData
    case networkError
}

// MARK: - Test Fixtures

enum ListMaterialsTestFixtures {
    static func createMaterial(
        id: UUID = UUID(),
        title: String = "Test Material"
    ) -> Material {
        // swiftlint:disable:next force_try
        try! Material(
            id: id,
            title: title,
            description: "Test description",
            status: .ready,
            fileURL: URL(string: "https://example.com/file.pdf"),
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            schoolID: UUID(),
            academicUnitID: UUID(),
            uploadedByTeacherID: UUID(),
            subject: "Mathematics",
            grade: "10th",
            isPublic: true,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    static func createMaterials(count: Int) -> [Material] {
        (0..<count).map { index in
            createMaterial(title: "Material \(index)")
        }
    }

    static func createResponse(
        materials: [Material],
        nextCursor: String? = nil,
        totalCount: Int? = nil
    ) -> MaterialsRepositoryResponse {
        MaterialsRepositoryResponse(
            materials: materials,
            nextCursor: nextCursor,
            totalCount: totalCount
        )
    }
}

// MARK: - Tests

final class ListMaterialsUseCaseTests: XCTestCase {

    var repository: MockListMaterialsRepository!
    var cache: MaterialsCacheService!
    var sut: ListMaterialsUseCase!

    override func setUp() async throws {
        try await super.setUp()
        repository = MockListMaterialsRepository()
        cache = MaterialsCacheService(maxEntries: 5, ttlSeconds: 60)
        sut = ListMaterialsUseCase(repository: repository, cache: cache)
    }

    override func tearDown() async throws {
        repository = nil
        cache = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Basic Tests

    func testExecute_ReturnsPage() async throws {
        // Arrange
        let materials = ListMaterialsTestFixtures.createMaterials(count: 3)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: materials)
        )

        let input = ListMaterialsInput()

        // Act
        let page = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(page.items.count, 3)
        XCTAssertNil(page.nextCursor)
        XCTAssertFalse(page.hasMore)
        XCTAssertFalse(page.isStale)
    }

    func testExecute_WithNextCursor_HasMore() async throws {
        // Arrange
        let materials = ListMaterialsTestFixtures.createMaterials(count: 20)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: materials,
                nextCursor: "next_page_cursor",
                totalCount: 100
            )
        )

        let input = ListMaterialsInput()

        // Act
        let page = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(page.items.count, 20)
        XCTAssertEqual(page.nextCursor, "next_page_cursor")
        XCTAssertTrue(page.hasMore)
        XCTAssertEqual(page.totalCount, 100)
    }

    func testExecute_EmptyResults_ReturnsEmptyPage() async throws {
        // Arrange
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: [])
        )

        let input = ListMaterialsInput()

        // Act
        let page = try await sut.execute(input: input)

        // Assert
        XCTAssertTrue(page.items.isEmpty)
        XCTAssertFalse(page.hasMore)
    }

    // MARK: - Filter Tests

    func testExecute_PassesFiltersToRepository() async throws {
        // Arrange
        let subjectId = UUID()
        let unitId = UUID()
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: [])
        )

        let input = ListMaterialsInput(
            filters: MaterialFilters(
                subjectId: subjectId,
                unitId: unitId,
                type: .pdf,
                status: .ready,
                searchQuery: "calculus"
            ),
            sortBy: .title,
            sortOrder: .ascending
        )

        // Act
        _ = try await sut.execute(input: input)

        // Assert
        let query = await repository.lastQuery
        XCTAssertEqual(query?.subjectId, subjectId)
        XCTAssertEqual(query?.unitId, unitId)
        XCTAssertEqual(query?.type, "pdf")
        XCTAssertEqual(query?.status, "ready")
        XCTAssertEqual(query?.searchQuery, "calculus")
        XCTAssertEqual(query?.sortBy, "title")
        XCTAssertEqual(query?.sortOrder, "asc")
    }

    func testExecute_PassesPaginationToRepository() async throws {
        // Arrange
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: [])
        )

        let input = ListMaterialsInput(
            pagination: CursorPagination(cursor: "page_2", limit: 50)
        )

        // Act
        _ = try await sut.execute(input: input)

        // Assert
        let query = await repository.lastQuery
        XCTAssertEqual(query?.cursor, "page_2")
        XCTAssertEqual(query?.limit, 50)
    }

    // MARK: - Validation Tests

    func testCursorPagination_ClampsLimit() {
        // Over max
        let over = CursorPagination(limit: 200)
        XCTAssertEqual(over.limit, 100)

        // Under min
        let under = CursorPagination(limit: 0)
        XCTAssertEqual(under.limit, 1)

        // Valid
        let valid = CursorPagination(limit: 50)
        XCTAssertEqual(valid.limit, 50)
    }

    // MARK: - Cache Tests

    func testExecute_UsesCacheOnSecondCall() async throws {
        // Arrange
        let materials = ListMaterialsTestFixtures.createMaterials(count: 3)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: materials)
        )

        let input = ListMaterialsInput()

        // Act - First call
        _ = try await sut.execute(input: input)

        // Clear mock to verify cache is used
        await repository.setResponse(nil)

        // Act - Second call (should use cache)
        let page = try await sut.execute(input: input)

        // Assert
        XCTAssertEqual(page.items.count, 3)

        let callCount = await repository.callCount
        XCTAssertEqual(callCount, 1) // Only called once
    }

    func testExecute_DifferentInputs_DifferentCacheKeys() async throws {
        // Arrange
        let materials1 = ListMaterialsTestFixtures.createMaterials(count: 2)
        let materials2 = ListMaterialsTestFixtures.createMaterials(count: 5)

        let input1 = ListMaterialsInput(sortBy: .createdAt)
        let input2 = ListMaterialsInput(sortBy: .title)

        // First call
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: materials1)
        )
        let page1 = try await sut.execute(input: input1)

        // Second call with different input
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: materials2)
        )
        let page2 = try await sut.execute(input: input2)

        // Assert - Both should have called repository
        let callCount = await repository.callCount
        XCTAssertEqual(callCount, 2)
        XCTAssertEqual(page1.items.count, 2)
        XCTAssertEqual(page2.items.count, 5)
    }

    func testExecute_NetworkError_ThrowsWhenNoCache() async throws {
        // Arrange - No prior cache, immediate error
        await repository.setError(ListMaterialsTestError.networkError)

        let input = ListMaterialsInput()

        // Act & Assert - Should throw since no cache exists
        do {
            _ = try await sut.execute(input: input)
            XCTFail("Expected error")
        } catch {
            // Expected - no stale cache to fall back to
            XCTAssertTrue(error is ListMaterialsTestError)
        }
    }

    func testCacheService_GetStale_ReturnsWithFlag() async {
        // Arrange - Cache with 0 TTL (immediately stale)
        let staleCache = MaterialsCacheService(maxEntries: 5, ttlSeconds: 0)

        let page = MaterialsPage(
            items: ListMaterialsTestFixtures.createMaterials(count: 3),
            nextCursor: nil,
            hasMore: false
        )
        await staleCache.set(key: "test", page: page)

        // Wait a tiny bit for TTL to expire
        try? await Task.sleep(nanoseconds: 1_000_000)

        // Act
        let stalePage = await staleCache.getStale(key: "test")

        // Assert
        XCTAssertNotNil(stalePage)
        XCTAssertTrue(stalePage?.isStale ?? false)
        XCTAssertEqual(stalePage?.items.count, 3)
    }

    func testInvalidateCache_ClearsAll() async throws {
        // Arrange
        let materials = ListMaterialsTestFixtures.createMaterials(count: 3)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: materials)
        )

        let input = ListMaterialsInput()
        _ = try await sut.execute(input: input)

        // Act
        await sut.invalidateCache()

        // New data
        let newMaterials = ListMaterialsTestFixtures.createMaterials(count: 5)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: newMaterials)
        )

        let page = try await sut.execute(input: input)

        // Assert - Should have fetched fresh data
        XCTAssertEqual(page.items.count, 5)

        let callCount = await repository.callCount
        XCTAssertEqual(callCount, 2)
    }

    // MARK: - Infinite Scroll Tests

    func testLoadInitial_SetsUpScrollState() async throws {
        // Arrange
        let materials = ListMaterialsTestFixtures.createMaterials(count: 20)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: materials,
                nextCursor: "cursor_2"
            )
        )

        let input = ListMaterialsInput()

        // Act
        let accumulated = try await sut.loadInitial(input: input)

        // Assert
        XCTAssertEqual(accumulated.items.count, 20)
        XCTAssertEqual(accumulated.nextCursor, "cursor_2")
        XCTAssertTrue(accumulated.hasMore)
        XCTAssertEqual(accumulated.pagesLoaded, 1)
    }

    func testLoadMore_AccumulatesItems() async throws {
        // Arrange
        let page1Materials = ListMaterialsTestFixtures.createMaterials(count: 20)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: page1Materials,
                nextCursor: "cursor_2"
            )
        )

        let input = ListMaterialsInput()
        _ = try await sut.loadInitial(input: input)

        // Setup page 2
        let page2Materials = ListMaterialsTestFixtures.createMaterials(count: 15)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: page2Materials,
                nextCursor: nil
            )
        )

        // Act
        let accumulated = try await sut.loadMore()

        // Assert
        XCTAssertEqual(accumulated.items.count, 35) // 20 + 15
        XCTAssertNil(accumulated.nextCursor)
        XCTAssertFalse(accumulated.hasMore)
        XCTAssertEqual(accumulated.pagesLoaded, 2)
    }

    func testLoadMore_DeduplicatesItems() async throws {
        // Arrange
        let sharedMaterial = ListMaterialsTestFixtures.createMaterial(title: "Shared")
        let page1Materials = [sharedMaterial] + ListMaterialsTestFixtures.createMaterials(count: 5)

        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: page1Materials,
                nextCursor: "cursor_2"
            )
        )

        let input = ListMaterialsInput()
        _ = try await sut.loadInitial(input: input)

        // Page 2 includes duplicate
        let page2Materials = [sharedMaterial] + ListMaterialsTestFixtures.createMaterials(count: 3)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: page2Materials,
                nextCursor: nil
            )
        )

        // Act
        let accumulated = try await sut.loadMore()

        // Assert - Should have 6 + 3 = 9 (not 10, because duplicate is removed)
        XCTAssertEqual(accumulated.items.count, 9)
    }

    func testLoadMore_WithoutInit_ThrowsError() async throws {
        // Act & Assert
        do {
            _ = try await sut.loadMore()
            XCTFail("Expected error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                XCTAssertTrue(description.contains("loadInitial"))
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testLoadMore_NoMorePages_ThrowsError() async throws {
        // Arrange
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: ListMaterialsTestFixtures.createMaterials(count: 5),
                nextCursor: nil // No more pages
            )
        )

        let input = ListMaterialsInput()
        _ = try await sut.loadInitial(input: input)

        // Act & Assert
        do {
            _ = try await sut.loadMore()
            XCTFail("Expected error")
        } catch let error as UseCaseError {
            if case .preconditionFailed(let description) = error {
                XCTAssertTrue(description.contains("más páginas"))
            } else {
                XCTFail("Wrong error type")
            }
        }
    }

    func testCanLoadMore_ReflectsState() async throws {
        // Initial - no cursor
        var canLoad = await sut.canLoadMore
        XCTAssertFalse(canLoad)

        // After loading with next cursor
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: ListMaterialsTestFixtures.createMaterials(count: 5),
                nextCursor: "next"
            )
        )
        _ = try await sut.loadInitial(input: ListMaterialsInput())

        canLoad = await sut.canLoadMore
        XCTAssertTrue(canLoad)
    }

    func testResetScrollState_ClearsAccumulated() async throws {
        // Arrange
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(
                materials: ListMaterialsTestFixtures.createMaterials(count: 10),
                nextCursor: "cursor"
            )
        )
        _ = try await sut.loadInitial(input: ListMaterialsInput())

        // Act
        await sut.resetScrollState()

        // Assert
        let accumulated = await sut.accumulated
        XCTAssertTrue(accumulated.items.isEmpty)
        XCTAssertEqual(accumulated.pagesLoaded, 0)
        XCTAssertFalse(accumulated.hasMore)
    }

    func testRefresh_ReloadsFromStart() async throws {
        // Arrange - Initial load
        let oldMaterials = ListMaterialsTestFixtures.createMaterials(count: 5)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: oldMaterials)
        )
        _ = try await sut.loadInitial(input: ListMaterialsInput())

        // New data for refresh
        let newMaterials = ListMaterialsTestFixtures.createMaterials(count: 10)
        await repository.setResponse(
            ListMaterialsTestFixtures.createResponse(materials: newMaterials)
        )

        // Act
        let refreshed = try await sut.refresh()

        // Assert
        XCTAssertEqual(refreshed.items.count, 10)
        XCTAssertEqual(refreshed.pagesLoaded, 1)
    }

    // MARK: - Model Tests

    func testMaterialFilters_None() {
        let filters = MaterialFilters.none
        XCTAssertNil(filters.subjectId)
        XCTAssertNil(filters.unitId)
        XCTAssertNil(filters.type)
        XCTAssertNil(filters.status)
        XCTAssertNil(filters.searchQuery)
    }

    func testMaterialsPage_Empty() {
        let page = MaterialsPage.empty
        XCTAssertTrue(page.items.isEmpty)
        XCTAssertNil(page.nextCursor)
        XCTAssertEqual(page.totalCount, 0)
        XCTAssertFalse(page.hasMore)
    }

    func testListMaterialsInput_DefaultValues() {
        let input = ListMaterialsInput()
        XCTAssertEqual(input.filters, .none)
        XCTAssertEqual(input.pagination.cursor, nil)
        XCTAssertEqual(input.pagination.limit, 20)
        XCTAssertEqual(input.sortBy, .createdAt)
        XCTAssertEqual(input.sortOrder, .descending)
    }

    // MARK: - Cache Service Tests

    func testCacheService_LRUEviction() async {
        // Cache with max 3 entries
        let smallCache = MaterialsCacheService(maxEntries: 3, ttlSeconds: 300)

        // Add 4 entries
        for i in 0..<4 {
            let page = MaterialsPage(
                items: [ListMaterialsTestFixtures.createMaterial(title: "M\(i)")],
                nextCursor: nil,
                hasMore: false
            )
            await smallCache.set(key: "key\(i)", page: page)
        }

        // Assert - first entry should be evicted
        let count = await smallCache.count
        XCTAssertEqual(count, 3)

        let evicted = await smallCache.get(key: "key0")
        XCTAssertNil(evicted)

        let kept = await smallCache.get(key: "key3")
        XCTAssertNotNil(kept)
    }
}
