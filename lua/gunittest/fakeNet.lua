GUnitTest.net = {}

local assert = function(v, msg)
    if v then return end
    assert(false, debug.traceback(msg))
end

---@class GUnitNetMessage
---@field name string
---@field data any[]
---@field length number The length of the data in bits.
local meta = {}
meta.__index = meta

---Creates a new net message.
---@param name string
---@return GUnitNetMessage
local function createNetMessage(name)
    return setmetatable({name = name, data = {}, length = 0}, meta)
end

---A list of net messages that have been created.
---@type table<string, GUnitNetMessage>
local messages = {}

---A list of functions to run when a net message is received.
---@type table<string, function>
local functions = {}

---@type GUnitNetMessage? The current write
local currentWrite = nil
---@type GUnitNetMessage? The current write
local currentRead = nil
GUnitTest.net.Start = function(name, _)
    assert(type(name) == "string", "net.Start must be called with a string")
    currentWrite = createNetMessage(name)
    messages[name] = currentWrite
end

local function runReceive(name)
    if not functions[name] then return false end
    currentRead = table.remove(messages, name)
    functions[name](currentRead.length)
    currentRead = nil
end

---@param ply Player|Player[]|CRecipientFilter
GUnitTest.net.Send = function(ply)
    assert(currentWrite, "net.Start must be called before net.Send")
    assert(SERVER, "net.Send can only be called on the server")
    assert(type(ply) == "Player" or type(ply) == "table" or type(ply) == "CRecipientFilter", "net.Send must be called with a Player, table of Players, or CRecipientFilter")
    runReceive(currentWrite.name)
    currentWrite = nil
end

GUnitTest.net.Broadcast = function()
    assert(currentWrite, "net.Start must be called before net.Broadcast")
    assert(SERVER, "net.Broadcast can only be called on the server")
    runReceive(currentWrite.name)
    currentWrite = nil
end

---@param ply Player|Player[]
GUnitTest.net.SendOmit = function(ply)
    assert(currentWrite, "net.Start must be called before net.SendOmit")
    assert(SERVER, "net.SendOmit can only be called on the server")
    assert(type(ply) == "Player" or type(ply) == "table", "net.SendOmit must be called with a Player or table of Players")
    runReceive(currentWrite.name)
    currentWrite = nil
end

GUnitTest.net.SendPAS = function(pos)
    assert(currentWrite, "net.Start must be called before net.SendPAS")
    assert(SERVER, "net.SendPAS can only be called on the server")
    assert(type(pos) == "Vector", "net.SendPAS must be called with a Vector")
    runReceive(currentWrite.name)
    currentWrite = nil
end

GUnitTest.net.SendPVS = function(pos)
    assert(currentWrite, "net.Start must be called before net.SendPVS")
    assert(GUnitTest.CURRENTENV.SERVER, "net.SendPVS can only be called on the server")
    assert(type(pos) == "Vector", "net.SendPVS must be called with a Vector")
    runReceive(currentWrite.name)
    currentWrite = nil
end

GUnitTest.net.SendToServer = function()
    assert(currentWrite, "net.Start must be called before net.SendToServer")
    PrintTable(GUnitTest.CURRENTENV)
    assert(GUnitTest.CURRENTENV.CLIENT, "net.SendToServer can only be called on the client")
    runReceive(currentWrite.name)
    currentWrite = nil
end

GUnitTest.net.Receive = function(name, func)
    assert(type(name) == "string", "net.Receive must be called with a string")
    assert(type(func) == "function", "net.Receive must be called with a function")
    functions[name] = func
    runReceive(name)
end

--#region Write Functions

GUnitTest.net.WriteFloat = function(num)
    assert(currentWrite, "net.Start must be called before net.WriteFloat")
    assert(type(num) == "number", "net.WriteFloat must be called with a number")
    assert(currentWrite, "net.Start must be called before net.WriteFloat")
    table.insert(currentWrite.data, num)
    currentWrite.length = currentWrite.length + 32
end

GUnitTest.net.WriteDouble = function(num)
    assert(currentWrite, "net.Start must be called before net.WriteFloat")
    assert(type(num) == "number", "net.WriteFloat must be called with a number")
    assert(currentWrite, "net.Start must be called before net.WriteFloat")
    table.insert(currentWrite.data, num)
    currentWrite.length = currentWrite.length + 64
