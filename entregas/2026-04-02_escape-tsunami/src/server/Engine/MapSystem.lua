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

	-- shop constrói chão e paredes próprias em setupShopArea
	-- main e base usam modelos do ServerStorage (carregados após buildArea)
	if name ~= "shop" and name ~= "main" and name ~= "base" then
		local floor = Instance.new("Part")
		floor.Name = "Floor_" .. name
		floor.Size = Vector3.new(area.size.X, 2, area.size.Z)
		floor.CFrame = area.spawn * CFrame.new(0, -2, 0)
		floor.Anchored = true
		floor.CanCollide = true
		floor.Material = Enum.Material.SmoothPlastic
		floor.TopSurface = Enum.SurfaceType.Smooth
		floor.BottomSurface = Enum.SurfaceType.Smooth
		floor.Parent = folder
	end

	return folder
end

-- ── Clona "base escape tsunami" dentro da área main, perto do pivot do mapa ──
local function loadBaseModelsInMain(folder: Instance, mapCF: CFrame)
	local SS = game:GetService("ServerStorage")
	local bases: { Instance } = {}
	for _, child in SS:GetChildren() do
		if child.Name == "base escape tsunami" then
			table.insert(bases, child)
		end
	end
	if #bases == 0 then
		warn("[MapSystem] 'base escape tsunami' não encontrado no ServerStorage")
		return
	end
	-- Posiciona em grade centrada no CFrame recebido (BaseZone ou pivot do mapa)
	local origin = mapCF
	local spacing = 10
	local cols  = math.ceil(math.sqrt(#bases))
	local nrows = math.ceil(#bases / cols)
	for i, base in bases do
		local row = math.floor((i - 1) / cols)
		local col = (i - 1) % cols
		local x = origin.Position.X + (col - (cols - 1) / 2) * spacing
		local z = origin.Position.Z + (row - (nrows - 1) / 2) * spacing
		local clone = base:Clone()
		clone.Name = "BasePedestal_" .. i
		clone.Parent = folder
		if clone:IsA("Model") then
			clone:PivotTo(CFrame.new(x, origin.Position.Y, z))
		elseif clone:IsA("BasePart") then
			(clone :: BasePart).CFrame = CFrame.new(x, origin.Position.Y, z)
		end
	end
	print(string.format("[MapSystem] %d pedestais posicionados dentro de Area_main", #bases))
end

-- ── Cria BrainrotSpawn Folder varrendo os BaseParts do modelo Map ──
-- Encontra partes grandes, planas e no nível do chão real — ignora safe areas em Y diferente.
local function buildSpawnPointsFolder(area: any)
	-- Remove folder de runs anteriores
	local existing = ws:FindFirstChild("BrainrotSpawn")
	if existing then existing:Destroy() end

	local folder = Instance.new("Folder")
	folder.Name = "BrainrotSpawn"
	folder.Parent = ws

	local mapModel = ws:FindFirstChild("Map")
	if not mapModel then
		warn("[MapSystem] Map não encontrado — BrainrotSpawn vazio, brainrots não vão spawnar.")
		return
	end

	-- groundY = Y do SpawnLocation real (já atualizado antes desta chamada)
	local groundY = area.spawn.Position.Y
	-- Janela de ±2 studs em torno do chão real: exclui safe areas recuadas/elevadas
	local yMin = groundY - 2
	local yMax = groundY + 2

	local added = 0
	for _, obj in mapModel:GetDescendants() do
		if not obj:IsA("BasePart") then continue end
		local bp = obj :: BasePart

		-- Apenas partes planas (UpVector aponta para cima — descarta paredes e tetos inclinados)
		if bp.CFrame.UpVector.Y < 0.7 then continue end

		-- Apenas partes grandes o suficiente para ser chão jogável (≥10 studs em X e Z)
		if bp.Size.X < 10 or bp.Size.Z < 10 then continue end

		-- Não sensores invisíveis
		if bp.Transparency >= 0.9 then continue end

		-- Top surface da parte deve estar dentro da janela do chão real
		local topSurfY = bp.Position.Y + bp.Size.Y * 0.5
		if topSurfY < yMin or topSurfY > yMax then continue end

		local p = Instance.new("Part")
		p.Name        = "SpawnPt_" .. added
		-- Limita tamanho do spawn point a 14 studs para não gerar offsets absurdos
		p.Size        = Vector3.new(math.min(bp.Size.X, 14), 1, math.min(bp.Size.Z, 14))
		p.CFrame      = CFrame.new(bp.Position.X, topSurfY, bp.Position.Z)
		p.Anchored    = true
		p.CanCollide  = false
		p.Transparency = 1
		p.Parent      = folder
		added += 1
	end

	print(string.format("[MapSystem] BrainrotSpawn: %d floor parts encontradas no Map (janela Y [%.1f, %.1f])",
		added, yMin, yMax))
end

-- ── Encontra o Map já existente no Workspace ────────────────────────
-- O Map fica permanentemente no Workspace (visível no Studio).
-- Spawn e base_origin são configurados em Settings.MAP_AREAS.main
-- NOTA: buildSpawnPointsFolder é chamado DEPOIS de ler o SpawnLocation real (groundY correto).
local function loadMainMap(folder: Instance, area: any)
	local mapModel = ws:FindFirstChild("Map")
	if not mapModel then
		warn("[MapSystem] 'Map' não encontrado no Workspace — arraste a Folder Map do ServerStorage para o Workspace no Studio")
	else
		print(string.format(
			"[MapSystem] Map encontrado no Workspace → spawn (%.1f, %.1f, %.1f)",
			area.spawn.Position.X, area.spawn.Position.Y, area.spawn.Position.Z
		))
	end
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

-- ── Constrói sala da loja — studs clássico + stall + NPC R6 ──────────
local function setupShopArea(area: any, folder: Instance)
	local cx     = area.spawn.Position.X
	local cz     = area.spawn.Position.Z
	local baseY  = area.spawn.Position.Y
	local halfX  = area.size.X / 2
	local halfZ  = area.size.Z / 2
	local wallH  = area.size.Y
	local floorY = baseY - 1              -- topo do chão (Y=9)
	local midY   = floorY + wallH / 2     -- centro das paredes (Y=24)
	local topY   = floorY + wallH         -- topo (Y=39)
	local frontZ = cz - halfZ             -- parede frontal

	-- Cores
	local WALL   = Color3.fromRGB(218, 133, 65)
	local ROOF   = Color3.fromRGB(150, 75,  20)
	local FLOOR  = Color3.fromRGB(232, 158, 60)
	local RED    = Color3.fromRGB(220, 30,  30)
	local STBLUE = Color3.fromRGB(30,  100, 200)   -- pilares do stall
	local WHITE  = Color3.fromRGB(255, 255, 255)
	local MAT    = Enum.Material.Plastic   -- Plastic mostra studs claramente
	local SMOOTH = Enum.SurfaceType.Smooth
	local STUDS  = Enum.SurfaceType.Studs

	-- Helper genérico (mat e topSurf opcionais)
	local function mk(pname: string, size: Vector3, cf: CFrame,
		color: Color3, mat: Enum.Material?, transp: number?,
		collide: boolean?, topSurf: Enum.SurfaceType?): Part
		local p = Instance.new("Part")
		p.Name         = pname;  p.Size   = size;    p.CFrame  = cf
		p.Anchored     = true
		p.CanCollide   = if collide == false then false else true
		p.Color        = color;  p.Material = mat or MAT
		p.Transparency = transp or 0
		p.TopSurface   = topSurf or SMOOTH
		p.BottomSurface = SMOOTH
		p.Parent       = folder
		return p
	end

	-- Screen YouTube: parte plana, SurfaceGui na face passada
	local function ytScreen(pos: Vector3, size: Vector3, face: Enum.NormalId)
		local scr = mk("YTScreen", size, CFrame.new(pos),
			Color3.fromRGB(35, 35, 35), nil, nil, false)
		local sg = Instance.new("SurfaceGui"); sg.Face = face; sg.Parent = scr
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.fromRGB(8, 8, 8)
		bg.Parent = sg
		local yt = Instance.new("Frame")
		yt.Size = UDim2.fromScale(0.55, 0.5)
		yt.Position = UDim2.fromScale(0.225, 0.25)
		yt.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
		yt.Parent = bg
		local uc = Instance.new("UICorner"); uc.CornerRadius = UDim.new(0.14, 0); uc.Parent = yt
		local pl = Instance.new("TextLabel")
		pl.Size = UDim2.fromScale(1, 1); pl.BackgroundTransparency = 1
		pl.Font = Enum.Font.GothamBold; pl.TextScaled = true
		pl.TextColor3 = WHITE; pl.Text = "▶"; pl.Parent = yt
	end

	-- ── Chão com Studs ─────────────────────────────────────────────────
	mk("ShopFloor", Vector3.new(area.size.X, 1, area.size.Z),
		CFrame.new(cx, baseY - 1.5, cz), FLOOR, nil, nil, nil, STUDS)

	-- ── Teto ────────────────────────────────────────────────────────────
	mk("ShopCeiling", Vector3.new(area.size.X + 2, 2, area.size.Z + 2),
		CFrame.new(cx, topY + 1, cz), ROOF)

	-- Paredes com Studs na face interior
	mk("WallBack", Vector3.new(area.size.X, wallH, 2),
		CFrame.new(cx, midY, cz + halfZ), WALL).FrontSurface = STUDS
	mk("WallLeft", Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx - halfX, midY, cz), WALL).RightSurface = STUDS
	mk("WallRight", Vector3.new(2, wallH, area.size.Z),
		CFrame.new(cx + halfX, midY, cz), WALL).LeftSurface = STUDS

	local crackW    = 8;   local crackH = 8
	local sideW     = halfX - crackW / 2
	local topSecH   = wallH - crackH
	local topSecMid = floorY + crackH + topSecH / 2

	mk("WallFront_L", Vector3.new(sideW, wallH, 2),
		CFrame.new(cx - crackW/2 - sideW/2, midY, frontZ), WALL).BackSurface = STUDS
	mk("WallFront_R", Vector3.new(sideW, wallH, 2),
		CFrame.new(cx + crackW/2 + sideW/2, midY, frontZ), WALL).BackSurface = STUDS
	mk("WallFront_Top", Vector3.new(crackW, topSecH, 2),
		CFrame.new(cx, topSecMid, frontZ), WALL).BackSurface = STUDS

	-- Helper: cria placa com texto "Youtuber\nJump Shop"
	local function makeSign(pname: string, size: Vector3, cf: CFrame)
		local s = mk(pname, size, cf, RED, nil, nil, false)
		local sg = Instance.new("SurfaceGui"); sg.Face = Enum.NormalId.Front; sg.Parent = s
		local lb = Instance.new("TextLabel")
		lb.Size = UDim2.fromScale(1, 1); lb.BackgroundColor3 = RED
		lb.BackgroundTransparency = 0; lb.Font = Enum.Font.GothamBold
		lb.TextScaled = true; lb.TextColor3 = WHITE
		lb.Text = "Youtuber\nJump Shop"; lb.Parent = sg
	end

	-- Sign exterior (visível de fora, face Front = -Z)
	makeSign("ShopSignExt", Vector3.new(crackW + 8, 4, 0.4),
		CFrame.new(cx, floorY + crackH + 2.5, frontZ - 0.2))

	-- ── YouTube screens nas paredes (sem rotação, NormalId correto) ────
	-- Parede traseira — face Front (-Z) aponta para interior ✓
	ytScreen(Vector3.new(cx - 8, floorY + 8, cz + halfZ - 0.16),
		Vector3.new(5, 4, 0.3), Enum.NormalId.Front)
	ytScreen(Vector3.new(cx,     floorY + 8, cz + halfZ - 0.16),
		Vector3.new(5, 4, 0.3), Enum.NormalId.Front)
	ytScreen(Vector3.new(cx + 8, floorY + 8, cz + halfZ - 0.16),
		Vector3.new(5, 4, 0.3), Enum.NormalId.Front)
	-- Parede direita — face Left (-X) aponta para interior ✓
	ytScreen(Vector3.new(cx + halfX - 0.16, floorY + 8, cz - 8),
		Vector3.new(0.3, 4, 5), Enum.NormalId.Left)
	ytScreen(Vector3.new(cx + halfX - 0.16, floorY + 8, cz + 6),
		Vector3.new(0.3, 4, 5), Enum.NormalId.Left)
	-- Parede esquerda — face Right (+X) aponta para interior ✓
	ytScreen(Vector3.new(cx - halfX + 0.16, floorY + 8, cz - 8),
		Vector3.new(0.3, 4, 5), Enum.NormalId.Right)
	ytScreen(Vector3.new(cx - halfX + 0.16, floorY + 8, cz + 6),
		Vector3.new(0.3, 4, 5), Enum.NormalId.Right)

	-- ── Stall "Youtuber Jump Shop" (pilares azuis + balcão + sign) ─────
	local stallZ = cz + 10         -- 10 studs além do centro, na metade traseira
	-- Pilares
	mk("Stall_PillarL", Vector3.new(2, 8, 2),
		CFrame.new(cx - 5, floorY + 4,   stallZ), STBLUE)
	mk("Stall_PillarR", Vector3.new(2, 8, 2),
		CFrame.new(cx + 5, floorY + 4,   stallZ), STBLUE)
	-- Balcão
	mk("Stall_CounterTop", Vector3.new(12, 0.8, 2.5),
		CFrame.new(cx, floorY + 3.6, stallZ), RED)
	mk("Stall_CounterFront", Vector3.new(12, 3.2, 0.5),
		CFrame.new(cx, floorY + 1.6, stallZ - 1.25), RED)
	-- Sign interior sobre o stall (face Front = -Z, visível de quem entra)
	makeSign("ShopSign", Vector3.new(12, 3.5, 0.4),
		CFrame.new(cx, floorY + 9.5, stallZ))

	-- ── NPC — R6 branco, cabeça preta, olhos vermelhos Neon ────────────
	local npcX  = cx
	local npcZ  = stallZ + 3       -- atrás do balcão, bem no fundo da loja
	local NWHITE = Color3.fromRGB(242, 243, 243)
	local NBLACK = Color3.fromRGB(17,  17,  17)
	local REDEYE = Color3.fromRGB(255, 20,  20)

	mk("NPC_LegL",       Vector3.new(1, 2,   1),
		CFrame.new(npcX - 0.55, floorY + 1,   npcZ), NWHITE)
	mk("NPC_LegR",       Vector3.new(1, 2,   1),
		CFrame.new(npcX + 0.55, floorY + 1,   npcZ), NWHITE)
	mk("NPC_LowerTorso", Vector3.new(2, 1,   1),
		CFrame.new(npcX,        floorY + 2.5,  npcZ), NWHITE)
	mk("NPC_UpperTorso", Vector3.new(2, 2,   1),
		CFrame.new(npcX,        floorY + 4,    npcZ), NWHITE)
	mk("NPC_ArmL",       Vector3.new(1, 2,   1),
		CFrame.new(npcX - 1.5,  floorY + 4,    npcZ), NWHITE)
	mk("NPC_ArmR",       Vector3.new(1, 2,   1),
		CFrame.new(npcX + 1.5,  floorY + 4,    npcZ), NWHITE)
	mk("NPC_HandL",      Vector3.new(1, 0.8, 1),
		CFrame.new(npcX - 1.5,  floorY + 2.6,  npcZ), NWHITE)
	mk("NPC_HandR",      Vector3.new(1, 0.8, 1),
		CFrame.new(npcX + 1.5,  floorY + 2.6,  npcZ), NWHITE)

	-- Cabeça preta
	local npcHead = mk("NPC_Head", Vector3.new(2, 2, 2),
		CFrame.new(npcX, floorY + 6.2, npcZ), NBLACK)

	-- Olhos vermelhos Neon — na face -Z da cabeça (frente do NPC = -Z)
	mk("NPC_EyeL", Vector3.new(0.5, 0.5, 0.3),
		CFrame.new(npcX - 0.5, floorY + 6.5, npcZ - 1.05),
		REDEYE, Enum.Material.Neon, nil, false)
	mk("NPC_EyeR", Vector3.new(0.5, 0.5, 0.3),
		CFrame.new(npcX + 0.5, floorY + 6.5, npcZ - 1.05),
		REDEYE, Enum.Material.Neon, nil, false)

	local auraPart = mk("NPC_Aura", Vector3.new(4, 10, 4),
		CFrame.new(npcX, floorY + 4.5, npcZ), WALL, nil, 1, false)
	local fire = Instance.new("Fire")
	fire.Color          = Color3.fromRGB(10, 0, 20)
	fire.SecondaryColor = Color3.fromRGB(0, 0, 0)
	fire.Heat           = 9
	fire.Size           = 9
	fire.Parent         = auraPart

	-- ── Silver YouTube buttons nas paredes ────────────────────────────
	local SS = game:GetService("ServerStorage")
	local ytBtn = SS:FindFirstChild("silver YouTube button", true)
	if ytBtn then
		-- helper: clona o modelo e posiciona via PrimaryPart ou SetPrimaryPartCFrame
		local function placeBtn(cf: CFrame)
			local clone = ytBtn:Clone()
			clone.Parent = folder
			if clone:IsA("Model") and clone.PrimaryPart then
				clone:SetPrimaryPartCFrame(cf)
			elseif clone:IsA("BasePart") then
				clone.CFrame = cf
			else
				-- modelo sem PrimaryPart: usa PivotTo (funciona em qualquer Model)
				clone:PivotTo(cf)
			end
		end

		local btnY   = floorY + 6       -- altura no centro das paredes
		-- paredes têm 2 studs de espessura; face interna = halfX/halfZ - 1
		-- inset = 2 garante que o pivot fique 1 stud fora da face interna
		local inset  = 2

		-- Parede traseira (cz + halfZ): face para -Z (interior) → sem rotação
		placeBtn(CFrame.new(cx - 10, btnY, cz + halfZ - inset))
		placeBtn(CFrame.new(cx,      btnY, cz + halfZ - inset))
		placeBtn(CFrame.new(cx + 10, btnY, cz + halfZ - inset))

		-- Parede esquerda (cx - halfX): face para +X (interior)
		placeBtn(CFrame.new(cx - halfX + inset, btnY, cz - 8)
			* CFrame.Angles(0, -math.pi / 2, 0))
		placeBtn(CFrame.new(cx - halfX + inset, btnY, cz + 8)
			* CFrame.Angles(0, -math.pi / 2, 0))

		-- Parede direita (cx + halfX): face para -X (interior)
		placeBtn(CFrame.new(cx + halfX - inset, btnY, cz - 8)
			* CFrame.Angles(0, math.pi / 2, 0))
		placeBtn(CFrame.new(cx + halfX - inset, btnY, cz + 8)
			* CFrame.Angles(0, math.pi / 2, 0))
	else
		warn("[MapSystem] 'silver YouTube button' não encontrado no ServerStorage")
	end

	-- ShopExit: sensor invisível no vão da porta frontal — player atravessa e volta ao mapa
	local exitPart = mk("ShopExit", Vector3.new(crackW, crackH, 1),
		CFrame.new(cx, floorY + crackH / 2, frontZ + 1), WALL, nil, 1, false)
	exitPart.CanCollide = false
	exitPart.CanTouch   = true
	CollectionService:AddTag(exitPart, "ShopExit")

	-- ShopCounter: trigger invisível em frente ao balcão — abre a JumpShop UI
	local counterTrigger = mk("ShopCounter", Vector3.new(10, 6, 4),
		CFrame.new(cx, floorY + 3, cz), WALL, nil, 1, false)
	counterTrigger.CanCollide = false
	counterTrigger.CanTouch   = true
	CollectionService:AddTag(counterTrigger, "ShopCounter")

	-- teleport_in: player nasce 6 studs dentro da porta, olhando para o balcão (+Z)
	area.teleport_in = CFrame.new(cx, floorY + 3, frontZ + 6)
		* CFrame.Angles(0, math.pi, 0)

	-- teleport_out: usa ShopReturn se existir, senão spawn principal
	local shopReturn = workspace:FindFirstChild("ShopReturn")
	area.teleport_out = if shopReturn and shopReturn:IsA("BasePart")
		then (shopReturn :: BasePart).CFrame
		else CFrame.new(-246, 0, -575)

	print("[MapSystem] Loja: studs + stall no fundo + YTscreens + silver buttons + NPC sem nametag")
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

	-- Limpa folders de runs anteriores para evitar acúmulo de parts
	for _, child in ws:GetChildren() do
		if child.Name:sub(1, 5) == "Area_" then
			child:Destroy()
		end
	end

	-- Cria as 3 áreas
	local areas = cfg.MAP_AREAS
	if not areas then
		warn("[MapSystem] Settings.MAP_AREAS ausente — MapSystem desativado.")
		return
	end

	-- ShopAnchor: Model da rachadura colocado pelo usuário no Studio.
	-- É só decoração visual + ponto de trigger. A loja fica em MAP_AREAS.shop.spawn (longe do mapa).
	if areas.shop then
		local shopAnchor = ws:FindFirstChild("ShopAnchor", true)
		if shopAnchor then
			local anchorPos: Vector3
			if shopAnchor:IsA("Model") then
				anchorPos = (shopAnchor :: Model):GetPivot().Position
				for _, desc in (shopAnchor :: Model):GetDescendants() do
					if desc:IsA("BasePart") then
						(desc :: BasePart).Anchored   = true
						(desc :: BasePart).CanCollide = false
					end
				end
			elseif shopAnchor:IsA("BasePart") then
				anchorPos = (shopAnchor :: BasePart).Position
				;(shopAnchor :: BasePart).Anchored   = true
				;(shopAnchor :: BasePart).CanCollide = false
			else
				anchorPos = areas.shop.spawn.Position
			end

			-- teleport_out: player volta para 6 studs na frente da rachadura
			areas.shop.teleport_out = CFrame.new(anchorPos.X, anchorPos.Y, anchorPos.Z - 6)

			-- Sensor invisível com tamanho garantido — cobre a abertura da rachadura
			local sensor = Instance.new("Part")
			sensor.Name         = "ShopEntranceSensor"
			sensor.Size         = Vector3.new(6, 8, 2)
			sensor.CFrame       = CFrame.new(anchorPos.X, anchorPos.Y + 4, anchorPos.Z)
			sensor.Anchored     = true
			sensor.CanCollide   = false
			sensor.CanTouch     = true
			sensor.Transparency = 0.5   -- visível temporariamente para debug (verde)
			sensor.Color        = Color3.fromRGB(0, 200, 0)
			sensor.Material     = Enum.Material.Neon
			sensor.Parent       = ws
			CollectionService:AddTag(sensor, "ShopEntrance")

			print(string.format("[MapSystem] ShopAnchor: sensor em (%.0f, %.0f, %.0f) | loja em (%.0f, %.0f, %.0f)",
				anchorPos.X, anchorPos.Y, anchorPos.Z,
				areas.shop.spawn.Position.X, areas.shop.spawn.Position.Y, areas.shop.spawn.Position.Z))
		else
			warn("[MapSystem] ShopAnchor não encontrado — coloque o Model da rachadura no Workspace e nomeie 'ShopAnchor'.")
		end
	end

	for name, area in areas do
		local folder = buildArea(name, area)
		if name == "main" then
			setupMainArea(area, folder)
			loadMainMap(folder, area)
		elseif name == "shop" then
			setupShopArea(area, folder)
		end
	end

	-- SpawnLocation: usa a colocada manualmente no Studio (ou cria fallback)
	local mainArea = areas.main
	if mainArea then
		local sl = ws:FindFirstChild("SpawnLocation", true) :: SpawnLocation?
		if sl then
			-- Atualiza area.spawn com a posição real → BrainrotSystem/WaveSystem usam bounds corretos
			mainArea.spawn = (sl :: SpawnLocation).CFrame
			print(string.format("[MapSystem] SpawnLocation do Studio: (%.0f, %.0f, %.0f)",
				(sl :: SpawnLocation).CFrame.Position.X,
				(sl :: SpawnLocation).CFrame.Position.Y,
				(sl :: SpawnLocation).CFrame.Position.Z))
		else
			sl = Instance.new("SpawnLocation") :: SpawnLocation
			;(sl :: SpawnLocation).Size = Vector3.new(6, 1, 6)
			;(sl :: SpawnLocation).CFrame = mainArea.spawn
			;(sl :: SpawnLocation).Anchored = true
			;(sl :: SpawnLocation).Transparency = 1
			;(sl :: SpawnLocation).CanCollide = true
			;(sl :: SpawnLocation).Neutral = true
			;(sl :: SpawnLocation).Parent = ws
			warn("[MapSystem] SpawnLocation não encontrada no Workspace — criada em fallback. Adicione uma no Studio.")
		end

		Players.PlayerAdded:Connect(function(player)
			player.RespawnLocation = sl :: SpawnLocation
		end)
		for _, player in Players:GetPlayers() do
			player.RespawnLocation = sl :: SpawnLocation
		end

		-- Gera spawn points DEPOIS de ler o SpawnLocation real, para groundY correto.
		-- area.spawn já foi atualizado com a CFrame real do SpawnLocation acima.
		buildSpawnPointsFolder(mainArea)
	end

	print("[MapSystem] Áreas criadas: " .. table.concat((function() local t={} for k in areas do table.insert(t,k) end return t end)(), ", "))
end

return MapSystem
