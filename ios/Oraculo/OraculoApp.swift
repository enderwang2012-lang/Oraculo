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
            print("[Oraculo] WARNING: corpus missing from bundle — shake will not change content. Clean build after xcodegen.")
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
                // 先换句/换色，勿等待语料或天气网络（否则回前台会卡数秒像 bug）。
                if oldPhase == .background {
                    session.refreshOnOpen()
                }
                Task { @MainActor in
                    #if !APPLICATION_EXTENSION_API_ONLY
                    LocationContextProvider.shared.refreshIfNeeded()
                    await CorpusRemoteUpdateService.refreshIfNeeded()
                    #endif
                    await OpenMeteoWeatherService.refreshSharedCacheIfNeeded()
                }
            case .background:
                Task { @MainActor in
                    session.syncWidgetDisplay()
                }
            default:
                break
            }
        }
    }
}
