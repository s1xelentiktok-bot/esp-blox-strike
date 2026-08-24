--==================================================
-- ESP + TEAM CHECK + FOV LOCK-ON
-- LocalScript
-- StarterPlayer > StarterPlayerScripts
--==================================================

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
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

local FOV_RADIUS = 300
local AIM_SMOOTHNESS = 0.18

local ESP_COLOR = Color3.fromRGB(255, 60, 60)

--==================================================
-- CONTAINER
--==================================================

local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESP_Objects"
ESPFolder.Parent = workspace

local ESPObjects = {}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "ESP_Menu"
Gui.ResetOnSpawn = false
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Size = UDim2.fromOffset(280, 245)
Main.Position = UDim2.fromOffset(20, 20)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Main

local Stroke = Instance.new("UIStroke")
Stroke.Color = Color3.fromRGB(65, 65, 75)
Stroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 38)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 23
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local function createButton(y)
    local Button = Instance.new("TextButton")

    Button.Size = UDim2.new(1, -20, 0, 38)
    Button.Position = UDim2.fromOffset(10, y)

    Button.BackgroundColor3 = Color3.fromRGB(75, 30, 30)
    Button.BorderSizePixel = 0

    Button.TextColor3 = Color3.fromRGB(255, 90, 90)
    Button.TextSize = 16
    Button.Font = Enum.Font.GothamBold

    Button.Parent = Main

    local C = Instance.new("UICorner")
    C.CornerRadius = UDim.new(0, 7)
    C.Parent = Button

    return Button
end

local ESPButton = createButton(45)
local TeamButton = createButton(87)
local AimButton = createButton(129)

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1, -20, 0, 25)
Hint.Position = UDim2.fromOffset(10, 178)
Hint.BackgroundTransparency = 1
Hint.Text = "ALT — lock-on"
Hint.TextColor3 = Color3.fromRGB(150, 150, 155)
Hint.TextSize = 12
Hint.Font = Enum.Font.Gotham
Hint.TextXAlignment = Enum.TextXAlignment.Left
Hint.Parent = Main

--==================================================
-- BUTTON STATE
--==================================================

local function updateButtons()

    ESPButton.Text =
        ESP_ENABLED and "ESP: ON" or "ESP: OFF"

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
-- TEAM CHECK
--==================================================

local function isEnemy(Player)

    if Player == LocalPlayer then
        return false
    end

    if not TEAM_CHECK_ENABLED then
        return true
    end

    if not LocalPlayer.Team or not Player.Team then
        return true
    end

    return Player.Team ~= LocalPlayer.Team
end

--==================================================
-- ESP REMOVE
--==================================================

local function removeESP(Player)

    local Object = ESPObjects[Player]

    if not Object then
        return
    end

    if Object.Highlight then
        Object.Highlight:Destroy()
    end

    ESPObjects[Player] = nil
end

--==================================================
-- ESP CREATE
--==================================================

local function createESP(Player)

    removeESP(Player)

    if not ESP_ENABLED then
        return
    end

    if not isEnemy(Player) then
        return
    end

    local Character = Player.Character

    if not Character then
        return
    end

    local Highlight = Instance.new("Highlight")

    Highlight.Name = "ESP"
    Highlight.Adornee = Character

    Highlight.DepthMode =
        Enum.HighlightDepthMode.AlwaysOnTop

    Highlight.FillColor = ESP_COLOR
    Highlight.FillTransparency = 0.78

    Highlight.OutlineColor =
        Color3.fromRGB(255, 255, 255)

    Highlight.OutlineTransparency = 0

    Highlight.Parent = ESPFolder

    ESPObjects[Player] = {
        Highlight = Highlight
    }
end

local function refreshESP()

    for _, Player in ipairs(Players:GetPlayers()) do

        if Player ~= LocalPlayer then
            createESP(Player)
        end
    end
end

--==================================================
-- FOV CIRCLE
--==================================================

local FOV = Instance.new("Frame")
FOV.Name = "AimbotFOV"

FOV.Size = UDim2.fromOffset(
    FOV_RADIUS * 2,
    FOV_RADIUS * 2
)

FOV.AnchorPoint = Vector2.new(0.5, 0.5)

FOV.BackgroundTransparency = 1

FOV.Visible = false

FOV.Parent = Gui

local FOVCorner = Instance.new("UICorner")
FOVCorner.CornerRadius = UDim.new(1, 0)
FOVCorner.Parent = FOV

local FOVStroke = Instance.new("UIStroke")
FOVStroke.Thickness = 2
FOVStroke.Color = Color3.fromRGB(255, 255, 255)
FOVStroke.Transparency = 0.2
FOVStroke.Parent = FOV

--==================================================
-- AIM STATE
--==================================================

local HoldingAim = false
local CurrentTarget = nil

local function updateFOV()

    local Viewport = Camera.ViewportSize

    FOV.Position = UDim2.fromOffset(
        Viewport.X / 2,
        Viewport.Y / 2
    )
