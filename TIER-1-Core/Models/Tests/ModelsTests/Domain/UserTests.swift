import Testing
import Foundation
import EduGoCommon
@testable import Models

@Suite("User Entity Tests")
struct UserTests {

    // MARK: - Initialization Tests

    @Test("User creation with valid data")
    func testValidUserCreation() throws {
        let user = try User(
            name: "John Doe",
            email: "john@edugo.com"
        )

        #expect(user.name == "John Doe")
        #expect(user.email == "john@edugo.com")
        #expect(user.isActive == true)
        #expect(user.roleIDs.isEmpty)
    }

    @Test("User creation trims whitespace from name")
    func testNameTrimming() throws {
        let user = try User(
            name: "  John Doe  ",
            email: "john@edugo.com"
        )

        #expect(user.name == "John Doe")
    }

    @Test("User creation lowercases email")
    func testEmailLowercase() throws {
        let user = try User(
            name: "John",
            email: "John@EDUGO.com"
        )

        #expect(user.email == "john@edugo.com")
    }

    @Test("User creation with custom ID")
    func testCustomID() throws {
        let customID = UUID()
        let user = try User(
            id: customID,
            name: "John",
            email: "john@edugo.com"
        )

        #expect(user.id == customID)
    }

    @Test("User creation with inactive status")
    func testInactiveUser() throws {
        let user = try User(
            name: "John",
            email: "john@edugo.com",
            isActive: false
        )

        #expect(user.isActive == false)
    }

    @Test("User creation with initial roles")
    func testInitialRoles() throws {
        let roleID1 = UUID()
        let roleID2 = UUID()
        let user = try User(
            name: "John",
            email: "john@edugo.com",
            roleIDs: [roleID1, roleID2]
        )

        #expect(user.roleIDs.count == 2)
        #expect(user.roleIDs.contains(roleID1))
        #expect(user.roleIDs.contains(roleID2))
    }

    // MARK: - Validation Tests

    @Test("User creation fails with empty name")
    func testEmptyNameFails() {
        #expect {
            _ = try User(name: "", email: "john@edugo.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "name" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with whitespace-only name")
    func testWhitespaceNameFails() {
        #expect {
            _ = try User(name: "   ", email: "john@edugo.com")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "name" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with invalid email")
    func testInvalidEmailFails() {
        #expect {
            _ = try User(name: "John", email: "notanemail")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "email" else {
                return false
            }
            return true
        }
    }

    @Test("User creation fails with email missing domain")
    func testEmailMissingDomainFails() {
        #expect {
            _ = try User(name: "John", email: "john@")
        } throws: { error in
            guard let domainError = error as? DomainError,
                  case .validationFailed(let field, _) = domainError,
                  field == "email" else {
                return false
            }
            return true
        }
    }

    @Test("Valid email formats are accepted")
    func testValidEmailFormats() throws {
        let validEmails = [
            "user@domain.com",
            "user.name@domain.com",
            "user+tag@domain.com",
            "user@sub.domain.com",
            "user123@domain.io"
        ]

        for email in validEmails {
            let user = try User(name: "Test", email: email)
            #expect(user.email == email.lowercased())
        }
    }

    // MARK: - Copy Method Tests

    @Test("with(name:) creates copy with new name")
    func testWithName() throws {
        let user = try User(name: "John", email: "john@edugo.com")
        let updated = try user.with(name: "Jane")

        #expect(updated.name == "Jane")
        #expect(updated.id == user.id)
        #expect(updated.email == user.email)
    }

    @Test("with(email:) creates copy with new email")
    func testWithEmail() throws {
        let user = try User(name: "John", email: "john@edugo.com")
        let updated = try user.with(email: "jane@edugo.com")

        #expect(updated.email == "jane@edugo.com")
        #expect(updated.id == user.id)
        #expect(updated.name == user.name)
    }

    @Test("with(isActive:) creates copy with new status")
    func testWithIsActive() throws {
        let user = try User(name: "John", email: "john@edugo.com")
        let deactivated = user.with(isActive: false)

        #expect(deactivated.isActive == false)
        #expect(deactivated.id == user.id)
    }

    // MARK: - Role Management Tests

    @Test("addRole adds role to user")
    func testAddRole() throws {
        let user = try User(name: "John", email: "john@edugo.com")
        let roleID = UUID()
        let updated = user.addRole(roleID)

        #expect(updated.roleIDs.contains(roleID))
        #expect(updated.roleIDs.count == 1)
    }

    @Test("addRole is idempotent")
    func testAddRoleIdempotent() throws {
        let user = try User(name: "John", email: "john@edugo.com")
        let roleID = UUID()
        let updated = user.addRole(roleID).addRole(roleID)

        #expect(updated.roleIDs.count == 1)
    }

    @Test("removeRole removes role from user")
    func testRemoveRole() throws {
        let roleID = UUID()
        let user = try User(
            name: "John",
            email: "john@edugo.com",
            roleIDs: [roleID]
        )
        let updated = user.removeRole(roleID)

        #expect(!updated.roleIDs.contains(roleID))
        #expect(updated.roleIDs.isEmpty)
    }

    @Test("hasRole returns correct value")
    func testHasRole() throws {
        let roleID = UUID()
        let otherRoleID = UUID()
        let user = try User(
            name: "John",
            email: "john@edugo.com",
            roleIDs: [roleID]
        )

        #expect(user.hasRole(roleID))
        #expect(!user.hasRole(otherRoleID))
    }

    // MARK: - Protocol Conformance Tests

    @Test("User conforms to Equatable")
    func testEquatable() throws {
        let id = UUID()
        let user1 = try User(id: id, name: "John", email: "john@edugo.com")
        let user2 = try User(id: id, name: "John", email: "john@edugo.com")
        let user3 = try User(name: "John", email: "john@edugo.com")

        #expect(user1 == user2)
        #expect(user1 != user3)
    }

    @Test("User conforms to Identifiable")
    func testIdentifiable() throws {
        let user = try User(name: "John", email: "john@edugo.com")
        #expect(user.id == user.id)
    }

    @Test("User conforms to Hashable")
    func testHashable() throws {
        let user1 = try User(name: "John", email: "john@edugo.com")
        let user2 = try User(name: "Jane", email: "jane@edugo.com")

        var userSet: Set<User> = []
        userSet.insert(user1)
        userSet.insert(user2)

        #expect(userSet.count == 2)
    }

    // MARK: - Error Description Tests

    @Test("DomainError has meaningful descriptions for validation failures")
    func testErrorDescriptions() {
        let emptyNameError = DomainError.validationFailed(field: "name", reason: "Name cannot be empty")
        let invalidEmailError = DomainError.validationFailed(field: "email", reason: "Invalid email: bad")

        #expect(emptyNameError.errorDescription?.contains("name") == true)
        #expect(emptyNameError.errorDescription?.contains("empty") == true)
        #expect(invalidEmailError.errorDescription?.contains("email") == true)
        #expect(invalidEmailError.errorDescription?.contains("bad") == true)
    }
}
