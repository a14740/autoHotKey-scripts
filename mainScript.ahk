
XButton1::End
XButton2::Home

time_status := 2
;AC 电源提示
new_status := getSystemPowerStatus()
SoundPlay "*-1"
acPowerAlarm(new_status)
current_status := new_status
SetTimer(acPowerMain, 8000)
acPowerMain(){
	global current_status
	global new_status := getSystemPowerStatus()
	;acPowerAlarm(0)
        if new_status != current_status{
        	;notify_change(current_status, new_status)
        	SoundPlay "*-1"
            acPowerAlarm(new_status)			
            current_status := new_status
        }
}
acPowerAlarm(status){
	if status {
		c := "cBlue"
		t := "有电✌"
		xn:= 140
		time_status := 2
		changeBrightness(45)
		;timeBrightness()
	}else {
		c := "cRed"
		t := "停电了!☹"
		xn:= 200
		;if (getBrightness() > 40)
			changeBrightness(30)
	}
	acPowerGui := Gui("+AlwaysOnTop +Disabled -SysMenu +Owner", "电源")
	acPowerGui.SetFont(c " s22", "微软雅黑")
	acPowerGui.Add("Text","Center", t)
	acPowerGui.Show("NoActivate NA X" SysGet(78)-xn " Y" SysGet(79)-100)
	SetTimer(DestroyTip, 5000)
	DestroyTip() {
    acPowerGui.Destroy()
    SetTimer , 0
	}
}
GetSystemPowerStatus()    { ;  ahk2.0
    buf:=buffer(12,0)
	if (dllCall("Kernel32.dll\GetSystemPowerStatus", "Ptr",buf.Ptr))    {
         ACLineStatus := numGet(buf,0,"UChar")
    }
    return ACLineStatus ; bRet
}

;按照时间改变亮度
SetTimer(timeBrightness, 600000)
timeBrightness(){
	global time_status, new_status
	currentTime := FormatTime(, "H") 
	if new_status && currentTime > 8 && currentTime < 19 && time_status!=0{
		changeBrightness(70)
		time_status := 0
		}
	if new_status && (currentTime < 9 || currentTime > 18) && time_status!=1{
		changeBrightness(45)
		time_status := 1	
		;MsgBox "当前系统时间是:" currentTime
	}
}
changeBrightness(brightness, timeout := 2) {
 For property in ComObjGet("winmgmts:\\.\root\WMI").ExecQuery("SELECT * FROM WmiMonitorBrightnessMethods")
  property.WmiSetBrightness(timeout, brightness := Max(0, Min(brightness, 100)))
}
getBrightness() {
 For property in ComObjGet("winmgmts:\\.\root\WMI").ExecQuery("SELECT * FROM WmiMonitorBrightness ")
  ;property.WmiSetBrightness(timeout, brightness := Max(0, Min(brightness, 100)))
  iCurrentBrightness := Format("{:d}", "0x" property.CurrentBrightness) ;转10进制
 return iCurrentBrightness
}
;changeBrightness(20)
^#B::MsgBox 'brightness: ' getBrightness() "`nAC: " GetSystemPowerStatus() "`ntime_status: " time_status ;"`ncurrentTime: " currentTime
^#C::{
  global time_status
  
  changeBrightness(10)
}

;贴图
#Requires AutoHotkey v2.0
#SingleInstance Force
 
CoordMode 'Mouse', 'Screen'
;CoordMode 'ToolTip', 'Screen'
 
;#Include 'Tip.ahk' ; 先前写的`更常用的ToolTip`
 
; '#898374'
class Config {
  static useRandomBgc := false ; NOTE: some bugs there, cannot be used against a solid color background
  static defaultBgc := '00c5cd'
  static guiOption := '+AlwaysOnTop -Caption +Border +ToolWindow'
  static guiTransparent := 160
 
  static singleton := false ; if true ,the gui instance will be reused
}
 
