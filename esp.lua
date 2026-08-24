--==================================================
-- ESP + AUTO TEAM CHECK + FOV LOCK
-- LocalScript
-- StarterPlayer > StarterPlayerScripts
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--==================================================
-- SETTINGS
--==================================================

local ESP_ENABLED = false
local TEAM_CHECK_ENABLED = false
local AIM_ENABLED = false

local AIM_KEY = Enum.KeyCode.LeftAlt
local MENU_KEY = Enum.KeyCode.LeftAlt

local FOV_RADIUS = 300
local AIM_SPEED = 0.35

local ESP_COLOR = Color3.fromRGB(255, 60, 60)

--==================================================
-- ESP FOLDER
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "GameESP"
ESPFolder.Parent = workspace

local ESPObjects = {}

--==================================================
-- TEAM DETECTION
--==================================================

local function readTeam(container)
	if not container then
		return nil
	end

	-- Attribute
	local attribute = container:GetAttribute("Team")

	if attribute ~= nil then
		return attribute
	end

	-- Другие распространённые названия атрибутов
	for _, name in ipairs({
		"TeamName",
		"TeamId",
		"TeamID",
		"Faction",
		"Side"
	}) do
		local value = container:GetAttribute(name)

		if value ~= nil then
			return value
		end
	end

	-- Значение Team внутри объекта
	local teamObject = container:FindFirstChild("Team")

	if teamObject then

		if teamObject:IsA("StringValue")
			or teamObject:IsA("IntValue")
			or teamObject:IsA("NumberValue")
			or teamObject:IsA("BoolValue") then

			return teamObject.Value
		end

		if teamObject:IsA("ObjectValue") then
			return teamObject.Value
		end
	end

	return nil
end

local function getPlayerTeam(player)

	-- Обычная Roblox Team
	if player.Team ~= nil then
		return player.Team
	end

	-- Атрибуты/значения Player
	local playerTeam = readTeam(player)

	if playerTeam ~= nil then
		return playerTeam
	end

	-- Атрибуты/значения Character
	if player.Character then
		local characterTeam = readTeam(player.Character)

		if characterTeam ~= nil then
			return characterTeam
		end
	end

	return nil
end

local function teamsEqual(a, b)

	if a == nil or b == nil then
		return false
	end

	if typeof(a) == "Instance"
		and typeof(b) == "Instance" then

		return a == b
	end

	return tostring(a) == tostring(b)
end

local function isEnemy(player)

	if player == LocalPlayer then
		return false
	end

	if not TEAM_CHECK_ENABLED then
		return true
	end

	local myTeam = getPlayerTeam(LocalPlayer)
	local otherTeam = getPlayerTeam(player)

	-- Если команды неизвестны,
	-- оставляем игрока видимым.
	if myTeam == nil or otherTeam == nil then
		return true
	end

	return not teamsEqual(myTeam, otherTeam)
end

--==================================================
-- ESP
--==================================================

local function removeESP(player)

	local object = ESPObjects[player]

	if object then
		object:Destroy()
		ESPObjects[player] = nil
	end
end

local function createESP(player)

	removeESP(player)

	if not ESP_ENABLED then
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

	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	highlight.FillColor = ESP_COLOR
	highlight.FillTransparency = 0.78

	highlight.OutlineColor =
		Color3.fromRGB(255, 255, 255)

	highlight.OutlineTransparency = 0

	highlight.Parent = ESPFolder

	ESPObjects[player] = highlight
end

local function refreshESP()

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer then
			createESP(player)
		end
	end
end

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "ESP_GUI"
Gui.ResetOnSpawn = false
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")

Main.Size = UDim2.fromOffset(285, 220)
Main.Position = UDim2.fromOffset(20, 20)

Main.BackgroundColor3 =
	Color3.fromRGB(24, 24, 28)

Main.BorderSizePixel = 0
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")

Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.fromOffset(10, 5)

