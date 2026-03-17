--!strict

local workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local GameConfig       = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("GameConfig"))
local FolderService    = require(script.Parent:WaitForChild("FolderService"))
local AnimationService = require(script.Parent:WaitForChild("AnimationService"))

local MapService = {}

-- ── Paleta coesa (pedra quente + acentos dourados) ────────────────────────────
local C = {
	-- Natureza
	rock       = Color3.fromRGB(138, 128, 115),
	rockDark   = Color3.fromRGB( 90,  82,  72),
	trunkDark  = Color3.fromRGB( 82,  55,  28),
	trunkLight = Color3.fromRGB(118,  85,  48),
	leafGreen  = Color3.fromRGB( 50,  92,  32),
	leafMid    = Color3.fromRGB( 70, 115,  42),
	leafLight  = Color3.fromRGB( 92, 145,  58),
	-- Água
	water      = Color3.fromRGB( 38,  98, 198),
	waterLight = Color3.fromRGB(108, 178, 255),
	-- Hub — pedra quente e mármore
	marble     = Color3.fromRGB(242, 238, 228),
	marbleMid  = Color3.fromRGB(218, 212, 198),
	stone      = Color3.fromRGB(172, 165, 150),
	stoneMid   = Color3.fromRGB(145, 138, 124),
	stoneDark  = Color3.fromRGB(105,  98,  86),
	-- Loja
	shopWall   = Color3.fromRGB(238, 224, 200),
	shopWood   = Color3.fromRGB( 88,  60,  34),
	shopRoof   = Color3.fromRGB(162,  48,  40),
	shopRoofD  = Color3.fromRGB(120,  34,  28),
	-- Leaderboard
	lbBase     = Color3.fromRGB( 28,  24,  40),
	gold       = Color3.fromRGB(255, 215,  45),
	goldDark   = Color3.fromRGB(172, 140,  18),
	-- Wheel
	wheelPed   = Color3.fromRGB( 50,  36,  86),
	wheelTop   = Color3.fromRGB( 72,  56, 122),
	wheelDisk  = Color3.fromRGB(225, 165,  25),
	-- Portais
	portalPlat = Color3.fromRGB( 46,  44,  60),
	-- Decoração
	lampMetal  = Color3.fromRGB( 50,  50,  58),
	lampOrb    = Color3.fromRGB(255, 245, 200),
	signBg     = Color3.fromRGB( 12,  10,  18),
	wallColor  = Color3.fromRGB( 80,  76,  68),
	wallTop    = Color3.fromRGB( 55,  52,  46),
	-- VIP
	vipGold    = Color3.fromRGB(255, 205,  38),
	vipPlat    = Color3.fromRGB( 76,  60,   8),
	vipDark    = Color3.fromRGB( 46,  36,   4),
}

-- ── Utilitários ───────────────────────────────────────────────────────────────
local function mkpart(
	parent : Instance,
	name   : string,
	size   : Vector3,
	cf     : CFrame,
	color  : Color3,
	mat    : Enum.Material
): Part
	local p      = Instance.new("Part")
	p.Name       = name
	p.Size       = size
	p.CFrame     = cf
	p.Color      = color
	p.Material   = mat
	p.Anchored   = true
	p.CastShadow = true
	p.Parent     = parent
	return p
end

local function mkwedge(
	parent : Instance,
	name   : string,
	size   : Vector3,
	cf     : CFrame,
	color  : Color3,
	mat    : Enum.Material
): WedgePart
	local p      = Instance.new("WedgePart")
	p.Name       = name
	p.Size       = size
	p.CFrame     = cf
	p.Color      = color
	p.Material   = mat
	p.Anchored   = true
	p.CastShadow = true
	p.Parent     = parent
	return p
end

local function addLight(parent: Instance, brightness: number, color: Color3, range: number): ()
	local l = Instance.new("PointLight")
	l.Brightness = brightness
	l.Color      = color
	l.Range      = range
	l.Parent     = parent
end

local function addParticles(parent: Instance, c1: Color3, c2: Color3, rate: number): ()
	local pe = Instance.new("ParticleEmitter")
	pe.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, c1),
		ColorSequenceKeypoint.new(1, c2),
	})
	pe.LightEmission  = 0.18  -- calibrado: evita flood de luz
	pe.LightInfluence = 0.8
	pe.Rate           = rate
	pe.Speed          = NumberRange.new(1.5, 5)
	pe.Lifetime       = NumberRange.new(1.0, 1.8)
	pe.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0,   0.4),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1,   0),
	})
	pe.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})
	pe.SpreadAngle = Vector2.new(25, 25)
	pe.Parent      = parent
end

local function addLabel(sign: Part, text: string, textColor: Color3): ()
	local gui   = Instance.new("SurfaceGui")
	gui.Face    = Enum.NormalId.Front
	gui.Parent  = sign
	local lbl            = Instance.new("TextLabel")
	lbl.Size             = UDim2.fromScale(1, 1)
	lbl.BackgroundColor3 = C.signBg
	lbl.TextColor3       = textColor
	lbl.Text             = text
	lbl.Font             = Enum.Font.GothamBold
	lbl.TextScaled       = true
	lbl.Parent           = gui
end

-- ── Módulo 1 — Terrain 250×250 ────────────────────────────────────────────────
local function buildTerrain(): ()
	local terrain = workspace.Terrain
	terrain:Clear()
	local H = GameConfig.MAP_HALF  -- 125

	-- Base Ground (sem grama alta em nenhuma área jogável — Módulo 4)
	-- Ground não gera lâminas de grama visuais, apenas chão plano marrom
	terrain:FillBlock(
		CFrame.new(0, -10, 0),
		Vector3.new(H * 2 + 10, 20, H * 2 + 10),
		Enum.Material.Ground
	)

	-- Colinas decorativas nas bordas (Grass para aspecto natural distante)
	terrain:FillBall(Vector3.new(-95, 12, 18),  24, Enum.Material.Grass)
	terrain:FillBall(Vector3.new( 18, 10, -95), 20, Enum.Material.Grass)
	terrain:FillBall(Vector3.new(-85, 8,  74),  18, Enum.Material.Grass)
	terrain:FillBall(Vector3.new( 74, 7,  -82), 15, Enum.Material.Grass)

	-- Cliffs de rocha nas bordas do mapa
	terrain:FillBlock(CFrame.new( 0, 8, -H-5), Vector3.new(H*2+20, 36, 12), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new( 0, 8,  H+5), Vector3.new(H*2+20, 36, 12), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new(-H-5, 8, 0),  Vector3.new(12, 36, H*2+20), Enum.Material.Rock)
	terrain:FillBlock(CFrame.new( H+5, 8, 0),  Vector3.new(12, 36, H*2+20), Enum.Material.Rock)

	-- Flatten zonas de estrutura (nivel a altura sob cada POI)
	terrain:FillBlock(CFrame.new(  0,  -10,  0),   Vector3.new(92, 20, 92),  Enum.Material.Ground) -- hub centro
	terrain:FillBlock(CFrame.new( 70,  -10, 70),   Vector3.new(72, 20, 56),  Enum.Material.Ground) -- portais
	terrain:FillBlock(CFrame.new(108,  -10, 50),   Vector3.new(46, 20, 46),  Enum.Material.Ground) -- VIP
	terrain:FillBlock(CFrame.new(-70,  -10,-70),   Vector3.new(40, 20, 40),  Enum.Material.Ground) -- spawn corner
	terrain:FillCylinder(CFrame.new(0, -10, 0), 20, 74, Enum.Material.Ground)                      -- caminho circular

	-- Corredor diagonal: Spawn (-70,-70) → Hub (0,0) — evita grama alta no caminho de entrada
	local diagCF = CFrame.new(-35, -10, -35) * CFrame.Angles(0, math.rad(45), 0)
	terrain:FillBlock(diagCF, Vector3.new(36, 20, 108), Enum.Material.Ground)

	-- Corredor diagonal: Hub (0,0) → Portais (70,70) — Grand Pathway sem grama
	local grandCF = CFrame.new(35, -10, 35) * CFrame.Angles(0, math.rad(45), 0)
	terrain:FillBlock(grandCF, Vector3.new(36, 20, 108), Enum.Material.Ground)
