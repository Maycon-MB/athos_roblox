--!strict

local Lighting = game:GetService("Lighting")

local LightingService = {}

-- Configura iluminação natural para hub world (sem saturação cyberpunk)
function LightingService.init(): ()
	-- Limpa efeitos de iluminação antigos
	for _, child in Lighting:GetChildren() do
		if child:IsA("PostEffect") or child:IsA("Atmosphere") then
			child:Destroy()
		end
	end

	-- Configuração base
	Lighting.ClockTime      = 14                          -- tarde (sol alto)
	Lighting.Brightness     = 2.0
	Lighting.Ambient        = Color3.fromRGB(100, 100, 100)
	Lighting.OutdoorAmbient = Color3.fromRGB(120, 128, 140)
	Lighting.FogEnd         = 600
	Lighting.FogColor       = Color3.fromRGB(180, 200, 220)

	-- Atmosfera suave (sem haze/glare excessivo)
	local atm           = Instance.new("Atmosphere")
	atm.Density         = 0.28
	atm.Offset          = 0.20
	atm.Color           = Color3.fromRGB(199, 199, 199)
	atm.Decay           = Color3.fromRGB(110, 120, 135)
	atm.Glare           = 0
	atm.Haze            = 0
	atm.Parent          = Lighting

	-- Bloom leve (realça neons sem machucar os olhos)
	local bloom         = Instance.new("BloomEffect")
	bloom.Intensity     = 0.35
	bloom.Size          = 18
	bloom.Threshold     = 0.92
	bloom.Parent        = Lighting

	print("[LightingService] Iluminação configurada (ShadowMap, tarde, bloom suave).")
end

return LightingService
