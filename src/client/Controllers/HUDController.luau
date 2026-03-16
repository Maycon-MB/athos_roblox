--!strict

--[[
	HUDController — HUD de combate:
	  • Barra de vida (baixo esquerda)
	  • Indicador de onda (topo centro)
	  • Contador de zumbis vivos (topo direita)
	  • Flash vermelho ao levar dano
	  • Tela de vitória
]]

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteNames"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local HUDController = {}

local screen        = Instance.new("ScreenGui")
screen.Name         = "AthosHUD"
screen.ResetOnSpawn = false
screen.Parent       = playerGui

-- ── Mira ─────────────────────────────────────────────────────────────────────

local cross = Instance.new("Frame")
cross.Size                   = UDim2.new(0, 16, 0, 16)
cross.Position               = UDim2.new(0.5, -8, 0.5, -8)
cross.BackgroundTransparency = 1
cross.Parent                 = screen

local function crossLine(size: UDim2, pos: UDim2): ()
	local l = Instance.new("Frame")
	l.Size                   = size; l.Position = pos
	l.BackgroundColor3       = Color3.fromRGB(255, 255, 255)
	l.BackgroundTransparency = 0.35
	l.BorderSizePixel        = 0
	l.Parent                 = cross
end
crossLine(UDim2.new(0,2,0,10), UDim2.new(0.5,-1,0.5,-5))
crossLine(UDim2.new(0,10,0,2), UDim2.new(0.5,-5,0.5,-1))

-- ── Wave Banner (topo centro) ─────────────────────────────────────────────────

