--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
local FCOISdefaultSettings = {}
local FCOISsettings = {}
local FCOISlocVars = {}
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons

--==========================================================================================================================================
--									FCOIS libAddonMenu 2.x settings menu
--==========================================================================================================================================
--Show the FCO ItemSaver FCOIS.settingsVars.settings panel
function FCOIS.ShowFCOItemSaverSettings()
    FCOIS.LAM:OpenToPanel(FCOIS.FCOSettingsPanel)
end

--Map the texture path to the texture ID
local function GetFCOTextureId(texturePath)
    if texturePath == nil or texturePath == "" then return 0 end
    for textureId, texturePathString in pairs(FCOIS.textureVars.MARKER_TEXTURES) do
        if	texturePathString == texturePath then
            return textureId
        end
    end
    return 0
end

-- Build the LAM options menu
function FCOIS.BuildAddonMenu()
    --Update some settings for the libAddonMenu settings menu
    FCOIS.updateSettingsBeforeAddonMenu()

    --Variablen
    local srcServer = 1
    local targServer = 1

    --Local variables to speed up stuff a bit
    FCOISdefaultSettings    = FCOIS.settingsVars.defaults
    FCOISsettings           = FCOIS.settingsVars.settings
    FCOISlocVars            = FCOIS.localizationVars
    local locVars           = FCOISlocVars.fcois_loc

    local panelData = {
		type 				= 'panel',
		name 				= FCOIS.addonVars.addonNameMenu,
		displayName 		= FCOIS.addonVars.addonNameMenuDisplay,
		author 				= FCOIS.addonVars.addonAuthor,
		version 			= FCOIS.addonVars.addonVersionOptions,
		registerForRefresh 	= true,
		registerForDefaults = true,
		slashCommand 		= "/fcoiss",
	    website             = FCOIS.addonVars.website
	}
	--The LibAddonMenu2.0 settings panel reference variable
	FCOIS.FCOSettingsPanel = FCOIS.LAM:RegisterAddonPanel(FCOIS.addonVars.gAddonName .. "_LAM", panelData)

    local apiVersion = FCOIS.APIversion or GetAPIVersion()
    --Backup variables
    if FCOIS.backup == nil then FCOIS.backup = {} end
    FCOIS.backup.withDetails = false
    FCOIS.backup.doClearBackup = false
    FCOIS.backup.apiVersion = tostring(apiVersion)
    local fcoBackup = FCOIS.backup
    --Restore variables
    if FCOIS.restore == nil then FCOIS.restore = {} end
    FCOIS.restore.withDetails = false
    FCOIS.restore.apiVersion = nil
    local fcoRestore = FCOIS.restore
    --Function to reset the backup edit control in the LAM settings to the current API version text
    local function resetBackupEditToCurrentAPI()
        local editCtrl = WINDOW_MANAGER:GetControlByName("FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT", "")
        if editCtrl ~= nil then
            editCtrl.editbox:SetText(apiVersion)
        end
        fcoBackup.apiVersion = apiVersion
        return fcoBackup.apiVersion
    end
    --Function to check if the backup API version edit text is too short
    local function isBackupEditAPITextTooShort()
        local editCtrl = WINDOW_MANAGER:GetControlByName("FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT", "")
        if editCtrl ~= nil then
            local editText = editCtrl.editbox:GetText()
            local apiVersionLength = FCOIS.APIVersionLength
            if editText and (editText == "" or string.len(editText) < apiVersionLength) then
                return true
            end
        end
        return false
    end

	-- Build options menu parts
    --The textures/marker icons names (just numbers)
	local texturesList = {}
    local maxTextureIcons = FCOIS.numVars.maxTextureIcons or 100
    for i=1, maxTextureIcons, 1 do
        texturesList[i] = tostring(i)
    end

    --Build the icons choicesValues list
    local iconsList, iconsListValues = FCOIS.GetLAMMarkerIconsDropdown('standard', true)
    --Build the icons list and the keybindings icons list
    local iconsListStandardIconOnKeybind = FCOIS.GetLAMMarkerIconsDropdown('keybinds', false)

    --The table with all the LAM dropdown controls that should get updated
    local LAMdropdownsWithIconList = {
        ["FCOItemSaver_Standard_Icon_On_Keybind_Dropdown"]              = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil },
        ["FCOItemSaver_Icon_On_Automatic_Set_Part_Dropdown"]            = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil },
        ["FCOItemSaver_Icon_On_Automatic_Non_Wished_Set_Part_Dropdown"] = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil },
        ["FCOItemSaver_Icon_On_Automatic_Crafted_Items_Dropdown"]       = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil },
        ["FCOItemSaver_Icon_On_Automatic_Recipe_Dropdown"]              = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil },
        ["FCOItemSaver_Icon_On_Automatic_Quality_Dropdown"]             = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil },
    }

    --Function to update the comboboxes of the LAM dropdowns holding the "iconList"/"iconsListStandardIconOnKeybind" entries
    --if an icon gets disabled or renamed
    local function updateIconListDropdownEntries()
        if LAMdropdownsWithIconList == nil then return nil end
        for dropdownCtrlName, updateData in pairs(LAMdropdownsWithIconList) do
            local dropdownCtrl = WINDOW_MANAGER:GetControlByName(dropdownCtrlName, "")
            if dropdownCtrl == nil or updateData == nil then return nil end
            if updateData["choices"] == nil then updateData["choices"] = "standard" end
            local choices = FCOIS.GetLAMMarkerIconsDropdown(updateData["choices"])
            local choicesValues = updateData["choicesValues"]
            local choicesTooltips = updateData["choicesTooltips"]
            dropdownCtrl:UpdateChoices(choices, choicesValues, choicesTooltips)
        end
    end

    --The list of recipe addons
    local recipeAddonsList = {}
    local recipeAddonsListValues = {}
    local function buildRecipeAddonsList()
        local recipeAddonsAvailable = FCOIS.otherAddons.recipeAddonsSupported
        for recipeAddonIdx, recipeAddonName in pairs(recipeAddonsAvailable) do
            table.insert(recipeAddonsListValues, recipeAddonIdx)
            table.insert(recipeAddonsList, recipeAddonName)
        end
    end
    buildRecipeAddonsList()

    --The list of research addons
    local researchAddonsList = {}
    local researchAddonsListValues = {}
    local function buildResearchAddonsList()
        local researchAddonsAvailable = FCOIS.otherAddons.researchAddonsSupported
        for researchAddonIdx, researchAddonName in pairs(researchAddonsAvailable) do
            table.insert(researchAddonsListValues, researchAddonIdx)
            table.insert(researchAddonsList, researchAddonName)
        end
    end
    buildResearchAddonsList()

	--Function to create a LAM control
	local function CreateControl(ref, name, tooltip, data, disabledChecks, getFunc, setFunc, defaultSettings, warning, isIconDropDown, scrollable)
        scrollable = scrollable or false
        if ref ~= nil then
            if string.find(ref, "FCOItemSaver_Settings_", 1)  ~= 1 then
                data.reference = "FCOItemSaver_Settings_" .. ref
            else
                data.reference = ref
            end
        end
        if data.type ~= "description" then
            data.name = name
            if data.type ~= "header" and data.type ~= "submenu" then
                data.tooltip = tooltip
                data.getFunc = getFunc
                data.setFunc = setFunc
                data.default = defaultSettings
                if disabledChecks ~= nil then
                    data.disabled = disabledChecks
                end
                data.scrollable = scrollable
                data.warning = warning
                --Is the created control a dropdown box containing the FCOIS marker icons?
                --Then add the reference to the list of dropboxes that need to be updated if an icon changes it's name or
                if isIconDropDown then
                    if LAMdropdownsWithIconList ~= nil then
                        LAMdropdownsWithIconList[tostring(data.reference)] = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil, ["scrollable"] = true }
                    end
                end
            end
        end
        return data
	end

	--Function to create a dropdown box for the LAM panel
	local function CreateDropdownBox(ref, name, tooltip, disabledChecks, getFunc, setFunc, defaultSettings, choicesList, choicesValuesList, choicesTooltipsList, warning, width, isIconDropDown, isScrollable)
        width = width or "full"
	    return CreateControl(ref, name, tooltip, { type = "dropdown", choices = choicesList, choicesValues = choicesValuesList, choicesTooltips = choicesTooltipsList, scrollable = isScrollable, width = width }, disabledChecks, getFunc, setFunc, defaultSettings, warning, isIconDropDown, isScrollable)
	end

-- !!! RU Patch Section START
--  Add english language description behind language descriptions in other languages
	local function nvl(val) if val == nil then return "..." end return val end
	--local LV_Cur = locVars
	local LV_Eng = FCOISlocVars.localizationAll[1]
	local languageOptions = {}
	for i=1, FCOIS.numVars.languageCount do
		local s="options_language_dropdown_selection"..i
		if locVars==LV_Eng then
			languageOptions[i] = nvl(locVars[s])
		else
			languageOptions[i] = nvl(locVars[s]) .. " (" .. nvl(LV_Eng[s]) .. ")"
		end
	end
-- !!! RU Patch Section END

    local savedVariablesOptions = {
    	[1] = locVars["options_savedVariables_dropdown_selection1"],
        [2] = locVars["options_savedVariables_dropdown_selection2"],
    }

    --The server/world/realm names dropdown
    local serverOptions = {}
    local serverOptionsValues = {}
    local serverOptionsTarget = {}
    local serverOptionsValuesTarget = {}
    local function reBuildServerOptions()
        local serverNames = FCOIS.mappingVars.serverNames
        --Reset the server name and index tables
        serverOptions = {}
        serverOptionsValues = {}
        for serverIdx, serverName in ipairs(serverNames) do
            if serverIdx > 1 then
                --Do we have server settings for the servername in the SavedVars?
                table.insert(serverOptionsTarget, serverName)
                table.insert(serverOptionsValuesTarget, serverIdx)
                if FCOItemSaver_Settings and FCOItemSaver_Settings[serverName] then
                    table.insert(serverOptions, serverName)
                    table.insert(serverOptionsValues, serverIdx)
                end
            else
                --Index 1: Always add it ("none" entry)
                table.insert(serverOptions, serverName)
                table.insert(serverOptionsValues, serverIdx)
                table.insert(serverOptionsTarget, serverName)
                table.insert(serverOptionsValuesTarget, serverIdx)
            end
        end
    end
    reBuildServerOptions()

    local mapServerNames = FCOIS.mappingVars.serverNames

	--Build the list of colored qualities for the settings
	local colorMagic = GetItemQualityColor(ITEM_QUALITY_MAGIC)
	local colorArcane = GetItemQualityColor(ITEM_QUALITY_ARCANE)
	local colorArtifact = GetItemQualityColor(ITEM_QUALITY_ARTIFACT)
	local colorLegendary = GetItemQualityColor(ITEM_QUALITY_LEGENDARY)
    local qualityList = {
		--[ITEM_QUALITY_TRASH] = locVars["options_quality_trash"],
		--[ITEM_QUALITY_NORMAL] = locVars["options_quality_normal"],
		[1] = locVars["options_quality_OFF"],
		[ITEM_QUALITY_MAGIC] 	 = colorMagic:Colorize(locVars["options_quality_magic"]),
		[ITEM_QUALITY_ARCANE] 	 = colorArcane:Colorize(locVars["options_quality_arcane"]),
		[ITEM_QUALITY_ARTIFACT]  = colorArtifact:Colorize(locVars["options_quality_artifact"]),
		[ITEM_QUALITY_LEGENDARY] = colorLegendary:Colorize(locVars["options_quality_legendary"]),
    }
    local levelList = {
        [1] = locVars["options_quality_OFF"],
    }
    local nonWishedChecksList = {
        [1] = locVars["options_level"],
        [2] = locVars["options_quality"],
        [3] = locVars["options_all"],
    }
    local nonWishedChecksValuesList = {
        [1] = FCOIS_CON_NON_WISHED_LEVEL,   -- Level
        [2] = FCOIS_CON_NON_WISHED_QUALITY, -- Quality
        [3] = FCOIS_CON_NON_WISHED_ALL,     -- All
    }

    --Add the normal levels first
    local levelIndex = (#levelList + 1) or 2 -- Add after the "Disabled" entry
    if FCOIS.mappingVars.levels ~= nil then
        for _, level in ipairs(FCOIS.mappingVars.levels) do
            levelList[levelIndex] = tostring(level)
            levelIndex = levelIndex + 1
        end
    end
    --Afterwards add the CP ranks
    if FCOIS.mappingVars.CPlevels ~= nil then
        for _, CPRank in ipairs(FCOIS.mappingVars.CPlevels) do
            levelList[levelIndex] = tostring("CP" .. CPRank)
            levelIndex = levelIndex + 1
        end
    end
    --Globalize the mapping table for the backwards search of the index "levelIndex", which will be
    --saved in the SavedVariables in the variable "FCOIS.settingsVars.settings.autoMarkSetsNonWishedLevel",
    --to get the level value (e.g. 40, or CP120)
    FCOIS.mappingVars.allLevels = levelList


    --Build the dropdown boxes for the armor, weapon and jewelry trait checkboxes
    local armorTraitControls = {}
    local jewelryTraitControls = {}
    local weaponTraitControls = {}
    local weaponShieldTraitControls = {}
    local traitData = {
		[1] = FCOIS.mappingVars.traits.armorTraits,         --Armor
		[2] = FCOIS.mappingVars.traits.jewelryTraits,       --Jewelry
		[3] = FCOIS.mappingVars.traits.weaponTraits,        --Weapons
        [4] = FCOIS.mappingVars.traits.weaponShieldTraits,  --Shields
	}
    local function buildTraitCheckboxes()
        if traitData == nil then return nil end
        --Mapping array for the type to FCOIS settings variable
        local typeToSettings = {
            [1] = FCOISsettings.autoMarkSetsCheckArmorTrait,
            [2] = FCOISsettings.autoMarkSetsCheckJewelryTrait,
            [3] = FCOISsettings.autoMarkSetsCheckWeaponTrait,
            [4] = FCOISsettings.autoMarkSetsCheckWeaponTrait,
        }
        local typeToSettingsDD = {
            [1] = FCOISsettings.autoMarkSetsCheckArmorTraitIcon,
            [2] = FCOISsettings.autoMarkSetsCheckJewelryTraitIcon,
            [3] = FCOISsettings.autoMarkSetsCheckWeaponTraitIcon,
            [4] = FCOISsettings.autoMarkSetsCheckWeaponTraitIcon,
        }
        local typeToTable = {
            [1] = armorTraitControls,
            [2] = jewelryTraitControls,
            [3] = weaponTraitControls,
            [4] = weaponShieldTraitControls,
        }
        --Loop over all trait types
        for traitType, traitTypeData in pairs(traitData) do
            --Loop over each traitTypes's data
            for traitTypeItemTrait, traitTypeName in pairs(traitTypeData) do
                local settingsVar = typeToSettings[traitType][traitTypeItemTrait]
                local ref = tostring(traitType) .. "_" .. tostring(traitTypeName)
                local name = traitTypeName
                local tooltip = traitTypeName
                local data = { type = "checkbox", width = "half" }
                local disabledFunc = function() return not FCOISsettings.autoMarkSets end
                local getFunc
                local setFunc
                local getFuncDD
                local setFuncDD
                local defaultSettings
                local defaultSettingsDD
                local disabledFuncDD
                --Armor
                if traitType == 1 then
                    getFunc = function() return FCOISsettings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait] end
                    getFuncDD = function() return FCOISsettings.autoMarkSetsCheckArmorTraitIcon[traitTypeItemTrait] end
                    setFunc = function(value) FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait] = value
                        if value == true then
                            FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                        end
                    end
                    setFuncDD = function(value) FCOISsettings.autoMarkSetsCheckArmorTraitIcon[traitTypeItemTrait] = value end
                    defaultSettings     = FCOISdefaultSettings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait]
                    defaultSettingsDD   = FCOISdefaultSettings.autoMarkSetsCheckArmorTraitIcon[traitTypeItemTrait]
                    disabledFuncDD = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait] end
                --Jewelry
                elseif traitType == 2 then
                    getFunc = function() return FCOISsettings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait] end
                    getFuncDD = function() return FCOISsettings.autoMarkSetsCheckJewelryTraitIcon[traitTypeItemTrait] end
                    setFunc = function(value) FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait] = value
                        if value == true then
                            FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                        end
                    end
                    setFuncDD = function(value) FCOISsettings.autoMarkSetsCheckJewelryTraitIcon[traitTypeItemTrait] = value end
                    defaultSettings     = FCOISdefaultSettings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait]
                    defaultSettingsDD   = FCOISdefaultSettings.autoMarkSetsCheckJewelryTraitIcon[traitTypeItemTrait]
                    disabledFuncDD = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait] end
                --Weapons or shields
                elseif traitType == 3 or traitType == 4 then
                    getFunc = function() return FCOISsettings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait] end
                    getFuncDD = function() return FCOISsettings.autoMarkSetsCheckWeaponTraitIcon[traitTypeItemTrait] end
                    setFunc = function(value) FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait] = value
                        if value == true then
                            FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                        end
                    end
                    setFuncDD = function(value) FCOISsettings.autoMarkSetsCheckWeaponTraitIcon[traitTypeItemTrait] = value end
                    defaultSettings     = FCOISdefaultSettings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait]
                    defaultSettingsDD   = FCOISdefaultSettings.autoMarkSetsCheckWeaponTraitIcon[traitTypeItemTrait]
                    disabledFuncDD = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait] end
                end
                --Create the dropdownbox now
                local createdTraitCB = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdTraitCB ~= nil then
                    table.insert(typeToTable[traitType], createdTraitCB)
                    --Add an additional dropdownbox for the icon, for each trait
                    local settingsVarDD = typeToSettingsDD[traitType][traitTypeItemTrait]
                    local refDD = ref .. "_DD"
                    local nameDD = traitTypeName .. " " .. locVars["options_icon1_texture"]
                    local tooltipDD = "Icon " .. traitTypeName
                    local createdIconTraitDDBox = CreateDropdownBox(refDD, nameDD, tooltipDD, disabledFuncDD, getFuncDD, setFuncDD, defaultSettingsDD, iconsList, iconsListValues, iconsList, nil, "half", true, true)
                    if createdIconTraitDDBox ~= nil then
                        table.insert(typeToTable[traitType], createdIconTraitDDBox)
                    end
                end
            end -- for traitTypeName, traitTypeItemTrait in pairs(traitTypeData) do
        end -- for traitType, traitTypeData in pairs(traitData) do
    end
    --Build the LAM 2.x checkboxes for the traits now
    buildTraitCheckboxes()

	--Build the dropdown boxes for the icon sort order
	local function buildIconSortOrderDropdowns()
        if numFilterIcons <= 0 then return nil end
		--Get the FCOIS icon count
		--The return array of dropdown boxes for the LAM panel
        local createdIconSortDDBoxes = {}
		--Static values
		--Static dropdown entries
        local choicesTooltipsList = {}
        for FCOISiconNr=1, numFilterIcons, 1 do
			local name = locVars["options_icon_sort_" .. tostring(FCOISiconNr)]
			local tooltip = locVars["options_icon_sort_order_tooltip"]
            if name ~= nil and name ~= "" then
	            local ref = "Icon_Sort_Dropdown_" .. tostring(FCOISiconNr)
				local getFunc = function() return FCOIS.settingsVars.settings.iconSortOrder[FCOISiconNr] end
				local setFunc = function(value)
                    FCOIS.settingsVars.settings.icon[value].sortOrder = FCOISiconNr
                    FCOIS.settingsVars.settings.iconSortOrder[FCOISiconNr] = value
                    --checkAllSortOrderDDBoxesForDuplicates()
                end
				local defSettings = FCOISdefaultSettings.iconSortOrder[FCOISiconNr]
				--Create the dropdownbox now
				local createdIconSortDDBox = CreateDropdownBox(ref, name, tooltip, nil, getFunc, setFunc, defSettings, iconsList, iconsListValues, iconsList, nil, "full", true, true)
				if createdIconSortDDBox ~= nil then
					table.insert(createdIconSortDDBoxes, createdIconSortDDBox)
				end
			end
        end
		return createdIconSortDDBoxes
    end

	--Set the preview icon values (width, height, color, etc.)
	local function InitPreviewIcon(i)
        local iconSettings = FCOISsettings.icon[i]
        local preViewControl = _G[string.format("FCOItemSaver_Settings_Filter%dPreview_Select", i)]
        if preViewControl == nil then return false end
        preViewControl:SetColor(ZO_ColorDef:New(iconSettings.color))
        preViewControl:SetIconSize(iconSettings.size)
        local text = string.format("%s: %s", locVars[string.format("options_icon%d_texture", i)], texturesList[iconSettings.texture])
        preViewControl.label:SetText(text)
    end

--==================== SetTracker - BEGIN ======================================
	--Function to build the SetTracker dropdown boxes
	local function buildSetTrackerDDBoxes()
		if not FCOIS.otherAddons.SetTracker.isActive or not SetTrack or not SetTrack.GetMaxTrackStates then return nil end
		--Get the amount of tracking states
		local STtrackingStates = SetTrack.GetMaxTrackStates()
	    if STtrackingStates == nil or STtrackingStates <= 0 then return false end

		--The return array for the LAM panel
        local createdSetTrackerDDBoxes = {}

		--Static values
        local disabledChecks = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end
		--Static dropdown entries
        local choicesValuesList = {}
        local choicesTooltipsList = {}
        for FCOISiconNr=1, numFilterIcons, 1 do
			local iconDescription = "FCOItemSaver icon " .. tostring(FCOISiconNr)
	        --Add each FCOIS icon description to the list
            choicesTooltipsList[FCOISiconNr] = iconDescription
	        --Add each FCOIS icon number to the list
            choicesValuesList[FCOISiconNr] = FCOISiconNr
        end

        --For each SetTracker tracking state (set) build one label with the description and one dropdown box with the FCOIS icons
        for i=0, (STtrackingStates-1), 1 do
			local ref = "SetTracker_State_" .. tostring(i)
			local name = ""
            local tooltip = ""
            if SetTrack.GetTrackStateInfo then
				local sTrackColour, sTrackName, sTrackTexture = SetTrack.GetTrackStateInfo(i)
				--Concatenate the standard SetTracker prefix string (SI_SETTRK_PREFIX_TRACKSTATE) for a tracked set and the number of the tracking state
                local sTrackNameStandard = GetString(SI_SETTRK_PREFIX_TRACKSTATE) .. tostring(i)
				--Is the name specified for the setTracker state? Otherwise don't add it
                if sTrackName ~= nil and sTrackName ~= "" and sTrackName ~= sTrackNameStandard then
--d(">> build FCOIS SetTracker dropdown boxes: " .. tostring(sTrackName) .. ", sTrackNameStandard: " .. tostring(sTrackNameStandard))
					local alternativeNameText = zo_strformat(locVars["options_auto_mark_settrackersets_to_fcois_icon"], tostring(i+1))
	                name = sTrackName or alternativeNameText or "SetTracker state " .. tostring(i+1)
					tooltip = alternativeNameText
	                --[[
		                if string.len(sTrackName) > 40 then
			                tooltip = locVars["options_auto_mark_settrackersets_to_fcois_icon_tooltip"]
		                else
			                tooltip = sTrackName or locVars["options_auto_mark_settrackersets_to_fcois_icon_tooltip"]
		               	end
	               ]]
				end
            end
			--Is the tracking state name determined?
            if name ~= "" then
	            local getFunc = function() return FCOISsettings.setTrackerIndexToFCOISIcon[i] end
	            local setFunc = function(value) FCOISsettings.setTrackerIndexToFCOISIcon[i] = value end
	            local defaultSettings = FCOISsettings.setTrackerIndexToFCOISIcon[i]
				--Create the dropdownbox now
				local createdSetTrackerDDBox = CreateDropdownBox(ref, name, tooltip, disabledChecks, getFunc, setFunc, defaultSettings, iconsList, choicesValuesList, choicesTooltipsList, nil, "full", true, true)
	            if createdSetTrackerDDBox ~= nil then
		            table.insert(createdSetTrackerDDBoxes, createdSetTrackerDDBox)
	            end
			end
        end
		return createdSetTrackerDDBoxes
    end

	-- Build a LAM SubMenu
	local function LAMSubmenu(subMenu)
		local submenuControls = {}

