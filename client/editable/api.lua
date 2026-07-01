-- Triggered when player starts a dyno run
function OnDynoStart(dynoKey)
    if Config.esxSettings.enabled and ESX then
        ESX.ShowNotification('Teste do dinamômetro iniciado!')
    end
end

-- Triggered when the dyno run is fully finished
function OnDynoFinish(dynoKey)
    if Config.esxSettings.enabled and ESX then
        ESX.ShowNotification('Teste do dinamômetro concluído!')
    end
end
