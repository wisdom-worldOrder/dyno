
function GetVehicleStats(veh)
    if not Config.dynoFormula then
        return GetVehicleStatsVanilla(veh)
    end

    if Config.dynoFormula == 'highperformance1' then
        return GetVehicleStatsAlternative(veh)
    end

    if Config.dynoFormula == 'highperformance2' then
        return GetVehicleStatsAlternative2(veh)
    end

    if Config.dynoFormula == 'highperformance3' then
        return GetVehicleStatsAlternative3(veh)
    end

    return GetVehicleStatsVanilla(veh)
end



function GetVehicleStatsVanilla(veh)
    return UseCache('vehStats' .. veh, function()
        local fInitialDriveForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce')
        local fDriveInertia = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveInertia')
        local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel')
        local fMass = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')
        local nInitialDriveGears = GetVehicleHandlingFloat(veh, 'CHandlingData', 'nInitialDriveGears')

        local fDriveBiasFront = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveBiasFront')


        local drivetrainLoss = 0.1 -- awd
        if fDriveBiasFront >= 0.85 then
            drivetrainLoss = 0.13 -- fwd
        end
        if fDriveBiasFront <= 0.15 then
            drivetrainLoss = 0.2 -- rwd
        end

        local wheelPower = GetWheelPower(veh)

        if IsVehicleFwd(veh) then
            wheelPower = wheelPower * fDriveBiasFront
        else
            wheelPower = wheelPower * (1 - fDriveBiasFront)
        end

        local rpm = GetVehicleCurrentRpm(veh)

        local maxRpm = ((math.min(161.0, fInitialDriveMaxFlatVel) / nInitialDriveGears / 30) * 8500) * 0.95
        local realRpm = math.floor(rpm * maxRpm)

        local torque = math.floor((fInitialDriveForce * fMass) * (realRpm / maxRpm)
                + (wheelPower * 40)
                * (math.min(4.0, math.max(0.7, (fMass / 1700) ^ 3)))
        )

        local hpMultiplier = 0.95
        if fInitialDriveMaxFlatVel >= 150 then
            hpMultiplier = 1.0
        end
        if fInitialDriveMaxFlatVel >= 159 then
            hpMultiplier = 1.1
            torque = math.floor(torque * 1.05)
        end
        if fInitialDriveMaxFlatVel >= 159.5 then
            hpMultiplier = 1.15
            torque = math.floor(torque * 1.15)
        end
        if fInitialDriveMaxFlatVel >= 164.0 then
            hpMultiplier = 1.05
            torque = math.floor(torque * 1.1)
        end

        local hp = math.abs(math.floor(DiminishingReturns(
                ((torque / 1.356) * (rpm * maxRpm) / 5252)
                        * fDriveInertia
                        * (math.min(160.0, fInitialDriveMaxFlatVel) / 150)
                        * wheelPower
                        * (1 - drivetrainLoss)
                        * hpMultiplier
                        * (math.min(2.0, math.max(0.95, fMass / 1400)))
        )))

        local torqueInUnits = torque

        if UsingFtLbs() then
            torqueInUnits = torque / 1.356
        end

        return hp, torqueInUnits, realRpm, rpm
    end, 50)
end


function GetVehicleStatsAlternative(veh)
    return UseCache('vehStats' .. veh, function()
        local fInitialDriveForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce')
        local fDriveInertia = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveInertia')
        local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel')
        local fMass = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')
        local nInitialDriveGears = GetVehicleHandlingFloat(veh, 'CHandlingData', 'nInitialDriveGears')

        local fDriveBiasFront = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveBiasFront')


        local drivetrainLoss = 0.1 -- awd
        if fDriveBiasFront >= 0.85 then
            drivetrainLoss = 0.13 -- fwd
        end
        if fDriveBiasFront <= 0.15 then
            drivetrainLoss = 0.2 -- rwd
        end

        local wheelPower = GetWheelPower(veh)

        if IsVehicleFwd(veh) then
            wheelPower = wheelPower * fDriveBiasFront
        else
            wheelPower = wheelPower * (1 - fDriveBiasFront)
        end

        local rpm = GetVehicleCurrentRpm(veh)

        local maxRpm = ((math.min(161.0, fInitialDriveMaxFlatVel) / nInitialDriveGears / 30) * 8500) * 0.95
        local realRpm = math.floor(rpm * maxRpm)

        local torque = math.floor((fInitialDriveForce * fMass) * (realRpm / maxRpm)
                + (wheelPower * 40)
                * (math.min(4.0, math.max(0.7, (fMass / 1700) ^ 3)))
        )

        local hpMultiplier = 0.95
        if fInitialDriveMaxFlatVel >= 150 then
            hpMultiplier = 1.0
        end
        if fInitialDriveMaxFlatVel >= 159 then
            hpMultiplier = 1.1
            torque = math.floor(torque * 1.05)
        end
        if fInitialDriveMaxFlatVel >= 159.5 then
            hpMultiplier = 1.15
            torque = math.floor(torque * 1.15)
        end
        if fInitialDriveMaxFlatVel >= 164.0 then
            hpMultiplier = 1.05
            torque = math.floor(torque * 1.1)
        end

        local hp = math.abs(math.floor(DiminishingReturns(
                ((torque / 1.356) * (rpm * maxRpm) / 5252)
                        * fDriveInertia
                        * math.min(1.1, wheelPower)
                        * (1 - drivetrainLoss)
                        * hpMultiplier
                        * (math.min(2.0, math.max(0.95, fMass / 1400)))
        )))

        local torqueInUnits = torque

        if UsingFtLbs() then
            torqueInUnits = torque / 1.356
        end

        return hp, torqueInUnits, realRpm, rpm
    end, 50)
