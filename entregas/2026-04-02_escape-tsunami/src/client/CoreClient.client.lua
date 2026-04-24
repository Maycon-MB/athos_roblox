--!strict
-- CoreClient — Boot do cliente. NÃO EDITE ESTE ARQUIVO.
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ui = script.Parent:WaitForChild("UI")

require(ui:WaitForChild("StatusBar")).init()
require(ui:WaitForChild("CurrencyHud")).init()
require(ui:WaitForChild("HudController")).init()
require(ui:WaitForChild("FakeButtons")).init()
require(ui:WaitForChild("WaveAlert")).init()
require(ui:WaitForChild("JumpShop")).init()
require(ui:WaitForChild("WaveMachinePanel")).init()
require(ui:WaitForChild("AdminPanel")).init()
require(ui:WaitForChild("AreaLabel")).init()
require(ui:WaitForChild("MainMenu")).init()

-- GalaxyBat: detecta Activated no client e dispara knockback server-side
local player = Players.LocalPlayer
local function connectBat(tool: Instance)
	if not tool:IsA("Tool") or tool.Name ~= "GalaxyBat" then return end
	(tool :: Tool).Activated:Connect(function()
		local swing = RS:FindFirstChild("GalaxyBatSwing") :: RemoteEvent?
		if swing then swing:FireServer() end
	end)
end
local function watchBackpack(bp: Instance)
	bp.ChildAdded:Connect(connectBat)
	for _, item in bp:GetChildren() do connectBat(item) end
end
player.CharacterAdded:Connect(function(char)
	watchBackpack(player:WaitForChild("Backpack"))
	char.ChildAdded:Connect(connectBat) -- equipado
end)
if player.Character then
	watchBackpack(player:WaitForChild("Backpack"))
end
