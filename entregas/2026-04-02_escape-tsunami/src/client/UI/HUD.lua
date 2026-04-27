--!strict
-- HUD — consome template editado no Studio (StarterGui.HUD).
-- NÃO cria UI. Só bind de números via SyncData.
--
-- Hierarquia esperada:
--   ScreenGui "HUD"
--     MainHUD
--       Row1.LabelTokens   (TextLabel)  → trade tokens (sem campo dedicado, usa wavesSurvived como proxy)
--       Row2.LabelCoins    (TextLabel)  → d.money formatado
--       Row3.LabelSpeed    (TextLabel)  → speed do tier atual
--       Row3.LabelJump     (TextLabel)  → jumps desbloqueados (count)
--       Row4.LabelMoney    (TextLabel)  → "$" + d.money formatado (destaque verde)
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local HUD = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

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

-- Calcula speed do tier atual lendo Settings.JUMPS pelo currentJump
local function speedForJump(jumpId: string?): number
	if not jumpId or jumpId == "" then return 16 end -- default Roblox
	for _, j in S.JUMPS do
		if j.id == jumpId then return (j.speed :: number) end
	end
	return 16
end

function HUD.init()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("HUD", 10)
	if not gui or not gui:IsA("ScreenGui") then
		warn("[HUD] ScreenGui 'HUD' não encontrado em PlayerGui")
		return
	end

	local R    = require(RS.Shared.Remotes)
	local sync = RS:WaitForChild(R.SyncData) :: RemoteEvent
	sync.OnClientEvent:Connect(function(d: any)
		local money = d.money or 0
		local unlocked = d.unlockedJumps or {}
		local jumpsCount = 0
		for _ in unlocked do jumpsCount += 1 end

		setText(gui, "LabelTokens", fmt(d.waveTokens or 0))
		setText(gui, "LabelCoins",  fmt(money))
		setText(gui, "LabelSpeed",  tostring(speedForJump(d.currentJump)))
		setText(gui, "LabelJump",   tostring(jumpsCount))
		setText(gui, "LabelMoney",  "$" .. fmt(money))
	end)
end

return HUD
