import CoreGraphics
import AnyKanaCore

/// キーとクリックとスクロールを聞くだけのイベントタップ。OS のイベントを Core の `InputEvent` に直して渡す。
/// 聞くだけ（listenOnly）なので、イベントを止めたり書き換えたりはしない。
@MainActor final class EventTap {
    private let onEvent: (InputEvent) -> Void
    private var port: CFMachPort?

    /// 入力監視の権限がないと作れない（nil を返す）。
    init?(onEvent: @escaping (InputEvent) -> Void) {
        self.onEvent = onEvent
        let types: [CGEventType] = [
            .flagsChanged, .keyDown, .leftMouseDown, .rightMouseDown, .otherMouseDown, .scrollWheel,
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        guard
            let port = CGEvent.tapCreate(
                tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
                eventsOfInterest: mask, callback: eventTapCallback,
                userInfo: Unmanaged.passUnretained(self).toOpaque())
        else { return nil }
        self.port = port
        // タップは main の run loop で動かす。callback も main スレッドで呼ばれる
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, port, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: port, enable: true)
    }

    fileprivate func receive(_ type: CGEventType, flags: CGEventFlags, isMomentum: Bool) {
        switch type {
        case .tapDisabledByTimeout, .tapDisabledByUserInput:
            // 処理が遅いと OS がタップを止める。止まったら自分で再開する
            logger.notice("event tap was disabled; enabling again")
            if let port { CGEvent.tapEnable(tap: port, enable: true) }
        case .flagsChanged:
            let modifiers = Modifiers(eventFlags: flags.rawValue)
            logger.debug("modifiers: \(String(modifiers.rawValue, radix: 2), privacy: .public)")
            onEvent(.modifiersChanged(modifiers))
        case .keyDown:
            onEvent(.keyDown)
        case .leftMouseDown, .rightMouseDown, .otherMouseDown:
            onEvent(.mouseDown)
        case .scrollWheel:
            // 指を離したあとの慣性のスクロールは、使う人の操作ではない。数えると、スクロールの直後の ⌘ が効かない
            if !isMomentum { onEvent(.scroll) }
        default:
            break
        }
    }
}

/// C の関数ポインタとして渡すので、外の値を捕まえられない。userInfo から EventTap を取り出す。
private func eventTapCallback(
    proxy: CGEventTapProxy, type: CGEventType, event: CGEvent, userInfo: UnsafeMutableRawPointer?
) -> Unmanaged<CGEvent>? {
    if let userInfo {
        let tap = Unmanaged<EventTap>.fromOpaque(userInfo).takeUnretainedValue()
        // CGEvent は Sendable でないので、要る値（種類と修飾キーの印、慣性のスクロールか）だけを取り出して渡す
        let flags = event.flags
        let isMomentum =
            type == .scrollWheel && event.getIntegerValueField(.scrollWheelEventMomentumPhase) != 0
        MainActor.assumeIsolated { tap.receive(type, flags: flags, isMomentum: isMomentum) }
    }
    return Unmanaged.passUnretained(event)
}
