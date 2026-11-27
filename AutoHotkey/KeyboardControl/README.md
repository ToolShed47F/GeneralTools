# keyboardcontroll_etc.ahk メモ

## 構成

- **IME**:Google日本語入力。Ctrl+Spaceで日本語と英語を切り替える
- **AHK**:AutoHotkey v2 の `keyboardcontroll_etc.ahk`
  - Caps(JIS配列なのでスキャンコード `sc03A` で指定)を単独で押す → IMEのON/OFFを直接切り替える(IMEの状態を取得できないアプリでは、代わりにCtrl+Spaceを送る)
  - Caps+各キー → Enter、BackSpace、矢印、数字など
- **複数PC**:PowerToysの **Mouse Without Borders(MWB)** で、別PCのキーボードからこのPCを操作している

## 過去に起きた問題(2026/11/27 解決)

### 症状
Capsを押してもIMEが切り替わらず、**スペースだけが入力される**ことがある。

### 原因
別PC(キーを送る側)で、**AHKのほうがMWBより先にキーを受け取っていた**。

キーを横取りする仕組み(キーボードフック)は、**後から起動したプログラムが先にキーを受け取る**。そのため、起動順によって動きが変わる。

```
【NGな状態】AHKが後から起動した
Caps → 別PCのAHK(ここでCtrl+Spaceに変換)→ MWB → ネットワーク → このPC
                                                   ↑ ここでCtrlとSpaceの順番がずれる
```

順番がずれて「Ctrlを離す → Spaceを押す」の順に届くと、ただのスペースとして入力される。

```
【OKな状態】PowerToysが後から起動した
Caps → MWB → (変換前のCapsのまま)ネットワーク → このPCのAHK(ここで変換)
```

### 解決方法
**別PCで、AHKが動いている状態のままPowerToysを起動し直す。**
(タスクトレイのPowerToysアイコンを右クリック → 終了 → スタートメニューから起動)

## 注意事項

- **別PCでAHKを起動し直したり、スクリプトを再読み込みしたりしたら、その後PowerToysも起動し直す。**
  AHKを起動し直すとAHKのほうが後になり、また症状が出る。
- **起動順は「AHK → PowerToys」にする。** スタートアップに登録する場合も、PowerToysが後から起動するようにする。
- **PowerToysのKeyboard ManagerでCapsを割り当てない。** AHKと二重に割り当てることになる。
- ユーザーを切り替えたりサインインし直したりした後に症状が出たら、まずPowerToysを起動し直す。
- MWBはKeyboard Managerとは別の機能。Keyboard Managerをオフにしても、MWBは動き続ける。

## 症状が再発したときの調べ方

1. **このPCのキーボードで直接**Capsを押して試す
   - 正常に動く → MWB経由の問題。別PCでPowerToysを起動し直す
   - 症状が出る → このPC側の問題。2へ進む
2. AHKのタスクトレイアイコンをダブルクリック → View → **Key history** を開き、Capsを何回か押してから F5 で更新する
   - `03A` の行(Caps)が出ていない → Capsが別のプログラムに横取りされている
   - Type列が `a` → 他のプログラムが作ったキー入力(MWB、NoMachine、PowerToysなど)
   - Type列が `i` → このスクリプト自身が送ったキー入力
   - 正しい順番は `Ctrl↓ → Space↓ → Space↑ → Ctrl↑`。Space↓がCtrl↑より後にあると、スペースだけが入力される
3. タスクマネージャーで、AutoHotkeyが2つ起動していないか確認する。キーを横取りするソフト(PowerToys、NoMachine、キーボードやマウスの付属ソフト)が動いていないかも見る

## ファイル

| ファイル | 内容 |
|---|---|
| `keyboardcontroll_etc.ahk` | スクリプト本体。CapsでのIME切り替えは、Ctrl+Spaceを送らずにIMEを直接切り替える。`#SingleInstance Force` で二重起動も防ぐ |
