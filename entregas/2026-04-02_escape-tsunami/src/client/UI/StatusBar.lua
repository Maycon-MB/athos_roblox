--!strict
-- StatusBar — Painel de recursos no canto inferior esquerdo.
-- Replica o layout do HUD original (Escape Waves For Brainmodz).
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local StatusBar = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

local lblIncome: TextLabel
local lblBR:     TextLabel
local lblMoney:  TextLabel
local lblTokens: TextLabel
local lblJump:   TextLabel

local function fmt(n: number): string
	if n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

local function incomePerSec(brainrots: any): number
	local total = 0
	for _, entry in brainrots do
		for _, br in S.BRAINROTS do
			if br.id == entry.id then
				total += br.income * entry.qty
				break
			end
		end
	end
	return total
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

local function makeRow(parent: Frame, icon: string, iconCol: Color3): TextLabel
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 28)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size = UDim2.new(0, 24, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Font = Enum.Font.GothamBold
	iconLbl.TextScaled = true
	iconLbl.TextColor3 = iconCol
	iconLbl.Text = icon
	iconLbl.Parent = row

	local valLbl = Instance.new("TextLabel")
	valLbl.Size = UDim2.new(1, -28, 1, 0)
	valLbl.Position = UDim2.new(0, 28, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font = Enum.Font.GothamBold
	valLbl.TextScaled = true
	valLbl.TextXAlignment = Enum.TextXAlignment.Left
	valLbl.TextColor3 = Color3.new(1, 1, 1)
	valLbl.TextStrokeTransparency = 0.4
	valLbl.Text = "0"
	valLbl.Parent = row
	return valLbl
end

function StatusBar.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "StatusBar"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 3
	gui.Parent = player:WaitForChild("PlayerGui")

	-- Painel principal — canto inferior esquerdo
	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 210, 0, 170)
	panel.Position = UDim2.new(0, 8, 1, -188)
	panel.BackgroundColor3 = Color3.fromRGB(20, 18, 28)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel
	local pp = Instance.new("UIPadding")
	pp.PaddingLeft = UDim.new(0, 8)
	pp.PaddingRight = UDim.new(0, 8)
	pp.PaddingTop = UDim.new(0, 6)
	pp.PaddingBottom = UDim.new(0, 6)
	pp.Parent = panel

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Parent = panel

	-- Income/s no topo (verde — como o jogo original)
	lblIncome = Instance.new("TextLabel")
	lblIncome.LayoutOrder = 0
	lblIncome.Size = UDim2.new(1, 0, 0, 22)
	lblIncome.BackgroundColor3 = Color3.fromRGB(18, 40, 18)
	lblIncome.BackgroundTransparency = 0.3
	lblIncome.BorderSizePixel = 0
	lblIncome.Font = Enum.Font.GothamBold
	lblIncome.TextScaled = true
	lblIncome.TextXAlignment = Enum.TextXAlignment.Center
	lblIncome.TextColor3 = Color3.fromRGB(80, 230, 80)
	lblIncome.Text = "$0/s"
	lblIncome.Parent = panel
	local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0, 6); ic.Parent = lblIncome

	-- Separador
	local sep = Instance.new("Frame")
	sep.LayoutOrder = 1
	sep.Size = UDim2.new(1, 0, 0, 1)
	sep.BackgroundColor3 = Color3.fromRGB(60, 55, 80)
	sep.BorderSizePixel = 0
	sep.Parent = panel

	-- Linhas de recursos
	local rows = Instance.new("Frame")
	rows.LayoutOrder = 2
	rows.Size = UDim2.new(1, 0, 0, 124)
	rows.BackgroundTransparency = 1
	rows.Parent = panel
	local rl = Instance.new("UIListLayout")
	rl.Padding = UDim.new(0, 3)
	rl.SortOrder = Enum.SortOrder.LayoutOrder
	rl.Parent = rows

	lblBR     = makeRow(rows, "🟠", Color3.fromRGB(255, 160, 60))
	lblMoney  = makeRow(rows, "🟢", Color3.fromRGB(60, 220, 60))
	lblTokens = makeRow(rows, "⚡", Color3.fromRGB(80, 200, 255))
	lblJump   = makeRow(rows, "👟", Color3.fromRGB(200, 200, 200))

	local R    = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		local brs: any = d.brainrots or {}
		local total = 0
		for _, e in brs do total += e.qty end

		local inc = incomePerSec(brs)
		lblIncome.Text = "$" .. fmt(inc) .. "/s"
		lblBR.Text     = total .. "/" .. tostring(d.baseSlots or 4) .. " BR"
		lblMoney.Text  = "$" .. fmt(d.money or 0)
		lblTokens.Text = "⚡" .. tostring(d.waveTokens or 0)

		local jid = d.currentJump or "none"
		lblJump.Text       = jumpName(jid)
		lblJump.TextColor3 = jumpColor(jid)
	end)
end

return StatusBar
