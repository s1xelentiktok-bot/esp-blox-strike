--========================================================--
--       ESP + TEAM CHECK + NPC RETICLE LOCK-ON          --
--                    LOCAL SCRIPT                       --
--========================================================--
--
-- Place in:
-- StarterPlayer > StarterPlayerScripts
--
-- Required for NPC lock:
-- workspace
--   └── NPCs
--        ├── Dummy
--        ├── NPC
--        └── ...
--
-- Left Alt  = hold NPC lock-on
-- Right Alt = show/hide menu
--
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

local AIM_KEY = Enum.KeyCode.LeftAlt
local MENU_KEY = Enum.KeyCode.RightAlt

local ESP_COLOR = Color3.fromRGB(255, 60, 60)

--========================================================--
-- NPC FOLDER
--========================================================--

local NPCFolder = workspace:FindFirstChild("NPCs")

if not NPCFolder then
	NPCFolder = Instance.new("Folder")
	NPCFolder.Name = "NPCs"
	NPCFolder.Parent = workspace
end

--========================================================--
-- ESP FOLDER
--========================================================--

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "GameESP"
ESPFolder.Parent = workspace

local ESPObjects = {}

--========================================================--
-- TEAM CHECK
--========================================================--

local function isEnemy(player)

	if not player then
		return false
	end

	if player == LocalPlayer then
		return false
	end

	if not TEAM_CHECK_ENABLED then
		return true
	end

	if LocalPlayer.Team == nil then
		return true
	end

	if player.Team == nil then
		return true
	end

	return player.Team ~= LocalPlayer.Team
end

--========================================================--
-- REMOVE ESP
--========================================================--

local function removeESP(player)

	local object = ESPObjects[player]

	if not object then
		return
	end

	if object.Highlight then
		object.Highlight:Destroy()
	end

	ESPObjects[player] = nil
end

--========================================================--
-- CREATE ESP
--========================================================--

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
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

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

--========================================================--
-- REFRESH ESP
--========================================================--

local function refreshESP()

	for _, player in ipairs(Players:GetPlayers()) do

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
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

Gui.Parent =
	LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- MAIN
--========================================================--

local Main = Instance.new("Frame")

Main.Size = UDim2.fromOffset(300, 245)
Main.Position = UDim2.fromOffset(20, 20)

Main.BackgroundColor3 =
	Color3.fromRGB(24, 24, 28)

Main.BorderSizePixel = 0
Main.Active = true

Main.Parent = Gui

local MainCorner = Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(0, 10)

MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")

MainStroke.Color =
	Color3.fromRGB(65, 65, 75)

MainStroke.Parent = Main

--========================================================--
-- TITLE
--========================================================--

local Title = Instance.new("TextLabel")

Title.Size =
	UDim2.new(1, -20, 0, 40)

Title.Position =
	UDim2.fromOffset(10, 5)

Title.BackgroundTransparency = 1

Title.Text = "ESP / NPC AIM"

Title.TextColor3 =
	Color3.new(1, 1, 1)

Title.TextSize = 23
Title.Font = Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.Parent = Main

--========================================================--
-- BUTTON
--========================================================--

local function makeButton(name, y)

	local button =
		Instance.new("TextButton")

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

	button.AutoButtonColor = true
	button.Active = true
	button.Selectable = true

	button.Parent = Main

	local corner =
		Instance.new("UICorner")

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
	makeButton("AimLock", 134)

--========================================================--
-- INFO
--========================================================--

local Info =
	Instance.new("TextLabel")

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
		text ..
		(enabled and ": ON" or ": OFF")

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
		"NPC AIM",
		AIM_ENABLED
	)
end

--========================================================--
-- FOV
--========================================================--

local FOV =
	Instance.new("Frame")

FOV.Name = "NPC_FOV"

FOV.Size =
	UDim2.fromOffset(
		FOV_RADIUS * 2,
		FOV_RADIUS * 2
	)

FOV.AnchorPoint =
	Vector2.new(0.5, 0.5)

FOV.BackgroundTransparency = 1
FOV.Visible = false

FOV.ZIndex = 2
FOV.Parent = Gui

local FOVCorner =
	Instance.new("UICorner")

FOVCorner.CornerRadius =
	UDim.new(1, 0)

FOVCorner.Parent = FOV

local FOVStroke =
	Instance.new("UIStroke")

