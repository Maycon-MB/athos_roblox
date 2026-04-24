--!strict
-- FakeButtons — Botões decorativos do HUD original (canto superior esquerdo).
-- Apenas visuais para a gravação cinematográfica. Cores e ícones imitam o
-- jogo "Steal a Brainrot" (Store/Trade/Index/V.I.P/Rebirth/Invite + Slow).
local Players = game:GetService("Players")
local FakeButtons = {}

local player = Players.LocalPlayer

-- { label, icon emoji, cor de fundo do ícone }
type Btn = { label: string, icon: string, color: Color3 }

local ROWS: { { Btn } } = {
	{
		{ label = "Store",      icon = "🛒", color = Color3.fromRGB(255, 130, 30) },
		{ label = "Trade",      icon = "💗", color = Color3.fromRGB(220, 70, 130) },
	},
	{
		{ label = "Index",      icon = "📕", color = Color3.fromRGB(220, 60, 60) },
		{ label = "V.I.P",      icon = "💎", color = Color3.fromRGB(80, 180, 255) },
	},
	{
		{ label = "Rebirth[0]", icon = "🔁", color = Color3.fromRGB(255, 80, 80) },
		{ label = "Invite",     icon = "✉️", color = Color3.fromRGB(255, 200, 80) },
	},
}

local function corner(p: Instance, r: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end

local function makeBtn(parent: Frame, b: Btn)
	local f = Instance.new("Frame")
	f.Size                 = UDim2.new(0, 78, 0, 28)
	f.BackgroundColor3     = Color3.fromRGB(245, 240, 230)
	f.BorderSizePixel      = 0
	f.Parent               = parent
	corner(f, 6)
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0); stroke.Thickness = 1.5
	stroke.Parent = f

	local iconBox = Instance.new("Frame")
	iconBox.Size                 = UDim2.new(0, 24, 0, 24)
	iconBox.Position             = UDim2.new(0, 2, 0, 2)
	iconBox.BackgroundColor3     = b.color
	iconBox.BorderSizePixel      = 0
	iconBox.Parent               = f
	corner(iconBox, 4)

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size                 = UDim2.new(1, 0, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Font                 = Enum.Font.GothamBold
	iconLbl.TextScaled           = true
	iconLbl.Text                 = b.icon
	iconLbl.Parent               = iconBox

	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.new(1, -30, 1, 0)
	lbl.Position             = UDim2.new(0, 28, 0, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font                 = Enum.Font.FredokaOne
	lbl.TextScaled           = true
	lbl.TextColor3           = Color3.fromRGB(40, 30, 20)
	lbl.Text                 = b.label
	lbl.Parent               = f
end

function FakeButtons.init()
	local gui = Instance.new("ScreenGui")
	gui.Name         = "FakeButtons"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2
	gui.Parent       = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size                 = UDim2.new(0, 168, 0, 130)
	panel.Position             = UDim2.new(0, 8, 0, 8)
	panel.BackgroundTransparency = 1
	panel.Parent               = gui

	local layout = Instance.new("UIListLayout")
	layout.Padding   = UDim.new(0, 4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent    = panel

	for _, row in ROWS do
		local rowFrame = Instance.new("Frame")
		rowFrame.Size                 = UDim2.new(1, 0, 0, 28)
		rowFrame.BackgroundTransparency = 1
		rowFrame.Parent               = panel
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding       = UDim.new(0, 4)
		rl.Parent        = rowFrame
		for _, b in row do
			makeBtn(rowFrame, b)
		end
	end

	-- [T] Slow: ON
	local slowFrame = Instance.new("Frame")
	slowFrame.Size                 = UDim2.new(1, 0, 0, 22)
	slowFrame.BackgroundColor3     = Color3.fromRGB(40, 32, 18)
	slowFrame.BorderSizePixel      = 0
	slowFrame.Parent               = panel
	corner(slowFrame, 5)
	local stroke2 = Instance.new("UIStroke")
	stroke2.Color = Color3.fromRGB(0, 0, 0); stroke2.Thickness = 1.5
	stroke2.Parent = slowFrame

	local slowLbl = Instance.new("TextLabel")
	slowLbl.Size                 = UDim2.new(1, 0, 1, 0)
	slowLbl.BackgroundTransparency = 1
	slowLbl.Font                 = Enum.Font.FredokaOne
	slowLbl.TextScaled           = true
	slowLbl.TextColor3           = Color3.fromRGB(255, 220, 80)
	slowLbl.Text                 = "[T] Slow: ON"
	slowLbl.Parent               = slowFrame
end

return FakeButtons
