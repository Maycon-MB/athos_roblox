--!strict
-- MapSystem — Gerencia 3 áreas (main/shop/base) e teleporte entre elas.
-- Cria chão placeholder + objetos interativos por área.
-- Lado: Server | Dependências: Settings, Remotes, PlayerData
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local ws = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local MapSystem = {}

local _cfg: any
local teleportRemote: RemoteEvent

-- ── Cria chão e paredes de uma área ─────────────────────────────────
local function buildArea(name: string, area: any)
	local folder = Instance.new("Folder")
	folder.Name = "Area_" .. name
	folder.Parent = ws

	-- Chão — cor diferente por área
	local floorColor = if name == "base"
		then Color3.fromRGB(210, 100, 180)   -- rosa/roxo como no print da base
		elseif name == "main"
		then Color3.fromRGB(80, 80, 90)
		else Color3.fromRGB(200, 170, 100)   -- areia (shop usa chão próprio)
	local floor = Instance.new("Part")
	floor.Name = "Floor_" .. name
	floor.Size = Vector3.new(area.size.X, 2, area.size.Z)
	floor.CFrame = area.spawn * CFrame.new(0, -2, 0)
	floor.Anchored = true
	floor.CanCollide = true
	floor.Color = floorColor
	floor.Material = Enum.Material.SmoothPlastic
	floor.TopSurface = Enum.SurfaceType.Smooth
	floor.BottomSurface = Enum.SurfaceType.Smooth
	floor.Parent = folder

	-- 4 Paredes invisíveis (barreira)
	local wallH = area.size.Y
	local halfX = area.size.X / 2
	local halfZ = area.size.Z / 2
	local baseY = area.spawn.Position.Y + wallH / 2
	local cx = area.spawn.Position.X
	local cz = area.spawn.Position.Z

	local walls = {
		{ CFrame.new(cx, baseY, cz - halfZ), Vector3.new(area.size.X, wallH, 2) },
		{ CFrame.new(cx, baseY, cz + halfZ), Vector3.new(area.size.X, wallH, 2) },
		{ CFrame.new(cx - halfX, baseY, cz), Vector3.new(2, wallH, area.size.Z) },
		{ CFrame.new(cx + halfX, baseY, cz), Vector3.new(2, wallH, area.size.Z) },
	}
	for i, w in walls do
		local wall = Instance.new("Part")
		wall.Name = "Wall_" .. i
		wall.Size = w[2] :: Vector3
		wall.CFrame = w[1] :: CFrame
		wall.Anchored = true
		wall.CanCollide = true
		wall.Transparency = 1
		wall.Parent = folder
	end

	return folder
end

-- ── Cria objetos interativos na área main ───────────────────────────
local function setupMainArea(area: any, folder: Instance)
	local cx = area.spawn.Position.X
	local cz = area.spawn.Position.Z
	local floorY = area.spawn.Position.Y

	-- WaveMachine (para WaveMachinePanel funcionar)
	local machine = Instance.new("Part")
	machine.Name = "WaveMachine"
	machine.Size = Vector3.new(4, 6, 4)
	machine.BrickColor = BrickColor.new("Dark stone grey")
	machine.Material = Enum.Material.SmoothPlastic
	machine.Anchored = true
	machine.Position = Vector3.new(cx + 30, floorY + 3, cz)
	machine.Parent = folder
	CollectionService:AddTag(machine, "WaveMachine")

	-- FusionMachine
	local fuse = Instance.new("Part")
	fuse.Name = "FusionMachine"
	fuse.Size = Vector3.new(4, 6, 4)
	fuse.BrickColor = BrickColor.new("Bright violet")
	fuse.Material = Enum.Material.SmoothPlastic
	fuse.Anchored = true
	fuse.Position = Vector3.new(cx - 30, floorY + 3, cz)
	fuse.Parent = folder
	CollectionService:AddTag(fuse, "FuseMachine")
end

