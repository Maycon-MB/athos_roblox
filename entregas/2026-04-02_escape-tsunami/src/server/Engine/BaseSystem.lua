--!strict
-- BaseSystem — Pedestais 3D na área base.
-- Cria slots físicos e atualiza BillboardGui com o inventário do jogador.
local Players = game:GetService("Players")
local BaseSystem = {}

local _cfg: any
local pedestals: { BasePart } = {}

-- Cria plataforma circular (slot de brainrot) — visual idêntico ao jogo original
local function makePedestal(pos: Vector3, idx: number): BasePart
	-- Disco circular plano azul/teal (Cylinder deitado: Size.X = espessura, Y/Z = diâmetro)
	local base = Instance.new("Part")
	base.Name          = "Pedestal_" .. idx
	base.Shape         = Enum.PartType.Cylinder
	base.Size          = Vector3.new(0.4, 5, 5)   -- 0.4 de espessura, 5 de diâmetro
	base.CFrame        = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)) -- eixo X aponta pra cima → disco flat
	base.Anchored      = true
	base.CanCollide    = true
	base.Material      = Enum.Material.SmoothPlastic
	base.Color         = Color3.fromRGB(0, 180, 200)
	base.TopSurface    = Enum.SurfaceType.Smooth
	base.BottomSurface = Enum.SurfaceType.Smooth
	base.Parent        = workspace

	-- Pad verde quadrado sob o pedestal (como na referência do jogo)
	local pad = Instance.new("Part")
	pad.Name          = "Pad_" .. idx
	pad.Size          = Vector3.new(4.4, 0.3, 4.4)
	pad.CFrame        = CFrame.new(pos + Vector3.new(0, -0.5, 0))
	pad.Anchored      = true
	pad.CanCollide    = false
	pad.Material      = Enum.Material.SmoothPlastic
	pad.Color         = Color3.fromRGB(100, 210, 100)
	pad.TopSurface    = Enum.SurfaceType.Smooth
	pad.BottomSurface = Enum.SurfaceType.Smooth
	pad.Parent        = workspace

	-- Borda neon verde (anel ligeiramente maior)
	local ring = Instance.new("Part")
	ring.Name       = "Ring_" .. idx
	ring.Shape      = Enum.PartType.Cylinder
	ring.Size       = Vector3.new(0.25, 5.8, 5.8)
	ring.CFrame     = CFrame.new(pos + Vector3.new(0, -0.08, 0)) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored   = true
	ring.CanCollide = false
	ring.Material   = Enum.Material.Neon
	ring.Color      = Color3.fromRGB(0, 220, 80)
	ring.Parent     = workspace

	-- BillboardGui com nome do brainrot
	local bb = Instance.new("BillboardGui")
	bb.Name        = "Label"
	bb.Size        = UDim2.new(0, 160, 0, 44)
	bb.StudsOffset = Vector3.new(0, 3.2, 0)
	bb.AlwaysOnTop = false
	bb.Parent      = base

	local lbl = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundColor3       = Color3.fromRGB(18, 16, 28)
	lbl.BackgroundTransparency = 0.1
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextScaled             = true
	lbl.TextColor3             = Color3.fromRGB(160, 160, 160)
	lbl.Text                   = "[ empty ]"
	lbl.Parent                 = bb
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 6); c.Parent = lbl

	return base
end

local function layoutPositions(center: Vector3, count: number): { Vector3 }
	local positions: { Vector3 } = {}
	local cols    = math.max(2, math.ceil(math.sqrt(count)))
	local spacing = 4.5
	for i = 1, count do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols
		local x   = center.X + (col - (cols - 1) / 2) * spacing
		local z   = center.Z + (row - math.floor((count - 1) / cols) / 2) * spacing
		table.insert(positions, Vector3.new(x, center.Y, z))
	end
	return positions
end

-- Atualiza os BillboardGuis com o inventário atual do jogador.
function BaseSystem.update(player: Player)
	local PD = require(script.Parent.PlayerData)
	local d  = PD.get(player)
	if not d then return end

	-- brainrots é array: { {id: string, qty: number} }
	local brainrots: { { id: string, qty: number } } = d.brainrots or {}

	-- Montar lista plana ordenada (mais raro primeiro)
	local list: { { id: string, qty: number, rarity: number } } = {}
	for _, entry in brainrots do
		if entry.qty > 0 then
			local rarity = 1
			for _, br in _cfg.BRAINROTS do
				if br.id == entry.id then rarity = br.rarity; break end
			end
			table.insert(list, { id = entry.id, qty = entry.qty, rarity = rarity })
		end
	end
	table.sort(list, function(a, b) return a.rarity > b.rarity end)

	for i, ped in pedestals do
		local bb  = ped:FindFirstChild("Label")
		local lbl = bb and (bb :: BillboardGui):FindFirstChildOfClass("TextLabel")
		if not lbl then continue end

		local entry = list[i]
		if entry then
			local name  = entry.id
			local color = Color3.fromRGB(255, 200, 40)
			for _, br in _cfg.BRAINROTS do
				if br.id == entry.id then
					name  = br.name
					color = br.color
					break
				end
			end
			local lbl2 = lbl :: TextLabel
			lbl2.Text       = (entry.qty > 1 and ("×" .. entry.qty .. " ") or "") .. name
			lbl2.TextColor3 = color
		else
			local lbl2 = lbl :: TextLabel
			lbl2.Text       = "[ empty ]"
			lbl2.TextColor3 = Color3.fromRGB(160, 160, 160)
		end
	end
end

function BaseSystem.init(cfg: any)
	_cfg = cfg

	local area   = cfg.MAP_AREAS.base
	local center = area.spawn.Position
	local slots  = cfg.BASE.SLOTS_DEFAULT

	local positions = layoutPositions(Vector3.new(center.X, center.Y - 1, center.Z), slots)
	for i, pos in positions do
		table.insert(pedestals, makePedestal(pos, i))
	end

	-- Refresh a cada 2s (solo recording: 1 jogador)
	task.spawn(function()
		while true do
			task.wait(2)
			for _, pl in Players:GetPlayers() do
				BaseSystem.update(pl)
			end
		end
	end)

	print(string.format("[BaseSystem] %d pedestais criados em MAP_AREAS.base", slots))
end

return BaseSystem
