local HttpService = game:GetService("HttpService")
local MPS = game:GetService("MarketplaceService")

local VirtualUser = game:service("VirtualUser")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")

local CoreGui = game:GetService("CoreGui")

local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

local PlayerGui = Player:WaitForChild("PlayerGui")

local Lighting = game:GetService("Lighting")
local _Workspace_ = game:GetService("Workspace")
local Camera = _Workspace_.CurrentCamera

local library
local FPS = 0

if game:GetService("RunService"):IsStudio() then
	library = require(script.Parent:WaitForChild("UI_LibraryModule"))
else
	library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Trollmaster847/InfinityHub/main/Utilities/UI_Library.lua"))()
end

game:GetService("RunService").RenderStepped:Connect(function()
	FPS += 1
end)

function getRoot(char)
	local rootPart = char:FindFirstChild('HumanoidRootPart') or char:FindFirstChild('Torso') or char:FindFirstChild('UpperTorso')
	return rootPart
end

function CheckTools(plr)
	if plr:FindFirstChildOfClass("Backpack"):FindFirstChildOfClass('Tool') or plr.Character:FindFirstChildOfClass('Tool') then
		return true
	end
end


function randomString()
	local length = math.random(10,20)
	local array = {}

	for i = 1, length do
		array[i] = string.char(math.random(32, 126))
	end

	return table.concat(array)
end

local INPUT_PRIORITY = Enum.ContextActionPriority.High.Value

Input = {} do

	keyboard = {
		W = 0,
		A = 0,
		S = 0,
		D = 0,
		E = 0,
		Q = 0,
		Up = 0,
		Down = 0,
		LeftShift = 0,
	}

	mouse = {
		Delta = Vector2.new(),
	}

	NAV_KEYBOARD_SPEED = Vector3.new(1, 1, 1)
	PAN_MOUSE_SPEED = Vector2.new(1, 1)*(math.pi/64)
	NAV_ADJ_SPEED = 0.75
	NAV_SHIFT_MUL = 0.25

	navSpeed = 1

	function Input.Vel(dt)
		navSpeed = math.clamp(navSpeed + dt*(keyboard.Up - keyboard.Down)*NAV_ADJ_SPEED, 0.01, 4)

		local kKeyboard = Vector3.new(
			keyboard.D - keyboard.A,
			keyboard.E - keyboard.Q,
			keyboard.S - keyboard.W
		)*NAV_KEYBOARD_SPEED

		local shift = UIS:IsKeyDown(Enum.KeyCode.LeftShift)

		return (kKeyboard)*(navSpeed*(shift and NAV_SHIFT_MUL or 1))
	end

	function Input.Pan(dt)
		local kMouse = mouse.Delta*PAN_MOUSE_SPEED
		mouse.Delta = Vector2.new()
		return kMouse
	end

	do
		function Keypress(action, state, input)
			keyboard[input.KeyCode.Name] = state == Enum.UserInputState.Begin and 1 or 0
			return Enum.ContextActionResult.Sink
		end

		function MousePan(action, state, input)
			local delta = input.Delta
			mouse.Delta = Vector2.new(-delta.y, -delta.x)
			return Enum.ContextActionResult.Sink
		end

		function Zero(t)
			for k, v in pairs(t) do
				t[k] = v*0
			end
		end

		function Input.StartCapture()
			game:GetService("ContextActionService"):BindActionAtPriority("FreecamKeyboard",Keypress,false,INPUT_PRIORITY,
			Enum.KeyCode.W,
			Enum.KeyCode.A,
			Enum.KeyCode.S,
			Enum.KeyCode.D,
			Enum.KeyCode.E,
			Enum.KeyCode.Q,
			Enum.KeyCode.Up,
			Enum.KeyCode.Down
			)
			game:GetService("ContextActionService"):BindActionAtPriority("FreecamMousePan",MousePan,false,INPUT_PRIORITY,Enum.UserInputType.MouseMovement)
		end

		function Input.StopCapture()
			navSpeed = 1
			Zero(keyboard)
			Zero(mouse)
			game:GetService("ContextActionService"):UnbindAction("FreecamKeyboard")
			game:GetService("ContextActionService"):UnbindAction("FreecamMousePan")
		end
	end
end

local PlayerState = {} do
	mouseBehavior = ""
	mouseIconEnabled = ""
	cameraType = ""
	cameraFocus = ""
	cameraCFrame = ""
	cameraFieldOfView = ""

	function PlayerState.Push()
		cameraFieldOfView = Camera.FieldOfView
		Camera.FieldOfView = 70

		cameraType = Camera.CameraType
		Camera.CameraType = Enum.CameraType.Custom

		cameraCFrame = Camera.CFrame
		cameraFocus = Camera.Focus

		mouseIconEnabled = UIS.MouseIconEnabled
		UIS.MouseIconEnabled = true

		mouseBehavior = UIS.MouseBehavior
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	end

	function PlayerState.Pop()
		Camera.FieldOfView = 70

		Camera.CameraType = cameraType
		cameraType = nil

		Camera.CFrame = cameraCFrame
		cameraCFrame = nil

		Camera.Focus = cameraFocus
		cameraFocus = nil

		UIS.MouseIconEnabled = mouseIconEnabled
		mouseIconEnabled = nil

		UIS.MouseBehavior = mouseBehavior
		mouseBehavior = nil
	end
end

Spring = {} do
	Spring.__index = Spring

	function Spring.new(freq, pos)
		local self = setmetatable({}, Spring)
		self.f = freq
		self.p = pos
		self.v = pos*0
		return self
	end

	function Spring:Update(dt, goal)
		local f = self.f*2*math.pi
		local p0 = self.p
		local v0 = self.v

		local offset = goal - p0
		local decay = math.exp(-f*dt)

		local p1 = goal + (v0*dt - offset*(f*dt + 1))*decay
		local v1 = (f*dt*(offset*f - v0) + v0)*decay

		self.p = p1
		self.v = v1

		return p1
	end

	function Spring:Reset(pos)
		self.p = pos
		self.v = pos*0
	end
end

function GetFocusDistance(cameraFrame)
	local znear = 0.1
	local viewport = Camera.ViewportSize
	local projy = 2*math.tan(cameraFov/2)
	local projx = viewport.x/viewport.y*projy
	local fx = cameraFrame.rightVector
	local fy = cameraFrame.upVector
	local fz = cameraFrame.lookVector

	local minVect = Vector3.new()
	local minDist = 512

	for x = 0, 1, 0.5 do
		for y = 0, 1, 0.5 do
			local cx = (x - 0.5)*projx
			local cy = (y - 0.5)*projy
			local offset = fx*cx - fy*cy + fz
			local origin = cameraFrame.p + offset*znear
			local _, hit = workspace:FindPartOnRay(Ray.new(origin, offset.unit*minDist))
			local dist = (hit - origin).magnitude
			if minDist > dist then
				minDist = dist
				minVect = offset.unit
			end
		end
	end

	return fz:Dot(minVect)*minDist
end

function CreateESP(Plr)
	task.spawn(function()
		for i,v in pairs(CoreGui:GetChildren()) do
			if v.Name == Plr.Name..'_ESP' then
				v:Destroy()
			end
		end
		
		wait()
		
		if Plr.Character and Plr.Name ~= Players.LocalPlayer.Name and not CoreGui:FindFirstChild(Plr.Name..'_ESP') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = Plr.Name..'_ESP'
			ESPholder.Parent = CoreGui
			
			repeat wait(1) until Plr.Character and getRoot(Plr.Character) and Plr.Character:FindFirstChildOfClass("Humanoid")
			
			if Plr.Character and Plr.Character:FindFirstChild('Head') then
				local BillboardGui = Instance.new("BillboardGui")
				local TextLabel = Instance.new("TextLabel")
				
				BillboardGui.Adornee = Plr.Character.Head
				BillboardGui.Name = Plr.Name
				BillboardGui.Parent = ESPholder
				BillboardGui.Size = UDim2.new(0, 100, 0, 150)
				BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
				BillboardGui.AlwaysOnTop = true
				
				TextLabel.Parent = BillboardGui
				TextLabel.BackgroundTransparency = 1
				TextLabel.Position = UDim2.new(0, 0, 0, -50)
				TextLabel.Size = UDim2.new(0, 100, 0, 100)
				TextLabel.Font = Enum.Font.SourceSansSemibold
				TextLabel.TextSize = 20
				TextLabel.TextColor3 = Color3.new(1, 1, 1)
				TextLabel.TextStrokeTransparency = 0
				TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
				TextLabel.Text = Plr.Name
				TextLabel.ZIndex = 10
				
				local EspLoopFunc
				local TeamChange
				local AddedFunc
				
				AddedFunc = Plr.CharacterAdded:Connect(function()
					if _G.InfinityHub_Data.PlayerESP then
						EspLoopFunc:Disconnect()
						TeamChange:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(Plr.Character) and Plr.Character:FindFirstChildOfClass("Humanoid")
						CreateESP(Plr)
						AddedFunc:Disconnect()
					else
						TeamChange:Disconnect()
						AddedFunc:Disconnect()
					end
				end)
				
				TeamChange = Plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
					if _G.InfinityHub_Data.PlayerESP then
						EspLoopFunc:Disconnect()
						AddedFunc:Disconnect()
						ESPholder:Destroy()
						repeat wait(1) until getRoot(Plr.Character) and Plr.Character:FindFirstChildOfClass("Humanoid")
						CreateESP(Plr)
						TeamChange:Disconnect()
					else
						TeamChange:Disconnect()
					end
				end)
				
				local function espLoop()
					if CoreGui:FindFirstChild(Plr.Name..'_ESP') then
						if Plr.Character and getRoot(Plr.Character) and Plr.Character:FindFirstChildOfClass("Humanoid") and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
							TextLabel.Text = Plr.Name
						end
					else
						TeamChange:Disconnect()
						AddedFunc:Disconnect()
						EspLoopFunc:Disconnect()
					end
				end
				EspLoopFunc = game:GetService("RunService").RenderStepped:Connect(espLoop)
			end
		end
	end)
end
function CreateCHMS(Plr)
	task.spawn(function()
		for i,v in pairs(CoreGui:GetChildren()) do
			if v.Name == Plr.Name..'_CHMS' then
				v:Destroy()
			end
		end
		
		wait()
		
		if Plr.Character and Plr.Name ~= Players.LocalPlayer.Name and not CoreGui:FindFirstChild(Plr.Name..'_CHMS') then
			local ESPholder = Instance.new("Folder")
			ESPholder.Name = Plr.Name..'_CHMS'
			ESPholder.Parent = CoreGui
			
			repeat wait(1) until Plr.Character and getRoot(Plr.Character) and Plr.Character:FindFirstChildOfClass("Humanoid")
			
			for b,n in pairs (Plr.Character:GetChildren()) do
				if (n:IsA("BasePart")) then
					local a = Instance.new("BoxHandleAdornment")
					a.Name = Plr.Name
					a.Parent = ESPholder
					a.Adornee = n
					a.AlwaysOnTop = true
					a.ZIndex = 10
					a.Size = n.Size
					a.Transparency = 0.3
					a.Color = Plr.TeamColor
				end
			end
			
			local AddedFunc
			local TeamChange
			local CHMSremoved
			
			AddedFunc = Plr.CharacterAdded:Connect(function()
				if _G.InfinityHub_Data.PlayerChams then
					ESPholder:Destroy()
					TeamChange:Disconnect()
					repeat wait(1) until getRoot(Plr.Character) and Plr.Character:FindFirstChildOfClass("Humanoid")
					CreateCHMS(Plr)
					AddedFunc:Disconnect()
				else
					TeamChange:Disconnect()
					AddedFunc:Disconnect()
				end
			end)
			
			TeamChange = Plr:GetPropertyChangedSignal("TeamColor"):Connect(function()
				if _G.InfinityHub_Data.PlayerChams then
					ESPholder:Destroy()
					AddedFunc:Disconnect()
					repeat wait(1) until getRoot(Plr.Character) and Plr.Character:FindFirstChildOfClass("Humanoid")
					CreateCHMS(Plr)
					TeamChange:Disconnect()
				else
					TeamChange:Disconnect()
				end
			end)
			
			CHMSremoved = ESPholder.AncestryChanged:Connect(function()
				TeamChange:Disconnect()
				AddedFunc:Disconnect()
				CHMSremoved:Disconnect()
			end)
		end
	end)
end
function CreateTracer()
	for i,v in pairs(game.Players:GetPlayers()) do	
		local Tracer = Drawing.new("Line")
		Tracer.Visible = true
		Tracer.Color = Color3.fromRGB(255, 255, 255)
		Tracer.Thickness = 1
		Tracer.Transparency = 1

		RS.RenderStepped:Connect(function()
			if v ~= Player and v ~= nil and v.Character ~= nil and v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health > 0 and v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
				local vector, OnScreen = Camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)

				if OnScreen then
					Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
					Tracer.To = Vector2.new(vector.X, vector.Y)
					Tracer.Visible = true
				else
					Tracer.Visible = false
				end
			else
				Tracer.Visible = false
			end
			if _G.InfinityHub_Data.PlayerTracerESP == false then
				Tracer.Visible = false
			end
		end)
	end

	game.Players.PlayerAdded:Connect(function(v)
		local Tracer = Drawing.new("Line")
		Tracer.Visible = true
		Tracer.Color = Color3.fromRGB(255, 255, 255)
		Tracer.Thickness = 1
		Tracer.Transparency = 1

		RS.RenderStepped:Connect(function()
			if v ~= nil and v.Character ~= nil and v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("Humanoid").Health > 0 and v.Character:FindFirstChild("HumanoidRootPart") ~= nil then
				local vector, OnScreen = Camera:WorldToViewportPoint(v.Character.HumanoidRootPart.Position)

				if OnScreen then
					Tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
					Tracer.To = Vector2.new(vector.X, vector.Y)
					Tracer.Visible = true
				else
					Tracer.Visible = false
				end
			else
				Tracer.Visible = false
			end
			if _G.InfinityHub_Data.PlayerTracerESP == false then
				Tracer.Visible = false
			end
		end)
	end)
end
function CreateBox()

	local worldToViewportPoint = Camera.worldToViewportPoint

	local HeadOff = Vector3.new(0, 0.5, 0)
	local LegOff = Vector3.new(0,3,0)

	for i,v in pairs(game.Players:GetChildren()) do
		local BoxOutline = Drawing.new("Square")
		BoxOutline.Visible = false
		BoxOutline.Color = Color3.new(0,0,0)
		BoxOutline.Thickness = 3
		BoxOutline.Transparency = 1
		BoxOutline.Filled = false

		local Box = Drawing.new("Square")
		Box.Visible = false
		Box.Color = Color3.fromRGB(255, 255, 255)
		Box.Thickness = 1
		Box.Transparency = 1
		Box.Filled = false

		game:GetService("RunService").RenderStepped:Connect(function()
			if v.Character ~= nil and v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("HumanoidRootPart") ~= nil and v.Character:FindFirstChild("Head") ~= nil and v ~= Player and v.Character.Humanoid.Health > 0 then
				local Vector, onScreen = Camera:worldToViewportPoint(v.Character.HumanoidRootPart.Position)

				local RootPart = v.Character.HumanoidRootPart
				local Head = v.Character.Head
				local RootPosition, RootVis = worldToViewportPoint(Camera, RootPart.Position)
				local HeadPosition = worldToViewportPoint(Camera, Head.Position + HeadOff)
				local LegPosition = worldToViewportPoint(Camera, RootPart.Position - LegOff)

				if onScreen then
					BoxOutline.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
					BoxOutline.Position = Vector2.new(RootPosition.X - BoxOutline.Size.X / 2, RootPosition.Y - BoxOutline.Size.Y / 2)
					BoxOutline.Visible = true

					Box.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
					Box.Position = Vector2.new(RootPosition.X - Box.Size.X / 2, RootPosition.Y - Box.Size.Y / 2)
					Box.Visible = true

				else
					BoxOutline.Visible = false
					Box.Visible = false
				end
			else
				BoxOutline.Visible = false
				Box.Visible = false
			end
			if _G.InfinityHub_Data.PlayerBoxESP == false then
				BoxOutline.Visible = false
				Box.Visible = false
			end
		end)
	end

	game.Players.PlayerAdded:Connect(function(v)
		local BoxOutline = Drawing.new("Square")
		BoxOutline.Visible = false
		BoxOutline.Color = Color3.new(0,0,0)
		BoxOutline.Thickness = 3
		BoxOutline.Transparency = 1
		BoxOutline.Filled = false

		local Box = Drawing.new("Square")
		Box.Visible = false
		Box.Color = Color3.fromRGB(255, 255, 255)
		Box.Thickness = 1
		Box.Transparency = 1
		Box.Filled = false

		game:GetService("RunService").RenderStepped:Connect(function()
			if v.Character ~= nil and v.Character:FindFirstChild("Humanoid") ~= nil and v.Character:FindFirstChild("HumanoidRootPart") ~= nil and v ~= Player and v.Character.Humanoid.Health > 0 then
				local Vector, onScreen = Camera:worldToViewportPoint(v.Character.HumanoidRootPart.Position)

				local RootPart = v.Character.HumanoidRootPart
				local Head = v.Character.Head
				local RootPosition, RootVis = worldToViewportPoint(Camera, RootPart.Position)
				local HeadPosition = worldToViewportPoint(Camera, Head.Position + HeadOff)
				local LegPosition = worldToViewportPoint(Camera, RootPart.Position - LegOff)

				if onScreen then
					BoxOutline.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
					BoxOutline.Position = Vector2.new(RootPosition.X - BoxOutline.Size.X / 2, RootPosition.Y - BoxOutline.Size.Y / 2)
					BoxOutline.Visible = true

					Box.Size = Vector2.new(1000 / RootPosition.Z, HeadPosition.Y - LegPosition.Y)
					Box.Position = Vector2.new(RootPosition.X - Box.Size.X / 2, RootPosition.Y - Box.Size.Y / 2)
					Box.Visible = true

				else
					BoxOutline.Visible = false
					Box.Visible = false
				end
			else
				BoxOutline.Visible = false
				Box.Visible = false
			end
			if _G.InfinityHub_Data.PlayerBoxESP == false then
				BoxOutline.Visible = false
				Box.Visible = false
			end
		end)
	end)
end