end

-- ── Módulo 2 — Caminho circular + postes (Archimedes) ─────────────────────────
local function buildCircularPath(env: Folder): ()
	local R    = GameConfig.PATH_RADIUS   -- 55
	local N    = GameConfig.PATH_SEGMENTS -- 48
	local W    = GameConfig.PATH_WIDTH    -- 14
	local step = (2 * math.pi) / N

	for i = 0, N - 1 do
		local a0  = step * i
		local a1  = step * (i + 1)
		local mid = (a0 + a1) / 2
		local mx  = math.cos(mid) * R
		local mz  = math.sin(mid) * R
		local len = 2 * R * math.sin(step / 2) + 0.2

		local cf = CFrame.new(mx, 0.55, mz) * CFrame.Angles(0, -(mid + math.pi / 2), 0)
		mkpart(env, "PathSeg"..i, Vector3.new(W, 1.1, len), cf, C.stone, Enum.Material.Cobblestone)

		-- Guias laterais (bordas de pedra)
		for _, side in {-1, 1} do
			local ex  = math.cos(mid) * (R + side * (W / 2 + 0.8))
			local ez  = math.sin(mid) * (R + side * (W / 2 + 0.8))
			local ecf = CFrame.new(ex, 0.75, ez) * CFrame.Angles(0, -(mid + math.pi / 2), 0)
			mkpart(env, "PathEdge"..i.."s"..tostring(side),
				Vector3.new(1.6, 1.6, len), ecf, C.stoneDark, Enum.Material.SmoothPlastic)
		end

		-- Poste a cada 6 segmentos (Módulo 4 — iluminação do caminho)
		if i % 6 == 0 then
			local lx = math.cos(mid) * (R + W / 2 + 3)
			local lz = math.sin(mid) * (R + W / 2 + 3)
			mkpart(env, "LampBase"..i,
				Vector3.new(1.6, 1, 1.6), CFrame.new(lx, 0.5, lz), C.lampMetal, Enum.Material.SmoothPlastic)
			mkpart(env, "LampPole"..i,
				Vector3.new(0.5, 10, 0.5), CFrame.new(lx, 5.5, lz), C.lampMetal, Enum.Material.SmoothPlastic)
			mkpart(env, "LampArm"..i,
				Vector3.new(0.4, 0.4, 2.4), CFrame.new(lx, 11, lz - 0.9), C.lampMetal, Enum.Material.SmoothPlastic)
			local orb = mkpart(env, "LampOrb"..i,
				Vector3.new(1.4, 1.4, 1.4), CFrame.new(lx, 11, lz - 2.1), C.lampOrb, Enum.Material.Neon)
			addLight(orb, 3.5, Color3.fromRGB(255, 238, 188), 22)
		end
	end
end

-- ── Módulo 2 — Grand Pathway (hub → portais) ──────────────────────────────────
local function buildGrandPathway(env: Folder): ()
	for i = 0, 5 do
		local t = i / 5
		local x = 38 + (62 - 38) * t
		local z = 38 + (62 - 38) * t
		mkpart(env, "GrandPath"..i,
			Vector3.new(16, 1.2, 16), CFrame.new(x, 0.6, z), C.marble, Enum.Material.Marble)
		-- Bordas laterais
		for _, s in {-1, 1} do
			mkpart(env, "GrandEdge"..i..tostring(s),
				Vector3.new(1.3, 1.8, 16), CFrame.new(x + s * 8.65, 0.9, z),
				C.stoneDark, Enum.Material.SmoothPlastic)
		end
	end
end

-- ── Módulo 4 — Fonte central (3 camadas — ponto focal do hub) ─────────────────
local function buildFountain(structures: Folder): ()
	-- Camada 0: piscina base (grande e imponente)
	mkpart(structures, "FountainRim",
		Vector3.new(24, 3.5, 24), CFrame.new(0, 1.75, 0), C.stone, Enum.Material.SmoothPlastic)
	mkpart(structures, "FountainRimInner",
		Vector3.new(20, 0.5, 20), CFrame.new(0, 0.75, 0), C.stoneMid, Enum.Material.SmoothPlastic)
	local water1 = mkpart(structures, "FountainWater1",
		Vector3.new(19, 0.5, 19), CFrame.new(0, 1.75, 0), C.water, Enum.Material.Glass)
	water1.Transparency = 0.22
	addLight(water1, 1.2, C.waterLight, 16)

	-- Camada 1: plataforma intermediária
	mkpart(structures, "FountainTier1",
		Vector3.new(13, 3, 13), CFrame.new(0, 4.5, 0), C.marble, Enum.Material.SmoothPlastic)
	mkpart(structures, "FountainTier1Top",
		Vector3.new(14, 0.5, 14), CFrame.new(0, 6.25, 0), C.stoneMid, Enum.Material.SmoothPlastic)
	local water2 = mkpart(structures, "FountainWater2",
		Vector3.new(10, 0.4, 10), CFrame.new(0, 6.55, 0), C.water, Enum.Material.Glass)
	water2.Transparency = 0.28

	-- Pilar central alto
	mkpart(structures, "FountainPillarBase",
		Vector3.new(4, 2, 4), CFrame.new(0, 7.5, 0), C.stoneMid, Enum.Material.SmoothPlastic)
	mkpart(structures, "FountainPillar",
		Vector3.new(3, 10, 3), CFrame.new(0, 13.5, 0), C.marble, Enum.Material.SmoothPlastic)

	-- Camada 2: taça do topo
	mkpart(structures, "FountainCup",
		Vector3.new(8, 2.5, 8), CFrame.new(0, 19.75, 0), C.stone, Enum.Material.SmoothPlastic)
	mkpart(structures, "FountainCupTop",
		Vector3.new(9, 0.5, 9), CFrame.new(0, 21.25, 0), C.stoneMid, Enum.Material.SmoothPlastic)
	local water3 = mkpart(structures, "FountainWater3",
		Vector3.new(6.5, 0.4, 6.5), CFrame.new(0, 21.65, 0), C.waterLight, Enum.Material.Neon)
	water3.Transparency = 0.08
	addLight(water3, 1.8, C.waterLight, 14)

	-- Espeto final (chapéu)
	mkpart(structures, "FountainSpire",
		Vector3.new(1.8, 4, 1.8), CFrame.new(0, 24, 0), C.marble, Enum.Material.SmoothPlastic)
	local tip = mkpart(structures, "FountainTip",
		Vector3.new(2.5, 0.8, 2.5), CFrame.new(0, 26.5, 0), C.gold, Enum.Material.Neon)
	addLight(tip, 1, C.gold, 10)

	-- Canteiros de flores (4 direções cardeais, raio 15 da fonte)
	local flowerColors = {
		Color3.fromRGB(255, 85, 85),
		Color3.fromRGB(255, 210, 50),
		Color3.fromRGB(180, 85, 255),
		Color3.fromRGB(85, 228, 118),
	}
	local bedOffsets = { {15, 0}, {-15, 0}, {0, 15}, {0, -15} }
	for idx, bp in ipairs(bedOffsets) do
		mkpart(structures, "FlowerBed"..idx,
			Vector3.new(6.5, 0.7, 3), CFrame.new(bp[1], 4.35, bp[2]),
			Color3.fromRGB(58, 108, 36), Enum.Material.Grass)
		for fi = 0, 2 do
			mkpart(structures, "Flower"..idx.."_"..fi,
				Vector3.new(1.1, 1.1, 1.1),
				CFrame.new(bp[1] + (fi - 1) * 2, 5.1, bp[2]),
				flowerColors[idx], Enum.Material.SmoothPlastic)
		end
	end

	-- Spray invisível (partículas de água)
	local spray = mkpart(structures, "FountainSpray",
		Vector3.new(0.3, 0.3, 0.3), CFrame.new(0, 22, 0), C.waterLight, Enum.Material.SmoothPlastic)
	spray.Transparency = 1
	addParticles(spray, C.waterLight, Color3.fromRGB(210, 235, 255), 22)
	addLight(spray, 1.2, C.waterLight, 12)
