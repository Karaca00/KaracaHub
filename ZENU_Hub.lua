--!strict -- ZENU Hub UI Library Framework -- Theme: Dark + Red | Inspired by Fluent Design -- Drop this ModuleScript into ReplicatedStorage (or wherever you prefer) and require it from a LocalScript.

-- Example: -- local ZENU = require(path.To.ZENUHub) -- local Window = ZENU:CreateWindow({ --     Title = "ZENU Hub", --     Subtitle = "Advanced Scripting Hub", --     Footer = "discord.gg/zenuhub", -- })

-- local Home = Window:AddTab({ Name = "Home", Icon = "rbxassetid://6031091000" }) -- local Farming = Window:AddTab({ Name = "Farming", Icon = "rbxassetid://6031280882" })

-- local Card = Farming:AddCard({ Title = "Farming", Icon = "rbxassetid://6031071054" }) -- Card:AddToggle({ Label = "Auto Farm", Default = false, Callback = function(v) print(v) end }) -- Card:AddSlider({ Label = "HP", Min = 0, Max = 100, Default = 100, Suffix = "HP" }) -- Card:AddDropdown({ Label = "Select NPC", Items = {"Bandit","Boss","Guard"}, Callback = function(v) print(v) end })

-- Window:Notify({ Title = "Loaded", Text = "ZENU Hub ready", Duration = 3 })

local ZENU = {} ZENU.__index = ZENU

local TweenService = game:GetService("TweenService") local UserInputService = game:GetService("UserInputService") local RunService = game:GetService("RunService") local Players = game:GetService("Players") local LocalPlayer = Players.LocalPlayer local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local function safeCall(fn, ...) local ok, result = pcall(fn, ...) if not ok then warn("[ZENU Hub]", result) end return ok, result end

local function create(className: string, props: {[string]: any}?) local inst = Instance.new(className) if props then for k, v in pairs(props) do inst[k] = v end end return inst end

local function corner(parent: Instance, radius: number?) local c = create("UICorner", { CornerRadius = UDim.new(0, radius or 10), Parent = parent }) return c end

local function stroke(parent: Instance, transparency: number?, thickness: number?) local s = create("UIStroke", { Color = Color3.fromRGB(60, 0, 0), Transparency = transparency or 0.2, Thickness = thickness or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent, }) return s end

local function padding(parent: Instance, p: number?) return create("UIPadding", { PaddingLeft = UDim.new(0, p or 10), PaddingRight = UDim.new(0, p or 10), PaddingTop = UDim.new(0, p or 10), PaddingBottom = UDim.new(0, p or 10), Parent = parent, }) end

local function list(parent: Instance, fill: Enum.FillDirection?, pad: number?) return create("UIListLayout", { FillDirection = fill or Enum.FillDirection.Vertical, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, pad or 8), Parent = parent, }) end

local function tween(inst: Instance, t: number, goal: {[string]: any}, style: Enum.EasingStyle?, dir: Enum.EasingDirection?) local info = TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out) TweenService:Create(inst, info, goal):Play() end

local function makeIconButton(parent: Instance, image: string, size: number) local b = create("ImageButton", { BackgroundTransparency = 1, Image = image, ImageColor3 = Color3.fromRGB(180, 180, 180), Size = UDim2.fromOffset(size, size), AutoButtonColor = false, Parent = parent, }) return b end

local function makeText(parent: Instance, text: string, size: number, bold: boolean?, color: Color3?) local l = create("TextLabel", { BackgroundTransparency = 1, Text = text, TextColor3 = color or Color3.fromRGB(245, 245, 245), Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham, TextSize = size, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, AutomaticSize = Enum.AutomaticSize.None, Parent = parent, }) return l end

local DEFAULT_ICONS = { Home = "rbxassetid://6031071054", Settings = "rbxassetid://6031280882", Farming = "rbxassetid://6031075938", PVP = "rbxassetid://6031091000", Misc = "rbxassetid://6031071054", }

local function iconAsset(name: string?) if not name or name == "" then return DEFAULT_ICONS.Home end if string.find(name, "rbxassetid://") then return name end return DEFAULT_ICONS[name] or DEFAULT_ICONS.Home end

local function normalize(s: any) return string.lower(tostring(s or "")) end

local function setVisibleRecursive(root: Instance, visible: boolean) if root:IsA("GuiObject") then root.Visible = visible end for _, d in ipairs(root:GetDescendants()) do if d:IsA("GuiObject") then d.Visible = visible end end end

