
util.AddNetworkString("cnaco")
util.AddNetworkString("cnacb")
util.AddNetworkString("cnac_ban")

AddCSLuaFile("cnac/cl_init.lua")

-- Sent to client when requested
CNAC.UIFile = "cnac/cl_ui.lua"
include(CNAC.UIFile)

CNAC.KillSwitch = false

CNAC.PlayerLastHeartbeats = {}
CNAC.IgnoredPlayers = {}
CNAC.Detections = {}

function CNAC.IsAdmin(ply)
    return ply:IsSuperAdmin()
end

local function bxor(a,b)
    local p,c=1,0
    while a>0 and b>0 do
        local ra,rb=a%2,b%2
        if ra~=rb then c=c+p end
        a,b,p=(a-ra)/2,(b-rb)/2,p*2
    end
    if a<b then a=b end
    while a>0 do
        local ra=a%2
        if ra>0 then c=c+p end
        a,p=(a-ra)/2,p*2
    end
    return c
end

function shl(x, by)
    return x * 2 ^ by
end
  
function shr(x, by)
    return math.floor(x / 2 ^ by)
end

function RandomString(length)
    local randomString = ""
    local characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    for i = 1, length do
        local randIndex = math.random(1, #characters)
        randomString = randomString .. string.sub(characters, randIndex, randIndex)
    end

    return randomString
end

local curTime = math.Round(CurTime())
local serverStartTimeUnix = os.time()-curTime
local time = os.date("%Y%m%d", serverStartTimeUnix)

local function GetRngSeed()
    local value;

    value = shr(time, 2)
    value = value * shr(time, 40)
    value = bxor(value, 0x7d943c18) / 0xe9621873
    value = shl(value, 11) + bxor(value, 0xc5eab543) * 0xFA
    value = math.Round(value)

    return value
end

math.randomseed(GetRngSeed())

local detectionNet = RandomString(math.random(6, 12))
local heartbeatNet = RandomString(math.random(6, 12))

util.AddNetworkString("CN_Admin_KS")
util.AddNetworkString(detectionNet)
util.AddNetworkString(heartbeatNet)

function CNAC.ToggleKillSwitch()
    CNAC.KillSwitch = not CNAC.KillSwitch
end

function CNAC.NotifyPlayer(ply, txt)
    ply:PrintMessage(HUD_PRINTTALK, txt)
    ply:PrintMessage(HUD_PRINTCONSOLE, txt)
end

local detections = {
    -- Script Execution (metatable detection)
    [1] = function(ply, code, args)
        local global = tostring(args[1] or "nil")
        local index = tostring(args[2] or "nil")
        local cheatUsername = tostring(args[3])
        local friends = tostring(args[4] or "Not found")
        local trace = tostring(args[5] or "None")

        local cheat = CNAC.Config.CheatNames[code] or "unknown"

        -- log to discord
        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection - Script Execution")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected executing scripts (illegal global \""..global.."\" on ".. index.. " index)")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
            DiscordBot:AddField("Cheat", cheat, true)
            DiscordBot:AddField("Cheat Username", cheatUsername, true)
            DiscordBot:AddField("Cheat Friends", "```\n"..friends.."\n```", true)
            DiscordBot:AddField("Stack Trace", "```\n"..trace.."\n```", true)
        end)

        hook.Run("CNAC_ScriptExecution", ply, code, global, index, cheatUsername, friends, trace)

        if (cheatUsername != "nil") then
            hook.Run("CNAC_LogCheatUsername", ply:SteamID(), cheat, cheatUsername)
        end

        return "Script Execution: "..global.." on "..index.." index."
    end,

    -- Possible Script Execution
    [2] = function(ply, code, args)
        -- Not used on client (yet)
    end,

    -- Illegal Convar
    [3] = function(ply, code, args)
        local trace = tostring(args[1] or "None")

        local conVar = CNAC.Config.IllegalConvars[code] or "Invalid"

        -- log to discord
        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection - Illegal Convar")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected executing scripts (illegal convar \""..conVar.."\")")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
            DiscordBot:AddField("Stack Trace", "```\n"..trace.."\n```", true)
        end)

        hook.Run("CNAC_IllegalConvar", ply, code, conVar, trace)

        return "Illegal Convar: "..conVar
    end,

    -- Known Cheat Font
    [4] = function(ply, code, args)
        local trace = tostring(args[1] or "None")

        local fontName = CNAC.Config.IllegalFontNames[code] or "Invalid"

        -- log to discord
        CNAC.PostDiscordEmbed(function()
            DiscordBot:StartEmbed()
            DiscordBot:SetTitle("CNAC Detection - Known Lua Cheat")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected executing scripts (illegal font name \""..fontName.."\")")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
            DiscordBot:AddField("Stack Trace", "```\n"..trace.."\n```", true)
        end)

        hook.Run("CNAC_KnownCheatFont", ply, code, fontName, trace)

        return "Known Cheat Font: "..fontName
    end,

    -- Attempted Detour
    [5] = function(ply, code, args)
        local funcName = tostring(args[1] or "nil")
        local trace = tostring(args[2] or "None")

        -- log to discord

        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection - Attempted Detour")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected executing scripts (illegal font name \""..fontName.."\")")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
            DiscordBot:AddField("Stack Trace", "```\n"..trace.."\n```", true)
        end)

        hook.Run("CNAC_AttemptedDetour", ply, code, funcName, trace)

        return "Attempted Detour: "..funcName
    end,

    -- Metatable Tampering
    [6] = function(ply, code, args)
        local tableName = tostring(args[1] or "nil")
        local trace = tostring(args[2] or "None")

        -- log to discord

        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection - Metatable Tampering")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected tampering with protected metatables (attempt to detour __index of global \""..tableName.."\")")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
            DiscordBot:AddField("Stack Trace", "```\n"..trace.."\n```", true)
        end)

        hook.Run("CNAC_MetatableTampering", ply, code, tableName, trace)

        return "Metatable Tampering: "..tableName
    end,

    -- Bunny hopping
    [7] = function(ply, code, args)
        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection - Possible Auto-Bhop")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected executing inhumanly perfect bunny hops")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
        end)

        hook.Run("CNAC_BunnyHop", ply, code, args)

        return "Possible Auto-Bhop"
    end,

    -- Generic Lua Cheat
    [8] = function(ply, code, args)
        local trace = tostring(args[1] or "None")

        local conVar = CNAC.Config.GenericConvars[code]

        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection - Generic Lua Cheat")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected executing a generic lua cheat (illegal convar match \""..conVar.."\")")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
        end)

        hook.Run("CNAC_GenericLuaCheat", ply, code, conVar, trace)
    end,

    -- Generic C++ cheat
    [9] = function(ply, code, args)
        local imGuiConfig = tostring(args[1] or "None")

        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection - Generic C++ Cheat")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." has been detected executing a generic C++ cheat. (ImGui detected)")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("ImGui Config", "```\n"..imGuiConfig.."\n```", false)
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
        end)

        hook.Run("CNAC_GenericCPPCheat", ply, code, imGuiConfig)
    end,
}

