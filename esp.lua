--========================================================--
-- ESP + TEAM CHECK + NPC LOCK-ON
-- LocalScript
-- StarterPlayer > StarterPlayerScripts
--
-- Left Alt  = NPC LOCK-ON
-- Right Alt = MENU
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- SETTINGS
--========================================================--

local ESP_ENABLED = false
local TEAM_CHECK_ENABLED = false
local AIM_ENABLED = false
local AIM_HOLDING = false

local FOV_RADIUS = 300
local AIM_SMOOTHNESS = 0.95

local AIM_KEY = Enum.KeyCode.LeftAlt
local MENU_KEY = Enum.KeyCode.RightAlt

local ESP_COLOR = Color3.fromRGB(255, 60, 60)

--========================================================--
-- ESP
--========================================================--

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "GameESP"
ESPFolder.Parent = workspace

local ESPObjects = {}

local function isEnemy(player)

	if player == LocalPlayer then
		return false
	end

	if not TEAM_CHECK_ENABLED then
		return true
	end

	if LocalPlayer.Team ~= nil
		and player.Team ~= nil then

		return player.Team ~= LocalPlayer.Team
	end

	return false
end

local function removeESP(player)

	local object = ESPObjects[player]

	if object then

		if object.Highlight then
			object.Highlight:Destroy()
		end

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

	ESPObjects[player] = {
		Highlight = highlight
	}
end

local function refreshESP()

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer then
			createESP(player)
		end
	end
end

--========================================================--
-- GUI
--========================================================--

local Gui = Instance.new("ScreenGui")

Gui.Name = "GameESPMenu"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true

Gui.Parent =
	LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")

Main.Size = UDim2.fromOffset(300, 245)
Main.Position = UDim2.fromOffset(20, 20)

Main.BackgroundColor3 =
	Color3.fromRGB(24, 24, 28)

Main.BorderSizePixel = 0
Main.Active = true

Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")

Title.Size =
	UDim2.new(1, -20, 0, 40)

Title.Position =
	UDim2.fromOffset(10, 5)

Title.BackgroundTransparency = 1
Title.Text = "ESP / NPC LOCK"

Title.TextColor3 =
	Color3.new(1, 1, 1)

Title.TextSize = 23
Title.Font = Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent = Main

--========================================================--
-- BUTTONS
--========================================================--

local function makeButton(name, y)

	local button = Instance.new("TextButton")

	button.Name = name

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

	corner.CornerRadius =
		UDim.new(0, 7)

	corner.Parent = button

	return button
end

local ESPButton =
	makeButton("ESP", 48)

local TeamButton =
	makeButton("TeamCheck", 91)

local AimButton =
	makeButton("NPCLock", 134)

local Info = Instance.new("TextLabel")

Info.Size =
	UDim2.new(1, -20, 0, 40)

Info.Position =
	UDim2.fromOffset(10, 180)

Info.BackgroundTransparency = 1

Info.Text =
	"Left Alt - NPC LOCK\nRight Alt - MENU"

Info.TextColor3 =
	Color3.fromRGB(150, 150, 155)

Info.TextSize = 11
Info.Font = Enum.Font.Gotham

Info.TextXAlignment =
	Enum.TextXAlignment.Left

Info.Parent = Main

--========================================================--
-- BUTTON STATE
--========================================================--

local function setButton(button, text, enabled)

	button.Text =
		text .. (enabled and ": ON" or ": OFF")

	if enabled then

		button.BackgroundColor3 =
			Color3.fromRGB(30, 80, 40)

		button.TextColor3 =
			Color3.fromRGB(90, 255, 110)

	else

		button.BackgroundColor3 =
			Color3.fromRGB(80, 30, 30)

		button.TextColor3 =
			Color3.fromRGB(255, 90, 90)
	end
end

local function updateButtons()

	setButton(
		ESPButton,
		"ESP",
		ESP_ENABLED
	)

	setButton(
		TeamButton,
		"TEAM CHECK",
		TEAM_CHECK_ENABLED
	)

	setButton(
		AimButton,
		"NPC LOCK",
		AIM_ENABLED
	)
end

--========================================================--
-- FOV
--========================================================--

local FOV = Instance.new("Frame")

FOV.Name = "NPCFOV"

