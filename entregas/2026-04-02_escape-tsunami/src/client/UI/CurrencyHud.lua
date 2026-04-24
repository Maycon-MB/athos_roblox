--!strict
-- CurrencyHud — bind de dados nos labels criados no Studio via Command Bar.
-- BrainrotsRow  > BrainrotsText  → total brainrots (SyncData)
-- MoneyRow2     > MoneyText      → dinheiro (SyncData)
-- MoneyRow      > redText        → WalkSpeed (Humanoid)
-- MoneyRow      > blueText       → JumpPower (Humanoid)
-- TotalMoneyRow > TotalMoneyText → $X.XXT verde (SyncData)
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local CurrencyHud = {}

local player = Players.LocalPlayer

local function abbreviate(n: number): string
	if n >= 1e12 then return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9  then return string.format("%.2fB", n / 1e9)
	elseif n >= 1e6  then return string.format("%.2fM", n / 1e6)
	elseif n >= 1e3  then return string.format("%.0fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

function CurrencyHud.init()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("CurrencyHud", 10) :: ScreenGui?
	if not gui then
		warn("[CurrencyHud] ScreenGui 'CurrencyHud' não encontrado.")
		return
	end

	local brainrotsLbl = gui:FindFirstChild("BrainrotsText",  true) :: TextLabel?
	local moneyLbl     = gui:FindFirstChild("MoneyText",      true) :: TextLabel?
	local totalLbl     = gui:FindFirstChild("TotalMoneyText", true) :: TextLabel?
	local redText      = gui:FindFirstChild("redText",        true) :: TextLabel?
	local blueText     = gui:FindFirstChild("blueText",       true) :: TextLabel?

	local function connectHumanoid(char: Model)
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		local function update()
			if redText  then redText.Text  = string.format("%.0f", hum.WalkSpeed) end
			if blueText then blueText.Text = string.format("%.0f", hum.JumpPower) end
		end
		update()
		hum:GetPropertyChangedSignal("WalkSpeed"):Connect(update)
		hum:GetPropertyChangedSignal("JumpPower"):Connect(update)
	end

	if player.Character then connectHumanoid(player.Character) end
	player.CharacterAdded:Connect(connectHumanoid)

	local R    = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		local totalBR = 0
		for _, e in (d.brainrots or {}) do totalBR += e.qty end
		local money = d.money or 0

		if brainrotsLbl then brainrotsLbl.Text = abbreviate(totalBR) end
		if moneyLbl     then moneyLbl.Text     = abbreviate(money) end
		if totalLbl     then totalLbl.Text     = "$" .. abbreviate(money) end
	end)
end

return CurrencyHud
