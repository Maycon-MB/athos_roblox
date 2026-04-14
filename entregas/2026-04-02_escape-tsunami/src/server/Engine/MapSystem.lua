--!strict
-- MapSystem — Gerencia 3 áreas (main/shop/base) e teleporte entre elas.
-- Cria chão placeholder + objetos interativos por área.
-- Lado: Server | Dependências: Settings, Remotes, PlayerData
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local MapSystem = {}

local _cfg: any
local teleportRemote: RemoteEvent

-- ── Cria chão e paredes de uma área ─────────────────────────────────
local function buildArea(name: string, area: any)
	local folder = Instance.new("Folder")
	folder.Name = "Area_" .. name
	folder.Parent = ws

	-- Chão — cor diferente por área
	local floorColor = if name == "base"
		then Color3.fromRGB(210, 100, 180)   -- rosa/roxo como no print da base
		elseif name == "main"
		then Color3.fromRGB(80, 80, 90)
		else Color3.fromRGB(200, 170, 100)   -- areia (shop usa chão próprio)
	local floor = Instance.new("Part")
	floor.Name = "Floor_" .. name
	floor.Size = Vector3.new(area.size.X, 2, area.size.Z)
	floor.CFrame = area.spawn * CFrame.new(0, -2, 0)
	floor.Anchored = true
	floor.CanCollide = true
	floor.Color = floorColor
	floor.Material = Enum.Material.SmoothPlastic
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = folder

	-- 4 Paredes invisíveis (barreira)
	local wallH = area.size.Y
	local halfX = area.size.X / 2
	local halfZ = area.size.Z / 2
	local baseY = area.spawn.Position.Y + wallH / 2
	local cx = area.spawn.Position.X
	local cz = area.spawn.Position.Z

	local walls = {
		{ CFrame.new(cx, baseY, cz - halfZ), Vector3.new(area.size.X, wallH, 2) },
		{ CFrame.new(cx, baseY, cz + halfZ), Vector3.new(area.size.X, wallH, 2) },
		{ CFrame.new(cx - halfX, baseY, cz), Vector3.new(2, wallH, area.size.Z) },
		{ CFrame.new(cx + halfX, baseY, cz), Vector3.new(2, wallH, area.size.Z) },
	}
	for i, w in walls do
		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i
		wall.Size = w[2] :: Vector3
		wall.CFrame = w[1] :: CFrame
		wall.Anchored = true
		wall.CanCollide = true
		wall.Transparency = 1
		wall.Parent = folder
	end

	return folder
end

-- ── Cria objetos interativos na área main ───────────────────────────
local function setupMainArea(area: any, folder: Instance)
	local cx = area.spawn.Position.X
	local cz = area.spawn.Position.Z
	local floorY = area.spawn.Position.Y

	-- WaveMachine (para WaveMachinePanel funcionar)
	local machine = Instance.new("Part")
	machine.Name = "WaveMachine"
	machine.Size = Vector3.new(4, 6, 4)
	machine.BrickColor = BrickColor.new("Dark stone grey")
	machine.Material = Enum.Material.SmoothPlastic
	machine.Anchored = true
	machine.Position = Vector3.new(cx + 30, floorY + 3, cz)
	machine.Parent = folder
	CollectionService:AddTag(machine, "WaveMachine")

	-- FusionMachine
	local fuse = Instance.new("Part")
	fuse.Name = "FusionMachine"
	fuse.Size = Vector3.new(4, 6, 4)
	fuse.BrickColor = BrickColor.new("Bright violet")
	fuse.Material = Enum.Material.SmoothPlastic
	fuse.Anchored = true
	fuse.Position = Vector3.new(cx - 30, floorY + 3, cz)
	fuse.Parent = folder
	CollectionService:AddTag(fuse, "FuseMachine")
end

