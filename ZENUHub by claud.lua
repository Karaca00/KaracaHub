--[[
    ███████╗███████╗███╗   ██╗██╗   ██╗    ██╗  ██╗██╗   ██╗██████╗ 
    ╚══███╔╝██╔════╝████╗  ██║██║   ██║    ██║  ██║██║   ██║██╔══██╗
      ███╔╝ █████╗  ██╔██╗ ██║██║   ██║    ███████║██║   ██║██████╔╝
     ███╔╝  ██╔══╝  ██║╚██╗██║██║   ██║    ██╔══██║██║   ██║██╔══██╗
    ███████╗███████╗██║ ╚████║╚██████╔╝    ██║  ██║╚██████╔╝██████╔╝
    ╚══════╝╚══════╝╚═╝  ╚═══╝ ╚═════╝     ╚═╝  ╚═╝ ╚═════╝ ╚═════╝ 
    
    ZENU Hub UI Library v2.0
    Advanced Scripting Hub Framework for Roblox
    Theme: Dark Mode | Red Accent | Fluent Design
    
    © ZENU Hub - discord.gg/zenuhub
--]]

-- ============================================================
--  SERVICES
-- ============================================================
local Players        = game:GetService("Players")
local RunService     = game:GetService("RunService")
local TweenService   = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui        = game:GetService("CoreGui")
local TextService    = game:GetService("TextService")

local LocalPlayer    = Players.LocalPlayer
local Mouse          = LocalPlayer:GetMouse()

-- ============================================================
--  LIBRARY TABLE
-- ============================================================
local ZENUHub = {}
ZENUHub.__index = ZENUHub

-- ============================================================
--  THEME
-- ============================================================
local Theme = {
    -- Backgrounds
    BG_PRIMARY       = Color3.fromRGB(10,  10,  12),   -- deepest dark
    BG_SECONDARY     = Color3.fromRGB(16,  16,  20),   -- main window
    BG_TERTIARY      = Color3.fromRGB(22,  22,  28),   -- sidebar
    BG_CARD          = Color3.fromRGB(26,  26,  33),   -- cards
    BG_CARD_HOVER    = Color3.fromRGB(32,  32,  42),   -- card hover
    BG_INPUT         = Color3.fromRGB(20,  20,  26),   -- inputs
    BG_DROPDOWN      = Color3.fromRGB(18,  18,  24),   -- dropdown

    -- Accent
    RED              = Color3.fromRGB(220, 30,  30),
    RED_DARK         = Color3.fromRGB(160, 20,  20),
    RED_BRIGHT       = Color3.fromRGB(255, 50,  50),
    RED_GLOW         = Color3.fromRGB(220, 30,  30),

    -- Text
    TEXT_PRIMARY     = Color3.fromRGB(240, 240, 245),
    TEXT_SECONDARY   = Color3.fromRGB(150, 150, 165),
    TEXT_MUTED       = Color3.fromRGB(80,  80,  95),
    TEXT_RED         = Color3.fromRGB(220, 30,  30),

    -- Borders & Lines
    BORDER           = Color3.fromRGB(40,  40,  52),
    BORDER_RED       = Color3.fromRGB(100, 20,  20),
    SEPARATOR        = Color3.fromRGB(30,  30,  40),

    -- Toggle
    TOGGLE_OFF       = Color3.fromRGB(45,  45,  58),
    TOGGLE_ON        = Color3.fromRGB(220, 30,  30),
    TOGGLE_KNOB      = Color3.fromRGB(240, 240, 245),

    -- Slider
    SLIDER_TRACK     = Color3.fromRGB(35,  35,  45),
    SLIDER_FILL      = Color3.fromRGB(220, 30,  30),
    SLIDER_THUMB     = Color3.fromRGB(240, 240, 245),

    -- Notification
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
    local info = TweenInfo.new(duration, style, direction)
    local t = TweenService:Create(obj, info, props)
    t:Play()
    return t
end

local function Spring(obj, props, duration)
    return Tween(obj, props, duration or 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- ============================================================
--  UTILITY HELPERS
-- ============================================================
local function Create(class, props, children)
    local inst = Instance.new(class)
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    if props and props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function MakeStroke(parent, thickness, color, transparency)
    return Create("UIStroke", {
        Parent       = parent,
        Thickness    = thickness or 1,
        Color        = color or Theme.BORDER,
        Transparency = transparency or 0,
    })
end

local function MakeCorner(parent, radius)
    return Create("UICorner", {
        Parent       = parent,
        CornerRadius = UDim.new(0, radius or 8),
    })
end

local function MakePadding(parent, t, b, l, r)
    return Create("UIPadding", {
        Parent          = parent,
        PaddingTop      = UDim.new(0, t or 6),
        PaddingBottom   = UDim.new(0, b or 6),
        PaddingLeft     = UDim.new(0, l or 6),
        PaddingRight    = UDim.new(0, r or 6),
    })
end

local function AddHoverEffect(btn, normalColor, hoverColor, stroke)
    btn.MouseEnter:Connect(function()
        Tween(btn, {BackgroundColor3 = hoverColor}, 0.15)
        if stroke then Tween(stroke, {Color = Theme.RED}, 0.15) end
    end)
    btn.MouseLeave:Connect(function()
        Tween(btn, {BackgroundColor3 = normalColor}, 0.15)
        if stroke then Tween(stroke, {Color = Theme.BORDER}, 0.15) end
    end)
end

local function RippleEffect(button)
    button.ClipsDescendants = true
    button.MouseButton1Down:Connect(function(x, y)
        local ripple = Create("Frame", {
            Parent              = button,
            BackgroundColor3    = Color3.fromRGB(255, 255, 255),
            BackgroundTransparency = 0.85,
            BorderSizePixel     = 0,
            ZIndex              = button.ZIndex + 10,
        })
        MakeCorner(ripple, 999)
        local pos = button.AbsolutePosition
        local size = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 2
        ripple.Size     = UDim2.new(0, 0, 0, 0)
        ripple.Position = UDim2.new(0, x - pos.X, 0, y - pos.Y)
        Tween(ripple, {
            Size     = UDim2.new(0, size, 0, size),
            Position = UDim2.new(0, x - pos.X - size/2, 0, y - pos.Y - size/2),
            BackgroundTransparency = 1,
        }, 0.5)
        task.delay(0.5, function() ripple:Destroy() end)
    end)
end

-- ============================================================
--  DRAGGING
-- ============================================================
local function MakeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos = false, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging  = true
            dragStart = input.Position
            startPos  = frame.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ============================================================
--  RESIZING
-- ============================================================
local function MakeResizable(frame, minW, minH)
    minW = minW or 500
    minH = minH or 350

    local handle = Create("TextButton", {
        Parent              = frame,
        Text                = "",
        Size                = UDim2.new(0, 18, 0, 18),
        Position            = UDim2.new(1, -18, 1, -18),
        BackgroundTransparency = 1,
        ZIndex              = frame.ZIndex + 20,
        AnchorPoint         = Vector2.new(0, 0),
    })

    -- resize icon
    Create("ImageLabel", {
        Parent              = handle,
        Size                = UDim2.new(1, -2, 1, -2),
        Position            = UDim2.new(0, 1, 0, 1),
        BackgroundTransparency = 1,
        Image               = "rbxassetid://6031094667",
        ImageColor3         = Theme.TEXT_MUTED,
    })

    local resizing, resizeStart, startSize = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing    = true
            resizeStart = input.Position
            startSize   = frame.AbsoluteSize
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            resizing = false
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - resizeStart
            local newW = math.max(minW, startSize.X + delta.X)
            local newH = math.max(minH, startSize.Y + delta.Y)
            frame.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
    return handle
end

-- ============================================================
--  NOTIFICATION SYSTEM
-- ============================================================
local NotifHolder

local function EnsureNotifHolder()
    if NotifHolder and NotifHolder.Parent then return end
    local sg = Create("ScreenGui", {
        Parent             = CoreGui,
        Name               = "ZENUNotifications",
        ResetOnSpawn       = false,
        ZIndexBehavior     = Enum.ZIndexBehavior.Sibling,
    })
    NotifHolder = Create("Frame", {
        Parent              = sg,
        BackgroundTransparency = 1,
        Size                = UDim2.new(0, 320, 1, 0),
        Position            = UDim2.new(1, -330, 0, 0),
        AnchorPoint         = Vector2.new(0, 0),
    })
    Create("UIListLayout", {
        Parent           = NotifHolder,
        FillDirection    = Enum.FillDirection.Vertical,
        VerticalAlignment= Enum.VerticalAlignment.Bottom,
        Padding          = UDim.new(0, 8),
        SortOrder        = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {
        Parent        = NotifHolder,
        PaddingBottom = UDim.new(0, 16),
        PaddingRight  = UDim.new(0, 10),
    })
end

function ZENUHub:Notify(options)
    EnsureNotifHolder()
    options = options or {}
    local title    = options.Title    or "ZENU Hub"
    local message  = options.Message  or ""
    local duration = options.Duration or 4
    local ntype    = options.Type     or "Info"  -- Info | Success | Error | Warn

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
        Size                = UDim2.new(1, 0, 0, 72),
        BorderSizePixel     = 0,
        BackgroundTransparency = 0.05,
        ClipsDescendants    = true,
    })
    MakeCorner(card, 10)
    MakeStroke(card, 1, Theme.BORDER)

    -- left accent strip
    Create("Frame", {
        Parent           = card,
        BackgroundColor3 = accent,
        Size             = UDim2.new(0, 3, 1, 0),
        BorderSizePixel  = 0,
    })
    MakeCorner(_, 0) -- suppress

    -- Title
    Create("TextLabel", {
        Parent            = card,
        Text              = title,
        Font              = Enum.Font.GothamBold,
        TextSize          = 13,
        TextColor3        = Theme.TEXT_PRIMARY,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, -52, 0, 20),
        Position          = UDim2.new(0, 14, 0, 10),
        TextXAlignment    = Enum.TextXAlignment.Left,
    })

    -- Message
    Create("TextLabel", {
        Parent            = card,
        Text              = message,
        Font              = Enum.Font.Gotham,
        TextSize          = 11,
        TextColor3        = Theme.TEXT_SECONDARY,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, -52, 0, 28),
        Position          = UDim2.new(0, 14, 0, 30),
        TextXAlignment    = Enum.TextXAlignment.Left,
        TextWrapped       = true,
    })

    -- Progress bar
    local bar = Create("Frame", {
        Parent           = card,
        BackgroundColor3 = accent,
        Size             = UDim2.new(1, 0, 0, 2),
        Position         = UDim2.new(0, 0, 1, -2),
        BorderSizePixel  = 0,
    })

    -- Slide in
    card.Position = UDim2.new(1, 10, 0, 0)
    Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.4, Enum.EasingStyle.Back)

    -- Progress shrink
    Tween(bar, {Size = UDim2.new(0, 0, 0, 2)}, duration, Enum.EasingStyle.Linear)

    -- Dismiss on click
    card.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            Tween(card, {Position = UDim2.new(1, 10, 0, 0), BackgroundTransparency = 1}, 0.3)
            task.delay(0.35, function() card:Destroy() end)
        end
    end)

    task.delay(duration, function()
        if card and card.Parent then
            Tween(card, {Position = UDim2.new(1, 10, 0, 0), BackgroundTransparency = 1}, 0.35)
            task.delay(0.4, function() if card then card:Destroy() end end)
        end
    end)
    return card
