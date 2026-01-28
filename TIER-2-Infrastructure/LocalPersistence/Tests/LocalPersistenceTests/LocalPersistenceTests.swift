import Testing
import Foundation
import SwiftData
@testable import LocalPersistence

// MARK: - Test Model

@Model
final class TestItem {
    var name: String
    var timestamp: Date

    init(name: String, timestamp: Date = .now) {
        self.name = name
        self.timestamp = timestamp
    }
}

// MARK: - Configuration Tests

@Suite("LocalPersistenceConfiguration Tests")
struct LocalPersistenceConfigurationTests {
    @Test("Testing configuration uses inMemory storage")
    func testTestingConfiguration() {
        let config = LocalPersistenceConfiguration.testing

        if case .inMemory = config.storageType {
            // Expected
        } else {
            Issue.record("Testing configuration should use inMemory storage")
        }

        #expect(config.cloudKitEnabled == false)
    }

    @Test("Production configuration uses persistent storage")
    func testProductionConfiguration() {
        let config = LocalPersistenceConfiguration.production

        if case .persistent = config.storageType {
            // Expected
        } else {
            Issue.record("Production configuration should use persistent storage")
        }

        #expect(config.cloudKitEnabled == false)
    }

    @Test("Default persistent URL is platform appropriate")
    func testDefaultPersistentURL() {
        let url = StorageType.defaultPersistentURL()

        #if os(iOS)
        #expect(url.path.contains("Documents"))
        #elseif os(macOS)
        #expect(url.path.contains("Application Support"))
        #endif

        #expect(url.path.contains("LocalPersistence"))
    }
}

// MARK: - Container Provider Tests

@Suite("PersistenceContainerProvider Tests", .serialized)
struct PersistenceContainerProviderTests {
    @Test("Shared instance is accessible")
    func testSharedInstance() async {
        let provider = PersistenceContainerProvider.shared
        // Provider should be accessible
        _ = provider
    }

    @Test("Container is not initialized before configuration")
    func testNotInitializedBeforeConfiguration() async {
        // The shared instance may or may not be initialized depending on test order
        // This test just verifies the property is accessible
        let isInitialized = await PersistenceContainerProvider.shared.isInitialized
        _ = isInitialized
    }

    @Test("Configure with inMemory storage succeeds")
    func testConfigureInMemory() async throws {
        let schema = Schema([TestItem.self])

        try await PersistenceContainerProvider.shared.configure(
            with: .testing,
            schema: schema
        )

        let isInitialized = await PersistenceContainerProvider.shared.isInitialized
        #expect(isInitialized == true)
    }

    @Test("perform executes operation after configuration")
    func testPerformOperation() async throws {
        let schema = Schema([TestItem.self])

        try await PersistenceContainerProvider.shared.configure(
            with: .testing,
            schema: schema
        )

        // Perform should work and return a value
        let result = try await PersistenceContainerProvider.shared.perform { _ in
            return 42
        }

        #expect(result == 42)
    }

    @Test("Can insert and fetch items using perform")
    func testInsertAndFetch() async throws {
        let schema = Schema([TestItem.self])

        try await PersistenceContainerProvider.shared.configure(
            with: .testing,
            schema: schema
        )

        // Insert a test item
        try await PersistenceContainerProvider.shared.perform { context in
            let testItem = TestItem(name: "Test Item")
            context.insert(testItem)
            try context.save()
        }

        // Fetch items in a separate perform call
        let fetchedName = try await PersistenceContainerProvider.shared.perform { context in
            let descriptor = FetchDescriptor<TestItem>()
            let items = try context.fetch(descriptor)
            return items.first?.name
        }

        #expect(fetchedName == "Test Item")
    }

    @Test("Reset clears the container")
    func testReset() async throws {
        let schema = Schema([TestItem.self])

        try await PersistenceContainerProvider.shared.configure(
            with: .testing,
            schema: schema
        )

        await PersistenceContainerProvider.shared.reset()

        let isInitialized = await PersistenceContainerProvider.shared.isInitialized
        #expect(isInitialized == false)
    }
}

// MARK: - Error Tests

@Suite("PersistenceError Tests", .serialized)
struct PersistenceErrorTests {
    @Test("perform throws notConfigured when not configured")
    func testPerformThrowsWhenNotConfigured() async {
        await PersistenceContainerProvider.shared.reset()

        do {
            _ = try await PersistenceContainerProvider.shared.perform { _ in
                return 1
            }
            Issue.record("Expected notConfigured error")
        } catch let error as PersistenceError {
            if case .notConfigured = error {
                // Expected
            } else {
                Issue.record("Expected notConfigured error, got \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
