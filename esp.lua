--========================================================--
--               PREMIUM ESP / AIM SYSTEM                --
--                     LocalScript                        --
--========================================================--
--
-- StarterPlayer > StarterPlayerScripts
--
-- Left Alt  = AIM
-- Right Alt = MENU
--
-- AIM LOGIC KEPT THE SAME
-- Team Check uses multiple detection methods
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

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

local AIM_COLOR = Color3.fromRGB(255, 70, 95)
local ESP_COLOR = Color3.fromRGB(255, 70, 95)

--========================================================--
-- CAMERA
--========================================================--

local Camera = workspace.CurrentCamera

local function getCamera()
	Camera = workspace.CurrentCamera
	return Camera
end

--========================================================--
-- TEAM RESOLVER
--========================================================--

local TEAM_ATTRIBUTE_NAMES = {
	"Team",
	"TeamName",
	"TeamId",
	"TeamID",
	"Faction",
	"Side",
	"SideName",
	"Group",
	"GroupName",
	"Allegiance",
	"Alignment",
}

local TEAM_VALUE_NAMES = {
	"Team",
	"TeamName",
	"TeamId",
	"TeamID",
	"Faction",
	"Side",
	"SideName",
	"Group",
	"GroupName",
	"Allegiance",
	"Alignment",
}

local TEAM_OBJECT_NAMES = {
	"Team",
	"team",
	"Faction",
	"Side",
	"Group",
	"Allegiance",
}

local function normalizeTeam(value)

	if value == nil then
		return nil
	end

	if typeof(value) == "Instance" then

		if value:IsA("Team") then
			return value
		end

		if value:IsA("StringValue")
			or value:IsA("IntValue")
			or value:IsA("NumberValue")
			or value:IsA("BoolValue") then

			return value.Value
		end

		if value:IsA("ObjectValue") then
			return value.Value
		end

		return value
	end

	return value
end

local function readAttributes(container)

	if not container then
		return nil
	end

	for _, name in ipairs(TEAM_ATTRIBUTE_NAMES) do

		local value =
			container:GetAttribute(name)

		if value ~= nil then
			return normalizeTeam(value)
		end
	end

	return nil
end

local function readValues(container)

	if not container then
		return nil
	end

	for _, name in ipairs(TEAM_VALUE_NAMES) do

		local value =
			container:FindFirstChild(name)

		if value then

			local result =
				normalizeTeam(value)

			if result ~= nil then
				return result
			end
		end
	end

	return nil
end

local function readTeamObjects(container)

	if not container then
		return nil
	end

	for _, name in ipairs(TEAM_OBJECT_NAMES) do

		local value =
			container:FindFirstChild(name, true)

		if value then

			local result =
				normalizeTeam(value)

			if result ~= nil then
				return result
			end
		end
	end

	return nil
end

local function resolveTeam(player)

	if not player then
		return nil
	end

	--==================================================
	-- 1. Standard Roblox Team
	--==================================================

	if player.Team ~= nil then
		return player.Team
	end

	--==================================================
	-- 2. Standard TeamColor
	--==================================================

	if player.TeamColor ~= nil then
		return player.TeamColor
	end

	--==================================================
	-- 3. Player Attributes
	--==================================================

	local attribute =
		readAttributes(player)

	if attribute ~= nil then
		return attribute
	end

	--==================================================
	-- 4. Player Values
	--==================================================

	local value =
		readValues(player)

	if value ~= nil then
		return value
	end

	--==================================================
	-- 5. Player Team Objects
	--==================================================

	local object =
		readTeamObjects(player)

	if object ~= nil then
		return object
	end

	--==================================================
	-- 6. Character Attributes
	--==================================================

	if player.Character then

		local characterAttribute =
			readAttributes(
				player.Character
			)

		if characterAttribute ~= nil then
			return characterAttribute
		end

		-- Character Values
		local characterValue =
			readValues(
				player.Character
			)

		if characterValue ~= nil then
			return characterValue
		end

		-- Character Team Objects
		local characterObject =
			readTeamObjects(
				player.Character
			)

		if characterObject ~= nil then
			return characterObject
		end
	end

	return nil
