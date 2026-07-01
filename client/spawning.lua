-- Delete all existing dyno objects and displays
function DeleteOldDynos()
    -- Clean up all dyno models and their components
    for dynoIndex, dynoConfig in pairs(Config.dynos) do
        -- Delete all dyno model types
        for modelIndex, dynoModel in pairs(Config.dynoModels) do
            DeleteNearestOfType(dynoConfig.coords, dynoModel.base)
            
            -- Delete all roller objects
            for rollerIndex, roller in pairs(dynoModel.rollers) do
                DeleteNearestOfType(dynoConfig.coords, roller.prop)
            end
        end
        
        -- Delete all display objects
        for displayIndex, display in pairs(dynoConfig.displays) do
            for displayTypeIndex, displayType in pairs(Config.displayTypes) do
                DeleteNearestOfType(display.displayCoords, displayType.prop)
            end
        end
    end
end

-- Create all dyno objects and displays
function CreateDynos()
    Citizen.CreateThread(function()
        -- Wait before starting creation
        Citizen.Wait(1000)
        
        -- Clean up any existing objects first
        DeleteOldDynos()
        Citizen.Wait(1000)
        
        -- Create each dyno
        for dynoIndex, dynoConfig in pairs(Config.dynos) do
            if dynoConfig.model then
                local dynoModel = Config.dynoModels[dynoConfig.model]
                
                Citizen.Wait(20)
                
                -- Request and create base dyno object
                DoRequestModel(dynoModel.base)
                
                local baseCoords = dynoConfig.coords + vector3(0.0, 0.0, -1.05) + dynoModel.offset
                local dynoObject = CreateObject(dynoModel.base, baseCoords, false, 1, 0)
                
                SetEntityAsMissionEntity(dynoObject, 1, 1)
                SetObjectTextureVariation(dynoObject, dynoModel.textureVariation or 0)
                SetEntityHeading(dynoObject, dynoConfig.heading + dynoModel.heading)
                
                -- Store dyno object reference
                Config.dynos[dynoIndex].object = dynoObject
                Config.dynos[dynoIndex].rollers = {}
                
                FreezeEntityPosition(dynoObject, true)
                
                -- Create roller objects
                for rollerIndex, rollerConfig in pairs(dynoModel.rollers) do
                    local rollerCoords = GetOffsetFromEntityInWorldCoords(dynoObject, rollerConfig.offset)
                    
                    Citizen.Wait(20)
                    DoRequestModel(rollerConfig.prop)
                    
                    local rollerObject = CreateObject(rollerConfig.prop, rollerCoords, false, 1, 0)
                    
                    SetEntityAsMissionEntity(rollerObject, 1, 1)
                    
                    local baseRotation = GetEntityRotation(dynoObject)
                    SetEntityRotation(rollerObject, baseRotation + rollerConfig.rotation, 0)
                    
                    FreezeEntityPosition(rollerObject, true)
                    
                    -- Store roller data
                    Config.dynos[dynoIndex].rollers[rollerIndex] = {
                        direction = rollerConfig.direction,
                        side = rollerConfig.side,
                        object = rollerObject,
                        rotation = rollerConfig.rotation
                    }
                end
            end
            
            -- Create display objects
            for displayIndex, displayConfig in pairs(dynoConfig.displays) do
                local displayType = Config.displayTypes[displayConfig.displayType]
                
                DoRequestModel(displayType.prop)
                
                local displayCoords = displayConfig.displayCoords + vector3(0.0, 0.0, -1.0)
                local displayObject = CreateObject(displayType.prop, displayCoords, false, 1, 0)
                
                SetEntityAsMissionEntity(displayObject, 1, 1)
                SetEntityHeading(displayObject, displayConfig.displayHeading)
                
                -- Apply tilt if specified
                if displayConfig.displayTilt then
                    SetEntityRotation(displayObject, displayConfig.displayTilt, 0.0, displayConfig.displayHeading)
                end
                
                FreezeEntityPosition(displayObject, true)
                
                -- Store display object reference
                Config.dynos[dynoIndex].displays[displayIndex].display = {
                    object = displayObject
                }
            end
        end
    end)
end

-- Initialize dyno creation
CreateDynos()

-- Delete all objects of a specific type near coordinates
function DeleteNearestOfType(coords, modelHash)
    local foundObject = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, modelHash, 0, 0, 0)
    
    while foundObject ~= 0 do
        SetEntityAsMissionEntity(foundObject, 1, 1)
        DeleteEntity(foundObject)
        
        foundObject = GetClosestObjectOfType(coords.x, coords.y, coords.z, 10.0, modelHash, 0, 0, 0)
        Citizen.Wait(10)
    end
end

-- Register restart event
RegisterNetEvent("kq_dyno:client:prepareRestart")

-- Handle restart preparation
AddEventHandler("kq_dyno:client:prepareRestart", function(triggerPlayerId)
    print("Restarting kq_dyno. Triggered by: " .. triggerPlayerId, 
          "Deleting dynos. Script will be restarted automatically after all dynos are deleted.")
    
    DeleteOldDynos()
    
    local currentPlayerId = GetPlayerServerId(PlayerId())
    
    -- Only the triggering player restarts the resource
    if triggerPlayerId == currentPlayerId then
        Citizen.CreateThread(function()
            Citizen.Wait(5000)
            ExecuteCommand("ensure " .. GetCurrentResourceName())
        end)
    end
end)
