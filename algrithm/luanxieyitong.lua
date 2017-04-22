--[[
环境变量
--]]
math.randomseed(tostring(os.time()):reverse():sub(1, 6))

local random = math.random
local ceil = math.ceil

--[[
问题中的输入
--]]
local g_countOfRepo = 1 			-- 配送中心的数量
local g_countOfCar = 3 				-- 配送车辆的数量
local g_countOfClient = 11 			-- 配送客户的数量
local g_maxDistancePerPath = 20000 	-- 每辆车的单次配送最大距离
local g_maxClientCountPerPath = 6 	-- 每辆车的单次配送最多客户数量
local g_repoIndex = 0 				-- 仓库的编号
local g_carSpeed = 30 				-- 车速
local g_cancleIndex = 6 			-- 退货编号

local g_distanceTbl = {}			-- 配送点之间的距离
-- lua 里面的下标自动从1开始，所以全部偏移1，1代表0号仓库（配送中心），2代表1号，以此类推
g_distanceTbl[1] = {0,2370,1700,1820,1850,2710,971,1010,764,547,1050,2420}
g_distanceTbl[2] = {2370,0,3700,4210,4120,797,1340,2000,2750,2860,4090,4570}
g_distanceTbl[3] = {1700,3700,0,1260,684,3730,2410,1760,978,1780,2610,2500}
g_distanceTbl[4] = {1820,4210,1260,0,447,4350,2770,2390,1390,1580,1770,1500}
g_distanceTbl[5] = {1850,4120,684,447,0,4270,2740,2260,1270,1730,2220,2010}
g_distanceTbl[6] = {2710,797,3730,4350,4270,0,1800,1960,2970,3190,4620,5040}
g_distanceTbl[7] = {971,1340,2410,2770,2740,1800,0,841,1460,1450,2900,3280}
g_distanceTbl[8] = {1010,2000,1760,2390,2260,1960,841,0,991,1570,3050,3380}
g_distanceTbl[9] = {764,2750,978,1390,1270,2970,1460,991,0,843,2140,2360}
g_distanceTbl[10] = {547,2860,1780,1580,1730,3190,1450,1570,843,0,1820,1440}
g_distanceTbl[11] = {1050,4090,2610,1770,2220,4620,2900,3050,2140,1820,0,618}
g_distanceTbl[12] = {2420,4570,2500,1500,2010,5040,3280,3380,2360,1440,618,0}

-- 配送点的价格
local g_clientPrice = {46.7, 66.3, 88.2, 44.2, 86.6, 76.7, 63.2, 64.3, 82.4, 47.2, 48.8} 

-- 所有的时间以15点为基准，以分钟为单位
local g_clientBeginTime = {1,3,8,11,12,14,15,17,22,23,28}
local g_clientEndTime = {121,123,128,90,132,134,133,137,142,143,148}

--[[
常量
--]]
--local g_RUNTIME = 60*1 -- 1min


local GA = {}
GA.m_sampleCount = 100 				-- 样本数量
GA.m_beginCalTime = nil
GA.m_solutionTbl = {}
GA.m_solution = nil
GA.m_compareSequence = nil
GA.m_selected = nil
GA.m_outed = nil
GA.m_bestEval = nil
GA.m_currentGeneration = 0 			-- 当前迭代次数
GA.m_maxGeneration = 100  			-- 终止条件（迭代到100代的时候终止）

function GA:Init()
	self.m_compareSequence = {}
	for i=1,self.m_sampleCount do
		table.insert(self.m_compareSequence, i)
	end
	for i,v in ipairs(g_clientBeginTime) do
		g_clientBeginTime[i] = v *60
	end
	for i,v in ipairs(g_clientEndTime) do
		g_clientEndTime[i] = v *60
	end
end

function GA:_RandomSelectSeqeuence()
	local randomTimes = random(ceil(self.m_sampleCount/10))
	for i=1,randomTimes do
		local target = random(self.m_sampleCount)
		self.m_compareSequence[i] = self.m_compareSequence[i] + self.m_compareSequence[target]
		self.m_compareSequence[target] = self.m_compareSequence[i] - self.m_compareSequence[target]
		self.m_compareSequence[i] = self.m_compareSequence[i] - self.m_compareSequence[target]
	end
end

-- 获取两个仓库之间的距离,0表示配送中心
function GA:_GetDistance(clientIndex1, clientIndex2)
	local indexInData1 = clientIndex1 + 1
	local indexInData2 = clientIndex2 + 1
	return g_distanceTbl[indexInData1][indexInData2]
