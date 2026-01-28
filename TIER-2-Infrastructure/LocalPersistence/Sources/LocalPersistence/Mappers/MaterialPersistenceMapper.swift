import Foundation
import Models
import EduGoCommon

/// Mapper for converting between MaterialModel (SwiftData) and Material (domain)
///
/// This struct provides static methods for bidirectional conversion between
/// the persistence model and the domain entity.
///
/// ## Usage
///
/// ```swift
/// // Convert from persistence to domain
/// let material = try MaterialPersistenceMapper.toDomain(materialModel)
///
/// // Convert from domain to persistence (new model)
/// let model = MaterialPersistenceMapper.toModel(material, existing: nil)
///
/// // Update existing model from domain
/// let updatedModel = MaterialPersistenceMapper.toModel(material, existing: existingModel)
/// ```
///
/// ## Notes
/// - Does NOT conform to `MapperProtocol` because `@Model` types are not `Codable`
/// - Handles URL ↔ String conversion for fileURL
/// - Unknown status strings default to `.uploaded`
/// - Throws `DomainError.validationFailed` if data is corrupted
public struct MaterialPersistenceMapper: Sendable {
    private init() {}

    /// Converts a MaterialModel to a domain Material
    ///
    /// - Parameter model: The SwiftData model to convert
    /// - Returns: A domain Material entity
    /// - Throws: `DomainError.validationFailed` if the model contains invalid data
    /// - Note: Unknown status strings default to `.uploaded`
    public static func toDomain(_ model: MaterialModel) throws -> Material {
        let status = MaterialStatus(rawValue: model.status) ?? .uploaded

        var url: URL?
        if let fileURLString = model.fileURL {
            url = URL(string: fileURLString)
        }

        return try Material(
            id: model.id,
            title: model.title,
            description: model.materialDescription,
            status: status,
            fileURL: url,
            fileType: model.fileType,
            fileSizeBytes: model.fileSizeBytes,
            schoolID: model.schoolID,
            academicUnitID: model.academicUnitID,
            uploadedByTeacherID: model.uploadedByTeacherID,
            subject: model.subject,
            grade: model.grade,
            isPublic: model.isPublic,
            processingStartedAt: model.processingStartedAt,
            processingCompletedAt: model.processingCompletedAt,
            createdAt: model.createdAt,
            updatedAt: model.updatedAt,
            deletedAt: model.deletedAt
        )
    }

    /// Converts a domain Material to a MaterialModel
    ///
    /// If an existing model is provided, updates its properties instead of
    /// creating a new instance. This is useful for SwiftData's change tracking.
    ///
    /// - Parameters:
    ///   - domain: The domain Material to convert
    ///   - existing: An optional existing MaterialModel to update
    /// - Returns: A MaterialModel with the domain entity's data
    public static func toModel(_ domain: Material, existing: MaterialModel?) -> MaterialModel {
        if let existing = existing {
            // Update existing model in place for SwiftData change tracking
            existing.title = domain.title
            existing.materialDescription = domain.description
            existing.status = domain.status.rawValue
            existing.fileURL = domain.fileURL?.absoluteString
            existing.fileType = domain.fileType
            existing.fileSizeBytes = domain.fileSizeBytes
            existing.schoolID = domain.schoolID
            existing.academicUnitID = domain.academicUnitID
            existing.uploadedByTeacherID = domain.uploadedByTeacherID
            existing.subject = domain.subject
            existing.grade = domain.grade
            existing.isPublic = domain.isPublic
            existing.processingStartedAt = domain.processingStartedAt
            existing.processingCompletedAt = domain.processingCompletedAt
            existing.updatedAt = domain.updatedAt
            existing.deletedAt = domain.deletedAt
            return existing
        } else {
            // Create new model
            return MaterialModel(
                id: domain.id,
                title: domain.title,
                materialDescription: domain.description,
                status: domain.status.rawValue,
                fileURL: domain.fileURL?.absoluteString,
                fileType: domain.fileType,
                fileSizeBytes: domain.fileSizeBytes,
                schoolID: domain.schoolID,
                academicUnitID: domain.academicUnitID,
                uploadedByTeacherID: domain.uploadedByTeacherID,
                subject: domain.subject,
                grade: domain.grade,
                isPublic: domain.isPublic,
                processingStartedAt: domain.processingStartedAt,
                processingCompletedAt: domain.processingCompletedAt,
                createdAt: domain.createdAt,
                updatedAt: domain.updatedAt,
                deletedAt: domain.deletedAt
            )
        }
    }
}
