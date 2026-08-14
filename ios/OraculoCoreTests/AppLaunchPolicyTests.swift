import XCTest
@testable import OraculoCore

final class AppLaunchPolicyTests: XCTestCase {
    func testResumeKeepsCurrentMomentWhenWidgetMomentIsUnchanged() {
        XCTAssertEqual(
            AppLaunchPolicy.resumeAction(widgetMomentDiffers: false),
            .replayCurrent
        )
    }

    func testResumeAdoptsWidgetMomentBeforeReplayingWhenItChanged() {
        XCTAssertEqual(
            AppLaunchPolicy.resumeAction(widgetMomentDiffers: true),
            .adoptWidgetMomentAndReplay
        )
    }

    func testFreshInstallShowsGreetingOnFirstAppLaunch() {
        XCTAssertTrue(
            AppLaunchPolicy.shouldShowFirstInstallGreeting(
                hasRecordedAppLaunch: false,
                hasExistingInstallID: false,
                hasExistingSharedMoment: false
            )
        )
    }

    func testExistingInstallationDoesNotShowGreetingAfterUpgrade() {
        XCTAssertFalse(
            AppLaunchPolicy.shouldShowFirstInstallGreeting(
                hasRecordedAppLaunch: false,
                hasExistingInstallID: true,
                hasExistingSharedMoment: true
            )
        )
    }

    func testExistingInstallIDAlonePreventsUpgradeGreeting() {
        XCTAssertFalse(
            AppLaunchPolicy.shouldShowFirstInstallGreeting(
                hasRecordedAppLaunch: false,
                hasExistingInstallID: true,
                hasExistingSharedMoment: false
            )
        )
    }

    func testExistingSharedMomentAlonePreventsUpgradeGreeting() {
        XCTAssertFalse(
            AppLaunchPolicy.shouldShowFirstInstallGreeting(
                hasRecordedAppLaunch: false,
                hasExistingInstallID: false,
                hasExistingSharedMoment: true
            )
        )
    }

    func testGreetingOnlyAppearsOnce() {
        XCTAssertFalse(
            AppLaunchPolicy.shouldShowFirstInstallGreeting(
                hasRecordedAppLaunch: true,
                hasExistingInstallID: false,
                hasExistingSharedMoment: false
            )
        )
    }

    func testFirstInstallGreetingUsesRequiredText() {
        XCTAssertEqual(Phrase.firstInstallGreeting.text, "你好呀")
        XCTAssertTrue(Phrase.firstInstallGreeting.textEn.isEmpty)
    }
}
