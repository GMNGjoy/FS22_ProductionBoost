ProductionTypes = {}
ProductionTypes.internalSettingsFile = "config/ProductionTypes.xml"
ProductionTypes.userSettingsFile = "modSettings/ProductionBoost_types.xml"
ProductionTypes.PRODUCTION_TYPES = {}

--
function ProductionTypes.initXml()
	ProductionTypes.xmlSchema = XMLSchema.new("productionTypes")

	local globalKey = "productionTypes"
	ProductionTypes.xmlSchema:register(XMLValueType.STRING, globalKey.."#name", "Name / key for the type which will be referneced elsewhere", nil)

	local typeKey = "productionTypes.productionType(?)"
	local productionSchemas = {
		[1] = { ["schema"] = ProductionTypes.xmlSchema, ["key"] = typeKey },
	}
	for _, s in ipairs(productionSchemas) do
		s.schema:register(XMLValueType.STRING, s.key.."#name", "Name / key for the type which will be referneced elsewhere", nil)
		s.schema:register(XMLValueType.STRING, s.key..".production(?)#configFileName", "Configuration XML file name", nil)
	end
end
--
function ProductionTypes.importUserConfigurations(userSettingsFile, overwriteExisting)

	if g_currentMission.isMultiplayer then
		print("Custom production type configurations are not supported in multiplayer")
		return
	end
	
	local N = 0
	if fileExists(userSettingsFile) then
		print("-- IMPORT user production types")
		N = N + ProductionTypes.importProductionTypes(userSettingsFile, overwriteExisting)
	else
		print("-- CREATING production types file")
		local defaultSettingsFile = Utils.getFilename(ProductionTypes.internalSettingsFile, ProductionTypes.path)
		copyFile(defaultSettingsFile, userSettingsFile, false)

		N = N + ProductionTypes.importProductionTypes(ProductionTypes.internalSettingsFile, overwriteExisting)
	end
	
	printf("-- LOADED %s type settings", N)
	return N
end
--
function ProductionTypes.importProductionTypes(xmlFilename, overwriteExisting)

	local i = 0
	local xmlFile = XMLFile.load("configXml", xmlFilename, ProductionTypes.xmlSchema)
	if xmlFile ~= 0 then
	
		while true do
			local configKey = string.format("productionTypes.productionType(%d)", i)

			if not xmlFile:hasProperty(configKey) then
				break
			end

			local configName = xmlFile:getValue(configKey.."#name")
			
			if configName ~= nil then
				local config = ProductionTypes.PRODUCTION_TYPES[configName]
				if config == nil or overwriteExisting then 
					-- init a new object
					config = {}

					-- allow individual storage filltypes to be overridden
					local productions = {}
					local j = 0
					while true do
						local loadAreaKey = string.format("%s.storage(%d)", configKey, j)
						if not xmlFile:hasProperty(loadAreaKey) then
							break
						end
						productions[j+1] = {}
						local configFileName = xmlFile:getValue(loadAreaKey.."#configFileName")
						productions[j+1].configFileName = ProductionBoost.getValidXmlName(configFileName)
						j = j + 1
					end

					if table.getn(productions) ~= 0 then
						config.productions = productions
					end

				else
					if ProductionBoost.debugFull then
						printf("---- -- Config ALREADY EXISTS: %s", validXmlFilename)
					end
				end

				-- overrwrite
				ProductionTypes.PRODUCTION_TYPES[configName] = config

				if ProductionBoost.debugFull then
					printf("---- -- TypeConfig ADDED: %s", configName)
				end

			else
				if ProductionBoost.debugFull then
					print("---- Config NOT FOUND: %s", configName)
				end			
			end
			
			i = i + 1
		end

		xmlFile:delete()
	end

	printf("-- IMPORTED %s user production types", i)
	return i
end
--
function ProductionTypes:loadXml()
	printf('-- ProductionTypes: Load XML')

	-- initialize the xml structure
	ProductionTypes.initXml()

	-- load the user settings
	local userSettingsFile = Utils.getFilename(ProductionTypes.userSettingsFile, getUserProfileAppPath())
	ProductionTypes.importUserConfigurations(userSettingsFile)
	
	-- did we load the config?
	if ProductionTypes.debugFull then
		printf('-- ProductionTypes: Loaded Custom Production Types')
		DebugUtil.printTableRecursively(ProductionTypes.PRODUCTION_TYPES)
	end
end