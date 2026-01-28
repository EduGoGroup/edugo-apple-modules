import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("AcademicUnitPersistenceMapper Tests")
struct AcademicUnitPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical unit")
    func testRoundtrip() throws {
        let schoolID = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        let original = try TestDataFactory.makeAcademicUnit(
            displayName: "Grade 5",
            type: .grade,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.displayName == original.displayName)
        #expect(restored.type == original.type)
        #expect(restored.schoolID == original.schoolID)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip preserves all unit types")
    func testRoundtripPreservesUnitTypes() throws {
        let types: [AcademicUnitType] = [.grade, .section, .club, .department, .course]

        for unitType in types {
            let original = try TestDataFactory.makeAcademicUnit(type: unitType)
            let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
            let restored = try AcademicUnitPersistenceMapper.toDomain(model)

            #expect(restored.type == unitType)
        }
    }

    @Test("Roundtrip preserves timestamps")
    func testRoundtripPreservesTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let original = try TestDataFactory.makeAcademicUnit(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = AcademicUnitPersistenceMapper.toModel(original, existing: nil)
        let restored = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() throws {
        let unit = try TestDataFactory.makeAcademicUnit()

        let model = AcademicUnitPersistenceMapper.toModel(unit, existing: nil)

        #expect(model.id == unit.id)
        #expect(model.displayName == unit.displayName)
        #expect(model.type == unit.type.rawValue)
        #expect(model.schoolID == unit.schoolID)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let unit1 = try TestDataFactory.makeAcademicUnit(displayName: "Original Unit")
        let existingModel = AcademicUnitPersistenceMapper.toModel(unit1, existing: nil)

        let newUpdatedAt = Date()
        let unit2 = try AcademicUnit(
            id: unit1.id,
            displayName: "Updated Unit",
            type: .section,
            parentUnitID: nil,
            schoolID: unit1.schoolID,
            createdAt: unit1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = AcademicUnitPersistenceMapper.toModel(unit2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.displayName == "Updated Unit")
        #expect(updatedModel.type == "section")
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel converts type enum to string")
    func testToModelConvertsTypeToString() throws {
        let unit = try TestDataFactory.makeAcademicUnit(type: .department)

        let model = AcademicUnitPersistenceMapper.toModel(unit, existing: nil)

        #expect(model.type == "department")
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain unit")
    func testToDomainCreatesValidUnit() throws {
        let schoolID = UUID()
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "Test Unit",
            type: "grade",
            schoolID: schoolID
        )

        let unit = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(unit.id == model.id)
        #expect(unit.displayName == model.displayName)
        #expect(unit.type == .grade)
        #expect(unit.schoolID == schoolID)
    }

    @Test("toDomain throws for empty displayName")
    func testToDomainThrowsForEmptyDisplayName() {
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "",
            type: "grade",
            schoolID: UUID()
        )

        #expect(throws: DomainError.self) {
            _ = try AcademicUnitPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain defaults unknown type to grade")
    func testToDomainDefaultsUnknownTypeToGrade() throws {
        let model = AcademicUnitModel(
            id: UUID(),
            displayName: "Test Unit",
            type: "unknown_type",
            schoolID: UUID()
        )

        let unit = try AcademicUnitPersistenceMapper.toDomain(model)

        #expect(unit.type == .grade)
    }

    @Test("toDomain converts all known type strings")
    func testToDomainConvertsAllKnownTypes() throws {
        let typeMapping: [(String, AcademicUnitType)] = [
            ("grade", .grade),
            ("section", .section),
            ("club", .club),
            ("department", .department),
            ("course", .course)
        ]

        for (typeString, expectedType) in typeMapping {
            let model = AcademicUnitModel(
                id: UUID(),
                displayName: "Test Unit",
                type: typeString,
                schoolID: UUID()
            )

            let unit = try AcademicUnitPersistenceMapper.toDomain(model)

            #expect(unit.type == expectedType)
        }
    }
}
