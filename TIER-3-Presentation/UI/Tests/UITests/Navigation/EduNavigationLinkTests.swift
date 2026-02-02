import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduNavigationLinkTests {
    // MARK: - NavigationRouter Tests

    @Test("EduNavigationRouter inicializa vacío")
    func testRouterInitialization() {
        let router = EduNavigationRouter()

        #expect(router.path.isEmpty)
    }

    @Test("EduNavigationRouter navega a destination")
    func testRouterNavigate() {
        let router = EduNavigationRouter()

        router.navigate(to: .detail(id: "123"))

        #expect(router.path.count == 1)
    }

    @Test("EduNavigationRouter va atrás")
    func testRouterGoBack() {
        let router = EduNavigationRouter()

        router.navigate(to: .settings)
        router.navigate(to: .profile)
        router.goBack()

        #expect(router.path.count == 1)
    }

    @Test("EduNavigationRouter va a root")
    func testRouterGoToRoot() {
        let router = EduNavigationRouter()

        router.navigate(to: .settings)
        router.navigate(to: .profile)
        router.goToRoot()

        #expect(router.path.isEmpty)
    }

    @Test("EduNavigationRouter navega a ruta completa")
    func testRouterNavigateToRoute() {
        let router = EduNavigationRouter()

        router.navigate(to: [.settings, .profile, .detail(id: "123")])

        #expect(router.path.count == 3)
    }

    @Test("EduNavigationRouter goBack en path vacío no crashea")
    func testRouterGoBackEmpty() {
        let router = EduNavigationRouter()

        router.goBack()

        #expect(router.path.isEmpty)
    }

    @Test("EduNavigationRouter múltiples navegaciones")
    func testRouterMultipleNavigations() {
        let router = EduNavigationRouter()

        router.navigate(to: .custom("home"))
        router.navigate(to: .settings)
        router.navigate(to: .profile)

        #expect(router.path.count == 3)
    }

    // MARK: - Destination Tests

    @Test("NavigationRouter.Destination igualdad")
    func testDestinationEquality() {
        let dest1 = EduNavigationRouter.Destination.detail(id: "123")
        let dest2 = EduNavigationRouter.Destination.detail(id: "123")
        let dest3 = EduNavigationRouter.Destination.detail(id: "456")

        #expect(dest1 == dest2)
        #expect(dest1 != dest3)
    }

    @Test("NavigationRouter.Destination settings igualdad")
    func testDestinationSettingsEquality() {
        let dest1 = EduNavigationRouter.Destination.settings
        let dest2 = EduNavigationRouter.Destination.settings

        #expect(dest1 == dest2)
    }

    @Test("NavigationRouter.Destination profile igualdad")
    func testDestinationProfileEquality() {
        let dest1 = EduNavigationRouter.Destination.profile
        let dest2 = EduNavigationRouter.Destination.profile

        #expect(dest1 == dest2)
    }

    @Test("NavigationRouter.Destination custom igualdad")
    func testDestinationCustomEquality() {
        let dest1 = EduNavigationRouter.Destination.custom("home")
        let dest2 = EduNavigationRouter.Destination.custom("home")
        let dest3 = EduNavigationRouter.Destination.custom("about")

        #expect(dest1 == dest2)
        #expect(dest1 != dest3)
    }

    @Test("NavigationRouter.Destination diferentes no son iguales")
    func testDestinationDifferentNotEqual() {
        let dest1 = EduNavigationRouter.Destination.custom("home")
        let dest2 = EduNavigationRouter.Destination.settings
        let dest3 = EduNavigationRouter.Destination.profile

        #expect(dest1 != dest2)
        #expect(dest2 != dest3)
        #expect(dest1 != dest3)
    }

    // MARK: - Router State Tests

    @Test("EduNavigationRouter limpia path con goToRoot")
    func testRouterClearPath() {
        let router = EduNavigationRouter()

        router.navigate(to: [.custom("home"), .settings, .profile])
        #expect(router.path.count == 3)

        router.goToRoot()
        #expect(router.path.isEmpty)
    }

    @Test("EduNavigationRouter reemplaza path con navigate array")
    func testRouterReplacePath() {
        let router = EduNavigationRouter()

        router.navigate(to: .custom("home"))
        router.navigate(to: .settings)
        #expect(router.path.count == 2)

        router.navigate(to: [.profile])
        #expect(router.path.count == 1)
    }

    @Test("EduNavigationRouter path order se mantiene")
    func testRouterPathOrder() {
        let router = EduNavigationRouter()

        router.navigate(to: .custom("home"))
        router.navigate(to: .settings)
        router.navigate(to: .profile)

        #expect(router.path[0] == .custom("home"))
        #expect(router.path[1] == .settings)
        #expect(router.path[2] == .profile)
    }
}
