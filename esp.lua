--========================================================--
--              NOVA COMBAT SYSTEM                       --
--       ESP + UNIVERSAL TEAM CHECK + AIM LOCK           --
--========================================================--
--
-- LocalScript
-- StarterPlayer > StarterPlayerScripts
--
-- LEFT ALT  = HOLD AIM
-- RIGHT ALT = SHOW / HIDE MENU
--
--========================================================--

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--========================================================--
-- CONFIG
--========================================================--

local Config = {

	ESPEnabled = false,
	TeamCheckEnabled = false,
	AimEnabled = false,
	AimHolding = false,

	FOV = 300,

	-- 1 = instant
	-- 0.5 = very fast
	-- 0.2 = smooth
	AimSmoothness = 1,

	AimKey = Enum.KeyCode.LeftAlt,
	MenuKey = Enum.KeyCode.RightAlt,

	ESPColor = Color3.fromRGB(
		255,
		65,
		90
	),

	EnemyColor = Color3.fromRGB(
		255,
		65,
		90
	),

	FriendlyColor = Color3.fromRGB(
		80,
		170,
		255
	),

	-- How often target selection is recalculated.
	TargetUpdateRate = 1 / 30,
}

--========================================================--
-- CLEAN PREVIOUS INSTANCE
--========================================================--

pcall(function()
	local old = PlayerGui:FindFirstChild(
		"NOVA_COMBAT_SYSTEM"
	)

	if old then
		old:Destroy()
	end
end)

pcall(function()
	RunService:UnbindFromRenderStep(
		"NOVA_AIM_LOCK"
	)
end)

--========================================================--
-- CAMERA
--========================================================--

local Camera = workspace.CurrentCamera

local function getCamera()

	Camera =
		workspace.CurrentCamera

	return Camera
end

--========================================================--
-- TEAM RESOLVER
--========================================================--

local TeamAttributeNames = {

	"Team",
	"TeamName",
	"TeamId",
	"TeamID",

	"Faction",
	"FactionName",

	"Side",
	"SideName",

	"Group",
	"GroupName",

	"Alignment",
	"Allegiance",

}

local TeamValueNames = {

	"Team",
	"TeamName",
	"TeamId",
	"TeamID",

	"Faction",
	"FactionName",

	"Side",
	"SideName",

	"Group",
	"GroupName",

	"Alignment",
	"Allegiance",

}

local function normalizeTeam(value)

	if value == nil then
		return nil
	end

	if typeof(value) == "Instance" then

		if value:IsA("ObjectValue") then
			return value.Value
		end

		if value:IsA("StringValue")
			or value:IsA("IntValue")
			or value:IsA("NumberValue")
			or value:IsA("BoolValue") then

			return value.Value
		end

	end

	return value
end

local function readAttributes(container)

	if not container then
		return nil
	end

	for _, name in ipairs(
		TeamAttributeNames
	) do

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

	for _, name in ipairs(
		TeamValueNames
	) do

		local object =
			container:FindFirstChild(name)

		if object then

			local value =
				normalizeTeam(object)

			if value ~= nil then
				return value
			end
		end
	end

	return nil
end

local function findTeamDeep(container)

	if not container then
		return nil
	end

	for _, name in ipairs({
		"Team",
		"Faction",
		"Side",
		"Group",
		"Allegiance",
	}) do

		local object =
			container:FindFirstChild(
				name,
				true
			)

		if object then

			local value =
				normalizeTeam(object)

			if value ~= nil then
				return value
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
	-- STANDARD ROBLOX TEAM
	--==================================================

	if player.Team ~= nil then
		return player.Team
	end

	--==================================================
	-- TEAM COLOR
	--==================================================

	if player.TeamColor ~= nil then
		return player.TeamColor
	end

	--==================================================
	-- ATTRIBUTES
	--==================================================

	local value =
		readAttributes(player)

	if value ~= nil then
		return value
	end

	--==================================================
	-- VALUE OBJECTS
	--==================================================

	value =
		readValues(player)

	if value ~= nil then
		return value
	end

	--==================================================
	-- DEEP TEAM OBJECT
	--==================================================

	value =
		findTeamDeep(player)

	if value ~= nil then
		return value
	end

	--==================================================
	-- CHARACTER
	--==================================================

	local character =
		player.Character

	if character then

		value =
			readAttributes(
				character
			)

		if value ~= nil then
			return value
		end

		value =
			readValues(
				character
			)

		if value ~= nil then
			return value
		end

		value =
			findTeamDeep(
				character
			)

		if value ~= nil then
			return value
		end
	end

	return nil