local Theme = { Bg = Color3.fromRGB(12, 12, 14), Panel = Color3.fromRGB(18, 18, 20), Panel2 = Color3.fromRGB(24, 24, 28), Panel3 = Color3.fromRGB(30, 30, 36), Stroke = Color3.fromRGB(70, 20, 20), Red = Color3.fromRGB(230, 30, 30), Red2 = Color3.fromRGB(170, 0, 0), Text = Color3.fromRGB(245, 245, 245), Muted = Color3.fromRGB(170, 170, 170), Subtle = Color3.fromRGB(120, 120, 120), Good = Color3.fromRGB(82, 196, 122), Warn = Color3.fromRGB(255, 184, 77), Bad = Color3.fromRGB(255, 90, 90), }

-- Window object local Window = {} Window.__index = Window

function ZENU:CreateWindow(config) config = config or {} local self = setmetatable({}, Window) self.Title = config.Title or "ZENU Hub" self.Subtitle = config.Subtitle or "Advanced Scripting Hub" self.Footer = config.Footer or "discord.gg/zenuhub" self.Keybind = config.Keybind or Enum.KeyCode.RightShift self.Categories = {} self.AllCards = {} self.AllSearchables = {} self.Destroyed = false self.Minimized = false self._connections = {} self._drag = nil self._resize = nil

local gui = create("ScreenGui", {
	Name = "ZENU_Hub",
	ResetOnSpawn = false,
	IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	Parent = PlayerGui,
})
self.Gui = gui

local root = create("Frame", {
	Name = "Root",
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5),
	Size = UDim2.fromOffset(980, 640),
	BackgroundColor3 = Theme.Bg,
	BorderSizePixel = 0,
	Parent = gui,
})
corner(root, 16)
stroke(root, 0.35, 1)
self.Root = root

local main = create("Frame", {
	Name = "Main",
	Size = UDim2.fromScale(1, 1),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Parent = root,
})
self.Main = main

local header = create("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 76),
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
	Parent = main,
})
corner(header, 16)
self.Header = header
local headerStroke = stroke(header, 0.7, 1)
headerStroke.Color = Color3.fromRGB(45, 45, 45)

local topBar = create("Frame", {
	Name = "TopBar",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(16, 12),
	Size = UDim2.new(1, -32, 0, 52),
	Parent = header,
})

local brandIcon = create("Frame", {
	Name = "Logo",
	Size = UDim2.fromOffset(52, 52),
	BackgroundColor3 = Color3.fromRGB(14, 14, 16),
	BorderSizePixel = 0,
	Parent = topBar,
})
corner(brandIcon, 14)
stroke(brandIcon, 0.65, 1)
local logoText = makeText(brandIcon, "Z", 28, true, Theme.Red)
logoText.Size = UDim2.fromScale(1, 1)
logoText.TextXAlignment = Enum.TextXAlignment.Center
logoText.TextYAlignment = Enum.TextYAlignment.Center

local titleWrap = create("Frame", {
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(66, 1),
	Size = UDim2.new(0, 340, 1, 0),
	Parent = topBar,
})
local titleLbl = makeText(titleWrap, self.Title, 24, true, Theme.Text)
titleLbl.Size = UDim2.new(1, 0, 0, 30)
local subtitleLbl = makeText(titleWrap, self.Subtitle, 13, false, Theme.Muted)
subtitleLbl.Position = UDim2.fromOffset(0, 28)
subtitleLbl.Size = UDim2.new(1, 0, 0, 18)

local searchWrap = create("Frame", {
	Name = "SearchWrap",
	BackgroundColor3 = Theme.Panel2,
	BorderSizePixel = 0,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, -116, 0, 6),
	Size = UDim2.fromOffset(250, 38),
	Parent = topBar,
})
corner(searchWrap, 12)
stroke(searchWrap, 0.8, 1)

local searchIcon = makeIconButton(searchWrap, "rbxassetid://6031154878", 16)
searchIcon.Position = UDim2.fromOffset(12, 11)
searchIcon.ImageColor3 = Theme.Subtle
local searchBox = create("TextBox", {
	Name = "SearchBox",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(38, 0),
	Size = UDim2.new(1, -48, 1, 0),
	ClearTextOnFocus = false,
	PlaceholderText = "Search functions...",
	Text = "",
	TextColor3 = Theme.Text,
	PlaceholderColor3 = Theme.Subtle,
	Font = Enum.Font.Gotham,
	TextSize = 14,
	TextXAlignment = Enum.TextXAlignment.Left,
	Parent = searchWrap,
})
self.SearchBox = searchBox

