--========================================================--
--        PREMIUM ESP + TEAM CHECK + AIM LOCK            --
--                    LocalScript                         --
--========================================================--
--
-- Put this LocalScript in:
-- StarterPlayer > StarterPlayerScripts
--
-- Controls:
-- Left Alt  = hold Aim Lock
-- Right Alt = show / hide menu
--
-- Features:
-- ESP
-- Team Check
-- Fast Aim Lock
-- FOV
-- No wall/visibility check
-- Premium UI
-- Welcome notification
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

	AimKey = Enum.KeyCode.LeftAlt,
	MenuKey = Enum.KeyCode.RightAlt,

	FOVRadius = 300,

	-- 1 = almost instant
	-- 0.5 = fast
	-- 0.2 = smooth
	AimSmoothness = 1,

	ESPColor = Color3.fromRGB(255, 70, 95),
	ESPFillTransparency = 0.78,

	-- Center-body preference
	AimParts = {
		"UpperTorso",
		"Torso",
		"HumanoidRootPart",
		"LowerTorso",
		"Head",
		"Chest",
		"Body",
		"Root",
		"Pelvis",
		"Spine",
	},
}

--========================================================--
-- CLEAN OLD GUI / FOLDER
--========================================================--

pcall(function()
	local oldGui = PlayerGui:FindFirstChild("PremiumCombatUI")
	if oldGui then
		oldGui:Destroy()
	end
end)

pcall(function()
	local oldFolder = workspace:FindFirstChild("PremiumESP")
	if oldFolder then
		oldFolder:Destroy()
	end
end)

pcall(function()
	RunService:UnbindFromRenderStep("PremiumAimLock")
end)

--========================================================--
-- CAMERA
--========================================================--

local Camera = workspace.CurrentCamera

local function getCamera()
	Camera = workspace.CurrentCamera
	return Camera
end

--========================================================--
-- ESP
--========================================================--

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PremiumESP"
ESPFolder.Parent = workspace

local ESPObjects = {}

--========================================================--
-- TEAM RESOLVER
--========================================================--

local function getAttributeTeam(container)
	if not container then
		return nil
	end

	local names = {
		"Team",
		"TeamName",
		"Faction",
		"Side",
		"TeamId",
		"TeamID",
		"FactionName",
		"SideName",
	}

	for _, name in ipairs(names) do
		local value = container:GetAttribute(name)

		if value ~= nil then
			return value
		end
	end

	return nil
end

local function getValueTeam(container)
	if not container then
		return nil
	end

	local names = {
		"Team",
		"TeamName",
		"Faction",
		"Side",
		"TeamId",
		"TeamID",
		"FactionName",
		"SideName",
	}

	for _, name in ipairs(names) do
		local object = container:FindFirstChild(name)

		if object then

			if object:IsA("StringValue")
				or object:IsA("IntValue")
				or object:IsA("NumberValue")
				or object:IsA("BoolValue") then

				return object.Value
			end

			if object:IsA("ObjectValue") then
				return object.Value
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
	-- 2. TeamColor
	--==================================================

	if player.TeamColor ~= nil then
		return player.TeamColor
	end

	--==================================================
	-- 3. Player attributes
	--==================================================

	local attributeTeam =
		getAttributeTeam(player)

	if attributeTeam ~= nil then
		return attributeTeam
	end

	--==================================================
	-- 4. Player values
	--==================================================

	local valueTeam =
		getValueTeam(player)

	if valueTeam ~= nil then
		return valueTeam
	end

	--==================================================
	-- 5. Character
	--==================================================

	local character = player.Character

	if character then

		local characterAttribute =
			getAttributeTeam(character)

		if characterAttribute ~= nil then
			return characterAttribute
		end

		local characterValue =
			getValueTeam(character)

		if characterValue ~= nil then
			return characterValue
		end
	end

	return nil
end

local function teamEquals(a, b)
	if a == nil or b == nil then
		return nil
	end

	if typeof(a) == "Instance"
		and typeof(b) == "Instance" then

		return a == b
	end

	if typeof(a) == "BrickColor"
		and typeof(b) == "BrickColor" then

		return a == b
	end

	if typeof(a) == "Color3"
		and typeof(b) == "Color3" then

		return a == b
	end

	return tostring(a) == tostring(b)
end

local function isEnemy(player)
	if not player then
		return false
	end

	if player == LocalPlayer then
		return false
	end

	-- Team Check OFF
	if not Config.TeamCheckEnabled then
		return true
	end

	local myTeam =
		resolveTeam(LocalPlayer)

	local otherTeam =
		resolveTeam(player)

	-- Both teams known
	if myTeam ~= nil
		and otherTeam ~= nil then

		local same =
			teamEquals(
				myTeam,
				otherTeam
			)

		if same == true then
			return false
		end

		if same == false then
			return true
		end
	end

	-- If team information cannot be resolved,
	-- do not classify the player as an enemy.
	return false
end

--========================================================--
-- ESP REMOVE
--========================================================--

local function removeESP(player)
	local object =
		ESPObjects[player]

	if not object then
		return
	end

	object:Destroy()
	ESPObjects[player] = nil