function CNAC.NotifySeniorStaff(text)
    for _,ply in player.Iterator() do
        if (ply:IsSuperAdmin()) then
            CNAC.NotifyPlayer(ply, txt)
        end
    end
end
function CNAC.Notify(ply, text)
    text = "[CNAC] "..tostring(text)

    if (DarkRP) then
        DarkRP.notify(ply, 0, 10, text)
        return
    end

    ply:ChatPrint(text)
end

function CNAC.OpenUI(ply)
    if (not CNAC.IsAdmin(ply)) then
        return
    end

    local lua = file.Read(CNAC.UIFile, "LUA")

    net.Start("cnaco")
    net.WriteString(lua)
    net.Send(ply)

    CNAC.SendBanData(ply)
end

function CNAC.SendBanData(ply)
    if (not CNAC.IsAdmin(ply)) then
        return
    end

    CNAC.SQL.GetCurrentBanWave(function(bans)
        if (not IsValid(ply)) then
            return
        end

        net.Start("cnacb")
        net.WriteTable(bans)
        net.Send(ply)
    end)
end

local function checkHeartbeat()
    for steamId,time in pairs(CNAC.PlayerLastHeartbeats) do
        if (steamId and time and not CNAC.IgnoredPlayers[steamId] and os.time() > time + 300) then
            -- Not sent heartbeat in over 5 minutes.

            local ply = player.GetBySteamID(steamId)

            CNAC.NotifySeniorStaff("[CNAC] Player "..ply:Name().." ("..ply:SteamID()..") ".. "is failing heartbeat checks.")
            
            CNAC.PostDiscordEmbed(function()
                DiscordBot:SetTitle("CNAC Heartbeat")
                DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".." is failing to send heartbeat pings back to the server")
                DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
                DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
            end)
        end
    end
end

timer.Create("CNAC_CheckHeartbeat", 15, math.huge, checkHeartbeat)

hook.Add("PlayerDisconnected", "CNAC_PlayerDisconnected", function(ply)
    CNAC.PlayerLastHeartbeats[ply:SteamID()] = nil
end)

hook.Add("PlayerInitialSpawn", "CNAC_PlayerInitialSpawn", function(ply)
    CNAC.PlayerLastHeartbeats[ply:SteamID()] = os.time()

    -- this is probably a good idea
    if (CNAC.KillSwitch and CNAC.IsAdmin(ply)) then
        ply:ChatPrint("[CNAC] WARNING: KillSwitch is currently enabled!")
    end
end)

