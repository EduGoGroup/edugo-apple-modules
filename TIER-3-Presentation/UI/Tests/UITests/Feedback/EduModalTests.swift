import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduModalTests {
    // MARK: - ModalManager Tests

    @Test("EduModalManager es singleton")
    func testSingleton() {
        let manager1 = EduModalManager.shared
        let manager2 = EduModalManager.shared
        #expect(manager1 === manager2)
    }

    @Test("EduModalManager muestra modal")
    func testShowModal() {
        let manager = EduModalManager.shared

        manager.show {
            Text("Modal content")
        }

        #expect(manager.isPresented == true)
        #expect(manager.modalView != nil)
    }

    @Test("EduModalManager dismiss modal")
    func testDismissModal() {
        let manager = EduModalManager.shared

        manager.show {
            Text("Modal content")
        }
        manager.dismiss()

        #expect(manager.isPresented == false)
    }

    // MARK: - ModalSize Tests

    @Test("EduModalSize small tiene altura correcta")
    func testSmallSize() {
        let size = EduModalSize.small
        #expect(size.height == 300)
    }

    @Test("EduModalSize medium tiene altura correcta")
    func testMediumSize() {
        let size = EduModalSize.medium
        #expect(size.height == 500)
    }

    @Test("EduModalSize large tiene altura correcta")
    func testLargeSize() {
        let size = EduModalSize.large
        #expect(size.height == 700)
    }

    @Test("EduModalSize fullScreen no tiene altura")
    func testFullScreenSize() {
        let size = EduModalSize.fullScreen
        #expect(size.height == nil)
    }

    @Test("EduModalSize custom tiene altura personalizada")
    func testCustomSize() {
        let size = EduModalSize.custom(400)
        #expect(size.height == 400)
    }

    // MARK: - ModalContent Tests

    @Test("EduModalContent inicializa correctamente")
    func testModalContent() {
        let content = EduModalContent(
            title: "Modal Title",
            size: .medium,
            showCloseButton: true,
            onDismiss: {}
        ) {
            Text("Content")
        }

        #expect(content.title == "Modal Title")
    }

    @Test("EduModalContent con valores por defecto")
    func testModalContentDefaults() {
        let content = EduModalContent(
            title: "Title"
        ) {
            Text("Content")
        }

        #expect(content.title == "Title")
    }

    @Test("EduModalContent sin botón de cierre")
    func testModalContentNoCloseButton() {
        let content = EduModalContent(
            title: "Title",
            showCloseButton: false
        ) {
            Text("Content")
        }

        #expect(content.showCloseButton == false)
    }

    @Test("EduModalContent con tamaño small")
    func testModalContentSmallSize() {
        let content = EduModalContent(
            title: "Small Modal",
            size: .small
        ) {
            Text("Content")
        }

        #expect(content.size.height == 300)
    }

    @Test("EduModalContent con tamaño large")
    func testModalContentLargeSize() {
        let content = EduModalContent(
            title: "Large Modal",
            size: .large
        ) {
            Text("Content")
        }

        #expect(content.size.height == 700)
    }

    // MARK: - ModalPresentationStyle Tests

    @Test("EduModalPresentationStyle sheet existe")
    func testSheetStyle() {
        let style = EduModalPresentationStyle.sheet
        #expect(style == .sheet)
    }

    #if os(iOS) || os(visionOS)
    @Test("EduModalPresentationStyle fullScreenCover existe (iOS/visionOS)")
    func testFullScreenCoverStyle() {
        let style = EduModalPresentationStyle.fullScreenCover
        #expect(style == .fullScreenCover)
    }

    @Test("EduModalPresentationStyle pageSheet existe (iOS/visionOS)")
    func testPageSheetStyle() {
        let style = EduModalPresentationStyle.pageSheet
        #expect(style == .pageSheet)
    }

    @Test("EduModalPresentationStyle formSheet existe (iOS/visionOS)")
    func testFormSheetStyle() {
        let style = EduModalPresentationStyle.formSheet
        #expect(style == .formSheet)
    }
    #endif
}
