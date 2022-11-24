ProductionBoost = {}
ProductionBoost.defaultGlobalFactor = 2.0
ProductionBoost.notOwnedStorageFactor = 5.0
ProductionBoost.debugFull = true
ProductionBoost.path = g_currentModDirectory;
ProductionBoost.modName = g_currentModName;
ProductionBoost.internalSettingsFile = "config/ProductionBoost.xml"
ProductionBoost.userSettingsFile = "modSettings/ProductionBoost.xml"
ProductionBoost.PRODUCTION_CONFIGURATIONS = {}

--
function ProductionBoost.initXml()
	ProductionBoost.xmlSchema = XMLSchema.new("productionBoost")

	local globalKey = "productionBoost"
	ProductionBoost.xmlSchema:register(XMLValueType.BOOL, globalKey.."#showDebug", "Show the visual debugging in the production menu", false)
	ProductionBoost.xmlSchema:register(XMLValueType.FLOAT, globalKey.."#globalFactor", "The multiplication factor applied to both cycle & storage if the others are not set", ProductionBoost.defaultGlobalFactor)
	ProductionBoost.xmlSchema:register(XMLValueType.FLOAT, globalKey.."#notOwnedFactor", "The multiplication factor applied to storage if production is not owned", ProductionBoost.notOwnedStorageFactor)
	ProductionBoost.xmlSchema:register(XMLValueType.FLOAT, globalKey.."#cycleFactor", "The multiplication factor applied to each production cycle", nil)
	ProductionBoost.xmlSchema:register(XMLValueType.FLOAT, globalKey.."#storageFactor", "The  multiplication factor applied to each storage fillType", nil)
	
	local productionKey = "productionBoost.productionOverrides.productionOverride(?)"
	local productionSchemas = {
		[1] = { ["schema"] = ProductionBoost.xmlSchema, ["key"] = productionKey },
	}
	for _, s in ipairs(productionSchemas) do
		s.schema:register(XMLValueType.STRING, s.key.."#configFileName", "Vehicle config file xml full path - used to identify supported vehicles", nil)
		s.schema:register(XMLValueType.BOOL, s.key.."#showDebug", "Show debug in console for this production only", false)
		s.schema:register(XMLValueType.STRING, s.key.."#globalFactor", "Multiplication factor applied to both cycle & storage", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#notOwnedFactor", "Multiplication factor applied storage if production is not owned", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#cycleFactor", "Multiplication factor applied to each production cycle", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#storageFactor", "Multiplication factor applied to each storage fillType", nil)
	
		s.schema:register(XMLValueType.STRING, s.key..".storage(?)#fillType", "FillType to override", nil)
		s.schema:register(XMLValueType.STRING, s.key..".storage(?)#capacity", "New Capacity", nil)
		s.schema:register(XMLValueType.STRING, s.key..".storage(?)#notOwnedCapacity", "New Capacity if production not owned", nil)
	end
end
--
function ProductionBoost.importUserConfigurations(userSettingsFile, overwriteExisting)

	if g_currentMission.isMultiplayer then
		print("Custom configurations are not supported in multiplayer")
		return
	end
	
	local N = 0
	if fileExists(userSettingsFile) then
		ProductionBoost.importGlobalSettings(userSettingsFile, overwriteExisting)
		print("-- IMPORT user production overrides")
		N = N + ProductionBoost.importProductionOverrides(userSettingsFile, overwriteExisting)
	else
		print("-- CREATING user settings file")
		local defaultSettingsFile = Utils.getFilename(ProductionBoost.internalSettingsFile, ProductionBoost.path)
		copyFile(defaultSettingsFile, userSettingsFile, false)

		ProductionBoost.showDebug = false
		ProductionBoost.globalFactor = ProductionBoost.defaultGlobalFactor
	end
	
	printf("-- LOADED %s user settings", N)
	return N
end
--
function ProductionBoost.importGlobalSettings(xmlFilename, overwriteExisting)

	if g_currentMission:getIsServer() then

		local xmlFile = XMLFile.load("configXml", xmlFilename, ProductionBoost.xmlSchema)
		if xmlFile ~= 0 then
		
			if overwriteExisting or not ProductionBoost.globalSettingsLoaded then
				print("-- IMPORT Production Boost global settings")
				ProductionBoost.globalSettingsLoaded = true
				ProductionBoost.showDebug = xmlFile:getValue("productionBoost#showDebug", false)
				ProductionBoost.globalFactor = xmlFile:getValue("productionBoost#globalFactor", ProductionBoost.defaultGlobalFactor)
				ProductionBoost.notOwnedFactor = xmlFile:getValue("productionBoost#notOwnedFactor", ProductionBoost.notOwnedStorageFactor)
				ProductionBoost.cycleFactor = xmlFile:getValue("productionBoost#cycleFactor", nil)
				ProductionBoost.storageFactor = xmlFile:getValue("productionBoost#storageFactor", nil)
				printf("    -- Show Debug: %s", ProductionBoost.showDebug)
				printf("    -- Global Factor: %2.1f", ProductionBoost.globalFactor)
				printf("    -- NotOwned Factor: %2.1f", ProductionBoost.notOwnedFactor)
				if ProductionBoost.cycleFactor ~= nil then 
					printf("    -- Cycle Factor: %2.1f", ProductionBoost.cycleFactor)
				end
				if ProductionBoost.storageFactor ~= nil then 
					printf("    -- Storage Factor: %2.1f", ProductionBoost.storageFactor)
				end
			end
			xmlFile:delete()
		end
	else
		print("Production Boost - global settings are only loaded for the server")
	end
end
--
function ProductionBoost.importProductionOverrides(xmlFilename, overwriteExisting)

	local i = 0
	local xmlFile = XMLFile.load("configXml", xmlFilename, ProductionBoost.xmlSchema)
	if xmlFile ~= 0 then
	
		while true do
			local configKey = string.format("productionBoost.productionOverrides.productionOverride(%d)", i)

			if not xmlFile:hasProperty(configKey) then
				break
			end

			local configFileName = xmlFile:getValue(configKey.."#configFileName")
			local validXmlFilename = ProductionBoost.getValidXmlName(configFileName)
			
			if ProductionBoost.debugFull then
				printf("---- ValidXml: %s ", validXmlFilename)
			end

			if validXmlFilename ~= nil then
				local config = ProductionBoost.PRODUCTION_CONFIGURATIONS[validXmlFilename]
				if config == nil or overwriteExisting then 
					-- init a new object
					config = {}

					-- set the filename based off of the loaded validXmlFilename
					config.xmlFilename = validXmlFilename

					-- set the config values from the xml
					config.showDebug = xmlFile:getValue(configKey.."#showDebug", false)
					config.globalFactor = xmlFile:getValue(configKey.."#globalFactor", nil)
					config.notOwnedFactor = xmlFile:getValue(configKey.."#notOwnedFactor", nil)
					config.cycleFactor = xmlFile:getValue(configKey.."#cycleFactor", nil)
					config.storageFactor = xmlFile:getValue(configKey.."#storageFactor", nil)

					-- allow individual storage filltypes to be overridden
					local storageOverrides = {}
					local j = 0
					while true do
						local loadAreaKey = string.format("%s.storage(%d)", configKey, j)
						if not xmlFile:hasProperty(loadAreaKey) then
							break
						end
						storageOverrides[j+1] = {}
						storageOverrides[j+1].fillType = xmlFile:getValue(loadAreaKey.."#fillType")
						storageOverrides[j+1].capacity = xmlFile:getValue(loadAreaKey.."#capacity")
						storageOverrides[j+1].notOwnedCapacity = xmlFile:getValue(loadAreaKey.."#notOwnedCapacity")
						j = j + 1
					end

					if table.getn(storageOverrides) ~= 0 then
						config.storage = storageOverrides
					end

					-- if we've enabled debug on an individual item, call it out as it's loaded
					if not config.showDebug then
						printf("---- parsed %s", validXmlFilename)
					else
						printf("---- parsed %s DEBUG", validXmlFilename)
					end

				else
					if ProductionBoost.debugFull then
						printf("---- -- Config ALREADY EXISTS: %s", validXmlFilename)
					end
				end

				-- overrwrite
				ProductionBoost.PRODUCTION_CONFIGURATIONS[validXmlFilename] = config
			else
				if ProductionBoost.debugFull then
					print("---- Config NOT FOUND: %s", validXmlFilename)
				end			
			end
			
			i = i + 1
		end

		xmlFile:delete()
	end

	printf("-- IMPORTED %s user configurations", i)
	return i
end
--
function ProductionBoost.getValidXmlName(configName)

	local xmlFilename = configName
	if g_storeManager:getItemByXMLFilename(xmlFilename) then
		return xmlFilename
	end
	
	xmlFilename = g_modsDirectory..configName
	if g_storeManager:getItemByXMLFilename(xmlFilename) then
		return xmlFilename
	end
	
	for i = 1, #g_dlcsDirectories do
		local dlcsDir = g_dlcsDirectories[i].path
		xmlFilename = dlcsDir..configName
		if g_storeManager:getItemByXMLFilename(xmlFilename) then
			return xmlFilename
		end
	end

end
--
function ProductionBoost:productionPointOnLoad()	

	local spec = self.spec_productionPoint
	local xmlFilename = spec.productionPoint.owningPlaceable.configFileName
	local prodOwnerId = spec.productionPoint.owningPlaceable:getOwnerFarmId()
	local currentFarmId = g_currentMission:getFarmId()
    local isProductionOwned = prodOwnerId == currentFarmId
	
	printf("-=- onLoadSavegame: %s", xmlFilename)
	printf("-=- productionName: %s", self:getName())
	printf("-=- prodOwnerId: %s", prodOwnerId)
	printf("-=- currentFarmId: %s", currentFarmId)
    printf("-=- isOwned: %s ", isProductionOwned)

	-- if ProductionBoost.debug then 
	-- 	print_r(self.productions)
	-- end
end
--
function ProductionBoost.updateSingleProduction(productionPoint)

	-- get the xml filename and owner
	local xmlFilename = productionPoint.owningPlaceable.configFileName
	local validXmlFilename = ProductionBoost.getValidXmlName(xmlFilename)

	if showDebug or ProductionBoost.debugFull then 
		printf("---- Production: %s [%s]", productionPoint:getName(), validXmlFilename)
	end

	local prodOwnerId = productionPoint:getOwnerFarmId()
	local isProductionOwned = prodOwnerId ~= 0
	
	-- get the debug status & factor from loaded settings
	local showDebug = ProductionBoost.showDebug
	local cycleFactor = ProductionBoost.globalFactor
	local storageFactor = cycleFactor
	local storageOverrides = nil
	
	-- from the config, if cycleFactor or storage factor is set, use those.
	if ProductionBoost.cycleFactor ~= nil then
		cycleFactor = ProductionBoost.cycleFactor
	end
	if ProductionBoost.storageFactor ~= nil then
		storageFactor = ProductionBoost.storageFactor
	end

	-- if the production is not owned, apply the notOwnedFactor to extend the input amounts
	if not isProductionOwned then
		storageFactor = ProductionBoost.notOwnedFactor
	end

	-- add in the custom overrides from the config file
	local customConfig = ProductionBoost.PRODUCTION_CONFIGURATIONS[validXmlFilename]
	if customConfig then
		if customConfig.showDebug ~= nil then
			showDebug = customConfig.showDebug
		end
		if customConfig.globalFactor ~= nil then
			cycleFactor = customConfig.globalFactor
			storageFactor = customConfig.globalFactor
		end
		if customConfig.cycleFactor ~= nil then
			cycleFactor = customConfig.cycleFactor
		end
		if customConfig.storageFactor ~= nil then
			storageFactor = customConfig.storageFactor
		end
		if customConfig.storage ~= nil then
			storageOverrides = customConfig.storage
			print("---- STORAGE OVERRIDES")
			print_r(storageOverrides)
		end
	end

	-- exit if we don't need to continue
	if cycleFactor == 1 and storageFactor == 1 and storageOverrides == nil then
		if showDebug or ProductionBoost.debugFull then 
			print("---- SKIP")
		end
		return
	end

	-- show debug info to console
	if showDebug or ProductionBoost.debugFull then 
		printf("---- Boosting: %s", productionPoint:getName())
	end
	if ProductionBoost.debugFull then 
		printf("---- - productionPointFilename: %s", validXmlFilename)
		printf("---- - productionPointOwnerId: %s", prodOwnerId)
		printf("---- - isOwned: %s ", isProductionOwned)
		printf("---- - cycleFactor: %2.1f", cycleFactor)
		printf("---- - storageFactor: %2.1f", storageFactor)
	end
	
	-- update production recipe cycles per month based on the input factor
	if cycleFactor ~= 1 then
		for i, production in ipairs(productionPoint.productions) do
			if production.outputs[1] ~= nil then
				local origPerMonth = production.cyclesPerMonth
				local newCyclesPerHour = production.cyclesPerHour * cycleFactor

				production.cyclesPerHour = newCyclesPerHour
				production.cyclesPerMinute = production.cyclesPerHour / 60
				production.cyclesPerMonth = production.cyclesPerHour * 24 -- per day, actually

				if showDebug or ProductionBoost.debugFull then
					printf("---- - Recipe %s cycles/m boosted by %2.1f from %s to %s",
						production.name,
						cycleFactor, 
						origPerMonth, 
						production.cyclesPerMonth
					)
				end
			end
		end
	end

	-- increase the input and output numbers to match the new production rates
	if storageFactor ~= 1 or storageOverrides then
		for i, capacity in pairs(productionPoint.storage.capacities) do
			local newCapacity = 0
			local fillTypeName = g_fillTypeManager.fillTypes[i].name

			-- if the config forces an override capacity then override it
			if storageOverrides ~= nil then
				local override
				for s, eachOverride in ipairs(storageOverrides) do
					if eachOverride.fillType.upper == fillTypeName.upper then 
						override = eachOverride
					end
				end

				-- if we found a fillType specific override, apply it as needed
				if override ~= nil then
					if isProductionOwned and override.capacity ~= nil then
						newCapacity = override.capacity
					end
					if not isProductionOwned and override.notOwnedCapacity ~= nil then
						newCapacity = override.notOwnedCapacity
					end
	
					if showDebug or ProductionBoost.debugFull then
						printf("---- - Storage for %s forced update from %s to %s",
							fillTypeName,
							capacity,
							newCapacity
						)
					end	
				end

			else 
				newCapacity = capacity * storageFactor
				if showDebug or ProductionBoost.debugFull then
					printf("---- - Storage for %s boosted by %2.1f from %s to %s",
						fillTypeName,
						storageFactor,
						capacity,
						newCapacity
					)
				end
			end 

			-- actually set the new capacity back into the production point
			if newCapacity ~= 0 then
				productionPoint.storage.capacities[i] = newCapacity
			end
		end
	end
end
--
function ProductionBoost:updateProductionData()	
	printf("-- ProductionBoost: Update All Production Data")

	if g_currentMission ~= nil and g_currentMission.productionChainManager ~= nil then
		local w = g_currentMission.productionChainManager.productionPoints;

		for prodId = 1, #g_currentMission.productionChainManager.productionPoints do
			local productionPoint = g_currentMission.productionChainManager.productionPoints[prodId]
			ProductionBoost.updateSingleProduction(productionPoint)
		end
	end
end
--
function ProductionBoost:loadXml()
	printf('-- ProductionBoost: Load XML Settings')

	-- initialize the xml structure
	ProductionBoost.initXml()

	-- load the user settings
	local userSettingsFile = Utils.getFilename(ProductionBoost.userSettingsFile, getUserProfileAppPath())
	ProductionBoost.importUserConfigurations(userSettingsFile)
	
	-- did we load the config?
	if ProductionBoost.debugFull then
		printf('-- ProductionBoost: Loaded Custom Production Configurations')
		DebugUtil.printTableRecursively(ProductionBoost.PRODUCTION_CONFIGURATIONS)
	end

	-- initialize the production types
	ProducitonTypes.initXML()
end
--
function ProductionBoost:init()
	print('-- ProductionBoost: Initialize')

	-- We need the mission active before this can be called.
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, ProductionBoost.loadXml)

	-- add listener for when a production is placed, and update that production as needed

	-- add listener for when a production is purchased, update that production to an owned production

	-- load the rest of the productions after we have a baseMission
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, ProductionBoost.updateProductionData);

	-- setup UI visibility for any production boost that is currently active

	
end
ProductionBoost.init()