-- ── Constrói sala da loja — visual "Youtuber Jump Shop" (tijolo marrom) ─
local function setupShopArea(area: any, folder: Instance)
	local cx    = area.spawn.Position.X
	local cz    = area.spawn.Position.Z
	local baseY = area.spawn.Position.Y
	local halfX = area.size.X / 2
	local halfZ = area.size.Z / 2
	local wallH = area.size.Y
	local midY  = baseY + wallH / 2
	local topY  = baseY + wallH

	local BRICK  = Color3.fromRGB(174, 99, 0)   -- tijolo laranja/marrom
	local ROOF   = Color3.fromRGB(140, 60, 0)
	local FLOOR  = Color3.fromRGB(200, 170, 100) -- chão areia
	local RED    = Color3.fromRGB(255, 0, 0)
	local WHITE  = Color3.fromRGB(255, 255, 255)
	local MAT    = Enum.Material.SmoothPlastic
	local BRICK_MAT = Enum.Material.Brick

	local function part(name: string, size: Vector3, cf: CFrame,
		color: Color3, mat: Enum.Material, transparency: number?, collide: boolean?): Part
		local p = Instance.new("Part")
		p.Name        = name
		p.Size        = size
		p.CFrame      = cf
		p.Anchored    = true
		p.CanCollide  = if collide == false then false else true
		p.Color       = color
		p.Material    = mat
		p.Transparency = transparency or 0
		p.TopSurface  = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent      = folder
		return p
	end

	local function surfaceLabel(parent: BasePart, text: string, face: Enum.NormalId,
		bg: Color3, fg: Color3)
		local sg = Instance.new("SurfaceGui")
		sg.Face   = face
		sg.Parent = parent
		local lbl = Instance.new("TextLabel")
		lbl.Size                   = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundColor3       = bg
		lbl.BackgroundTransparency = 0
		lbl.Font                   = Enum.Font.GothamBold
		lbl.TextScaled             = true
		lbl.TextColor3             = fg
		lbl.Text                   = text
		lbl.Parent                 = sg
	end

	-- Plaquinha YouTube: Part vermelho pequeno com ▶ branco, pregado sobre a parede
	local function ytBadge(cf: CFrame)
		local badge = Instance.new("Part")
		badge.Name          = "YTBadge"
		badge.Size          = Vector3.new(3, 2, 0.15)
		badge.CFrame        = cf
		badge.Anchored      = true
		badge.CanCollide    = false
		badge.Color         = RED
		badge.Material      = MAT
		badge.TopSurface    = Enum.SurfaceType.Smooth
		badge.BottomSurface = Enum.SurfaceType.Smooth
		badge.Parent        = folder
		local sg  = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = badge
		local lbl = Instance.new("TextLabel")
		lbl.Size                   = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundColor3       = RED
		lbl.BackgroundTransparency = 0
		lbl.Font                   = Enum.Font.GothamBold
		lbl.TextScaled             = true
		lbl.TextColor3             = WHITE
		lbl.Text                   = "▶"
		lbl.Parent                 = sg
	end

	-- Chão
	part("ShopFloor", Vector3.new(area.size.X, 1, area.size.Z),
		CFrame.new(cx, baseY - 1.5, cz), FLOOR, MAT)

	-- Teto
	part("ShopCeiling", Vector3.new(area.size.X + 2, 2, area.size.Z + 2),
		CFrame.new(cx, topY + 1, cz), ROOF, BRICK_MAT)

	-- Paredes laterais (tijolo)
	part("WallLeft",  Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx - halfX, midY, cz), BRICK, BRICK_MAT)
	part("WallRight", Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx + halfX, midY, cz), BRICK, BRICK_MAT)

	-- Parede traseira — tijolo marrom, sem cor sobre a face
	part("WallBack", Vector3.new(area.size.X, wallH, 2),
		CFrame.new(cx, midY, cz + halfZ), BRICK, BRICK_MAT)

	-- Logos YouTube: plaquinhas vermelhas (3×2 studs) presas sobre as paredes
	-- Parede traseira: 5 badges, face aponta -Z (em direção à entrada)
	local backZ = cz + halfZ - 0.1
	ytBadge(CFrame.new(cx,      baseY + 4, backZ))
	ytBadge(CFrame.new(cx - 9,  baseY + 4, backZ))
	ytBadge(CFrame.new(cx + 9,  baseY + 4, backZ))
	ytBadge(CFrame.new(cx - 4,  baseY + 8, backZ))
	ytBadge(CFrame.new(cx + 4,  baseY + 8, backZ))

	-- Paredes laterais: badge face aponta para o interior
	-- Esq (cx-halfX): face aponta +X → rotação Y -90°
	local rotE = CFrame.Angles(0, math.rad(-90), 0)
	-- Dir (cx+halfX): face aponta -X → rotação Y +90°
	local rotD = CFrame.Angles(0, math.rad( 90), 0)
	ytBadge(CFrame.new(cx - halfX + 0.1, baseY + 4, cz - 6) * rotE)
	ytBadge(CFrame.new(cx - halfX + 0.1, baseY + 4, cz + 6) * rotE)
	ytBadge(CFrame.new(cx + halfX - 0.1, baseY + 4, cz - 6) * rotD)
	ytBadge(CFrame.new(cx + halfX - 0.1, baseY + 4, cz + 6) * rotD)

	-- Parede frontal com abertura larga (entrada da loja) — 8 studs
	local crackW = 8
	local crackH = 8
	local sideW  = (halfX - crackW / 2)

	part("WallFront_L",
		Vector3.new(sideW, wallH, 2),
		CFrame.new(cx - crackW/2 - sideW/2, midY, cz - halfZ),
		BRICK, BRICK_MAT)
	part("WallFront_R",
		Vector3.new(sideW, wallH, 2),
		CFrame.new(cx + crackW/2 + sideW/2, midY, cz - halfZ),
		BRICK, BRICK_MAT)
	part("WallFront_Top",
		Vector3.new(crackW, wallH - crackH, 2),
		CFrame.new(cx, baseY + crackH + (wallH - crackH)/2, cz - halfZ),
		BRICK, BRICK_MAT)

	-- Placa "Youtuber Jump Shop" acima da entrada
	local sign = part("ShopSign",
		Vector3.new(crackW + 4, 3, 1),
		CFrame.new(cx, baseY + crackH + 2, cz - halfZ - 0.5),
		RED, MAT)
	surfaceLabel(sign, "Youtuber Jump Shop", Enum.NormalId.Front, RED, WHITE)

	-- Dois monitores decorativos nas laterais do sign (como no print)
	for _, side in { -1, 1 } do
		local mon = part("Monitor_" .. side,
			Vector3.new(2.5, 2.5, 0.5),
			CFrame.new(cx + side * (crackW/2 + 2.5), baseY + crackH + 2, cz - halfZ - 0.5),
			Color3.fromRGB(30, 30, 30), MAT)
		surfaceLabel(mon, "▶", Enum.NormalId.Front,
			Color3.fromRGB(30, 30, 30), RED)
	end

	-- CrackWall trigger (invisível, no fundo da sala)
	local trigger = Instance.new("Part")
	trigger.Name        = "CrackWall"
	trigger.Size        = Vector3.new(area.size.X - 4, wallH - 2, 1)
	trigger.CFrame      = CFrame.new(cx, midY, cz + halfZ - 2)
	trigger.Anchored    = true
	trigger.CanCollide  = false
	trigger.Transparency = 1
	trigger.Parent      = folder
	CollectionService:AddTag(trigger, "CrackWall")

	print("[MapSystem] Loja construída: Youtuber Jump Shop (tijolo + logos YouTube)")
