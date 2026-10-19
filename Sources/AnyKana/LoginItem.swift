import Foundation
import ServiceManagement

/// ログイン時に起動するよう、最初の1回だけ登録する。登録すると、システム設定の「ログイン項目」に出る。
/// 使う人がそこでオフにしたら、その選択を守る（もう一度は登録しない）。
@MainActor enum LoginItem {
    private static let registeredKey = "registeredLoginItem"

    static func registerOnce() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: registeredKey) else { return }
        do {
            try SMAppService.mainApp.register()
            defaults.set(true, forKey: registeredKey)
            logger.info("registered as a login item")
        } catch {
            logger.error("could not register as a login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
