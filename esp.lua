--========================================================--
--              PREMIUM ESP / AIM SYSTEM                 --
--                  LocalScript                           --
--                                                        --
-- StarterPlayer > StarterPlayerScripts                   --
--                                                        --
-- Left Alt  = Hold Aim                                  --
-- Right Alt = Show / Hide Menu                           --
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
	ESP = false,
	TeamCheck = false,
	Aim = false,

	FOV = 300,
	AimSpeed = 1,

	AimKey = Enum.KeyCode.LeftAlt,
	MenuKey = Enum.KeyCode.RightAlt,

	ESPColor = Color3.fromRGB(255, 70, 95),
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
-- ESP STORAGE
--========================================================--

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "PremiumESP"
ESPFolder.Parent = workspace

local ESPObjects = {}

--========================================================--
-- TEAM CHECK
--========================================================--

local function isEnemy(player)
	if not player or player == LocalPlayer then
		return false
	end

	if not Config.TeamCheck then
		return true
	end

	-- Основная Roblox Team система.
	if LocalPlayer.Team and player.Team then
		return player.Team ~= LocalPlayer.Team
	end

	-- Если одна из команд ещё не назначена,
	-- считаем игрока невалидным для Team Check.
	return false
end

--========================================================--
-- ESP
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

local function createESP(player)
	removeESP(player)

	if not Config.ESP then
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
	highlight.Name = "EnemyESP"
	highlight.Adornee = character
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

	highlight.FillColor = Config.ESPColor
	highlight.FillTransparency = 0.78

	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0

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
-- GUI
--========================================================--

local Gui = Instance.new("ScreenGui")
Gui.Name = "PremiumCombatUI"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
Gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
Gui.Parent = PlayerGui

--========================================================--
-- NOTIFICATION
--========================================================--

local Welcome = Instance.new("Frame")
Welcome.Size = UDim2.fromOffset(360, 90)
Welcome.Position = UDim2.new(0.5, -180, 0, -110)
Welcome.BackgroundColor3 = Color3.fromRGB(18, 18, 23)
Welcome.BorderSizePixel = 0
Welcome.ZIndex = 200
Welcome.Parent = Gui

local WelcomeCorner = Instance.new("UICorner")
WelcomeCorner.CornerRadius = UDim.new(0, 14)
WelcomeCorner.Parent = Welcome

local WelcomeStroke = Instance.new("UIStroke")
WelcomeStroke.Color = Color3.fromRGB(85, 85, 100)
WelcomeStroke.Thickness = 1
WelcomeStroke.Parent = Welcome

local WelcomeTitle = Instance.new("TextLabel")
WelcomeTitle.Size = UDim2.new(1, -30, 0, 32)
WelcomeTitle.Position = UDim2.fromOffset(15, 12)
WelcomeTitle.BackgroundTransparency = 1
WelcomeTitle.Text = "WELCOME BACK"
WelcomeTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
WelcomeTitle.Font = Enum.Font.GothamBold
WelcomeTitle.TextSize = 20
WelcomeTitle.TextXAlignment = Enum.TextXAlignment.Left
WelcomeTitle.ZIndex = 201
WelcomeTitle.Parent = Welcome

local WelcomeSub = Instance.new("TextLabel")
WelcomeSub.Size = UDim2.new(1, -30, 0, 25)
WelcomeSub.Position = UDim2.fromOffset(15, 47)
WelcomeSub.BackgroundTransparency = 1
WelcomeSub.Text = "Premium ESP system initialized"
WelcomeSub.TextColor3 = Color3.fromRGB(150, 150, 160)
WelcomeSub.Font = Enum.Font.Gotham
WelcomeSub.TextSize = 12
WelcomeSub.TextXAlignment = Enum.TextXAlignment.Left
WelcomeSub.ZIndex = 201
WelcomeSub.Parent = Welcome

Welcome.Position = UDim2.new(0.5, -180, 0, -110)

