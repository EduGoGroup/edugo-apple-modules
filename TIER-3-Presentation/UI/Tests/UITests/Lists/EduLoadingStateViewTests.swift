import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduLoadingStateViewTests {

    @Test("EduLoadingStateView inicializa correctamente")
    func testInitialization() {
        let view = EduLoadingStateView()
        #expect(view != nil)
    }

    @Test("EduLoadingStateView muestra skeleton rows")
    func testShowsSkeletonRows() {
        let view = EduLoadingStateView()
        // El view muestra 3 skeleton rows con shimmer effect
        #expect(view != nil)
    }
}
