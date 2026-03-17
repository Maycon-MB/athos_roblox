--!strict

local workspace = game:GetService("Workspace")

local FolderService = {}

local _folders: { [string]: Folder } = {}

local FOLDER_NAMES = { "Environment", "Structures", "Borders", "Gameplay" }

-- Cria (ou recria) as pastas organizacionais no workspace
function FolderService.init(): ()
	for _, name in FOLDER_NAMES do
		-- Remove versão antiga se existir (idempotente ao reiniciar servidor)
		local existing = workspace:FindFirstChild(name)
		if existing then existing:Destroy() end

		local folder  = Instance.new("Folder")
		folder.Name   = name
		folder.Parent = workspace
		_folders[name] = folder
	end
	print("[FolderService] Pastas criadas: " .. table.concat(FOLDER_NAMES, ", "))
end

-- Retorna a pasta pelo nome; lança erro se não existir
function FolderService.get(name: string): Folder
	return assert(_folders[name], "[FolderService] Pasta não encontrada: " .. name)
end

return FolderService
