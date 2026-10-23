import Testing
@testable import AnyKanaCore

/// 2026-10-23 に macOS 26.5 で見た入力ソースの性質を、そのまま写したもの
private enum Sample {
    static let abc = InputSourceTraits(
        id: InputSourceID.abc, kind: .standalone, bundleID: nil, isEnabled: true, isSelectCapable: true)
    static let zhuyin = InputSourceTraits(
        id: InputSourceID.zhuyin, kind: .inputMode, bundleID: "com.apple.inputmethod.TCIM",
        isEnabled: true, isSelectCapable: true)
    static let traditionalChinese = InputSourceTraits(
        id: "com.apple.inputmethod.TCIM", kind: .inputMethod, bundleID: "com.apple.inputmethod.TCIM",
        isEnabled: true, isSelectCapable: false)
    /// 外したあとも、モード自身は「有効」と答える
    static let simplifiedPinyin = InputSourceTraits(
        id: "com.apple.inputmethod.SCIM.ITABC", kind: .inputMode, bundleID: "com.apple.inputmethod.SCIM",
        isEnabled: true, isSelectCapable: true)
    static let simplifiedChineseRemoved = InputSourceTraits(
        id: "com.apple.inputmethod.SCIM", kind: .inputMethod, bundleID: "com.apple.inputmethod.SCIM",
        isEnabled: false, isSelectCapable: false)
    static let ainu = InputSourceTraits(
        id: "com.apple.inputmethod.AinuIM.Ainu", kind: .inputMode, bundleID: "com.apple.inputmethod.AinuIM",
        isEnabled: false, isSelectCapable: true)
    static let dvorak = InputSourceTraits(
        id: "com.apple.keylayout.Dvorak", kind: .standalone, bundleID: nil, isEnabled: false, isSelectCapable: true)
}

@Suite("入力メニューに並ぶ（選べる）入力ソース")
struct SelectableInputSourcesTests {
    @Test("有効なキーボード配列は選べる")
    func enabledLayout() {
        #expect(SelectableInputSources.ids(from: [Sample.abc]) == [InputSourceID.abc])
    }

    @Test("有効でないものは選べない")
    func disabled() {
        #expect(SelectableInputSources.ids(from: [Sample.dvorak, Sample.ainu]) == [])
    }

    @Test("入力モードは、親の入力方式も有効なら選べる")
    func modeOfEnabledMethod() {
        #expect(
            SelectableInputSources.ids(from: [Sample.traditionalChinese, Sample.zhuyin]) == [InputSourceID.zhuyin])
    }

    @Test("入力モードは、自分が有効と答えても、親の入力方式が外れていれば選べない")
    func modeOfRemovedMethod() {
        #expect(SelectableInputSources.ids(from: [Sample.simplifiedChineseRemoved, Sample.simplifiedPinyin]) == [])
    }

    @Test("入力モードは、親の入力方式が見つからなければ選べない")
    func modeWithoutMethod() {
        #expect(SelectableInputSources.ids(from: [Sample.zhuyin]) == [])
    }

    @Test("入力方式そのもの（モードを束ねるもの）は並べない")
    func methodItself() {
        #expect(SelectableInputSources.ids(from: [Sample.traditionalChinese]) == [])
    }

    @Test("並びの順は、渡された順のまま")
    func keepsOrder() {
        let all = [
            Sample.zhuyin, Sample.dvorak, Sample.simplifiedPinyin, Sample.abc, Sample.traditionalChinese,
            Sample.simplifiedChineseRemoved, Sample.ainu,
        ]
        #expect(SelectableInputSources.ids(from: all) == [InputSourceID.zhuyin, InputSourceID.abc])
    }
}
