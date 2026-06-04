import Foundation

struct Phrase: Codable, Identifiable, Hashable {
    let id: String
    let text: String
    /// 诗意英文 paraphrase（对齐 nipponcolors 罗马字注音层，非直译）
    let textEn: String
    let layer: String
    let emotionTheme: String
    let dispatch: PhraseDispatch?

    init(
        id: String,
        text: String,
        textEn: String = "",
        layer: String,
        emotionTheme: String,
        dispatch: PhraseDispatch? = nil
    ) {
        self.id = id
        self.text = text
        self.textEn = textEn
        self.layer = layer
        self.emotionTheme = emotionTheme
        self.dispatch = dispatch
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        text = try c.decode(String.self, forKey: .text)
        textEn = try c.decodeIfPresent(String.self, forKey: .textEn) ?? ""
        layer = try c.decode(String.self, forKey: .layer)
        emotionTheme = try c.decode(String.self, forKey: .emotionTheme)
        dispatch = try c.decodeIfPresent(PhraseDispatch.self, forKey: .dispatch)
    }

    private enum CodingKeys: String, CodingKey {
        case id, text, textEn, layer, emotionTheme, dispatch
    }

    /// 语料缺失时的统一兜底句（id="fallback"），全工程唯一来源。
    static let fallback = Phrase(
        id: "fallback",
        text: "先缓一缓",
        textEn: "Pause, and soften",
        layer: "anchor",
        emotionTheme: "light_comfort"
    )
}