--------------------------------------------------------------------------------
		if subMenu == "SetTracker" then
--Checkboxes
			local cbAutoMarkSetTracker = {
	            type = "checkbox",
				name = locVars["options_auto_mark_settrackersets"],
				tooltip = locVars["options_auto_mark_settrackersets_tooltip"],
				getFunc = function() return FCOISsettings.autoMarkSetTrackerSets end,
				setFunc = function(value)
					FCOISsettings.autoMarkSetTrackerSets = value
				end,
				width = "half",
				disabled = function() return not FCOIS.otherAddons.SetTracker.isActive end,
				requiresReload = true,
            }
			table.insert(submenuControls, cbAutoMarkSetTracker)
            local cbAutoMarkSetTrackerCheckAllIcons = {
            type = "checkbox",
            name = locVars["options_enable_auto_mark_check_all_icons"],
            tooltip = locVars["options_enable_auto_mark_check_all_icons_tooltip"],
            getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsCheckAllIcons end,
            setFunc = function(value)
                FCOISsettings.autoMarkSetTrackerSetsCheckAllIcons = value
            end,
            width = "half",
            disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
        }
            table.insert(submenuControls, cbAutoMarkSetTrackerCheckAllIcons)
			local cbAutoMarkSetTrackerTooltips = {
				type = "checkbox",
				name = locVars["options_auto_mark_settrackersets_show_tooltip_on_FCOIS_marker"],
				tooltip = locVars["options_auto_mark_settrackersets_show_tooltip_on_FCOIS_marker_tooltip"],
				getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsShowTooltip end,
				setFunc = function(value)
					FCOISsettings.autoMarkSetTrackerSetsShowTooltip = value
				end,
				width = "half",
				disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
			}
			table.insert(submenuControls, cbAutoMarkSetTrackerTooltips)
			local cbAutoMarkSetTrackerInv = {
	            type = "checkbox",
				name = locVars["options_auto_mark_settrackersets_inv"],
				tooltip = locVars["options_auto_mark_settrackersets_inv_tooltip"],
				getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsInv end,
				setFunc = function(value)
					FCOISsettings.autoMarkSetTrackerSetsInv = value
				end,
				width = "half",
				disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
            }
			table.insert(submenuControls, cbAutoMarkSetTrackerInv)
			local cbAutoMarkSetTrackerWorn = {
	            type = "checkbox",
				name = locVars["options_auto_mark_settrackersets_worn"],
				tooltip = locVars["options_auto_mark_settrackersets_worn_tooltip"],
				getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsWorn end,
				setFunc = function(value)
					FCOISsettings.autoMarkSetTrackerSetsWorn = value
				end,
				width = "half",
				disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
            }
			table.insert(submenuControls, cbAutoMarkSetTrackerWorn)
			local cbAutoMarkSetTrackerBank = {
	            type = "checkbox",
				name = locVars["options_auto_mark_settrackersets_bank"],
				tooltip = locVars["options_auto_mark_settrackersets_bank_tooltip"],
				getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsBank end,
				setFunc = function(value)
					FCOISsettings.autoMarkSetTrackerSetsBank = value
				end,
				width = "half",
				disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
            }
			table.insert(submenuControls, cbAutoMarkSetTrackerBank)
			local cbAutoMarkSetTrackerGuildBank = {
	            type = "checkbox",
				name = locVars["options_auto_mark_settrackersets_guildbank"],
				tooltip = locVars["options_auto_mark_settrackersets_guildbank_tooltip"],
				getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsGuildBank end,
				setFunc = function(value)
					FCOISsettings.autoMarkSetTrackerSetsGuildBank = value
				end,
				width = "half",
				disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
            }
			table.insert(submenuControls, cbAutoMarkSetTrackerGuildBank)
			local cbAutoMarkSetTrackerRescan = {
	            type = "checkbox",
				name = locVars["options_auto_mark_settrackersets_rescan"],
				tooltip = locVars["options_auto_mark_settrackersets_rescan_tooltip"],
				getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsRescan end,
				setFunc = function(value)
					FCOISsettings.autoMarkSetTrackerSetsRescan = value
				end,
				width = "half",
				disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
            }
			table.insert(submenuControls, cbAutoMarkSetTrackerRescan)
--Dropdown boxes
            --Is the SetTracker addon active?
            if FCOIS.otherAddons.SetTracker.isActive and SetTrack and SetTrack.GetMaxTrackStates then
				local createdSetTrackerDDBoxes = buildSetTrackerDDBoxes()
		    	--Was the SetTracker submenu build?
		        if createdSetTrackerDDBoxes ~= nil and #createdSetTrackerDDBoxes > 0 then
		        	for _, createdSetTrackerDDBox in pairs(createdSetTrackerDDBoxes) do
						table.insert(submenuControls, createdSetTrackerDDBox)
		            end
		        end
            end
--------------------------------------------------------------------------------
		elseif subMenu == "IconSortOrder" then
            --Add the warning header
            local data = {}
            data.type = "description"
            data.text = locVars["options_icon_sort_order_warning"]
            --Create the dropdownbox now
            local createdIconSortWarningHeader = CreateControl(nil, "", "", data)
            table.insert(submenuControls, createdIconSortWarningHeader)
            --Create the dropdown boxes for the icons
			local createdIconSortOrderDDBoxes = buildIconSortOrderDropdowns()
			--Was the IconSortOrder submenu build?
			if createdIconSortOrderDDBoxes ~= nil and #createdIconSortOrderDDBoxes > 0 then
				for _, createdIconSortOrderDDBox in pairs(createdIconSortOrderDDBoxes) do
					table.insert(submenuControls, createdIconSortOrderDDBox)
				end
			end
		end -- if subMenu == "SetTracker" then
--------------------------------------------------------------------------------
		return submenuControls
	end
	-- Creating LAM optionPanel for the SetTracker addon
	local SetTrackerSubmenuControls = LAMSubmenu("SetTracker")
	-- Creating LAM optionPanel for the FCOIS icon sort order
	local IconSortOrderSubmenuControls = LAMSubmenu("IconSortOrder")
--==================== SetTracker - END ========================================




--==================== Dynamic icons - BEGIN ===================================
    local iconId2FCOISIconNr            = FCOIS.mappingVars.dynamicToIcon
    local iconId2FCOISIconLockDynMenuNr = FCOIS.mappingVars.iconToLockDyn
    local numDynIcons                   = FCOIS.numVars.gFCONumDynamicIcons

    --Build the enable/disable checkboxes submenu for the dynamic icons
    local function buildDynamicIconEnableCheckboxes()
        local dynamicIconsEnabledCbs = {}
        --Create 1 checkbox to enable/disable the dynamic icons for each dynamic icon
        for dynIconId=1, numDynIcons, 1 do
            local fcoisDynIconNr = iconId2FCOISIconNr[dynIconId] --e.g. dynamic icon 1 = FCOIS icon ID 13, 2 = 14, and so on
            local fcoisLockDynMenuIconNr = iconId2FCOISIconLockDynMenuNr[dynIconId] --e.g. dynamic icon 1 = 2, 2 = 3, and so on

            local name = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_activate_text"]
            local tooltip = locVars["options_icon_activate_text_tooltip"]
            local data = { type = "checkbox", width = "half" }
            local disabledFunc = function() return false end
            local getFunc = function() return FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            local setFunc = function(value)
                FCOISsettings.isIconEnabled[fcoisDynIconNr] = value
                if value == true then
                    --Update the color of the dynamic icons's icon picker tetxure again as it was grayed out
                    local ctrl = WINDOW_MANAGER:GetControlByName("FCOItemSaver_Settings_Filter" .. tostring(fcoisDynIconNr) .. "Preview_Select", "")
                    if ctrl ~= nil then
                        local r, g, b, a = FCOISsettings.icon[fcoisDynIconNr].color.r, FCOISsettings.icon[fcoisDynIconNr].color.g, FCOISsettings.icon[fcoisDynIconNr].color.b, FCOISsettings.icon[fcoisDynIconNr].color.a
                        ctrl:SetColor(ZO_ColorDef:New(r,g,b,a))
                    end
                end

            end
            local defaultSettings = FCOISdefaultSettings.isIconEnabled[fcoisDynIconNr]
            --Create the dropdownbox now
            local createdDynIconEnableCB = CreateControl(name, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdDynIconEnableCB ~= nil then
                table.insert(dynamicIconsEnabledCbs, createdDynIconEnableCB)
            end
        end -- for traitTypeName, traitTypeItemTrait in pairs(traitTypeData) do
        return dynamicIconsEnabledCbs
    end
    local dynIconsEnabledCheckboxes = buildDynamicIconEnableCheckboxes()

    --Build the complete submenus for the dynamic icons
    local function buildDynamicIconSubMenus()
        local dynIconsSubMenus = {}
        --[[
        --Each submenu starts with this header...
            {
                type = "submenu",
                name = locVars["options_icon13_color"],
                reference = "FCOIS_OPTIONS_" .. locVars["options_icon13_color"].."_submenu",
                controls =
                {
                ...
                },
            },
        ]]

        --Create 1 checkbox to enable/disable the dynamic icons for each dynamic icon
        for dynIconId=1, numDynIcons, 1 do
            local fcoisDynIconNr = iconId2FCOISIconNr[dynIconId] --e.g. dynamic icon 1 = FCOIS icon ID 13, 2 = 14, and so on
            local fcoisLockDynMenuIconNr = iconId2FCOISIconLockDynMenuNr[dynIconId] --e.g. dynamic icon 1 = 2, 2 = 3, and so on

            --Clear the controls of the submenu
            local dynIconsSubMenusControls = {}

            --Variables
            local name
            local tooltip
            local data = {}
            local disabledFunc, getFunc, setFunc, defaultSettings, createdControl

------------------------------------------------------------------------------------------------------------------------
            --Add the name edit box
--[[
                {
                    type = "editbox",
                    name = locVars["options_icon13_color"],
                    tooltip = "",
                    getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].name end,
                    setFunc = function(newValue)
                        FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].name = newValue
                        FCOIS.changeContextMenuEntryTexts(FCOIS_CON_ICON_DYNAMIC_1)
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
                    end,
                    width = "half",
                    default = locVars["options_icon13_name"],
                    disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                },
]]
            name = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_color"]
            tooltip = ""
            data = { type = "editbox", width = "half" }
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].name end
            setFunc = function(newValue)
                FCOISsettings.icon[fcoisDynIconNr].name = newValue
                FCOIS.changeContextMenuEntryTexts(fcoisDynIconNr)
                --Update the icon list dropdown entries (name, enabled state)
                updateIconListDropdownEntries()
            end
            defaultSettings = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_name"]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end

------------------------------------------------------------------------------------------------------------------------
            --Add the color picker
--[[
                {
                    type = "colorpicker",
                    name = locVars["options_icon13_color"],
                    tooltip = "",
                    getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].color.r, FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].color.g, FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].color.b, FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].color.a end,
                    setFunc = function(r,g,b,a)
                        FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
                        FCOItemSaver_Settings_Filter13Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
                        --Set global variable to update the marker colors and textures
                        FCOIS.preventerVars.gUpdateMarkersNow = true
                    end,
                    width="half",
                    default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].color,
                    disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                },
]]
            name = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_color"]
            tooltip = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_color_tooltip"]
            data = { type = "colorpicker", width = "half" }
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].color.r, FCOISsettings.icon[fcoisDynIconNr].color.g, FCOISsettings.icon[fcoisDynIconNr].color.b, FCOISsettings.icon[fcoisDynIconNr].color.a end
            setFunc = function(r,g,b,a)
                FCOISsettings.icon[fcoisDynIconNr].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
                local ctrl = WINDOW_MANAGER:GetControlByName("FCOItemSaver_Settings_Filter" .. tostring(fcoisDynIconNr) .. "Preview_Select", "")
                if ctrl ~= nil then ctrl:SetColor(ZO_ColorDef:New(r,g,b,a)) end
                --Set global variable to update the marker colors and textures
                FCOIS.preventerVars.gUpdateMarkersNow = true
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].color
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end

------------------------------------------------------------------------------------------------------------------------
            --Add the icon picker
            --[[
                            {
                                type = "iconpicker",
                                name = locVars["options_icon13_texture"],
                                tooltip = locVars["options_icon13_texture_tooltip"],
                                choices = FCOIS.textureVars.MARKER_TEXTURES,
                                choicesTooltips = texturesList,
                                getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].texture] end,
                                setFunc = function(texturePath)
                                    local textureId = GetFCOTextureId(texturePath)
                                    if textureId ~= 0 then
                                        FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].texture = textureId
                                        FCOItemSaver_Settings_Filter13Preview_Select.label:SetText(locVars["options_icon13_texture"] .. ": " .. texturesList[textureId])
                                        local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_LOCKDYN], "")
                                        FCOIS.UpdateButtonColorsAndTextures(1, p_button, -999)
                                        --Set global variable to update the marker colors and textures
                                        FCOIS.preventerVars.gUpdateMarkersNow = true
                                    end
                                end,
                                maxColumns = 6,
                                visibleRows = 5,
                                iconSize = FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].size,
                                width = "half",
                                default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].texture],
                                reference = "FCOItemSaver_Settings_Filter13Preview_Select",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
            ]]
            local ref = "FCOItemSaver_Settings_Filter".. tostring(fcoisDynIconNr) .. "Preview_Select"
            name = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_texture"]
            tooltip = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_texture_tooltip"]
            data = { type = "iconpicker", width = "half", choices = FCOIS.textureVars.MARKER_TEXTURES, choicesTooltips = texturesList, maxColumns=6, visibleRows=5, iconSize=FCOISsettings.icon[fcoisDynIconNr].size}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[fcoisDynIconNr].texture] end
            setFunc = function(texturePath)
                local textureId = GetFCOTextureId(texturePath)
                if textureId ~= 0 then
                    FCOISsettings.icon[fcoisDynIconNr].texture = textureId
                    local ctrl = WINDOW_MANAGER:GetControlByName("FCOItemSaver_Settings_Filter" .. tostring(fcoisDynIconNr) .. "Preview_Select", "")
                    if ctrl ~= nil then ctrl.label:SetText(locVars["options_icon"..tostring(fcoisDynIconNr).."_texture"] .. ": " .. texturesList[textureId]) end
                    local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_LOCKDYN], "")
                    if p_button ~= nil then FCOIS.UpdateButtonColorsAndTextures(1, p_button, -999) end
                    --Set global variable to update the marker colors and textures
                    FCOIS.preventerVars.gUpdateMarkersNow = true
                end
            end
            defaultSettings = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[fcoisDynIconNr].texture]
            createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end

------------------------------------------------------------------------------------------------------------------------
            --Add the size slider
            --[[
                            {
                                type = "slider",
                                name = locVars["options_icon13_size"],
                                tooltip = locVars["options_icon13_size_tooltip"],
                                min = 12,
                                max = 48,
                                decimals = 0,
                                autoSelect = true,
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].size end,
                                setFunc = function(size)
                                    FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].size = size
                                    FCOItemSaver_Settings_Filter13Preview_Select:SetIconSize(size)
                                end,
                                width="half",
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].size,
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
            ]]
            name = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_size"]
            tooltip = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_size_tooltip"]
            data = { type = "slider", width = "half", min=12, max=48, decimals=0, autoselect=true}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].size end
            setFunc = function(size)
                FCOISsettings.icon[fcoisDynIconNr].size = size
                local ctrl = WINDOW_MANAGER:GetControlByName("FCOItemSaver_Settings_Filter" .. tostring(fcoisDynIconNr) .. "Preview_Select", "")
                if ctrl ~= nil then ctrl:SetIconSize(size) end
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].size
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the tooltip checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_icon13_tooltip"],
                                tooltip = locVars["options_icon13_tooltip_tooltip"],
                                getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_DYNAMIC_1] end,
                                setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_DYNAMIC_1] = value
                                    FCOIS.preventerVars.gUpdateMarkersNow = true
                                end,
                                default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_DYNAMIC_1],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_tooltip"]
            tooltip = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_tooltip_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.showMarkerTooltip[fcoisDynIconNr] end
            setFunc = function(value)
                FCOISsettings.showMarkerTooltip[fcoisDynIconNr] = value
                FCOIS.preventerVars.gUpdateMarkersNow = true
            end
            defaultSettings = FCOISdefaultSettings.showMarkerTooltip[fcoisDynIconNr]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the disable research checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_gear_disable_research_check"],
                                tooltip = locVars["options_gear_disable_research_check_tooltip"],
                                getFunc = function() return FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_DYNAMIC_1] end,
                                setFunc = function(value) FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_DYNAMIC_1] = value
                                end,
                                default = FCOISdefaultSettings.disableResearchCheck[FCOIS_CON_ICON_DYNAMIC_1],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },

        ]]
            name = locVars["options_gear_disable_research_check"]
            tooltip = locVars["options_gear_disable_research_check_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.disableResearchCheck[fcoisDynIconNr] end
            setFunc = function(value) FCOISsettings.disableResearchCheck[fcoisDynIconNr] = value
            end
            defaultSettings = FCOISdefaultSettings.disableResearchCheck[fcoisDynIconNr]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the enable as gear checkbox
            name = locVars["options_gear_enable_as_gear"]
            tooltip = locVars["options_gear_enable_as_gear_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.iconIsGear[fcoisDynIconNr] end
            setFunc = function(value)
                FCOISsettings.iconIsGear[fcoisDynIconNr] = value
                --Now rebuild all other gear set values
                FCOIS.rebuildGearSetBaseVars(fcoisDynIconNr, value)
            end
            defaultSettings = FCOISdefaultSettings.iconIsGear[fcoisDynIconNr]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the respect inventory flag icon state
            name = locVars["options_enable_block_marked_disable_with_flag"]
            tooltip = locVars["options_enable_block_marked_disable_with_flag_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].temporaryDisableByInventoryFlagIcon end
            setFunc = function(value)
                FCOISsettings.icon[fcoisDynIconNr].temporaryDisableByInventoryFlagIcon = value
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].temporaryDisableByInventoryFlagIcon
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the anti-destroy header
            --[[
                            --Anti-destroy: Icon 13 (dynamic 1)
                            {
                                type = "header",
                                name = locVars["options_header_anti_destroy"],
                            },
        ]]
            name = locVars["options_header_anti_destroy"]
            data = { type = "header"}
            createdControl = CreateControl(nil, name, nil, data, nil, nil, nil, nil, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block destroy checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_destroying"],
                                tooltip = locVars["options_enable_block_destroying_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_INVENTORY] end,
                                setFunc = function(value)
                                    FCOIS.updateAntiCheckAtPanelVariable(FCOIS_CON_ICON_DYNAMIC_1, LF_INVENTORY, value)
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_INVENTORY],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_destroying"]
            tooltip = locVars["options_enable_block_destroying_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_INVENTORY] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_INVENTORY, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_INVENTORY]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block selling checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_selling"],
                                tooltip = locVars["options_enable_block_selling_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_VENDOR_SELL] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_VENDOR_SELL] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_VENDOR_SELL],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_selling"]
            tooltip = locVars["options_enable_block_selling_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_VENDOR_SELL] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_VENDOR_SELL, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_VENDOR_SELL]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block deconstruction checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_deconstruction"],
                                tooltip = locVars["options_enable_block_deconstruction_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_deconstruction"]
            tooltip = locVars["options_enable_block_deconstruction_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_SMITHING_DECONSTRUCT, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
--Add the block jewelry deconstruction checkbox
--[[
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_deconstruction"],
                    tooltip = locVars["options_enable_block_deconstruction_tooltip"],
                    getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT] end,
                    setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT] = value
                    end,
                    default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT],
                    width="half",
                    disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                },
]]
            name = locVars["options_enable_block_jewelry_deconstruction"]
            tooltip = locVars["options_enable_block_jewelry_deconstruction_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_DECONSTRUCT] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_JEWELRY_DECONSTRUCT, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_DECONSTRUCT]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block improvement checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_improvement"],
                                tooltip = locVars["options_enable_block_improvement_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_improvement"]
            tooltip = locVars["options_enable_block_improvement_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_SMITHING_IMPROVEMENT, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
--Add the block jewelry improvement checkbox
--[[
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_improvement"],
                    tooltip = locVars["options_enable_block_improvement_tooltip"],
                    getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT] end,
                    setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT] = value
                    end,
                    default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT],
                    width="half",
                    disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                },
]]
            name = locVars["options_enable_block_jewelry_improvement"]
            tooltip = locVars["options_enable_block_jewelry_improvement_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_IMPROVEMENT] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_JEWELRY_IMPROVEMENT, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_IMPROVEMENT]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block refinement checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_refinement"],
                                tooltip = locVars["options_enable_block_refinement_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_REFINE] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_REFINE] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_REFINE],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_refinement"]
            tooltip = locVars["options_enable_block_refinement_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_REFINE] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_SMITHING_REFINE, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_REFINE]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
--Add the block jewelry refinement checkbox
--[[
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_refinement"],
                    tooltip = locVars["options_enable_block_refinement_tooltip"],
                    getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_REFINE] end,
                    setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_REFINE] = value
                    end,
                    default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_SMITHING_REFINE],
                    width="half",
                    disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                },
]]
            name = locVars["options_enable_block_jewelry_refinement"]
            tooltip = locVars["options_enable_block_jewelry_refinement_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_REFINE] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_JEWELRY_REFINE, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_REFINE]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block sell in guildstore checkbox
            --[[
        {
                                type = "checkbox",
                                name = locVars["options_enable_block_selling_guild_store"],
                                tooltip = locVars["options_enable_block_selling_guild_store_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_GUILDSTORE_SELL] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_GUILDSTORE_SELL] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_GUILDSTORE_SELL],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_selling_guild_store"]
            tooltip = locVars["options_enable_block_selling_guild_store_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_GUILDSTORE_SELL] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_GUILDSTORE_SELL, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_GUILDSTORE_SELL]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block enchanting creation checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_creation"],
                                tooltip = locVars["options_enable_block_creation_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ENCHANTING_CREATION] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ENCHANTING_CREATION] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ENCHANTING_CREATION],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_creation"]
            tooltip = locVars["options_enable_block_creation_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_CREATION] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_ENCHANTING_CREATION, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_CREATION]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block enchanting extraction checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_extraction"],
                                tooltip = locVars["options_enable_block_extraction_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ENCHANTING_EXTRACTION] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ENCHANTING_EXTRACTION] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ENCHANTING_EXTRACTION],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_extraction"]
            tooltip = locVars["options_enable_block_extraction_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_EXTRACTION] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_ENCHANTING_EXTRACTION, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_EXTRACTION]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block fence selling checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_fence_selling"],
                                tooltip = locVars["options_enable_block_fence_selling_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_FENCE_SELL] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_FENCE_SELL] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_FENCE_SELL],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_fence_selling"]
            tooltip = locVars["options_enable_block_fence_selling_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_SELL] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_FENCE_SELL, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_SELL]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block launder selling checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_launder_selling"],
                                tooltip = locVars["options_enable_block_launder_selling_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_FENCE_LAUNDER] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_FENCE_LAUNDER] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_FENCE_LAUNDER],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_launder_selling"]
            tooltip = locVars["options_enable_block_launder_selling_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_LAUNDER] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_FENCE_LAUNDER, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_LAUNDER]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block trading checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_trading"],
                                tooltip = locVars["options_enable_block_trading_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_TRADE] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_TRADE] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_TRADE],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_trading"]
            tooltip = locVars["options_enable_block_trading_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_TRADE] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_TRADE, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_TRADE]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block send by mail checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_sending_mail"],
                                tooltip = locVars["options_enable_block_sending_mail_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_MAIL_SEND] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_MAIL_SEND] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_MAIL_SEND],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_sending_mail"]
            tooltip = locVars["options_enable_block_sending_mail_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_MAIL_SEND] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_MAIL_SEND, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_MAIL_SEND]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block alchemy destroy checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_alchemy_destroy"],
                                tooltip = locVars["options_enable_block_alchemy_destroy_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ALCHEMY_CREATION] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ALCHEMY_CREATION] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_ALCHEMY_CREATION],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },
        ]]
            name = locVars["options_enable_block_alchemy_destroy"]
            tooltip = locVars["options_enable_block_alchemy_destroy_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ALCHEMY_CREATION] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_ALCHEMY_CREATION, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ALCHEMY_CREATION]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Add the block retrait checkbox
            --[[
                            {
                                type = "checkbox",
                                name = locVars["options_enable_block_retrait"],
                                tooltip = locVars["options_enable_block_retrait_tooltip"],
                                getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_RETRAIT] end,
                                setFunc = function(value) FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_RETRAIT] = value
                                end,
                                default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DYNAMIC_1].antiCheckAtPanel[LF_RETRAIT],
                                width="half",
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DYNAMIC_1] end,
                            },


                        } -- controls icon 13
                    }, -- submenu icon 13
            ]]
            name = locVars["options_enable_block_retrait"]
            tooltip = locVars["options_enable_block_retrait_tooltip"]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not FCOISsettings.isIconEnabled[fcoisDynIconNr] end
            getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_RETRAIT] end
            setFunc = function(value) FCOIS.updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_RETRAIT, value)
            end
            defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_RETRAIT]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(dynIconsSubMenusControls, createdControl)
            end
