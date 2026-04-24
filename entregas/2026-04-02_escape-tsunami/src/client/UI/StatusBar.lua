--!strict
-- StatusBar — HUD vertical canto inferior esquerdo (estilo referência).
-- 4 widgets de moeda em coluna + linha "total" em ouro destacado.
-- Estrutura gerada via código; pra iterar visual, edite em Command Bar ou no
-- Property panel após o primeiro boot (ScreenGui vive em PlayerGui em runtime).
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local StatusBar = {}

local player = Players.LocalPlayer

-- ── Paleta ────────────────────────────────────────────────────────────
local BG_DARK       = Color3.fromRGB(18, 16, 26)
local WHITE         = Color3.new(1, 1, 1)
local BLACK         = Color3.fromRGB(0, 0, 0)
local GREEN_ICON    = Color3.fromRGB(80, 220, 90)
local GOLD_ICON     = Color3.fromRGB(255, 200, 40)
local RED_ICON      = Color3.fromRGB(230, 70, 70)
local BLUE_ICON     = Color3.fromRGB(80, 170, 255)
local GREEN_PLUS    = Color3.fromRGB(60, 200, 70)
local TOTAL_GOLD    = Color3.fromRGB(255, 230, 80)

local lblBR:     TextLabel
local lblMoney:  TextLabel
local lblJumps:  TextLabel
local lblTokens: TextLabel
local lblFused:  TextLabel
local lblKills:  TextLabel
local lblTotal:  TextLabel

local function fmt(n: number): string
	if n >= 1e12 then return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.0fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

local function stroke(p: Instance, color: Color3, thick: number)
	local s = Instance.new("UIStroke")
	s.Color = color; s.Thickness = thick
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
end

