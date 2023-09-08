; RunAsAdmin() ; uncomment if you launch dark and darker with admin privileges for some reason
#Requires AutoHotkey v2.0.7
#SingleInstance Force
#Warn
#WinActivateForce
#Include lib/Gdip_All.ahk

F5::Reload()
!Esc::ExitApp()

dad := MyDad()

class MyDad {
  static myGui := {}
  circles := [] ; array of circle guis
  coords := [] ; array of circle coords, saved as objects {x: xpos, y: ypos, w: width, h: height}
  count := 0  ; count of circles
  mode := 0 ; 0 = off, 1 = coords set, 2 = listing loop operating
  windowState := 0 ; 0 = not found, 1 = found - state of dad window
  helpState := 0 ; 0 = off, 1 = on - state of help gui
  
  __New() {
    this.myGui := Gui("+MinimizeBox -Resize +AlwaysOnTop +DPIScale", "myDad")
    this.myGui.SetFont("s14", "Calibri")
    this.myGui.AddText(, "myDad")
    this.myGui.help := this.myGui.AddButton("vHelp  w25 h25 x+152", "?").OnEvent("Click", (*) => this.Help())
    this.myGui.SetFont("s12")
    this.myGui.AddText("vInfo y50 x20", "Enter your listing text below:")
    this.myGui.Add("Edit", "vEditBox w230")
    this.myGui.AddButton("vbSet Default w71", "Set")
    this.myGui.AddButton("vbStart +Disabled wp x+9", "Start").OnEvent("Click", (*) => this.Start())
    this.myGui.AddButton("vbStop wp x+9", "Reset")
    this.myGui.SetFont("s10")
    this.myGui.sb := this.myGui.Add("StatusBar")
    
    this.myGui["bSet"].OnEvent("Click", (*) => this.Set())
    this.myGui["bSet"].OnEvent("ContextMenu", (*) => this.DeleteCircle())
    this.myGui.OnEvent("Close", (*) => ExitApp())
    
    this.myGui.Show()
    this.CheckWindow()
    SetTimer((*) => this.CheckWindow(), 3000)
    SetTimer((*) => this.ButtonOperation(), 300)
  }
  
  ButtonOperation() {
    switch (this.windowState) {
      case 0:  ; window not found
        this.mode := 0
        this.myGui["bSet"].Enabled := 0
        this.myGui["bStart"].Enabled := 0
        this.myGui["bStop"].Enabled := 1
        this.myGui["bStop"].Text := "Reset"
        this.myGui["bStop"].OnEvent("Click", (*) => this.Reset(), -1)
      case 1: ; window found
        switch (this.mode) {
          case 0: ; off
            this.myGui["bSet"].Enabled := 1
            this.myGui["bStart"].Enabled := 0
            this.myGui["bStop"].Enabled := 1
            this.myGui["bStop"].Text := "Reset"
            this.myGui["bStop"].OnEvent("Click", (*) => this.Reset(), -1)
            this.GetCircleCoords()
          case 1: ; coords set
            this.myGui["bSet"].Enabled := 1
            this.myGui["bStart"].Enabled := 1
            this.myGui["bStop"].Enabled := 1
            this.myGui["bStop"].Text := "Reset"
            this.myGui["bStop"].OnEvent("Click", (*) => this.Reset(), -1)
            this.GetCircleCoords()
          case 2: ; listing loop operating
            this.myGui["bSet"].Enabled := 0
            this.myGui["bStart"].Enabled := 0
            this.myGui["bStop"].Enabled := 1
            this.myGui["bStop"].Text := "Stop"
            this.myGui["bStop"].OnEvent("Click", (*) => this.Stop(), -1)
            this.GetCircleCoords()
        }
    }
  }
  
  Set() {
    this.circles.Push(this.MakeCircle(this.count += 1))
    this.myGui.sb.Text := "Circle " this.count " created."
    (this.circles.Length == 0) ? (this.mode := 0) : (this.mode := 1)
    this.GetCircleCoords()
  }
  
