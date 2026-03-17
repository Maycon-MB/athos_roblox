--!strict

local Controllers = script.Parent:WaitForChild("Controllers")

local CharacterController    = require(Controllers:WaitForChild("CharacterController"))
local CinematicController    = require(Controllers:WaitForChild("CinematicController"))
local NotificationController = require(Controllers:WaitForChild("NotificationController"))

CharacterController.init()
CinematicController.init()      -- Módulo 6: câmera cinematográfica ao nascer
NotificationController.init()   -- Módulo 6: popup de recompensa do Wheel Spin

print("[Client] Pronto.")
