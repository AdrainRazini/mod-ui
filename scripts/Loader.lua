local HttpService = game:GetService("HttpService")

local request =
    (syn and syn.request)
    or (http and http.request)
    or http_request
    or request
    or (fluxus and fluxus.request)
    or (krnl and krnl.request)

if not request then
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
    return request({
        Url = "https://mod-ui.vercel.app/resolver/exec",
        Method = "POST",
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
    warn("Erro HTTP:", status, body)
    return
end

if not body or body == "" then
    warn("Resposta vazia")
    return
end

print("Script recebido")

local ok, err = pcall(function()
    loadstring(body)()
end)

if not ok then
    warn("Erro ao executar:", err)
end