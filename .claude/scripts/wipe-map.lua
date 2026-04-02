-- WIPE SCRIPT — Cole no Command Bar do Studio antes de usar um mapa novo
-- Remove scripts, sons e objetos de lógica do kit importado.
-- Mantém apenas geometria visual.

local targets = {
	"Script", "LocalScript", "ModuleScript",
	"SpawnLocation", "Sound", "RemoteEvent", "RemoteFunction"
}

local count = 0
for _, v in pairs(game.Workspace:GetDescendants()) do
	for _, className in pairs(targets) do
		if v:IsA(className) then
			v:Destroy()
			count = count + 1
			break
		end
	end
end

print("Faxina concluida! " .. count .. " objetos removidos.")
