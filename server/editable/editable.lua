
function GetDiscordDescription(model, license, player)
    local description = '- **' .. L('Vehicle') .. '**: ' .. model ..
            '\n- **' .. L('License plate') .. '**: ' .. license ..
            '\n- **' .. L('Date') .. '**: '.. os.date("%A, %m %B %Y - %H:%M")

    if Config.webhook.includeUserName then
        description = description .. '\n\n'.. L('User') .. ': ' .. GetPlayerName(player)
    end
    if Config.webhook.includeSteamId then
        if not Config.webhook.includeUserName then
            description = description .. '\n'
        end
        description = description .. '\n*' .. GetIdentifier(player) .. '*'
    end

    return description
end

function GetIdentifier(player)
    for k, v in ipairs(GetPlayerIdentifiers(player)) do
        if string.match(v, 'license:') then
            return v:gsub('license:', '')
        end
    end
    return ''
end

RegisterCommand('kq_dyno_restart', function(source)
    TriggerClientEvent('kq_dyno:client:prepareRestart', -1, source)
end, true)