------------------------------------------------------------------------------------------------------------------------
            --Create the submenu header for the dynamic icon and assign the before build controls to it
            if dynIconsSubMenusControls ~= nil and #dynIconsSubMenusControls > 0 then
                local ref = "FCOIS_OPTIONS_" .. locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_color"].."_submenu"
                name = locVars["options_icon" .. tostring(fcoisDynIconNr) .. "_color"]
                tooltip = ""
                data = { type = "submenu", controls = dynIconsSubMenusControls }
                local createdDynIconSubMenuSurrounding = CreateControl(ref, name, tooltip, data, nil, nil, nil, nil, nil)
                table.insert(dynIconsSubMenus, createdDynIconSubMenuSurrounding)
            end
        end -- for traitTypeName, traitTypeItemTrait in pairs(traitTypeData) do
        return dynIconsSubMenus

    end
    local dynIconsSubMenus = buildDynamicIconSubMenus()
--==================== Dynamic icons - END =====================================


--==================== Restore API versions - BEGIN =====================================
    --Read all restorable API versions from the savedvars to get a table with the API
    --version and date + time when they were created
    local restoreChoices = {}
    local restoreChoicesValues = {}
    function FCOIS.buildRestoreAPIVersionData(doUpdateDropdownValues)
        local foundRestoreData = {}
        local backupData = FCOISsettings.backupData
        if backupData ~= nil then
            restoreChoices = {}
            restoreChoicesValues = {}
            doUpdateDropdownValues = doUpdateDropdownValues or false
            for backupApiVersion, _ in pairs(backupData) do
                local dateInfo = tostring(backupData[backupApiVersion].timestamp) or ""
                local restoreEntry = {}
                restoreEntry.apiVersion = backupApiVersion
                restoreEntry.timestamp  = dateInfo
                table.insert(foundRestoreData, restoreEntry)
                --Build the choices and choices values for the LAM dropdown box of restore api versions
                local tableIndex = #restoreChoices+1
                restoreChoices[tableIndex] = "[" .. tostring(dateInfo) .. "] " .. tostring(backupApiVersion)
                restoreChoicesValues[tableIndex] = tonumber(backupApiVersion)
            end
            --Update the choices and choicesValues in the LAM restore API verison dropdown now
            --> only needed if manually clicked the "refresh restorable backups" button
            if doUpdateDropdownValues then
                local restoreableBackupsDD = WINDOW_MANAGER:GetControlByName("FCOITEMSAVER_SETTINGS_RESTORE_API_VERSION_DROPDOWN", "")
                if restoreableBackupsDD then
                    restoreableBackupsDD:UpdateChoices(restoreChoices, restoreChoicesValues)
                    fcoRestore.apiVersion = nil
                end
            end
        end
        return foundRestoreData
    end
    --Build the dropdown box for the restorable API versions now
    FCOIS.buildRestoreAPIVersionData(false)

--==================== Restore API versions - END =======================================

--==================== LAM controls - BEGIN =====================================
	--LAM 2.0 callback function if the panel was created
    local FCOLAMPanelCreated = function(panel)
        if panel == FCOIS.FCOSettingsPanel then
    --d("[FCOIS] SettingsPanel Created")
            --Update the filterIcon textures etc.
            for i = 1, numFilterIcons do
                InitPreviewIcon(i)
            end
            --Check if the user set ordering of context menu entries (marker icons) is valid, else use the default sorting
            if FCOIS.checkIfUserContextMenuSortOrderValid() == false then
	        	FCOIS.resetUserContextMenuSortOrder()
            end
            CALLBACK_MANAGER:UnregisterCallback("LAM-PanelControlsCreated")
        end
    end

	--The option controls for the LAM 2.0 panel
	local optionsTable =
    {	-- BEGIN OF OPTIONS TABLE

		{
			type = 'description',
			text = locVars["options_description"],
            reference = "FCOItemSaver_LAM_Settings_Description_Header",
		},

--==============================================================================
		{
			type = "submenu",
			name = locVars["options_header1"],
			controls = {
				{
					type = 'dropdown',
					name = locVars["options_language"],
					tooltip = locVars["options_language_tooltip"],
					choices = languageOptions,
		            getFunc = function() return languageOptions[FCOIS.settingsVars.defaultSettings.language] end,
		            setFunc = function(value)
		                for i,v in pairs(languageOptions) do
		                    if v == value then
		                        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Settings language] v: " .. tostring(v) .. ", i: " .. tostring(i), false) end
		                    	FCOIS.settingsVars.defaultSettings.language = i
		                        --Tell the FCOISsettings that you have manually chosen the language and want to keep it
		                        --Read in function Localization() after ReloadUI()
		                        FCOISsettings.languageChosen = true
								--locVars			  	 = locVars[i]
		                        --ReloadUI()
		                    end
		                end
		            end,
                    disabled = function() return FCOISsettings.alwaysUseClientLanguage end,
		            warning = locVars["options_language_description1"],
                    requiresReload = true,
				},
				{
					type = "checkbox",
					name = locVars["options_language_use_client"],
					tooltip = locVars["options_language_use_client_tooltip"],
					getFunc = function() return FCOISsettings.alwaysUseClientLanguage end,
					setFunc = function(value)
						FCOISsettings.alwaysUseClientLanguage = value
                        --ReloadUI()
  		            end,
		            default = FCOISdefaultSettings.alwaysUseClientLanguage,
		            warning = locVars["options_language_description1"],
                    requiresReload = true,
				},

				{
					type = 'dropdown',
					name = locVars["options_savedvariables"],
					tooltip = locVars["options_savedvariables_tooltip"],
					choices = savedVariablesOptions,
		            getFunc = function() return savedVariablesOptions[FCOIS.settingsVars.defaultSettings.saveMode] end,
		            setFunc = function(value)
		                for i,v in pairs(savedVariablesOptions) do
		                    if v == value then
		                        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Settings save mode] v: " .. tostring(v) .. ", i: " .. tostring(i), false) end
		                        FCOIS.settingsVars.defaultSettings.saveMode = i
		                        --ReloadUI()
		                    end
		                end
		            end,
		            warning = locVars["options_language_description1"],
                    requiresReload = true,
				},

--Copy savedvars from server to server
                {
                    type = 'header',
                    name = locVars["options_header_copy_sv"],
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_source_server"],
                    tooltip = locVars["options_copy_sv_source_server"],
                    choices = serverOptions,
                    choicesValues = serverOptionsValues,
                    getFunc = function() return srcServer end,
                    setFunc = function(value)
                        srcServer = value
                    end,
                    width = "half",
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_target_server"],
                    tooltip = locVars["options_copy_sv_target_server"],
                    choices = serverOptionsTarget,
                    choicesValues = serverOptionsValuesTarget,
                    getFunc = function() return targServer end,
                    setFunc = function(value)
                        targServer = value
                    end,
                    width = "half",
                },
                {
                    type = "button",
                    name = locVars["options_copy_sv_to_server"],
                    tooltip = locVars["options_copy_sv_to_server_tooltip"],
                    func = function()
                        FCOIS.copySavedVarsFromServerToServer(srcServer, targServer, false)
                        reBuildServerOptions()
                    end,
                    isDangerous = true,
                    disabled = function() return (FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound) or (srcServer == 1 or targServer == 1 or srcServer == targServer) end,
                    warning = locVars["options_copy_sv_to_server_warning"],
                    width="half",
                },

                {
                    type = "button",
                    name = locVars["options_delete_sv_on_server"],
                    tooltip = locVars["options_delete_sv_on_server_tooltip"],
                    func = function()
                        FCOIS.copySavedVarsFromServerToServer(srcServer, targServer, true)
                        reBuildServerOptions()
                    end,
                    isDangerous = true,
                    disabled = function()
                        local targetServerName = mapServerNames[targServer]
                        if (FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound)
                            or (targServer == 1 or targetServerName == FCOIS.worldName)
                            or (targServer ~= 1 and FCOItemSaver_Settings[targetServerName] == nil)
                        then
                            return true
                        end
                        return false
                    end,
                    warning = locVars["options_delete_sv_on_server_tooltip"],
                    width="half",
                },

--Unique ID switch
				{
					type = 'header',
					name = locVars["options_header_uniqueids"],
				},
				{
					type = "checkbox",
					name = locVars["options_use_uniqueids"],
					tooltip = locVars["options_use_uniqueids_tooltip"],
					getFunc = function() return FCOISsettings.useUniqueIds end,
					setFunc = function(value)
						FCOISsettings.useUniqueIdsToggle = value
					end,
					default = FCOISdefaultSettings.useUniqueIds,
                    warning = locVars["options_description_uniqueids"],
                    requiresReload = true,
				},
                --Migrate the item markers from itemInstanceid to UniqueId
                {
                    type = "button",
                    name = locVars["options_migrate_uniqueids"],
                    tooltip = locVars["options_migrate_uniqueids_tooltip"],
                    func = function()
                        FCOIS.migrateItemInstanceIdMarkersToUniqueIdMarkers()
                    end,
                    isDangerous = true,
                    disabled = function() return not FCOISsettings.useUniqueIds end,
                    warning = locVars["options_migrate_uniqueids_warning"],
                    width="half",
                },
                --ReloadUI button
                {
                    type = "button",
                    name = "Reload UI",
                    tooltip = "Reload UI",
                    func = function()
                        ReloadUI()
                    end,
                    isDangerous = true,
                    disabled = function()
                        if FCOISsettings.useUniqueIdsToggle == nil then return true end
                        if FCOISsettings.useUniqueIdsToggle then
                            if FCOISsettings.useUniqueIds then
                                --Disable the ReloadUI button if the unique IDs should be used, and they are already enabled
                                return true
                            else
                                --Enable the ReloadUI button if the unique IDs should be used, and they are not already enabled
                                return false
                            end
                        else
                            if FCOISsettings.useUniqueIds then
                                --Enable the ReloadUI button if the unique IDs should not be used, and they are already enabled
                                return false
                            else
                                --Disable the ReloadUI button if the unique IDs should not be used, and they are not already enabled
                                return true
                            end
                        end
                    end,
                    width="half",
                },

                {
                    type = 'header',
                    name = locVars["options_header_ZOsLock"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_use_ZOs_lock_functions"],
                    tooltip = locVars["options_use_ZOs_lock_functions_tooltip"],
                    getFunc = function() return FCOISsettings.useZOsLockFunctions end,
                    setFunc = function(value) FCOISsettings.useZOsLockFunctions = value
                    end,
                    default = FCOISdefaultSettings.useZOsLockFunctions,
                    width="half",
                },
                {
                    type = "button",
                    name = locVars["options_scan_ZOs_lock_functions"],
                    tooltip = locVars["options_scan_ZOs_lock_functions_tooltip"],
                    func = function() FCOIS.scanInventoriesForZOsLockedItems(true)
                    end,
                    isDangerous = true,
                    disabled = function() return FCOISsettings.useZOsLockFunctions end,
                    warning = locVars["options_scan_ZOs_lock_functions_warning"],
                    width="half",
                },
            } -- controls submenu general options
		}, -- submenu general options
--==============================================================================
-- vvv OTHER ICONS vvv
--==============================================================================
		{
			type = "submenu",
			name = locVars["options_header_color"],
			controls = {
--==============================================================================
		{
			type = "submenu",
			name = locVars["options_icons_non_gear"],
			controls =
			{
--==============================================================================
                {
	            	type = "submenu",
					name = locVars["options_icon1_color"],
					reference = "FCOIS_OPTIONS_" .. locVars["options_icon1_color"].."_submenu",
					controls =
					{
						{
							type = "colorpicker",
							name = locVars["options_icon1_color"],
							tooltip = locVars["options_icon1_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_LOCK].color.r, FCOISsettings.icon[FCOIS_CON_ICON_LOCK].color.g, FCOISsettings.icon[FCOIS_CON_ICON_LOCK].color.b, FCOISsettings.icon[FCOIS_CON_ICON_LOCK].color.a end,
				            setFunc = function(r,g,b,a)
				            	FCOISsettings.icon[FCOIS_CON_ICON_LOCK].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter1Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width="half",
				            default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_LOCK].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_LOCK] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon1_texture"],
						    tooltip = locVars["options_icon1_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_LOCK].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_LOCK].texture = textureId
									FCOItemSaver_Settings_Filter1Preview_Select.label:SetText(locVars["options_icon1_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_LOCKDYN], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_LOCK, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_LOCK].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_LOCK].texture],
						    reference = "FCOItemSaver_Settings_Filter1Preview_Select",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_LOCK] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon1_tooltip"],
							tooltip = locVars["options_icon1_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_LOCK] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_LOCK] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_LOCK],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_LOCK] end,
						},
				 		{
							type = "slider",
							name = locVars["options_icon1_size"],
							tooltip = locVars["options_icon1_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_LOCK].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_LOCK].size = size
									FCOItemSaver_Settings_Filter1Preview_Select:SetIconSize(size)
				 				end,
				            width="half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_LOCK].size,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_LOCK] end,
						},
					} -- controls icon 1
	        	}, -- submenu icon 1
--==============================================================================
                {
					type = "submenu",
					name = locVars["options_icon3_color"],
					reference = "FCOIS_OPTIONS_" .. locVars["options_icon3_color"].."_submenu",
					controls =
					{
						{
							type = "colorpicker",
							name = locVars["options_icon3_color"],
							tooltip = locVars["options_icon3_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].color.r, FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].color.g, FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].color.b, FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter3Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_RESEARCH].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon3_texture"],
						    tooltip = locVars["options_icon3_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].texture = textureId
									FCOItemSaver_Settings_Filter3Preview_Select.label:SetText(locVars["options_icon3_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_RESDECIMP], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_RESEARCH, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].texture],
						    reference = "FCOItemSaver_Settings_Filter3Preview_Select",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon3_tooltip"],
							tooltip = locVars["options_icon3_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_RESEARCH] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_RESEARCH] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_RESEARCH],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
						},
						{
							type = "slider",
							name = locVars["options_icon3_size"],
							tooltip = locVars["options_icon3_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_RESEARCH].size = size
				                    FCOItemSaver_Settings_Filter3Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_RESEARCH].size,
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
						},
		            } -- controls icon 3
				}, -- submenu icon 3
--==============================================================================
                {
					type = "submenu",
					name = locVars["options_icon5_color"],
					reference = "FCOIS_OPTIONS_" .. locVars["options_icon5_color"].."_submenu",
					controls =
					{
						{
							type = "colorpicker",
							name = locVars["options_icon5_color"],
							tooltip = locVars["options_icon5_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_SELL].color.r, FCOISsettings.icon[FCOIS_CON_ICON_SELL].color.g, FCOISsettings.icon[FCOIS_CON_ICON_SELL].color.b, FCOISsettings.icon[FCOIS_CON_ICON_SELL].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_SELL].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter5Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_SELL].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon5_texture"],
						    tooltip = locVars["options_icon5_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_SELL].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_SELL].texture = textureId
									FCOItemSaver_Settings_Filter5Preview_Select.label:SetText(locVars["options_icon5_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_SELL, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_SELL].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_SELL].texture],
						    reference = "FCOItemSaver_Settings_Filter5Preview_Select",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon5_tooltip"],
							tooltip = locVars["options_icon5_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_SELL] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_SELL] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_SELL],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
						},
						{
							type = "slider",
							name = locVars["options_icon5_size"],
							tooltip = locVars["options_icon5_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_SELL].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_SELL].size = size
				                    FCOItemSaver_Settings_Filter5Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_SELL].size,
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
						},
		            } -- controls icon 5
				}, -- submenu icon 5
--==============================================================================
                {
					type = "submenu",
					name = locVars["options_icon9_color"],
					reference = "FCOIS_OPTIONS_" .. locVars["options_icon9_color"].."_submenu",
					controls =
					{
						{
							type = "colorpicker",
							name = locVars["options_icon9_color"],
							tooltip = locVars["options_icon9_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].color.r, FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].color.g, FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].color.b, FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter9Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DECONSTRUCTION] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon9_texture"],
						    tooltip = locVars["options_icon9_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].texture = textureId
									FCOItemSaver_Settings_Filter9Preview_Select.label:SetText(locVars["options_icon9_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_RESDECIMP], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_DECONSTRUCTION, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].texture],
						    reference = "FCOItemSaver_Settings_Filter9Preview_Select",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DECONSTRUCTION] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon9_tooltip"],
							tooltip = locVars["options_icon9_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_DECONSTRUCTION] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_DECONSTRUCTION] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_DECONSTRUCTION],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DECONSTRUCTION] end,
						},
						{
							type = "slider",
							name = locVars["options_icon9_size"],
							tooltip = locVars["options_icon9_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].size = size
				                    FCOItemSaver_Settings_Filter9Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_DECONSTRUCTION].size,
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DECONSTRUCTION] end,
						},
		            } -- controls icon 9
				}, -- submenu icon 9
--==============================================================================
                {
					type = "submenu",
					name = locVars["options_icon10_color"],
					reference = "FCOIS_OPTIONS_" .. locVars["options_icon10_color"].."_submenu",
					controls =
					{
						{
							type = "colorpicker",
							name = locVars["options_icon10_color"],
							tooltip = locVars["options_icon10_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].color.r, FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].color.g, FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].color.b, FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter10Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_IMPROVEMENT].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_IMPROVEMENT] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon10_texture"],
						    tooltip = locVars["options_icon10_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].texture = textureId
									FCOItemSaver_Settings_Filter10Preview_Select.label:SetText(locVars["options_icon10_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_RESDECIMP], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_IMPROVEMENT, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].texture],
						    reference = "FCOItemSaver_Settings_Filter10Preview_Select",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_IMPROVEMENT] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon10_tooltip"],
							tooltip = locVars["options_icon10_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_IMPROVEMENT] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_IMPROVEMENT] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_IMPROVEMENT],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_IMPROVEMENT] end,
						},
						{
							type = "slider",
							name = locVars["options_icon10_size"],
							tooltip = locVars["options_icon10_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_IMPROVEMENT].size = size
				                    FCOItemSaver_Settings_Filter10Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_IMPROVEMENT].size,
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_IMPROVEMENT] end,
						},
		            } -- controls icon 10
				}, -- submenu icon 10
--==============================================================================
                {
					type = "submenu",
					name = locVars["options_icon11_color"],
					reference = "FCOIS_OPTIONS_" .. locVars["options_icon11_color"].."_submenu",
					controls =
					{
				        {
				            type = "colorpicker",
				            name = locVars["options_icon11_color"],
				            tooltip = locVars["options_icon11_color_tooltip"],
				            getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color.r, FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color.g, FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color.b, FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color.a end,
				            setFunc = function(r,g,b,a)
				                FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter11Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
				                --Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            width = "half",
				            default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
				        },
						{
						    type = "iconpicker",
						    name = locVars["options_icon11_texture"],
						    tooltip = locVars["options_icon11_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].texture = textureId
									FCOItemSaver_Settings_Filter11Preview_Select.label:SetText(locVars["options_icon11_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].texture],
						    reference = "FCOItemSaver_Settings_Filter11Preview_Select",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
						},
				        {
				            type = "checkbox",
				            name = locVars["options_icon11_tooltip"],
				            tooltip = locVars["options_icon11_tooltip_tooltip"],
				            getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
				            setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_SELL_AT_GUILDSTORE],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
				        },
				        {
				            type = "slider",
				            name = locVars["options_icon11_size"],
				            tooltip = locVars["options_icon11_size_tooltip"],
				            min = 12,
				            max = 48,
                            decimals = 0,
                            autoSelect = true,
				            getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].size end,
				            setFunc = function(size)
				                FCOISsettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].size = size
				                FCOItemSaver_Settings_Filter11Preview_Select:SetIconSize(size)
				                --Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].size,
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
				        },
                        {
                            type = "checkbox",
                            name = locVars["options_icon11_only_unbound"],
                            tooltip = locVars["options_icon11_only_unbound_tooltip"],
                            getFunc = function() return FCOISsettings.allowOnlyUnbound[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
                            setFunc = function(value) FCOISsettings.allowOnlyUnbound[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = value
                            end,
                            default = FCOISdefaultSettings.allowOnlyUnbound[FCOIS_CON_ICON_SELL_AT_GUILDSTORE],
                            width="half",
                            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
                        },
		            } -- controls icon 11
				}, -- submenu icon 11
--==============================================================================
                {
					type = "submenu",
					name = locVars["options_icon12_color"],
					reference = "FCOIS_OPTIONS_" .. locVars["options_icon12_color"].."_submenu",
					controls =
					{
				        {
				            type = "colorpicker",
				            name = locVars["options_icon12_color"],
				            tooltip = locVars["options_icon12_color_tooltip"],
				            getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].color.r, FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].color.g, FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].color.b, FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].color.a end,
				            setFunc = function(r,g,b,a)
				                FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter12Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
				                --Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            width = "half",
				            default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_INTRICATE].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
				        },
						{
						    type = "iconpicker",
						    name = locVars["options_icon12_texture"],
						    tooltip = locVars["options_icon12_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].texture = textureId
									FCOItemSaver_Settings_Filter12Preview_Select.label:SetText(locVars["options_icon12_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_INTRICATE, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].texture],
						    reference = "FCOItemSaver_Settings_Filter12Preview_Select",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
						},
				        {
				            type = "checkbox",
				            name = locVars["options_icon12_tooltip"],
				            tooltip = locVars["options_icon12_tooltip_tooltip"],
				            getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_INTRICATE] end,
				            setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_INTRICATE] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_INTRICATE],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
				        },
				        {
				            type = "slider",
				            name = locVars["options_icon12_size"],
				            tooltip = locVars["options_icon12_size_tooltip"],
				            min = 12,
				            max = 48,
                            decimals = 0,
                            autoSelect = true,
				            getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].size end,
				            setFunc = function(size)
				                FCOISsettings.icon[FCOIS_CON_ICON_INTRICATE].size = size
				                FCOItemSaver_Settings_Filter12Preview_Select:SetIconSize(size)
				                --Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_INTRICATE].size,
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
				        },
		            } -- controls icon 12
				}, -- submenu icon 12
--==============================================================================
-- NORMAL ICONS enabled/disabled
				{
					type = "checkbox",
					name = locVars["options_icon1_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS_CON_ICON_LOCK] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS_CON_ICON_LOCK] = value
		            	FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            default = FCOISdefaultSettings.isIconEnabled[FCOIS_CON_ICON_LOCK],
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon3_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] = value
		            	FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            default = FCOISdefaultSettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH],
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon5_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] = value
		            	FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            default = FCOISdefaultSettings.isIconEnabled[FCOIS_CON_ICON_SELL],
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon9_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DECONSTRUCTION] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS_CON_ICON_DECONSTRUCTION] = value
		            	FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            default = FCOISdefaultSettings.isIconEnabled[FCOIS_CON_ICON_DECONSTRUCTION],
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon10_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS_CON_ICON_IMPROVEMENT] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS_CON_ICON_IMPROVEMENT] = value
		            	FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            default = FCOISdefaultSettings.isIconEnabled[FCOIS_CON_ICON_IMPROVEMENT],
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon11_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = value
		            	FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            default = FCOISdefaultSettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE],
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon12_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] = value
		            	FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            default = FCOISdefaultSettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE],
		            width="full",
				},
			} -- controls normal icons
		}, -- submenu normal icons
--==============================================================================
-- ^^^ OTHER ICONS ^^^
--
-- vvv GEAR SETS vvv
--==============================================================================
		{
			type = "submenu",
			name = locVars["options_icons_gears"],
			controls =
            {
				{
					type = "submenu",
					name = locVars["options_icons_gear1"],
					controls =
			   		{
				   		{
							type = "editbox",
							name = locVars["options_icon2_name"],
							tooltip = locVars["options_icon2_name_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].name end,
							setFunc = function(newValue)
				            	FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].name = newValue
								FCOIS.changeContextMenuEntryTexts(FCOIS_CON_ICON_GEAR_1)
                                --Update the icon list dropdown entries (name, enabled state)
                                updateIconListDropdownEntries()
				            end,
							width = "half",
							default = locVars["options_icon2_name"],
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] end,
						},
						{
							type = "colorpicker",
							name = locVars["options_icon2_color"],
							tooltip = locVars["options_icon2_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].color.r, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].color.g, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].color.b, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter2Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_1].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon2_texture"],
						    tooltip = locVars["options_icon2_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].texture = textureId
									FCOItemSaver_Settings_Filter2Preview_Select.label:SetText(locVars["options_icon2_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_GEAR_1, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].texture],
						    reference = "FCOItemSaver_Settings_Filter2Preview_Select",
							disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] end,
						},
						{
							type = "slider",
							name = locVars["options_icon2_size"],
							tooltip = locVars["options_icon2_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_1].size = size
				                    FCOItemSaver_Settings_Filter2Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_1].size,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon2_tooltip"],
							tooltip = locVars["options_icon2_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_1] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_1] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_1],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_gear_disable_research_check"],
							tooltip = locVars["options_gear_disable_research_check_tooltip"],
							getFunc = function() return FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_1] end,
							setFunc = function(value) FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_1] = value
				            end,
				            default = FCOISdefaultSettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_1],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] end,
						},
					} -- controls gear 1
		        }, -- submenu gear 1

		--==============================================================================
				{
					type = "submenu",
					name = locVars["options_icons_gear2"],
					controls =
			   		{
				   		{
							type = "editbox",
							name = locVars["options_icon4_name"],
							tooltip = locVars["options_icon4_name_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].name end,
							setFunc = function(newValue)
				            	FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].name = newValue
								FCOIS.changeContextMenuEntryTexts(FCOIS_CON_ICON_GEAR_2)
                                --Update the icon list dropdown entries (name, enabled state)
                                updateIconListDropdownEntries()
							end,
							width = "half",
							default = locVars["options_icon4_name"],
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] end,
						},
						{
							type = "colorpicker",
							name = locVars["options_icon4_color"],
							tooltip = locVars["options_icon4_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].color.r, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].color.g, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].color.b, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter4Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_2].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon4_texture"],
						    tooltip = locVars["options_icon4_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].texture = textureId
									FCOItemSaver_Settings_Filter4Preview_Select.label:SetText(locVars["options_icon4_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_GEAR_2, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].texture],
						    reference = "FCOItemSaver_Settings_Filter4Preview_Select",
							disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] end,
						},
						{
							type = "slider",
							name = locVars["options_icon4_size"],
							tooltip = locVars["options_icon4_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_2].size = size
				                    FCOItemSaver_Settings_Filter4Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_2].size,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon4_tooltip"],
							tooltip = locVars["options_icon4_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_2] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_2] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_2],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_gear_disable_research_check"],
							tooltip = locVars["options_gear_disable_research_check_tooltip"],
							getFunc = function() return FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_2] end,
							setFunc = function(value) FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_2] = value
				            end,
				            default = FCOISdefaultSettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_2],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] end,
						},
					} -- controls gear 2
		        }, -- submenu gear 2

		--==============================================================================
				{
					type = "submenu",
					name = locVars["options_icons_gear3"],
					controls =
			   		{
				   		{
							type = "editbox",
							name = locVars["options_icon6_name"],
							tooltip = locVars["options_icon6_name_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].name end,
							setFunc = function(newValue)
				            	FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].name = newValue
								FCOIS.changeContextMenuEntryTexts(FCOIS_CON_ICON_GEAR_3)
                                --Update the icon list dropdown entries (name, enabled state)
                                updateIconListDropdownEntries()
							end,
							width = "half",
							default = locVars["options_icon6_name"],
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] end,
						},
						{
							type = "colorpicker",
							name = locVars["options_icon6_color"],
							tooltip = locVars["options_icon6_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].color.r, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].color.g, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].color.b, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter6Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_3].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon6_texture"],
						    tooltip = locVars["options_icon6_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].texture = textureId
									FCOItemSaver_Settings_Filter6Preview_Select.label:SetText(locVars["options_icon6_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_GEAR_3, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].texture],
						    reference = "FCOItemSaver_Settings_Filter6Preview_Select",
							disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] end,
						},
						{
							type = "slider",
							name = locVars["options_icon6_size"],
							tooltip = locVars["options_icon6_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_3].size = size
				                    FCOItemSaver_Settings_Filter6Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_3].size,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon6_tooltip"],
							tooltip = locVars["options_icon6_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_3] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_3] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_3],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_gear_disable_research_check"],
							tooltip = locVars["options_gear_disable_research_check_tooltip"],
							getFunc = function() return FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_3] end,
							setFunc = function(value) FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_3] = value
				            end,
				            default = FCOISdefaultSettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_3],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] end,
						},
					} -- controls gear 3
		        }, -- submenu gear 3
		--==============================================================================
				{
					type = "submenu",
					name = locVars["options_icons_gear4"],
					controls =
			   		{
				   		{
							type = "editbox",
							name = locVars["options_icon7_name"],
							tooltip = locVars["options_icon7_name_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].name end,
							setFunc = function(newValue)
				            	FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].name = newValue
								FCOIS.changeContextMenuEntryTexts(FCOIS_CON_ICON_GEAR_4)
                                --Update the icon list dropdown entries (name, enabled state)
                                updateIconListDropdownEntries()
							end,
							width = "half",
							default = locVars["options_icon7_name"],
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] end,
						},
						{
							type = "colorpicker",
							name = locVars["options_icon7_color"],
							tooltip = locVars["options_icon7_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].color.r, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].color.g, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].color.b, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter7Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_4].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon7_texture"],
						    tooltip = locVars["options_icon7_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].texture = textureId
									FCOItemSaver_Settings_Filter7Preview_Select.label:SetText(locVars["options_icon7_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_GEAR_4, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].texture],
						    reference = "FCOItemSaver_Settings_Filter7Preview_Select",
							disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] end,
						},
						{
							type = "slider",
							name = locVars["options_icon7_size"],
							tooltip = locVars["options_icon7_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_4].size = size
				                    FCOItemSaver_Settings_Filter7Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_4].size,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon7_tooltip"],
							tooltip = locVars["options_icon7_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_4] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_4] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_4],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_gear_disable_research_check"],
							tooltip = locVars["options_gear_disable_research_check_tooltip"],
							getFunc = function() return FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_4] end,
							setFunc = function(value) FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_4] = value
				            end,
				            default = FCOISdefaultSettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_4],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] end,
						},
					} -- controls gear 4
		        }, -- submenu gear 4
		--==============================================================================
				{
					type = "submenu",
					name = locVars["options_icons_gear5"],
					controls =
		            {
				   		{
							type = "editbox",
							name = locVars["options_icon8_name"],
							tooltip = locVars["options_icon8_name_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].name end,
							setFunc = function(newValue)
				            	FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].name = newValue
								FCOIS.changeContextMenuEntryTexts(FCOIS_CON_ICON_GEAR_5)
                                --Update the icon list dropdown entries (name, enabled state)
                                updateIconListDropdownEntries()
							end,
							width = "half",
							default = locVars["options_icon8_name"],
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] end,
						},
						{
							type = "colorpicker",
							name = locVars["options_icon8_color"],
							tooltip = locVars["options_icon8_color_tooltip"],
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].color.r, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].color.g, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].color.b, FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].color.a end,
							setFunc = function(r,g,b,a)
								FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
				                FCOItemSaver_Settings_Filter8Preview_Select:SetColor(ZO_ColorDef:New(r,g,b,a))
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_5].color,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] end,
						},
						{
						    type = "iconpicker",
						    name = locVars["options_icon8_texture"],
						    tooltip = locVars["options_icon8_texture_tooltip"],
						    choices = FCOIS.textureVars.MARKER_TEXTURES,
							choicesTooltips = texturesList,
						    getFunc = function() return FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].texture] end,
						    setFunc = function(texturePath)
						        local textureId = GetFCOTextureId(texturePath)
								if textureId ~= 0 then
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].texture = textureId
									FCOItemSaver_Settings_Filter8Preview_Select.label:SetText(locVars["options_icon8_texture"] .. ": " .. texturesList[textureId])
									local p_button = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS], "")
									FCOIS.UpdateButtonColorsAndTextures(FCOIS_CON_ICON_GEAR_5, p_button, -999)
									--Set global variable to update the marker colors and textures
									FCOIS.preventerVars.gUpdateMarkersNow = true
						        end
						    end,
						   	maxColumns = 6,
						    visibleRows = 5,
						    iconSize = FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].size,
						    width = "half",
						    default = FCOIS.textureVars.MARKER_TEXTURES[FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].texture],
						    reference = "FCOItemSaver_Settings_Filter8Preview_Select",
							disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] end,
						},
						{
							type = "slider",
							name = locVars["options_icon8_size"],
							tooltip = locVars["options_icon8_size_tooltip"],
							min = 12,
							max = 48,
                            decimals = 0,
                            autoSelect = true,
							getFunc = function() return FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].size end,
							setFunc = function(size)
									FCOISsettings.icon[FCOIS_CON_ICON_GEAR_5].size = size
				                    FCOItemSaver_Settings_Filter8Preview_Select:SetIconSize(size)
									--Set global variable to update the marker colors and textures
					                FCOIS.preventerVars.gUpdateMarkersNow = true
								end,
				            width = "half",
							default = FCOISdefaultSettings.icon[FCOIS_CON_ICON_GEAR_5].size,
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_icon8_tooltip"],
							tooltip = locVars["options_icon8_tooltip_tooltip"],
							getFunc = function() return FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_5] end,
							setFunc = function(value) FCOISsettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_5] = value
				            	FCOIS.preventerVars.gUpdateMarkersNow = true
				            end,
				            default = FCOISdefaultSettings.showMarkerTooltip[FCOIS_CON_ICON_GEAR_5],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] end,
						},
						{
							type = "checkbox",
							name = locVars["options_gear_disable_research_check"],
							tooltip = locVars["options_gear_disable_research_check_tooltip"],
							getFunc = function() return FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_5] end,
							setFunc = function(value) FCOISsettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_5] = value
				            end,
				            default = FCOISdefaultSettings.disableResearchCheck[FCOIS_CON_ICON_GEAR_5],
				            width="half",
				            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] end,
						},
			        } -- controls gear 5
			    }, -- submenu gear 5
