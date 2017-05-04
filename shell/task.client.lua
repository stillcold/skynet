--package.path = package.path .. ";c:/luaclass/?.lua"
local json = require "json"

local function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1"))end

local function httpPost(url, data, callback)
	local handle = io.popen("curl -s -X post --data "..data.." "..url)
	local ret = handle:read("*a")
	io.close()
	if callback then
		return callback(ret)
	end
	return ret
end

local function is_platform_windows()
    return "\\" == package.config:sub(1,1)
end

local function parseArg()
	local optiontbl = {}
	local flagTbl = {}
	local lastLlag = nil

	for k,v in ipairs(arg) do
		--print(k,v)
		local _,flag = string.match(v, "([-]+)(%w+)")
		-- 匹配到了-
		if _ and flag then
			lastLlag = trim(flag)
			--print("lastLlag",lastLlag)
		elseif lastLlag then
			flagTbl[lastLlag] = v
			--print("set",lastLlag,v)
			lastLlag = nil
		else
			optiontbl[v] = true
		end

	end

	return optiontbl, flagTbl
end

local function doArg(isWindows)

	local optiontbl, flagTbl = parseArg()
	local dataTbl = {}
	local callback = nil
	if optiontbl.get then
		local defaulTarget = "getAllTask"
		local target = flagTbl.target
		if target then
			if target == "all" then
				dataTbl.cmd = "getAllTask"
				callback = function(ret)
					print("all task is ")
					local allTaskTbl = json.decode(ret)
					for index,task in pairs(allTaskTbl) do
						print(index,json.encode(task))
					end
				end
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
		--print("do add")
		dataTbl = flagTbl

		-- bodyTbl.title, bodyTbl.taskType,bodyTbl.content,bodyTbl.deadline,bodyTbl.priority
		flagTbl.title = flagTbl.title or "task"
		flagTbl.taskType = flagTbl.taskType or "todo"
		flagTbl.deadline = flagTbl.deadline or "week"
		flagTbl.priority = flagTbl.priority or "memo"

		if not flagTbl.content then
			print([[task add <--content (str)> 
	[--title (str)] 
	[--taskType (todo/doing/done)] 
	[--deadline (week/day/now/month/year/20170501/20170501_14:23:58)] 
	[--priority (critical/high/normal/low/memo)]  ]])
			return
		end

		dataTbl.cmd = "addTask"

	end

	local toPostData = json.encode(dataTbl)
	if isWindows then
		--print("is windows")
		toPostData = string.gsub(toPostData, '"', [[\"]])
	end
	--print(toPostData)
	local res = httpPost("120.24.98.130:6001", toPostData, callback)

	if res then
		print(res)
	end

end

local IS_WINDOWS = is_platform_windows()
doArg(IS_WINDOWS)