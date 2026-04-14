--!strict
-- ProgressPanel — Animação de progresso dos pulos.
-- Faixa horizontal no topo com 7 cards visuais (sem texto).
-- Fica verde + ✓ ao desbloquear cada pulo.
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local ProgressPanel = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

-- Emoji representativo de cada pulo (sem texto — só visual)
local AVATARS: { [string]: string } = {
	james   = "👟",
	jj      = "🛡️",
	mana    = "💜",
	pdoro   = "🌊",
	matheus = "🦇",
	caylus  = "🔔",
	athos   = "🔥",
}

function ProgressPanel.init()
	local gui = Instance.new("ScreenGui")
	gui.Name         = "ProgressPanel"
	gui.ResetOnSpawn = false
	gui.Parent       = player:WaitForChild("PlayerGui")

	local CARD_W = 72
	local CARD_H = 86
	local PAD    = 6
	local COUNT  = #S.JUMPS
	local panelW = COUNT * (CARD_W + PAD) - PAD + 24

	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.new(0, panelW, 0, CARD_H + 18)
	panel.Position               = UDim2.new(0.5, -panelW / 2, 0, 8)
	panel.BackgroundColor3       = Color3.fromRGB(16, 14, 24)
	panel.BackgroundTransparency = 0.12
	panel.BorderSizePixel        = 0
	panel.Parent                 = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 12); pc.Parent = panel

	local row = Instance.new("Frame")
	row.Name                 = "Row"
	row.Size                 = UDim2.new(1, -12, 0, CARD_H)
	row.Position             = UDim2.new(0, 6, 0, 9)
	row.BackgroundTransparency = 1
	row.Parent               = panel
	local lay = Instance.new("UIListLayout")
	lay.FillDirection     = Enum.FillDirection.Horizontal
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.Padding           = UDim.new(0, PAD)
	lay.Parent            = row

	for _, j in S.JUMPS do
		if not j or not j.id then continue end
		local card = Instance.new("Frame")
		card.Name             = "Card_" .. j.id
		card.Size             = UDim2.new(0, CARD_W, 0, CARD_H)
		card.BackgroundColor3 = Color3.fromRGB(36, 32, 50)
		card.BorderSizePixel  = 0
		card.Parent           = row
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 10); cc.Parent = card

		local stroke = Instance.new("UIStroke")
		stroke.Name      = "Border"
		stroke.Color     = j.color or Color3.fromRGB(80, 80, 100)
		stroke.Thickness = 2
		stroke.Parent    = card

		-- Avatar: fundo com cor do tier + emoji centralizado
		local ava = Instance.new("Frame")
		ava.Name                 = "Ava"
		ava.Size                 = UDim2.new(1, -4, 0, CARD_W - 4)
		ava.Position             = UDim2.new(0, 2, 0, 2)
		ava.BackgroundColor3     = j.color or Color3.fromRGB(60, 60, 80)
		ava.BackgroundTransparency = 0.40
		ava.BorderSizePixel      = 0
		ava.Parent               = card
		local ac = Instance.new("UICorner"); ac.CornerRadius = UDim.new(0, 8); ac.Parent = ava

		local ico = Instance.new("TextLabel")
		ico.Name                   = "Ico"
		ico.Size                   = UDim2.new(1, 0, 1, 0)
		ico.BackgroundTransparency = 1
		ico.Font                   = Enum.Font.GothamBold
		ico.TextScaled             = true
		ico.TextColor3             = Color3.new(1, 1, 1)
		ico.Text                   = AVATARS[j.id] or "👟"
		ico.Parent                 = ava

		-- Barra de cor sólida no fundo (identificador do tier)
		local bar = Instance.new("Frame")
		bar.Size             = UDim2.new(1, -4, 0, 12)
		bar.Position         = UDim2.new(0, 2, 1, -14)
		bar.BackgroundColor3 = j.color or Color3.fromRGB(80, 80, 100)
		bar.BackgroundTransparency = 0.18
		bar.BorderSizePixel  = 0
		bar.Parent           = card
		local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = bar
	end

	-- Marca card como desbloqueado: fica verde + ✓
	local function markUnlocked(jumpId: string)
		local card = row:FindFirstChild("Card_" .. jumpId) :: Frame?
		if not card then return end
		card.BackgroundColor3 = Color3.fromRGB(24, 80, 32)
		local border = card:FindFirstChild("Border") :: UIStroke?
		if border then
			border.Color     = Color3.fromRGB(80, 220, 80)
			border.Thickness = 3
		end
		local ava = card:FindFirstChild("Ava") :: Frame?
		if ava then
			ava.BackgroundColor3       = Color3.fromRGB(35, 170, 55)
			ava.BackgroundTransparency = 0.15
			local ico = ava:FindFirstChild("Ico") :: TextLabel?
			if ico then ico.Text = "✓" end
		end
	end

	local R = require(RS.Shared.Remotes)
	local sync      = RS:WaitForChild(R.SyncData) :: RemoteEvent
	local purchased = RS:WaitForChild(R.JumpPurchased) :: RemoteEvent

	sync.OnClientEvent:Connect(function(d: any)
		if not d then return end
		for _, id in (d.unlockedJumps or {}) do
			markUnlocked(id)
		end
	end)
	purchased.OnClientEvent:Connect(function(id: string)
		markUnlocked(id)
	end)
end

return ProgressPanel