end

local function getTarget()

    local Center = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    local ClosestPlayer = nil
    local ClosestDistance = FOV_RADIUS

    for _, Player in ipairs(Players:GetPlayers()) do

        if Player ~= LocalPlayer
            and isEnemy(Player) then

            local Character = Player.Character

            if Character then

                local Humanoid =
                    Character:FindFirstChildOfClass("Humanoid")

                local Head =
                    Character:FindFirstChild("Head")

                if Humanoid
                    and Humanoid.Health > 0
                    and Head then

                    local Position, Visible =
                        Camera:WorldToViewportPoint(
                            Head.Position
                        )

                    if Visible then

                        local ScreenPosition =
                            Vector2.new(
                                Position.X,
                                Position.Y
                            )

                        local Distance =
                            (ScreenPosition - Center).Magnitude

                        if Distance < ClosestDistance then
                            ClosestDistance = Distance
                            ClosestPlayer = Player
                        end
                    end
                end
            end
        end
    end

    return ClosestPlayer
end

--==================================================
-- INPUT
--==================================================

UserInputService.InputBegan:Connect(function(Input, Processed)

    if Processed then
        return
    end

    if Input.KeyCode == AIM_KEY then
        HoldingAim = true
    end
end)

UserInputService.InputEnded:Connect(function(Input)

    if Input.KeyCode == AIM_KEY then
        HoldingAim = false
        CurrentTarget = nil
    end
end)

--==================================================
-- BUTTONS
--==================================================

ESPButton.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    updateButtons()
    refreshESP()
end)

TeamButton.MouseButton1Click:Connect(function()

    TEAM_CHECK_ENABLED =
        not TEAM_CHECK_ENABLED

    updateButtons()

    -- Пересоздаём ESP полностью.
    refreshESP()

    -- Если текущая цель стала союзником,
    -- сразу сбрасываем её.
    if CurrentTarget
        and not isEnemy(CurrentTarget) then

        CurrentTarget = nil
    end
end)

AimButton.MouseButton1Click:Connect(function()

    AIM_ENABLED = not AIM_ENABLED

    FOV.Visible = AIM_ENABLED

    if not AIM_ENABLED then
        HoldingAim = false
        CurrentTarget = nil
    end

    updateButtons()
end)

--==================================================
-- PLAYER EVENTS
--==================================================

local function setupPlayer(Player)

    if Player == LocalPlayer then
        return
    end

    Player.CharacterAdded:Connect(function()

        task.wait(0.5)

        createESP(Player)
    end)

    Player.CharacterRemoving:Connect(function()

        removeESP(Player)

        if CurrentTarget == Player then
            CurrentTarget = nil
        end
    end)

    Player:GetPropertyChangedSignal("Team"):Connect(function()

        if TEAM_CHECK_ENABLED then
            createESP(Player)

            if CurrentTarget == Player
                and not isEnemy(Player) then

                CurrentTarget = nil
            end
        end
    end)
end

for _, Player in ipairs(Players:GetPlayers()) do
    setupPlayer(Player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(Player)

    removeESP(Player)

    if CurrentTarget == Player then
        CurrentTarget = nil
    end
end)

--==================================================
-- LOCAL TEAM CHANGE
--==================================================

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()

    if TEAM_CHECK_ENABLED then
        refreshESP()
    end

    if CurrentTarget
        and not isEnemy(CurrentTarget) then

        CurrentTarget = nil
    end
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

    updateFOV()

    if not AIM_ENABLED then
        return
    end

    if not HoldingAim then
        return
    end

    if not CurrentTarget
        or not isEnemy(CurrentTarget) then

        CurrentTarget = getTarget()
    end

    if not CurrentTarget then
        return
    end

    local Character =
        CurrentTarget.Character

    if not Character then
        CurrentTarget = nil
        return
    end

    local Head =
        Character:FindFirstChild("Head")

    local Humanoid =
        Character:FindFirstChildOfClass("Humanoid")

    if not Head
        or not Humanoid
        or Humanoid.Health <= 0 then

        CurrentTarget = nil
        return
    end

    -- Lock-on внутри твоей игры.
    local TargetPosition =
        Camera:WorldToViewportPoint(
            Head.Position
        )

    local Center =
        Vector2.new(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )

    local Target =
        Vector2.new(
            TargetPosition.X,
            TargetPosition.Y
        )

    if (Target - Center).Magnitude > FOV_RADIUS then
        CurrentTarget = nil
        return
    end

    local CameraPosition =
        Camera.CFrame.Position

    local Direction =
        (Head.Position - CameraPosition).Unit

    local TargetCFrame =
        CFrame.lookAt(
            CameraPosition,
            CameraPosition + Direction
        )

    Camera.CFrame =
        Camera.CFrame:Lerp(
            TargetCFrame,
            AIM_SMOOTHNESS
        )
end)

--==================================================
-- START
--==================================================

updateButtons()
updateFOV()
