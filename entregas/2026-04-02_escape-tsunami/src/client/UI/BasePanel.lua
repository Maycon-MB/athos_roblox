--!strict
-- BasePanel — Inventário de brainrots na base + income/s total.
-- Posição: canto direito. Atualiza via SyncData.
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local BasePanel = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)
local NAMES  = require(RS.Shared.Remotes)

local listFrame:   ScrollingFrame
local incomeLabel: TextLabel

local function fmt(n: number): string
	if n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.1fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

-- brainrots vem do servidor como array { {id:string, qty:number} }[]
local function incomePerSec(brainrots: { any }): number
	local total = 0
	for _, entry in brainrots do
		local e: any = entry
		for _, br in S.BRAINROTS do
			if br.id == e.id then
				total += br.income * (e.qty :: number)
				break
			end
		end
	end
	return total
end

local function rebuild(data: any)
	for _, c in listFrame:GetChildren() do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end

	local brainrots: { any } = data.brainrots or {}
	incomeLabel.Text = "$" .. fmt(incomePerSec(brainrots)) .. "/s"

	local sellEvent = RS:FindFirstChild(NAMES.SellBrainrot)

	-- Ordenar por raridade (mais raro primeiro)
	local list: { { id: string, qty: number, rarity: number } } = {}
	for _, entry in brainrots do
		local e: any = entry
		if (e.qty :: number) > 0 then
			local rarity = 1
			for _, br in S.BRAINROTS do
				if br.id == e.id then rarity = br.rarity; break end
			end
			table.insert(list, { id = e.id :: string, qty = e.qty :: number, rarity = rarity })
		end
	end
	table.sort(list, function(a, b) return a.rarity > b.rarity end)

	for _, entry in list do
		local name  = entry.id
		local color = Color3.fromRGB(200, 200, 200)
		local income = 0
		for _, br in S.BRAINROTS do
			if br.id == entry.id then
				name = br.name; color = br.color; income = br.income; break
			end
		end

		local row = Instance.new("Frame")
		row.Size             = UDim2.new(1, -4, 0, 38)
		row.BackgroundColor3 = Color3.fromRGB(28, 26, 38)
		row.BorderSizePixel  = 0
		row.Parent           = listFrame
		local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0, 6); rc.Parent = row

		local nameLbl = Instance.new("TextLabel")
		nameLbl.Size               = UDim2.new(0.52, 0, 1, 0)
		nameLbl.Position           = UDim2.new(0, 4, 0, 0)
		nameLbl.BackgroundTransparency = 1
		nameLbl.Font               = Enum.Font.GothamBold
		nameLbl.TextScaled         = true
		nameLbl.TextXAlignment     = Enum.TextXAlignment.Left
		nameLbl.TextColor3         = color
		nameLbl.Text               = (entry.qty > 1 and ("×" .. entry.qty .. " ") or "") .. name
		nameLbl.Parent             = row

		local incLbl = Instance.new("TextLabel")
		incLbl.Size               = UDim2.new(0.25, 0, 1, 0)
		incLbl.Position           = UDim2.new(0.52, 0, 0, 0)
		incLbl.BackgroundTransparency = 1
		incLbl.Font               = Enum.Font.Gotham
		incLbl.TextScaled         = true
		incLbl.TextColor3         = Color3.fromRGB(100, 220, 100)
		incLbl.Text               = "$" .. fmt(income) .. "/s"
		incLbl.Parent             = row

		local sellBtn = Instance.new("TextButton")
		sellBtn.Size             = UDim2.new(0.22, 0, 0.75, 0)
		sellBtn.Position         = UDim2.new(0.77, 0, 0.125, 0)
		sellBtn.BackgroundColor3 = Color3.fromRGB(200, 55, 55)
		sellBtn.Font             = Enum.Font.GothamBold
		sellBtn.TextScaled       = true
		sellBtn.TextColor3       = Color3.new(1, 1, 1)
		sellBtn.Text             = "Sell"
		sellBtn.BorderSizePixel  = 0
		sellBtn.Parent           = row
		local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 4); sc.Parent = sellBtn

		local capturedId = entry.id
		sellBtn.MouseButton1Click:Connect(function()
			if sellEvent then
				(sellEvent :: RemoteEvent):FireServer(capturedId)
			end
		end)
	end
end

function BasePanel.init()
	local gui = Instance.new("ScreenGui")
	gui.Name         = "BasePanel"
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 4
	gui.Parent       = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name                   = "Panel"
	panel.Size                   = UDim2.new(0, 248, 0, 330)
	panel.Position               = UDim2.new(1, -260, 0.5, -165)
	panel.BackgroundColor3       = Color3.fromRGB(16, 14, 24)
	panel.BackgroundTransparency = 0.15
	panel.BorderSizePixel        = 0
	panel.Parent                 = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 12); pc.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size               = UDim2.new(1, -36, 0, 34)
	title.BackgroundTransparency = 1
	title.Font               = Enum.Font.GothamBold
	title.TextScaled         = true
	title.TextColor3         = Color3.fromRGB(255, 200, 40)
	title.Text               = "YOUR BASE"
	title.Parent             = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size             = UDim2.new(0, 28, 0, 28)
	closeBtn.Position         = UDim2.new(1, -32, 0, 3)
	closeBtn.BackgroundColor3 = Color3.fromRGB(180, 45, 45)
	closeBtn.Font             = Enum.Font.GothamBold
	closeBtn.TextColor3       = Color3.new(1, 1, 1)
	closeBtn.TextSize         = 14
	closeBtn.Text             = "✕"
	closeBtn.BorderSizePixel  = 0
	closeBtn.Parent           = panel
	local cc2 = Instance.new("UICorner"); cc2.CornerRadius = UDim.new(0, 6); cc2.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function()
		panel.Visible = false
	end)

	incomeLabel = Instance.new("TextLabel")
	incomeLabel.Size               = UDim2.new(1, 0, 0, 26)
	incomeLabel.Position           = UDim2.new(0, 0, 0, 34)
	incomeLabel.BackgroundTransparency = 1
	incomeLabel.Font               = Enum.Font.Gotham
	incomeLabel.TextScaled         = true
	incomeLabel.TextColor3         = Color3.fromRGB(100, 220, 100)
	incomeLabel.Text               = "$0/s"
	incomeLabel.Parent             = panel

	listFrame = Instance.new("ScrollingFrame")
	listFrame.Name                = "List"
	listFrame.Size                = UDim2.new(1, -8, 1, -68)
	listFrame.Position            = UDim2.new(0, 4, 0, 64)
	listFrame.BackgroundTransparency = 1
	listFrame.ScrollBarThickness  = 4
	listFrame.CanvasSize          = UDim2.new(0, 0, 0, 0)
	listFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
	listFrame.Parent              = panel

	local layout = Instance.new("UIListLayout")
	layout.SortOrder  = Enum.SortOrder.LayoutOrder
	layout.Padding    = UDim.new(0, 4)
	layout.Parent     = listFrame

	-- Visível sempre (pedestais ficam na área main; painel mostra inventário da base em qualquer área)
	panel.Visible = true

	local syncData = RS:WaitForChild(NAMES.SyncData) :: RemoteEvent
	syncData.OnClientEvent:Connect(function(data: any)
		if data then rebuild(data) end
	end)
end

return BasePanel
