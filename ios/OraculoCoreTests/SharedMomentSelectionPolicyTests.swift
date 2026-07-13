import XCTest
@testable import OraculoCore

final class SharedMomentSelectionPolicyTests: XCTestCase {
    func testScheduledMomentWinsWhenCurrentMomentBelongsToPreviousDay() {
        let source = SharedMomentSelectionPolicy.preferredSource(
            for: "2026-07-13",
            currentDayKey: "2026-07-12",
            scheduledDayKey: "2026-07-13"
        )

        XCTAssertEqual(source, .scheduled)
    }

    func testCurrentMomentWinsWhenAppAlreadyDisplayedToday() {
        let source = SharedMomentSelectionPolicy.preferredSource(
            for: "2026-07-13",
            currentDayKey: "2026-07-13",
            scheduledDayKey: "2026-07-13"
        )

        XCTAssertEqual(source, .current)
    }
}
