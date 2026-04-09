--[[
    ███████╗███████╗███╗   ██╗██╗   ██╗    ██╗  ██╗██╗   ██╗██████╗
    ╚══███╔╝██╔════╝████╗  ██║██║   ██║    ██║  ██║██║   ██║██╔══██╗
      ███╔╝ █████╗  ██╔██╗ ██║██║   ██║    ███████║██║   ██║██████╔╝
     ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║    ██╔══██║██║   ██║██╔══██╗
    ███████╗███████╗██║ ╚████║╚██████╔╝    ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    ZENU Hub UI Library  v3.2 (Ultimate Edition)
    (c) discord.gg/zenuhub

    [NEW IN v3.0]
      + ColorPicker  : callback receives (Color3)
      + Watermark    : ZENUHub:CreateWatermark(opts) - FPS/Ping/Time floating bar
      + Theme Manager: ZENUHub:ApplyTheme(nameOrTable)  presets: Blue Green Purple Gold
                       ZENUHub:RegisterTheme(name,t)  ZENUHub:GetTheme()
      + Config I/O   : ZENUHub:SaveConfig(file) / ZENUHub:LoadConfig(file) - JSON
                       Settings helpers: auto-load on startup, manual save/load buttons
                       Per-component opt-out: Save=false when adding a component
                       Keybind: saves both Key AND Mode  (type "kb")
                       Dropdown / MultiDropdown values saved automatically via Flag
                       Config dropdown shows filenames with .json extension
      + Unload       : ZENUHub:Unload() - disconnects ALL events, destroys all GUIs
      + Keybind Modes: [•••] config button beside keybind
                       Toggle (fire once) | Hold (cb true/false) | Always (cb each heartbeat)
      + Tooltip Delay: 0.35s delay before tooltip appears

    [NEW IN v3.2]
      + Start=true   : ทุก component รองรับ Start=true เพื่อให้รัน Callback ทันทีตอนสร้าง
                       LoadConfig / AutoLoad จะเรียก callback ด้วยถ้า Start=true
                       ใช้งาน: section:AddToggle({..., Start=true, Callback=function(v) end})
                       Button: Start=true จะ fire ทันที (ไม่ส่งค่า เหมือนกดปุ่ม)
                       Keybind: Start=true จะส่ง KeyCode ปัจจุบัน (ไม่ fire key logic)
                       component ใดมี item:FireCallback() สำหรับเรียกจากภายนอกด้วย

    [NEW IN v3.1]
      + ResetToDefault : :ResetToDefault() restores Default= value on every component
                         (Toggle, Checkbox, Slider, Textbox, Dropdown, MultiDropdown,
                          ColorPicker, Keybind — Keybind also resets Mode)
      + ResetAll       : ZENUHub:ResetAllToDefault()
      + DeleteConfig   : ZENUHub:DeleteConfig(file) + [X] Delete button in config UI
      + Flag init      : Flags[flag] populated immediately at creation
      + MultiDD fix    : Default={} pre-selections applied; save uses explicit "mdd" type
      + Keybind fix    : SaveConfig now guaranteed to write key+mode ("kb" type)
                         Flags updated instantly when user listens a new key
      + Save=false     : callbacks no longer pollute Flags for unsaved components

    Full control API on every component item:
      Common    : :Destroy()  :Show()  :Hide()  :SetEnabled(bool)  :Get()
      Named     : :SetName(s)
      Toggle    : :Set(bool)  :Toggle()  :ResetToDefault()  :SetCallback(fn)
      Checkbox  : :Set(bool)  :Toggle()  :ResetToDefault()  :SetCallback(fn)
      ColorPick : :Set(Color3)  :ResetToDefault()  :SetCallback(fn)   cb(Color3)
      Button    : :Fire()  :SetCallback(fn)
      Slider    : :Set(n)  :SetRange(min,max)  :SetStep(n)  :SetSuffix(s)  :ResetToDefault()  :SetCallback(fn)
                  opts: Step=n → ขนาดการกระโดด เช่น Step=5 หรือ Step=0.1
      Textbox   : :Set(s)  :Clear()  :SetPlaceholder(s)  :ResetToDefault()  :SetCallback(fn)
      Dropdown  : :Set(s)  :Clear()  :SetItems(t)  :AddItem(s)  :RemoveItem(s)  :Refresh(t)  :ResetToDefault()  :SetCallback(fn)
                  opts: Required=true  → ห้าม deselect ให้ว่าง
      MultiDD   : :Set(t)  :Clear()  :SetItems(t)  :AddItem(s)  :RemoveItem(s)  :Refresh(t)  :SetMaxSelect(n)  :SetMinSelect(n)  :GetSelected()  :ResetToDefault()  :SetCallback(fn)
                  opts: MinSelect=n   → กำหนดจำนวนที่เลือกขั้นต่ำ
      Label     : :SetText(s)  :SetColor(c)  :SetTextSize(n)
      Text      : :SetText(s)  :SetColor(c)  :SetTextSize(n)  :SetAlign(s)
      Keybind   : :Set(kc)  :Clear()  :SetMode(m)  :ResetToDefault()  :SetCallback(fn)  :FireCallback()
      All above : Start=true → รัน callback ทันทีตอนสร้าง และตอน LoadConfig/AutoLoad
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local CoreGui          = game:GetService("CoreGui")
local TextService      = game:GetService("TextService")
local Workspace        = game:GetService("Workspace")

-- ============================================================
--  LIBRARY
-- ============================================================
local ZENUHub       = {}
ZENUHub.__index     = ZENUHub
ZENUHub.Flags       = {}
ZENUHub._connections = {}   -- all tracked RBXScriptConnections for :Unload()
ZENUHub._guiList     = {}   -- all ScreenGuis for :Unload()
ZENUHub._flaggedItems= {}   -- flag -> item, used by SaveConfig / LoadConfig

-- ── Built-in Themes (accent colour overrides applied to T table) ──
ZENUHub._themes = {
    Blue = {
        RED=Color3.fromRGB(50,130,255),  RED_D=Color3.fromRGB(28,75,190),
        RED_B=Color3.fromRGB(85,165,255),RED_DIM=Color3.fromRGB(10,28,80),
        BG_SUBPILL_A=Color3.fromRGB(50,130,255),TOG_ON=Color3.fromRGB(50,130,255),
        SLD_FILL=Color3.fromRGB(50,130,255),BORDER_R=Color3.fromRGB(18,50,100),
        N_INFO=Color3.fromRGB(50,130,255),
    },
    Green = {
        RED=Color3.fromRGB(35,185,85),   RED_D=Color3.fromRGB(20,115,50),
        RED_B=Color3.fromRGB(60,220,110),RED_DIM=Color3.fromRGB(10,40,18),
        BG_SUBPILL_A=Color3.fromRGB(35,185,85),TOG_ON=Color3.fromRGB(35,185,85),
        SLD_FILL=Color3.fromRGB(35,185,85),BORDER_R=Color3.fromRGB(18,68,32),
    },
    Purple = {
        RED=Color3.fromRGB(145,60,235),  RED_D=Color3.fromRGB(90,35,165),
        RED_B=Color3.fromRGB(185,90,255),RED_DIM=Color3.fromRGB(40,15,72),
        BG_SUBPILL_A=Color3.fromRGB(145,60,235),TOG_ON=Color3.fromRGB(145,60,235),
        SLD_FILL=Color3.fromRGB(145,60,235),BORDER_R=Color3.fromRGB(60,18,105),
    },
    Gold = {
        RED=Color3.fromRGB(225,165,30),  RED_D=Color3.fromRGB(155,110,15),
        RED_B=Color3.fromRGB(255,200,60),RED_DIM=Color3.fromRGB(70,45,8),
        BG_SUBPILL_A=Color3.fromRGB(225,165,30),TOG_ON=Color3.fromRGB(225,165,30),
        SLD_FILL=Color3.fromRGB(225,165,30),BORDER_R=Color3.fromRGB(90,60,12),
    },
}

-- ============================================================
--  THEME
-- ============================================================
local T = {
    BG_WIN      = Color3.fromRGB(16, 16, 20),
    BG_SIDE     = Color3.fromRGB(20, 20, 26),
    BG_HEAD     = Color3.fromRGB(11, 11, 14),
    BG_CARD     = Color3.fromRGB(24, 24, 32),
    BG_CARD_H   = Color3.fromRGB(30, 30, 40),
    BG_INPUT    = Color3.fromRGB(18, 18, 24),
    BG_DROP     = Color3.fromRGB(16, 16, 22),

    -- Sub-tab bar
    BG_SUBBAR   = Color3.fromRGB(13, 13, 17),
    BG_SUBPILL  = Color3.fromRGB(22, 22, 30),    -- inactive pill
    BG_SUBPILL_A= Color3.fromRGB(220, 30, 30),   -- active pill

    RED         = Color3.fromRGB(220,  30,  30),
    RED_D       = Color3.fromRGB(150,  18,  18),
    RED_B       = Color3.fromRGB(255,  60,  60),
    RED_DIM     = Color3.fromRGB( 60,  10,  10),

    LOGO_BG     = Color3.fromRGB(10,  10,  12),
    LOGO_BORDER = Color3.fromRGB(70,  70,  80),

    TXT_PRI     = Color3.fromRGB(238, 238, 244),
    TXT_SEC     = Color3.fromRGB(145, 145, 160),
    TXT_MUTED   = Color3.fromRGB( 75,  75,  90),

    BORDER      = Color3.fromRGB( 38,  38,  50),
    BORDER_R    = Color3.fromRGB( 90,  18,  18),
    SEP         = Color3.fromRGB( 28,  28,  38),

    TOG_OFF     = Color3.fromRGB(42,  42,  55),
    TOG_ON      = Color3.fromRGB(220, 30,  30),
    TOG_KNOB    = Color3.fromRGB(238, 238, 244),

    SLD_TRACK   = Color3.fromRGB(32,  32,  44),
    SLD_FILL    = Color3.fromRGB(220, 30,  30),
    SLD_THUMB   = Color3.fromRGB(238, 238, 244),

    N_BG        = Color3.fromRGB(16,  16,  22),
    N_SUCCESS   = Color3.fromRGB( 35, 185,  85),
    N_ERROR     = Color3.fromRGB(220,  35,  35),
    N_INFO      = Color3.fromRGB( 55, 140, 225),
    N_WARN      = Color3.fromRGB(225, 165,  30),
}

-- LAYOUT CONSTANTS
local SUB_BAR_H = 40   -- horizontal sub-tab pill bar height
local SIDE_W    = 72   -- sidebar width (wider to show icon + name)

-- Snapshot the Default theme now that T is fully defined
do local snap={} for k,v in pairs(T) do snap[k]=v end ZENUHub._themes.Default=snap end

-- ============================================================
--  TWEEN / SPRING
-- ============================================================
local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quint,
        dir or Enum.EasingDirection.Out), props):Play()
end
local function Spring(obj, props, t)
    Tween(obj, props, t or 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ============================================================
--  HELPERS
-- ============================================================
local function New(cls, p)
    local o = Instance.new(cls)
    for k,v in pairs(p or {}) do if k~="Parent" then o[k]=v end end
    if p and p.Parent then o.Parent=p.Parent end
    return o
end
local function Corner(par, r)
    return New("UICorner",{Parent=par, CornerRadius=UDim.new(0,r or 8)})
end
local function Stroke(par, th, col, tr)
    return New("UIStroke",{Parent=par,Thickness=th or 1,
        Color=col or T.BORDER, Transparency=tr or 0})
end
local function Pad(par, top, bot, lft, rgt)
    return New("UIPadding",{Parent=par,
        PaddingTop=UDim.new(0,top or 6), PaddingBottom=UDim.new(0,bot or 6),
        PaddingLeft=UDim.new(0,lft or 6), PaddingRight=UDim.new(0,rgt or 6)})
end
local function Hover(btn, norm, hov)
    btn.MouseEnter:Connect(function() Tween(btn,{BackgroundColor3=hov},0.14) end)
    btn.MouseLeave:Connect(function() Tween(btn,{BackgroundColor3=norm},0.14) end)
end

-- ============================================================
--  COLOR HELPERS  (for ColorPicker HEX/RGB inputs)
-- ============================================================
local function Color3ToHex(c)
    return string.format("%02X%02X%02X",
        math.clamp(math.floor(c.R*255+0.5),0,255),
        math.clamp(math.floor(c.G*255+0.5),0,255),
        math.clamp(math.floor(c.B*255+0.5),0,255))
end
local function HexToColor3(hex)
    hex = hex:gsub("#",""):upper():match("^%x+") or ""
    if #hex == 3 then
        hex = hex:sub(1,1):rep(2)..hex:sub(2,2):rep(2)..hex:sub(3,3):rep(2)
    end
    if #hex ~= 6 then return nil end
    local r = tonumber(hex:sub(1,2),16)
    local g = tonumber(hex:sub(3,4),16)
    local b = tonumber(hex:sub(5,6),16)
    if not (r and g and b) then return nil end
    return Color3.fromRGB(r,g,b)
end

-- ============================================================
--  TOOLTIP  (lazy singleton, floats near cursor)
-- ============================================================
local _ttGui, _ttFrame, _ttLbl
local _ttConn

local function _ensureTooltip()
    if _ttGui and _ttGui.Parent then return end
    _ttGui = New("ScreenGui",{Parent=CoreGui, Name="ZENUTooltip",
        ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true})
    _ttFrame = New("Frame",{Parent=_ttGui, BackgroundColor3=Color3.fromRGB(18,18,24),
        Size=UDim2.new(0,0,0,22), AutomaticSize=Enum.AutomaticSize.X,
        BorderSizePixel=0, ZIndex=9999, Visible=false})
    Corner(_ttFrame,5); Stroke(_ttFrame,1,Color3.fromRGB(55,55,70))
    _ttLbl = New("TextLabel",{Parent=_ttFrame, Text="",
        Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=Color3.fromRGB(200,200,215),
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.X,
        Size=UDim2.new(0,0,1,0), ZIndex=10000})
    Pad(_ttLbl,0,0,8,8)
end

local function SetupTooltip(frame, text)
    if not text or text == "" then return end

    -- place tooltip near a pixel position, staying inside viewport
    local function _placeAt(px, py)
        if not (_ttFrame and _ttFrame.Parent) then return end
        task.defer(function()
            if not (_ttFrame and _ttFrame.Parent) then return end
            local vp = workspace.CurrentCamera.ViewportSize
            local tw = _ttFrame.AbsoluteSize.X
            local th = _ttFrame.AbsoluteSize.Y
            -- prefer: slightly right of cursor, vertically centred on cursor
            local tx = px + 14
            local ty = py - math.floor(th / 2)
            -- push left if it would clip the right edge
            if tx + tw + 6 > vp.X then tx = px - tw - 14 end
            -- clamp top/bottom
            ty = math.clamp(ty, 4, vp.Y - th - 4)
            tx = math.clamp(tx, 4, vp.X - tw - 4)
            _ttFrame.Position = UDim2.new(0, tx, 0, ty)
        end)
    end

    -- mouse: show on enter after 0.35s delay to reduce visual noise
    local _ttPending = false
    frame.MouseEnter:Connect(function()
        _ttPending = true
        task.delay(0.35, function()
            if not _ttPending then return end
            _ensureTooltip()
            _ttLbl.Text  = text
            _ttFrame.Visible = true
            local mp = UserInputService:GetMouseLocation()
            _placeAt(mp.X, mp.Y)
            if _ttConn then _ttConn:Disconnect() end
            _ttConn = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement then
                    _placeAt(inp.Position.X, inp.Position.Y)
                end
            end)
        end)
    end)
    frame.MouseLeave:Connect(function()
        _ttPending = false
        if _ttFrame then _ttFrame.Visible = false end
        if _ttConn  then _ttConn:Disconnect(); _ttConn = nil end
    end)

    -- touch: show while finger is down, positioned at touch point
    frame.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch then return end
        _ensureTooltip()
        _ttLbl.Text      = text
        _ttFrame.Visible = true
        _placeAt(inp.Position.X, inp.Position.Y)
        if _ttConn then _ttConn:Disconnect() end
        _ttConn = inp.Changed:Connect(function()
            -- follow finger while it moves
            _placeAt(inp.Position.X, inp.Position.Y)
            if inp.UserInputState == Enum.UserInputState.End then
                _ttFrame.Visible = false
                if _ttConn then _ttConn:Disconnect(); _ttConn = nil end
            end
        end)
    end)
end

-- ============================================================
--  RIPPLE  (Touch-safe)
-- ============================================================
local function Ripple(btn)
    btn.ClipsDescendants = true
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1
        and inp.UserInputType~=Enum.UserInputType.Touch then return end
        local abs=btn.AbsolutePosition
        local x,y=inp.Position.X-abs.X, inp.Position.Y-abs.Y
        local sz=math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y)*2.2
        local r=New("Frame",{Parent=btn,
            BackgroundColor3=Color3.new(1,1,1), BackgroundTransparency=0.82,
            BorderSizePixel=0, Size=UDim2.new(0,0,0,0),
            Position=UDim2.new(0,x,0,y), ZIndex=btn.ZIndex+10})
        Corner(r,999)
        Tween(r,{Size=UDim2.new(0,sz,0,sz),
            Position=UDim2.new(0,x-sz/2,0,y-sz/2), BackgroundTransparency=1}, 0.48)
        task.delay(0.5, function() if r then r:Destroy() end end)
    end)
end

-- ============================================================
--  DRAG  (clamp to viewport)
-- ============================================================
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil
    
    frame.Active = true
    handle.Active = true
    
    if handle:IsA("GuiButton") then
        handle.Modal = true
    end

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.AbsolutePosition
            
            if handle:IsA("GuiButton") then
                handle.Modal = true
            end
            
            local connection
            connection = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        
        local d = inp.Position - dragStart
        local viewportSize = workspace.CurrentCamera.ViewportSize
        local frameSize = frame.AbsoluteSize

        local newX = startPos.X + d.X
        local newY = startPos.Y + d.Y

        newX = math.clamp(newX, 0, viewportSize.X - frameSize.X)
        newY = math.clamp(newY, 0, viewportSize.Y - frameSize.Y)

        frame.Position = UDim2.new(0, newX, 0, newY)
    end)
end

-- ============================================================
--  NOTIFICATIONS  (with queue — max 4 visible at once)
-- ============================================================
local NotifHolder
local N_ICON={Info="[i]",Success="[+]",Error="[!]",Warn="[?]"}
local _notifMax    = 4
local _notifActive = 0
local _notifQueue  = {}

