--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
--if not FCOIS.libsLoadedProperly then return end

local tos = tostring
local tins = table.insert
local strformat = string.format

local debugMessage = FCOIS.debugMessage

local gil = GetItemLink 

local addonVars = FCOIS.addonVars
local doCompanionItemChecks = FCOIS.DoCompanionItemChecks
local isUnboundAndNotStolenItemChecks = FCOIS.IsUnboundAndNotStolenItemChecks

local libFilters = FCOIS.libFilters

local universalDeconGlobal = FCOIS.ZOControlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL

--==========================================================================================================================================
-- 			README PLEASE		README PLEASE			-FCOIS API limitations-			README PLEASE		README PLEASE
--==========================================================================================================================================
--IMPORTANT		IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT
--
--
--
-- [GAMEPAD MODE]
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! FCOItemSaver is NOT working with the gamepad mode enabled !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--If you are using any of these API functions below with the gamepad mode enabled they will throw error messages.
--The only way to enable FCOIS with the gamepad mode enabled is to use the addon "Advanced Disable Controller UI" AND disable the gamepad mode
--in the settings of this (ADCUI) addon! This will allow you to play and fight with the gamepad but the keyboard UI is shown in the inventories,
--making FCOIS work properly.
--
--You need to check the following within your addons code:
--Is the gamepad mode enabled in the game:
--if IsInGamepadPreferredMode() then
--	--We are in gamepad mode so check if the addon Advanced Disable Controller UI is enabled
--	--and the setting to use the gamepad mode in this addon is OFF
--	if FCOIS.checkIfADCUIAndIsNotUsingGamepadMode() then
--	--FCOIS will work properly. You can use the API functions now
--		--Your code here
--	else
--		--FCOIS won't work properly! Do NOT call any API functions and abort here now
--		return false
--	end
--else
--	--We are in keyboard mode so FCOIS will work normal
--end
--
--
--
-- [CRAFTING STATIONS]
--FCOItemSaver API functions are NOT working properly at crafting stations if you do not open the controls (UI) normally
--(e.g. show the Deconstruction panel and THEN check for FCOIS.IsDeconstructionLocked(bagId, slotIndex) BEFORE trying to use the API functions!
--Due to ESO's design one could simply approach a crafting station and as the station got opened (and it's on the way to show the refinement panel)
--you could already deconstruct, improve and/or refine materials.
--But FCOItemSaver relies on the UI elements like improvementSlot, refinementSlot, etc. in order to detect the opened panel, assure all items got
--loaded properly and the marker icons set will be checked + the items get protected properly.
--So please do not use the FCOIS API to do crafting stuff and protection checks if the UI for the crafting is not loaded properly!
--
--
--
--IMPORTANT		IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT	IMPORTANT



--==========================================================================================================================================
-- 															FCOIS API
--==========================================================================================================================================
--Local variables for speedup
local numVars = FCOIS.numVars
local numFilterIcons = numVars.gFCONumFilterIcons
local numFilters = numVars.gFCONumFilters
local numFilterInventoryTypes = numVars.gFCONumFilterInventoryTypes

local mappingVars = FCOIS.mappingVars

--local ZOsCtrlVars = FCOIS.ZOControlVars

--Local functions for speedup
local checkIfFCOISSettingsWereLoaded 	= FCOIS.CheckIfFCOISSettingsWereLoaded
local getSavedVarsMarkedItemsTableName	 = FCOIS.GetSavedVarsMarkedItemsTableName

local deconstructionSelectionHandler = FCOIS.DeconstructionSelectionHandler
local itemSelectionHandler           = FCOIS.ItemSelectionHandler

local checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local isItemProtectedAtASlotNow = FCOIS.IsItemProtectedAtASlotNow
local signItemId = FCOIS.SignItemId
local refreshEquipmentControl = FCOIS.RefreshEquipmentControl
local filterBasics = FCOIS.FilterBasics
local checkIfCharOrInvNeedsRingUpdate = FCOIS.CheckIfCharOrInvNeedsRingUpdate
local checkIfOtherDemarksSell = FCOIS.CheckIfOtherDemarksSell
local checkIfOtherDemarksDeconstruction = FCOIS.CheckIfOtherDemarksSell
local isItemLinkResearchable = FCOIS.IsItemLinkResearchable
local isItemResearchableNoControl = FCOIS.IsItemResearchableNoControl
local getIconsToRemove = FCOIS.GetIconsToRemove
local isItemBindable = FCOIS.IsItemBindable
local checkIfItemShouldBeDemarked = FCOIS.CheckIfItemShouldBeDemarked
local getItemIdFromItemLink = FCOIS.GetItemIdFromItemLink
local getItemLinkFromItemId = FCOIS.GetItemLinkFromItemId
local isCharacterShown = FCOIS.IsCharacterShown
local isCompanionCharacterShown = FCOIS.IsCompanionCharacterShown
local buildIconText = FCOIS.BuildIconText
local filterStatus = FCOIS.FilterStatus
local command_handler = FCOIS.Command_handler
local checkIfItemUnmarkedChecksNeeded = FCOIS.CheckIfItemUnmarkedChecksNeeded --#299


--------------------------------------------------------------------------------
-- Local helper functions
-----------------------------------------------------------------------------------
local function isAnJewelryItem(bagId, slotIndex)
	local isJewelryItem = false
	local craftingType = GetCraftingInteractionType()
	if craftingType == CRAFTING_TYPE_JEWELRYCRAFTING then
		isJewelryItem = true
	end
	if not isJewelryItem then
		local equipType = (bagId and slotIndex and GetItemLinkEquipType(gil(bagId, slotIndex))) or nil
		if equipType and (equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING) then
			isJewelryItem = true
		end
	end
	return isJewelryItem
end
--------------------------------------------------------------------------------
local function isResearchableCheck(p_iconId, p_bagId, p_slotIndex, p_itemLink)
	if not p_iconId then return false end
	if ((not p_bagId or not p_slotIndex) and not p_itemLink) then return false end
	p_itemLink = p_itemLink or gil(p_bagId, p_slotIndex)
	if mappingVars.iconIsResearchable[p_iconId] or mappingVars.iconIsDynamic[p_iconId] then
		-- Check if item is researchable (as only researchable items can work as equipment too)
		local isResearchableItem, isReconstructedOrRetraited = isItemLinkResearchable(p_itemLink, p_iconId, nil)
		isResearchableItem = isResearchableItem or false
		if isResearchableItem == true then return true, isReconstructedOrRetraited end
	else
		return true, nil
	end
	return false, nil
end
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


--=========== FCOIS Filter icons =============================
--Get all the possible filter icons as a table (to be used in e.g. FCOIS.MarkItem or FCOIS.MarkItemByItemInstanceId (iconId parameter)
--> returns table { [1] = FCOIS_CON_ICON_LOCK, [2] = FCOIS_CON_ICON_*, ... }
local function getAllFilterIconsAsTab()
	local retTab = {}
	for iconNr=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
		retTab[#retTab + 1] = iconNr
	end
	return retTab
end
FCOIS.GetAllFilterIconsAsTab = getAllFilterIconsAsTab


--=========== FCOIS Protection check API functions (with possbility to show alert messages) =============================
--[[ Description:

	Basically the protection check functions of this API (FCOIS.Is*****Locked) will call the function:
	FCOIS.callDeconstructionSelectionHandler(integer bag, integer slot, boolean echo, boolean overrideChatOutput, boolean suppressChatOutput, boolean overrideAlert, boolean suppressAlert boolean calledFromExternalAddon, libFilters2.x->LF_filterPanelID panelId)

	You need to give the function call the item's bag and slotId, and the LibFilters 3.x filter panel ID of the desired panel that you want to check, e.g. the crafting improvement panel.
    It will think we are at the improvement tab of the crafting station (and not at the crafting stations  create, deconstruct, or research tabs)
    Improvement panel LibFilters 3.x constant:    LF_SMITHING_IMPROVEMENT

    Function call parameters:
    Integer bag:                                                The bag index of the inventory/bank/guild bank/craft bag/equipment item
    Integer slotIndex:                                          The slot index of the inventory/bank/guild bank/craft bag/equipment item
    Boolean parameter echo: 									if true the chat output or alert message will be shown if protected.
    Boolean parameters overrideChatOutput / overrideAlert: 	    if true the FCOIS settings for the chat/alert messages will be overwritten so they get shown from your call.
    Boolean parameters suppressChatOutput / suppressAlert: 		if true the FCOIs settings for the chat/alert message will be suppressed so no message is shown from your call.
    Boolean parameter calledFromExternalAddon: 					Must be true if the call comes from another addon than FCOIS. Otherwise the protective functions won't work properly! Must be true for these protective check functions too!
    Integer parameter panelId: 									LibFilters 3.x filter constant LF_* for the panel where the check should be done. If this variable is nil FCOIS will detect the active panel automatically. If the parameter calledFromExternalAddon is true ONLY the panelid will be used to determine the active protections, no control:IsHidden() will be checked to determine the active panel!
    Boolean parameter isDragAndDrop: 	    					if true the item was dragged&dropped
    Integer parameter panelIdParent:							LibFilters 3.x filter constant LF_* for the parent panel at the CraftBag, if addon CraftBagExtended (or similar) is enabled which allows Mail/Trade etc. CraftBag panels as well. No automatic detection!
]]
--Function to call the itemSelectionHandler from other addons (e.g. DoItAll with FCOItemSaver support)
--Return true:   Item is protected
--Returns false: Item is not protected
function FCOIS.callItemSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId, isDragAndDrop, panelIdParent)
	echo = echo or false
	isDragAndDrop = isDragAndDrop or false
	overrideChatOutput = overrideChatOutput or false
	suppressChatOutput = suppressChatOutput or false
	overrideAlert = overrideAlert or false
	suppressAlert = suppressAlert or false
	calledFromExternalAddon = calledFromExternalAddon or false
    FCOIS.preventerVars.gCalledFromInternalFCOIS = not calledFromExternalAddon
	if not checkIfFCOISSettingsWereLoaded(calledFromExternalAddon, not addonVars.gAddonLoaded) then return true end
	--Return true to "protect" an item, if the bag and slot are missing
	if bag == nil or slot == nil then return true end
	--Call the item selection handler method now for the item
	return itemSelectionHandler(bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId, panelIdParent)
end
--Local function for speedup -> Anti-Item protection handler
local FCOIScish = FCOIS.callItemSelectionHandler

--Function to call the DeconstructionSelectionHandler from other addons (e.g. DoItAll with FCOItemSaver support). Only used at the deconstruction/extract panels of LibFilters.
-- If no deconstructable panel get's detected or no filterPanelId of a deconstructable panel was passed at the parameter panelId (+ calledFromExternalAddon must be true in this case!)
-- the normal ItemSelectionHandler function will be called internally from the DeconstructionSelectionHandlder function.
--Return true:   Item is protected
--Returns false: Item is not protected
function FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
    echo = echo or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    calledFromExternalAddon	= calledFromExternalAddon or false
    FCOIS.preventerVars.gCalledFromInternalFCOIS = not calledFromExternalAddon
	if not checkIfFCOISSettingsWereLoaded(calledFromExternalAddon, not addonVars.gAddonLoaded) then return true end
    --Return true to "protect" an item, if the bag and slot are missing
    if bag == nil or slot == nil then return true end
    --Call the item selection handler method now for the item
    return deconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
end
--Local function for speedup -> Anti-Deconstruction protection handler
local FCOIScdsh = FCOIS.callDeconstructionSelectionHandler


--Function to call the protection handlers for each entry of a given "panels" table
function FCOIS.callDeconstructionSelectionHandlerWithPanelTable(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelTable)
	if type(panelTable) ~= "table" then return false end
	echo = echo or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    calledFromExternalAddon	= calledFromExternalAddon or false
    FCOIS.preventerVars.gCalledFromInternalFCOIS = calledFromExternalAddon
	if not checkIfFCOISSettingsWereLoaded(calledFromExternalAddon, not addonVars.gAddonLoaded) then return true end
    --Return true to "protect" an item, if the bag and slot are missing
    if bag == nil or slot == nil then return true end
    --Call the item selection handler method now for the item, for each panel of the panelTable
	local panelCheckResultLoop
	for _, panelId in ipairs(panelTable) do
		panelCheckResultLoop = deconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
		if panelCheckResultLoop == true then return true end
	end
	return false
end
local FCOIScdshTab = FCOIS.callDeconstructionSelectionHandlerWithPanelTable

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS check single protection API functions (without alert messages, only provided panel check!) =================================
-- ===== ANTI-* - Automatically determine the current filter panel ID ====
-- FCOIS prevention for being ...
--Check if the item is protected somehow at the current panel.
--ATTENTION: This will NOT ONLY check for the LOCK marker icon (FCOIS_CON_ICON_LOCK)!
--It will check for ANY marker icon which prevents the item from e.g. destroy (inventory panel), attach to mail (mail panel),
--deconstruct (crafting station deconstruction panel), attach to trade (player trade panel),
--put into guild bank where you got no rights to withdraw it again (at guild deposit panel) etc.
--The protection depends on the marker icon type (normal, gear, dynamic, dynamic set as gear) and the protective global settings (for normal and gear marker icons)
--or dynamic protective settings (for each dynamic, including dynamic set as gear, icons)
function FCOIS.IsLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
    -- (bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
    return FCOIScdsh(bagId, slotIndex, false, true, true, true, true, true)
end

--Check if the item is locked at any of the specified panels in panelTable. The key must be a non-gap integer and the value the LF_* panel constant of LibFilters
-- e.g. panelTable = {[1] = LF_SMITHING_DECONSTRUCTION, [2] = LF_SMITHING_IMPROVEMENT }
function FCOIS.IsAnyPanelLocked(bagId, slotIndex, panelTable)
	--Don't show chat output and don't show alert message
    -- (bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelTableWithIds)
    return FCOIScdshTab(bagId, slotIndex, false, true, true, true, true, true, panelTable)
end

-- ===== ANTI DESTROY =====
-- FCOIS prevention for being destroyed at the current panel
function FCOIS.IsDestroyLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScdsh(bagId, slotIndex, false, true, true, true, true, true)
end

-- ===== ANTI TRADE =====
-- FCOIS prevention for being traded
function FCOIS.IsTradeLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_TRADE)
end

-- ===== ANTI MAIL =====
-- FCOIS prevention for being mailed
function FCOIS.IsMailLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_MAIL_SEND)
end

-- ===== ANTI SELL =====
-- FCOIS prevention for being sold at a vendor
function FCOIS.IsVendorSellLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_VENDOR_SELL)
end

-- FCOIS prevention for being sold at the guild store
function FCOIS.IsGuildStoreSellLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_GUILDSTORE_SELL)
end

-- FCOIS prevention for being sold at a fence
function FCOIS.IsFenceSellLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_FENCE_SELL)
end