--==============================================================================
-- GEAR SETS enabled/disabled

				{
					type = "checkbox",
					name = locVars["options_icon2_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] end,
					setFunc = function(value)
		            	FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] = value
						--Hide the textures for gear 1
		            	if not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[1]] then
		                    --Character equipment
		                	FCOIS.RefreshEquipmentControl(nil, false, 2)
		                    FCOIS.FilterBasics(true)
		                else
		                    --Character equipment, create if not yet created
		                	FCOIS.RefreshEquipmentControl(nil, true, 2)
		                    FCOIS.FilterBasics(true)
		                end
		                FCOIS.preventerVars.gChangedGears 	= true
		                FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon4_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] = value
						--Hide the textures for gear 2
		            	if not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[2]] then
		                    --Character equipment
		                	FCOIS.RefreshEquipmentControl(nil, false, 4)
		                    FCOIS.FilterBasics(true)
		                else
		                    --Character equipment, create if not yet created
		                	FCOIS.RefreshEquipmentControl(nil, true, 4)
		                    FCOIS.FilterBasics(true)
		                end
		                FCOIS.preventerVars.gChangedGears 	= true
		                FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            width="full",
				},
				{
					type = "checkbox",
					name = locVars["options_icon6_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] = value
						--Hide the textures for gear 3
		            	if not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[3]] then
		                    --Character equipment
		                	FCOIS.RefreshEquipmentControl(nil, false, 6)
		                    FCOIS.FilterBasics(true)
		                else
		                    --Character equipment, create if not yet created
		                	FCOIS.RefreshEquipmentControl(nil, true, 6)
		                    FCOIS.FilterBasics(true)
		                end
		                FCOIS.preventerVars.gChangedGears 	= true
		                FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            width="full",
				},
		        {
					type = "checkbox",
					name = locVars["options_icon7_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] = value
						--Hide the textures for gear 4
		            	if not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[4]] then
		                    --Character equipment
		                	FCOIS.RefreshEquipmentControl(nil, false, 7)
		                    FCOIS.FilterBasics(true)
		                else
		                    --Character equipment, create if not yet created
		                	FCOIS.RefreshEquipmentControl(nil, true, 7)
		                    FCOIS.FilterBasics(true)
		                end
		                FCOIS.preventerVars.gChangedGears 	= true
		                FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            width="full",
				},
		        {
					type = "checkbox",
					name = locVars["options_icon8_activate_text"],
					tooltip = locVars["options_icon_activate_text_tooltip"],
					getFunc = function() return FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] end,
					setFunc = function(value) FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] = value
						--Hide the textures for gear 5
		            	if not FCOISsettings.isIconEnabled[FCOIS.mappingVars.gearToIcon[5]] then
		                    --Character equipment
		                	FCOIS.RefreshEquipmentControl(nil, false, 8)
		                    FCOIS.FilterBasics(true)
		                else
		                    --Character equipment, create if not yet created
		                	FCOIS.RefreshEquipmentControl(nil, true, 8)
		                    FCOIS.FilterBasics(true)
		                end
		                FCOIS.preventerVars.gChangedGears 	= true
		                FCOIS.preventerVars.gUpdateMarkersNow = true
                        --Update the icon list dropdown entries (name, enabled state)
                        updateIconListDropdownEntries()
		            end,
		            width="full",
				},

	        } -- controls gear sets
	}, -- submenu gear sets

--==============================================================================
-- ^^^ GEAR SETS ^^^
--==============================================================================

--==============================================================================
-- DYNAMIC ICONs
--==============================================================================
    {
        type = "submenu",
        name = locVars["options_icons_dynamic"],
        controls =
        {

--==============================================================================
            -- Dynamic icons - Enable/Disable them
            {
                type = "submenu",
                name = locVars["options_header_enable_disable"],
                controls = dynIconsEnabledCheckboxes
            },
--==============================================================================
            --The submenus for all the dynamic icons
            {
                type = "submenu",
                name = locVars["options_icons_dynamic"],
                controls = dynIconsSubMenus
            },

--==============================================================================
        },	-- controls DYNAMIC ICONs
    }, -- submenu DYNAMIC ICONs

--==============================================================================
-- ICON OPTIONS
--=============================================================================================
	{
		type = "submenu",
		name = locVars["options_header_icon_options"],
		controls =
		{
	--========= DEACTIVATED ICONS OPTIONS============================================
			{
				type = "submenu",
				name = locVars["options_header_deactivated_symbols"],
	            controls =
	            {
					{
						type = "checkbox",
						name = locVars["options_deactivated_symbols_apply_anti_checks"],
						tooltip = locVars["options_deactivated_symbols_apply_anti_checks_tooltip"],
						getFunc = function() return FCOISsettings.checkDeactivatedIcons end,
						setFunc = function(value) FCOISsettings.checkDeactivatedIcons = value
			            end,
					},
	            } -- controls deactivated items
			}, -- submenu deactivated items

	--========= ICON SORT OPTIONS ==================================================
	-- FCOIS Icon sort order
					{
						type = "submenu",
						name = locVars["options_header_sort_order"],
						reference = "FCOItemSaver_Settings_IconSortOrder_SubMenu",
						controls = IconSortOrderSubmenuControls, -- dynamically created dropdown controls for each FCOIS icon, for the sort order
					},

    --========= ICON POSITIONS ==================================================
			{
				type = "submenu",
				name = locVars["options_header_pos"],
	            controls =
	            {
					{
						type = "slider",
						name = locVars["options_pos_inventories"],
						tooltip = locVars["options_pos_inventories_tooltip"],
						min = -10,
						max = 540,
                        autoSelect = true,
						getFunc = function() return FCOISsettings.iconPosition.x end,
						setFunc = function(offset)
								FCOISsettings.iconPosition.x = offset
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
						default = FCOISdefaultSettings.iconPosition.x,
			            width="full",
					},
					{
						type = "slider",
						name = locVars["options_pos_crafting"],
						tooltip = locVars["options_pos_crafting_tooltip"],
						min = -10,
						max = 540,
                        autoSelect = true,
						getFunc = function() return FCOISsettings.iconPositionCrafting.x end,
						setFunc = function(offset)
								FCOISsettings.iconPositionCrafting.x = offset
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
						default = FCOISdefaultSettings.iconPositionCrafting.x,
			            width="full",
					},
					{
						type = "slider",
						name = locVars["options_pos_character_x"],
						tooltip = locVars["options_pos_character_x_tooltip"],
						min = -15,
						max = 40,
                        autoSelect = true,
						getFunc = function() return FCOISsettings.iconPositionCharacter.x end,
						setFunc = function(offset)
								FCOISsettings.iconPositionCharacter.x = offset
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
						default = FCOISdefaultSettings.iconPositionCharacter.x,
			            width="half",
					},
					{
						type = "slider",
						name = locVars["options_pos_character_y"],
						tooltip = locVars["options_pos_character_y_tooltip"],
						min = -40,
						max = 15,
                        autoSelect = true,
						getFunc = function() return FCOISsettings.iconPositionCharacter.y end,
						setFunc = function(offset)
								FCOISsettings.iconPositionCharacter.y = offset
								--Set global variable to update the marker colors and textures
				                FCOIS.preventerVars.gUpdateMarkersNow = true
							end,
						default = FCOISdefaultSettings.iconPositionCharacter.y,
			            width="half",
					},
	            } -- controls positions
			}, -- submenu positions

 		} -- controls icon options
	}, -- submenu icon options

	--========= KEYBINDS =======================================================
		{
			type = "submenu",
			name = locVars["options_header_keybind_options"],
            controls = {
--[[
		        {
					type = "checkbox",
					name = locVars["options_icon_cycle_on_keybind"],
					tooltip = locVars["options_icon_cycle_on_keybind_tooltip"],
					getFunc = function() return FCOISsettings.cycleMarkerSymbolOnKeybind end,
					setFunc = function(value) FCOISsettings.cycleMarkerSymbolOnKeybind = value
		            end,
		            width="full",
				},
]]
				{
					type = 'dropdown',
					name = locVars["options_icon_standard_on_keybind"],
					tooltip = locVars["options_icon_standard_on_keybind_tooltip"],
					choices = iconsList,
                    choicesValues = iconsListValues,
                    scrollable = true,
		            getFunc = function() return FCOISsettings.standardIconOnKeybind
                    end,
		            setFunc = function(value)
                        FCOISsettings.standardIconOnKeybind = value
		            end,
		            default = iconsList[FCOISdefaultSettings.standardIconOnKeybind],
		            reference = "FCOItemSaver_Standard_Icon_On_Keybind_Dropdown",
		            disabled = function()
                    	return FCOISsettings.cycleMarkerSymbolOnKeybind
                    end
				},
			},  -- controls keybinds
        },  -- submenu keybinds


		}, -- controls all icons
	}, -- submenu all icons

