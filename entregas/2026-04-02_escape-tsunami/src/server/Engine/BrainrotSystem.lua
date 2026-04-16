--!strict
-- BrainrotSystem — Brainrots para cenários fake.
-- Spawn dentro de MAP_AREAS.main. ProximityPrompt (E) para coletar.
-- Carry visual + SafeZone delivery + FusionMachine.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local BrainrotSystem = {}

local _cfg: any
local active: { Model } = {}
local carrying: { [Player]: Model } = {}
local disabledBrainrots: { [string]: boolean } = {}

-- ── API pública para BaseSystem ──────────────────────────────────────
function BrainrotSystem.isCarrying(pl: Player): boolean
	return carrying[pl] ~= nil
end

function BrainrotSystem.getCarriedId(pl: Player): string?
	local m = carrying[pl]
	if not m then return nil end
	local idVal = m:FindFirstChild("BrainrotId") :: StringValue?
	return if idVal then idVal.Value else nil
end

function BrainrotSystem.dropCarried(pl: Player)
	local m = carrying[pl]
	if m and m.Parent then
		m:Destroy()
	end
	carrying[pl] = nil :: any
end

-- Habilita/desabilita spawn de um brainrot específico (chamado pelo AdminSystem)
function BrainrotSystem.setEnabled(id: string, enabled: boolean)
	disabledBrainrots[id] = not enabled
end
local sellRemote: RemoteEvent
local fuseRemote: RemoteEvent
local fuseResult: RemoteEvent

-- ── Solda brainrot acima da cabeça do jogador ───────────────────────
local function attachToPlayer(pl: Player, model: Model, body: BasePart)
	local char = pl.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end

	local flag = Instance.new("BoolValue")
	flag.Name = "_carried"
	flag.Parent = model

	for _, obj in model:GetDescendants() do
		if obj:IsA("BasePart") and obj ~= body then
			obj.Anchored = false
			local wc = Instance.new("WeldConstraint")
			wc.Part0 = obj
			wc.Part1 = body
			wc.Parent = model
		end
	end

	body.CFrame = hrp.CFrame * CFrame.new(0, 6, 0)
	body.Anchored = false
	local wc2 = Instance.new("WeldConstraint")
	wc2.Part0 = body
	wc2.Part1 = hrp
	wc2.Parent = model

	carrying[pl] = model
end

-- ── Helpers ─────────────────────────────────────────────────────────
local function pt(parent: Instance, sz: Vector3, cf: CFrame, col: Color3): Part
	local p = Instance.new("Part")
	p.Size = sz
	p.CFrame = cf
	p.Color = col
	p.Anchored = true
	p.CanCollide = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CastShadow = false
	p.Parent = parent
	return p
end

