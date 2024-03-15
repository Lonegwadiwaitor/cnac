
CNAC.SQL = CNAC.SQL or {}

CNAC.SQL.LoggedDetections = CNAC.SQL.LoggedDetections or {}
CNAC.SQL.CheatUsernameLogs = CNAC.SQL.CheatUsernameLogs or {}

function CNAC.SQL.Initialize()
    if (not SQL) then
        return
    end

    CNAC.Print("Initializing cnac_detections SQL...")

	local queryString = [[CREATE TABLE IF NOT EXISTS `network`.`cnac_detections` (
`steamid` VARCHAR(64),
`detection_code` INT,
`sub_code` INT,
`message` VARCHAR(512),
`time` BIGINT,
PRIMARY KEY (`steamid`))]]

	local query = SQL:query(queryString)
	function query:onSuccess()
		CNAC.Print("Initialized cnac_detections SQL")
	end
	function query:onError(err)
		CNAC.Print("Error Initializing cnac_detections SQL ( "..tostring(err).." )")
	end
	query:start()

    CNAC.Print("Initializing cnac_cheat_usernames SQL...")

    local queryString = [[CREATE TABLE IF NOT EXISTS `network`.`cnac_cheat_usernames` (
`steamid` VARCHAR(64),
`cheat_name` VARCHAR(128),
`cheat_username` VARCHAR(256),
`time` BIGINT,
PRIMARY KEY (`steamid`, `cheat_name`, `cheat_username`))]]

    local query = SQL:query(queryString)
    function query:onSuccess()
        CNAC.Print("Initialized cnac_cheat_usernames SQL")
    end
    function query:onError(err)
        CNAC.Print("Error Initializing cnac_cheat_usernames SQL ( "..tostring(err).." )")
    end
    query:start()

    CNAC.Print("Initializing cnac_ban_wave SQL...")

    local queryString = [[CREATE TABLE IF NOT EXISTS `network`.`cnac_ban_wave` (
`steamid` VARCHAR(128),
`banned` TINYINT,
`time` BIGINT,
PRIMARY KEY (`steamid`))]]

    local query = SQL:query(queryString)
    function query:onSuccess()
        CNAC.Print("Initialized cnac_ban_wave SQL")
    end
    function query:onError(err)
        CNAC.Print("Error Initializing cnac_ban_wave SQL ( "..tostring(err).." )")
    end
    query:start()
end

function CNAC.SQL.LogDetection(steamid, detectionCode, subCode, message)
    if (not CNAC.SQL.Connected) then
        return
    end

    local sid64 = util.SteamIDTo64(steamid)
    if (not sid64 or tostring(sid64) == "0") then
        CNAC.Print("Invalid SQL log SteamID64 for "..tostring(steamid))
        return
    end

    local query = SQL:prepare("INSERT INTO `cnac_detections` (`steamid`, `detection_code`, `sub_code`, `message`, `time`) VALUES (?, ?, ?, ?, ?)")
    query:setString(1, steamid)
    query:setNumber(2, detectionCode)
    query:setNumber(3, subCode)
    query:setString(4, message)
    query:setNumber(5, os.time())
    function query:onSuccess()
        CNAC.Print("SQL Logged detection for "..steamid..": "..message)
    end
    function query:onError(err)
        CNAC.Print("SQL Error logging detection for "..steamid..": "..tostring(err))
    end
    query:start()
end

function CNAC.SQL.LogCheatUsername(steamid, cheatName, cheatUsername)
    if (not CNAC.SQL.Connected) then
        return
    end

    if (CNAC.SQL.CheatUsernameLogs[steamid] and SysTime() - CNAC.SQL.CheatUsernameLogs[steamid] < 60) then
        return
    end

    if (not table.HasValue(CNAC.Config.CheatNames, cheatName)) then
        return
    end

    CNAC.SQL.CheatUsernameLogs[steamid] = SysTime()

    local sid64 = util.SteamIDTo64(steamid)
    if (not sid64 or tostring(sid64) == "0") then
        CNAC.Print("Invalid SQL log SteamID64 for "..tostring(steamid))
        return
    end

    CNAC.SQL.GetCheatUsernames(steamid, function(usernames)
        local usernameAlreadyExists = false
        for k, v in pairs(usernames) do
            if (v.cheat_name == cheatName and v.cheat_username == cheatUsername) then
                usernameAlreadyExists = true
                break
            end
        end

        if (usernameAlreadyExists) then
            return
        end

        local mostRecentLog = 0
        for k, v in pairs(usernames) do
            if (v.cheat_name == cheatName and v.time > mostRecentLog) then
                mostRecentLog = v.time
            end
        end

        // 24 hour cooldown
        if (os.time() - mostRecentLog < 60 * 60 * 24) then
            return
        end

        CNAC.Print("Logging cheat username for "..steamid..": "..cheatName.." - "..cheatUsername)
        
        local query = SQL:prepare("INSERT INTO `cnac_cheat_usernames` (`steamid`, `cheat_name`, `cheat_username`, `time`) VALUES (?, ?, ?, ?)")
        query:setString(1, steamid)
        query:setString(2, cheatName)
        query:setString(3, cheatUsername)
        query:setNumber(4, os.time())
        function query:onSuccess()
            CNAC.Print("SQL Logged cheat username for "..steamid..": "..cheatName.." - "..cheatUsername)
        end
        function query:onError(err)
            CNAC.Print("SQL Error logging cheat username for "..steamid..": "..tostring(err))
        end
        query:start()
    end)
