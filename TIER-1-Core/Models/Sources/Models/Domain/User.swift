import Foundation
import EduGoCommon

// MARK: - User Entity

/// Represents a user in the EduGo system.
///
/// `User` is an immutable, thread-safe entity conforming to `Sendable`.
/// Relationships are modeled via IDs (value semantics) rather than references.
///
/// ## Example
/// ```swift
/// let user = User(
///     id: UUID(),
///     name: "John Doe",
///     email: "john@edugo.com",
///     isActive: true
/// )
///
/// // Add a role
/// let updatedUser = user.addRole(adminRoleID)
/// ```
public struct User: Sendable, Equatable, Identifiable, Codable, Hashable {

    // MARK: - Properties

    /// Unique identifier for the user
    public let id: UUID

    /// User's display name
    public let name: String

    /// User's email address (validated format)
    public let email: String

    /// Whether the user account is active
    public let isActive: Bool

    /// Set of role IDs assigned to this user
    public let roleIDs: Set<UUID>

    // MARK: - Initialization

    /// Creates a new User instance.
    ///
    /// - Parameters:
    ///   - id: Unique identifier. Defaults to a new UUID.
    ///   - name: User's display name. Must not be empty.
    ///   - email: User's email address. Must be valid format.
    ///   - isActive: Whether the account is active. Defaults to true.
    ///   - roleIDs: Set of assigned role IDs. Defaults to empty.
    /// - Throws: `DomainError.validationFailed` if validation fails.
    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        isActive: Bool = true,
        roleIDs: Set<UUID> = []
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else {
            throw DomainError.validationFailed(
                field: "name",
                reason: "El nombre no puede estar vacío"
            )
        }

        let normalizedEmail = email.trimmingCharacters(in: .whitespaces)
        try EmailValidator.validate(normalizedEmail)

        self.id = id
        self.name = trimmedName
        self.email = normalizedEmail.lowercased()
        self.isActive = isActive
        self.roleIDs = roleIDs
    }

    // MARK: - Copy Methods

    /// Creates a copy with updated name.
    ///
    /// - Parameter name: The new name.
    /// - Returns: A new `User` instance with the updated name.
    /// - Throws: `DomainError.validationFailed` if name is empty.
    public func with(name: String) throws -> User {
        try User(
            id: id,
            name: name,
            email: email,
            isActive: isActive,
            roleIDs: roleIDs
        )
    }

    /// Creates a copy with updated email.
    ///
    /// - Parameter email: The new email address.
    /// - Returns: A new `User` instance with the updated email.
    /// - Throws: `DomainError.validationFailed` if format is invalid.
    public func with(email: String) throws -> User {
        try User(
            id: id,
            name: name,
            email: email,
            isActive: isActive,
            roleIDs: roleIDs
        )
    }

    /// Creates a copy with updated active status.
    ///
    /// - Parameter isActive: The new active status.
    /// - Returns: A new `User` instance with the updated status.
    public func with(isActive: Bool) -> User {
        // Safe to force-try since we're reusing validated values
        // swiftlint:disable:next force_try
        try! User(
            id: id,
            name: name,
            email: email,
            isActive: isActive,
            roleIDs: roleIDs
        )
    }

    // MARK: - Role Management

    /// Creates a copy with an additional role.
    ///
    /// - Parameter roleID: The role ID to add.
    /// - Returns: A new `User` with the role added.
    public func addRole(_ roleID: UUID) -> User {
        var newRoles = roleIDs
        newRoles.insert(roleID)
        // swiftlint:disable:next force_try
        return try! User(
            id: id,
            name: name,
            email: email,
            isActive: isActive,
            roleIDs: newRoles
        )
    }

    /// Creates a copy with a role removed.
    ///
    /// - Parameter roleID: The role ID to remove.
    /// - Returns: A new `User` without the specified role.
    public func removeRole(_ roleID: UUID) -> User {
        var newRoles = roleIDs
        newRoles.remove(roleID)
        // swiftlint:disable:next force_try
        return try! User(
            id: id,
            name: name,
            email: email,
            isActive: isActive,
            roleIDs: newRoles
        )
    }

    /// Checks if the user has a specific role.
    ///
    /// - Parameter roleID: The role ID to check.
    /// - Returns: `true` if the user has the role, `false` otherwise.
    public func hasRole(_ roleID: UUID) -> Bool {
        roleIDs.contains(roleID)
    }

}
