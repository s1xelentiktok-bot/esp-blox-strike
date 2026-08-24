-- ESP SYSTEM
-- LocalScript
-- StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local ESP_ENABLED = false
local SKELETON_ENABLED = false
local TEAM_CHECK_ENABLED = false
local GUI_VISIBLE = true

local ESP_COLOR = Color3.fromRGB(255, 60, 60)
local SKELETON_COLOR = Color3.fromRGB(255, 255, 255)

local ESP_TRANSPARENCY = 0.78

local ESP_CONTAINER = Instance.new("Folder")
ESP_CONTAINER.Name = "LocalESP"
ESP_CONTAINER.Parent = workspace

local PlayerObjects = {}

--==================================================
-- GUI
--==================================================

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.Size = UDim2.fromOffset(270, 220)
Main.Position = UDim2.fromOffset(20, 20)
Main.BackgroundColor3 = Color3.fromRGB(24, 24, 28)
Main.BorderSizePixel = 0
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(65, 65, 75)
MainStroke.Thickness = 1
MainStroke.Parent = Main

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Size = UDim2.new(1, -20, 0, 38)
Title.Position = UDim2.fromOffset(10, 5)
Title.BackgroundTransparency = 1
Title.Text = "ESP"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.TextSize = 23
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Main

local function CreateButton(name, y)
    local Button = Instance.new("TextButton")

    Button.Name = name
    Button.Size = UDim2.new(1, -20, 0, 36)
    Button.Position = UDim2.fromOffset(10, y)
    Button.BackgroundColor3 = Color3.fromRGB(65, 30, 30)
    Button.BorderSizePixel = 0
    Button.AutoButtonColor = true
    Button.TextColor3 = Color3.fromRGB(255, 90, 90)
    Button.TextSize = 16
    Button.Font = Enum.Font.GothamBold
    Button.Parent = Main

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 7)
    Corner.Parent = Button

    return Button
end

local ESPButton = CreateButton("ESP", 45)
local SkeletonButton = CreateButton("Skeleton", 85)
local TeamButton = CreateButton("TeamCheck", 125)

local Hint = Instance.new("TextLabel")
Hint.Size = UDim2.new(1, -20, 0, 25)
Hint.Position = UDim2.fromOffset(10, 170)
Hint.BackgroundTransparency = 1
Hint.Text = "ALT — скрыть / показать"
Hint.TextColor3 = Color3.fromRGB(150, 150, 155)
Hint.TextSize = 12
Hint.Font = Enum.Font.Gotham
Hint.TextXAlignment = Enum.TextXAlignment.Left
Hint.Parent = Main

--==================================================
-- BUTTON STATE
--==================================================

local function UpdateButtons()

    if ESP_ENABLED then
        ESPButton.Text = "ESP: ON"
        ESPButton.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
        ESPButton.TextColor3 = Color3.fromRGB(90, 255, 110)
    else
        ESPButton.Text = "ESP: OFF"
        ESPButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
        ESPButton.TextColor3 = Color3.fromRGB(255, 90, 90)
    end

    if SKELETON_ENABLED then
        SkeletonButton.Text = "SKELETON: ON"
        SkeletonButton.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
        SkeletonButton.TextColor3 = Color3.fromRGB(90, 255, 110)
    else
        SkeletonButton.Text = "SKELETON: OFF"
        SkeletonButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
        SkeletonButton.TextColor3 = Color3.fromRGB(255, 90, 90)
    end

    if TEAM_CHECK_ENABLED then
        TeamButton.Text = "TEAM CHECK: ON"
        TeamButton.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
        TeamButton.TextColor3 = Color3.fromRGB(90, 255, 110)
    else
        TeamButton.Text = "TEAM CHECK: OFF"
        TeamButton.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
        TeamButton.TextColor3 = Color3.fromRGB(255, 90, 90)
    end
end

--==================================================
-- TEAM CHECK
--==================================================

local function IsEnemy(Player)

    if not TEAM_CHECK_ENABLED then
        return true
    end

    if not LocalPlayer.Team or not Player.Team then
        return true
    end

    return Player.Team ~= LocalPlayer.Team
end

--==================================================
-- CLEANUP
--==================================================

local function RemovePlayerESP(Player)

    local Data = PlayerObjects[Player]

    if not Data then
        return
    end

    if Data.Highlight then
        Data.Highlight:Destroy()
    end

    if Data.Skeleton then
        Data.Skeleton:Destroy()
    end

    PlayerObjects[Player] = nil
end

--==================================================
-- SKELETON
--==================================================

