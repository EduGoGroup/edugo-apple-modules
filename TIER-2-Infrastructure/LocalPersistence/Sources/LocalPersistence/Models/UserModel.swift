import Foundation
import SwiftData

/// SwiftData model for persisting User entities
///
/// This model stores user data in SwiftData and can be converted to/from
/// the domain `User` type using `UserPersistenceMapper`.
///
/// ## Notes
/// - Uses `[UUID]` for roleIDs because SwiftData doesn't support `Set<UUID>` directly
/// - The `id` property has a unique constraint to ensure data integrity
@Model
public final class UserModel {
    /// Unique identifier for the user
    @Attribute(.unique)
    public var id: UUID

    /// User's display name
    public var name: String

    /// User's email address (normalized to lowercase)
    public var email: String

    /// Whether the user account is active
    public var isActive: Bool

    /// Array of role IDs assigned to the user
    /// Stored as Array because SwiftData doesn't support Set<UUID>
    public var roleIDs: [UUID]

    /// Creates a new UserModel instance
    ///
    /// - Parameters:
    ///   - id: Unique identifier (defaults to new UUID)
    ///   - name: User's display name
    ///   - email: User's email address
    ///   - isActive: Whether the account is active (defaults to true)
    ///   - roleIDs: Array of role IDs (defaults to empty)
    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        isActive: Bool = true,
        roleIDs: [UUID] = []
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.isActive = isActive
        self.roleIDs = roleIDs
    }
}
