
---@class GU_caseResult
---@field name string
---@field success boolean
---@field error GUnitError?
---@field cost number
---@field line number?
---@field file string?
local caseResult = {}
caseResult.__index = caseResult

---@class GU_fileResult
---@field results GU_caseResult[]
---@field groupname string?
local results = {}
results.__index = results

---Adds a new result to the results list.
---@param name string
---@param success boolean
---@param cost number
---@param error GUnitError?
function results:AddNewResult(name, success, cost, error)
    table.insert(self.results, setmetatable({name = name, success = success, cost = cost, error = error}, caseResult))
    self.success = self.success and success
    self.cost = (self.cost or 0) + cost
end
---Includes a file and runs the tests in it.
---@param path any
---@return GU_fileResult
function GUnitTest.include(path)
    local result = setmetatable({file = path, results = {}, groupname = nil, cost = 0}, results)
    local env = GUnitTest.CreateNewEnvironment()
    setfenv(0, env.ENV)
    local data = include(path)
    setfenv(0, env.DefaultEnv)
    if not data then
        result:AddNewResult("Compile Error", false, 0, {file = path, error = "File not found", lines = {}, line = 0, failedTest = false})
        return result
    end

    local cases = GUnitTest.NewCases(data, string.GetFileFromFilename(path))
    result.groupname = cases.groupname
    if cases.init then
        local s = SysTime()
        local success, err = env:TestFunction(path, cases.init)
        local cost = SysTime() - s
        if success then
            result:AddNewResult("Init", true, cost)
        else
            result:AddNewResult("Init", false, cost, err)
            return result
        end
    end
    for _, v in pairs(cases.cases) do
        local s = SysTime()
        local success, err = env:TestFunction(path, v.func)
        local cost = SysTime() - s
        if success then
            result:AddNewResult(v.name, true, cost)
        else
            result:AddNewResult(v.name, false, cost, err)
        end
    end
    return result
end

---@class GU_compiledGroup
---@field success boolean
---@field cost number
---@field results GU_fileResult[]

---@class CompileResults
---@field titles table<string, GU_compiledGroup>
---@field cost number
---@field success boolean

---Runs all tests and returns the results.
---@param comResults CompileResults
---@param folder string
local function runTestFolder(comResults, folder)
    local files = file.Find("unittest/" .. folder .. "/*.lua", "LUA")
    for _, file in pairs(files or {}) do
        local r = GUnitTest.include("unittest/" .. folder .. "/" .. file)
        if not r or not r.groupname then continue end -- No tests found

        local title = comResults.titles[folder]
        if not title then
            title = {results = {}, success = true, cost = 0}
            comResults.titles[folder] = title
        end
        local group = title.results[r.groupname]
        if not group then
            group = {results = {}, success = true, cost = 0}
            title.results[r.groupname] = group
        end
        for _, v in pairs(r.results) do
            table.insert(group.results, v)
            group.success = group.success and v.success
            group.cost = group.cost + v.cost
            title.cost = title.cost + v.cost
        end
        comResults.titles[folder].success = comResults.titles[folder].success and group.success
        comResults.success = comResults.success and group.success
        comResults.cost = comResults.cost + group.cost
    end
end

---Runs all tests and returns the results.
---@return CompileResults
function GUnitTest.RunAllTests()
    ---@type CompileResults
    local results = {titles = {}, cost = 0, success = true}
    local _, folders = file.Find("unittest/*", "LUA")
    for _, folder in pairs(folders or {}) do
        runTestFolder(results, folder)
    end
    return results
end

---Runs all tests in a folder and returns the results.
---@param folder string
---@return CompileResults
function GUnitTest.RunTests(folder)
    ---@type CompileResults
    local results = {titles = {}, cost = 0, success = true}
    runTestFolder(results, folder)
    return results
end

local function niceName(str)
    return str:sub(1, 1):upper() .. str:sub(2):gsub("%u", " %1")
end

local gray = Color(155,155,155)
local errColor = Color(255, 105, 105)
local successColor = Color(0, 255, 0)

---Prints the results of the tests to the console.
---@param foldOut boolean? If true, the results will be folded out.
---@param testResult CompileResults
function GUnitTest.PrintResults(foldOut, testResult)
    MsgC(color_white, string.rep("=", 40) .. "\n")
    MsgC("GUnitTest\t")
    MsgC(gray, "Duration: " .. string.format("%.6f", testResult.cost) .. "s\t")
    if table.Count(testResult.titles) == 0 then
        MsgC(errColor, "No tests found\n")
        return
    elseif testResult.success then
        MsgC(successColor, "Passed\n")
    else
        MsgC(errColor, "Failed\n")
    end

    for title, res in pairs(testResult.titles) do
        MsgN()
        MsgC(color_white, string.format("└─ %s: ", niceName(title)))
        MsgC(gray, string.format("Duration: %.6fs\t", res.cost))
        if res.success then
            MsgC(successColor, "Passed\n")
        else
            MsgC(errColor, "Failed\n")
        end

        -- Print each group
        local n, i = table.Count(res.results), 0
        for group, gres in pairs(res.results) do
            i = i + 1
            local last = i == n
            local start = last and "└─ " or "├─ "
            local lineChar = last and " " or "│"
            MsgC(color_white, string.format("\t%s%s: \t", start, niceName(group)))
            MsgC(gray, string.format("Duration: %.6fs\t",gres.cost))
            if gres.success then
                MsgC(successColor, "Passed\n")
                if not foldOut then continue end
            else
                MsgC(errColor, "Failed\n")
            end
            -- Find longest name
            local longestName = 0
            for _, value in pairs(gres.results) do
                longestName = math.max(longestName, #value.name) + 1
            end
            for key, value in ipairs(gres.results) do
                local text = niceName(value.name)
                MsgC(color_white, string.format("\t%s\t%s %s%s ",
                    lineChar,
                    key == #gres.results and "└" or "├",
                    text,
                    string.rep(' ', longestName - #text)))

                MsgC(gray, string.format("Duration: %.6fs\t", value.cost))
                if value.success then
                    MsgC(successColor, "Passed\n")
                else
                    MsgC(errColor, value.error.failedTest and "Failed\n" or "Error\n")
                end
            end
        end
    end

    -- When done, print all errors
    MsgC(color_white, string.rep("=", 40) .. "\n")
    for _, res in pairs(testResult.titles) do
        for _, gres in pairs(res.results) do
            for _, case in pairs(gres.results) do
                if not case.success then
                    if case.error.failedTest then
                        MsgC(errColor, "Failed: ")
                    else
                        MsgC(errColor, "Error: ")
                    end
                    MsgC(color_white, case.error.file .. ":" .. case.error.line.."\n")
                    for _, line in pairs(case.error.lines) do
                        MsgC(gray, line)
                    end
                    if case.error.errorPos then
                        local n = case.error.errorPos - #case.error.error - 2
                        if n < 0 then
                            -- Left padding
                            MsgC(errColor, string.rep(" ", case.error.errorPos) .. "^ ")
                            MsgC(errColor, case.error.error)
                        else
                            -- Right padding
                            MsgC(errColor, string.rep(" ", n))
                            MsgC(errColor, case.error.error)
                            MsgC(errColor, " ^")
                        end
                    else
                        MsgC(errColor, case.error.error)
                    end
                    MsgN()
                end
            end
        end
    end
end