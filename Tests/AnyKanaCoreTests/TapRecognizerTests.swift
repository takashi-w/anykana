import Testing
@testable import AnyKanaCore

/// 出来事を順に渡して、出てきた枠を集める。
private func taps(_ events: [InputEvent]) -> [Slot] {
    var recognizer = TapRecognizer()
    return events.compactMap { recognizer.handle($0) }
}

@Suite("単押し")
struct SingleTapTests {
    @Test("左 ⌘ を押して離すと、左 ⌘ の枠")
    func leftCommand() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
        ]) == [.leftCommand])
    }

    @Test("右 ⌘ を押して離すと、右 ⌘ の枠")
    func rightCommand() {
        #expect(taps([
            .modifiersChanged(.rightCommand),
            .modifiersChanged([]),
        ]) == [.rightCommand])
    }

    @Test("左 ⌥ を押して離すと、左 ⌥ の枠")
    func leftOption() {
        #expect(taps([
            .modifiersChanged(.leftOption),
            .modifiersChanged([]),
        ]) == [.leftOption])
    }

    @Test("右 ⌥ を押して離すと、右 ⌥ の枠")
    func rightOption() {
        #expect(taps([
            .modifiersChanged(.rightOption),
            .modifiersChanged([]),
        ]) == [.rightOption])
    }

    @Test("🌐 を押して離すと、🌐 の枠")
    func globe() {
        #expect(taps([
            .modifiersChanged(.fn),
            .modifiersChanged([]),
        ]) == [.globe])
    }

    @Test("スクロールしたあとで ⌘ を押して離せば、効く")
    func scrollBeforeCommand() {
        #expect(taps([
            .scroll,
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
        ]) == [.leftCommand])
    }

    @Test("長く押していても、ほかに何も起きなければ、その枠")
    func longPress() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
        ]) == [.leftCommand])
    }

    @Test("続けて押せば、そのたびに枠を返す")
    func repeated() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
            .keyDown,
            .modifiersChanged(.rightCommand),
            .modifiersChanged([]),
        ]) == [.leftCommand, .rightCommand])
    }
}

@Suite("押したキーのほかに何か起きたら、切り替えない")
struct CancelTests {
    @Test("⌘ を押したままキーを押した（⌘C）")
    func commandAndKey() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .keyDown,
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("⌘ を押したままクリックした（⌘クリック）")
    func commandAndClick() {
        #expect(taps([
            .modifiersChanged(.rightCommand),
            .mouseDown,
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("⌘ を押したままスクロールした（Figma や地図で拡大する）")
    func commandAndScroll() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .scroll,
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("⌥ を押したままキーを押した（⌥E で é を打つ）")
    func optionAndKey() {
        #expect(taps([
            .modifiersChanged(.rightOption),
            .keyDown,
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("右 ⌘ を押したまま右 ⌥ を押した")
    func commandThenOption() {
        #expect(taps([
            .modifiersChanged(.rightCommand),
            .modifiersChanged([.rightCommand, .rightOption]),
            .modifiersChanged(.rightCommand),
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("⌘ を押したまま Shift を押した")
    func commandThenShift() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .modifiersChanged([.leftCommand, .others]),
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("Shift を押したまま ⌘ をタップした（⌘英かな とは変えた）")
    func shiftThenCommand() {
        #expect(taps([
            .modifiersChanged(.others),
            .modifiersChanged([.others, .leftCommand]),
            .modifiersChanged(.others),
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("Shift を押したまま ⌘ を押し、Shift を先に離した")
    func shiftThenCommandReleaseShiftFirst() {
        #expect(taps([
            .modifiersChanged(.others),
            .modifiersChanged([.others, .leftCommand]),
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("左右の ⌘ を両方押した")
    func bothCommands() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .modifiersChanged([.leftCommand, .rightCommand]),
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
        ]).isEmpty)
    }

    @Test("やめたあとでも、次に押して離せば効く")
    func recoversAfterCancel() {
        #expect(taps([
            .modifiersChanged(.leftCommand),
            .keyDown,
            .modifiersChanged([]),
            .modifiersChanged(.leftCommand),
            .modifiersChanged([]),
        ]) == [.leftCommand])
    }
}

@Suite("取りこぼし")
struct MissedEventTests {
    @Test("押したのを見ていないまま離されたら、何もしない")
    func releaseWithoutPress() {
        #expect(taps([
            .modifiersChanged([]),
        ]).isEmpty)
    }
}
