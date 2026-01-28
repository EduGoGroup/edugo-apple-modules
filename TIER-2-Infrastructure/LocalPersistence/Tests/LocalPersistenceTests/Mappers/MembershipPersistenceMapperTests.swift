import Testing
import Foundation
import SwiftData
import Models
@testable import LocalPersistence

@Suite("MembershipPersistenceMapper Tests")
struct MembershipPersistenceMapperTests {

    // MARK: - Roundtrip Tests

    @Test("Domain to Model to Domain roundtrip produces identical membership")
    func testRoundtrip() {
        let userID = UUID()
        let unitID = UUID()
        let enrolledAt = Date()
        let createdAt = Date()
        let updatedAt = Date()
        let original = TestDataFactory.makeMembership(
            userID: userID,
            unitID: unitID,
            role: .teacher,
            isActive: true,
            enrolledAt: enrolledAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        // Domain -> Model
        let model = MembershipPersistenceMapper.toModel(original, existing: nil)

        // Model -> Domain
        let restored = MembershipPersistenceMapper.toDomain(model)

        #expect(restored.id == original.id)
        #expect(restored.userID == original.userID)
        #expect(restored.unitID == original.unitID)
        #expect(restored.role == original.role)
        #expect(restored.isActive == original.isActive)
        #expect(restored.enrolledAt == original.enrolledAt)
        #expect(restored.createdAt == original.createdAt)
        #expect(restored.updatedAt == original.updatedAt)
    }

    @Test("Roundtrip preserves all roles")
    func testRoundtripPreservesRoles() {
        let roles: [MembershipRole] = [.owner, .teacher, .assistant, .student, .guardian]

        for role in roles {
            let original = TestDataFactory.makeMembership(role: role)
            let model = MembershipPersistenceMapper.toModel(original, existing: nil)
            let restored = MembershipPersistenceMapper.toDomain(model)

            #expect(restored.role == role)
        }
    }

    @Test("Roundtrip with withdrawnAt date")
    func testRoundtripWithWithdrawnAt() {
        let withdrawnAt = Date()
        let original = TestDataFactory.makeMembership(
            isActive: false,
            withdrawnAt: withdrawnAt
        )

        let model = MembershipPersistenceMapper.toModel(original, existing: nil)
        let restored = MembershipPersistenceMapper.toDomain(model)

        #expect(restored.withdrawnAt == withdrawnAt)
        #expect(restored.isActive == false)
    }

    @Test("Roundtrip preserves timestamps")
    func testRoundtripPreservesTimestamps() {
        let createdAt = Date(timeIntervalSince1970: 1000000)
        let updatedAt = Date(timeIntervalSince1970: 2000000)
        let enrolledAt = Date(timeIntervalSince1970: 500000)
        let original = TestDataFactory.makeMembership(
            enrolledAt: enrolledAt,
            createdAt: createdAt,
            updatedAt: updatedAt
        )

        let model = MembershipPersistenceMapper.toModel(original, existing: nil)
        let restored = MembershipPersistenceMapper.toDomain(model)

        #expect(restored.enrolledAt == enrolledAt)
        #expect(restored.createdAt == createdAt)
        #expect(restored.updatedAt == updatedAt)
    }

    // MARK: - toModel Tests

    @Test("toModel creates new model when existing is nil")
    func testToModelCreatesNew() {
        let membership = TestDataFactory.makeMembership()

        let model = MembershipPersistenceMapper.toModel(membership, existing: nil)

        #expect(model.id == membership.id)
        #expect(model.userID == membership.userID)
        #expect(model.unitID == membership.unitID)
        #expect(model.role == membership.role.rawValue)
    }

    @Test("toModel updates existing model in place")
    func testToModelUpdatesExisting() {
        let membership1 = TestDataFactory.makeMembership(role: .student)
        let existingModel = MembershipPersistenceMapper.toModel(membership1, existing: nil)

        let newUpdatedAt = Date()
        let membership2 = Membership(
            id: membership1.id,
            userID: membership1.userID,
            unitID: membership1.unitID,
            role: .teacher,
            isActive: false,
            enrolledAt: membership1.enrolledAt,
            withdrawnAt: Date(),
            createdAt: membership1.createdAt,
            updatedAt: newUpdatedAt
        )

        let updatedModel = MembershipPersistenceMapper.toModel(membership2, existing: existingModel)

        // Should be the same instance
        #expect(updatedModel === existingModel)
        #expect(updatedModel.role == "teacher")
        #expect(updatedModel.isActive == false)
        #expect(updatedModel.withdrawnAt != nil)
        #expect(updatedModel.updatedAt == newUpdatedAt)
    }

    @Test("toModel converts role enum to string")
    func testToModelConvertsRoleToString() {
        let membership = TestDataFactory.makeMembership(role: .owner)

        let model = MembershipPersistenceMapper.toModel(membership, existing: nil)

        #expect(model.role == "owner")
    }

    // MARK: - toDomain Tests

    @Test("toDomain creates valid domain membership")
    func testToDomainCreatesValidMembership() {
        let userID = UUID()
        let unitID = UUID()
        let model = MembershipModel(
            id: UUID(),
            userID: userID,
            unitID: unitID,
            role: "teacher",
            isActive: true,
            enrolledAt: Date()
        )

        let membership = MembershipPersistenceMapper.toDomain(model)

        #expect(membership.id == model.id)
        #expect(membership.userID == userID)
        #expect(membership.unitID == unitID)
        #expect(membership.role == .teacher)
        #expect(membership.isActive == true)
    }

    @Test("toDomain defaults unknown role to student")
    func testToDomainDefaultsUnknownRoleToStudent() {
        let model = MembershipModel(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "unknown_role",
            isActive: true,
            enrolledAt: Date()
        )

        let membership = MembershipPersistenceMapper.toDomain(model)

        #expect(membership.role == .student)
    }

    @Test("toDomain converts all known role strings")
    func testToDomainConvertsAllKnownRoles() {
        let roleMapping: [(String, MembershipRole)] = [
            ("owner", .owner),
            ("teacher", .teacher),
            ("assistant", .assistant),
            ("student", .student),
            ("guardian", .guardian)
        ]

        for (roleString, expectedRole) in roleMapping {
            let model = MembershipModel(
                id: UUID(),
                userID: UUID(),
                unitID: UUID(),
                role: roleString,
                isActive: true,
                enrolledAt: Date()
            )

            let membership = MembershipPersistenceMapper.toDomain(model)

            #expect(membership.role == expectedRole)
        }
    }

    @Test("toDomain handles nil withdrawnAt")
    func testToDomainHandlesNilWithdrawnAt() {
        let model = MembershipModel(
            id: UUID(),
            userID: UUID(),
            unitID: UUID(),
            role: "student",
            isActive: true,
            enrolledAt: Date(),
            withdrawnAt: nil
        )

        let membership = MembershipPersistenceMapper.toDomain(model)

        #expect(membership.withdrawnAt == nil)
    }
}
