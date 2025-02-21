--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local tos = tostring

local currentCharId       = GetCurrentCharacterId()

--Function to set the default settings
function FCOIS.BuildDefaultSettings()
	--The default values for the language and save mode
	FCOIS.settingsVars.firstRunSettings = {
		language 	 		    = 1, --Standard: English
		saveMode     		    = 2, --Standard: Account wide FCOIS settings (1=Each character, 2=Account wide, 3=All accounts the same)
		--Save the filter buttons for each character individually
		filterButtonsSaveForCharacter = false,
	}

	--Pre-set the deafult values
	FCOIS.settingsVars.defaults = {
		languageChosen				= false,
		alwaysUseClientLanguage		= true,
		remindUserAboutSavedVariablesBackup = true,
		--markedItems	 		    	= {}, --> moved down to use dynamic name of the table entry
		icon		 		    	= {},
		iconPosition				= {},
		iconPositionCrafting		= {},
		iconPositionCharacter		= {},
		iconSizeCharacter			= 20,
		iconSortOrder				= {},
		iconSortOrderEntries		= {},
		filterButtonLeft			= {},
		filterButtonTop				= {},
		filterButtonData			= {},
		filterButtonSettings  = { --FCOIS v2.2.4 2021-11-15
		},
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
		allowCompanionInventoryFilter = true,
		allowOnlyUnbound            = {},
		blockMarkedRepairKits		= false,
		blockMarkedGlyphs			= true,
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
		autoMarkBagsToScan = {
			[BAG_BACKPACK] = true,
			[BAG_BANK] = true,
			[BAG_GUILDBANK] = true,
			[BAG_HOUSE_BANK_ONE] = true,
		},
		autoMarkBagsToScanOrder = {
			[1] = {
				value 		= BAG_BACKPACK,
				uniqueKey 	= LF_INVENTORY,
				--text  		= locVars["FCOIS_LibFilters_PanelIds"][LF_INVENTORY],
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_INVENTORY],

			},
			[2] = {
				value 		= BAG_BANK,
				uniqueKey 	= LF_BANK_WITHDRAW,
				--text  		= locVars["FCOIS_LibFilters_PanelIds"][LF_BANK_WITHDRAW],
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_BANK_WITHDRAW],
			},
			[3] = {
				value 		= BAG_GUILDBANK,
				uniqueKey 	= LF_GUILDBANK_WITHDRAW,
				--text  		= locVars["FCOIS_LibFilters_PanelIds"][LF_GUILDBANK_WITHDRAW],
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_GUILDBANK_WITHDRAW],
			},
			[4] = {
				value 		= BAG_HOUSE_BANK_ONE,
				uniqueKey 	= LF_HOUSE_BANK_WITHDRAW,
				--text  		= locVars["FCOIS_LibFilters_PanelIds"][LF_HOUSE_BANK_WITHDRAW],
				--tooltip 	= locVars["FCOIS_LibFilters_PanelIds"][LF_HOUSE_BANK_WITHDRAW],
			},
		},
		autoMarkBagsChatOutput		= false,
		autoMarkNewItems			= false,
		autoMarkNewIconNr           = FCOIS_CON_ICON_LOCK,
		autoMarkNewItemsCheckOthers = false,
		autoMarkOrnate 		    	= false,
		autoMarkIntricate           = false,
		autoMarkResearch			= false,
		autoMarkResearchOnlyLoggedInChar = false,
		autoMarkResearchCheckAllIcons = false,
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
		autoMarkMotifs				= false, --#308
		autoMarkKnownMotifs 		= false, --#308
		motifsAddonUsed 			= FCOIS_MOTIF_ADDON_LIBCHARACTERKNOWLEDGE, --#308
		autoMarkMotifsOnlyThisChar  = false, --#308
		autoMarkMotifsIconNr		= FCOIS_CON_ICON_LOCK,  --#308
		autoMarkKnownMotifsIconNr   = FCOIS_CON_ICON_SELL_AT_GUILDSTORE, --#308
		showMotifsInChat			= false, --#308
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
		autoMarkSetsNonWishedChecks         = FCOIS_CON_NON_WISHED_TRAIT,
		autoMarkSetsNonWishedSellOthers     = true,
		autoMarkSetsNonWishedQuality 		= 1,
		autoMarkSetsNonWishedLevel			= 1,
		autoMarkSetsWithTraitIfAutoSetMarked = true,
		autoMarkSetsOnlyTraits				= false,
		autoMarkSetsWithTraitCheckAllIcons  = false,
		autoMarkSetsWithTraitCheckAllGearIcons = false,
		autoMarkSetsWithTraitCheckAllSetTrackerIcons = false,
		autoMarkSetsWithTraitCheckSellIcons = false,
		autoMarkSetsItemCollectionBook 					= false,
		autoMarkSetsItemCollectionBookAddonUsed 		= FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD,
		autoMarkSetsItemCollectionBookMissingIcon 		= FCOIS_CON_ICON_NONE,
		autoMarkSetsItemCollectionBookNonMissingIcon	= FCOIS_CON_ICON_NONE,
		autoMarkSetsItemCollectionBookOnlyCurrentAccount= true,
		autoMarkSetsItemCollectionBookCheckAllIcons		= false,
		showSetCollectionMarkedInChat		= false,
		autoMarkSetTrackerSets				= false,
		autoMarkSetTrackerSetsCheckAllIcons = false,
		autoMarkSetTrackerSetsInv			= false,
		autoMarkSetTrackerSetsBank			= false,
		autoMarkSetTrackerSetsGuildBank		= false,
		autoMarkSetTrackerSetsWorn			= false,
		autoMarkSetTrackerSetsShowTooltip	= false,
		autoMarkSetTrackerSetsRescan		= false,
		setTrackerIndexToFCOISIcon			= {},
		autoMarkSetsExcludeSets = false,
		autoMarkSetsExcludeSetsList = {},
		autoMarkWastedResearchScrolls		= true,
		autoDeMarkSell				= false,
		autoDeMarkSellInGuildStore	= false,
		autoDeMarkSellOnOthers		= false,
		autoDeMarkSellOnOthersExclusionDynamic = false,
		autoDeMarkSellGuildStoreOnOthers = false,
		autoDeMarkSellGuildStoreOnOthersExclusionDynamic = false,
		autoDeMarkDeconstructionOnOthers = false,
		autoDeMarkDeconstructionOnOthersExclusionDynamic = false,
		autoDeMarkDeconstruct		= false,
		autoMarkPreventIfMarkedForSell = false,
		autoMarkPreventIfMarkedForDeconstruction = false,
		autoMarkArmorWeaponJewelry = false,
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
		contextMenuClearMarkesModifierKey = KEY_SHIFT, --Shift key
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
		uniqueItemIdType			= FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE, -- Realy unique ids by ZOS
		uniqueIdParts				= {
			level = true,
			quality = true,
			trait = true,
			style = true,
			enchantment = true,
			isStolen = true,
			isCrafted = true,
			isCraftedBy = true,
			isCrownItem = false,
		},

		--[[ FCOIS v2.2.4
		allowedUniqueIdItemTypes = {
			[ITEMTYPE_ARMOR]	= true,
			[ITEMTYPE_WEAPON] 	= true,
		},
		]]
		allowedUniqueIdItemTypes = nil, --set nil as it is not used anymore!

		allowedFCOISUniqueIdItemTypes = {
			[ITEMTYPE_ARMOR]	= true,
			[ITEMTYPE_WEAPON] 	= true,
		}, --will be filled with all other available itemtypes further down below, value = false!
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
		markerIconOffset = {},
		enableKeybindChording = true,
		reApplyIconsAfterEnchanting = true,
		reApplyIconsAfterImprovement = true,
		reApplyIconsAfterLaunderFenceRemove = false, --#299
		autoBindMissingSetCollectionPiecesOnLoot = false,
		autoBindMissingSetCollectionPiecesOnLootMarkKnown = false,
		autoBindMissingSetCollectionPiecesOnLootToChat = false,
		autoMarkItemCoolDownTrackerTrackedItems = false,
		itemCoolDownTrackerTrackedItemsMarkerIcon = FCOIS_CON_ICON_LOCK,
		addRemoveAllMarkerIconsToItemContextMenu = false,
		showTooltipAtRestoreLastMarked = false,
		markerIconsOutputOrder = {},
		markerIconsOutputOrderEntries = {},
		--autoMarkLibSetsSetSearchFavorites = false, --#301 LibSets set search favorites
		--LibSetsSetSearchFavoriteToFCOISMapping = {}, --#301 LibSets set search favorites
		--LibSetsSetSearchFavoriteToFCOISMappingRemoved = {} --#301 LibSets set search favorites
	}
	--The tables for the markedItems, non-unique and unique
	local addonVars = FCOIS.addonVars
	--Added with FCOIS v2.0.2
	--Different tables for normal "signed" itemInstanceId/ZOs really uniqueId string markerIcons in the SavedVariables,
	--or FCOIS created uniqueIds as string (containing different parts like level, quality, trait, crafted state, etc.)
	local savedVarsMarkedItemsNames = addonVars.savedVarsMarkedItemsNames
	--"markedItems" table for non-unique and ZOs unique (FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE) marker icons
	FCOIS.settingsVars.defaults[savedVarsMarkedItemsNames[false]] = {}
	--"markedItemsFCOISUnique" table for FCOIS unique (FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE) marker icons
	FCOIS.settingsVars.defaults[savedVarsMarkedItemsNames[FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE]] = {}

	--Local constant values for speed-up
	local numLibFiltersFilterPanelIds   = FCOIS.numVars.gFCONumFilterInventoryTypes
	local activeFilterPanelIds          = FCOIS.mappingVars.activeFilterPanelIds
	local numFilterIcons                = FCOIS.numVars.gFCONumFilterIcons
	local filterButtonsToCheck          = FCOIS.checkVars.filterButtonsToCheck
	-- local numNonDynamicAndGearIcons     = FCOIS.numVars.gFCONumNonDynamicAndGearIcons
	local numMaxGearStatic				= FCOIS.numVars.gFCONumGearSetsStatic
	local numMaxDynIcons                = FCOIS.numVars.gFCOMaxNumDynamicIcons
	local iconIsDynamic                 = FCOIS.mappingVars.iconIsDynamic
	local iconIdToDynIcon               = FCOIS.mappingVars.dynamicToIcon
	local iconNrToOrdinalStr            = FCOIS.mappingVars.iconNrToOrdinalStr

	--Added with FCOIS v1.9.9 - Accoutn wide "per character" settings
	--The table for the current character Id
	FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId] = {}
	--The filterButton state
	FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].isFilterPanelOn = {}
	--Create the helper arrays for the filter button context menus
	FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastLockDynFilterIconId = {}
	FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastGearFilterIconId = {}
	FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastResDecImpFilterIconId = {}
	FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastSellGuildIntFilterIconId = {}

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
			--Create the helper arrays for the filter button context menus
			FCOIS.settingsVars.defaults.lastLockDynFilterIconId[libFiltersFilterPanelIdHelper]		= -1
			FCOIS.settingsVars.defaults.lastGearFilterIconId[libFiltersFilterPanelIdHelper] 		= -1
			FCOIS.settingsVars.defaults.lastResDecImpFilterIconId[libFiltersFilterPanelIdHelper] 	= -1
			FCOIS.settingsVars.defaults.lastSellGuildIntFilterIconId[libFiltersFilterPanelIdHelper]	= -1

			--Create 2-dimensional array for the UNDO functions from the addiitonal inventory context menu (flag) menu
			FCOIS.contextMenuVars.undoMarkedItems[libFiltersFilterPanelIdHelper] = {}

			--Added with FCOIS v1.9.9
			FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].isFilterPanelOn[libFiltersFilterPanelIdHelper] = {}
			FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].isFilterPanelOn[libFiltersFilterPanelIdHelper] = {false, false, false, false}
			--Create the helper arrays for the filter button context menus
			FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastLockDynFilterIconId[libFiltersFilterPanelIdHelper] = -1
			FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastGearFilterIconId[libFiltersFilterPanelIdHelper] = -1
			FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastResDecImpFilterIconId[libFiltersFilterPanelIdHelper] = -1
			FCOIS.settingsVars.accountWideButForEachCharacterDefaults[currentCharId].lastSellGuildIntFilterIconId[libFiltersFilterPanelIdHelper] = -1

			--Added with FCOIS v2.2.4
			FCOIS.settingsVars.defaults.filterButtonSettings[libFiltersFilterPanelIdHelper] = {
				[FCOIS_CON_FILTER_BUTTON_LOCKDYN]      = {
					filterWithLogicalAND = true, --true: filter button will add with logical AND / false: filter button will add with logical OR
				},
				[FCOIS_CON_FILTER_BUTTON_GEARSETS]     = {
					filterWithLogicalAND = true,
				},
				[FCOIS_CON_FILTER_BUTTON_RESDECIMP]    = {
					filterWithLogicalAND = true,
				},
				[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] = {
					filterWithLogicalAND = true,
				},
			}
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
		local isIconDynamic = iconIsDynamic[filterIconHelper]

		--Marker icons in inventories - non-unique & unique
		FCOIS.settingsVars.defaults[savedVarsMarkedItemsNames[false]][filterIconHelper] = {}
		FCOIS.settingsVars.defaults[savedVarsMarkedItemsNames[FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE]][filterIconHelper] = {}

		--Defaults for filter button offsets
		FCOIS.settingsVars.defaults.filterButtonTop[filterIconHelper]  = FCOIS.filterButtonVars.gFilterButtonTop
		FCOIS.settingsVars.defaults.filterButtonLeft[filterIconHelper] = FCOIS.filterButtonVars.gFilterButtonLeft[filterIconHelper]

		--General icon information
		FCOIS.settingsVars.defaults.icon[filterIconHelper] 		  	= {}
		FCOIS.settingsVars.defaults.icon[filterIconHelper].antiCheckAtPanel = {}
		FCOIS.settingsVars.defaults.icon[filterIconHelper].demarkAllOthers = false --added with FCOIS 1.5.2
		FCOIS.settingsVars.defaults.icon[filterIconHelper].demarkAllOthersExcludeDynamic = false
		FCOIS.settingsVars.defaults.icon[filterIconHelper].demarkAllOthersExcludeNormal = false -- added with FCOIS 1.9.6
		--Icon offsets in inventories etc. (FCOIS v1.6.8)
		FCOIS.settingsVars.defaults.icon[filterIconHelper].offsets = {}
		--For each filterPanelId do some checks and add icon default settings data:
		for filterIconHelperPanel = 1, numLibFiltersFilterPanelIds, 1 do
			--FCOIS v1.6.8
			--For each filterPanelId add the icon offsets table
			FCOIS.settingsVars.defaults.icon[filterIconHelper].offsets[filterIconHelperPanel] = defaultIconOffsets

			--FCOIS v.1.4.4 - Research dialog panels need to be protected as default value as they were added new with this version
			--FCOIS v.2.1.0 - Companion inventory panel needs to be protected as default value as it was added new with this version
			local valueToSet = false
			if filterIconHelperPanel == LF_SMITHING_RESEARCH_DIALOG or filterIconHelperPanel == LF_JEWELRY_RESEARCH_DIALOG or
					filterIconHelperPanel == LF_INVENTORY_COMPANION then
				valueToSet = true
			end
			FCOIS.settingsVars.defaults.icon[filterIconHelper].antiCheckAtPanel[filterIconHelperPanel] = valueToSet
		end

		--Defaults for research check is "false", except for dynamic icons where it is "true"
		local defResearchCheck = false
		if isIconDynamic then defResearchCheck = true end
		FCOIS.settingsVars.defaults.disableResearchCheck[filterIconHelper] = defResearchCheck
		if isIconDynamic == true then
			FCOIS.settingsVars.defaults.icon[filterIconHelper].temporaryDisableByInventoryFlagIcon = false
			--Added with FCOIS 1.9.6
			FCOIS.settingsVars.defaults.icon[filterIconHelper].autoMarkPreventIfMarkedWithThis = false
			--Added with FCOIS 1.9.9
			FCOIS.settingsVars.defaults.icon[filterIconHelper].autoRemoveMarkForBag = {}
			FCOIS.settingsVars.defaults.icon[filterIconHelper].autoRemoveMarkForBag[BAG_BANK] = false
			FCOIS.settingsVars.defaults.icon[filterIconHelper].autoRemoveMarkForBag[BAG_GUILDBANK] = false
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

	--Update the static "Gear sets" texts depending on localization
	for staticGearIndex=1, numMaxGearStatic, 1 do
		FCOIS.settingsVars.defaults.icon[_G["FCOIS_CON_ICON_GEAR_" .. tos(staticGearIndex)]].name = "Gear " ..tos(staticGearIndex)
	end

	--Update the "Dynamic icon" texts depending on localization
	for dynIconNr=1, numMaxDynIcons, 1 do
		--Use english ordinals
		local iconToOrdinalStrDynEn = iconNrToOrdinalStr[1][tonumber(dynIconNr)] or "th"
		local dynIconStr = tos(dynIconNr).. iconToOrdinalStrDynEn
		FCOIS.settingsVars.defaults.icon[_G["FCOIS_CON_ICON_DYNAMIC_" .. tos(dynIconNr)]].name = dynIconStr .. " dynamic"
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

	--Added with FCOIS v1.8.4
	FCOIS.settingsVars.defaults.markerIconOffset = FCOIS.settingsVars.defaults.markerIconOffset or {}
	--Add offsets for the marker icons in the inventories for some special addons like:
	-->GridList
	FCOIS.settingsVars.defaults.markerIconOffset["GridList"] = {
		x 		= 12,
		y 		= -12,
		scale 	= 90,
	}

	--Added with FCOIS v2.0.1
	--UniqueId created by FCOIS -> allowed itemTypes.
	--For all itemTypes: Add them as disabled in the defaults.
	-->Armor and weapon are already defined at the table above as "true", so they will be skipped here
	local itemTypeMax = FCOIS.numVars.maxItemType
	--If not given set it to current maximum = 71 -> ITEMTYPE_GROUP_REPAIR
	local allowedFCOISUniqueIdItemTypes = FCOIS.settingsVars.defaults.allowedFCOISUniqueIdItemTypes
	for itemType=ITEMTYPE_NONE, itemTypeMax, 1 do
		if itemType > 0 and allowedFCOISUniqueIdItemTypes[itemType] == nil then
			FCOIS.settingsVars.defaults.allowedFCOISUniqueIdItemTypes[itemType] = false
		end
	end

	--Added with FCOIS v2.1.6
	-->Custom filterPanel Ids = non standard LibFilters filterPanels
	local customFilterPanelIds = FCOIS.customFilterPanelIds
	for _, FCOISCustomFilterPanelId in ipairs(customFilterPanelIds) do
		--Create 2-dimensional array for the UNDO functions from the addiitonal inventory context menu (flag) menu
		FCOIS.contextMenuVars.undoMarkedItems[FCOISCustomFilterPanelId] = {}

		FCOIS.settingsVars.defaults.FCOISAdditionalInventoriesButtonOffset[FCOISCustomFilterPanelId] = {
			["top"] = 0,
			["left"] = 0,
		}
	end

	--Added with FCOIS v2.6.1
	--#301 LibSets set search favorite categories
	--[[
	FCOIS.settingsVars.defaults.LibSetsSetSearchFavoriteToFCOISMapping = {}
	local libSetsSetSearchFavoriteToFCOISMapping = FCOIS.settingsVars.defaults.LibSetsSetSearchFavoriteToFCOISMapping
	local libSetsSetSearchCategoryData = FCOIS.GetLibSetsSetSearchFavoriteCategories()
	if not ZO_IsTableEmpty(libSetsSetSearchCategoryData) then
		for idx, categoryData in ipairs(libSetsSetSearchCategoryData) do
			if categoryData.category ~= nil then
				libSetsSetSearchFavoriteToFCOISMapping[categoryData.category] = FCOIS_CON_ICON_DYNAMIC_1 --Default = 1st dynamic marker icon of FCOIS
			end
		end
	end
	]]
end
