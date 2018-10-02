--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons

--==========================================================================================================================================
-- 															FCOIS API
--==========================================================================================================================================
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS Protection check API functions (with possbility to show alert messages) =============================
--[[ Description:

	Basically the protection check functions of this API (FCOIS.Is*****Locked) will call the function:
	FCOIS.callDeconstructionSelectionHandler(integer bag, integer slot, boolean echo, boolean overrideChatOutput, boolean suppressChatOutput, boolean overrideAlert, boolean suppressAlert boolean calledFromExternalAddon, libFilters2.x->LF_filterPanelID panelId)

	You need to give the function call the item's bag and slotId, and the libFilters 2.x filter panel ID of the desired panel that you want to check, e.g. the crafting research panel.
    It will think we are at the research tab of the crafting station (and not at the crafting stations  create, deconstruct, or improve tabs)
    Research panel libFilters 2.x constant:    LF_SMITHING_RESEARCH

    Function call parameters:
    Integer bag:                                                The bag index of the inventory/bank/guild bank/craft bag/equipment item
    Integer slotIndex:                                          The slot index of the inventory/bank/guild bank/craft bag/equipment item
    Boolean parameter echo: 									if true the chat output or alert message will be shown if protected.
    Boolean parameters overrideChatOutput / overrideAlert: 	    if true the FCOIS settings for the chat/alert messages will be overwritten so they get shown from your call.
    Boolean parameters suppressChatOutput / suppressAlert: 		if true the FCOIs settings for the chat/alert message will be suppressed so no message is shown from your call.
    Boolean parameter calledFromExternalAddon: 					Must be true if the call comes from another addon then FCOIS. Otherwise the protective functions won't work properly! Must be true for these protective check functions too!
    Integer parameter panelId: 									libFilters 2.x filter constant LF_* for the panel where the check should be done. If this variable is nil FCOIS will detect the active panel automatically.
]]
--Function to call the itemSelectionHandler from other addons (e.g. DoItAll with FCOItemSaver support)
--Return true:   Item is protected
--Returns false: Item is not protected
function FCOIS.callItemSelectionHandler(bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
    echo = echo or false
    isDragAndDrop = isDragAndDrop or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    calledFromExternalAddon = calledFromExternalAddon or false

    --Return true to "protect" an item, if the bag and slot are missing
    if bag == nil or slot == nil then return true end
    --Call the item selection handler method now for the item
    return FCOIS.ItemSelectionHandler(bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
end

--Function to call the DeconstructionSelectionHandler from other addons (e.g. DoItAll with FCOItemSaver support)
--Return true:   Item is protected
--Returns false: Item is not protected
function FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
    echo = echo or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    calledFromExternalAddon	= calledFromExternalAddon or false

    --Return true to "protect" an item, if the bag and slot are missing
    if bag == nil or slot == nil then return true end
    --Call the item selection handler method now for the item
    return FCOIS.DeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
end


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
    return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true)
end

-- ===== ANTI DESTROY =====
-- FCOIS prevention for being destroyed at the current panel
function FCOIS.IsDestroyLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true)
end

-- ===== ANTI TRADE =====
-- FCOIS prevention for being traded
function FCOIS.IsTradeLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_TRADE)
end

-- ===== ANTI MAIL =====
-- FCOIS prevention for being mailed
function FCOIS.IsMailLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_MAIL_SEND)
end

-- ===== ANTI SELL =====
-- FCOIS prevention for being sold at a vendor
function FCOIS.IsVendorSellLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_VENDOR_SELL)
end

-- FCOIS prevention for being sold at the guild store
function FCOIS.IsGuildStoreSellLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_GUILDSTORE_SELL)
end

-- FCOIS prevention for being sold at a fence
function FCOIS.IsFenceSellLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_FENCE_SELL)
end

-- ===== ANTI LAUNDER =====
-- FCOIS prevention for being laundered
function FCOIS.IsLaunderLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_FENCE_LAUNDER)
end

-- ===== ANTI Deposit =====
-- FCOIS prevention for being depositted to player bank
--> ATTENTION: FCOIS is currently NOT protecting the deposit of items to a player bank.
-- This is always allowed!
-- If you want to check if there is a marker icon on the item you want to deposit, and thus not allow to deposit it,
-- use the function FCOIS.IsMarked() please -> See below in this API file!
function FCOIS.IsPlayerBankDepositLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_BANK_DEPOSIT)
end

-- FCOIS prevention for being depositted to a guild bank
--> ATTENTION: FCOIS is currently only protecting the deposit of items to a guild bank, if you have enabled the setting for it and
-- if you are not allowed to withdraw this item anymore (missing rights in that guild).
-- This applies even to non marked items, so there does not need to be a marker icon on the item!
-- Otherwise the deposit is always allowed!
-- If you want to check if there is a marker icon on the item you want to deposit, and thus not allow to deposit it,
-- use the function FCOIS.IsMarked() please -> See below in this API file!
function FCOIS.IsGuildBankDepositLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_GUILDBANK_DEPOSIT)
end

-- ===== ANTI Withdraw =====
-- FCOIS prevention for being withdrawn from player bank
--> ATTENTION: FCOIS is currently NOT protecting the withdraw of items from a player bank.
-- This is always allowed!
-- If you want to check if there is a marker icon on the item you want to withdraw, and thus not allow to withdraw it,
-- use the function FCOIS.IsMarked() please -> See below in this API file!
function FCOIS.IsPlayerBankWithdrawLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_BANK_WITHDRAW)
end

-- FCOIS prevention for being withdrawn from a guild bank
--> ATTENTION: FCOIS is currently NOT protecting the withdraw of items from a guild bank.
-- This is always allowed!
-- If you want to check if there is a marker icon on the item you want to withdraw, and thus not allow to withdraw it,
-- use the function FCOIS.IsMarked() please -> See below in this API file!
function FCOIS.IsGuildBankWithdrawLocked(bagId, slotIndex)
    --Don't show chat output and don't show alert message
    return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_GUILDBANK_WITHDRAW)
