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
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
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
	money          = "",
	survive_waves  = "",
	kill_noobs     = "💀",
	sell_brainrots = "",
	fuse_brainrots = "",
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
	if ct == "money" then return "$" .. fmtMoney(j.cost_value :: number) end
	return "×" .. tostring(j.cost_value)
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

local function applyState(card: Frame, j: any, state: string)
	local btn = card:FindFirstChild("PriceBtn", true) :: TextButton?
	if not btn then warn("[JumpShop] PriceBtn não encontrado em", card.Name) return end

	-- Desativa todos os UIGradients do botão para não interferir
	for _, g in btn:GetDescendants() do
		if g:IsA("UIGradient") then g.Enabled = false end
	end

	btn.BackgroundTransparency = 0
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)

	local mainColor: Color3
	local darkColor: Color3
	if state == "owned" then
		mainColor = Color3.fromRGB(30, 110, 140)
		darkColor = Color3.fromRGB(15, 65, 90)
		btn.Text = "✓ OWNED"
		btn.Active = false
		btn.AutoButtonColor = false
	elseif state == "available" then
		mainColor = Color3.fromRGB(60, 180, 50)
		darkColor = Color3.fromRGB(30, 110, 20)
		btn.Text = costText(j)
		btn.Active = true
		btn.AutoButtonColor = false
	else
		mainColor = Color3.fromRGB(100, 100, 100)
		darkColor = Color3.fromRGB(60, 60, 60)
		btn.Text = costText(j)
		btn.Active = false
		btn.AutoButtonColor = false
	end

	btn.BackgroundColor3 = mainColor

	-- Imagem de preço customizada (sobrescreve texto)
	local priceImg = btn:FindFirstChild("PriceImage") :: ImageLabel?
	local priceLbl = btn:FindFirstChild("PriceLabel") :: TextLabel?
	if j.price_image and j.price_image ~= "" and state ~= "owned" then
		btn.Text = ""
		btn.ClipsDescendants = false
		local hasLabel = j.price_label and j.price_label ~= ""
		if not priceImg then
			local newImg = Instance.new("ImageLabel")
			newImg.Name = "PriceImage"
			newImg.BackgroundTransparency = 1
			newImg.ScaleType = Enum.ScaleType.Fit
			newImg.ZIndex = btn.ZIndex + 5
			newImg.Parent = btn
			priceImg = newImg
		end
		local img = priceImg :: ImageLabel
		img.Image = j.price_image
		img.Position = UDim2.new(0, 0, 0, 0)
		if hasLabel then
			img.Size = UDim2.new(0.45, 0, 0.85, 0)
			img.Position = UDim2.new(j.price_img_x or 0, j.price_img_x and 0 or 4, 0.075, 0)
			btn.Text = j.price_label
			btn.TextXAlignment = Enum.TextXAlignment.Right
			local pad = btn:FindFirstChildOfClass("UIPadding") or Instance.new("UIPadding", btn)
			pad.PaddingRight = UDim.new(j.price_padding_right or 0.08, 0)
		else
			img.Size = UDim2.new(1, 0, 1, 0)
			btn.Text = ""
			btn.TextXAlignment = Enum.TextXAlignment.Center
		end
		img.Visible = true
		if priceLbl then priceLbl.Visible = false end
	elseif priceImg then
		priceImg.Visible = false
		if priceLbl then priceLbl.Visible = false end
		btn.TextXAlignment = Enum.TextXAlignment.Center
	end

	-- Barra escura no fundo (efeito 3D)
	local bar = btn:FindFirstChild("BottomBar") :: Frame?
	if not bar then
		bar = Instance.new("Frame")
		;(bar :: Frame).Name = "BottomBar"
		;(bar :: Frame).Size = UDim2.new(1, 0, 0, 6)
		;(bar :: Frame).Position = UDim2.new(0, 0, 1, -6)
		;(bar :: Frame).BorderSizePixel = 0
		;(bar :: Frame).ZIndex = btn.ZIndex + 1
		;(bar :: Frame).Parent = btn
	end
	;(bar :: Frame).BackgroundColor3 = darkColor
end

local function populateCard(card: Frame, j: any, state: string)
	card.Name = "Card_" .. j.id

	local nameLbl = card:FindFirstChild("NameLbl", true) :: TextLabel?
	if nameLbl then
		nameLbl.Text = (j.name or j.label or "?") .. " Jump Boost"
	end

	local subLbl = card:FindFirstChild("SubLbl", true) :: TextLabel?
	if subLbl then
		if type(j.rewards) == "table" then
			subLbl.Text = ""
			local banner = subLbl.Parent
			local row = banner:FindFirstChild("RewardsRow")
			if row then row:Destroy() end
			row = Instance.new("Frame")
			row.Name           = "RewardsRow"
			row.Size           = UDim2.new(subLbl.Size.X.Scale, subLbl.Size.X.Offset, subLbl.Size.Y.Scale, subLbl.Size.Y.Offset)
			row.Position       = subLbl.Position
			row.BackgroundTransparency = 1
			row.ClipsDescendants = false
			row.Parent         = banner
			local lay = Instance.new("UIListLayout", row)
			lay.FillDirection       = Enum.FillDirection.Horizontal
			lay.VerticalAlignment   = Enum.VerticalAlignment.Center
			lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
			lay.Padding             = UDim.new(0, 3)
			lay.SortOrder           = Enum.SortOrder.LayoutOrder
			local order = 0
			for _, item in (j.rewards :: any) do
				order += 1
				local img = Instance.new("ImageLabel", row)
				img.LayoutOrder         = order
				local sz = (item.s or 24) :: number
				img.Size                = UDim2.new(0, sz, 0, sz)
				img.BackgroundTransparency = 1
				img.ScaleType           = Enum.ScaleType.Fit
				img.Image               = "rbxassetid://" .. item.i
				if item.v then
					order += 1
					local lbl = Instance.new("TextLabel", row)
					lbl.LayoutOrder       = order
					lbl.Size              = UDim2.new(0, 26, 0, 24)
					lbl.BackgroundTransparency = 1
					lbl.Font              = Enum.Font.GothamBold
					lbl.TextScaled        = true
					lbl.TextColor3        = Color3.fromRGB(220, 220, 220)
					lbl.TextXAlignment    = Enum.TextXAlignment.Left
					lbl.Text              = item.v :: string
					local stroke = Instance.new("UIStroke", lbl)
					stroke.Color           = Color3.new(0, 0, 0)
					stroke.Thickness       = 1.5
					stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual
				end
			end
			-- Escala proporcionalmente se o conteúdo passar da largura do row
			task.defer(function()
				if not row or not row.Parent then return end
				local contentW = lay.AbsoluteContentSize.X
				local rowW     = row.AbsoluteSize.X
				if contentW > 0 and rowW > 0 and contentW > rowW then
					local us = Instance.new("UIScale", row)
					us.Scale = rowW / contentW
				end
			end)
		else
			subLbl.Text = j.rewards or ""
		end
	end

	-- Icon: ImageLabel dentro do ImgArea do template. Script só troca .Image.
	-- Imagens ficam em Settings.JUMPS[i].image (rbxassetid://...)
	local icon = card:FindFirstChild("Icon", true) :: ImageLabel?
	if icon and j.image and j.image ~= "" then
		icon.Image = j.image
	end

	applyState(card, j, state)

	local btn = card:FindFirstChild("PriceBtn", true) :: TextButton?
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

function JumpShop.open() open() end

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
