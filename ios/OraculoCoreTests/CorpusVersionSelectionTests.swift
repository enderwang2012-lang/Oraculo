import XCTest
@testable import OraculoCore

final class CorpusVersionSelectionTests: XCTestCase {
    func testNewerBundleWinsOverStaleCache() {
        XCTAssertFalse(
            CorpusVersionSelection.shouldUseCached(
                cachedVersion: 7,
                bundledVersion: 8,
                hasCachedPayload: true
            )
        )
    }

    func testNewerCacheWinsOverBundle() {
        XCTAssertTrue(
            CorpusVersionSelection.shouldUseCached(
                cachedVersion: 8,
                bundledVersion: 7,
                hasCachedPayload: true
            )
        )
    }

    func testEqualVersionUsesBundledPayload() {
        XCTAssertFalse(
            CorpusVersionSelection.shouldUseCached(
                cachedVersion: 7,
                bundledVersion: 7,
                hasCachedPayload: true
            )
        )
    }
}
