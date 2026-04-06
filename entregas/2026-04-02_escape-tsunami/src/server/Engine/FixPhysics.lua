--!strict
-- FixPhysics — Script temporário de diagnóstico.
-- Ancora todas as BaseParts do mapa para impedir queda antes do spawn.
-- Desative quando o mapa original já tiver Anchored correto.
local FixPhysics = {}

function FixPhysics.init()
	local ws  = game:GetService("Workspace")
	local env = ws:FindFirstChild("Environment_Dirty")
	if not env then
		warn("[FixPhysics] Environment_Dirty NAO encontrado — Rojo provavelmente falhou no build.")
		return
	end

	local fixed = 0
	for _, obj in env:GetDescendants() do
		if obj:IsA("BasePart") then
			local bp      = obj :: BasePart
			bp.Anchored   = true
			bp.CanCollide = true
			-- Transparency = 0 apenas para teste visual: confirma que a geometria existe
			if bp.Transparency >= 0.95 then bp.Transparency = 0 end
			fixed += 1
		end
	end
	print(string.format("[FixPhysics] %d BaseParts ancoradas em Environment_Dirty.", fixed))
end

return FixPhysics
