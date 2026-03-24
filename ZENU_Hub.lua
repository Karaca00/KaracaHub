-- ZENU Hub UI Library
-- Theme: Red & Black
-- Version: 2.0.0

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {
    Tabs = {},
    Groups = {},
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
    }
}

-- Utility Functions
local function MakeDraggable(topBar, mainFrame)
    local dragging, dragInput, dragStart, startPos

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
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

local function CreateTween(obj, info, goal)
    local tween = TweenService:Create(obj, TweenInfo.new(table.unpack(info)), goal)
    tween:Play()
    return tween
end

function Library:Notification(title, text, duration)
    local NotificationGui = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui")):FindFirstChild("ZENUNotifGui")
    if not NotificationGui then
        NotificationGui = Instance.new("ScreenGui")
        NotificationGui.Name = "ZENUNotifGui"
        NotificationGui.Parent = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"))
    end

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 280, 0, 70)
    NotifFrame.Position = UDim2.new(1, 10, 1, -80)
    NotifFrame.BackgroundColor3 = Library.Theme.MainColor
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = NotificationGui

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

    CreateTween(NotifFrame, {0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out}, {Position = UDim2.new(1, -290, 1, -80)})
    
    task.delay(duration or 4, function()
        CreateTween(NotifFrame, {0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In}, {Position = UDim2.new(1, 10, 1, -80)})
        task.wait(0.5)
        NotifFrame:Destroy()
    end)
end

