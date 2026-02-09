-- ==========================================
-- The Apocalypse: Verific Game 
-- ==========================================
-- Meta dados
local ModInfo = {
	Name = "The Apocalypse",
	Version = "1.0.0", -- versão atual
	Date = "2026-02-08",
    GameId = 75519253084635,
	Notes = "Mode Menu"
}

-- AutoExec: só roda no jogo ID  
if game.PlaceId ~= ModInfo.GameId then
	return -- sai se não for o jogo certo
end

-- ==========================================
-- The Apocalypse: Global Services
-- ==========================================

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")

-- ==========================================
-- The Apocalypse: External Services
-- ==========================================



-- ==========================================
-- The Apocalypse: Upload Library
-- ==========================================

local Regui
local player = Players.LocalPlayer
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local GuiName = "Mod_The_Apocalypse_" .. game.Players.LocalPlayer.Name

-- ==========================================
-- Remote Sources
-- ==========================================
local URLS = {
	Github = "https://raw.githubusercontent.com/AdrainRazini/mastermod/refs/heads/main/module/dataGui.lua",
	Vercel = "https://animal-simulator-server.vercel.app/lua/DataGui.lua"
}

-- ==========================================
-- Tenta carregar localmente
-- ==========================================
local success, module = pcall(function()
	local mod = script.Parent and script.Parent:FindFirstChild("Mod_UI")
	if mod then
		return require(mod)
	end
end)

if success and module then
	Regui = module
	print("[✅ Mod Loader] Carregado localmente com sucesso!")
else
	-- ==========================================
	-- 2️⃣ Tenta baixar remoto
	-- ==========================================
	local code

	for source, url in pairs(URLS) do
		local okHttp, result = pcall(function()
			return game:HttpGet(url)
		end)

		if okHttp and type(result) == "string" and result ~= "" then
			code = result
			print("[🌐 Mod Loader] Código baixado de:", source)
			break
		else
			warn("[⚠️ Mod Loader] Falha ao baixar de:", source)
		end
	end

	-- ==========================================
	-- Executa o código remoto
	-- ==========================================
	if code then
		local okLoad, fn = pcall(loadstring, code)

		if okLoad and type(fn) == "function" then
			local okRun, result = pcall(fn)
			if okRun and result then
				Regui = result
				print("[✅ Mod Loader] Módulo remoto carregado com sucesso!")
			else
				warn("[❌ Mod Loader] Erro ao executar módulo remoto:", result)
			end
		else
			warn("[❌ Mod Loader] Código remoto inválido")
		end
	else
		warn("[❌ Mod Loader] Nenhuma das fontes pôde ser carregada.")
	end
end

-- ==========================================
-- Falha crítica
-- ==========================================
if not Regui then
	warn("[❌ Mod Loader] Falha crítica: Regui não carregado")
	return
end


--===================--
-- Window Guis Tabs --
-- ⬇ ⬇ ⬇ ⬇ ⬇ ⬇ ⬇ ⬇
--===================--
-- GUI
Window = Regui.TabsWindow({Title=GuiName, Text="Animal Simulator", Size=UDim2.new(0, 350, 0, 250), Icon_btn = true})

-- Tabs
FarmTab = Regui.CreateTab(Window,{Name="Farm"})
GameTab = Regui.CreateTab(Window,{Name="Game"})
AfkTab = Regui.CreateTab(Window,{Name="Afk Mod"})
ConfigsTab = Regui.CreateTab(Window,{Name="Configs"})
ReadmeTab = Regui.CreateTab(Window,{Name="Readme"})

-- Especial Tab
local Credits = Regui.CreditsUi(ReadmeTab, { Alignment = "Center", Alignment_Texts = "Left"}, function() end)
--===================--