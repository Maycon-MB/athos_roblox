--!strict
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local WaveAlert = {}

local player = Players.LocalPlayer

function WaveAlert.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "WaveAlert"; gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local lbl = Instance.new("TextLabel")
	lbl.Size  = UDim2.new(0, 420, 0, 62)
	lbl.Position = UDim2.new(0.5, -210, 0, 80)
	lbl.BackgroundColor3 = Color3.fromRGB(200, 40, 20)
	lbl.BackgroundTransparency = 0.15
	lbl.BorderSizePixel = 0
	lbl.Font  = Enum.Font.GothamBold; lbl.TextScaled = true
	lbl.TextColor3 = Color3.new(1,1,1); lbl.TextStrokeTransparency = 0
	lbl.Text  = "TSUNAMI INCOMING!"; lbl.Visible = false; lbl.Parent = gui
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = lbl

	local R = require(RS.Shared.Remotes)

	local started = RS:WaitForChild(R.WaveStarted) :: RemoteEvent
	started.OnClientEvent:Connect(function(n: number)
		lbl.BackgroundColor3 = Color3.fromRGB(200, 40, 20)
		lbl.Text    = "TSUNAMI #" .. n .. "!"
		lbl.Visible = true
		task.delay(3, function() lbl.Visible = false end)
	end)

	local survived = RS:WaitForChild(R.WaveSurvived) :: RemoteEvent
	survived.OnClientEvent:Connect(function()
		lbl.BackgroundColor3 = Color3.fromRGB(30, 160, 60)
		lbl.Text    = "SURVIVED!"
		lbl.Visible = true
		task.delay(2, function()
			lbl.BackgroundColor3 = Color3.fromRGB(200, 40, 20)
			lbl.Visible = false
		end)
	end)
end

return WaveAlert
