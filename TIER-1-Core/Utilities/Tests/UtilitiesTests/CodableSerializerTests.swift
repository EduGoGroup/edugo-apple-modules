import Foundation
import Testing
@testable import Utilities

/// Tests for `CodableSerializer` actor.
@Suite("CodableSerializer Tests")
struct CodableSerializerTests {

    // MARK: - Test Models

    struct TestUser: Codable, Equatable, Sendable {
        let userId: UUID
        let userName: String
        let createdAt: Date
        let isActive: Bool
    }

    struct NestedModel: Codable, Equatable, Sendable {
        let parentId: Int
        let childItems: [ChildItem]

        struct ChildItem: Codable, Equatable, Sendable {
            let itemName: String
            let itemValue: Double
        }
    }

    // MARK: - Encoding Tests

    @Test("Encode simple struct to JSON data")
    func encodeSimpleStruct() async throws {
        let serializer = CodableSerializer()
        let userId = UUID()
        let createdAt = Date(timeIntervalSince1970: 1705312200)
        let user = TestUser(
            userId: userId,
            userName: "John Doe",
            createdAt: createdAt,
            isActive: true
        )

        let data = try await serializer.encode(user)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"user_id\""))
        #expect(jsonString.contains("\"user_name\""))
        #expect(jsonString.contains("\"created_at\""))
        #expect(jsonString.contains("\"is_active\""))
        #expect(jsonString.contains("John Doe"))
        // UUID in JSON is uppercase
        #expect(jsonString.lowercased().contains(userId.uuidString.lowercased()))
    }

    @Test("Encode with pretty printing")
    func encodePrettyPrinted() async throws {
        let serializer = CodableSerializer()
        let user = TestUser(
            userId: UUID(),
            userName: "Test",
            createdAt: Date(),
            isActive: false
        )

        let prettyData = try await serializer.encode(user, prettyPrinted: true)
        let prettyString = String(data: prettyData, encoding: .utf8)!

        #expect(prettyString.contains("\n"))
        #expect(prettyString.contains("  "))
    }

    @Test("Encode to string")
    func encodeToString() async throws {
        let serializer = CodableSerializer()
        let user = TestUser(
            userId: UUID(),
            userName: "StringTest",
            createdAt: Date(),
            isActive: true
        )

        let jsonString = try await serializer.encodeToString(user)

        #expect(jsonString.contains("\"user_name\""))
        #expect(jsonString.contains("StringTest"))
    }

    @Test("Encode nested structures")
    func encodeNestedStructures() async throws {
        let serializer = CodableSerializer()
        let nested = NestedModel(
            parentId: 42,
            childItems: [
                .init(itemName: "First", itemValue: 1.5),
                .init(itemName: "Second", itemValue: 2.5)
            ]
        )

        let data = try await serializer.encode(nested)
        let jsonString = String(data: data, encoding: .utf8)!

        #expect(jsonString.contains("\"parent_id\""))
        #expect(jsonString.contains("\"child_items\""))
        #expect(jsonString.contains("\"item_name\""))
        #expect(jsonString.contains("\"item_value\""))
    }

    // MARK: - Decoding Tests

    @Test("Decode JSON data to struct")
    func decodeJSONData() async throws {
        let serializer = CodableSerializer()
        let userId = UUID()
        let json = """
        {
            "user_id": "\(userId.uuidString)",
            "user_name": "Jane Doe",
            "created_at": "2024-01-15T10:30:00Z",
            "is_active": true
        }
        """
        let data = json.data(using: .utf8)!

        let user: TestUser = try await serializer.decode(TestUser.self, from: data)

        #expect(user.userId == userId)
        #expect(user.userName == "Jane Doe")
        #expect(user.isActive == true)
    }

    @Test("Decode JSON string to struct")
    func decodeJSONString() async throws {
        let serializer = CodableSerializer()
        let userId = UUID()
        let json = """
        {
            "user_id": "\(userId.uuidString)",
            "user_name": "Bob Smith",
            "created_at": "2024-06-20T15:45:00Z",
            "is_active": false
        }
        """

        let user: TestUser = try await serializer.decode(TestUser.self, from: json)

        #expect(user.userId == userId)
        #expect(user.userName == "Bob Smith")
        #expect(user.isActive == false)
    }

    @Test("Decode nested structures")
    func decodeNestedStructures() async throws {
        let serializer = CodableSerializer()
        let json = """
        {
            "parent_id": 100,
            "child_items": [
                {"item_name": "Alpha", "item_value": 10.0},
                {"item_name": "Beta", "item_value": 20.5}
            ]
        }
        """
        let data = json.data(using: .utf8)!

        let nested: NestedModel = try await serializer.decode(NestedModel.self, from: data)

        #expect(nested.parentId == 100)
        #expect(nested.childItems.count == 2)
        #expect(nested.childItems[0].itemName == "Alpha")
        #expect(nested.childItems[1].itemValue == 20.5)
    }

    // MARK: - Round-trip Tests

    @Test("Encode then decode produces equal result")
    func roundTripEquality() async throws {
        let serializer = CodableSerializer()
        let original = TestUser(
            userId: UUID(),
            userName: "RoundTrip User",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        let encoded = try await serializer.encode(original)
        let decoded: TestUser = try await serializer.decode(TestUser.self, from: encoded)

        #expect(original == decoded)
    }

    @Test("Round-trip nested model")
    func roundTripNestedModel() async throws {
        let serializer = CodableSerializer()
        let original = NestedModel(
            parentId: 999,
            childItems: [
                .init(itemName: "Item1", itemValue: 1.1),
                .init(itemName: "Item2", itemValue: 2.2),
                .init(itemName: "Item3", itemValue: 3.3)
            ]
        )

        let encoded = try await serializer.encode(original)
        let decoded: NestedModel = try await serializer.decode(NestedModel.self, from: encoded)

        #expect(original == decoded)
    }

    // MARK: - Error Handling Tests

    @Test("Decode invalid JSON throws decodingFailed error")
    func decodeInvalidJSON() async throws {
        let serializer = CodableSerializer()
        let invalidJSON = "{ invalid json }"

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: invalidJSON)
        }
    }

    @Test("Decode missing required field throws decodingFailed error")
    func decodeMissingField() async throws {
        let serializer = CodableSerializer()
        let incompleteJSON = """
        {
            "user_id": "\(UUID().uuidString)",
            "user_name": "Missing Fields"
        }
        """

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: incompleteJSON)
        }
    }

    @Test("Decode type mismatch throws decodingFailed error")
    func decodeTypeMismatch() async throws {
        let serializer = CodableSerializer()
        let wrongTypeJSON = """
        {
            "user_id": "\(UUID().uuidString)",
            "user_name": 12345,
            "created_at": "2024-01-15T10:30:00Z",
            "is_active": true
        }
        """

        await #expect(throws: SerializationError.self) {
            let _: TestUser = try await serializer.decode(TestUser.self, from: wrongTypeJSON)
        }
    }

    // MARK: - Shared Instance Tests

    @Test("Shared instance is consistent")
    func sharedInstanceConsistency() async throws {
        let user = TestUser(
            userId: UUID(),
            userName: "Shared Test",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        let encoded = try await CodableSerializer.shared.encode(user)
        let decoded: TestUser = try await CodableSerializer.shared.decode(TestUser.self, from: encoded)

        #expect(user == decoded)
    }

    // MARK: - Configuration Tests

    @Test("Custom configuration with pretty printing")
    func customPrettyPrintConfiguration() async throws {
        let config = SerializerConfiguration.prettyPrinted
        let serializer = CodableSerializer(configuration: config)

        let user = TestUser(
            userId: UUID(),
            userName: "Pretty",
            createdAt: Date(),
            isActive: true
        )

        let data = try await serializer.encode(user)
        let string = String(data: data, encoding: .utf8)!

        #expect(string.contains("\n"))
    }

    @Test("Default configuration uses snake_case and ISO8601")
    func defaultConfigurationStrategies() async throws {
        let config = SerializerConfiguration.default
        let serializer = CodableSerializer(configuration: config)

        let user = TestUser(
            userId: UUID(),
            userName: "ConfigTest",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        let jsonString = try await serializer.encodeToString(user)

        #expect(jsonString.contains("\"user_name\""))
        #expect(jsonString.contains("\"created_at\""))
        // ISO8601 format, exact time depends on timezone but format is consistent
        #expect(jsonString.contains("2024-01-15T"))
        #expect(jsonString.contains(":00Z"))
    }

    // MARK: - Concurrency Tests

    @Test("Concurrent encode operations are thread-safe")
    func concurrentEncode() async throws {
        let serializer = CodableSerializer.shared

        try await withThrowingTaskGroup(of: Data.self) { group in
            for i in 0..<100 {
                group.addTask {
                    let user = TestUser(
                        userId: UUID(),
                        userName: "User\(i)",
                        createdAt: Date(),
                        isActive: i % 2 == 0
                    )
                    return try await serializer.encode(user)
                }
            }

            var count = 0
            for try await _ in group {
                count += 1
            }

            #expect(count == 100)
        }
    }

    @Test("Concurrent decode operations are thread-safe")
    func concurrentDecode() async throws {
        let serializer = CodableSerializer.shared
        let userId = UUID()
        let json = """
        {
            "user_id": "\(userId.uuidString)",
            "user_name": "Concurrent",
            "created_at": "2024-01-15T10:30:00Z",
            "is_active": true
        }
        """

        try await withThrowingTaskGroup(of: TestUser.self) { group in
            for _ in 0..<100 {
                group.addTask {
                    try await serializer.decode(TestUser.self, from: json)
                }
            }

            var count = 0
            for try await user in group {
                #expect(user.userId == userId)
                count += 1
            }

            #expect(count == 100)
        }
    }

    @Test("Mixed concurrent encode and decode operations")
    func mixedConcurrentOperations() async throws {
        let serializer = CodableSerializer.shared
        let original = TestUser(
            userId: UUID(),
            userName: "Mixed",
            createdAt: Date(timeIntervalSince1970: 1705312200),
            isActive: true
        )

        try await withThrowingTaskGroup(of: Bool.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    let encoded = try await serializer.encode(original)
                    let decoded: TestUser = try await serializer.decode(TestUser.self, from: encoded)
                    return original == decoded
                }
            }

            for try await result in group {
                #expect(result == true)
            }
        }
    }
}