end

local function teamsMatch(a, b)

	if a == nil or b == nil then
		return nil
	end

	a = normalizeTeam(a)
	b = normalizeTeam(b)

	if a == nil or b == nil then
		return nil
	end

	-- Same Instance
	if typeof(a) == "Instance"
		and typeof(b) == "Instance" then

		return a == b
	end

	-- Same BrickColor
	if typeof(a) == "BrickColor"
		and typeof(b) == "BrickColor" then

		return a == b
	end

	-- Color3
	if typeof(a) == "Color3"
		and typeof(b) == "Color3" then

		return a == b
	end

	-- Primitive values
	return tostring(a) == tostring(b)
end

local function isEnemy(player)

	if not player
		or player == LocalPlayer then

		return false
	end

	if not TEAM_CHECK_ENABLED then
		return true
	end

	local myTeam =
		resolveTeam(LocalPlayer)

	local theirTeam =
		resolveTeam(player)

	-- If both teams were found,
	-- only the opposite team is an enemy.
	if myTeam ~= nil
		and theirTeam ~= nil then

		local same =
			teamsMatch(
				myTeam,
				theirTeam
			)

		if same == true then
			return false
		end

		if same == false then
			return true
		end
	end

	-- Unknown team:
	-- don't hide the player.
	-- This prevents Team Check from
	-- accidentally hiding everybody.
	return true
end

--========================================================--
-- ESP
--========================================================--

local ESPFolder =
	Instance.new("Folder")

ESPFolder.Name =
	"PremiumESP"

ESPFolder.Parent =
	workspace

local ESPObjects = {}

local function removeESP(player)

	local object =
		ESPObjects[player]

	if not object then
		return
	end

	if object.Highlight then
		object.Highlight:Destroy()
	end

	ESPObjects[player] = nil
end

local function createESP(player)

	removeESP(player)

	if not ESP_ENABLED then
		return
	end

	if not isEnemy(player) then
		return
	end

	local character =
		player.Character

	if not character then
		return
	end

	local highlight =
		Instance.new("Highlight")

	highlight.Name =
		"EnemyESP"

	highlight.Adornee =
		character

	highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	highlight.FillColor =
		ESP_COLOR

	highlight.FillTransparency =
		0.78

	highlight.OutlineColor =
		Color3.fromRGB(
			255,
			255,
			255
		)

	highlight.OutlineTransparency =
		0

	highlight.Parent =
		ESPFolder

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
-- PREMIUM GUI
--========================================================--

local Gui =
	Instance.new("ScreenGui")

Gui.Name =
	"PremiumCombatUI"

Gui.ResetOnSpawn =
	false

Gui.IgnoreGuiInset =
	true

Gui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

Gui.Parent =
	PlayerGui

--========================================================--
-- WELCOME
--========================================================--

local Welcome =
	Instance.new("Frame")

Welcome.Size =
	UDim2.fromOffset(
		380,
		92
	)

Welcome.Position =
	UDim2.new(
		0.5,
		-190,
		0,
		-110
	)

Welcome.BackgroundColor3 =
	Color3.fromRGB(
		16,
		16,
		21
	)

Welcome.BorderSizePixel =
	0

Welcome.ZIndex =
	200

Welcome.Parent =
	Gui

local WelcomeCorner =
	Instance.new("UICorner")

WelcomeCorner.CornerRadius =
	UDim.new(
		0,
		15
	)

WelcomeCorner.Parent =
	Welcome

local WelcomeStroke =
	Instance.new("UIStroke")

WelcomeStroke.Color =
	Color3.fromRGB(
		90,
		90,
		110
	)

WelcomeStroke.Thickness =
	1

WelcomeStroke.Parent =
	Welcome

local WelcomeAccent =
	Instance.new("Frame")

WelcomeAccent.Size =
	UDim2.new(
		0,
		4,
		1,
		-24
	)

WelcomeAccent.Position =
	UDim2.fromOffset(
		8,
		12
	)

WelcomeAccent.BackgroundColor3 =
	AIM_COLOR

