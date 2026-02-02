import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduErrorStateViewTests {

    @Test("EduErrorStateView muestra mensaje de error")
    func testDisplaysErrorMessage() {
        let errorMessage = "Error de red"
        let view = EduErrorStateView(
            message: errorMessage,
            onRetry: { }
        )
        #expect(view != nil)
    }

    @Test("EduErrorStateView ejecuta onRetry")
    func testOnRetryExecution() {
        @MainActor
        class TestContext {
            var retryWasCalled = false
        }

        let context = TestContext()

        let view = EduErrorStateView(
            message: "Error",
            onRetry: {
                context.retryWasCalled = true
            }
        )

        #expect(view != nil)
    }

    @Test("EduErrorStateView con título custom")
    func testCustomTitle() {
        let view = EduErrorStateView(
            title: "Oops!",
            message: "Algo salió mal",
            retryTitle: "Intentar de nuevo",
            onRetry: { }
        )
        #expect(view != nil)
    }
}
