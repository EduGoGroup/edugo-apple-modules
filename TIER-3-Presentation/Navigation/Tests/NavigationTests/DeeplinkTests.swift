import XCTest
@testable import Navigation
import CQRS

/// Tests unitarios para el sistema de deeplinks.
///
/// Valida:
/// - Deeplink: Conversión a paths y screens
/// - DeeplinkParser: Parsing de URLs
/// - DeeplinkHandler: Manejo de deeplinks y navegación
@MainActor
final class DeeplinkTests: XCTestCase {

    // MARK: - Deeplink Path Tests

    func testDashboardDeeplinkPath() {
        // Arrange
        let deeplink = Deeplink.dashboard

        // Act
        let path = deeplink.path

        // Assert
        XCTAssertEqual(path, "/dashboard")
    }

    func testMaterialListDeeplinkPath() {
        // Arrange
        let deeplink = Deeplink.materialList

        // Act
        let path = deeplink.path

        // Assert
        XCTAssertEqual(path, "/materials")
    }

    func testMaterialDetailDeeplinkPath() {
        // Arrange
        let materialId = UUID()
        let deeplink = Deeplink.materialDetail(materialId: materialId)

        // Act
        let path = deeplink.path

        // Assert
        XCTAssertEqual(path, "/materials/\(materialId.uuidString)")
    }

    func testAssessmentDeeplinkPath() {
        // Arrange
        let assessmentId = UUID()
        let userId = UUID()
        let deeplink = Deeplink.assessment(assessmentId: assessmentId, userId: userId)

        // Act
        let path = deeplink.path

        // Assert
        XCTAssertEqual(path, "/assessments/\(assessmentId.uuidString)?userId=\(userId.uuidString)")
    }

    func testAssessmentResultsDeeplinkPath() {
        // Arrange
        let assessmentId = UUID()
        let deeplink = Deeplink.assessmentResults(assessmentId: assessmentId)

        // Act
        let path = deeplink.path

        // Assert
        XCTAssertEqual(path, "/assessments/\(assessmentId.uuidString)/results")
    }

    // MARK: - Deeplink to Screen Conversion Tests

    func testDashboardDeeplinkToScreen() {
        // Arrange
        let deeplink = Deeplink.dashboard

        // Act
        let screen = deeplink.toScreen()

        // Assert
        XCTAssertEqual(screen, .dashboard)
    }

    func testMaterialDetailDeeplinkToScreen() {
        // Arrange
        let materialId = UUID()
        let deeplink = Deeplink.materialDetail(materialId: materialId)

        // Act
        let screen = deeplink.toScreen()

        // Assert
        XCTAssertEqual(screen, .materialDetail(materialId: materialId))
    }

    func testAssessmentDeeplinkToScreen() {
        // Arrange
        let assessmentId = UUID()
        let userId = UUID()
        let deeplink = Deeplink.assessment(assessmentId: assessmentId, userId: userId)

        // Act
        let screen = deeplink.toScreen()

        // Assert
        XCTAssertEqual(screen, .assessment(assessmentId: assessmentId, userId: userId))
    }
}

// MARK: - DeeplinkParser Tests

final class DeeplinkParserTests: XCTestCase {

    func testParseDashboardURL() {
        // Arrange
        let url = URL(string: "edugo://dashboard")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .dashboard)
    }

    func testParseMaterialListURL() {
        // Arrange
        let url = URL(string: "edugo://materials")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .materialList)
    }

    func testParseMaterialDetailURL() {
        // Arrange
        let materialId = UUID()
        let url = URL(string: "edugo://materials/\(materialId.uuidString)")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .materialDetail(materialId: materialId))
    }

    func testParseAssessmentURLWithQueryParams() {
        // Arrange
        let assessmentId = UUID()
        let userId = UUID()
        let url = URL(string: "edugo://assessments/\(assessmentId.uuidString)?userId=\(userId.uuidString)")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .assessment(assessmentId: assessmentId, userId: userId))
    }

    func testParseAssessmentResultsURL() {
        // Arrange
        let assessmentId = UUID()
        let url = URL(string: "edugo://assessments/\(assessmentId.uuidString)/results")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .assessmentResults(assessmentId: assessmentId))
    }

    func testParseUserProfileURL() {
        // Arrange
        let url = URL(string: "edugo://profile")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .userProfile)
    }

    func testParseLoginURL() {
        // Arrange
        let url = URL(string: "edugo://login")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .login)
    }

    func testParseInvalidURLReturnsNil() {
        // Arrange
        let url = URL(string: "edugo://invalid/route")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertNil(deeplink)
    }

    func testParseMalformedUUIDReturnsNil() {
        // Arrange
        let url = URL(string: "edugo://materials/not-a-uuid")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertNil(deeplink)
    }

    func testParseUniversalLink() {
        // Arrange
        let materialId = UUID()
        let url = URL(string: "https://edugo.app/materials/\(materialId.uuidString)")!

        // Act
        let deeplink = DeeplinkParser.parse(url)

        // Assert
        XCTAssertEqual(deeplink, .materialDetail(materialId: materialId))
    }
}

