--!strict
-- JumpShop — Loja de Pulos de Youtubers.
-- Abre via ShowShop (CrackWall/ShopCounter). Fecha com botão ✕.
-- Estética: warm dark + gold, inspirada na referência Jump Boost Shop.
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local JumpShop = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

-- ── Paleta warm-dark ─────────────────────────────────────────────────
local BG        = Color3.fromRGB(22, 16, 10)
local HEADER_BG = Color3.fromRGB(200, 140, 20)
local CARD_BG   = Color3.fromRGB(32, 24, 14)
local BTN_FREE  = Color3.fromRGB(40, 185, 70)
local BTN_LOCK  = Color3.fromRGB(70, 65, 60)
local BTN_OWN   = Color3.fromRGB(180, 140, 20)
local WHITE     = Color3.new(1, 1, 1)
local GOLD      = Color3.fromRGB(255, 210, 50)
local DARK_TXT  = Color3.fromRGB(30, 22, 10)

-- ── Emoji por tier ────────────────────────────────────────────────────
local ICONS: { [string]: string } = {
	james   = "👟",
	jj      = "🛡️",
	mana    = "💜",
	pdoro   = "🌊",
	matheus = "🦇",
	caylus  = "🔔",
	athos   = "🔥",
}

local REWARDS: { [string]: string } = {
	james   = "🎁 Jamezini",
	jj      = "🎁 Mikey  🛡️",
	mana    = "💜  Base MAX",
	pdoro   = "🌊 10k tokens",
	matheus = "🎁 ×3 Glaciero  🦇",
	caylus  = "🎁 ×3 Lucky Box",
	athos   = "🔥 Base Athos cheia",
}

-- ── Texto de custo ────────────────────────────────────────────────────
local function costText(j: any): string
	local ct = j.cost_type :: string
	if ct == "free" then return "FREE"
	elseif ct == "money" then
		local v = j.cost_value :: number
		if v >= 1e6 then return "$" .. string.format("%.0fM", v / 1e6)
		else return "$" .. string.format("%.0fK", v / 1e3) end
	elseif ct == "survive_waves"  then return "🌊 ×" .. j.cost_value .. " waves"
	elseif ct == "kill_noobs"     then return "☠️  ×" .. j.cost_value .. " kills"
	elseif ct == "sell_brainrots" then return "💱 ×" .. j.cost_value .. " sales"
	elseif ct == "fuse_brainrots" then return "🔥 ×" .. j.cost_value .. " fusions"
	end
	return "?"
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
local cardRow:     Frame
local currentData: any = {}
local buyRemote:   RemoteEvent
local isOpen       = false

local function corner(p: Instance, r: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end

-- ── Constrói card ─────────────────────────────────────────────────────
local function buildCard(parent: Instance, j: any, state: string)
	local tierColor: Color3 = j.color or GOLD

	local card = Instance.new("Frame")
	card.Name             = "Card_" .. j.id
	card.Size             = UDim2.new(0, 160, 0, 220)
	card.BackgroundColor3 = CARD_BG
	card.BorderSizePixel  = 0
	card.Parent           = parent
	corner(card, 14)

	local st = Instance.new("UIStroke")
	st.Color     = if state == "owned" then GOLD elseif state == "locked" then BTN_LOCK else tierColor
	st.Thickness = if state == "owned" then 3 else 2
	st.Parent    = card

	-- Topo colorido
	local topBg = tierColor:Lerp(Color3.fromRGB(8, 6, 2), 0.52)
	local top = Instance.new("Frame")
	top.Size             = UDim2.new(1, 0, 0, 124)
	top.BackgroundColor3 = if state == "locked" then Color3.fromRGB(40, 38, 34) else topBg
	top.BorderSizePixel  = 0
	top.Parent           = card
	corner(top, 12)
	-- tapa cantos inferiores do topo
	local fix = Instance.new("Frame")
	fix.Size = UDim2.new(1, 0, 0.4, 0); fix.Position = UDim2.new(0, 0, 0.6, 0)
	fix.BackgroundColor3 = top.BackgroundColor3; fix.BorderSizePixel = 0; fix.Parent = top

	-- Nome centralizado no topo (sem emoji)
	local nm = Instance.new("TextLabel")
	nm.Size = UDim2.new(1, -8, 1, 0); nm.Position = UDim2.new(0, 4, 0, 0)
	nm.BackgroundTransparency = 1
	nm.Font = Enum.Font.GothamBold; nm.TextScaled = true
	nm.TextXAlignment = Enum.TextXAlignment.Center
	nm.TextColor3 = if state == "locked" then Color3.fromRGB(140, 130, 110)
		elseif state == "owned" then GOLD
		else WHITE
	nm.Text = if state == "owned" then "✓\n" .. j.name else j.name
	nm.Parent = top

	-- Stats
	local stats = Instance.new("TextLabel")
	stats.Size = UDim2.new(1, -8, 0, 22); stats.Position = UDim2.new(0, 4, 0, 128)
	stats.BackgroundTransparency = 1
	stats.Font = Enum.Font.Gotham; stats.TextScaled = true
	stats.TextColor3 = Color3.fromRGB(200, 185, 155)
	stats.Text = string.format("↑%d   ⚡%d", j.jump, j.speed)
	stats.Parent = card

	-- Reward
	local rew = Instance.new("TextLabel")
	rew.Size = UDim2.new(1, -8, 0, 20); rew.Position = UDim2.new(0, 4, 0, 152)
	rew.BackgroundTransparency = 1
	rew.Font = Enum.Font.Gotham; rew.TextScaled = true
	rew.TextColor3 = Color3.fromRGB(150, 215, 155)
	rew.Text = REWARDS[j.id] or ""; rew.Parent = card

	-- Botão preço
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, -12, 0, 36); btn.Position = UDim2.new(0, 6, 1, -42)
	btn.Font = Enum.Font.GothamBold; btn.TextScaled = true
	btn.BorderSizePixel = 0; btn.Parent = card
	corner(btn, 8)

	if state == "owned" then
		btn.BackgroundColor3 = BTN_OWN
		btn.TextColor3       = DARK_TXT
		btn.Text             = "✓  OBTIDO"
		btn.Active           = false; btn.AutoButtonColor = false
	elseif state == "available" then
		btn.BackgroundColor3 = BTN_FREE
		btn.TextColor3       = WHITE
		btn.Text             = costText(j)
		btn.AutoButtonColor  = true
		btn.MouseButton1Click:Connect(function()
			buyRemote:FireServer(j.id)
		end)
	else
		btn.BackgroundColor3 = BTN_LOCK
		btn.TextColor3       = Color3.fromRGB(160, 150, 130)
		btn.Text             = "🔒  " .. costText(j)
		btn.Active           = false; btn.AutoButtonColor = false
	end
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
end

