--[[ @TaskScheduler .. v 1.0]]
-- Sistema de gerenciamento de tarefas
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Gerencier = {
	Tasks = {},
	LastRun = {},
	Metrics = {},
	FPS = 60,
	LoadFactor = 1,
	_orderedTasks = {}, -- Cache da lista ordenada (atualizada só quando necessário)
	_isDirty = true,    -- Flag para reordenar apenas quando houver mudanças
	_heartbeatConnection = nil,
	_fpsConnection = nil,
	_connections = {}    -- Para gerenciar conexões RenderStepped e outras
}

-- ========== FUNÇÕES AUXILIARES ==========
local function updateOrderedTasks(self)
	if not self._isDirty then return end
	self._orderedTasks = {}
	for name, task in pairs(self.Tasks) do
		table.insert(self._orderedTasks, {name = name, task = task})
	end
	table.sort(self._orderedTasks, function(a, b)
		return a.task.Priority > b.task.Priority
	end)
	self._isDirty = false
end

-- ========== MÉTODOS PÚBLICOS ==========
function Gerencier:AddTask(name, config)
	assert(type(name) == "string", "Task name must be a string")
	assert(type(config.Callback) == "function", "Callback must be a function")

	self.Tasks[name] = {
		Interval = config.Interval or 0.1,
		Priority = config.Priority or 1,
		Callback = config.Callback,
		Dynamic = config.Dynamic or false,
		Enabled = true,
		SafeMode = config.SafeMode ~= false -- Padrão é true (protegido)
	}

	self.LastRun[name] = 0
	self.Metrics[name] = {
		ExecTime = 0,
		Calls = 0,
		Errors = 0,
		LastError = nil
	}
	self._isDirty = true  -- Força reordenação na próxima execução
end

function Gerencier:RemoveTask(name)
	if not self.Tasks[name] then return end
	self.Tasks[name] = nil
	self.LastRun[name] = nil
	self.Metrics[name] = nil
	self._isDirty = true
end

function Gerencier:SetTaskEnabled(name, enabled)
	if self.Tasks[name] then
		self.Tasks[name].Enabled = enabled
	end
end

function Gerencier:UpdateTaskPriority(name, priority)
	if self.Tasks[name] then
		self.Tasks[name].Priority = priority
		self._isDirty = true
	end
end

function Gerencier:UpdateTaskInterval(name, interval)
	if self.Tasks[name] then
		self.Tasks[name].Interval = interval
	end
end

-- Adiciona uma tarefa de renderização com controle de taxa (throttle)
function Gerencier:AddRenderTask(name, config)
	local fn
	local fps = 30

	-- suporte a função direta
	if type(config) == "function" then
		fn = config
	else
		fn = config.Callback
		fps = config.TargetFPS or 30
	end

	assert(type(fn) == "function", "RenderTask precisa de uma função")

	local interval = 1 / fps
	local lastRun = 0

	local connection = RunService.RenderStepped:Connect(function()
		local now = tick()
		if now - lastRun >= interval then
			lastRun = now
			task.spawn(fn)
		end
	end)

	self._connections[name] = connection
	return connection
end

function Gerencier:RemoveRenderTask(name)
	if self._connections[name] then
		self._connections[name]:Disconnect()
		self._connections[name] = nil
	end
end

-- Executa uma tarefa única imediatamente em uma thread separada
function Gerencier:AddSpawnTask(fn)
	task.spawn(fn)
end

-- Cria um sub-motor que roda dentro do loop principal (sem conexões extras)
function Gerencier:CreateSubMotor(name, cfg)
	local motor = {
		Tasks = {},
		LastRun = {},
		_enabled = true,
		_parent = self
	}

	function motor:AddTask(taskName, taskCfg)
		self.Tasks[taskName] = {
			Interval = taskCfg.Interval or 0.1,
			Callback = taskCfg.Callback,
			Enabled = true
		}
		self.LastRun[taskName] = 0
	end

	function motor:RemoveTask(taskName)
		self.Tasks[taskName] = nil
		self.LastRun[taskName] = nil
	end

	-- Registra o sub-motor para ser processado pelo loop principal
	table.insert(self._subMotors or {}, motor)
	self._subMotors = self._subMotors or {}
	return motor
end

-- ========== MONITORAMENTO DE FPS (SUAVIZADO) ==========
local fpsHistory = {60, 60, 60}
local fpsIndex = 1
RunService.Heartbeat:Connect(function(dt)
	if dt > 0 then
		local currentFPS = 1 / dt
		fpsHistory[fpsIndex] = currentFPS
		fpsIndex = (fpsIndex % 3) + 1
		local avgFPS = (fpsHistory[1] + fpsHistory[2] + fpsHistory[3]) / 3
		Gerencier.FPS = math.floor(avgFPS)

		-- Ajuste suave do LoadFactor (valores entre 1 e 2)
		if avgFPS < 25 then
			Gerencier.LoadFactor = math.min(Gerencier.LoadFactor + 0.05, 2.0)
		elseif avgFPS < 40 then
			Gerencier.LoadFactor = math.min(Gerencier.LoadFactor + 0.02, 1.5)
		else
			Gerencier.LoadFactor = math.max(Gerencier.LoadFactor - 0.01, 1.0)
		end
	end
end)

-- ========== LOOP PRINCIPAL (ÚNICO) ==========
function Gerencier:Run()
	if self._heartbeatConnection then return end  -- Evita múltiplos Run()

	self._heartbeatConnection = RunService.Heartbeat:Connect(function()
		local now = tick()

		-- Atualiza lista ordenada apenas se houve mudança
		updateOrderedTasks(self)

		-- Processa tarefas principais
		for _, data in ipairs(self._orderedTasks) do
			local name = data.name
			local task = data.task

			if not task.Enabled then continue end

			local interval = task.Interval
			if task.Dynamic then
				interval = interval * self.LoadFactor
			end

			if now - self.LastRun[name] >= interval then
				self.LastRun[name] = now

				local start = tick()

				--local ok, err = pcall(task.Callback)
				local ok, err 
				if task.SafeMode then
					ok, err = pcall(task.Callback)
					if not ok then
						warn(string.format("[Gerencier] Task '%s' error: %s", name, err))
					end
					-- Tratamento de erro...
				else
					ok = true
					task.Callback() -- Execução direta, sem overhead
				end

				local execTime = tick() - start

				local metric = self.Metrics[name]
				metric.ExecTime = execTime
				metric.Calls += 1

				if not ok then
					metric.Errors += 1
					metric.LastError = err
					warn(string.format("[Gerencier] Task '%s' error: %s", name, err))
				end

				-- Se a tarefa demorar muito, pode causar lag; opcionalmente poderíamos fazer task.defer
			end
		end

		-- Processa sub-motores
		if self._subMotors then
			for _, motor in ipairs(self._subMotors) do
				if motor._enabled then
					for tName, t in pairs(motor.Tasks) do
						if t.Enabled then
							if now - motor.LastRun[tName] >= t.Interval then
								motor.LastRun[tName] = now
								pcall(t.Callback)
							end
						end
					end
				end
			end
		end
	end)
end

-- ========== LIMPEZA ==========
function Gerencier:Destroy()
	if self._heartbeatConnection then
		self._heartbeatConnection:Disconnect()
		self._heartbeatConnection = nil
	end
	for _, conn in pairs(self._connections) do
		conn:Disconnect()
	end
	table.clear(self.Tasks)
	table.clear(self._orderedTasks)
	table.clear(self._subMotors or {})
end

return Gerencier