local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
require "skynet.manager"    -- import skynet.register

local table = table
local string = string
local localHmtlVarTbl = {}
localHmtlVarTbl.curIndex = 1
local htmlHeader
local htmlBottom
local cachedClientFd = nil
local requestInProgress = false

local isRlease = true

local function getDefaultHtml()
    if isRlease then
        return [==[<a href="http://120.24.98.130:8001?cmd=goodAdjust" style=" color:#666; font-size:80px;">Good</a>
<a href="http://120.24.98.130:8001?cmd=badAdjust" style=" color:#666; font-size:80px;">Bad</a>
<br>
<img src= "http://120.24.98.130:8001?cmd=getPic" width="980" >
]==]

    end

    return [==[<a href="http://192.168.0.107:8001?cmd=goodAdjust" style=" color:#666; font-size:80px;">Good</a>
<a href="http://192.168.0.107:8001?cmd=badAdjust" style=" color:#666; font-size:80px;">Bad</a>
<br>
<img src= "http://192.168.0.107:8001?cmd=getPic" width="980" >
]==]

end

local function setHtmlShell()
	local f = assert(io.open([==[examples/html_header.html]==],'r'))
	local content = f:read("*all")
	htmlHeader = content
	
	f = assert(io.open([==[examples/html_bottom.html]==],'r'))
	local content = f:read("*all")
	htmlBottom = content
end


setHtmlShell()

local mainContent = {}

local function reamAllContent()
	local f = assert(io.open([==[examples/resource/content.data]==],'r'))
	for line in f:lines() do
		table.insert(mainContent, line)
	end
end
reamAllContent()


local function getLocalVar(varName)
	print("getLocalVar")
	print(varName)
	print(localHmtlVarTbl[varName])
	return localHmtlVarTbl[varName] or ""
end

local function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1"))end

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local mode = ...

if mode == "agent" then



skynet.start(function()
	skynet.dispatch("lua", function (_,_,id,more)

		if id == "ANSWER" then

			print("more is ",more)
			if cachedClientFd then
            	response(cachedClientFd, 200, "OK")
            	cachedClientFd = nil
            else
            	print("nil cachedClientFd 2")
            end

            return
		end

		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		if code then
			if code ~= 200 then
				response(id, code)
			else

				print(url)
				local tmp = {}
				if header.host then
					table.insert(tmp, string.format("host: %s", header.host))
				end
				local path, query = urllib.parse(url)
				table.insert(tmp, string.format("path: %s", path))

				local queryTbl = {}
				if query then
					queryTbl = urllib.parse_query(query)
					for k, v in pairs(queryTbl) do
						table.insert(tmp, string.format("query: %s= %s", k,v))
					end
				end
				--table.insert(tmp, "-----header----")


				if queryTbl.cmd == "getPic" then
					print("request pic")
					local innerClientMsg = getDefaultHtml()


					if not requestInProgress then
						requestInProgress = true
						innerClientMsg = skynet.call("SIMPLESOCKET", "lua", "getPicFromResClient")
						requestInProgress = false
					end

					if innerClientMsg == "no connecttion found" then
						response(id, code, innerClientMsg or "empty", resheader)
					end

					local resheader = {}
					resheader["content-type"] = "image/png"
					response(id, code, innerClientMsg or "empty", resheader)

				end

				if queryTbl.cmd == "goodAdjust" then
					print("adjust")

					local innerClientMsg = getDefaultHtml()

					response(id, code, innerClientMsg or "empty")

					skynet.send("SIMPLESOCKET", "lua", "goodAdjust")

				end

				if queryTbl.cmd == "badAdjust" then
					print("adjust")
					local innerClientMsg = getDefaultHtml()

					response(id, code, innerClientMsg or "empty")

					skynet.send("SIMPLESOCKET", "lua", "badAdjust")

				end

				
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
	local agent = {}
	for i= 1, 20 do
		agent[i] = skynet.newservice(SERVICE_NAME, "agent")
	end
	local balance = 1
	local id = socket.listen("0.0.0.0", 8001)
	skynet.error("Listen web port 8001")
	socket.start(id , function(id, addr)
		skynet.error(string.format("%s connected, pass it to agent :%08x", addr, agent[balance]))
		skynet.send(agent[balance], "lua", id)
		balance = balance + 1
		if balance > #agent then
			balance = 1
		end
	end)

	skynet.dispatch("lua", function(session, address, cmd, ...)

		print("SIMPLEWEB debug ", cmd)
        if string.sub(cmd, 1, 6) == "ANSWER" then
        	print("SIMPLEWEB recieve ANSWER ")

        	local target = tonumber(string.sub(cmd, 7) )

        	-- skynet.send(agent[balance], "lua", cmd, ...)
        	response(target, 200, "what")
        	
        end
    end)

	skynet.register "SIMPLEWEB"
end)

end
