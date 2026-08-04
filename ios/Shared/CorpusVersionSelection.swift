import Foundation

enum CorpusVersionSelection {
    static func shouldUseCached(
        cachedVersion: Int,
        bundledVersion: Int,
        hasCachedPayload: Bool
    ) -> Bool {
        hasCachedPayload && cachedVersion > bundledVersion
    }
}
