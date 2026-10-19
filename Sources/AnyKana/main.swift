import AppKit
import AnyKanaCore
import os

let bundleID = "io.github.takashi-w.anykana"
let logger = Logger(subsystem: bundleID, category: "app")

/// 出来事を受けて、どの枠を押したかを読み、行き先を引いて、切り替える。
@MainActor final class AppController {
    private var recognizer = TapRecognizer()
    private let store: KeyMapStore
    private let selector = InputSourceSelector()
    private var tap: EventTap?

    init(store: KeyMapStore) {
        self.store = store
    }

    func start() {
        // 入力監視（キーを聞く）とアクセシビリティ（キーを送る）。初回はシステム設定の案内が出る
        if !CGPreflightListenEventAccess() { CGRequestListenEventAccess() }
        if !CGPreflightPostEventAccess() { CGRequestPostEventAccess() }
        startTap()
    }

    /// 権限がまだなら作れないので、許可されるまで 2 秒ごとに試す。
    private func startTap() {
        if let tap = EventTap(onEvent: { [weak self] in self?.handle($0) }) {
            self.tap = tap
            logger.info("event tap started")
            return
        }
        logger.notice("waiting for the Input Monitoring permission")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.startTap()
        }
    }

    private func handle(_ event: InputEvent) {
        guard let slot = recognizer.handle(event) else { return }
        logger.info("\(String(describing: slot), privacy: .public)")
        guard let destination = store.keyMap.destination(for: slot) else { return }
        selector.select(destination)
    }
}

/// 動いている AnyKana をもう一度開くと（Spotlight や Finder、`open`）、設定の画面を出す。
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    private let settings: SettingsWindow

    init(settings: SettingsWindow) {
        self.settings = settings
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        settings.show()
        return false
    }
}

// すでに AnyKana が動いていたら、あとから起動した方は何もせずに終わる（両方動くと、二重に切り替わる）
let me = ProcessInfo.processInfo.processIdentifier
if NSRunningApplication.runningApplications(withBundleIdentifier: bundleID)
    .contains(where: { $0.processIdentifier != me })
{
    logger.notice("AnyKana is already running; quitting")
    exit(0)
}

let app = NSApplication.shared
// Dock にもアプリの切り替えにも出さない（Info.plist の LSUIElement と同じ）
app.setActivationPolicy(.accessory)
let store = KeyMapStore()
let delegate = AppDelegate(settings: SettingsWindow(store: store))
app.delegate = delegate
let controller = AppController(store: store)
controller.start()
// swift run（.app に組んでいないとき）は、ログイン項目にしない
if Bundle.main.bundleIdentifier == bundleID { LoginItem.registerOnce() }
app.run()