Title.BackgroundTransparency = 1

Title.Text = "ESP / AIM"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent = Main

local function makeButton(y)

	local button = Instance.new("TextButton")

	button.Size =
		UDim2.new(1, -20, 0, 38)

	button.Position =
		UDim2.fromOffset(10, y)

	button.BackgroundColor3 =
		Color3.fromRGB(80, 30, 30)

	button.BorderSizePixel = 0

	button.TextColor3 =
		Color3.fromRGB(255, 90, 90)

	button.TextSize = 15
	button.Font = Enum.Font.GothamBold

	button.Parent = Main

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button

	return button
end

local ESPButton = makeButton(45)
local TeamButton = makeButton(87)
local AimButton = makeButton(129)

local Hint = Instance.new("TextLabel")

Hint.Size =
	UDim2.new(1, -20, 0, 25)

Hint.Position =
	UDim2.fromOffset(10, 175)

Hint.BackgroundTransparency = 1

Hint.Text =
	"Left Alt = AIM • Right Alt = MENU"

Hint.TextColor3 =
	Color3.fromRGB(150, 150, 155)

Hint.TextSize = 11
Hint.Font = Enum.Font.Gotham

Hint.TextXAlignment =
	Enum.TextXAlignment.Left

Hint.Parent = Main

--==================================================
-- BUTTON STATE
--==================================================

local function updateButtons()

	ESPButton.Text =
		ESP_ENABLED
		and "ESP: ON"
		or "ESP: OFF"

	ESPButton.BackgroundColor3 =
		ESP_ENABLED
		and Color3.fromRGB(30, 80, 40)
		or Color3.fromRGB(80, 30, 30)

	ESPButton.TextColor3 =
		ESP_ENABLED
		and Color3.fromRGB(90, 255, 110)
		or Color3.fromRGB(255, 90, 90)


	TeamButton.Text =
		TEAM_CHECK_ENABLED
		and "TEAM CHECK: ON"
		or "TEAM CHECK: OFF"

	TeamButton.BackgroundColor3 =
		TEAM_CHECK_ENABLED
		and Color3.fromRGB(30, 80, 40)
		or Color3.fromRGB(80, 30, 30)

	TeamButton.TextColor3 =
		TEAM_CHECK_ENABLED
		and Color3.fromRGB(90, 255, 110)
		or Color3.fromRGB(255, 90, 90)


	AimButton.Text =
		AIM_ENABLED
		and "AIM LOCK: ON"
		or "AIM LOCK: OFF"

	AimButton.BackgroundColor3 =
		AIM_ENABLED
		and Color3.fromRGB(30, 80, 40)
		or Color3.fromRGB(80, 30, 30)

	AimButton.TextColor3 =
		AIM_ENABLED
		and Color3.fromRGB(90, 255, 110)
		or Color3.fromRGB(255, 90, 90)
end

--==================================================
-- FOV
--==================================================

local FOV = Instance.new("Frame")

FOV.Name = "AimFOV"

FOV.Size = UDim2.fromOffset(
	FOV_RADIUS * 2,
	FOV_RADIUS * 2
)

FOV.AnchorPoint =
	Vector2.new(0.5, 0.5)

FOV.BackgroundTransparency = 1
FOV.Visible = false

FOV.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOV

local FOVStroke = Instance.new("UIStroke")

FOVStroke.Thickness = 2
FOVStroke.Color = Color3.new(1, 1, 1)
FOVStroke.Transparency = 0.2

FOVStroke.Parent = FOV

--==================================================
-- AIM PART
--==================================================

local function getAimPart(character)

	if not character then
		return nil
	end

	-- Приоритетные точки
	for _, name in ipairs({
		"Head",
		"UpperTorso",
		"Torso",
		"HumanoidRootPart"
	}) do

		local part = character:FindFirstChild(name)

		if part and part:IsA("BasePart") then
			return part
		end
	end

	-- Кастомная модель:
	-- берём ближайший подходящий BasePart
	local bestPart = nil

	for _, object in ipairs(character:GetDescendants()) do

		if object:IsA("BasePart") then

			if object.Name ~= "Handle" then
				bestPart = object
				break
			end
		end
	end

	return bestPart