end

-- ── Módulo 4 — Hub de Spawn (centrado em 0,0 — Módulo 1: 3 camadas) ───────────
local function buildHubArea(structures: Folder): ()
	-- Plataforma em 3 camadas concêntricas (filler do maior ao menor — Módulo 3)
	mkpart(structures, "HubRing1",
		Vector3.new(90, 1, 90), CFrame.new(0, 0.5, 0), C.stoneMid, Enum.Material.Cobblestone)
	mkpart(structures, "HubRing2",
		Vector3.new(80, 1.5, 80), CFrame.new(0, 1.75, 0), C.stone, Enum.Material.SmoothPlastic)
	mkpart(structures, "HubPlatform",
		Vector3.new(70, 2, 70), CFrame.new(0, 3, 0), C.marble, Enum.Material.Marble)

	-- Trim NEON dourado nas 4 bordas (define claramente o limite da plataforma)
	for _, ax in {-35, 35} do
		mkpart(structures, "HubTrimX"..tostring(ax),
			Vector3.new(72, 0.6, 2.2), CFrame.new(0, 4.3, ax), C.gold, Enum.Material.Neon)
		mkpart(structures, "HubTrimZ"..tostring(ax),
			Vector3.new(2.2, 0.6, 72), CFrame.new(ax, 4.3, 0), C.gold, Enum.Material.Neon)
	end

	-- Escadas NW (player entra por aqui vindo de -70,-70)
	for step = 0, 3 do
		local off = step * 3.5
		mkpart(structures, "HubStairNW"..step,
			Vector3.new(18, 1, 4),
			CFrame.new(-18, 3 - step * 0.75, -36 - off - 2) * CFrame.Angles(0, 0, 0),
			C.stone, Enum.Material.SmoothPlastic)
	end
	-- Escadas sul (saída para o caminho circular)
	for step = 0, 2 do
		mkpart(structures, "HubStairS"..step,
			Vector3.new(18, 1, 4),
			CFrame.new(12, 3 - step * 0.75, 36 + step * 3.5 + 2),
			C.stone, Enum.Material.SmoothPlastic)
	end

	-- Pilares decorativos nos 4 cantos da plataforma (Módulo 5: detalhe visual)
	local cornerCoords = { {-33, -33}, {33, -33}, {-33, 33}, {33, 33} }
	for idx, cp in ipairs(cornerCoords) do
		mkpart(structures, "CornerBase"..idx,
			Vector3.new(4.5, 3.5, 4.5), CFrame.new(cp[1], 2.25, cp[2]),
			C.stoneMid, Enum.Material.SmoothPlastic)
		mkpart(structures, "CornerPillar"..idx,
			Vector3.new(2.8, 13, 2.8), CFrame.new(cp[1], 10.5, cp[2]),
			C.stone, Enum.Material.SmoothPlastic)
		mkpart(structures, "CornerBand"..idx,
			Vector3.new(3.5, 1.2, 3.5), CFrame.new(cp[1], 8, cp[2]),
			C.stoneDark, Enum.Material.SmoothPlastic)
		local orb = mkpart(structures, "CornerOrb"..idx,
			Vector3.new(2.2, 2.2, 2.2), CFrame.new(cp[1], 18, cp[2]),
			C.lampOrb, Enum.Material.Neon)
		addLight(orb, 2.8, Color3.fromRGB(255, 242, 198), 22)
	end

	-- Bancos ao redor da fonte (voltados para o centro)
	local benchData = {
		{ x =  20, z =   0, ry = math.rad(-90) },
		{ x = -20, z =   0, ry = math.rad( 90) },
		{ x =   0, z = -20, ry = 0             },
	}
	for idx, bd in ipairs(benchData) do
		local bcf = CFrame.new(bd.x, 4.65, bd.z) * CFrame.Angles(0, bd.ry, 0)
		mkpart(structures, "BenchSeat"..idx,
			Vector3.new(5.5, 0.55, 2), bcf, C.marble, Enum.Material.SmoothPlastic)
		mkpart(structures, "BenchBack"..idx,
			Vector3.new(5.5, 1.8, 0.4),
			CFrame.new(bd.x, 5.4, bd.z) * CFrame.Angles(0, bd.ry, 0) * CFrame.new(0, 0, -0.8),
			C.stone, Enum.Material.SmoothPlastic)
		mkpart(structures, "BenchLegL"..idx,
			Vector3.new(0.5, 1.5, 2),
			CFrame.new(bd.x, 4.15, bd.z) * CFrame.Angles(0, bd.ry, 0) * CFrame.new(-2.2, 0, 0),
			C.stoneDark, Enum.Material.SmoothPlastic)
		mkpart(structures, "BenchLegR"..idx,
			Vector3.new(0.5, 1.5, 2),
			CFrame.new(bd.x, 4.15, bd.z) * CFrame.Angles(0, bd.ry, 0) * CFrame.new( 2.2, 0, 0),
			C.stoneDark, Enum.Material.SmoothPlastic)
	end

	-- ── Leaderboard (torre LESTE do hub — não bloqueia a vista da fonte) ───────
	local lbX, lbZ = 28, 5
	-- Base escalonada
	mkpart(structures, "LBBase1",
		Vector3.new(16, 4, 12), CFrame.new(lbX, 6, lbZ), C.lbBase, Enum.Material.SmoothPlastic)
	mkpart(structures, "LBBase2",
		Vector3.new(13, 2, 9), CFrame.new(lbX, 9, lbZ), C.stoneDark, Enum.Material.SmoothPlastic)
	-- Torre principal
	mkpart(structures, "LBTower",
		Vector3.new(11, 42, 7), CFrame.new(lbX, 32, lbZ), C.lbBase, Enum.Material.SmoothPlastic)
	-- Moldura da tela (frente)
	mkpart(structures, "LBFrame",
		Vector3.new(13, 15, 1.2), CFrame.new(lbX, 31, lbZ - 4), C.stoneDark, Enum.Material.SmoothPlastic)
	local lbScreen = mkpart(structures, "LBScreen",
		Vector3.new(11, 13, 0.4), CFrame.new(lbX, 31, lbZ - 4.4), C.signBg, Enum.Material.SmoothPlastic)
	addLabel(lbScreen, "TOP PLAYERS", C.gold)
	-- Coroa neon no topo
	mkpart(structures, "LBCrown",
		Vector3.new(13, 2.5, 9), CFrame.new(lbX, 54.5, lbZ), C.gold, Enum.Material.Neon)
	mkpart(structures, "LBSpire",
		Vector3.new(3.5, 5, 3.5), CFrame.new(lbX, 59, lbZ), C.gold, Enum.Material.Neon)
	-- Luzes laterais do topo
	for _, sx in {-6, 6} do
		local cap = mkpart(structures, "LBCapLight"..tostring(sx),
			Vector3.new(2, 2, 2), CFrame.new(lbX + sx, 55, lbZ), C.gold, Enum.Material.Neon)
		addLight(cap, 1.8, C.gold, 14)
	end
	addLight(
		mkpart(structures, "LBFrontLight", Vector3.new(0.1,0.1,0.1),
			CFrame.new(lbX, 31, lbZ - 6), C.signBg, Enum.Material.SmoothPlastic),
		3, C.gold, 20)

	-- ── Loja (NE do hub) ──────────────────────────────────────────────────────
	local shX, shZ = 22, -22
	-- Degrau da loja
	mkpart(structures, "ShopStep",
		Vector3.new(24, 1.5, 18), CFrame.new(shX, 4.75, shZ), C.stoneMid, Enum.Material.SmoothPlastic)
	-- Paredes
	mkpart(structures, "ShopWall",
		Vector3.new(20, 13, 14), CFrame.new(shX, 11.5, shZ), C.shopWall, Enum.Material.SmoothPlastic)
	-- Revestimento de madeira lateral (Bloxburg: detalhe nos cantos)
	mkpart(structures, "ShopWoodL",
		Vector3.new(1.6, 13.5, 14.8), CFrame.new(shX - 9.8, 11.5, shZ), C.shopWood, Enum.Material.WoodPlanks)
	mkpart(structures, "ShopWoodR",
		Vector3.new(1.6, 13.5, 14.8), CFrame.new(shX + 9.8, 11.5, shZ), C.shopWood, Enum.Material.WoodPlanks)
	-- Janelas com moldura
	for _, wx in {shX - 5.5, shX + 5.5} do
		mkpart(structures, "ShopWinFrame"..tostring(wx),
			Vector3.new(5, 6.2, 0.35), CFrame.new(wx, 11, shZ - 7.2), C.shopWood, Enum.Material.SmoothPlastic)
		mkpart(structures, "ShopWin"..tostring(wx),
			Vector3.new(4.2, 5.5, 0.38), CFrame.new(wx, 11, shZ - 7.1),
			Color3.fromRGB(148, 210, 232), Enum.Material.Glass)
	end
	-- Porta central com moldura
	mkpart(structures, "ShopDoorFrame",
		Vector3.new(4.2, 9.8, 0.45), CFrame.new(shX, 8, shZ - 7.2), C.shopWood, Enum.Material.WoodPlanks)
	local door = mkpart(structures, "ShopDoor",
		Vector3.new(3.5, 9, 0.38), CFrame.new(shX, 8, shZ - 7.05),
		Color3.fromRGB(148, 210, 232), Enum.Material.Glass)
	door.Transparency = 0.2
	-- Telhado A-frame (WedgePart — Módulo 1 DRY)
	mkwedge(structures, "ShopRoofF",
		Vector3.new(23, 7, 10), CFrame.new(shX, 21.5, shZ - 4), C.shopRoof, Enum.Material.SmoothPlastic)
	mkwedge(structures, "ShopRoofB",
		Vector3.new(23, 7, 10), CFrame.new(shX, 21.5, shZ + 4) * CFrame.Angles(0, math.pi, 0),
		C.shopRoof, Enum.Material.SmoothPlastic)
	mkpart(structures, "ShopRidge",
		Vector3.new(23.5, 0.7, 0.7), CFrame.new(shX, 25.5, shZ), C.shopRoofD, Enum.Material.SmoothPlastic)
	-- Toldo sobre a porta
	mkwedge(structures, "ShopAwning",
		Vector3.new(8, 1.5, 3.2), CFrame.new(shX, 13.5, shZ - 9.2) * CFrame.Angles(math.rad(-18), 0, 0),
		C.shopRoof, Enum.Material.SmoothPlastic)
	-- Placa com moldura
	mkpart(structures, "ShopSignFrame",
		Vector3.new(18, 5.8, 0.45), CFrame.new(shX, 17.5, shZ - 7.4), C.shopWood, Enum.Material.SmoothPlastic)
	local shSign = mkpart(structures, "ShopSign",
		Vector3.new(17, 5, 0.38), CFrame.new(shX, 17.5, shZ - 7.25), C.signBg, Enum.Material.SmoothPlastic)
	addLabel(shSign, "LOJA", Color3.fromRGB(255, 255, 185))
	addLight(
		mkpart(structures, "ShopLight", Vector3.new(0.1,0.1,0.1), CFrame.new(shX, 15, shZ-9), C.signBg, Enum.Material.SmoothPlastic),
		2.5, Color3.fromRGB(255, 242, 188), 18)

	-- ── Wheel Spin (SW do hub) ─────────────────────────────────────────────────
	local wX, wZ = -24, 20
	-- Pedestal em 3 camadas (Módulo 3: maior ao menor)
	mkpart(structures, "WheelPed1",
		Vector3.new(18, 2, 18), CFrame.new(wX, 5, wZ), C.stoneMid, Enum.Material.SmoothPlastic)
	mkpart(structures, "WheelPed2",
		Vector3.new(14, 3, 14), CFrame.new(wX, 7.5, wZ), C.wheelPed, Enum.Material.SmoothPlastic)
	mkpart(structures, "WheelPed3",
		Vector3.new(11, 2.5, 11), CFrame.new(wX, 10.25, wZ), C.wheelTop, Enum.Material.SmoothPlastic)
	mkpart(structures, "WheelPedTop",
		Vector3.new(12.5, 0.6, 12.5), CFrame.new(wX, 11.8, wZ), C.gold, Enum.Material.Neon)

	-- Disco da roda
	local wheelDisk = mkpart(structures, "WheelDisk",
		Vector3.new(0.65, 18, 18), CFrame.new(wX, 22, wZ), C.wheelDisk, Enum.Material.SmoothPlastic)
	-- Segmentos coloridos com raios neon
	local segColors = {
		Color3.fromRGB(255,  60,  60),
		Color3.fromRGB( 60, 200, 255),
		Color3.fromRGB( 75, 220,  80),
		Color3.fromRGB(255, 200,  20),
	}
	for r = 0, 3 do
		-- Raio neon
		mkpart(structures, "WheelSpoke"..r,
			Vector3.new(0.55, 17, 0.55),
			CFrame.new(wX, 22, wZ) * CFrame.Angles(0, 0, math.rad(r * 45)),
			segColors[r + 1], Enum.Material.Neon)
		-- Segmento de cor
		mkpart(structures, "WheelSeg"..r,
			Vector3.new(0.65, 8, 8),
			CFrame.new(wX, 22, wZ) * CFrame.Angles(0, 0, math.rad(r * 45 + 22.5)),
			segColors[r + 1], Enum.Material.SmoothPlastic)
	end
	-- Centro da roda
	mkpart(structures, "WheelHub",
		Vector3.new(1.5, 3.5, 3.5), CFrame.new(wX, 22, wZ), C.gold, Enum.Material.Neon)
	AnimationService.rotate(wheelDisk, 0.6)
	-- Ponteiro
	mkpart(structures, "WheelPointer",
		Vector3.new(1.8, 4.5, 1.8), CFrame.new(wX + 10, 31, wZ), Color3.fromRGB(235, 50, 50), Enum.Material.Neon)

	-- ProximityPrompt + CollectionService tag (Módulo 5 — interatividade)
	local wheelPromptHost = mkpart(structures, "WheelPromptHost",
		Vector3.new(11, 0.2, 11), CFrame.new(wX, 12, wZ), C.gold, Enum.Material.Neon)
	wheelPromptHost.Transparency = 0.85
	local prompt               = Instance.new("ProximityPrompt")
	prompt.ActionText          = "Girar"
	prompt.ObjectText          = "Wheel Spin"
	prompt.MaxActivationDistance = 14
	prompt.HoldDuration         = 0
	prompt.Parent               = wheelPromptHost
	CollectionService:AddTag(wheelPromptHost, "WheelSpin")  -- WheelService escuta esta tag

	-- Placa
	local wSign = mkpart(structures, "WheelSign",
		Vector3.new(15, 5, 0.6), CFrame.new(wX, 9, wZ - 7.5), C.signBg, Enum.Material.SmoothPlastic)
	addLabel(wSign, "GIRO GRATIS", Color3.fromRGB(255, 230, 80))

	-- ── Starter Eggs (SE do hub) ───────────────────────────────────────────────
	local eX, eZ = 24, 20
	-- Bancada de exibição em mármore
	mkpart(structures, "EggBench",
		Vector3.new(30, 2.5, 13), CFrame.new(eX, 5.25, eZ), C.marble, Enum.Material.Marble)
	mkpart(structures, "EggBenchTop",
		Vector3.new(31, 0.6, 14), CFrame.new(eX, 6.8, eZ), C.stoneMid, Enum.Material.SmoothPlastic)
	local eggColors = {
		{ body = Color3.fromRGB(255, 82, 82),  glow = Color3.fromRGB(255, 145, 145) },
		{ body = Color3.fromRGB(75, 182, 255),  glow = Color3.fromRGB(148, 222, 255) },
		{ body = Color3.fromRGB(78, 228, 118),  glow = Color3.fromRGB(148, 255, 185) },
	}
	for j = 0, 2 do
		local eggPart = mkpart(structures, "Egg"..j,
			Vector3.new(4.8, 7.5, 4.8),
			CFrame.new(eX - 10 + j * 10, 11.25, eZ) * CFrame.Angles(0, math.rad(j * 30), 0.09),
			eggColors[j + 1].body, Enum.Material.SmoothPlastic)
		AnimationService.float(eggPart, 0.55, 0.9 + j * 0.15)
		addLight(eggPart, 1.2, eggColors[j + 1].glow, 10)
	end
	local eSign = mkpart(structures, "EggSign",
		Vector3.new(17, 5, 0.6), CFrame.new(eX, 10, eZ - 7.5), C.signBg, Enum.Material.SmoothPlastic)
	addLabel(eSign, "STARTER EGGS", Color3.fromRGB(185, 255, 185))

	-- ── Item Premium (centro-sul) — Módulo 4: visível desde o spawn ────────────
	local pmX, pmZ = 0, 28
	mkpart(structures, "PremiumPed1",
		Vector3.new(16, 2, 16), CFrame.new(pmX, 5, pmZ), C.stoneMid, Enum.Material.SmoothPlastic)
	mkpart(structures, "PremiumPed2",
		Vector3.new(12, 2.5, 12), CFrame.new(pmX, 7.25, pmZ), C.wheelPed, Enum.Material.SmoothPlastic)
	mkpart(structures, "PremiumPedTop",
		Vector3.new(13, 0.6, 13), CFrame.new(pmX, 8.8, pmZ), C.gold, Enum.Material.Neon)
	-- 3 halos concêntricos girando em velocidades diferentes
	for k, ringSize in ipairs({10, 13, 16}) do
		local halo = mkpart(structures, "PremiumHalo"..k,
			Vector3.new(0.5, ringSize, ringSize),
			CFrame.new(pmX, 15, pmZ) * CFrame.Angles(0, math.rad(k * 60), 0),
			C.gold, Enum.Material.Neon)
		AnimationService.rotate(halo, 0.8 + k * 0.25)
	end
	-- Pet flutuante (Titanic)
	local petPart = mkpart(structures, "PremiumPet",
		Vector3.new(6.5, 9.5, 6.5), CFrame.new(pmX, 15, pmZ), Color3.fromRGB(0, 165, 255), Enum.Material.Neon)
	AnimationService.float(petPart, 1.8, 1.0)
	addParticles(petPart, Color3.fromRGB(0, 200, 255), Color3.fromRGB(180, 240, 255), 6)
	addLight(petPart, 2.2, Color3.fromRGB(0, 180, 255), 16)
	local pmSign = mkpart(structures, "PremiumSign",
		Vector3.new(18, 5, 0.6), CFrame.new(pmX, 18, pmZ - 9.5), C.signBg, Enum.Material.SmoothPlastic)
	addLabel(pmSign, "TITANIC PET", Color3.fromRGB(0, 210, 255))
