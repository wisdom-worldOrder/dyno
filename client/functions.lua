-- Global player job variable
PLAYER_JOB = nil

-- Localization function
function L(key)
    if Locale then
        if Locale[key] then
            return Locale[key]
        end
    end
    return key
end

-- Check if player is the driver of a vehicle
function IsPedDriver(vehicle)
    local driver = GetPedInVehicleSeat(vehicle, -1)
    local playerPed = PlayerPedId()
    return driver == playerPed
end

-- Get vehicle state statistics with caching
function GetVehicleStateStats(vehicle)
    return UseCache("vehStateStats" .. vehicle, function()
        local horsepower = Entity(vehicle).state.kq_dyno_hp or 0
        local torque = Entity(vehicle).state.kq_dyno_torque or 0
        local displayRpm = Entity(vehicle).state.kq_dyno_rpm or 0
        local realRpm = Entity(vehicle).state.kq_dyno_real_rpm or 0
        
        return horsepower, torque, realRpm, displayRpm
    end, 100)
end

-- Real wait function that blocks for specified milliseconds
function RealWait(milliseconds)
    local endTime = GetGameTimer() + milliseconds
    
    while endTime > GetGameTimer() do
        Citizen.Wait(100)
    end
end

-- Play animation with automatic cleanup
function PlayAnim(animDict, animName, flags, duration)
    Citizen.CreateThread(function()
        RequestAnimDict(animDict)
        
        local attempts = 0
        while not HasAnimDictLoaded(animDict) do
            Citizen.Wait(50)
            attempts = attempts + 1
            if attempts > 100 then
                return
            end
        end
        
        TaskPlayAnim(
            PlayerPedId(),
            animDict,
            animName,
            1.5,
            1.0,
            duration or -1,
            flags or 1,
            0,
            false,
            false,
            false
        )
        
        RemoveAnimDict(animDict)
    end)
end

-- Cached entity touching check
function IsEntityTouchingCached(entity1, entity2)
    return UseCache("touching_" .. entity1 .. "_" .. entity2, function()
        return IsEntityTouchingEntity(entity1, entity2)
    end, 500)
end

-- Check if table contains a value
function Contains(table, value)
    for _, tableValue in ipairs(table) do
        if tableValue == value then
            return true
        end
    end
    return false
end

-- Request model and wait for it to load
function DoRequestModel(modelName)
    local modelHash = GetHashKey(modelName)
    RequestModel(modelHash)
    
    local timeout = 2000
    while not HasModelLoaded(modelHash) and timeout > 0 do
        Citizen.Wait(20)
        timeout = timeout - 20
    end
end

-- Get nearest vehicle to coordinates with caching
function GetNearestVehicle(coords)
    return UseCache("nearestVehicle_" .. coords.x .. "_" .. coords.y .. "_" .. coords.z, function()
        local vehicles = GetGamePool("CVehicle")
        local closestDistance = 4.0
        local closestVehicle = nil
        
        for i = 1, #vehicles do
            local vehicleCoords = GetEntityCoords(vehicles[i])
            local distance = GetDistanceBetweenCoords(vehicleCoords, coords, 1)
            
            if closestDistance > distance then
                closestVehicle = vehicles[i]
                closestDistance = distance
            end
        end
        
        return closestVehicle
    end, 1000)
end

-- Check if vehicle is touching dyno sides
function IsTouchingSides(dyno, vehicle)
    return UseCache("touchingSides_" .. vehicle, function()
        -- If dyno has no model (is invisible), assume both sides are touching
        if not dyno.model then
            return {true, true}
        end
        
        local touchingSides = {false, false}
        
        -- Check each roller for contact
        for _, roller in pairs(dyno.rollers) do
            if roller.object then
                local isTouching = IsEntityTouchingCached(roller.object, vehicle)
                if isTouching then
                    touchingSides[roller.side] = true
                end
            end
        end
        
        return touchingSides
    end, 300)
end

-- Check if vehicle is running dyno test
function IsRunningDyno(vehicle)
    return UseCache("isRunningDyno_" .. vehicle, function()
        return Entity(vehicle).state.kq_using_dyno
    end, 200)
end

-- Check if vehicle is logging dyno data
function IsLoggingData(vehicle)
    return UseCache("isLoggingData_" .. vehicle, function()
        return Entity(vehicle).state.kq_dyno_logging
    end, 200)
end

-- Get offset position with heading rotation
function GetOffsetWithHeading(baseCoords, offset, heading)
    if heading == nil then
        return
    end
    
    local headingRadians = heading * math.pi / 180
    
    -- Apply rotation matrix
    local rotatedX = offset.x * math.cos(headingRadians) - offset.y * math.sin(headingRadians)
    local rotatedY = offset.x * math.sin(headingRadians) + offset.y * math.cos(headingRadians)
    
    return vector3(
        baseCoords.x + rotatedX,
        baseCoords.y + rotatedY,
        baseCoords.z + offset.z
    )
end

-- Get nearest dyno to player with caching
function GetNearestDyno()
    return UseCache("nearestDyno", function()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local nearestDyno = nil
        local nearestIndex = nil
        local closestDistance = 10.0
        
        for dynoIndex, dynoConfig in pairs(Config.dynos) do
            local distance = GetDistanceBetweenCoords(playerCoords, dynoConfig.coords)
            
            if closestDistance > distance then
                closestDistance = distance
                nearestDyno = dynoConfig
                nearestIndex = dynoIndex
            end
        end
        
        return nearestDyno, nearestIndex, closestDistance
    end, 1000)
end

-- Check if vehicle is front-wheel drive
function IsVehicleFwd(vehicle)
    return UseCache("isFwd_" .. vehicle, function()
        local driveBias = GetVehicleHandlingFloat(vehicle, "CHandlingData", "fDriveBiasFront")
        return driveBias > 0.5
    end, 30000)
end

-- Debug print function
function Debug(...)
    if Config.debug then
        print(...)
    end
end

-- Draw marker for dyno interaction
function DrawDynoMarker(dyno)
    DrawMarker(43, dyno.coords + vector3(0.0, 0.0, -1.0), 0.0, 0.0, 0.0, 0.0, 0.0, dyno.heading, 2.5, 1.0, 0.5, 40, 110, 250, 30, 0, 0, 0, 0)
end

-- Display keybind tip on screen
function KeybindTip(message)
    SetTextComponentFormat("STRING")
    AddTextComponentString(message)
    EndTextCommandDisplayHelp(0, 0, 0, 200)
end

-- Check if player can perform dyno tests
function CanPerformDynoTests(dynoKey)
    return UseCache('CanPerformDynoTests' .. dynoKey, function()
        local dyno = Config.dynos[dynoKey]
        return (not Config.jobWhitelist.enabled or (not PLAYER_JOB or not dyno.jobs or Contains(dyno.jobs, PLAYER_JOB)))
    end, 5000)
end

-- Dyno event handlers
function OnDynoStart(dynoIndex)
    -- Called when dyno test starts
end

function OnDynoFinish(dynoIndex)
    -- Called when dyno test finishes
end