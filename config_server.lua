
-- Discord webhook options
Config.webhook = {
    enabled = false, -- Whether to send the dyno sheets to the discord webhook

    -- To get the Discord webhook link, right click on a channel > Edit channel > Integrations > Webhooks > View webhooks > New webhook
    url = 'YOUR_WEBHOOK_URL_HERE',

    -- Here you can add webhooks for specific dynos. Based on the dyno key/index name (same as in config.lua)
    dynoSpecific = {
        ['bennys'] = 'DYNO_SPECIFIC_WEBHOOK_URL_HERE', -- remove this line if you don't want to use a dyno specific webhooks
    },

    -- Replace this with the name of your server or a title you want on your dyno sheets
    title = 'KuzQuality - DynoTech',

    -- Whether to include certain parts of the users info in the webhook messages
    includeUserName = true,
    includeSteamId = true,

    color = 16723456,
}
