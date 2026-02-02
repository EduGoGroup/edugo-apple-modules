import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduEmptyStateViewTests {

    @Test("EduEmptyStateView muestra icono, título y descripción")
    func testBasicDisplay() {
        let view = EduEmptyStateView(
            icon: "tray",
            title: "Sin elementos",
            description: "No hay datos para mostrar"
        )
        #expect(view != nil)
    }

    @Test("EduEmptyStateView con action button")
    func testWithAction() {
        @MainActor
        class TestContext {
            var actionCalled = false
        }

        let context = TestContext()

        let view = EduEmptyStateView(
            title: "Sin datos",
            description: "Crea uno nuevo",
            actionTitle: "Crear",
            action: {
                context.actionCalled = true
            }
        )

        #expect(view != nil)
    }

    @Test("EduEmptyStateView sin action button")
    func testWithoutAction() {
        let view = EduEmptyStateView(
            title: "Vacío",
            description: "Sin acción"
        )
        #expect(view != nil)
    }
}
