--!strict
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RS                = game:GetService("ReplicatedStorage")
local JumpSystem = {}

local _cfg:         any
local buyRemote:    RemoteEvent
local purchased:    RemoteEvent
local showShop:     RemoteEvent

local function applyStats(pl: Player, jump: number, speed: number)
	local char = pl.Character; if not char then return end
	local h    = char:FindFirstChildOfClass("Humanoid"); if not h then return end
	h.JumpPower = jump; h.WalkSpeed = speed
end

local function applyParticles(pl: Player, kind: string)
	local char = pl.Character; if not char then return end
	local hrp  = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	for _, a in hrp:GetChildren() do
		if a:IsA("Attachment") and a.Name == "JumpFX" then a:Destroy() end
	end
	local att = Instance.new("Attachment"); att.Name = "JumpFX"; att.Parent = hrp
	local pe  = Instance.new("ParticleEmitter"); pe.Parent = att
	pe.Speed  = NumberRange.new(3, 8); pe.Rate = 15
	pe.Lifetime = NumberRange.new(0.5, 1.2)
	pe.SpreadAngle = Vector2.new(30, 30); pe.LockedToPart = false
	if kind == "hearts" then
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 100, 180))
		pe.Size  = NumberSequence.new(0.3)
	elseif kind == "fire" then
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255,  60, 0)),
		})
		pe.Size = NumberSequence.new(0.5); pe.LightEmission = 0.15
	end
end

local function handleBuy(pl: Player, jumpId: string)
	local PD = require(script.Parent.PlayerData)
	local d  = PD.get(pl); if not d then return end
	if PD.hasJump(pl, jumpId) then return end

	local cfg: any = nil
	for _, j in _cfg.JUMPS do if j.id == jumpId then cfg = j; break end end
	if not cfg then return end

	local ct = cfg.cost_type :: string
	if     ct == "free"           then  -- gratis
	elseif ct == "money"          then if d.money         < cfg.cost_value then return end; d.money -= cfg.cost_value
	elseif ct == "survive_waves"  then if d.wavesSurvived < cfg.cost_value then return end
	elseif ct == "kill_noobs"     then if d.noobsKilled   < cfg.cost_value then return end
	elseif ct == "sell_brainrots" then if d.brainrotsSold < cfg.cost_value then return end
	elseif ct == "fuse_brainrots" then if d.brainrotsFused< cfg.cost_value then return end
	else return
	end

	PD.unlockJump(pl, jumpId)

	if cfg.brainrot then
		PD.addBrainrot(pl, cfg.brainrot, cfg.brainrot_qty or 1)
	end
	if cfg.fill_base then
		for _ = 1, d.baseSlots do PD.addBrainrot(pl, "athos_brainrot") end
	end
	if cfg.wave_tokens  then d.waveTokens += cfg.wave_tokens end
	if cfg.extra == "wave_shield" then d.hasShield = true end
	if cfg.base_upgrade then d.baseSlots = _cfg.BASE.SLOTS_MAX end
	PD.sync(pl)

	applyStats(pl, cfg.jump, cfg.speed)
	if cfg.particles then applyParticles(pl, cfg.particles) end
	purchased:FireClient(pl, jumpId)
end

local function reapplyOnSpawn(pl: Player)
	pl.CharacterAdded:Connect(function()
		task.wait(0.15)
		local PD = require(script.Parent.PlayerData)
		local d  = PD.get(pl); if not d or d.currentJump == "none" then return end
		for _, j in _cfg.JUMPS do
			if j.id == d.currentJump then
				applyStats(pl, j.jump, j.speed)
				if (j :: any).particles then applyParticles(pl, (j :: any).particles) end
				break
			end
		end
	end)
end

function JumpSystem.init(cfg: any)
	_cfg = cfg
	local R = require(RS.Shared.Remotes)

	buyRemote        = Instance.new("RemoteEvent")
	buyRemote.Name   = R.BuyJump; buyRemote.Parent = RS
	buyRemote.OnServerEvent:Connect(handleBuy)

	purchased        = Instance.new("RemoteEvent")
	purchased.Name   = R.JumpPurchased; purchased.Parent = RS

	showShop        = Instance.new("RemoteEvent")
	showShop.Name   = R.ShowShop; showShop.Parent = RS

	Players.PlayerAdded:Connect(reapplyOnSpawn)
	for _, pl in Players:GetPlayers() do reapplyOnSpawn(pl) end

	-- CrackWall touch → abre loja
	task.spawn(function()
		task.wait(3)   -- aguarda MapTagger terminar
		local tagged = CollectionService:GetTagged("CrackWall")
		for _, part in tagged do
			if not part:IsA("BasePart") then continue end
			local touched: { [Player]: boolean } = {}
			(part :: BasePart).Touched:Connect(function(hit)
				local char = hit.Parent; if not char then return end
				local pl   = Players:GetPlayerFromCharacter(char); if not pl then return end
				if touched[pl] then return end
				touched[pl] = true
				showShop:FireClient(pl)
				task.delay(1, function() touched[pl] = nil end)
			end)
		end
	end)
end

return JumpSystem
