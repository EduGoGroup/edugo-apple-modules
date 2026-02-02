import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduToastTests {
    @Test("ToastManager es singleton")
    func testSingleton() {
        let manager1 = ToastManager.shared
        let manager2 = ToastManager.shared
        #expect(manager1 === manager2)
    }
    
    @Test("ToastManager muestra toast")
    func testShowToast() async {
        let manager = ToastManager.shared
        manager.show("Test", style: .info)
        #expect(manager.toasts.count > 0)
    }
}