--==============================================================================
-- MARKINGs
--==============================================================================
    {
		type = "submenu",
        name = locVars["options_header_marking_options"],
		controls =
		{

            {
                type = "submenu",
                name = locVars["options_header_marking_undo"],
                controls =
                {
                    {
                        type = "checkbox",
                        name = locVars["options_remove_all_markers_with_shift_rightclick"],
                        tooltip = locVars["options_remove_all_markers_with_shift_rightclick_tooltip"],
                        getFunc = function() return FCOISsettings.contextMenuClearMarkesByShiftKey end,
                        setFunc = function(value) FCOISsettings.contextMenuClearMarkesByShiftKey = value
                        end,
                        default = FCOISdefaultSettings.contextMenuClearMarkesByShiftKey,
                        width="full",
                    },
                },
            },

--======== ITEM AUTOMATIC MARKING ==============================================
			{
				type = "submenu",
				name = locVars["options_header_items"],
	            controls =
	            {

	--==============================================================================
	--Equipment auto-marking
					{   -- Equipment
						type = "submenu",
						name = locVars["options_header_equipment"],
                        controls =
                        {
							{
								type = "checkbox",
								name = locVars["options_equipment_markall_gear"],
								tooltip = locVars["options_equipment_markall_gear_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkAllEquipment end,
								setFunc = function(value) FCOISsettings.autoMarkAllEquipment = value
					            end,
							},
							{
								type = "checkbox",
								name = locVars["options_equipment_markall_gear_add_weapons"],
								tooltip = locVars["options_equipment_markall_gear_add_weapons_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkAllWeapon end,
								setFunc = function(value) FCOISsettings.autoMarkAllWeapon = value
					            end,
					            disabled = function() return not FCOISsettings.autoMarkAllEquipment end,
							},
							{
								type = "checkbox",
								name = locVars["options_equipment_markall_gear_add_jewelry"],
								tooltip = locVars["options_equipment_markall_gear_add_jewelry_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkAllJewelry end,
								setFunc = function(value) FCOISsettings.autoMarkAllJewelry = value
					            end,
					            disabled = function() return not FCOISsettings.autoMarkAllEquipment end,
							},
						}, -- controls equipment auto-marking
                    }, -- submenu equipment auto-marking
	--==============================================================================
					{   -- Ornate
						type = "submenu",
						name = GetString(SI_ITEMTRAITTYPE10),
                        controls =
                        {
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_ornate_items"],
								tooltip = locVars["options_enable_auto_mark_ornate_items_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkOrnate end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkOrnate = value
					                if (FCOISsettings.autoMarkOrnate == true) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "ornate", false)
					                end
					            end,
					            width = "half",
					            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
							},
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_ornate_items_in_chat"],
								tooltip = locVars["options_enable_auto_mark_ornate_items_in_chat_tooltip"],
								getFunc = function() return FCOISsettings.showOrnateItemsInChat end,
								setFunc = function(value)
					            	FCOISsettings.showOrnateItemsInChat = value
					            end,
					            disabled = function() return not FCOISsettings.autoMarkOrnate end,
					            width = "half",
					            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
							},
						} -- controls ornate
                    }, -- submenu ornate
	--==============================================================================
					{   -- Intricate
						type = "submenu",
						name = GetString(SI_ITEMTRAITTYPE9),
                        controls =
                        {
					        {
					            type = "checkbox",
					            name = locVars["options_enable_auto_mark_intricate_items"],
					            tooltip = locVars["options_enable_auto_mark_intricate_items_tooltip"],
					            getFunc = function() return FCOISsettings.autoMarkIntricate end,
					            setFunc = function(value)
					                FCOISsettings.autoMarkIntricate = value
					                if (FCOISsettings.autoMarkIntricate == true) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "intricate", false)
					                end
					            end,
					            width = "half",
					            disabled = function() return not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
					        },
					        {
					            type = "checkbox",
					            name = locVars["options_enable_auto_mark_intricate_items_in_chat"],
					            tooltip = locVars["options_enable_auto_mark_intricate_items_in_chat_tooltip"],
					            getFunc = function() return FCOISsettings.showIntricateItemsInChat end,
					            setFunc = function(value)
					                FCOISsettings.showIntricateItemsInChat = value
					            end,
					            disabled = function() return not FCOISsettings.autoMarkIntricate or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
					            width = "half",
					        },
			            } -- controls intrictae
					}, -- submenu intrictae
	--==============================================================================
					{   -- Research
						type = "submenu",
						name = GetString(SI_SMITHING_TAB_RESEARCH),
                        controls =
                        {
                            {
                                type = 'dropdown',
                                name = locVars["options_auto_mark_addon"],
                                tooltip = zo_strformat(locVars["options_auto_mark_addon_tooltip"], GetString(SI_SMITHING_TAB_RESEARCH)),
                                choices = researchAddonsList,
                                choicesValues = researchAddonsListValues,
                                --scrollable = true,
                                getFunc = function() return FCOISsettings.researchAddonUsed
                                end,
                                setFunc = function(value)
                                    FCOISsettings.researchAddonUsed = value

                                end,
                                default = FCOISdefaultSettings.researchAddonUsed,
                                --disabled = function() return not FCOISsettings.autoMarkResearch end,
                                width = "half",
                            },
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_research_items"],
								tooltip = locVars["options_enable_auto_mark_research_items_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkResearch end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkResearch = value
					                if (FCOISsettings.autoMarkResearch == true and FCOIS.checkIfResearchAddonUsed() and FCOIS.checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed)) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "research", false)
					                end
					            end,
					            disabled = function() return not FCOIS.checkIfResearchAddonUsed() or not FCOIS.checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed) or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
					            warning = locVars["options_enable_auto_mark_research_items_hint"],
					            width = "half",
							},
                            {
                                type = "checkbox",
                                name = locVars["options_logged_in_char"],
                                tooltip = locVars["options_logged_in_char_tooltip"],
                                getFunc = function() return FCOISsettings.autoMarkResearchOnlyLoggedInChar end,
                                setFunc = function(value)
                                    FCOISsettings.autoMarkResearchOnlyLoggedInChar = value
                                    if (FCOISsettings.autoMarkResearch == true and FCOISsettings.autoMarkResearchOnlyLoggedInChar == true and FCOIS.checkIfResearchAddonUsed() and FCOIS.checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed)) then
                                        FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "research", false)
                                    end
                                end,
                                disabled = function() return not FCOIS.checkIfResearchAddonUsed() or FCOISsettings.researchAddonUsed == FCOIS_RESEARCH_ADDON_ESO_STANDARD or FCOISsettings.researchAddonUsed == FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT or not FCOIS.checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed) or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
                                warning = locVars["options_enable_auto_mark_research_items_hint_logged_in_char"],
                                width = "half",
                            },
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_research_items_in_chat"],
								tooltip = locVars["options_enable_auto_mark_research_items_in_chat_tooltip"],
								getFunc = function() return FCOISsettings.showResearchItemsInChat end,
								setFunc = function(value)
					            	FCOISsettings.showResearchItemsInChat = value
					            end,
					            disabled = function() return not FCOIS.checkIfResearchAddonUsed() or not FCOIS.checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed) or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] or not FCOISsettings.autoMarkResearch end,
					            warning = locVars["options_enable_auto_mark_research_items_hint"],
					            width = "half",
							},
                            {
                                type = "checkbox",
                                name = locVars["options_enable_auto_mark_wasted_research_scrolls"],
                                tooltip = locVars["options_enable_auto_mark_wasted_research_scrolls_tooltip"],
                                getFunc = function() return FCOISsettings.autoMarkWastedResearchScrolls end,
                                setFunc = function(value)
                                    FCOISsettings.autoMarkWastedResearchScrolls = value
                                    if FCOISsettings.autoMarkWastedResearchScrolls then
                                        FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "researchScrolls", false)
                                    end
                                end,
                                disabled = function() return (DetailedResearchScrolls == nil or DetailedResearchScrolls.GetWarningLine == nil) or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_LOCK] end,
                                width = "full",
                            },
			            } -- controls research
					}, -- submenu research
	--==============================================================================
                    {   -- New
                        type = "submenu",
                        name = locVars["options_header_items_mark_new"],
                        controls =
                        {
                            {
                                type = "checkbox",
                                name = locVars["options_enable_auto_mark_new_items"],
                                tooltip = locVars["options_enable_auto_mark_new_items_tooltip"],
                                getFunc = function() return FCOISsettings.autoMarkNewItems end,
                                setFunc = function(value)
                                    FCOISsettings.autoMarkNewItems = value
                                    if (FCOISsettings.autoMarkNewItems == true) then
                                        FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "new", false)
                                    end
                                end,
                                disabled = function() return not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkNewIconNr] end,
                                width = "half",
                            },
                            {
                                type = 'dropdown',
                                name = locVars["options_auto_mark_new_items__icon"],
                                tooltip = locVars["options_auto_mark_new_items_icon_tooltip"],
                                choices = iconsList,
                                choicesValues = iconsListValues,
                                scrollable = true,
                                getFunc = function() return FCOISsettings.autoMarkNewIconNr
                                end,
                                setFunc = function(value)
                                    FCOISsettings.autoMarkNewIconNr = value
                                end,
                                default = iconsList[FCOISdefaultSettings.autoMarkNewIconNr],
                                reference = "FCOItemSaver_Icon_On_Automatic_New_Item_Dropdown",
                                disabled = function() return not FCOISsettings.autoMarkNewItems end,
                                width = "half",
                            },
                        } -- controls research
                    }, -- submenu research
            --==============================================================================
					{  -- Sets
						type = "submenu",
						name = locVars["options_enable_auto_mark_sets"],
                        controls =
                        {

			--==============================================================================
			-- SetTracker auto-marking
							{
								type = "submenu",
								name = locVars["options_header_settracker"],
								reference = "FCOItemSaver_Settings_SetTracker_SubMenu",
								controls = SetTrackerSubmenuControls, -- dynamically created dropdown controls for each SetTracker tracking state/index
							},
			--==============================================================================
			-- Normal sets
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_sets"],
								tooltip = locVars["options_enable_auto_mark_sets_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkSets end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkSets = value
					                if (FCOISsettings.autoMarkSets == true) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
					                end
					            end,
					            disabled = function() return not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsIconNr] end,
					            width = "half",
							},
							{
								type = 'dropdown',
								name = locVars["options_auto_mark_sets_icon"],
								tooltip = locVars["options_auto_mark_sets_icon_tooltip"],
								choices = iconsList,
                                choicesValues = iconsListValues,
                                scrollable = true,
					            getFunc = function() return FCOISsettings.autoMarkSetsIconNr
			                    end,
					            setFunc = function(value)
                                    FCOISsettings.autoMarkSetsIconNr = value
					            end,
					            default = iconsList[FCOISdefaultSettings.autoMarkSetsIconNr],
					            reference = "FCOItemSaver_Icon_On_Automatic_Set_Part_Dropdown",
					            disabled = function() return not FCOISsettings.autoMarkSets or FCOISsettings.autoMarkSetsOnlyTraits end,
			                    width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_check_all_icons"],
								tooltip = locVars["options_enable_auto_mark_check_all_icons_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkSetsCheckAllIcons end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkSetsCheckAllIcons = value
					                if (FCOISsettings.autoMarkSetsCheckAllIcons == true) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
					                end
					            end,
					            disabled = function() return not FCOISsettings.autoMarkSets or FCOISsettings.autoMarkSetsOnlyTraits end,
					            width = "full",
							},
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_sets_all_gear_marker_icons"],
								tooltip = locVars["options_enable_auto_mark_sets_all_gear_marker_icons_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkSetsCheckAllGearIcons end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkSetsCheckAllGearIcons = value
					                if (FCOISsettings.autoMarkSetsCheckAllGearIcons == true) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
					                end
					            end,
					            disabled = function() return FCOISsettings.autoMarkSetsCheckAllIcons or (not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets) or FCOISsettings.autoMarkSetsOnlyTraits end,
					            width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_sets_settracker_icons"],
								tooltip = locVars["options_enable_auto_mark_sets_settracker_icons_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkSetsCheckAllSetTrackerIcons end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkSetsCheckAllSetTrackerIcons = value
					                if (FCOISsettings.autoMarkSetsCheckAllSetTrackerIcons == true) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
					                end
					            end,
					            disabled = function() return not FCOISsettings.autoMarkSets or not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets or FCOISsettings.autoMarkSetsOnlyTraits end,
					            width = "half",
                            },
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_sets_sell_icon"],
								tooltip = locVars["options_enable_auto_mark_sets_sell_icon_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkSetsCheckSellIcons end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkSetsCheckSellIcons = value
					                if (FCOISsettings.autoMarkSetsCheckSellIcons == true) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
					                end
					            end,
					            disabled = function() return FCOISsettings.autoMarkSetsCheckAllIcons or (not FCOISsettings.autoMarkSets or (not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] and not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE])) or FCOISsettings.autoMarkSetsOnlyTraits end,
					            width = "full",
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_traits_only"],
                                tooltip = locVars["options_auto_mark_traits_only_tooltip"],
                                getFunc = function() return FCOISsettings.autoMarkSetsOnlyTraits end,
                                setFunc = function(value)
                                    FCOISsettings.autoMarkSetsOnlyTraits = value
                                end,
                                disabled = function() return not FCOISsettings.autoMarkSets end,
                                width = "full",
                            },

                --==============================================================================
                -- Sets - Traits
                            {
                                type = "submenu",
                                name = locVars["options_header_traits"],
                                reference = "FCOItemSaver_Settings_Set_Traits_SubMenu",
                                controls = {
                        --==============================================================================
                        -- Sets - Armor traits
                                        {
                                            type = "submenu",
                                            name = GetString(SI_ITEMTYPE45),
                                            controls = armorTraitControls,
                                        }, -- sub menu armor tarits
                        --==============================================================================
                        -- Sets - Jewelry traits
                                        {
                                            type = "submenu",
                                            name = GetString(SI_GAMEPADITEMCATEGORY38) .. " " .. GetString(SI_SMITHING_HEADER_TRAIT),
                                            controls = jewelryTraitControls,
                                        }, -- submenu jewelry traits
                        --==============================================================================
                        -- Sets - Weapon traits
                                        {
                                            type = "submenu",
                                            name = GetString(SI_ITEMTYPE46),
                                            controls = weaponTraitControls,
                                        }, -- submenu weapon traits
                        --==============================================================================
                        -- Sets - Shield traits
                                        {
                                            type = "submenu",
                                            name = GetString(SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_SHIELD),
                                            controls = weaponShieldTraitControls,
                                        }, -- submenu weapon traits
                        --==============================================================================
                            --Additional automatic-marking: Non-wished options
                                        {
                                            type = "submenu",
                                            name = locVars["options_header_non_wished"],
                                            reference = "FCOItemSaver_Settings_Set_Traits_NonWished_SubMenu",
                                            controls = {

                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_enable_auto_mark_sets_non_wished"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_non_wished_tooltip"],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsNonWished end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsNonWished = value
                                                        if (FCOISsettings.autoMarkSetsNonWished == true) then
                                                            FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end

                                                    end,
                                                    disabled = function() return (not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not FCOISsettings.autoMarkSets) end,
                                                    width = "half",
                                                },
                                                {
                                                    type = 'dropdown',
                                                    name = locVars["options_enable_auto_mark_sets_non_wished_icon"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_non_wished_icon_tooltip"],
                                                    choices = iconsList,
                                                    choicesValues = iconsListValues,
                                                    scrollable = true,
                                                    getFunc = function() return FCOISsettings.autoMarkSetsNonWishedIconNr
                                                    end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsNonWishedIconNr = value
                                                    end,
                                                    default = iconsList[FCOISdefaultSettings.autoMarkSetsNonWishedIconNr],
                                                    reference = "FCOItemSaver_Icon_On_Automatic_Non_Wished_Set_Part_Dropdown",
                                                    disabled = function() return (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished) end,
                                                    width = "half",
                                                },

                                                {
                                                    type = 'dropdown',
                                                    name = locVars["options_enable_auto_mark_sets_non_wished_checks"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_non_wished_checks_tooltip"],
                                                    choices = nonWishedChecksList,
                                                    choicesValues = nonWishedChecksValuesList,
                                                    --scrollable = true,
                                                    getFunc = function() return FCOISsettings.autoMarkSetsNonWishedChecks end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsNonWishedChecks = value
                                                        if (FCOISsettings.autoMarkSetsNonWishedChecks == true) then
                                                            FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end
                                                    end,
                                                    disabled = function()return (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL]) end,
                                                    default = FCOISdefaultSettings.autoMarkSetsNonWishedChecks,
                                                    width = "full",
                                                },

                                                {
                                                    type = 'dropdown',
                                                    name = locVars["options_enable_auto_mark_sets_non_wished_level"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_non_wished_level_tooltip"],
                                                    choices = levelList,
                                                    scrollable = true,
                                                    getFunc = function() return levelList[FCOISsettings.autoMarkSetsNonWishedLevel] end,
                                                    setFunc = function(value)
                                                        for i,v in pairs(levelList) do
                                                            if v == value then
                                                                FCOISsettings.autoMarkSetsNonWishedLevel = i
                                                                if i ~= 1 then
                                                                    FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                end
                                                                break
                                                            end
                                                        end
                                                    end,
                                                    disabled = function()return (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] or (FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_ALL and FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_LEVEL)) end,
                                                    default = FCOISdefaultSettings.autoMarkSetsNonWishedLevel,
                                                    width = "full",
                                                },

                                                {
                                                    type = 'dropdown',
                                                    name = locVars["options_enable_auto_mark_sets_non_wished_quality"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_non_wished_quality_tooltip"],
                                                    choices = qualityList,
                                                    getFunc = function() return qualityList[FCOISsettings.autoMarkSetsNonWishedQuality] end,
                                                    setFunc = function(value)
                                                        for i,v in pairs(qualityList) do
                                                            if v == value then
                                                                FCOISsettings.autoMarkSetsNonWishedQuality = i
                                                                if i ~= 1 then
                                                                    FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                end
                                                                break
                                                            end
                                                        end
                                                    end,
                                                    disabled = function()return (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] or (FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_ALL and FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_QUALITY)) end,
                                                    default = FCOISdefaultSettings.autoMarkSetsNonWishedQuality,
                                                    width = "full",
                                                },
                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_enable_auto_mark_sets_non_wished_sell_others"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_non_wished_sell_others_tooltip"],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsNonWishedSellOthers end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsNonWishedSellOthers = value
                                                        if (FCOISsettings.autoMarkSetsNonWishedSellOthers == true) then
                                                            FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end
                                                    end,
                                                    disabled = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
                                                    default = FCOISdefaultSettings.autoMarkSetsNonWishedSellOthers,
                                                    width = "full",
                                                },
                                            }, -- controls
                                        }, -- submenu non-wished

                                    {
                                        type = "checkbox",
                                        name = locVars["options_enable_auto_mark_check_all_icons"],
                                        tooltip = locVars["options_enable_auto_mark_check_all_icons_tooltip"],
                                        getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkSetsWithTraitCheckAllIcons = value
                                            if (FCOISsettings.autoMarkSetsWithTraitCheckAllIcons == true) then
                                                FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                            end
                                        end,
                                        disabled = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished end,
                                        default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckAllIcons,
                                        width = "full",
                                    },
                                    {
                                        type = "checkbox",
                                        name = locVars["options_enable_auto_mark_sets_all_gear_marker_icons"],
                                        tooltip = locVars["options_enable_auto_mark_sets_all_gear_marker_icons_tooltip"],
                                        getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllGearIcons end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkSetsWithTraitCheckAllGearIcons = value
                                            if (FCOISsettings.autoMarkSetsWithTraitCheckAllGearIcons == true) then
                                                FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                            end
                                        end,
                                        disabled = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons or (not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished) end,
                                        default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckAllGearIcons,
                                        width = "half",
                                    },
                                    {
                                        type = "checkbox",
                                        name = locVars["options_enable_auto_mark_sets_settracker_icons"],
                                        tooltip = locVars["options_enable_auto_mark_sets_settracker_icons_tooltip"],
                                        getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons = value
                                            if (FCOISsettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons == true) then
                                                FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                            end
                                        end,
                                        disabled = function() return not FCOISsettings.autoMarkSets or not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets or not FCOISsettings.autoMarkSetsNonWished end,
                                        default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons,
                                        width = "half",
                                    },
                                    {
                                        type = "checkbox",
                                        name = locVars["options_enable_auto_mark_sets_sell_icon"],
                                        tooltip = locVars["options_enable_auto_mark_sets_sell_icon_tooltip"],
                                        getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckSellIcons end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkSetsWithTraitCheckSellIcons = value
                                            if (FCOISsettings.autoMarkSetsWithTraitCheckSellIcons == true) then
                                                FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                            end
                                        end,
                                        disabled = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons or (not FCOISsettings.autoMarkSets or (not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL] and not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE])) or not FCOISsettings.autoMarkSetsNonWished end,
                                        default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckSellIcons,
                                        width = "full",
                                    },
                                    {
                                        type = "checkbox",
                                        name = locVars["options_auto_mark_traits_with_set_too"],
                                        tooltip = locVars["options_auto_mark_traits_with_set_too_tooltip"],
                                        getFunc = function() return FCOISsettings.autoMarkSetsWithTraitIfAutoSetMarked end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkSetsWithTraitIfAutoSetMarked = value
                                            if (FCOISsettings.autoMarkSetsWithTraitIfAutoSetMarked == true) then
                                                FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                            end
                                        end,
                                        default = FCOISdefaultSettings.autoMarkSetsWithTraitIfAutoSetMarked,
                                        width = "half",
                                        disabled = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons or (not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets) end,
                                    },

                                },
                            },

                            {
                                type = "checkbox",
                                name = locVars["options_enable_auto_mark_sets_already_bound"],
                                tooltip = locVars["options_enable_auto_mark_sets_already_bound_tooltip"],
                                getFunc = function() return FCOISsettings.showBoundItemMarker end,
                                setFunc = function(value)
                                    FCOISsettings.showBoundItemMarker = value
                                end,
                                width = "half",
                            },

							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_sets_in_chat"],
								tooltip = locVars["options_enable_auto_mark_sets_in_chat_tooltip"],
								getFunc = function() return FCOISsettings.showSetsInChat end,
								setFunc = function(value)
					            	FCOISsettings.showSetsInChat = value
					            end,
					            disabled = function() return not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets end,
					            width = "half",
							},
			            } -- controls sets
					}, -- submenu sets
	--==============================================================================
					{   --Crafted
						type = "submenu",
						name = GetString(SI_ITEM_FORMAT_STR_CRAFTED),
                        controls =
                        {
                            {   --Crafted "Writs"
                                type = "submenu",
                                name = "Writ Creator",
                                controls =
                                {
                                    {
                                        type = "checkbox",
                                        name = locVars["options_auto_mark_crafted_writ_items"],
                                        tooltip = locVars["options_auto_mark_crafted_writ_items_tooltip"],
                                        getFunc = function() return FCOISsettings.autoMarkCraftedWritItems end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkCraftedWritItems = value
                                        end,
                                        disabled = function()
                                            return  not FCOIS.otherAddons.LazyWritCreatorActive
                                                    or (not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedWritCreatorItemsIconNr] and FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr])
                                        end,
                                        width = "full",
                                    },
                                    {
                                        type = 'dropdown',
                                        name = locVars["options_auto_mark_crafted_writ_items_icon"],
                                        tooltip = locVars["options_auto_mark_crafted_writ_items_icon_tooltip"],
                                        choices = iconsList,
                                        choicesValues = iconsListValues,
                                        scrollable = true,
                                        getFunc = function() return FCOISsettings.autoMarkCraftedWritCreatorItemsIconNr
                                        end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkCraftedWritCreatorItemsIconNr = value
                                            --Check if the icon needs to get the setting to skip the research check enabled
                                            if value ~= nil then
                                                FCOIS.setDynamicIconAntiResearchCheck(value, true)
                                            end
                                        end,
                                        default = iconsList[FCOISdefaultSettings.autoMarkCraftedWritCreatorItemsIconNr],
                                        reference = "FCOItemSaver_Icon_On_Automatic_Crafted_Writ_Items_Dropdown",
                                        disabled = function() return not FCOIS.otherAddons.LazyWritCreatorActive or not FCOISsettings.autoMarkCraftedWritItems end,
                                        width = "half",
                                    },
                                    {
                                        type = 'dropdown',
                                        name = locVars["options_auto_mark_crafted_masterwrit_items_icon"],
                                        tooltip = locVars["options_auto_mark_crafted_masterwrit_items_icon_tooltip"],
                                        choices = iconsList,
                                        choicesValues = iconsListValues,
                                        scrollable = true,
                                        getFunc = function() return FCOISsettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr
                                        end,
                                        setFunc = function(value)
                                            FCOISsettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr = value
                                            --Check if the icon needs to get the setting to skip the research check enabled
                                            if value ~= nil then
                                                FCOIS.setDynamicIconAntiResearchCheck(value, true)
                                            end
                                        end,
                                        default = iconsList[FCOISdefaultSettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr],
                                        reference = "FCOItemSaver_Icon_On_Automatic_Crafted_MasterWrit_Items_Dropdown",
                                        disabled = function() return not FCOIS.otherAddons.LazyWritCreatorActive or not FCOISsettings.autoMarkCraftedWritItems end,
                                        width = "half",
                                    },
                                },
                            },
							{
								type = "checkbox",
								name = locVars["options_auto_mark_crafted_items"],
								tooltip = locVars["options_auto_mark_crafted_items_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkCraftedItems end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkCraftedItems = value
					            end,
					            disabled = function() return not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
					            width = "half",
							},
							{
								type = 'dropdown',
								name = locVars["options_auto_mark_crafted_items_icon"],
								tooltip = locVars["options_auto_mark_crafted_items_icon_tooltip"],
								choices = iconsList,
                                choicesValues = iconsListValues,
                                scrollable = true,
					            getFunc = function() return FCOISsettings.autoMarkCraftedItemsIconNr
			                    end,
					            setFunc = function(value)
                                    FCOISsettings.autoMarkCraftedItemsIconNr = value
                                    --Check if the icon needs to get the setting to skip the research check enabled
                                    if value ~= nil then
                                        FCOIS.setDynamicIconAntiResearchCheck(value, true)
                                    end
					            end,
					            default = iconsList[FCOISdefaultSettings.autoMarkCraftedItemsIconNr],
					            reference = "FCOItemSaver_Icon_On_Automatic_Crafted_Items_Dropdown",
					            disabled = function() return not FCOISsettings.autoMarkCraftedItems end,
			                    width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_auto_mark_crafted_items_sets"],
								tooltip = locVars["options_auto_mark_crafted_items_sets_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkCraftedItemsSets end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkCraftedItemsSets = value
					            end,
					            disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
					            width = "full",
							},

                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_crafted_items_panel_alchemy"],
                                tooltip = locVars["options_auto_mark_crafted_items_panel_alchemy_tooltip"],
                                getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ALCHEMY] end,
                                setFunc = function(value)
                                    FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ALCHEMY] = value
                                    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_ALCHEMY)
                                end,
                                disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                width = "full",
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_crafted_items_panel_blacksmithing"],
                                tooltip = locVars["options_auto_mark_crafted_items_panel_blacksmithing_tooltip"],
                                getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_BLACKSMITHING] end,
                                setFunc = function(value)
                                    FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_BLACKSMITHING] = value
                                    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_BLACKSMITHING)
                                end,
                                disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                width = "full",
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_crafted_items_panel_clothier"],
                                tooltip = locVars["options_auto_mark_crafted_items_panel_clothier_tooltip"],
                                getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_CLOTHIER] end,
                                setFunc = function(value)
                                    FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_CLOTHIER] = value
                                    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_CLOTHIER)
                                end,
                                disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                width = "full",
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_crafted_items_panel_enchanting"],
                                tooltip = locVars["options_auto_mark_crafted_items_panel_enchanting_tooltip"],
                                getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ENCHANTING] end,
                                setFunc = function(value)
                                    FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ENCHANTING] = value
                                    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_ENCHANTING)
                                end,
                                disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                width = "full",
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_crafted_items_panel_provisioning"],
                                tooltip = locVars["options_auto_mark_crafted_items_panel_provisioning_tooltip"],
                                getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_PROVISIONING] end,
                                setFunc = function(value)
                                    FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_PROVISIONING] = value
                                    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_PROVISIONING)
                                end,
                                disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                width = "full",
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_crafted_items_panel_woodworking"],
                                tooltip = locVars["options_auto_mark_crafted_items_panel_woodworking_tooltip"],
                                getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_WOODWORKING] end,
                                setFunc = function(value)
                                    FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_WOODWORKING] = value
                                    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_WOODWORKING)
                                end,
                                disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                width = "full",
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_auto_mark_crafted_items_panel_jewelry"],
                                tooltip = locVars["options_auto_mark_crafted_items_panel_jewelry_tooltip"],
                                getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_JEWELRYCRAFTING] end,
                                setFunc = function(value)
                                    FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_JEWELRYCRAFTING] = value
                                    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_JEWELRYCRAFTING)
                                end,
                                disabled = function() return not FCOISsettings.autoMarkCraftedItems or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                width = "full",
                            },
			            } -- controls crafted items
					}, -- submenu crafted items
	--==============================================================================
					{   -- Recipes
						type = "submenu",
						name = GetString(SI_ITEMTYPE29),
                        controls =
                        {
                            {
                                type = 'dropdown',
                                name = locVars["options_auto_mark_addon"],
                                tooltip = zo_strformat(locVars["options_auto_mark_addon_tooltip"], GetString(SI_ITEMTYPE29)),
                                choices = recipeAddonsList,
                                choicesValues = recipeAddonsListValues,
                                --scrollable = true,
                                getFunc = function() return FCOISsettings.recipeAddonUsed
                                end,
                                setFunc = function(value)
                                    FCOISsettings.recipeAddonUsed = value

                                end,
                                default = FCOISdefaultSettings.recipeAddonUsed,
                                --disabled = function() return not FCOISsettings.autoMarkRecipes end,
                                width = "half",
                            },
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_recipes"],
								tooltip = locVars["options_enable_auto_mark_recipes_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkRecipes end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkRecipes = value
					                if (FCOISsettings.autoMarkRecipes == true and FCOIS.checkIfRecipeAddonUsed() and FCOIS.checkIfChosenRecipeAddonActive(FCOISsettings.autoMarkRecipes)) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "recipes", false)
					                end
					            end,
					            disabled = function() return not FCOIS.checkIfRecipeAddonUsed() or not FCOIS.checkIfChosenRecipeAddonActive(FCOISsettings.autoMarkRecipes) or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkRecipesIconNr] end,
					            warning = locVars["options_enable_auto_mark_recipes_hint"],
					            width = "half",
							},
							{
								type = 'dropdown',
								name = locVars["options_auto_mark_recipes_icon"],
								tooltip = locVars["options_auto_mark_recipes_icon_tooltip"],
								choices = iconsList,
                                choicesValues = iconsListValues,
                                scrollable = true,
					            getFunc = function() return FCOISsettings.autoMarkRecipesIconNr
			                    end,
					            setFunc = function(value)
                                    FCOISsettings.autoMarkRecipesIconNr = value
					            end,
					            default = iconsList[FCOISdefaultSettings.autoMarkRecipesIconNr],
					            reference = "FCOItemSaver_Icon_On_Automatic_Recipe_Dropdown",
					            disabled = function() return not FCOISsettings.autoMarkRecipes or not FCOIS.checkIfRecipeAddonUsed() or not FCOIS.checkIfChosenRecipeAddonActive(FCOISsettings.recipeAddonUsed) end,
			                    width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_auto_mark_recipes_this_char"],
								tooltip = locVars["options_auto_mark_recipes_this_char_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkRecipesOnlyThisChar end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkRecipesOnlyThisChar = value
					                if (FCOISsettings.autoMarkRecipes == true and FCOIS.checkIfRecipeAddonUsed()) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "recipes", false)
					                end
					            end,
					            disabled = function() return not FCOIS.checkIfRecipeAddonUsed() or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkRecipesIconNr] or not FCOIS.checkIfChosenRecipeAddonActive(FCOISsettings.recipeAddonUsed) end,
					            width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_known_recipes"],
								tooltip = locVars["options_enable_auto_mark_known_recipes_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkKnownRecipes end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkKnownRecipes = value
					                if (FCOISsettings.autoMarkKnownRecipes == true and FCOIS.checkIfRecipeAddonUsed()) then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "knownRecipes", false)
					                end
					            end,
					            disabled = function() return not FCOIS.checkIfRecipeAddonUsed() or not FCOISsettings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] or not FCOIS.checkIfChosenRecipeAddonActive(FCOISsettings.recipeAddonUsed) end,
					            warning = locVars["options_enable_auto_mark_recipes_hint"],
					            width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_recipes_in_chat"],
								tooltip = locVars["options_enable_auto_mark_recipes_in_chat_tooltip"],
								getFunc = function() return FCOISsettings.showRecipesInChat end,
								setFunc = function(value)
					            	FCOISsettings.showRecipesInChat = value
					            end,
					            disabled = function() return not FCOIS.checkIfRecipeAddonUsed() or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkRecipesIconNr] or not FCOISsettings.autoMarkRecipes or not FCOIS.checkIfChosenRecipeAddonActive(FCOISsettings.recipeAddonUsed) end,
					            warning = locVars["options_enable_auto_mark_recipes_hint"],
					            width = "half",
							},
			            } -- controls recipes
					}, -- submenu recipes

    --==============================================================================
					{   -- Quality
						type = "submenu",
						name = locVars["options_enable_auto_mark_quality_items"],
                        controls =
                        {
							{
								type = 'dropdown',
								name = locVars["options_enable_auto_mark_quality_items"],
								tooltip = locVars["options_enable_auto_mark_quality_items_tooltip"],
								choices = qualityList,
					            getFunc = function() return qualityList[FCOISsettings.autoMarkQuality] end,
					            setFunc = function(value)
					                for i,v in pairs(qualityList) do
					                    if v == value then
					                    	FCOISsettings.autoMarkQuality = i
					                        if i ~= 1 then
							                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
		                                    end
					                        break
					                    end
					                end
					            end,
					            default = FCOISdefaultSettings.autoMarkQuality,
					            width = "half",
							},
							{
								type = 'dropdown',
								name = locVars["options_auto_mark_quality_icon"],
								tooltip = locVars["options_auto_mark_quality_icon_tooltip"],
								choices = iconsList,
                                choicesValues = iconsListValues,
                                scrollable = true,
					            getFunc = function() return FCOISsettings.autoMarkQualityIconNr
			                    end,
					            setFunc = function(value)
                                    FCOISsettings.autoMarkQualityIconNr = value
					            end,
					            default = iconsList[FCOISdefaultSettings.autoMarkQualityIconNr],
					            reference = "FCOItemSaver_Icon_On_Automatic_Quality_Dropdown",
					            disabled = function() return FCOISsettings.autoMarkQuality == 1 end,
			                    width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_higher_quality_items"],
								tooltip = locVars["options_enable_auto_mark_higher_quality_items_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkHigherQuality end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkHigherQuality = value
					                if FCOISsettings.autoMarkHigherQuality and FCOISsettings.autoMarkQuality ~= 1 and FCOISsettings.autoMarkQuality ~= ITEM_QUALITY_LEGENDARY then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
					                end
					            end,
					            disabled = function() return FCOISsettings.autoMarkQuality == 1 or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkQualityIconNr] or FCOISsettings.autoMarkQuality == ITEM_QUALITY_LEGENDARY end,
					            width = "half",
							},
							{
								type = "checkbox",
								name = locVars["options_auto_mark_quality_icon_no_armor"],
								tooltip = locVars["options_auto_mark_quality_icon_no_armor_tooltip"],
								getFunc = function() return FCOISsettings.autoMarkHigherQualityExcludeArmor end,
								setFunc = function(value)
					            	FCOISsettings.autoMarkHigherQualityExcludeArmor = value
					                if FCOISsettings.autoMarkHigherQuality and FCOISsettings.autoMarkQuality ~= 1 then
					                	FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
					                end
					            end,
					            disabled = function() return FCOISsettings.autoMarkQuality == 1 or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkQualityIconNr] end,
					            width = "half",
							},
                            {
                                type = "checkbox",
                                name = locVars["options_enable_auto_mark_check_all_icons"],
                                tooltip = locVars["options_enable_auto_mark_check_all_icons_tooltip"],
                                getFunc = function() return FCOISsettings.autoMarkQualityCheckAllIcons end,
                                setFunc = function(value)
                                    FCOISsettings.autoMarkQualityCheckAllIcons = value
                                    if (FCOISsettings.autoMarkQualityCheckAllIcons == true) then
                                        FCOIS.scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
                                    end
                                end,
                                disabled = function() return FCOISsettings.autoMarkQuality == 1 or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkQualityIconNr] end,
                                default = FCOISsettings.autoMarkQualityCheckAllIcons,
                                width = "half",
                            },
							{
								type = "checkbox",
								name = locVars["options_enable_auto_mark_quality_items_in_chat"],
								tooltip = locVars["options_enable_auto_mark_quality_items_in_chat_tooltip"],
								getFunc = function() return FCOISsettings.showQualityItemsInChat end,
								setFunc = function(value)
					            	FCOISsettings.showQualityItemsInChat = value
					            end,
					            disabled = function() return FCOISsettings.autoMarkQuality == 1 or not FCOISsettings.isIconEnabled[FCOISsettings.autoMarkQualityIconNr] end,
					            width = "half",
							},
			            } -- controls quality
					}, -- submenu quality
	--==============================================================================
    	-- Do not mark automatically again, if ....

					-- Sell
					{
						type = "checkbox",
						name = locVars["options_prevent_auto_marking_sell"],
						tooltip = locVars["options_prevent_auto_marking_sell_tooltip"],
						getFunc = function() return FCOISsettings.autoMarkPreventIfMarkedForSell end,
						setFunc = function(value)
			            	FCOISsettings.autoMarkPreventIfMarkedForSell = value
			            end,
			            width = "full",
					},
					-- Deconstruction
					{
						type = "checkbox",
						name = locVars["options_prevent_auto_marking_deconstruction"],
						tooltip = locVars["options_prevent_auto_marking_deconstruction_tooltip"],
						getFunc = function() return FCOISsettings.autoMarkPreventIfMarkedForDeconstruction end,
						setFunc = function(value)
			            	FCOISsettings.autoMarkPreventIfMarkedForDeconstruction = value
			            end,
			            width = "full",
					},

	            } -- controls marking
			}, -- submenu marking

	--==============================================================================
	-- ITEM AUOMATIC DE-MARKING
	--==============================================================================
			{
				type = "submenu",
				name = locVars["options_header_items_demark"],
	            controls =
	            {
                    {
                        type = "submenu",
                        name = locVars["options_header_items_demark_all"],
                        controls =
                        {
                            {
                                type = "checkbox",
                                name = locVars["options_demark_all_selling"],
                                tooltip = locVars["options_demark_all_selling_tooltip"],
                                getFunc = function() return FCOISsettings.autoDeMarkSell end,
                                setFunc = function(value) FCOISsettings.autoDeMarkSell = value
                                end,
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_demark_all_selling_guild_store"],
                                tooltip = locVars["options_demark_all_selling_guild_store_tooltip"],
                                getFunc = function() return FCOISsettings.autoDeMarkSellInGuildStore end,
                                setFunc = function(value) FCOISsettings.autoDeMarkSellInGuildStore = value
                                end,
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_demark_all_deconstruct"],
                                tooltip = locVars["options_demark_all_deconstruct_tooltip"],
                                getFunc = function() return FCOISsettings.autoDeMarkDeconstruct end,
                                setFunc = function(value) FCOISsettings.autoDeMarkDeconstruct = value
                                end,
                            },
                        },
                    },
                    {
                        type = "submenu",
                        name = locVars["options_header_items_demark_sell"],
                        controls =
                        {
                            {
                                type = "checkbox",
                                name = locVars["options_demark_sell_on_others"],
                                tooltip = locVars["options_demark_sell_on_others_tooltip"],
                                getFunc = function() return FCOISsettings.autoDeMarkSellOnOthers end,
                                setFunc = function(value) FCOISsettings.autoDeMarkSellOnOthers = value
                                end,
                            },
                            {
                                type = "checkbox",
                                name = locVars["options_demark_sell_guild_store_on_others"],
                                tooltip = locVars["options_demark_sell_guild_store_on_others_tooltip"],
                                getFunc = function() return FCOISsettings.autoDeMarkSellGuildStoreOnOthers end,
                                setFunc = function(value) FCOISsettings.autoDeMarkSellGuildStoreOnOthers = value
                                end,
                            },
                        }, -- controls de-marking sell
                    }, -- submenu de-marking sell
					
	            } -- controls de-marking
			}, -- submenu de-marking

        }, -- controls marking
    }, -- submenu marking

