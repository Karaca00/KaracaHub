local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {
    Flags = {},
    Minimized = false,
    Theme = {
        MainColor = Color3.fromRGB(15, 15, 15),
        SecondaryColor = Color3.fromRGB(20, 20, 20),
        AccentColor = Color3.fromRGB(255, 0, 0), -- ZENU Red
        TextColor = Color3.fromRGB(255, 255, 255),
        DarkText = Color3.fromRGB(150, 150, 150),
        ElementColor = Color3.fromRGB(25, 25, 25),
        SectionColor = Color3.fromRGB(22, 22, 22),
        BorderColor = Color3.fromRGB(35, 35, 35)
    },
    ActiveTab = nil,
    ActiveGroup = nil,
    TabGroups = {},
    Tabs = {},
    Notifications = {},
    -- Store original UI properties for minimize/restore
    OriginalMainFrameSize = nil,
    OriginalMainFramePosition = nil,
    OriginalTitleLabelPosition = nil,
    OriginalMinBtnPosition = nil,
    OriginalCloseBtnPosition = nil,
    OriginalBtnContainerPosition = nil,
    CurrentConfig = {}
}

-- Utility Functions
local function CreateTween(obj, info, goal)
    local tween = TweenService:Create(obj, TweenInfo.new(unpack(info)), goal)
    tween:Play()
    return tween
end

local function MakeDraggable(topBar, mainFrame)
    local dragging, dragInput, dragStart, startPos
    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            local conn
            conn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    conn:Disconnect()
                end
            end)
        end
    end)
    topBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

