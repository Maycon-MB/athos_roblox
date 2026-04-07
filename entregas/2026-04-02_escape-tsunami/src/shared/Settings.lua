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
	SafeZone    = { "SafeZone", "Shelter", "Cosmic", "Mythical", "Common", "Uncommon", "Rare", "Epic", "Legendary", "Secret" },
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
S.BRAINROTS = {
	{ id = "jamezini_cakenini", name = "Jamezini Cakenini", rarity = 1, income = 2,
	  color = Color3.fromRGB(200, 160, 120) },
	{ id = "mikey",             name = "Mikey",             rarity = 5, income = 7000,
	  color = Color3.fromRGB(255, 180,  40) },
	{ id = "athos_brainrot",    name = "Athos Brainrot",    rarity = 7, income = 999000000,
	  color = Color3.fromRGB(255,  20, 147) },
}

-- ── PULOS ────────────────────────────────────────────────────────────
-- cost_type: "free" | "money" | "survive_waves" | "kill_noobs" | "sell_brainrots" | "fuse_brainrots"
S.JUMPS = {
	{
		id         = "james",
		label      = "James",
		jump       = 70,
		speed      = 67,
		cost_type  = "free",
		cost_value = 0,
		brainrot   = "jamezini_cakenini",
		brainrot_qty = 1,
	},
	{
		id         = "jj",
		label      = "JJ",
		jump       = 100,
		speed      = 250,
		cost_type  = "money",
		cost_value = 5000,
		brainrot   = "mikey",
		brainrot_qty = 1,
		extra      = "wave_shield",
	},
	{
		id         = "mana",
		label      = "Mana",
		jump       = 150,
		speed      = 400,
		cost_type  = "money",
		cost_value = 500000,
		particles  = "hearts",
		base_upgrade = true,
	},
	{
		id         = "pdoro",
		label      = "Pdoro",
		jump       = 200,
		speed      = 600,
		cost_type  = "survive_waves",
		cost_value = 10,
		wave_tokens = 1000,
	},
	{
		id         = "matheus",
		label      = "Matheus",
		jump       = 250,
		speed      = 800,
		cost_type  = "kill_noobs",
		cost_value = 5,
		brainrot   = "glaciero_infernati",
		brainrot_qty = 3,
		extra      = "galaxy_bat",
	},
	{
		id         = "caylus",
		label      = "Caylus",
		jump       = 1000,
		speed      = 2000,
		cost_type  = "sell_brainrots",
		cost_value = 10,
		brainrot   = "infinity_lucky_box",
		brainrot_qty = 3,
	},
	{
		id         = "athos",
		label      = "Athos",
		jump       = 999999,
		speed      = 999999,
		cost_type  = "fuse_brainrots",
		cost_value = 2,
		fill_base  = true,
		particles  = "fire",
	},
}

-- ── BASE ──────────────────────────────────────────────────────────────
S.BASE = { SLOTS_DEFAULT = 4, SLOTS_MAX = 12 }

-- ── SPAWN ─────────────────────────────────────────────────────────────
-- XZ = coordenada na pista onde o raycast de spawn deve descer.
-- Y é ignorado no raycast (sempre parte de Y=1000 para baixo).
S.SPAWN = { POSITION = Vector3.new(-1083.8, -84.1, 153.5) }

return S
