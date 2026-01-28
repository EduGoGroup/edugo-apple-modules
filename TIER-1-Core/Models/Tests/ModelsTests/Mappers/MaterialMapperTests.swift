import Testing
import Foundation
@testable import Models
import EduGoCommon

@Suite("MaterialMapper Tests")
struct MaterialMapperTests {

    // MARK: - Test Data

    private let schoolID = UUID()
    private let academicUnitID = UUID()
    private let teacherID = UUID()
    private let fileURLString = "https://s3.amazonaws.com/bucket/materials/test.pdf"

    // MARK: - toDomain Tests

    @Test("toDomain with valid DTO returns Material")
    func toDomainWithValidDTO() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let dto = MaterialDTO(
            id: UUID(),
            title: "Introduction to Calculus",
            description: "A comprehensive guide",
            status: "ready",
            fileURL: fileURLString,
            fileType: "application/pdf",
            fileSizeBytes: 1048576,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: teacherID,
            subject: "Mathematics",
            grade: "12th Grade",
            isPublic: false,
            processingStartedAt: createdAt,
            processingCompletedAt: updatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )

        let material = try MaterialMapper.toDomain(dto)

        #expect(material.id == dto.id)
        #expect(material.title == "Introduction to Calculus")
        #expect(material.description == "A comprehensive guide")
        #expect(material.status == .ready)
        #expect(material.fileURL?.absoluteString == fileURLString)
        #expect(material.fileType == "application/pdf")
        #expect(material.fileSizeBytes == 1048576)
        #expect(material.schoolID == schoolID)
        #expect(material.academicUnitID == academicUnitID)
        #expect(material.uploadedByTeacherID == teacherID)
        #expect(material.subject == "Mathematics")
        #expect(material.grade == "12th Grade")
        #expect(material.isPublic == false)
    }

    @Test("toDomain with all status types")
    func toDomainWithAllStatusTypes() throws {
        let statuses = ["uploaded", "processing", "ready", "failed"]
        let expectedStatuses: [MaterialStatus] = [.uploaded, .processing, .ready, .failed]

        for (statusString, expectedStatus) in zip(statuses, expectedStatuses) {
            let dto = MaterialDTO(
                id: UUID(),
                title: "Test Material",
                description: nil,
                status: statusString,
                fileURL: nil,
                fileType: nil,
                fileSizeBytes: nil,
                schoolID: schoolID,
                academicUnitID: nil,
                uploadedByTeacherID: nil,
                subject: nil,
                grade: nil,
                isPublic: false,
                processingStartedAt: nil,
                processingCompletedAt: nil,
                createdAt: Date(),
                updatedAt: Date(),
                deletedAt: nil
            )

            let material = try MaterialMapper.toDomain(dto)
            #expect(material.status == expectedStatus)
        }
    }

    @Test("toDomain with unknown status throws")
    func toDomainWithUnknownStatus() {
        let dto = MaterialDTO(
            id: UUID(),
            title: "Test Material",
            description: nil,
            status: "unknown_status",
            fileURL: nil,
            fileType: nil,
            fileSizeBytes: nil,
            schoolID: schoolID,
            academicUnitID: nil,
            uploadedByTeacherID: nil,
            subject: nil,
            grade: nil,
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        #expect(throws: DomainError.self) {
            _ = try MaterialMapper.toDomain(dto)
        }
    }

    @Test("toDomain with nil fileURL returns nil URL")
    func toDomainWithNilFileURL() throws {
        let dto = MaterialDTO(
            id: UUID(),
            title: "Test Material",
            description: nil,
            status: "uploaded",
            fileURL: nil,
            fileType: nil,
            fileSizeBytes: nil,
            schoolID: schoolID,
            academicUnitID: nil,
            uploadedByTeacherID: nil,
            subject: nil,
            grade: nil,
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        let material = try MaterialMapper.toDomain(dto)

        #expect(material.fileURL == nil)
    }

    @Test("toDomain with invalid fileURL throws")
    func toDomainWithInvalidFileURL() {
        let dto = MaterialDTO(
            id: UUID(),
            title: "Test Material",
            description: nil,
            status: "uploaded",
            fileURL: "not a url",
            fileType: nil,
            fileSizeBytes: nil,
            schoolID: schoolID,
            academicUnitID: nil,
            uploadedByTeacherID: nil,
            subject: nil,
            grade: nil,
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        #expect(throws: DomainError.self) {
            _ = try MaterialMapper.toDomain(dto)
        }
    }

    @Test("toDomain with deleted material")
    func toDomainWithDeletedMaterial() throws {
        let deletedAt = Date(timeIntervalSince1970: 3000)

        let dto = MaterialDTO(
            id: UUID(),
            title: "Deleted Material",
            description: nil,
            status: "ready",
            fileURL: nil,
            fileType: nil,
            fileSizeBytes: nil,
            schoolID: schoolID,
            academicUnitID: nil,
            uploadedByTeacherID: nil,
            subject: nil,
            grade: nil,
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: deletedAt
        )

        let material = try MaterialMapper.toDomain(dto)

        #expect(material.isDeleted == true)
        #expect(material.deletedAt == deletedAt)
    }

    @Test("toDomain with empty title throws error")
    func toDomainWithEmptyTitleThrows() {
        let dto = MaterialDTO(
            id: UUID(),
            title: "",
            description: nil,
            status: "uploaded",
            fileURL: nil,
            fileType: nil,
            fileSizeBytes: nil,
            schoolID: schoolID,
            academicUnitID: nil,
            uploadedByTeacherID: nil,
            subject: nil,
            grade: nil,
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        #expect(throws: DomainError.self) {
            _ = try MaterialMapper.toDomain(dto)
        }
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts Material correctly")
    func toDTOConvertsMaterialCorrectly() throws {
        let fileURL = URL(string: fileURLString)!
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let material = try Material(
            id: UUID(),
            title: "Introduction to Calculus",
            description: "A comprehensive guide",
            status: .ready,
            fileURL: fileURL,
            fileType: "application/pdf",
            fileSizeBytes: 1048576,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: teacherID,
            subject: "Mathematics",
            grade: "12th Grade",
            isPublic: true,
            processingStartedAt: createdAt,
            processingCompletedAt: updatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )

        let dto = MaterialMapper.toDTO(material)

        #expect(dto.id == material.id)
        #expect(dto.title == "Introduction to Calculus")
        #expect(dto.description == "A comprehensive guide")
        #expect(dto.status == "ready")
        #expect(dto.fileURL == fileURLString)
        #expect(dto.fileType == "application/pdf")
        #expect(dto.fileSizeBytes == 1048576)
        #expect(dto.schoolID == schoolID)
        #expect(dto.academicUnitID == academicUnitID)
        #expect(dto.uploadedByTeacherID == teacherID)
        #expect(dto.subject == "Mathematics")
        #expect(dto.grade == "12th Grade")
        #expect(dto.isPublic == true)
    }

    @Test("toDTO with nil fileURL returns nil string")
    func toDTOWithNilFileURL() throws {
        let material = try Material(
            title: "Test",
            fileURL: nil,
            schoolID: schoolID
        )

        let dto = MaterialMapper.toDTO(material)

        #expect(dto.fileURL == nil)
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)
        let updatedAt = Date(timeIntervalSince1970: 2000)

        let original = try Material(
            id: UUID(),
            title: "Test Material",
            description: "A description",
            status: .ready,
            fileURL: URL(string: fileURLString),
            fileType: "application/pdf",
            fileSizeBytes: 512000,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: teacherID,
            subject: "Science",
            grade: "10th Grade",
            isPublic: true,
            processingStartedAt: createdAt,
            processingCompletedAt: updatedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: nil
        )

        let dto = MaterialMapper.toDTO(original)
        let converted = try MaterialMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip with minimal data preserves data")
    func roundtripWithMinimalData() throws {
        let createdAt = Date(timeIntervalSince1970: 1000)

        let original = try Material(
            title: "Minimal Material",
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: createdAt
        )

        let dto = MaterialMapper.toDTO(original)
        let converted = try MaterialMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip with deleted material preserves data")
    func roundtripWithDeletedMaterial() throws {
        let deletedAt = Date(timeIntervalSince1970: 3000)

        let original = try Material(
            title: "Deleted Material",
            schoolID: schoolID,
            createdAt: Date(timeIntervalSince1970: 1000),
            updatedAt: Date(timeIntervalSince1970: 2000),
            deletedAt: deletedAt
        )

        let dto = MaterialMapper.toDTO(original)
        let converted = try MaterialMapper.toDomain(dto)

        #expect(original == converted)
    }

    // MARK: - Extension Method Tests

    @Test("MaterialDTO.toDomain() works correctly")
    func dtoToDomainExtension() throws {
        let dto = MaterialDTO(
            id: UUID(),
            title: "Test Material",
            description: nil,
            status: "ready",
            fileURL: fileURLString,
            fileType: nil,
            fileSizeBytes: nil,
            schoolID: schoolID,
            academicUnitID: nil,
            uploadedByTeacherID: nil,
            subject: nil,
            grade: nil,
            isPublic: false,
            processingStartedAt: nil,
            processingCompletedAt: nil,
            createdAt: Date(),
            updatedAt: Date(),
            deletedAt: nil
        )

        let material = try dto.toDomain()

        #expect(material.id == dto.id)
        #expect(material.status == .ready)
    }

    @Test("Material.toDTO() works correctly")
    func materialToDTOExtension() throws {
        let material = try Material(
            title: "Test Material",
            status: .processing,
            schoolID: schoolID
        )

        let dto = material.toDTO()

        #expect(dto.id == material.id)
        #expect(dto.status == "processing")
    }

    // MARK: - JSON Serialization Tests

    @Test("MaterialDTO encodes to JSON with snake_case keys")
    func dtoEncodesToSnakeCaseJSON() throws {
        let id = UUID()
        let createdAt = Date(timeIntervalSince1970: 1705318200)
        let updatedAt = Date(timeIntervalSince1970: 1705459500)
        let processingStartedAt = Date(timeIntervalSince1970: 1705318200)
        let processingCompletedAt = Date(timeIntervalSince1970: 1705400000)
        let deletedAt = Date(timeIntervalSince1970: 1705500000)

        let dto = MaterialDTO(
            id: id,
            title: "Test Material",
            description: "A description",
            status: "ready",
            fileURL: fileURLString,
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            schoolID: schoolID,
            academicUnitID: academicUnitID,
            uploadedByTeacherID: teacherID,
            subject: "Math",
            grade: "12th",
            isPublic: true,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(dto)
        let json = String(data: data, encoding: .utf8)!

        #expect(json.contains("\"file_url\""))
        #expect(json.contains("\"file_type\""))
        #expect(json.contains("\"file_size_bytes\""))
        #expect(json.contains("\"school_id\""))
        #expect(json.contains("\"academic_unit_id\""))
        #expect(json.contains("\"uploaded_by_teacher_id\""))
        #expect(json.contains("\"is_public\""))
        #expect(json.contains("\"processing_started_at\""))
        #expect(json.contains("\"processing_completed_at\""))
        #expect(json.contains("\"created_at\""))
        #expect(json.contains("\"updated_at\""))
        #expect(json.contains("\"deleted_at\""))
        #expect(!json.contains("\"fileURL\""))
        #expect(!json.contains("\"schoolID\""))
    }

    @Test("MaterialDTO decodes from JSON with snake_case keys")
    func dtoDecodesFromSnakeCaseJSON() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "title": "Introduction to Calculus",
            "description": "A comprehensive guide",
            "status": "ready",
            "file_url": "https://example.com/file.pdf",
            "file_type": "application/pdf",
            "file_size_bytes": 1048576,
            "school_id": "660e8400-e29b-41d4-a716-446655440001",
            "academic_unit_id": "770e8400-e29b-41d4-a716-446655440002",
            "uploaded_by_teacher_id": "880e8400-e29b-41d4-a716-446655440003",
            "subject": "Mathematics",
            "grade": "12th Grade",
            "is_public": true,
            "processing_started_at": "2024-01-15T10:30:00Z",
            "processing_completed_at": "2024-01-15T10:35:00Z",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-20T14:45:00Z",
            "deleted_at": null
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(MaterialDTO.self, from: data)

        #expect(dto.title == "Introduction to Calculus")
        #expect(dto.status == "ready")
        #expect(dto.fileURL == "https://example.com/file.pdf")
        #expect(dto.isPublic == true)
        #expect(dto.deletedAt == nil)
    }

    @Test("MaterialDTO decodes from JSON with null optional fields")
    func dtoDecodesFromJSONWithNullOptionalFields() throws {
        let json = """
        {
            "id": "550e8400-e29b-41d4-a716-446655440000",
            "title": "Minimal Material",
            "description": null,
            "status": "uploaded",
            "file_url": null,
            "file_type": null,
            "file_size_bytes": null,
            "school_id": "660e8400-e29b-41d4-a716-446655440001",
            "academic_unit_id": null,
            "uploaded_by_teacher_id": null,
            "subject": null,
            "grade": null,
            "is_public": false,
            "processing_started_at": null,
            "processing_completed_at": null,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z",
            "deleted_at": null
        }
        """
        let data = json.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let dto = try decoder.decode(MaterialDTO.self, from: data)

        #expect(dto.title == "Minimal Material")
        #expect(dto.description == nil)
        #expect(dto.fileURL == nil)
        #expect(dto.academicUnitID == nil)
        #expect(dto.isPublic == false)
    }
}