!`:: {
  ;ToolTip 'READY'
  SystemCursors := [32512,32513,32514,32515,32516,32640,32641,32642,32643,32644,32645,32646,32648,32649,32650,3265]
	CursorShared  := DllCall( "LoadCursor", "Uint",0, "Int",32515 )
	for CursorID in SystemCursors {
		CursorHandle := DllCall("CopyImage", "ptr", CursorShared, "uint", 2, "int", 0, "int", 0, "uint", 0, "ptr")
		DllCall("SetSystemCursor", "uint", CursorHandle, "int", CursorID)
	}
  Hotkey 'LButton', StartClip, 'On'
  Hotkey 'Esc', Cancel, 'On'
}
 
Cancel(*) {
  Hotkey 'LButton', 'Off'
  DllCall("SystemParametersInfo", "uint", SPI_SETCURSORS := 0x57, "uint", 0, "ptr", 0, "uint", 0)
  ;Tip.ShowTip('CANCEL')
}
 
StartClip(*) {
  g := Config.singleton
    ? GetGui()
    : Gui(Config.guiOption)
  g.BackColor := Config.useRandomBgc
    ? GetRandomColor()
    : Config.defaultBgc
  MouseGetPos &begin_x, &begin_y
  g.Show('x' begin_x ' y' begin_y)
  WinSetTransparent(Config.guiTransparent, 'ahk_id' g.Hwnd)
  last_x := 0, last_y := 0
  while GetKeyState('LButton', 'P') {
    MouseGetPos &end_x, &end_y
    x := End_x < Begin_x ? End_x : Begin_x
    y := End_y < Begin_y ? End_y : Begin_y
    ; caculate gui size
    scope_x := Abs(begin_x - end_x)
    scope_y := Abs(begin_y - end_y)
    if last_x != end_x || last_y != end_y {
      ;ToolTip(scope_x 'X' scope_y, x, y - 20, 1)
      ;ToolTip('(' end_x ',' end_y ')', end_x, end_y + 20, 2)
    }
    last_x := end_x
    last_y := end_y
    g.Move(x, y, scope_x, scope_y)
    Sleep 5
  }
  Hotkey 'LButton', 'Off'
  Hotkey 'Esc', 'Off'
  DllCall("SystemParametersInfo", "uint", SPI_SETCURSORS := 0x57, "uint", 0, "ptr", 0, "uint", 0)
;ToolTip
  ;ToolTip , , , 2
  proxy := g.AddText('xp w' scope_x ' h' scope_y,)
  proxy.OnEvent('DoubleClick', (*) => WinClose('ahk_id' g.Hwnd))
  fn := MoveWin.Bind(g.Hwnd)
  proxy.OnEvent('Click', fn)
  ClipScreen(g.Hwnd)
}
 
MoveWin(hwnd, *) {
  MouseGetPos(&px, &py)
  WinGetPos(&wx, &wy, , , 'ahk_id' hwnd)
  dx := wx - px, dy := wy - py
  SetWinDelay 1
  While GetKeyState("LButton", "P") {
    MouseGetPos(&nx, &ny)
    WinMove(nx + dx, ny + dy, , , 'ahk_id' hwnd)
  }
}
 
GetGui() {
  static g := Gui(Config.guiOption)
  return g
}
 
GetRandomColor() {
  rx := Random(0, A_ScreenWidth)
  ry := Random(0, A_ScreenHeight)
  return Config.defaultBgc := PixelGetColor(rx, ry, 'RGB')
}
 
#Esc:: {
  global
  res := MsgBox('Exit?', , 0x1)
  if res != 'OK'
    return
  try ; only 'try'
    DllCall('user32.dll\ReleaseDC', 'int', 0, 'uint', hdc_frame)
  DllCall('user32.dll\ReleaseDC', 'int', 0, 'uint', hdd_frame)
  ExitApp()
}
 
!Esc:: {
  ;Tip.ShowTip('Clear all')
  for w in WinGetList('ahk_pid ' ProcessExist())
    try
      WinClose 'ahk_id' w
    catch
      ;MsgBox 'Error ocur on -> ' w
      return
}
 
hdd_frame := DllCall("GetDC", 'UInt', 0)
hdc_frame := ''
 
ClipScreen(MagnifierID) {
  global hdc_frame := DllCall("GetDC", 'UInt', MagnifierID)
  ; WinSetTransparent(255, 'ahk_id' MagnifierID) ; is unnecessary
  WinSetTransColor(Config.defaultBgc, 'ahk_id' MagnifierID)
  WinGetPos(&x, &y, &Rx, &Ry, 'ahk_id' MagnifierID)
 
  DllCall("gdi32.dll\StretchBlt", 'UInt', hdc_frame, 'Int'
    , 0, 'Int', 0, 'Int', Rx, 'Int', Ry
    , 'UInt', hdd_frame, 'UInt', x, 'UInt', y
    , 'Int', Rx, 'Int', Ry, 'UInt', 0xCC0020) ; SRCCOPY
 
  ; main work is done
  ;Tip.ShowTip('OVER')
}