end

-- ── Módulo 4 — Área de Portais (SE do mapa) ───────────────────────────────────
local function buildPortalArea(structures: Folder): ()
	local PA = GameConfig.PORTAL_AREA_POS  -- (70, 0, 70)

	-- Plataforma em 2 camadas
	mkpart(structures, "PortalBase1",
		Vector3.new(74, 2.5, 34), CFrame.new(PA + Vector3.new(0, 1.25, 0)),
		C.stoneMid, Enum.Material.SmoothPlastic)
	mkpart(structures, "PortalBase2",
		Vector3.new(70, 4, 30), CFrame.new(PA + Vector3.new(0, 3, 0)),
		C.portalPlat, Enum.Material.SmoothPlastic)
	-- Trim na borda superior
	mkpart(structures, "PortalTrim",
		Vector3.new(72, 0.6, 32), CFrame.new(PA + Vector3.new(0, 5.3, 0)),
		C.stoneDark, Enum.Material.SmoothPlastic)

	-- Colunas decorativas nas pontas (Módulo 5: detalhe arquitetônico)
	for _, ox in {-33, 33} do
		mkpart(structures, "PortalCol"..tostring(ox),
			Vector3.new(4, 28, 4), CFrame.new(PA.X + ox, PA.Y + 14, PA.Z),
			C.stone, Enum.Material.SmoothPlastic)
		mkpart(structures, "PortalColMid"..tostring(ox),
			Vector3.new(5, 2.5, 5), CFrame.new(PA.X + ox, PA.Y + 12, PA.Z),
			C.stoneDark, Enum.Material.SmoothPlastic)
		local cap = mkpart(structures, "PortalColCap"..tostring(ox),
			Vector3.new(6, 2.5, 6), CFrame.new(PA.X + ox, PA.Y + 29, PA.Z),
			C.stoneDark, Enum.Material.SmoothPlastic)
		local capLight = mkpart(structures, "PortalColLight"..tostring(ox),
			Vector3.new(2.5, 2.5, 2.5), CFrame.new(PA.X + ox, PA.Y + 32, PA.Z),
			C.gold, Enum.Material.Neon)
		addLight(capLight, 1.5, C.gold, 14)
		_ = cap
	end

	local portals = {
		{ name = "Floresta", ring = Color3.fromRGB(35, 212, 82),  fill = Color3.fromRGB(12, 78, 28),  light = Color3.fromRGB(60, 255, 100), offset = -22 },
		{ name = "Oceano",   ring = Color3.fromRGB(28, 162, 255), fill = Color3.fromRGB(10, 65, 128),  light = Color3.fromRGB(80, 180, 255), offset =   0 },
		{ name = "Deserto",  ring = Color3.fromRGB(255, 152, 28), fill = Color3.fromRGB(138, 62, 10),  light = Color3.fromRGB(255, 175, 60), offset =  22 },
	}

	for _, portal in portals do
		local px = PA.X + portal.offset
		local py = PA.Y + 18
		local pz = PA.Z

		-- Frame externo espesso (rotateZ = efeito vórtice — Módulo 4)
		local ring = mkpart(structures, "PortalRing_"..portal.name,
			Vector3.new(16, 24, 2.5), CFrame.new(px, py, pz), portal.ring, Enum.Material.Neon)
		AnimationService.rotateZ(ring, 0.38)
		addLight(ring, 2.2, portal.light, 16)

		-- Anel intermediário (decorativo, estático)
		mkpart(structures, "PortalMid_"..portal.name,
			Vector3.new(14, 22, 1.4), CFrame.new(px, py, pz - 1.6),
			Color3.fromRGB(
				math.round(portal.ring.R * 255 * 0.42),
				math.round(portal.ring.G * 255 * 0.42),
				math.round(portal.ring.B * 255 * 0.42)
			), Enum.Material.SmoothPlastic)

		-- Preenchimento com vidro colorido
		local fill = mkpart(structures, "PortalFill_"..portal.name,
			Vector3.new(12, 20, 0.7), CFrame.new(px, py, pz - 2.3), portal.fill, Enum.Material.Glass)
		fill.Transparency = 0.32
		addParticles(fill, portal.ring, Color3.new(1, 1, 1), 6)

		-- Nome do portal acima com moldura
		mkpart(structures, "PortalNameFrame_"..portal.name,
			Vector3.new(16, 5.2, 0.5), CFrame.new(px, py + 15, pz), C.stoneDark, Enum.Material.SmoothPlastic)
		local sig = mkpart(structures, "PortalSign_"..portal.name,
			Vector3.new(15, 4.5, 0.6), CFrame.new(px, py + 15, pz + 0.4), C.signBg, Enum.Material.SmoothPlastic)
		addLabel(sig, portal.name, portal.ring)
	end
