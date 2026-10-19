/// Core が受け取る出来事。アプリの側が、OS のイベント（CGEvent）をこの形に直して渡す。
public enum InputEvent: Sendable, Equatable {
    /// 修飾キーが変わった。変わったあとの、押されている修飾キーのすべてを持つ
    /// （差分ではなく全体を持つので、途中のイベントを取りこぼしても次で追いつける）。
    case modifiersChanged(Modifiers)
    /// 修飾キーでないキーが押された。
    case keyDown
    /// マウスやトラックパッドのボタンが押された。
    case mouseDown
    /// 使う人がスクロールした（指を離したあとの慣性のスクロールは、アプリの側で外す）。
    case scroll
}

/// 押されている修飾キー。枠になるキー（左右の ⌘、左右の ⌥、fn（🌐））を見分け、ほかの修飾キー
/// （Shift・Control）はまとめて `others` にする。CapsLock は入れない（オンのあいだずっと立っている印なので）。
public struct Modifiers: OptionSet, Sendable, Hashable {
    public let rawValue: UInt8
    public init(rawValue: UInt8) { self.rawValue = rawValue }

    public static let leftCommand = Modifiers(rawValue: 1 << 0)
    public static let rightCommand = Modifiers(rawValue: 1 << 1)
    public static let leftOption = Modifiers(rawValue: 1 << 2)
    public static let rightOption = Modifiers(rawValue: 1 << 3)
    public static let fn = Modifiers(rawValue: 1 << 4)
    public static let others = Modifiers(rawValue: 1 << 5)

    /// OS の修飾キーの印（CGEventFlags の rawValue）から作る。
    /// Core は CoreGraphics を import しないので、生の値で受ける。
    public init(eventFlags: UInt64) {
        self = []
        insertSided(
            eventFlags, key: EventFlag.command,
            left: (EventFlag.leftCommandDevice, .leftCommand),
            right: (EventFlag.rightCommandDevice, .rightCommand))
        insertSided(
            eventFlags, key: EventFlag.option,
            left: (EventFlag.leftOptionDevice, .leftOption),
            right: (EventFlag.rightOptionDevice, .rightOption))
        if eventFlags & EventFlag.fn != 0 { insert(.fn) }
        if eventFlags & EventFlag.others != 0 { insert(.others) }
    }

    /// 左右のある修飾キー（⌘ と ⌥）を、デバイスのビットで左右に分けて入れる。
    private mutating func insertSided(
        _ eventFlags: UInt64, key: UInt64,
        left: (device: UInt64, modifier: Modifiers), right: (device: UInt64, modifier: Modifiers)
    ) {
        guard eventFlags & key != 0 else { return }
        let isLeft = eventFlags & left.device != 0
        let isRight = eventFlags & right.device != 0
        if isLeft { insert(left.modifier) }
        if isRight { insert(right.modifier) }
        // 左右が分からないときは、切り替えない側に倒す
        if !isLeft && !isRight { insert(.others) }
    }
}

/// CGEventFlags の生の値。CapsLock（maskAlphaShift）とテンキー（maskNumericPad）は、
/// 押している間だけの印ではないので見ない。
private enum EventFlag {
    static let leftCommandDevice: UInt64 = 0x08  // NX_DEVICELCMDKEYMASK
    static let rightCommandDevice: UInt64 = 0x10  // NX_DEVICERCMDKEYMASK
    static let leftOptionDevice: UInt64 = 0x20  // NX_DEVICELALTKEYMASK
    static let rightOptionDevice: UInt64 = 0x40  // NX_DEVICERALTKEYMASK
    static let command: UInt64 = 0x0010_0000  // maskCommand
    static let option: UInt64 = 0x0008_0000  // maskAlternate
    static let fn: UInt64 = 0x0080_0000  // maskSecondaryFn
    /// maskShift・maskControl
    static let others: UInt64 = 0x0002_0000 | 0x0004_0000
}
