--!strict
-- AdminSystem — Painel de controle para gravação cinematográfica.
-- /admin no chat abre o painel. Todos os comandos passam pelo servidor.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local AdminSystem = {}

local _cfg: any
local adminCmd: RemoteEvent
local adminResp: RemoteEvent

local godModePlayers: { [Player]: boolean } = {}

local function handle(pl: Player, cmd: string, arg: string?)
	local WS = require(script.Parent.WaveSystem)
	local PD = require(script.Parent.PlayerData)
	local MS = require(script.Parent.MapSystem)

	if cmd == "wave" then
		WS.startWave(40)
		adminResp:FireClient(pl, "ok", "Wave started (speed 40)")
	elseif cmd == "fast_wave" then
		WS.startWave(80)
		adminResp:FireClient(pl, "ok", "Fast wave started (speed 80)")
	elseif cmd == "give_money" then
		PD.addMoney(pl, 999999999)
		adminResp:FireClient(pl, "ok", "$999M added")
	elseif cmd == "set_coins" then
		local amount = tonumber(arg) or 0
		local d = PD.get(pl)
		if d then
			d.money = amount
			PD.sync(pl)
			adminResp:FireClient(pl, "ok", "Coins set to " .. tostring(amount))
		end
	elseif cmd == "kill_all" then
		for _, p in Players:GetPlayers() do
			if p ~= pl and p.Character then
				local h = p.Character:FindFirstChildOfClass("Humanoid")
				if h then
					h.Health = 0
				end
			end
		end
		adminResp:FireClient(pl, "ok", "All players killed")
	elseif cmd == "list" then
		local names: { string } = {}
		for _, p in Players:GetPlayers() do
			table.insert(names, p.Name)
		end
		adminResp:FireClient(pl, "list", table.concat(names, ", "))
	elseif cmd == "teleport" then
		local area = arg or "main"
		MS.teleportTo(pl, area)
		adminResp:FireClient(pl, "ok", "Teleported to " .. area)
	elseif cmd == "give_jump" then
		local jumpId = arg or ""
		local JS = require(script.Parent.JumpSystem)
		PD.unlockJump(pl, jumpId)
		-- Aplica stats do jump
		for _, j in _cfg.JUMPS do
			if j.id == jumpId then
				local char = pl.Character
				if char then
					local h = char:FindFirstChildOfClass("Humanoid")
					if h then
						h.JumpPower = j.jump
						h.WalkSpeed = j.speed
					end
				end
				local d = PD.get(pl)
				if d then
					d.currentJump = jumpId
					PD.sync(pl)
				end
				break
			end
		end
		-- Notifica cliente
		local R = require(RS.Shared.Remotes)
		local purchased = RS:FindFirstChild(R.JumpPurchased) :: RemoteEvent?
		if purchased then
			purchased:FireClient(pl, jumpId)
		end
		adminResp:FireClient(pl, "ok", "Jump given: " .. jumpId)
	elseif cmd == "god_mode" then
		godModePlayers[pl] = not godModePlayers[pl]
		local char = pl.Character
		if char then
			local h = char:FindFirstChildOfClass("Humanoid")
			if h then
				if godModePlayers[pl] then
					h.MaxHealth = math.huge
					h.Health = math.huge
				else
					h.MaxHealth = 100
					h.Health = 100
				end
			end
		end
		local state = if godModePlayers[pl] then "ON" else "OFF"
		adminResp:FireClient(pl, "ok", "God Mode: " .. state)
	elseif cmd == "open_shop" then
		local R = require(RS.Shared.Remotes)
		local showShop = RS:FindFirstChild(R.ShowShop) :: RemoteEvent?
		if showShop then
			showShop:FireClient(pl)
		end
		adminResp:FireClient(pl, "ok", "Shop opened")
	elseif cmd == "reset" then
		local d = PD.get(pl)
		if d then
			d.money = 0
			d.currentJump = "none"
			d.unlockedJumps = {}
			d.brainrots = {}
			d.waveTokens = 0
			d.wavesSurvived = 0
			d.noobsKilled = 0
			d.brainrotsSold = 0
			d.brainrotsFused = 0
			d.hasShield = false
			d.baseSlots = _cfg.BASE.SLOTS_DEFAULT
			PD.sync(pl)
		end
		adminResp:FireClient(pl, "ok", "Progress reset")
	end
end

function AdminSystem.init(cfg: any)
	_cfg = cfg
	local R = require(RS.Shared.Remotes)

	adminCmd = Instance.new("RemoteEvent")
	adminCmd.Name = R.AdminCmd
	adminCmd.Parent = RS
	adminCmd.OnServerEvent:Connect(handle)

	adminResp = Instance.new("RemoteEvent")
	adminResp.Name = R.AdminResp
	adminResp.Parent = RS

	-- Reaplicar god mode no respawn
	Players.PlayerAdded:Connect(function(pl)
		pl.Chatted:Connect(function(msg)
			if msg:lower():match("^%s*/admin") then
				adminResp:FireClient(pl, "toggle", "")
			end
		end)
		pl.CharacterAdded:Connect(function(char)
			if godModePlayers[pl] then
				task.wait(0.2)
				local h = char:FindFirstChildOfClass("Humanoid")
				if h then
					h.MaxHealth = math.huge
					h.Health = math.huge
				end
			end
		end)
	end)

	Players.PlayerRemoving:Connect(function(pl)
		godModePlayers[pl] = nil
	end)
end

return AdminSystem
