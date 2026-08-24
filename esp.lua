-- esp.lua
-- LocalScript -> StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local ESP_ENABLED = false
local SKELETON_ENABLED = false
local TEAM_CHECK_ENABLED = false
local GUI_VISIBLE = true

local ESP_COLOR = Color3.fromRGB(255, 60, 60)
local SKELETON_COLOR = Color3.fromRGB(255, 255, 255)

local Container = Instance.new("Folder")
Container.Name = "ESP_CONTAINER"
Container.Parent = workspace

local Objects = {}

--==================================================
-- GUI
--==================================================

local Gui = Instance.new("ScreenGui")
Gui.Name = "ESP_GUI"
Gui.ResetOnSpawn = false
Gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.fromOffset(270, 220)
Frame.Position = UDim2.fromOffset(20, 20)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 28)
Frame.BorderSizePixel = 0
Frame.Parent = Gui

local Corner = Instance.new("UICorner")
Corner.CornerRadius = UDim.new(0, 10)
Corner.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -20, 0, 35)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "ESP"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 23
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Frame

local function makeButton(name, y)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(1, -20, 0, 36)
    button.Position = UDim2.fromOffset(10, y)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Parent = Frame

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 7)
    c.Parent = button

    return button
end

local ESPButton = makeButton("ESP", 45)
local SkeletonButton = makeButton("Skeleton", 85)
local TeamButton = makeButton("Team", 125)

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1, -20, 0, 25)
Hint.Position = UDim2.fromOffset(10, 170)
Hint.BackgroundTransparency = 1
Hint.Text = "ALT — скрыть / показать"
Hint.TextColor3 = Color3.fromRGB(150, 150, 155)
Hint.TextSize = 12
Hint.Font = Enum.Font.Gotham
Hint.TextXAlignment = Enum.TextXAlignment.Left
Hint.Parent = Frame

local function updateButtons()

    ESPButton.Text = ESP_ENABLED and "ESP: ON" or "ESP: OFF"
    ESPButton.BackgroundColor3 =
        ESP_ENABLED
        and Color3.fromRGB(30, 80, 40)
        or Color3.fromRGB(80, 30, 30)

    ESPButton.TextColor3 =
        ESP_ENABLED
        and Color3.fromRGB(90, 255, 110)
        or Color3.fromRGB(255, 90, 90)

    SkeletonButton.Text =
        SKELETON_ENABLED
        and "SKELETON: ON"
        or "SKELETON: OFF"

    SkeletonButton.BackgroundColor3 =
        SKELETON_ENABLED
        and Color3.fromRGB(30, 80, 40)
        or Color3.fromRGB(80, 30, 30)

    SkeletonButton.TextColor3 =
        SKELETON_ENABLED
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
-- CLEANUP
--==================================================

local function removePlayer(player)

    local data = Objects[player]

    if not data then
        return
    end

    if data.highlight then
        data.highlight:Destroy()
    end

    if data.skeleton then
        data.skeleton:Destroy()
    end

    Objects[player] = nil
end

--==================================================
-- SKELETON
--==================================================

local function createSkeleton(character)

    local folder = Instance.new("Folder")
    folder.Name = "Skeleton"
    folder.Parent = Container

    local attachments = {}

    local function getAttachment(part)

        if attachments[part] then
            return attachments[part]
        end

        local attachment = Instance.new("Attachment")
        attachment.Parent = part

        attachments[part] = attachment

        return attachment
    end

    local function connectParts(part0, part1)

        if not part0 or not part1 then
            return
        end

        local a0 = getAttachment(part0)
        local a1 = getAttachment(part1)

        local beam = Instance.new("Beam")

        beam.Attachment0 = a0
        beam.Attachment1 = a1
        beam.Width0 = 0.04
        beam.Width1 = 0.04
        beam.FaceCamera = true
        beam.LightEmission = 1
        beam.Color = ColorSequence.new(SKELETON_COLOR)

        beam.Parent = folder
    end

    -- R15/R6 и кастомные Motor6D-реги
    for _, object in ipairs(character:GetDescendants()) do

        if object:IsA("Motor6D") then

            if object.Part0 and object.Part1 then
                connectParts(object.Part0, object.Part1)
            end
        end
    end

    -- Кастомные Bone
    for _, object in ipairs(character:GetDescendants()) do

        if object:IsA("Bone") then

            local parent = object.Parent

            if parent and parent:IsA("BasePart") then

                local parentBone =
                    object.Parent:FindFirstChildWhichIsA("Bone")

                if parentBone then
                    connectParts(parent, parentBone)
                end
            end
        end
    end

    return folder
end

--==================================================
-- CREATE ESP
--==================================================

local function createPlayer(player)

    if player == LocalPlayer then
        return
    end

    removePlayer(player)

    -- TEAM CHECK ДО СОЗДАНИЯ ОБЪЕКТОВ
    if not isEnemy(player) then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    local data = {}

    if ESP_ENABLED then

        local highlight = Instance.new("Highlight")

        highlight.Name = "ESP_Highlight"
        highlight.Adornee = character
        highlight.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        highlight.FillColor = ESP_COLOR
        highlight.FillTransparency = 0.78

        highlight.OutlineColor =
            Color3.fromRGB(255, 255, 255)

        highlight.OutlineTransparency = 0

        highlight.Parent = Container

        data.highlight = highlight
    end

    if SKELETON_ENABLED then
        data.skeleton = createSkeleton(character)
    end

    Objects[player] = data
end

--==================================================
-- REFRESH
--==================================================

local function refresh()

    for _, player in ipairs(Players:GetPlayers()) do

        if player ~= LocalPlayer then
            createPlayer(player)
        end
    end
end

--==================================================
-- BUTTONS
--==================================================

ESPButton.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    updateButtons()
    refresh()
end)

SkeletonButton.MouseButton1Click:Connect(function()

    SKELETON_ENABLED = not SKELETON_ENABLED

    updateButtons()
    refresh()
end)

TeamButton.MouseButton1Click:Connect(function()

    TEAM_CHECK_ENABLED = not TEAM_CHECK_ENABLED

    updateButtons()

    -- Полностью пересоздаём ESP.
    -- Поэтому союзники сразу исчезают.
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
        Frame.Visible = GUI_VISIBLE
    end
end)

--==================================================
-- PLAYER EVENTS
--==================================================

local function setupPlayer(player)

    if player == LocalPlayer then
        return
    end

    player.CharacterAdded:Connect(function()

        task.wait(0.5)

        if ESP_ENABLED or SKELETON_ENABLED then
            createPlayer(player)
        end
    end)

    player.CharacterRemoving:Connect(function()
        removePlayer(player)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayer(player)
end

Players.PlayerAdded:Connect(setupPlayer)

Players.PlayerRemoving:Connect(function(player)
    removePlayer(player)
end)

--==================================================
-- TEAM CHANGES
--==================================================

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()

    if TEAM_CHECK_ENABLED then
        refresh()
    end
end)

for _, player in ipairs(Players:GetPlayers()) do

    if player ~= LocalPlayer then

        player:GetPropertyChangedSignal("Team"):Connect(function()

            if TEAM_CHECK_ENABLED then
                createPlayer(player)
            end
        end)
    end
end

--==================================================
-- START
--==================================================

updateButtons()
