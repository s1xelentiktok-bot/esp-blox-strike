-- esp.lua
-- Для собственной Roblox-игры

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local ESP_ENABLED = false
local SKELETON_ENABLED = false
local TEAM_CHECK_ENABLED = false
local GUI_VISIBLE = true

local ESP_FOLDER = Instance.new("Folder")
ESP_FOLDER.Name = "ESP_Objects"
ESP_FOLDER.Parent = workspace

local objects = {}

--==================================================
-- GUI
--==================================================

local gui = Instance.new("ScreenGui")
gui.Name = "ESP_GUI"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(260, 205)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
frame.BorderSizePixel = 0
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = frame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "ESP"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

local function createButton(text, y)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(1, -20, 0, 35)
    button.Position = UDim2.fromOffset(10, y)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Parent = frame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = button

    return button
end

local espButton = createButton("ESP: OFF", 43)
local skeletonButton = createButton("SKELETON: OFF", 83)
local teamButton = createButton("TEAM CHECK: OFF", 123)

local hint = Instance.new("TextLabel")
hint.Size = UDim2.new(1, -20, 0, 25)
hint.Position = UDim2.fromOffset(10, 166)
hint.BackgroundTransparency = 1
hint.Text = "ALT — скрыть / показать"
hint.TextColor3 = Color3.fromRGB(150, 150, 155)
hint.TextSize = 12
hint.Font = Enum.Font.Gotham
hint.TextXAlignment = Enum.TextXAlignment.Left
hint.Parent = frame

local function updateButtons()
    espButton.Text = ESP_ENABLED and "ESP: ON" or "ESP: OFF"
    espButton.TextColor3 = ESP_ENABLED
        and Color3.fromRGB(80, 255, 100)
        or Color3.fromRGB(255, 90, 90)

    skeletonButton.Text = SKELETON_ENABLED
        and "SKELETON: ON"
        or "SKELETON: OFF"

    skeletonButton.TextColor3 = SKELETON_ENABLED
        and Color3.fromRGB(80, 255, 100)
        or Color3.fromRGB(255, 90, 90)

    teamButton.Text = TEAM_CHECK_ENABLED
        and "TEAM CHECK: ON"
        or "TEAM CHECK: OFF"

    teamButton.TextColor3 = TEAM_CHECK_ENABLED
        and Color3.fromRGB(80, 255, 100)
        or Color3.fromRGB(255, 90, 90)

    espButton.BackgroundColor3 = ESP_ENABLED
        and Color3.fromRGB(30, 75, 40)
        or Color3.fromRGB(75, 30, 30)

    skeletonButton.BackgroundColor3 = SKELETON_ENABLED
        and Color3.fromRGB(30, 75, 40)
        or Color3.fromRGB(75, 30, 30)

    teamButton.BackgroundColor3 = TEAM_CHECK_ENABLED
        and Color3.fromRGB(30, 75, 40)
        or Color3.fromRGB(75, 30, 30)
end

--==================================================
-- TEAM CHECK
--==================================================

local function isEnemy(player)
    if not TEAM_CHECK_ENABLED then
        return true
    end

    if not LocalPlayer.Team or not player.Team then
        return true
    end

    return player.Team ~= LocalPlayer.Team
end

--==================================================
-- REMOVE
--==================================================

local function removeESP(player)
    local data = objects[player]

    if not data then
        return
    end

    if data.highlight then
        data.highlight:Destroy()
    end

    if data.skeleton then
        data.skeleton:Destroy()
    end

    objects[player] = nil
end

--==================================================
-- SKELETON
--==================================================

local function findPart(character, ...)
    for _, name in ipairs({...}) do
        local obj = character:FindFirstChild(name, true)

        if obj and obj:IsA("BasePart") then
            return obj
        end
    end

    return nil
end

local function createBone(folder, part0, part1)
    if not part0 or not part1 then
        return
    end

    local attachment0 = Instance.new("Attachment")
    attachment0.Parent = part0

    local attachment1 = Instance.new("Attachment")
    attachment1.Parent = part1

    local beam = Instance.new("Beam")
    beam.Attachment0 = attachment0
    beam.Attachment1 = attachment1
    beam.Width0 = 0.045
    beam.Width1 = 0.045
    beam.FaceCamera = true
    beam.LightEmission = 1
    beam.Color = ColorSequence.new(
        Color3.fromRGB(255, 255, 255)
    )
    beam.Parent = folder
end

