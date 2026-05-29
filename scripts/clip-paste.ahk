#Requires AutoHotkey v2.0
; ============================================================
;  clip-paste — Windows 클립보드 이미지를 원격 드롭 폴더로 전송
;  캡처(Ctrl+C) → 이 핫키 → PNG 저장 → scp → Claude 프롬프트에 /paste
; ============================================================

; ─── 여기 3개만 본인 값으로 바꾸세요 ───────────────────────
SSH_USER_HOST := "USER@HOST"                  ; 예: "sungmin-cho@192.168.219.100" (비번 없는 SSH 키 필요)
REMOTE_DROP   := "/ABS/PATH/TO/clip-drop"     ; 호스트의 드롭 폴더 절대경로 = 컨테이너의 $CLIP_DROP 과 같은 위치
TERMINAL_EXE  := "Code.exe"                   ; Claude 를 띄우는 창. VS Code=Code.exe / Windows Terminal=WindowsTerminal.exe
; ──────────────────────────────────────────────────────────

note(msg, ms := 1500) {
    ToolTip(msg)
    SetTimer(() => ToolTip(), -ms)
}

; 지정한 터미널 창에서만 Ctrl+Shift+V 가로채기 (Ctrl+V 는 그대로 둠 → 텍스트 붙여넣기 안전)
#HotIf WinActive("ahk_exe " TERMINAL_EXE)
^+v:: {
    note("① 핫키 발동")
    ; CF_BITMAP(2) 또는 CF_DIB(8) 둘 다 이미지로 인정 (캡처도구마다 형식 다름)
    hasImg := DllCall("IsClipboardFormatAvailable", "UInt", 2) || DllCall("IsClipboardFormatAvailable", "UInt", 8)
    if !hasImg {
        note("② 클립보드에 이미지 없음 (캡처 후 Ctrl+C 했나요?)")
        return
    }
    png := A_Temp "\clip_" A_Now ".png"
    fname := "clip_" A_Now ".png"
    ps := "Add-Type -AssemblyName System.Windows.Forms,System.Drawing; $i=[Windows.Forms.Clipboard]::GetImage(); if($i){$i.Save('" png "',[System.Drawing.Imaging.ImageFormat]::Png)}"
    RunWait('powershell.exe -sta -NoProfile -WindowStyle Hidden -Command "' ps '"', , "Hide")
    if !FileExist(png) {
        note("③ PNG 저장 실패")
        return
    }
    note("④ 저장됨, 전송 중...")
    code := RunWait('scp -q "' png '" ' SSH_USER_HOST ':"' REMOTE_DROP '/' fname '"', , "Hide")
    FileDelete(png)
    if code != 0 {
        note("⑤ scp 실패 (코드 " code ") — SSH 키/경로 확인")
        return
    }
    note("⑥ 전송 완료 → /paste")
    SendText("/paste")
    Send("{Enter}")
}
#HotIf
