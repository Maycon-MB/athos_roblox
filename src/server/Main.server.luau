--!strict

local Services = script.Parent:WaitForChild("Services")

local SpawnService    = require(Services:WaitForChild("SpawnService"))
local MapService      = require(Services:WaitForChild("MapService"))
local TrainingService = require(Services:WaitForChild("TrainingService"))

MapService.init()
SpawnService.init()
TrainingService.init()

print("[Main] Servidor pronto.")
