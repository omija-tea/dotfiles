; #NoTrayIcon

SetCapsLockState, AlwaysOff

; Ctrl::Alt
; Alt::Ctrl
^q::WinClose, A

#If GetKeyState("Capslock","P")
   k::Up
   h::Left
   j::Down
   l::Right
   u::BackSpace
   o::Del
   
   ]::Send, {>}
   1::Send, {(}
   2::Send, {)}
   3::Send, {{}
   4::Send, {}}
   5::Send, {[}
   6::Send, {]}
   7::PgUp
   8::PgDn

   w::Up
   a::Left
   s::Down
   d::Right
   e::BackSpace
   q::Enter
   t::_
   r::=
   z::Home
   x::End
   c::Esc


   =::Send, {=}{>}
   n::Home
   m::End
   f::CapsLock
   ,::Send, {<}{-}
   .::Send, {-}{>}
#If


^F10::Send CtrlUp
