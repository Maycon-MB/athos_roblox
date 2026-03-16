--!strict

--[[
	CombatController — Combate por Raycast

	Diferenças da versão antiga (bola de fogo):
	  • Raycast a partir da câmera (mira precisa e instantânea)
	  • Trilha visual do projétil (beam de partículas)
	  • Flash de muzzle no braço direito
	  • Hit validado no servidor via RemoteEvent
	  • Disparo com clique do mouse OU tecla F
	  • Animação de recuo do braço
]]

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local TweenService      = game:GetService("TweenService")
local Debris            = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared      = ReplicatedStorage:WaitForChild("Shared")
local GameConfig  = require(Shared:WaitForChild("GameConfig"))
local RemoteNames = require(Shared:WaitForChild("RemoteNames"))

local player = Players.LocalPlayer

local CombatController = {}

local lastShot    = 0
local shootRemote: RemoteEvent?

-- ── Modelo da arma ────────────────────────────────────────────────────────────

local function attachGun(character: Model): ()
	local rArm = (character:FindFirstChild("Right Arm") or character:FindFirstChild("RightHand")) :: BasePart?
	if not rArm then return end

	local old = rArm:FindFirstChild("Gun")
	if old then old:Destroy() end

	local gun      = Instance.new("Model")
	gun.Name       = "Gun"
	gun.Parent     = rArm

	local dark  = Color3.fromRGB(25,  25,  25)
	local metal = Color3.fromRGB(70,  70,  75)
	local glow  = Color3.fromRGB(200, 30,  30)

	local function gp(name: string, size: Vector3, color: Color3, offset: Vector3): Part
		local pt         = Instance.new("Part")
		pt.Name          = name
		pt.Size          = size
		pt.Color         = color
		pt.Material      = Enum.Material.SmoothPlastic
		pt.Anchored      = false
		pt.CanCollide    = false
		pt.CastShadow    = false
		pt.Parent        = gun
		local w  = Instance.new("WeldConstraint")
		w.Part0  = rArm; w.Part1 = pt; w.Parent = rArm
		pt.CFrame = rArm.CFrame * CFrame.new(offset)
		return pt
	end

	gp("Body",    Vector3.new(0.3,  0.5, 1.2), dark,  Vector3.new(0, -0.4,  -0.8))
	gp("Barrel",  Vector3.new(0.14, 0.14, 1.0), metal, Vector3.new(0, -0.15, -1.5))
	gp("Handle",  Vector3.new(0.22, 0.7, 0.28), dark,  Vector3.new(0, -0.85, -0.6))
	gp("Trigger", Vector3.new(0.08, 0.25, 0.12), metal, Vector3.new(0, -0.65, -0.75))

	local tip      = gp("Tip", Vector3.new(0.18, 0.18, 0.08), glow, Vector3.new(0, -0.15, -2.05))
	tip.Material   = Enum.Material.Neon

	-- Luz na ponta da arma
	local l        = Instance.new("PointLight")
	l.Color        = glow
	l.Brightness   = 1.5
	l.Range        = 6
	l.Parent       = tip
end

-- ── Recuo do braço ────────────────────────────────────────────────────────────

local function playRecoil(character: Model): ()
	local torso = character:FindFirstChild("Torso") :: BasePart?
	if not torso then return end
	local rShoulder = torso:FindFirstChild("Right Shoulder") :: Motor6D?
	if not rShoulder then return end
	local orig = rShoulder.C0
	TweenService:Create(rShoulder, TweenInfo.new(0.05), { C0 = orig * CFrame.Angles(-math.rad(25), 0, 0) }):Play()
	task.delay(0.1, function()
		TweenService:Create(rShoulder, TweenInfo.new(0.12), { C0 = orig * CFrame.Angles(math.rad(8), 0, 0) }):Play()
	end)
	task.delay(0.22, function()
		TweenService:Create(rShoulder, TweenInfo.new(0.1), { C0 = orig }):Play()
	end)
end

-- ── Muzzle flash ─────────────────────────────────────────────────────────────

