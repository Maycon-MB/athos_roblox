--!strict
-- CurrencyHud — Painel de moedas/recursos no canto inferior esquerdo.
-- Criado por código (sem template Studio). Atualiza via SyncData.
-- Fica abaixo dos botões do FakeButtons, com o mesmo estilo de transparência.
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local CurrencyHud = {}

local player = Players.LocalPlayer

-- ── Configuração visual das linhas ──────────────────────────────────────────
type RowDef = { icon: string, color: Color3, plus: boolean }

local ROWS: { RowDef } = {
	{ icon = "💎", color = Color3.fromRGB(130,  60, 210), plus = false },  -- premium
	{ icon = "🪙", color = Color3.fromRGB(220, 160,  20), plus = true  },  -- money principal
	{ icon = "🦘", color = Color3.fromRGB( 50, 130, 210), plus = false },  -- jumps
	{ icon = "🌊", color = Color3.fromRGB( 30, 185, 210), plus = true  },  -- tokens
}

local ROW_H  = 28
local PAD    = 5
local WIDTH  = 160

-- ── Referências aos labels para atualização ─────────────────────────────────
local rowValues: { TextLabel } = {}
local moneyBig: TextLabel

-- ── Helpers ─────────────────────────────────────────────────────────────────
local function corner(p: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = p
end

local function abbreviate(n: number): string
	if n >= 1e12 then return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9  then return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6  then return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3  then return string.format("%.0fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

-- ── Constrói uma linha de recurso ────────────────────────────────────────────
local function buildRow(parent: Frame, def: RowDef, index: number): TextLabel
	local yOff = PAD + (index - 1) * (ROW_H + PAD)

	local row = Instance.new("Frame")
	row.Size                  = UDim2.new(1, -PAD * 2, 0, ROW_H)
	row.Position              = UDim2.new(0, PAD, 0, yOff)
	row.BackgroundTransparency = 1
	row.Parent                = parent

	-- ícone circular colorido
	local iconCircle = Instance.new("Frame")
	iconCircle.Size             = UDim2.new(0, ROW_H, 0, ROW_H)
	iconCircle.BackgroundColor3 = def.color
	iconCircle.BorderSizePixel  = 0
	iconCircle.Parent           = row
	corner(iconCircle, ROW_H // 2)

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size                   = UDim2.new(1, 0, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Font                   = Enum.Font.GothamBold
	iconLbl.TextScaled             = true
	iconLbl.Text                   = def.icon
	iconLbl.Parent                 = iconCircle

	-- valor
	local valueWidth = 1 - (if def.plus then 0.18 else 0)
	local valLbl = Instance.new("TextLabel")
	valLbl.Size                   = UDim2.new(valueWidth, -(ROW_H + 6), 1, 0)
	valLbl.Position               = UDim2.new(0, ROW_H + 6, 0, 0)
	valLbl.BackgroundTransparency = 1
	valLbl.Font                   = Enum.Font.GothamBold
	valLbl.TextScaled             = true
	valLbl.TextXAlignment         = Enum.TextXAlignment.Left
	valLbl.TextColor3             = Color3.fromRGB(255, 255, 255)
	valLbl.Text                   = "0"
	valLbl.Parent                 = row

	-- botão "+" decorativo (igual ao jogo de referência)
	if def.plus then
		local plusBtn = Instance.new("TextLabel")
		plusBtn.Size               = UDim2.new(0, 22, 0, 22)
		plusBtn.Position           = UDim2.new(1, -22, 0.5, -11)
		plusBtn.BackgroundColor3   = def.color
		plusBtn.BorderSizePixel    = 0
		plusBtn.Font               = Enum.Font.GothamBold
		plusBtn.TextScaled         = true
		plusBtn.TextColor3         = Color3.fromRGB(255, 255, 255)
		plusBtn.Text               = "+"
		plusBtn.Parent             = row
		corner(plusBtn, 5)
	end

	return valLbl
end

-- ── init ────────────────────────────────────────────────────────────────────
function CurrencyHud.init()
	local PANEL_H = #ROWS * (ROW_H + PAD) + PAD + 4 + 34  -- rows + separador + linha de dinheiro

	local gui = Instance.new("ScreenGui")
	gui.Name         = "CurrencyHud"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 3
	gui.Parent       = player:WaitForChild("PlayerGui")

	-- painel externo — mesmo estilo de fundo do FakeButtons
	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.new(0, WIDTH, 0, PANEL_H)
	panel.Position               = UDim2.new(0, 8, 1, -(PANEL_H + 8))
	panel.BackgroundColor3       = Color3.fromRGB(28, 22, 14)
	panel.BackgroundTransparency = 0.2
	panel.BorderSizePixel        = 0
	panel.Parent                 = gui
	corner(panel, 8)

	local stroke = Instance.new("UIStroke")
	stroke.Color     = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 1.5
	stroke.Parent    = panel

	-- linhas de recurso
	for i, def in ROWS do
		rowValues[i] = buildRow(panel, def, i)
	end

	-- separador fino
	local sepY = PAD + #ROWS * (ROW_H + PAD)
	local sep = Instance.new("Frame")
	sep.Size             = UDim2.new(1, -PAD * 2, 0, 1)
	sep.Position         = UDim2.new(0, PAD, 0, sepY)
	sep.BackgroundColor3 = Color3.fromRGB(90, 75, 45)
	sep.BorderSizePixel  = 0
	sep.Parent           = panel

	-- linha de dinheiro grande ($1.11T)
	moneyBig = Instance.new("TextLabel")
	moneyBig.Size                   = UDim2.new(1, -PAD * 2, 0, 30)
	moneyBig.Position               = UDim2.new(0, PAD, 0, sepY + 4)
	moneyBig.BackgroundTransparency = 1
	moneyBig.Font                   = Enum.Font.GothamBold
	moneyBig.TextScaled             = true
	moneyBig.TextXAlignment         = Enum.TextXAlignment.Left
	moneyBig.TextColor3             = Color3.fromRGB(80, 220, 80)  -- verde, igual ao ref
	moneyBig.Text                   = "$0"
	moneyBig.Parent                 = panel

	-- escuta SyncData e atualiza os 4 valores + linha de dinheiro
	local R    = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		local totalBR = 0
		for _, e in (d.brainrots or {}) do totalBR += e.qty end

		local jumpsCount = 0
		for _ in (d.unlockedJumps or {}) do jumpsCount += 1 end

		local money  = d.money      or 0
		local tokens = d.waveTokens or 0

		-- linha 1: 💎 brainrots (premium visual)
		rowValues[1].Text = abbreviate(totalBR)
		-- linha 2: 🪙 money
		rowValues[2].Text = abbreviate(money)
		-- linha 3: 🦘 jumps desbloqueados
		rowValues[3].Text = tostring(jumpsCount) .. "/7"
		-- linha 4: 🌊 wave tokens
		rowValues[4].Text = abbreviate(tokens)

		moneyBig.Text = "$" .. abbreviate(money)
	end)
end

return CurrencyHud
