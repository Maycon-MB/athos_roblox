--!strict

local GameConfig = {
	-- Spawn
	SPAWN_POSITION   = Vector3.new(0, 5, 0),
	SPAWN_SHIELD_SEC = 3,

	-- Mapa
	ARENA_HALF = 40,

	-- Dummies (grid 3x3 sem o centro)
	DUMMY_HEALTH      = 500,
	DUMMY_RESPAWN_SEC = 2.5,
	DUMMY_POSITIONS   = {
		Vector3.new(-18, 0, -18),
		Vector3.new(  0, 0, -18),
		Vector3.new( 18, 0, -18),
		Vector3.new(-18, 0,   0),
		Vector3.new( 18, 0,   0),
		Vector3.new(-18, 0,  18),
		Vector3.new(  0, 0,  18),
		Vector3.new( 18, 0,  18),
	},

	-- Treino / Combate
	PUNCH_COOLDOWN   = 0.32,
	PUNCH_RANGE      = 7,
	BASE_DAMAGE      = 10,
	STRENGTH_PER_HIT = 1,

	-- Upgrades (comprados em ordem com força acumulada)
	UPGRADES = {
		{ name = "Velocidade I",   cost = 50,   stat = "speed",  value = 3  },
		{ name = "Dano I",         cost = 100,  stat = "damage", value = 10 },
		{ name = "Velocidade II",  cost = 300,  stat = "speed",  value = 4  },
		{ name = "Dano II",        cost = 600,  stat = "damage", value = 15 },
		{ name = "Velocidade III", cost = 1200, stat = "speed",  value = 5  },
		{ name = "Dano III",       cost = 2500, stat = "damage", value = 25 },
		{ name = "Velocidade IV",  cost = 4000, stat = "speed",  value = 6  },
		{ name = "Dano IV",        cost = 7000, stat = "damage", value = 40 },
	},

	-- Níveis de força
	LEVELS = {
		{ name = "Iniciante",  min = 0     },
		{ name = "Aprendiz",   min = 100   },
		{ name = "Guerreiro",  min = 300   },
		{ name = "Elite",      min = 700   },
		{ name = "Mestre",     min = 1500  },
		{ name = "Lendário",   min = 3000  },
		{ name = "Divino",     min = 6000  },
		{ name = "Imortal",    min = 12000 },
	},
}

return GameConfig
