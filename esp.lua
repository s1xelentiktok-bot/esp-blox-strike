-- LocalScript
-- StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESP_ENABLED = false
local TEAM_CHECK = false
local AIM_ENABLED = false
local AIM_HOLDING = false

local FOV_RADIUS = 300
local AIM_SPEED = 0.45

local espFolder = Instance.new("Folder")
espFolder.Name = "ESP"
espFolder.Parent = workspace

local espObjects = {}

--==================================================
-- TEAM DETECTION
--==================================================

local function getTeamValue(player)
    if not player then
        return nil
    end

    -- Обычная Roblox Team
    if player.Team then
        return player.Team
    end

    -- Attribute игрока
    local teamAttribute = player:GetAttribute("Team")
    if teamAttribute ~= nil then
        return teamAttribute
    end

    -- Attribute персонажа
    if player.Character then
        local charTeam = player.Character:GetAttribute("Team")

        if charTeam ~= nil then
            return charTeam
        end
    end

    -- StringValue / ObjectValue
    local value = player:FindFirstChild("Team")

    if value then
        if value:IsA("StringValue") then
            return value.Value
        elseif value:IsA("ObjectValue") then
            return value.Value
        end
    end

    if player.Character then
        local value2 = player.Character:FindFirstChild("Team")

        if value2 then
            if value2:IsA("StringValue") then
                return value2.Value
            elseif value2:IsA("ObjectValue") then
                return value2.Value
            end
        end
    end

    return nil
end

local function isEnemy(player)

    if player == LP then
        return false
    end

    if not TEAM_CHECK then
        return true
    end

    local myTeam = getTeamValue(LP)
    local theirTeam = getTeamValue(player)

    -- Если команда неизвестна, не считаем игрока союзником
    if myTeam == nil or theirTeam == nil then
        return true
    end

    if typeof(myTeam) == "Instance"
        and typeof(theirTeam) == "Instance" then

        return myTeam ~= theirTeam
    end

    return tostring(myTeam) ~= tostring(theirTeam)
end

--==================================================
-- ESP
--==================================================

local function removeESP(player)

    if espObjects[player] then
        espObjects[player]:Destroy()
        espObjects[player] = nil
    end
end

local function addESP(player)

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

    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    highlight.FillColor = Color3.fromRGB(255, 60, 60)
    highlight.FillTransparency = 0.75

    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.OutlineTransparency = 0

    highlight.Parent = espFolder

    espObjects[player] = highlight
end

local function refreshESP()

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP then
            addESP(player)
        end
    end
end

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "ESP_GUI"
gui.ResetOnSpawn = false
gui.Parent = LP:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 190)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundColor3 = Color3.fromRGB(25,25,28)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-20,0,35)
title.Position = UDim2.fromOffset(10,5)
title.BackgroundTransparency = 1
title.Text = "ESP / AIM"
title.TextColor3 = Color3.new(1,1,1)
title.TextSize = 21
title.Font = Enum.Font.GothamBold
title.Parent = frame

local function button(text, y)

    local b = Instance.new("TextButton")

    b.Size = UDim2.new(1,-20,0,35)
    b.Position = UDim2.fromOffset(10,y)

    b.BackgroundColor3 = Color3.fromRGB(80,30,30)
    b.TextColor3 = Color3.fromRGB(255,90,90)

    b.Text = text
    b.TextSize = 15
    b.Font = Enum.Font.GothamBold

    b.BorderSizePixel = 0
    b.Parent = frame

    Instance.new("UICorner", b).CornerRadius = UDim.new(0,7)

    return b
end

local espButton = button("ESP: OFF",45)
local teamButton = button("TEAM CHECK: OFF",85)
local aimButton = button("AIM LOCK: OFF",125)

local function updateButtons()

    espButton.Text = ESP_ENABLED and "ESP: ON" or "ESP: OFF"
    teamButton.Text = TEAM_CHECK and "TEAM CHECK: ON" or "TEAM CHECK: OFF"
    aimButton.Text = AIM_ENABLED and "AIM LOCK: ON" or "AIM LOCK: OFF"

end

--==================================================
-- FOV
--==================================================

local fov = Instance.new("Frame")

fov.Size = UDim2.fromOffset(
    FOV_RADIUS * 2,
    FOV_RADIUS * 2
)

