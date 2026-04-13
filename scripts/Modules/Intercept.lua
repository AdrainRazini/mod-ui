-- [[@Intercept .. v 1.0]]
-- Sistema de interceptação de remotes (InvokeServer / FireServer)

local Intercept = {}
Intercept.__index = Intercept

-- =========================
-- CONSTRUCTOR
-- =========================
function Intercept.new()
    local self = setmetatable({}, Intercept)

    self.Cache = {}
    self.Hooks = {}
    self.TempList = {}

    self.Enabled = false
    self._hooked = false

    return self
end

-- =========================
-- CACHE
-- =========================
function Intercept:AddArgs(key, remote, ...)
    self.Cache[key] = {
        Remote = remote,
        Args = {...}
    }
end

function Intercept:GetArgs(key)
    return self.Cache[key]
end

function Intercept:ClearArgs(key)
    if key then
        self.Cache[key] = nil
    else
        self.Cache = {}
    end
end

-- =========================
-- HOOKS
-- =========================
function Intercept:AddHook(name, callback)
    self.Hooks[name] = callback
end

function Intercept:RemoveHook(name)
    self.Hooks[name] = nil
end

-- =========================
-- TEMP LIST
-- =========================
function Intercept:AddTemp(name, duration)
    self.TempList[name] = true

    if duration then
        task.delay(duration, function()
            self.TempList[name] = nil
        end)
    end
end

function Intercept:RemoveTemp(name)
    self.TempList[name] = nil
end

-- suporta match parcial (upgrade)
function Intercept:IsTemp(name)
    for tempName in pairs(self.TempList) do
        if tempName == name then
            return true -- match exato
        end

        if string.find(string.lower(name), string.lower(tempName)) then
            return true -- match parcial
        end
    end
    return false
end

-- =========================
-- REPLAY
-- =========================
function Intercept:Replay(key)
    local data = self:GetArgs(key)
    if not data then return end

    local remote = data.Remote
    local args = data.Args

    if not remote then return end

    if remote:IsA("RemoteEvent") then
        return remote:FireServer(unpack(args))
    else
        return remote:InvokeServer(unpack(args))
    end
end
-- =========================
-- LOG
-- =========================
function Intercept:LogAll(name, ...)
	print("Intercept", name)
	for i,v in ipairs({...}) do
		print("  Arg", i, ":", v)
	end
end
-- =========================
-- EXECUTE MANUAL
-- =========================
function Intercept:Execute(name, remote, ...)
    local args = {...}

    -- fallback
    if not remote then
        local data = self:GetArgs(name)
        if data then
            remote = data.Remote
            args = data.Args
        else
            return warn("Execute falhou: sem remote")
        end
    end

    -- apenas executa
    if remote:IsA("RemoteEvent") then
        return remote:FireServer(unpack(args))
    else
        return remote:InvokeServer(unpack(args))
    end
end

-- =========================
-- GLOBAL HOOK (__namecall)
-- =========================
function Intercept:Enable()
    if self._hooked then return end

    local mt = getrawmetatable(game)
    local old = mt.__namecall

    setreadonly(mt, false)

    --[[mt.__namecall = newcclosure(function(selfRemote, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "InvokeServer" or method == "FireServer" then
            --local name = selfRemote.Name
            local name = selfRemote:GetFullName()

            if self.Enabled and InterceptInstance then
                local instance = InterceptInstance

                if instance:IsTemp(name) then
                    instance:AddArgs(name, selfRemote, unpack(args))
                    instance:LogAll(name, unpack(args))
                end

                if instance.Hooks[name] then
                    local newArgs = instance.Hooks[name](unpack(args))
                    if newArgs then
                        return old(selfRemote, unpack(newArgs))
                    end
                end
            end
        end

        return old(selfRemote, ...)
    end)]]

    --mt.__namecall = newcclosure(function(selfRemote, ...)
    mt.__namecall = function(selfRemote, ...)
    local method = getnamecallmethod()
    local args = {...}

    if method == "InvokeServer" or method == "FireServer" then
        --local name = selfRemote:GetFullName()
        local name = selfRemote.Name

        if self.Enabled and InterceptInstance then
            local instance = InterceptInstance

            if instance:IsTemp(name) then
                instance:AddArgs(name, selfRemote, unpack(args))
                instance:LogAll(name, unpack(args))
            end
        end
    end

    -- 🔒 SEMPRE chama original (SEM ALTERAÇÃO)
    return old(selfRemote, ...)
end

    setreadonly(mt, true)

    self._hooked = true
end

-- =========================
-- TOGGLE
-- =========================
function Intercept:SetEnabled(state)
    self.Enabled = state
end

-- =========================
-- SINGLETON (global access)
-- =========================
InterceptInstance = Intercept.new()

return InterceptInstance