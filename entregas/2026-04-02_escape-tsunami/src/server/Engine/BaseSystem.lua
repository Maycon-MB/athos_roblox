--!strict
-- BaseSystem — Pedestais 3D da base + mechanic de store.
-- Pedestais = modelos "base escape tsunami" como filhos diretos do Workspace.
-- Cada pedestal tem Parts "Slot1", "Slot2"... onde os brainrots são colocados.
local Players = game:GetService("Players")
local BaseSystem = {}

local _cfg: any

type Slot = {
	part:       BasePart,   -- BasePart que recebe o ProximityPrompt
	displayCF:  CFrame,     -- posição onde o modelo 3D flutua (pivot do slot)
	prompt:     ProximityPrompt?,
	model:      Model?,
	brainrotId: string?,
}

local slots: { Slot } = {}

-- ── Limpa artefatos de runs anteriores ──────────────────────────────
local function cleanLegacy()
	local ws = game:GetService("Workspace")
	for _, child in ws:GetChildren() do
		local n = child.Name
		if n:match("^BRDisplay_") or n:match("^StoreTrigger") then
			child:Destroy()
		end
	end
end

-- ── Coleta Slot1, Slot2... dentro dos pedestais ─────────────────────
-- Suporta tanto BasePart quanto Model como tipo do slot.
-- Se slot é Model: usa seu pivot p/ display e sua primeira BasePart p/ o prompt.
local function findSlots()
	local ws = game:GetService("Workspace")
	local pedestalCount = 0

	for _, child in ws:GetChildren() do
		if child.Name == "base escape tsunami" and child:IsA("Model") then
			pedestalCount += 1
			local i = 1
			while true do
				local found = (child :: Model):FindFirstChild("Slot" .. i, true)
				if not found then break end

				local promptPart: BasePart?
				local displayCF:  CFrame

				if found:IsA("BasePart") then
					promptPart = found :: BasePart
					displayCF  = (found :: BasePart).CFrame

				elseif found:IsA("Model") then
					local sm = found :: Model
					promptPart = sm.PrimaryPart
						or sm:FindFirstChildWhichIsA("BasePart") :: BasePart?
					displayCF  = sm:GetPivot()
				end

				if promptPart then
					table.insert(slots, {
						part       = promptPart :: BasePart,
						displayCF  = displayCF  :: CFrame,
						prompt     = nil,
						model      = nil,
						brainrotId = nil,
					})
				else
					warn(string.format("[LOG:BaseSystem] Slot%d pedestal %d — Model sem BasePart utilizável, ignorado",
						i, pedestalCount))
				end
				i += 1
			end

			local found_here = 0
			for _, s in slots do
				if (child :: Model):IsAncestorOf(s.part) then found_here += 1 end
			end
			print(string.format("[LOG:BaseSystem] Pedestal %d — %d slots carregados", pedestalCount, found_here))
		end
	end

	print(string.format("[LOG:BaseSystem] Total: %d pedestais | %d slots prontos", pedestalCount, #slots))
end

-- ── Exibe modelo 3D flutuando acima do slot ─────────────────────────
local function showModel(slot: Slot, brId: string)
	local old = slot.model
	if old and (old :: Model).Parent then (old :: Model):Destroy() end
	slot.model = nil

	local ws = game:GetService("Workspace")
	local SS  = game:GetService("ServerStorage")

	local brCfg: any = nil
	for _, br in _cfg.BRAINROTS do
		if br.id == brId then brCfg = br; break end
	end

	local modelName: string = if brCfg and brCfg.model_name ~= nil
		then brCfg.model_name :: string
		else (if brCfg then brCfg.name :: string else brId)

	local template = SS:FindFirstChild(modelName)
	if not template then
		-- tenta pelo id também
		template = SS:FindFirstChild(brId)
	end

	local clone: Model
	if template and template:IsA("Model") then
		clone = (template :: Model):Clone()
		print(string.format("[LOG:BaseSystem] Modelo '%s' clonado para slot %s", modelName, slot.part.Name))
	else
		warn(string.format("[LOG:BaseSystem] Modelo '%s' não encontrado no SS — usando esfera fallback", modelName))
		clone = Instance.new("Model")
		local body = Instance.new("Part")
		body.Name       = "Body"
		body.Shape      = Enum.PartType.Ball
		body.Size       = Vector3.new(2.5, 2.5, 2.5)
		body.Anchored   = true
		body.CanCollide = false
		body.Material   = Enum.Material.SmoothPlastic
		body.Color      = (brCfg and brCfg.color) or Color3.new(1, 1, 1)
		body.Parent     = clone
		clone.PrimaryPart = body
	end

	clone.Name = "BRDisplay_" .. brId
	for _, obj in clone:GetDescendants() do
		if obj:IsA("BasePart") then
			(obj :: BasePart).Anchored   = true
			(obj :: BasePart).CanCollide = false
		end
	end

	local extents = clone:GetExtentsSize()
	clone:PivotTo(slot.displayCF * CFrame.new(0, extents.Y / 2 + 1.5, 0))
	clone.Parent = ws
	slot.model   = clone

	-- Animação de flutuação
	task.spawn(function()
		local t     = math.random() * math.pi * 2
		local parts: { BasePart } = {}
		local baseY: { number }   = {}
		for _, obj in clone:GetDescendants() do
			if obj:IsA("BasePart") then
				table.insert(parts, obj)
				table.insert(baseY, obj.Position.Y)
			end
		end
		while clone.Parent do
			t  += task.wait(0.03)
			local dy = math.sin(t) * 0.3
			for i, p in parts do
				if p.Anchored then
					p.CFrame = CFrame.new(p.Position.X, baseY[i] + dy, p.Position.Z)
				end
			end
		end
	end)
end

-- ── ProximityPrompt "Store" no slot vazio ───────────────────────────
local function addStorePrompt(slot: Slot)
	if slot.prompt and slot.prompt.Parent then
		slot.prompt:Destroy()
	end
	slot.prompt = nil

	local pp = Instance.new("ProximityPrompt")
	pp.ActionText            = "Store"
	pp.ObjectText            = "Base Slot"
	pp.KeyboardKeyCode       = Enum.KeyCode.E
	pp.MaxActivationDistance = 10
	pp.HoldDuration          = 0
	pp.Parent                = slot.part

	slot.prompt = pp
	print(string.format("[LOG:BaseSystem] Prompt 'Store' criado em %s", slot.part.Name))

	pp.Triggered:Connect(function(pl: Player)
		print(string.format("[LOG:Store] %s ativou slot %s", pl.Name, slot.part.Name))

		local BS = require(script.Parent.BrainrotSystem)
		if not BS.isCarrying(pl) then
			print("[LOG:Store] BLOQUEADO — jogador não está carregando nada")
			return
		end

		local id = BS.getCarriedId(pl)
		print(string.format("[LOG:Store] ID carregado: '%s'", tostring(id)))
		if not id or id == "" then
			warn("[LOG:Store] BLOQUEADO — id do brainrot carregado é nil/vazio")
			return
		end

		local PD = require(script.Parent.PlayerData)
		local d  = PD.get(pl)
		if not d then
			warn("[LOG:Store] BLOQUEADO — PlayerData nil")
			return
		end

		local count    = PD.countBrainrots(pl)
		local maxSlots = d.baseSlots
		print(string.format("[LOG:Store] inventário: %d/%d slots", count, maxSlots))
		if count >= maxSlots then
			print("[LOG:Store] BLOQUEADO — inventário cheio")
			return
		end

		PD.addBrainrot(pl, id)
		BS.dropCarried(pl)

		slot.brainrotId = id
		pp:Destroy()
		slot.prompt = nil
		showModel(slot, id)
		print(string.format("[LOG:Store] OK — '%s' guardado em %s", id, slot.part.Name))
	end)
end

-- ── Preenche todos os slots com um brainrot (usado pelo fill_base do Pulo Athos) ──
-- Não precisa de carry — preenche direto com modelo + inventário.
function BaseSystem.fillAll(pl: Player, brainrotId: string)
	local PD = require(script.Parent.PlayerData)
	local filled = 0
	for _, slot in slots do
		if slot.brainrotId ~= nil then continue end
		PD.addBrainrot(pl, brainrotId)
		slot.brainrotId = brainrotId
		if slot.prompt and slot.prompt.Parent then
			slot.prompt:Destroy()
			slot.prompt = nil
		end
		showModel(slot, brainrotId)
		filled += 1
	end
	print(string.format("[BaseSystem] fillAll '%s' → %d slots preenchidos para %s",
		brainrotId, filled, pl.Name))
end

-- ── Sincronização: libera slots cujo brainrot saiu do inventário ─────
function BaseSystem.update(player: Player)
	local PD = require(script.Parent.PlayerData)
	local d  = PD.get(player)
	if not d then return end

	for _, slot in slots do
		if slot.brainrotId == nil then continue end
		local stillHas = false
		for _, entry in d.brainrots do
			local e: any = entry
			if e.id == slot.brainrotId and e.qty > 0 then
				stillHas = true; break
			end
		end
		if not stillHas then
			slot.brainrotId = nil
			if slot.model and (slot.model :: Model).Parent then
				(slot.model :: Model):Destroy()
			end
			slot.model = nil
			addStorePrompt(slot)
		end
	end
end

function BaseSystem.init(cfg: any)
	_cfg = cfg
	cleanLegacy()
	findSlots()

	for _, slot in slots do
		addStorePrompt(slot)
	end

	task.spawn(function()
		while true do
			task.wait(2)
			for _, pl in Players:GetPlayers() do
				BaseSystem.update(pl)
			end
		end
	end)
end

return BaseSystem