end


-- ===== ANTI CRAFTING =====
-- FCOIS prevention for being created as enchantment
function FCOIS.IsEnchantingCreationLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_ENCHANTING_CREATION)
end

-- FCOIS prevention for being refined
function FCOIS.IsRefinementLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_REFINE)
end

-- FCOIS prevention for being deconstructed
function FCOIS.IsDeconstructionLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_DECONSTRUCT)
end

-- FCOIS prevention for being improved
function FCOIS.IsImprovementLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_IMPROVEMENT)
end

-- FCOIS prevention for jewelry being refined
function FCOIS.IsJewelryRefinementLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_REFINE)
end

-- FCOIS prevention for jewelry being deconstructed
function FCOIS.IsJewelryDeconstructionLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_DECONSTRUCT)
end

-- FCOIS prevention for jewelry being improved
function FCOIS.IsJewelryImprovementLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_JEWELRY_IMPROVEMENT)
end

-- FCOIS prevention for being extracted from a glyphe
function FCOIS.IsEnchantingExtractionLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_ENCHANTING_EXTRACTION)
end

-- FCOIS prevention for being researched
function FCOIS.IsResearchLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_SMITHING_RESEARCH)
end

-- FCOIS prevention for being destroyed at the alchemy station
function FCOIS.IsAlchemyDestroyLocked(bagId, slotIndex)
	--Don't show chat output and don't show alert message
	return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, LF_ALCHEMY_CREATION)
end

-- ===== ANTI EQUIP =====
-- FCOIS prevention for being equipped
function FCOIS.IsEquipLocked(bagId, slotIndex)
	--Only if the "ask before bind" setting is enabled: Every marked item that is not yet bound is protected
    if not FCOIS.settingsVars.settings.askBeforeEquipBoundItems or not FCOIS.isItemBindable(bagId, slotIndex) then return false end

	--Only the bindable AND non-bound equipment items result in a positive result = item is locked
    return true

    --Check if any marker icon is set on the item
    --local isItemMarked = FCOIS.IsMarked(bagId, slotIndex, -1) or false
    --return isItemMarked
end

-- ===== ANTI Junk =====
-- FCOIS prevention for being marked as junk (e.g. in AddOn Dustman)
function FCOIS.IsJunkLocked(bagId, slotIndex)
	local isItemProtectedAgainstJunk = false
    --Check all marker icons and exclude the icon for "Sell"
    local markedIcons = {}
    local settings = FCOIS.settingsVars.settings
	local isItemMarked, markedIcons = FCOIS.IsMarked(bagId, slotIndex, -1, FCOIS_CON_ICON_SELL)
    --Is the item marked with any of the marker items (except "sell" item)
    if isItemMarked and markedIcons ~= nil then
        --Check each of the dynamic icons in the returned table "markedIcons".
        --Loop over the returned array and check all icons where the marker is set
        local oneMarkedDynamicIconFound = false
        local noneDynamicIconMarked = false
        local oneDynamicDoesNotAllowToSell = false
        local isDynamic = FCOIS.mappingVars.iconIsDynamic
		for iconId, isMarked in pairs(markedIcons) do
            --Is a dynamic icon?
            local isDynIcon = isDynamic[iconId] or false
			if isMarked and isDynIcon then
                oneMarkedDynamicIconFound = true
                --All marked dyanmic icons must allow "sell" in order to let this item be marked as junk!
                --Check if dynamic icon's "sell" setting is allowed
                local iconData = settings.icon[iconId]
				if iconData.antiCheckAtPanel[LF_VENDOR_SELL] then
                    oneDynamicDoesNotAllowToSell = true
                end
            elseif isMarked and not isDynIcon then
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


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS filter API functions==========================
function FCOIS.IsIconEnabled(markerIconId)
    if markerIconId == nil or markerIconId <= 0 or markerIconId > numFilterIcons then return nil end
--d("[FCOIS.IsIconEnabled] markerIconId: " .. tostring(markerIconId))
    --If the settings were not loaded yet, do this now
    if not FCOIS.addonVars.gSettingsLoaded then
