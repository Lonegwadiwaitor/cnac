
function CNAC.PostDiscordEmbed(callback)
    if (not DiscordBot) then
        CNAC.Print("DiscordBot is not installed, cannot post embeds.")
        return
    end

    for _, webhook in ipairs(CNAC.DiscordWebhooks) do
        DiscordBot:StartEmbed()

        callback()
        
        DiscordBot:SendEmbed(webhook)
    end
end