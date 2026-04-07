--!strict
------------------------------------------------------------------------
-- COREENGINE.SERVER.LUA — Motor Universal. NÃO EDITE ESTE ARQUIVO.
-- Toda configuração fica em src/shared/Settings.lua.
------------------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ws = game:GetService("Workspace")

local S = require(RS.Shared.Settings)

-- ── Diagnóstico: mostra o que veio do Settings.lua ───────────────────
do
	local keys = {}
	for k in S do
		table.insert(keys, k)
	end
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

-- ── Sequência de boot industrial ─────────────────────────────────────
-- 1. MapLoader — clona e sanitiza o mapa (scripts destruídos, partes ancoradas)
safeInit("MapLoader", function()
	require(E.MapLoader).setup()
end)

-- 2. MapTagger — aplica tags CollectionService nas peças do mapa
safeInit("MapTagger", function()
	require(E.MapTagger).init(S.TAG_MAP)
end)

-- 3. Sistemas de jogo
safeInit("PlayerData", function()
	require(E.PlayerData).init(S)
end)
safeInit("WaveSystem", function()
	require(E.WaveSystem).init(S)
end)
safeInit("BrainrotSystem", function()
	require(E.BrainrotSystem).init(S)
end)
safeInit("JumpSystem", function()
	require(E.JumpSystem).init(S)
end)
safeInit("AdminSystem", function()
	require(E.AdminSystem).init(S)
end)
safeInit("MobSystem", function()
	require(E.MobSystem).init(S)
end)

-- ── Spawn position ────────────────────────────────────────────────────
-- Prioridade 1: peça tagueada "GameSpawn" (coloque um bloco chamado "Spawn" no mapa)
-- Prioridade 2: raycast a partir de Settings.SPAWN.POSITION (XZ do início da pista)
-- Prioridade 3: fallback manual Settings.SPAWN.POSITION
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

	-- P2: raycast a partir do XZ do Settings.SPAWN (ignora água)
	warn("[CoreEngine] Nenhum 'Spawn' no mapa — usando raycast de Settings.SPAWN.")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local waterParts: { Instance } = {}
	for _, obj in CollectionService:GetTagged("TsunamiWater") do
		table.insert(waterParts, obj)
	end
	for _, obj in CollectionService:GetTagged("Tsunami") do
		table.insert(waterParts, obj)
	end
	params.FilterDescendantsInstances = waterParts

	local px = if S.SPAWN and S.SPAWN.POSITION then S.SPAWN.POSITION.X else 0
	local pz = if S.SPAWN and S.SPAWN.POSITION then S.SPAWN.POSITION.Z else 0

	local hit = ws:Raycast(Vector3.new(px, 1000, pz), Vector3.new(0, -2000, 0), params)
	if hit then
		local pos = hit.Position + Vector3.new(0, 5, 0)
		print(string.format("[CoreEngine] Spawn via raycast: (%.1f, %.1f, %.1f)", pos.X, pos.Y, pos.Z))
		return pos
	end

	-- P3: fallback
	local fallback = S.SPAWN and S.SPAWN.POSITION or Vector3.new(0, 5, 0)
	warn("[CoreEngine] Raycast falhou — usando fallback " .. tostring(fallback))
	return fallback
end

-- 4. task.wait(2) para física estabilizar, depois configura spawn
task.spawn(function()
	task.wait(2)
	local spawnPos = findSpawnPosition()
	local spawnCF = CFrame.new(spawnPos)

	-- Reposiciona ou cria SpawnLocation
	local sl = ws:FindFirstChildOfClass("SpawnLocation")
	if sl then
		sl.CFrame = spawnCF
	else
		local newSL = Instance.new("SpawnLocation")
		newSL.Size = Vector3.new(6, 1, 6)
		newSL.CFrame = spawnCF - Vector3.new(0, 2, 0)
		newSL.Anchored = true
		newSL.Transparency = 1
		newSL.CanCollide = true
		newSL.Parent = ws
	end

	-- Teleporte de segurança em CharacterAdded
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			task.wait(0.2)
			local char = player.Character
			if not char then
				return
			end
			local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
			if hrp then
				hrp.CFrame = spawnCF
			end
		end)
	end)

	-- Teleporta players já conectados (teste no Studio)
	for _, player in Players:GetPlayers() do
		local char = player.Character
		if not char then
			continue
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = spawnCF
		end
	end
end)

print("[CoreEngine] Ativo — " .. game.Name)
