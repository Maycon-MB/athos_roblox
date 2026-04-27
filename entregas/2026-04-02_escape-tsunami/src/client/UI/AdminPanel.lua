--!strict
-- AdminPanel — Painel de controle para gravação cinematográfica.
-- F8 ou /admin abre/fecha. Seções: Areas, Economy, Jumps, Waves, Brainrots, Tools.
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local AdminPanel = {}

local player = Players.LocalPlayer
local _gui: ScreenGui? = nil

function AdminPanel.toggle()
	if _gui then _gui.Enabled = not _gui.Enabled end
end

-- ── Paleta ────────────────────────────────────────────────────────────
local BG       = Color3.fromRGB(10, 8, 18)
local HDR      = Color3.fromRGB(80, 20, 20)
local SEC      = Color3.fromRGB(255, 200, 40)
local DARK     = Color3.fromRGB(32, 28, 48)
local BLUE     = Color3.fromRGB(30, 80, 160)
local GREEN    = Color3.fromRGB(30, 130, 55)
local RED      = Color3.fromRGB(170, 35, 35)
local ORANGE   = Color3.fromRGB(180, 100, 20)
local WHITE    = Color3.new(1, 1, 1)

local function corner(p: Instance, r: number)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r); c.Parent = p
end

local function makeBtn(parent: Instance, text: string, color: Color3, onClick: () -> ()): TextButton
	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(1, 0, 0, 34)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel  = 0
	btn.Font             = Enum.Font.GothamBold
	btn.TextScaled       = true
	btn.TextColor3       = WHITE
	btn.Text             = text
	btn.AutoButtonColor  = true
	btn.Parent           = parent
	corner(btn, 7)
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function makeSection(parent: Instance, title: string)
	-- Spacer
	local sp = Instance.new("Frame")
	sp.Size = UDim2.new(1, 0, 0, 6)
	sp.BackgroundTransparency = 1
	sp.Parent = parent

	local lbl = Instance.new("TextLabel")
	lbl.Size                 = UDim2.new(1, 0, 0, 20)
	lbl.BackgroundColor3     = Color3.fromRGB(40, 32, 60)
	lbl.BackgroundTransparency = 0.3
	lbl.BorderSizePixel      = 0
	lbl.Font                 = Enum.Font.GothamBold
	lbl.TextScaled           = true
	lbl.TextColor3           = SEC
	lbl.TextXAlignment       = Enum.TextXAlignment.Left
	lbl.Text                 = "  " .. title
	lbl.Parent               = parent
	corner(lbl, 5)
end

-- ── TextBox + botão em linha ──────────────────────────────────────────
local function makeInputRow(parent: Instance, placeholder: string,
	btnText: string, color: Color3, onSubmit: (string) -> ())
	local row = Instance.new("Frame")
	row.Size = UDim2.new(1, 0, 0, 34)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local input = Instance.new("TextBox")
	input.Size             = UDim2.new(0.58, -2, 1, 0)
	input.BackgroundColor3 = Color3.fromRGB(28, 24, 42)
	input.BorderSizePixel  = 0
	input.Font             = Enum.Font.Gotham
	input.TextScaled       = true
	input.TextColor3       = WHITE
	input.PlaceholderText  = placeholder
	input.PlaceholderColor3 = Color3.fromRGB(90, 80, 110)
	input.Text             = ""
	input.Parent           = row
	corner(input, 7)

	local btn = Instance.new("TextButton")
	btn.Size             = UDim2.new(0.42, -2, 1, 0)
	btn.Position         = UDim2.new(0.58, 2, 0, 0)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel  = 0
	btn.Font             = Enum.Font.GothamBold
	btn.TextScaled       = true
	btn.TextColor3       = WHITE
	btn.Text             = btnText
	btn.AutoButtonColor  = true
	btn.Parent           = row
	corner(btn, 7)
	btn.MouseButton1Click:Connect(function()
		onSubmit(input.Text)
		input.Text = ""
	end)
end

