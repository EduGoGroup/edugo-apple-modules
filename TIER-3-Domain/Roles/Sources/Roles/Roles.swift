import Foundation

/// Roles - Role-based access control module
///
/// Manages user roles, permissions, and access control.
/// TIER-3 Domain module.
public enum UserRole: String, Sendable, Codable {
    case student
    case teacher
    case admin
    case parent
}

public struct Permission: Sendable, Codable {
    public let name: String
    public let scope: String

    public init(name: String, scope: String) {
        self.name = name
        self.scope = scope
    }
}

public actor RolesManager: Sendable {
    public static let shared = RolesManager()

    private var currentRole: UserRole?
    private var permissions: Set<String> = []

    private init() {}

    /// Set current user role
    public func setRole(_ role: UserRole) {
        currentRole = role
        configurePermissions(for: role)
    }

    /// Check if user has permission
    public func hasPermission(_ permission: String) -> Bool {
        permissions.contains(permission)
    }

    /// Get current role
    public func getCurrentRole() -> UserRole? {
        currentRole
    }

    private func configurePermissions(for role: UserRole) {
        switch role {
        case .student:
            permissions = ["view_courses", "submit_assignments"]
        case .teacher:
            permissions = ["view_courses", "create_assignments", "grade_assignments"]
        case .admin:
            permissions = ["view_courses", "create_courses", "manage_users", "view_analytics"]
        case .parent:
            permissions = ["view_student_progress"]
        }
    }
}