-- ===== ANTI LAUNDER =====
-- FCOIS prevention for being laundered
function FCOIS.IsLaunderLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_FENCE_LAUNDER)
end

-- ===== ANTI Deposit =====
-- FCOIS prevention for being depositted to player bank
--> ATTENTION: FCOIS is currently NOT protecting the deposit of items to a player bank.
-- This is always allowed!
-- If you want to check if there is a marker icon on the item you want to deposit, and thus not allow to deposit it,
-- use the function FCOIS.IsMarked() -> See below in this API file, or FCOIS.IsLocked(bagId, slotIndex) -> See above in this API file
function FCOIS.IsPlayerBankDepositLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_BANK_DEPOSIT)
end

-- FCOIS prevention for being depositted to a guild bank
--> ATTENTION: FCOIS is currently only protecting the deposit of items to a guild bank, if you have enabled the setting for it and
-- if you are not allowed to withdraw this item anymore (missing rights in that guild).
-- This applies even to non marked items, so there does not need to be a marker icon on the item!
-- Otherwise the deposit is always allowed!
-- If you want to check if there is a marker icon on the item you want to deposit, and thus not allow to deposit it,
-- use the function FCOIS.IsMarked() -> See below in this API file, or FCOIS.IsLocked(bagId, slotIndex) -> See above in this API file
function FCOIS.IsGuildBankDepositLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_GUILDBANK_DEPOSIT)
end

-- ===== ANTI Withdraw =====
-- FCOIS prevention for being withdrawn from player bank
--> ATTENTION: FCOIS is currently NOT protecting the withdraw of items from a player bank.
-- This is always allowed!
-- If you want to check if there is a marker icon on the item you want to withdraw, and thus not allow to withdraw it,
-- use the function FCOIS.IsMarked() -> See below in this API file, or FCOIS.IsLocked(bagId, slotIndex) -> See above in this API file
function FCOIS.IsPlayerBankWithdrawLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_BANK_WITHDRAW)
end

-- FCOIS prevention for being withdrawn from a guild bank
--> ATTENTION: FCOIS is currently NOT protecting the withdraw of items from a guild bank.
-- This is always allowed!
-- If you want to check if there is a marker icon on the item you want to withdraw, and thus not allow to withdraw it,
-- use the function FCOIS.IsMarked() -> See below in this API file, or FCOIS.IsLocked(bagId, slotIndex) -> See above in this API file
function FCOIS.IsGuildBankWithdrawLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_GUILDBANK_WITHDRAW)
end


-- ===== ANTI CRAFTING =====
-- FCOIS prevention for jewelry being refined
function FCOIS.IsJewelryRefinementLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_REFINE)
end
local isJewelryRefinementLocked = FCOIS.IsJewelryRefinementLocked

-- FCOIS prevention for jewelry being deconstructed
function FCOIS.IsJewelryDeconstructionLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScdsh(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_DECONSTRUCT)
end
local isJewelryDeconstructionLocked = FCOIS.IsJewelryDeconstructionLocked

-- FCOIS prevention for jewelry being improved
function FCOIS.IsJewelryImprovementLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_IMPROVEMENT)
end
local isJewelryImprovementLocked = FCOIS.IsJewelryImprovementLocked

-- FCOIS prevention for jewelry being researched
function FCOIS.IsJewelryResearchLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_RESEARCH)
end
local isJewelryResearchLocked = FCOIS.IsJewelryResearchLocked

-- FCOIS prevention for jewelry being researched at the jewelry research popup dialog
function FCOIS.IsJewelryResearchDialogLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_RESEARCH_DIALOG)
end
local isJewelryResearchDialogLocked = FCOIS.IsJewelryResearchDialogLocked

-- FCOIS prevention for being refined
function FCOIS.IsRefinementLocked(bagId, slotIndex, doNotCheckJewelry)
	doNotCheckJewelry = doNotCheckJewelry or false
	if not doNotCheckJewelry then
		local isJewelryCrafting = isAnJewelryItem(bagId, slotIndex)
		if isJewelryCrafting == true then
			return isJewelryRefinementLocked(bagId, slotIndex)
		end
	end
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_REFINE)
end

-- FCOIS prevention for being deconstructed
function FCOIS.IsDeconstructionLocked(bagId, slotIndex, doNotCheckJewelry)
	doNotCheckJewelry = doNotCheckJewelry or false
	if not doNotCheckJewelry then
		local isJewelryCrafting = isAnJewelryItem(bagId, slotIndex)
		if isJewelryCrafting == true then
			return isJewelryDeconstructionLocked(bagId, slotIndex)
		end
	end
	--Don't show chat output and don't show alert message
	return FCOIScdsh(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_DECONSTRUCT)
end

-- FCOIS prevention for being improved
function FCOIS.IsImprovementLocked(bagId, slotIndex, doNotCheckJewelry)
	doNotCheckJewelry = doNotCheckJewelry or false
	if not doNotCheckJewelry then
		local isJewelryCrafting = isAnJewelryItem(bagId, slotIndex)
		if isJewelryCrafting == true then
			return isJewelryImprovementLocked(bagId, slotIndex)
		end
	end
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_IMPROVEMENT)
end

-- FCOIS prevention for being researched
function FCOIS.IsResearchLocked(bagId, slotIndex, doNotCheckJewelry)
	doNotCheckJewelry = doNotCheckJewelry or false
	if not doNotCheckJewelry then
		local isJewelryCrafting = isAnJewelryItem(bagId, slotIndex)
		if isJewelryCrafting == true then
			return isJewelryResearchLocked(bagId, slotIndex)
		end
	end
	--Don't show chat output and don't show alert message
	--bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_RESEARCH)
end

-- FCOIS prevention for being researched at the research popup dialog
function FCOIS.IsResearchDialogLocked(bagId, slotIndex, doNotCheckJewelry)
	doNotCheckJewelry = doNotCheckJewelry or false
	if not doNotCheckJewelry then
		local isJewelryCrafting = isAnJewelryItem(bagId, slotIndex)
		if isJewelryCrafting == true then
			return isJewelryResearchDialogLocked(bagId, slotIndex)
		end
	end
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_RESEARCH_DIALOG)
end

-- FCOIS prevention for being created as enchantment or extracting an enchantment
function FCOIS.IsEnchantingLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScdshTab(bagId, slotIndex, false, true, true, true, true, true, {LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION})
end

-- FCOIS prevention for being created as enchantment
function FCOIS.IsEnchantingCreationLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_ENCHANTING_CREATION)
end

-- FCOIS prevention for being extracted from a glyphe
function FCOIS.IsEnchantingExtractionLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScdsh(bagId, slotIndex, false, true, true, true, true, true, LF_ENCHANTING_EXTRACTION)
end

-- FCOIS prevention for being destroyed at the alchemy station
function FCOIS.IsAlchemyDestroyLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIScish(bagId, slotIndex, false, true, true, true, true, true, LF_ALCHEMY_CREATION)
end


-- ===== ANTI EQUIP =====
-- FCOIS prevention for being equipped
--[[
function FCOIS.IsEquipLocked(bagId, slotIndex)
    FCOIS.preventerVars.gCalledFromInternalFCOIS = false
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return true end
	--Only if the "ask before bind" setting is enabled: Every marked item that is not yet bound is protected
	if not FCOIS.settingsVars.settings.askBeforeEquipBoundItems or not isItemBindable(bagId, slotIndex) then return false end
	--Only the bindable AND non-bound equipment items result in a positive result = item is locked
	return true
end
]]

-- ===== ANTI Junk =====
-->See below FCOIS.IsMarked

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS filter API functions==========================
function FCOIS.IsIconEnabled(markerIconId, calledFromExternalAddon)
	calledFromExternalAddon = calledFromExternalAddon or false
	if markerIconId == nil or markerIconId <= 0 or markerIconId > numFilterIcons then return nil end
--d("[FCOIS.IsIconEnabled] markerIconId: " .. tos(markerIconId))
    FCOIS.preventerVars.gCalledFromInternalFCOIS = calledFromExternalAddon
	if not checkIfFCOISSettingsWereLoaded(calledFromExternalAddon, not addonVars.gAddonLoaded) then return false end
    --Check if the icon is enabled
	local isIconEnabled = FCOIS.settingsVars.settings.isIconEnabled
	local isIconEnabledOne = isIconEnabled[markerIconId] or false
    return isIconEnabledOne
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS is an item marked API functions =================================
--Function used to check if the items is marked with any marker icon and return a boolean value + array containing the marker icons which are set
-->Used in FCOIS.IsMarked and FCOIS.IsMarkedByItemInstanceId
---addonName (String):					Can be left NIL! The unique addon name which was used to temporarily enable the uniqueId usage for the item checks.
---										-> See FCOIS API function "FCOIS.UseTemporaryUniqueIds(addonName, doUse)"
local function checkIfItemIsMarkedAndReturnMarkerIcons(instance, iconIds, excludeIconIds, addonName)
	if instance == nil then return nil, nil end
	if (iconIds ~= -1 and excludeIconIds ~= nil) or excludeIconIds == -1 then return nil, nil end
	local markedArray = {}
	for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
		markedArray[i] = false
	end
	local itemIsMarked              = false

	--is the parameter excludeIconIds an array/table?
	local excludeIconIdsIsTable    = false
	--Table containing the excluded icon IDs and the value true
	local excludeIconIdsCheckTable = {}
	if excludeIconIds ~= nil then
		if type(excludeIconIds)=="table" then
			excludeIconIdsIsTable = true
			--Get each excluded iconId from array/table
			for _, excludedIconId in pairs(excludeIconIds) do
				--Add the excluded icon id to the check table, with the value true
				excludeIconIdsCheckTable[excludedIconId] = true
			end
		else
			--Add the excluded icon id to the check table, with the value true
			excludeIconIdsCheckTable[excludeIconIds] = true
		end
	end

	local savedVarsMarkedItemsTableName = getSavedVarsMarkedItemsTableName()

	--Is parameter iconIds an array/table?
	if type(iconIds)=="table" then
		--Counter to check if any icon was already checked inside the for... loop
		local iconsChecked = 0
		local iconIsSet = false
		--Get each iconId from array/table
		for _, iconId in pairs(iconIds) do
			--Check for all icons if the item is marked
			if iconId == -1 then
				--Was any iconId checked before?
				if iconsChecked > 0 then
					--Initialize the return value and array again
					for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
						markedArray[i] = false
					end
					itemIsMarked = false
				end
				--Check all iconIds now
				for icoId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
					--Only if iconIds contains the value -1 or {-1} do the excluded icon checks too
					if not excludeIconIdsCheckTable[icoId] then
						--Is the not-excluded icon ID protected?
						if (checkIfItemIsProtected(icoId, instance, nil, addonName) == true) then
							--return true, if any icon is set
							itemIsMarked        = true
							markedArray[icoId] = true
						end
					end
				end

				--Abort here as all icons were checked now and no further single iconId from parameter iconIds must be checked
				return itemIsMarked, markedArray

				--Check only a specific iconId
			else
				--Is the iconId a number not equals -1?
				if type(iconId)=="number" then
					--Increase the icons checked so any entry with iconId == -1, after this entry here was checked, will
					--initialize the return array with false again!
					iconsChecked = iconsChecked + 1
					--is the item marked with that iconId?
					if (FCOIS[savedVarsMarkedItemsTableName][iconId] ~= nil) then
						iconIsSet = checkIfItemIsProtected(iconId, instance, nil, addonName)
						markedArray[iconId] = iconIsSet
						if not itemIsMarked then
							itemIsMarked = iconIsSet
						end
					end
				end
			end
		end
		return itemIsMarked, markedArray

	else

		--iconIds is no array/table
		--Check only 1 icon
		if (iconIds ~= -1) then
			itemIsMarked = FCOIS[savedVarsMarkedItemsTableName][iconIds] ~= nil and checkIfItemIsProtected(iconIds, instance, nil, addonName)
			if itemIsMarked then
				markedArray[iconIds] = true
			end
			return itemIsMarked, markedArray
		else
			--Check for all icons if the item is marked. return true, if any icon is set
			for icoId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
				--Only if iconIds contains the value -1 or {-1} do the excluded icon checks too
				if not excludeIconIdsCheckTable[icoId] then
					--Is the not-excluded icon ID protected?
					if (checkIfItemIsProtected(icoId, instance, nil, addonName) == true) then
						itemIsMarked        = true
						markedArray[icoId] = true
					end
				end
			end
			return itemIsMarked, markedArray
		end

	end
end -- checkIfItemIsMarkedAndReturnMarkerIcons

