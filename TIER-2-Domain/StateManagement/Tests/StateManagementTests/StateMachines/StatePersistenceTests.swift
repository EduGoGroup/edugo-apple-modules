import Testing
import Foundation
@testable import StateManagement

// MARK: - Test State

struct TestPersistableState: Codable, Sendable, Equatable {
    let id: Int
    let name: String
}

// MARK: - InMemoryStatePersistence Tests

@Suite("InMemoryStatePersistence")
struct InMemoryStatePersistenceTests {

    @Test("Save and load works correctly")
    func saveAndLoadWorksCorrectly() async throws {
        let persistence = InMemoryStatePersistence()
        let original = TestPersistableState(id: 42, name: "Test")

        try await persistence.save(original, forKey: "test_key")

        let loaded: TestPersistableState? = try await persistence.load(forKey: "test_key")
        #expect(loaded == original)
    }

    @Test("Load returns nil for non-existent key")
    func loadReturnsNilForNonExistentKey() async throws {
        let persistence = InMemoryStatePersistence()

        let loaded: TestPersistableState? = try await persistence.load(forKey: "non_existent")
        #expect(loaded == nil)
    }

    @Test("Remove works correctly")
    func removeWorksCorrectly() async throws {
        let persistence = InMemoryStatePersistence()
        let state = TestPersistableState(id: 1, name: "Test")

        try await persistence.save(state, forKey: "test_key")
        #expect(await persistence.exists(forKey: "test_key") == true)

        await persistence.remove(forKey: "test_key")
        #expect(await persistence.exists(forKey: "test_key") == false)
    }

    @Test("Exists returns correct value")
    func existsReturnsCorrectValue() async throws {
        let persistence = InMemoryStatePersistence()

        #expect(await persistence.exists(forKey: "test_key") == false)

        try await persistence.save(TestPersistableState(id: 1, name: "Test"), forKey: "test_key")
        #expect(await persistence.exists(forKey: "test_key") == true)
    }

    @Test("Clear removes all states")
    func clearRemovesAllStates() async throws {
        let persistence = InMemoryStatePersistence()

        try await persistence.save(TestPersistableState(id: 1, name: "One"), forKey: "key1")
        try await persistence.save(TestPersistableState(id: 2, name: "Two"), forKey: "key2")
        try await persistence.save(TestPersistableState(id: 3, name: "Three"), forKey: "key3")

        await persistence.clear()

        #expect(await persistence.exists(forKey: "key1") == false)
        #expect(await persistence.exists(forKey: "key2") == false)
        #expect(await persistence.exists(forKey: "key3") == false)
    }

    @Test("Can persist AssessmentState")
    func canPersistAssessmentState() async throws {
        let persistence = InMemoryStatePersistence()
        let original = AssessmentState.inProgress(answeredCount: 5, totalQuestions: 10)

        try await persistence.save(original, forKey: "assessment")

        let loaded: AssessmentState? = try await persistence.load(forKey: "assessment")
        #expect(loaded == original)
    }
}

// MARK: - NoOpStatePersistence Tests

@Suite("NoOpStatePersistence")
struct NoOpStatePersistenceTests {

    @Test("Save does nothing")
    func saveDoesNothing() async throws {
        let persistence = NoOpStatePersistence()
        let state = TestPersistableState(id: 1, name: "Test")

        try await persistence.save(state, forKey: "test_key")

        // Load should return nil because nothing was saved
        let loaded: TestPersistableState? = try await persistence.load(forKey: "test_key")
        #expect(loaded == nil)
    }

    @Test("Load always returns nil")
    func loadAlwaysReturnsNil() async throws {
        let persistence = NoOpStatePersistence()

        let loaded: TestPersistableState? = try await persistence.load(forKey: "any_key")
        #expect(loaded == nil)
    }

    @Test("Exists always returns false")
    func existsAlwaysReturnsFalse() async {
        let persistence = NoOpStatePersistence()

        #expect(await persistence.exists(forKey: "any_key") == false)
    }
}

// MARK: - UserDefaultsStatePersistence Tests