end

local function sameTeam(
	playerA,
	playerB
)

	local teamA =
		resolveTeam(playerA)

	local teamB =
		resolveTeam(playerB)

	if teamA == nil
		or teamB == nil then

		return nil
	end

	if typeof(teamA) == "Instance"
		and typeof(teamB) == "Instance" then

		return teamA == teamB
	end

	if typeof(teamA) == "BrickColor"
		and typeof(teamB) == "BrickColor" then

		return teamA == teamB
	end

	if typeof(teamA) == "Color3"
		and typeof(teamB) == "Color3" then

		return teamA == teamB
	end

	return tostring(teamA)
		== tostring(teamB)
end

local function isEnemy(player)

	if not player
		or player == LocalPlayer then

		return false
	end

	if not Config.TeamCheckEnabled then
		return true
	end

	local result =
		sameTeam(
			LocalPlayer,
			player
		)

	-- Same team = NEVER enemy
	if result == true then
		return false
	end

	-- Different team = enemy
	if result == false then
		return true
	end

	-- Unknown team = do not highlight/target.
	return false
end

--========================================================--
-- ESP
--========================================================--

local ESPFolder =
	Instance.new("Folder")

ESPFolder.Name =
	"NOVA_ESP"

ESPFolder.Parent =
	workspace

local ESPObjects = {}

local function removeESP(player)

	local highlight =
		ESPObjects[player]

	if highlight then
		highlight:Destroy()
	end

	ESPObjects[player] =
		nil
end

local function createESP(player)

	removeESP(player)

	if not Config.ESPEnabled then
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
		Config.ESPColor

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

--========================================================--
-- GUI
--========================================================--

local Gui =
	Instance.new("ScreenGui")

Gui.Name =
	"NOVA_COMBAT_SYSTEM"

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
		390,
		95
	)

Welcome.Position =
	UDim2.new(
		0.5,
		-195,
		0,
		-120
	)

Welcome.BackgroundColor3 =
	Color3.fromRGB(
		15,
		15,
		20
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
		80,
		80,
		95
	)

WelcomeStroke.Thickness =
	1

WelcomeStroke.Parent =
	Welcome

local WelcomeAccent =
	Instance.new("Frame")

WelcomeAccent.Size =
	UDim2.fromOffset(
		4,
		65
	)

WelcomeAccent.Position =
	UDim2.fromOffset(
		9,
		15
	)

WelcomeAccent.BackgroundColor3 =
	Config.EnemyColor

WelcomeAccent.BorderSizePixel =
	0

WelcomeAccent.ZIndex =
	201

WelcomeAccent.Parent =
	Welcome

local WelcomeAccentCorner =
	Instance.new("UICorner")

WelcomeAccentCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

WelcomeAccentCorner.Parent =
	WelcomeAccent

local WelcomeTitle =
	Instance.new("TextLabel")

WelcomeTitle.Size =
	UDim2.new(
		1,
		-45,
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

local WelcomeSub =
	Instance.new("TextLabel")

WelcomeSub.Size =
	UDim2.new(
		1,
		-45,
		0,
		25
	)

WelcomeSub.Position =
	UDim2.fromOffset(
		25,
		48
	)

WelcomeSub.BackgroundTransparency =
	1

WelcomeSub.Text =
	"Premium combat interface initialized"

WelcomeSub.TextColor3 =
	Color3.fromRGB(
		145,
		145,
		160
	)

WelcomeSub.TextSize =
	11

WelcomeSub.Font =
	Enum.Font.Gotham

WelcomeSub.TextXAlignment =
	Enum.TextXAlignment.Left

WelcomeSub.ZIndex =
	201

WelcomeSub.Parent =
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
				-195,
				0,
				25
			)
	}
):Play()