--==============================================================================
--		FILTERs
--==============================================================================
        {
            type = "submenu",
            name = locVars["options_header_filters"],
            controls =
            {

        {
            type = "submenu",
            name = locVars["options_header_filters"],
            controls =
            {
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_inventory"],
					tooltip = locVars["options_enable_filter_in_inventory_tooltip"],
					getFunc = function() return FCOISsettings.allowInventoryFilter end,
					setFunc = function(value) FCOISsettings.allowInventoryFilter = value
				        --Hide the filter buttons at the filter panel Id
						FCOIS.updateFilterButtonsInInv(-1)
		                --Unregister and reregister the inventory filter LF_INVENTORY
		            	FCOIS.EnableFilters(-100)
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_craftbag"],
					tooltip = locVars["options_enable_filter_in_craftbag_tooltip"],
					getFunc = function() return FCOISsettings.allowCraftBagFilter end,
					setFunc = function(value) FCOISsettings.allowCraftBagFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_bank"],
					tooltip = locVars["options_enable_filter_in_bank_tooltip"],
					getFunc = function() return FCOISsettings.allowBankFilter end,
					setFunc = function(value) FCOISsettings.allowBankFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_guildbank"],
					tooltip = locVars["options_enable_filter_in_guildbank_tooltip"],
					getFunc = function() return FCOISsettings.allowGuildBankFilter end,
					setFunc = function(value) FCOISsettings.allowGuildBankFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_tradinghouse"],
					tooltip = locVars["options_enable_filter_in_tradinghouse_tooltip"],
					getFunc = function() return FCOISsettings.allowTradinghouseFilter end,
					setFunc = function(value) FCOISsettings.allowTradinghouseFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_trade"],
					tooltip = locVars["options_enable_filter_in_trade_tooltip"],
					getFunc = function() return FCOISsettings.allowTradeFilter end,
					setFunc = function(value) FCOISsettings.allowTradeFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_mail"],
					tooltip = locVars["options_enable_filter_in_mail_tooltip"],
					getFunc = function() return FCOISsettings.allowMailFilter end,
					setFunc = function(value) FCOISsettings.allowMailFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_store"],
					tooltip = locVars["options_enable_filter_in_store_tooltip"],
					getFunc = function() return FCOISsettings.allowVendorFilter end,
					setFunc = function(value) FCOISsettings.allowVendorFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_fence"],
					tooltip = locVars["options_enable_filter_in_fence_tooltip"],
					getFunc = function() return FCOISsettings.allowFenceFilter end,
					setFunc = function(value) FCOISsettings.allowFenceFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_launder"],
					tooltip = locVars["options_enable_filter_in_launder_tooltip"],
					getFunc = function() return FCOISsettings.allowLaunderFilter end,
					setFunc = function(value) FCOISsettings.allowLaunderFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_refinement"],
					tooltip = locVars["options_enable_filter_in_refinement_tooltip"],
					getFunc = function() return FCOISsettings.allowRefinementFilter end,
					setFunc = function(value) FCOISsettings.allowRefinementFilter = value
		            end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_enable_filter_in_jewelry_refinement"],
                    tooltip = locVars["options_enable_filter_in_jewelry_refinement_tooltip"],
                    getFunc = function() return FCOISsettings.allowJewelryRefinementFilter end,
                    setFunc = function(value) FCOISsettings.allowJewelryRefinementFilter = value
                    end,
                },
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_deconstruction"],
					tooltip = locVars["options_enable_filter_in_deconstruction_tooltip"],
					getFunc = function() return FCOISsettings.allowDeconstructionFilter end,
					setFunc = function(value) FCOISsettings.allowDeconstructionFilter = value
		            end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_enable_filter_in_jewelry_deconstruction"],
                    tooltip = locVars["options_enable_filter_in_jewelry_deconstruction_tooltip"],
                    getFunc = function() return FCOISsettings.allowJewelryDeconstructionFilter end,
                    setFunc = function(value) FCOISsettings.allowJewelryDeconstructionFilter = value
                    end,
                },
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_improvement"],
					tooltip = locVars["options_enable_filter_in_improvement_tooltip"],
					getFunc = function() return FCOISsettings.allowImprovementFilter end,
					setFunc = function(value) FCOISsettings.allowImprovementFilter = value
		            end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_enable_filter_in_jewelry_improvement"],
                    tooltip = locVars["options_enable_filter_in_jewelry_improvement_tooltip"],
                    getFunc = function() return FCOISsettings.allowJewelryImprovementFilter end,
                    setFunc = function(value) FCOISsettings.allowJewelryImprovementFilter = value
                    end,
                },
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_enchanting"],
					tooltip = locVars["options_enable_filter_in_enchanting_tooltip"],
					getFunc = function() return FCOISsettings.allowEnchantingFilter end,
					setFunc = function(value) FCOISsettings.allowEnchantingFilter = value
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_filter_in_alchemy"],
					tooltip = locVars["options_enable_filter_in_alchemy_tooltip"],
					getFunc = function() return FCOISsettings.allowAlchemyFilter end,
					setFunc = function(value) FCOISsettings.allowAlchemyFilter = value
		            end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_enable_filter_in_retrait"],
                    tooltip = locVars["options_enable_filter_in_retrait_tooltip"],
                    getFunc = function() return FCOISsettings.allowRetraitFilter end,
                    setFunc = function(value) FCOISsettings.allowRetraitFilter = value
                    end,
                },
		--==============================================================================
				{
		        	type = "header",
					name = locVars["options_header_filter_chat"],
			    },
			    {
					type = "checkbox",
					name = locVars["options_chat_filter_status"],
					tooltip = locVars["options_chat_filter_status_tooltip"],
					getFunc = function() return FCOISsettings.showFilterStatusInChat end,
					setFunc = function(value) FCOISsettings.showFilterStatusInChat = value
		            end,
				},
            } -- controls filters
        }, -- submenu filters


