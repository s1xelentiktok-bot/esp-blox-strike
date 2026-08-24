--========================================================--
--              ESP + TEAM CHECK + AIM LOCK               --
--                    LOCAL SCRIPT                        --
--========================================================--
-- Place in:
-- StarterPlayer > StarterPlayerScripts
--
-- Left Alt  = hold AIM
-- Right Alt = show / hide menu
--
-- AIM does not use raycast, so walls do not block targeting.
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

local AIM_KEY = Enum.KeyCode.LeftAlt
local MENU_KEY = Enum.KeyCode.RightAlt

local FOV_RADIUS = 300

-- 1 = almost instant
-- 0.5 = very fast
-- 0.2 = smooth
local AIM_SMOOTHNESS = 0.95

local ESP_COLOR = Color3.fromRGB(
	255,
	60,
	60
)

--========================================================--
-- CAMERA
--========================================================--

local Camera = workspace.CurrentCamera

local function getCamera()

	Camera = workspace.CurrentCamera

	return Camera
end

--========================================================--
-- ESP FOLDER
--========================================================--

local ESPFolder = Instance.new("Folder")

ESPFolder.Name =
	"ESP_Objects"

ESPFolder.Parent =
	workspace

local ESPObjects = {}

--========================================================--
-- TEAM CHECK
--========================================================--

local function isEnemy(Player)

	if Player == LocalPlayer then
		return false
	end

	if not TEAM_CHECK_ENABLED then
		return true
	end

	if not LocalPlayer.Team
		or not Player.Team then

		return true
	end

	return Player.Team ~= LocalPlayer.Team
end

--========================================================--
-- REMOVE ESP
--========================================================--

local function removeESP(Player)

	local Object =
		ESPObjects[Player]

	if not Object then
		return
	end

	if Object.Highlight then
		Object.Highlight:Destroy()
	end

	ESPObjects[Player] = nil
end

--========================================================--
-- CREATE ESP
--========================================================--

local function createESP(Player)

	removeESP(Player)

	if not ESP_ENABLED then
		return
	end

	if not isEnemy(Player) then
		return
	end

	local Character =
		Player.Character

	if not Character then
		return
	end

	local Highlight =
		Instance.new("Highlight")

	Highlight.Name =
		"ESP"

	Highlight.Adornee =
		Character

	Highlight.DepthMode =
		Enum.HighlightDepthMode.AlwaysOnTop

	Highlight.FillColor =
		ESP_COLOR

	Highlight.FillTransparency =
		0.78

	Highlight.OutlineColor =
		Color3.fromRGB(
			255,
			255,
			255
		)

	Highlight.OutlineTransparency =
		0

	Highlight.Parent =
		ESPFolder

	ESPObjects[Player] = {
		Highlight = Highlight
	}
end

--========================================================--
-- REFRESH ESP
--========================================================--

local function refreshESP()

	for _, Player in ipairs(
		Players:GetPlayers()
	) do

		if Player ~= LocalPlayer then
			createESP(Player)
		end
	end
end

--========================================================--
-- GUI
--========================================================--

local Gui =
	Instance.new("ScreenGui")

Gui.Name =
	"ESP_Menu"

Gui.ResetOnSpawn =
	false

Gui.IgnoreGuiInset =
	true

Gui.ZIndexBehavior =
	Enum.ZIndexBehavior.Sibling

Gui.Parent =
	LocalPlayer:WaitForChild(
		"PlayerGui"
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
		300,
		245
	)

Main.Position =
	UDim2.fromOffset(
		20,
		20
	)

Main.BackgroundColor3 =
	Color3.fromRGB(
		24,
		24,
		28
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
		10
	)

MainCorner.Parent =
	Main

local MainStroke =
	Instance.new("UIStroke")

MainStroke.Color =
	Color3.fromRGB(
		65,
		65,
		75
	)

MainStroke.Thickness =
	1

MainStroke.Parent =
	Main

--========================================================--
-- TITLE
--========================================================--

local Title =
	Instance.new("TextLabel")

Title.Size =
	UDim2.new(
		1,
		-20,
		0,
		38
	)

Title.Position =
	UDim2.fromOffset(
		10,
		5
	)

Title.BackgroundTransparency =
	1

Title.Text =
	"ESP / AIM"

Title.TextColor3 =
	Color3.new(
		1,
		1,
		1
	)

Title.TextSize =
	23

Title.Font =
	Enum.Font.GothamBold

