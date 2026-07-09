#Requires AutoHotkey v2.0
; #NoTrayIcon ;

SetCapsLockState "AlwaysOff"

; Ctrl::Alt
; Alt::Ctrl

^q::WinClose("A")

; =============================================================
; Alt + ` (backtick)
;  - Alt-Tab 스위처 UI가 떠 있는 상태  -> Shift+Tab 전송 (이전 항목으로 이동)
;  - 스위처가 없는 평상시            -> 현재 활성 창과 같은 프로그램의
;                                         다음 창으로 순환 전환 (macOS Cmd+`)
; =============================================================

; 스위처가 떠 있을 때: 뒤로가기
; (참고: AHK v2에는 AltTab/ShiftAltTab 이라는 내장 특수 액션이 있지만,
;  공식적으로 #HotIf의 영향을 받지 않는다고 확인되어 있어서(포럼 확인됨)
;  이 용도로는 쓸 수 없음. 그래서 Shift+Tab을 직접 보내는 방식을 사용.)
; 클래스명은 윈도우 버전/빌드에 따라 다름:
;   - XamlExplorerHostIslandWindow : Windows 11 (새 Alt-Tab 스위처)
;   - MultitaskingViewFrame        : Windows 10 (일부 빌드) / Win+Tab 작업보기
;   - TaskSwitcherWnd              : Windows 7/8.1, 구형 Alt-Tab
#HotIf WinActive("ahk_class XamlExplorerHostIslandWindow")
    or WinActive("ahk_exe explorer.exe ahk_class MultitaskingViewFrame")
    or WinActive("ahk_class TaskSwitcherWnd")
!`::Send("{Blind}+{Tab}")
#HotIf

; 진단용: Alt+Tab 스위처를 띄운 채(Alt를 누른 상태로) Alt+F1을 누르면
; 현재 활성 창의 ahk_class / ahk_exe 를 툴팁으로 보여줌.
; 위 조건이 또 안 맞을 경우 이 값을 확인해서 #HotIf 조건에 추가하면 됨.
!F1::ToolTip("class: " WinGetClass("A") "`nexe: " WinGetProcessName("A"))

; 평상시: 같은 프로그램 창 순환
!`::CycleSameAppWindows()

CycleSameAppWindows(*) {
    activeHwnd := WinExist("A")
    if !activeHwnd
        return

    activeExe := WinGetProcessName("ahk_id " activeHwnd)
    winList := WinGetList("ahk_exe " activeExe)

    if (winList.Length <= 1)
        return

    curPos := 0
    for index, hwnd in winList {
        if (hwnd = activeHwnd) {
            curPos := index
            break
        }
    }

    nextPos := curPos + 1
    if (nextPos > winList.Length)
        nextPos := 1

    WinActivate("ahk_id " winList[nextPos])
}

#HotIf GetKeyState("CapsLock", "P")
    k::Up
    h::Left
    j::Down
    l::Right
    u::Send("^{Left}")
    i::Send("^{Right}")
    
    ]::Send(">")
    1::Send("(")
    2::Send(")")
    3::Send("{")
    4::Send("}")
    5::Send("[")
    6::Send("]")
    7::PgUp
    8::PgDn

    w::Up
    a::Left
    s::Down
    d::Right
    e::BackSpace
    q::Enter
    t::Send("_")
    r::Send("=")
    z::Home
    x::End
    c::Esc

    =::Send("=>")
    n::Home
    m::End
    f::CapsLock
    ,::Send("<-")
    .::Send("->")
#HotIf