local controls = create("Frame", {
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(1, 0),
	Position = UDim2.new(1, 0, 0, 8),
	Size = UDim2.fromOffset(100, 34),
	Parent = topBar,
})
local controlLayout = list(controls, Enum.FillDirection.Horizontal, 8)
controlLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right

local minimizeBtn = create("TextButton", {
	Name = "Minimize",
	Text = "—",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Theme.Text,
	BackgroundColor3 = Theme.Panel2,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Size = UDim2.fromOffset(28, 28),
	Parent = controls,
})
corner(minimizeBtn, 10)

local expandBtn = create("TextButton", {
	Name = "Expand",
	Text = "+",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Theme.Text,
	BackgroundColor3 = Theme.Panel2,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Size = UDim2.fromOffset(28, 28),
	Visible = false,
	Parent = controls,
})
corner(expandBtn, 10)

local closeBtn = create("TextButton", {
	Name = "Close",
	Text = "X",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Theme.Text,
	BackgroundColor3 = Theme.Red2,
	BorderSizePixel = 0,
	AutoButtonColor = false,
	Size = UDim2.fromOffset(28, 28),
	Parent = controls,
})
corner(closeBtn, 10)

local body = create("Frame", {
	Name = "Body",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(0, 80),
	Size = UDim2.new(1, 0, 1, -120),
	Parent = main,
})

local sidebar = create("Frame", {
	Name = "Sidebar",
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(14, 0),
	Size = UDim2.new(0, 86, 1, -10),
	Parent = body,
})
corner(sidebar, 16)
stroke(sidebar, 0.75, 1)
self.Sidebar = sidebar

local sideScroll = create("ScrollingFrame", {
	Name = "SidebarScroll",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Position = UDim2.fromOffset(0, 0),
	Size = UDim2.new(1, 0, 1, 0),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarThickness = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = sidebar,
})
padding(sideScroll, 10)
local sideList = list(sideScroll, Enum.FillDirection.Vertical, 10)
self.SidebarScroll = sideScroll

local content = create("Frame", {
	Name = "Content",
	BackgroundTransparency = 1,
	Position = UDim2.fromOffset(112, 0),
	Size = UDim2.new(1, -126, 1, -10),
	Parent = body,
})
self.Content = content

local contentScroll = create("ScrollingFrame", {
	Name = "ContentScroll",
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 1, 0),
	CanvasSize = UDim2.new(0, 0, 0, 0),
	ScrollBarThickness = 6,
	ScrollBarImageColor3 = Theme.Red,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = content,
})
padding(contentScroll, 2)
local contentList = list(contentScroll, Enum.FillDirection.Vertical, 12)
self.ContentScroll = contentScroll

local footer = create("Frame", {
	Name = "Footer",
	BackgroundColor3 = Theme.Panel,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 14, 1, -34),
	Size = UDim2.new(1, -28, 0, 22),
	Parent = main,
})
corner(footer, 10)
stroke(footer, 0.8, 1)
local footerLbl = makeText(footer, self.Footer, 12, false, Theme.Muted)
footerLbl.Size = UDim2.new(1, -40, 1, 0)
footerLbl.Position = UDim2.fromOffset(12, 0)
local resizeHandle = create("ImageLabel", {
	Name = "ResizeHandle",
	BackgroundTransparency = 1,
	Image = "rbxassetid://7072718367",
	ImageColor3 = Theme.Subtle,
	AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -2, 1, -2),
	Size = UDim2.fromOffset(18, 18),
	Parent = root,
})
self.ResizeHandle = resizeHandle

local function updateSearch()
	local q = normalize(searchBox.Text)
	for _, item in ipairs(self.AllSearchables) do
		local match = q == "" or string.find(normalize(item.Keywords), q, 1, true) ~= nil
		if item.Instance and item.Instance.Parent then
			if item.Type == "Card" then
				item.Instance.Visible = match or item.AlwaysVisible
			else
				item.Instance.Visible = match
			end
		end
	end
end

searchBox:GetPropertyChangedSignal("Text"):Connect(updateSearch)

