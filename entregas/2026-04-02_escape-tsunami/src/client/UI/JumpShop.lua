--!strict
-- JumpShop — consome template editado visualmente no Studio (StarterGui.JumpShop).
-- Toda criação visual vive em em_manutencao.rbxl; este script só preenche dados
-- e conecta interações. Edite o template no Studio → Ctrl+S → funciona.
--
-- Hierarquia esperada do template:
--   ScreenGui "JumpShop"
--     Panel
--       Header
--         CloseBtn
--       CardsBox
--         Scroll
--           CardRow (UIListLayout)
--         LeftArrow
--         RightArrow
--     Templates
--       CardTemplate (com descendants: NameLbl, SubLbl, Face, Shoe, PriceBtn)
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local JumpShop = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

-- ── Emojis por tier (sobrescrevem Face.Text; edite no template pra mudar fonte/cor) ──
local FACE_EMOJI: { [string]: string } = {
	james   = "👦",
	jj      = "🧒",
	mana    = "👧",
	pdoro   = "🧑",
	matheus = "👨",
	caylus  = "🤴",
	athos   = "🔥",
}

local COST_ICON: { [string]: string } = {
	money          = "💰",
	survive_waves  = "🌊",
	kill_noobs     = "💀",
	sell_brainrots = "💱",
	fuse_brainrots = "🔥",
}

-- ── Gradientes dos estados do PriceBtn (substituem o UIGradient do template) ──
local BTN_GREEN_TOP = Color3.fromRGB(110, 230, 80)
local BTN_GREEN_BOT = Color3.fromRGB(40, 160, 40)
local BTN_GOLD_TOP  = Color3.fromRGB(255, 215, 70)
local BTN_GOLD_BOT  = Color3.fromRGB(220, 150, 20)
local BTN_LOCK_TOP  = Color3.fromRGB(150, 150, 150)
local BTN_LOCK_BOT  = Color3.fromRGB(90, 90, 90)
local BTN_OWN_TOP   = Color3.fromRGB(80, 200, 220)
local BTN_OWN_BOT   = Color3.fromRGB(30, 110, 140)

local function fmtMoney(v: number): string
	if v >= 1e6 then return string.format("%.0fM", v / 1e6)
	elseif v >= 1e3 then return string.format("%.0fK", v / 1e3)
	else return tostring(v) end
end

local function costText(j: any): string
	local ct = j.cost_type :: string
	if ct == "free" then return "FREE" end
	local icon = COST_ICON[ct] or ""
	if ct == "money" then
		return icon .. " $" .. fmtMoney(j.cost_value :: number)
	end
	return icon .. " ×" .. tostring(j.cost_value)
end

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

local gui:          ScreenGui
local panel:        Frame
local scroll:       ScrollingFrame
local cardRow:      Frame
local cardTemplate: Frame
local leftArrow:    TextButton
local rightArrow:   TextButton
local cardWidth     = 170
local cardGap       = 12
local currentData: any = {}
local buyRemote:    RemoteEvent
local isOpen        = false

-- ── Aplica o gradiente do estado no PriceBtn ──
local function setBtnGradient(btn: Instance, top: Color3, bot: Color3)
	local g = btn:FindFirstChildWhichIsA("UIGradient")
	if g then
		g.Color = ColorSequence.new(top, bot)
		g.Rotation = 90
	else
		local ng = Instance.new("UIGradient")
		ng.Color = ColorSequence.new(top, bot)
		ng.Rotation = 90
		ng.Parent = btn
	end
end

local function applyState(card: Frame, j: any, state: string)
	local btn = card:FindFirstChild("PriceBtn") :: TextButton?
	if not btn then return end
	if state == "owned" then
		setBtnGradient(btn, BTN_OWN_TOP, BTN_OWN_BOT)
		btn.Text = "✓ OWNED"
		btn.Active = false
		btn.AutoButtonColor = false
	elseif state == "available" then
		if (j.cost_type :: string) == "free" then
			setBtnGradient(btn, BTN_GREEN_TOP, BTN_GREEN_BOT)
		else
			setBtnGradient(btn, BTN_GOLD_TOP, BTN_GOLD_BOT)
		end
		btn.Text = costText(j)
		btn.Active = true
		btn.AutoButtonColor = true
	else
		setBtnGradient(btn, BTN_LOCK_TOP, BTN_LOCK_BOT)
		btn.Text = costText(j)
		btn.Active = false
		btn.AutoButtonColor = false
	end
