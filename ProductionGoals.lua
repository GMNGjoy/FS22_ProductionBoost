ProductionBoost = {}
ProductionBoost.baseFactor = 5
ProductionBoost.logging = true
ProductionBoost.debug = true
ProductionBoost.dir = g_currentModDirectory;
ProductionBoost.modName = g_currentModName;
ProductionBoost.stats = {
	allProductions = 0,
	ownedProductions = 0,
	ownedActiveProductions = 0,
	ownedAllActiveProductions = 0,
}
ProductionBoost.productions = {}
ProductionBoost.productionStats = {}

-- source(TSStockCheck.dir .. "gui/InGameMenuTSStockCheck.lua")

function ProductionBoost:loadEachProduction(success, components, xmlFile, key, customEnv, i3dMappings)
	if success then
		local i3dName = xmlFile:getValue("placeable.base.filename")
		
		if ProductionBoost.logging then 
			printf("-- Boosting production: %s %s", i3dName, self.productionId)
		end
		if ProductionBoost.debug then 
			-- DebugUtil.printTableRecursively(customEnv)
		end

		local origData = {
			productions = {},
			outputs = {}
		}

		-- update production cycles per month
		for i, production in ipairs(self.productions) do
			if production.outputs[1] ~= nil then
				-- store the original cyclesPerMonth
				origData.productions['recipe'..i] = production.cyclesPerMonth

				-- local newCyclesPerHour = production.cyclesPerHour * ProductionBoost.baseFactor

				-- production.cyclesPerHour = newCyclesPerHour
				-- production.cyclesPerMinute = production.cyclesPerHour / 60
				-- production.cyclesPerMonth = production.cyclesPerHour * 24 -- per day, actually


				if ProductionBoost.logging then 
					printf("---- Recipe %s cycles/month boosted! %s", production.name, i)
				end
				-- if ProductionBoost.debug then
				-- 	printf("---- Recipe %s cycles/month from %s to %s; Monthly output updated from %s to %s ", 
				-- 		production.name, 
				-- 		origPerMonth, 
				-- 		production.cyclesPerMonth, 
				-- 		(origPerMonth * production.outputs[1].amount), 
				-- 		(production.cyclesPerMonth * production.outputs[1].amount)
				-- 	)	
				-- end
			end
		end

		-- increase the input and output numbers to match the new production rates
		for i, value in pairs(self.storage.capacities) do
			origData.outputs['output'..i] = value

			-- local newValue = value * ProductionBoost.baseFactor
			-- self.storage.capacities[i] = newValue
			if ProductionBoost.logging then 
				printf("---- Storage for %s boosted!", g_fillTypeManager.fillTypes[i].name)
			end
			-- if ProductionBoost.debug then
			-- 	printf("---- Storage for %s boosted from %s to %s",
			-- 		g_fillTypeManager.fillTypes[i].name,
			-- 		value,
			-- 		newValue
			-- 	)
			-- end
		end
		
		ProductionBoost.productions[i3dName] = origData
	end

	

	return success
end


function ProductionBoost:loadProductionData()	

	printf("-- loadProductionData")

	-- if ProductionBoost.debug then 
	-- 	print_r(self.productions)
	-- end

	if g_currentMission ~= nil and g_currentMission.productionChainManager ~= nil then
		local w = g_currentMission.productionChainManager.productionPoints;

		printf("-- allProductionPoints")
		DebugUtil.printTableRecursively(w)

		for prodId = 1, #g_currentMission.productionChainManager.productionPoints do
			local productionPoint = g_currentMission.productionChainManager.productionPoints[prodId]
			local prodOwnerId = productionPoint:getOwnerFarmId()
			
			printf("-- prodution %s %s", prodOwnerId, productionPoint:getName())
			
			if (prodOwnerId == g_currentMission:getFarmId()) then
				-- apply a ownership boost

			else 
				-- apply the default boost
			end		
		end
	end
end


function ProductionBoost:applyProductionBoost()	

	if ProductionBoost.debug then 
		print_r(self.productions)
	end

	if g_currentMission ~= nil and g_currentMission.productionChainManager ~= nil then
		--local w = g_currentMission.productionChainManager.productionPoints;
		for prodId = 1, #g_currentMission.productionChainManager.productionPoints do
			local productionPoint = g_currentMission.productionChainManager.productionPoints[prodId]
			local prodOwnerId = productionPoint:getOwnerFarmId()
			if (prodOwnerId == g_currentMission:getFarmId()) then
				-- apply a ownership boost

			else 
				-- apply the default boost
			end		
		end
	end
