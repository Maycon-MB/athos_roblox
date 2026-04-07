--!strict
------------------------------------------------------------------------
-- COREENGINE.SERVER.LUA — Motor Universal. NÃO EDITE ESTE ARQUIVO.
-- Toda configuração fica em src/shared/Settings.lua.
------------------------------------------------------------------------
local RS      = game:GetService("ReplicatedStorage")
local SSS     = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ws      = game:GetService("Workspace")

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

-- ── 1. MapLoader — captura o modelo retornado ─────────────────────────
local gameMap: Model? = nil
do
	local ok, err = pcall(function()
		gameMap = require(E.MapLoader).setup()
	end)
	if not ok then
		warn("[CoreEngine] MapLoader.setup() falhou: " .. tostring(err))
	end
end

-- ── 2. MapTagger ──────────────────────────────────────────────────────
safeInit("MapTagger",      function() require(E.MapTagger).init(S.TAG_MAP) end)

-- ── 3. Sistemas de jogo ───────────────────────────────────────────────
safeInit("PlayerData",     function() require(E.PlayerData).init(S) end)
safeInit("WaveSystem",     function() require(E.WaveSystem).init(S) end)
safeInit("BrainrotSystem", function() require(E.BrainrotSystem).init(S) end)
safeInit("JumpSystem",     function() require(E.JumpSystem).init(S) end)
safeInit("AdminSystem",    function() require(E.AdminSystem).init(S) end)
safeInit("MobSystem",      function() require(E.MobSystem).init(S) end)

-- ── 4. Spawn via física nativa do Roblox ─────────────────────────────
-- Busca a SpawnLocation dentro do GameMap (preservada pelo MapLoader).
-- Fallback: cria SpawnLocation em Settings.SPAWN.
-- Usa player.RespawnLocation + LoadCharacter() — física nativa, sem teleporte.
task.spawn(function()
	task.wait(1) -- aguarda física estabilizar

	-- Localizar ou criar SpawnLocation
	local spawnLocation: SpawnLocation

	if gameMap then
		local sl = gameMap:FindFirstChildOfClass("SpawnLocation") :: SpawnLocation?
		if sl then
			sl.Neutral = true -- garante que qualquer player possa usar
			spawnLocation = sl
			print(string.format(
				"[CoreEngine] SpawnLocation do mapa: '%s' (%.1f, %.1f, %.1f)",
				sl.Name, sl.Position.X, sl.Position.Y, sl.Position.Z
			))
		end
	end

	if not spawnLocation then
		warn("[CoreEngine] Sem SpawnLocation no GameMap — criando fallback em Settings.SPAWN.")
		local base = if S.SPAWN and S.SPAWN.POSITION then S.SPAWN.POSITION else Vector3.new(0, -86.1, 0)
		local newSL        = Instance.new("SpawnLocation")
		newSL.Size         = Vector3.new(6, 1, 6)
		newSL.CFrame       = CFrame.new(Vector3.new(base.X, -86.1, base.Z))
		newSL.Anchored     = true
		newSL.Transparency = 1
		newSL.CanCollide   = true
		newSL.Neutral      = true
		newSL.Parent       = ws
		spawnLocation = newSL
		print(string.format("[CoreEngine] SpawnLocation criada em: (%.1f, -86.1, %.1f)", base.X, base.Z))
	end

	-- Novos players: define RespawnLocation antes do auto-spawn do Roblox
	Players.PlayerAdded:Connect(function(player)
		player.RespawnLocation = spawnLocation
	end)

	-- Players já conectados (Studio): força respawn imediato no local correto
	for _, player in Players:GetPlayers() do
		player.RespawnLocation = spawnLocation
		player:LoadCharacter()
	end
end)

print("[CoreEngine] Ativo — " .. game.Name)
