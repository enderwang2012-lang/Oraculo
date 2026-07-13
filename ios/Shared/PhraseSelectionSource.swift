import Foundation

enum PhraseSelectionSource: String, Codable, Equatable, Hashable {
    case appInteraction
    case dailyAuto
    case fallback
}

enum SharedMomentSelectionSource: Equatable {
    case current
    case scheduled
    case none
}

enum SharedMomentSelectionPolicy {
    static func preferredSource(
        for dayKey: String,
        currentDayKey: String?,
        scheduledDayKey: String?
    ) -> SharedMomentSelectionSource {
        if currentDayKey == dayKey {
            return .current
        }
        if scheduledDayKey == dayKey {
            return .scheduled
        }
        return .none
    }
}
