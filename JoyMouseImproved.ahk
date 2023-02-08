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

		this.MouseTopSpeed := 5
		this.JoyZBoost := 5 ; Affects how much holding JoyZ increases mouse speed

		this.MouseMoveDelay := 10
		this.ScrollWheelDelay := 30
		this.DPadDelay := 30

		this.Active := True
	}
}

Global Session := new State
Global keyboard
initKeyboard(keyboard)
Global MouseController := new MouseControls()

; Hold Back to toggle JoyMouse
Hotkey, % Session.JoystickNumber . "Joy7", J7, On

if Session.Active {
	ToggleHotKeys("On")
	SetTimer, DPad, % Session.DPadDelay
	MouseController.SetTimer("cursor_timer", Session.MouseMoveDelay)
	MouseController.SetTimer("scroll_wheel_timer", Session.ScrollWheelDelay)
}

ToggleHotKeys(State) {
	Hotkey, % Session.JoystickNumber . "Joy1", J1, % State
	Hotkey, % Session.JoystickNumber . "Joy2", J2, % State
	Hotkey, % Session.JoystickNumber . "Joy3", J3, % State
	Hotkey, % Session.JoystickNumber . "Joy4", J4, % State
	Hotkey, % Session.JoystickNumber . "Joy5", J5, % State
	Hotkey, % Session.JoystickNumber . "Joy6", J6, % State
	Hotkey, % Session.JoystickNumber . "Joy6", J6, % State
	; J7 used for toggling
	Hotkey, % Session.JoystickNumber . "Joy7", J7, % State
	Hotkey, % Session.JoystickNumber . "Joy8", J8, % State
	Hotkey, % Session.JoystickNumber . "Joy9", J9, % State
	Hotkey, % Session.JoystickNumber . "Joy10", J10, % State
}

Labels() { ; so the returns don't interrupt the main thread
	; A
	J1:
		if (keyboard.Enabled and keyboard.RowIndex) {
			k := keyboard.Layout[keyboard.RowIndex, keyboard.ColumnIndex].1
			if (keyboard.IsModifier(k))
				keyboard.SendModifier(k)
			else
				keyboard.SendPress(k)
		}
		else {
			Click, left, down
			KeyWait % A_ThisHotkey
			Click, left, up
		}
		Return

	; B
	J2:
		Click, right, down
		KeyWait % A_ThisHotkey
		Click, right, up
		Return

	; X
	J3:
		SendInput, {Enter}
		Return

	; Y
	J4:
		keyboard.Toggle()
		Return

	; LB
	J5:
		if (keyboard.Enabled) {
			keyboard.SendPress("BS")
		}
		else {
			SendInput {Alt down}{Tab}
			KeyWait, % A_ThisHotkey
			SendInput {Alt up}
		}
		Return

	; RB
	J6:
		if (keyboard.Enabled)
			keyboard.SendPress("Space")

	; Back
	J7:
		KeyWait % A_ThisHotkey
		If (A_TimeSinceThisHotkey > 600) {
			If not Session.Active {
				Session.active := not Session.Active
				ComObjCreate("SAPI.SpVoice").Speak("Activated")
				SetTimer, DPad, % Session.DPadDelay
				MouseController.SetTimer("cursor_timer", Session.MouseMoveDelay)
				MouseController.SetTimer("scroll_wheel_timer", Session.ScrollWheelDelay)
				ToggleHotKeys("On")	
			}
			Else {
				Session.active := not Session.Active
				ComObjCreate("SAPI.SpVoice").Speak("Disabled")
				ToggleHotKeys("Off")
				SetTimer, DPad, off
				MouseController.SetTimer("cursor_timer", "off")
				MouseController.SetTimer("scroll_wheel_timer", "off")
			}
		}
		Return

	; Start
	J8:
		Return

	; LS Down
	J9:
		Return
	
	; RS Down
	J10:
		Return

}
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

	if keyboard.Enabled {
		if left
			keyboard.ChangeIndex("Left")
		else if up
			keyboard.ChangeIndex("Up")
		else if down
			keyboard.ChangeIndex("Down")
		else if right
			keyboard.ChangeIndex("Right")
	}
	else if (JoyZ < 60) {
		if left
			SendInput {Left}
		else if up
			SendInput {Up}
		else if down
			SendInput {Down}
		else if right
			SendInput {Right}
	} 
	else {
		if left
			SendInput ^+{Tab}
		else if up
			SendInput ^t
		else if down
			SendInput ^w
		else if right
			SendInput ^{Tab}
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
		if (JoyR > Session.JoyThresholdUpper) {
			SendInput {WheelDown}
		}

		if (JoyR >= 0 and JoyR < Session.JoyThresholdLower) { ; first condition controls for the controller being off
			SendInput {WheelUp}
		}

		GetKeyState, JoyU, % Session.JoyStickNumber "JoyU"
		if (JoyU > Session.JoyThresholdUpper) {
			SendInput {WheelRight}
		}

		if (JoyU < Session.JoyThresholdLower) {
			SendInput {WheelLeft}
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

			; So LT doesn't reverse direction
			if JoyZ > 45
				JoyZ := 50

			MouseMove, (1 + Session.JoyZBoost * (50 - JoyZ) / 100) * this.top_speed * x,  (1 + Session.JoyZBoost * (50 - JoyZ) / 100) * this.top_speed * y, 0, R
		}

		Return
    }
}