end

--==================================================
-- AIM TARGET
--==================================================

local function getClosestTarget()

	local center = Vector2.new(
		Camera.ViewportSize.X / 2,
		Camera.ViewportSize.Y / 2
	)

	local closestPart = nil
	local closestDistance = FOV_RADIUS

	for _, player in ipairs(Players:GetPlayers()) do

		if player ~= LocalPlayer
			and isEnemy(player) then

			local character = player.Character
			local part = getAimPart(character)

			local humanoid =
				character
				and character:FindFirstChildOfClass(
					"Humanoid"
				)

			if character
				and part
				and humanoid
				and humanoid.Health > 0 then

				local screenPosition, visible =
					Camera:WorldToViewportPoint(
						part.Position
					)

				if visible
					and screenPosition.Z > 0 then

					local screen =
						Vector2.new(
							screenPosition.X,
							screenPosition.Y
						)

					local distance =
						(screen - center).Magnitude

					if distance < closestDistance then

						closestDistance = distance
						closestPart = part
					end
				end
			end
		end
	end

	return closestPart
end

--==================================================
-- INPUT
--==================================================

local aimHolding = false

UIS.InputBegan:Connect(function(input, processed)

	if processed then
		return
	end

	if input.KeyCode == AIM_KEY then
		aimHolding = true
	end
end)

UIS.InputEnded:Connect(function(input)

	if input.KeyCode == AIM_KEY then
		aimHolding = false
	end
end)

--==================================================
-- BUTTONS
--==================================================

ESPButton.MouseButton1Click:Connect(function()

	ESP_ENABLED = not ESP_ENABLED

	refreshESP()
	updateButtons()
end)

TeamButton.MouseButton1Click:Connect(function()

	TEAM_CHECK_ENABLED =
		not TEAM_CHECK_ENABLED

	refreshESP()
	updateButtons()
end)

AimButton.MouseButton1Click:Connect(function()

	AIM_ENABLED = not AIM_ENABLED

	FOV.Visible = AIM_ENABLED

	if not AIM_ENABLED then
		aimHolding = false
	end

	updateButtons()
end)

--==================================================
-- PLAYERS
--==================================================

local function setupPlayer(player)

	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(function()

		task.wait(0.5)

		createESP(player)
	end)

	player.CharacterRemoving:Connect(function()

		removeESP(player)
	end)

	player:GetPropertyChangedSignal(
		"Team"
	):Connect(function()

		if TEAM_CHECK_ENABLED then
			refreshESP()
		end
	end)
end

for _, player in ipairs(
	Players:GetPlayers()
) do

	setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)

	removeESP(player)
end)

--==================================================
-- TEAM CHANGES
--==================================================

LocalPlayer:GetPropertyChangedSignal(
	"Team"
):Connect(function()

	if TEAM_CHECK_ENABLED then
		refreshESP()
	end
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

	local viewport = Camera.ViewportSize

	FOV.Position =
		UDim2.fromOffset(
			viewport.X / 2,
			viewport.Y / 2
		)

	if not AIM_ENABLED then
		return
	end

	if not aimHolding then
		return
	end

	local target = getClosestTarget()

	if not target then
		return
	end

	local cameraPosition =
		Camera.CFrame.Position

	local direction =
		(target.Position - cameraPosition).Unit

	local targetCFrame =
		CFrame.lookAt(
			cameraPosition,
			cameraPosition + direction
		)

	Camera.CFrame =
		Camera.CFrame:Lerp(
			targetCFrame,
			AIM_SPEED
		)
end)

--==================================================
-- START
--==================================================

updateButtons()
FOV.Visible = false