--d(">Loading user settings!")
        FCOIS.LoadUserSettings()
    end
    --Check if the icon is enabled
    local settings = FCOIS.settingsVars.settings
	local isIconEnabled = settings.isIconEnabled[markerIconId] or false
    return isIconEnabled
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS mark an item API functions =================================
--Global function to mark an item with an icon
--TODO: Add possibility to provide a table with multiple icons to mark!
function FCOIS.MarkItem(bag, slot, iconId, showIcon, updateInventories)
	--d("[FCOIS.MarkItem] bag " .. tostring(bag) .. ", slot: " .. tostring(slot) .. ", iconId: " .. tostring(iconId) .. ", show: " .. tostring(showIcon) .. ", updateInv: " .. tostring(updateInventories))
	if bag == nil or slot == nil then return false end
	if ((iconId > numFilterIcons) or (iconId < 1 and iconId ~= -1)) then return false end
	if showIcon == nil then showIcon = true end
    updateInventories = updateInventories or false

    local settings = FCOIS.settingsVars.settings
    local numVars = FCOIS.numVars

    local isCharShown = (bag == BAG_WORN and not FCOIS.ZOControlVars.CHARACTER:IsHidden())
    local recurRetValTotal = true
	--Recursively set/remove markers for all icons?
	if iconId == -1 then
		--Set preventing variable against endless loop
		FCOIS.preventerVars.markItemAntiEndlessLoop = true
		local doUpdateInvNow = false
		local recurRetVal = false
        local numFilterIcons = numVars.gFCONumFilterIcons
		for iconNr=1, numFilterIcons, 1 do
			if updateInventories and iconNr == numFilterIcons then
				doUpdateInvNow = true
			end
			--Recursively call this function again to change each marker icon at the item
			recurRetVal = FCOIS.MarkItem(bag, slot, iconNr, showIcon, doUpdateInvNow)
			if not recurRetVal then
				recurRetValTotal = false
			end
		end
		--Reset preventing variable against endless loop
		FCOIS.preventerVars.markItemAntiEndlessLoop = false
	end -- if iconId == -1 then

	--Only run this code if not all icons should be checked
	if iconId ~= -1 then
		--Allow the update of the marker here, and change it later if no update is needed
		local doUpdateMarkerNow = true
		--Get/use the (given) item instance id
		local itemId = FCOIS.MyGetItemInstanceIdNoControl(bag, slot)
		if itemId ~= nil then
			local researchableItem = false
			--Set the marker here now
			local itemIsMarked = showIcon
			if itemIsMarked == nil then itemIsMarked = false end
			--Item is already un/marked -> No need to change it
			if FCOIS.checkIfItemIsProtected(iconId, itemId) == itemIsMarked then
				doUpdateMarkerNow = false
			else
				--Check if the item is a researchable one, but only if icon should be shown and bag + slot are given
				-- Equipment gear 1, 2, 3, 4, 5, Research, Improve, Deconstruct or Intricate
                local mappingVars = FCOIS.mappingVars
				local iconIsResearchable = mappingVars.iconIsResearchable[iconId] or false
                if (showIcon and iconIsResearchable and (bag ~= nil and slot ~= nil)) then
					researchableItem = true
					-- Check if item is researchable (as only researchable items can work as equipment too)
					if (not FCOIS.isItemResearchableNoControl(bag, slot, iconId)) then
						doUpdateMarkerNow = false
						recurRetValTotal = false
					end
				end
			end

--d("[FCOIS]MarkItem - updateInventories: " .. tostring(updateInventories) .. ", doUpdateMarkerNow: " ..tostring(doUpdateMarkerNow) ..", iconId: " ..tostring(iconId) .. ", show: " ..tostring(showIcon))
			--Change the marker now?
			if doUpdateMarkerNow then
				--Unmark all other markers before? Only if marker should be set
				--Prevent endless loop here as FCOIS.MarkItem will call itsself recursively
				if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon and FCOIS.checkIfItemShouldBeDemarked(iconId) then
--d(">remove all markers now, isCharShown: " ..tostring(isCharShown) .. ", bag: " ..tostring(bag) .. ", charCtrlHidden: " .. tostring(FCOIS.ZOControlVars.CHARACTER:IsHidden()))
					--Remove all markers now
					FCOIS.MarkItem(bag, slot, -1, false, isCharShown)
					FCOIS.preventerVars.markItemAntiEndlessLoop = false

				--Any other circumstances
				else
--d(">1")
					--Prevent endless loop here as FCOIS.MarkItem will call itsself recursively
					-- Should the item be marked?
					if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon and (
					--  Icon is not sell or sell at guild store
					--  and is the setting to remove sell/sell at guild store enabled if any other marker icon is set?
						FCOIS.checkIfOtherDemarksSell(iconId)
					) then
--d(">2")
						--Get the icon to remove
						local iconsToRemove = {}
						iconsToRemove = FCOIS.getIconsToRemove(iconId)
                        --Is the item marked with any of the icons that should be removed?
                        if FCOIS.IsMarked(bag, slot, iconsToRemove) then
                            --For each icon that should be removed, do:
                            for key, iconToRemove in pairs(iconsToRemove) do
--d(">remove icon: " ..tostring(iconToRemove))
                                --Remove the sell/sell at guildstore/... marker icons now
                                --Is the character screen shown, then update the marker icons now?
                                FCOIS.MarkItem(bag, slot, iconToRemove, false, isCharShown)
                                FCOIS.preventerVars.markItemAntiEndlessLoop = false
                            end
                        end
                    else
--d(">>isCharShown: " ..tostring(isCharShown) .. ", antiEndlessLoop: " ..tostring(FCOIS.preventerVars.markItemAntiEndlessLoop) .. ", updateInventories: " ..tostring(updateInventories) .. ", doUpdateMarkerNow: " ..tostring(doUpdateMarkerNow))
                        --Is the character shown, and we are inside a loop to demark everyhting?
                        --Set the inventory to update now so the removed marker icons get updated properly at the character
                        if isCharShown and FCOIS.preventerVars.markItemAntiEndlessLoop and updateInventories == false then
                            updateInventories = true
                        end
                    end
				end
				
				--d(">>itemIsMarked: " .. tostring(itemIsMarked))

				--Shall we unmark the item? Then remove it from the SavedVars totally!
				if itemIsMarked == false then itemIsMarked = nil end
				--Un/Mark the item now
				FCOIS.markedItems[iconId][FCOIS.SignItemId(itemId)] = itemIsMarked
				--d(">> new markedItem value: " .. tostring(FCOIS.markedItems[iconId][FCOIS.SignItemId(itemId)]))
			end
		end --if itemId ~= nil

		--Update inventories or character equipment, but only needed if marker was changed
		if ( (updateInventories and doUpdateMarkerNow) or (FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem) ) then
--d("<<yUpdateInv: " ..tostring(updateInventories) .. ", doUpdateMarkerNow: " .. tostring(doUpdateMarkerNow) .. ", gOverrideInvUpdateAfterMarkItem: " ..tostring(FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem))
			FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = false

			if isCharShown then
				FCOIS.RefreshEquipmentControl(nil, showIcon, iconId)
			elseif bag == BAG_BACKPACK or bag == BAG_VIRTUAL
				or bag == BAG_BANK or bag == BAG_SUBSCRIBER_BANK or bag == BAG_GUILDBANK or IsHouseBankBag(bag) then
				FCOIS.FilterBasics(false)
			end
		end -- if updateInventories ...
	end -- if iconId ~= -1

	--Return value if icon was added/removed
	return recurRetValTotal