FOV.Size =
	UDim2.fromOffset(
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
FOVStroke.Transparency = 0.2
FOVStroke.Parent = FOV

--========================================================--
-- NPC BODY PART
--========================================================--

local BodyNames = {
	"HumanoidRootPart",
	"UpperTorso",
	"Torso",
	"Chest",
	"Body",
	"Root",
	"Pelvis",
	"Spine"
}

local function getNPCBody(character)

	if not character then
		return nil
	end

	for _, name in ipairs(BodyNames) do

		local part =
			character:FindFirstChild(
				name,
				true
			)

		if part
			and part:IsA("BasePart")
			and part.Transparency < 1 then

			return part
		end
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if humanoid then

		local root =
			character:FindFirstChild(
				"HumanoidRootPart"
			)

		if root then
			return root
		end
	end

	return nil
end

--========================================================--
-- NPC CHECK
--========================================================--

local function isNPC(model)

	if not model:IsA("Model") then
		return false
	end

	-- Не выбираем персонажей игроков.
	if Players:GetPlayerFromCharacter(model) then
		return false
	end

	local humanoid =
		model:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoid then
		return false
	end

	if humanoid.Health <= 0 then
		return false
	end

	return true
end

--========================================================--
-- FIND NPC
--========================================================--

local function getClosestNPC()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return nil
	end

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local closestPart = nil
	local closestDistance = FOV_RADIUS

	for _, object in ipairs(
		workspace:GetDescendants()
	) do

		if object:IsA("Model")
			and isNPC(object) then

			local part =
				getNPCBody(object)

			if part then

				local position =
					camera:WorldToViewportPoint(
						part.Position
					)

				if position.Z > 0 then

					local screen =
						Vector2.new(
							position.X,
							position.Y
						)

					local distance =
						(
							screen - center
						).Magnitude

					if distance <
						closestDistance then

						closestDistance =
							distance

						closestPart =
							part
					end
				end
			end
		end
	end

	return closestPart
end

--========================================================--
-- AIM
--========================================================--

local function aimAt(part)

	if not part
		or not part.Parent then
		return
	end

	local camera =
		workspace.CurrentCamera

	if not camera then
		return
	end

	local cameraPosition =
		camera.CFrame.Position

	local targetCFrame =
		CFrame.lookAt(
			cameraPosition,
			part.Position
		)

	camera.CFrame =
		camera.CFrame:Lerp(
			targetCFrame,
			AIM_SMOOTHNESS
		)
end

--========================================================--
-- BUTTON EVENTS
--========================================================--

ESPButton.MouseButton1Click:Connect(
	function()

		ESP_ENABLED =
			not ESP_ENABLED

		refreshESP()
		updateButtons()
	end
)

TeamButton.MouseButton1Click:Connect(
	function()

		TEAM_CHECK_ENABLED =
			not TEAM_CHECK_ENABLED

		refreshESP()
		updateButtons()
	end
)

AimButton.MouseButton1Click:Connect(
	function()

		AIM_ENABLED =
			not AIM_ENABLED

		FOV.Visible =
			AIM_ENABLED

		if not AIM_ENABLED then
			AIM_HOLDING = false
		end

		updateButtons()
	end
)

--========================================================--
-- INPUT
--========================================================--

UserInputService.InputBegan:Connect(
	function(input, processed)

		if processed then
			return
		end

		if input.KeyCode == AIM_KEY then
			AIM_HOLDING = true
		end

		if input.KeyCode == MENU_KEY then

			Main.Visible =
				not Main.Visible
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.KeyCode == AIM_KEY then
			AIM_HOLDING = false
		end
	end
)

--========================================================--
-- PLAYERS
--========================================================--

local function setupPlayer(player)

	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(
		function()

			task.wait(0.5)

			createESP(player)
		end
	)

	player.CharacterRemoving:Connect(
		function()

			removeESP(player)
		end
	)

	player:GetPropertyChangedSignal(
		"Team"
	):Connect(
		function()

			if TEAM_CHECK_ENABLED then
				createESP(player)
			end
		end
	)
end

for _, player in ipairs(
	Players:GetPlayers()
) do

	setupPlayer(player)
end

Players.PlayerAdded:Connect(
	setupPlayer
)

Players.PlayerRemoving:Connect(
	function(player)

		removeESP(player)
	end
)

LocalPlayer:GetPropertyChangedSignal(
	"Team"
):Connect(
	function()

		if TEAM_CHECK_ENABLED then
			refreshESP()
		end
	end
)

--========================================================--
-- RENDER
--========================================================--

RunService:BindToRenderStep(
	"NPCLock",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		local camera =
			workspace.CurrentCamera

		if not camera then
			return
		end

		local viewport =
			camera.ViewportSize

		FOV.Position =
			UDim2.fromOffset(
				viewport.X / 2,
				viewport.Y / 2
			)

		if not AIM_ENABLED
			or not AIM_HOLDING then
			return
		end

		local target =
			getClosestNPC()

		if target then
			aimAt(target)
		end
	end
)

--========================================================--
-- START
--========================================================--

updateButtons()

FOV.Visible = false
Main.Visible = true