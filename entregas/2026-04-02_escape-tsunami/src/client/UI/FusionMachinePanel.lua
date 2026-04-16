--!strict
-- FusionMachinePanel — UI de fusão de brainrots.
-- Abre via ShowFusionPanel (Remote). Jogador seleciona 2 brainrots → clica Fuse.
-- Estética: escuro + neon roxo, consistente com o resto do jogo.
local Players      = game:GetService("Players")
local RS           = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local FusionMachinePanel = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

-- Cores base
local BG       = Color3.fromRGB(14, 12, 22)
local BG2      = Color3.fromRGB(22, 18, 36)
local PURPLE   = Color3.fromRGB(140, 60, 255)
local PURPLE_D = Color3.fromRGB(80, 30, 160)
local GREEN    = Color3.fromRGB(50, 200, 80)
local RED      = Color3.fromRGB(200, 50, 50)
local GOLD     = Color3.fromRGB(255, 200, 40)
local WHITE    = Color3.new(1, 1, 1)
local GRAY     = Color3.fromRGB(90, 85, 110)

local gui:      ScreenGui
local panel:    Frame
local slotA:    Frame
local slotB:    Frame
local fuseBtn:  TextButton
local resultLbl: TextLabel
local listFrame: ScrollingFrame

-- Estado de seleção
local selectedA: string? = nil
local selectedB: string? = nil
local currentInventory: { any } = {}

-- Remotes (resolvidos no init)
local fuseRemote:   RemoteEvent
local fuseResult:   RemoteEvent
local showPanel:    RemoteEvent
local syncData:     RemoteEvent

-- ── Helpers de UI ────────────────────────────────────────────────────
local function corner(parent: Instance, r: number)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = parent
end

local function stroke(parent: Instance, color: Color3, thick: number)
	local s = Instance.new("UIStroke")
	s.Color = color; s.Thickness = thick
	s.Parent = parent
end

local function label(parent: Instance, text: string, font: Enum.Font,
	color: Color3, size: UDim2, pos: UDim2): TextLabel
	local l = Instance.new("TextLabel")
	l.Size = size; l.Position = pos
	l.BackgroundTransparency = 1
	l.Font = font; l.TextScaled = true
	l.TextColor3 = color; l.Text = text
	l.Parent = parent
	return l
end

-- ── Nome e cor do brainrot por id ────────────────────────────────────
local function brainrotInfo(id: string): (string, Color3)
	for _, br in S.BRAINROTS do
		if br.id == id then
			return br.name, br.color or PURPLE
		end
	end
	return id, GRAY
end

-- ── Atualiza visual dos slots ─────────────────────────────────────────
local function refreshSlots()
	-- Slot A
	local nameA = slotA:FindFirstChild("Name") :: TextLabel?
	local icoA  = slotA:FindFirstChild("Ico")  :: TextLabel?
	if selectedA then
		local n, c = brainrotInfo(selectedA)
		if nameA then nameA.Text = n; nameA.TextColor3 = c end
		if icoA  then icoA.Text  = "🟣" end
		local s2 = slotA:FindFirstChild("Stroke") :: UIStroke?
		if s2 then s2.Color = PURPLE end
	else
		if nameA then nameA.Text = "Slot A"; nameA.TextColor3 = GRAY end
		if icoA  then icoA.Text  = "+" end
		local s2 = slotA:FindFirstChild("Stroke") :: UIStroke?
		if s2 then s2.Color = GRAY end
	end

	-- Slot B
	local nameB = slotB:FindFirstChild("Name") :: TextLabel?
	local icoB  = slotB:FindFirstChild("Ico")  :: TextLabel?
	if selectedB then
		local n, c = brainrotInfo(selectedB)
		if nameB then nameB.Text = n; nameB.TextColor3 = c end
		if icoB  then icoB.Text  = "🟣" end
		local s2 = slotB:FindFirstChild("Stroke") :: UIStroke?
		if s2 then s2.Color = PURPLE end
	else
		if nameB then nameB.Text = "Slot B"; nameB.TextColor3 = GRAY end
		if icoB  then icoB.Text  = "+" end
		local s2 = slotB:FindFirstChild("Stroke") :: UIStroke?
		if s2 then s2.Color = GRAY end
	end

	-- Botão FUSE: ativo só com 2 selecionados
	local ready = selectedA ~= nil and selectedB ~= nil
	fuseBtn.BackgroundColor3 = if ready then PURPLE else GRAY
	fuseBtn.AutoButtonColor  = ready
	fuseBtn.Active           = ready
	local fs = fuseBtn:FindFirstChild("Stroke") :: UIStroke?
	if fs then fs.Color = if ready then PURPLE else GRAY end
