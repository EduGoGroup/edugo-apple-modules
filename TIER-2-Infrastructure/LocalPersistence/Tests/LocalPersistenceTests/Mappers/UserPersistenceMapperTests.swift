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
        let createdAt = Date()
        let updatedAt = Date()
        let original = try TestDataFactory.makeUser(
            firstName: "John",
            lastName: "Doe",
            email: "john@example.com",
            isActive: true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = UserPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try UserPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.firstName == original.firstName)
        #expect(restored.lastName == original.lastName)
        #expect(restored.email == original.email)
        #expect(restored.isActive == original.isActive)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip with inactive user")
    func testRoundtripInactiveUser() throws {
        let original = try TestDataFactory.makeUser(isActive: false)

        let model = UserPersistenceMapper.toModel(original, existing: nil)
        let restored = try UserPersistenceMapper.toDomain(model)

        #expect(restored.isActive == false)
    }

    @Test("Roundtrip preserves all timestamps")
    func testRoundtripPreservesTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let original = try TestDataFactory.makeUser(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = UserPersistenceMapper.toModel(original, existing: nil)
        let restored = try UserPersistenceMapper.toDomain(model)

        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() throws {
        let user = try TestDataFactory.makeUser()

        let model = UserPersistenceMapper.toModel(user, existing: nil)

        #expect(model.id == user.id)
        #expect(model.firstName == user.firstName)
        #expect(model.lastName == user.lastName)
        #expect(model.email == user.email)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let user1 = try TestDataFactory.makeUser(firstName: "Original", lastName: "User")
        let existingModel = UserPersistenceMapper.toModel(user1, existing: nil)

        let newUpdatedAt = Date()
        let user2 = try User(
            id: user1.id,
            firstName: "Updated",
            lastName: "Name",
            email: user1.email,
            isActive: false,
            createdAt: user1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = UserPersistenceMapper.toModel(user2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.firstName == "Updated")
        #expect(updatedModel.lastName == "Name")
        #expect(updatedModel.isActive == false)
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel preserves createdAt when updating")
    func testToModelPreservesCreatedAt() throws {
        let originalCreatedAt = Date(timeIntervalSince1970: 1000000)
        let user1 = try TestDataFactory.makeUser(createdAt: originalCreatedAt)
        let existingModel = UserPersistenceMapper.toModel(user1, existing: nil)

        let user2 = try User(
            id: user1.id,
            firstName: "Updated",
            lastName: "User",
            email: user1.email,
            isActive: true,
            createdAt: originalCreatedAt,
            updatedAt: Date()
        )

        let updatedModel = UserPersistenceMapper.toModel(user2, existing: existingModel)

        #expect(updatedModel.createdAt == originalCreatedAt)
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain user")
    func testToDomainCreatesValidUser() throws {
        let model = UserModel(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "test@example.com",
            isActive: true
        )

        let user = try UserPersistenceMapper.toDomain(model)

        #expect(user.id == model.id)
        #expect(user.firstName == model.firstName)
        #expect(user.lastName == model.lastName)
        #expect(user.email == model.email)
        #expect(user.isActive == model.isActive)
    }

    @Test("toDomain throws for empty firstName")
    func testToDomainThrowsForEmptyFirstName() {
        let model = UserModel(
            id: UUID(),
            firstName: "",
            lastName: "User",
            email: "test@example.com",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try UserPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for empty lastName")
    func testToDomainThrowsForEmptyLastName() {
        let model = UserModel(
            id: UUID(),
            firstName: "Test",
            lastName: "",
            email: "test@example.com",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try UserPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for invalid email")
    func testToDomainThrowsForInvalidEmail() {
        let model = UserModel(
            id: UUID(),
            firstName: "Test",
            lastName: "User",
            email: "invalid-email",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try UserPersistenceMapper.toDomain(model)
        }
    }
}
