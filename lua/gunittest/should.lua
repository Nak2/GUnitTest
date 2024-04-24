
---@class UnitTest
---@field Result any
---@field protected __type string
---@field protected __errorMessage string?
---@field protected __index any?
local unitObj = {}
unitObj.__index = function(tab, key)
    if key == "And" then return tab end
    return unitObj[key]
end

---@class UnitResult
---@field And UnitTest
---@field Result any
---@field protected __index UnitResult
local unitResult = {}
unitResult.__index = unitResult

---Creates a new Should object.
---@param obj any
---@return UnitTest
function GUnitTest.Should(obj)
    return setmetatable({Result = obj, __errorMessage = nil, __type = type(obj)}, unitObj)
end

---Swaps the unittest to unitResult.
---@param unitTest UnitTest
---@return UnitResult
local function swap(unitTest)
    return setmetatable({And = unitTest, Result = unitTest.Result}, unitResult)
end

---Sets the error message of the object if the assertion fails.
---@param msg string?
---@return UnitResult
function unitObj:WithMessage(msg)
    self.__errorMessage = msg
    return swap(self)
end

---Throws an error with the error message (Unless WithMessage is used).
---@param msg string
function unitObj:Assert(msg)
    assert(false, debug.traceback(self.__errorMessage or msg))
end

--#region Boolean / nil Assertions

---Asserts that the object is true.
---@return UnitResult
function unitObj:BeTrue()
    if self.Result ~= true then
        self:Assert(string.format("Expected true, but got %s", tostring(self.Result)))
    end
    return swap(self)
end

---Asserts that the object is false.
---@return UnitResult
function unitObj:BeFalse()
    if self.Result ~= false then
        self:Assert(string.format("Expected false, but got %s", tostring(self.Result)))
    end
    return swap(self)
end

---Asserts that the object is nil.
---@return UnitResult
function unitObj:BeNil()
    if self.Result ~= nil then
        self:Assert(string.format("Expected nil, but got %s", tostring(self.Result)))
    end
    return swap(self)
end

--#endregion

--#region Operator Assertions

---Check if the tables content match
---@param tab1 table
---@param tab2 table
---@return string?
---@return string?
local function checkTableMatch(tab1, tab2)
    local totalKeys = {}
    for k, _ in pairs(tab1) do
        totalKeys[k] = true
    end
    for k, _ in pairs(tab2) do
        totalKeys[k] = true
    end
    for k, _ in pairs(totalKeys) do
        local v, v2 = tab1[k], tab2[k]
        if type(v) == "table" and type(v2) == "table" then
            local misA, misB = checkTableMatch(v, v2)
            if misA or misB then
                return string.format("[%s]%s", k, misA), string.format("[%s]%s", k, misB)
            end
        elseif v ~= v2 then
            return string.format("[%s] = %s", k, v), string.format("[%s] = %s", k, v2)
        end
    end
end

---Asserts that the object be equal to the value.
---
---**Note:** If both values are tables, it will check if the tables match.
---@param value any
---@return UnitResult
function unitObj:Be(value)
    -- If both values are tables, we need to check if they match.
    if self.__type == "table" and type(value) == "table" then
        local misA, misB = checkTableMatch(value, self.Result)
        if misA or misB then
            self:Assert(string.format("Expected %s, but got %s", misA, misB))
        end
        return swap(self)
    end
    if self.Result ~= value then
        self:Assert(string.format("Expected %s, but got %s", tostring(value), tostring(self.Result)))
    end
    return swap(self)
end

---Asserts that the object be greater than the value.
---@param value number|any
---@return UnitResult
function unitObj:BeGreaterThan(value)
    if self.Result <= value then
        self:Assert(string.format("Expected %s to be greater than %s", tostring(self.Result), tostring(value)))
    end
    return swap(self)
end

---Asserts that the object be less than the value.
---@param value number|any
---@return UnitResult
function unitObj:BeLessThan(value)
    if self.Result >= value then
        self:Assert(string.format("Expected %s to be less than %s", tostring(self.Result), tostring(value)))
    end
    return swap(self)
end

function unitObj:BeGreaterThanOrEqual(value)
    if self.Result < value then
        self:Assert(string.format("Expected %s to be greater than or equal to %s", tostring(self.Result), tostring(value)))
    end
    return swap(self)
end

function unitObj:BeLessThanOrEqual(value)
    if self.Result > value then
        self:Assert(string.format("Expected %s to be less than or equal to %s", tostring(self.Result), tostring(value)))
    end
    return swap(self)
end

--#endregion

--#region Type Assertions

---Asserts that the object be of the type.
---@param _type string
---@return UnitResult
function unitObj:BeOfType(_type)
    if self.__type ~= _type then
        self:Assert(string.format("Expected object to be of type %s, but got %s", _type, self.__type))
    end
    return swap(self)
end

---Asserts that the object be a table.
---@return UnitResult
function unitObj:Exist()
    if self.Result == nil then
        self:Assert("Expected object to exist")
    end
    return swap(self)
end

---Asserts that the object not exist.
---@return UnitResult
function unitObj:NotExist()
    if self.Result ~= nil then
        self:Assert(string.format("Expected object to not exist, but got %s", tostring(self.Result)))
    end
    return swap(self)
end

--#endregion

--#region Table Assertions