end

local function populateCard(card: Frame, j: any, state: string)
	card.Name = "Card_" .. j.id

	local nameLbl = card:FindFirstChild("NameLbl", true) :: TextLabel?
	if nameLbl then
		nameLbl.Text = (j.name or j.label or "?") .. " Jump Boost"
	end

	local subLbl = card:FindFirstChild("SubLbl", true) :: TextLabel?
	if subLbl then
		subLbl.Text = j.rewards or ""
	end

	local face = card:FindFirstChild("Face", true) :: TextLabel?
	if face then
		face.Text = FACE_EMOJI[j.id] or "👤"
	end

	local shoe = card:FindFirstChild("Shoe", true) :: ImageLabel?
	if shoe and j.image and j.image ~= "" then
		shoe.Image = j.image
	end

	applyState(card, j, state)

	local btn = card:FindFirstChild("PriceBtn") :: TextButton?
	if btn and state == "available" then
		btn.MouseButton1Click:Connect(function()
			buyRemote:FireServer(j.id)
		end)
	end
end

local function updateArrows()
	if not scroll or not leftArrow or not rightArrow then return end
	local hasOverflow = scroll.AbsoluteCanvasSize.X > scroll.AbsoluteSize.X + 1
	leftArrow.Visible = hasOverflow
	rightArrow.Visible = hasOverflow
end

local function rebuildCards()
	for _, c in cardRow:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then c:Destroy() end
	end
	for _, j in S.JUMPS do
		if not j or not j.id then continue end
		local clone = cardTemplate:Clone()
		clone.Visible = true
		clone.Parent = cardRow
		populateCard(clone, j, cardState(j, currentData))
	end
	task.defer(updateArrows)
end

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

local function open()
	if isOpen then return end
	isOpen = true
	rebuildCards()
	scroll.CanvasPosition = Vector2.new(0, 0)
	gui.Enabled = true
end

local function close()
	if not isOpen then return end
	isOpen = false
	gui.Enabled = false
end

function JumpShop.init()
	local R = require(RS.Shared.Remotes)
	buyRemote = RS:WaitForChild(R.BuyJump) :: RemoteEvent

	local playerGui = player:WaitForChild("PlayerGui")
	local guiInst = playerGui:WaitForChild("JumpShop", 10)
	if not guiInst or not guiInst:IsA("ScreenGui") then
		warn("[JumpShop] Template 'JumpShop' não encontrado em PlayerGui. Verifique StarterGui no .rbxl.")
		return
	end
	gui = guiInst :: ScreenGui
	gui.Enabled = false
	gui.DisplayOrder = 10
	gui.ResetOnSpawn = false

	panel = gui:WaitForChild("Panel") :: Frame

	local header = panel:WaitForChild("Header") :: Frame
	local closeBtn = header:WaitForChild("CloseBtn") :: TextButton
	closeBtn.MouseButton1Click:Connect(close)

	local cardsBox = panel:WaitForChild("CardsBox") :: Frame
	scroll = cardsBox:WaitForChild("Scroll") :: ScrollingFrame
	cardRow = scroll:WaitForChild("CardRow") :: Frame

	leftArrow  = cardsBox:WaitForChild("LeftArrow") :: TextButton
	rightArrow = cardsBox:WaitForChild("RightArrow") :: TextButton
	leftArrow.MouseButton1Click:Connect(function() scrollBy(-(cardWidth + cardGap)) end)
	rightArrow.MouseButton1Click:Connect(function() scrollBy(cardWidth + cardGap) end)
	scroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateArrows)
	scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateArrows)

	-- Extrai CardTemplate e descarta a pasta Templates do PlayerGui
	local templates = gui:WaitForChild("Templates") :: Folder
	local tmpl = templates:WaitForChild("CardTemplate") :: Frame
	cardTemplate = tmpl:Clone()
	cardWidth = tmpl.Size.X.Offset > 0 and tmpl.Size.X.Offset or cardWidth
	local lay = cardRow:FindFirstChildWhichIsA("UIListLayout")
	if lay then cardGap = lay.Padding.Offset end
	templates:Destroy()

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
