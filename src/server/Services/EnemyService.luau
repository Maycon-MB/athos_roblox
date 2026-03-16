--!strict

--[[
	EnemyService — Sistema de ondas + IA de zumbis

	Correções em relação à versão antiga:
	  • Zumbis nascem em 8 pontos fixos distribuídos (não se agrupam)
	  • IA usa MoveTo atualizado a cada 0.35s (não apenas uma vez)
	  • Dano ao jogador via RemoteEvent (PlayerHurt)
	  • Servidor valida o hit antes de aplicar dano (PlayerShoot)
	  • Ondas progressivas com pausa entre elas
]]

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local GameConfig  = require(Shared:WaitForChild("GameConfig"))
local RemoteNames = require(Shared:WaitForChild("RemoteNames"))

-- MapService é required após init para garantir que os spawn points existam
local MapService = require(script.Parent:WaitForChild("MapService"))

local EnemyService = {}

local remotes: Folder

-- ── Estado da onda ────────────────────────────────────────────────────────────

local currentWave  = 0
local zombiesAlive = 0
local zombiesTotal = 0
local waveRunning  = false
local gameOver     = false
local spawnIndex   = 0  -- cicla pelos 8 spawn points em ordem

local MAX_WAVES = 5  -- vitória após esta onda

-- ── Utilitário: jogador mais próximo ─────────────────────────────────────────

local function nearestPlayer(fromPos: Vector3): (Player?, BasePart?)
	local bestDist = math.huge
	local bestPlayer: Player?
	local bestHRP: BasePart?

	for _, player in Players:GetPlayers() do
		local char = player.Character
		if not char then continue end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		local hum = char:FindFirstChildOfClass("Humanoid")
		if not (hrp and hum and hum.Health > 0) then continue end
		local dist = (hrp.Position - fromPos).Magnitude
		if dist < bestDist then
			bestDist   = dist
			bestPlayer = player
			bestHRP    = hrp
		end
	end

	return bestPlayer, bestHRP
end

-- ── Construção do zumbi (R6 manual) ──────────────────────────────────────────

local function motor6D(parent: Instance, part0: BasePart, part1: BasePart, c0: CFrame, c1: CFrame): Motor6D
	local m  = Instance.new("Motor6D")
	m.Part0  = part0
	m.Part1  = part1
	m.C0     = c0
	m.C1     = c1
	m.Parent = parent
	return m
end

local function newPart(name: string, size: Vector3, color: Color3, parent: Instance): Part
	local pt         = Instance.new("Part")
	pt.Name          = name
	pt.Size          = size
	pt.Color         = color
	pt.Material      = Enum.Material.SmoothPlastic
	pt.TopSurface    = Enum.SurfaceType.Smooth
	pt.BottomSurface = Enum.SurfaceType.Smooth
	pt.CanCollide    = true
	pt.Parent        = parent
	return pt
end

local ZOMBIE_COLOR  = Color3.fromRGB(50,  90,  40)   -- verde escuro
local ZOMBIE_COLOR2 = Color3.fromRGB(35,  65,  28)

