import Foundation

enum AppResumeAction: Equatable {
    case replayCurrent
    case adoptWidgetMomentAndReplay
}

enum AppLaunchPolicy {
    static func resumeAction(widgetMomentDiffers: Bool) -> AppResumeAction {
        widgetMomentDiffers ? .adoptWidgetMomentAndReplay : .replayCurrent
    }

    static func shouldShowFirstInstallGreeting(
        hasRecordedAppLaunch: Bool,
        hasExistingInstallID: Bool,
        hasExistingSharedMoment: Bool
    ) -> Bool {
        !hasRecordedAppLaunch && !hasExistingInstallID && !hasExistingSharedMoment
    }
}
