/// 行き先。どうやって切り替えるかは、アプリの側が場合ごとに決める。
public enum Destination: Hashable, Sendable, Codable {
    /// そのキーを押したふりをする。
    case keyCode(UInt16)
    /// 入力ソースを ID で直接選ぶ。
    case inputSource(id: String)

    /// JIS キーボードの「英数」キー
    public static let eisu = Destination.keyCode(102)
    /// JIS キーボードの「かな」キー
    public static let kana = Destination.keyCode(104)

    /// 入力ソースの ID から、行き先を決める。ABC と日本語（ローマ字入力）は、英数とかなのキーを送る。
    /// ほかは ID で選ぶ。
    public init(inputSourceID id: String) {
        switch id {
        case InputSourceID.abc: self = .eisu
        case InputSourceID.japanese: self = .kana
        default: self = .inputSource(id: id)
        }
    }
}
