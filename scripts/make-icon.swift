#!/usr/bin/env swift
// アプリのアイコン（Resources/AppIcon.icns）を描いて作る。仮置き（2026-10-19）。
// 使い方: swift scripts/make-icon.swift（リポジトリの直下で）。途中の PNG は .build/AppIcon.iconset に置く
//
// 形は macOS のアイコンの格子に合わせる: 1024 の画面の中央に 824 の角丸の正方形。
// macOS 26 は、この形に収まらないアイコンを灰色の枠に入れて出す。
// 絵は、設定の画面と同じキーの刻印。中に ⌘、下に A・あ・ㄅ（どの入力ソースでも選べる）。
import AppKit

let canvas: CGFloat = 1024

func color(_ hex: UInt32) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
}

func drawText(_ text: String, font: NSFont, color: NSColor, centerX: CGFloat, centerY: CGFloat) {
    let string = NSAttributedString(string: text, attributes: [.font: font, .foregroundColor: color])
    let size = string.size()
    string.draw(at: NSPoint(x: centerX - size.width / 2, y: centerY - size.height / 2))
}

/// 1024 の座標で描く（原点は左下）
func drawIcon() {
    // 下地: 角丸の正方形
    let body = NSRect(x: 100, y: 100, width: 824, height: 824)
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: 185, yRadius: 185)
    NSGradient(starting: color(0x6A8BFF), ending: color(0x3550D6))!.draw(in: bodyPath, angle: -90)

    // キーの刻印: 側面（少し下にずらした濃い色）と、上面
    let face = NSRect(x: 232, y: 262, width: 560, height: 530)
    let side = face.offsetBy(dx: 0, dy: -34)
    color(0x1F2E8A).withAlphaComponent(0.55).setFill()
    NSBezierPath(roundedRect: side, xRadius: 104, yRadius: 104).fill()
    let facePath = NSBezierPath(roundedRect: face, xRadius: 104, yRadius: 104)
    NSGradient(starting: color(0xFFFFFF), ending: color(0xE6E9F2))!.draw(in: facePath, angle: -90)

    // ⌘ と、その下に A・あ・ㄅ
    drawText(
        "⌘", font: .systemFont(ofSize: 300, weight: .medium), color: color(0x252B47),
        centerX: face.midX, centerY: face.midY + 58)
    drawText(
        "A  あ  ㄅ", font: .systemFont(ofSize: 76, weight: .semibold), color: color(0x3550D6),
        centerX: face.midX, centerY: face.minY + 92)
}

func png(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    // 大きさごとに縮めた画像ではなく、その大きさで描き直す（小さいときもにじまない）
    let scale = CGFloat(pixels) / canvas
    NSGraphicsContext.current!.cgContext.scaleBy(x: scale, y: scale)
    drawIcon()
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let iconset = URL(fileURLWithPath: ".build/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    try png(pixels: points).write(to: iconset.appendingPathComponent("icon_\(points)x\(points).png"))
    try png(pixels: points * 2).write(to: iconset.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconset.path, "-o", "Resources/AppIcon.icns"]
try iconutil.run()
iconutil.waitUntilExit()
print(iconutil.terminationStatus == 0 ? "作った: Resources/AppIcon.icns" : "iconutil が失敗した")
