-- Manus UI Library for Roblox
-- A clean, modern, and categorized UI library for scripts

local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Library = {
    Tabs = {},
    Flags = {},
    Theme = {
        MainColor = Color3.fromRGB(30, 30, 35),
        SecondaryColor = Color3.fromRGB(40, 40, 45),
        AccentColor = Color3.fromRGB(0, 170, 255),
        TextColor = Color3.fromRGB(255, 255, 255),
        DarkText = Color3.fromRGB(180, 180, 180),
        ElementColor = Color3.fromRGB(45, 45, 50),
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

function Library:Notification(title, text, duration)
    local NotificationGui = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui")):FindFirstChild("ManusNotificationGui")
    if not NotificationGui then
        NotificationGui = Instance.new("ScreenGui")
        NotificationGui.Name = "ManusNotificationGui"
        NotificationGui.Parent = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"))
    end

    local NotifFrame = Instance.new("Frame")
    NotifFrame.Size = UDim2.new(0, 250, 0, 60)
    NotifFrame.Position = UDim2.new(1, 10, 1, -70)
    NotifFrame.BackgroundColor3 = Library.Theme.MainColor
    NotifFrame.BorderSizePixel = 0
    NotifFrame.Parent = NotificationGui

    local NotifCorner = Instance.new("UICorner")
    NotifCorner.CornerRadius = UDim.new(0, 6)
    NotifCorner.Parent = NotifFrame

    local NotifTitle = Instance.new("TextLabel")
    NotifTitle.Size = UDim2.new(1, -20, 0, 25)
    NotifTitle.Position = UDim2.new(0, 10, 0, 5)
    NotifTitle.BackgroundTransparency = 1
    NotifTitle.Text = title
    NotifTitle.TextColor3 = Library.Theme.AccentColor
    NotifTitle.TextSize = 14
    NotifTitle.Font = Enum.Font.GothamBold
    NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
    NotifTitle.Parent = NotifFrame

    local NotifText = Instance.new("TextLabel")
    NotifText.Size = UDim2.new(1, -20, 0, 25)
    NotifText.Position = UDim2.new(0, 10, 0, 30)
    NotifText.BackgroundTransparency = 1
    NotifText.Text = text
    NotifText.TextColor3 = Library.Theme.TextColor
    NotifText.TextSize = 13
    NotifText.Font = Enum.Font.Gotham
    NotifText.TextXAlignment = Enum.TextXAlignment.Left
    NotifText.Parent = NotifFrame

    TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = UDim2.new(1, -260, 1, -70)}):Play()
    
    task.delay(duration or 3, function()
        TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.new(1, 10, 1, -70)}):Play()
        task.wait(0.5)
        NotifFrame:Destroy()
    end)
end

