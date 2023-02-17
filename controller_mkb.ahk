﻿#NoEnv
#SingleInstance
SendMode Input
SetWorkingDir %A_ScriptDir%
SetTitleMatchMode, 1 ; important for OSK
SetMouseDelay, -1
SetBatchLines, -1
Process, Priority,, H
DllCall("SetThreadDpiAwarenessContext", "ptr", -3, "ptr")

#Include, osk.ahk

; initialize objects
Global Session := new SessionSettings
Session.DetectJoystick()

Global keyboard := new OSK(Session.Keyboard.Theme, Session.Keyboard.Layout)

Global Joy := new JoyState()

; Enable Hotkeys
Joy.SetTimer("MonitorTrigger", Session.Joystick.JoyDelay) 
if Session.General.StartActive {
	ToggleHotKeys("On")
}
else {
	; ToggleHotKeys("On") ; otherwise toggle won't enable hotkeys
	ToggleHotkeys("Off")
}

; todo fix static hotkeys not being toggled
ToggleHotKeys(State) {
	if (State = "On") {
		SetTimer, DPad, % Session.Joystick.DPadDelay
		Joy.SetTimer("Monitor", Session.Joystick.JoyDelay)
	}
	else {
		SetTimer, DPad, off
		Joy.SetTimer("Monitor", "off")
	}

	Buttons := {1: "A", 2: "B", 3: "X", 4: "Y", 5: "LB", 6: "RB", 7: "Back", 8: "Start", 9: "LSDown", 10: "RSDown"} 

	; regular
	for ID, Button in Buttons {
		if Session.Button[Button] {
			if (State = "On" or Session.Button[Button] = "ToggleScript" or not IsLabel(Session.General.JoyNumber . "Joy" . ID))
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, % Session.Button[Button]
			else
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, Off
		}
	}

	; LT held down - can be used to have LT function as a modifier
	Hotkey, If, Joy.LTDown()
	for ID, Button in Buttons {
		Button := Button . "_LTDown"
		if Session.Button[Button] {
			if (State = "On" or Session.Button[Button] = "ToggleScript")
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, % Session.Button[Button]
			else
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, Off
		}
	}

	; keyboard on
	Hotkey, If, keyboard.Enabled
	for ID, Button in Buttons {
		Button := Button . "_KeyboardOn"
		if Session.Button[Button] {
			if (State = "On" or Session.Button[Button] = "ToggleScript")
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, % Session.Button[Button]
			else
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, Off
		}
	}

	; keyboard on with dpad navigation
	Hotkey, If, keyboard.Enabled && keyboard.IsDPadKeyboard()
	for ID, Button in Buttons {
		Button := Button . "_DPadKeyboard"
		if Session.Button[Button] {
			if (State = "On" or Session.Button[Button] = "ToggleScript")
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, % Session.Button[Button]
			else
				Hotkey, % Session.General.JoyNumber . "Joy" . ID, Off
		}
	}
}

; initialize hotkey conditions
#If, Joy.LTDown()
#If, keyboard.Enabled
#If, keyboard.Enabled && keyboard.IsDPadKeyboard()
#If

