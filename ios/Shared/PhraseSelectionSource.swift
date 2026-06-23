import Foundation

enum PhraseSelectionSource: String, Codable, Equatable, Hashable {
    case appInteraction
    case dailyAuto
    case fallback
}