initKeyboard(byref Name) {
	Name := new OSK(Name)
	HandleOSKClick:
		Name.HandleOSKClick()
		return
}

Class OSK
; Adapted from feiyue's script: https://www.autohotkey.com/boards/viewtopic.php?t=58366 
{

	__New() {
		this.Enabled := False

		this.Keys := []
		this.Controls := []
		this.Modifiers := ["LShift", "LCtrl", "LWin", "LAlt", "RShift", "RCtrl", "RWin", "RAlt", "Caps"]

		this.Background := "010409"
		this.ButtonColour := "0d1117" 
		this.ButtonOutlineColour := "0d1117" 
		this.ActiveButtonColour := "1b1a20" 
		this.SentButtonColour := "7c2a2b"
		this.ToggledButtonColour := "7c2a2a" ; don't set exactly the same as SentButtonColour
		this.TextColour := "8b949e"

        this.MonitorKeyPresses := ObjBindMethod(this, "MonitorAllKeys") ; can choose between MonitorModifiers and MonitorAllKeys

		this.Layout := []
        ; row 1- format is ["Text", width:=45, x-offset:=2]
        this.Layout.Push([ ["Esc"],["F1",,23],["F2"],["F3"],["F4"],["F5",,15],["F6"],["F7"],["F8"],["F9",,15],["F10"],["F11"],["F12"],["PrintScreen",60,10],["ScrollLock",60],["Pause",60] ])
        ; row 2
		this.Layout.Push([ ["~", 30],["1"],["2"],["3"],["4"],["5"],["6"],["7"],["8"],["9"],["0"],["-"],["="],["BS", 60],["Ins",60,10],["Home",60],["PgUp",60] ])
        ; row 3
		this.Layout.Push([ ["Tab"],["q"],["w"],["e"],["r"],["t"],["y"],["u"],["i"],["o"],["p"],["["],["]"],["\"],["Del",60,10],["End",60],["PgDn",60] ])
        ; row 4
		this.Layout.Push([ ["CapsLock",60],["a"],["s"],["d"],["f"],["g"],["h"],["j"],["k"],["l"],["`;"],["'"],["Enter",77] ])
        ; row 5
		this.Layout.Push([ ["LShift",90],["z"],["x"],["c"],["v"],["b"],["n"],["m"],[","],["."],["/"],["RShift",94],["↑",60,72] ])
        ; row 6
		this.Layout.Push([ ["LCtrl",60],["LWin",60],["LAlt",60],["Space",222],["RAlt",60],["RWin",60],["App",60],["RCtrl",60],["Left",60,10],["Down",60],["Right",60] ])

		; Optionally sets alternate text for the button actions named in this.Layout
		this.PrettyName := { "PrintScreen": "Prt Scr", "ScrollLock": "Scr Lk"
								, 1: "1 !", 2: "2 @", 3: "3 #", 4: "4 $", 5: "5 %", 6: "6 ^", 7: "7 &&", 8: "8 *", 9: "9 (", 0: "0 )", "-": "- _", "=": "= +", "BS": "←", "PgUp": "Pg Up", "PgDn": "Pg Dn"
								, "[": "[ {", "]": "] }", "\": "\ |"
								, "CapsLock": "Caps", "`;": "`; :", "'": "' """
								, "LShift": "Shift", ",": ", <", ".": ". >", "/": "/ ?", "RShift": "Shift"
								, "LCtrl": "Ctrl", "LWin": "Win", "LAlt": "Alt", "Space": " ", "RAlt": "Alt", "RWin": "Win", "AppsKey": "App", "RCtrl": "Ctrl", "Up": "↑", "Down": "↓", "Left": "←", "Right": "→"}

		this.Make()
	}

    SetTimer(TimerID, Period) {
        Timer := this[TimerID]
        SetTimer % Timer, % Period
		return
    }

	IsModifier(Key) {
		if (Key = "LShift" 
			or Key = "LCtrl" 
			or Key = "LAlt" 
			or Key = "LWin" 
			or Key = "RShift" 
			or Key = "RCtrl" 
			or Key = "RAlt" 
			or Key = "RWin"
			or Key = "CapsLock"
			or Key = "ScrollLock")
			return True
		else
			return False
	}

	Make() {
		Gui, OSK: +AlwaysOnTop -DPIScale +Owner -Caption +E0x08000000 
		Gui, OSK: Font, s12, Verdana
		Gui, OSK: Margin, 10, 10
		Gui, OSK: Color, % this.Background
		SS_CenterTextInBox := 0x200 ; styling adjustment
		For Index, Row in this.Layout {
			For i, Button in Row {
                Width := Button.2 ? Button.2 : 45 
                HorizontalOffset := Button.3 ? Button.3 : 2
                RelativePosition := Index <= 2 and i = 1 ? "xm" : i=1 ? "xm y+2" : "x+" HorizontalOffset
				ButtonText := this.PrettyName[Button.1] ? this.PrettyName[Button.1] : Button.1

				; Control handling is from Hellbent's script: https://www.autohotkey.com/boards/viewtopic.php?t=87535
                Gui, OSK:Add, Text, % RelativePosition " c" this.TextColour " w" Width " h" 30 " -Wrap BackgroundTrans Center hwndbottomt gHandleOSKClick " SS_CenterTextInBox, % Button.1 ; handles the click
                Gui, OSK:Add, Progress, % "xp yp w" Width " h" 30 " Disabled Background" this.ButtonOutlineColour " c" this.ButtonColour " hwndp", 100
                Gui, OSK:Add, Text, % "xp yp c" this.TextColour " w" Width " h" 30 " -Wrap BackgroundTrans Center hwndtopt " SS_CenterTextInBox, % ButtonText ; displays the pretty name

				this.Keys[Button.1] := [Index, i]
                this.Controls[Index, i] := {Progress: p, Text: topt, Label: HandlePress, Colour: this.ButtonColour}
			}
		}
		Return
	}

	HandleOSKClick() {
		if (this.IsModifier(A_GuiControl)) {
			this.SendModifier(A_GuiControl)
		}
		else {
			this.SendPress(A_GuiControl)
		}
		return
	}

	Show() {
		this.Enabled := True

		; reset active key
		this.UpdateGraphics(this.Controls[this.RowIndex, this.ColumnIndex], this.ButtonColour)
		this.ColumnIndex := 0
		this.RowIndex := 0

		CurrentMonitorIndex := this.GetCurrentMonitorIndex()
		DetectHiddenWindows On
		Gui, OSK: +LastFound
		Gui, OSK:Show, Hide
		GUI_Hwnd := WinExist()
		this.GetClientSize(GUI_Hwnd,GUI_Width,GUI_Height)
		DetectHiddenWindows Off

		GUI_X := this.CoordXCenterScreen(GUI_Width,CurrentMonitorIndex)
		GUI_Y := this.CoordYCenterScreen(GUI_Height,CurrentMonitorIndex)

		Gui, OSK:Show, % "x" GUI_X " y" GUI_Y " NA", On-Screen Keyboard

		this.SetTimer("MonitorKeyPresses", 30)

		Return
	}

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
			return ((Mon1Right-Mon1Left - WidthOfGUI) / 2) + Mon1Left
	}

	CoordYCenterScreen(HeightofGUI,ScreenNumber) {
		SysGet, Mon1, Monitor, %ScreenNumber%
			return (Mon1Bottom - 80 - HeightofGUI)
	}

	GetClientSize(hwnd, ByRef w, ByRef h) {
		VarSetCapacity(rc, 16)
		DllCall("GetClientRect", "uint", hwnd, "uint", &rc)
		w := NumGet(rc, 8, "int")
		h := NumGet(rc, 12, "int")
	}

	SendModifier(Key) {
		ModifierRow := this.Keys[Key][1]
		ModifierColumn := this.Keys[Key][2]
		if (Key = "CapsLock")
			SetCapsLockState, % not GetKeyState(Key, "T")
		else if (Key = "ScrollLock")
			SetScrollLockState, % not GetKeyState(Key, "T")
		else {
			ModifierOn := GetKeyState(Key)
			if (ModifierOn)
				SendInput, % "{" Key " up}"
			else 
				SendInput, % "{" Key " down}"
		}
		return
	}

	MonitorModifiers() {
		For _, Modifier in this.Modifiers {
			if (Modifier = "CapsLock" or Key = "ScrollLock")
				ModifierOn := GetKeyState(Key, "T")
			else
				ModifierOn := GetKeyState(Modifier)
			ModifierRow := this.Keys[Modifier][1]
			ModifierColumn := this.Keys[Modifier][2]
			if (ModifierOn and this.Controls[ModifierRow, ModifierColumn].Colour != this.ToggledButtonColour) {
				this.UpdateGraphics(this.Controls[ModifierRow, ModifierColumn], this.ToggledButtonColour)
			}
			else if (not ModifierOn and this.Controls[ModifierRow, ModifierColumn].Colour = this.ToggledButtonColour) {
				if (ModifierRow = this.RowIndex and ModifierColumn = this.ColumnIndex)
					this.UpdateGraphics(this.Controls[ModifierRow, ModifierColumn], this.ActiveButtonColour)
				else
					this.UpdateGraphics(this.Controls[ModifierRow, ModifierColumn], this.ButtonColour)
			}
		}
		Return
	}


	MonitorAllKeys() {
		For _, Row in this.Layout {
			For i, Key in Row {
				Key := Key.1
				if (Key = "CapsLock" or Key = "ScrollLock")
					KeyOn := GetKeyState(Key, "T")
				else
					KeyOn := GetKeyState(Key)
				KeyRow := this.Keys[Key][1]
				KeyColumn := this.Keys[Key][2]
				if (KeyOn and this.Controls[KeyRow, KeyColumn].Colour != this.ToggledButtonColour) {
					this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], this.ToggledButtonColour)
				}
				else if (not KeyOn and this.Controls[KeyRow, KeyColumn].Colour = this.ToggledButtonColour) {
					if (KeyRow = this.RowIndex and KeyColumn = this.ColumnIndex)
						this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], this.ActiveButtonColour)
					else
						this.UpdateGraphics(this.Controls[KeyRow, KeyColumn], this.ButtonColour)
				}
			}
		}
		Return
	}

	SendPress(Key) {
		SentRow := this.Keys[Key][1]
		SentColumn := this.Keys[Key][2]
		OldColor := this.Controls[SentRow][SentColumn].Colour
		this.UpdateGraphics(this.Controls[SentRow, SentColumn], this.SentButtonColour)
		SendInput, % "{Blind}{" Key "}" 
		For _, Modifier in this.Modifiers {
			ModifierOn := GetKeyState(Modifier)
			if (ModifierOn)
				SendInput, % "{" Modifier " up}"
		}
		Sleep, 100
		if (SentRow = this.RowIndex and SentColumn = this.ColumnIndex)
			this.UpdateGraphics(this.Controls[SentRow, SentColumn], this.ActiveButtonColour)
		else
			this.UpdateGraphics(this.Controls[SentRow, SentColumn], this.ButtonColour)
		Return
	}

	Hide() {
		this.Enabled := False
		Gui, OSK: Hide
		this.SetTimer("MonitorKeyPresses", "off")
		return
	}

	Toggle() {
		If this.Enabled {
			this.Hide()
		}
		Else {
			this.Show()
		}
		Return
	}

    ChangeIndex(Direction) {
		if (not this.RowIndex) {
			this.RowIndex := 4
			this.ColumnIndex := 7
		}

		if (this.Controls[this.RowIndex, this.ColumnIndex].Colour != this.ToggledButtonColour)
			this.UpdateGraphics(this.Controls[this.RowIndex, this.ColumnIndex], this.ButtonColour)

		this.HandleChangeIndex(Direction)

        if (Direction = "Up") {
			if this.RowIndex = 1
				this.RowIndex := this.Controls.Length()
			else
				this.RowIndex := this.RowIndex - 1
            this.ColumnIndex := min(this.ColumnIndex, this.Controls[this.RowIndex].Length())
        }
        if (Direction = "Down") {
            this.RowIndex := mod(this.RowIndex, this.Controls.Length()) + 1
            this.ColumnIndex := min(this.ColumnIndex, this.Controls[this.RowIndex].Length())
        }
        if (Direction = "Left") {
			if this.ColumnIndex = 1
				this.ColumnIndex := this.Controls[this.RowIndex].Length()
			else
				this.ColumnIndex := this.ColumnIndex - 1
        }
        if (Direction = "Right") {
            this.ColumnIndex := mod(this.ColumnIndex, this.Controls[this.RowIndex].Length()) + 1
        }

		if (this.Controls[this.RowIndex, this.ColumnIndex].Colour != this.ToggledButtonColour)
			this.UpdateGraphics(this.Controls[this.RowIndex, this.ColumnIndex], this.ActiveButtonColour)
    }

	HandleChangeIndex(Direction) {
		; hardcoded logic to fix unusual index changes due to variable button widths
		if (this.RowIndex = 1) {
			if (this.ColumnIndex > 1 and Direction = "Down")
				this.ColumnIndex += 1
			else if (this.ColumnIndex > 12 and Direction = "Up")
				this.ColumnIndex -= 5
			else if (this.ColumnIndex > 8 and Direction = "Up")
				this.ColumnIndex -= 4
			else if (this.ColumnIndex > 3 and Direction = "Up")
				this.ColumnIndex := 4
		}
		else if (this.RowIndex = 2) {
			if (this.ColumnIndex > 1 and Direction = "Up")
				this.ColumnIndex -= 1
		}
		else if (this.RowIndex = 3) {
			if (this.ColumnIndex = 14 and Direction = "Down")
				this.ColumnIndex -= 1
			else if (this.ColumnIndex > 14 and Direction = "Down")
				this.RowIndex += 1

		}
		else if (this.RowIndex = 4) {
			if (this.ColumnIndex = 13 and Direction = "Up") 
				this.ColumnIndex += 1
			else if (this.ColumnIndex = 13 and Direction = "Down")
				this.ColumnIndex -= 1
		}
		else if (this.RowIndex = 5) {
			if (this.ColumnIndex = 13 and Direction = "Up") {
				this.RowIndex -= 1
				this.ColumnIndex += 3
			}
			else if (this.ColumnIndex = 13 and Direction = "Down")
				this.ColumnIndex -= 3
			else if (this.ColumnIndex = 12 and Direction = "Up")
				this.ColumnIndex += 1
			else if (this.ColumnIndex > 8 and Direction = "Down")
				this.ColumnIndex -= 4
			else if (this.ColumnIndex > 3 and Direction = "Down")
				this.ColumnIndex := 4
		}
		else if (this.RowIndex = 6) {
			if (this.ColumnIndex > 7 and Direction = "Down") {
				this.ColumnIndex += 5
			}
			else if (this.ColumnIndex > 4 and (Direction = "Up" or Direction = "Down")) {
				this.ColumnIndex += 4
			}
			else if (this.ColumnIndex = 4 and (Direction = "Up" or Direction = "Down")) {
				this.ColumnIndex := 6
			}
		}
		return
	}

    UpdateGraphics(Obj, Colour){
        GuiControl, % "OSK: +C" Colour, % Obj.Progress
        GuiControl, OSK: +Redraw, % obj.Text
		Obj.Colour := Colour
        Return
    }
}