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
		spawn = CFrame.new(-246, -3, -575),      -- topo do chão inicial + 3 studs
		base_origin = CFrame.new(-246, -3, 406), -- onde os pedestais aparecem (fim do mapa)
		size = Vector3.new(250, 80, 1200),        -- cobre o mapa inteiro
		-- Centro real do mapa para spawn de brainrots (midpoint entre spawn e base_origin)
		-- spawn.Z=-575, base_origin.Z=406 → center=-85; halfZ=480 cobre toda a extensão jogável
		brainrot_center = CFrame.new(-246, -3, -85),
		brainrot_half   = Vector3.new(110, 0, 480),
	},
	shop = {
		label = "SECRET SHOP",
		spawn = CFrame.new(5000, 0, 0),  -- longe do mapa principal; nunca sobrepõe
		size = Vector3.new(60, 30, 60),
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
-- Pesos por raridade (índice = rarity). Legendary (5) elevado para Mikey aparecer no mapa.
S.SPAWN_WEIGHTS = { 60, 20, 8, 4, 6, 0.1, 0.02 }

-- ── ZONAS DE SPAWN DE BRAINROTS ──────────────────────────────────────
-- Define retângulos XZ onde brainrots podem nascer. Raycast desce para achar Y do chão.
-- cx/cz = centro do retângulo | halfX/halfZ = metade do tamanho em cada eixo
-- Ajuste os valores para cobrir o corredor jogável sem incluir paredes ou safe area.
S.SPAWN_ZONES = {
	{ cx = -246, halfX = 30, cz = 370, halfZ = 50 },
	-- cobre X: [-276, -216] | cobre Z: [320, 420]
	-- brainrots nascem junto à base (base_origin Z=406) para coleta imediata
}

-- ── BRAINROTS ─────────────────────────────────────────────────────────
S.BRAINROT_ZONE = { MAX = 12, RATE = 3 }
S.BRAINROTS = {
	{
		id = "jamezini_cakenini",
		name = "Jamezini Cakenini",
		rarity = 1,
		income = 2,
		color = Color3.fromRGB(200, 160, 120),
		model_name = "Noobini Cakenini",
	},
	{ id = "mikey", name = "Mikey", rarity = 5, income = 7000, color = Color3.fromRGB(255, 180, 40), model_name = "Mikey" },
	{ id = "athinhosyt", name = "AthinhosYT", rarity = 4, income = 500, color = Color3.fromRGB(160, 60, 220), model_name = "AthinhosYT" },
}

-- ── PULOS ────────────────────────────────────────────────────────────
-- cost_type: "free" | "money" | "survive_waves" | "kill_noobs" | "sell_brainrots" | "fuse_brainrots"
-- image: rbxassetid:// do tênis+cabeça do YouTuber (deixe "" para fallback emoji)
-- rewards: subtitle do card (mínimo palavras, máximo símbolos) — renderizado no banner
S.JUMPS = {
	{
		id = "james",
		label = "James",
		name = "James",
		color = Color3.fromRGB(80, 180, 80),
		image = "rbxassetid://92876302516404",
		user_id = 10630798575,
		jump = 10,
		speed = 67,
		rewards = {
		{i="134526838307331", v="10", s=40},
		{i="17368052918", v="67"},
		{i="91545674212636"},
	},
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
		image = "rbxassetid://104594177458534", -- zenichi
		user_id = 2837432041,
		jump = 40,
		speed = 250,
		rewards = {
		{i="134526838307331", v="40", s=40},
		{i="17368052918", v="250"},
		{i="120966795620680"},
		{i="111703189121563"},
	},
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
		image = "rbxassetid://99028854481677",
		user_id = 4477141353,
		jump = 90,
		speed = 400,
		rewards = {
		{i="134526838307331", v="90", s=40},
		{i="17368052918", v="400"},
		{i="78149540827603"},
	},
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
		image = "rbxassetid://80820275716340",
		user_id = 821426662,
		jump = 140,
		speed = 600,
		rewards = {
		{i="134526838307331", v="140", s=40},
		{i="17368052918", v="600"},
		{i="108225536815904", v="10K"},
	},
		cost_type = "survive_waves",
		cost_value = 10,
		wave_tokens = 10000,
		price_image = "rbxassetid://108225536815904",
		price_label = "x10",
	},
	{
		id = "matheus",
		label = "Matheus",
		name = "Matheus",
		color = Color3.fromRGB(160, 60, 220),
		image = "rbxassetid://117561125426551",
		user_id = 5055393579,
		jump = 170,
		speed = 800,
		rewards = {
		{i="134526838307331", v="170", s=40},
		{i="17368052918", v="800"},
		{i="126418573204977", v="3×"},
		{i="109982463208200"},
	},
		cost_type = "kill_noobs",
		cost_value = 5,
		price_image = "rbxassetid://140404369071027",
		price_label = "×5",
		price_img_x = 0.15,
		price_padding_right = 0.18,
		brainrot = "glaciero_infernati",
		brainrot_qty = 3,
		extra = "galaxy_bat",
	},
	{
		id = "caylus",
		label = "Caylus",
		name = "Caylus",
		color = Color3.fromRGB(255, 80, 0),
		image = "rbxassetid://137262830122100",
		user_id = 2657540898,
		jump = 200,
		speed = 2000,
		rewards = {
		{i="134526838307331", v="200", s=40},
		{i="17368052918", v="2K"},
		{i="87762066148941", v="3×"},
	},
		cost_type = "sell_brainrots",
		cost_value = 10,
		brainrot = "infinity_lucky_box",
		brainrot_qty = 3,
		price_image = "rbxassetid://137837626508439",
	},
	{
		id = "athos",
		label = "Athos",
		name = "Athos",
		color = Color3.fromRGB(255, 20, 147),
		image = "rbxassetid://104576040550373",
		user_id = 4083053143,
		jump = 250,
		speed = 2500,
		rewards = {
		{i="134526838307331", v="250", s=40},
		{i="17368052918", v="2.5K"},
		{i="121042659282481"},
	},
		cost_type = "fuse_brainrots",
		cost_value = 2,
		fill_base = true,
		particles = "fire",
		price_image = "rbxassetid://89343154348628",
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

-- ── MENU LATERAL (MainMenuOptions) ─────────────────────────────────────
-- Lista de botões clonados do ButtonTemplate em runtime. Adicione/remova à vontade.
-- novelty = true → mostra inner border amarelo + badge "NEW!"
S.MAIN_MENU = {
	-- Espaçamento entre botões (px). Ajuste sem abrir Studio.
	cell_padding = 20,
	admin = {
		enabled = true,
		icon = "rbxassetid://18209589139",
		label = "ADMIN PANEL",
	},
	buttons = {
		{ id = "store",   label = "Store",      icon = "rbxassetid://15985638648",    novelty = true },
		{ id = "trade",   label = "Trade",      icon = "rbxassetid://18367658811" },
		{ id = "index",   label = "Index",      icon = "rbxassetid://125938585603640" },
		{ id = "vip",     label = "V.I.P",      icon = "rbxassetid://103049239176781" },
		{ id = "rebirth", label = "Rebirth[0]", icon = "rbxassetid://18367579959" },
		{ id = "invite",  label = "Invite",     icon = "rbxassetid://83383867459336" },
	},
}

return S