local welcomeIn = TweenService:Create(
	Welcome,
	TweenInfo.new(
		0.55,
		Enum.EasingStyle.Quint,
		Enum.EasingDirection.Out
	),
	{
		Position = UDim2.new(0.5, -180, 0, 25)
	}
)

welcomeIn:Play()

task.delay(3, function()
	local welcomeOut = TweenService:Create(
		Welcome,
		TweenInfo.new(
			0.45,
			Enum.EasingStyle.Quint,
			Enum.EasingDirection.In
		),
		{
			Position = UDim2.new(0.5, -180, 0, -110)
		}
	)

	welcomeOut:Play()

	welcomeOut.Completed:Connect(function()
		Welcome:Destroy()
	end)
end)

--========================================================--
-- MAIN WINDOW
--========================================================--

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(345, 345)
Main.Position = UDim2.fromOffset(25, 25)
Main.BackgroundColor3 = Color3.fromRGB(17, 17, 22)
Main.BorderSizePixel = 0
Main.Active = true
Main.ZIndex = 10
Main.Parent = Gui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 16)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(65, 65, 78)
MainStroke.Thickness = 1
MainStroke.Parent = Main

--========================================================--
-- TOP BAR
--========================================================--

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1, 0, 0, 65)
Header.BackgroundTransparency = 1
Header.Parent = Main

local Brand = Instance.new("TextLabel")
Brand.Size = UDim2.new(1, -30, 0, 28)
Brand.Position = UDim2.fromOffset(15, 10)
Brand.BackgroundTransparency = 1
Brand.Text = "NOVA"
Brand.TextColor3 = Color3.fromRGB(255, 255, 255)
Brand.TextSize = 24
Brand.Font = Enum.Font.GothamBlack
Brand.TextXAlignment = Enum.TextXAlignment.Left
Brand.Parent = Header

local Version = Instance.new("TextLabel")
Version.Size = UDim2.new(1, -30, 0, 18)
Version.Position = UDim2.fromOffset(16, 38)
Version.BackgroundTransparency = 1
Version.Text = "COMBAT VISUALS  •  v2.0"
Version.TextColor3 = Color3.fromRGB(125, 125, 140)
Version.TextSize = 10
Version.Font = Enum.Font.GothamMedium
Version.TextXAlignment = Enum.TextXAlignment.Left
Version.Parent = Header

--========================================================--
-- SEPARATOR
--========================================================--

local Separator = Instance.new("Frame")
Separator.Size = UDim2.new(1, -30, 0, 1)
Separator.Position = UDim2.fromOffset(15, 65)
Separator.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
Separator.BorderSizePixel = 0
Separator.Parent = Main

--========================================================--
-- STATUS
--========================================================--

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -30, 0, 22)
Status.Position = UDim2.fromOffset(15, 76)
Status.BackgroundTransparency = 1
Status.Text = "SYSTEM READY"
Status.TextColor3 = Color3.fromRGB(100, 255, 130)
Status.TextSize = 10
Status.Font = Enum.Font.GothamBold
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Main

--========================================================--
-- TOGGLE CREATOR
--========================================================--