local s, info = pcall(MPS.GetProductInfo,MPS,game.PlaceId)
local Window = library:CreateWindow("Infinity Hub", Color3.fromRGB(0, 255, 0), Enum.KeyCode.LeftControl)

local Home = Window:CreatePage("Home", 7072717697, 1)
local HomeSection = Home:CreateSection("Home")

HomeSection:CreateButton("Place Name: "..tostring(info.Name))

HomeSection:CreateButton("Player UserId: "..Player.UserId)
HomeSection:CreateButton("Player: "..Player.DisplayName.." | @"..Player.Name)

local FPSBtn = HomeSection:CreateButton("FPS: "..FPS)

HomeSection:CreateButton("JobId: "..game.JobId, function()
	if setclipboard then
		setclipboard(game.JobId)
		library:CoreNotification('Discord Invite', 'Copied to clipboard!\n'..game.JobId)
	else
		library:CoreNotification('Discord Invite', 'Can not copy JobId!\n'..game.JobId)
	end
end)

HomeSection:CreateButton("Copy Discord Server Invitation", function(args)
	--Main:Notify(tostring(info.Name),"Copied Discord Invitation!","Normal")

	if setclipboard then
		setclipboard('https://discord.com/invite/eWXxNYZd5p')
		library:CoreNotification('Discord Invite', 'Copied to clipboard!\ndiscord.gg/eWXxNYZd5p')
	else
		library:CoreNotification('Discord Invite', 'discord.gg/eWXxNYZd5p')
	end

	local req = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request

	if req then
		req({
			Url = 'http://127.0.0.1:6463/rpc?v=1',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				Origin = 'https://discord.com'
			},
			Body = HttpService:JSONEncode({
				cmd = 'INVITE_BROWSER',
				nonce = HttpService:GenerateGUID(false),
				args = {code = 'eWXxNYZd5p'}
			})
		})
	end
end)

local Universal = Window:CreatePage("Universal", 7072717348, 4)

local UniversalSection = Universal:CreateSection("Visuals")
local ESP_Tog = UniversalSection:CreateToggle("Players ESP", function(arg)
	if _G.InfinityHub_Data.PlayerESP then

		_G.InfinityHub_Data.PlayerESP = false
		library:CoreNotification(tostring(info.Name),"Disabled Players ESP!")

	else

		_G.InfinityHub_Data.PlayerESP = true
		library:CoreNotification(tostring(info.Name),"Enabled Players ESP!")
	end
	
	if _G.InfinityHub_Data.PlayerESP then
		for i,v in pairs(Players:GetChildren()) do
			if v.ClassName == "Player" and v.Name ~= Player.Name then
				CreateESP(v)
			end
		end
	else
		for i, v in pairs(CoreGui:GetChildren()) do
			if string.sub(v.Name, -4) == '_ESP' then
				v:Destroy()
			end
		end
	end
end)

spawn(function()
	if _G.InfinityHub_Data.PlayerESP then
		library:CoreNotification(tostring(info.Name),"Enabled Players ESP!")
		ESP_Tog:UpdateToggle("Players ESP", true)
	end
end)

local Cham_Tog = UniversalSection:CreateToggle("Players Chams", function(arg)
	if _G.InfinityHub_Data.PlayerChams then

		_G.InfinityHub_Data.PlayerChams = false
		library:CoreNotification(tostring(info.Name),"Disabled Players Chams!")

	else

		_G.InfinityHub_Data.PlayerChams = true
		library:CoreNotification(tostring(info.Name),"Enabled Players Chams!")
	end
	
	if _G.InfinityHub_Data.PlayerChams then
		for i,v in pairs(Players:GetChildren()) do
			if v.ClassName == "Player" and v.Name ~= Player.Name then
				CreateCHMS(v)
			end
		end
	else
		for i,v in pairs(Players:GetChildren()) do
			for i, c in pairs(CoreGui:GetChildren()) do
				if c.Name == v.Name..'_CHMS' then
					c:Destroy()
				end
			end
		end
	end
end)

spawn(function()
	if _G.InfinityHub_Data.PlayerChams then
		library:CoreNotification(tostring(info.Name),"Enabled Players Chams!")
		Cham_Tog:UpdateToggle("Players Chams", true)
	end
end)

local Tracer_Tog = UniversalSection:CreateToggle("Players Tracers", function(arg)
	if _G.InfinityHub_Data.PlayerTracerESP then

		_G.InfinityHub_Data.PlayerTracerESP = false
		library:CoreNotification(tostring(info.Name),"Disabled Players Tracers!")

	else

		_G.InfinityHub_Data.PlayerTracerESP = true
		library:CoreNotification(tostring(info.Name),"Enabled Players Tracers!")
	end

	if _G.InfinityHub_Data.PlayerTracerESP then
		library:CoreNotification(tostring(info.Name),"Enabled Players Tracers!")
		CreateTracer()
	end
end)

spawn(function()
	if _G.InfinityHub_Data.PlayerTracerESP then
		library:CoreNotification(tostring(info.Name),"Enabled Players Tracers!")
		Tracer_Tog:UpdateToggle("Players Tracers", true)
	end
end)

local Box_Tog = UniversalSection:CreateToggle("Players Boxes", function(arg)
	if _G.InfinityHub_Data.PlayerBoxESP then

		_G.InfinityHub_Data.PlayerBoxESP = false
		library:CoreNotification(tostring(info.Name),"Disabled Players Boxes!")

	else

		_G.InfinityHub_Data.PlayerBoxESP = true
		library:CoreNotification(tostring(info.Name),"Enabled Players Boxes!")
	end

	if _G.InfinityHub_Data.PlayerBoxESP then
		CreateBox()
	end
end)

spawn(function()
	if _G.InfinityHub_Data.PlayerBoxESP then
		library:CoreNotification(tostring(info.Name),"Enabled Players Boxes!")
		Box_Tog:UpdateToggle("Players Boxes", true)
	end
end)

local materials = true
local smoothplastic = Enum.Material.SmoothPlastic
local objects = {}

function scan(object)
	local objectlist = object:GetChildren()
	for i = 1, #objectlist do
		if objectlist[i]:IsA('BasePart') then
			objects[objectlist[i]] = objectlist[i].Material
		end
		scan(objectlist[i])
	end
end

scan(workspace)

UniversalSection:CreateToggle("Remove Textures", function(arg)

	materials = not materials

	if materials then
		library:CoreNotification(tostring(info.Name),"Added Old Textures!")
		for i in pairs(objects) do
			i.Material = objects[i]
			i.CastShadow = true
		end
	else
		library:CoreNotification(tostring(info.Name),"Removed Textures!")
		for i in pairs(objects) do
			i.Material = smoothplastic
			i.CastShadow = false
		end
	end
end)

function x(v)
	if v then
		for _, v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') then
				v.LocalTransparencyModifier = 0.5
			end
		end
	else
		for _,v in pairs(workspace:GetDescendants()) do
			if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') then
				v.LocalTransparencyModifier = 0
			end
		end
	end
end

Xrays = false
UniversalSection:CreateToggle("Xrays", function(arg)
	if Xrays == false then
		Xrays = true
		
		x(Xrays)
		library:CoreNotification(tostring(info.Name),"Enabled Xrays!")

	elseif Xrays == true then
		Xrays = false
		
		x(Xrays)
		library:CoreNotification(tostring(info.Name),"Disabled Xrays!")
	end
end)

UniversalSection:CreateButton("UnLock Chat", function()
	library:CoreNotification(tostring(info.Name),"Chat UnLocked!")

	game.StarterGui:SetCore( "ChatMakeSystemMessage",{
		Text = "Welcome to the chat, player",
		Color = Color3.new(0, 225, 0),
		Font = Enum.Font.SourceSans,
		TextSize = 18
	})

	game.Players.LocalPlayer.PlayerGui.Chat.Frame.ChatChannelParentFrame.Visible = true
	game.Players.LocalPlayer.PlayerGui.Chat.Frame.ChatBarParentFrame.Position = UDim2.new(0, 0, 1, -42)
end)

EnabledResetButton = false
UniversalSection:CreateToggle("Reset Button", function(arg)
	EnabledResetButton = arg
	
	if EnabledResetButton then
		
		StarterGui:SetCore("ResetButtonCallback",true)
		library:CoreNotification(tostring(info.Name),"Enabled reset Button!")

	else

		StarterGui:SetCore("ResetButtonCallback",false)
		library:CoreNotification(tostring(info.Name),"Disabled reset Button!")
	end
end)

LockMouse = false
UniversalSection:CreateToggle("Un-Lock Mouse", function(arg)
	LockMouse = arg
	
	if LockMouse then
		
		library:LockMouse(true)
		library:CoreNotification(tostring(info.Name),"Mouse UnLocked!")

	else
		
		library:LockMouse(false)
		library:CoreNotification(tostring(info.Name),"Mouse Locked!")
	end
end)

local UniversalSection2 = Universal:CreateSection("Player")

Tp_Player = nil
UniversalSection2:CreateTextbox("Teleport to Player", true, nil, nil, function(arg)
	local GetPlayer = function(Player)
		for i, v in pairs(game.Players:GetPlayers()) do
			if string.find(v.Name, Player) then
				return v
			elseif v.Name:sub(1, Player:len()):lower() == Player:lower() then
				return v
			end
		end
	end

	local player = GetPlayer(arg)
	
	Tp_Player = player

	getRoot(game.Players.LocalPlayer.Character).CFrame = player.Character:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0,0,0)
end)

SpamTp = false
UniversalSection2:CreateToggle("Player Spam TP", function(arg)
	SpamTp = arg
	
	if SpamTp then
		library:CoreNotification(tostring(info.Name),"Enabled Spam Tp!")
	else
		library:CoreNotification(tostring(info.Name),"Disabled Spam Tp!")
	end
	
	while wait() do
		if SpamTp and Tp_Player then
			getRoot(game.Players.LocalPlayer.Character).CFrame = Tp_Player.Character:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0,0,0)
		end
	end
end)

FLYING = false
QEfly = true
flyspeed = 1

function sFLY()
	repeat wait() until Players.LocalPlayer and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
	repeat wait() until Mouse

	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end

	local T = getRoot(Players.LocalPlayer.Character)
	local CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
	local SPEED = 0

	local function FLY()
		FLYING = true
		local BG = Instance.new('BodyGyro')
		local BV = Instance.new('BodyVelocity')
		BG.P = 9e4
		BG.Parent = T
		BV.Parent = T
		BG.maxTorque = Vector3.new(9e9, 9e9, 9e9)
		BG.cframe = T.CFrame
		BV.velocity = Vector3.new(0, 0, 0)
		BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
		task.spawn(function()
			repeat wait()
				if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
					Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = true
				end
				if CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0 then
					SPEED = 50
				elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.Q + CONTROL.E ~= 0) and SPEED ~= 0 then
					SPEED = 0
				end
				if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.Q + CONTROL.E) ~= 0 then
					BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
					lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R}
				elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.Q + CONTROL.E) == 0 and SPEED ~= 0 then
					BV.velocity = ((workspace.CurrentCamera.CoordinateFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((workspace.CurrentCamera.CoordinateFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + CONTROL.Q + CONTROL.E) * 0.2, 0).p) - workspace.CurrentCamera.CoordinateFrame.p)) * SPEED
				else
					BV.velocity = Vector3.new(0, 0, 0)
				end
				BG.cframe = workspace.CurrentCamera.CoordinateFrame
			until not FLYING
			CONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			lCONTROL = {F = 0, B = 0, L = 0, R = 0, Q = 0, E = 0}
			SPEED = 0
			BG:Destroy()
			BV:Destroy()

			if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
				Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
			end
		end)
	end

	flyKeyDown = Mouse.KeyDown:Connect(function(KEY)
		if KEY:lower() == 'w' then
			CONTROL.F = (flyspeed)
		elseif KEY:lower() == 's' then
			CONTROL.B = - (flyspeed)
		elseif KEY:lower() == 'a' then
			CONTROL.L = - (flyspeed)
		elseif KEY:lower() == 'd' then 
			CONTROL.R = (flyspeed)
		elseif QEfly and KEY:lower() == 'e' then
			CONTROL.Q = (flyspeed)*2
		elseif QEfly and KEY:lower() == 'q' then
			CONTROL.E = -(flyspeed)*2
		end
		pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Track end)
	end)

	flyKeyUp = Mouse.KeyUp:Connect(function(KEY)
		if KEY:lower() == 'w' then
			CONTROL.F = 0
		elseif KEY:lower() == 's' then
			CONTROL.B = 0
		elseif KEY:lower() == 'a' then
			CONTROL.L = 0
		elseif KEY:lower() == 'd' then
			CONTROL.R = 0
		elseif KEY:lower() == 'e' then
			CONTROL.Q = 0
		elseif KEY:lower() == 'q' then
			CONTROL.E = 0
		end
	end)
	FLY()
end

function NOFLY()
	FLYING = false

	if flyKeyDown or flyKeyUp then flyKeyDown:Disconnect() flyKeyUp:Disconnect() end
	if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') then
		Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').PlatformStand = false
	end
	pcall(function() workspace.CurrentCamera.CameraType = Enum.CameraType.Custom end)
end

UniversalSection2:CreateToggle("Fly Script", function(arg)
	FLYING = arg
	if FLYING then
		
		NOFLY()

		wait()

		sFLY()

		library:CoreNotification(tostring(info.Name),"Enabled Fly Script!")

	else

		NOFLY()
		library:CoreNotification(tostring(info.Name),"Disabled Fly Script!")
	end
end)

UniversalSection2:CreateTextbox("Fly Speed", false, 1, 10,function(arg)
	flyspeed = arg:gsub("%D",""):sub(0,5)

	getRoot(game.Players.LocalPlayer.Character).BodyVelocity.velocity = Vector3.new(0, arg:gsub("%D",""):sub(0,5), 0)
end)

local flinging = false
local flingtbl = {}

function FLING()
	local rootpart = getRoot(game.Players.LocalPlayer.Character)

	if not rootpart then return end

	flingtbl.OldVelocity = rootpart.Velocity

	local bv = Instance.new("BodyAngularVelocity")

	flingtbl.bv = bv

	bv.MaxTorque = Vector3.new(1, 1, 1) * math.huge
	bv.P = math.huge
	bv.AngularVelocity = Vector3.new(0, 9e5, 0)
	bv.Parent = rootpart

	local Char = game.Players.LocalPlayer.Character:GetChildren()

	for i, v in next, Char do
		if v:IsA("BasePart") then
			v.CanCollide = false
			v.Massless = true
			v.Velocity = Vector3.new(0, 0, 0)
		end
	end

	flingtbl.Noclipping2 = game:GetService("RunService").Stepped:Connect(function()
		for i, v in next, Char do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end
	end)
end

function UNFLING()
	local rootpart = getRoot(game.Players.LocalPlayer.Character)

	if not rootpart then return end
	flingtbl.OldPos = rootpart.CFrame

	local Char = game.Players.LocalPlayer.Character:GetChildren()

	if flingtbl.bv ~= nil then
		flingtbl.bv:Destroy()
		flingtbl.bv = nil
	end

	if flingtbl.Noclipping2 ~= nil then
		flingtbl.Noclipping2:Disconnect()
		flingtbl.Noclipping2 = nil
	end

	for i, v in next, Char do
		if v:IsA("BasePart") then
			v.CanCollide = true
			v.Massless = false
		end
	end

	flingtbl.isRunning = game:GetService("RunService").Stepped:Connect(function()
		if flingtbl.OldPos ~= nil then
			rootpart.CFrame = flingtbl.OldPos
		end
		if flingtbl.OldVelocity ~= nil then
			rootpart.Velocity = flingtbl.OldVelocity
		end
	end)

	wait(2)

	rootpart.Anchored = true

	if flingtbl.isRunning ~= nil then
		flingtbl.isRunning:Disconnect()
		flingtbl.isRunning = nil
	end
	rootpart.Anchored = false

	if flingtbl.OldVelocity ~= nil then
		rootpart.Velocity = flingtbl.OldVelocity
	end

	if flingtbl.OldPos ~= nil then
		rootpart.CFrame = flingtbl.OldPos
	end

	wait()

	flingtbl.OldVelocity = nil
	flingtbl.OldPos = nil
	flinging = false
end

UniversalSection2:CreateToggle("Fling", function(arg)
	flinging = false
	
	if flinging then

		FLING()
		library:CoreNotification(tostring(info.Name),"Enabled Fling Script!")

	else

		UNFLING()
		library:CoreNotification(tostring(info.Name),"Disabled Fling Script!")
	end
end)

InfiniteJump = false
UniversalSection2:CreateToggle("Inf Jump", function(arg)
	InfiniteJump = arg
	
	if InfiniteJump then

		library:CoreNotification(tostring(info.Name),"Enabled Infinite Jump Script!")
		
	else
		
		library:CoreNotification(tostring(info.Name),"Disabled Infinite Jump Script!")
	end

	game:GetService("UserInputService").JumpRequest:connect(function()
		if InfiniteJump then
			game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
		end
	end)
end)

Noclip = false
UniversalSection2:CreateToggle("NoClip", function(arg)
	if Noclip == false then
		Noclip = true

		library:CoreNotification(tostring(info.Name),"Enabled Noclip Script!")

	elseif Noclip == true then
		Noclip = false

		library:CoreNotification(tostring(info.Name),"Disabled Noclip Script!")
	end

	RS.Stepped:Connect(function()
		for i, v in next, game.Players.LocalPlayer.Character:GetChildren() do
			if v:IsA("BasePart") and Noclip == true then
				v.CanCollide = false
			end
		end
	end)
end)

AntiAFK = false
UniversalSection2:CreateToggle("Anti-AFK", function(arg)
	if AntiAFK == false then
		AntiAFK = true
		
		AFKStatusLabel:UpdateLabel("Status: On")
		library:CoreNotification(tostring(info.Name),"Enabled AntiAFK Script!")

	elseif AntiAFK == true then
		AntiAFK = false
		
		AFKStatusLabel:UpdateLabel("Status: off")
		library:CoreNotification(tostring(info.Name),"Disabled AntiAFK Script!")
	end
	
	Player.Idled:connect(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
		
		AFKStatusLabel:UpdateLabel("You went idle and ROBLOX tried to kick you but we reflected it!")
		
		wait(1)
		
		AFKStatusLabel:UpdateLabel("Status: Script Re-Enabled")
	end)
end)

AFKStatusLabel = UniversalSection2:CreateLabel("Status: off")

