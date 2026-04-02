--!strict
-- Abre quando player fica < 10 studs de uma peça tagueada "WaveMachine".
local Players           = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService        = game:GetService("RunService")
local RS                = game:GetService("ReplicatedStorage")
local WaveMachinePanel = {}

local player = Players.LocalPlayer
local tokens = 0

function WaveMachinePanel.init()
	local gui = Instance.new("ScreenGui")
	gui.Name  = "WaveMachinePanel"; gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent  = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size  = UDim2.new(0, 300, 0, 290)
	panel.Position = UDim2.new(0.5,-150,0.5,-145)
	panel.BackgroundColor3 = Color3.fromRGB(12, 18, 38)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0; panel.Parent = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,14); pc.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size  = UDim2.new(1,-48,0,44)
	title.BackgroundTransparency = 1
	title.Font  = Enum.Font.GothamBold; title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(80,180,255); title.Text = "WAVE MACHINE"
	title.Parent = panel

	local tokenLbl = Instance.new("TextLabel")
	tokenLbl.Name  = "Tokens"
	tokenLbl.Size  = UDim2.new(1,0,0,24); tokenLbl.Position = UDim2.new(0,0,0,44)
	tokenLbl.BackgroundTransparency = 1
	tokenLbl.Font  = Enum.Font.Gotham; tokenLbl.TextScaled = true
	tokenLbl.TextColor3 = Color3.fromRGB(180,220,255)
	tokenLbl.Text  = "~ 0"; tokenLbl.Parent = panel

	local close = Instance.new("TextButton")
	close.Size   = UDim2.new(0,34,0,34); close.Position = UDim2.new(1,-42,0,5)
	close.BackgroundColor3 = Color3.fromRGB(200,50,50); close.BorderSizePixel = 0
	close.Font   = Enum.Font.GothamBold; close.TextScaled = true
	close.TextColor3 = Color3.new(1,1,1); close.Text = "X"; close.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,7); cc.Parent = close
	close.MouseButton1Click:Connect(function() gui.Enabled = false end)

	local R  = require(RS.Shared.Remotes)
	local ut = RS:WaitForChild(R.UseWaveToken) :: RemoteEvent

	local list = Instance.new("Frame")
	list.Size  = UDim2.new(1,-16,1,-76); list.Position = UDim2.new(0,8,0,72)
	list.BackgroundTransparency = 1; list.Parent = panel
	local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0,8); lay.Parent = list

	local waves = {
		{ label = "Wave  [1~]",       speed = "40",  cost = 1  },
		{ label = "Fast Wave  [5~]",  speed = "70",  cost = 5  },
		{ label = "Mega Wave  [10~]", speed = "100", cost = 10 },
	}
	for _, w in waves do
		local btn = Instance.new("TextButton")
		btn.Size  = UDim2.new(1,0,0,56)
		btn.BackgroundColor3 = Color3.fromRGB(18,55,110)
		btn.BorderSizePixel  = 0
		btn.Font  = Enum.Font.GothamBold; btn.TextScaled = true
		btn.TextColor3 = Color3.new(1,1,1); btn.Text = w.label
		btn.Parent = list
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = btn
		local spd = w.speed
		btn.MouseButton1Click:Connect(function()
			ut:FireServer(spd)
			gui.Enabled = false
		end)
	end

	-- Sync tokens
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		tokens = d.waveTokens or 0
		tokenLbl.Text = "~ " .. tokens
	end)

	-- Proximity check
	RunService.Heartbeat:Connect(function()
		local char = player.Character; if not char then return end
		local hrp  = char:FindFirstChild("HumanoidRootPart") :: BasePart?; if not hrp then return end
		local near = false
		for _, part in CollectionService:GetTagged("WaveMachine") do
			if part:IsA("BasePart") and (hrp.Position - (part :: BasePart).Position).Magnitude < 10 then
				near = true; break
			end
		end
		if near ~= gui.Enabled then gui.Enabled = near end
	end)
end

return WaveMachinePanel
