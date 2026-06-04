import Foundation

/// 对外暴露「今日一句」；App 启动与进入前台时刷新共享缓存。
struct DailyPhraseService {
    private let store: PhraseStore

    init(store: PhraseStore = .shared) {
        self.store = store
    }

    var todayPhrase: Phrase {
        store.phrase(for: Date())
    }

    var todayDayKey: String {
        PhraseStore.dayKey(for: Date())
    }

    func refreshSharedCache() {
        store.syncTodayToSharedDefaults()
    }
}
