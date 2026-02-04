import XCTest
@testable import EduFoundation

final class EduFoundationTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertEqual(EduFoundation.version, "2.0.0")
    }
}