task.delay(
	3,
	function()

		if not Welcome.Parent then
			return
		end

		local tween =
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
							-195,
							0,
							-120
						)
				}
			)

		tween:Play()

		tween.Completed:Connect(
			function()

				if Welcome.Parent then
					Welcome:Destroy()
				end
			end
		)
	end
)

--========================================================--
-- MAIN WINDOW
--========================================================--

local Main =
	Instance.new("Frame")

Main.Name =
	"Main"

Main.Size =
	UDim2.fromOffset(
		365,
		360
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
	"COMBAT VISUALS  •  UNIVERSAL"

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
		20
	)

Status.Position =
	UDim2.fromOffset(
		15,
		74
	)

Status.BackgroundTransparency =
	1

Status.Text =
	"● SYSTEM READY"

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
-- TOGGLE CREATOR
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

	local TitleLabel =
		Instance.new("TextLabel")

	TitleLabel.Size =
		UDim2.new(
			1,
			-80,
			0,
			22
		)

	TitleLabel.Position =
		UDim2.fromOffset(
			13,
			7
		)

	TitleLabel.BackgroundTransparency =
		1

	TitleLabel.Text =
		title

	TitleLabel.TextColor3 =
		Color3.fromRGB(
			240,
			240,
			245
		)

	TitleLabel.TextSize =
		14

	TitleLabel.Font =
		Enum.Font.GothamBold

	TitleLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	TitleLabel.Parent =
		Holder

	local DescriptionLabel =
		Instance.new("TextLabel")

	DescriptionLabel.Size =
		UDim2.new(
			1,
			-80,
			0,
			20
		)

	DescriptionLabel.Position =
		UDim2.fromOffset(
			13,
			31
		)

	DescriptionLabel.BackgroundTransparency =
		1

	DescriptionLabel.Text =
		description

	DescriptionLabel.TextColor3 =
		Color3.fromRGB(
			115,
			115,
			130
		)

	DescriptionLabel.TextSize =
		9

	DescriptionLabel.Font =
		Enum.Font.Gotham

	DescriptionLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	DescriptionLabel.Parent =
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
		101,
		"PLAYER ESP",
		"Highlight enemy players"
	)

local TeamToggle, TeamKnob =
	createToggle(
		169,
		"TEAM CHECK",
		"Hide and ignore your own team"
	)

local AimToggle, AimKnob =
	createToggle(
		237,
		"AIM LOCK",
		"Hold Left Alt inside the FOV"
	)

--========================================================--
-- UI STATE
--========================================================--

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
		Config.ESPEnabled
	)

	updateToggle(
		TeamToggle,
		TeamKnob,
		Config.TeamCheckEnabled
	)

	updateToggle(
		AimToggle,
		AimKnob,
		Config.AimEnabled
	)

	if Config.AimEnabled then

		Status.Text =
			"● AIM SYSTEM READY"

	else

		Status.Text =
			"● SYSTEM READY"
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
		Config.FOV * 2,
		Config.FOV * 2
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
	Config.AimColor
		or Config.ESPColor
		or Config.EnemyColor

FOVStroke.Parent =
	FOV

--========================================================--
-- AIM PART CACHE
--========================================================--

local PartPriority = {

	"UpperTorso",
	"Torso",
	"HumanoidRootPart",
	"LowerTorso",

	"Chest",
	"Body",
	"Center",
	"Root",
	"Pelvis",
	"Spine",

	"Head",

}

local AimCache = {}

local function isValidAimPart(part)

	return part
		and part.Parent
		and part:IsA("BasePart")
		and part.Transparency < 1
end

local function findPartByName(
	character,
	name
)

	local part =
		character:FindFirstChild(
			name,
			true
		)

	if isValidAimPart(part) then
		return part
	end

	return nil
end

