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
        print("^1[ERROR] Callback with name '" .. name .. "' already exists!^0")
        return
    end

    BCCCallbacks.Registered[name] = callback
    print("^2[INFO] BCC Callback '" .. name .. "' registered successfully.^0")
end

-- Function to trigger a registered callback on the server
RegisterNetEvent('BCCCallbacks:Request')
AddEventHandler('BCCCallbacks:Request', function(name, requestId, ...)
    local src = source
    local callback = BCCCallbacks.Registered[name]

    if callback then
        -- Execute the callback and send the result back to the client
        callback(src, function(response)
            TriggerClientEvent('BCCCallbacks:Response', src, requestId, response)
        end, ...)
    else
        -- If the callback does not exist, log an error
        print("^1[ERROR] No callback found for '" .. name .. "'^0")
        TriggerClientEvent('BCCCallbacks:Response', src, requestId, nil) -- Return a null response
    end
end)
