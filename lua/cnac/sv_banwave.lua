
function CNAC.DoBanWave(onlineOnly, callback)
    CNAC.Print("Processing current ban wave...")

    if (onlineOnly) then
        CNAC.Print("Ban wave only processing online players.")
    end
    
    if (not KAdmin or not KAdmin.Blacklist) then
        CNAC.Print("Error: KAdmin or KAdmin.Blacklist is not loaded, cannot perform ban wave.")

        if (callback) then
            callback(false, "KAdmin or KAdmin.Blacklist is not loaded, cannot perform ban wave.")
        end

        return
    end

    CNAC.SQL.GetCurrentBanWave(function(bans)
        CNAC.Print("Processing "..#bans.." bans...")
        
        for _, ban in pairs(bans) do
            if (onlineOnly) then
                local ply = player.GetBySteamID(ban.steamid)
                if (not IsValid(ply)) then
                    continue
                end
            end

            CNAC.DoBan(ban.steamid)
        end

        CNAC.Print("Ban wave complete.")

        if (callback) then
            callback(true, #bans)
        end
    end)
end

function CNAC.DoBan(steamid)
    CNAC.Print("Banning "..steamid.."...")

    local steamid64 = util.SteamIDTo64(steamid)
    KAdmin.Blacklist.AddBlacklist(steamid64, "Cheating", "CNAC", nil, function(success, err)
        if (not success) then
            CNAC.Print("Failed to ban "..steamid..": "..tostring(err))
            return
        end

        CNAC.SQL.MarkBanned(steamid)
    end)
end

function CNAC.AddToBanWave(ply, callback)
    if (isentity(ply)) then
        if (not IsValid(ply) or not ply:IsPlayer()) then
            return
        end

        ply = ply:SteamID()
    end

    CNAC.SQL.InsertPendingBan(ply, callback)

    for k, v in player.Iterator() do
        if (v:IsSuperAdmin()) then
            v:ChatPrint("[CNAC] "..ply.." has been detected for cheating and marked for the next ban wave.")
        end
    end
end