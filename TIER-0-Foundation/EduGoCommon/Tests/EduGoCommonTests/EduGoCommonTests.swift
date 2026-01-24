import Testing
@testable import EduGoCommon

@Suite("EduGoCommon Tests")
struct EduGoCommonTests {
    @Test("Module version is defined")
    func testModuleVersion() {
        #expect(EduGoCommon.version == "1.0.0")
    }
}
