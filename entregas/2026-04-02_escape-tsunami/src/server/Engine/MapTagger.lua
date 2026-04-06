--!strict
-- MapTagger: aplica tags do CollectionService em peças do Workspace.
-- 1) Por nome exato (Settings.TAG_MAP)
-- 2) Auto-detecção de água dentro de qualquer Model/Folder chamado "DefaultMap"
--    por nome comum OU por propriedades (grande + azulada/transparente)
local CollectionService = game:GetService("CollectionService")
local MapTagger = {}

-- Nomes considerados "água" na busca automática (case-insensitive)
local WATER_NAMES = {
	"water","ocean","sea","wave","tsunami","flood","river","lake",
	"tide","surge","aqua","liquid","lava","magma","slime",
}

-- Retorna true se a cor for predominantemente azul/ciano
local function isBlueish(col: Color3): boolean
	-- Azul > Vermelho e Azul > Verde com margem mínima
	return col.B > 0.35 and col.B > col.R + 0.12 and col.B > col.G - 0.15
end

-- Retorna true se a cor for verde-água / ciano
local function isCyanish(col: Color3): boolean
	return col.G > 0.4 and col.B > 0.4 and col.R < 0.35
end

-- Heurística: BasePart grande E (azul/ciano OU semitransparente)
local function looksLikeWater(part: BasePart): boolean
	local s   = part.Size
	local big = s.X * s.Z > 300 or s.X > 25 or s.Z > 25          -- área grande
	local col = part.Color
	local blueLike  = isBlueish(col) or isCyanish(col)
	local seeThrough = part.Transparency >= 0.15 and part.Transparency < 0.95
	return big and (blueLike or seeThrough)
end

local function tagWater(part: BasePart, reason: string)
	if CollectionService:HasTag(part, "Tsunami") then return end
	CollectionService:AddTag(part, "Tsunami")
	print(string.format("[MapTagger] AUTO-WATER '%s' (%s)", part.Name, reason))
end

-- Palavras obrigatórias no nome para detecção heurística de água.
-- Exigir nome E propriedades evita falsos positivos em pisos transparentes.
local HEURISTIC_NAMES = { "water", "wave", "sea", "oceano" }

-- Auto-detecção DESATIVADA: estava causando falsos positivos no chão.
-- Reative quando o mapa tiver peças de água com nomes e transparência confirmados.
local function autoDetectWater(_container: Instance)
	return
	-- luacheck: ignore (código de referência abaixo)
	for _, obj in ({} :: any) do
		if not obj:IsA("BasePart") then continue end
		local part = obj :: BasePart

		-- 1) Nome comum (lista ampla) → tagueia independente de propriedades
		local nameLower = part.Name:lower()
		for _, wname in WATER_NAMES do
			if nameLower:find(wname, 1, true) then
				tagWater(part, "nome: " .. part.Name)
				break
			end
		end

		-- 2) Heurística por propriedades — EXIGE nome com palavra de água
		-- (evita taguear pisos grandes/transparentes como chão de mapa)
		if not CollectionService:HasTag(part, "Tsunami") and looksLikeWater(part) then
			local hasWaterName = false
			for _, wname in HEURISTIC_NAMES do
				if nameLower:find(wname, 1, true) then hasWaterName = true; break end
			end
			if hasWaterName then
				tagWater(part, string.format(
					"prop+nome: size=%.0fx%.0f transp=%.2f",
					part.Size.X, part.Size.Z, part.Transparency
				))
			end
		end
	end
end

function MapTagger.init(tagMap: { [string]: { string } })
	local ws = game:GetService("Workspace")
	local resolvedTagMap: { [string]: { string } } = tagMap or {}

	-- ── Passo 1: tag por nome exato (Settings.TAG_MAP) ───────────────────────
	-- "Spawn" → GameSpawn sempre embutido, independente do Settings.TAG_MAP
	local function tryTag(obj: Instance)
		if obj.Name == "Spawn" then
			CollectionService:AddTag(obj, "GameSpawn")
		end
		for tag, names in resolvedTagMap do
			for _, name in names do
				if obj.Name == name then
					CollectionService:AddTag(obj, tag)
				end
			end
		end
	end

	for _, obj in ws:GetDescendants() do tryTag(obj) end
	ws.DescendantAdded:Connect(tryTag)

	-- ── Passo 2: auto-detecção de água dentro de DefaultMap ──────────────────
	local defaultMap = ws:FindFirstChild("DefaultMap")
	if defaultMap then
		autoDetectWater(defaultMap)
	else
		-- Tenta qualquer Model/Folder no Workspace que pareça um mapa importado
		for _, child in ws:GetChildren() do
			if child:IsA("Model") or child:IsA("Folder") then
				if child.Name ~= "Camera" and child.Name ~= "Terrain" then
					autoDetectWater(child)
				end
			end
		end
	end

	-- ── Passo 3: relatório + fallback de diagnóstico ──────────────────────────
	for tag in resolvedTagMap do
		local n = #CollectionService:GetTagged(tag)
		print(string.format("[MapTagger] '%s' → %d objeto(s)", tag, n))
	end

	-- Se ainda não encontrou água, imprime script de diagnóstico no Output
	if #CollectionService:GetTagged("Tsunami") == 0 then
		warn("[MapTagger] Nenhuma peça de água encontrada automaticamente.")
		warn("[MapTagger] Cole o comando abaixo no Command Bar do Studio para listar candidatos:")
		print([[
---- COLE NO COMMAND BAR (Studio > View > Command Bar) ----
local results = {}
for _, obj in workspace:GetDescendants() do
    if obj:IsA("BasePart") then
        local s = obj.Size
        table.insert(results, string.format(
            "Nome='%s'  Size=%.0fx%.0fx%.0f  Color=(%.2f,%.2f,%.2f)  Transp=%.2f  Parent='%s'",
            obj.Name, s.X, s.Y, s.Z,
            obj.Color.R, obj.Color.G, obj.Color.B,
            obj.Transparency, obj.Parent and obj.Parent.Name or "?"
        ))
    end
end
table.sort(results)
for _, r in results do print(r) end
print("Total de BaseParts:", #results)
---- FIM DO SCRIPT ----]])
	end
end

return MapTagger
