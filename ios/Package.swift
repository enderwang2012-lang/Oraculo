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
                "ContextSnapshot.swift",
                "ContextSnapshotBuilder.swift",
                "CorpusBundledMeta.swift",
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
                "PhraseDispatchScorer.swift",
                "PhraseFreshnessScorer.swift",
                "PhrasePicker.swift",
                "PhraseStore.swift",
                "Resources",
                "SessionOracleService.swift",
                "SharedOracleMomentStore.swift",
                "SolarTermCalendar.swift",
                "WidgetTimelineRefresher.swift",
            ],
            sources: [
                "AppConstants.swift",
                "Color+Hex.swift",
                "FestivalCalendar.swift",
                "GeoContext.swift",
                "LocationContextCache.swift",
                "NipponColor.swift",
                "OpenMeteoWeatherService.swift",
                "Phrase.swift",
                "PhraseDispatch.swift",
                "PhraseExposureHistory.swift",
                "PhraseFreshness.swift",
                "PhraseSelectionSource.swift",
                "WeatherContextCache.swift",
            ]
        ),
        .testTarget(
            name: "OraculoCoreTests",
            dependencies: ["OraculoCore"],
            path: "OraculoCoreTests"
        ),
    ]
)
