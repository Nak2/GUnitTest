
---@class GUnitErrorHeader
---@field file string
---@field line number
---@field var string? #The variable that caused the error
---@field error string
---@field failedTest boolean #If the error is from a failed test

---Locates the problem in the error message.
---@param str string
---@return GUnitErrorHeader
local function locateProblem(str)
    local split = string.Explode("\n", str)
    -- First line is file:line:error message
    local header = string.Explode(":", table.remove(split, 1))

    local fil = header[1]
    local line = header[2]
    local err = header[3]
    local var = string.match(err, "'(.-)'")
    local failedTest = false

    if #split > 0 then
        -- We need to remove any should.lua lines
        for _, v in pairs(split) do
            v = v:Trim()
            if v == "stack traceback:" then
                continue
            end
            -- If string starts with "addons/gunittest" ignore
            if string.match(v, "^addons/gunittest") then
                var = string.match(v, "'(.-)'")
                continue
            end
            failedTest = true
            header = string.Explode(":", v)
            if #header > 1 then
                fil = header[1]
                line = header[2]
                break
            end
        end
    end
    return {file = fil, line = line, error = err, var = var, failedTest = failedTest}
end

--- Retrive the 3 lines before and after the error line.
local function getLines(fil, line)
    local lines = {}
    local file = file.Open(fil, "r", "GAME")
    if not file then
        return {"","File not found",""}
    end
    for i = 1, line do
        if i < line - 4 then
            file:ReadLine()
            continue
        end
        table.insert(lines, i .. (i < 10 and " " or "") .. "| " .. file:ReadLine())
    end
    file:Close()
    return lines
end

---Shows the error location.
---@param header GUnitErrorHeader
---@param lines string[]
local function findErrorLocation(header, lines)
    -- Locate the position of the error. Usually the variable is surrounded by ' or "
    local pos = 0
    -- If var is found, we can try to locate the position of the error
    if header.var then
        local pattern = "[^%a]" .. header.var .. "[^%a]"
        pos = (string.find(" " .. lines[#lines] .. " ", pattern) or 1) - 1
    end
    return pos > 0 and pos or nil
end

local function niceError(str)
    local s = str:sub(1, 1):upper() .. str:sub(2)
    if s:sub(-1) ~= "." then
        s = s .. "."
    end
    return s
end

---@class GUnitError
---@field file string
---@field lines string[]
---@field line number
---@field error string
---@field errorPos number?
---@field failedTest boolean

---Handles the error message.
---@param fil string
---@param str string
---@return GUnitError
function GUnitTest.ErrorHandle(fil, str)
    local header = locateProblem(str)
    local lines = getLines(header.file, header.line)
    local errorPos = findErrorLocation(header, lines)
    return {file = fil, lines = lines, error = niceError(header.error:Trim()), errorPos = errorPos, line = header.line, failedTest = header.failedTest}
end