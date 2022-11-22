ProductionBoost = {}
ProductionBoost.defaultGlobalFactor = 2.0
ProductionBoost.notOwnedStorageFactor = 5.0
ProductionBoost.debugFull = true
ProductionBoost.path = g_currentModDirectory;
ProductionBoost.modName = g_currentModName;
ProductionBoost.userSettingsFile = "modSettings/ProductionBoost.xml"
ProductionBoost.PRODUCTION_CONFIGURATIONS = {}

--
function ProductionBoost.initXml()
	--g_configurationManager:addConfigurationType("productionBoost", g_i18n:getText("configuration_productionBoost"), "productionBoost", nil, nil, nil, ConfigurationUtil.SELECTOR_MULTIOPTION)
	
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
		s.schema:register(XMLValueType.STRING, s.key.."#globalFactor", "Multiplication factor applied to both cycle & storage", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#notOwnedFactor", "Multiplication factor applied storage if production is not owned", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#cycleFactor", "Multiplication factor applied to each production cycle", nil)
		s.schema:register(XMLValueType.STRING, s.key.."#storageFactor", "Multiplication factor applied to each storage fillType", nil)
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
		local defaultSettingsFile = Utils.getFilename("config/ProductionBoost.xml", ProductionBoost.path)
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
				printf("    -- Cycle Factor: %2.1f", ProductionBoost.cycleFactor)
				printf("    -- Storage Factor: %2.1f", ProductionBoost.storageFactor)
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
					config = {}
					-- configGroup[selectedConfigs].loadingArea = {}
					
					-- local config = configGroup[selectedConfigs]
					-- config.useConfigName = useConfigName
					config.xmlFilename = validXmlFilename
					
					-- local j = 0
					-- local hasBaleHeight = false
					-- while true do
					-- 	local loadAreaKey = string.format("%s.loadingArea(%d)", configKey, j)
					-- 	if not xmlFile:hasProperty(loadAreaKey) then
					-- 		break
					-- 	end
					-- 	config.loadingArea[j+1] = {}
					-- 	config.loadingArea[j+1].width  = xmlFile:getValue(loadAreaKey.."#width")
					-- 	config.loadingArea[j+1].length = xmlFile:getValue(loadAreaKey.."#length")
					-- 	config.loadingArea[j+1].height = xmlFile:getValue(loadAreaKey.."#height")
					-- 	config.loadingArea[j+1].baleHeight = xmlFile:getValue(loadAreaKey.."#baleHeight", nil)
					-- 	config.loadingArea[j+1].offset = xmlFile:getValue(loadAreaKey.."#offset", "0 0 0", true)
					-- 	config.loadingArea[j+1].noLoadingIfFolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfFolded", false)
					-- 	config.loadingArea[j+1].noLoadingIfUnfolded = xmlFile:getValue(loadAreaKey.."#noLoadingIfUnfolded", false)
					-- 	config.loadingArea[j+1].noLoadingIfCovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfCovered", false)
					-- 	config.loadingArea[j+1].noLoadingIfUncovered = xmlFile:getValue(loadAreaKey.."#noLoadingIfUncovered", false)
					-- 	hasBaleHeight = hasBaleHeight or type(config.loadingArea[j+1].baleHeight) == 'number'
					-- 	j = j + 1
					-- end
					
					-- local isBaleTrailer = xmlFile:getValue(configKey..".options#isBaleTrailer", nil)
					-- local horizontalLoading = xmlFile:getValue(configKey..".options#horizontalLoading", nil)
					
					-- config.horizontalLoading = horizontalLoading or isBaleTrailer or false
					-- config.isBaleTrailer = isBaleTrailer or hasBaleHeight
				
					config.showDebug = xmlFile:getValue(configKey.."#showDebug", debugAll)
					config.globalFactor = xmlFile:getValue(configKey.."#globalFactor", nil)
					config.notOwnedFactor = xmlFile:getValue(configKey.."#notOwnedFactor", nil)
					config.cycleFactor = xmlFile:getValue(configKey.."#cycleFactor", nil)
					config.storageFactor = xmlFile:getValue(configKey.."#storageFactor", nil)

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

	local xmlFilename = productionPoint.owningPlaceable.configFileName
	local validXmlFilename = ProductionBoost.getValidXmlName(xmlFilename)
	local prodOwnerId = productionPoint:getOwnerFarmId()
	local isProductionOwned = prodOwnerId ~= 0
	
	-- get the debug status & factor from loaded settings
	local showDebug = ProductionBoost.showDebug
	local cycleFactor = ProductionBoost.globalFactor
	local storageFactor = cycleFactor
	
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
	end

	-- exit if we don't need to continue
	if cycleFactor == 1 and storageFactor == 1 then
		return
	end

	-- show debug info to console
	if showDebug or ProductionBoost.debugFull then 
		printf("---- Boosting: %s", productionPoint:getName())
	end
	if ProductionBoost.debugFull then 
		printf("---- -- productionPointFilename: %s", validXmlFilename)
		printf("---- -- producitonPointOwnerId: %s", prodOwnerId)
		printf("---- -- isOwned: %s ", isProductionOwned)
		printf("---- -- cycleFactor: %2.1f", cycleFactor)
		printf("---- -- storageFactor: %2.1f", storageFactor)
	end
	
	-- update production recipe cycles per month
	if cycleFactor ~= 1 then
		for i, production in ipairs(productionPoint.productions) do
			if production.outputs[1] ~= nil then
				local origPerMonth = production.cyclesPerMonth
				local newCyclesPerHour = production.cyclesPerHour * cycleFactor

				production.cyclesPerHour = newCyclesPerHour
				production.cyclesPerMinute = production.cyclesPerHour / 60
				production.cyclesPerMonth = production.cyclesPerHour * 24 -- per day, actually

				if showDebug or ProductionBoost.debugFull then
					printf("---- -- Recipe %s cycles/m boosted by %2.1f from %s to %s",
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
	if storageFactor ~= 1 then
		for i, value in pairs(productionPoint.storage.capacities) do
			local newValue = value * storageFactor

			productionPoint.storage.capacities[i] = newValue
			
			if showDebug or ProductionBoost.debugFull then
				printf("---- -- Storage for %s boosted by %2.1f from %s to %s",
					g_fillTypeManager.fillTypes[i].name,
					storageFactor,
					value,
					newValue
				)
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
end


function ProductionBoost:init()
	printf('-- ProductionBoost: Initialize')

	-- We need the mission active before this can be called.
	Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, ProductionBoost.loadXml)

	-- load the rest of the productions after we have a baseMission
	FSBaseMission.registerActionEvents = Utils.appendedFunction(FSBaseMission.registerActionEvents, ProductionBoost.updateProductionData);
	--FSBaseMission.onConnectionFinishedLoading = Utils.appendedFunction(FSBaseMission.onConnectionFinishedLoading, ProductionBoost.loadProductionData)
end

-- init the mod through the basegame loadMap function.
--addModEventListener(ProductionBoost)
ProductionBoost.init()

-- function PlaceableProductionPoint:onLoad(savegame)
--     local spec = self.spec_productionPoint
--     local productionPoint = ProductionPoint.new(self.isServer, self.isClient, self.baseDirectory)
--     productionPoint.owningPlaceable = self
--     if productionPoint:load(self.components, self.xmlFile, "placeable.productionPoint", self.customEnvironment, self.i3dMappings) then
--         spec.productionPoint = productionPoint
--     else
--         productionPoint:delete()
--         self:setLoadingState(Placeable.LOADING_STATE_ERROR)
--     end
-- end