local waveBox                    = Instance.new("Frame")
waveBox.Size                     = UDim2.new(0, 260, 0, 48)
waveBox.Position                 = UDim2.new(0.5, -130, 0, 10)
waveBox.BackgroundColor3         = Color3.fromRGB(8, 0, 0)
waveBox.BackgroundTransparency   = 0.3
waveBox.BorderSizePixel          = 0
waveBox.Parent                   = screen
Instance.new("UICorner", waveBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", waveBox).Color        = Color3.fromRGB(140, 20, 20)

local waveLabel                  = Instance.new("TextLabel")
waveLabel.Size                   = UDim2.new(1, 0, 1, 0)
waveLabel.BackgroundTransparency = 1
waveLabel.Text                   = "Aguardando..."
waveLabel.Font                   = Enum.Font.GothamBold
waveLabel.TextSize               = 20
waveLabel.TextColor3             = Color3.fromRGB(255, 60, 60)
waveLabel.TextXAlignment         = Enum.TextXAlignment.Center
waveLabel.Parent                 = waveBox

-- ── Contador de zumbis (topo direita) ────────────────────────────────────────

local zombieBox                  = Instance.new("Frame")
zombieBox.Size                   = UDim2.new(0, 170, 0, 48)
zombieBox.Position               = UDim2.new(1, -186, 0, 10)
zombieBox.BackgroundColor3       = Color3.fromRGB(8, 0, 0)
zombieBox.BackgroundTransparency = 0.3
zombieBox.BorderSizePixel        = 0
zombieBox.Parent                 = screen
Instance.new("UICorner", zombieBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", zombieBox).Color        = Color3.fromRGB(140, 20, 20)

local zombieLabel                = Instance.new("TextLabel")
zombieLabel.Size                 = UDim2.new(1, 0, 1, 0)
zombieLabel.BackgroundTransparency = 1
zombieLabel.Text                 = ""
zombieLabel.Font                 = Enum.Font.GothamBold
zombieLabel.TextSize             = 18
zombieLabel.TextColor3           = Color3.fromRGB(220, 180, 180)
zombieLabel.TextXAlignment       = Enum.TextXAlignment.Center
zombieLabel.Parent               = zombieBox

-- ── Barra de vida (baixo esquerda) ───────────────────────────────────────────

local hpBox                      = Instance.new("Frame")
hpBox.Size                       = UDim2.new(0, 250, 0, 54)
hpBox.Position                   = UDim2.new(0, 16, 1, -70)
hpBox.BackgroundColor3           = Color3.fromRGB(8, 0, 0)
hpBox.BackgroundTransparency     = 0.3
hpBox.BorderSizePixel            = 0
hpBox.Parent                     = screen
Instance.new("UICorner", hpBox).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", hpBox).Color        = Color3.fromRGB(140, 20, 20)

local hpTitle                    = Instance.new("TextLabel")
hpTitle.Size                     = UDim2.new(1, -10, 0, 18)
hpTitle.Position                 = UDim2.new(0, 10, 0, 4)
hpTitle.BackgroundTransparency   = 1
hpTitle.Text                     = "VIDA"
hpTitle.Font                     = Enum.Font.GothamBold
hpTitle.TextSize                 = 12
hpTitle.TextColor3               = Color3.fromRGB(255, 80, 80)
hpTitle.TextXAlignment           = Enum.TextXAlignment.Left
hpTitle.Parent                   = hpBox

local hpBg                       = Instance.new("Frame")
hpBg.Size                        = UDim2.new(1, -16, 0, 16)
hpBg.Position                    = UDim2.new(0, 8, 0, 28)
hpBg.BackgroundColor3            = Color3.fromRGB(50, 0, 0)
hpBg.BorderSizePixel             = 0
hpBg.Parent                      = hpBox
Instance.new("UICorner", hpBg).CornerRadius = UDim.new(0, 5)

local hpBar                      = Instance.new("Frame")
hpBar.Size                       = UDim2.new(1, 0, 1, 0)
hpBar.BackgroundColor3           = Color3.fromRGB(220, 40, 40)
hpBar.BorderSizePixel            = 0
hpBar.Parent                     = hpBg
Instance.new("UICorner", hpBar).CornerRadius = UDim.new(0, 5)

local function updateHP(): ()
	local char = player.Character
	if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
	TweenService:Create(hpBar, TweenInfo.new(0.2), { Size = UDim2.new(pct, 0, 1, 0) }):Play()
	hpBar.BackgroundColor3 = if pct > 0.5
		then Color3.fromRGB(220, 40, 40)
		else Color3.fromRGB(255, 110, 20)
end

-- ── Flash de dano (overlay vermelho) ─────────────────────────────────────────

local damageFlash                    = Instance.new("Frame")
damageFlash.Size                     = UDim2.new(1, 0, 1, 0)
damageFlash.BackgroundColor3         = Color3.fromRGB(200, 0, 0)
damageFlash.BackgroundTransparency   = 1
damageFlash.BorderSizePixel          = 0
damageFlash.ZIndex                   = 5
damageFlash.Parent                   = screen

local function flashDamage(): ()
	TweenService:Create(damageFlash, TweenInfo.new(0.08), { BackgroundTransparency = 0.55 }):Play()
	task.delay(0.1, function()
		TweenService:Create(damageFlash, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
	end)
end

-- ── Anúncio de onda (banner animado) ─────────────────────────────────────────

local announcement                   = Instance.new("Frame")
announcement.Size                    = UDim2.new(0, 500, 0, 80)
announcement.Position                = UDim2.new(0.5, -250, 0.3, 0)
announcement.BackgroundTransparency  = 1
announcement.ZIndex                  = 6
announcement.Visible                 = false
announcement.Parent                  = screen

local announceLbl                    = Instance.new("TextLabel")
announceLbl.Size                     = UDim2.new(1, 0, 1, 0)
announceLbl.BackgroundTransparency   = 1
announceLbl.Font                     = Enum.Font.GothamBold
announceLbl.TextSize                 = 54
announceLbl.TextColor3               = Color3.fromRGB(255, 50, 50)
announceLbl.TextStrokeColor3         = Color3.new(0, 0, 0)
announceLbl.TextStrokeTransparency   = 0.3
announceLbl.TextXAlignment           = Enum.TextXAlignment.Center
announceLbl.ZIndex                   = 7
announceLbl.Parent                   = announcement

local function showAnnouncement(text: string, color: Color3): ()
	announceLbl.Text       = text
	announceLbl.TextColor3 = color
	announcement.Visible   = true
	announceLbl.TextTransparency = 1
	TweenService:Create(announceLbl, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	task.delay(2.2, function()
		TweenService:Create(announceLbl, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.delay(0.4, function() announcement.Visible = false end)
	end)
end

-- ── Tela de vitória ───────────────────────────────────────────────────────────

local winFrame                       = Instance.new("Frame")
winFrame.Size                        = UDim2.new(1, 0, 1, 0)
winFrame.BackgroundColor3            = Color3.fromRGB(0, 0, 0)
winFrame.BackgroundTransparency      = 0.35
winFrame.Visible                     = false
winFrame.ZIndex                      = 10
winFrame.Parent                      = screen

local winLabel                       = Instance.new("TextLabel")
winLabel.Size                        = UDim2.new(1, 0, 0, 110)
winLabel.Position                    = UDim2.new(0, 0, 0.38, 0)
winLabel.BackgroundTransparency      = 1
winLabel.Text                        = "VOCÊ SOBREVIVEU"
winLabel.Font                        = Enum.Font.GothamBold
winLabel.TextSize                    = 58
winLabel.TextColor3                  = Color3.fromRGB(255, 60, 60)
winLabel.TextStrokeColor3            = Color3.new(0, 0, 0)
winLabel.TextStrokeTransparency      = 0.3
winLabel.TextXAlignment              = Enum.TextXAlignment.Center
winLabel.ZIndex                      = 11
winLabel.Parent                      = winFrame

-- ── Init ──────────────────────────────────────────────────────────────────────

function HUDController.init(): ()
	-- Vida
	local function connectHP(char: Model): ()
		local hum = char:WaitForChild("Humanoid", 5) :: Humanoid?
		if hum then
			hum:GetPropertyChangedSignal("Health"):Connect(updateHP)
			updateHP()
		end
	end
	player.CharacterAdded:Connect(connectHP)
	if player.Character then connectHP(player.Character) end

	-- Remotes
	local remotes = ReplicatedStorage:WaitForChild("Remotes")

	;(remotes:WaitForChild(RemoteNames.WAVE_START) :: RemoteEvent).OnClientEvent:Connect(function(wave: number)
		waveLabel.Text = "ONDA  " .. wave .. "  /  5"
		showAnnouncement("ONDA " .. wave, Color3.fromRGB(255, 60, 60))
	end)

	;(remotes:WaitForChild(RemoteNames.ZOMBIE_UPDATE) :: RemoteEvent).OnClientEvent:Connect(function(alive: number, total: number)
		zombieLabel.Text = alive .. " / " .. total .. "  zumbis"
	end)

	;(remotes:WaitForChild(RemoteNames.WAVE_COMPLETE) :: RemoteEvent).OnClientEvent:Connect(function(wave: number)
		if wave < 5 then
			showAnnouncement("ONDA " .. wave .. " CONCLUÍDA!", Color3.fromRGB(60, 220, 80))
		end
	end)

	;(remotes:WaitForChild(RemoteNames.PLAYER_HURT) :: RemoteEvent).OnClientEvent:Connect(function(_dmg: number)
		flashDamage()
	end)

	;(remotes:WaitForChild(RemoteNames.GAME_WON) :: RemoteEvent).OnClientEvent:Connect(function()
		winFrame.Visible = true
	end)

	print("[HUDController] Inicializado.")
end

return HUDController
