--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

--Function to set the default settings
function FCOIS.buildDefaultSettings()
    --The default values for the language and save mode
    FCOIS.settingsVars.firstRunSettings = {
        language 	 		    = 1, --Standard: English
        saveMode     		    = 2, --Standard: Account wide FCOIS settings (1=Each character, 2=Account wide, 3=All accounts the same)
    }

    --Pre-set the deafult values
    FCOIS.settingsVars.defaults = {
		languageChosen				= false,
		alwaysUseClientLanguage		= true,
		rememberUserAboutSavedVariablesBackup = true,
		markedItems	 		    	= {},
		icon		 		    	= {},
		iconPosition				= {},
		iconPositionCrafting		= {},
		iconPositionCharacter		= {},
		iconSortOrder				= {},
		filterButtonLeft			= {},
		filterButtonTop				= {},
		filterButtonData			= {},
		splitFilters				= true, -- always true since version 0.8.7. Support for non-split filter buttons is obsolete since then
		isFilterOn   		   	 	= {false, false, false, false},
		isFilterPanelOn				= {},
		atPanelEnabled				= {},
		isIconEnabled				= {},
		lastLockDynFilterIconId		 = {},
		lastGearFilterIconId		 = {},
		lastResDecImpFilterIconId	 = {},
		lastSellGuildIntFilterIconId = {},
		allowResearch 		    	= true,
		allowDeconstructIntricate	= true,
		allowDeconstructDeconstruction = true,
		allowDeconstructDeconstructionWithMarkers = false,
		allowInventoryFilter    	= true,
		allowCraftBagFilter			= true,
		allowVendorBuyFilter	    = false,
		allowVendorFilter	    	= true,
		allowVendorBuybackFilter   	= false,
		allowVendorRepairFilter	   	= false,
		allowFenceFilter			= true,
		allowLaunderFilter			= true,
		allowGuildBankFilter    	= true,
		allowBankFilter 	    	= true,
		allowTradinghouseFilter		= true,
		allowTradeFilter	   	 	= true,
		allowMailFilter		    	= true,
		allowEnchantingFilter		= true,
		allowRefinementFilter		= true,
		allowJewelryRefinementFilter = true,
		allowDeconstructionFilter	= true,
		allowJewelryDeconstructionFilter = true,
		allowImprovementFilter  	= true,
		allowJewelryImprovementFilter = true,
		allowResearchFilter  		= true,
		allowJewelryResearchFilter  = true,
		allowAlchemyFilter			= true,
        allowRetraitFilter          = true,
        allowOnlyUnbound            = {},
		blockMarkedRepairKits		= false,
		blockDestroying				= true,
		blockRefinement				= true,
		blockDeconstruction			= true,
		blockImprovement			= true,
        blockResearch               = true,
		blockResearchDialog  		= true,
		blockJewelryRefinement		= true,
		blockJewelryDeconstruction	= true,
		blockJewelryImprovement		= true,
        blockJewelryResearch        = true,
		blockJewelryResearchDialog  = true,
        blockSendingByMail			= true,
		blockTrading				= true,
		blockVendorBuy				= false,
		blockSelling				= true,
		blockVendorBuyback			= false,
		blockVendorRepair			= false,
		blockSellingGuildStore      = true,
		blockFence					= true,
		blockLaunder				= true,
		blockRetrait				= true,
		removeMarkAsJunk			= false,
		allowMarkAsJunkForMarkedToBeSold = true,
        dontUnjunkOnBulkMark        = false,
		dontUnjunkOnNormalMark		= false,
		junkItemsMarkedToBeSold		= false,
		dontUnJunkItemsMarkedToBeSold = false,
		allowSellingForBlocked		= true,
		allowSellingForBlockedOrnate = true,
		allowSellingForBlockedIntricate = false,
		allowSellingGuildStoreForBlockedIntricate = false,
		allowImproveImprovement		= true,
		blockEnchantingCreation		= true,
		blockEnchantingExtraction	= true,
		blockAlchemyDestroy			= true,
		blockAutoLootContainer		= true,
		blockMarkedAutoLootContainerDisableWithFlag = false,
		blockMarkedRecipes			= true,
		blockMarkedRecipesDisableWithFlag = false,
		blockMarkedMotifs			= true,
		blockMarkedMotifsDisableWithFlag = false,
		blockMarkedPotions			= false,
		blockMarkedFood			    = false,
		blockMarkedFoodDisableWithFlag = false,
		blockMarkedCrownStoreItemDisableWithFlag = false,
		blockGuildBankWithoutWithdraw = true,
		blockGuildBankWithoutWithdrawDisableWithFlag = false,
		blockSpecialItemsEnchantment = true,
		blockCrownStoreItems		= false,
		checkDeactivatedIcons		= false,
		autoReenable_blockDestroying			= true,
		autoReenable_blockRefinement 			= true,
		autoReenable_blockDeconstruction		= true,
		autoReenable_blockImprovement			= true,
		autoReenable_blockJewelryRefinement 	= true,
		autoReenable_blockJewelryDeconstruction	= true,
		autoReenable_blockJewelryImprovement	= true,
		autoReenable_blockSendingByMail			= true,
		autoReenable_blockTrading				= true,
		autoReenable_blockVendorBuy				= true,
		autoReenable_blockSelling				= true,
		autoReenable_blockVendorBuyback			= true,
		autoReenable_blockVendorRepair			= true,
		autoReenable_blockSellingGuildStore		= true,
		autoReenable_blockFenceSelling			= true,
		autoReenable_blockLaunderSelling		= true,
		autoReenable_blockEnchantingCreation	= true,
		autoReenable_blockEnchantingExtraction	= true,
		autoReenable_blockAlchemyDestroy		= true,
		autoReenable_blockRetrait				= true,
		autoReenable_blockGuildBankWithoutWithdraw = true,
		autoMarkNewItems			= false,
        autoMarkNewIconNr           = FCOIS_CON_ICON_LOCK,
		autoMarkOrnate 		    	= false,
		autoMarkIntricate           = false,
		autoMarkResearch			= false,
		autoMarkResearchOnlyLoggedInChar = false,
		researchAddonUsed			= FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT, --Default research marking addon: ResearchAssistant
		autoMarkQuality				= 1,
		autoMarkQualityIconNr		= FCOIS_CON_ICON_LOCK,
		autoMarkHigherQuality		= false,
		autoMarkQualityCheckAllIcons = false,
		autoMarkAllEquipment		= true,
		autoMarkAllWeapon			= false,
		autoMarkAllJewelry			= false,
		autoMarkRecipes 			= false,
		autoMarkKnownRecipes 		= false,
		recipeAddonUsed				= FCOIS_RECIPE_ADDON_SOUSCHEF, --Default recipe marking addon: SousChef
		autoMarkRecipesOnlyThisChar = false,
		autoMarkRecipesIconNr		= FCOIS_CON_ICON_LOCK,
		allowedCraftSkillsForCraftedMarking = {
			[CRAFTING_TYPE_ALCHEMY] 		= false,
			[CRAFTING_TYPE_BLACKSMITHING] 	= true,
			[CRAFTING_TYPE_CLOTHIER] 		= true,
			[CRAFTING_TYPE_ENCHANTING] 		= true,
			[CRAFTING_TYPE_INVALID] 		= false,
			[CRAFTING_TYPE_PROVISIONING] 	= false,
			[CRAFTING_TYPE_WOODWORKING] 	= true,
			[CRAFTING_TYPE_JEWELRYCRAFTING] = true,
		},
		autoMarkCraftedItems		= false,
        autoMarkCraftedWritItems	= false,
		autoMarkCraftedItemsIconNr	= FCOIS_CON_ICON_LOCK,
		autoMarkCraftedWritCreatorItemsIconNr = FCOIS_CON_ICON_LOCK,
        autoMarkCraftedWritCreatorMasterWritItemsIconNr = FCOIS_CON_ICON_LOCK,
		autoMarkCraftedItemsSets	= false,
		autoMarkSets				= false,
		autoMarkSetsIconNr			= FCOIS_CON_ICON_GEAR_1,
		autoMarkSetsCheckAllIcons 	= false,
		autoMarkSetsCheckAllGearIcons = true,
		autoMarkSetsCheckAllSetTrackerIcons = false,
		autoMarkSetsCheckSellIcons = false,
		autoMarkSetsCheckArmorTrait 		= {},
		autoMarkSetsCheckJewelryTrait 		= {},
		autoMarkSetsCheckWeaponTrait 		= {},
        autoMarkSetsCheckArmorTraitIcon 	= {},
        autoMarkSetsCheckJewelryTraitIcon	= {},
        autoMarkSetsCheckWeaponTraitIcon	= {},
		autoMarkSetsNonWished 				= false,
		autoMarkSetsNonWishedIconNr			= FCOIS_CON_ICON_DECONSTRUCTION,
		autoMarkSetsNonWishedIfCharBelowLevel = false,
        autoMarkSetsNonWishedChecks         = FCOIS_CON_NON_WISHED_LEVEL,
        autoMarkSetsNonWishedSellOthers     = true,
		autoMarkSetsNonWishedQuality 		= 1,
		autoMarkSetsNonWishedLevel			= 1,
		autoMarkSetsWithTraitIfAutoSetMarked = true,
		autoMarkSetsOnlyTraits				= false,
        autoMarkSetsWithTraitCheckAllIcons  = false,
        autoMarkSetsWithTraitCheckAllGearIcons = false,
        autoMarkSetsWithTraitCheckAllSetTrackerIcons = false,
        autoMarkSetsWithTraitCheckSellIcons = false,
		autoMarkSetTrackerSets				= false,
		autoMarkSetTrackerSetsCheckAllIcons = false,
		autoMarkSetTrackerSetsInv			= true,
		autoMarkSetTrackerSetsBank			= false,
		autoMarkSetTrackerSetsGuildBank		= false,
		autoMarkSetTrackerSetsWorn			= false,
		autoMarkSetTrackerSetsShowTooltip	= false,
		autoMarkSetTrackerSetsRescan		= false,
		setTrackerIndexToFCOISIcon			= {},
		autoMarkWastedResearchScrolls		= true,
		autoDeMarkSell				= false,
		autoDeMarkSellInGuildStore	= false,
		autoDeMarkSellOnOthers		= false,
		autoDeMarkSellGuildStoreOnOthers = false,
		autoDeMarkDeconstruct		= false,
		autoMarkPreventIfMarkedForSell = false,
		autoMarkPreventIfMarkedForDeconstruction = false,
		showFilterStatusInChat  	= false,
		showOrnateItemsInChat   	= false,
		showIntricateItemsInChat     = false,
		showResearchItemsInChat 	= false,
		showSetsInChat 				= false,
		showQualityItemsInChat		= false,
		showRecipesInChat			= false,
		showFCOISMenuBarButton		= true,
		showFCOISAdditionalInventoriesButton = true,
		colorizeFCOISAdditionalInventoriesButton = true,
		FCOISAdditionalInventoriesButtonOffset = {},
		showFilterButtonTooltip		= true,
		showFilterButtonContextTooltip = true,
		showAntiMessageInChat		= true,
		showAntiMessageAsAlert		= true,
		showMarkerTooltip			= {},
		askBeforeEquipBoundItems	= true,
		splitLockDynFilter			= true,
		splitGearSetsFilter			= true,
		splitResearchDeconstructionImprovementFilter = true,
		splitSellGuildSellIntricateFilter = true,
		showIconTooltipAtCharacter	= true,
		useSubContextMenu			= false,
		showContextMenuDivider		= true,
		contextMenuDividerShowsSettings = false,
		contextMenuDividerClearsMarkers = true,
		contextMenuClearMarkesByShiftKey = false,
		addContextMenuLeadingSpaces	 = 0,
		useContextMenuCustomMarkedNormalColor = true,
		contextMenuCustomMarkedNormalColor = {["r"] = 1,["g"] = 0,["b"] = 0,["a"] = 1},
		contextMenuItemEntryShowTooltip	= false,
		contextMenuItemEntryShowTooltipWithSHIFTKeyOnly = false,
		contextMenuItemEntryTooltipProtectedPanels	= false,
		showArmorTypeIconAtCharacter = false,
		armorTypeIconAtCharacterX	 = 15,
		armorTypeIconAtCharacterY	 = 15,
		armorTypeIconAtCharacterLightColor  = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1},
		armorTypeIconAtCharacterMediumColor = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1},
		armorTypeIconAtCharacterHeavyColor  = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1},
		showArmorTypeHeaderTextAtCharacter = false,
		disableResearchCheck 		= {},
		cycleMarkerSymbolOnKeybind	= false,
		standardIconOnKeybind		= FCOIS_CON_ICON_LOCK,
		useZOsLockFunctions			= true,
		showBoundItemMarker			= false,
		--Test hooks
        testHooks					= false,
		--Debugging
		debug						= false,
		deepDebug					= false,
		debugDepth					= 1,
		useUniqueIds				= false,
        useUniqueIdsToggle          = nil,
		showFilteredItemCount		= false,
		showTransmutationGeodeLootDialog = true,
		addContextMenuLeadingMarkerIcon = true,
		contextMenuLeadingIconSize = 22,
		contextMenuEntryColorEqualsIconColor = true,
        useDynSubMenuMaxCount = 11,
		backupData = {},
        doBackupAfterJumpToHouse = false,
        backupParams = {},
		iconIsGear = {
            [FCOIS_CON_ICON_GEAR_1] = true,
            [FCOIS_CON_ICON_GEAR_2] = true,
            [FCOIS_CON_ICON_GEAR_3] = true,
            [FCOIS_CON_ICON_GEAR_4] = true,
            [FCOIS_CON_ICON_GEAR_5] = true,
        },
		filterButtonContextMenuMaxIcons = 6,
		useDifferentUndoFilterPanels = true,
		-- Added with FCOIS v1.5.2. Value of addonFCOISChangedDynIconMaxUsableSlider = nil to assure checks in file src/FCOIS_Settings.lua, function afterSettings()!
		numMaxDynamicIconsUsable = 10,
		addonFCOISChangedDynIconMaxUsableSlider = nil, --Set the value of settings.addonFCOISChangedDynIconMaxUsableSlider to nil to repeat checks after addon updates in file src/FCOIS_Settings.lua, function afterSettings()!
		autoMarkPreventIfMarkedForSellAtGuildStore = false,
		autoMarkKnownRecipesIconNr = FCOIS_CON_ICON_SELL_AT_GUILDSTORE,
		sortIconsInAdditionalInvFlagContextMenu = false,
		keybindMoveMarkedForSellToJunkEnabled = true,
		keybindMoveItemToJunkEnabled = false,
		keybindMoveItemToJunkAddSellIcon = false,
    }
    --Local constant values for speed-up
    local numLibFiltersFilterPanelIds   = FCOIS.numVars.gFCONumFilterInventoryTypes
    local activeFilterPanelIds          = FCOIS.mappingVars.activeFilterPanelIds
    local numFilterIcons                = FCOIS.numVars.gFCONumFilterIcons
    local filterButtonsToCheck          = FCOIS.checkVars.filterButtonsToCheck
   -- local numNonDynamicAndGearIcons     = FCOIS.numVars.gFCONumNonDynamicAndGearIcons
    local numMaxDynIcons                = FCOIS.numVars.gFCOMaxNumDynamicIcons
    local iconIsDynamic                 = FCOIS.mappingVars.iconIsDynamic
    local iconIdToDynIcon               = FCOIS.mappingVars.dynamicToIcon
    local iconNrToOrdinalStr            = FCOIS.mappingVars.iconNrToOrdinalStr

	--For each panel id that is active
    for libFiltersFilterPanelIdHelper = 1, numLibFiltersFilterPanelIds, 1 do
		if activeFilterPanelIds[libFiltersFilterPanelIdHelper] == true then
			--Create 2-dimensional arrays for the filters
		    FCOIS.settingsVars.defaults.isFilterPanelOn[libFiltersFilterPanelIdHelper] = {false, false, false, false}
		    --Create 2-dimensional array for the "enabled" setings (Filters, Anti-Destroy, Anti-Deconstruction, Anti-Sell, Anti-Trade, Anti-Mail, etc.)
		    FCOIS.settingsVars.defaults.atPanelEnabled[libFiltersFilterPanelIdHelper]	= {
		        ["filters"] 		 = false,
--			    ["anti-destroy"] 	 = false,
--			    ["anti-deconstruct"] = false,
--				["anti-improve"]	 = false,
--				["anti-sell"]	 	 = false,
--				["anti-sell-exception"] = false,
--				["anti-trade"] 		 = false,
--				["anti-mail"] 		 = false,
--				["anti-fence"] 		 = false,
--				["anti-launder"]	 = false,
	        }
			--Create the helper arays for the filter button context menus
			FCOIS.settingsVars.defaults.lastLockDynFilterIconId[libFiltersFilterPanelIdHelper]		= -1
            FCOIS.settingsVars.defaults.lastGearFilterIconId[libFiltersFilterPanelIdHelper] 		= -1
            FCOIS.settingsVars.defaults.lastResDecImpFilterIconId[libFiltersFilterPanelIdHelper] 	= -1
            FCOIS.settingsVars.defaults.lastSellGuildIntFilterIconId[libFiltersFilterPanelIdHelper]= -1
			--Create 2-dimensional array for the UNDO functions from the addiitonal inventory context menu (flag) menu
			FCOIS.contextMenuVars.undoMarkedItems[libFiltersFilterPanelIdHelper] = {}
		end
		--FCOIS version 1.6.7
		--Add the default additional inventory context menu "flag" button values for each filter panel ID
		FCOIS.settingsVars.defaults.FCOISAdditionalInventoriesButtonOffset[libFiltersFilterPanelIdHelper] = {
			["top"] = 0,
			["left"] = 0,
		}
    end
	--Create 2-dimensional arrays for the icons
	local dynamicCounter = 0
	local defaultIconOffsets = {
		["left"] 	= 0,
		["top"] 	= 0,
	}
	for filterIconHelper = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
       --Marker icons in inventories
       	FCOIS.settingsVars.defaults.markedItems[filterIconHelper] 	= {}
        --Defaults for filter button offsets
        FCOIS.settingsVars.defaults.filterButtonTop[filterIconHelper]  = FCOIS.filterButtonVars.gFilterButtonTop
        FCOIS.settingsVars.defaults.filterButtonLeft[filterIconHelper] = FCOIS.filterButtonVars.gFilterButtonLeft[filterIconHelper]

        --General icon information
        FCOIS.settingsVars.defaults.icon[filterIconHelper] 		  	= {}
	    FCOIS.settingsVars.defaults.icon[filterIconHelper].antiCheckAtPanel = {}
		FCOIS.settingsVars.defaults.icon[filterIconHelper].demarkAllOthers = false --added with FCOIS 1.5.2
		FCOIS.settingsVars.defaults.icon[filterIconHelper].demarkAllOthersExcludeDynamic = false
		--Icon offsets in inventories etc. (FCOIS v1.6.8)
		FCOIS.settingsVars.defaults.icon[filterIconHelper].offsets = {}
		--For each filterPanelId do some checks and add icon default settings data:
		for filterIconHelperPanel = 1, numLibFiltersFilterPanelIds, 1 do
			--FCOIS v1.6.8
			--For each filterPanelId add the icon offsets table
			FCOIS.settingsVars.defaults.icon[filterIconHelper].offsets[filterIconHelperPanel] = defaultIconOffsets

			--FCOIS v.1.4.4 - Research dialog panels need to be protected as default value as they were added new with this version
			local valueToSet = false
			if filterIconHelperPanel == LF_SMITHING_RESEARCH_DIALOG or filterIconHelperPanel == LF_JEWELRY_RESEARCH_DIALOG then
				valueToSet = true
			end
			FCOIS.settingsVars.defaults.icon[filterIconHelper].antiCheckAtPanel[filterIconHelperPanel] = valueToSet
        end

        --Defaults for research check is "false", except for dynamic icons where it is "true"
		local defResearchCheck = false
		local isIconDynamic = iconIsDynamic[filterIconHelper]
		if isIconDynamic then defResearchCheck = true end
        FCOIS.settingsVars.defaults.disableResearchCheck[filterIconHelper] = defResearchCheck
        if isIconDynamic then
            FCOIS.settingsVars.defaults.icon[filterIconHelper].temporaryDisableByInventoryFlagIcon = false
        end

        --Defaults for the enabling/disabling of the icons
        local enabledVar = true
		--Only enable the first three dyanmic icons by default
		if isIconDynamic then
			dynamicCounter = dynamicCounter + 1
			if dynamicCounter > 3 then
				enabledVar = false
			end
		end
		FCOIS.settingsVars.defaults.isIconEnabled[filterIconHelper] = enabledVar

        --Defaults for the marker icon tooltips
        if FCOIS.settingsVars.defaults.showMarkerTooltip[filterIconHelper] == nil then
	        FCOIS.settingsVars.defaults.showMarkerTooltip[filterIconHelper] = true
        end

        --Defaults for allow only unbound items to be marked
        --Introduced with FCOIS version 1.0.6
        FCOIS.settingsVars.defaults.allowOnlyUnbound[filterIconHelper] = false

        --Fill the missing icon numbers to the isGearSet table so they exist with a "false" value as "non gear" entries
        local isStaticGearIcon = FCOIS.mappingVars.isStaticGearIcon
        if FCOIS.settingsVars.defaults.iconIsGear[filterIconHelper] == nil then
            FCOIS.settingsVars.defaults.iconIsGear[filterIconHelper] = false
        end
        --Always set the 5 static gear icons to "true"
        if isStaticGearIcon[filterIconHelper] ~= nil and isStaticGearIcon[filterIconHelper] then
            FCOIS.settingsVars.defaults.iconIsGear[filterIconHelper] = true
        end
    end -- for filter icons ...
	--Preset the default icon colors, textures and sort orders
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_LOCK].color   = {["r"] = 1,["g"] = 0,["b"] = 0,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_LOCK].texture = 1
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_LOCK].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_LOCK].sortOrder = 1
    FCOIS.settingsVars.defaults.iconSortOrder[1] = FCOIS_CON_ICON_LOCK

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_1].color   = {["r"] = 0,["g"] = 1,["b"] = 0,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_1].texture = 2
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_1].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_1].sortOrder = 8
    FCOIS.settingsVars.defaults.iconSortOrder[2] = FCOIS_CON_ICON_RESEARCH

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_RESEARCH].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_RESEARCH].texture = 3
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_RESEARCH].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_RESEARCH].sortOrder = 2
    FCOIS.settingsVars.defaults.iconSortOrder[3] = FCOIS_CON_ICON_SELL

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_2].color   = {["r"] = 1,["g"] = 0,["b"] = 1,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_2].texture = 2
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_2].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_2].sortOrder = 9
    FCOIS.settingsVars.defaults.iconSortOrder[4] = FCOIS_CON_ICON_DECONSTRUCTION

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL].color   = {["r"] = 1,["g"] = 1,["b"] = 0,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL].texture = 4
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL].sortOrder = 3
    FCOIS.settingsVars.defaults.iconSortOrder[5] = FCOIS_CON_ICON_IMPROVEMENT

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_3].color   = {["r"] = 1,["g"] = 1,["b"] = 0,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_3].texture = 2
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_3].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_3].sortOrder = 10
    FCOIS.settingsVars.defaults.iconSortOrder[6] = FCOIS_CON_ICON_SELL_AT_GUILDSTORE

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_4].color   = {["r"] = 1,["g"] = 1,["b"] = 0,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_4].texture = 2
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_4].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_4].sortOrder = 11
    FCOIS.settingsVars.defaults.iconSortOrder[7] = FCOIS_CON_ICON_INTRICATE

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_5].color   = {["r"] = 1,["g"] = 1,["b"] = 0,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_5].texture = 2
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_5].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_5].sortOrder = 12
    FCOIS.settingsVars.defaults.iconSortOrder[8] = FCOIS_CON_ICON_GEAR_1

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DECONSTRUCTION].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DECONSTRUCTION].texture = 55
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DECONSTRUCTION].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DECONSTRUCTION].sortOrder = 4
    FCOIS.settingsVars.defaults.iconSortOrder[9] = FCOIS_CON_ICON_GEAR_2

	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_IMPROVEMENT].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_IMPROVEMENT].texture = 56
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_IMPROVEMENT].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_IMPROVEMENT].sortOrder = 5
    FCOIS.settingsVars.defaults.iconSortOrder[10] = FCOIS_CON_ICON_GEAR_3

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color   = {["r"] = 1,["g"] = 1,["b"] = 0,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].texture = 58
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].sortOrder = 6
    FCOIS.settingsVars.defaults.iconSortOrder[11] = FCOIS_CON_ICON_GEAR_4

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_INTRICATE].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_INTRICATE].texture = 60
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_INTRICATE].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_INTRICATE].sortOrder = 7
    FCOIS.settingsVars.defaults.iconSortOrder[12] = FCOIS_CON_ICON_GEAR_5

