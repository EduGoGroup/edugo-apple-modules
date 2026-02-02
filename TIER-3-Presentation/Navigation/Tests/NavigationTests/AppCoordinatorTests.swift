import XCTest
@testable import Navigation
import CQRS
import Models

/// Tests unitarios para AppCoordinator.
///
/// Valida:
/// - Navegación básica (push, pop, popToRoot)
/// - Presentación de modales (sheets, fullScreenCovers)
/// - Integración con EventBus para navegación automática
/// - Manejo de estado de autenticación
@MainActor
final class AppCoordinatorTests: XCTestCase {

    // MARK: - Properties

    var sut: AppCoordinator!
    var mediator: Mediator!
    var eventBus: EventBus!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mediator = Mediator()
        eventBus = EventBus()
        sut = AppCoordinator(mediator: mediator, eventBus: eventBus)
    }

    override func tearDown() async throws {
        await sut.cleanup()
        sut = nil
        mediator = nil
        eventBus = nil
        try await super.tearDown()
    }

    // MARK: - Navigation Tests

    func testNavigateAddsToPath() {
        // Act
        sut.navigate(to: .dashboard)

        // Assert
        XCTAssertEqual(sut.navigationPath.count, 1)
        XCTAssertEqual(sut.currentScreen, .dashboard)
    }

    func testGoBackRemovesFromPath() {
        // Arrange
        sut.navigate(to: .dashboard)
        sut.navigate(to: .materialList)
        XCTAssertEqual(sut.navigationPath.count, 2)

        // Act
        sut.goBack()

        // Assert
        XCTAssertEqual(sut.navigationPath.count, 1)
    }

    func testGoBackDoesNothingWhenPathIsEmpty() {
        // Arrange
        XCTAssertEqual(sut.navigationPath.count, 0)

        // Act
        sut.goBack()

        // Assert
        XCTAssertEqual(sut.navigationPath.count, 0)
    }

    func testPopToRootClearsPath() {
        // Arrange
        sut.isAuthenticated = true
        sut.navigate(to: .dashboard)
        sut.navigate(to: .materialList)
        sut.navigate(to: .userProfile)
        XCTAssertEqual(sut.navigationPath.count, 3)

        // Act
        sut.popToRoot()

        // Assert
        XCTAssertEqual(sut.navigationPath.count, 0)
        XCTAssertEqual(sut.currentScreen, .dashboard)
    }

    func testPopToRootWhenNotAuthenticatedShowsLogin() {
        // Arrange
        sut.isAuthenticated = false
        sut.navigate(to: .dashboard)

        // Act
        sut.popToRoot()

        // Assert
        XCTAssertEqual(sut.currentScreen, .login)
    }

    func testCanGoBackReturnsTrueWhenPathNotEmpty() {
        // Arrange
        sut.navigate(to: .dashboard)

        // Act & Assert
        XCTAssertTrue(sut.canGoBack)
    }

    func testCanGoBackReturnsFalseWhenPathIsEmpty() {
        // Act & Assert
        XCTAssertFalse(sut.canGoBack)
    }

    // MARK: - Modal Presentation Tests

    func testPresentSheetSetsSheet() {
        // Act
        sut.presentSheet(.materialUpload)

        // Assert
        XCTAssertEqual(sut.presentedSheet, .materialUpload)
        XCTAssertNil(sut.presentedFullScreenCover)
    }

    func testPresentFullScreenCoverSetsCover() {
        // Act
        sut.presentFullScreenCover(.userProfile)

        // Assert
        XCTAssertEqual(sut.presentedFullScreenCover, .userProfile)
        XCTAssertNil(sut.presentedSheet)
    }

    func testDismissModalClearsSheet() {
        // Arrange
        sut.presentSheet(.materialUpload)
        XCTAssertNotNil(sut.presentedSheet)

        // Act
        sut.dismissModal()

        // Assert
        XCTAssertNil(sut.presentedSheet)
    }

    func testDismissModalClearsFullScreenCover() {
        // Arrange
        sut.presentFullScreenCover(.userProfile)
        XCTAssertNotNil(sut.presentedFullScreenCover)

        // Act
        sut.dismissModal()

        // Assert
        XCTAssertNil(sut.presentedFullScreenCover)
    }

    func testIsModalPresentedReturnsTrueWhenSheetPresented() {
        // Arrange
        sut.presentSheet(.materialUpload)

        // Act & Assert
        XCTAssertTrue(sut.isModalPresented)
    }

    func testIsModalPresentedReturnsTrueWhenFullScreenCoverPresented() {
        // Arrange
        sut.presentFullScreenCover(.userProfile)

        // Act & Assert
        XCTAssertTrue(sut.isModalPresented)
    }

    func testIsModalPresentedReturnsFalseWhenNoModalPresented() {
        // Act & Assert
        XCTAssertFalse(sut.isModalPresented)
    }

    // MARK: - Reset Navigation Tests

    func testResetNavigationClearsAllState() {
        // Arrange
        sut.isAuthenticated = true
        sut.currentUserId = UUID()
        sut.navigate(to: .dashboard)
        sut.presentSheet(.materialUpload)

        // Act
        sut.resetNavigation()

        // Assert
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUserId)
        XCTAssertEqual(sut.navigationPath.count, 0)
        XCTAssertNil(sut.presentedSheet)
        XCTAssertNil(sut.presentedFullScreenCover)
        XCTAssertEqual(sut.currentScreen, .login)
    }

    // MARK: - EventBus Integration Tests

    func testLoginSuccessEventNavigatesToDashboard() async throws {
        // Arrange
        let userId = UUID()
        let event = LoginSuccessEvent(userId: userId, email: "test@edugo.com")

        // Act
        await eventBus.publish(event)

        // Esperar a que se procese el evento
        try await Task.sleep(for: .milliseconds(100))

        // Assert
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertEqual(sut.currentUserId, userId)
        XCTAssertEqual(sut.currentScreen, .dashboard)
    }

    func testMaterialUploadedEventNavigatesToMaterialList() async throws {
        // Arrange
        let event = MaterialUploadedEvent(
            materialId: UUID(),
            title: "Test Material",
            fileName: "test.pdf",
            subjectId: UUID(),
            unitId: UUID()
        )
        sut.presentSheet(.materialUpload)
        XCTAssertNotNil(sut.presentedSheet)

        // Act
        await eventBus.publish(event)
        try await Task.sleep(for: .milliseconds(100))

        // Assert
        XCTAssertNil(sut.presentedSheet)
        XCTAssertEqual(sut.currentScreen, .materialList)
    }

    func testAssessmentSubmittedEventNavigatesToResults() async throws {
        // Arrange
        let assessmentId = UUID()
        let event = AssessmentSubmittedEvent(
            attemptId: UUID(),
            assessmentId: assessmentId,
            userId: UUID(),
            score: 80,
            maxScore: 100,
            passed: true,
            percentage: 80.0,
            timeSpentSeconds: 300
        )

        // Act
        await eventBus.publish(event)
        try await Task.sleep(for: .milliseconds(100))

        // Assert
        XCTAssertEqual(sut.currentScreen, .assessmentResults(assessmentId: assessmentId))
    }

    // MARK: - Screen Tests

    func testScreenIdReturnsCorrectIdentifier() {
        // Test basic screens
        XCTAssertEqual(Screen.login.id, "login")
        XCTAssertEqual(Screen.dashboard.id, "dashboard")
        XCTAssertEqual(Screen.materialList.id, "materialList")

        // Test screens with parameters
        let materialId = UUID()
        XCTAssertEqual(
            Screen.materialDetail(materialId: materialId).id,
            "materialDetail-\(materialId)"
        )

        let assessmentId = UUID()
        XCTAssertEqual(
            Screen.assessment(assessmentId: assessmentId, userId: UUID()).id,
            "assessment-\(assessmentId)"
        )
    }
}
