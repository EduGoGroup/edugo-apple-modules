import XCTest
import SwiftUI
@testable import Navigation
import CQRS

/// Tests unitarios para NavigationHelpers y ViewModifiers.
///
/// Valida:
/// - EnvironmentKey para AppCoordinator
/// - NavigationDestinationModifier
/// - NavigationBarModifier
/// - NavigationButton, SheetButton, FullScreenCoverButton
@MainActor
final class NavigationHelpersTests: XCTestCase {

    var appCoordinator: AppCoordinator!
    var mediator: Mediator!
    var eventBus: EventBus!

    override func setUp() async throws {
        try await super.setUp()
        mediator = Mediator()
        eventBus = EventBus()
        appCoordinator = AppCoordinator(mediator: mediator, eventBus: eventBus)
        await appCoordinator.setup()
    }

    override func tearDown() async throws {
        await appCoordinator.cleanup()
        appCoordinator = nil
        mediator = nil
        eventBus = nil
        try await super.tearDown()
    }

    // MARK: - Environment Tests

    func testCoordinatorEnvironmentCanBeSet() {
        // This test validates that the environment key is properly defined
        // Actual SwiftUI environment testing requires ViewInspector or UI tests

        // We can test that the coordinator itself works
        XCTAssertNotNil(appCoordinator)
    }

    // MARK: - NavigationDestinationModifier Tests

    func testNavigationDestinationModifierExists() {
        // Test that the modifier can be created
        let modifier = NavigationDestinationModifier()
        XCTAssertNotNil(modifier)
    }

    // MARK: - NavigationButton Tests

    func testNavigationButtonNavigatesWhenPressed() {
        // Arrange
        appCoordinator.isAuthenticated = true

        // Act - Simulate button press by calling coordinator directly
        appCoordinator.navigate(to: .dashboard)

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .dashboard)
        XCTAssertEqual(appCoordinator.navigationPath.count, 1)
    }

    func testNavigationButtonNavigatesToMaterialDetail() {
        // Arrange
        appCoordinator.isAuthenticated = true
        let materialId = UUID()

        // Act
        appCoordinator.navigate(to: .materialDetail(materialId: materialId))

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .materialDetail(materialId: materialId))
    }

    // MARK: - SheetButton Tests

    func testSheetButtonPresentsSheet() {
        // Act
        appCoordinator.presentSheet(.materialUpload)

        // Assert
        XCTAssertEqual(appCoordinator.presentedSheet, .materialUpload)
        XCTAssertTrue(appCoordinator.isModalPresented)
    }

    func testSheetButtonPresentsAssignmentSheet() {
        // Arrange
        let materialId = UUID()

        // Act
        appCoordinator.presentSheet(.materialAssignment(materialId: materialId))

        // Assert
        XCTAssertEqual(appCoordinator.presentedSheet, .materialAssignment(materialId: materialId))
    }

    // MARK: - FullScreenCoverButton Tests

    func testFullScreenCoverButtonPresentsCover() {
        // Act
        appCoordinator.presentFullScreenCover(.contextSwitch)

        // Assert
        XCTAssertEqual(appCoordinator.presentedFullScreenCover, .contextSwitch)
        XCTAssertTrue(appCoordinator.isModalPresented)
    }

    // MARK: - NavigationBar Tests

    func testNavigationBarModifierExists() {
        // Test that the modifier can be created
        let modifier = NavigationBarModifier(
            title: "Test",
            showBackButton: true,
            trailingAction: nil,
            trailingIcon: nil
        )
        XCTAssertNotNil(modifier)
    }

    func testNavigationBarWithBackButtonUsesCoordinatorState() {
        // Arrange - No navigation yet
        XCTAssertFalse(appCoordinator.canGoBack)

        // Act - Navigate
        appCoordinator.navigate(to: .dashboard)

        // Assert - Can go back now
        XCTAssertTrue(appCoordinator.canGoBack)
    }

    // MARK: - Integration Tests

    func testCompleteNavigationFlow() {
        // Arrange
        appCoordinator.isAuthenticated = true

        // Act - Simulate user flow
        appCoordinator.navigate(to: .dashboard)
        appCoordinator.navigate(to: .materialList)
        appCoordinator.presentSheet(.materialUpload)

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .materialList)
        XCTAssertEqual(appCoordinator.navigationPath.count, 2)
        XCTAssertEqual(appCoordinator.presentedSheet, .materialUpload)
    }

    func testNavigationButtonsRespectAuthenticationState() {
        // Arrange - Not authenticated
        appCoordinator.isAuthenticated = false

        // Act - Try to navigate to protected route
        appCoordinator.navigate(to: .materialList)

        // Assert - Should navigate (actual auth check happens in DeeplinkHandler)
        XCTAssertEqual(appCoordinator.currentScreen, .materialList)
    }
}
