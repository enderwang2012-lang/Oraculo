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
        guard !colors.isEmpty else { return NipponColor.fallback }
        let key = PhraseStore.dayKey(for: date)
        let seed = "\(key)|color|\(InstallID.value)"

        let colorDispatch = phrase?.effectiveColorDispatch
        let pool = ColorMoodPicker.candidatePool(from: colors, dispatch: colorDispatch)
        if pool.isEmpty {
            // 兜底：通常 colors 非空且 ban 不会清空所有色；保险起见留这条路径。
            let index = PhraseStore.stableIndex(for: seed, count: colors.count)
            return colors[index]
        }
        return ColorMoodPicker.pick(
            from: pool,
            dispatch: colorDispatch,
            seed: seed,
            contextTags: context?.activeTags
        )
    }
}

/// 与 PhrasePicker 对称：从色板里按 colorMoods/colorBan 挑色。
enum ColorMoodPicker {
    /// 池低于此值时停止 ban，回落为只加权——避免长期看到同样几个色。
    static let minPoolSize = 30
    static let moodBoostMultiplier: Double = 2.0
    /// 情境亲和加权：命中当前 context 标签的色再乘此系数（与 mood 加权可叠乘）。
    static let contextBoostMultiplier: Double = 2.0
    /// 细色族加权：命中句 colorFamilies 的色再乘此系数（比 mood 更精确，故更强）。
    static let familyBoostMultiplier: Double = 3.0

    static func candidatePool(
        from colors: [NipponColor],
        dispatch: PhraseDispatch?
    ) -> [NipponColor] {
        guard let bans = dispatch?.colorBan, !bans.isEmpty else { return colors }
        let banSet = Set(bans)
        let filtered = colors.filter { color in
            color.moods.allSatisfy { !banSet.contains($0) }
        }
        return filtered.count >= minPoolSize ? filtered : colors
    }

    static func pick(
        from pool: [NipponColor],
        dispatch: PhraseDispatch?,
        seed: String,
        contextTags: Set<String>? = nil
    ) -> NipponColor {
        let moods = Set(dispatch?.colorMoods ?? [])
        let families = Set(dispatch?.colorFamilies ?? [])
        let ctx = contextTags ?? Set<String>()
        if moods.isEmpty && families.isEmpty && ctx.isEmpty {
            // 无情绪偏好、无色族偏好、无情境信息：均匀切片，与原行为一致。
            let index = PhraseStore.stableIndex(for: seed, count: pool.count)
            return pool[index]
        }

        let weights: [Double] = pool.map { color in
            var w = 1.0
            if !moods.isEmpty, color.moods.contains(where: { moods.contains($0) }) {
                w *= moodBoostMultiplier
            }
            if !families.isEmpty, families.contains(color.family) {
                w *= familyBoostMultiplier
            }
            if !ctx.isEmpty, color.contextTags.contains(where: { ctx.contains($0) }) {
                w *= contextBoostMultiplier
            }
            return w
        }
        let total = weights.reduce(0, +)
        guard total > 0 else { return pool[0] }

        // 与 PhrasePicker.seededUnit 同套：FNV-1a → [0,1) → 加权累加。
        let unit = Double(PhraseStore.stableHash64(for: seed) % 1_000_000) / 1_000_000.0
        var roll = unit * total
        for (color, weight) in zip(pool, weights) {
            roll -= weight
            if roll <= 0 { return color }
        }
        return pool.last ?? NipponColor.fallback
    }
}