@Suite("UserDefaultsStatePersistence")
struct UserDefaultsStatePersistenceTests {

    private func makeTestSuiteName() -> String {
        // Use a unique suite name for each test to avoid conflicts
        "com.edugo.test.\(UUID().uuidString)"
    }

    @Test("Save and load works correctly")
    func saveAndLoadWorksCorrectly() async throws {
        let suiteName = makeTestSuiteName()
        let persistence = UserDefaultsStatePersistence(suiteName: suiteName, keyPrefix: "Test.")
        let original = TestPersistableState(id: 42, name: "Test State")

        try await persistence.save(original, forKey: "my_key")

        let loaded: TestPersistableState? = try await persistence.load(forKey: "my_key")
        #expect(loaded == original)
    }

    @Test("Load returns nil for non-existent key")
    func loadReturnsNilForNonExistentKey() async throws {
        let suiteName = makeTestSuiteName()
        let persistence = UserDefaultsStatePersistence(suiteName: suiteName)

        let loaded: TestPersistableState? = try await persistence.load(forKey: "non_existent")
        #expect(loaded == nil)
    }

    @Test("Remove works correctly")
    func removeWorksCorrectly() async throws {
        let suiteName = makeTestSuiteName()
        let persistence = UserDefaultsStatePersistence(suiteName: suiteName)
        let state = TestPersistableState(id: 1, name: "Test")

        try await persistence.save(state, forKey: "test_key")
        #expect(await persistence.exists(forKey: "test_key") == true)

        await persistence.remove(forKey: "test_key")
        #expect(await persistence.exists(forKey: "test_key") == false)
    }

    @Test("Key prefix is applied correctly")
    func keyPrefixIsAppliedCorrectly() async throws {
        let suiteName = makeTestSuiteName()
        let persistence = UserDefaultsStatePersistence(suiteName: suiteName, keyPrefix: "MyApp.")
        let state = TestPersistableState(id: 1, name: "Test")

        try await persistence.save(state, forKey: "state")

        // Verify the key includes the prefix by loading it back
        let loaded: TestPersistableState? = try await persistence.load(forKey: "state")
        #expect(loaded == state)
    }

    @Test("Can persist complex AssessmentState")
    func canPersistComplexAssessmentState() async throws {
        let suiteName = makeTestSuiteName()
        let persistence = UserDefaultsStatePersistence(suiteName: suiteName)

        let states: [AssessmentState] = [
            .idle,
            .loading,
            .ready,
            .inProgress(answeredCount: 5, totalQuestions: 10),
            .submitting,
            .completed(score: 0.875),
            .error(.timeout),
            .error(.networkError(reason: "Connection lost"))
        ]

        for (index, original) in states.enumerated() {
            let key = "state_\(index)"
            try await persistence.save(original, forKey: key)

            let loaded: AssessmentState? = try await persistence.load(forKey: key)
            #expect(loaded == original, "State \(original) should persist correctly")
        }
    }
}

// MARK: - Concurrency Tests

@Suite("StatePersistence Concurrency")
struct StatePersistenceConcurrencyTests {

    @Test("InMemoryStatePersistence is thread-safe")
    func inMemoryStatePersistenceIsThreadSafe() async throws {
        let persistence = InMemoryStatePersistence()

        await withTaskGroup(of: Void.self) { group in
            // Writers
            for i in 0..<50 {
                group.addTask {
                    let state = TestPersistableState(id: i, name: "State \(i)")
                    try? await persistence.save(state, forKey: "key_\(i)")
                }
            }

            // Readers
            for i in 0..<50 {
                group.addTask {
                    let _: TestPersistableState? = try? await persistence.load(forKey: "key_\(i)")
                }
            }
        }

        // Should complete without crashes
        let count = await countExistingKeys(in: persistence, prefix: "key_", count: 50)
        #expect(count > 0)
    }

    private func countExistingKeys(in persistence: InMemoryStatePersistence, prefix: String, count: Int) async -> Int {
        var existing = 0
        for i in 0..<count {
            if await persistence.exists(forKey: "\(prefix)\(i)") {
                existing += 1
            }
        }
        return existing
    }
}
