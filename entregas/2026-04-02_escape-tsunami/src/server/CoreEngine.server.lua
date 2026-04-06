--!strict
------------------------------------------------------------------------
-- COREENGINE.SERVER.LUA — Motor Universal. NÃO EDITE ESTE ARQUIVO.
-- Toda configuração fica em src/shared/Settings.lua.
------------------------------------------------------------------------
local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ws      = game:GetService("Workspace")

-- ── Limpeza do kit importado — DESATIVADA temporariamente ───────────
-- Para reativar, descomente o bloco abaixo.
--[[
local WIPE_CLASSES = { Script=true, LocalScript=true, ModuleScript=true,
                       Sound=true, RemoteEvent=true, RemoteFunction=true }
local env = ws:FindFirstChild("Environment_Dirty")
if env then
	local removidos = 0
	for _, obj in env:GetDescendants() do
		if WIPE_CLASSES[obj.ClassName] then obj:Destroy(); removidos += 1 end
	end
	if removidos > 0 then
		print(string.format("[CoreEngine] Wipe: %d objeto(s) removidos de Environment_Dirty.", removidos))
	end
end
--]]

local S = require(RS.Shared.Settings)

-- ── Diagnóstico: mostra o que veio do Settings.lua ───────────────────
do
	local keys = {}
	for k in S do table.insert(keys, k) end
	if #keys == 0 then
		warn("[CoreEngine] Settings.lua retornou tabela VAZIA — verifique o arquivo.")
	else
		print("[CoreEngine] Settings carregado. Chaves: " .. table.concat(keys, ", "))
	end
end

local E = SSS:WaitForChild("Engine")

-- Protege o boot: falha num módulo não impede os demais de carregar.
local function safeInit(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn(string.format("[CoreEngine] %s.init() falhou: %s", name, tostring(err)))
	end
end

-- FixPhysics primeiro: ancora o mapa antes de qualquer lógica de spawn
safeInit("FixPhysics",     function() require(E.FixPhysics).init() end)

-- ── Log de auditoria do mapa ──────────────────────────────────────────
do
	local env = ws:FindFirstChild("Environment_Dirty")
	if env then
		print("[DEBUG] Objetos em Environment_Dirty: " .. #env:GetChildren())
		local partes = 0
		for _, obj in env:GetDescendants() do
			if obj:IsA("BasePart") then partes += 1 end
		end
		print("[DEBUG] BaseParts totais em Environment_Dirty: " .. partes)
	else
		warn("[DEBUG] Environment_Dirty NAO encontrado — Rojo nao injetou o mapa!")
	end
end

safeInit("MapTagger",      function() require(E.MapTagger).init(S.TAG_MAP) end)
safeInit("PlayerData",     function() require(E.PlayerData).init(S) end)
safeInit("WaveSystem",     function() require(E.WaveSystem).init(S) end)
safeInit("BrainrotSystem", function() require(E.BrainrotSystem).init(S) end)
safeInit("JumpSystem",     function() require(E.JumpSystem).init(S) end)
safeInit("AdminSystem",    function() require(E.AdminSystem).init(S) end)
safeInit("MobSystem",      function() require(E.MobSystem).init(S) end)

-- ── Spawn position ────────────────────────────────────────────────────
-- Prioridade 1: peça tagueada "GameSpawn" (coloque um bloco chamado "Spawn" no mapa)
-- Prioridade 2: raycast a partir do centro geométrico do mapa
-- Prioridade 3: Settings.SPAWN.POSITION (fallback manual)
local function findSpawnPosition(): Vector3
	local CollectionService = game:GetService("CollectionService")

	-- P1: GameSpawn explícito
	local spawns = CollectionService:GetTagged("GameSpawn")
	if #spawns > 0 then
		local bp = spawns[1] :: BasePart
		local pos = bp.Position + Vector3.new(0, bp.Size.Y / 2 + 3, 0)
		print(string.format("[CoreEngine] Spawn via GameSpawn '%s': (%.1f, %.1f, %.1f)", bp.Name, pos.X, pos.Y, pos.Z))
		return pos
	end

	-- P2: raycast a partir do centro geométrico (ignora água)
	warn("[CoreEngine] Nenhum 'Spawn' no mapa — usando raycast de centro geometrico.")
	local sumX, sumZ, count = 0, 0, 0
	for _, obj in ws:GetDescendants() do
		if not obj:IsA("BasePart") then continue end
		local bp = obj :: BasePart
		if CollectionService:HasTag(bp, "TsunamiWater") then continue end
		if CollectionService:HasTag(bp, "Tsunami") then continue end
		if bp.Transparency >= 0.95 then continue end
		sumX += bp.Position.X
		sumZ += bp.Position.Z
		count += 1
	end
	local cx = if count > 0 then sumX / count else 0
	local cz = if count > 0 then sumZ / count else 0

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local waterParts: { Instance } = {}
	for _, obj in CollectionService:GetTagged("TsunamiWater") do table.insert(waterParts, obj) end
	for _, obj in CollectionService:GetTagged("Tsunami")      do table.insert(waterParts, obj) end
	params.FilterDescendantsInstances = waterParts

	-- Usa XZ do Settings.SPAWN se definido; caso contrário, centro geométrico
	local px = if S.SPAWN and S.SPAWN.POSITION then S.SPAWN.POSITION.X else cx
	local pz = if S.SPAWN and S.SPAWN.POSITION then S.SPAWN.POSITION.Z else cz

	local hit = ws:Raycast(Vector3.new(px, 1000, pz), Vector3.new(0, -2000, 0), params)
	if hit then
		local pos = hit.Position + Vector3.new(0, 5, 0)
		print(string.format("[CoreEngine] Spawn via raycast: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z))
		return pos
	end

	-- P3: fallback — usa XZ do SPAWN mas Y seguro para cair na pista
	local fallback = S.SPAWN and S.SPAWN.POSITION or Vector3.new(0, 5, 0)
	warn("[CoreEngine] Raycast falhou — usando fallback " .. tostring(fallback))
	return fallback
end

-- Aguarda MapTagger terminar (3s) antes de calcular — peças de água já tagueadas
task.delay(3, function()
	local spawnPos = findSpawnPosition()
	local spawnCF  = CFrame.new(spawnPos)

	-- Reposiciona ou cria SpawnLocation para o Roblox spawnar no lugar certo
	local sl = ws:FindFirstChildOfClass("SpawnLocation")
	if sl then
		sl.CFrame = spawnCF
	else
		local newSL         = Instance.new("SpawnLocation")
		newSL.Size          = Vector3.new(6, 1, 6)
		newSL.CFrame        = spawnCF - Vector3.new(0, 2, 0)
		newSL.Anchored      = true
		newSL.Transparency  = 1     -- invisível: não polui o visual do mapa
		newSL.CanCollide    = true
		newSL.Parent        = ws
	end

	-- Teleporte de segurança em CharacterAdded
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			local char = player.Character; if not char then return end
			local hrp  = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then hrp.CFrame = spawnCF end
		end)
	end)

	-- Teleporta players já conectados (teste no Studio)
	for _, player in Players:GetPlayers() do
		local char = player.Character; if not char then continue end
		local hrp  = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then hrp.CFrame = spawnCF end
	end
end)

print("[CoreEngine] Ativo — " .. game.Name)