function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZENUHub"
    ScreenGui.Parent = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"))
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 600, 0, 400)
    MainFrame.Position = UDim2.new(0.5, -300, 0.5, -200)
    MainFrame.BackgroundColor3 = Library.Theme.MainColor
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

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
    TitleLabel.Text = "ZENU HUB"
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

    -- Minimize Logic
    MinBtn.MouseButton1Click:Connect(function()
        Library.Minimized = not Library.Minimized
        if Library.Minimized then
            CreateTween(MainFrame, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 600, 0, 45)})
            MinBtn.Text = "+"
        else
            CreateTween(MainFrame, {0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(0, 600, 0, 400)})
            MinBtn.Text = "—"
        end
    end)

    CloseBtn.MouseButton1Click:Connect(function()
        CreateTween(MainFrame, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In}, {Size = UDim2.new(0, 0, 0, 0), Position = MainFrame.Position + UDim2.new(0, 300, 0, 200)})
        task.wait(0.3)
        ScreenGui:Destroy()
    end)

    local Window = {
        CurrentTab = nil,
        Tabs = {}
    }

    function Window:CreateGroup(name)
        local GroupFrame = Instance.new("Frame")
        GroupFrame.Name = name .. "Group"
        GroupFrame.Size = UDim2.new(1, 0, 0, 35)
        GroupFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        GroupFrame.BorderSizePixel = 0
        GroupFrame.ClipsDescendants = true
        GroupFrame.Parent = TabContainer

        local GroupCorner = Instance.new("UICorner")
        GroupCorner.CornerRadius = UDim.new(0, 6)
        GroupCorner.Parent = GroupFrame

        local GroupLabel = Instance.new("TextLabel")
        GroupLabel.Size = UDim2.new(1, -40, 0, 35)
        GroupLabel.Position = UDim2.new(0, 10, 0, 0)
        GroupLabel.BackgroundTransparency = 1
        GroupLabel.Text = name
        GroupLabel.TextColor3 = Library.Theme.AccentColor
        GroupLabel.TextSize = 14
        GroupLabel.Font = Enum.Font.GothamBold
        GroupLabel.TextXAlignment = Enum.TextXAlignment.Left
        GroupLabel.Parent = GroupFrame

        local Arrow = Instance.new("TextLabel")
        Arrow.Size = UDim2.new(0, 35, 0, 35)
        Arrow.Position = UDim2.new(1, -35, 0, 0)
        Arrow.BackgroundTransparency = 1
        Arrow.Text = ">"
        Arrow.TextColor3 = Library.Theme.DarkText
        Arrow.TextSize = 14
        Arrow.Font = Enum.Font.GothamBold
        Arrow.Parent = GroupFrame

        local GroupBtn = Instance.new("TextButton")
        GroupBtn.Size = UDim2.new(1, 0, 0, 35)
        GroupBtn.BackgroundTransparency = 1
        GroupBtn.Text = ""
        GroupBtn.Parent = GroupFrame

        local SubTabContainer = Instance.new("Frame")
        SubTabContainer.Size = UDim2.new(1, -10, 0, 0)
        SubTabContainer.Position = UDim2.new(0, 10, 0, 35)
        SubTabContainer.BackgroundTransparency = 1
        SubTabContainer.Parent = GroupFrame

        local SubTabList = Instance.new("UIListLayout")
        SubTabList.Parent = SubTabContainer
        SubTabList.Padding = UDim.new(0, 2)

        local Expanded = false
        local Group = {}

        local function UpdateGroupSize()
            if Expanded then
                local targetHeight = 40 + SubTabList.AbsoluteContentSize.Y
                CreateTween(GroupFrame, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(1, 0, 0, targetHeight)})
                CreateTween(Arrow, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Rotation = 90})
            else
                CreateTween(GroupFrame, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(1, 0, 0, 35)})
                CreateTween(Arrow, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Rotation = 0})
            end
            task.wait(0.3)
            TabContainer.CanvasSize = UDim2.new(0, 0, 0, TabListLayout.AbsoluteContentSize.Y)
        end

        GroupBtn.MouseButton1Click:Connect(function()
            Expanded = not Expanded
            UpdateGroupSize()
        end)

        function Group:CreateTab(name)
            local TabBtn = Instance.new("TextButton")
            TabBtn.Name = name .. "Tab"
            TabBtn.Size = UDim2.new(1, 0, 0, 30)
            TabBtn.BackgroundColor3 = Library.Theme.ElementColor
            TabBtn.BackgroundTransparency = 1
            TabBtn.Text = name
            TabBtn.TextColor3 = Library.Theme.DarkText
            TabBtn.TextSize = 13
            TabBtn.Font = Enum.Font.GothamSemibold
            TabBtn.Parent = SubTabContainer

            local Page = Instance.new("ScrollingFrame")
            Page.Name = name .. "Page"
            Page.Size = UDim2.new(1, -20, 1, -20)
            Page.Position = UDim2.new(0, 10, 0, 10)
            Page.BackgroundTransparency = 1
            Page.ScrollBarThickness = 2
            Page.Visible = false
            Page.CanvasSize = UDim2.new(0, 0, 0, 0)
            Page.Parent = Pages

            local PageList = Instance.new("UIListLayout")
            PageList.Parent = Page
            PageList.SortOrder = Enum.SortOrder.LayoutOrder
            PageList.Padding = UDim.new(0, 12)

            PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 10)
            end)

            TabBtn.MouseButton1Click:Connect(function()
                for _, v in pairs(Pages:GetChildren()) do v.Visible = false end
                for _, v in pairs(TabContainer:GetDescendants()) do
                    if v:IsA("TextButton") and v.Name:find("Tab") then
                        CreateTween(v, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.DarkText, BackgroundTransparency = 1})
                    end
                end
                Page.Visible = true
                CreateTween(TabBtn, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.TextColor, BackgroundTransparency = 0.8})
            end)

            if Window.CurrentTab == nil then
                Page.Visible = true
                TabBtn.TextColor3 = Library.Theme.TextColor
                TabBtn.BackgroundTransparency = 0.8
                Window.CurrentTab = name
                Expanded = true
                UpdateGroupSize()
            end

        local function CreateElements(Tab, Page)
            function Tab:CreateSection(title)
                local SectionFrame = Instance.new("Frame")
                SectionFrame.Name = title .. "Section"
                SectionFrame.Size = UDim2.new(1, 0, 0, 40)
                SectionFrame.BackgroundColor3 = Library.Theme.SectionColor
                SectionFrame.BorderSizePixel = 0
                SectionFrame.Parent = Page

                local SectionCorner = Instance.new("UICorner")
                SectionCorner.CornerRadius = UDim.new(0, 8)
                SectionCorner.Parent = SectionFrame

                local SectionStroke = Instance.new("UIStroke")
                SectionStroke.Color = Library.Theme.BorderColor
                SectionStroke.Thickness = 1
                SectionStroke.Parent = SectionFrame

                local SectionLabel = Instance.new("TextLabel")
                SectionLabel.Size = UDim2.new(1, -20, 0, 30)
                SectionLabel.Position = UDim2.new(0, 10, 0, 5)
                SectionLabel.BackgroundTransparency = 1
                SectionLabel.Text = title:upper()
                SectionLabel.TextColor3 = Library.Theme.AccentColor
                SectionLabel.TextSize = 12
                SectionLabel.Font = Enum.Font.GothamBold
                SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
                SectionLabel.Parent = SectionFrame

                local Container = Instance.new("Frame")
                Container.Name = "Container"
                Container.Size = UDim2.new(1, -20, 0, 0)
                Container.Position = UDim2.new(0, 10, 0, 35)
                Container.BackgroundTransparency = 1
                Container.Parent = SectionFrame

                local ContainerList = Instance.new("UIListLayout")
                ContainerList.Parent = Container
                ContainerList.SortOrder = Enum.SortOrder.LayoutOrder
                ContainerList.Padding = UDim.new(0, 8)

                ContainerList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    SectionFrame.Size = UDim2.new(1, 0, 0, ContainerList.AbsoluteContentSize.Y + 45)
                    Container.Size = UDim2.new(1, -20, 0, ContainerList.AbsoluteContentSize.Y)
                end)

                local Section = {}

                function Section:CreateButton(text, callback)
                    local Button = Instance.new("TextButton")
                    Button.Name = text .. "Button"
                    Button.Size = UDim2.new(1, 0, 0, 35)
                    Button.BackgroundColor3 = Library.Theme.ElementColor
                    Button.Text = text
                    Button.TextColor3 = Library.Theme.TextColor
                    Button.TextSize = 14
                    Button.Font = Enum.Font.GothamSemibold
                    Button.AutoButtonColor = false
                    Button.Parent = Container
                    Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)

                    Button.MouseButton1Click:Connect(function()
                        CreateTween(Button, {0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {BackgroundColor3 = Library.Theme.AccentColor})
                        task.wait(0.1)
                        CreateTween(Button, {0.1, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {BackgroundColor3 = Library.Theme.ElementColor})
                        if callback then callback() end
                    end)
                end

                function Section:CreateToggle(text, default, callback)
                    local Enabled = default or false
                    local Toggle = Instance.new("TextButton")
                    Toggle.Size = UDim2.new(1, 0, 0, 35)
                    Toggle.BackgroundColor3 = Library.Theme.ElementColor
                    Toggle.Text = ""
                    Toggle.Parent = Container
                    Instance.new("UICorner", Toggle).CornerRadius = UDim.new(0, 6)

                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, -50, 1, 0)
                    Label.Position = UDim2.new(0, 10, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = text
                    Label.TextColor3 = Library.Theme.TextColor
                    Label.TextSize = 14
                    Label.Font = Enum.Font.GothamSemibold
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Toggle

                    local Box = Instance.new("Frame")
                    Box.Size = UDim2.new(0, 35, 0, 18)
                    Box.Position = UDim2.new(1, -45, 0.5, -9)
                    Box.BackgroundColor3 = Enabled and Library.Theme.AccentColor or Color3.fromRGB(40, 40, 40)
                    Box.Parent = Toggle
                    Instance.new("UICorner", Box).CornerRadius = UDim.new(1, 0)

                    local Dot = Instance.new("Frame")
                    Dot.Size = UDim2.new(0, 14, 0, 14)
                    Dot.Position = Enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)
                    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                    Dot.Parent = Box
                    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

                    Toggle.MouseButton1Click:Connect(function()
                        Enabled = not Enabled
                        CreateTween(Box, {0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {BackgroundColor3 = Enabled and Library.Theme.AccentColor or Color3.fromRGB(40, 40, 40)})
                        CreateTween(Dot, {0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Position = Enabled and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7)})
                        if callback then callback(Enabled) end
                    end)
                end

                function Section:CreateSlider(text, min, max, default, callback)
                    local Slider = Instance.new("Frame")
                    Slider.Size = UDim2.new(1, 0, 0, 45)
                    Slider.BackgroundColor3 = Library.Theme.ElementColor
                    Slider.Parent = Container
                    Instance.new("UICorner", Slider).CornerRadius = UDim.new(0, 6)

                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, -60, 0, 20)
                    Label.Position = UDim2.new(0, 10, 0, 5)
                    Label.BackgroundTransparency = 1
                    Label.Text = text
                    Label.TextColor3 = Library.Theme.TextColor
                    Label.TextSize = 14
                    Label.Font = Enum.Font.GothamSemibold
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Slider

                    local ValueLabel = Instance.new("TextLabel")
                    ValueLabel.Size = UDim2.new(0, 40, 0, 20)
                    ValueLabel.Position = UDim2.new(1, -50, 0, 5)
                    ValueLabel.BackgroundTransparency = 1
                    ValueLabel.Text = tostring(default or min)
                    ValueLabel.TextColor3 = Library.Theme.AccentColor
                    ValueLabel.TextSize = 14
                    ValueLabel.Font = Enum.Font.GothamBold
                    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
                    ValueLabel.Parent = Slider

                    local Bar = Instance.new("Frame")
                    Bar.Size = UDim2.new(1, -20, 0, 6)
                    Bar.Position = UDim2.new(0, 10, 0, 30)
                    Bar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
                    Bar.Parent = Slider
                    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

                    local Fill = Instance.new("Frame")
                    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
                    Fill.BackgroundColor3 = Library.Theme.AccentColor
                    Fill.Parent = Bar
                    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

                    local SliderBtn = Instance.new("TextButton")
                    SliderBtn.Size = UDim2.new(1, 0, 1, 0)
                    SliderBtn.BackgroundTransparency = 1
                    SliderBtn.Text = ""
                    SliderBtn.Parent = Bar

                    local function Update()
                        local mouseX = Mouse.X
                        local barX = Bar.AbsolutePosition.X
                        local barWidth = Bar.AbsoluteSize.X
                        local percentage = math.clamp((mouseX - barX) / barWidth, 0, 1)
                        local value = math.floor(min + (max - min) * percentage)
                        
                        ValueLabel.Text = tostring(value)
                        Fill.Size = UDim2.new(percentage, 0, 1, 0)
                        if callback then callback(value) end
                    end

                    local dragging = false
                    SliderBtn.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = true
                        end
                    end)
                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 then
                            dragging = false
                        end
                    end)
                    RunService.RenderStepped:Connect(function()
                        if dragging then Update() end
                    end)
                end

                function Section:CreateDropdown(text, list, callback)
                    local Expanded = false
                    local Dropdown = Instance.new("Frame")
                    Dropdown.Size = UDim2.new(1, 0, 0, 35)
                    Dropdown.BackgroundColor3 = Library.Theme.ElementColor
                    Dropdown.ClipsDescendants = true
                    Dropdown.Parent = Container
                    Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 6)

                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, -40, 0, 35)
                    Label.Position = UDim2.new(0, 10, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = text
                    Label.TextColor3 = Library.Theme.TextColor
                    Label.TextSize = 14
                    Label.Font = Enum.Font.GothamSemibold
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Dropdown

                    local Arrow = Instance.new("TextLabel")
                    Arrow.Size = UDim2.new(0, 35, 0, 35)
                    Arrow.Position = UDim2.new(1, -35, 0, 0)
                    Arrow.BackgroundTransparency = 1
                    Arrow.Text = "v"
                    Arrow.TextColor3 = Library.Theme.DarkText
                    Arrow.TextSize = 14
                    Arrow.Font = Enum.Font.GothamBold
                    Arrow.Parent = Dropdown

                    local Btn = Instance.new("TextButton")
                    Btn.Size = UDim2.new(1, 0, 0, 35)
                    Btn.BackgroundTransparency = 1
                    Btn.Text = ""
                    Btn.Parent = Dropdown

                    local ItemContainer = Instance.new("Frame")
                    ItemContainer.Size = UDim2.new(1, -10, 0, #list * 30)
                    ItemContainer.Position = UDim2.new(0, 5, 0, 35)
                    ItemContainer.BackgroundTransparency = 1
                    ItemContainer.Parent = Dropdown
                    Instance.new("UIListLayout", ItemContainer).Padding = UDim.new(0, 2)

                    for _, v in pairs(list) do
                        local ItemBtn = Instance.new("TextButton")
                        ItemBtn.Size = UDim2.new(1, 0, 0, 28)
                        ItemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        ItemBtn.Text = v
                        ItemBtn.TextColor3 = Library.Theme.DarkText
                        ItemBtn.TextSize = 13
                        ItemBtn.Font = Enum.Font.GothamSemibold
                        ItemBtn.Parent = ItemContainer
                        Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 4)

                        ItemBtn.MouseButton1Click:Connect(function()
                            Label.Text = text .. ": " .. v
                            Expanded = false
                            CreateTween(Dropdown, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(1, 0, 0, 35)})
                            CreateTween(Arrow, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Rotation = 0})
                            if callback then callback(v) end
                        end)
                    end

                    Btn.MouseButton1Click:Connect(function()
                        Expanded = not Expanded
                        local targetHeight = Expanded and (40 + (#list * 30)) or 35
                        CreateTween(Dropdown, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(1, 0, 0, targetHeight)})
                        CreateTween(Arrow, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Rotation = Expanded and 180 or 0})
                    end)
                end

                function Section:CreateMultiDropdown(text, list, callback)
                    local Expanded = false
                    local Selected = {}
                    local Dropdown = Instance.new("Frame")
                    Dropdown.Size = UDim2.new(1, 0, 0, 35)
                    Dropdown.BackgroundColor3 = Library.Theme.ElementColor
                    Dropdown.ClipsDescendants = true
                    Dropdown.Parent = Container
                    Instance.new("UICorner", Dropdown).CornerRadius = UDim.new(0, 6)

                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, -40, 0, 35)
                    Label.Position = UDim2.new(0, 10, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = text .. ": None"
                    Label.TextColor3 = Library.Theme.TextColor
                    Label.TextSize = 14
                    Label.Font = Enum.Font.GothamSemibold
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Dropdown

                    local Arrow = Instance.new("TextLabel")
                    Arrow.Size = UDim2.new(0, 35, 0, 35)
                    Arrow.Position = UDim2.new(1, -35, 0, 0)
                    Arrow.BackgroundTransparency = 1
                    Arrow.Text = "v"
                    Arrow.TextColor3 = Library.Theme.DarkText
                    Arrow.TextSize = 14
                    Arrow.Font = Enum.Font.GothamBold
                    Arrow.Parent = Dropdown

                    local Btn = Instance.new("TextButton")
                    Btn.Size = UDim2.new(1, 0, 0, 35)
                    Btn.BackgroundTransparency = 1
                    Btn.Text = ""
                    Btn.Parent = Dropdown

                    local ItemContainer = Instance.new("Frame")
                    ItemContainer.Size = UDim2.new(1, -10, 0, #list * 30)
                    ItemContainer.Position = UDim2.new(0, 5, 0, 35)
                    ItemContainer.BackgroundTransparency = 1
                    ItemContainer.Parent = Dropdown
                    Instance.new("UIListLayout", ItemContainer).Padding = UDim.new(0, 2)

                    for _, v in pairs(list) do
                        local ItemBtn = Instance.new("TextButton")
                        ItemBtn.Size = UDim2.new(1, 0, 0, 28)
                        ItemBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                        ItemBtn.Text = v
                        ItemBtn.TextColor3 = Library.Theme.DarkText
                        ItemBtn.TextSize = 13
                        ItemBtn.Font = Enum.Font.GothamSemibold
                        ItemBtn.Parent = ItemContainer
                        Instance.new("UICorner", ItemBtn).CornerRadius = UDim.new(0, 4)

                        ItemBtn.MouseButton1Click:Connect(function()
                            if table.find(Selected, v) then
                                table.remove(Selected, table.find(Selected, v))
                                CreateTween(ItemBtn, {0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.DarkText, BackgroundColor3 = Color3.fromRGB(35, 35, 35)})
                            else
                                table.insert(Selected, v)
                                CreateTween(ItemBtn, {0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.AccentColor, BackgroundColor3 = Color3.fromRGB(45, 35, 35)})
                            end
                            Label.Text = text .. ": " .. (#Selected > 0 and table.concat(Selected, ", ") or "None")
                            if callback then callback(Selected) end
                        end)
                    end

                    Btn.MouseButton1Click:Connect(function()
                        Expanded = not Expanded
                        local targetHeight = Expanded and (40 + (#list * 30)) or 35
                        CreateTween(Dropdown, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Size = UDim2.new(1, 0, 0, targetHeight)})
                        CreateTween(Arrow, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {Rotation = Expanded and 180 or 0})
                    end)
                end

                function Section:CreateParagraph(title, content)
                    local ParaFrame = Instance.new("Frame")
                    ParaFrame.Size = UDim2.new(1, 0, 0, 60)
                    ParaFrame.BackgroundColor3 = Library.Theme.ElementColor
                    ParaFrame.Parent = Container
                    Instance.new("UICorner", ParaFrame).CornerRadius = UDim.new(0, 6)

                    local Title = Instance.new("TextLabel")
                    Title.Size = UDim2.new(1, -20, 0, 25)
                    Title.Position = UDim2.new(0, 10, 0, 5)
                    Title.BackgroundTransparency = 1
                    Title.Text = title
                    Title.TextColor3 = Library.Theme.AccentColor
                    Title.TextSize = 14
                    Title.Font = Enum.Font.GothamBold
                    Title.TextXAlignment = Enum.TextXAlignment.Left
                    Title.Parent = ParaFrame

                    local Content = Instance.new("TextLabel")
                    Content.Size = UDim2.new(1, -20, 0, 0)
                    Content.Position = UDim2.new(0, 10, 0, 30)
                    Content.BackgroundTransparency = 1
                    Content.Text = content
                    Content.TextColor3 = Library.Theme.TextColor
                    Content.TextSize = 13
                    Content.Font = Enum.Font.Gotham
                    Content.TextXAlignment = Enum.TextXAlignment.Left
                    Content.TextYAlignment = Enum.TextYAlignment.Top
                    Content.TextWrapped = true
                    Content.Parent = ParaFrame

                    Content:GetPropertyChangedSignal("TextBounds"):Connect(function()
                        Content.Size = UDim2.new(1, -20, 0, Content.TextBounds.Y)
                        ParaFrame.Size = UDim2.new(1, 0, 0, Content.TextBounds.Y + 40)
                    end)
                    
                    return {
                        SetContent = function(newText) Content.Text = newText end
                    }
                end

                function Section:CreateLabel(text)
                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(1, 0, 0, 20)
                    Label.BackgroundTransparency = 1
                    Label.Text = "• " .. text
                    Label.TextColor3 = Library.Theme.DarkText
                    Label.TextSize = 13
                    Label.Font = Enum.Font.GothamSemibold
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Container
                    
                    return {
                        SetText = function(newText) Label.Text = "• " .. newText end
                    }
                end

                function Section:CreateInput(text, placeholder, callback)
                    local Input = Instance.new("Frame")
                    Input.Size = UDim2.new(1, 0, 0, 35)
                    Input.BackgroundColor3 = Library.Theme.ElementColor
                    Input.Parent = Container
                    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 6)

                    local Label = Instance.new("TextLabel")
                    Label.Size = UDim2.new(0, 100, 1, 0)
                    Label.Position = UDim2.new(0, 10, 0, 0)
                    Label.BackgroundTransparency = 1
                    Label.Text = text
                    Label.TextColor3 = Library.Theme.TextColor
                    Label.TextSize = 14
                    Label.Font = Enum.Font.GothamSemibold
                    Label.TextXAlignment = Enum.TextXAlignment.Left
                    Label.Parent = Input

                    local Box = Instance.new("TextBox")
                    Box.Size = UDim2.new(1, -120, 0, 25)
                    Box.Position = UDim2.new(0, 110, 0.5, -12)
                    Box.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
                    Box.Text = ""
                    Box.PlaceholderText = placeholder or "Type..."
                    Box.TextColor3 = Library.Theme.TextColor
                    Box.PlaceholderColor3 = Library.Theme.DarkText
                    Box.TextSize = 13
                    Box.Font = Enum.Font.Gotham
                    Box.Parent = Input
                    Instance.new("UICorner", Box).CornerRadius = UDim.new(0, 4)

                    Box.FocusLost:Connect(function()
                        if callback then callback(Box.Text) end
                    end)
                end

                return Section
            end
        end

        function Group:CreateTab(name)
            local TabBtn = Instance.new("TextButton")
            TabBtn.Name = name .. "Tab"
            TabBtn.Size = UDim2.new(1, 0, 0, 30)
            TabBtn.BackgroundColor3 = Library.Theme.ElementColor
            TabBtn.BackgroundTransparency = 1
            TabBtn.Text = name
            TabBtn.TextColor3 = Library.Theme.DarkText
            TabBtn.TextSize = 13
            TabBtn.Font = Enum.Font.GothamSemibold
            TabBtn.Parent = SubTabContainer

            local Page = Instance.new("ScrollingFrame")
            Page.Name = name .. "Page"
            Page.Size = UDim2.new(1, -20, 1, -20)
            Page.Position = UDim2.new(0, 10, 0, 10)
            Page.BackgroundTransparency = 1
            Page.ScrollBarThickness = 2
            Page.Visible = false
            Page.CanvasSize = UDim2.new(0, 0, 0, 0)
            Page.Parent = Pages

            local PageList = Instance.new("UIListLayout")
            PageList.Parent = Page
            PageList.SortOrder = Enum.SortOrder.LayoutOrder
            PageList.Padding = UDim.new(0, 12)

            PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 10)
            end)

            TabBtn.MouseButton1Click:Connect(function()
                for _, v in pairs(Pages:GetChildren()) do v.Visible = false end
                for _, v in pairs(TabContainer:GetDescendants()) do
                    if v:IsA("TextButton") and v.Name:find("Tab") then
                        CreateTween(v, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.DarkText, BackgroundTransparency = 1})
                    end
                end
                Page.Visible = true
                CreateTween(TabBtn, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.TextColor, BackgroundTransparency = 0.8})
            end)

            if Window.CurrentTab == nil then
                Page.Visible = true
                TabBtn.TextColor3 = Library.Theme.TextColor
                TabBtn.BackgroundTransparency = 0.8
                Window.CurrentTab = name
                Expanded = true
                UpdateGroupSize()
            end

            local Tab = {}
            CreateElements(Tab, Page)
            return Tab
        end

        return Group
    end

    function Window:CreateTab(name)
        local TabBtn = Instance.new("TextButton")
        TabBtn.Name = name .. "Tab"
        TabBtn.Size = UDim2.new(1, 0, 0, 35)
        TabBtn.BackgroundColor3 = Library.Theme.ElementColor
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = name
        TabBtn.TextColor3 = Library.Theme.DarkText
        TabBtn.TextSize = 14
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.Parent = TabContainer
        Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Size = UDim2.new(1, -20, 1, -20)
        Page.Position = UDim2.new(0, 10, 0, 10)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.Visible = false
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Parent = Pages

        local PageList = Instance.new("UIListLayout")
        PageList.Parent = Page
        PageList.SortOrder = Enum.SortOrder.LayoutOrder
        PageList.Padding = UDim.new(0, 12)

        PageList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageList.AbsoluteContentSize.Y + 10)
        end)

        TabBtn.MouseButton1Click:Connect(function()
            for _, v in pairs(Pages:GetChildren()) do v.Visible = false end
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then
                    CreateTween(v, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.DarkText, BackgroundTransparency = 1})
                end
            end
            Page.Visible = true
            CreateTween(TabBtn, {0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out}, {TextColor3 = Library.Theme.TextColor, BackgroundTransparency = 0.5})
        end)

        if Window.CurrentTab == nil then
            Page.Visible = true
            TabBtn.TextColor3 = Library.Theme.TextColor
            TabBtn.BackgroundTransparency = 0.5
            Window.CurrentTab = name
        end

        local Tab = {}
        CreateElements(Tab, Page)
        return Tab
    end

    return Window
end

return Library
