local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local json = require "json"
local table = table
local string = string

local taskData = {}
local actionTbl = {}

local taskTypeTbl = {todo=1, doing=2, done=3}
local priorityTbl = {critical=1,high=2,normal=3,low=4,memo=5}

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

function actionTbl:addTask(bodyTbl)
	local title, taskType, content, deadLine, priority = bodyTbl.title, bodyTbl.taskType,bodyTbl.content,bodyTbl.deadLine,bodyTbl.priority
	if not title then
		return "invalidTitle"
	end
	if not taskType then
		return "invalidTaskType"
	end
	if not content then
		return "invalidContent"
	end
	if not deadLine then
		return "invalidDeadLine"
	end
	if not priority then
		return "invalidPriority"
	end
	
	local deadLine = os.date("%c", deadLine)
	if not deadLine then
		return "invalidFormatDeadLine,convert fail"
	end
	if not taskTypeTbl[taskType] then
		return "taskType not in defined table"
	end
	if not priorityTbl[priority] then
		return "priority not in defined table"
	end

	table.insert(taskData, {title = title, content = content, priority = priorityTbl[priority], deadLine = deadLine, taskType = taskTypeTbl[taskType]})
	return "addTask done"

end

function actionTbl:getAllTask()
	return json.encode(taskData)
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
					local q = json.decode(body)
					for k, v in pairs(q) do
						k = trim(k)
						v = trim(v)
						bodyTbl[k] = v
					end
				end

				table.insert(tmp, "-----body----<br/>" .. body)

				local bodyInfoStr = ""
				for k,v in pairs(bodyTbl) do
					bodyInfoStr = bodyInfoStr.."key "..k.. " value "..v.."\n"
				end
				
				--response(id, code, table.concat(tmp,"\n")..bodyInfoStr)

				local retRes = "none action taken"
				local cmd = bodyTbl.cmd
				if not cmd then
					response(id, code, retRes)
					return
				end
				local action = actionTbl[cmd]
				if not action then
					retRes = "no function found"
					response(id, code, retRes)
					return
				end

				retRes = action(actionTbl, bodyTbl)
				response(id, code, retRes)

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