end

-- function ProductionBoost:checkProductionUsage()	
-- 	if g_currentMission ~= nil and g_currentMission.productionChainManager ~= nil then
-- 		--local w = g_currentMission.productionChainManager.productionPoints;
-- 		for prodId = 1, #g_currentMission.productionChainManager.productionPoints do
-- 			local productionPoint = g_currentMission.productionChainManager.productionPoints[prodId]
-- 			local prodOwnerId = productionPoint:getOwnerFarmId()
-- 			if (prodOwnerId == g_currentMission:getFarmId()) then
-- 				self.stats.ownedProductions = self.stats.ownedProductions + 1

-- 				local activeRecipes = 0
-- 				for r = 1, #productionPoint.productions do
-- 					local recipe = productionPoint.productions[r]
-- 					if recipe.isActive then
-- 						activeRecipes = activeRecipes + 1
-- 					end
					
-- 				end

-- 				-- Save the production point into the stats
-- 				self.productionStats[productionPoint.index] = {
-- 					index = productionPoint.index,
-- 					name = productionPoint.name,
-- 					title = productionPoint.title,
-- 					activeRecipes = #productionPoint.productions
-- 				}
-- 			end		
-- 		end
-- 	end
-- end

-- function ProductionBoost:checkProductionStockLevels()	
-- 	if g_currentMission ~= nil and g_currentMission.productionChainManager ~= nil then
-- 		local w = g_currentMission.productionChainManager.productionPoints;
-- 		for s = 1, #g_currentMission.productionChainManager.productionPoints do
-- 			local y = g_currentMission.productionChainManager.productionPoints[s]
-- 			local z = y:getOwnerFarmId()
-- 			local A = z == g_currentMission:getFarmId()
-- 			for x = 1, #y.outputFillTypeIdsArray do
-- 				local l = y.outputFillTypeIdsArray[x]
-- 				local v = MathUtil.round(y.storage:getFillLevel(l))
-- 				local B = y.storage:getCapacity(l)
-- 				local C = MathUtil.getFlooredPercent(v, B)
-- 				local D = y:getOutputDistributionMode(l)
-- 				if v > 0 and A then
-- 					self.stockData[l].currentStockLevel = self.stockData[l].currentStockLevel + v;
-- 					if self.stockData[l].stockLevels["Prod" .. tostring(s)] ~= nill then
-- 						self.stockData[l].stockLevels["Prod" .. tostring(s)].level =
-- 							self.stockData[l].stockLevels["Prod" .. tostring(s)].level + v
-- 					else
-- 						local p = nil;
-- 						self.stockData[l].stockLevels["Prod" .. tostring(s)] = {
-- 							name = y:getName(),
-- 							level = v,
-- 							mapHotSpot = p
-- 						}
-- 					end
-- 				end
-- 			end
-- 		end
-- 	end
-- 	self.inStockData = {}
-- 	for f, E in pairs(self.stockData) do
-- 		if E.currentStockLevel > 0 then
-- 			table.insert(self.inStockData, E)
-- 		end
-- 	end

-- end

function ProductionBoost:loadMap() 
	local stats = {}

	printf('-- ProductionBoost Load!')

	local function appendFunction(oldFunc, newFunc)
		if oldFunc ~= nil then
			return function (self, ...)
				retValue = oldFunc(self, ...)
				return newFunc(self, retValue, ...)
			end
		else
			return newFunc
		end
	end

	-- load production data
	-- ProductionBoost.loadProductionData()

	
	-- on startup, load each map production
	-- ProductionPoint.load = appendFunction(ProductionPoint.load, ProductionBoost.loadEachProduction)
	-- ProductionPoint.load = Utils.appendedFunction(ProductionPoint.load, ProductionBoost.loadEachProduction)

	-- once the map finishes loading, apply the boosts
	BaseMission.loadMapFinished = Utils.appendedFunction(BaseMission.loadMapFinished, ProductionBoost.loadProductionData)
end

-- ProductionBoost.initialize()
addModEventListener(ProductionBoost)


-- BaseMission.loadMapFinished = Utils.appendedFunction(BaseMission.loadMapFinished, RegisterRollerMissionVehicles.loadMapFinished)

