--!strict

local Controllers = script.Parent:WaitForChild("Controllers")

local CharacterController = require(Controllers:WaitForChild("CharacterController"))
local HUDController       = require(Controllers:WaitForChild("HUDController"))
local CombatController    = require(Controllers:WaitForChild("CombatController"))
local IntroController     = require(Controllers:WaitForChild("IntroController"))

CharacterController.init()
HUDController.init()
CombatController.init()
IntroController.init()

print("[Client] Pronto.")
