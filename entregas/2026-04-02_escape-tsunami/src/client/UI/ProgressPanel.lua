--!strict
-- ProgressPanel — Faixa vertical no lado direito mostrando os 7 pulos.
-- Check verde ao desbloquear cada um. Fica abaixo do BasePanel.
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ProgressPanel = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

local CARD_W  = 44
local CARD_H  = 44
local PAD     = 4
local BG      = Color3.fromRGB(14, 12, 22)
local LOCKED  = Color3.fromRGB(50, 46, 64)
local OWNED   = Color3.fromRGB(24, 90, 36)
local GOLD    = Color3.fromRGB(255, 210, 50)
local WHITE   = Color3.new(1, 1, 1)

-- Iniciais visíveis em cada card (sem emoji — clean)
local INITIALS: { [string]: string } = {
	james   = "J",
	jj      = "JJ",
	mana    = "M",
	pdoro   = "P",
	matheus = "Ma",
	caylus  = "Ca",
	athos   = "At",
}

function ProgressPanel.init()
	local gui = Instance.new("ScreenGui")
	gui.Name         = "ProgressPanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 3
	gui.Parent       = player:WaitForChild("PlayerGui")

	-- Painel vertical
	local totalH = #S.JUMPS * (CARD_H + PAD) - PAD + 16
	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.new(0, CARD_W + 16, 0, totalH)
	-- posicionado à direita, abaixo do BasePanel (~380px do topo)
	panel.Position               = UDim2.new(1, -(CARD_W + 24), 0, 390)
	panel.BackgroundColor3       = BG
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel        = 0
	panel.Parent                 = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 10); pc.Parent = panel

	local col = Instance.new("Frame")
	col.Name                 = "Col"
	col.Size                 = UDim2.new(1, -8, 1, -8)
	col.Position             = UDim2.new(0, 4, 0, 4)
	col.BackgroundTransparency = 1
	col.Parent               = panel

	local lay = Instance.new("UIListLayout")
	lay.FillDirection     = Enum.FillDirection.Vertical
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.Padding           = UDim.new(0, PAD)
	lay.Parent            = col

	-- Constrói os cards
	for _, j in S.JUMPS do
		if not j or not j.id then continue end
		local tierColor: Color3 = j.color or GOLD

		local card = Instance.new("Frame")
		card.Name             = "Card_" .. j.id
		card.Size             = UDim2.new(0, CARD_W, 0, CARD_H)
		card.BackgroundColor3 = LOCKED
		card.BorderSizePixel  = 0
		card.Parent           = col
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 8); cc.Parent = card

		local st = Instance.new("UIStroke")
		st.Name      = "Border"
		st.Color     = LOCKED
		st.Thickness = 2
		st.Parent    = card

		local lbl = Instance.new("TextLabel")
		lbl.Name                   = "Lbl"
		lbl.Size                   = UDim2.new(1, 0, 1, 0)
		lbl.BackgroundTransparency = 1
		lbl.Font                   = Enum.Font.GothamBold
		lbl.TextScaled             = true
		lbl.TextColor3             = Color3.fromRGB(100, 90, 120)
		lbl.Text                   = INITIALS[j.id] or j.id:sub(1,2):upper()
		lbl.Parent                 = card
	end

	-- Marca card como desbloqueado com tween
	local function markUnlocked(jumpId: string)
		local card = col:FindFirstChild("Card_" .. jumpId) :: Frame?
		if not card then return end

		local j: any = nil
		for _, jj in S.JUMPS do
			if jj.id == jumpId then j = jj; break end
		end
		local tierColor: Color3 = (j and j.color) or GOLD

		TweenService:Create(card,
			TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
			{ BackgroundColor3 = OWNED }):Play()

		local border = card:FindFirstChild("Border") :: UIStroke?
		if border then
			TweenService:Create(border,
				TweenInfo.new(0.25, Enum.EasingStyle.Quad),
				{ Color = tierColor }):Play()
		end

		local lbl = card:FindFirstChild("Lbl") :: TextLabel?
		if lbl then
			TweenService:Create(lbl,
				TweenInfo.new(0.15, Enum.EasingStyle.Quad),
				{ TextColor3 = GOLD }):Play()
			task.delay(0.1, function()
				lbl.Text = "✓"
			end)
		end
	end

	local R       = require(RS.Shared.Remotes)
	local syncEvt = RS:WaitForChild(R.SyncData)      :: RemoteEvent
	local purchEvt = RS:WaitForChild(R.JumpPurchased) :: RemoteEvent

	syncEvt.OnClientEvent:Connect(function(d: any)
		if not d then return end
		for _, id in (d.unlockedJumps or {}) do
			markUnlocked(id)
		end
	end)
	purchEvt.OnClientEvent:Connect(function(id: string)
		markUnlocked(id)
	end)
end

return ProgressPanel
