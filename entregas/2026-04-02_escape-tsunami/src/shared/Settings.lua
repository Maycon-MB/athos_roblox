--!strict
------------------------------------------------------------------------
-- SETTINGS.LUA — ÚNICO ARQUIVO QUE VOCÊ EDITA POR ROTEIRO
-- Fonte de verdade para dados de gameplay. Engine lê via cfg.CHAVE.
-- Abordagem Cinematográfica: cenários fake isolados, sem injeção de mapa.
------------------------------------------------------------------------
local S = {}

-- ── ÁREAS DO MAPA (3 cenários no mesmo Place) ───────────────────────
-- Cada área é uma região física separada no Workspace.
-- spawn = CFrame onde o jogador aparece ao teleportar.
-- size = bounding box da área (para spawn de brainrots/waves/mobs).
S.MAP_AREAS = {
	main = {
		label = "TSUNAMI ESCAPE",
		spawn = CFrame.new(0, 10, 0),
		size = Vector3.new(200, 50, 200),
	},
	shop = {
		label = "LOJA SECRETA",
		spawn = CFrame.new(500, 10, 0),
		size = Vector3.new(60, 30, 60),
	},
	base = {
		label = "SUA BASE",
		spawn = CFrame.new(0, 10, 500),
		size = Vector3.new(80, 30, 80),
	},
}

-- ── TSUNAMI ───────────────────────────────────────────────────────────
S.WAVE = {
	INTERVAL = 30,
	SPEED = 18,
	SPEED_MAX = 60,
	HOLD_TIME = 2,
	AUTO_WAVES = false, -- false = admin trigger apenas (cinematográfico)
}

-- ── RARIDADES ─────────────────────────────────────────────────────────
S.RARITIES = {
	[1] = { name = "Common", color = Color3.fromRGB(180, 180, 180) },
	[2] = { name = "Uncommon", color = Color3.fromRGB(80, 200, 80) },
	[3] = { name = "Rare", color = Color3.fromRGB(60, 120, 220) },
	[4] = { name = "Epic", color = Color3.fromRGB(160, 60, 220) },
	[5] = { name = "Legendary", color = Color3.fromRGB(255, 200, 0) },
	[6] = { name = "Metata", color = Color3.fromRGB(255, 80, 0) },
	[7] = { name = "Infinity", color = Color3.fromRGB(255, 20, 147) },
}
S.SPAWN_WEIGHTS = { 60, 25, 10, 4, 1, 0.1, 0.02 }

-- ── BRAINROTS ─────────────────────────────────────────────────────────
S.BRAINROT_ZONE = { MAX = 12, RATE = 3 }
S.BRAINROTS = {
	{
		id = "jamezini_cakenini",
		name = "Jamezini Cakenini",
		rarity = 1,
		income = 2,
		color = Color3.fromRGB(200, 160, 120),
	},
	{ id = "mikey", name = "Mikey", rarity = 5, income = 7000, color = Color3.fromRGB(255, 180, 40) },
	{
		id = "glaciero_infernati",
		name = "Glaciero Infernati",
		rarity = 4,
		income = 50000,
		color = Color3.fromRGB(80, 180, 255),
	},
	{
		id = "athos_brainrot",
		name = "O Athos Brainrot",
		rarity = 7,
		income = 999000000,
		color = Color3.fromRGB(255, 20, 147),
	},
	{
		id = "athos_mutacao_fogo",
		name = "AthosBreinrot Mutacao Fogo",
		rarity = 7,
		income = 999000000,
		color = Color3.fromRGB(255, 80, 0),
	},
}

-- ── PULOS ────────────────────────────────────────────────────────────
-- cost_type: "free" | "money" | "survive_waves" | "kill_noobs" | "sell_brainrots" | "fuse_brainrots"
S.JUMPS = {
	{
		id = "james",
		label = "James",
		name = "James",
		color = Color3.fromRGB(80, 180, 80),
		jump = 10,
		speed = 67,
		cost_type = "free",
		cost_value = 0,
		brainrot = "jamezini_cakenini",
		brainrot_qty = 1,
	},
	{
		id = "jj",
		label = "JJ",
		name = "JJ",
		color = Color3.fromRGB(60, 120, 220),
		jump = 40,
		speed = 250,
		cost_type = "money",
		cost_value = 5000,
		brainrot = "mikey",
		brainrot_qty = 1,
		extra = "wave_shield",
	},
	{
		id = "mana",
		label = "Mana",
		name = "Mana",
		color = Color3.fromRGB(255, 100, 180),
		jump = 90,
		speed = 400,
		cost_type = "money",
		cost_value = 500000,
		particles = "hearts",
		base_upgrade = true,
	},
	{
		id = "pdoro",
		label = "Pdoro",
		name = "Pdoro",
		color = Color3.fromRGB(255, 200, 40),
		jump = 140,
		speed = 600,
		cost_type = "survive_waves",
		cost_value = 10,
		wave_tokens = 10000,
	},
	{
		id = "matheus",
		label = "Matheus",
		name = "Matheus",
		color = Color3.fromRGB(160, 60, 220),
		jump = 170,
		speed = 800,
		cost_type = "kill_noobs",
		cost_value = 5,
		brainrot = "glaciero_infernati",
		brainrot_qty = 3,
		extra = "galaxy_bat",
	},
	{
		id = "caylus",
		label = "Caylus",
		name = "Caylus",
		color = Color3.fromRGB(255, 80, 0),
		jump = 200,
		speed = 2000,
		cost_type = "sell_brainrots",
		cost_value = 10,
		brainrot = "infinity_lucky_box",
		brainrot_qty = 3,
	},
	{
		id = "athos",
		label = "Athos",
		name = "Athos",
		color = Color3.fromRGB(255, 20, 147),
		jump = 250,
		speed = 2500,
		cost_type = "fuse_brainrots",
		cost_value = 2,
		fill_base = true,
		particles = "fire",
	},
}

-- ── CHALLENGES (mapping cost_type → stat field em PlayerData) ────────
S.CHALLENGES = {
	survive_waves = { stat = "wavesSurvived" },
	kill_noobs = { stat = "noobsKilled" },
	sell_brainrots = { stat = "brainrotsSold" },
	fuse_brainrots = { stat = "brainrotsFused" },
}

-- ── BASE ──────────────────────────────────────────────────────────────
S.BASE = { SLOTS_DEFAULT = 4, SLOTS_MAX = 12 }

return S
