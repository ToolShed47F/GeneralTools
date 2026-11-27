#Requires AutoHotkey v2.0

; --- スクロール系 ---
PgUp::MouseClick "WheelUp", , , 1
PgDn::MouseClick "WheelDown", , , 1
Pause::Click "Left"
ScrollLock::Click "Right"

; --- 移動速度・状態の設定 ---
base_speed := 5      
max_speed := 30  
acceleration := 1  
current_speed := base_speed

; 各キーの押下状態フラグ
i_pressed := false
j_pressed := false
k_pressed := false
l_pressed := false

; --- Alt + I/J/K/L のホットキー定義（アプリへのキー漏れを完全ブロック） ---
!i::global i_pressed := true
!i Up::global i_pressed := false

!j::global j_pressed := true
!j Up::global j_pressed := false

!k::global k_pressed := true
!k Up::global k_pressed := false

!l::global l_pressed := true
!l Up::global l_pressed := false

; --- Alt + U：短押しで左クリック、長押しで左ドラッグ ---
!u::
{
    ; 0.2秒（200ms）以内にUキーを離せば「単発クリック」、押し続けたら「ドラッグ」に移行
    if KeyWait("u", "T0.2") {
        Click("Left")
    } else {
        Click("Left Down")
        KeyWait("u")
        Click("Left Up")
    }
}

; --- Alt + O：短押しで右クリック、長押しで右ドラッグ ---
!o::
{
    if KeyWait("o", "T0.2") {
        Click("Right")
    } else {
        Click("Right Down")
        KeyWait("o")
        Click("Right Up")
    }
}

; --- 定期監視タイマー（斜め移動・加速の処理） ---
SetTimer(MoveMouseLoop, 10)

MoveMouseLoop() {
    global i_pressed, j_pressed, k_pressed, l_pressed, current_speed, base_speed, max_speed, acceleration
    
    if GetKeyState("Alt", "P") && (i_pressed || j_pressed || k_pressed || l_pressed) {
        dx := 0
        dy := 0
        
        if j_pressed  ; 左
            dx -= 1
        if l_pressed  ; 右
            dx += 1
        if i_pressed  ; 上
            dy -= 1
        if k_pressed  ; 下
            dy += 1
            
        if (dx != 0 || dy != 0) {
            MouseMove(dx * current_speed, dy * current_speed, 0, "R")
            
            if (current_speed < max_speed)
                current_speed += acceleration
        }
    } else {
        current_speed := base_speed
    }
}

; --- CapsLock(英数)キーを修飾キーとして使う ---
; JIS配列では CapsLock キーが「英数キー(vkF0)」として送られるため、
; キー名ではなく物理キーのスキャンコード sc03A で指定する。
; ※ PowerToys などでの CapsLock → Ctrl+Space の割り当ては解除しておくこと。

; Caps 単体で押して離したとき → Ctrl+Space（IMEの英字かな切り替え）
; ほかのキーと組み合わせたときは送られない
sc03A::Send "^{Space}"

; --- Caps + 基本キー ---
sc03A & m::Send "{Enter}"      ; Caps + M → Enter
sc03A & sc027::Send "{Backspace}"  ; Caps + ; → BackSpace（U が数字になったため移動）

; --- Caps + A → Esc（Q が数字になったため移動） ---
sc03A & a::Send "{Esc}"

; --- Caps + H → F7 ---
sc03A & b::Send "{F7}"

; --- Caps + C → Alt（Cを押している間だけAltを押した状態にする） ---
sc03A & c::
{
    Send "{Blind}{Alt down}"
    KeyWait("c")              ; Cキーが離されるまで待つ
    Send "{Blind}{Alt up}"
}

; --- Caps + V → Tab（Blindで、Caps+C のAltを押したまま送る → Alt+Tabになる） ---
sc03A & v::Send "{Blind}{Tab}"