end

function GetVehicleStatsAlternative2(veh)
    return UseCache('vehStats' .. veh, function()
        local fInitialDriveForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce')
        local fDriveInertia = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveInertia')
        local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel')
        local fMass = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')
        local nInitialDriveGears = GetVehicleHandlingFloat(veh, 'CHandlingData', 'nInitialDriveGears')

        local fDriveBiasFront = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveBiasFront')


        local drivetrainLoss = 0.1 -- awd
        if fDriveBiasFront >= 0.85 then
            drivetrainLoss = 0.13 -- fwd
        end
        if fDriveBiasFront <= 0.15 then
            drivetrainLoss = 0.2 -- rwd
        end

        local wheelPower = GetWheelPower(veh)

        if IsVehicleFwd(veh) then
            wheelPower = wheelPower * fDriveBiasFront
        else
            wheelPower = wheelPower * (1 - fDriveBiasFront)
        end

        local rpm = GetVehicleCurrentRpm(veh)

        local maxRpm = ((math.min(161.0, fInitialDriveMaxFlatVel) / nInitialDriveGears / 30) * 8500) * 0.95
        local realRpm = math.floor(rpm * maxRpm)

        local torque = math.floor(((fInitialDriveForce * 0.5) * fMass) * (realRpm / maxRpm)
                + (math.min(3.0, wheelPower))
                * (math.min(4.0, math.max(0.7, (fMass / 1700) ^ 3)))
        )

        local hpMultiplier = 0.95
        if fInitialDriveMaxFlatVel >= 150 then
            hpMultiplier = 1.0
        end
        if fInitialDriveMaxFlatVel >= 159 then
            hpMultiplier = 1.1
            torque = math.floor(torque * 1.05)
        end
        if fInitialDriveMaxFlatVel >= 159.5 then
            hpMultiplier = 1.15
            torque = math.floor(torque * 1.15)
        end
        if fInitialDriveMaxFlatVel >= 164.0 then
            hpMultiplier = 1.05
            torque = math.floor(torque * 1.1)
        end

        local hp = math.abs(math.floor(DiminishingReturns(
                ((torque / 1.356) * (rpm * maxRpm) / 5252)
                        * fDriveInertia
                        * (math.min(160.0, fInitialDriveMaxFlatVel) / 250)
                        * math.min(2.0, wheelPower)
                        * (1 - drivetrainLoss)
                        * hpMultiplier
                        * (math.min(2.0, math.max(0.95, fMass / 1400)))
        )))

        local torqueInUnits = torque

        if UsingFtLbs() then
            torqueInUnits = torque / 1.356
        end

        return hp, torqueInUnits, realRpm, rpm
    end, 50)
end



function GetVehicleStatsAlternative3(veh)
    return UseCache('vehStats' .. veh, function()
        local fInitialDriveForce = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveForce')
        local fDriveInertia = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveInertia')
        local fInitialDriveMaxFlatVel = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fInitialDriveMaxFlatVel')
        local fMass = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fMass')
        local nInitialDriveGears = GetVehicleHandlingFloat(veh, 'CHandlingData', 'nInitialDriveGears')

        local fDriveBiasFront = GetVehicleHandlingFloat(veh, 'CHandlingData', 'fDriveBiasFront')


        local drivetrainLoss = 0.1 -- awd
        if fDriveBiasFront >= 0.85 then
            drivetrainLoss = 0.13 -- fwd
        end
        if fDriveBiasFront <= 0.15 then
            drivetrainLoss = 0.2 -- rwd
        end

        local wheelPower = GetWheelPower(veh)

        if IsVehicleFwd(veh) then
            wheelPower = wheelPower * fDriveBiasFront
        else
            wheelPower = wheelPower * (1 - fDriveBiasFront)
        end

        local rpm = GetVehicleCurrentRpm(veh)

        local maxRpm = ((math.min(161.0, fInitialDriveMaxFlatVel) / nInitialDriveGears / 35) * 8500) * 0.95
        local realRpm = math.floor(rpm * maxRpm)

        local torque = math.floor(((fInitialDriveForce * 0.4) * fMass) * (realRpm / maxRpm)
                + (math.min(2.0, wheelPower / 2))
                * (math.min(4.0, math.max(0.7, (fMass / 1700) ^ 3)))
        )

        local hpMultiplier = 0.95
        if fInitialDriveMaxFlatVel >= 150 then
            hpMultiplier = 1.0
        end
        if fInitialDriveMaxFlatVel >= 159 then
            hpMultiplier = 1.1
            torque = math.floor(torque * 1.05)
        end
        if fInitialDriveMaxFlatVel >= 159.5 then
            hpMultiplier = 1.15
            torque = math.floor(torque * 1.15)
        end
        if fInitialDriveMaxFlatVel >= 164.0 then
            hpMultiplier = 1.05
            torque = math.floor(torque * 1.1)
        end

        local hp = math.abs(math.floor(DiminishingReturns(
                ((torque / 1.356) * (rpm * maxRpm) / 5252)
                        * fDriveInertia
                        * math.min(2.0, wheelPower / 2)
                        * (1 - drivetrainLoss)
                        * hpMultiplier
                        * (math.min(2.0, math.max(0.95, fMass / 1400)))
        )))

        local torqueInUnits = torque

        if UsingFtLbs() then
            torqueInUnits = torque / 1.356
        end

        return hp, torqueInUnits, realRpm, rpm
    end, 50)