// MARK: - SerializationError Tests

@Suite("SerializationError Tests")
struct SerializationErrorTests {

    @Test("Error descriptions are meaningful")
    func errorDescriptions() {
        let encodingError = SerializationError.encodingFailed(
            type: "TestType",
            reason: "Test reason"
        )
        let decodingError = SerializationError.decodingFailed(
            type: "AnotherType",
            reason: "Another reason"
        )

        #expect(encodingError.errorDescription?.contains("TestType") == true)
        #expect(encodingError.errorDescription?.contains("Test reason") == true)
        #expect(decodingError.errorDescription?.contains("AnotherType") == true)
        #expect(decodingError.errorDescription?.contains("Another reason") == true)
    }

    @Test("Errors are equatable")
    func errorsEquatable() {
        let error1 = SerializationError.encodingFailed(type: "Type", reason: "Reason")
        let error2 = SerializationError.encodingFailed(type: "Type", reason: "Reason")
        let error3 = SerializationError.decodingFailed(type: "Type", reason: "Reason")

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}

// MARK: - SerializerConfiguration Tests

@Suite("SerializerConfiguration Tests")
struct SerializerConfigurationTests {

    @Test("Default configuration has expected values")
    func defaultConfiguration() {
        let config = SerializerConfiguration.default

        #expect(config.outputFormatting == nil)
    }

    @Test("PrettyPrinted configuration has formatting")
    func prettyPrintedConfiguration() {
        let config = SerializerConfiguration.prettyPrinted

        #expect(config.outputFormatting?.contains(.prettyPrinted) == true)
        #expect(config.outputFormatting?.contains(.sortedKeys) == true)
    }

    @Test("Custom configuration preserves values")
    func customConfiguration() {
        let config = SerializerConfiguration(
            dateEncodingStrategy: .secondsSince1970,
            keyEncodingStrategy: .useDefaultKeys,
            dateDecodingStrategy: .secondsSince1970,
            keyDecodingStrategy: .useDefaultKeys,
            outputFormatting: .prettyPrinted
        )

        #expect(config.outputFormatting == .prettyPrinted)
    }
}
