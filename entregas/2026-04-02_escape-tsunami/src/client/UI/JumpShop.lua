--!strict
-- JumpShop — Loja de Pulos de Youtubers (estética Jump Boost Shop).
-- Fundo transparente com contorno preto. 3 cards visíveis; setas auto-hide.
-- Card: banner bilinear (nome + recompensas em símbolos) · botão pill.
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local JumpShop = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

-- ── Paleta Jump Boost Shop ───────────────────────────────────────────
local HEADER_TOP      = Color3.fromRGB(255, 180, 30)
local HEADER_BOT      = Color3.fromRGB(230, 120, 15)
local CARD_BG_TOP     = Color3.fromRGB(255, 225, 60)
local CARD_BG_BOT     = Color3.fromRGB(255, 170, 20)
local BTN_GREEN_TOP   = Color3.fromRGB(110, 230, 80)
local BTN_GREEN_BOT   = Color3.fromRGB(40, 160, 40)
local BTN_GOLD_TOP    = Color3.fromRGB(255, 215, 70)
local BTN_GOLD_BOT    = Color3.fromRGB(220, 150, 20)
local BTN_LOCK_TOP    = Color3.fromRGB(150, 150, 150)
local BTN_LOCK_BOT    = Color3.fromRGB(90, 90, 90)
local BTN_OWN_TOP     = Color3.fromRGB(80, 200, 220)
local BTN_OWN_BOT     = Color3.fromRGB(30, 110, 140)
local BLACK           = Color3.fromRGB(0, 0, 0)
local WHITE           = Color3.new(1, 1, 1)
local SHOE_BLUE       = Color3.fromRGB(70, 160, 255)

-- ── Emoji fallback (cabeça do YouTuber) ──────────────────────────────
local FACE_EMOJI: { [string]: string } = {
	james   = "👦",
	jj      = "🧒",
	mana    = "👧",
	pdoro   = "🧑",
	matheus = "👨",
	caylus  = "🤴",
	athos   = "🔥",
}

-- ── Ícone de moeda por cost_type (prefixado no botão) ────────────────
local COST_ICON: { [string]: string } = {
	money          = "💰",
	survive_waves  = "🌊",
	kill_noobs     = "💀",
	sell_brainrots = "💱",
	fuse_brainrots = "🔥",
}

-- ── Constantes visuais (mexa aqui para ajustar sem tocar layout) ──────
local CARD_W       = 170
local CARD_H       = 240
local CARD_GAP     = 12
local HEADER_H     = 50
local TITLE_SIZE   = 28   -- TextSize fixo (não TextScaled) — controla tamanho do título
local PANEL_W      = 580
local PANEL_PAD_V  = 8    -- respiro entre header e cards (e abaixo dos cards)
local SHOE_ASSET   = "rbxassetid://12620788648" -- tênis azul (mesmo do header)

-- ── Formata valor monetário compactado ───────────────────────────────
local function fmtMoney(v: number): string
	if v >= 1e6 then return string.format("%.0fM", v / 1e6)
	elseif v >= 1e3 then return string.format("%.0fK", v / 1e3)
	else return tostring(v) end
end

-- ── Texto de custo (botão) ────────────────────────────────────────────
local function costText(j: any): string
	local ct = j.cost_type :: string
	if ct == "free" then return "FREE" end
	local icon = COST_ICON[ct] or ""
	if ct == "money" then
		return icon .. " $" .. fmtMoney(j.cost_value :: number)
	end
	return icon .. " ×" .. tostring(j.cost_value)
end

-- ── Estado do card ────────────────────────────────────────────────────
local function cardState(j: any, d: any): string
	if not d then return "locked" end
	for _, id in (d.unlockedJumps or {}) do
		if id == j.id then return "owned" end
	end
	local ct = j.cost_type :: string
	if ct == "free" then return "available"
	elseif ct == "money" then
		return if (d.money or 0) >= j.cost_value then "available" else "locked"
	elseif ct == "survive_waves" then
		return if (d.wavesSurvived or 0) >= j.cost_value then "available" else "locked"
	elseif ct == "kill_noobs" then
		return if (d.noobsKilled or 0) >= j.cost_value then "available" else "locked"
	elseif ct == "sell_brainrots" then
		return if (d.brainrotsSold or 0) >= j.cost_value then "available" else "locked"
	elseif ct == "fuse_brainrots" then
		return if (d.brainrotsFused or 0) >= j.cost_value then "available" else "locked"
	end
	return "locked"
end

local gui:         ScreenGui
local panel:       Frame
local scroll:      ScrollingFrame
local cardRow:     Frame
local leftArrow:   TextButton
local rightArrow:  TextButton
local currentData: any = {}
local buyRemote:   RemoteEvent
local isOpen       = false