end

--========================================================--
-- ESP CREATE
--========================================================--

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
		Config.ESPFillTransparency

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
		17,
		17,
		22
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
		85,
		85,
		100
	)

WelcomeStroke.Thickness =
	1

WelcomeStroke.Parent =
	Welcome

local Accent =
	Instance.new("Frame")

Accent.Size =
	UDim2.fromOffset(
		4,
		65
	)

Accent.Position =
	UDim2.fromOffset(
		9,
		15
	)

Accent.BackgroundColor3 =
	Config.ESPColor

Accent.BorderSizePixel =
	0

Accent.ZIndex =
	201

Accent.Parent =
	Welcome

local AccentCorner =
	Instance.new("UICorner")

AccentCorner.CornerRadius =
	UDim.new(
		1,
		0
	)

AccentCorner.Parent =
	Accent

local WelcomeTitle =
	Instance.new("TextLabel")

WelcomeTitle.Size =
	UDim2.new(
		1,
		-35,
		0,
		32
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
		-35,
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
	"Premium combat system initialized"

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
							-195,
							0,
							-120
						)
				}
			)

		out:Play()

		out.Completed:Connect(
			function()
				if Welcome then
					Welcome:Destroy()
				end
			end
		)
	end
)

--========================================================--
-- MAIN
--========================================================--

local Main =
	Instance.new("Frame")

Main.Name =
	"Main"

Main.Size =
	UDim2.fromOffset(
		360,
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
		75
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

	local corner =
		Instance.new("UICorner")

	corner.CornerRadius =
		UDim.new(
			0,
			10
		)

	corner.Parent =
		Holder

	local stroke =
		Instance.new("UIStroke")

	stroke.Color =
		Color3.fromRGB(
			42,
			42,
			52
		)

	stroke.Parent =
		Holder

	local titleLabel =
		Instance.new("TextLabel")

	titleLabel.Size =
		UDim2.new(
			1,
			-80,
			0,
			22
		)

	titleLabel.Position =
		UDim2.fromOffset(
			13,
			7
		)

	titleLabel.BackgroundTransparency =
		1

	titleLabel.Text =
		title

	titleLabel.TextColor3 =
		Color3.fromRGB(
			240,
			240,
			245
		)

	titleLabel.TextSize =
		14

	titleLabel.Font =
		Enum.Font.GothamBold

	titleLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	titleLabel.Parent =
		Holder

	local descriptionLabel =
		Instance.new("TextLabel")

	descriptionLabel.Size =
		UDim2.new(
			1,
			-80,
			0,
			20
		)

	descriptionLabel.Position =
		UDim2.fromOffset(
			13,
			31
		)

	descriptionLabel.BackgroundTransparency =
		1

	descriptionLabel.Text =
		description

	descriptionLabel.TextColor3 =
		Color3.fromRGB(
			115,
			115,
			130
		)

	descriptionLabel.TextSize =
		9

	descriptionLabel.Font =
		Enum.Font.Gotham

	descriptionLabel.TextXAlignment =
		Enum.TextXAlignment.Left

	descriptionLabel.Parent =
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
		"PLAYER ESP",
		"Highlight enemy players"
	)

local TeamToggle, TeamKnob =
	createToggle(
		170,
		"TEAM CHECK",
		"Opposite team only"
	)

local AimToggle, AimKnob =
	createToggle(
		238,
		"AIM LOCK",
		"Hold Left Alt inside FOV"
	)

