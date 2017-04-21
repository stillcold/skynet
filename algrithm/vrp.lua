--[[
环境变量
--]]
local random = math.random
local ceil = math.ceil

--[[
题目中的输入
--]]
local g_countOfRepo = 1
local g_countOfCar = 3
local g_countOfClient = 11

--[[
常量
--]]
--local g_RUNTIME = 60*1 -- 1min


local GA = {}
GA.m_sampleCount = 1000
GA.m_beginCalTime = nil
GA.m_solutionTbl = {}
GA.m_solution = nil
GA.m_compareSequence = nil
GA.m_selected = nil
GA.m_outed = nil
GA.m_bestEval = -1
GA.m_currentGeneration = 0 -- 当前迭代次数
GA.m_maxGeneration = 100 -- 终止条件

function GA:Init()
	self.m_compareSequence = {}
	for i=1,self.m_sampleCount do
		table.insert(self.m_compareSequence, i)
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

function GA:_GenerateRandomSolution()
	local pathOfEachCar = {}
	for i=1,g_countOfCar do
		pathOfEachCar[i] = {}
	end
	for i=1,g_countOfClient do
		local randomCar = random(g_countOfCar)
		table.insert(pathOfEachCar[randomCar], i)
	end
	return pathOfEachCar
end

function GA:_SetBestSolution(index)
	self.m_solution = self.m_solutionTbl[index]
end

-- 适用于三个函数
function GA:_GetChildFromParent(index1, index2)
	local childPath = {}
	local taken = {}
	for i=1,g_countOfCar do
		childPath[i] = self.m_solutionTbl[index1][i]
		childPath[]
	end
end

function GA:_GetRandomSelected()
	for i=1,10 do
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
		self.m_solutionTbl[inedx] = self:_GetChildFromParent(randomSelectIndex1, randomSelectIndex2)
	end
end

-- todo 
function GA:_Evaluate(index)
end

function GA:ShouldEnd()
	if self.m_currentGeneration >= self.m_maxGeneration then
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
		if evalA <= evalB then
			self.m_selected[index] = true
			self.m_outed[index + 1] = true
			if self.m_bestEval ~= -1 and self.m_bestEval > evalA then
				self:_SetBestSolution(index)
			end
		else
			self.m_outed[index] = true
			self.m_selected[inedx + 1] = true
			if self.m_bestEval ~= -1 and self.m_bestEval > evalB then
				self:_SetBestSolution(index + 1)
			end
		end
	end

end

function GA:Run()
	self:Init()
	self:Generate()
	self.m_beginCalTime = os.time()
	while self:ShouldEnd() do
		GA:Select()
		GA:Mutation()
		GA.m_currentGeneration = GA.m_currentGeneration + 1
	end
end