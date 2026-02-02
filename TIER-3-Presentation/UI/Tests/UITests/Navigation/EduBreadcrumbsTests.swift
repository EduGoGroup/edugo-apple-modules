import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduBreadcrumbsTests {
    // MARK: - BreadcrumbItem Tests

    @Test("EduBreadcrumbItem inicializa correctamente")
    func testBreadcrumbItemInitialization() {
        let item = EduBreadcrumbItem(
            id: "home",
            title: "Home",
            icon: "house",
            destination: "/home"
        )

        #expect(item.id == "home")
        #expect(item.title == "Home")
        #expect(item.icon == "house")
        #expect(item.destination == "/home")
    }

    @Test("EduBreadcrumbItem sin icono")
    func testBreadcrumbItemNoIcon() {
        let item = EduBreadcrumbItem(
            id: "profile",
            title: "Profile",
            destination: "/profile"
        )

        #expect(item.icon == nil)
    }

    @Test("EduBreadcrumbItem sin destination (último item)")
    func testBreadcrumbItemNoDestination() {
        let item = EduBreadcrumbItem(
            id: "current",
            title: "Current Page",
            icon: "doc"
        )

        #expect(item.destination == nil)
    }

    // MARK: - BreadcrumbBuilder Tests

    @Test("EduBreadcrumbBuilder agrega items")
    func testBuilderAdd() {
        var builder = EduBreadcrumbBuilder()

        builder.add(id: "home", title: "Home", icon: "house", destination: "/home")
        builder.add(id: "profile", title: "Profile", icon: "person", destination: "/profile")

        let items = builder.build()

        #expect(items.count == 2)
        #expect(items[0].title == "Home")
        #expect(items[1].title == "Profile")
    }

    @Test("EduBreadcrumbBuilder desde path")
    func testBuilderFromPath() {
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

        #expect(items.count == 3)
        #expect(items[0].title == "Home")
        #expect(items[0].icon == "house")
        #expect(items[1].title == "Profile")
        #expect(items[1].icon == "person")
        #expect(items[2].title == "Settings")
        #expect(items[2].icon == nil)
    }

    @Test("EduBreadcrumbBuilder último item sin destination")
    func testBuilderLastItemNoDestination() {
        let titles = ["home": "Home", "current": "Current"]
        let items = EduBreadcrumbBuilder.fromPath(
            ["home", "current"],
            titles: titles
        )

        #expect(items[0].destination != nil)
        #expect(items[1].destination == nil)
    }

    @Test("EduBreadcrumbBuilder path vacío")
    func testBuilderEmptyPath() {
        let items = EduBreadcrumbBuilder.fromPath([], titles: [:])

        #expect(items.isEmpty)
    }

    // MARK: - BreadcrumbCoordinator Tests

    @Test("EduBreadcrumbCoordinator inicializa vacío")
    func testCoordinatorInitialization() {
        let coordinator = EduBreadcrumbCoordinator()

        #expect(coordinator.items.isEmpty)
    }

    @Test("EduBreadcrumbCoordinator actualiza desde path")
    func testCoordinatorUpdate() {
        let coordinator = EduBreadcrumbCoordinator()
        let titles = ["home": "Home", "profile": "Profile"]

        coordinator.update(path: ["home", "profile"], titles: titles)

        #expect(coordinator.items.count == 2)
        #expect(coordinator.items[0].title == "Home")
        #expect(coordinator.items[1].title == "Profile")
    }

    @Test("EduBreadcrumbCoordinator push agrega item")
    func testCoordinatorPush() {
        let coordinator = EduBreadcrumbCoordinator()

        coordinator.push(id: "home", title: "Home", destination: "/home")
        coordinator.push(id: "profile", title: "Profile", destination: nil)

        #expect(coordinator.items.count == 2)
        #expect(coordinator.items[0].destination == "/home")
        #expect(coordinator.items[1].destination == nil)
    }

    @Test("EduBreadcrumbCoordinator pop remueve último item")
    func testCoordinatorPop() {
        let coordinator = EduBreadcrumbCoordinator()

        coordinator.push(id: "home", title: "Home", destination: "/home")
        coordinator.push(id: "profile", title: "Profile", destination: nil)
        coordinator.pop()

        #expect(coordinator.items.count == 1)
        #expect(coordinator.items[0].title == "Home")
    }

    @Test("EduBreadcrumbCoordinator clear limpia todos los items")
    func testCoordinatorClear() {
        let coordinator = EduBreadcrumbCoordinator()

        coordinator.push(id: "home", title: "Home", destination: "/home")
        coordinator.push(id: "profile", title: "Profile", destination: "/profile")
        coordinator.clear()

        #expect(coordinator.items.isEmpty)
    }

    @Test("EduBreadcrumbCoordinator pop en lista vacía no crashea")
    func testCoordinatorPopEmpty() {
        let coordinator = EduBreadcrumbCoordinator()

        coordinator.pop()

        #expect(coordinator.items.isEmpty)
    }

    @Test("EduBreadcrumbCoordinator múltiples updates")
    func testCoordinatorMultipleUpdates() {
        let coordinator = EduBreadcrumbCoordinator()
        let titles = ["home": "Home", "profile": "Profile"]

        coordinator.update(path: ["home"], titles: titles)
        #expect(coordinator.items.count == 1)

        coordinator.update(path: ["home", "profile"], titles: titles)
        #expect(coordinator.items.count == 2)
    }
}
