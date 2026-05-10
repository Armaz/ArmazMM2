local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- CONFIGURATION
local MAX_DISTANCE = 300
local SMOOTHNESS = 0.15 
local JITTER_STRENGTH = 0.01

-- ROLE DETECTION HELPER
local function getRole(player)
	if not player or not player.Character then return "Innocent" end
	local backpack = player:FindFirstChild("Backpack")
	local character = player.Character

	if (backpack and backpack:FindFirstChild("Knife")) or (character and character:FindFirstChild("Knife")) then
		return "Murderer"
	elseif (backpack and backpack:FindFirstChild("Gun")) or (character and character:FindFirstChild("Gun")) then
		return "Sheriff"
	end
	return "Innocent"
end

-- LOBBY CHECK (MM2 maps usually keep players away from the 'Lobby' area during rounds)
local function isInLobby()
	local char = LocalPlayer.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return true end
	
	-- Most MM2 lobbies are located at very specific high or low Y coordinates
	-- Or we check if the 'Voting' or 'Map' UI is visible
	if LocalPlayer.PlayerGui:FindFirstChild("MainGui") and LocalPlayer.PlayerGui.MainGui:FindFirstChild("Lobby") then
		return LocalPlayer.PlayerGui.MainGui.Lobby.Visible
	end
	return false
end

-- TARGETING LOGIC
local function getTarget()
	if isInLobby() then return nil end

	local myRole = getRole(LocalPlayer)
	local targets = {}
	local closestTarget = nil
	local shortestDistance = MAX_DISTANCE

	-- Step 1: Decide who we are allowed to hit
	for _, p in pairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
			local targetRole = getRole(p)
			local humanoid = p.Character:FindFirstChild("Humanoid")

			if humanoid and humanoid.Health > 0 then
				if myRole == "Murderer" then
					-- Priority: Sheriff first, then Innocents
					if targetRole == "Sheriff" then
						table.insert(targets, {part = p.Character.Head, priority = 1})
					else
						table.insert(targets, {part = p.Character.Head, priority = 2})
					end
				elseif myRole == "Sheriff" then
					-- Only lock onto Murderer
					if targetRole == "Murderer" then
						table.insert(targets, {part = p.Character.Head, priority = 1})
					end
				elseif myRole == "Innocent" then
					-- Only lock onto Murderer IF I have the gun (Hero)
					if LocalPlayer.Backpack:FindFirstChild("Gun") or LocalPlayer.Character:FindFirstChild("Gun") then
						if targetRole == "Murderer" then
							table.insert(targets, {part = p.Character.Head, priority = 1})
						end
					end
				end
			end
		end
	end

	-- Step 2: Pick the best target based on priority and distance
	table.sort(targets, function(a, b) return a.priority < b.priority end)

	for _, t in ipairs(targets) do
		local dist = (LocalPlayer.Character.HumanoidRootPart.Position - t.part.Position).Magnitude
		if dist < shortestDistance then
			shortestDistance = dist
			closestTarget = t.part
			-- If we found a priority 1 (Sheriff/Murderer), we stop looking and lock on
			if t.priority == 1 then break end 
		end
	end

	return closestTarget
end

-- EXECUTION LOOP
RunService.RenderStepped:Connect(function()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
		local targetHead = getTarget()
		
		if targetHead then
			local jitter = Vector3.new(
				math.random(-100, 100) / 1000 * JITTER_STRENGTH,
				math.random(-100, 100) / 1000 * JITTER_STRENGTH,
				math.random(-100, 100) / 1000 * JITTER_STRENGTH
			)
			
			local targetCFrame = CFrame.new(Camera.CFrame.Position, targetHead.Position + jitter)
			Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, SMOOTHNESS)
		end
	end
end)
