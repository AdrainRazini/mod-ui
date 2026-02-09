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
-- Global Mod Registry (Executor Memory)
-- ==========================================
local genv = getgenv()

genv.__MODS__ = genv.__MODS__ or {}
genv.__MODS__.TheApocalypse = genv.__MODS__.TheApocalypse or {
	Loaded = false,
	Version = ModInfo.Version,
	Cache = {}
}

local MOD = genv.__MODS__.TheApocalypse

-- evita double inject
if MOD.Loaded then
	warn("[⚠️ Mod Loader] The Apocalypse já está carregado")
	return
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
-- Critical failure -- Load -- Blocked -- or -- Out of tune
-- ==========================================
if not Regui then
	warn("[❌ Mod Loader] Falha crítica: Regui não carregado")
	return
end


-- ==========================================
-- Avoid interface clones.
-- ==========================================

if PlayerGui:FindFirstChild(GuiName) then
	Regui.Notifications(PlayerGui, {Title="Alert", Text="Neutralized Code", Icon="fa_rr_information", Tempo=10})
	return
end


--===================--
-- Window Guis Tabs --
-- ⬇ ⬇ ⬇ ⬇ ⬇ ⬇ ⬇ ⬇
--===================--
-- GUI
Window = Regui.TabsWindow({Title=GuiName, Text= ModInfo.Name, Size=UDim2.new(0, 350, 0, 250), Icon_btn = true})

-- Tabs
StandardTab = Regui.CreateTab(Window,{Name="Standard"})
FarmTab = Regui.CreateTab(Window,{Name="Farm"})
GameTab = Regui.CreateTab(Window,{Name="Game"})
AfkTab = Regui.CreateTab(Window,{Name="Afk Mod"})
ConfigsTab = Regui.CreateTab(Window,{Name="Configs"})
ReadmeTab = Regui.CreateTab(Window,{Name="Readme"})

-- Especial Tab
local Credits = Regui.CreditsUi(ReadmeTab, { Alignment = "Center", Alignment_Texts = "Left"}, function() end)
--===================--

--================================================
-- Locals -- Memory
--================================================
local Cache = {}

--[[
local AF = {}
local AF_Timer = {}
local PVP = {}
local PVP_Timer = {}
]]

--================================================
-- Using -- Dynamic Creation -- Current Version of the Memory Library
--================================================

-- 
--================================================
-- Notification Helper
--================================================
function Notification(Title, Text, Tempo, Icon)
	Title = Title or "Null"
	Text  = Text  or "Null"
	Tempo = Tempo or 1
	Icon  = Icon  or "fa_envelope"

	local OldGui = (Window and Window.Frame and Window.Frame.Parent) or PlayerGui

	Regui.NotificationPerson(OldGui, {
		Title = Title,
		Text  = Text,
		Tempo = Tempo,
		Icon  = Icon
	})
end


-- Add a label
Regui.CreateLabel(StandardTab, {
	Text = "Welcome to Regui!",
	Color = "White",
	Alignment = "Center"
})


local OptionsStrings = Regui.CreateSelectorOpitions(StandardTab, {
	Name = "Selector",
	Alignment = "Center",
	Size_Frame = UDim2.new(1,-10,0,50),
	Frame_Max = 50,
	Options = {

		"On",
		"Off"

	},

	Type = "String"
}, function(val)
	print("Você escolheu:", val)
end)

local OptionsInstance = Regui.CreateSelectorOpitions(StandardTab, {
	Name = "Selector",
	Alignment = "Center",
	Size_Frame = UDim2.new(1,-10,0,50),
	Frame_Max = 50,
	Options = {

		{name = "Name", Obj = "Parent"},
		
	},

	Type = "Instance"
}, function(val)
	print("Você escolheu:", val)
end)

-- Add a button
Regui.CreateButton(StandardTab, {
	Text = "Click Me",
	Color = "White",
	BGColor = "Blue"
}, function()
	print("Button clicked!")

	Notification(
		"Hello!",
		"You clicked the button!",
		3,
		"fa_envelope"
	)
end)

-- Add a toggle
Regui.CreateToggleboxe(StandardTab, {
	Text = "Enable Feature",
	Color = "Green"
}, function(state)
	print("Toggle state:", state)
end)

-- Add a checkbox
Regui.CreateCheckboxe(StandardTab, {
	Text = "Extra Option",
	Color = "Yellow"
}, function(state)
	print("Checkbox state:", state)
end)

-- Add a slider
Regui.CreateSliderInt(StandardTab, {
	Text = "Speed",
	Minimum = 1,
	Maximum = 10,
	Value = 5
}, function(value)
	print("Slider value:", value)
end)