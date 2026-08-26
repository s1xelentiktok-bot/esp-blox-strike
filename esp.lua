--========================================================--
--           BLOX STRIKE - ADVANCED ESP & AIMLOCK         --
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local AIM_HOLDING = false

--========================================================--
-- CONFIG
--========================================================--

local Config = {
	ESP = {
		Enabled = false,
		FillColor = Color3.fromRGB(255, 55, 55),
		FillTransparency = 0.75,
		OutlineColor = Color3.fromRGB(255, 255, 255),
		OutlineTransparency = 0,
	},

	TeamCheck = {
		Enabled = false,
	},

	Aim = {
		Enabled = false,
		FOVRadius = 250,
		MaxDistance = 2000,
	},

	Keys = {
		Aim = Enum.KeyCode.LeftAlt,
		Menu = Enum.KeyCode.RightAlt,
	},

	UI = {
		MenuPosition = UDim2.fromOffset(25, 25),
	},
}

--========================================================--
-- CAMERA & STORAGE
--========================================================--

local Camera = workspace.CurrentCamera

local function getCamera()
	Camera = workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
	return Camera
end

-- Удаляем старый ESP если скрипт перезапускался
if workspace:FindFirstChild("BloxStrikeESP") then
	workspace.BloxStrikeESP:Destroy()
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "BloxStrikeESP"
ESPFolder.Parent = workspace

local ESPObjects = {}

--========================================================--
-- TEAM CHECK LOGIC
--========================================================--

local function isEnemy(player)
	if not player or player == LocalPlayer then
		return false
	end

	if not Config.TeamCheck.Enabled then
		return true
	end

	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		return LocalPlayer.Team ~= player.Team
	end

	if LocalPlayer.TeamColor and player.TeamColor then
		return LocalPlayer.TeamColor ~= player.TeamColor
	end

	return true
end

--========================================================--
-- ESP SYSTEM
--========================================================--

local function removeESP(player)
	local data = ESPObjects[player]
	if data then
		if data.Highlight then
			data.Highlight:Destroy()
		end
		ESPObjects[player] = nil
	end
end

local function createESP(player)
	removeESP(player)

	if not Config.ESP.Enabled or not isEnemy(player) then return end

	local character = player.Character
	if not character or not character:FindFirstChildOfClass("Humanoid") then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_" .. player.Name
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillColor = Config.ESP.FillColor
	highlight.FillTransparency = Config.ESP.FillTransparency
	highlight.OutlineColor = Config.ESP.OutlineColor
	highlight.OutlineTransparency = Config.ESP.OutlineTransparency
	highlight.Parent = ESPFolder

	ESPObjects[player] = { Highlight = highlight }
end

local function refreshESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			if Config.ESP.Enabled and isEnemy(player) then
				createESP(player)
			else
				removeESP(player)
			end
		end
	end
end

--========================================================--
-- AIMLOCK LOGIC (BODY TARGET + THROUGH WALLS)
--========================================================--

local function getTargetBodyPart(character)
	if not character then return nil end
	return character:FindFirstChild("UpperTorso") 
		or character:FindFirstChild("Torso") 
		or character:FindFirstChild("HumanoidRootPart")
end

local function getClosestEnemyPlayer()
	local cam = getCamera()
	if not cam then return nil end

	local mousePos = UserInputService:GetMouseLocation()
	local closestPart = nil
	local shortestDistance = Config.Aim.FOVRadius

	for _, player in ipairs(Players:GetPlayers()) do
		if isEnemy(player) and player.Character then
			local char = player.Character
			local humanoid = char:FindFirstChildOfClass("Humanoid")
			local targetPart = getTargetBodyPart(char)

			if humanoid and humanoid.Health > 0 and targetPart then
				local myChar = LocalPlayer.Character
				local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
				
				local dist3D = myRoot and (targetPart.Position - myRoot.Position).Magnitude or 0
				if dist3D <= Config.Aim.MaxDistance then
					local screenPos, onScreen = cam:WorldToViewportPoint(targetPart.Position)
					
					if onScreen then
						local screenVec = Vector2.new(screenPos.X, screenPos.Y)
						local distanceToMouse = (screenVec - mousePos).Magnitude

						if distanceToMouse < shortestDistance then
							shortestDistance = distanceToMouse
							closestPart = targetPart
						end
					end
				end
			end
		end
	end

	return closestPart
end

--========================================================--
-- GUI INITIALIZATION
--========================================================--

if PlayerGui:FindFirstChild("BloxStrikeGui") then
	PlayerGui.BloxStrikeGui:Destroy()
end

local Gui = Instance.new("ScreenGui")
Gui.Name = "BloxStrikeGui"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

--========================================================--
-- WELCOME NOTIFICATION (ВСПЛЫВАЮЩЕЕ ПРИВЕТСТВИЕ)
--========================================================--

