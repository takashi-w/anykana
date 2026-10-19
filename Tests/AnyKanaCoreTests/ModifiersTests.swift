import Testing
@testable import AnyKanaCore

/// CGEventFlags の生の値（CoreGraphics の maskCommand などと、IOKit の NX_DEVICE…KEYMASK）
private enum Flag {
    static let leftCommandDevice: UInt64 = 0x08  // NX_DEVICELCMDKEYMASK
    static let rightCommandDevice: UInt64 = 0x10  // NX_DEVICERCMDKEYMASK
    static let leftOptionDevice: UInt64 = 0x20  // NX_DEVICELALTKEYMASK
    static let rightOptionDevice: UInt64 = 0x40  // NX_DEVICERALTKEYMASK
    static let capsLock: UInt64 = 0x0001_0000  // maskAlphaShift
    static let shift: UInt64 = 0x0002_0000
    static let control: UInt64 = 0x0004_0000
    static let option: UInt64 = 0x0008_0000  // maskAlternate
    static let command: UInt64 = 0x0010_0000
    static let numericPad: UInt64 = 0x0020_0000
    static let fn: UInt64 = 0x0080_0000  // maskSecondaryFn
    static let nonCoalesced: UInt64 = 0x0100
}

@Suite("OS の修飾キーの印を Modifiers に直す")
struct ModifiersFromEventFlagsTests {
    @Test("何も押されていない")
    func none() {
        #expect(Modifiers(eventFlags: 0) == [])
    }

    @Test("左 ⌘")
    func leftCommand() {
        #expect(Modifiers(eventFlags: Flag.command | Flag.leftCommandDevice) == .leftCommand)
    }

    @Test("右 ⌘")
    func rightCommand() {
        #expect(Modifiers(eventFlags: Flag.command | Flag.rightCommandDevice) == .rightCommand)
    }

    @Test("左右の ⌘")
    func bothCommands() {
        let flags = Flag.command | Flag.leftCommandDevice | Flag.rightCommandDevice
        #expect(Modifiers(eventFlags: flags) == [.leftCommand, .rightCommand])
    }

    @Test("⌘ なのに左右が分からないときは、ほかの修飾キーとして扱う（切り替えない側に倒す）")
    func commandWithoutSide() {
        #expect(Modifiers(eventFlags: Flag.command) == .others)
    }

    @Test("左 ⌥")
    func leftOption() {
        #expect(Modifiers(eventFlags: Flag.option | Flag.leftOptionDevice) == .leftOption)
    }

    @Test("右 ⌥")
    func rightOption() {
        #expect(Modifiers(eventFlags: Flag.option | Flag.rightOptionDevice) == .rightOption)
    }

    @Test("⌥ なのに左右が分からないときは、ほかの修飾キーとして扱う（切り替えない側に倒す）")
    func optionWithoutSide() {
        #expect(Modifiers(eventFlags: Flag.option) == .others)
    }

    @Test("fn（🌐）")
    func fn() {
        #expect(Modifiers(eventFlags: Flag.fn) == .fn)
    }

    @Test("右 ⌘ と右 ⌥")
    func rightCommandAndRightOption() {
        let flags = Flag.command | Flag.rightCommandDevice | Flag.option | Flag.rightOptionDevice
        #expect(Modifiers(eventFlags: flags) == [.rightCommand, .rightOption])
    }

    @Test("Shift・Control は、ほかの修飾キー", arguments: [Flag.shift, Flag.control])
    func others(flag: UInt64) {
        #expect(Modifiers(eventFlags: flag) == .others)
    }

    @Test("Shift と左 ⌘")
    func shiftAndLeftCommand() {
        let flags = Flag.shift | Flag.command | Flag.leftCommandDevice
        #expect(Modifiers(eventFlags: flags) == [.leftCommand, .others])
    }

    @Test("CapsLock・テンキー・そのほかの印は数えない", arguments: [Flag.capsLock, Flag.numericPad, Flag.nonCoalesced])
    func ignored(flag: UInt64) {
        #expect(Modifiers(eventFlags: flag) == [])
        #expect(Modifiers(eventFlags: flag | Flag.command | Flag.leftCommandDevice) == .leftCommand)
    }
}
