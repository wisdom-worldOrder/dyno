-- Get webhook title from convar
local webhookTitle = GetConvar("kq_dyno_title", "KuzQuality - DynoTech")
WEBHOOK_TITLE = webhookTitle

-- Main dyno interaction thread
Citizen.CreateThread(function()
    while true do
        local sleepTime = 3000
        local playerPed = PlayerPedId()
        local nearestDyno, dynoIndex, distance = GetNearestDyno()
        local isInVehicle = IsPedInAnyVehicle(playerPed, 0)
        
        if isInVehicle then
            local isUnreachable = IsPlayerUnreachable()
            if not isUnreachable then
                local vehicle = GetVehiclePedIsUsing(playerPed)
                
                if nearestDyno then
                    sleepTime = 1500
                    
                    if distance <= 4.0 then
                        sleepTime = 1000
                        local touchingSides = IsTouchingSides(nearestDyno, vehicle)
                        local isRunning = IsRunningDyno(vehicle)
                        
                        -- Sempre mostrar marker quando próximo e não rodando teste
                        if not isRunning then
                            DrawDynoMarker(nearestDyno)
                            sleepTime = 1
                        end
                            
                        
                        -- Verificar se pode interagir com o dyno
                        if distance <= 3.0 and not isRunning then
                            sleepTime = 1
                            local canPerformTests = CanPerformDynoTests(dynoIndex)
                            
                            if canPerformTests then
                                local startPrompt = L("Press ~{INPUT}~ to start the dyno test")
                                startPrompt = startPrompt:gsub("{INPUT}", Config.keybinds.start.name)
                                KeybindTip(startPrompt)
                                
                                if IsControlJustReleased(0, Config.keybinds.start.input) then
                                    RunDynoTest(dynoIndex)
                                end
                            else
                                KeybindTip(L("~r~You are not allowed to perform dyno tests"))
                            end
                        end
                    end
                end
            end
        end
        
        Citizen.Wait(sleepTime)
    end
end)

-- Dyno roller animation thread
Citizen.CreateThread(function()
    while true do
        local sleepTime = 3000
        local nearestDyno, dynoIndex, distance = GetNearestDyno()
        
        if nearestDyno then
            local hasRollers = nearestDyno.rollers
            
            if hasRollers then
                local nearestVehicle = GetNearestVehicle(nearestDyno.coords)
                
                if nearestVehicle then
                    sleepTime = 250
                    local isRunningDyno = IsRunningDyno(nearestVehicle)
                    
                    if isRunningDyno then
                        sleepTime = 20
                        local wheelSpeed = 0
                        local isVehicleFwd = IsVehicleFwd(nearestVehicle)
                        
                        if isVehicleFwd then
                            wheelSpeed = GetVehicleWheelSpeed(nearestVehicle, 0)
                        else
                            wheelSpeed = -GetVehicleWheelSpeed(nearestVehicle, 2)
                        end
                        
                        -- Animate each roller
                        for rollerIndex, roller in pairs(nearestDyno.rollers) do
                            if roller.object then
                                if not roller.spin then
                                    roller.spin = 0
                                end
                                
                                roller.spin = roller.spin + (wheelSpeed * roller.direction * 40)
                                roller.spin = roller.spin % 360
                                
                                local dynoRotation = GetEntityRotation(nearestDyno.object)
                                local spinRotation = vector3(0.0, roller.spin, 0.0)
                                local finalRotation = dynoRotation + spinRotation + roller.rotation
                                
                                SetEntityRotation(roller.object, finalRotation.x, finalRotation.y, finalRotation.z, 0, 0)
                            end
                        end
                    end
                end
            end
        end
        
        Citizen.Wait(sleepTime)
    end
end)

-- Start data synchronization for vehicle stats
function StartDataSync(vehicle)
    Citizen.CreateThread(function()
        while true do
            if not DoesEntityExist(vehicle) then
                break
            end
            
            if not IsRunningDyno(vehicle) then
                break
            end
            
            local horsepower, torque, realRpm, displayRpm = GetVehicleStats(vehicle)
            
            -- Set vehicle state data for UI display
            Entity(vehicle).state:set("kq_dyno_rpm", displayRpm, true)
            Entity(vehicle).state:set("kq_dyno_real_rpm", realRpm, true)
            Entity(vehicle).state:set("kq_dyno_hp", horsepower, true)
            Entity(vehicle).state:set("kq_dyno_torque", torque, true)
            
            Citizen.Wait(150)
        end
    end)
end

