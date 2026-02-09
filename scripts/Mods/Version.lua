-- Mods/Folders/scripts-modules
-- Manifest do Mod: The Apocalypse

local Version = {
	Name = "The Apocalypse",
	Id = "the_apocalypse",

	Version = "1.0.0",
	Build = 1,

	Author = "Adrian Razini",
	Date = "2026-02-08",

	-- Compatibilidade
	GameId = 75519253084635,
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
		RemoteVersionUrl = "https://animal-simulator-server.vercel.app/mods/the_apocalypse/version",
		RemoteScriptUrl  = "https://animal-simulator-server.vercel.app/mods/the_apocalypse/main.lua"
	},

	-- Meta
	Description = "Mode Menu for The Apocalypse",
	Tags = { "farm", "gui", "automation" }
}

return Version
