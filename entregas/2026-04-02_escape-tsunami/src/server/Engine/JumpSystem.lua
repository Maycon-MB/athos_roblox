--!strict
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local JumpSystem = {}

local _cfg: any
local buyRemote: RemoteEvent
local purchased: RemoteEvent
local showShop: RemoteEvent

local function applyStats(pl: Player, jump: number, speed: number)
	local char = pl.Character
	if not char then
		return
	end
	local h = char:FindFirstChildOfClass("Humanoid")
	if not h then
		return
	end
	h.JumpPower = jump
	h.WalkSpeed = speed
end

local function applyParticles(pl: Player, kind: string)
	local char = pl.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	for _, a in hrp:GetChildren() do
		if a:IsA("Attachment") and a.Name == "JumpFX" then
			a:Destroy()
		end
	end
	local att = Instance.new("Attachment")
	att.Name = "JumpFX"
	att.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Parent = att
	pe.Speed = NumberRange.new(3, 8)
	pe.Rate = 15
	pe.Lifetime = NumberRange.new(0.5, 1.2)
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.LockedToPart = false
	if kind == "hearts" then
		pe.Color = ColorSequence.new(Color3.fromRGB(255, 100, 180))
		pe.Size = NumberSequence.new(0.3)
	elseif kind == "fire" then
		pe.Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)),
			ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 60, 0)),
		})
		pe.Size = NumberSequence.new(0.5)
		pe.LightEmission = 0.15
	end
end

local function handleBuy(pl: Player, jumpId: string)
	local PD = require(script.Parent.PlayerData)
	local d = PD.get(pl)
	if not d then
		return
	end
	if PD.hasJump(pl, jumpId) then
		return
	end

	local cfg: any = nil
	for _, j in _cfg.JUMPS do
		if j.id == jumpId then
			cfg = j
			break
		end
	end
	if not cfg then
		return
	end

	local ct = cfg.cost_type :: string
	if ct == "free" then -- gratis
	elseif ct == "money" then
		if d.money < cfg.cost_value then
			return
		end
		d.money -= cfg.cost_value
	elseif ct == "survive_waves" then
		if d.wavesSurvived < cfg.cost_value then
			return
		end
	elseif ct == "kill_noobs" then
		if d.noobsKilled < cfg.cost_value then
			return
		end
	elseif ct == "sell_brainrots" or ct == "fuse_brainrots" then
		-- Transacional: verifica E consome N brainrots do inventário agora.
		if not PD.consumeAnyBrainrots(pl, cfg.cost_value) then
			return
		end
	else
		return
	end

	PD.unlockJump(pl, jumpId)

	if cfg.brainrot then
		PD.addBrainrot(pl, cfg.brainrot, cfg.brainrot_qty or 1)
	end
	if cfg.fill_base then
		-- Preenche todos os slots físicos dos pedestais + adiciona ao inventário.
		-- require dentro da função para evitar ciclo de dependência no init.
		local BS = require(script.Parent.BaseSystem)
		BS.fillAll(pl, "athos_mutacao_fogo")
	end
	if cfg.wave_tokens then
		d.waveTokens += cfg.wave_tokens
	end
	if cfg.extra == "wave_shield" then
		d.hasShield = true
	end
	if cfg.extra == "galaxy_bat" then
		local tool = Instance.new("Tool")
		tool.Name = "GalaxyBat"
		tool.ToolTip = "Galaxy Bat"
		tool.RequiresHandle = true
		local handle = Instance.new("Part")
		handle.Name = "Handle"
		handle.Size = Vector3.new(0.35, 2.4, 0.35)
		handle.BrickColor = BrickColor.new("Bright violet")
		handle.Material = Enum.Material.Neon
		handle.Parent = tool
		local head = Instance.new("Part")
		head.Name = "Head"
		head.Size = Vector3.new(1.4, 0.5, 0.5)
		head.BrickColor = BrickColor.new("Bright yellow")
		head.Material = Enum.Material.SmoothPlastic
		head.CanCollide = false
		head.Parent = tool
		local hw = Instance.new("WeldConstraint")
		hw.Part0 = handle; hw.Part1 = head; hw.Parent = tool
		head.CFrame = handle.CFrame * CFrame.new(0.9, 1.1, 0)
		tool.Parent = pl.Backpack
	end
	if cfg.base_upgrade then
		d.baseSlots = _cfg.BASE.SLOTS_MAX
	end
	PD.sync(pl)

	applyStats(pl, cfg.jump, cfg.speed)
	if cfg.particles then
		applyParticles(pl, cfg.particles)
	end
	purchased:FireClient(pl, jumpId)
