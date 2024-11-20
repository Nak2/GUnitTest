
AddCSLuaFile()

local autorun = CreateConVar("gunittest_autorun", "0", FCVAR_ARCHIVE, "Should GUnit run automatically when the server starts?")
local enable = CreateConVar("gunittest_enable", game.IsDedicated() and "0" or "1", FCVAR_ARCHIVE, "Should GUnit be enabled?")
-- If enabled, add all CS files in the gunittest folder to the download lis for the client.
if enable:GetBool() then
    local _, folders = file.Find("lua/unittest/*", "GAME")
    for _, folder in ipairs(folders or {}) do
        local files = file.Find("lua/unittest/" .. folder .. "/*.lua", "GAME")
        for _, file in ipairs(files or {}) do
            AddCSLuaFile("unittest/" .. folder .. "/" .. file)
        end
    end
else
    return
end

GUnitTest = {}

AddCSLuaFile("gunittest/should.lua")
include("gunittest/should.lua")
AddCSLuaFile("gunittest/errhandle.lua")
include("gunittest/errhandle.lua")
AddCSLuaFile("gunittest/env.lua")
include("gunittest/env.lua")
AddCSLuaFile("gunittest/case.lua")
include("gunittest/case.lua")
AddCSLuaFile("gunittest/logic.lua")
include("gunittest/logic.lua")

local function conFunc(ply, con, args)
    if IsValid(ply) and not (ply:IsSuperAdmin() or ply:IsListenServerHost()) then return end
    args = args or {}
    local results
    if #args > 0 then
        results = GUnitTest.RunTests(args[1])
    else
        results = GUnitTest.RunAllTests()
    end
    GUnitTest.PrintResults(con == "gunittest_run_fullreport", results)
end

local function conHelp(com, args)
    if #args <1 then return {com} end
    local tbl = {}
    local _, folders = file.Find("lua/unittest/*", "GAME")
    local search = args:Trim()
    for _, value in pairs(folders or {}) do
        if string.find(value, search) then
            table.insert(tbl, com .. " " .. value)
        end
    end
    return tbl
end

if SERVER then
    concommand.Add("gunittest_run", conFunc, conHelp, "Run all tests or tests in a specific folder.")
    concommand.Add("gunittest_run_fullreport", conFunc, conHelp, "Run all tests or tests in a specific folder. Also prints all test results.")
elseif enable:GetBool() then
    concommand.Add("gunittest_run_cl", conFunc, conHelp, "Run all tests or tests in a specific folder.")
    concommand.Add("gunittest_run_fullreport_cl", conFunc, conHelp, "Run all tests or tests in a specific folder. Also prints all test results.")
end

if autorun:GetBool() then
    GUnitTest.PrintResults(false, GUnitTest.RunAllTests())
end
