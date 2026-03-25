--[[
    ███████╗███████╗███╗   ██╗██╗   ██╗    ██╗  ██╗██╗   ██╗██████╗
    ╚══███╔╝██╔════╝████╗  ██║██║   ██║    ██║  ██║██║   ██║██╔══██╗
      ███╔╝ █████╗  ██╔██╗ ██║██║   ██║    ███████║██║   ██║██████╔╝
     ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║    ██╔══██║██║   ██║██╔══██╗
    ███████╗███████╗██║ ╚████║╚██████╔╝    ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝

    ZENU Hub UI Library v2.1
    Advanced Scripting Hub Framework for Roblox
    Theme: Dark Mode | Red Accent | Fluent Design

    Fixes v2.1:
      - Slider รองรับ Touch (มือถือ) อย่างสมบูรณ์
      - เปลี่ยน Emoji/Unicode เป็นตัวอักษร ASCII ที่ทำงานได้ทุกอุปกรณ์
      - ระบบ Minimize ใหม่: กดย่อ = ซ่อน UI + โชว์ปุ่มลอยไอค่อน Z
        กดปุ่ม Z = เปิด UI กลับขึ้นมา

    (c) ZENU Hub - discord.gg/zenuhub
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local CoreGui           = game:GetService("CoreGui")
local TextService       = game:GetService("TextService")

local LocalPlayer = Players.LocalPlayer

-- ============================================================
--  LIBRARY TABLE
-- ============================================================
local ZENUHub = {}
ZENUHub.__index = ZENUHub

-- ============================================================
--  THEME
-- ============================================================
local Theme = {
    BG_PRIMARY       = Color3.fromRGB(10,  10,  12),
    BG_SECONDARY     = Color3.fromRGB(16,  16,  20),
    BG_TERTIARY      = Color3.fromRGB(22,  22,  28),
    BG_CARD          = Color3.fromRGB(26,  26,  33),
    BG_CARD_HOVER    = Color3.fromRGB(32,  32,  42),
    BG_INPUT         = Color3.fromRGB(20,  20,  26),
    BG_DROPDOWN      = Color3.fromRGB(18,  18,  24),

    RED              = Color3.fromRGB(220, 30,  30),
    RED_DARK         = Color3.fromRGB(160, 20,  20),
    RED_BRIGHT       = Color3.fromRGB(255, 60,  60),

    TEXT_PRIMARY     = Color3.fromRGB(240, 240, 245),
    TEXT_SECONDARY   = Color3.fromRGB(150, 150, 165),
    TEXT_MUTED       = Color3.fromRGB(80,  80,  95),

    BORDER           = Color3.fromRGB(40,  40,  52),
    BORDER_RED       = Color3.fromRGB(100, 20,  20),
    SEPARATOR        = Color3.fromRGB(30,  30,  40),

    TOGGLE_OFF       = Color3.fromRGB(45,  45,  58),
    TOGGLE_ON        = Color3.fromRGB(220, 30,  30),
    TOGGLE_KNOB      = Color3.fromRGB(240, 240, 245),

    SLIDER_TRACK     = Color3.fromRGB(35,  35,  45),
    SLIDER_FILL      = Color3.fromRGB(220, 30,  30),
    SLIDER_THUMB     = Color3.fromRGB(240, 240, 245),

    NOTIF_BG         = Color3.fromRGB(20,  20,  26),
    NOTIF_SUCCESS    = Color3.fromRGB(30,  180, 80),
    NOTIF_ERROR      = Color3.fromRGB(220, 30,  30),
    NOTIF_INFO       = Color3.fromRGB(50,  130, 220),
    NOTIF_WARN       = Color3.fromRGB(220, 160, 30),
}

-- ============================================================
--  TWEEN HELPERS
-- ============================================================
local function Tween(obj, props, duration, style, direction)
    duration  = duration  or 0.25
    style     = style     or Enum.EasingStyle.Quint
    direction = direction or Enum.EasingDirection.Out
    TweenService:Create(obj, TweenInfo.new(duration, style, direction), props):Play()
end

local function Spring(obj, props, duration)
    Tween(obj, props, duration or 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ============================================================
--  INSTANCE FACTORY
-- ============================================================
local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    if props and props.Parent then inst.Parent = props.Parent end
    return inst
end

local function MakeCorner(parent, radius)
    return Create("UICorner", {Parent = parent, CornerRadius = UDim.new(0, radius or 8)})
end

local function MakeStroke(parent, thickness, color, transparency)
    return Create("UIStroke", {
        Parent       = parent,
        Thickness    = thickness    or 1,
        Color        = color        or Theme.BORDER,
        Transparency = transparency or 0,
    })
end

local function MakePadding(parent, t, b, l, r)
    return Create("UIPadding", {
        Parent        = parent,
        PaddingTop    = UDim.new(0, t or 6),
        PaddingBottom = UDim.new(0, b or 6),
        PaddingLeft   = UDim.new(0, l or 6),
        PaddingRight  = UDim.new(0, r or 6),
    })
end

local function AddHover(btn, normal, hover)
    btn.MouseEnter:Connect(function()  Tween(btn, {BackgroundColor3 = hover},  0.15) end)
    btn.MouseLeave:Connect(function()  Tween(btn, {BackgroundColor3 = normal}, 0.15) end)
end

-- ============================================================
--  TOUCH-SAFE RIPPLE
-- (ใช้ InputBegan แทน MouseButton1Down เพื่อรองรับ Touch)
-- ============================================================
local function RippleEffect(button)
    button.ClipsDescendants = true
    button.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1
        and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        local abs  = button.AbsolutePosition
        local x, y = inp.Position.X - abs.X, inp.Position.Y - abs.Y
        local sz   = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        local rpl  = Create("Frame", {
            Parent              = button,
            BackgroundColor3    = Color3.fromRGB(255,255,255),
            BackgroundTransparency = 0.85,
            BorderSizePixel     = 0,
            Size                = UDim2.new(0,0,0,0),
            Position            = UDim2.new(0, x, 0, y),
            ZIndex              = button.ZIndex + 10,
        })
        MakeCorner(rpl, 999)
        Tween(rpl, {
            Size     = UDim2.new(0,sz,0,sz),
            Position = UDim2.new(0, x-sz/2, 0, y-sz/2),
            BackgroundTransparency = 1,
        }, 0.5)
        task.delay(0.52, function() if rpl then rpl:Destroy() end end)
    end)
end

-- ============================================================
--  DRAGGING  (Mouse + Touch)
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
--  NOTIFICATION SYSTEM
-- ============================================================
local NotifHolder

local function EnsureNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = Create("ScreenGui", {
        Parent         = CoreGui,
        Name           = "ZENUNotif",
        ResetOnSpawn   = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    })
    NotifHolder = Create("Frame", {
        Parent              = sg,
        BackgroundTransparency = 1,
        Size                = UDim2.new(0, 300, 1, 0),
        Position            = UDim2.new(1, -310, 0, 0),
    })
    Create("UIListLayout", {
        Parent            = NotifHolder,
        FillDirection     = Enum.FillDirection.Vertical,
        VerticalAlignment = Enum.VerticalAlignment.Bottom,
        Padding           = UDim.new(0, 8),
        SortOrder         = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {
        Parent        = NotifHolder,
        PaddingBottom = UDim.new(0, 16),
        PaddingRight  = UDim.new(0, 8),
    })
end

function ZENUHub:Notify(options)
    EnsureNotifHolder()
    options = options or {}
    local title    = options.Title    or "ZENU Hub"
    local message  = options.Message  or ""
    local duration = options.Duration or 4
    local ntype    = options.Type     or "Info"

    local accentMap = {
        Info    = Theme.NOTIF_INFO,
        Success = Theme.NOTIF_SUCCESS,
        Error   = Theme.NOTIF_ERROR,
        Warn    = Theme.NOTIF_WARN,
    }
    local accent = accentMap[ntype] or Theme.NOTIF_INFO

    local card = Create("Frame", {
        Parent              = NotifHolder,
        BackgroundColor3    = Theme.NOTIF_BG,
        Size                = UDim2.new(1, 0, 0, 70),
        BorderSizePixel     = 0,
        ClipsDescendants    = true,
    })
    MakeCorner(card, 10)
    MakeStroke(card, 1, Theme.BORDER)

    -- left accent strip
    local strip = Create("Frame", {
        Parent           = card,
        BackgroundColor3 = accent,
        Size             = UDim2.new(0, 3, 1, 0),
        BorderSizePixel  = 0,
    })

    Create("TextLabel", {
        Parent            = card,
        Text              = title,
        Font              = Enum.Font.GothamBold,
        TextSize          = 13,
        TextColor3        = Theme.TEXT_PRIMARY,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, -20, 0, 20),
        Position          = UDim2.new(0, 14, 0, 8),
        TextXAlignment    = Enum.TextXAlignment.Left,
    })
    Create("TextLabel", {
        Parent            = card,
        Text              = message,
        Font              = Enum.Font.Gotham,
        TextSize          = 11,
        TextColor3        = Theme.TEXT_SECONDARY,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, -20, 0, 28),
        Position          = UDim2.new(0, 14, 0, 28),
        TextXAlignment    = Enum.TextXAlignment.Left,
        TextWrapped       = true,
    })

    local bar = Create("Frame", {
        Parent           = card,
        BackgroundColor3 = accent,
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BorderSizePixel  = 0,
    })

    -- Slide in from right
    card.Position = UDim2.new(1, 10, 0, 0)
    Spring(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.4)
    Tween(bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    -- Dismiss on touch/click
    card.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            Tween(card, {Position = UDim2.new(1,10,0,0), BackgroundTransparency=1}, 0.25)
            task.delay(0.3, function() if card then card:Destroy() end end)
        end
    end)

    task.delay(duration, function()
        if card and card.Parent then
            Tween(card, {Position = UDim2.new(1,10,0,0), BackgroundTransparency=1}, 0.3)
            task.delay(0.35, function() if card then card:Destroy() end end)
        end
    end)
end

-- ============================================================
--  MAIN WINDOW
-- ============================================================
function ZENUHub:CreateWindow(options)
    options  = options  or {}
    local hubName = options.Name        or "ZENU Hub"
    local hubDesc = options.Description or "Advanced Scripting Hub"
    local initTab = options.DefaultTab  or nil
    local sizeW   = options.Width       or 700
    local sizeH   = options.Height      or 460
    local discord = options.Discord     or "discord.gg/zenuhub"

    -- ── ScreenGui ────────────────────────────────────────────
    local ScreenGui = Create("ScreenGui", {
        Parent             = CoreGui,
        Name               = "ZENUHub_" .. tostring(math.random(10000,99999)),
        ResetOnSpawn       = false,
        ZIndexBehavior     = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset     = true,
    })

    -- ── Main Frame ───────────────────────────────────────────
    local MainFrame = Create("Frame", {
        Parent           = ScreenGui,
        BackgroundColor3 = Theme.BG_SECONDARY,
        Size             = UDim2.new(0, sizeW, 0, sizeH),
        Position         = UDim2.new(0.5, -sizeW/2, 0.5, -sizeH/2),
        BorderSizePixel  = 0,
        ClipsDescendants = false,
    })
    MakeCorner(MainFrame, 12)
    MakeStroke(MainFrame, 1, Theme.BORDER_RED, 0.3)

    -- Drop shadow
    Create("ImageLabel", {
        Parent              = MainFrame,
        BackgroundTransparency = 1,
        Size                = UDim2.new(1,60,1,60),
        Position            = UDim2.new(0,-30,0,-30),
        ZIndex              = MainFrame.ZIndex - 1,
        Image               = "rbxassetid://5554236805",
        ImageColor3         = Color3.fromRGB(0,0,0),
        ImageTransparency   = 0.55,
        ScaleType           = Enum.ScaleType.Slice,
        SliceCenter         = Rect.new(23,23,277,277),
    })

    -- ── HEADER ───────────────────────────────────────────────
    local Header = Create("Frame", {
        Parent           = MainFrame,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1,0,0,52),
        BorderSizePixel  = 0,
        ZIndex           = 5,
    })
    MakeCorner(Header, 12)
    -- fill bottom of header so corners only show on top
    Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1,0,0,12),
        Position         = UDim2.new(0,0,1,-12),
        BorderSizePixel  = 0,
        ZIndex           = 4,
    })

    MakeDraggable(MainFrame, Header)

    -- Logo "Z" box
    local LogoBox = Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.RED,
        Size             = UDim2.new(0,34,0,34),
        Position         = UDim2.new(0,12,0.5,-17),
        BorderSizePixel  = 0,
        ZIndex           = 6,
    })
    MakeCorner(LogoBox, 8)
    Create("TextLabel", {
        Parent            = LogoBox,
        Text              = "Z",
        Font              = Enum.Font.GothamBold,
        TextSize          = 20,
        TextColor3        = Color3.fromRGB(255,255,255),
        BackgroundTransparency = 1,
        Size              = UDim2.new(1,0,1,0),
        TextXAlignment    = Enum.TextXAlignment.Center,
        TextYAlignment    = Enum.TextYAlignment.Center,
        ZIndex            = 7,
    })

    Create("TextLabel", {
        Parent            = Header,
        Text              = hubName,
        Font              = Enum.Font.GothamBold,
        TextSize          = 15,
        TextColor3        = Theme.TEXT_PRIMARY,
        BackgroundTransparency = 1,
        Size              = UDim2.new(0,160,0,20),
        Position          = UDim2.new(0,54,0,7),
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 6,
    })
    Create("TextLabel", {
        Parent            = Header,
        Text              = hubDesc,
        Font              = Enum.Font.Gotham,
        TextSize          = 10,
        TextColor3        = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(0,200,0,16),
        Position          = UDim2.new(0,54,0,28),
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 6,
    })

    -- Search Bar
    local SearchBox = Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.BG_INPUT,
        Size             = UDim2.new(0,175,0,26),
        Position         = UDim2.new(1,-285,0.5,-13),
        BorderSizePixel  = 0,
        ZIndex           = 6,
    })
    MakeCorner(SearchBox, 6)
    MakeStroke(SearchBox, 1, Theme.BORDER)

    -- [S] icon (ASCII-safe)
    Create("TextLabel", {
        Parent            = SearchBox,
        Text              = "[S]",
        Font              = Enum.Font.GothamBold,
        TextSize          = 9,
        TextColor3        = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(0,24,1,0),
        Position          = UDim2.new(0,3,0,0),
        TextXAlignment    = Enum.TextXAlignment.Center,
        ZIndex            = 7,
    })
    local SearchInput = Create("TextBox", {
        Parent            = SearchBox,
        Text              = "",
        PlaceholderText   = "Search features...",
        Font              = Enum.Font.Gotham,
        TextSize          = 11,
        TextColor3        = Theme.TEXT_PRIMARY,
        PlaceholderColor3 = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1,-28,1,0),
        Position          = UDim2.new(0,26,0,0),
        TextXAlignment    = Enum.TextXAlignment.Left,
        ClearTextOnFocus  = false,
        ZIndex            = 7,
    })

    -- ── Window Buttons  (ASCII labels — mobile-safe) ─────────
    -- [X] Close   [-] Minimize
    -- NOTE: BtnExpand removed; กดย่อ = ซ่อน UI + โชว์ Z icon
    local function MakeWinBtn(label, bgColor, xOffset)
        local btn = Create("TextButton", {
            Parent           = Header,
            Text             = label,
            Font             = Enum.Font.GothamBold,
            TextSize         = 11,
            TextColor3       = Color3.fromRGB(210,210,210),
            BackgroundColor3 = bgColor,
            Size             = UDim2.new(0,22,0,22),
            Position         = UDim2.new(1, xOffset, 0.5,-11),
            BorderSizePixel  = 0,
            ZIndex           = 8,
        })
        MakeCorner(btn, 6)
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = bgColor:Lerp(Color3.new(1,1,1),0.2)}, 0.1)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = bgColor}, 0.1)
        end)
        return btn
    end

    local BtnClose    = MakeWinBtn("X",  Color3.fromRGB(200,40,40),  -30)
    local BtnMinimize = MakeWinBtn("-",  Color3.fromRGB(50,50,65),   -58)

    -- ── BODY ─────────────────────────────────────────────────
    local Body = Create("Frame", {
        Parent           = MainFrame,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1,0,1,-52-24),
        Position         = UDim2.new(0,0,0,52),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })

    -- ── SIDEBAR ──────────────────────────────────────────────
    local Sidebar = Create("Frame", {
        Parent           = Body,
        BackgroundColor3 = Theme.BG_TERTIARY,
        Size             = UDim2.new(0,52,1,0),
        BorderSizePixel  = 0,
    })
    Create("Frame", {  -- right separator line
        Parent           = Sidebar,
        BackgroundColor3 = Theme.SEPARATOR,
        Size             = UDim2.new(0,1,1,0),
        Position         = UDim2.new(1,-1,0,0),
        BorderSizePixel  = 0,
    })

    local SidebarList = Create("ScrollingFrame", {
        Parent              = Sidebar,
        BackgroundTransparency = 1,
        Size                = UDim2.new(1,0,1,-8),
        Position            = UDim2.new(0,0,0,8),
        ScrollBarThickness  = 0,
        BorderSizePixel     = 0,
        CanvasSize          = UDim2.new(0,0,0,0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })
    Create("UIListLayout", {
        Parent              = SidebarList,
        FillDirection       = Enum.FillDirection.Vertical,
        HorizontalAlignment = Enum.HorizontalAlignment.Center,
        Padding             = UDim.new(0,4),
        SortOrder           = Enum.SortOrder.LayoutOrder,
    })
    MakePadding(SidebarList, 4, 4, 0, 0)

    -- ── CONTENT AREA ─────────────────────────────────────────
    local ContentArea = Create("Frame", {
        Parent           = Body,
        BackgroundColor3 = Theme.BG_SECONDARY,
        Size             = UDim2.new(1,-52,1,0),
        Position         = UDim2.new(0,52,0,0),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })

    -- ── FOOTER ───────────────────────────────────────────────
    local Footer = Create("Frame", {
        Parent           = MainFrame,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1,0,0,24),
        Position         = UDim2.new(0,0,1,-24),
        BorderSizePixel  = 0,
    })
    MakeCorner(Footer, 12)
    Create("Frame", {  -- fill top so only bottom corners round
        Parent           = Footer,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1,0,0,12),
        Position         = UDim2.new(0,0,0,0),
        BorderSizePixel  = 0,
    })
    Create("Frame", {  -- separator line at top of footer
        Parent           = Footer,
        BackgroundColor3 = Theme.SEPARATOR,
        Size             = UDim2.new(1,0,0,1),
        Position         = UDim2.new(0,0,0,0),
        BorderSizePixel  = 0,
    })
    Create("TextLabel", {
        Parent            = Footer,
        Text              = discord,
        Font              = Enum.Font.Gotham,
        TextSize          = 10,
        TextColor3        = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1,-20,1,0),
        Position          = UDim2.new(0,12,0,0),
        TextXAlignment    = Enum.TextXAlignment.Left,
    })

    -- Resize handle (bottom-right)
    local ResizeHandle = Create("TextButton", {
        Parent              = MainFrame,
        Text                = "//",
        Font                = Enum.Font.GothamBold,
        TextSize            = 9,
        TextColor3          = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size                = UDim2.new(0,20,0,20),
        Position            = UDim2.new(1,-20,1,-20),
        BorderSizePixel     = 0,
        ZIndex              = 30,
    })
    do  -- resize logic (mouse only; mobile uses fixed size)
        local resizing, resizeStart, startSize = false, nil, nil
        ResizeHandle.InputBegan:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing    = true
                resizeStart = inp.Position
                startSize   = MainFrame.AbsoluteSize
            end
        end)
        ResizeHandle.InputEnded:Connect(function(inp)
            if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
        UserInputService.InputChanged:Connect(function(inp)
            if not resizing then return end
            if inp.UserInputType ~= Enum.UserInputType.MouseMovement then return end
            local d  = inp.Position - resizeStart
            local nW = math.max(480, startSize.X + d.X)
            local nH = math.max(340, startSize.Y + d.Y)
            MainFrame.Size = UDim2.new(0, nW, 0, nH)
        end)
    end

    -- ── FLOATING Z-ICON  (โชว์เมื่อกดย่อ UI) ────────────────
    -- ออกแบบตามรูปตัวอย่าง: สี่เหลี่ยมขอบมน พื้นดำเข้ม กรอบแดง ตัว Z สีแดง
    local ZFloatGui = Create("ScreenGui", {
        Parent             = CoreGui,
        Name               = "ZENUFloat_" .. tostring(math.random(1000,9999)),
        ResetOnSpawn       = false,
        ZIndexBehavior     = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset     = true,
        Enabled            = false,  -- ซ่อนไว้ก่อน
    })

    local ZFloatBtn = Create("TextButton", {
        Parent              = ZFloatGui,
        Text                = "",
        BackgroundColor3    = Color3.fromRGB(14, 14, 18),
        Size                = UDim2.new(0, 60, 0, 60),
        Position            = UDim2.new(0, 20, 0.5, -30),  -- ซ้ายกลางจอ
        BorderSizePixel     = 0,
        ZIndex              = 50,
    })
    MakeCorner(ZFloatBtn, 14)
    MakeStroke(ZFloatBtn, 2, Theme.RED, 0)

    -- Inner Z label
    Create("TextLabel", {
        Parent            = ZFloatBtn,
        Text              = "Z",
        Font              = Enum.Font.GothamBold,
        TextSize          = 30,
        TextColor3        = Theme.RED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1,0,1,0),
        TextXAlignment    = Enum.TextXAlignment.Center,
        TextYAlignment    = Enum.TextYAlignment.Center,
        ZIndex            = 51,
    })

    -- ปุ่ม Z ลากได้
    MakeDraggable(ZFloatBtn, ZFloatBtn)

    -- pulse glow ให้รู้ว่ากดได้
    task.spawn(function()
        while ZFloatGui.Enabled do
            Tween(ZFloatBtn, {BackgroundColor3 = Color3.fromRGB(30,14,14)}, 0.8,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.85)
            Tween(ZFloatBtn, {BackgroundColor3 = Color3.fromRGB(14,14,18)}, 0.8,
                Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
            task.wait(0.85)
        end
    end)

    -- ── ANIMATE IN ───────────────────────────────────────────
    MainFrame.Size = UDim2.new(0, sizeW, 0, 0)
    MainFrame.BackgroundTransparency = 0.8
    Spring(MainFrame, {Size = UDim2.new(0, sizeW, 0, sizeH), BackgroundTransparency = 0}, 0.45)

    -- ── CLOSE ────────────────────────────────────────────────
    BtnClose.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0,sizeW,0,0), BackgroundTransparency=1}, 0.3)
        task.delay(0.35, function()
            ScreenGui:Destroy()
            ZFloatGui:Destroy()
        end)
    end)

    -- ── MINIMIZE  →  ซ่อน UI + โชว์ Z Icon ─────────────────
    BtnMinimize.MouseButton1Click:Connect(function()
        -- เก็บ size ปัจจุบันก่อน
        local savedSize = MainFrame.Size
        -- Animate ย่อลง
        Tween(MainFrame, {Size = UDim2.new(0, sizeW, 0, 0), BackgroundTransparency = 1}, 0.3,
            Enum.EasingStyle.Quint)
        task.delay(0.32, function()
            MainFrame.Visible  = false
            ZFloatGui.Enabled  = true
            -- Pulse task
            task.spawn(function()
                while ZFloatGui.Enabled do
                    Tween(ZFloatBtn, {BackgroundColor3 = Color3.fromRGB(30,14,14)}, 0.8,
                        Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(0.85)
                    if not ZFloatGui.Enabled then break end
                    Tween(ZFloatBtn, {BackgroundColor3 = Color3.fromRGB(14,14,18)}, 0.8,
                        Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
                    task.wait(0.85)
                end
            end)
            -- Animate Z icon เข้า
            ZFloatBtn.Size = UDim2.new(0,0,0,0)
            Spring(ZFloatBtn, {Size = UDim2.new(0,60,0,60)}, 0.4)
        end)
    end)

    -- ── Z ICON CLICK  →  เปิด UI กลับ ───────────────────────
    ZFloatBtn.MouseButton1Click:Connect(function()
        -- ตรวจว่าไม่ใช่ Drag
        ZFloatGui.Enabled = false
        MainFrame.Visible = true
        MainFrame.Size    = UDim2.new(0, sizeW, 0, 0)
        MainFrame.BackgroundTransparency = 0.8
        Spring(MainFrame, {Size = UDim2.new(0, sizeW, 0, sizeH), BackgroundTransparency = 0}, 0.4)
    end)

    -- ============================================================
    --  WINDOW OBJECT
    -- ============================================================
    local Window = {}
    Window._tabs       = {}
    Window._activeTab  = nil
    Window._mainFrame  = MainFrame
    Window._screenGui  = ScreenGui

    -- Search filter
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local q = SearchInput.Text:lower()
        for _, tab in pairs(Window._tabs) do
            for _, sec in pairs(tab._sections or {}) do
                for _, item in pairs(sec._items or {}) do
                    if item._frame then
                        item._frame.Visible = (q == "")
                            or (item._label and item._label:lower():find(q,1,true) ~= nil)
                    end
                end
            end
        end
    end)

    -- ── ADD TAB ──────────────────────────────────────────────
    function Window:AddTab(options)
        options = options or {}
        local tabName = options.Name or "Tab"
        -- Icon: รับ string ใดก็ได้ แต่ใช้ ASCII 2 ตัวแทน emoji หากต้องการ
        -- e.g. Name="Farming", Icon="FA"  หรือ Icon="H" ก็ได้
        local tabIcon = options.Icon or tabName:sub(1,2):upper()

        -- Sidebar button
        local IconBtn = Create("TextButton", {
            Parent              = SidebarList,
            Text                = tabIcon,
            Font                = Enum.Font.GothamBold,
            TextSize            = 11,
            TextColor3          = Theme.TEXT_MUTED,
            BackgroundColor3    = Theme.BG_TERTIARY,
            Size                = UDim2.new(0,40,0,40),
            BorderSizePixel     = 0,
            ZIndex              = 6,
            TextXAlignment      = Enum.TextXAlignment.Center,
            TextYAlignment      = Enum.TextYAlignment.Center,
        })
        MakeCorner(IconBtn, 8)

        -- Tooltip
        local Tooltip = Create("Frame", {
            Parent           = IconBtn,
            BackgroundColor3 = Theme.BG_CARD,
            Size             = UDim2.new(0,80,0,24),
            Position         = UDim2.new(1,6,0.5,-12),
            BorderSizePixel  = 0,
            Visible          = false,
            ZIndex           = 20,
            ClipsDescendants = false,
        })
        MakeCorner(Tooltip, 5)
        MakeStroke(Tooltip, 1, Theme.BORDER)
        local TipLabel = Create("TextLabel", {
            Parent            = Tooltip,
            Text              = tabName,
            Font              = Enum.Font.GothamBold,
            TextSize          = 11,
            TextColor3        = Theme.TEXT_PRIMARY,
            BackgroundTransparency = 1,
            Size              = UDim2.new(1,-10,1,0),
            Position          = UDim2.new(0,5,0,0),
            ZIndex            = 21,
        })
        -- auto-size tooltip
        local ts = TextService:GetTextSize(tabName,11,Enum.Font.GothamBold,Vector2.new(999,24))
        Tooltip.Size = UDim2.new(0, ts.X+12, 0, 24)

        IconBtn.MouseEnter:Connect(function()
            Tooltip.Visible = true
            Tween(IconBtn, {TextColor3 = Theme.RED}, 0.15)
        end)
        IconBtn.MouseLeave:Connect(function()
            Tooltip.Visible = false
        end)

        -- Active indicator bar (left edge)
        local ActiveBar = Create("Frame", {
            Parent           = IconBtn,
            BackgroundColor3 = Theme.RED,
            Size             = UDim2.new(0,3,0,22),
            Position         = UDim2.new(0,-3,0.5,-11),
            BorderSizePixel  = 0,
            Visible          = false,
        })
        MakeCorner(ActiveBar, 2)

        -- Content page
        local Page = Create("ScrollingFrame", {
            Parent              = ContentArea,
            BackgroundTransparency = 1,
            Size                = UDim2.new(1,0,1,0),
            BorderSizePixel     = 0,
            ScrollBarThickness  = 3,
            ScrollBarImageColor3 = Theme.RED,
            CanvasSize          = UDim2.new(0,0,0,0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible             = false,
        })
        Create("UIListLayout", {
            Parent        = Page,
            FillDirection = Enum.FillDirection.Vertical,
            Padding       = UDim.new(0,8),
            SortOrder     = Enum.SortOrder.LayoutOrder,
        })
        MakePadding(Page, 10, 10, 10, 10)

        local Tab = { _name = tabName, _btn = IconBtn, _page = Page, _bar = ActiveBar, _sections = {} }

        local function SelectTab()
            if Window._activeTab then
                Window._activeTab._page.Visible = false
                Tween(Window._activeTab._btn, {TextColor3=Theme.TEXT_MUTED, BackgroundColor3=Theme.BG_TERTIARY}, 0.15)
                Window._activeTab._bar.Visible = false
            end
            Tab._page.Visible = true
            Tween(IconBtn, {TextColor3=Theme.TEXT_PRIMARY, BackgroundColor3=Theme.BG_CARD}, 0.15)
            Tab._bar.Visible = true
            Window._activeTab = Tab
        end

        IconBtn.MouseButton1Click:Connect(SelectTab)
        if #Window._tabs == 0 or tabName == initTab then SelectTab() end
        table.insert(Window._tabs, Tab)

        -- ── ADD SECTION (Card) ────────────────────────────────
        function Tab:AddSection(options)
            options = options or {}
            local secName   = options.Name      or "Section"
            local secIcon   = options.Icon      or nil  -- ASCII string
            local collapsed = options.Collapsed or false

            local Card = Create("Frame", {
                Parent           = Page,
                BackgroundColor3 = Theme.BG_CARD,
                Size             = UDim2.new(1,0,0,0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            MakeCorner(Card, 10)
            MakeStroke(Card, 1, Theme.BORDER)

            -- Card header bar
            local CardHead = Create("TextButton", {
                Parent           = Card,
                BackgroundColor3 = Theme.BG_CARD,
                Size             = UDim2.new(1,0,0,36),
                Text             = "",
                BorderSizePixel  = 0,
                ZIndex           = 3,
            })
            MakeCorner(CardHead, 10)

            local xOff = 12
            if secIcon then
                Create("TextLabel", {
                    Parent            = CardHead,
                    Text              = secIcon,
                    Font              = Enum.Font.GothamBold,
                    TextSize          = 13,
                    TextColor3        = Theme.RED,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(0,20,1,0),
                    Position          = UDim2.new(0,10,0,0),
                    TextXAlignment    = Enum.TextXAlignment.Center,
                    ZIndex            = 4,
                })
                xOff = 34
            end

            Create("TextLabel", {
                Parent            = CardHead,
                Text              = secName,
                Font              = Enum.Font.GothamBold,
                TextSize          = 12,
                TextColor3        = Theme.TEXT_PRIMARY,
                BackgroundTransparency = 1,
                Size              = UDim2.new(1,-50,1,0),
                Position          = UDim2.new(0,xOff,0,0),
                TextXAlignment    = Enum.TextXAlignment.Left,
                ZIndex            = 4,
            })

            -- Chevron (ASCII: v = open, > = closed)
            local Chevron = Create("TextLabel", {
                Parent            = CardHead,
                Text              = collapsed and ">" or "v",
                Font              = Enum.Font.GothamBold,
                TextSize          = 13,
                TextColor3        = Theme.TEXT_MUTED,
                BackgroundTransparency = 1,
                Size              = UDim2.new(0,20,1,0),
                Position          = UDim2.new(1,-26,0,0),
                TextXAlignment    = Enum.TextXAlignment.Center,
                ZIndex            = 4,
            })

            -- Items container
            local ItemsFrame = Create("Frame", {
                Parent              = Card,
                BackgroundTransparency = 1,
                Size                = UDim2.new(1,0,0,0),
                Position            = UDim2.new(0,0,0,36),
                AutomaticSize       = Enum.AutomaticSize.Y,
                BorderSizePixel     = 0,
                Visible             = not collapsed,
            })
            Create("UIListLayout", {
                Parent        = ItemsFrame,
                FillDirection = Enum.FillDirection.Vertical,
                Padding       = UDim.new(0,4),
                SortOrder     = Enum.SortOrder.LayoutOrder,
            })
            MakePadding(ItemsFrame, 4, 8, 10, 10)

            local isCollapsed = collapsed
            CardHead.MouseButton1Click:Connect(function()
                isCollapsed        = not isCollapsed
                ItemsFrame.Visible = not isCollapsed
                Chevron.Text       = isCollapsed and ">" or "v"
                Tween(CardHead, {BackgroundColor3 = isCollapsed and Theme.BG_CARD_HOVER or Theme.BG_CARD}, 0.15)
            end)
            AddHover(CardHead, Theme.BG_CARD, Theme.BG_CARD_HOVER)

            local Section = { _items = {} }
            table.insert(Tab._sections, Section)

            -- ── TOGGLE ───────────────────────────────────────
            function Section:AddToggle(opts)
                opts = opts or {}
                local label    = opts.Name     or "Toggle"
                local default  = opts.Default  or false
                local callback = opts.Callback or function() end
                local flag     = opts.Flag     or nil

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1,0,0,34),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Row, 6)

                Create("TextLabel", {
                    Parent            = Row,
                    Text              = label,
                    Font              = Enum.Font.Gotham,
                    TextSize          = 12,
                    TextColor3        = Theme.TEXT_PRIMARY,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1,-60,1,0),
                    Position          = UDim2.new(0,10,0,0),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                })

                local Track = Create("TextButton", {
                    Parent           = Row,
                    Text             = "",
                    BackgroundColor3 = default and Theme.TOGGLE_ON or Theme.TOGGLE_OFF,
                    Size             = UDim2.new(0,42,0,22),
                    Position         = UDim2.new(1,-50,0.5,-11),
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                })
                MakeCorner(Track, 11)

                local Knob = Create("Frame", {
                    Parent           = Track,
                    BackgroundColor3 = Theme.TOGGLE_KNOB,
                    Size             = UDim2.new(0,16,0,16),
                    Position         = default and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8),
                    BorderSizePixel  = 0,
                    ZIndex           = 4,
                })
                MakeCorner(Knob, 8)

                local state = default
                local item  = {_frame = Row, _label = label, Value = state}

                local function SetState(v, fire)
                    state = v; item.Value = v
                    Tween(Track, {BackgroundColor3 = v and Theme.TOGGLE_ON or Theme.TOGGLE_OFF}, 0.2)
                    Spring(Knob, {Position = v and UDim2.new(1,-19,0.5,-8) or UDim2.new(0,3,0.5,-8)}, 0.25)
                    if fire ~= false then callback(v) end
                    if flag then ZENUHub.Flags[flag] = v end
                end

                Track.MouseButton1Click:Connect(function() SetState(not state) end)
                AddHover(Row, Theme.BG_CARD, Theme.BG_CARD_HOVER)
                function item:Set(v) SetState(v, false) end
                table.insert(Section._items, item)
                return item
            end

            -- ── BUTTON ───────────────────────────────────────
            function Section:AddButton(opts)
                opts = opts or {}
                local label    = opts.Name     or "Button"
                local callback = opts.Callback or function() end

                local Btn = Create("TextButton", {
                    Parent           = ItemsFrame,
                    Text             = label,
                    Font             = Enum.Font.GothamBold,
                    TextSize         = 12,
                    TextColor3       = Theme.TEXT_PRIMARY,
                    BackgroundColor3 = Theme.RED_DARK,
                    Size             = UDim2.new(1,0,0,34),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Btn, 6)
                RippleEffect(Btn)

                Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3=Theme.RED}, 0.15) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3=Theme.RED_DARK}, 0.15) end)
                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, {BackgroundColor3=Theme.RED_BRIGHT}, 0.07)
                    task.delay(0.07, function() Tween(Btn, {BackgroundColor3=Theme.RED}, 0.12) end)
                    callback()
                end)

                local item = {_frame=Btn, _label=label}
                table.insert(Section._items, item)
                return item
            end

            -- ── SLIDER  (Touch-safe) ──────────────────────────
            --  *** BUG FIX: เพิ่ม Touch support ใน InputBegan / InputEnded / InputChanged ***
            function Section:AddSlider(opts)
                opts = opts or {}
                local label    = opts.Name     or "Slider"
                local min      = opts.Min      or 0
                local max      = opts.Max      or 100
                local default  = math.clamp(opts.Default or min, min, max)
                local suffix   = opts.Suffix   or ""
                local callback = opts.Callback or function() end
                local flag     = opts.Flag     or nil

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1,0,0,52),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Row, 6)

                Create("TextLabel", {
                    Parent            = Row,
                    Text              = label,
                    Font              = Enum.Font.Gotham,
                    TextSize          = 12,
                    TextColor3        = Theme.TEXT_PRIMARY,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(0.6,0,0,22),
                    Position          = UDim2.new(0,10,0,4),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                })

                local ValLabel = Create("TextLabel", {
                    Parent            = Row,
                    Text              = tostring(default) .. suffix,
                    Font              = Enum.Font.GothamBold,
                    TextSize          = 12,
                    TextColor3        = Theme.RED,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(0.4,-10,0,22),
                    Position          = UDim2.new(0.6,0,0,4),
                    TextXAlignment    = Enum.TextXAlignment.Right,
                })

                -- Track — ขยาย hitbox เพื่อให้ง่ายต่อการแตะบนมือถือ
                local Track = Create("Frame", {
                    Parent           = Row,
                    BackgroundColor3 = Theme.SLIDER_TRACK,
                    Size             = UDim2.new(1,-20,0,6),
                    Position         = UDim2.new(0,10,1,-20),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Track, 3)

                local Fill = Create("Frame", {
                    Parent           = Track,
                    BackgroundColor3 = Theme.SLIDER_FILL,
                    Size             = UDim2.new((default-min)/(max-min),0,1,0),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Fill, 3)

                local Thumb = Create("Frame", {
                    Parent           = Track,
                    BackgroundColor3 = Theme.SLIDER_THUMB,
                    Size             = UDim2.new(0,16,0,16),
                    Position         = UDim2.new((default-min)/(max-min),-8,0.5,-8),
                    BorderSizePixel  = 0,
                    ZIndex           = 3,
                })
                MakeCorner(Thumb, 8)
                MakeStroke(Thumb, 1.5, Theme.SLIDER_FILL)

                -- Invisible touch-area on top of track (taller = easier to tap)
                local TouchArea = Create("TextButton", {
                    Parent              = Row,
                    Text                = "",
                    BackgroundTransparency = 1,
                    Size                = UDim2.new(1,-20,0,28),
                    Position            = UDim2.new(0,10,1,-34),
                    BorderSizePixel     = 0,
                    ZIndex              = 5,
                })

                local value    = default
                local dragging = false
                local item     = {_frame=Row, _label=label, Value=value}

                local function UpdateSlider(inputX)
                    local abs = Track.AbsolutePosition
                    local sz  = Track.AbsoluteSize
                    local pct = math.clamp((inputX - abs.X) / sz.X, 0, 1)
                    value       = math.round(min + pct*(max-min))
                    item.Value  = value
                    local fpct  = (value-min)/(max-min)
                    Tween(Fill,  {Size     = UDim2.new(fpct,0,1,0)},     0.05, Enum.EasingStyle.Linear)
                    Tween(Thumb, {Position = UDim2.new(fpct,-8,0.5,-8)}, 0.05, Enum.EasingStyle.Linear)
                    ValLabel.Text = tostring(value) .. suffix
                    callback(value)
                    if flag then ZENUHub.Flags[flag] = value end
                end

                -- *** Touch + Mouse 양쪽 지원 ***
                TouchArea.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        UpdateSlider(inp.Position.X)
                    end
                end)
                TouchArea.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                -- InputChanged สำหรับ drag
                UserInputService.InputChanged:Connect(function(inp)
                    if not dragging then return end
                    if inp.UserInputType == Enum.UserInputType.MouseMovement
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1
                    or inp.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)

                AddHover(Row, Theme.BG_CARD, Theme.BG_CARD_HOVER)

                function item:Set(v)
                    value = math.clamp(v, min, max)
                    local fpct = (value-min)/(max-min)
                    Fill.Size      = UDim2.new(fpct,0,1,0)
                    Thumb.Position = UDim2.new(fpct,-8,0.5,-8)
                    ValLabel.Text  = tostring(value) .. suffix
                    item.Value     = value
                end

                table.insert(Section._items, item)
                return item
            end

            -- ── TEXTBOX ──────────────────────────────────────
            function Section:AddTextbox(opts)
                opts = opts or {}
                local label       = opts.Name        or "Textbox"
                local placeholder = opts.Placeholder or "Enter text..."
                local default     = opts.Default     or ""
                local callback    = opts.Callback    or function() end
                local flag        = opts.Flag        or nil

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1,0,0,54),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Row, 6)

                Create("TextLabel", {
                    Parent            = Row,
                    Text              = label,
                    Font              = Enum.Font.Gotham,
                    TextSize          = 11,
                    TextColor3        = Theme.TEXT_SECONDARY,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1,-20,0,18),
                    Position          = UDim2.new(0,10,0,5),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                })

                local InputFrame = Create("Frame", {
                    Parent           = Row,
                    BackgroundColor3 = Theme.BG_INPUT,
                    Size             = UDim2.new(1,-20,0,26),
                    Position         = UDim2.new(0,10,0,24),
                    BorderSizePixel  = 0,
                })
                MakeCorner(InputFrame, 5)
                local stroke = MakeStroke(InputFrame, 1, Theme.BORDER)

                local Input = Create("TextBox", {
                    Parent            = InputFrame,
                    Text              = default,
                    PlaceholderText   = placeholder,
                    Font              = Enum.Font.Gotham,
                    TextSize          = 11,
                    TextColor3        = Theme.TEXT_PRIMARY,
                    PlaceholderColor3 = Theme.TEXT_MUTED,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1,-12,1,0),
                    Position          = UDim2.new(0,6,0,0),
                    ClearTextOnFocus  = false,
                    ZIndex            = 3,
                })

                Input.Focused:Connect(function()   Tween(stroke, {Color=Theme.RED},    0.15) end)
                Input.FocusLost:Connect(function()
                    Tween(stroke, {Color=Theme.BORDER}, 0.15)
                    callback(Input.Text)
                end)

                local item = {_frame=Row, _label=label, Value=Input.Text}
                Input:GetPropertyChangedSignal("Text"):Connect(function()
                    item.Value = Input.Text
                    if flag then ZENUHub.Flags[flag] = Input.Text end
                end)
                table.insert(Section._items, item)
                return item
            end

            -- ── DROPDOWN  (with search) ───────────────────────
            function Section:AddDropdown(opts)
                opts = opts or {}
                local label    = opts.Name     or "Dropdown"
                local items    = opts.Items    or {}
                local default  = opts.Default  or (items[1] or "None")
                local callback = opts.Callback or function() end
                local flag     = opts.Flag     or nil
                local selected = default

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1,0,0,56),
                    BorderSizePixel  = 0,
                    ZIndex           = 5,
                    ClipsDescendants = false,
                })
                MakeCorner(Row, 6)

                Create("TextLabel", {
                    Parent            = Row,
                    Text              = label,
                    Font              = Enum.Font.Gotham,
                    TextSize          = 11,
                    TextColor3        = Theme.TEXT_SECONDARY,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1,-20,0,18),
                    Position          = UDim2.new(0,10,0,5),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    ZIndex            = 6,
                })

                local DropBtn = Create("TextButton", {
                    Parent           = Row,
                    Text             = "",
                    BackgroundColor3 = Theme.BG_INPUT,
                    Size             = UDim2.new(1,-20,0,26),
                    Position         = UDim2.new(0,10,0,24),
                    BorderSizePixel  = 0,
                    ZIndex           = 6,
                    ClipsDescendants = false,
                })
                MakeCorner(DropBtn, 5)
                MakeStroke(DropBtn, 1, Theme.BORDER)

                local SelLabel = Create("TextLabel", {
                    Parent            = DropBtn,
                    Text              = selected,
                    Font              = Enum.Font.Gotham,
                    TextSize          = 11,
                    TextColor3        = Theme.TEXT_PRIMARY,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1,-28,1,0),
                    Position          = UDim2.new(0,8,0,0),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    ZIndex            = 7,
                })
                -- Chevron (ASCII)
                Create("TextLabel", {
                    Parent=DropBtn,Text="v",Font=Enum.Font.GothamBold,TextSize=11,
                    TextColor3=Theme.TEXT_MUTED,BackgroundTransparency=1,
                    Size=UDim2.new(0,22,1,0),Position=UDim2.new(1,-24,0,0),
                    TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7,
                })

                -- Drop list panel
                local DropList = Create("Frame", {
                    Parent           = DropBtn,
                    BackgroundColor3 = Theme.BG_DROPDOWN,
                    Size             = UDim2.new(1,0,0,0),
                    Position         = UDim2.new(0,0,1,4),
                    BorderSizePixel  = 0,
                    Visible          = false,
                    ZIndex           = 50,
                    ClipsDescendants = true,
                })
                MakeCorner(DropList, 6)
                MakeStroke(DropList, 1, Theme.BORDER)

                -- Search inside dropdown
                local SRow = Create("Frame", {
                    Parent=DropList, BackgroundColor3=Theme.BG_INPUT,
                    Size=UDim2.new(1,-12,0,22), Position=UDim2.new(0,6,0,6),
                    BorderSizePixel=0, ZIndex=51,
                })
                MakeCorner(SRow, 4); MakeStroke(SRow, 1, Theme.BORDER)
                local SInput = Create("TextBox", {
                    Parent=SRow, Text="", PlaceholderText="Search...",
                    Font=Enum.Font.Gotham, TextSize=10,
                    TextColor3=Theme.TEXT_PRIMARY, PlaceholderColor3=Theme.TEXT_MUTED,
                    BackgroundTransparency=1, Size=UDim2.new(1,-8,1,0),
                    Position=UDim2.new(0,4,0,0), ClearTextOnFocus=false, ZIndex=52,
                })

                local ItemList = Create("ScrollingFrame", {
                    Parent=DropList, BackgroundTransparency=1,
                    Size=UDim2.new(1,0,1,-36), Position=UDim2.new(0,0,0,34),
                    ScrollBarThickness=2, ScrollBarImageColor3=Theme.RED,
                    BorderSizePixel=0, CanvasSize=UDim2.new(0,0,0,0),
                    AutomaticCanvasSize=Enum.AutomaticSize.Y, ZIndex=51,
                })
                Create("UIListLayout",{Parent=ItemList,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
                MakePadding(ItemList,2,2,4,4)

                local allBtns = {}
                local function BuildItems(filter)
                    for _,v in ipairs(allBtns) do v:Destroy() end
                    allBtns = {}
                    for _,it in ipairs(items) do
                        if filter=="" or it:lower():find(filter:lower(),1,true) then
                            local ib = Create("TextButton", {
                                Parent=ItemList, Text=it,
                                Font=Enum.Font.Gotham, TextSize=11,
                                TextColor3=Theme.TEXT_PRIMARY,
                                BackgroundColor3=Theme.BG_DROPDOWN,
                                Size=UDim2.new(1,0,0,26), BorderSizePixel=0,
                                TextXAlignment=Enum.TextXAlignment.Left, ZIndex=52,
                            })
                            MakeCorner(ib,4); MakePadding(ib,0,0,8,4)
                            ib.MouseEnter:Connect(function() Tween(ib,{BackgroundColor3=Theme.BG_CARD_HOVER},0.1) end)
                            ib.MouseLeave:Connect(function() Tween(ib,{BackgroundColor3=Theme.BG_DROPDOWN},0.1) end)
                            ib.MouseButton1Click:Connect(function()
                                selected=it; SelLabel.Text=it
                                DropList.Visible=false
                                callback(it)
                                if flag then ZENUHub.Flags[flag]=it end
                            end)
                            table.insert(allBtns,ib)
                        end
                    end
                end

                BuildItems("")
                SInput:GetPropertyChangedSignal("Text"):Connect(function() BuildItems(SInput.Text) end)

                local open = false
                DropBtn.MouseButton1Click:Connect(function()
                    open = not open; DropList.Visible = open
                    if open then
                        local h = math.min(#items*28+44,160)
                        DropList.Size = UDim2.new(1,0,0,h)
                        SInput.Text=""; BuildItems("")
                    end
                end)

                local item = {_frame=Row, _label=label, Value=selected}
                function item:Set(v)  selected=v; SelLabel.Text=v; item.Value=v end
                function item:Refresh(newItems) items=newItems; BuildItems(SInput.Text) end
                table.insert(Section._items, item)
                return item
            end

            -- ── MULTI-DROPDOWN ────────────────────────────────
            function Section:AddMultiDropdown(opts)
                opts = opts or {}
                local label    = opts.Name     or "Multi Select"
                local items    = opts.Items    or {}
                local defaults = opts.Default  or {}
                local callback = opts.Callback or function() end

                local selected = {}
                for _,v in ipairs(defaults) do selected[v]=true end

                local Row = Create("Frame", {
                    Parent=ItemsFrame, BackgroundColor3=Theme.BG_CARD,
                    Size=UDim2.new(1,0,0,56), BorderSizePixel=0, ZIndex=5, ClipsDescendants=false,
                })
                MakeCorner(Row, 6)

                Create("TextLabel", {
                    Parent=Row, Text=label, Font=Enum.Font.Gotham, TextSize=11,
                    TextColor3=Theme.TEXT_SECONDARY, BackgroundTransparency=1,
                    Size=UDim2.new(1,-20,0,18), Position=UDim2.new(0,10,0,5),
                    TextXAlignment=Enum.TextXAlignment.Left, ZIndex=6,
                })

                local DropBtn = Create("TextButton", {
                    Parent=Row, Text="", BackgroundColor3=Theme.BG_INPUT,
                    Size=UDim2.new(1,-20,0,26), Position=UDim2.new(0,10,0,24),
                    BorderSizePixel=0, ZIndex=6, ClipsDescendants=false,
                })
                MakeCorner(DropBtn, 5); MakeStroke(DropBtn, 1, Theme.BORDER)

                local function GetSelText()
                    local t={}; for k in pairs(selected) do table.insert(t,k) end
                    return #t==0 and "None" or table.concat(t,", ")
                end
                local SelLabel=Create("TextLabel",{
                    Parent=DropBtn, Text=GetSelText(), Font=Enum.Font.Gotham, TextSize=10,
                    TextColor3=Theme.TEXT_PRIMARY, BackgroundTransparency=1,
                    Size=UDim2.new(1,-28,1,0), Position=UDim2.new(0,8,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left, TextTruncate=Enum.TextTruncate.AtEnd, ZIndex=7,
                })
                Create("TextLabel",{Parent=DropBtn,Text="v",Font=Enum.Font.GothamBold,TextSize=11,
                    TextColor3=Theme.TEXT_MUTED,BackgroundTransparency=1,Size=UDim2.new(0,22,1,0),
                    Position=UDim2.new(1,-24,0,0),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7})

                local DropList=Create("Frame",{Parent=DropBtn,BackgroundColor3=Theme.BG_DROPDOWN,
                    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,4),
                    BorderSizePixel=0,Visible=false,ZIndex=50,ClipsDescendants=true})
                MakeCorner(DropList,6); MakeStroke(DropList,1,Theme.BORDER)

                local SR=Create("Frame",{Parent=DropList,BackgroundColor3=Theme.BG_INPUT,
                    Size=UDim2.new(1,-12,0,22),Position=UDim2.new(0,6,0,6),BorderSizePixel=0,ZIndex=51})
                MakeCorner(SR,4); MakeStroke(SR,1,Theme.BORDER)
                local SDD=Create("TextBox",{Parent=SR,Text="",PlaceholderText="Search...",
                    Font=Enum.Font.Gotham,TextSize=10,TextColor3=Theme.TEXT_PRIMARY,PlaceholderColor3=Theme.TEXT_MUTED,
                    BackgroundTransparency=1,Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),
                    ClearTextOnFocus=false,ZIndex=52})

                local IL=Create("ScrollingFrame",{Parent=DropList,BackgroundTransparency=1,
                    Size=UDim2.new(1,0,1,-36),Position=UDim2.new(0,0,0,34),
                    ScrollBarThickness=2,ScrollBarImageColor3=Theme.RED,
                    BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),
                    AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=51})
                Create("UIListLayout",{Parent=IL,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
                MakePadding(IL,2,2,4,4)

                local allIB={}
                local function BuildMD(filter)
                    for _,v in ipairs(allIB) do v:Destroy() end; allIB={}
                    for _,it in ipairs(items) do
                        if filter=="" or it:lower():find(filter:lower(),1,true) then
                            local iRow=Create("Frame",{Parent=IL,
                                BackgroundColor3=selected[it] and Theme.RED_DARK or Theme.BG_DROPDOWN,
                                Size=UDim2.new(1,0,0,26),BorderSizePixel=0,ZIndex=52})
                            MakeCorner(iRow,4)
                            Create("TextLabel",{Parent=iRow,Text=it,Font=Enum.Font.Gotham,TextSize=11,
                                TextColor3=Theme.TEXT_PRIMARY,BackgroundTransparency=1,
                                Size=UDim2.new(1,-30,1,0),Position=UDim2.new(0,8,0,0),
                                TextXAlignment=Enum.TextXAlignment.Left,ZIndex=53})
                            -- checkmark ASCII
                            Create("TextLabel",{Parent=iRow,Text=selected[it] and "[v]" or "[ ]",
                                Font=Enum.Font.GothamBold,TextSize=10,TextColor3=Theme.RED,
                                BackgroundTransparency=1,Size=UDim2.new(0,28,1,0),
                                Position=UDim2.new(1,-30,0,0),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=53})
                            local ib2=Create("TextButton",{Parent=iRow,Text="",BackgroundTransparency=1,
                                Size=UDim2.new(1,0,1,0),ZIndex=54})
                            ib2.MouseButton1Click:Connect(function()
                                selected[it]=not selected[it]
                                SelLabel.Text=GetSelText()
                                callback(selected)
                                BuildMD(SDD.Text)
                            end)
                            table.insert(allIB,iRow)
                        end
                    end
                end
                BuildMD(""); SDD:GetPropertyChangedSignal("Text"):Connect(function() BuildMD(SDD.Text) end)

                local open=false
                DropBtn.MouseButton1Click:Connect(function()
                    open=not open; DropList.Visible=open
                    if open then
                        local h=math.min(#items*28+44,160)
                        DropList.Size=UDim2.new(1,0,0,h)
                        SDD.Text=""; BuildMD("")
                    end
                end)

                local item={_frame=Row,_label=label,Value=selected}
                table.insert(Section._items,item)
                return item
            end

            -- ── LABEL ────────────────────────────────────────
            function Section:AddLabel(opts)
                opts = opts or {}
                local text  = opts.Text      or "Label"
                local color = opts.Color     or Theme.TEXT_SECONDARY
                local tsize = opts.TextSize  or 11

                local Lbl = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1,0,0,28),
                    AutomaticSize    = Enum.AutomaticSize.Y,
                    BorderSizePixel  = 0,
                })
                MakeCorner(Lbl, 5)
                MakeStroke(Lbl, 1, Theme.SEPARATOR)

                local LT = Create("TextLabel", {
                    Parent            = Lbl,
                    Text              = text,
                    Font              = Enum.Font.Gotham,
                    TextSize          = tsize,
                    TextColor3        = color,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1,-16,0,28),
                    AutomaticSize     = Enum.AutomaticSize.Y,
                    Position          = UDim2.new(0,8,0,0),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    TextWrapped       = true,
                    RichText          = true,
                })
                MakePadding(LT,4,4,0,0)

                local item = {_frame=Lbl, _label=text}
                function item:SetText(t) LT.Text=t end
                table.insert(Section._items, item)
                return item
            end

            -- ── KEYBIND ──────────────────────────────────────
            function Section:AddKeybind(opts)
                opts = opts or {}
                local label    = opts.Name     or "Keybind"
                local default  = opts.Default  or Enum.KeyCode.Unknown
                local callback = opts.Callback or function() end

                local key       = default
                local listening = false

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1,0,0,34),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Row, 6)

                Create("TextLabel", {
                    Parent=Row, Text=label, Font=Enum.Font.Gotham, TextSize=12,
                    TextColor3=Theme.TEXT_PRIMARY, BackgroundTransparency=1,
                    Size=UDim2.new(1,-90,1,0), Position=UDim2.new(0,10,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left,
                })

                local KbBtn = Create("TextButton", {
                    Parent=Row,
                    Text = key==Enum.KeyCode.Unknown and "NONE" or key.Name,
                    Font=Enum.Font.GothamBold, TextSize=10, TextColor3=Theme.RED,
                    BackgroundColor3=Theme.BG_INPUT,
                    Size=UDim2.new(0,72,0,22), Position=UDim2.new(1,-80,0.5,-11),
                    BorderSizePixel=0, ZIndex=3,
                })
                MakeCorner(KbBtn, 4); MakeStroke(KbBtn, 1, Theme.BORDER)

                KbBtn.MouseButton1Click:Connect(function()
                    listening=true; KbBtn.Text="..."
                    Tween(KbBtn, {TextColor3=Theme.TEXT_PRIMARY}, 0.1)
                end)

                UserInputService.InputBegan:Connect(function(inp, gpe)
                    if gpe then return end
                    if inp.UserInputType==Enum.UserInputType.Keyboard then
                        if listening then
                            listening=false; key=inp.KeyCode
                            KbBtn.Text=key.Name
                            Tween(KbBtn,{TextColor3=Theme.RED},0.1)
                        elseif inp.KeyCode==key then
                            callback()
                        end
                    end
                end)

                AddHover(Row, Theme.BG_CARD, Theme.BG_CARD_HOVER)
                local item={_frame=Row,_label=label,Value=key}
                table.insert(Section._items, item)
                return item
            end

            return Section
        end  -- AddSection

        return Tab
    end  -- AddTab

    return Window
end  -- CreateWindow

-- ============================================================
--  FLAGS
-- ============================================================
ZENUHub.Flags = {}

return ZENUHub


--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  USAGE EXAMPLE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ZENUHub = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

local Window = ZENUHub:CreateWindow({
    Name        = "ZENU Hub",
    Description = "Advanced Scripting Hub",
    Discord     = "discord.gg/zenuhub",
    Width       = 680,
    Height      = 460,
})

-- Icon ใช้ ASCII 1-2 ตัว เพื่อความเข้ากันได้กับมือถือ
-- หรือจะใช้ emoji ก็ได้ถ้า Device รองรับ
local HomeTab = Window:AddTab({ Name = "Home",    Icon = "HM" })
local FarmTab = Window:AddTab({ Name = "Farming", Icon = "FA" })
local PVPTab  = Window:AddTab({ Name = "PVP",     Icon = "PV" })
local MiscTab = Window:AddTab({ Name = "Misc",    Icon = "MC" })

-- Home
local WelcomeSec = HomeTab:AddSection({ Name = "Welcome", Icon = "*" })
WelcomeSec:AddLabel({ Text = "<b>ZENU Hub v2.1</b> — Touch slider fixed!", Color = Color3.fromRGB(220,30,30) })
WelcomeSec:AddLabel({ Text = "Tap the [-] button to minimize. Tap the floating Z to restore." })

-- Farming
local FarmSec = FarmTab:AddSection({ Name = "Auto Farm", Icon = ">" })

FarmSec:AddToggle({
    Name = "Auto Farm", Default = false, Flag = "AutoFarm",
    Callback = function(v)
        ZENUHub:Notify({ Title="Auto Farm", Message=v and "Enabled!" or "Disabled.", Type=v and "Success" or "Info", Duration=3 })
    end,
})

FarmSec:AddSlider({
    Name = "Walk Speed", Min = 16, Max = 200, Default = 16, Suffix = " spd", Flag = "WalkSpeed",
    Callback = function(v)
        local char = game.Players.LocalPlayer.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = v
        end
    end,
})

local BossSec = FarmTab:AddSection({ Name = "Boss Farm", Icon = "!!" })

BossSec:AddDropdown({
    Name = "Select Boss",
    Items = {"Dragon","Golem","Shadow King","Ice Queen","Demon Lord"},
    Default = "Dragon", Flag = "SelectedBoss",
    Callback = function(v) print("Boss:", v) end,
})
BossSec:AddButton({
    Name = "Teleport to Boss",
    Callback = function()
        ZENUHub:Notify({ Title="Teleport", Message="Going to " .. (ZENUHub.Flags.SelectedBoss or "?"), Type="Info" })
    end,
})

-- PVP
local PVPSec = PVPTab:AddSection({ Name = "Combat", Icon = ">>" })
PVPSec:AddToggle({ Name="Aimbot", Default=false, Callback=function(v) print("Aimbot:", v) end })
PVPSec:AddSlider({ Name="Aimbot Range", Min=50, Max=500, Default=150, Suffix=" studs", Callback=function(v) print("Range:", v) end })
PVPSec:AddMultiDropdown({
    Name="Target Filters", Items={"Players","NPCs","Bosses","Guild"},
    Default={"Players"}, Callback=function(s) print("Targets:", s) end,
})

-- Misc
local MiscSec = MiscTab:AddSection({ Name = "Player", Icon = "PL" })
MiscSec:AddTextbox({ Name="Display Name", Placeholder="Enter name...", Callback=function(v) print(v) end })
MiscSec:AddKeybind({ Name="Toggle UI", Default=Enum.KeyCode.RightShift, Callback=function() print("toggled") end })
MiscSec:AddButton({
    Name="Test Notification",
    Callback=function()
        ZENUHub:Notify({ Title="ZENU Hub", Message="Hello from v2.1!", Type="Success", Duration=5 })
    end,
})
]]
