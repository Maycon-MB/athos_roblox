--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local SpawnService = {}

local function place(character: Model): ()
	local ok, err = pcall(function()
		character:PivotTo(CFrame.new(GameConfig.SPAWN_POSITION))
	end)
	if not ok then
		warn("[SpawnService] PivotTo falhou:", err)
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then hrp.CFrame = CFrame.new(GameConfig.SPAWN_POSITION) end
	end
end

local function applyShield(character: Model): ()
	local hum = character:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local maxHP  = hum.MaxHealth
	local finish = tick() + GameConfig.SPAWN_SHIELD_SEC
	task.spawn(function()
		while tick() < finish do
			if not (hum and hum.Parent) then break end
			if hum.Health < maxHP then hum.Health = maxHP end
			task.wait(0.1)
		end
	end)
end

local function onCharacterAdded(character: Model): ()
	character:WaitForChild("HumanoidRootPart", 10)
	character:WaitForChild("Humanoid", 10)
	task.wait(0.15)
	place(character)
	applyShield(character)
end

function SpawnService.init(): ()
	Players.PlayerAdded:Connect(function(player: Player)
		player.CharacterAdded:Connect(function(char: Model)
			task.spawn(onCharacterAdded, char)
		end)
	end)
	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(function(char: Model)
			task.spawn(onCharacterAdded, char)
		end)
		if player.Character then
			task.spawn(onCharacterAdded, player.Character)
		end
	end
	print("[SpawnService] Inicializado.")
end

return SpawnService
