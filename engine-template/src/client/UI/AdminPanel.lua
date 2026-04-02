--!strict
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local AdminPanel = {}

local player = Players.LocalPlayer

function AdminPanel.init()
	local gui = Instance.new("ScreenGui")
	gui.Name  = "AdminPanel"; gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent  = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size  = UDim2.new(0, 300, 0, 380)
	panel.Position = UDim2.new(0.5,-150,0.5,-190)
	panel.BackgroundColor3 = Color3.fromRGB(12,10,20)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0; panel.Parent = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,14); pc.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size  = UDim2.new(1,-48,0,44)
	title.BackgroundTransparency = 1
	title.Font  = Enum.Font.GothamBold; title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255,80,80); title.Text = "ADMIN PANEL"
	title.Parent = panel

	local close = Instance.new("TextButton")
	close.Size  = UDim2.new(0,36,0,36); close.Position = UDim2.new(1,-44,0,4)
	close.BackgroundColor3 = Color3.fromRGB(200,50,50); close.BorderSizePixel = 0
	close.Font  = Enum.Font.GothamBold; close.TextScaled = true
	close.TextColor3 = Color3.new(1,1,1); close.Text = "X"; close.Parent = panel
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,7); cc.Parent = close
	close.MouseButton1Click:Connect(function() gui.Enabled = false end)

	local log = Instance.new("TextLabel")
	log.Name  = "Log"
	log.Size  = UDim2.new(1,-16,0,24); log.Position = UDim2.new(0,8,1,-30)
	log.BackgroundTransparency = 1
	log.Font  = Enum.Font.Gotham; log.TextScaled = true
	log.TextColor3 = Color3.fromRGB(120,255,120); log.Text = ""; log.Parent = panel

	local list = Instance.new("Frame")
	list.Size  = UDim2.new(1,-16,1,-80); list.Position = UDim2.new(0,8,0,50)
	list.BackgroundTransparency = 1; list.Parent = panel
	local lay = Instance.new("UIListLayout"); lay.Padding = UDim.new(0,6); lay.Parent = list

	local R       = require(RS.Shared.Remotes)
	local cmdRemote = RS:WaitForChild(R.AdminCmd) :: RemoteEvent
	local resp    = RS:WaitForChild(R.AdminResp)  :: RemoteEvent

	local btns = {
		{ label = "Wave",       cmd = "wave"       },
		{ label = "Fast Wave",  cmd = "fast_wave"  },
		{ label = "Kill All",   cmd = "kill_all"   },
		{ label = "Max Money",  cmd = "give_money" },
		{ label = "List Players",cmd = "list"      },
	}
	for _, b in btns do
		local btn = Instance.new("TextButton")
		btn.Size  = UDim2.new(1,0,0,46)
		btn.BackgroundColor3 = Color3.fromRGB(38,32,58)
		btn.BorderSizePixel  = 0
		btn.Font  = Enum.Font.GothamBold; btn.TextScaled = true
		btn.TextColor3 = Color3.new(1,1,1); btn.Text = b.label
		btn.Parent = list
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = btn
		local cmd = b.cmd
		btn.MouseButton1Click:Connect(function()
			cmdRemote:FireServer(cmd, "")
		end)
	end

	resp.OnClientEvent:Connect(function(kind: string, msg: string?)
		if kind == "toggle" then
			gui.Enabled = not gui.Enabled
		elseif kind == "ok" then
			log.Text = msg or "OK"
		elseif kind == "list" then
			log.Text = msg or ""
		end
	end)
end

return AdminPanel
