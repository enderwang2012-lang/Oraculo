import Foundation

struct PhraseFreshness: Codable, Equatable, Hashable {
    let semanticCluster: String
    let cadenceGroup: String
    let lifecycle: String

    static let fallback = PhraseFreshness(
        semanticCluster: "general",
        cadenceGroup: "general",
        lifecycle: "active"
    )
}
