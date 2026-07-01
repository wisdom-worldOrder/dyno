-- Build default URL for DUI
local defaultUrl = "https://cfx-nui-" .. GetCurrentResourceName() .. "/html/index.html"
DEFAULT_URL = defaultUrl

-- Create DUI object for dyno display
function CreateDuiObject(dynoIndex)
    -- Clean up any existing DUI first
    DestroyDynoDisplay(dynoIndex)
    
    Debug("Creating a new DuiObject", dynoIndex)
    
    -- Create texture dictionary name
    local txdDictName = "kq_dyno_dui_" .. dynoIndex .. "_dict"
    local txdDict = CreateRuntimeTxd(txdDictName)
    Debug(txdDictName)
    
    -- Create texture name
    local txdTextureName = "kq_dyno_dui_" .. dynoIndex .. "_txd"
    
    -- Create DUI with 1280x720 resolution
    local duiObject = CreateDui(DEFAULT_URL, 1280, 720)
    Debug("created duiObject", duiObject)
    
    -- Get DUI handle
    local duiHandle = GetDuiHandle(duiObject)
    Debug("created dui", duiHandle)
    
    -- Create runtime texture from DUI handle
    local runtimeTexture = CreateRuntimeTextureFromDuiHandle(txdDict, txdTextureName, duiHandle)
    Debug("created tx", runtimeTexture)
    
    -- Store DUI data in config
    local dynoConfig = Config.dynos[dynoIndex]
    dynoConfig.dui = {
        duiObject = duiObject,
        dui = duiHandle,
        txd = txdDict,
        txdName = txdDictName,
        tx = runtimeTexture,
        txName = txdTextureName
    }
end

-- Track vehicles with visual effects applied
local vehicleVisualEffects = {}

-- Main display rendering thread
Citizen.CreateThread(function()
    while true do
        local sleepTime = 2000
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        
        Debug("looping dyno display check")
        
        -- Check each dyno for display rendering
        for dynoIndex, dynoConfig in pairs(Config.dynos) do
            local distanceToDyno = GetDistanceBetweenCoords(playerCoords, dynoConfig.coords)
            
            if distanceToDyno < 40.0 then
                Debug("near a dyno")
                
                if sleepTime >= 500 then
                    sleepTime = 500
                end
                
                local nearestVehicle = GetNearestVehicle(dynoConfig.coords)
                Debug("dyno dui", dynoConfig.dui)
                
                -- Render displays if DUI exists
                if dynoConfig.dui then
                    sleepTime = 1
                    Debug("rendering displays")
                    
                    -- Render each display screen
                    for displayIndex, displayData in pairs(dynoConfig.displays) do
                        local displayType = Config.displayTypes[displayData.displayType]
                        
                        if displayData.display and displayData.display.object then
                            local displayCoords = GetOffsetFromEntityInWorldCoords(
                                displayData.display.object, 
                                displayType.offset
                            )
                            
                            Debug("draw image", displayCoords)
                            
                            local displayHeading = displayData.displayHeading + displayType.heading
                            local displayTilt = displayData.displayTilt or 0.0
                            
                            DrawImage(
                                displayCoords,
                                displayHeading,
                                displayType.size.x,
                                displayType.size.y,
                                displayTilt,
                                dynoConfig.dui.txdName,
                                dynoConfig.dui.txName,
                                255,
                                0.0
                            )
                        end
                    end
                    
                    -- Render on-screen display if enabled and player is driver
                    if Config.displaySheetOnScreen and nearestVehicle then
                        local isDriver = IsPedDriver(nearestVehicle)
                        
                        if isDriver then
                            Debug("can render sprite?", dynoConfig.dui)
                            
                            if dynoConfig.dui.txdName then
                                Debug("rendering sprite", dynoConfig.dui.txdName)
                                
                                local screenOffsetX = Config.screenSheetOffset.x or 0.84
                                local screenOffsetY = Config.screenSheetOffset.y or 0.833
                                
                                -- Draw background sprite
                                DrawSprite(
                                    "", "", 
                                    screenOffsetX, screenOffsetY,
                                    0.31, 0.316, 0.0,
                                    140, 40, 40, 170
                                )
                                
                                -- Draw DUI content
                                DrawSpriteUv(
                                    dynoConfig.dui.txdName,
                                    dynoConfig.dui.txName,
                                    screenOffsetX, screenOffsetY,
                                    0.3, 0.3, 0.0,
                                    0.0, 1.0, 1.0, 0,
                                    255, 255, 255, 255
                                )
                            end
                        end
                    end
                end
                
                -- Check if dyno should start running
                local isDynoRunning = dynoConfig.dui and dynoConfig.dui.duiObject and dynoConfig.running
                
                if not isDynoRunning and nearestVehicle then
                    local isVehicleRunningDyno = IsRunningDyno(nearestVehicle)
                    
                    if isVehicleRunningDyno then
                        -- Start dyno display
                        dynoConfig.running = true
                        CreateDuiObject(dynoIndex)
                        StartDynoData(nearestVehicle, dynoIndex)
                        
                        -- Monitor dyno completion
                        Citizen.CreateThread(function()
                            while true do
                                if not IsRunningDyno(nearestVehicle) then
                                    break
                                end
                                Citizen.Wait(300)
                            end
                            FinishDynoDisplay(dynoIndex)
                        end)
                    end
                end
                
                -- Handle vehicle visual effects
                if nearestVehicle then
                    local isVehicleRunningDyno = IsRunningDyno(nearestVehicle)
                    
                    if isVehicleRunningDyno then
                        SetRemoteCarVisuals(nearestVehicle)
                        vehicleVisualEffects[nearestVehicle] = true
                    else
                        if vehicleVisualEffects[nearestVehicle] then
                            ResetVehicleWheels(nearestVehicle)
                            vehicleVisualEffects[nearestVehicle] = false
                        end
                    end
                end
            else
                -- Player is far from dyno, clean up DUI
                if dynoConfig.dui and dynoConfig.dui.duiObject then
                    DestroyDui(dynoConfig.dui.duiObject)
                    dynoConfig.dui = nil
                end
            end
        end
        
        Citizen.Wait(sleepTime)
    end
end)

