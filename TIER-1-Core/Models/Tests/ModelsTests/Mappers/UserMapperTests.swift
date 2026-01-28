import Testing
import Foundation
@testable import Models

@Suite("UserMapper Tests")
struct UserMapperTests {

    // MARK: - toDomain Tests

    @Test("toDomain with valid DTO returns User")
    func toDomainWithValidDTO() throws {
        let roleID1 = UUID()
        let roleID2 = UUID()
        let dto = UserDTO(
            id: UUID(),
            name: "John Doe",
            email: "john@example.com",
            isActive: true,
            roleIDs: [roleID1, roleID2]
        )

        let user = try UserMapper.toDomain(dto)

        #expect(user.id == dto.id)
        #expect(user.name == "John Doe")
        #expect(user.email == "john@example.com")
        #expect(user.isActive == true)
        #expect(user.roleIDs.count == 2)
        #expect(user.roleIDs.contains(roleID1))
        #expect(user.roleIDs.contains(roleID2))
    }

    @Test("toDomain with invalid email throws validation error")
    func toDomainWithInvalidEmail() {
        let dto = UserDTO(id: UUID(), name: "Test", email: "invalid-email", isActive: true, roleIDs: [])

        #expect(throws: (any Error).self) {
            _ = try UserMapper.toDomain(dto)
        }
    }

    @Test("toDomain with empty name throws validation error")
    func toDomainWithEmptyName() {
        let dto = UserDTO(id: UUID(), name: "   ", email: "test@example.com", isActive: true, roleIDs: [])

        #expect(throws: (any Error).self) {
            _ = try UserMapper.toDomain(dto)
        }
    }

    @Test("toDomain normalizes email to lowercase")
    func toDomainNormalizesEmail() throws {
        let dto = UserDTO(id: UUID(), name: "Test", email: "John.Doe@Example.COM", isActive: true, roleIDs: [])

        let user = try UserMapper.toDomain(dto)

        #expect(user.email == "john.doe@example.com")
    }

    @Test("toDomain trims name whitespace")
    func toDomainTrimsName() throws {
        let dto = UserDTO(id: UUID(), name: "  John Doe  ", email: "john@example.com", isActive: true, roleIDs: [])

        let user = try UserMapper.toDomain(dto)

        #expect(user.name == "John Doe")
    }

    @Test("toDomain converts roleIDs array to set removing duplicates")
    func toDomainConvertsRoleIDsArrayToSet() throws {
        let roleID = UUID()
        let dto = UserDTO(id: UUID(), name: "Test", email: "test@example.com", isActive: true, roleIDs: [roleID, roleID, roleID])

        let user = try UserMapper.toDomain(dto)

        #expect(user.roleIDs.count == 1)
        #expect(user.roleIDs.contains(roleID))
    }

    // MARK: - toDTO Tests

    @Test("toDTO converts User correctly")
    func toDTOConvertsCorrectly() throws {
        let roleID = UUID()
        let user = try User(id: UUID(), name: "Jane", email: "jane@test.com", isActive: false, roleIDs: [roleID])

        let dto = UserMapper.toDTO(user)

        #expect(dto.id == user.id)
        #expect(dto.name == user.name)
        #expect(dto.email == user.email)
        #expect(dto.isActive == false)
        #expect(dto.roleIDs.count == 1)
        #expect(dto.roleIDs.contains(roleID))
    }

    @Test("toDTO with empty roleIDs returns empty array")
    func toDTOWithEmptyRoleIDs() throws {
        let user = try User(id: UUID(), name: "Test", email: "test@test.com", isActive: true, roleIDs: [])

        let dto = UserMapper.toDTO(user)

        #expect(dto.roleIDs.isEmpty)
    }

    // MARK: - Roundtrip Tests

    @Test("roundtrip preserves data")
    func roundtripPreservesData() throws {
        let roleID = UUID()
        let original = try User(id: UUID(), name: "Test User", email: "test@test.com", isActive: true, roleIDs: [roleID])

        let dto = UserMapper.toDTO(original)
        let converted = try UserMapper.toDomain(dto)

        #expect(original == converted)
    }

    @Test("roundtrip with multiple roleIDs preserves all IDs")
    func roundtripWithMultipleRoleIDs() throws {
        let roleIDs: Set<UUID> = [UUID(), UUID(), UUID()]
        let original = try User(id: UUID(), name: "Multi Role", email: "multi@test.com", isActive: true, roleIDs: roleIDs)

        let dto = UserMapper.toDTO(original)
        let converted = try UserMapper.toDomain(dto)

        #expect(original.roleIDs == converted.roleIDs)
    }
}