WelcomeAccent.BorderSizePixel =
	0

WelcomeAccent.ZIndex =
	201

WelcomeAccent.Parent =
	Welcome

local AccentCorner =
	Instance.new("UICorner")

AccentCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

AccentCorner.Parent =
	WelcomeAccent

local WelcomeTitle =
	Instance.new("TextLabel")

WelcomeTitle.Size =
	UDim2.new(
		1,
		-40,
		0,
		31
	)

WelcomeTitle.Position =
	UDim2.fromOffset(
		25,
		12
	)

WelcomeTitle.BackgroundTransparency =
	1

WelcomeTitle.Text =
	"WELCOME BACK"

WelcomeTitle.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

WelcomeTitle.TextSize =
	21

WelcomeTitle.Font =
	Enum.Font.GothamBlack

WelcomeTitle.TextXAlignment =
	Enum.TextXAlignment.Left

WelcomeTitle.ZIndex =
	201

WelcomeTitle.Parent =
	Welcome

local WelcomeSubtitle =
	Instance.new("TextLabel")

WelcomeSubtitle.Size =
	UDim2.new(
		1,
		-40,
		0,
		25
	)

WelcomeSubtitle.Position =
	UDim2.fromOffset(
		25,
		45
	)

WelcomeSubtitle.BackgroundTransparency =
	1

WelcomeSubtitle.Text =
	"Premium system initialized successfully"

WelcomeSubtitle.TextColor3 =
	Color3.fromRGB(
		145,
		145,
		160
	)

WelcomeSubtitle.TextSize =
	11

WelcomeSubtitle.Font =
	Enum.Font.Gotham

WelcomeSubtitle.TextXAlignment =
	Enum.TextXAlignment.Left

WelcomeSubtitle.ZIndex =
	201

WelcomeSubtitle.Parent =
	Welcome

TweenService:Create(
	Welcome,
	TweenInfo.new(
		0.55,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	),
	{
		Position =
			UDim2.new(
				0.5,
				-190,
				0,
				25
			)
	}
):Play()

task.delay(
	3,
	function()

		local out =
			TweenService:Create(
				Welcome,
				TweenInfo.new(
					0.45,
					Enum.EasingStyle.Quint,
					Enum.EasingDirection.In
				),
				{
					Position =
						UDim2.new(
							0.5,
							-190,
							0,
							-110
						)
				}
			)

		out:Play()

		out.Completed:Connect(
			function()
				Welcome:Destroy()
			end
		)
	end
)

--========================================================--
-- MAIN MENU
--========================================================--

local Main =
	Instance.new("Frame")

Main.Size =
	UDim2.fromOffset(
		355,
		350
	)

Main.Position =
	UDim2.fromOffset(
		25,
		25
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		17,
		17,
		22
	)

Main.BorderSizePixel =
	0

Main.Active =
	true

Main.ZIndex =
	10

Main.Parent =
	Gui

local MainCorner =
	Instance.new("UICorner")

MainCorner.CornerRadius =
	UDim.new(
		0,
		16
	)

MainCorner.Parent =
	Main

local MainStroke =
	Instance.new("UIStroke")

MainStroke.Color =
	Color3.fromRGB(
		60,
		60,
		72
	)

MainStroke.Thickness =
	1

MainStroke.Parent =
	Main

--========================================================--
-- HEADER
--========================================================--

local Brand =
	Instance.new("TextLabel")

Brand.Size =
	UDim2.new(
		1,
		-30,
		0,
		30
	)

Brand.Position =
	UDim2.fromOffset(
		15,
		10
	)

Brand.BackgroundTransparency =
	1

Brand.Text =
	"NOVA"

Brand.TextColor3 =
	Color3.fromRGB(
		255,
		255,
		255
	)

Brand.TextSize =
	25

Brand.Font =
	Enum.Font.GothamBlack

Brand.TextXAlignment =
	Enum.TextXAlignment.Left

Brand.Parent =
	Main

local Version =
	Instance.new("TextLabel")

Version.Size =
	UDim2.new(
		1,
		-30,
		0,
		18
	)

Version.Position =
	UDim2.fromOffset(
		16,
		39
	)