end

-- ============================================================
--  MAIN WINDOW CREATION
-- ============================================================
function ZENUHub:CreateWindow(options)
    options = options or {}
    local hubName    = options.Name        or "ZENU Hub"
    local hubDesc    = options.Description or "Advanced Scripting Hub"
    local initTab    = options.DefaultTab  or nil
    local sizeW      = options.Width       or 720
    local sizeH      = options.Height      or 480
    local discord    = options.Discord     or "discord.gg/zenuhub"

    -- Root ScreenGui
    local ScreenGui = Create("ScreenGui", {
        Parent             = CoreGui,
        Name               = "ZENUHub_" .. tostring(math.random(10000,99999)),
        ResetOnSpawn       = false,
        ZIndexBehavior     = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset     = true,
    })

    -- Blur overlay (subtle)
    local Blur = Create("BlurEffect", {
        Parent = game:GetService("Lighting"),
        Size   = 0,
    })

    -- ── Main Frame ──────────────────────────────────────────
    local MainFrame = Create("Frame", {
        Parent              = ScreenGui,
        BackgroundColor3    = Theme.BG_SECONDARY,
        Size                = UDim2.new(0, sizeW, 0, sizeH),
        Position            = UDim2.new(0.5, -sizeW/2, 0.5, -sizeH/2),
        BorderSizePixel     = 0,
        ClipsDescendants    = false,
    })
    MakeCorner(MainFrame, 12)
    MakeStroke(MainFrame, 1, Theme.BORDER_RED, 0.3)

    -- Drop shadow
    Create("ImageLabel", {
        Parent              = MainFrame,
        BackgroundTransparency = 1,
        Size                = UDim2.new(1, 60, 1, 60),
        Position            = UDim2.new(0, -30, 0, -30),
        ZIndex              = MainFrame.ZIndex - 1,
        Image               = "rbxassetid://5554236805",
        ImageColor3         = Color3.fromRGB(0, 0, 0),
        ImageTransparency   = 0.55,
        ScaleType           = Enum.ScaleType.Slice,
        SliceCenter         = Rect.new(23, 23, 277, 277),
    })

    -- ── HEADER ──────────────────────────────────────────────
    local Header = Create("Frame", {
        Parent           = MainFrame,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1, 0, 0, 52),
        BorderSizePixel  = 0,
        ZIndex           = 5,
    })
    -- round only top corners
    Create("UICorner", { Parent = Header, CornerRadius = UDim.new(0, 12) })
    -- fill bottom to merge
    Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1, 0, 0, 12),
        Position         = UDim2.new(0, 0, 1, -12),
        BorderSizePixel  = 0,
        ZIndex           = 4,
    })

    MakeDraggable(MainFrame, Header)

    -- Logo Z
    local LogoFrame = Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.RED,
        Size             = UDim2.new(0, 34, 0, 34),
        Position         = UDim2.new(0, 12, 0.5, -17),
        BorderSizePixel  = 0,
        ZIndex           = 6,
    })
    MakeCorner(LogoFrame, 8)
    Create("TextLabel", {
        Parent            = LogoFrame,
        Text              = "Z",
        Font              = Enum.Font.GothamBold,
        TextSize          = 20,
        TextColor3        = Color3.fromRGB(255, 255, 255),
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, 0, 1, 0),
        TextXAlignment    = Enum.TextXAlignment.Center,
        TextYAlignment    = Enum.TextYAlignment.Center,
        ZIndex            = 7,
    })

    -- Hub Name
    Create("TextLabel", {
        Parent            = Header,
        Text              = hubName,
        Font              = Enum.Font.GothamBold,
        TextSize          = 15,
        TextColor3        = Theme.TEXT_PRIMARY,
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 160, 0, 20),
        Position          = UDim2.new(0, 54, 0, 7),
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 6,
    })

    -- Hub Desc
    Create("TextLabel", {
        Parent            = Header,
        Text              = hubDesc,
        Font              = Enum.Font.Gotham,
        TextSize          = 10,
        TextColor3        = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 200, 0, 16),
        Position          = UDim2.new(0, 54, 0, 28),
        TextXAlignment    = Enum.TextXAlignment.Left,
        ZIndex            = 6,
    })

    -- Search Bar
    local SearchBox = Create("Frame", {
        Parent           = Header,
        BackgroundColor3 = Theme.BG_INPUT,
        Size             = UDim2.new(0, 180, 0, 28),
        Position         = UDim2.new(1, -290, 0.5, -14),
        BorderSizePixel  = 0,
        ZIndex           = 6,
    })
    MakeCorner(SearchBox, 6)
    MakeStroke(SearchBox, 1, Theme.BORDER)

    Create("TextLabel", {
        Parent            = SearchBox,
        Text              = "🔍",
        Font              = Enum.Font.Gotham,
        TextSize          = 12,
        TextColor3        = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(0, 22, 1, 0),
        Position          = UDim2.new(0, 4, 0, 0),
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
        Size              = UDim2.new(1, -30, 1, 0),
        Position          = UDim2.new(0, 26, 0, 0),
        TextXAlignment    = Enum.TextXAlignment.Left,
        ClearTextOnFocus  = false,
        ZIndex            = 7,
    })

    -- Window Controls
    local function MakeWinBtn(label, color, xPos)
        local btn = Create("TextButton", {
            Parent              = Header,
            Text                = label,
            Font                = Enum.Font.GothamBold,
            TextSize            = 10,
            TextColor3          = Color3.fromRGB(200, 200, 200),
            BackgroundColor3    = color,
            Size                = UDim2.new(0, 20, 0, 20),
            Position            = UDim2.new(1, xPos, 0.5, -10),
            BorderSizePixel     = 0,
            ZIndex              = 8,
        })
        MakeCorner(btn, 5)
        btn.MouseEnter:Connect(function()
            Tween(btn, {BackgroundColor3 = color:Lerp(Color3.fromRGB(255,255,255), 0.2)}, 0.1)
        end)
        btn.MouseLeave:Connect(function()
            Tween(btn, {BackgroundColor3 = color}, 0.1)
        end)
        return btn
    end

    local BtnClose    = MakeWinBtn("✕", Color3.fromRGB(200,50,50),  -28)
    local BtnMinimize = MakeWinBtn("—", Color3.fromRGB(50,50,65),   -56)
    local BtnExpand   = MakeWinBtn("⤢", Color3.fromRGB(50,50,65),   -84)

    -- ── BODY (Sidebar + Content) ─────────────────────────────
    local Body = Create("Frame", {
        Parent           = MainFrame,
        BackgroundTransparency = 1,
        Size             = UDim2.new(1, 0, 1, -52 - 24),  -- minus header & footer
        Position         = UDim2.new(0, 0, 0, 52),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })

    -- ── SIDEBAR ──────────────────────────────────────────────
    local Sidebar = Create("Frame", {
        Parent           = Body,
        BackgroundColor3 = Theme.BG_TERTIARY,
        Size             = UDim2.new(0, 52, 1, 0),
        BorderSizePixel  = 0,
    })

    -- separator line
    Create("Frame", {
        Parent           = Sidebar,
        BackgroundColor3 = Theme.SEPARATOR,
        Size             = UDim2.new(0, 1, 1, 0),
        Position         = UDim2.new(1, -1, 0, 0),
        BorderSizePixel  = 0,
    })

    local SidebarList = Create("ScrollingFrame", {
        Parent              = Sidebar,
        BackgroundTransparency = 1,
        Size                = UDim2.new(1, 0, 1, -8),
        Position            = UDim2.new(0, 0, 0, 8),
        ScrollBarThickness  = 0,
        BorderSizePixel     = 0,
        CanvasSize          = UDim2.new(0, 0, 0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
    })

    Create("UIListLayout", {
        Parent           = SidebarList,
        FillDirection    = Enum.FillDirection.Vertical,
        HorizontalAlignment= Enum.HorizontalAlignment.Center,
        Padding          = UDim.new(0, 4),
        SortOrder        = Enum.SortOrder.LayoutOrder,
    })
    Create("UIPadding", {
        Parent = SidebarList,
        PaddingTop = UDim.new(0,4),
        PaddingBottom = UDim.new(0,4),
    })

    -- ── CONTENT ──────────────────────────────────────────────
    local ContentArea = Create("Frame", {
        Parent           = Body,
        BackgroundColor3 = Theme.BG_SECONDARY,
        Size             = UDim2.new(1, -52, 1, 0),
        Position         = UDim2.new(0, 52, 0, 0),
        BorderSizePixel  = 0,
        ClipsDescendants = true,
    })

    -- ── FOOTER ───────────────────────────────────────────────
    local Footer = Create("Frame", {
        Parent           = MainFrame,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1, 0, 0, 24),
        Position         = UDim2.new(0, 0, 1, -24),
        BorderSizePixel  = 0,
    })
    -- round bottom corners
    Create("UICorner", {Parent = Footer, CornerRadius = UDim.new(0, 12)})
    Create("Frame", {
        Parent           = Footer,
        BackgroundColor3 = Theme.BG_PRIMARY,
        Size             = UDim2.new(1, 0, 0, 12),
        Position         = UDim2.new(0, 0, 0, 0),
        BorderSizePixel  = 0,
    })
    -- separator
    Create("Frame", {
        Parent           = Footer,
        BackgroundColor3 = Theme.SEPARATOR,
        Size             = UDim2.new(1, 0, 0, 1),
        Position         = UDim2.new(0, 0, 0, 0),
        BorderSizePixel  = 0,
    })

    Create("TextLabel", {
        Parent            = Footer,
        Text              = discord,
        Font              = Enum.Font.Gotham,
        TextSize          = 10,
        TextColor3        = Theme.TEXT_MUTED,
        BackgroundTransparency = 1,
        Size              = UDim2.new(1, -30, 1, 0),
        Position          = UDim2.new(0, 12, 0, 0),
        TextXAlignment    = Enum.TextXAlignment.Left,
    })

    MakeResizable(MainFrame, 480, 340)

    -- ── MINIMIZE SYSTEM ───────────────────────────────────────
    local minimized = false
    local fullSize  = MainFrame.Size

    BtnMinimize.MouseButton1Click:Connect(function()
        minimized = true
        fullSize  = MainFrame.Size
        Tween(MainFrame, {Size = UDim2.new(0, sizeW, 0, 52)}, 0.35, Enum.EasingStyle.Back)
        task.wait(0.1)
        Body.Visible   = false
        Footer.Visible = false
    end)

    BtnExpand.MouseButton1Click:Connect(function()
        if minimized then
            minimized       = false
            Body.Visible    = true
            Footer.Visible  = true
            Tween(MainFrame, {Size = fullSize}, 0.35, Enum.EasingStyle.Back)
        end
    end)

    BtnClose.MouseButton1Click:Connect(function()
        Tween(MainFrame, {Size = UDim2.new(0, sizeW, 0, 0), BackgroundTransparency = 1}, 0.3)
        task.delay(0.35, function()
            ScreenGui:Destroy()
            Blur:Destroy()
        end)
    end)

    -- Animate in
    MainFrame.Size = UDim2.new(0, sizeW, 0, 0)
    MainFrame.BackgroundTransparency = 0.8
    Spring(MainFrame, {Size = UDim2.new(0, sizeW, 0, sizeH), BackgroundTransparency = 0}, 0.45)

    -- ── TAB SYSTEM ────────────────────────────────────────────
    local Window = {}
    Window._tabs       = {}
    Window._activeTab  = nil
    Window._mainFrame  = MainFrame
    Window._screenGui  = ScreenGui
    Window._searchInput = SearchInput

    -- Search functionality
    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchInput.Text:lower()
        for _, tab in pairs(Window._tabs) do
            if tab._page then
                for _, section in pairs(tab._sections or {}) do
                    for _, item in pairs(section._items or {}) do
                        if item._frame then
                            local visible = query == "" or
                                (item._label and item._label:lower():find(query, 1, true))
                            item._frame.Visible = visible
                        end
                    end
                end
            end
        end
    end)

    -- ── ADD TAB ───────────────────────────────────────────────
    function Window:AddTab(options)
        options = options or {}
        local tabName = options.Name  or "Tab"
        local tabIcon = options.Icon  or "☰"

        -- Sidebar icon button
        local IconBtn = Create("TextButton", {
            Parent              = SidebarList,
            Text                = tabIcon,
            Font                = Enum.Font.GothamBold,
            TextSize            = 16,
            TextColor3          = Theme.TEXT_MUTED,
            BackgroundColor3    = Theme.BG_TERTIARY,
            Size                = UDim2.new(0, 38, 0, 38),
            BorderSizePixel     = 0,
            ZIndex              = 6,
        })
        MakeCorner(IconBtn, 8)

        -- Tooltip
        local Tooltip = Create("Frame", {
            Parent              = IconBtn,
            BackgroundColor3    = Theme.BG_CARD,
            Size                = UDim2.new(0, 0, 0, 24),
            Position            = UDim2.new(1, 6, 0.5, -12),
            BorderSizePixel     = 0,
            Visible             = false,
            ZIndex              = 20,
            ClipsDescendants    = true,
        })
        MakeCorner(Tooltip, 5)
        MakeStroke(Tooltip, 1, Theme.BORDER)
        local TooltipLabel = Create("TextLabel", {
            Parent              = Tooltip,
            Text                = tabName,
            Font                = Enum.Font.GothamBold,
            TextSize            = 11,
            TextColor3          = Theme.TEXT_PRIMARY,
            BackgroundTransparency = 1,
            Size                = UDim2.new(1, -12, 1, 0),
            Position            = UDim2.new(0, 6, 0, 0),
            ZIndex              = 21,
        })

        local textSize = TextService:GetTextSize(tabName, 11, Enum.Font.GothamBold, Vector2.new(999,24))
        Tooltip.Size = UDim2.new(0, textSize.X + 12, 0, 24)

        IconBtn.MouseEnter:Connect(function()
            Tooltip.Visible = true
            Tween(IconBtn, {TextColor3 = Theme.RED}, 0.15)
        end)
        IconBtn.MouseLeave:Connect(function()
            Tooltip.Visible = false
        end)

        -- Active indicator
        local ActiveBar = Create("Frame", {
            Parent           = IconBtn,
            BackgroundColor3 = Theme.RED,
            Size             = UDim2.new(0, 3, 0, 20),
            Position         = UDim2.new(0, -3, 0.5, -10),
            BorderSizePixel  = 0,
            Visible          = false,
        })
        MakeCorner(ActiveBar, 2)

        -- Page (content frame for this tab)
        local Page = Create("ScrollingFrame", {
            Parent              = ContentArea,
            BackgroundTransparency = 1,
            Size                = UDim2.new(1, 0, 1, 0),
            BorderSizePixel     = 0,
            ScrollBarThickness  = 3,
            ScrollBarImageColor3 = Theme.RED,
            CanvasSize          = UDim2.new(0, 0, 0, 0),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            Visible             = false,
        })

        Create("UIListLayout", {
            Parent           = Page,
            FillDirection    = Enum.FillDirection.Vertical,
            Padding          = UDim.new(0, 8),
            SortOrder        = Enum.SortOrder.LayoutOrder,
        })
        Create("UIPadding", {
            Parent        = Page,
            PaddingTop    = UDim.new(0, 10),
            PaddingBottom = UDim.new(0, 10),
            PaddingLeft   = UDim.new(0, 10),
            PaddingRight  = UDim.new(0, 10),
        })

        local Tab = {
            _name     = tabName,
            _btn      = IconBtn,
            _page     = Page,
            _bar      = ActiveBar,
            _sections = {},
        }

        local function SelectTab()
            -- deselect previous
            if Window._activeTab then
                Window._activeTab._page.Visible = false
                Tween(Window._activeTab._btn, {TextColor3 = Theme.TEXT_MUTED, BackgroundColor3 = Theme.BG_TERTIARY}, 0.15)
                Window._activeTab._bar.Visible = false
            end
            -- select this
            Tab._page.Visible = true
            Tween(IconBtn, {TextColor3 = Theme.TEXT_PRIMARY, BackgroundColor3 = Theme.BG_CARD}, 0.15)
            Tab._bar.Visible = true
            Window._activeTab = Tab
        end

        IconBtn.MouseButton1Click:Connect(SelectTab)

        -- auto-select first tab
        if #Window._tabs == 0 or tabName == initTab then
            SelectTab()
        end

        table.insert(Window._tabs, Tab)

        -- ── ADD SECTION (Card) ────────────────────────────────
        function Tab:AddSection(options)
            options = options or {}
            local secName    = options.Name      or "Section"
            local secIcon    = options.Icon      or nil
            local collapsed  = options.Collapsed or false

            local Card = Create("Frame", {
                Parent           = Page,
                BackgroundColor3 = Theme.BG_CARD,
                Size             = UDim2.new(1, 0, 0, 0),
                AutomaticSize    = Enum.AutomaticSize.Y,
                BorderSizePixel  = 0,
                ClipsDescendants = true,
            })
            MakeCorner(Card, 10)
            MakeStroke(Card, 1, Theme.BORDER)

            -- Card header
            local CardHeader = Create("TextButton", {
                Parent           = Card,
                BackgroundColor3 = Theme.BG_CARD,
                Size             = UDim2.new(1, 0, 0, 36),
                Text             = "",
                BorderSizePixel  = 0,
                ZIndex           = 3,
            })
            MakeCorner(CardHeader, 10)

            -- Icon (if any)
            local xOff = 12
            if secIcon then
                Create("TextLabel", {
                    Parent            = CardHeader,
                    Text              = secIcon,
                    Font              = Enum.Font.GothamBold,
                    TextSize          = 14,
                    TextColor3        = Theme.RED,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(0, 20, 1, 0),
                    Position          = UDim2.new(0, 10, 0, 0),
                    TextXAlignment    = Enum.TextXAlignment.Center,
                    ZIndex            = 4,
                })
                xOff = 34
            end

            Create("TextLabel", {
                Parent            = CardHeader,
                Text              = secName,
                Font              = Enum.Font.GothamBold,
                TextSize          = 12,
                TextColor3        = Theme.TEXT_PRIMARY,
                BackgroundTransparency = 1,
                Size              = UDim2.new(1, -50, 1, 0),
                Position          = UDim2.new(0, xOff, 0, 0),
                TextXAlignment    = Enum.TextXAlignment.Left,
                ZIndex            = 4,
            })

            -- Chevron
            local Chevron = Create("TextLabel", {
                Parent            = CardHeader,
                Text              = collapsed and "›" or "⌄",
                Font              = Enum.Font.GothamBold,
                TextSize          = 14,
                TextColor3        = Theme.TEXT_MUTED,
                BackgroundTransparency = 1,
                Size              = UDim2.new(0, 20, 1, 0),
                Position          = UDim2.new(1, -26, 0, 0),
                TextXAlignment    = Enum.TextXAlignment.Center,
                ZIndex            = 4,
            })

            -- Items container
            local ItemsFrame = Create("Frame", {
                Parent              = Card,
                BackgroundTransparency = 1,
                Size                = UDim2.new(1, 0, 0, 0),
                Position            = UDim2.new(0, 0, 0, 36),
                AutomaticSize       = Enum.AutomaticSize.Y,
                BorderSizePixel     = 0,
                Visible             = not collapsed,
            })

            Create("UIListLayout", {
                Parent        = ItemsFrame,
                FillDirection = Enum.FillDirection.Vertical,
                Padding       = UDim.new(0, 4),
                SortOrder     = Enum.SortOrder.LayoutOrder,
            })
            MakePadding(ItemsFrame, 4, 8, 10, 10)

            -- Collapse toggle
            local isCollapsed = collapsed
            CardHeader.MouseButton1Click:Connect(function()
                isCollapsed = not isCollapsed
                ItemsFrame.Visible = not isCollapsed
                Chevron.Text = isCollapsed and "›" or "⌄"
                Tween(CardHeader, {BackgroundColor3 = isCollapsed and Theme.BG_CARD_HOVER or Theme.BG_CARD}, 0.15)
            end)

            AddHoverEffect(CardHeader, Theme.BG_CARD, Theme.BG_CARD_HOVER)

            local Section = { _items = {} }
            table.insert(Tab._sections, Section)

            -- ── TOGGLE ───────────────────────────────────────
            function Section:AddToggle(options)
                options = options or {}
                local label    = options.Name     or "Toggle"
                local default  = options.Default  or false
                local callback = options.Callback or function() end
                local flag     = options.Flag     or nil

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1, 0, 0, 32),
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
                    Size              = UDim2.new(1, -60, 1, 0),
                    Position          = UDim2.new(0, 10, 0, 0),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                })

                local Track = Create("TextButton", {
                    Parent              = Row,
                    Text                = "",
                    BackgroundColor3    = default and Theme.TOGGLE_ON or Theme.TOGGLE_OFF,
                    Size                = UDim2.new(0, 40, 0, 20),
                    Position            = UDim2.new(1, -48, 0.5, -10),
                    BorderSizePixel     = 0,
                    ZIndex              = 3,
                })
                MakeCorner(Track, 10)

                local Knob = Create("Frame", {
                    Parent              = Track,
                    BackgroundColor3    = Theme.TOGGLE_KNOB,
                    Size                = UDim2.new(0, 14, 0, 14),
                    Position            = default and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7),
                    BorderSizePixel     = 0,
                    ZIndex              = 4,
                })
                MakeCorner(Knob, 7)

                local state = default
                local item  = {_frame = Row, _label = label, Value = state}

                local function SetState(v, fireCallback)
                    state = v
                    item.Value = v
                    Tween(Track, {BackgroundColor3 = v and Theme.TOGGLE_ON or Theme.TOGGLE_OFF}, 0.2)
                    Tween(Knob,  {Position = v and UDim2.new(1,-17,0.5,-7) or UDim2.new(0,3,0.5,-7)}, 0.2, Enum.EasingStyle.Back)
                    if fireCallback ~= false then callback(v) end
                    if flag then ZENUHub.Flags = ZENUHub.Flags or {}; ZENUHub.Flags[flag] = v end
                end

                Track.MouseButton1Click:Connect(function() SetState(not state) end)
                AddHoverEffect(Row, Theme.BG_CARD, Theme.BG_CARD_HOVER)

                function item:Set(v) SetState(v, false) end
                table.insert(Section._items, item)
                return item
            end

            -- ── BUTTON ───────────────────────────────────────
            function Section:AddButton(options)
                options = options or {}
                local label    = options.Name     or "Button"
                local callback = options.Callback or function() end

                local Btn = Create("TextButton", {
                    Parent              = ItemsFrame,
                    Text                = label,
                    Font                = Enum.Font.GothamBold,
                    TextSize            = 12,
                    TextColor3          = Theme.TEXT_PRIMARY,
                    BackgroundColor3    = Theme.RED_DARK,
                    Size                = UDim2.new(1, 0, 0, 32),
                    BorderSizePixel     = 0,
                })
                MakeCorner(Btn, 6)
                RippleEffect(Btn)

                Btn.MouseEnter:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.RED}, 0.15) end)
                Btn.MouseLeave:Connect(function() Tween(Btn, {BackgroundColor3 = Theme.RED_DARK}, 0.15) end)
                Btn.MouseButton1Click:Connect(function()
                    Tween(Btn, {BackgroundColor3 = Theme.RED_BRIGHT}, 0.07)
                    task.delay(0.07, function() Tween(Btn, {BackgroundColor3 = Theme.RED}, 0.12) end)
                    callback()
                end)

                local item = {_frame = Btn, _label = label}
                table.insert(Section._items, item)
                return item
            end

            -- ── SLIDER ───────────────────────────────────────
            function Section:AddSlider(options)
                options = options or {}
                local label    = options.Name     or "Slider"
                local min      = options.Min      or 0
                local max      = options.Max      or 100
                local default  = options.Default  or min
                local suffix   = options.Suffix   or ""
                local callback = options.Callback or function() end
                local flag     = options.Flag     or nil

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1, 0, 0, 48),
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
                    Size              = UDim2.new(0.6, 0, 0, 22),
                    Position          = UDim2.new(0, 10, 0, 4),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                })

                local ValLabel = Create("TextLabel", {
                    Parent            = Row,
                    Text              = tostring(default) .. suffix,
                    Font              = Enum.Font.GothamBold,
                    TextSize          = 12,
                    TextColor3        = Theme.RED,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(0.4, -10, 0, 22),
                    Position          = UDim2.new(0.6, 0, 0, 4),
                    TextXAlignment    = Enum.TextXAlignment.Right,
                })

                local Track = Create("Frame", {
                    Parent           = Row,
                    BackgroundColor3 = Theme.SLIDER_TRACK,
                    Size             = UDim2.new(1, -20, 0, 4),
                    Position         = UDim2.new(0, 10, 1, -16),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Track, 2)

                local Fill = Create("Frame", {
                    Parent           = Track,
                    BackgroundColor3 = Theme.SLIDER_FILL,
                    Size             = UDim2.new((default-min)/(max-min), 0, 1, 0),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Fill, 2)

                local Thumb = Create("Frame", {
                    Parent              = Track,
                    BackgroundColor3    = Theme.SLIDER_THUMB,
                    Size                = UDim2.new(0, 12, 0, 12),
                    Position            = UDim2.new((default-min)/(max-min), -6, 0.5, -6),
                    BorderSizePixel     = 0,
                    ZIndex              = 3,
                })
                MakeCorner(Thumb, 6)
                MakeStroke(Thumb, 1.5, Theme.SLIDER_FILL)

                local value = default
                local dragging = false
                local item = {_frame = Row, _label = label, Value = value}

                local function UpdateSlider(inputX)
                    local abs = Track.AbsolutePosition
                    local sz  = Track.AbsoluteSize
                    local pct = math.clamp((inputX - abs.X) / sz.X, 0, 1)
                    value = math.round(min + pct * (max - min))
                    item.Value = value
                    local fpct = (value - min) / (max - min)
                    Tween(Fill,  {Size     = UDim2.new(fpct, 0, 1, 0)},              0.05, Enum.EasingStyle.Linear)
                    Tween(Thumb, {Position = UDim2.new(fpct, -6, 0.5, -6)},         0.05, Enum.EasingStyle.Linear)
                    ValLabel.Text = tostring(value) .. suffix
                    callback(value)
                    if flag then ZENUHub.Flags = ZENUHub.Flags or {}; ZENUHub.Flags[flag] = value end
                end

                Track.InputBegan:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then
                        dragging = true
                        UpdateSlider(inp.Position.X)
                    end
                end)
                UserInputService.InputEnded:Connect(function(inp)
                    if inp.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(inp)
                    if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
                        UpdateSlider(inp.Position.X)
                    end
                end)

                AddHoverEffect(Row, Theme.BG_CARD, Theme.BG_CARD_HOVER)

                function item:Set(v)
                    value = math.clamp(v, min, max)
                    local fpct = (value - min) / (max - min)
                    Fill.Size     = UDim2.new(fpct, 0, 1, 0)
                    Thumb.Position = UDim2.new(fpct, -6, 0.5, -6)
                    ValLabel.Text = tostring(value) .. suffix
                end

                table.insert(Section._items, item)
                return item
            end

            -- ── TEXTBOX ──────────────────────────────────────
            function Section:AddTextbox(options)
                options = options or {}
                local label       = options.Name        or "Textbox"
                local placeholder = options.Placeholder or "Enter text..."
                local default     = options.Default     or ""
                local callback    = options.Callback    or function() end
                local flag        = options.Flag        or nil

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1, 0, 0, 54),
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
                    Size              = UDim2.new(1, -20, 0, 18),
                    Position          = UDim2.new(0, 10, 0, 6),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                })

                local InputFrame = Create("Frame", {
                    Parent           = Row,
                    BackgroundColor3 = Theme.BG_INPUT,
                    Size             = UDim2.new(1, -20, 0, 24),
                    Position         = UDim2.new(0, 10, 0, 24),
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
                    Size              = UDim2.new(1, -12, 1, 0),
                    Position          = UDim2.new(0, 6, 0, 0),
                    ClearTextOnFocus  = false,
                    ZIndex            = 3,
                })

                Input.Focused:Connect(function()  Tween(stroke, {Color = Theme.RED}, 0.15) end)
                Input.FocusLost:Connect(function() Tween(stroke, {Color = Theme.BORDER}, 0.15); callback(Input.Text) end)

                local item = {_frame = Row, _label = label, Value = Input.Text}
                Input:GetPropertyChangedSignal("Text"):Connect(function()
                    item.Value = Input.Text
                    if flag then ZENUHub.Flags = ZENUHub.Flags or {}; ZENUHub.Flags[flag] = Input.Text end
                end)

                table.insert(Section._items, item)
                return item
            end

            -- ── DROPDOWN ─────────────────────────────────────
            function Section:AddDropdown(options)
                options = options or {}
                local label    = options.Name     or "Dropdown"
                local items    = options.Items    or {}
                local default  = options.Default  or nil
                local callback = options.Callback or function() end
                local flag     = options.Flag     or nil

                local selected = default or (items[1] or "None")

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1, 0, 0, 56),
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
                    Size              = UDim2.new(1, -20, 0, 18),
                    Position          = UDim2.new(0, 10, 0, 6),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    ZIndex            = 6,
                })

                local DropBtn = Create("TextButton", {
                    Parent              = Row,
                    Text                = "",
                    BackgroundColor3    = Theme.BG_INPUT,
                    Size                = UDim2.new(1, -20, 0, 26),
                    Position            = UDim2.new(0, 10, 0, 24),
                    BorderSizePixel     = 0,
                    ZIndex              = 6,
                    ClipsDescendants    = false,
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
                    Size              = UDim2.new(1, -28, 1, 0),
                    Position          = UDim2.new(0, 8, 0, 0),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    ZIndex            = 7,
                })

                Create("TextLabel", {
                    Parent            = DropBtn,
                    Text              = "⌄",
                    Font              = Enum.Font.GothamBold,
                    TextSize          = 12,
                    TextColor3        = Theme.TEXT_MUTED,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(0, 22, 1, 0),
                    Position          = UDim2.new(1, -24, 0, 0),
                    TextXAlignment    = Enum.TextXAlignment.Center,
                    ZIndex            = 7,
                })

                -- Drop list
                local DropList = Create("Frame", {
                    Parent              = DropBtn,
                    BackgroundColor3    = Theme.BG_DROPDOWN,
                    Size                = UDim2.new(1, 0, 0, 0),
                    Position            = UDim2.new(0, 0, 1, 4),
                    BorderSizePixel     = 0,
                    Visible             = false,
                    ZIndex              = 50,
                    ClipsDescendants    = true,
                })
                MakeCorner(DropList, 6)
                MakeStroke(DropList, 1, Theme.BORDER)

                -- Search inside dropdown
                local SearchRow = Create("Frame", {
                    Parent           = DropList,
                    BackgroundColor3 = Theme.BG_INPUT,
                    Size             = UDim2.new(1, -12, 0, 22),
                    Position         = UDim2.new(0, 6, 0, 6),
                    BorderSizePixel  = 0,
                    ZIndex           = 51,
                })
                MakeCorner(SearchRow, 4)
                MakeStroke(SearchRow, 1, Theme.BORDER)

                local SearchDD = Create("TextBox", {
                    Parent            = SearchRow,
                    Text              = "",
                    PlaceholderText   = "Search...",
                    Font              = Enum.Font.Gotham,
                    TextSize          = 10,
                    TextColor3        = Theme.TEXT_PRIMARY,
                    PlaceholderColor3 = Theme.TEXT_MUTED,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1, -8, 1, 0),
                    Position          = UDim2.new(0, 4, 0, 0),
                    ClearTextOnFocus  = false,
                    ZIndex            = 52,
                })

                local ItemList = Create("ScrollingFrame", {
                    Parent              = DropList,
                    BackgroundTransparency = 1,
                    Size                = UDim2.new(1, 0, 1, -36),
                    Position            = UDim2.new(0, 0, 0, 34),
                    ScrollBarThickness  = 2,
                    ScrollBarImageColor3 = Theme.RED,
                    BorderSizePixel     = 0,
                    CanvasSize          = UDim2.new(0, 0, 0, 0),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ZIndex              = 51,
                })
                Create("UIListLayout", {Parent = ItemList, Padding = UDim.new(0,2), SortOrder = Enum.SortOrder.LayoutOrder})
                MakePadding(ItemList, 2, 2, 4, 4)

                local allItemBtns = {}
                local function BuildItems(filter)
                    for _, v in ipairs(allItemBtns) do v:Destroy() end
                    allItemBtns = {}
                    for _, it in ipairs(items) do
                        if filter == "" or it:lower():find(filter:lower(), 1, true) then
                            local ib = Create("TextButton", {
                                Parent              = ItemList,
                                Text                = it,
                                Font                = Enum.Font.Gotham,
                                TextSize            = 11,
                                TextColor3          = Theme.TEXT_PRIMARY,
                                BackgroundColor3    = Theme.BG_DROPDOWN,
                                Size                = UDim2.new(1, 0, 0, 24),
                                BorderSizePixel     = 0,
                                TextXAlignment      = Enum.TextXAlignment.Left,
                                ZIndex              = 52,
                            })
                            MakeCorner(ib, 4)
                            MakePadding(ib, 0, 0, 6, 6)
                            ib.MouseEnter:Connect(function() Tween(ib, {BackgroundColor3 = Theme.BG_CARD_HOVER}, 0.1) end)
                            ib.MouseLeave:Connect(function() Tween(ib, {BackgroundColor3 = Theme.BG_DROPDOWN}, 0.1) end)
                            ib.MouseButton1Click:Connect(function()
                                selected = it
                                SelLabel.Text = it
                                DropList.Visible = false
                                callback(it)
                                if flag then ZENUHub.Flags = ZENUHub.Flags or {}; ZENUHub.Flags[flag] = it end
                            end)
                            table.insert(allItemBtns, ib)
                        end
                    end
                end

                BuildItems("")
                SearchDD:GetPropertyChangedSignal("Text"):Connect(function() BuildItems(SearchDD.Text) end)

                local open = false
                DropBtn.MouseButton1Click:Connect(function()
                    open = not open
                    DropList.Visible = open
                    if open then
                        local h = math.min(#items * 26 + 44, 150)
                        DropList.Size = UDim2.new(1, 0, 0, h)
                        SearchDD.Text = ""
                        BuildItems("")
                    end
                end)

                local item = {_frame = Row, _label = label, Value = selected}
                function item:Set(v)
                    selected = v
                    SelLabel.Text = v
                    item.Value = v
                end
                function item:Refresh(newItems)
                    items = newItems
                    BuildItems(SearchDD.Text)
                end

                table.insert(Section._items, item)
                return item
            end

            -- ── MULTI-DROPDOWN ────────────────────────────────
            function Section:AddMultiDropdown(options)
                options = options or {}
                local label    = options.Name     or "Multi Select"
                local items    = options.Items    or {}
                local defaults = options.Default  or {}
                local callback = options.Callback or function() end

                local selected = {}
                for _, v in ipairs(defaults) do selected[v] = true end

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1, 0, 0, 56),
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
                    Size              = UDim2.new(1, -20, 0, 18),
                    Position          = UDim2.new(0, 10, 0, 6),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    ZIndex            = 6,
                })

                local DropBtn = Create("TextButton", {
                    Parent              = Row,
                    Text                = "",
                    BackgroundColor3    = Theme.BG_INPUT,
                    Size                = UDim2.new(1, -20, 0, 26),
                    Position            = UDim2.new(0, 10, 0, 24),
                    BorderSizePixel     = 0,
                    ZIndex              = 6,
                    ClipsDescendants    = false,
                })
                MakeCorner(DropBtn, 5)
                MakeStroke(DropBtn, 1, Theme.BORDER)

                local function GetSelectedText()
                    local t = {}
                    for k in pairs(selected) do table.insert(t, k) end
                    return #t == 0 and "None" or table.concat(t, ", ")
                end

                local SelLabel = Create("TextLabel", {
                    Parent            = DropBtn,
                    Text              = GetSelectedText(),
                    Font              = Enum.Font.Gotham,
                    TextSize          = 10,
                    TextColor3        = Theme.TEXT_PRIMARY,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1, -28, 1, 0),
                    Position          = UDim2.new(0, 8, 0, 0),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    TextTruncate      = Enum.TextTruncate.AtEnd,
                    ZIndex            = 7,
                })

                Create("TextLabel", {Parent=DropBtn,Text="⌄",Font=Enum.Font.GothamBold,TextSize=12,
                    TextColor3=Theme.TEXT_MUTED,BackgroundTransparency=1,Size=UDim2.new(0,22,1,0),
                    Position=UDim2.new(1,-24,0,0),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=7})

                local DropList = Create("Frame", {
                    Parent=DropBtn,BackgroundColor3=Theme.BG_DROPDOWN,
                    Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,1,4),
                    BorderSizePixel=0,Visible=false,ZIndex=50,ClipsDescendants=true,
                })
                MakeCorner(DropList,6); MakeStroke(DropList,1,Theme.BORDER)

                local SearchRow=Create("Frame",{Parent=DropList,BackgroundColor3=Theme.BG_INPUT,
                    Size=UDim2.new(1,-12,0,22),Position=UDim2.new(0,6,0,6),BorderSizePixel=0,ZIndex=51})
                MakeCorner(SearchRow,4); MakeStroke(SearchRow,1,Theme.BORDER)
                local SearchDD=Create("TextBox",{Parent=SearchRow,Text="",PlaceholderText="Search...",
                    Font=Enum.Font.Gotham,TextSize=10,TextColor3=Theme.TEXT_PRIMARY,PlaceholderColor3=Theme.TEXT_MUTED,
                    BackgroundTransparency=1,Size=UDim2.new(1,-8,1,0),Position=UDim2.new(0,4,0,0),
                    ClearTextOnFocus=false,ZIndex=52})

                local ItemList=Create("ScrollingFrame",{Parent=DropList,BackgroundTransparency=1,
                    Size=UDim2.new(1,0,1,-36),Position=UDim2.new(0,0,0,34),ScrollBarThickness=2,
                    ScrollBarImageColor3=Theme.RED,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),
                    AutomaticCanvasSize=Enum.AutomaticSize.Y,ZIndex=51})
                Create("UIListLayout",{Parent=ItemList,Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder})
                MakePadding(ItemList,2,2,4,4)

                local allIBtns={}
                local function BuildMD(filter)
                    for _,v in ipairs(allIBtns) do v:Destroy() end
                    allIBtns={}
                    for _,it in ipairs(items) do
                        if filter=="" or it:lower():find(filter:lower(),1,true) then
                            local iRow=Create("Frame",{Parent=ItemList,BackgroundColor3=selected[it] and Theme.RED_DARK or Theme.BG_DROPDOWN,
                                Size=UDim2.new(1,0,0,24),BorderSizePixel=0,ZIndex=52})
                            MakeCorner(iRow,4)
                            Create("TextLabel",{Parent=iRow,Text=it,Font=Enum.Font.Gotham,TextSize=11,
                                TextColor3=Theme.TEXT_PRIMARY,BackgroundTransparency=1,Size=UDim2.new(1,-30,1,0),
                                Position=UDim2.new(0,8,0,0),TextXAlignment=Enum.TextXAlignment.Left,ZIndex=53})
                            Create("TextLabel",{Parent=iRow,Text=selected[it] and "✓" or "",Font=Enum.Font.GothamBold,
                                TextSize=11,TextColor3=Theme.RED,BackgroundTransparency=1,Size=UDim2.new(0,22,1,0),
                                Position=UDim2.new(1,-24,0,0),TextXAlignment=Enum.TextXAlignment.Center,ZIndex=53})
                            local ib2=Create("TextButton",{Parent=iRow,Text="",BackgroundTransparency=1,
                                Size=UDim2.new(1,0,1,0),ZIndex=54})
                            ib2.MouseButton1Click:Connect(function()
                                selected[it]=not selected[it]
                                SelLabel.Text=GetSelectedText()
                                callback(selected)
                                BuildMD(SearchDD.Text)
                            end)
                            table.insert(allIBtns,iRow)
                        end
                    end
                end

                BuildMD("")
                SearchDD:GetPropertyChangedSignal("Text"):Connect(function() BuildMD(SearchDD.Text) end)

                local open=false
                DropBtn.MouseButton1Click:Connect(function()
                    open=not open; DropList.Visible=open
                    if open then
                        local h=math.min(#items*26+44,150)
                        DropList.Size=UDim2.new(1,0,0,h)
                        SearchDD.Text=""; BuildMD("")
                    end
                end)

                local item={_frame=Row,_label=label,Value=selected}
                table.insert(Section._items,item)
                return item
            end

            -- ── LABEL ────────────────────────────────────────
            function Section:AddLabel(options)
                options = options or {}
                local text  = options.Text  or "Label"
                local color = options.Color or Theme.TEXT_SECONDARY
                local size  = options.TextSize or 11

                local Lbl = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1, 0, 0, 28),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Lbl, 5)
                MakeStroke(Lbl, 1, Theme.SEPARATOR)

                local LblText = Create("TextLabel", {
                    Parent            = Lbl,
                    Text              = text,
                    Font              = Enum.Font.Gotham,
                    TextSize          = size,
                    TextColor3        = color,
                    BackgroundTransparency = 1,
                    Size              = UDim2.new(1, -16, 1, 0),
                    Position          = UDim2.new(0, 8, 0, 0),
                    TextXAlignment    = Enum.TextXAlignment.Left,
                    TextWrapped       = true,
                    RichText          = true,
                })

                local item = {
                    _frame = Lbl,
                    _label = text,
                    SetText = function(self, t) LblText.Text = t end
                }
                table.insert(Section._items, item)
                return item
            end

            -- ── KEYBIND ──────────────────────────────────────
            function Section:AddKeybind(options)
                options = options or {}
                local label    = options.Name     or "Keybind"
                local default  = options.Default  or Enum.KeyCode.Unknown
                local callback = options.Callback or function() end

                local key = default
                local listening = false

                local Row = Create("Frame", {
                    Parent           = ItemsFrame,
                    BackgroundColor3 = Theme.BG_CARD,
                    Size             = UDim2.new(1, 0, 0, 32),
                    BorderSizePixel  = 0,
                })
                MakeCorner(Row, 6)

                Create("TextLabel", {Parent=Row,Text=label,Font=Enum.Font.Gotham,TextSize=12,
                    TextColor3=Theme.TEXT_PRIMARY,BackgroundTransparency=1,
                    Size=UDim2.new(1,-90,1,0),Position=UDim2.new(0,10,0,0),
                    TextXAlignment=Enum.TextXAlignment.Left})

                local KbBtn = Create("TextButton", {
                    Parent              = Row,
                    Text                = key == Enum.KeyCode.Unknown and "NONE" or key.Name,
                    Font                = Enum.Font.GothamBold,
                    TextSize            = 10,
                    TextColor3          = Theme.RED,
                    BackgroundColor3    = Theme.BG_INPUT,
                    Size                = UDim2.new(0, 70, 0, 20),
                    Position            = UDim2.new(1, -78, 0.5, -10),
                    BorderSizePixel     = 0,
                    ZIndex              = 3,
                })
                MakeCorner(KbBtn, 4)
                MakeStroke(KbBtn, 1, Theme.BORDER)

                KbBtn.MouseButton1Click:Connect(function()
                    listening = true
                    KbBtn.Text = "..."
                    Tween(KbBtn, {TextColor3 = Theme.TEXT_PRIMARY}, 0.1)
                end)

                UserInputService.InputBegan:Connect(function(inp, gpe)
                    if gpe then return end
                    if inp.UserInputType == Enum.UserInputType.Keyboard then
                        if listening then
                            listening = false
                            key = inp.KeyCode
                            KbBtn.Text = key.Name
                            Tween(KbBtn, {TextColor3 = Theme.RED}, 0.1)
                        else
                            if inp.KeyCode == key then callback() end
                        end
                    end
                end)

                AddHoverEffect(Row, Theme.BG_CARD, Theme.BG_CARD_HOVER)
                local item = {_frame = Row, _label = label, Value = key}
                table.insert(Section._items, item)
                return item
            end

            return Section
        end

        return Tab
    end

    return Window
