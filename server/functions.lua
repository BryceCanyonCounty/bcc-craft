VORPcore = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()
Discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar) -- Setup Discord webhook

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end

-- BCC Callback handler
BCCCallbacks = {}
BCCCallbacks.Registered = {}

-- Function to register a callback with a unique name
function BCCCallbacks.Register(name, callback)
    if BCCCallbacks.Registered[name] then
        devPrint("^1[ERROR] Callback with name '" .. name .. "' already exists!^0")
        return
    end

    BCCCallbacks.Registered[name] = callback
    devPrint("^2[INFO] BCC Callback '" .. name .. "' registered successfully.^0")
end

RegisterNetEvent('BCCCallbacks:Request')
AddEventHandler('BCCCallbacks:Request', function(name, requestId, ...)
    local src = source
    local callback = BCCCallbacks.Registered[name]
    local args = { ... }

    -- Check and log data to detect issues
    if args[1] then
        --print("[DEBUG] Server received data:", json.encode(args[1]))
    else
        --print("[ERROR] Server received empty or nil data.")
    end

    if callback then
        callback(src, function(response)
            TriggerClientEvent('BCCCallbacks:Response', src, requestId, response)
        end, table.unpack(args))
    else
        print("[ERROR] No callback registered with name:", name)
        TriggerClientEvent('BCCCallbacks:Response', src, requestId, nil)
    end
end)
