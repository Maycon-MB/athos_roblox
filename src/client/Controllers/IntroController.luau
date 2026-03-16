--!strict

local Players           = game:GetService("Players")
local TweenService      = game:GetService("TweenService")
local UserInputService  = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteNames"))

local player    = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local IntroController = {}

local function tw(obj: Instance, props: { [string]: any }, t: number): ()
	TweenService:Create(obj :: any, TweenInfo.new(t, Enum.EasingStyle.Sine), props):Play()
end

function IntroController.init(): ()
	local screen              = Instance.new("ScreenGui")
	screen.Name               = "IntroScreen"
	screen.ResetOnSpawn       = false
	screen.DisplayOrder       = 99
	screen.Parent             = playerGui

	local bg                  = Instance.new("Frame")
	bg.Size                   = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3       = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 0
	bg.BorderSizePixel        = 0
	bg.Parent                 = screen

	-- Título principal
	local title               = Instance.new("TextLabel")
	title.Size                = UDim2.new(1, 0, 0, 100)
	title.Position            = UDim2.new(0, 0, 0.3, 0)
	title.BackgroundTransparency = 1
	title.Text                = "ATHOS"
	title.Font                = Enum.Font.GothamBold
	title.TextSize            = 88
	title.TextColor3          = Color3.fromRGB(220, 30, 30)
	title.TextTransparency    = 1
	title.TextStrokeColor3    = Color3.new(0, 0, 0)
	title.TextStrokeTransparency = 0.4
	title.TextXAlignment      = Enum.TextXAlignment.Center
	title.Parent              = bg

	-- Subtítulo "SURVIVAL"
	local sub2                = Instance.new("TextLabel")
	sub2.Size                 = UDim2.new(1, 0, 0, 40)
	sub2.Position             = UDim2.new(0, 0, 0.48, 0)
	sub2.BackgroundTransparency = 1
	sub2.Text                 = "S U R V I V A L"
	sub2.Font                 = Enum.Font.GothamBold
	sub2.TextSize             = 26
	sub2.TextColor3           = Color3.fromRGB(180, 40, 40)
	sub2.TextTransparency     = 1
	sub2.TextXAlignment       = Enum.TextXAlignment.Center
	sub2.Parent               = bg

	-- Linha decorativa
	local line                = Instance.new("Frame")
	line.Size                 = UDim2.new(0, 0, 0, 2)
	line.Position             = UDim2.new(0.5, 0, 0.555, 0)
	line.AnchorPoint          = Vector2.new(0.5, 0.5)
	line.BackgroundColor3     = Color3.fromRGB(180, 30, 30)
	line.BorderSizePixel      = 0
	line.Parent               = bg

	-- Instrução
	local hint                = Instance.new("TextLabel")
	hint.Size                 = UDim2.new(1, 0, 0, 36)
	hint.Position             = UDim2.new(0, 0, 0.6, 0)
	hint.BackgroundTransparency = 1
	hint.Text                 = "Pressione qualquer tecla para entrar"
	hint.Font                 = Enum.Font.Gotham
	hint.TextSize             = 20
	hint.TextColor3           = Color3.fromRGB(190, 190, 190)
	hint.TextTransparency     = 1
	hint.TextXAlignment       = Enum.TextXAlignment.Center
	hint.Parent               = bg

	-- Crédito
	local credit              = Instance.new("TextLabel")
	credit.Size               = UDim2.new(1, 0, 0, 26)
	credit.Position           = UDim2.new(0, 0, 0.9, 0)
	credit.BackgroundTransparency = 1
	credit.Text               = "dev: Maycon Bruno  •  Athos SG"
	credit.Font               = Enum.Font.Gotham
	credit.TextSize           = 15
	credit.TextColor3         = Color3.fromRGB(100, 100, 100)
	credit.TextTransparency   = 1
	credit.TextXAlignment     = Enum.TextXAlignment.Center
	credit.Parent             = bg

	-- Fade in sequencial
	task.wait(0.5)
	tw(title,  { TextTransparency = 0 }, 1.2)
	task.wait(0.9)
	tw(sub2,   { TextTransparency = 0 }, 0.7)
	task.wait(0.5)
	tw(line,   { Size = UDim2.new(0, 320, 0, 2) }, 0.6)
	task.wait(0.5)
	tw(hint,   { TextTransparency = 0 }, 0.8)
	task.wait(0.4)
	tw(credit, { TextTransparency = 0 }, 0.8)

	local dismissed = false
	local conn: RBXScriptConnection

	local function dismiss(): ()
		if dismissed then return end
		dismissed = true
		conn:Disconnect()

		for _ = 1, 3 do
			tw(hint, { TextTransparency = 1 }, 0.15); task.wait(0.2)
			tw(hint, { TextTransparency = 0 }, 0.15); task.wait(0.2)
		end

		tw(bg,     { BackgroundTransparency = 1 }, 1.4)
		tw(title,  { TextTransparency = 1 }, 1.0)
		tw(sub2,   { TextTransparency = 1 }, 1.0)
		tw(line,   { BackgroundTransparency = 1 }, 1.0)
		tw(hint,   { TextTransparency = 1 }, 1.0)
		tw(credit, { TextTransparency = 1 }, 1.0)
		task.wait(1.5)
		screen:Destroy()

		local remotes   = ReplicatedStorage:WaitForChild("Remotes")
		local introDone = remotes:FindFirstChild(RemoteNames.INTRO_DONE) :: RemoteEvent?
		if introDone then introDone:FireServer() end
	end

	conn = UserInputService.InputBegan:Connect(function(_: InputObject, processed: boolean)
		if not processed then task.spawn(dismiss) end
	end)

	print("[IntroController] Inicializado.")
end

return IntroController