local function corner(p: Instance, r: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end

-- ── Cria uma row de moeda: [ícone circular] [número] [+ opcional] ─────
local function makeRow(parent: Frame, emoji: string, iconBg: Color3, hasPlus: boolean): TextLabel
	local row = Instance.new("Frame")
	row.Size                 = UDim2.new(1, 0, 0, 38)
	row.BackgroundColor3     = BG_DARK
	row.BackgroundTransparency = 0.35
	row.BorderSizePixel      = 0
	row.Parent               = parent
	corner(row, 16)
	stroke(row, BLACK, 2)

	-- Ícone circular colorido
	local iconWrap = Instance.new("Frame")
	iconWrap.Size                 = UDim2.new(0, 32, 0, 32)
	iconWrap.Position             = UDim2.new(0, 4, 0.5, 0)
	iconWrap.AnchorPoint          = Vector2.new(0, 0.5)
	iconWrap.BackgroundColor3     = iconBg
	iconWrap.BorderSizePixel      = 0
	iconWrap.Parent               = row
	corner(iconWrap, 999)
	stroke(iconWrap, BLACK, 1.5)

	local iconLbl = Instance.new("TextLabel")
	iconLbl.Size                 = UDim2.new(1, 0, 1, 0)
	iconLbl.BackgroundTransparency = 1
	iconLbl.Font                 = Enum.Font.GothamBold
	iconLbl.TextScaled           = true
	iconLbl.TextColor3           = WHITE
	iconLbl.Text                 = emoji
	iconLbl.Parent               = iconWrap

	-- Número
	local val = Instance.new("TextLabel")
	val.Size                 = UDim2.new(1, hasPlus and -82 or -44, 1, -6)
	val.Position             = UDim2.new(0, 42, 0, 3)
	val.BackgroundTransparency = 1
	val.Font                 = Enum.Font.FredokaOne
	val.TextScaled           = true
	val.TextColor3           = WHITE
	val.TextStrokeTransparency = 0
	val.TextStrokeColor3     = BLACK
	val.TextXAlignment       = Enum.TextXAlignment.Left
	val.Text                 = "0"
	val.Parent               = row

	-- Botão [+] verde (opcional)
	if hasPlus then
		local plus = Instance.new("TextButton")
		plus.Size             = UDim2.new(0, 36, 0, 28)
		plus.Position         = UDim2.new(1, -40, 0.5, 0)
		plus.AnchorPoint      = Vector2.new(0, 0.5)
		plus.BackgroundColor3 = GREEN_PLUS
		plus.BorderSizePixel  = 0
		plus.Font             = Enum.Font.FredokaOne
		plus.TextScaled       = true
		plus.TextColor3       = WHITE
		plus.Text             = "+"
		plus.AutoButtonColor  = true
		plus.Parent           = row
		corner(plus, 6)
		stroke(plus, BLACK, 1.5)
	end

	return val
end

function StatusBar.init()
	local gui = Instance.new("ScreenGui")
	gui.Name         = "StatusBar"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 3
	gui.Parent       = player:WaitForChild("PlayerGui")

	-- Container vertical bottom-left
	local container = Instance.new("Frame")
	container.Name                 = "Container"
	container.AutomaticSize        = Enum.AutomaticSize.Y
	container.Size                 = UDim2.new(0, 230, 0, 0)
	container.AnchorPoint          = Vector2.new(0, 1)
	container.Position             = UDim2.new(0, 12, 1, -12)
	container.BackgroundTransparency = 1
	container.Parent               = gui

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Vertical
	lay.SortOrder     = Enum.SortOrder.LayoutOrder
	lay.Padding       = UDim.new(0, 6)
	lay.Parent        = container

	-- 6 widgets (reordene ou troque emoji/cor conforme preferir)
	lblBR     = makeRow(container, "🧠", GREEN_ICON, false)                            -- brainrots coletados
	lblMoney  = makeRow(container, "💰", GOLD_ICON, true)                              -- dinheiro principal
	lblJumps  = makeRow(container, "👟", RED_ICON, false)                              -- pulos desbloqueados
	lblTokens = makeRow(container, "🌊", BLUE_ICON, true)                              -- wave tokens
	lblFused  = makeRow(container, "🧬", Color3.fromRGB(180, 80, 220), false)          -- brainrots fundidos
	lblKills  = makeRow(container, "💀", Color3.fromRGB(120, 120, 120), false)         -- noobs mortos

	-- Total destacado (ouro grande, sem BG)
	local totalRow = Instance.new("Frame")
	totalRow.Size                 = UDim2.new(1, 0, 0, 44)
	totalRow.BackgroundTransparency = 1
	totalRow.Parent               = container

	lblTotal = Instance.new("TextLabel")
	lblTotal.Size                 = UDim2.new(1, 0, 1, 0)
	lblTotal.BackgroundTransparency = 1
	lblTotal.Font                 = Enum.Font.FredokaOne
	lblTotal.TextScaled           = true
	lblTotal.TextColor3           = TOTAL_GOLD
	lblTotal.TextStrokeTransparency = 0
	lblTotal.TextStrokeColor3     = BLACK
	lblTotal.TextXAlignment       = Enum.TextXAlignment.Left
	lblTotal.Text                 = "$0"
	lblTotal.Parent               = totalRow

	-- Bind de dados
	local R    = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		local brs: any = d.brainrots or {}
		local totalBR = 0
		for _, e in brs do totalBR += e.qty end

		local unlocked = d.unlockedJumps or {}
		local jumpsCount = 0
		for _ in unlocked do jumpsCount += 1 end

		lblBR.Text     = fmt(totalBR)
		lblMoney.Text  = fmt(d.money or 0)
		lblJumps.Text  = tostring(jumpsCount) .. "/7"
		lblTokens.Text = fmt(d.waveTokens or 0)
		lblFused.Text  = fmt(d.brainrotsFused or 0)
		lblKills.Text  = fmt(d.noobsKilled or 0)
		lblTotal.Text  = "$" .. fmt(d.money or 0)
	end)
end

return StatusBar
