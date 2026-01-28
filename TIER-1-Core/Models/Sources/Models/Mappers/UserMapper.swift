// UserMapper.swift
// Models
//
// Bidirectional mapper between UserDTO and User domain entity.

import Foundation
import EduGoCommon

/// Mapper for bidirectional conversion between `UserDTO` and `User` domain entity.
///
/// This mapper handles the conversion between the backend's JSON representation
/// and the application's domain model, delegating validation to the `User` initializer.
///
/// ## Overview
/// `UserMapper` provides type-safe conversion that:
/// - Converts `Array` to `Set` for role IDs (domain uses `Set` for uniqueness)
/// - Delegates email and name validation to `User.init`
/// - Preserves all user properties during roundtrip conversion
///
/// ## Example
/// ```swift
/// // DTO from backend
/// let dto = UserDTO(
///     id: UUID(),
///     name: "John Doe",
///     email: "john@example.com",
///     isActive: true,
///     roleIDs: [roleID1, roleID2]
/// )
///
/// // Convert to domain
/// let user = try UserMapper.toDomain(dto)
///
/// // Convert back to DTO
/// let backToDTO = UserMapper.toDTO(user)
/// ```
///
/// ## Error Handling
/// The `toDomain` method throws errors from `User.init`:
/// - `DomainError.validationFailed(field: "name", ...)` if name is empty
/// - `DomainError.validationFailed(field: "email", ...)` if email is invalid
public struct UserMapper: MapperProtocol {
    public typealias DTO = UserDTO
    public typealias Domain = User

    /// Converts a `UserDTO` from the backend to a `User` domain entity.
    ///
    /// - Parameter dto: The data transfer object from the backend.
    /// - Returns: A validated `User` domain entity.
    /// - Throws: `DomainError.validationFailed` if email or name are invalid.
    /// - Note: `User.init` normalizes email to lowercase and trims whitespace from name/email.
    public static func toDomain(_ dto: UserDTO) throws -> User {
        try User(
            id: dto.id,
            name: dto.name,
            email: dto.email,
            isActive: dto.isActive,
            roleIDs: Set(dto.roleIDs)
        )
    }

    /// Converts a `User` domain entity to a `UserDTO` for the backend.
    ///
    /// - Parameter domain: The domain entity to convert.
    /// - Returns: A `UserDTO` suitable for sending to the backend.
    public static func toDTO(_ domain: User) -> UserDTO {
        UserDTO(
            id: domain.id,
            name: domain.name,
            email: domain.email,
            isActive: domain.isActive,
            roleIDs: Array(domain.roleIDs)
        )
    }
}
