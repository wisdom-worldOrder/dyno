-- Set webhook configuration convars
if Config.webhook.enabled then
    SetConvarReplicated("kq_dyno_webhook", "true")
end

SetConvarReplicated("kq_dyno_title", Config.webhook.title or "KuzQuality - DynoTech")

-- Localization function
function L(key)
    if Locale and Locale[key] then
        return Locale[key]
    end
    return key
end

-- Check if table contains a value
function Contains(table, value)
    for _, item in ipairs(table) do
        if item == value then
            return true
        end
    end
    return false
end

-- Start dyno test event handler
RegisterNetEvent("kq_dyno:server:start-dyno")
AddEventHandler("kq_dyno:server:start-dyno", function(vehicleNetworkId, dynoIndex)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetworkId)
    
    EnsureEntityStateBag(vehicle)
    
    -- Set vehicle dyno state
    Entity(vehicle).state.kq_using_dyno = dynoIndex
    Entity(vehicle).state.kq_dyno_logging = true
    Entity(vehicle).state.kq_dyno_rpm = 0
    Entity(vehicle).state.kq_dyno_real_rpm = 0
    Entity(vehicle).state.kq_dyno_torque = 0
    Entity(vehicle).state.kq_dyno_hp = 0
end)

-- Finish dyno test event handler
RegisterNetEvent("kq_dyno:server:finish-dyno")
AddEventHandler("kq_dyno:server:finish-dyno", function(vehicleNetworkId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetworkId)
    
    Entity(vehicle).state.kq_using_dyno = false
end)

-- Finish logging event handler
RegisterNetEvent("kq_dyno:server:finish-logging")
AddEventHandler("kq_dyno:server:finish-logging", function(vehicleNetworkId)
    local vehicle = NetworkGetEntityFromNetworkId(vehicleNetworkId)
    
    Entity(vehicle).state.kq_dyno_logging = false
end)

-- Save dyno image event handler
RegisterNetEvent("kq_dyno:server:save-dyno-image")
AddEventHandler("kq_dyno:server:save-dyno-image", function(imageData, horsepower, torque, dynoIndex)
    SendToDiscord(source, imageData, horsepower, torque, dynoIndex)
end)

-- Send dyno results to Discord webhook
function SendToDiscord(playerId, imageData, horsepower, torque, dynoIndex)
    -- Check if webhook is enabled and valid
    if not Config.webhook.enabled or not string.find(Config.webhook.url, "https://discord.com/") then
        return
    end
    
    local webhookUrl = Config.webhook.url
    
    -- Use dyno-specific webhook if configured
    if Config.webhook.dynoSpecific and Config.webhook.dynoSpecific[dynoIndex] then
        webhookUrl = Config.webhook.dynoSpecific[dynoIndex]
    end
    
    -- Exit if webhook URL is invalid
    if webhookUrl == false or webhookUrl == nil then
        return
    end
    
    -- Update Discord bot avatar and get user info
    PerformHttpRequest(webhookUrl, function(statusCode, responseData, headers)
        Citizen.Wait(1000)
        
        local discordData = json.decode(responseData)
        local userId = discordData.id
        local avatarHash = discordData.avatar
        
        local description = GetDiscordDescription(torque, horsepower, playerId)
        
        local embeds = {}
        local embed = {
            color = Config.webhook.color or 16723456,
            title = L("Dyno performance report"),
            description = description,
            image = {
                url = "https://cdn.discordapp.com/avatars/" .. userId .. "/" .. avatarHash .. ".webp?size=1280"
            },
            footer = {
                text = L("Dyno technology by KuzQuality.com")
            }
        }
        
        embeds[1] = embed
        
        -- Send the actual webhook message
        PerformHttpRequest(webhookUrl, function(responseCode)
            if responseCode ~= 200 and responseCode ~= 204 then
                print("Something went wrong while sending the discord webhook", responseCode)
            end
        end, "POST", json.encode({
            username = "Dyno",
            embeds = embeds
        }), {
            ["Content-Type"] = "application/json"
        })
        
    end, "PATCH", json.encode({
        name = "Dyno",
        avatar = imageData
    }), {
        ["Content-Type"] = "application/json"
    })
end
