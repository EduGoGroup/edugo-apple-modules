// UserDTO.swift
// Models
//
// Data Transfer Object for User entity from backend API.

import Foundation

/// Data Transfer Object representing a User from the backend API.
///
/// This struct maps to the JSON structure returned by edu-admin and edu-mobile APIs,
/// using snake_case property names via `CodingKeys`.
///
/// ## JSON Structure (from backend)
/// ```json
/// {
///     "id": "550e8400-e29b-41d4-a716-446655440000",
///     "first_name": "John",
///     "last_name": "Doe",
///     "email": "john.doe@example.com",
///     "is_active": true,
///     "created_at": "2024-01-15T10:30:00Z",
///     "updated_at": "2024-01-20T14:45:00Z"
/// }
/// ```
///
/// ## Usage
/// ```swift
/// let decoder = JSONDecoder()
/// decoder.dateDecodingStrategy = .iso8601
/// let userDTO = try decoder.decode(UserDTO.self, from: jsonData)
/// let user = try userDTO.toDomain()
/// ```
///
/// ## Notes
/// - Roles are NOT stored in User; they are managed through `Membership` entities
/// - The `password` field is only used for create/update requests, not in responses
public struct UserDTO: Codable, Sendable, Equatable {
    /// Unique identifier for the user.
    public let id: UUID

    /// User's first name.
    public let firstName: String

    /// User's last name.
    public let lastName: String

    /// User's email address.
    public let email: String

    /// Whether the user account is active.
    public let isActive: Bool

    /// Timestamp when the user was created.
    public let createdAt: Date

    /// Timestamp when the user was last updated.
    public let updatedAt: Date

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    /// Creates a new UserDTO instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the user.
    ///   - firstName: User's first name.
    ///   - lastName: User's last name.
    ///   - email: User's email address.
    ///   - isActive: Whether the user account is active.
    ///   - createdAt: Timestamp when the user was created.
    ///   - updatedAt: Timestamp when the user was last updated.
    public init(
        id: UUID,
        firstName: String,
        lastName: String,
        email: String,
        isActive: Bool,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.firstName = firstName
        self.lastName = lastName
        self.email = email
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Domain Conversion

extension UserDTO {
    /// Converts this DTO to a domain `User` entity.
    ///
    /// - Returns: A validated `User` domain entity.
    /// - Throws: `DomainError.validationFailed` if email or names are invalid.
    public func toDomain() throws -> User {
        try User(
            id: id,
            firstName: firstName,
            lastName: lastName,
            email: email,
            isActive: isActive,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - User Extension

extension User {
    /// Converts this domain entity to a `UserDTO` for API communication.
    ///
    /// - Returns: A `UserDTO` suitable for sending to the backend.
    public func toDTO() -> UserDTO {
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
}
