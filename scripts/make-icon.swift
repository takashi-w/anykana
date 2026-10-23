#!/usr/bin/env swift
// アプリのアイコン（Resources/AppIcon.icns）を描いて作る（2026-10-23）。
// 使い方: swift scripts/make-icon.swift（リポジトリの直下で）。途中の PNG は .build/AppIcon.iconset に置く
//
// 形は macOS のアイコンの格子に合わせる: 1024 の画面の中央に 824 の角丸の正方形。
// macOS 26 は、この形に収まらないアイコンを灰色の枠に入れて出すので、角丸の全体をキーにする。
// 絵は、色の場のキーに白い ⌘（どの入力ソースでも選べる）。決めた理由は docs/requirements.md の「アイコン」
import AppKit

let canvas: CGFloat = 1024
let body = NSRect(x: 100, y: 100, width: 824, height: 824)
let bodyRadius: CGFloat = 185

func color(_ hex: UInt32, _ alpha: CGFloat = 1) -> NSColor {
    NSColor(
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}

/// 色の場: 下地の色に、四隅から色を広げる。明るい色を角に寄せ、⌘ の後ろ（中央）は少し暗くする
func drawField(in path: NSBezierPath, brightness: CGFloat = 1) {
    // (色, 中心の x と y（0〜1）, 半径（幅に対する割合）)
    let spots: [(UInt32, CGFloat, CGFloat, CGFloat)] = [
        (0xE8452C, 0, 1, 0.55), (0xE89B1A, 1, 1, 0.5), (0x0F9D8A, 0, 0, 0.55), (0x3B5BDB, 1, 0, 0.55),
    ]
    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    color(0x3A2F9E).setFill()
    body.fill()
    for (hex, fx, fy, fr) in spots {
        let center = NSPoint(x: body.minX + body.width * fx, y: body.minY + body.height * fy)
        NSGradient(starting: color(hex), ending: color(hex, 0))!
            .draw(fromCenter: center, radius: 0, toCenter: center, radius: body.width * fr, options: [])
    }
    let middle = NSPoint(x: body.midX, y: body.midY + 30)
    NSGradient(starting: color(0x000000, 0.22), ending: color(0x000000, 0))!
        .draw(fromCenter: middle, radius: 0, toCenter: middle, radius: body.width * 0.42, options: [])
    if brightness < 1 {
        color(0x000000, 1 - brightness).setFill()
        body.fill()
    }
    NSGraphicsContext.restoreGraphicsState()
}

/// ⌘ の4つの輪の1つ。正方形の角から伸びる辺と、270° の弧。quadrant は 0 右上、1 左上、2 左下、3 右下
func commandLoop(center: NSPoint, a: CGFloat, r: CGFloat, quadrant: Int) -> NSBezierPath {
    let sx: CGFloat = (quadrant == 0 || quadrant == 3) ? 1 : -1
    let sy: CGFloat = (quadrant == 0 || quadrant == 1) ? 1 : -1
    let corner = NSPoint(x: center.x + sx * a, y: center.y + sy * a)
    let loopCenter = NSPoint(x: center.x + sx * (a + r), y: center.y + sy * (a + r))
    let path = NSBezierPath()
    path.move(to: corner)
    path.line(to: NSPoint(x: loopCenter.x, y: corner.y))
    // 右上の輪を -90° から 180° まで反時計回りに描き、ほかの象限は鏡に映す
    var mirror = AffineTransform()
    mirror.translate(x: loopCenter.x, y: loopCenter.y)
    mirror.scale(x: sx, y: sy)
    let arc = NSBezierPath()
    arc.appendArc(withCenter: .zero, radius: r, startAngle: -90, endAngle: 180, clockwise: false)
    arc.transform(using: mirror)
    path.append(arc)
    path.line(to: corner)
    return path
}

/// ⌘ を線で描く（フォントの字形より、太さと大きさを小さいサイズに合わせやすい）。size は全体の幅
func drawCommand(center: NSPoint, size: CGFloat, width: CGFloat) {
    let r = size / 6
    let a = r
    color(0xFFFFFF).setStroke()
    for quadrant in 0..<4 {
        let loop = commandLoop(center: center, a: a, r: r, quadrant: quadrant)
        loop.lineWidth = width
        loop.lineCapStyle = .round
        loop.lineJoinStyle = .round
        loop.stroke()
    }
    let square = NSBezierPath(rect: NSRect(x: center.x - a, y: center.y - a, width: 2 * a, height: 2 * a))
    square.lineWidth = width
    square.lineJoinStyle = .round
    square.stroke()
}

/// 1024 の座標で描く（原点は左下）
func drawIcon() {
    // 側面: 角丸の全体を暗くした色の場。上面を下だけ持ち上げるので、見えるのは下の縁だけ
    let bodyPath = NSBezierPath(roundedRect: body, xRadius: bodyRadius, yRadius: bodyRadius)
    drawField(in: bodyPath, brightness: 0.62)
    // 上面: 上と左右は外形にそろえる（暗い縁が上に回ると、光の向きと食い違って枠線に見える）
    let lip: CGFloat = 52
    let face = NSRect(x: body.minX, y: body.minY + lip, width: body.width, height: body.height - lip)
    drawField(in: NSBezierPath(roundedRect: face, xRadius: bodyRadius, yRadius: bodyRadius))
    drawCommand(center: NSPoint(x: face.midX, y: face.midY + 2), size: 400, width: 50)
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
