/// 単独で押して離すと、割り当てた行き先にするキー（枠）。行き先は知らない（行き先は `KeyMap` が引く）。
/// rawValue は、対応表を保存するときの枠の名前（`defaults write` でも書く）。
public enum Slot: String, Hashable, Sendable, Codable, CaseIterable {
    case leftCommand, rightCommand, leftOption, rightOption, globe
}
