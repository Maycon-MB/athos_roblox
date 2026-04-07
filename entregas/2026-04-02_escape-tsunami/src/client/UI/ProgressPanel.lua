--!strict
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local ProgressPanel = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

function ProgressPanel.init()
	local gui = Instance.new("ScreenGui")
	gui.Name  = "ProgressPanel"; gui.ResetOnSpawn = false
	gui.Parent = player:WaitForChild("PlayerGui")

	local panel = Instance.new("Frame")
	panel.Size  = UDim2.new(0, 112, 0, #S.JUMPS * 68 + 32)
	panel.Position = UDim2.new(1,-124,0.5, -(#S.JUMPS * 34 + 16))
	panel.BackgroundColor3 = Color3.fromRGB(16, 14, 24)
	panel.BackgroundTransparency = 0.18
	panel.BorderSizePixel = 0; panel.Parent = gui
	local pc = Instance.new("UICorner"); pc.CornerRadius = UDim.new(0,12); pc.Parent = panel

	local title = Instance.new("TextLabel")
	title.Size  = UDim2.new(1,0,0,26)
	title.BackgroundTransparency = 1
	title.Font  = Enum.Font.GothamBold; title.TextScaled = true
	title.TextColor3 = Color3.new(1,1,1); title.Text = "JUMPS"; title.Parent = panel

	local list = Instance.new("Frame")
	list.Name  = "List"
	list.Size  = UDim2.new(1,-8,1,-30); list.Position = UDim2.new(0,4,0,28)
	list.BackgroundTransparency = 1; list.Parent = panel
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0,4)
	lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
	lay.Parent = list

	for _, j in S.JUMPS do
		local card = Instance.new("Frame")
		card.Name  = "Card_"..j.id
		card.Size  = UDim2.new(1,0,0,60)
		card.BackgroundColor3 = Color3.fromRGB(40,36,54)
		card.BorderSizePixel = 0; card.Parent = list
		local cc = Instance.new("UICorner"); cc.CornerRadius = UDim.new(0,8); cc.Parent = card
		local stroke = Instance.new("UIStroke")
		stroke.Name  = "Border"; stroke.Color = Color3.fromRGB(80,80,100)
		stroke.Thickness = 2; stroke.Parent = card

		local ico = Instance.new("Frame")
		ico.Name  = "Icon"
		ico.Size  = UDim2.new(0,36,0,36); ico.Position = UDim2.new(0.5,-18,0,3)
		ico.BackgroundColor3 = j.color or Color3.fromRGB(255, 255, 255); ico.BorderSizePixel = 0; ico.Parent = card
		local ic = Instance.new("UICorner"); ic.CornerRadius = UDim.new(0,6); ic.Parent = ico
		local iL = Instance.new("TextLabel")
		iL.Name  = "Label"
		iL.Size  = UDim2.new(1,0,1,0); iL.BackgroundTransparency = 1
		iL.Font  = Enum.Font.GothamBold; iL.TextScaled = true
		iL.TextColor3 = Color3.new(1,1,1)
		iL.Text  = string.upper(string.sub(j.id, 1, 2)); iL.Parent = ico

		local nL = Instance.new("TextLabel")
		nL.Size  = UDim2.new(1,-4,0,14); nL.Position = UDim2.new(0,2,1,-16)
		nL.BackgroundTransparency = 1
		nL.Font  = Enum.Font.Gotham; nL.TextScaled = true
		nL.TextColor3 = Color3.fromRGB(180,180,200); nL.Text = tostring(j.name or "---"); nL.Parent = card
	end

	local function markUnlocked(jumpId: string)
		local card = list:FindFirstChild("Card_"..jumpId) :: Frame?
		if not card then return end
		card.BackgroundColor3 = Color3.fromRGB(28, 90, 36)
		local border = card:FindFirstChild("Border") :: UIStroke?
		if border then border.Color = Color3.fromRGB(80, 220, 80) end
		local icon = card:FindFirstChild("Icon") :: Frame?
		if icon then
			icon.BackgroundColor3 = Color3.fromRGB(60, 200, 80)
			local lbl = icon:FindFirstChild("Label") :: TextLabel?
			if lbl then lbl.Text = "V" end
		end
	end

	local R = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		if not d then return end
		for _, id in (d.unlockedJumps or {}) do markUnlocked(id) end
	end)
	local purchased = RS:WaitForChild(R.JumpPurchased) :: RemoteEvent
	purchased.OnClientEvent:Connect(function(id: string) markUnlocked(id) end)
end

return ProgressPanel