-- ── Constrói sala da loja — estética Roblox SmoothPlastic (quadrados) ─
local function setupShopArea(area: any, folder: Instance)
	local cx    = area.spawn.Position.X
	local cz    = area.spawn.Position.Z
	local baseY = area.spawn.Position.Y
	local halfX = area.size.X / 2
	local halfZ = area.size.Z / 2
	local wallH = area.size.Y
	local midY  = baseY + wallH / 2
	local topY  = baseY + wallH
	local floorY = baseY - 1  -- topo do chão

	-- Cores — estética Roblox quadrado (SmoothPlastic, não tijolo)
	local WALL  = Color3.fromRGB(188, 128, 68)  -- marrom quente
	local ROOF  = Color3.fromRGB(150, 80,  20)
	local FLOOR = Color3.fromRGB(235, 155, 55)  -- laranja
	local RED   = Color3.fromRGB(220, 30,  30)
	local WHITE = Color3.fromRGB(255, 255, 255)
	local MAT   = Enum.Material.SmoothPlastic    -- quadrados Roblox

	local function part(name: string, size: Vector3, cf: CFrame,
		color: Color3, mat: Enum.Material, transparency: number?, collide: boolean?): Part
		local p = Instance.new("Part")
		p.Name          = name; p.Size = size; p.CFrame = cf
		p.Anchored      = true
		p.CanCollide    = if collide == false then false else true
		p.Color         = color; p.Material = mat
		p.Transparency  = transparency or 0
		p.TopSurface    = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		p.Parent        = folder
		return p
	end

	-- Monitor YouTube: tela azul escura com logo do YouTube (= estética do jogo ref)
	local function ytMonitor(cf: CFrame)
		local mon = Instance.new("Part")
		mon.Name          = "YTMonitor"
		mon.Size          = Vector3.new(5, 3.5, 0.25)
		mon.CFrame        = cf
		mon.Anchored      = true; mon.CanCollide = false
		mon.Color         = Color3.fromRGB(20, 20, 30)
		mon.Material      = MAT
		mon.TopSurface    = Enum.SurfaceType.Smooth
		mon.BottomSurface = Enum.SurfaceType.Smooth
		mon.Parent        = folder
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = mon
		-- Fundo da tela
		local bg = Instance.new("Frame")
		bg.Size = UDim2.new(1,0,1,0)
		bg.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
		bg.Parent = sg
		-- Logo YouTube: retângulo vermelho arredondado com ▶
		local logo = Instance.new("Frame")
		logo.Size     = UDim2.new(0.55, 0, 0.58, 0)
		logo.Position = UDim2.new(0.225, 0, 0.21, 0)
		logo.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		logo.Parent = bg
		local lc = Instance.new("UICorner"); lc.CornerRadius = UDim.new(0.18, 0); lc.Parent = logo
		local play = Instance.new("TextLabel")
		play.Size = UDim2.new(1,0,1,0)
		play.BackgroundTransparency = 1
		play.Font = Enum.Font.GothamBold
		play.TextScaled = true
		play.TextColor3 = WHITE
		play.Text = "▶"
		play.Parent = logo
	end

	-- ── Chão + Teto ────────────────────────────────────────────────────
	part("ShopFloor",   Vector3.new(area.size.X, 1, area.size.Z),
		CFrame.new(cx, baseY - 1.5, cz), FLOOR, MAT)
	part("ShopCeiling", Vector3.new(area.size.X + 2, 2, area.size.Z + 2),
		CFrame.new(cx, topY + 1, cz), ROOF, MAT)

	-- ── Paredes (SmoothPlastic — estética "quadrados" do Roblox) ───────
	part("WallLeft",  Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx - halfX, midY, cz), WALL, MAT)
	part("WallRight", Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx + halfX, midY, cz), WALL, MAT)
	part("WallBack",  Vector3.new(area.size.X, wallH, 2),
		CFrame.new(cx, midY, cz + halfZ), WALL, MAT)

	-- ── Monitores YouTube nas paredes ──────────────────────────────────
	-- Parede traseira — 3 monitores (face aponta -Z, em direção à entrada)
	ytMonitor(CFrame.new(cx,     baseY + 5, cz + halfZ - 0.14))
	ytMonitor(CFrame.new(cx - 10, baseY + 5, cz + halfZ - 0.14))
	ytMonitor(CFrame.new(cx + 10, baseY + 5, cz + halfZ - 0.14))
	-- Lateral esquerda — face aponta +X (rotação Y -90°)
	local rotE = CFrame.Angles(0, math.rad(-90), 0)
	ytMonitor(CFrame.new(cx - halfX + 0.14, baseY + 5, cz - 4) * rotE)
	ytMonitor(CFrame.new(cx - halfX + 0.14, baseY + 5, cz + 8) * rotE)
	-- Lateral direita — face aponta -X (rotação Y +90°)
	local rotD = CFrame.Angles(0, math.rad( 90), 0)
	ytMonitor(CFrame.new(cx + halfX - 0.14, baseY + 5, cz - 4) * rotD)
	ytMonitor(CFrame.new(cx + halfX - 0.14, baseY + 5, cz + 8) * rotD)

	-- ── Parede frontal com entrada ──────────────────────────────────────
	local crackW = 8
	local crackH = 8
	local sideW  = halfX - crackW / 2

	part("WallFront_L", Vector3.new(sideW, wallH, 2),
		CFrame.new(cx - crackW/2 - sideW/2, midY, cz - halfZ), WALL, MAT)
	part("WallFront_R", Vector3.new(sideW, wallH, 2),
		CFrame.new(cx + crackW/2 + sideW/2, midY, cz - halfZ), WALL, MAT)
	part("WallFront_Top", Vector3.new(crackW, wallH - crackH, 2),
		CFrame.new(cx, baseY + crackH + (wallH - crackH)/2, cz - halfZ), WALL, MAT)

	-- Sign "Youtuber Jump Shop" (vermelho, acima da entrada)
	local signPart = Instance.new("Part")
	signPart.Name = "ShopSign"; signPart.Size = Vector3.new(crackW + 8, 4, 0.4)
	signPart.CFrame = CFrame.new(cx, baseY + crackH + 2.5, cz - halfZ - 0.2)
	signPart.Anchored = true; signPart.CanCollide = false
	signPart.Color = RED; signPart.Material = MAT
	signPart.TopSurface = Enum.SurfaceType.Smooth; signPart.BottomSurface = Enum.SurfaceType.Smooth
	signPart.Parent = folder
	local sgSign = Instance.new("SurfaceGui"); sgSign.Face = Enum.NormalId.Front; sgSign.Parent = signPart
	local lbSign = Instance.new("TextLabel")
	lbSign.Size = UDim2.new(1,0,1,0); lbSign.BackgroundColor3 = RED; lbSign.BackgroundTransparency = 0
	lbSign.Font = Enum.Font.GothamBold; lbSign.TextScaled = true
	lbSign.TextColor3 = WHITE; lbSign.Text = "Youtuber\nJump Shop"; lbSign.Parent = sgSign

	-- Monitores YouTube na fachada (lado de fora, cada lado da entrada)
	ytMonitor(CFrame.new(cx - crackW/2 - sideW/2, baseY + 5, cz - halfZ - 0.14))
	ytMonitor(CFrame.new(cx + crackW/2 + sideW/2, baseY + 5, cz - halfZ - 0.14))

	-- ── NPC — Shopkeeper sentado atrás de balcão vermelho ──────────────
	-- Balcão vermelho centralizado, ~15 studs da entrada
	local deskX = cx
	local deskZ = cz - halfZ + 14
	-- Pernas do balcão
	for _, side in { -2.2, 2.2 } do
		part("DeskLeg", Vector3.new(0.8, 3.5, 0.8),
			CFrame.new(deskX + side, floorY + 1.75, deskZ), RED, MAT)
	end
	-- Tampo do balcão
	part("DeskTop", Vector3.new(6.5, 0.6, 2.5),
		CFrame.new(deskX, floorY + 3.8, deskZ), RED, MAT)

	-- NPC atrás do balcão — corpo azul estilo Roblox
	local nz  = deskZ + 2.2
	local NBODY = Color3.fromRGB(50, 110, 210)   -- azul médio
	local NHEAD = Color3.fromRGB(255, 213, 170)  -- skin
	local NLEG  = Color3.fromRGB(30,  60,  150)  -- azul escuro (calça)

	-- Torso (visível acima do balcão)
	part("NPC_Torso", Vector3.new(2, 2.5, 1),
		CFrame.new(deskX, floorY + 5.0, nz), NBODY, MAT)
	-- Cabeça
	local npcHead = part("NPC_Head", Vector3.new(2, 2, 2),
		CFrame.new(deskX, floorY + 7.2, nz), NHEAD, MAT)
	-- Braços apoiados no balcão (ligeiramente inclinados para frente)
	part("NPC_ArmL", Vector3.new(1, 2.5, 1),
		CFrame.new(deskX - 1.5, floorY + 4.6, nz - 0.5) * CFrame.Angles(math.rad(20), 0, 0),
		NBODY, MAT)
	part("NPC_ArmR", Vector3.new(1, 2.5, 1),
		CFrame.new(deskX + 1.5, floorY + 4.6, nz - 0.5) * CFrame.Angles(math.rad(20), 0, 0),
		NBODY, MAT)
	-- Pernas (atrás do balcão, não visíveis pela frente)
	part("NPC_LegL", Vector3.new(1, 2.5, 1),
		CFrame.new(deskX - 0.5, floorY + 1.25, nz), NLEG, MAT)
	part("NPC_LegR", Vector3.new(1, 2.5, 1),
		CFrame.new(deskX + 0.5, floorY + 1.25, nz), NLEG, MAT)
	-- Name tag acima da cabeça
	local npcBB = Instance.new("BillboardGui")
	npcBB.Size = UDim2.new(0, 160, 0, 36); npcBB.StudsOffset = Vector3.new(0, 2.2, 0)
	npcBB.AlwaysOnTop = false; npcBB.Parent = npcHead
	local npcLbl = Instance.new("TextLabel")
	npcLbl.Size = UDim2.new(1,0,1,0)
	npcLbl.BackgroundColor3 = Color3.fromRGB(20,16,30); npcLbl.BackgroundTransparency = 0.1
	npcLbl.Font = Enum.Font.GothamBold; npcLbl.TextScaled = true
	npcLbl.TextColor3 = Color3.fromRGB(255,200,40); npcLbl.Text = "Shop Keeper"; npcLbl.Parent = npcBB
	local npcC = Instance.new("UICorner"); npcC.CornerRadius = UDim.new(0,6); npcC.Parent = npcLbl

	-- CrackWall trigger (invisível, no fundo da sala)
	local trigger = Instance.new("Part")
	trigger.Name        = "CrackWall"
	trigger.Size        = Vector3.new(area.size.X - 4, wallH - 2, 1)
	trigger.CFrame      = CFrame.new(cx, midY, cz + halfZ - 2)
	trigger.Anchored    = true
	trigger.CanCollide  = false
	trigger.Transparency = 1
	trigger.Parent      = folder
	CollectionService:AddTag(trigger, "CrackWall")

	print("[MapSystem] Loja construída: Youtuber Jump Shop (tijolo + logos YouTube)")
