if HUB_LOADED and not _G.HUB_DEBUG == true then
	warn("Infinity Hub is already running!")
	return
end

pcall(function() getgenv().HUB_LOADED = true end)

if not game:IsLoaded() then

	NotLoaded = Instance.new("Message")
	NotLoaded.Text = "Infinity Hub is waiting for the game to load"

	local s, e = pcall(function()
		NotLoaded.Parent = game:GetService("CoreGui")
	end)

	if not s then
		NotLoaded.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end

	game.Loaded:Wait()

	NotLoaded:Destroy()
end

local TweenService = game:GetService("TweenService")
local MPS = game:GetService("MarketplaceService")

local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

_G.InfinityHub_Data = {
	UIRaimbowEffect = false,

	PlayerChams = false,
	PlayerESP = false,

	PlayerTracerESP = false,
	PlayerBoxESP = false,
	
	PresetColor = Color3.fromRGB(0, 255, 0),
	CloseBind = Enum.KeyCode.LeftControl,
	Position = nil,
	
	ShowNotifications = true,
}

function RestoreUI()

	if _G.InfinityHub_Data.PlayerESP then
		_G.InfinityHub_Data.PlayerESP = false
		
		for i, v in pairs(CoreGui:GetChildren()) do
			if string.sub(v.Name, -4) == '_ESP' then
				v:Destroy()
			end
		end
	end
	
	if _G.InfinityHub_Data.PlayerChams then
		_G.InfinityHub_Data.PlayerChams = false

		for i,v in pairs(game.Players:GetChildren()) do
			for i, c in pairs(CoreGui:GetChildren()) do
				if c.Name == v.Name..'_CHMS' then
					c:Destroy()
				end
			end
		end
	end
	
	if _G.InfinityHub_Data.PlayerTracerESP then
		_G.InfinityHub_Data.PlayerTracerESP = false
	end
	if _G.InfinityHub_Data.PlayerBoxESP then
		_G.InfinityHub_Data.PlayerBoxESP = false
	end
	
	if _G.InfinityHub_Data.UIRaimbowEffect then
		_G.InfinityHub_Data.UIRaimbowEffect = false
	end
	if _G.InfinityHub_Data.ShowNotifications then
		_G.InfinityHub_Data.ShowNotifications = false
	end
end


local HubColorValue = {RainbowColorValue = 0, HueSelectionPosition = 0}

local HueSelectionPosition
local RainbowColorValue

local SelectedTab = nil
local PARENT = nil

coroutine.wrap(
	function()
		while wait() do
			HubColorValue.RainbowColorValue = HubColorValue.RainbowColorValue + 1 / 255
			HubColorValue.HueSelectionPosition = HubColorValue.HueSelectionPosition + 1

			if HubColorValue.RainbowColorValue >= 1 then
				HubColorValue.RainbowColorValue = 0
			end

			if HubColorValue.HueSelectionPosition == 120 then
				HubColorValue.HueSelectionPosition = 0
			end
			HueSelectionPosition = HubColorValue.HueSelectionPosition
			RainbowColorValue = HubColorValue.RainbowColorValue
		end
	end
)()

function randomString()
	local length = math.random(10,20)
	local array = {}

	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end

	return table.concat(array)
end

function MakeDraggable(MainFrame)
	local DragTonggle = nil
	local DragStart = nil
	local startPos = nil

	local function UpdateInput(input)

		local Delta = input.Position - DragStart

		local Pos = UDim2.new(

			startPos.X.Scale, 

			startPos.X.Offset + Delta.X,

			startPos.Y.Scale, startPos.Y.Offset + Delta.Y

		)

		TweenService:Create(MainFrame, TweenInfo.new(0.25), {Position = Pos}):Play()
	end

	MainFrame.InputBegan:Connect(function(input)
		if (input.UserInputType == Enum.UserInputType.MouseButton1) then 
			DragTonggle = true

			DragStart = input.Position
			startPos = MainFrame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					DragTonggle = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement then
			if DragTonggle then
				UpdateInput(input)
			end
		end
	end)
end

if not RS:IsStudio() then
	function Load_UI_Settings()
		if (readfile and isfile) then

			if isfile("InfinityHub\\InfinityHubData.json") then
				_G.InfinityHub_Data = HttpService:JSONDecode(readfile("InfinityHub\\InfinityHubData.json"))

				warn("InfinityHub Data loaded")
			end

			warn("Settings loaded")
		end
	end

	function Save_UI_Settings()
		if (writefile) and (makefolder) then

			local Infinity_Hub_Data_json = HttpService:JSONEncode(_G.InfinityHub_Data)

			makefolder("InfinityHub")


			makefolder("InfinityHub\\Core")
			writefile("InfinityHub\\Core\\Token.tkn",game:GetService("HttpService"):GenerateGUID(true))


			makefolder("InfinityHub\\Logs")
			makefolder("InfinityHub\\Modules")


			makefolder("InfinityHub\\Data")

			writefile("InfinityHub\\InfinityHubData.json",Infinity_Hub_Data_json)

			warn("Settings saved")
		end
	end
	
	Load_UI_Settings()
end

local library = {}