end -- FCOIS.MarkItem

--Function to mark an item via the itemInstaceId of an item or the uniqueId of an item.
--IMPORTANT: The itemInstanceId or uniqueId must be unsigned! They will get signed in this function.
--This function can be used to mark an item for a non-logged in character
function FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, iconId, showIcon, itemLink, itemId)
--d("[FCOIS.MarkItemByItemInstanceId] id " .. tostring(itemInstanceOrUniqueId) .. ", iconId: " .. tostring(iconId) .. ", show: " .. tostring(showIcon))
	if itemInstanceOrUniqueId == nil then return false end
	if ((iconId > numFilterIcons) or (iconId < 1 and iconId ~= -1)) then return false end
	if showIcon == nil then showIcon = true end

	local settings = FCOIS.settingsVars.settings
	local numVars = FCOIS.numVars

	--local isCharShown = not FCOIS.ZOControlVars.CHARACTER:IsHidden()
	local recurRetValTotal = true
	--Recursively set/remove markers for all icons?
	if iconId == -1 then
		--Set preventing variable against endless loop
		FCOIS.preventerVars.markItemAntiEndlessLoop = true
		local recurRetVal = false
		local numFilterIcons = numVars.gFCONumFilterIcons
		for iconNr=1, numFilterIcons, 1 do
			--Recursively call this function again to change each marker icon at the item
			recurRetVal = FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, iconNr, showIcon, itemLink, itemId)
			if not recurRetVal then
				recurRetValTotal = false
			end
		end
		--Reset preventing variable against endless loop
		FCOIS.preventerVars.markItemAntiEndlessLoop = false
	end -- if iconId == -1 then

	--Only run this code if not all icons should be checked
	if iconId ~= -1 then
		--Allow the update of the marker here, and change it later if no update is needed
		local doUpdateMarkerNow = true
		--Use the given itemLink or the given itemId to build a generic itemLink from it
        if itemId ~= nil and itemLink == nil then
            --Build a generic itemLink from the itemId to test the itemType
            itemLink = FCOIS.getItemLinkFromItemId(itemId)
        end
		if itemLink ~= nil then
--d(">"..itemLink)
			local researchableItem = false
			--Set the marker here now
			local itemIsMarked = showIcon
			if itemIsMarked == nil then itemIsMarked = false end
			--Item is already un/marked -> No need to change it
			if FCOIS.checkIfItemIsProtected(iconId, itemInstanceOrUniqueId) == itemIsMarked then
				doUpdateMarkerNow = false
			else
				--Check if the item is a researchable one, but only if icon should be shown and bag + slot are given
				-- Equipment gear 1, 2, 3, 4, 5, Research, Improve, Deconstruct or Intricate
				local mappingVars = FCOIS.mappingVars
				local iconIsResearchable = mappingVars.iconIsResearchable[iconId] or false
				if (showIcon and iconIsResearchable) then
					researchableItem = true
                    -- Check if item is researchable (as only researchable items can work as equipment too)
					if (not FCOIS.isItemLinkResearchable(itemLink, iconId)) then
						doUpdateMarkerNow = false
						recurRetValTotal = false
					end
				end
			end

