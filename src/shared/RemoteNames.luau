--!strict

local RemoteNames = {
	LEADERBOARD_UPDATE = "LeaderboardUpdate",  -- server → all  ({name, score}[])
	WHEEL_REWARD       = "WheelReward",        -- server → player (label: string)
}

return RemoteNames