---Asserts that the object be empty.
---@return UnitResult
function unitObj:BeEmpty()
    if self.__type == "string" then
        if #self.Result ~= 0 then
            self:Assert(string.format("Expected string to be empty, but got %d characters", #self.Result))
        end
    else
        if table.Count(self.Result) ~= 0 then
            self:Assert(string.format("Expected object to be empty, but got %d elements", #self.Result))
        end
    end
    return swap(self)
end

---Asserts that the object not be empty.
---@return UnitResult
function unitObj:NotBeEmpty()
    if self.__type == "string" then
        if #self.Result == 0 then
            self:Assert("Expected string to not be empty")
        end
    else
        if table.Count(self.Result) == 0 then
            self:Assert("Expected object to not be empty")
        end
    end
    return swap(self)
end

---Asserts that the object exist in the the given table.
---@param tbl table
---@return UnitResult
function unitObj:BeIn(tbl)
    for _, v in pairs(tbl) do
        if v == self.Result then
            return swap(self)
        end
    end
    self:Assert("Expected object to be in table")
    return swap(self)
end

---Asserts that the object does not exist in the given table.
---@param tbl table
---@return UnitResult
function unitObj:BeNotIn(tbl)
    for _, v in pairs(tbl) do
        if v ~= self.Result then
            self:Assert(string.format("Expected object not to be in the table, but got %s", tostring(self.Result)))
        end
    end
    return swap(self)
end

---Asserts that the table contains each of the given values.
---@param ... any
function unitObj:Contain(...)
    if self.__type ~= "table" then
        self:Assert("Expected object to be a table")
    end
    local tab = {...}
    for _, v in pairs(tab) do
        local found = false
        for _, val in pairs(self.Result) do
            if val == v then
                found = true
                break
            end
        end
        if not found then
            self:Assert(string.format("Expected object to contain '%s'", tostring(v)))
        end
    end
    return swap(self)
end

---Asserts that the object only contains unique values.
---@return UnitResult
function unitObj:BeUniqueItems()
    local tbl = {}
    for _, v in pairs(self.Result) do
        if tbl[v] then
            self:Assert(string.format("Expected object to have unique items, but found '%s' multiple times", tostring(v)))
        end
        tbl[v] = true
    end
    return swap(self)
end

---Asserts that the object be ordered.
---@return UnitResult
function unitObj:BeOrdered()
    for k, v in pairs(self.Result) do
        if k == 1 then continue end
        local last = self.Result[k - 1]
        if last and last > v then
            self:Assert(string.format("Expected object to be ordered, but '%s' is greater than '%s'", tostring(last), tostring(v)))
        end
    end
    return swap(self)
end

---Asserts that the object only contains the same values.
---@return UnitResult
function unitObj:BeSameItems()
    local last
    for _, v in pairs(self.Result) do
        if last == nil then
            last = v
            continue
        elseif last ~= v then
            self:Assert(string.format("Expected object to only contain '%s', but found '%s'", tostring(last), tostring(v)))
        end
    end
    return swap(self)
end

---Asserts that the object have a specific count.
---@param count number
---@return UnitResult
function unitObj:HaveCount(count)
    local num = table.Count(self.Result)
    if num ~= count then
        self:Assert(string.format("Expected object to have %d elements, but got %d", count, num))
    end
    return swap(self)
end

---Asserts that the object have a specific key. If val is provided, it will check if the value is the same.
---@param key any # The key to check for.
---@param val any? # The value to check for.
---@return UnitResult
function unitObj:ContainKey(key, val)
    if not self.Result[key] then
        self:Assert(string.format("Expected object to contain key [%s]", tostring(key)))
    end
    if val ~= nil then
        if self.Result[key] ~= val then
            self:Assert(string.format("Expected [%s] to be '%s', but got '%s'", tostring(key), tostring(val), tostring(self.Result[key])))
        end
    end
    return swap(self)
end

---Asserts that the object have specific keys.
---@param ... any # The keys to check for.
---@return UnitResult
function unitObj:ContainKeys(...)
    local keys = {...}
    for _, key in pairs(keys) do
        if not self.Result[key] then
            self:Assert(string.format("Expected object to contain key [%s]", tostring(key)))
        end
    end
    return swap(self)
end

---Asserts a custom function on the object. Returning false will throw an error.
---@param fun function
---@return UnitResult
function unitObj:Pass(fun)
    if not fun(self.Result) then
        self:Assert("Expected object to pass the function")
    end
    return swap(self)
end

--#endregion

--#region String Assertions

---Asserts that the object be a string.
---@return UnitResult
function unitObj:BeString()
    if self.__type ~= "string" then
        self:Assert(string.format("Expected object to be a string, but got %s", self.__type))
    end
    return swap(self)
end

---Asserts that the object starts with the value.
---@param value string
---@return UnitResult
function unitObj:StartWith(value)
    if self.__type ~= "string" then
        self:Assert(string.format("Expected object to be a string, but got %s", self.__type))
    end
    if self.Result:sub(1, #value) ~= value then
        self:Assert("Expected object to start with " .. tostring(value))
    end
    return swap(self)
end

---Asserts that the object ends with the value.
---@param value string
---@return UnitResult
function unitObj:EndWith(value)
    if self.__type ~= "string" then
        self:Assert(string.format("Expected object to be a string, but got %s", self.__type))
    end
    if self.Result:sub(-#value) ~= value then
        self:Assert("Expected object to end with " .. tostring(value))
    end
    return swap(self)
end

---Asserts that the object contains the string
---@param value string
---@return UnitResult
function unitObj:ContainString(value)
    if self.__type == "string" then
        if not string.find(self.Result, value) then
            self:Assert("Expected string to contain " .. tostring(value))
        end
    else -- Check if object has a key with the value
        for _, v in pairs(self.Result) do
            if string.find(v, value) then
                return swap(self)
            end
        end
        self:Assert("Expected object to contain " .. tostring(value))
    end
    return swap(self)
end

--#endregion
