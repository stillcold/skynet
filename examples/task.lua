------------------------
-- todo list 管理模块
-- 	最核心的模块是获取下一个优先级最高的任务，因此需要一个可以精确量化的对任务按照优先级进行估值的约定。
--	为了防止不必要的麻烦，这个文件中的任务管理基于如下规则：
--	1、任务优先级有 taskType<"todo","doing","done">、priority<1-10> 、 deadline<dateTime>三个影响因子，优先级最终的结果以Value标志
--	2、三个因子的影响权重排序为:deadline>taskType>priority
--	3、deadline有6个区分度:过期，时，天，周，月，年，权重为100
--	4、taskType有3个区分度:todo,doing,done,权重为10
--	5、priority有5个区分度:critical,high,normal.low,memo。权重为1
--	6、优先级最终由以下公式计算得出:
--		value = V(deadline)*1000+V(taskType)*1000+V(priority)
--		其中:V(deadline)表示根据deadline计算出来的deadline的区分度估值.目前deadline有6个区分度的话，最大的值为5，最小的为1。taskType和priority以此类推
--
------------------------
local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local json = require "json"
local httpc = require "http.httpc"
local table = table
local string = string

local print = function ( ... )
	
end

local taskData = {}
local actionTbl = {}

local taskType2Value = {todo=2, doing=3, done=1}
local priority2Value = {critical=5,high=4,normal=3,low=2,memo=1}
local value2TaskType = {"done", "todo", "doing"}
local value2Priority = {"memo", "low", "normal", "high", "critical"}

local taskTypeWeight = 10000
local taskPriorityWeight =1
local deadlineWeight = 100

local loadDataTick
local hasLoaded
local maxId

local function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1"))end

local function copytbl(ori)
	if not ori then
		return nil
	end

	if type(ori) ~= "table" then
		return ori
	end

	local copy = {}
	for k,v in pairs(ori) do
		copy[k] = copytbl(v)
	end
	return copy
end

-- 20170501_13:46:59
local function GetDateFromNumber(v)

	local t = {}

	local rawDeadline
	local isSpecialStr = false
	if v == "now" then
		t = os.date("*t",os.time() )
		isSpecialStr = true
	end

	if v == "hour" then
		t = os.date("*t",os.time() + 3600)
		isSpecialStr = true
	end

	if v == "today" or v == "day" then
		t = os.date("*t",os.time() + 24*3600)
		isSpecialStr = true
	end

	if v == "week" then
		t = os.date("*t",os.time() + 7*24*3600)
		isSpecialStr = true
	end

	if v == "month" then
		t = os.date("*t",os.time() + 30*24*3600)
		isSpecialStr = true
	end

	if v == "year" then
		t = os.date("*t",os.time() + 365*24*3600)
		isSpecialStr = true
	end

	local v_number = tonumber(v)
	if v_number and v_number > 0 then
		t = os.date("*t",v_number)
		isSpecialStr = true
	end

	if isSpecialStr then
		rawDeadline = ""..t.year.."-"..t.month.."-"..t.day.."_"..t.hour.."-"..t.min.."-"..t.sec
		return t,rawDeadline
	end

	t.year,t.month,t.day,t.hour,t.min,t.sec = tostring(v):match("(....)(..)(..)[_]+(..)-(..)-(..)")
	for k,v in pairs(t) do t[k] = tonumber(v) end
	t.hour = t.hour or 0
	t.min = t.min or 0
	t.sec = t.sec or 0
	return t
end