-- ── Helpers ──────────────────────────────────────────────────────────
local function stroke(p: Instance, color: Color3, thick: number): UIStroke
	local s = Instance.new("UIStroke")
	s.Color = color; s.Thickness = thick
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end

local function vertGradient(p: Instance, top: Color3, bot: Color3): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(top, bot); g.Rotation = 90
	g.Parent = p
	return g
end

local function corner(p: Instance, radiusPx: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radiusPx)
	c.Parent = p
	return c
end

-- ── Constrói card ─────────────────────────────────────────────────────
local function buildCard(parent: Instance, j: any, state: string)
	local card = Instance.new("Frame")
	card.Name             = "Card_" .. j.id
	card.Size             = UDim2.new(0, CARD_W, 0, CARD_H)
	card.BackgroundColor3 = WHITE
	card.BorderSizePixel  = 0
	card.Parent           = parent
	vertGradient(card, CARD_BG_TOP, CARD_BG_BOT)
	stroke(card, BLACK, 3)

	-- Banner branco bilinear (nome + recompensas)
	local banner = Instance.new("Frame")
	banner.Size             = UDim2.new(1, -10, 0, 56)
	banner.Position         = UDim2.new(0, 5, 0, 5)
	banner.BackgroundColor3 = WHITE
	banner.BorderSizePixel  = 0
	banner.Parent           = card
	stroke(banner, BLACK, 2)

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                   = UDim2.new(1, -8, 0, 24)
	nameLbl.Position               = UDim2.new(0, 4, 0, 2)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font                   = Enum.Font.FredokaOne
	nameLbl.TextScaled             = true
	nameLbl.TextColor3             = BLACK
	nameLbl.Text                   = j.name or j.label or "?"
	nameLbl.Parent                 = banner

	local sub = Instance.new("TextLabel")
	sub.Size                   = UDim2.new(1, -8, 0, 26)
	sub.Position               = UDim2.new(0, 4, 0, 26)
	sub.BackgroundTransparency = 1
	sub.Font                   = Enum.Font.GothamBold
	sub.TextScaled             = true
	sub.TextColor3             = BLACK
	sub.TextWrapped            = true
	sub.Text                   = j.rewards or ""
	sub.Parent                 = banner

	-- Área central — imagem do pulo (ImageLabel se j.image, senão emoji)
	local imgArea = Instance.new("Frame")
	imgArea.Size     = UDim2.new(1, -10, 0, 110)
	imgArea.Position = UDim2.new(0, 5, 0, 66)
	imgArea.BackgroundTransparency = 1
	imgArea.Parent   = card

	if j.image and j.image ~= "" then
		local img = Instance.new("ImageLabel")
		img.Size                   = UDim2.new(1, 0, 1, 0)
		img.BackgroundTransparency = 1
		img.Image                  = j.image
		img.ScaleType              = Enum.ScaleType.Fit
		img.Parent                 = imgArea
	else
		local face = Instance.new("TextLabel")
		face.Size                   = UDim2.new(1, 0, 0.55, 0)
		face.Position               = UDim2.new(0, 0, 0, 0)
		face.BackgroundTransparency = 1
		face.Font                   = Enum.Font.GothamBold
		face.TextScaled             = true
		face.Text                   = FACE_EMOJI[j.id] or "👤"
		face.TextColor3             = WHITE
		face.Parent                 = imgArea

		local shoe = Instance.new("ImageLabel")
		shoe.Size                   = UDim2.new(1, 0, 0.5, 0)
		shoe.Position               = UDim2.new(0, 0, 0.5, 0)
		shoe.BackgroundTransparency = 1
		shoe.Image                  = SHOE_ASSET
		shoe.ScaleType              = Enum.ScaleType.Fit
		shoe.Parent                 = imgArea
	end

	-- Setas verdes ▲▲ (decorativas, canto inferior-direito da arte)
	local arrows = Instance.new("TextLabel")
	arrows.Size                   = UDim2.new(0, 40, 0, 22)
	arrows.AnchorPoint            = Vector2.new(1, 1)
	arrows.Position               = UDim2.new(1, -4, 1, -2)
	arrows.BackgroundTransparency = 1
	arrows.Font                   = Enum.Font.FredokaOne
	arrows.TextScaled             = true
	arrows.TextColor3             = Color3.fromRGB(40, 200, 40)
	arrows.Text                   = "▲▲"
	arrows.Parent                 = imgArea
	stroke(arrows, BLACK, 1.5)

	-- Botão preço (pill rounded)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, -12, 0, 44)
	btn.Position         = UDim2.new(0, 6, 1, -52)
	btn.BackgroundColor3 = WHITE
	btn.BorderSizePixel  = 0
	btn.Font             = Enum.Font.FredokaOne
	btn.TextScaled       = true
	btn.TextColor3       = WHITE
	btn.AutoButtonColor  = false
	btn.Text             = ""
	btn.Parent           = card
	corner(btn, 10)
	stroke(btn, BLACK, 2.5)

	if state == "owned" then
		vertGradient(btn, BTN_OWN_TOP, BTN_OWN_BOT)
		btn.Text = "✓ OWNED"
		btn.Active = false
	elseif state == "available" then
		if (j.cost_type :: string) == "free" then
			vertGradient(btn, BTN_GREEN_TOP, BTN_GREEN_BOT)
		else
			vertGradient(btn, BTN_GOLD_TOP, BTN_GOLD_BOT)
		end
		btn.Text = costText(j)
		btn.Active = true
		btn.AutoButtonColor = true
		btn.MouseButton1Click:Connect(function()
			buyRemote:FireServer(j.id)
		end)
	else
		vertGradient(btn, BTN_LOCK_TOP, BTN_LOCK_BOT)
		btn.Text = costText(j)
		btn.Active = false
	end