local UniversalSection3 = Universal:CreateSection("Camera")

NoclipCamera = false
UniversalSection3:CreateToggle("NoClip Camera", function(arg)
	if NoclipCamera == false then
		NoclipCamera = true
		library:CoreNotification(tostring(info.Name),"Enabled Noclip Camera!")

	elseif NoclipCamera == true then
		NoclipCamera = false
		library:CoreNotification(tostring(info.Name),"Disabled Noclip Camera!")
	end


	local sc = (debug and debug.setconstant) or setconstant
	local gc = (debug and debug.getconstants) or getconstants

	if not sc or not getgc or not gc then
		return
	end

	local pop = game.Players.LocalPlayer.PlayerScripts.PlayerModule.CameraModule.ZoomController.Popper
	for _, v in pairs(getgc()) do
		if type(v) == 'function' and getfenv(v).script == pop then
			for i, v1 in pairs(gc(v)) do
				if tonumber(v1) == .25 then
					sc(v, i, 0)
				elseif tonumber(v1) == 0 then
					sc(v, i, .25)
				end
			end
		end
	end
end)

local cameraPos = Vector3.new()
local cameraRot = Vector2.new()

local velSpring = Spring.new(5, Vector3.new())
local panSpring = Spring.new(5, Vector2.new())

fcRunning = false

local function StepFreecam(dt)
	local vel = velSpring:Update(dt, Input.Vel(dt))
	local pan = panSpring:Update(dt, Input.Pan(dt))

	local zoomFactor = math.sqrt(math.tan(math.rad(70/2))/math.tan(math.rad(cameraFov/2)))

	cameraRot = cameraRot + pan*Vector2.new(0.75, 1)*8*(dt/zoomFactor)
	cameraRot = Vector2.new(math.clamp(cameraRot.x, -math.rad(90), math.rad(90)), cameraRot.y%(2*math.pi))

	local cameraCFrame = CFrame.new(cameraPos)*CFrame.fromOrientation(cameraRot.x, cameraRot.y, 0)*CFrame.new(vel*Vector3.new(1, 1, 1)*64*dt)
	cameraPos = cameraCFrame.p

	Camera.CFrame = cameraCFrame
	Camera.Focus = cameraCFrame*CFrame.new(0, 0, -GetFocusDistance(cameraCFrame))
	Camera.FieldOfView = cameraFov
end

function StartFreecam(pos)
	if fcRunning then
		StopFreecam()
	end

	local cameraCFrame = Camera.CFrame
	if pos then
		cameraCFrame = pos
	end
	cameraRot = Vector2.new()
	cameraPos = cameraCFrame.p
	cameraFov = Camera.FieldOfView

	velSpring:Reset(Vector3.new())
	panSpring:Reset(Vector2.new())

	PlayerState.Push()
	game:GetService("RunService"):BindToRenderStep("Freecam", Enum.RenderPriority.Camera.Value, StepFreecam)
	Input.StartCapture()
	fcRunning = true
end

function StopFreecam()
	if not fcRunning then return end
	Input.StopCapture()
	game:GetService("RunService"):UnbindFromRenderStep("Freecam")
	PlayerState.Pop()
	workspace.Camera.FieldOfView = 70
	fcRunning = false
end


UniversalSection3:CreateToggle("Free Camera", function(args)
	if fcRunning then

		StopFreecam()
		library:CoreNotification(tostring(info.Name),"Enabled Free Camera!")

	else

		StartFreecam()
		library:CoreNotification(tostring(info.Name),"Disabled Free Camera!")
	end
end)

UniversalSection3:CreateTextbox("Spectate Player", true, nil, nil, function(arg)
	local GetPlayer = function(Player)
		for i, v in pairs(game.Players:GetPlayers()) do
			if string.find(v.Name, Player) then
				return v
			elseif v.Name:sub(1, Player:len()):lower() == Player:lower() then
				return v
			end
		end
	end

	local player = GetPlayer(arg)

	Camera.CameraSubject = player.Character:FindFirstChild("Humanoid")
end)

UniversalSection3:CreateButton("Stop spectate player", function()
	library:CoreNotification(tostring(info.Name),"Stoped spectating player!","Normal")

	Camera.CameraSubject = game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
end)

local UniversalSection4 = Universal:CreateSection("Mouse")


ClickTP = false
UniversalSection4:CreateToggle("Click to TP", function(arg)
	if ClickTP == false then
		ClickTP = true

		library:CoreNotification(tostring(info.Name),"Enabled Click to TP!")

	elseif ClickTP == true then
		ClickTP = false

		library:CoreNotification(tostring(info.Name),"Disabled Click to TP!")
	end
end)

ClickDel = false
UniversalSection4:CreateToggle("Click to Delete", function(arg)
	if ClickDel == false then
		ClickDel = true

		library:CoreNotification(tostring(info.Name),"Enabled Click to Delete!")

	elseif ClickDel == true then
		ClickDel = false

		library:CoreNotification(tostring(info.Name),"Disabled Click to Delete!")
	end
end)

local function clicktpFunc()
	pcall(function()
		if Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid') and Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').SeatPart then
			Players.LocalPlayer.Character:FindFirstChildOfClass('Humanoid').Sit = false
			wait(.1)
		end
		getRoot(Players.LocalPlayer.Character).CFrame = Mouse.Hit + Vector3.new(0,8,0)
	end)
end


Mouse.Button1Down:Connect(function()
	if ClickTP then
		if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) and Players.LocalPlayer.Character then
			clicktpFunc()
		elseif UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and Players.LocalPlayer.Character then
			clicktpFunc()
		end
	elseif ClickDel then
		if  UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
			pcall(function() Mouse.Target:Destroy() end)
		elseif UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			pcall(function() Mouse.Target:Destroy() end)
		end
	end
end)

local UniversalSection5 = Universal:CreateSection("Anti-Exploits")

Antikick = false
UniversalSection5:CreateToggle("Client Anti-kick", function(arg)
	if Antikick == false then
		Antikick = true

		library:CoreNotification(tostring(info.Name),"Enabled Anti-kick Script!")

	elseif Antikick == true then
		Antikick = false

		library:CoreNotification(tostring(info.Name),"Disabled Anti-kick Script!")
	end

	local mt = getrawmetatable(game)
	local old = mt.__namecall
	local protect = newcclosure or protect_function

	if not protect then
		library:CoreNotification("Incompatible Exploit Warning", "Your exploit does not support protection against stack trace errors, resulting to fallback function")
		protect = function(f) return f end
	end

	setreadonly(mt, false)
	mt.__namecall = protect(function(self, ...)
		if Antikick == false then return end

		local method = getnamecallmethod()
		if method == "Kick" then
			wait(9e9)
			return
		end
		return old(self, ...)
	end)

	if Antikick == true then
		hookfunction(Players.LocalPlayer.Kick,protect(function() wait(9e9) end))
	end

	library:CoreNotification("Client Antikick","Client anti kick is now active (only effective on localscript kick)")
end)

AntiTP = false
UniversalSection5:CreateToggle("Client Anti-Teleport", function(arg)
	if AntiTP == false then
		AntiTP = true
		
		library:CoreNotification(tostring(info.Name),"Enabled Anti-kick Teleport!")

	elseif AntiTP == true then
		AntiTP = false

		library:CoreNotification(tostring(info.Name),"Disabled Anti-kick Teleport!")
	end

	local TeleportService, TP, tptpi = game:GetService("TeleportService")

	if AntiTP == true then
		TP = hookfunction(TeleportService.Teleport, function(id, ...)
			if allow_rj and id == game.Placeid then
				return tp(id, ...)
			end
			return wait(9e9)
		end)

		tptpi = hookfunction(TeleportService.TeleportToPlaceInstance, function(id, server, ...)
			if allow_rj and id == game.Placeid and server == game.JobId then
				return TP(id, server, ...)
			end
			return wait(9e9)
		end)

		library:CoreNotification("Client AntiTP","Client anti teleport is now active (only effective on localscript teleport)")
	else
		return
	end
end)

ServerHop = false
UniversalSection5:CreateToggle("Server Hop", function(arg)
	if ServerHop == false then
		ServerHop = true

		library:CoreNotification(tostring(info.Name),"Enabled Server Hop!")
	elseif ServerHop == true then
		ServerHop = false

		library:CoreNotification(tostring(info.Name),"Enabled Server Hop!")
	end
	
	local PlaceID = game.PlaceId
	local AllIDs = {}
	
	local foundAnything = ""
	
	local actualHour = os.date("!*t").hour
	local Deleted = false
	
	local File = pcall(function()
		AllIDs = game:GetService('HttpService'):JSONDecode(readfile("NotSameServers.json"))
	end)
	
	if not File then
		table.insert(AllIDs, actualHour)
		writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
	end
	
	local function TPReturner()
		local Site;
		if foundAnything == "" then
			Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100'))
		else
			Site = game.HttpService:JSONDecode(game:HttpGet('https://games.roblox.com/v1/games/' .. PlaceID .. '/servers/Public?sortOrder=Asc&limit=100&cursor=' .. foundAnything))
		end
		local ID = ""
		if Site.nextPageCursor and Site.nextPageCursor ~= "null" and Site.nextPageCursor ~= nil then
			foundAnything = Site.nextPageCursor
		end
		local num = 0;
		for i,v in pairs(Site.data) do
			local Possible = true
			ID = tostring(v.id)
			if tonumber(v.maxPlayers) > tonumber(v.playing) then
				for _,Existing in pairs(AllIDs) do
					if num ~= 0 then
						if ID == tostring(Existing) then
							Possible = false
						end
					else
						if tonumber(actualHour) ~= tonumber(Existing) then
							local delFile = pcall(function()
								delfile("NotSameServers.json")
								AllIDs = {}
								table.insert(AllIDs, actualHour)
							end)
						end
					end
					num = num + 1
				end
				if Possible == true then
					table.insert(AllIDs, ID)
					wait()
					pcall(function()
						writefile("NotSameServers.json", game:GetService('HttpService'):JSONEncode(AllIDs))
						wait()
						game:GetService("TeleportService"):TeleportToPlaceInstance(PlaceID, ID, game.Players.LocalPlayer)
					end)
					wait(4)
				end
			end
		end
	end

	local function Teleport()
		while wait() do
			pcall(function()
				TPReturner()
				if foundAnything ~= "" then
					TPReturner()
				end
			end)
		end
	end
	
	while ServerHop do	
		if #game.Players:GetPlayers() == 1 then
			wait() Teleport()
		end
	end
end)

UniversalSection5:CreateTextbox("Join Server (Put Server JobId)", true, nil, nil, function(arg)
	game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, arg, Players.LocalPlayer)
end)

local Character = Window:CreatePage("Character", 6887023120, 5)

local CharacterSection = Character:CreateSection("Humanoid")

CharacterSection:CreateSlider("Set WalkSpeed",16, 0, 1000, function(arg)
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = arg
end)

CharacterSection:CreateSlider("Set JumpPower",50, 0, 1000, function(arg)
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").JumpPower = arg
end)

CharacterSection:CreateSlider("Set Health",100, 0, 1000, function(arg)
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").MaxHealth = arg
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").Health = arg
end)

CharacterSection:CreateButton("Reset WalkSpeed & JumpPower", function()
	library:CoreNotification(tostring(info.Name),"Reseted WalkSpeed & JumpPower!")

	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").WalkSpeed = 16
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").JumpPower = 50
end)

CharacterSection:CreateButton("Reset Health", function()
	library:CoreNotification(tostring(info.Name),"Reseted Health!")

	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").MaxHealth  = 100
	game.Players.LocalPlayer.Character:WaitForChild("Humanoid").MaxHealth  = 100
end)

local CharacterSection2 = Character:CreateSection("Animations")

