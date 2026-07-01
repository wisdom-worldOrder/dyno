-- Cache storage table
local cache = {}

-- Save data to cache with optional expiration time
function SaveCache(key, data, maxAge)
    local cacheEntry = {}
    cacheEntry.data = data
    
    local currentTime = GetGameTimer()
    local expirationTime = maxAge or 3000
    cacheEntry.maxAge = currentTime + expirationTime
    
    cache[key] = cacheEntry
end

-- Remove a specific cache entry
function WipeCache(key)
    cache[key] = nil
end

-- Retrieve cached data or execute callback to generate new data
function UseCache(key, callback, maxAge)
    local cacheEntry = cache[key]
    
    -- Check if cache entry exists and is still valid
    if cacheEntry then
        local currentTime = GetGameTimer()
        if cacheEntry.maxAge >= currentTime then
            -- Cache is valid, return cached data
            return table.unpack(cacheEntry.data)
        end
    end
    
    -- Cache miss or expired, execute callback to get new data
    local result = {callback()}
    
    -- Save the new data to cache
    SaveCache(key, result, maxAge)
    
    -- Return the new data
    return table.unpack(result)
end
