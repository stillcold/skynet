local json = require "json"

local function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1"))end

local function httpPost(url, data)
	local handle = io.popen("curl -s -X post -d '"..data.."' "..url)
	local ret = handle:read("*all")
	io.close()
	return ret
end

local function parseArg()
	local optiontbl = {}
	local flagTbl = {}
	local lastLlag = nil

	for k,v in ipairs(arg) do
		print(k,v)
		local _,flag = string.match(v, "([-]+)(%w+)")
		-- 匹配到了-
		if _ and flag then
			lastLlag = trim(flag)
			print("lastLlag",lastLlag)
		elseif lastLlag then
			flagTbl[lastLlag] = v
			print(v)
			lastLlag = nil
		else
			optiontbl[v] = true
		end

	end

	return optiontbl, flagTbl
end

local function doArg()
	local optiontbl, flagTbl = parseArg()
	local dataTbl = {}
	if optiontbl.get then
		local defaulTarget = "getAllTask"
		local target = flagTbl[target]
		if target then
			if target == "all" then
				dataTbl.cmd = "getAllTask"
			elseif target == "today" then
				dataTbl.cmd = "getTodayTask"
			elseif target == "vip" then
				dataTbl.cmd = "getMostImportantTask"
			else
				dataTbl.cmd = defaulTarget
			end
		else
			dataTbl.cmd = defaulTarget
		end
	elseif optiontbl.add then
		print("do add")
		dataTbl = flagTbl

		-- bodyTbl.title, bodyTbl.taskType,bodyTbl.content,bodyTbl.deadline,bodyTbl.priority
		flagTbl.title = flagTbl.title or "task"
		flagTbl.taskType = flagTbl.taskType or "todo"
		flagTbl.deadline = flagTbl.deadline or "week"
		flagTbl.priority = flagTbl.priority or "memo"

		if not flagTbl.content then
			print("no content detected")
			return
		end

		dataTbl.cmd = "addTask"

	end

	print(json.encode(dataTbl))
	local res = httpPost("120.24.98.130:6001", json.encode(dataTbl))
	print(res)
end


local function GetDateFromNumber(v)

	if v == "now" then
		return os.date("*t",os.time() )
	end

	if v == "hour" then
		return os.date("*t",os.time() + 3600)
	end

	if v == "today" or v == "day" then
		return os.date("*t",os.time() + 24*3600)
	end

	if v == "week" then
		return os.date("*t",os.time() + 7*24*3600)
	end

	if v == "month" then
		return os.date("*t",os.time() + 30*24*3600)
	end

	if v == "year" then
		return os.date("*t",os.time() + 365*24*3600)
	end


	local t = {}

	t.year,t.month,t.day,t.hour,t.min,t.sec = tostring(v):match("(....)(..)(..)[_]+(..):(..):(..)")
	for k,v in pairs(t) do t[k] = tonumber(v) end
	t.hour = t.hour or 0
	t.min = t.min or 0
	t.sec = t.sec or 0
	return t
end

local deadline = "day"
local deadlineTime = os.time(GetDateFromNumber(deadline))
print(deadlineTime)

if not deadlineTime then
	return
end

doArg()