local Animate = game.Players.LocalPlayer.Character:FindFirstChild("Animate")
CharacterSection2:CreateButton("Astronaut Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=891621366"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=891633237"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=891667138"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=891636393"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=891627522"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=891609353"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=891617961"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Bubbly Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=910004836"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=910009958"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=910034870"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=910025107"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=910016857"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=910001910"
	Animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=910030921"
	Animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=910028158"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Cartoony Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=742637544"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=742638445"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=742640026"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=742638842"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=742637942"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=742636889"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=742637151"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Elder Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=845397899"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=845400520"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=845403856"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=845386501"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=845398858"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=845392038"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=845396048"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Knight Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=657595757"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=657568135"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=657552124"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=657564596"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=658409194"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=658360781"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=657600338"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Levitation Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=616006778"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=616008087"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616013216"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616010382"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616008936"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=616003713"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616005863"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Mage Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=707742142"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=707855907"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=707897309"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=707861613"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=707853694"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=707826056"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=707829716"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Ninja Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=656117400"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=656118341"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=656121766"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=656118852"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=656117878"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=656114359"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=656115606"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Pirate Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=750781874"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=750782770"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=750785693"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=750783738"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=750782230"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=750779899"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=750780242"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Robot Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=616088211"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=616089559"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616095330"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616091570"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616090535"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=616086039"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616087089"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Stylish Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=616136790"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=616138447"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616146177"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616140816"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616139451"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=616133594"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616134815"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("SuperHero Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=616111295"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=616113536"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616122287"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616117076"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616115533"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=616104706"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616108001"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Toy Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=782841498"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=782845736"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=782843345"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=782842708"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=782847020"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=782843869"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=782846423"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Vampire Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1083445855"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1083450166"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1083473930"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1083462077"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1083455352"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1083439238"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1083443587"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Werewolf Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1083195517"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1083214717"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1083178339"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1083216690"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1083218792"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1083182000"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1083189019"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Zombie Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=616158929"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=616160636"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616168032"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616163682"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616161997"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=616156119"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616157476"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("Anthro Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=2510196951"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=2510197257"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=2510202577"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=2510198475"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=2510197830"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=2510192778"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=2510195892"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection2:CreateButton("None Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=0"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=0"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=0"
	Animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=0"
	Animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=0"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

local CharacterSection3 = Character:CreateSection("Special Animations")

CharacterSection3:CreateButton("Patrol Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1149612882"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1150842221"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1151231493"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1150967949"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1148811837"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1148811837"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1148863382"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection3:CreateButton("Confident Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1069977950"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1069987858"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1070017263"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1070001516"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1069984524"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1069946257"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1069973677"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection3:CreateButton("PopStar Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1212900985"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1150842221"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1212980338"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1212980348"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1212954642"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1213044953"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1212900995"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection3:CreateButton("CowBoy Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1014390418"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1014398616"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1014421541"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1014401683"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1014394726"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1014380606"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1014384571"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection3:CreateButton("Ghost Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=616006778"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=616008087"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=616013216"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=616013216"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=616008936"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=616005863"
	Animate.swimidle.SwimIdle.AnimationId = "http://www.roblox.com/asset/?id=616012453"
	Animate.swim.Swim.AnimationId = "http://www.roblox.com/asset/?id=616011509"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection3:CreateButton("Sneaky Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=1132473842"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=1132477671"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=1132510133"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=1132494274"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=1132489853"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=1132461372"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=1132469004"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

CharacterSection3:CreateButton("Princess Anim", function()
	Animate.idle.Animation1.AnimationId = "http://www.roblox.com/asset/?id=941003647"
	Animate.idle.Animation2.AnimationId = "http://www.roblox.com/asset/?id=941013098"
	Animate.walk.WalkAnim.AnimationId = "http://www.roblox.com/asset/?id=941028902"
	Animate.run.RunAnim.AnimationId = "http://www.roblox.com/asset/?id=941015281"
	Animate.jump.JumpAnim.AnimationId = "http://www.roblox.com/asset/?id=941008832"
	Animate.climb.ClimbAnim.AnimationId = "http://www.roblox.com/asset/?id=940996062"
	Animate.fall.FallAnim.AnimationId = "http://www.roblox.com/asset/?id=941000007"
	game.Players.LocalPlayer.Character.Humanoid.Jump = true
end)

local Configuration = Window:CreatePage("Configure", 6860899302, 6)

local ConfigurationSection = Configuration:CreateSection("Configuration")

ConfigurationSection:CreateBind("Close/Open UI KeyBind", Enum.KeyCode.LeftControl , function(arg)
	_G.InfinityHub_Data.CloseBind = arg
	library:ToggleUI()
end)

ConfigurationSection:Colorpicker("Slect a color", _G.InfinityHub_Data.PresetColor)

ConfigurationSection:CreateToggle("UI Rainbow effect", function(arg)
	_G.InfinityHub_Data.UIRaimbowEffect = not _G.InfinityHub_Data.UIRaimbowEffect
end)

ConfigurationSection:CreateToggle("Show UI Notifications", function(arg)
	_G.InfinityHub_Data.ShowNotifications = not _G.InfinityHub_Data.ShowNotifications
end)

ConfigurationSection:CreateButton("Kill Roblox Process", function()
	game:Shutdown()
end)

ConfigurationSection:CreateButton("Destroy Infinity Hub", function()
	library:DestroyUI()
end)

ConfigurationSection:CreateButton("Save Settings", function()
	library:SaveUISettings()
end)

ConfigurationSection:CreateButton("Erase Data", function()
	library:Notify("NOTIFICATION", "Are you sure you want to delete all user interface data?", "fuction", function(arg)
		if arg == true then
			if isfile and delfile then
				if isfile("InfinityHub\\InfinityHubData.json") then
					delfile("InfinityHub\\InfinityHubData.json")
					
					library:Notify("NOTIFICATION", "data deleted succesfully!", "Normal")
				end
			end
		end
	end)
end)

local Credits = Window:CreatePage("Credits", 6883783410, 7)

local CreditsSection = Credits:CreateSection("Lead Developer")

CreditsSection:CreateButton("0nlyyAlxn - Lead Developer              (Alxn<3#5429)", function()
	if setclipboard then
		setclipboard('Alxn<3#5429')
		library:CoreNotification('Discord DevTag', 'Copied to clipboard!\nAlxn<3#5429')
	else
		library:CoreNotification('Discord DevTag', 'Alxn<3#5429')
	end
end)

local CreditsSection2 = Credits:CreateSection("Develpoers")

CreditsSection2:CreateButton("02_Vale7u7 - Scripter              (•Vxlenn•💋✨#3628)", function()
	if setclipboard then
		setclipboard('•Vxlenn•💋✨#3628')
		library:CoreNotification('Discord DevTag', 'Copied to clipboard!\n•Vxlenn•💋✨#3628')
	else
		library:CoreNotification('Discord DevTag', '•Vxlenn•💋✨#3628')
	end
end)

CreditsSection2:CreateButton("FG Icey - Scripter              (iceyW#7089)", function()

	if setclipboard then
		setclipboard('iceyW#7089')
		library:CoreNotification('Discord DevTag', 'Copied to clipboard!\niceyW#7089')
	else
		library:CoreNotification('Discord DevTag', 'iceyW#7089')
	end
end)

CreditsSection2:CreateButton("JeyLex - BETA TESTER              (JayLex💢#6989)", function()

	if setclipboard then
		setclipboard('JayLex💢#6989')
		library:CoreNotification('Discord DevTag', 'Copied to clipboard!\nJayLex💢#6989')
	else
		library:CoreNotification('Discord DevTag', 'iceyW#7089')
	end
end)

local CreditsSection3 = Credits:CreateSection("Others")

CreditsSection3:CreateButton("Ethanoj1 - UI inspiration              (£thanoj1#3304)")
CreditsSection3:CreateButton("Venyx - UI inspiration")

local CreditsSection4 = Credits:CreateSection("Discord Servers")

CreditsSection4:CreateButton("Offcial Server1: Aure Ware", function()
	if setclipboard then
		setclipboard('https://discord.com/invite/24kYCDh6wd')
		library:CoreNotification('Discord Invite', 'Copied to clipboard!\ndiscord.gg/24kYCDh6wd')
	else
		library:CoreNotification('Discord Invite', 'discord.gg/24kYCDh6wd')
	end

	local req = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request

	if req then
		req({
			Url = 'http://127.0.0.1:6463/rpc?v=1',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				Origin = 'https://discord.com'
			},
			Body = HttpService:JSONEncode({
				cmd = 'INVITE_BROWSER',
				nonce = HttpService:GenerateGUID(false),
				args = {code = '24kYCDh6wd'}
			})
		})
	end
end)

CreditsSection4:CreateButton("Offcial Server2: The Lofi Room 11:11", function()
	if setclipboard then
		setclipboard('https://discord.com/invite/eWXxNYZd5p')
		library:CoreNotification('Discord Invite', 'Copied to clipboard!\ndiscord.gg/eWXxNYZd5p')
	else
		library:CoreNotification('Discord Invite', 'discord.gg/eWXxNYZd5p')
	end

	local req = syn and syn.request or http and http.request or http_request or fluxus and fluxus.request or getgenv().request or request

	if req then
		req({
			Url = 'http://127.0.0.1:6463/rpc?v=1',
			Method = 'POST',
			Headers = {
				['Content-Type'] = 'application/json',
				Origin = 'https://discord.com'
			},
			Body = HttpService:JSONEncode({
				cmd = 'INVITE_BROWSER',
				nonce = HttpService:GenerateGUID(false),
				args = {code = 'eWXxNYZd5p'}
			})
		})
	end
end)

function TRNE_Scripts()
	
	local function ChangeLighting()
		if workspace:FindFirstChild("Day").Value == false then
			Lighting.ColorShift_Bottom = Color3.fromRGB(0, 0, 0)
			Lighting.ColorShift_Top = Color3.fromRGB(0, 0, 0)
			Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
			Lighting.Ambient = Color3.fromRGB(50, 50, 50)

			Lighting.Atmosphere.Density = 0.45
			Lighting.Brightness = 3	
			Lighting.ClockTime = 14
		end
	end

	local TPinProgress = false
	local TPtoFlareGunEnabled = false

	local function TPToFlareGun()
		for i,v in pairs(_Workspace_:GetChildren()) do
			if v:IsA("Tool") and v.Name == "FlareGun" then
				if TPinProgress == false then
					TPinProgress = true

					local OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame

					getRoot(game.Players.LocalPlayer.Character).CFrame = _Workspace_:FindFirstChild("FlareGun"):WaitForChild("Handle").CFrame
					wait(1)
					getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos

					wait(1)

					TPinProgress = false
				end
			end	
		end
	end

	local function MakeESP(Parent, Text, Color)
		local ESP = Instance.new("BillboardGui")
		local TextLabel = Instance.new("TextLabel", ESP)

		ESP.Name = "ESP"
		ESP.Parent = Parent
		ESP.AlwaysOnTop = true
		ESP.LightInfluence = 1
		ESP.Size = UDim2.new(0, 50, 0, 50)
		ESP.StudsOffset = Vector3.new(0, 2, 0)

		TextLabel.BackgroundColor3 = Color3.new(1, 1, 1)
		TextLabel.Font = Enum.Font.SourceSansLight
		TextLabel.BackgroundTransparency = 1
		TextLabel.Size = UDim2.new(1, 0, 1, 0)
		TextLabel.Text = Text
		TextLabel.TextColor3 = Color
		TextLabel.TextScaled = true
		
		local Highlight = Instance.new("Highlight")
		
		Highlight.FillTransparency = 1
		Highlight.OutlineColor = Color
		
		Highlight.Adornee = Parent
		Highlight.Parent = Parent		
	end

	local function lookDown()
		workspace.Camera.CFrame = CFrame.new(264.744202, 44.9857788, 19.0272675, 0.917633414, -0.391390145, 0.0690128133, 0, 0.173648611, 0.984807611, -0.397428036, -0.903692365, 0.159345)
	end
	
	local OldPos = nil
	
	local GameStuff = Window:CreatePage("TR:NE", 4621599120, 3)

	---------| Player |--------
	
	local GameStuffSection = GameStuff:CreateSection("Player")
	
	GameStuffSection:CreateButton("Unlock Chat", function()
		library:CoreNotification(tostring(info.Name),"Chat UnLocked!")

		game.StarterGui:SetCore( "ChatMakeSystemMessage",{
			Text = "Welcome to the chat, player",
			Color = Color3.new(0, 225, 0),
			Font = Enum.Font.SourceSans,
			TextSize = 18
		})

		game.Players.LocalPlayer.PlayerGui.Chat.Frame.ChatChannelParentFrame.Visible = true
		game.Players.LocalPlayer.PlayerGui.Chat.Frame.ChatBarParentFrame.Position = UDim2.new(0, 0, 1, -42)
	end)

	GameStuffSection:CreateButton("Remove FallDamage", function()
		library:CoreNotification(tostring(info.Name),"Removed FallDamage Script!")

		game.PLayers.LocalPlayer.Character:FindFirstChild("FallDamage"):Destroy()
	end)

	GameStuffSection:CreateButton("Remove PowerDamage", function()
		library:CoreNotification(tostring(info.Name),"Removed PowerDamage Script!")

		game.Workspace.LocationsFolder.PowerStation.PowerDamage:Destroy()
	end)

	GameStuffSection:CreateButton("Remove Crawling", function()
		library:CoreNotification(tostring(info.Name),"Removed Crawling Script!")

		game.Players.LocalPlayer.Character.CharValues.Crawling:Destroy()
	end)
	
	---------| Features |--------
	
	local GameStuffSection2 = GameStuff:CreateSection("Features")
	
	if _Workspace_:FindFirstChild("GameTimer") and _Workspace_:FindFirstChild("PowerTimer") then
		local GameTimerBtn = GameStuffSection2:CreateButton("GameTimer: ".._Workspace_:FindFirstChild("GameTimer").Value)
		local PowerTimerBtn = GameStuffSection2:CreateButton("PowerTimer: ".._Workspace_:FindFirstChild("PowerTimer").Value)
		
		
		RS.RenderStepped:Connect(function()
			GameTimerBtn:UpdateButton("GameTimer: ".._Workspace_:FindFirstChild("GameTimer").Value)
			PowerTimerBtn:UpdateButton("PowerTimer: ".._Workspace_:FindFirstChild("PowerTimer").Value)
		end)
	end
	
	if _Workspace_:FindFirstChild("The_Rake") and _Workspace_:FindFirstChild("The_Rake"):FindFirstChildOfClass("Humanoid") then
		local RakeHealthBtn = GameStuffSection2:CreateButton("Rake Health: ".._Workspace_:FindFirstChild("The_Rake"):FindFirstChildOfClass("Humanoid").Health)
		
		RS.RenderStepped:Connect(function()
			for i,v in pairs(game.Workspace:GetChildren()) do
				if string.find(v.Name, "The_Rake") then
					if v:FindFirstChildOfClass("Humanoid") ~= nil then
						RakeHealthBtn:UpdateButton("Rake Health: "..v:FindFirstChildOfClass("Humanoid").Health)
					end				
				end
			end
		end)
	end

	local InfStamina = false
	GameStuffSection2:CreateToggle("Infinite Stamina", function(arg)
		if InfStamina == false then
			InfStamina = true
			library:CoreNotification(tostring(info.Name),"Enabled Infinite Stamina Script!")

		elseif InfStamina == true then
			InfStamina = false
			library:CoreNotification(tostring(info.Name),"Disabled Infinite Stamina Script!")
		end
		
		while wait() do
			if InfStamina == true then
				game.Players.LocalPlayer.Character.CharValues.StaminaPercentValue.Value = 100
			end
		end
	end)

	local AutoChangeLighting = false
	GameStuffSection2:CreateToggle("Always Day", function(arg)
		if AutoChangeLighting == false then
			AutoChangeLighting = true
			library:CoreNotification(tostring(info.Name),"Enabled Auto Make Day Script!")

		elseif AutoChangeLighting == true then
			AutoChangeLighting = false
			library:CoreNotification(tostring(info.Name),"Disabled Auto Make Day Script!")
		end

		ChangeLighting()

		Lighting.Changed:Connect(function()
			if AutoChangeLighting == true then
				ChangeLighting()
			end
		end)
	end)

	local AutoDisableHourEffects = false
	GameStuffSection2:CreateToggle("Hour Effects", function(arg)
		if AutoDisableHourEffects == false then
			AutoDisableHourEffects = true
			library:CoreNotification(tostring(info.Name),"Disabled Hour Effects!")

		elseif AutoDisableHourEffects == true then
			AutoDisableHourEffects = false
			library:CoreNotification(tostring(info.Name),"Enabled Hour Effects!")
		end


		pcall(function()
			if AutoDisableHourEffects == true then
				Lighting:FindFirstChild("HourCC").Enabled = false
				PlayerGui:FindFirstChild("HoursGui").BH_VignetteImage.Visible = false
			end
		end)

		Lighting:FindFirstChild("HourCC").Changed:Connect(function()
			pcall(function()
				if AutoDisableHourEffects == true then
					Lighting:FindFirstChild("HourCC").Enabled = false
					PlayerGui:FindFirstChild("HoursGui").BH_VignetteImage.Visible = false
				end
			end)
		end)

		pcall(function()
			PlayerGui:FindFirstChild("HoursGui").BH_VignetteImage.Changed:Connect(function()
				if AutoDisableHourEffects == true then
					PlayerGui:FindFirstChild("HoursGui").BH_VignetteImage.Visible = false
				end
			end)
		end)

		pcall(function()
			if AutoDisableHourEffects == false then
				Lighting:FindFirstChild("HourCC").Enabled = true
				PlayerGui:FindFirstChild("HoursGui").BH_VignetteImage.Visible = true
			end
		end)
	end)

	local AutoKillRake = false
	GameStuffSection2:CreateButton("Bring RakOOF", function()
		pcall(function()
			for i,v in pairs(game.Workspace:GetChildren()) do
				if v.Name == 'The_Rake' then
					if v:FindFirstChild("HumanoidRootPart") ~= nil and v:FindFirstChild("NPC").Health > 0 then

						v:FindFirstChild("HumanoidRootPart").Anchored = true

						v:FindFirstChild("HumanoidRootPart").CFrame = getRoot(game.Players.LocalPlayer.Character).CFrame * CFrame.new(0,0,-5)
						library:CoreNotification(tostring(info.Name),"RakeOOF teleported to your current Position")
					end
				end
			end
		end)
	end)

	pcall(function()
		workspace:FindFirstChild("Day").Changed:Connect(function()
			if workspace:FindFirstChild("Day").Value == false then
				for _,v in pairs(game.Workspace:GetDescendants()) do
					if string.find(v.Name, "The_Rake") and v:FindFirstChild("HumanoidRootPart") and v:FindFirstChild("HumanoidRootPart").Anchored == true then
						v:FindFirstChild("HumanoidRootPart").Anchored = false

						library:CoreNotification(tostring(info.Name),"Day BoolValue Changed to: "..workspace:FindFirstChild("Day").Value..", RakeOOF UnAnchored")
					end
				end
			end
		end)
	end)

	GameStuffSection2:CreateButton("Fix Power Station", function()
		if game:GetService("Workspace").PowerTimer.Value <= 0 then

			local OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
			library:CoreNotification("Attempting to fix Power Station")

			lookDown()

			getRoot(game.Players.LocalPlayer.Character).CFrame = game:GetService("Workspace").LocationsFolder.PowerStation.ControlButtons.Buttons.InteractPart.CFrame
			task.wait(0.3)

			fireproximityprompt(game:GetService("Workspace").LocationsFolder.PowerStation.ControlButtons.Buttons.InteractPart.ProximityPrompt,1,true)
			task.wait(0.3)

			getRoot(game.Players.LocalPlayer.Character).CFrame  = OldPos 
			library:CoreNotification(tostring(info.Name),"Power Station Fixed; wait a little for it to start up!")
		else 
			library:CoreNotification(tostring(info.Name),"Power Station is already fixed! It's current power is "..tostring(game:GetService("Workspace").PowerTimer.Value).."%")
		end
	end)

	GameStuffSection2:CreateButton("Collect All JoseDucks", function()
		library:CoreNotification(tostring(info.Name),"Collected all JoseDucks!")

		for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.DuckParts:GetDescendants()) do
			if v:IsA("ClickDetector") then 
				fireclickdetector(v)
			end 
		end
	end)

	GameStuffSection2:CreateButton("Collect All Fish Coals", function()
		library:CoreNotification(tostring(info.Name),"Collected all Fish Coals!")

		for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.MegaFishCoalParts:GetDescendants()) do
			if v:IsA("ClickDetector") then 
				fireclickdetector(v)
				task.wait(0.3)
			end 
		end
	end)
	
	GameStuffSection2:CreateButton("Collect All Ships", function()
		library:CoreNotification(tostring(info.Name),"Collected all Ships!")

		for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.ChipsGiversFolder:GetDescendants()) do
			if v:IsA("ClickDetector") then 
				fireclickdetector(v)
			end 
		end
	end)

	GameStuffSection2:CreateButton("Collect All Coins", function()
		library:CoreNotification(tostring(info.Name),"Collected all Coins!")

		local OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame

		for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.CoinsGiverSpawns:GetDescendants()) do
			if v.Name == "CoinGiverPart" then 
				lookDown()
				getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
				task.wait(0.3)
				fireproximityprompt(v:FindFirstChild("ProximityPrompt"),1,true)
				task.wait(0.3)
			end 
		end
		getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
	end)
	
	---------| Teleports Stuff |--------
	
	local GameStuffSection3 = GameStuff:CreateSection("Teleports")

	GameStuffSection3:CreateButton("Shop", function()
		library:CoreNotification(tostring(info.Name),"Teleported to Shop")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-253.668549, 7.99385405, -396.407745, 0.99999845, 1.72123364e-08, 0.00174353924, -1.71232095e-08, 1, -5.11310851e-08, -0.00174353924, 5.11011571e-08, 0.99999845)
	end)

	GameStuffSection3:CreateButton("Destroyed Cabin", function()
		library:CoreNotification(tostring(info.Name),"Teleported to Destroyed Cabin")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-29.3237915, 35.668808, 97.8813934, 0.0369028896, -8.90335059e-08, 0.999318838, 2.37063134e-08, 1, 8.82187621e-08, -0.999318838, 2.04346389e-08, 0.0369028896)
	end)

	GameStuffSection3:CreateButton("PlayGround", function()
		library:CoreNotification(tostring(info.Name),"Teleported to PlayGround")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(183.452515, 49, -184.358582, 0.0626890585, 7.41214237e-08, 0.998033106, 6.19538199e-08, 1, -7.81589833e-08, -0.998033106, 6.67316797e-08, 0.0626890585)
	end)

	GameStuffSection3:CreateButton("Unfinished House", function()
		library:CoreNotification(tostring(info.Name),"Teleported to Unfinished House")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(339.886719, 58.8000069, 2.54844642, 0.0265348684, 3.87841013e-08, -0.999647915, 1.19592904e-08, 1, 3.91152106e-08, 0.999647915, -1.2992996e-08, 0.0265348684)
	end)

	GameStuffSection3:CreateButton("Survival SafeHouse", function()
		library:CoreNotification(tostring(info.Name),"Teleported to Survival SafeHouse")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-63.8092575, 19.4319229, -362.182037, -0.998391271, 4.10960732e-09, -0.0566993281, 7.36233341e-09, 1, -5.71590988e-08, 0.0566993281, -5.74845842e-08, -0.998391271)
	end)

	GameStuffSection3:CreateButton("Crashed Car", function()
		library:CoreNotification(tostring(info.Name),"Teleported to Crashed Car")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(126.956894, 4.95958805, 250.944809, -0.844417214, -1.89735108e-08, 0.535686076, 3.37987558e-08, 1, 8.86970284e-08, -0.535686076, 9.30028179e-08, -0.844417214)
	end)

	GameStuffSection3:CreateButton("Power Station", function()
		library:CoreNotification(tostring(info.Name),"Teleported to Power Station")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(332.752869, 7.8125, 264.779663, 0.998335302, 1.47704915e-08, -0.0576765202, -1.59519846e-08, 1, -2.00244124e-08, 0.0576765202, 2.09111324e-08, 0.998335302)
	end)

	GameStuffSection3:CreateButton("RakOOF Spawn", function()
		library:CoreNotification(tostring(info.Name),"Teleported to Survival RakOOF Spawn")
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-330.965057, -8.60246658, 296.202972, -0.680176198, 3.83994525e-08, 0.733048677, -1.69613781e-08, 1, -6.81212313e-08, -0.733048677, -5.87679558e-08, -0.680176198)
	end)
	
	GameStuffSection3:CreateButton("SupplyDrop", function()
		for i,v in pairs(game.Workspace:GetChildren()) do
			if v:IsA("Model") and v.Name == "SupplyDrop" then
				if v ~= nil and v:FindFirstChild("Model2") ~= nil and v:FindFirstChild("Model2"):FindFirstChild("ClickPartOpen") ~= nil then
					
					library:CoreNotification(tostring(info.Name),"Teleported to the SupplyDrop")
					getRoot(game.Players.LocalPlayer.Character).CFrame = game.Workspace.SupplyDrop.Model2.ClickPartOpen.CFrame
				else
					library:CoreNotification(tostring(info.Name),"SupplyDrop not found")
				end				
			end
		end		
	end)

	local AutoTP_FlareGun = false
	GameStuffSection3:CreateToggle("Auto TP to FlareGun", function(arg)
		if AutoTP_FlareGun == false then
			AutoTP_FlareGun = true
			library:CoreNotification(tostring(info.Name),"Enabled Auto TP to FlareGun Script!")

		elseif AutoTP_FlareGun == true then
			AutoTP_FlareGun = false
			library:CoreNotification(tostring(info.Name),"Disabled Auto TP to FlareGun Script!")
		end

		if AutoTP_FlareGun == true then
			TPtoFlareGunEnabled = true

			TPToFlareGun()
		else
			TPtoFlareGunEnabled = false
		end
	end)

	GameStuffSection3:CreateButton("TP to FlareGun", function()
		if TPtoFlareGunEnabled == false then
			TPToFlareGun()
			library:CoreNotification(tostring(info.Name),"Teleported to FlareGun Spawn!")
		else
			library:CoreNotification(tostring(info.Name),"Auto TP to FlareGun Script is Enabled!")
		end

	end)
	
	---------| Farm Stuff |--------
	
	local GameStuffSection4 = GameStuff:CreateSection("Farmimg Features")
	
	local AutoFarmRequiredToolList = {"GoldenPan", "Pan"}
	GameStuffSection4:CreateToggle("Survivals AutoFarm [BETA]",function()
		if AutoKillRake == false then
			AutoKillRake = true

		elseif AutoKillRake == true then
			AutoKillRake = false
		end
		
		while wait() do
			if InfStamina == false then
				library:CoreNotification(tostring(info.Name),"Please Enable Infinite Stamina to proceed!")
				return
			end
			if not Player:GetAttribute("InServerMenuValue") and CheckTools(game.Players.LocalPlayer) then
				if workspace:FindFirstChild("Day").Value == false and AutoKillRake == true and game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").Health > 0 then
					game.Players.LocalPlayer.Character.Humanoid:UnequipTools()

					for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
						if table.find(AutoFarmRequiredToolList, v.Name) then			
							for i,v in pairs(game.Workspace:GetChildren()) do
								if v.Name == 'The_Rake' and v:FindFirstChild("HumanoidRootPart") then
									library:CoreNotification(tostring(info.Name),"AFK AutoFarm initialized!, Teleported To Player & RakeOOF to SafePlace")

									game.Players.LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson

									pcall(function()
										repeat
											task.wait()
										until isrbxactive()

										local Viewport = workspace.CurrentCamera.ViewportSize
										mousemoveabs(Viewport.X / 2, Viewport.Y / 2)
									end)

									game.Players.LocalPlayer.Character.Humanoid:UnequipTools()
									local OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
									
									wait()
									
									game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart").CFrame = _Workspace_:FindFirstChild("PlayerStartMenuPart").CFrame

									v:FindFirstChild("HumanoidRootPart").Anchored = true
									v:FindFirstChild("HumanoidRootPart").CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0,0,-2)

									for i, v in pairs(game.Players.LocalPlayer.Backpack:GetChildren()) do
										if table.find(AutoFarmRequiredToolList, v.Name) then
											if v.Name == "GoldenPan" then
												game.Players.LocalPlayer.Character.Humanoid:EquipTool(game.Players.LocalPlayer.Backpack:FindFirstChild("GoldenPan"))

											elseif v.Name == "Pan" and not v:FindFirstChild("GoldenPan") then
												game.Players.LocalPlayer.Character.Humanoid:EquipTool(game.Players.LocalPlayer.Backpack:FindFirstChild("Pan"))
											end											
										end
									end
										

									repeat wait()

										v:FindFirstChild("HumanoidRootPart").Anchored = true
										v:FindFirstChild("HumanoidRootPart").CFrame = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.new(0, 0, -2)
										game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v:FindFirstChild("HumanoidRootPart").CFrame * CFrame.new(0, 0, -2)
										
										game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart").CFrame = _Workspace_:FindFirstChild("PlayerStartMenuPart").CFrame
										
										pcall(function()
											mouse1click()
										end)

									until v:FindFirstChild("NPC").Health == 0 or game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").Health == 0 or AutoKillRake == false or workspace:FindFirstChild("Day").Value == true

									game.Players.LocalPlayer.CameraMode = Enum.CameraMode.Classic

									game.Players.LocalPlayer.Character.Humanoid:UnequipTools()
									game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart").CFrame = OldPos

									if AutoKillRake == false then
										library:CoreNotification(tostring(info.Name),"Disabled AFK AutoFarm!, Player teleported to your old position")
										return

									elseif workspace:FindFirstChild("Day").Value == true and not v:FindFirstChild("NPC").Health == 0 then
										library:CoreNotification(tostring(info.Name),"Oops it looks like it's day try it the next night!, Player teleported to your old position")

									elseif game.Players.LocalPlayer.Character:FindFirstChild("Humanoid").Health == 0 then
										library:CoreNotification(tostring(info.Name),"You died, AFK AutoFarm un-initialized")

									elseif v:FindFirstChild("NPC").Health == 0 then
										library:CoreNotification(tostring(info.Name),"RakeOOF Killed!, Player teleported to your old position")
									end
								end
							end
						elseif game:GetService("BadgeService"):UserHasBadge(Player.UserId, 2124908983) and Player.leaderstats.Points.Value > 500 then
							if not game.Players.LocalPlayer.Backpack:FindFirstChild("GoldenPan") then
								fireclickdetector(game:GetService("Workspace").StuffGiversFolder.GoldToolGiver.ClickDetector)
							end
							
						elseif not game:GetService("BadgeService"):UserHasBadge(Player.UserId, 2124908983) and Player.leaderstats.Points.Value > 500 then
							for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.PanGiverSpawns:GetDescendants()) do
								if v:IsA("ClickDetector") then
									
									game.Players.LocalPlayer.Character.Humanoid:UnequipTools()
									if not game.Players.LocalPlayer.Backpack:FindFirstChild("Pan") then
										fireclickdetector(v)
									else
										return
									end
								end 
							end
						end
					end
				end
			end
		end
	end)
	
	local PointsAutoFarm = false
	GameStuffSection4:CreateToggle("Scraps AutoFarm", function(arg)
		if PointsAutoFarm == false then
			PointsAutoFarm = true
			library:CoreNotification(tostring(info.Name),"Enabled Scraps AutoFarm Script!")

		elseif PointsAutoFarm == true then
			PointsAutoFarm = false
			library:CoreNotification(tostring(info.Name),"Disabled Scraps AutoFarm Script!")
		end

		coroutine.resume(coroutine.create(function()
			pcall(function()
				while wait() do
					for i, v in pairs(game:GetService("Workspace").StuffGiversFolder.ScrapMetals:GetDescendants()) do
						if v.Name == "TouchInterest" and v.Parent and PointsAutoFarm == true then
							firetouchinterest(getRoot(game.Players.LocalPlayer.Character), v.Parent, 0)
							wait(0.01)
							firetouchinterest(getRoot(game.Players.LocalPlayer.Character), v.Parent, 1)
						end
					end
				end
			end)
		end))
	end)
	
	local PowerFixAutoFarm = false
	GameStuffSection4:CreateToggle("Auto Fix Power Station", function()
		if PowerFixAutoFarm == false then
			PowerFixAutoFarm = true
			library:CoreNotification(tostring(info.Name),"Enabled Fix Power Station Script!")

		elseif PowerFixAutoFarm == true then
			PowerFixAutoFarm = false
			library:CoreNotification(tostring(info.Name),"Disabled Fix Power Station Script!")
		end
		
		
		coroutine.resume(coroutine.create(function()
			pcall(function()
				while wait() do
					if game:GetService("Workspace").PowerTimer.Value <= 0 and _Workspace_:FindFirstChild("HourIsHappening").Value == false and PowerFixAutoFarm then
						if game:GetService("Workspace").PowerRestoring.Value == false then
							local OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
							library:CoreNotification(tostring(info.Name),"Attempting to fix Power Station")

							lookDown()

							getRoot(game.Players.LocalPlayer.Character).CFrame = game:GetService("Workspace").LocationsFolder.PowerStation.ControlButtons.Buttons.InteractPart.CFrame
							task.wait(0.3)

							fireproximityprompt(game:GetService("Workspace").LocationsFolder.PowerStation.ControlButtons.Buttons.InteractPart.ProximityPrompt,1,true)
							task.wait(0.3)

							getRoot(game.Players.LocalPlayer.Character).CFrame  = OldPos
						end

						return library:CoreNotification(tostring(info.Name),"Power Station Fixed; wait a little for it to start up!")
					elseif game:GetService("Workspace").PowerTimer.Value > 1  then
						
						return library:CoreNotification(tostring(info.Name),"Power Station is already fixed! It's current power is "..tostring(game:GetService("Workspace").PowerTimer.Value).."%")
					elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true then
						return library:CoreNotification(tostring(info.Name),"A Hour is in Progress!")
					end
				end
			end)
		end))
	end)
	
	local VendingMachineAutoFarm = false
	GameStuffSection4:CreateToggle("Vending machine AutoFram", function()
		if VendingMachineAutoFarm == false then
			VendingMachineAutoFarm = true
			library:CoreNotification(tostring(info.Name),"Enabled Vending Machine Auto Farm!")

		elseif VendingMachineAutoFarm == true then
			VendingMachineAutoFarm = false
			library:CoreNotification(tostring(info.Name),"Disabled Vending Machine Auto Farm!")
		end
		
		game.Players.LocalPlayer.Character.Humanoid:UnequipTools()
		
		coroutine.resume(coroutine.create(function()
			pcall(function()
				while wait() do
					for i, v in pairs(game.Players:GetPlayers()) do
						if v == game.Players.LocalPlayer then
							if v.Backpack:FindFirstChild("Coin") and VendingMachineAutoFarm == true then
								local OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame

								repeat 
									getRoot(game.Players.LocalPlayer.Character).CFrame = game:GetService("Workspace").LocationsFolder.Shop.VendingMachine.InteractPart.CFrame
									task.wait(0.3)

									fireproximityprompt(game:GetService("Workspace").LocationsFolder.Shop.VendingMachine.InteractPart.ProximityPrompt,1,true)			
								until v.Backpack:FindFirstChild("Coin") == nil or VendingMachineAutoFarm == false

								getRoot(game.Players.LocalPlayer.Character).CFrame  = OldPos
							end
						end
					end
				end
			end)
		end))
	end)

	local HoursSafeMode = false
	local HoursafeModeTog
	
	HoursafeModeTog = GameStuffSection4:CreateToggle("Hours Safe Mode", function(arg)
		if HoursSafeMode == false then
			HoursSafeMode = true
			library:CoreNotification(tostring(info.Name),"Enabled Hours SafeMode!")

		elseif HoursSafeMode == true then
			HoursSafeMode = false
			library:CoreNotification(tostring(info.Name),"Disabled Hours SafeMode!")
		end

		_Workspace_:FindFirstChild("HourIsHappening").Changed:Connect(function()
			if _Workspace_:FindFirstChild("HourIsHappening").Value == true and HoursSafeMode == true and AutoKillRake == false then

				OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame

				getRoot(game.Players.LocalPlayer.Character).CFrame = _Workspace_:FindFirstChild("PlayerStartMenuPart").CFrame	

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == false and HoursSafeMode == true and AutoKillRake == false then
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
			end
		end)

		pcall(function()
			if AutoKillRake == true then
				HoursafeModeTog:UpdateToggle("Hours Safe Mode", false)
				HoursSafeMode = false
				return
			end
			
			if _Workspace_:FindFirstChild("HourIsHappening").Value == true and HoursSafeMode == true and AutoKillRake == false then

				OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame

				getRoot(game.Players.LocalPlayer.Character).CFrame = _Workspace_:FindFirstChild("PlayerStartMenuPart").CFrame	

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == false and HoursSafeMode == true and AutoKillRake == false then
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
			end
		end)
	end)
	
	---------| Visuals Stuff |--------
	
	local GameStuffSection5 = GameStuff:CreateSection("Visuals")

	local RakeEsp = false
	GameStuffSection5:CreateToggle("Rake ESP", function(arg)
		if RakeEsp == false then
			RakeEsp = true
			library:CoreNotification(tostring(info.Name),"Enabled Rake Esp!")

		elseif RakeEsp == true then
			RakeEsp = false
			library:CoreNotification(tostring(info.Name),"Disabled Rake Esp!")
		end


		RS.RenderStepped:Connect(function()
			for i,v in pairs(game.Workspace:GetChildren()) do
				if v.Name == 'The_Rake' then
					if v:FindFirstChild("Head") ~= nil and v:FindFirstChild("Head"):FindFirstChild("ESP") == nil and RakeEsp == true then
						MakeESP(v:FindFirstChild("Head"), "The Rake", Color3.fromRGB(255, 0, 0))
						v:FindFirstChild("Head"):FindFirstChild("Highlight"):Destroy()
						
					elseif v:FindFirstChild("Head"):FindFirstChild("ESP") and RakeEsp == false then
						v:FindFirstChild("Head"):FindFirstChild("ESP"):Destroy()
						v:FindFirstChild("Head"):FindFirstChild("Highlight"):Destroy()
					end				
				end
			end
		end)
	end)

	local FlareGunEsp = false
	GameStuffSection5:CreateToggle("FlareGun ESP", function(arg)
		if FlareGunEsp == false then
			FlareGunEsp = true
			library:CoreNotification(tostring(info.Name),"Enabled Rake ESP!")

		elseif FlareGunEsp == true then
			FlareGunEsp = false
			library:CoreNotification(tostring(info.Name),"Disabled Rake ESP!")
		end


		RS.RenderStepped:Connect(function()
			for i,v in pairs(game.Workspace:GetChildren()) do
				if v:IsA("Tool") and v.Name == "FlareGun" then
					if v:FindFirstChild("Handle") ~= nil and v:FindFirstChild("Handle"):FindFirstChild("ESP") == nil and FlareGunEsp == true then
						MakeESP(v:FindFirstChild("Handle"), "FlareGun", Color3.fromRGB(255, 85, 0))

					elseif v:FindFirstChild("Handle"):FindFirstChild("ESP") and FlareGunEsp == false then
						v:FindFirstChild("Handle"):FindFirstChild("ESP"):Destroy()
						v:FindFirstChild("Handle"):FindFirstChild("Highlight"):Destroy()
					end				
				end
			end
		end)
	end)

	local SupplyDropGunEsp = false
	GameStuffSection5:CreateToggle("SupplyDrop ESP", function(arg)
		if SupplyDropGunEsp == false then
			SupplyDropGunEsp = true
			library:CoreNotification(tostring(info.Name),"Enabled SupplyDrop ESP!")

		elseif SupplyDropGunEsp == true then
			SupplyDropGunEsp = false
			library:CoreNotification(tostring(info.Name),"Disabled SupplyDrop ESP!")
		end


		RS.RenderStepped:Connect(function()
			for i,v in pairs(game.Workspace:GetChildren()) do
				if v:IsA("Model") and v.Name == "SupplyDrop" then
					if v ~= nil and v:FindFirstChild("ESP") == nil and SupplyDropGunEsp == true then
						MakeESP(v, "SupplyDrop", Color3.fromRGB(0, 255, 0))

					elseif v:FindFirstChild("ESP") and SupplyDropGunEsp == false then
						v:FindFirstChild("ESP"):Destroy()
						v:FindFirstChild("Highlight"):Destroy()
					end				
				end
			end
		end)
	end)
	
	local ShowLocations = false
	GameStuffSection5:CreateToggle("Locations ESP", function(arg)
		if ShowLocations == false then
			ShowLocations = true
			library:CoreNotification(tostring(info.Name),"Enabled Locations ESP!")

		elseif ShowLocations == true then
			ShowLocations = false
			library:CoreNotification(tostring(info.Name),"Disabled Locations ESP!")
		end

		
		RS.RenderStepped:Connect(function()
			for i, v in pairs(_Workspace_.LocationsBillboardGuis:GetDescendants()) do
				if v.Name == "MapBillboardGui" then
					if ShowLocations then
						v.Enabled = true
					else
						v.Enabled = false
					end	
				end
			end
		end)
	end)
	
	local ShowJoseDucks = false
	GameStuffSection5:CreateToggle("JoseDucks ESP", function()
		if ShowJoseDucks == false then
			ShowJoseDucks = true
			library:CoreNotification(tostring(info.Name),"Enabled JoseDucks ESP!")

		elseif ShowJoseDucks == true then
			ShowJoseDucks = false
			library:CoreNotification(tostring(info.Name),"Disabled JoseDucks ESP!")
		end
		
		RS.RenderStepped:Connect(function()
			for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.DuckParts:GetChildren()) do
				if v ~= nil and v:FindFirstChild("ESP") == nil and ShowJoseDucks == true then
					MakeESP(v, "JoseDuck", Color3.fromRGB(255, 255, 0))

				elseif v:FindFirstChild("ESP") and ShowJoseDucks == false then
					v:FindFirstChild("ESP"):Destroy()
					v:FindFirstChild("Highlight"):Destroy()
				end		
			end
		end)
	end)
	
	local ShowFishCoals = false
	GameStuffSection5:CreateToggle("Fish Coals ESP", function()
		if ShowFishCoals == false then
			ShowFishCoals = true
			library:CoreNotification(tostring(info.Name),"Enabled Fish Coals ESP!")

		elseif ShowFishCoals == true then
			ShowFishCoals = false
			library:CoreNotification(tostring(info.Name),"Disabled Fish Coals ESP!")
		end
		
		RS.RenderStepped:Connect(function()
			for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.MegaFishCoalParts:GetChildren()) do
				if v ~= nil and v:FindFirstChild("ESP") == nil and ShowFishCoals == true then
					MakeESP(v, "FishCoal", Color3.fromRGB(0, 255, 255))

				elseif v:FindFirstChild("ESP") and ShowFishCoals == false then
					v:FindFirstChild("ESP"):Destroy()
					v:FindFirstChild("Highlight"):Destroy()
				end	
			end
		end)
	end)
	
	local ShowShips = false
	GameStuffSection5:CreateToggle("Ships ESP", function()
		if ShowShips == false then
			ShowShips = true
			library:CoreNotification(tostring(info.Name),"Enabled Ships ESP!")

		elseif ShowShips == true then
			ShowShips = false
			library:CoreNotification(tostring(info.Name),"Disabled Ships ESP!")
		end
		
		RS.RenderStepped:Connect(function()
			for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.ChipsGiversFolder:GetChildren()) do
				if v ~= nil and v:FindFirstChild("ESP") == nil and ShowShips == true then
					MakeESP(v, "Ships", Color3.fromRGB(255, 170, 0))

				elseif v:FindFirstChild("ESP") and ShowShips == false then
					v:FindFirstChild("ESP"):Destroy()
					v:FindFirstChild("Highlight"):Destroy()
				end	
			end
		end)
	end)
	
	local ShowCoins = false
	GameStuffSection5:CreateToggle("Coins ESP", function()
		if ShowCoins == false then
			ShowCoins = true
			library:CoreNotification(tostring(info.Name),"Enabled Coins ESP!")

		elseif ShowCoins == true then
			ShowCoins = false
			library:CoreNotification(tostring(info.Name),"Disabled CoinsESP!")
		end
		
		RS.RenderStepped:Connect(function()
			for i,v in pairs(game:GetService("Workspace").StuffGiversFolder.CoinsGiverSpawns:GetChildren()) do
				if v ~= nil and v:FindFirstChild("ESP") == nil and ShowCoins == true then
					MakeESP(v, "Coin", Color3.fromRGB(255, 255, 127))

				elseif v:FindFirstChild("ESP") and ShowCoins == false then
					v:FindFirstChild("ESP"):Destroy()
					v:FindFirstChild("Highlight"):Destroy()
				end 
			end
		end)
	end)
	
	---------| Code Features |--------

	local GameStuffSection6 = GameStuff:CreateSection("Codes Features")

	GameStuffSection6:CreateButton("Give Cheese", function()
		library:CoreNotification(tostring(info.Name),"Code Reedemed: Cheese!")

		game:GetService("Players").LocalPlayer.PlayerGui.CodeGui.SendTextBoxRE:FireServer("cheese")
		wait(4.50)
		game.Players.LocalPlayer.PlayerGui.CodeGui.CodeFrame.Visible = false
	end)

	GameStuffSection6:CreateButton("Give BloxyCola", function()
		library:CoreNotification(tostring(info.Name),"Code Reedemed: BloxyCola!")

		game:GetService("Players").LocalPlayer.PlayerGui.CodeGui.SendTextBoxRE:FireServer("code")
		wait(4.50)
		game.Players.LocalPlayer.PlayerGui.CodeGui.CodeFrame.Visible = false
	end)

	GameStuffSection6:CreateButton("Give Bright Flashlight", function()
		library:CoreNotification(tostring(info.Name),"Code Reedemed: Bright Flashlight!")

		game:GetService("Players").LocalPlayer.PlayerGui.CodeGui.SendTextBoxRE:FireServer("brightness")
		wait(4.50)
		game.Players.LocalPlayer.PlayerGui.CodeGui.CodeFrame.Visible = false
	end)

	GameStuffSection6:CreateButton("SUS", function()
		library:CoreNotification(tostring(info.Name),"Code Reedemed: impostor suit!")

		game:GetService("Players").LocalPlayer.PlayerGui.CodeGui.SendTextBoxRE:FireServer("imposter")
		wait(4.50)
		game.Players.LocalPlayer.PlayerGui.CodeGui.CodeFrame.Visible = false
	end)
	
	---------| Visuals Stuff |--------

	local GameStuffSection7 = GameStuff:CreateSection("Misc")
	
	local HoursNotify = false
	GameStuffSection7:CreateToggle("Hours Notify", function(arg)
		if HoursNotify == false then
			HoursNotify = true
			library:CoreNotification(tostring(info.Name),"Enabled Hours Notify!")

		elseif HoursNotify == true then
			HoursNotify = false
			library:CoreNotification(tostring(info.Name),"Disabled Hours Notify!")
		end

		_Workspace_:FindFirstChild("HourIsHappening").Changed:Connect(function()
			if _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingBloodHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",
					Text =   "BloodHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingNightmareHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",   
					Text =   "NightmareHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingCorruptedHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected", 
					Text =   "CorruptedHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingCheeseHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",  
					Text =   "CheeseHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingOrangesHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",
					Text =   "OrangesHour",
					Button1 = "Ok", Duration = 20,
				})
			end
		end)

		pcall(function()
			if _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingBloodHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",
					Text =   "BloodHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingNightmareHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",   
					Text =   "NightmareHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingCorruptedHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected", 
					Text =   "CorruptedHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingCheeseHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",  
					Text =   "CheeseHour",
					Button1 = "Ok", Duration = 20,
				})

			elseif _Workspace_:FindFirstChild("HourIsHappening").Value == true and _Workspace_:FindFirstChild("BeingOrangesHour").Value == true then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Hour Start Detected",
					Text =   "OrangesHour",
					Button1 = "Ok", Duration = 20,
				})
			end
		end)
	end)

	GameStuffSection7:CreateButton("Show Shop UI", function()
		firetouchinterest(getRoot(game.Players.LocalPlayer.Character),game:GetService("Workspace").LocationsFolder.Shop.EnterShopPart,0)
	end)

	GameStuffSection7:CreateButton("Show Supply UI", function()
		game:GetService("Players").LocalPlayer.PlayerGui.SupplyDropGui.RemoteEvent:FireServer()
	end)