local function buildZombie(id: number, spawnPos: Vector3): Model
	local model      = Instance.new("Model")
	model.Name       = "Zombie_" .. id

	local hrp        = newPart("HumanoidRootPart", Vector3.new(2,2,1), Color3.fromRGB(0,0,0), model)
	hrp.Transparency = 1
	hrp.CanCollide   = false

	local torso  = newPart("Torso",     Vector3.new(2,2,1), ZOMBIE_COLOR,  model)
	local head   = newPart("Head",      Vector3.new(2,1,1), ZOMBIE_COLOR2, model)
	local rArm   = newPart("Right Arm", Vector3.new(1,2,1), ZOMBIE_COLOR,  model)
	local lArm   = newPart("Left Arm",  Vector3.new(1,2,1), ZOMBIE_COLOR,  model)
	local rLeg   = newPart("Right Leg", Vector3.new(1,2,1), ZOMBIE_COLOR2, model)
	local lLeg   = newPart("Left Leg",  Vector3.new(1,2,1), ZOMBIE_COLOR2, model)

	-- Olhos brilhantes
	local eyeLight       = Instance.new("PointLight")
	eyeLight.Color       = Color3.fromRGB(255, 50, 0)
	eyeLight.Brightness  = 2
	eyeLight.Range       = 8
	eyeLight.Parent      = head

	-- Motor6Ds — estrutura R6 padrão
	motor6D(hrp,   hrp,   torso, CFrame.new(0,-1,0)*CFrame.Angles(-math.pi/2,0,math.pi), CFrame.new(0,-1,0)*CFrame.Angles(-math.pi/2,0,math.pi))
	motor6D(torso, torso, head,  CFrame.new(0,1,0)*CFrame.Angles(-math.pi/2,0,math.pi),  CFrame.new(0,-0.5,0)*CFrame.Angles(-math.pi/2,0,math.pi))
	motor6D(torso, torso, rArm,  CFrame.new(1.5,0.5,0)*CFrame.Angles(0,math.pi/2,0),     CFrame.new(-0.5,0.5,0)*CFrame.Angles(0,math.pi/2,0))
	motor6D(torso, torso, lArm,  CFrame.new(-1.5,0.5,0)*CFrame.Angles(0,-math.pi/2,0),   CFrame.new(0.5,0.5,0)*CFrame.Angles(0,-math.pi/2,0))
	motor6D(torso, torso, rLeg,  CFrame.new(0.5,-1,0)*CFrame.Angles(0,math.pi/2,0),      CFrame.new(0,1,0)*CFrame.Angles(0,math.pi/2,0))
	motor6D(torso, torso, lLeg,  CFrame.new(-0.5,-1,0)*CFrame.Angles(0,-math.pi/2,0),    CFrame.new(0,1,0)*CFrame.Angles(0,-math.pi/2,0))

	-- Humanoid
	local hum            = Instance.new("Humanoid")
	hum.MaxHealth        = GameConfig.ZOMBIE_HEALTH
	hum.Health           = GameConfig.ZOMBIE_HEALTH
	hum.WalkSpeed        = GameConfig.ZOMBIE_SPEED
	hum.RigType          = Enum.HumanoidRigType.R6
	hum.Parent           = model

	model.PrimaryPart    = hrp

	-- Barra de vida acima da cabeça
	local billboard            = Instance.new("BillboardGui")
	billboard.Size             = UDim2.new(0, 80, 0, 10)
	billboard.StudsOffset      = Vector3.new(0, 3.5, 0)
	billboard.AlwaysOnTop      = false
	billboard.ResetOnSpawn     = false
	billboard.Parent           = head

	local bg                   = Instance.new("Frame")
	bg.Size                    = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3        = Color3.fromRGB(40, 0, 0)
	bg.BorderSizePixel         = 0
	bg.Parent                  = billboard

	local bar                  = Instance.new("Frame")
	bar.Name                   = "HPBar"
	bar.Size                   = UDim2.new(1, 0, 1, 0)
	bar.BackgroundColor3       = Color3.fromRGB(200, 30, 30)
	bar.BorderSizePixel        = 0
	bar.Parent                 = bg

	-- Atualiza a barra quando o HP muda
	hum:GetPropertyChangedSignal("Health"):Connect(function()
		local pct      = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
		bar.Size       = UDim2.new(pct, 0, 1, 0)
	end)

	-- Posiciona o zumbi
	model.Parent = workspace
	model:PivotTo(CFrame.new(spawnPos))

	return model
end

-- ── IA do zumbi ───────────────────────────────────────────────────────────────

local function runAI(model: Model, hum: Humanoid): ()
	task.spawn(function()
		local lastAttack = 0

		while hum.Health > 0 and model.Parent do
			local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
			if not hrp then break end

			local _, targetHRP = nearestPlayer(hrp.Position)
			if targetHRP then
				-- Move em direção ao jogador
				hum:MoveTo(targetHRP.Position)

				-- Ataca se estiver perto
				local dist = (targetHRP.Position - hrp.Position).Magnitude
				local now  = tick()

				if dist <= GameConfig.ZOMBIE_ATTACK_RANGE and now - lastAttack >= GameConfig.ZOMBIE_ATTACK_COOL then
					lastAttack = now
					-- Encontra o jogador para aplicar o dano
					for _, player in Players:GetPlayers() do
						local char = player.Character
						if char and char:FindFirstChild("HumanoidRootPart") == targetHRP then
							local playerHum = char:FindFirstChildOfClass("Humanoid")
							if playerHum and playerHum.Health > 0 then
								playerHum:TakeDamage(GameConfig.ZOMBIE_DAMAGE)
								-- Notifica o cliente do dano (efeito de tela)
								local hurtEvent = remotes:FindFirstChild(RemoteNames.PLAYER_HURT) :: RemoteEvent?
								if hurtEvent then hurtEvent:FireClient(player, GameConfig.ZOMBIE_DAMAGE) end
							end
							break
						end
					end
				end
			end

			task.wait(0.35)
		end
	end)
