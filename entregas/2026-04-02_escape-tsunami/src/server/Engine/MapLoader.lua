--!strict
-- MapLoader — Padrão Sandbox.
-- Clona RawMap de ServerStorage para Workspace com pipeline de limpeza:
--   1) Destrói Script/LocalScript/ModuleScript ANTES de Parent = Workspace
--   2) Ancora todas as BaseParts (CanCollide = true)
-- Nenhum script de kit roda no Workspace.
local SS = game:GetService("ServerStorage")
local ws = game:GetService("Workspace")
local MapLoader = {}

function MapLoader.setup(): Model?
	local assets = SS:FindFirstChild("Assets")
	local maps = assets and assets:FindFirstChild("Maps")
	local raw = maps and maps:FindFirstChild("RawMap") :: Model?
	if not raw then
		warn("[MapLoader] ServerStorage.Assets.Maps.RawMap NAO encontrado.")
		return nil
	end

	local clone = raw:Clone()

	-- 1) Wipe: scripts e pastas de kit ANTES de Parent = Workspace
	-- O motor é quem manda — nenhum script do mapa roda.
	local wiped = 0
	for _, obj in clone:GetDescendants() do
		if obj.Parent == nil then continue end -- já destruído por pai
		local isScript = obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
		local isKitFolder = obj:IsA("Folder") and obj.Name:lower():find("serverscriptservice", 1, true) ~= nil
		if isScript or isKitFolder then
			print(string.format("[MapLoader] Removido: '%s' (%s)", obj.Name, obj.ClassName))
			obj:Destroy()
			wiped += 1
		end
	end

	-- 2) Ancorar todas as BaseParts
	local anchored = 0
	for _, obj in clone:GetDescendants() do
		if obj:IsA("BasePart") then
			local bp = obj :: BasePart
			bp.Anchored = true
			bp.CanCollide = true
			if bp.Transparency >= 0.95 then
				bp.Transparency = 0
			end
			anchored += 1
		end
	end

	-- 2b) Sanitizar barreiras visuais: peças/filhos de "Wall", "Fence", "Divider"
	-- muito grandes e opacas viram transparentes+passáveis (não destroem visual do mapa).
	local BARRIER_PARENTS = { wall = true, fence = true, divider = true }
	local barriers = 0
	for _, obj in clone:GetDescendants() do
		if not obj:IsA("BasePart") then continue end
		local bp = obj :: BasePart
		local nameLower   = bp.Name:lower()
		local parentLower = bp.Parent and bp.Parent.Name:lower() or ""
		local isBarrier   = BARRIER_PARENTS[nameLower] or BARRIER_PARENTS[parentLower]
		local isLarge     = bp.Size.X > 100 or bp.Size.Z > 100
		local isOpaque    = bp.Transparency < 0.1
		if isBarrier and isLarge and isOpaque then
			bp.Transparency = 0.5
			bp.CanCollide   = false
			barriers += 1
			print(string.format("[MapLoader] Barreira suavizada: '%s'  Size=(%.0f×%.0f×%.0f)",
				bp.Name, bp.Size.X, bp.Size.Y, bp.Size.Z))
		end
	end

	-- 3) Injetar no Workspace
	clone.Name = "GameMap"
	clone.Parent = ws

	print(string.format("[MapLoader] Mapa injetado: %d scripts destruidos, %d BaseParts ancoradas, %d barreiras suavizadas.", wiped, anchored, barriers))
	return clone
end

return MapLoader
