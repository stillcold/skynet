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
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		if code then
			if code ~= 200 then
				response(id, code)
			else
				local tmp = {}
				
				local bodyTbl = {}
				if body then
					local q = urllib.parse_query(body)
					for k, v in pairs(q) do
						print("set",k,v)
						k = trim(k)
						v = trim(v)
						bodyTbl[k] = v
					end
				end

				local beginIndex = tonumber(bodyTbl.page or 1 ) or 1 + 1

				table.insert(tmp, "-----body----<br/>" .. body)

				local bodyInfoStr = ""
				for k,v in pairs(bodyTbl) do
					bodyInfoStr = bodyInfoStr.."key "..k.. " value "..v.."\n"
				end
				
				response(id, code, table.concat(tmp,"\n")..bodyInfoStr)
			end
		else
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
	end)
end)

else

skynet.start(function()
	local agent = skynet.newservice(SERVICE_NAME, "agent")
	local balance = 1
	local id = socket.listen("0.0.0.0", 6001)
	skynet.error("Listen web port 6001")
	socket.start(id , function(id, addr)
		skynet.send(agent, "lua", id)
	end)
end)

end