local function buildAimCache(player)

	local character =
		player.Character

	if not character then
		AimCache[player] = nil
		return
	end

	--==================================================
	-- PRIMARY PART
	--==================================================

	if isValidAimPart(
		character.PrimaryPart
	) then

		AimCache[player] =
			character.PrimaryPart

		return
	end

	--==================================================
	-- BODY PARTS
	--==================================================

	for _, name in ipairs(
		PartPriority
	) do

		local part =
			findPartByName(
				character,
				name
			)

		if part then

			AimCache[player] =
				part

			return
		end
	end

	--==================================================
	-- FALLBACK
	--==================================================

	for _, object in ipairs(
		character:GetDescendants()
	) do

		if isValidAimPart(object)
			and object.Name ~= "Handle" then

			AimCache[player] =
				object

			return
		end
	end

	AimCache[player] =
		nil
end

local function getAimPart(player)

	local cached =
		AimCache[player]

	if isValidAimPart(cached) then
		return cached
	end

	buildAimCache(player)

	return AimCache[player]
end

--========================================================--
-- CHARACTER CACHE
--========================================================--

local function onCharacterAdded(
	player
)

	task.defer(
		buildAimCache,
		player
)

end

local function onCharacterRemoving(
	player
)

	AimCache[player] =
		nil

end

local function setupPlayer(
	player
)

	if player ==
		LocalPlayer then

		return
	end

	player.CharacterAdded:Connect(
		function()
			onCharacterAdded(
				player
			)

			task.wait(
				0.2
			)

			createESP(
				player
			)
		end
	)

	player.CharacterRemoving:Connect(
		function()
			onCharacterRemoving(
				player
			)

			removeESP(
				player
			)
		end
	)

	-- Standard Team
	player:GetPropertyChangedSignal(
		"Team"
	):Connect(
		function()

			if TEAM_CHECK_ENABLED then

				createESP(
					player
				)
			end

			if CurrentTargetPlayer ==
				player
				and not isEnemy(player) then

				CurrentTargetPlayer =
					nil
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

	-- Common custom team attributes
	for _, name in ipairs({

		"Team",
		"TeamName",
		"TeamId",
		"TeamID",

		"Faction",
		"FactionName",

		"Side",
		"SideName",

		"Group",
		"GroupName",

	}) do

		player:GetAttributeChangedSignal(
			name
		):Connect(
			function()

				if TEAM_CHECK_ENABLED then
					createESP(
						player
					)
				end

				if CurrentTargetPlayer ==
					player
					and not isEnemy(player) then

					CurrentTargetPlayer =
						nil
				end
			end
		)
	end
end

for _, player in ipairs(
	Players:GetPlayers()
) do

	setupPlayer(
		player
	)

	if player.Character then
		buildAimCache(
			player
		)
	end
end

Players.PlayerAdded:Connect(
	setupPlayer
)

Players.PlayerRemoving:Connect(
	function(player)

		removeESP(
			player
		)

		AimCache[player] =
			nil

		if CurrentTargetPlayer ==
			player then

			CurrentTargetPlayer =
				nil
		end
	end
)

LocalPlayer:GetPropertyChangedSignal(
	"Team"
):Connect(
	function()

		if TEAM_CHECK_ENABLED then

			refreshESP()

			CurrentTargetPlayer =
				nil
		end
	end
)

LocalPlayer:GetPropertyChangedSignal(
	"TeamColor"
):Connect(
	function()

		if TEAM_CHECK_ENABLED then

			refreshESP()

			CurrentTargetPlayer =
				nil
		end
	end
)

--========================================================--
-- TARGET
--========================================================--

CurrentTargetPlayer = nil
local TargetTimer = 0

local function isTargetValid(
	player,
	part
)

	if not player
		or player ==
			LocalPlayer then

		return false
	end

	if not isEnemy(player) then
		return false
	end

	if not player.Character then
		return false
	end

	if not isValidAimPart(part) then
		return false
	end

	local humanoid =
		player.Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if humanoid
		and humanoid.Health <= 0 then

		return false
	end

	return true
end

local function getTargetScreenDistance(
	player,
	part
)

	local camera =
		getCamera()

	if not camera then
		return nil
	end

	local screen =
		camera:WorldToViewportPoint(
			part.Position
		)

	if screen.Z <= 0 then
		return nil
	end

	local center =
		Vector2.new(
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		)

	local position =
		Vector2.new(
			screen.X,
			screen.Y
		)

	return (
		position -
		center
	).Magnitude
end

local function findClosestEnemy()

	local camera =
		getCamera()

	if not camera then
		return nil
	end

	local closestPlayer =
		nil

	local closestPart =
		nil

	local closestDistance =
		Config.FOV

	for _, player in ipairs(
		Players:GetPlayers()
	) do

		if player ~= LocalPlayer
			and isEnemy(player) then

			local part =
				getAimPart(player)

			if part then

				local distance =
					getTargetScreenDistance(
						player,
						part
					)

				if distance
					and distance < closestDistance then

					closestDistance =
						distance

					closestPlayer =
						player

					closestPart =
						part
				end
			end
		end
	end

	return closestPlayer,
		closestPart
end

--========================================================--
-- AIM
--========================================================--

local function aimAt(
	part
)

	if not isValidAimPart(part) then
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

	if direction.Magnitude <=
		0.001 then

		return
	end

	local targetCFrame =
		CFrame.lookAt(
			cameraPosition,
			part.Position
		)

	if Config.AimSmoothness >= 1 then

		camera.CFrame =
			targetCFrame

	else

		camera.CFrame =
			camera.CFrame:Lerp(
				targetCFrame,
				Config.AimSmoothness
			)
	end
end

--========================================================--
-- AIM INPUT
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
			Config.AimKey then

			if Config.AimEnabled then

				Config.AimHolding =
					true

				CurrentTargetPlayer =
					nil

				TargetTimer = 1
			end

			return
		end

		if input.KeyCode ==
			Config.MenuKey then

			Main.Visible =
				not Main.Visible

			return
		end
	end
)