local function EnsureNotif()
    if NotifHolder and NotifHolder.Parent then return end
    local sg=New("ScreenGui",{Parent=CoreGui,Name="ZENUNotif",
        ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true})
    table.insert(ZENUHub._guiList, sg)
    NotifHolder=New("Frame",{Parent=sg,BackgroundTransparency=1,
        Size=UDim2.new(0,310,1,0),Position=UDim2.new(1,-320,0,0)})
    New("UIListLayout",{Parent=NotifHolder,FillDirection=Enum.FillDirection.Vertical,
        VerticalAlignment=Enum.VerticalAlignment.Bottom,
        Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
    Pad(NotifHolder,0,18,0,10)
end

local function _dequeueNotif()
    if _notifActive < _notifMax and #_notifQueue > 0 then
        local opts = table.remove(_notifQueue, 1)
        ZENUHub:Notify(opts)
    end
end

function ZENUHub:Notify(opts)
    EnsureNotif()
    opts=opts or {}
    -- Queue if already at max visible
    if _notifActive >= _notifMax then
        table.insert(_notifQueue, opts)
        return
    end
    _notifActive = _notifActive + 1
    local title=opts.Title or "ZENU Hub"; local msg=opts.Message or ""
    local dur=opts.Duration or 4; local ntype=opts.Type or "Info"
    local acC={Info=T.N_INFO,Success=T.N_SUCCESS,Error=T.N_ERROR,Warn=T.N_WARN}
    local accent=acC[ntype] or T.N_INFO
    local icon=N_ICON[ntype] or "[i]"

    local card=New("CanvasGroup",{Parent=NotifHolder,BackgroundColor3=T.N_BG,
        Size=UDim2.new(1,0,0,72),BorderSizePixel=0,
        GroupTransparency=1})
    Corner(card,10); Stroke(card,1,T.BORDER)

    local iconBg=New("Frame",{Parent=card,
        BackgroundColor3=accent:Lerp(T.N_BG,0.7),
        Size=UDim2.new(0,32,0,32),Position=UDim2.new(0,14,0.5,-16),
        BorderSizePixel=0,ZIndex=3})
    Corner(iconBg,16)
    New("TextLabel",{Parent=iconBg,Text=icon,Font=Enum.Font.GothamBold,
        TextSize=12,TextColor3=accent,BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0),TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=4})

    New("TextLabel",{Parent=card,Text=title,Font=Enum.Font.GothamBold,
        TextSize=13,TextColor3=T.TXT_PRI,BackgroundTransparency=1,
        Size=UDim2.new(1,-70,0,18),Position=UDim2.new(0,56,0,14),
        TextXAlignment=Enum.TextXAlignment.Left,ZIndex=3})
        
    New("TextLabel",{Parent=card,Text=msg,Font=Enum.Font.Gotham,
        TextSize=11,TextColor3=T.TXT_SEC,BackgroundTransparency=1,
        Size=UDim2.new(1,-70,0,26),Position=UDim2.new(0,56,0,34),
        TextXAlignment=Enum.TextXAlignment.Left,TextWrapped=true,ZIndex=3})

    local bar=New("Frame",{Parent=card,BackgroundColor3=accent,
        Size=UDim2.new(1,0,0,3),Position=UDim2.new(0,0,1,-3),
        BorderSizePixel=0,ZIndex=5})

    card.Position=UDim2.new(1,50,0,0)
    Tween(card,{Position=UDim2.new(0,0,0,0),GroupTransparency=0},0.4,
        Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
        
    Tween(bar,{Size=UDim2.new(0,0,0,3)},dur,Enum.EasingStyle.Linear)

    local _closed = false
    local function CloseNotif()
        if _closed then return end
        _closed = true
        if card and card.Parent then
            Tween(card,{Position=UDim2.new(1,50,0,0),GroupTransparency=1},0.3,
                Enum.EasingStyle.Quint,Enum.EasingDirection.In)
            task.delay(0.35,function()
                if card then card:Destroy() end
                _notifActive = math.max(0, _notifActive - 1)
                _dequeueNotif()
            end)
        end
    end

    card.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            CloseNotif()
        end
    end)
    
    task.delay(dur,function()
        CloseNotif()
    end)
end


-- ============================================================
--  WATERMARK / STATUS INDICATOR
-- ============================================================
--[[
    ZENUHub:CreateWatermark(opts)
      opts.Name     string  — hub name        (default "ZENU Hub")
      opts.Version  string  — version string  (default "v3.0")
      opts.FPS      bool    — show FPS        (default true)
      opts.Ping     bool    — show ping ms    (default true)
      opts.Time     bool    — show HH:MM:SS   (default true)
      opts.Position string  — "TopLeft"|"TopRight"|"BottomLeft"|"BottomRight"
    Returns wm:  :Show()  :Hide()  :SetName(s)  :SetVersion(s)  :Destroy()
--]]
function ZENUHub:CreateWatermark(opts)
    opts = opts or {}
    local wmName   = opts.Name    or "ZENU Hub"
    local wmVer    = opts.Version or "v3.0"
    local showFPS  = opts.FPS  ~= false
    local showPing = opts.Ping ~= false
    local showTime = opts.Time ~= false
    local wmPos    = opts.Position or "TopRight"

    local posMap = {
        TopLeft     = {pos=UDim2.new(0,8,0,8),    anc=Vector2.new(0,0)},
        TopRight    = {pos=UDim2.new(1,-8,0,8),   anc=Vector2.new(1,0)},
        BottomLeft  = {pos=UDim2.new(0,8,1,-8),   anc=Vector2.new(0,1)},
        BottomRight = {pos=UDim2.new(1,-8,1,-8),  anc=Vector2.new(1,1)},
    }
    local pm = posMap[wmPos] or posMap.TopRight

    local WG = New("ScreenGui",{Parent=CoreGui, Name="ZENUWatermark",
        ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true})
    table.insert(ZENUHub._guiList, WG)

    local WF = New("Frame",{Parent=WG, BackgroundColor3=T.BG_WIN,
        AutomaticSize=Enum.AutomaticSize.X, Size=UDim2.new(0,0,0,26),
        Position=pm.pos, AnchorPoint=pm.anc, BorderSizePixel=0, ZIndex=200})
    Corner(WF,6); Stroke(WF,1,T.BORDER_R,0.4)
    -- Accent left bar
    New("Frame",{Parent=WF, BackgroundColor3=T.RED,
        Size=UDim2.new(0,3,1,-6), Position=UDim2.new(0,0,0,3),
        BorderSizePixel=0, ZIndex=201})
    local WL = New("TextLabel",{Parent=WF, Text="ZENU Hub",
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=T.TXT_PRI,
        BackgroundTransparency=1, AutomaticSize=Enum.AutomaticSize.X,
        Size=UDim2.new(0,0,1,0), RichText=true, ZIndex=201})
    Pad(WL,0,0,10,8)

    local _fps=60; local _fCnt=0; local _fTimer=0; local _wmVisible=true

    local _wmConn = RunService.Heartbeat:Connect(function(dt)
        if not _wmVisible then return end
        _fCnt=_fCnt+1; _fTimer=_fTimer+dt
        if _fTimer >= 0.5 then
            _fps=math.round(_fCnt/_fTimer); _fCnt=0; _fTimer=0
        end
        local parts = {}
        table.insert(parts,'<font color="#DC1E1E"><b>Z</b></font>  '..wmName)
        if wmVer ~= "" then table.insert(parts, wmVer) end
        if showTime  then table.insert(parts, os.date("%H:%M:%S")) end
        if showFPS   then table.insert(parts, _fps.." FPS") end
        if showPing  then
            local ok,ping = pcall(function()
                return math.round(Players.LocalPlayer:GetNetworkPing()*1000)
            end)
            table.insert(parts, (ok and ping or "?").."ms")
        end
        local sep = '  <font color="#3C3C50">|</font>  '
        WL.Text = table.concat(parts, sep)
    end)
    table.insert(ZENUHub._connections, _wmConn)

    local wm = {}
    function wm:Show()        _wmVisible=true;  WF.Visible=true  end
    function wm:Hide()        _wmVisible=false; WF.Visible=false end
    function wm:SetName(n)    wmName=n end
    function wm:SetVersion(v) wmVer=v end
    function wm:Destroy()
        _wmConn:Disconnect()
        for i,c in ipairs(ZENUHub._connections) do
            if c==_wmConn then table.remove(ZENUHub._connections,i); break end
        end
        if WG and WG.Parent then WG:Destroy() end
        for i,g in ipairs(ZENUHub._guiList) do
            if g==WG then table.remove(ZENUHub._guiList,i); break end
        end
    end
    return wm
end


-- ============================================================
--  CONFIG  —  SaveConfig / LoadConfig
-- ============================================================
--[[
    ZENUHub:SaveConfig(filename)
      Serialises ZENUHub.Flags to JSON and writes via writefile().
      Supports: boolean, number, string, Color3, EnumItem(KeyCode), table(MultiDD).
      filename omits extension — ".json" is appended automatically.

    ZENUHub:LoadConfig(filename)
      Reads the file, deserialises, and calls :Set() on every flagged component.

    For the Settings tab convenience helpers see Window:AddConfigSection(section).
--]]
-- ── CONFIG FOLDER & PATH HELPERS ──────────────────────────────
local CFG_FOLDER     = "Zenu_Config"
local AUTO_CFG_NAME  = "Auto_Config"

local function _cfgEnsureFolder()
    if not isfolder(CFG_FOLDER) then
        pcall(function() makefolder(CFG_FOLDER) end)
    end
end

local function _cfgDefaultName()
    local lp = Players.LocalPlayer
    return lp and tostring(lp.UserId) or "player"
end

local function _cfgPath(name)
    -- ยอมรับทั้ง "MyFile" และ "MyFile.json"
    if name:sub(-5):lower() == ".json" then
        return CFG_FOLDER.."/"..name
    end
    return CFG_FOLDER.."/"..name..".json"
end

-- Returns list of config filenames (WITH .json extension, excluding Auto_Config.json)
function ZENUHub:ListConfigs()
    _cfgEnsureFolder()
    local names = {}
    local ok, files = pcall(function() return listfiles(CFG_FOLDER) end)
    if not ok then return names end
    for _, f in ipairs(files) do
        -- จับชื่อไฟล์รวมนามสกุล เช่น "MyConfig.json"
        local n = tostring(f):match("([^/\\]+%.json)$")
        if n and n ~= AUTO_CFG_NAME..".json" then
            table.insert(names, n)
        end
    end
    table.sort(names)
    return names
end

-- Save/Load the auto-save & auto-load toggle states to Auto_Config (separate file)
function ZENUHub:SaveAutoConfig(data)
    _cfgEnsureFolder()
    local path = _cfgPath(AUTO_CFG_NAME)
    pcall(function()
        writefile(path, HttpService:JSONEncode(data or {}))
    end)
end

function ZENUHub:LoadAutoConfig()
    local path = _cfgPath(AUTO_CFG_NAME)
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(path))
    end)
    return ok and data or {}
end

-- ── SERIALISE ONE VALUE ───────────────────────────────────────
-- [v3.1] item must never be nil here — SaveConfig now guards the loop.
local function _serialise(val, item)
    local t = typeof(val)
    if t == "userdata" and tostring(val):match("Enum") then
        t = "EnumItem"
    end

    if     t=="boolean"  then return {_t="b",   v=val}
    elseif t=="number"   then return {_t="n",   v=val}
    elseif t=="string"   then return {_t="s",   v=val}
    elseif t=="Color3"   then return {_t="c",
        r=math.round(val.R*255), g=math.round(val.G*255), b=math.round(val.B*255)}
    elseif t=="EnumItem" then
        if item and item._type=="Keybind" then
            -- ดึงชื่อปุ่มด้วยวิธีที่ปลอดภัยกว่า ดักจับกรณีที่ val.Name ใช้ไม่ได้
            local keyName = tostring(val.Name)
            if keyName == "nil" or keyName == "" then
                keyName = tostring(val):match("%.([^%.]+)$") or "Unknown"
            end
            return {_t="kb", k=keyName, m=item.Mode or "Toggle"}
        end
        return {_t="k", n=val.Name}
    elseif t=="table" then
        if item and item._type=="MultiDropdown" then
            local copy = {}
            for i, v in pairs(val) do table.insert(copy, v) end -- ใช้ pairs ปลอดภัยกว่า
            return {_t="mdd", v=copy}
        end
        return {_t="tbl", v=val}
    end
    return nil
end

function ZENUHub:SaveConfig(filename)
    _cfgEnsureFolder()
    filename = (filename and filename ~= "") and filename or _cfgDefaultName()
    local fullPath = _cfgPath(filename)

    -- Snapshot current value from every flagged item first, then merge Flags
    local data = {}
    for flag, item in pairs(self._flaggedItems) do
        local val = item.Value
        if val ~= nil then self.Flags[flag] = val end
    end
    for flag, val in pairs(self.Flags) do
        -- [v3.1 FIX] Only serialise flags that have a registered item.
        -- Without this guard, Save=false components that still fire Flags
        -- callbacks would be written with wrong type (e.g. Keybind saved as
        -- generic "k" instead of "kb", losing the Mode field).
        local item = self._flaggedItems[flag]
        if item then
            local entry = _serialise(val, item)
            if entry then data[flag] = entry end
        end
    end

    local ok, err = pcall(function()
        writefile(fullPath, HttpService:JSONEncode(data))
    end)
    if ok then
        self:Notify({Title="Config Saved", Message="-> "..fullPath, Type="Success", Duration=3})
    else
        self:Notify({Title="Save Failed",  Message=tostring(err):sub(1,80), Type="Error", Duration=4})
    end
    return ok
end

function ZENUHub:LoadConfig(filename)
    filename = (filename and filename ~= "") and filename or _cfgDefaultName()
    local fullPath = _cfgPath(filename)

    -- If filename is default (player ID) and file doesn't exist, bail silently
    if not isfile(fullPath) then
        self:Notify({Title="Load Failed", Message="File not found: "..fullPath, Type="Error", Duration=3})
        return false
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(fullPath))
    end)
    if not ok then
        self:Notify({Title="Load Failed", Message="Invalid config file", Type="Error", Duration=3})
        return false
    end

    local loaded = 0
    for flag, entry in pairs(data) do
        local item = self._flaggedItems[flag]
        if item and entry._t then
            local t = entry._t
            pcall(function()
                if     t=="b"   then item:Set(entry.v == true)
                elseif t=="n"   then item:Set(tonumber(entry.v) or 0)
                elseif t=="s"   then item:Set(tostring(entry.v))
                elseif t=="c"   then item:Set(Color3.fromRGB(entry.r,entry.g,entry.b))
                elseif t=="k"   then
                    local kc = Enum.KeyCode[entry.n]
                    if kc then item:Set(kc) end
                elseif t=="kb"  then
                    -- ป้องกันการที่ entry.k ติดคำว่า Enum.KeyCode.E มา
                    local kName = tostring(entry.k):match("%.([^%.]+)$") or entry.k
                    local success, kc = pcall(function() return Enum.KeyCode[kName] end)
                    
                    if success and kc then item:Set(kc) end
                    if entry.m and item.SetMode then item:SetMode(entry.m) end
                elseif t=="tbl"  and type(entry.v)=="table" then item:Set(entry.v)
                elseif t=="mdd"  and type(entry.v)=="table" then item:Set(entry.v)
                end
                self.Flags[flag] = item.Value
                -- [v3.2] Fire callback after load if component has Start=true
                if item._fireOnStart and type(item.FireCallback) == "function" then
                    item:FireCallback()
                end
            end)
            loaded = loaded + 1
        end
    end
    self:Notify({Title="Config Loaded", Message=loaded.." setting(s) restored", Type="Info", Duration=3})
    return true
end

-- ── DELETE CONFIG ─────────────────────────────────────────────────────────────
--[[
    ZENUHub:DeleteConfig(filename)
      Deletes the config file and returns true on success.
      filename accepts name with or without ".json" extension.
--]]
function ZENUHub:DeleteConfig(filename)
    filename = (filename and filename ~= "") and filename or _cfgDefaultName()
    local fullPath = _cfgPath(filename)
    if not isfile(fullPath) then
        self:Notify({Title="Delete Failed", Message="File not found: "..fullPath, Type="Error", Duration=3})
        return false
    end
    local ok, err = pcall(function() delfile(fullPath) end)
    if ok then
        self:Notify({Title="Config Deleted", Message=fullPath, Type="Warn", Duration=3})
    else
        self:Notify({Title="Delete Failed", Message=tostring(err):sub(1,80), Type="Error", Duration=4})
    end
    return ok
end


-- ============================================================
--  UNLOAD / DESTROY
-- ============================================================
--[[
    ZENUHub:Unload()
      Disconnects every tracked RBXScriptConnection, destroys every ScreenGui
      (main window, float icon, notification, tooltip, watermark), and resets state.
--]]
function ZENUHub:Unload()
    for _, conn in ipairs(self._connections) do
        pcall(function() conn:Disconnect() end)
    end
    self._connections = {}

    for _, gui in ipairs(self._guiList) do
        pcall(function() if gui and gui.Parent then gui:Destroy() end end)
    end
    self._guiList = {}

    if _ttConn then pcall(function() _ttConn:Disconnect() end); _ttConn=nil end
    if _ttGui and _ttGui.Parent then
        pcall(function() _ttGui:Destroy() end)
        _ttGui=nil; _ttFrame=nil; _ttLbl=nil
    end
    if NotifHolder and NotifHolder.Parent and NotifHolder.Parent.Parent then
        pcall(function() NotifHolder.Parent:Destroy() end)
        NotifHolder=nil
    end

    self._flaggedItems = {}
    self.Flags         = {}
    _notifActive       = 0
    _notifQueue        = {}

    self:Notify({Title="ZENU Hub", Message="Unloaded successfully", Type="Info", Duration=3})
    task.delay(3.5, function()
        if NotifHolder and NotifHolder.Parent and NotifHolder.Parent.Parent then
            pcall(function() NotifHolder.Parent:Destroy() end); NotifHolder=nil
        end
    end)
end


-- ============================================================
--  RESET ALL TO DEFAULT
-- ============================================================
function ZENUHub:ResetAllToDefault()
    local count = 0
    for _, item in pairs(self._flaggedItems) do
        if item and type(item.ResetToDefault) == "function" then
            pcall(function() item:ResetToDefault() end)
            count = count + 1
        end
    end
    self:Notify({Title="Settings Reset",
        Message=count.." setting(s) restored to default", Type="Info", Duration=3})
    return count
end


-- ============================================================
--  THEME MANAGER
-- ============================================================
--[[
    ZENUHub:ApplyTheme(nameOrTable)
      name    string  — built-in preset: "Default"|"Blue"|"Green"|"Purple"|"Gold"
      table   table   — custom key/value overrides matching T field names

    ZENUHub:RegisterTheme(name, colorTable)  — add a new named preset
    ZENUHub:GetTheme()                        — returns a shallow copy of current T
    ZENUHub:AddThemeSection(section)          — plug-and-play settings controls
      Adds a Dropdown (preset), accent ColorPicker, and background ColorPicker.
--]]
function ZENUHub:ApplyTheme(nameOrTable)
    local colors
    if type(nameOrTable)=="string" then
        colors = self._themes[nameOrTable]
        if not colors then
            self:Notify({Title="Theme Error",
                Message="Unknown preset '"..nameOrTable.."'", Type="Warn", Duration=3})
            return false
        end
    elseif type(nameOrTable)=="table" then
        colors = nameOrTable
    else return false end

    for k,v in pairs(colors) do if T[k]~=nil then T[k]=v end end
    self:Notify({Title="Theme Applied",
        Message="New UI elements will use updated colours", Type="Success", Duration=3})
    return true
