--!strict

--[[
	MapService — Dojo de treinamento estilo cyberpunk:
	  • Chão escuro com linhas neon azuis
	  • 4 paredes com painéis de luz
	  • 4 pilares nos cantos com topo neon
	  • 8 plataformas circulares para dummies
	  • Balcão da loja (canto +X +Z)
	  • Torre do leaderboard (canto -X +Z)
	  • Iluminação noturna azul-roxa com bloom
]]

local Lighting = game:GetService("Lighting")
local W        = workspace

local MapService = {}

-- Referência ao Part do leaderboard (TrainingService atualiza o SurfaceGui)
MapService.LeaderboardPart = nil :: Part?

-- ── Paleta ────────────────────────────────────────────────────────────────────

local C = {
	floor    = Color3.fromRGB(22,  20,  28),
	wall     = Color3.fromRGB(18,  16,  24),
	pillar   = Color3.fromRGB(30,  28,  40),
	neonBlue = Color3.fromRGB(0,   140, 255),
	neonRed  = Color3.fromRGB(220, 30,  30),
	platform = Color3.fromRGB(38,  32,  52),
	shopDesk = Color3.fromRGB(45,  38,  60),
}

-- ── Utilitários ───────────────────────────────────────────────────────────────

local function part(parent: Instance, pos: Vector3, size: Vector3, color: Color3, mat: Enum.Material?): Part
	local pt         = Instance.new("Part")
	pt.Size          = size
	pt.Position      = pos
	pt.Color         = color
	pt.Material      = mat or Enum.Material.SmoothPlastic
	pt.Anchored      = true
	pt.TopSurface    = Enum.SurfaceType.Smooth
	pt.BottomSurface = Enum.SurfaceType.Smooth
	pt.Parent        = parent
	return pt
end

local function neonPart(parent: Instance, pos: Vector3, size: Vector3, color: Color3): Part
	local pt = part(parent, pos, size, color, Enum.Material.Neon)
	pt.CastShadow = false
	return pt
end

local function pointLight(parent: Instance, color: Color3, brightness: number, range: number): ()
	local l      = Instance.new("PointLight")
	l.Color      = color
	l.Brightness = brightness
	l.Range      = range
	l.Shadows    = true
	l.Parent     = parent
end

-- ── Iluminação ────────────────────────────────────────────────────────────────

local function setupLighting(): ()
	Lighting.ClockTime         = 0
	Lighting.Ambient           = Color3.fromRGB(8,  8,  18)
	Lighting.OutdoorAmbient    = Color3.fromRGB(10, 10, 22)
	Lighting.Brightness        = 0.8
	Lighting.ColorShift_Top    = Color3.fromRGB(20, 20, 50)
	Lighting.ColorShift_Bottom = Color3.fromRGB(5,  5,  15)
	Lighting.FogEnd            = 200
	Lighting.FogColor          = Color3.fromRGB(5,  5,  18)

	for _, child in Lighting:GetChildren() do
		if child:IsA("Atmosphere") or child:IsA("BloomEffect") or child:IsA("ColorCorrectionEffect") then
			child:Destroy()
		end
	end

	local bloom        = Instance.new("BloomEffect")
	bloom.Intensity    = 1.6
	bloom.Size         = 28
	bloom.Threshold    = 0.85
	bloom.Parent       = Lighting

	local cc           = Instance.new("ColorCorrectionEffect")
	cc.Brightness      = -0.06
	cc.Contrast        = 0.18
	cc.Saturation      = 0.15
	cc.TintColor       = Color3.fromRGB(200, 210, 255)
	cc.Parent          = Lighting
end

-- ── Chão ──────────────────────────────────────────────────────────────────────

local function buildFloor(folder: Instance, A: number): ()
	-- Chão principal
	part(folder, Vector3.new(0, 0, 0), Vector3.new(A*2, 1, A*2), C.floor, Enum.Material.SmoothPlastic)

	-- Linhas neon no chão (grade)
	local gridStep = 10
	local i        = -A + gridStep
	while i < A do
		neonPart(folder, Vector3.new(i, 0.52, 0),  Vector3.new(0.15, 0.1, A*2), C.neonBlue)
		neonPart(folder, Vector3.new(0, 0.52, i),  Vector3.new(A*2, 0.1, 0.15), C.neonBlue)
		i += gridStep
	end

	-- Anel central neon
	local ringR = 6
	local segs  = 24
	for s = 0, segs - 1 do
		local a0 = (s / segs) * math.pi * 2
		local a1 = ((s + 1) / segs) * math.pi * 2
		local mx = math.cos((a0 + a1) / 2) * ringR
		local mz = math.sin((a0 + a1) / 2) * ringR
		local len = 2 * ringR * math.sin(math.pi / segs) + 0.05
		local seg = neonPart(folder, Vector3.new(mx, 0.55, mz), Vector3.new(0.18, 0.12, len), C.neonRed)
		seg.CFrame = CFrame.new(Vector3.new(mx, 0.55, mz)) * CFrame.Angles(0, -(a0+a1)/2, 0)
	end
