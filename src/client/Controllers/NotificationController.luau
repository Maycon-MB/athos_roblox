--!strict

-- Módulo 6 — UX: popup de recompensa do Wheel Spin
-- Recebe o RemoteEvent WHEEL_REWARD e mostra notificação animada na tela

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteNames")
)

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local NotificationController = {}

-- Paleta de cores por tipo de recompensa
local COLORS: { [string]: Color3 } = {
	["50 Coins"]  = Color3.fromRGB(255, 210, 60),
	["100 Coins"] = Color3.fromRGB(255, 195, 20),
	["200 Coins"] = Color3.fromRGB(255, 170, 0),
	["Rare Egg"]  = Color3.fromRGB(80,  200, 255),
	["Epic Pet"]  = Color3.fromRGB(220, 80,  255),
}
local DEFAULT_COLOR  = Color3.fromRGB(200, 200, 200)
local COOLDOWN_COLOR = Color3.fromRGB(180, 60,  60)

local function isCooldown(label: string): boolean
	return label:sub(1, 8) == "Cooldown"
end

local function showNotification(label: string): ()
	-- Determina cor
	local accent = if isCooldown(label)
		then COOLDOWN_COLOR
		else (COLORS[label] or DEFAULT_COLOR)

	-- ScreenGui temporária (destruída automaticamente após a animação)
	local gui        = Instance.new("ScreenGui")
	gui.Name         = "WheelNotif"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent       = playerGui

	-- Frame principal — começa fora da tela (baixo) e sobe
	local frame         = Instance.new("Frame")
	frame.Name          = "NotifFrame"
	frame.Size          = UDim2.new(0, 320, 0, 72)
	frame.AnchorPoint   = Vector2.new(0.5, 1)
	frame.Position      = UDim2.new(0.5, 0, 1.15, 0)  -- abaixo da tela
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 22)
	frame.BorderSizePixel  = 0
	frame.Parent        = gui

	local corner        = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = frame

	-- Barra de cor no topo
	local bar           = Instance.new("Frame")
	bar.Name            = "AccentBar"
	bar.Size            = UDim2.new(1, 0, 0, 4)
	bar.Position        = UDim2.new(0, 0, 0, 0)
	bar.BackgroundColor3 = accent
	bar.BorderSizePixel  = 0
	bar.Parent          = frame

	local barCorner         = Instance.new("UICorner")
	barCorner.CornerRadius  = UDim.new(0, 10)
	barCorner.Parent        = bar

	-- Ícone da roda (texto simples)
	local icon          = Instance.new("TextLabel")
	icon.Name           = "Icon"
	icon.Size           = UDim2.new(0, 50, 1, -8)
	icon.Position       = UDim2.new(0, 8, 0, 4)
	icon.BackgroundTransparency = 1
	icon.Text           = if isCooldown(label) then "!" else "*"
	icon.TextColor3     = accent
	icon.TextScaled     = true
	icon.Font           = Enum.Font.GothamBold
	icon.Parent         = frame

	-- Linha de título
	local title         = Instance.new("TextLabel")
	title.Name          = "Title"
	title.Size          = UDim2.new(1, -70, 0, 22)
	title.Position      = UDim2.new(0, 60, 0, 10)
	title.BackgroundTransparency = 1
	title.Text          = if isCooldown(label) then "WHEEL SPIN" else "WHEEL SPIN"
	title.TextColor3    = Color3.fromRGB(160, 160, 165)
	title.TextScaled    = false
	title.TextSize      = 11
	title.Font          = Enum.Font.Gotham
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent        = frame

	-- Linha da recompensa
	local reward        = Instance.new("TextLabel")
	reward.Name         = "RewardLabel"
	reward.Size         = UDim2.new(1, -70, 0, 28)
	reward.Position     = UDim2.new(0, 60, 0, 30)
	reward.BackgroundTransparency = 1
	reward.Text         = label
	reward.TextColor3   = accent
	reward.TextScaled   = false
	reward.TextSize     = 18
	reward.Font         = Enum.Font.GothamBold
	reward.TextXAlignment = Enum.TextXAlignment.Left
	reward.Parent       = frame

	-- Animação: slide para cima
	local slideIn = TweenService:Create(frame,
		TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.new(0.5, 0, 0.9, 0) }
	)
	slideIn:Play()
	slideIn.Completed:Wait()

	-- Pausa visível
	task.wait(if isCooldown(label) then 1.5 else 2.2)

	-- Fade out
	local fadeOut = TweenService:Create(frame,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ Position = UDim2.new(0.5, 0, 1.15, 0),
		  BackgroundTransparency = 1 }
	)
	-- Fade labels também
	TweenService:Create(reward,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }):Play()
	TweenService:Create(title,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }):Play()
	TweenService:Create(icon,
		TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ TextTransparency = 1 }):Play()

	fadeOut:Play()
	fadeOut.Completed:Wait()

	gui:Destroy()
end

function NotificationController.init(): ()
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local event   = remotes:WaitForChild(RemoteNames.WHEEL_REWARD) :: RemoteEvent

	event.OnClientEvent:Connect(function(label: string)
		task.spawn(showNotification, label)
	end)

	print("[NotificationController] Pronto.")
end

return NotificationController
