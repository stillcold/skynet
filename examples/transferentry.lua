local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string

local function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1"))end

local mode = ...

if mode == "agent" then

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

skynet.start(function()
	skynet.dispatch("lua", function (k,v,id)
		print("handle")
		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local content = ""
		while true do
			print("try read")
			content = content..socket.readall(id)
			print("content read from socket is", content)
		end
		
		
		print("done")
		socket.close(id)
	end)
end)

else

skynet.start(function()
	local agent = {}
	for i= 1, 20 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	local id = socket.listen("0.0.0.0", 8003)
	skynet.error("transferentry Listen port 8003")
	socket.start(id , function(id, addr)
		--skynet.error(string.format("connect id %s, %s connected, pass it to agent :%08x", id, addr, agent[balance]))
		skynet.send(agent[balance], "lua", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)
end)

end