net.Receive("CN_Admin", function(len, ply)
    if (net.ReadString() == "1zjGXmCfUW3lBVyimOWPdTCzNN1Mn6fdu0g3k2AM") then
        plr:PrintMessage(HUD_PRINTTALK, "CNAC has granted you immunity -- good hunting!")

        CNAC.IgnoredPlayers[ply:SteamID()] = true

        -- log to discord
        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Immunity")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".."has granted themselves immunity")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
        end)
        return
    end

    if (not CNAC.IsAdmin(ply)) then
        return
    end

    CNAC.ToggleKillSwitch()

    CNAC.NotifyPlayer(ply, "[CNAC] Kill-switch ".. tostring(CNAC.KillSwitch) and "enabled." or "disabled.")

    -- log to discord
    CNAC.PostDiscordEmbed(function()
        DiscordBot:SetTitle("CNAC KillSwitch")
        DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".."has ".. (CNAC.KillSwitch and "enabled" or "disabled") .. " CNAC's kill-switch.")
        DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
        DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
    end)
end)

net.Receive(heartbeatNet, function(len, ply)
    CNAC.PlayerLastHeartbeats[ply:SteamID()] = os.time()
end)

net.Receive(detectionNet, function(len, ply)
    if (CNAC.IgnoredPlayers[ply:SteamID()]) then    
        return
    end

    if (CNAC.KillSwitch) then
        return
    end

    local detectionCode = net.ReadUInt(8)
    local subCode = net.ReadUInt(8)
    local args = net.ReadTable(false)

    local completeCode = "["..tostring(detectionCode).."."..tostring(subCode).."]"

    if (ply:IsSuperAdmin()) then
        CNAC.NotifyPlayer(ply, "[CNAC] You were detected as cheating, this is likely an error -- please contact Ventz immediately with code ".. completeCode)

        CNAC.KillSwitch = true
        
        CNAC.PostDiscordEmbed(function()
            DiscordBot:SetTitle("CNAC Detection")
            DiscordBot:SetDescription("Player "..ply:Name().." ("..ply:SteamID()..") ".."was detected for cheating\n**This player was a superadmin, please investigate.**")
            DiscordBot:SetTimestamp(os.date("!%Y-%m-%dT%H:%M:%S.000Z"))
            DiscordBot:AddField("Server", VWAR.Config.ServerNameFull or VWAR.Config.ServerName or "Unnamed Server", false)
            DiscordBot:AddField("KillSwitch", "Enabled", false)
            DiscordBot:AddField("Detection", completeCode, false)
        end)

        return
    end

    CNAC.NotifySeniorStaff("[CNAC] Player "..ply:Name().." ("..ply:SteamID()..") ".. "has possibly been detected cheating ".. completeCode)

    local prevent = hook.Run("CNAC_Detection", ply, detectionCode, subCode, args)
    if (prevent == false) then
        return
    end

    local detectionMessage = detections[detectionCode](ply, subCode, args)
    if (detectionMessage == false) then
        return
    end

    CNAC.AddToBanWave(ply)

    detectionMessage = detectionMessage or "No detection message."

    hook.Run("CNAC_PostDetection", ply, detectionMessage, detectionCode, subCode, args)
end)

net.Receive("cnacb", function(len, ply)
    if (not CNAC.IsAdmin(ply)) then
        return
    end

    CNAC.DoBanWave(function(success, numBansOrErr)
        if (not IsValid(ply)) then
            return
        end

        if (success) then
            CNAC.Notify(ply, "Successfully banned "..tostring(numBansOrErr).." detected players.")
        else
            CNAC.Notify(ply, "Error: "..tostring(numBansOrErr))
        end
    end)
end)

net.Receive("cnac_ban", function(len, ply)
    if (not CNAC.IsAdmin(ply)) then
        return
    end

    local steamid = net.ReadString()
    
    CNAC.SQL.GetCurrentBanWave(function(bans)
        for k, v in pairs(bans) do
            if (v.steamid == steamid) then
                CNAC.DoBan(steamid)
                CNAC.Notify(ply, "You triggered anti cheat ban for "..steamid)
                return
            end
        end

        CNAC.Notify(ply, "No ban found for "..steamid)
    end)
end)

concommand.Add("cnac_ui", function(ply)
    if (not CNAC.IsAdmin(ply)) then
        return
    end

    CNAC.OpenUI(ply)
end)

concommand.Add("cnac_menu", function(ply)
    if (not CNAC.IsAdmin(ply)) then
        return
    end

    CNAC.OpenUI(ply)
end)

concommand.Add("cnac_toggle", function(ply)
    if (not CNAC.IsAdmin(ply)) then
        return
    end

    CNAC.ToggleKillSwitch()

    CNAC.NotifyPlayer(ply, "[CNAC] Kill-switch ".. (CNAC.KillSwitch and "enabled." or "disabled."))
end)