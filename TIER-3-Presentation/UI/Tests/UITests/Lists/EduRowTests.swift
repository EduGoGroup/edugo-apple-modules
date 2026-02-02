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
}
