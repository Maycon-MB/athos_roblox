--!strict
-- JumpShop — Loja de Pulos de Youtubers.
-- Abre via ShowShop (CrackWall). Progressive revelation: owned → available → locked.
-- Design: fundo escuro, borda neon, símbolos (sem texto desnecessário).
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local JumpShop = {}

local player     = Players.LocalPlayer
local S          = require(RS.Shared.Settings)

-- ── Tabela de rewards por tier (texto para câmera, emojis) ───────────
local REWARDS: { [string]: string } = {
	james   = "🎁 Jamezini",
	jj      = "🎁 Mikey · 🛡️ Shield",
	mana    = "💛 Hearts · 🏠 Base MAX",
	pdoro   = "🌊 10.000 Tokens",
	matheus = "🎁 ×3 Glaciero · 🏏 Galaxy Bat",
	caylus  = "🎁 ×3 Lucky Box",
	athos   = "🔥 Base cheia Athos",
}

local gui: ScreenGui
local currentData: any = {}

-- ── Custo formatado com símbolo ───────────────────────────────────────
local function costText(j: any): string
	local ct = j.cost_type :: string
	if ct == "free" then
		return "🆓 FREE"
	elseif ct == "money" then
		local v = j.cost_value :: number
		if v >= 1e6 then return "💰 " .. string.format("%.0fM", v / 1e6)
		elseif v >= 1e3 then return "💰 " .. string.format("%.0fK", v / 1e3)
		else return "💰 " .. tostring(v) end
	elseif ct == "survive_waves"  then return "🌊 ×" .. tostring(j.cost_value)
	elseif ct == "kill_noobs"     then return "☠️ ×" .. tostring(j.cost_value)
	elseif ct == "sell_brainrots" then return "💱 ×" .. tostring(j.cost_value)
	elseif ct == "fuse_brainrots" then return "🔥 ×" .. tostring(j.cost_value)
	end
	return "?"
end

-- ── Verifica se jogador pode comprar ─────────────────────────────────
local function canAfford(j: any): boolean
	local d = currentData
	if not d then return false end
	local ct = j.cost_type :: string
	if ct == "free"           then return true
	elseif ct == "money"      then return (d.money or 0) >= j.cost_value
	elseif ct == "survive_waves"  then return (d.wavesSurvived or 0) >= j.cost_value
	elseif ct == "kill_noobs"     then return (d.noobsKilled or 0) >= j.cost_value
	elseif ct == "sell_brainrots" then return (d.brainrotsSold or 0) >= j.cost_value
	elseif ct == "fuse_brainrots" then return (d.brainrotsFused or 0) >= j.cost_value
	end
	return false
end

