import AnyKanaCore
import Foundation
import Observation

/// 対応表を UserDefaults に残す。設定の画面が書き、AppController が引く。
/// 形は「枠の名前 → 入力ソースの ID」なので、`defaults write` でも書き換えられる。
@MainActor @Observable final class KeyMapStore {
    private static let defaultsKey = "keyMap"
    private(set) var keyMap: KeyMap

    init() {
        keyMap = Self.load()
    }

    /// `defaults write` で書き換えられていたら、それを読み直す。
    func reload() {
        keyMap = Self.load()
    }

    /// その枠に入力ソースを割り当てる。nil なら空ける。
    func assign(_ id: String?, to slot: Slot) {
        keyMap.inputSources[slot] = id
        UserDefaults.standard.set(keyMap.propertyList, forKey: Self.defaultsKey)
        logger.info("\(slot.rawValue, privacy: .public) -> \(id ?? "none", privacy: .public)")
    }

    /// 選べる入力ソースの割り当てだけを残し、外した入力ソースの枠を空ける（要件の「決めたこと」）。
    func keepOnly(available ids: [String]) {
        let kept = keyMap.keepingOnly(available: ids)
        guard kept != keyMap else { return }
        for (slot, id) in keyMap.inputSources where kept.inputSources[slot] == nil {
            logger.info("\(slot.rawValue, privacy: .public): \(id, privacy: .public) was removed")
        }
        keyMap = kept
        UserDefaults.standard.set(keyMap.propertyList, forKey: Self.defaultsKey)
    }

    private static func load() -> KeyMap {
        // 置き直したことがなければ、置き直す前の設定
        guard let saved = UserDefaults.standard.dictionary(forKey: defaultsKey) else { return .default }
        return KeyMap(propertyList: saved.compactMapValues { $0 as? String })
    }
}