local function loadAllTaskFronDB()
	if hasLoaded then
		return
	end
	local bodyTbl = {}
	bodyTbl.cmd = "select"
	local recvheader = {}
	local status, body = httpc.postJson("120.24.98.130", "/db.php", bodyTbl, recvheader)

	hasLoaded = true

	if not body then
		return
	end

	local alldata = json.decode(body)
	if not alldata then
		return
	end

	for _,data in pairs(alldata) do

		local id = data.id
		id = tonumber(id)

		print(id)
		if not maxId or maxId < tonumber(id) then
			maxId = tonumber(id)
		end

		print(data.data)

		local taskDataT = json.decode(data.data)

		local title = taskDataT.title
		print(title)
		local content = taskDataT.content
		print(content)
		local deadline = taskDataT.deadline
		print(deadline)
		local taskType = taskDataT.taskType
		taskType = taskType2Value[taskType] or tonumber(taskType) or 2
		print(taskType)
		local priority = taskDataT.priority
		priority = priority2Value[priority] or tonumber(priority) or 3
		print(priority)
		local timeTbl,newRawStr = GetDateFromNumber(deadline)
		local deadlineTime = os.time(timeTbl)

		local task = {id = id, title = title, content = content, priority = priority, deadline = deadlineTime, taskType = taskType, rawDeadline = newRawStr or deadline}

		table.insert(taskData, task)
		print(taskData)
		for k,v in pairs(taskData) do
			print(k,v)
		end
	end
	
	--table.insert(taskData, {title = title, content = content, priority = priority2Value[priority], deadline = deadlineTime, taskType = taskType2Value[taskType], rawDeadline = newRawStr or deadline})
end

local function updateTask(id, data)
	local bodyTbl = {}
	bodyTbl.cmd = "update"
	bodyTbl.id = id
	bodyTbl.data = copytbl (data)
	bodyTbl.data.rawDeadline = nil

	bodyTbl.Deleted = 0
	local recvheader = {}
	local status, body = httpc.postJson("120.24.98.130", "/db.php", bodyTbl, recvheader)
	print(status, body)
end

local function OnTaskUpdate(index)
	local task = taskData[index]
	updateTask(task.id, task)
end


local function insertTask(id, data)
	local bodyTbl = {}
	bodyTbl.cmd = "insert"
	bodyTbl.id = id
	
	bodyTbl.data = copytbl (data)
	bodyTbl.data.rawDeadline = nil

	bodyTbl.Deleted = 0
	local recvheader = {}
	local status, body = httpc.postJson("120.24.98.130", "/db.php", bodyTbl, recvheader)
	print(status, body)
end


local function markTaskAsDelete(id, data)
	local bodyTbl = {}
	bodyTbl.cmd = "update"
	bodyTbl.id = id

	bodyTbl.data = copytbl (data)
	bodyTbl.data.rawDeadline = nil
	bodyTbl.Deleted = 1
	local recvheader = {}
	local status, body = httpc.postJson("120.24.98.130", "/db.php", bodyTbl, recvheader)
	print(status, body)
end


local mode = ...

if mode == "agent" then

local function response(id, ...)
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local function _GetTaskTypeValue(taskType)
	if not taskType then
		return 0
	end

	return (taskType or 0) * taskTypeWeight
end

local function _GetTaskPriorityValue(priority)
	if not priority then
		return 0
	end

	return (priority or 0) * taskPriorityWeight
end

local function _GetTaskDeadlineValue(deadline)
	if not deadline then
		return 0
	end
	local nowTime = os.time()
	local timeOffset = deadline - nowTime

	if timeOffset < 0 then
		return 19 * deadlineWeight
	end
	if timeOffset == 0 then
		return 15 * deadlineWeight
	end
	if timeOffset < 60 then
		return 14 * deadlineWeight
	end
	if timeOffset < 300 then
		return 13 * deadlineWeight
	end
	if timeOffset < 600 then
		return 13 * deadlineWeight
	end
	if timeOffset < 0.5 * 3600 then
		return 12 * deadlineWeight
	end
	if timeOffset < 1 * 3600 then
		return 11 * deadlineWeight
	end
	if timeOffset < 2 * 3600 then
		return 10 * deadlineWeight
	end
	if timeOffset < 3 * 3600 then
		return 9 * deadlineWeight
	end
	if timeOffset < 4 * 3600 then
		return 8 * deadlineWeight
	end
	if timeOffset < 5 * 3600 then
		return 7 * deadlineWeight
	end
	if timeOffset < 6 * 3600 then
		return 6 * deadlineWeight
	end
	if timeOffset < 24 * 3600 then
		return 5 * deadlineWeight
	end
	if timeOffset < 24 * 3600 * 7 then
		return 4 * deadlineWeight
	end
	if timeOffset < 24 * 3600 * 30 then
		return 3 * deadlineWeight
	end
	if timeOffset < 24 * 3600 * 365 then
		return 2 * deadlineWeight
	end

	return 1 * deadlineWeight