--==============================================================================
--		FILTER BUTTONS
--==============================================================================
		{
        	type = "submenu",
			name = locVars["options_header_filter_buttons"],
            controls =
            {
--[[
				{
					type = "header",
					name = locVars["options_header_split_filters"],
				},
				{
					type = "checkbox",
					name = locVars["options_split_filters"],
					tooltip = locVars["options_split_filters_tooltip"],
					getFunc = function() return FCOISsettings.splitFilters end,
					setFunc = function(value)
		            	FCOISsettings.splitFilters = value
		                --Set the global flag to override the function's unregisterFilters() unregister method
		                --because it will check for FCOISsettings.SplitFilters and is called from function doFilter() at
		                --function FCOIS.EnableFilters(-100) below
		                FCOIS.overrideVars.gSplitFilterOverride = true
				        --Hide the filter buttons at the filter panel Id
						FCOIS.updateFilterButtonsInInv(-1)
		                --Unregister and reregister the inventory filter LF_INVENTORY
						FCOIS.EnableFilters(-100)
		            end,
				},
]]
                --==============================================================================
				{
					type = "header",
					name = locVars["options_header_filter_buttons_position"],
				},
		        {
					type = "editbox",
					name = locVars["options_filter_button1_left"],
					tooltip = locVars["options_filter_button1_left_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_LOCKDYN] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_LOCKDYN] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_LOCKDYN)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_LOCKDYN],
				},
				{
					type = "editbox",
					name = locVars["options_filter_button1_top"],
					tooltip = locVars["options_filter_button1_top_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_LOCKDYN] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_LOCKDYN] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_LOCKDYN)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_LOCKDYN],
				},
				{
					type = "editbox",
					name = locVars["options_filter_button2_left"],
					tooltip = locVars["options_filter_button2_left_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_GEARSETS] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_GEARSETS] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_GEARSETS)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_GEARSETS],
				},
		        {
					type = "editbox",
					name = locVars["options_filter_button2_top"],
					tooltip = locVars["options_filter_button2_top_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_GEARSETS] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_GEARSETS] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_GEARSETS)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_GEARSETS],
				},
				{
					type = "editbox",
					name = locVars["options_filter_button3_left"],
					tooltip = locVars["options_filter_button3_left_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_RESDECIMP] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_RESDECIMP] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_RESDECIMP)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_RESDECIMP],
				},
		        {
					type = "editbox",
					name = locVars["options_filter_button3_top"],
					tooltip = locVars["options_filter_button3_top_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_RESDECIMP] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_RESDECIMP] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_RESDECIMP)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_RESDECIMP],
				},
				{
					type = "editbox",
					name = locVars["options_filter_button4_left"],
					tooltip = locVars["options_filter_button4_left_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_SELLGUILDINT)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT],
				},
				{
					type = "editbox",
					name = locVars["options_filter_button4_top"],
					tooltip = locVars["options_filter_button4_top_tooltip"],
					getFunc = function() return FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] end,
					setFunc = function(newValue)
			           		FCOISsettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] = newValue
			                        FCOIS.updateFilterButtonsInInv(FCOIS_CON_FILTER_BUTTON_SELLGUILDINT)
					end,
					width = "half",
					default = FCOISdefaultSettings.filterButtonTop[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT],
				},
				{
					type = "checkbox",
					name = locVars["options_filter_buttons_show_tooltip"],
					tooltip = locVars["options_filter_buttons_show_tooltip_tooltip"],
					getFunc = function() return FCOISsettings.showFilterButtonTooltip end,
					setFunc = function(value) FCOISsettings.showFilterButtonTooltip = value
		            end,
				},
            } -- controls filter buttons
	    }, -- submenu filter buttons

--[[
--TODO: Enable later again!
            {
                type = "checkbox",
                name = locVars["options_enable_filtered_item_count"],
                tooltip = locVars["options_enable_filtered_item_count_tooltip"],
                getFunc = function() return FCOISsettings.showFilteredItemCount end,
                setFunc = function(value)
                    FCOISsettings.showFilteredItemCount = value
                end,
                default = FCOISdefaultSettings.showFilteredItemCount,
            },
]]

        } -- controls ALL filters
	}, -- submenu ALL filters


--==============================================================================
-- ANTI DESTROY
--==============================================================================
		{
			type = "submenu",
			name = locVars["options_header_anti_destroy"],
            controls =
            {

                -- ANTI EQUIP
                {
                    type = "submenu",
                    name = locVars["options_header_anti_equip"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_askBeforeEquipBoundItems"],
                            tooltip = locVars["options_askBeforeEquipBoundItems_tooltip"],
                            getFunc = function() return FCOISsettings.askBeforeEquipBoundItems end,
                            setFunc = function(value) FCOISsettings.askBeforeEquipBoundItems = value
                            end,
                            default = FCOISdefaultSettings.askBeforeEquipBoundItems,
                            --disabled = function() return FCOIS.APIversion > 100019 end, --Ask before bind will be introduced ingame with patch 3.1, API 100020
                        },
                    }, -- controls anti equip
                }, -- submenu anti equip
				{
					type = "header",
					name = locVars["options_header_destroy"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_destroying"],
					tooltip = locVars["options_enable_block_destroying_tooltip"],
					getFunc = function() return FCOISsettings.blockDestroying end,
					setFunc = function(value) FCOISsettings.blockDestroying = value
                           	FCOISsettings.autoReenable_blockDestroying = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_destroying"],
					tooltip = locVars["options_auto_reenable_block_destroying_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockDestroying end,
					setFunc = function(value) FCOISsettings.autoReenable_blockDestroying = value
			           end,
		            disabled = function() return not FCOISsettings.blockDestroying end,
				},
				{
					type = "header",
					name = locVars["options_header_refinement"],
				},
			    {
					type = "checkbox",
					name = locVars["options_enable_block_refinement"],
					tooltip = locVars["options_enable_block_refinement_tooltip"],
					getFunc = function() return FCOISsettings.blockRefinement end,
					setFunc = function(value) FCOISsettings.blockRefinement = value
                           	FCOISsettings.autoReenable_blockRefinement = value
			        end,
				},
			    {
					type = "checkbox",
					name = locVars["options_auto_reenable_block_refinement"],
					tooltip = locVars["options_auto_reenable_block_refinement_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockRefinement end,
					setFunc = function(value) FCOISsettings.autoReenable_blockRefinement = value
			           end,
		            disabled = function() return not FCOISsettings.blockRefinement end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_jewelry_refinement"],
                    tooltip = locVars["options_enable_block_jewelry_refinement_tooltip"],
                    getFunc = function() return FCOISsettings.blockJewelryRefinement end,
                    setFunc = function(value) FCOISsettings.blockJewelryRefinement = value
                        FCOISsettings.autoReenable_blockJewelryRefinement = value
                    end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_jewelry_refinement"],
                    tooltip = locVars["options_auto_reenable_block_jewelry_refinement_tooltip"],
                    getFunc = function() return FCOISsettings.autoReenable_blockJewelryRefinement end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockJewelryRefinement = value
                    end,
                    disabled = function() return not FCOISsettings.blockJewelryRefinement end,
                },
				{
					type = "header",
					name = locVars["options_header_deconstruction"],
				},
			    {
					type = "checkbox",
					name = locVars["options_enable_block_deconstruction"],
					tooltip = locVars["options_enable_block_deconstruction_tooltip"],
					getFunc = function() return FCOISsettings.blockDeconstruction end,
					setFunc = function(value) FCOISsettings.blockDeconstruction = value
                           	FCOISsettings.autoReenable_blockDeconstruction = value
			        end,
				},
			    {
					type = "checkbox",
					name = locVars["options_auto_reenable_block_deconstruction"],
					tooltip = locVars["options_auto_reenable_block_deconstruction_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockDeconstruction end,
					setFunc = function(value) FCOISsettings.autoReenable_blockDeconstruction = value
			           end,
		            disabled = function() return not FCOISsettings.blockDeconstruction end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_jewelry_deconstruction"],
                    tooltip = locVars["options_enable_block_jewelry_deconstruction_tooltip"],
                    getFunc = function() return FCOISsettings.blockJewelryDeconstruction end,
                    setFunc = function(value) FCOISsettings.blockJewelryDeconstruction = value
                        FCOISsettings.autoReenable_blockJewelryDeconstruction = value
                    end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_jewelry_deconstruction"],
                    tooltip = locVars["options_auto_reenable_block_jewelry_deconstruction_tooltip"],
                    getFunc = function() return FCOISsettings.autoReenable_blockJewelryDeconstruction end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockJewelryDeconstruction = value
                    end,
                    disabled = function() return not FCOISsettings.blockJewelryDeconstruction end,
                },
				{
					type = "checkbox",
					name = locVars["options_enable_block_deconstruction_exception_intricate"],
					tooltip = locVars["options_enable_block_deconstruction_exception_intricate_tooltip"],
					getFunc = function() return FCOISsettings.allowDeconstructIntricate end,
					setFunc = function(value) FCOISsettings.allowDeconstructIntricate = value
		            end,
		            disabled = function() return not FCOISsettings.blockDeconstruction and not FCOISsettings.blockJewelryDeconstruction end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_deconstruction_exception_deconstruction"],
					tooltip = locVars["options_enable_block_deconstruction_exception_deconstruction_tooltip"],
					getFunc = function() return FCOISsettings.allowDeconstructDeconstruction end,
					setFunc = function(value) FCOISsettings.allowDeconstructDeconstruction = value
		            end,
		            disabled = function() return not FCOISsettings.blockDeconstruction and not FCOISsettings.blockJewelryDeconstruction end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_deconstruction_exception_deconstruction_all_markers"],
					tooltip = locVars["options_enable_block_deconstruction_exception_deconstruction_all_markers_tooltip"],
					getFunc = function() return FCOISsettings.allowDeconstructDeconstructionWithMarkers end,
					setFunc = function(value) FCOISsettings.allowDeconstructDeconstructionWithMarkers = value
		            end,
		            disabled = function() return (not FCOISsettings.blockDeconstruction and not FCOISsettings.blockJewelryDeconstruction) or not FCOISsettings.allowDeconstructDeconstruction end,
				},
				{
					type = "header",
					name = locVars["options_header_improvement"],
				},
			    {
					type = "checkbox",
					name = locVars["options_enable_block_improvement"],
					tooltip = locVars["options_enable_block_improvement_tooltip"],
					getFunc = function() return FCOISsettings.blockImprovement end,
					setFunc = function(value) FCOISsettings.blockImprovement = value
                           	FCOISsettings.autoReenable_blockImprovement = value
			           end,
				},
			    {
					type = "checkbox",
					name = locVars["options_auto_reenable_block_improvement"],
					tooltip = locVars["options_auto_reenable_block_improvement_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockImprovement end,
					setFunc = function(value) FCOISsettings.autoReenable_blockImprovement = value
			           end,
		            disabled = function() return not FCOISsettings.blockImprovement end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_jewelry_improvement"],
                    tooltip = locVars["options_enable_block_jewelry_improvement_tooltip"],
                    getFunc = function() return FCOISsettings.blockJewelryImprovement end,
                    setFunc = function(value) FCOISsettings.blockJewelryImprovement = value
                        FCOISsettings.autoReenable_blockJewelryImprovement = value
                    end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_jewelry_improvement"],
                    tooltip = locVars["options_auto_reenable_block_jewelry_improvement_tooltip"],
                    getFunc = function() return FCOISsettings.autoReenable_blockJewelryImprovement end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockJewelryImprovement = value
                    end,
                    disabled = function() return not FCOISsettings.blockJewelryImprovement end,
                },
				{
					type = "checkbox",
					name = locVars["options_enable_block_improvement_exception_improvement"],
					tooltip = locVars["options_enable_block_improvement_exception_improvement_tooltip"],
					getFunc = function() return FCOISsettings.allowImproveImprovement end,
					setFunc = function(value) FCOISsettings.allowImproveImprovement = value
		             end,
		            disabled = function() return not FCOISsettings.blockImprovement and not FCOISsettings.blockJewelryImprovement end,
				},
				{
					type = "header",
					name = locVars["options_header_research"],
				},
				{
					type = "checkbox",
					name = locVars["options_research_filter"],
					tooltip = locVars["options_research_filter_tooltip"],
					getFunc = function() return FCOISsettings.allowResearch end,
					setFunc = function(value) FCOISsettings.allowResearch = value
		             end,
				},
				{
					type = "header",
					name = locVars["options_header_repair"],
				},
				{
					type = "checkbox",
					name = locVars["options_allow_marked_repair"],
					tooltip = locVars["options_allow_marked_repair_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedRepairKits end,
					setFunc = function(value) FCOISsettings.blockMarkedRepairKits = value
		             end,
				},
				{
					type = "header",
					name = locVars["options_header_rune_creation"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_creation"],
					tooltip = locVars["options_enable_block_creation_tooltip"],
					getFunc = function() return FCOISsettings.blockEnchantingCreation end,
					setFunc = function(value) FCOISsettings.blockEnchantingCreation = value
                           	FCOISsettings.autoReenable_blockEnchantingCreation = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_creation"],
					tooltip = locVars["options_auto_reenable_block_creation_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockEnchantingCreation end,
					setFunc = function(value) FCOISsettings.autoReenable_blockEnchantingCreation = value
			           end,
		            disabled = function() return not FCOISsettings.blockEnchantingCreation end,
				},
				{
					type = "header",
					name = locVars["options_header_rune_extraction"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_extraction"],
					tooltip = locVars["options_enable_block_extraction_tooltip"],
					getFunc = function() return FCOISsettings.blockEnchantingExtraction end,
					setFunc = function(value) FCOISsettings.blockEnchantingExtraction = value
                           	FCOISsettings.autoReenable_blockEnchantingExtraction = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_extraction"],
					tooltip = locVars["options_auto_reenable_block_extraction_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockEnchantingExtraction end,
					setFunc = function(value) FCOISsettings.autoReenable_blockEnchantingExtraction = value
			           end,
					disabled = function() return not FCOISsettings.blockEnchantingExtraction end,
				},
				{
					type = "header",
					name = locVars["options_header_sell"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_selling"],
					tooltip = locVars["options_enable_block_selling_tooltip"],
					getFunc = function() return FCOISsettings.blockSelling end,
					setFunc = function(value) FCOISsettings.blockSelling = value
                           	FCOISsettings.autoReenable_blockSelling = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_selling"],
					tooltip = locVars["options_auto_reenable_block_selling_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockSelling end,
					setFunc = function(value) FCOISsettings.autoReenable_blockSelling = value
			           end,
		            disabled = function() return not FCOISsettings.blockSelling end,
				},
				{
					type = "checkbox",
					name = locVars["options_block_selling_exception"],
					tooltip = locVars["options_block_selling_exception_tooltip"],
					getFunc = function() return FCOISsettings.allowSellingForBlocked end,
					setFunc = function(value) FCOISsettings.allowSellingForBlocked = value
			           end,
		            disabled = function() return not FCOISsettings.blockSelling end,
				},
		        {
		            type = "checkbox",
		            name = locVars["options_block_selling_exception_intricate"],
		            tooltip = locVars["options_block_selling_exception_intricate_tooltip"],
		            getFunc = function() return FCOISsettings.allowSellingForBlockedIntricate end,
		            setFunc = function(value) FCOISsettings.allowSellingForBlockedIntricate = value
		            end,
		            disabled = function() return not FCOISsettings.blockSelling end,
		        },
		        {
		            type = "checkbox",
		            name = locVars["options_block_selling_exception_ornate"],
		            tooltip = locVars["options_block_selling_exception_ornate_tooltip"],
		            getFunc = function() return FCOISsettings.allowSellingForBlockedOrnate end,
		            setFunc = function(value) FCOISsettings.allowSellingForBlockedOrnate = value
		            end,
		            disabled = function() return not FCOISsettings.blockSelling and not FCOISsettings.blockSellingGuildStore end,
		        },
				{
					type = "header",
					name = locVars["options_header_sell_at_guild_store"],
				},
		        {
		            type = "checkbox",
		            name = locVars["options_enable_block_selling_guild_store"],
		            tooltip = locVars["options_enable_block_selling_guild_store_tooltip"],
		            getFunc = function() return FCOISsettings.blockSellingGuildStore end,
		            setFunc = function(value) FCOISsettings.blockSellingGuildStore = value
                           	FCOISsettings.autoReenable_blockSellingGuildStore = value
		            end,
		        },
		        {
		            type = "checkbox",
		            name = locVars["options_auto_reenable_block_selling_guild_store"],
		            tooltip = locVars["options_auto_reenable_block_selling_guild_store_tooltip"],
		            getFunc = function() return FCOISsettings.autoReenable_blockSellingGuildStore end,
		            setFunc = function(value) FCOISsettings.autoReenable_blockSellingGuildStore = value
		            end,
		            disabled = function() return not FCOISsettings.blockSellingGuildStore end,
		        },
				{
					type = "checkbox",
					name = locVars["options_block_selling_exception_guild_store"],
					tooltip = locVars["options_block_selling_exception_guild_store_tooltip"],
					getFunc = function() return FCOISsettings.allowSellingInGuildStoreForBlocked end,
					setFunc = function(value) FCOISsettings.allowSellingInGuildStoreForBlocked = value
			           end,
					disabled = function() return not FCOISsettings.blockSellingGuildStore end,
				},
                {
                    type = "checkbox",
                    name = locVars["options_block_selling_exception_intricate"],
                    tooltip = locVars["options_block_selling_exception_intricate_tooltip"],
                    getFunc = function() return FCOISsettings.allowSellingGuildStoreForBlockedIntricate end,
                    setFunc = function(value) FCOISsettings.allowSellingGuildStoreForBlockedIntricate = value
                    end,
                    disabled = function() return not FCOISsettings.blockSellingGuildStore end,
                },
				{
					type = "header",
					name = locVars["options_header_fence"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_fence_selling"],
					tooltip = locVars["options_enable_block_fence_selling_tooltip"],
					getFunc = function() return FCOISsettings.blockFence end,
					setFunc = function(value) FCOISsettings.blockFence = value
                           	FCOISsettings.autoReenable_blockFenceSelling = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_fence_selling"],
					tooltip = locVars["options_auto_reenable_block_fence_selling_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockFenceSelling end,
					setFunc = function(value) FCOISsettings.autoReenable_blockFenceSelling = value
			           end,
		            disabled = function() return not FCOISsettings.blockFence end,
				},
				{
					type = "header",
					name = locVars["options_header_launder"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_launder_selling"],
					tooltip = locVars["options_enable_block_launder_selling_tooltip"],
					getFunc = function() return FCOISsettings.blockLaunder end,
					setFunc = function(value) FCOISsettings.blockLaunder = value
                           	FCOISsettings.autoReenable_blockLaunderSelling = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_launder_selling"],
					tooltip = locVars["options_auto_reenable_block_launder_selling_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockLaunderSelling end,
					setFunc = function(value) FCOISsettings.autoReenable_blockLaunderSelling = value
			           end,
		            disabled = function() return not FCOISsettings.blockLaunder end,
				},
				{
					type = "header",
					name = locVars["options_header_trade"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_trading"],
					tooltip = locVars["options_enable_block_trading_tooltip"],
					getFunc = function() return FCOISsettings.blockTrading end,
					setFunc = function(value) FCOISsettings.blockTrading = value
                           	FCOISsettings.autoReenable_blockTrading = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_trading"],
					tooltip = locVars["options_auto_reenable_block_trading_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockTrading end,
					setFunc = function(value) FCOISsettings.autoReenable_blockTrading = value
			           end,
		            disabled = function() return not FCOISsettings.blockTrading end,
				},
				{
					type = "header",
					name = locVars["options_header_mail"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_sending_mail"],
					tooltip = locVars["options_enable_block_sending_mail_tooltip"],
					getFunc = function() return FCOISsettings.blockSendingByMail end,
					setFunc = function(value) FCOISsettings.blockSendingByMail = value
                           	FCOISsettings.autoReenable_blockSendingByMail = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_sending_mail"],
					tooltip = locVars["options_auto_reenable_block_sending_mail_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockSendingByMail end,
					setFunc = function(value) FCOISsettings.autoReenable_blockSendingByMail = value
			           end,
		            disabled = function() return not FCOISsettings.blockSendingByMail end,
				},
				{
					type = "header",
					name = locVars["options_header_alchemy_destroy"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_alchemy_destroy"],
					tooltip = locVars["options_enable_block_alchemy_destroy_tooltip"],
					getFunc = function() return FCOISsettings.blockAlchemyDestroy end,
					setFunc = function(value) FCOISsettings.blockAlchemyDestroy = value
                           	FCOISsettings.autoReenable_blockAlchemyDestroy = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_auto_reenable_block_alchemy_destroy"],
					tooltip = locVars["options_auto_reenable_block_alchemy_destroy_tooltip"],
					getFunc = function() return FCOISsettings.autoReenable_blockAlchemyDestroy end,
					setFunc = function(value) FCOISsettings.autoReenable_blockAlchemyDestroy = value
			           end,
		            disabled = function() return not FCOISsettings.blockAlchemyDestroy end,
				},
				{
					type = "header",
					name = locVars["options_header_containers"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_autoloot_container"],
					tooltip = locVars["options_enable_block_autoloot_container_tooltip"],
					getFunc = function() return FCOISsettings.blockAutoLootContainer end,
					setFunc = function(value) FCOISsettings.blockAutoLootContainer = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_marked_disable_with_flag"],
					tooltip = locVars["options_enable_block_marked_disable_with_flag_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedAutoLootContainerDisableWithFlag end,
					setFunc = function(value) FCOISsettings.blockMarkedAutoLootContainerDisableWithFlag = value
			           end,
                    disabled = function() return not FCOISsettings.blockAutoLootContainer end,
				},
				{
					type = "header",
					name = locVars["options_header_recipes"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_marked_recipes"],
					tooltip = locVars["options_enable_block_marked_recipes_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedRecipes end,
					setFunc = function(value) FCOISsettings.blockMarkedRecipes = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_marked_disable_with_flag"],
					tooltip = locVars["options_enable_block_marked_disable_with_flag_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedRecipesDisableWithFlag end,
					setFunc = function(value) FCOISsettings.blockMarkedRecipesDisableWithFlag = value
			           end,
				},

                {
                    type = "header",
                    name = locVars["options_header_junk"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_remove_context_menu_mark_as_junk"],
                    tooltip = locVars["options_remove_context_menu_mark_as_junk_tooltip"],
                    getFunc = function() return FCOISsettings.removeMarkAsJunk end,
                    setFunc = function(value) FCOISsettings.removeMarkAsJunk = value
                    end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_dont_unjunk_on_normal_mark"],
                    tooltip = locVars["options_dont_unjunk_on_normal_mark_tooltip"],
                    getFunc = function() return FCOISsettings.dontUnjunkOnNormalMark end,
                    setFunc = function(value) FCOISsettings.dontUnjunkOnNormalMark = value
                    end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_dont_unjunk_on_bulk_mark"],
                    tooltip = locVars["options_dont_unjunk_on_bulk_mark_tooltip"],
                    getFunc = function() return FCOISsettings.dontUnjunkOnBulkMark end,
                    setFunc = function(value) FCOISsettings.dontUnjunkOnBulkMark = value
                    end,
                },
				{
					type = "header",
					name = locVars["options_header_motifs"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_motifs"],
					tooltip = locVars["options_enable_block_motifs_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedMotifs end,
					setFunc = function(value) FCOISsettings.blockMarkedMotifs = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_marked_disable_with_flag"],
					tooltip = locVars["options_enable_block_marked_disable_with_flag_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedMotifsDisableWithFlag end,
					setFunc = function(value) FCOISsettings.blockMarkedMotifsDisableWithFlag = value
			           end,
				},
				{
					type = "header",
					name = locVars["options_header_food"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_potions"],
					tooltip = locVars["options_enable_block_potions_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedPotions end,
					setFunc = function(value) FCOISsettings.blockMarkedPotions = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_food"],
					tooltip = locVars["options_enable_block_food_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedFood end,
					setFunc = function(value) FCOISsettings.blockMarkedFood = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_marked_disable_with_flag"],
					tooltip = locVars["options_enable_block_marked_disable_with_flag_tooltip"],
					getFunc = function() return FCOISsettings.blockMarkedFoodDisableWithFlag end,
					setFunc = function(value) FCOISsettings.blockMarkedFoodDisableWithFlag = value
			           end,
				},
				{
					type = "header",
					name = locVars["options_header_guild_bank"],
				},
				{
					type = "checkbox",
					name = locVars["options_enable_block_guild_bank_without_withdraw"],
					tooltip = locVars["options_enable_block_guild_bank_without_withdraw_tooltip"],
					getFunc = function() return FCOISsettings.blockGuildBankWithoutWithdraw end,
					setFunc = function(value) FCOISsettings.blockGuildBankWithoutWithdraw = value
			           end,
				},
                {
                    type = "header",
                    name = locVars["options_header_transmutation"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_transmutation_dialog_max_withdraw"],
                    tooltip = locVars["options_enable_block_transmutation_dialog_max_withdraw_tooltip"],
                    getFunc = function() return FCOISsettings.showTransmutationGeodeLootDialog end,
                    setFunc = function(value) FCOISsettings.showTransmutationGeodeLootDialog = value
                    end,
                },
                {
                    type = "header",
                    name = locVars["options_header_crownstore"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_crownstoreitems"],
                    tooltip = locVars["options_enable_block_crownstoreitems_tooltip"],
                    getFunc = function() return FCOISsettings.blockCrownStoreItems end,
                    setFunc = function(value) FCOISsettings.blockCrownStoreItems = value
                    end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_disable_with_flag"],
                    tooltip = locVars["options_enable_block_marked_disable_with_flag_tooltip"],
                    getFunc = function() return FCOISsettings.blockMarkedCrownStoreItemDisableWithFlag end,
                    setFunc = function(value) FCOISsettings.blockMarkedCrownStoreItemDisableWithFlag = value
                    end,
                },
				{
					type = "header",
					name = locVars["options_header_anti_output_options"],
				},
			    {
					type = "checkbox",
					name = locVars["show_anti_messages_in_chat"],
					tooltip = locVars["show_anti_messages_in_chat_tooltip"],
					getFunc = function() return FCOISsettings.showAntiMessageInChat end,
					setFunc = function(value) FCOISsettings.showAntiMessageInChat = value
			           end,
				},
				{
					type = "checkbox",
					name = locVars["show_anti_messages_as_alert"],
					tooltip = locVars["show_anti_messages_as_alert_tooltip"],
					getFunc = function() return FCOISsettings.showAntiMessageAsAlert end,
					setFunc = function(value) FCOISsettings.showAntiMessageAsAlert = value
			           end,
				},
            } -- controls anti destroy
		}, -- submenu anti destroy

--==============================================================================
-- CONTEXT MENUs IN INVENTORY
		{
			type = "submenu",
			name = locVars["options_header_context_menu"],
            controls =
            {
                {
                	type = "header",
                    name = locVars["options_header_context_menu_inventory"],
                },
				{
					type = "checkbox",
					name = locVars["options_use_subcontextmenu"],
					tooltip = locVars["options_use_subcontextmenu_tooltip"],
					getFunc = function() return FCOISsettings.useSubContextMenu end,
					setFunc = function(value) FCOISsettings.useSubContextMenu = value
		            end,
				},

                {
                    type = "slider",
                    min  = 0,
                    max  = 30,
                    step = 1,
                    decimals = 0,
                    autoSelect = true,
                    name = locVars["options_contextmenu_use_dyn_submenu"],
                    tooltip = locVars["options_contextmenu_use_dyn_submenu_tooltip"],
                    getFunc = function() return FCOISsettings.useDynSubMenuMaxCount end,
                    setFunc = function(value)
                        FCOISsettings.useDynSubMenuMaxCount = value
                    end,
                    disabled = function()
                        return FCOISsettings.useSubContextMenu
                    end,
                },

				{
					type = "checkbox",
					name = locVars["options_show_contextmenu_divider"],
					tooltip = locVars["options_show_contextmenu_divider_tooltip"],
					getFunc = function() return FCOISsettings.showContextMenuDivider end,
					setFunc = function(value) FCOISsettings.showContextMenuDivider = value
		            end,
		            disabled = function() return FCOISsettings.useSubContextMenu end,
				},
				{
					type = "checkbox",
					name = locVars["options_contextmenu_divider_opens_settings"],
					tooltip = locVars["options_contextmenu_divider_opens_settings_tooltip"],
					getFunc = function() return FCOISsettings.contextMenuDividerShowsSettings end,
					setFunc = function(value)
		            	FCOISsettings.contextMenuDividerShowsSettings = value
						if FCOISsettings.contextMenuDividerShowsSettings then
		                	FCOISsettings.contextMenuDividerClearsMarkers = false
		                end
		            end,
		            disabled = function()
		            	if FCOISsettings.useSubContextMenu then
		                	return true
		                else
		                	if FCOISsettings.showContextMenuDivider then
		                    	return FCOISsettings.contextMenuDividerClearsMarkers
		                    else
		                    	return true
		                    end
		                end
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_contextmenu_divider_clears_all_markers"],
					tooltip = locVars["options_contextmenu_divider_clears_all_markers_tooltip"],
					getFunc = function() return FCOISsettings.contextMenuDividerClearsMarkers end,
					setFunc = function(value)
		            	FCOISsettings.contextMenuDividerClearsMarkers = value
						if FCOISsettings.contextMenuDividerClearsMarkers then
		                	FCOISsettings.contextMenuDividerShowsSettings = false
		                end
		            end,
		            disabled = function()
		            	if FCOISsettings.useSubContextMenu then
		                	return true
		                else
		                	if FCOISsettings.showContextMenuDivider then
		                        return FCOISsettings.contextMenuDividerShowsSettings
		                    else
		                    	return true
		                    end
		                end
		            end,
				},
				{
					type = "slider",
                    min  = 0,
                    max  = 10,
                    step = 1,
                    decimals = 0,
                    autoSelect = true,
					name = locVars["options_contextmenu_leading_spaces"],
					tooltip = locVars["options_contextmenu_leading_spaces_tooltip"],
					getFunc = function() return FCOISsettings.addContextMenuLeadingSpaces end,
					setFunc = function(value)
		            	FCOISsettings.addContextMenuLeadingSpaces = value
		            end,
		            disabled = function()
		            	return FCOISsettings.useSubContextMenu
		            end,
				},
				{
					type = "checkbox",
					name = locVars["options_contextmenu_use_custom_marked_normal_color"],
					tooltip = locVars["options_contextmenu_use_custom_marked_normal_color_tooltip"],
					getFunc = function() return FCOISsettings.useContextMenuCustomMarkedNormalColor end,
					setFunc = function(value) FCOISsettings.useContextMenuCustomMarkedNormalColor = value
		            end,
					default = FCOISdefaultSettings.useContextMenuCustomMarkedNormalColor,
		            width = "half",
				},
		        {
		            type = "colorpicker",
		            name = locVars["options_contextmenu_custom_marked_normal_color"],
		            tooltip = locVars["options_contextmenu_custom_marked_normal_color_tooltip"],
		            getFunc = function() return FCOISsettings.contextMenuCustomMarkedNormalColor.r, FCOISsettings.contextMenuCustomMarkedNormalColor.g, FCOISsettings.contextMenuCustomMarkedNormalColor.b, FCOISsettings.contextMenuCustomMarkedNormalColor.a end,
		            setFunc = function(r,g,b,a)
		                FCOISsettings.contextMenuCustomMarkedNormalColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
		            end,
		            width = "half",
		            disabled = function() return not FCOISsettings.useContextMenuCustomMarkedNormalColor end,
		            default = FCOISdefaultSettings.contextMenuCustomMarkedNormalColor,
		        },
                {
                    type = "checkbox",
                    name = locVars["options_contextmenu_leading_icon"],
                    tooltip = locVars["options_contextmenu_leading_icon_tooltip"],
                    getFunc = function() return FCOISsettings.addContextMenuLeadingMarkerIcon end,
                    setFunc = function(value) FCOISsettings.addContextMenuLeadingMarkerIcon = value
                    end,
                    default = FCOISdefaultSettings.addContextMenuLeadingMarkerIcon,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_contextmenu_use_icon_color"],
                    tooltip = locVars["options_contextmenu_use_icon_color_tooltip"],
                    getFunc = function() return FCOISsettings.contextMenuEntryColorEqualsIconColor end,
                    setFunc = function(value) FCOISsettings.contextMenuEntryColorEqualsIconColor = value
                    end,
                    default = FCOISdefaultSettings.contextMenuEntryColorEqualsIconColor,
                    width = "half",
                },
                {
                    type = "slider",
                    min  = 12,
                    max  = 40,
                    step = 2,
                    decimals = 0,
                    autoSelect = true,
                    name = locVars["options_contextmenu_leading_icon_size"],
                    tooltip = locVars["options_contextmenu_leading_icon_size_tooltip"],
                    getFunc = function() return FCOISsettings.contextMenuLeadingIconSize end,
                    setFunc = function(value)
                        FCOISsettings.contextMenuLeadingIconSize = value
                    end,
                    default = FCOISdefaultSettings.contextMenuLeadingIconSize,
                    disabled = function()
                        return not FCOISsettings.addContextMenuLeadingMarkerIcon
                    end,
                },
                --------------------------------------------------------------------------------------------------------
                {
                    type = "header",
                    name = locVars["options_header_context_menu_filter_buttons"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_split_lockdyn_filter"],
                    tooltip = locVars["options_split_lockdyn_filter_tooltip"],
                    getFunc = function() return FCOISsettings.splitLockDynFilter end,
                    setFunc = function(value) FCOISsettings.splitLockDynFilter = value
                        --Change the gear sets filter context-menu button's texture
                        local lockDynSplitFilterContextMenuButton = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_LOCKDYN], "")
                        if lockDynSplitFilterContextMenuButton ~= nil then
                            FCOIS.UpdateButtonColorsAndTextures(1, lockDynSplitFilterContextMenuButton, nil, LF_INVENTORY)
                            FCOIS.FilterBasics(true)
                        end
                    end,
                    --disabled = function() return not FCOISsettings.splitFilters end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_split_gearsets_filter"],
                    tooltip = locVars["options_split_gearsets_filter_tooltip"],
                    getFunc = function() return FCOISsettings.splitGearSetsFilter end,
                    setFunc = function(value) FCOISsettings.splitGearSetsFilter = value
                        --Change the gear sets filter context-menu button's texture
                        local gearSetSplitFilterContextMenuButton = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS], "")
                        if gearSetSplitFilterContextMenuButton ~= nil then
                            FCOIS.UpdateButtonColorsAndTextures(2, gearSetSplitFilterContextMenuButton, nil, LF_INVENTORY)
                            FCOIS.FilterBasics(true)
                        end
                    end,
                    --disabled = function() return not FCOISsettings.splitFilters end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_split_resdecimp_filter"],
                    tooltip = locVars["options_split_resdecimp_filter_tooltip"],
                    getFunc = function() return FCOISsettings.splitResearchDeconstructionImprovementFilter end,
                    setFunc = function(value) FCOISsettings.splitResearchDeconstructionImprovementFilter = value
                        --Change the gear sets filter context-menu button's texture
                        local resDecSplitFilterContextMenuButton = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_RESDECIMP], "")
                        if resDecSplitFilterContextMenuButton ~= nil then
                            FCOIS.UpdateButtonColorsAndTextures(3, resDecSplitFilterContextMenuButton, nil, LF_INVENTORY)
                            FCOIS.FilterBasics(true)
                        end
                    end,
                    --disabled = function() return not FCOISsettings.splitFilters end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_split_sellguildint_filter"],
                    tooltip = locVars["options_split_sellguildint_filter_tooltip"],
                    getFunc = function() return FCOISsettings.splitSellGuildSellIntricateFilter end,
                    setFunc = function(value) FCOISsettings.splitSellGuildSellIntricateFilter = value
                        --Change the gear sets filter context-menu button's texture
                        local sellGuildIntSplitFilterContextMenuButton = WINDOW_MANAGER:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT], "")
                        if sellGuildIntSplitFilterContextMenuButton ~= nil then
                            FCOIS.UpdateButtonColorsAndTextures(4, sellGuildIntSplitFilterContextMenuButton, nil, LF_INVENTORY)
                            FCOIS.FilterBasics(true)
                        end
                    end,
                    --disabled = function() return not FCOISsettings.splitFilters end,
                },

                {
                    type = "checkbox",
                    name = locVars["options_filter_buttons_context_menu_show_tooltip"],
                    tooltip = locVars["options_filter_buttons_context_menu_show_tooltip_tooltip"],
                    getFunc = function() return FCOISsettings.showFilterButtonContextTooltip end,
                    setFunc = function(value) FCOISsettings.showFilterButtonContextTooltip = value
                    end,
                    disabled = function()
                        if     FCOISsettings.splitLockDynFilter == false
                                and FCOISsettings.splitGearSetsFilter == false
                                and FCOISsettings.splitResearchDeconstructionImprovementFilter == false
                                and FCOISsettings.splitSellGuildSellIntricateFilter == false
                        then
                            return true
                        else
                            return false
                        end
                    end,
                },
                {
                    type = "slider",
                    min  = 0,
                    max  = FCOIS.numVars.gFCONumDynamicIcons,
                    step = 1,
                    decimals = 0,
                    autoSelect = true,
                    name = locVars["options_context_menu_filter_buttons_max_icons"],
                    tooltip = locVars["options_context_menu_filter_buttons_max_icons_tooltip"],
                    getFunc = function() return FCOISsettings.filterButtonContextMenuMaxIcons end,
                    setFunc = function(value)
                        FCOISsettings.filterButtonContextMenuMaxIcons = value
                    end,
                    default = FCOISdefaultSettings.filterButtonContextMenuMaxIcons,
                    disabled = function()
                        if     not FCOISsettings.splitLockDynFilter and not FCOISsettings.splitGearSetsFilter
                           and not FCOISsettings.splitResearchDeconstructionImprovementFilter and not FCOISsettings.splitSellGuildSellIntricateFilter then
                            return true
                        else
                            return false
                        end
                    end,
                },

            } -- controls context menu
		}, -- submenu context menu

--==============================================================================
-- ADDITIONAL BUTTONS
		{
        	type = "submenu",
			name = locVars["options_header_additional_buttons"],
            controls =
            {
				{
					type = "checkbox",
					name = locVars["options_additional_buttons_FCOIS_settings"],
					tooltip = locVars["options_additional_buttons_FCOIS_settings_tooltip"],
					getFunc = function() return FCOISsettings.showFCOISMenuBarButton end,
					setFunc = function(value) FCOISsettings.showFCOISMenuBarButton = value
			            --FCOIS.AddAdditionalButtons("FCOSettings")
		            end,
		            default = FCOISdefaultSettings.showFCOISMenuBarButton,
                    disabled = function()
                    	if VOTANS_MENU_SETTINGS and VOTANS_MENU_SETTINGS:IsMenuButtonEnabled() then
                        	return true
                        else
                        	return false
                        end
                    end
				},
		{
	       	type = "submenu",
			name = locVars["options_additional_buttons_FCOIS_additional_options"],
	           controls =
	           {
			        {
						type = "checkbox",
						name = locVars["options_additional_buttons_FCOIS_additional_options"],
						tooltip = locVars["options_additional_buttons_FCOIS_additional_options_tooltip"],
						getFunc = function() return FCOISsettings.showFCOISAdditionalInventoriesButton end,
						setFunc = function(value) FCOISsettings.showFCOISAdditionalInventoriesButton = value
		                       if value == false then
						   		--Change the button color of the context menu invoker
								FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
		                       end
				            FCOIS.AddAdditionalButtons("FCOInventoriesContextMenuButtons")
			            end,
			            default = FCOISdefaultSettings.showFCOISAdditionalInventoriesButton
					},
			        {
						type = "checkbox",
						name = locVars["options_additional_buttons_FCOIS_additional_options_colorize"],
						tooltip = locVars["options_additional_buttons_FCOIS_additional_options_colorize_tooltip"],
						getFunc = function() return FCOISsettings.colorizeFCOISAdditionalInventoriesButton end,
						setFunc = function(value) FCOISsettings.colorizeFCOISAdditionalInventoriesButton = value
					   		--Change the button color of the context menu invoker
							FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
			            end,
                        disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
			            default = FCOISdefaultSettings.colorizeFCOISAdditionalInventoriesButton
					},
                    {
                        type = "checkbox",
                        name = locVars["options_undo_use_different_filterpanels"],
                        tooltip = locVars["options_undo_use_different_filterpanels_tooltip"],
                        getFunc = function() return FCOISsettings.useDifferentUndoFilterPanels end,
                        setFunc = function(value) FCOISsettings.useDifferentUndoFilterPanels = value
                        end,
                        default = FCOISdefaultSettings.useDifferentUndoFilterPanels,
                        disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
                        width="full",
                    },
                    {
                        type = "slider",
                        min  = -500,
                        max  = 500,
                        step = 1,
                        decimals = 0,
                        autoSelect = true,
                        name = locVars["options_additional_buttons_FCOIS_additional_options_offsetx"],
                        tooltip = locVars["options_additional_buttons_FCOIS_additional_options_offsetx_tooltip"],
                        getFunc = function() return FCOISsettings.FCOISAdditionalInventoriesButtonOffset.x end,
                        setFunc = function(value)
                            FCOISsettings.FCOISAdditionalInventoriesButtonOffset.x = value
                            --Update the additional inventory "flag" invoker button positions
                            FCOIS.reAnchorAdditionalInvButtons(true)
                        end,
                        disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
                        default = FCOISdefaultSettings.FCOISAdditionalInventoriesButtonOffset.x,
                        width = "half",
                    },
                   {
                       type = "slider",
                       min  = -500,
                       max  = 500,
                       step = 1,
                       decimals = 0,
                       autoSelect = true,
                       name = locVars["options_additional_buttons_FCOIS_additional_options_offsety"],
                       tooltip = locVars["options_additional_buttons_FCOIS_additional_options_offsety_tooltip"],
                       getFunc = function() return FCOISsettings.FCOISAdditionalInventoriesButtonOffset.y end,
                       setFunc = function(value)
                           FCOISsettings.FCOISAdditionalInventoriesButtonOffset.y = value
                           --Update the additional inventory "flag" invoker button positions
                           FCOIS.reAnchorAdditionalInvButtons(true)
                       end,
                       disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
                       default = FCOISdefaultSettings.FCOISAdditionalInventoriesButtonOffset.y,
                       width = "half",
                   },

	            } -- controls additional buttons in inventories
	        }, -- submenu  additional buttons in inventories

            } -- controls additional buttons
        }, -- submenu  additional buttons
--==============================================================================
        -- CHARACTER
		{
			type = "submenu",
			name = locVars["options_header_character"],
            controls =
            {
				{
					type = "checkbox",
					name = locVars["options_tooltipatchar"],
					tooltip = locVars["options_tooltipatchar_tooltip"],
					getFunc = function() return FCOISsettings.showIconTooltipAtCharacter end,
					setFunc = function(value) FCOISsettings.showIconTooltipAtCharacter = value
		            end,
				},
				{
					type = "header",
					name = locVars["options_header_character_armor_type"],
                },
				{
					type = "checkbox",
					name = locVars["options_show_armor_type_icon"],
					tooltip = locVars["options_show_armor_type_icon_tooltip"],
					getFunc = function() return FCOISsettings.showArmorTypeIconAtCharacter end,
					setFunc = function(value) FCOISsettings.showArmorTypeIconAtCharacter = value
		            end,
				},
				{
					type = "slider",
					name = locVars["options_armor_type_icon_character_pos_x"],
					tooltip = locVars["options_armor_type_icon_character_pos_x_tooltip"],
					min = -15,
					max = 40,
                    autoSelect = true,
					getFunc = function() return FCOISsettings.armorTypeIconAtCharacterX end,
					setFunc = function(offset)
							FCOISsettings.armorTypeIconAtCharacterX = offset
							FCOIS.countAndUpdateEquippedArmorTypes()
						end,
					default = FCOISdefaultSettings.armorTypeIconAtCharacterX,
		            disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
		            width="half",
				},
				{
					type = "slider",
					name = locVars["options_armor_type_icon_character_pos_y"],
					tooltip = locVars["options_armor_type_icon_character_pos_y_tooltip"],
					min = -15,
 					max = 40,
                    autoSelect = true,
					getFunc = function() return FCOISsettings.armorTypeIconAtCharacterY end,
					setFunc = function(offset)
							FCOISsettings.armorTypeIconAtCharacterY = offset
							FCOIS.countAndUpdateEquippedArmorTypes()
						end,
					default = FCOISdefaultSettings.armorTypeIconAtCharacterY,
		            disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
		            width="half",
				},
		        {
		            type = "colorpicker",
		            name = locVars["options_armor_type_icon_character_light_color"],
		            tooltip = locVars["options_armor_type_icon_character_light_color_tooltip"],
		            getFunc = function() return FCOISsettings.armorTypeIconAtCharacterLightColor.r, FCOISsettings.armorTypeIconAtCharacterLightColor.g, FCOISsettings.armorTypeIconAtCharacterLightColor.b, FCOISsettings.armorTypeIconAtCharacterLightColor.a end,
		            setFunc = function(r,g,b,a)
		                FCOISsettings.armorTypeIconAtCharacterLightColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
						FCOIS.countAndUpdateEquippedArmorTypes()
		            end,
		            width = "full",
		            disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
		            default = FCOISdefaultSettings.armorTypeIconAtCharacterLightColor,
		        },
		        {
		            type = "colorpicker",
		            name = locVars["options_armor_type_icon_character_medium_color"],
		            tooltip = locVars["options_armor_type_icon_character_medium_color_tooltip"],
		            getFunc = function() return FCOISsettings.armorTypeIconAtCharacterMediumColor.r, FCOISsettings.armorTypeIconAtCharacterMediumColor.g, FCOISsettings.armorTypeIconAtCharacterMediumColor.b, FCOISsettings.armorTypeIconAtCharacterMediumColor.a end,
		            setFunc = function(r,g,b,a)
		                FCOISsettings.armorTypeIconAtCharacterMediumColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
						FCOIS.countAndUpdateEquippedArmorTypes()
		            end,
		            width = "full",
		            disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
		            default = FCOISdefaultSettings.armorTypeIconAtCharacterMediumColor,
		        },
		        {
		            type = "colorpicker",
		            name = locVars["options_armor_type_icon_character_heavy_color"],
		            tooltip = locVars["options_armor_type_icon_character_heavy_color_tooltip"],
		            getFunc = function() return FCOISsettings.armorTypeIconAtCharacterHeavyColor.r, FCOISsettings.armorTypeIconAtCharacterHeavyColor.g, FCOISsettings.armorTypeIconAtCharacterHeavyColor.b, FCOISsettings.armorTypeIconAtCharacterHeavyColor.a end,
		            setFunc = function(r,g,b,a)
		                FCOISsettings.armorTypeIconAtCharacterHeavyColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
						FCOIS.countAndUpdateEquippedArmorTypes()
		            end,
		            width = "full",
		            disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
		            default = FCOISdefaultSettings.armorTypeIconAtCharacterHeavyColor,
		        },
				{
					type = "checkbox",
					name = locVars["options_show_armor_type_header_text"],
					tooltip = locVars["options_show_armor_type_header_text_tooltip"],
					getFunc = function() return FCOISsettings.showArmorTypeHeaderTextAtCharacter end,
					setFunc = function(value) FCOISsettings.showArmorTypeHeaderTextAtCharacter = value
		            end,
				},
            } -- controls character
		}, -- submenu chracter
--=============================================================================================
        -- BACKUP & RESTORE
        {
            type = "submenu",
            name = locVars["options_header_backup_and_restore"],
            controls =
            {
                --Marker icons backup
                {
                    type = "header",
                    name = locVars["options_header_marking_options"],
                },
                {
                    type = "submenu",
                    name = locVars["options_backup_marker_icons"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_backup_details"],
                            tooltip = locVars["options_backup_details_tooltip"],
                            getFunc = function() return fcoBackup.withDetails end,
                            setFunc = function(value) fcoBackup.withDetails = value
                            end,
                        },
                        {
                            type = "editbox",
                            name = locVars["options_backup_apiversion"],
                            tooltip = locVars["options_backup_apiversion_tooltip"],
                            getFunc = function() return fcoBackup.apiVersion end,
                            setFunc = function(value)
                                local resetToCurrentAPI = false
                                if value ~= "" then
                                    --String only contains numbers -> Does not contain alphanumeric characters (%w = alphanumeric characters, uppercase W = unequals w)
                                    local strLen = string.len(value)
                                    local apiLength = FCOIS.APIVersionLength
                                    local numValue = tonumber(value)
                                    local onlyDigits = (numValue ~= nil and numValue > 0) or false
                                    --Input text is >= API version length
                                    if strLen == apiLength then
                                        --API version text only contains numbers?
                                        if onlyDigits then
                                            fcoBackup.apiVersion = value
                                        else
                                            resetToCurrentAPI = true
                                        end
                                    elseif strLen > apiLength then
                                        resetToCurrentAPI = true
                                    end
                                else
                                    --Preset the empty edit field with current API version
                                    resetToCurrentAPI = true
                                end
                                --Reset the edit field to current API version due to false entries?
                                if resetToCurrentAPI then
                                    value = resetBackupEditToCurrentAPI()
                                end
                            end,
                            reference = "FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT",
                            default = apiVersion,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_backup_clear"],
                            tooltip = locVars["options_backup_clear_tooltip"],
                            getFunc = function() return fcoBackup.doClearBackup end,
                            setFunc = function(value) fcoBackup.doClearBackup = value
                            end,
                        },
                        --Backup the marker icons with the help of the unique IDs of each item now!
                        {
                            type = "button",
                            name = locVars["options_backup_marker_icons"],
                            tooltip = locVars["options_backup_marker_icons_tooltip"],
                            func = function()
                                --Check the backup API version edit text and content
                                if isBackupEditAPITextTooShort() then
                                    resetBackupEditToCurrentAPI()
                                end
                                local title = locVars["options_backup_marker_icons"] .. " - API "
                                local body = locVars["options_backup_marker_icons_warning"]
                                --Show confirmation dialog
                                FCOIS.ShowConfirmationDialog("BackupMarkerIconsDialog", title .. tostring(fcoBackup.apiVersion), body, function() FCOIS.preBackup("unique", fcoBackup.withDetails, fcoBackup.apiVersion, fcoBackup.doClearBackup) end, nil, nil, nil, true)
                                --backupType, withDetails, apiVersion, doClearBackup
                                --FCOIS.preBackup("unique", fcoBackup.withDetails, fcoBackup.apiVersion, fcoBackup.doClearBackup)
                            end,
                            --isDangerous = true,
                            disabled = function() return false end,
                            warning = locVars["options_backup_marker_icons_warning"],
                            width="half",
                        },
                    },
                },
                {
                    type = "submenu",
                    name = locVars["options_restore_marker_icons"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_restore_details"],
                            tooltip = locVars["options_restore_details_tooltip"],
                            getFunc = function() return fcoRestore.withDetails end,
                            setFunc = function(value) fcoRestore.withDetails = value
                            end,
                        },
                        {
                            type = 'dropdown',
                            name = locVars["options_restore_apiversion"],
                            tooltip = locVars["options_restore_apiversion_tooltip"],
                            choices = restoreChoices,
                            choicesValues = restoreChoicesValues,
                            getFunc = function() return fcoRestore.apiVersion end,
                            setFunc = function(value)
                                fcoRestore.apiVersion = value
                            end,
                            default = apiVersion,
                            reference = "FCOITEMSAVER_SETTINGS_RESTORE_API_VERSION_DROPDOWN"
                        },
                        --Restore the marker icons with the help of the unique IDs of each item now!
                        {
                            type = "button",
                            name = locVars["options_restore_marker_icons"],
                            tooltip = locVars["options_restore_marker_icons_tooltip"],
                            func = function()
                                if fcoRestore.apiVersion ~= nil then
                                    --(restoreType, withDetails, apiVersion)
                                    --FCOIS.restoreMarkerIcons("unique", fcoRestore.withDetails, fcoRestore.apiVersion)
                                    local title = locVars["options_restore_marker_icons"] .. " - API "
                                    local body = locVars["options_restore_marker_icons_warning"]
                                    --Show confirmation dialog
                                    FCOIS.ShowConfirmationDialog("RestoreMarkerIconsDialog", title .. tostring(fcoRestore.apiVersion), body, function() FCOIS.preRestore("unique", fcoRestore.withDetails, fcoRestore.apiVersion) end, nil, nil, nil, true)
                                end
                            end,
                            --isDangerous = false,
                            disabled = function() return false end,
                            warning = locVars["options_restore_marker_icons_warning"],
                            width="half",
                        },
                        --Delete the selected backup data
                        {
                            type = "button",
                            name = locVars["options_restore_marker_icons_delete_selected"],
                            tooltip = locVars["options_restore_marker_icons_delete_selected_tooltip"],
                            func = function()
                                if fcoRestore.apiVersion ~= nil then
                                    local title = locVars["options_restore_marker_icons_delete_selected"] .. " - API "
                                    local body = locVars["options_restore_marker_icons_delete_selected_warning2"]
                                    --Show confirmation dialog
                                    FCOIS.ShowConfirmationDialog("DeleteRestoreMarkerIconsDialog", title .. tostring(fcoRestore.apiVersion), body, function() FCOIS.deleteBackup("unique", fcoRestore.apiVersion) end, nil, nil, nil, true)
                                end
                            end,
                            isDangerous = true,
                            disabled = function() return false end,
                            warning = locVars["options_restore_marker_icons_delete_selected_warning"],
                            width="half",
                        },
                    },
                },
            },
        }

	} -- END OF OPTIONS TABLE
    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", FCOLAMPanelCreated)
	FCOIS.LAM:RegisterOptionControls(FCOIS.addonVars.gAddonName .. "_LAM", optionsTable)
    --Show the LibFeedback icon top right at the LAM panel
    FCOItemSaver_LAM:SetHandler("OnEffectivelyShown", function()
        FCOIS.toggleFeedbackButton(true)
    end)
    --Hide the LibFeedBack icon
    FCOItemSaver_LAM:SetHandler("OnEffectivelyHidden", function()
        FCOIS.toggleFeedbackButton(false)
    end)
end
--==================== LAM controls - END =====================================

--==============================================================================
--============================== END SETTINGS ==================================
--==============================================================================
