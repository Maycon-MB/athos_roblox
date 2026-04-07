--!strict
-- WaveSystem — Motor Universal de Tsunami
-- Auto-descobre os limites do mapa pela geometria.
-- Move a peça tagueada "TsunamiWater" do limite Z- ao limite Z+ da pista.
-- Funciona em qualquer mapa sem coordenadas fixas.
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RS = game:GetService("ReplicatedStorage")
local WaveSystem = {}

local _cfg: any
local waveCount = 0
local waveActive = false
local waveStarted: RemoteEvent
local waveSurvived: RemoteEvent
local useToken: RemoteEvent

-- ── Auto-discovery dos limites Z do mapa ─────────────────────────────
-- Ignora peças de água para não distorcer o cálculo.
local function findMapZBounds(): (number, number, number, number)
	local ws = game:GetService("Workspace")
	local minZ = math.huge
	local maxZ = -math.huge
	local minX = math.huge
	local maxX = -math.huge

	local waterTags = { TsunamiWater = true, Tsunami = true }

	for _, obj in ws:GetDescendants() do
		if not obj:IsA("BasePart") then
			continue
		end
		local bp = obj :: BasePart
		-- Pula peças de água e peças sem colisão (decoração aérea)
		if waterTags[bp.Name] then
			continue
		end
		if CollectionService:HasTag(bp, "TsunamiWater") then
			continue
		end
		if CollectionService:HasTag(bp, "Tsunami") then
			continue
		end
		if bp.Transparency >= 0.95 then
			continue
		end

		local pos = bp.Position
		if pos.Z < minZ then
			minZ = pos.Z
		end
		if pos.Z > maxZ then
			maxZ = pos.Z
		end
		if pos.X < minX then
			minX = pos.X
		end
		if pos.X > maxX then
			maxX = pos.X
		end
	end

	if minZ == math.huge then
		minZ = -200
		maxZ = 200
		minX = -40
		maxX = 40
	end
	return minZ, maxZ, minX, maxX
end

-- ── SafeZone check por bounding box ──────────────────────────────────
local function isInSafeZone(pos: Vector3): boolean
	for _, part in CollectionService:GetTagged("SafeZone") do
		if not part:IsA("BasePart") then
			continue
		end
		local bp = part :: BasePart
		local rel = bp.CFrame:PointToObjectSpace(pos)
		local half = bp.Size / 2
		if math.abs(rel.X) <= half.X and math.abs(rel.Y) <= half.Y + 2 and math.abs(rel.Z) <= half.Z then
			return true
		end
	end
	return false
end

-- ── Coleta ou cria a peça da onda ────────────────────────────────────
local function getOrCreateWavePart(startCF: CFrame, width: number): BasePart
	-- Prefere peça já tagueada no mapa
	for _, obj in CollectionService:GetTagged("TsunamiWater") do
		if obj:IsA("BasePart") then
			local bp = obj :: BasePart
			bp.CFrame = startCF
			return bp
		end
	end
	-- Fallback: cria parede azul
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWave"
	wall.Size = Vector3.new(width + 40, 35, 8)
	wall.CFrame = startCF
	wall.Anchored = true
	wall.CanCollide = false
	wall.Color = Color3.fromRGB(30, 110, 220)
	wall.Transparency = 0.25
	wall.CastShadow = false
	wall.Parent = game:GetService("Workspace")
	return wall
end

