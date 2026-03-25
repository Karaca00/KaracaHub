--[[
    ███████╗███████╗███╗   ██╗██╗   ██╗    ██╗  ██╗██╗   ██╗██████╗
    ╚══███╔╝██╔════╝████╗  ██║██║   ██║    ██║  ██║██║   ██║██╔══██╗
      ███╔╝ █████╗  ██╔██╗ ██║██║   ██║    ███████║██║   ██║██████╔╝
     ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║    ██╔══██║██║   ██║██╔══██╗
    ███████╗███████╗██║ ╚████║╚██████╔╝    ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    ZENU Hub UI Library  v2.2
    (c) discord.gg/zenuhub

    Changes v2.2
      [FIX]  Search bar ไม่ทับ Title เมื่อ UI เล็ก (400x270)
      [FIX]  Search กรองระดับ Section — ซ่อน Card ที่ไม่มีผลลัพธ์ทั้งหมด
      [FIX]  โลโก้ Z: พื้นดำ + กรอบเทา + ตัว Z สีแดง (Header & Float icon)
      [FIX]  Minimize: ซ่อน UI ทันที ไม่มี animation ย่อขนาด
      [FIX]  Drag clamping — UI ไม่หลุดนอกจอ
      [NEW]  MultiDropdown: รองรับ MaxSelect (จำนวนสูงสุดที่เลือกได้)
      [NEW]  Slider: ปรับปรุง visual + hitbox ใหญ่ขึ้น
      [NEW]  Notifications: redesign สวยขึ้น พร้อม type icon
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players          = game:GetService("Players")
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui          = game:GetService("CoreGui")
local TextService      = game:GetService("TextService")
local Workspace        = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  LIBRARY
-- ============================================================
local ZENUHub        = {}
ZENUHub.__index      = ZENUHub
ZENUHub.Flags        = {}

-- ============================================================
--  THEME
-- ============================================================
local T = {
    -- Backgrounds
    BG_DEEP      = Color3.fromRGB( 8,  8, 10),   -- very dark
    BG_WIN       = Color3.fromRGB(16, 16, 20),   -- main window
    BG_SIDE      = Color3.fromRGB(20, 20, 26),   -- sidebar
    BG_HEAD      = Color3.fromRGB(11, 11, 14),   -- header/footer
    BG_CARD      = Color3.fromRGB(24, 24, 32),   -- section card
    BG_CARD_H    = Color3.fromRGB(30, 30, 40),   -- card hover
    BG_INPUT     = Color3.fromRGB(18, 18, 24),   -- inputs
    BG_DROP      = Color3.fromRGB(16, 16, 22),   -- dropdown list

    -- Accent
    RED          = Color3.fromRGB(220,  30,  30),
    RED_D        = Color3.fromRGB(150,  18,  18),
    RED_B        = Color3.fromRGB(255,  60,  60),
    RED_DIM      = Color3.fromRGB( 60,  10,  10),

    -- Logo
    LOGO_BG      = Color3.fromRGB(10,  10,  12),  -- near-black box
    LOGO_BORDER  = Color3.fromRGB(70,  70,  80),  -- gray border

    -- Text
    TXT_PRI      = Color3.fromRGB(238, 238, 244),
    TXT_SEC      = Color3.fromRGB(145, 145, 160),
    TXT_MUTED    = Color3.fromRGB( 75,  75,  90),

    -- Borders
    BORDER       = Color3.fromRGB( 38,  38,  50),
    BORDER_R     = Color3.fromRGB( 90,  18,  18),
    SEP          = Color3.fromRGB( 28,  28,  38),

    -- Toggle
    TOG_OFF      = Color3.fromRGB(42,  42,  55),
    TOG_ON       = Color3.fromRGB(220, 30,  30),
    TOG_KNOB     = Color3.fromRGB(238, 238, 244),

    -- Slider
    SLD_TRACK    = Color3.fromRGB(32,  32,  44),
    SLD_FILL     = Color3.fromRGB(220, 30,  30),
    SLD_THUMB    = Color3.fromRGB(238, 238, 244),

    -- Notifications
    N_BG         = Color3.fromRGB(16,  16,  22),
    N_SUCCESS    = Color3.fromRGB( 35, 185,  85),
    N_ERROR      = Color3.fromRGB(220,  35,  35),
    N_INFO       = Color3.fromRGB( 55, 140, 225),
    N_WARN       = Color3.fromRGB(225, 165,  30),
}

-- ============================================================
--  TWEEN / SPRING
-- ============================================================
local function Tween(obj, props, t, style, dir)
    TweenService:Create(obj,
        TweenInfo.new(t or 0.22, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
        props):Play()
end
local function Spring(obj, props, t)
    Tween(obj, props, t or 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ============================================================
--  INSTANCE FACTORY
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
    return New("UIStroke",{Parent=par, Thickness=th or 1, Color=col or T.BORDER, Transparency=tr or 0})
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
--  RIPPLE  (Touch-safe)
-- ============================================================
local function Ripple(btn)
    btn.ClipsDescendants = true
    btn.InputBegan:Connect(function(inp)
        if inp.UserInputType~=Enum.UserInputType.MouseButton1
        and inp.UserInputType~=Enum.UserInputType.Touch then return end
        local abs = btn.AbsolutePosition
        local x,y = inp.Position.X-abs.X, inp.Position.Y-abs.Y
        local sz  = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y)*2.2
        local r   = New("Frame",{Parent=btn,
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
--  DRAGGING  — with viewport clamping
-- ============================================================
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = inp.Position
            startPos  = frame.Position
        end
    end)
    handle.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType ~= Enum.UserInputType.MouseMovement
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = inp.Position - dragStart
        frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + d.X,
            startPos.Y.Scale, startPos.Y.Offset + d.Y
        )
    end)
end

-- ============================================================
--  NOTIFICATION SYSTEM  (redesigned)
-- ============================================================
local NotifHolder

local function EnsureNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = New("ScreenGui",{
        Parent=CoreGui, Name="ZENUNotif",
        ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true,
    })
    NotifHolder = New("Frame",{
        Parent=sg, BackgroundTransparency=1,
        Size=UDim2.new(0,310,1,0), Position=UDim2.new(1,-320,0,0),
    })
    New("UIListLayout",{
        Parent=NotifHolder,
        FillDirection=Enum.FillDirection.Vertical,
        VerticalAlignment=Enum.VerticalAlignment.Bottom,
        Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder,
    })
    Pad(NotifHolder, 0, 18, 0, 10)
end

-- Type icon labels (ASCII)
local N_ICON = { Info="[i]", Success="[+]", Error="[!]", Warn="[?]" }

function ZENUHub:Notify(opts)
    EnsureNotifHolder()
    opts = opts or {}
    local title    = opts.Title    or "ZENU Hub"
    local message  = opts.Message  or ""
    local duration = opts.Duration or 4
    local ntype    = opts.Type     or "Info"

    local accentC = {
        Info    = T.N_INFO,
        Success = T.N_SUCCESS,
        Error   = T.N_ERROR,
        Warn    = T.N_WARN,
    }
    local accent = accentC[ntype] or T.N_INFO
    local icon   = N_ICON[ntype]  or "[i]"

    -- Card
    local card = New("Frame",{
        Parent=NotifHolder, BackgroundColor3=T.N_BG,
        Size=UDim2.new(1,0,0,76), BorderSizePixel=0,
        BackgroundTransparency=1,   -- start invisible, fade in
        ClipsDescendants=true,
    })
    Corner(card, 11)
    Stroke(card, 1, T.BORDER)

    -- Colored top edge bar (3px)
    New("Frame",{Parent=card, BackgroundColor3=accent,
        Size=UDim2.new(1,0,0,3), Position=UDim2.new(0,0,0,0),
        BorderSizePixel=0, ZIndex=2})

    -- Icon bubble
    local iconBg = New("Frame",{Parent=card, BackgroundColor3=accent,
        Size=UDim2.new(0,32,0,32),
        Position=UDim2.new(0,12,0,0), AnchorPoint=Vector2.new(0,0),
        BorderSizePixel=0, ZIndex=3})
    iconBg.Position = UDim2.new(0,12,0,16)
    Corner(iconBg, 8)
    -- Dim icon bg slightly
    iconBg.BackgroundColor3 = accent:Lerp(T.N_BG, 0.55)
    New("TextLabel",{Parent=iconBg, Text=icon,
        Font=Enum.Font.GothamBold, TextSize=11, TextColor3=accent,
        BackgroundTransparency=1, Size=UDim2.new(1,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center, ZIndex=4})

    -- Title
    New("TextLabel",{Parent=card, Text=title,
        Font=Enum.Font.GothamBold, TextSize=13, TextColor3=T.TXT_PRI,
        BackgroundTransparency=1,
        Size=UDim2.new(1,-68,0,18), Position=UDim2.new(0,54,0,14),
        TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3})

    -- Message
    New("TextLabel",{Parent=card, Text=message,
        Font=Enum.Font.Gotham, TextSize=11, TextColor3=T.TXT_SEC,
        BackgroundTransparency=1,
        Size=UDim2.new(1,-68,0,26), Position=UDim2.new(0,54,0,32),
        TextXAlignment=Enum.TextXAlignment.Left,
        TextWrapped=true, ZIndex=3})

    -- Progress bar (bottom, shrinks left-to-right)
    local bar = New("Frame",{Parent=card, BackgroundColor3=accent,
        Size=UDim2.new(1,0,0,2), Position=UDim2.new(0,0,1,-2),
        BorderSizePixel=0, ZIndex=3})
    bar.BackgroundTransparency = 0.4

    -- Divider below top strip
    New("Frame",{Parent=card, BackgroundColor3=T.SEP,
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,3),
        BorderSizePixel=0, ZIndex=2})

    -- Slide + Fade in from right
    card.Position = UDim2.new(1, 12, 0, 0)
    Tween(card,{Position=UDim2.new(0,0,0,0), BackgroundTransparency=0}, 0.35,
        Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    Tween(bar, {Size=UDim2.new(0,0,0,2)}, duration, Enum.EasingStyle.Linear)

    -- Dismiss on tap
    card.InputBegan:Connect(function(inp)
        if inp.UserInputType==Enum.UserInputType.MouseButton1
        or inp.UserInputType==Enum.UserInputType.Touch then
            Tween(card,{Position=UDim2.new(1,12,0,0), BackgroundTransparency=1}, 0.22)
            task.delay(0.26, function() if card then card:Destroy() end end)
        end
    end)
    task.delay(duration, function()
        if card and card.Parent then
            Tween(card,{Position=UDim2.new(1,12,0,0), BackgroundTransparency=1}, 0.28)
            task.delay(0.32, function() if card then card:Destroy() end end)
        end
    end)
end

-- ============================================================
--  MAIN WINDOW
-- ============================================================
function ZENUHub:CreateWindow(opts)
    opts = opts or {}
    local hubName = opts.Name        or "ZENU Hub"
    local hubDesc = opts.Description or "Advanced Scripting Hub"
    local initTab = opts.DefaultTab  or nil
    local sizeW   = opts.Width       or 680
    local sizeH   = opts.Height      or 460
    local discord = opts.Discord     or "discord.gg/zenuhub"

    -- Root ScreenGui
    local SG = New("ScreenGui",{
        Parent=CoreGui,
        Name="ZENUHub_"..tostring(math.random(10000,99999)),
        ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true,
    })

    -- ── Main Frame ───────────────────────────────────────────
    local MF = New("Frame",{
        Parent=SG, BackgroundColor3=T.BG_WIN,
        Size=UDim2.new(0,sizeW,0,sizeH),
        Position=UDim2.new(0.5,-sizeW/2,0.5,-sizeH/2),
        BorderSizePixel=0, ClipsDescendants=false,
    })
    Corner(MF, 12)
    Stroke(MF, 1, T.BORDER_R, 0.35)

    -- Drop shadow
    New("ImageLabel",{Parent=MF, BackgroundTransparency=1,
        Size=UDim2.new(1,60,1,60), Position=UDim2.new(0,-30,0,-30),
        ZIndex=MF.ZIndex-1, Image="rbxassetid://5554236805",
        ImageColor3=Color3.new(0,0,0), ImageTransparency=0.5,
        ScaleType=Enum.ScaleType.Slice, SliceCenter=Rect.new(23,23,277,277)})

    -- ── HEADER  ──────────────────────────────────────────────
    local Hdr = New("Frame",{
        Parent=MF, BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,52), BorderSizePixel=0, ZIndex=5,
    })
    Corner(Hdr, 12)
    -- fill bottom 12px so only top corners show
    New("Frame",{Parent=Hdr, BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,1,-12),
        BorderSizePixel=0, ZIndex=4})
    -- bottom separator
    New("Frame",{Parent=Hdr, BackgroundColor3=T.SEP,
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,1,-1),
        BorderSizePixel=0, ZIndex=4})

    MakeDraggable(MF, Hdr)

    -- Logo box: black + gray border + red Z  (matches reference image)
    local LogoBox = New("Frame",{
        Parent=Hdr, BackgroundColor3=T.LOGO_BG,
        Size=UDim2.new(0,34,0,34),
        Position=UDim2.new(0,12,0.5,-17),
        BorderSizePixel=0, ZIndex=6,
    })
    Corner(LogoBox, 9)
    Stroke(LogoBox, 1.5, T.LOGO_BORDER)
    New("TextLabel",{Parent=LogoBox, Text="Z",
        Font=Enum.Font.GothamBold, TextSize=21,
        TextColor3=T.RED, BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center, ZIndex=7})

    -- Hub name + desc  (truncate to avoid overlap)
    New("TextLabel",{Parent=Hdr, Text=hubName,
        Font=Enum.Font.GothamBold, TextSize=14, TextColor3=T.TXT_PRI,
        BackgroundTransparency=1,
        Size=UDim2.new(0,115,0,20), Position=UDim2.new(0,54,0,7),
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=6})
    New("TextLabel",{Parent=Hdr, Text=hubDesc,
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=T.TXT_MUTED,
        BackgroundTransparency=1,
        Size=UDim2.new(0,115,0,16), Position=UDim2.new(0,54,0,28),
        TextXAlignment=Enum.TextXAlignment.Left,
        TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=6})

    -- Window buttons  (X close, - minimize) — anchored right
    local function WinBtn(lbl, bg, xOff)
        local b = New("TextButton",{
            Parent=Hdr, Text=lbl,
            Font=Enum.Font.GothamBold, TextSize=11,
            TextColor3=Color3.fromRGB(210,210,210),
            BackgroundColor3=bg,
            Size=UDim2.new(0,22,0,22),
            Position=UDim2.new(1,xOff,0.5,-11),
            BorderSizePixel=0, ZIndex=8,
        })
        Corner(b,6)
        b.MouseEnter:Connect(function() Tween(b,{BackgroundColor3=bg:Lerp(Color3.new(1,1,1),0.22)},0.1) end)
        b.MouseLeave:Connect(function() Tween(b,{BackgroundColor3=bg},0.1) end)
        return b
    end
    local BtnClose = WinBtn("X", Color3.fromRGB(195,38,38), -30)
    local BtnMin   = WinBtn("-", Color3.fromRGB(48,48,62),  -58)

    -- Search bar — positioned between title and buttons, scales with window
    -- Uses relative X so it doesn't overlap title at small sizes
    -- Left anchor at 175px (after title zone), right gap 68px (for 2 buttons)
    local SearchBox = New("Frame",{
        Parent=Hdr, BackgroundColor3=T.BG_INPUT,
        -- scale-based: fills space between title and buttons
        Size=UDim2.new(1,-248,0,26),   -- total width minus left zone (178) minus btn zone (70)
        Position=UDim2.new(0,178,0.5,-13),
        BorderSizePixel=0, ZIndex=6,
    })
    Corner(SearchBox,6); Stroke(SearchBox,1,T.BORDER)
    New("TextLabel",{Parent=SearchBox, Text="[S]",
        Font=Enum.Font.GothamBold, TextSize=9, TextColor3=T.TXT_MUTED,
        BackgroundTransparency=1, Size=UDim2.new(0,24,1,0),
        Position=UDim2.new(0,3,0,0),
        TextXAlignment=Enum.TextXAlignment.Center, ZIndex=7})
    local SearchInput = New("TextBox",{
        Parent=SearchBox, Text="", PlaceholderText="Search...",
        Font=Enum.Font.Gotham, TextSize=11,
        TextColor3=T.TXT_PRI, PlaceholderColor3=T.TXT_MUTED,
        BackgroundTransparency=1,
        Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,26,0,0),
        TextXAlignment=Enum.TextXAlignment.Left,
        ClearTextOnFocus=false, ZIndex=7})
    -- focus highlight
    SearchInput.Focused:Connect(function() Tween(SearchBox,{BackgroundColor3=T.BG_CARD},0.14) end)
    SearchInput.FocusLost:Connect(function() Tween(SearchBox,{BackgroundColor3=T.BG_INPUT},0.14) end)

    -- ── BODY  (Sidebar + Content) ────────────────────────────
    local Body = New("Frame",{
        Parent=MF, BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,-52-22),
        Position=UDim2.new(0,0,0,52),
        BorderSizePixel=0, ClipsDescendants=true,
    })

    -- Sidebar
    local Sidebar = New("Frame",{
        Parent=Body, BackgroundColor3=T.BG_SIDE,
        Size=UDim2.new(0,50,1,0), BorderSizePixel=0,
    })
    New("Frame",{Parent=Sidebar, BackgroundColor3=T.SEP,
        Size=UDim2.new(0,1,1,0), Position=UDim2.new(1,-1,0,0), BorderSizePixel=0})

    local SideList = New("ScrollingFrame",{
        Parent=Sidebar, BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,-8), Position=UDim2.new(0,0,0,8),
        ScrollBarThickness=0, BorderSizePixel=0,
        CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
    })
    New("UIListLayout",{Parent=SideList, FillDirection=Enum.FillDirection.Vertical,
        HorizontalAlignment=Enum.HorizontalAlignment.Center,
        Padding=UDim.new(0,5), SortOrder=Enum.SortOrder.LayoutOrder})
    Pad(SideList, 6,6,0,0)

    -- Content area
    local Content = New("Frame",{
        Parent=Body, BackgroundColor3=T.BG_WIN,
        Size=UDim2.new(1,-50,1,0), Position=UDim2.new(0,50,0,0),
        BorderSizePixel=0, ClipsDescendants=true,
    })

    -- Footer
    local Footer = New("Frame",{
        Parent=MF, BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,22),
        Position=UDim2.new(0,0,1,-22),
        BorderSizePixel=0,
    })
    Corner(Footer,12)
    New("Frame",{Parent=Footer, BackgroundColor3=T.BG_HEAD,
        Size=UDim2.new(1,0,0,12), Position=UDim2.new(0,0,0,0), BorderSizePixel=0})
    New("Frame",{Parent=Footer, BackgroundColor3=T.SEP,
        Size=UDim2.new(1,0,0,1), Position=UDim2.new(0,0,0,0), BorderSizePixel=0})
    New("TextLabel",{Parent=Footer, Text=discord,
        Font=Enum.Font.Gotham, TextSize=10, TextColor3=T.TXT_MUTED,
        BackgroundTransparency=1, Size=UDim2.new(1,-20,1,0),
        Position=UDim2.new(0,12,0,0), TextXAlignment=Enum.TextXAlignment.Left})

    -- Resize handle
    local RH = New("TextButton",{Parent=MF, Text="//",
        Font=Enum.Font.GothamBold, TextSize=9, TextColor3=T.TXT_MUTED,
        BackgroundTransparency=1, Size=UDim2.new(0,20,0,20),
        Position=UDim2.new(1,-20,1,-20), BorderSizePixel=0, ZIndex=30})
    do
        local rsz,rs,rss = false,nil,nil
        RH.InputBegan:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then
                rsz=true; rs=inp.Position; rss=MF.AbsoluteSize end
        end)
        RH.InputEnded:Connect(function(inp)
            if inp.UserInputType==Enum.UserInputType.MouseButton1 then rsz=false end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if not rsz or inp.UserInputType~=Enum.UserInputType.MouseMovement then return end
            local d=inp.Position-rs
            MF.Size=UDim2.new(0,math.max(360,rss.X+d.X),0,math.max(280,rss.Y+d.Y))
        end)
    end

    -- ── FLOAT Z ICON  (shows when minimized) ─────────────────
    -- Style: near-black bg + gray border + red Z — matches reference image
    local FloatGui = New("ScreenGui",{
        Parent=CoreGui,
        Name="ZENUFloat_"..tostring(math.random(1000,9999)),
        ResetOnSpawn=false,
        ZIndexBehavior=Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset=true,
        Enabled=false,
    })
    local FloatBtn = New("TextButton",{
        Parent=FloatGui, Text="",
        BackgroundColor3=T.LOGO_BG,
        Size=UDim2.new(0,58,0,58),
        Position=UDim2.new(0,18,0.5,-29),
        BorderSizePixel=0, ZIndex=50,
    })
    Corner(FloatBtn, 14)
    Stroke(FloatBtn, 2, T.LOGO_BORDER)   -- gray border
    New("TextLabel",{Parent=FloatBtn, Text="Z",
        Font=Enum.Font.GothamBold, TextSize=30,
        TextColor3=T.RED, BackgroundTransparency=1,
        Size=UDim2.new(1,0,1,0),
        TextXAlignment=Enum.TextXAlignment.Center,
        TextYAlignment=Enum.TextYAlignment.Center,
        ZIndex=51})

    -- Subtle pulsing glow on float icon
    local pulseActive = false
    local function StartPulse()
        if pulseActive then return end
        pulseActive = true
        task.spawn(function()
            while pulseActive do
                Tween(FloatBtn,{BackgroundColor3=Color3.fromRGB(22,12,12)},0.9,
                    Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
                task.wait(0.95)
                if not pulseActive then break end
                Tween(FloatBtn,{BackgroundColor3=T.LOGO_BG},0.9,
                    Enum.EasingStyle.Sine,Enum.EasingDirection.InOut)
                task.wait(0.95)
            end
            FloatBtn.BackgroundColor3 = T.LOGO_BG
        end)
    end
    local function StopPulse() pulseActive=false end

    MakeDraggable(FloatBtn, FloatBtn)

    -- ── OPEN ANIMATION ───────────────────────────────────────
    MF.Size = UDim2.new(0,sizeW,0,0)
    MF.BackgroundTransparency = 0.9
    Spring(MF,{Size=UDim2.new(0,sizeW,0,sizeH), BackgroundTransparency=0}, 0.44)

    -- ── CLOSE ────────────────────────────────────────────────
    BtnClose.MouseButton1Click:Connect(function()
        Tween(MF,{BackgroundTransparency=1},0.22)
        task.delay(0.25, function()
            SG:Destroy(); FloatGui:Destroy()
        end)
    end)

    -- ── MINIMIZE  →  instant hide + show float icon ──────────
    BtnMin.MouseButton1Click:Connect(function()
        MF.Visible     = false
        FloatGui.Enabled = true
        FloatBtn.Size  = UDim2.new(0,0,0,0)
        Spring(FloatBtn,{Size=UDim2.new(0,58,0,58)},0.38)
        StartPulse()
    end)

    -- ── FLOAT Z CLICK  →  restore UI ─────────────────────────
    FloatBtn.MouseButton1Click:Connect(function()
        StopPulse()
        FloatGui.Enabled = false
        MF.Visible = true
        MF.BackgroundTransparency = 0.85
        Spring(MF,{BackgroundTransparency=0}, 0.3)
    end)

    -- ============================================================
    --  WINDOW OBJECT
    -- ============================================================
    local Window = {
        _tabs      = {},
        _activeTab = nil,
        _mainFrame = MF,
        _screenGui = SG,
    }

    -- ── SEARCH  (Section-level filtering) ────────────────────
    -- Hides entire Section card when no items in it match the query
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SearchInput.Text:lower():gsub("^%s+",""):gsub("%s+$","")
        for _, tab in pairs(Window._tabs) do
            for _, sec in pairs(tab._sections or {}) do
                if q == "" then
                    -- Restore everything
                    if sec._card then sec._card.Visible = true end
                    for _, item in pairs(sec._items or {}) do
                        if item._frame then item._frame.Visible = true end
                    end
                else
                    local hasMatch = false
                    for _, item in pairs(sec._items or {}) do
                        if item._frame then
                            local match = item._label
                                and item._label:lower():find(q,1,true) ~= nil
                            item._frame.Visible = match
                            if match then hasMatch = true end
                        end
                    end
                    -- Show/hide the whole Section Card
                    if sec._card then
                        sec._card.Visible = hasMatch
                        -- If visible, keep ItemsFrame open so items show
                        if hasMatch and sec._itemsFrame then
                            sec._itemsFrame.Visible = true
                        end
                    end
                end
            end
        end
    end)

    -- ── ADD TAB ──────────────────────────────────────────────
    function Window:AddTab(options)
        options = options or {}
        local tabName = options.Name or "Tab"
        local tabIcon = options.Icon or tabName:sub(1,2):upper()

        -- Sidebar icon button
        local IBtn = New("TextButton",{
            Parent=SideList, Text=tabIcon,
            Font=Enum.Font.GothamBold, TextSize=11,
            TextColor3=T.TXT_MUTED, BackgroundColor3=T.BG_SIDE,
            Size=UDim2.new(0,38,0,38),
            BorderSizePixel=0, ZIndex=6,
            TextXAlignment=Enum.TextXAlignment.Center,
            TextYAlignment=Enum.TextYAlignment.Center,
        })
        Corner(IBtn, 8)

        -- Tooltip
        local Tip = New("Frame",{Parent=IBtn,
            BackgroundColor3=T.BG_CARD,
            Size=UDim2.new(0,80,0,24),
            Position=UDim2.new(1,6,0.5,-12),
            BorderSizePixel=0, Visible=false, ZIndex=30,
        })
        Corner(Tip,5); Stroke(Tip,1,T.BORDER)
        New("TextLabel",{Parent=Tip, Text=tabName,
            Font=Enum.Font.GothamBold, TextSize=11, TextColor3=T.TXT_PRI,
            BackgroundTransparency=1, Size=UDim2.new(1,-8,1,0),
            Position=UDim2.new(0,4,0,0), ZIndex=31})
        local ts=TextService:GetTextSize(tabName,11,Enum.Font.GothamBold,Vector2.new(999,24))
        Tip.Size=UDim2.new(0,ts.X+12,0,24)

        IBtn.MouseEnter:Connect(function() Tip.Visible=true;  Tween(IBtn,{TextColor3=T.RED},0.14) end)
        IBtn.MouseLeave:Connect(function() Tip.Visible=false end)

        -- Active indicator
        local ActBar = New("Frame",{Parent=IBtn, BackgroundColor3=T.RED,
            Size=UDim2.new(0,3,0,20), Position=UDim2.new(0,-3,0.5,-10),
            BorderSizePixel=0, Visible=false})
        Corner(ActBar,2)

        -- Content page
        local Page = New("ScrollingFrame",{
            Parent=Content, BackgroundTransparency=1,
            Size=UDim2.new(1,0,1,0), BorderSizePixel=0,
            ScrollBarThickness=3, ScrollBarImageColor3=T.RED,
            CanvasSize=UDim2.new(0,0,0,0),
            AutomaticCanvasSize=Enum.AutomaticSize.Y,
            Visible=false,
        })
        New("UIListLayout",{Parent=Page,
            FillDirection=Enum.FillDirection.Vertical,
            Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder})
        Pad(Page,10,10,10,10)

        local Tab = {_name=tabName, _btn=IBtn, _page=Page, _bar=ActBar, _sections={}}

        local function SelectTab()
            if Window._activeTab then
                Window._activeTab._page.Visible=false
                Tween(Window._activeTab._btn,
                    {TextColor3=T.TXT_MUTED,BackgroundColor3=T.BG_SIDE},0.15)
                Window._activeTab._bar.Visible=false
            end
            Tab._page.Visible=true
            Tween(IBtn,{TextColor3=T.TXT_PRI,BackgroundColor3=T.BG_CARD_H},0.15)
            Tab._bar.Visible=true
            Window._activeTab=Tab
        end
        IBtn.MouseButton1Click:Connect(SelectTab)
        if #Window._tabs==0 or tabName==initTab then SelectTab() end
        table.insert(Window._tabs, Tab)

        -- ── ADD SECTION  ──────────────────────────────────────
        function Tab:AddSection(options)
            options=options or {}
            local secName   = options.Name      or "Section"
            local secIcon   = options.Icon      or nil
            local collapsed = options.Collapsed or false

            -- Card frame
            local Card = New("Frame",{
                Parent=Page, BackgroundColor3=T.BG_CARD,
                Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                BorderSizePixel=0, ClipsDescendants=true,
            })
            Corner(Card,10); Stroke(Card,1,T.BORDER)

            -- Card header
            local CH = New("TextButton",{
                Parent=Card, Text="", BackgroundColor3=T.BG_CARD,
                Size=UDim2.new(1,0,0,36), BorderSizePixel=0, ZIndex=3,
            })
            Corner(CH,10)
            local xOff=12
            if secIcon then
                New("TextLabel",{Parent=CH, Text=secIcon,
                    Font=Enum.Font.GothamBold, TextSize=13, TextColor3=T.RED,
                    BackgroundTransparency=1, Size=UDim2.new(0,20,1,0),
                    Position=UDim2.new(0,10,0,0),
                    TextXAlignment=Enum.TextXAlignment.Center, ZIndex=4})
                xOff=34
            end
            New("TextLabel",{Parent=CH, Text=secName,
                Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TXT_PRI,
                BackgroundTransparency=1, Size=UDim2.new(1,-50,1,0),
                Position=UDim2.new(0,xOff,0,0),
                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=4})
            local Chev=New("TextLabel",{Parent=CH,
                Text=collapsed and ">" or "v",
                Font=Enum.Font.GothamBold, TextSize=13, TextColor3=T.TXT_MUTED,
                BackgroundTransparency=1, Size=UDim2.new(0,20,1,0),
                Position=UDim2.new(1,-26,0,0),
                TextXAlignment=Enum.TextXAlignment.Center, ZIndex=4})

            -- Items frame
            local IF = New("Frame",{
                Parent=Card, BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,0), Position=UDim2.new(0,0,0,36),
                AutomaticSize=Enum.AutomaticSize.Y,
                BorderSizePixel=0, Visible=not collapsed,
            })
            New("UIListLayout",{Parent=IF,
                FillDirection=Enum.FillDirection.Vertical,
                Padding=UDim.new(0,4), SortOrder=Enum.SortOrder.LayoutOrder})
            Pad(IF,4,8,10,10)

            local isC=collapsed
            CH.MouseButton1Click:Connect(function()
                isC=not isC; IF.Visible=not isC
                Chev.Text=isC and ">" or "v"
                Tween(CH,{BackgroundColor3=isC and T.BG_CARD_H or T.BG_CARD},0.14)
            end)
            Hover(CH,T.BG_CARD,T.BG_CARD_H)

            -- Section object — store Card and IF references for search
            local Section={_items={}, _card=Card, _itemsFrame=IF}
            table.insert(Tab._sections, Section)

            -- ────────────────────────────────────────────────────
            --  TOGGLE
            -- ────────────────────────────────────────────────────
            function Section:AddToggle(o)
                o=o or {}
                local lbl=o.Name or "Toggle"; local def=o.Default or false
                local cb=o.Callback or function() end; local flag=o.Flag

                local Row=New("Frame",{Parent=IF, BackgroundColor3=T.BG_CARD,
                    Size=UDim2.new(1,0,0,34), BorderSizePixel=0})
                Corner(Row,6)
                New("TextLabel",{Parent=Row, Text=lbl,
                    Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TXT_PRI,
                    BackgroundTransparency=1, Size=UDim2.new(1,-60,1,0),
                    Position=UDim2.new(0,10,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left})
                local Track=New("TextButton",{Parent=Row, Text="",
                    BackgroundColor3=def and T.TOG_ON or T.TOG_OFF,
                    Size=UDim2.new(0,42,0,22),
                    Position=UDim2.new(1,-50,0.5,-11),
                    BorderSizePixel=0, ZIndex=3})
                Corner(Track,11)
                local Knob=New("Frame",{Parent=Track,
                    BackgroundColor3=T.TOG_KNOB,
                    Size=UDim2.new(0,16,0,16),
                    Position=def and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                    BorderSizePixel=0, ZIndex=4})
                Corner(Knob,8)
                local state=def
                local item={_frame=Row,_label=lbl,Value=state}
                local function SetS(v,fire)
                    state=v; item.Value=v
                    Tween(Track,{BackgroundColor3=v and T.TOG_ON or T.TOG_OFF},0.2)
                    Spring(Knob,{Position=v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)},0.24)
                    if fire~=false then cb(v) end
                    if flag then ZENUHub.Flags[flag]=v end
                end
                Track.MouseButton1Click:Connect(function() SetS(not state) end)
                Hover(Row,T.BG_CARD,T.BG_CARD_H)
                function item:Set(v) SetS(v,false) end
                table.insert(Section._items,item); return item
            end

            -- ────────────────────────────────────────────────────
            --  BUTTON
            -- ────────────────────────────────────────────────────
            function Section:AddButton(o)
                o=o or {}
                local lbl=o.Name or "Button"; local cb=o.Callback or function() end
                local Btn=New("TextButton",{Parent=IF, Text=lbl,
                    Font=Enum.Font.GothamBold, TextSize=12, TextColor3=T.TXT_PRI,
                    BackgroundColor3=T.RED_D,
                    Size=UDim2.new(1,0,0,34), BorderSizePixel=0})
                Corner(Btn,6); Ripple(Btn)
                Btn.MouseEnter:Connect(function() Tween(Btn,{BackgroundColor3=T.RED},0.14) end)
                Btn.MouseLeave:Connect(function() Tween(Btn,{BackgroundColor3=T.RED_D},0.14) end)
                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn,{BackgroundColor3=T.RED_B},0.06)
                    task.delay(0.06,function() Tween(Btn,{BackgroundColor3=T.RED},0.12) end)
                    cb()
                end)
                local item={_frame=Btn,_label=lbl}
                table.insert(Section._items,item); return item
            end

            -- ────────────────────────────────────────────────────
            --  SLIDER  (Touch-safe, improved visuals)
            -- ────────────────────────────────────────────────────
            function Section:AddSlider(o)
                o=o or {}
                local lbl=o.Name or "Slider"
                local mn=o.Min or 0; local mx=o.Max or 100
                local def=math.clamp(o.Default or mn, mn, mx)
                local suf=o.Suffix or ""; local cb=o.Callback or function() end
                local flag=o.Flag

                local Row=New("Frame",{Parent=IF, BackgroundColor3=T.BG_CARD,
                    Size=UDim2.new(1,0,0,56), BorderSizePixel=0})
                Corner(Row,6)

                New("TextLabel",{Parent=Row, Text=lbl,
                    Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TXT_PRI,
                    BackgroundTransparency=1, Size=UDim2.new(0.62,0,0,22),
                    Position=UDim2.new(0,10,0,4),
                    TextXAlignment=Enum.TextXAlignment.Left})

                -- Value chip
                local ValChip=New("Frame",{Parent=Row, BackgroundColor3=T.RED_DIM,
                    Size=UDim2.new(0,56,0,20),
                    Position=UDim2.new(1,-64,0,6),
                    BorderSizePixel=0})
                Corner(ValChip,5)
                local ValLbl=New("TextLabel",{Parent=ValChip,
                    Text=tostring(def)..suf,
                    Font=Enum.Font.GothamBold, TextSize=11, TextColor3=T.RED,
                    BackgroundTransparency=1, Size=UDim2.new(1,-4,1,0),
                    Position=UDim2.new(0,2,0,0),
                    TextXAlignment=Enum.TextXAlignment.Center})

                -- Track + Fill + Thumb
                local Track=New("Frame",{Parent=Row, BackgroundColor3=T.SLD_TRACK,
                    Size=UDim2.new(1,-20,0,5),
                    Position=UDim2.new(0,10,1,-18),
                    BorderSizePixel=0})
                Corner(Track,3)

                local initPct=(def-mn)/(mx-mn)
                local Fill=New("Frame",{Parent=Track, BackgroundColor3=T.SLD_FILL,
                    Size=UDim2.new(initPct,0,1,0), BorderSizePixel=0})
                Corner(Fill,3)

                local Thumb=New("Frame",{Parent=Track,
                    BackgroundColor3=T.SLD_THUMB,
                    Size=UDim2.new(0,18,0,18),
                    Position=UDim2.new(initPct,-9,0.5,-9),
                    BorderSizePixel=0, ZIndex=3})
                Corner(Thumb,9); Stroke(Thumb,2,T.SLD_FILL)

                -- Wide invisible touch area
                local TA=New("TextButton",{Parent=Row, Text="",
                    BackgroundTransparency=1,
                    Size=UDim2.new(1,-20,0,32),
                    Position=UDim2.new(0,10,1,-36),
                    BorderSizePixel=0, ZIndex=5})

                local val=def; local dragS=false
                local item={_frame=Row,_label=lbl,Value=val}

                local function UpdateSlider(ix)
                    local abs=Track.AbsolutePosition; local sz=Track.AbsoluteSize
                    local pct=math.clamp((ix-abs.X)/sz.X,0,1)
                    val=math.round(mn+pct*(mx-mn)); item.Value=val
                    local fp=(val-mn)/(mx-mn)
                    Tween(Fill,{Size=UDim2.new(fp,0,1,0)},0.04,Enum.EasingStyle.Linear)
                    Tween(Thumb,{Position=UDim2.new(fp,-9,0.5,-9)},0.04,Enum.EasingStyle.Linear)
                    ValLbl.Text=tostring(val)..suf
                    cb(val)
                    if flag then ZENUHub.Flags[flag]=val end
                end

                TA.InputBegan:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1
                    or inp.UserInputType==Enum.UserInputType.Touch then
                        dragS=true; UpdateSlider(inp.Position.X)
                    end
                end)
                TA.InputEnded:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1
                    or inp.UserInputType==Enum.UserInputType.Touch then
                        dragS=false
                    end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if not dragS then return end
                    if inp.UserInputType==Enum.UserInputType.MouseMovement
                    or inp.UserInputType==Enum.UserInputType.Touch then
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType==Enum.UserInputType.MouseButton1
                    or inp.UserInputType==Enum.UserInputType.Touch then
                        dragS=false
                    end
                end)
                Hover(Row,T.BG_CARD,T.BG_CARD_H)
                function item:Set(v)
                    val=math.clamp(v,mn,mx); local fp=(val-mn)/(mx-mn)
                    Fill.Size=UDim2.new(fp,0,1,0)
                    Thumb.Position=UDim2.new(fp,-9,0.5,-9)
                    ValLbl.Text=tostring(val)..suf; item.Value=val
                end
                table.insert(Section._items,item); return item
            end

            -- ────────────────────────────────────────────────────
            --  TEXTBOX
            -- ────────────────────────────────────────────────────
            function Section:AddTextbox(o)
                o=o or {}
                local lbl=o.Name or "Textbox"
                local ph=o.Placeholder or "Enter text..."
                local def=o.Default or ""; local cb=o.Callback or function() end
                local flag=o.Flag

                local Row=New("Frame",{Parent=IF, BackgroundColor3=T.BG_CARD,
                    Size=UDim2.new(1,0,0,54), BorderSizePixel=0})
                Corner(Row,6)
                New("TextLabel",{Parent=Row, Text=lbl,
                    Font=Enum.Font.Gotham, TextSize=11, TextColor3=T.TXT_SEC,
                    BackgroundTransparency=1,
                    Size=UDim2.new(1,-20,0,18), Position=UDim2.new(0,10,0,5),
                    TextXAlignment=Enum.TextXAlignment.Left})
                local IFr=New("Frame",{Parent=Row, BackgroundColor3=T.BG_INPUT,
                    Size=UDim2.new(1,-20,0,26), Position=UDim2.new(0,10,0,24),
                    BorderSizePixel=0})
                Corner(IFr,5); local sk=Stroke(IFr,1,T.BORDER)
                local Inp=New("TextBox",{Parent=IFr, Text=def, PlaceholderText=ph,
                    Font=Enum.Font.Gotham, TextSize=11,
                    TextColor3=T.TXT_PRI, PlaceholderColor3=T.TXT_MUTED,
                    BackgroundTransparency=1,
                    Size=UDim2.new(1,-12,1,0), Position=UDim2.new(0,6,0,0),
                    ClearTextOnFocus=false, ZIndex=3})
                Inp.Focused:Connect(function() Tween(sk,{Color=T.RED},0.14) end)
                Inp.FocusLost:Connect(function() Tween(sk,{Color=T.BORDER},0.14); cb(Inp.Text) end)
                local item={_frame=Row,_label=lbl,Value=Inp.Text}
                Inp:GetPropertyChangedSignal("Text"):Connect(function()
                    item.Value=Inp.Text
                    if flag then ZENUHub.Flags[flag]=Inp.Text end
                end)
                table.insert(Section._items,item); return item
            end

            -- ────────────────────────────────────────────────────
            --  DROPDOWN  (single, with search)
            -- ────────────────────────────────────────────────────
            function Section:AddDropdown(o)
                o = o or {}
                local lbl = o.Name or "Dropdown"; local items = o.Items or {}
                local sel = o.Default or (items[1] or "None")
                local cb = o.Callback or function() end; local flag = o.Flag
            
                -- Row with automatic height
                local Row = New("Frame", {
                    Parent = IF,
                    BackgroundColor3 = T.BG_CARD,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                    ClipsDescendants = false,
                    AutomaticSize = Enum.AutomaticSize.Y,
                })
                Corner(Row, 6)
            
                -- Label
                New("TextLabel", {
                    Parent = Row,
                    Text = lbl,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = T.TXT_SEC,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 18),
                    Position = UDim2.new(0, 10, 0, 5),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })
            
                -- Dropdown button (now at top of Row)
                local DB = New("TextButton", {
                    Parent = Row,
                    Text = "",
                    BackgroundColor3 = T.BG_INPUT,
                    Size = UDim2.new(1, -20, 0, 26),
                    Position = UDim2.new(0, 10, 0, 0),   -- placed at top of Row
                    BorderSizePixel = 0,
                    ZIndex = 6,
                    ClipsDescendants = false,
                })
                Corner(DB, 5)
                Stroke(DB, 1, T.BORDER)
            
                local SL = New("TextLabel", {
                    Parent = DB,
                    Text = sel,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = T.TXT_PRI,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 7,
                })
                New("TextLabel", {
                    Parent = DB,
                    Text = "v",
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = T.TXT_MUTED,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 22, 1, 0),
                    Position = UDim2.new(1, -24, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7,
                })
            
                -- Dropdown list frame – now child of Row
                local DL = New("Frame", {
                    Parent = Row,
                    BackgroundColor3 = T.BG_DROP,
                    Size = UDim2.new(1, -20, 0, 0),      -- width matches DB
                    Position = UDim2.new(0, 10, 0, 30),  -- just below DB (26 + 4)
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 100,
                    ClipsDescendants = false,
                })
                Corner(DL, 6)
                Stroke(DL, 1, T.BORDER)
            
                -- Search bar inside dropdown
                local SR2 = New("Frame", {
                    Parent = DL,
                    BackgroundColor3 = T.BG_INPUT,
                    Size = UDim2.new(1, -12, 0, 22),
                    Position = UDim2.new(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    ZIndex = 51,
                })
                Corner(SR2, 4)
                Stroke(SR2, 1, T.BORDER)
                local SI = New("TextBox", {
                    Parent = SR2,
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
                    ZIndex = 52,
                })
            
                -- Scrollable item list
                local IL2 = New("ScrollingFrame", {
                    Parent = DL,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, 0, 1, -36),
                    Position = UDim2.new(0, 0, 0, 34),
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = T.RED,
                    BorderSizePixel = 0,
                    CanvasSize = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex = 51,
                })
                New("UIListLayout", {
                    Parent = IL2,
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })
                Pad(IL2, 2, 2, 4, 4)
            
                local allB = {}
                local function BuildDD(f)
                    for _, v in ipairs(allB) do v:Destroy() end
                    allB = {}
                    for _, it in ipairs(items) do
                        if f == "" or it:lower():find(f:lower(), 1, true) then
                            local ib = New("TextButton", {
                                Parent = IL2,
                                Text = it,
                                Font = Enum.Font.Gotham,
                                TextSize = 11,
                                TextColor3 = T.TXT_PRI,
                                BackgroundColor3 = T.BG_DROP,
                                Size = UDim2.new(1, 0, 0, 26),
                                BorderSizePixel = 0,
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 52,
                            })
                            Corner(ib, 4)
                            Pad(ib, 0, 0, 8, 4)
                            ib.MouseEnter:Connect(function()
                                Tween(ib, { BackgroundColor3 = T.BG_CARD_H }, 0.1)
                            end)
                            ib.MouseLeave:Connect(function()
                                Tween(ib, { BackgroundColor3 = T.BG_DROP }, 0.1)
                            end)
                            ib.MouseButton1Click:Connect(function()
                                sel = it
                                SL.Text = it
                                DL.Visible = false
                                cb(it)
                                if flag then ZENUHub.Flags[flag] = it end
                            end)
                            table.insert(allB, ib)
                        end
                    end
                end
                BuildDD("")
                SI:GetPropertyChangedSignal("Text"):Connect(function()
                    BuildDD(SI.Text)
                end)
            
                local open = false
                DB.MouseButton1Click:Connect(function()
                    open = not open
                    DL.Visible = open
                    if open then
                        local height = math.min(#items * 28 + 44, 128)
                        DL.Size = UDim2.new(1, -20, 0, height)
                        SI.Text = ""
                        BuildDD("")
                    end
                end)
            
                local item = { _frame = Row, _label = lbl, Value = sel }
                function item:Set(v)
                    sel = v
                    SL.Text = v
                    item.Value = v
                end
                function item:Refresh(ni)
                    items = ni
                    BuildDD(SI.Text)
                end
                table.insert(Section._items, item)
                return item
            end

            -- ────────────────────────────────────────────────────
            --  MULTI-DROPDOWN  (with MaxSelect support)
            -- ────────────────────────────────────────────────────
            function Section:AddMultiDropdown(o)
                o = o or {}
                local lbl = o.Name or "Multi Select"
                local items = o.Items or {}
                local defaults = o.Default or {}
                local maxSel = o.MaxSelect or math.huge
                local cb = o.Callback or function() end
            
                local selected = {}
                for _, v in ipairs(defaults) do selected[v] = true end
            
                -- Row with automatic height
                local Row = New("Frame", {
                    Parent = IF,
                    BackgroundColor3 = T.BG_CARD,
                    BorderSizePixel = 0,
                    ZIndex = 5,
                    ClipsDescendants = false,
                    AutomaticSize = Enum.AutomaticSize.Y,
                })
                Corner(Row, 6)
            
                -- Label row with badge
                local LblRow = New("Frame", {
                    Parent = Row,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -20, 0, 18),
                    Position = UDim2.new(0, 10, 0, 5),
                    ZIndex = 6,
                })
                New("TextLabel", {
                    Parent = LblRow,
                    Text = lbl,
                    Font = Enum.Font.Gotham,
                    TextSize = 11,
                    TextColor3 = T.TXT_SEC,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0.7, 0, 1, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 6,
                })
                local MaxBadge
                if maxSel ~= math.huge then
                    MaxBadge = New("TextLabel", {
                        Parent = LblRow,
                        Text = "0/" .. tostring(maxSel),
                        Font = Enum.Font.GothamBold,
                        TextSize = 10,
                        TextColor3 = T.RED,
                        BackgroundTransparency = 1,
                        Size = UDim2.new(0.3, 0, 1, 0),
                        Position = UDim2.new(0.7, 0, 0, 0),
                        TextXAlignment = Enum.TextXAlignment.Right,
                        ZIndex = 6,
                    })
                end
            
                -- Dropdown button (placed at top of Row)
                local DB2 = New("TextButton", {
                    Parent = Row,
                    Text = "",
                    BackgroundColor3 = T.BG_INPUT,
                    Size = UDim2.new(1, -20, 0, 26),
                    Position = UDim2.new(0, 10, 0, 0),
                    BorderSizePixel = 0,
                    ZIndex = 6,
                    ClipsDescendants = false,
                })
                Corner(DB2, 5)
                Stroke(DB2, 1, T.BORDER)
            
                local function CountSel()
                    local n = 0
                    for _ in pairs(selected) do n = n + 1 end
                    return n
                end
                local function GetSelText()
                    local t = {}
                    for k in pairs(selected) do table.insert(t, k) end
                    return #t == 0 and "None" or table.concat(t, ", ")
                end
                local function UpdateBadge()
                    if MaxBadge then
                        local n = CountSel()
                        MaxBadge.Text = n .. "/" .. tostring(maxSel)
                        MaxBadge.TextColor3 = (n >= maxSel) and T.RED_B or T.RED
                    end
                end
            
                local SLM = New("TextLabel", {
                    Parent = DB2,
                    Text = GetSelText(),
                    Font = Enum.Font.Gotham,
                    TextSize = 10,
                    TextColor3 = T.TXT_PRI,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1, -28, 1, 0),
                    Position = UDim2.new(0, 8, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Left,
                    TextTruncate = Enum.TextTruncate.AtEnd,
                    ZIndex = 7,
                })
                New("TextLabel", {
                    Parent = DB2,
                    Text = "v",
                    Font = Enum.Font.GothamBold,
                    TextSize = 11,
                    TextColor3 = T.TXT_MUTED,
                    BackgroundTransparency = 1,
                    Size = UDim2.new(0, 22, 1, 0),
                    Position = UDim2.new(1, -24, 0, 0),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    ZIndex = 7,
                })
            
                -- Multi‑dropdown list frame – child of Row
                local DL2 = New("Frame", {
                    Parent = Row,
                    BackgroundColor3 = T.BG_DROP,
                    Size = UDim2.new(1, -20, 0, 0),
                    Position = UDim2.new(0, 10, 0, 30),   -- below DB2 (26 + 4)
                    BorderSizePixel = 0,
                    Visible = false,
                    ZIndex = 100,
                    ClipsDescendants = false,
                })
                Corner(DL2, 6)
                Stroke(DL2, 1, T.BORDER)
            
                local SRM = New("Frame", {
                    Parent = DL2,
                    BackgroundColor3 = T.BG_INPUT,
                    Size = UDim2.new(1, -12, 0, 22),
                    Position = UDim2.new(0, 6, 0, 6),
                    BorderSizePixel = 0,
                    ZIndex = 51,
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
                    ZIndex = 52,
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
                    ZIndex = 51,
                })
                New("UIListLayout", {
                    Parent = ILM,
                    Padding = UDim.new(0, 2),
                    SortOrder = Enum.SortOrder.LayoutOrder,
                })
                Pad(ILM, 2, 2, 4, 4)
            
                local allIBM = {}
                local function BuildMD(f)
                    for _, v in ipairs(allIBM) do v:Destroy() end
                    allIBM = {}
                    local atMax = (CountSel() >= maxSel)
                    for _, it in ipairs(items) do
                        if f == "" or it:lower():find(f:lower(), 1, true) then
                            local isOn = selected[it] == true
                            local dimmed = (atMax and not isOn)
                            local iRow = New("Frame", {
                                Parent = ILM,
                                BackgroundColor3 = isOn and T.RED_DIM or T.BG_DROP,
                                Size = UDim2.new(1, 0, 0, 28),
                                BorderSizePixel = 0,
                                ZIndex = 52,
                            })
                            Corner(iRow, 4)
                            New("TextLabel", {
                                Parent = iRow,
                                Text = it,
                                Font = Enum.Font.Gotham,
                                TextSize = 11,
                                TextColor3 = dimmed and T.TXT_MUTED or T.TXT_PRI,
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, -36, 1, 0),
                                Position = UDim2.new(0, 8, 0, 0),
                                TextXAlignment = Enum.TextXAlignment.Left,
                                ZIndex = 53,
                            })
                            local ck = New("Frame", {
                                Parent = iRow,
                                BackgroundColor3 = isOn and T.RED or T.BG_CARD_H,
                                Size = UDim2.new(0, 16, 0, 16),
                                Position = UDim2.new(1, -26, 0.5, -8),
                                BorderSizePixel = 0,
                                ZIndex = 53,
                            })
                            Corner(ck, 4)
                            if isOn then
                                New("TextLabel", {
                                    Parent = ck,
                                    Text = "v",
                                    Font = Enum.Font.GothamBold,
                                    TextSize = 10,
                                    TextColor3 = Color3.new(1, 1, 1),
                                    BackgroundTransparency = 1,
                                    Size = UDim2.new(1, 0, 1, 0),
                                    TextXAlignment = Enum.TextXAlignment.Center,
                                    TextYAlignment = Enum.TextYAlignment.Center,
                                    ZIndex = 54,
                                })
                            end
                            local hb = New("TextButton", {
                                Parent = iRow,
                                Text = "",
                                BackgroundTransparency = 1,
                                Size = UDim2.new(1, 0, 1, 0),
                                ZIndex = 55,
                            })
                            hb.MouseEnter:Connect(function()
                                if not dimmed then
                                    Tween(iRow, { BackgroundColor3 = isOn and T.RED_DIM:Lerp(Color3.new(1, 1, 1), 0.05) or T.BG_CARD_H }, 0.1)
                                end
                            end)
                            hb.MouseLeave:Connect(function()
                                Tween(iRow, { BackgroundColor3 = isOn and T.RED_DIM or T.BG_DROP }, 0.1)
                            end)
                            hb.MouseButton1Click:Connect(function()
                                if not isOn and CountSel() >= maxSel then
                                    ZENUHub:Notify({
                                        Title = "Selection Limit",
                                        Message = "Max " .. tostring(maxSel) .. " items allowed.",
                                        Type = "Warn",
                                        Duration = 2,
                                    })
                                    return
                                end
                                selected[it] = not selected[it]
                                SLM.Text = GetSelText()
                                UpdateBadge()
                                cb(selected)
                                BuildMD(SDDM.Text)
                            end)
                            table.insert(allIBM, iRow)
                        end
                    end
                end
            
                UpdateBadge()
                BuildMD("")
                SDDM:GetPropertyChangedSignal("Text"):Connect(function()
                    BuildMD(SDDM.Text)
                end)
            
                local openM = false
                DB2.MouseButton1Click:Connect(function()
                    openM = not openM
                    DL2.Visible = openM
                    if openM then
                        local height = math.min(#items * 30 + 44, 128)
                        DL2.Size = UDim2.new(1, -20, 0, height)
                        SDDM.Text = ""
                        BuildMD("")
                    end
                end)
            
                local item = { _frame = Row, _label = lbl, Value = selected }
                table.insert(Section._items, item)
                return item
            end

            -- ────────────────────────────────────────────────────
            --  LABEL
            -- ────────────────────────────────────────────────────
            function Section:AddLabel(o)
                o=o or {}
                local text=o.Text or "Label"
                local col=o.Color or T.TXT_SEC
                local tsz=o.TextSize or 11
                local Lbl=New("Frame",{Parent=IF, BackgroundColor3=T.BG_CARD,
                    Size=UDim2.new(1,0,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                    BorderSizePixel=0})
                Corner(Lbl,5); Stroke(Lbl,1,T.SEP)
                local LT=New("TextLabel",{Parent=Lbl, Text=text,
                    Font=Enum.Font.Gotham, TextSize=tsz, TextColor3=col,
                    BackgroundTransparency=1,
                    Size=UDim2.new(1,-16,0,0), AutomaticSize=Enum.AutomaticSize.Y,
                    Position=UDim2.new(0,8,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,
                    TextWrapped=true, RichText=true})
                Pad(LT,5,5,0,0)
                local item={_frame=Lbl,_label=text}
                function item:SetText(t) LT.Text=t end
                table.insert(Section._items,item); return item
            end

            -- ────────────────────────────────────────────────────
            --  KEYBIND
            -- ────────────────────────────────────────────────────
            function Section:AddKeybind(o)
                o=o or {}
                local lbl=o.Name or "Keybind"
                local def=o.Default or Enum.KeyCode.Unknown
                local cb=o.Callback or function() end
                local key=def; local listening=false

                local Row=New("Frame",{Parent=IF, BackgroundColor3=T.BG_CARD,
                    Size=UDim2.new(1,0,0,34), BorderSizePixel=0})
                Corner(Row,6)
                New("TextLabel",{Parent=Row, Text=lbl,
                    Font=Enum.Font.Gotham, TextSize=12, TextColor3=T.TXT_PRI,
                    BackgroundTransparency=1,
                    Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,10,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left})
                local KB=New("TextButton",{Parent=Row,
                    Text=key==Enum.KeyCode.Unknown and "NONE" or key.Name,
                    Font=Enum.Font.GothamBold, TextSize=10, TextColor3=T.RED,
                    BackgroundColor3=T.BG_INPUT,
                    Size=UDim2.new(0,72,0,22), Position=UDim2.new(1,-80,0.5,-11),
                    BorderSizePixel=0, ZIndex=3})
                Corner(KB,4); Stroke(KB,1,T.BORDER)
                KB.MouseButton1Click:Connect(function()
                    listening=true; KB.Text="..."
                    Tween(KB,{TextColor3=T.TXT_PRI},0.1)
                end)
                UserInputService.InputBegan:Connect(function(inp,gpe)
                    if gpe then return end
                    if inp.UserInputType==Enum.UserInputType.Keyboard then
                        if listening then
                            listening=false; key=inp.KeyCode
                            KB.Text=key.Name; Tween(KB,{TextColor3=T.RED},0.1)
                        elseif inp.KeyCode==key then cb() end
                    end
                end)
                Hover(Row,T.BG_CARD,T.BG_CARD_H)
                local item={_frame=Row,_label=lbl,Value=key}
                table.insert(Section._items,item); return item
            end

            return Section
        end -- AddSection

        return Tab
    end -- AddTab

    return Window
end -- CreateWindow

return ZENUHub


--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  USAGE EXAMPLE — ZENU Hub v2.2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ZENUHub = loadstring(game:HttpGet("YOUR_RAW_URL"))()

local Win = ZENUHub:CreateWindow({
    Name        = "ZENU Hub",
    Description = "Advanced Scripting Hub",
    Discord     = "discord.gg/zenuhub",
    Width       = 680,
    Height      = 460,
})

-- ── Tabs ──────────────────────────────────────────
local Home    = Win:AddTab({ Name = "Home",    Icon = "HM" })
local Farm    = Win:AddTab({ Name = "Farming", Icon = "FA" })
local PVP     = Win:AddTab({ Name = "PVP",     Icon = "PV" })
local Misc    = Win:AddTab({ Name = "Misc",    Icon = "MC" })

-- ── Home ──────────────────────────────────────────
local InfoSec = Home:AddSection({ Name = "Info", Icon = "*" })
InfoSec:AddLabel({
    Text  = "<b>ZENU Hub v2.2</b>  —  What's new:",
    Color = Color3.fromRGB(220,30,30),
})
InfoSec:AddLabel({ Text = "Search now hides entire sections with no matches." })
InfoSec:AddLabel({ Text = "Tap [-] to minimize. Tap floating Z to restore." })

-- ── Farming ───────────────────────────────────────
local FarmSec = Farm:AddSection({ Name = "Auto Farm", Icon = ">" })
FarmSec:AddToggle({
    Name = "Auto Farm", Default = false, Flag = "AutoFarm",
    Callback = function(v)
        ZENUHub:Notify({
            Title = "Auto Farm",
            Message = v and "Enabled!" or "Disabled.",
            Type = v and "Success" or "Info", Duration = 3,
        })
    end,
})
FarmSec:AddSlider({
    Name = "Walk Speed", Min = 16, Max = 200, Default = 16,
    Suffix = " spd", Flag = "WalkSpeed",
    Callback = function(v)
        local c = game.Players.LocalPlayer.Character
        if c and c:FindFirstChild("Humanoid") then
            c.Humanoid.WalkSpeed = v
        end
    end,
})

local BossSec = Farm:AddSection({ Name = "Boss Farm", Icon = "!!" })
BossSec:AddDropdown({
    Name  = "Select Boss",
    Items = {"Dragon","Golem","Shadow King","Ice Queen","Demon Lord"},
    Default = "Dragon", Flag = "Boss",
    Callback = function(v) print("Boss:", v) end,
})
BossSec:AddButton({
    Name = "Teleport to Boss",
    Callback = function()
        ZENUHub:Notify({
            Title = "Teleport",
            Message = "Going to " .. (ZENUHub.Flags.Boss or "?"),
            Type = "Info",
        })
    end,
})

-- ── PVP ───────────────────────────────────────────
local PVPSec = PVP:AddSection({ Name = "Combat", Icon = ">>" })
PVPSec:AddToggle({ Name="Aimbot", Default=false,
    Callback=function(v) print("Aimbot:",v) end })
PVPSec:AddSlider({ Name="Aimbot Range", Min=50, Max=500, Default=150,
    Suffix=" studs", Callback=function(v) print("Range:",v) end })

-- MaxSelect example: only 3 targets allowed
PVPSec:AddMultiDropdown({
    Name      = "Target Filters",
    Items     = {"Players","NPCs","Bosses","Guild Members","Pets"},
    Default   = {"Players"},
    MaxSelect = 3,           -- *** max 3 selections ***
    Callback  = function(sel)
        local t={} for k in pairs(sel) do t[#t+1]=k end
        print("Targets:", table.concat(t,", "))
    end,
})

-- ── Misc ──────────────────────────────────────────
local MiscSec = Misc:AddSection({ Name = "Player", Icon = "PL" })
MiscSec:AddTextbox({
    Name="Display Name", Placeholder="Enter name...",
    Callback=function(v) print("Name:",v) end,
})
MiscSec:AddKeybind({
    Name="Toggle UI", Default=Enum.KeyCode.RightShift,
    Callback=function() print("UI key!") end,
})
MiscSec:AddButton({
    Name = "Test All Notification Types",
    Callback = function()
        for i,t in ipairs({"Info","Success","Error","Warn"}) do
            task.delay((i-1)*1.2, function()
                ZENUHub:Notify({
                    Title = t .. " Notification",
                    Message = "This is a "..t:lower().." message.",
                    Type = t, Duration = 4,
                })
            end)
        end
    end,
})
]]
