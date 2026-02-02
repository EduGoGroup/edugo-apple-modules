import XCTest
@testable import Navigation
import CQRS

/// Tests unitarios para los FeatureCoordinators.
///
/// Valida:
/// - AuthCoordinator: Navegación de autenticación
/// - MaterialsCoordinator: Navegación de materiales
/// - AssessmentCoordinator: Navegación de evaluaciones
/// - DashboardCoordinator: Navegación del dashboard
/// - CoordinatorFactory: Creación de coordinadores
@MainActor
final class FeatureCoordinatorsTests: XCTestCase {

    // MARK: - Properties

    var appCoordinator: AppCoordinator!
    var mediator: Mediator!
    var eventBus: EventBus!
    var factory: CoordinatorFactory!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mediator = Mediator()
        eventBus = EventBus()
        appCoordinator = AppCoordinator(mediator: mediator, eventBus: eventBus)
        await appCoordinator.setup()
        factory = CoordinatorFactory(appCoordinator: appCoordinator, mediator: mediator)
    }

    override func tearDown() async throws {
        await appCoordinator.cleanup()
        appCoordinator = nil
        mediator = nil
        eventBus = nil
        factory = nil
        try await super.tearDown()
    }

    // MARK: - AuthCoordinator Tests

    func testAuthCoordinatorStartNavigatesToLogin() {
        // Arrange
        let sut = factory.makeAuthCoordinator()

        // Act
        sut.start()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .login)
    }

    func testAuthCoordinatorShowLoginNavigates() {
        // Arrange
        let sut = factory.makeAuthCoordinator()

        // Act
        sut.showLogin()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .login)
    }

    func testAuthCoordinatorHandleLogoutResetsNavigation() {
        // Arrange
        let sut = factory.makeAuthCoordinator()
        appCoordinator.isAuthenticated = true
        appCoordinator.navigate(to: .dashboard)

        // Act
        sut.handleLogout()

        // Assert
        XCTAssertFalse(appCoordinator.isAuthenticated)
        XCTAssertEqual(appCoordinator.currentScreen, .login)
        XCTAssertEqual(appCoordinator.navigationPath.count, 0)
    }

    // MARK: - MaterialsCoordinator Tests

    func testMaterialsCoordinatorStartNavigatesToList() {
        // Arrange
        let sut = factory.makeMaterialsCoordinator()

        // Act
        sut.start()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .materialList)
    }

    func testMaterialsCoordinatorShowMaterialListNavigates() {
        // Arrange
        let sut = factory.makeMaterialsCoordinator()

        // Act
        sut.showMaterialList()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .materialList)
    }

    func testMaterialsCoordinatorShowMaterialDetailNavigatesWithId() {
        // Arrange
        let sut = factory.makeMaterialsCoordinator()
        let materialId = UUID()

        // Act
        sut.showMaterialDetail(materialId: materialId)

        // Assert
        XCTAssertEqual(appCoordinator.navigationPath.count, 1)
        XCTAssertEqual(appCoordinator.currentScreen, .materialDetail(materialId: materialId))
    }

    func testMaterialsCoordinatorShowUploadMaterialPresentsSheet() {
        // Arrange
        let sut = factory.makeMaterialsCoordinator()

        // Act
        sut.showUploadMaterial()

        // Assert
        XCTAssertEqual(appCoordinator.presentedSheet, .materialUpload)
    }

    func testMaterialsCoordinatorShowAssignMaterialPresentsSheet() {
        // Arrange
        let sut = factory.makeMaterialsCoordinator()
        let materialId = UUID()

        // Act
        sut.showAssignMaterial(materialId: materialId)

        // Assert
        XCTAssertEqual(appCoordinator.presentedSheet, .materialAssignment(materialId: materialId))
    }

    func testMaterialsCoordinatorDismissUploadClosesModal() {
        // Arrange
        let sut = factory.makeMaterialsCoordinator()
        sut.showUploadMaterial()
        XCTAssertNotNil(appCoordinator.presentedSheet)

        // Act
        sut.dismissUpload()

        // Assert
        XCTAssertNil(appCoordinator.presentedSheet)
    }

    // MARK: - AssessmentCoordinator Tests

    func testAssessmentCoordinatorShowAssessmentNavigatesWithIds() {
        // Arrange
        let sut = factory.makeAssessmentCoordinator()
        let assessmentId = UUID()
        let userId = UUID()

        // Act
        sut.showAssessment(assessmentId: assessmentId, userId: userId)

        // Assert
        XCTAssertEqual(appCoordinator.navigationPath.count, 1)
        XCTAssertEqual(
            appCoordinator.currentScreen,
            .assessment(assessmentId: assessmentId, userId: userId)
        )
    }

    func testAssessmentCoordinatorShowResultsNavigates() {
        // Arrange
        let sut = factory.makeAssessmentCoordinator()
        let assessmentId = UUID()

        // Act
        sut.showResults(assessmentId: assessmentId)

        // Assert
        XCTAssertEqual(appCoordinator.navigationPath.count, 1)
        XCTAssertEqual(appCoordinator.currentScreen, .assessmentResults(assessmentId: assessmentId))
    }

    func testAssessmentCoordinatorReturnToDashboardPopsToRoot() {
        // Arrange
        let sut = factory.makeAssessmentCoordinator()
        appCoordinator.isAuthenticated = true
        appCoordinator.navigate(to: .dashboard)
        appCoordinator.navigate(to: .materialList)
        XCTAssertEqual(appCoordinator.navigationPath.count, 2)

        // Act
        sut.returnToDashboard()

        // Assert
        XCTAssertEqual(appCoordinator.navigationPath.count, 0)
        XCTAssertEqual(appCoordinator.currentScreen, .dashboard)
    }

    // MARK: - DashboardCoordinator Tests

    func testDashboardCoordinatorStartNavigatesToDashboard() {
        // Arrange
        let sut = factory.makeDashboardCoordinator()

        // Act
        sut.start()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .dashboard)
    }

    func testDashboardCoordinatorShowProfileNavigates() {
        // Arrange
        let sut = factory.makeDashboardCoordinator()

        // Act
        sut.showProfile()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .userProfile)
    }

    func testDashboardCoordinatorShowContextSwitchPresentsSheet() {
        // Arrange
        let sut = factory.makeDashboardCoordinator()

        // Act
        sut.showContextSwitch()

        // Assert
        XCTAssertEqual(appCoordinator.presentedSheet, .contextSwitch)
    }

    func testDashboardCoordinatorNavigateToMaterialsDelegatesToMaterialsCoordinator() {
        // Arrange
        let sut = factory.makeDashboardCoordinator()

        // Act
        sut.navigateToMaterials()

        // Assert
        XCTAssertEqual(appCoordinator.currentScreen, .materialList)
    }

    func testDashboardCoordinatorNavigateToAssessmentDelegatesToAssessmentCoordinator() {
        // Arrange
        let sut = factory.makeDashboardCoordinator()
        let assessmentId = UUID()
        let userId = UUID()

        // Act
        sut.navigateToAssessment(assessmentId: assessmentId, userId: userId)

        // Assert
        XCTAssertEqual(
            appCoordinator.currentScreen,
            .assessment(assessmentId: assessmentId, userId: userId)
        )
    }

    // MARK: - CoordinatorFactory Tests

    func testCoordinatorFactoryCreatesAuthCoordinator() {
        // Act
        let coordinator = factory.makeAuthCoordinator()

        // Assert
        XCTAssertNotNil(coordinator)
        XCTAssertTrue(coordinator.appCoordinator === appCoordinator)
    }

    func testCoordinatorFactoryCreatesMaterialsCoordinator() {
        // Act
        let coordinator = factory.makeMaterialsCoordinator()

        // Assert
        XCTAssertNotNil(coordinator)
        XCTAssertTrue(coordinator.appCoordinator === appCoordinator)
    }

    func testCoordinatorFactoryCreatesAssessmentCoordinator() {
        // Act
        let coordinator = factory.makeAssessmentCoordinator()

        // Assert
        XCTAssertNotNil(coordinator)
        XCTAssertTrue(coordinator.appCoordinator === appCoordinator)
    }

    func testCoordinatorFactoryCreatesDashboardCoordinator() {
        // Act
        let coordinator = factory.makeDashboardCoordinator()

        // Assert
        XCTAssertNotNil(coordinator)
        XCTAssertTrue(coordinator.appCoordinator === appCoordinator)
    }
}
