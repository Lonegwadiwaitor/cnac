
if (SERVER) then
    return
end

local pairs = pairs
local tostring = tostring
local getMetatable = getmetatable
local setMetatable = setmetatable
local getRegistry = debug.getregistry
local traceBack = debug.traceback
local getInfo = debug.getinfo
local forEach = table.foreach
local strFind = string.find

local netStart = net.Start;
local netSendToServer = net.SendToServer;
local netWriteUInt = net.WriteUInt;
local netWriteTable = net.WriteTable;
local entsGetAll = ents.GetAll;
local renderCapture = render.Capture;
local NetToID = util.NetworkStringToID;
local rand = math.random
local randSeed = math.randomseed
local round = math.Round
local floor = math.floor
local curTime = CurTime
local osDate = os.date
local hookAdd = hook.Add
local strSub = string.sub
local osTime = os.time

-- would rather not use built-in bxor, idiots will prolly try hooking it
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
    return floor(x / 2 ^ by)
end

function RandomString(length)
    local randomString = ""
    local characters = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"

    for i = 1, length do
        local randIndex = rand(1, #characters)
        randomString = randomString .. strSub(characters, randIndex, randIndex)
    end

    return randomString
end
  

-- defeatable with newcclosure, but still a potential detection vector
local function IsCFunction(f)
    return getInfo(f, "flnSu").what == "C"
end

local function IsLuaFunction(f)
    return not IsCFunction(f)
end

local detectionNet = nil
local heartbeatNet = nil

local function ValidateCFunction(func, funcName)
    if (not IsCFunction(func)) then
        if (not detectionNet) then
            return RunConsoleCommand("retry") -- i dont think this is against any tos? correct me if im wrong
        end

        netStart(detectionNet)
        netWriteUInt(5, 8)
        netWriteUInt(1, 8)
        netWriteTable({
            funcName,
            traceBack()
        }, false)
        netSendToServer()
    end
end

local limit = 60 * 5
local currentTime = round(curTime() - limit)
local serverStartTimeUnix = osTime() - currentTime
local time = osDate("%Y%m%d", serverStartTimeUnix)

local function GetRngSeed()
    local value;

    value = shr(time, 2)
    value = value * shr(time, 40)
    value = bxor(value, 0x7d943c18) / 0xe9621873
    value = shl(value, 11) + bxor(value, 0xc5eab543) * 0xFA
    value = round(value)

    return value
end

local i = 0
while (true) do
    i = i + 1

    if (i > limit * 2) then
        return
    end

    randSeed(GetRngSeed())

    detectionNet = RandomString(rand(6, 12))
    heartbeatNet = RandomString(rand(6, 12))

    if (NetToID(detectionNet) ~= 0 and NetToID(heartbeatNet) ~= 0) then
        break
    end

    currentTime = round(curTime()-limit)+i
    serverStartTimeUnix = osTime() - currentTime
    time = osDate("%Y%m%d", serverStartTimeUnix)
end

timer.Create("CNAC_Heartbeat", 60, math.huge, function()
    netStart(heartbeatNet)
    netSendToServer()
end)

-- This is all made purposely complex for a reason, even in the case that the script is deobfuscated, I don't want to make reverse engineering easy for them.
-- SMALL REMINDER that since this is obfuscated, they only have bytecode to work with, making it more difficult for them.
-- (also its very different from 5.1 so no luadec!)
-- Read the server init.lua if you want to make sense of the detections.

-------------------- Oink & Cheadle API detections, Metatable Tampering & Detours --------------------
local protectedGlobals = {
    "net",
    "vgui",
    "debug",
    "timer",
    "hook",
    "ents",
    "render"
}

local illegalGlobals = {
    "oink",
    "cheadle_api"
}

local cachedGlobals = {}

local detectedMetatableTampering = false

local function detourMt(global)
    cachedGlobals[global] = {}

    for i,v in pairs(_G[global]) do
        cachedGlobals[global][i] = v
    end

    local index
    index = function(self, idx)
        local trace = traceBack()

        -------------------- Metatable Tampering --------------------
        if (getMetatable(_G[global]).__index ~= index and not detectedMetatableTampering) then
            -- let's not spam detections
            detectedMetatableTampering = true

            netStart(detectionNet)
            netWriteUInt(6, 8)
            netWriteUInt(1, 8)
            netWriteTable({
                global,
                traceBack()
            }, false)
            netSendToServer()
        end
        --------------------------------------------------------

        local info = getInfo(2, "flnSu")
        if (info and info.what == "main" and info.func) then
            local env = getfenv(info.func)

            if (env) then
                for i2 = 1, #illegalGlobals do
                    local illegalGlobal = illegalGlobals[i2]

                    if (env[illegalGlobal]) then
                        local cheatEnvironment = env[illegalGlobal] -- _G.oink // _G.cheadle_api
                        -- Script Execution - oink.industries (detected illegal global \"oink\" during "..global.." index)

                        local cheatUser = "None"
                        local friends = {}

                        if (cheatEnvironment.username) then
                            cheatUser = cheatEnvironment.username()
                        end

                        if (cheatEnvironment.GetUsername) then
                            cheatUser = cheatEnvironment.GetUsername()
                        end

                        if (cheatEnvironment.Config.IsFriend) then
                            local entities = entsGetAll()
                            for i = 1, #entities do
                                local entity = entities[i]

                                if (entity:IsPlayer()) then
                                    local isFriend = cheatEnvironment.Config.IsFriend(entity)
                                    
                                    if (isFriend) then
                                        friends[#friends+1] = entity:SteamID()
                                    end
                                end
                            end
                        end
                        
                        netStart(detectionNet)
                        netWriteUInt(1, 8)
                        netWriteUInt(illegalGlobal == "oink" and 1 or 2, 8)
                        netWriteTable({
                            illegalGlobal,
                            global,
                            cheatUser,
                            friends,
                            trace
                        }, false)
                        netSendToServer()
                    end
                end
            end
        end
        
        return cachedGlobals[global][idx]
    end

    -------------------- Attempted Detour --------------------
    local newindex
    newindex = function(self, key, value)
        cachedGlobals[global][key] = value
    end
    --------------------------------------------------------

    _G[global] =
        setMetatable({}, {
            __index = index,
            __newindex = newindex
        }
    )
end

for i = 1, #protectedGlobals do
    local v = protectedGlobals[i]
    detourMt(v)
end
--------------------------------------------------------

-------------------- Illegal Convar --------------------
local illegalConVars = {
    "book",
    "smeghack_menu",
    "ib_menu",
    "nigger_menu", -- :/
    "lenny_menu",
    "odius_menu",
    "at_menu",
    "cf_menu",
    "fap_menu",
    "pb_menu",
    "qq_menu",
    "sh_menu",
    "shenbot_menu",
    "lokidevs_menu",
    "ace_menu",
    "loki_menu",
    

    "+SethHack_Menu",
    "+neon_menu",
    "+Aim",
    "+Ares_Aim",
    "+Isis_Aim",
    "+Ares_PropKill"
}

local genericConVars = {
    "hack",
    "exploit",
    "aimbot",
    "antiaim",
    "bhop",
    "bunnyhop",
    "_menu",
}

local oldConCommandAdd = concommand.Add
concommand.Add = function(...)
    local args = {...}

    local commandName = args[1]

    for i = 1, #illegalConVars do
        local v = illegalConVars[i]

        if (commandName:find(v)) then
            netStart(detectionNet)
            netWriteUInt(3, 8)
            netWriteUInt(i, 8)
            netWriteTable({
                traceBack()
            }, false)
            netSendToServer()
        end
    end

    for i = 1, #genericConVars do
        local v = genericConVars[i]

        if (commandName:find(v)) then
            netStart(detectionNet)
            netWriteUInt(8, 8)
            netWriteUInt(i, 8)
            netWriteTable({
                traceBack()
            }, false)
            netSendToServer()
        end
    end

    return oldConCommandAdd(...)
end
--------------------------------------------------------


-------------------- Known Lua Cheat --------------------
local illegalFontNames = {
    "onehack.font", -- onehack
    "VisualsFont", -- idiotbox
    "memes", -- "acebot"
}

local surfaceCreateFont = surface.CreateFont

surface.CreateFont = function(name, tbl)
    for i = 1, #illegalFontNames do
        local v = illegalFontNames[i]

        if (name:find(v)) then
            netStart(detectionNet)
            netWriteUInt(4, 8)
            netWriteUInt(i, 8)
            netWriteTable({
                traceBack()
            }, false)
            netSendToServer()
        end
    end

    return surfaceCreateFont(name, tbl)
end
--------------------------------------------------------


-------------------- Bunny hopping --------------------

local KeyDown  = getRegistry().CUserCmd.KeyDown
local IsOnGround = getRegistry().Entity.IsOnGround
local tableEmpty = table.Empty

local playerState = { Count1 = 0, Count2 = 0, Buffer = {} }

-- TODO: Most cheaters hold SPACE for bhop
-- Engineer another detection to see if they hop without letting go of that key
hookAdd("SetupMove", RandomString(rand(6, 12)), function(ply, _, cmd)
	local lastOnGround = playerState.OnGround
	local lastInJump   = playerState.InJump

    local onGround = IsOnGround(ply)
	local inJump   = KeyDown(cmd, IN_JUMP)

    if (lastOnGround and not onGround) then
		playerState.Count2 = 0
	elseif (not lastOnGround and onGround) then
		if (not lastInJump and inJump) then
			playerState.Count1 = playerState.Count1 + 1
			if (playerState.Count1 == 50) then
				local a, b, c = 0, 0, 0
				for i = 1, #playerState.Buffer do
					local x = playerState.Buffer [i]
					a = a + 1 
					b = b + x
					c = c + x * x
				end
				
				if ((c - b * b / a) / a < 0.1) then
                    netStart(detectionNet)
                    netWriteUInt(4, 8)
                    netWriteUInt(i, 8)
                    netWriteTable({
                        traceBack()
                    }, false)
                    netSendToServer()
				end
			end
		else
			playerState = { Count1 = 0, Count2 = 0, Buffer = {} }
		end
	elseif (onGround and lastInJump ~= inJump) then
		playerState = { Count1 = 0, Count2 = 0, Buffer = {} }
	end

    if (not onGround and lastInJump and not inJump) and
	    playerState.Count2 >= 0 then
		playerState.Buffer[#playerState.Buffer + 1] = playerState.Count2
		playerState.Count2 = -math.huge
	end
	
	playerState.Count2 = playerState.Count2 + 1
	
	playerState.OnGround = onGround
	playerState.InJump   = inJump
end)

--------------------------------------------------------

-------------------- ImGui --------------------
local imGuiConfig = file.Read( "imgui.ini", "BASE_PATH" )
local usedImGui = imGuiConfig ~= nil

if (usedImGui) then
    netStart(detectionNet)
    netWriteUInt(9, 8)
    netWriteUInt(1, 8)
    netWriteTable({
        imGuiConfig
    }, false)
    netSendToServer()
end
--------------------------------------------------------