--d("[FCOIS]MarkItemByItemInstanceId doUpdateMarkerNow: " ..tostring(doUpdateMarkerNow) ..", iconId: " ..tostring(iconId) .. ", show: " ..tostring(showIcon))
			--Change the marker now?
			if doUpdateMarkerNow then
				--Unmark all other markers before? Only if marker should be set
				--Prevent endless loop here as FCOIS.MarkItemByItemInstanceId will call itsself recursively
				if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon and FCOIS.checkIfItemShouldBeDemarked(iconId) then
					--d(">remove all markers now, isCharShown: " ..tostring(isCharShown) .. ", bag: " ..tostring(bag) .. ", charCtrlHidden: " .. tostring(FCOIS.ZOControlVars.CHARACTER:IsHidden()))
					--Remove all markers now
					FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, -1, false, itemLink, itemId)
					FCOIS.preventerVars.markItemAntiEndlessLoop = false

                --Any other circumstances
				else
					--d(">1")
					--Prevent endless loop here as FCOIS.MarkItemByItemInstanceId will call itsself recursively
					-- Should the item be marked?
					if not FCOIS.preventerVars.markItemAntiEndlessLoop and showIcon and (
					--  Icon is not sell or sell at guild store
					--  and is the setting to remove sell/sell at guild store enabled if any other marker icon is set?
					   FCOIS.checkIfOtherDemarksSell(iconId)
					) then
						--d(">2")
						--Get the icon to remove
						local iconsToRemove = {}
						iconsToRemove = FCOIS.getIconsToRemove(iconId)
						--Is the item marked with any of the icons that should be removed?
						if FCOIS.IsMarkedByItemInstanceId(itemInstanceOrUniqueId, iconsToRemove) then
							--For each icon that should be removed, do:
							for key, iconToRemove in pairs(iconsToRemove) do
								--d(">remove icon: " ..tostring(iconToRemove))
								--Remove the sell/sell at guildstore/... marker icons now
								--Is the character screen shown, then update the marker icons now?
								FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, iconToRemove, false, itemLink, itemId)
								FCOIS.preventerVars.markItemAntiEndlessLoop = false
							end
						end
					--else
						--d(">>isCharShown: " ..tostring(isCharShown) .. ", antiEndlessLoop: " ..tostring(FCOIS.preventerVars.markItemAntiEndlessLoop) .. ", updateInventories: " ..tostring(updateInventories) .. ", doUpdateMarkerNow: " ..tostring(doUpdateMarkerNow))
						--Is the character shown, and we are inside a loop to demark everyhting?
						--Set the inventory to update now so the removed marker icons get updated properly at the character
						--if isCharShown and FCOIS.preventerVars.markItemAntiEndlessLoop then
						--end
					end
				end

				--d(">>itemIsMarked: " .. tostring(itemIsMarked))

				--Shall we unmark the item? Then remove it from the SavedVars totally!
				if itemIsMarked == false then itemIsMarked = nil end
				--Un/Mark the item now
				FCOIS.markedItems[iconId][FCOIS.SignItemId(itemInstanceOrUniqueId)] = itemIsMarked
				--d(">> new markedItem value: " .. tostring(FCOIS.markedItems[iconId][FCOIS.SignItemId(itemId)]))
			end
		end --if itemId ~= nil

	end -- if iconId ~= -1

	--Return value if icon was added/removed
	return recurRetValTotal
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS is an item marked API functions =================================
--Function used to check if the items is marked with any marker icon and return a boolean value + array containing the marker icons which are set
-->Used in FCOIS.IsMarked and FCOIS.IsMarkedByItemInstanceId
local function checkIfItemIsMarkedAndReturnMarkerIcons(instance, iconIds, excludeIconIds)
	if instance == nil then return nil, nil end
	if (iconIds ~= -1 and excludeIconIds ~= nil) or excludeIconIds == -1 then return nil, nil end
	local markedArray = {}
	for i=1, numFilterIcons, 1 do
		markedArray[i] = false
	end
	local isMarked = false

	--is the parameter excludeIconIds an array/table?
	local excludeIconIdsIsTable = false
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
					for i=1, numFilterIcons, 1 do
						markedArray[i] = false
					end
					isMarked = false
				end
				--Check all iconIds now
				for icoId = 1, numFilterIcons, 1 do
					--Only if iconIds contains the value -1 or {-1} do the excluded icon checks too
					if not excludeIconIdsCheckTable[icoId] then
						--Is the not-excluded icon ID protected?
						if (FCOIS.checkIfItemIsProtected(icoId, instance) == true) then
							--return true, if any icon is set
							isMarked = true
							markedArray[icoId] = true
						end
					end
				end

				--Abort here as all icons were checked now and no further single iconId from parameter iconIds must be checked
				return isMarked, markedArray

				--Check only a specific iconId
			else
				--Is the iconId a number not equals -1?
				if type(iconId)=="number" then
					--Increase the icons checked so any entry with iconId == -1, after this entry here was checked, will
					--initialize the return array with false again!
					iconsChecked = iconsChecked + 1
					--is the item marked with that iconId?
					if (FCOIS.markedItems[iconId] ~= nil) then
						iconIsSet = FCOIS.checkIfItemIsProtected(iconId, instance)
						markedArray[iconId] = iconIsSet
						if not isMarked then
							isMarked = iconIsSet
						end
					end
				end
			end
		end
		return isMarked, markedArray

	else

		--iconIds is no array/table
		--Check only 1 icon
		if (iconIds ~= -1) then
			isMarked = FCOIS.markedItems[iconIds] ~= nil and FCOIS.checkIfItemIsProtected(iconIds, instance)
			if isMarked then
				markedArray[iconIds] = true
			end
			return isMarked, markedArray
		else
			--Check for all icons if the item is marked. return true, if any icon is set
			for icoId = 1, numFilterIcons, 1 do
				--Only if iconIds contains the value -1 or {-1} do the excluded icon checks too
				if not excludeIconIdsCheckTable[icoId] then
					--Is the not-excluded icon ID protected?
					if (FCOIS.checkIfItemIsProtected(icoId, instance) == true) then
						isMarked = true
						markedArray[icoId] = true
					end
				end
			end
			return isMarked, markedArray
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
function FCOIS.IsMarkedByItemInstanceId(itemInstanceId, iconIds, excludeIconIds)
	if (iconIds ~= -1 and excludeIconIds ~= nil) or excludeIconIds == -1 then return nil, nil end
	if itemInstanceId == nil then return nil, nil end
	--Build the itemInstanceId (signed) by help of the itemId
	local signedItemInstanceId = FCOIS.SignItemId(itemInstanceId, nil, true) -- only sign
	if signedItemInstanceId == nil then return nil, nil end
	local isMarked = false
	local markedIconsArray = {}
	isMarked, markedIconsArray = checkIfItemIsMarkedAndReturnMarkerIcons(signedItemInstanceId, iconIds, excludeIconIds)
	return isMarked, markedIconsArray
end -- FCOIS.IsMarkedByItemInstanceId

--Global function to return boolean value, if an item is marked
-- + it will return an array as 2nd return parameter, containing boolean entries, one for each iconId. True if item is marked with this iconId, false if not
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
	--At least one of the needed function parameters is missing. Return nil, nil
    if (bag == nil or slot == nil or iconIds == nil) then return nil, nil end
	local signedItemInstanceId = FCOIS.MyGetItemInstanceIdNoControl(bag, slot)
	if signedItemInstanceId == nil then return nil, nil end
	local isMarked = false
	local markedIconsArray = {}
	isMarked, markedIconsArray = checkIfItemIsMarkedAndReturnMarkerIcons(signedItemInstanceId, iconIds, excludeIconIds)
	return isMarked, markedIconsArray