end

-- ── Teleporte ───────────────────────────────────────────────────────
function MapSystem.teleportTo(player: Player, areaName: string)
	local areas = _cfg.MAP_AREAS
	if not areas then
		return
	end
	local area = areas[areaName]
	if not area then
		warn("[MapSystem] Área desconhecida: " .. tostring(areaName))
		return
	end
	local char = player.Character
	if not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then
		return
	end
	hrp.CFrame = area.spawn * CFrame.new(0, 5, 0) -- +5 studs acima do spawn para não spawnar dentro do chão
	teleportRemote:FireClient(player, areaName, area.label)
	print(string.format("[MapSystem] %s teleportado para '%s'", player.Name, areaName))
end

function MapSystem.getAreaCFrame(areaName: string): CFrame?
	local areas = _cfg.MAP_AREAS
	if not areas then
		return nil
	end
	local area = areas[areaName]
	if not area then
		return nil
	end
	return area.spawn
end

function MapSystem.getAreaBounds(areaName: string): (Vector3?, Vector3?)
	local areas = _cfg.MAP_AREAS
	if not areas then
		return nil, nil
	end
	local area = areas[areaName]
	if not area then
		return nil, nil
	end
	return area.spawn.Position, area.size
end

function MapSystem.init(cfg: any)
	_cfg = cfg
	local R = require(RS.Shared.Remotes)

	teleportRemote = Instance.new("RemoteEvent")
	teleportRemote.Name = R.TeleportArea
	teleportRemote.Parent = RS

	-- Cria as 3 áreas
	local areas = cfg.MAP_AREAS
	if not areas then
		warn("[MapSystem] Settings.MAP_AREAS ausente — MapSystem desativado.")
		return
	end

	for name, area in areas do
		local folder = buildArea(name, area)
		if name == "main" then
			setupMainArea(area, folder)
		elseif name == "shop" then
			setupShopArea(area, folder)
		end
	end

	-- SpawnLocation na área main
	local mainArea = areas.main
	if mainArea then
		local sl = Instance.new("SpawnLocation")
		sl.Size = Vector3.new(6, 1, 6)
		sl.CFrame = mainArea.spawn
		sl.Anchored = true
		sl.Transparency = 1
		sl.CanCollide = true
		sl.Neutral = true
		sl.Parent = ws
		print(
			string.format(
				"[MapSystem] SpawnLocation criada em (%.0f, %.0f, %.0f)",
				mainArea.spawn.Position.X,
				mainArea.spawn.Position.Y,
				mainArea.spawn.Position.Z
			)
		)

		Players.PlayerAdded:Connect(function(player)
			player.RespawnLocation = sl
		end)
		for _, player in Players:GetPlayers() do
			player.RespawnLocation = sl
		end
	end

	print("[MapSystem] 3 áreas criadas: main, shop, base")
end

return MapSystem
