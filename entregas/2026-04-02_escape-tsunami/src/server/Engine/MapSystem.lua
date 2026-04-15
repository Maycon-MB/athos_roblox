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
	if name ~= "shop" then
		local floorColor = if name == "base"
			then Color3.fromRGB(210, 100, 180)
			else Color3.fromRGB(80, 80, 90)
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

	local trigger = mk("CrackWall", Vector3.new(area.size.X - 4, wallH - 2, 1),
		CFrame.new(cx, midY, cz + halfZ - 2), WALL, nil, 1, false)
	CollectionService:AddTag(trigger, "CrackWall")

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