end -- FCOIS.IsMarked

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
	if (bag ~= nil and slot ~= nil and filterId ~= nil) then
        local instance = FCOIS.MyGetItemInstanceIdNoControl(bag, slot)
		if instance == nil then return false end
        local offs  = 0
		--Workaround for empty filterPanelId
		if (filterPanelId == nil or filterPanelId == '') then
			--Fallback solution: FilterPanelId will be the inventory
			filterPanelId = LF_INVENTORY
		end

		local filterStatusVar = {}
		--Create 2-dimensional arrays for the filters
		for h_inv = 1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
			if FCOIS.mappingVars.activeFilterPanelIds[h_inv] == true then
				filterStatusVar[h_inv] = {false, false, false, false}
			end
		end

		--Check all filters, silently (chat output: disabled)
		filterStatusVar = FCOIS.filterStatus(-1, true, true)

		if (filterId ~= -1) then
			if (filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN) then
				if (FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, instance)  == true or
						FCOIS.checkIfItemIsProtected(nil, instance, "dynamic") == true) then
					--Split filtes, or old behaviour?
					if (FCOIS.settingsVars.settings.splitFilters == true) then
						--Is the deconstruction filter activated?
						if (filterStatusVar[filterPanelId][filterId] == true) then
							return true
						end
					else
						if (filterStatusVar[1][filterId] == true) then
							return true
						end
					end
				end
			elseif (filterId == FCOIS_CON_FILTER_BUTTON_GEARSETS) then
				if (FCOIS.checkIfItemIsProtected(nil, instance, "gear") == true) then
					--Split filtes, or old behaviour?
					if (FCOIS.settingsVars.settings.splitFilters == true) then
						--Is the deconstruction filter activated?
						if (filterStatusVar[filterPanelId][filterId] == true) then
							return true
						end
					else
						if (filterStatusVar[1][filterId] == true) then
							return true
						end
					end
				end
			elseif (filterId == FCOIS_CON_FILTER_BUTTON_RESDECIMP) then
				if (FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, instance) == true or
						FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, instance) == true or
						FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, instance) == true    ) then
					--Split filtes, or old behaviour?
					if (FCOIS.settingsVars.settings.splitFilters == true) then
						--Is the research filter activated?
						if (filterStatusVar[filterPanelId][filterId] == true) then
							return true
						end
					else
						if (filterStatusVar[1][filterId] == true) then
							return true
						end
					end
				end
			elseif (filterId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT) then
				if (FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL, instance) == true or
						FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, instance) == true or
						FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, instance) == true    ) then
					--Split filtes, or old behaviour?
					if (FCOIS.settingsVars.settings.splitFilters == true) then
						--Is the sell filter activated?
						--Attention: FilterId equals 4, but we need to check the value 5 here:
						if (filterStatusVar[filterPanelId][5] == true) then
							return true
						end
					else
						--Attention: FilterId equals 4, but we need to check the value 5 here:
						if (filterStatusVar[1][5] == true) then
							return true
						end
					end
				end
			else
				if (FCOIS.markedItems[filterId] ~= nil and FCOIS.checkIfItemIsProtected(filterId, instance)) then
					--Split filtes, or old behaviour?
					if (FCOIS.settingsVars.settings.splitFilters == true) then
						--Is the deconstruction filter activated?
						if (filterStatusVar[filterPanelId][filterId] == true) then
							return true
						end
					else
						if (filterStatusVar[1][filterId] == true) then
							return true
						end
					end
				end
			end
		else
			--Check for all filters if the item is marked. return true, if any filter applies
			for filtId = 1, FCOIS.numVars.gFCONumFilters, 1 do
				if (filtId == FCOIS_CON_FILTER_BUTTON_LOCKDYN) then
					if (FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, instance)  == true or
							FCOIS.checkIfItemIsProtected(nil, instance, "dynamic") == true) then
						--Split filtes, or old behaviour?
						if (FCOIS.settingsVars.settings.splitFilters == true) then
							--Is the deconstruction filter activated?
							if (filterStatusVar[filterPanelId][filtId] == true) then
								return true
							end
						else
							if (filterStatusVar[1][filtId] == true) then
								return true
							end
						end
					end
				elseif (filtId == FCOIS_CON_FILTER_BUTTON_GEARSETS) then
					if (FCOIS.checkIfItemIsProtected(nil, instance, "gear") == true) then
						--Split filtes, or old behaviour?
						if (FCOIS.settingsVars.settings.splitFilters == true) then
							--Is the deconstruction filter activated?
							if (filterStatusVar[filterPanelId][filtId] == true) then
								return true
							end
						else
							if (filterStatusVar[1][filtId] == true) then
								return true
							end
						end
					end
				elseif (filtId == FCOIS_CON_FILTER_BUTTON_RESDECIMP) then
					if (FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, instance) == true or
							FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, instance) == true or
							FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, instance) == true    ) then
						--Split filtes, or old behaviour?
						if (FCOIS.settingsVars.settings.splitFilters == true) then
							--Is the research filter activated?
							if (filterStatusVar[filterPanelId][filtId] == true) then
								return true
							end
						else
							if (filterStatusVar[1][filtId] == true) then
								return true
							end
						end
					end
				elseif (filtId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT) then
					if (FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL, instance) == true or
							FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, instance) == true or
							FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, instance) == true    ) then
						--Split filtes, or old behaviour?
						if (FCOIS.settingsVars.settings.splitFilters == true) then
							--Is the sell filter activated?
							--Attention: filtId equals 4, but we need to check the value 5 here:
							if (filterStatusVar[filterPanelId][5] == true) then
								return true
							end
						else
							--Attention: filtId equals 4, but we need to check the value 5 here:
							if (filterStatusVar[1][5] == true) then
								return true
							end
						end
					end
				else
					if (FCOIS.checkIfItemIsProtected(filtId, instance) == true) then
						--Split filtes, or old behaviour?
						if (FCOIS.settingsVars.settings.splitFilters == true) then
							--Is the deconstruction filter activated?
							if (filterStatusVar[filterPanelId][filtId] == true) then
								return true
							end
						else
							if (filterStatusVar[1][filtId] == true) then
								return true
							end
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
function FCOIS.ChangeFilter(filterId)
	--Valid filterId?
	if filterId == nil or filterId <= 0 or filterId > FCOIS.numVars.gFCONumFilters then return end
	--Valid filterPanelId?
	if FCOIS.gFilterWhere == nil or FCOIS.gFilterWhere <= 0
			or FCOIS.gFilterWhere > FCOIS.numVars.gFCONumFilterInventoryTypes then return end
	--Is filtering at the current panel enabled?
	if not FCOIS.settingsVars.settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"] then return end
	--is the filterPanelId visible?
	if FCOIS.mappingVars.gFilterPanelIdToInv[FCOIS.gFilterWhere]:IsHidden() then return end

	if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOChangeFilter] FilterId: " .. tostring(filterId) .. ", FilterPanelId: " .. tostring(FCOIS.gFilterWhere) .. ", InventoryName: " .. FCOIS.mappingVars.gFilterPanelIdToInv[FCOIS.gFilterWhere]:GetName(), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
	--Use the chat command handler now to emulate a filter change
	FCOIS.command_handler("filter" .. tostring(filterId) .. " " .. tostring(FCOIS.gFilterWhere))
