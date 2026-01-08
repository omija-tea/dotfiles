; #NoTrayIcon ;

SetCapsLockState "AlwaysOff"

; Ctrl::Alt
; Alt::Ctrl

^q::WinClose("A")

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