end

GUnitTest.net.WriteInt = function(num, bits)
    assert(currentWrite, "net.Start must be called before net.WriteInt")
    assert(type(num) == "number", "net.WriteInt must be called with a number")
    assert(type(bits) == "number", "net.WriteInt must be called with a number")
    --- Check to see if number is within the range of bits
    assert(num >= -2^(bits-1) and num < 2^(bits-1), "Number is out of range for bits")
    table.insert(currentWrite.data, num)
    currentWrite.length = currentWrite.length + bits
end

GUnitTest.net.WriteUInt = function(num, bits)
    assert(currentWrite, "net.Start must be called before net.WriteUInt")
    assert(type(num) == "number", "net.WriteUInt must be called with a number")
    assert(type(bits) == "number", "net.WriteUInt must be called with a number")
    --- Check to see if number is within the range of bits
    assert(num >= 0 and num < 2^bits, "Number is out of range for bits")
    table.insert(currentWrite.data, num)
    currentWrite.length = currentWrite.length + bits
end

GUnitTest.net.WriteBit = function(bool)
    assert(currentWrite, "net.Start must be called before net.WriteBit")
    assert(type(bool) == "boolean", "net.WriteBit must be called with a boolean")
    table.insert(currentWrite.data, bool)
    currentWrite.length = currentWrite.length + 1
end
GUnitTest.net.WriteBool = GUnitTest.net.WriteBit

GUnitTest.net.WriteColor = function(color)
    assert(currentWrite, "net.Start must be called before net.WriteColor")
    assert(type(color) == "table", "net.WriteColor must be called with a table")
    assert(type(color.r) == "number", "Color must have a red value")
    assert(type(color.g) == "number", "Color must have a green value")
    assert(type(color.b) == "number", "Color must have a blue value")
    table.insert(currentWrite.data, color)
    currentWrite.length = currentWrite.length + 32 * 4
end

