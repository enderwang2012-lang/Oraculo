import Foundation
import XCTest
@testable import OraculoCore

final class DailyColorSelectorTests: XCTestCase {
    func testSelectionIsDeterministicForSameDayInstallAndContext() {
        let colors = makeColors()
        let dispatch = PhraseDispatch(
            universal: true,
            onlyWhen: [],
            boost: [],
            negative: nil,
            colorMoods: ["cool"],
            colorBan: nil,
            colorFamilies: nil
        )

        let first = DailyColorSelector.color(
            from: colors,
            dispatch: dispatch,
            dayKey: "2026-07-10",
            installID: "install-a",
            contextTags: ["weather:snow"]
        )
        let second = DailyColorSelector.color(
            from: colors,
            dispatch: dispatch,
            dayKey: "2026-07-10",
            installID: "install-a",
            contextTags: ["weather:snow"]
        )

        XCTAssertEqual(first, second)
    }

    func testContextTagsParticipateInSharedColorWeighting() {
        let colors = makeColors()

        let differingSelection = (0 ..< 1_000).first { index in
            let installID = "install-\(index)"
            let withoutContext = DailyColorSelector.color(
                from: colors,
                dispatch: nil,
                dayKey: "2026-07-10",
                installID: installID,
                contextTags: []
            )
            let withSnowContext = DailyColorSelector.color(
                from: colors,
                dispatch: nil,
                dayKey: "2026-07-10",
                installID: installID,
                contextTags: ["weather:snow"]
            )
            return withoutContext != withSnowContext
        }

        XCTAssertNotNil(
            differingSelection,
            "Context tags should affect at least one deterministic seed"
        )
    }

    private func makeColors() -> [NipponColor] {
        [
            NipponColor(
                id: "snow",
                name: "snow",
                cname: "雪",
                hex: "F5F5F5",
                foreground: "dark",
                moods: ["cool"],
                contextTags: ["weather:snow"],
                family: "gray",
                textMode: .ink
            ),
            NipponColor(
                id: "sun",
                name: "sun",
                cname: "日",
                hex: "F2C14E",
                foreground: "dark",
                moods: ["warm"],
                contextTags: ["weather:clear"],
                family: "yellow",
                textMode: .ink
            ),
        ]
    }
}