-- ── Ciclo de uma onda ────────────────────────────────────────────────
local function startWave(speedOverride: number?, killer: Player?)
	if waveActive then
		return
	end
	waveActive = true
	waveCount += 1

	local cfg = _cfg.WAVE
	local speed = speedOverride or math.min(cfg.SPEED + math.floor(waveCount / 5) * 4, cfg.SPEED_MAX)

	-- Calcula limites do mapa
	local minZ, maxZ, minX, maxX = findMapZBounds()
	local mapWidth = maxX - minX
	local centerX = (minX + maxX) / 2
	local centerY = 10 -- altura padrão da onda

	local startCF = CFrame.new(centerX, centerY, minZ - 20)
	local endZ = maxZ + 20

	local wave = getOrCreateWavePart(startCF, mapWidth)
	local wasCreatedByUs = wave.Name == "TsunamiWave"

	print(
		string.format(
			"[WaveSystem] Onda #%d | Z: %.0f→%.0f | speed: %.0f | largura: %.0f",
			waveCount,
			startCF.Position.Z,
			endZ,
			speed,
			mapWidth
		)
	)

	waveStarted:FireAllClients(waveCount)

	-- Rastreia sobreviventes
	local survived: { [Player]: boolean } = {}
	for _, p in Players:GetPlayers() do
		survived[p] = true
	end

	local PD = require(script.Parent.PlayerData)
	local conn = wave.Touched:Connect(function(hit)
		local char = hit.Parent
		if not char then
			return
		end
		local pl = Players:GetPlayerFromCharacter(char)
		if not pl then
			return
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp and isInSafeZone(hrp.Position) then
			return
		end
		local d = PD.get(pl)
		if d and d.hasShield then
			return
		end
		survived[pl] = false
		local h = char:FindFirstChildOfClass("Humanoid")
		if h then
			h.Health = 0
		end
		if killer then
			local kd = PD.get(killer)
			if kd then
				kd.noobsKilled += 1
				PD.sync(killer)
			end
		end
	end)

	task.spawn(function()
		-- Avança pela pista
		while wave and wave.Parent do
			local dt = task.wait(0.03)
			local newZ = wave.Position.Z + speed * dt
			wave.CFrame = CFrame.new(wave.Position.X, wave.Position.Y, newZ)
			if newZ >= endZ then
				break
			end
		end

		task.wait(cfg.HOLD_TIME)
		conn:Disconnect()

		-- Volta à posição inicial (ou destrói se foi criada por fallback)
		if wave and wave.Parent then
			if wasCreatedByUs then
				wave:Destroy()
			else
				wave.CFrame = startCF -- reseta para o próximo ciclo
			end
		end

		-- Notifica sobreviventes
		for pl, ok in survived do
			if ok and pl.Parent then
				waveSurvived:FireClient(pl, waveCount)
				local d = PD.get(pl)
				if d then
					d.wavesSurvived += 1
					PD.sync(pl)
				end
			end
		end

		waveActive = false
	end)
end

function WaveSystem.startWave(speed: number?, killer: Player?)
	startWave(speed, killer)
end

function WaveSystem.init(cfg: any)
	_cfg = cfg
	local R = require(RS.Shared.Remotes)

	waveStarted = Instance.new("RemoteEvent")
	waveStarted.Name = R.WaveStarted
	waveStarted.Parent = RS

	waveSurvived = Instance.new("RemoteEvent")
	waveSurvived.Name = R.WaveSurvived
	waveSurvived.Parent = RS

	useToken = Instance.new("RemoteEvent")
	useToken.Name = R.UseWaveToken
	useToken.Parent = RS

	useToken.OnServerEvent:Connect(function(p, speedStr: string)
		local PD = require(script.Parent.PlayerData)
		local d = PD.get(p)
		if not d then
			return
		end
		local spd = tonumber(speedStr) or 40
		local cost = if spd >= 100 then 10 elseif spd >= 70 then 5 else 1
		if d.waveTokens < cost then
			return
		end
		d.waveTokens -= cost
		PD.sync(p)
		startWave(spd, p)
	end)

	-- Auto waves (skip se Settings.WAVE não estiver preenchido)
	if not cfg.WAVE then
		warn("[WaveSystem] Settings.WAVE ausente — ondas desativadas. Preencha Settings.lua.")
		return
	end
	task.spawn(function()
		while true do
			task.wait(cfg.WAVE.INTERVAL)
			startWave()
		end
	end)
end

return WaveSystem
