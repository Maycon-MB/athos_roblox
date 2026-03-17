--!strict

local GameConfig = {

	-- ── Mapa ─────────────────────────────────────────────────────────────────
	MAP_HALF      = 125,    -- metade do lado: mapa total 250×250 studs
	WALL_HEIGHT   = 30,

	-- ── Caminho circular ─────────────────────────────────────────────────────
	PATH_RADIUS   = 55,
	PATH_SEGMENTS = 48,
	PATH_WIDTH    = 14,

	-- ── Posições ─────────────────────────────────────────────────────────────
	SPAWN_POSITION    = Vector3.new(-70, 2, -70),   -- canto NW (beira do mapa)
	PORTAL_AREA_POS   = Vector3.new(70, 0, 70),     -- canto SE (portais)
	VIP_PORTAL_POS    = Vector3.new(108, 0, 50),    -- leste (exclusivo)

	-- ── Spawn ─────────────────────────────────────────────────────────────────
	SPAWN_SHIELD_SEC  = 3,

	-- ── Decoração de borda ────────────────────────────────────────────────────
	BORDER_SEED  = 42,
	TREE_COUNT   = 60,
	ROCK_COUNT   = 40,
}

return GameConfig
