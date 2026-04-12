--!strict
-- WaveSystem — Onda de tsunami para cenários fake.
-- Opera dentro de MAP_AREAS.main. Sem auto-discovery.
-- Admin trigger por default (AUTO_WAVES = false).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local WaveSystem = {}

local _cfg: any
local waveCount = 0
local waveActive = false
local waveStarted: RemoteEvent
local waveSurvived: RemoteEvent
local useToken: RemoteEvent

-- ── Cria parede azul da onda ────────────────────────────────────────
local function createWavePart(startX: number, centerZ: number, depth: number, waveY: number): BasePart
	local WAVE_HEIGHT = 40
	local wall = Instance.new("Part")
	wall.Name = "TsunamiWave"
	wall.Size = Vector3.new(8, WAVE_HEIGHT, depth + 40)
	wall.CFrame = CFrame.new(startX, waveY, centerZ)
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

	-- Bounds da área main via MAP_AREAS
	local area = _cfg.MAP_AREAS and _cfg.MAP_AREAS.main
	local spawnCF = if area then area.spawn else CFrame.new(0, 10, 0)
	local areaSize = if area then area.size else Vector3.new(200, 50, 200)

	local cx = spawnCF.Position.X
	local cz = spawnCF.Position.Z
	local floorY = spawnCF.Position.Y

	-- Onda nasce no final da área (+X) e varre em direção ao spawn (-X)
	local startX = cx + areaSize.X / 2 + 20
	local endX = cx - areaSize.X / 2 - 20
	local waveY = floorY + 20

	local wave = createWavePart(startX, cz, areaSize.Z, waveY)

	print(string.format("[WaveSystem] Onda #%d | X: %.0f→%.0f | speed: %.0f", waveCount, startX, endX, speed))

	waveStarted:FireAllClients(waveCount)

	-- Rastreia sobreviventes
	local survived: { [Player]: boolean } = {}
	for _, p in Players:GetPlayers() do
		survived[p] = true
	end

	local ws = game:GetService("Workspace")
	local PD = require(script.Parent.PlayerData)

	-- Spatial Query: detecta players dentro dos bounds da onda
	local damageParams = OverlapParams.new()
	damageParams.FilterType = Enum.RaycastFilterType.Include
	local function syncDamageFilter()
		local chars: { Instance } = {}
		for _, p in Players:GetPlayers() do
			if p.Character then
				table.insert(chars, p.Character)
			end
		end
		damageParams.FilterDescendantsInstances = chars
	end
	syncDamageFilter()

	local damaged: { [Player]: boolean } = {}
	local damageConn: RBXScriptConnection
	damageConn = RunService.Heartbeat:Connect(function()
		syncDamageFilter()
		local hits = ws:GetPartBoundsInBox(wave.CFrame, wave.Size, damageParams)
		for _, hit in hits do
			local char = hit.Parent
			if not char then
				continue
			end
			local pl = Players:GetPlayerFromCharacter(char)
			if not pl or damaged[pl] then
				continue
			end
			local d = PD.get(pl)
			if d and d.hasShield then
				continue
			end
			damaged[pl] = true
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
		end
	end)

	task.spawn(function()
		-- Avança ao longo do eixo X (sentido negativo: fim→início)
		while wave and wave.Parent do
			local dt = task.wait(0.03)
			local newX = wave.Position.X - speed * dt
			wave.CFrame = CFrame.new(newX, wave.Position.Y, wave.Position.Z)
			if newX <= endX then
				break
			end
		end

		task.wait(cfg.HOLD_TIME)
		damageConn:Disconnect()

		if wave and wave.Parent then
			wave:Destroy()
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

	if not cfg.WAVE then
		warn("[WaveSystem] Settings.WAVE ausente — ondas desativadas.")
		return
	end

	-- Auto waves só se habilitado (cinematográfico = desativado por default)
	if cfg.WAVE.AUTO_WAVES then
		task.spawn(function()
			while true do
				task.wait(cfg.WAVE.INTERVAL)
				startWave()
			end
		end)
	end
end

return WaveSystem
