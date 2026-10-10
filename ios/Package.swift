// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "OraculoCore",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .library(name: "OraculoCore", targets: ["OraculoCore"]),
    ],
    targets: [
        .target(
            name: "OraculoCore",
            path: "Shared",
            exclude: [
                "BreathingBottomGlow.swift",
                "ContextSnapshotBuilder.swift",
                "CorpusRemoteUpdateService.swift",
                "DailyOracle.swift",
                "DailyPhraseService.swift",
                "GeoCoordinateMapper.swift",
                "InstallID.swift",
                "LocationContextProvider.swift",
                "NipponAmbienceView.swift",
                "NipponColorStore.swift",
                "NipponCrossfadeBackground.swift",
                "OracleMoment.swift",
                "OraculoTypography.swift",
                "PhraseColorHint.swift",
                "PhraseStore.swift",
                "Resources",
                "SessionOracleService.swift",
                "SharedOracleMomentStore.swift",
                "WidgetTimelineRefresher.swift",
            ],
            sources: [
                "AppLaunchPolicy.swift",
                "AppConstants.swift",
                "CalendarConfig.swift",
                "CalendarConfigStore.swift",
                "Color+Hex.swift",
                "ContextSnapshot.swift",
                "CorpusBundledMeta.swift",
                "CorpusReleaseStorage.swift",
                "CorpusVersionSelection.swift",
                "FestivalCalendar.swift",
                "GeoContext.swift",
                "LocationContextCache.swift",
                "NipponColor.swift",
                "OpenMeteoWeatherService.swift",
                "Phrase.swift",
                "PhraseDispatch.swift",
                "PhraseDateBindingSelector.swift",
                "PhraseDispatchScorer.swift",
                "PhraseExposureHistory.swift",
                "PhraseFreshness.swift",
                "PhraseFreshnessScorer.swift",
                "PhrasePicker.swift",
                "PhraseSelectionSource.swift",
                "WeatherContextCache.swift",
                "SolarTermCalendar.swift",
            ]
        ),
        .testTarget(
            name: "OraculoCoreTests",
            dependencies: ["OraculoCore"],
            path: "OraculoCoreTests"
        ),
    ]
)
