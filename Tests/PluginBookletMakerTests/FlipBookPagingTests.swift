import XCTest
@testable import PluginBookletMaker

final class FlipBookPagingTests: XCTestCase {

    func testEmptyDocumentHasNoPageRange() {
        XCTAssertNil(FlipBookPaging.pageRange(forSpread: 0, pageCount: 0))
    }

    func testCoverAndBackCoverAreSinglePages() {
        XCTAssertEqual(FlipBookPaging.pageRange(forSpread: 0, pageCount: 8), 1...1)
        XCTAssertEqual(FlipBookPaging.pageRange(forSpread: 4, pageCount: 8), 8...8)
        XCTAssertEqual(FlipBookPaging.pageRange(forSpread: 0, pageCount: 1), 1...1)
    }

    func testInteriorSpreadsContainTwoPages() {
        for (spread, expected) in [
            (1, 2...3),
            (2, 4...5),
            (3, 6...7),
        ] {
            XCTAssertEqual(
                FlipBookPaging.pageRange(forSpread: spread, pageCount: 8),
                expected
            )
        }
    }

    func testOddPageCountClampsTheLastSpread() {
        XCTAssertEqual(FlipBookPaging.pageRange(forSpread: 2, pageCount: 5), 4...5)
        XCTAssertNil(FlipBookPaging.pageRange(forSpread: 3, pageCount: 5))
    }

    func testOutOfRangeSpreadsReturnNil() {
        XCTAssertNil(FlipBookPaging.pageRange(forSpread: -1, pageCount: 8))
        XCTAssertNil(FlipBookPaging.pageRange(forSpread: 5, pageCount: 8))
        XCTAssertNil(FlipBookPaging.pageRange(forSpread: 1, pageCount: 1))
    }
}