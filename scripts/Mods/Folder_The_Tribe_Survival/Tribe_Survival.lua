--[[@Tribe-Survival .. v 1.0]]

local Regui
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local GuiName = "Mod_The_Wanderlands_"..game.Players.LocalPlayer.Name
local camera = workspace.CurrentCamera

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local plr = game.Players.LocalPlayer
local mouse = plr:GetMouse()
local cam = workspace.CurrentCamera

-- Meta dados
local ModInfo = {
	Name = "Tribe-Survival",
	Version = "1.0.0",
	Date = "2026-04-05",

	Notes = "Mode Menu"
}

-- Tenta carregar localmente para testes
local success, module = pcall(function()
	return require(script.Parent:FindFirstChild("Mod_UI")) -- Teste localmente ou em StarterGui
end)

if success and module then
	Regui = module
else
	-- Tenta baixar remoto
	local HttpService = game:GetService("HttpService")
	local ok, err = pcall(function()
		local code = game:HttpGet("https://mod-ui.vercel.app/api/Core/Mod_UI") -- Meu Servidor Api Git UI
		Regui = loadstring(code)()
	end)

	if not ok then
		warn("Não foi possível carregar Mod_UI nem local nem remoto!", err)
	end
end

assert(Regui, "Regui não foi carregado!")


-- Evita múltiplas GUIs
if PlayerGui:FindFirstChild(GuiName) then
	Regui.Notifications(PlayerGui, {
		Title = "Alert",
		Text = "Neutralized Code",
		Icon = "fa_rr_information",
		Tempo = 10
	})
	return
end



-- =========================
-- 🧠 HELPERS UI
-- =========================
local function CreateLabel(tab, text, color, size, alignment)
	return  Regui.CreateLabel(tab, {
		Text = text or "Loading...",
		Color = color or "White",
		Size = size or UDim2.new(1, -10, 0, 25),
		Alignment = alignment or"Left"
	})
end

local function CreateSlider(tab, text, value, min, max, callback)
	return Regui.CreateSliderInt(tab, {
		Text = text,
		Color = "Blue",
		Value = value,
		Minimum = min,
		Maximum = max
	}, callback)
end

local function CreateToggle(tab, text, callback)
	return Regui.CreateCheckboxe(tab, {
		Text = text,
		Color = "Blue"
	}, callback)
end

local function CreateSelector(tab, name, options, callback)
	return Regui.CreateSelectorOpitions(tab, {
		Name = name,
		Alignment = "Center",
		Size_Frame = UDim2.new(1, -10, 0, 100),
		Options = options,
		Frame_Max = 50,
		Type = "String"
	}, callback)
end

--Notify
local function Notify(Title, text, icon, tempo)
	Regui.NotificationPerson(Window.Frame.Parent, {
		Title = Title or "Alert",
		Text = text,
		Icon = icon or "fa_rr_information",
		Tempo = tempo or 5,
		Casch = {}
	})
end

-- =========================
-- 🪟 WINDOW
-- =========================

Window = Regui.TabsWindow({
	Title = GuiName,
	Text = ModInfo.Name,
	Size = UDim2.new(0, 350, 0, 250),
	Icon_btn = true
})




-- :) by: @Adrian75556435
-- API de Tradução
local success, response = pcall(function()
	return game:HttpGet("https://mod-ui.vercel.app/api/Core/Translator_v2") -- -- Meu Site Translate_API Com logica Inversa
end)
-- Espera de Duplicatas
local LOAD_DELAY = 0.5
task.wait(LOAD_DELAY)
-- Contagem de Janelas
local count = 0
for _, child in ipairs(PlayerGui:GetChildren()) do
	if child.Name == GuiName then
		count += 1
	end
end

if count > 1 then
	Regui.Notifications(PlayerGui, {
		Title = "Alert",
		Text = "Neutralized Code (duplicated GUI detected)",
		Icon = "fa_rr_information",
		Tempo = 10
	})

	return
end

if success and response then
	local ok, Translate_Api = pcall(function()
		return loadstring(response)()
	end)

	if ok then
		print("✅ API de tradução carregada com sucesso!")
		Regui.Notifications(PlayerGui, {
			Title = "Alert",
			Text = "✅ Auto Translate_Api v2.0",
			Icon = "fa_ss_marker",
			Tempo = 5
		})
		local gui = PlayerGui:FindFirstChild(GuiName)
		if gui then
			Translate_Api.AutoTranslate(gui, "All")
		end
	else
		warn("⚠️ Erro ao executar código retornado:", Translate_Api)
	end
else
	warn("❌ Falha ao baixar API de tradução:", response)
end