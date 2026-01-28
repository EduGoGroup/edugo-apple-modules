import Foundation
@testable import Models

/// Factory methods for creating test DTOs with sensible defaults.
enum TestFixtures {

    // MARK: - UserDTO

    static func makeUserDTO(
        id: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "User",
        email: String = "test@example.com",
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> UserDTO {
        UserDTO(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    // MARK: - RoleDTO

    static func makeRoleDTO(
        id: UUID = UUID(),
        name: String = "Test Role",
        level: Int = 1,
        permissionIDs: [UUID] = []
    ) -> RoleDTO {
        RoleDTO(
            id: id,
            name: name,
            level: level,
            permissionIDs: permissionIDs
        )
    }

    // MARK: - PermissionDTO

    static func makePermissionDTO(
        id: UUID = UUID(),
        code: String = "users.read",
        resource: String = "users",
        action: String = "read"
    ) -> PermissionDTO {
        PermissionDTO(
            id: id,
            code: code,
            resource: resource,
            action: action
        )
    }

    // MARK: - DocumentDTO

    static func makeDocumentDTO(
        id: UUID = UUID(),
        title: String = "Test Document",
        content: String = "Test content",
        type: String = "lesson",
        state: String = "draft",
        ownerID: UUID = UUID(),
        collaboratorIDs: [UUID] = [],
        createdAt: String = "2024-01-15T10:30:00.000Z",
        modifiedAt: String = "2024-01-15T10:30:00.000Z",
        version: Int = 1,
        tags: [String] = []
    ) -> DocumentDTO {
        let metadata = DocumentMetadataDTO(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            version: version,
            tags: tags
        )
        return DocumentDTO(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs,
            metadata: metadata
        )
    }

    // MARK: - DocumentMetadataDTO

    static func makeDocumentMetadataDTO(
        createdAt: String = "2024-01-15T10:30:00.000Z",
        modifiedAt: String = "2024-01-15T10:30:00.000Z",
        version: Int = 1,
        tags: [String] = []
    ) -> DocumentMetadataDTO {
        DocumentMetadataDTO(
            createdAt: createdAt,
            modifiedAt: modifiedAt,
            version: version,
            tags: tags
        )
    }
}
