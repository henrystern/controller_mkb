#NoEnv
#SingleInstance
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 1 ; important for OSK
SetMouseDelay, -1
SetBatchLines, -1
Process, Priority,, H
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

class State
; Settings and session info
{
	__new() {
		this.JoystickNumber := 2
		this.JoyThresholdLower := 50 - 20
		this.JoyThresholdUpper := 50 + 20

		this.MouseTopSpeed := 10
		this.JoyZBoost := 3 ; Affects how much holding JoyZ increases mouse speed

		this.MouseMoveDelay := 10
		this.ScrollWheelDelay := 30
		this.DPadDelay := 30

		this.active := True
	}
}

Global Session := new State
Global keyboard := new OSK 
Global MouseController := new MouseControls()

SetTimer, DPad, % Session.DPadDelay
MouseController.SetTimer("cursor_timer", Session.MouseMoveDelay)
MouseController.SetTimer("scroll_wheel_timer", Session.ScrollWheelDelay)

Hotkey, % Session.JoystickNumber . "Joy1", J1
Hotkey, % Session.JoystickNumber . "Joy2", J2
Hotkey, % Session.JoystickNumber . "Joy3", J3
Hotkey, % Session.JoystickNumber . "Joy4", J4
Hotkey, % Session.JoystickNumber . "Joy5", J5
2Joy8::Reload ; for development

; A
J1:
	Click, left, down
	KeyWait % A_ThisHotkey
	Click, left, up
	Return

; B
J2:
	Click, right, down
	KeyWait % A_ThisHotkey
	Click, right, up
	Return

; X
J3:
	if not keyboard.isActive() {
		Send, {Enter}
		Return
	}
    k := keyboard.Controls[keyboard.RowIndex, keyboard.ColumnIndex].Content
    keyboard.SendPress(k)
	return

; Y
J4:
	keyboard.toggle()
	Return

; LB
J5:
	Send {Alt down}{Tab}
	KeyWait, % A_ThisHotkey
	Send {Alt up}
	Return

DPad() {
	GetKeyState, JoyPOV, % Session.JoyStickNumber "JoyPov"
	GetKeyState, JoyZ, % Session.JoyStickNumber "JoyZ"
	if (JoyPOV = -1) {  ; No angle.
		return
	}

	left := JoyPOV = 27000
	up := JoyPOV = 0
	down := JoyPOV = 18000
	right := JoyPOV = 9000

	if keyboard.isActive() {
		if left
			keyboard.changeIndex("Left")
		else if up
			keyboard.changeIndex("Up")
		else if down
			keyboard.changeIndex("Down")
		else if right
			keyboard.changeIndex("Right")
	}
	else if (JoyZ < 60) {
		if left
			Send {Left}
		else if up
			Send {Up}
		else if down
			Send {Down}
		else if right
			Send {Right}
	} 
	else {
		if left
			Send ^+{Tab}
		else if up
			Send ^t
		else if down
			Send ^w
		else if right
			Send ^{Tab}
	}
	Sleep, 200
	return
}

