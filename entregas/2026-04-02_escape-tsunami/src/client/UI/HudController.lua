--!strict
-- HudController — Tier de pulo atual no canto inferior esquerdo.
-- Escuta: SyncData (Remote) → atualiza nome, jump, speed e cor do tier.
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local HudController = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)
local NAMES  = require(RS.Shared.Remotes)

local frame:    Frame
local lblName:  TextLabel
local lblStats: TextLabel

local function pulse()
	local big  = TweenInfo.new(0.10, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local norm = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	TweenService:Create(frame, big,  { Size = UDim2.new(0, 220, 0, 72) }):Play()
	task.delay(0.12, function()
		TweenService:Create(frame, norm, { Size = UDim2.new(0, 200, 0, 64) }):Play()
	end)
end

local function updateTier(jumpId: string?)
	if not jumpId or jumpId == "" then
		lblName.Text        = "sem pulo"
		lblName.TextColor3  = Color3.fromRGB(120, 120, 120)
		lblStats.Text       = ""
		return
	end
	for _, j in S.JUMPS do
		if j.id == jumpId then
			lblName.Text        = j.name
			lblName.TextColor3  = j.color
			lblStats.Text       = string.format("↑%d  ⚡%d", j.jump, j.speed)
			pulse()
			return
		end
	end
end

function HudController.init()
	local gui = Instance.new("ScreenGui")
	gui.Name           = "HudController"
	gui.ResetOnSpawn   = false
	gui.DisplayOrder   = 5
	gui.Parent         = player:WaitForChild("PlayerGui")

	frame = Instance.new("Frame")
	frame.Name                  = "TierFrame"
	frame.Size                  = UDim2.new(0, 200, 0, 64)
	frame.Position              = UDim2.new(0, 8, 1, -80)
	frame.BackgroundColor3      = Color3.fromRGB(16, 14, 24)
	frame.BackgroundTransparency = 0.18
	frame.BorderSizePixel       = 0
	frame.Parent                = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent       = frame

	-- Barra de cor lateral
	local badge = Instance.new("Frame")
	badge.Size             = UDim2.new(0, 5, 1, -8)
	badge.Position         = UDim2.new(0, 4, 0, 4)
	badge.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	badge.BorderSizePixel  = 0
	badge.Parent           = frame
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = badge

	lblName = Instance.new("TextLabel")
	lblName.Name                = "Name"
	lblName.Size                = UDim2.new(1, -18, 0.52, 0)
	lblName.Position            = UDim2.new(0, 14, 0, 4)
	lblName.BackgroundTransparency = 1
	lblName.Font                = Enum.Font.GothamBold
	lblName.TextScaled          = true
	lblName.TextXAlignment      = Enum.TextXAlignment.Left
	lblName.TextColor3          = Color3.fromRGB(120, 120, 120)
	lblName.Text                = "sem pulo"
	lblName.Parent              = frame

	lblStats = Instance.new("TextLabel")
	lblStats.Name               = "Stats"
	lblStats.Size               = UDim2.new(1, -18, 0.38, 0)
	lblStats.Position           = UDim2.new(0, 14, 0.54, 0)
	lblStats.BackgroundTransparency = 1
	lblStats.Font               = Enum.Font.Gotham
	lblStats.TextScaled         = true
	lblStats.TextXAlignment     = Enum.TextXAlignment.Left
	lblStats.TextColor3         = Color3.fromRGB(160, 160, 160)
	lblStats.Text               = ""
	lblStats.Parent             = frame

	local syncData = RS:WaitForChild(NAMES.SyncData) :: RemoteEvent
	syncData.OnClientEvent:Connect(function(data: any)
		if data and data.currentJump then
			updateTier(data.currentJump)
		end
	end)
end

return HudController