--Global function to return boolean value, if an item is marked
-- + it will return an array as 2nd return parameter, containing boolean entries, one for each iconId. True if item is marked with this iconId, false if not
--Check if an item is marked by the help of it's item id
--itemInstanceId:  The itemInstanceId or uniqueId of the item
--iconIds: Specifies the icon the item is marked with. iconIds can be any of the marker icons FCOIS_CON_ICON_* or -1 for all icons.
--		   The parameter can be an array/table too.
--		   The array's/table's key can be any index/value that you like.
--         The value to the key must be the icon number, or -1 for all icons (if -1 is used more than once in the table it'll only be checked once!).
--excludeIconIds:   Exclude the iconID or an array of iconIDs from the check.
--                  Can only be used together with iconIds = -1 or iconIds = {-1}!
--                  excludeIconIds cannot be -1 or the function will return nil!
---addonName (String):	Can be left NIL! The unique addon name which was used to temporarily enable the uniqueId usage for the item checks.
---						-> See FCOIS API function "FCOIS.UseTemporaryUniqueIds(addonName, doUse)"
function FCOIS.IsMarkedByItemInstanceId(itemInstanceId, iconIds, excludeIconIds, addonName)
	if (iconIds ~= -1 and excludeIconIds ~= nil) or excludeIconIds == -1 then return nil, nil end
	if itemInstanceId == nil then return nil, nil end
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	--Build the itemInstanceId (signed) by help of the itemId
	local signedItemInstanceId = signItemId(itemInstanceId, nil, true, addonName, nil, nil) -- only sign
--d(">FCOIS.IsMarkedByItemInstanceId, itemInstanceId: " .. tos(itemInstanceId) .. ", signedItemInstanceId: " ..tos(signedItemInstanceId))
	if signedItemInstanceId == nil then return nil, nil end
	local itemIsMarked = false
	local markedIconsArray = {}
	itemIsMarked, markedIconsArray = checkIfItemIsMarkedAndReturnMarkerIcons(signedItemInstanceId, iconIds, excludeIconIds, addonName)
	return itemIsMarked, markedIconsArray
end -- FCOIS.IsMarkedByItemInstanceId
local isMarkedByItemInstanceId = FCOIS.IsMarkedByItemInstanceId

--Global function to return boolean value, if an item is marked
-- + it will return an array as 2nd return parameter, containing boolean entries, one for each iconId (key). True if item is marked with this iconId, false if not (value).
--bag:     The bag where the item is located
--slot:    The slotIndex where the item is located in the bag
--iconIds: Specifies the icon the item is marked with. iconIds can be any of the marker icons FCOIS_CON_ICON_* or -1 for all icons.
--		   The parameter can be an array/table too.
--		   The array's/table's key can be any index/value that you like.
--         The value to the key must be the icon number, or -1 for all icons (if -1 is used more than once in the table it'll only be checked once!).
--excludeIconIds:   Exclude the iconID or an array of iconIDs from the check.
--                  Can only be used together with iconIds = -1 or iconIds = {-1}!
--                  excludeIconIds cannot be -1 or the function will return nil!
function FCOIS.IsMarked(bag, slot, iconIds, excludeIconIds)
    if (iconIds ~= -1 and excludeIconIds ~= nil) or excludeIconIds == -1 then return nil, nil end
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	--At least one of the needed function parameters is missing. Return nil, nil
    if (bag == nil or slot == nil or iconIds == nil) then return nil, nil end
	local signedItemInstanceId = myGetItemInstanceIdNoControl(bag, slot)
	if signedItemInstanceId == nil then return nil, nil end
	local itemIsMarked = false
	local markedIconsArray = {}
	itemIsMarked, markedIconsArray = checkIfItemIsMarkedAndReturnMarkerIcons(signedItemInstanceId, iconIds, excludeIconIds, nil)
	return itemIsMarked, markedIconsArray
end -- FCOIS.IsMarked
local isMarked = FCOIS.IsMarked


-- ===== ANTI Junk =====
-- FCOIS prevention for being marked as junk (e.g. in AddOn Dustman)
function FCOIS.IsJunkLocked(bagId, slotIndex, calledFromExternalAddon)
	calledFromExternalAddon = calledFromExternalAddon or false
	FCOIS.preventerVars.gCalledFromInternalFCOIS = calledFromExternalAddon
	if not checkIfFCOISSettingsWereLoaded(calledFromExternalAddon, not addonVars.gAddonLoaded) then return true end
	local isItemProtectedAgainstJunk = false
    --Check all marker icons and exclude the icon for "Sell"
    local settings = FCOIS.settingsVars.settings
	local isItemMarked, markedIcons = isMarked(bagId, slotIndex, -1, FCOIS_CON_ICON_SELL)
    --Is the item marked with any of the marker items (except "sell" item)
    if isItemMarked and markedIcons ~= nil then
        --Check each of the dynamic icons in the returned table "markedIcons".
        --Loop over the returned array and check all icons where the marker is set
        local oneMarkedDynamicIconFound = false
        local noneDynamicIconMarked = false
        local oneDynamicDoesNotAllowToSell = false
        local isDynamic = mappingVars.iconIsDynamic
		for iconId, itemIsMarked in pairs(markedIcons) do
            --Is a dynamic icon?
            local isDynIcon = isDynamic[iconId] or false
			if itemIsMarked and isDynIcon then
                oneMarkedDynamicIconFound = true
                --All marked dyanmic icons must allow "sell" in order to let this item be marked as junk!
                --Check if dynamic icon's "sell" setting is allowed
                local iconData = settings.icon[iconId]
				if iconData.antiCheckAtPanel[LF_VENDOR_SELL] == true then
                    oneDynamicDoesNotAllowToSell = true
                end
            elseif itemIsMarked and not isDynIcon then
                noneDynamicIconMarked = true
                break -- Exit the loop now as a none dynamic icon protects the item
            end
        end
        --Is any dynamic icon marked in the retun array?
        if oneMarkedDynamicIconFound and not noneDynamicIconMarked then
            --Set the result variable to true if itemIsMarked and was a dnymic icon, and one of the dynamic icons does not allow "sell"
            isItemProtectedAgainstJunk = oneDynamicDoesNotAllowToSell
        else
            --No dynamic icons were marked!
            --Set the result variable to true if itemIsMarked, as item is marked and it's not a dynamic marker icon
            isItemProtectedAgainstJunk = isItemMarked
        end
    end
    --Return the "isItemProtectedAgainstJunk" value now
    return isItemProtectedAgainstJunk
end

--Global function to return boolean value, if an item is marked with any FCOIS gear marker icons (FCOIS_CON_ICON_GEAR_1 to 5, or dynamic icon defined as gear).
-- + it will return an array as 2nd return parameter, containing boolean entries for each gear iconId (key). True (value) if item is marked with this gear iconId,
-- false (value) if not.
--bag:     The bag where the item is located
--slot:    The slotIndex where the item is located in the bag
function FCOIS.IsGear(bag, slot)
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return nil end
	local settings = FCOIS.settingsVars.settings
	local isGearIcon = settings.iconIsGear
	local gearIconIds = {}
	for gearIconId, isGearIconId in pairs(isGearIcon) do
		if isGearIconId == true then
			tins(gearIconIds, gearIconId)
		end
	end
	return isMarked(bag, slot, gearIconIds, nil)
end


function FCOIS.UpdateInventory(bag, isCharShown, showIcon, iconId)
	--d("<<UpdateInv: " ..tos(updateInventories) .. ", doUpdateMarkerNow: " .. tos(doUpdateMarkerNow) .. ", gOverrideInvUpdateAfterMarkItem: " ..tos(FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem))
	if isCharShown then
		refreshEquipmentControl(nil, showIcon, iconId)
	elseif bag == nil then
		filterBasics(false)
	elseif bag ~= nil and (bag == BAG_BACKPACK or bag == BAG_VIRTUAL
			or bag == BAG_BANK or bag == BAG_SUBSCRIBER_BANK or bag == BAG_GUILDBANK or IsHouseBankBag(bag)
			or (bag == BAG_WORN and FCOIS.IsVendorPanelShown(LF_VENDOR_REPAIR, false))) then
		filterBasics(false)
	end
end
local FCOIS_UpdateInventory = FCOIS.UpdateInventory

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS mark an item API functions =================================
--Global function to mark an item with one (or several, by help of a table or iconId = -1) FCOIS marker icon(s).
--The other marking functions like "automatic de-mark" or "automatic mark" will be applied too.
-->Parameters:
---bag (number):				The bagId of the item to mark
---slot (number): 				The slotId of the item to mark
---iconId (number|table): 		Number: The iconId to change. Can be a value between 1 and FCOIS.numVars.gFCONumFilterIcons, or -1 for all.
---								Table:	A table containing the icons to change. Table key must be a number (without gaps!) and the value must be the marker icon Id
---								e.g. local myTableOfFCOISMarkerIcons = { [1] = FCOIS_CON_ICON_RSEARCH, [2] = FCOIS_CON_ICON_SELL }
---showIcon (boolean): 			Flag to set if the item should be marked with the icon(s), or not
---updateInventories (boolean):	Flag to set if the inventory lists should be updated, or not. Use this only "after updating the last marker icon", if you (de)mark many at once!
local markItem
function FCOIS.MarkItem(bag, slot, iconId, showIcon, updateInventories)
--d("[FCOIS.MarkItem] bag " .. tos(bag) .. ", slot: " .. tos(slot) .. ", iconId: " .. tos(iconId) .. ", show: " .. tos(showIcon) .. ", updateInv: " .. tos(updateInventories))
	markItem = markItem or FCOIS.MarkItem
	if bag == nil or slot == nil or iconId == nil then return false end
	if showIcon == nil then showIcon = true end
	updateInventories = updateInventories or false
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	--Are we restoring or clearing marker icons via SHIFT + right mouse button on an inventory row e.g.?
	local isRestoringOrClearingMarkerIcons = (FCOIS.preventerVars.gRestoringMarkerIcons or FCOIS.preventerVars.gClearingMarkerIcons) or false
	local isCharShown = ((bag == BAG_WORN and isCharacterShown()) or (bag == BAG_COMPANION_WORN and isCompanionCharacterShown())) or false
	local recurRetValTotal = true
	--Check the type of iconId parameter
	local iconIdType = type(iconId)
	local iconIdTypeIsATable = false
	if iconIdType == "number" then
		if ((iconId > numFilterIcons) or (iconId < FCOIS_CON_ICON_LOCK and iconId ~= -1)) then return false end
	elseif iconIdType == "table" then
--d("[FCOIS]MarkItem - IconId is a table with " .. tos(#iconId) .. " entries!")
		--IconId is a table. Set the variable so no marker icons will be changed with this 1st call of the function FCOIS.MarkItem
		iconIdTypeIsATable = true
		--Set preventing variable against endless loop
		FCOIS.preventerVars.markItemAntiEndlessLoop = true
		--Now change each icon inside the table
		local doUpdateInvNow = false
		local recurRetVal = false
		local numMarkerIconsToChange = #iconId
		local markerIconsChanged = 0
		FCOIS.lastVars.MarkItem_IconTable = iconId		--#299
		FCOIS.lastVars.Last_MarkItem_IconTable = nil	--#299
		for _, iconIdInTable in ipairs(iconId) do
			FCOIS.preventerVars.gMarkItemLastIconInLoop = false
			markerIconsChanged = markerIconsChanged + 1
			if updateInventories and markerIconsChanged == numMarkerIconsToChange then
				doUpdateInvNow = true
				FCOIS.preventerVars.gMarkItemLastIconInLoop = true
			end
			--Recursively call this function again to change each marker icon at the item
			recurRetVal = markItem(bag, slot, iconIdInTable, showIcon, doUpdateInvNow)
			if not recurRetVal then
				recurRetValTotal = false
			end
		end
		FCOIS.lastVars.MarkItem_IconTable = nil			--#299
		FCOIS.lastVars.Last_MarkItem_IconTable = nil	--#299
		--Reset preventing variable against endless loop
		FCOIS.preventerVars.markItemAntiEndlessLoop = false
	else
		return false
	end
	--IconId is not a table, then go on. Else: return with return value in recurRetValTotal
	if not iconIdTypeIsATable then
		--Recursively set/remove markers for all icons?
		if iconId == -1 then
			--Set preventing variable against endless loop
			FCOIS.preventerVars.markItemAntiEndlessLoop = true
			local doUpdateInvNow = false
			local recurRetVal = false
			FCOIS.lastVars.MarkItem_IconTable = getAllFilterIconsAsTab() --#299
			FCOIS.lastVars.Last_MarkItem_IconTable = nil --#299
			for iconNr=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
				FCOIS.preventerVars.gMarkItemLastIconInLoop = false
				if updateInventories and iconNr == numFilterIcons then
					doUpdateInvNow = true
					FCOIS.preventerVars.gMarkItemLastIconInLoop = true
				end
				--Recursively call this function again to change each marker icon at the item
				recurRetVal = markItem(bag, slot, iconNr, showIcon, doUpdateInvNow)
				if not recurRetVal then
					recurRetValTotal = false
				end
			end
			FCOIS.lastVars.MarkItem_IconTable = nil			--#299
			FCOIS.lastVars.Last_MarkItem_IconTable = nil	--#299
			--Reset preventing variable against endless loop
			FCOIS.preventerVars.markItemAntiEndlessLoop = false
		end -- if iconId == -1 then

		--Only run this code if not all icons should be checked
		if iconId ~= -1 then
			--Allow the update of the marker here, and change it later if no update is needed
			local doUpdateMarkerNow = true
			--Get/use the (given) item instance id
			local itemId = myGetItemInstanceIdNoControl(bag, slot)
			if itemId ~= nil then
				local savedVarsMarkedItemsTableName = getSavedVarsMarkedItemsTableName()

				--Set the marker here now
				local itemIsMarked = showIcon
				if itemIsMarked == nil then itemIsMarked = false end
				--Item is already un/marked -> No need to change it
				if checkIfItemIsProtected(iconId, itemId) == itemIsMarked then
					doUpdateMarkerNow = false
				else
					--Check if the item is a researchable one, but only if icon should be shown and bag + slot are given
					-- Equipment gear 1, 2, 3, 4, 5, Research, Improve, Deconstruct or Intricate
					local iconIsResearchable = mappingVars.iconIsResearchable[iconId] or false
					if (showIcon and iconIsResearchable and (bag ~= nil and slot ~= nil)) then
						-- Check if item is researchable (as only researchable items can work as equipment too)
						if (not isItemResearchableNoControl(bag, slot, iconId)) then
							doUpdateMarkerNow = false
							recurRetValTotal = false
							--The last marker icon in a loop call of FCOIS.MarkItem is reached and we abort here becasue the item is not
							--researchable but should be marked with a marker icon which needs a researchable item?
							--Update the inventory lists then at least
							if FCOIS.preventerVars.gMarkItemLastIconInLoop then
								FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = true
							end
						end
					end
				end

--d("[FCOIS]MarkItem - updateInventories: " .. tos(updateInventories) .. ", doUpdateMarkerNow: " ..tos(doUpdateMarkerNow) ..", iconId: " ..tos(iconId) .. ", show: " ..tos(showIcon) .. ", isRestoringOrClearingMarkerIcons: " .. tos(isRestoringOrClearingMarkerIcons))
				--Change the marker now?
				if doUpdateMarkerNow then
					local settings = FCOIS.settingsVars.settings
					--Do not auto (un)mark other/all marker icons if we are restoring or clearing marker icons!
					if not isRestoringOrClearingMarkerIcons then
						--Unmark all other markers before? Only if marker should be set
						--Prevent endless loop here as FCOIS.MarkItem will call itsself recursively
						if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon and checkIfItemShouldBeDemarked(iconId) then
--d(">remove all markers now, isCharShown: " ..tos(isCharShown) .. ", bag: " ..tos(bag) .. ", charCtrlHidden: " .. tos(ZOsCtrlVars.CHARACTER:IsHidden()))
							--Check if dynamic marker items should not be removed
							local isDynamicIcon = mappingVars.iconIsDynamic
							local iconsToRemoveViaAutomaticRemoveCheck = {}
							local iconsToRemoveViaAutomaticRemoveCheckTmp = {}
							local isMarkedForAutoRemoveCheck
							local iconSettings = settings.icon[iconId]
							if iconSettings.demarkAllOthersExcludeDynamic or iconSettings.demarkAllOthersExcludeNormal then
								--Get all marked icons (including dynamic icons)
								isMarkedForAutoRemoveCheck, iconsToRemoveViaAutomaticRemoveCheck = isMarked(bag, slot, -1)
								--Check which ones are normal/dynamic and remove them from the list
								if isMarkedForAutoRemoveCheck then
									if iconsToRemoveViaAutomaticRemoveCheck and #iconsToRemoveViaAutomaticRemoveCheck > 0 then
										for iconIdForRemoveCheckLoop, isIconMarkedForRemoveCheckLoop in pairs(iconsToRemoveViaAutomaticRemoveCheck) do
											if isIconMarkedForRemoveCheckLoop then
												local isDynamicIconCheck = isDynamicIcon[iconIdForRemoveCheckLoop]
												if iconSettings.demarkAllOthersExcludeDynamic then
													if not isDynamicIconCheck then
														--Add this non-dynamic icon to the automatic remove table!
														tins(iconsToRemoveViaAutomaticRemoveCheckTmp, iconIdForRemoveCheckLoop)
													end
												elseif iconSettings.demarkAllOthersExcludeNormal then
													if isDynamicIconCheck then
														--Add this dynamic icon to the automatic remove table!
														tins(iconsToRemoveViaAutomaticRemoveCheckTmp, iconIdForRemoveCheckLoop)
													end
												end
											end
										end
										iconsToRemoveViaAutomaticRemoveCheck = iconsToRemoveViaAutomaticRemoveCheckTmp
									end
								end
							else
								iconsToRemoveViaAutomaticRemoveCheck = -1
							end
							--Remove all markers now, using the -1 iconId if all icons should be removed without any further checks,
							--or use the given table with iconIds to remove if further checks were done
							markItem(bag, slot, iconsToRemoveViaAutomaticRemoveCheck, false, isCharShown)
							FCOIS.preventerVars.markItemAntiEndlessLoop = false

						--Any other circumstances
						else
							--Prevent endless loop here as FCOIS.MarkItem will call itsself recursively
							-- Should the item be marked?
							if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon then
								--  Icon is not sell or sell at guild store
								--  and is the setting to remove sell/sell at guild store/deconstruction enabled if any other marker icon is set?
								local demarksSell = checkIfOtherDemarksSell(iconId)
								local demarksDecon = checkIfOtherDemarksDeconstruction(iconId)
								if demarksSell == true or demarksDecon == true then
									--d(">remove sell/sell at guild store if any other marker icon is set")
									--Get the icon to remove
									local iconsToRemove = {}
									iconsToRemove = getIconsToRemove(bag, slot, nil, iconId, demarksSell, demarksDecon)
									--Is the item marked with any of the icons that should be removed?
									if iconsToRemove ~= nil and isMarked(bag, slot, iconsToRemove) then
										--For each icon that should be removed, do:
										for _, iconToRemove in pairs(iconsToRemove) do
											--d(">remove icon: " ..tos(iconToRemove))
											--Remove the sell/sell at guildstore/... marker icons now
											--Is the character screen shown, then update the marker icons now?
											markItem(bag, slot, iconToRemove, false, isCharShown)
											FCOIS.preventerVars.markItemAntiEndlessLoop = false
										end
									end
								end
							else
								--d(">>isCharShown: " ..tos(isCharShown) .. ", antiEndlessLoop: " ..tos(FCOIS.preventerVars.markItemAntiEndlessLoop) .. ", updateInventories: " ..tos(updateInventories) .. ", doUpdateMarkerNow: " ..tos(doUpdateMarkerNow))
								--Is the character shown, and we are inside a loop to demark everyhting?
								--Set the inventory to update now so the removed marker icons get updated properly at the character
								if isCharShown and FCOIS.preventerVars.markItemAntiEndlessLoop and updateInventories == false then
									updateInventories = true
								end
							end
						end
					end -- if not isRestoringOrClearingMarkerIcons
					--d(">>itemIsMarked: " .. tos(itemIsMarked))
					--Shall we unmark the item? Then remove it from the SavedVars totally!
					if itemIsMarked == false then itemIsMarked = nil end
					--Un/Mark the item now
					local signedItemId = signItemId(itemId, nil, nil, nil, bag, slot)
					if signedItemId ~= nil and FCOIS[savedVarsMarkedItemsTableName] and FCOIS[savedVarsMarkedItemsTableName][iconId] then
						FCOIS[savedVarsMarkedItemsTableName][iconId][signedItemId] = itemIsMarked

						if itemIsMarked == nil then --#299 Removed the marker
							--Item got removed so check if launder/fence etc. checks need to be done now --#299
							--If FCOIS.lastVars.MarkItem_IconTable is provided then we only need to run the checkIfItemUnmarkedChecksNeeded once
							if FCOIS.lastVars.Last_MarkItem_IconTable == nil or (FCOIS.lastVars.MarkItem_IconTable ~= nil and FCOIS.lastVars.Last_MarkItem_IconTable ~= FCOIS.lastVars.MarkItem_IconTable) then
								checkIfItemUnmarkedChecksNeeded(bag, slot, FCOIS.lastVars.MarkItem_IconTable or iconId, nil, nil, itemId, nil, signedItemId)
							end
							if FCOIS.lastVars.MarkItem_IconTable ~= nil then
								FCOIS.lastVars.Last_MarkItem_IconTable = FCOIS.lastVars.MarkItem_IconTable
							end
						end
					else
						--Error message
						debugMessage("[MarkItem]","FCOIS[savedVarsMarkedItemsTableName][iconId] -> Missing iconId ("..tos(iconId)..") or signedItemId (" ..tos(signedItemId) .. " subtable for SV table ("..tos(savedVarsMarkedItemsTableName) ..")", false, FCOIS_DEBUG_DEPTH_NORMAL, false, true)
					end
					--d(">> new markedItem value: " .. tos(FCOIS[getSavedVarsMarkedItemsTableName()][iconId][signItemId(itemId, nil, nil, nil)]))
				end
			end --if itemId ~= nil
			--Update inventories or character equipment, but only needed if marker was changed
			if ( (updateInventories and doUpdateMarkerNow) or (FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem) ) then
				--d("<<UpdateInv: " ..tos(updateInventories) .. ", doUpdateMarkerNow: " .. tos(doUpdateMarkerNow) .. ", gOverrideInvUpdateAfterMarkItem: " ..tos(FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem))
				FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = false

				FCOIS_UpdateInventory(bag, isCharShown, showIcon, iconId)
			end -- if updateInventories ...
		end -- if iconId ~= -1
	end -- if not iconIdTypeIsATable
	--Return value if icon was added/removed
	return recurRetValTotal
end -- FCOIS.MarkItem
markItem = FCOIS.MarkItem

--Function to mark an item with a FCOIS marker icon using either the itemInstaceId, or the uniqueId, of that item.
--IMPORTANT: The itemInstanceId or uniqueId must be unsigned! They will get signed in this function.
--This function can be used to mark an item for a non-logged in character
-->Parameters:
---itemInstanceOrUniqueId (number):		The itemInstanceId or the uniqueId of the item to mark. Could be the realUniqueId64 or the id64String,
---									    or since FCOIS v1.9.6 the , concatenated String of "<unsignedItemInstanceIdOrItemId>,<levelNumber>,<qualityId>,<traitId>,<styleId>,<enchantId>,<isStolen>,<isCrafted>..."
---iconId (number|table): 		        Number: The iconId to change. Can be a value between 1 and FCOIS.numVars.gFCONumFilterIcons, or -1 for all.
---								        Table:	A table containing the icons to change. Table key must be a number (without gaps!) and the value must be the marker icon Id
---								        e.g. local myTableOfFCOISMarkerIcons = { [1] = FCOIS_CON_ICON_RSEARCH, [2] = FCOIS_CON_ICON_SELL }
---showIcon (boolean): 			        Flag to set if the item should be marked with the icon(s), or not
---itemLink (String):                   The itemLink of the item. Can be left NIL and will be determined via the itemId then. One of the two must be given though!
---itemId (number):                     The itemID of the item. Can be left NIL and the itemLink will be used instead. One of the two must be given though!
---addonName (String):					Can be left NIL! The unique addon name which was used to temporarily enable the uniqueId usage for the item checks.
---										-> See FCOIS API function "FCOIS.UseTemporaryUniqueIds(addonName, doUse)"
---updateInventories (boolean):    		Flag to set if the inventory lists should be updated, or not. Use this only "after updating the last marker icon", if you (de)mark many at once!
local markItemByItemInstanceId
function FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, iconId, showIcon, itemLink, itemId, addonName, updateInventories)
	markItemByItemInstanceId = FCOIS.MarkItemByItemInstanceId
	--d("[FCOIS.MarkItemByItemInstanceId] id " .. tos(itemInstanceOrUniqueId) .. ", iconId: " .. tos(iconId) .. ", show: " .. tos(showIcon))
    if itemInstanceOrUniqueId == nil then return false end
    if itemLink == nil and itemId == nil then return false end
    if showIcon == nil then showIcon = true end
	updateInventories = updateInventories or false
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	local isCharShown = (isCharacterShown() or isCompanionCharacterShown()) or false

    --Use the given itemLink or the given itemId to build a generic itemLink from it
    if itemId ~= nil and itemLink == nil then
        --Build a generic itemLink from the itemId to test the itemType
        itemLink = getItemLinkFromItemId(itemId)
    end
    --local isCharShown = not ZOsCtrlVars.CHARACTER:IsHidden()
    local recurRetValTotal = true
    --Check the type of iconId parameter
    local iconIdType = type(iconId)
    local iconIdTypeIsATable = false
    if iconIdType == "number" then
        if ((iconId > numFilterIcons) or (iconId < FCOIS_CON_ICON_LOCK and iconId ~= -1)) then return false end
    elseif iconIdType == "table" then
        --d("[FCOIS]MarkItemByItemInstanceId - IconId is a table with " .. tos(#iconId) .. " entries!")
        --IconId is a table. Set the variable so no marker icons will be changed with this 1st call of the function FCOIS.MarkItemByItemInstanceId
        iconIdTypeIsATable = true
        --Set preventing variable against endless loop
        FCOIS.preventerVars.markItemAntiEndlessLoop = true
		local doUpdateInvNow = false
        --Now change each icon inside the table
        local recurRetVal = false
		local numMarkerIconsToChange = #iconId
		local markerIconsChanged = 0
		FCOIS.lastVars.MarkItemByItemInstanceId_IconTable = iconId --#299
		FCOIS.lastVars.Last_MarkItemByItemInstanceId_IconTable = nil --#299
        for _, iconIdInTable in ipairs(iconId) do
			FCOIS.preventerVars.gMarkItemLastIconInLoop = false
			markerIconsChanged = markerIconsChanged + 1
			if updateInventories and markerIconsChanged == numMarkerIconsToChange then
				doUpdateInvNow = true
				FCOIS.preventerVars.gMarkItemLastIconInLoop = true
			end
            --Recursively call this function again to change each marker icon at the item
            recurRetVal = markItemByItemInstanceId(itemInstanceOrUniqueId, iconIdInTable, showIcon, itemLink, itemId, addonName, doUpdateInvNow)
            if not recurRetVal then
                recurRetValTotal = false
            end
        end
		FCOIS.lastVars.MarkItemByItemInstanceId_IconTable = nil --#299
		FCOIS.lastVars.Last_MarkItemByItemInstanceId_IconTable = nil --#299
        --Reset preventing variable against endless loop
        FCOIS.preventerVars.markItemAntiEndlessLoop = false
    else
        return false
    end

    --IconId is not a table, then go on. Else: return with return value in recurRetValTotal
    if not iconIdTypeIsATable then
        --Recursively set/remove markers for all icons?
        if iconId == -1 then
            --Set preventing variable against endless loop
            FCOIS.preventerVars.markItemAntiEndlessLoop = true
            local recurRetVal = false
			local doUpdateInvNow = false
			FCOIS.lastVars.MarkItemByItemInstanceId_IconTable = getAllFilterIconsAsTab() --#299
			FCOIS.lastVars.Last_MarkItemByItemInstanceId_IconTable = nil --#299
            for iconNr=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
				if updateInventories and iconNr == numFilterIcons then
					doUpdateInvNow = true
					FCOIS.preventerVars.gMarkItemLastIconInLoop = true
				end
                --Recursively call this function again to change each marker icon at the item
                recurRetVal = markItemByItemInstanceId(itemInstanceOrUniqueId, iconNr, showIcon, itemLink, itemId, addonName, doUpdateInvNow)
                if not recurRetVal then
                    recurRetValTotal = false
                end
            end
			FCOIS.lastVars.MarkItemByItemInstanceId_IconTable = nil --#299
			FCOIS.lastVars.Last_MarkItemByItemInstanceId_IconTable = nil --#299
            --Reset preventing variable against endless loop
            FCOIS.preventerVars.markItemAntiEndlessLoop = false
        end -- if iconId == -1 then

        --Only run this code if not all icons should be checked
        if iconId ~= -1 then
            --Allow the update of the marker here, and change it later if no update is needed
            local doUpdateMarkerNow = true
            if itemLink ~= nil then
				local savedVarsMarkedItemsTableName = getSavedVarsMarkedItemsTableName()
--d(">"..itemLink)
                local researchableItem = false
                --Set the marker here now
                local itemIsMarked = showIcon
                if itemIsMarked == nil then itemIsMarked = false end
                --Item is already un/marked -> No need to change it
                if checkIfItemIsProtected(iconId, itemInstanceOrUniqueId, nil, addonName) == itemIsMarked then
                    doUpdateMarkerNow = false
--d(">changed doUpdateMarkerNow to: " ..tos(doUpdateMarkerNow))
                else
                    --Check if the item is a researchable one, but only if icon should be shown and bag + slot are given
                    -- Equipment gear 1, 2, 3, 4, 5, Research, Improve, Deconstruct or Intricate
                    local iconIsResearchable = mappingVars.iconIsResearchable[iconId] or false
                    if (showIcon and iconIsResearchable) then
                        researchableItem = true
                        -- Check if item is researchable (as only researchable items can work as equipment too)
                        if (not isItemLinkResearchable(itemLink, iconId)) then
--d(">Item is not researchable. Changed doUpdateMarkerNow to: " ..tos(doUpdateMarkerNow))
                            doUpdateMarkerNow = false
                            recurRetValTotal = false
                        end
                    end
                end

--d("[FCOIS]MarkItemByItemInstanceId doUpdateMarkerNow: " ..tos(doUpdateMarkerNow) ..", iconId: " ..tos(iconId) .. ", show: " ..tos(showIcon))
                --Change the marker now?
                if doUpdateMarkerNow then
                    --Unmark all other markers before? Only if marker should be set
                    --Prevent endless loop here as FCOIS.MarkItemByItemInstanceId will call itsself recursively
                    if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon and checkIfItemShouldBeDemarked(iconId) then
--d(">remove all markers now, isCharShown: " ..tos(isCharShown) .. ", bag: " ..tos(bag) .. ", charCtrlHidden: " .. tos(ZOsCtrlVars.CHARACTER:IsHidden()))
                        --Remove all markers now
                        markItemByItemInstanceId(itemInstanceOrUniqueId, -1, false, itemLink, itemId, addonName, false)
                        FCOIS.preventerVars.markItemAntiEndlessLoop = false

                    --Any other circumstances
                    else
--d(">1")
                        --Prevent endless loop here as FCOIS.MarkItemByItemInstanceId will call itsself recursively
                        -- Should the item be marked?
						if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon then
							--d(">2")
							--  Icon is not sell or sell at guild store
							--  and is the setting to remove sell/sell at guild store/deconstruction enabled if any other marker icon is set?
							local demarksSell = checkIfOtherDemarksSell(iconId)
							local demarksDecon = checkIfOtherDemarksDeconstruction(iconId)
							if demarksSell == true or demarksDecon == true then
								--Get the icon to remove
								local iconsToRemove = {}
								iconsToRemove = getIconsToRemove(nil, nil, itemInstanceOrUniqueId, iconId, demarksSell, demarksDecon)
								--Is the item marked with any of the icons that should be removed?
								if iconsToRemove ~= nil and isMarkedByItemInstanceId(itemInstanceOrUniqueId, iconsToRemove, addonName) then
									--For each icon that should be removed, do:
									for _, iconToRemove in pairs(iconsToRemove) do
										--d(">remove icon: " ..tos(iconToRemove))
										--Remove the sell/sell at guildstore/... marker icons now
										--Is the character screen shown, then update the marker icons now?
										markItemByItemInstanceId(itemInstanceOrUniqueId, iconToRemove, false, itemLink, itemId, addonName, false)
										FCOIS.preventerVars.markItemAntiEndlessLoop = false
									end
								end
							end
							--else
							--d(">>isCharShown: " ..tos(isCharShown) .. ", antiEndlessLoop: " ..tos(FCOIS.preventerVars.markItemAntiEndlessLoop) .. ", updateInventories: " ..tos(updateInventories) .. ", doUpdateMarkerNow: " ..tos(doUpdateMarkerNow))
							--Is the character shown, and we are inside a loop to demark everyhting?
							--Set the inventory to update now so the removed marker icons get updated properly at the character
							--if isCharShown and FCOIS.preventerVars.markItemAntiEndlessLoop then
							--end
						end
                    end

--d(">>itemIsMarked: " .. tos(itemIsMarked))
                    --Shall we unmark the item? Then remove it from the SavedVars totally!
                    if itemIsMarked == false then itemIsMarked = nil end
                    --Un/Mark the item now
					local signedItemInstanceOrUniqueId = signItemId(itemInstanceOrUniqueId, nil, nil, addonName, nil, nil)
--d(">itemId: " ..tos(itemId) .. ", itemInstanceOrUniqueId: " .. tos(itemInstanceOrUniqueId) .. ", signedItemInstanceOrUniqueId: " .. tos(signedItemInstanceOrUniqueId))
					if signedItemInstanceOrUniqueId ~= nil and FCOIS[savedVarsMarkedItemsTableName] and FCOIS[savedVarsMarkedItemsTableName][iconId] then
						FCOIS[savedVarsMarkedItemsTableName][iconId][signedItemInstanceOrUniqueId] = itemIsMarked

						if itemIsMarked == nil then --#299 Removed the marker
							--Item got removed so check if launder/fence etc. checks need to be done now --#299
							--If FCOIS.lastVars.MarkItem_IconTable is provided then we only need to run the checkIfItemUnmarkedChecksNeeded once
							if FCOIS.lastVars.Last_MarkItemByItemInstanceId_IconTable == nil or (FCOIS.lastVars.MarkItemByItemInstanceId_IconTable ~= nil and FCOIS.lastVars.Last_MarkItemByItemInstanceId_IconTable ~= FCOIS.lastVars.MarkItemByItemInstanceId_IconTable) then
								checkIfItemUnmarkedChecksNeeded(nil, nil, FCOIS.lastVars.MarkItemByItemInstanceId_IconTable or iconId, itemInstanceOrUniqueId, itemLink, itemId, addonName, signedItemInstanceOrUniqueId)
							end
							if FCOIS.lastVars.MarkItemByItemInstanceId_IconTable ~= nil then
								FCOIS.lastVars.Last_MarkItemByItemInstanceId_IconTable = FCOIS.lastVars.MarkItemByItemInstanceId_IconTable
							end
						end
					else
						--Error message
						debugMessage("[MarkItemByItemInstanceId]","FCOIS[savedVarsMarkedItemsTableName][iconId] -> Missing iconId ("..tos(iconId)..") or signedItemInstanceOrUniqueId (" .. tos(signedItemInstanceOrUniqueId) .." subtable for SV table ("..tos(savedVarsMarkedItemsTableName) ..")", false, FCOIS_DEBUG_DEPTH_NORMAL, false, true)
					end
--d(">> new markedItem value: " .. tos(FCOIS[getSavedVarsMarkedItemsTableName()][iconId][signedItemInstanceOrUniqueId]))
                end
            end --if itemId ~= nil
			--Update inventories or character equipment, but only needed if marker was changed
			if ( (updateInventories and doUpdateMarkerNow) or (FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem) ) then
				--d("<<UpdateInv: " ..tos(updateInventories) .. ", doUpdateMarkerNow: " .. tos(doUpdateMarkerNow) .. ", gOverrideInvUpdateAfterMarkItem: " ..tos(FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem))
				FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = false

				FCOIS_UpdateInventory(nil, isCharShown, showIcon, iconId)
			end -- if updateInventories ...
        end -- if iconId ~= -1
    end --if not iconIdTypeIsATable then
    --Return value if icon was added/removed
    return recurRetValTotal
end -- FCOIS.MarkItemByItemInstanceId
markItemByItemInstanceId = FCOIS.MarkItemByItemInstanceId


--Global function to temporarily set the addon to use UniqueItemIds for functions "FCOIS.IsMarkedByItemInstanceId" and "FCOIS.MarkItemByItemInstanceId"
-- even if the FCOIS settings are set to use the normal itemInstanceIds.
-- The "temporary timeframe" will last from doUse = true until doUse will be set to false again for the same addonName.
--Attention: doUse will be set to false for ALL addons upon reloadui/logout/loading screens.
--->This function will return a boolean value to show if the temporary setting was enabled properly (true), or not (false).
--addonName:	String	Your addon's unique name, which must be set in order to uniquely identify which checks should use the uniqueIds. Otherwise
--				 FCOIS itsself or other addons would use uniqueIds in the "temporary timeframe" as well, where it is not wanted to happen!
--				Important: Be sure to use the SAME addonName within the FCOIS API functions FCOIS.IsMarkedByItemInstanceId (parameter "addonName")
--						    and/or FCOIS.MarkItemByItemInstanceId (parameter "addonName") AND specify a uniqueId then, instead of an itemInstanceId!
--doUse:		Boolean true/false to enable/disable the temporary setting. Will be disabled automatically after reloadui/logout/zone change
function FCOIS.UseTemporaryUniqueIds(addonName, doUse)
	if addonName == nil or addonName == "" then return false end
	if type(addonName) ~= "string" or type(doUse) ~= "boolean" then return false end
	if FCOIS.temporaryUseUniqueIds == nil then return false end
	--Enable
	if doUse == true then
		if FCOIS.temporaryUseUniqueIds[addonName] == nil then
			FCOIS.temporaryUseUniqueIds[addonName] = true
		else
			return false
		end
	--Disable
	else
		if FCOIS.temporaryUseUniqueIds[addonName] == nil then
			return false
		else
			FCOIS.temporaryUseUniqueIds[addonName] = nil
		end
	end
	return true
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS filter API functions==========================
--Global function to return boolean value, if an item is filtered
--
--bag:     The bag where the item is located
--slot:    The slotIndex where the item is located in the bag
--filterId: Specifies the filter for which the item is marked. The variable FCOIS.numVars.gFCONumFilters gives the maximum filter number.
--			Special: Filter 1 controls icons 1, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, ... (the lock icon and dynamic icons LOCKDYN)
--		 			 Filter 2 controls icons 2, 4, 6, 7 and 8 (Gear sets GEAR)
--					 Filter 3 controls icons 3, 9 and 10 (Research, deconstruction & improvement RESDECIMP)
--					 Filter 4 controls icon 5, 11 and 12 (Sell, sell in guild store & intricate SELLGUILDINT)
--filterPanelId: The panel where the filter is activated. Possible values are:
function FCOIS.IsFiltered(bag, slot, filterId, filterPanelId)
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	if (bag ~= nil and slot ~= nil and filterId ~= nil) then
        local instance = myGetItemInstanceIdNoControl(bag, slot)
		if instance == nil then return false end

		local savedVarsMarkedItemsTableName = getSavedVarsMarkedItemsTableName()

		--Workaround for empty filterPanelId
		if (filterPanelId == nil or filterPanelId == '') then
			--Fallback solution: FilterPanelId will be the inventory
			filterPanelId = LF_INVENTORY
		end

		local filterStatusVar = {}
		local activeFilterPanelIds = mappingVars.activeFilterPanelIds
		--Create 2-dimensional arrays for the filters
		for h_inv = 1, numFilterInventoryTypes, 1 do
			if activeFilterPanelIds[h_inv] == true then
				filterStatusVar[h_inv] = {false, false, false, false}
			end
		end

		--Check all filters, silently (chat output: disabled)
		filterStatusVar = filterStatus(-1, true, true)

		if (filterId ~= -1) then
			if (filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN) then
				if (checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, instance)  == true or
						checkIfItemIsProtected(nil, instance, "dynamic") == true) then
					--Is the deconstruction filter activated?
					if (filterStatusVar[filterPanelId][filterId] == true) then
						return true
					end
				end
			elseif (filterId == FCOIS_CON_FILTER_BUTTON_GEARSETS) then
				if (checkIfItemIsProtected(nil, instance, "gear") == true) then
					--Is the deconstruction filter activated?
					if (filterStatusVar[filterPanelId][filterId] == true) then
						return true
					end
				end
			elseif (filterId == FCOIS_CON_FILTER_BUTTON_RESDECIMP) then
				if (checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, instance) == true or
						checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, instance) == true or
						checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, instance) == true    ) then
					--Is the research filter activated?
					if (filterStatusVar[filterPanelId][filterId] == true) then
						return true
					end
				end
			elseif (filterId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT) then
				if (checkIfItemIsProtected(FCOIS_CON_ICON_SELL, instance) == true or
						checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, instance) == true or
						checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, instance) == true    ) then
					--Is the sell filter activated?
					--Attention: FilterId equals 4, but we need to check the value 5 here:
					if (filterStatusVar[filterPanelId][5] == true) then
						return true
					end
				end
			else
				if (FCOIS[savedVarsMarkedItemsTableName][filterId] ~= nil and checkIfItemIsProtected(filterId, instance)) then
					--Is the deconstruction filter activated?
					if (filterStatusVar[filterPanelId][filterId] == true) then
						return true
					end
				end
			end
		else
			--Check for all filters if the item is marked. return true, if any filter applies
			for filtId = 1, numFilters, 1 do
				if (filtId == FCOIS_CON_FILTER_BUTTON_LOCKDYN) then
					if (checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, instance)  == true or
							checkIfItemIsProtected(nil, instance, "dynamic") == true) then
						--Is the deconstruction filter activated?
						if (filterStatusVar[filterPanelId][filtId] == true) then
							return true
						end
					end
				elseif (filtId == FCOIS_CON_FILTER_BUTTON_GEARSETS) then
					if (checkIfItemIsProtected(nil, instance, "gear") == true) then
						--Is the deconstruction filter activated?
						if (filterStatusVar[filterPanelId][filtId] == true) then
							return true
						end
					end
				elseif (filtId == FCOIS_CON_FILTER_BUTTON_RESDECIMP) then
					if (checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, instance) == true or
							checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, instance) == true or
							checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, instance) == true    ) then
						--Is the research filter activated?
						if (filterStatusVar[filterPanelId][filtId] == true) then
							return true
						end
					end
				elseif (filtId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT) then
					if (checkIfItemIsProtected(FCOIS_CON_ICON_SELL, instance) == true or
							checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, instance) == true or
							checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, instance) == true    ) then
						--Is the sell filter activated?
						--Attention: filtId equals 4, but we need to check the value 5 here:
						if (filterStatusVar[filterPanelId][5] == true) then
							return true
						end
					end
				else
					if (checkIfItemIsProtected(filtId, instance) == true) then
						--Is the deconstruction filter activated?
						if (filterStatusVar[filterPanelId][filtId] == true) then
							return true
						end
					end
				end
			end
			return false
		end
	else
		--Current function parameters are missing. Return nil
		return nil
	end
