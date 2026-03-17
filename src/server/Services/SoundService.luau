--!strict

-- Módulo 6 — Áudio Espacial
-- Estratégia de sons:
--   1. rbxasset:// → embutidos no cliente Roblox (SEMPRE funcionam, sem HTTP)
--   2. rbxassetid:// → tenta múltiplos candidatos em ordem; usa o primeiro que carregar
--   Se nenhum carregar, loga aviso sem travar o servidor.

local workspace = game:GetService("Workspace")

-- ── Sons embutidos no cliente (rbxasset://) ─────────────────────────────────
-- Estes NUNCA dão HTTP 403 pois estão no pacote local do Roblox.
local BUILTIN = {
	swim          = "rbxasset://sounds/action_swim.mp3",       -- água / bolhas
	electronicPing = "rbxasset://sounds/electronicpingshort.wav", -- tom eletrônico
}

-- ── Candidatos de música (rbxassetid://) ────────────────────────────────────
-- Múltiplos IDs por categoria; o SoundService testa em ordem e usa o 1º que carregar.
-- Todos são de domínio público / pack gratuito do DevForum (Boa's Free Music Pack
-- devforum.roblox.com/t/free-professional-music-pack-6-tracks/1453204).
-- Se o seu estúdio mostrar erros mesmo assim, substitua pelo ID de qualquer
-- áudio encontrado em: Toolbox → Audio → filtrar criador "Roblox".
local MUSIC_CANDIDATES = {
	hubMusic = {
		"rbxassetid://7399811837",  -- Cloudy Space   (Boa — domínio público)
		"rbxassetid://7399815715",  -- Space Cruise   (Boa — domínio público)
		"rbxassetid://7399812832",  -- Frozen In Time (Boa — domínio público)
	},
	vipAmbient = {
		"rbxassetid://7399813440",  -- Ice Castle     (Boa — domínio público)
		"rbxassetid://7399814871",  -- No Light       (Boa — domínio público)
		"rbxassetid://7399816850",  -- Supernova      (Boa — domínio público)
	},
}

local GameConfig = require(
	game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig")
)

local SoundService = {}

-- ── Helpers ─────────────────────────────────────────────────────────────────

local function safePlay(sound: Sound): ()
	local ok, err = pcall(function() sound:Play() end)
	if not ok then
		warn("[SoundService] Falha ao reproduzir:", sound.Name, "—", err)
	end
end

local function makeAnchor(name: string, pos: Vector3): Part
	local p        = Instance.new("Part")
	p.Name         = "SoundAnchor_" .. name
	p.Size         = Vector3.new(1, 1, 1)
	p.CFrame       = CFrame.new(pos)
	p.Anchored     = true
	p.CanCollide   = false
	p.Transparency = 1
	p.Parent       = workspace
	return p
end

-- Coloca um som embutido (rbxasset://) — carrega instantaneamente.
local function placeBuiltinSound(
	name    : string,
	pos     : Vector3,
	assetPath : string,
	volume  : number,
	maxDist : number
): ()
	local anchor = makeAnchor(name, pos)
	local s      = Instance.new("Sound")
	s.Name       = name
	s.SoundId    = assetPath
	s.Volume     = volume
	s.RollOffMaxDistance = maxDist
	s.RollOffMinDistance = 4
	s.Looped     = true
	s.Parent     = anchor
	safePlay(s)
	print("[SoundService]", name, "ativo (rbxasset:// embutido)")
end

-- Coloca um som rbxassetid:// com tentativa assíncrona + timeout de 6s.
local function placeAssetSound(
	name    : string,
	pos     : Vector3,
	soundId : string,
	volume  : number,
	maxDist : number,
	onFail  : () -> ()
): ()
	local anchor = makeAnchor(name, pos)
	local s      = Instance.new("Sound")
	s.Name       = name
	s.SoundId    = soundId
	s.Volume     = volume
	s.RollOffMaxDistance = maxDist
	s.RollOffMinDistance = 4
	s.Looped     = true
	s.Parent     = anchor

	local loaded = false
	local conn: RBXScriptConnection
	conn = s.Loaded:Connect(function()
		loaded = true
		conn:Disconnect()
		safePlay(s)
	end)

	task.delay(6, function()
		if not loaded then
			conn:Disconnect()
			anchor:Destroy()  -- limpa o anchor antes de tentar próximo candidato
			onFail()
		end
	end)
end

-- Tenta candidatos em ordem; para no 1º que carregar.
local function placeMusicWithFallback(
	name       : string,
	pos        : Vector3,
	candidates : { string },
	volume     : number,
	maxDist    : number
): ()
	local index = 1
	local function tryNext(): ()
		if index > #candidates then
			warn("[SoundService]", name,
				"— nenhum candidato carregou. Abra o Toolbox → Audio → filtrar por",
				"criador 'Roblox' e cole o ID em MUSIC_CANDIDATES dentro do SoundService.luau")
			return
		end
		local id = candidates[index]
		index   += 1
		placeAssetSound(name, pos, id, volume, maxDist, tryNext)
	end
	tryNext()
end

-- ── Música 2D do hub (sem posição — ouvida em todo o mapa) ─────────────────
local function placeHubMusic(candidates: { string }): ()
	local index = 1
	local function tryNext(): ()
		if index > #candidates then
			warn("[SoundService] HubMusic — nenhum candidato carregou.",
				"Toolbox → Audio → criador 'Roblox' → copie o ID → cole em MUSIC_CANDIDATES.hubMusic")
			return
		end
		local id = candidates[index]
		index   += 1

		local s             = Instance.new("Sound")
		s.Name              = "HubMusic"
		s.SoundId           = id
		s.Volume            = 0.20
		s.Looped            = true
		s.RollOffMaxDistance = 600
		s.Parent            = workspace

		local loaded = false
		local conn: RBXScriptConnection
		conn = s.Loaded:Connect(function()
			loaded = true
			conn:Disconnect()
			safePlay(s)
			print("[SoundService] HubMusic ativo →", id)
		end)

		task.delay(6, function()
			if not loaded then
				conn:Disconnect()
				s:Destroy()
				tryNext()
			end
		end)
	end
	tryNext()
end

-- ── Init ─────────────────────────────────────────────────────────────────────

function SoundService.init(): ()
	-- Música 2D do hub (fallback automático entre candidatos)
	placeHubMusic(MUSIC_CANDIDATES.hubMusic)

	-- Fonte: rbxasset:// embutido — funciona sempre
	-- (action_swim.mp3 = som de água/bolhas, ideal para fonte)
	placeBuiltinSound(
		"Fountain",
		Vector3.new(0, 5, 0),
		BUILTIN.swim,
		0.38, 40
	)

	-- Hum dos portais: tom eletrônico embutido
	-- (electronicpingshort.wav em loop cria um zumbido digital suave)
	local PA = GameConfig.PORTAL_AREA_POS
	for _, offset in {-22, 0, 22} do
		placeBuiltinSound(
			"Portal" .. tostring(offset),
			Vector3.new(PA.X + offset, PA.Y + 14, PA.Z),
			BUILTIN.electronicPing,
			0.18, 28
		)
	end

	-- VIP portal: ambient música com fallback
	local VP = GameConfig.VIP_PORTAL_POS
	placeMusicWithFallback(
		"VIPPortal",
		Vector3.new(VP.X, VP.Y + 14, VP.Z),
		MUSIC_CANDIDATES.vipAmbient,
		0.28, 32
	)

	print("[SoundService] Áudio espacial inicializado.")
	print("[SoundService] Fonte e portais: rbxasset:// (garantido).")
	print("[SoundService] HubMusic e VIP: tentando candidatos de domínio público...")
end

return SoundService