Labels() { ; so the returns don't interrupt the main thread

	ToggleScript:
		; KeyWait, % A_ThisHotkey
		; If (A_TimeSinceThisHotkey > 500) {
			If not Session.IsActive {
				Session.IsActive := not Session.IsActive
				ToggleHotKeys("On")	
				ComObjCreate("SAPI.SpVoice").Speak("On")
			}
			Else {
				Session.IsActive := not Session.IsActive
				ToggleHotKeys("Off")
				ComObjCreate("SAPI.SpVoice").Speak("Off")
			}
		; }
		Return

	LeftClick:
		Click, left, down
		KeyWait % A_ThisHotkey
		Click, left, up
		Return

	SendKeyboardPress:
		while GetKeyState(A_ThisHotkey) {
			if A_Index > 1
				Sleep, 150
			Key := keyboard.Layout[keyboard.RowIndex, keyboard.ColumnIndex].1
			keyboard.HandleOSKClick(Key)
			Sleep, 10
		}
		Return

	RightClick:
		Click, right, down
		KeyWait % A_ThisHotkey
		Click, right, up
		Return

	MiddleClick:
		Click, middle, down
		KeyWait % A_ThisHotkey
		Click, middle, up
		Return

	SendEnter:
		while GetKeyState(A_ThisHotkey) {
			if A_Index > 1
				Sleep, 200
			SendInput, {Enter}
			Sleep, 10
		}
		Return

	ToggleKeyboard:
		keyboard.Toggle()
		Return

	HoldAltTab:
		SendInput {Alt down}{Tab}
		KeyWait, % A_ThisHotkey
		SendInput {Alt up}
		Return

	SendBackspace:
		while GetKeyState(A_ThisHotkey) {
			if A_Index > 1
				Sleep, 150
			keyboard.SendPress("BS")
			Sleep, 10
		}
		Return

	SendSpace:
		while GetKeyState(A_ThisHotkey) {
			if A_Index > 1
				Sleep, 150
			keyboard.SendPress("Space")
			Sleep, 10
		}
		Return

	SendCapsLock:
		keyboard.SendModifier("CapsLock")
		Return
	
	SendCtrl:
		keyboard.SendModifier("LCtrl")
		Return

	DPad:
		while GetKeyState(Session.General.JoyNumber . "JoyPOV") != -1 {
			if A_Index > 1
				Sleep, 150
			JoyPOV := GetKeyState(Session.General.JoyNumber . "JoyPOV")
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
			else if (Joy.LTDown()) {
				if left
					SendInput ^+{Tab}
				else if up
					SendInput ^t
				else if down
					SendInput ^w
				else if right
					SendInput ^{Tab}
			} 
			else {
				if left
					SendInput {Left}
				else if up
					SendInput {Up}
				else if down
					SendInput {Down}
				else if right
					SendInput {Right}
			}
			Sleep, 10
		}
		return

}

NormalizeJoyRange(Joy) {
	; Takes a joy value between 0 and 100 and returns a range from -1 to 1 excluding the threshold amount

	; if joy not on
	if (not Joy and Joy != 0) { 
		return 0
	}

	if (Joy < Session.General.JoyThresholdLower) {
		return (Joy - Session.General.JoyThresholdLower) / Session.General.JoyThresholdLower
	}

	if (Joy > Session.General.JoyThresholdUpper) {
		return (Joy - Session.General.JoyThresholdUpper) / Session.General.JoyThresholdLower
	}

	; if joy doesnt exceed threshold
	return 0
}

class SessionSettings
; Settings and session info
{
	__new() {
		this.General := this.ReadSettings("GENERAL")
		this.General := this.General ? this.General : {StartActive: True, JoyThresholdLower: 35, JoyThresholdUpper: 65}

		this.Joystick := this.ReadSettings("JOYSTICK")
		this.Joystick := this.Joystick ? this.Joystick : {MouseTopSpeed: 5, ScrollTopSpeed: 30, InvertedScroll: False, RTBoost: 3, JoyDelay: 10, DPadDelay: 30}

		this.Button := this.ReadSettings("BUTTON") 
		this.Button := this.Button ? this.Button : {  A: "LeftClick"
													, B: "RightClick"
													, X: "SendEnter"
													, Y: "ToggleKeyboard"
													, L: "HoldAltTab"
													, LSDown: "MiddleClick"
													, LB_KeyboardOn: "SendBackSpace"
													, RB_KeyboardOn: "SendSpace"
													, LSDown_KeyboardOn: "SendCapsLock"
													, RSDown_KeyboardOn: "SendCtrl"
													, A_DPadKeyboard: "SendKeyboardPress"}

		this.Keyboard := this.ReadSettings("KEYBOARD")
		this.Keyboard := this.Keyboard ? this.Keyboard : {Keyboard.Theme: "dark", Keyboard.Layout: "qwerty"}

		this.IsActive := this.General.StartActive
	}

	ReadSettings(settings_category) {
		if not FileExist("settings.ini") {
			return False
		}

		IniRead, raw_settings, settings.ini, % settings_category
		settings := {}
		Loop, Parse, raw_settings, "`n"
		{
			Array := StrSplit(A_LoopField, "=")
			settings[Array[1]] := this.StrToBoolIfBool(Trim(Array[2]))
		}
		return settings 
	}

	StrToBoolIfBool(str) {
		lower_str := Format("{:L}", str)
		if (lower_str == "true")
			return True
		if (lower_str == "false")
			return False
		return str
	}

	DetectJoystick() {
		JoyInfo := GetKeyState(this.General.JoyNumber . "JoyInfo")
		if not JoyInfo {
			msgbox, 4,, % "WARNING: No Joystick detected with the specified JoyNumber" this.General.JoyNumber ".`rWould you like to detect a JoyNumber?"
			IfMsgBox, Yes 
			{
				Loop 10 {
					JoyInfo := GetKeyState(A_Index . "JoyInfo")
					if JoyInfo {
						MsgBox % "Using joystick " A_Index ", with properties: " JoyInfo
						this.General.JoyNumber := A_Index
						Return	
					}
				}
			}
			MsgBox No Joystick detected. Exiting Script.
			ExitApp
		}
	}

}

