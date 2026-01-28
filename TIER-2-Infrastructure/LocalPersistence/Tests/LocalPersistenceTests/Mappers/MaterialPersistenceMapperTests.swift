import Testing
import Foundation
import SwiftData
import Models
import EduGoCommon
@testable import LocalPersistence

@Suite("MaterialPersistenceMapper Tests")
struct MaterialPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical material")
    func testRoundtrip() throws {
        let schoolID = UUID()
        let createdAt = Date()
        let updatedAt = Date()
        let original = try TestDataFactory.makeMaterial(
            title: "Test Material",
            status: .uploaded,
            schoolID: schoolID,
            isPublic: false,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = MaterialPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = try MaterialPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.title == original.title)
        #expect(restored.status == original.status)
        #expect(restored.schoolID == original.schoolID)
        #expect(restored.isPublic == original.isPublic)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip preserves all status values")
    func testRoundtripPreservesStatusValues() throws {
        let statuses: [MaterialStatus] = [.uploaded, .processing, .ready, .failed]

        for status in statuses {
            let original = try TestDataFactory.makeMaterial(status: status)
            let model = MaterialPersistenceMapper.toModel(original, existing: nil)
            let restored = try MaterialPersistenceMapper.toDomain(model)

            #expect(restored.status == status)
        }
    }

    @Test("Roundtrip preserves timestamps")
    func testRoundtripPreservesTimestamps() throws {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let original = try TestDataFactory.makeMaterial(
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = MaterialPersistenceMapper.toModel(original, existing: nil)
        let restored = try MaterialPersistenceMapper.toDomain(model)

        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    @Test("Roundtrip with public material")
    func testRoundtripWithPublicMaterial() throws {
        let original = try TestDataFactory.makeMaterial(isPublic: true)

        let model = MaterialPersistenceMapper.toModel(original, existing: nil)
        let restored = try MaterialPersistenceMapper.toDomain(model)

        #expect(restored.isPublic == true)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() throws {
        let material = try TestDataFactory.makeMaterial()

        let model = MaterialPersistenceMapper.toModel(material, existing: nil)

        #expect(model.id == material.id)
        #expect(model.title == material.title)
        #expect(model.status == material.status.rawValue)
        #expect(model.schoolID == material.schoolID)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() throws {
        let material1 = try TestDataFactory.makeMaterial(title: "Original Material")
        let existingModel = MaterialPersistenceMapper.toModel(material1, existing: nil)

        let newUpdatedAt = Date()
        let material2 = try Material(
            id: material1.id,
            title: "Updated Material",
            status: .ready,
            schoolID: material1.schoolID,
            isPublic: true,
            createdAt: material1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = MaterialPersistenceMapper.toModel(material2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.title == "Updated Material")
        #expect(updatedModel.status == "ready")
        #expect(updatedModel.isPublic == true)
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel converts status enum to string")
    func testToModelConvertsStatusToString() throws {
        let material = try TestDataFactory.makeMaterial(status: .processing)

        let model = MaterialPersistenceMapper.toModel(material, existing: nil)

        #expect(model.status == "processing")
    }

    @Test("toModel converts URL to string")
    func testToModelConvertsURLToString() throws {
        let url = URL(string: "https://example.com/file.pdf")!
        let material = try Material(
            id: UUID(),
            title: "Test Material",
            status: .uploaded,
            fileURL: url,
            schoolID: UUID(),
            isPublic: false,
            createdAt: Date(),
            updatedAt: Date()
        )

        let model = MaterialPersistenceMapper.toModel(material, existing: nil)

        #expect(model.fileURL == "https://example.com/file.pdf")
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain material")
    func testToDomainCreatesValidMaterial() throws {
        let schoolID = UUID()
        let model = MaterialModel(
            id: UUID(),
            title: "Test Material",
            status: "uploaded",
            schoolID: schoolID,
            isPublic: false
        )

        let material = try MaterialPersistenceMapper.toDomain(model)

        #expect(material.id == model.id)
        #expect(material.title == model.title)
        #expect(material.status == .uploaded)
        #expect(material.schoolID == schoolID)
        #expect(material.isPublic == false)
    }

    @Test("toDomain throws for empty title")
    func testToDomainThrowsForEmptyTitle() {
        let model = MaterialModel(
            id: UUID(),
            title: "",
            status: "uploaded",
            schoolID: UUID(),
            isPublic: false
        )

        #expect(throws: DomainError.self) {
            _ = try MaterialPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain throws for unknown status")
    func testToDomainThrowsForUnknownStatus() {
        let model = MaterialModel(
            id: UUID(),
            title: "Test Material",
            status: "unknown_status",
            schoolID: UUID(),
            isPublic: false
        )

        #expect(throws: DomainError.self) {
            _ = try MaterialPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain converts all known status strings")
    func testToDomainConvertsAllKnownStatuses() throws {
        let statusMapping: [(String, MaterialStatus)] = [
            ("uploaded", .uploaded),
            ("processing", .processing),
            ("ready", .ready),
            ("failed", .failed)
        ]

        for (statusString, expectedStatus) in statusMapping {
            let model = MaterialModel(
                id: UUID(),
                title: "Test Material",
                status: statusString,
                schoolID: UUID(),
                isPublic: false
            )

            let material = try MaterialPersistenceMapper.toDomain(model)

            #expect(material.status == expectedStatus)
        }
    }

    @Test("toDomain converts string to URL")
    func testToDomainConvertsStringToURL() throws {
        let model = MaterialModel(
            id: UUID(),
            title: "Test Material",
            status: "uploaded",
            fileURL: "https://example.com/file.pdf",
            schoolID: UUID(),
            isPublic: false
        )

        let material = try MaterialPersistenceMapper.toDomain(model)

        #expect(material.fileURL?.absoluteString == "https://example.com/file.pdf")
    }

    @Test("toDomain throws for invalid URL")
    func testToDomainThrowsForInvalidURL() {
        let model = MaterialModel(
            id: UUID(),
            title: "Test Material",
            status: "uploaded",
            fileURL: "not a url",
            schoolID: UUID(),
            isPublic: false
        )

        #expect(throws: DomainError.self) {
            _ = try MaterialPersistenceMapper.toDomain(model)
        }
    }

    @Test("toDomain handles nil fileURL")
    func testToDomainHandlesNilFileURL() throws {
        let model = MaterialModel(
            id: UUID(),
            title: "Test Material",
            status: "uploaded",
            fileURL: nil,
            schoolID: UUID(),
            isPublic: false
        )

        let material = try MaterialPersistenceMapper.toDomain(model)

        #expect(material.fileURL == nil)
    }

    @Test("toDomain handles optional properties")
    func testToDomainHandlesOptionalProperties() throws {
        let academicUnitID = UUID()
        let teacherID = UUID()
        let processingStartedAt = Date()
        let processingCompletedAt = Date()

        let model = MaterialModel(
            id: UUID(),
            title: "Test Material",
            materialDescription: "Test description",
            status: "ready",
            fileURL: "https://example.com/file.pdf",
            fileType: "application/pdf",
            fileSizeBytes: 1024,
            schoolID: UUID(),
            academicUnitID: academicUnitID,
            uploadedByTeacherID: teacherID,
            subject: "Mathematics",
            grade: "5th Grade",
            isPublic: true,
            processingStartedAt: processingStartedAt,
            processingCompletedAt: processingCompletedAt
        )

        let material = try MaterialPersistenceMapper.toDomain(model)

        #expect(material.description == "Test description")
        #expect(material.fileType == "application/pdf")
        #expect(material.fileSizeBytes == 1024)
        #expect(material.academicUnitID == academicUnitID)
        #expect(material.uploadedByTeacherID == teacherID)
        #expect(material.subject == "Mathematics")
        #expect(material.grade == "5th Grade")
        #expect(material.processingStartedAt == processingStartedAt)
        #expect(material.processingCompletedAt == processingCompletedAt)
    }
}
