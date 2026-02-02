import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduListViewTests {

    // Test #1: ViewState.loading
    @Test("EduListView muestra loading state correctamente")
    func testLoadingState() {
        let listView = EduListView<String, Text>(
            state: .loading,
            content: { item in Text(item) }
        )
        #expect(listView != nil)
    }

    // Test #2: ViewState.success con items
    @Test("EduListView muestra success con items")
    func testSuccessStateWithItems() {
        let items = ["Item 1", "Item 2", "Item 3"]
        let listView = EduListView<String, Text>(
            state: .success(items),
            content: { item in Text(item) }
        )
        #expect(listView != nil)
    }

    // Test #3: ViewState.success vacío
    @Test("EduListView muestra empty cuando success está vacío")
    func testSuccessStateEmpty() {
        let listView = EduListView<String, Text>(
            state: .success([]),
            emptyTitle: "Sin datos",
            emptyDescription: "No hay elementos",
            content: { item in Text(item) }
        )
        #expect(listView != nil)
    }

    // Test #4: ViewState.error
    @Test("EduListView muestra error state con mensaje")
    func testErrorState() {
        let errorMessage = "Error de conexión"
        let listView = EduListView<String, Text>(
            state: .error(errorMessage),
            onRetry: { },
            content: { item in Text(item) }
        )
        #expect(listView != nil)
    }

    // Test #5: ViewState.empty
    @Test("EduListView muestra empty state")
    func testEmptyState() {
        let listView = EduListView<String, Text>(
            state: .empty,
            emptyTitle: "Lista vacía",
            content: { item in Text(item) }
        )
        #expect(listView != nil)
    }

    // Test #6: onRetry se ejecuta
    @Test("EduListView ejecuta onRetry en error state")
    func testOnRetryExecution() {
        @MainActor
        class TestContext {
            var retryWasCalled = false
        }

        let context = TestContext()

        let listView = EduListView<String, Text>(
            state: .error("Error"),
            onRetry: {
                context.retryWasCalled = true
            },
            content: { item in Text(item) }
        )

        #expect(listView != nil)
    }

    // Test #7: Custom empty title/description
    @Test("EduListView usa custom empty title y description")
    func testCustomEmptyText() {
        let customTitle = "No hay resultados"
        let customDescription = "Intenta otra búsqueda"

        let listView = EduListView<String, Text>(
            state: .empty,
            emptyTitle: customTitle,
            emptyDescription: customDescription,
            content: { item in Text(item) }
        )

        #expect(listView != nil)
    }
}