local WelcomeFrame = Instance.new("Frame")
WelcomeFrame.Name = "WelcomeFrame"
WelcomeFrame.Size = UDim2.fromOffset(320, 65)
WelcomeFrame.Position = UDim2.new(0.5, -160, 0.4, 0)
WelcomeFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
WelcomeFrame.BackgroundTransparency = 1
WelcomeFrame.BorderSizePixel = 0
WelcomeFrame.ZIndex = 100
WelcomeFrame.Parent = Gui

local WelcomeCorner = Instance.new("UICorner")
WelcomeCorner.CornerRadius = UDim.new(0, 12)
WelcomeCorner.Parent = WelcomeFrame

local WelcomeStroke = Instance.new("UIStroke")
WelcomeStroke.Thickness = 1.5
WelcomeStroke.Color = Color3.fromRGB(255, 60, 60)
WelcomeStroke.Transparency = 1
WelcomeStroke.Parent = WelcomeFrame

local WelcomeTitle = Instance.new("TextLabel")
WelcomeTitle.Size = UDim2.new(1, 0, 0.5, 0)
WelcomeTitle.Position = UDim2.fromScale(0, 0.1)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Text = "BLOX STRIKE"
WelcomeTitle.TextColor3 = Color3.fromRGB(255, 60, 60)
WelcomeTitle.TextSize = 18
WelcomeTitle.Font = Enum.Font.GothamBold
WelcomeTitle.TextTransparency = 1
WelcomeTitle.ZIndex = 101
WelcomeTitle.Parent = WelcomeFrame

local WelcomeSub = Instance.new("TextLabel")
WelcomeSub.Size = UDim2.new(1, 0, 0.4, 0)
WelcomeSub.Position = UDim2.fromScale(0, 0.55)
WelcomeSub.BackgroundTransparency = 1
WelcomeSub.Text = "Script Successfully Loaded!"
WelcomeSub.TextColor3 = Color3.fromRGB(220, 220, 220)
WelcomeSub.TextSize = 13
WelcomeSub.Font = Enum.Font.GothamMedium
WelcomeSub.TextTransparency = 1
WelcomeSub.ZIndex = 101
WelcomeSub.Parent = WelcomeFrame

-- Анимация всплытия приветствия
task.spawn(function()
	local tweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	
	TweenService:Create(WelcomeFrame, tweenInfo, {BackgroundTransparency = 0.15, Position = UDim2.new(0.5, -160, 0.45, 0)}):Play()
	TweenService:Create(WelcomeStroke, tweenInfo, {Transparency = 0}):Play()
	TweenService:Create(WelcomeTitle, tweenInfo, {TextTransparency = 0}):Play()
	TweenService:Create(WelcomeSub, tweenInfo, {TextTransparency = 0}):Play()

	task.wait(2.5)

	local tweenOut = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	TweenService:Create(WelcomeFrame, tweenOut, {BackgroundTransparency = 1, Position = UDim2.new(0.5, -160, 0.4, 0)}):Play()
	TweenService:Create(WelcomeStroke, tweenOut, {Transparency = 1}):Play()
	TweenService:Create(WelcomeTitle, tweenOut, {TextTransparency = 1}):Play()
	TweenService:Create(WelcomeSub, tweenOut, {TextTransparency = 1}):Play()

	task.wait(0.5)
	WelcomeFrame:Destroy()
end)

--========================================================--
-- MAIN MENU (LEFT TOP)
--========================================================--

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(260, 255)
Main.Position = Config.UI.MenuPosition
Main.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 10
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1.5
MainStroke.Color = Color3.fromRGB(45, 45, 55)
MainStroke.Parent = Main

-- Title Header
local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLOX STRIKE"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.TextSize = 17
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 11
Title.Parent = Main

local TitleSub = Instance.new("TextLabel")
TitleSub.Size = UDim2.new(1, -20, 0, 40)
TitleSub.Position = UDim2.fromOffset(120, 0)
TitleSub.BackgroundTransparency = 1
TitleSub.Text = "|  CHEAT MENU"
TitleSub.TextColor3 = Color3.fromRGB(130, 130, 140)
TitleSub.TextSize = 13
TitleSub.Font = Enum.Font.GothamMedium
TitleSub.TextXAlignment = Enum.TextXAlignment.Left
TitleSub.ZIndex = 11
TitleSub.Parent = Main

-- Перетаскивание Меню
do
	local dragging, dragStart, startPosition
	Title.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPosition = Main.Position
		end
	end)
	Title.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(
				startPosition.X.Scale,
				startPosition.X.Offset + delta.X,
				startPosition.Y.Scale,
				startPosition.Y.Offset + delta.Y
			)
		end
	end)
end

