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

	-- Espaçamento e tamanho: rodam sempre, independente de Templates.
	local cfg: any = S.MAIN_MENU

	-- Busca UIGridLayout em qualquer lugar do ScreenGui (não depende de nomes específicos)
	local gridLayout = gui:FindFirstChildWhichIsA("UIGridLayout", true)
	if gridLayout then
		local pad = cfg.cell_padding or 4
		gridLayout.CellPadding = UDim2.new(0, pad, 0, pad)
	end

	-- Tamanho do painel principal (primeiro Frame filho do ScreenGui)
	if cfg.panel_size then
		local mfAny = gui:FindFirstChildWhichIsA("Frame") :: Frame?
		if mfAny then
			mfAny.Size = cfg.panel_size
		end
	end

	local mf = gui:FindFirstChild("MenuFrame") :: Frame?
	if not mf then return end

	-- Se não tiver pasta Templates, modo hardcoded: apenas ajustes acima são aplicados.
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
	end

	-- Grid de botões
	for i, def in cfg.buttons do
		local clone = btnMaster:Clone()
		populateButton(clone, def, i)
		clone.Parent = grid
	end

	-- Remove a pasta Templates do PlayerGui (clones já saíram)
	templates:Destroy()
end

return MainMenu