fov.AnchorPoint = Vector2.new(.5,.5)
fov.BackgroundTransparency = 1
fov.Visible = false
fov.Parent = gui

local fc = Instance.new("UICorner")
fc.CornerRadius = UDim.new(1,0)
fc.Parent = fov

local fs = Instance.new("UIStroke")
fs.Thickness = 2
fs.Color = Color3.new(1,1,1)
fs.Transparency = .2
fs.Parent = fov

--==================================================
-- AIM TARGET
--==================================================

local function getAimPart(character)

    if not character then
        return nil
    end

    -- Приоритет: Head
    local head = character:FindFirstChild("Head")

    if head and head:IsA("BasePart") then
        return head
    end

    -- Для кастомных моделей
    local upper = character:FindFirstChild("UpperTorso")

    if upper and upper:IsA("BasePart") then
        return upper
    end

    local torso = character:FindFirstChild("Torso")

    if torso and torso:IsA("BasePart") then
        return torso
    end

    -- Последняя попытка
    return character:FindFirstChildWhichIsA("BasePart")
end

local function getClosestTarget()

    local center = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    local closest = nil
    local closestDistance = FOV_RADIUS

    for _, player in ipairs(Players:GetPlayers()) do

        if player ~= LP and isEnemy(player) then

            local character = player.Character
            local humanoid =
                character and character:FindFirstChildOfClass("Humanoid")

            local part = getAimPart(character)

            if character
                and humanoid
                and humanoid.Health > 0
                and part then

                local screen, visible =
                    Camera:WorldToViewportPoint(part.Position)

                if visible and screen.Z > 0 then

                    local position = Vector2.new(
                        screen.X,
                        screen.Y
                    )

                    local distance =
                        (position - center).Magnitude

                    if distance <= closestDistance then

                        -- Проверяем прямую видимость
                        local origin = Camera.CFrame.Position
                        local direction = part.Position - origin

                        local params = RaycastParams.new()
                        params.FilterType =
                            Enum.RaycastFilterType.Exclude

                        params.FilterDescendantsInstances = {
                            LP.Character
                        }

                        local result =
                            workspace:Raycast(
                                origin,
                                direction,
                                params
                            )

                        if not result
                            or result.Instance:IsDescendantOf(character) then

                            closestDistance = distance
                            closest = part
                        end
                    end
                end
            end
        end
    end

    return closest
end

--==================================================
-- BUTTONS
--==================================================

espButton.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    refreshESP()
    updateButtons()
end)

teamButton.MouseButton1Click:Connect(function()

    TEAM_CHECK = not TEAM_CHECK

    refreshESP()
    updateButtons()
end)

aimButton.MouseButton1Click:Connect(function()

    AIM_ENABLED = not AIM_ENABLED

    fov.Visible = AIM_ENABLED

    if not AIM_ENABLED then
        AIM_HOLDING = false
    end

    updateButtons()
end)

--==================================================
-- ALT
--==================================================

UIS.InputBegan:Connect(function(input, processed)

    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftAlt then
        AIM_HOLDING = true
    end
end)

UIS.InputEnded:Connect(function(input)

    if input.KeyCode == Enum.KeyCode.LeftAlt then
        AIM_HOLDING = false
    end
end)

--==================================================
-- PLAYERS
--==================================================

Players.PlayerAdded:Connect(function(player)

    player.CharacterAdded:Connect(function()

        task.wait(.5)
        addESP(player)
    end)

    player:GetPropertyChangedSignal("Team"):Connect(function()

        if TEAM_CHECK then
            refreshESP()
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)

    removeESP(player)
end)

--==================================================
-- MAIN LOOP
--==================================================

RunService.RenderStepped:Connect(function()

    if AIM_ENABLED then

        fov.Position = UDim2.fromOffset(
            Camera.ViewportSize.X / 2,
            Camera.ViewportSize.Y / 2
        )
    end

    if not AIM_ENABLED or not AIM_HOLDING then
        return
    end

    local target = getClosestTarget()

    if not target then
        return
    end

    local cameraPosition = Camera.CFrame.Position
    local direction =
        (target.Position - cameraPosition).Unit

    local wanted =
        CFrame.lookAt(
            cameraPosition,
            cameraPosition + direction
        )

    Camera.CFrame =
        Camera.CFrame:Lerp(
            wanted,
            AIM_SPEED
        )
end)

--==================================================
-- START
--==================================================

updateButtons()