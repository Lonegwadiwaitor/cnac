
CNAC.Config = {}

---------------- IMPORTANT BIG COMMENT ----------------

-- THESE CONFIG TABLES MUST MATCH THE TABLES IN THE CLIENT FILE
-- DO NOT FORGET TO UPDATE THE CLIENT FILE IF YOU CHANGE ANYTHING HERE

---------------- IMPORTANT BIG COMMENT ----------------

CNAC.Config.CheatNames = {
    "oink.industries",
    "cheadleware",
    "unknown",
}

-- Will be moved to external file later
CNAC.DiscordWebhooks = {
    
}

local token = file.Read(".cnac_discord_token.dat", "GAME")

if (token) then
    table.insert(CNAC.DiscordWebhooks, token)
end

CNAC.Config.IllegalConvars = {
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

CNAC.Config.GenericConvars = {
    "exploit",
    "aimbot",
    "antiaim",
    "bhop",
    "bunnyhop",
    -- "_menu",
}

CNAC.Config.IllegalFontNames = {
    "onehack.font", -- onehack
    "VisualsFont", -- idiotbox
    "memes", -- "acebot"
}