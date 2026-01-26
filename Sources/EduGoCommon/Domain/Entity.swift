import Foundation

/// A protocol that defines the fundamental properties and behaviors for all domain entities.
///
/// The `Entity` protocol establishes a baseline contract for domain models in the EduGo system.
/// It combines `Identifiable`, `Equatable`, and `Sendable` to ensure entities are uniquely
/// identifiable, comparable, and safe to use across concurrency boundaries in Swift 6.2+.
///
/// ## Core Requirements
///
/// All conforming types must provide:
/// - A unique identifier (`id`)
/// - Creation timestamp (`createdAt`)
/// - Last modification timestamp (`updatedAt`)
///
/// ## Concurrency Safety
///
/// By conforming to `Sendable`, entities guarantee thread-safe access to their properties,
/// making them suitable for use with Swift's structured concurrency features including
/// `async`/`await`, actors, and task groups.
///
/// ## Usage Example
///
/// ```swift
/// public struct User: Entity {
///     public let id: UUID
///     public let createdAt: Date
///     public var updatedAt: Date
///
///     public let email: String
///     public var name: String
///
///     public init(
///         id: UUID = UUID(),
///         createdAt: Date = Date(),
///         updatedAt: Date = Date(),
///         email: String,
///         name: String
///     ) {
///         self.id = id
///         self.createdAt = createdAt
///         self.updatedAt = updatedAt
///         self.email = email
///         self.name = name
///     }
/// }
/// ```
///
/// ## Design Rationale
///
/// - **Identifiable**: Enables use in SwiftUI `ForEach` and collection operations requiring unique identification
/// - **Equatable**: Supports value comparison, essential for diffing, testing, and state management
/// - **Sendable**: Guarantees concurrency safety without requiring `@unchecked` escape hatches
///
/// - Note: Conforming types should use value types (`struct`) with immutable or properly synchronized properties
/// - Important: The `updatedAt` property should be updated whenever entity state changes
public protocol Entity: Identifiable, Equatable, Sendable where ID == UUID {
    /// The unique identifier for the entity.
    ///
    /// This property is required by `Identifiable` and must be a `UUID` to ensure
    /// global uniqueness across distributed systems.
    var id: ID { get }

    /// The timestamp when the entity was created.
    ///
    /// This value should be set once during entity initialization and remain immutable
    /// throughout the entity's lifecycle.
    var createdAt: Date { get }

    /// The timestamp when the entity was last updated.
    ///
    /// This value should be updated whenever any property of the entity changes,
    /// providing an audit trail for modifications.
    var updatedAt: Date { get }
}