end

-- ── Paredes ───────────────────────────────────────────────────────────────────

local function buildWalls(folder: Instance, A: number, H: number): ()
	local wallDefs = {
		{ Vector3.new( 0,  H/2+0.5,  A),  Vector3.new(A*2+4, H, 2) },
		{ Vector3.new( 0,  H/2+0.5, -A),  Vector3.new(A*2+4, H, 2) },
		{ Vector3.new( A,  H/2+0.5,  0),  Vector3.new(2, H, A*2+4) },
		{ Vector3.new(-A,  H/2+0.5,  0),  Vector3.new(2, H, A*2+4) },
	}
	for _, d in wallDefs do
		part(folder, d[1], d[2], C.wall, Enum.Material.SmoothPlastic)
	end

	-- Painéis neon nas paredes (tiras horizontais)
	local panelH = 0.3
	local heights = { H * 0.25 + 0.5, H * 0.65 + 0.5 }
	for _, py in heights do
		neonPart(folder, Vector3.new(0, py, A+0.05),  Vector3.new(A*2, panelH, 0.2), C.neonBlue)
		neonPart(folder, Vector3.new(0, py, -A-0.05), Vector3.new(A*2, panelH, 0.2), C.neonBlue)
		neonPart(folder, Vector3.new(A+0.05, py, 0),  Vector3.new(0.2, panelH, A*2), C.neonBlue)
		neonPart(folder, Vector3.new(-A-0.05, py, 0), Vector3.new(0.2, panelH, A*2), C.neonBlue)
	end
end

-- ── Pilares dos cantos ────────────────────────────────────────────────────────

local function buildPillar(folder: Instance, cx: number, cz: number, H: number): ()
	local body = part(folder, Vector3.new(cx, H/2+0.5, cz), Vector3.new(4, H+2, 4), C.pillar, Enum.Material.SmoothPlastic)
	-- Topo neon
	local top = neonPart(folder, Vector3.new(cx, H+2.2, cz), Vector3.new(4.4, 0.5, 4.4), C.neonBlue)
	pointLight(top, C.neonBlue, 4, 22)
	-- Linha vertical no pilar
	neonPart(folder, Vector3.new(cx, H/2+0.5, cz + 2.05), Vector3.new(0.2, H, 0.15), C.neonRed)
end

local function buildPillars(folder: Instance, A: number, H: number): ()
	for _, corner in { {A+1, A+1}, {A+1, -A-1}, {-A-1, A+1}, {-A-1, -A-1} } do
		buildPillar(folder, corner[1], corner[2], H)
	end
end

-- ── Plataformas dos dummies ───────────────────────────────────────────────────

local function buildDummyPlatforms(folder: Instance, positions: { Vector3 }): ()
	for _, pos in positions do
		-- Base da plataforma
		local base = part(folder, Vector3.new(pos.X, 0.65, pos.Z), Vector3.new(5, 0.3, 5), C.platform)
		-- Borda neon
		neonPart(folder, Vector3.new(pos.X, 0.82, pos.Z + 2.5), Vector3.new(5, 0.12, 0.15), C.neonRed)
		neonPart(folder, Vector3.new(pos.X, 0.82, pos.Z - 2.5), Vector3.new(5, 0.12, 0.15), C.neonRed)
		neonPart(folder, Vector3.new(pos.X + 2.5, 0.82, pos.Z), Vector3.new(0.15, 0.12, 5), C.neonRed)
		neonPart(folder, Vector3.new(pos.X - 2.5, 0.82, pos.Z), Vector3.new(0.15, 0.12, 5), C.neonRed)
	end
end

-- ── Balcão da loja ────────────────────────────────────────────────────────────

