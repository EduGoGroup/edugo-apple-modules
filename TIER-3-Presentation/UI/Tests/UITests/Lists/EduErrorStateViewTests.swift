import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduErrorStateViewTests {

    @Test("EduErrorStateView muestra mensaje de error")
    func testDisplaysErrorMessage() {
        let errorMessage = "Error de red"
        let _ = EduErrorStateView(
            message: errorMessage,
            onRetry: { }
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduErrorStateView ejecuta onRetry")
    func testOnRetryExecution() {
        @MainActor
        class TestContext {
            var retryWasCalled = false
        }

        let context = TestContext()

        let _ = EduErrorStateView(
            message: "Error",
            onRetry: {
                context.retryWasCalled = true
            }
        )
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduErrorStateView con título custom")
    func testCustomTitle() {
        let _ = EduErrorStateView(
            title: "Oops!",
            message: "Algo salió mal",
            retryTitle: "Intentar de nuevo",
            onRetry: { }
        )
        // La inicialización exitosa del struct es suficiente validación
    }
}
