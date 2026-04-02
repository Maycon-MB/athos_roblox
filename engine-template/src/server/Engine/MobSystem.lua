--!strict
-- MobSystem — Spawna NPCs em posições aleatórias do mapa via Raycast.
-- Coloque os modelos dos personagens em ReplicatedStorage > Mobs.
-- Se a pasta não existir, o sistema é ignorado silenciosamente.
local CollectionService = game:GetService("CollectionService")
local RS                = game:GetService("ReplicatedStorage")
local MobSystem = {}

local MOB_COUNT  = 5     -- quantos NPCs spawnar por modelo
local SPREAD     = 80    -- raio de dispersão em studs ao redor do centro

local function raycastGround(x: number, z: number): Vector3?
	local ws     = game:GetService("Workspace")
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude

	-- Ignora água
	local exclude: { Instance } = {}
	for _, obj in CollectionService:GetTagged("TsunamiWater") do table.insert(exclude, obj) end
	for _, obj in CollectionService:GetTagged("Tsunami")      do table.insert(exclude, obj) end
	params.FilterDescendantsInstances = exclude

	local hit = ws:Raycast(Vector3.new(x, 1000, z), Vector3.new(0, -2000, 0), params)
	if hit then return hit.Position + Vector3.new(0, 3, 0) end
	return nil
end

local function spawnMob(template: Model, pos: Vector3)
	local ws    = game:GetService("Workspace")
	local clone = template:Clone()
	clone.Parent = ws

	-- Posiciona via PrimaryPart ou primeiro BasePart encontrado
	local root = clone.PrimaryPart
	if not root then
		for _, obj in clone:GetDescendants() do
			if obj:IsA("BasePart") then root = obj :: BasePart; break end
		end
	end
	if root then
		clone:PivotTo(CFrame.new(pos))
	end

	-- Ancora todos os parts (NPCs estáticos para gravação)
	for _, obj in clone:GetDescendants() do
		if obj:IsA("BasePart") then
			(obj :: BasePart).Anchored = true
		end
	end
end

function MobSystem.init(_cfg: any)
	local mobsFolder = RS:FindFirstChild("Mobs")
	if not mobsFolder then
		print("[MobSystem] ReplicatedStorage.Mobs não encontrado — NPCs desativados.")
		return
	end

	-- Aguarda mapa carregar e MapTagger terminar
	task.delay(4, function()
		local ws = game:GetService("Workspace")

		-- Centro do mapa
		local sumX, sumZ, count = 0, 0, 0
		for _, obj in ws:GetDescendants() do
			if obj:IsA("BasePart") and not CollectionService:HasTag(obj, "TsunamiWater") then
				local bp = obj :: BasePart
				sumX += bp.Position.X; sumZ += bp.Position.Z; count += 1
			end
		end
		local cx = if count > 0 then sumX / count else 0
		local cz = if count > 0 then sumZ / count else 0

		for _, template in mobsFolder:GetChildren() do
			if not template:IsA("Model") then continue end
			local spawned = 0
			local attempts = 0
			while spawned < MOB_COUNT and attempts < MOB_COUNT * 6 do
				attempts += 1
				local rx = cx + math.random(-SPREAD, SPREAD)
				local rz = cz + math.random(-SPREAD, SPREAD)
				local pos = raycastGround(rx, rz)
				if pos then
					spawnMob(template, pos)
					spawned += 1
				end
			end
			print(string.format("[MobSystem] '%s' → %d NPC(s) spawnados", template.Name, spawned))
		end
	end)
end

return MobSystem
