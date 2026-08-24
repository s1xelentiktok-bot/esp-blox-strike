--==================================================
-- ESP SYSTEM
-- LocalScript -> StarterPlayerScripts
--==================================================

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local ESP_ENABLED = false
local TEAM_CHECK_ENABLED = false
local AIM_ENABLED = false
local AIM_HOLDING = false

local FOV_RADIUS = 300
local AIM_SPEED = 0.35

local ESP_COLOR = Color3.fromRGB(255, 60, 60)

--==================================================
-- FOLDER
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPObjects"
ESPFolder.Parent = workspace

local ESPObjects = {}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "GameESP"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(290, 225)
Main.Position = UDim2.fromOffset(25, 25)
Main.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 10
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 1
MainStroke.Color = Color3.fromRGB(70, 70, 80)
MainStroke.Parent = Main

--==================================================
-- TITLE
--==================================================

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.fromOffset(10, 7)
Title.BackgroundTransparency = 1
Title.Text = "ESP / AIM"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 22
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.ZIndex = 11
Title.Parent = Main

--==================================================
-- BUTTON
--==================================================

local function createButton(name, y)

	local Button = Instance.new("TextButton")

	Button.Name = name
	Button.Size = UDim2.new(1, -20, 0, 38)
	Button.Position = UDim2.fromOffset(10, y)

	Button.BackgroundColor3 =
		Color3.fromRGB(75, 30, 30)

	Button.BorderSizePixel = 0

	Button.TextColor3 =
		Color3.fromRGB(255, 100, 100)

	Button.TextSize = 15
	Button.Font = Enum.Font.GothamBold

	Button.AutoButtonColor = true
	Button.Active = true
	Button.Selectable = true
	Button.ZIndex = 20

	Button.Parent = Main

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 7)
	Corner.Parent = Button

	return Button
end

local ESPButton =
	createButton("ESPButton", 48)

local TeamButton =
	createButton("TeamButton", 91)

local AimButton =
	createButton("AimButton", 134)

local Info = Instance.new("TextLabel")
Info.Size = UDim2.new(1, -20, 0, 25)
Info.Position = UDim2.fromOffset(10, 180)
Info.BackgroundTransparency = 1
Info.Text = "Left Alt = AIM | Right Alt = MENU"
Info.TextColor3 = Color3.fromRGB(150, 150, 155)
Info.TextSize = 11
Info.Font = Enum.Font.Gotham
Info.TextXAlignment = Enum.TextXAlignment.Left
Info.ZIndex = 11
Info.Parent = Main

--==================================================
-- BUTTON UPDATE
--==================================================

local function setButtonState(Button, enabled, text)

	Button.Text =
		text .. (enabled and ": ON" or ": OFF")

	if enabled then

		Button.BackgroundColor3 =
			Color3.fromRGB(30, 85, 40)

		Button.TextColor3 =
			Color3.fromRGB(100, 255, 120)

	else

		Button.BackgroundColor3 =
			Color3.fromRGB(75, 30, 30)

		Button.TextColor3 =
			Color3.fromRGB(255, 100, 100)
	end
end

local function updateButtons()

	setButtonState(
		ESPButton,
		ESP_ENABLED,
		"ESP"
	)

	setButtonState(
		TeamButton,
		TEAM_CHECK_ENABLED,
		"TEAM CHECK"
	)

	setButtonState(
		AimButton,
		AIM_ENABLED,
		"AIM LOCK"
	)
end

--==================================================
-- TEAM DETECTION
--==================================================

local function getTeam(player)

	if not player then
		return nil
	end

	-- Стандартная Roblox Team
	if player.Team then
		return player.Team
	end

	-- Attributes
	for _, name in ipairs({
		"Team",
		"TeamName",
		"Faction",
		"Side"
	}) do

		local value =
			player:GetAttribute(name)

		if value ~= nil then
			return value
		end
	end

	-- Values
	for _, name in ipairs({
		"Team",
		"TeamName",
		"Faction",
		"Side"
	}) do

		local object =
			player:FindFirstChild(name)

		if object then

			if object:IsA("StringValue")
				or object:IsA("IntValue")
				or object:IsA("NumberValue") then

				return object.Value
			end

			if object:IsA("ObjectValue") then
				return object.Value
			end
		end
	end

	-- Character
	local character = player.Character

	if character then

		for _, name in ipairs({
			"Team",
			"TeamName",
			"Faction",
			"Side"
		}) do

			local value =
				character:GetAttribute(name)

			if value ~= nil then
				return value
			end
		end
	end

	return nil
end

local function sameTeam(player)

	if not TEAM_CHECK_ENABLED then
		return false
	end

	local myTeam =
		getTeam(LocalPlayer)

	local otherTeam =
		getTeam(player)

	if myTeam == nil
		or otherTeam == nil then

		return false
	end

	if typeof(myTeam) == "Instance"
		and typeof(otherTeam) == "Instance" then

		return myTeam == otherTeam
	end

	return tostring(myTeam) ==
		tostring(otherTeam)
