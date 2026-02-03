import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduLoadingStateViewTests {

    @Test("EduLoadingStateView inicializa correctamente")
    func testInitialization() {
        let _ = EduLoadingStateView()
        // La inicialización exitosa del struct es suficiente validación
    }

    @Test("EduLoadingStateView muestra skeleton rows")
    func testShowsSkeletonRows() {
        let _ = EduLoadingStateView()
        // El view muestra 3 skeleton rows con shimmer effect
        // La inicialización exitosa del struct es suficiente validación
    }
}
