--!strict
-- Loja de Pulos de Youtubers — abre ao tocar CrackWall (ShowShop remote).
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local JumpShop = {}

local player  = Players.LocalPlayer
local S       = require(RS.Shared.Settings)

local gui: ScreenGui
local currentData: any = {}

local COST_LABELS: { [string]: string } = {
	free           = "FREE",
	money          = "$",
	survive_waves  = "Survive",
	kill_noobs     = "Kill",
	sell_brainrots = "Sell",
	fuse_brainrots = "Fuse",
}

local function costText(j: any): string
	local ct = j.cost_type :: string
	if ct == "free"           then return "FREE"
	elseif ct == "money"      then
		local v = j.cost_value :: number
		if v >= 1e6 then return "$"..string.format("%.0fM", v/1e6)
		elseif v >= 1e3 then return "$"..string.format("%.0fK", v/1e3)
		else return "$"..tostring(v) end
	elseif ct == "survive_waves"  then return "Survive "..tostring(j.cost_value).." waves"
	elseif ct == "kill_noobs"     then return "Kill "..tostring(j.cost_value).." noobs"
	elseif ct == "sell_brainrots" then return "Sell "..tostring(j.cost_value).." BRs"
	elseif ct == "fuse_brainrots" then return "Fuse "..tostring(j.cost_value).." BRs"
	end
	return "?"
end

local function canAfford(j: any): boolean
	local d = currentData
	if not d or not d.money then return false end
	local ct = j.cost_type :: string
	if ct == "free"           then return true
	elseif ct == "money"      then return (d.money or 0) >= j.cost_value
	elseif ct == "survive_waves"  then return (d.wavesSurvived or 0) >= j.cost_value
	elseif ct == "kill_noobs"     then return (d.noobsKilled or 0)   >= j.cost_value
	elseif ct == "sell_brainrots" then return (d.brainrotsSold or 0) >= j.cost_value
	elseif ct == "fuse_brainrots" then return (d.brainrotsFused or 0)>= j.cost_value
	end
	return false
end

local function buildCard(scroll: ScrollingFrame, j: any)
	local isOwned = false
	for _, id in (currentData.unlockedJumps or {}) do
		if id == j.id then isOwned = true; break end
	end

	local card = Instance.new("Frame")
	card.Name  = "Card_"..j.id
	card.Size  = UDim2.new(0, 160, 0, 220)
	card.BackgroundColor3 = j.color
	card.BackgroundTransparency = 0.15
	card.BorderSizePixel = 0; card.Parent = scroll
	local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0, 12); cc.Parent = card

	-- Owned overlay
	if isOwned then
		local ov = Instance.new("Frame")
		ov.Size  = UDim2.new(1,0,1,0); ov.BackgroundColor3 = Color3.fromRGB(30,120,40)
		ov.BackgroundTransparency = 0.3; ov.BorderSizePixel = 0; ov.Parent = card
		local oc = Instance.new("UICorner"); oc.CornerRadius = UDim.new(0,12); oc.Parent = ov
		local ol = Instance.new("TextLabel")
		ol.Size  = UDim2.new(1,0,1,0); ol.BackgroundTransparency = 1
		ol.Font  = Enum.Font.GothamBold; ol.TextScaled = true
		ol.TextColor3 = Color3.new(1,1,1); ol.Text = "✓"; ol.Parent = ov
		return
	end

	-- Shoe icon
	local shoe = Instance.new("TextLabel")
	shoe.Size  = UDim2.new(1,0,0,64)
	shoe.Position = UDim2.new(0,0,0,8)
	shoe.BackgroundTransparency = 1
	shoe.Font  = Enum.Font.GothamBold; shoe.TextScaled = true
	shoe.TextColor3 = Color3.new(1,1,1); shoe.Text = "👟"; shoe.Parent = card

	-- Name
	local name = Instance.new("TextLabel")
	name.Size  = UDim2.new(1,-8,0,28); name.Position = UDim2.new(0,4,0,74)
	name.BackgroundTransparency = 1
	name.Font  = Enum.Font.GothamBold; name.TextScaled = true
	name.TextColor3 = Color3.new(1,1,1); name.TextStrokeTransparency = 0.4
	name.Text  = j.name; name.Parent = card

	-- Stats
	local stats = Instance.new("TextLabel")
	stats.Size  = UDim2.new(1,-8,0,44); stats.Position = UDim2.new(0,4,0,104)
	stats.BackgroundTransparency = 1
	stats.Font  = Enum.Font.Gotham; stats.TextScaled = true; stats.TextWrapped = true
	stats.TextColor3 = Color3.fromRGB(220,220,220)
	stats.Text  = "Jump: "..tostring(j.jump).."\nSpeed: "..tostring(j.speed)
	stats.Parent = card

	-- Buy button
	local canBuy = canAfford(j)
	local btn = Instance.new("TextButton")
	btn.Size  = UDim2.new(1,-16,0,38); btn.Position = UDim2.new(0,8,1,-46)
	btn.BackgroundColor3 = if canBuy then Color3.fromRGB(40,180,60) else Color3.fromRGB(80,80,80)
	btn.BorderSizePixel = 0
	btn.Font  = Enum.Font.GothamBold; btn.TextScaled = true
	btn.TextColor3 = Color3.new(1,1,1); btn.Text = costText(j); btn.Parent = card
	local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0,8); bc.Parent = btn

	if canBuy then
		local R = require(RS.Shared.Remotes)
		local buyRemote = RS:WaitForChild(R.BuyJump) :: RemoteEvent
		btn.MouseButton1Click:Connect(function()
			buyRemote:FireServer(j.id)
			gui.Enabled = false
		end)
	end