end

local function reapplyOnSpawn(pl: Player)
	pl.CharacterAdded:Connect(function()
		task.wait(0.15)
		local PD = require(script.Parent.PlayerData)
		local d = PD.get(pl)
		if not d or d.currentJump == "none" then
			return
		end
		for _, j in _cfg.JUMPS do
			if j.id == d.currentJump then
				applyStats(pl, j.jump, j.speed)
				if (j :: any).particles then
					applyParticles(pl, (j :: any).particles)
				end
				break
			end
		end
	end)
end

function JumpSystem.init(cfg: any)
	_cfg = cfg
	local R = require(RS.Shared.Remotes)

	buyRemote = Instance.new("RemoteEvent")
	buyRemote.Name = R.BuyJump
	buyRemote.Parent = RS
	buyRemote.OnServerEvent:Connect(handleBuy)

	purchased = Instance.new("RemoteEvent")
	purchased.Name = R.JumpPurchased
	purchased.Parent = RS

	showShop = Instance.new("RemoteEvent")
	showShop.Name = R.ShowShop
	showShop.Parent = RS

	-- GalaxyBat knockback (client dispara via GalaxyBatSwing)
	local galaxyBatSwing = Instance.new("RemoteEvent")
	galaxyBatSwing.Name = R.GalaxyBatSwing
	galaxyBatSwing.Parent = RS
	galaxyBatSwing.OnServerEvent:Connect(function(pl: Player)
		local char = pl.Character
		if not char then return end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then return end
		local ws = game:GetService("Workspace")
		for _, obj in ws:GetDescendants() do
			if obj.Name == "Noob" and obj:IsA("Model") then
				local noobHrp = obj:FindFirstChild("HumanoidRootPart") :: BasePart?
				if noobHrp then
					local dist = (noobHrp.Position - hrp.Position).Magnitude
					if dist < 14 then
						local dir = (noobHrp.Position - hrp.Position).Unit
						noobHrp:ApplyImpulse(dir * 90 + Vector3.new(0, 45, 0))
					end
				end
			end
		end
	end)

	Players.PlayerAdded:Connect(reapplyOnSpawn)
	for _, pl in Players:GetPlayers() do
		reapplyOnSpawn(pl)
	end

	-- Posição salva ao entrar pela ShopEntrance — usada pelo ShopExit para retornar
	local shopEntryCFrame: { [Player]: CFrame } = {}
	Players.PlayerRemoving:Connect(function(pl) shopEntryCFrame[pl] = nil end)

	-- Utilitário: conecta Touched com cooldown por player
	local function onTouched(part: BasePart, fn: (pl: Player, char: Model) -> ())
		local cooldown: { [Player]: boolean } = {}
		part.Touched:Connect(function(hit)
			local char = hit.Parent
			if not char then return end
			local pl = Players:GetPlayerFromCharacter(char)
			if not pl or cooldown[pl] then return end
			cooldown[pl] = true
			fn(pl, char :: Model)
			task.delay(2, function() cooldown[pl] = nil end)
		end)
	end

	-- ShopEntrance: sensor na rachadura → teleporta para dentro da loja (sem abrir UI)
	local function setupShopEntrance(part: BasePart)
		-- Visual: luz neon roxa + partículas para indicar passagem secreta
		local light = Instance.new("PointLight")
		light.Color      = Color3.fromRGB(140, 60, 255)
		light.Brightness = 3
		light.Range      = 18
		light.Parent     = part

		local att = Instance.new("Attachment")
		att.Parent = part
		local pe = Instance.new("ParticleEmitter")
		pe.Color        = ColorSequence.new(Color3.fromRGB(160, 80, 255))
		pe.LightEmission = 0.18
		pe.Rate          = 6
		pe.Lifetime      = NumberRange.new(1, 2)
		pe.Speed         = NumberRange.new(1, 3)
		pe.SpreadAngle   = Vector2.new(60, 60)
		pe.Size          = NumberSequence.new(0.2)
		pe.Parent        = att

		onTouched(part, function(pl, char)
			if _cfg and _cfg.MAP_AREAS and _cfg.MAP_AREAS.shop then
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					-- Salva posição de entrada para o ShopExit restaurar
					-- 3 studs atrás do HRP (posição do mapa antes de atravessar a parede)
					shopEntryCFrame[pl] = (hrp :: BasePart).CFrame * CFrame.new(0, 0, 3)
					local dest: CFrame = _cfg.MAP_AREAS.shop.teleport_in or _cfg.MAP_AREAS.shop.spawn
					;(hrp :: BasePart).CFrame = dest
				end
			end
			-- UI NÃO abre aqui — só abre ao se aproximar do balcão (ShopCounter)
		end)
	end

	-- ShopCounter: trigger próximo ao NPC/balcão → abre a JumpShop UI
	local function setupShopCounter(part: BasePart)
		onTouched(part, function(pl, _char)
			showShop:FireClient(pl)
		end)
	end

	-- ShopExit: portal invisível na saída da loja → player volta para a posição de entrada
	-- Cooldown de 4s para não disparar logo ao entrar na loja
	local shopExitCooldown: { [Player]: boolean } = {}
	local function setupShopExit(part: BasePart)
		part.Touched:Connect(function(hit)
			local char = hit.Parent
			if not char then return end
			local pl = Players:GetPlayerFromCharacter(char)
			if not pl or shopExitCooldown[pl] then return end
			shopExitCooldown[pl] = true
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				-- Prioridade 1: posição salva ao entrar pela ShopEntrance
				local saved = shopEntryCFrame[pl]
				if saved then
					(hrp :: BasePart).CFrame = saved
				elseif _cfg and _cfg.MAP_AREAS then
					-- Fallback: spawn principal + raycast pra achar chão real
					local returnCF: CFrame = _cfg.MAP_AREAS.main.spawn
					local ws = game:GetService("Workspace")
					local rp = RaycastParams.new()
					rp.FilterType = Enum.RaycastFilterType.Exclude
					rp.FilterDescendantsInstances = { char }
					local origin = returnCF.Position + Vector3.new(0, 300, 0)
					local hitR = ws:Raycast(origin, Vector3.new(0, -800, 0), rp)
					if hitR and hitR.Normal.Y > 0.5 then
						(hrp :: BasePart).CFrame = CFrame.new(hitR.Position + Vector3.new(0, 5, 0))
					else
						(hrp :: BasePart).CFrame = returnCF + Vector3.new(0, 10, 0)
						warn("[ShopExit] raycast sem chão — fallback +10Y")
					end
				end
			end
			task.delay(4, function() shopExitCooldown[pl] = nil end)
		end)
	end

	task.spawn(function()
		task.wait(3) -- aguarda MapSystem criar as tags
		for _, part in CollectionService:GetTagged("ShopEntrance") do
			if part:IsA("BasePart") then setupShopEntrance(part :: BasePart) end
		end
		for _, part in CollectionService:GetTagged("ShopExit") do
			if part:IsA("BasePart") then setupShopExit(part :: BasePart) end
		end
		for _, part in CollectionService:GetTagged("ShopCounter") do
			if part:IsA("BasePart") then setupShopCounter(part :: BasePart) end
		end
		CollectionService:GetInstanceAddedSignal("ShopEntrance"):Connect(function(part)
			if part:IsA("BasePart") then setupShopEntrance(part :: BasePart) end
		end)
		CollectionService:GetInstanceAddedSignal("ShopExit"):Connect(function(part)
			if part:IsA("BasePart") then setupShopExit(part :: BasePart) end
		end)
		CollectionService:GetInstanceAddedSignal("ShopCounter"):Connect(function(part)
			if part:IsA("BasePart") then setupShopCounter(part :: BasePart) end
		end)
	end)
end

return JumpSystem
