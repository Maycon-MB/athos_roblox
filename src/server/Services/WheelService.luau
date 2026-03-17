--!strict

-- Módulo 2 + Módulo 5 — Wheel Spin com Zero Trust
-- CollectionService gerencia os objetos interativos (tag "WheelSpin")
-- Magnitude check no servidor antes de processar qualquer ação

local CollectionService  = game:GetService("CollectionService")
local ReplicatedStorage  = game:GetService("ReplicatedStorage")
local Players            = game:GetService("Players")

local RemoteNames = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteNames")
)

local WHEEL_TAG  = "WheelSpin"
local MAX_DIST   = 18  -- Módulo 2: distância máxima para ativar o giro

type RewardTier = { label: string, chance: number, coins: number }

local REWARDS: { RewardTier } = {
	{ label = "50 Coins",   chance = 0.40, coins = 50  },
	{ label = "100 Coins",  chance = 0.30, coins = 100 },
	{ label = "200 Coins",  chance = 0.18, coins = 200 },
	{ label = "Rare Egg",   chance = 0.08, coins = 0   },
	{ label = "Epic Pet",   chance = 0.04, coins = 0   },
}

local WheelService = {}

-- Cooldown por jogador — evita spam
local cooldowns: { [Player]: number } = {}
local COOLDOWN_SEC = 30

local function pickReward(): RewardTier
	local roll = math.random()
	local acc  = 0
	for _, tier in REWARDS do
		acc += tier.chance
		if roll <= acc then
			return tier
		end
	end
	return REWARDS[1]
end

local function getRemote(): RemoteEvent?
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then return nil end
	local ev = remotes:FindFirstChild(RemoteNames.WHEEL_REWARD)
	if ev and ev:IsA("RemoteEvent") then return ev :: RemoteEvent end
	return nil
end

local function deliverReward(player: Player, tier: RewardTier): ()
	-- Entrega moedas via leaderstats (Módulo 5 — monetização tangível)
	if tier.coins > 0 then
		local ls = player:FindFirstChild("leaderstats")
		if ls then
			local coinsVal = ls:FindFirstChild("Coins")
			if coinsVal and coinsVal:IsA("IntValue") then
				coinsVal.Value += tier.coins
			end
		end
	end

	-- Notifica cliente para exibir popup de recompensa (Módulo 6 — UX)
	local remote = getRemote()
	if remote then
		remote:FireClient(player, tier.label)
	end

	print("[WheelService]", player.Name, "girou → recompensa:", tier.label)
end

local function onTriggered(player: Player, promptHost: BasePart): ()
	-- Módulo 2: Magnitude check (Zero Trust Architecture)
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local dist = (hrp.Position - promptHost.Position).Magnitude
	if dist > MAX_DIST then
		warn("[WheelService] Magnitude check falhou —", player.Name,
			"dist:", math.round(dist), "/ max:", MAX_DIST)
		return
	end

	-- Cooldown
	local now  = tick()
	local last = cooldowns[player] or 0
	if now - last < COOLDOWN_SEC then
		local remaining = math.ceil(COOLDOWN_SEC - (now - last))
		local remote    = getRemote()
		if remote then
			remote:FireClient(player, "Cooldown: " .. tostring(remaining) .. "s")
		end
		return
	end
	cooldowns[player] = now

	deliverReward(player, pickReward())
end

local function hookPrompt(part: Instance): ()
	if not part:IsA("BasePart") then return end
	local basePart = part :: BasePart
	local prompt   = basePart:FindFirstChildOfClass("ProximityPrompt")
	if not prompt then
		prompt = basePart:WaitForChild("ProximityPrompt", 5) :: ProximityPrompt?
	end
	if not prompt then return end

	prompt.Triggered:Connect(function(player: Player)
		onTriggered(player, basePart)
	end)
end

function WheelService.init(): ()
	-- Módulo 5: CollectionService — gerencia todos os objetos com tag WheelSpin
	for _, part in CollectionService:GetTagged(WHEEL_TAG) do
		task.spawn(hookPrompt, part)
	end

	CollectionService:GetInstanceAddedSignal(WHEEL_TAG):Connect(function(part: Instance)
		task.spawn(hookPrompt, part)
	end)

	-- Limpa cooldowns quando jogador sai
	Players.PlayerRemoving:Connect(function(player: Player)
		cooldowns[player] = nil
	end)

	print("[WheelService] Inicializado — tag:", WHEEL_TAG, "| max dist:", MAX_DIST)
end

return WheelService