Class MouseControls
{
    __New() {
		this.top_speed := Session.MouseTopSpeed
        this.velocity_x := 0
        this.velocity_y := 0
        this.scroll_wheel_timer := ObjBindMethod(this, "MoveScrollWheel")
        this.cursor_timer := ObjBindMethod(this, "MoveCursor")
    }

    SetTimer(timer_id, period) {
        timer := this[timer_id]
        SetTimer % timer, % period
		return
    }

    MoveScrollWheel() {
		GetKeyState, JoyR, % Session.JoyStickNumber "JoyR"

		; check joystick is on
		if not JoyR
			return

		if (JoyR > Session.JoyThresholdUpper) {
			Send {WheelDown}
		}

		if (JoyR < Session.JoyThresholdLower) {
			Send {WheelUp}
		}

		GetKeyState, JoyU, % Session.JoyStickNumber "JoyU"
		if (JoyU > Session.JoyThresholdUpper) {
			send {WheelRight}
		}

		if (JoyU < Session.JoyThresholdLower) {
			Send {WheelLeft}
		}

		return
    }

    MoveCursor() {
		JoyX := GetKeyState(Session.JoyStickNumber . "JoyX")
		JoyY := GetKeyState(Session.JoyStickNumber . "JoyY")

		if (JoyY <= Session.JoyThresholdLower) {
			y := (JoyY / Session.JoyThresholdLower) - 1
		}
		else if (JoyY >= Session.JoyThresholdUpper) {
			y := (JoyY - Session.JoyThresholdUpper) / (100 - Session.JoyThresholdUpper)
		}
		else
			y := 0


		if (JoyX <= Session.JoyThresholdLower) {
			x := (JoyX / Session.JoyThresholdLower) - 1
		}
		else if (JoyX >= Session.JoyThresholdUpper) {
			x := (JoyX - Session.JoyThresholdUpper) / (100 - Session.JoyThresholdUpper)
		}
		else
			x := 0

		if (x != 0 or y != 0){
			JoyZ := GetKeyState(Session.JoyStickNumber . "JoyZ")

			if JoyZ > 45
				JoyZ := 50

			MouseMove, (1 + Session.JoyZBoost * (50 - JoyZ) / 100) * this.top_speed * x,  (1 + Session.JoyZBoost * (50 - JoyZ) / 100) * this.top_speed * y, 0, R
		}

		Return
    }
}

/*
--------------------------------
On-Screen Keyboard -- OSK() v1.5  By FeiYue

This is a small tool similar to the WinXP's On-Screen Keyboard.

--------------------------------
*/

; for centering keyboard on screen
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