end


function GA:_GetCostTime(distance)
	return ((distance/1000)/g_carSpeed)*3600
end

function GA:_GetTimePunish(lateTime, price)
	local cost = 0
	cost = cost + 5
	cost = cost + 2 * (price / 10 ) * (lateTime / 3600)
	return cost
end

function GA:_GetTimeLostValue(costTime, price)
	return 1 * (price / 10) * (costTime / 3600)
end

-- 判断当前路径是否能否加入到当前车的路径中
-- 考虑几个限制
-- 第一个限制是车的单子不超过6个（退货其实是一样,也是按照客户个数来计算）
-- 第二个限制是车的距离不能超过20KM
function GA:_CanInsert(carIndex, clientIndex, pathInfo)
	--print(carIndex, clientIndex, pathInfo)
	if pathInfo[carIndex].clientCount + 1 > g_maxDistancePerPath then
		--print("too many client")
		return false
	end
	local lastClient = pathInfo[carIndex].lastClient
	local currentDistance = pathInfo[carIndex].distance

	--print("lastClient", lastClient)
	--print("clientIndex", clientIndex)
	--print("g_repoIndex", g_repoIndex)
	--print("first distance", self:_GetDistance(lastClient, clientIndex))
	--print("second distance", self:_GetDistance(clientIndex,g_repoIndex))
	if currentDistance + self:_GetDistance(lastClient, clientIndex) + self:_GetDistance(clientIndex,g_repoIndex) > g_maxDistancePerPath then
		--print("_CanInsert",currentDistance, self:_GetDistance(lastClient, clientIndex), self:_GetDistance(clientIndex,g_repoIndex), g_maxDistancePerPath)
		return false
	end

	return true
end

