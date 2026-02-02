import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduNavigationBarTests {
    // MARK: - NavigationBarItem Tests

    @Test("EduNavigationBarItem inicializa correctamente")
    func testBarItemInitialization() {
        let item = EduNavigationBarItem(
            title: "Done",
            icon: "checkmark",
            action: {}
        )

        #expect(item.title == "Done")
        #expect(item.icon == "checkmark")
    }

    @Test("EduNavigationBarItem sin icono")
    func testBarItemNoIcon() {
        let item = EduNavigationBarItem(
            title: "Save",
            action: {}
        )

        #expect(item.title == "Save")
        #expect(item.icon == nil)
    }

    @Test("EduNavigationBarItem solo con icono")
    func testBarItemIconOnly() {
        let item = EduNavigationBarItem(
            icon: "plus",
            action: {}
        )

        #expect(item.title == nil)
        #expect(item.icon == "plus")
    }

    // MARK: - NavigationBarConfiguration Tests

    @Test("EduNavigationBarConfiguration inicializa con valores por defecto")
    func testConfigurationDefaults() {
        let config = EduNavigationBarConfiguration()

        #expect(config.displayMode == .automatic)
        #expect(config.showsBackButton == true)
    }

    @Test("EduNavigationBarConfiguration con display mode large")
    func testConfigurationLargeMode() {
        let config = EduNavigationBarConfiguration(
            displayMode: .large,
            showsBackButton: true,
            showsLeadingButton: false,
            showsTrailingButton: true
        )

        #expect(config.displayMode == .large)
        #expect(config.showsBackButton == true)
        #expect(config.showsLeadingButton == false)
        #expect(config.showsTrailingButton == true)
    }

    @Test("EduNavigationBarConfiguration con display mode inline")
    func testConfigurationInlineMode() {
        let config = EduNavigationBarConfiguration(
            displayMode: .inline
        )

        #expect(config.displayMode == .inline)
    }

    @Test("EduNavigationBarConfiguration sin botones")
    func testConfigurationNoButtons() {
        let config = EduNavigationBarConfiguration(
            showsBackButton: false,
            showsLeadingButton: false,
            showsTrailingButton: false
        )

        #expect(config.showsBackButton == false)
        #expect(config.showsLeadingButton == false)
        #expect(config.showsTrailingButton == false)
    }

    // MARK: - NavigationCoordinator Tests

    @Test("EduNavigationCoordinator inicializa vacío")
    func testCoordinatorInitialization() {
        let coordinator = EduNavigationCoordinator()

        #expect(coordinator.path.isEmpty)
        #expect(coordinator.currentTitle == "")
    }

    @Test("EduNavigationCoordinator push agrega ruta")
    func testCoordinatorPush() {
        let coordinator = EduNavigationCoordinator()

        coordinator.push("detail", title: "Detail View")

        #expect(coordinator.path.count == 1)
        #expect(coordinator.path.first == "detail")
        #expect(coordinator.currentTitle == "Detail View")
    }

    @Test("EduNavigationCoordinator pop remueve última ruta")
    func testCoordinatorPop() {
        let coordinator = EduNavigationCoordinator()

        coordinator.push("detail", title: "Detail View")
        coordinator.push("settings", title: "Settings")
        coordinator.pop()

        #expect(coordinator.path.count == 1)
        #expect(coordinator.path.first == "detail")
    }

    @Test("EduNavigationCoordinator popToRoot limpia path")
    func testCoordinatorPopToRoot() {
        let coordinator = EduNavigationCoordinator()

        coordinator.push("detail", title: "Detail")
        coordinator.push("settings", title: "Settings")
        coordinator.push("profile", title: "Profile")
        coordinator.popToRoot()

        #expect(coordinator.path.isEmpty)
        #expect(coordinator.currentTitle == "")
    }

    @Test("EduNavigationCoordinator navigate a ruta específica")
    func testCoordinatorNavigate() {
        let coordinator = EduNavigationCoordinator()

        coordinator.navigate(to: ["home", "profile", "settings"])

        #expect(coordinator.path.count == 3)
        #expect(coordinator.currentTitle == "settings")
    }

    @Test("EduNavigationCoordinator pop en path vacío no crashea")
    func testCoordinatorPopEmpty() {
        let coordinator = EduNavigationCoordinator()

        coordinator.pop()

        #expect(coordinator.path.isEmpty)
    }

    @Test("EduNavigationCoordinator múltiples push")
    func testCoordinatorMultiplePush() {
        let coordinator = EduNavigationCoordinator()

        coordinator.push("one", title: "One")
        coordinator.push("two", title: "Two")
        coordinator.push("three", title: "Three")

        #expect(coordinator.path.count == 3)
        #expect(coordinator.path == ["one", "two", "three"])
    }
}
