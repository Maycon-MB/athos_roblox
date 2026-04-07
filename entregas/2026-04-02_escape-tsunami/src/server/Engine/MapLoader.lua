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

	-- 1) Wipe scripts e pastas de kit ANTES de Parent
	-- Inclui Folders cujo nome delata origem (ex: "ungroup in ServerScriptService")
	local wiped = 0
	for _, obj in clone:GetDescendants() do
		if obj.Parent == nil then continue end -- já destruído por pai
		local isScript = obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript")
		local isKitFolder = obj:IsA("Folder") and obj.Name:lower():find("serverscriptservice", 1, true) ~= nil
		if isScript or isKitFolder then
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

	-- 3) Injetar no Workspace
	clone.Name = "GameMap"
	clone.Parent = ws

	print(string.format("[MapLoader] Mapa injetado: %d scripts destruidos, %d BaseParts ancoradas.", wiped, anchored))
	return clone
end

return MapLoader