-- ── Constrói card individual ──────────────────────────────────────────
-- state: "owned" | "available" | "locked"
local function buildCard(parent: Instance, j: any, state: string)
	local card = Instance.new("Frame")
	card.Name             = "Card_" .. j.id
	card.Size             = UDim2.new(0, 154, 0, 230)
	card.BackgroundColor3 = Color3.fromRGB(20, 18, 30)
	card.BackgroundTransparency = 0.05
	card.BorderSizePixel  = 0
	card.Parent           = parent
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 14); cc.Parent = card

	-- Borda neon lateral (cor do tier)
	local border = Instance.new("Frame")
	border.Size             = UDim2.new(0, 4, 1, -8)
	border.Position         = UDim2.new(0, 0, 0, 4)
	border.BackgroundColor3 = if state == "locked"
		then Color3.fromRGB(60, 60, 70)
		else (j.color or Color3.fromRGB(255, 200, 40))
	border.BorderSizePixel  = 0
	border.Parent           = card
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 4); bc.Parent = border

	-- ── ESTADO: COMPRADO ─────────────────────────────────────────────
	if state == "owned" then
		local ov = Instance.new("Frame")
		ov.Size                   = UDim2.new(1, 0, 1, 0)
		ov.BackgroundColor3       = Color3.fromRGB(30, 110, 45)
		ov.BackgroundTransparency = 0.25
		ov.BorderSizePixel        = 0
		ov.Parent                 = card
		local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0, 14); oc.Parent = ov

		local check = Instance.new("TextLabel")
		check.Size                   = UDim2.new(1, 0, 0.55, 0)
		check.Position               = UDim2.new(0, 0, 0.05, 0)
		check.BackgroundTransparency = 1
		check.Font                   = Enum.Font.GothamBold
		check.TextScaled             = true
		check.TextColor3             = Color3.new(1, 1, 1)
		check.Text                   = "✓"
		check.Parent                 = ov

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size                   = UDim2.new(1, -8, 0, 28)
		nameLbl.Position               = UDim2.new(0, 4, 0.62, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font                   = Enum.Font.GothamBold
		nameLbl.TextScaled             = true
		nameLbl.TextColor3             = Color3.new(1, 1, 1)
		nameLbl.Text                   = j.name or j.label
		nameLbl.Parent                 = ov
		return
	end

	-- ── ESTADO: BLOQUEADO ────────────────────────────────────────────
	if state == "locked" then
		-- Shoe icon apagado
		local shoe = Instance.new("TextLabel")
		shoe.Size                   = UDim2.new(1, 0, 0, 60)
		shoe.Position               = UDim2.new(0, 0, 0, 10)
		shoe.BackgroundTransparency = 1
		shoe.Font                   = Enum.Font.GothamBold
		shoe.TextScaled             = true
		shoe.TextColor3             = Color3.fromRGB(60, 60, 70)
		shoe.Text                   = "👟"
		shoe.Parent                 = card

		-- Lock icon
		local lock = Instance.new("TextLabel")
		lock.Size                   = UDim2.new(0, 40, 0, 40)
		lock.Position               = UDim2.new(0.5, -20, 0, 16)
		lock.BackgroundTransparency = 1
		lock.Font                   = Enum.Font.GothamBold
		lock.TextScaled             = true
		lock.TextColor3             = Color3.fromRGB(200, 200, 200)
		lock.Text                   = "🔒"
		lock.Parent                 = card

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size                   = UDim2.new(1, -8, 0, 24)
		nameLbl.Position               = UDim2.new(0, 4, 0, 76)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font                   = Enum.Font.GothamBold
		nameLbl.TextScaled             = true
		nameLbl.TextColor3             = Color3.fromRGB(90, 90, 100)
		nameLbl.Text                   = j.name or j.label
		nameLbl.Parent                 = card

		local costLbl = Instance.new("TextLabel")
		costLbl.Size                   = UDim2.new(1, -8, 0, 20)
		costLbl.Position               = UDim2.new(0, 4, 0, 102)
		costLbl.BackgroundTransparency = 1
		costLbl.Font                   = Enum.Font.Gotham
		costLbl.TextScaled             = true
		costLbl.TextColor3             = Color3.fromRGB(80, 80, 90)
		costLbl.Text                   = costText(j)
		costLbl.Parent                 = card

		local btnLocked = Instance.new("TextButton")
		btnLocked.Size             = UDim2.new(1, -12, 0, 36)
		btnLocked.Position         = UDim2.new(0, 6, 1, -42)
		btnLocked.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
		btnLocked.BorderSizePixel  = 0
		btnLocked.Font             = Enum.Font.GothamBold
		btnLocked.TextScaled       = true
		btnLocked.TextColor3       = Color3.fromRGB(80, 80, 90)
		btnLocked.Text             = "🔒 LOCKED"
		btnLocked.AutoButtonColor  = false
		btnLocked.Parent           = card
		local blc = Instance.new("UICorner"); blc.CornerRadius = UDim.new(0, 8); blc.Parent = btnLocked
		return
	end

	-- ── ESTADO: DISPONÍVEL ───────────────────────────────────────────
	local shoe = Instance.new("TextLabel")
	shoe.Size                   = UDim2.new(1, 0, 0, 68)
	shoe.Position               = UDim2.new(0, 0, 0, 6)
	shoe.BackgroundTransparency = 1
	shoe.Font                   = Enum.Font.GothamBold
	shoe.TextScaled             = true
	shoe.TextColor3             = Color3.new(1, 1, 1)
	shoe.Text                   = "👟"
	shoe.Parent                 = card

	local nameLbl = Instance.new("TextLabel")
	nameLbl.Size                   = UDim2.new(1, -8, 0, 26)
	nameLbl.Position               = UDim2.new(0, 4, 0, 76)
	nameLbl.BackgroundTransparency = 1
	nameLbl.Font                   = Enum.Font.GothamBold
	nameLbl.TextScaled             = true
	nameLbl.TextColor3             = j.color or Color3.fromRGB(255, 200, 40)
	nameLbl.TextStrokeTransparency = 0.5
	nameLbl.Text                   = j.name or j.label
	nameLbl.Parent                 = card

	local statsLbl = Instance.new("TextLabel")
	statsLbl.Size                   = UDim2.new(1, -8, 0, 20)
	statsLbl.Position               = UDim2.new(0, 4, 0, 104)
	statsLbl.BackgroundTransparency = 1
	statsLbl.Font                   = Enum.Font.Gotham
	statsLbl.TextScaled             = true
	statsLbl.TextColor3             = Color3.fromRGB(200, 200, 200)
	statsLbl.Text                   = string.format("↑%d  ⚡%d", j.jump, j.speed)
	statsLbl.Parent                 = card

	local rewardLbl = Instance.new("TextLabel")
	rewardLbl.Size                   = UDim2.new(1, -8, 0, 28)
	rewardLbl.Position               = UDim2.new(0, 4, 0, 126)
	rewardLbl.BackgroundTransparency = 1
	rewardLbl.Font                   = Enum.Font.Gotham
	rewardLbl.TextScaled             = true
	rewardLbl.TextWrapped            = true
	rewardLbl.TextColor3             = Color3.fromRGB(160, 220, 160)
	rewardLbl.Text                   = REWARDS[j.id] or ""
	rewardLbl.Parent                 = card

	local affordable = canAfford(j)
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, -12, 0, 36)
	btn.Position         = UDim2.new(0, 6, 1, -42)
	btn.BackgroundColor3 = if affordable
		then Color3.fromRGB(35, 170, 55)
		else Color3.fromRGB(60, 60, 75)
	btn.BorderSizePixel  = 0
	btn.Font             = Enum.Font.GothamBold
	btn.TextScaled       = true
	btn.TextColor3       = Color3.new(1, 1, 1)
	btn.Text             = costText(j)
	btn.AutoButtonColor  = affordable
	btn.Parent           = card
	local btnC = Instance.new("UICorner"); btnC.CornerRadius = UDim.new(0, 8); btnC.Parent = btn

	if affordable then
		local R      = require(RS.Shared.Remotes)
		local buyEv  = RS:WaitForChild(R.BuyJump) :: RemoteEvent
		btn.MouseButton1Click:Connect(function()
			buyEv:FireServer(j.id)
			gui.Enabled = false
		end)
	end