end

-- 获得当前任务的优先级估值
local function GetTaskValue(taskIndex)
	local currentTask = taskData[taskIndex]
	if not currentTask then
		return 0
	end

	return _GetTaskDeadlineValue(currentTask.deadline) + _GetTaskTypeValue(currentTask.taskType) + _GetTaskPriorityValue(currentTask.priority)

end


-- API: 获取当前优先级最高的任务
function actionTbl:getMostImportantTask()
	for index,task in pairs(taskData) do
		task.value = GetTaskValue(index)
	end

	table.sort(taskData, function(first, second) return first.value > second.value end)

	local data = copytbl(taskData[1])
	data.index = 1
	data.priority = value2Priority[data.priority] or data.priority
	data.taskType = value2TaskType[data.taskType] or data.taskType

	if data.subTask then
		for _,subtask in ipairs(data.subTask) do
			subtask.status = value2TaskType[subtask.status] or subtask.status
		end
	end

	return json.encode(data or {})
end

-- API: 增加一个任务
function actionTbl:addTask(bodyTbl)
	local title, taskType, content, deadline, priority = bodyTbl.title, bodyTbl.taskType,bodyTbl.content,bodyTbl.deadline,bodyTbl.priority
	if not title then
		return "invalidTitle"
	end
	if not taskType then
		return "invalidTaskType"
	end
	if not content then
		return "invalidContent"
	end
	if not deadline then
		return "invalidDeadline"
	end
	if not priority then
		return "invalidPriority"
	end
	
	local timeTbl,newRawStr = GetDateFromNumber(deadline)
	local deadlineTime = os.time(timeTbl)
	if not deadlineTime then
		return "invalidFormatDeadline,convert fail"
	end
	if not taskType2Value[taskType] then
		return "taskType not in defined table"
	end
	if not priority2Value[priority] then
		return "priority not in defined table"
	end

	local id = (maxId or 0) + 1
	local task = {id = id, title = title, content = content, priority = priority2Value[priority], deadline = deadlineTime, taskType = taskType2Value[taskType], rawDeadline = newRawStr or deadline}
	table.insert(taskData, task)
	insertTask(id, task)
	return "addTask done"

end

-- API : 获取今天的所有任务
function actionTbl:getTodayTask()
	local retTbl = {}
	local nowTime = os.time()
	for index,task in pairs(taskData) do
		if task.deadline - nowTime <= 24 * 3600 then
			local data = copytbl(task)
			data.index = index
			data.priority = value2Priority[data.priority] or data.priority
			data.taskType = value2TaskType[data.taskType] or data.taskType

			if data.subTask then
				for _,subtask in ipairs(data.subTask) do
					subtask.status = value2TaskType[subtask.status] or subtask.status
				end
			end

			table.insert(retTbl, data)
		end
	end
	return json.encode(retTbl)
end

-- API: 获取所有的任务
function actionTbl:getAllTask()
	print(taskData)
	for k,v in pairs(taskData) do
		print(k,v)
	end
	loadAllTaskFronDB()
	local data = copytbl(taskData)
	for index,task in pairs(data) do
		task.priority = value2Priority[task.priority] or task.priority
		task.taskType = value2TaskType[task.taskType] or task.taskType
		task.index = index
		task.deadline = nil
		task.value = nil
		if task.subTask then
			for _,subtask in ipairs(task.subTask) do
				subtask.status = value2TaskType[subtask.status] or subtask.status
			end
		end
	end
	return json.encode(data)