end

function TOH_Scripts()
	
	local AutoFarm = false
	local function AutoFarmFunc()
		spawn(function()
			while AutoFarm do
				local endzone = game.Workspace.tower.sections.finish.FinishGlow.CFrame

				local player = game.Players.LocalPlayer.Character
				player.HumanoidRootPart.CFrame = endzone
				wait()
			end
		end)
	end
	
	local GameStuff = Window:CreatePage("TOH", 4621599120, 3)
	local GameStuffSection = GameStuff:CreateSection("Features")
	
	GameStuffSection:CreateButton("Bypass Anti-Cheat",function()
		library:CoreNotification(tostring(info.Name),"Bypassed Anti-Cheat!")

		local reg = getreg()

		for i, Function in next, reg do
			if type(Function) == 'function' then
				local info = getinfo(Function)

				if info.name == 'kick' then
					if (hookfunction(info.func, function(...)end)) then
						warn("succesfully hooked kick")
					else
						warn("failed to hook kick")
					end
				end
			end
		end

		local playerscripts = game:GetService("Players").LocalPlayer.PlayerScripts

		local script1 = playerscripts.LocalScript
		local script2 = playerscripts.LocalScript2

		local script1signal = script1.Changed
		local script2signal = script2.Changed

		for i, connection in next, getconnections(script1signal) do
			connection:Disable()
		end

		for i, connection in next, getconnections(script2signal) do
			connection:Disable()
		end

		script1:Destroy()
		script2:Destroy()
	end)
	
	GameStuffSection:CreateButton("God Mode (Remove KillParts)",function()
		for i,v in pairs(game:GetService("Workspace").tower:GetDescendants()) do
			if v:IsA("BoolValue") and v.Name == "kills" then
				v.Parent:Destroy()
			end
		end
	end)

	InfiniteJump = false
	GameStuffSection:CreateToggle("Infinite Jump",function()
		if InfiniteJump == false then
			InfiniteJump = true

			library:CoreNotification(tostring(info.Name),"Enabled Infinite Jump Script!")
		elseif InfiniteJump == true then
			InfiniteJump = false
			
			library:CoreNotification(tostring(info.Name),"Disabled Infinite Jump Script!")
		end

		game:GetService("UserInputService").JumpRequest:connect(function()
			if InfiniteJump == true then
				game:GetService"Players".LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
			end
		end)
	end) 
	
	GameStuffSection:CreateButton("Go to the Top",function()
		library:CoreNotification(tostring(info.Name),"Teleported to the Top!")

		getRoot(game.Players.LocalPlayer.Character).CFrame = workspace.tower.sections.finish.FinishGlow.CFrame
	end)
	
	GameStuffSection:CreateToggle("AutoFarm [BETA]",function()
		if AutoFarm == false then
			AutoFarm = true
			
			library:CoreNotification(tostring(info.Name),"Enabled Infinite Jump Script!")
		elseif AutoFarm == true then
			AutoFarm = false
			
			library:CoreNotification(tostring(info.Name),"Disabled Infinite Jump Script!")
		end
		
		if AutoFarm == true then
			AutoFarmFunc()
		end
	end)
	
	GameStuffSection:CreateButton("Get All Items/Tools",function()
		library:CoreNotification(tostring(info.Name),"All Items/Tools gived to you!")

		for i,v in pairs(game.Players.LocalPlayer.Backpack:GetDescendants()) do
			if v:IsA("Tool") then
				v:Destroy()
			end
		end

		wait() 

		for i,v in pairs(game.ReplicatedStorage.Gear:GetDescendants()) do
			if v:IsA("Tool") then
				local CloneThings = v:Clone()
				wait()
				CloneThings.Parent = game.Players.LocalPlayer.Backpack
			end
		end
	end)
