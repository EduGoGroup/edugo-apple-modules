import Foundation
import Models

/// Factory for creating test data
///
/// Provides helper methods for creating valid User and Document entities
/// for use in unit tests.
enum TestDataFactory {
    /// Creates a valid User with default or custom values
    ///
    /// - Parameters:
    ///   - id: User ID (defaults to new UUID)
    ///   - name: User name (defaults to "Test User")
    ///   - email: User email (defaults to unique email based on ID)
    ///   - isActive: Active status (defaults to true)
    ///   - roleIDs: Set of role IDs (defaults to empty)
    /// - Returns: A valid User entity
    static func makeUser(
        id: UUID = UUID(),
        name: String = "Test User",
        email: String? = nil,
        isActive: Bool = true,
        roleIDs: Set<UUID> = []
    ) throws -> User {
        let finalEmail = email ?? "test-\(id.uuidString.prefix(8))@example.com"
        return try User(
            id: id,
            name: name,
            email: finalEmail,
            isActive: isActive,
            roleIDs: roleIDs
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
                name: "User \(index)",
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
