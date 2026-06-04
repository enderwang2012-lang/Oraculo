import SwiftUI

@main
struct OraculoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = OracleSessionModel()
    private let daily = DailyOracleService()

    init() {
        daily.refreshSharedCache()
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
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                Task { @MainActor in
                    #if !APPLICATION_EXTENSION_API_ONLY
                    LocationContextProvider.shared.refreshIfNeeded()
                    await CorpusRemoteUpdateService.refreshIfNeeded()
                    #endif
                    await OpenMeteoWeatherService.refreshSharedCacheIfNeeded()
                    daily.refreshSharedCache()
                    session.refreshOnOpen()
                }
            default:
                break
            }
        }
    }
}