function Library:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ManusUILib"
    ScreenGui.Parent = (RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"))
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 550, 0, 350)
    MainFrame.Position = UDim2.new(0.5, -275, 0.5, -175)
    MainFrame.BackgroundColor3 = Library.Theme.MainColor
    MainFrame.BorderSizePixel = 0
    MainFrame.Parent = ScreenGui

    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(0, 8)
    UICorner.Parent = MainFrame

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Size = UDim2.new(0, 150, 1, 0)
    Sidebar.BackgroundColor3 = Library.Theme.SecondaryColor
    Sidebar.BorderSizePixel = 0
    Sidebar.Parent = MainFrame

    local SidebarCorner = Instance.new("UICorner")
    SidebarCorner.CornerRadius = UDim.new(0, 8)
    SidebarCorner.Parent = Sidebar

    -- Fix for Sidebar Corner (only left side)
    local SidebarCover = Instance.new("Frame")
    SidebarCover.Name = "SidebarCover"
    SidebarCover.Size = UDim2.new(0, 10, 1, 0)
    SidebarCover.Position = UDim2.new(1, -10, 0, 0)
    SidebarCover.BackgroundColor3 = Library.Theme.SecondaryColor
    SidebarCover.BorderSizePixel = 0
    SidebarCover.Parent = Sidebar

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Name = "Title"
    TitleLabel.Size = UDim2.new(1, 0, 0, 40)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Text = title or "Manus UI"
    TitleLabel.TextColor3 = Library.Theme.TextColor
    TitleLabel.TextSize = 18
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Parent = Sidebar

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, 0, 1, -50)
    TabContainer.Position = UDim2.new(0, 0, 0, 45)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 2
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.Parent = Sidebar

    local TabListLayout = Instance.new("UIListLayout")
    TabListLayout.Parent = TabContainer
    TabListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    TabListLayout.Padding = UDim.new(0, 5)

    local TabPadding = Instance.new("UIPadding")
    TabPadding.PaddingLeft = UDim.new(0, 10)
    TabPadding.PaddingRight = UDim.new(0, 10)
    TabPadding.Parent = TabContainer

    -- Search Bar
    local SearchFrame = Instance.new("Frame")
    SearchFrame.Name = "SearchFrame"
    SearchFrame.Size = UDim2.new(1, -20, 0, 30)
    SearchFrame.Position = UDim2.new(0, 10, 0, 45)
    SearchFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    SearchFrame.Parent = Sidebar

    local SearchCorner = Instance.new("UICorner")
    SearchCorner.CornerRadius = UDim.new(0, 6)
    SearchCorner.Parent = SearchFrame

    local SearchInput = Instance.new("TextBox")
    SearchInput.Name = "SearchInput"
    SearchInput.Size = UDim2.new(1, -10, 1, 0)
    SearchInput.Position = UDim2.new(0, 5, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.Text = ""
    SearchInput.PlaceholderText = "Search..."
    SearchInput.TextColor3 = Library.Theme.TextColor
    SearchInput.PlaceholderColor3 = Library.Theme.DarkText
    SearchInput.TextSize = 13
    SearchInput.Font = Enum.Font.Gotham
    SearchInput.Parent = SearchFrame

    TabContainer.Position = UDim2.new(0, 0, 0, 80)
    TabContainer.Size = UDim2.new(1, 0, 1, -85)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local text = SearchInput.Text:lower()
        for _, v in pairs(TabContainer:GetChildren()) do
            if v:IsA("TextButton") then
                if text == "" or v.Text:lower():find(text) then
                    v.Visible = true
                else
                    v.Visible = false
                end
            end
        end
    end)

    -- Content Area
    local ContentArea = Instance.new("Frame")
    ContentArea.Name = "ContentArea"
    ContentArea.Size = UDim2.new(1, -150, 1, 0)
    ContentArea.Position = UDim2.new(0, 150, 0, 0)
    ContentArea.BackgroundTransparency = 1
    ContentArea.Parent = MainFrame

    local Pages = Instance.new("Frame")
    Pages.Name = "Pages"
    Pages.Size = UDim2.new(1, 0, 1, -10)
    Pages.Position = UDim2.new(0, 0, 0, 5)
    Pages.BackgroundTransparency = 1
    Pages.Parent = ContentArea

    MakeDraggable(Sidebar, MainFrame)

    local Window = {
        CurrentTab = nil
    }

    function Window:CreateTab(name, icon)
        local TabButton = Instance.new("TextButton")
        TabButton.Name = name .. "Tab"
        TabButton.Size = UDim2.new(1, 0, 0, 35)
        TabButton.BackgroundColor3 = Library.Theme.ElementColor
        TabButton.BackgroundTransparency = 1
        TabButton.Text = name
        TabButton.TextColor3 = Library.Theme.DarkText
        TabButton.TextSize = 14
        TabButton.Font = Enum.Font.GothamSemibold
        TabButton.AutoButtonColor = false
        TabButton.Parent = TabContainer

        local TabButtonCorner = Instance.new("UICorner")
        TabButtonCorner.CornerRadius = UDim.new(0, 6)
        TabButtonCorner.Parent = TabButton

        local Page = Instance.new("ScrollingFrame")
        Page.Name = name .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 4
        Page.Visible = false
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.Parent = Pages

        local PageListLayout = Instance.new("UIListLayout")
        PageListLayout.Parent = Page
        PageListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageListLayout.Padding = UDim.new(0, 8)

        local PagePadding = Instance.new("UIPadding")
        PagePadding.PaddingLeft = UDim.new(0, 15)
        PagePadding.PaddingRight = UDim.new(0, 15)
        PagePadding.PaddingTop = UDim.new(0, 10)
        PagePadding.PaddingBottom = UDim.new(0, 10)
        PagePadding.Parent = Page

        PageListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageListLayout.AbsoluteContentSize.Y + 20)
        end)

        TabButton.MouseButton1Click:Connect(function()
            for _, v in pairs(Pages:GetChildren()) do
                v.Visible = false
            end
            for _, v in pairs(TabContainer:GetChildren()) do
                if v:IsA("TextButton") then
                    TweenService:Create(v, TweenInfo.new(0.3), {BackgroundTransparency = 1, TextColor3 = Library.Theme.DarkText}):Play()
                end
            end
            Page.Visible = true
            TweenService:Create(TabButton, TweenInfo.new(0.3), {BackgroundTransparency = 0, TextColor3 = Library.Theme.TextColor}):Play()
            Window.CurrentTab = name
        end)

        -- Initialize first tab
        if Window.CurrentTab == nil then
            Page.Visible = true
            TabButton.BackgroundTransparency = 0
            TabButton.TextColor3 = Library.Theme.TextColor
            Window.CurrentTab = name
        end

        local Tab = {}

        function Tab:CreateSection(title)
            local SectionLabel = Instance.new("TextLabel")
            SectionLabel.Name = title .. "Section"
            SectionLabel.Size = UDim2.new(1, 0, 0, 25)
            SectionLabel.BackgroundTransparency = 1
            SectionLabel.Text = title:upper()
            SectionLabel.TextColor3 = Library.Theme.AccentColor
            SectionLabel.TextSize = 12
            SectionLabel.Font = Enum.Font.GothamBold
            SectionLabel.TextXAlignment = Enum.TextXAlignment.Left
            SectionLabel.Parent = Page
            
            return Tab
        end

        function Tab:CreateButton(text, callback)
            local Button = Instance.new("TextButton")
            Button.Name = text .. "Button"
            Button.Size = UDim2.new(1, 0, 0, 35)
            Button.BackgroundColor3 = Library.Theme.ElementColor
            Button.Text = text
            Button.TextColor3 = Library.Theme.TextColor
            Button.TextSize = 14
            Button.Font = Enum.Font.GothamSemibold
            Button.AutoButtonColor = false
            Button.Parent = Page

            local ButtonCorner = Instance.new("UICorner")
            ButtonCorner.CornerRadius = UDim.new(0, 6)
            ButtonCorner.Parent = Button

            Button.MouseButton1Click:Connect(function()
                TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.AccentColor}):Play()
                task.wait(0.1)
                TweenService:Create(Button, TweenInfo.new(0.1), {BackgroundColor3 = Library.Theme.ElementColor}):Play()
                if callback then callback() end
            end)
        end

        function Tab:CreateToggle(text, default, callback)
            local ToggleEnabled = default or false
            
            local ToggleFrame = Instance.new("Frame")
            ToggleFrame.Name = text .. "Toggle"
            ToggleFrame.Size = UDim2.new(1, 0, 0, 35)
            ToggleFrame.BackgroundColor3 = Library.Theme.ElementColor
            ToggleFrame.Parent = Page

            local ToggleCorner = Instance.new("UICorner")
            ToggleCorner.CornerRadius = UDim.new(0, 6)
            ToggleCorner.Parent = ToggleFrame

            local ToggleLabel = Instance.new("TextLabel")
            ToggleLabel.Size = UDim2.new(1, -50, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 10, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.TextColor3 = Library.Theme.TextColor
            ToggleLabel.TextSize = 14
            ToggleLabel.Font = Enum.Font.GothamSemibold
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.Parent = ToggleFrame

            local ToggleOuter = Instance.new("Frame")
            ToggleOuter.Size = UDim2.new(0, 40, 0, 20)
            ToggleOuter.Position = UDim2.new(1, -50, 0.5, -10)
            ToggleOuter.BackgroundColor3 = ToggleEnabled and Library.Theme.AccentColor or Color3.fromRGB(80, 80, 85)
            ToggleOuter.Parent = ToggleFrame

            local OuterCorner = Instance.new("UICorner")
            OuterCorner.CornerRadius = UDim.new(1, 0)
            OuterCorner.Parent = ToggleOuter

            local ToggleInner = Instance.new("Frame")
            ToggleInner.Size = UDim2.new(0, 16, 0, 16)
            ToggleInner.Position = ToggleEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
            ToggleInner.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            ToggleInner.Parent = ToggleOuter

            local InnerCorner = Instance.new("UICorner")
            InnerCorner.CornerRadius = UDim.new(1, 0)
            InnerCorner.Parent = ToggleInner

            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Size = UDim2.new(1, 0, 1, 0)
            ToggleButton.BackgroundTransparency = 1
            ToggleButton.Text = ""
            ToggleButton.Parent = ToggleFrame

            ToggleButton.MouseButton1Click:Connect(function()
                ToggleEnabled = not ToggleEnabled
                TweenService:Create(ToggleOuter, TweenInfo.new(0.2), {BackgroundColor3 = ToggleEnabled and Library.Theme.AccentColor or Color3.fromRGB(80, 80, 85)}):Play()
                TweenService:Create(ToggleInner, TweenInfo.new(0.2), {Position = ToggleEnabled and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)}):Play()
                if callback then callback(ToggleEnabled) end
            end)
        end

        function Tab:CreateSlider(text, min, max, default, callback)
            local SliderFrame = Instance.new("Frame")
            SliderFrame.Name = text .. "Slider"
            SliderFrame.Size = UDim2.new(1, 0, 0, 45)
            SliderFrame.BackgroundColor3 = Library.Theme.ElementColor
            SliderFrame.Parent = Page

            local SliderCorner = Instance.new("UICorner")
            SliderCorner.CornerRadius = UDim.new(0, 6)
            SliderCorner.Parent = SliderFrame

            local SliderLabel = Instance.new("TextLabel")
            SliderLabel.Size = UDim2.new(1, -60, 0, 20)
            SliderLabel.Position = UDim2.new(0, 10, 0, 5)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = text
            SliderLabel.TextColor3 = Library.Theme.TextColor
            SliderLabel.TextSize = 14
            SliderLabel.Font = Enum.Font.GothamSemibold
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            SliderLabel.Parent = SliderFrame

            local ValueLabel = Instance.new("TextLabel")
            ValueLabel.Size = UDim2.new(0, 40, 0, 20)
            ValueLabel.Position = UDim2.new(1, -50, 0, 5)
            ValueLabel.BackgroundTransparency = 1
            ValueLabel.Text = tostring(default or min)
            ValueLabel.TextColor3 = Library.Theme.DarkText
            ValueLabel.TextSize = 14
            ValueLabel.Font = Enum.Font.GothamSemibold
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValueLabel.Parent = SliderFrame

            local SliderBar = Instance.new("Frame")
            SliderBar.Size = UDim2.new(1, -20, 0, 6)
            SliderBar.Position = UDim2.new(0, 10, 0, 30)
            SliderBar.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
            SliderBar.Parent = SliderFrame

            local BarCorner = Instance.new("UICorner")
            BarCorner.CornerRadius = UDim.new(1, 0)
            BarCorner.Parent = SliderBar

            local SliderFill = Instance.new("Frame")
            SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Library.Theme.AccentColor
            SliderFill.Parent = SliderBar

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(1, 0)
            FillCorner.Parent = SliderFill

            local SliderButton = Instance.new("TextButton")
            SliderButton.Size = UDim2.new(1, 0, 1, 0)
            SliderButton.BackgroundTransparency = 1
            SliderButton.Text = ""
            SliderButton.Parent = SliderBar

            local function UpdateSlider()
                local mouseX = Mouse.X
                local barX = SliderBar.AbsolutePosition.X
                local barWidth = SliderBar.AbsoluteSize.X
                local percentage = math.clamp((mouseX - barX) / barWidth, 0, 1)
                local value = math.floor(min + (max - min) * percentage)
                
                ValueLabel.Text = tostring(value)
                TweenService:Create(SliderFill, TweenInfo.new(0.1), {Size = UDim2.new(percentage, 0, 1, 0)}):Play()
                if callback then callback(value) end
            end

            local dragging = false
            SliderButton.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    UpdateSlider()
                end
            end)

            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)

            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider()
                end
            end)
        end

        function Tab:CreateDropdown(text, list, callback)
            local DropdownEnabled = false
            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Name = text .. "Dropdown"
            DropdownFrame.Size = UDim2.new(1, 0, 0, 35)
            DropdownFrame.BackgroundColor3 = Library.Theme.ElementColor
            DropdownFrame.ClipsDescendants = true
            DropdownFrame.Parent = Page

            local DropdownCorner = Instance.new("UICorner")
            DropdownCorner.CornerRadius = UDim.new(0, 6)
            DropdownCorner.Parent = DropdownFrame

            local DropdownLabel = Instance.new("TextLabel")
            DropdownLabel.Size = UDim2.new(1, -40, 0, 35)
            DropdownLabel.Position = UDim2.new(0, 10, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = text
            DropdownLabel.TextColor3 = Library.Theme.TextColor
            DropdownLabel.TextSize = 14
            DropdownLabel.Font = Enum.Font.GothamSemibold
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            DropdownLabel.Parent = DropdownFrame

            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 35, 0, 35)
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "v"
            Arrow.TextColor3 = Library.Theme.DarkText
            Arrow.TextSize = 14
            Arrow.Font = Enum.Font.GothamBold
            Arrow.Parent = DropdownFrame

            local DropdownButton = Instance.new("TextButton")
            DropdownButton.Size = UDim2.new(1, 0, 0, 35)
            DropdownButton.BackgroundTransparency = 1
            DropdownButton.Text = ""
            DropdownButton.Parent = DropdownFrame

            local ItemContainer = Instance.new("Frame")
            ItemContainer.Size = UDim2.new(1, -20, 0, #list * 30)
            ItemContainer.Position = UDim2.new(0, 10, 0, 35)
            ItemContainer.BackgroundTransparency = 1
            ItemContainer.Parent = DropdownFrame

            local ItemListLayout = Instance.new("UIListLayout")
            ItemListLayout.Parent = ItemContainer
            ItemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            ItemListLayout.Padding = UDim.new(0, 2)

            for _, item in pairs(list) do
                local ItemButton = Instance.new("TextButton")
                ItemButton.Size = UDim2.new(1, 0, 0, 28)
                ItemButton.BackgroundColor3 = Color3.fromRGB(55, 55, 60)
                ItemButton.Text = item
                ItemButton.TextColor3 = Library.Theme.DarkText
                ItemButton.TextSize = 13
                ItemButton.Font = Enum.Font.GothamSemibold
                ItemButton.Parent = ItemContainer

                local ItemCorner = Instance.new("UICorner")
                ItemCorner.CornerRadius = UDim.new(0, 4)
                ItemCorner.Parent = ItemButton

                ItemButton.MouseButton1Click:Connect(function()
                    DropdownLabel.Text = text .. ": " .. item
                    DropdownEnabled = false
                    TweenService:Create(DropdownFrame, TweenInfo.new(0.3), {Size = UDim2.new(1, 0, 0, 35)}):Play()
                    TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = 0}):Play()
                    if callback then callback(item) end
                end)
            end

            DropdownButton.MouseButton1Click:Connect(function()
                DropdownEnabled = not DropdownEnabled
                local targetSize = DropdownEnabled and UDim2.new(1, 0, 0, 40 + (#list * 30)) or UDim2.new(1, 0, 0, 35)
                TweenService:Create(DropdownFrame, TweenInfo.new(0.3), {Size = targetSize}):Play()
                TweenService:Create(Arrow, TweenInfo.new(0.3), {Rotation = DropdownEnabled and 180 or 0}):Play()
            end)
        end

        function Tab:CreateInput(text, placeholder, callback)
            local InputFrame = Instance.new("Frame")
            InputFrame.Name = text .. "Input"
            InputFrame.Size = UDim2.new(1, 0, 0, 35)
            InputFrame.BackgroundColor3 = Library.Theme.ElementColor
            InputFrame.Parent = Page

            local InputCorner = Instance.new("UICorner")
            InputCorner.CornerRadius = UDim.new(0, 6)
            InputCorner.Parent = InputFrame

            local InputLabel = Instance.new("TextLabel")
            InputLabel.Size = UDim2.new(0, 100, 1, 0)
            InputLabel.Position = UDim2.new(0, 10, 0, 0)
            InputLabel.BackgroundTransparency = 1
            InputLabel.Text = text
            InputLabel.TextColor3 = Library.Theme.TextColor
            InputLabel.TextSize = 14
            InputLabel.Font = Enum.Font.GothamSemibold
            InputLabel.TextXAlignment = Enum.TextXAlignment.Left
            InputLabel.Parent = InputFrame

            local TextBox = Instance.new("TextBox")
            TextBox.Size = UDim2.new(1, -120, 0, 25)
            TextBox.Position = UDim2.new(0, 110, 0.5, -12)
            TextBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            TextBox.Text = ""
            TextBox.PlaceholderText = placeholder or "Type here..."
            TextBox.TextColor3 = Library.Theme.TextColor
            TextBox.PlaceholderColor3 = Library.Theme.DarkText
            TextBox.TextSize = 13
            TextBox.Font = Enum.Font.Gotham
            TextBox.Parent = InputFrame

            local TextCorner = Instance.new("UICorner")
            TextCorner.CornerRadius = UDim.new(0, 4)
            TextCorner.Parent = TextBox

            TextBox.FocusLost:Connect(function()
                if callback then callback(TextBox.Text) end
            end)
        end

        function Tab:CreateLabel(text)
            local Label = Instance.new("TextLabel")
            Label.Name = "Label"
            Label.Size = UDim2.new(1, 0, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Library.Theme.DarkText
            Label.TextSize = 13
            Label.Font = Enum.Font.Gotham
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Page
            
            return {
                SetText = function(newText)
                    Label.Text = newText
                end
            }
        end

        function Tab:CreateKeybind(text, default, callback)
            local Key = default or Enum.KeyCode.RightControl
            local Binding = false

            local BindFrame = Instance.new("Frame")
            BindFrame.Name = text .. "Keybind"
            BindFrame.Size = UDim2.new(1, 0, 0, 35)
            BindFrame.BackgroundColor3 = Library.Theme.ElementColor
            BindFrame.Parent = Page

            local BindCorner = Instance.new("UICorner")
            BindCorner.CornerRadius = UDim.new(0, 6)
            BindCorner.Parent = BindFrame

            local BindLabel = Instance.new("TextLabel")
            BindLabel.Size = UDim2.new(1, -100, 1, 0)
            BindLabel.Position = UDim2.new(0, 10, 0, 0)
            BindLabel.BackgroundTransparency = 1
            BindLabel.Text = text
            BindLabel.TextColor3 = Library.Theme.TextColor
            BindLabel.TextSize = 14
            BindLabel.Font = Enum.Font.GothamSemibold
            BindLabel.TextXAlignment = Enum.TextXAlignment.Left
            BindLabel.Parent = BindFrame

            local BindButton = Instance.new("TextButton")
            BindButton.Size = UDim2.new(0, 80, 0, 25)
            BindButton.Position = UDim2.new(1, -90, 0.5, -12)
            BindButton.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
            BindButton.Text = Key.Name
            BindButton.TextColor3 = Library.Theme.AccentColor
            BindButton.TextSize = 13
            BindButton.Font = Enum.Font.GothamBold
            BindButton.Parent = BindFrame

            local BindBtnCorner = Instance.new("UICorner")
            BindBtnCorner.CornerRadius = UDim.new(0, 4)
            BindBtnCorner.Parent = BindButton

            BindButton.MouseButton1Click:Connect(function()
                BindButton.Text = "..."
                Binding = true
            end)

            UserInputService.InputBegan:Connect(function(input)
                if Binding and input.UserInputType == Enum.UserInputType.Keyboard then
                    Key = input.KeyCode
                    BindButton.Text = Key.Name
                    Binding = false
                elseif not Binding and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Key then
                    if callback then callback() end
                end
            end)
        end

        return Tab
    end

    return Window
end

return Library
