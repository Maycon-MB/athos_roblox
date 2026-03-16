--!strict

local Players = game:GetService("Players")
local player  = Players.LocalPlayer

local CharacterController = {}

local function applyTheme(character: Model): ()
	character:WaitForChild("Humanoid", 10)
	task.wait(1)

	for _, item in character:GetChildren() do
		if item:IsA("Shirt") or item:IsA("Pants")
			or item:IsA("ShirtGraphic") or item:IsA("Accessory") then
			item:Destroy()
		end
	end

	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") and desc.Name ~= "HumanoidRootPart" then
			desc.Color    = Color3.fromRGB(15, 15, 15)
			desc.Material = Enum.Material.SmoothPlastic
		end
		if desc:IsA("Decal") then desc:Destroy() end
	end

	local head = character:FindFirstChild("Head") :: BasePart?
	if head then
		local glow      = Instance.new("PointLight")
		glow.Color      = Color3.fromRGB(255, 0, 0)
		glow.Brightness = 3
		glow.Range      = 10
		glow.Parent     = head
	end

	for _, name in { "Right Arm", "Left Arm", "RightHand", "LeftHand" } do
		local limb = character:FindFirstChild(name) :: BasePart?
		if not limb then continue end
		local fire          = Instance.new("Fire")
		fire.Size           = 2
		fire.Heat           = 5
		fire.Color          = Color3.fromRGB(255, 80, 0)
		fire.SecondaryColor = Color3.fromRGB(255, 220, 0)
		fire.Parent         = limb
	end
end

function CharacterController.init(): ()
	player.CharacterAdded:Connect(function(char) task.spawn(applyTheme, char) end)
	if player.Character then task.spawn(applyTheme, player.Character) end
	print("[CharacterController] Inicializado.")
end

return CharacterController