end

local function rebuildCards()
	if not gui then return end
	local scroll = gui:FindFirstChild("Panel") and
		(gui:FindFirstChild("Panel") :: Frame):FindFirstChild("Scroll") :: ScrollingFrame?
	if not scroll then return end
	scroll:ClearAllChildren()

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.VerticalAlignment = Enum.VerticalAlignment.Center
	lay.Padding = UDim.new(0, 10); lay.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 10); pad.Parent = scroll

	for _, j in S.JUMPS do buildCard(scroll, j) end
	scroll.CanvasSize = UDim2.new(0, #S.JUMPS * 172, 0, 0)
end

function JumpShop.init()
	gui = Instance.new("ScreenGui")
	gui.Name = "JumpShop"; gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent  = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Name  = "Panel"
	panel.Size  = UDim2.new(0, 900, 0, 320)
	panel.Position = UDim2.new(0.5, -450, 0.5, -160)
	panel.BackgroundColor3 = Color3.fromRGB(18, 15, 28)
	panel.BackgroundTransparency = 0.05
	panel.BorderSizePixel = 0; panel.Parent = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0, 16); pc.Parent = panel

	-- Title bar
	local title = Instance.new("TextLabel")
	title.Size  = UDim2.new(1,-60,0,46)
	title.BackgroundTransparency = 1
	title.Font  = Enum.Font.GothamBold; title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(255,200,40)
	title.Text  = "JUMP SHOP"; title.Parent = panel

	local closeBtn = Instance.new("TextButton")
	closeBtn.Size  = UDim2.new(0, 38, 0, 38)
	closeBtn.Position = UDim2.new(1,-46,0,4)
	closeBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
	closeBtn.BorderSizePixel = 0
	closeBtn.Font  = Enum.Font.GothamBold; closeBtn.TextScaled = true
	closeBtn.TextColor3 = Color3.new(1,1,1); closeBtn.Text = "X"; closeBtn.Parent = panel
	local cbc = Instance.new("UICorner"); cbc.CornerRadius = UDim.new(0,8); cbc.Parent = closeBtn
	closeBtn.MouseButton1Click:Connect(function() gui.Enabled = false end)

	local scroll = Instance.new("ScrollingFrame")
	scroll.Name  = "Scroll"
	scroll.Size  = UDim2.new(1,-20,1,-54)
	scroll.Position = UDim2.new(0,10,0,50)
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.ScrollBarThickness = 6; scroll.Parent = panel

	local R = require(RS.Shared.Remotes)

	-- Open/close
	local showShop = RS:WaitForChild(R.ShowShop) :: RemoteEvent
	showShop.OnClientEvent:Connect(function()
		rebuildCards()
		gui.Enabled = true
	end)

	-- Update when data syncs
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		currentData = d
		if gui.Enabled then rebuildCards() end
	end)

	-- Mark owned on purchase
	local purchased = RS:WaitForChild(R.JumpPurchased) :: RemoteEvent
	purchased.OnClientEvent:Connect(function()
		if gui.Enabled then rebuildCards() end
	end)
end

return JumpShop
