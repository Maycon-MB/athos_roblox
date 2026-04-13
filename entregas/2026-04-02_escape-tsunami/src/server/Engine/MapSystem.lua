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

	-- Chão
	local floor = Instance.new("Part")
	floor.Name = "Floor_" .. name
	floor.Size = Vector3.new(area.size.X, 2, area.size.Z)
	floor.CFrame = area.spawn * CFrame.new(0, -2, 0)
	floor.Anchored = true
	floor.CanCollide = true
	floor.Color = Color3.fromRGB(60, 60, 70)
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

-- ── Constrói sala física da loja secreta ────────────────────────────
-- Sala confinada com paredes visíveis, teto, fenda de entrada e neon.
local function setupShopArea(area: any, folder: Instance)
	local cx     = area.spawn.Position.X
	local cz     = area.spawn.Position.Z
	local baseY  = area.spawn.Position.Y  -- nível do chão (Y do spawn)
	local halfX  = area.size.X / 2        -- 30
	local halfZ  = area.size.Z / 2        -- 30
	local wallH  = area.size.Y            -- 30
	local midY   = baseY + wallH / 2      -- centro vertical das paredes
	local topY   = baseY + wallH          -- topo (onde vai o teto)

	local WALL_COLOR  = Color3.fromRGB(35, 32, 42)
	local FLOOR_COLOR = Color3.fromRGB(25, 23, 32)
	local NEON_COLOR  = Color3.fromRGB(255, 30, 30)  -- vermelho YouTube
	local MAT         = Enum.Material.SmoothPlastic
	local NEON_MAT    = Enum.Material.Neon

	local function part(name: string, size: Vector3, cf: CFrame,
		color: Color3, mat: Enum.Material, transparency: number?): Part
		local p = Instance.new("Part")
		p.Name        = name
		p.Size        = size
		p.CFrame      = cf
		p.Anchored    = true
		p.CanCollide  = true
		p.Color       = color
		p.Material    = mat
		p.Transparency = transparency or 0
		p.TopSurface  = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent      = folder
		return p
	end

	-- Chão visível (substitui o placeholder cinza do buildArea)
	part("ShopFloor", Vector3.new(area.size.X, 1, area.size.Z),
		CFrame.new(cx, baseY - 1.5, cz), FLOOR_COLOR, MAT)

	-- Teto
	part("ShopCeiling", Vector3.new(area.size.X + 4, 2, area.size.Z + 4),
		CFrame.new(cx, topY + 1, cz), WALL_COLOR, MAT)

	-- Parede traseira (fundo da sala — onde fica o trigger da loja)
	part("WallBack", Vector3.new(area.size.X, wallH, 2),
		CFrame.new(cx, midY, cz + halfZ), WALL_COLOR, MAT)

	-- Paredes laterais
	part("WallLeft",  Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx - halfX, midY, cz), WALL_COLOR, MAT)
	part("WallRight", Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx + halfX, midY, cz), WALL_COLOR, MAT)

	-- Parede frontal com FENDA (crack) centralizada — 3 studs larga, 6 studs alta
	local crackW  = 3    -- largura da fenda
	local crackH  = 6    -- altura da fenda (passa o personagem)
	local sideW   = halfX - crackW / 2  -- 28.5

	-- Trecho esquerdo
	part("WallFront_L",
		Vector3.new(sideW, wallH, 2),
		CFrame.new(cx - crackW/2 - sideW/2, midY, cz - halfZ),
		WALL_COLOR, MAT)

	-- Trecho direito
	part("WallFront_R",
		Vector3.new(sideW, wallH, 2),
		CFrame.new(cx + crackW/2 + sideW/2, midY, cz - halfZ),
		WALL_COLOR, MAT)

	-- Verga acima da fenda (fecha o topo)
	part("WallFront_Top",
		Vector3.new(crackW, wallH - crackH, 2),
		CFrame.new(cx, baseY + crackH + (wallH - crackH)/2, cz - halfZ),
		WALL_COLOR, MAT)

	-- Borda neon vermelha ao redor da fenda (efeito YouTube)
	local neonThick = 0.3
	-- Lateral esquerda da fenda
	part("CrackNeon_L", Vector3.new(neonThick, crackH, neonThick),
		CFrame.new(cx - crackW/2, baseY + crackH/2, cz - halfZ), NEON_COLOR, NEON_MAT)
	-- Lateral direita
	part("CrackNeon_R", Vector3.new(neonThick, crackH, neonThick),
		CFrame.new(cx + crackW/2, baseY + crackH/2, cz - halfZ), NEON_COLOR, NEON_MAT)
	-- Topo da fenda
	part("CrackNeon_Top", Vector3.new(crackW + neonThick*2, neonThick, neonThick),
		CFrame.new(cx, baseY + crackH, cz - halfZ), NEON_COLOR, NEON_MAT)

	-- Faixas neon nas paredes laterais (atmosfera de sala secreta)
	for side = -1, 1, 2 do
		local x = cx + side * (halfX - 0.2)
		-- Faixa horizontal a meia altura
		part("NeonStrip_Side_" .. side,
			Vector3.new(neonThick, neonThick, area.size.Z - 4),
			CFrame.new(x, baseY + wallH * 0.4, cz), NEON_COLOR, NEON_MAT)
	end
	-- Faixa na parede traseira
	part("NeonStrip_Back",
		Vector3.new(area.size.X - 4, neonThick, neonThick),
		CFrame.new(cx, baseY + wallH * 0.4, cz + halfZ - 0.2), NEON_COLOR, NEON_MAT)

	-- CrackWall — trigger na parede do fundo (player se aproxima → loja abre)
	local trigger = Instance.new("Part")
	trigger.Name        = "CrackWall"
	trigger.Size        = Vector3.new(area.size.X - 4, wallH - 2, 1)
	trigger.CFrame      = CFrame.new(cx, midY, cz + halfZ - 2)
	trigger.Anchored    = true
	trigger.CanCollide  = false
	trigger.Transparency = 1
	trigger.Parent      = folder
	CollectionService:AddTag(trigger, "CrackWall")

	print("[MapSystem] Sala da loja construída com fenda de entrada")
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