end

function NDS_Scripts()
	local GameStuff = Window:CreatePage("NDS", 4621599120, 3)
	local GameStuffSection = GameStuff:CreateSection("Features")

	local DisasterWarnings = false
	GameStuffSection:CreateToggle("Notify Disaster",function()
		if DisasterWarnings == false then
			DisasterWarnings = true

		elseif DisasterWarnings == true then
			DisasterWarnings = false
		end

		if DisasterWarnings == true then
			local Character = game:GetService("Players").LocalPlayer.Character
			local Tag = Character:FindFirstChild("SurvivalTag")

			if Tag then
				game:GetService("StarterGui"):SetCore("SendNotification",{     
					Title = "Disaster Detected",
					Text =   "" .. Tag.Value,
					Button1 = "Ok",
					Duration = 20,
				})
			end

			local function Repeat(R)
				R.ChildAdded:connect(
					function(Find)
						if Find.Name == "SurvivalTag" then
							game:GetService("StarterGui"):SetCore("SendNotification",{     
								Title = "Disaster Detected",  
								Text =   "".. Find.Value,
								Button1 = "Ok",
								Duration = 20,
							})
						end
					end
				)
			end

			Repeat(Character)
			game:GetService("Players").LocalPlayer.CharacterAdded:connect(function(R)
				Repeat(R)
			end)
		end
	end)

	local MapVotePage = false
	GameStuffSection:CreateButton("Open Golden ComPass",function()
		if MapVotePage == false then
			MapVotePage = true
			library:CoreNotification(tostring(info.Name),"Visible MapVotePage!")

		elseif MapVotePage == true then
			MapVotePage = false
			library:CoreNotification(tostring(info.Name),"Invisible MapVotePage!")
		end

		if MapVotePage == true then		
			TextLabel = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MapVotePage
			TextLabel.Visible = true
		else
			TextLabel = game:GetService("Players").LocalPlayer.PlayerGui.MainGui.MapVotePage
			TextLabel.Visible = false
		end
	end)

	GameStuffSection:CreateButton("Remove FallDamage",function()
		library:CoreNotification(tostring(info.Name),"Disabled FallDamage Script!")

		while wait() do
			if game.Players.LocalPlayer.Character:FindFirstChild("FallDamageScript") then
				game.Players.LocalPlayer.Character:FindFirstChild("FallDamageScript"):Destroy()
			end
		end
	end)
	
	GameStuffSection:CreateButton("Interact all",function()
		for i, v in pairs(game:GetService("Workspace").Structure:GetDescendants()) do
			if v:IsA("ClickDetector") then
				if fireclickdetector then
					fireclickdetector(v)
				else
					library:CoreNotification(tostring(info.Name),"Ejecutor not supported!")
				end
			end
		end
	end)

	local GameStuffSection2 = GameStuff:CreateSection("Game Mods")
	
	local BalloonClone
	GameStuffSection2:CreateButton("Copy Green Balloon",function()
		if not game.Workspace[Player.Name]:FindFirstChild("GreenBalloon") and not game.Players.LocalPlayer.Backpack:FindFirstChild("GreenBalloon") then
			library:CoreNotification(tostring(info.Name),"You will experience some lag until found the Green Balloon!")
		else
			library:CoreNotification(tostring(info.Name),"You already have the Green Balloon!")
		end

		while wait() do
			for i, v in ipairs(game.Players:GetPlayers()) do
				if not game.Workspace[Player.Name]:FindFirstChild("GreenBalloon") and not Player.Backpack:FindFirstChild("GreenBalloon") then
					for i, v2 in ipairs(v.Character:GetChildren()) do
						if (tostring(v2.Name) == "GreenBalloon") then
							BalloonClone = v2:Clone()
							BalloonClone.Parent = Player.Backpack
						end
					end
				else
					return
				end
			end 
		end
	end)
	
	local RemoveLava = false
	GameStuffSection2:CreateToggle("Remove Volcan Lava",function()
		if RemoveLava == false then
			
			RemoveLava = true
			library:CoreNotification(tostring(info.Name),"Disable remove Volcan Lava script!")

		elseif RemoveLava == true then
			RemoveLava = false
			library:CoreNotification(tostring(info.Name),"Enabled remove Volcan Lava script!")
		end
		
		game:GetService("Workspace").Structure.ChildAdded:Connect(function(Child)
			if Child.Name == "Lava" and RemoveLava then
				game:GetService("Debris"):AddItem(Child, 0)
			end
		end)
	end)
	
	local RemoveMeteors = false
	GameStuffSection2:CreateToggle("Remove Meteors",function()
		if RemoveMeteors == false then
			
			RemoveMeteors = true
			library:CoreNotification(tostring(info.Name),"Disable remove meteors script!")

		elseif RemoveMeteors == true then
			
			RemoveMeteors = false
			library:CoreNotification(tostring(info.Name),"Enabled remove meteors script!")
		end

		game:GetService("Workspace").Structure.MeteorFolder.ChildAdded:Connect(function(Child)
			if Child.Name == "MeteorTemplate" and RemoveMeteors then
				game:GetService("Debris"):AddItem(Child, 0)
			end
		end)
	end)
	
	local RocksCollide = false
	GameStuffSection2:CreateToggle("Island Rocks Collidable",function()
		if RocksCollide == false then

			RocksCollide = true
			library:CoreNotification(tostring(info.Name),"Disable Island Rocks Collide!")

		elseif RocksCollide == true then

			RocksCollide = false
			library:CoreNotification(tostring(info.Name),"Enabled Island Rocks Collide!")
		end

		game:GetService("RunService").RenderStepped:Connect(function()
			for i, v in pairs(game:GetService("Workspace").Island:GetChildren()) do
				if v.Name == "LowerRocks" and RocksCollide then
					v.CanCollide = true
				elseif v.Name == "LowerRocks" and not RocksCollide then
					v.CanCollide = false
				end
			end
		end)
	end)
	
	local GameStuffSection3 = GameStuff:CreateSection("Teleports")
	
	GameStuffSection3:CreateButton("Teleport To Lobby",function()
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-243, 194, 331)
	end)

	GameStuffSection3:CreateButton("Teleport To Map",function()
		getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-117, 47, 5)
	end)
end