; --- Caps + 矢印キー（S/D/F/G）※Shift併用で範囲選択 ---
sc03A & s::Send "{Blind}{Left}"   ; Caps + S → ←
sc03A & d::Send "{Blind}{Up}"     ; Caps + D → ↑
sc03A & f::Send "{Blind}{Down}"   ; Caps + F → ↓
sc03A & g::Send "{Blind}{Right}"  ; Caps + G → →

; --- Caps + H → F10 ---
sc03A & h::Send "{F10}"

; --- Caps + J/K → マウスホイール ---
sc03A & j::Click "WheelDown"  ; Caps + K → 下スクロール
sc03A & k::Click "WheelUp"    ; Caps + J → 上スクロール

; --- Caps + 上段で数字入力（Shift併用で記号） ---
sc03A & q::Send "{Blind}1"
sc03A & w::Send "{Blind}2"
sc03A & e::Send "{Blind}3"
sc03A & r::Send "{Blind}4"
sc03A & t::Send "{Blind}5"
sc03A & y::Send "{Blind}6"
sc03A & u::Send "{Blind}7"
sc03A & i::Send "{Blind}8"
sc03A & o::Send "{Blind}9"
sc03A & p::Send "{Blind}0"
sc03A & sc01A::Send "{Blind}-"

; --- Chrome用：短押しで戻る、連打でタブを閉じる、長押しで「とは？」 ---
#HotIf WinActive("ahk_exe chrome.exe")

XButton1::
{
    if (A_PriorHotkey == "XButton1" && A_TimeSincePriorHotkey < 300) {
        Send "^w"
        KeyWait "XButton1"
        return
    }
    if KeyWait("XButton1", "T0.3") {
        Send "!{Left}"
    } else {
        SendTextNoIME("とは？")    ; ← ここを変更
        KeyWait "XButton1"
    }
}

; --- Chrome以外：短押しで通常の戻る、長押しで「とは？」 ---
#HotIf

XButton1::
{
    if KeyWait("XButton1", "T0.3") {
        Send "{XButton1}"
    } else {
        SendTextNoIME("とは？")    ; ← ここを変更
        KeyWait "XButton1"
    }
}
#HotIf

; --- 全アプリ共通：進むボタン（1回で貼り付け、2回で進む、長押しでコピー） ---
XButton2::
{
    global xb2Pending
    if !IsSet(xb2Pending)
        xb2Pending := false
    wasPending := xb2Pending
    if wasPending {
        SetTimer XB2Paste, 0
        xb2Pending := false
    }
    if KeyWait("XButton2", "T0.3") {
        if wasPending {
            Send "{XButton2}"     ; 2回押し → 進む
        } else {
            xb2Pending := true
            SetTimer XB2Paste, -300
        }
    } else {
        Send "^c"                 ; 長押し → コピー
        KeyWait "XButton2"
    }
}

XB2Paste() {
    global xb2Pending
    xb2Pending := false
    Send "^v"
}

; --- 日付入力(;dで今日の日付変換、英字ローマ字どちらでも使える） ---
:*:;d::
{
    SendText FormatTime(, "_yyyyMMdd")
}

; IMEを一時的にオフにして文字列を確定入力する
SendTextNoIME(text) {
    DetectHiddenWindows True
    hwnd := 0
    try hwnd := ControlGetFocus("A")
    if !hwnd
        hwnd := WinExist("A")
    ime := DllCall("imm32\ImmGetDefaultIMEWnd", "Ptr", hwnd, "Ptr")
    prev := SendMessage(0x283, 0x5, 0, , "ahk_id " ime)   ; 現在のIME状態を取得
    if prev
        SendMessage(0x283, 0x6, 0, , "ahk_id " ime)       ; IMEオフ
    SendText text
    if prev {
        Sleep 50
        SendMessage(0x283, 0x6, 1, , "ahk_id " ime)       ; IMEを元に戻す
    }
}