end

-- ── Atualiza visibilidade das setas conforme overflow ─────────────────
local function updateArrows()
	if not scroll or not leftArrow or not rightArrow then return end
	local hasOverflow = scroll.AbsoluteCanvasSize.X > scroll.AbsoluteSize.X + 1
	leftArrow.Visible = hasOverflow
	rightArrow.Visible = hasOverflow
end

-- ── Reconstrói cards ──────────────────────────────────────────────────
local function rebuildCards()
	for _, c in cardRow:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
	for _, j in S.JUMPS do
		if not j or not j.id then continue end
		buildCard(cardRow, j, cardState(j, currentData))
	end
	task.defer(updateArrows)
end

-- ── Setas de scroll (esquerda/direita) ────────────────────────────────
local function scrollBy(delta: number)
	local target = math.clamp(
		scroll.CanvasPosition.X + delta,
		0,
		math.max(0, scroll.AbsoluteCanvasSize.X - scroll.AbsoluteSize.X)
	)
	TweenService:Create(scroll,
		TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CanvasPosition = Vector2.new(target, 0) }):Play()
end

local function makeArrow(parent: Instance, dir: number, xAnchor: UDim): TextButton
	local btn = Instance.new("TextButton")
	btn.Size                   = UDim2.new(0, 38, 0, 60)
	btn.AnchorPoint            = Vector2.new(if dir < 0 then 0 else 1, 0.5)
	btn.Position               = UDim2.new(xAnchor.Scale, xAnchor.Offset, 0.5, 0)
	btn.BackgroundColor3       = Color3.fromRGB(40, 30, 10)
	btn.BackgroundTransparency = 0.15
	btn.BorderSizePixel        = 0
	btn.Font                   = Enum.Font.FredokaOne
	btn.TextScaled             = true
	btn.TextColor3             = WHITE
	btn.Text                   = if dir < 0 then "◀" else "▶"
	btn.Visible                = false
	btn.Parent                 = parent
	stroke(btn, BLACK, 2)
	btn.MouseButton1Click:Connect(function()
		scrollBy(dir * (CARD_W + CARD_GAP))
	end)
	return btn
end

-- ── Abre / fecha ──────────────────────────────────────────────────────
local function open()
	if isOpen then return end
	isOpen = true
	rebuildCards()
	scroll.CanvasPosition = Vector2.new(0, 0)
	panel.Visible = true
end

local function close()
	if not isOpen then return end
	isOpen = false
	panel.Visible = false
end

