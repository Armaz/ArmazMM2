local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- SETTINGS
local MURDERER_COLOR = Color3.fromRGB(255, 0, 0)
local SHERIFF_COLOR = Color3.fromRGB(0, 0, 255)
local INNOCENT_COLOR = Color3.fromRGB(0, 255, 0)
local SELF_COLOR = Color3.fromRGB(255, 255, 255) 

local function getRoleInfo(player)
    if not player then return "INNOCENT", INNOCENT_COLOR end
    
    local backpack = player:FindFirstChild("Backpack")
    local character = player.Character

    local hasKnife = (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife"))
    local hasGun = (backpack and backpack:FindFirstChild("Gun")) or (character and character:FindFirstChild("Gun"))

    if hasKnife then
        return "MURDERER", MURDERER_COLOR
    elseif hasGun then
        return "SHERIFF", SHERIFF_COLOR
    end
    
    return "INNOCENT", INNOCENT_COLOR
end

local function addESP(player, character)
    -- ALWAYS lock the search to the Head
    local head = character:FindFirstChild("Head")
    if not head then return end

    -- 1. HIGHLIGHT (Stays on Character)
    local highlight = character:FindFirstChild("MM2Highlight")
    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "MM2Highlight"
        highlight.Parent = character
    end

    -- 2. BILLBOARD GUI (Locked to Head)
    local billboard = character:FindFirstChild("MM2Label")
    if not billboard then
        billboard = Instance.new("BillboardGui")
        billboard.Name = "MM2Label"
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.AlwaysOnTop = true
        billboard.MaxDistance = math.huge
        billboard.ExtentsOffset = Vector3.new(0, 3, 0)
        
        local label = Instance.new("TextLabel")
        label.Name = "RoleText"
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Font = Enum.Font.GothamBold
        label.TextSize = 20
        label.TextStrokeTransparency = 0
        label.TextStrokeColor3 = Color3.new(0,0,0)
        label.Parent = billboard
    end
    
    -- Force the Billboard to be parented to the Head specifically
    billboard.Adornee = head
    billboard.Parent = character

    -- 3. APPLY COLORS & TEXT
    if player == LocalPlayer then
        highlight.FillColor = SELF_COLOR
        highlight.OutlineColor = Color3.new(0,0,0)
        billboard.RoleText.Text = "YOU"
        billboard.RoleText.TextColor3 = SELF_COLOR
    else
        local roleName, roleColor = getRoleInfo(player)
        highlight.FillColor = roleColor
        highlight.OutlineColor = Color3.new(1,1,1)
        billboard.RoleText.Text = roleName
        billboard.RoleText.TextColor3 = roleColor
    end

    highlight.FillTransparency = 0.5
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

-- Faster Refresh
task.spawn(function()
    while task.wait(0.3) do
        for _, player in pairs(Players:GetPlayers()) do
            if player.Character then
                addESP(player, player.Character)
            end
        end
    end
end)
