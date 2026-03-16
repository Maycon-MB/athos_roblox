--!strict

local RemoteNames = {
	PUNCH_DUMMY        = "PunchDummy",         -- client → server  (dummyName: string)
	STRENGTH_UPDATE    = "StrengthUpdate",     -- server → client  (strength: number, level: string, damage: number, speed: number)
	DUMMY_HIT          = "DummyHit",           -- server → all     (dummyName: string, hpPct: number)
	DUMMY_DIED         = "DummyDied",          -- server → all     (dummyName: string)
	DUMMY_RESPAWN      = "DummyRespawn",       -- server → all     (dummyName: string)
	BUY_UPGRADE        = "BuyUpgrade",         -- client → server  (index: number)
	UPGRADE_RESULT     = "UpgradeResult",      -- server → client  (success: boolean, message: string)
	LEADERBOARD_UPDATE = "LeaderboardUpdate",  -- server → all     ({name, strength, level}[])
}

return RemoteNames