end -- FCOIS.IsFiltered

--Global function to change a filter at the given panel Id
function FCOIS.ChangeFilter(filterId, libFiltersFilterPanelId)
--d("[FCOIS]ChangeFilter - filterId: " ..tos(filterId) .. ", libFiltersFilterPanelId: " .. tos(libFiltersFilterPanelId) .. ", gFilterWhere: " ..tos(FCOIS.gFilterWhere))
	--If filterPanelId is nil get it via LibFilters panel/fragment/other de))
	libFiltersFilterPanelId = libFiltersFilterPanelId or FCOIS.gFilterWhere
	--If filterPanelId is nil get it via LibFilters panel/fragment/other detection
	if libFiltersFilterPanelId == nil then
		if libFilters == nil then libFilters = FCOIS.libFilters end
		libFiltersFilterPanelId = libFilters:GetCurrentFilterType()
	end
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	--Valid filterId?
	if filterId == nil or filterId <= 0 or filterId > numFilters then return end
	--Valid filterPanelId?
	if libFiltersFilterPanelId == nil or libFiltersFilterPanelId <= 0
			or libFiltersFilterPanelId > numFilterInventoryTypes then return end
	local settings = FCOIS.settingsVars.settings
	--Is filtering at the current panel enabled?
	if not settings.atPanelEnabled[libFiltersFilterPanelId]["filters"] then return end
	--is the filterPanelId visible?
	-->Special check for UNIVERSAL DECONSTRUCTION
	--#254 Keybinds to change filter button state at universal deconstruction do not work
	local filterPanelIdPassedInOrFound, isUniversalDeconFilterPanel = FCOIS.GetCurrentFilterPanelIdAtDeconNPC(libFiltersFilterPanelId)
	if isUniversalDeconFilterPanel == true and filterPanelIdPassedInOrFound ~= nil then
		universalDeconGlobal = universalDeconGlobal or FCOIS.ZOControlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL
		if universalDeconGlobal.control:IsHidden() then
			return
		end
	else
		if mappingVars.gFilterPanelIdToInv[libFiltersFilterPanelId]:IsHidden() then
			return
		end
	end
	if settings.debug then debugMessage( "[ChangeFilter]","FilterId: " .. tos(filterId) .. ", FilterPanelId: " .. tos(libFiltersFilterPanelId) .. ", InventoryName: " .. mappingVars.gFilterPanelIdToInv[libFiltersFilterPanelId]:GetName(), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
	--Use the chat command handler now to emulate a filter change
	command_handler("filter" .. tos(filterId) .. " " .. tos(libFiltersFilterPanelId))
end -- FCOChangeFilter

--Function to check if the inventory context menu should not be shown as the user pressed the SHIFT key + right mouse button
--(special FCOIS behavior). If so the context menu will not be shown and other addons, which add context menu entries, shouldn't show
--their context menu neither
function FCOIS.ShouldInventoryContextMenuBeHiddden()
--d("[FCOIS]ShouldInventoryContextMenuBeHiddden")
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
--d(">contextMenuClearMarkesByShiftKey: " ..tos(contextMenuClearMarkesByShiftKey) .. ", dontShowInvContextMenu: " ..tos(FCOIS.preventerVars.dontShowInvContextMenu))
    return (contextMenuClearMarkesByShiftKey == true and FCOIS.preventerVars.dontShowInvContextMenu == true and true) or false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS get icon information API functions==========================
--Global function to get the number of possible different gear sets and their icon IDs
--Returns the number of gear sets as 1st value, and an array for the mapping from gear to the icon ID as 2nd value
function FCOIS.GetGearSetInfo()
	local gearToIcon = mappingVars.gearToIcon
	if not gearToIcon or #gearToIcon <= 0 then return nil end
    return #gearToIcon, gearToIcon
end -- FCOGetGearSetInfo

--Global function to get the number of possible different dyanmic icons and their icon IDs
--Returns the number of dynamic icons as 1st value, and an array for the mapping from dynamic icon to the icon ID as 2nd value
function FCOIS.GetDynamicInfo()
	local dynamicToIcon = mappingVars.dynamicToIcon
	if not dynamicToIcon or #dynamicToIcon <= 0 then return nil end
    return #dynamicToIcon, dynamicToIcon
end -- FCOGetDynamicInfo

--Global function to check if an item is a dynamic icon marked as gearset
function FCOIS.IsDynamicGearIcon(iconId)
	if iconId == nil then return end
	local iconToGear = mappingVars.iconToGear
	local iconToDynamic = mappingVars.iconToDynamic
	if iconToDynamic and iconToGear and iconToGear[iconId] ~= nil and iconToDynamic[iconId] ~= nil then
		return true
	end
	return false
end
local isDynamicGearIcon = FCOIS.IsDynamicGearIcon
FCOIS.isDynamicGearIcon = isDynamicGearIcon --backwards compatibility

--Global function to get the FCOIS gear marker icons.
--Optional boolean parameter "onlyDynamicOnes": nil = return all gear icons. true = the result table will contain the dynamic gear marker icons only,
---false = the result it will contain the non-dynamic (static) ones only.
--Returns a table with key number <gearIconNr> = value boolean true
function FCOIS.GetGearIcons(onlyDynamicOnes)
	local numGearIcons, gearIcons = FCOIS.GetGearSetInfo()
	if numGearIcons <= 0 or gearIcons == nil then return end
	local gearMarkerIcons = {}
	for _, gearIconId in ipairs(gearIcons) do
		local doAdd = true
		if onlyDynamicOnes ~= nil then
			local isDynamicGearIconMarker = isDynamicGearIcon(gearIconId) or false
			doAdd = (onlyDynamicOnes == true and isDynamicGearIconMarker == true and true)
					or (onlyDynamicOnes == false and not isDynamicGearIconMarker and true) or false
		end
		if doAdd == true then
			gearMarkerIcons[gearIconId] = true
		end
	end
	return gearMarkerIcons
end

--Global function to get the for a given gear set's iconId (2, 4, 6, 7 or 8) or a dynamic icon id (13, 14, 15, 16, 17, 18, 19, 20, 21, 22, ...)
--> use the constants for the marker icons please! e.g. FCOIS_CON_ICON_LOCK, FCOIS_CON_ICON_DYNAMIC_1 etc. Check file src/FCOIS_constants.lua for the available constants (top of the file)
--boolean withTexture <optional>: Add the icon's texture to the name (default: left side)
--boolean textureAtRight <optional>: Put the texture at the right side of the name
--boolean textureNonColored <optional>: If true the texture will not be colored explicitly, if false the texture will use the color of the icon settings
function FCOIS.GetIconText(iconId, withTexture, textureAtRight, textureNonColored)
	--Load the user settings, if not done already
	withTexture = withTexture or false
	textureAtRight = textureAtRight or false
	textureNonColored = textureNonColored or false
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return nil end
	if iconId == nil then return end
	local settings = FCOIS.settingsVars.settings
	local iconSettings = settings.icon and settings.icon[iconId]
	if iconSettings ~= nil and iconSettings.name ~= nil and iconSettings.name ~= "" then
		local iconName = iconSettings.name
		if withTexture == true then
			--2022-08-14 add the icon's texture left, colored from the settings of the icon
			iconName = buildIconText(iconName, iconId, textureAtRight, textureNonColored)
		end
		return iconName
	end
	return nil
end -- FCOGetIconText
local getIconText = FCOIS.GetIconText

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS localization API functions==========================
--Global function to get text for the keybindings etc.
function FCOIS.GetLocText(textName, isKeybindingText, placeHoldersTab)
--d("[FCOIS.GetLocText] textName: " .. tos(textName))
    isKeybindingText = isKeybindingText or false
	local prevVars = FCOIS.preventerVars
    prevVars.KeyBindingTexts = isKeybindingText

    --Do the localization now (if not already done)
	if not isKeybindingText or (isKeybindingText and not prevVars.gKeybindingLocalizationDone) then
		FCOIS.Localization()
	end

	prevVars.KeyBindingTexts = false

	local fcois_loc = FCOIS.localizationVars.fcois_loc
    if textName == nil or fcois_loc == nil or fcois_loc[textName] == nil then return "" end
	local returnText = fcois_loc[textName]

	if placeHoldersTab ~= nil and #placeHoldersTab > 0 then
		for _, placeHolderReplacement in ipairs(placeHoldersTab) do
			returnText = strformat(returnText, tos(placeHolderReplacement))
		end
	end
    return returnText
end -- FCOGetLocText


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS keybind API functions ======================================
--Mark the icon with a chosen keybind
--Parameters:	Number iconId: The iconId to set new
--			 	Number p_bagId: The bagid of the item to mark
--				Number p_slotIndex: The slotIndex of the item to mark
--				Boolean removeMarkers: true = Remove all other markers before setting the new one
function FCOIS.MarkItemByKeybind(iconId, p_bagId, p_slotIndex, removeMarkers)
    if iconId == nil then return false end
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	removeMarkers = removeMarkers or false
	--is the icon enabled? Otherwise abort here.
    local settings = FCOIS.settingsVars.settings
	local isIconEnabled = settings.isIconEnabled
	if not isIconEnabled[iconId] then return false end
	--local isIIfAControlChanged = false
	local bagId, slotIndex, controlBelowMouse, controlTypeBelowMouse
	local itemLink
	local itemInstanceOrUniqueId
	local itemId
--d("[FCOIS.MarkItemByKeybind] Bag: " .. tos(bagId) .. ", slot: " .. tos(slotIndex))
	if p_bagId == nil or p_slotIndex == nil then
		bagId, slotIndex, controlBelowMouse, controlTypeBelowMouse  = FCOIS.GetBagAndSlotFromControlUnderMouse()
		--No valid bagId and slotIndex was found
		if bagId ~= false or slotIndex ~= nil then
			--No IIfA mouse over GUI was triggered, so clear the data again
			FCOIS.IIfAmouseOvered = nil
		end
	else
		bagId, slotIndex =  p_bagId, p_slotIndex
	end

    --bag and slot could be retrieved?
    if bagId ~= nil and slotIndex ~= nil then
        if settings.debug then debugMessage( "[MarkItemByKeybind]","Bag: " .. tos(bagId) .. ", slot: " .. tos(slotIndex), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[FCOIS.MarkItemByKeybind] Bag: " .. tos(bagId) .. ", slot: " .. tos(slotIndex) .. ", controlBelowMouse: ".. tos(controlBelowMouse) .. ", controlTypeBelowMouse: " .. tos(controlTypeBelowMouse))
		--local mappingVars = FCOIS.mappingVars
        --Check if the item is currently marked with this icon, or not
        --Get the itemId of the bag, slot combination
        itemId = myGetItemInstanceIdNoControl(bagId, slotIndex)
        if itemId ~= nil then
			--Check if item is not researchable and research/gear/improve/deconstruct/intrictae icon is used, or if icon is a dynamic on and the research check is enabled
			-- Equipment gear (1, 2, 3, 4, 5), Research, Improve, Deconstruct, Intricate or dynamic icons
			--Check if the icon is allowed for research and if the research-enabled check is set in the settings
			local isResearchable, wasRetraitedOrReconstructed = isResearchableCheck(iconId, bagId, slotIndex)
			if not isResearchable == true then
--d("<Abort: Item not researchable")
				--Abort here if not researchable or not enabled to be marked even if not researchable in the dynamic icon settings
				return false
			end
			--Retraited/Reconstructed and mark with research icon? Not possible
			if wasRetraitedOrReconstructed == true and iconId == FCOIS_CON_ICON_RESEARCH then
            	return false
        	end
			--Companion owned item and mark with e.g. deconstruct icon? Not possible
			local isAllowed = doCompanionItemChecks(bagId, slotIndex, iconId, nil, true, nil, nil)
			if not isAllowed then
				return false
			end
			--Bound item but want to sell at guild store?
			--Check if an item is not-bound yet and only allow to mark it if it's still unbound
			--The item is already bound but it should only be un-bound to allow the marker icon
			--> Remove the marker icon from the context menu
        	--#252
			local isAllowed, isBound, isStolen = isUnboundAndNotStolenItemChecks(bagId, slotIndex, iconId, nil, nil, nil, nil)
			if not isAllowed and (isBound == true or isStolen == true) then return false end

            --Set the marker here now
            --Item is already un/marked?
			local itemIsMarked
			if removeMarkers == true then
				FCOIS.preventerVars.gCalledFromInternalFCOIS = true
				--Remove all marker icons on the item
				markItem(bagId, slotIndex, -1, false, false)
				itemIsMarked = false
			else
				itemIsMarked = isMarked(bagId, slotIndex, iconId, nil)
			end
            itemIsMarked = not itemIsMarked
			FCOIS.preventerVars.gCalledFromInternalFCOIS = true
            --Check if all markers should be removed prior to setting a new marker
            markItem(bagId, slotIndex, iconId, itemIsMarked, true)
            --If the item got marked: Check if the item is a junk item. Remove it from junk again then
			if itemIsMarked == true then
				isItemProtectedAtASlotNow(bagId, slotIndex, false, true)
			end
			--Check if item is a ring and the char/inv needs an update on a same ring item
			controlBelowMouse = controlBelowMouse or moc()
			checkIfCharOrInvNeedsRingUpdate(bagId, slotIndex, controlBelowMouse:GetParent(), itemIsMarked, iconId)
        end
    else
		--Is the controlType below the mouse given?
		if controlTypeBelowMouse ~= nil then
			--Did we try to change a marker icon at the IIfA (InventoryInsightFromAshes) UI?
			if controlTypeBelowMouse == FCOIS.otherAddons.IIFAitemsListEntryPrePattern then
				local itemIsMarked = false
				if FCOIS.IIfAmouseOvered ~= nil then
--d("[FCOIS]MarkItemByKeybind-IIfA control found: " .. FCOIS.IIfAmouseOvered.itemLink)
					local IIfAmouseOvered = FCOIS.IIfAmouseOvered
					if IIfAmouseOvered.itemLink ~= nil and IIfAmouseOvered.itemInstanceOrUniqueId ~= nil then
						itemLink = IIfAmouseOvered.itemLink
						itemInstanceOrUniqueId = IIfAmouseOvered.itemInstanceOrUniqueId
						--Get the item's id from the itemLink
						itemId = getItemIdFromItemLink(itemLink)
						--Check if item is not researchable and research/gear/improve/deconstruct/intrictae icon is used, or if icon is a dynamic on and the research check is enabled
						-- Equipment gear (1, 2, 3, 4, 5), Research, Improve, Deconstruct, Intricate or dynamic icons
						--Check if the icon is allowed for research and if the research-enabled check is set in the settings
						local isResearchable, wasRetraitedOrReconstructed = isResearchableCheck(iconId, nil, nil, itemLink)
						if not isResearchable == true then
							--Abort here if not researchable or not enabled to be marked even if not researchable in the dynamic icon settings
							return false
						end
						--Retraited/Reconstructed and mark with research icon? Not possible
						if wasRetraitedOrReconstructed == true and iconId == FCOIS_CON_ICON_RESEARCH then
							return false
						end
						--Companion owned item and mark with e.g. deconstruct icon? Not possible
						--No bagId and slotIndex given on IIfA frame (for non logged-in char, house bank etc.)
						local isAllowed = doCompanionItemChecks(nil, nil, iconId, nil, true, nil, itemLink)
						if not isAllowed then
							return false
						end
						--Item is already un/marked?
						if removeMarkers == true then
							--Remove all marker icons on the item
							markItemByItemInstanceId(itemInstanceOrUniqueId, -1, false, itemLink, itemId, nil, false)
							itemIsMarked = false
						else
							itemIsMarked = isMarkedByItemInstanceId(itemInstanceOrUniqueId, iconId)
						end
						itemIsMarked = not itemIsMarked
						--Check if all markers should be removed prior to setting a new marker
						--FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, iconId, showIcon, itemLink, itemId, addonName, updateInventories)
						markItemByItemInstanceId(itemInstanceOrUniqueId, iconId, itemIsMarked, itemLink, itemId, nil, true)
					end
				end
				if itemIsMarked == true then
					--Check if the item was marked via IIfA and this was opened at e.g. the carfting deconstruction panel and the same item was slotted currently there:
					--Remove it from the slot then if it is protected now!
					isItemProtectedAtASlotNow(nil, nil, false, true)
				end
			end
		end
        return false
    end
	return bagId, slotIndex, itemInstanceOrUniqueId, itemLink, itemId
end -- FCOIS.MarkItemByKeybind
local markItemByKeybind = FCOIS.MarkItemByKeybind

--Returns the next/previous enabled marker icon
--Parameter: Boolean respectResearchableCheck. If true the item below the mouse cursor will be checked and if it is a
--non-researchable item marker icons will not be returned which can only apply to researchable items.
local function getNextEnabledMarkerIcon(direction, currentSortOrderId, respectResearchableCheck)
	direction = direction or "next"
	if direction ~= "next" and direction ~= "prev" then return 0 end
	respectResearchableCheck = respectResearchableCheck or false
	local nextIconInDirection = 0
	local settings = FCOIS.settingsVars.settings
	local isIconEnabled = settings.isIconEnabled
	local iconSortOrder = settings.iconSortOrder
	local icons = settings.icon
	local bagId, slotIndex
	if respectResearchableCheck == true then
		bagId, slotIndex =  FCOIS.GetBagAndSlotFromControlUnderMouse()
	end

	--Get the next iconId from sortOrder
	if direction == "next" then
		if currentSortOrderId <= (numFilterIcons-1) then
			for iconsSortOrder=currentSortOrderId+1, #iconSortOrder, 1 do
				nextIconInDirection = iconSortOrder[iconsSortOrder]
				--Found the next icon in sortOrder and it is enabled?
				if icons[nextIconInDirection] ~= nil and isIconEnabled[nextIconInDirection] then
					if respectResearchableCheck == true then
						local isResearchable, wasRetraitedOrReconstructed = isResearchableCheck(nextIconInDirection, bagId, slotIndex)
						if isResearchable == true and (not wasRetraitedOrReconstructed or (wasRetraitedOrReconstructed and nextIconInDirection ~= FCOIS_CON_ICON_RESEARCH)) then
							return nextIconInDirection
						end
					else
						return nextIconInDirection
					end
				end
			end
			nextIconInDirection = 0
		end
		--If no icon was found until end of sortOrder: Start at 1 again until currentSortOder is reached
		if nextIconInDirection == 0 then
			for iconsSortOrder=1, currentSortOrderId-1, 1 do
				nextIconInDirection = iconSortOrder[iconsSortOrder]
				--Found the next icon in sortOrder and it is enabled?
				if icons[nextIconInDirection] ~= nil and isIconEnabled[nextIconInDirection] then
					if respectResearchableCheck == true then
						local isResearchable, wasRetraitedOrReconstructed = isResearchableCheck(nextIconInDirection, bagId, slotIndex)
						if isResearchable == true and (not wasRetraitedOrReconstructed or (wasRetraitedOrReconstructed and nextIconInDirection ~= FCOIS_CON_ICON_RESEARCH)) then
							return nextIconInDirection
						end
					else
						return nextIconInDirection
					end
				end
			end
		end
	elseif direction == "prev" then
		if currentSortOrderId >= 2 then
			for iconsSortOrder=currentSortOrderId-1, 1, -1 do
				nextIconInDirection = iconSortOrder[iconsSortOrder]
				--Found the prev icon in sortOrder and it is enabled?
				if icons[nextIconInDirection] ~= nil and isIconEnabled[nextIconInDirection] then
					if respectResearchableCheck == true then
						local isResearchable, wasRetraitedOrReconstructed = isResearchableCheck(nextIconInDirection, bagId, slotIndex)
						if isResearchable == true and (not wasRetraitedOrReconstructed or (wasRetraitedOrReconstructed and nextIconInDirection ~= FCOIS_CON_ICON_RESEARCH)) then
							return nextIconInDirection
						end
					else
						return nextIconInDirection
					end
				end
			end
			nextIconInDirection = 0
		end
		--If no icon was found until begin of sortOrder: Start at the end again until currentSortOder is reached
		if nextIconInDirection == 0 then
			for iconsSortOrder=numFilterIcons, currentSortOrderId+1, -1 do
				nextIconInDirection = iconSortOrder[iconsSortOrder]
				--Found the prev icon in sortOrder and it is enabled?
				if icons[nextIconInDirection] ~= nil and isIconEnabled[nextIconInDirection] then
					if respectResearchableCheck == true then
						local isResearchable, wasRetraitedOrReconstructed = isResearchableCheck(nextIconInDirection, bagId, slotIndex)
						if isResearchable == true and (not wasRetraitedOrReconstructed or (wasRetraitedOrReconstructed and nextIconInDirection ~= FCOIS_CON_ICON_RESEARCH)) then
							return nextIconInDirection
						end
					else
						return nextIconInDirection
					end
				end
			end
		end
	end
	return nextIconInDirection
end

--Function to get the first enabled marker icon
--The function will respect the icon sort order set in the settings!
--Parameter: Boolean searchBackwards. If true: search will be done backwards from last dynamic icon to lock icon
--Else if false: It will be searched forwards.
--Parameter: Boolean respectResearchableCheck. If true the item below the mouse cursor will be checked and if it is a
--non-researchable item marker icons will not be returned which can only apply to researchable items.
function FCOIS.GetFirstEnabledMarkerIcon(searchBackwards, respectResearchableCheck)
	searchBackwards = searchBackwards or false
	respectResearchableCheck = respectResearchableCheck or false
	if searchBackwards == true then
		--Get the next enabled marker icon, backwards from 0, respecting the researchability
		return getNextEnabledMarkerIcon("prev", 0, respectResearchableCheck)
	else
		--Get the next enabled marker icon, forwards from 0, respecting the researchability
		return getNextEnabledMarkerIcon("next", 0, respectResearchableCheck)
	end
	return 0
end
local getFirstEnabledMarkerIcon = FCOIS.GetFirstEnabledMarkerIcon

--Returns the last enabled marker icon of all marker icons
--The function will respect the icon sort order set in the settings!
--Parameter: Boolean respectResearchableCheck. If true the item below the mouse cursor will be checked and if it is a
--non-researchable item marker icons will not be returned which can only apply to researchable items.
function FCOIS.GetLastEnabledMarkerIcon(respectResearchableCheck)
	--Search backwards in the enabled marker icons and return first enabeld one
	return getFirstEnabledMarkerIcon(true, respectResearchableCheck)
end
local getLastEnabledMarkerIcon = FCOIS.GetLastEnabledMarkerIcon

--Cycle through the item markers by help of a keybind
local markItemCycle
function FCOIS.MarkItemCycle(direction)
	direction = direction or "standard"
	if direction ~= "standard" and direction ~= "next" and direction ~= "prev" then return false end
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
	markItemCycle = markItemCycle or FCOIS.MarkItemCycle
	--The sort order of the marker icons was defined in the FCOIS settings. Use this sort order as icon mark order
	local settings = FCOIS.settingsVars.settings
	local iconSortOrder = settings.iconSortOrder
	local icons = settings.icon

	local function getNextAndPreviousMarkerIcon(currentSortOrderId)
		if currentSortOrderId == nil then return nil, nil end
		local nextIconId, prevIconId = 0, 0
		nextIconId = getNextEnabledMarkerIcon("next", currentSortOrderId, true)
		prevIconId = getNextEnabledMarkerIcon("prev", currentSortOrderId, true)
		return nextIconId, prevIconId
	end
	local function checkRemoveAndGetIconToMark(bagId, slotIndex)
		--Get the current marker icon. This will only work if only 1 marker icon is set!
		local currentIconId = 0
		local next, prev = 0, 0
		FCOIS.preventerVars.gCalledFromInternalFCOIS = true
		local itemIsMarked, markedIconsArray = isMarked(bagId, slotIndex, -1, nil)
		if itemIsMarked == true and markedIconsArray ~= nil then
			local markerIconsApplied = 0
			for iconId, isMarkedIconId in pairs(markedIconsArray) do
				if isMarkedIconId == true then
					markerIconsApplied = markerIconsApplied + 1
					currentIconId = iconId
				end
				if markerIconsApplied > 1 then
					currentIconId = 0
					break
				end
			end
			--Only 1 marker icon is set and the used iconId is known?
			if markerIconsApplied == 1 and currentIconId ~= 0 then
				--Check which sort order this marker icon currently got
				local currentSortOrderId = icons[currentIconId].sortOrder or 0
				if currentSortOrderId > 0 then
					--Get the next and previous sort order's marker icon
					next, prev = getNextAndPreviousMarkerIcon(currentSortOrderId)
					--[[
					--Will be done in FCOIS.MarkItemByKeybind now to prevent icons beeing removed and then set again in MarkItemByKeybind
					if next ~= 0 and prev ~= 0 then
						--Remove the current marker icon
						markItem(bagId, slotIndex, currentIconId, false, false)
					end
					]]
				end
			end
		elseif not itemIsMarked then
			--Get first enabled marker icon searching forwards
			next = getFirstEnabledMarkerIcon(false, true)
			prev = getLastEnabledMarkerIcon(true)
		end
--d("next: "..tos(next) ..", prev: " ..tos(prev))
		--Return the next and previous iconId
		return next, prev, currentIconId
	end

	--Mark with standard icon
	if direction == "standard" then
		--Setting to cycle the marker icon "up" via the "standard" keybind is enabled?
		local cycleMarkerSymbolOnKeybind = settings.cycleMarkerSymbolOnKeybind or false
		if cycleMarkerSymbolOnKeybind == true then
			FCOIS.preventerVars.gCalledFromInternalFCOIS = true
			markItemCycle("next")
		else
			--Not enabled: Set the standard marker icon
			local standardIconOnKeybind = settings.standardIconOnKeybind
			if standardIconOnKeybind ~= nil and standardIconOnKeybind > 0 and standardIconOnKeybind <= numFilterIcons then
	--d("Mark item with standard markersymbol from settings: " .. settings.standardIconOnKeybind)
				local iconId = standardIconOnKeybind
				local isIconEnabled = settings.isIconEnabled
				if not isIconEnabled[iconId] then
					--d(">> IconId was not enabled in the settings! Taking iconId 1")
					iconId = FCOIS_CON_ICON_LOCK --the lock symbol will be always enabled!
				end
				--Mark/Unmark the item now
				FCOIS.preventerVars.gCalledFromInternalFCOIS = true
				markItemByKeybind(iconId)
			end
		end

	--Mark with next icon
	elseif direction == "next" then
--d("Mark item with next markersymbol")
		if iconSortOrder ~= nil and icons ~= nil then
			local bagId, slotIndex = FCOIS.GetBagAndSlotFromControlUnderMouse()
--d("bag, slot: " ..tos(bagId) .. ", " .. tos(slotIndex))
			if bagId and slotIndex then
				--Check if only one marker icon is set, remove it, get the next and previous marker icon IDs
				local next, _ = checkRemoveAndGetIconToMark(bagId, slotIndex)
				if next and next > 0 then
					--Mark with the next marker icon
					FCOIS.preventerVars.gCalledFromInternalFCOIS = true
					markItemByKeybind(next, bagId, slotIndex, true) -- remove old marker icons
				end
			end
		end

	--Mark with previous icon
	elseif direction == "prev" then
--d("Mark item with prev markersymbol")
		if iconSortOrder ~= nil and icons ~= nil then
			local bagId, slotIndex = FCOIS.GetBagAndSlotFromControlUnderMouse()
			if bagId and slotIndex then
				--Check if only one marker icon is set, remove it, get the next and previous marker icon IDs
				local _, prev = checkRemoveAndGetIconToMark(bagId, slotIndex)
				if prev and prev > 0 then
					--Mark with the previous marker icon
					FCOIS.preventerVars.gCalledFromInternalFCOIS = true
					markItemByKeybind(prev, bagId, slotIndex, true) -- remove old marker icons
				end
			end
		end

	end
end
markItemCycle = FCOIS.MarkItemCycle

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS marker icon API functions ==========================
function FCOIS.CountMarkerIconsEnabled()
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return false end
    local iconsEnabledCount = 0
    local dynIconsEnabledCount = 0
    local isDynamicIcon = mappingVars.iconIsDynamic
	local settings = FCOIS.settingsVars.settings
	local isIconEnabled = settings.isIconEnabled
    for iconNr=FCOIS_CON_ICON_LOCK, numFilterIcons do
        if isIconEnabled[iconNr] then
            if isDynamicIcon[iconNr] then
                dynIconsEnabledCount = dynIconsEnabledCount +1
            end
            iconsEnabledCount = iconsEnabledCount + 1
        end
    end
    return iconsEnabledCount, dynIconsEnabledCount
end


--Check if a marker icon was changed manually via the context menu e.g.
function FCOIS.GetMarkerIconChangedManually()
	local prevVars = FCOIS.preventerVars
	if prevVars.markerIconChangedManually then
		return true
	end
	return false
end

--Check if an inventory list refresh is active
-- (to prevent addons applying the inventoryRow's setupCallback function during the refresh again and again)
function FCOIS.GetListIsRefreshing()
    local prevVars = FCOIS.preventerVars
    if prevVars.isInventoryListUpdating then
        return true
    end
    return false
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS settings API functions ==========================
--Function to load the needed settings from an external addon and return it to the caller if needed
--> Will return the whole settings structure so you got access to:
----> returnTable. settings:			SavedVars (current char/global for all chars -> dependent on the settings) for the addon
----> returnTable. defaults:			default values for the SavedVars for the addon
----> returnTable. defaultSettings:		Global base settings (all character settings) for the addon, like language, saved mode (each character, account wide)

--Settings will be loaded normally "again" within FCOIS addon
function FCOIS.BuildAndGetSettingsFromExternal()
	--Load the needed user settings -> file FCOIS-Settings.lua, from the SavedVariables with flag "external call" = true
	if not checkIfFCOISSettingsWereLoaded(true, not addonVars.gAddonLoaded) then return nil end
	return FCOIS.settingsVars
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS LibAddonMenu 2.0 API functions ==========================
--Function to build a LAM dropdown choices and choicesValues table for the available FCOIS marker icons
--> Type: String - can be one of the following one:
---> standard: A list with the marker icons, using the name from the settings, including the icon as texture (if "withIcons" = true) and disabled icons are marked red.
---> standardNonDisabled: A list with the marker icons, using the name from the settings, including the icon as texture (if "withIcons" = true) and disabled icons are not marked in any other way then enabled ones.
---> keybinds: A list with the marker icons, using the fixed name from the translations, including the icon as texture (if "withIcons" = true) and disabled icons are marked red.
---> gearSets: A list with only the gear set marker icons, using the name from the settings, including the icon as texture (if "withIcons" = true) and disabled icons are marked red.
---In all cases the icons added to the dropdown and dropdown values will only include the dynamic icons which are currently enabled via the settings slider
---"Max. dynamic icons"
--> withIcons: Boolean - Add the textures of the marker icons to the list entries
--> withNoneEntry: Boolean - Add a "- No icon selected -" entry to the dropdown box, as first entry, returning the value of FCOIS_CON_ICON_NONE (-100)
-->returns:
--->table iconsDropdownList:				A table with key = non-gap number and value = the FCOIS gear icon text, including the icon and the "none" entry depending on the parameters of the function)
--->table iconsDropdownValuesList:			A table with key = non-gap number and value = the FCOIS gear icon ID (e.g. FCOIS_CON_ICON_LOCK, etc.), including the icon and the "none" entry depending on the parameters of the function)
--->table iconsDropdownValuesTooltipsList:	A table with key = non-gap number and value = the FCOIS gear icon tooltip text, including the icon and the "none" entry depending on the parameters of the function)
function FCOIS.GetLAMMarkerIconsDropdown(type, withIcons, withNoneEntry)
	if type == nil then type = "standard" end
	withIcons = withIcons or false
	withNoneEntry = withNoneEntry or false
	local FCOISlocVars = FCOIS.localizationVars
	local locVars = FCOISlocVars.fcois_loc
    local colorIconEndStr   = FCOIS_CON_ICON_SUFFIX_COLOR
	local nameIconEndStr    = FCOIS_CON_ICON_SUFFIX_NAME
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return nil end
	local settings = FCOIS.settingsVars.settings
	local isIconEnabled = settings.isIconEnabled
	local isGearIcon = settings.iconIsGear
	local isDynamicIcon = mappingVars.iconIsDynamic
	local icon2DynIconCountNr = mappingVars.iconToDynamic
	local numDynIconsUsable = settings.numMaxDynamicIconsUsable
	local iconIsResearchable = mappingVars.iconIsResearchable

	--Build icons choicesValues list
	local function buildIconsChoicesValuesList(typeToCheck, p_withNoneEntry)
		--Shall the icons values list contain non-enabled icons?
        local typeToEnabledCheck = {
            ['standard']            = false,
            ['standardNonDisabled'] = true,
            ['keybinds']            = false,
            ['gearSets']            = false,
			['recipe'] 				= true,
        }
        local choicesValuesList = {}
        local doCheckForEnabledIcons = typeToEnabledCheck[typeToCheck] or false
		local isRecipe = typeToCheck == "recipe"
		local counter = 0
		for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
			local goOn = false
			local isGear = isGearIcon[i]
			local isDynamic = isDynamicIcon[i]
			if isDynamic then
				--Map the icon to the dynamic icon counter
				local dynIconCountNr = icon2DynIconCountNr[i]
				--Is the dynamic icon enabled or disabled via the slider "Max dynamic icons"?
				if dynIconCountNr <= numDynIconsUsable then
					goOn = true
				end
			elseif isGear then
				goOn = true
			else
				goOn = true
			end
			--Do not allow icons that are gear, or non-researchable ones as they cannot be applied t recipes
			if isRecipe == true then
				if isGear == true or iconIsResearchable[i] then
					goOn = false
				end
			end
			if goOn then
				local doAddIconValueNow = true
				if doCheckForEnabledIcons then
					doAddIconValueNow = isIconEnabled[i]
				end
				if doAddIconValueNow and typeToCheck == "gearSets" then
					doAddIconValueNow = isGearIcon[i]
				end
				if doAddIconValueNow then
					counter = counter + 1
					choicesValuesList[counter] = i
				end
			end
		end
		if p_withNoneEntry == true and (choicesValuesList and #choicesValuesList>0) then
			tins(choicesValuesList, 1, FCOIS_CON_ICON_NONE)
		end
        return choicesValuesList
	end

	--Build the icon lists for the options
	local function buildIconsChoicesList(typeToCheck, p_withIcons, p_withNoneEntry)
		local iconsList = {}
		if typeToCheck == 'standard' or typeToCheck == 'standardNone' then
			for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
  				local goOn = false
				local isGear = isGearIcon[i]
				local isDynamic = isDynamicIcon[i]
				if isDynamic then
					--Map the icon to the dynamic icon counter
					local dynIconCountNr = icon2DynIconCountNr[i]
					--Is the dynamic icon enabled or disabled via the slider "Max dynamic icons"?
					if dynIconCountNr <= numDynIconsUsable then
						goOn = true
					end
				elseif isGear then
					goOn = true
				else
					goOn = true
				end
				if goOn then
					local locNameStr = FCOISlocVars.iconEndStrArray[i] or (((isDynamic or isGear) and nameIconEndStr) or colorIconEndStr)
					local iconIsEnabled = isIconEnabled[i]
					FCOIS.preventerVars.gCalledFromInternalFCOIS = true
					local iconName = getIconText(i) or locVars["options_icon" .. tos(i) .. "_" .. locNameStr] or "Icon " .. tos(i)
					--Should the icon be shown at the start of the text too?
					if p_withIcons then
						local iconNameWithIcon = buildIconText(iconName, i, false, not iconIsEnabled)
						iconName = iconNameWithIcon
					end
					--Is the icon enabled?
					if iconIsEnabled then
						iconsList[i] = iconName
					else
						--Icon is not enabled, so color the entry red (or strike it through)
						iconsList[i] = "|cFF0000" .. iconName .. "|r"
					end
				end
			end

		elseif typeToCheck == 'recipe' then
			local counter = 0
			for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
  				local goOn = false
				local isGear = isGearIcon[i]
				local isDynamic = isDynamicIcon[i]
				local iconIsEnabled = isIconEnabled[i]
				if not iconIsEnabled or iconIsResearchable[i] or isGear == true then
					goOn = false
				else
					if isDynamic then
						--Map the icon to the dynamic icon counter
						local dynIconCountNr = icon2DynIconCountNr[i]
						--Is the dynamic icon enabled or disabled via the slider "Max dynamic icons"?
						if dynIconCountNr <= numDynIconsUsable then
							goOn = true
						end
					else
						goOn = true
					end
				end
				if goOn then
					counter = counter + 1
					local locNameStr = FCOISlocVars.iconEndStrArray[i] or (((isDynamic or isGear) and nameIconEndStr) or colorIconEndStr)
					FCOIS.preventerVars.gCalledFromInternalFCOIS = true
					local iconName = getIconText(i) or locVars["options_icon" .. tos(i) .. "_" .. locNameStr] or "Icon " .. tos(i)
					--Should the icon be shown at the start of the text too?
					if p_withIcons then
						local iconNameWithIcon = buildIconText(iconName, i, false, not iconIsEnabled)
						iconName = iconNameWithIcon
					end
					iconsList[counter] = iconName
				end
			end

		elseif typeToCheck == 'standardNonDisabled' then
			for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
				if isIconEnabled[i] then
					local isGear = isGearIcon[i]
					local isDynamic = isDynamicIcon[i]
					local locNameStr = FCOISlocVars.iconEndStrArray[i] or (((isDynamic or isGear) and nameIconEndStr) or colorIconEndStr)
					local iconName = locVars["options_icon" .. tos(i) .. "_" .. locNameStr]
					--Should the icon be shown at the start of the text too?
					if p_withIcons then
						local iconNameWithIcon = buildIconText(iconName, i, false, true) -- no color as row is completely red
						iconName = iconNameWithIcon
					end
                    iconsList[i] = iconName
				end
			end
		elseif typeToCheck == 'keybinds' then
			--Check for each icon if it is enabled in the settings
			for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
				local goOn = false
				local isGear = isGearIcon[i]
				local isDynamic = isDynamicIcon[i]
				if isDynamic then
					--Map the icon to the dynamic icon counter
					local dynIconCountNr = icon2DynIconCountNr[i]
					--Is the dynamic icon enabled or disabled via the slider "Max dynamic icons"?
					if dynIconCountNr <= numDynIconsUsable then
						goOn = true
					end
				elseif isGear then
					goOn = true
				else
					goOn = true
				end
				if goOn then
					local locNameStr = FCOISlocVars.iconEndStrArray[i] or (((isDynamic or isGear) and nameIconEndStr) or colorIconEndStr)
					local iconName = locVars["options_icon" .. tos(i) .. "_" .. locNameStr]
					local iconIsEnabled = isIconEnabled[i]
					--Should the icon be shown at the start of the text too?
					if p_withIcons then
						local iconNameWithIcon = buildIconText(iconName, i, false, not iconIsEnabled)
						iconName = iconNameWithIcon
					end
					--Is the icon enabled?
					if iconIsEnabled then
						iconsList[i] = iconName
					else
						--Icon is not enabled, so color the entry red (or strike it through)
						iconsList[i] = "|cFF0000" .. iconName .. "|r"
					end
				end
			end
		elseif typeToCheck == 'gearSets' then
			local gearCounter = 1
			for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
				--Check if icon is a gear set icon and if it's enabled
				local goOn = false
				local isGear = isGearIcon[i]
				local isDynamic = isDynamicIcon[i]
				if isGear then
					if isDynamic then
						--Map the icon to the dynamic icon counter
						local dynIconCountNr = icon2DynIconCountNr[i]
						--Is the dynamic icon enabled or disabled via the slider "Max dynamic icons"?
						if dynIconCountNr <= numDynIconsUsable then
							goOn = true
						end
						goOn = true
					else
						goOn = true
					end
					if goOn then
						local iconIsEnabled = isIconEnabled[i]
						local locNameStr = FCOISlocVars.iconEndStrArray[i] or (((isDynamic or isGear) and nameIconEndStr) or colorIconEndStr)
			            FCOIS.preventerVars.gCalledFromInternalFCOIS = true
						local iconName = getIconText(i) or locVars["options_icon" .. tos(i) .. "_" .. locNameStr] or "Icon " .. tos(i)
						--Should the icon be shown at the start of the text too?
						if p_withIcons then
							local iconNameWithIcon = buildIconText(iconName, i, false, not iconIsEnabled)
							iconName = iconNameWithIcon
						end
						--Is the icon enabled?
						if iconIsEnabled then
							iconsList[gearCounter] = iconName
						else
							--Icon is not enabled, so color the entry red (or strike it through)
							iconsList[gearCounter] = "|cFF0000" .. iconName .. "|r"
						end
						gearCounter = gearCounter + 1
					end
				end
			end
        end
		if p_withNoneEntry == true and (iconsList and #iconsList>0) then
			tins(iconsList, 1, locVars["options_icon_none"])
		end

		return iconsList
    end

	--Build icons choicesValues tooltips list
	local function buildIconsChoicesValuesTooltipsList(typeToCheck, p_withIcons, p_withNoneEntry)
        --Currently now own tooltips -> Using the names of function buildIconsChoicesList
	end

    local iconsDropdownList, iconsDropdownValuesList = buildIconsChoicesList(type, withIcons, withNoneEntry), buildIconsChoicesValuesList(type, withNoneEntry)
    --local iconsDropdownValuesTooltipsList = buildIconsChoicesValuesTooltipsList(type, withIcons, withNoneEntry)
	local iconsDropdownValuesTooltipsList = iconsDropdownList

	if iconsDropdownList and iconsDropdownValuesList and #iconsDropdownList ~= #iconsDropdownValuesList then
		d(strformat("[FCOIS]ERROR: GetLAMMarkerIconsDropdown - typeToCheck: %s, withIcons: %s, withNoneEntry: %s -> count entries/values: %s/%s", tos(type), tos(withIcons), tos(withNoneEntry), tos(#iconsDropdownList), tos(#iconsDropdownValuesList)))
		--For debugging
		if GetDisplayName() == "@Baertram" then
			FCOIS._errorDropDownList = ZO_ShallowTableCopy(iconsDropdownList)
			FCOIS._errorDropDownListValues = ZO_ShallowTableCopy(iconsDropdownValuesList)
			--Equal the two table entry counts so that LAM is not erroring out
			if #iconsDropdownValuesList > #iconsDropdownList then
				for idx, iconText in ipairs(iconsDropdownValuesList) do
					if idx > #iconsDropdownList then
						table.remove(iconsDropdownValuesList, idx)
					end
				end
			else
				for idx, iconText in ipairs(iconsDropdownList) do
					if idx > #iconsDropdownValuesList then
						table.remove(iconsDropdownList, idx)
					end
				end
			end
		end
	end
	return iconsDropdownList, iconsDropdownValuesList, iconsDropdownValuesTooltipsList
end

--Mark an item by a keybind and run a command (functions defined in this function) on it
--Parameters: 	markerIconsToApply Table of marker icons or -1 for all
--				commandToRun String defining the functions to run on the item
function FCOIS.MarkAndRunOnItemByKeybind(markerIconsToApply, commandToRun)
	--d("[FCOIS]MarkAndRunOnItemByKeybind-commandToRun: " ..tos(commandToRun))
	if markerIconsToApply == nil or commandToRun == nil or commandToRun == "" then return end
	if not checkIfFCOISSettingsWereLoaded(FCOIS.preventerVars.gCalledFromInternalFCOIS, not addonVars.gAddonLoaded) then return nil end
	local settings = FCOIS.settingsVars.settings

	--Junk the item now via the keybind?
	if commandToRun == "junk" then
		--#291 API func for mass move junk not working if keybind is disabled
		local keybindMoveItemToJunkEnabled = settings.keybindMoveItemToJunkEnabled
		if not keybindMoveItemToJunkEnabled then return end

		--Add the 'sell' icon?
		local isJunkNow
		local addSellIconAsAddToJunk = settings.keybindMoveItemToJunkAddSellIcon
		--Get bagId and slotIndex or the IIfA data of the item below the mouse
		local bagId, slotIndex, _, _ = FCOIS.GetBagAndSlotFromControlUnderMouse()
		if bagId ~= false or slotIndex then
			--No IIfA mouse over GUI was triggered, so clear the data again
			FCOIS.IIfAmouseOvered = nil
		end
		if bagId and slotIndex then
			--Is the item already in the junk?
			isJunkNow = IsItemJunk(bagId, slotIndex) or false
			--Add the sell icon if it is not junked already
			if not isJunkNow and addSellIconAsAddToJunk == true then
				FCOIS.preventerVars.gCalledFromInternalFCOIS = true
				--Remove all marker icons
				--Update not needed as it will be moved away to junk to another tab (tab change will update the visible inventory)
				markItem(bagId, slotIndex, -1, false, false)
				FCOIS.preventerVars.gCalledFromInternalFCOIS = true
				--Set the sell icon now
				markItem(bagId, slotIndex, FCOIS_CON_ICON_SELL, true, false)
				--If the item is already junked then remove all marker icons again and remove it from the junk
			elseif isJunkNow == true then
				FCOIS.preventerVars.gCalledFromInternalFCOIS = true
				--Remove all marker icons
				--Update not needed as it will be moved away from junk to another tab (tab change will update the visible inventory)
				markItem(bagId, slotIndex, -1, false, false)
			end
			--Invert the junk state of the item now
			SetItemIsJunk(bagId, slotIndex, not isJunkNow)

			--[[
            --Currently disabled as it would only work for items in your inventory and we cannot check this easily via the IIfA UI
            else
                --Is the controlType below the mouse given?
                if controlTypeBelowMouse ~= nil then
                    --Did we try to change a marker icon at the InventoryInsightFromAshes UI?
                    if controlTypeBelowMouse == FCOIS.otherAddons.IIFAitemsListEntryPrePattern then
                        if FCOIS.IIfAmouseOvered ~= nil then
        --d("[FCOIS]MarkItemByKeybind-IIfA control found: " .. FCOIS.IIfAmouseOvered.itemLink)
                            local IIfAmouseOvered = FCOIS.IIfAmouseOvered
                            if IIfAmouseOvered.itemLink ~= nil and IIfAmouseOvered.itemInstanceOrUniqueId ~= nil then
                                local itemLink = IIfAmouseOvered.itemLink
                                local itemInstanceOrUniqueId = IIfAmouseOvered.itemInstanceOrUniqueId
                                --Get the item's id from the itemLink
                                local itemId = FCOIS.getItemIdFromItemLink(itemLink)
                                --Remove all marker icons on the item
                                markItemByItemInstanceId(itemInstanceOrUniqueId, -1, false, itemLink, itemId, nil, false)
                                if addSellIconAsAddToJunk == true then
                                    --FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, iconId, showIcon, itemLink, itemId, addonName, updateInventories)
                                    markItemByItemInstanceId(itemInstanceOrUniqueId, FCOIS_CON_ICON_SELL, true, itemLink, itemId, nil, true)
                                end
                                --SetItemIsJunk(bagId, slotIndex, true)
                            end
                        end
                    end
                end
            ]]
		end
	end
end

--==========================================================================================================================================
-- 															FCOIS API - END
--==========================================================================================================================================