local function muzzleFlash(origin: Vector3): ()
	local flash          = Instance.new("Part")
	flash.Size           = Vector3.new(0.5, 0.5, 0.5)
	flash.Shape          = Enum.PartType.Ball
	flash.Color          = Color3.fromRGB(255, 220, 100)
	flash.Material       = Enum.Material.Neon
	flash.Anchored       = true
	flash.CanCollide     = false
	flash.CastShadow     = false
	flash.Position       = origin
	flash.Parent         = workspace

	local l              = Instance.new("PointLight")
	l.Color              = Color3.fromRGB(255, 200, 80)
	l.Brightness         = 10
	l.Range              = 14
	l.Parent             = flash

	TweenService:Create(flash, TweenInfo.new(0.07), {
		Size = Vector3.new(0.05, 0.05, 0.05),
		Transparency = 1,
	}):Play()
	Debris:AddItem(flash, 0.1)
end

-- ── Trilha do projétil ────────────────────────────────────────────────────────

local function bulletTrail(from: Vector3, to: Vector3): ()
	local dir    = (to - from)
	local dist   = dir.Magnitude
	if dist < 0.1 then return end
	local mid    = from + dir * 0.5

	local beam         = Instance.new("Part")
	beam.Size          = Vector3.new(0.06, 0.06, dist)
	beam.CFrame        = CFrame.lookAt(mid, to)
	beam.Color         = Color3.fromRGB(255, 240, 160)
	beam.Material      = Enum.Material.Neon
	beam.Anchored      = true
	beam.CanCollide    = false
	beam.CastShadow    = false
	beam.Parent        = workspace

	TweenService:Create(beam, TweenInfo.new(0.1), { Transparency = 1 }):Play()
	Debris:AddItem(beam, 0.12)
end

-- ── Efeito de impacto ─────────────────────────────────────────────────────────

local function hitEffect(pos: Vector3): ()
	local e            = Instance.new("Part")
	e.Size             = Vector3.new(0.9, 0.9, 0.9)
	e.Shape            = Enum.PartType.Ball
	e.Color            = Color3.fromRGB(255, 80, 0)
	e.Material         = Enum.Material.Neon
	e.Anchored         = true
	e.CanCollide       = false
	e.CastShadow       = false
	e.Position         = pos
	e.Parent           = workspace

	TweenService:Create(e, TweenInfo.new(0.18), {
		Size = Vector3.new(0.05, 0.05, 0.05),
		Transparency = 1,
	}):Play()
	Debris:AddItem(e, 0.2)
end

-- ── Disparo (Raycast) ─────────────────────────────────────────────────────────

local function shoot(): ()
	local now = tick()
	if now - lastShot < GameConfig.GUN_COOLDOWN then return end
	lastShot = now

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- Origem: tip da arma (aproximado como camera position deslocado)
	local camera    = workspace.CurrentCamera
	local origin    = camera.CFrame.Position
	local direction = camera.CFrame.LookVector * GameConfig.GUN_RANGE

	-- Raycast excluindo o personagem local
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = { char }
	params.FilterType                 = Enum.RaycastFilterType.Exclude

	local result = workspace:Raycast(origin, direction, params)
	local hitPos = if result then result.Position else (origin + direction)

	-- Origem visual (ponta da arma)
	local visualOrigin = hrp.Position + Vector3.new(0, 1.2, 0)
	muzzleFlash(visualOrigin)
	bulletTrail(visualOrigin, hitPos)
	playRecoil(char)

	-- Hit em zumbi
	if result then
		local inst  = result.Instance
		local model = inst:FindFirstAncestorOfClass("Model")
		if model and model.Name:match("^Zombie_") then
			hitEffect(hitPos)
			if shootRemote then shootRemote:FireServer(model) end
		end
	end
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function CombatController.init(): ()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	shootRemote   = remotes:WaitForChild(RemoteNames.PLAYER_SHOOT) :: RemoteEvent

	-- Anexa arma ao personagem
	player.CharacterAdded:Connect(function(char: Model)
		task.wait(1.2)
		attachGun(char)
	end)
	if player.Character then
		task.delay(1.2, function()
			if player.Character then attachGun(player.Character) end
		end)
	end

	-- Disparo: clique esquerdo do mouse
	UserInputService.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then return end
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.KeyCode == Enum.KeyCode.F then
			shoot()
		end
	end)

	print("[CombatController] Inicializado. Clique ou F para atirar.")
end

return CombatController