end

-- ── Constrói card de brainrot no inventário ───────────────────────────
local function buildInventoryCard(id: string, qty: number)
	local name, col = brainrotInfo(id)

	local card = Instance.new("TextButton")
	card.Name             = "Card_" .. id
	card.Size             = UDim2.new(1, -8, 0, 52)
	card.BackgroundColor3 = BG2
	card.BorderSizePixel  = 0
	card.Text             = ""
	card.AutoButtonColor  = false
	card.Parent           = listFrame
	corner(card, 8)
	stroke(card, GRAY, 1.5)

	-- Emoji / ícone
	local ico = Instance.new("TextLabel")
	ico.Size = UDim2.new(0, 44, 1, -8)
	ico.Position = UDim2.new(0, 4, 0, 4)
	ico.BackgroundColor3 = col
	ico.BackgroundTransparency = 0.55
	ico.BorderSizePixel = 0
	ico.Font = Enum.Font.GothamBold
	ico.TextScaled = true
	ico.TextColor3 = WHITE
	ico.Text = "🟣"
	ico.Parent = card
	corner(ico, 6)

	-- Nome
	local nm = label(card, name, Enum.Font.GothamBold, col,
		UDim2.new(1, -56, 0.55, 0), UDim2.new(0, 52, 0, 4))
	nm.TextXAlignment = Enum.TextXAlignment.Left

	-- Quantidade
	local qt = label(card, "×" .. qty, Enum.Font.Gotham, GRAY,
		UDim2.new(1, -56, 0.38, 0), UDim2.new(0, 52, 0.56, 0))
	qt.TextXAlignment = Enum.TextXAlignment.Left

	-- Click: preenche slot A depois slot B
	card.MouseButton1Click:Connect(function()
		if selectedA == nil then
			selectedA = id
		elseif selectedB == nil and id ~= selectedA then
			selectedB = id
		elseif selectedA == id then
			selectedA = selectedB
			selectedB = nil
		elseif selectedB == id then
			selectedB = nil
		else
			-- ambos preenchidos e clicou num terceiro: substitui slot B
			selectedB = id
		end

		-- highlight: borda neon se selecionado
		local st = card:FindFirstChild("UIStroke") :: UIStroke?
		if st then
			st.Color = if (id == selectedA or id == selectedB) then PURPLE else GRAY
			st.Thickness = if (id == selectedA or id == selectedB) then 2.5 else 1.5
		end
		refreshSlots()
	end)

	return card
end

-- ── Reconstrói lista do inventário ───────────────────────────────────
local function rebuildList()
	for _, c in listFrame:GetChildren() do
		if not c:IsA("UIListLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	-- Reseta seleção se brainrots sumiram
	local hasA = false; local hasB = false
	for _, entry in currentInventory do
		local e: any = entry
		if e.qty > 0 then
			if e.id == selectedA then hasA = true end
			if e.id == selectedB then hasB = true end
		end
	end
	if not hasA then selectedA = nil end
	if not hasB then selectedB = nil end

	local any = false
	for _, entry in currentInventory do
		local e: any = entry
		if (e.qty :: number) > 0 then
			buildInventoryCard(e.id :: string, e.qty :: number)
			any = true
		end
	end
	if not any then
		label(listFrame, "No brainrots in inventory", Enum.Font.Gotham, GRAY,
			UDim2.new(1, 0, 0, 36), UDim2.new(0, 0, 0, 8))
	end
	refreshSlots()
end

-- ── Abre / fecha com tween ────────────────────────────────────────────
local isOpen = false

local function open()
	if isOpen then return end
	isOpen = true
	resultLbl.Text = ""
	selectedA = nil; selectedB = nil
	rebuildList()
	panel.Visible = true
	panel.BackgroundTransparency = 1
	TweenService:Create(panel, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 0.08
	}):Play()
	panel:TweenSize(UDim2.new(0, 420, 0, 500),
		Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.22, true)
end

local function close()
	if not isOpen then return end
	isOpen = false
	local t = TweenService:Create(panel, TweenInfo.new(0.14, Enum.EasingStyle.Quad), {
		BackgroundTransparency = 1
	})
	t:Play()
	t.Completed:Connect(function() panel.Visible = false end)
