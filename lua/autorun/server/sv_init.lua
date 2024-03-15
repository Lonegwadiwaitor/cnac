
CNAC = CNAC or {}

function CNAC.Print(...)
    local date = os.date("%Y-%m-%d %H:%M:%S", os.time())
    print(date.." [CNAC]", ...)
end

include("cnac/sv_config.lua")
include("cnac/sv_sql.lua")
include("cnac/sv_cnac.lua")
include("cnac/sv_banwave.lua")
include("cnac/sv_messaging.lua")