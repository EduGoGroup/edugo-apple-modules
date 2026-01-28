// UserDTO.swift
// Models
//
// Data Transfer Object for User entity from backend API.

import Foundation

/// Data Transfer Object representing a User from the backend API.
///
/// This struct maps to the JSON structure returned by the backend,
/// using snake_case property names via `CodingKeys`.
///
/// ## JSON Structure
/// ```json
/// {
///     "id": "550e8400-e29b-41d4-a716-446655440000",
///     "name": "John Doe",
///     "email": "john.doe@example.com",
///     "is_active": true,
///     "role_ids": ["uuid1", "uuid2"]
/// }
/// ```
///
/// ## Usage
/// ```swift
/// let decoder = JSONDecoder()
/// let userDTO = try decoder.decode(UserDTO.self, from: jsonData)
/// let user = try UserMapper.toDomain(userDTO)
/// ```
public struct UserDTO: Codable, Sendable, Equatable {
    /// Unique identifier for the user.
    public let id: UUID

    /// User's display name.
    public let name: String

    /// User's email address.
    public let email: String

    /// Whether the user account is active.
    public let isActive: Bool

    /// Array of role IDs assigned to the user.
    public let roleIDs: [UUID]

    /// Maps JSON snake_case keys to Swift camelCase properties.
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case isActive = "is_active"
        case roleIDs = "role_ids"
    }

    /// Creates a new UserDTO instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for the user.
    ///   - name: User's display name.
    ///   - email: User's email address.
    ///   - isActive: Whether the user account is active.
    ///   - roleIDs: Array of role IDs assigned to the user.
    public init(
        id: UUID,
        name: String,
        email: String,
        isActive: Bool,
        roleIDs: [UUID]
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.isActive = isActive
        self.roleIDs = roleIDs
    }
}