FOVStroke.Thickness = 2
FOVStroke.Transparency = 0.2

FOVStroke.Color =
	Color3.fromRGB(255, 255, 255)

FOVStroke.Parent = FOV

--========================================================--
-- RETICLE
--========================================================--

local Reticle =
	Instance.new("Frame")

Reticle.Name =
	"NPCReticle"

Reticle.Size =
	UDim2.fromOffset(12, 12)

Reticle.AnchorPoint =
	Vector2.new(0.5, 0.5)

Reticle.BackgroundTransparency = 1
Reticle.Visible = false

Reticle.ZIndex = 100
Reticle.Parent = Gui

local ReticleCorner =
	Instance.new("UICorner")

ReticleCorner.CornerRadius =
	UDim.new(1, 0)

ReticleCorner.Parent = Reticle

local ReticleStroke =
	Instance.new("UIStroke")

ReticleStroke.Thickness = 2

ReticleStroke.Color =
	Color3.fromRGB(255, 70, 70)

ReticleStroke.Parent = Reticle

--========================================================--
-- NPC PART
--========================================================--

local function getNPCPart(model)

	if not model then
		return nil
	end

	local preferred = {
		"HumanoidRootPart",
		"UpperTorso",
		"Torso",
		"Chest",
		"Body",
		"Root"
	}

	for _, name in ipairs(preferred) do

		local part =
			model:FindFirstChild(
				name,
				true
			)

		if part
			and part:IsA("BasePart")
			and part.Transparency < 1 then

			return part
		end
	end

	return model:FindFirstChildWhichIsA(
		"BasePart",
		true
	)
end

--========================================================--
-- NPC VALIDATION
--========================================================--

local function validNPC(model)

	if not model:IsA("Model") then
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

	return getNPCPart(model) ~= nil
end

--========================================================--
-- NPC CACHE
--========================================================--

local NPCs = {}

local function addNPC(object)

	if validNPC(object) then
		NPCs[object] = true
	end
end

local function removeNPC(object)

	NPCs[object] = nil
end

for _, object in ipairs(
	NPCFolder:GetChildren()
) do

	addNPC(object)
end

NPCFolder.ChildAdded:Connect(
	function(object)

		task.defer(
			addNPC,
			object
		)
	end
)

NPCFolder.ChildRemoved:Connect(
	function(object)

		removeNPC(object)
	end
)

--========================================================--
-- TARGET SEARCH
--========================================================--

local function getClosestNPC()

	local camera =
		workspace.CurrentCamera

	if not camera then
		return nil
	end

	local center =
		Vector2.new(
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		)

	local closestPart = nil
	local closestDistance = FOV_RADIUS

	for npc in pairs(NPCs) do

		if npc.Parent
			and validNPC(npc) then

			local part =
				getNPCPart(npc)

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
-- CURRENT TARGET
--========================================================--

local CurrentTarget = nil

--========================================================--
-- UPDATE RETICLE
--========================================================--

local function updateReticle()

	if not AIM_ENABLED
		or not AIM_HOLDING then

		Reticle.Visible = false
		CurrentTarget = nil

		return
	end

	local camera =
		workspace.CurrentCamera

	if not camera then
		return
	end

	if not CurrentTarget
		or not CurrentTarget.Parent then

		CurrentTarget =
			getClosestNPC()
	end

	if not CurrentTarget then

		Reticle.Visible = false

		return
	end

	local position =
		camera:WorldToViewportPoint(
			CurrentTarget.Position
		)

	if position.Z <= 0 then

		CurrentTarget = nil
		Reticle.Visible = false

		return
	end

	Reticle.Position =
		UDim2.fromOffset(
			position.X,
			position.Y
		)

	Reticle.Visible = true
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
			CurrentTarget = nil
			Reticle.Visible = false
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

			return
		end

		if input.KeyCode == MENU_KEY then

			Main.Visible =
				not Main.Visible

			return
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.KeyCode == AIM_KEY then

			AIM_HOLDING = false
			CurrentTarget = nil
			Reticle.Visible = false
		end
	end
)

--========================================================--
-- PLAYER EVENTS
--========================================================--

local function setupPlayer(player)

	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(
		function()

			task.wait(0.25)

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
	"NPC_Reticle",
	Enum.RenderPriority.Last.Value,
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