end

-- ── Reconstrói todos os cards com estado correto ──────────────────────
local function rebuildCards()
	if not gui then return end
	local panel  = gui:FindFirstChild("Panel") :: Frame?
	local scroll = panel and panel:FindFirstChild("Scroll") :: ScrollingFrame?
	if not scroll then return end
	scroll:ClearAllChildren()

	local lay = Instance.new("UIListLayout")
	lay.FillDirection      = Enum.FillDirection.Horizontal
	lay.VerticalAlignment  = Enum.VerticalAlignment.Center
	lay.Padding            = UDim.new(0, 10)
	lay.Parent             = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.Parent      = scroll

	-- Determina índice do último tier comprado
	local unlocked: { [string]: boolean } = {}
	for _, id in (currentData.unlockedJumps or {}) do
		unlocked[id] = true
	end

	local lastOwnedIdx = 0
	for i, j in S.JUMPS do
		if unlocked[j.id] then lastOwnedIdx = i end
	end

	for i, j in S.JUMPS do
		local state: string
		if unlocked[j.id] then
			state = "owned"
		elseif i == lastOwnedIdx + 1 then
			state = "available"
		else
			state = "locked"
		end
		buildCard(scroll, j, state)
	end

	scroll.CanvasSize = UDim2.new(0, #S.JUMPS * 166, 0, 0)
end

function JumpShop.init()
	gui = Instance.new("ScreenGui")
	gui.Name         = "JumpShop"
	gui.ResetOnSpawn = false
	gui.Enabled      = false
	gui.Parent       = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.new(0, 940, 0, 320)
	panel.Position               = UDim2.new(0.5, -470, 0.5, -160)
	panel.BackgroundColor3       = Color3.fromRGB(14, 12, 22)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel        = 0
	panel.Parent                 = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 18); pc.Parent = panel

	-- Linha superior neon
	local topLine = Instance.new("Frame")
	topLine.Size             = UDim2.new(1, -36, 0, 3)
	topLine.Position         = UDim2.new(0, 18, 0, 44)
	topLine.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
	topLine.BorderSizePixel  = 0
	topLine.Parent           = panel

	local title = Instance.new("TextLabel")
	title.Size                   = UDim2.new(1, -60, 0, 44)
	title.BackgroundTransparency = 1
	title.Font                   = Enum.Font.GothamBold
	title.TextScaled             = true
	title.TextColor3             = Color3.fromRGB(255, 200, 40)
	title.TextXAlignment         = Enum.TextXAlignment.Left
	title.Text                   = "  JUMP SHOP"
	title.Parent                 = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, 36, 0, 36)
	closeBtn.Position         = UDim2.new(1, -44, 0, 4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(190, 45, 45)
	closeBtn.BorderSizePixel  = 0
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextScaled       = true
	closeBtn.TextColor3       = Color3.new(1, 1, 1)
	closeBtn.Text             = "✕"
	closeBtn.Parent           = panel
	local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0, 8); cbc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name                = "Scroll"
	scroll.Size                = UDim2.new(1, -20, 1, -56)
	scroll.Position            = UDim2.new(0, 10, 0, 52)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel     = 0
	scroll.ScrollBarThickness  = 5
	scroll.Parent              = panel

	local R = require(RS.Shared.Remotes)

	local showShop = RS:WaitForChild(R.ShowShop) :: RemoteEvent
	showShop.OnClientEvent:Connect(function()
		rebuildCards()
		gui.Enabled = true
	end)

	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		currentData = d
		if gui.Enabled then rebuildCards() end
	end)

	local purchased = RS:WaitForChild(R.JumpPurchased) :: RemoteEvent
	purchased.OnClientEvent:Connect(function()
		if gui.Enabled then rebuildCards() end
	end)
end

return JumpShop
