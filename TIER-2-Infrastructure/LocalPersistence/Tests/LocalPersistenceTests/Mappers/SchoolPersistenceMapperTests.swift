import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("SchoolPersistenceMapper Tests")
struct SchoolPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical school")
    func testRoundtrip() throws {
        let createdAt = Date()
        let updatedAt = Date()
        let original = try TestDataFactory.makeSchool(
            name: "Test Academy",
            code: "TA001",
            isActive: true,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = SchoolPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.name == original.name)
        #expect(restored.code == original.code)
        #expect(restored.isActive == original.isActive)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip with inactive school")
    func testRoundtripInactiveSchool() throws {
        let original = try TestDataFactory.makeSchool(isActive: false)

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.isActive == false)
    }

    @Test("Roundtrip preserves all timestamps")
    func testRoundtripPreservesTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let original = try TestDataFactory.makeSchool(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    @Test("Roundtrip preserves metadata")
    func testRoundtripPreservesMetadata() throws {
        let metadata: [String: JSONValue] = [
            "founded": .integer(1990),
            "public": .bool(true),
            "motto": .string("Learning is fun")
        ]
        let original = try School(
            name: "Metadata School",
            code: "META-001",
            metadata: metadata
        )

        let model = SchoolPersistenceMapper.toModel(original, existing: nil)
        let restored = try SchoolPersistenceMapper.toDomain(model)

        #expect(restored.metadata == metadata)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() throws {
        let school = try TestDataFactory.makeSchool()

        let model = SchoolPersistenceMapper.toModel(school, existing: nil)

        #expect(model.id == school.id)
        #expect(model.name == school.name)
        #expect(model.code == school.code)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let school1 = try TestDataFactory.makeSchool(name: "Original School")
        let existingModel = SchoolPersistenceMapper.toModel(school1, existing: nil)

        let newUpdatedAt = Date()
        let school2 = try School(
            id: school1.id,
            name: "Updated School",
            code: school1.code,
            isActive: false,
            createdAt: school1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = SchoolPersistenceMapper.toModel(school2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.name == "Updated School")
        #expect(updatedModel.isActive == false)
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel preserves createdAt when updating")
    func testToModelPreservesCreatedAt() throws {
        let originalCreatedAt = Date(timeIntervalSince1970: 1000000)
        let school1 = try TestDataFactory.makeSchool(createdAt: originalCreatedAt)
        let existingModel = SchoolPersistenceMapper.toModel(school1, existing: nil)

        let school2 = try School(
            id: school1.id,
            name: "Updated School",
            code: school1.code,
            isActive: true,
            createdAt: originalCreatedAt,
            updatedAt: Date()
        )

        let updatedModel = SchoolPersistenceMapper.toModel(school2, existing: existingModel)

        #expect(updatedModel.createdAt == originalCreatedAt)
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain school")
    func testToDomainCreatesValidSchool() throws {
        let model = SchoolModel(
            id: UUID(),
            name: "Test School",
            code: "TS001",
            isActive: true
        )

        let school = try SchoolPersistenceMapper.toDomain(model)

        #expect(school.id == model.id)
        #expect(school.name == model.name)
        #expect(school.code == model.code)
        #expect(school.isActive == model.isActive)
    }

    @Test("toDomain throws for empty name")
    func testToDomainThrowsForEmptyName() {
        let model = SchoolModel(
            id: UUID(),
            name: "",
            code: "TS001",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try SchoolPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for empty code")
    func testToDomainThrowsForEmptyCode() {
        let model = SchoolModel(
            id: UUID(),
            name: "Test School",
            code: "",
            isActive: true
        )

        #expect(throws: DomainError.self) {
            _ = try SchoolPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain handles optional properties")
    func testToDomainHandlesOptionalProperties() throws {
        let model = SchoolModel(
            id: UUID(),
            name: "Test School",
            code: "TS001",
            isActive: true,
            address: "123 Main St",
            city: "Test City",
            country: "Test Country",
            contactEmail: "school@example.com",
            contactPhone: "+1234567890",
            maxStudents: 500,
            maxTeachers: 50,
            subscriptionTier: "premium"
        )

        let school = try SchoolPersistenceMapper.toDomain(model)

        #expect(school.address == "123 Main St")
        #expect(school.city == "Test City")
        #expect(school.country == "Test Country")
        #expect(school.contactEmail == "school@example.com")
        #expect(school.contactPhone == "+1234567890")
        #expect(school.maxStudents == 500)
        #expect(school.maxTeachers == 50)
        #expect(school.subscriptionTier == "premium")
    }
}