end

-- ── Gestão de ondas ───────────────────────────────────────────────────────────

local function onZombieDied(): ()
	zombiesAlive -= 1
	local updateEvent = remotes:FindFirstChild(RemoteNames.ZOMBIE_UPDATE) :: RemoteEvent?
	if updateEvent then updateEvent:FireAllClients(zombiesAlive, zombiesTotal) end

	if zombiesAlive > 0 then return end

	-- Onda concluída
	local completeEvent = remotes:FindFirstChild(RemoteNames.WAVE_COMPLETE) :: RemoteEvent?
	if completeEvent then completeEvent:FireAllClients(currentWave) end

	if currentWave >= MAX_WAVES then
		-- Vitória
		gameOver = true
		task.delay(2, function()
			local wonEvent = remotes:FindFirstChild(RemoteNames.GAME_WON) :: RemoteEvent?
			if wonEvent then wonEvent:FireAllClients() end
		end)
		return
	end

	-- Próxima onda após pausa
	waveRunning = false
	task.delay(GameConfig.WAVE_BREAK_SEC, function()
		if not gameOver then
			startWave(currentWave + 1)
		end
	end)
end

local zombieIdCounter = 0

function startWave(wave: number): ()
	if waveRunning or gameOver then return end
	waveRunning    = true
	currentWave    = wave
	local count    = GameConfig.WAVE_BASE_COUNT + (wave - 1) * GameConfig.WAVE_EXTRA_PER_WAVE
	zombiesAlive   = count
	zombiesTotal   = count

	-- Anuncia a onda aos clientes
	local startEvent = remotes:FindFirstChild(RemoteNames.WAVE_START) :: RemoteEvent?
	if startEvent then startEvent:FireAllClients(wave) end

	local updateEvent = remotes:FindFirstChild(RemoteNames.ZOMBIE_UPDATE) :: RemoteEvent?
	if updateEvent then updateEvent:FireAllClients(zombiesAlive, zombiesTotal) end

	-- Spawna os zumbis um a um, rotacionando pelos spawn points
	task.spawn(function()
		local spawnPoints = MapService.SPAWN_POINTS
		if #spawnPoints == 0 then
			warn("[EnemyService] Sem spawn points! MapService.SPAWN_POINTS está vazio.")
			return
		end

		for i = 1, count do
			if gameOver then break end
			spawnIndex = (spawnIndex % #spawnPoints) + 1
			local spawnPos = spawnPoints[spawnIndex]

			zombieIdCounter += 1
			local zombie = buildZombie(zombieIdCounter, spawnPos)
			local hum    = zombie:FindFirstChildOfClass("Humanoid")

			if hum then
				runAI(zombie, hum)
				hum.Died:Connect(function()
					task.delay(2.5, function()
						if zombie.Parent then zombie:Destroy() end
					end)
					onZombieDied()
				end)
			end

			task.wait(GameConfig.WAVE_SPAWN_INTERVAL)
		end
	end)
end

-- ── Dano validado pelo servidor ───────────────────────────────────────────────

local function onPlayerShoot(player: Player, zombieModel: unknown): ()
	if typeof(zombieModel) ~= "Instance" then return end
	if not zombieModel:IsA("Model") then return end
	if not (zombieModel :: Model).Name:match("^Zombie_") then return end

	local hum = (zombieModel :: Model):FindFirstChildOfClass("Humanoid")
	if hum and hum.Health > 0 then
		hum:TakeDamage(GameConfig.GUN_DAMAGE)
	end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function EnemyService.init(): ()
	remotes = ReplicatedStorage:WaitForChild("Remotes") :: Folder

	-- Aguarda o jogador fechar a intro para começar
	local introDoneEvent = remotes:WaitForChild(RemoteNames.INTRO_DONE) :: RemoteEvent
	introDoneEvent.OnServerEvent:Connect(function(_player: Player)
		if not waveRunning and not gameOver then
			task.delay(2, function() startWave(1) end)
		end
	end)

	-- Valida shots dos clientes
	local shootEvent = remotes:WaitForChild(RemoteNames.PLAYER_SHOOT) :: RemoteEvent
	shootEvent.OnServerEvent:Connect(onPlayerShoot)

	print("[EnemyService] Inicializado. Aguardando intro.")
end

return EnemyService