function Apeirophobia_Scripts()
	local GameStuff = Window:CreatePage("Apeirophobia", 4621599120, 3)
	local GameStuffSection = GameStuff:CreateSection("Visuals")
	
	local function lookDown()
		workspace.Camera.CFrame = CFrame.new(264.744202, 44.9857788, 19.0272675, 0.917633414, -0.391390145, 0.0690128133, 0, 0.173648611, 0.984807611, -0.397428036, -0.903692365, 0.159345)
	end
	
	local function round(num, numDecimalPlaces)
		local mult = 10^(numDecimalPlaces or 0)
		return math.floor(num * mult + 0.5) / mult
	end
	
	local EntitiesESP = false
	local function MakeEntityESP(Entity)
		task.spawn(function()
			for i,v in pairs(CoreGui:GetChildren()) do
				if v.Name == Entity.Name..'_ESP' then
					v:Destroy()
				end
			end

			wait()

			if Entity ~= nil and not CoreGui:FindFirstChild(Entity.Name..'_ESP') then
				local ESPholder = Instance.new("Folder")
				ESPholder.Name = Entity.Name..'_ESP'
				ESPholder.Parent = CoreGui

				repeat wait(1) until Entity and Entity:FindFirstChild("HumanoidRootPart") and Entity:FindFirstChildOfClass("Humanoid")
				
				for i, n in pairs(Entity:GetChildren()) do
					local a = Instance.new("Highlight")
					a.Name = Entity.Name
					
					a.Parent = ESPholder
					a.Adornee = n
					
					a.FillTransparency = 1
					a.OutlineColor = Color3.new(1, 0, 0)
				end
				
				if Entity:FindFirstChild('HumanoidRootPart') then
					local BillboardGui = Instance.new("BillboardGui")
					local TextLabel = Instance.new("TextLabel")

					BillboardGui.Adornee = Entity.HumanoidRootPart
					BillboardGui.Name = Entity.Name
					BillboardGui.Parent = ESPholder
					BillboardGui.Size = UDim2.new(0, 100, 0, 150)
					BillboardGui.StudsOffset = Vector3.new(0, 1, 0)
					BillboardGui.AlwaysOnTop = true

					TextLabel.Parent = BillboardGui
					TextLabel.BackgroundTransparency = 1
					TextLabel.Position = UDim2.new(0, 0, 0, -50)
					TextLabel.Size = UDim2.new(0, 100, 0, 100)
					TextLabel.Font = Enum.Font.SourceSansSemibold
					TextLabel.TextSize = 20
					TextLabel.TextColor3 = Color3.new(1, 0, 0)
					TextLabel.TextStrokeTransparency = 0
					TextLabel.TextYAlignment = Enum.TextYAlignment.Bottom
					TextLabel.Text = Entity.Name
					TextLabel.ZIndex = 10

					local EspLoopFunc
					local AddedFunc
					
					AddedFunc = game:GetService("Workspace").Entities.ChildAdded:Connect(function()
						if EntitiesESP then
							EspLoopFunc:Disconnect()
							ESPholder:Destroy()
							repeat wait(1) until Entity and Entity:FindFirstChild("HumanoidRootPart") and Entity:FindFirstChildOfClass("Humanoid")
							CreateESP(Entity)
							AddedFunc:Disconnect()
						else
							AddedFunc:Disconnect()
						end
					end)

					local function espLoop()
						if CoreGui:FindFirstChild(Entity.Name..'_ESP') then
							if Entity and Entity:FindFirstChild("HumanoidRootPart") and Entity:FindFirstChildOfClass("Humanoid") and Players.LocalPlayer.Character and getRoot(Players.LocalPlayer.Character) and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
								local pos = math.floor((getRoot(Players.LocalPlayer.Character).Position - Entity:FindFirstChild("HumanoidRootPart").Position).magnitude)
								TextLabel.Text = 'Name: '..Entity.Name..' | Health: '..round(Entity:FindFirstChildOfClass('Humanoid').Health, 1)..' | Studs: '..pos
							end
						else
							AddedFunc:Disconnect()
							EspLoopFunc:Disconnect()
						end
					end
					EspLoopFunc = game:GetService("RunService").RenderStepped:Connect(espLoop)
				end
			end
		end)
	end

	local function MakePartESP(Part)
		local a = Instance.new("Highlight")
		a.Name = Part.Name.."_PESP"
		a.Parent = Part

		a.FillTransparency = 1
		a.OutlineColor = Color3.new(0, 1, 0)
	end

	GameStuffSection:CreateToggle("Entities ESP",function()
		if EntitiesESP == false then
			EntitiesESP = true
			
			library:CoreNotification(tostring(info.Name),"Enabled Entities ESP!")
			for i,v in pairs(game:GetService("Workspace").Entities:GetChildren()) do
				if v ~= nil and v:FindFirstChildOfClass('Humanoid') then
					MakeEntityESP(v)
				end
			end

		elseif EntitiesESP == true then
			EntitiesESP = false
			
			library:CoreNotification(tostring(info.Name),"Disabled Entities ESP!")
			for i,c in pairs(CoreGui:GetChildren()) do
				if string.sub(c.Name, -4) == '_ESP' then
					c:Destroy()
				end
			end
		end
	end)
	
	pcall(function()
		game:GetService("Workspace"):FindFirstChild("Entities").ChildAdded:Connect(function()
			for i,v in pairs(game:GetService("Workspace").Entities:GetChildren()) do
				if v ~= nil and v:FindFirstChildOfClass('Humanoid') then
					MakeEntityESP(v)
				end
			end
		end)
	end)
	
	local InteractsESP = false
	GameStuffSection:CreateToggle("Interacts ESP",function()
		if InteractsESP == false then
			InteractsESP = true
			
			library:CoreNotification(tostring(info.Name),"Enabled Interacts ESP!")
			for i,v in pairs(game:GetService("Workspace").Ignored.Interacts:GetChildren()) do
				if not v:IsA("Folder") and InteractsESP then
					MakePartESP(v)
				end
			end
			
		elseif InteractsESP == true then
			InteractsESP = false
			
			library:CoreNotification(tostring(info.Name),"Disabled Interacts ESP!")
			for i,v in pairs(game:GetService("Workspace").Ignored.Interacts:GetDescendants()) do
				if v:IsA("Highlight") and v.Name == v..'_PESP' then
					if not v:IsA("Folder") and not InteractsESP then
						v:Destroy()
					end
				end
			end
		end
	end)
	
	pcall(function()
		game:GetService("Workspace"):FindFirstChild("Ignored").Interacts.ChildAdded:Connect(function()
			for i,v in pairs(game:GetService("Workspace").Ignored.Interacts:GetChildren()) do
				if not v:IsA("Folder") and InteractsESP then
					MakePartESP(v)
				end
			end
		end)
	end)
	
	local function x(v)
		if v then
			for _, v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') then
					v.LocalTransparencyModifier = 0.5
				end
			end
		else
			for _,v in pairs(workspace:GetDescendants()) do
				if v:IsA("BasePart") and not v.Parent:FindFirstChildOfClass('Humanoid') and not v.Parent.Parent:FindFirstChildOfClass('Humanoid') then
					v.LocalTransparencyModifier = 0
				end
			end
		end
	end

	local Xrays = false
	GameStuffSection:CreateToggle("Xrays", function(arg)
		if Xrays == false then
			Xrays = true

			x(Xrays)
			library:CoreNotification(tostring(info.Name),"Enabled Xrays!")

		elseif Xrays == true then
			Xrays = false

			x(Xrays)
			library:CoreNotification(tostring(info.Name),"Disabled Xrays!")
		end
	end)
	
	local GameStuffSection2 = GameStuff:CreateSection("Features")
	
	local Bright = false

	local function MakeBright()
		if Bright == false then
			
			Lighting.Ambient = Color3.fromRGB(88, 88, 88)
			Lighting.OutdoorAmbient = Color3.fromRGB(17, 17, 17)
			Lighting.ClockTime = 0
			
			if library:GetStorage():FindFirstChildOfClass("Atmosphere") then 
				library:GetStorage():FindFirstChildOfClass("Atmosphere").Parent = Lighting
			end
			
		elseif Bright == true then
			
			Lighting.Ambient = Color3.fromRGB(255, 255, 255)
			Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
			Lighting.ClockTime = 14
			
			if Lighting:FindFirstChildOfClass("Atmosphere") then
				Lighting:FindFirstChildOfClass("Atmosphere").Parent = library:GetStorage()
			end			
		end
	end
	
	GameStuffSection2:CreateToggle("Remove Fog & Darkness", function()
		if Bright == false then
			Bright = true
			
			
			MakeBright()
			library:CoreNotification(tostring(info.Name),"Lighting has been set to default!")
			
		elseif Bright == true then
			Bright = false
			
			MakeBright()
			library:CoreNotification(tostring(info.Name),"Lighting has been set to brightness!")
		end
		
		Lighting.Changed:Connect(function()
			if Bright == true then
				MakeBright()
			end
		end)
	end)
	
	GameStuffSection2:CreateButton("Better Flashlight", function()
		game:GetService("RunService").RenderStepped:Connect(function()
			if game:GetService("Workspace").Camera:FindFirstChild(Player.Name.."-cameraLight").isOn.Value == true then
				game:GetService("Workspace").Camera:FindFirstChild(Player.Name.."-cameraLight").Attachment.Light.Brightness = 8
			end
		end)
	end)
	
	local GameStuffSection3 = GameStuff:CreateSection("Levels")
	
	GameStuffSection3:CreateButton("Win Nivel 0", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("0") then
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-900.474121, 11.6797581, -92.6382675, -0.0974363089, -6.39630287e-08, -0.995241761, -7.19740569e-08, 1, -5.72224259e-08, 0.995241761, 6.6056046e-08, -0.0974363089) + Vector3.new(0, 0, 2)
		else
			library:CoreNotification(tostring(info.Name), "Error level 0 not found!")
		end
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 1", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("1") then
			lookDown()
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-793.850037, -151.622299, -1064.25256, -0.996208489, -3.70349582e-08, -0.0869976729, -3.45077567e-08, 1, -3.05529362e-08, 0.0869976729, -2.74349983e-08, -0.996208489) + Vector3.new(0, -5, 0)
		else
			library:CoreNotification(tostring(info.Name), "Error level 1 not found!")
		end		
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 2", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("2") then
			lookDown()
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-583.516479, -176.937714, -2537.09717, 0.9761042, 3.80586158e-08, -0.217303112, -4.97488024e-08, 1, -4.83260436e-08, 0.217303112, 5.7981822e-08, 0.9761042) + Vector3.new(0, 0, -5)
		else
			library:CoreNotification(tostring(info.Name), "Error level 2 not found!")
		end
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 3", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("3") then
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(605.852722, 6.11551285, -107.700623, 0.0369290411, 2.70137246e-08, 0.999317884, -9.26398585e-08, 1, -2.36087274e-08, -0.999317884, -9.17048268e-08, 0.0369290411) + Vector3.new(-2, 0, 0)
		else
			library:CoreNotification(tostring(info.Name), "Error level 3 not found!")
		end
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 4", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("4") then
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-2209.50757, -51.0735779, 558.133484, 0.0311232321, -3.51010883e-08, 0.999515533, -9.50273815e-08, 1, 3.80770935e-08, -0.999515533, -9.61664242e-08, 0.0311232321) + Vector3.new(-8, 0, 0)
		else
			library:CoreNotification(tostring(info.Name), "Error level 4 not found!")
		end		
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 5", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("5") then
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-609.675781, 10.8961239, 3563.83813, 0.997318447, -2.38395997e-10, 0.0731843337, 2.34878367e-10, 1, 5.66718894e-11, -0.0731843337, -3.93305041e-11, 0.997318447) + Vector3.new(0, 0, -5)
		else
			library:CoreNotification(tostring(info.Name), "Error level 5 not found!")
		end
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 6", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("6") then
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(2578.12231, 2.04531336, -2565.16943, -0.999633908, -7.39856532e-08, 0.0270570181, -7.46393241e-08, 1, -2.31492159e-08, -0.0270570181, -2.51602579e-08, -0.999633908) + Vector3.new(0, 0, 8)
		else
			library:CoreNotification(tostring(info.Name), "Error level 6 not found!")
		end
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 7", function()
		library:CoreNotification(tostring(info.Name), "Error trying to Teleport to the exit")
		
		--[[
		wait(2)

		local Viewport = workspace.CurrentCamera.ViewportSize

		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1016.43652, 2.04531336, -2806.32739, -0.346844345, -5.54511068e-08, -0.937922716, -2.92374462e-08, 1, -4.83091682e-08, 0.937922716, 1.06667031e-08, -0.346844345)
		workspace.Camera.CFrame = CFrame.new(1016.43652, 2.04531336, -2806.32739, -0.346844345, -5.54511068e-08, -0.937922716, -2.92374462e-08, 1, -4.83091682e-08, 0.937922716, 1.06667031e-08, -0.346844345)

		wait(2)

		--local Viewport = workspace.CurrentCamera.ViewportSize
		--mousemoveabs(Viewport.X / 2, Viewport.Y / 2)

		wait(2)

		mouse1click()

		wait(1)
		
		-- dont work
		
		--mouse1click()
		keypress(0x59)
		keyrelease(0x59)

		wait(1)

		mousemoveabs(Viewport.X / 2, Viewport.Y / 1.78)

		wait(1)

		mousemoveabs(Viewport.X / 2.1, Viewport.Y / 1.77)

		wait(2)

		mouse1click()

		wait(1)

		mouse1click()

		wait(5)

		print("door opened!")
		--game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(1176.67139, 2.04531312, -2944.45605, 0.999001563, 1.72250996e-08, -0.0446767546, -2.05519104e-08, 1, -7.40047241e-08, 0.0446767546, 7.48490265e-08, 0.999001563) + Vector3.new(0, 0, -5)
		]]--
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 8", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("8") then
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-3173.68359, 10.8319893, -211.152069, -0.999660015, -1.49546224e-08, -0.0260730945, -1.42643195e-08, 1, -2.66616844e-08, 0.0260730945, -2.62807056e-08, -0.999660015) + Vector3.new(0, 0, 2)
		else
			library:CoreNotification(tostring(info.Name), "Error level 8 not found!")
		end
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 9", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("9") then
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(3794.20166, 51.8909607, -442.522736, 0.0164151266, -3.45828894e-08, 0.999865234, 1.12382397e-08, 1, 3.44030475e-08, -0.999865234, 1.06719957e-08, 0.0164151266) + Vector3.new(-2, 0, 0)
		else
			library:CoreNotification(tostring(info.Name), "Error level 9 not found!")
		end
	end)
	
	GameStuffSection3:CreateButton("Win Nivel 10", function()
		library:CoreNotification(tostring(info.Name), "Error trying to Teleport to the exit")
	end)
	
	local GameStuffSection4 = GameStuff:CreateSection("Badges")
	
	GameStuffSection4:CreateButton("Ben Chair (Level 0 Only!)", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("0") then
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-236.810028, 7.07423782, -811.105957, -0.999940932, -3.39150361e-08, -0.0108689293, -3.32854029e-08, 1, -5.8110647e-08, 0.0108689293, -5.77454387e-08, -0.999940932)
		else
			library:CoreNotification(tostring(info.Name), "Error Ben's Chair not found!")
		end
	end)
	
	GameStuffSection4:CreateButton("Lost Soul (Level 0 Only!)", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("0") then
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-693.927185, 5.16907215, -333.976501, 0.00564997224, -1.17897265e-08, -0.999984086, -6.20399554e-09, 1, -1.18249677e-08, 0.999984086, 6.27070706e-09, 0.00564997224)
		else
			library:CoreNotification(tostring(info.Name), "Error Soul not found!")
		end
	end)
	
	local OldPos
	GameStuffSection4:CreateButton("Collect all Simulation Cores (Level 0 Only!)", function()
		if game:GetService("Workspace").Buildings:FindFirstChild("0") then
			
			OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
			wait(1)			
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-236.655273, 5.1690712, -815.520569, -0.999984205, -4.65599257e-08, -0.00561929727, -4.67444821e-08, 1, 3.27117746e-08, 0.00561929727, 3.29739294e-08, -0.999984205)			
			wait()
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-490.717102, 5.16907215, -638.06665, -0.0554201417, -4.86189666e-09, -0.998463094, -9.11751954e-08, 1, 1.91339611e-10, 0.998463094, 9.10456706e-08, -0.0554201417)
			
			getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
			
			repeat wait(1) until game:GetService("Workspace").Buildings:FindFirstChild("1")
			
			OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
			wait(1)
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-1053.96997, -29.4202404, -1142.80811, 0.0436958224, -2.63774815e-08, -0.999044895, -9.26734511e-09, 1, -2.68080296e-08, 0.999044895, 1.04298925e-08, 0.0436958224)
			
			getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
			
			repeat wait(1) until game:GetService("Workspace").Buildings:FindFirstChild("3")
			
			OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
			wait(1)
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(566.490479, 4.52199173, -322.884216, 0.0105115809, 1.65510876e-08, -0.999944746, 6.19649825e-08, 1, 1.72033889e-08, 0.999944746, -6.21423908e-08, 0.0105115809)
			wait()
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(621.600952, 5.11445522, -118.770676, 0.0522793755, 3.19209299e-08, 0.99863255, 1.12718288e-08, 1, -3.2554734e-08, -0.99863255, 1.29583553e-08, 0.0522793755)
			
			getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
			
			repeat wait(1) until game:GetService("Workspace").Buildings:FindFirstChild("4")

			OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
			wait(1)
			
			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-1894.05701, -50.9735718, 463.954468, 0.0237002466, 1.44570578e-08, 0.999719143, 3.6350658e-09, 1, -1.45472949e-08, -0.999719143, 3.9788195e-09, 0.0237002466)

			getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
			
			repeat wait(1) until game:GetService("Workspace").Buildings:FindFirstChild("5")

			OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
			wait(1)

			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(-370.765869, 11.2919006, 4090.83301, 0.0595045127, -1.10110951e-08, 0.998228014, -3.54791077e-08, 1, 1.31455558e-08, -0.998228014, -3.61984611e-08, 0.0595045127)

			getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
			
			repeat wait(1) until game:GetService("Workspace").Buildings:FindFirstChild("9")

			OldPos = getRoot(game.Players.LocalPlayer.Character).CFrame
			wait(1)

			getRoot(game.Players.LocalPlayer.Character).CFrame = CFrame.new(3805.65381, 51.033432, -357.305664, 0.0737505034, -8.99931507e-08, -0.997276723, -7.1083349e-08, 1, -9.54956434e-08, 0.997276723, 7.79326186e-08, 0.0737505034)

			getRoot(game.Players.LocalPlayer.Character).CFrame = OldPos
		else
			library:CoreNotification(tostring(info.Name), "Error Core1 not found!")
		end
	end)
end

