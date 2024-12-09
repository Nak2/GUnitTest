
local net = {}
net.__index = function()
    error("Attempt to access net library in a test environment.")
end

---The current environment.
---@type GU_Env?
GUnitTest.CURRENTENV = nil

--- Creates a new environment, copying the global environment. Any changes to the environment will not affect the global environment.
---@return table
local function createNew()
    local newEnv = {}
    newEnv._UNITTEST = true
    newEnv.Should = GUnitTest.Should
    newEnv.net = setmetatable({}, net) -- Prevent access to net library
    newEnv.prints = {}
    newEnv.print = function(...)
        local args = {...}
        local tab = {}
        for index, value in ipairs(args) do
            tab[index] = tostring(value)
        end
        newEnv.prints[#newEnv.prints + 1] = table.concat(tab, "\t")
    end
    return setmetatable(newEnv, {__index = _G, __newindex = rawset})
end

---Annotation support for within environment.
local function annotationSupport()
    Should = GUnitTest.Should
end

---@class GU_Env
---@field ENV table
---@field DefaultEnv table
local env = {}
env.__index = env

---Creates a new environment.
---@return GU_Env
function GUnitTest.CreateNewEnvironment()
    return setmetatable({ENV = createNew(), DefaultEnv = _G}, env)
end

_GUNITTEST_PRINT = _GUNITTEST_PRINT or print

function env:SetEnv(func)
    self.ENV.prints = {}
    GUnitTest.CURRENTENV = self.ENV
    print = self.ENV.print
    setfenv(func or 0, self.ENV)
end

---Resets the environment to the default environment.
---@param func function
function env:Reset(func)
    setfenv(func or 0, self.DefaultEnv)
    GUnitTest.CURRENTENV = nil
    print = _GUNITTEST_PRINT
end

---Runs the function in the environment. Returns true on success, false on failure. Second return value is the error message.
---@param fil string #The file path
---@param func function #The function to run
---@param ... any #Arguments to pass to the function
---@return boolean #Success
---@return GUnitError? #Error
function env:TestFunction(fil, func, ...)
    GUnitTest.CURRENTENV = self.ENV
    self:SetEnv(func)
    local success, errorMessage = pcall(func, ...)
    self:Reset(func)
    GUnitTest.CURRENTENV = nil
    if not success then
        return false, GUnitTest.ErrorHandle(fil, errorMessage)
    end
    return true
end