end

-- ── Módulo 4 — Portal VIP (exclusivo, afastado — Módulo 4: exclusividade) ─────
local function buildVIPPortal(structures: Folder): ()
	local VP = GameConfig.VIP_PORTAL_POS  -- (108, 0, 50)

	-- Plataforma em 3 camadas (mais elaborada que os demais)
	mkpart(structures, "VIPBase1",
		Vector3.new(32, 2.5, 32), CFrame.new(VP + Vector3.new(0, 1.25, 0)),
		C.stoneMid, Enum.Material.SmoothPlastic)
	mkpart(structures, "VIPBase2",
		Vector3.new(28, 4, 28), CFrame.new(VP + Vector3.new(0, 4, 0)),
		C.vipPlat, Enum.Material.Marble)
	mkpart(structures, "VIPPlatform",
		Vector3.new(24, 2.5, 24), CFrame.new(VP + Vector3.new(0, 7.25, 0)),
		C.vipDark, Enum.Material.SmoothPlastic)
	-- Borda neon dourada
	mkpart(structures, "VIPEdge",
		Vector3.new(26, 0.8, 26), CFrame.new(VP + Vector3.new(0, 8.9, 0)),
		C.vipGold, Enum.Material.Neon)
	addLight(
		mkpart(structures, "VIPEdgeLight", Vector3.new(0.1,0.1,0.1), CFrame.new(VP.X, VP.Y + 8, VP.Z), C.signBg, Enum.Material.SmoothPlastic),
		1.5, C.vipGold, 20)

	-- Escadas de acesso (4 degraus — Módulo 2: hierarquia)
	for step = 0, 3 do
		mkpart(structures, "VIPStair"..step,
			Vector3.new(16, 2, 4.5),
			CFrame.new(VP.X, 2.5 + step * 1.6, VP.Z - 14 + step * 4.5),
			Color3.fromRGB(145, 125, 42), Enum.Material.SmoothPlastic)
	end

	-- Portal dourado com frame espessa (rotateZ)
	local ring = mkpart(structures, "VIPPortalRing",
		Vector3.new(14, 22, 2.8), CFrame.new(VP.X, VP.Y + 21, VP.Z),
		C.vipGold, Enum.Material.Neon)
	AnimationService.rotateZ(ring, 0.22)
	addLight(ring, 2.8, C.vipGold, 18)
	-- Anel interno
	mkpart(structures, "VIPPortalMid",
		Vector3.new(12, 20, 1.4), CFrame.new(VP.X, VP.Y + 21, VP.Z - 2),
		Color3.fromRGB(160, 130, 14), Enum.Material.SmoothPlastic)
	-- Preenchimento
	local fill = mkpart(structures, "VIPPortalFill",
		Vector3.new(10, 18, 0.7), CFrame.new(VP.X, VP.Y + 21, VP.Z - 2.8),
		Color3.fromRGB(178, 140, 6), Enum.Material.Glass)
	fill.Transparency = 0.28
	addParticles(fill, C.vipGold, Color3.new(1, 1, 0.6), 8)

	-- Colunas laterais com capitel elaborado
	for _, side in {-9, 9} do
		mkpart(structures, "VIPCol"..tostring(side),
			Vector3.new(3.5, 34, 3.5), CFrame.new(VP.X + side, VP.Y + 17, VP.Z),
			C.stone, Enum.Material.SmoothPlastic)
		mkpart(structures, "VIPColMid"..tostring(side),
			Vector3.new(4.5, 2.5, 4.5), CFrame.new(VP.X + side, VP.Y + 10, VP.Z),
			C.stoneDark, Enum.Material.SmoothPlastic)
		local cap = mkpart(structures, "VIPColCap"..tostring(side),
			Vector3.new(5.5, 2.5, 5.5), CFrame.new(VP.X + side, VP.Y + 35, VP.Z),
			C.vipGold, Enum.Material.Neon)
		addLight(cap, 2, C.vipGold, 14)
	end
	-- Arco conectando as colunas
	mkpart(structures, "VIPArch",
		Vector3.new(22, 3.5, 4.5), CFrame.new(VP.X, VP.Y + 37.5, VP.Z), C.vipGold, Enum.Material.Neon)

	-- Placa VIP
	local vipSig = mkpart(structures, "VIPSign",
		Vector3.new(20, 5.5, 0.6), CFrame.new(VP.X, VP.Y + 43, VP.Z), C.signBg, Enum.Material.SmoothPlastic)
	addLabel(vipSig, "VIP PORTAL", C.vipGold)
