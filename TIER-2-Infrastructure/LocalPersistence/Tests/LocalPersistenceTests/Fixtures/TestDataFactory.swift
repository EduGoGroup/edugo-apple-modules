import Foundation
import Models

/// Factory for creating test data
///
/// Provides helper methods for creating valid User, Document, and other entities
/// for use in unit tests.
enum TestDataFactory {
    /// Creates a valid User with default or custom values
    ///
    /// - Parameters:
    ///   - id: User ID (defaults to new UUID)
    ///   - firstName: User first name (defaults to "Test")
    ///   - lastName: User last name (defaults to "User")
    ///   - email: User email (defaults to unique email based on ID)
    ///   - isActive: Active status (defaults to true)
    ///   - createdAt: Creation timestamp (defaults to now)
    ///   - updatedAt: Last update timestamp (defaults to now)
    /// - Returns: A valid User entity
    static func makeUser(
        id: UUID = UUID(),
        firstName: String = "Test",
        lastName: String = "User",
        email: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> User {
        let finalEmail = email ?? "test-\(id.uuidString.prefix(8))@example.com"
        return try User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: finalEmail,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid School with default or custom values
    static func makeSchool(
        id: UUID = UUID(),
        name: String = "Test School",
        code: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> School {
        let finalCode = code ?? "SCH-\(id.uuidString.prefix(8))"
        return try School(
            id: id,
            name: name,
            code: finalCode,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid AcademicUnit with default or custom values
    static func makeAcademicUnit(
        id: UUID = UUID(),
        displayName: String = "Test Unit",
        type: AcademicUnitType = .grade,
        schoolID: UUID = UUID(),
        parentUnitID: UUID? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> AcademicUnit {
        return try AcademicUnit(
            id: id,
            displayName: displayName,
            type: type,
            parentUnitID: parentUnitID,
            schoolID: schoolID,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid Membership with default or custom values
    static func makeMembership(
        id: UUID = UUID(),
        userID: UUID = UUID(),
        unitID: UUID = UUID(),
        role: MembershipRole = .student,
        isActive: Bool = true,
        enrolledAt: Date = Date(),
        withdrawnAt: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Membership {
        return Membership(
            id: id,
            userID: userID,
            unitID: unitID,
            role: role,
            isActive: isActive,
            enrolledAt: enrolledAt,
            withdrawnAt: withdrawnAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid Material with default or custom values
    static func makeMaterial(
        id: UUID = UUID(),
        title: String = "Test Material",
        status: MaterialStatus = .uploaded,
        schoolID: UUID = UUID(),
        isPublic: Bool = false,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) throws -> Material {
        return try Material(
            id: id,
            title: title,
            status: status,
            schoolID: schoolID,
            isPublic: isPublic,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    /// Creates a valid Document with default or custom values
    ///
    /// - Parameters:
    ///   - id: Document ID (defaults to new UUID)
    ///   - title: Document title (defaults to "Test Document")
    ///   - content: Document content (defaults to "Test content")
    ///   - type: Document type (defaults to .lesson)
    ///   - state: Document state (defaults to .draft)
    ///   - ownerID: Owner ID (defaults to new UUID)
    ///   - collaboratorIDs: Set of collaborator IDs (defaults to empty)
    ///   - version: Metadata version (defaults to 1)
    ///   - tags: Set of tags (defaults to empty)
    /// - Returns: A valid Document entity
    static func makeDocument(
        id: UUID = UUID(),
        title: String = "Test Document",
        content: String = "Test content",
        type: DocumentType = .lesson,
        state: DocumentState = .draft,
        ownerID: UUID = UUID(),
        collaboratorIDs: Set<UUID> = [],
        version: Int = 1,
        tags: Set<String> = []
    ) throws -> Document {
        let metadata = DocumentMetadata(
            createdAt: Date(),
            modifiedAt: Date(),
            version: version,
            tags: tags
        )
        return try Document(
            id: id,
            title: title,
            content: content,
            type: type,
            state: state,
            metadata: metadata,
            ownerID: ownerID,
            collaboratorIDs: collaboratorIDs
        )
    }

    /// Creates multiple users with unique data
    ///
    /// - Parameter count: Number of users to create
    /// - Returns: Array of valid User entities
    static func makeUsers(count: Int) throws -> [User] {
        try (0..<count).map { index in
            try makeUser(
                firstName: "User",
                lastName: "\(index)",
                email: "user\(index)@example.com"
            )
        }
    }

    /// Creates multiple documents with unique data
    ///
    /// - Parameters:
    ///   - count: Number of documents to create
    ///   - ownerID: Owner ID for all documents
    /// - Returns: Array of valid Document entities
    static func makeDocuments(count: Int, ownerID: UUID = UUID()) throws -> [Document] {
        try (0..<count).map { index in
            try makeDocument(
                title: "Document \(index)",
                content: "Content for document \(index)",
                ownerID: ownerID
            )
        }
    }
}
