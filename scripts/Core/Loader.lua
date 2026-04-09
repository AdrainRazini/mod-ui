local HttpService = game:GetService("HttpService")

local ctx = getgenv().__CTX__ or {}

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

if not success or not response or response.StatusCode ~= 200 then
    warn("Resolver falhou")
    return
end

local code = response.Body

local ok, err = pcall(function()
    loadstring(code)()
end)

if not ok then
    warn("Erro ao executar mod:", err)
end