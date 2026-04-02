--!strict
------------------------------------------------------------------------
-- SETTINGS.LUA — ÚNICO ARQUIVO QUE VOCÊ EDITA POR ROTEIRO
-- Leia o ROTEIRO.md e preencha via Claude Code no terminal.
-- Os valores abaixo são defaults seguros para o Engine não crashar.
-- Substitua tudo conforme o roteiro.
------------------------------------------------------------------------
local S = {}

-- ── TAGS ─────────────────────────────────────────────────────────────
S.TAG_MAP = {
	Tsunami     = { "Water", "Wave", "Tsunami", "Ocean" },
	SafeZone    = { "SafeZone", "Shelter" },
	WaveMachine = { "WaveMachine" },
	FuseMachine = { "FuseMachine" },
	CrackWall   = { "CrackWall", "SecretWall" },
}

-- ── TSUNAMI ───────────────────────────────────────────────────────────
S.WAVE = {
	INTERVAL    = 30,
	SPEED       = 18,
	SPEED_MAX   = 60,
	HOLD_TIME   = 2,
	RECEDE_MULT = 2,
	TAG_WATER   = "TsunamiWater",
	TAG_START   = "StartPoint",
	TAG_END     = "EndPoint",
	TAG_SAFEZONE= "SafeZone",
}

-- ── RARIDADES ─────────────────────────────────────────────────────────
S.RARITIES = {
	[1] = { name = "Common",    color = Color3.fromRGB(180,180,180) },
	[2] = { name = "Uncommon",  color = Color3.fromRGB( 80,200, 80) },
	[3] = { name = "Rare",      color = Color3.fromRGB( 60,120,220) },
	[4] = { name = "Epic",      color = Color3.fromRGB(160, 60,220) },
	[5] = { name = "Legendary", color = Color3.fromRGB(255,200,  0) },
	[6] = { name = "Metata",    color = Color3.fromRGB(255, 80,  0) },
	[7] = { name = "Infinity",  color = Color3.fromRGB(255, 20,147) },
}
S.SPAWN_WEIGHTS = { 60, 25, 10, 4, 1, 0.1, 0.02 }

-- ── BRAINROTS ─────────────────────────────────────────────────────────
S.BRAINROT_ZONE = { Z_MIN=-180, Z_MAX=180, X_RANGE=16, Y=1, MAX=12, RATE=3 }
S.BRAINROTS = {}  -- TODO: preencher com base no roteiro

-- ── PULOS ────────────────────────────────────────────────────────────
S.JUMPS = {}  -- TODO: preencher com base no roteiro

-- ── BASE ──────────────────────────────────────────────────────────────
S.BASE = { SLOTS_DEFAULT = 4, SLOTS_MAX = 12 }

-- ── SPAWN ─────────────────────────────────────────────────────────────
S.SPAWN = { POSITION = Vector3.new(0, 5, 0) }

return S
