--!strict
-- MainMenu — consome template editado no Studio (StarterGui.MainMenuOptions).
-- Clona Templates.ButtonTemplate × N e Templates.AdminTemplate × 1.
-- Config em Settings.MAIN_MENU. Iteração visual = 100% no Studio.
--
-- Hierarquia esperada:
--   ScreenGui "MainMenuOptions"
--     MenuFrame
--       AdminSlot (recebe clone de AdminTemplate)
--       Grid (UIGridLayout, recebe clones de ButtonTemplate)
--     Templates
--       ButtonTemplate (invisível — clonado N vezes)
--       AdminTemplate (invisível — clonado 1 vez)
--
-- CardTemplate descendants obrigatórios (nomes):
--   Icon (ImageLabel)
--   Label (TextLabel)
--   InnerBorder (Frame com UIStroke) — toggle visibility via stroke.Transparency
--   NewBadge (TextLabel) — Visible controlado aqui
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local MainMenu = {}

local player = Players.LocalPlayer
local S      = require(RS.Shared.Settings)

local function populateButton(btn: GuiObject, def: any, order: number)
	btn.Name = def.id .. "Button"
	(btn :: any).LayoutOrder = order
	btn.Visible = true

	local icon = btn:FindFirstChild("Icon", true) :: ImageLabel?
	if icon and def.icon and def.icon ~= "" then
		icon.Image = def.icon
	end

	local label = btn:FindFirstChild("Label", true) :: TextLabel?
	if label then
		label.Text      = def.label or def.id
		label.TextColor3 = if def.novelty
			then Color3.fromRGB(255, 200, 0)
			else Color3.fromRGB(255, 255, 255)
	end

	local inner = btn:FindFirstChild("InnerBorder") :: Frame?
	if inner then
		local stk = inner:FindFirstChildWhichIsA("UIStroke")
		if stk then
			stk.Color        = if def.novelty
				then Color3.fromRGB(255, 200, 0)
				else Color3.fromRGB(180, 180, 180)
			stk.Transparency = 0
		end
	end

	local newBadge = btn:FindFirstChild("NewBadge") :: TextLabel?
	if newBadge then
		newBadge.Visible = def.novelty == true
	end
end

