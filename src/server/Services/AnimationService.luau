--!strict

local RunService = game:GetService("RunService")

type Entry = {
	part  : BasePart,
	kind  : string,
	speed : number,
	amp   : number,
	baseY : number,
}

local entries: { Entry } = {}
local elapsed = 0

RunService.Heartbeat:Connect(function(dt: number)
	elapsed += dt
	for _, e in entries do
		if not e.part:IsDescendantOf(game) then continue end
		if e.kind == "rotateY" then
			e.part.CFrame = e.part.CFrame * CFrame.Angles(0, e.speed * dt, 0)
		elseif e.kind == "rotateZ" then
			-- Gira no eixo Z: ideal para portais (efeito vórtice)
			e.part.CFrame = e.part.CFrame * CFrame.Angles(0, 0, e.speed * dt)
		elseif e.kind == "float" then
			local pos = e.part.Position
			local newY = e.baseY + math.sin(elapsed * e.speed) * e.amp
			e.part.CFrame = CFrame.new(pos.X, newY, pos.Z)
		end
	end
end)

local AnimationService = {}

-- Rotaciona em torno do eixo Y (halo horizontal, roda)
function AnimationService.rotate(part: BasePart, radiansPerSec: number): ()
	table.insert(entries, {
		part  = part,
		kind  = "rotateY",
		speed = radiansPerSec,
		amp   = 0,
		baseY = part.Position.Y,
	})
end

-- Rotaciona em torno do eixo Z (portais — efeito vórtice)
function AnimationService.rotateZ(part: BasePart, radiansPerSec: number): ()
	table.insert(entries, {
		part  = part,
		kind  = "rotateZ",
		speed = radiansPerSec,
		amp   = 0,
		baseY = part.Position.Y,
	})
end

-- Flutua com bobbing senoidal
function AnimationService.float(part: BasePart, amplitude: number, speed: number): ()
	table.insert(entries, {
		part  = part,
		kind  = "float",
		speed = speed,
		amp   = amplitude,
		baseY = part.Position.Y,
	})
end

print("[AnimationService] Loop ativo.")

return AnimationService