  Start() {
    if !this.GetCircleCoords() {
      this.myGui.sb.Text := "No circle coordinates have been set."
      this.mode := 0
      return 0
    }
    
    local rdm := 0
    SetTimer((*) => this.GetCircleCoords(), 0)
    this.mode := 2
    for circle in this.circles {
      circle.Opt("+E0x20")
    }
    Sleep(500)
    
    while this.mode := 2 {
      this.myGui.sb.Text := "Listing " this.count " items."
      try WinActivate("ahk_class UnrealWindow")
      catch {
        this.myGui.sb.Text := "Please launch Dad first."
        this.mode := 0
        return 0
      }
      
      for coord in this.coords {
        if this.mode != 2 {
          break
        }
        Sleep(100 + Random(0, 100))
        Send("{Shift down}")
        Sleep(100 + Random(0, 100))
        Click(coord.x + (coord.w//2), coord.y + (coord.h//2))
        Sleep(100 + Random(0, 100))
        Send("{Shift up}")
        Sleep(100 + Random(0, 100))
      }
      Send(this.myGui["EditBox"].Text "{Enter}")
      rdm := Random(1000, 2000)
      slp := ((rdm + 9100) // 100)
      this.myGui.sb.Text := "Waiting " (rdm + 9100) "ms..."
      
      loop 100 {
        if this.mode != 2 {
          this.myGui.sb.Text := "Listing stopped."
          for circle in this.circles {
            circle.Opt("-E0x20")
          }
          return
        }
        else
          Sleep(slp)
      }
      
    }
  }
  
  Stop() {
    this.mode := 1
    return 1
  }
  
  Reset() {
    local circle
    if this.circles.Length != 0 {
      for circle in this.circles {
        circle.Destroy()
      }
    }
    this.circles := [], this.coords := []
    this.count := 0, this.mode := 0
    this.myGui["EditBox"].Text := ""
    this.myGui.sb.Text := "Reset."
  }
  
  GetCircleCoords() {
    local xpos:=ypos:=wid:=hgt:=0
    this.coords := []
    
    if !this.circles.Length {
      this.mode := 0
      return 0
    }
    else if this.circles.Length > 0 {
      for index, circle in this.circles {
        WinGetPos(&xpos, &ypos, &wid, &hgt, circle.Title)
        this.coords.Push({x: xpos, y: ypos, w: wid, h: hgt})
      }
      return 1
    }
  }
  
  CheckWindow() {
    switch (WinExist("ahk_class UnrealWindow")) {
      case 0:
        this.myGui.sb.Text := "Dad window not detected."
        this.windowState := 0
        if (this.circles.Length == 0) {
          this.mode := 0
        }
      default:
        if (this.myGui.sb.Text == "Dad window not detected.") {
          this.myGui.sb.Text := ""
        }
        this.windowState := 1
    }
  }
  
  MakeCircle(count) {
    ValidateToken(token := Gdip_Startup())
    OnExit(ExitFunc)
    
    local circleGui, handle, bitmap, deviceContext, oldBitmap, graphics, brush
    local width := 40, height := 40, options := "y30p Centre cbb000000 r4 s20", font := "Arial"
    
    circleGui := Gui("-Caption +E0x80000 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs", "circ" count)
    circleGui.Add("Edit", "w" width " h" height " y40 vcircleEdit")
    circleGui.Show("NA")
    handle := WinExist()
    bitmap := CreateDIBSection(width, height)
    deviceContext := CreateCompatibleDC()
    oldBitmap := SelectObject(deviceContext, bitmap)
    graphics := Gdip_GraphicsFromHDC(deviceContext)
    Gdip_SetSmoothingMode(graphics, 4)
    brush := Gdip_BrushCreateSolid(0x808cff3b)
    Gdip_FillEllipse(graphics, brush, 0, 0, width, height)
    Gdip_DeleteBrush(brush)
    VerifyFont(font)
    Gdip_TextToGraphics(graphics, String(count), options, font, width, height)
    UpdateLayeredWindow(handle, deviceContext, (A_ScreenWidth-width)//2, (A_ScreenHeight-height)//2, width, height)
    OnMessage(0x201, WM_LBUTTONDOWN)
    
    SelectObject(deviceContext, oldBitmap)
    DeleteObject(bitmap)
    DeleteDC(deviceContext)
    Gdip_DeleteGraphics(graphics)
    
    return circleGui
    
    WM_LBUTTONDOWN(wParam:="", lParam:="", msg:="", hwnd:="") {
      PostMessage(0xA1, 2)
    }
    
    ValidateToken(token) {
      if !(token) {
        MsgBox("Gdiplus failed to start. Please ensure you have gdiplus on your system")
        ExitApp()
      }
    }
    
    VerifyFont(font) {
      if !(Gdip_FontFamilyCreate(font)) {
        MsgBox("The font you have specified does not exist on the system.")
        ExitApp()
      }
    }
    
    ExitFunc(exitReason, exitCode) {
      Gdip_Shutdown(token)
    }
  }
  
  DeleteCircle() {
    local last
    try last := this.circles.RemoveAt(-1)
    catch {
      this.myGui.sb.Text := "No circles to delete."
      return 0
    }
    else {
      last.Destroy()
      this.myGui.sb.Text := "Circle " this.count " deleted."
      this.count -= 1
      if this.count == 0 {
        this.mode := 0
      }
      this.GetCircleCoords() ? (this.mode := 1) : (this.mode := 0)
      this.ButtonOperation()
    }
  }
  
  Help() {
    local x:=y:=w:=h:=0
    WinGetPos(&x, &y, &w, &h, "myDad")
    if this.helpState == 0 {
      this.helpState := 1
      newWidth := w + 300
      this.myGui.Move(,,newWidth)
      
      helpTab := this.myGui.Add("Tab3", "w285 ym", ["Instructions","Hotkeys","About"])
      
      helpTab.UseTab(1)
      this.myGui.SetFont("s9")
      this.myGui.Add("Edit", "w250 h100 VScroll +ReadOnly", "1. Start 'Dad' script.`n2. Click 'Set' to create draggable circles on stash items.`n3. Right-click 'Set' to delete the last circle.`n4. Input desired trade chat text.`n5. Click 'Start' to begin listing process, which auto-repeats every 10-11 seconds.`n6. Click 'Stop' to end the process.`n7. Click 'Reset' to clear all circles and text.")      
      
      helpTab.UseTab(2)
      this.myGui.Add("Text", "w275", "`nF5:   Reload App`n`nAlt+Esc:   Exit App")
      
      helpTab.UseTab(3)
      this.myGui.Add("Text", "w275", "`nmyDad v1.0`nby Xsollus`n`nhttps://github.com/Xsollus/myDad")
      helpTab.UseTab()
      this.myGui.Show()
      
      
      this.myGui.Show()
    }
    else if this.helpState == 1 {
      this.helpState := 0
      oldWidth := w - 300
      this.myGui.Move(,,oldWidth)
      this.myGui.Show()
    }
  }
  
}

; RunAsAdmin() ; auto-relaunch as admin if needed
RunAsAdmin() {
  full_command_line := DllCall("GetCommandLine", "str")
  if not (A_IsAdmin or RegExMatch(full_command_line, " /restart(?!\S)")) {
    try
      {
      if A_IsCompiled
        Run '*RunAs "' A_ScriptFullPath '" /restart'
      else
        Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
  }
}
