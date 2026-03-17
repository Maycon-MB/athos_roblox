--!strict

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))

local SpawnService = {}

-- Olha para o centro do hub ao nascer (evita spawnar de costas para o mapa)
local HUB_LOOK_AT = Vector3.new(0, 2, 0)  -- centro do hub, Y=2 (nível da plataforma)

local function setupLeaderstats(player: Player): ()
	local ls      = Instance.new("Folder")
	ls.Name       = "leaderstats"
	ls.Parent     = player

	local coins   = Instance.new("IntValue")
	coins.Name    = "Coins"
	coins.Value   = 0
	coins.Parent  = ls
end

local function place(character: Model): ()
	local spawnCF = CFrame.new(GameConfig.SPAWN_POSITION, HUB_LOOK_AT)
	local ok, err = pcall(function()
		character:PivotTo(spawnCF)
	end)
	if not ok then
		warn("[SpawnService] PivotTo falhou:", err)
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then hrp.CFrame = spawnCF end
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
		setupLeaderstats(player)
		player.CharacterAdded:Connect(function(char: Model)
			task.spawn(onCharacterAdded, char)
		end)
	end)
	for _, player in Players:GetPlayers() do
		setupLeaderstats(player)
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