end

function ZENUHub:RegisterTheme(name, colors)
    assert(type(name)=="string" and type(colors)=="table")
    self._themes[name] = colors
end

function ZENUHub:GetTheme()
    local copy={} for k,v in pairs(T) do copy[k]=v end return copy
end

function ZENUHub:AddThemeSection(section)
    -- Build sorted list of theme names
    local names={}
    for k in pairs(self._themes) do table.insert(names,k) end
    table.sort(names)
    section:AddDropdown({
        Name="Theme Preset", Items=names, Default="Default",
        Tooltip="Switch the accent colour theme for newly created elements",
        Callback=function(v) if v and v~="" then self:ApplyTheme(v) end end
    })
    section:AddColorPicker({
        Name="Accent Colour", Default=T.RED,
        Tooltip="Override the primary accent colour",
        Callback=function(c)
            T.RED=c; T.TOG_ON=c; T.SLD_FILL=c; T.BG_SUBPILL_A=c
            T.RED_D=c:Lerp(Color3.new(0,0,0),0.32)
            T.RED_B=c:Lerp(Color3.new(1,1,1),0.22)
            T.RED_DIM=c:Lerp(Color3.new(0,0,0),0.72)
            T.BORDER_R=c:Lerp(Color3.new(0,0,0),0.6)
        end
    })
    section:AddColorPicker({
        Name="Window Background", Default=T.BG_WIN,
        Tooltip="Override the window background colour",
        Callback=function(c)
            T.BG_WIN=c
            T.BG_SIDE=c:Lerp(Color3.new(1,1,1),0.025)
            T.BG_HEAD=c:Lerp(Color3.new(0,0,0),0.14)
            T.BG_CARD=c:Lerp(Color3.new(1,1,1),0.05)
            T.BG_CARD_H=c:Lerp(Color3.new(1,1,1),0.09)
        end
    })
end


