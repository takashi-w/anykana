// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AnyKana",
    platforms: [.macOS(.v14)],
    targets: [
        // OS に触れない純粋なロジック（押し方の判定と、行き先の対応表）
        .target(name: "AnyKanaCore"),
        // OS につなぐ部分（イベントタップ、入力ソースの切り替え、設定の画面）
        .executableTarget(name: "AnyKana", dependencies: ["AnyKanaCore"]),
        .testTarget(name: "AnyKanaCoreTests", dependencies: ["AnyKanaCore"]),
    ]
)