function AdminPanel.init()
	local S = require(RS.Shared.Settings)
	local R = require(RS.Shared.Remotes)

	local gui = Instance.new("ScreenGui")
	gui.Name         = "AdminPanel"
	gui.ResetOnSpawn = false
	gui.Enabled      = false
	gui.DisplayOrder = 20
	gui.Parent       = player:WaitForChild("PlayerGui")
	_gui             = gui

	local panel = Instance.new("Frame")
	panel.Size             = UDim2.new(0, 300, 0, 580)
	panel.Position         = UDim2.new(1, -310, 0.5, -290)
	panel.BackgroundColor3 = BG
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel  = 0
	panel.Parent           = gui
	corner(panel, 14)
	local ps = Instance.new("UIStroke"); ps.Color = Color3.fromRGB(200, 40, 40); ps.Thickness = 1.5; ps.Parent = panel

	-- ── Header ────────────────────────────────────────────────────────
	local header = Instance.new("Frame")
	header.Size             = UDim2.new(1, 0, 0, 44)
	header.BackgroundColor3 = HDR
	header.BorderSizePixel  = 0
	header.Parent           = panel
	corner(header, 12)
	local hf = Instance.new("Frame")
	hf.Size = UDim2.new(1, 0, 0.5, 0); hf.Position = UDim2.new(0, 0, 0.5, 0)
	hf.BackgroundColor3 = HDR; hf.BorderSizePixel = 0; hf.Parent = header

	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -50, 1, 0)
	title.Position           = UDim2.new(0, 10, 0, 0)
	title.BackgroundTransparency = 1
	title.Font               = Enum.Font.GothamBold
	title.TextScaled         = true
	title.TextColor3         = WHITE
	title.TextXAlignment     = Enum.TextXAlignment.Left
	title.Text               = "⚙  ADMIN PANEL"
	title.Parent             = header

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, 34, 0, 34)
	closeBtn.Position         = UDim2.new(1, -40, 0, 5)
	closeBtn.BackgroundColor3 = RED
	closeBtn.BorderSizePixel  = 0
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextScaled       = true
	closeBtn.TextColor3       = WHITE
	closeBtn.Text             = "✕"
	closeBtn.Parent           = header
	corner(closeBtn, 7)
	closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

	-- ── Log (fundo inferior) ──────────────────────────────────────────
	local logBg = Instance.new("Frame")
	logBg.Size             = UDim2.new(1, -12, 0, 28)
	logBg.Position         = UDim2.new(0, 6, 1, -32)
	logBg.BackgroundColor3 = Color3.fromRGB(18, 28, 18)
	logBg.BorderSizePixel  = 0
	logBg.Parent           = panel
	corner(logBg, 6)

	local log = Instance.new("TextLabel")
	log.Name               = "Log"
	log.Size               = UDim2.new(1, -8, 1, 0)
	log.Position           = UDim2.new(0, 4, 0, 0)
	log.BackgroundTransparency = 1
	log.Font               = Enum.Font.Gotham
	log.TextScaled         = true
	log.TextColor3         = Color3.fromRGB(100, 255, 120)
	log.TextXAlignment     = Enum.TextXAlignment.Left
	log.Text               = "ready"
	log.Parent             = logBg

	-- ── ScrollingFrame do conteúdo ────────────────────────────────────
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size                = UDim2.new(1, -12, 1, -82)
	scroll.Position            = UDim2.new(0, 6, 0, 48)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel     = 0
	scroll.ScrollBarThickness  = 4
	scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 40, 40)
	scroll.CanvasSize          = UDim2.new(0, 0, 0, 0)
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent              = panel

	local lay = Instance.new("UIListLayout")
	lay.Padding   = UDim.new(0, 4)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent    = scroll

	local pad = Instance.new("UIPadding")
	pad.PaddingBottom = UDim.new(0, 6); pad.Parent = scroll

	local cmdRemote = RS:WaitForChild(R.AdminCmd)  :: RemoteEvent
	local respRemote = RS:WaitForChild(R.AdminResp) :: RemoteEvent

	local function cmd(action: string, arg: string)
		cmdRemote:FireServer(action, arg)
	end

	-- ── AREAS ─────────────────────────────────────────────────────────
	makeSection(scroll, "AREAS")
	local areaLabels: { { id: string, label: string } } = {
		{ id = "main", label = "🌊  Main Map" },
		{ id = "shop", label = "🛒  Secret Shop" },
	}
	if S.MAP_AREAS and S.MAP_AREAS.base then
		table.insert(areaLabels, { id = "base", label = "🏠  Base" })
	end
	for _, a in areaLabels do
		local aId = a.id
		makeBtn(scroll, a.label, BLUE, function() cmd("teleport", aId) end)
	end

	-- ── ECONOMY ───────────────────────────────────────────────────────
	makeSection(scroll, "ECONOMY")
	makeBtn(scroll, "💰  Max Money ($999M)", GREEN, function() cmd("give_money", "") end)
	makeInputRow(scroll, "e.g. 5000", "Set $", GREEN, function(v)
		local clean = v:gsub("[^%d]", "")
		if clean ~= "" then cmd("set_coins", clean) end
	end)
	makeBtn(scroll, "Set 500K", DARK, function() cmd("set_coins", "500000") end)
	makeBtn(scroll, "Reset Coins", RED, function() cmd("set_coins", "0") end)

	-- ── JUMPS ─────────────────────────────────────────────────────────
	makeSection(scroll, "JUMPS")
	for _, j in S.JUMPS do
		local jId    = j.id
		local jColor = (j.color or DARK):Lerp(Color3.fromRGB(10, 8, 20), 0.4)
		makeBtn(scroll, "⚡  " .. (j.label or j.id), jColor, function()
			cmd("give_jump", jId)
		end)
	end

	-- ── WAVES ─────────────────────────────────────────────────────────
	makeSection(scroll, "WAVES")
	makeBtn(scroll, "🌊  Wave (speed 40)",      DARK,   function() cmd("wave", "") end)
	makeBtn(scroll, "🌊  Fast Wave (speed 80)", ORANGE, function() cmd("fast_wave", "") end)

	-- ── BRAINROTS ─────────────────────────────────────────────────────
	makeSection(scroll, "BRAINROTS — GIVE")
	for _, br in S.BRAINROTS do
		local brId   = br.id
		local brName = br.name
		local brCol  = (br.color or DARK):Lerp(Color3.fromRGB(10, 8, 20), 0.45)
		makeBtn(scroll, "🎁  " .. brName, brCol, function()
			cmd("give_brainrot", brId)
		end)
	end

	makeSection(scroll, "BRAINROTS — SPAWN")
	local spawnState: { [string]: boolean } = {}
	local spawnBtns:  { [string]: TextButton } = {}
	for _, br in S.BRAINROTS do
		local brId   = br.id
		local brName = br.name
		spawnState[brId] = true
		local btn = makeBtn(scroll, "ON: " .. brName, GREEN, function()
			spawnState[brId] = not spawnState[brId]
			cmd("toggle_brainrot", brId)
			local on = spawnState[brId]
			spawnBtns[brId].Text             = (if on then "ON: " else "OFF: ") .. brName
			spawnBtns[brId].BackgroundColor3 = if on then GREEN else RED
		end)
		spawnBtns[brId] = btn
	end

	-- ── FERRAMENTAS ───────────────────────────────────────────────────
	makeSection(scroll, "TOOLS")
	makeBtn(scroll, "🛡️  God Mode Toggle", ORANGE, function() cmd("god_mode", "") end)
	makeBtn(scroll, "⚡  Reset Speed",      BLUE,   function() cmd("reset_speed", "") end)
	makeBtn(scroll, "🛒  Open Shop",        BLUE,   function() cmd("open_shop", "") end)
	makeBtn(scroll, "☠️  Kill All Noobs",   RED,    function() cmd("kill_all", "") end)
	makeBtn(scroll, "🔄  Reset Progress",   RED,    function() cmd("reset", "") end)

	-- ── Resposta do servidor ──────────────────────────────────────────
	respRemote.OnClientEvent:Connect(function(kind: string, msg: string?)
		if kind == "toggle" then
			gui.Enabled = not gui.Enabled
		elseif kind == "ok" or kind == "list" then
			log.Text = msg or "OK"
			task.delay(5, function()
				if log.Text == (msg or "OK") then log.Text = "ready" end
			end)
		end
	end)

	-- ── F8 toggle ─────────────────────────────────────────────────────
	local UIS = game:GetService("UserInputService")
	UIS.InputBegan:Connect(function(input: InputObject, processed: boolean)
		if processed then return end
		if input.KeyCode == Enum.KeyCode.F8 then
			gui.Enabled = not gui.Enabled
		end
	end)

	-- ── /admin via TextChatService ─────────────────────────────────────
	local ok2, TCS = pcall(function() return game:GetService("TextChatService") end)
	if ok2 and TCS then
		local tcCmd = Instance.new("TextChatCommand")
		tcCmd.Name           = "AdminToggle"
		tcCmd.PrimaryAlias   = "/admin"
		tcCmd.SecondaryAlias = "/adm"
		tcCmd.Parent         = TCS :: TextChatService
		tcCmd.Triggered:Connect(function(_src: Instance, _raw: string)
			gui.Enabled = not gui.Enabled
		end)
	end
end

return AdminPanel