Title.TextXAlignment =
	Enum.TextXAlignment.Left

Title.ZIndex =
	11

Title.Parent =
	Main

--========================================================--
-- BUTTON
--========================================================--

local function createButton(
	Name,
	Y
)

	local Button =
		Instance.new("TextButton")

	Button.Name =
		Name

	Button.Size =
		UDim2.new(
			1,
			-20,
			0,
			38
		)

	Button.Position =
		UDim2.fromOffset(
			10,
			Y
		)

	Button.BackgroundColor3 =
		Color3.fromRGB(
			80,
			30,
			30
		)

	Button.BorderSizePixel =
		0

	Button.TextColor3 =
		Color3.fromRGB(
			255,
			90,
			90
		)

	Button.TextSize =
		15

	Button.Font =
		Enum.Font.GothamBold

	Button.Active =
		true

	Button.Selectable =
		true

	Button.AutoButtonColor =
		true

	Button.ZIndex =
		20

	Button.Parent =
		Main

	local Corner =
		Instance.new("UICorner")

	Corner.CornerRadius =
		UDim.new(
			0,
			7
		)

	Corner.Parent =
		Button

	return Button
end

local ESPButton =
	createButton(
		"ESPButton",
		48
	)

local TeamButton =
	createButton(
		"TeamButton",
		91
	)

local AimButton =
	createButton(
		"AimButton",
		134
	)

--========================================================--
-- INFO
--========================================================--

local Info =
	Instance.new("TextLabel")

Info.Size =
	UDim2.new(
		1,
		-20,
		0,
		40
	)

Info.Position =
	UDim2.fromOffset(
		10,
		180
	)

Info.BackgroundTransparency =
	1

Info.Text =
	"Left Alt  -  AIM\nRight Alt -  MENU"

Info.TextColor3 =
	Color3.fromRGB(
		150,
		150,
		155
	)

Info.TextSize =
	11

Info.Font =
	Enum.Font.Gotham

Info.TextXAlignment =
	Enum.TextXAlignment.Left

Info.ZIndex =
	11

Info.Parent =
	Main

--========================================================--
-- BUTTON STATE
--========================================================--

local function updateButton(
	Button,
	Name,
	Enabled
)

	if Enabled then

		Button.Text =
			Name .. ": ON"

		Button.BackgroundColor3 =
			Color3.fromRGB(
				30,
				80,
				40
			)

		Button.TextColor3 =
			Color3.fromRGB(
				90,
				255,
				110
			)

	else

		Button.Text =
			Name .. ": OFF"

		Button.BackgroundColor3 =
			Color3.fromRGB(
				80,
				30,
				30
			)

		Button.TextColor3 =
			Color3.fromRGB(
				255,
				90,
				90
			)
	end
end

local function updateButtons()

	updateButton(
		ESPButton,
		"ESP",
		ESP_ENABLED
	)

	updateButton(
		TeamButton,
		"TEAM CHECK",
		TEAM_CHECK_ENABLED
	)

	updateButton(
		AimButton,
		"AIM LOCK",
		AIM_ENABLED
	)
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
	2

FOVStroke.Color =
	Color3.fromRGB(
		255,
		255,
		255
	)

FOVStroke.Transparency =
	0.2

FOVStroke.Parent =
	FOV

--========================================================--
-- AIM PART SEARCH
--========================================================--

local AimPartNames = {

	"Head",

	"UpperTorso",

	"Torso",

	"HumanoidRootPart",

	"LowerTorso",

	"Chest",

	"Body",

	"Root",

	"Pelvis",

	"Spine"

}

local function findNamedPart(
	Character,
	Name
)

	local Part =
		Character:FindFirstChild(
			Name,
			true
		)

	if Part
		and Part:IsA("BasePart") then

		return Part
	end

	return nil
end

local function getAimPart(
	Character
)

	if not Character then
		return nil
	end

	-- First try known body parts.
	for _, Name in ipairs(
		AimPartNames
	) do

		local Part =
			findNamedPart(
				Character,
				Name
			)

		if Part then
			return Part
		end
	end

	-- Fallback for completely custom rigs.
	for _, Object in ipairs(
		Character:GetDescendants()
	) do

		if Object:IsA("BasePart")
			and Object.Name ~= "Handle" then

			return Object
		end
	end

	return nil
end

--========================================================--
-- ALIVE CHECK
--========================================================--