-- ============================================================
--  SECTION COMPONENTS  (shared builder)
-- ============================================================
local function BuildSectionComponents(Section, IF)

    -- ── SHARED: attach common methods ───────────
    local function _attachCommon(item, rootFrame, opts)
        opts = opts or {}
        item._enabled = true

        function item:Destroy()
            if rootFrame and rootFrame.Parent then
                Tween(rootFrame,{BackgroundTransparency=1},0.15)
                task.delay(0.18, function()
                    if rootFrame then rootFrame:Destroy() end
                end)
            end
            for i,v in ipairs(Section._items) do
                if v==self then table.remove(Section._items,i); break end
            end
        end

        function item:Show()
            if rootFrame then rootFrame.Visible=true end
        end
        function item:Hide()
            if rootFrame then rootFrame.Visible=false end
        end
        function item:Get()
            return item.Value
        end

        local overlay
        function item:SetEnabled(en)
            self._enabled = en
            if not en then
                if not overlay then
                    overlay = New("Frame",{Parent=rootFrame,
                        BackgroundColor3=Color3.fromRGB(0,0,0),
                        BackgroundTransparency=0.55,
                        Size=UDim2.new(1,0,1,0),
                        BorderSizePixel=0,
                        ZIndex=rootFrame.ZIndex+50})
                    Corner(overlay,6)
                end
                overlay.Visible=true
            else
                if overlay then overlay.Visible=false end
            end
        end

        -- Tooltip support
        if opts.Tooltip and opts.Tooltip ~= "" then
            SetupTooltip(rootFrame, opts.Tooltip)
        end

        -- Register flagged items for SaveConfig / LoadConfig
        -- opts.Save = false  → บังคับไม่เซฟ แม้จะมี Flag
        -- opts.Save = true   → เซฟ (ค่าเริ่มต้นเมื่อมี Flag)
        if opts.Flag and opts.Save ~= false then
            ZENUHub._flaggedItems[opts.Flag] = item
            -- [v3.1] Populate Flags with the default value immediately.
            if item.Value ~= nil then
                ZENUHub.Flags[opts.Flag] = item.Value
            end
        end
    end

    -- ── TOGGLE ───────────────────────────────────────────────
    function Section:AddToggle(o)
        o=o or {}
        local lbl=o.Name or "Toggle"; local def=o.Default or false
        local cb=o.Callback or function() end; local flag=o.Flag

        local Row=New("Frame",{Parent=IF,BackgroundColor3=T.BG_CARD,
            Size=UDim2.new(1,0,0,34),BorderSizePixel=0})
        Corner(Row,6)

        local NameLbl=New("TextLabel",{Parent=Row,Text=lbl,Font=Enum.Font.Gotham,TextSize=12,
            TextColor3=T.TXT_PRI,BackgroundTransparency=1,
            Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,10,0,0),
            TextXAlignment=Enum.TextXAlignment.Left})

        local Track=New("TextButton",{Parent=Row,Text="",
            BackgroundColor3=def and T.TOG_ON or T.TOG_OFF,
            Size=UDim2.new(0,42,0,22),Position=UDim2.new(1,-50,0.5,-11),
            BorderSizePixel=0,ZIndex=3})
        Corner(Track,11)
        local Knob=New("Frame",{Parent=Track,BackgroundColor3=T.TOG_KNOB,
            Size=UDim2.new(0,16,0,16),
            Position=def and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BorderSizePixel=0,ZIndex=4})
        Corner(Knob,8)

        local state=def
        local item={_frame=Row,_label=lbl,Value=state,_type="Toggle"}

        local function SetS(v,fire)
            state=v; item.Value=v
            Tween(Track,{BackgroundColor3=v and T.TOG_ON or T.TOG_OFF},0.2)
            Spring(Knob,{Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)},0.24)
            if fire~=false then cb(v) end
            if flag then ZENUHub.Flags[flag]=v end
        end

        Track.MouseButton1Click:Connect(function()
            if item._enabled~=false then SetS(not state) end
        end)
        Hover(Row,T.BG_CARD,T.BG_CARD_H)

        item._default = def
        function item:Set(v)           SetS(v,false) end
        function item:Toggle()         SetS(not state) end
        function item:ResetToDefault() SetS(self._default, false) end
        function item:SetCallback(f)   cb=f end
        function item:SetName(s)       lbl=s; NameLbl.Text=s; item._label=s end
        function item:FireCallback()   cb(item.Value) end

        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(state) end) end
        table.insert(Section._items,item); return item ─────────────────────────────────────────────
    function Section:AddCheckbox(o)
        o=o or {}
        local lbl=o.Name or "Checkbox"; local def=o.Default or false
        local cb=o.Callback or function() end; local flag=o.Flag

        local Row=New("Frame",{Parent=IF,BackgroundColor3=T.BG_CARD,
            Size=UDim2.new(1,0,0,34),BorderSizePixel=0})
        Corner(Row,6)

        local NameLbl=New("TextLabel",{Parent=Row,Text=lbl,Font=Enum.Font.Gotham,TextSize=12,
            TextColor3=T.TXT_PRI,BackgroundTransparency=1,
            Size=UDim2.new(1,-60,1,0),Position=UDim2.new(0,10,0,0),
            TextXAlignment=Enum.TextXAlignment.Left})

        local BoxBtn=New("TextButton",{Parent=Row,Text="",
            BackgroundColor3=def and T.TOG_ON or T.TOG_OFF,
            Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,-32,0.5,-11),
            BorderSizePixel=0,ZIndex=3})
        Corner(BoxBtn,5)
        Stroke(BoxBtn, 1, T.BORDER)
        
        local CheckIcon=New("TextLabel",{Parent=BoxBtn,Text="✓",
            Font=Enum.Font.GothamBold,TextSize=14,TextColor3=Color3.new(1,1,1),
            BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
            TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,
            TextTransparency=def and 0 or 1, ZIndex=4})

        local state=def
        local item={_frame=Row,_label=lbl,Value=state,_type="Checkbox"}

        local function SetS(v,fire)
            state=v; item.Value=v
            Tween(BoxBtn,{BackgroundColor3=v and T.TOG_ON or T.TOG_OFF},0.15)
            Tween(CheckIcon,{TextTransparency=v and 0 or 1},0.15)
            if fire~=false then cb(v) end
            if flag then ZENUHub.Flags[flag]=v end
        end

        BoxBtn.MouseButton1Click:Connect(function()
            if item._enabled~=false then SetS(not state) end
        end)
        Hover(Row,T.BG_CARD,T.BG_CARD_H)

        item._default = def
        function item:Set(v)           SetS(v,false) end
        function item:Toggle()         SetS(not state) end
        function item:ResetToDefault() SetS(self._default, false) end
        function item:SetCallback(f)   cb=f end
        function item:SetName(s)       lbl=s; NameLbl.Text=s; item._label=s end
        function item:FireCallback()   cb(item.Value) end

        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(state) end) end
        table.insert(Section._items,item); return item
    end

    -- ── BUTTON ───────────────────────────────────────────────
    function Section:AddButton(o)
        o = o or {}
        local lbl = o.Name or "Button"
        local cb = o.Callback or function() end
    
        local Btn = New("TextButton", {
            Parent = IF,
            Text = lbl,
            Font = Enum.Font.GothamBold,
            TextSize = 12,
            TextColor3 = T.TXT_PRI,
            BackgroundColor3 = T.RED_D,
            Size = UDim2.new(1, 0, 0, 34),
            BorderSizePixel = 0
        })
        Corner(Btn, 6)
        Ripple(Btn)
    
        local item = { _frame = Btn, _label = lbl, _type = "Button", _enabled = true }
    
        local function DoClick()
            Tween(Btn, { BackgroundColor3 = T.RED_B }, 0.06)
            task.delay(0.06, function()
                if Btn and Btn.Parent then
                    Tween(Btn, { BackgroundColor3 = T.RED }, 0.12)
                end
            end)
            cb()
        end
    
        Btn.MouseEnter:Connect(function()
            Tween(Btn, { BackgroundColor3 = T.RED }, 0.14)
        end)
        Btn.MouseLeave:Connect(function()
            Tween(Btn, { BackgroundColor3 = T.RED_D }, 0.14)
        end)
        Btn.MouseButton1Click:Connect(function()
            if item._enabled == false then return end
            DoClick()
        end)
    
        function item:Fire()
            if self._enabled == false then return end
            DoClick()
        end
        function item:SetCallback(f) cb = f end
        function item:SetName(s)
            lbl = s
            Btn.Text = s
            item._label = s
        end
        function item:FireCallback() cb() end

        item._fireOnStart = o.Start == true
        _attachCommon(item, Btn, o)
        if o.Start then task.defer(function() cb() end) end
        table.insert(Section._items, item)
        return item
    end

    -- ── SLIDER  (Touch-safe) ─────────────────────────────────
    function Section:AddSlider(o)
        o = o or {}
        local lbl  = o.Name or "Slider"
        local mn   = o.Min or 0; local mx = o.Max or 100
        local step = math.abs(o.Step or 1)   -- Step: ขนาดการกระโดดของ slider (default=1)
        if step == 0 then step = 1 end
        local def  = math.clamp(o.Default or mn, mn, mx)
        local suf  = o.Suffix or ""; local cb = o.Callback or function() end
        local flag = o.Flag

        -- คำนวณจำนวนทศนิยมจาก step เพื่อ format ค่าให้ถูกต้อง
        local function _decimals(s)
            local str = tostring(s)
            local dot = str:find("%.")
            return dot and (#str - dot) or 0
        end
        local stepDecimals = _decimals(step)
    
        local Row = New("Frame", {Parent = IF, BackgroundColor3 = T.BG_CARD, 
            Size = UDim2.new(1, 0, 0, 56), BorderSizePixel = 0})
        Corner(Row, 6)
    
        local NameLbl = New("TextLabel", {Parent = Row, Text = lbl, Font = Enum.Font.Gotham, TextSize = 12,
            TextColor3 = T.TXT_PRI, BackgroundTransparency = 1,
            Size = UDim2.new(0.62, 0, 0, 22), Position = UDim2.new(0, 10, 0, 4),
            TextXAlignment = Enum.TextXAlignment.Left})
    
        local ValChip = New("Frame", {Parent = Row, BackgroundColor3 = T.RED_DIM,
            Size = UDim2.new(0, 56, 0, 20), Position = UDim2.new(1, -64, 0, 6), BorderSizePixel = 0})
        Corner(ValChip, 5)
        Stroke(ValChip, 1, T.RED, 0.6)
    
        local ValInput = New("TextBox", {Parent = ValChip, Text = tostring(def) .. suf,
            Font = Enum.Font.GothamBold, TextSize = 11, TextColor3 = T.RED,
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Center, ClearTextOnFocus = false})
    
        local Track = New("Frame", {Parent = Row, BackgroundColor3 = T.SLD_TRACK,
            Size = UDim2.new(1, -20, 0, 4), Position = UDim2.new(0, 10, 1, -16), BorderSizePixel = 0})
        Corner(Track, 2)
    
        local Fill = New("Frame", {Parent = Track, BackgroundColor3 = T.SLD_FILL,
            Size = UDim2.new(0, 0, 1, 0), BorderSizePixel = 0})
        Corner(Fill, 2)
    
        local Thumb = New("Frame", {Parent = Track, BackgroundColor3 = T.TXT_PRI,
            Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0, -7, 0.5, -7),
            BorderSizePixel = 0, ZIndex = 3})
        Corner(Thumb, 14)
        Stroke(Thumb, 2, T.SLD_FILL)
    
        local TA = New("TextButton", {Parent = Row, Text = "",
            BackgroundTransparency = 1, Size = UDim2.new(1, -10, 0, 32),
            Position = UDim2.new(0, 5, 1, -36), BorderSizePixel = 0, ZIndex = 5})
    
        local val = def; local dragS = false
        local item = {_frame = Row, _label = lbl, Value = val, _type = "Slider"}
    
        local function ApplyVal(v, fire)
            if v == nil then return end
            -- snap to step
            local snapped = math.round(v / step) * step
            -- clamp และป้องกัน floating point drift
            local factor = 10 ^ stepDecimals
            snapped = math.clamp(math.round(snapped * factor) / factor, mn, mx)
            val = snapped
            item.Value = val

            local fp = math.clamp((val - mn) / (mx - mn), 0, 1)
            Tween(Fill, {Size = UDim2.new(fp, 0, 1, 0)}, 0.1)
            Tween(Thumb, {Position = UDim2.new(fp, -7, 0.5, -7)}, 0.1)

            -- format ทศนิยมให้ตรงกับ step
            local fmt = stepDecimals > 0 and ("%." .. stepDecimals .. "f") or "%d"
            ValInput.Text = string.format(fmt, val) .. suf
            if fire ~= false then cb(val) end
            if flag then ZENUHub.Flags[flag] = val end
        end
    
        ValInput.FocusLost:Connect(function()
            local raw = ValInput.Text:gsub(suf, ""):match("^%-?%d+%.?%d*") or ""
            local n = tonumber(raw)
            if n then
                ApplyVal(n, true)
            else
                ApplyVal(val, false)
            end
        end)
    
        local function UpdS(ix)
            if not ix then return end 
            local abs = Track.AbsolutePosition
            local sz = Track.AbsoluteSize
            if sz.X <= 0 then return end 
            
            local pct = math.clamp((ix - abs.X) / sz.X, 0, 1)
            ApplyVal(mn + pct * (mx - mn), true)
        end
    
        TA.InputBegan:Connect(function(inp)
            if item._enabled == false then return end
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragS = true
                UpdS(inp.Position.X)
            end
        end)
    
        local inputConnection
        inputConnection = UserInputService.InputChanged:Connect(function(inp)
            if dragS and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
                if inp.Position then
                    UpdS(inp.Position.X)
                end
            end
        end)
    
        -- FIX 1: Store InputEnded connection so it can be disconnected on destroy
        local inputEndedConnection
        inputEndedConnection = UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
                dragS = false
            end
        end)
    
        ApplyVal(def, false)
        Hover(Row, T.BG_CARD, T.BG_CARD_H)
    
        item._default = def
        function item:Set(v)           ApplyVal(v, false) end
        function item:ResetToDefault() ApplyVal(self._default, false) end
        function item:SetCallback(f)   cb = f end
        function item:SetName(s)       lbl = s; NameLbl.Text = s; item._label = s end
        function item:SetSuffix(s)     suf = s; ApplyVal(val, false) end
        function item:FireCallback()   cb(item.Value) end
        function item:SetStep(s)
            step = math.abs(s or 1)
            if step == 0 then step = 1 end
            stepDecimals = _decimals(step)
            ApplyVal(val, false)
        end
        function item:SetRange(newMin, newMax)
            mn = newMin; mx = newMax
            ApplyVal(val, false)
        end
    
        Row.Destroying:Connect(function()
            if inputConnection then inputConnection:Disconnect() end
            if inputEndedConnection then inputEndedConnection:Disconnect() end
        end)
    
        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(val) end) end
        table.insert(Section._items, item)
        return item
    end

    -- ── TEXTBOX ──────────────────────────────────────────────
    function Section:AddTextbox(o)
        o=o or {}
        local lbl=o.Name or "Textbox"; local ph=o.Placeholder or "Enter text..."
        local def=o.Default or ""; local cb=o.Callback or function() end
        local flag=o.Flag

        local Row=New("Frame",{Parent=IF,BackgroundColor3=T.BG_CARD,
            Size=UDim2.new(1,0,0,54),BorderSizePixel=0})
        Corner(Row,6)

        local NameLbl=New("TextLabel",{Parent=Row,Text=lbl,Font=Enum.Font.Gotham,TextSize=11,
            TextColor3=T.TXT_SEC,BackgroundTransparency=1,
            Size=UDim2.new(1,-20,0,18),Position=UDim2.new(0,10,0,5),
            TextXAlignment=Enum.TextXAlignment.Left})

        local IFr=New("Frame",{Parent=Row,BackgroundColor3=T.BG_INPUT,
            Size=UDim2.new(1,-20,0,26),Position=UDim2.new(0,10,0,24),BorderSizePixel=0})
        Corner(IFr,5); local sk=Stroke(IFr,1,T.BORDER)

        local Inp=New("TextBox",{Parent=IFr,Text=def,PlaceholderText=ph,
            Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TXT_PRI,
            PlaceholderColor3=T.TXT_MUTED,BackgroundTransparency=1,
            Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),
            ClearTextOnFocus=false,ZIndex=3})

        Inp.Focused:Connect(function() Tween(sk,{Color=T.RED},0.14) end)
        Inp.FocusLost:Connect(function() Tween(sk,{Color=T.BORDER},0.14); cb(Inp.Text) end)

        local item={_frame=Row,_label=lbl,Value=Inp.Text,_type="Textbox"}

        Inp:GetPropertyChangedSignal("Text"):Connect(function()
            item.Value=Inp.Text
            if flag then ZENUHub.Flags[flag]=Inp.Text end
        end)

        item._default = def
        function item:Set(v)             Inp.Text=v; item.Value=v end
        function item:Clear()            Inp.Text=""; item.Value="" end
        function item:ResetToDefault()   self:Set(self._default) end
        function item:SetName(s)         lbl=s; NameLbl.Text=s; item._label=s end
        function item:SetPlaceholder(s)  Inp.PlaceholderText=s end
        function item:SetCallback(f)     cb=f end
        function item:FireCallback()     cb(item.Value) end

        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(Inp.Text) end) end
        table.insert(Section._items,item); return item
    end

    -- ── DROPDOWN ─────────────────────────────────────────────
    function Section:AddDropdown(o)
        o = o or {}
        local lbl      = o.Name or "Dropdown"
        local items    = o.Items or {}
        local sel      = o.Default or (items[1] or "")
        local cb       = o.Callback or function() end
        local flag     = o.Flag
        local required = o.Required == true   -- Required=true: ห้าม deselect ให้ว่าง
    
        local Row = New("Frame", {
            Parent = IF,
            BackgroundColor3 = T.BG_CARD,
            Size = UDim2.new(1, 0, 0, 56),
            BorderSizePixel = 0,
            ZIndex = 5,
            ClipsDescendants = true
        })
        Corner(Row, 6)
    
        local NameLbl = New("TextLabel", {
            Parent = Row,
            Text = lbl,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = T.TXT_SEC,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.new(0, 10, 0, 5),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })
    
        local DB = New("TextButton", {
            Parent = Row,
            Text = "",
            BackgroundColor3 = T.BG_INPUT,
            Size = UDim2.new(1, -20, 0, 26),
            Position = UDim2.new(0, 10, 0, 24),
            BorderSizePixel = 0,
            ZIndex = 6,
            ClipsDescendants = false
        })
        Corner(DB, 5)
        Stroke(DB, 1, T.BORDER)
    
        local SL = New("TextLabel", {
            Parent = DB,
            Text = sel,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = sel == "" and T.TXT_MUTED or T.TXT_PRI,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -28, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 7
        })
    
        local Arrow = New("TextLabel", {
            Parent = DB,
            Text = "v",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = T.TXT_MUTED,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 22, 1, 0),
            Position = UDim2.new(1, -24, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 7
        })
    
        local DL = New("Frame", {
            Parent = DB,
            BackgroundColor3 = T.BG_DROP,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 4),
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true
        })
        Corner(DL, 6)
        Stroke(DL, 1, T.BORDER)
    
        local SR = New("Frame", {
            Parent = DL,
            BackgroundColor3 = T.BG_INPUT,
            Size = UDim2.new(1, -12, 0, 22),
            Position = UDim2.new(0, 6, 0, 6),
            BorderSizePixel = 0,
            ZIndex = 51
        })
        Corner(SR, 4)
        Stroke(SR, 1, T.BORDER)
    
        local SI = New("TextBox", {
            Parent = SR,
            Text = "",
            PlaceholderText = "Search...",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = T.TXT_PRI,
            PlaceholderColor3 = T.TXT_MUTED,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            ClearTextOnFocus = false,
            ZIndex = 52
        })
    
        local IL = New("ScrollingFrame", {
            Parent = DL,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, -36),
            Position = UDim2.new(0, 0, 0, 34),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.RED,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 51
        })
        New("UIListLayout", {
            Parent = IL,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Pad(IL, 2, 2, 4, 4)
    
        local item = { _frame = Row, _label = lbl, Value = sel, _type = "Dropdown", _enabled = true }
        local allB = {}
        local open = false
        local _ddOutsideConn = nil

        local function CloseDD()
            open = false
            DL.Visible = false
            Tween(Row, { Size = UDim2.new(1, 0, 0, 56) }, 0.2)
            Tween(Arrow, { Rotation = 0 }, 0.2)
            if _ddOutsideConn then _ddOutsideConn:Disconnect(); _ddOutsideConn = nil end
        end
    
        local function BuildDD(f)
            for _, v in ipairs(allB) do
                if v then v:Destroy() end
            end
            allB = {}
    
            for _, it in ipairs(items) do
                if f == "" or it:lower():find(f:lower(), 1, true) then
                    local isSelected = (sel == it)
    
                    local ib = New("TextButton", {
                        Parent = IL,
                        Text = it,
                        Font = Enum.Font.Gotham,
                        TextSize = 11,
                        TextColor3 = isSelected and T.RED or T.TXT_PRI,
                        BackgroundColor3 = isSelected and T.RED_DIM or T.BG_DROP,
                        Size = UDim2.new(1, 0, 0, 26),
                        BorderSizePixel = 0,
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 52
                    })
                    Corner(ib, 4)
                    Pad(ib, 0, 0, 8, 4)
    
                    ib.MouseEnter:Connect(function()
                        Tween(ib, { BackgroundColor3 = isSelected and T.RED_DIM or T.BG_CARD_H }, 0.1)
                    end)
                    ib.MouseLeave:Connect(function()
                        Tween(ib, { BackgroundColor3 = isSelected and T.RED_DIM or T.BG_DROP }, 0.1)
                    end)
    
                    ib.MouseButton1Click:Connect(function()
                        if item._enabled == false then return end
    
                        if sel == it then
                            -- Required=true: ห้าม deselect
                            if required then CloseDD(); return end
                            sel = ""
                            SL.Text = ""
                            SL.TextColor3 = T.TXT_MUTED
                            cb(nil)
                            if flag then ZENUHub.Flags[flag] = nil end
                        else
                            sel = it
                            SL.Text = it
                            SL.TextColor3 = T.TXT_PRI
                            cb(it)
                            if flag then ZENUHub.Flags[flag] = it end
                        end
    
                        item.Value = sel
                        CloseDD()
                        BuildDD(SI.Text)
                    end)
    
                    table.insert(allB, ib)
                end
            end
        end
    
        BuildDD("")
        SI:GetPropertyChangedSignal("Text"):Connect(function()
            BuildDD(SI.Text)
        end)
    
        DB.MouseButton1Click:Connect(function()
            if item._enabled == false then return end
    
            open = not open
            DL.Visible = open
            if open then
                local ds = math.min(#items * 28 + 44, 128)
                DL.Size = UDim2.new(1, 0, 0, ds)
                SI.Text = ""
                BuildDD("")
                Tween(Row, { Size = UDim2.new(1, 0, 0, 56 + ds + 8) }, 0.2)
                Tween(Arrow, { Rotation = 180 }, 0.2)
                -- Close when clicking outside the Row
                task.defer(function()
                    if not open then return end
                    _ddOutsideConn = UserInputService.InputBegan:Connect(function(inp, gpe)
                        if gpe then return end
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        local abs = Row.AbsolutePosition
                        local sz  = Row.AbsoluteSize
                        local pos = inp.Position
                        if pos.X < abs.X or pos.X > abs.X + sz.X
                        or pos.Y < abs.Y or pos.Y > abs.Y + sz.Y then
                            CloseDD()
                        end
                    end)
                end)
            else
                CloseDD()
            end
        end)
    
        item._default = o.Default or (items[1] or "")
        function item:Set(v)
            sel = v
            SL.Text = v
            SL.TextColor3 = v ~= "" and T.TXT_PRI or T.TXT_MUTED
            item.Value = v
            BuildDD(SI.Text)
            if flag then ZENUHub.Flags[flag] = v ~= "" and v or nil end
        end
        function item:Clear()
            if required then return end   -- Required=true: ห้าม clear
            sel = ""
            SL.Text = ""
            SL.TextColor3 = T.TXT_MUTED
            item.Value = ""
            BuildDD(SI.Text)
            cb(nil)
            if flag then ZENUHub.Flags[flag] = nil end
        end
        function item:ResetToDefault() self:Set(self._default) end
        function item:SetName(s)
            lbl = s
            NameLbl.Text = s
            item._label = s
        end
        function item:SetCallback(f) cb = f end
        function item:FireCallback()   cb(item.Value) end
        function item:SetItems(t)
            items = t
            sel = ""
            SL.Text = ""
            item.Value = ""
            BuildDD(SI.Text)
        end
        function item:AddItem(s)
            table.insert(items, s)
            BuildDD(SI.Text)
        end
        function item:RemoveItem(s)
            for i, v in ipairs(items) do
                if v == s then
                    table.remove(items, i)
                    break
                end
            end
            if sel == s then self:Clear() else BuildDD(SI.Text) end
        end
        function item:Refresh(t)
            self:SetItems(t)
        end
    
        Row.Destroying:Connect(function()
            if _ddOutsideConn then _ddOutsideConn:Disconnect(); _ddOutsideConn = nil end
        end)

        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(sel) end) end
        table.insert(Section._items, item)
        return item
    end

    -- ── MULTI-DROPDOWN ───────────────────────────────────────
    function Section:AddMultiDropdown(o)
        o = o or {}
        local lbl      = o.Name or "Multi Select"
        local items    = o.Items or {}
        local defaults = o.Default or {}
        local maxSel   = o.MaxSelect or math.huge
        local minSel   = o.MinSelect or 0   -- MinSelect: จำนวนขั้นต่ำที่ต้องเลือก
        local cb       = o.Callback or function() end
        local flag     = o.Flag

        local selectedMap = {}
        local selectedOrder = {}

        -- [v3.1 FIX] Apply Default={...} immediately so the component starts
        -- with the correct selections and SaveConfig captures them correctly.
        for _, v in ipairs(defaults) do
            if not selectedMap[v] and #selectedOrder < maxSel then
                selectedMap[v] = true
                table.insert(selectedOrder, v)
            end
        end

        local Row = New("Frame", {
            Parent = IF,
            BackgroundColor3 = T.BG_CARD,
            Size = UDim2.new(1, 0, 0, 56),
            BorderSizePixel = 0,
            ZIndex = 5,
            ClipsDescendants = true
        })
        Corner(Row, 6)

        local LR = New("Frame", {
            Parent = Row,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -20, 0, 18),
            Position = UDim2.new(0, 10, 0, 5),
            ZIndex = 6
        })
        local NameLbl = New("TextLabel", {
            Parent = LR,
            Text = lbl,
            Font = Enum.Font.Gotham,
            TextSize = 11,
            TextColor3 = T.TXT_SEC,
            BackgroundTransparency = 1,
            Size = UDim2.new(0.7, 0, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 6
        })

        local MB
        local function RefreshMB()
            if MB then
                local n = #selectedOrder
                MB.Text = n .. "/" .. tostring(maxSel)
                MB.TextColor3 = (n >= maxSel) and T.RED_B or T.RED
            end
        end
        if maxSel ~= math.huge then
            MB = New("TextLabel", {
                Parent = LR,
                Text = "0/" .. tostring(maxSel),
                Font = Enum.Font.GothamBold,
                TextSize = 10,
                TextColor3 = T.RED,
                BackgroundTransparency = 1,
                Size = UDim2.new(0.3, 0, 1, 0),
                Position = UDim2.new(0.7, 0, 0, 0),
                TextXAlignment = Enum.TextXAlignment.Right,
                ZIndex = 6
            })
        end

        local DB2 = New("TextButton", {
            Parent = Row,
            Text = "",
            BackgroundColor3 = T.BG_INPUT,
            Size = UDim2.new(1, -20, 0, 26),
            Position = UDim2.new(0, 10, 0, 24),
            BorderSizePixel = 0,
            ZIndex = 6,
            ClipsDescendants = false
        })
        Corner(DB2, 5)
        Stroke(DB2, 1, T.BORDER)

        local SLM = New("TextLabel", {
            Parent = DB2,
            Text = "",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = T.TXT_PRI,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -28, 1, 0),
            Position = UDim2.new(0, 8, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            TextTruncate = Enum.TextTruncate.AtEnd,
            ZIndex = 7
        })
        local Arr2 = New("TextLabel", {
            Parent = DB2,
            Text = "v",
            Font = Enum.Font.GothamBold,
            TextSize = 11,
            TextColor3 = T.TXT_MUTED,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 22, 1, 0),
            Position = UDim2.new(1, -24, 0, 0),
            TextXAlignment = Enum.TextXAlignment.Center,
            ZIndex = 7
        })

        local DL2 = New("Frame", {
            Parent = DB2,
            BackgroundColor3 = T.BG_DROP,
            Size = UDim2.new(1, 0, 0, 0),
            Position = UDim2.new(0, 0, 1, 4),
            BorderSizePixel = 0,
            Visible = false,
            ZIndex = 100,
            ClipsDescendants = true
        })
        Corner(DL2, 6)
        Stroke(DL2, 1, T.BORDER)

        local SRM = New("Frame", {
            Parent = DL2,
            BackgroundColor3 = T.BG_INPUT,
            Size = UDim2.new(1, -12, 0, 22),
            Position = UDim2.new(0, 6, 0, 6),
            BorderSizePixel = 0,
            ZIndex = 51
        })
        Corner(SRM, 4)
        Stroke(SRM, 1, T.BORDER)

        local SDDM = New("TextBox", {
            Parent = SRM,
            Text = "",
            PlaceholderText = "Search...",
            Font = Enum.Font.Gotham,
            TextSize = 10,
            TextColor3 = T.TXT_PRI,
            PlaceholderColor3 = T.TXT_MUTED,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            ClearTextOnFocus = false,
            ZIndex = 52
        })

        local ILM = New("ScrollingFrame", {
            Parent = DL2,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 1, -36),
            Position = UDim2.new(0, 0, 0, 34),
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = T.RED,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 51
        })
        New("UIListLayout", {
            Parent = ILM,
            Padding = UDim.new(0, 2),
            SortOrder = Enum.SortOrder.LayoutOrder
        })
        Pad(ILM, 2, 2, 4, 4)

        local item = { _frame = Row, _label = lbl, Value = {}, _type = "MultiDropdown", _enabled = true }
        local allIBM = {}
        local open2 = false
        local _mddOutsideConn = nil
        local BuildMD

        local function SyncValue()
            local out = {}
            for i, v in ipairs(selectedOrder) do
                out[i] = v
            end
            item.Value = out
            if flag then
                ZENUHub.Flags[flag] = out
            end
            return out
        end

        local function UpdateText()
            if #selectedOrder == 0 then
                SLM.Text = ""
            else
                SLM.Text = table.concat(selectedOrder, ", ")
            end
            RefreshMB()
        end

        BuildMD = function(f)
            for _, v in ipairs(allIBM) do
                if v then v:Destroy() end
            end
            allIBM = {}

            local atMax = (#selectedOrder >= maxSel)
            for _, it in ipairs(items) do
                if f == "" or it:lower():find(f:lower(), 1, true) then
                    local isOn = selectedMap[it] == true
                    local dimmed = (atMax and not isOn)

                    local iRow = New("Frame", {
                        Parent = ILM,
                        BackgroundColor3 = isOn and T.RED_DIM or T.BG_DROP,
                        Size = UDim2.new(1, 0, 0, 28),
                        BorderSizePixel = 0,
                        ZIndex = 52
                    })
                    Corner(iRow, 4)

                    local ib = New("TextButton", {
                        Parent = iRow,
                        Text = it,
                        Font = Enum.Font.Gotham,
                        TextSize = 10,
                        TextColor3 = isOn and T.RED or (dimmed and T.TXT_MUTED or T.TXT_PRI),
                        BackgroundTransparency = 1,
                        Size = UDim2.new(1, 0, 1, 0),
                        TextXAlignment = Enum.TextXAlignment.Left,
                        ZIndex = 53
                    })
                    Pad(ib, 0, 0, 8, 4)

                    ib.MouseButton1Click:Connect(function()
                        if item._enabled == false then return end

                        if selectedMap[it] then
                            -- MinSelect: ห้าม deselect ถ้าจำนวนที่เลือกอยู่ = minSel
                            if #selectedOrder <= minSel then
                                ZENUHub:Notify({
                                    Title = "Minimum",
                                    Message = "ต้องเลือกอย่างน้อย " .. tostring(minSel) .. " รายการ",
                                    Type = "Warn",
                                    Duration = 2
                                })
                                return
                            end
                            selectedMap[it] = nil
                            for i, v in ipairs(selectedOrder) do
                                if v == it then
                                    table.remove(selectedOrder, i)
                                    break
                                end
                            end
                        else
                            if #selectedOrder >= maxSel then
                                ZENUHub:Notify({
                                    Title = "Limit",
                                    Message = "Max " .. tostring(maxSel) .. " items.",
                                    Type = "Warn",
                                    Duration = 2
                                })
                                return
                            end
                            selectedMap[it] = true
                            table.insert(selectedOrder, it)
                        end

                        UpdateText()
                        -- FIX 6: SyncValue() called once, result reused for callback
                        local out = SyncValue()
                        BuildMD(SDDM.Text)
                        cb(out)
                    end)

                    table.insert(allIBM, iRow)
                end
            end
        end

        UpdateText()
        SyncValue()
        BuildMD("")

        SDDM:GetPropertyChangedSignal("Text"):Connect(function()
            BuildMD(SDDM.Text)
        end)

        local function CloseMDD()
            open2 = false
            DL2.Visible = false
            Tween(Row, { Size = UDim2.new(1, 0, 0, 56) }, 0.2)
            Tween(Arr2, { Rotation = 0 }, 0.2)
            if _mddOutsideConn then _mddOutsideConn:Disconnect(); _mddOutsideConn = nil end
        end

        DB2.MouseButton1Click:Connect(function()
            if item._enabled == false then return end

            open2 = not open2
            DL2.Visible = open2
            if open2 then
                local ds = math.min(#items * 30 + 44, 150)
                DL2.Size = UDim2.new(1, 0, 0, ds)
                SDDM.Text = ""
                BuildMD("")
                Tween(Row, { Size = UDim2.new(1, 0, 0, 56 + ds + 8) }, 0.2)
                Tween(Arr2, { Rotation = 180 }, 0.2)
                -- Close when clicking outside the Row
                task.defer(function()
                    if not open2 then return end
                    _mddOutsideConn = UserInputService.InputBegan:Connect(function(inp, gpe)
                        if gpe then return end
                        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
                        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
                        local abs = Row.AbsolutePosition
                        local sz  = Row.AbsoluteSize
                        local pos = inp.Position
                        if pos.X < abs.X or pos.X > abs.X + sz.X
                        or pos.Y < abs.Y or pos.Y > abs.Y + sz.Y then
                            CloseMDD()
                        end
                    end)
                end)
            else
                CloseMDD()
            end
        end)

        item._default = defaults
        function item:Set(t, fire)
            selectedMap = {}
            selectedOrder = {}

            if type(t) == "table" then
                -- เปลี่ยนจาก ipairs เป็น pairs เผื่อ JSON แปลง array เป็น dictionary แบบ {"1":"Head"}
                for _, v in pairs(t) do
                    -- เช็คด้วยว่า v เป็น string แน่ๆ กัน JSON เพี้ยน
                    if type(v) == "string" and not selectedMap[v] and #selectedOrder < maxSel then
                        selectedMap[v] = true
                        table.insert(selectedOrder, v)
                    end
                end
            end

            UpdateText()
            local out = SyncValue()
            BuildMD(SDDM.Text)
            
            if fire ~= false then cb(out) end
        end

        function item:ResetToDefault() self:Set(self._default) end
        function item:Clear()
            if minSel > 0 then return end   -- MinSelect > 0: ห้าม clear ทั้งหมด
            selectedMap = {}
            selectedOrder = {}
            UpdateText()
            SyncValue()
            BuildMD(SDDM.Text)
            cb({})
            if flag then
                ZENUHub.Flags[flag] = nil
            end
        end
        function item:SetName(s)
            lbl = s
            NameLbl.Text = s
            item._label = s
        end
        function item:SetCallback(f) cb = f end
        function item:FireCallback()   cb(item.Value) end
            maxSel = n
            if n ~= math.huge and not MB then
                MB = New("TextLabel", {
                    Parent = LR,
                    Text = "0/" .. tostring(n),
                    Font = Enum.Font.GothamBold,
                    TextSize = 10,
                    TextColor3 = T.RED,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.3, 0, 1, 0),
                    Position = UDim2.new(0.7, 0, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    ZIndex = 6
                })
            end

            while #selectedOrder > maxSel do
                local removed = table.remove(selectedOrder)
                selectedMap[removed] = nil
            end

            UpdateText()
            SyncValue()
            BuildMD(SDDM.Text)
        end
        function item:SetMinSelect(n)
            minSel = math.max(0, n)
            -- ถ้าเลือกไว้น้อยกว่า minSel ใหม่ ให้แจ้ง (ไม่บังคับเพิ่มอัตโนมัติ)
        end
        function item:SetItems(t)
            items = t
            selectedMap = {}
            selectedOrder = {}
            SLM.Text = ""
            UpdateText()
            SyncValue()
            RefreshMB()
            BuildMD(SDDM.Text)
            if flag then
                ZENUHub.Flags[flag] = nil
            end
        end
        function item:AddItem(s)
            table.insert(items, s)
            BuildMD(SDDM.Text)
        end
        function item:RemoveItem(s)
            for i, v in ipairs(items) do
                if v == s then
                    table.remove(items, i)
                    break
                end
            end
            if selectedMap[s] then
                selectedMap[s] = nil
                for i, v in ipairs(selectedOrder) do
                    if v == s then
                        table.remove(selectedOrder, i)
                        break
                    end
                end
            end
            UpdateText()
            SyncValue()
            BuildMD(SDDM.Text)
        end
        function item:GetSelected()
            return SyncValue()
        end
        function item:Refresh(t)
            self:SetItems(t)
        end

        Row.Destroying:Connect(function()
            if _mddOutsideConn then _mddOutsideConn:Disconnect(); _mddOutsideConn = nil end
        end)

        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(item.Value) end) end
        table.insert(Section._items, item)
        return item
    end

    -- ── COLOR PICKER ───────────────────────────────────────
    function Section:AddColorPicker(o)
        o = o or {}
        local lbl   = o.Name    or "Color Picker"
        local def   = o.Default or Color3.fromRGB(255, 255, 255)
        local cb    = o.Callback or function() end
        local flag  = o.Flag

        local H, S, V = Color3.toHSV(def)

        local Row = New("Frame", {
            Parent = IF, BackgroundColor3 = T.BG_CARD,
            Size = UDim2.new(1,0,0,34), BorderSizePixel=0,
            ClipsDescendants=true, ZIndex=4
        })
        Corner(Row, 6)

        local NameLbl = New("TextLabel", {
            Parent=Row, Text=lbl, Font=Enum.Font.Gotham, TextSize=12,
            TextColor3=T.TXT_PRI, BackgroundTransparency=1,
            Size=UDim2.new(1,-60,0,34), Position=UDim2.new(0,10,0,0),
            TextXAlignment=Enum.TextXAlignment.Left, ZIndex=5
        })

        local ColorBtn = New("TextButton", {
            Parent=Row, Text="", BackgroundColor3=def,
            Size=UDim2.new(0,42,0,22), Position=UDim2.new(1,-50,0,6),
            BorderSizePixel=0, ZIndex=6
        })
        Corner(ColorBtn,5); Stroke(ColorBtn,1,T.BORDER)

        -- Panel: 172 px tall
        local PickerPanel = New("Frame", {
            Parent=Row, BackgroundColor3=T.BG_DROP,
            Size=UDim2.new(1,-20,0,172), Position=UDim2.new(0,10,0,38),
            BorderSizePixel=0, Visible=false, ZIndex=10
        })
        Corner(PickerPanel,6); Stroke(PickerPanel,1,T.BORDER)

        -- SV map
        local SVMap = New("TextButton", {
            Parent=PickerPanel, Text="", BackgroundColor3=Color3.fromHSV(H,1,1),
            Size=UDim2.new(1,-30,0,96), Position=UDim2.new(0,8,0,8),
            BorderSizePixel=0, AutoButtonColor=false, ZIndex=11
        })
        Corner(SVMap,4)
        local WhiteLayer = New("Frame",{Parent=SVMap,
            BackgroundColor3=Color3.fromRGB(255,255,255),
            Size=UDim2.new(1,0,1,0), BorderSizePixel=0, ZIndex=12})
        Corner(WhiteLayer,4)
        New("UIGradient",{Parent=WhiteLayer, Rotation=0,
            Transparency=NumberSequence.new{
                NumberSequenceKeypoint.new(0,0), NumberSequenceKeypoint.new(1,1)}})
        local BlackLayer = New("Frame",{Parent=SVMap,
            BackgroundColor3=Color3.fromRGB(0,0,0),
            Size=UDim2.new(1,0,1,0), BorderSizePixel=0, ZIndex=13})
        Corner(BlackLayer,4)
        New("UIGradient",{Parent=BlackLayer, Rotation=90,
            Transparency=NumberSequence.new{
                NumberSequenceKeypoint.new(0,1), NumberSequenceKeypoint.new(1,0)}})
        local SVDot = New("Frame",{Parent=BlackLayer,
            BackgroundColor3=Color3.new(1,1,1),
            Size=UDim2.new(0,8,0,8), Position=UDim2.new(S,-4,1-V,-4),
            BorderSizePixel=0, ZIndex=14})
        Corner(SVDot,4); Stroke(SVDot,1,Color3.new(0,0,0))

        -- Hue bar
        local HueMap = New("TextButton",{
            Parent=PickerPanel, Text="", BackgroundColor3=Color3.new(1,1,1),
            Size=UDim2.new(0,10,0,96), Position=UDim2.new(1,-18,0,8),
            BorderSizePixel=0, AutoButtonColor=false, ZIndex=11
        })
        Corner(HueMap,4)
        New("UIGradient",{Parent=HueMap, Rotation=90, Color=ColorSequence.new{
            ColorSequenceKeypoint.new(0,    Color3.fromRGB(255,0,0)),
            ColorSequenceKeypoint.new(0.167,Color3.fromRGB(255,255,0)),
            ColorSequenceKeypoint.new(0.333,Color3.fromRGB(0,255,0)),
            ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,255,255)),
            ColorSequenceKeypoint.new(0.667,Color3.fromRGB(0,0,255)),
            ColorSequenceKeypoint.new(0.833,Color3.fromRGB(255,0,255)),
            ColorSequenceKeypoint.new(1,    Color3.fromRGB(255,0,0))
        }})
        local HueDot = New("Frame",{Parent=HueMap,
            BackgroundColor3=Color3.new(1,1,1),
            Size=UDim2.new(1,4,0,4), Position=UDim2.new(0,-2,H,-2),
            BorderSizePixel=0, ZIndex=13})
        Stroke(HueDot,1,Color3.new(0,0,0))

        -- ── Separator above HEX/RGB ───────────────────────────
        New("Frame",{Parent=PickerPanel, BackgroundColor3=T.BORDER,
            Size=UDim2.new(1,-16,0,1), Position=UDim2.new(0,8,0,112),
            BorderSizePixel=0, ZIndex=11})

        -- ── HEX Input ─────────────────────────────────────────
        local HexRow = New("Frame",{Parent=PickerPanel, BackgroundTransparency=1,
            Size=UDim2.new(1,-16,0,22), Position=UDim2.new(0,8,0,118),
            BorderSizePixel=0, ZIndex=11})
        local HexFrame = New("Frame",{Parent=HexRow,
            BackgroundColor3=T.BG_INPUT,
            Size=UDim2.new(0.46,-2,1,0), Position=UDim2.new(0,0,0,0),
            BorderSizePixel=0, ZIndex=12})
        Corner(HexFrame,4); local HexStroke=Stroke(HexFrame,1,T.BORDER)
        New("TextLabel",{Parent=HexFrame, Text="#",
            Font=Enum.Font.GothamBold, TextSize=10, TextColor3=T.TXT_MUTED,
            BackgroundTransparency=1, Size=UDim2.new(0,18,1,0),
            TextXAlignment=Enum.TextXAlignment.Center, ZIndex=13})
        local HexBox = New("TextBox",{Parent=HexFrame, Text="",
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=T.RED,
            PlaceholderText="RRGGBB", PlaceholderColor3=T.TXT_MUTED,
            BackgroundTransparency=1, ClearTextOnFocus=false,
            Size=UDim2.new(1,-20,1,0), Position=UDim2.new(0,18,0,0), ZIndex=13})

        -- ── RGB Inputs ────────────────────────────────────────
        local RgbFrame = New("Frame",{Parent=HexRow, BackgroundTransparency=1,
            Size=UDim2.new(0.54,-4,1,0), Position=UDim2.new(0.46,4,0,0),
            BorderSizePixel=0, ZIndex=12})
        New("UIListLayout",{Parent=RgbFrame,
            FillDirection=Enum.FillDirection.Horizontal,
            Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder,
            VerticalAlignment=Enum.VerticalAlignment.Center})
        local RBoxes = {}
        for i, ch in ipairs({"R","G","B"}) do
            local cellCol = i==1 and Color3.fromRGB(200,60,60)
                         or i==2 and Color3.fromRGB(60,180,90)
                         or Color3.fromRGB(60,110,210)
            local cell = New("Frame",{Parent=RgbFrame,
                BackgroundColor3=T.BG_INPUT,
                Size=UDim2.new(0.333,-2,1,0), BorderSizePixel=0, ZIndex=13})
            Corner(cell,4); Stroke(cell,1,T.BORDER)
            New("TextLabel",{Parent=cell, Text=ch,
                Font=Enum.Font.GothamBold, TextSize=9, TextColor3=cellCol,
                BackgroundTransparency=1, Size=UDim2.new(0,14,1,0), ZIndex=14,
                TextXAlignment=Enum.TextXAlignment.Center})
            local tb = New("TextBox",{Parent=cell, Text="",
                Font=Enum.Font.GothamBold, TextSize=10,
                TextColor3=T.TXT_PRI, PlaceholderText="0",
                PlaceholderColor3=T.TXT_MUTED, BackgroundTransparency=1,
                ClearTextOnFocus=false,
                Size=UDim2.new(1,-16,1,0), Position=UDim2.new(0,14,0,0), ZIndex=14})
            RBoxes[i] = tb
        end

        -- ── State & helpers ───────────────────────────────────
        local _updatingInputs = false
        local item = { _frame=Row, _label=lbl, Value=def, _type="ColorPicker", _enabled=true }
        local open = false
        local draggingSV=false; local draggingHue=false

        local function SyncInputsFromHSV()
            if _updatingInputs then return end
            _updatingInputs = true
            local c = Color3.fromHSV(H,S,V)
            HexBox.Text = Color3ToHex(c)
            RBoxes[1].Text = tostring(math.floor(c.R*255+0.5))
            RBoxes[2].Text = tostring(math.floor(c.G*255+0.5))
            RBoxes[3].Text = tostring(math.floor(c.B*255+0.5))
            _updatingInputs = false
        end

        local function UpdateDots()
            SVDot.Position = UDim2.new(S,-4,1-V,-4)
            HueDot.Position = UDim2.new(0,-2,H,-2)
        end

        local function UpdateColor(fire)
            local newColor = Color3.fromHSV(H,S,V)
            SVMap.BackgroundColor3 = Color3.fromHSV(H,1,1)
            ColorBtn.BackgroundColor3 = newColor
            SyncInputsFromHSV()
            item.Value = newColor
            if fire ~= false then cb(newColor) end
            if flag then ZENUHub.Flags[flag] = newColor end
        end

        local function ApplyHSV(fire) UpdateDots(); UpdateColor(fire) end

        -- Wire input boxes
        HexBox.Focused:Connect(function() Tween(HexStroke,{Color=T.RED},0.14) end)
        HexBox.FocusLost:Connect(function()
            Tween(HexStroke,{Color=T.BORDER},0.14)
            local c = HexToColor3(HexBox.Text)
            if c then H,S,V=Color3.toHSV(c); ApplyHSV(true) end
        end)
        for i, tb in ipairs(RBoxes) do
            tb.FocusLost:Connect(function()
                if _updatingInputs then return end
                local n = tonumber(tb.Text)
                if n then
                    local c = Color3.fromHSV(H,S,V)
                    local rv = {math.floor(c.R*255+0.5),math.floor(c.G*255+0.5),math.floor(c.B*255+0.5)}
                    rv[i] = math.clamp(math.floor(n+0.5),0,255)
                    H,S,V = Color3.toHSV(Color3.fromRGB(rv[1],rv[2],rv[3]))
                    ApplyHSV(true)
                end
            end)
        end

        local function ToggleCP()
            if item._enabled == false then return end
            open = not open
            PickerPanel.Visible = open
            -- Open height = 34 (header) + 172 (panel) + 14 (gap) = 220
            Tween(Row, {Size=UDim2.new(1,0,0, open and 220 or 34)}, 0.2)
        end
        ColorBtn.MouseButton1Click:Connect(ToggleCP)
        Hover(Row, T.BG_CARD, T.BG_CARD_H)

        local function UpdateSV(inp)
            local pos=SVMap.AbsolutePosition; local sz=SVMap.AbsoluteSize
            S = math.clamp((inp.Position.X-pos.X)/sz.X,0,1)
            V = 1-math.clamp((inp.Position.Y-pos.Y)/sz.Y,0,1)
            ApplyHSV(true)
        end
        local function UpdateHue(inp)
            local pos=HueMap.AbsolutePosition; local sz=HueMap.AbsoluteSize
            H = math.clamp((inp.Position.Y-pos.Y)/sz.Y,0,1)
            ApplyHSV(true)
        end
        SVMap.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                draggingSV=true; UpdateSV(inp) end
        end)
        HueMap.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                draggingHue=true; UpdateHue(inp) end
        end)
        local cpChangedConn = UserInputService.InputChanged:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseMovement
            or inp.UserInputType==Enum.UserInputType.Touch then
                if draggingSV    then UpdateSV(inp)         end
                if draggingHue   then UpdateHue(inp)        end
            end
        end)
        local cpEndedConn = UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1
            or inp.UserInputType==Enum.UserInputType.Touch then
                draggingSV=false; draggingHue=false
            end
        end)
        Row.Destroying:Connect(function()
            if cpChangedConn then cpChangedConn:Disconnect() end
            if cpEndedConn   then cpEndedConn:Disconnect()   end
        end)

        item._default      = def
        function item:Set(col)
            H,S,V = Color3.toHSV(col); ApplyHSV(false)
        end
        function item:ResetToDefault()
            self:Set(self._default)
        end
        function item:SetName(s)
            lbl=s; NameLbl.Text=s; item._label=s
        end
        function item:SetCallback(f) cb=f end
        function item:FireCallback()   cb(item.Value) end

        UpdateDots(); UpdateColor(false)

        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(item.Value) end) end
        table.insert(Section._items, item)
        return item
    end


    -- ── LABEL ────────────────────────────────────────────────
    function Section:AddLabel(o)
        o=o or {}
        local text=o.Text or "Label"; local col=o.Color or T.TXT_SEC
        local tsz=o.TextSize or 11

        local Lbl=New("Frame",{Parent=IF,BackgroundColor3=T.BG_CARD,
            Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0})
        Corner(Lbl,5); Stroke(Lbl,1,T.SEP)

        local LT=New("TextLabel",{Parent=Lbl,Text=text,Font=Enum.Font.Gotham,
            TextSize=tsz,TextColor3=col,BackgroundTransparency=1,
            Size=UDim2.new(1,-16,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            Position=UDim2.new(0,8,0,0),TextXAlignment=Enum.TextXAlignment.Left,
            TextWrapped=true,RichText=true})
        Pad(LT,5,5,0,0)

        local item={_frame=Lbl,_label=text,_type="Label"}

        function item:SetText(s)       LT.Text=s; item._label=s end
        function item:SetColor(c)      LT.TextColor3=c end
        function item:SetTextSize(n)   LT.TextSize=n end

        _attachCommon(item, Lbl, o)
        table.insert(Section._items,item); return item
    end

    -- ── TEXT  (plain text, no border/background) ─────────────
    function Section:AddText(o)
        o=o or {}
        local text   = o.Text     or ""
        local col    = o.Color    or T.TXT_SEC
        local tsz    = o.TextSize or 11
        local font   = o.Font     or Enum.Font.Gotham
        local pad    = o.Padding  or 3
        local alignMap={Left=Enum.TextXAlignment.Left,
            Center=Enum.TextXAlignment.Center,Right=Enum.TextXAlignment.Right}
        local xAlign = alignMap[o.Align] or Enum.TextXAlignment.Left

        local Wrap=New("Frame",{Parent=IF,BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BorderSizePixel=0})

        local LT=New("TextLabel",{Parent=Wrap,Text=text,Font=font,
            TextSize=tsz,TextColor3=col,BackgroundTransparency=1,
            Size=UDim2.new(1,-20,0,0),AutomaticSize=Enum.AutomaticSize.Y,
            Position=UDim2.new(0,10,0,0),TextXAlignment=xAlign,
            TextWrapped=true,RichText=true})
        Pad(LT,pad,pad,0,0)

        local item={_frame=Wrap,_label=text,_type="Text"}

        function item:SetText(s)
            LT.Text=s; item._label=s end
        function item:SetColor(c)
            LT.TextColor3=c end
        function item:SetTextSize(n)
            LT.TextSize=n end
        function item:SetAlign(a)
            LT.TextXAlignment=alignMap[a] or Enum.TextXAlignment.Left end

        _attachCommon(item, Wrap, o)
        table.insert(Section._items,item); return item
    end

    -- ── KEYBIND  (Toggle / Hold / Always modes + [•••] config) ──
    function Section:AddKeybind(o)
        o = o or {}
        local lbl      = o.Name    or "Keybind"
        local def      = o.Default or Enum.KeyCode.Unknown
        local cb       = o.Callback or function() end
        local kbMode   = o.Mode    or "Toggle"   -- "Toggle" | "Hold" | "Always"
        local key      = def
        local listening= false
        local kbHeld   = false   -- is key currently held down?

        local Row = New("Frame",{
            Parent=IF, BackgroundColor3=T.BG_CARD,
            Size=UDim2.new(1,0,0,34), BorderSizePixel=0
        })
        Corner(Row,6)

        local NameLbl = New("TextLabel",{
            Parent=Row, Text=lbl, Font=Enum.Font.Gotham, TextSize=12,
            TextColor3=T.TXT_PRI, BackgroundTransparency=1,
            Size=UDim2.new(1,-116,1,0), Position=UDim2.new(0,10,0,0),
            TextXAlignment=Enum.TextXAlignment.Left
        })

        -- Key bind button (narrower to make room for config)
        local KB = New("TextButton",{
            Parent=Row, Text=key==Enum.KeyCode.Unknown and "NONE" or key.Name,
            Font=Enum.Font.GothamBold, TextSize=10,
            TextColor3=T.RED, BackgroundColor3=T.BG_INPUT,
            Size=UDim2.new(0,64,0,22), Position=UDim2.new(1,-100,0.5,-11),
            BorderSizePixel=0, ZIndex=3
        })
        Corner(KB,4); Stroke(KB,1,T.BORDER)

        -- [T/H/A] mode indicator button  (T=Toggle  H=Hold  A=Always)
        local _modeInitMap = {Toggle="T", Hold="H", Always="A"}
        local CfgBtn = New("TextButton",{
            Parent=Row, Text=_modeInitMap[kbMode] or "T",
            Font=Enum.Font.GothamBold, TextSize=11,
            TextColor3=T.RED, BackgroundColor3=T.BG_INPUT,
            Size=UDim2.new(0,26,0,22), Position=UDim2.new(1,-32,0.5,-11),
            BorderSizePixel=0, ZIndex=3
        })
        Corner(CfgBtn,4); Stroke(CfgBtn,1,T.BORDER)

        local item = {
            _frame=Row, _label=lbl, Value=key,
            _type="Keybind", _enabled=true, Mode=kbMode
        }

        -- ── Listen for new key ────────────────────────────────
        KB.MouseButton1Click:Connect(function()
            if item._enabled==false then return end
            listening=true
            KB.Text="..."
            Tween(KB,{TextColor3=T.TXT_PRI},0.1)
        end)

        -- ── Mode Popup (floating ScreenGui) ──────────────────
        local _modePopGui = nil
        local _modePopOutConn = nil

        local function CloseModePopup()
            if _modePopGui and _modePopGui.Parent then
                _modePopGui:Destroy(); _modePopGui=nil
            end
            if _modePopOutConn then
                _modePopOutConn:Disconnect(); _modePopOutConn=nil
            end
        end

        local function OpenModePopup()
            CloseModePopup()
            _modePopGui = New("ScreenGui",{Parent=CoreGui, Name="ZENUModePopup",
                ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
                IgnoreGuiInset=true})

            local _pf = New("Frame",{Parent=_modePopGui,
                BackgroundColor3=T.BG_DROP, Size=UDim2.new(0,96,0,86),
                BorderSizePixel=0, ZIndex=300})
            Corner(_pf,8); Stroke(_pf,1,T.BORDER)

            New("UIListLayout",{Parent=_pf,
                Padding=UDim.new(0,3), SortOrder=Enum.SortOrder.LayoutOrder})
            Pad(_pf,5,5,5,5)

            New("TextLabel",{Parent=_pf, Text="KEYBIND MODE",
                Font=Enum.Font.GothamBold, TextSize=8,
                TextColor3=T.TXT_MUTED, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,12), ZIndex=301,
                TextXAlignment=Enum.TextXAlignment.Center})

            local modes = {"Toggle","Hold","Always"}
            local modeDesc = {
                Toggle="Fire once per press",
                Hold  ="cb(true) down / cb(false) up",
                Always="cb() every heartbeat while held",
            }
            for _, m in ipairs(modes) do
                local isActive = (kbMode == m)
                local mb = New("TextButton",{Parent=_pf,
                    Text=m, Font=Enum.Font.GothamBold, TextSize=11,
                    TextColor3=isActive and T.RED or T.TXT_PRI,
                    BackgroundColor3=isActive and T.RED_DIM or T.BG_CARD,
                    Size=UDim2.new(1,0,0,20),
                    BorderSizePixel=0, ZIndex=301})
                Corner(mb,5)
                SetupTooltip(mb, modeDesc[m])
                mb.MouseEnter:Connect(function()
                    if kbMode~=m then Tween(mb,{BackgroundColor3=T.BG_CARD_H},0.1) end
                end)
                mb.MouseLeave:Connect(function()
                    Tween(mb,{BackgroundColor3=isActive and T.RED_DIM or T.BG_CARD},0.1)
                end)
                mb.MouseButton1Click:Connect(function()
                    kbMode = m; item.Mode = m
                    local modeInitials = {Toggle="T",Hold="H",Always="A"}
                    CfgBtn.Text = modeInitials[m] or "T"
                    Tween(CfgBtn,{TextColor3=T.RED},0.1)
                    -- อัปเดต Flag เพื่อให้ SaveConfig จับค่าล่าสุดได้
                    if o.Flag then ZENUHub.Flags[o.Flag] = key end
                    CloseModePopup()
                end)
            end

            -- Position near CfgBtn
            task.defer(function()
                if not (_pf and _pf.Parent) then return end
                local ap  = CfgBtn.AbsolutePosition
                local vp  = workspace.CurrentCamera.ViewportSize
                local px  = ap.X - 68
                local py  = ap.Y - 94
                px = math.clamp(px, 4, vp.X - 100)
                py = math.clamp(py, 4, vp.Y - 90)
                _pf.Position = UDim2.new(0,px,0,py)
            end)

            -- Close on outside click
            task.defer(function()
                _modePopOutConn = UserInputService.InputBegan:Connect(function(inp,gpe)
                    if gpe then return end
                    if inp.UserInputType~=Enum.UserInputType.MouseButton1
                    and inp.UserInputType~=Enum.UserInputType.Touch then return end
                    task.defer(function()
                        if not (_pf and _pf.Parent) then return end
                        local abs=_pf.AbsolutePosition; local sz=_pf.AbsoluteSize
                        local pos=inp.Position
                        if pos.X<abs.X or pos.X>abs.X+sz.X
                        or pos.Y<abs.Y or pos.Y>abs.Y+sz.Y then
                            CloseModePopup()
                        end
                    end)
                end)
            end)
        end

        CfgBtn.MouseButton1Click:Connect(function()
            if item._enabled==false then return end
            if _modePopGui and _modePopGui.Parent then
                CloseModePopup()
            else
                OpenModePopup()
            end
        end)
        CfgBtn.MouseEnter:Connect(function() Tween(CfgBtn,{TextColor3=T.RED_B},0.1) end)
        CfgBtn.MouseLeave:Connect(function()
            local modeInitials={Toggle="T",Hold="H",Always="A"}
            CfgBtn.Text = modeInitials[kbMode] or "T"
            Tween(CfgBtn,{TextColor3=T.RED},0.1)
        end)

        -- ── Input connections ─────────────────────────────────
        local kbInputConn = UserInputService.InputBegan:Connect(function(inp,gpe)
            if gpe then return end
            if inp.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if listening then
                listening=false
                key=inp.KeyCode
                KB.Text=key.Name
                Tween(KB,{TextColor3=T.RED},0.1)
                item.Value=key
                -- [v3.1] Update Flags immediately so SaveConfig always captures
                -- the latest key even without a prior :Set() call.
                if o.Flag and ZENUHub._flaggedItems[o.Flag] then
                    ZENUHub.Flags[o.Flag] = key
                end
                return
            end
            if inp.KeyCode==key and item._enabled~=false then
                kbHeld=true
                if     kbMode=="Toggle" then cb()
                elseif kbMode=="Hold"   then cb(true)
                end
            end
        end)

        local kbEndedConn = UserInputService.InputEnded:Connect(function(inp)
            if inp.UserInputType~=Enum.UserInputType.Keyboard then return end
            if inp.KeyCode==key then
                kbHeld=false
                if kbMode=="Hold" then cb(false) end
            end
        end)

        -- Always mode: fire cb() every heartbeat while key held
        local kbHeartConn = RunService.Heartbeat:Connect(function()
            if kbMode=="Always" and kbHeld and item._enabled~=false then
                cb()
            end
        end)
        table.insert(ZENUHub._connections, kbHeartConn)

        Hover(Row, T.BG_CARD, T.BG_CARD_H)

        item._default     = def
        item._defaultMode = o.Mode or "Toggle"
        function item:Set(kc)
            key=kc; item.Value=kc
            KB.Text=(kc==Enum.KeyCode.Unknown) and "NONE" or kc.Name
            -- Only update Flags if this item is registered (not Save=false)
            if o.Flag and ZENUHub._flaggedItems[o.Flag] then
                ZENUHub.Flags[o.Flag] = kc
            end
        end
        function item:Clear()
            key=Enum.KeyCode.Unknown; item.Value=key; KB.Text="NONE"
        end
        function item:SetName(s)
            lbl=s; NameLbl.Text=s; item._label=s
        end
        function item:SetMode(m)
            kbMode=m; item.Mode=m
            local mi={Toggle="T",Hold="H",Always="A"}
            CfgBtn.Text=mi[m] or "T"
            Tween(CfgBtn,{TextColor3=T.RED},0.1)
            if o.Flag and ZENUHub._flaggedItems[o.Flag] then
                ZENUHub.Flags[o.Flag] = key
            end
        end
        function item:ResetToDefault()
            self:Set(self._default)
            self:SetMode(self._defaultMode)
        end
        function item:SetCallback(f) cb=f end
        function item:FireCallback()   cb(item.Value) end

        Row.Destroying:Connect(function()
            if kbInputConn  then kbInputConn:Disconnect()  end
            if kbEndedConn  then kbEndedConn:Disconnect()  end
            if kbHeartConn  then kbHeartConn:Disconnect()  end
            CloseModePopup()
            for i,c in ipairs(ZENUHub._connections) do
                if c==kbHeartConn then table.remove(ZENUHub._connections,i); break end
            end
        end)

        item._fireOnStart = o.Start == true
        _attachCommon(item, Row, o)
        if o.Start then task.defer(function() cb(key) end) end
        table.insert(Section._items, item)
        return item
    end

    -- ── SEPARATOR ────────────────────────────────────────────
    function Section:AddSeparator(o)
        o = o or {}
        local label  = o.Label or ""
        local col    = o.Color or T.BORDER

        local Wrap = New("Frame", {Parent=IF, BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,18), BorderSizePixel=0})

        -- Horizontal line
        local Line = New("Frame", {Parent=Wrap, BackgroundColor3=col,
            Size=UDim2.new(1,-16,0,1), Position=UDim2.new(0,8,0.5,0),
            BorderSizePixel=0})
        Corner(Line,1)

        if label ~= "" then
            -- Pill label centred on the line
            local LF = New("Frame", {Parent=Wrap,
                BackgroundColor3=T.BG_CARD,
                AutomaticSize=Enum.AutomaticSize.X,
                Size=UDim2.new(0,0,0,16),
                Position=UDim2.new(0.5,0,0.5,-8),
                AnchorPoint=Vector2.new(0.5,0),
                BorderSizePixel=0, ZIndex=2})
            Corner(LF,4)
            local LL = New("TextLabel",{Parent=LF,
                Text=label, Font=Enum.Font.Gotham, TextSize=10,
                TextColor3=T.TXT_MUTED, BackgroundTransparency=1,
                AutomaticSize=Enum.AutomaticSize.X,
                Size=UDim2.new(0,0,1,0), ZIndex=3})
            Pad(LL,0,0,6,6)
        end

        local item = {_frame=Wrap, _label=label, _type="Separator", Value=nil}
        _attachCommon(item, Wrap, o)
        table.insert(Section._items, item)
        return item
    end

