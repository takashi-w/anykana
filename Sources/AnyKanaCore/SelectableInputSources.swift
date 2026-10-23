/// 入力ソースのうち、選べるかを決めるのに要る性質。OS の入力ソースから写して渡す。
public struct InputSourceTraits: Sendable, Equatable {
    public enum Kind: Sendable, Equatable {
        /// 入力方式の中の1つのモード（注音、拼音など）
        case inputMode
        /// モードを束ねる入力方式（繁体中文など）。それ自体は選ばない
        case inputMethod
        /// キーボード配列など、親を持たないもの
        case standalone
    }

    public let id: String
    public let kind: Kind
    public let bundleID: String?
    public let isEnabled: Bool
    public let isSelectCapable: Bool

    public init(id: String, kind: Kind, bundleID: String?, isEnabled: Bool, isSelectCapable: Bool) {
        self.id = id
        self.kind = kind
        self.bundleID = bundleID
        self.isEnabled = isEnabled
        self.isSelectCapable = isSelectCapable
    }
}

/// 入っている入力ソースから、入力メニューに並ぶもの（選べるもの）を選ぶ。
///
/// macOS の「有効な入力ソース」の一覧は、長く動くプロセスの中では古いまま残り、外したものも並ぶ。
/// また、入力方式を外しても、その下のモードは自分を「有効」と答えることがある。
/// そのため、入っているものすべての性質から、モードは親の入力方式も有効かまで見て選ぶ。
public enum SelectableInputSources {
    /// 選べるものの ID を、渡された順のまま返す。
    public static func ids(from sources: [InputSourceTraits]) -> [String] {
        let enabledMethods = Set(
            sources.filter { $0.kind == .inputMethod && $0.isEnabled }.compactMap(\.bundleID))
        return sources.filter { source in
            guard source.isEnabled, source.isSelectCapable else { return false }
            switch source.kind {
            case .standalone: return true
            case .inputMethod: return false
            case .inputMode: return source.bundleID.map(enabledMethods.contains) ?? false
            }
        }.map(\.id)
    }
}
