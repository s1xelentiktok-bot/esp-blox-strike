--========================================================--
--                 ADVANCED GAME ESP                     --
--              + TEAM CHECK + NPC LOCK                  --
--========================================================--
--
-- LocalScript
-- StarterPlayer > StarterPlayerScripts
--
-- CONTROLS:
-- Left Alt  = hold NPC lock
-- Right Alt = show / hide menu
--
-- SETUP:
-- workspace
--   └── NPCs
--       ├── NPC / Dummy / Bot ...
--
-- NPCs should contain a Humanoid and preferably:
-- HumanoidRootPart / UpperTorso / Torso / Chest
--
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- CONFIG
--========================================================--

local Config = {

	ESP = {
		Enabled = false,

		FillColor = Color3.fromRGB(255, 60, 60),
		FillTransparency = 0.78,

		OutlineColor = Color3.fromRGB(255, 255, 255),
		OutlineTransparency = 0,
	},

	TeamCheck = {
		Enabled = false,
	},

	Aim = {
		Enabled = false,

		FOVRadius = 300,

		-- Как часто пересчитывать цель.
		-- 30 раз/сек достаточно и почти не грузит CPU.
		TargetRefreshRate = 1 / 30,

		-- Максимальная дистанция для NPC.
		MaxDistance = 1500,

		-- Сохранять текущую цель, пока она допустима.
		StickyTarget = true,
	},

	Keys = {
		Aim = Enum.KeyCode.LeftAlt,
		Menu = Enum.KeyCode.RightAlt,
	},

	UI = {
		MenuPosition = UDim2.fromOffset(20, 20),
	},

	NPC = {
		FolderName = "NPCs",

		-- Можно также помечать NPC тегом "LockableNPC".
		TagName = "LockableNPC",
	},
}

--========================================================--
-- CAMERA
--========================================================--

local Camera = workspace.CurrentCamera

local function getCamera()
	Camera = workspace.CurrentCamera
	return Camera
end

--========================================================--
-- NPC SOURCE
--========================================================--

local NPCFolder = workspace:FindFirstChild(Config.NPC.FolderName)

-- Не создаём папку автоматически, чтобы случайно
-- не считать пустую папку игровой системой NPC.
if not NPCFolder then
	NPCFolder = nil
end

--========================================================--
-- ESP STORAGE
--========================================================--

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "GameESP"
ESPFolder.Parent = workspace

local ESPObjects = {}

--========================================================--
-- TEAM CHECK
--========================================================--

local function areEnemies(playerA, playerB)
	if not playerA or not playerB then
		return false
	end

	if playerA == playerB then
		return false
	end

	if not Config.TeamCheck.Enabled then
		return true
	end

	-- Основной, нормальный Roblox-вариант.
	if playerA.Team ~= nil and playerB.Team ~= nil then
		return playerA.Team ~= playerB.Team
	end

	-- Если команда ещё не назначена,
	-- не считаем игрока врагом.
	return false
end

local function isEnemy(player)
	return areEnemies(LocalPlayer, player)
end

--========================================================--
-- ESP
--========================================================--

local function removeESP(player)
	local data = ESPObjects[player]

	if not data then
		return
	end

	if data.Highlight then
		data.Highlight:Destroy()
	end

	ESPObjects[player] = nil
end

local function createESP(player)
	removeESP(player)

	if not Config.ESP.Enabled then
		return
	end

	if not isEnemy(player) then
		return
	end

	local character = player.Character
	if not character then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "PlayerESP"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	highlight.FillColor = Config.ESP.FillColor
	highlight.FillTransparency = Config.ESP.FillTransparency

	highlight.OutlineColor = Config.ESP.OutlineColor
	highlight.OutlineTransparency = Config.ESP.OutlineTransparency

	highlight.Parent = ESPFolder

	ESPObjects[player] = {
		Highlight = highlight,
	}
end

local function refreshESP()
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			createESP(player)
		end
	end
end

--========================================================--
-- GUI HELPERS
--========================================================--

local Gui = Instance.new("ScreenGui")
Gui.Name = "GameESPMenu"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(310, 250)
Main.Position = Config.UI.MenuPosition
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 10
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = Color3.fromRGB(65, 65, 75)
MainStroke.Parent = Main

--========================================================--
-- TITLE BAR
--========================================================--

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 36)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "GAME ESP / NPC LOCK"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 21
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 11
Title.Parent = Main

--========================================================--
-- DRAGGING
--========================================================--

do
	local dragging = false
	local dragStart
	local startPosition

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
		if not dragging then
			return
		end

		if input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end

		local delta = input.Position - dragStart

		Main.Position = UDim2.new(
			startPosition.X.Scale,
			startPosition.X.Offset + delta.X,
			startPosition.Y.Scale,
			startPosition.Y.Offset + delta.Y
		)
	end)
end

--========================================================--
-- BUTTONS
--========================================================--

