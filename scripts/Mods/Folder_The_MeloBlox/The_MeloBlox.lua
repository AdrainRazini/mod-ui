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

local plr = game.Players.LocalPlayer
local mouse = plr:GetMouse()
local cam = workspace.CurrentCamera

-- Meta dados
local ModInfo = {
	Name = "The MeloBlox",
	Version = "3.1.0",
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


-- Testes de Mods 
local Test_ = {

    -- plr
	Speed = {},
	Jump = {},
	FOV = nil,
	NoClip = {},

    -- args
	Button_Box = false,
	Toggle_Test = false,
	Int_Value = 0,
	Float_Value = 0,
	Type_Name = "Null",
	Cache = {}

}

local Selection = {
	CurrentNPC = nil, -- Armazena o NPC atual
	CurrentGroup = nil, -- Armazena o grupo atual
	CurrentFolder = nil, -- Armazena a pasta atual
	Highlights = {}, -- Armazena os Highlights ativos
	ModeHealth = "Closest", -- ou "Highest", "ClosestLow", etc
	Filters = {
		Name = nil,      -- string ou pattern
		MinLevel = 0,  -- número mínimo
		MaxLevel = 5,  -- número máximo
	} -- Armazena os NPCs encontrados ex: Name e Lv.xx
}


local AutoSystem = {

	-- Configurações do sistema
	Enabled = false, -- Ativação do sistema
	TargetMode = "Force", -- Modo de aproximação
	EnableAutoMode = false, -- Ativa o modo automático

	-- Controle de atualização automática
	AutoUpdate = false, -- boolean (controle)
	TargetFolder = nil, -- folder real

	-- Configurações de movimento
	SpeedForce = 80, -- Força aplicada ao movimento
	LockCamera = false, -- Bloqueia a câmera e move
	LockRoot = false, -- Bloqueia o movimento do player

	-- Distancia de raio de um Circulo
	Distance = 10, -- Distancia do Player ao alvo CLock
	FixY = 1, -- Fixa a altura do movimento Altura
	Angle = 180, -- Angulo de inclinação -- de 0 a 360

	-- Configurações de alvo
	TargetPosition = nil, -- Posição do alvo
	Range = 100, -- Raio de detecção
	TargetNPC = nil, -- NPC alvo
	Delay = 0.2
}



local rayParams = RaycastParams.new()
rayParams.FilterDescendantsInstances = {plr.Character}
rayParams.FilterType = Enum.RaycastFilterType.Blacklist --> Raycast ignora o personagem do jogador

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

	Selection.GroupMap = nil  -- ← libera referência antiga
	Selection.GroupMap = {}    -- ← novo mapa


	Selection.CurrentFolder = folder
	AutoSystem.TargetFolder = folder 

	for _, npc in ipairs(group) do
		highlightNPC(npc)
		Selection.GroupMap[npc] = true
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

local Options_Farm_Modes = {
	"Auto",
	"Fast",
	"Move",
	"Fly",
	"Force"
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

			--if table.find(Selection.CurrentGroup, obj) then continue end
			if Selection.GroupMap[obj] then continue end

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

-- WeakKeys para limpar referências de NPCs automaticamente
local NpcInfoCache = setmetatable({}, {__mode="k"}) -- chave = npc

local HealthCache = setmetatable({}, {__mode="k"}) -- WeakKeys

-- Busca de Entidade (Melhorada)
local Filters = {
	{ "CreatureName", "TextLabel", "Name" },
	{ "LvlTxt", "TextLabel", "Level" },
	{ "HealthTxt", "TextLabel", "Health" },
}

-- Ex: "Goblin Lv. 12"
local function ExtractLevel(text)
	if not text then return end
	-- procura por "Lv." seguido de número
	local level = string.match(text, "Lv%.%s*(%d+)")
	return tonumber(level)
end

-- Ex: "Goblin Lv. 12"
local function ExtractName(text)
	if not text then return end
	-- remove a parte "Lv. XX" se existir
	local name = text:gsub("Lv%.%s*%d+", ""):gsub("^%s*(.-)%s*$", "%1")
	return name
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


-- Busca recursiva de objetos que correspondem aos filtros
local function FindNpcInfo(npcRoot)
	if not npcRoot then return end

	if NpcInfoCache[npcRoot] then
		return NpcInfoCache[npcRoot]
	end

	local info = {}

	for _, descendant in pairs(npcRoot:GetDescendants()) do
		for _, filter in pairs(Filters) do
			local id, className, key = table.unpack(filter)
			if descendant:IsA(className) and descendant.Name:find(id) then
				local text = descendant.Text
				if text then
					if key == "Name" then
						info.Name = ExtractName(text)
					elseif key == "Level" then
						info.Level = ExtractLevel(text)
					elseif key == "Health" then
						info.CurrentHealth, info.MaxHealth = ExtractHealth(text)
					end
				end
			end
		end
	end

	-- Heurística rápida se não encontrou
	for _, descendant in pairs(npcRoot:GetDescendants()) do
		if descendant:IsA("TextLabel") and descendant.Text then
			if not info.Name then
				local ok, name = pcall(ExtractName, descendant.Text)
				if ok then info.Name = name end
			end
			if not info.Level then
				local ok, lvl = pcall(ExtractLevel, descendant.Text)
				if ok then info.Level = lvl end
			end
		end
	end

	NpcInfoCache[npcRoot] = info
	print(info.Name, info.Level)
	return info
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


local function GetCachedHealth(npc)
	local cache = HealthCache[npc]

	if cache and tick() - cache.time < 0.5 then
		return cache.current, cache.max
	end

	local current, max = CustomLifeSelect(npc)

	HealthCache[npc] = {
		current = current,
		max = max,
		time = tick()
	}

	return current, max
end

local function CleanHealthCache()
	for npc, data in pairs(HealthCache) do
		if not npc or not npc.Parent then
			HealthCache[npc] = nil
		end
	end
end

local function GetHealthPercent(npc)
	local current, max = GetCachedHealth(npc) --CustomLifeSelect(npc)

	if current and max then
		return current / max
	end
end

local function PassesFilters(npc)
	if not npc or not npc.Parent then return false end
	local info = FindNpcInfo(npc)
	if not info then return false end

	local filters = Selection.Filters

	-- filtro por nome (ignora se for "All" ou nil)
	if filters.Name and filters.Name ~= "All" then
		if not string.find(info.Name or "", filters.Name) then
			return false
		end
	end

	-- filtro por nível mínimo
	if filters.MinLevel and (info.Level or 0) < filters.MinLevel then
		return false
	end

	-- filtro por nível máximo
	if filters.MaxLevel and (info.Level or 5) > filters.MaxLevel then
		return false
	end

	return true
end
-- Função para gerar nomes únicos
local function GenerateUniqueNames(Folder)
	local uniqueNames = {}
	local seen = {}

	if Folder then
		for _, npc in ipairs(Folder:GetChildren()) do
			if npc:IsA("Model") and npc:FindFirstChild("Humanoid") then
				local info = FindNpcInfo(npc)
				if info and info.Name and not seen[info.Name] then
					table.insert(uniqueNames, info.Name)
					seen[info.Name] = true
				end
			end
		end
	else
		for npc, info in pairs(NpcInfoCache) do
			if npc and npc.Parent and info.Name and not seen[info.Name] then
				table.insert(uniqueNames, info.Name)
				seen[info.Name] = true
			end
		end
	end

	table.insert(uniqueNames, 1, "All")
	return uniqueNames
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

		if not PassesFilters(npc) then continue end  -- aplica filtro aqui

		local hum = npc:FindFirstChild("Humanoid")
		local hrp = npc:FindFirstChild("HumanoidRootPart")

		if not hum or hum.Health <= 0 or not hrp then continue end

		local dist = (hrp.Position - root.Position).Magnitude

		-- resolve vida UMA vez só
		local current, max = GetCachedHealth(npc) --CustomLifeSelect(npc)

		local healthPercent
		if current and max then
			healthPercent = current / max
		else
			healthPercent = hum.Health / hum.MaxHealth
		end

		local score

		--  MODES (usando %)

		local hp = healthPercent -- 0 → 1

		local distNorm = dist / AutoSystem.Range
		local hpNorm = hp

		if mode == "Closest" then
			score = dist

		elseif mode == "Lowest" then
			score = hp -- menor % primeiro

		elseif mode == "Highest" then
			score = -hp -- maior % primeiro

		elseif mode == "ClosestLow" then
			-- mistura equilibrada
			score = (distNorm * 0.5) + (hpNorm * 0.5)

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


local function smoothTeleport(targetPos)
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- FAST MODE = teleport instantâneo
	if AutoSystem.TargetMode == "Fast" then
		root.CFrame = CFrame.new(targetPos)
		root.Velocity = Vector3.zero -- evita carry de velocidade
		return
	end

	-- NORMAL MODE (suave)
	local alpha = 0.15 -- 0.1 = mais suave | 1 = instantâneo
	root.CFrame = root.CFrame:Lerp(CFrame.new(targetPos), alpha)
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

local function SmoothLookCamera(camera, targetPos, alpha)
	alpha = alpha or 0.2

	local currentCF = camera.CFrame
	local targetCF = CFrame.new(currentCF.Position, targetPos)

	camera.CFrame = currentCF:Lerp(targetCF, alpha)
end

-- Look Camera
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

	elseif AutoSystem.TargetMode == "Fast" then
		tpToNPC(npc)

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

local Gerencier = {
	Tasks = {},
	LastRun = {},
	Metrics = {},
	FPS = 60,
	LoadFactor = 1 -- adaptador
}

-- adicionar task avançada
function Gerencier:AddTask(name, config)
	self.Tasks[name] = {
		Interval = config.Interval or 0.1,
		Priority = config.Priority or 1,
		Callback = config.Callback,
		Dynamic = config.Dynamic or false
	}

	self.LastRun[name] = 0
	self.Metrics[name] = {
		ExecTime = 0,
		Calls = 0
	}
end

-- monitor de FPS
RunService.Heartbeat:Connect(function(dt)
	Gerencier.FPS = math.floor(1 / dt)

	-- auto adaptação
	if Gerencier.FPS < 40 then
		Gerencier.LoadFactor = 1.5
	elseif Gerencier.FPS < 25 then
		Gerencier.LoadFactor = 2
	else
		Gerencier.LoadFactor = 1
	end
end)

-- runner principal
function Gerencier:Run()
	RunService.Heartbeat:Connect(function()
		local now = tick()

		-- ordena por prioridade
		local ordered = {}

		for name, task in pairs(self.Tasks) do
			table.insert(ordered, {name = name, task = task})
		end

		table.sort(ordered, function(a, b)
			return a.task.Priority > b.task.Priority
		end)

		for _, data in ipairs(ordered) do
			local name = data.name
			local task = data.task

			local interval = task.Interval

			-- adaptive interval
			if task.Dynamic then
				interval *= self.LoadFactor
			end

			if now - self.LastRun[name] >= interval then
				self.LastRun[name] = now

				local start = tick()

				local ok, err = pcall(task.Callback)

				local execTime = tick() - start

				-- métricas
				local metric = self.Metrics[name]
				metric.ExecTime = execTime
				metric.Calls += 1

				if not ok then
					warn("[Task Error]", name, err)
				end
			end
		end
	end)
end

function Gerencier:AddRenderTask(name, fn)
	RunService.RenderStepped:Connect(fn)
end

local currentTarget = nil

Gerencier:AddTask("Target", {
	Interval = AutoSystem.Delay,
	Priority = 3,
	Dynamic = true,

	Callback = function()
		if not (AutoSystem.Enabled and AutoSystem.EnableAutoMode) then return end

		if AutoSystem.AutoUpdate then
			updateGroup()
		end

		currentTarget = getBestNPCFromGroup()

		-- contagem, apenas:
		if math.random() < 0.05 then  -- 5% de chance por ciclo (~1 vez por segundo)
			CleanHealthCache()
		end
	end
})

Gerencier:AddTask("Movement", {
	Interval = AutoSystem.Delay,
	Priority = 2,

	Callback = function()
		if not AutoSystem.Enabled then 
			clearForce()
			return 
		end

		-- SE DESATIVOU AUTO MODE → PARA TUDO
		if not AutoSystem.EnableAutoMode then
			clearForce()
			--SetAutoRotate(true)

			currentTarget = nil
			Selection.CurrentNPC = nil -- ESSENCIAL

			return
		end

		-- AUTO MODE ATIVO
		local target = currentTarget

		if target then
			moveToNPC_ByMode(target)
			Selection.CurrentNPC = target
		else
			clearForce()
		end
	end
})

Gerencier:AddRenderTask("Render", function()

	local enabled = AutoSystem.Enabled
	local auto = AutoSystem.EnableAutoMode

	if not enabled or not auto then
		SetAutoRotate(true)
	end

	local npc = Selection.CurrentNPC
	if not npc then return end

	local hrp = npc:FindFirstChild("HumanoidRootPart")
	local char = plr.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")

	if not hrp or not root then return end

	if AutoSystem.LockRoot then
		SetAutoRotate(false)
		ForceLockRoot(root, hrp.Position)
	end

	if AutoSystem.LockCamera then
		local camPos = camera.CFrame.Position
		camera.CFrame = CFrame.new(camPos, hrp.Position)
	end
end)

Gerencier:Run()

local OptionsStrings_Filter
local LevelSlider

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

-- =========================
-- 🪟 TABS
-- =========================

local FarmTab     = Regui.CreateTab(Window, {Name = "Farm"})
local PlayerTab  = Regui.CreateTab(Window, {Name = "Player"})
local ModesTab    = Regui.CreateTab(Window, {Name = "Modes"})
local HelpTab     = Regui.CreateTab(Window, {Name = "Help"})



--[[
local GameTab    = Regui.CreateTab(Window, {Name = "Game"})
]]

local ConfigsTab = Regui.CreateTab(Window, {Name = "Configs"})


local ModesLabel = Regui.CreateLabel(ModesTab, {
	Text = "Modes...",
	Color = "White",
	Size = UDim2.new(1, -10, 0, 25),
	Alignment = "Left"
})

local HelpLabel = Regui.CreateLabel(HelpTab, {
	Text = "Help...",
	Color = "White",
	Size = UDim2.new(1, -10, 0, 25),
	Alignment = "Left"
})

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


Regui.CreateLabel(FarmTab, {
	Text = "-- Select Filters --",
	Color = "White",
	Alignment = "Center"
})

-- Cria selector
OptionsStrings_Filter = Regui.CreateSelectorOpitions(FarmTab, {
	Name = "Selector: NPC",
	Alignment = "Center",
	Size_Frame = UDim2.new(1,-10,0,100),
	Options = {"All"}, -- valor inicial
	Frame_Max = 50,
	Type = "String"
}, function(val)
	Selection.Filters.Name = val == "All" and nil or val -- "All" ignora filtro
	print("Você escolheu:", val)
end)

-- Atualiza opções do selector quando mudar a tabela
local function UpdateSelectorOptions()
	local names = GenerateUniqueNames(Selection.CurrentFolder)
	OptionsStrings_Filter.Reset(names)
end

-- Exemplo: atualizar a cada 5 segundos
spawn(function()
	while true do
		UpdateSelectorOptions()
		wait(5)
	end
end)

Regui.CreateLabel(FarmTab, {
	Text = "-- Select Level xx --",
	Color = "White",
	Alignment = "Center"
})


CreateToggle(FarmTab, "Enable Select Infinit Lv", function(state)

	if state then
		Selection.Filters.MaxLevel = 9999
		LevelSlider.Set(9999)
	else

	end

end)


LevelSlider = CreateSlider(FarmTab, "Level", Selection.Filters.MaxLevel, 1, 500, function(val)
	Selection.Filters.MaxLevel = val
end)


Regui.CreateLabel(FarmTab, {
	Text = "-- Activate Internal System --",
	Color = "White",
	Alignment = "Center"
})


local EnableClickSelect = CreateToggle(FarmTab, "Enable Click Select", function(state)
	AutoSystem.Enabled = state
end)

EnableClickSelect.Set(true)



Regui.CreateLabel(FarmTab, {
	Text = "-- Movement System --",
	Color = "White",
	Alignment = "Center"
})
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

CreateSelector(MovementTabs["Settings"], "Move Mode", Options_Farm_Modes, function(val)
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

CreateToggle(MovementTabs["Automation"], "Root Lock", function(state)
	AutoSystem.LockRoot = state
end)


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


-- =========================
-- PLAYER EDITOR
-- =========================

-- Título principal
Regui.CreateLabel(PlayerTab, {
	Text = "-- Player Editor --",
	Color = "White",
	Alignment = "Center"
})

-- SPEED
Regui.CreateLabel(PlayerTab, {
	Text = "Adjust your walking speed:",
	Color = "LightBlue",
	Alignment = "Left"
})
Test_.Speed.Slider = CreateSlider(PlayerTab, "Player Speed", 16, 0, 100, function(val)
	local plr = game.Players.LocalPlayer
	if plr.Character and plr.Character:FindFirstChild("Humanoid") then
		plr.Character.Humanoid.WalkSpeed = val
	end
	Test_.Speed.Value = val
end)
Test_.Speed.Slider.Set(16)

-- JUMP
Regui.CreateLabel(PlayerTab, {
	Text = "Adjust jump power:",
	Color = "LightBlue",
	Alignment = "Left"
})
Test_.Jump.Slider = CreateSlider(PlayerTab, "Player Jump", 50, 0, 200, function(val)
	local plr = game.Players.LocalPlayer
	if plr.Character and plr.Character:FindFirstChild("Humanoid") then
		plr.Character.Humanoid.JumpPower = val
	end
	Test_.Jump.Value = val
end)
Test_.Jump.Slider.Set(50)

-- CAMERA FOV
Regui.CreateLabel(PlayerTab, {
	Text = "Camera Field of View:",
	Color = "LightBlue",
	Alignment = "Left"
})
Test_.FOV = CreateSlider(PlayerTab, "Camera FOV", workspace.CurrentCamera.FieldOfView, 70, 120, function(val)
	workspace.CurrentCamera.FieldOfView = val
end)

-- NOCLIP
Regui.CreateLabel(PlayerTab, {
	Text = "Enable or disable NoClip:",
	Color = "LightBlue",
	Alignment = "Left"
})
Test_.NoClip.Toggle = CreateToggle(PlayerTab, "Enable NoClip", function(state)
	Test_.NoClip = state
end)

-- NoClip Loop
spawn(function()
	while true do
		if Test_.NoClip then
			local plr = game.Players.LocalPlayer
			local char = plr.Character
			if char then
				for _, part in pairs(char:GetDescendants()) do
					if part:IsA("BasePart") then
						part.CanCollide = false
					end
				end
			end
		end
		wait(0.1)
	end
end)

-- PLAYER TYPE
Regui.CreateLabel(PlayerTab, {
	Text = "Select a player type:",
	Color = "LightBlue",
	Alignment = "Left"
})
Test_.Type_Name = CreateSelector(PlayerTab, "Player Type", {"Default","God","Fast","Custom"}, function(val)
	Test_.Type_Name = val
	Notify("Player Type", "Changed to: " .. val)
end)


-- Model Selector
local Label_Ex_Farme = Regui.CreateLabel(ExampleTab, {Text = "Example", Color = "White", Alignment = "Center"})


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

local SliderFloatExample = Regui.CreateSliderFloat(ExampleTab, {Text = "Timer Flaot", Color = "Blue", Value = 0.1, Minimum = 0, Maximum = 1}, function(state)
	Test_.Float_Value = state
	print("Slider Float clicada! Estado:", Test_.Float_Value)

end)

local SliderIntExample = Regui.CreateSliderInt(ExampleTab, {Text = "Timer Int", Color = "Blue", Value = 1, Minimum = 0, Maximum = 100}, function(state)
	Test_.Int_Value = state
	print("Slider Int clicada! Estado:", Test_.Int_Value)

end)

local SliderOptionExample = Regui.CreateSliderOption(ExampleTab, {Text = "Timer Option", Color = "White", Background = "Blue" , Value = 1, Table = {"Melle","Fire","Aura"}}, function(state)
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

Size_Window_Choice = "Normal"

-- Função que ajusta o tamanho da janela
function Set_Size(Obj)
	if Size_Window_Choice == "Small" then
		Obj.Size = UDim2.new(0, 300, 0, 200)
	elseif Size_Window_Choice == "Normal" then
		Obj.Size = UDim2.new(0, 350, 0, 250)
	elseif Size_Window_Choice == "Large" then
		Obj.Size = UDim2.new(0, 400, 0, 300)
	end
end

-- SliderOption para escolher o tamanho da janela
local Slider_Size = Regui.CreateSliderOption(ConfigsTab, {
	Text = "Window Size",
	Color = "White",
	Background = "Blue",
	Value = 2, -- valor inicial
	Table = {"Small", "Normal", "Large"} -- opções
}, function(state)
	Size_Window_Choice = state -- atualiza a variável
	Set_Size(Window.Frame) -- aplica o tamanho na janela
end)


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
local MiniAdrian = Regui.CreateImage(ReadmeTab, {
	Name = "Mini Adrian",
	Transparence = 1,
	Alignment = "Center",
	Id_Image = "rbxassetid://127904385880677",
	Size_Image = UDim2.new(0, 100, 0, 100)
})

Regui.applyCorner(MiniAdrian)

local Hepl_Txt = [[
📘 MELOBLOX HELP GUIDE
-----------------------------

🖱️ SELECTION
• Enable "Click Select" to choose an NPC
• Click on any NPC to select its group
• All NPCs in the same folder will be highlighted

🎯 TARGET SYSTEM
• Target Mode defines how NPCs are selected:
  - Closest: nearest enemy
  - Lowest: lowest HP
  - Highest: highest HP
  - Smart: balanced (distance + HP)
  - Random: random target

⚙️ MOVEMENT MODES
• Move → uses Humanoid:MoveTo (safe)
• Fly → smooth directional velocity
• Force → advanced BodyVelocity system
• Auto → switches mode based on distance

📏 MOVEMENT SETTINGS
• Distance → how far from NPC you stay
• Height Offset → vertical positioning
• Angle → position around the NPC (circle)

🤖 AUTOMATION
• Auto Mode → automatically selects targets
• Auto Update → refresh NPC list dynamically
• Camera Lock → locks camera to target

📊 LOGS
• Shows real-time system info:
  - Current target
  - HP %
  - Mode & settings
  - Group size

💡 TIPS
• Use "Force" for smoother orbit movement
• Use "Auto" for smart farming
• Increase Range to detect more NPCs
• Combine Smart + Auto for best efficiency

⚠️ NOTES
• Script adapts to different NPC systems
• Works with custom health detection (UI / Humanoid)

-----------------------------
🔥 MeloBlox - Modular & Adaptive System
]]

local Modes_Txt = [[
🎯 TARGET MODES
--------------------------

Closest
• Targets the nearest NPC

Lowest
• Targets the lowest HP enemy

LowestPercent
• Targets the lowest HP (%)

ClosestLow
• Mix: close + low HP

Smart ⭐
• Balanced (distance + HP)
• Best overall mode

Highest
• Targets highest HP

Tank
• Focus on strongest enemies

Weakest
• Focus on easiest targets

Aggressive
• Targets dangerous + close enemies

Strongest
• Prioritizes powerful NPCs

Random
• Random target

Custom
• Based on NPC direction (threat)
]]


local function AutoResizeLabel(label, padding)
	padding = padding or 10

	local textSize = label.TextSize
	local font = label.Font
	local width = label.AbsoluteSize.X

	-- calcula o tamanho do texto
	local textBounds = game:GetService("TextService"):GetTextSize(
		label.Text,
		textSize,
		font,
		Vector2.new(width, math.huge)
	)

	-- aplica altura dinâmica
	label.Size = UDim2.new(1, -10, 0, textBounds.Y + padding)
end

local function SetLabelText(label, text)
	if label.Text ~= text then
		label.Text = text
		task.defer(function()
			AutoResizeLabel(label, 15)
		end)
	end
end

RunService.Heartbeat:Connect(function()
	if not LogsLabel then return end

	SetLabelText(HelpLabel, Hepl_Txt)
	SetLabelText(ModesLabel, Modes_Txt)
	SetLabelText(LogsLabel, BuildLogs())
end)

Notify("Version: "..ModInfo.Name,ModInfo.Version,"fa_bx_code_end",1)


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