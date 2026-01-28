import Testing
import Foundation
import EduGoCommon
@testable import Models
import EduGoCommon

@Suite("AcademicUnitMapper Tests")
struct AcademicUnitMapperTests {

    // MARK: - Test Data

    private let schoolID = UUID()
    private let parentUnitID = UUID()

    // MARK: - toDomain Tests

    @Test("toDomain with valid DTO returns AcademicUnit")
    func toDomainWithValidDTO() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "10th Grade",
            code: "G10",
            description: "Tenth grade students",
            type: "grade",
            parentUnitID: nil,
            schoolID: schoolID,
            metadata: ["capacity": .string("120")],
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )

        let unit = try AcademicUnitMapper.toDomain(dto)

        #expect(unit.id == dto.id)
        #expect(unit.displayName == "10th Grade")
        #expect(unit.code == "G10")
        #expect(unit.description == "Tenth grade students")
        #expect(unit.type == .grade)
        #expect(unit.parentUnitID == nil)
        #expect(unit.schoolID == schoolID)
        #expect(unit.isTopLevel == true)
    }

    @Test("toDomain with all unit types")
    func toDomainWithAllUnitTypes() throws {
        let types = ["grade", "section", "club", "department", "course"]
        let expectedTypes: [AcademicUnitType] = [.grade, .section, .club, .department, .course]

        for (typeString, expectedType) in zip(types, expectedTypes) {
            let dto = AcademicUnitDTO(
                id: UUID(),
                displayName: "Test Unit",
                code: nil,
                description: nil,
                type: typeString,
                parentUnitID: nil,
                schoolID: schoolID,
                metadata: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            let unit = try AcademicUnitMapper.toDomain(dto)
            #expect(unit.type == expectedType)
        }
    }

    @Test("toDomain with unknown type throws")
    func toDomainWithUnknownType() {
        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "Test Unit",
            code: nil,
            description: nil,
            type: "unknown_type",
            parentUnitID: nil,
            schoolID: schoolID,
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        #expect(throws: DomainError.self) {
            _ = try AcademicUnitMapper.toDomain(dto)
        }
    }

    @Test("toDomain with parent unit ID")
    func toDomainWithParentUnitID() throws {
        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "Section A",
            code: nil,
            description: nil,
            type: "section",
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        let unit = try AcademicUnitMapper.toDomain(dto)

        #expect(unit.parentUnitID == parentUnitID)
        #expect(unit.isTopLevel == false)
    }

    @Test("toDomain with deleted unit")
    func toDomainWithDeletedUnit() throws {
        let deletedAt = Date(timeIntervalSince1970: 3000)

        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "Deleted Unit",
            code: nil,
            description: nil,
            type: "grade",
            parentUnitID: nil,
            schoolID: schoolID,
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: deletedAt
        )

        let unit = try AcademicUnitMapper.toDomain(dto)

        #expect(unit.isDeleted == true)
        #expect(unit.deletedAt == deletedAt)
    }

    @Test("toDomain with empty displayName throws error")
    func toDomainWithEmptyDisplayNameThrows() {
        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "",
            code: nil,
            description: nil,
            type: "grade",
            parentUnitID: nil,
            schoolID: schoolID,
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        #expect(throws: DomainError.self) {
            _ = try AcademicUnitMapper.toDomain(dto)
        }
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts AcademicUnit correctly")
    func toDTOConvertsAcademicUnitCorrectly() throws {
        let unit = try AcademicUnit(
            id: UUID(),
            displayName: "10th Grade",
            code: "G10",
            description: "Tenth grade students",
            type: .grade,
            parentUnitID: nil,
            schoolID: schoolID,
            metadata: ["capacity": .string("120")],
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000),
            deletedAt: nil
        )

        let dto = AcademicUnitMapper.toDTO(unit)

        #expect(dto.id == unit.id)
        #expect(dto.displayName == "10th Grade")
        #expect(dto.code == "G10")
        #expect(dto.type == "grade")
        #expect(dto.schoolID == schoolID)
    }

    @Test("toDTO preserves parent unit ID")
    func toDTOPreservesParentUnitID() throws {
        let unit = try AcademicUnit(
            displayName: "Section A",
            type: .section,
            parentUnitID: parentUnitID,
            schoolID: schoolID
        )

        let dto = AcademicUnitMapper.toDTO(unit)

        #expect(dto.parentUnitID == parentUnitID)
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let original = try AcademicUnit(
            id: UUID(),
            displayName: "10th Grade",
            code: "G10",
            description: "Tenth grade students",
            type: .grade,
            parentUnitID: nil,
            schoolID: schoolID,
            metadata: ["key": .string("value")],
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )

        let dto = AcademicUnitMapper.toDTO(original)
        let converted = try AcademicUnitMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip with parent unit preserves hierarchy")
    func roundtripWithParentUnitPreservesHierarchy() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)

        let original = try AcademicUnit(
            displayName: "Section A",
            type: .section,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let dto = AcademicUnitMapper.toDTO(original)
        let converted = try AcademicUnitMapper.toDomain(dto)

        #expect(original == converted)
        #expect(converted.parentUnitID == parentUnitID)
    }

    @Test("roundtrip with deleted unit preserves data")
    func roundtripWithDeletedUnit() throws {
        let deletedAt = Date(timeIntervalSince1970: 3000)

        let original = try AcademicUnit(
            displayName: "Deleted Unit",
            type: .grade,
            schoolID: schoolID,
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000),
            deletedAt: deletedAt
        )

        let dto = AcademicUnitMapper.toDTO(original)
        let converted = try AcademicUnitMapper.toDomain(dto)

        #expect(original == converted)
    }

    // MARK: - Extension Method Tests

    @Test("AcademicUnitDTO.toDomain() works correctly")
    func dtoToDomainExtension() throws {
        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "Test Unit",
            code: nil,
            description: nil,
            type: "section",
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        let unit = try dto.toDomain()

        #expect(unit.id == dto.id)
        #expect(unit.type == .section)
    }

    @Test("AcademicUnit.toDTO() works correctly")
    func academicUnitToDTOExtension() throws {
        let unit = try AcademicUnit(
            displayName: "Test Unit",
            type: .department,
            schoolID: schoolID
        )

        let dto = unit.toDTO()

        #expect(dto.id == unit.id)
        #expect(dto.type == "department")
    }

    // MARK: - JSON Serialization Tests

    @Test("AcademicUnitDTO encodes to JSON with snake_case keys")
    func dtoEncodesToSnakeCaseJSON() throws {
        let createdAt = Date(timeIntervalSince1970: 1705318200)
        let updatedAt = Date(timeIntervalSince1970: 1705459500)
        let deletedAt = Date(timeIntervalSince1970: 1705500000)

        let dto = AcademicUnitDTO(
            id: UUID(),
            displayName: "10th Grade",
            code: "G10",
            description: "Tenth grade",
            type: "grade",
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            metadata: nil,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"display_name\""))
        #expect(json.contains("\"parent_unit_id\""))
        #expect(json.contains("\"school_id\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))
        #expect(json.contains("\"deleted_at\""))
        #expect(!json.contains("\"displayName\""))
        #expect(!json.contains("\"parentUnitID\""))
        #expect(!json.contains("\"schoolID\""))
    }

    @Test("AcademicUnitDTO decodes from JSON with snake_case keys")
    func dtoDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "display_name": "10th Grade",
            "code": "G10",
            "description": "Tenth grade students",
            "type": "grade",
            "parent_unit_id": null,
            "school_id": "660e8400-e29b-41d4-a716-446655440001",
            "metadata": null,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-20T14:45:00Z",
            "deleted_at": null
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(AcademicUnitDTO.self, from: data)

        #expect(dto.displayName == "10th Grade")
        #expect(dto.type == "grade")
        #expect(dto.parentUnitID == nil)
        #expect(dto.deletedAt == nil)
    }

    @Test("AcademicUnitDTO decodes from JSON with parent unit")
    func dtoDecodesFromJSONWithParentUnit() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "display_name": "Section A",
            "code": "G10-A",
            "description": null,
            "type": "section",
            "parent_unit_id": "770e8400-e29b-41d4-a716-446655440002",
            "school_id": "660e8400-e29b-41d4-a716-446655440001",
            "metadata": null,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-20T14:45:00Z",
            "deleted_at": null
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(AcademicUnitDTO.self, from: data)

        #expect(dto.displayName == "Section A")
        #expect(dto.type == "section")
        #expect(dto.parentUnitID != nil)
    }
}