end -- FCOChangeFilter


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS get icon information API functions==========================
--Global function to get the number of possible different gear sets and their icon IDs
--Returns the number of gear sets as 1st value, and an array for the mapping from gear to the icon ID as 2nd value
function FCOIS.GetGearSetInfo()
	if #FCOIS.mappingVars.gearToIcon <= 0 then return nil end
    return #FCOIS.mappingVars.gearToIcon, FCOIS.mappingVars.gearToIcon
end -- FCOGetGearSetInfo

--Global function to get the number of possible different dyanmic icons and their icon IDs
--Returns the number of dynamic icons as 1st value, and an array for the mapping from dynamic icon to the icon ID as 2nd value
function FCOIS.GetDynamicInfo()
	if #FCOIS.mappingVars.dynamicToIcon <= 0 then return nil end
    return #FCOIS.mappingVars.dynamicToIcon, FCOIS.mappingVars.dynamicToIcon
end -- FCOGetDynamicInfo

--Global function to get the for a given gear set's iconId (2, 4, 6, 7 or 8) or a dynamic icon id (13, 14, 15, 16, 17, 18, 19, 20, 21, 22)
--> use the constants for the amrker icons please! e.g. FCOIS_CON_ICON_LOCK, FCOIS_CON_ICON_DYNAMIC_1 etc. Check file src/FCOIS_constants.lua for the available constants (top of the file)
function FCOIS.GetIconText(iconId)
	--Load the user settings, if not done already
	FCOIS.LoadUserSettings()

	if iconId ~= nil and FCOIS.settingsVars.settings.icon ~= nil and
       FCOIS.settingsVars.settings.icon[iconId] ~= nil and FCOIS.settingsVars.settings.icon[iconId].name ~= nil and FCOIS.settingsVars.settings.icon[iconId].name ~= "" then
	   	return FCOIS.settingsVars.settings.icon[iconId].name
    end
end -- FCOGetIconText


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS localization API functions==========================
--Global function to get text for the keybindings etc.
function FCOIS.GetLocText(textName, isKeybindingText)
--d("[FCOIS.GetLocText] textName: " .. tostring(textName))
    isKeybindingText = isKeybindingText or false

    FCOIS.preventerVars.KeyBindingTexts = isKeybindingText

    --Do the localization now
    FCOIS.Localization()

    if textName == nil or FCOIS.localizationVars.fcois_loc == nil or FCOIS.localizationVars.fcois_loc[textName] == nil then return "" end
    return FCOIS.localizationVars.fcois_loc[textName]
end -- FCOGetLocText


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS keybind API functions ======================================
--Mark the icon with a chosen keybind
function FCOIS.MarkItemByKeybind(iconId)
    if iconId == nil then return false end
    --is the icon enabled? Otherwise abort here.
    if not FCOIS.settingsVars.settings.isIconEnabled[iconId] then return false end
    local bagId, slotIndex = FCOIS.GetBagAndSlotFromControlUnderMouse()
    --bag and slot could be retrieved?
    if bagId ~= nil and slotIndex ~= nil then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.MarkItemByKeybind] Bag: " .. bagId .. ", slot: " .. slotIndex, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

        --Check if the item is currently marked with this icon, or not
        --Get the itemId of the bag, slot combination
        local itemId = FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex)
        if itemId ~= nil then
			--Check if item is not researchable and research/gear/improve/deconstruct/intrictae icon is used, or if icon is a dynamic on and the research check is enabled
			-- Equipment gear (1, 2, 3, 4, 5), Research, Improve, Deconstruct, Intricate or dynamic icons
			--Check if the icon is allowed for research and if the research-enabled check is set in the settings
			if FCOIS.mappingVars.iconIsResearchable[iconId] or FCOIS.mappingVars.iconIsDynamic[iconId] then
				-- Check if item is researchable (as only researchable items can work as equipment too)
				if not FCOIS.isItemResearchableNoControl(bagId, slotIndex, iconId) then
					--Abort here if not researchable or not enabled to be marked even if not researchable in the dynamic icon settings
					return false
				end
			end
            --Set the marker here now
            --Item is already un/marked?
            local itemIsMarked = FCOIS.checkIfItemIsProtected(iconId, itemId)
            itemIsMarked = not itemIsMarked
            --Check if all markers should be removed prior to setting a new marker
            FCOIS.MarkItem(bagId, slotIndex, iconId, itemIsMarked, true)
            --If the item got marked: Check if the item is a junk item. Remove it from junk again then
            if itemIsMarked then
				FCOIS.IsItemProtectedAtASlotNow(bagId, slotIndex)
            end
        end
    else
        return false
    end
end -- FCOIS.MarkItemByKeybind