end

-- ── Constrói um slot de seleção ───────────────────────────────────────
local function makeSlot(parent: Instance, pos: UDim2): Frame
	local f = Instance.new("Frame")
	f.Size             = UDim2.new(0, 130, 0, 110)
	f.Position         = pos
	f.BackgroundColor3 = BG2
	f.BorderSizePixel  = 0
	f.Parent           = parent
	corner(f, 12)
	local st = stroke(f, GRAY, 2) -- saved as "Stroke" child
	;(f:FindFirstChildOfClass("UIStroke") :: UIStroke).Name = "Stroke"

	local ico = label(f, "+", Enum.Font.GothamBold, GRAY,
		UDim2.new(1, 0, 0.5, 0), UDim2.new(0, 0, 0.04, 0))
	ico.Name = "Ico"
	ico.TextXAlignment = Enum.TextXAlignment.Center

	local nm = label(f, "Slot", Enum.Font.Gotham, GRAY,
		UDim2.new(1, -8, 0.32, 0), UDim2.new(0, 4, 0.62, 0))
	nm.Name = "Name"
	nm.TextXAlignment = Enum.TextXAlignment.Center

	return f
end

-- ── Init principal ────────────────────────────────────────────────────
function FusionMachinePanel.init()
	local R = require(RS.Shared.Remotes)

	gui = Instance.new("ScreenGui")
	gui.Name         = "FusionMachinePanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 12
	gui.Parent       = player:WaitForChild("PlayerGui")

	-- Painel principal
	panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.new(0, 420, 0, 500)
	panel.Position               = UDim2.new(0.5, -210, 0.5, -250)
	panel.BackgroundColor3       = BG
	panel.BackgroundTransparency = 0.08
	panel.BorderSizePixel        = 0
	panel.Visible                = false
	panel.Parent                 = gui
	corner(panel, 16)
	stroke(panel, PURPLE, 2)

	-- ── Header ──────────────────────────────────────────────────────────
	local header = Instance.new("Frame")
	header.Size             = UDim2.new(1, 0, 0, 48)
	header.BackgroundColor3 = PURPLE_D
	header.BackgroundTransparency = 0.15
	header.BorderSizePixel  = 0
	header.Parent           = panel
	corner(header, 14)
	-- cobre cantos inferiores do header
	local hFix = Instance.new("Frame")
	hFix.Size = UDim2.new(1, 0, 0.5, 0); hFix.Position = UDim2.new(0, 0, 0.5, 0)
	hFix.BackgroundColor3 = PURPLE_D; hFix.BackgroundTransparency = 0.15
	hFix.BorderSizePixel = 0; hFix.Parent = header

	label(header, "🔥  FUSION MACHINE", Enum.Font.GothamBold, WHITE,
		UDim2.new(1, -50, 1, 0), UDim2.new(0, 12, 0, 0))

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, 36, 0, 36)
	closeBtn.Position         = UDim2.new(1, -42, 0, 6)
	closeBtn.BackgroundColor3 = RED
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextColor3       = WHITE
	closeBtn.TextScaled       = true
	closeBtn.Text             = "✕"
	closeBtn.BorderSizePixel  = 0
	closeBtn.Parent           = header
	corner(closeBtn, 8)
	closeBtn.MouseButton1Click:Connect(close)

	-- ── Área dos slots ───────────────────────────────────────────────────
	local slotsRow = Instance.new("Frame")
	slotsRow.Size             = UDim2.new(1, -24, 0, 120)
	slotsRow.Position         = UDim2.new(0, 12, 0, 56)
	slotsRow.BackgroundTransparency = 1
	slotsRow.Parent           = panel

	slotA = makeSlot(slotsRow, UDim2.new(0, 0, 0, 0))
	slotB = makeSlot(slotsRow, UDim2.new(1, -130, 0, 0))

	-- "+" central
	label(slotsRow, "+", Enum.Font.GothamBold, PURPLE,
		UDim2.new(0, 40, 0, 40), UDim2.new(0.5, -20, 0, 35))

	-- seta "→" para resultado
	label(slotsRow, "→  ?", Enum.Font.GothamBold, GOLD,
		UDim2.new(0, 60, 0, 24), UDim2.new(0.5, -20, 0, 46))

	-- ── Label resultado ──────────────────────────────────────────────────
	resultLbl = label(panel, "", Enum.Font.GothamBold, GREEN,
		UDim2.new(1, -24, 0, 28), UDim2.new(0, 12, 0, 182))
	resultLbl.TextXAlignment = Enum.TextXAlignment.Center

	-- ── Separador ────────────────────────────────────────────────────────
	local sep = Instance.new("Frame")
	sep.Size             = UDim2.new(1, -24, 0, 1)
	sep.Position         = UDim2.new(0, 12, 0, 218)
	sep.BackgroundColor3 = PURPLE
	sep.BackgroundTransparency = 0.6
	sep.BorderSizePixel  = 0
	sep.Parent           = panel

	label(panel, "Select 2 brainrots from your inventory", Enum.Font.Gotham, GRAY,
		UDim2.new(1, -24, 0, 18), UDim2.new(0, 12, 0, 224))

	-- ── Lista de inventário ───────────────────────────────────────────────
	listFrame = Instance.new("ScrollingFrame")
	listFrame.Name                = "List"
	listFrame.Size                = UDim2.new(1, -24, 0, 170)
	listFrame.Position            = UDim2.new(0, 12, 0, 248)
	listFrame.BackgroundColor3    = BG2
	listFrame.BackgroundTransparency = 0.3
	listFrame.BorderSizePixel     = 0
	listFrame.ScrollBarThickness  = 4
	listFrame.ScrollBarImageColor3 = PURPLE
	listFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent              = panel
	corner(listFrame, 10)

	local lay = Instance.new("UIListLayout")
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding   = UDim.new(0, 4)
	lay.Parent    = listFrame
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4); pad.PaddingLeft = UDim.new(0, 4)
	pad.PaddingRight = UDim.new(0, 4); pad.Parent = listFrame

	-- ── Botão FUSE ────────────────────────────────────────────────────────
	fuseBtn = Instance.new("TextButton")
	fuseBtn.Size             = UDim2.new(1, -24, 0, 44)
	fuseBtn.Position         = UDim2.new(0, 12, 1, -52)
	fuseBtn.BackgroundColor3 = GRAY
	fuseBtn.Font             = Enum.Font.GothamBold
	fuseBtn.TextColor3       = WHITE
	fuseBtn.TextScaled       = true
	fuseBtn.Text             = "🔥  FUSE ×2"
	fuseBtn.BorderSizePixel  = 0
	fuseBtn.Active           = false
	fuseBtn.AutoButtonColor  = false
	fuseBtn.Parent           = panel
	corner(fuseBtn, 10)
	local fs = Instance.new("UIStroke")
	fs.Name = "Stroke"; fs.Color = GRAY; fs.Thickness = 2
	fs.Parent = fuseBtn

	fuseBtn.MouseButton1Click:Connect(function()
		if not selectedA or not selectedB then return end
		if not fuseBtn.Active then return end
		fuseBtn.Active = false
		fuseBtn.BackgroundColor3 = GRAY
		fuseBtn.Text = "⏳ Fundindo..."
		fuseRemote:FireServer(selectedA, selectedB)
	end)

	-- ── Escuta resultados ─────────────────────────────────────────────────
	fuseResult = RS:WaitForChild(R.FuseResult) :: RemoteEvent
	fuseResult.OnClientEvent:Connect(function(ok: boolean, msg: string)
		resultLbl.Text       = msg
		resultLbl.TextColor3 = if ok then GREEN else RED
		fuseBtn.Text         = "🔥  FUSE ×2"
		selectedA = nil; selectedB = nil
		-- Fecha após 2s se deu certo
		if ok then
			task.delay(2, function()
				if isOpen then close() end
			end)
		else
			-- Mantém aberto para tentar de novo
			refreshSlots()
		end
	end)

	-- ── Escuta SyncData para atualizar inventário ─────────────────────────
	syncData = RS:WaitForChild(R.SyncData) :: RemoteEvent
	syncData.OnClientEvent:Connect(function(data: any)
		if data and data.brainrots then
			currentInventory = data.brainrots
			if isOpen then rebuildList() end
		end
	end)

	-- ── Abre ao receber ShowFusionPanel ───────────────────────────────────
	showPanel = RS:WaitForChild(R.ShowFusionPanel) :: RemoteEvent
	showPanel.OnClientEvent:Connect(open)
end

return FusionMachinePanel