local function createSkeleton(player, character)
    local folder = Instance.new("Folder")
    folder.Name = "Skeleton"
    folder.Parent = ESP_FOLDER

    local head = findPart(character, "Head")

    local upperTorso = findPart(
        character,
        "UpperTorso",
        "Torso",
        "Chest",
        "Body"
    )

    local lowerTorso = findPart(
        character,
        "LowerTorso",
        "Pelvis",
        "Waist"
    )

    local leftUpperArm = findPart(
        character,
        "LeftUpperArm",
        "Left Arm"
    )

    local leftLowerArm = findPart(
        character,
        "LeftLowerArm"
    )

    local leftHand = findPart(
        character,
        "LeftHand"
    )

    local rightUpperArm = findPart(
        character,
        "RightUpperArm",
        "Right Arm"
    )

    local rightLowerArm = findPart(
        character,
        "RightLowerArm"
    )

    local rightHand = findPart(
        character,
        "RightHand"
    )

    local leftUpperLeg = findPart(
        character,
        "LeftUpperLeg",
        "Left Leg"
    )

    local leftLowerLeg = findPart(
        character,
        "LeftLowerLeg"
    )

    local leftFoot = findPart(
        character,
        "LeftFoot"
    )

    local rightUpperLeg = findPart(
        character,
        "RightUpperLeg",
        "Right Leg"
    )

    local rightLowerLeg = findPart(
        character,
        "RightLowerLeg"
    )

    local rightFoot = findPart(
        character,
        "RightFoot"
    )

    createBone(folder, head, upperTorso)
    createBone(folder, upperTorso, lowerTorso)

    createBone(folder, upperTorso, leftUpperArm)
    createBone(folder, leftUpperArm, leftLowerArm)
    createBone(folder, leftLowerArm, leftHand)

    createBone(folder, upperTorso, rightUpperArm)
    createBone(folder, rightUpperArm, rightLowerArm)
    createBone(folder, rightLowerArm, rightHand)

    createBone(folder, lowerTorso, leftUpperLeg)
    createBone(folder, leftUpperLeg, leftLowerLeg)
    createBone(folder, leftLowerLeg, leftFoot)

    createBone(folder, lowerTorso, rightUpperLeg)
    createBone(folder, rightUpperLeg, rightLowerLeg)
    createBone(folder, rightLowerLeg, rightFoot)

    return folder
end

--==================================================
-- CREATE ESP
--==================================================

local function createESP(player)
    if player == LocalPlayer then
        return
    end

    removeESP(player)

    if not ESP_ENABLED and not SKELETON_ENABLED then
        return
    end

    if not isEnemy(player) then
        return
    end

    local character = player.Character

    if not character or not character:IsA("Model") then
        return
    end

    local data = {}

    if ESP_ENABLED then
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESP_Highlight"
        highlight.Adornee = character
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

        highlight.FillColor = Color3.fromRGB(255, 0, 0)
        highlight.FillTransparency = 0.78

        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0

        highlight.Parent = ESP_FOLDER

        data.highlight = highlight
    end

    if SKELETON_ENABLED then
        data.skeleton = createSkeleton(player, character)
    end

    objects[player] = data
end

--==================================================
-- UPDATE
--==================================================

local function refresh()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            createESP(player)
        end
    end
end

--==================================================
-- BUTTONS
--==================================================

espButton.MouseButton1Click:Connect(function()
    ESP_ENABLED = not ESP_ENABLED
    updateButtons()
    refresh()
end)

skeletonButton.MouseButton1Click:Connect(function()
    SKELETON_ENABLED = not SKELETON_ENABLED
    updateButtons()
    refresh()
end)

teamButton.MouseButton1Click:Connect(function()
    TEAM_CHECK_ENABLED = not TEAM_CHECK_ENABLED
    updateButtons()
    refresh()
end)

--==================================================
-- ALT
--==================================================

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftAlt
        or input.KeyCode == Enum.KeyCode.RightAlt then

        GUI_VISIBLE = not GUI_VISIBLE
        frame.Visible = GUI_VISIBLE
    end
end)

--==================================================
-- PLAYERS
--==================================================

local function setupPlayer(player)
    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if ESP_ENABLED or SKELETON_ENABLED then
            createESP(player)
        end
    end)

    player.CharacterRemoving:Connect(function()
        removeESP(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    removeESP(player)
end)

-- Обновляем ESP при смене команды
LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()
    if TEAM_CHECK_ENABLED then
        refresh()
    end
end)

--==================================================
-- START
--==================================================

updateButtons()