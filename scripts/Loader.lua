--[[@Loader .. v 2.0 ]]
local HttpService = game:GetService("HttpService")

-- Multi Loader ex ..
local function getRequestFunction()
    local names = {
        "syn_request","http_request","request","httprequest","secure_request"
    }

    for _, name in ipairs(names) do
        local fn = rawget(_G, name)
        if type(fn) == "function" then
            return fn
        end
    end

    local ok, genv = pcall(function()
        return getgenv and getgenv()
    end)

    if ok and type(genv) == "table" and type(genv.request) == "function" then
        return genv.request
    end

    local executors = {"syn","fluxus","krnl","sentinel","protosmasher","rconsole"}

    for _, ex in ipairs(executors) do
        local ok2, obj = pcall(function()
            return _G[ex]
        end)

        if ok2 and type(obj) == "table" then
            local fn = obj.request
            if type(fn) == "function" then
                return fn
            end
        end
    end

    return nil
end

local requestFunction = getRequestFunction()

if not requestFunction then
    error("Executor não suporta HTTP request")
end

local ctx = getgenv().__CTX__

if type(ctx) ~= "table" then
    warn("CTX inválido")
    return
end

if not ctx.mod then
    warn("CTX sem mod")
    return
end

print("CTX:", HttpService:JSONEncode(ctx))

local success, response = pcall(function()
    return requestFunction({
        Url = "https://mod-ui.vercel.app/resolver/exec",
        url = "https://mod-ui.vercel.app/resolver/exec",
        Method = "POST",
        method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(ctx)
    })
end)

if not success then
    warn("Erro na request:", response)
    return
end

if not response then
    warn("Sem resposta")
    return
end

-- suporte a formatos diferentes de executor
local status = response.StatusCode or response.status
local body = response.Body or response.body

if status ~= 200 then
    warn("Tentando fallback GET...")

    local url = "https://mod-ui.vercel.app/resolver/exec?mod=" .. ctx.mod

    local r = requestFunction({
        Url = url,
        url = url,
        Method = "GET",
        method = "GET"
    })

    status = r.StatusCode or r.status
    body = r.Body or r.body
end

if status ~= 200 then
    warn("Erro HTTP:", status, body)
    return
end

if not body or body == "" then
    warn("Resposta vazia")
    return
end

print("Script recebido")

local fn, compileErr = loadstring(body)

if not fn then
    warn("Erro ao compilar:", compileErr)
    return
end

-- stack trace real
local ok, runtimeErr = xpcall(fn, function(err)
    return debug.traceback(err)
end)

if not ok then
    warn("Erro detalhado:\n", runtimeErr)
end

if not ok then
    warn("Erro ao executar:", runtimeErr)
end