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

function NotifyClient(src, message, duration, notifyType)
	duration = duration or ((Config.NotifyOptions and Config.NotifyOptions.autoClose) or 4000)
	notifyType = notifyType or ((Config.NotifyOptions and Config.NotifyOptions.type) or "info")

	if Config.Notify == "feather-menu" then
		BccUtils.RPC:Notify("bcc-crafting:NotifyClient", {
			message = message,
			type = notifyType,
			duration = duration
		}, src)
	elseif Config.Notify == "vorp-core" then
		VORPcore.NotifyRightTip(src, message, duration)
	else
		print("^1[Notify] Invalid Config.Notify: " .. tostring(Config.Notify))
	end
end

if Config.useBccUserlog then
    UserLogAPI = exports['bcc-userlog']:getUserLogAPI()
end
