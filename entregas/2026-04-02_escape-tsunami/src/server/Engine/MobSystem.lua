--!strict
-- MobSystem — Spawna NPCs Noob na area main com wandering AI e kill detection.
-- Usa MAP_AREAS.main para posicao. Sem auto-center via Workspace scan.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local MobSystem = {}

local MOB_COUNT = 5

local function raycastGround(x: number, z: number): Vector3?
	local ws = game:GetService("Workspace")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = {}
	for _, obj in CollectionService:GetTagged("Tsunami") do
		table.insert(exclude, obj)
	end
	params.FilterDescendantsInstances = exclude
	local hit = ws:Raycast(Vector3.new(x, 1000, z), Vector3.new(0, -2000, 0), params)
	if hit then
		return hit.Position + Vector3.new(0, 3, 0)
	end
	return nil
end

local function buildNoobRig(): Model
	local model = Instance.new("Model")
	model.Name = "Noob"

	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Anchored = false
	hrp.CanCollide = true
	hrp.Transparency = 1
	hrp.Parent = model

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(2, 2, 1)
	torso.BrickColor = BrickColor.new("Bright blue")
	torso.CanCollide = false
	torso.Parent = model

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 1, 1)
	head.BrickColor = BrickColor.new("Yellow")
	head.CanCollide = false
	head.Parent = model

	local weldTorso = Instance.new("WeldConstraint")
	weldTorso.Part0 = hrp
	weldTorso.Part1 = torso
	weldTorso.Parent = model

	local weldHead = Instance.new("WeldConstraint")
	weldHead.Part0 = torso
	weldHead.Part1 = head
	weldHead.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.WalkSpeed = 8
	humanoid.Parent = model

	model.PrimaryPart = hrp
	return model
end

local function nearestPlayer(pos: Vector3): Player?
	local best: Player? = nil
	local bestDist = 40
	for _, pl in Players:GetPlayers() do
		local char = pl.Character
		if not char then
			continue
		end
		local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not hrp then
			continue
		end
		local d = (hrp.Position - pos).Magnitude
		if d < bestDist then
			bestDist = d
			best = pl
		end
	end
	return best
end

local function spawnNoob(pos: Vector3, spawnCenter: Vector3)
	local ws = game:GetService("Workspace")
	local mob = buildNoobRig()
	mob.Parent = ws
	mob:PivotTo(CFrame.new(pos))

	local humanoid = mob:FindFirstChildOfClass("Humanoid") :: Humanoid
	local hrp = mob.PrimaryPart :: BasePart

	-- Wandering AI
	task.spawn(function()
		while humanoid.Health > 0 do
			local offset = Vector3.new(math.random(-30, 30), 0, math.random(-30, 30))
			humanoid:MoveTo(spawnCenter + offset)
			task.wait(math.random(3, 7))
		end
	end)

	-- Kill detection
	humanoid.Died:Connect(function()
		local killer = nearestPlayer(hrp.Position)
		if killer then
			local PD = require(script.Parent.PlayerData)
			local d = PD.get(killer)
			if d then
				d.noobsKilled += 1
				PD.sync(killer)
				print(string.format("[MobSystem] %s matou Noob (%d/5)", killer.Name, d.noobsKilled))
			end
		end
		task.delay(1, function()
			mob:Destroy()
		end)
	end)
end

function MobSystem.init(cfg: any)
	task.delay(4, function()
		-- Centro da area main via MAP_AREAS
		local area = cfg.MAP_AREAS and cfg.MAP_AREAS.main
		local cx = if area then area.spawn.Position.X else 0
		local cz = if area then area.spawn.Position.Z else 0
		local areaSize = if area then area.size else Vector3.new(200, 50, 200)
		local spread = math.floor(areaSize.X / 3)
		local center = Vector3.new(cx, 0, cz)

		local spawned = 0
		local attempts = 0
		while spawned < MOB_COUNT and attempts < MOB_COUNT * 6 do
			attempts += 1
			local rx = cx + math.random(-spread, spread)
			local rz = cz + math.random(-spread, spread)
			local pos = raycastGround(rx, rz)
			if pos then
				spawnNoob(pos, center)
				spawned += 1
			end
		end
		print(string.format("[MobSystem] %d Noob(s) spawnados", spawned))
	end)
end

return MobSystem