function Library:Notification(title, text, duration)
    local NotificationGui = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui")):FindFirstChild("ZENUNotifGui")
    if not NotificationGui then
        NotificationGui = Instance.new("ScreenGui")
        NotificationGui.Name = "ZENUNotifGui"
        NotificationGui.Parent = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"))
        NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    end

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 280, 0, 70)
    NotifFrame.Position = UDim2.new(1, 10, 1, -80) -- Start off-screen to the right
    NotifFrame.BackgroundColor3 = Library.Theme.MainColor
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = NotificationGui
    NotifFrame.BackgroundTransparency = 0

    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 8)
    NotifCorner.Parent = NotifFrame

    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 4, 1, -20)
    AccentBar.Position = UDim2.new(0, 8, 0, 10)
    AccentBar.BackgroundColor3 = Library.Theme.AccentColor
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = NotifFrame
    Instance.new("UICorner", AccentBar).CornerRadius = UDim.new(1, 0)

    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -40, 0, 25)
    NotifTitle.Position = UDim2.new(0, 20, 0, 8)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = Library.Theme.AccentColor
    NotifTitle.TextSize = 15
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.Parent = NotifFrame

    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -40, 0, 30)
    NotifText.Position = UDim2.new(0, 20, 0, 32)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Library.Theme.TextColor
    NotifText.TextSize = 13
    NotifText.Font = Enum.Font.Gotham
    NotifText.TextXAlignment = Enum.TextXAlignment.Left
    NotifText.TextWrapped = true
    NotifText.Parent = NotifFrame

    -- Animation for notification entry
    CreateTween(NotifFrame, {0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {Position = UDim2.new(1, -290, 1, -80)}):Play()
    
    table.insert(Library.Notifications, NotifFrame)
    local currentNotifIndex = #Library.Notifications

    -- Adjust positions of existing notifications
    for i, notif in ipairs(Library.Notifications) do
        if notif ~= NotifFrame then
            local newYOffset = -80 - (i - 1) * (NotifFrame.Size.Y.Offset + 10) -- Stack notifications
            CreateTween(notif, {0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {Position = UDim2.new(1, -290, 1, newYOffset)}):Play()
        end
    end

    task.delay(duration or 4, function()
        -- Animation for notification exit
        CreateTween(NotifFrame, {0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In}, {Position = UDim2.new(1, 10, 1, -80)}):Play()
        task.wait(0.5)
        NotifFrame:Destroy()
        -- Remove from table and re-adjust positions
        for i = currentNotifIndex, #Library.Notifications - 1 do
            Library.Notifications[i] = Library.Notifications[i+1]
            local newYOffset = -80 - (i - 1) * (NotifFrame.Size.Y.Offset + 10)
            CreateTween(Library.Notifications[i], {0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {Position = UDim2.new(1, -290, 1, newYOffset)}):Play()
        end
        Library.Notifications[#Library.Notifications] = nil
    end)
end

function Library:CreateWindow(title, config)
    config = config or {}
    Library.CurrentConfig = config -- Store current config

    if config.Theme then
        for k, v in pairs(config.Theme) do
            Library.Theme[k] = v
        end
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZENUHub"
    ScreenGui.Parent = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"))
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = config.Size or UDim2.new(0, 600, 0, 400)
    MainFrame.Position = config.Position or UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = Library.Theme.MainColor
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    MainFrame.BackgroundTransparency = config.Transparency or 0

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 10)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Library.Theme.BorderColor
    MainStroke.Thickness = 1
    MainStroke.Parent = MainFrame

    -- Top Bar (Header)
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 45)
    TopBar.BackgroundColor3 = Library.Theme.SecondaryColor
    TopBar.BorderSizePixel = 0
    TopBar.Parent = MainFrame

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 10)
    TopBarCorner.Parent = TopBar

    -- Cover Bottom Corners of TopBar
    local TopBarCover = Instance.new("Frame")
    TopBarCover.Size = UDim2.new(1, 0, 0, 10)
    TopBarCover.Position = UDim2.new(0, 0, 1, -10)
    TopBarCover.BackgroundColor3 = Library.Theme.SecondaryColor
    TopBarCover.BorderSizePixel = 0
    TopBarCover.Parent = TopBar

    -- Logo "Z"
    local LogoFrame = Instance.new("Frame")
    LogoFrame.Size = UDim2.new(0, 30, 0, 30)
    LogoFrame.Position = UDim2.new(0, 10, 0, 7)
    LogoFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    LogoFrame.Parent = TopBar
    Instance.new("UICorner", LogoFrame).CornerRadius = UDim.new(0, 6)

    local LogoText = Instance.new("TextLabel")
    LogoText.Size = UDim2.new(1, 0, 1, 0)
    LogoText.BackgroundTransparency = 1
    LogoText.Text = "Z"
    LogoText.TextColor3 = Library.Theme.AccentColor
    LogoText.TextSize = 20
    LogoText.Font = Enum.Font.GothamBold
    LogoText.Parent = LogoFrame

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(0, 200, 1, 0)
    TitleLabel.Position = UDim2.new(0, 50, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title or "ZENU HUB"
    TitleLabel.TextColor3 = Library.Theme.TextColor
    TitleLabel.TextSize = 16
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    -- Buttons Container
    local BtnContainer = Instance.new("Frame")
    BtnContainer.Size = UDim2.new(0, 80, 1, 0)
    BtnContainer.Position = UDim2.new(1, -85, 0, 0)
    BtnContainer.BackgroundTransparency = 1
    BtnContainer.Parent = TopBar

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 30, 0, 30)
    CloseBtn.Position = UDim2.new(1, -35, 0, 7)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(35, 25, 25)
    CloseBtn.Text = "×"
    CloseBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
    CloseBtn.TextSize = 24
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.Parent = BtnContainer
    Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

    local MinBtn = Instance.new("TextButton")
    MinBtn.Name = "MinBtn"
    MinBtn.Size = UDim2.new(0, 30, 0, 30)
    MinBtn.Position = UDim2.new(1, -70, 0, 7)
    MinBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    MinBtn.Text = "—"
    MinBtn.TextColor3 = Library.Theme.DarkText
    MinBtn.TextSize = 18
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.Parent = BtnContainer
    Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

    -- Sidebar & Content
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 170, 1, -45)
    Sidebar.Position = UDim2.new(0, 0, 0, 45)
    Sidebar.BackgroundColor3 = Library.Theme.SecondaryColor
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -170, 1, -45)
    ContentArea.Position = UDim2.new(0, 170, 0, 45)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -10, 1, -10)
    TabContainer.Position = UDim2.new(0, 5, 0, 5)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)

    local Pages = Instance.new("Frame")
    Pages.Name = "Pages"
    Pages.Size = UDim2.new(1, 0, 1, 0)
    Pages.BackgroundTransparency = 1
    Pages.Parent = ContentArea

    MakeDraggable(TopBar, MainFrame)

    -- Store original UI properties for minimize/restore
    Library.OriginalMainFrameSize = MainFrame.Size
    Library.OriginalMainFramePosition = MainFrame.Position
    Library.OriginalTitleLabelPosition = TitleLabel.Position
    Library.OriginalMinBtnPosition = MinBtn.Position
    Library.OriginalCloseBtnPosition = CloseBtn.Position
    Library.OriginalBtnContainerPosition = BtnContainer.Position

    MinBtn.MouseButton1Click:Connect(function()
        Library.Minimized = not Library.Minimized
        if Library.Minimized then
            -- Minimize UI: shrink both X and Y, make transparent
            CreateTween(MainFrame, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 200, 0, 45), Position = UDim2.new(Library.OriginalMainFramePosition.X.Scale, Library.OriginalMainFramePosition.X.Offset + Library.OriginalMainFrameSize.X.Offset - 200, Library.OriginalMainFramePosition.Y.Scale, Library.OriginalMainFramePosition.Y.Offset)}):Play()
            CreateTween(MainFrame, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {BackgroundTransparency = 1}):Play() -- Make it fully transparent when minimized
            CreateTween(Sidebar, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 0, 1, -45)}):Play()
            CreateTween(ContentArea, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 0, 1, -45), Position = UDim2.new(0, 0, 0, 45)}):Play()
            
            -- Adjust Title and MinBtn positions for minimized state
            CreateTween(TitleLabel, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = UDim2.new(0, 50, 0, 0)}):Play()
            CreateTween(BtnContainer, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = UDim2.new(1, -85, 0, 0)}):Play()
            CreateTween(MinBtn, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = UDim2.new(1, -35, 0, 7)}):Play()
            CreateTween(CloseBtn, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = UDim2.new(1, 0, 0, 7)}):Play()

            MinBtn.Text = "+"
        else
            -- Restore UI
            CreateTween(MainFrame, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = Library.OriginalMainFrameSize, Position = Library.OriginalMainFramePosition}):Play()
            CreateTween(MainFrame, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {BackgroundTransparency = Library.CurrentConfig.Transparency or 0}):Play() -- Restore original transparency
            CreateTween(Sidebar, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 170, 1, -45)}):Play()
            CreateTween(ContentArea, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(1, -170, 1, -45), Position = UDim2.new(0, 170, 0, 45)}):Play()

            -- Restore Title and MinBtn positions
            CreateTween(TitleLabel, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = Library.OriginalTitleLabelPosition}):Play()
            CreateTween(BtnContainer, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = Library.OriginalBtnContainerPosition}):Play()
            CreateTween(MinBtn, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = Library.OriginalMinBtnPosition}):Play()
            CreateTween(CloseBtn, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = Library.OriginalCloseBtnPosition}):Play()

            MinBtn.Text = "—"
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        CreateTween(MainFrame, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In}, {Size = UDim2.new(0, 0, 0, 0), Position = MainFrame.Position + UDim2.new(0, 300, 0, 200)}):Play()
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    local Window = {}
    Window.MainFrame = MainFrame
    Window.Sidebar = Sidebar
    Window.ContentArea = ContentArea
    Window.Pages = Pages
    Window.TabContainer = TabContainer
    Window.TabListLayout = TabListLayout

    function Window:CreateGroup(name)
        local Group = {}
        Group.Name = name
        Group.Tabs = {}
        Library.TabGroups[name] = Group

        local GroupButton = Instance.new("TextButton")
        GroupButton.Name = name .. "GroupButton"
        GroupButton.Size = UDim2.new(1, -10, 0, 30)
        GroupButton.Position = UDim2.new(0, 5, 0, 0)
        GroupButton.BackgroundColor3 = Library.Theme.ElementColor
        GroupButton.BorderSizePixel = 0
        GroupButton.Text = name
        GroupButton.TextColor3 = Library.Theme.TextColor
        GroupButton.TextSize = 14
        GroupButton.Font = Enum.Font.GothamBold
        GroupButton.TextXAlignment = Enum.TextXAlignment.Left
        GroupButton.TextWrapped = true
        GroupButton.Parent = TabContainer
        Instance.new("UICorner", GroupButton).CornerRadius = UDim.new(0, 6)

        local GroupLayout = Instance.new("UIListLayout")
        GroupLayout.Parent = GroupButton
        GroupLayout.SortOrder = Enum.SortOrder.LayoutOrder
        GroupLayout.Padding = UDim.new(0, 5)
        GroupLayout.FillDirection = Enum.FillDirection.Vertical
        GroupLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

        local GroupPadding = Instance.new("UIPadding")
        GroupPadding.PaddingLeft = UDim.new(0, 10)
        GroupPadding.Parent = GroupButton

        local GroupArrow = Instance.new("TextLabel")
        GroupArrow.Size = UDim2.new(0, 20, 1, 0)
        GroupArrow.Position = UDim2.new(1, -25, 0, 0)
        GroupArrow.BackgroundTransparency = 1
        GroupArrow.Text = "▼"
        GroupArrow.TextColor3 = Library.Theme.DarkText
        GroupArrow.TextSize = 12
        GroupArrow.Font = Enum.Font.GothamBold
        GroupArrow.Parent = GroupButton

        Group.Expanded = false
        GroupButton.Size = UDim2.new(1, -10, 0, 30) -- Initial size

        GroupButton.MouseButton1Click:Connect(function()
            Group.Expanded = not Group.Expanded
            if Group.Expanded then
                CreateTween(GroupButton, {0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {Size = UDim2.new(1, -10, 0, 30 + (#Group.Tabs * 35))}):Play()
                CreateTween(GroupArrow, {0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {Rotation = 180}):Play()
                for _, tab in pairs(Group.Tabs) do
                    tab.TabButton.Visible = true
                    tab.TabButton.LayoutOrder = tab.OriginalLayoutOrder -- Restore original order
                end
            else
                CreateTween(GroupButton, {0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {Size = UDim2.new(1, -10, 0, 30)}):Play()
                CreateTween(GroupArrow, {0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out}, {Rotation = 0}):Play()
                for _, tab in pairs(Group.Tabs) do
                    tab.TabButton.Visible = false
                    tab.TabButton.LayoutOrder = 9999 -- Move out of layout order
                end
            end
            TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y) -- Update CanvasSize
        end)

        function Group:CreateTab(name)
            local Tab = {}
            Tab.Name = name
            Tab.Elements = {}
            Tab.OriginalLayoutOrder = #Group.Tabs + 1
            table.insert(Group.Tabs, Tab)
            Library.Tabs[name] = Tab

            local TabButton = Instance.new("TextButton")
            TabButton.Name = name .. "TabButton"
            TabButton.Size = UDim2.new(1, -20, 0, 30)
            TabButton.Position = UDim2.new(0, 10, 0, 0)
            TabButton.BackgroundColor3 = Library.Theme.ElementColor
            TabButton.BorderSizePixel = 0
            TabButton.Text = name
            TabButton.TextColor3 = Library.Theme.DarkText
            TabButton.TextSize = 14
            TabButton.Font = Enum.Font.Gotham
            TabButton.TextXAlignment = Enum.TextXAlignment.Left
            TabButton.Parent = GroupButton
            TabButton.Visible = false -- Hidden by default
            TabButton.LayoutOrder = 9999 -- Hidden by default
            Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)

            local TabPage = Instance.new("ScrollingFrame")
            TabPage.Name = name .. "Page"
            TabPage.Size = UDim2.new(1, 0, 1, 0)
            TabPage.BackgroundTransparency = 1
            TabPage.ScrollBarThickness = 6
            TabPage.ScrollBarImageColor3 = Library.Theme.DarkText
            TabPage.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated by UIListLayout
            TabPage.Parent = Pages
            TabPage.Visible = false

            local PageLayout = Instance.new("UIListLayout")
            PageLayout.Parent = TabPage
            PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
            PageLayout.Padding = UDim.new(0, 10)
            PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

            local PagePadding = Instance.new("UIPadding")
            PagePadding.PaddingTop = UDim.new(0, 10)
            PagePadding.PaddingBottom = UDim.new(0, 10)
            PagePadding.PaddingLeft = UDim.new(0, 10)
            PagePadding.PaddingRight = UDim.new(0, 10)
            PagePadding.Parent = TabPage

            Tab.TabPage = TabPage
            Tab.TabButton = TabButton
            Tab.PageLayout = PageLayout

            TabButton.MouseButton1Click:Connect(function()
                if Library.ActiveTab then
                    Library.ActiveTab.TabPage.Visible = false
                    CreateTween(Library.ActiveTab.TabButton, {0.2}, {BackgroundColor3 = Library.Theme.ElementColor, TextColor3 = Library.Theme.DarkText}):Play()
                end
                TabPage.Visible = true
                CreateTween(TabButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor, TextColor3 = Library.Theme.TextColor}):Play()
                Library.ActiveTab = Tab
                Library.ActiveGroup = Group
            end)

            function Tab:CreateSection(sectionTitle)
                local SectionFrame = Instance.new("Frame")
                SectionFrame.Name = sectionTitle .. "Section"
                SectionFrame.Size = UDim2.new(1, 0, 0, 0) -- Auto size based on content
                SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
                SectionFrame.BackgroundColor3 = Library.Theme.SectionColor
                SectionFrame.BorderSizePixel = 0
                SectionFrame.Parent = TabPage
                Instance.new("UICorner", SectionFrame).CornerRadius = UDim.new(0, 8)
                Instance.new("UIStroke", SectionFrame).Color = Library.Theme.BorderColor

                local SectionLayout = Instance.new("UIListLayout")
                SectionLayout.Parent = SectionFrame
                SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
                SectionLayout.Padding = UDim.new(0, 8)
                SectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

                local SectionPadding = Instance.new("UIPadding")
                SectionPadding.PaddingTop = UDim.new(0, 10)
                SectionPadding.PaddingBottom = UDim.new(0, 10)
                SectionPadding.PaddingLeft = UDim.new(0, 10)
                SectionPadding.PaddingRight = UDim.new(0, 10)
                SectionPadding.Parent = SectionFrame

                local TitleLabel = Instance.new("TextLabel")
                TitleLabel.Size = UDim2.new(1, -20, 0, 20)
                TitleLabel.Position = UDim2.new(0, 10, 0, 0)
                TitleLabel.BackgroundTransparency = 1
                TitleLabel.Text = sectionTitle
                TitleLabel.TextColor3 = Library.Theme.AccentColor
                TitleLabel.TextSize = 16
                TitleLabel.Font = Enum.Font.GothamBold
                TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
                TitleLabel.Parent = SectionFrame

                local Section = {}
                Section.Frame = SectionFrame
                Section.Layout = SectionLayout
                Section.Padding = SectionPadding

                function Section:CreateButton(text, callback)
                    local Button = Instance.new("TextButton")
                    Button.Size = UDim2.new(1, -20, 0, 30)
                    Button.Position = UDim2.new(0, 10, 0, 0)
                    Button.BackgroundColor3 = Library.Theme.ElementColor
                    Button.BorderSizePixel = 0
                    Button.Text = text
                    Button.TextColor3 = Library.Theme.TextColor
                    Button.TextSize = 14
                    Button.Font = Enum.Font.Gotham
                    Button.Parent = SectionFrame
                    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

                    Button.MouseButton1Click:Connect(function()
                        if callback then pcall(callback) end
                    end)
                    return Button
                end

                function Section:CreateToggle(text, default, callback)
                    local ToggleFrame = Instance.new("Frame")
                    ToggleFrame.Size = UDim2.new(1, -20, 0, 30)
                    ToggleFrame.Position = UDim2.new(0, 10, 0, 0)
                    ToggleFrame.BackgroundColor3 = Library.Theme.ElementColor
                    ToggleFrame.BorderSizePixel = 0
                    ToggleFrame.Parent = SectionFrame
                    Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 6)

                    local ToggleLabel = Instance.new("TextLabel")
                    ToggleLabel.Size = UDim2.new(1, -40, 1, 0)
                    ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
                    ToggleLabel.BackgroundTransparency = 1
                    ToggleLabel.Text = text
                    ToggleLabel.TextColor3 = Library.Theme.TextColor
                    ToggleLabel.TextSize = 14
                    ToggleLabel.Font = Enum.Font.Gotham
                    ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                    ToggleLabel.Parent = ToggleFrame

                    local ToggleButton = Instance.new("TextButton")
                    ToggleButton.Size = UDim2.new(0, 20, 0, 20)
                    ToggleButton.Position = UDim2.new(1, -30, 0, 5)
                    ToggleButton.BackgroundColor3 = Library.Theme.DarkText
                    ToggleButton.BorderSizePixel = 0
                    ToggleButton.Text = ""
                    ToggleButton.Parent = ToggleFrame
                    Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

                    local State = default or false
                    local function UpdateToggleVisual()
                        if State then
                            CreateTween(ToggleButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor}):Play()
                        else
                            CreateTween(ToggleButton, {0.2}, {BackgroundColor3 = Library.Theme.DarkText}):Play()
                        end
                    end
                    UpdateToggleVisual()

                    ToggleButton.MouseButton1Click:Connect(function()
                        State = not State
                        UpdateToggleVisual()
                        if callback then pcall(callback, State) end
                    end)
                    return ToggleFrame, function() return State end
                end

                function Section:CreateSlider(text, min, max, default, callback)
                    local SliderFrame = Instance.new("Frame")
                    SliderFrame.Size = UDim2.new(1, -20, 0, 40)
                    SliderFrame.Position = UDim2.new(0, 10, 0, 0)
                    SliderFrame.BackgroundColor3 = Library.Theme.ElementColor
                    SliderFrame.BorderSizePixel = 0
                    SliderFrame.Parent = SectionFrame
                    Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 6)

                    local SliderLabel = Instance.new("TextLabel")
                    SliderLabel.Size = UDim2.new(1, -60, 0, 20)
                    SliderLabel.Position = UDim2.new(0, 10, 0, 5)
                    SliderLabel.BackgroundTransparency = 1
                    SliderLabel.Text = text .. ": " .. tostring(default or min)
                    SliderLabel.TextColor3 = Library.Theme.TextColor
                    SliderLabel.TextSize = 14
                    SliderLabel.Font = Enum.Font.Gotham
                    SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                    SliderLabel.Parent = SliderFrame

                    local ValueLabel = Instance.new("TextLabel")
                    ValueLabel.Size = UDim2.new(0, 50, 0, 20)
                    ValueLabel.Position = UDim2.new(1, -60, 0, 5)
                    ValueLabel.BackgroundTransparency = 1
                    ValueLabel.Text = tostring(default or min)
                    ValueLabel.TextColor3 = Library.Theme.DarkText
                    ValueLabel.TextSize = 14
                    ValueLabel.Font = Enum.Font.Gotham
                    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    ValueLabel.Parent = SliderFrame

                    local SliderBar = Instance.new("Frame")
                    SliderBar.Size = UDim2.new(1, -20, 0, 5)
                    SliderBar.Position = UDim2.new(0, 10, 0, 28)
                    SliderBar.BackgroundColor3 = Library.Theme.DarkText
                    SliderBar.BorderSizePixel = 0
                    SliderBar.Parent = SliderFrame
                    Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

                    local SliderFill = Instance.new("Frame")
                    SliderFill.Size = UDim2.new(0, 0, 1, 0)
                    SliderFill.Position = UDim2.new(0, 0, 0, 0)
                    SliderFill.BackgroundColor3 = Library.Theme.AccentColor
                    SliderFill.BorderSizePixel = 0
                    SliderFill.Parent = SliderBar
                    Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

                    local SliderHandle = Instance.new("Frame")
                    SliderHandle.Size = UDim2.new(0, 15, 0, 15)
                    SliderHandle.Position = UDim2.new(0, 0, 0.5, -7)
                    SliderHandle.BackgroundColor3 = Library.Theme.TextColor
                    SliderHandle.BorderSizePixel = 0
                    SliderHandle.Parent = SliderBar
                    Instance.new("UICorner", SliderHandle).CornerRadius = UDim.new(1, 0)
                    Instance.new("UIStroke", SliderHandle).Color = Library.Theme.AccentColor

                    local CurrentValue = default or min
                    local draggingSlider = false

                    local function UpdateSlider(inputPos)
                        local relativeX = math.clamp(inputPos.X - SliderBar.AbsolutePosition.X, 0, SliderBar.AbsoluteSize.X)
                        local ratio = relativeX / SliderBar.AbsoluteSize.X
                        CurrentValue = math.floor(min + (max - min) * ratio + 0.5) -- Round to nearest integer
                        CurrentValue = math.clamp(CurrentValue, min, max)

                        SliderFill.Size = UDim2.new(ratio, 0, 1, 0)
                        SliderHandle.Position = UDim2.new(ratio, 0, 0.5, -7)
                        ValueLabel.Text = tostring(CurrentValue)
                        SliderLabel.Text = text .. ": " .. tostring(CurrentValue)
                        if callback then pcall(callback, CurrentValue) end
                    end

                    SliderHandle.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            draggingSlider = true
                            UserInputService.InputChanged:Connect(function(inputObject)
                                if draggingSlider and (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch) then
                                    UpdateSlider(inputObject.Position)
                                end
                            end)
                            UserInputService.InputEnded:Connect(function(inputObject)
                                if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
                                    draggingSlider = false
                                end
                            end)
                        end
                    end)

                    -- Initial update
                    local initialRatio = (CurrentValue - min) / (max - min)
                    SliderFill.Size = UDim2.new(initialRatio, 0, 1, 0)
                    SliderHandle.Position = UDim2.new(initialRatio, 0, 0.5, -7)

                    return SliderFrame, function() return CurrentValue end
                end

                function Section:CreateDropdown(text, options, callback)
                    local DropdownFrame = Instance.new("Frame")
                    DropdownFrame.Size = UDim2.new(1, -20, 0, 30)
                    DropdownFrame.Position = UDim2.new(0, 10, 0, 0)
                    DropdownFrame.BackgroundColor3 = Library.Theme.ElementColor
                    DropdownFrame.BorderSizePixel = 0
                    DropdownFrame.Parent = SectionFrame
                    Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 6)

                    local DropdownLabel = Instance.new("TextLabel")
                    DropdownLabel.Size = UDim2.new(1, -40, 1, 0)
                    DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                    DropdownLabel.BackgroundTransparency = 1
                    DropdownLabel.Text = text .. ": " .. options[1]
                    DropdownLabel.TextColor3 = Library.Theme.TextColor
                    DropdownLabel.TextSize = 14
                    DropdownLabel.Font = Enum.Font.Gotham
                    DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                    DropdownLabel.Parent = DropdownFrame

                    local DropdownArrow = Instance.new("TextLabel")
                    DropdownArrow.Size = UDim2.new(0, 20, 1, 0)
                    DropdownArrow.Position = UDim2.new(1, -30, 0, 0)
                    DropdownArrow.BackgroundTransparency = 1
                    DropdownArrow.Text = "▼"
                    DropdownArrow.TextColor3 = Library.Theme.DarkText
                    DropdownArrow.TextSize = 12
                    DropdownArrow.Font = Enum.Font.GothamBold
                    DropdownArrow.Parent = DropdownFrame

                    local DropdownList = Instance.new("Frame")
                    DropdownList.Size = UDim2.new(1, 0, 0, 0)
                    DropdownList.Position = UDim2.new(0, 0, 1, 5)
                    DropdownList.BackgroundColor3 = Library.Theme.ElementColor
                    DropdownList.BorderSizePixel = 0
                    DropdownList.Parent = DropdownFrame
                    DropdownList.Visible = false
                    Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 6)
                    Instance.new("UIStroke", DropdownList).Color = Library.Theme.BorderColor

                    local ListLayout = Instance.new("UIListLayout")
                    ListLayout.Parent = DropdownList
                    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    ListLayout.Padding = UDim.new(0, 5)

                    local ListPadding = Instance.new("UIPadding")
                    ListPadding.PaddingTop = UDim.new(0, 5)
                    ListPadding.PaddingBottom = UDim.new(0, 5)
                    ListPadding.Parent = DropdownList

                    local CurrentSelection = options[1]

                    for i, optionText in ipairs(options) do
                        local OptionButton = Instance.new("TextButton")
                        OptionButton.Size = UDim2.new(1, -10, 0, 25)
                        OptionButton.Position = UDim2.new(0, 5, 0, 0)
                        OptionButton.BackgroundColor3 = Library.Theme.ElementColor
                        OptionButton.BorderSizePixel = 0
                        OptionButton.Text = optionText
                        OptionButton.TextColor3 = Library.Theme.TextColor
                        OptionButton.TextSize = 14
                        OptionButton.Font = Enum.Font.Gotham
                        OptionButton.Parent = DropdownList
                        Instance.new("UICorner", OptionButton).CornerRadius = UDim.new(0, 4)

                        if optionText == CurrentSelection then
                            OptionButton.BackgroundColor3 = Library.Theme.AccentColor
                        end

                        OptionButton.MouseButton1Click:Connect(function()
                            CurrentSelection = optionText
                            DropdownLabel.Text = text .. ": " .. CurrentSelection
                            DropdownList.Visible = false
                            CreateTween(DropdownArrow, {0.2}, {Rotation = 0}):Play()
                            if callback then pcall(callback, CurrentSelection) end
                            for _, btn in pairs(DropdownList:GetChildren()) do
                                if btn:IsA("TextButton") then
                                    CreateTween(btn, {0.2}, {BackgroundColor3 = Library.Theme.ElementColor}):Play()
                                end
                            end
                            CreateTween(OptionButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor}):Play()
                        end
                    end)

                    DropdownFrame.MouseButton1Click:Connect(function()
                        DropdownList.Visible = not DropdownList.Visible
                        if DropdownList.Visible then
                            CreateTween(DropdownArrow, {0.2}, {Rotation = 180}):Play()
                            DropdownList.Size = UDim2.new(1, 0, 0, ListLayout.AbsoluteContentSize.Y + ListPadding.PaddingTop.Offset + ListPadding.PaddingBottom.Offset)
                        else
                            CreateTween(DropdownArrow, {0.2}, {Rotation = 0}):Play()
                        end
                    end)

                    return DropdownFrame, function() return CurrentSelection end
                end

                function Section:CreateMultiDropdown(text, options, callback)
                    local MultiDropdownFrame = Instance.new("Frame")
                    MultiDropdownFrame.Size = UDim2.new(1, -20, 0, 30)
                    MultiDropdownFrame.Position = UDim2.new(0, 10, 0, 0)
                    MultiDropdownFrame.BackgroundColor3 = Library.Theme.ElementColor
                    MultiDropdownFrame.BorderSizePixel = 0
                    MultiDropdownFrame.Parent = SectionFrame
                    Instance.new("UICorner", MultiDropdownFrame).CornerRadius = UDim.new(0, 6)

                    local MultiDropdownLabel = Instance.new("TextLabel")
                    MultiDropdownLabel.Size = UDim2.new(1, -40, 1, 0)
                    MultiDropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                    MultiDropdownLabel.BackgroundTransparency = 1
                    MultiDropdownLabel.Text = text .. ": None"
                    MultiDropdownLabel.TextColor3 = Library.Theme.TextColor
                    MultiDropdownLabel.TextSize = 14
                    MultiDropdownLabel.Font = Enum.Font.Gotham
                    MultiDropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                    MultiDropdownLabel.TextWrapped = true
                    MultiDropdownLabel.Parent = MultiDropdownFrame

                    local MultiDropdownArrow = Instance.new("TextLabel")
                    MultiDropdownArrow.Size = UDim2.new(0, 20, 1, 0)
                    MultiDropdownArrow.Position = UDim2.new(1, -30, 0, 0)
                    MultiDropdownArrow.BackgroundTransparency = 1
                    MultiDropdownArrow.Text = "▼"
                    MultiDropdownArrow.TextColor3 = Library.Theme.DarkText
                    MultiDropdownArrow.TextSize = 12
                    MultiDropdownArrow.Font = Enum.Font.GothamBold
                    MultiDropdownArrow.Parent = MultiDropdownFrame

                    local MultiDropdownList = Instance.new("Frame")
                    MultiDropdownList.Size = UDim2.new(1, 0, 0, 0)
                    MultiDropdownList.Position = UDim2.new(0, 0, 1, 5)
                    MultiDropdownList.BackgroundColor3 = Library.Theme.ElementColor
                    MultiDropdownList.BorderSizePixel = 0
                    MultiDropdownList.Parent = MultiDropdownFrame
                    MultiDropdownList.Visible = false
                    Instance.new("UICorner", MultiDropdownList).CornerRadius = UDim.new(0, 6)
                    Instance.new("UIStroke", MultiDropdownList).Color = Library.Theme.BorderColor

                    local ListLayout = Instance.new("UIListLayout")
                    ListLayout.Parent = MultiDropdownList
                    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                    ListLayout.Padding = UDim.new(0, 5)

                    local ListPadding = Instance.new("UIPadding")
                    ListPadding.PaddingTop = UDim.new(0, 5)
                    ListPadding.PaddingBottom = UDim.new(0, 5)
                    ListPadding.Parent = MultiDropdownList

                    local SelectedOptions = {}

                    local function UpdateMultiDropdownLabel()
                        local selectedNames = {}
                        for optionName, isSelected in pairs(SelectedOptions) do
                            if isSelected then
                                table.insert(selectedNames, optionName)
                            end
                        end
                        if #selectedNames == 0 then
                            MultiDropdownLabel.Text = text .. ": None"
                        else
                            MultiDropdownLabel.Text = text .. ": " .. table.concat(selectedNames, ", ")
                        end
                    end

                    for i, optionText in ipairs(options) do
                        SelectedOptions[optionText] = false

                        local OptionButton = Instance.new("TextButton")
                        OptionButton.Size = UDim2.new(1, -10, 0, 25)
                        OptionButton.Position = UDim2.new(0, 5, 0, 0)
                        OptionButton.BackgroundColor3 = Library.Theme.ElementColor
                        OptionButton.BorderSizePixel = 0
                        OptionButton.Text = optionText
                        OptionButton.TextColor3 = Library.Theme.TextColor
                        OptionButton.TextSize = 14
                        OptionButton.Font = Enum.Font.Gotham
                        OptionButton.Parent = MultiDropdownList
                        Instance.new("UICorner", OptionButton).CornerRadius = UDim.new(0, 4)

                        OptionButton.MouseButton1Click:Connect(function()
                            SelectedOptions[optionText] = not SelectedOptions[optionText]
                            if SelectedOptions[optionText] then
                                CreateTween(OptionButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor}):Play()
                            else
                                CreateTween(OptionButton, {0.2}, {BackgroundColor3 = Library.Theme.ElementColor}):Play()
                            end
                            UpdateMultiDropdownLabel()
                            if callback then pcall(callback, SelectedOptions) end
                        end)
                    end

                    MultiDropdownFrame.MouseButton1Click:Connect(function()
                        MultiDropdownList.Visible = not MultiDropdownList.Visible
                        if MultiDropdownList.Visible then
                            CreateTween(MultiDropdownArrow, {0.2}, {Rotation = 180}):Play()
                            MultiDropdownList.Size = UDim2.new(1, 0, 0, ListLayout.AbsoluteContentSize.Y + ListPadding.PaddingTop.Offset + ListPadding.PaddingBottom.Offset)
                        else
                            CreateTween(MultiDropdownArrow, {0.2}, {Rotation = 0}):Play()
                        end
                    end)

                    UpdateMultiDropdownLabel()
                    return MultiDropdownFrame, function() return SelectedOptions end
                end

                function Section:CreateInput(text, default, callback)
                    local InputFrame = Instance.new("Frame")
                    InputFrame.Size = UDim2.new(1, -20, 0, 30)
                    InputFrame.Position = UDim2.new(0, 10, 0, 0)
                    InputFrame.BackgroundColor3 = Library.Theme.ElementColor
                    InputFrame.BorderSizePixel = 0
                    InputFrame.Parent = SectionFrame
                    Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 6)

                    local InputLabel = Instance.new("TextLabel")
                    InputLabel.Size = UDim2.new(0, 60, 1, 0)
                    InputLabel.Position = UDim2.new(0, 10, 0, 0)
                    InputLabel.BackgroundTransparency = 1
                    InputLabel.Text = text .. ":"
                    InputLabel.TextColor3 = Library.Theme.TextColor
                    InputLabel.TextSize = 14
                    InputLabel.Font = Enum.Font.Gotham
                    InputLabel.TextXAlignment = Enum.TextXAlignment.Left
                    InputLabel.Parent = InputFrame

                    local TextBox = Instance.new("TextBox")
                    TextBox.Size = UDim2.new(1, -80, 1, -10)
                    TextBox.Position = UDim2.new(0, 70, 0, 5)
                    TextBox.BackgroundColor3 = Library.Theme.DarkText
                    TextBox.BorderSizePixel = 0
                    TextBox.Text = default or ""
                    TextBox.TextColor3 = Library.Theme.TextColor
                    TextBox.TextSize = 14
                    TextBox.Font = Enum.Font.Gotham
                    TextBox.TextXAlignment = Enum.TextXAlignment.Left
                    TextBox.ClearTextOnFocus = false
                    TextBox.Parent = InputFrame
                    Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)

                    TextBox.FocusLost:Connect(function()
                        if callback then pcall(callback, TextBox.Text) end
                    end)
                    return InputFrame, function() return TextBox.Text end
                end

                function Section:CreateLabel(text)
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, -20, 0, 20)
                    Label.Position = UDim2.new(0, 10, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = text
                    Label.TextColor3 = Library.Theme.DarkText
                    Label.TextSize = 13
                    Label.Font = Enum.Font.Gotham
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.TextWrapped = true
                    Label.Parent = SectionFrame
                    return Label
                end

                function Section:CreateParagraph(text)
                    local ParagraphFrame = Instance.new("Frame")
                    ParagraphFrame.Size = UDim2.new(1, -20, 0, 0) -- AutomaticSize.Y
                    ParagraphFrame.AutomaticSize = Enum.AutomaticSize.Y
                    ParagraphFrame.Position = UDim2.new(0, 10, 0, 0)
                    ParagraphFrame.BackgroundTransparency = 1
                    ParagraphFrame.Parent = SectionFrame

                    local ParagraphLabel = Instance.new("TextLabel")
                    ParagraphLabel.Size = UDim2.new(1, 0, 1, 0)
                    ParagraphLabel.BackgroundTransparency = 1
                    ParagraphLabel.Text = text
                    ParagraphLabel.TextColor3 = Library.Theme.DarkText
                    ParagraphLabel.TextSize = 13
                    ParagraphLabel.Font = Enum.Font.Gotham
                    ParagraphLabel.TextXAlignment = Enum.TextXAlignment.Left
                    ParagraphLabel.TextWrapped = true
                    ParagraphLabel.Parent = ParagraphFrame
                    return ParagraphFrame
                end

                return Section
            end
            return Tab
        end
        return Group
    end

    -- Standalone Tab (not in a group)
    function Window:CreateTab(name)
        local Tab = {}
        Tab.Name = name
        Tab.Elements = {}
        
        -- Create a dummy group for standalone tabs to manage layout
        local StandaloneGroup = {}
        StandaloneGroup.Name = name .. "_StandaloneGroup"
        StandaloneGroup.Tabs = {Tab}
        StandaloneGroup.Expanded = true -- Always expanded

        Library.Tabs[name] = Tab

        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "TabButton"
        TabButton.Size = UDim2.new(1, -10, 0, 30)
        TabButton.Position = UDim2.new(0, 5, 0, 0)
        TabButton.BackgroundColor3 = Library.Theme.ElementColor
        TabButton.BorderSizePixel = 0
        TabButton.Text = name
        TabButton.TextColor3 = Library.Theme.DarkText
        TabButton.TextSize = 14
        TabButton.Font = Enum.Font.Gotham
        TabButton.TextXAlignment = Enum.TextXAlignment.Left
        TabButton.Parent = TabContainer
        Instance.new("UICorner", TabButton).CornerRadius = UDim.new(0, 6)

        local TabPage = Instance.new("ScrollingFrame")
        TabPage.Name = name .. "Page"
        TabPage.Size = UDim2.new(1, 0, 1, 0)
        TabPage.BackgroundTransparency = 1
        TabPage.ScrollBarThickness = 6
        TabPage.ScrollBarImageColor3 = Library.Theme.DarkText
        TabPage.CanvasSize = UDim2.new(0, 0, 0, 0) -- Will be updated by UIListLayout
        TabPage.Parent = Pages
        TabPage.Visible = false

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Parent = TabPage
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Padding = UDim.new(0, 10)
        PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingTop = UDim.new(0, 10)
        PagePadding.PaddingBottom = UDim.new(0, 10)
        PagePadding.PaddingLeft = UDim.new(0, 10)
        PagePadding.PaddingRight = UDim.new(0, 10)
        PagePadding.Parent = TabPage

        Tab.TabPage = TabPage
        Tab.TabButton = TabButton
        Tab.PageLayout = PageLayout

        TabButton.MouseButton1Click:Connect(function()
            if Library.ActiveTab then
                Library.ActiveTab.TabPage.Visible = false
                CreateTween(Library.ActiveTab.TabButton, {0.2}, {BackgroundColor3 = Library.Theme.ElementColor, TextColor3 = Library.Theme.DarkText}):Play()
            end
            TabPage.Visible = true
            CreateTween(TabButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor, TextColor3 = Library.Theme.TextColor}):Play()
            Library.ActiveTab = Tab
            Library.ActiveGroup = StandaloneGroup
        end)

        function Tab:CreateSection(sectionTitle)
            local SectionFrame = Instance.new("Frame")
            SectionFrame.Name = sectionTitle .. "Section"
            SectionFrame.Size = UDim2.new(1, 0, 0, 0) -- AutomaticSize.Y
            SectionFrame.AutomaticSize = Enum.AutomaticSize.Y
            SectionFrame.BackgroundColor3 = Library.Theme.SectionColor
            SectionFrame.BorderSizePixel = 0
            SectionFrame.Parent = TabPage
            Instance.new("UICorner", SectionFrame).CornerRadius = UDim.new(0, 8)
            Instance.new("UIStroke", SectionFrame).Color = Library.Theme.BorderColor

            local SectionLayout = Instance.new("UIListLayout")
            SectionLayout.Parent = SectionFrame
            SectionLayout.SortOrder = Enum.SortOrder.LayoutOrder
            SectionLayout.Padding = UDim.new(0, 8)
            SectionLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center

            local SectionPadding = Instance.new("UIPadding")
            SectionPadding.PaddingTop = UDim.new(0, 10)
            SectionPadding.PaddingBottom = UDim.new(0, 10)
            SectionPadding.PaddingLeft = UDim.new(0, 10)
            SectionPadding.PaddingRight = UDim.new(0, 10)
            SectionPadding.Parent = SectionFrame

            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1, -20, 0, 20)
            TitleLabel.Position = UDim2.new(0, 10, 0, 0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = sectionTitle
            TitleLabel.TextColor3 = Library.Theme.AccentColor
            TitleLabel.TextSize = 16
            TitleLabel.Font = Enum.Font.GothamBold
            TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
            TitleLabel.Parent = SectionFrame

            local Section = {}
            Section.Frame = SectionFrame
            Section.Layout = SectionLayout
            Section.Padding = SectionPadding

            function Section:CreateButton(text, callback)
                local Button = Instance.new("TextButton")
                Button.Size = UDim2.new(1, -20, 0, 30)
                Button.Position = UDim2.new(0, 10, 0, 0)
                Button.BackgroundColor3 = Library.Theme.ElementColor
                Button.BorderSizePixel = 0
                Button.Text = text
                Button.TextColor3 = Library.Theme.TextColor
                Button.TextSize = 14
                Button.Font = Enum.Font.Gotham
                Button.Parent = SectionFrame
                Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

                Button.MouseButton1Click:Connect(function()
                    if callback then pcall(callback) end
                end)
                return Button
            end

            function Section:CreateToggle(text, default, callback)
                local ToggleFrame = Instance.new("Frame")
                ToggleFrame.Size = UDim2.new(1, -20, 0, 30)
                ToggleFrame.Position = UDim2.new(0, 10, 0, 0)
                ToggleFrame.BackgroundColor3 = Library.Theme.ElementColor
                ToggleFrame.BorderSizePixel = 0
                ToggleFrame.Parent = SectionFrame
                Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 6)

                local ToggleLabel = Instance.new("TextLabel")
                ToggleLabel.Size = UDim2.new(1, -40, 1, 0)
                ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
                ToggleLabel.BackgroundTransparency = 1
                ToggleLabel.Text = text
                ToggleLabel.TextColor3 = Library.Theme.TextColor
                ToggleLabel.TextSize = 14
                ToggleLabel.Font = Enum.Font.Gotham
                ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
                ToggleLabel.Parent = ToggleFrame

                local ToggleButton = Instance.new("TextButton")
                ToggleButton.Size = UDim2.new(0, 20, 0, 20)
                ToggleButton.Position = UDim2.new(1, -30, 0, 5)
                ToggleButton.BackgroundColor3 = Library.Theme.DarkText
                ToggleButton.BorderSizePixel = 0
                ToggleButton.Text = ""
                ToggleButton.Parent = ToggleFrame
                Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(1, 0)

                local State = default or false
                local function UpdateToggleVisual()
                    if State then
                        CreateTween(ToggleButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor}):Play()
                    else
                        CreateTween(ToggleButton, {0.2}, {BackgroundColor3 = Library.Theme.DarkText}):Play()
                    end
                end
                UpdateToggleVisual()

                ToggleButton.MouseButton1Click:Connect(function()
                    State = not State
                    UpdateToggleVisual()
                    if callback then pcall(callback, State) end
                end)
                return ToggleFrame, function() return State end
            end

            function Section:CreateSlider(text, min, max, default, callback)
                local SliderFrame = Instance.new("Frame")
                SliderFrame.Size = UDim2.new(1, -20, 0, 40)
                SliderFrame.Position = UDim2.new(0, 10, 0, 0)
                SliderFrame.BackgroundColor3 = Library.Theme.ElementColor
                SliderFrame.BorderSizePixel = 0
                SliderFrame.Parent = SectionFrame
                Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 6)

                local SliderLabel = Instance.new("TextLabel")
                SliderLabel.Size = UDim2.new(1, -60, 0, 20)
                SliderLabel.Position = UDim2.new(0, 10, 0, 5)
                SliderLabel.BackgroundTransparency = 1
                SliderLabel.Text = text .. ": " .. tostring(default or min)
                SliderLabel.TextColor3 = Library.Theme.TextColor
                SliderLabel.TextSize = 14
                SliderLabel.Font = Enum.Font.Gotham
                SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
                SliderLabel.Parent = SliderFrame

                local ValueLabel = Instance.new("TextLabel")
                ValueLabel.Size = UDim2.new(0, 50, 0, 20)
                ValueLabel.Position = UDim2.new(1, -60, 0, 5)
                ValueLabel.BackgroundTransparency = 1
                ValueLabel.Text = tostring(default or min)
                ValueLabel.TextColor3 = Library.Theme.DarkText
                ValueLabel.TextSize = 14
                ValueLabel.Font = Enum.Font.Gotham
                ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                ValueLabel.Parent = SliderFrame

                local SliderBar = Instance.new("Frame")
                SliderBar.Size = UDim2.new(1, -20, 0, 5)
                SliderBar.Position = UDim2.new(0, 10, 0, 28)
                SliderBar.BackgroundColor3 = Library.Theme.DarkText
                SliderBar.BorderSizePixel = 0
                SliderBar.Parent = SliderFrame
                Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)

                local SliderFill = Instance.new("Frame")
                SliderFill.Size = UDim2.new(0, 0, 1, 0)
                SliderFill.Position = UDim2.new(0, 0, 0, 0)
                SliderFill.BackgroundColor3 = Library.Theme.AccentColor
                SliderFill.BorderSizePixel = 0
                SliderFill.Parent = SliderBar
                Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)

                local SliderHandle = Instance.new("Frame")
                SliderHandle.Size = UDim2.new(0, 15, 0, 15)
                SliderHandle.Position = UDim2.new(0, 0, 0.5, -7)
                SliderHandle.BackgroundColor3 = Library.Theme.TextColor
                SliderHandle.BorderSizePixel = 0
                SliderHandle.Parent = SliderBar
                Instance.new("UICorner", SliderHandle).CornerRadius = UDim.new(1, 0)
                Instance.new("UIStroke", SliderHandle).Color = Library.Theme.AccentColor

                local CurrentValue = default or min
                local draggingSlider = false

                local function UpdateSlider(inputPos)
                    local relativeX = math.clamp(inputPos.X - SliderBar.AbsolutePosition.X, 0, SliderBar.AbsoluteSize.X)
                    local ratio = relativeX / SliderBar.AbsoluteSize.X
                    CurrentValue = math.floor(min + (max - min) * ratio + 0.5) -- Round to nearest integer
                    CurrentValue = math.clamp(CurrentValue, min, max)

                    SliderFill.Size = UDim2.new(ratio, 0, 1, 0)
                    SliderHandle.Position = UDim2.new(ratio, 0, 0.5, -7)
                    ValueLabel.Text = tostring(CurrentValue)
                    SliderLabel.Text = text .. ": " .. tostring(CurrentValue)
                    if callback then pcall(callback, CurrentValue) end
                end

                SliderHandle.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        draggingSlider = true
                        UserInputService.InputChanged:Connect(function(inputObject)
                            if draggingSlider and (inputObject.UserInputType == Enum.UserInputType.MouseMovement or inputObject.UserInputType == Enum.UserInputType.Touch) then
                                UpdateSlider(inputObject.Position)
                            end
                        end)
                        UserInputService.InputEnded:Connect(function(inputObject)
                            if inputObject.UserInputType == Enum.UserInputType.MouseButton1 or inputObject.UserInputType == Enum.UserInputType.Touch then
                                draggingSlider = false
                            end
                        end)
                    end
                end)

                -- Initial update
                local initialRatio = (CurrentValue - min) / (max - min)
                SliderFill.Size = UDim2.new(initialRatio, 0, 1, 0)
                SliderHandle.Position = UDim2.new(initialRatio, 0, 0.5, -7)

                return SliderFrame, function() return CurrentValue end
            end

            function Section:CreateDropdown(text, options, callback)
                local DropdownFrame = Instance.new("Frame")
                DropdownFrame.Size = UDim2.new(1, -20, 0, 30)
                DropdownFrame.Position = UDim2.new(0, 10, 0, 0)
                DropdownFrame.BackgroundColor3 = Library.Theme.ElementColor
                DropdownFrame.BorderSizePixel = 0
                DropdownFrame.Parent = SectionFrame
                Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 6)

                local DropdownLabel = Instance.new("TextLabel")
                DropdownLabel.Size = UDim2.new(1, -40, 1, 0)
                DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                DropdownLabel.BackgroundTransparency = 1
                DropdownLabel.Text = text .. ": " .. options[1]
                DropdownLabel.TextColor3 = Library.Theme.TextColor
                DropdownLabel.TextSize = 14
                DropdownLabel.Font = Enum.Font.Gotham
                DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                DropdownLabel.Parent = DropdownFrame

                local DropdownArrow = Instance.new("TextLabel")
                DropdownArrow.Size = UDim2.new(0, 20, 1, 0)
                DropdownArrow.Position = UDim2.new(1, -30, 0, 0)
                DropdownArrow.BackgroundTransparency = 1
                DropdownArrow.Text = "▼"
                DropdownArrow.TextColor3 = Library.Theme.DarkText
                DropdownArrow.TextSize = 12
                DropdownArrow.Font = Enum.Font.GothamBold
                DropdownArrow.Parent = DropdownFrame

                local DropdownList = Instance.new("Frame")
                DropdownList.Size = UDim2.new(1, 0, 0, 0)
                DropdownList.Position = UDim2.new(0, 0, 1, 5)
                DropdownList.BackgroundColor3 = Library.Theme.ElementColor
                DropdownList.BorderSizePixel = 0
                DropdownList.Parent = DropdownFrame
                DropdownList.Visible = false
                Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 6)
                Instance.new("UIStroke", DropdownList).Color = Library.Theme.BorderColor

                local ListLayout = Instance.new("UIListLayout")
                ListLayout.Parent = DropdownList
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ListLayout.Padding = UDim.new(0, 5)

                local ListPadding = Instance.new("UIPadding")
                ListPadding.PaddingTop = UDim.new(0, 5)
                ListPadding.PaddingBottom = UDim.new(0, 5)
                ListPadding.Parent = DropdownList

                local CurrentSelection = options[1]

                for i, optionText in ipairs(options) do
                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Size = UDim2.new(1, -10, 0, 25)
                    OptionButton.Position = UDim2.new(0, 5, 0, 0)
                    OptionButton.BackgroundColor3 = Library.Theme.ElementColor
                    OptionButton.BorderSizePixel = 0
                    OptionButton.Text = optionText
                    OptionButton.TextColor3 = Library.Theme.TextColor
                    OptionButton.TextSize = 14
                    OptionButton.Font = Enum.Font.Gotham
                    OptionButton.Parent = DropdownList
                    Instance.new("UICorner", OptionButton).CornerRadius = UDim.new(0, 4)

                    if optionText == CurrentSelection then
                        OptionButton.BackgroundColor3 = Library.Theme.AccentColor
                    end

                    OptionButton.MouseButton1Click:Connect(function()
                        CurrentSelection = optionText
                        DropdownLabel.Text = text .. ": " .. CurrentSelection
                        DropdownList.Visible = false
                        CreateTween(DropdownArrow, {0.2}, {Rotation = 0}):Play()
                        if callback then pcall(callback, CurrentSelection) end
                        for _, btn in pairs(DropdownList:GetChildren()) do
                            if btn:IsA("TextButton") then
                                CreateTween(btn, {0.2}, {BackgroundColor3 = Library.Theme.ElementColor}):Play()
                            end
                        end
                        CreateTween(OptionButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor}):Play()
                    end)
                end

                DropdownFrame.MouseButton1Click:Connect(function()
                    DropdownList.Visible = not DropdownList.Visible
                    if DropdownList.Visible then
                        CreateTween(DropdownArrow, {0.2}, {Rotation = 180}):Play()
                        DropdownList.Size = UDim2.new(1, 0, 0, ListLayout.AbsoluteContentSize.Y + ListPadding.PaddingTop.Offset + ListPadding.PaddingBottom.Offset)
                    else
                        CreateTween(DropdownArrow, {0.2}, {Rotation = 0}):Play()
                    end
                end)

                return DropdownFrame, function() return CurrentSelection end
            end

            function Section:CreateMultiDropdown(text, options, callback)
                local MultiDropdownFrame = Instance.new("Frame")
                MultiDropdownFrame.Size = UDim2.new(1, -20, 0, 30)
                MultiDropdownFrame.Position = UDim2.new(0, 10, 0, 0)
                MultiDropdownFrame.BackgroundColor3 = Library.Theme.ElementColor
                MultiDropdownFrame.BorderSizePixel = 0
                MultiDropdownFrame.Parent = SectionFrame
                Instance.new("UICorner", MultiDropdownFrame).CornerRadius = UDim.new(0, 6)

                local MultiDropdownLabel = Instance.new("TextLabel")
                MultiDropdownLabel.Size = UDim2.new(1, -40, 1, 0)
                MultiDropdownLabel.Position = UDim2.new(0, 10, 0, 0)
                MultiDropdownLabel.BackgroundTransparency = 1
                MultiDropdownLabel.Text = text .. ": None"
                MultiDropdownLabel.TextColor3 = Library.Theme.TextColor
                MultiDropdownLabel.TextSize = 14
                MultiDropdownLabel.Font = Enum.Font.Gotham
                MultiDropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
                MultiDropdownLabel.TextWrapped = true
                MultiDropdownLabel.Parent = MultiDropdownFrame

                local MultiDropdownArrow = Instance.new("TextLabel")
                MultiDropdownArrow.Size = UDim2.new(0, 20, 1, 0)
                MultiDropdownArrow.Position = UDim2.new(1, -30, 0, 0)
                MultiDropdownArrow.BackgroundTransparency = 1
                MultiDropdownArrow.Text = "▼"
                MultiDropdownArrow.TextColor3 = Library.Theme.DarkText
                MultiDropdownArrow.TextSize = 12
                MultiDropdownArrow.Font = Enum.Font.GothamBold
                MultiDropdownArrow.Parent = MultiDropdownFrame

                local MultiDropdownList = Instance.new("Frame")
                MultiDropdownList.Size = UDim2.new(1, 0, 0, 0)
                MultiDropdownList.Position = UDim2.new(0, 0, 1, 5)
                MultiDropdownList.BackgroundColor3 = Library.Theme.ElementColor
                MultiDropdownList.BorderSizePixel = 0
                MultiDropdownList.Parent = MultiDropdownFrame
                MultiDropdownList.Visible = false
                Instance.new("UICorner", MultiDropdownList).CornerRadius = UDim.new(0, 6)
                Instance.new("UIStroke", MultiDropdownList).Color = Library.Theme.BorderColor

                local ListLayout = Instance.new("UIListLayout")
                ListLayout.Parent = MultiDropdownList
                ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
                ListLayout.Padding = UDim.new(0, 5)

                local ListPadding = Instance.new("UIPadding")
                ListPadding.PaddingTop = UDim.new(0, 5)
                ListPadding.PaddingBottom = UDim.new(0, 5)
                ListPadding.Parent = MultiDropdownList

                local SelectedOptions = {}

                local function UpdateMultiDropdownLabel()
                    local selectedNames = {}
                    for optionName, isSelected in pairs(SelectedOptions) do
                        if isSelected then
                            table.insert(selectedNames, optionName)
                        end
                    end
                    if #selectedNames == 0 then
                        MultiDropdownLabel.Text = text .. ": None"
                    else
                        MultiDropdownLabel.Text = text .. ": " .. table.concat(selectedNames, ", ")
                    end
                end

                for i, optionText in ipairs(options) do
                    SelectedOptions[optionText] = false

                    local OptionButton = Instance.new("TextButton")
                    OptionButton.Size = UDim2.new(1, -10, 0, 25)
                    OptionButton.Position = UDim2.new(0, 5, 0, 0)
                    OptionButton.BackgroundColor3 = Library.Theme.ElementColor
                    OptionButton.BorderSizePixel = 0
                    OptionButton.Text = optionText
                    OptionButton.TextColor3 = Library.Theme.TextColor
                    OptionButton.TextSize = 14
                    OptionButton.Font = Enum.Font.Gotham
                    OptionButton.Parent = MultiDropdownList
                    Instance.new("UICorner", OptionButton).CornerRadius = UDim.new(0, 4)

                    OptionButton.MouseButton1Click:Connect(function()
                        SelectedOptions[optionText] = not SelectedOptions[optionText]
                        if SelectedOptions[optionText] then
                            CreateTween(OptionButton, {0.2}, {BackgroundColor3 = Library.Theme.AccentColor}):Play()
                        else
                            CreateTween(OptionButton, {0.2}, {BackgroundColor3 = Library.Theme.ElementColor}):Play()
                        end
                        UpdateMultiDropdownLabel()
                        if callback then pcall(callback, SelectedOptions) end
                    end)
                end

                MultiDropdownFrame.MouseButton1Click:Connect(function()
                    MultiDropdownList.Visible = not MultiDropdownList.Visible
                    if MultiDropdownList.Visible then
                        CreateTween(MultiDropdownArrow, {0.2}, {Rotation = 180}):Play()
                        MultiDropdownList.Size = UDim2.new(1, 0, 0, ListLayout.AbsoluteContentSize.Y + ListPadding.PaddingTop.Offset + ListPadding.PaddingBottom.Offset)
                    else
                        CreateTween(MultiDropdownArrow, {0.2}, {Rotation = 0}):Play()
                    end
                end)

                UpdateMultiDropdownLabel()
                return MultiDropdownFrame, function() return SelectedOptions end
            end

            function Section:CreateInput(text, default, callback)
                local InputFrame = Instance.new("Frame")
                InputFrame.Size = UDim2.new(1, -20, 0, 30)
                InputFrame.Position = UDim2.new(0, 10, 0, 0)
                InputFrame.BackgroundColor3 = Library.Theme.ElementColor
                InputFrame.BorderSizePixel = 0
                InputFrame.Parent = SectionFrame
                Instance.new("UICorner", InputFrame).CornerRadius = UDim.new(0, 6)

                local InputLabel = Instance.new("TextLabel")
                InputLabel.Size = UDim2.new(0, 60, 1, 0)
                InputLabel.Position = UDim2.new(0, 10, 0, 0)
                InputLabel.BackgroundTransparency = 1
                InputLabel.Text = text .. ":"
                InputLabel.TextColor3 = Library.Theme.TextColor
                InputLabel.TextSize = 14
                InputLabel.Font = Enum.Font.Gotham
                InputLabel.TextXAlignment = Enum.TextXAlignment.Left
                InputLabel.Parent = InputFrame

                local TextBox = Instance.new("TextBox")
                TextBox.Size = UDim2.new(1, -80, 1, -10)
                TextBox.Position = UDim2.new(0, 70, 0, 5)
                TextBox.BackgroundColor3 = Library.Theme.DarkText
                TextBox.BorderSizePixel = 0
                TextBox.Text = default or ""
                TextBox.TextColor3 = Library.Theme.TextColor
                TextBox.TextSize = 14
                TextBox.Font = Enum.Font.Gotham
                TextBox.TextXAlignment = Enum.TextXAlignment.Left
                TextBox.ClearTextOnFocus = false
                TextBox.Parent = InputFrame
                Instance.new("UICorner", TextBox).CornerRadius = UDim.new(0, 4)

                TextBox.FocusLost:Connect(function()
                    if callback then pcall(callback, TextBox.Text) end
                end)
                return InputFrame, function() return TextBox.Text end
            end

            function Section:CreateLabel(text)
                local Label = Instance.new("TextLabel")
                Label.Size = UDim2.new(1, -20, 0, 20)
                Label.Position = UDim2.new(0, 10, 0, 0)
                Label.BackgroundTransparency = 1
                Label.Text = text
                Label.TextColor3 = Library.Theme.DarkText
                Label.TextSize = 13
                Label.Font = Enum.Font.Gotham
                Label.TextXAlignment = Enum.TextXAlignment.Left
                Label.TextWrapped = true
                Label.Parent = SectionFrame
                return Label
            end

            function Section:CreateParagraph(text)
                local ParagraphFrame = Instance.new("Frame")
                ParagraphFrame.Size = UDim2.new(1, -20, 0, 0) -- AutomaticSize.Y
                ParagraphFrame.AutomaticSize = Enum.AutomaticSize.Y
                ParagraphFrame.Position = UDim2.new(0, 10, 0, 0)
                ParagraphFrame.BackgroundTransparency = 1
                ParagraphFrame.Parent = SectionFrame

                local ParagraphLabel = Instance.new("TextLabel")
                ParagraphLabel.Size = UDim2.new(1, 0, 1, 0)
                ParagraphLabel.BackgroundTransparency = 1
                ParagraphLabel.Text = text
                ParagraphLabel.TextColor3 = Library.Theme.DarkText
                ParagraphLabel.TextSize = 13
                ParagraphLabel.Font = Enum.Font.Gotham
                ParagraphLabel.TextXAlignment = Enum.TextXAlignment.Left
                ParagraphLabel.TextWrapped = true
                ParagraphLabel.Parent = ParagraphFrame
                return ParagraphFrame
            end

            return Section
        end
        return Tab
    end

    return Window
end

return Library