local function createButton(name, y)
	local button = Instance.new("TextButton")

	button.Name = name
	button.Size = UDim2.new(1, -20, 0, 38)
	button.Position = UDim2.fromOffset(10, y)

	button.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
	button.BorderSizePixel = 0

	button.TextColor3 = Color3.fromRGB(255, 90, 90)
	button.TextSize = 15
	button.Font = Enum.Font.GothamBold

	button.Active = true
	button.Selectable = true
	button.AutoButtonColor = true
	button.ZIndex = 20

	button.Parent = Main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button

	return button
end

local ESPButton = createButton("ESP", 45)
local TeamButton = createButton("Team", 88)
local AimButton = createButton("Aim", 131)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 45)
Info.Position = UDim2.fromOffset(10, 176)
Info.BackgroundTransparency = 1

Info.Text = "Left Alt — NPC LOCK\nRight Alt — MENU"
Info.TextColor3 = Color3.fromRGB(150, 150, 155)
Info.TextSize = 11
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.ZIndex = 11
Info.Parent = Main

local function updateButton(button, title, enabled)
	if enabled then
		button.Text = title .. ": ON"
		button.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
		button.TextColor3 = Color3.fromRGB(90, 255, 110)
	else
		button.Text = title .. ": OFF"
		button.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
		button.TextColor3 = Color3.fromRGB(255, 90, 90)
	end
end

local function updateButtons()
	updateButton(ESPButton, "ESP", Config.ESP.Enabled)
	updateButton(TeamButton, "TEAM CHECK", Config.TeamCheck.Enabled)
	updateButton(AimButton, "NPC LOCK", Config.Aim.Enabled)
end

--========================================================--
-- FOV
--========================================================--

local FOV = Instance.new("Frame")
FOV.Name = "FOV"
FOV.Size = UDim2.fromOffset(
	Config.Aim.FOVRadius * 2,
	Config.Aim.FOVRadius * 2
)
FOV.AnchorPoint = Vector2.new(0.5, 0.5)
FOV.BackgroundTransparency = 1
FOV.Visible = false
FOV.ZIndex = 2
FOV.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOV

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.2
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Parent = FOV

--========================================================--
-- RETICLE
--========================================================--

local Reticle = Instance.new("Frame")
Reticle.Name = "NPCReticle"
Reticle.Size = UDim2.fromOffset(14, 14)
Reticle.AnchorPoint = Vector2.new(0.5, 0.5)
Reticle.BackgroundTransparency = 1
Reticle.Visible = false
Reticle.ZIndex = 100
Reticle.Parent = Gui

local ReticleCorner = Instance.new("UICorner")
ReticleCorner.CornerRadius = UDim.new(1, 0)
ReticleCorner.Parent = Reticle

local ReticleStroke = Instance.new("UIStroke")
ReticleStroke.Thickness = 2
ReticleStroke.Color = Color3.fromRGB(255, 70, 70)
ReticleStroke.Parent = Reticle

--========================================================--
-- NPC CACHE
--========================================================--

local NPCs = {}

local function getNPCBodyPart(model)
	if not model then
		return nil
	end

	-- Предпочтительно центр тела.
	local preferredNames = {
		"HumanoidRootPart",
		"UpperTorso",
		"Torso",
		"Chest",
		"Body",
		"Root",
		"Pelvis",
	}

	for _, name in ipairs(preferredNames) do
		local part = model:FindFirstChild(name, true)

		if part and part:IsA("BasePart") then
			return part
		end
	end

	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function tryRegisterNPC(model)
	if not model or not model:IsA("Model") then
		return
	end

	if Players:GetPlayerFromCharacter(model) then
		return
	end

	local humanoid = model:FindFirstChildOfClass("Humanoid")

	if not humanoid then
		return
	end

	local part = getNPCBodyPart(model)

	if not part then
		return
	end

	NPCs[model] = {
		Model = model,
		Humanoid = humanoid,
		Part = part,
	}
end

local function unregisterNPC(model)
	NPCs[model] = nil
end

-- NPC source from Folder.
if NPCFolder then
	for _, object in ipairs(NPCFolder:GetChildren()) do
		tryRegisterNPC(object)
	end

	NPCFolder.ChildAdded:Connect(function(object)
		task.defer(tryRegisterNPC, object)
	end)

	NPCFolder.ChildRemoved:Connect(function(object)
		unregisterNPC(object)
	end)
end

-- Optional CollectionService support:
-- Tag an NPC with "LockableNPC".
for _, object in ipairs(
	CollectionService:GetTagged(Config.NPC.TagName)
) do
	tryRegisterNPC(object)
end

CollectionService:GetInstanceAddedSignal(
	Config.NPC.TagName
):Connect(function(object)
	tryRegisterNPC(object)
end)

CollectionService:GetInstanceRemovedSignal(
	Config.NPC.TagName
):Connect(function(object)
	unregisterNPC(object)
end)

--========================================================--
-- AIM TARGET
--========================================================--

local CurrentTarget = nil
local TargetRefreshTimer = 0

local function targetIsValid(part)
	if not part or not part.Parent then
		return false
	end

	for model, data in pairs(NPCs) do
		if data.Part == part and model.Parent then
			if data.Humanoid and data.Humanoid.Health > 0 then
				return true
			end
		end
	end

	return false
