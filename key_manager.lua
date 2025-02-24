local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

local KeyManager = {}
KeyManager.WebhookURL = "https://discord.com/api/webhooks/1343686063662825635/VVv1euDJPBGHCCvI_-J34eQ9NdoeeR8X-GuRX0ki1OB6B6xJYPj-4xTLKuK3C-IOoLXF"

-- Store used keys with device IDs
local usedKeys = {}
local keyFilePath = "AfonsoScripts/used_keys.json"

-- Function to load used keys from file
function KeyManager.LoadUsedKeys()
    if isfile(keyFilePath) then
        local success, result = pcall(function()
            return HttpService:JSONDecode(readfile(keyFilePath))
        end)
        
        if success then
            usedKeys = result
            return true
        end
    end
    
    -- If file doesn't exist or can't be decoded, create a new one
    usedKeys = {}
    writefile(keyFilePath, HttpService:JSONEncode(usedKeys))
    return false
end

-- Function to save used keys to file
function KeyManager.SaveUsedKeys()
    writefile(keyFilePath, HttpService:JSONEncode(usedKeys))
end

-- Generate a unique device ID
function KeyManager.GetDeviceId()
    local hwid = game:GetService("RbxAnalyticsService"):GetClientId()
    local player = Players.LocalPlayer
    
    -- Combine hardware ID with account ID for better uniqueness
    local deviceId = hwid .. "_" .. player.UserId
    return deviceId
end

-- Check if a key is valid and unused for this device
function KeyManager.ValidateKey(key)
    -- Get device ID
    local deviceId = KeyManager.GetDeviceId()
    
    -- Check if key is in the accepted keys list
    local validKeys = {"premiumkey1"} -- This should match your main script
    local keyValid = false
    
    for _, validKey in ipairs(validKeys) do
        if key == validKey then
            keyValid = true
            break
        end
    end
    
    if not keyValid then
        return false, "Invalid key"
    end
    
    -- Check if key is already used on this device
    if usedKeys[key] and usedKeys[key][deviceId] then
        return false, "Key already used on this device"
    end
    
    return true, "Key valid"
end

-- Mark a key as used and send webhook
function KeyManager.UseKey(key)
    local deviceId = KeyManager.GetDeviceId()
    local player = Players.LocalPlayer
    
    -- Initialize key in used keys table if it doesn't exist
    if not usedKeys[key] then
        usedKeys[key] = {}
    end
    
    -- Mark key as used for this device
    usedKeys[key][deviceId] = {
        username = player.Name,
        userId = player.UserId,
        timestamp = os.time()
    }
    
    -- Save to file
    KeyManager.SaveUsedKeys()
    
    -- Send webhook notification
    KeyManager.SendWebhook(key, player)
    
    return true
end

-- Send webhook notification to Discord
function KeyManager.SendWebhook(key, player)
    local data = {
        content = nil,
        embeds = {
            {
                title = "Key Used - Afonso Scripts",
                description = "A key has been used in your script",
                color = 5814783, -- Blue color in decimal
                fields = {
                    {
                        name = "Key",
                        value = key,
                        inline = true
                    },
                    {
                        name = "Username",
                        value = player.Name,
                        inline = true
                    },
                    {
                        name = "User ID",
                        value = tostring(player.UserId),
                        inline = true
                    },
                    {
                        name = "Device ID",
                        value = KeyManager.GetDeviceId():sub(1, 20) .. "...", -- Truncated for readability
                        inline = false
                    }
                },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }
    
    local success, err = pcall(function()
        HttpService:PostAsync(KeyManager.WebhookURL, HttpService:JSONEncode(data), Enum.HttpContentType.ApplicationJson)
    end)
    
    return success
end

-- Initialize on load
KeyManager.LoadUsedKeys()

return KeyManager