end

-- ── Teleporte ───────────────────────────────────────────────────────
function MapSystem.teleportTo(player: Player, areaName: string)
	local areas = _cfg.MAP_AREAS
	if not areas then
		return
	end
	local area = areas[areaName]
	if not area then
		warn("[MapSystem] Área desconhecida: " .. tostring(areaName))
		return
	end
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	hrp.CFrame = area.spawn * CFrame.new(0, 5, 0) -- +5 studs acima do spawn para não spawnar dentro do chão
	teleportRemote:FireClient(player, areaName, area.label)
	print(string.format("[MapSystem] %s teleportado para '%s'", player.Name, areaName))
end

function MapSystem.getAreaCFrame(areaName: string): CFrame?
	local areas = _cfg.MAP_AREAS
	if not areas then
		return nil
	end
	local area = areas[areaName]
	if not area then
		return nil
	end
	return area.spawn
end

function MapSystem.getAreaBounds(areaName: string): (Vector3?, Vector3?)
	local areas = _cfg.MAP_AREAS
	if not areas then
		return nil, nil
	end
	local area = areas[areaName]
	if not area then
		return nil, nil
	end
	return area.spawn.Position, area.size
end

function MapSystem.init(cfg: any)
	_cfg = cfg
	local R = require(RS.Shared.Remotes)

	teleportRemote = Instance.new("RemoteEvent")
	teleportRemote.Name = R.TeleportArea
	teleportRemote.Parent = RS

	-- Cria as 3 áreas
	local areas = cfg.MAP_AREAS
	if not areas then
		warn("[MapSystem] Settings.MAP_AREAS ausente — MapSystem desativado.")
		return
	end

	for name, area in areas do
		local folder = buildArea(name, area)
		if name == "main" then
			setupMainArea(area, folder)
		elseif name == "shop" then
			setupShopArea(area, folder)
		end
	end

	-- SpawnLocation na área main
	local mainArea = areas.main
	if mainArea then
		local sl = Instance.new("SpawnLocation")
		sl.Size = Vector3.new(6, 1, 6)
		sl.CFrame = mainArea.spawn
		sl.Anchored = true
		sl.Transparency = 1
		sl.CanCollide = true
		sl.Neutral = true
		sl.Parent = ws
		print(
			string.format(
				"[MapSystem] SpawnLocation criada em (%.0f, %.0f, %.0f)",
				mainArea.spawn.Position.X,
				mainArea.spawn.Position.Y,
				mainArea.spawn.Position.Z
			)
		)

		Players.PlayerAdded:Connect(function(player)
			player.RespawnLocation = sl
		end)
		for _, player in Players:GetPlayers() do
			player.RespawnLocation = sl
		end
	end

	print("[MapSystem] 3 áreas criadas: main, shop, base")
end

return MapSystem
