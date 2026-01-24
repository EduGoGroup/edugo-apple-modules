import Foundation

/// Models - Core data models module
///
/// Defines domain models, DTOs, and shared data structures.
/// TIER-1 Core module.
public protocol Model: Sendable, Codable, Identifiable {}

/// Base user model
public struct User: Model {
    public let id: UUID
    public let email: String
    public let name: String

    public init(id: UUID, email: String, name: String) {
        self.id = id
        self.email = email
        self.name = name
    }
}
