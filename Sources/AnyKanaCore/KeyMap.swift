/// 枠（Slot）に、入力ソースの ID を割り当てる対応表。押し方の判定は知らない。
public struct KeyMap: Sendable, Equatable {
    /// 枠 → 入力ソースの ID
    public var inputSources: [Slot: String]

    public init(_ inputSources: [Slot: String]) {
        self.inputSources = inputSources
    }

    public func destination(for slot: Slot) -> Destination? {
        inputSources[slot].map(Destination.init(inputSourceID:))
    }

    /// 保存の形（枠の名前 → 入力ソースの ID）から作る。知らない枠の名前は読み飛ばす。
    public init(propertyList: [String: String]) {
        var inputSources: [Slot: String] = [:]
        for (name, id) in propertyList {
            if let slot = Slot(rawValue: name) { inputSources[slot] = id }
        }
        self.init(inputSources)
    }

    /// 保存の形。UserDefaults にそのまま置け、`defaults write` でも書ける。
    public var propertyList: [String: String] {
        Dictionary(uniqueKeysWithValues: inputSources.map { ($0.key.rawValue, $0.value) })
    }

    /// 使う人が置き直す前の設定。
    public static let `default` = KeyMap([
        .leftCommand: InputSourceID.abc,
        .rightCommand: InputSourceID.japanese,
        .rightOption: InputSourceID.zhuyin,
    ])
}