local function buildShop(folder: Instance, A: number): ()
	local sx, sz = A - 8, A - 8

	-- Mesa do balcão
	local desk = part(folder, Vector3.new(sx, 2, sz), Vector3.new(10, 1, 4), C.shopDesk, Enum.Material.SmoothPlastic)
	neonPart(folder,   Vector3.new(sx, 2.55, sz),      Vector3.new(10.1, 0.12, 4.1), C.neonBlue)

	-- Backwall
	local bw = part(folder, Vector3.new(sx, 4.5, sz + 2.2), Vector3.new(10, 6, 0.4), C.pillar)
	neonPart(folder, Vector3.new(sx, 7.1, sz + 2.3), Vector3.new(10, 0.2, 0.2), C.neonBlue)

	-- Label "LOJA" via SurfaceGui
	local gui           = Instance.new("SurfaceGui")
	gui.SizingMode      = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud   = 50
	gui.Face            = Enum.NormalId.Front
	gui.Parent          = bw

	local lbl                  = Instance.new("TextLabel")
	lbl.Size                   = UDim2.new(1, 0, 0.5, 0)
	lbl.Position               = UDim2.new(0, 0, 0.25, 0)
	lbl.BackgroundTransparency = 1
	lbl.Text                   = "LOJA  [E]"
	lbl.Font                   = Enum.Font.GothamBold
	lbl.TextScaled             = true
	lbl.TextColor3             = Color3.fromRGB(0, 200, 255)
	lbl.Parent                 = gui

	pointLight(desk, C.neonBlue, 3, 18)
end

-- ── Torre do leaderboard ──────────────────────────────────────────────────────

local function buildLeaderboard(folder: Instance, A: number): Part
	local lx, lz = -A + 8, A - 8

	-- Base da torre
	part(folder, Vector3.new(lx, 4, lz), Vector3.new(8, 8, 1), C.pillar, Enum.Material.SmoothPlastic)
	neonPart(folder, Vector3.new(lx, 8.15, lz - 0.55), Vector3.new(8.2, 0.2, 0.2), C.neonBlue)
	neonPart(folder, Vector3.new(lx, 0.65, lz - 0.55), Vector3.new(8.2, 0.2, 0.2), C.neonBlue)

	-- Painel onde o SurfaceGui vai
	local board = part(folder, Vector3.new(lx, 4.5, lz - 0.55), Vector3.new(7.5, 7, 0.15), C.floor)
	board.Name  = "LeaderboardBoard"

	local header = Instance.new("SurfaceGui")
	header.SizingMode    = Enum.SurfaceGuiSizingMode.PixelsPerStud
	header.PixelsPerStud = 50
	header.Face          = Enum.NormalId.Front
	header.Name          = "LeaderboardGui"
	header.Parent        = board

	local title                  = Instance.new("TextLabel")
	title.Size                   = UDim2.new(1, 0, 0.15, 0)
	title.BackgroundTransparency = 1
	title.Text                   = "RANKING"
	title.Font                   = Enum.Font.GothamBold
	title.TextScaled             = true
	title.TextColor3             = Color3.fromRGB(0, 200, 255)
	title.Parent                 = header

	local list                   = Instance.new("Frame")
	list.Name                    = "List"
	list.Size                    = UDim2.new(1, 0, 0.85, 0)
	list.Position                = UDim2.new(0, 0, 0.15, 0)
	list.BackgroundTransparency  = 1
	list.Parent                  = header

	pointLight(board, C.neonBlue, 2, 16)

	return board
end

-- ── Init ──────────────────────────────────────────────────────────────────────

function MapService.init(): ()
	setupLighting()

	local old = W:FindFirstChild("TrainingMap")
	if old then old:Destroy() end

	local folder      = Instance.new("Folder")
	folder.Name       = "TrainingMap"
	folder.Parent     = W

	-- Oculta o baseplate padrão
	local base = W:FindFirstChild("Baseplate")
	if base and base:IsA("BasePart") then
		base.Transparency = 1
		base.CanCollide   = false
	end

	-- Oculta SpawnLocation visual
	local sl = W:FindFirstChild("SpawnLocation")
	if sl and sl:IsA("BasePart") then
		sl.Transparency = 1
	end

	local A = 40
	local H = 14

	buildFloor(folder, A)
	buildWalls(folder, A, H)
	buildPillars(folder, A, H)
	buildDummyPlatforms(folder, game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))

	local cfg = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("GameConfig"))
	buildDummyPlatforms(folder, cfg.DUMMY_POSITIONS)
	buildShop(folder, A)
	MapService.LeaderboardPart = buildLeaderboard(folder, A)

	print("[MapService] Dojo construído.")
end

return MapService
