--!strict
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local StatusBar = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

local lblMoney: TextLabel
local lblBR:    TextLabel
local lblJump:  TextLabel
local lblToken: TextLabel

local function fmt(n: number): string
	if n >= 1e9 then return string.format("%.1fB", n/1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n/1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n/1e3)
	else return tostring(math.floor(n)) end
end

local function jumpColor(id: string): Color3
	for _, j in S.JUMPS do if j.id == id then return j.color end end
	return Color3.fromRGB(180, 180, 180)
end

local function jumpName(id: string): string
	if id == "none" then return "Default" end
	for _, j in S.JUMPS do if j.id == id then return j.name end end
	return id
end

local function statBox(bar: Frame, icon: string, iconCol: Color3, w: number): TextLabel
	local f = Instance.new("Frame")
	f.Size  = UDim2.new(0, w, 0, 52)
	f.BackgroundColor3 = Color3.fromRGB(25, 18, 8)
	f.BackgroundTransparency = 0.25
	f.BorderSizePixel = 0; f.Parent = bar
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 10); c.Parent = f

	local iL = Instance.new("TextLabel")
	iL.Size  = UDim2.new(0, 32, 1, 0)
	iL.BackgroundTransparency = 1
	iL.Font  = Enum.Font.GothamBold; iL.TextScaled = true
	iL.TextColor3 = iconCol; iL.Text = icon; iL.Parent = f

	local vL = Instance.new("TextLabel")
	vL.Size  = UDim2.new(1, -34, 1, 0); vL.Position = UDim2.new(0, 34, 0, 0)
	vL.BackgroundTransparency = 1
	vL.Font  = Enum.Font.GothamBold; vL.TextScaled = true
	vL.TextColor3 = Color3.new(1,1,1); vL.TextStrokeTransparency = 0.35
	vL.Text  = "0"; vL.Parent = f
	return vL
end

function StatusBar.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "StatusBar"; gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local bar = Instance.new("Frame")
	bar.Size  = UDim2.new(0, 530, 0, 64)
	bar.Position = UDim2.new(0.5, -265, 1, -76)
	bar.BackgroundColor3 = Color3.fromRGB(195, 95, 15)
	bar.BackgroundTransparency = 0.08
	bar.BorderSizePixel = 0; bar.Parent = gui
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 14); bc.Parent = bar

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.Padding = UDim.new(0, 6)
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.Parent = bar
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8); pad.Parent = bar

	lblMoney = statBox(bar, "$",  Color3.fromRGB(255,230,60),  120)
	lblBR    = statBox(bar, "BR", Color3.fromRGB(200,160,255), 110)
	lblJump  = statBox(bar, "👟", Color3.new(1,1,1),           155)
	lblToken = statBox(bar, "~",  Color3.fromRGB(80,200,255),  110)

	local R    = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		lblMoney.Text = "$" .. fmt(d.money or 0)
		local tot = 0
		for _, e in (d.brainrots or {}) do tot += e.qty end
		lblBR.Text   = tot .. "/" .. tostring(d.baseSlots or 4)
		local jid    = d.currentJump or "none"
		lblJump.Text = jumpName(jid)
		lblJump.TextColor3 = jumpColor(jid)
		lblToken.Text = "~" .. tostring(d.waveTokens or 0)
	end)
end

return StatusBar