-- Кнопки
local function createButton(name, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, -24, 0, 36)
	button.Position = UDim2.fromOffset(12, y)
	button.BackgroundColor3 = Color3.fromRGB(32, 24, 28)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(255, 80, 80)
	button.TextSize = 13
	button.Font = Enum.Font.GothamBold
	button.ZIndex = 20
	button.AutoButtonColor = false
	button.Parent = Main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = button

	local stroke = Instance.new("UIStroke")
	stroke.Thickness = 1
	stroke.Color = Color3.fromRGB(70, 35, 35)
	stroke.Parent = button

	return button, stroke
end

local ESPButton, ESPStroke = createButton("ESP", 45)
local TeamButton, TeamStroke = createButton("Team", 88)
local AimButton, AimStroke = createButton("Aim", 131)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -24, 0, 40)
Info.Position = UDim2.fromOffset(12, 180)
Info.BackgroundTransparency = 1
Info.Text = "[Left Alt] — Hold Aim Lock\n[Right Alt] — Hide / Show Menu"
Info.TextColor3 = Color3.fromRGB(110, 110, 120)
Info.TextSize = 11
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.ZIndex = 11
Info.Parent = Main

local function updateButton(button, stroke, title, enabled)
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if enabled then
		button.Text = title .. "  [ ON ]"
		TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(24, 45, 32), TextColor3 = Color3.fromRGB(80, 255, 140)}):Play()
		TweenService:Create(stroke, tweenInfo, {Color = Color3.fromRGB(40, 120, 65)}):Play()
	else
		button.Text = title .. "  [ OFF ]"
		TweenService:Create(button, tweenInfo, {BackgroundColor3 = Color3.fromRGB(38, 24, 28), TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
		TweenService:Create(stroke, tweenInfo, {Color = Color3.fromRGB(90, 35, 35)}):Play()
	end
end

local function updateButtons()
	updateButton(ESPButton, ESPStroke, "PLAYER ESP", Config.ESP.Enabled)
	updateButton(TeamButton, TeamStroke, "TEAM CHECK", Config.TeamCheck.Enabled)
	updateButton(AimButton, AimStroke, "AIM LOCK", Config.Aim.Enabled)
end

-- FOV Circle
local FOV = Instance.new("Frame")
FOV.Name = "FOV"
FOV.Size = UDim2.fromOffset(Config.Aim.FOVRadius * 2, Config.Aim.FOVRadius * 2)
FOV.AnchorPoint = Vector2.new(0.5, 0.5)
FOV.BackgroundTransparency = 1
FOV.Visible = false
FOV.ZIndex = 2
FOV.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOV

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 1.2
FOVStroke.Transparency = 0.4
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Parent = FOV

--========================================================--
-- BUTTON EVENTS
--========================================================--

ESPButton.MouseButton1Click:Connect(function()
	Config.ESP.Enabled = not Config.ESP.Enabled
	refreshESP()
	updateButtons()
end)

TeamButton.MouseButton1Click:Connect(function()
	Config.TeamCheck.Enabled = not Config.TeamCheck.Enabled
	refreshESP()
	updateButtons()
end)

AimButton.MouseButton1Click:Connect(function()
	Config.Aim.Enabled = not Config.Aim.Enabled
	FOV.Visible = Config.Aim.Enabled
	if not Config.Aim.Enabled then
		AIM_HOLDING = false
	end
	updateButtons()
end)

--========================================================--
-- INPUT & TOGGLE MENU
--========================================================--

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end

	if input.KeyCode == Config.Keys.Aim then
		AIM_HOLDING = true
	elseif input.KeyCode == Config.Keys.Menu then
		Main.Visible = not Main.Visible
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Config.Keys.Aim then
		AIM_HOLDING = false
	end
end)

--========================================================--
-- LISTENERS
--========================================================--

local function setupPlayer(player)
	if player == LocalPlayer then return end

	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if Config.ESP.Enabled then
			createESP(player)
		end
	end)

	player.CharacterRemoving:Connect(function()
		removeESP(player)
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		task.wait(0.1)
		refreshESP()
	end)
end

for _, player in ipairs(Players:GetPlayers()) do
	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)
Players.PlayerRemoving:Connect(function(player)
	removeESP(player)
end)

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
	task.wait(0.1)
	refreshESP()
end)

--========================================================--
-- RENDER LOOP (AIMLOCK EXECUTION & FOV)
--========================================================--

RunService.RenderStepped:Connect(function()
	if Config.Aim.Enabled then
		local mousePos = UserInputService:GetMouseLocation()
		FOV.Position = UDim2.fromOffset(mousePos.X, mousePos.Y)
	end

	if Config.Aim.Enabled and AIM_HOLDING then
		local targetPart = getClosestEnemyPlayer()
		if targetPart then
			local cam = getCamera()
			if cam then
				cam.CFrame = CFrame.new(cam.CFrame.Position, targetPart.Position)
			end
		end
	end
end)

updateButtons()
