import SwiftUI

@main
struct OraculoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = OracleSessionModel()

    init() {
        #if DEBUG
        let phrases = PhraseStore.shared.phraseCount
        let colors = NipponColorStore.shared.colorCount
        print("[Oraculo] bundled phrases=\(phrases), colors=\(colors)")
        if phrases <= 1 || colors <= 1 {
            print("[Oraculo] WARNING: corpus missing from bundle — long-press refresh will not change content. Clean build after xcodegen.")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView(session: session)
        }
        .onChange(of: scenePhase) { oldPhase, phase in
            switch phase {
            case .active:
                // 回前台：先展示当前句，略停后再换句；勿等待语料或天气网络。
                if oldPhase == .background {
                    session.refreshOnResumeFromBackground()
                }
                session.syncWidgetDisplay()
                Task { @MainActor in
                    #if !APPLICATION_EXTENSION_API_ONLY
                    if LocationContextProvider.isLocationContextEnabled {
                        LocationContextProvider.shared.refreshIfNeeded()
                        await OpenMeteoWeatherService.refreshSharedCacheIfPossible()
                    }
                    await CorpusRemoteUpdateService.refreshIfNeeded()
                    #endif
                }
            case .background:
                Task { @MainActor in
                    session.cancelPendingResumeRefresh()
                    session.syncWidgetDisplay()
                }
            default:
                break
            }
        }
    }
}
