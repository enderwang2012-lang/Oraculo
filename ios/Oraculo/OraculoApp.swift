import SwiftUI

@main
struct OraculoApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var session = OracleSessionModel()
    @State private var wasInBackground = false

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
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active:
                if wasInBackground {
                    wasInBackground = false
                    session.refreshOnResumeFromBackground()
                }
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
                wasInBackground = true
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