Class JoyState
{
    __New() {
        this.velocity_x := 0
        this.velocity_y := 0
        this.Monitor := ObjBindMethod(this, "MonitorJoySticks")
        this.MonitorTrigger := ObjBindMethod(this, "MonitorTriggers")
    }

    SetTimer(timer_id, period) {
        timer := this[timer_id]
        SetTimer % timer, % period
		return
    }

	MonitorJoySticks() {
		RawJoyX := GetKeyState(Session.General.JoyNumber . "JoyX")
		this.LSx := Session.JoyStick.InvertedMouse ? - NormalizeJoyRange(RawJoyX) : NormalizeJoyRange(RawJoyX)

		RawJoyY := GetKeyState(Session.General.JoyNumber . "JoyY")
		this.LSy := Session.JoyStick.InvertedMouse ? - NormalizeJoyRange(RawJoyY) : NormalizeJoyRange(RawJoyY)

		RawJoyU := GetKeyState(Session.General.JoyNumber . "JoyU")
		this.RSx := Session.JoyStick.InvertedScroll ? - NormalizeJoyRange(RawJoyU) : NormalizeJoyRange(RawJoyU)

		RawJoyR := GetKeyState(Session.General.JoyNumber . "JoyR")
		this.RSy := Session.JoyStick.InvertedScroll ? NormalizeJoyRange(RawJoyR) : - NormalizeJoyRange(RawJoyR)

		this.MoveScrollWheel()
		this.MoveCursor()
		this.DPad()
	}

	MonitorTriggers() {
		RawJoyZ := GetKeyState(Session.General.JoyNumber . "JoyZ")
		this.LT := abs(max(NormalizeJoyRange(RawJoyZ), 0))
		this.RT := abs(min(NormalizeJoyRange(RawJoyZ), 0))
	}

	LTDown() {
		return this.LT
	}

	RTDown() {
		return this.RT
	}

    MoveScrollWheel() {
		; using mouse_event instead of SendInput to allow smooth scrolling
		; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-mouse_event

		; WheelUp/Down
		if this.RSy
			DllCall("mouse_event", uint, 0x0800, int, x, int, y, uint, (1 + Session.JoyStick.RTBoost * this.RT) * Session.Joystick.ScrollTopSpeed * this.RSy, int, 0)

		; WheelLeft/Right
		if this.RSx
			DllCall("mouse_event", uint, 0x1000, int, x, int, y, uint, (1 + Session.JoyStick.RTBoost * this.RT) * Session.Joystick.ScrollTopSpeed * this.RSx, int, 0)

		return
    }

    MoveCursor() {
		if this.LSx or this.LSy
			MouseMove, (1 + Session.Joystick.RTBoost * this.RT) * Session.Joystick.MouseTopSpeed * this.LSx,  (1 + Session.Joystick.RTBoost * this.RT) * Session.Joystick.MouseTopSpeed * this.LSy, 0, R
		Return
    }
}