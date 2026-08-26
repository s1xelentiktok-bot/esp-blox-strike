--========================================================--
--          BLOX STRIKE - UNIVERSAL ESP & AIMBOT          --
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
	Players.PlayerAdded:Wait()
	LocalPlayer = Players.LocalPlayer
end

local AIM_HOLDING = false

--========================================================--
-- CONFIG
--========================================================--

local Config = {
	ESP = {
		Enabled = false,
		FillColor = Color3.fromRGB(255, 50, 50),
		FillTransparency = 0.7,
		OutlineColor = Color3.fromRGB(255, 255, 255),
		OutlineTransparency = 0,
	},
	TeamCheck = {
		Enabled = false,
	},
	Aim = {
		Enabled = false,
		FOVRadius = 250,
		MaxDistance = 3000,
	},
	Keys = {
		Aim = Enum.KeyCode.LeftAlt,
		Menu = Enum.KeyCode.RightAlt,
	},
}

--========================================================--
-- SAFE GUI PARENT
--========================================================--

local function getSafeParent()
	local success, result = pcall(function()
		if gethui then return gethui() end
		if cloneref and CoreGui then return cloneref(CoreGui) end
		if CoreGui then return CoreGui end
	end)
	if success and result then return result end
	return LocalPlayer:WaitForChild("PlayerGui")
end

local TargetParent = getSafeParent()

for _, oldGui in ipairs(TargetParent:GetChildren()) do
	if oldGui.Name == "BS_Cheat_Gui" then
		oldGui:Destroy()
	end
end

--========================================================--
-- CAMERA & STORAGE
--========================================================--

local function getCamera()
	return workspace.CurrentCamera or workspace:FindFirstChildOfClass("Camera")
end

if workspace:FindFirstChild("BS_ESP_Folder") then
	workspace.BS_ESP_Folder:Destroy()
end

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "BS_ESP_Folder"
ESPFolder.Parent = workspace

local ESPHighlights = {}

--========================================================--
-- ADVANCED TARGET & TEAM FINDER
--========================================================--

-- Вспомогательная функция поиска персонажа (даже кастомного)
local function getPlayerCharacter(player)
	if player.Character and player.Character:FindFirstChildOfClass("Humanoid") then
		return player.Character
	end
	
	-- Поиск кастомной модели по имени игрока в workspace
	local char = workspace:FindFirstChild(player.Name)
	if char and char:FindFirstChildOfClass("Humanoid") then
		return char
	end
	
	return nil
end

-- Универсальная проверка на врага
local function isEnemy(player)
	if not player or player == LocalPlayer then return false end
	if not Config.TeamCheck.Enabled then return true end

	-- 1. Стандартная проверка Roblox Team
	if LocalPlayer.Team ~= nil and player.Team ~= nil then
		return LocalPlayer.Team ~= player.Team
	end
	if LocalPlayer.TeamColor and player.TeamColor then
		return LocalPlayer.TeamColor ~= player.TeamColor
	end

	-- 2. Проверка по атрибутам / папкам игры (две основные команды)
	local myChar = getPlayerCharacter(LocalPlayer)
	local targetChar = getPlayerCharacter(player)

	if myChar and targetChar then
		local myTeamVal = myChar:FindFirstChild("Team") or myChar:FindFirstChild("Side")
		local targetTeamVal = targetChar:FindFirstChild("Team") or targetChar:FindFirstChild("Side")

		if myTeamVal and targetTeamVal then
			return myTeamVal.Value ~= targetTeamVal.Value
		end
	end

	return true
end

-- Получение части тела для аима (торс/грудь)
local function getTargetBodyPart(character)
	if not character then return nil end
	return character:FindFirstChild("UpperTorso") 
		or character:FindFirstChild("Torso") 
		or character:FindFirstChild("Chest")
		or character:FindFirstChild("HumanoidRootPart")
end

--========================================================--
-- ESP SYSTEM
--========================================================--

local function removeESP(player)
	if ESPHighlights[player] then
		pcall(function() ESPHighlights[player]:Destroy() end)
		ESPHighlights[player] = nil
	end
end

local function createESP(player)
	removeESP(player)

	if not Config.ESP.Enabled or not isEnemy(player) then return end

	local character = getPlayerCharacter(player)
	if not character then return end

	pcall(function()
		local highlight = Instance.new("Highlight")
		highlight.Name = "ESP_" .. player.Name
		highlight.Adornee = character
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.FillColor = Config.ESP.FillColor
		highlight.FillTransparency = Config.ESP.FillTransparency
		highlight.OutlineColor = Config.ESP.OutlineColor
		highlight.OutlineTransparency = Config.ESP.OutlineTransparency
		highlight.Parent = ESPFolder

		ESPHighlights[player] = highlight
	end)
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
-- AIMLOCK LOGIC
--========================================================--

local function getClosestEnemyPlayer()
	local cam = getCamera()
	if not cam then return nil end

	local mousePos = UserInputService:GetMouseLocation()
	local closestPart = nil
	local shortestDistance = Config.Aim.FOVRadius

	for _, player in ipairs(Players:GetPlayers()) do
		if isEnemy(player) then
			local char = getPlayerCharacter(player)
			if char then
				local humanoid = char:FindFirstChildOfClass("Humanoid")
				local targetPart = getTargetBodyPart(char)

				if humanoid and humanoid.Health > 0 and targetPart then
					local myChar = getPlayerCharacter(LocalPlayer)
					local myRoot = myChar and getTargetBodyPart(myChar)
					
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
	end

	return closestPart
