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
        return [NipponColor.fallback]
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

    /// 选色：根据当前句的 colorMoods/colorBan 收窄候选池，再按 InstallID 切片。
    /// - 不传 phrase（兼容老调用）：等价于「全 248 色随机」，与之前行为一致。
    /// - 传 context：命中色彩 contextTags 的色额外加权——「颜色也应景」（季节/节日/天气）。
    /// - 池过小（< minPoolSize=30）回落为不剔除，避免连续几天同色暴露算法。
    func color(
        for date: Date = Date(),
        phrase: Phrase? = nil,
        context: ContextSnapshot? = nil
    ) -> NipponColor {
        let key = PhraseStore.dayKey(for: date)
        let colorDispatch = phrase?.effectiveColorDispatch
        return DailyColorSelector.color(
            from: colors,
            dispatch: colorDispatch,
            dayKey: key,
            installID: InstallID.value,
            contextTags: context?.activeTags ?? []
        )
    }
}