Version.BackgroundTransparency =
	1

Version.Text =
	"COMBAT VISUALS  •  PREMIUM"

Version.TextColor3 =
	Color3.fromRGB(
		115,
		115,
		130
	)

Version.TextSize =
	9

Version.Font =
	Enum.Font.GothamMedium

Version.TextXAlignment =
	Enum.TextXAlignment.Left

Version.Parent =
	Main

local Separator =
	Instance.new("Frame")

Separator.Size =
	UDim2.new(
		1,
		-30,
		0,
		1
	)

Separator.Position =
	UDim2.fromOffset(
		15,
		65
	)

Separator.BackgroundColor3 =
	Color3.fromRGB(
		45,
		45,
		55
	)

Separator.BorderSizePixel =
	0

Separator.Parent =
	Main

local Status =
	Instance.new("TextLabel")

Status.Size =
	UDim2.new(
		1,
		-30,
		0,
		22
	)

Status.Position =
	UDim2.fromOffset(
		15,
		73
	)

Status.BackgroundTransparency =
	1

Status.Text =
	"●  SYSTEM READY"

Status.TextColor3 =
	Color3.fromRGB(
		90,
		255,
		120
	)

Status.TextSize =
	10

Status.Font =
	Enum.Font.GothamBold

Status.TextXAlignment =
	Enum.TextXAlignment.Left

Status.Parent =
	Main

--========================================================--
-- TOGGLES
--========================================================--

local function createToggle(
	y,
	title,
	description
)

	local Holder =
		Instance.new("Frame")

	Holder.Size =
		UDim2.new(
			1,
			-30,
			0,
			62
		)

	Holder.Position =
		UDim2.fromOffset(
			15,
			y
		)

	Holder.BackgroundColor3 =
		Color3.fromRGB(
			23,
			23,
			29
		)

	Holder.BorderSizePixel =
		0

	Holder.Parent =
		Main

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(
			0,
			10
		)

	Corner.Parent =
		Holder

	local Stroke =
		Instance.new("UIStroke")

	Stroke.Color =
		Color3.fromRGB(
			42,
			42,
			52
		)

	Stroke.Parent =
		Holder

	local Title =
		Instance.new("TextLabel")

	Title.Size =
		UDim2.new(
			1,
			-80,
			0,
			23
		)

	Title.Position =
		UDim2.fromOffset(
			13,
			7
		)

	Title.BackgroundTransparency =
		1

	Title.Text =
		title

	Title.TextColor3 =
		Color3.fromRGB(
			240,
			240,
			245
		)

	Title.TextSize =
		14

	Title.Font =
		Enum.Font.GothamBold

	Title.TextXAlignment =
		Enum.TextXAlignment.Left

	Title.Parent =
		Holder

	local Description =
		Instance.new("TextLabel")

	Description.Size =
		UDim2.new(
			1,
			-80,
			0,
			20
		)

	Description.Position =
		UDim2.fromOffset(
			13,
			31
		)

	Description.BackgroundTransparency =
		1

	Description.Text =
		description

	Description.TextColor3 =
		Color3.fromRGB(
			115,
			115,
			130
		)

	Description.TextSize =
		9

	Description.Font =
		Enum.Font.Gotham

	Description.TextXAlignment =
		Enum.TextXAlignment.Left

	Description.Parent =
		Holder

	local Toggle =
		Instance.new("TextButton")

	Toggle.Size =
		UDim2.fromOffset(
			50,
			26
		)

	Toggle.Position =
		UDim2.new(
			1,
			-63,
			0.5,
			-13
		)

	Toggle.BackgroundColor3 =
		Color3.fromRGB(
			55,
			55,
			65
		)

	Toggle.BorderSizePixel =
		0

	Toggle.Text =
		""

	Toggle.AutoButtonColor =
		false

	Toggle.Parent =
		Holder

	local ToggleCorner =
		Instance.new("UICorner")

	ToggleCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	ToggleCorner.Parent =
		Toggle

	local Knob =
		Instance.new("Frame")

	Knob.Size =
		UDim2.fromOffset(
			20,
			20
		)

	Knob.Position =
		UDim2.fromOffset(
			3,
			3
		)

	Knob.BackgroundColor3 =
		Color3.fromRGB(
			220,
			220,
			225
		)

	Knob.BorderSizePixel =
		0

	Knob.Parent =
		Toggle

	local KnobCorner =
		Instance.new("UICorner")

	KnobCorner.CornerRadius =
		UDim.new(
			1,
			0
		)

	KnobCorner.Parent =
		Knob

	return Toggle, Knob
