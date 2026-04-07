--!strict
-- MapLoader — Padrão Sandbox.
-- Pipeline:
--   1) Destrói Script/LocalScript/ModuleScript + SpawnLocations do kit
--   2) Destrói BaseParts identificadas como barreiras (caminho visualmente limpo)
--   3) Ancora todas as BaseParts restantes
-- Nenhum script de kit roda no Workspace.
local SS = game:GetService("ServerStorage")
local ws = game:GetService("Workspace")
local MapLoader = {}

-- Nomes (contains, case-insensitive) de partes a DESTRUIR.
-- Discovery: '.', 'Line', 'Secret', 'Wall', 'Fence', 'Divider' bloqueavam o caminho.
local BARRIER_NAMES = { "%.", "line", "secret", "wall", "fence", "divider" }

local function isBarrier(bp: BasePart): boolean
	local nameLower = bp.Name:lower()
	for _, pat in BARRIER_NAMES do
		if nameLower:find(pat, 1, true) then
			return true
		end
	end
	return false
end

function MapLoader.setup(): Model?
	local assets = SS:FindFirstChild("Assets")
	local maps   = assets and assets:FindFirstChild("Maps")
	local raw    = maps and maps:FindFirstChild("RawMap") :: Model?
	if not raw then
		warn("[MapLoader] ServerStorage.Assets.Maps.RawMap NAO encontrado.")
		return nil
	end

	local clone = raw:Clone()

	-- 1) Wipe: scripts, pastas de kit e SpawnLocations do kit
	local wiped = 0
	for _, obj in clone:GetDescendants() do
		if obj.Parent == nil then continue end
		local isScript    = obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
		local isKitFolder = obj:IsA("Folder") and obj.Name:lower():find("serverscriptservice", 1, true) ~= nil
		if isScript or isKitFolder then
			print(string.format("[MapLoader] Removido: '%s' (%s)", obj.Name, obj.ClassName))
			obj:Destroy()
			wiped += 1
		end
	end

	-- 2) Destruir barreiras (antes de ancorar — evita iterar partes já destruídas)
	local destroyed = 0
	for _, obj in clone:GetDescendants() do
		if obj.Parent == nil then continue end
		if not obj:IsA("BasePart") then continue end
		if isBarrier(obj :: BasePart) then
			obj:Destroy()
			destroyed += 1
		end
	end

	-- 3) Ancorar todas as BaseParts restantes
	local anchored = 0
	for _, obj in clone:GetDescendants() do
		if not obj:IsA("BasePart") then continue end
		local bp    = obj :: BasePart
		bp.Anchored = true
		bp.CanCollide = true
		if bp.Transparency >= 0.95 then
			bp.Transparency = 0
		end
		anchored += 1
	end

	-- 4) Injetar no Workspace
	clone.Name   = "GameMap"
	clone.Parent = ws

	print(string.format(
		"[MapLoader] Mapa injetado: %d scripts removidos, %d barreiras destruidas, %d BaseParts ancoradas.",
		wiped, destroyed, anchored
	))
	return clone
end

return MapLoader