function SuperBombSurvival_Scripts()
	local GameStuff = Window:CreatePage("SBS", 4621599120, 3)
	
	local InLobby = false
	local OldCFrame = nil
	
	local GameStuffSection = GameStuff:CreateSection("Game Mods")
	
	local AntiRagdoll = false
	GameStuffSection:CreateToggle("Anti Ragdoll", function(arg)
		if AntiRagdoll  then
			AntiRagdoll = false
		else
			AntiRagdoll = true
		end
		
		RS.RenderStepped:Connect(function()
			if AntiRagdoll then
				game:GetService("ReplicatedStorage").Remotes.Ragdoll:FireServer("off")
			end
		end)
	end)
	
	local BombEffects = false
	GameStuffSection:CreateToggle("Dsaible Some Bomb Effects", function(arg)
		if BombEffects  then
			AntiRagdoll = false
		else
			BombEffects = true
		end

		RS.RenderStepped:Connect(function()
			if BombEffects then
				local Plr_Character = Player.Character or Player.ChildAdded:Wait()
				
				Plr_Character.ChildAdded:Connect(function(Child)
					if Child:IsA("BoolValue") and Child.Name == "confused" then
						Child:Destroy()
					end
				end)
			end
		end)
	end)
	
	local GameStuffSection2 = GameStuff:CreateSection("Pickups")
	
	GameStuffSection2:CreateButton("Charge Power Up", function()
		for i,v in pairs(game:GetService("Workspace").Bombs:GetChildren()) do
			if v.Name == "ChargeSoda" then
				OldCFrame = getRoot(game.Players.LocalPlayer.Character).CFrame
				v.CanCollide = false
				
				getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
				wait()
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
				return
			end
		end
	end)
	
	GameStuffSection2:CreateButton("Heal Yourself", function()
		for i,v in pairs(game:GetService("Workspace").Bombs:GetChildren()) do
			if v.Name == "Pizza" then
				OldCFrame = getRoot(game.Players.LocalPlayer.Character).CFrame
				v.CanCollide = false
				
				getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
				wait()
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
				return
				
			elseif v.Name == "PizzaBox" then
				OldCFrame = getRoot(game.Players.LocalPlayer.Character).CFrame
				v.CanCollide = false
				
				getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
				wait()
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
				return
			end
		end
	end)
	
	GameStuffSection2:CreateButton("Grab FireShield", function()
		for i,v in pairs(game:GetService("Workspace").Bombs:GetChildren()) do
			if v.Name == "FireShield" then
				OldCFrame = getRoot(game.Players.LocalPlayer.Character).CFrame
				v.CanCollide = false

				getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
				wait()
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
				return
			end
		end
	end)
	
	GameStuffSection2:CreateButton("Grab MagicShield", function()
		for i,v in pairs(game:GetService("Workspace").Bombs:GetChildren()) do
			if v.Name == "MagicShield" then
				OldCFrame = getRoot(game.Players.LocalPlayer.Character).CFrame
				v.CanCollide = false

				getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
				wait()
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
				return
			end
		end
	end)
	
	GameStuffSection2:CreateButton("Grab HeartPickup", function()
		for i,v in pairs(game:GetService("Workspace").Bombs:GetChildren()) do
			if v.Name == "HeartPickup" then
				OldCFrame = getRoot(game.Players.LocalPlayer.Character).CFrame
				v.CanCollide = false

				getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
				wait()
				getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
				return
			end
		end
	end)
	
	local GameStuffSection3 = GameStuff:CreateSection("AutoFarm")
	
	local CoinAutoFarm = false
	GameStuffSection3:CreateToggle("Coin AutoFarm", function(arg)
		if CoinAutoFarm  then
			CoinAutoFarm = false
		else
			CoinAutoFarm = true
		end
		
		OldCFrame = getRoot(game.Players.LocalPlayer.Character).CFrame
		
		RS.RenderStepped:Connect(function()
			if CoinAutoFarm == true then
				for i,v in pairs(game:GetService("Workspace").Bombs:GetChildren()) do
					if v.Name == "Coin_silver" or v.Name == "Coin_gold" or v.Name == "Coin_gold2" or v.Name == "Coin_copper" or v.Name == "Coin_event" then
						v.CanCollide = false

						getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
						wait()
						getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
					end
				end

				for i,v in pairs(game:GetService("Workspace"):GetChildren()) do
					if v.Name == "Coin_silver" or v.Name == "Coin_gold" or v.Name == "Coin_gold2" or v.Name == "Coin_copper" or v.Name == "Coin_event" then
						v.CanCollide = false

						getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
						wait()
						getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
					end
				end
			end
		end)
		
		if not CoinAutoFarm then
			getRoot(game.Players.LocalPlayer.Character).CFrame = OldCFrame
		end
	end)
	
	--[[local SurvivalsAutoFarm = false
	GameStuffSection3:CreateToggle("Survivals AutoFarm", function(arg)
		if SurvivalsAutoFarm then
			SurvivalsAutoFarm = false
		else
			SurvivalsAutoFarm = true
		end

		RS.RenderStepped:Connect(function()
			if SurvivalsAutoFarm == true and InLobby == false then
				for i, v in pairs(game:GetService("Workspace").SPAWNS:GetChildren()) do
					if v:IsA("SpawnLocation")  then
						getRoot(game.Players.LocalPlayer.Character).CFrame = v.CFrame
					end
				end
			end
		end)
	end)]]--
	
	game:GetService("ReplicatedStorage").ChildAdded:Connect(function(Child)
		if Child:IsA("Model") and Child.Name == "Decor" and InLobby == true then
			InLobby = false
		end
	end)
	
	
	game:GetService("ReplicatedStorage").ChildRemoved:Connect(function(Child)
		if Child:IsA("Model") and Child.Name == "Decor" and InLobby == false then
			InLobby = true
		end
	end)
end

function RaiseFloppa_Scripts()
	local function fireproximityprompt(Obj, Amount, Skip)
		if Obj.ClassName == "ProximityPrompt" then 
			Amount = Amount or 1
			local PromptTime = Obj.HoldDuration
			if Skip then 
				Obj.HoldDuration = 0
			end
			for i = 1, Amount do 
				Obj:InputHoldBegin()
				if not Skip then 
					wait(Obj.HoldDuration)
				end
				Obj:InputHoldEnd()
			end
			Obj.HoldDuration = PromptTime
		else 
			error("userdata<ProximityPrompt> expected")
		end
	end
	
	for i,v in pairs(game.Workspace:GetDescendants()) do
		if v:IsA("ProximityPrompt") then 
			v.RequiresLineOfSight = false
		end 
	end

	local function lookDown()
		workspace.Camera.CFrame = CFrame.new(264.744202, 44.9857788, 19.0272675, 0.917633414, -0.391390145, 0.0690128133, 0, 0.173648611, 0.984807611, -0.397428036, -0.903692365, 0.159345)
	end
	
	local GameStuff = Window:CreatePage("Raise a floppa", 4621599120, 3)

	local GameStuffSection = GameStuff:CreateSection("Game Mods")
		
	GameStuffSection:CreateButton("Save game", function()
		library:CoreNotification(tostring(info.Name), "Game Saved!")
		local currentpos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
		
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-81.27365112304688, 7.799998760223389, -24.59555435180664); lookDown(); task.wait(0.3)
		
		fireproximityprompt(game:GetService("Workspace")["Floppy Disk"].ProximityPrompt,1,true)
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = currentpos
	end)
	
	GameStuffSection:CreateButton("Collect all money", function()
		for i,v in pairs(game.Workspace:GetDescendants()) do
			if v.Name == "Money" and v:IsA("MeshPart") then 
				firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart,v,0)
				firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart,v,1)
			end 
		end
	end)
	
	GameStuffSection:CreateButton("Collect all Mushroom", function()
		if game.Workspace:FindFirstChild("Mushroom") then 
			for i,v in pairs(game.Workspace:GetDescendants()) do
				if v.Name == "Mushroom" and v:IsA("MeshPart") then 
					lookDown()
					
					game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.CFrame
					task.wait(0.3)
					fireproximityprompt(v.ForagePrompt,1,true)
					task.wait(0.3)
				end 
			end
		else
			library:CoreNotification(tostring(info.Name), "Outdoor not unlocked yet")
		end
	end)
	
	GameStuffSection:CreateButton("Collect all Meteorite", function()
		if game.Workspace:FindFirstChild("Meteorite") then 
			for i,v in pairs(game.Workspace:GetChildren()) do
				if v.Name == "Meteorite" and v:IsA("Tool") and v:FindFirstChild("Handle") then
					game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = v.Handle.CFrame
					task.wait(0.3)
				end 
			end
		else
			library:CoreNotification(tostring(info.Name), "Outdoor not unlocked yet")
		end
	end)
	
	GameStuffSection:CreateButton("Remove accended obby", function()
		if game.Workspace:FindFirstChild("Temple") then 
			game:GetService("Workspace").Temple.Obby:Destroy()
			library:CoreNotification(tostring(info.Name), "Obby Destroyed!")
		else
			library:CoreNotification(tostring(info.Name), "No obby found (did you accend yet?)")
		end 
	end)

	local GameStuffSection2 = GameStuff:CreateSection("AutoFarm")
	
	local AutoClickFloppa = false
	GameStuffSection2:CreateToggle("Auto Click Floppa", function()
		if AutoClickFloppa  then
			
			AutoClickFloppa = false		
			library:CoreNotification(tostring(info.Name), "Disabled Auto Floppa Click!")
		elseif AutoClickFloppa == false then
			
			AutoClickFloppa = true		
			library:CoreNotification(tostring(info.Name), "Enabled Auto Floppa Click!")
		end
		
		while wait() do 
			if AutoClickFloppa then 
				fireclickdetector(game:GetService("Workspace").Floppa.ClickDetector)
			end
		end
	end)
	
	local AutoConsolateFloppa = false
	GameStuffSection2:CreateToggle("Auto Consolate Floppa", function()
		if AutoConsolateFloppa  then

			AutoConsolateFloppa = false		
			library:CoreNotification(tostring(info.Name), "Disabled Auto Consolate Floppa!")
		elseif AutoConsolateFloppa == false then

			AutoConsolateFloppa = true		
			library:CoreNotification(tostring(info.Name), "Enabled Auto Consolate Floppa!")
		end
		
		local currentpos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame

		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").Floppa.HumanoidRootPart.CFrame
		fireproximityprompt(game:GetService("Workspace").Floppa.HumanoidRootPart.PetPrompt,1,true)

		getRoot(game.Player.LocalPlayer.Character).CFrame = currentpos

		while wait(10) do 
			if AutoConsolateFloppa then
				local currentpos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
				
				game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").Floppa.HumanoidRootPart.CFrame
				fireproximityprompt(game:GetService("Workspace").Floppa.HumanoidRootPart.PetPrompt,1,true)
				
				getRoot(game.Player.LocalPlayer.Character).CFrame = currentpos
			end
		end
	end)
	
	local AutoCollectMoney = false
	local MoneyListener
	
	GameStuffSection2:CreateToggle("Auto collect money", function()
		if AutoCollectMoney  then
			
			AutoCollectMoney = false
			library:CoreNotification(tostring(info.Name), "Disabled Auto Collect Money!")
			
		elseif AutoCollectMoney == false then
			
			AutoCollectMoney = true
			library:CoreNotification(tostring(info.Name), "Enabled Auto Collect Money!")
		end
		
		if AutoCollectMoney then 
			for i,v in pairs(game.Workspace:GetDescendants()) do
				if v.Name == "Money" and v:IsA("MeshPart") then 
					firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart,v,0)
					firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart,v,1)
				end 
			end
		end 
		
		game.Workspace.ChildAdded:Connect(function(Obj)
			if AutoCollectMoney then 
				for i,v in pairs(game.Workspace:GetDescendants()) do
					if v.Name == "Money" and v:IsA("MeshPart") then 
						firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart,v,0)
						firetouchinterest(game.Players.LocalPlayer.Character.HumanoidRootPart,v,1)
					end 
				end
			end 
		end)
	end)
	
	local AutoSave = false
	GameStuffSection2:CreateToggle("Auto Save", function()
		if AutoSave  then
			
			AutoSave = false
			library:CoreNotification(tostring(info.Name), "Disabled Auto Save!")
			
		elseif AutoSave == false then
			
			AutoSave = true		
			library:CoreNotification(tostring(info.Name), "Enabled Auto Save!")
		end
		
		local currentpos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame
		
		library:CoreNotification(tostring(info.Name), "Game Saved!")
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-81.27365112304688, 7.799998760223389, -24.59555435180664); lookDown(); task.wait(0.3)

		fireproximityprompt(game:GetService("Workspace")["Floppy Disk"].ProximityPrompt,1,true)
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = currentpos

		while wait(10) do 
			if AutoSave then 
				local currentpos = game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame

				game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-81.27365112304688, 7.799998760223389, -24.59555435180664); lookDown(); task.wait(0.3)

				fireproximityprompt(game:GetService("Workspace")["Floppy Disk"].ProximityPrompt,1,true)
				game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = currentpos

				library:CoreNotification(tostring(info.Name), "Game Saved!")
			end
		end
	end)
	
	local GameStuffSection2 = GameStuff:CreateSection("Teleports & Shops")
	
	GameStuffSection2:CreateButton("Backrooms shop", function()
		lookDown()
		
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").Backrooms.PC.CFrame
		task.wait(0.3)
		fireproximityprompt(game:GetService("Workspace").Backrooms.PC.ProximityPrompt,1,true)

		library:CoreNotification(tostring(info.Name), "Teleported to Backrooms Shop!")
	end)
	
	GameStuffSection2:CreateButton("Witch shop", function()
		lookDown()
		
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace")["Jinx' Cauldron"]["Jinx Witch"].jinx.CFrame
		task.wait(0.3)
		fireproximityprompt(game:GetService("Workspace")["Jinx' Cauldron"].Cauldron.Cauldron.ProximityPrompt,1,true)
		
		library:CoreNotification(tostring(info.Name), "Teleported to Witch shop!")
	end)
	
	GameStuffSection2:CreateButton("Alien shop", function()
		lookDown()

		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").Alien.HumanoidRootPart.CFrame
		task.wait(0.3)
		fireproximityprompt(game:GetService("Workspace").Alien.HumanoidRootPart.ProximityPrompt,1,true)

		library:CoreNotification(tostring(info.Name), "Teleported to Alien shop!")
	end)
	
	GameStuffSection2:CreateButton("Teleport to Backrooms", function()
		lookDown()
		
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-12558.9306640625, 57.98476028442383, -16148.994140625)
		library:CoreNotification(tostring(info.Name), "Teleported to Backrooms!")
	end)
	
	GameStuffSection2:CreateButton("Go home", function()
		game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").HomeTeleport.CFrame
		library:CoreNotification(tostring(info.Name), "Teleported to Home!")
	end)
	
	local GameStuffSection3 = GameStuff:CreateSection("Misc")
	
	local Almond = 0
	local Money_Required = 0
	
	GameStuffSection3:CreateSlider("Set Almond Amount", 1, 25, function(arg)
		Almond = arg
		Money_Required = arg * 1000 
	end)
	
	GameStuffSection3:CreateButton("Buy Almond Water", function()
		if tonumber(game.Players.LocalPlayer.leaderstats2.Money.Value) < Money_Required then 
			library:CoreNotification(tostring(info.Name), "Oops, Not enough money!")
		else
			lookDown()
			
			local counter =  0 
			
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").Backrooms.PC.CFrame
			task.wait(0.3)
			fireproximityprompt(game:GetService("Workspace").Backrooms.PC.ProximityPrompt,1,true);
			task.wait(0.3)
			
			while counter ~= Almond do 
				game:GetService("ReplicatedStorage").Purchase2:FireServer("Almond Water")
				counter = counter + 1
			end
			
			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = game:GetService("Workspace").HomeTeleport.CFrame
		end
	end)
	
	GameStuffSection3:CreateButton("Max Altar (uses all cash)", function()
		if game.Workspace:FindFirstChild("Altar") then 
			library:CoreNotification(tostring(info.Name), "Setting up altar..")

			game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-59.9468994, 7.80000067, -51.4093704, 0.732256234, 2.32286883e-08, -0.681029201, -2.72008407e-08, 1, 4.8613229e-09, 0.681029201, 1.49648329e-08, 0.732256234)
			task.wait(0.3)
			lookDown()

			task.wait(0.3)
			local thing = 0

			while thing < 50 do 
				game.Players.LocalPlayer.Character.HumanoidRootPart.CFrame = CFrame.new(-59.9468994, 7.80000067, -51.4093704, 0.732256234, 2.32286883e-08, -0.681029201, -2.72008407e-08, 1, 4.8613229e-09, 0.681029201, 1.49648329e-08, 0.732256234)
				lookDown()

				fireproximityprompt(game:GetService("Workspace").Altar["Thin Wall"].ProximityPrompt,1,true)
				task.wait(0.3)
				thing = thing +1 
			end

			library:CoreNotification(tostring(info.Name), "Finished offering..")

			task.wait(3)

			library:CoreNotification(tostring(info.Name), "Done!")
		else			
			library:CoreNotification(tostring(info.Name), "Altar not found!")
		end 
	end)
end

spawn(function()
	if game.PlaceId == 6053107323 then
		
		TRNE_Scripts()
		
		for i, v in pairs(game:GetDescendants()) do wait() end
		library:Notify("Infinity Hub", "Game Supported!\nEnjoy the game features, Game: "..tostring(info.Name), "Normal")
	elseif game.PlaceId == 1962086868 then
		
		TOH_Scripts()
		
		for i, v in pairs(game:GetDescendants()) do wait() end
		library:Notify("Infinity Hub", "Game Supported!\nEnjoy the game features, Game: "..tostring(info.Name), "Normal")
	elseif game.PlaceId == 189707 then
		NDS_Scripts()
		
		for i, v in pairs(game:GetDescendants()) do wait() end
		library:Notify("Infinity Hub", "Game Supported!\nEnjoy the game features, Game: "..tostring(info.Name), "Normal")
	elseif game.PlaceId == 9508108517 then
		
		Apeirophobia_Scripts()
		
		for i, v in pairs(game:GetDescendants()) do wait() end
		library:Notify("Infinity Hub", "Game Supported!\nEnjoy the game features, Game: "..tostring(info.Name), "Normal")
		
	elseif game.PlaceId == 164051105 then
		
		
		SuperBombSurvival_Scripts()
		
		for i, v in pairs(game:GetDescendants()) do wait() end
		library:Notify("Infinity Hub", "Game Supported!\nEnjoy the game features, Game: "..tostring(info.Name), "Normal")
		
	elseif game.PlaceId == 9203864304 then
		
		RaiseFloppa_Scripts()

		for i, v in pairs(game:GetDescendants()) do wait() end
		library:Notify("Infinity Hub", "Game Supported!\nEnjoy the game features, Game: "..tostring(info.Name), "Normal")
		
	elseif game.PlaceId == 7157823351 then
		TRNE_Scripts()

		TOH_Scripts()

		NDS_Scripts()

		Apeirophobia_Scripts()
		
		SuperBombSurvival_Scripts()
		
		for i, v in pairs(game:GetDescendants()) do wait() end
		library:Notify("Infinity Hub", "Testing Place Detected!\nLoaded all games features, Game: "..tostring(info.Name), "Normal")
	end
end)

_G.InfinityHub_Data_ExperimentalUsers = {
	["xii01_Alxn"] = 2737327936,
	["D4RK_M4N3"] = 2796084622,
	["lIMURD3RIl"] = 1545065123,
	
	-- Alt Accounts
	
	["y7105h2j58r5t4y147h"] = 2887394147,
}

spawn(function()
	for i, v in pairs(_G.InfinityHub_Data_ExperimentalUsers) do
		if Player.UserId == v then		
			
			local Experimental = Window:CreatePage("Experimental", 7072707647, 8)
			local ExperimentalSection = Experimental:CreateSection("Experimental")
			
			ExperimentalSection:CreateButton("Beta Features")
			
			ExperimentalSection:CreateButton("There is no Beta Features for now!, come back later..")
		end
	end
end)

local Scripts = Window:CreatePage("Scripts", 7072707514, 2)
local ScriptsSection = Scripts:CreateSection("Scripts")

ScriptsSection:CreateScriptInfoButton(6053107323, "Ok") -- The Rake: Noob Edition

ScriptsSection:CreateScriptInfoButton(1962086868, "Ok") -- Tower of Hell

ScriptsSection:CreateScriptInfoButton(189707, "Ok") -- Natural Disaster Survival

ScriptsSection:CreateScriptInfoButton(10277607801, "Ok") -- Apeirophobia

ScriptsSection:CreateScriptInfoButton(164051105, "Ok") -- SuperBombSurvival

while wait(1) do
	FPSBtn:UpdateButton("FPS: "..FPS)
	FPS = 0
end