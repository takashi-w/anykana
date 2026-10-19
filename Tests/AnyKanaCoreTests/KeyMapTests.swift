import Testing
@testable import AnyKanaCore

@Suite("対応表")
struct KeyMapTests {
    @Test("置き直す前の設定: 左 ⌘ は英数")
    func defaultLeft() {
        #expect(KeyMap.default.destination(for: .leftCommand) == .eisu)
    }

    @Test("置き直す前の設定: 右 ⌘ はかな")
    func defaultRight() {
        #expect(KeyMap.default.destination(for: .rightCommand) == .kana)
    }

    @Test("置き直す前の設定: 右 ⌥ はボポモフォ")
    func defaultRightOption() {
        #expect(KeyMap.default.destination(for: .rightOption) == .inputSource(id: InputSourceID.zhuyin))
    }

    @Test("置き直す前の設定: 左 ⌥ と 🌐 は空けておく")
    func defaultEmpty() {
        #expect(KeyMap.default.destination(for: .leftOption) == nil)
        #expect(KeyMap.default.destination(for: .globe) == nil)
    }

    @Test("英数とかなは、JIS キーボードの 102 と 104 のキー")
    func eisuAndKanaKeyCodes() {
        #expect(Destination.eisu == .keyCode(102))
        #expect(Destination.kana == .keyCode(104))
    }

    @Test("割り当てたとおりに引く")
    func customBinding() {
        let map = KeyMap([.rightCommand: InputSourceID.zhuyin])
        #expect(map.destination(for: .rightCommand) == .inputSource(id: InputSourceID.zhuyin))
    }

    @Test("どの枠でも、ABC は英数のキー、日本語はかなのキー")
    func abcAndJapaneseOnAnySlot() {
        let map = KeyMap([.globe: InputSourceID.abc, .leftOption: InputSourceID.japanese])
        #expect(map.destination(for: .globe) == .eisu)
        #expect(map.destination(for: .leftOption) == .kana)
    }

    @Test("対応表にない枠は、行き先なし")
    func missingBinding() {
        let map = KeyMap([.leftCommand: InputSourceID.abc])
        #expect(map.destination(for: .rightCommand) == nil)
    }

    @Test("保存の形は、枠の名前 → 入力ソースの ID")
    func propertyList() {
        #expect(
            KeyMap.default.propertyList == [
                "leftCommand": InputSourceID.abc,
                "rightCommand": InputSourceID.japanese,
                "rightOption": InputSourceID.zhuyin,
            ])
    }

    @Test("保存の形から戻す")
    func fromPropertyList() {
        let map = KeyMap(propertyList: ["globe": InputSourceID.zhuyin, "leftCommand": InputSourceID.abc])
        #expect(map == KeyMap([.globe: InputSourceID.zhuyin, .leftCommand: InputSourceID.abc]))
    }

    @Test("保存して戻すと、同じ対応表になる")
    func roundTrip() {
        let map = KeyMap([.leftOption: "com.example.inputmethod.Cyrillic", .globe: InputSourceID.zhuyin])
        #expect(KeyMap(propertyList: map.propertyList) == map)
    }

    @Test("知らない枠の名前は、読み飛ばす（defaults write の書き間違いなど）")
    func unknownSlotName() {
        let map = KeyMap(propertyList: ["middleCommand": InputSourceID.abc, "globe": InputSourceID.zhuyin])
        #expect(map == KeyMap([.globe: InputSourceID.zhuyin]))
    }

    @Test("空の対応表も、空のまま戻す（すべて「なし」にしたとき）")
    func emptyPropertyList() {
        #expect(KeyMap(propertyList: [:]) == KeyMap([:]))
    }
}
