import Foundation

enum PhraseDateBindingSelector {
    static func candidatePool(from phrases: [Phrase], activeTags: Set<String>) -> [Phrase] {
        let eligible = phrases.filter { phrase in
            guard phrase.freshness.lifecycle != "retired" else { return false }
            let dispatch = phrase.dispatch ?? .fallback
            guard dispatch.onlyWhen.isEmpty || dispatch.onlyWhen.contains(where: activeTags.contains) else {
                return false
            }
            if let binding = dispatch.dateBinding, binding.mode == .exclusive {
                return binding.rules.contains(where: activeTags.contains)
            }
            return phrase.freshness.lifecycle != "retired"
        }
        let exclusive = exclusivePool(from: eligible, activeTags: activeTags)
        return exclusive.isEmpty ? eligible : exclusive
    }

    static func exclusivePool(from phrases: [Phrase], activeTags: Set<String>) -> [Phrase] {
        let matching = phrases.filter { phrase in
            guard let binding = phrase.dispatch?.dateBinding,
                  binding.mode == .exclusive,
                  !binding.rules.isEmpty
            else {
                return false
            }
            return binding.rules.contains(where: activeTags.contains)
        }

        guard let highestPriority = matching.compactMap({ $0.dispatch?.dateBinding?.priority }).max() else {
            return []
        }
        return matching.filter { $0.dispatch?.dateBinding?.priority == highestPriority }
    }
}