-- Finish dyno display with timeout
function FinishDynoDisplay(dynoIndex)
    Citizen.CreateThread(function()
        local dynoConfig = Config.dynos[dynoIndex]
        dynoConfig.running = false
        
        local originalDuiObject = dynoConfig.dui and dynoConfig.dui.duiObject or 0
        
        -- Wait for screen timeout
        local timeoutSeconds = Config.screenTimeout or 20
        Citizen.Wait(timeoutSeconds * 1000)
        
        -- Check if DUI object is still the same (hasn't been recreated)
        local currentDuiObject = dynoConfig.dui and dynoConfig.dui.duiObject or nil
        
        if originalDuiObject == currentDuiObject then
            DestroyDynoDisplay(dynoIndex)
        end
    end)
end

-- Destroy dyno display and clean up resources
function DestroyDynoDisplay(dynoIndex)
    local dynoConfig = Config.dynos[dynoIndex]
    
    if dynoConfig.dui and dynoConfig.dui.duiObject then
        DestroyDui(dynoConfig.dui.duiObject)
        dynoConfig.dui.duiObject = nil
    end
    
    dynoConfig.dui = nil
end

-- Draw image on display using sprite polygons
function DrawImage(coords, heading, width, height, tilt, txdName, txName, alpha, depth)
    local tiltRadians = math.rad(tilt)
    local tiltOffset = height * math.tan(tiltRadians)
    
    -- Draw first triangle
    DrawSpritePoly(
        GetOffsetWithHeading(coords, vector3(0.0, tiltOffset, height), heading),
        GetOffsetWithHeading(coords, vector3(width, tiltOffset, height), heading),
        GetOffsetWithHeading(coords, vector3(0.0, 0.0, 0.0), heading),
        255, 255, 255, alpha,
        txdName, txName,
        1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0
    )
    
    -- Draw second triangle
    DrawSpritePoly(
        GetOffsetWithHeading(coords, vector3(0.0, 0.0, 0.0), heading),
        GetOffsetWithHeading(coords, vector3(width, tiltOffset, height), heading),
        GetOffsetWithHeading(coords, vector3(width, 0.0, 0.0), heading),
        255, 255, 255, alpha,
        txdName, txName,
        1.0, 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0
    )
end

-- Set visual effects for remote vehicles during dyno test
function SetRemoteCarVisuals(vehicle)
    local horsepower, torque, realRpm, displayRpm = GetVehicleStateStats(vehicle)
    local isDriver = IsPedDriver(vehicle)
    
    if not isDriver then
        -- Update vehicle RPM for visual effects
        SetVehicleCurrentRpm(vehicle, displayRpm)
        
        -- Animate wheels if RPM is high enough
        if displayRpm > 0.2 then
            local wheelCount = GetVehicleNumberOfWheels(vehicle)
            for wheelIndex = 0, wheelCount - 1 do
                local isVehicleFwd = IsVehicleFwd(vehicle)
                
                if isVehicleFwd then
                    if wheelIndex <= 1 then
                        SetVehicleWheelRotationSpeed(vehicle, wheelIndex, -44.1 * displayRpm * 5000)
                    end
                else
                    if wheelIndex >= 2 then
                        SetVehicleWheelRotationSpeed(vehicle, wheelIndex, -44.1 * displayRpm * 5000)
                    end
                end
            end
        end
    end
end

-- Start dyno data synchronization for DUI updates
function StartDynoData(vehicle, dynoIndex)
    Citizen.CreateThread(function()
        Citizen.Wait(200)
        
        while true do
            if not IsRunningDyno(vehicle) then
                break
            end
            
            if not IsLoggingData(vehicle) then
                break
            end
            
            Citizen.Wait(150)
            
            local dynoConfig = Config.dynos[dynoIndex]
            
            if dynoConfig.dui then
                local horsepower, torque, displayRpm = GetVehicleStateStats(vehicle)
                
                local updateData = {
                    event = "update",
                    rpm = displayRpm,
                    hp = horsepower,
                    torque = torque,
                    title = WEBHOOK_TITLE,
                    peakHp = L("Peak HP"),
                    peakTorque = L("Peak torque"),
                    torqueUnit = GetTorqueUnit()
                }
                
                SendDuiMessage(dynoConfig.dui.duiObject, json.encode(updateData))
            end
        end
    end)
end
