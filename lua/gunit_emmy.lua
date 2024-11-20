--- Emmy support. You can copy this file into your project and use it to get autocompletion in your IDE.
--- @meta

---@class GUnit.UnitTest
---@field WithMessage fun(self: GUnit.UnitTest, message: string): GUnit.UnitResult # Sets a custom error message.
---@field Exist fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts that the object exists.
---@field NotExist fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts that the object does not exist.
---@field Be fun(self: GUnit.UnitTest, value: any): GUnit.UnitResult # Asserts equality.
---@field BeOfType fun(self: GUnit.UnitTest, _type: string): GUnit.UnitResult # Asserts the object's type.
---@field BeTrue fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object is true.
---@field BeFalse fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object is false.
---@field BeNil fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object is nil.
---@field BeLessThan fun(self: GUnit.UnitTest, value: number): GUnit.UnitResult # Asserts the object is less than a value.
---@field BeLessThanOrEqual fun(self: GUnit.UnitTest, value: number): GUnit.UnitResult # Asserts the object is less than or equal to a value.
---@field BeGreaterThan fun(self: GUnit.UnitTest, value: number): GUnit.UnitResult # Asserts the object is greater than a value.
---@field BeGreaterThanOrEqual fun(self: GUnit.UnitTest, value: number): GUnit.UnitResult # Asserts the object is greater than or equal to a value.
---@field Contain fun(self: GUnit.UnitTest, ...: any): GUnit.UnitResult # Asserts the object contains specified values.
---@field ContainKey fun(self: GUnit.UnitTest, key: any, val: any?): GUnit.UnitResult # Asserts the object has a key with an optional value.
---@field ContainKeys fun(self: GUnit.UnitTest, ...: any): GUnit.UnitResult # Asserts the object contains specific keys.
---@field BeEmpty fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object is empty.
---@field NotBeEmpty fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object is not empty.
---@field BeUniqueItems fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object contains only unique items.
---@field BeOrdered fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object is ordered.
---@field BeIn fun(self: GUnit.UnitTest, tbl: table): GUnit.UnitResult # Asserts the object is in the given table.
---@field BeNotIn fun(self: GUnit.UnitTest, tbl: table): GUnit.UnitResult # Asserts the object is not in the given table.
---@field BeSameItems fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts all items in the object are the same.
---@field HaveCount fun(self: GUnit.UnitTest, count: number): GUnit.UnitResult # Asserts the object has a specific count.
---@field Pass fun(self: GUnit.UnitTest, fun: fun(any: any): boolean): GUnit.UnitResult # Asserts the object passes a custom function.
---@field BeString fun(self: GUnit.UnitTest): GUnit.UnitResult # Asserts the object is a string.
---@field StartWith fun(self: GUnit.UnitTest, value: string): GUnit.UnitResult # Asserts the string starts with the given value.
---@field EndWith fun(self: GUnit.UnitTest, value: string): GUnit.UnitResult # Asserts the string ends with the given value.
---@field ContainString fun(self: GUnit.UnitTest, value: string): GUnit.UnitResult # Asserts the string contains the given value.
---@field Result any # The value being tested.

---@class GUnit.UnitResult
---@field And GUnit.UnitTest # Provides chainable access to the original UnitTest object.
---@field Result any # The value being tested.

if false then
    --- Creates a new test case.
    --- @param any any # The value to test.
    --- @return GUnit.UnitTest
    function Should(any) end

    _UNITTEST = true
end
