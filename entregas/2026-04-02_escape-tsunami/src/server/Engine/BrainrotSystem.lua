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
local carrying: { [Player]: any } = {}
local disabledBrainrots: { [string]: boolean } = {}

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

	-- Tenta clonar modelo real de VFXBrainrots (pelo id ou nome do brainrot)
	local vfxFolder = ws:FindFirstChild("VFXBrainrots")
	local template: Model? = nil
	if vfxFolder then
		template = vfxFolder:FindFirstChild(br.id) :: Model?
			or vfxFolder:FindFirstChild(br.name) :: Model?
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

	local sel = Instance.new("SelectionBox")
	sel.Adornee = body
	sel.Color3 = rar.color
	sel.LineThickness = 0.06
	sel.Parent = m

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

-- ── Spawn dentro de MAP_AREAS.main ──────────────────────────────────
local function spawnOne()
	local br = pickBrainrot()

	-- Bounds da área main
	local area = _cfg.MAP_AREAS and _cfg.MAP_AREAS.main
	local spawnCF = if area then area.spawn else CFrame.new(0, 10, 0)
	local areaSize = if area then area.size else Vector3.new(200, 50, 200)

	local cx = spawnCF.Position.X
	local cz = spawnCF.Position.Z
	local halfX = areaSize.X / 2 - 10
	local halfZ = areaSize.Z / 2 - 10

	local rx = cx + math.random(-math.floor(halfX), math.floor(halfX))
	local rz = cz + math.random(-math.floor(halfZ), math.floor(halfZ))

	-- Raycast para encontrar o chão
	local ws = game:GetService("Workspace")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = {}
	for _, obj in CollectionService:GetTagged("Tsunami") do
		table.insert(exclude, obj)
	end
	params.FilterDescendantsInstances = exclude
	local hit = ws:Raycast(Vector3.new(rx, 500, rz), Vector3.new(0, -2000, 0), params)
	local spawnY = if hit then hit.Position.Y + 2 else spawnCF.Position.Y + 2

	local cf = CFrame.new(rx, spawnY, rz)
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
		local PD = require(script.Parent.PlayerData)
		local d = PD.get(pl)
		if not d then
			return
		end
		if carrying[pl] then
			return
		end
		if PD.countBrainrots(pl) >= d.baseSlots then
			return
		end
		pp:Destroy()
		for i, m2 in active do
			if m2 == model then
				table.remove(active, i)
				break
			end
		end
		attachToPlayer(pl, model, touch)
		print(string.format("[BrainrotSystem] %s coletou %s (%s)", pl.Name, br.name, br.id))
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
			fuseResult:FireClient(pl, true, "Obteve: " .. result.name)
		else
			PD.addBrainrot(pl, id1)
			fuseResult:FireClient(pl, false, "Nenhum resultado disponivel.")
		end
	end)

	-- FusionMachine ProximityPrompt (conecta ao Part criado pelo MapSystem)
	task.delay(3, function()
		for _, obj in CollectionService:GetTagged("FuseMachine") do
			if not obj:IsA("BasePart") then
				continue
			end
			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Fuse"
			prompt.ObjectText = "Fusion Machine"
			prompt.HoldDuration = 1.5
			prompt.MaxActivationDistance = 8
			prompt.Parent = obj

			prompt.Triggered:Connect(function(pl: Player)
				local PD = require(script.Parent.PlayerData)
				local d = PD.get(pl)
				if not d or #d.brainrots < 2 then
					fuseResult:FireClient(pl, false, "Precisa de 2 Brainrots!")
					return
				end
				local id1 = d.brainrots[1].id
				local id2 = d.brainrots[2].id
				local r1 = 1
				for _, br in cfg.BRAINROTS do
					if br.id == id1 then
						r1 = br.rarity
						break
					end
				end
				PD.removeBrainrot(pl, id1)
				PD.removeBrainrot(pl, id2)
				local target = math.min(r1 + 1, #cfg.RARITIES)
				local cands: { any } = {}
				for _, br in cfg.BRAINROTS do
					if br.rarity == target then
						table.insert(cands, br)
					end
				end
				local result = if #cands > 0 then cands[math.random(1, #cands)] else nil
				if result then
					PD.addBrainrot(pl, result.id)
					d.brainrotsFused += 1
					PD.sync(pl)
					fuseResult:FireClient(pl, true, "Obteve: " .. result.name)
				else
					PD.addBrainrot(pl, id1)
					PD.sync(pl)
					fuseResult:FireClient(pl, false, "Nenhum resultado disponivel.")
				end
			end)
		end
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

	-- SafeZone delivery: ao tocar SafeZone carregando → credita no inventário
	task.spawn(function()
		task.wait(3)
		local function connectSafeZone(part: Instance)
			if not part:IsA("BasePart") then
				return
			end
			local inZone: { [Player]: boolean } = {}
			(part :: BasePart).Touched:Connect(function(hit)
				local char = hit.Parent
				if not char then
					return
				end
				local pl = Players:GetPlayerFromCharacter(char)
				if not pl then
					return
				end
				if inZone[pl] then
					return
				end
				local m = carrying[pl]
				if not m then
					return
				end
				inZone[pl] = true
				local idVal = m:FindFirstChild("BrainrotId") :: StringValue?
				if idVal then
					local PD = require(script.Parent.PlayerData)
					local d = PD.get(pl)
					if d and PD.countBrainrots(pl) < d.baseSlots then
						PD.addBrainrot(pl, idVal.Value)
						print(string.format("[BrainrotSystem] %s entregou %s na SafeZone", pl.Name, idVal.Value))
					end
				end
				m:Destroy()
				carrying[pl] = nil :: any
				task.delay(1, function()
					inZone[pl] = nil
				end)
			end)
		end
		for _, p in CollectionService:GetTagged("SafeZone") do
			connectSafeZone(p)
		end
		CollectionService:GetInstanceAddedSignal("SafeZone"):Connect(connectSafeZone)
	end)

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
