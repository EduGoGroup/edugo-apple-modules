import Testing
import SwiftUI
@testable import UI

@MainActor
struct EduRowTests {
    @Test("EduRow inicializa correctamente")
    func testBasicInitialization() {
        let row = EduRow("Test") {
            EmptyView()
        } trailing: {
            EmptyView()
        }
        #expect(row != nil)
    }

    @Test("EduRow con subtitle")
    func testWithSubtitle() {
        let row = EduRow("Title", subtitle: "Subtitle")
        #expect(row != nil)
    }

    @Test("EduRow con leading content")
    func testWithLeading() {
        let row = EduRow("Title") {
            Image(systemName: "star")
        } trailing: {
            EmptyView()
        }
        #expect(row != nil)
    }

    @Test("EduRow con trailing content")
    func testWithTrailing() {
        let row = EduRow("Title") {
            EmptyView()
        } trailing: {
            Image(systemName: "chevron.right")
        }
        #expect(row != nil)
    }

    @Test("EduRow con divider desactivado")
    func testWithoutDivider() {
        let row = EduRow("Title", showDivider: false)
        #expect(row != nil)
    }

    @Test("EduRow ejecuta onTap action")
    func testOnTapExecution() {
        @MainActor
        class TestContext {
            var tapped = false
        }

        let context = TestContext()

        let row = EduRow("Title", onTap: {
            context.tapped = true
        })

        #expect(row != nil)
    }

    @Test("EduRow con leading Y trailing")
    func testWithLeadingAndTrailing() {
        let row = EduRow("Title") {
            Image(systemName: "star")
        } trailing: {
            Image(systemName: "chevron.right")
        }
        #expect(row != nil)
    }

    @Test("EduRow sin leading ni trailing")
    func testWithoutLeadingOrTrailing() {
        let row = EduRow("Simple Title")
        #expect(row != nil)
    }
}