end

--==================================================
-- ESP
--==================================================

local function removeESP(player)

	local highlight =
		ESPObjects[player]

	if highlight then
		highlight:Destroy()
	end

	ESPObjects[player] = nil
end

local function createESP(player)

	removeESP(player)

	if not ESP_ENABLED then
		return
	end

	if sameTeam(player) then
		return
	end

	local character =
		player.Character

	if not character then
		return
	end

	local highlight =
		Instance.new("Highlight")

	highlight.Name = "ESP"
	highlight.Adornee = character

	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	highlight.FillColor =
		ESP_COLOR

	highlight.FillTransparency =
		0.78

	highlight.OutlineColor =
		Color3.new(1, 1, 1)

	highlight.OutlineTransparency =
		0

	highlight.Parent =
		ESPFolder

	ESPObjects[player] =
		highlight
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

--==================================================
-- FOV
--==================================================

local FOV = Instance.new("Frame")

FOV.Name = "FOV"
FOV.Size = UDim2.fromOffset(
	FOV_RADIUS * 2,
	FOV_RADIUS * 2
)

FOV.AnchorPoint =
	Vector2.new(0.5, 0.5)

FOV.BackgroundTransparency = 1
FOV.Visible = false
FOV.ZIndex = 3
FOV.Parent = Gui

local FOVCorner =
	Instance.new("UICorner")

FOVCorner.CornerRadius =
	UDim.new(1, 0)

FOVCorner.Parent = FOV

local FOVStroke =
	Instance.new("UIStroke")

FOVStroke.Thickness = 2
FOVStroke.Color =
	Color3.new(1, 1, 1)

FOVStroke.Transparency = 0.25
FOVStroke.Parent = FOV

--==================================================
-- AIM PART
--==================================================

local function getAimPart(character)

	if not character then
		return nil
	end

	for _, name in ipairs({
		"Head",
		"UpperTorso",
		"Torso",
		"HumanoidRootPart"
	}) do

		local part =
			character:FindFirstChild(name)

		if part
			and part:IsA("BasePart") then

			return part
		end
	end

	return character:FindFirstChildWhichIsA(
		"BasePart"
	)
end

--==================================================
-- FIND TARGET
--==================================================

local function getClosestTarget()

	local center =
		Vector2.new(
			Camera.ViewportSize.X / 2,
			Camera.ViewportSize.Y / 2
		)

	local closest = nil
	local closestDistance =
		FOV_RADIUS

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer
			and not sameTeam(player) then

			local character =
				player.Character

			local humanoid =
				character
				and character:FindFirstChildOfClass(
					"Humanoid"
				)

			local part =
				getAimPart(character)

			if character
				and humanoid
				and humanoid.Health > 0
				and part then

				local screen, visible =
					Camera:WorldToViewportPoint(
						part.Position
					)

				if visible
					and screen.Z > 0 then

					local position =
						Vector2.new(
							screen.X,
							screen.Y
						)

					local distance =
						(position - center).Magnitude

					if distance <
						closestDistance then

						closestDistance =
							distance

						closest =
							part
					end
				end
			end
		end
	end

	return closest
end

--==================================================
-- INPUT
--==================================================

UIS.InputBegan:Connect(
	function(input, processed)

		if processed then
			return
		end

		if input.KeyCode ==
			Enum.KeyCode.LeftAlt then

			AIM_HOLDING = true

		elseif input.KeyCode ==
			Enum.KeyCode.RightAlt then

			Main.Visible =
				not Main.Visible
		end
	end
)

UIS.InputEnded:Connect(
	function(input)

		if input.KeyCode ==
			Enum.KeyCode.LeftAlt then

			AIM_HOLDING = false
		end
	end
)

--==================================================
-- BUTTON EVENTS
--==================================================

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

--==================================================
-- PLAYER EVENTS
--==================================================

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

--==================================================
-- LOCAL TEAM CHANGE
--==================================================

LocalPlayer:GetPropertyChangedSignal(
	"Team"
):Connect(
	function()

		if TEAM_CHECK_ENABLED then
			refreshESP()
		end
	end
)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(
	function()

		local viewport =
			Camera.ViewportSize

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
			getClosestTarget()

		if not target then
			return
		end

		local origin =
			Camera.CFrame.Position

		local direction =
			(target.Position - origin).Unit

		local targetCFrame =
			CFrame.lookAt(
				origin,
				origin + direction
			)

		Camera.CFrame =
			Camera.CFrame:Lerp(
				targetCFrame,
				AIM_SPEED
			)
	end
)

--==================================================
-- START
--==================================================

updateButtons()
FOV.Visible = false