end

function CNAC.SQL.GetCheatUsernames(steamid, callback)
    if (not CNAC.SQL.Connected) then
        return
    end

    local sid64 = util.SteamIDTo64(steamid)
    if (not sid64 or tostring(sid64) == "0") then
        CNAC.Print("Invalid SQL log SteamID64 for "..tostring(steamid))
        return
    end

    local query = SQL:prepare("SELECT * FROM `cnac_cheat_usernames` WHERE `steamid` = ?")
    query:setString(1, steamid)
    function query:onSuccess(data)
        if (not data) then
            callback({})
            return
        end

        callback(data)
    end
    function query:onError(err)
        CNAC.Print("SQL Error getting cheat usernames for "..steamid..": "..tostring(err))

        callback({})
    end
    query:start()
end

function CNAC.SQL.GetCurrentBanWave(callback)
    if (not CNAC.SQL.Connected) then
        return
    end

    local query = SQL:prepare("SELECT * FROM `network`.`cnac_ban_wave` WHERE `banned` = 0")
    function query:onSuccess(data)
        if (not data) then
            callback({})
            return
        end

        callback(data)
    end
    function query:onError(err)
        CNAC.Print("SQL Error getting ban wave: "..tostring(err))

        callback({})
    end
    query:start()
end

function CNAC.SQL.InsertPendingBan(steamid, callback)
    if (not CNAC.SQL.Connected) then
        return
    end

    local query = SQL:prepare("INSERT INTO `network`.`cnac_ban_wave` (`steamid`, `banned`, `time`) VALUES (?, 0, ?) ON DUPLICATE KEY UPDATE `time` = ?, `banned` = 0")
    query:setString(1, steamid)
    query:setNumber(2, os.time())
    function query:onSuccess()
        if (callback) then
            callback(true)
        end
    end
    function query:onError(err)
        CNAC.Print("SQL Error inserting pending ban for "..steamid..": "..tostring(err))

        if (callback) then
            callback(false)
        end
    end
    query:start()
end

function CNAC.SQL.MarkBanned(steamid, callback)
    if (not CNAC.SQL.Connected) then
        return
    end

    local query = SQL:prepare("UPDATE `network`.`cnac_ban_wave` SET `banned` = 1 WHERE `steamid` = ?")
    query:setString(1, steamid)
    function query:onSuccess()
        if (callback) then
            callback(true)
        end
    end
    function query:onError(err)
        CNAC.Print("SQL Error marking banned for "..steamid..": "..tostring(err))

        if (callback) then
            callback(false)
        end
    end
    query:start()
end

hook.Add("CNAC_PostDetection", "cn_anti_cheat", function(ply, detectionMessage, detectionCode, subCode, args)
    local steamid = ply:SteamID()
    CNAC.SQL.LoggedDetections[steamid] = CNAC.SQL.LoggedDetections[steamid] or {}
    CNAC.SQL.LoggedDetections[steamid][detectionCode] = CNAC.SQL.LoggedDetections[steamid][detectionCode] or {
        count = 0,
        subCodes = {},
    }

    if (CNAC.SQL.LoggedDetections[steamid][detectionCode].subCodes[subCode]) then
        return
    end

    CNAC.SQL.LoggedDetections[steamid][detectionCode].subCodes[subCode] = true
    CNAC.SQL.LoggedDetections[steamid][detectionCode].count = CNAC.SQL.LoggedDetections[steamid][detectionCode].count + 1

    if (CNAC.SQL.LoggedDetections[steamid][detectionCode].count > 5) then
        return
    end

    CNAC.SQL.LogDetection(ply:SteamID(), detectionCode, subCode, detectionMessage)
end)

hook.Add("CNAC_LogCheatUsername", "cn_anti_cheat", function(steamid, cheat, cheatUsername)
    CNAC.SQL.LogCheatUsername(steamid, cheat, cheatUsername)
end)

hook.Add("SQLConnected", "cn_anti_cheat", function()
	CNAC.SQL.Initialize()

    CNAC.SQL.Connected = true
end)
CNAC.SQL.Initialize()