local function createToggle(y, title, description)
	local Holder = Instance.new("Frame")
	Holder.Size = UDim2.new(1, -30, 0, 61)
	Holder.Position = UDim2.fromOffset(15, y)
	Holder.BackgroundColor3 = Color3.fromRGB(23, 23, 29)
	Holder.BorderSizePixel = 0
	Holder.Parent = Main

	local Corner = Instance.new("UICorner")
	Corner.CornerRadius = UDim.new(0, 10)
	Corner.Parent = Holder

	local Stroke = Instance.new("UIStroke")
	Stroke.Color = Color3.fromRGB(42, 42, 52)
	Stroke.Parent = Holder

	local Title = Instance.new("TextLabel")
	Title.Size = UDim2.new(1, -75, 0, 24)
	Title.Position = UDim2.fromOffset(13, 7)
	Title.BackgroundTransparency = 1
	Title.Text = title
	Title.TextColor3 = Color3.fromRGB(240, 240, 245)
	Title.TextSize = 14
	Title.Font = Enum.Font.GothamBold
	Title.TextXAlignment = Enum.TextXAlignment.Left
	Title.Parent = Holder

	local Description = Instance.new("TextLabel")
	Description.Size = UDim2.new(1, -75, 0, 20)
	Description.Position = UDim2.fromOffset(13, 31)
	Description.BackgroundTransparency = 1
	Description.Text = description
	Description.TextColor3 = Color3.fromRGB(120, 120, 135)
	Description.TextSize = 10
	Description.Font = Enum.Font.Gotham
	Description.TextXAlignment = Enum.TextXAlignment.Left
	Description.Parent = Holder

	local Toggle = Instance.new("TextButton")
	Toggle.Size = UDim2.fromOffset(48, 25)
	Toggle.Position = UDim2.new(1, -61, 0.5, -12)
	Toggle.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	Toggle.BorderSizePixel = 0
	Toggle.Text = ""
	Toggle.AutoButtonColor = false
	Toggle.Parent = Holder

	local ToggleCorner = Instance.new("UICorner")
	ToggleCorner.CornerRadius = UDim.new(1, 0)
	ToggleCorner.Parent = Toggle

	local Knob = Instance.new("Frame")
	Knob.Size = UDim2.fromOffset(19, 19)
	Knob.Position = UDim2.fromOffset(3, 3)
	Knob.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
	Knob.BorderSizePixel = 0
	Knob.Parent = Toggle

	local KnobCorner = Instance.new("UICorner")
	KnobCorner.CornerRadius = UDim.new(1, 0)
	KnobCorner.Parent = Knob

	return Holder, Toggle, Knob
end

local ESPHolder, ESPToggle, ESPKnob =
	createToggle(
		108,
		"Player ESP",
		"Highlight enemy players through the map"
	)

local TeamHolder, TeamToggle, TeamKnob =
	createToggle(
		177,
		"Team Check",
		"Display and target only the opposite team"
	)

local AimHolder, AimToggle, AimKnob =
	createToggle(
		246,
		"Aim Lock",
		"Hold Left Alt to lock inside the FOV"
	)

local function updateToggle(toggle, knob, enabled)
	local targetToggle
	local targetKnob

	if enabled then
		targetToggle = Color3.fromRGB(45, 120, 65)
		targetKnob = UDim2.fromOffset(26, 3)
	else
		targetToggle = Color3.fromRGB(55, 55, 65)
		targetKnob = UDim2.fromOffset(3, 3)
	end

	TweenService:Create(
		toggle,
		TweenInfo.new(0.15),
		{
			BackgroundColor3 = targetToggle
		}
	):Play()

	TweenService:Create(
		knob,
		TweenInfo.new(0.15),
		{
			Position = targetKnob
		}
	):Play()
end

local function updateUI()
	updateToggle(
		ESPToggle,
		ESPKnob,
		Config.ESP
	)

	updateToggle(
		TeamToggle,
		TeamKnob,
		Config.TeamCheck
	)

	updateToggle(
		AimToggle,
		AimKnob,
		Config.Aim
	)

	if Config.Aim then
		Status.Text = "AIM SYSTEM READY"
		Status.TextColor3 =
			Color3.fromRGB(100, 255, 130)
	else
		Status.Text = "SYSTEM READY"
		Status.TextColor3 =
			Color3.fromRGB(100, 255, 130)
	end
end

--========================================================--
-- FOV
--========================================================--

