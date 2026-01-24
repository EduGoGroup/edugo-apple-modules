import Testing
import Foundation
@testable import Models

@Suite("Models Tests")
struct ModelsTests {
    @Test("User model creation")
    func testUserCreation() {
        let user = User(
            id: UUID(),
            email: "test@edugo.com",
            name: "Test User"
        )

        #expect(user.email == "test@edugo.com")
        #expect(user.name == "Test User")
    }
}
