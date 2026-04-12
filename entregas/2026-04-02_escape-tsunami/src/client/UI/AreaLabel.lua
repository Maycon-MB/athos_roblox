--!strict
-- AreaLabel — Overlay cinematográfico ao trocar de área.
-- Mostra nome da área com fade in/out ao receber TeleportArea.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local AreaLabel = {}

local player = Players.LocalPlayer

function AreaLabel.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "AreaLabel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 10
	gui.Parent = player:WaitForChild("PlayerGui")

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 80)
	label.Position = UDim2.new(0, 0, 0.35, 0)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.TextScaled = true
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeColor3 = Color3.new(0, 0, 0)
	label.TextStrokeTransparency = 0
	label.TextTransparency = 1
	label.Text = ""
	label.Parent = gui

	local R = require(RS.Shared.Remotes)
	local remote = RS:WaitForChild(R.TeleportArea) :: RemoteEvent

	remote.OnClientEvent:Connect(function(_areaName: string, areaLabel: string)
		label.Text = areaLabel or _areaName:upper()

		-- Fade in
		local fadeIn = TweenService:Create(label, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			TextTransparency = 0,
		})
		fadeIn:Play()
		fadeIn.Completed:Wait()

		task.wait(2)

		-- Fade out
		local fadeOut = TweenService:Create(label, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			TextTransparency = 1,
		})
		fadeOut:Play()
	end)
end

return AreaLabel
