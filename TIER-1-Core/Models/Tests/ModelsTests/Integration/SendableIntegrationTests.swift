import Testing
import Foundation
@testable import Models

/// Integration tests validating Sendable conformance and thread-safety
/// of domain entities under concurrent access scenarios.
///
/// These tests verify that:
/// 1. Entities can be safely passed across task boundaries
/// 2. Concurrent modifications (via copy) don't cause data races
/// 3. The deterministic behavior of immutable value types holds under stress
@Suite("Sendable Integration Tests")
struct SendableIntegrationTests {

    // MARK: - Concurrent User Modifications

    @Test("Concurrent User modifications produce deterministic results")
    func testConcurrentUserModifications() async throws {
        let baseUser = try User(
            name: "Base User",
            email: "base@edugo.com"
        )

        // Simulate 100 concurrent "modifications" (each creates a copy)
        let results = await withTaskGroup(of: User.self, returning: [User].self) { group in
            for i in 0..<100 {
                let roleID = UUID()
                group.addTask {
                    // Each task gets its own copy (value semantics)
                    // and adds a unique role
                    let modified = baseUser.addRole(roleID)
                    // Simulate some work
                    _ = modified.name.count + i
                    return modified
                }
            }

            var results: [User] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        // Verify all 100 tasks completed
        #expect(results.count == 100)

        // Each result should have exactly 1 role (its own)
        // because value semantics means each task has isolated copy
        for result in results {
            #expect(result.roleIDs.count == 1)
            #expect(result.id == baseUser.id)
            #expect(result.name == baseUser.name)
        }

        // Original user is unchanged
        #expect(baseUser.roleIDs.isEmpty)
    }

    @Test("Concurrent Role modifications with permissions")
    func testConcurrentRoleModifications() async throws {
        let baseRole = try Role(
            name: "Test Role",
            level: .teacher
        )

        let results = await withTaskGroup(of: Role.self, returning: [Role].self) { group in
            for _ in 0..<100 {
                let permissionID = UUID()
                group.addTask {
                    baseRole.addPermission(permissionID)
                }
            }

            var results: [Role] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        #expect(results.count == 100)

        // Each result has exactly 1 permission (isolated copies)
        for result in results {
            #expect(result.permissionIDs.count == 1)
        }

        // Original unchanged
        #expect(baseRole.permissionIDs.isEmpty)
    }

    @Test("Concurrent Document state transitions")
    func testConcurrentDocumentTransitions() async throws {
        let ownerID = UUID()

        // Create multiple documents concurrently
        let documents = await withTaskGroup(of: Document.self, returning: [Document].self) { group in
            for i in 0..<50 {
                group.addTask {
                    // swiftlint:disable:next force_try
                    let doc = try! Document(
                        title: "Document \(i)",
                        content: "Content for document \(i)",
                        type: .lesson,
                        ownerID: ownerID
                    )
                    return doc
                }
            }

            var results: [Document] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        #expect(documents.count == 50)

        // Now publish all documents concurrently
        let published = await withTaskGroup(of: Document?.self, returning: [Document].self) { group in
            for doc in documents {
                group.addTask {
                    try? doc.publish()
                }
            }

            var results: [Document] = []
            for await result in group {
                if let doc = result {
                    results.append(doc)
                }
            }
            return results
        }

        #expect(published.count == 50)

        // All should be in published state
        for doc in published {
            #expect(doc.state == .published)
        }
    }

    // MARK: - Complex Graph Navigation

    @Test("Concurrent navigation of User-Role-Permission graph")
    func testConcurrentGraphNavigation() async throws {
        // Build a graph: 10 users, each with 5 roles, each role with 3 permissions
        var permissions: [Permission] = []
        for resource in Resource.allCases.prefix(3) {
            for action in Action.allCases.prefix(3) {
                permissions.append(Permission.create(resource: resource, action: action))
            }
        }

        let roles: [Role] = try (0..<5).map { i in
            var role = try Role(name: "Role \(i)", level: RoleLevel.allCases[i % 3])
            for perm in permissions.prefix(3) {
                role = role.addPermission(perm.id)
            }
            return role
        }

        let users: [User] = try (0..<10).map { i in
            var user = try User(name: "User \(i)", email: "user\(i)@edugo.com")
            for role in roles {
                user = user.addRole(role.id)
            }
            return user
        }

        // Concurrently navigate the graph from all users
        let rolesCopy = roles // Capture immutable copy
        let navigationResults = await withTaskGroup(
            of: (userID: UUID, roleCount: Int, hasAllRoles: Bool).self,
            returning: [(userID: UUID, roleCount: Int, hasAllRoles: Bool)].self
        ) { group in
            for user in users {
                group.addTask {
                    let roleCount = user.roleIDs.count
                    let hasAllRoles = rolesCopy.allSatisfy { user.hasRole($0.id) }
                    return (user.id, roleCount, hasAllRoles)
                }
            }

            var results: [(userID: UUID, roleCount: Int, hasAllRoles: Bool)] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        #expect(navigationResults.count == 10)

        for result in navigationResults {
            #expect(result.roleCount == 5)
            #expect(result.hasAllRoles == true)
        }
    }

    // MARK: - Pipeline Simulation

    @Test("Document lifecycle pipeline simulation")
    func testDocumentLifecyclePipeline() async throws {
        let ownerID = UUID()
        let collaboratorIDs = (0..<3).map { _ in UUID() }

        // Pipeline: Create -> Add Collaborators -> Publish -> Archive
        // Run 20 documents through the pipeline concurrently
        let finalDocuments = await withTaskGroup(of: Document?.self, returning: [Document].self) { group in
            for i in 0..<20 {
                group.addTask {
                    // Step 1: Create
                    guard let doc = try? Document(
                        title: "Pipeline Doc \(i)",
                        content: "Content for pipeline document \(i)",
                        type: .assignment,
                        ownerID: ownerID
                    ) else { return nil }

                    // Step 2: Add collaborators
                    var withCollabs = doc
                    for collabID in collaboratorIDs {
                        withCollabs = withCollabs.addCollaborator(collabID)
                    }

                    // Step 3: Publish
                    guard let published = try? withCollabs.publish() else { return nil }

                    // Step 4: Archive
                    guard let archived = try? published.archive() else { return nil }

                    return archived
                }
            }

            var results: [Document] = []
            for await result in group {
                if let doc = result {
                    results.append(doc)
                }
            }
            return results
        }

        #expect(finalDocuments.count == 20)

        for doc in finalDocuments {
            #expect(doc.state == .archived)
            #expect(doc.collaboratorIDs.count == 3)
            #expect(doc.ownerID == ownerID)
            #expect(doc.metadata.version >= 3) // At least 3 state changes
        }
    }

    // MARK: - Sendable Verification

    @Test("Entities can be captured in Tasks without issues")
    func testSendableCaptureInTasks() async throws {
        let user = try User(name: "Sendable Test", email: "sendable@test.com")
        let role = try Role(name: "Sendable Role", level: .admin)
        let permission = Permission.create(resource: .users, action: .read)
        let document = try Document(
            title: "Sendable Doc",
            content: "Content",
            type: .lesson,
            ownerID: user.id
        )

        // All entities should be capturable in concurrent tasks
        async let userTask = Task { user.name }.value
        async let roleTask = Task { role.level }.value
        async let permissionTask = Task { permission.code }.value
        async let documentTask = Task { document.state }.value

        let results = await (userTask, roleTask, permissionTask, documentTask)

        #expect(results.0 == "Sendable Test")
        #expect(results.1 == .admin)
        #expect(results.2 == "users.read")
        #expect(results.3 == .draft)
    }

    @Test("Entities maintain identity across task boundaries")
    func testEntityIdentityAcrossTasks() async throws {
        let originalID = UUID()
        let user = try User(
            id: originalID,
            name: "Identity Test",
            email: "identity@test.com"
        )

        // Pass to multiple tasks and verify identity preserved
        let ids = await withTaskGroup(of: UUID.self, returning: [UUID].self) { group in
            for _ in 0..<50 {
                group.addTask {
                    user.id
                }
            }

            var results: [UUID] = []
            for await id in group {
                results.append(id)
            }
            return results
        }

        #expect(ids.count == 50)
        #expect(ids.allSatisfy { $0 == originalID })
    }
}
