--!strict
------------------------------------------------------------------------
-- COREENGINE.SERVER.LUA — Motor Universal. NÃO EDITE ESTE ARQUIVO.
-- Toda configuração fica em src/shared/Settings.lua.
-- Abordagem Cinematográfica: cenários fake, sem injeção de mapa.
------------------------------------------------------------------------
local RS = game:GetService("ReplicatedStorage")
local SSS = game:GetService("ServerScriptService")

local S = require(RS.Shared.Settings)

-- ── Diagnóstico: mostra o que veio do Settings.lua ───────────────────
do
	local keys = {}
	for k in S do
		table.insert(keys, k)
	end
	if #keys == 0 then
		warn("[CoreEngine] Settings.lua retornou tabela VAZIA — verifique o arquivo.")
	else
		print("[CoreEngine] Settings carregado. Chaves: " .. table.concat(keys, ", "))
	end
end

local E = SSS:WaitForChild("Engine")

-- Protege o boot: falha num módulo não impede os demais de carregar.
local function safeInit(name: string, fn: () -> ())
	local ok, err = pcall(fn)
	if not ok then
		warn(string.format("[CoreEngine] %s.init() falhou: %s", name, tostring(err)))
	end
end

-- ── 1. MapSystem — cria as 3 áreas + spawn ───────────────────────────
safeInit("MapSystem", function()
	require(E.MapSystem).init(S)
end)

-- ── 2. Sistemas de jogo ───────────────────────────────────────────────
safeInit("PlayerData", function()
	require(E.PlayerData).init(S)
end)
safeInit("WaveSystem", function()
	require(E.WaveSystem).init(S)
end)
safeInit("BrainrotSystem", function()
	require(E.BrainrotSystem).init(S)
end)
safeInit("JumpSystem", function()
	require(E.JumpSystem).init(S)
end)
safeInit("AdminSystem", function()
	require(E.AdminSystem).init(S)
end)
safeInit("MobSystem", function()
	require(E.MobSystem).init(S)
end)
safeInit("BaseSystem", function()
	require(E.BaseSystem).init(S)
end)

print("[CoreEngine] Ativo — " .. game.Name)