end

local function getClosestNPC()
	local camera = getCamera()

	if not camera then
		return nil
	end

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local bestPart = nil
	local bestDistance = Config.Aim.FOVRadius

	local cameraPosition = camera.CFrame.Position

	for model, data in pairs(NPCs) do
		if not model.Parent then
			NPCs[model] = nil
			continue
		end

		local humanoid = data.Humanoid
		local part = data.Part

		if not humanoid
			or not humanoid.Parent
			or not part
			or not part.Parent then

			NPCs[model] = nil
			continue
		end

		if humanoid.Health <= 0 then
			continue
		end

		local worldDistance =
			(part.Position - cameraPosition).Magnitude

		if worldDistance >
			Config.Aim.MaxDistance then

			continue
		end

		local screen, visible =
			camera:WorldToViewportPoint(part.Position)

		if not visible or screen.Z <= 0 then
			continue
		end

		local screenPosition =
			Vector2.new(screen.X, screen.Y)

		local screenDistance =
			(screenPosition - center).Magnitude

		if screenDistance < bestDistance then
			bestDistance = screenDistance
			bestPart = part
		end
	end

	return bestPart
end

--========================================================--
-- TARGET UPDATE
--========================================================--

local function updateTarget(dt)
	if not Config.Aim.Enabled
		or not AIM_HOLDING then

		CurrentTarget = nil
		return
	end

	TargetRefreshTimer += dt

	if TargetRefreshTimer <
		Config.Aim.TargetRefreshRate then

		return
	end

	TargetRefreshTimer = 0

	if Config.Aim.StickyTarget
		and targetIsValid(CurrentTarget) then

		local camera = getCamera()

		if camera then
			local screen, visible =
				camera:WorldToViewportPoint(
					CurrentTarget.Position
				)

			if visible and screen.Z > 0 then
				local center = Vector2.new(
					camera.ViewportSize.X / 2,
					camera.ViewportSize.Y / 2
				)

				local position = Vector2.new(
					screen.X,
					screen.Y
				)

				if (position - center).Magnitude
					<= Config.Aim.FOVRadius then

					return
				end
			end
		end
	end

	CurrentTarget = getClosestNPC()
end

--========================================================--
-- RETICLE
--========================================================--

local function updateReticle()
	if not Config.Aim.Enabled
		or not AIM_HOLDING
		or not targetIsValid(CurrentTarget) then

		Reticle.Visible = false
		return
	end

	local camera = getCamera()

	if not camera then
		Reticle.Visible = false
		return
	end

	local screen, visible =
		camera:WorldToViewportPoint(
			CurrentTarget.Position
		)

	if not visible or screen.Z <= 0 then
		Reticle.Visible = false
		return
	end

	Reticle.Position =
		UDim2.fromOffset(
			screen.X,
			screen.Y
		)

	Reticle.Visible = true
end

--========================================================--
-- BUTTONS
--========================================================--

ESPButton.MouseButton1Click:Connect(function()
	Config.ESP.Enabled = not Config.ESP.Enabled

	refreshESP()
	updateButtons()
end)

TeamButton.MouseButton1Click:Connect(function()
	Config.TeamCheck.Enabled =
		not Config.TeamCheck.Enabled

	refreshESP()
	updateButtons()
end)

AimButton.MouseButton1Click:Connect(function()
	Config.Aim.Enabled =
		not Config.Aim.Enabled

	FOV.Visible = Config.Aim.Enabled

	if not Config.Aim.Enabled then
		AIM_HOLDING = false
		CurrentTarget = nil
		Reticle.Visible = false
	end

	updateButtons()
end)

--========================================================--
-- INPUT
--========================================================--

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Config.Keys.Aim then
		AIM_HOLDING = true
		TargetRefreshTimer = Config.Aim.TargetRefreshRate
		return
	end

	if input.KeyCode == Config.Keys.Menu then
		Main.Visible = not Main.Visible
		return
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Config.Keys.Aim then
		AIM_HOLDING = false
		CurrentTarget = nil
		Reticle.Visible = false
	end
end)

--========================================================--
-- PLAYER SETUP
--========================================================--

local function setupPlayer(player)
	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.2)
		createESP(player)
	end)

	player.CharacterRemoving:Connect(function()
		removeESP(player)
	end)

	player:GetPropertyChangedSignal("Team"):Connect(function()
		if Config.TeamCheck.Enabled then
			createESP(player)
		end
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
	if Config.TeamCheck.Enabled then
		refreshESP()
	end
end)

--========================================================--
-- RENDER
--========================================================--

RunService:BindToRenderStep(
	"GameNPCOverlay",
	Enum.RenderPriority.Last.Value,
	function(dt)

		local camera = getCamera()

		if not camera then
			return
		end

		local viewport = camera.ViewportSize

		FOV.Position =
			UDim2.fromOffset(
				viewport.X / 2,
				viewport.Y / 2
			)

		updateTarget(dt)
		updateReticle()
	end
)

--========================================================--
-- START
--========================================================--

updateButtons()

FOV.Visible = false
Reticle.Visible = false
Main.Visible = true
