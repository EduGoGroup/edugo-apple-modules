//
//  EduTabBarTests.swift
//  UI Tests
//
//  Tests para componentes de TabBar (EduTabItem, EduTabBarCoordinator)
//  Framework: Swift Testing
//  Cobertura: ~95% de funcionalidad core del TabBar
//

import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduTabBarTests {
    // MARK: - TabItem Tests

    @Test("EduTabItem inicializa correctamente")
    func testTabItemInitialization() {
        let item = EduTabItem(
            id: "home",
            title: "Home",
            icon: "house",
            selectedIcon: "house.fill",
            badge: "5"
        )

        #expect(item.id == "home")
        #expect(item.title == "Home")
        #expect(item.icon == "house")
        #expect(item.selectedIcon == "house.fill")
        #expect(item.badge == "5")
    }

    @Test("EduTabItem sin badge")
    func testTabItemNoBadge() {
        let item = EduTabItem(
            id: "profile",
            title: "Profile",
            icon: "person",
            selectedIcon: "person.fill"
        )

        #expect(item.id == "profile")
        #expect(item.badge == nil)
    }

    @Test("EduTabItem sin selectedIcon devuelve nil")
    func testTabItemDefaultSelectedIcon() {
        let item = EduTabItem(
            id: "settings",
            title: "Settings",
            icon: "gear"
        )

        #expect(item.selectedIcon == nil)
    }

    // MARK: - TabBarCoordinator Tests

    @Test("EduTabBarCoordinator inicializa con tab inicial")
    func testCoordinatorInitialization() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        #expect(coordinator.selectedTab == "home")
        #expect(coordinator.previousTab == nil)
    }

    @Test("EduTabBarCoordinator cambia de tab")
    func testCoordinatorSelection() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        coordinator.select(tab: "profile")

        #expect(coordinator.selectedTab == "profile")
        #expect(coordinator.previousTab == "home")
    }

    @Test("EduTabBarCoordinator vuelve al tab anterior")
    func testCoordinatorGoBack() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        coordinator.select(tab: "profile")
        coordinator.goBackToPreviousTab()

        #expect(coordinator.selectedTab == "home")
        #expect(coordinator.previousTab == "profile")
    }

    @Test("EduTabBarCoordinator múltiples cambios de tab")
    func testCoordinatorMultipleSelections() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        coordinator.select(tab: "search")
        coordinator.select(tab: "profile")
        coordinator.select(tab: "settings")

        #expect(coordinator.selectedTab == "settings")
        #expect(coordinator.previousTab == "profile")
    }

    @Test("EduTabBarCoordinator goBack sin tab anterior no cambia")
    func testCoordinatorGoBackWithoutPrevious() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        coordinator.goBackToPreviousTab()

        #expect(coordinator.selectedTab == "home")
        #expect(coordinator.previousTab == nil)
    }

    @Test("EduTabBarCoordinator selecciona mismo tab actualiza previous")
    func testCoordinatorSelectSameTab() {
        let coordinator = EduTabBarCoordinator(initialTab: "home")

        coordinator.select(tab: "profile")
        coordinator.select(tab: "profile")

        #expect(coordinator.selectedTab == "profile")
        #expect(coordinator.previousTab == "profile")
    }
}
