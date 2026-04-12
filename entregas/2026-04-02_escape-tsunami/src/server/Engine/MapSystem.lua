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

-- ── Cria objetos interativos na área shop ───────────────────────────
local function setupShopArea(area: any, folder: Instance)
	local cx = area.spawn.Position.X
	local cz = area.spawn.Position.Z
	local floorY = area.spawn.Position.Y

	-- CrackWall (trigger para abrir JumpShop)
	local wall = Instance.new("Part")
	wall.Name = "CrackWall"
	wall.Size = Vector3.new(12, 10, 2)
	wall.CFrame = CFrame.new(cx, floorY + 5, cz + 15)
	wall.Anchored = true
	wall.CanCollide = true
	wall.Color = Color3.fromRGB(120, 80, 50)
	wall.Material = Enum.Material.Brick
	wall.Parent = folder
	CollectionService:AddTag(wall, "CrackWall")
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
	hrp.CFrame = area.spawn
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
