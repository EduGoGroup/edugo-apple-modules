import Foundation
import Models
import EduGoCommon

/// Mapper for converting between UserModel (SwiftData) and User (domain)
///
/// This struct provides static methods for bidirectional conversion between
/// the persistence model and the domain entity.
///
/// ## Usage
///
/// ```swift
/// // Convert from persistence to domain
/// let user = try UserPersistenceMapper.toDomain(userModel)
///
/// // Convert from domain to persistence (new model)
/// let model = UserPersistenceMapper.toModel(user, existing: nil)
///
/// // Update existing model from domain
/// let updatedModel = UserPersistenceMapper.toModel(user, existing: existingModel)
/// ```
///
/// ## Notes
/// - Does NOT conform to `MapperProtocol` because `@Model` types are not `Codable`
/// - Handles `Array<UUID>` ↔ `Set<UUID>` conversion for roleIDs
/// - Throws `DomainError.validationFailed` if data is corrupted
public struct UserPersistenceMapper: Sendable {
    private init() {}

    /// Converts a UserModel to a domain User
    ///
    /// - Parameter model: The SwiftData model to convert
    /// - Returns: A domain User entity
    /// - Throws: `DomainError.validationFailed` if the model contains invalid data
    public static func toDomain(_ model: UserModel) throws -> User {
        // Convert Array to Set for roleIDs
        let roleIDsSet = Set(model.roleIDs)

        // User.init validates name and email
        return try User(
            id: model.id,
            name: model.name,
            email: model.email,
            isActive: model.isActive,
            roleIDs: roleIDsSet
        )
    }

    /// Converts a domain User to a UserModel
    ///
    /// If an existing model is provided, updates its properties instead of
    /// creating a new instance. This is useful for SwiftData's change tracking.
    ///
    /// - Parameters:
    ///   - domain: The domain User to convert
    ///   - existing: An optional existing UserModel to update
    /// - Returns: A UserModel with the domain entity's data
    public static func toModel(_ domain: User, existing: UserModel?) -> UserModel {
        // Convert Set to Array for roleIDs
        let roleIDsArray = Array(domain.roleIDs)

        if let existing = existing {
            // Update existing model in place for SwiftData change tracking
            existing.name = domain.name
            existing.email = domain.email
            existing.isActive = domain.isActive
            existing.roleIDs = roleIDsArray
            return existing
        } else {
            // Create new model
            return UserModel(
                id: domain.id,
                name: domain.name,
                email: domain.email,
                isActive: domain.isActive,
                roleIDs: roleIDsArray
            )
        }
    }
}
