--!strict
-- FakeButtons — Botões decorativos do HUD original no canto superior esquerdo.
-- Apenas visuais para a gravação (Store/Trade/Index/VIP/Rebirth/Invite).
local Players = game:GetService("Players")
local FakeButtons = {}

local player = Players.LocalPlayer

local ROWS = {
	{ "Store",       "Trade"  },
	{ "Index",       "V.I.P"  },
	{ "Rebirth[0]",  "Invite" },
}

local function makeBtn(parent: Frame, text: string)
	local f = Instance.new("Frame")
	f.Size = UDim2.new(0, 72, 0, 26)
	f.BackgroundColor3 = Color3.fromRGB(35, 30, 48)
	f.BorderSizePixel = 0
	f.Parent = parent
	local fc = Instance.new("UICorner"); fc.CornerRadius = UDim.new(0, 5); fc.Parent = f
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 70, 110)
	stroke.Thickness = 1
	stroke.Parent = f
	local lbl = Instance.new("TextLabel")
	lbl.Size = UDim2.new(1, 0, 1, 0)
	lbl.BackgroundTransparency = 1
	lbl.Font = Enum.Font.GothamBold
	lbl.TextScaled = true
	lbl.TextColor3 = Color3.fromRGB(220, 210, 255)
	lbl.Text = text
	lbl.Parent = f
end

function FakeButtons.init()
	local gui = Instance.new("ScreenGui")
	gui.Name = "FakeButtons"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 2
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 152, 0, 120)
	panel.Position = UDim2.new(0, 8, 0, 8)
	panel.BackgroundTransparency = 1
	panel.Parent = gui

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = panel

	for _, row in ROWS do
		local rowFrame = Instance.new("Frame")
		rowFrame.Size = UDim2.new(1, 0, 0, 26)
		rowFrame.BackgroundTransparency = 1
		rowFrame.Parent = panel
		local rl = Instance.new("UIListLayout")
		rl.FillDirection = Enum.FillDirection.Horizontal
		rl.Padding = UDim.new(0, 4)
		rl.Parent = rowFrame
		for _, label in row do
			makeBtn(rowFrame, label)
		end
	end

	-- [T] Slow: ON
	local slowFrame = Instance.new("Frame")
	slowFrame.Size = UDim2.new(1, 0, 0, 22)
	slowFrame.BackgroundColor3 = Color3.fromRGB(28, 24, 38)
	slowFrame.BorderSizePixel = 0
	slowFrame.Parent = panel
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 4); sc.Parent = slowFrame
	local stroke2 = Instance.new("UIStroke")
	stroke2.Color = Color3.fromRGB(80, 70, 110)
	stroke2.Thickness = 1
	stroke2.Parent = slowFrame
	local slowLbl = Instance.new("TextLabel")
	slowLbl.Size = UDim2.new(1, 0, 1, 0)
	slowLbl.BackgroundTransparency = 1
	slowLbl.Font = Enum.Font.Gotham
	slowLbl.TextScaled = true
	slowLbl.TextColor3 = Color3.fromRGB(255, 220, 80)
	slowLbl.Text = "[T] Slow: ON"
	slowLbl.Parent = slowFrame
end

return FakeButtons
