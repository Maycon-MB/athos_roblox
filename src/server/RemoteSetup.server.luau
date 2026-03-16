--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("RemoteNames"))

local folder  = Instance.new("Folder")
folder.Name   = "Remotes"
folder.Parent = ReplicatedStorage

for _, name in RemoteNames do
	local e        = Instance.new("RemoteEvent")
	e.Name         = name
	e.Parent       = folder
end

print("[RemoteSetup] Remotes criados.")
