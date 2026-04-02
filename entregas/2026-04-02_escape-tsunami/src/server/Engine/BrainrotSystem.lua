--!strict
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local BrainrotSystem = {}

local _cfg:   any
local active: { Model } = {}
local sellRemote: RemoteEvent
local fuseRemote: RemoteEvent

-- Helpers ─────────────────────────────────────────────────────────────
local function pt(parent: Instance, sz: Vector3, cf: CFrame, col: Color3): Part
	local p           = Instance.new("Part")
	p.Size            = sz;  p.CFrame      = cf;  p.Color      = col
	p.Anchored        = true; p.CanCollide  = false
	p.TopSurface      = Enum.SurfaceType.Smooth
	p.BottomSurface   = Enum.SurfaceType.Smooth
	p.CastShadow      = false; p.Parent = parent
	return p
end

local function textLabel(parent: Instance, txt: string, col: Color3,
                          sz: UDim2, pos: UDim2?): TextLabel
	local l = Instance.new("TextLabel")
	l.Size  = sz; l.Position = pos or UDim2.new(0,0,0,0)
	l.BackgroundTransparency = 1
	l.Font  = Enum.Font.GothamBold; l.TextScaled = true
	l.TextColor3 = col; l.TextStrokeTransparency = 0
	l.Text  = txt; l.Parent = parent
	return l
end

local function makeBrainrot(br: any, origin: CFrame): (Model, BasePart)
	local ws  = game:GetService("Workspace")
	local m   = Instance.new("Model")
	m.Name    = "BR_" .. br.id
	m.Parent  = ws

	local rar = _cfg.RARITIES[br.rarity] or _cfg.RARITIES[1]

	-- Body + head
	local body = pt(m, Vector3.new(2.5, 3, 1.5), origin * CFrame.new(0, 1.5, 0), br.color)
	body.Name  = "Body"
	local head = pt(m, Vector3.new(2.5, 2.5, 2.5), origin * CFrame.new(0, 4.25, 0),
	                Color3.fromRGB(255, 213, 170))
	head.Name  = "Head"
	-- Arms
	pt(m, Vector3.new(0.9, 2.5, 0.9), origin * CFrame.new(-1.8, 1.5, 0), br.color)
	pt(m, Vector3.new(0.9, 2.5, 0.9), origin * CFrame.new( 1.8, 1.5, 0), br.color)
	-- Legs
	pt(m, Vector3.new(1.1, 2.5, 1.1), origin * CFrame.new(-0.7, -1.1, 0), Color3.fromRGB(50,50,100))
	pt(m, Vector3.new(1.1, 2.5, 1.1), origin * CFrame.new( 0.7, -1.1, 0), Color3.fromRGB(50,50,100))

	-- Face billboard (on head front face)
	local faceBB = Instance.new("BillboardGui")
	faceBB.Size  = UDim2.new(0, 70, 0, 50)
	faceBB.StudsOffset = Vector3.new(0, 0, head.Size.Z / 2 + 0.1)
	faceBB.Parent = head
	textLabel(faceBB, "• •", Color3.fromRGB(40,30,20), UDim2.new(1,0,0.5,0), UDim2.new(0,0,0.05,0))
	textLabel(faceBB, "‿",   Color3.fromRGB(40,30,20), UDim2.new(1,0,0.4,0), UDim2.new(0,0,0.58,0))

	-- Name / rarity / income tag (floating above)
	local tagBB = Instance.new("BillboardGui")
	tagBB.Size  = UDim2.new(0, 160, 0, 54)
	tagBB.StudsOffset = Vector3.new(0, 4.5, 0)
	tagBB.Parent = body
	textLabel(tagBB, br.name,   Color3.new(1,1,1),    UDim2.new(1,0,0.48,0))
	textLabel(tagBB, rar.name,  rar.color,             UDim2.new(1,0,0.28,0), UDim2.new(0,0,0.48,0))
	textLabel(tagBB, "$"..tostring(br.income).."/s",
	          Color3.fromRGB(255,220,60), UDim2.new(1,0,0.24,0), UDim2.new(0,0,0.76,0))

	-- Rarity outline
	local sel = Instance.new("SelectionBox")
	sel.Adornee = body; sel.Color3 = rar.color
	sel.LineThickness = 0.06; sel.Parent = m

	-- Float animation
	task.spawn(function()
		local t    = math.random() * math.pi * 2
		local parts: { BasePart } = {}
		local baseY: { number }   = {}
		for _, obj in m:GetDescendants() do
			if obj:IsA("BasePart") then
				table.insert(parts, obj)
				table.insert(baseY, obj.Position.Y)
			end
		end
		while m.Parent do
			t += task.wait(0.03)
			local dy = math.sin(t) * 0.3
			for i, p2 in parts do
				p2.CFrame = CFrame.new(p2.Position.X, baseY[i] + dy, p2.Position.Z)
			end
		end
	end)

	m.PrimaryPart = body
	return m, body
