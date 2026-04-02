--!strict
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local AdminSystem = {}

local adminCmd:  RemoteEvent
local adminResp: RemoteEvent

local function handle(pl: Player, cmd: string, arg: string?)
	local WS = require(script.Parent.WaveSystem)
	local PD = require(script.Parent.PlayerData)

	if cmd == "wave" then
		WS.startWave(40)
		adminResp:FireClient(pl, "ok", "Wave started")
	elseif cmd == "fast_wave" then
		WS.startWave(80)
		adminResp:FireClient(pl, "ok", "Fast wave started")
	elseif cmd == "give_money" then
		PD.addMoney(pl, 999999999)
		adminResp:FireClient(pl, "ok", "$999M added")
	elseif cmd == "kill_all" then
		for _, p in Players:GetPlayers() do
			if p ~= pl and p.Character then
				local h = p.Character:FindFirstChildOfClass("Humanoid")
				if h then h.Health = 0 end
			end
		end
		adminResp:FireClient(pl, "ok", "All players killed")
	elseif cmd == "list" then
		local names: { string } = {}
		for _, p in Players:GetPlayers() do table.insert(names, p.Name) end
		adminResp:FireClient(pl, "list", table.concat(names, ", "))
	end
end

function AdminSystem.init(_cfg: any)
	local R = require(RS.Shared.Remotes)

	adminCmd        = Instance.new("RemoteEvent")
	adminCmd.Name   = R.AdminCmd; adminCmd.Parent = RS
	adminCmd.OnServerEvent:Connect(handle)

	adminResp        = Instance.new("RemoteEvent")
	adminResp.Name   = R.AdminResp; adminResp.Parent = RS

	Players.PlayerAdded:Connect(function(pl)
		pl.Chatted:Connect(function(msg)
			if msg:lower():match("^%s*/admin") then
				adminResp:FireClient(pl, "toggle", "")
			end
		end)
	end)
end

return AdminSystem
