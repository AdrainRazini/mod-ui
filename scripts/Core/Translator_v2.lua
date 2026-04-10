--[[@translator .. v 4.0]]

local function getConfig()
    local ctx = getgenv and getgenv().__CTX__ or {}
    return ctx.translator or {}
end
 -- contextos aplicados remotamente
local Config = getConfig()

local Translator = {}
local Cache = {}
local Pending = {}
local LastRequest = 0

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

local function getLang()
    local Config = getConfig()
    return Config.target ~= "auto"
        and Config.target
        or string.sub(player.LocaleId, 1, 2)
end
--local targetLang = string.sub(player.LocaleId, 1, 2)
local targetLang = getLang()

local requestFunction =
(syn and syn.request)                 -- Synapse X (legacy)
or
(syn_request)                         -- algumas builds antigas
or
(http_request)                        -- padrão comum
or
(request)                             -- fallback global
or
(httprequest)                         -- variação sem underscore
or
(fluxus and fluxus.request)          -- Fluxus
or
(krnl and krnl.request)              -- KRNL
or
(sentinel and sentinel.request)      -- Sentinel (antigo)
or
(protosmasher and protosmasher.request) -- ProtoSmasher
or
(is_sirhurt_closure and request)     -- SirHurt (hacky check)
or
(secure_request)                     -- alguns privados usam isso
or
(rconsole and rconsole.request)      -- raríssimo / custom
or
(getgenv().request)                  -- alguns loaders injetam aqui

--local BASE_URL = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. targetLang .. "&dt=t&q="

local function getBaseUrl()
    local Config = getConfig()
    local lang = Config.target ~= "auto"
        and Config.target
        or string.sub(player.LocaleId, 1, 2)

    return "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&tl=" .. lang .. "&dt=t&q="
end

if not requestFunction then
    error("Executor não suporta HTTP request")
end

local function normalizeResponse(res)
    if typeof(res) ~= "table" then
        return { Body = "" }
    end

    return {
        Body = res.Body or res.body or res.ResponseBody or "",
        StatusCode = res.StatusCode or res.status or res.Status or 0,
        Headers = res.Headers or res.headers or {}
    }
end

local function normalizeKey(str)
    return string.lower(string.gsub(str, "^%s*(.-)%s*$", "%1"))
end

local function throttle()
    local now = tick()
    local delta = now - LastRequest
    local Config = getConfig()
    local delay = Config.throttle or 0.15

    if delta < delay then
     task.wait(delay - delta)
    end

    LastRequest = tick()
end

local function release(key)
    Pending[key] = nil
end

-- Tradução segura
function Translator.TranslateText(text)

    local Config = getConfig()

    if Config.enabled == false then
        return text
    end
    -- 1. Validação IMEDIATA (mais leve primeiro)
    if not text or text == "" or #text < 2 then
        return text
    end

    -- 2. Heurística (evita request inútil)
    if getLang() == "en" and not string.find(text, "[^\x00-\x7F]") then
        return text
    end

    --local key = normalizeKey(text)

    local lang = getLang()
    local key = lang .. ":" .. normalizeKey(text)

    --3. Cache (ultra rápido)
    if Cache[key] then
        return Cache[key]
    end

    -- 4. Pending (evita duplicação)
    if Pending[key] then
         local timeout = getConfig().timeout or 5
          local start = tick()
          while Pending[key] and (tick() - start) < timeout do
          task.wait()
          end
         if Cache[key] then return Cache[key] end
        return text
    end

    

    Pending[key] = true

    -- 5. Throttle (só quando realmente vai fazer request)
    throttle()

    local translated = text -- fallback padrão

    local successRequest, result = pcall(function()

    --local url = BASE_URL .. HttpService:UrlEncode(text)
    local url = getBaseUrl() .. HttpService:UrlEncode(text)

        local response = requestFunction({
            Url = url,
            url = url,
            Method = "GET",
            method = "GET"
        })

        response = normalizeResponse(response)

        if response.Body == "" then
            return nil
        end

        --local data = HttpService:JSONDecode(response.Body)

        local successDecode, data = pcall(HttpService.JSONDecode, HttpService, response.Body)

        if not successDecode or not data or not data[1] or not data[1][1] then
            return nil
        end

        --return data[1][1][1] -- v1
        local full = ""
        for _, part in ipairs(data[1]) do
          full = full .. (part[1] or "")
        end

        return full
    end)

    release(key) -- Limpar 

    -- 🔹 6. Aplicação segura
    if successRequest and result and result ~= "" then
        translated = result
        Cache[key] = translated
    end

    -- 🔹 7. Cleanup SEMPRE
    Pending[key] = nil

    return translated
end

-- 🔹 AutoTranslate estável (NÃO quebra HUD)
function Translator.AutoTranslate(gui, searchMode)
    searchMode = searchMode or "Class"

    if not gui or typeof(gui.GetDescendants) ~= "function" then
        warn("[AutoTranslate] GUI inválido")
        return
    end

    local descendants = gui:GetDescendants()

    for i = 1, #descendants do
        local obj = descendants[i]
    --for _, obj in ipairs(gui:GetDescendants()) do
        if obj:IsA("TextLabel") or obj:IsA("TextButton") then

            if obj:GetAttribute("Translated") then
                continue
            end

            if string.find(obj.Name, "Translate_Off") then
                continue
            end

            local textToTranslate =
                (searchMode == "Name" and obj.Name)
                or (searchMode == "All" and (obj.Text ~= "" and obj.Text or obj.Name))
                or obj.Text

            if textToTranslate and #textToTranslate > 1 then

            local objRef = obj
            --task.spawn(function()
            task.defer(function()
               local translated = Translator.TranslateText(textToTranslate)
                if objRef and objRef.Parent and objRef:IsA("TextLabel") then
                  objRef.Text = translated
                  objRef:SetAttribute("Translated", true)
                  end
            end)

             --[[
             local translated = Translator.TranslateText(textToTranslate)
             obj.Text = translated
             obj:SetAttribute("Translated", true)
             task.wait(0.15) --(anti-crash HUD)
             ]]

            end
        end
    end
end

return Translator