end

-- ── Módulo 1 — Muros de borda com topo duplicado ──────────────────────────────
local function buildWalls(borders: Folder): ()
	local H  = GameConfig.MAP_HALF
	local WH = GameConfig.WALL_HEIGHT
	local WT = 4
	local S  = H * 2
	local defs = {
		{ sz = Vector3.new(S + WT*2, WH, WT), cf = CFrame.new(0,    WH/2, -H - WT/2) },
		{ sz = Vector3.new(S + WT*2, WH, WT), cf = CFrame.new(0,    WH/2,  H + WT/2) },
		{ sz = Vector3.new(WT, WH, S),        cf = CFrame.new(-H - WT/2, WH/2, 0)    },
		{ sz = Vector3.new(WT, WH, S),        cf = CFrame.new( H + WT/2, WH/2, 0)    },
	}
	for i, d in defs do
		mkpart(borders, "Wall"..i, d.sz, d.cf, C.wallColor, Enum.Material.SmoothPlastic)
		mkpart(borders, "WallTop"..i,
			Vector3.new(d.sz.X + 1, 3, d.sz.Z + 1),
			d.cf * CFrame.new(0, WH / 2 + 1.5, 0),
			C.wallTop, Enum.Material.SmoothPlastic)
	end
end

-- ── Módulo 3 — Cachoeiras (quebram monotonia de bordas com azul) ───────────────
local function buildWaterfalls(borders: Folder): ()
	local falls = { { x = 118, dir = 1 }, { x = -118, dir = -1 } }
	for i, f in falls do
		mkpart(borders, "WFWall"..i,
			Vector3.new(14, 25, 6), CFrame.new(f.x, 12, 0), C.rock, Enum.Material.SmoothPlastic)
		local flow = mkpart(borders, "WFFlow"..i,
			Vector3.new(8, 23, 1.2), CFrame.new(f.x - f.dir * 3.8, 11, 0), C.water, Enum.Material.Neon)
		addLight(flow, 1.5, C.waterLight, 12)
		local pool = mkpart(borders, "WFPool"..i,
			Vector3.new(16, 1.2, 14), CFrame.new(f.x - f.dir * 3.8, 0.6, 0), C.water, Enum.Material.Glass)
		pool.Transparency = 0.35
		addParticles(pool, C.waterLight, Color3.fromRGB(210, 235, 255), 4)
		mkpart(borders, "WFRockL"..i,
			Vector3.new(4.5, 4, 5), CFrame.new(f.x - f.dir * 7, 2, 6) * CFrame.Angles(0, 0.9, 0.1),
			C.rockDark, Enum.Material.SmoothPlastic)
		mkpart(borders, "WFRockR"..i,
			Vector3.new(3.5, 3, 4), CFrame.new(f.x - f.dir * 7, 1.5, -6) * CFrame.Angles(0, 2.2, 0),
			C.rock, Enum.Material.SmoothPlastic)
	end
