import Foundation
import Models
import EduGoCommon

/// Auth - Authentication and authorization module
///
/// Handles user authentication, token management, and authorization.
/// TIER-3 Domain module.
///
/// ## UserContextProtocol Implementation
///
/// AuthManager implementa `UserContextProtocol` para exponer información básica
/// del usuario a otros módulos sin crear dependencias circulares.
public actor AuthManager: Sendable, UserContextProtocol {
    public static let shared = AuthManager()

    private var currentUser: User?
    private var accessToken: String?

    private init() {}

    /// Check if user is authenticated
    public var isAuthenticated: Bool {
        accessToken != nil
    }

    /// Get current authenticated user
    public func getCurrentUser() -> User? {
        currentUser
    }

    /// Sign in with credentials
    public func signIn(email: String, password: String) async throws {
        // Placeholder implementation
        // In production, this would call authentication API
        let user = User(id: UUID(), email: email, name: "User")
        currentUser = user
        accessToken = "mock_token"
    }

    /// Sign out
    public func signOut() {
        currentUser = nil
        accessToken = nil
    }

    // MARK: - UserContextProtocol Implementation

    /// ID del usuario actualmente autenticado
    public var currentUserId: UUID? {
        get async {
            currentUser?.id
        }
    }

    /// Email del usuario actualmente autenticado
    public var currentUserEmail: String? {
        get async {
            currentUser?.email
        }
    }
}