end -- BuildSectionComponents

-- ============================================================
--  MAIN WINDOW
-- ============================================================
function ZENUHub:CreateWindow(opts)
    opts=opts or {}
    local hubName=opts.Name        or "ZENU Hub"
    local hubDesc=opts.Description or "Advanced Scripting Hub"
    local initTab=opts.DefaultTab  or nil
    local sizeW  =opts.Width       or 720
    local sizeH  =opts.Height      or 480
    local discord=opts.Discord     or "discord.gg/zenuhub"
    local creator  = opts.Creator   or ""
    -- Social links (only displayed if value is provided)
    local _socials = {
        {key="Discord",   icon="DC", col=Color3.fromRGB( 88,101,242), url=opts.Discord},
        {key="Facebook",  icon="FB", col=Color3.fromRGB( 66,103,178), url=opts.Facebook},
        {key="TikTok",    icon="TT", col=Color3.fromRGB(  0,200,190), url=opts.TikTok},
        {key="YouTube",   icon="YT", col=Color3.fromRGB(220, 30, 30), url=opts.YouTube},
        {key="Line",      icon="LN", col=Color3.fromRGB(  0,195, 75), url=opts.Line},
        {key="Instagram", icon="IG", col=Color3.fromRGB(210, 55,115), url=opts.Instagram},
    }
    local _enabledSocials = {}
    for _, s in ipairs(_socials) do
        if s.url and s.url ~= "" then table.insert(_enabledSocials, s) end
    end

    local SG=New("ScreenGui",{Parent=CoreGui,
        Name="ZENUHub_"..tostring(math.random(10000,99999)),
        ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true})
    table.insert(ZENUHub._guiList, SG)

    local MF=New("Frame",{Parent=SG,BackgroundColor3=T.BG_WIN,
        Size=UDim2.new(0,sizeW,0,sizeH),
        Position=UDim2.new(0.5,-sizeW/2,0.5,-sizeH/2),
        BorderSizePixel=0,ClipsDescendants=false})
    Corner(MF,12); Stroke(MF,1,T.BORDER_R,0.35)

    -- ── HEADER ───────────────────────────────────────────────
    local Hdr=New("Frame",{Parent=MF,BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,52),BorderSizePixel=0,ZIndex=5})
    Corner(Hdr,12)
    New("Frame",{Parent=Hdr,BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),
        BorderSizePixel=0,ZIndex=4})
    New("Frame",{Parent=Hdr,BackgroundColor3=T.SEP,
        Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),
        BorderSizePixel=0,ZIndex=4})

    MakeDraggable(MF,Hdr)

    -- ── Z LOGO ───────────────────────────────────────────────────
    local LB=New("TextButton",{Parent=Hdr,
        BackgroundColor3=Color3.fromRGB(22,18,18),
        Text="",AutoButtonColor=false,
        Size=UDim2.new(0,42,0,42),Position=UDim2.new(0,8,0.5,-21),
        BorderSizePixel=0,ZIndex=6,ClipsDescendants=true})
    Corner(LB,12)
    -- 3px gray border
    Stroke(LB,3,Color3.fromRGB(90,90,100),0)
    -- faint top gloss
    local _Gl=New("Frame",{Parent=LB,
        BackgroundColor3=Color3.fromRGB(255,255,255),BackgroundTransparency=0.93,
        Size=UDim2.new(1,0,0,42),Position=UDim2.new(0,0,0,0),
        BorderSizePixel=0,ZIndex=7})
    Corner(_Gl,12)
    -- Z label
    New("TextLabel",{Parent=LB,Text="Z",Font=Enum.Font.GothamBold,TextSize=24,
        TextColor3=T.RED,BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center,ZIndex=8})

    New("TextLabel",{Parent=Hdr,Text=hubName,Font=Enum.Font.GothamBold,TextSize=14,
        TextColor3=T.TXT_PRI,BackgroundTransparency=1,Size=UDim2.new(0,115,0,20),
        Position=UDim2.new(0,54,0,7),TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=6})
    New("TextLabel",{Parent=Hdr,Text=hubDesc,Font=Enum.Font.Gotham,TextSize=10,
        TextColor3=T.TXT_MUTED,BackgroundTransparency=1,Size=UDim2.new(0,115,0,16),
        Position=UDim2.new(0,54,0,28),TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=6})

    local function WB(lbl,bg,xOff)
        local b=New("TextButton",{Parent=Hdr,Text=lbl,Font=Enum.Font.GothamBold,
            TextSize=11,TextColor3=Color3.fromRGB(210,210,210),BackgroundColor3=bg,
            Size=UDim2.new(0,22,0,22),Position=UDim2.new(1,xOff,0.5,-11),
            BorderSizePixel=0,ZIndex=8})
        Corner(b,6)
        b.MouseEnter:Connect(function() Tween(b,{BackgroundColor3=bg:Lerp(Color3.new(1,1,1),0.22)},0.1) end)
        b.MouseLeave:Connect(function() Tween(b,{BackgroundColor3=bg},0.1) end)
        return b
    end
    local BtnX=WB("X",Color3.fromRGB(195,38,38),-30)
    local BtnM=WB("-",Color3.fromRGB(48,48,62),-58)

    local SBx=New("Frame",{Parent=Hdr,BackgroundColor3=T.BG_INPUT,
        Size=UDim2.new(1,-248,0,26),Position=UDim2.new(0,178,0.5,-13),
        BorderSizePixel=0,ZIndex=6})
    Corner(SBx,6); Stroke(SBx,1,T.BORDER)
    New("TextLabel",{Parent=SBx,Text="[S]",Font=Enum.Font.GothamBold,TextSize=9,
        TextColor3=T.TXT_MUTED,BackgroundTransparency=1,Size=UDim2.new(0,24,1,0),
        Position=UDim2.new(0,3,0,0),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7})
    local SI=New("TextBox",{Parent=SBx,Text="",PlaceholderText="Search...",
        Font=Enum.Font.Gotham,TextSize=11,TextColor3=T.TXT_PRI,PlaceholderColor3=T.TXT_MUTED,
        BackgroundTransparency=1,Size=UDim2.new(1,-28,1,0),Position=UDim2.new(0,26,0,0),
        TextXAlignment=Enum.TextXAlignment.Left,ClearTextOnFocus=false,ZIndex=7})
    SI.Focused:Connect(function() Tween(SBx,{BackgroundColor3=T.BG_CARD},0.14) end)
    SI.FocusLost:Connect(function() Tween(SBx,{BackgroundColor3=T.BG_INPUT},0.14) end)

    -- ── BODY ─────────────────────────────────────────────────
    local Body=New("Frame",{Parent=MF,BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,-52-22),Position=UDim2.new(0,0,0,52),
        BorderSizePixel=0,ClipsDescendants=true})

    local Sidebar=New("Frame",{Parent=Body,BackgroundColor3=T.BG_SIDE,
        Size=UDim2.new(0,SIDE_W,1,0),BorderSizePixel=0})
    New("Frame",{Parent=Sidebar,BackgroundColor3=T.SEP,
        Size=UDim2.new(0,1,1,0),Position=UDim2.new(1,-1,0,0),BorderSizePixel=0})
    local SideList=New("ScrollingFrame",{Parent=Sidebar,BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,-8),Position=UDim2.new(0,0,0,8),
        ScrollBarThickness=0,BorderSizePixel=0,
        CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y})
    New("UIListLayout",{Parent=SideList,FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,5),SortOrder=Enum.SortOrder.LayoutOrder})
    Pad(SideList,6,6,0,0)

    local Content=New("Frame",{Parent=Body,BackgroundColor3=T.BG_WIN,
        Size=UDim2.new(1,-SIDE_W,1,0),Position=UDim2.new(0,SIDE_W,0,0),
        BorderSizePixel=0,ClipsDescendants=true})

    local Footer=New("Frame",{Parent=MF,BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,22),Position=UDim2.new(0,0,1,-22),BorderSizePixel=0})
    Corner(Footer,12)
    New("Frame",{Parent=Footer,BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,0),BorderSizePixel=0})
    New("Frame",{Parent=Footer,BackgroundColor3=T.SEP,
        Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,0,0),BorderSizePixel=0})
    New("TextLabel",{Parent=Footer,Text=discord,Font=Enum.Font.Gotham,TextSize=10,
        TextColor3=T.TXT_MUTED,BackgroundTransparency=1,Size=UDim2.new(1,-20,1,0),
        Position=UDim2.new(0,12,0,0),TextXAlignment=Enum.TextXAlignment.Left})

    -- ── RESIZE HANDLE (bottom-right only, touch + mouse, stable) ──
    local RH=New("Frame",{Parent=MF,BackgroundTransparency=1,
        Size=UDim2.new(0,28,0,28),Position=UDim2.new(1,-28,1,-28),
        BorderSizePixel=0,ZIndex=30,Active=true})
    New("TextLabel",{Parent=RH,Text="⊿",Font=Enum.Font.GothamBold,TextSize=11,
        TextColor3=T.TXT_MUTED,BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Right,
        TextYAlignment=Enum.TextYAlignment.Bottom,ZIndex=31})
    do
        local rsz    = false
        local rsStart = nil  -- Vector2: cursor position at drag start
        local rfStart = nil  -- Vector2: window size at drag start

        RH.InputBegan:Connect(function(inp)
            if rsz then return end   -- ignore extra inputs while already resizing
            if inp.UserInputType ~= Enum.UserInputType.MouseButton1
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end

            rsz     = true
            rsStart = Vector2.new(inp.Position.X, inp.Position.Y)
            rfStart = MF.AbsoluteSize

            -- detect release via the same InputObject (works for both mouse & touch)
            local c; c = inp.Changed:Connect(function()
                if inp.UserInputState == Enum.UserInputState.End then
                    rsz = false
                    c:Disconnect()
                end
            end)
        end)

        UserInputService.InputChanged:Connect(function(inp)
            if not rsz then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement
            and inp.UserInputType ~= Enum.UserInputType.Touch then return end

            local cur  = Vector2.new(inp.Position.X, inp.Position.Y)
            local d    = cur - rsStart
            local vp   = workspace.CurrentCamera.ViewportSize
            local mpos = MF.AbsolutePosition   -- window anchor (top-left)

            -- clamp so window can't exceed viewport
            local newW = math.clamp(rfStart.X + d.X, 420, vp.X - mpos.X - 2)
            local newH = math.clamp(rfStart.Y + d.Y, 300, vp.Y - mpos.Y - 2)
            MF.Size    = UDim2.new(0, newW, 0, newH)
        end)
    end

    -- ============================================================
    --  PROFILE PANEL
    -- ============================================================
    local PROFILE_W  = 224
    local profOpen   = false

    local ProfilePanel = New("Frame",{
        Parent=MF, BackgroundColor3=T.BG_WIN,
        Size=UDim2.new(0,0,1,0),
        Position=UDim2.new(1,4,0,0),
        BorderSizePixel=0, ClipsDescendants=true, ZIndex=8,
        Visible=false})
    Corner(ProfilePanel,12)
    Stroke(ProfilePanel,1,T.BORDER_R,0.35)

    -- ─── Player Header ────────────────────────────────────────
    local ProfHdr=New("Frame",{Parent=ProfilePanel,BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,108), Position=UDim2.new(0,0,0,0),
        BorderSizePixel=0, ZIndex=9})
    Corner(ProfHdr,12)
    -- fill bottom corners
    New("Frame",{Parent=ProfHdr,BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),BorderSizePixel=0,ZIndex=8})
    New("Frame",{Parent=ProfHdr,BackgroundColor3=T.SEP,
        Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BorderSizePixel=0,ZIndex=9})

    -- avatar circle
    local AvatarFrame=New("Frame",{Parent=ProfHdr,BackgroundColor3=T.LOGO_BG,
        Size=UDim2.new(0,58,0,58),Position=UDim2.new(0.5,-29,0,8),
        BorderSizePixel=0,ZIndex=10})
    Corner(AvatarFrame,29)
    Stroke(AvatarFrame,2,T.RED)
    local AvatarImg=New("ImageLabel",{Parent=AvatarFrame,BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0),Image="",ZIndex=11})
    Corner(AvatarImg,29)

    local _lp = Players.LocalPlayer
    local ProfName=New("TextLabel",{Parent=ProfHdr,
        Text=_lp.DisplayName,Font=Enum.Font.GothamBold,TextSize=12,
        TextColor3=T.TXT_PRI,BackgroundTransparency=1,
        Size=UDim2.new(1,-12,0,16),Position=UDim2.new(0,6,0,70),
        TextXAlignment=Enum.TextXAlignment.Center,
        TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=10})
    local ProfDisp=New("TextLabel",{Parent=ProfHdr,
        Text="@".._lp.Name,Font=Enum.Font.Gotham,TextSize=10,
        TextColor3=T.TXT_MUTED,BackgroundTransparency=1,
        Size=UDim2.new(1,-12,0,14),Position=UDim2.new(0,6,0,86),
        TextXAlignment=Enum.TextXAlignment.Center,
        TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=10})

    -- async load avatar thumbnail
    task.spawn(function()
        local ok, url = pcall(function()
            return Players:GetUserThumbnailAsync(
                _lp.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size420x420)
        end)
        if ok and url then AvatarImg.Image = url end
    end)

    -- ─── Info Scroll (custom widgets area) ────────────────────
    local _socialH = (#_enabledSocials > 0) and (#_enabledSocials * 28 + 34) or 0
    local _credH   = (creator ~= "") and 40 or 0
    local _infoScrollH = -(116 + 10 + _socialH + _credH + 8)

    local InfoScroll=New("ScrollingFrame",{Parent=ProfilePanel,
        BackgroundTransparency=1,
        Size=UDim2.new(1,-12, 1, _infoScrollH),
        Position=UDim2.new(0,6, 0, 116),
        ScrollBarThickness=3,ScrollBarImageColor3=T.RED,
        BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=9})
    New("UIListLayout",{Parent=InfoScroll,
        FillDirection=Enum.FillDirection.Vertical,
        Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
    Pad(InfoScroll,4,4,0,0)

    -- ─── Social Links ──────────────────────────────────────────
    if #_enabledSocials > 0 then
        -- separator above socials
        local _sep1=New("Frame",{Parent=ProfilePanel,BackgroundColor3=T.SEP,
            Size=UDim2.new(1,-24,0,1),Position=UDim2.new(0,12,1,-(_credH+_socialH+4)),
            BorderSizePixel=0,ZIndex=9})

        local SocialFrame=New("Frame",{Parent=ProfilePanel,BackgroundTransparency=1,
            Size=UDim2.new(1,-12,0,_socialH),
            Position=UDim2.new(0,6,1,-(_credH+_socialH)),
            BorderSizePixel=0,ZIndex=9})
        New("UIListLayout",{Parent=SocialFrame,
            FillDirection=Enum.FillDirection.Vertical,
            Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})

        -- section label
        New("TextLabel",{Parent=SocialFrame,Text="CONTACT",
            Font=Enum.Font.GothamBold,TextSize=9,
            TextColor3=T.TXT_MUTED,BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,18),
            TextXAlignment=Enum.TextXAlignment.Left,
            ZIndex=10})
        Pad(SocialFrame,6,2,4,4)

        for _, s in ipairs(_enabledSocials) do
            local sRow=New("TextButton",{Parent=SocialFrame,Text="",
                BackgroundColor3=T.BG_CARD,
                Size=UDim2.new(1,0,0,26),
                BorderSizePixel=0,ZIndex=10,
                AutoButtonColor=false})
            Corner(sRow,5)

            -- icon badge
            local iBadge=New("Frame",{Parent=sRow,
                BackgroundColor3=s.col:Lerp(Color3.new(0,0,0),0.45),
                Size=UDim2.new(0,28,0,18),
                Position=UDim2.new(0,4,0.5,-9),
                BorderSizePixel=0,ZIndex=11})
            Corner(iBadge,4)
            New("TextLabel",{Parent=iBadge,Text=s.icon,
                Font=Enum.Font.GothamBold,TextSize=9,
                TextColor3=s.col,BackgroundTransparency=1,
                Size=UDim2.new(1,0,1,0),
                TextXAlignment=Enum.TextXAlignment.Center,
                ZIndex=12})

            -- url text
            New("TextLabel",{Parent=sRow,Text=s.url,
                Font=Enum.Font.Gotham,TextSize=10,
                TextColor3=T.TXT_PRI,BackgroundTransparency=1,
                Size=UDim2.new(1,-40,1,0),
                Position=UDim2.new(0,36,0,0),
                TextXAlignment=Enum.TextXAlignment.Left,
                TextTruncate=Enum.TextTruncate.AtEnd,
                ZIndex=11})

            -- hover + click to copy
            Hover(sRow, T.BG_CARD, T.BG_CARD_H)
            sRow.MouseButton1Click:Connect(function()
                pcall(function()
                    if setclipboard then
                        setclipboard(s.url)
                        ZENUHub:Notify({
                            Title="Copied!",
                            Message=s.key.." copied to clipboard",
                            Type="Success", Duration=2})
                    end
                end)
            end)
        end
    end

    -- ─── Credits ──────────────────────────────────────────────
    if creator ~= "" then
        New("Frame",{Parent=ProfilePanel,BackgroundColor3=T.SEP,
            Size=UDim2.new(1,-24,0,1),Position=UDim2.new(0,12,1,-(_credH)),
            BorderSizePixel=0,ZIndex=9})
        local CredFrame=New("Frame",{Parent=ProfilePanel,BackgroundColor3=T.BG_HEAD,
            Size=UDim2.new(1,0,0,_credH),Position=UDim2.new(0,0,1,-_credH),
            BorderSizePixel=0,ZIndex=9})
        Corner(CredFrame,12)
        New("Frame",{Parent=CredFrame,BackgroundColor3=T.BG_HEAD,
            Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,0,0),
            BorderSizePixel=0,ZIndex=8})
        New("TextLabel",{Parent=CredFrame,
            Text="Created by  "..creator,
            Font=Enum.Font.Gotham,TextSize=10,
            TextColor3=T.TXT_MUTED,BackgroundTransparency=1,
            Size=UDim2.new(1,-12,1,0),Position=UDim2.new(0,6,0,0),
            TextXAlignment=Enum.TextXAlignment.Center,
            TextWrapped=true,ZIndex=10})
    end

    -- ─── Toggle profile panel on Z click ──────────────────────
    LB.MouseButton1Click:Connect(function()
        profOpen = not profOpen
        if profOpen then
            ProfilePanel.Visible = true
            Tween(ProfilePanel,{Size=UDim2.new(0,PROFILE_W,1,0)},0.28,
                Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
            Tween(LB,{BackgroundColor3=T.RED_DIM},0.14)
        else
            Tween(ProfilePanel,{Size=UDim2.new(0,0,1,0)},0.22,
                Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
            Tween(LB,{BackgroundColor3=T.LOGO_BG},0.14)
            task.delay(0.25, function()
                if not profOpen then ProfilePanel.Visible = false end
            end)
        end
    end)
    LB.MouseEnter:Connect(function()
        if not profOpen then
            Tween(LB,{BackgroundColor3=T.LOGO_BG:Lerp(Color3.new(1,1,1),0.12)},0.1)
        end
    end)
    LB.MouseLeave:Connect(function()
        if not profOpen then Tween(LB,{BackgroundColor3=T.LOGO_BG},0.1) end
    end)


    local FG=New("ScreenGui",{Parent=CoreGui,
        Name="ZENUFloat_"..tostring(math.random(1000,9999)),
        ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true,Enabled=false})
    table.insert(ZENUHub._guiList, FG)
    local FB=New("TextButton",{Parent=FG,Text="",BackgroundColor3=T.LOGO_BG,
        Size=UDim2.new(0,58,0,58),Position=UDim2.new(0,18,0.5,-29),
        BorderSizePixel=0,ZIndex=50})
    Corner(FB,14); Stroke(FB,2,T.LOGO_BORDER)
    New("TextLabel",{Parent=FB,Text="Z",Font=Enum.Font.GothamBold,TextSize=30,
        TextColor3=T.RED,BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Center,TextYAlignment=Enum.TextYAlignment.Center,ZIndex=51})
    MakeDraggable(FB,FB)

    local pulseOn=false
    local function StartPulse()
        if pulseOn then return end; pulseOn=true
        task.spawn(function()
            while pulseOn do
                Tween(FB,{BackgroundColor3=Color3.fromRGB(22,12,12)},0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
                task.wait(0.95); if not pulseOn then break end
                Tween(FB,{BackgroundColor3=T.LOGO_BG},0.9,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
                task.wait(0.95)
            end; FB.BackgroundColor3=T.LOGO_BG
        end)
    end
    local function StopPulse() pulseOn=false end

    MF.Size=UDim2.new(0,sizeW,0,0); MF.BackgroundTransparency=0.9
    Spring(MF,{Size=UDim2.new(0,sizeW,0,sizeH),BackgroundTransparency=0},0.44)

    BtnX.MouseButton1Click:Connect(function()
        Tween(MF,{BackgroundTransparency=1},0.22)
        task.delay(0.25,function()
            -- ลบ GUI ทุกชิ้น: main window, float icon, watermark, notification
            for _, gui in ipairs(ZENUHub._guiList) do
                pcall(function() if gui and gui.Parent then gui:Destroy() end end)
            end
            ZENUHub._guiList = {}
            -- ลบ tooltip
            if _ttConn then pcall(function() _ttConn:Disconnect() end); _ttConn=nil end
            if _ttGui and _ttGui.Parent then
                pcall(function() _ttGui:Destroy() end)
                _ttGui=nil; _ttFrame=nil; _ttLbl=nil
            end
            -- ลบ notification holder (ScreenGui ของมัน)
            if NotifHolder and NotifHolder.Parent and NotifHolder.Parent.Parent then
                pcall(function() NotifHolder.Parent:Destroy() end); NotifHolder=nil
            end
            -- ตัด connections ทั้งหมด
            for _, conn in ipairs(ZENUHub._connections) do
                pcall(function() conn:Disconnect() end)
            end
            ZENUHub._connections = {}
            _notifActive = 0; _notifQueue = {}
        end)
    end)
    BtnM.MouseButton1Click:Connect(function()
        MF.Visible=false; FG.Enabled=true
        FB.Size=UDim2.new(0,0,0,0); Spring(FB,{Size=UDim2.new(0,58,0,58)},0.38); StartPulse()
    end)
    FB.MouseButton1Click:Connect(function()
        StopPulse(); FG.Enabled=false; MF.Visible=true
        MF.BackgroundTransparency=0.85; Spring(MF,{BackgroundTransparency=0},0.3)
    end)

    -- ============================================================
    --  WINDOW OBJECT
    -- ============================================================
    local Window={_tabs={},_activeTab=nil,_mainFrame=MF,_screenGui=SG}

    SI:GetPropertyChangedSignal("Text"):Connect(function()
        local q=SI.Text:lower():gsub("^%s+",""):gsub("%s+$","")
        for _,tab in pairs(Window._tabs) do
            for _,sub in pairs(tab._subtabs or {}) do
                for _,sec in pairs(sub._sections or {}) do
                    if q=="" then
                        if sec._card then sec._card.Visible=true end
                        for _,item in pairs(sec._items or {}) do
                            if item._frame then item._frame.Visible=true end
                        end
                    else
                        local hasMatch=false
                        for _,item in pairs(sec._items or {}) do
                            if item._frame then
                                local m=item._label and item._label:lower():find(q,1,true)~=nil
                                item._frame.Visible=m
                                if m then hasMatch=true end
                            end
                        end
                        if sec._card then
                            sec._card.Visible=hasMatch
                            if hasMatch and sec._itemsFrame then
                                sec._itemsFrame.Visible=true
                            end
                        end
                    end
                end
            end
        end
    end)

    -- ============================================================
    --  ADD TAB
    -- ============================================================
    function Window:AddTab(options)
        options=options or {}
        local tabName=options.Name or "Tab"
        local tabIcon=options.Icon or tabName:sub(1,2):upper()

        local IBtnFrame=New("TextButton",{Parent=SideList,Text="",
            BackgroundColor3=T.BG_SIDE,
            Size=UDim2.new(1,-10,0,56),
            BorderSizePixel=0,ZIndex=6,
            AutoButtonColor=false})
        Corner(IBtnFrame,8)

        local IIcon=New("TextLabel",{Parent=IBtnFrame,
            Text=tabIcon,
            Font=Enum.Font.GothamBold,TextSize=16,
            TextColor3=T.TXT_MUTED,
            BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,28),
            Position=UDim2.new(0,0,0,6),
            TextXAlignment=Enum.TextXAlignment.Center,
            TextYAlignment=Enum.TextYAlignment.Center,
            ZIndex=7})

        local IName=New("TextLabel",{Parent=IBtnFrame,
            Text=tabName,
            Font=Enum.Font.Gotham,TextSize=9,
            TextColor3=T.TXT_MUTED,
            BackgroundTransparency=1,
            Size=UDim2.new(1,-4,0,16),
            Position=UDim2.new(0,2,0,34),
            TextXAlignment=Enum.TextXAlignment.Center,
            TextTruncate=Enum.TextTruncate.AtEnd,
            ZIndex=7})

        local IBtn = IBtnFrame

        IBtn.MouseEnter:Connect(function()
            Tween(IIcon,{TextColor3=T.RED},0.14)
            Tween(IName,{TextColor3=T.RED},0.14)
        end)
        IBtn.MouseLeave:Connect(function()
            if Window._activeTab and Window._activeTab._btn == IBtn then return end
            Tween(IIcon,{TextColor3=T.TXT_MUTED},0.14)
            Tween(IName,{TextColor3=T.TXT_MUTED},0.14)
        end)

        local ActBar=New("Frame",{Parent=IBtn,BackgroundColor3=T.RED,
            Size=UDim2.new(0,3,0,30),Position=UDim2.new(0,0,0.5,-15),
            BorderSizePixel=0,Visible=false})
        Corner(ActBar,2)

        local TabPage=New("Frame",{Parent=Content,BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0),BorderSizePixel=0,Visible=false,
            ClipsDescendants=true})

        local SubBar=New("Frame",{Parent=TabPage,BackgroundColor3=T.BG_SUBBAR,
            Size=UDim2.new(1,0,0,SUB_BAR_H),Position=UDim2.new(0,0,0,0),
            BorderSizePixel=0})
        New("Frame",{Parent=SubBar,BackgroundColor3=T.SEP,
            Size=UDim2.new(1,0,0,1),Position=UDim2.new(0,0,1,-1),BorderSizePixel=0})

        local PillScroll=New("ScrollingFrame",{Parent=SubBar,
            BackgroundTransparency=1,
            Size=UDim2.new(1,-8,1,-8),Position=UDim2.new(0,4,0,4),
            ScrollBarThickness=0,ScrollingDirection=Enum.ScrollingDirection.X,
            BorderSizePixel=0,CanvasSize=UDim2.new(0,0,1,0),
            AutomaticCanvasSize=Enum.AutomaticSize.X})
        New("UIListLayout",{Parent=PillScroll,FillDirection=Enum.FillDirection.Horizontal,
            VerticalAlignment=Enum.VerticalAlignment.Center,
            Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
        Pad(PillScroll,0,0,4,4)

        local SubContent=New("Frame",{Parent=TabPage,BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,-SUB_BAR_H),
            Position=UDim2.new(0,0,0,SUB_BAR_H),
            BorderSizePixel=0,ClipsDescendants=true})

        local Tab={
            _name=tabName, _btn=IBtn, _page=TabPage,
            _bar=ActBar, _subtabs={}, _activeSubTab=nil,
            _iconLbl=IIcon, _nameLbl=IName,
        }

        local function SelectTab()
            if Window._activeTab then
                local prev=Window._activeTab
                prev._page.Visible=false
                prev._bar.Visible=false
                Tween(prev._btn,{BackgroundColor3=T.BG_SIDE},0.15)
                if prev._iconLbl then Tween(prev._iconLbl,{TextColor3=T.TXT_MUTED},0.15) end
                if prev._nameLbl then Tween(prev._nameLbl,{TextColor3=T.TXT_MUTED},0.15) end
            end
            TabPage.Visible=true
            ActBar.Visible=true
            Tween(IBtn,{BackgroundColor3=T.BG_CARD_H},0.15)
            Tween(IIcon,{TextColor3=T.RED},0.15)
            Tween(IName,{TextColor3=T.TXT_PRI},0.15)
            Window._activeTab=Tab
        end
        IBtn.MouseButton1Click:Connect(SelectTab)
        if #Window._tabs==0 or tabName==initTab then SelectTab() end
        table.insert(Window._tabs,Tab)

        -- ==========================================================
        --  ADD SUB-TAB
        -- ==========================================================
        function Tab:AddSubTab(options)
            options=options or {}
            local stName=options.Name or ("SubTab "..tostring(#Tab._subtabs+1))
            local isFirst=(#Tab._subtabs==0)

            local Pill=New("TextButton",{Parent=PillScroll,Text=stName,
                Font=Enum.Font.GothamBold,TextSize=11,
                TextColor3=isFirst and Color3.new(1,1,1) or T.TXT_MUTED,
                BackgroundColor3=isFirst and T.BG_SUBPILL_A or T.BG_SUBPILL,
                AutomaticSize=Enum.AutomaticSize.X,
                Size=UDim2.new(0,0,0.75,0),
                BorderSizePixel=0,ZIndex=6})
            Corner(Pill,6)
            Pad(Pill,0,0,12,12)

            local StPage=New("ScrollingFrame",{Parent=SubContent,
                BackgroundTransparency=1,Size=UDim2.new(1,0,1,0),
                BorderSizePixel=0,ScrollBarThickness=3,
                ScrollBarImageColor3=T.RED,
                CanvasSize=UDim2.new(0,0,0,0),
                AutomaticCanvasSize=Enum.AutomaticSize.Y,
                Visible=isFirst})
            New("UIListLayout",{Parent=StPage,FillDirection=Enum.FillDirection.Vertical,
                Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder})
            Pad(StPage,10,10,10,10)

            local SubTab={_name=stName,_pill=Pill,_page=StPage,_sections={}}

            local function SelectSubTab()
                if Tab._activeSubTab then
                    Tab._activeSubTab._page.Visible=false
                    Tween(Tab._activeSubTab._pill,
                        {BackgroundColor3=T.BG_SUBPILL,TextColor3=T.TXT_MUTED},0.18)
                end
                StPage.Visible=true
                Tween(Pill,{BackgroundColor3=T.BG_SUBPILL_A,TextColor3=Color3.new(1,1,1)},0.18)
                Tab._activeSubTab=SubTab
            end
            Pill.MouseButton1Click:Connect(SelectSubTab)
            if isFirst then Tab._activeSubTab=SubTab end
            table.insert(Tab._subtabs,SubTab)

            -- ──────────────────────────────────────────────────
            --  ADD SECTION (Updated Card Border Logic)
            -- ──────────────────────────────────────────────────
            function SubTab:AddSection(options)
                options=options or {}
                local secName  =options.Name      or "Section"
                local secIcon  =options.Icon      or nil
                local isOpened = true 
                if options.Collapsed ~= nil then isOpened = not options.Collapsed end
                if options.Opened ~= nil then isOpened = options.Opened end

                -- Card - เอา AutomaticSize ออกแล้วคำนวณขนาดเอง เพื่อให้ขอบหดตามแอนิเมชันเป๊ะๆ
                local Card=New("Frame",{Parent=StPage,BackgroundColor3=T.BG_CARD,
                    Size=UDim2.new(1,0,0,36), 
                    BorderSizePixel=0,ClipsDescendants=true})
                Corner(Card,10); Stroke(Card,1,T.BORDER)

                -- Card header (ความสูง 36)
                local CH=New("TextButton",{Parent=Card,Text="",
                    BackgroundColor3=isOpened and T.BG_CARD or T.BG_CARD_H,Size=UDim2.new(1,0,0,36),
                    BorderSizePixel=0,ZIndex=3})
                Corner(CH,10)
                local xOff=12
                if secIcon then
                    New("TextLabel",{Parent=CH,Text=secIcon,Font=Enum.Font.GothamBold,
                        TextSize=13,TextColor3=T.RED,BackgroundTransparency=1,
                        Size=UDim2.new(0,20,1,0),Position=UDim2.new(0,10,0,0),
                        TextXAlignment=Enum.TextXAlignment.Center,ZIndex=4})
                    xOff=34
                end
                New("TextLabel",{Parent=CH,Text=secName,Font=Enum.Font.GothamBold,
                    TextSize=12,TextColor3=T.TXT_PRI,BackgroundTransparency=1,
                    Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,xOff,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,ZIndex=4})
                local Chev=New("TextLabel",{Parent=CH,
                    Text=isOpened and "v" or ">",
                    Font=Enum.Font.GothamBold,TextSize=13,TextColor3=T.TXT_MUTED,
                    BackgroundTransparency=1,Size=UDim2.new(0,20,1,0),
                    Position=UDim2.new(1,-26,0,0),
                    TextXAlignment=Enum.TextXAlignment.Center,ZIndex=4})

                -- Animation Container Frame
                local Container = New("Frame",{Parent=Card, BackgroundTransparency=1,
                    Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,36),
                    ClipsDescendants=true, BorderSizePixel=0})

                -- Items frame (ด้านใน Container)
                local IF=New("Frame",{Parent=Container,BackgroundTransparency=1,
                    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                    BorderSizePixel=0})
                local UIList = New("UIListLayout",{Parent=IF,FillDirection=Enum.FillDirection.Vertical,
                    Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder})
                Pad(IF,4,8,10,10)

                -- ฟังก์ชันอัปเดตขนาด (ควบคุม Card ไปด้วย)
                local function UpdateSize(animate)
                    local innerH = IF.AbsoluteSize.Y
                    local targetH = isOpened and (36 + innerH) or 36
                    local contH = isOpened and innerH or 0

                    if animate then
                        Tween(Card, {Size=UDim2.new(1,0,0,targetH)}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                        Tween(Container, {Size=UDim2.new(1,0,0,contH)}, 0.25, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
                    else
                        Card.Size = UDim2.new(1,0,0,targetH)
                        Container.Size = UDim2.new(1,0,0,contH)
                    end
                end

                -- ให้ Card ขยับตามขนาดอัตโนมัติ (เช่นตอน Dropdown เปิด/ขยาย)
                IF:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
                    if isOpened then
                        local innerH = IF.AbsoluteSize.Y
                        -- ตั้งค่าขนาดโดยตรงเพื่อให้ลื่นไหลไปกับ Tween ของตัวลูกด้านใน
                        Card.Size = UDim2.new(1,0,0,36 + innerH)
                        Container.Size = UDim2.new(1,0,0,innerH)
                    end
                end)

                CH.MouseButton1Click:Connect(function()
                    isOpened = not isOpened
                    Chev.Text = isOpened and "v" or ">"
                    Tween(CH,{BackgroundColor3=isOpened and T.BG_CARD or T.BG_CARD_H},0.14)
                    UpdateSize(true)
                end)

                -- ตั้งค่าสถานะเริ่มต้น
                task.spawn(function()
                    task.wait() 
                    UpdateSize(false)
                end)

                local Section={_items={},_card=Card,_itemsFrame=IF}
                table.insert(SubTab._sections,Section)

                BuildSectionComponents(Section,IF)

                return Section
            end

            return SubTab
        end

        return Tab
    end

    -- ============================================================
    --  PROFILE PANEL API
    -- ============================================================

    --[[
        Window:AddProfileInfo(opts)
          opts.Text      string   — content (supports RichText)
          opts.Color     Color3   — text colour  (default TXT_SEC)
          opts.TextSize  number   — font size     (default 11)
          opts.Bold      bool     — use GothamBold instead of Gotham
        Returns the TextLabel instance.

        Window:AddProfileButton(opts)
          opts.Name      string   — button label
          opts.Icon      string   — optional ASCII icon prefix  "[>>]"
          opts.Callback  function — called on click
        Returns the TextButton instance.

        Window:SetCreatorName(name)  — update the credits label at runtime.
        Window:OpenProfile()   / Window:CloseProfile()  — programmatic control.
    --]]

    function Window:AddProfileInfo(o)
        o = o or {}
        local text  = o.Text     or ""
        local col   = o.Color    or T.TXT_SEC
        local tsz   = o.TextSize or 11
        local font  = (o.Bold) and Enum.Font.GothamBold or Enum.Font.Gotham

        local Lbl = New("TextLabel",{Parent=InfoScroll,
            Text=text, Font=font, TextSize=tsz,
            TextColor3=col, BackgroundTransparency=1,
            Size=UDim2.new(1,-8,0,0),
            AutomaticSize=Enum.AutomaticSize.Y,
            TextXAlignment=Enum.TextXAlignment.Left,
            TextWrapped=true, RichText=true,
            ZIndex=10})
        Pad(Lbl,3,3,4,4)
        return Lbl
    end

    function Window:AddProfileButton(o)
        o = o or {}
        local lbl  = o.Name     or "Button"
        local icon = o.Icon     or ""
        local cb   = o.Callback or function() end
        local displayText = (icon ~= "") and (icon.."  "..lbl) or lbl

        local Btn = New("TextButton",{Parent=InfoScroll,
            Text=displayText,
            Font=Enum.Font.GothamBold,TextSize=11,
            TextColor3=T.TXT_PRI,BackgroundColor3=T.RED_D,
            Size=UDim2.new(1,-8,0,28),
            BorderSizePixel=0, ZIndex=10})
        Corner(Btn,6)
        Ripple(Btn)
        Hover(Btn, T.RED_D, T.RED)
        Btn.MouseButton1Click:Connect(function() cb() end)
        return Btn
    end

    function Window:OpenProfile()
        profOpen = true
        ProfilePanel.Visible = true
        Tween(ProfilePanel,{Size=UDim2.new(0,PROFILE_W,1,0)},0.28,
            Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
        Tween(LB,{BackgroundColor3=T.RED_DIM},0.14)
    end
    function Window:CloseProfile()
        profOpen = false
        Tween(ProfilePanel,{Size=UDim2.new(0,0,1,0)},0.22,
            Enum.EasingStyle.Quint,Enum.EasingDirection.Out)
        Tween(LB,{BackgroundColor3=T.LOGO_BG},0.14)
        task.delay(0.25, function()
            if not profOpen then ProfilePanel.Visible = false end
        end)
    end

    -- ========================================================
    --  AddConfigSection  (plug-and-play Save/Load UI for Settings)
    -- ========================================================
    --[[
        Window:AddConfigSection(section)
          section  Section  — the section to add controls into

        องค์ประกอบ:
          • Textbox    : ชื่อไฟล์สำหรับ Save  (ว่าง = ใช้ Player ID)
          • [S] Save   : บันทึกค่าทั้งหมดลง Zenu_Config/<name>.json
          • Dropdown   : เลือกไฟล์สำหรับ Load  (ว่าง = ใช้ Player ID)
          • [L] Load   : โหลดจากไฟล์ที่เลือก
          • Auto Save  : เปิด = บันทึกอัตโนมัติทุกครั้งที่กด Save
                         state เก็บแยกใน Zenu_Config/Auto_Config.json
          • Auto Load  : เปิด = โหลดอัตโนมัติตอนเริ่ม
                         state เก็บแยกใน Zenu_Config/Auto_Config.json
    --]]
    function Window:AddConfigSection(section)
        -- โหลด state ของ auto toggles จาก Auto_Config
        local autoCfg       = ZENUHub:LoadAutoConfig()
        local autoSaveState = autoCfg.auto_save == true
        local autoLoadState = autoCfg.auto_load == true

        -- ── SAVE: Textbox ชื่อไฟล์ ───────────────────────────
        section:AddSeparator({Label="SAVE"})
        -- forward-declare เพื่อให้ closure ของ Save ใช้ได้
        local loadDDItem

        local saveNameItem = section:AddTextbox({
            Name="Save Filename",
            Default="",
            Placeholder="ชื่อไฟล์ (ว่าง = Player ID)",
            Tooltip="บันทึกไปที่ Zenu_Config/<ชื่อ>.json  ถ้าว่างใช้ Player ID เป็นชื่อ",
        })

        section:AddButton({
            Name="[S] Save Config",
            Tooltip="บันทึกค่าทุก Flag ลงไฟล์ที่กำหนด",
            Callback=function()
                local n = saveNameItem and saveNameItem.Value or ""
                ZENUHub:SaveConfig(n)
                -- ถ้า auto save เปิดอยู่ ให้อัปเดต dropdown ด้วย
                if autoSaveState and loadDDItem then
                    local fresh = ZENUHub:ListConfigs()
                    table.insert(fresh, 1, "Auto")
                    pcall(function() loadDDItem:SetItems(fresh) end)
                end
            end
        })

        -- ── LOAD: Dropdown เลือกไฟล์ ─────────────────────────
        section:AddSeparator({Label="LOAD"})
        local cfgFiles = ZENUHub:ListConfigs()
        table.insert(cfgFiles, 1, "Auto")   -- ตัวเลือกแรก = Auto (โหลดจาก UID)

        loadDDItem = section:AddDropdown({
            Name="Load Config File",
            Items=cfgFiles,
            Default="Auto",
            Tooltip="Auto = โหลดจาก <PlayerUID>.json  |  เลือกไฟล์ = โหลดไฟล์นั้น  |  ว่าง = ต้องเลือกไฟล์ก่อน",
        })

        -- helper: แปลง dropdown value เป็น filename จริงสำหรับ LoadConfig
        local function resolveLoad(silent)
            local v = loadDDItem and loadDDItem.Value or ""
            if v == "" then
                if not silent then
                    ZENUHub:Notify({Title="Load Config", Message="กรุณาเลือกไฟล์ก่อน", Type="Warn", Duration=2})
                end
                return nil
            end
            if v == "Auto" then
                return _cfgDefaultName()   -- UID ของผู้เล่น
            end
            return v
        end

        -- ปุ่ม Refresh รายชื่อไฟล์ใน Dropdown
        section:AddButton({
            Name="[↺] Refresh File List",
            Tooltip="สแกนไฟล์ใหม่ใน Zenu_Config/",
            Callback=function()
                local fresh = ZENUHub:ListConfigs()
                table.insert(fresh, 1, "Auto")
                loadDDItem:SetItems(fresh)
                ZENUHub:Notify({Title="File List", Message=#fresh-1 .." ไฟล์พบ", Type="Info", Duration=2})
            end
        })

        section:AddButton({
            Name="[L] Load Config",
            Tooltip="โหลดคอนฟิกจากไฟล์ที่เลือกใน Dropdown  (Auto = UID.json)",
            Callback=function()
                local n = resolveLoad(false)
                if n then ZENUHub:LoadConfig(n) end
            end
        })

        section:AddButton({
            Name="[X] Delete Config",
            Tooltip="ลบไฟล์ที่เลือกอยู่ใน Dropdown (ไม่สามารถกู้คืนได้)",
            Callback=function()
                local n = loadDDItem and loadDDItem.Value or ""
                if n == "" or n == "Auto" then
                    ZENUHub:Notify({Title="Delete", Message="กรุณาเลือกไฟล์ก่อน", Type="Warn", Duration=2})
                    return
                end
                local ok = ZENUHub:DeleteConfig(n)
                if ok then
                    -- Refresh dropdown after deletion
                    local fresh = ZENUHub:ListConfigs()
                    table.insert(fresh, 1, "Auto")
                    loadDDItem:SetItems(fresh)
                end
            end
        })

        -- ── AUTO SAVE / AUTO LOAD ─────────────────────────────
        section:AddSeparator({Label="AUTO"})

        section:AddToggle({
            Name="Auto Save",
            Default=autoSaveState,
            Tooltip="เปิด: บันทึกอัตโนมัติทุกครั้งที่กด Save  (state เก็บใน Auto_Config)",
            Callback=function(v)
                autoSaveState = v
                local d = ZENUHub:LoadAutoConfig()
                d.auto_save = v
                ZENUHub:SaveAutoConfig(d)
                if v then
                    local n = saveNameItem and saveNameItem.Value or ""
                    ZENUHub:SaveConfig(n)
                end
            end
        })

        section:AddToggle({
            Name="Auto Load",
            Default=autoLoadState,
            Tooltip="เปิด: โหลดคอนฟิกอัตโนมัติตอนเริ่มต้น  Auto = UID.json  (state เก็บใน Auto_Config)",
            Callback=function(v)
                autoLoadState = v
                local d = ZENUHub:LoadAutoConfig()
                d.auto_load = v
                ZENUHub:SaveAutoConfig(d)
                if v then
                    local n = resolveLoad(true)
                    if n then ZENUHub:LoadConfig(n) end
                end
            end
        })

        -- โหลดทันทีถ้า auto load เปิดอยู่
        if autoLoadState then
            task.defer(function()
                local n = resolveLoad(true)
                if n then ZENUHub:LoadConfig(n) end
            end)
        end
    end

    return Window
end

return ZENUHub