local function setMinimized(state: boolean)
	self.Minimized = state
	tween(root, 0.22, { Size = state and UDim2.fromOffset(980, 84) or UDim2.fromOffset(980, 640) })
	content.Visible = not state
	footer.Visible = not state
	sidebar.Visible = not state
	expandBtn.Visible = state
	minimizeBtn.Visible = not state
end

minimizeBtn.MouseButton1Click:Connect(function()
	setMinimized(true)
end)
expandBtn.MouseButton1Click:Connect(function()
	setMinimized(false)
end)
closeBtn.MouseButton1Click:Connect(function()
	gui:Destroy()
	self.Destroyed = true
end)

local function makeDraggable(handle: GuiObject, dragTarget: GuiObject)
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = dragTarget.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			self._drag = input
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and input == self._drag and dragStart and startPos then
			local delta = input.Position - dragStart
			dragTarget.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
end

makeDraggable(header, root)

local resizing = false
local resizeStartPos, resizeStartSize
resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = true
		resizeStartPos = input.Position
		resizeStartSize = root.Size
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		resizing = false
	end
end)
RunService.RenderStepped:Connect(function()
	if resizing and resizeStartPos and resizeStartSize then
		local mouse = UserInputService:GetMouseLocation()
		local dx = mouse.X - resizeStartPos.X
		local dy = mouse.Y - resizeStartPos.Y
		local newX = math.clamp(resizeStartSize.X.Offset + dx, 780, 1400)
		local newY = math.clamp(resizeStartSize.Y.Offset + dy, 500, 900)
		root.Size = UDim2.fromOffset(newX, newY)
	end
end)

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == self.Keybind then
		root.Visible = not root.Visible
	end
end)

-- Public API helpers
function self:Notify(opts)
	opts = opts or {}
	local title = tostring(opts.Title or "Notification")
	local text = tostring(opts.Text or "")
	local duration = tonumber(opts.Duration or 3) or 3

	local notify = create("Frame", {
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 360, 0, 18),
		Size = UDim2.fromOffset(320, 74),
		Parent = gui,
	})
	corner(notify, 14)
	stroke(notify, 0.65, 1)
	local t1 = makeText(notify, title, 16, true, Theme.Text)
	t1.Position = UDim2.fromOffset(14, 10)
	t1.Size = UDim2.new(1, -28, 0, 18)
	local t2 = makeText(notify, text, 13, false, Theme.Muted)
	t2.Position = UDim2.fromOffset(14, 30)
	t2.Size = UDim2.new(1, -28, 0, 28)
	local bar = create("Frame", {
		BackgroundColor3 = Theme.Red2,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 1, -3),
		Size = UDim2.new(1, 0, 0, 3),
		Parent = notify,
	})
	tween(notify, 0.25, { Position = UDim2.new(1, -18, 0, 18) })
	task.spawn(function()
		local start = os.clock()
		while notify.Parent and os.clock() - start < duration do
			local alpha = 1 - ((os.clock() - start) / duration)
			bar.Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 0, 3)
			RunService.Heartbeat:Wait()
		end
		if notify.Parent then
			tween(notify, 0.22, { Position = UDim2.new(1, 360, 0, 18) })
			task.wait(0.24)
			notify:Destroy()
		end
	end)
end

function self:Destroy()
	if self.Gui then
		self.Gui:Destroy()
	end
	self.Destroyed = true
end

