local Regui
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local GuiName = "Mod_The_Tribe_"..game.Players.LocalPlayer.Name
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
	Name = "Tribe Survival",
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



local Intercept

local success, response = pcall(function()
	return game:HttpGet("https://mod-ui.vercel.app/api/Modules/Intercept")
end)

if success and response then
	local ok, module = pcall(function()
		return loadstring(response)()
	end)

	if ok and module then
		Intercept = module
	else
		warn("Erro ao carregar Intercept:", module)
	end
else
	warn("Erro ao baixar Intercept:", response)
end

-- só executa se existir
if Intercept then
	Intercept:Enable()
	Intercept:SetEnabled(true)
	Intercept:AddTemp("Eat")
end



local TaskScheduler

local success, response = pcall(function()
	return game:HttpGet("https://mod-ui.vercel.app/api/Modules/TaskScheduler")
end)

if success and response then
	local ok, module = pcall(function()
		return loadstring(response)()
	end)

	if ok and module then
		TaskScheduler = module
	else
		warn("Erro ao carregar Intercept:", module)
	end
else
	warn("Erro ao baixar TaskScheduler:", response)
end

-- só executa se existir
if TaskScheduler then
	TaskScheduler:Run()
end


-- Aim Lock
local function SetAutoRotate(state)
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")
	if hum then
		hum.AutoRotate = state
	end
end

local function ForceLockRoot(root, targetPos)
	local pos = root.Position
	local target = Vector3.new(targetPos.X, pos.Y, targetPos.Z)

	root.CFrame = CFrame.new(pos, target)
end

local function LockRootToPosition(targetPosition)
	local root = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local pos = root.Position
	local target = Vector3.new(targetPosition.X, pos.Y, targetPosition.Z)

	root.CFrame = CFrame.new(pos, target)
end

local function SmoothLockRoot(root, targetPos, alpha)
	alpha = alpha or 0.2

	local pos = root.Position
	local target = Vector3.new(targetPos.X, pos.Y, targetPos.Z)

	local targetCF = CFrame.new(pos, target)
	root.CFrame = root.CFrame:Lerp(targetCF, alpha)
end

local function InstantLockRoot(root, targetPos)
    local pos = root.Position
    local lookAt = Vector3.new(targetPos.X, pos.Y, targetPos.Z)

    root.CFrame = CFrame.new(pos, lookAt)
end

local function GetClosestPlayer(maxDistance)
	local closest = nil
	local shortest = maxDistance or math.huge

	local myChar = plr.Character
	if not myChar then return nil end

	local myRoot = myChar:FindFirstChild("HumanoidRootPart")
	if not myRoot then return nil end

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= plr then
			local char = player.Character
			local hum = char and char:FindFirstChild("Humanoid")
			local root = char and char:FindFirstChild("HumanoidRootPart")

			if hum and hum.Health > 0 and root then
				local dist = (root.Position - myRoot.Position).Magnitude

				if dist < shortest then
					shortest = dist
					closest = player
				end
			end
		end
	end

	return closest
end

local Selection = { CurrentTarget = nil,MaxDistance = 50, Highlights = setmetatable({}, {__mode="k"})}
local AutoSystem = { AutoEat = false, TimerEat = 0.5, AutoAim = false, AutoAbility = false , AbilityTimer = 1}

-- Target
local function UpdateTarget()
	Selection.CurrentTarget = GetClosestPlayer(Selection.MaxDistance)
end

local function ApplyAim()
	if not Selection.CurrentTarget then return end

	local char = Selection.CurrentTarget.Character
	if not char then return end

	local targetRoot = char:FindFirstChild("HumanoidRootPart")
	local myRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

	if not targetRoot or not myRoot then return end

	--SmoothLockRoot(myRoot, targetRoot.Position, 0.01)
	InstantLockRoot(myRoot, targetRoot.Position)
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

local ModFarm     = Regui.CreateTab(Window, {Name = "Farm"})
local HelpTab     = Regui.CreateTab(Window, {Name = "Help"})

local Label = Regui.CreateLabel(ModFarm, {Text = "Auto Eat Test", Color = "White", Alignment = "Center"})

local EnableAutoEatSelect = CreateToggle(ModFarm, "Auto Eat", function(state)
	AutoSystem.AutoEat = state
end)

CreateSlider(ModFarm, "Speed Auto Eat", AutoSystem.TimerEat, 0, 1, function(val)
	AutoSystem.TimerEat = val
	TaskScheduler:UpdateTaskInterval("Eat", val)
end)

local EnableAutoEatSelect = CreateToggle(ModFarm, "Automatically Aim", function(state)
	AutoSystem.AutoAim = state
end)

CreateSlider(ModFarm, "Max Distance", Selection.MaxDistance, 10, 100, function(val)
	Selection.MaxDistance = val
end)

local EnableAutoAbSelect = CreateToggle(ModFarm, "Automatically Aim", function(state)
	AutoSystem.AutoAbility = state

	while AutoSystem.AutoAbility do
		task.wait(Selection.AbilityTimer or 1)

		local character = plr.Character
		if not character then continue end

		local backpack = plr:FindFirstChild("Backpack")
		if not backpack then continue end

		local tool = backpack:FindFirstChild("Wooden Shield") 
			or character:FindFirstChild("Wooden Shield")

		if tool and character:FindFirstChild("Secondary") then
			local remote = character.Secondary:FindFirstChild("UseAbility")

			if remote then
				remote:FireServer(tool)
			end
		end
	end
end)


CreateSlider(ModFarm, "_Test", Selection.AbilityTimer, 1, 3, function(val)
	Selection.AbilityTimer = val
end)

TaskScheduler:AddTask("Eat", {
	Interval = AutoSystem.TimerEat,
	Priority = 1,

	Callback = function()
		if AutoSystem.AutoEat then
			Intercept:Replay("Eat")
		end
	end
})

TaskScheduler:AddTask("AimAssist", {
	Interval = 0.01, -- bem fluido
	Priority = 2,

	Callback = function()

    if not AutoSystem.AutoAim then
	 SetAutoRotate(true)
	 return
    end

     SetAutoRotate(false)
	 UpdateTarget()
	 ApplyAim()
	end
})


local MemeCat = Regui.CreateImage(ModFarm, {
	Name = "Mini Adrian",
	Transparence = 1,
	Alignment = "Center",
	Id_Image = "rbxassetid://122365940403758",
	Size_Image = UDim2.new(0, 100, 0, 100)
})


local Hlp = [[
-- Guide
Grab the food and use the Auto-Eat event;
Eat the food a few times to capture
the feeding event.
]]


local LabelHelp = Regui.CreateLabel(HelpTab, {Text = Hlp, Color = "White", Alignment = "Center"})


local ReadmeTab = Regui.CreateTab(Window, {Name = "Readme"})

local Credits = Regui.CreditsUi(ReadmeTab, { Alignment = "Center", Alignment_Texts = "Left"}, function() end)
local MiniAdrian = Regui.CreateImage(ReadmeTab, {
	Name = "Mini Adrian",
	Transparence = 1,
	Alignment = "Center",
	Id_Image = "rbxassetid://127904385880677",
	Size_Image = UDim2.new(0, 100, 0, 100)
})

Regui.applyCorner(MiniAdrian)



Notify("Version: "..ModInfo.Name,ModInfo.Version,"fa_bx_code_end",1)


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
