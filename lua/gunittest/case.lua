
--- A case
---@class Cases
---@field groupname string
---@field init function?
---@field cases Case[]
local meta_cases = {}
meta_cases.__index = meta_cases

--- Creates a new test case.
---@param tbl table  #A list of cases. Each case should contain a name and function.
---@param filName string #The name of the file.
---@return Cases
function GUnitTest.NewCases(tbl, filName)
    local newCases = setmetatable({
        init = tbl.init,
        groupname = tbl.groupname or filName, 
        cases = {}
    }, meta_cases)
    for _, v in pairs(tbl.cases or {}) do
        table.insert(newCases.cases, GUnitTest.NewCase(v.name, v.func))
    end
    return newCases
end

--- A list of test
---@class Case
---@field name string
---@field func function
local case = {}
case.__index = case

--- Creates a new test case.
---@param name string
---@param func function
---@return Case
function GUnitTest.NewCase(name, func)
    if name == "Init" then
        -- Init is a reserved name
        name = "InitTest"
    end
    return setmetatable({name = name, func = func}, case)
end