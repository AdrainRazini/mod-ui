-- scripts/Core/Http.lua
-- novo Objetivo Fazer ser hibrido para server ou scripters
-- Obj: Conexão https + jogo 

local HttpService = game:GetService("HttpService")

local Http = {}
Http.__index = Http

-- estado interno
Http.BaseUrl = nil
Http.Endpoints = {}

-- cache simples em memória
local Cache = {}

-- ============================
-- INIT (resolver)
-- ============================

Http._initialized = false

function Http:Init(resolverUrl)
	resolverUrl = resolverUrl or "http://localhost:3000/resolver"

	if self._initialized then
		return true
	end

	local success, response = pcall(function()
		return HttpService:GetAsync(resolverUrl)
	end)

	if not success then
		warn("[Mod_UI][HTTP] Resolver offline, usando fallback")
		Http.BaseUrl = "http://localhost:3000/api"
		return false
	end

	local data = HttpService:JSONDecode(response)
	
	self.Domain = data.base and data.base.root
	self.BaseUrl = data.base and data.base.api
	self.Endpoints = data.endpoints or {}

	if not Http.BaseUrl then
		warn("[Mod_UI][HTTP] Resolver inválido")
		return false
	end

	print("[Mod_UI][HTTP] Resolver carregado:", Http.BaseUrl)
	
	self._initialized = true
	return true
end


-- ============================
-- GET raw (texto puro)
-- ============================

function Http:GetRaw(path)
	assert(Http.BaseUrl, "Http não inicializado. Chame Http:Init()")

	if Cache[path] then
		return Cache[path]
	end

	local url = Http.BaseUrl .. "/" .. path

	local success, response = pcall(function()
		return HttpService:GetAsync(url)
	end)

	if not success then
		warn("[Mod_UI][HTTP] Falha ao buscar:", path)
		return nil
	end

	Cache[path] = response
	return response
end

-- ============================
-- GET Module (Lua)
-- ============================

local RunService = game:GetService("RunService")

function Http:GetModule(path)
	if RunService:IsServer() then
		warn("[Mod_UI][HTTP] GetModule não permitido no Server")
		return nil
	end

	local code = self:GetRaw(path)
	if not code then return nil end

	local fn, err = loadstring(code)
	if not fn then
		warn("[Mod_UI][HTTP] Erro ao compilar:", err)
		return nil
	end

	local ok, result = pcall(fn)
	if not ok then
		warn("[Mod_UI][HTTP] Erro ao executar módulo:", result)
		return nil
	end

	return result
end

function Http:GetByName(name)
	local endpoint = self.Endpoints[name]
	if not endpoint then
		warn("[Mod_UI][HTTP] Endpoint não encontrado:", name)
		return nil
	end

	return self:GetRaw(endpoint:gsub(self.BaseUrl .. "/", ""))
end



return Http

--[[
-- Simulação do que Retorna
Http = {
  -- metatable
  __index = Http,

  -- controle interno
  _initialized = true,

  -- base resolvida automaticamente
  BaseUrl = "https://mod-ui.vercel.app/api",
  Domain = "https://mod-ui.vercel.app/"
  -- endpoints absolutos vindos do backend
  Endpoints = {
    health   = "https://mod-ui.vercel.app/health",
    apps     = "https://mod-ui.vercel.app/apps",
    config   = "https://mod-ui.vercel.app/config",
    resolver = "https://mod-ui.vercel.app/resolver"
  },

  -- métodos
  Init = function(self, resolverUrl) end,
  GetRaw = function(self, path) end,
  GetModule = function(self, path) end,
  GetByName = function(self, name) end
}

]]