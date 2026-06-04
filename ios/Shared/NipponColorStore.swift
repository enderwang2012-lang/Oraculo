import Foundation

final class NipponColorStore {
    static let shared = NipponColorStore()

    private(set) var colors: [NipponColor] = []

    var colorCount: Int { colors.count }

    private init() {
        colors = Self.loadColors(from: .main)
    }

    static func loadColors(from bundle: Bundle) -> [NipponColor] {
        if let decoded = loadColorsOrNil(from: bundle), !decoded.isEmpty {
            return decoded
        }
        return [NipponColor(id: "011", name: "nakabeni", cname: "中紅", hex: "DB4D6D", foreground: "light")]
    }

    private static func loadColorsOrNil(from bundle: Bundle) -> [NipponColor]? {
        let url = bundle.url(forResource: AppConstants.nipponColorsResourceName, withExtension: "json")
            ?? bundle.url(forResource: AppConstants.nipponColorsResourceName, withExtension: "json", subdirectory: "Resources")
        guard let url,
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([NipponColor].self, from: data),
              !decoded.isEmpty
        else {
            return nil
        }
        return decoded
    }

    func color(for date: Date = Date()) -> NipponColor {
        guard !colors.isEmpty else {
            return NipponColor(id: "011", name: "nakabeni", cname: "中紅", hex: "DB4D6D", foreground: "light")
        }
        let key = PhraseStore.dayKey(for: date)
        // 与短语不同种子，避免「句子和颜色」永远同索引
        let index = PhraseStore.stableIndex(for: key + "|color", count: colors.count)
        return colors[index]
    }
}
