--!strict
------------------------------------------------------------------------
-- COREENGINE.SERVER.LUA — Motor Universal. NÃO EDITE ESTE ARQUIVO.
-- Toda configuração fica em src/shared/Settings.lua.
------------------------------------------------------------------------
local RS         = game:GetService("ReplicatedStorage")
local SSS        = game:GetService("ServerScriptService")
local Players    = game:GetService("Players")
local ws         = game:GetService("Workspace")
local RunService = game:GetService("RunService")

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

-- ── 3b. Sistema de Coleta — Spatial Query (Gold Standard) ───────────
-- Substitui .Touched massivo por GetPartBoundsInBox + OverlapParams.
-- Referência: create.roblox.com/docs/reference/engine/classes/WorldRoot
-- Mobile-first: budget de <2ms por frame de varredura.
local function SetupCollections(map: Model?)
	if not map then return end

	local CS = game:GetService("CollectionService")
	local PD = require(E.PlayerData)

	-- Valor de moeda por raridade (nome da peça em lowercase → coins)
	local RARITY_VALUE: { [string]: number } = {
		common    = 10,
		uncommon  = 50,
		rare      = 200,
		epic      = 1000,
		legendary = 5000,
		secret    = 10000,
	}
	-- Zonas permanentes: não são consumidas (apenas protegem do tsunami)
	local PERMANENT: { [string]: boolean } = {
		safezone = true,
		shelter  = true,
		cosmic   = true,
		mythical = true,
	}

	-- Indexa apenas partes consumíveis com valor definido
	local zones: { BasePart } = {}
	for _, part in CS:GetTagged("SafeZone") do
		if not part:IsA("BasePart") then continue end
		local bp      = part :: BasePart
		local nameLow = bp.Name:lower()
		if not PERMANENT[nameLow] and RARITY_VALUE[nameLow] then
			table.insert(zones, bp)
		end
	end

	print(string.format("[Gameplay] Sistema de Coleta ativado para %d itens.", #zones))
	if #zones == 0 then return end

	-- OverlapParams: inclui apenas partes de personagens de players
	-- FilterType.Include = só retorna partes dentro dos modelos listados
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Include

	local function syncFilter()
		local chars: { Instance } = {}
		for _, pl in Players:GetPlayers() do
			if pl.Character then
				table.insert(chars, pl.Character)
			end
		end
		params.FilterDescendantsInstances = chars
	end

	Players.PlayerAdded:Connect(function(pl)
		pl.CharacterAdded:Connect(syncFilter)
		syncFilter()
	end)
	Players.PlayerRemoving:Connect(syncFilter)
	syncFilter()

	-- Varredura por Heartbeat — itera em reverso para remoção segura por índice
	local frameCount   = 0
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function()
		if #zones == 0 then
			conn:Disconnect()
			print("[Gameplay] Todos os itens coletados — Spatial Query encerrado.")
			return
		end

		local t0 = os.clock()

		for i = #zones, 1, -1 do
			local bp = zones[i]

			-- Parte já destruída por outro sistema (onda, admin, etc.)
			if not bp or not bp.Parent then
				table.remove(zones, i)
				continue
			end

			local hits = ws:GetPartBoundsInBox(bp.CFrame, bp.Size, params)
			if #hits == 0 then continue end

			-- Primeiro hit válido recompensa o player e consome o item
			for _, hit in hits do
				local char = hit.Parent
				if not char then continue end
				local pl = Players:GetPlayerFromCharacter(char)
				if not pl then continue end

				local value = RARITY_VALUE[bp.Name:lower()] or 0
				if value > 0 then PD.addMoney(pl, value) end

				bp.Transparency = 1
				bp.CanCollide   = false
				task.defer(function()
					if bp.Parent then bp:Destroy() end
				end)
				table.remove(zones, i)
				break
			end
		end

		-- Log de performance: warn se acima do budget, print periódico se OK
		local ms = (os.clock() - t0) * 1000
		frameCount += 1
		if ms > 2 then
			warn(string.format(
				"[Gameplay] Spatial Query acima do budget: %.3f ms (%d zonas)",
				ms, #zones
			))
		elseif frameCount % 300 == 0 then -- ~5s a 60fps
			print(string.format(
				"[Gameplay] Spatial Query OK: %.3f ms (%d zonas restantes)",
				ms, #zones
			))
		end
	end)
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
