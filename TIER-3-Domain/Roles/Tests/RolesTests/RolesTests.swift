import Testing
import Foundation
@testable import Roles

@Suite("Roles Tests")
struct RolesTests {
    @Test("RolesManager shared instance is accessible")
    func testSharedInstance() {
        let roles = RolesManager.shared
        // Roles should be accessible
    }

    @Test("Student role has correct permissions")
    func testStudentPermissions() async {
        let roles = RolesManager.shared
        await roles.setRole(.student)

        let hasViewCourses = await roles.hasPermission("view_courses")
        let hasManageUsers = await roles.hasPermission("manage_users")

        #expect(hasViewCourses == true)
        #expect(hasManageUsers == false)
    }

    @Test("Admin role has elevated permissions")
    func testAdminPermissions() async {
        let roles = RolesManager.shared
        await roles.setRole(.admin)

        let hasManageUsers = await roles.hasPermission("manage_users")
        let hasViewAnalytics = await roles.hasPermission("view_analytics")

        #expect(hasManageUsers == true)
        #expect(hasViewAnalytics == true)
    }
}
