--!strict
-- WipeEnvironment — Remove scripts do kit importado em Environment_Dirty.
-- Executa uma vez ao Play no Studio e se auto-destrói. NÃO EDITE.
local ws = game:GetService("Workspace")
local env = ws:FindFirstChild("Environment_Dirty")
if not env then script:Destroy(); return end

-- Remove APENAS scripts do kit importado.
-- BaseParts, Models, Folders, Sounds, Spawns e Remotes do mapa são preservados.
local removidos = 0
for _, obj in env:GetDescendants() do
	if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ModuleScript") then
		obj:Destroy()
		removidos += 1
	end
end
print(string.format("[WipeEnvironment] %d objeto(s) removidos de Environment_Dirty.", removidos))
script:Destroy()
