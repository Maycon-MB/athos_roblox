--!strict
-- CinematicVFX — VFX de spoofing de velocidade.
-- Quando o player equipa um pulo de fake_speed alta (Caylus/Athos),
-- vendemos a ilusão de 2000+ studs/s mesmo com WalkSpeed real capada em 200:
--   • Camera.FieldOfView 70 → 115 (tween)
--   • ColorCorrection.Brightness leve para sensação de "rush"
--   • ParticleEmitter "SpeedLines" anexado ao HRP
-- Threshold = 1500 (cobre Caylus 2000 e Athos 2500; deixa Pdoro 600 / Matheus 800 fora).
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local M = {}

local VFX_THRESHOLD = 1500
local FOV_NORMAL = 70
local FOV_FAST = 115
local TWEEN_INFO = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local player = Players.LocalPlayer
local active = false
local cc: ColorCorrectionEffect? = nil

local function getOrCreateCC(): ColorCorrectionEffect
	if cc and cc.Parent then return cc end
	local existing = Lighting:FindFirstChild("CinematicVFX_CC")
	if existing and existing:IsA("ColorCorrectionEffect") then
		cc = existing
		return existing
	end
	local fresh = Instance.new("ColorCorrectionEffect")
	fresh.Name = "CinematicVFX_CC"
	fresh.Brightness = 0
	fresh.Contrast = 0
	fresh.Saturation = 0
	fresh.Parent = Lighting
	cc = fresh
	return fresh
end

local function attachSpeedLines(hrp: BasePart)
	for _, c in hrp:GetChildren() do
		if c:IsA("Attachment") and c.Name == "SpeedLinesFX" then c:Destroy() end
	end
	local att = Instance.new("Attachment")
	att.Name = "SpeedLinesFX"
	att.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "SpeedLines"
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 60
	pe.Lifetime = NumberRange.new(0.25, 0.45)
	pe.Speed = NumberRange.new(0)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1.8),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.2),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.Color = ColorSequence.new(Color3.fromRGB(220, 230, 255))
	pe.LightEmission = 0.4
	pe.LockedToPart = false
	pe.Parent = att
end

local function detachSpeedLines()
	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	for _, c in hrp:GetChildren() do
		if c:IsA("Attachment") and c.Name == "SpeedLinesFX" then c:Destroy() end
	end
end

local function activate()
	if active then return end
	active = true
	local cam = Workspace.CurrentCamera
	if cam then
		TweenService:Create(cam, TWEEN_INFO, { FieldOfView = FOV_FAST }):Play()
	end
	TweenService:Create(getOrCreateCC(), TWEEN_INFO, { Brightness = 0.1, Saturation = 0.15 }):Play()
	local char = player.Character
	if char then
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then attachSpeedLines(hrp) end
	end
end

local function deactivate()
	if not active then return end
	active = false
	local cam = Workspace.CurrentCamera
	if cam then
		TweenService:Create(cam, TWEEN_INFO, { FieldOfView = FOV_NORMAL }):Play()
	end
	TweenService:Create(getOrCreateCC(), TWEEN_INFO, { Brightness = 0, Saturation = 0 }):Play()
	detachSpeedLines()
end

function M.init()
	local jumpEquipped = RS:WaitForChild("JumpEquipped") :: RemoteEvent
	jumpEquipped.OnClientEvent:Connect(function(_jumpId: string, fakeSpeed: number)
		if fakeSpeed >= VFX_THRESHOLD then
			activate()
		else
			deactivate()
		end
	end)
	-- Reanexa SpeedLines após respawn (FOV/CC sobrevivem ao respawn)
	player.CharacterAdded:Connect(function(char)
		if not active then return end
		local hrp = char:WaitForChild("HumanoidRootPart", 5) :: BasePart?
		if hrp then attachSpeedLines(hrp) end
	end)
end

return M
