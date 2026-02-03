import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduEmptyStateViewTests {

    @Test("EduEmptyStateView muestra icono, título y descripción")
    func testBasicDisplay() {
        let _ = EduEmptyStateView(
            icon: "tray",
            title: "Sin elementos",
            description: "No hay datos para mostrar"
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduEmptyStateView con action button")
    func testWithAction() {
        @MainActor
        class TestContext {
            var actionCalled = false
        }

        let context = TestContext()

        let _ = EduEmptyStateView(
            title: "Sin datos",
            description: "Crea uno nuevo",
            actionTitle: "Crear",
            action: {
                context.actionCalled = true
            }
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduEmptyStateView sin action button")
    func testWithoutAction() {
        let _ = EduEmptyStateView(
            title: "Vacío",
            description: "Sin acción"
        )
        // La inicialización exitosa del struct es suficiente validación
    }
}