// MARK: - DeeplinkHandler Tests

@MainActor
final class DeeplinkHandlerTests: XCTestCase {

    var sut: DeeplinkHandler!
    var appCoordinator: AppCoordinator!
    var mediator: Mediator!
    var eventBus: EventBus!

    override func setUp() async throws {
        try await super.setUp()
        mediator = Mediator()
        eventBus = EventBus()
        appCoordinator = AppCoordinator(mediator: mediator, eventBus: eventBus)
        await appCoordinator.setup()
        sut = DeeplinkHandler(appCoordinator: appCoordinator)
    }

    override func tearDown() async throws {
        await appCoordinator.cleanup()
        sut = nil
        appCoordinator = nil
        mediator = nil
        eventBus = nil
        try await super.tearDown()
    }

    // MARK: - URL Handling Tests

    func testHandleValidURLNavigates() {
        // Arrange
        appCoordinator.isAuthenticated = true
        let url = URL(string: "edugo://dashboard")!

        // Act
        let result = sut.handle(url)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(appCoordinator.currentScreen, .dashboard)
        XCTAssertEqual(sut.lastDeeplink, .dashboard)
    }

    func testHandleInvalidURLReturnsFalse() {
        // Arrange
        let url = URL(string: "edugo://invalid/route")!

        // Act
        let result = sut.handle(url)

        // Assert
        XCTAssertFalse(result)
    }

    func testHandleProtectedRouteWithoutAuthNavigatesToLogin() {
        // Arrange
        appCoordinator.isAuthenticated = false
        let url = URL(string: "edugo://dashboard")!

        // Act
        let result = sut.handle(url)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(appCoordinator.currentScreen, .login)
        XCTAssertEqual(sut.lastDeeplink, .dashboard)
    }

    func testHandlePublicRouteWithoutAuthNavigates() {
        // Arrange
        appCoordinator.isAuthenticated = false
        let url = URL(string: "edugo://login")!

        // Act
        let result = sut.handle(url)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(appCoordinator.currentScreen, .login)
    }

    // MARK: - Push Notification Tests

    func testHandlePushNotificationWithValidDeeplink() {
        // Arrange
        appCoordinator.isAuthenticated = true
        let userInfo: [AnyHashable: Any] = [
            "deeplink": "edugo://materials"
        ]

        // Act
        let result = sut.handlePushNotification(userInfo: userInfo)

        // Assert
        XCTAssertTrue(result)
        XCTAssertEqual(appCoordinator.currentScreen, .materialList)
    }

    func testHandlePushNotificationWithoutDeeplinkReturnsFalse() {
        // Arrange
        let userInfo: [AnyHashable: Any] = [:]

        // Act
        let result = sut.handlePushNotification(userInfo: userInfo)

        // Assert
        XCTAssertFalse(result)
    }

    // MARK: - Post-Login Navigation Tests

    func testHandlePostLoginNavigationNavigatesToStoredDeeplink() {
        // Arrange
        appCoordinator.isAuthenticated = false
        let url = URL(string: "edugo://materials")!
        _ = sut.handle(url)
        XCTAssertEqual(appCoordinator.currentScreen, .login)
        XCTAssertNotNil(sut.lastDeeplink)

        // Act: Simulate successful login
        appCoordinator.isAuthenticated = true
        sut.handlePostLoginNavigation()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .materialList)
        XCTAssertNil(sut.lastDeeplink)
    }

    func testHandlePostLoginNavigationWithNoStoredDeeplinkDoesNothing() {
        // Arrange
        appCoordinator.isAuthenticated = true
        appCoordinator.navigate(to: .dashboard)
        XCTAssertNil(sut.lastDeeplink)

        // Act
        sut.handlePostLoginNavigation()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .dashboard)
    }
}
