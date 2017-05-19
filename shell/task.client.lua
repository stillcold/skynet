--package.path = package.path .. ";c:/luaclass/?.lua"
-- ---------------------
-- config
-- ---------------------
local enumPlatForm = {
	Linux = 1,
	Windows = 2,
	Cygwin = 3,
	Mingw = 4,
	Maxosx = 5,
}

local PLATFORM = enumPlatForm.Windows
local CURRENTDIR = [[D:/mingw_offline_v/mingw/msys/1.0/home/Chao/skynet/shell/]]
-- ---------------------
-- config end
-- ---------------------

package.path = package.path .. ";"..CURRENTDIR.."?.lua"
local json = require "json"

local function trim(s) return (string.gsub(s, "^%s*(.-)%s*$", "%1"))end

local function httpPost(url, data, callback)
	local ret

	if PLATFORM == enumPlatForm.Cygwin or PLATFORM == enumPlatForm.Mingw then
		local orderStr = "curl -s -X post -d '"..data.."' "..url
		os.execute(orderStr)
		-- 这个函数返回的是状态码,根本拿不到真正的执行结果
		return
	elseif PLATFORM == enumPlatForm.Linux or PLATFORM == enumPlatForm.Macosx then
		--todo
		local handle = io.popen("curl -s -X post --data '"..data.."' "..url)
		ret = handle:read("*a")
	else
		local handle = io.popen("curl -s -X post --data "..data.." "..url)
		ret = handle:read("*a")
	end
	io.close()
	if callback then
		return callback(ret)
	end
	return ret
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
		elseif lastLlag then
			if flagTbl[lastLlag] then
				flagTbl[lastLlag] = flagTbl[lastLlag].." "..v
			else
				flagTbl[lastLlag] = v
			end
			
			--print("set",lastLlag,v)
			--lastLlag = nil
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
		local target = flagTbl.target or flagTbl.t
		if target then
			if target == "all" then
				dataTbl.cmd = "getAllTask"
				callback = function(ret)
					print("\nAll task is: \n")
					local allTaskTbl = json.decode(ret)
					for index,task in pairs(allTaskTbl) do
						local taskData = task
						if taskData then
							print("\t"..index..":")
							print("\t",taskData.title)
							print("\t",taskData.taskType.."\t"..taskData.priority.."\t"..taskData.rawDeadline)
							print("\t",taskData.content)
							
							print("\t","_____________________\n")
						end
					end
				end
			elseif target == "today" then
				dataTbl.cmd = "getTodayTask"

				callback = function(ret)
					print("\nTask in 24 hours is: \n")
					local allTaskTbl = json.decode(ret)
					for index,task in pairs(allTaskTbl) do
						local taskData = task
						if taskData then
							print("\t"..index..":")
							print("\t",taskData.taskType)
							print("\t",taskData.title)
							print("\t",taskData.content)
							print("\t",taskData.priority)
							print("\t",taskData.rawDeadline)
							print("\t","_____________________\n")
						end

					end
				end

			elseif target == "vip" then
				dataTbl.cmd = "getMostImportantTask"

				callback = function(ret)
					print("\nMost important task is: \n")
					local taskData = json.decode(ret)
					if taskData and taskData.title then
						print("\t",taskData.taskType)
						print("\t",taskData.title)
						print("\t",taskData.content)
						print("\t",taskData.priority)
						print("\t",taskData.rawDeadline)
						print("\t","_____________________\n")
					end
				end
			else
				dataTbl.cmd = defaulTarget
			end
		else
			dataTbl.cmd = defaulTarget
			callback = function(ret)
				print("\nAll task is: \n")
				local allTaskTbl = json.decode(ret)
				for index,task in pairs(allTaskTbl) do
					local taskData = task
					if taskData then

						print("\t"..index..":")

						if taskData.subTask and taskData.subTask[1] then
							print("\t",taskData.taskType.."..."..taskData.priority.."..."..taskData.rawDeadline)
							print("\t",taskData.title)

							print("\t",taskData.content.."\n")
							if taskData.subTask then
								for i,subTask in ipairs(taskData.subTask) do
									print("\t\t",i..":"..subTask.content.." "..subTask.status)
								end
							end
						else
							print("\t",taskData.taskType)
							print("\t",taskData.title)
							print("\t",taskData.content)
							print("\t",taskData.priority)
							print("\t",taskData.rawDeadline)
							
						end
						
						
						print("\t","_______________________________\n")
					end
					
				end
			end
		end
	elseif optiontbl.add then
		--print("do add")
		dataTbl = flagTbl

		-- bodyTbl.title, bodyTbl.taskType,bodyTbl.content,bodyTbl.deadline,bodyTbl.priority
		flagTbl.title = flagTbl.title or flagTbl.i or "task"
		flagTbl.taskType = flagTbl.taskType or flagTbl.t or "todo"
		flagTbl.deadline = flagTbl.deadline or flagTbl.d or "week"
		flagTbl.priority = flagTbl.priority or flagTbl.p or "memo"
		flagTbl.content = flagTbl.content or flagTbl.c

		flagTbl.hour = flagTbl.hour or flagTbl.h
		if flagTbl.hour then
			flagTbl.deadline = tostring(os.time() + tonumber(flagTbl.hour) * 3600)
		end

		flagTbl.second = flagTbl.second or flagTbl.s
		if flagTbl.second then
			flagTbl.deadline = tostring(os.time() + tonumber(flagTbl.second))
		end

		flagTbl.minute = flagTbl.minute or flagTbl.m
		if flagTbl.minute then
			flagTbl.deadline = tostring(os.time() + tonumber(flagTbl.minute) % 60)
		end

		if not flagTbl.content then
			print([[task add <--content (str)> 
	[--title (str)] 
	[--taskType (todo/doing/done)] 
	[--deadline (week/day/now/month/year/20170501/20170501_14:23:58)] 
	[--priority (critical/high/normal/low/memo)]  ]])
			return
		end

		dataTbl.cmd = "addTask"
	elseif optiontbl.done then
		dataTbl.cmd = "finishTask"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task done <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)
	elseif optiontbl.doing then
		dataTbl.cmd = "onTask"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task done <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)

	elseif optiontbl.delete then
		dataTbl.cmd = "deleteTask"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task done <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)

	elseif optiontbl.subadd then
		dataTbl.cmd = "addSubTask"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task addSub <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)
		dataTbl.content = flagTbl.content or flagTbl.c

	elseif optiontbl.subdelete or optiontbl.subdel then
		dataTbl.cmd = "deleteSubTask"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task addSub <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)
		dataTbl.subIndex = flagTbl.subIndex or flagTbl.s

	elseif optiontbl.subset then
		dataTbl.cmd = "setSubTaskStatus"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task addSub <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)
		dataTbl.subIndex = flagTbl.subIndex or flagTbl.s
		dataTbl.status = flagTbl.taskType or flagTbl.t or "done"
	elseif optiontbl.subdoing then
		dataTbl.cmd = "setSubTaskStatus"
		dataTbl.status = "doing"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task addSub <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)
		dataTbl.subIndex = flagTbl.subIndex or flagTbl.s
	
	elseif optiontbl.subdone then
		dataTbl.cmd = "setSubTaskStatus"
		dataTbl.status = "done"
		dataTbl.index = flagTbl.index or flagTbl.i
		if not dataTbl.index then
			print([[task addSub <--index (number)> ]])
			return
		end
		dataTbl.index = tostring(dataTbl.index)
		dataTbl.subIndex = flagTbl.subIndex or flagTbl.s

	end

	local toPostData = json.encode(dataTbl)
	if PLATFORM == enumPlatForm.Windows then
		toPostData = string.gsub(toPostData, '"', [[\"]])
		toPostData = string.gsub(toPostData, ' ', [[_]])
	end
	--print(toPostData)
	local res = httpPost("120.24.98.130:6001", toPostData, callback)

	if res then
		print(res)
	end

end

local function is_platform_windows()
    return "\\" == package.config:sub(1,1)
end
--local IS_WINDOWS = is_platform_windows()

doArg()