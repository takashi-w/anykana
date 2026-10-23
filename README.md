# AnyKana

**Tap ⌘ to pick any input source.**

Picks any input source when you press ⌘, ⌥, or 🌐 alone. Left ⌘ picks ABC and right ⌘ picks Japanese, like ⌘英かな (cmd-eikana). You can also give an input source to left ⌥, right ⌥, and 🌐. Each key always goes to its own input source, so you do not need to check which one you are on.

Built for personal use. Source only: build it on your own Mac (see below). No support is offered. Pull requests may not be reviewed. Forks are welcome. Tested on macOS 26.5 with Apple Silicon.

キーを単独で押して離すだけで、ほしい入力ソースを直接選ぶ Mac の常駐アプリです。左 ⌘ で英数、右 ⌘ でかなにします（⌘英かな と同じ）。左右の ⌥ と 🌐 にも入力ソースを割り当てられ、5つまで一発で選べます（ボポモフォ（注音）など）。Control + Space や 🌐 の巡回と違い、今どの入力ソースかを気にしなくてよいのが芯です。

個人で使うための道具です。ソースだけを公開しているので、自分の Mac でビルドして使います（下の「使い始める」）。サポートはしません。プルリクエストは見ないことがあります。フォークは歓迎します。

最初の割り当ては、左 ⌘ で英数、右 ⌘ でかな、右 ⌥ でボポモフォです。ログイン時に起動し、二重には起動しません。メニューバーはなく、動いている AnyKana をもう一度開くと、割り当てを置き直す小さな画面が出ます。

## 文書の地図

| 知りたいこと | 読むもの |
| --- | --- |
| 何を作るか、なぜ作るか、何をどう決めたか（要件の正本、MVV） | `docs/requirements.md` |
| 今どこまでできたか、実機での確かめ方 | `docs/progress.md` |

## 構成

Swift Package です。Xcode は使わず、Command Line Tools 26.6（Swift 6.3.3、SDK は macOS 26.5）でビルドします。macOS 26.5（Tahoe）、Apple Silicon で確かめています。

```
Sources/AnyKanaCore/     OS に触れない純粋なロジック（どの枠を押したかの判定と、行き先の対応表）。テストする所
Sources/AnyKana/        OS につなぐ部分（イベントタップ、入力ソースの切り替え、設定の画面）。実機で確かめる所
Tests/AnyKanaCoreTests/  Swift Testing のテスト（Command Line Tools だけでは XCTest は使えない）
Resources/Info.plist    アプリの情報（Bundle ID、Dock に出さない LSUIElement）
Resources/*.lproj      画面の文言（英語と日本語。システムの言語に従う）
Resources/AppIcon.icns アイコン。scripts/make-icon.swift で描いて作る
scripts/build-app.sh   .app に組んで、自己署名の証明書で署名し、~/Applications に置く
scripts/test.sh        swift test を動かす（Command Line Tools だけのときに要る場所を足す）
```

- 権限は2つ要る。入力監視（キーを聞く）とアクセシビリティ（英数とかなのキーを送る。⌃Space を送る）
- 権限は Bundle ID と署名した証明書でアプリを見分けている。同じ証明書（`scripts/build-app.sh` の `SIGN_IDENTITY`）で署名し続ければ、作り直しても付け直さなくてよい
- `scripts/build-app.sh` で署名するとき、キーチェーンのパスワードを聞かれることがある（codesign が `AnyKana Dev` の秘密鍵を使うため）。「常に許可」を選ぶと、次からは聞かれない

## 使い始める

リポジトリのほかに要るものはない。証明書は、Mac ごとに作る（秘密鍵はその Mac のキーチェーンの中だけにある）。

1. Command Line Tools を入れる: `xcode-select --install`。Swift 6.0 以上ならよい（`swift --version`）
2. 署名の証明書を作る。キーチェーンアクセスのメニュー「キーチェーンアクセス」→「証明書アシスタント」→「証明書を作成…」で:
   - 名前: `AnyKana Dev`（`scripts/build-app.sh` の `SIGN_IDENTITY` と同じ）
   - 固有名のタイプ: 自己署名ルート
   - 証明書のタイプ: コード署名
   - 有効期間は、何もしないと1年。「デフォルトを無効にする」にチェックを入れると、長くできる（例: 3650 日）
3. 証明書を確かめる: `security find-identity -p codesigning` に `"AnyKana Dev"` が出ればよい。`CSSMERR_TP_NOT_TRUSTED` と付くが、自己署名なので、それで署名できる
4. 使う入力ソースを足す（システム設定 → キーボード → 入力ソース）。英数とかなに使うなら ABC と日本語（ローマ字入力）。ID で選ぶ入力ソース（ボポモフォなど）を使うときも、ABC が要る（要件の6章）
5. ⌃Space を確かめる（システム設定 → キーボード → キーボードショートカット → 入力ソース）: 「前の入力ソースを選択」がオンで、⌃Space のまま。ID で選ぶ入力ソースを選ぶのに使う（要件の6章）
6. `scripts/build-app.sh` で作って置き、`open ~/Applications/AnyKana.app` で起動する
7. 権限の案内が2つ出たら、システム設定で入力監視とアクセシビリティの両方で AnyKana をオンにする。2 秒ほどで動き始める。動かなければ `pkill -x AnyKana` で止めて、もう一度 `open` する。ログイン項目には、最初の起動で登録される
8. 割り当ては、動いている AnyKana をもう一度開いて置き直す

### 証明書の期限が切れたら

古い証明書をキーチェーンアクセスで消してから、上の2で作り直す（同じ名前が2つあると、codesign はどちらを使うか決められずに止まる）。証明書が変わるので、権限は付け直す（システム設定で、入力監視とアクセシビリティの AnyKana を一度消してから、7をやり直す）。期限は `security find-certificate -c "AnyKana Dev" -p | openssl x509 -noout -enddate` で見られる

## コマンド

| やること | コマンド |
| --- | --- |
| ビルド | `swift build` |
| テスト | `scripts/test.sh`（Command Line Tools 26 では、`swift test` だけだと Swift Testing が見つからない） |
| アプリを作って置く | `scripts/build-app.sh`（動いている AnyKana は止める） |
| アイコンを作り直す | `swift scripts/make-icon.swift`（絵を変えたら。`Resources/AppIcon.icns` を書き換える） |
| 起動 / 終了 | `open ~/Applications/AnyKana.app` / `pkill -x AnyKana`（設定の画面の「Quit AnyKana」でもよい） |
| 割り当てを置き直す | 動いている AnyKana をもう一度開く（Spotlight か `open ~/Applications/AnyKana.app`） |
| 割り当てをコマンドで書く | `defaults write io.github.takashi-w.anykana keyMap -dict globe com.apple.inputmethod.TCIM.Zhuyin`（対応表まるごとを書き換える。枠の名前は `leftCommand`・`rightCommand`・`leftOption`・`rightOption`・`globe`）。起動し直すか、設定の画面を開くと読み直す |
| 割り当てを最初に戻す | `defaults delete io.github.takashi-w.anykana keyMap` |
| ログイン項目に登録し直す（最初の起動で1回だけ登録する） | `defaults delete io.github.takashi-w.anykana registeredLoginItem` のあと、起動し直す |
| ログを見る | `log stream --predicate 'subsystem == "io.github.takashi-w.anykana"' --level debug` |

## License

MIT. See `LICENSE`.
