import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduToastTests {
    // MARK: - ToastManager Tests

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

    @Test("ToastManager dismiss toast")
    func testDismissToast() {
        let manager = ToastManager.shared
        manager.show("Test", style: .info)

        if let toast = manager.toasts.first {
            manager.dismiss(toast)
            #expect(manager.toasts.allSatisfy { $0.id != toast.id })
        }
    }

    // MARK: - ToastStyle Tests

    @Test("ToastStyle success tiene icono correcto")
    func testSuccessStyle() {
        let style = ToastStyle.success
        #expect(style.icon == "checkmark.circle.fill")
    }

    @Test("ToastStyle error tiene icono correcto")
    func testErrorStyle() {
        let style = ToastStyle.error
        #expect(style.icon == "xmark.circle.fill")
    }

    @Test("ToastStyle warning tiene icono correcto")
    func testWarningStyle() {
        let style = ToastStyle.warning
        #expect(style.icon == "exclamationmark.triangle.fill")
    }

    @Test("ToastStyle info tiene icono correcto")
    func testInfoStyle() {
        let style = ToastStyle.info
        #expect(style.icon == "info.circle.fill")
    }

    // MARK: - ToastItem Tests

    @Test("ToastItem inicializa correctamente")
    func testToastItem() {
        let item = ToastItem(message: "Test", style: .success, duration: 5.0)
        #expect(item.message == "Test")
        #expect(item.style == .success)
        #expect(item.duration == 5.0)
    }

    @Test("ToastItem tiene ID único")
    func testToastItemUniqueID() {
        let item1 = ToastItem(message: "Test 1", style: .info, duration: 3.0)
        let item2 = ToastItem(message: "Test 2", style: .info, duration: 3.0)
        #expect(item1.id != item2.id)
    }

    // MARK: - EduToast View Tests

    @Test("EduToast view inicializa correctamente")
    func testEduToastView() {
        let item = ToastItem(message: "Test", style: .info, duration: 3.0)
        let toast = EduToast(item: item) {}
        #expect(toast.item.message == "Test")
    }

    // MARK: - ToastStyle Color Tests

    @Test("ToastStyle success tiene color verde")
    func testSuccessColor() {
        let style = ToastStyle.success
        #expect(style.color == .green)
    }

    @Test("ToastStyle error tiene color rojo")
    func testErrorColor() {
        let style = ToastStyle.error
        #expect(style.color == .red)
    }

    @Test("ToastStyle warning tiene color naranja")
    func testWarningColor() {
        let style = ToastStyle.warning
        #expect(style.color == .orange)
    }

    @Test("ToastStyle info tiene color azul")
    func testInfoColor() {
        let style = ToastStyle.info
        #expect(style.color == .blue)
    }
}