local function isAlive(Player)

	local Character =
		Player.Character

	if not Character then
		return false
	end

	local Humanoid =
		Character:FindFirstChildOfClass(
			"Humanoid"
		)

	if Humanoid then
		return Humanoid.Health > 0
	end

	return true
end

--========================================================--
-- TARGET SEARCH
--========================================================--

local function findClosestTarget()

	local CameraObject =
		getCamera()

	if not CameraObject then
		return nil
	end

	local Center =
		Vector2.new(
			CameraObject.ViewportSize.X / 2,
			CameraObject.ViewportSize.Y / 2
		)

	local ClosestPart =
		nil

	local ClosestDistance =
		FOV_RADIUS

	for _, Player in ipairs(
		Players:GetPlayers()
	) do

		if Player ~= LocalPlayer
			and isEnemy(Player)
			and isAlive(Player) then

			local Character =
				Player.Character

			local Part =
				getAimPart(
					Character
				)

			if Part then

				-- No raycast here.
				-- Walls therefore do not block
				-- target selection.

				local ScreenPosition =
					CameraObject:WorldToViewportPoint(
						Part.Position
					)

				if ScreenPosition.Z > 0 then

					local Position =
						Vector2.new(
							ScreenPosition.X,
							ScreenPosition.Y
						)

					local Distance =
						(
							Position -
							Center
						).Magnitude

					if Distance <
						ClosestDistance then

						ClosestDistance =
							Distance

						ClosestPart =
							Part
					end
				end
			end
		end
	end

	return ClosestPart
end

--========================================================--
-- AIM
--========================================================--

local function aimAt(
	Part
)

	local CameraObject =
		getCamera()

	if not CameraObject
		or not Part then

		return
	end

	if not Part.Parent then
		return
	end

	local CameraPosition =
		CameraObject.CFrame.Position

	local Direction =
		Part.Position -
		CameraPosition

	if Direction.Magnitude <=
		0.001 then

		return
	end

	local TargetCFrame =
		CFrame.lookAt(
			CameraPosition,
			Part.Position
		)

	CameraObject.CFrame =
		CameraObject.CFrame:Lerp(
			TargetCFrame,
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
-- KEYBOARD
--========================================================--

UserInputService.InputBegan:Connect(
	function(Input, Processed)

		if Processed then
			return
		end

		-- LEFT ALT
		if Input.KeyCode ==
			AIM_KEY then

			AIM_HOLDING =
				true

			return
		end

		-- RIGHT ALT
		if Input.KeyCode ==
			MENU_KEY then

			Main.Visible =
				not Main.Visible

			return
		end
	end
)

UserInputService.InputEnded:Connect(
	function(Input)

		if Input.KeyCode ==
			AIM_KEY then

			AIM_HOLDING =
				false
		end
	end
)

--========================================================--
-- PLAYER EVENTS
--========================================================--

local function setupPlayer(Player)

	if Player == LocalPlayer then
		return
	end

	Player.CharacterAdded:Connect(
		function()

			task.wait(0.5)

			createESP(Player)
		end
	)

	Player.CharacterRemoving:Connect(
		function()

			removeESP(Player)
		end
	)

	Player:GetPropertyChangedSignal(
		"Team"
	):Connect(
		function()

			if TEAM_CHECK_ENABLED then
				createESP(Player)
			end
		end
	)
end

for _, Player in ipairs(
	Players:GetPlayers()
) do

	setupPlayer(Player)
end

Players.PlayerAdded:Connect(
	setupPlayer
)

Players.PlayerRemoving:Connect(
	function(Player)

		removeESP(Player)
	end
)

--========================================================--
-- LOCAL TEAM CHANGE
--========================================================--

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
-- MAIN LOOP
--========================================================--

RunService.RenderStepped:Connect(
	function()

		local CameraObject =
			getCamera()

		if not CameraObject then
			return
		end

		-- Keep FOV centered.
		local Viewport =
			CameraObject.ViewportSize

		FOV.Position =
			UDim2.fromOffset(
				Viewport.X / 2,
				Viewport.Y / 2
			)

		-- AIM disabled.
		if not AIM_ENABLED then
			return
		end

		-- Left Alt released.
		if not AIM_HOLDING then
			return
		end

		local Target =
			findClosestTarget()

		if not Target then
			return
		end

		aimAt(Target)
	end
)

--========================================================--
-- START
--========================================================--

updateButtons()

FOV.Visible =
	false

Main.Visible =
	true