end

--========================================================--
-- GUI CREATION
--========================================================--

local Gui = Instance.new("ScreenGui")
Gui.Name = "BS_Cheat_Gui"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function() Gui.Parent = TargetParent end)

-- Приветствие
local WelcomeFrame = Instance.new("Frame")
WelcomeFrame.Size = UDim2.fromOffset(300, 60)
WelcomeFrame.Position = UDim2.new(0.5, -150, 0.35, 0)
WelcomeFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
WelcomeFrame.BackgroundTransparency = 1
WelcomeFrame.BorderSizePixel = 0
WelcomeFrame.ZIndex = 100
WelcomeFrame.Parent = Gui

local WelcomeCorner = Instance.new("UICorner")
WelcomeCorner.CornerRadius = UDim.new(0, 10)
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
WelcomeTitle.TextSize = 17
WelcomeTitle.Font = Enum.Font.GothamBold
WelcomeTitle.TextTransparency = 1
WelcomeTitle.ZIndex = 101
WelcomeTitle.Parent = WelcomeFrame

local WelcomeSub = Instance.new("TextLabel")
WelcomeSub.Size = UDim2.new(1, 0, 0.4, 0)
WelcomeSub.Position = UDim2.fromScale(0, 0.55)
WelcomeSub.BackgroundTransparency = 1
WelcomeSub.Text = "Script Loaded Successfully!"
WelcomeSub.TextColor3 = Color3.fromRGB(200, 200, 200)
WelcomeSub.TextSize = 12
WelcomeSub.Font = Enum.Font.GothamMedium
WelcomeSub.TextTransparency = 1
WelcomeSub.ZIndex = 101
WelcomeSub.Parent = WelcomeFrame

task.spawn(function()
	local tInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	TweenService:Create(WelcomeFrame, tInfo, {BackgroundTransparency = 0.1, Position = UDim2.new(0.5, -150, 0.4, 0)}):Play()
	TweenService:Create(WelcomeStroke, tInfo, {Transparency = 0}):Play()
	TweenService:Create(WelcomeTitle, tInfo, {TextTransparency = 0}):Play()
	TweenService:Create(WelcomeSub, tInfo, {TextTransparency = 0}):Play()

	task.wait(2)

	local tOut = TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
	TweenService:Create(WelcomeFrame, tOut, {BackgroundTransparency = 1, Position = UDim2.new(0.5, -150, 0.35, 0)}):Play()
	TweenService:Create(WelcomeStroke, tOut, {Transparency = 1}):Play()
	TweenService:Create(WelcomeTitle, tOut, {TextTransparency = 1}):Play()
	TweenService:Create(WelcomeSub, tOut, {TextTransparency = 1}):Play()

	task.wait(0.4)
	WelcomeFrame:Destroy()
end)

-- Главное Меню
local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(250, 245)
Main.Position = UDim2.fromOffset(25, 25)
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

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.fromOffset(12, 0)
Title.BackgroundTransparency = 1
Title.Text = "BLOX STRIKE MENU"
Title.TextColor3 = Color3.fromRGB(255, 60, 60)
Title.TextSize = 15
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 11
Title.Parent = Main

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
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPosition.X.Scale, startPosition.X.Offset + delta.X, startPosition.Y.Scale, startPosition.Y.Offset + delta.Y)
		end
	end)
end

local function createButton(name, y)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Size = UDim2.new(1, -24, 0, 36)
	button.Position = UDim2.fromOffset(12, y)
	button.BackgroundColor3 = Color3.fromRGB(32, 24, 28)
	button.BorderSizePixel = 0
	button.TextColor3 = Color3.fromRGB(255, 80, 80)
	button.TextSize = 12
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
Info.Position = UDim2.fromOffset(12, 175)
Info.BackgroundTransparency = 1
Info.Text = "[Left Alt] — Hold Aim Lock\n[Right Alt] — Hide / Show Menu"
Info.TextColor3 = Color3.fromRGB(110, 110, 120)
Info.TextSize = 11
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.ZIndex = 11
Info.Parent = Main

local function updateButton(button, stroke, title, enabled)
	local tInfo = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	if enabled then
		button.Text = title .. "  [ ON ]"
		TweenService:Create(button, tInfo, {BackgroundColor3 = Color3.fromRGB(24, 45, 32), TextColor3 = Color3.fromRGB(80, 255, 140)}):Play()
		TweenService:Create(stroke, tInfo, {Color = Color3.fromRGB(40, 120, 65)}):Play()
	else
		button.Text = title .. "  [ OFF ]"
		TweenService:Create(button, tInfo, {BackgroundColor3 = Color3.fromRGB(38, 24, 28), TextColor3 = Color3.fromRGB(255, 80, 80)}):Play()
		TweenService:Create(stroke, tInfo, {Color = Color3.fromRGB(90, 35, 35)}):Play()
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
	if not Config.Aim.Enabled then AIM_HOLDING = false end
	updateButtons()
end)

--========================================================--
-- INPUT HANDLING
--========================================================--

UserInputService.InputBegan:Connect(function(input)
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
-- LOOP PROCESSORS
--========================================================--

-- Авто-обновление ESP каждые 0.5 сек (устойчивость при возрождении)
task.spawn(function()
	while task.wait(0.5) do
		if Config.ESP.Enabled then
			refreshESP()
		end
	end
end)

-- Кадр-в-кадр наведение и FOV
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
