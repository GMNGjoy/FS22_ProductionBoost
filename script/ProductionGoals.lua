ProductionGoals = {}
ProductionGoals.dir = g_currentModDirectory;
ProductionGoals.modName = g_currentModName;
ProductionGoals.stats = {
	allProductions = 0,
	ownedProductions = 0,
	ownedActiveProductions = 0,
	ownedAllActiveProductions = 0,
}
ProductionGoals.productions = {}
ProductionGoals.productionStats = {}


-- TODO
-- Add production goal xml loader
-- Add listeners
---- Listener for production being purchased / sold
---- Listener for production recipe being activated
---- Listener for production being placed / demolished
-- Add UI tab
---- Add UI button
---- Add UI display for goals / highlight if active
---- Add UI progress bar for each
-- Add UI display for any goal boost currently active

function ProductionGoals:checkProductionUsage()	
	if g_currentMission ~= nil and g_currentMission.productionChainManager ~= nil then
		--local w = g_currentMission.productionChainManager.productionPoints;
		for prodId = 1, #g_currentMission.productionChainManager.productionPoints do
			local productionPoint = g_currentMission.productionChainManager.productionPoints[prodId]
			local prodOwnerId = productionPoint:getOwnerFarmId()
			if (prodOwnerId == g_currentMission:getFarmId()) then
				self.stats.ownedProductions = self.stats.ownedProductions + 1

				local activeRecipes = 0
				for r = 1, #productionPoint.productions do
					local recipe = productionPoint.productions[r]
					if recipe.isActive then
						activeRecipes = activeRecipes + 1
					end
					
				end

				-- Save the production point into the stats
				self.productionStats[productionPoint.index] = {
					index = productionPoint.index,
					name = productionPoint.name,
					title = productionPoint.title,
					activeRecipes = #productionPoint.productions
				}
			end		
		end
	end
end
