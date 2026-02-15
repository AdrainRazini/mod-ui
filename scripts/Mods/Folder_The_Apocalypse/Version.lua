-- Mods/Folder_The_Apocalypse/Version.lua
-- Manifest do Mod: The Apocalypse

local Version = {
	Name = "The Apocalypse",
	Id = "the_apocalypse",

	Version = "1.1.0",
	Build = 1,

	Author = "Adrian Razini",
	Date = "2026-02-08",

    -- IDs de Jogo
	UniverseId = 7009714292,          -- game.GameId
	MainPlaceId = 75519253084635,     -- place principal
	SubPlaces = {                     -- sub-places permitidos
		122160128185618,
	},
    
    -- Compatibilidade
	Executor = { "Delta", "Fluxus", "Arceus" },

	-- Loader flags
	Enabled = true,
	AutoExec = true,

	-- Entry point do mod
	Entry = "The_Apocalypse.lua",

	-- Pasta principal
	Folder = "Folder_The_Apocalypse",

	-- Update / Remote
	Update = {
		Channel = "stable",
		RemoteVersionUrl = "...",
		RemoteScriptUrl  = "..."
	},

	-- Meta
	Description = "Mode Menu for The Apocalypse",
	Tags = { "farm", "gui", "automation" }
}

return Version

--[[

local version = require(script.Parent.Mods.Version)

if not version.Enabled then
	return
end

if version.GameId ~= game.PlaceId then
	return
end

-- carregar entrypoint
local entry = script.Parent.Mods:FindFirstChild(version.Entry)
if entry then
	loadfile(entry)()
end

]]