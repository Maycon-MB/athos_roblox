--!strict

-- Módulo 6 — Imersão: câmera cinematográfica ao nascer
-- Varredura panorâmica do hub antes de devolver o controle ao jogador

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CinematicController = {}

-- Posição central do hub (ponto focal da câmera)
local HUB_CENTER = Vector3.new(0, 10, 0)

local function playCinematic(): ()
	task.wait(0.35)  -- SpawnService posiciona o personagem primeiro

	local char = player.Character
	if not char then return end
	local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	-- Trava câmera para controle scriptado
	camera.CameraType = Enum.CameraType.Scriptable

	-- Fase 1: panorâmica alta — revela o mapa completo ao jogador
	local cf1 = CFrame.lookAt(Vector3.new(-82, 62, -82), HUB_CENTER)
	-- Fase 2: aproximação lateral — destaca leaderboard e estruturas
	local cf2 = CFrame.lookAt(Vector3.new(-48, 32, -68), HUB_CENTER)
	-- Fase 3: nível do jogador — sensação de "entrar" no hub
	local cf3 = CFrame.lookAt(Vector3.new(-18, 16, -52), HUB_CENTER)

	camera.CFrame = cf1

	local sweep = TweenInfo.new(2.4, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local enter = TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)

	local t1 = TweenService:Create(camera, sweep, { CFrame = cf2 })
	local t2 = TweenService:Create(camera, enter, { CFrame = cf3 })

	t1:Play()
	t1.Completed:Wait()
	t2:Play()
	t2.Completed:Wait()

	-- Devolve câmera ao sistema padrão do Roblox
	camera.CameraType = Enum.CameraType.Custom
end

function CinematicController.init(): ()
	local function onCharAdded(char: Model): ()
		char:WaitForChild("HumanoidRootPart", 10)
		task.spawn(playCinematic)
	end

	player.CharacterAdded:Connect(onCharAdded)

	-- Personagem já carregado (primeiro spawn)
	if player.Character then
		task.spawn(onCharAdded, player.Character)
	end

	print("[CinematicController] Pronto.")
end

return CinematicController
