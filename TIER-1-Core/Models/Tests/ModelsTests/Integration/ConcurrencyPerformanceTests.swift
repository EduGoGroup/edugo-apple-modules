import Testing
import Foundation
@testable import Models

/// Performance tests for domain entities under high-concurrency scenarios.
///
/// These tests measure:
/// 1. Performance impact of value semantics (copy-on-write)
/// 2. Throughput under load (1000+ operations)
/// 3. Memory behavior with large entity graphs
@Suite("Concurrency Performance Tests")
struct ConcurrencyPerformanceTests {

    // MARK: - High-Volume Operations

    @Test("1000+ User copy operations complete quickly")
    func testMassiveUserCopyOperations() async throws {
        let baseUser = try User(
            firstName: "Performance",
            lastName: "Test User",
            email: "perf@test.com"
        )

        let startTime = ContinuousClock.now

        // Perform 1000 concurrent copy operations
        let results = await withTaskGroup(of: User.self, returning: [User].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    var modified = try! baseUser.with(firstName: "User\(i)")
                    // Simulate typical modifications
                    if i % 2 == 0 {
                        modified = modified.with(isActive: false)
                    }
                    return modified
                }
            }

            var results: [User] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        // Should complete in under 2 seconds
        #expect(elapsed < .seconds(2), "Operations took too long: \(elapsed)")
    }

    @Test("1000+ Role operations with permission management")
    func testMassiveRoleOperations() async throws {
        let permissionIDs = (0..<10).map { _ in UUID() }

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Role.self, returning: [Role].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    var role = try! Role(
                        name: "Role \(i)",
                        level: RoleLevel.allCases[i % 3]
                    )

                    // Add multiple permissions
                    for permID in permissionIDs.prefix(i % 10 + 1) {
                        role = role.addPermission(permID)
                    }

                    return role
                }
            }

            var results: [Role] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "Operations took too long: \(elapsed)")
    }

    @Test("1000+ Document lifecycle operations")
    func testMassiveDocumentOperations() async throws {
        let ownerID = UUID()

        let startTime = ContinuousClock.now

        let results = await withTaskGroup(of: Document?.self, returning: [Document].self) { group in
            for i in 0..<1000 {
                group.addTask {
                    guard let doc = try? Document(
                        title: "Doc \(i)",
                        content: "Content \(i)",
                        type: DocumentType.allCases[i % DocumentType.allCases.count],
                        ownerID: ownerID
                    ) else { return nil }

                    // Add some collaborators
                    var modified = doc
                    for _ in 0..<(i % 5) {
                        modified = modified.addCollaborator(UUID())
                    }

                    // Update content
                    modified = modified.with(content: "Updated content \(i)")

                    return modified
                }
            }

            var results: [Document] = []
            results.reserveCapacity(1000)
            for await result in group {
                if let doc = result {
                    results.append(doc)
                }
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 1000)
        #expect(elapsed < .seconds(2), "Operations took too long: \(elapsed)")
    }

    // MARK: - Large Graph Performance

    @Test("Large entity graph construction performance")
    func testLargeGraphConstruction() async throws {
        let startTime = ContinuousClock.now

        // Create a large permission set
        let permissions = await withTaskGroup(of: Permission.self, returning: [Permission].self) { group in
            for resource in Resource.allCases {
                for action in Action.allCases {
                    group.addTask {
                        Permission.create(resource: resource, action: action)
                    }
                }
            }

            var results: [Permission] = []
            for await perm in group {
                results.append(perm)
            }
            return results
        }

        // Create roles with permissions
        let roles = await withTaskGroup(of: Role.self, returning: [Role].self) { group in
            for i in 0..<50 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    var role = try! Role(
                        name: "Role \(i)",
                        level: RoleLevel.allCases[i % 3]
                    )
                    for perm in permissions.prefix(permissions.count / 2) {
                        role = role.addPermission(perm.id)
                    }
                    return role
                }
            }

            var results: [Role] = []
            for await role in group {
                results.append(role)
            }
            return results
        }

        // Create users (roles are now managed via Membership, not stored in User)
        let users = await withTaskGroup(of: User.self, returning: [User].self) { group in
            for i in 0..<100 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    try! User(
                        firstName: "User",
                        lastName: "\(i)",
                        email: "user\(i)@perf.test"
                    )
                }
            }

            var results: [User] = []
            for await user in group {
                results.append(user)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        // Verify graph construction
        #expect(permissions.count == Resource.allCases.count * Action.allCases.count)
        #expect(roles.count == 50)
        #expect(users.count == 100)
        #expect(elapsed < .seconds(2), "Graph construction took too long: \(elapsed)")
    }

    // MARK: - Read-Heavy Workload

    @Test("Read-heavy concurrent access performance")
    func testReadHeavyWorkload() async throws {
        // Setup: Create a user
        // swiftlint:disable:next force_try
        let user = try! User(firstName: "Read", lastName: "Test", email: "read@test.com")

        let startTime = ContinuousClock.now

        // Perform 5000 concurrent reads
        let results = await withTaskGroup(
            of: (fullName: String, email: String).self,
            returning: [(fullName: String, email: String)].self
        ) { group in
            for _ in 0..<5000 {
                group.addTask {
                    (user.fullName, user.email)
                }
            }

            var results: [(fullName: String, email: String)] = []
            results.reserveCapacity(5000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        #expect(results.count == 5000)
        #expect(results.allSatisfy { $0.fullName == "Read Test" && $0.email == "read@test.com" })
        #expect(elapsed < .seconds(1), "Read operations took too long: \(elapsed)")
    }

    // MARK: - Mixed Workload

    @Test("Mixed read/write workload performance")
    func testMixedWorkload() async throws {
        let baseUser = try User(firstName: "Mixed", lastName: "Test", email: "mixed@test.com")

        let startTime = ContinuousClock.now

        // 70% reads, 30% writes
        let results = await withTaskGroup(
            of: (isWrite: Bool, success: Bool).self,
            returning: [(isWrite: Bool, success: Bool)].self
        ) { group in
            for i in 0..<1000 {
                let isWrite = i % 10 < 3 // 30% writes
                group.addTask {
                    if isWrite {
                        // swiftlint:disable:next force_try
                        let modified = try! baseUser.with(firstName: "Modified\(i)")
                        return (true, modified.firstName.starts(with: "Modified"))
                    } else {
                        _ = baseUser.fullName
                        _ = baseUser.email
                        _ = baseUser.isActive
                        return (false, true)
                    }
                }
            }

            var results: [(isWrite: Bool, success: Bool)] = []
            results.reserveCapacity(1000)
            for await result in group {
                results.append(result)
            }
            return results
        }

        let elapsed = ContinuousClock.now - startTime

        let writes = results.filter { $0.isWrite }
        let reads = results.filter { !$0.isWrite }

        #expect(writes.count == 300)
        #expect(reads.count == 700)
        #expect(results.allSatisfy { $0.success })
        #expect(elapsed < .seconds(2), "Mixed workload took too long: \(elapsed)")
    }

    // MARK: - Aggregation Performance

    @Test("Concurrent aggregation produces correct results")
    func testConcurrentAggregation() async throws {
        // Create 100 users
        let users = try (0..<100).map { i in
            try User(firstName: "User", lastName: "\(i)", email: "user\(i)@agg.test")
        }

        let startTime = ContinuousClock.now

        // Concurrently count total fullName length across all users
        let totalLength = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            for user in users {
                group.addTask {
                    user.fullName.count
                }
            }

            var total = 0
            for await count in group {
                total += count
            }
            return total
        }

        let elapsed = ContinuousClock.now - startTime

        // Expected: "User 0" to "User 99" - calculate actual expected length
        // "User " = 5 chars + digit length (1 or 2)
        // 0-9: 10 users * (5 + 1) = 60
        // 10-99: 90 users * (5 + 2) = 630
        let expectedTotal = 10 * 6 + 90 * 7  // = 60 + 630 = 690
        #expect(totalLength == expectedTotal)
        #expect(elapsed < .seconds(1), "Aggregation took too long: \(elapsed)")
    }

    // MARK: - Stress Test

    @Test("Extreme concurrent pressure test")
    func testExtremeConcurrentPressure() async throws {
        let startTime = ContinuousClock.now

        // Spawn many tasks that each do multiple operations
        let results = await withTaskGroup(of: Int.self, returning: Int.self) { group in
            for i in 0..<200 {
                group.addTask {
                    var operationCount = 0

                    // Create and modify user (5 operations)
                    // swiftlint:disable:next force_try
                    var user = try! User(firstName: "Stress", lastName: "\(i)", email: "stress\(i)@test.com")
                    for j in 0..<5 {
                        // swiftlint:disable:next force_try
                        user = try! user.with(firstName: "Stress\(j)")
                        operationCount += 1
                    }

                    // Create and modify role
                    // swiftlint:disable:next force_try
                    var role = try! Role(name: "StressRole \(i)", level: .teacher)
                    for _ in 0..<5 {
                        role = role.addPermission(UUID())
                        operationCount += 1
                    }

                    // Create and modify document
                    // swiftlint:disable:next force_try
                    var doc = try! Document(
                        title: "StressDoc \(i)",
                        content: "Content",
                        type: .lesson,
                        ownerID: user.id
                    )
                    for _ in 0..<5 {
                        doc = doc.addCollaborator(UUID())
                        operationCount += 1
                    }

                    return operationCount
                }
            }

            var total = 0
            for await count in group {
                total += count
            }
            return total
        }

        let elapsed = ContinuousClock.now - startTime

        // 200 tasks * 15 operations each = 3000 total operations
        #expect(results == 3000)
        #expect(elapsed < .seconds(2), "Stress test took too long: \(elapsed)")
    }
}