-- Main dyno test execution function
function RunDynoTest(dynoIndex)
    local playerPed = PlayerPedId()
    local vehicle = GetVehiclePedIsUsing(playerPed)
    local networkId = NetworkGetNetworkIdFromEntity(vehicle)
    
    if not networkId then
        error("Entity network id not found")
    end
    
    -- Initialize dyno test
    OnDynoStart(dynoIndex)
    DestroyDynoDisplay(dynoIndex)
    Citizen.Wait(50)
    
    -- Start server-side dyno test
    TriggerServerEvent("kq_dyno:server:start-dyno", networkId, dynoIndex)
    Citizen.Wait(50)
    
    -- Clear cache and prepare vehicle
    WipeCache("isRunningDyno_" .. vehicle)
    SetVehicleCurrentRpm(vehicle, 0.1)
    
    -- Main dyno test thread
    Citizen.CreateThread(function()
        -- Disable physics and freeze vehicle
        SetVehicleGravity(vehicle, false)
        Citizen.Wait(50)
        FreezeEntityPosition(vehicle, true)
        DisableVehicleWorldCollision(vehicle)
        
        local testComplete = false
        local rpmPeakReached = false
        local peakTime = nil
        local finishLoggingStarted = false
        
        Citizen.Wait(750)
        StartDataSync(vehicle)
        Citizen.Wait(750)
        
        local currentRpm = GetVehicleCurrentRpm(vehicle)
        local startTime = GetGameTimer()
        
        -- Main test loop
        while not testComplete do
            Citizen.Wait(1)
            local elapsedTime = (GetGameTimer() - startTime) / 10
            
            if not DoesEntityExist(vehicle) then
                return
            end
            
            -- Check if RPM peak is reached
            if currentRpm >= 0.98 and not rpmPeakReached then
                rpmPeakReached = true
                peakTime = GetGameTimer()
            end
            
            if rpmPeakReached then
                -- Start finish logging after peak
                if not finishLoggingStarted then
                    finishLoggingStarted = true
                    Citizen.CreateThread(function()
                        Citizen.Wait(2000)
                        TriggerServerEvent("kq_dyno:server:finish-logging", networkId)
                    end)
                end
                
                -- RPM decay after peak
                local decayRate = (currentRpm * 0.0005) + 0.0004
                decayRate = decayRate * elapsedTime
                
                -- Apply different decay rates based on RPM
                if currentRpm >= 0.94 then
                    decayRate = decayRate * 0.75
                end
                if currentRpm >= 0.96 then
                    decayRate = decayRate * 0.6
                end
                if currentRpm >= 0.97 then
                    decayRate = decayRate * 0.4
                end
                
                currentRpm = currentRpm - decayRate
                
                -- End test when RPM drops low enough
                if currentRpm <= 0.2 then
                    testComplete = true
                end
            else
                -- RPM buildup phase
                local buildupRate = math.min(0.0003, currentRpm * 0.0003)
                buildupRate = 0.0006 - buildupRate
                buildupRate = buildupRate * elapsedTime
                
                -- Apply different buildup rates based on RPM
                if currentRpm >= 0.94 then
                    buildupRate = buildupRate * 0.75
                end
                if currentRpm >= 0.96 then
                    buildupRate = buildupRate * 0.6
                end
                if currentRpm >= 0.97 then
                    buildupRate = buildupRate * 0.4
                end
                
                currentRpm = math.min(0.98, currentRpm + buildupRate)
            end
            
            if not DoesEntityExist(vehicle) then
                return
            end
            
            -- Update vehicle RPM and wheel rotation
            SetVehicleCurrentRpm(vehicle, currentRpm)
            TaskVehicleTempAction(playerPed, vehicle, 32, 1)
            
            -- Animate wheels if RPM is high enough
            if currentRpm > 0.2 then
                local wheelCount = GetVehicleNumberOfWheels(vehicle)
                for wheelIndex = 0, wheelCount - 1 do
                    local isVehicleFwd = IsVehicleFwd(vehicle)
                    
                    if isVehicleFwd then
                        if wheelIndex <= 1 then
                            SetVehicleWheelRotationSpeed(vehicle, wheelIndex, -44.1 * currentRpm)
                        end
                    else
                        if wheelIndex >= 2 then
                            SetVehicleWheelRotationSpeed(vehicle, wheelIndex, -44.1 * currentRpm)
                        end
                    end
                end
            end
            
            startTime = GetGameTimer()
        end
        
        -- Restore vehicle physics and finish test
        Citizen.Wait(100)
        SetVehicleGravity(vehicle, true)
        SetEntityCollision(vehicle, true, true)
        FreezeEntityPosition(vehicle, false)
        
        CaptureDynoImage(dynoIndex)
        OnDynoFinish(dynoIndex)
        TriggerServerEvent("kq_dyno:server:finish-dyno", networkId)
    end)
end

-- Capture dyno test image for webhook
function CaptureDynoImage(dynoIndex)
    local dynoConfig = Config.dynos[dynoIndex]
    
    if dynoConfig.dui then
        local webhookEnabled = GetConvar("kq_dyno_webhook", "false")
        
        if webhookEnabled == "true" then
            local captureData = {
                event = "capture-image",
                title = WEBHOOK_TITLE,
                dynoKey = dynoIndex
            }
            
            SendDuiMessage(dynoConfig.dui.duiObject, json.encode(captureData))
        end
    end
end

-- NUI callback for saving dyno images
RegisterNUICallback("SaveDynoImage", function(data, callback)
    local dynoKey = data.dynoKey or 1
    local canPerform = CanPerformDynoTests(dynoKey)
    
    if canPerform then
        local vehicle = GetVehiclePedIsUsing(PlayerPedId())
        local vehicleModel = GetEntityModel(vehicle)
        local makeName = GetMakeNameFromVehicleModel(vehicleModel)
        local displayName = GetDisplayNameFromVehicleModel(vehicleModel)
        local fullVehicleName = makeName .. " " .. displayName
        local plateText = GetVehicleNumberPlateText(vehicle)
        
        TriggerServerEvent("kq_dyno:server:save-dyno-image", data.img, plateText, fullVehicleName, data.dynoKey)
    end
    
    callback(true)
end)
