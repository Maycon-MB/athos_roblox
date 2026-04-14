--!strict
-- AdminPanel — Painel de controle expandido para gravação cinematográfica.
-- /admin no chat abre. Seções: Areas, Economy, Jumps, Waves, Tools.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local AdminPanel = {}

local player = Players.LocalPlayer

local function makeBtn(parent: Instance, text: string, color: Color3, onClick: () -> ())
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(1, 0, 0, 36)
	btn.BackgroundColor3 = color
	btn.BorderSizePixel = 0
	btn.Font = Enum.Font.GothamBold
	btn.TextScaled = true
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.Text = text
	btn.Parent = parent
	local bc = Instance.new("UICorner")
	bc.CornerRadius = UDim.new(0, 8)
	bc.Parent = btn
	btn.MouseButton1Click:Connect(onClick)
	return btn
end

local function makeSection(parent: Instance, title: string): Frame
	local header = Instance.new("TextLabel")
	header.Size = UDim2.new(1, 0, 0, 22)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamBold
	header.TextScaled = true
	header.TextColor3 = Color3.fromRGB(255, 200, 40)
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.Text = "— " .. title
	header.Parent = parent
	return header :: any
end

function AdminPanel.init()
	local S = require(RS.Shared.Settings)
	local R = require(RS.Shared.Remotes)

	local gui = Instance.new("ScreenGui")
	gui.Name = "AdminPanel"
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.DisplayOrder = 20
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size = UDim2.new(0, 320, 0, 600)
	panel.Position = UDim2.new(1, -330, 0.5, -300)
	panel.BackgroundColor3 = Color3.fromRGB(12, 10, 20)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0
	panel.Parent = gui
	local pc = Instance.new("UICorner")
	pc.CornerRadius = UDim.new(0, 14)
	pc.Parent = panel

	-- Title
	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -48, 0, 40)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255, 80, 80)
	title.Text = "ADMIN PANEL"
	title.Parent = panel

	-- Close button
	local close = Instance.new("TextButton")
	close.Size = UDim2.new(0, 36, 0, 36)
	close.Position = UDim2.new(1, -44, 0, 2)
	close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	close.BorderSizePixel = 0
	close.Font = Enum.Font.GothamBold
	close.TextScaled = true
	close.TextColor3 = Color3.new(1, 1, 1)
	close.Text = "X"
	close.Parent = panel
	local cc = Instance.new("UICorner")
	cc.CornerRadius = UDim.new(0, 7)
	cc.Parent = close
	close.MouseButton1Click:Connect(function()
		gui.Enabled = false
	end)

	-- Log label
	local log = Instance.new("TextLabel")
	log.Name = "Log"
	log.Size = UDim2.new(1, -16, 0, 24)
	log.Position = UDim2.new(0, 8, 1, -30)
	log.BackgroundTransparency = 1
	log.Font = Enum.Font.Gotham
	log.TextScaled = true
	log.TextColor3 = Color3.fromRGB(120, 255, 120)
	log.Text = ""
	log.Parent = panel

	-- Scrollable content
	local scroll = Instance.new("ScrollingFrame")
	scroll.Size = UDim2.new(1, -16, 1, -80)
	scroll.Position = UDim2.new(0, 8, 0, 46)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 4
	scroll.Parent = panel
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 4)
	lay.Parent = scroll

	local cmdRemote = RS:WaitForChild(R.AdminCmd) :: RemoteEvent
	local resp = RS:WaitForChild(R.AdminResp) :: RemoteEvent

	local darkBtn = Color3.fromRGB(38, 32, 58)
	local blueBtn = Color3.fromRGB(30, 80, 160)
	local greenBtn = Color3.fromRGB(30, 120, 50)
	local redBtn = Color3.fromRGB(160, 40, 40)

	-- ── AREAS ────────────────────────────────────────────────────────
	makeSection(scroll, "AREAS")
	local areas = { "main", "shop", "base" }
	for _, area in areas do
		local areaName = area
		local label = if S.MAP_AREAS and S.MAP_AREAS[area] then S.MAP_AREAS[area].label else area:upper()
		makeBtn(scroll, label, blueBtn, function()
			cmdRemote:FireServer("teleport", areaName)
		end)
	end

	-- ── ECONOMY ──────────────────────────────────────────────────────
	makeSection(scroll, "ECONOMY")
	makeBtn(scroll, "Max Money ($999M)", greenBtn, function()
		cmdRemote:FireServer("give_money", "")
	end)
	-- TextBox para valor customizado
	local moneyRow = Instance.new("Frame")
	moneyRow.Size = UDim2.new(1, 0, 0, 36)
	moneyRow.BackgroundTransparency = 1
	moneyRow.Parent = scroll
	local moneyInput = Instance.new("TextBox")
	moneyInput.Size = UDim2.new(0.55, -2, 1, 0)
	moneyInput.BackgroundColor3 = Color3.fromRGB(30, 28, 44)
	moneyInput.BorderSizePixel = 0
	moneyInput.Font = Enum.Font.Gotham
	moneyInput.TextScaled = true
	moneyInput.TextColor3 = Color3.new(1,1,1)
	moneyInput.PlaceholderText = "valor ex: 5000"
	moneyInput.Text = ""
	moneyInput.Parent = moneyRow
	local mic = Instance.new("UICorner"); mic.CornerRadius = UDim.new(0,8); mic.Parent = moneyInput
	local moneySetBtn = Instance.new("TextButton")
	moneySetBtn.Size = UDim2.new(0.45, -2, 1, 0)
	moneySetBtn.Position = UDim2.new(0.55, 2, 0, 0)
	moneySetBtn.BackgroundColor3 = greenBtn
	moneySetBtn.BorderSizePixel = 0
	moneySetBtn.Font = Enum.Font.GothamBold
	moneySetBtn.TextScaled = true
	moneySetBtn.TextColor3 = Color3.new(1,1,1)
	moneySetBtn.Text = "Set $"
	moneySetBtn.Parent = moneyRow
	local msc = Instance.new("UICorner"); msc.CornerRadius = UDim.new(0,8); msc.Parent = moneySetBtn
	moneySetBtn.MouseButton1Click:Connect(function()
		local v = moneyInput.Text:gsub("[^%d]", "")
		if v ~= "" then cmdRemote:FireServer("set_coins", v) end
	end)
	makeBtn(scroll, "Set 500K", darkBtn, function() cmdRemote:FireServer("set_coins", "500000") end)
	makeBtn(scroll, "Set 0 Coins", redBtn, function() cmdRemote:FireServer("set_coins", "0") end)

	-- ── JUMPS ────────────────────────────────────────────────────────
	makeSection(scroll, "JUMPS")
	for _, j in S.JUMPS do
		local jumpId = j.id
		local jumpColor = j.color or darkBtn
		makeBtn(scroll, "Give: " .. (j.label or j.id), jumpColor, function()
			cmdRemote:FireServer("give_jump", jumpId)
		end)
	end

	-- ── WAVES ────────────────────────────────────────────────────────
	makeSection(scroll, "WAVES")
	makeBtn(scroll, "Wave (speed 40)", darkBtn, function()
		cmdRemote:FireServer("wave", "")
	end)
	makeBtn(scroll, "Fast Wave (speed 80)", darkBtn, function()
		cmdRemote:FireServer("fast_wave", "")
	end)

	-- ── BRAINROTS ────────────────────────────────────────────────────
	makeSection(scroll, "BRAINROTS — DAR")
	for _, br in S.BRAINROTS do
		local brId   = br.id
		local brName = br.name
		local brCol  = br.color or darkBtn
		makeBtn(scroll, "+ " .. brName, brCol, function()
			cmdRemote:FireServer("give_brainrot", brId)
		end)
	end

	makeSection(scroll, "BRAINROTS — SPAWN")
	-- Toggle por brainrot: verde = ON, cinza = OFF
	local spawnState: { [string]: boolean } = {}
	local spawnBtns: { [string]: TextButton } = {}
	for _, br in S.BRAINROTS do
		local brId   = br.id
		local brName = br.name
		spawnState[brId] = true -- começa habilitado
		local btn = makeBtn(scroll, "✓ " .. brName .. " spawn", greenBtn, function()
			spawnState[brId] = not spawnState[brId]
			cmdRemote:FireServer("toggle_brainrot", brId)
			spawnBtns[brId].Text = (if spawnState[brId] then "✓ " else "✗ ") .. brName .. " spawn"
			spawnBtns[brId].BackgroundColor3 = if spawnState[brId] then greenBtn else redBtn
		end)
		spawnBtns[brId] = btn
	end

	-- ── TOOLS ────────────────────────────────────────────────────────
	makeSection(scroll, "TOOLS")
	makeBtn(scroll, "God Mode Toggle", Color3.fromRGB(200, 160, 0), function()
		cmdRemote:FireServer("god_mode", "")
	end)
	makeBtn(scroll, "Reset Speed", Color3.fromRGB(60, 130, 200), function()
		cmdRemote:FireServer("reset_speed", "")
	end)
	makeBtn(scroll, "Open Shop", blueBtn, function()
		cmdRemote:FireServer("open_shop", "")
	end)
	makeBtn(scroll, "Kill All", redBtn, function()
		cmdRemote:FireServer("kill_all", "")
	end)
	makeBtn(scroll, "List Players", darkBtn, function()
		cmdRemote:FireServer("list", "")
	end)
	makeBtn(scroll, "Reset Progress", redBtn, function()
		cmdRemote:FireServer("reset", "")
	end)

	-- Auto-size canvas
	lay:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)
	end)
	scroll.CanvasSize = UDim2.new(0, 0, 0, lay.AbsoluteContentSize.Y + 10)

	-- Response handler (comandos do servidor)
	resp.OnClientEvent:Connect(function(kind: string, msg: string?)
		if kind == "toggle" then
			gui.Enabled = not gui.Enabled
		elseif kind == "ok" then
			log.Text = msg or "OK"
		elseif kind == "list" then
			log.Text = msg or ""
		end
	end)

	-- Tecla F9 abre/fecha o painel (funciona independente do modo de chat)
	local UIS = game:GetService("UserInputService")
	UIS.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then return end
		if input.KeyCode == Enum.KeyCode.F8 then
			gui.Enabled = not gui.Enabled
		end
	end)

	-- Tenta TextChatCommand como fallback (novo chat)
	local ok, TCS = pcall(function() return game:GetService("TextChatService") end)
	if ok and TCS then
		local cmd = Instance.new("TextChatCommand")
		cmd.Name           = "AdminToggle"
		cmd.PrimaryAlias   = "/admin"
		cmd.SecondaryAlias = "/adm"
		cmd.Parent         = TCS :: TextChatService
		cmd.Triggered:Connect(function(_src: Instance, _raw: string)
			gui.Enabled = not gui.Enabled
		end)
	end
end

return AdminPanel