------Dynamic icons ---------------------------------------------------------------------------------------------------
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_1].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_1].texture = 46
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_1].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_1].sortOrder = 13
    FCOIS.settingsVars.defaults.iconSortOrder[13] = FCOIS_CON_ICON_DYNAMIC_1

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_2].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_2].texture = 47
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_2].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_2].sortOrder = 14
    FCOIS.settingsVars.defaults.iconSortOrder[14] = FCOIS_CON_ICON_DYNAMIC_2

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_3].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_3].texture = 48
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_3].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_3].sortOrder = 15
    FCOIS.settingsVars.defaults.iconSortOrder[15] = FCOIS_CON_ICON_DYNAMIC_3

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_4].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_4].texture = 49
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_4].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_4].sortOrder = 16
    FCOIS.settingsVars.defaults.iconSortOrder[16] = FCOIS_CON_ICON_DYNAMIC_4

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_5].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_5].texture = 50
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_5].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_5].sortOrder = 17
    FCOIS.settingsVars.defaults.iconSortOrder[17] = FCOIS_CON_ICON_DYNAMIC_5

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_6].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_6].texture = 51
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_6].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_6].sortOrder = 18
    FCOIS.settingsVars.defaults.iconSortOrder[18] = FCOIS_CON_ICON_DYNAMIC_6

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_7].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_7].texture = 52
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_7].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_7].sortOrder = 19
    FCOIS.settingsVars.defaults.iconSortOrder[19] = FCOIS_CON_ICON_DYNAMIC_7

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_8].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_8].texture = 53
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_8].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_8].sortOrder = 20
    FCOIS.settingsVars.defaults.iconSortOrder[20] = FCOIS_CON_ICON_DYNAMIC_8

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_9].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_9].texture = 54
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_9].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_9].sortOrder = 21
    FCOIS.settingsVars.defaults.iconSortOrder[21] = FCOIS_CON_ICON_DYNAMIC_9

    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_10].color   = {["r"] = 1,["g"] = 1,["b"] = 1,["a"] = 1}
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_10].texture = 55
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_10].size    = FCOIS.iconVars.gIconWidth
    FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_10].sortOrder = 22
    FCOIS.settingsVars.defaults.iconSortOrder[22] = FCOIS_CON_ICON_DYNAMIC_10

	--Add the next 20 default values for the dynamic icons (11 to 30)
	local currentIconSortOrder = FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_DYNAMIC_10].sortOrder
	for dynIconId=11, numMaxDynIcons, 1 do
		local dynIconNumber = iconIdToDynIcon[dynIconId]
		if iconIsDynamic[dynIconNumber] then
			currentIconSortOrder = currentIconSortOrder + 1
			FCOIS.settingsVars.defaults.icon[dynIconNumber].color   = {["r"] = 1,["g"] = 0,["b"] = 0,["a"] = 1}
			FCOIS.settingsVars.defaults.icon[dynIconNumber].texture = 1
			FCOIS.settingsVars.defaults.icon[dynIconNumber].size    = FCOIS.iconVars.gIconWidth
			FCOIS.settingsVars.defaults.icon[dynIconNumber].sortOrder = currentIconSortOrder
			FCOIS.settingsVars.defaults.iconSortOrder[currentIconSortOrder] = dynIconNumber
		end
	end

	--Preset the default icon positions (inventories and character)
    FCOIS.settingsVars.defaults.iconPosition.x		 	=	0
    FCOIS.settingsVars.defaults.iconPosition.y		 	=	0
    FCOIS.settingsVars.defaults.iconPositionCrafting.x 	=	-5
    FCOIS.settingsVars.defaults.iconPositionCrafting.y 	=	0
    FCOIS.settingsVars.defaults.iconPositionCharacter.x	=   0
    FCOIS.settingsVars.defaults.iconPositionCharacter.y	=	0

	--Update the "Gear sets" texts depending on locaization
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_1].name    = "Gear 1"
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_2].name    = "Gear 2"
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_3].name    = "Gear 3"
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_4].name    = "Gear 4"
	FCOIS.settingsVars.defaults.icon[FCOIS_CON_ICON_GEAR_5].name    = "Gear 5"

	--Update the "Dynamic icon" texts depending on localization
    for dynIconNr=1, numMaxDynIcons, 1 do
        --Use english ordinals
        local iconToOrdinalStrDynEn = iconNrToOrdinalStr[1][tonumber(dynIconNr)] or "th"
        local dynIconStr = tostring(dynIconNr).. iconToOrdinalStrDynEn
		FCOIS.settingsVars.defaults.icon[_G["FCOIS_CON_ICON_DYNAMIC_" .. tostring(dynIconNr)]].name     = dynIconStr .. " dynamic"
    end

    --New filter button data settings -> since FCOIS version 1.4.4
    for _, filterButtonNr in ipairs(filterButtonsToCheck) do
        --Initialize the default settings
        FCOIS.settingsVars.defaults.filterButtonData[filterButtonNr] = FCOIS.settingsVars.defaults.filterButtonData[filterButtonNr] or {}
        for filterIconHelperPanel = 1, numLibFiltersFilterPanelIds, 1 do
            --Create a subtable in the filterIcon data for each libFiltersFilterPanelId
            FCOIS.settingsVars.defaults.filterButtonData[filterButtonNr][filterIconHelperPanel] = FCOIS.settingsVars.defaults.filterButtonData[filterButtonNr][filterIconHelperPanel]
                or  {
                ["left"]    = FCOIS.filterButtonVars.gFilterButtonLeft[filterButtonNr],
                ["top"]     = FCOIS.filterButtonVars.gFilterButtonTop,
                ["width"]   = FCOIS.filterButtonVars.gFilterButtonWidth,
                ["height"]  = FCOIS.filterButtonVars.gFilterButtonHeight,
            }
        end
    end
end