end

local ESPToggle, ESPKnob =
	createToggle(
		102,
		"Player ESP",
		"Highlight enemy players"
	)

local TeamToggle, TeamKnob =
	createToggle(
		170,
		"Team Check",
		"Opposite team only"
	)

local AimToggle, AimKnob =
	createToggle(
		238,
		"Aim Lock",
		"Hold Left Alt inside FOV"
	)

local function updateToggle(
	toggle,
	knob,
	enabled
)

	local toggleColor
	local knobPosition

	if enabled then

		toggleColor =
			Color3.fromRGB(
				45,
				115,
				65
			)

		knobPosition =
			UDim2.fromOffset(
				27,
				3
			)

	else

		toggleColor =
			Color3.fromRGB(
				55,
				55,
				65
			)

		knobPosition =
			UDim2.fromOffset(
				3,
				3
			)
	end

	TweenService:Create(
		toggle,
		TweenInfo.new(
			0.15,
			Enum.EasingStyle.Quad
		),
		{
			BackgroundColor3 =
				toggleColor
		}
	):Play()

	TweenService:Create(
		knob,
		TweenInfo.new(
			0.15,
			Enum.EasingStyle.Quad
		),
		{
			Position =
				knobPosition
		}
	):Play()
end

local function updateUI()

	updateToggle(
		ESPToggle,
		ESPKnob,
		ESP_ENABLED
	)

	updateToggle(
		TeamToggle,
		TeamKnob,
		TEAM_CHECK_ENABLED
	)

	updateToggle(
		AimToggle,
		AimKnob,
		AIM_ENABLED
	)

	if AIM_ENABLED then

		Status.Text =
			"●  AIM SYSTEM READY"

	else

		Status.Text =
			"●  SYSTEM READY"
	end
end

--========================================================--
-- FOV
--========================================================--

local FOV =
	Instance.new("Frame")

FOV.Name =
	"AimFOV"

FOV.Size =
	UDim2.fromOffset(
		FOV_RADIUS * 2,
		FOV_RADIUS * 2
	)

FOV.AnchorPoint =
	Vector2.new(
		0.5,
		0.5
	)

FOV.BackgroundTransparency =
	1

FOV.Visible =
	false

FOV.ZIndex =
	2

FOV.Parent =
	Gui

local FOVCorner =
	Instance.new("UICorner")

FOVCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

FOVCorner.Parent =
	FOV

local FOVStroke =
	Instance.new("UIStroke")

FOVStroke.Thickness =
	1.5

FOVStroke.Transparency =
	0.2

FOVStroke.Color =
	AIM_COLOR

FOVStroke.Parent =
	FOV

--========================================================--
-- AIM PART
--========================================================--

local AimNames = {
	"Head",
	"UpperTorso",
	"Torso",
	"HumanoidRootPart",
	"LowerTorso",
	"Chest",
	"Body",
	"Root",
	"Pelvis",
	"Spine",
}

local function getAimPart(character)

	if not character then
		return nil
	end

	for _, name in ipairs(
		AimNames
	) do

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

	return character:FindFirstChildWhichIsA(
		"BasePart",
		true
	)
end

--========================================================--
-- TARGET SEARCH
--========================================================--

local function findClosestEnemy()

	local camera =
		getCamera()

	if not camera then
		return nil
	end

	local center =
		Vector2.new(
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		)

	local closestPart =
		nil

	local closestDistance =
		FOV_RADIUS

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer
			and isEnemy(player) then

			local character =
				player.Character

			if character then

				local humanoid =
					character:FindFirstChildOfClass(
						"Humanoid"
					)

				if humanoid
					and humanoid.Health > 0 then

					local part =
						getAimPart(character)

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
									screen -
									center
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
		end
	end

	return closestPart
