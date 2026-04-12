--!strict
-- CoreClient — Boot do cliente. NÃO EDITE ESTE ARQUIVO.
local ui = script.Parent:WaitForChild("UI")

require(ui:WaitForChild("StatusBar")).init()
require(ui:WaitForChild("WaveAlert")).init()
require(ui:WaitForChild("JumpShop")).init()
require(ui:WaitForChild("WaveMachinePanel")).init()
require(ui:WaitForChild("ProgressPanel")).init()
require(ui:WaitForChild("AdminPanel")).init()
require(ui:WaitForChild("AreaLabel")).init()
