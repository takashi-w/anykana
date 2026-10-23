import AppKit
import Carbon
import CoreGraphics
import AnyKanaCore

/// 行き先（Destination）を、実際の切り替えに直す。
@MainActor final class InputSourceSelector {
    /// API で選んでから、次に進むまで待つ時間。spike（zhuyin-probe の prev）と同じ
    private static let stepDelay: Duration = .milliseconds(50)
    /// 目的の入力ソースと ⌃Space の間にはさむ入力ソース
    private static let abcID = InputSourceID.abc

    func select(_ destination: Destination) {
        switch destination {
        case .keyCode(let keyCode):
            postKey(CGKeyCode(keyCode))
        case .inputSource(let id):
            selectInputSource(id: id)
        }
    }

    /// そのキーを押して離したふりをする（英数 102、かな 104）。アクセシビリティの権限が要る。
    private func postKey(_ keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)
        for keyDown in [true, false] {
            let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown)
            // ⌘ を離した直後に送るので修飾キーはないはずだが、念のため空にする
            event?.flags = []
            event?.post(tap: .cghidEventTap)
        }
        logger.info("posted key \(keyCode)")
    }

    /// 入力ソースを ID で選ぶ。API で選ぶだけでは表示しか変わらないことがあるので、目的 → ABC と選んでから
    /// ⌃Space（前の入力ソースを選択）を送り、macOS 自身の切り替えで目的に戻す（要件の「決めたこと」）。
    /// もうその入力ソースなら、何もしない。
    private func selectInputSource(id: String) {
        let sources = InstalledInputSources.selectableSources()
        guard let source = Self.find(id, in: sources), let abc = Self.find(Self.abcID, in: sources) else {
            logger.error("no enabled input source: \(id, privacy: .public) or ABC")
            return
        }
        guard Self.currentSourceID() != id else {
            logger.info("already on \(id, privacy: .public)")
            return
        }
        Task { @MainActor in
            TISSelectInputSource(source)
            try? await Task.sleep(for: Self.stepDelay)
            TISSelectInputSource(abc)
            try? await Task.sleep(for: Self.stepDelay)
            Self.postControlSpace()
            logger.info("selected \(id, privacy: .public)")
        }
    }

    /// ⌃ を押したまま Space を押して離し、⌃ も離したふりをする。
    private static func postControlSpace() {
        let source = CGEventSource(stateID: .hidSystemState)
        let control: CGKeyCode = 59
        let space: CGKeyCode = 49
        let keys: [(CGKeyCode, Bool, CGEventFlags)] = [
            (control, true, .maskControl),
            (space, true, .maskControl),
            (space, false, .maskControl),
            (control, false, []),
        ]
        for (keyCode, keyDown, flags) in keys {
            let event = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: keyDown)
            event?.flags = flags
            event?.post(tap: .cghidEventTap)
        }
    }

    private static func find(_ id: String, in sources: [TISInputSource]) -> TISInputSource? {
        sources.first { stringProperty($0, kTISPropertyInputSourceID) == id }
    }

    private static func currentSourceID() -> String? {
        let source = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        return stringProperty(source, kTISPropertyInputSourceID)
    }
}

/// 設定の画面に並べる入力ソース
struct InputSourceInfo: Identifiable, Hashable {
    let id: String
    let name: String
}

enum InstalledInputSources {
    /// 今有効で、選べるキーボードの入力ソース（入力メニューに並ぶもの）
    static func selectable() -> [InputSourceInfo] {
        selectableSources().compactMap { source in
            guard let id = stringProperty(source, kTISPropertyInputSourceID) else { return nil }
            return InputSourceInfo(id: id, name: stringProperty(source, kTISPropertyLocalizedName) ?? id)
        }
    }

    /// 「有効なものだけ」の一覧は、長く動くプロセスでは外したものも残るので、入っているものすべてから選ぶ
    /// （AnyKanaCore の SelectableInputSources）。
    static func selectableSources() -> [TISInputSource] {
        let filter =
            [kTISPropertyInputSourceCategory as String: kTISCategoryKeyboardInputSource as String] as CFDictionary
        let sources = TISCreateInputSourceList(filter, true)?.takeRetainedValue() as? [TISInputSource] ?? []
        let ids = Set(SelectableInputSources.ids(from: sources.compactMap(traits)))
        return sources.filter { stringProperty($0, kTISPropertyInputSourceID).map(ids.contains) ?? false }
    }

    private static func traits(_ source: TISInputSource) -> InputSourceTraits? {
        guard let id = stringProperty(source, kTISPropertyInputSourceID) else { return nil }
        let type = stringProperty(source, kTISPropertyInputSourceType)
        let kind: InputSourceTraits.Kind =
            if type == kTISTypeKeyboardInputMode as String {
                .inputMode
            } else if type == kTISTypeKeyboardInputMethodModeEnabled as String {
                .inputMethod
            } else {
                // キーボード配列と、モードを持たない入力方式は、それ自体を選ぶ
                .standalone
            }
        return InputSourceTraits(
            id: id, kind: kind, bundleID: stringProperty(source, kTISPropertyBundleID),
            isEnabled: boolProperty(source, kTISPropertyInputSourceIsEnabled),
            isSelectCapable: boolProperty(source, kTISPropertyInputSourceIsSelectCapable))
    }
}

private func stringProperty(_ source: TISInputSource, _ key: CFString) -> String? {
    guard let pointer = TISGetInputSourceProperty(source, key) else { return nil }
    return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
}

private func boolProperty(_ source: TISInputSource, _ key: CFString) -> Bool {
    guard let pointer = TISGetInputSourceProperty(source, key) else { return false }
    return CFBooleanGetValue(Unmanaged<CFBoolean>.fromOpaque(pointer).takeUnretainedValue())
}
