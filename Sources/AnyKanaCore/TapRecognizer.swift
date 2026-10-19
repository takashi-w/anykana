/// 出来事の並びから、どの枠のキーを単独で押して離したかを読み取る。行き先は知らない。
///
/// 「何も押されていない状態から枠のキーを1つだけ押し、ほかに何も起きないまま、すべて離した」ときに、その枠を返す。
/// 途中でほかのことが起きたら、すべて離すまで何も返さない。
public struct TapRecognizer: Sendable {
    /// いま押されている修飾キー（最後に受け取った全体）
    private var held: Modifiers = []
    /// 単独で押して離したことになりうる枠。途中で何か起きたら nil にする
    private var candidate: Slot?

    public init() {}

    public mutating func handle(_ event: InputEvent) -> Slot? {
        switch event {
        case .keyDown, .mouseDown, .scroll:
            if !held.isEmpty { candidate = nil }
            return nil

        case .modifiersChanged(let modifiers):
            defer { held = modifiers }

            if modifiers.isEmpty {
                defer { candidate = nil }
                return candidate
            }
            if held.isEmpty {
                // 何も押されていない状態から押し始めた。枠のキーを1つだけなら、候補になる
                candidate = Self.lone(modifiers)
            } else if Self.lone(modifiers) != candidate {
                // 押し始めのキーだけ、という状態から外れた
                candidate = nil
            }
            return nil
        }
    }

    /// 枠のキーが1つだけ押されていて、ほかに何も押されていないなら、その枠
    private static func lone(_ modifiers: Modifiers) -> Slot? {
        switch modifiers {
        case .leftCommand: .leftCommand
        case .rightCommand: .rightCommand
        case .leftOption: .leftOption
        case .rightOption: .rightOption
        case .fn: .globe
        default: nil
        }
    }
}
