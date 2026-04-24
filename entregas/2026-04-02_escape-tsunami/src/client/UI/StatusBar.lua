--!strict
-- StatusBar — consome template editado no Studio (StarterGui.StatusBar).
-- NÃO cria UI. Só encontra TextLabels por nome e atualiza números via SyncData.
-- Toda iteração visual = Studio Property panel.
--
-- Hierarquia esperada (qualquer lugar dentro de StarterGui.StatusBar):
--   TextLabel "Value_Brainrots"   → total de brainrots coletados (fmt)
--   TextLabel "Value_Money"       → d.money (fmt)
--   TextLabel "Value_Jumps"       → "N/7" (count de unlockedJumps)
--   TextLabel "Value_Tokens"      → d.waveTokens (fmt)
--   TextLabel "Value_Fused"       → d.brainrotsFused (fmt)
--   TextLabel "Value_Kills"       → d.noobsKilled (fmt)
--   TextLabel "Value_Total"       → "$" .. fmt(d.money)
-- Qualquer label ausente é ignorado (não quebra).
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local StatusBar = {}

local player = Players.LocalPlayer

local function fmt(n: number): string
	if n >= 1e12 then return string.format("%.2fT", n / 1e12)
	elseif n >= 1e9 then return string.format("%.1fB", n / 1e9)
	elseif n >= 1e6 then return string.format("%.1fM", n / 1e6)
	elseif n >= 1e3 then return string.format("%.0fK", n / 1e3)
	else return tostring(math.floor(n)) end
end

local function setText(root: Instance, name: string, text: string)
	local lbl = root:FindFirstChild(name, true)
	if lbl and lbl:IsA("TextLabel") then
		lbl.Text = text
	end
end

function StatusBar.init()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("StatusBar", 10)
	if not gui or not gui:IsA("ScreenGui") then
		warn("[StatusBar] ScreenGui 'StatusBar' não encontrado em PlayerGui. Crie em StarterGui com os TextLabels 'Value_*'.")
		return
	end

	local R    = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		local brs: any = d.brainrots or {}
		local totalBR = 0
		for _, e in brs do totalBR += e.qty end

		local unlocked = d.unlockedJumps or {}
		local jumpsCount = 0
		for _ in unlocked do jumpsCount += 1 end

		local money = d.money or 0

		setText(gui, "Value_Brainrots", fmt(totalBR))
		setText(gui, "Value_Money",     fmt(money))
		setText(gui, "Value_Jumps",     tostring(jumpsCount) .. "/7")
		setText(gui, "Value_Tokens",    fmt(d.waveTokens or 0))
		setText(gui, "Value_Fused",     fmt(d.brainrotsFused or 0))
		setText(gui, "Value_Kills",     fmt(d.noobsKilled or 0))
		setText(gui, "Value_Total",     "$" .. fmt(money))
	end)
end

return StatusBar