-- ── Abre / fecha ──────────────────────────────────────────────────────
local function open()
	if isOpen then return end
	isOpen = true
	rebuildCards()
	panel.Visible = true
	panel.BackgroundTransparency = 1
	TweenService:Create(panel,
		TweenInfo.new(0.20, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ BackgroundTransparency = 0.06 }):Play()
	panel:TweenSize(UDim2.new(0, 1200, 0, 310),
		Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.22, true)
end

local function close()
	if not isOpen then return end
	isOpen = false
	TweenService:Create(panel,
		TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
		{ BackgroundTransparency = 1 }):Play()
	task.delay(0.15, function() panel.Visible = false end)
end

-- ── Init ──────────────────────────────────────────────────────────────
function JumpShop.init()
	local R = require(RS.Shared.Remotes)

	buyRemote = RS:WaitForChild(R.BuyJump) :: RemoteEvent

	gui = Instance.new("ScreenGui")
	gui.Name = "JumpShop"; gui.ResetOnSpawn = false
	gui.DisplayOrder = 10; gui.Parent = player:WaitForChild("PlayerGui")

	-- Painel
	panel = Instance.new("Frame")
	panel.Name = "Panel"
	panel.Size = UDim2.new(0, 1200, 0, 310)
	panel.Position = UDim2.new(0.5, -600, 0.5, -155)
	panel.BackgroundColor3 = BG
	panel.BackgroundTransparency = 0.06
	panel.BorderSizePixel = 0
	panel.Visible = false
	panel.ClipsDescendants = true
	panel.Parent = gui
	corner(panel, 18)
	local ps = Instance.new("UIStroke"); ps.Color = GOLD; ps.Thickness = 2.5; ps.Parent = panel

	-- Header dourado
	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 50)
	header.BackgroundColor3 = HEADER_BG
	header.BorderSizePixel = 0; header.Parent = panel
	corner(header, 16)
	local hf = Instance.new("Frame")
	hf.Size = UDim2.new(1, 0, 0.5, 0); hf.Position = UDim2.new(0, 0, 0.5, 0)
	hf.BackgroundColor3 = HEADER_BG; hf.BorderSizePixel = 0; hf.Parent = header

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -60, 1, 0); title.Position = UDim2.new(0, 14, 0, 0)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold; title.TextScaled = true
	title.TextColor3 = DARK_TXT; title.TextXAlignment = Enum.TextXAlignment.Left
	title.Text = "⚡  YOUTUBER JUMP SHOP"; title.Parent = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size = UDim2.new(0, 38, 0, 38); closeBtn.Position = UDim2.new(1, -44, 0, 6)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	closeBtn.Font = Enum.Font.GothamBold; closeBtn.TextColor3 = WHITE
	closeBtn.TextSize = 20; closeBtn.Text = "✕"
	closeBtn.BorderSizePixel = 0; closeBtn.Parent = header
	corner(closeBtn, 8)
	closeBtn.MouseButton1Click:Connect(close)

	-- Scroll horizontal
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -58); scroll.Position = UDim2.new(0, 8, 0, 54)
	scroll.BackgroundTransparency = 1; scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 5; scroll.ScrollBarImageColor3 = GOLD
	scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.X
	scroll.ScrollingDirection = Enum.ScrollingDirection.X
	scroll.Parent = panel

	cardRow = Instance.new("Frame")
	cardRow.Name = "CardRow"; cardRow.Size = UDim2.new(0, 0, 1, 0)
	cardRow.AutomaticSize = Enum.AutomaticSize.X
	cardRow.BackgroundTransparency = 1; cardRow.Parent = scroll

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.Padding = UDim.new(0, 10); lay.Parent = cardRow

	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8); pad.PaddingRight = UDim.new(0, 8)
	pad.Parent = cardRow

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