end

-- API: 标记任务为完成状态
function actionTbl:finishTask(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end

	local task = taskData[index]
	if not task then
		return "no task found"
	end

	task.taskType = taskType2Value.done
	OnTaskUpdate(index)

	return "set done"
end

-- API: 标记任务为doing状态
function actionTbl:onTask(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end

	local task = taskData[index]
	if not task then
		return "no task found"
	end

	task.taskType = taskType2Value.doing
	OnTaskUpdate(index)
	return "set done"
end

-- API: 标记任务为todo状态
function actionTbl:resetTaskType(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end

	local task = taskData[index]
	if not task then
		return "no task found"
	end

	task.taskType = taskType2Value.todo
	OnTaskUpdate(index)
	return "set done"
end

-- API: 设置任务优先级
function actionTbl:setTaskPriority(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end

	local task = taskData[index]
	if not task then
		return "no task found"
	end

	local priority = bodyTbl.priority
	if not priority2Value[priority] then
		return "priority not in defined table"
	end

	task.priority = priority2Value[priority]
	OnTaskUpdate(index)
	return "set done"
end

-- API: 取消任务
function actionTbl:deleteTask(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end
	local task = taskData[index]
	if not task then
		return "no task found"
	end

	table.remove(taskData,index)

	markTaskAsDelete(task.id, task)

	return "delete done"
end

-- API: 添加子任务
-- todo DB
function actionTbl:addSubTask(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end
	local task = taskData[index]
	if not task then
		return "no task found"
	end

	local content = bodyTbl.content
	if not content then
		return "no sub task"
	end

	bodyTbl.status = bodyTbl.status and string.lower(bodyTbl.status)
	local status = bodyTbl.status and taskType2Value[bodyTbl.status] or taskType2Value.todo

	task.subTask = task.subTask or {}
	table.insert(task.subTask, {content = content, status = status})

	return "add done"
end

-- API: 删除子任务
-- todo DB
function actionTbl:deleteSubTask(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end
	local task = taskData[index]
	if not task then
		return "no task found"
	end

	local subIndex = bodyTbl.subIndex
	if not subIndex then
		return "no subIndex"
	end

	subIndex = tonumber(subIndex)
	local subTask = task.subTask[subIndex]
	if not subTask then
		return "no subtask found"
	end

	table.remove(task.subTask, subIndex)

	return "delete done"
end


-- API: 设置子任务状态
-- todo DB
function actionTbl:setSubTaskStatus(bodyTbl)
	local index = bodyTbl.index
	index = tonumber(index)
	if not index then
		return "invalid index"
	end
	local task = taskData[index]
	if not task then
		return "no task found"
	end

	local subIndex = bodyTbl.subIndex
	if not subIndex then
		return "no subIndex"
	end

	subIndex = tonumber(subIndex)
	local subTask = task.subTask[subIndex]
	if not subTask then
		return "no subtask found"
	end

	bodyTbl.status = bodyTbl.status and string.lower(bodyTbl.status)
	local status = bodyTbl.status and taskType2Value[bodyTbl.status]
	if not status then
		return "no subtask status"
	end

	subTask.status = status

	return "set done"
end


-- API: 设置子任务状态
function actionTbl:testHttp(bodyTbl)
	local recvheader = {}
	local status, body = httpc.postJson("120.24.98.130", "/db.php", bodyTbl, recvheader)

	print(status, body)
	return body
end

--loadDataTick = skynet.timeout(300, loadAllTaskFronDB)

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
	--skynet.timeout(300, function() loadAllTaskFronDB() end)

	local id = socket.listen("0.0.0.0", 6001)
	skynet.error("Listen web port 6001")
	socket.start(id , function(id, addr)
		skynet.send(agent, "lua", id)
	end)
end)

end