end

--========================================================--
-- AIM LOCK
--========================================================--
-- НЕ МЕНЯЮ ПРИНЦИП ТВОЕГО РАБОЧЕГО AIM.
-- Быстрое наведение через Camera.CFrame.
--========================================================--

local function aimAt(part)

	if not part
		or not part.Parent then

		return
	end

	local camera =
		getCamera()

	if not camera then
		return
	end

	local cameraPosition =
		camera.CFrame.Position

	local direction =
		part.Position -
		cameraPosition

	if direction.Magnitude < 0.001 then
		return
	end

	camera.CFrame =
		CFrame.lookAt(
			cameraPosition,
			part.Position
		)
end

--========================================================--
-- TOGGLES
--========================================================--

ESPToggle.MouseButton1Click:Connect(
	function()

		ESP_ENABLED =
			not ESP_ENABLED

		refreshESP()
		updateUI()
	end
)

TeamToggle.MouseButton1Click:Connect(
	function()

		TEAM_CHECK_ENABLED =
			not TEAM_CHECK_ENABLED

		refreshESP()
		updateUI()
	end
)

AimToggle.MouseButton1Click:Connect(
	function()

		AIM_ENABLED =
			not AIM_ENABLED

		FOV.Visible =
			AIM_ENABLED

		if not AIM_ENABLED then

			AIM_HOLDING =
				false
		end

		updateUI()
	end
)

--========================================================--
-- INPUT
--========================================================--

UserInputService.InputBegan:Connect(
	function(
		input,
		processed
	)

		if processed then
			return
		end

		if input.KeyCode ==
			AIM_KEY then

			if AIM_ENABLED then
				AIM_HOLDING = true
			end

			return
		end

		if input.KeyCode ==
			MENU_KEY then

			Main.Visible =
				not Main.Visible

			return
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.KeyCode ==
			AIM_KEY then

			AIM_HOLDING =
				false
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

	-- Standard Team
	player:GetPropertyChangedSignal(
		"Team"
	):Connect(
		function()

			if TEAM_CHECK_ENABLED then
				createESP(player)
			end
		end
	)

	-- TeamColor
	player:GetPropertyChangedSignal(
		"TeamColor"
	):Connect(
		function()

			if TEAM_CHECK_ENABLED then
				createESP(player)
			end
		end
	)

	-- Common custom Team attributes
	for _, name in ipairs(
		TEAM_ATTRIBUTE_NAMES
	) do

		player:GetAttributeChangedSignal(
			name
		):Connect(
			function()

				if TEAM_CHECK_ENABLED then
					createESP(player)
				end
			end
		)
	end
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

LocalPlayer:GetPropertyChangedSignal(
	"TeamColor"
):Connect(
	function()

		if TEAM_CHECK_ENABLED then
			refreshESP()
		end
	end
)

for _, name in ipairs(
	TEAM_ATTRIBUTE_NAMES
) do

	LocalPlayer:GetAttributeChangedSignal(
		name
	):Connect(
		function()

			if TEAM_CHECK_ENABLED then
				refreshESP()
			end
		end
	)
end

--========================================================--
-- RENDER
--========================================================--

local lastTargetUpdate = 0
local targetUpdateInterval = 1 / 30
local currentTarget = nil

RunService:BindToRenderStep(
	"PremiumAimSystem",
	Enum.RenderPriority.Camera.Value + 1,
	function(dt)

		local camera =
			getCamera()

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

			currentTarget =
				nil

			return
		end

		lastTargetUpdate += dt

		if lastTargetUpdate >=
			targetUpdateInterval
			or not currentTarget
			or not currentTarget.Parent then

			lastTargetUpdate = 0

			currentTarget =
				findClosestEnemy()
		end

		if currentTarget then
			aimAt(
				currentTarget
			)
		end
	end
)

--========================================================--
-- START
--========================================================--

updateUI()

FOV.Visible =
	false

Main.Visible =
	true