GUnitTest.net.WriteString = function(str)
    assert(currentWrite, "net.Start must be called before net.WriteString")
    assert(type(str) == "string", "net.WriteString must be called with a string")
    assert(#str > 65532, "String is too long")
    table.insert(currentWrite.data, str)
    currentWrite.length = currentWrite.length + #str * 8 + 8
end

GUnitTest.net.WriteData = function(data, length)
    assert(currentWrite, "net.Start must be called before net.WriteData")
    assert(type(data) == "string", "net.WriteData must be called with a string")
    length = length or #data
    table.insert(currentWrite.data, data)
    currentWrite.length = currentWrite.length + length * 8
end

---For debugging purposes. This supports a table
---@param ent Entity|table
GUnitTest.net.WriteEntity = function(ent)
    assert(currentWrite, "net.Start must be called before net.WriteEntity")
    table.insert(currentWrite.data, ent)
    currentWrite.length = currentWrite.length + 13
end

---For debugging purposes. This supports a table
---@param ent Player|table
GUnitTest.net.WritePlayer = function(ent)
    assert(currentWrite, "net.Start must be called before net.WriteEntity")
    table.insert(currentWrite.data, ent)
    currentWrite.length = currentWrite.length + 8
end

---**TODO:** This fix data length
---**Warning:** This function does not update the length of the message correctly.
GUnitTest.net.WriteTable = function(tbl, seq)
    assert(currentWrite, "net.Start must be called before net.WriteTable")
    assert(type(tbl) == "table", "net.WriteTable must be called with a table")
    if seq then
        assert(table.IsSequential(tbl), "Table must be sequential")
        currentWrite.length = currentWrite.length + 32
        table.insert(currentWrite.data, tbl)
    else
        currentWrite.length = currentWrite.length + 32
        table.insert(currentWrite.data, tbl)
    end
end

GUnitTest.net.WriteType = function(any)
    assert(currentWrite, "net.Start must be called before net.WriteType")
    table.insert(currentWrite.data, any)
end

--#endregion

--#region Read Functions

GUnitTest.net.ReadFloat = function()
    assert(currentRead, "net.ReadFloat must be called within net.Receive")
    local num = table.remove(currentRead.data, 1)
    assert(type(num) == "number", "net.ReadFloat did not return a number")
    return num
end

GUnitTest.net.ReadDouble = function(num)
    assert(currentRead, "net.ReadDouble must be called within net.Receive")
    local num = table.remove(currentRead.data, 1)
    assert(type(num) == "number", "net.ReadDouble did not return a number")
    return num
end

GUnitTest.net.ReadInt = function(bits)
    assert(currentRead, "net.ReadInt must be called within net.Receive")
    assert(type(bits) == "number", "net.ReadInt must be called with a number")
    local num = table.remove(currentRead.data, 1)
    assert(type(num) == "number", "net.ReadInt did not return a number")
    assert(num >= -2^(bits-1) and num < 2^(bits-1), "Number is out of range for bits")
    return num
end

GUnitTest.net.ReadUInt = function(bits)
    assert(currentRead, "net.ReadUInt must be called within net.Receive")
    assert(type(bits) == "number", "net.ReadUInt must be called with a number")
    local num = table.remove(currentRead.data, 1)
    assert(type(num) == "number", "net.ReadUInt did not return a number")
    assert(num >= 0 and num < 2^bits, "Number is out of range for bits")
    return num
end

GUnitTest.net.ReadBit = function()
    assert(currentRead, "net.ReadBit must be called within net.Receive")
    local bool = table.remove(currentRead.data, 1) and 1 or 0
    assert(type(bool) == "number", "net.ReadBit did not return a number")
    return bool
end

GUnitTest.net.ReadBool = function()
    assert(currentRead, "net.ReadBool must be called within net.Receive")
    local bool = table.remove(currentRead.data, 1)
    assert(type(bool) == "boolean", "net.ReadBool did not return a boolean")
    return bool
end

GUnitTest.net.ReadColor = function(color)
    assert(currentRead, "net.ReadColor must be called within net.Receive")
    local color = table.remove(currentRead.data, 1)
    assert(type(color) == "table", "net.ReadColor did not return a Color / table")
    assert(type(color.r) == "number", "Color must have a red value")
    assert(type(color.g) == "number", "Color must have a green value")
    assert(type(color.b) == "number", "Color must have a blue value")
    return color
end

GUnitTest.net.ReadString = function(str)
    assert(currentRead, "net.ReadString must be called within net.Receive")
    local str = table.remove(currentRead.data, 1)
    assert(type(str) == "string", "net.ReadString did not return a string")
    assert(#str > 65532, "String is too long")
    return str
end

GUnitTest.net.ReadData = function(length)
    assert(currentRead, "net.ReadData must be called within net.Receive")
    assert(type(length) == "number", "net.ReadData must be called with a length")
    local data = table.remove(currentRead.data, 1)
    assert(type(data) == "string", "net.ReadData did not return a string")
    assert(#data > length, "Data length does not match")
    return data
end

---For debugging purposes. This supports a table
GUnitTest.net.ReadEntity = function(ent)
    assert(currentRead, "net.ReadEntity must be called within net.Receive")
    local ent = table.remove(currentRead.data, 1)
    assert(type(ent) == "Entity" or type(ent) == "table", "net.ReadEntity did not return an Entity")
    return ent
end

---For debugging purposes. This supports a table
GUnitTest.net.ReadPlayer = function(ent)
    assert(currentRead, "net.ReadPlayer must be called within net.Receive")
    local ent = table.remove(currentRead.data, 1)
    assert(type(ent) == "Player" or type(ent) == "table", "net.ReadPlayer did not return a Player")
    return ent
end

---**TODO:** This fix data length
---**Warning:** This function does not update the length of the message correctly.
GUnitTest.net.ReadTable = function(seq)
    assert(currentRead, "net.ReadTable must be called within net.Receive")
    local tbl = table.remove(currentRead.data, 1)
    assert(type(tbl) == "table", "net.ReadTable did not return a table")
    if seq then
        assert(table.IsSequential(tbl), "Table must be sequential")
    end
    return tbl
end

GUnitTest.net.ReadType = function(typeID)
    assert(currentRead, "net.ReadType must be called within net.Receive")
    local any = table.remove(currentRead.data, 1)
    if typeID then
        assert(TypeID(any) == typeID, string.format("net.ReadType expected %s but got %s(%s)", typeID, TypeID(any), type(any)))
    end
    return any
end

--#endregion