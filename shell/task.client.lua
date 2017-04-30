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
		local _,flag = string.match(v, "(--)(%w)")
		-- 匹配到了-
		if _ and flag then
			lastLlag = trim(flag)
		end

		if lastLlag then
			flagTbl[lastLlag] = trim(v)
			print(v)
			lastLlag = nil
		end

		optiontbl[v] = true

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
				elseif target == "getMostImportantTask"
			else
				dataTbl.cmd = defaulTarget
			end
		else
			dataTbl.cmd = defaulTarget
		end
	elseif optiontbl.add then
		dataTbl = flagTbl

		-- bodyTbl.title, bodyTbl.taskType,bodyTbl.content,bodyTbl.deadline,bodyTbl.priority
		flagTbl.title = flagTbl.title or "task"
		flagTbl.taskType = flagTbl.taskType or "todo"
		flagTbl.deadline = flagTbl.deadline or "20170501"
		flagTbl.priority = flagTbl.priority or "memo"

		if not flagTbl then
			print("no content detected")
			return
		end

		dataTbl.cmd = "addTask"

	end

	local res = httpPost("120.24.98.130:6001", json.encode(dataTbl))
	print(json.encode(dataTbl), res)
end

doArg()