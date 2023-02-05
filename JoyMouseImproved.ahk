#NoEnv
#SingleInstance
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode,2
SetMouseDelay, -1
SetBatchLines, -1
Process, Priority,, H
; CoordMode, Mouse, Screen
; CoordMode, Pixel, Screen
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr") 

class Settings
{
	__new() {
		this.JoystickNumber := 2 ; will have to change the remaps manually
		this.JoyThreshold := 20

		this.MouseTopSpeed := 10 

		this.MouseMoveDelay := 10
		this.ScrollWheelDelay := 30
		this.DPadDelay := 30

		this.JoyThresholdUpper := 50 + this.JoyThreshold
		this.JoyThresholdLower := 50 - this.JoyThreshold
	}
}

Global UserSettings := new Settings
Global keyboard := new OSK 
Global MouseController := new MouseControls()

SetTimer, DPad, % UserSettings.DPadDelay
MouseController.SetTimer("cursor_timer", UserSettings.MouseMoveDelay)
MouseController.SetTimer("scroll_wheel_timer", UserSettings.ScrollWheelDelay)

; A
2Joy1::
	Click, left, down
	KeyWait % A_ThisHotkey
	Click, left, up
	Return
; B
2Joy2::RButton
; X
2Joy3::Enter
; Y
2Joy4::keyboard.toggle()

; LB
2Joy5:: ; the built in alt tab labels weren't working for me
	Send {Alt down}{Tab}
	KeyWait, % A_ThisHotkey
	Send {Alt up}
	Return

DPad() {
	GetKeyState, JoyPOV, % UserSettings.JoyStickNumber "JoyPov"
	GetKeyState, JoyZ, % UserSettings.JoyStickNumber "JoyZ"
	if (JoyPOV = -1) {  ; No angle.
		return
	}
	else if (JoyZ < 60) {
	if keyboard.enabled {
		if JoyPOV = 27000
			GuiControl, Focus, "BS"
		else if JoyPOV = 0
			GuiControl, Focus, "t"
		else if JoyPOV = 18000
			GuiControl, Focus, "x"
		else if JoyPOV = 9000
			GuiControl, Focus, "h"
		Return
	}
	if JoyPOV = 27000
		Send {Left}
	else if JoyPOV = 0
		Send {Up}
	else if JoyPOV = 18000
		Send {Down}
	else if JoyPOV = 9000
		Send {Right}
	} 
	else 
	{
	if JoyPOV = 27000
		Send ^+{Tab}
	else if JoyPOV = 0
		Send ^t
	else if JoyPOV = 18000
		Send ^w
	else if JoyPOV = 9000
		Send ^{Tab}
	}
	Sleep, 200
	return
}

GetCurrentMonitorIndex() {
	CoordMode, Mouse, Screen
	MouseGetPos, mx, my
	SysGet, monitorsCount, 80

	Loop %monitorsCount%{
		SysGet, monitor, Monitor, %A_Index%
		if (monitorLeft <= mx && mx <= monitorRight && monitorTop <= my && my <= monitorBottom){
			Return A_Index
			}
		}
		Return 1
}

CoordXCenterScreen(WidthOfGUI,ScreenNumber) {
SysGet, Mon1, Monitor, %ScreenNumber%
	return (( Mon1Right-Mon1Left - WidthOfGUI ) / 2) + Mon1Left
}

CoordYCenterScreen(HeightofGUI,ScreenNumber) {
SysGet, Mon1, Monitor, %ScreenNumber%
	return (Mon1Bottom - 80 - HeightofGUI )
}

GetClientSize(hwnd, ByRef w, ByRef h) {
    VarSetCapacity(rc, 16)
    DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
    w := NumGet(rc, 8, "int")
    h := NumGet(rc, 12, "int")
}

Class MouseControls
{
    __New() {
		this.top_speed := UserSettings.MouseTopSpeed
        this.velocity_x := 0
        this.velocity_y := 0
        this.scroll_wheel_timer := ObjBindMethod(this, "MoveScrollWheel")
        this.cursor_timer := ObjBindMethod(this, "MoveCursor")
    }

    SetTimer(timer_id, period) {
        timer := this[timer_id]
        SetTimer % timer, % period
    }

    MoveScrollWheel() {
		GetKeyState, JoyR, % UserSettings.JoyStickNumber "JoyR"
		if (JoyR > UserSettings.JoyThresholdUpper) {
			Send {WheelDown}
		}
		else if (JoyR < UserSettings.JoyThresholdLower) {
			Send {WheelUp}
		}

		GetKeyState, JoyU, % UserSettings.JoyStickNumber "JoyU"
		if (JoyU > UserSettings.JoyThresholdUpper) {
			send {WheelRight}
		}
		else if (JoyU < UserSettings.JoyThresholdLower) {
			Send {WheelLeft}
		}

		return
    }

    MoveCursor() {
		JoyX := GetKeyState(UserSettings.JoyStickNumber . "JoyX")
		JoyY := GetKeyState(UserSettings.JoyStickNumber . "JoyY")


		if (JoyY <= UserSettings.JoyThresholdLower) {
			y := (JoyY / UserSettings.JoyThresholdLower) - 1
		}
		else if (JoyY >= UserSettings.JoyThresholdUpper) {
			y := (JoyY - UserSettings.JoyThresholdUpper) / (100 - UserSettings.JoyThresholdUpper)
		}
		else
			y := 0


		if (JoyX <= UserSettings.JoyThresholdLower) {
			x := (JoyX / UserSettings.JoyThresholdLower) - 1
		}
		else if (JoyX >= UserSettings.JoyThresholdUpper) {
			x := (JoyX - UserSettings.JoyThresholdUpper) / (100 - UserSettings.JoyThresholdUpper)
		}
		else
			x := 0

		if (x != 0 or y != 0){
			JoyZ := GetKeyState(UserSettings.JoyStickNumber . "JoyZ")
			MouseMove, (1 + 3 * (50 - JoyZ) / 100) * this.top_speed * x,  (1 + 3 * (50 - JoyZ) / 100) * this.top_speed * y, 0, R
		}
    }
}