local FOV = Instance.new("Frame")
FOV.Name = "FOV"
FOV.Size = UDim2.fromOffset(
	Config.FOV * 2,
	Config.FOV * 2
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
FOVStroke.Thickness = 1.5
FOVStroke.Transparency = 0.2
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Parent = FOV

--========================================================--
-- AIM TARGET
--========================================================--

local AimParts = {
	"Head",
	"UpperTorso",
	"Torso",
	"HumanoidRootPart",
	"LowerTorso",
	"Chest",
	"Body",
	"Root",
	"Pelvis",
}

local function getAimPart(character)
	if not character then
		return nil
	end

	for _, name in ipairs(AimParts) do
		local part = character:FindFirstChild(name, true)

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
	local camera = getCamera()

	if not camera then
		return nil
	end

	local center = Vector2.new(
		camera.ViewportSize.X / 2,
		camera.ViewportSize.Y / 2
	)

	local closestPart = nil
	local closestDistance = Config.FOV

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer
			and isEnemy(player) then

			local character = player.Character

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
		end
	end

	return closestPart
end

--========================================================--
-- AIM
--========================================================--

local AimHolding = false
local CurrentTarget = nil

local function aimAt(part)
	if not part or not part.Parent then
		return
	end

	local camera = getCamera()

	if not camera then
		return
	end

	local origin = camera.CFrame.Position
	local difference = part.Position - origin

	if difference.Magnitude < 0.001 then
		return
	end

	-- Быстрое наведение.
	camera.CFrame = CFrame.lookAt(
		origin,
		part.Position
	)
end

--========================================================--
-- TOGGLE EVENTS
--========================================================--

ESPToggle.MouseButton1Click:Connect(function()
	Config.ESP = not Config.ESP

	refreshESP()
	updateUI()
end)

TeamToggle.MouseButton1Click:Connect(function()
	Config.TeamCheck = not Config.TeamCheck

	-- Team Check влияет и на ESP,
	-- и на выбор Aim Lock.
	refreshESP()

	CurrentTarget = nil
	updateUI()
end)

AimToggle.MouseButton1Click:Connect(function()
	Config.Aim = not Config.Aim

	if not Config.Aim then
		AimHolding = false
		CurrentTarget = nil
	end

	FOV.Visible = Config.Aim
	updateUI()
end)

--========================================================--
-- INPUT
--========================================================--

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end

	if input.KeyCode == Config.AimKey then
		if Config.Aim then
			AimHolding = true
			CurrentTarget = nil
		end

		return
	end

	if input.KeyCode == Config.MenuKey then
		Main.Visible = not Main.Visible
		return
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.KeyCode == Config.AimKey then
		AimHolding = false
		CurrentTarget = nil
	end
end)

--========================================================--
-- PLAYER EVENTS
--========================================================--

local function setupPlayer(player)
	if player == LocalPlayer then
		return
	end

	player.CharacterAdded:Connect(function()
		task.wait(0.25)
		createESP(player)
	end)

	player.CharacterRemoving:Connect(function()
		removeESP(player)

		if CurrentTarget
			and CurrentTarget.Parent == nil then

			CurrentTarget = nil
		end
	end)

	player:GetPropertyChangedSignal(
		"Team"
	):Connect(function()

		if Config.TeamCheck then
			createESP(player)

			if CurrentTarget
				and CurrentTarget.Parent
				and CurrentTarget.Parent == player.Character then

				CurrentTarget = nil
			end
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

	if CurrentTarget
		and CurrentTarget.Parent == player.Character then

		CurrentTarget = nil
	end
end)

LocalPlayer:GetPropertyChangedSignal(
	"Team"
):Connect(function()

	if Config.TeamCheck then
		refreshESP()
		CurrentTarget = nil
	end
end)

--========================================================--
-- MAIN RENDER
--========================================================--

local lastTargetUpdate = 0
local TargetUpdateInterval = 1 / 30

RunService:BindToRenderStep(
	"PremiumAimSystem",
	Enum.RenderPriority.Camera.Value + 1,
	function(dt)

		local camera = getCamera()

		if not camera then
			return
		end

		-- FOV follows screen center.
		FOV.Position = UDim2.fromOffset(
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		)

		if not Config.Aim
			or not AimHolding then

			return
		end

		lastTargetUpdate += dt

		if lastTargetUpdate >= TargetUpdateInterval
			or not CurrentTarget
			or not CurrentTarget.Parent then

			lastTargetUpdate = 0
			CurrentTarget =
				findClosestEnemy()
		end

		if CurrentTarget then
			aimAt(CurrentTarget)
		end
	end
)

--========================================================--
-- START
--========================================================--

updateUI()

FOV.Visible = false
Main.Visible = true