function MainMenu.init()
	local playerGui = player:WaitForChild("PlayerGui")
	local gui = playerGui:WaitForChild("MainMenuOptions", 10)
	if not gui or not gui:IsA("ScreenGui") then
		warn("[MainMenu] MainMenuOptions não encontrado em PlayerGui")
		return
	end

	local cfg: any = S.MAIN_MENU

	-- Estilização dos botões hardcoded (Label + InnerBorder)
	-- AdminButton tem RainbowAnim → não toca no InnerBorder dele
	-- StoreButton tem NewBadge → novelty (amarelo); demais → branco/cinza
	local YELLOW = Color3.fromRGB(255, 200, 0)
	local WHITE  = Color3.fromRGB(255, 255, 255)
	local GRAY   = Color3.fromRGB(180, 180, 180)

	for _, btn in gui:GetDescendants() do
		if btn:IsA("TextButton") then
			local isNovelty = btn:FindFirstChild("NewBadge", true) ~= nil

			local lbl = btn:FindFirstChild("Label") :: TextLabel?
			if lbl then
				lbl.TextColor3 = if isNovelty then YELLOW else WHITE
			end

			local ib = btn:FindFirstChild("InnerBorder") :: Frame?
			if ib and not ib:FindFirstChild("RainbowAnim") then
				local stk = ib:FindFirstChildWhichIsA("UIStroke")
				if stk then
					stk.Color        = if isNovelty then YELLOW else GRAY
					stk.Transparency = 0
				end
			end
		end
	end

	local mf = gui:FindFirstChild("MenuFrame") :: Frame?
	if not mf then return end

	-- AdminButton já existe direto em MenuFrame neste place (não via Templates clone).
	-- Conecta o click → toggle do AdminPanel (substitui o atalho F8).
	local existingAdmin = mf:FindFirstChild("AdminButton")
	if existingAdmin and existingAdmin:IsA("GuiButton") then
		local AdminPanel = require(script.Parent:WaitForChild("AdminPanel"))
		;(existingAdmin :: GuiButton).MouseButton1Click:Connect(function()
			AdminPanel.toggle()
		end)
	end

	-- Modo hardcoded sem Templates: estilização aplicada, clonagem não ocorre.
	local templates = gui:FindFirstChild("Templates")
	if not templates then return end

	local btnTmpl  = templates:FindFirstChild("ButtonTemplate") :: GuiObject?
	local adminTmpl = templates:FindFirstChild("AdminTemplate") :: GuiObject?
	local adminSlot = mf:FindFirstChild("AdminSlot") :: Frame?
	local grid     = mf:FindFirstChild("Grid") :: Frame?
	if not (btnTmpl and adminTmpl and adminSlot and grid) then return end

	-- Clona fora de Templates antes de remover a pasta
	local btnMaster = btnTmpl:Clone()
	local adminMaster = adminTmpl:Clone()

	-- Admin no topo
	if cfg.admin and cfg.admin.enabled then
		local clone = adminMaster:Clone()
		clone.Name = "AdminButton"
		clone.Visible = true
		local ic = clone:FindFirstChild("Icon", true) :: ImageLabel?
		if ic and cfg.admin.icon then ic.Image = cfg.admin.icon end
		local lb = clone:FindFirstChild("Label", true) :: TextLabel?
		if lb then lb.Text = cfg.admin.label or "ADMIN" end
		clone.Parent = adminSlot

		-- Conecta click → toggle do AdminPanel (substitui o atalho F8)
		local AdminPanel = require(script.Parent:WaitForChild("AdminPanel"))
		local clickTarget = clone:IsA("GuiButton") and clone
			or clone:FindFirstChildWhichIsA("GuiButton", true)
		if clickTarget then
			(clickTarget :: GuiButton).MouseButton1Click:Connect(function()
				AdminPanel.toggle()
			end)
		else
			warn("[MainMenu] AdminTemplate sem GuiButton clicável")
		end
	end

	-- Grid de botões
	for i, def in cfg.buttons do
		local clone = btnMaster:Clone()
		populateButton(clone, def, i)
		clone.Parent = grid
	end

	-- Remove a pasta Templates do PlayerGui (clones já saíram)
	templates:Destroy()

	-- ── Botão Slow Mode — abaixo do grid, sempre visível ─────────────
	local SLOW_GREEN = Color3.fromRGB(87, 200, 80)
	local SLOW_RED   = Color3.fromRGB(190, 55, 55)

	local slowOn = false
	local slowBtn = Instance.new("TextButton")
	slowBtn.Name             = "SlowModeBtn"
	slowBtn.Size             = UDim2.new(1, 0, 0, 36)
	slowBtn.LayoutOrder      = 999
	slowBtn.BackgroundColor3 = SLOW_GREEN
	slowBtn.BorderSizePixel  = 0
	slowBtn.Font             = Enum.Font.GothamBold
	slowBtn.TextScaled       = true
	slowBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
	slowBtn.Text             = "Slow Mode: OFF"
	slowBtn.AutoButtonColor  = true
	slowBtn.Parent           = mf
	local sc = Instance.new("UICorner"); sc.CornerRadius = UDim.new(0, 6); sc.Parent = slowBtn

	local function updateSlowBtn()
		slowBtn.Text             = if slowOn then "Slow Mode: ON" else "Slow Mode: OFF"
		slowBtn.BackgroundColor3 = if slowOn then SLOW_GREEN else SLOW_RED
	end

	local R2 = require(RS.Shared.Remotes)
	local cmdRem  = RS:WaitForChild(R2.AdminCmd)  :: RemoteEvent
	local respRem = RS:WaitForChild(R2.AdminResp) :: RemoteEvent

	slowBtn.MouseButton1Click:Connect(function()
		cmdRem:FireServer("slow_motion", "")
	end)
	respRem.OnClientEvent:Connect(function(kind: string, msg: string?)
		if kind == "slow_state" then
			slowOn = (msg == "ON")
			updateSlowBtn()
		end
	end)
end

return MainMenu