function GA:_RawCanInsert(path, carIndex, toCheckClientIndex)
	if #path[carIndex] + 1 > g_maxClientCountPerPath then
		--print("too much client", #path[carIndex] + 1 )
		return false
	end
	local lastClient = g_repoIndex
	local totalDistance = 0
	for _,clientIndex in ipairs(path[carIndex]) do
		totalDistance = totalDistance + self:_GetDistance(lastClient, clientIndex)
		lastClient = clientIndex
	end
	totalDistance = totalDistance + self:_GetDistance(lastClient, toCheckClientIndex)
	totalDistance = totalDistance + self:_GetDistance(toCheckClientIndex, g_repoIndex)
	if totalDistance > g_maxDistancePerPath then
		--print("in valid dsitance ", totalDistance)
		return false
	end
	return true
end

-- 把当前客户加入当前车的路径中
function GA:_AddClientToPath(pathOfEachCar, carIndex, clientIndex, pathInfo)
	--print("_AddClientToPath", pathOfEachCar, carIndex, clientIndex)
	table.insert(pathOfEachCar[carIndex], clientIndex)
	pathInfo[carIndex].distance = self:_GetDistance(pathInfo[carIndex].lastClient, clientIndex) + pathInfo[carIndex].distance
	pathInfo[carIndex].lastClient = clientIndex
	pathInfo[carIndex].clientCount = pathInfo[carIndex].clientCount + 1
end

function GA:_GetRandomClientInLeftClient(leftClient)
	local count = #leftClient
	if count <= 0 then
		--print("invalid _GetRandomClientInLeftClient")
		return
	end

	local randomPick = random(count)
	local ret = leftClient[randomPick]
	table.remove(leftClient, randomPick)
	return ret
end

-- 随机产生一个可行的路径
function GA:_GenerateRandomSolution()
	local pathOfEachCar = {}
	local pathInfo = {}
	local leftClient = {1,2,3,4,5,6,7,8,9,10,11}
	for i=1,g_countOfCar do
		pathOfEachCar[i] = {}
		pathInfo[i] = {}
		pathInfo[i].lastClient = 0
		pathInfo[i].clientCount = 0
		pathInfo[i].distance = 0
	end
	for i=1,g_countOfClient do
		local randomCar = random(g_countOfCar)
		local randomClient = self:_GetRandomClientInLeftClient(leftClient)
		while( not self:_CanInsert(randomCar, randomClient, pathInfo)) do
			randomCar = randomCar + 1
			if randomCar > g_countOfCar then
				randomCar = 1
			end
		end
		self:_AddClientToPath(pathOfEachCar, randomCar, randomClient, pathInfo)
		--self:_PrintSolution(pathOfEachCar)
	end
	--self:_PrintSolution(pathOfEachCar)
	return pathOfEachCar
end

function GA:_SetBestSolution(index)
	self.m_solution = self.m_solutionTbl[index]
end

-- 繁殖算法
-- 先算定一个车，这辆车用第二个父亲
-- 其他的因子优先从第一个父亲中选
function GA:_GetChildFromParent(solutionIndex1, solutionIndex2)
	local childPath = {}
	local leftClient = {1,2,3,4,5,6,7,8,9,10,11}
	local firstPickCar = random(g_countOfCar)

	--self:_PrintSolution(self.m_solutionTbl[solutionIndex1])
	--self:_PrintSolution(self.m_solutionTbl[solutionIndex2])

	childPath[firstPickCar] = self.m_solutionTbl[solutionIndex2][firstPickCar]
	for i,v in ipairs(childPath[firstPickCar]) do
		leftClient[v] = nil
	end

	local indexOfCar = firstPickCar
	--print("firstPickCar", firstPickCar)

	for i=1,g_countOfCar-1 do
		indexOfCar = indexOfCar + 1
		if indexOfCar > g_countOfCar then
			indexOfCar = 1
		end

		childPath[indexOfCar] = childPath[indexOfCar] or {}
		--print("_GetChildFromParent ", solutionIndex1, indexOfCar)
		for _,v in ipairs(self.m_solutionTbl[solutionIndex1][indexOfCar] or {}) do
			if leftClient[v] then
				--print(indexOfCar, v, "lalala")
				if self:_RawCanInsert(childPath, indexOfCar, v) then
					table.insert(childPath[indexOfCar], v)
					leftClient[v] = nil
				end
			end
		end
	end

	local firstChoiceIndex = indexOfCar
	local lastChoiceIndex = firstPickCar
	local middleChoiceIndex = firstChoiceIndex - 1
	if middleChoiceIndex == 0 then
		middleChoiceIndex = g_countOfCar
	end

	for _,clientIndex in pairs(leftClient) do
		leftClient[clientIndex] = nil
		if self:_RawCanInsert(childPath, firstChoiceIndex, clientIndex) then
			table.insert(childPath[firstChoiceIndex],clientIndex)
		elseif self:_RawCanInsert(childPath, middleChoiceIndex, clientIndex) then
			table.insert(childPath[middleChoiceIndex], clientIndex)
		else
			table.insert(childPath[lastChoiceIndex], clientIndex)
		end
	end

	--self:_PrintSolution(childPath)
	return childPath
end

function GA:_GetRandomSelected()
	for i=1,1000 do
		local selectIndex = random(self.m_sampleCount)
		if self.m_selected[selectIndex] then
			return selectIndex
		end
	end

	return selectIndex
end

function GA:Generate()
	self.m_solutionTbl = {}
	for i=1,self.m_sampleCount do
		local solution = self:_GenerateRandomSolution()
		table.insert(self.m_solutionTbl, solution)
	end
end

function GA:Mutation()
	for index,_ in pairs(self.m_outed) do
		local randomSelectIndex1 = self:_GetRandomSelected()
		local randomSelectIndex2 = self:_GetRandomSelected()
		-- _GetChildFromParent 一定要返回一个新对象,因为m_solutionTbl最终会被浅拷贝
		--print(randomSelectIndex1.." and "..randomSelectIndex2.." generate "..index)
		self.m_solutionTbl[index] = self:_GetChildFromParent(randomSelectIndex1, randomSelectIndex2)
	end
	self.m_selected = {}
	self.m_outed = {}
end

function GA:_CompareEval(evalA, evalB)
	local costDiff = evalA.cost - evalB.cost
	local satisfyDiff = evalA.satisfy - evalB.satisfy
	if evalA.maxLen > evalB.maxLen then
		return false
	elseif evalA.maxLen < evalB.maxLen then
		return true
	end
	-- A的成本高
	if costDiff > 0 then
		-- A的满意度低
		if satisfyDiff < 0 then
			return false
		end

		local costDiffRate = costDiff / evalA.cost
		local satisfyDiffRate = satisfyDiff/ evalA.satisfy

		-- 成本的影响盖过了满意度
		if costDiffRate > satisfyDiffRate then
			return false
		end

		return true
	end

	-- 接下来A的成本低

	-- A的满意度高
	if satisfyDiff > 0 then
		return true
	end

	local costDiffRate =  - costDiff / evalA.cost
	local satisfyDiffRate =  - satisfyDiff/ evalA.satisfy

	-- 满意度的影响盖过了成本
	if costDiffRate < satisfyDiffRate then
		return true
	end

	return false

end

-- 适应因子计算
-- 计算出成本和满意度
function GA:_Evaluate(solutionIndex)
	local cost = 0 					-- 成本
	local satisfy = 0 				-- 满意度(总时间，每个点的到达时间 - 下单时间之和)
	local maxLen = 0

	for carIndex=1,g_countOfCar do
		cost = cost + 5 			-- 固定工资
		local totalDistance = 0
		local totalTime = 0
		local lastClient = g_repoIndex
		--print("solutionIndex ", solutionIndex)
		--self:_PrintSolution(self.m_solutionTbl[solutionIndex])
		--print(solutionIndex, carIndex)
		local firstIndex = self.m_solutionTbl[solutionIndex][carIndex][1]
		local begintime = g_clientBeginTime[firstIndex]
		local dynamicTime = begintime

		maxLen = math.max(maxLen, #self.m_solutionTbl[solutionIndex][carIndex] or 0)

		for _,clientIndex in ipairs(self.m_solutionTbl[solutionIndex][carIndex]) do
			
			local currentDistance = self:_GetDistance(lastClient, clientIndex)
			totalDistance = totalDistance + currentDistance

			local transportTime = self:_GetCostTime(currentDistance)
			local arriveTime = dynamicTime + transportTime
			local endTime = g_clientEndTime[clientIndex]
			local begintime = g_clientBeginTime[clientIndex]
			local price = g_clientPrice[clientIndex]
			-- 10 单位时间的货损成本
			cost = cost + self:_GetTimeLostValue(transportTime, price)

			satisfy = satisfy + arriveTime - begintime
			if arriveTime > endTime then
				-- 8 超出配送时间的惩罚成本
				cost = cost + self:_GetTimePunish(arriveTime - endTime, price)
			end

			lastClient = clientIndex
			-- totalTime = totalTime + 5*60 -- 每位顾客的访问时间
		end

		totalDistance = totalDistance + self:_GetDistance(lastClient, g_repoIndex)
		-- 5 运输成本
		cost = cost + (totalDistance / 1000) * 5

	end

	return {cost = cost, satisfy = 1/satisfy, maxLen = maxLen}
end

function GA:ShouldEnd()
	if self.m_currentGeneration > self.m_maxGeneration then
		return true
	end
	return false
end

function GA:Select()
	self.m_selected = {}
	self.m_outed = {}
	self:_RandomSelectSeqeuence()
	for index =1,self.m_sampleCount,2 do
		local evalA = self:_Evaluate(index)
		local evalB = self:_Evaluate(index + 1)

		-- A更好
		if self:_CompareEval(evalA, evalB) then
			self.m_selected[index] = true
			self.m_outed[index + 1] = true
			if self.m_bestEval == nil or not self:_CompareEval(self.m_bestEval, evalA) then
				self:_SetBestSolution(index)
				self.m_bestEval = evalA
			end
		else
			self.m_outed[index] = true
			self.m_selected[index + 1] = true
			if self.m_bestEval == nil or not self:_CompareEval(self.m_bestEval, evalB) then
				self:_SetBestSolution(index + 1)
				self.m_bestEval = evalB
			end
		end
	end
	local selectedStr = "优胜的样本序号为： "
	for k,v in pairs(self.m_selected) do
		selectedStr = selectedStr .. k..", "
	end
	--print(selectedStr)

	selectedStr = selectedStr.."其它样本将会被淘汰"
	print(selectedStr)
	for k,v in pairs(self.m_outed) do
		selectedStr = selectedStr .. k..", "
	end
	--print(selectedStr)

end

function GA:_PrintSolution(solution)
	print("==========================================")
	for carIndex,carPath in pairs(solution or {}) do
		local resultStr = "第"..carIndex.."辆车的路径为 : 0"
		for _,clientIndex in ipairs(carPath or {}) do
			resultStr = resultStr..", "..clientIndex
		end
		resultStr = resultStr .. ", 0"
		print(resultStr)
	end
end

function GA:Run()
	print("遗传算法开始初始化.")
	self:Init()
	print("初始化完毕,开始产生样本.")
	self:Generate()
	print("样本生成完毕,样本总数为 "..self.m_sampleCount..".")
	self.m_beginCalTime = os.time()
	print("迭代开始，进入选择、繁殖过程")
	while not self:ShouldEnd() do
		print("第"..self.m_currentGeneration.."代.")
		GA:Select()
		GA:Mutation()
		GA.m_currentGeneration = GA.m_currentGeneration + 1
	end
	print("算法结束，最终结果为")
	self:_PrintSolution(self.m_solution)
end


GA:Run()

