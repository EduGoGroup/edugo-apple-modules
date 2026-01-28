import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("LocalUserRepository Tests", .serialized)
struct LocalUserRepositoryTests {
    private let schema = Schema([UserModel.self, DocumentModel.self])

    // MARK: - Setup Helper

    private func setupRepository() async throws -> LocalUserRepository {
        let provider = PersistenceContainerProvider()
        // Always configure a fresh provider to avoid cross-suite interference
        try await provider.configure(
            with: .testing,
            schema: schema
        )
        return LocalUserRepository(containerProvider: provider)
    }

    // MARK: - CRUD Tests

    @Test("Save and get user")
    func testSaveAndGet() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(name: "John Doe")

        try await repository.save(user)
        let fetched = try await repository.get(id: user.id)

        #expect(fetched != nil)
        #expect(fetched?.id == user.id)
        #expect(fetched?.name == "John Doe")
    }

    @Test("Get returns nil for non-existent user")
    func testGetReturnsNilForNonExistent() async throws {
        let repository = try await setupRepository()

        let fetched = try await repository.get(id: UUID())

        #expect(fetched == nil)
    }

    @Test("List returns saved users")
    func testListReturnsSavedUsers() async throws {
        let repository = try await setupRepository()
        let user1 = try TestDataFactory.makeUser(name: "User 1", email: "user1@test.com")
        let user2 = try TestDataFactory.makeUser(name: "User 2", email: "user2@test.com")

        try await repository.save(user1)
        try await repository.save(user2)

        let listed = try await repository.list()

        // Check that at least our users are present
        #expect(listed.contains { $0.id == user1.id })
        #expect(listed.contains { $0.id == user2.id })
    }

    @Test("Delete removes user")
    func testDeleteRemovesUser() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser()

        try await repository.save(user)
        try await repository.delete(id: user.id)

        let fetched = try await repository.get(id: user.id)
        #expect(fetched == nil)
    }

    @Test("Delete throws for non-existent user")
    func testDeleteThrowsForNonExistent() async throws {
        let repository = try await setupRepository()

        do {
            try await repository.delete(id: UUID())
            Issue.record("Expected deleteFailed error")
        } catch let error as RepositoryError {
            if case .deleteFailed = error {
                // Expected
            } else {
                Issue.record("Expected deleteFailed, got \(error)")
            }
        }
    }

    // MARK: - Upsert Tests

    @Test("Save same user twice updates instead of duplicating")
    func testUpsertUpdatesExisting() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(name: "Original Name")

        try await repository.save(user)

        let updatedUser = try User(
            id: user.id,
            name: "Updated Name",
            email: user.email,
            isActive: user.isActive,
            roleIDs: user.roleIDs
        )
        try await repository.save(updatedUser)

        let fetched = try await repository.get(id: user.id)
        #expect(fetched?.name == "Updated Name")
    }

    @Test("Upsert updates all fields")
    func testUpsertUpdatesAllFields() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(
            name: "Test",
            isActive: true,
            roleIDs: []
        )

        try await repository.save(user)

        let newRoleID = UUID()
        let updatedUser = try User(
            id: user.id,
            name: "Updated",
            email: user.email,
            isActive: false,
            roleIDs: [newRoleID]
        )
        try await repository.save(updatedUser)

        let fetched = try await repository.get(id: user.id)

        #expect(fetched?.name == "Updated")
        #expect(fetched?.isActive == false)
        #expect(fetched?.roleIDs.contains(newRoleID) == true)
    }

    // MARK: - Edge Cases

    @Test("Save user with empty roleIDs")
    func testSaveUserWithEmptyRoles() async throws {
        let repository = try await setupRepository()
        let user = try TestDataFactory.makeUser(roleIDs: [])

        try await repository.save(user)
        let fetched = try await repository.get(id: user.id)

        #expect(fetched?.roleIDs.isEmpty == true)
    }

    @Test("Save user with many roleIDs")
    func testSaveUserWithManyRoles() async throws {
        let repository = try await setupRepository()
        let roles: Set<UUID> = Set((0..<20).map { _ in UUID() })
        let user = try TestDataFactory.makeUser(roleIDs: roles)

        try await repository.save(user)
        let fetched = try await repository.get(id: user.id)

        #expect(fetched?.roleIDs.count == 20)
    }
}
