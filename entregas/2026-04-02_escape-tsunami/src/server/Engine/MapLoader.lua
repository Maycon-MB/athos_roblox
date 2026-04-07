--!strict
-- MapLoader — Padrão Sandbox + Collision Groups (padrão industrial).
-- Pipeline:
--   1) Destrói Script/LocalScript/ModuleScript + SpawnLocations do kit
--   2) Ancora todas as BaseParts
--   3) Peças passáveis → CollisionGroup "MapPassable" (não colide com Default/players)
-- Nenhum script de kit roda no Workspace.
local SS            = game:GetService("ServerStorage")
local ws            = game:GetService("Workspace")
local PhysicsService = game:GetService("PhysicsService")
local MapLoader     = {}

-- Nomes de peças (contains, case-insensitive) que devem ser passáveis.
-- Discovery: 227 partes bloqueantes revelaram estes padrões.
local PASSABLE_NAMES = {
	"%.",        -- peças chamadas "."
	"line",
	"secret",
	"bottom",
	"wall",
	"fence",
	"hitbox",
	"vip",
	"divider",
}

local function isPassable(bp: BasePart): boolean
	local nameLower = bp.Name:lower()
	for _, pat in PASSABLE_NAMES do
		if nameLower:find(pat, 1, true) then
			return true
		end
	end
	return false
end

-- Garante que o collision group exista e não colide com "Default" (players).
local function ensureCollisionGroup()
	local ok = pcall(function()
		PhysicsService:RegisterCollisionGroup("MapPassable")
	end)
	if not ok then
		-- Já existe — apenas garante a regra de não-colisão.
	end
	PhysicsService:CollisionGroupSetCollidable("MapPassable", "Default", false)
end

function MapLoader.setup(): Model?
	local assets = SS:FindFirstChild("Assets")
	local maps   = assets and assets:FindFirstChild("Maps")
	local raw    = maps and maps:FindFirstChild("RawMap") :: Model?
	if not raw then
		warn("[MapLoader] ServerStorage.Assets.Maps.RawMap NAO encontrado.")
		return nil
	end

	ensureCollisionGroup()
	local clone = raw:Clone()

	-- 1) Wipe: scripts, SpawnLocations e pastas de kit ANTES de Parent = Workspace
	local wiped = 0
	for _, obj in clone:GetDescendants() do
		if obj.Parent == nil then continue end
		local isScript    = obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
		local isKitFolder = obj:IsA("Folder") and obj.Name:lower():find("serverscriptservice", 1, true) ~= nil
		-- SpawnLocations PRESERVADAS: o CoreEngine as usa para posicionar o spawn.
		if isScript or isKitFolder then
			print(string.format("[MapLoader] Removido: '%s' (%s)", obj.Name, obj.ClassName))
			obj:Destroy()
			wiped += 1
		end
	end

	-- 2) Anchor + 3) CollisionGroup nas peças passáveis
	local anchored  = 0
	local passable  = 0
	for _, obj in clone:GetDescendants() do
		if not obj:IsA("BasePart") then continue end
		local bp = obj :: BasePart
		bp.Anchored = true

		if isPassable(bp) then
			-- Collision group: não colide com players (Default) — solução definitiva.
			bp.CollisionGroup = "MapPassable"
			bp.CanCollide      = false   -- redundância de segurança
			passable += 1
		else
			bp.CanCollide = true
		end

		if bp.Transparency >= 0.95 then
			bp.Transparency = 0
		end
		anchored += 1
	end

	-- 4) Injetar no Workspace
	clone.Name   = "GameMap"
	clone.Parent = ws

	print(string.format(
		"[MapLoader] Mapa injetado: %d removidos, %d ancoradas, %d passaveis (MapPassable).",
		wiped, anchored, passable
	))
	return clone
end

return MapLoader