end

-- ── Módulo 3 — Árvore procedural (5 camadas, tronco duplo) ────────────────────
local function buildTree(folder: Folder, px: number, pz: number, scale: number): ()
	local th = 9 * scale
	mkpart(folder, "TrunkBase",
		Vector3.new(2.8 * scale, 3.5 * scale, 2.8 * scale),
		CFrame.new(px, 1.75 * scale, pz), C.trunkDark, Enum.Material.WoodPlanks)
	mkpart(folder, "TrunkUpper",
		Vector3.new(2.1 * scale, th - 3 * scale, 2.1 * scale),
		CFrame.new(px, 3.5 * scale + (th - 3.5 * scale) / 2, pz), C.trunkLight, Enum.Material.WoodPlanks)
	local layers = {
		{ s = 1.12, dy = th + 1.5 * scale, col = C.leafGreen },
		{ s = 0.92, dy = th + 3.8 * scale, col = C.leafMid   },
		{ s = 0.74, dy = th + 5.8 * scale, col = C.leafLight  },
		{ s = 0.56, dy = th + 7.5 * scale, col = C.leafGreen  },
		{ s = 0.38, dy = th + 9.0 * scale, col = C.leafLight  },
	}
	for _, layer in layers do
		local w = 9 * scale * layer.s
		mkpart(folder, "Leaf",
			Vector3.new(w, 5.5 * scale * layer.s, w),
			CFrame.new(px, layer.dy, pz), layer.col, Enum.Material.Grass)
	end
end

-- ── Módulo 3 — Rocha procedural (2 peças para volume) ─────────────────────────
local function buildRock(folder: Folder, px: number, pz: number, scale: number, yaw: number): ()
	mkpart(folder, "Rock",
		Vector3.new(4.8 * scale, 3.2 * scale, 4.2 * scale),
		CFrame.new(px, 1.6 * scale, pz) * CFrame.Angles(0, yaw, 0.13), C.rock, Enum.Material.SmoothPlastic)
	mkpart(folder, "RockSmall",
		Vector3.new(2.8 * scale, 2.2 * scale, 2.8 * scale),
		CFrame.new(px + 2.8 * scale, scale, pz + 1.6 * scale) * CFrame.Angles(0, yaw + 1.4, 0),
		C.rockDark, Enum.Material.SmoothPlastic)
end

-- ── Módulo 3 — Decoração de bordas (seed 42 = determinístico) ─────────────────
local function buildBorderDecor(borders: Folder): ()
	local H     = GameConfig.MAP_HALF
	local INNER = H - 15
	local OUTER = H - 4

	-- Camada 1: árvores grandes nas bordas
	math.randomseed(GameConfig.BORDER_SEED)
	for _ = 1, GameConfig.TREE_COUNT do
		local side = math.random(1, 4)
		local px: number = 0
		local pz: number = 0
		if side == 1 then
			px = math.random(-H + 10, H - 10); pz = -math.random(INNER, OUTER)
		elseif side == 2 then
			px = math.random(-H + 10, H - 10); pz =  math.random(INNER, OUTER)
		elseif side == 3 then
			px = -math.random(INNER, OUTER);   pz =  math.random(-H + 10, H - 10)
		else
			px =  math.random(INNER, OUTER);   pz =  math.random(-H + 10, H - 10)
		end
		buildTree(borders, px, pz, 0.8 + math.random() * 0.7)
	end

	-- Camada 2: rochas acompanhando as bordas
	math.randomseed(GameConfig.BORDER_SEED + 1)
	for _ = 1, GameConfig.ROCK_COUNT do
		local side = math.random(1, 4)
		local px: number = 0
		local pz: number = 0
		if side == 1 then
			px = math.random(-H + 10, H - 10); pz = -math.random(INNER - 5, OUTER)
		elseif side == 2 then
			px = math.random(-H + 10, H - 10); pz =  math.random(INNER - 5, OUTER)
		elseif side == 3 then
			px = -math.random(INNER - 5, OUTER); pz = math.random(-H + 10, H - 10)
		else
			px =  math.random(INNER - 5, OUTER); pz = math.random(-H + 10, H - 10)
		end
		buildRock(borders, px, pz, 0.5 + math.random() * 0.7, math.random() * math.pi * 2)
	end
end

-- ── Módulo 3 — Caminho do spawn ao gateway (hierarquia de navegação) ──────────
local function buildSpawnPath(env: Folder): ()
	-- Plataforma do spawn (dá identidade ao ponto de nascimento)
	mkpart(env, "SpawnPad",
		Vector3.new(18, 0.7, 18),
		CFrame.new(-70, 0.35, -70) * CFrame.Angles(0, math.rad(45), 0),
		C.stone, Enum.Material.Cobblestone)

	-- Bordas da plataforma do spawn
	for _, sx in {-10, 10} do
		mkpart(env, "SpawnPadEdge"..tostring(sx),
			Vector3.new(18, 1.4, 1.5),
			CFrame.new(-70, 0.7, -70 + sx) * CFrame.Angles(0, math.rad(45), 0),
			C.stoneDark, Enum.Material.SmoothPlastic)
	end

	-- Caminho diagonal do spawn → gateway (6 ladrilhos, alinhados com a diagonal)
	for i = 0, 5 do
		local t  = i / 5
		local tx = -68 + 24 * t   -- de (-68,-68) até (-44,-44)
		local tz = -68 + 24 * t
		mkpart(env, "SpawnPath"..i,
			Vector3.new(7.5, 0.7, 8.5),
			CFrame.new(tx, 0.35, tz) * CFrame.Angles(0, math.rad(45), 0),
			C.stone, Enum.Material.Cobblestone)
		-- Pedras de borda em cada lado do caminho
		for _, side in {-1, 1} do
			mkpart(env, "PathEdge"..i..tostring(side),
				Vector3.new(1.2, 0.9, 8),
				CFrame.new(tx + side * 4.8, 0.45, tz - side * 4.8)
					* CFrame.Angles(0, math.rad(45), 0),
				C.stoneDark, Enum.Material.SmoothPlastic)
		end
	end

	-- Lanternas às margens do caminho (posições 1 e 4)
	for _, ti in {1, 4} do
		local t  = ti / 5
		local tx = -68 + 24 * t
		local tz = -68 + 24 * t
		for _, side in {-1, 1} do
			-- offset perpendicular ao caminho diagonal
			local lx = tx + side * 6.2
			local lz = tz - side * 6.2
			mkpart(env, "PathPoleBase"..ti..tostring(side),
				Vector3.new(1.4, 1, 1.4), CFrame.new(lx, 0.5, lz),
				C.lampMetal, Enum.Material.SmoothPlastic)
			mkpart(env, "PathPole"..ti..tostring(side),
				Vector3.new(0.5, 8, 0.5), CFrame.new(lx, 4.5, lz),
				C.lampMetal, Enum.Material.SmoothPlastic)
			mkpart(env, "PathArm"..ti..tostring(side),
				Vector3.new(0.4, 0.4, 2), CFrame.new(lx, 9, lz - 0.8),
				C.lampMetal, Enum.Material.SmoothPlastic)
			local orb = mkpart(env, "PathOrb"..ti..tostring(side),
				Vector3.new(1.3, 1.3, 1.3), CFrame.new(lx, 9, lz - 1.9),
				C.lampOrb, Enum.Material.Neon)
			addLight(orb, 3, Color3.fromRGB(255, 238, 188), 16)
		end
	end