end



function GetWheelPower(veh)
    local power = 0
    for i = 0 , GetVehicleNumberOfWheels(veh) - 1 do
        power = power + GetVehicleWheelPower(veh, i) * (GetVehicleWheelTireColliderSize(veh, i) * 2 + 0.15)
    end
    return power
end

function DiminishingReturns(x)
    return x * (1 - (math.min(0.3, (x + 100) / 2400) - 0.05))
end


function UsingFtLbs()
    return Config.torqueUnits == 'lb-ft' or Config.torqueUnits == 'lbs' or Config.torqueUnits == 'ft-lb'
end

function GetTorqueUnit()
    if UsingFtLbs() then
        return L('lb-ft')
    end
    return L('nm')
end

function IsPlayerUnreachable()
    local playerPed = PlayerPedId()
    return IsPedRagdoll(playerPed) or IsEntityDead(playerPed)
end


function KeybindTip(message)
    SetTextComponentFormat("STRING")
    AddTextComponentString(message)
    EndTextCommandDisplayHelp(0, 0, 0, 200)
end

-- This function is responsible for all the tooltips displayed on top right of the screen, you could
-- replace it with a custom notification etc.
function Notify(message)
    SetTextComponentFormat("STRING")
    AddTextComponentString(message)
    EndTextCommandDisplayHelp(0, 0, 0, -1)
end

RegisterNetEvent('kq_dyno:client:notify')
AddEventHandler('kq_dyno:client:notify', function(message)
    Notify(message)
end)

function PlayAnim(dict, anim, flag, duration)
    Citizen.CreateThread(function()
        RequestAnimDict(dict)
        local timeout = 0
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(50)
            timeout = timeout + 1
            if timeout > 100 then
                return
            end
        end
        TaskPlayAnim(PlayerPedId(), dict, anim, 1.5, 1.0, duration or -1, flag or 1, 0, false, false, false)
        RemoveAnimDict(dict)
    end)
end

function DrawDynoMarker(dyno)
    DrawMarker(43, dyno.coords + vector3(0.0, 0.0, -1.0), 0.0, 0.0, 0.0, 0.0, 0.0, dyno.heading, 2.5, 1.0, 0.5, 40, 110, 250, 30, 0, 0, 0, 0)
end

function CanPerformDynoTests(dynoKey)
    return UseCache('CanPerformDynoTests' .. dynoKey, function()
        local dyno = Config.dynos[dynoKey]

        return (not Config.jobWhitelist.enabled or (not PLAYER_JOB or not dyno.jobs or Contains(dyno.jobs, PLAYER_JOB)))
    end, 5000)
end

-- Keybinds display
buttons = nil
keybinds = {}

function AddKeybindDisplay(key, label)
    buttons = nil
    
    table.insert(keybinds, {
        key = '~' .. key .. '~',
        label = label,
    })
    
    buttons = RequestScaleformMovie("INSTRUCTIONAL_BUTTONS")
    while not HasScaleformMovieLoaded(buttons) do
        Wait(0)
    end
    
    BeginScaleformMovieMethod(buttons, "CLEAR_ALL")
    EndScaleformMovieMethod()
    
    for k, keybind in pairs(keybinds) do
        BeginScaleformMovieMethod(buttons, "SET_DATA_SLOT")
        ScaleformMovieMethodAddParamInt(k - 1)
        ScaleformMovieMethodAddParamPlayerNameString(keybind.key)
        PushScaleformMovieMethodParameterString(keybind.label)
        EndScaleformMovieMethod()
    end
    
    BeginScaleformMovieMethod(buttons, "DRAW_INSTRUCTIONAL_BUTTONS")
    EndScaleformMovieMethod()
end

function ClearKeybinds()
    buttons = nil
    keybinds = {}
end


Citizen.CreateThread(function()
    while true do
        local sleep = 500
        
        if buttons ~= nil then
            sleep = 1
            DrawScaleformMovieFullscreen(buttons, 255, 255, 255, 255, 0)
        end
        Citizen.Wait(sleep)
    end
end)
