local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

local max_client = 64

skynet.start(function()
	skynet.error("Server start")
	skynet.uniqueservice("protoloader")
	if not skynet.getenv "daemon" then
		local console = skynet.newservice("console")
	end
	skynet.newservice("debug_console",8000)
	skynet.newservice("simpledb")
	skynet.newservice("simpleweb")
	skynet.newservice("task")
	skynet.newservice("transferentry")
	skynet.newservice("httptransfer")
	skynet.newservice("simplesocket")

	local watchdog = skynet.newservice("watchdog")

	-- 00000000: 调用 watchdog 服务,发送 start 消息和一堆配置
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	skynet.error("Watchdog listen on", 8888)
	skynet.exit()
end)