UserInputService.InputEnded:Connect(
	function(input)

		if input.KeyCode ==
			Config.AimKey then

			Config.AimHolding =
				false

			CurrentTargetPlayer =
				nil
		end
	end
)

--========================================================--
-- BUTTONS
--========================================================--

ESPToggle.MouseButton1Click:Connect(
	function()

		Config.ESPEnabled =
			not Config.ESPEnabled

		refreshESP()
		updateUI()
	end
)

TeamToggle.MouseButton1Click:Connect(
	function()

		Config.TeamCheckEnabled =
			not Config.TeamCheckEnabled

		CurrentTargetPlayer =
			nil

		refreshESP()
		updateUI()
	end
)

AimToggle.MouseButton1Click:Connect(
	function()

		Config.AimEnabled =
			not Config.AimEnabled

		if not Config.AimEnabled then

			Config.AimHolding =
				false

			CurrentTargetPlayer =
				nil
		end

		FOV.Visible =
			Config.AimEnabled

		updateUI()
	end
)

--========================================================--
-- MAIN RENDER
--========================================================--

RunService:BindToRenderStep(
	"NOVA_AIM_LOCK",
	Enum.RenderPriority.Camera.Value + 1,
	function(dt)

		local camera =
			getCamera()

		if not camera then
			return
		end

		-- FOV center
		FOV.Position =
			UDim2.fromOffset(
				camera.ViewportSize.X / 2,
				camera.ViewportSize.Y / 2
			)

		if not Config.AimEnabled
			or not Config.AimHolding then

			return
		end

		TargetTimer += dt

		-- Reacquire target periodically
		if TargetTimer >=
			Config.TargetUpdateRate
			or not CurrentTargetPlayer then

			TargetTimer = 0

			local player, part =
				findClosestEnemy()

			CurrentTargetPlayer =
				player
		end

		if not CurrentTargetPlayer then
			return
		end

		local targetPart =
			getAimPart(
				CurrentTargetPlayer
			)

		if not isTargetValid(
			CurrentTargetPlayer,
			targetPart
		) then

			CurrentTargetPlayer =
				nil

			return
		end

		aimAt(
			targetPart
		)
	end
)

--========================================================--
-- START
--========================================================--

updateUI()

FOV.Visible = false
Main.Visible = true