/*
--------------------------------
On-Screen Keyboard -- OSK() v1.5  By FeiYue

This is a small tool similar to the WinXP's On-Screen Keyboard.

Written in function form, easy to invoke in other scripts.

--------------------------------
*/

Class OSK
{

	__new() {
		this.enabled := False
	}

	show() {
		this.enabled := True
		static NewName:={ " ":"Space", Caps:"CapsLock"
		, App:"AppsKey", PrScn:"PrintScreen", ScrLk:"ScrollLock"
		, "↑":"Up", "↓":"Down", "←":"Left", "→":"Right" }
		w1:=45, h1:=30, w2:=60, w3:=w1*14+2*13

		s1:=[ ["Esc"],["F1",,w3-w1*13-15*2-2*9],["F2"],["F3"],["F4"],["F5",,15]
			,["F6"],["F7"],["F8"],["F9",,15],["F10"],["F11"],["F12"]
			,["PrScn",w2,10],["ScrLk",w2],["Pause",w2] ]

		s2:=[ ["~ ``"],["! 1"],["@ 2"],["# 3"],["$ 4"],["% 5"],["^ 6"]
			,["&& 7"],["* 8"],["( 9"],[") 0"],["_ -"],["+ ="],["BS"]
			,["Ins",w2,10],["Home",w2],["PgUp",w2] ]

		s3:=[ ["Tab"],["q"],["w"],["e"],["r"],["t"],["y"]
			,["u"],["i"],["o"],["p"],["{ ["],["} ]"],["| \"]
			,["Del",w2,10],["End",w2],["PgDn",w2] ]

		s4:=[ ["Caps",w2],["a"],["s"],["d"],["f"],["g"],["h"]
			,["j"],["k"],["l"],[": `;"],[""" '"],["Enter",w3-w1*11-w2-2*12] ]

		s5:=[ ["Shift",w1*2],["z"],["x"],["c"],["v"],["b"]
			,["n"],["m"],["< ,"],["> ."],["? /"],["Shift",w3-w1*12-2*11]
			,["↑",w2,10+w2+2] ]

		s6:=[ ["Ctrl",w2],["Win",w2],["Alt",w2],[" ",w3-w2*7-2*7]
			,["Alt",w2],["Win",w2],["App",w2],["Ctrl",w2]
			,["←",w2,10],["↓",w2],["→",w2] ]
		Gui, OSK: +AlwaysOnTop +Owner +E0x08000000 -Caption
		Gui, OSK: Font, s12, Verdana
		Gui, OSK: Margin, 10, 10
		Gui, OSK: Color, DDEEFF
		Loop, 6 {
			if (A_Index<=2)
			j=
			For i,v in s%A_Index%
			{
			w:=v.2 ? v.2 : w1, d:=v.3 ? v.3 : 2
			j:=j="" ? "xm" : i=1 ? "xm y+2" : "x+" d
			Gui, OSK: Add, Button, %j% w%w% h%h1% -Wrap gHandlePress, % v.1
			}
		}

		;---------GET CENTER OF CURRENT MONITOR---------
		;get current monitor index
		CurrentMonitorIndex:=GetCurrentMonitorIndex()
		;get Hwnd of current GUI
		DetectHiddenWindows On
		Gui, OSK: +LastFound
		Gui, OSK:Show, Hide
		GUI_Hwnd := WinExist()
		;Calculate size of GUI
		GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
		DetectHiddenWindows Off
		;Calculate where the GUI should be positioned
		GUI_X:=CoordXCenterScreen(GUI_Width,CurrentMonitorIndex)
		GUI_Y:=CoordYCenterScreen(GUI_Height,CurrentMonitorIndex)
		;------- / GET CENTER OF CURRENT MONITOR--------- 
		;SHOW GUI AT CENTER OF CURRENT SCREEN
		Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " noactivate", On-Screen Keyboard

		HandlePress:
			k:=A_GuiControl
			if k in Shift,Ctrl,Win,Alt
			{
				v:=k="Win" ? "LWin" : k
				GuiControlGet, isEnabled, OSK: Enabled, %k%
				GuiControl, OSK: Disable%isEnabled%, %k%
				if (!isEnabled)
				SendInput, {Blind}{%v%}
				return
			}
			s:=InStr(k," ") ? SubStr(k,0) : k
			s:=(v:=NewName[s]) ? v : s, s:="{" s "}"
			For i,k in StrSplit("Shift,Ctrl,Win,Alt", ",")
			{
				GuiControlGet, isEnabled, OSK: Enabled, %k%
				if (!isEnabled)
				{
				GuiControl, OSK: Enable, %k%
				v:=k="Win" ? "LWin" : k
				s={%v% Down}%s%{%v% Up}
				}
			}
			SendInput, {Blind}%s%
			return
	}

	hide() {
		this.enabled := False
		Gui, OSK: Destroy
		return
	}

	toggle() {
		If this.enabled {
			this.hide()
		}
		Else {
			this.show()
		}
		Return
	}

}

^r::Reload