local function updateToggle(
	toggle,
	knob,
	enabled
)

	local color
	local position

	if enabled then

		color =
			Color3.fromRGB(
				45,
				115,
				65
			)

		position =
			UDim2.fromOffset(
				27,
				3
			)

	else

		color =
			Color3.fromRGB(
				55,
				55,
				65
			)

		position =
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
			BackgroundColor3 = color
		}
	):Play()

	TweenService:Create(
		knob,
		TweenInfo.new(
			0.15,
			Enum.EasingStyle.Quad
		),
		{
			Position = position
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
		Config.FOVRadius * 2,
		Config.FOVRadius * 2
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
	Config.AimColor or Config.ESPColor

FOVStroke.Parent =
	FOV

--========================================================--
-- AIM PART
--========================================================--

local function getAimPart(character)

	if not character then
		return nil
	end

	for _, name in ipairs(
		Config.AimParts
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
-- TARGET
--========================================================--

local CurrentTarget = nil

local function targetValid(player, part)

	if not player
		or player == LocalPlayer then

		return false
	end

	if not isEnemy(player) then
		return false
	end

	local character =
		player.Character

	if not character then
		return false
	end

	local humanoid =
		character:FindFirstChildOfClass(
			"Humanoid"
		)

	if not humanoid
		or humanoid.Health <= 0 then

		return false
	end

	if not part
		or not part.Parent then

		return false
	end

	return true
end

local function getClosestTarget()

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

	local bestPlayer = nil
	local bestPart = nil
	local bestDistance =
		Config.FOVRadius

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

				local part =
					getAimPart(character)

				if humanoid
					and humanoid.Health > 0
					and part then

					-- Deliberately no Raycast.
					-- Walls do not remove the target.

					local screen =
						camera:WorldToViewportPoint(
							part.Position
						)

					if screen.Z > 0 then

						local screenPosition =
							Vector2.new(
								screen.X,
								screen.Y
							)

						local distance =
							(
								screenPosition -
								center
							).Magnitude

						if distance <
							bestDistance then

							bestDistance =
								distance

							bestPlayer =
								player

							bestPart =
								part
						end
					end
				end
			end
		end
	end

	return bestPlayer, bestPart
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
		getCamera()

	if not camera then
		return
	end

	local origin =
		camera.CFrame.Position

	local difference =
		part.Position -
		origin

	if difference.Magnitude <=
		0.001 then

		return
	end

	local targetCFrame =
		CFrame.lookAt(
			origin,
			part.Position
		)

	-- Fast / instant
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
-- BUTTON EVENTS
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

		CurrentTarget =
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

			CurrentTarget =
				nil
		end

		FOV.Visible =
			Config.AimEnabled

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

		-- Left Alt = Aim
		if input.KeyCode ==
			Config.AimKey then

			if Config.AimEnabled then

				Config.AimHolding =
					true

				CurrentTarget =
					nil
			end

			return
		end

		-- Right Alt = Menu
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

			CurrentTarget =
				nil
		end
	end
)

--========================================================--
-- PLAYER SETUP
--========================================================--

local function setupPlayer(player)

	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(
		function()

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

			removeESP(
				player
			)

			if CurrentTarget
				and CurrentTarget.Parent
				and CurrentTarget.Parent ==
					player.Character then

				CurrentTarget =
					nil
			end
		end
	)

	player:GetPropertyChangedSignal(
		"Team"
	):Connect(
		function()

			if Config.TeamCheckEnabled then

				createESP(
					player
				)

				if CurrentTarget
					and CurrentTarget.Parent
					and CurrentTarget.Parent ==
						player.Character then

					if not isEnemy(player) then
						CurrentTarget =
							nil
					end
				end
			end
		end
	)

	player:GetPropertyChangedSignal(
		"TeamColor"
	):Connect(
		function()

			if Config.TeamCheckEnabled then
				createESP(player)
			end
		end
	)

	for _, attributeName in ipairs({
		"Team",
		"TeamName",
		"TeamId",
		"TeamID",
		"Faction",
		"Side",
	}) do

		player:GetAttributeChangedSignal(
			attributeName
		):Connect(
			function()

				if Config.TeamCheckEnabled then
					createESP(player)

					if CurrentTarget
						and CurrentTarget.Parent ==
							player.Character
						and not isEnemy(player) then

						CurrentTarget =
							nil
					end
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
end

Players.PlayerAdded:Connect(
	setupPlayer
)

Players.PlayerRemoving:Connect(
	function(player)

		removeESP(
			player
		)

		if CurrentTarget
			and CurrentTarget.Parent ==
				player.Character then

			CurrentTarget =
				nil
		end
	end
)

--========================================================--
-- LOCAL TEAM CHANGE
--========================================================--

LocalPlayer:GetPropertyChangedSignal(
	"Team"
):Connect(
	function()

		if Config.TeamCheckEnabled then

			CurrentTarget =
				nil

			refreshESP()
		end
	end
)

LocalPlayer:GetPropertyChangedSignal(
	"TeamColor"
):Connect(
	function()

		if Config.TeamCheckEnabled then
			CurrentTarget =
				nil

			refreshESP()
		end
	end
)

for _, attributeName in ipairs({
	"Team",
	"TeamName",
	"TeamId",
	"TeamID",
	"Faction",
	"Side",
}) do

	LocalPlayer:GetAttributeChangedSignal(
		attributeName
	):Connect(
		function()

			if Config.TeamCheckEnabled then

				CurrentTarget =
					nil

				refreshESP()
			end
		end
	)
end

--========================================================--
-- RENDER
--========================================================--

RunService:BindToRenderStep(
	"PremiumAimLock",
	Enum.RenderPriority.Camera.Value + 1,
	function()

		local camera =
			getCamera()

		if not camera then
			return
		end

		-- Keep FOV in screen center.
		FOV.Position =
			UDim2.fromOffset(
				camera.ViewportSize.X / 2,
				camera.ViewportSize.Y / 2
			)

		-- Nothing to do while Aim is off.
		if not Config.AimEnabled then
			return
		end

		-- Left Alt released.
		if not Config.AimHolding then
			return
		end

		-- Validate current target.
		if CurrentTarget then

			local targetPlayer =
				Players:GetPlayerFromCharacter(
					CurrentTarget.Parent
				)

			if not targetPlayer
				or not targetValid(
					targetPlayer,
					CurrentTarget
				) then

				CurrentTarget =
					nil
			end
		end

		-- Find target when needed.
		if not CurrentTarget then

			local player, part =
				getClosestTarget()

			if player
				and part then

				CurrentTarget =
					part
			end
		end

		-- Aim.
		if CurrentTarget then
			aimAt(
				CurrentTarget
			)
		end
	end
)

--========================================================--
-- START
--========================================================--

updateUI()

FOV.Visible = false
Main.Visible = true