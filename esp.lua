local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local ESPEnabled = false
local highlights = {}

local function addESP(player)
    if player == LocalPlayer then return end
    if not player.Character then return end

    local old = player.Character:FindFirstChild("MyESP")
    if old then
        old:Destroy()
    end

    if not ESPEnabled then return end

    local highlight = Instance.new("Highlight")
    highlight.Name = "MyESP"
    highlight.Adornee = player.Character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.7
    highlight.OutlineTransparency = 0

    highlight.Parent = player.Character
    highlights[player] = highlight
end

local function removeESP(player)
    if highlights[player] then
        highlights[player]:Destroy()
        highlights[player] = nil
    end

    if player.Character then
        local esp = player.Character:FindFirstChild("MyESP")
        if esp then
            esp:Destroy()
        end
    end
end

local function setESP(state)
    ESPEnabled = state

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if state then
                addESP(player)
            else
                removeESP(player)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(0.5)
        if ESPEnabled then
            addESP(player)
        end
    end)
end)

Players.PlayerRemoving:Connect(removeESP)

setESP(true)