end

-- ============================================================
--  FLAGS (global state)
-- ============================================================
ZENUHub.Flags = {}

-- ============================================================
--  RETURN LIBRARY
-- ============================================================
return ZENUHub


--[[
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   USAGE EXAMPLE  (paste below or in a separate script)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

local ZENUHub = loadstring(game:HttpGet("YOUR_RAW_URL_HERE"))()

-- ── Create Window ──────────────────────────────────
local Window = ZENUHub:CreateWindow({
    Name        = "ZENU Hub",
    Description = "Advanced Scripting Hub",
    Discord     = "discord.gg/zenuhub",
    Width       = 720,
    Height      = 480,
})

-- ── Add Tabs ───────────────────────────────────────
local HomeTab = Window:AddTab({ Name = "Home",    Icon = "🏠" })
local FarmTab = Window:AddTab({ Name = "Farming", Icon = "⚔️" })
local PVPTab  = Window:AddTab({ Name = "PVP",     Icon = "🛡️" })
local MiscTab = Window:AddTab({ Name = "Misc",    Icon = "⚙️" })

-- ── Home Tab ───────────────────────────────────────
local WelcomeSec = HomeTab:AddSection({ Name = "Welcome", Icon = "★" })
WelcomeSec:AddLabel({ Text = "<b>Welcome to ZENU Hub!</b> — v2.0", Color = Color3.fromRGB(220,30,30) })
WelcomeSec:AddLabel({ Text = "Use the sidebar icons to navigate between tabs." })

-- ── Farming Tab ────────────────────────────────────
local FarmSec = FarmTab:AddSection({ Name = "Auto Farm", Icon = "⚔️" })

local autoFarm = FarmSec:AddToggle({
    Name     = "Auto Farm",
    Default  = false,
    Flag     = "AutoFarm",
    Callback = function(v)
        print("Auto Farm:", v)
        ZENUHub:Notify({
            Title   = "Auto Farm",
            Message = v and "Auto Farm Enabled!" or "Auto Farm Disabled.",
            Type    = v and "Success" or "Info",
            Duration= 3,
        })
    end,
})

local farmSpeed = FarmSec:AddSlider({
    Name     = "Walk Speed",
    Min      = 16,
    Max      = 200,
    Default  = 16,
    Suffix   = " spd",
    Flag     = "WalkSpeed",
    Callback = function(v)
        if game.Players.LocalPlayer.Character then
            game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = v
        end
    end,
})

local BossSec = FarmTab:AddSection({ Name = "Boss Farm", Icon = "👹", Collapsed = false })

local npcDropdown = BossSec:AddDropdown({
    Name     = "Select Boss",
    Items    = {"Dragon", "Golem", "Shadow King", "Ice Queen", "Demon Lord"},
    Default  = "Dragon",
    Flag     = "SelectedBoss",
    Callback = function(v)
        print("Selected Boss:", v)
    end,
})

BossSec:AddButton({
    Name     = "Teleport to Boss",
    Callback = function()
        ZENUHub:Notify({
            Title   = "Teleport",
            Message = "Teleporting to " .. (ZENUHub.Flags.SelectedBoss or "Boss") .. "...",
            Type    = "Info",
        })
    end,
})

-- ── PVP Tab ────────────────────────────────────────
local PVPSec = PVPTab:AddSection({ Name = "Combat", Icon = "🛡️" })

local aimbot = PVPSec:AddToggle({
    Name     = "Aimbot",
    Default  = false,
    Callback = function(v) print("Aimbot:", v) end,
})

PVPSec:AddSlider({
    Name     = "Aimbot Range",
    Min      = 50,
    Max      = 500,
    Default  = 150,
    Suffix   = " studs",
    Callback = function(v) print("Range:", v) end,
})

PVPSec:AddMultiDropdown({
    Name     = "Target Filters",
    Items    = {"Players", "NPCs", "Bosses", "Guild Members"},
    Default  = {"Players"},
    Callback = function(selected)
        print("Targets:", selected)
    end,
})

-- ── Misc Tab ────────────────────────────────────────
local MiscSec = MiscTab:AddSection({ Name = "Player", Icon = "👤" })

MiscSec:AddTextbox({
    Name        = "Custom Display Name",
    Placeholder = "Enter name...",
    Callback    = function(v) print("Name:", v) end,
})

MiscSec:AddKeybind({
    Name     = "Toggle UI",
    Default  = Enum.KeyCode.RightShift,
    Callback = function()
        print("UI Toggle keybind pressed!")
    end,
})

MiscSec:AddButton({
    Name     = "Show Notification",
    Callback = function()
        ZENUHub:Notify({
            Title   = "ZENU Hub",
            Message = "This is a test notification with progress bar!",
            Type    = "Success",
            Duration= 5,
        })
    end,
})

-- Read flags anywhere:
-- print(ZENUHub.Flags.AutoFarm)
-- print(ZENUHub.Flags.WalkSpeed)
-- print(ZENUHub.Flags.SelectedBoss)
]]