function self:AddTab(tabConfig)
	tabConfig = tabConfig or {}
	local tab = setmetatable({}, { __index = self })
	tab.Window = self
	tab.Name = tabConfig.Name or "Tab"
	tab.Icon = iconAsset(tabConfig.Icon)
	tab.Cards = {}
	tab.Keywords = tabConfig.Keywords or tab.Name
	tab.Active = false

	local btn = create("TextButton", {
		Name = tab.Name .. "Tab",
		Text = "",
		BackgroundColor3 = Theme.Panel2,
		BorderSizePixel = 0,
		AutoButtonColor = false,
		Size = UDim2.fromOffset(62, 62),
		Parent = sideScroll,
	})
	corner(btn, 16)
	stroke(btn, 0.82, 1)
	local icon = create("ImageLabel", {
		BackgroundTransparency = 1,
		Image = tab.Icon,
		ImageColor3 = Theme.Muted,
		Size = UDim2.fromOffset(24, 24),
		Position = UDim2.fromOffset(19, 13),
		Parent = btn,
	})
	local label = makeText(btn, tab.Name, 11, true, Theme.Muted)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.Size = UDim2.new(1, -8, 0, 16)
	label.Position = UDim2.fromOffset(4, 36)
	label.RichText = true

	local contentHolder = create("Frame", {
		Name = tab.Name .. "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = false,
		Parent = contentScroll,
	})
	local contentList2 = list(contentHolder, Enum.FillDirection.Vertical, 12)
	padding(contentHolder, 2)
	tab.Container = contentHolder
	tab.Button = btn

	local function activate()
		for _, c in ipairs(self.Categories) do
			c.Container.Visible = false
			c.Button.BackgroundColor3 = Theme.Panel2
			local img = c.Button:FindFirstChildOfClass("ImageLabel")
			local txt = c.Button:FindFirstChildOfClass("TextLabel")
			if img then img.ImageColor3 = Theme.Muted end
			if txt then txt.TextColor3 = Theme.Muted end
		end
		contentHolder.Visible = true
		btn.BackgroundColor3 = Theme.Red2
		icon.ImageColor3 = Color3.new(1,1,1)
		label.TextColor3 = Color3.new(1,1,1)
	end

	btn.MouseEnter:Connect(function()
		if not tab.Active then tween(btn, 0.14, { BackgroundColor3 = Color3.fromRGB(34, 34, 40) }) end
	end)
	btn.MouseLeave:Connect(function()
		if not tab.Active then tween(btn, 0.14, { BackgroundColor3 = Theme.Panel2 }) end
	end)
	btn.MouseButton1Click:Connect(function()
		tab.Active = true
		activate()
		for _, c in ipairs(self.Categories) do c.Active = false end
	end)

	table.insert(self.Categories, tab)
	table.insert(self.AllSearchables, { Type = "Tab", Instance = btn, Keywords = tab.Name .. " " .. tab.Keywords })

	if #self.Categories == 1 then
		tab.Active = true
		activate()
	end

	function tab:AddCard(cardConfig)
		cardConfig = cardConfig or {}
		local card = {}
		card.Window = self.Window
		card.Tab = tab
		card.Title = cardConfig.Title or "Card"
		card.Icon = iconAsset(cardConfig.Icon)
		card.Keywords = cardConfig.Keywords or card.Title
		card.Collapsed = false
		card.Controls = {}

		local cardFrame = create("Frame", {
			Name = card.Title .. "Card",
			BackgroundColor3 = Theme.Panel2,
			BorderSizePixel = 0,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = contentHolder,
		})
		corner(cardFrame, 16)
		stroke(cardFrame, 0.72, 1)
		local headerRow = create("TextButton", {
			BackgroundTransparency = 1,
			Text = "",
			Size = UDim2.new(1, 0, 0, 44),
			Parent = cardFrame,
		})
		local cardIcon = create("ImageLabel", {
			BackgroundTransparency = 1,
			Image = card.Icon,
			ImageColor3 = Theme.Red,
			Size = UDim2.fromOffset(18, 18),
			Position = UDim2.fromOffset(14, 13),
			Parent = headerRow,
		})
		local title = makeText(headerRow, card.Title, 15, true, Theme.Text)
		title.Position = UDim2.fromOffset(40, 11)
		title.Size = UDim2.new(1, -80, 0, 20)
		local chevron = makeText(headerRow, "˅", 18, true, Theme.Muted)
		chevron.TextXAlignment = Enum.TextXAlignment.Right
		chevron.Position = UDim2.new(1, -28, 0, 10)
		chevron.Size = UDim2.fromOffset(16, 20)

		local bodyFrame = create("Frame", {
			Name = "Body",
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 0),
			Parent = cardFrame,
		})
		local bodyLayout = list(bodyFrame, Enum.FillDirection.Vertical, 10)
		padding(bodyFrame, 12)
		bodyFrame.Position = UDim2.fromOffset(0, 44)
		card.Body = bodyFrame
		card.Header = headerRow
		card.Frame = cardFrame

		local function applyCollapse()
			bodyFrame.Visible = not card.Collapsed
			chevron.Text = card.Collapsed and ">" or "˅"
		end
		applyCollapse()

		headerRow.MouseEnter:Connect(function()
			tween(cardFrame, 0.12, { BackgroundColor3 = Theme.Panel3 })
		end)
		headerRow.MouseLeave:Connect(function()
			tween(cardFrame, 0.12, { BackgroundColor3 = Theme.Panel2 })
		end)
		headerRow.MouseButton1Click:Connect(function()
			card.Collapsed = not card.Collapsed
			applyCollapse()
		end)

		function card:_addRow(containerHeight)
			local row = create("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, containerHeight or 40),
				Parent = bodyFrame,
			})
			return row
		end

		function card:AddLabel(opts)
			opts = opts or {}
			local row = self:_addRow(opts.Height or 28)
			local lbl = makeText(row, opts.Text or "Label", opts.TextSize or 13, opts.Bold ~= false, opts.Color or Theme.Text)
			lbl.Size = UDim2.new(1, 0, 1, 0)
			lbl.RichText = true
			lbl.TextWrapped = true
			return lbl
		end

		function card:AddButton(opts)
			opts = opts or {}
			local row = self:_addRow(40)
			local btn = create("TextButton", {
				Text = opts.Text or "Button",
				Font = Enum.Font.GothamSemibold,
				TextSize = 14,
				TextColor3 = Theme.Text,
				BackgroundColor3 = Theme.Red2,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = row,
			})
			corner(btn, 12)
			btn.MouseButton1Click:Connect(function()
				safeCall(opts.Callback or function() end)
			end)
			btn.MouseEnter:Connect(function() tween(btn, 0.12, { BackgroundColor3 = Theme.Red }) end)
			btn.MouseLeave:Connect(function() tween(btn, 0.12, { BackgroundColor3 = Theme.Red2 }) end)
			return btn
		end

		function card:AddToggle(opts)
			opts = opts or {}
			local state = opts.Default == true
			local row = self:_addRow(42)
			local label = makeText(row, opts.Label or "Toggle", 14, false, Theme.Text)
			label.Size = UDim2.new(1, -70, 1, 0)
			local switch = create("TextButton", {
				Text = "",
				BackgroundColor3 = state and Theme.Red2 or Theme.Panel3,
				BorderSizePixel = 0,
				AutoButtonColor = false,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, 0, 0.5, 0),
				Size = UDim2.fromOffset(52, 24),
				Parent = row,
			})
			corner(switch, 999)
			local knob = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(245,245,245),
				BorderSizePixel = 0,
				Position = state and UDim2.fromOffset(30, 3) or UDim2.fromOffset(3, 3),
				Size = UDim2.fromOffset(18, 18),
				Parent = switch,
			})
			corner(knob, 999)
			local function set(v)
				state = v
				tween(switch, 0.15, { BackgroundColor3 = state and Theme.Red2 or Theme.Panel3 })
				tween(knob, 0.15, { Position = state and UDim2.fromOffset(30, 3) or UDim2.fromOffset(3, 3) })
				safeCall(opts.Callback or function() end, state)
			end
			switch.MouseButton1Click:Connect(function() set(not state) end)
			return { Set = set, Get = function() return state end }
		end

		function card:AddTextbox(opts)
			opts = opts or {}
			local row = self:_addRow(52)
			local label = makeText(row, opts.Label or "Textbox", 13, false, Theme.Text)
			label.Size = UDim2.new(1, 0, 0, 16)
			local box = create("TextBox", {
				BackgroundColor3 = Theme.Panel3,
				BorderSizePixel = 0,
				PlaceholderText = opts.Placeholder or "Type here...",
				Text = opts.Default or "",
				TextColor3 = Theme.Text,
				PlaceholderColor3 = Theme.Subtle,
				Font = Enum.Font.Gotham,
				TextSize = 14,
				ClearTextOnFocus = false,
				Position = UDim2.fromOffset(0, 22),
				Size = UDim2.new(1, 0, 0, 30),
				Parent = row,
			})
			corner(box, 10)
			padding(box, 10)
			box.FocusLost:Connect(function(enter)
				if enter then
					safeCall(opts.Callback or function() end, box.Text)
				end
			end)
			return box
		end

		function card:AddSlider(opts)
			opts = opts or {}
			local min = tonumber(opts.Min or 0) or 0
			local max = tonumber(opts.Max or 100) or 100
			local value = tonumber(opts.Default or min) or min
			local suffix = tostring(opts.Suffix or "")
			local row = self:_addRow(58)
			local label = makeText(row, opts.Label or "Slider", 13, false, Theme.Text)
			label.Size = UDim2.new(1, -60, 0, 16)
			local valueLbl = makeText(row, tostring(value) .. suffix, 13, true, Theme.Red)
			valueLbl.TextXAlignment = Enum.TextXAlignment.Right
			valueLbl.AnchorPoint = Vector2.new(1, 0)
			valueLbl.Position = UDim2.new(1, 0, 0, 0)
			valueLbl.Size = UDim2.fromOffset(56, 16)
			local track = create("Frame", {
				BackgroundColor3 = Theme.Panel3,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 26),
				Size = UDim2.new(1, 0, 0, 12),
				Parent = row,
			})
			corner(track, 999)
			local fill = create("Frame", {
				BackgroundColor3 = Theme.Red2,
				BorderSizePixel = 0,
				Size = UDim2.new(0, 0, 1, 0),
				Parent = track,
			})
			corner(fill, 999)
			local knob = create("Frame", {
				BackgroundColor3 = Color3.fromRGB(245,245,245),
				BorderSizePixel = 0,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				Parent = track,
			})
			corner(knob, 999)
			local dragging = false
			local function setValue(v)
				value = math.clamp(math.floor(v + 0.5), min, max)
				local alpha = (value - min) / math.max((max - min), 1)
				fill.Size = UDim2.new(alpha, 0, 1, 0)
				knob.Position = UDim2.new(alpha, 0, 0.5, 0)
				valueLbl.Text = tostring(value) .. suffix
				safeCall(opts.Callback or function() end, value)
			end
			local function updateFromX(x)
				local alpha = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
				setValue(min + ((max - min) * alpha))
			end
			track.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					updateFromX(input.Position.X)
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					updateFromX(input.Position.X)
				end
			end)
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			setValue(value)
			return { Set = setValue, Get = function() return value end }
		end

		local function dropdownCore(opts, multi: boolean)
			opts = opts or {}
			local row = self:_addRow(multi and 180 or 150)
			local label = makeText(row, opts.Label or (multi and "Multi Dropdown" or "Dropdown"), 13, false, Theme.Text)
			label.Size = UDim2.new(1, 0, 0, 16)
			local holder = create("Frame", {
				BackgroundColor3 = Theme.Panel3,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(0, 22),
				Size = UDim2.new(1, 0, 0, multi and 148 or 120),
				Parent = row,
			})
			corner(holder, 12)
			stroke(holder, 0.84, 1)
			local selectedLabel = makeText(holder, opts.Placeholder or "Select...", 13, false, Theme.Muted)
			selectedLabel.Position = UDim2.fromOffset(12, 8)
			selectedLabel.Size = UDim2.new(1, -44, 0, 16)
			local dropBtn = create("TextButton", {
				Text = "˅",
				Font = Enum.Font.GothamBold,
				TextSize = 18,
				TextColor3 = Theme.Muted,
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 4),
				Size = UDim2.fromOffset(22, 20),
				Parent = holder,
			})

			local search = create("TextBox", {
				BackgroundColor3 = Theme.Panel2,
				BorderSizePixel = 0,
				PlaceholderText = "Search...",
				Text = "",
				TextColor3 = Theme.Text,
				PlaceholderColor3 = Theme.Subtle,
				Font = Enum.Font.Gotham,
				TextSize = 13,
				ClearTextOnFocus = false,
				Position = UDim2.fromOffset(12, 32),
				Size = UDim2.new(1, -24, 0, 28),
				Parent = holder,
			})
			corner(search, 10)
			padding(search, 8)

			local listHolder = create("ScrollingFrame", {
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Position = UDim2.fromOffset(12, 66),
				Size = UDim2.new(1, -24, 1, -78),
				ScrollBarThickness = 4,
				CanvasSize = UDim2.new(0,0,0,0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				Parent = holder,
			})
			local ll = list(listHolder, Enum.FillDirection.Vertical, 6)
			local open = false
			local selected = multi and {} or nil
			local items = opts.Items or {}

			local function refreshLabel()
				if multi then
					local arr = selected
					local text = (#arr == 0) and (opts.Placeholder or "Select...") or table.concat(arr, ", ")
					selectedLabel.Text = text
					selectedLabel.TextColor3 = (#arr == 0) and Theme.Muted or Theme.Text
				else
					selectedLabel.Text = selected or (opts.Placeholder or "Select...")
					selectedLabel.TextColor3 = selected and Theme.Text or Theme.Muted
				end
			end

			local function rebuild()
				for _, child in ipairs(listHolder:GetChildren()) do
					if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end
				end
				local q = normalize(search.Text)
				for _, item in ipairs(items) do
					local text = tostring(item)
					if q == "" or string.find(normalize(text), q, 1, true) then
						local opt = create("TextButton", {
							Text = "",
							BackgroundColor3 = Theme.Panel2,
							BorderSizePixel = 0,
							AutoButtonColor = false,
							Size = UDim2.new(1, 0, 0, 28),
							Parent = listHolder,
						})
						corner(opt, 8)
						local optLbl = makeText(opt, text, 13, false, Theme.Text)
						optLbl.Position = UDim2.fromOffset(10, 0)
						optLbl.Size = UDim2.new(1, -20, 1, 0)
						opt.MouseEnter:Connect(function() tween(opt, 0.1, { BackgroundColor3 = Theme.Red2 }) end)
						opt.MouseLeave:Connect(function() tween(opt, 0.1, { BackgroundColor3 = Theme.Panel2 }) end)
						opt.MouseButton1Click:Connect(function()
							if multi then
								local idx = table.find(selected, text)
								if idx then table.remove(selected, idx) else table.insert(selected, text) end
								safeCall(opts.Callback or function() end, selected)
							else
								selected = text
								safeCall(opts.Callback or function() end, selected)
							end
							refreshLabel()
							rebuild()
						end)
					end
				end
			end

			local function toggleOpen()
				open = not open
				listHolder.Visible = open
				search.Visible = open
				dropBtn.Text = open and "˄" or "˅"
				if open then rebuild() end
			end
			listHolder.Visible = false
			search.Visible = false
			dropBtn.MouseButton1Click:Connect(toggleOpen)
			search:GetPropertyChangedSignal("Text"):Connect(function() if open then rebuild() end end)
			refreshLabel()
			table.insert(self.Window.AllSearchables, { Type = "Component", Instance = holder, Keywords = (opts.Label or "") .. " " .. table.concat(items, " ") })
			return {
				Get = function() return selected end,
				Set = function(v)
					selected = v
					refreshLabel()
				end,
			}
		end

		function card:AddDropdown(opts)
			return dropdownCore(opts, false)
		end

		function card:AddMultiDropdown(opts)
			local ret = dropdownCore(opts, true)
			if ret and type(ret.Get) == "function" then
				-- no-op, kept for API compatibility
			end
			return ret
		end

		function card:AddGroup(opts)
			opts = opts or {}
			local row = self:_addRow(opts.Height or 42)
			local container = create("Frame", {
				BackgroundColor3 = Theme.Panel3,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
				Parent = row,
			})
			corner(container, 12)
			stroke(container, 0.86, 1)
			local layout = list(container, Enum.FillDirection.Horizontal, 8)
			layout.HorizontalAlignment = Enum.HorizontalAlignment.Left
			padding(container, 8)
			return {
				Frame = container,
				AddIconTab = function(_, iconName, callback)
					local iconBtn = create("TextButton", {
						Text = "",
						BackgroundColor3 = Theme.Panel2,
						BorderSizePixel = 0,
						AutoButtonColor = false,
						Size = UDim2.fromOffset(34, 34),
						Parent = container,
					})
					corner(iconBtn, 10)
					local im = create("ImageLabel", {
						BackgroundTransparency = 1,
						Image = iconAsset(iconName),
						ImageColor3 = Theme.Muted,
						Size = UDim2.fromOffset(18, 18),
						Position = UDim2.fromOffset(8, 8),
						Parent = iconBtn,
					})
					iconBtn.MouseEnter:Connect(function() tween(iconBtn, 0.12, { BackgroundColor3 = Theme.Red2 }) im.ImageColor3 = Color3.new(1,1,1) end)
					iconBtn.MouseLeave:Connect(function() tween(iconBtn, 0.12, { BackgroundColor3 = Theme.Panel2 }) im.ImageColor3 = Theme.Muted end)
					iconBtn.MouseButton1Click:Connect(function() safeCall(callback or function() end) end)
					return iconBtn
				end,
			}
		end

		table.insert(self.Window.AllSearchables, { Type = "Card", Instance = cardFrame, Keywords = card.Title .. " " .. card.Keywords, AlwaysVisible = true })
		table.insert(self.Cards, card)
		return card
	end

	return tab
end

function self:AddSection(opts)
	return self:AddTab(opts)
end

setmetatable(self, Window)
return self

end

return ZENU