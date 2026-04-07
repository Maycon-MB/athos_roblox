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

-- ── 3b. Sistema de Coleta — SafeZone-tagged parts ────────────────────
-- Itens com raridade (Common/Rare/etc.) são consumíveis: concedem moeda e
-- somem ao toque. Zonas permanentes (Cosmic/Mythical) apenas protegem.
-- Debounce por player evita spam e vazamento de memória.
local function SetupCollections(map: Model?)
	if not map then return end

	-- Valor por raridade (nome da peça → moeda)
	local RARITY_VALUE: { [string]: number } = {
		common    = 10,
		uncommon  = 50,
		rare      = 200,
		epic      = 1000,
		legendary = 5000,
		secret    = 10000,
	}
	-- Zonas permanentes: não são consumíveis
	local PERMANENT: { [string]: boolean } = {
		safezone = true,
		shelter  = true,
		cosmic   = true,
		mythical = true,
	}

	local CS = game:GetService("CollectionService")
	local PD = require(E.PlayerData)
	local count = 0

	for _, part in CS:GetTagged("SafeZone") do
		if not part:IsA("BasePart") then continue end
		local bp       = part :: BasePart
		local nameLow  = bp.Name:lower()
		local value    = RARITY_VALUE[nameLow]
		local isPerm   = PERMANENT[nameLow] or (value == nil)

		-- Debounce por player: { [Player]: true } — GC automático quando desconectam
		local debounce: { [Player]: boolean } = {}

		local conn: RBXScriptConnection
		conn = bp.Touched:Connect(function(hit: BasePart)
			local char = hit.Parent
			if not char then return end
			local pl = Players:GetPlayerFromCharacter(char)
			if not pl then return end
			if debounce[pl] then return end

			debounce[pl] = true

			if value and value > 0 then
				PD.addMoney(pl, value)
			end

			if not isPerm then
				-- Consumível: fade + destruição para evitar conexão morta
				conn:Disconnect()
				bp.Transparency = 1
				bp.CanCollide   = false
				task.delay(0.1, function() bp:Destroy() end)
			else
				-- Zona permanente: libera debounce após 1s
				task.delay(1, function() debounce[pl] = nil end)
			end
		end)

		-- Garante limpeza da conexão se a peça for destruída por outro caminho
		bp.Destroying:Connect(function() conn:Disconnect() end)

		count += 1
	end

	print(string.format("[Gameplay] Sistema de Coleta ativado para %d itens.", count))
end

safeInit("Collections", function() SetupCollections(gameMap) end)

-- ── 4. Spawn via física nativa do Roblox ─────────────────────────────
-- Busca a SpawnLocation dentro do GameMap (preservada pelo MapLoader).
-- Fallback: cria SpawnLocation em Settings.SPAWN.
-- Usa player.RespawnLocation + LoadCharacter() — física nativa, sem teleporte.
task.spawn(function()
	task.wait(1) -- aguarda física estabilizar

	-- ── Localizar ponto de spawn (3 prioridades) ─────────────────────────
	local spawnLocation: SpawnLocation? = nil

	-- P1: BasePart chamada "SpawnPoint" — marcador manual do desenvolvedor
	if gameMap then
		local marker = gameMap:FindFirstChild("SpawnPoint", true) :: BasePart?
		if marker and marker:IsA("BasePart") then
			local newSL        = Instance.new("SpawnLocation")
			newSL.Size         = Vector3.new(6, 1, 6)
			newSL.CFrame       = CFrame.new(marker.Position)
			newSL.Anchored     = true
			newSL.Transparency = 1
			newSL.CanCollide   = true
			newSL.Neutral      = true
			newSL.Parent       = ws
			spawnLocation = newSL
			print(string.format(
				"[CoreEngine] Spawn via marcador 'SpawnPoint': (%.1f, %.1f, %.1f)",
				marker.Position.X, marker.Position.Y, marker.Position.Z
			))
		end
	end

	-- P2: SpawnLocation existente no GameMap (busca recursiva)
	if not spawnLocation and gameMap then
		local sl = gameMap:FindFirstChildWhichIsA("SpawnLocation", true) :: SpawnLocation?
		if sl then
			sl.Neutral  = true
			spawnLocation = sl
			print(string.format(
				"[CoreEngine] Spawn via SpawnLocation '%s': (%.1f, %.1f, %.1f)",
				sl.Name, sl.Position.X, sl.Position.Y, sl.Position.Z
			))
		end
	end

	-- P3: fallback — cria SpawnLocation em Settings.SPAWN
	if not spawnLocation then
		if S.SPAWN and S.SPAWN.POSITION then
			local base     = S.SPAWN.POSITION
			local newSL    = Instance.new("SpawnLocation")
			newSL.Size     = Vector3.new(6, 1, 6)
			newSL.CFrame   = CFrame.new(Vector3.new(base.X, -86.1, base.Z))
			newSL.Anchored = true
			newSL.Transparency = 1
			newSL.CanCollide   = true
			newSL.Neutral      = true
			newSL.Parent       = ws
			spawnLocation = newSL
			print(string.format("[CoreEngine] Spawn via Settings.SPAWN: (%.1f, -86.1, %.1f)", base.X, base.Z))
		else
			warn("[CRITICAL] Nenhum ponto de spawn encontrado no mapa ou no Settings!")
		end
	end

	if not spawnLocation then return end

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
