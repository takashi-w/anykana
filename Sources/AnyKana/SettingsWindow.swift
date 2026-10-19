import AnyKanaCore
import AppKit
import SwiftUI

/// 対応表を置き直す小さな画面。動いている AnyKana をもう一度開いたときだけ出す（要件の「決めたこと」）。
@MainActor final class SettingsWindow {
    private let store: KeyMapStore
    private var window: NSWindow?
    private var hosting: NSHostingController<SettingsView>?

    init(store: KeyMapStore) {
        self.store = store
    }

    func show() {
        store.reload()
        // 入力ソースは開くたびに一覧し直す（システム設定で足したり外したりしているかもしれない）
        let sources = InstalledInputSources.selectable()
        logger.debug("input sources: \(sources.map(\.name).joined(separator: ", "), privacy: .public)")
        let view = SettingsView(store: store, sources: sources)
        if let hosting, let window {
            hosting.rootView = view
            window.makeKeyAndOrderFront(nil)
        } else {
            let hosting = NSHostingController(rootView: view)
            let window = SettingsPanel(contentViewController: hosting)
            window.title = "AnyKana"
            window.styleMask = [.titled, .closable]
            window.isReleasedWhenClosed = false
            window.center()
            window.makeKeyAndOrderFront(nil)
            self.hosting = hosting
            self.window = window
        }
        // Dock に出さないアプリなので、自分で前に出す
        NSApp.activate()
        logger.info("showing the settings window")
    }
}

/// メニューのないアプリなので、⌘W と esc で閉じられるよう、窓が自分で受ける。
private final class SettingsPanel: NSWindow {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
            event.charactersIgnoringModifiers == "w"
        {
            performClose(nil)
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func cancelOperation(_ sender: Any?) {
        performClose(nil)
    }
}

struct SettingsView: View {
    let store: KeyMapStore
    let sources: [InputSourceInfo]

    var body: some View {
        Form {
            Section {
                ForEach(Slot.allCases, id: \.self) { slot in
                    Picker(selection: selection(for: slot)) {
                        Text("None").tag(String?.none)
                        ForEach(options(for: slot)) { source in
                            Text(source.name).tag(String?.some(source.id))
                        }
                    } label: {
                        SlotLabel(slot: slot)
                    }
                }
            } footer: {
                if store.keyMap.inputSources[.globe] != nil {
                    // macOS の 🌐 の巡回と二重に動かないように（要件の「決めたこと」）。リンクは設定を開くだけ
                    Text("globe.note")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // 終了は、割り当てとは別の節に置く。窓の右下（完了ボタンの位置）には置かない
            Section {
                Button("Quit AnyKana") { NSApp.terminate(nil) }
            }
        }
        .formStyle(.grouped)
        .frame(width: 360)
        .fixedSize(horizontal: false, vertical: true)
    }

    private func selection(for slot: Slot) -> Binding<String?> {
        Binding(
            get: { store.keyMap.inputSources[slot] },
            set: { store.assign($0, to: slot) })
    }

    /// 有効な入力ソースに、割り当て済みで今は入っていないものを足す（外したことが分かるように）。
    private func options(for slot: Slot) -> [InputSourceInfo] {
        guard let id = store.keyMap.inputSources[slot], !sources.contains(where: { $0.id == id }) else {
            return sources
        }
        return sources + [InputSourceInfo(id: id, name: String(localized: "\(id) (not installed)"))]
    }
}

/// 枠の名前。キーはキーボードの刻印のように枠で囲み、1つのキーを押すことを形で伝える。
/// キーを先に置いて縦にそろえ、左右はその後ろに添える。
struct SlotLabel: View {
    let slot: Slot

    var body: some View {
        HStack(spacing: 8) {
            Keycap(slot: slot)
            switch slot {
            case .leftCommand, .leftOption: Text("Left").foregroundStyle(.secondary)
            case .rightCommand, .rightOption: Text("Right").foregroundStyle(.secondary)
            case .globe: EmptyView()
            }
        }
    }
}

private struct Keycap: View {
    let slot: Slot

    var body: some View {
        Group {
            switch slot {
            case .leftCommand, .rightCommand: Text(verbatim: "⌘")
            case .leftOption, .rightOption: Text(verbatim: "⌥")
            case .globe: Image(systemName: "globe")
            }
        }
        .font(.system(size: 12, weight: .medium))
        .frame(width: 24, height: 20)
        .background(RoundedRectangle(cornerRadius: 5).strokeBorder(.tertiary))
    }
}
