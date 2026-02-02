import XCTest
import SwiftUI
@testable import UI

@MainActor
final class EduNavigationTests: XCTestCase {

    // MARK: - TabBar Tests

    func testTabItemInitialization() {
        let item = EduTabItem(
            id: "home",
            title: "Home",
            icon: "house",
            selectedIcon: "house.fill",
            badge: "5"
        )

        XCTAssertEqual(item.id, "home")
        XCTAssertEqual(item.title, "Home")
        XCTAssertEqual(item.icon, "house")
        XCTAssertEqual(item.selectedIcon, "house.fill")
        XCTAssertEqual(item.badge, "5")
    }

    func testTabBarCoordinatorInitialization() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        XCTAssertEqual(coordinator.selectedTab, "home")
        XCTAssertNil(coordinator.previousTab)
    }

    func testTabBarCoordinatorSelection() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        coordinator.select(tab: "profile")

        XCTAssertEqual(coordinator.selectedTab, "profile")
        XCTAssertEqual(coordinator.previousTab, "home")
    }

    func testTabBarCoordinatorGoBack() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        coordinator.select(tab: "profile")
        coordinator.goBackToPreviousTab()

        XCTAssertEqual(coordinator.selectedTab, "home")
        XCTAssertEqual(coordinator.previousTab, "profile")
    }

    // MARK: - NavigationBar Tests

    func testNavigationBarItemInitialization() {
        final class ActionTracker: @unchecked Sendable {
            var called = false
        }

        let tracker = ActionTracker()
        let item = EduNavigationBarItem(
            title: "Done",
            icon: "checkmark",
            action: { tracker.called = true }
        )

        XCTAssertEqual(item.title, "Done")
        XCTAssertEqual(item.icon, "checkmark")

        item.action()
        XCTAssertTrue(tracker.called)
    }

    func testNavigationBarConfiguration() {
        let config = EduNavigationBarConfiguration(
            displayMode: .large,
            showsBackButton: true,
            showsLeadingButton: false,
            showsTrailingButton: true
        )

        XCTAssertEqual(config.displayMode, .large)
        XCTAssertTrue(config.showsBackButton)
        XCTAssertFalse(config.showsLeadingButton)
        XCTAssertTrue(config.showsTrailingButton)
    }

    func testNavigationCoordinatorInitialization() {
        let coordinator = EduNavigationCoordinator()

        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertEqual(coordinator.currentTitle, "")
    }

    func testNavigationCoordinatorPush() {
        let coordinator = EduNavigationCoordinator()

        coordinator.push("detail", title: "Detail View")

        XCTAssertEqual(coordinator.path.count, 1)
        XCTAssertEqual(coordinator.path.first, "detail")
        XCTAssertEqual(coordinator.currentTitle, "Detail View")
    }

    func testNavigationCoordinatorPop() {
        let coordinator = EduNavigationCoordinator()

        coordinator.push("detail", title: "Detail View")
        coordinator.push("settings", title: "Settings")
        coordinator.pop()

        XCTAssertEqual(coordinator.path.count, 1)
        XCTAssertEqual(coordinator.path.first, "detail")
    }

    func testNavigationCoordinatorPopToRoot() {
        let coordinator = EduNavigationCoordinator()

        coordinator.push("detail", title: "Detail")
        coordinator.push("settings", title: "Settings")
        coordinator.popToRoot()

        XCTAssertTrue(coordinator.path.isEmpty)
        XCTAssertEqual(coordinator.currentTitle, "")
    }

    func testNavigationCoordinatorNavigate() {
        let coordinator = EduNavigationCoordinator()

        coordinator.navigate(to: ["home", "profile", "settings"])

        XCTAssertEqual(coordinator.path.count, 3)
        XCTAssertEqual(coordinator.currentTitle, "settings")
    }

    // MARK: - Breadcrumbs Tests

    func testBreadcrumbItemInitialization() {
        let item = EduBreadcrumbItem(
            id: "home",
            title: "Home",
            icon: "house",
            destination: "/home"
        )

        XCTAssertEqual(item.id, "home")
        XCTAssertEqual(item.title, "Home")
        XCTAssertEqual(item.icon, "house")
        XCTAssertEqual(item.destination, "/home")
    }

    func testBreadcrumbBuilderAdd() {
        var builder = EduBreadcrumbBuilder()

        builder.add(id: "home", title: "Home", icon: "house", destination: "/home")
        builder.add(id: "profile", title: "Profile", icon: "person", destination: "/profile")

        let items = builder.build()

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items[0].title, "Home")
        XCTAssertEqual(items[1].title, "Profile")
    }

    func testBreadcrumbBuilderFromPath() {
        let titles = [
            "home": "Home",
            "profile": "Profile",
            "settings": "Settings"
        ]
        let icons = [
            "home": "house",
            "profile": "person"
        ]

        let items = EduBreadcrumbBuilder.fromPath(
            ["home", "profile", "settings"],
            titles: titles,
            icons: icons
        )

        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(items[0].title, "Home")
        XCTAssertEqual(items[0].icon, "house")
        XCTAssertEqual(items[1].title, "Profile")
        XCTAssertEqual(items[2].title, "Settings")
        XCTAssertNil(items[2].destination)
    }

    func testBreadcrumbCoordinatorUpdate() {
        let coordinator = EduBreadcrumbCoordinator()
        let titles = ["home": "Home", "profile": "Profile"]

        coordinator.update(path: ["home", "profile"], titles: titles)

        XCTAssertEqual(coordinator.items.count, 2)
        XCTAssertEqual(coordinator.items[0].title, "Home")
        XCTAssertEqual(coordinator.items[1].title, "Profile")
    }

    func testBreadcrumbCoordinatorPush() {
        let coordinator = EduBreadcrumbCoordinator()

        coordinator.push(id: "home", title: "Home", destination: "/home")
        coordinator.push(id: "profile", title: "Profile", destination: nil)

        XCTAssertEqual(coordinator.items.count, 2)
        XCTAssertEqual(coordinator.items[0].destination, "/home")
        XCTAssertNil(coordinator.items[1].destination)
    }

    func testBreadcrumbCoordinatorPop() {
        let coordinator = EduBreadcrumbCoordinator()

        coordinator.push(id: "home", title: "Home", destination: "/home")
        coordinator.push(id: "profile", title: "Profile", destination: nil)
        coordinator.pop()

        XCTAssertEqual(coordinator.items.count, 1)
    }

    func testBreadcrumbCoordinatorClear() {
        let coordinator = EduBreadcrumbCoordinator()

        coordinator.push(id: "home", title: "Home", destination: "/home")
        coordinator.clear()

        XCTAssertTrue(coordinator.items.isEmpty)
    }

    // MARK: - NavigationRouter Tests

    func testNavigationRouterInitialization() {
        let router = EduNavigationRouter()

        XCTAssertTrue(router.path.isEmpty)
    }

    func testNavigationRouterNavigate() {
        let router = EduNavigationRouter()

        router.navigate(to: .detail(id: "123"))

        XCTAssertEqual(router.path.count, 1)
    }

    func testNavigationRouterGoBack() {
        let router = EduNavigationRouter()

        router.navigate(to: .settings)
        router.navigate(to: .profile)
        router.goBack()

        XCTAssertEqual(router.path.count, 1)
    }

    func testNavigationRouterGoToRoot() {
        let router = EduNavigationRouter()

        router.navigate(to: .settings)
        router.navigate(to: .profile)
        router.goToRoot()

        XCTAssertTrue(router.path.isEmpty)
    }

    func testNavigationRouterNavigateToRoute() {
        let router = EduNavigationRouter()

        router.navigate(to: [.settings, .profile, .detail(id: "123")])

        XCTAssertEqual(router.path.count, 3)
    }

    func testNavigationRouterDestinationEquality() {
        let dest1 = EduNavigationRouter.Destination.detail(id: "123")
        let dest2 = EduNavigationRouter.Destination.detail(id: "123")
        let dest3 = EduNavigationRouter.Destination.detail(id: "456")

        XCTAssertEqual(dest1, dest2)
        XCTAssertNotEqual(dest1, dest3)
    }
}