local function CreateSkeleton(Character)

    local Folder = Instance.new("Folder")
    Folder.Name = "Skeleton"
    Folder.Parent = ESP_CONTAINER

    local CreatedAttachments = {}

    local function GetAttachment(Part)

        if not Part then
            return nil
        end

        if CreatedAttachments[Part] then
            return CreatedAttachments[Part]
        end

        local Attachment = Instance.new("Attachment")
        Attachment.Name = "ESP_Attachment"
        Attachment.Parent = Part

        CreatedAttachments[Part] = Attachment

        return Attachment
    end

    for _, Object in ipairs(Character:GetDescendants()) do

        if Object:IsA("Motor6D") then

            local Part0 = Object.Part0
            local Part1 = Object.Part1

            if Part0 and Part1 then

                local Attachment0 = GetAttachment(Part0)
                local Attachment1 = GetAttachment(Part1)

                if Attachment0 and Attachment1 then

                    local Beam = Instance.new("Beam")

                    Beam.Name = "Bone"
                    Beam.Attachment0 = Attachment0
                    Beam.Attachment1 = Attachment1

                    Beam.Width0 = 0.045
                    Beam.Width1 = 0.045

                    Beam.FaceCamera = true
                    Beam.LightEmission = 1

                    Beam.Color = ColorSequence.new(
                        SKELETON_COLOR
                    )

                    Beam.Parent = Folder
                end
            end
        end
    end

    return Folder
end

--==================================================
-- CREATE ESP
--==================================================

local function CreatePlayerESP(Player)

    if Player == LocalPlayer then
        return
    end

    RemovePlayerESP(Player)

    if not ESP_ENABLED and not SKELETON_ENABLED then
        return
    end

    -- TEAM CHECK ПРОВЕРЯЕТСЯ ДО СОЗДАНИЯ ESP
    if not IsEnemy(Player) then
        return
    end

    local Character = Player.Character

    if not Character then
        return
    end

    if not Character:IsA("Model") then
        return
    end

    local Data = {}

    --==================================================
    -- HIGHLIGHT
    --==================================================

    if ESP_ENABLED then

        local Highlight = Instance.new("Highlight")

        Highlight.Name = "PlayerESP"
        Highlight.Adornee = Character

        Highlight.DepthMode =
            Enum.HighlightDepthMode.AlwaysOnTop

        Highlight.FillColor = ESP_COLOR
        Highlight.FillTransparency = ESP_TRANSPARENCY

        Highlight.OutlineColor =
            Color3.fromRGB(255, 255, 255)

        Highlight.OutlineTransparency = 0

        Highlight.Parent = ESP_CONTAINER

        Data.Highlight = Highlight
    end

    --==================================================
    -- SKELETON
    --==================================================

    if SKELETON_ENABLED then

        Data.Skeleton =
            CreateSkeleton(Character)
    end

    PlayerObjects[Player] = Data
end

--==================================================
-- REFRESH
--==================================================

local function RefreshESP()

    for _, Player in ipairs(Players:GetPlayers()) do

        if Player ~= LocalPlayer then
            CreatePlayerESP(Player)
        end
    end
end

--==================================================
-- TOGGLE ESP
--==================================================

ESPButton.MouseButton1Click:Connect(function()

    ESP_ENABLED = not ESP_ENABLED

    UpdateButtons()
    RefreshESP()
end)

--==================================================
-- TOGGLE SKELETON
--==================================================

SkeletonButton.MouseButton1Click:Connect(function()

    SKELETON_ENABLED = not SKELETON_ENABLED

    UpdateButtons()
    RefreshESP()
end)

--==================================================
-- TOGGLE TEAM CHECK
--==================================================

TeamButton.MouseButton1Click:Connect(function()

    TEAM_CHECK_ENABLED =
        not TEAM_CHECK_ENABLED

    UpdateButtons()

    -- Полностью пересоздаём ESP,
    -- поэтому своя команда сразу исчезает.
    RefreshESP()
end)

--==================================================
-- ALT GUI
--==================================================

UserInputService.InputBegan:Connect(function(Input, Processed)

    if Processed then
        return
    end

    if Input.KeyCode == Enum.KeyCode.LeftAlt
        or Input.KeyCode == Enum.KeyCode.RightAlt then

        GUI_VISIBLE = not GUI_VISIBLE

        Main.Visible = GUI_VISIBLE
    end
end)

--==================================================
-- PLAYER SETUP
--==================================================

local function SetupPlayer(Player)

    if Player == LocalPlayer then
        return
    end

    Player.CharacterAdded:Connect(function(Character)

        task.wait(0.5)

        if ESP_ENABLED or SKELETON_ENABLED then
            CreatePlayerESP(Player)
        end
    end)

    Player.CharacterRemoving:Connect(function()

        RemovePlayerESP(Player)
    end)

    if Player.Character then

        if ESP_ENABLED or SKELETON_ENABLED then
            CreatePlayerESP(Player)
        end
    end
end

for _, Player in ipairs(Players:GetPlayers()) do
    SetupPlayer(Player)
end

Players.PlayerAdded:Connect(function(Player)

    SetupPlayer(Player)
end)

Players.PlayerRemoving:Connect(function(Player)

    RemovePlayerESP(Player)
end)

--==================================================
-- TEAM CHANGE
--==================================================

LocalPlayer:GetPropertyChangedSignal("Team"):Connect(function()

    if TEAM_CHECK_ENABLED then
        RefreshESP()
    end
end)

--==================================================
-- INITIAL STATE
--==================================================

UpdateButtons()