--Cycle through the item markers by help of a keybind
--> Currently only the standard icon is supported
function FCOIS.MarkItemCycle(direction)
	direction = direction or "next"
	if direction ~= "next" and direction ~= "prev" then return false end

	if FCOIS.settingsVars.settings.standardIconOnKeybind ~= nil and FCOIS.settingsVars.settings.standardIconOnKeybind > 0 and FCOIS.settingsVars.settings.standardIconOnKeybind <= numFilterIcons then
		--d("Mark item with standard markersymbol from settings: " .. FCOIS.settingsVars.settings.standardIconOnKeybind)
		local iconId = FCOIS.settingsVars.settings.standardIconOnKeybind
		if not FCOIS.settingsVars.settings.isIconEnabled[iconId] then
			--d(">> IconId was not enabled in the settings! Taking iconId 1")
			iconId = 1 --the lock symbol will be always enabled!
		end
		--Mark/Unmark the item now
		FCOIS.MarkItemByKeybind(iconId)
	end
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS marker icon API functions ==========================
function FCOIS.countMarkerIconsEnabled()
    local iconsEnabledCount = 0
    local dynIconsEnabledCount = 0
    local iconsEnabledSettings = FCOIS.settingsVars.settings.isIconEnabled
    local isDynamicIcon = FCOIS.mappingVars.iconIsDynamic

    for iconNr=1, numFilterIcons do
        if iconsEnabledSettings[iconNr] then
            if isDynamicIcon[iconNr] then
                dynIconsEnabledCount = dynIconsEnabledCount +1
            end
            iconsEnabledCount = iconsEnabledCount + 1
        end
    end
    return iconsEnabledCount, dynIconsEnabledCount
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
	FCOIS.LoadUserSettings(true)
	return FCOIS.settingsVars
end


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--=========== FCOIS LibAddonMenu 2.0 API functions ==========================
--Function to build a LAM dropdown choices and choicesValues table for the available FCOIS marker icons
--> Type can be one of the following one:
---> standard: A list with the marker icons, using the name from the settins, including the icon as texture (if "withIcons" = true) and disabled icons are marked red
---> standardNonDisabled: A list with the marker icons, using the name from the settins, including the icon as texture (if "withIcons" = true) and disabled icons are not marked in any other way then enabled ones
---> keybinds: A list with the marker icons, using the fixed name from the translations, including the icon as texture (if "withIcons" = true) and disabled icons are marked red
---> gearSets: A list with only the gear set marker icons, using the name from the settings, including the icon as texture (if "withIcons" = true) and disabled icons are marked red
function FCOIS.GetLAMMarkerIconsDropdown(type, withIcons)
	if type == nil then type = "standard" end
	withIcons = withIcons or false
	local FCOISlocVars            = FCOIS.localizationVars
	if FCOIS.settingsVars == nil or FCOIS.settingsVars.settings == nil or FCOIS.settingsVars.settings.isIconEnabled == nil then
		FCOIS.BuildAndGetSettingsFromExternal()
	end

	--Build icons choicesValues list
	local function buildIconsChoicesValuesList()
		local choicesValuesList = {}
		for i=1, numFilterIcons, 1 do
			choicesValuesList[i] = i
		end
		return choicesValuesList
	end

	--Build the icon lists for the options
	local function buildIconsChoicesList(type, withIcons)
		type = type or 'standard'
		withIcons = withIcons or false
		local settings = FCOIS.settingsVars.settings
		local iconsList = {}
		if type == 'standard' then
			for i=1, numFilterIcons, 1 do
				local locNameStr = FCOISlocVars.iconEndStrArray[i]
				local iconName = FCOIS.GetIconText(i) or FCOISlocVars.fcois_loc["options_icon" .. tostring(i) .. "_" .. locNameStr] or "Icon " .. tostring(i)
				local iconIsEnabled = settings.isIconEnabled[i]
				--Should the icon be shown at the start of the text too?
				if withIcons then
					local iconNameWithIcon = FCOIS.buildIconText(iconName, i, false, not iconIsEnabled)
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
		elseif type == 'standardNonDisabled' then
			for i=1, numFilterIcons, 1 do
				if settings.isIconEnabled[i] then
					local locNameStr = FCOISlocVars.iconEndStrArray[i]
					local iconName = FCOISlocVars.fcois_loc["options_icon" .. tostring(i) .. "_" .. locNameStr]
					--Should the icon be shown at the start of the text too?
					if withIcons then
						local iconNameWithIcon = FCOIS.buildIconText(iconName, i, false, true) -- no color as row is completely red
						iconName = iconNameWithIcon
					end
					iconsList[i] = iconName
				end
			end
		elseif type == 'keybinds' then
			--Check for each icon if it is enabled in the settings
			for i=1, numFilterIcons, 1 do
				local locNameStr = FCOISlocVars.iconEndStrArray[i]
				local iconName = FCOISlocVars.fcois_loc["options_icon" .. tostring(i) .. "_" .. locNameStr]
				local iconIsEnabled = settings.isIconEnabled[i]
				--Should the icon be shown at the start of the text too?
				if withIcons then
					local iconNameWithIcon = FCOIS.buildIconText(iconName, i, false, not iconIsEnabled)
					iconName = iconNameWithIcon
				end
				iconsList[i] = iconName
			end
		elseif type == 'gearSets' then
			local gearCounter = 1
			local isGearIcon = settings.iconIsGear
			for i=1, numFilterIcons, 1 do
				--Check if icon is a gear set icon and if it's enabled
				local iconIsEnabled = settings.isIconEnabled[i]
				if isGearIcon[i] and iconIsEnabled then
					local locNameStr = FCOISlocVars.iconEndStrArray[i]
					local iconName = FCOISlocVars.fcois_loc["options_icon" .. tostring(i) .. "_" .. locNameStr]
					--Should the icon be shown at the start of the text too?
					if withIcons then
						local iconNameWithIcon = FCOIS.buildIconText(iconName, i, false, not iconIsEnabled)
						iconName = iconNameWithIcon
					end
					iconsList[gearCounter] = iconName
					gearCounter = gearCounter + 1
				end
			end
		end
		return iconsList
	end
    return buildIconsChoicesList(type, withIcons), buildIconsChoicesValuesList()
end

--==========================================================================================================================================
-- 															FCOIS API - END
--==========================================================================================================================================