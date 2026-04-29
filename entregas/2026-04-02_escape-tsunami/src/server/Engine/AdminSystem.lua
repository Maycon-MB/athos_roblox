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
local brainrotSpawnEnabled: { [string]: boolean } = {}
local slowActive = false
local originalGravity = 196.2
local originalSpeeds: { [Player]: { walk: number, jump: number } } = {}

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
	elseif cmd == "give_brainrot" then
		local brainrotId = arg or ""
		local PD = require(script.Parent.PlayerData)
		PD.addBrainrot(pl, brainrotId, 1)
		adminResp:FireClient(pl, "ok", "Brainrot given: " .. brainrotId)
	elseif cmd == "reset_speed" then
		local char = pl.Character
		if char then
			local h = char:FindFirstChildOfClass("Humanoid")
			if h then
				h.WalkSpeed = 16
				h.JumpPower = 50
			end
		end
		adminResp:FireClient(pl, "ok", "Speed reset (WalkSpeed 16 / JumpPower 50)")
	elseif cmd == "toggle_brainrot" then
		local brainrotId = arg or ""
		-- nil ou true = habilitado; false = desabilitado
		local current = brainrotSpawnEnabled[brainrotId]
		local newState = if current == false then true else false
		brainrotSpawnEnabled[brainrotId] = newState
		local BS = require(script.Parent.BrainrotSystem)
		BS.setEnabled(brainrotId, newState)
		local stateText = if newState then "ON" else "OFF"
		adminResp:FireClient(pl, "ok", "Spawn " .. brainrotId .. ": " .. stateText)
	elseif cmd == "slow_motion" then
		slowActive = not slowActive
		local ws = game:GetService("Workspace")
		if slowActive then
			originalGravity = ws.Gravity
			ws.Gravity = originalGravity * 0.35
			for _, p in Players:GetPlayers() do
				local char = p.Character
				if char then
					local h = char:FindFirstChildOfClass("Humanoid")
					if h then
						originalSpeeds[p] = { walk = h.WalkSpeed, jump = h.JumpPower }
						h.WalkSpeed = math.max(h.WalkSpeed * 0.35, 4)
						h.JumpPower = math.max(h.JumpPower * 0.35, 20)
					end
				end
			end
		else
			ws.Gravity = originalGravity
			for _, p in Players:GetPlayers() do
				local char = p.Character
				if char then
					local h = char:FindFirstChildOfClass("Humanoid")
					if h and originalSpeeds[p] then
						h.WalkSpeed = originalSpeeds[p].walk
						h.JumpPower = originalSpeeds[p].jump
					end
				end
			end
			originalSpeeds = {}
		end
		local state = if slowActive then "ON" else "OFF"
		adminResp:FireClient(pl, "slow_state", state)
		adminResp:FireClient(pl, "ok", "Slow Motion: " .. state)
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
