local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local ZENU_Lib = {}

-- [[ Configuration & Theme ]]
local Theme = {
    MainSide = Color3.fromRGB(15, 15, 15),
    Background = Color3.fromRGB(25, 25, 25),
    Section = Color3.fromRGB(35, 35, 35),
    Accent = Color3.fromRGB(255, 0, 0), -- Red 'Z' Style
    Text = Color3.fromRGB(240, 240, 240),
    TextDark = Color3.fromRGB(180, 180, 180),
    Font = Enum.Font.GothamMedium
}

-- [[ Utility Functions ]]
local function MakeDraggable(topbar, object)
    local dragging, dragInput, dragStart, startPos
    topbar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = object.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            object.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    topbar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

function ZENU_Lib:CreateWindow(hubName)
    local ScreenGui = Instance.new("ScreenGui", CoreGui)
    ScreenGui.Name = "ZENU_Hub"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- Main Frame
    local Main = Instance.new("Frame", ScreenGui)
    Main.Size = UDim2.new(0, 550, 0, 350)
    Main.Position = UDim2.new(0.5, -275, 0.5, -175)
    Main.BackgroundColor3 = Theme.Background
    Main.ClipsDescendants = true
    
    local MainCorner = Instance.new("UICorner", Main)
    MainCorner.CornerRadius = UDim.new(0, 10)

    -- Windows 11 Style Stroke
    local MainStroke = Instance.new("UIStroke", Main)
    MainStroke.Color = Color3.fromRGB(50, 50, 50)
    MainStroke.Thickness = 1.5

    -- TopBar
    local TopBar = Instance.new("Frame", Main)
    TopBar.Size = UDim2.new(1, 0, 0, 40)
    TopBar.BackgroundTransparency = 1
    
    local Logo = Instance.new("TextLabel", TopBar)
    Logo.Text = "Z"
    Logo.TextColor3 = Theme.Accent
    Logo.TextSize = 24
    Logo.Font = Enum.Font.GothamBold
    Logo.Size = UDim2.new(0, 40, 1, 0)
    Logo.BackgroundTransparency = 1

    local Title = Instance.new("TextLabel", TopBar)
    Title.Text = hubName or "ZENU Hub"
    Title.Position = UDim2.new(0, 45, 0, 0)
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.TextColor3 = Theme.Text
    Title.Font = Theme.Font
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.BackgroundTransparency = 1

    -- Control Buttons (Minimize / Close)
    local Controls = Instance.new("Frame", TopBar)
    Controls.Size = UDim2.new(0, 80, 1, 0)
    Controls.Position = UDim2.new(1, -80, 0, 0)
    Controls.BackgroundTransparency = 1

    local CloseBtn = Instance.new("TextButton", Controls)
    CloseBtn.Text = "×"
    CloseBtn.Size = UDim2.new(0.5, 0, 1, 0)
    CloseBtn.Position = UDim2.new(0.5, 0, 0, 0)
    CloseBtn.TextColor3 = Theme.Text
    CloseBtn.TextSize = 20
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local MinimizeBtn = Instance.new("TextButton", Controls)
    MinimizeBtn.Text = "—"
    MinimizeBtn.Size = UDim2.new(0.5, 0, 1, 0)
    MinimizeBtn.TextColor3 = Theme.Text
    MinimizeBtn.BackgroundTransparency = 1

    -- Minimize Logic
    local minimized = false
    local originalSize = Main.Size
    MinimizeBtn.MouseButton1Click:Connect(function()
        minimized = not minimized
        if minimized then
            TweenService:Create(Main, TweenInfo.new(0.3), {Size = UDim2.new(0, 550, 0, 40)}):Play()
            MinimizeBtn.Text = "+"
        else
            TweenService:Create(Main, TweenInfo.new(0.3), {Size = originalSize}):Play()
            MinimizeBtn.Text = "—"
        end
    end)

    MakeDraggable(TopBar, Main)

    -- Sidebar & Container
    local Sidebar = Instance.new("ScrollingFrame", Main)
    Sidebar.Size = UDim2.new(0, 150, 1, -40)
    Sidebar.Position = UDim2.new(0, 0, 0, 40)
    Sidebar.BackgroundColor3 = Theme.MainSide
    Sidebar.BorderSizePixel = 0
    Sidebar.ScrollBarThickness = 0
    
    local SidebarLayout = Instance.new("UIListLayout", Sidebar)
    SidebarLayout.Padding = UDim.new(0, 5)
    
    local Container = Instance.new("Frame", Main)
    Container.Size = UDim2.new(1, -160, 1, -50)
    Container.Position = UDim2.new(0, 155, 0, 45)
    Container.BackgroundTransparency = 1

    local Window = {}

    -- [[ Tab Groups System ]]
    function Window:CreateTabGroup(groupName)
        local GroupBtn = Instance.new("TextButton", Sidebar)
        GroupBtn.Size = UDim2.new(1, -10, 0, 30)
        GroupBtn.BackgroundColor3 = Theme.Section
        GroupBtn.Text = " ▼ " .. groupName
        GroupBtn.TextColor3 = Theme.Accent
        GroupBtn.Font = Theme.Font
        GroupBtn.TextSize = 14
        
        local GroupContainer = Instance.new("Frame", Sidebar)
        GroupContainer.Size = UDim2.new(1, 0, 0, 0)
        GroupContainer.AutomaticSize = Enum.AutomaticSize.Y
        GroupContainer.BackgroundTransparency = 1
        GroupContainer.Visible = true
        
        local GroupLayout = Instance.new("UIListLayout", GroupContainer)
        
        GroupBtn.MouseButton1Click:Connect(function()
            GroupContainer.Visible = not GroupContainer.Visible
            GroupBtn.Text = (GroupContainer.Visible and " ▼ " or " ▶ ") .. groupName
        end)

        local TabGroup = {}
        function TabGroup:CreateTab(name)
            local TabBtn = Instance.new("TextButton", GroupContainer)
            TabBtn.Size = UDim2.new(1, 0, 0, 30)
            TabBtn.BackgroundTransparency = 1
            TabBtn.Text = "   " .. name
            TabBtn.TextColor3 = Theme.TextDark
            TabBtn.Font = Theme.Font
            TabBtn.TextXAlignment = Enum.TextXAlignment.Left

            local Page = Instance.new("ScrollingFrame", Container)
            Page.Size = UDim2.new(1, 0, 1, 0)
            Page.BackgroundTransparency = 1
            Page.Visible = false
            Page.ScrollBarThickness = 2
            Page.ScrollBarImageColor3 = Theme.Accent

            local PageLayout = Instance.new("UIListLayout", Page)
            PageLayout.Padding = UDim.new(0, 10)

            TabBtn.MouseButton1Click:Connect(function()
                for _, v in pairs(Container:GetChildren()) do v.Visible = false end
                Page.Visible = true
            end)

            local SectionLib = {}
            function SectionLib:CreateSection(secName)
                local SecFrame = Instance.new("Frame", Page)
                SecFrame.Size = UDim2.new(1, -10, 0, 0)
                SecFrame.AutomaticSize = Enum.AutomaticSize.Y
                SecFrame.BackgroundColor3 = Theme.Section
                
                local SecCorner = Instance.new("UICorner", SecFrame)
                local SecLayout = Instance.new("UIListLayout", SecFrame)
                SecLayout.Padding = UDim.new(0, 8)
                
                local SecPadding = Instance.new("UIPadding", SecFrame)
                SecPadding.PaddingTop = UDim.new(0, 10)
                SecPadding.PaddingBottom = UDim.new(0, 10)
                SecPadding.PaddingLeft = UDim.new(0, 10)
                SecPadding.PaddingRight = UDim.new(0, 10)

                local SecTitle = Instance.new("TextLabel", SecFrame)
                SecTitle.Text = secName:upper()
                SecTitle.Font = Enum.Font.GothamBold
                SecTitle.TextColor3 = Theme.Accent
                SecTitle.TextSize = 12
                SecTitle.BackgroundTransparency = 1
                SecTitle.Size = UDim2.new(1, 0, 0, 15)

                local Elements = {}

                -- Multi Dropdown
                function Elements:CreateMultiDropdown(text, list, callback)
                    local DropFrame = Instance.new("Frame", SecFrame)
                    DropFrame.Size = UDim2.new(1, 0, 0, 35)
                    DropFrame.BackgroundColor3 = Theme.Background
                    local Selected = {}

                    local DropTitle = Instance.new("TextLabel", DropFrame)
                    DropTitle.Text = text .. ": None"
                    DropTitle.Size = UDim2.new(1, 0, 1, 0)
                    DropTitle.BackgroundTransparency = 1
                    DropTitle.TextColor3 = Theme.Text

                    local DropBtn = Instance.new("TextButton", DropFrame)
                    DropBtn.Size = UDim2.new(1, 0, 1, 0)
                    DropBtn.BackgroundTransparency = 1
                    DropBtn.Text = ""

                    DropBtn.MouseButton1Click:Connect(function()
                        -- Logic สำหรับเปิดรายการ (Simplified)
                        -- ในเวอร์ชันเต็มคุณสามารถสร้าง Frame ซ้อนออกมาได้
                    end)
                end

                -- Mobile & PC Slider
                function Elements:CreateSlider(text, min, max, default, callback)
                    local SliderFrame = Instance.new("Frame", SecFrame)
                    SliderFrame.Size = UDim2.new(1, 0, 0, 45)
                    SliderFrame.BackgroundTransparency = 1

                    local Label = Instance.new("TextLabel", SliderFrame)
                    Label.Text = text .. " : " .. default
                    Label.Size = UDim2.new(1, 0, 0, 20)
                    Label.TextColor3 = Theme.Text
                    Label.BackgroundTransparency = 1

                    local Bar = Instance.new("Frame", SliderFrame)
                    Bar.Size = UDim2.new(1, 0, 0, 6)
                    Bar.Position = UDim2.new(0, 0, 0, 25)
                    Bar.BackgroundColor3 = Color3.fromRGB(50, 50, 50)

                    local Fill = Instance.new("Frame", Bar)
                    Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
                    Fill.BackgroundColor3 = Theme.Accent

                    local function UpdateSlider(input)
                        local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
                        local val = math.floor(min + (max - min) * pos)
                        Fill.Size = UDim2.new(pos, 0, 1, 0)
                        Label.Text = text .. " : " .. val
                        callback(val)
                    end

                    Bar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            UpdateSlider(input)
                            local moveCon
                            moveCon = UserInputService.InputChanged:Connect(function(move)
                                if move.UserInputType == Enum.UserInputType.MouseMovement or move.UserInputType == Enum.UserInputType.Touch then
                                    UpdateSlider(move)
                                end
                            end)
                            UserInputService.InputEnded:Connect(function(up)
                                if up.UserInputType == Enum.UserInputType.MouseButton1 or up.UserInputType == Enum.UserInputType.Touch then
                                    moveCon:Disconnect()
                                end
                            end)
                        end
                    end)
                end
                
                function Elements:CreateParagraph(content)
                    local Para = Instance.new("TextLabel", SecFrame)
                    Para.Size = UDim2.new(1, 0, 0, 0)
                    Para.AutomaticSize = Enum.AutomaticSize.Y
                    Para.Text = content
                    Para.TextColor3 = Theme.TextDark
                    Para.TextWrapped = true
                    Para.BackgroundTransparency = 1
                    Para.Font = Theme.Font
                    Para.TextSize = 13
                    Para.TextXAlignment = Enum.TextXAlignment.Left
                end

                return Elements
            end
            return SectionLib
        end
        return TabGroup
    end

    -- [[ Better Notifications ]]
    function ZENU_Lib:Notify(title, msg, duration)
        local Notif = Instance.new("Frame", ScreenGui)
        Notif.Size = UDim2.new(0, 250, 0, 70)
        Notif.Position = UDim2.new(1, 20, 1, -100)
        Notif.BackgroundColor3 = Theme.Section
        Instance.new("UICorner", Notif).CornerRadius = UDim.new(0, 8)
        
        local NTitle = Instance.new("TextLabel", Notif)
        NTitle.Text = "🔴 " .. title
        NTitle.Size = UDim2.new(1, -20, 0, 30)
        NTitle.TextColor3 = Theme.Accent
        NTitle.Position = UDim2.new(0, 10, 0, 5)
        NTitle.BackgroundTransparency = 1
        NTitle.Font = Enum.Font.GothamBold

        local NMsg = Instance.new("TextLabel", Notif)
        NMsg.Text = msg
        NMsg.Position = UDim2.new(0, 10, 0, 30)
        NMsg.Size = UDim2.new(1, -20, 0, 30)
        NMsg.TextColor3 = Theme.Text
        NMsg.BackgroundTransparency = 1
        NMsg.TextWrapped = true

        Notif:TweenPosition(UDim2.new(1, -270, 1, -100), "Out", "Back", 0.5)
        task.wait(duration or 3)
        Notif:TweenPosition(UDim2.new(1, 20, 1, -100), "In", "Linear", 0.5, true, function() Notif:Destroy() end)
    end

    return Window
end

return ZENU_Lib
