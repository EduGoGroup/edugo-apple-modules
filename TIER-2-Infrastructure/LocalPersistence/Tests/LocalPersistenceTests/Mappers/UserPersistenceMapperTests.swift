import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("UserPersistenceMapper Tests")
struct UserPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical user")
    func testRoundtrip() throws {
        let original = try TestDataFactory.makeUser(
            name: "John Doe",
            email: "john@example.com",
            isActive: true,
            roleIDs: [UUID(), UUID()]
        )

        // Domain -> Model
        let model = UserPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try UserPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.name == original.name)
        #expect(restored.email == original.email)
        #expect(restored.isActive == original.isActive)
        #expect(restored.roleIDs == original.roleIDs)
    }

    @Test("Roundtrip with empty roleIDs")
    func testRoundtripEmptyRoles() throws {
        let original = try TestDataFactory.makeUser(roleIDs: [])

        let model = UserPersistenceMapper.toModel(original, existing: nil)
        let restored = try UserPersistenceMapper.toDomain(model)

        #expect(restored.roleIDs.isEmpty)
    }

    @Test("Roundtrip with many roleIDs preserves all")
    func testRoundtripManyRoles() throws {
        let roles: Set<UUID> = Set((0..<10).map { _ in UUID() })
        let original = try TestDataFactory.makeUser(roleIDs: roles)

        let model = UserPersistenceMapper.toModel(original, existing: nil)
        let restored = try UserPersistenceMapper.toDomain(model)

        #expect(restored.roleIDs.count == 10)
        #expect(restored.roleIDs == roles)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() throws {
        let user = try TestDataFactory.makeUser()

        let model = UserPersistenceMapper.toModel(user, existing: nil)

        #expect(model.id == user.id)
        #expect(model.name == user.name)
        #expect(model.email == user.email)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let user1 = try TestDataFactory.makeUser(name: "Original")
        let existingModel = UserPersistenceMapper.toModel(user1, existing: nil)

        let user2 = try User(
            id: user1.id,
            name: "Updated",
            email: user1.email,
            isActive: false,
            roleIDs: [UUID()]
        )

        let updatedModel = UserPersistenceMapper.toModel(user2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.name == "Updated")
        #expect(updatedModel.isActive == false)
        #expect(updatedModel.roleIDs.count == 1)
    }

    @Test("toModel converts Set to Array for roleIDs")
    func testSetToArrayConversion() throws {
        let roles: Set<UUID> = [UUID(), UUID(), UUID()]
        let user = try TestDataFactory.makeUser(roleIDs: roles)

        let model = UserPersistenceMapper.toModel(user, existing: nil)

        #expect(model.roleIDs.count == 3)
        #expect(Set(model.roleIDs) == roles)
    }

    // MARK: - toDomain Tests

    @Test("toDomain converts Array to Set for roleIDs")
    func testArrayToSetConversion() throws {
        let roleID = UUID()
        let model = UserModel(
            id: UUID(),
            name: "Test",
            email: "test@example.com",
            isActive: true,
            roleIDs: [roleID, roleID, roleID] // duplicates
        )

        let user = try UserPersistenceMapper.toDomain(model)

        // Set should deduplicate
        #expect(user.roleIDs.count == 1)
        #expect(user.roleIDs.contains(roleID))
    }

    @Test("toDomain throws for empty name")
    func testToDomainThrowsForEmptyName() {
        let model = UserModel(
            id: UUID(),
            name: "",
            email: "test@example.com",
            isActive: true,
            roleIDs: []
        )

        #expect(throws: DomainError.self) {
            _ = try UserPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for invalid email")
    func testToDomainThrowsForInvalidEmail() {
        let model = UserModel(
            id: UUID(),
            name: "Test User",
            email: "invalid-email",
            isActive: true,
            roleIDs: []
        )

        #expect(throws: DomainError.self) {
            _ = try UserPersistenceMapper.toDomain(model)
        }
    }
}
