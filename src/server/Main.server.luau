--!strict

local Services = script.Parent:WaitForChild("Services")

local LightingService = require(Services:WaitForChild("LightingService"))
local FolderService   = require(Services:WaitForChild("FolderService"))
local MapService      = require(Services:WaitForChild("MapService"))
local SpawnService    = require(Services:WaitForChild("SpawnService"))
local SoundService    = require(Services:WaitForChild("SoundService"))
local WheelService    = require(Services:WaitForChild("WheelService"))

LightingService.init()  -- iluminação antes de tudo
FolderService.init()    -- cria pastas no workspace
MapService.init()       -- constrói o mapa (tags CollectionService incluídas)
SpawnService.init()     -- posicionamento e shield do jogador
SoundService.init()     -- áudio espacial por área (Módulo 6)
WheelService.init()     -- interatividade com magnitude check (Módulo 2+5)

print("[Main] Hub world pronto — v2 com áudio, cinemática e interatividade.")
