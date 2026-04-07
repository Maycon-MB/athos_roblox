--!strict
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local PlayerData = {}

local _cfg: any
local _data: { [Player]: any } = {}
local _sync: RemoteEvent

local function newData(): any
	return {
		money = 0,
		brainrots = {}, -- { id: string, qty: number }[]
		currentJump = "none",
		waveTokens = 0,
		wavesSurvived = 0,
		noobsKilled = 0,
		brainrotsSold = 0,
		brainrotsFused = 0,
		unlockedJumps = {},
		baseSlots = _cfg.BASE and _cfg.BASE.SLOTS_DEFAULT or 4,
		hasShield = false,
	}
end

function PlayerData.get(p: Player): any
	return _data[p]
end

function PlayerData.sync(p: Player)
	if _data[p] then
		_sync:FireClient(p, _data[p])
	end
end

function PlayerData.addMoney(p: Player, n: number)
	local d = _data[p]
	if not d then
		return
	end
	d.money += n
	PlayerData.sync(p)
end

function PlayerData.addBrainrot(p: Player, id: string, qty: number?)
	local d = _data[p]
	if not d then
		return
	end
	local n = qty or 1
	for _, e in d.brainrots do
		if e.id == id then
			e.qty += n
			PlayerData.sync(p)
			return
		end
	end
	table.insert(d.brainrots, { id = id, qty = n })
	PlayerData.sync(p)
end

function PlayerData.removeBrainrot(p: Player, id: string): boolean
	local d = _data[p]
	if not d then
		return false
	end
	for i, e in d.brainrots do
		if e.id == id then
			e.qty -= 1
			if e.qty <= 0 then
				table.remove(d.brainrots, i)
			end
			PlayerData.sync(p)
			return true
		end
	end
	return false
end

function PlayerData.countBrainrots(p: Player): number
	local d = _data[p]
	if not d then
		return 0
	end
	local t = 0
	for _, e in d.brainrots do
		t += e.qty
	end
	return t
end

function PlayerData.unlockJump(p: Player, id: string)
	local d = _data[p]
	if not d then
		return
	end
	for _, j in d.unlockedJumps do
		if j == id then
			return
		end
	end
	table.insert(d.unlockedJumps, id)
	d.currentJump = id
	PlayerData.sync(p)
end

function PlayerData.hasJump(p: Player, id: string): boolean
	local d = _data[p]
	if not d then
		return false
	end
	for _, j in d.unlockedJumps do
		if j == id then
			return true
		end
	end
	return false
end

-- Remove N brainrots do inventário (qualquer tipo, FIFO).
-- Retorna true se havia saldo suficiente e o consumo foi feito.
-- Retorna false sem alterar o inventário caso contrário.
function PlayerData.consumeAnyBrainrots(p: Player, qty: number): boolean
	local d = _data[p]
	if not d then
		return false
	end
	local total = 0
	for _, e in d.brainrots do
		total += e.qty
	end
	if total < qty then
		return false
	end
	local remaining = qty
	local i = 1
	while i <= #d.brainrots and remaining > 0 do
		local e = d.brainrots[i]
		if e.qty <= remaining then
			remaining -= e.qty
			table.remove(d.brainrots, i)
		else
			e.qty -= remaining
			remaining = 0
			i += 1
		end
	end
	PlayerData.sync(p)
	return true
end

function PlayerData.init(cfg: any)
	_cfg = cfg
	local R = require(RS.Shared.Remotes)

	_sync = Instance.new("RemoteEvent")
	_sync.Name = R.SyncData
	_sync.Parent = RS

	Players.PlayerAdded:Connect(function(p)
		_data[p] = newData()
		task.wait(1) -- aguarda client carregar
		PlayerData.sync(p)
	end)

	Players.PlayerRemoving:Connect(function(p)
		_data[p] = nil :: any
	end)

	-- Income loop: +$income/s por brainrot
	task.spawn(function()
		while true do
			task.wait(1)
			for _, p in Players:GetPlayers() do
				local d = _data[p]
				if not d then
					continue
				end
				local income = 0
				for _, entry in d.brainrots do
					for _, br in cfg.BRAINROTS do
						if br.id == entry.id then
							income += br.income * entry.qty
							break
						end
					end
				end
				if income > 0 then
					d.money += income
					PlayerData.sync(p)
				end
			end
		end
	end)
end

return PlayerData
