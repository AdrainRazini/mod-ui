local Regui
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local GuiName = "Mod_The_MeloBlox_"..game.Players.LocalPlayer.Name
local camera = workspace.CurrentCamera

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

-- Meta dados
local ModInfo = {
	Name = "The MeloBlox",
	Version = "1.0.0",
	Date = "2026-04-05",

	Notes = "Mode Menu"
}



-- Tenta carregar localmente
local success, module = pcall(function()
	return require(script.Parent:FindFirstChild("Mod_UI"))
end)

if success and module then
	Regui = module
else
	-- Tenta baixar remoto
	local HttpService = game:GetService("HttpService")
	local ok, err = pcall(function()
		local code = game:HttpGet("https://raw.githubusercontent.com/AdrainRazini/mastermod/refs/heads/main/module/dataGui.lua")
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



local Test_ = {
	Button_Box = false,
	Toggle_Test = false,
	Int_Value = 0,
	Float_Value = 0,
	Type_Name = "Null",
	Cache = {}

}

local Selection = {
	CurrentNPC = nil,
	CurrentGroup = nil,
	CurrentFolder = nil,
	Highlights = {},
	ModeHealth = "Lowest" -- ou "Highest", "ClosestLow", etc
}


local AutoSystem = {
	Enabled = false,
	TargetMode = "Force",
	EnableAutoMode = false,

	AutoUpdate = false, -- boolean (controle)
	TargetFolder = nil, -- folder real

	SpeedForce = 80, -- Força aplicada ao movimento
	LockCamera = false, -- Bloqueia a câmera e move

	-- Distancia de raio de um Circulo
	Distance = 10, -- Distancia do Player ao alvo CLock
	FixY = 1, -- Fixa a altura do movimento Altura
	Angle = 180, -- Angulo de inclinação -- de 0 a 360


	TargetPosition = nil,
	Range = 100,
	TargetNPC = nil,
	Delay = 0.2
}

local plr = game.Players.LocalPlayer
local mouse = plr:GetMouse()

local cam = workspace.CurrentCamera

local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {plr.Character}
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

local function getMouseRay()
	return cam:ScreenPointToRay(mouse.X, mouse.Y)
end

local function getMouseHit()
	local ray = getMouseRay()
	return workspace:Raycast(ray.Origin, ray.Direction * 1000, rayParams)
end

-- pega o MODEL do NPC
local function getNPCModel(part)
	if not part then return end

	local model = part:FindFirstAncestorOfClass("Model")
	if model and model:FindFirstChild("Humanoid") then
		return model
	end
end


local function clearHighlights()
	for i = #Selection.Highlights, 1, -1 do
		local hl = Selection.Highlights[i]
		if hl then
			hl:Destroy()
		end
		Selection.Highlights[i] = nil
	end
end

local function highlightNPC(npc)
	local hl = Instance.new("Highlight")
	hl.FillColor = Color3.fromRGB(255, 80, 80)
	hl.OutlineTransparency = 1
	hl.Parent = npc

	table.insert(Selection.Highlights, hl)
end
-- pega todos NPCs do mesmo grupo
local function getNPCGroup(npc)
	if not npc then return end
	local folder = npc.Parent
	if not folder then return end

	local npcs = {}

	for _, v in ipairs(folder:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChild("Humanoid") then
			table.insert(npcs, v)
		end
	end

	return npcs, folder
end

local function selectNPC(npc)
	if not npc then return end

	local group, folder = getNPCGroup(npc)
	if not group then return end

	clearHighlights()

	Selection.CurrentNPC = npc
	Selection.CurrentGroup = group

	Selection.CurrentFolder = folder
	AutoSystem.TargetFolder = folder 

	for _, n in ipairs(group) do
		highlightNPC(n)
	end

	print("Selecionado:", npc.Name, "| Grupo:", folder.Name)
end

local function updateChar(char)
	rayParams.FilterDescendantsInstances = {char}
end

updateChar(plr.Character or plr.CharacterAdded:Wait())
plr.CharacterAdded:Connect(updateChar)

local Options_Farm = {
	"Closest",
	"Lowest",
	"LowestPercent", -- novo
	"ClosestLow",
	"Smart",
	"Highest",
	"Tank", --  mais vida
	"Random",
	"Custom"
}

-- Busca de Entidade
local function getNearestEnemy()
	if not Selection.CurrentGroup then return end

	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end


	local source = Selection.CurrentFolder 
		and Selection.CurrentFolder:GetChildren() 
		or workspace:GetDescendants()

	local nearest = nil
	local shortest = math.huge

	for _, obj in ipairs(source) do
		if obj:IsA("Model") then
			local hum = obj:FindFirstChildOfClass("Humanoid")
			if not hum or hum.Health <= 0 then continue end

			if table.find(Selection.CurrentGroup, obj) then continue end

			local hrp = obj:FindFirstChild("HumanoidRootPart")
			if not hrp then continue end

			local dist = (hrp.Position - root.Position).Magnitude

			if dist < shortest and dist <= AutoSystem.Range then
				shortest = dist
				nearest = obj
			end
		end
	end

	return nearest
end

local function ExtractHealth(text)
	if not text then return end

	local current, max = string.match(text, "(%d+)%s*/%s*(%d+)")
	current = tonumber(current)
	max = tonumber(max)

	if current and max and max > 0 then
		return current, max
	end
end


local function SmartScanHealth(npcRoot)
	local bestCurrent, bestMax

	for _, obj in ipairs(npcRoot:GetDescendants()) do
		if obj:IsA("TextLabel") then
			local current, max = ExtractHealth(obj.Text)

			if current and max then
				-- pega o melhor candidato
				if not bestMax or max > bestMax then
					bestCurrent = current
					bestMax = max
				end
			end
		end
	end

	return bestCurrent, bestMax
end


local function CustomLifeSelect(npc)
	local npcRoot = npc:FindFirstChild("HumanoidRootPart")
	if not npcRoot then return end

	-- =========================
	-- 🔥 FAST PATH (teu método)
	-- =========================
	local Board = npcRoot:FindFirstChild("HealthGUI")
	local BoardFrame = Board and Board:FindFirstChild("HealthBar")
	local HealthImage = BoardFrame and BoardFrame:FindFirstChild("HealhTxt")

	if HealthImage then
		local HealthLabel

		if HealthImage:IsA("TextLabel") then
			HealthLabel = HealthImage
		else
			HealthLabel = HealthImage:FindFirstChildWhichIsA("TextLabel")
		end

		if HealthLabel then
			local current, max = ExtractHealth(HealthLabel.Text)

			if current and max then
				print("⚡ FAST:", npc.Name, current, max)
				return current, max
			end
		end
	end

	-- =========================
	-- 🧠 SMART PATH (fallback)
	-- =========================
	local current, max = SmartScanHealth(npcRoot)

	if current and max then
		print("🧠 SMART:", npc.Name, current, max)
		return current, max
	end

	-- =========================
	-- ❌ FAIL
	-- =========================
	--print("❌ Sem vida detectada:", npc.Name)
end


local function GetHealthPercent(npc)
	local current, max = CustomLifeSelect(npc)

	if current and max then
		return current / max
	end
end


-- Pegar NPC mais próximo
local function getBestNPCFromGroup()
	local group = Selection.CurrentGroup
	if not group or #group == 0 then return end

	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local mode = Selection.ModeHealth or "Closest"

	-- RANDOM
	if mode == "Random" then
		local valid = {}

		for _, npc in ipairs(group) do
			local hum = npc:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then
				table.insert(valid, npc)
			end
		end

		if #valid > 0 then
			return valid[math.random(1, #valid)]
		end
	end

	local best = nil
	local bestScore = math.huge

	for _, npc in ipairs(group) do
		if not npc or not npc.Parent then continue end

		local hum = npc:FindFirstChild("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")

		if not hum or hum.Health <= 0 or not hrp then continue end

		local dist = (hrp.Position - root.Position).Magnitude

		-- resolve vida UMA vez só
		local current, max = CustomLifeSelect(npc)

		local healthPercent
		if current and max then
			healthPercent = current / max
		else
			healthPercent = hum.Health / hum.MaxHealth
		end

		local score

		--  MODES (usando %)

		local hp = healthPercent -- 0 → 1

		if mode == "Closest" then
			score = dist

		elseif mode == "Lowest" then
			score = hp -- menor % primeiro

		elseif mode == "Highest" then
			score = -hp -- maior % primeiro

		elseif mode == "ClosestLow" then
			-- mistura equilibrada
			score = dist + (hp * 50)

		elseif mode == "Strongest" then
			-- foca no mais tank (boss)
			score = -(hp * 1000) + dist

		elseif mode == "Weakest" then
			-- foca no mais fácil de matar
			score = (hp * 100) + dist

		elseif mode == "Smart" then
			-- 🧠 inteligente (kill eficiente)

			local distanceFactor = dist / AutoSystem.Range
			local lowHpFactor = (1 - hp)

			-- prioridade: baixo HP + perto
			score = (distanceFactor * 0.4) + (hp * 0.6)

		elseif mode == "LowestPercent" then
			-- foca no mais fraco
			score = healthPercent

		elseif mode == "Tank" then
			-- foca no mais resistente
			score = -healthPercent

		elseif mode == "Aggressive" then
			-- entra no meio dos mais perigosos
			local danger = hp
			local proximity = 1 / math.max(dist, 1)

			score = -(danger * 0.7) - (proximity * 0.3)

		elseif mode == "Custom" then
			local npcForward = hrp.CFrame.LookVector
			local dirToPlayer = (root.Position - hrp.Position).Unit
			local threat = npcForward:Dot(dirToPlayer)

			score = dist - (threat * 50)

		else
			score = dist
		end

		if score < bestScore then
			bestScore = score
			best = npc
		end
	end

	return best
end


-- Pegar posição no círculo
local function GetPositionNPC(npc)
	if not npc then return end

	local distance = AutoSystem.Distance or 0
	local fixY = AutoSystem.FixY or 0
	local angle = math.rad(AutoSystem.Angle or 0)

	local root = npc:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local center = root.Position

	-- círculo no plano XZ
	local offset = Vector3.new(
		math.cos(angle) * distance,
		0,
		math.sin(angle) * distance
	)

	local targetPosition = center + offset

	return Vector3.new(
		targetPosition.X,
		targetPosition.Y + fixY,
		targetPosition.Z
	)
end


local function movePlayerToNPC(npc)
	if not npc then return end

	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")

	local targetPos = GetPositionNPC(npc)
	if not targetPos then return end

	if hum then
		hum:MoveTo(targetPos)
	end
end

local function flyToPosition(targetPos, speed)
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid")
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root or not hum then return end

	speed = speed or 50

	local direction = (targetPos - root.Position)
	local distance = direction.Magnitude

	if distance < 2 then return end

	-- força pulo se estiver no chão
	if hum.FloorMaterial ~= Enum.Material.Air then
		hum.Jump = true
	end

	local moveDir = direction.Unit
	root.Velocity = Vector3.new(moveDir.X * speed, root.Velocity.Y, moveDir.Z * speed)
end


local function smoothTeleport(targetPos)
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local alpha = 0.15 -- suavidade (0.1 = lento / 1 = instant)
	root.CFrame = root.CFrame:Lerp(CFrame.new(targetPos), alpha)
end


local function getForce()
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local bv = root:FindFirstChild("AutoForce")

	if not bv then
		bv = Instance.new("BodyVelocity")
		bv.Name = "AutoForce"
		bv.MaxForce = Vector3.new(1e5,1e5,1e5)
		bv.Parent = root
	end

	return bv
end

-- forçar movimento
local function forceMove(targetPos)
	local bv = getForce()
	if not bv then return end

	local root = bv.Parent
	local offset = targetPos - root.Position
	local distance = offset.Magnitude

	if distance < 2 then
		bv.Velocity = Vector3.zero
		return
	end

	local dir = offset.Unit

	local k = 5
	local speed = math.clamp(distance * k, 0, AutoSystem.SpeedForce * 3)

	local targetVel = dir * speed

	-- freio inteligente
	local currentVel = bv.Velocity
	if currentVel:Dot(dir) < 0 then
		currentVel = currentVel * 0.5
	end

	-- suavização adaptativa
	local responsiveness = math.clamp(distance / 20, 0.2, 0.8)

	local finalVel = currentVel:Lerp(targetVel, responsiveness)

	-- trava final de precisão
	if distance < 5 then
		finalVel = dir * (distance * 5)
	end

	bv.Velocity = finalVel
end

local function clearForce()
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local bv = root:FindFirstChild("AutoForce")
	if bv then
		bv:Destroy()
	end
end


-- Imput de Poss
local function flyToNPC(npc)
	if not npc then return end

	local targetPos = GetPositionNPC(npc)
	if not targetPos then return end

	flyToPosition(targetPos, AutoSystem.SpeedForce) -- Força Speed
end

local function tpToNPC(npc)
	local targetPos = GetPositionNPC(npc)
	if not targetPos then return end

	smoothTeleport(targetPos)
end

local function forceToNPC(npc)
	local targetPos = GetPositionNPC(npc)
	if not targetPos then return end
	forceMove(targetPos)
end



local function updateGroup()
	local folder = AutoSystem.TargetFolder or Selection.CurrentFolder
	if not folder then return end

	local group = Selection.CurrentGroup or {}
	local exists = {}

	-- marca os que existem
	for _, npc in ipairs(group) do
		if npc and npc.Parent then
			exists[npc] = true
		end
	end

	-- adiciona novos NPCs
	for _, v in ipairs(folder:GetChildren()) do
		if v:IsA("Model") and v:FindFirstChild("Humanoid") then
			if not exists[v] then
				table.insert(group, v)
			end
		end
	end

	-- limpa inválidos
	for i = #group, 1, -1 do
		local npc = group[i]
		if not npc or not npc.Parent then
			table.remove(group, i)
		end
	end

	Selection.CurrentGroup = group
end

local function LookCameraToPosition(targetPosition, duration)
	duration = duration or 0

	local currentCFrame = camera.CFrame
	local newCFrame = CFrame.new(currentCFrame.Position, targetPosition)

	local tween = TweenService:Create(
		camera,
		TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{CFrame = newCFrame}
	)

	tween:Play()
	return tween
end

-- Gerencia o movimento do jogador
local function moveToNPC_ByMode(npc)
	if not npc then return end

	if AutoSystem.TargetMode == "Move" then
		movePlayerToNPC(npc)

	elseif AutoSystem.TargetMode == "Fly" then
		flyToNPC(npc)

	elseif AutoSystem.TargetMode == "Force" then
		local hrp = npc:FindFirstChild("HumanoidRootPart")
		if hrp then
			forceToNPC(npc)
			--forceMove(hrp.Position)
		end

	elseif AutoSystem.TargetMode == "Auto" then
		-- inteligente: escolhe baseado na distância
		local char = plr.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hrp = npc:FindFirstChild("HumanoidRootPart")

		if root and hrp then
			local dist = (hrp.Position - root.Position).Magnitude

			if dist > 80 then
				--smoothTeleport(hrp.Position)
				tpToNPC(npc)
			elseif dist > 25 then
				flyToNPC(npc)
			else
				movePlayerToNPC(npc)

			end
		end
	end
end

local RunService = game:GetService("RunService")

local lastUpdate = 0

RunService.Heartbeat:Connect(function()
	if not AutoSystem.Enabled then clearForce() return end
	-- LockCamera Intantanio
	if AutoSystem.LockCamera then
		local hrp = Selection.CurrentNPC and Selection.CurrentNPC:FindFirstChild("HumanoidRootPart")
		if hrp then
			LookCameraToPosition(hrp.Position, 0.1)
		end
	end

	if tick() - lastUpdate < AutoSystem.Delay then return end
	lastUpdate = tick()

	-- 🔄 atualização real (sem conflito)
	if AutoSystem.AutoUpdate then
		updateGroup()
	end

	if AutoSystem.EnableAutoMode then
		local target = getBestNPCFromGroup()

		if target then
			moveToNPC_ByMode(target) -- Envia Target ou npc
			Selection.CurrentNPC = target
		else
			clearForce() -- importante pra não ficar bugado
		end

		return
	end


	clearForce() -- garante que não fica com velocity travada
end)

mouse.Button1Down:Connect(function()
	if not AutoSystem.Enabled then return end
	local result = getMouseHit()
	if not result then return end

	local npc = getNPCModel(result.Instance)

	if npc then
		selectNPC(npc)
	else
		-- salva posição de movimento
		AutoSystem.TargetPosition = result.Position
	end
end)

-- =========================
-- 🧠 HELPERS UI
-- =========================

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
local function Notify(text, icon, tempo)
	Regui.NotificationPerson(Window.Frame.Parent, {
		Title = "Alert",
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

-- =========================
-- 🪟 TABS
-- =========================

local FarmTab    = Regui.CreateTab(Window, {Name = "Farm"})
local PlayerTab  = Regui.CreateTab(Window, {Name = "Player"})
local GameTab    = Regui.CreateTab(Window, {Name = "Game"})
local ConfigsTab = Regui.CreateTab(Window, {Name = "Configs"})
local HelpTab    = Regui.CreateTab(Window, {Name = "Help"})

local ExampleTab = Regui.CreateTab(Window, {Name = "Example"})
ExampleTab.Visible = false

-- =========================
-- 🎮 CONTROL
-- =========================

Regui.CreateLabel(FarmTab, {
	Text = "-- Control --",
	Color = "White",
	Alignment = "Center"
})

Regui.CreateButton(FarmTab, {
	Text = "Clear Highlights",
	Color = "Blue"
}, function()
	clearHighlights()

	Selection.CurrentNPC = nil
	Selection.CurrentGroup = nil
	Selection.CurrentFolder = nil

	AutoSystem.TargetPosition = nil
	AutoSystem.TargetFolder = nil

	clearForce()
end)

local EnableClickSelect = CreateToggle(FarmTab, "Enable Click Select", function(state)
	AutoSystem.Enabled = state
end)

EnableClickSelect.Set(true)

-- =========================
-- 🧭 MOVEMENT (SUB SYSTEM)
-- =========================

local MovementTabs = Regui.SubTabsWindow(FarmTab, {
	Text = "Movement System",
	Table = {"Automation","Settings", "Logs"},
	Color = "Blue"
})

-- =========================
-- 📜 LOGS UI
-- =========================

local LogsLabel = Regui.CreateLabel(MovementTabs["Logs"], {
	Text = "Loading...",
	Color = "White",
	Alignment = "Left"
})

-- função de formatar texto
local function BuildLogs()
	local npcName = Selection.CurrentNPC and Selection.CurrentNPC.Name or "None"
	local groupSize = Selection.CurrentGroup and #Selection.CurrentGroup or 0

	local mode = AutoSystem.TargetMode
	local auto = tostring(AutoSystem.EnableAutoMode)
	local update = tostring(AutoSystem.AutoUpdate)
	local hp = Selection.CurrentNPC and GetHealthPercent(Selection.CurrentNPC)
	hp = hp and math.floor(hp * 100) .. "%" or "N/A"

	local dist = AutoSystem.Distance
	local speed = AutoSystem.SpeedForce

	return table.concat({
		"📊 SYSTEM LOGS",
		"-----------------------",
		"Target: " .. npcName,
		"HP: " .. hp,
		"Group Size: " .. groupSize,
		"",
		"Mode: " .. mode,
		"Auto Mode: " .. auto,
		"Auto Update: " .. update,
		"",
		"Distance: " .. dist,
		"Speed: " .. speed,
	}, "\n")
end

-- 🔹 SETTINGS

Regui.CreateLabel(MovementTabs["Settings"], {
	Text = "-- Movement Config --",
	Color = "White",
	Alignment = "Center"
})

CreateSelector(MovementTabs["Settings"], "Move Mode", {"Auto", "Move", "Fly", "Force"}, function(val)
	AutoSystem.TargetMode = val
	clearForce()
end)

CreateSlider(MovementTabs["Settings"], "Speed Force", AutoSystem.SpeedForce, 10, 100, function(val)
	AutoSystem.SpeedForce = val
end)

CreateSlider(MovementTabs["Settings"], "Distance", AutoSystem.Distance, 0, 50, function(val)
	AutoSystem.Distance = val
end)

CreateSlider(MovementTabs["Settings"], "Height Offset (Y)", AutoSystem.FixY, 0, 25, function(val)
	AutoSystem.FixY = val
end)

CreateSlider(MovementTabs["Settings"], "Angle", AutoSystem.Angle, 0, 360, function(val)
	AutoSystem.Angle = val
end)

-- 🔹 AUTOMATION

Regui.CreateLabel(MovementTabs["Automation"], {
	Text = "-- Automation --",
	Color = "White",
	Alignment = "Center"
})

CreateToggle(MovementTabs["Automation"], "Auto Move to NPC", function(state)
	AutoSystem.EnableAutoMode = state
end)

local AutoUpdateNPC = CreateToggle(MovementTabs["Automation"], "Auto Update NPCs", function(state)
	AutoSystem.AutoUpdate = state
end)

AutoUpdateNPC.Set(true)

CreateToggle(MovementTabs["Automation"], "Camera Lock", function(state)
	AutoSystem.LockCamera = state
end)

-- =========================
-- 🎯 TARGET AI
-- =========================

Regui.CreateLabel(FarmTab, {
	Text = "-- Target AI --",
	Color = "White",
	Alignment = "Center"
})

CreateSelector(FarmTab, "Target Mode", Options_Farm, function(val)
	Selection.ModeHealth = val
end)

CreateSlider(FarmTab, "Search Range", AutoSystem.Range, 0, 500, function(val)
	AutoSystem.Range = val
end)

-- Model Selector

local Label_Ex_Farme = Regui.CreateLabel(FarmTab, {Text = "Example", Color = "White", Alignment = "Center"})


local Check_Farme = Regui.CreateCheckboxe(ExampleTab, {Text = "Checkboxe", Color = "Blue"}, function(state)
	Test_.Button_Box = state
	--print("Checkbox clicada! Estado:", Test_.Button_Box)

	if Test_.Button_Box  then
		-- Notificação se for Verdadeiro
		Regui.NotificationPerson(Window.Frame.Parent, {
			Title = "Alert",
			Text = "Checkbox clicada! Estado: " .. tostring(Test_.Button_Box),
			Icon = "fa_envelope",
			Tempo = 10,
			Casch = {},
			Sound = ""
		}, function()
			print("Notificação fechada!")
		end)
	end


end)


local Toggle_Farme = Regui.CreateToggleboxe(ExampleTab, {Text = "Toggle", Color = "Blue"}, function(state)

	Test_.Toggle_Test = state
	--print("Toggle clicada! Estado:", Test_.Toggle_Test)

	if Test_.Toggle_Test then

	end
end)

-- Principais sliders

local SliderFloat = Regui.CreateSliderFloat(ExampleTab, {Text = "Timer Flaot", Color = "Blue", Value = 0.1, Minimum = 0, Maximum = 1}, function(state)
	Test_.Float_Value = state
	print("Slider Float clicada! Estado:", Test_.Float_Value)

end)

local SliderInt = Regui.CreateSliderInt(ExampleTab, {Text = "Timer Int", Color = "Blue", Value = 1, Minimum = 0, Maximum = 100}, function(state)
	Test_.Int_Value = state
	print("Slider Int clicada! Estado:", Test_.Int_Value)

end)

local SliderOption = Regui.CreateSliderOption(ExampleTab, {Text = "Timer Option", Color = "White", Background = "Blue" , Value = 1, Table = {"Melle","Fire","Aura"}}, function(state)
	Test_.Type_Name = state
	print("Slider Int clicada! Estado:", Test_.Type_Name)
end)


-- Cria SubWindow 
local SubWin = Regui.SubTabsWindow(ExampleTab, {
	Text = "Sub_Window",
	Table = {"Logs","Player","Main"},
	Color = "Blue"
})

-- Adiciona controles dentro de cada subtab
Regui.CreateSliderInt(SubWin["Logs"], {
	Text = "Delay Logs",
	Color = "Blue",
	Value = 5,
	Minimum = 0,
	Maximum = 20
}, function(val)  end)

Regui.CreateSliderInt(SubWin["Player"], {
	Text = "HP Regen",
	Color = "Green",
	Value = 50,
	Minimum = 0,
	Maximum = 100
}, function(val)  end)

Regui.CreateSliderInt(SubWin["Main"], {
	Text = "Auto Timer",
	Color = "Red",
	Value = 1,
	Minimum = 0,
	Maximum = 10
}, function(val)  end)


local Tab_F_Logs = Regui.CreateSubTab(ExampleTab, { Text = "Alert", Table= {"Logs: Null", "Player: " .. game.Players.LocalPlayer.Name, "Main: Null"}, Color = "Blue"})
local SliderInt = Regui.CreateSliderInt(Tab_F_Logs, {Text = "Timer Int", Color = "Blue", Value = 1, Minimum = 0, Maximum = 100}, function(state) end) 


local Label_Farme2 = Regui.CreateLabel(ConfigsTab, {Text = "Example", Color = "White", Alignment = "Center"})

-- Exemplo de uso:
local Painter = Regui.CreatePainterPanel(ConfigsTab, {
	{name = "Main_Frame", Obj = Window.Frame},
	{name = "Top_Bar", Obj = Window.TopBar},
	{name = "Tabs_Container", Obj = Window.Tabs},
	{name = "Tab_Content", Obj = Window.TabContainer},
	{name = "Top_Tabs_Bar", Obj = Window.TopTabs},
	{name = "Config_Bar", Obj = ConfigsTab},
	{name = "Label_Display", Obj = Label_Farme2}
}, function(color, name, obj)
	print("Cor aplicada em:", name, color)
end)


-- Exemplo de uso
local OptionsStrings = Regui.CreateSelectorOpitions(ConfigsTab, {
	Name = "Selector",
	Alignment = "Center",
	Size_Frame = UDim2.new(1,-10,0,50),
	Options = {"Nil", "UI", "Nil", "UI","Nil", "UI","Nil", "UI","Nil", "UI"},
	Frame_Max = 50,
	Type = "String"
}, function(val)
	print("Você escolheu:", val)
end)



local OptionsInstance = Regui.CreateSelectorOpitions(ConfigsTab, {
	Name = "Selector",
	Alignment = "Center",
	Size_Frame = UDim2.new(1,-10,0,50),
	Frame_Max = 50,
	Options = {

		{name = "Main_Frame", Obj = Window.Frame},
		{name = "Top_Bar", Obj = Window.TopBar},
		{name = "Tabs_Container", Obj = Window.Tabs},
		{name = "Tab_Content", Obj = Window.TabContainer},
		{name = "Top_Tabs_Bar", Obj = Window.TopTabs},
		{name = "Config_Bar", Obj = ConfigsTab},
		{name = "Label_Display", Obj = Label_Farme2}

	},

	Type = "Instance"
}, function(val)
	print("Você escolheu:", val)
end)

local ReadmeTab = Regui.CreateTab(Window, {Name = "Readme"})
--[[

local Readme_Lb = Regui.CreateLabel(ReadmeTab, {
	Text = "\n• This UI library was created by @Adrian75556435 Thanks."
		.. "\n• Owner Of Script: @Adrian75556435"
		.. "\n• Script & Management By: @Adrian75556435",
	Color = "White",
	Alignment = "Left"
})

]]

local Credits = Regui.CreditsUi(ReadmeTab, { Alignment = "Center", Alignment_Texts = "Left"}, function() end)

RunService.Heartbeat:Connect(function()
	if not LogsLabel then return end

	LogsLabel.Text = BuildLogs()
end)

-- :) by: @Adrian75556435

-- API de Tradução
local success, response = pcall(function()
	return game:HttpGet("https://animal-simulator-server.vercel.app/lua/TranslateV2.lua")
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
			Text = "✅ Auto Translate_Api",
			Icon = "fa_rr_information",
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