end

-- ── Módulo 3+5 — Gateway de entrada NW (primeira impressão do jogador) ────────
local function buildGateway(structures: Folder): ()
	local gX, gZ = -44, -44
	local gRot   = CFrame.Angles(0, math.rad(45), 0)  -- orientado para o spawn

	-- Colunas (offset perpendicular à direção de chegada)
	for _, side in {-1, 1} do
		local cx = gX + side * 7
		local cz = gZ - side * 7
		mkpart(structures, "GateBase"..tostring(side),
			Vector3.new(5.5, 3.5, 5.5), CFrame.new(cx, 1.75, cz),
			C.stone, Enum.Material.SmoothPlastic)
		mkpart(structures, "GateCol"..tostring(side),
			Vector3.new(3.8, 24, 3.8), CFrame.new(cx, 14, cz),
			C.marble, Enum.Material.SmoothPlastic)
		mkpart(structures, "GateColBand"..tostring(side),
			Vector3.new(4.8, 1.5, 4.8), CFrame.new(cx, 10, cz),
			C.stoneDark, Enum.Material.SmoothPlastic)
		local capLight = mkpart(structures, "GateCapLight"..tostring(side),
			Vector3.new(2.8, 2.8, 2.8), CFrame.new(cx, 28, cz), C.gold, Enum.Material.Neon)
		addLight(capLight, 1.6, C.gold, 14)  -- calibrado: era 2.8/20
	end

	-- Arco central (rotacionado para enfrentar o spawn em NW)
	mkpart(structures, "GateArch",
		Vector3.new(24, 5, 5.5), CFrame.new(gX, 25, gZ) * gRot,
		C.marble, Enum.Material.SmoothPlastic)
	-- Trim dourado calibrado: SmoothPlastic em vez de Neon puro — sem bloom excessivo
	mkpart(structures, "GateArchTrim",
		Vector3.new(26, 2, 6.5), CFrame.new(gX, 28.5, gZ) * gRot,
		Color3.fromRGB(225, 185, 35), Enum.Material.SmoothPlastic)
	-- Faixa neon fina no centro do trim (destaque sem flood de luz)
	mkpart(structures, "GateArchNeon",
		Vector3.new(22, 0.8, 3), CFrame.new(gX, 28.5, gZ) * gRot,
		C.gold, Enum.Material.Neon)
	mkpart(structures, "GateArchKeystone",
		Vector3.new(4, 5, 5.5), CFrame.new(gX, 25, gZ),
		C.stoneDark, Enum.Material.SmoothPlastic)

	-- Placa "ATHOS HUB" voltada para o jogador que se aproxima
	local signCF = CFrame.new(gX, 23.5, gZ) * gRot * CFrame.new(0, 0, -3.5)
	local welcomeSign = mkpart(structures, "GateSign",
		Vector3.new(15, 5.5, 0.6), signCF, C.signBg, Enum.Material.SmoothPlastic)
	addLabel(welcomeSign, "ATHOS HUB", C.gold)
	addLight(
		mkpart(structures, "GateSignLight", Vector3.new(0.1, 0.1, 0.1),
			signCF * CFrame.new(0, 0, -1.5), C.signBg, Enum.Material.SmoothPlastic),
		2.2, C.gold, 16)   -- calibrado: era 3.5/24 → 2.2/16
end

-- ── Módulo 4 — Jardim interno (entre hub e caminho circular) ──────────────────
local function buildInnerGarden(env: Folder): ()
	local innerR = 44  -- entre borda da plataforma (35) e caminho (55)

	-- Pequenas árvores decorativas em 6 posições (sem NW = entrada do gateway)
	local angles = {
		0,                  -- leste
		math.pi / 2,        -- sul
		math.pi,            -- oeste
		3 * math.pi / 2,    -- norte
		math.pi / 4,        -- SE
		3 * math.pi / 4,    -- SW
	}

	for _, angle in ipairs(angles) do
		local tx = math.cos(angle) * innerR
		local tz = math.sin(angle) * innerR
		-- Pula a direção NW (gateway + corredor de chegada)
		if tx < -18 and tz < -18 then continue end

		-- Tronco duplo (pequeno)
		mkpart(env, "InnTrunk_"..tostring(math.round(angle * 10)),
			Vector3.new(1.8, 5, 1.8), CFrame.new(tx, 2.5, tz),
			C.trunkDark, Enum.Material.WoodPlanks)
		-- 3 camadas de folhagem
		local leafLayers = {
			{ s = 1.0, dy = 7.0, col = C.leafMid   },
			{ s = 0.8, dy = 9.2, col = C.leafGreen  },
			{ s = 0.5, dy = 11.0, col = C.leafLight  },
		}
		for li, layer in ipairs(leafLayers) do
			local w = 7.5 * layer.s
			mkpart(env, "InnLeaf_"..tostring(math.round(angle * 10)).."_"..li,
				Vector3.new(w, 4 * layer.s, w), CFrame.new(tx, layer.dy, tz),
				layer.col, Enum.Material.Grass)
		end

		-- Rocha decorativa na base da árvore
		mkpart(env, "InnRock_"..tostring(math.round(angle * 10)),
			Vector3.new(3, 1.8, 2.5),
			CFrame.new(tx + 2.5, 0.9, tz + 1.5) * CFrame.Angles(0, angle, 0.1),
			C.rock, Enum.Material.SmoothPlastic)
	end
end

-- ── Init ──────────────────────────────────────────────────────────────────────
function MapService.init(): ()
	local base = workspace:FindFirstChild("Baseplate") :: BasePart?
	if base then base.Transparency = 1 end
	local sl = workspace:FindFirstChild("SpawnLocation") :: BasePart?
	if sl then sl.Transparency = 1 end

	local env        = FolderService.get("Environment")
	local structures = FolderService.get("Structures")
	local borders    = FolderService.get("Borders")

	buildTerrain()
	buildCircularPath(env)
	buildGrandPathway(env)
	buildWalls(borders)
	buildWaterfalls(borders)
	buildBorderDecor(borders)
	buildSpawnPath(env)            -- plataforma spawn + caminho diagonal + lanternas
	buildFountain(structures)
	buildHubArea(structures)
	buildGateway(structures)       -- arco ATHOS HUB com placa
	buildInnerGarden(env)          -- árvores entre hub e caminho circular
	buildPortalArea(structures)
	buildVIPPortal(structures)

	print("[MapService] Hub world v3 — gateway, jardim, pilares, bancos, flores.")
end

return MapService