function library:CreateWindow(Hub_Name, MainColor, CloseBind)

	local UI = Instance.new("ScreenGui")

	local MainFrame = Instance.new("ImageLabel")
	local Tabs = Instance.new("ImageLabel")
	local TopBar = Instance.new("ImageLabel")

	local TabsContainer = Instance.new("ScrollingFrame")
	local UIListLayout = Instance.new("UIListLayout")

	local LockMouseButton = Instance.new("TextButton")
	local Title = Instance.new("TextLabel")
	local TabsFolder = Instance.new("Folder")
	local StorageFrame = Instance.new("Frame")
	
	local PlayerInfoFrame = Instance.new("Frame")
	local UICorner = Instance.new("UICorner")
	
	local PlayerImage = Instance.new("ImageLabel")
	local UICorner2 = Instance.new("UICorner")
	
	local PlayerName = Instance.new("TextLabel")
	local DisplayName = Instance.new("TextLabel")

	_G.InfinityHub_Data.PresetColor = MainColor or Color3.fromRGB(0, 255, 0)
	_G.InfinityHub_Data.CloseBind = CloseBind or Enum.KeyCode.LeftControl

	PARENT = UI

	if not RS:IsStudio() then
		pcall(function()
			if (not is_sirhurt_closure) and (syn and syn.protect_gui) then
				syn.protect_gui(UI)
				UI.Parent = CoreGui

			elseif get_hidden_gui or gethui then
				local hiddenUI = get_hidden_gui or gethui
				UI.Parent = hiddenUI()

			elseif CoreGui:FindFirstChild("RobloxGui") then
				UI = CoreGui.RobloxGui
			else
				UI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
			end
		end)
	else
		UI.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
	end

	UI.Name = randomString()

	MainFrame.Name = "Main"
	MainFrame.Parent = UI
	MainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	MainFrame.BackgroundTransparency = 1.000
	MainFrame.Position = _G.InfinityHub_Data.Position or UDim2.new(0.5, 0, 0.5, 0)
	MainFrame.Size = UDim2.new(0, 0, 0, 0)
	MainFrame.Image = "rbxassetid://4641149554"
	MainFrame.ImageColor3 = Color3.fromRGB(24, 24, 24)
	MainFrame.ScaleType = Enum.ScaleType.Slice
	MainFrame.SliceCenter = Rect.new(4, 4, 296, 296)

	Tabs.Name = "Tabs"
	Tabs.Parent = MainFrame
	Tabs.Visible = false
	Tabs.BackgroundTransparency = 1.000
	Tabs.ClipsDescendants = true
	Tabs.Position = UDim2.new(0, 0, 0, 38)
	Tabs.Size = UDim2.new(-0.0299999993, 126, 1, -38)
	Tabs.ZIndex = 3
	Tabs.Image = "rbxassetid://5012534273"
	Tabs.ImageColor3 = Color3.fromRGB(14, 14, 14)
	Tabs.ScaleType = Enum.ScaleType.Slice
	Tabs.SliceCenter = Rect.new(4, 4, 296, 296)

	TabsContainer.Name = "TabsContainer"
	TabsContainer.Parent = Tabs
	TabsContainer.Active = true
	TabsContainer.BackgroundTransparency = 1.000
	TabsContainer.Position = UDim2.new(0, 0, 0, 10)
	TabsContainer.Size = UDim2.new(1, 0, 0.832, -20)
	TabsContainer.CanvasSize = UDim2.new(0, 0, 0, 314)
	TabsContainer.ScrollBarThickness = 0

	UIListLayout.Parent = TabsContainer
	UIListLayout.Padding = UDim.new(0, 10)
	
	
	for i, v in pairs(TabsContainer:GetChildren()) do
		if UIListLayout.AbsoluteContentSize.Y > 325 then
			
			local TabsContainerScroll = Instance.new("ScrollingFrame")
			TabsContainerScroll.ZIndex = 3
			
			TabsContainerScroll.BackgroundTransparency = 1
			TabsContainerScroll.BorderSizePixel = 0
			
			TabsContainerScroll.Position = UDim2.new(0, 0, 0, 10)
			TabsContainerScroll.Size = UDim2.new(1, 0, 0.832, -20)
			
			TabsContainerScroll.ScrollBarImageColor3 = Color3.fromRGB(255, 255, 255)
			TabsContainerScroll.ScrollBarThickness = 2
			
			v:Clone().Parent =  TabsContainerScroll	
			TabsContainer = TabsContainerScroll
			
			pcall(function() TabsContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 35) end)
		end
	end
	
	TabsContainer.ChildAdded:Connect(function()
		pcall(function() TabsContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 35) end)
	end)

	TabsContainer.ChildRemoved:Connect(function()
		pcall(function() TabsContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 35) end)
	end)
	TabsContainer.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 20)

	TopBar.Name = "TopBar"
	TopBar.Parent = MainFrame
	TopBar.BackgroundTransparency = 1.000
	TopBar.ClipsDescendants = true
	TopBar.Size = UDim2.new(1, 0, 0, 38)
	TopBar.ZIndex = 5
	TopBar.Image = "rbxassetid://4595286933"
	TopBar.ImageColor3 = Color3.fromRGB(10, 10, 10)
	TopBar.ScaleType = Enum.ScaleType.Slice
	TopBar.SliceCenter = Rect.new(4, 4, 296, 296)

	Title.Name = "Title"
	Title.Parent = TopBar
	Title.AnchorPoint = Vector2.new(0, 0.5)
	Title.BackgroundTransparency = 1.000
	Title.Position = UDim2.new(0, 20, 0, 19)
	Title.Size = UDim2.new(1, -46, 0, 16)
	Title.ZIndex = 6
	Title.Font = Enum.Font.GothamBold
	Title.Text = tostring(Hub_Name)
	Title.TextColor3 = Color3.fromRGB(230, 230, 230)
	Title.TextSize = 14.000
	Title.TextXAlignment = Enum.TextXAlignment.Left

	TabsFolder.Name = "TabsFolder"
	TabsFolder.Parent = MainFrame
	
	StorageFrame.Size = UDim2.new(0,0,0,0)
	StorageFrame.Name = "StorageFrame"
	StorageFrame.Visible = false
	StorageFrame.Parent = MainFrame

	LockMouseButton.Name = "LockMouseButton"

	LockMouseButton.Size = UDim2.new(0,0,0,0)
	LockMouseButton.Text = ""

	LockMouseButton.Parent = PARENT
	
	PlayerInfoFrame.Name = "PlayerInfoFrame"
	PlayerInfoFrame.Parent = Tabs
	PlayerInfoFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
	PlayerInfoFrame.BorderSizePixel = 0
	PlayerInfoFrame.Position = UDim2.new(0, 0, 0.852409661, 0)
	PlayerInfoFrame.Size = UDim2.new(0, 111, 0, 48)
	PlayerInfoFrame.ZIndex = 3
	
	UICorner.CornerRadius = UDim.new(0, 6)
	UICorner.Parent = PlayerInfoFrame

	PlayerImage.Name = "PlayerImage"
	PlayerImage.Parent = PlayerInfoFrame
	PlayerImage.BackgroundTransparency = 1
	PlayerImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	PlayerImage.Position = UDim2.new(0.045, 0, 0.2, 0)
	PlayerImage.Size = UDim2.new(0, 32, 0, 32)
	PlayerImage.ZIndex = 3
	
	local ThumbnailType = Enum.ThumbnailType.HeadShot
	local ThumbnailSize = Enum.ThumbnailSize.Size420x420
	local content = game.Players:GetUserThumbnailAsync(game.Players.LocalPlayer.UserId, ThumbnailType, ThumbnailSize)
	
	PlayerImage.Image = content

	UICorner2.CornerRadius = UDim.new(0, 100)
	UICorner2.Parent = PlayerImage

	PlayerName.Name = "PlayerName"
	PlayerName.Parent = PlayerInfoFrame
	PlayerName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	PlayerName.BackgroundTransparency = 1.000
	PlayerName.Position = UDim2.new(0.38, 0, 0.263636261, 0)
	PlayerName.Size = UDim2.new(0, 63, 0, 17)
	PlayerName.ZIndex = 3
	PlayerName.Font = Enum.Font.SourceSans
	PlayerName.Text = "@"..tostring(game.Players.LocalPlayer.Name)
	PlayerName.TextColor3 = Color3.fromRGB(255, 255, 255)
	PlayerName.TextScaled = true
	PlayerName.TextSize = 12.000
	PlayerName.TextWrapped = true
	PlayerName.TextXAlignment = Enum.TextXAlignment.Left

	DisplayName.Name = "DisplayName"
	DisplayName.Parent = PlayerInfoFrame
	DisplayName.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	DisplayName.BackgroundTransparency = 1.000
	DisplayName.Position = UDim2.new(0.38, 0, 0.49090901, 0)
	DisplayName.Size = UDim2.new(0, 45, 0, 17)
	DisplayName.ZIndex = 3
	DisplayName.Font = Enum.Font.SourceSans
	DisplayName.Text = tostring(game.Players.LocalPlayer.DisplayName)
	DisplayName.TextColor3 = Color3.fromRGB(255, 255, 255)
	DisplayName.TextScaled = true
	DisplayName.TextSize = 12.000
	DisplayName.TextTransparency = 0.650
	DisplayName.TextWrapped = true
	DisplayName.TextXAlignment = Enum.TextXAlignment.Left

	MakeDraggable(MainFrame)
	MainFrame:TweenSize(UDim2.new(0, 500, 0, 370), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 1.2, true)
	
	task.wait(0.6)
	
	Tabs.Visible = true
	
	local uitoggled = false
	UserInputService.InputBegan:Connect(
		function(io, p)
			if io.KeyCode == _G.InfinityHub_Data.CloseBind then
				if uitoggled == false then
					MainFrame:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
					Tabs.Visible = false
					
					for i, v in pairs(TabsFolder:GetChildren()) do
						if v:IsA("ScrollingFrame") then
							v.Visible = false
						end
					end
					
					uitoggled = true
					wait(.5)
					UI.Enabled = false
				else
					MainFrame:TweenSize(UDim2.new(0, 500, 0, 370), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
					Tabs.Visible = true
					
					for i, v in pairs(TabsFolder:GetChildren()) do
						if v:IsA("ScrollingFrame") then
							if SelectedTab ~= nil then
								if v.Name == tostring(SelectedTab) then
									v.Visible = true
								end
							else
								if v.Name == "HomeFrame" then 
									v.Visible = true
								end
							end
						end
					end
					
					UI.Enabled = true
					wait(.5)
					uitoggled = false
				end
			end
		end
	)

	function library:LockMouse(Value)
		LockMouseButton.Modal = Value
	end

	function library:SaveUISettings()
		pcall(function() _G.InfinityHub_Data.Position = MainFrame.Position end)
		task.wait()
		pcall(function() Save_UI_Settings() end)
	end

	function library:DestroyUI()
		pcall(function() _G.InfinityHub_Data.Position = MainFrame.Position end)
		task.wait()
		pcall(function() getgenv().HUB_LOADED = false end)
		
		pcall(function() Save_UI_Settings() end)
		task.wait()
		pcall(function() RestoreUI() end)
		
		PARENT:Destroy()
	end
	
	function library:GetStorage()
		return StorageFrame
	end
	
	function library:CoreNotification(Title, Msg, Duration, BtnTxt, callback)
		if _G.InfinityHub_Data.ShowNotifications == false then
			return
		end
		
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = Title or Hub_Name.." | NOTIFICATION";
			Text = Msg or tostring(nil);

			Button1 = BtnTxt or "OK";
			Duration = Duration or 10;
			
			callback = callback or function() end
		})
	end
	
	function library:Notify(title, Msg, NotifyType, callback)

		if self.DestroyNotification then
			self.DestroyNotification = self.DestroyNotification()
		end

		local MainFrameNotify = Instance.new("ImageLabel")
		
		MainFrameNotify.Name = "Notification"
		MainFrameNotify.Parent = UI
		MainFrameNotify.BackgroundTransparency = 1
		MainFrameNotify.Size = UDim2.new(0, 200, 0, 60)
		MainFrameNotify.Image = "rbxassetid://5028857472"
		MainFrameNotify.ImageColor3 = Color3.fromRGB(24, 24, 24)
		MainFrameNotify.ScaleType = Enum.ScaleType.Slice
		MainFrameNotify.SliceCenter = Rect.new(4, 4, 296, 296)
		MainFrameNotify.ZIndex = 3
		MainFrameNotify.ClipsDescendants = true
			
		local Flash = Instance.new("ImageLabel")
		
		Flash.Name = "Flash"
		Flash.Size = UDim2.new(1, 0, 1, 0)
		Flash.BackgroundTransparency = 1
		Flash.Parent = MainFrameNotify
		Flash.Image = "rbxassetid://4641149554"
		Flash.ImageColor3 = Color3.fromRGB(255, 255, 255)
		Flash.ZIndex = 5
		
		local Glow = Instance.new("ImageLabel")
		
		Glow.Name = "Glow"
		Glow.BackgroundTransparency = 1
		Glow.Position = UDim2.new(0, -15, 0, -15)
		Glow.Size = UDim2.new(1, 30, 1, 30)
		Glow.ZIndex = 2
		Glow.Parent = MainFrameNotify
		Glow.Image = "rbxassetid://5028857084"
		Glow.ImageColor3 = _G.InfinityHub_Data.PresetColor
		Glow.ScaleType = Enum.ScaleType.Slice
		Glow.SliceCenter = Rect.new(24, 24, 276, 276)
		
		local Title = Instance.new("TextLabel")
		
		Title.Name = "Title"
		Title.BackgroundTransparency = 1
		Title.Position = UDim2.new(0, 10, 0, 8)
		Title.Size = UDim2.new(1, -40, 0, 16)
		Title.ZIndex = 4
		Title.Parent = MainFrameNotify
		Title.Font = Enum.Font.GothamSemibold
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.TextSize = 14.000
		Title.TextXAlignment = Enum.TextXAlignment.Left
		
		local Text = Instance.new("TextLabel")
		
		Text.Name = "Text"
		Text.BackgroundTransparency = 1
		Text.Position = UDim2.new(0, 10, 1, -24)
		Text.Size = UDim2.new(1, -40, 0, 16)
		Text.ZIndex = 4
		Text.Parent = MainFrameNotify
		Text.Font = Enum.Font.Gotham
		Text.TextColor3 = Color3.fromRGB(255, 255, 255)
		Text.TextSize = 12.000
		Text.TextXAlignment = Enum.TextXAlignment.Left
		
		local Accept = Instance.new("ImageButton")
		
		Accept.Name = "Accept"
		Accept.Parent = MainFrameNotify
		Accept.BackgroundTransparency = 1
		Accept.Position = UDim2.new(1, -26, 0, 8)
		Accept.Size = UDim2.new(0, 16, 0, 16)
		Accept.Image = "rbxassetid://5012538259"
		Accept.ImageColor3 = Color3.fromRGB(255, 255, 255)
		Accept.ZIndex = 4
		
		local Decline = Instance.new("ImageButton")
		
		Decline.Name = "Decline"
		Decline.Parent = MainFrameNotify
		Decline.BackgroundTransparency = 1
		Decline.Position = UDim2.new(1, -26, 1, -24)
		Decline.Size = UDim2.new(0, 16, 0, 16)
		Decline.Image = "rbxassetid://5012538583"
		Decline.ImageColor3 = Color3.fromRGB(255, 255, 255)
		Decline.ZIndex = 4

		MakeDraggable(MainFrameNotify)	
		
		callback = callback or function() end
		
		NotifyType = NotifyType or "Normal"
		title = title or Hub_Name.." | NOTIFICATION"
		Msg = Msg or ""

		Title.Text = title
		Text.Text = Msg
		
		local Value = false
		
		local padding = 10
		local TextService = game:GetService("TextService"):GetTextSize(Msg, 12, Enum.Font.Gotham, Vector2.new(math.huge, 16))
		
		MainFrameNotify.Position = library.lastNotification or UDim2.new(0, padding, 1, -(MainFrameNotify.AbsoluteSize.Y + padding))
		MainFrameNotify.Size = UDim2.new(0, 0, 0, 60)
		
		TweenService:Create(MainFrameNotify, TweenInfo.new(0.2), {Size = UDim2.new(0, TextService.X + 80, 0, 60)}):Play()
		wait(0.2)

		MainFrameNotify.ClipsDescendants = false
		TweenService:Create(Flash, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 60), Position = UDim2.new(1, 0, 0, 0)}):Play()

		local active = true
		local function DestroyNotify()

			if not active then
				return
			end

			active = false
			MainFrameNotify.ClipsDescendants = true

			library.lastNotification = MainFrameNotify.Position
			
			Flash.Position = UDim2.new(0, 0, 0, 0)
			TweenService:Create(Flash, TweenInfo.new(0.2), {Size = UDim2.new(1, 0, 1, 0)}):Play()

			wait(0.2)
			TweenService:Create(MainFrameNotify, TweenInfo.new(0.2), {Size = UDim2.new(0, 0, 0, 60), Position = MainFrameNotify.Position + UDim2.new(0, TextService.X + 70, 0, 0)}):Play()
			
			wait(0.2)
			MainFrameNotify:Destroy()
		end
		
		self.DestroyNotification = DestroyNotify
		
		if NotifyType == "Normal" then
			Decline.Visible = false
			Accept.Visible = false
			
			wait(5)
			
			self.DestroyNotification()
		end
		
		Accept.MouseButton1Click:Connect(function()

			if not active then 
				return
			end

			Value = true
			pcall(callback, Value)

			DestroyNotify()
		end)

		Decline.MouseButton1Click:Connect(function()

			if not active then 
				return
			end

			Value = false
			pcall(callback, Value)

			DestroyNotify()
		end)
	end

	local Tabs = {}

	function Tabs:CreatePage(TabName, AssetId, Priority)

		local TabFrame = Instance.new("ScrollingFrame")
		local UIListLayout = Instance.new("UIListLayout")

		local function UpdateSize()
			local cS = UIListLayout.AbsoluteContentSize

			TabFrame.CanvasSize = UDim2.new(0, 0, 0, cS.Y + 30)
		end

		TabFrame.Name = TabName.."Frame"
		TabFrame.Parent = TabsFolder
		TabFrame.Active = true
		TabFrame.BackgroundTransparency = 1.000
		TabFrame.BorderSizePixel = 0
		TabFrame.Position = UDim2.new(0, 116, 0, 46)
		TabFrame.Size = UDim2.new(1.03600001, -142, 1, -56)
		TabFrame.CanvasSize = UDim2.new(0, 0, 0, 452)
		TabFrame.ScrollBarThickness = 3

		UIListLayout.Parent = TabFrame
		UIListLayout.SortOrder = Enum.SortOrder.Name
		UIListLayout.Padding = UDim.new(0, 10)

		local TabBtn = Instance.new("TextButton")
		local Title = Instance.new("TextLabel")
		local Icon = Instance.new("ImageLabel")

		TabBtn.Name = tostring(Priority).."_"..TabName.."_TabBtn"		
		TabBtn.Parent = TabsContainer
		TabBtn.BackgroundTransparency = 1.000
		TabBtn.BorderSizePixel = 0
		TabBtn.Size = UDim2.new(1, 0, 0, 26)
		TabBtn.ZIndex = 3
		TabBtn.AutoButtonColor = false
		TabBtn.Font = Enum.Font.Gotham
		TabBtn.Text = ""
		TabBtn.TextSize = 14.000

		Title.Name = "Title"
		Title.Parent = TabBtn
		Title.AnchorPoint = Vector2.new(0, 0.5)
		Title.BackgroundTransparency = 1.000
		Title.Position = UDim2.new(0, 40, 0.5, 0)
		Title.Size = UDim2.new(0, 76, 1, 0)
		Title.ZIndex = 3
		Title.Font = Enum.Font.Gotham
		Title.Text = TabName
		Title.TextColor3 = Color3.fromRGB(255, 255, 255)
		Title.TextSize = 12
		Title.TextTransparency = 0.650
		Title.TextXAlignment = Enum.TextXAlignment.Left
		
		for i = 1, #TabName do
			if i > 10 then
				Title.TextSize = 10
			end
		end

		Icon.Name = "Icon"
		Icon.Parent = TabBtn
		Icon.AnchorPoint = Vector2.new(0, 0.5)
		Icon.BackgroundTransparency = 1.000
		Icon.Position = UDim2.new(0, 12, 0.5, 0)
		Icon.Size = UDim2.new(0, 16, 0, 16)
		Icon.ZIndex = 3
		Icon.Image = "rbxassetid://"..tostring(AssetId)
		Icon.ImageTransparency = 0.65
		Icon.ScaleType = Enum.ScaleType.Fit

		for i,v in pairs(TabsFolder:GetChildren()) do
			if v:IsA("ScrollingFrame") and v.Name == "HomeFrame" then
				v.Visible = true
			else
				v.Visible = false
			end
		end

		for i ,v in pairs(TabsContainer:GetDescendants()) do
			if v.Parent:FindFirstChild("Title") and v.Parent:FindFirstChild("Icon") then
				if string.find(v.Parent.Name, "1") then

					TweenService:Create(
						v.Parent.Title,
						TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{TextTransparency = 0}
					):Play()

					TweenService:Create(
						v.Parent.Icon,
						TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ImageTransparency = 0}
					):Play()

				else

					TweenService:Create(
						v.Parent.Title,
						TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{TextTransparency = 0.65}
					):Play()

					TweenService:Create(
						v.Parent.Icon,
						TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
						{ImageTransparency = 0.65}
					):Play()
				end
			end	
		end

		local Debounce = false

		TabBtn.MouseButton1Click:Connect(function()
			if Debounce == false then
				Debounce = true

				for i ,v in next, TabsFolder:GetChildren() do
					v.Visible = false
				end

				for i ,v in pairs(TabsContainer:GetDescendants()) do
					if v.Parent:FindFirstChild("Title") then
						TweenService:Create(
							v.Parent.Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.65}
						):Play()

						TweenService:Create(
							v.Parent.Icon,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageTransparency = 0.65}
						):Play()
					end		
				end

				task.wait(0.36)

				TweenService:Create(
					TabBtn.Title,
					TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{TextTransparency = 0}
				):Play()

				TweenService:Create(
					TabBtn.Icon,
					TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
					{ImageTransparency = 0}
				):Play()
				
				SelectedTab = TabFrame
				TabFrame.Visible = true

				wait(2)
				Debounce = false
			end
		end)

		TabBtn.MouseEnter:Connect(function()
			TweenService:Create(
				TabBtn.Icon,
				TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{--[[Rotation = -12,]] Size = UDim2.new(0, 18, 0, 18)}
			):Play()

			TweenService:Create(
				TabBtn,
				TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextSize = 15}
			):Play()
		end)

		TabBtn.MouseLeave:Connect(function()
			TweenService:Create(
				TabBtn.Icon,
				TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{--[[Rotation = 0,]] Size = UDim2.new(0, 16, 0, 16)}
			):Play()

			TweenService:Create(
				TabBtn,
				TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
				{TextSize = 12}
			):Play()
		end)

		UpdateSize()
		
		TabFrame.ChildAdded:Connect(UpdateSize)
		TabFrame.ChildRemoved:Connect(UpdateSize)

		local Sections = {}

		function Sections:CreateSection(SecName)

			SecName = SecName or "Section"
			local modules = {}

			local SectionFrame = Instance.new("ImageLabel")
			local Container = Instance.new("Frame")

			local ContainerLayout = Instance.new("UIListLayout")
			local Title = Instance.new("TextLabel")

			SectionFrame.Parent = TabFrame
			SectionFrame.Name = "SectionFrame"

			SectionFrame.BackgroundTransparency = 1.000
			SectionFrame.ClipsDescendants = true
			SectionFrame.Size = UDim2.new(1, -10, 0, 328)
			SectionFrame.ZIndex = 2
			SectionFrame.Image = "rbxassetid://5028857472"
			SectionFrame.ImageColor3 = Color3.fromRGB(20, 20, 20)
			SectionFrame.ScaleType = Enum.ScaleType.Slice
			SectionFrame.SliceCenter = Rect.new(4, 4, 296, 296)

			Container.Name = "Container"
			Container.Parent = SectionFrame
			Container.Active = true
			Container.BackgroundTransparency = 1.000
			Container.BorderSizePixel = 0
			Container.Position = UDim2.new(0, 8, 0, 8)
			Container.Size = UDim2.new(1, -16, 1, -16)

			ContainerLayout.Parent = Container
			ContainerLayout.SortOrder = Enum.SortOrder.LayoutOrder
			ContainerLayout.Padding = UDim.new(0, 4)

			Title.Name = "0_Title"
			Title.Parent = Container
			Title.BackgroundTransparency = 1.000
			Title.Size = UDim2.new(1, 0, 0, 20)
			Title.ZIndex = 2
			Title.Font = Enum.Font.GothamSemibold
			Title.Text = SecName
			Title.TextColor3 = Color3.fromRGB(255, 255, 255)
			Title.TextSize = 12.000
			Title.TextXAlignment = Enum.TextXAlignment.Left

			SectionFrame.Size = UDim2.new(1, -10, 0, ContainerLayout.AbsoluteContentSize.X + 30)

			local function UpdateSectionFrame()

				local UIListLayoutSize = ContainerLayout.AbsoluteContentSize
				SectionFrame.Size = UDim2.new(1, -10, 0, UIListLayoutSize.Y + 30)
				Container.Size = UDim2.new(1, -16, 1, UIListLayoutSize.Y)
			end

			UpdateSize()
			UpdateSectionFrame()

			Container.ChildAdded:Connect(UpdateSectionFrame)
			Container.ChildRemoved:Connect(UpdateSectionFrame)

			local Elements = {}
			
			function Elements:CreateScriptInfoButton(PlaceId, Status)
				local s, info = pcall(MPS.GetProductInfo,MPS,tonumber(PlaceId))
				
				local GameInfoBtn = Instance.new("TextButton")
				local UICorner = Instance.new("UICorner")

				local GameImage = Instance.new("ImageLabel")

				local GameImageCorner = Instance.new("UICorner")
				local GameTitleText = Instance.new("TextLabel")

				local StatusFrame = Instance.new("Frame")

				local UICorner_2 = Instance.new("UICorner")
				local StatusText = Instance.new("TextLabel")

				local StatusCircle = Instance.new("Frame")
				local StatusCircleCorner = Instance.new("UICorner")

				GameInfoBtn.Name = "GameInfoBtn"
				GameInfoBtn.Parent = Container
				GameInfoBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				GameInfoBtn.Size = UDim2.new(1, 0, 0, 48)
				GameInfoBtn.ZIndex = 2
				GameInfoBtn.Font = Enum.Font.SourceSans
				GameInfoBtn.Text = ""
				GameInfoBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
				GameInfoBtn.TextSize = 14.000

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = GameInfoBtn

				GameImage.Name = "GameImage"
				GameImage.Parent = GameInfoBtn
				GameImage.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				GameImage.Position = UDim2.new(0.0250000004, 0, 0.100000001, 0)
				GameImage.Size = UDim2.new(0, 38, 0, 38)
				GameImage.ZIndex = 2
				GameImage.Image = "rbxassetid://"..tonumber(info.IconImageAssetId)

				GameImageCorner.Name = "GameImageCorner"
				GameImageCorner.Parent = GameImage

				GameTitleText.Name = "GameTitleText"
				GameTitleText.Parent = GameInfoBtn
				GameTitleText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				GameTitleText.BackgroundTransparency = 1.000
				GameTitleText.Position = UDim2.new(0.150000006, 0, 0.280000001, 0)
				GameTitleText.Size = UDim2.new(0, 120, 0, 20)
				GameTitleText.ZIndex = 2
				GameTitleText.Font = Enum.Font.Gotham
				GameTitleText.Text = tostring(info.Name)
				GameTitleText.TextColor3 = Color3.fromRGB(255, 255, 255)
				GameTitleText.TextScaled = true
				GameTitleText.TextSize = 12.000
				GameTitleText.TextWrapped = true

				StatusFrame.Name = "StatusFrame"
				StatusFrame.Parent = GameInfoBtn
				StatusFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
				StatusFrame.Position = UDim2.new(0.75, 0, 0.280000001, 0)
				StatusFrame.Size = UDim2.new(0, 78, 0, 18)
				StatusFrame.Visible = true
				StatusFrame.ZIndex = 3

				UICorner_2.Parent = StatusFrame

				StatusText.Name = "StatusText"
				StatusText.Parent = StatusFrame
				StatusText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				StatusText.BackgroundTransparency = 1.000
				StatusText.Position = UDim2.new(0.200000003, 0, 0, 0)
				StatusText.Size = UDim2.new(0, 35, 0, 18)
				StatusText.ZIndex = 3
				StatusText.Font = Enum.Font.Gotham
				StatusText.Text = "Status:"
				StatusText.TextColor3 = Color3.fromRGB(255, 255, 255)
				StatusText.TextSize = 15.000

				StatusCircle.Name = "StatusCircle"
				StatusCircle.Parent = StatusFrame
				StatusCircle.BackgroundColor3 = Color3.fromRGB(85, 255, 0)
				StatusCircle.Position = UDim2.new(0.779999971, 0, 0.180000007, 0)
				StatusCircle.Size = UDim2.new(0, 12, 0, 12)
				StatusCircle.ZIndex = 3

				StatusCircleCorner.CornerRadius = UDim.new(0, 100)
				StatusCircleCorner.Name = "StatusCircleCorner"
				StatusCircleCorner.Parent = StatusCircle

				GameInfoBtn.MouseButton1Click:Connect(function()
					if Status == "Ok" then
						library:Notify("NOTIFICATION", "You will be teleported to: "..tostring(info.Name).."\nAre you sure of this?", "fuction", function(arg)
							if arg then
								game:GetService("TeleportService"):Teleport(PlaceId)
							end
						end)

					elseif Status == "Warning" then
						library:Notify("NOTIFICATION", "Be careful, you will be teleported to a game that has just been updated\nAre you sure of this?", "fuction", function(arg)
							if arg then
								game:GetService("TeleportService"):Teleport(PlaceId)
							end
						end)

					elseif Status == "Broken" then
						library:Notify("NOTIFICATION", "Warning this game is recently updated the Scripts are Broken/Patched\nAre you sure of this?", "fuction", function(arg)
							if arg then
								game:GetService("TeleportService"):Teleport(PlaceId)
							end
						end)

					elseif Status == "Offline" then
						library:Notify("NOTIFICATION", "Script Offline due Server/API Issues or Maintenance", "Normal")
					end
				end)
				
				UpdateSize()
				UpdateSectionFrame()
			end
			
			function Elements:Colorpicker(ActionText, Present , callback)

				local ColorPicker = Instance.new("ImageLabel")
				local Title = Instance.new("TextLabel")

				local ColorPickerContainer = Instance.new("Frame")

				local Canvas = Instance.new("ImageButton")		
				local DarknessGradient = Instance.new("UIGradient")

				local Cursor = Instance.new("TextButton")
				local Color = Instance.new("ImageButton")

				local Slider = Instance.new("TextButton")

				local ColourGradient = Instance.new("UIGradient")

				local Inputs = Instance.new("Frame")
				local UIListLayout = Instance.new("UIListLayout")

				local Text = Instance.new("TextLabel")
				local TextColorValue_R = Instance.new("TextLabel")

				local Text_2 = Instance.new("TextLabel")
				local TextColorValue_G = Instance.new("TextLabel")

				local Text_3 = Instance.new("TextLabel")

				local TextColorValue_B = Instance.new("TextLabel")
				local UIListLayout_2 = Instance.new("UIListLayout")

				local Confirm = Instance.new("TextButton")
				local UICorner = Instance.new("UICorner")
				local Close = Instance.new("ImageButton")

				local R = Instance.new("ImageLabel")
				local G = Instance.new("ImageLabel")
				local B = Instance.new("ImageLabel")

				local ColorpickerBtn = Instance.new("TextButton")
				local UICorner = Instance.new("UICorner")
				local BoxColor = Instance.new("Frame")

				local UICorner_2 = Instance.new("UICorner")
				local Circle = Instance.new("Frame")

				local UICorner_3 = Instance.new("UICorner")
				local CircleSmall = Instance.new("Frame")

				local UICorner_4 = Instance.new("UICorner")
				local Title_2 = Instance.new("TextLabel")

				local OldToggleColor

				ColorPicker.Name = "ColorPicker"
				ColorPicker.Parent = PARENT
				ColorPicker.AnchorPoint = Vector2.new(0.5, 0.5)
				ColorPicker.BackgroundTransparency = 1.000
				ColorPicker.Position = UDim2.new(0.779999971, 0, 0.5, 0)
				ColorPicker.Selectable = true
				ColorPicker.Visible = false
				ColorPicker.Image = "rbxassetid://5028857472"
				ColorPicker.ImageColor3 = Color3.fromRGB(24, 24, 24)
				ColorPicker.ScaleType = Enum.ScaleType.Slice
				ColorPicker.SliceCenter = Rect.new(2, 2, 298, 298)
				
				Title.Name = "Title"
				Title.Parent = ColorPicker
				Title.BackgroundTransparency = 1.000
				Title.Position = UDim2.new(0, 10, 0, 8)
				Title.Size = UDim2.new(1, -40, 0, 16)
				Title.ZIndex = 2
				Title.Font = Enum.Font.GothamSemibold
				Title.Text = "Color Picker"
				Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextSize = 14.000
				Title.TextXAlignment = Enum.TextXAlignment.Left

				ColorPickerContainer.Name = "Container"
				ColorPickerContainer.Parent = ColorPicker
				ColorPickerContainer.BackgroundTransparency = 1.000
				ColorPickerContainer.ClipsDescendants = true
				ColorPickerContainer.Position = UDim2.new(0, 8, 0, 32)
				ColorPickerContainer.Size = UDim2.new(1, -18, 1, -40)

				Canvas.Name = "Canvas"
				Canvas.Parent = ColorPickerContainer
				Canvas.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Canvas.BackgroundTransparency = 1.000
				Canvas.BorderColor3 = Color3.fromRGB(20, 20, 20)
				Canvas.Size = UDim2.new(1, 0, -0.173574522, 60)
				Canvas.AutoButtonColor = false
				Canvas.ZIndex = 2
				Canvas.Image = "rbxassetid://5108535320"
				Canvas.ScaleType = Enum.ScaleType.Slice
				Canvas.SliceCenter = Rect.new(2, 2, 298, 298)

				DarknessGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 0, 0))}
				DarknessGradient.Name = "DarknessGradient"
				DarknessGradient.Parent = Canvas

				Cursor.Name = "Cursor"
				Cursor.Parent = Canvas
				Cursor.Active = false
				Cursor.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Cursor.Selectable = false
				Cursor.Size = UDim2.new(0, 2, 1, 0)
				Cursor.ZIndex = 2
				Cursor.Text = ""

				Color.Name = "Color"
				Color.Parent = ColorPickerContainer
				Color.BackgroundTransparency = 1.000
				Color.BorderSizePixel = 0
				Color.Position = UDim2.new(0, 0, 0, 43)
				Color.Selectable = false
				Color.Size = UDim2.new(1, 0, 0.162790701, 16)
				Color.ZIndex = 2
				Color.AutoButtonColor = false
				Color.Image = "rbxassetid://5028857472"
				Color.ScaleType = Enum.ScaleType.Slice
				Color.SliceCenter = Rect.new(2, 2, 298, 298)

				Slider.Name = "Slider"
				Slider.Parent = Color
				Slider.Active = false
				Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Slider.Position = UDim2.new(0, 58, 0, 0)
				Slider.Selectable = false
				Slider.Size = UDim2.new(0, 2, 1, 0)
				Slider.ZIndex = 2
				Slider.Text = ""

				ColourGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 4)), ColorSequenceKeypoint.new(0.20, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(0.40, Color3.fromRGB(0, 255, 0)), ColorSequenceKeypoint.new(0.60, Color3.fromRGB(0, 255, 255)), ColorSequenceKeypoint.new(0.80, Color3.fromRGB(0, 0, 255)), ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 255))}
				ColourGradient.Name = "ColourGradient"
				ColourGradient.Parent = Color

				Inputs.Name = "Inputs"
				Inputs.Parent = ColorPickerContainer
				Inputs.BackgroundTransparency = 1.000
				Inputs.Position = UDim2.new(0, 10, 0, 158)
				Inputs.Size = UDim2.new(1, 0, 0, 16)

				UIListLayout.Parent = Inputs
				UIListLayout.FillDirection = Enum.FillDirection.Horizontal
				UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
				UIListLayout.Padding = UDim.new(0, 6)

				R.Name = "R"
				R.Parent = Inputs
				R.BackgroundTransparency = 1.000
				R.BorderSizePixel = 0
				R.Size = UDim2.new(0.305000007, 0, 1, 0)
				R.ZIndex = 2
				R.Image = "rbxassetid://5028857472"
				R.ImageColor3 = Color3.fromRGB(14, 14, 14)
				R.ScaleType = Enum.ScaleType.Slice
				R.SliceCenter = Rect.new(2, 2, 298, 298)

				Text.Name = "R_Text"
				Text.Parent = R
				Text.BackgroundTransparency = 1.000
				Text.Size = UDim2.new(0.400000006, 0, 1, 0)
				Text.ZIndex = 2
				Text.Font = Enum.Font.Gotham
				Text.Text = "R:"
				Text.TextColor3 = Color3.fromRGB(255, 255, 255)
				Text.TextSize = 10.000

				TextColorValue_R.Name = "TextColorValue"
				TextColorValue_R.Parent = R
				TextColorValue_R.Active = true
				TextColorValue_R.BackgroundTransparency = 1.000
				TextColorValue_R.Position = UDim2.new(0.300000012, 0, 0, 0)
				TextColorValue_R.Selectable = true
				TextColorValue_R.Size = UDim2.new(0.600000024, 0, 1, 0)
				TextColorValue_R.ZIndex = 2
				TextColorValue_R.Font = Enum.Font.Gotham
				TextColorValue_R.Text = "0"
				TextColorValue_R.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextColorValue_R.TextSize = 10.000

				G.Name = "G"
				G.Parent = Inputs
				G.BackgroundTransparency = 1.000
				G.BorderSizePixel = 0
				G.Size = UDim2.new(0.305000007, 0, 1, 0)
				G.ZIndex = 2
				G.Image = "rbxassetid://5028857472"
				G.ImageColor3 = Color3.fromRGB(14, 14, 14)
				G.ScaleType = Enum.ScaleType.Slice
				G.SliceCenter = Rect.new(2, 2, 298, 298)

				Text_2.Name = "G_Text"
				Text_2.Parent = G
				Text_2.BackgroundTransparency = 1.000
				Text_2.Size = UDim2.new(0.400000006, 0, 1, 0)
				Text_2.ZIndex = 2
				Text_2.Font = Enum.Font.Gotham
				Text_2.Text = "G:"
				Text_2.TextColor3 = Color3.fromRGB(255, 255, 255)
				Text_2.TextSize = 10.000

				TextColorValue_G.Name = "TextColorValue"
				TextColorValue_G.Parent = G
				TextColorValue_G.Active = true
				TextColorValue_G.BackgroundTransparency = 1.000
				TextColorValue_G.Position = UDim2.new(0.300000012, 0, 0, 0)
				TextColorValue_G.Selectable = true
				TextColorValue_G.Size = UDim2.new(0.600000024, 0, 1, 0)
				TextColorValue_G.ZIndex = 2
				TextColorValue_G.Font = Enum.Font.Gotham
				TextColorValue_G.Text = "255"
				TextColorValue_G.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextColorValue_G.TextSize = 10.000

				B.Name = "B"
				B.Parent = Inputs
				B.BackgroundTransparency = 1.000
				B.BorderSizePixel = 0
				B.Size = UDim2.new(0.305000007, 0, 1, 0)
				B.ZIndex = 2
				B.Image = "rbxassetid://5028857472"
				B.ImageColor3 = Color3.fromRGB(14, 14, 14)
				B.ScaleType = Enum.ScaleType.Slice
				B.SliceCenter = Rect.new(2, 2, 298, 298)

				Text_3.Name = "B_Text"
				Text_3.Parent = B
				Text_3.BackgroundTransparency = 1.000
				Text_3.Size = UDim2.new(0.400000006, 0, 1, 0)
				Text_3.ZIndex = 2
				Text_3.Font = Enum.Font.Gotham
				Text_3.Text = "B:"
				Text_3.TextColor3 = Color3.fromRGB(255, 255, 255)
				Text_3.TextSize = 10.000

				TextColorValue_B.Name = "TextColorValue"
				TextColorValue_B.Parent = B
				TextColorValue_B.Active = true
				TextColorValue_B.BackgroundTransparency = 1.000
				TextColorValue_B.Position = UDim2.new(0.300000012, 0, 0, 0)
				TextColorValue_B.Selectable = true
				TextColorValue_B.Size = UDim2.new(0.600000024, 0, 1, 0)
				TextColorValue_B.ZIndex = 2
				TextColorValue_B.Font = Enum.Font.Gotham
				TextColorValue_B.Text = "0"
				TextColorValue_B.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextColorValue_B.TextSize = 10.000

				UIListLayout_2.Parent = ColorPickerContainer
				UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
				UIListLayout_2.Padding = UDim.new(0, 6)

				Confirm.Name = "Confirm"
				Confirm.Parent = ColorPickerContainer
				Confirm.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				Confirm.BorderSizePixel = 0
				Confirm.Size = UDim2.new(1, 0, 0, 20)
				Confirm.ZIndex = 2
				Confirm.Font = Enum.Font.Gotham
				Confirm.Text = "Confirm"
				Confirm.TextColor3 = Color3.fromRGB(255, 255, 255)
				Confirm.TextSize = 12.000
				Confirm.TextTransparency = 0.100

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Confirm

				Close.Name = "Close"
				Close.Parent = ColorPicker
				Close.Active = false
				Close.BackgroundTransparency = 1.000
				Close.Position = UDim2.new(1, -26, 0, 8)
				Close.Selectable = false
				Close.Size = UDim2.new(0, 16, 0, 16)
				Close.ZIndex = 3
				Close.Image = "rbxassetid://7072725342"

				ColorpickerBtn.Name = "Colorpicker"
				ColorpickerBtn.Parent = Container
				ColorpickerBtn.Active = false
				ColorpickerBtn.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				ColorpickerBtn.ClipsDescendants = true
				ColorpickerBtn.Selectable = false
				ColorpickerBtn.Size = UDim2.new(1, 0, 0, 30)
				ColorpickerBtn.ZIndex = 2
				ColorpickerBtn.Text = ""

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = ColorpickerBtn

				BoxColor.Name = "BoxColor"
				BoxColor.Parent = ColorpickerBtn
				BoxColor.BackgroundColor3 = Present
				BoxColor.Position = UDim2.new(0.884857178, 0, 0.166333348, 0)
				BoxColor.Size = UDim2.new(0, 35, 0, 20)
				BoxColor.ZIndex = 3

				UICorner_2.CornerRadius = UDim.new(0, 5)
				UICorner_2.Parent = BoxColor

				Circle.Name = "Circle"
				Circle.Parent = ColorpickerBtn
				Circle.Active = true
				Circle.AnchorPoint = Vector2.new(0.5, 0.5)
				Circle.BackgroundColor3 = Color3.fromRGB(211, 211, 211)
				Circle.Position = UDim2.new(0.0448571444, 0, 0.499666661, 0)
				Circle.Size = UDim2.new(0, 12, 0, 12)
				Circle.ZIndex = 3

				UICorner_3.CornerRadius = UDim.new(2, 6)
				UICorner_3.Parent = Circle

				CircleSmall.Name = "CircleSmall"
				CircleSmall.Parent = Circle
				CircleSmall.Active = true
				CircleSmall.AnchorPoint = Vector2.new(0.5, 0.5)
				CircleSmall.BackgroundColor3 = Color3.fromRGB(64, 68, 75)
				CircleSmall.BackgroundTransparency = 1.000
				CircleSmall.Position = UDim2.new(0.5, 0, 0.5, 0)
				CircleSmall.Size = UDim2.new(0, 9, 0, 9)

				UICorner_4.CornerRadius = UDim.new(2, 6)
				UICorner_4.Parent = CircleSmall

				Title_2.Name = "Title"
				Title_2.Parent = ColorpickerBtn
				Title_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Title_2.BackgroundTransparency = 1.000
				Title_2.Position = UDim2.new(0.0822436512, 0, 0.0333333351, 0)
				Title_2.Size = UDim2.new(0, 113, 0, 29)
				Title_2.ZIndex = 3
				Title_2.Font = Enum.Font.Gotham
				Title_2.Text = "Colorpicker"
				Title_2.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title_2.TextSize = 12.000
				Title_2.TextTransparency = 0.100
				Title_2.TextXAlignment = Enum.TextXAlignment.Left

				local FrameTonggled = false
				local Debounce = false

				ColorpickerBtn.MouseButton1Click:Connect(function()
					if FrameTonggled == false and Debounce == false then
						ColorPicker:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						
						Confirm.Visible = false
						Inputs.Visible = false
						Canvas.Visible = false
						
						Color.Visible = false
						Close.Visible = false
						
						Title.Visible = false
						
						FrameTonggled = true
						Debounce = true

						task.wait(.4)

						ColorPicker.Visible = false

						task.wait(1)

						Debounce = false
					else
						ColorPicker:TweenSize(UDim2.new(0, 132, 0, 169), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						
						Confirm.Visible = true
						Inputs.Visible = true
						Canvas.Visible = true

						Color.Visible = true
						Close.Visible = true

						Title.Visible = true
						
						ColorPicker.Visible = true
						FrameTonggled = false
					end
				end)

				Close.MouseButton1Click:Connect(function()
					if FrameTonggled == false and Debounce == false then
						ColorPicker:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						
						Confirm.Visible = false
						Inputs.Visible = false
						Canvas.Visible = false

						Color.Visible = false
						Close.Visible = false

						Title.Visible = false
						
						FrameTonggled = true
						Debounce = true

						task.wait(.4)

						ColorPicker.Visible = false

						task.wait(1)

						Debounce = false
					else
						ColorPicker:TweenSize(UDim2.new(0, 132, 0, 169), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						
						Confirm.Visible = true
						Inputs.Visible = true
						Canvas.Visible = true

						Color.Visible = true
						Close.Visible = true

						Title.Visible = true
						
						ColorPicker.Visible = true
						FrameTonggled = false
					end
				end)

				Confirm.MouseButton1Click:Connect(function()
					if FrameTonggled == false and Debounce == false then
						ColorPicker:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						
						Confirm.Visible = false
						Inputs.Visible = false
						Canvas.Visible = false

						Color.Visible = false
						Close.Visible = false

						Title.Visible = false
						
						FrameTonggled = true
						Debounce = true

						task.wait(.5)

						ColorPicker.Visible = false

						task.wait(.5)

						Debounce = false
					else
						ColorPicker:TweenSize(UDim2.new(0, 132, 0, 169), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						
						Confirm.Visible = true
						Inputs.Visible = true
						Canvas.Visible = true

						Color.Visible = true
						Close.Visible = true

						Title.Visible = true
						
						ColorPicker.Visible = true
						FrameTonggled = false
					end
				end)

				local mouse = game.Players.LocalPlayer:GetMouse()

				local movingColourSlider = false
				local movingDarknessSlider = false

				Slider.MouseButton1Down:Connect(function()
					movingColourSlider = true
				end)
				Slider.MouseButton1Up:Connect(function()
					movingColourSlider = false
				end)

				Color.MouseButton1Down:Connect(function()
					movingColourSlider = true
				end)
				Color.MouseButton1Up:Connect(function()
					movingColourSlider = false
				end)

				Canvas.MouseButton1Down:Connect(function()
					movingDarknessSlider = true
				end)
				Canvas.MouseButton1Up:Connect(function()
					movingDarknessSlider = false
				end)


				Cursor.MouseButton1Down:Connect(function()
					movingDarknessSlider = true
				end)
				Cursor.MouseButton1Up:Connect(function()
					movingDarknessSlider = false
				end)	

				mouse.Button1Up:Connect(function()
					movingColourSlider = false
					movingDarknessSlider = false
				end)

				mouse.Move:Connect(function()
					if _G.InfinityHub_Data.UIRaimbowEffect then
						return
					end

					if movingColourSlider then

						local xOffset = (mouse.X - Color.AbsolutePosition.X)

						xOffset = math.clamp(xOffset, 0, Color.AbsoluteSize.X)

						local sliderPosNew = UDim2.new(0, xOffset, Slider.Position.Y)
						Slider.Position = sliderPosNew
					end

					if movingDarknessSlider then

						local xOffset = (mouse.X - Color.AbsolutePosition.X)

						xOffset = math.clamp(xOffset, 0, Color.AbsoluteSize.X)

						local sliderPosNew = UDim2.new(0, xOffset, Slider.Position.Y)
						Cursor.Position = sliderPosNew
					end
				end)

				local function returnColour(percentage, gradientKeyPoints)

					local leftColour = gradientKeyPoints[1]
					local rightColour = gradientKeyPoints[#gradientKeyPoints]

					local lerpPercent = 0.5
					local colour = leftColour.Value


					for i = 1, #gradientKeyPoints - 1 do

						if gradientKeyPoints[i].Time <= percentage and gradientKeyPoints[i + 1].Time >= percentage then

							leftColour = gradientKeyPoints[i]
							rightColour = gradientKeyPoints[i + 1]

							lerpPercent = (percentage - leftColour.Time) / (rightColour.Time - leftColour.Time)

							colour = leftColour.Value:Lerp(rightColour.Value, lerpPercent)

							return colour
						end
					end	
				end

				local function updateColourPreview()
					if _G.InfinityHub_Data.UIRaimbowEffect then
						return
					end

					local colourMinXPos = Color.AbsolutePosition.X
					local colourMaxXPos = colourMinXPos + Color.AbsoluteSize.X

					local colourXPixelSize = colourMaxXPos - colourMinXPos

					local colourSliderX = Slider.AbsolutePosition.X

					local colourXPos = (colourSliderX - colourMinXPos) / colourXPixelSize


					local darknessMinXPos = Canvas.AbsolutePosition.X
					local darknessMaxXPos = darknessMinXPos + Canvas.AbsoluteSize.X

					local darknessXPixelSize = darknessMaxXPos - darknessMinXPos

					local darknessSliderX = Cursor.AbsolutePosition.X

					local darknessXPos = (darknessSliderX - darknessMinXPos) / darknessXPixelSize


					local darkness = returnColour(darknessXPos, Canvas.DarknessGradient.Color.Keypoints)
					local darknessR, darknessG, darknessB = 255 - math.floor(darkness.R * 255), 255 - math.floor(darkness.G * 255), 255 - math.floor(darkness.B * 255)


					local colour = returnColour(colourXPos, Color.ColourGradient.Color.Keypoints)
					local colourR, colourG, colourB = math.floor(colour.R * 255), math.floor(colour.G * 255), math.floor(colour.B * 255)

					local resultColour = Color3.fromRGB(colourR - darknessR, colourG - darknessG, colourB - darknessB)

					BoxColor.BackgroundColor3 = resultColour

					_G.InfinityHub_Data.PresetColor = resultColour
					MainColor = resultColour

					R.TextColorValue.Text = colourR - darknessR
					G.TextColorValue.Text = colourG - darknessG
					B.TextColorValue.Text = colourB - darknessB
				end

				OldToggleColor = _G.InfinityHub_Data.PresetColor

				coroutine.resume(coroutine.create(function()
					while wait() do
						if _G.InfinityHub_Data.UIRaimbowEffect then

							OldToggleColor = BoxColor.BackgroundColor3

							while _G.InfinityHub_Data.UIRaimbowEffect do

								BoxColor.BackgroundColor3 = Color3.fromHSV(RainbowColorValue, 1, 1)

								_G.InfinityHub_Data.PresetColor = Color3.fromHSV(RainbowColorValue, 1, 1)
								MainColor = Color3.fromHSV(RainbowColorValue, 1, 1)
								
								Cursor.Position = UDim2.new(0, 0, 0, 0)
								Slider.Position = UDim2.new(0, HueSelectionPosition, 0, 0)
								
								wait()
							end
						end
					end
				end))

				MakeDraggable(ColorPicker)

				UpdateSize()
				UpdateSectionFrame()

				Slider:GetPropertyChangedSignal("Position"):Connect(updateColourPreview)
				Cursor:GetPropertyChangedSignal("Position"):Connect(updateColourPreview)
			end

			function Elements:CreateLabel(ActionText)

				local Label = Instance.new("TextLabel")
				local UICorner = Instance.new("UICorner")

				local LabelFunctions = {}
				ActionText = ActionText or ""

				Label.Name = "Label"
				Label.Parent = Container
				Label.Active = true
				Label.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				Label.BorderSizePixel = 0
				Label.Selectable = true
				Label.Size = UDim2.new(1, 0, 0, 30)
				Label.ZIndex = 2
				Label.Font = Enum.Font.Gotham
				Label.Text = ActionText
				Label.TextColor3 = Color3.fromRGB(255, 255, 255)
				Label.TextSize = 12.000
				Label.TextTransparency = 0.100

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Label

				UpdateSize()
				UpdateSectionFrame()

				function LabelFunctions:UpdateLabel(newText)
					if Label.Text ~= "  "..newText then
						Label.Text = "  "..newText
					end
				end

				return LabelFunctions
			end

			function Elements:CreateButton(ActionText, callback)

				local Button = Instance.new("TextButton")
				local UICorner = Instance.new("UICorner")

				local ButtonFunctions = {}

				callback = callback or function() end		
				ActionText = ActionText or ""

				Button.Name = "Button"
				Button.Text = ActionText
				Button.Parent = Container
				Button.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				Button.BorderSizePixel = 0
				Button.Size = UDim2.new(1, 0, 0, 30)
				Button.ZIndex = 2
				Button.Font = Enum.Font.Gotham
				Button.TextColor3 = Color3.fromRGB(255, 255, 255)
				Button.TextSize = 12.000
				Button.TextTransparency = 0.100

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Button

				Button.MouseButton1Click:Connect(function()
					pcall(callback)
				end)

				UpdateSize()
				UpdateSectionFrame()

				function ButtonFunctions:UpdateButton(newTitle)
					Button.Text = newTitle
				end
				
				return ButtonFunctions
			end

			function Elements:CreateTextbox(ActionText, Disapper, defaultValue , MaxValue, callback)

				local Textbox = Instance.new("Frame")
				local Title = Instance.new("TextLabel")

				local Button = Instance.new("ImageLabel")
				local Textbox_2 = Instance.new("TextBox")

				local UICorner = Instance.new("UICorner")

				defaultValue = defaultValue or ""
				MaxValue = MaxValue or ""

				Textbox.Name = "Textbox"
				Textbox.Parent = Container
				Textbox.Active = true
				Textbox.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				Textbox.BorderSizePixel = 0
				Textbox.Selectable = true
				Textbox.Size = UDim2.new(1, 0, 0, 30)
				Textbox.ZIndex = 2

				Title.Name = "Title"
				Title.Parent = Textbox
				Title.AnchorPoint = Vector2.new(0, 0.5)
				Title.BackgroundTransparency = 1.000
				Title.Position = UDim2.new(0, 10, 0.5, 1)
				Title.Size = UDim2.new(0.5, 0, 1, 0)
				Title.ZIndex = 3
				Title.Font = Enum.Font.Gotham
				Title.Text = ActionText
				Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextSize = 12.000
				Title.TextTransparency = 0.100
				Title.TextXAlignment = Enum.TextXAlignment.Left

				Button.Name = "Button"
				Button.Parent = Textbox
				Button.BackgroundTransparency = 1.000
				Button.Position = UDim2.new(1, -110, 0.5, -8)
				Button.Size = UDim2.new(0, 100, 0, 16)
				Button.ZIndex = 2
				Button.Image = "rbxassetid://5028857472"
				Button.ImageColor3 = Color3.fromRGB(20, 20, 20)
				Button.ScaleType = Enum.ScaleType.Slice
				Button.SliceCenter = Rect.new(2, 2, 298, 298)

				Textbox_2.Name = "Textbox"
				Textbox_2.Parent = Button
				Textbox_2.BackgroundTransparency = 1.000
				Textbox_2.Position = UDim2.new(0, 5, 0, 0)
				Textbox_2.Size = UDim2.new(1, -10, 1, 0)
				Textbox_2.ZIndex = 3
				Textbox_2.Font = Enum.Font.GothamSemibold
				Textbox_2.Text = defaultValue
				Textbox_2.TextColor3 = Color3.fromRGB(255, 255, 255)
				Textbox_2.TextSize = 11.000

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Textbox

				Textbox_2.FocusLost:Connect(function(ep)
					if ep then
						if #Textbox_2.Text > 0 then
							pcall(callback, Textbox_2.Text)
							if Disapper then
								Textbox_2.Text = ""

							elseif not Disapper and tonumber(Textbox_2.Text) >= tonumber(MaxValue) then
								Textbox_2.Text = tonumber(MaxValue)
							end
						end
					end
				end)

				UpdateSize()
				UpdateSectionFrame()
			end

			function Elements:CreateToggle(ActionText, callback)

				local Tonggle = Instance.new("TextButton")
				local Title = Instance.new("TextLabel")
				local Button = Instance.new("ImageLabel")
				local Frame = Instance.new("ImageLabel")
				local UICorner = Instance.new("UICorner")

				callback = callback or function() end
				ActionText = ActionText or ""

				local TogFunction = {}
				local Tonggled = false

				Tonggle.Name = "Tonggle"
				Tonggle.Parent = Container
				Tonggle.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				Tonggle.BorderSizePixel = 0
				Tonggle.Size = UDim2.new(1, 0, 0, 30)
				Tonggle.ZIndex = 2
				Tonggle.Text = ""

				Title.Name = "Title"
				Title.Parent = Tonggle
				Title.AnchorPoint = Vector2.new(0, 0.5)
				Title.BackgroundTransparency = 1.000
				Title.Position = UDim2.new(0, 10, 0.5, 1)
				Title.Size = UDim2.new(0.5, 0, 1, 0)
				Title.ZIndex = 3
				Title.Font = Enum.Font.Gotham
				Title.Text = ActionText
				Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextSize = 12.000
				Title.TextTransparency = 0.100
				Title.TextXAlignment = Enum.TextXAlignment.Left

				Button.Name = "Button"
				Button.Parent = Tonggle
				Button.BackgroundTransparency = 1.000
				Button.BorderSizePixel = 0
				Button.Position = UDim2.new(1, -50, 0.5, -8)
				Button.Size = UDim2.new(0, 40, 0, 16)
				Button.ZIndex = 2
				Button.Image = "rbxassetid://5028857472"
				Button.ImageColor3 = Color3.fromRGB(20, 20, 20)
				Button.ScaleType = Enum.ScaleType.Slice
				Button.SliceCenter = Rect.new(2, 2, 298, 298)

				Frame.Name = "Frame"
				Frame.Parent = Button
				Frame.BackgroundTransparency = 1.000
				Frame.Position = UDim2.new(0, 2, 0.5, -6)
				Frame.Size = UDim2.new(1, -22, 1, -4)
				Frame.ZIndex = 2
				Frame.Image = "rbxassetid://5028857472"
				Frame.ScaleType = Enum.ScaleType.Slice
				Frame.SliceCenter = Rect.new(2, 2, 298, 298)

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Tonggle

				local function Fire()
					Tonggled = not Tonggled


					Frame:TweenPosition(Tonggled and UDim2.new(0, 22, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),"In", "Linear", 0.2, false)
					--ToggleFrame2.BackgroundColor3 = Tonggled and Color3.fromRGB(85, 255, 0) or Color3.fromRGB(35,35,35)
					pcall(callback, Tonggled)

					if Tonggled then
						Title.Text = ActionText
					else
						Title.Text = ActionText
					end
				end

				Tonggle.MouseButton1Click:Connect(Fire)

				UpdateSize()
				UpdateSectionFrame()

				function TogFunction:UpdateToggle(newText, isTogOn)
					isTogOn = isTogOn or Tonggled

					if newText ~= nil then 
						if Tonggled then
							Title.Text = newText
						else
							Title.Text = newText
						end
					end

					if isTogOn then
						Tonggled = true

						Frame:TweenPosition(Tonggled and UDim2.new(0, 22, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),"In", "Linear", 0.2, false)
						pcall(callback, Tonggled)
					else
						Tonggled = false

						Frame:TweenPosition(Tonggled and UDim2.new(0, 22, 0.5, -6) or UDim2.new(0, 2, 0.5, -6),"In", "Linear", 0.2, false)
						pcall(callback, Tonggled)
					end
				end
				return TogFunction
			end

			function Elements:CreateSlider(ActionText, default, min, max, callback)
				
				local Slider = Instance.new("ImageButton")

				local Title = Instance.new("TextLabel")
				local TextBox = Instance.new("TextBox")

				local SliderText = Instance.new("TextLabel")
				local Bar = Instance.new("ImageLabel")

				local Fill = Instance.new("ImageLabel")
				local Circle = Instance.new("ImageLabel")

				Slider.Name = "Slider"
				Slider.Parent = Container
				Slider.BackgroundTransparency = 1
				Slider.BorderSizePixel = 0
				Slider.Position = UDim2.new(0.292817682, 0, 0.299145311, 0)
				Slider.Size = UDim2.new(1, 0, 0, 50)
				Slider.ZIndex = 2
				Slider.Image = "rbxassetid://5028857472"
				Slider.ImageColor3 = Color3.fromRGB(14, 14, 14)
				Slider.ScaleType = Enum.ScaleType.Slice
				Slider.SliceCenter = Rect.new(2, 2, 298, 298)

				Title.Name = "Title"
				Title.BackgroundTransparency = 1
				Title.Position = UDim2.new(0, 10, 0, 6)
				Title.Size = UDim2.new(0.5, 0, 0, 16)
				Title.ZIndex = 3
				Title.Font = Enum.Font.Gotham
				Title.Text = ActionText
				Title.Parent = Slider
				Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextSize = 12
				Title.TextTransparency = 0.10000000149012
				Title.TextXAlignment = Enum.TextXAlignment.Left

				TextBox.Name = "TextBox"
				TextBox.BackgroundTransparency = 1
				TextBox.BorderSizePixel = 0
				TextBox.Position = UDim2.new(1, -30, 0, 6)
				TextBox.Size = UDim2.new(0, 20, 0, 16)
				TextBox.ZIndex = 3
				TextBox.Parent = Slider
				TextBox.Font = Enum.Font.GothamSemibold
				TextBox.Text = default or min
				TextBox.TextColor3 = Color3.fromRGB(255, 255, 255)
				TextBox.TextSize = 12
				TextBox.TextXAlignment = Enum.TextXAlignment.Right

				SliderText.Name = "Slider"
				SliderText.Parent = Slider
				SliderText.BackgroundTransparency = 1
				SliderText.Position = UDim2.new(0, 10, 0, 28)
				SliderText.Size = UDim2.new(1, -20, 0, 16)
				SliderText.ZIndex = 3
				SliderText.Text = ""

				Bar.Name = "Bar"
				Bar.Parent = SliderText
				Bar.AnchorPoint = Vector2.new(0, 0.5)
				Bar.BackgroundTransparency = 1
				Bar.Position = UDim2.new(0, 0, 0.5, 0)
				Bar.Size = UDim2.new(1, 0, 0, 4)
				Bar.ZIndex = 3
				Bar.Image = "rbxassetid://5028857472"
				Bar.ImageColor3 = Color3.fromRGB(20, 20, 20)
				Bar.ScaleType = Enum.ScaleType.Slice
				Bar.SliceCenter = Rect.new(2, 2, 298, 298)

				Fill.Name = "Fill"
				Fill.Parent = Bar
				Fill.BackgroundTransparency = 1
				Fill.Size = UDim2.new(0.8, 0, 1, 0)
				Fill.ZIndex = 3
				Fill.Image = "rbxassetid://5028857472"
				Fill.ImageColor3 = Color3.fromRGB(255, 255, 255)
				Fill.ScaleType = Enum.ScaleType.Slice
				Fill.SliceCenter = Rect.new(2, 2, 298, 298)

				Circle.Name = "Circle"
				Circle.Parent = Fill
				Circle.AnchorPoint = Vector2.new(0.5, 0.5)
				Circle.BackgroundTransparency = 1
				Circle.ImageTransparency = 1.000
				Circle.ImageColor3 = Color3.fromRGB(255, 255, 255)
				Circle.Position = UDim2.new(1, 0, 0.5, 0)
				Circle.Size = UDim2.new(0, 10, 0, 10)
				Circle.ZIndex = 3
				Circle.Image = "rbxassetid://4608020054"

				local Mouse = game.Players.LocalPlayer:GetMouse()
				
				local allowed = {[""] = true,["-"] = true}
				local value = default or min

				local dragging = false
				local CanDrag = false
				
				local function updateSlider(slider, title, value, min, max, lvalue)
					if title then
						Title.Text = title
					end

					local percent = (Mouse.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X

					if value then
						percent = (value - min) / (max - min)
					end

					percent = math.clamp(percent, 0, 1)
					value = value or math.floor(min + (max - min) * percent)

					TextBox.Text = value
					TweenService:Create(Fill, TweenInfo.new(0.1), {Size = UDim2.new(percent, 0, 1, 0)}):Play()

					return value
				end

				updateSlider(Slider, nil, value, min, max)

				Slider.MouseButton1Down:Connect(function(input)
					if dragging then
						dragging = false
					else
						dragging = true
					end

					while dragging and CanDrag do
						TweenService:Create(Circle, TweenInfo.new(0.1), {ImageTransparency = 0}):Play()

						value = updateSlider(Slider, nil, nil, min, max, value)
						pcall(callback, value)

						RS.RenderStepped:Wait()
					end

					wait(0.5)
					TweenService:Create(Circle, TweenInfo.new(0.2), {ImageTransparency = 1}):Play()
				end)

				Slider.MouseLeave:Connect(function()
					dragging = false
					CanDrag = false
				end)

				Slider.MouseEnter:Connect(function()
					CanDrag = true
				end)

				TextBox.FocusLost:Connect(function()
					if not tonumber(TextBox.Text) then
						value = updateSlider(Slider, nil, default or min, min, max)
						pcall(callback, value)
					end
				end)

				TextBox:GetPropertyChangedSignal("Text"):Connect(function()
					local text = TextBox.Text

					if not allowed[text] and not tonumber(text) then
						TextBox.Text = text:sub(1, #text - 1)

					elseif not allowed[text] then	
						value = updateSlider(Slider, nil, tonumber(text) or value, min, max)
						pcall(callback, value)
					end
				end)

				UpdateSize()
				UpdateSectionFrame()
			end
			
			function Elements:CreateDropDown(ActionText, ActionText2, list, callback)
				local DropFunc = {}
				local Selected = nil
				
				local FrameSize = 43
				local ItemCount = 0
				
				local DropToggled = false
				
				local Dropdown = Instance.new("TextButton")
				local DropdownCorner = Instance.new("UICorner")
				local Title = Instance.new("TextLabel")
				local ArrowIco = Instance.new("ImageLabel")
				local DropItemHolder = Instance.new("ScrollingFrame")
				local DropLayout = Instance.new("UIListLayout")

				Dropdown.Name = "Dropdown"
				Dropdown.Parent = Container
				Dropdown.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				Dropdown.ClipsDescendants = true
				Dropdown.Position = UDim2.new(0.110937499, 0, 0.67653507, 0)
				Dropdown.Size = UDim2.new(1, 0, 0, 30)
				Dropdown.AutoButtonColor = false
				Dropdown.Font = Enum.Font.SourceSans
				Dropdown.Text = ""
				Dropdown.TextColor3 = Color3.fromRGB(0, 0, 0)
				Dropdown.TextSize = 14.000
				Dropdown.ZIndex = 2

				DropdownCorner.CornerRadius = UDim.new(0, 4)
				DropdownCorner.Name = "DropdownCorner"
				DropdownCorner.Parent = Dropdown

				Title.Name = "Title"
				Title.Parent = Dropdown
				Title.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				Title.BackgroundTransparency = 1.000
				Title.Position = UDim2.new(0.028, 0, 0, 0)
				Title.Size = UDim2.new(0, 113, 0, 30)
				Title.Font = Enum.Font.Gotham
				Title.Text = ActionText
				Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextStrokeColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextSize = 12
				Title.ZIndex = 3
				Title.TextTransparency = 0.1
				Title.TextXAlignment = Enum.TextXAlignment.Left

				ArrowIco.Name = "ArrowIco"
				ArrowIco.Parent = Title
				ArrowIco.AnchorPoint = Vector2.new(0.5, 0.5)
				ArrowIco.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				ArrowIco.BackgroundTransparency = 1.000
				ArrowIco.Position = UDim2.new(2.8, 0, 0, 16)
				ArrowIco.Selectable = true
				ArrowIco.ZIndex = 3
				ArrowIco.Size = UDim2.new(0, 22, 0, 22)
				ArrowIco.Image = "http://www.roblox.com/asset/?id=7072706663"
				ArrowIco.ImageTransparency = .3

				DropItemHolder.Name = "DropItemHolder"
				DropItemHolder.Parent = Title
				DropItemHolder.Active = true
				DropItemHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				DropItemHolder.BackgroundTransparency = 1.000
				DropItemHolder.ZIndex = 3
				DropItemHolder.BorderSizePixel = 0
				DropItemHolder.Position = UDim2.new(-0.042, 0, 1.024, 0)
				DropItemHolder.Size = UDim2.new(3, 0, 0, 82)
				DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, 0)
				DropItemHolder.ScrollBarThickness = 5
				DropItemHolder.ScrollBarImageColor3 = Color3.fromRGB(41, 42, 48)

				DropLayout.Name = "DropLayout"
				DropLayout.Parent = DropItemHolder
				DropLayout.SortOrder = Enum.SortOrder.LayoutOrder
				DropLayout.Padding = UDim.new(0, 2)

				Dropdown.MouseButton1Click:Connect(function()
					if DropToggled == false then
						Title.Text = ActionText2.." "..tostring(Selected)
						Dropdown:TweenSize(UDim2.new(1, 0, 0, FrameSize), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageTransparency = 0}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Rotation = 180}
						):Play()
						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0}
						):Play()
						
						wait(.4)
						
						UpdateSize()
						UpdateSectionFrame()
						
						Container.Size = UDim2.new(1, -16, 1, ContainerLayout.AbsoluteContentSize.Y)
					else
						Title.Text = ActionText2.." "..tostring(Selected)
						Dropdown:TweenSize(UDim2.new(1, 0, 0, 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageTransparency = .3}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Rotation = 0}
						):Play()
						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
						
						wait(.4)
						
						UpdateSize()
						UpdateSectionFrame()
						
						Container.Size = UDim2.new(1, -16, 1, ContainerLayout.AbsoluteContentSize.Y)
					end
					DropToggled = not DropToggled
				end)

				for i,v in next, list do
					ItemCount = ItemCount + 1

					if ItemCount == 1 then
						FrameSize = 78
					elseif ItemCount == 2 then
						FrameSize = 107
					elseif ItemCount >= 3 then
						FrameSize = 133
					end
					
					local Item = Instance.new("TextButton")
					local ItemCorner = Instance.new("UICorner")

					Item.Name = "Item"
					Item.Parent = DropItemHolder
					Item.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
					Item.ClipsDescendants = true
					Item.Size = UDim2.new(1, 0, 0, 25)
					Item.AutoButtonColor = false
					Item.Font = Enum.Font.Gotham
					Item.ZIndex = 3
					Item.Text = v
					Item.TextColor3 = Color3.fromRGB(255, 255, 255)
					Item.TextSize = 15.000
					Item.TextTransparency = 0.3

					ItemCorner.CornerRadius = UDim.new(0, 5)
					ItemCorner.Name = "ItemCorner"
					ItemCorner.Parent = Item
					DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y)

					Item.MouseEnter:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0}
						):Play()
					end)

					Item.MouseLeave:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
					end)

					Item.MouseButton1Click:Connect(function()
						pcall(callback, v)
						
						Title.Text = ActionText2.." "..v
						Selected = v
						
						DropToggled = not DropToggled
						
						Dropdown:TweenSize(UDim2.new(1, 0, 0, 30), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageTransparency = .3}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Rotation = 0}
						):Play()

						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
						
						wait(.4)
						
						UpdateSize()
						UpdateSectionFrame()
						
						Container.Size = UDim2.new(1, -16, 1, ContainerLayout.AbsoluteContentSize.Y)

					end)
				end
				
				function DropFunc:Add(addtext)
					ItemCount = ItemCount + 1

					if ItemCount == 1 then
						FrameSize = 78
					elseif ItemCount == 2 then
						FrameSize = 107
					elseif ItemCount >= 3 then
						FrameSize = 133
					end
					local Item = Instance.new("TextButton")
					local ItemCorner = Instance.new("UICorner")

					Item.Name = "Item"
					Item.Parent = DropItemHolder
					Item.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
					Item.ClipsDescendants = true
					Item.Size = UDim2.new(1, 0, 0, 25)
					Item.AutoButtonColor = false
					Item.Font = Enum.Font.Gotham
					Item.ZIndex = 3
					Item.Text = addtext
					Item.TextColor3 = Color3.fromRGB(255, 255, 255)
					Item.TextSize = 15.000
					Item.TextTransparency = 0.3

					ItemCorner.CornerRadius = UDim.new(0, 4)
					ItemCorner.Name = "ItemCorner"
					ItemCorner.Parent = Item
					DropItemHolder.CanvasSize = UDim2.new(0, 0, 0, DropLayout.AbsoluteContentSize.Y)

					Item.MouseEnter:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0}
						):Play()
					end)

					Item.MouseLeave:Connect(function()
						TweenService:Create(
							Item,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
					end)

					Item.MouseButton1Click:Connect(function()
						pcall(callback, addtext)
						
						Title.Text = ActionText
						Selected = addtext
						
						DropToggled = not DropToggled
						
						Dropdown:TweenSize(UDim2.new(1, 0, 0, 43), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageTransparency = .3}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Rotation = 0}
						):Play()

						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
						
						wait(.4)
						
						UpdateSize()
						UpdateSectionFrame()
						
						Container.Size = UDim2.new(1, -16, 1, ContainerLayout.AbsoluteContentSize.Y)
					end)
					if DropToggled == true then
						Title.Text = Selected
						Dropdown:TweenSize(UDim2.new(1, 0, 0, 43), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageTransparency = .3}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Rotation = 0}
						):Play()
						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
						
						wait(.4)
						
						UpdateSize()
						UpdateSectionFrame()
						
						Container.Size = UDim2.new(1, -16, 1, ContainerLayout.AbsoluteContentSize.Y)
					end
				end

				function DropFunc:Clear()
					Title.Text = ActionText
					FrameSize = 0
					ItemCount = 0
					
					for i, v in next, DropItemHolder:GetChildren() do
						if v.Name == "Item" then
							v:Destroy()
						end
					end
					
					if DropToggled == true then
						Title.Text = Selected
						Dropdown:TweenSize(UDim2.new(1, 0, 0, 43), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, .6, true)
						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextColor3 = Color3.fromRGB(255,255,255)}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageColor3 = Color3.fromRGB(255,255,255)}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{ImageTransparency = .3}
						):Play()
						TweenService:Create(
							ArrowIco,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{Rotation = 0}
						):Play()
						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
						
						wait(.4)
						
						UpdateSize()
						UpdateSectionFrame()
						
						Container.Size = UDim2.new(0, 0, 0, ContainerLayout.AbsoluteContentSize.Y)
					end
				end
				
				UpdateSize()
				UpdateSectionFrame()
				
				return DropFunc
			end
			
			function Elements:CreateBind(ActionText, PresetBind, callback)

				local Keybind = Instance.new("Frame")
				local Title = Instance.new("TextLabel")
				local UICorner = Instance.new("UICorner")
				local Bind = Instance.new("ImageButton")
				local Text = Instance.new("TextLabel")

				local Key = PresetBind.Name

				Keybind.Name = "Keybind"
				Keybind.Parent = Container
				Keybind.Active = true
				Keybind.BackgroundColor3 = Color3.fromRGB(14, 14, 14)
				Keybind.BorderSizePixel = 0
				Keybind.Selectable = true
				Keybind.Size = UDim2.new(1, 0, 0, 30)
				Keybind.ZIndex = 2

				Title.Name = "Title"
				Title.Parent = Keybind
				Title.AnchorPoint = Vector2.new(0, 0.5)
				Title.BackgroundTransparency = 1.000
				Title.Position = UDim2.new(0, 10, 0.5, 1)
				Title.Size = UDim2.new(1, 0, 1, 0)
				Title.ZIndex = 3
				Title.Font = Enum.Font.Gotham
				Title.Text = "Keybind"
				Title.TextColor3 = Color3.fromRGB(255, 255, 255)
				Title.TextSize = 12.000
				Title.TextTransparency = 0.100
				Title.TextXAlignment = Enum.TextXAlignment.Left

				UICorner.CornerRadius = UDim.new(0, 5)
				UICorner.Parent = Keybind

				Bind.Name = "Bind"
				Bind.Parent = Keybind
				Bind.Active = false
				Bind.BackgroundTransparency = 1.000
				Bind.Position = UDim2.new(1, -110, 0.5, -8)
				Bind.Selectable = false
				Bind.Size = UDim2.new(0, 100, 0, 16)
				Bind.ZIndex = 2
				Bind.Image = "rbxassetid://5028857472"
				Bind.ImageColor3 = Color3.fromRGB(20, 20, 20)
				Bind.ScaleType = Enum.ScaleType.Slice
				Bind.SliceCenter = Rect.new(2, 2, 298, 298)

				Text.Name = "Text"
				Text.Parent = Bind
				Text.BackgroundTransparency = 1.000
				Text.ClipsDescendants = true
				Text.Size = UDim2.new(1, 0, 1, 0)
				Text.ZIndex = 3
				Text.Font = Enum.Font.GothamSemibold
				Text.Text = Key
				Text.TextColor3 = Color3.fromRGB(255, 255, 255)
				Text.TextSize = 11.000

				Bind.MouseButton1Click:connect(
					function()
						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextColor3 = _G.InfinityHub_Data.PresetColor}
						):Play()

						TweenService:Create(
							Text,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextColor3 = _G.InfinityHub_Data.PresetColor}
						):Play()

						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0}
						):Play()

						TweenService:Create(
							Text,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0}
						):Play()

						Text.Text = "..."

						local inputwait = game:GetService("UserInputService").InputBegan:wait()

						if inputwait.KeyCode.Name ~= "Unknown" then
							Text.Text = inputwait.KeyCode.Name
							Key = inputwait.KeyCode.Name
						end

						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextColor3 = Color3.fromRGB(255,255,255)}
						):Play()

						TweenService:Create(
							Text,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextColor3 = Color3.fromRGB(255,255,255)}
						):Play()

						TweenService:Create(
							Title,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()

						TweenService:Create(
							Text,
							TweenInfo.new(.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
							{TextTransparency = 0.3}
						):Play()
					end
				)

				game:GetService("UserInputService").InputBegan:Connect(function(current, pressed)
					if not pressed then
						if current.KeyCode.Name == Key then
							pcall(callback, current.KeyCode)
						end
					end
				end)

				UpdateSize()
				UpdateSectionFrame()
			end
			return Elements
		end	
		return Sections
	end
	return Tabs
end
return library