local function textLabel(parent: Instance, txt: string, col: Color3, sz: UDim2, pos: UDim2?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = sz
	l.Position = pos or UDim2.new(0, 0, 0, 0)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.GothamBold
	l.TextScaled = true
	l.TextColor3 = col
	l.TextStrokeTransparency = 0
	l.Text = txt
	l.Parent = parent
	return l
end

local function makeBrainrot(br: any, origin: CFrame): (Model, BasePart)
	local ws = game:GetService("Workspace")
	local rar = _cfg.RARITIES[br.rarity] or _cfg.RARITIES[1]

	-- Tenta clonar modelo real do ServerStorage (campo model_name > name > id)
	local SS = game:GetService("ServerStorage")
	local template: Model? = nil
	local modelName: string = if br.model_name ~= nil
		then br.model_name :: string
		else (br.name :: string)
	template = SS:FindFirstChild(modelName) :: Model?
	if not template then
		template = SS:FindFirstChild(br.id) :: Model?
	end

	local m: Model
	local body: BasePart

	if template then
		-- Usa modelo real com textura
		m = template:Clone() :: Model
		m.Name = "BR_" .. br.id
		-- Posiciona: PrimaryPart ou primeiro BasePart encontrado
		local primary = m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart") :: BasePart?
		if primary then
			m:PivotTo(origin * CFrame.new(0, primary.Size.Y / 2, 0))
		end
		body = (m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")) :: BasePart
		body.Name = "Body"
		-- Ancora todas as parts do modelo
		for _, obj in m:GetDescendants() do
			if obj:IsA("BasePart") then
				obj.Anchored = true
				obj.CanCollide = false
			end
		end
		m.Parent = ws
	else
		-- Fallback: esfera flutuante na cor do brainrot (sem boneco feio)
		m = Instance.new("Model")
		m.Name   = "BR_" .. br.id
		m.Parent = ws

		body          = pt(m, Vector3.new(3, 3, 3), origin * CFrame.new(0, 2, 0), br.color or rar.color or Color3.new(1, 1, 1))
		body.Name     = "Body"
		body.Shape    = Enum.PartType.Ball
		body.Material = Enum.Material.SmoothPlastic
	end

	-- BillboardGui de tag (nome/raridade/renda) — sempre presente
	local tagBB = Instance.new("BillboardGui")
	tagBB.Size = UDim2.new(0, 160, 0, 54)
	tagBB.StudsOffset = Vector3.new(0, 4.5, 0)
	tagBB.Parent = body
	textLabel(tagBB, br.name, Color3.new(1, 1, 1), UDim2.new(1, 0, 0.48, 0))
	textLabel(tagBB, rar.name, rar.color, UDim2.new(1, 0, 0.28, 0), UDim2.new(0, 0, 0.48, 0))
	textLabel(
		tagBB,
		"$" .. tostring(br.income) .. "/s",
		Color3.fromRGB(255, 220, 60),
		UDim2.new(1, 0, 0.24, 0),
		UDim2.new(0, 0, 0.76, 0)
	)

	-- Float animation
	task.spawn(function()
		local t = math.random() * math.pi * 2
		local parts: { BasePart } = {}
		local baseY: { number } = {}
		for _, obj in m:GetDescendants() do
			if obj:IsA("BasePart") then
				table.insert(parts, obj)
				table.insert(baseY, obj.Position.Y)
			end
		end
		while m.Parent and not m:FindFirstChild("_carried") do
			t += task.wait(0.03)
			if m:FindFirstChild("_carried") then break end
			local dy = math.sin(t) * 0.3
			for i, p2 in parts do
				if p2.Anchored then -- não move parts já soldadas ao HRP
					p2.CFrame = CFrame.new(p2.Position.X, baseY[i] + dy, p2.Position.Z)
				end
			end
		end
	end)

	m.PrimaryPart = body
	return m, body
end

local function pickBrainrot(): any
	local w = _cfg.SPAWN_WEIGHTS
	-- Filtra brainrots desabilitados pelo admin
	local pool: { any } = {}
	for _, br in _cfg.BRAINROTS do
		if not disabledBrainrots[br.id] then
			table.insert(pool, br)
		end
	end
	if #pool == 0 then return _cfg.BRAINROTS[1] end

	local total = 0
	for _, br in pool do
		total += w[br.rarity] or 0
	end
	local roll = math.random() * total
	local acc = 0
	for _, br in pool do
		acc += w[br.rarity] or 0
		if roll <= acc then
			return br
		end
	end
	return pool[1]
end

-- SPAWN_ZONES: lidas de Settings.SPAWN_ZONES (retângulos XZ explícitos).
-- Raycast desce para achar o Y real do chão em cada posição escolhida.
-- Sem análise de geometria — fonte de verdade é o Settings.lua.
local spawnZonesLogged = false

local function pickSpawnCF(): CFrame?
	local ws2    = game:GetService("Workspace")
	local zones  = _cfg.SPAWN_ZONES
	if not zones or #zones == 0 then return nil end

	-- Escolhe zona aleatória (ponderada pelo tamanho)
	local totalArea = 0
	for _, z in zones do totalArea += (z.halfX * 2) * (z.halfZ * 2) end
	local roll = math.random() * totalArea
	local chosen: any = zones[1]
	local acc = 0
	for _, z in zones do
		acc += (z.halfX * 2) * (z.halfZ * 2)
		if roll <= acc then chosen = z; break end
	end

	-- Posição XZ aleatória dentro da zona
	local rx = chosen.cx + math.random() * chosen.halfX * 2 - chosen.halfX
	local rz = chosen.cz + math.random() * chosen.halfZ * 2 - chosen.halfZ

	-- Raycast para encontrar o Y exato do chão nessa posição
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local excl: { Instance } = {}
	for _, obj in CollectionService:GetTagged("Tsunami") do table.insert(excl, obj) end
	params.FilterDescendantsInstances = excl

	local startY = (_cfg.MAP_AREAS and _cfg.MAP_AREAS.main and _cfg.MAP_AREAS.main.spawn.Position.Y or 0) + 300
	local hit    = ws2:Raycast(Vector3.new(rx, startY, rz), Vector3.new(0, -600, 0), params)

	if not spawnZonesLogged then
		spawnZonesLogged = true
		print(string.format("[BrainrotSystem] SPAWN_ZONES ativas: %d zona(s)", #zones))
	end

	if hit and hit.Normal.Y > 0.7 then
		return CFrame.new(rx, hit.Position.Y + 0.5, rz)
	end
	-- Sem hit válido: usa Y do spawn como fallback
	local groundY = _cfg.MAP_AREAS and _cfg.MAP_AREAS.main and _cfg.MAP_AREAS.main.spawn.Position.Y or 0
	return CFrame.new(rx, groundY + 0.5, rz)
end

-- ── Spawn via SPAWN_ZONES do Settings ───────────────────────────────
local function spawnOne()
	local br = pickBrainrot()

	local cf = pickSpawnCF()
	if not cf then
		-- Fallback: sem SPAWN_ZONES — usa brainrot_center/half do Settings
		local area = _cfg.MAP_AREAS and _cfg.MAP_AREAS.main
		local c    = if area and area.brainrot_center ~= nil
			then area.brainrot_center :: CFrame else CFrame.new(0, 0, 0)
		local bh   = if area and area.brainrot_half ~= nil
			then area.brainrot_half :: Vector3 else Vector3.new(80, 0, 80)
		local rx = c.Position.X + (math.random() * bh.X * 2 - bh.X)
		local rz = c.Position.Z + (math.random() * bh.Z * 2 - bh.Z)
		cf = CFrame.new(rx, c.Position.Y + 0.5, rz)
		warn("[BrainrotSystem] SPAWN_ZONES não configuradas — usando brainrot_center")
	end

	print(string.format("[LOG:Spawn] %s → (%.0f, %.0f, %.0f)",
		br.id, cf.Position.X, cf.Position.Y, cf.Position.Z))
	local model, touch = makeBrainrot(br, cf)
	table.insert(active, model)

	local idVal = Instance.new("StringValue")
	idVal.Name = "BrainrotId"
	idVal.Value = br.id
	idVal.Parent = model

	-- ProximityPrompt: tecla E para carregar
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Collect"
	pp.ObjectText = br.name
	pp.KeyboardKeyCode = Enum.KeyCode.E
	pp.MaxActivationDistance = 8
	pp.HoldDuration = 0
	pp.Parent = touch

	pp.Triggered:Connect(function(pl: Player)
		print(string.format("[LOG:Collect] %s tentou coletar %s", pl.Name, br.id))
		local PD = require(script.Parent.PlayerData)
		local d = PD.get(pl)
		if not d then
			warn("[LOG:Collect] BLOQUEADO — PlayerData nil para " .. pl.Name)
			return
		end
		if carrying[pl] then
			print("[LOG:Collect] BLOQUEADO — já está carregando outro brainrot")
			return
		end
		-- Limite verificado só no store (pedestal), não aqui.
		pp:Destroy()
		for i, m2 in active do
			if m2 == model then
				table.remove(active, i)
				break
			end
		end
		local char = pl.Character
		local hrp  = char and char:FindFirstChild("HumanoidRootPart")
		if not char or not hrp then
			warn("[LOG:Collect] BLOQUEADO — personagem/HRP não encontrado")
			return
		end
		attachToPlayer(pl, model, touch)
		print(string.format("[LOG:Collect] OK — %s agora carrega '%s'", pl.Name, br.id))
	end)
end

function BrainrotSystem.init(cfg: any)
	_cfg = cfg
	if not cfg.BRAINROTS or not cfg.BRAINROT_ZONE then
		warn("[BrainrotSystem] Settings.BRAINROTS/BRAINROT_ZONE ausente — desativado.")
		return
	end
	local R = require(RS.Shared.Remotes)

	sellRemote = Instance.new("RemoteEvent")
	sellRemote.Name = R.SellBrainrot
	sellRemote.Parent = RS

	fuseRemote = Instance.new("RemoteEvent")
	fuseRemote.Name = R.FuseBrainrots
	fuseRemote.Parent = RS

	fuseResult = Instance.new("RemoteEvent")
	fuseResult.Name = R.FuseResult
	fuseResult.Parent = RS

	local showFusionPanel = Instance.new("RemoteEvent")
	showFusionPanel.Name = R.ShowFusionPanel
	showFusionPanel.Parent = RS

	sellRemote.OnServerEvent:Connect(function(pl, id: string)
		local PD = require(script.Parent.PlayerData)
		if not PD.removeBrainrot(pl, id) then
			return
		end
		for _, br in cfg.BRAINROTS do
			if br.id == id then
				local d = PD.get(pl)
				if d then
					PD.addMoney(pl, br.income * 10)
					d.brainrotsSold += 1
					PD.sync(pl)
				end
				break
			end
		end
	end)

	fuseRemote.OnServerEvent:Connect(function(pl, id1: string, id2: string)
		local PD = require(script.Parent.PlayerData)
		if not PD.removeBrainrot(pl, id1) then
			return
		end
		if not PD.removeBrainrot(pl, id2) then
			PD.addBrainrot(pl, id1)
			return
		end
		local r1 = 1
		for _, br in cfg.BRAINROTS do
			if br.id == id1 then
				r1 = br.rarity
				break
			end
		end
		local target = math.min(r1 + 1, #cfg.RARITIES)
		local cands: { any } = {}
		for _, br in cfg.BRAINROTS do
			if br.rarity == target then
				table.insert(cands, br)
			end
		end
		local result = cands[math.random(1, math.max(1, #cands))]
		if result then
			PD.addBrainrot(pl, result.id)
			local d = PD.get(pl)
			if d then
				d.brainrotsFused += 1
				PD.sync(pl)
			end
			fuseResult:FireClient(pl, true, "Got: " .. result.name)
		else
			PD.addBrainrot(pl, id1)
			fuseResult:FireClient(pl, false, "No result available.")
		end
	end)

	-- FusionMachine ProximityPrompt — abre a UI de seleção no cliente.
	-- A fusão em si acontece via fuseRemote (FuseBrainrots) quando o jogador confirma na UI.
	local function setupFuseMachine(obj: BasePart)
		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Open"
		prompt.ObjectText = "Fusion Machine"
		prompt.HoldDuration = 0
		prompt.MaxActivationDistance = 8
		prompt.Parent = obj
		prompt.Triggered:Connect(function(pl: Player)
			showFusionPanel:FireClient(pl)
		end)
	end

	task.delay(3, function()
		for _, obj in CollectionService:GetTagged("FuseMachine") do
			if obj:IsA("BasePart") then setupFuseMachine(obj :: BasePart) end
		end
		CollectionService:GetInstanceAddedSignal("FuseMachine"):Connect(function(obj)
			if obj:IsA("BasePart") then setupFuseMachine(obj :: BasePart) end
		end)
	end)

	-- Limpeza: ao sair ou morrer, destrói brainrot carregado
	Players.PlayerRemoving:Connect(function(pl)
		local m = carrying[pl]
		if m then
			m:Destroy()
		end
		carrying[pl] = nil :: any
	end)
	Players.PlayerAdded:Connect(function(pl)
		pl.CharacterAdded:Connect(function()
			local m = carrying[pl]
			if m then
				m:Destroy()
				carrying[pl] = nil :: any
			end
		end)
	end)

	-- Store via pedestal: BaseSystem gerencia ProximityPrompt "Store" em cada pedestal.
	-- dropCarried() é chamado por BaseSystem quando o jogador armazena no pedestal.

	-- Spawn inicial
	for _ = 1, 6 do
		spawnOne()
	end

	-- Respawn loop
	task.spawn(function()
		while true do
			task.wait(cfg.BRAINROT_ZONE.RATE)
			for i = #active, 1, -1 do
				if not active[i] or not active[i].Parent then
					table.remove(active, i)
				end
			end
			if #active < cfg.BRAINROT_ZONE.MAX then
				spawnOne()
			end
		end
	end)
end

return BrainrotSystem