-- ── Init ──────────────────────────────────────────────────────────────
function JumpShop.init()
	local R = require(RS.Shared.Remotes)

	buyRemote = RS:WaitForChild(R.BuyJump) :: RemoteEvent

	gui = Instance.new("ScreenGui")
	gui.Name = "JumpShop"; gui.ResetOnSpawn = false
	gui.DisplayOrder = 10; gui.Parent = player:WaitForChild("PlayerGui")

	-- Painel: transparente com contorno preto, sem bordas arredondadas.
	-- Largura = 3×170 + 2×12 + 2×12 padding + 16 margem scroll ≈ 574
	-- Painel: altura = header + padding + card + padding (flush, sem sobra vertical)
	local PANEL_H = HEADER_H + PANEL_PAD_V * 2 + CARD_H
	panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.new(0, PANEL_W, 0, PANEL_H)
	panel.Position               = UDim2.new(0.5, -PANEL_W / 2, 0.5, -PANEL_H / 2)
	panel.BackgroundTransparency = 1
	panel.BorderSizePixel        = 0
	panel.Visible                = false
	panel.Parent                 = gui
	stroke(panel, BLACK, 3)

	-- Header dourado (cantos retos)
	local header = Instance.new("Frame")
	header.Size             = UDim2.new(1, 0, 0, HEADER_H)
	header.BackgroundColor3 = WHITE
	header.BorderSizePixel  = 0
	header.Parent           = panel
	vertGradient(header, HEADER_TOP, HEADER_BOT)
	stroke(header, BLACK, 2.5)

	-- Ícone tênis à esquerda do título
	local shoeIcon = Instance.new("ImageLabel")
	shoeIcon.Name                   = "ShoeIcon"
	shoeIcon.Size                   = UDim2.new(0, HEADER_H - 12, 0, HEADER_H - 12)
	shoeIcon.Position               = UDim2.new(0, 10, 0.5, 0)
	shoeIcon.AnchorPoint            = Vector2.new(0, 0.5)
	shoeIcon.BackgroundTransparency = 1
	shoeIcon.Image                  = SHOE_ASSET
	shoeIcon.Parent                 = header

	-- Título (TextSize fixo — não enche o header)
	local title = Instance.new("TextLabel")
	title.Size                   = UDim2.new(1, -120, 1, 0)
	title.Position               = UDim2.new(0, 60, 0, 0)
	title.BackgroundTransparency = 1
	title.Font                   = Enum.Font.FredokaOne
	title.TextSize               = TITLE_SIZE
	title.TextColor3             = WHITE
	title.TextXAlignment         = Enum.TextXAlignment.Center
	title.Text                   = "Jump Boost Shop"
	title.Parent                 = header
	stroke(title, BLACK, 2)

	-- X de fechar (vermelho, cantos retos)
	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, HEADER_H - 10, 0, HEADER_H - 10)
	closeBtn.Position         = UDim2.new(1, -(HEADER_H - 5), 0, 5)
	closeBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
	closeBtn.BorderSizePixel  = 0
	closeBtn.Font             = Enum.Font.FredokaOne
	closeBtn.TextScaled       = true
	closeBtn.TextColor3       = WHITE
	closeBtn.Text             = "X"
	closeBtn.Parent           = header
	stroke(closeBtn, BLACK, 2.5)
	closeBtn.MouseButton1Click:Connect(close)

	-- Container dos cards (logo abaixo do header, com padding mínimo)
	local cardsBox = Instance.new("Frame")
	cardsBox.Size                   = UDim2.new(1, 0, 1, -HEADER_H)
	cardsBox.Position               = UDim2.new(0, 0, 0, HEADER_H)
	cardsBox.BackgroundTransparency = 1
	cardsBox.Parent                 = panel

	-- Scroll horizontal (sem barra visível)
	scroll = Instance.new("ScrollingFrame")
	scroll.Size                   = UDim2.new(1, -16, 1, -PANEL_PAD_V * 2)
	scroll.Position               = UDim2.new(0, 8, 0, PANEL_PAD_V)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel        = 0
	scroll.ScrollBarThickness     = 0
	scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize    = Enum.AutomaticSize.X
	scroll.ScrollingDirection     = Enum.ScrollingDirection.X
	scroll.ClipsDescendants       = true
	scroll.Parent                 = cardsBox

	cardRow = Instance.new("Frame")
	cardRow.Name                   = "CardRow"
	cardRow.Size                   = UDim2.new(0, 0, 1, 0)
	cardRow.AutomaticSize          = Enum.AutomaticSize.X
	cardRow.BackgroundTransparency = 1
	cardRow.Parent                 = scroll

	local lay = Instance.new("UIListLayout")
	lay.FillDirection     = Enum.FillDirection.Horizontal
	lay.VerticalAlignment = Enum.VerticalAlignment.Top
	lay.Padding           = UDim.new(0, CARD_GAP)
	lay.Parent            = cardRow

	-- Setas ◀ ▶ (auto-hide quando não há overflow)
	leftArrow  = makeArrow(cardsBox, -1, UDim.new(0, 4))
	rightArrow = makeArrow(cardsBox,  1, UDim.new(1, -4))

	scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateArrows)
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateArrows)

	-- Remotes
	local showEvt = RS:WaitForChild(R.ShowShop)      :: RemoteEvent
	local syncEvt = RS:WaitForChild(R.SyncData)      :: RemoteEvent
	local purch   = RS:WaitForChild(R.JumpPurchased) :: RemoteEvent

	showEvt.OnClientEvent:Connect(open)
	syncEvt.OnClientEvent:Connect(function(data: any)
		currentData = data
		if isOpen then rebuildCards() end
	end)
	purch.OnClientEvent:Connect(function(_: string)
		if isOpen then rebuildCards() end
	end)
end

return JumpShop
