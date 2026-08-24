-- esp.lua

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer

local enabled = false
local guiVisible = true

-- GUI
local gui = Instance.new("ScreenGui")
gui.Name = "ESPExecutor"
gui.ResetOnSpawn = false
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(230, 100)
frame.Position = UDim2.fromOffset(20, 20)
frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
frame.BorderSizePixel = 0
frame.Parent = gui

Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundTransparency = 1
title.Text = "ESP"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 22
title.Font = Enum.Font.GothamBold
title.Parent = frame

local status = Instance.new("TextButton")
status.Size = UDim2.new(1, -20, 0, 35)
status.Position = UDim2.fromOffset(10, 40)
status.BorderSizePixel = 0
status.TextSize = 18
status.Font = Enum.Font.GothamBold
status.Parent = frame

Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)

local function updateStatus()
    if enabled then
        status.Text = "ESP: ON"
        status.TextColor3 = Color3.fromRGB(80, 255, 100)
        status.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
    else
        status.Text = "ESP: OFF"
        status.TextColor3 = Color3.fromRGB(255, 80, 80)
        status.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    end
end

local function removeESP(character)
    local highlight = character and character:FindFirstChild("ESP_Highlight")

    if highlight then
        highlight:Destroy()
    end
end

local function addESP(player)
    if player == LocalPlayer then
        return
    end

    local character = player.Character

    if not character then
        return
    end

    removeESP(character)

    if not enabled then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.FillTransparency = 0.75

    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.OutlineTransparency = 0

    highlight.Parent = character
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        addESP(player)
    end
end

local function setESP(state)
    enabled = state
    updateStatus()
    updateESP()
end

status.MouseButton1Click:Connect(function()
    setESP(not enabled)
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)

        if enabled then
            addESP(player)
        end
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        player.CharacterAdded:Connect(function()
            task.wait(0.5)

            if enabled then
                addESP(player)
            end
        end)
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end

    if input.KeyCode == Enum.KeyCode.LeftAlt
        or input.KeyCode == Enum.KeyCode.RightAlt then

        guiVisible = not guiVisible
        frame.Visible = guiVisible
    end
end)

updateStatus()
setESP(false)