import Foundation
import SwiftData
import Models
import EduGoCommon

/// Local repository for User entities using SwiftData
///
/// This actor implements `UserRepositoryProtocol` and provides thread-safe
/// CRUD operations for User entities persisted in SwiftData.
///
/// ## Thread Safety
///
/// As an actor, all operations are automatically serialized, ensuring
/// thread-safe access to the underlying SwiftData context.
///
/// ## Usage
///
/// ```swift
/// let repository = LocalUserRepository()
///
/// // Save a user
/// let user = try User(name: "John", email: "john@example.com")
/// try await repository.save(user)
///
/// // Fetch a user
/// if let fetched = try await repository.get(id: user.id) {
///     print("Found: \(fetched.name)")
/// }
///
/// // List all users
/// let allUsers = try await repository.list()
///
/// // Delete a user
/// try await repository.delete(id: user.id)
/// ```
public actor LocalUserRepository: UserRepositoryProtocol {
    private let containerProvider: PersistenceContainerProvider

    /// Creates a new LocalUserRepository
    ///
    /// - Parameter containerProvider: The persistence container provider (defaults to shared)
    public init(containerProvider: PersistenceContainerProvider = .shared) {
        self.containerProvider = containerProvider
    }

    /// Retrieves a user by ID
    ///
    /// - Parameter id: The user's unique identifier
    /// - Returns: The user if found, nil otherwise
    /// - Throws: `RepositoryError.fetchFailed` if the query fails
    public func get(id: UUID) async throws -> User? {
        do {
            return try await containerProvider.perform { context in
                let predicate = #Predicate<UserModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let results = try context.fetch(descriptor)

                guard let model = results.first else {
                    return nil
                }

                return try UserPersistenceMapper.toDomain(model)
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map user: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }

    /// Saves a user (insert or update)
    ///
    /// If a user with the same ID exists, it will be updated.
    /// Otherwise, a new user will be created.
    ///
    /// - Parameter user: The user to save
    /// - Throws: `RepositoryError.saveFailed` if the save operation fails
    public func save(_ user: User) async throws {
        do {
            try await containerProvider.perform { context in
                // Check if user already exists (upsert)
                let predicate = #Predicate<UserModel> { model in
                    model.id == user.id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                let existing = try context.fetch(descriptor).first

                // Convert domain to model (updates existing or creates new)
                let model = UserPersistenceMapper.toModel(user, existing: existing)

                // Insert only if new
                if existing == nil {
                    context.insert(model)
                }

                try context.save()
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.saveFailed(reason: error.localizedDescription)
        }
    }

    /// Deletes a user by ID
    ///
    /// - Parameter id: The user's unique identifier
    /// - Throws: `RepositoryError.deleteFailed` if the user doesn't exist or deletion fails
    public func delete(id: UUID) async throws {
        do {
            try await containerProvider.perform { context in
                let predicate = #Predicate<UserModel> { model in
                    model.id == id
                }
                var descriptor = FetchDescriptor(predicate: predicate)
                descriptor.fetchLimit = 1

                guard let model = try context.fetch(descriptor).first else {
                    throw RepositoryError.deleteFailed(reason: "User with id \(id) not found")
                }

                context.delete(model)
                try context.save()
            }
        } catch let error as RepositoryError {
            throw error
        } catch {
            throw RepositoryError.deleteFailed(reason: error.localizedDescription)
        }
    }

    /// Lists all users
    ///
    /// - Returns: An array of all users
    /// - Throws: `RepositoryError.fetchFailed` if the query fails
    public func list() async throws -> [User] {
        do {
            return try await containerProvider.perform { context in
                let descriptor = FetchDescriptor<UserModel>()
                let models = try context.fetch(descriptor)

                return try models.map { model in
                    try UserPersistenceMapper.toDomain(model)
                }
            }
        } catch let error as RepositoryError {
            throw error
        } catch let error as DomainError {
            throw RepositoryError.fetchFailed(reason: "Failed to map users: \(error.localizedDescription)")
        } catch {
            throw RepositoryError.fetchFailed(reason: error.localizedDescription)
        }
    }
}