Class OSK
; Adapted from feiyue's script: https://www.autohotkey.com/boards/viewtopic.php?t=58366 
{

	__new() {
		this.enabled := False

        ; start at h
		this.ColumnIndex := 7
		this.RowIndex := 4

		this.Handles := []
		this.Controls := []

		this.background := "010409"
		this.button_colour := "0d1117" 
		this.button_outline_colour := "0d1117" 
		this.active_button_colour := "1b1a20" 
		this.text_colour := "8b949e"

		this.layout := []
        ; row 1- format is ["Text", width, offset]
        this.layout.Push([ ["Esc"],["F1",,23],["F2"],["F3"],["F4"],["F5",,15],["F6"],["F7"],["F8"],["F9",,15],["F10"],["F11"],["F12"],["PrScn",60,10],["ScrLk",60],["Pause",60] ])
        ; row 2
		this.layout.Push([ ["~", 30],["! 1"],["@ 2"],["# 3"],["$ 4"],["% 5"],["^ 6"],["&& 7"],["* 8"],["( 9"],[") 0"],["_ -"],["+ ="],["BS", 60],["Ins",60,10],["Home",60],["PgUp",60] ])
        ; row 3
		this.layout.Push([ ["Tab"],["q"],["w"],["e"],["r"],["t"],["y"],["u"],["i"],["o"],["p"],["{ ["],["} ]"],["| \"],["Del",60,10],["End",60],["PgDn",60] ])
        ; row 4
		this.layout.Push([ ["Caps",60],["a"],["s"],["d"],["f"],["g"],["h"],["j"],["k"],["l"],[": `;"],[""" '"],["Enter",77] ])
        ; row 5
		this.layout.Push([ ["Shift",90],["z"],["x"],["c"],["v"],["b"],["n"],["m"],["< ,"],["> ."],["? /"],["Shift",94],["↑",60,72] ])
        ; row 6
		this.layout.Push([ ["Ctrl",60],["Win",60],["Alt",60],[" ",222],["Alt",60],["Win",60],["App",60],["Ctrl",60],["←",60,10],["↓",60],["→",60] ])

		this.PrettyName := { " ":"Space", Caps:"CapsLock", App:"AppsKey", PrScn:"PrintScreen", ScrLk:"ScrollLock", "↑":"Up", "↓":"Down", "←":"Left", "→":"Right"}

		this.make()
	}

	make() {
		Gui, OSK: +AlwaysOnTop -DPIScale +Owner -Caption +E0x08000000 
		Gui, OSK: Font, s12
		Gui, OSK: Margin, 10, 10
		Gui, OSK: Color, % this.background
		SS_CenterTextInBox := 0x200 ; styling adjustment
		For index, row in this.layout {
            if index <= 2
                j := ""

			For i,v in row {
                w := v.2 ? v.2 : 45 
                d := v.3 ? v.3 : 2
                j := j = "" ? "xm" : i=1 ? "xm y+2" : "x+" d

				; Control handling is from Hellbent's script: https://www.autohotkey.com/boards/viewtopic.php?t=87535
                Gui, OSK:Add, Text, % j " c" this.text_colour " w" w " h" 30 " -Wrap BackgroundTrans Center hwndthwnd gHandleClick " SS_CenterTextInBox, % v.1
                Gui, OSK:Add, Progress, % "xp yp w" w " h" 30 " Disabled Background" this.button_outline_colour " c" this.button_colour " hwndphwnd", 100
                Gui, OSK:Add, Text, % "xp yp c" this.text_colour " w" w " h" 30 " -Wrap BackgroundTrans Center hwndtthwnd " SS_CenterTextInBox, % v.1


                this.Handles[thwnd] := [index, i]
                this.Controls[index, i] := {Progress: phwnd, Text: tthwnd, Label: HandlePress, Content: v.1}
			}
		}
		Return

		HandleClick:
			keyboard.UpdateGraphics(keyboard.Controls[keyboard.RowIndex, keyboard.ColumnIndex] , keyboard.button_colour)
			GuiControlGet, bottomt, hwnd, % A_GuiControl
			keyboard.RowIndex := keyboard.Handles[bottomt][1]
			keyboard.ColumnIndex := keyboard.Handles[bottomt][2]
			; msgbox % bottomt ", " keyboard.RowIndex ", " keyboard.ColumnIndex
			keyboard.UpdateGraphics(keyboard.Controls[keyboard.RowIndex, keyboard.ColumnIndex] , keyboard.active_button_colour)
			keyboard.SendPress(A_GuiControl)	
			return
	}

	show() {
		this.enabled := True
		keyboard.UpdateGraphics( keyboard.Controls[keyboard.RowIndex, keyboard.ColumnIndex] , keyboard.button_colour )
		this.ColumnIndex := 7
		this.RowIndex := 4

		CurrentMonitorIndex:=GetCurrentMonitorIndex()
		DetectHiddenWindows On
		Gui, OSK: +LastFound
		Gui, OSK:Show, Hide
		GUI_Hwnd := WinExist()
		GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
		DetectHiddenWindows Off

		GUI_X:=CoordXCenterScreen(GUI_Width,CurrentMonitorIndex)
		GUI_Y:=CoordYCenterScreen(GUI_Height,CurrentMonitorIndex)

		Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", On-Screen Keyboard

		Return


	}

	SendPress(k) {
		if k in Shift,Ctrl,Win,Alt
		{
			v := k="Win" ? "LWin" : k
			GuiControlGet, isEnabled, OSK: Enabled, %k%
			GuiControl, OSK: Disable%isEnabled%, %k%
			if (!isEnabled)
			SendInput, {Blind}{%v%}
			return
		}
		s := InStr(k," ") ? SubStr(k,0) : k
		s := (this.PrettyName[s]) ? this.PrettyName[s] : s
		s := "{" s "}"
		For i,k in StrSplit("Shift,Ctrl,Win,Alt", ",")
		{
			GuiControlGet, isEnabled, OSK: Enabled, %k%
			if (!isEnabled)
			{
			GuiControl, OSK: Enable, %k%
			v:=k="Win" ? "LWin" : k
			s = {%v% Down}%s%{%v% Up}
			}
		}
		SendInput, {Blind}%s%
		Return
	}

	hide() {
		this.enabled := False
		Gui, OSK: Hide
		return
	}

	toggle() {
		If this.isActive() {
			this.hide()
		}
		Else {
			this.show()
		}
		Return
	}

	isActive() {
		return this.enabled
	}

    changeIndex(direction) {
        this.UpdateGraphics( keyboard.Controls[this.RowIndex, this.ColumnIndex] , this.button_colour)
		this.handleChangeIndex(direction)
        if (direction = "Up") {
			if this.RowIndex = 1
				this.RowIndex := this.Controls.Length()
			else
				this.RowIndex := this.RowIndex - 1
            this.ColumnIndex := min(this.ColumnIndex, this.Controls[this.RowIndex].Length())
        }
        if (direction = "Down") {
            this.RowIndex := mod(this.RowIndex, this.Controls.Length()) + 1
            this.ColumnIndex := min(this.ColumnIndex, this.Controls[this.RowIndex].Length())
        }
        if (direction = "Left") {
			if this.ColumnIndex = 1
				this.ColumnIndex := this.Controls[this.RowIndex].Length()
			else
				this.ColumnIndex := this.ColumnIndex - 1
        }
        if (direction = "Right") {
            this.ColumnIndex := mod(this.ColumnIndex, this.Controls[this.RowIndex].Length()) + 1
        }
        this.UpdateGraphics( keyboard.Controls[this.RowIndex, this.ColumnIndex] , this.active_button_colour)
    }

	handleChangeIndex(direction) {
		; hardcoded logic to fix unusual index changes due to variable button widths
		if (this.RowIndex = 1) {
			if (this.ColumnIndex > 1 and direction = "Down")
				this.ColumnIndex += 1
			else if (this.ColumnIndex > 12 and direction = "Up")
				this.ColumnIndex -= 5
			else if (this.ColumnIndex > 8 and direction = "Up")
				this.ColumnIndex -= 4
			else if (this.ColumnIndex > 3 and direction = "Up")
				this.ColumnIndex := 4
		}
		else if (this.RowIndex = 2) {
			if (this.ColumnIndex > 1 and direction = "Up")
				this.ColumnIndex -= 1
		}
		else if (this.RowIndex = 3) {
			if (this.ColumnIndex = 14 and direction = "Down")
				this.ColumnIndex -= 1
			else if (this.ColumnIndex > 14 and direction = "Down")
				this.RowIndex += 1

		}
		else if (this.RowIndex = 4) {
			if (this.ColumnIndex = 13 and direction = "Up") 
				this.ColumnIndex += 1
			else if (this.ColumnIndex = 13 and direction = "Down")
				this.ColumnIndex -= 1
		}
		else if (this.RowIndex = 5) {
			if (this.ColumnIndex = 13 and direction = "Up") {
				this.RowIndex -= 1
				this.ColumnIndex += 3
			}
			if (this.ColumnIndex = 13 and direction = "Down")
				this.ColumnIndex += 1
			if (this.ColumnIndex = 12 and direction = "Up")
				this.ColumnIndex += 1
			else if (this.ColumnIndex > 8 and direction = "Down")
				this.ColumnIndex -= 4
			else if (this.ColumnIndex > 3 and direction = "Down")
				this.ColumnIndex := 4
		}
		else if (this.RowIndex = 6) {
			if (this.ColumnIndex > 7 and direction = "Down")
				this.ColumnIndex += 5
			else if (this.ColumnIndex > 4 and direction = "Up" or direction = "Down")
				this.ColumnIndex += 4
			else if (this.ColumnIndex = 4 and direction = "Up" or direction = "Down")
				this.ColumnIndex := 6
		}
		return
	}

    UpdateGraphics( obj , Color ){
        GuiControl, OSK: +C%Color%, % obj.Progress
        GuiControl, OSK: +Redraw, % obj.Text
        Return
    }
}