end

local function pickBrainrot(): any
	local w = _cfg.SPAWN_WEIGHTS
	local total = 0
	for _, br in _cfg.BRAINROTS do total += w[br.rarity] or 0 end
	local roll = math.random() * total; local acc = 0
	for _, br in _cfg.BRAINROTS do
		acc += w[br.rarity] or 0
		if roll <= acc then return br end
	end
	return _cfg.BRAINROTS[1]
end

local function spawnOne()
	local z  = _cfg.BRAINROT_ZONE
	local br = pickBrainrot()
	local cf = CFrame.new(
		math.random(-z.X_RANGE, z.X_RANGE),
		z.Y,
		math.random(z.Z_MIN, z.Z_MAX)
	)
	local model, touch = makeBrainrot(br, cf)
	table.insert(active, model)

	local idVal       = Instance.new("StringValue")
	idVal.Name        = "BrainrotId"
	idVal.Value       = br.id
	idVal.Parent      = model

	touch.Touched:Connect(function(hit)
		local char = hit.Parent; if not char then return end
		local pl   = Players:GetPlayerFromCharacter(char); if not pl then return end
		local PD   = require(script.Parent.PlayerData)
		local d    = PD.get(pl); if not d then return end
		if PD.countBrainrots(pl) >= d.baseSlots then return end
		model:Destroy()
		for i, m2 in active do
			if m2 == model then table.remove(active, i); break end
		end
		PD.addBrainrot(pl, br.id)
	end)
end

function BrainrotSystem.init(cfg: any)
	_cfg = cfg
	if not cfg.BRAINROTS or not cfg.BRAINROT_ZONE then
		warn("[BrainrotSystem] Settings.BRAINROTS/BRAINROT_ZONE ausente — brainrots desativados. Preencha Settings.lua.")
		return
	end
	local R = require(RS.Shared.Remotes)

	sellRemote        = Instance.new("RemoteEvent")
	sellRemote.Name   = R.SellBrainrot
	sellRemote.Parent = RS

	fuseRemote        = Instance.new("RemoteEvent")
	fuseRemote.Name   = R.FuseBrainrots
	fuseRemote.Parent = RS

	sellRemote.OnServerEvent:Connect(function(pl, id: string)
		local PD = require(script.Parent.PlayerData)
		if not PD.removeBrainrot(pl, id) then return end
		for _, br in cfg.BRAINROTS do
			if br.id == id then
				local d = PD.get(pl)
				if d then
					PD.addMoney(pl, br.income * 10)
					d.brainrotsSold += 1; PD.sync(pl)
				end
				break
			end
		end
	end)

	fuseRemote.OnServerEvent:Connect(function(pl, id1: string, id2: string)
		local PD = require(script.Parent.PlayerData)
		if not PD.removeBrainrot(pl, id1) then return end
		if not PD.removeBrainrot(pl, id2) then PD.addBrainrot(pl, id1); return end
		local r1 = 1
		for _, br in cfg.BRAINROTS do if br.id == id1 then r1 = br.rarity; break end end
		local target = math.min(r1 + 1, #cfg.RARITIES)
		local cands: { any } = {}
		for _, br in cfg.BRAINROTS do
			if br.rarity == target then table.insert(cands, br) end
		end
		local result = cands[math.random(1, math.max(1, #cands))]
		if result then
			PD.addBrainrot(pl, result.id)
			local d = PD.get(pl)
			if d then d.brainrotsFused += 1; PD.sync(pl) end
		end
	end)

	for _ = 1, 6 do spawnOne() end

	task.spawn(function()
		while true do
			task.wait(cfg.BRAINROT_ZONE.RATE)
			for i = #active, 1, -1 do
				if not active[i] or not active[i].Parent then
					table.remove(active, i)
				end
			end
			if #active < cfg.BRAINROT_ZONE.MAX then spawnOne() end
		end
	end)
end

return BrainrotSystem
