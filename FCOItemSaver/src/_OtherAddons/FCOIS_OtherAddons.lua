--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local debugMessage = FCOIS.debugMessage

local wm = WINDOW_MANAGER

local tos = tostring
local strformat = string.format
local strlen = string.len
local strsub = string.sub

local gil = GetItemLink 

local addonVars = FCOIS.addonVars
local mappingVars = FCOIS.mappingVars
local bagsToBuildIdFor = mappingVars.bagsToBuildItemInstanceOrUniqueIdFor

local checkVars = FCOIS.checkVars
--local allowedUniqueItemTypes = checkVars.uniqueIdItemTypes

local getSavedVarsMarkedItemsTableName       = FCOIS.GetSavedVarsMarkedItemsTableName
local getFCOISMarkerIconSavedVariablesItemId = FCOIS.GetFCOISMarkerIconSavedVariablesItemId
local signItemId                             = FCOIS.SignItemId
local myGetItemInstanceIdNoControl           = FCOIS.MyGetItemInstanceIdNoControl

local otherAddons = FCOIS.otherAddons

local checkIfOtherDemarksSell = FCOIS.CheckIfOtherDemarksSell
local checkIfOtherDemarksDeconstruction = FCOIS.CheckIfOtherDemarksSell

local filterBasics = FCOIS.FilterBasics
local refreshEquipmentControl = FCOIS.RefreshEquipmentControl
local checkIfItemShouldBeDemarked = FCOIS.CheckIfItemShouldBeDemarked
local isCharacterShown = FCOIS.IsCharacterShown
--local isCompanionCharacterShown = FCOIS.IsCompanionCharacterShown

local checkIfIsOwnerOfHouse = FCOIS.CheckIfIsOwnerOfHouse
local checkIfInHouse = FCOIS.CheckIfInHouse
local checkIfHouseBankBagAndInOwnHouse = FCOIS.CheckIfHouseBankBagAndInOwnHouse
local getCurrentlyLoggedInCharUniqueId = FCOIS.GetCurrentlyLoggedInCharUniqueId
local checkIfFCOISSettingsWereLoaded = FCOIS.CheckIfFCOISSettingsWereLoaded


--==========================================================================================================================================
--									FCOIS other addon functions
--==========================================================================================================================================

-- ==================================================================
--               AdvancedDisableControllerUI
-- ==================================================================
function FCOIS.CheckIfADCUIAndIsNotUsingGamepadMode()
    return (otherAddons and otherAddons.ADCUIActive
            and ADCUI ~= nil and ADCUI.savedVariables ~= nil and ADCUI.savedVariables.useControllerUI == false) or false
end

--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Dolgubon's Lazy Writ Creator
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Function to check if an item is crafted via the addon Dolgubon's Lazy Writ Creator
function FCOIS.CheckLazyWritCreatorCraftedItem()
    local writCreatedItem, craftingType, addonRequester
    if otherAddons.LazyWritCreatorActive and WritCreater ~= nil and FCOIS.settingsVars.settings.autoMarkCraftedWritItems and LibLazyCrafting ~= nil then
        writCreatedItem, craftingType, addonRequester = LibLazyCrafting:IsPerformingCraftProcess() --> returns boolean, type of crafting, addon that requested the craft
--d("[FCOIS]checkLazyWritCreatorCraftedItem - writCreatedItem: " .. tos(writCreatedItem) .. ", craftingType: " .. tos(craftingType) .. ", addonRequester: " .. tos(addonRequester))
        FCOIS.preventerVars.writCreatorCreatedItem = writCreatedItem and addonRequester == WritCreater.name
    end
    return writCreatedItem, craftingType, addonRequester
end

--Should the new created item be marked with a marker icon of the WritCreatorAddon
--Parameters: LLC_CRAFT_SUCCESS, station, {["bag"] = BAG_BACKPACK,["slot"] = currentCraftAttempt.slot,["reference"] = currentCraftAttempt.reference}
function FCOIS.CheckIfWritItemShouldBeMarked(craftSuccess, craftSkill, craftData)
    local isMasterWrit = FCOIS.preventerVars.createdMasterWrit or false
--d("[FCOIS]checkIfWritItemShouldBeMarked - craftSuccess: " .. tos(craftSuccess)  .. ", craftSkill: " .. tos(craftSkill) .. ", bag: " .. tos(craftData.bag) .. ", slotIndex: " .. tos(craftData.slot) .. ", reference: " .. tos(craftData.reference) .. ", isMasterWrit: " ..tos(isMasterWrit))
    --Check if the addon WritCreator is enabled and the settings are enabled to automatically mark writ items
    if not otherAddons.LazyWritCreatorActive or WritCreater == nil or not FCOIS.settingsVars.settings.autoMarkCraftedWritItems or craftSuccess ~= LLC_CRAFT_SUCCESS then return false end
    --Check the needed marker icon and if it's enabled in the settings
    local writCreatorMarkerIcons = {
        [true]  = FCOIS.settingsVars.settings.autoMarkCraftedWritCreatorMasterWritItemsIconNr,
        [false] = FCOIS.settingsVars.settings.autoMarkCraftedWritCreatorItemsIconNr,
    }
    local writMarkerIcon = writCreatorMarkerIcons[isMasterWrit]
    if not FCOIS.settingsVars.settings.isIconEnabled[writMarkerIcon] then return false end
    --Get the actual craftskill and overwrite the variable FCOIS.preventerVars.newItemCrafted with true
    --local craftSkill = GetCraftingInteractionType()
    if craftSkill ~= CRAFTING_TYPE_INVALID then
        local itemLink = gil(craftData.bag, craftData.slot)
--d(">writCreator: Item " .. itemLink .. " will be marked now with marker icon " .. tos(writMarkerIcon))
        FCOIS.MarkItem(craftData.bag, craftData.slot, writMarkerIcon, true, true)
    end
    FCOIS.preventerVars.createdMasterWrit = nil
end
local checkIfWritItemShouldBeMarked = FCOIS.CheckIfWritItemShouldBeMarked


-- ==================================================================
--               CraftBagExtended & AwesomeGuildstore
-- ==================================================================
--Function to check if CraftBagExtended or AwesomeGuildStore are active
function FCOIS.CheckIfCBEorAGSActive(parentFilterPanelId, checkWithoutParentFilterPanelId)
    checkWithoutParentFilterPanelId = checkWithoutParentFilterPanelId or false
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Other addons]","checkIfCBEorAGSActive - parentFilterPanelId: " .. tos(parentFilterPanelId) ..", checkWithoutParentFilterPanelId: " .. tos(checkWithoutParentFilterPanelId), true, FCOIS_DEBUG_DEPTH_SPAM) end
    local addonActive = false
    --Do the check only for the other addons enabled
    if checkWithoutParentFilterPanelId then
        --CraftBagExtended addon is active, or AwesomeGuildStore addon is active and we are at the CraftBag panel of AGS's guild store sell tab
        addonActive = otherAddons.craftBagExtendedActive or FCOIS.otherAddons.AGSActive
    else
        --Do the checks together for the other addons enabled AND the parent filter panel ID given from the craftbag's fragment callback function
        if parentFilterPanelId == nil then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[Other addons]","checkIfCBEorAGSActive <<< aborted", true, FCOIS_DEBUG_DEPTH_SPAM) end
            return false
        end
        --CraftBagExtended addon is active, or AwesomeGuildStore addon is active and we are at the CraftBag panel of AGS's guild store sell tab
        addonActive = otherAddons.craftBagExtendedActive or (otherAddons.AGSActive and parentFilterPanelId == LF_GUILDSTORE_SELL)
    end
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Other addons]", "checkIfCBEorAGSActive > addonActive: " .. tos(addonActive), true, FCOIS_DEBUG_DEPTH_SPAM) end
    return addonActive
end
local checkIfCBEorAGSActive = FCOIS.CheckIfCBEorAGSActive
--Fixing FCOIS_Constants.lua file here:
FCOIS.mappingVars.filterPanelIdToBlockSettingName[LF_CRAFTBAG].callbackFunc = checkIfCBEorAGSActive


-- ==================================================================
--                      SetTracker
-- ==================================================================
--Get the SetTracker data from it's SavedVariables and build the FCOIS mapping table data etc.
function otherAddons.SetTracker.GetSetTrackerSettingsAndBuildFCOISSetTrackerData()
    --Support for addon 'SetTracker': Get the number of allowed indices of SetTracker and
    --build a mapping array for SetTracker index -> FCOIS marker icon
    if otherAddons.SetTracker.isActive and SetTrack and SetTrack.GetMaxTrackStates then
        local settings = FCOIS.settingsVars.settings
        local STtrackingStates = SetTrack.GetMaxTrackStates()
        for i=0, (STtrackingStates-1), 1 do
            if settings.setTrackerIndexToFCOISIcon[i] == nil then
                FCOIS.settingsVars.settings.setTrackerIndexToFCOISIcon[i] = FCOIS_CON_ICON_NONE
            end
        end

        --BagId to SetTracker addon settings in FCOIS
        FCOIS.mappingVars.bagToSetTrackerSettings = {
            [BAG_WORN]		        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsWorn,
            --[BAG_COMPANION_WORN]    = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsWorn,
            [BAG_BACKPACK]	        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsInv,
            [BAG_BANK]		        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsBank,
            [BAG_SUBSCRIBER_BANK]   = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsBank,
            [BAG_GUILDBANK]	        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsGuildBank,
        }
    end
end

--Loop function to check the items in your inventories against a set name and mark them with FCOIS marker icon, if tracked with addon SetTracker
local function checkSetTrackerTrackingStateAndMarkWithFCOISIcon(sSetName, setTrackerState, iTrackIndex, doShow, p_bagId, p_slotIndex)
    local settings = FCOIS.settingsVars.settings
    if SetTrack == nil or SetTrack.GetTrackingInfo == nil or SetTrack.GetTrackStateInfo == nil or not otherAddons.SetTracker.isActive
            or settings.autoMarkSetTrackerSets == false
            or sSetName == nil or iTrackIndex == nil or doShow == nil then
        --d("[FCOIS]checkSetTrackerTrackingStateAndMarkWithFCOISIcon - Aborted")
        return false, nil
    end
    local retVar = true
    --Bags to check for items
    local bagsToCheck = {
        [BAG_BACKPACK]	= settings.autoMarkSetTrackerSetsInv,
        [BAG_WORN]		= settings.autoMarkSetTrackerSetsWorn,
        --[BAG_COMPANION_WORN] = settings.autoMarkSetTrackerSetsWorn,
        [BAG_BANK]		= settings.autoMarkSetTrackerSetsBank,
        [BAG_GUILDBANK]	= settings.autoMarkSetTrackerSetsGuildBank,
    }
    --Is the user an ESO+ subscriber?
    if IsESOPlusSubscriber() then
        --Add the subscriber bank to the inventories to check
        if GetBagUseableSize(BAG_SUBSCRIBER_BANK) > 0 then
            bagsToCheck[BAG_SUBSCRIBER_BANK] = settings.autoMarkSetTrackerSetsBank
        end
    end
    --Add the houes bank bags
    local houseBagIds = mappingVars.houseBankBagIdToBag
    for _, bagHouseBankNumber in ipairs(houseBagIds) do
        if IsHouseBankBag(bagHouseBankNumber) then
            bagsToCheck[bagHouseBankNumber] = settings.autoMarkSetTrackerSetsBank
        end
    end

    local removeAllSetTrackerMarkerIcons = false
    local setTrackerPossibleFCOISMarkerIcons = {}
    --Get the marker icon from FCOIS for the current trackIndex and create/show the marker icon now
    local FCOISMarkerIconForSetTracker = settings.setTrackerIndexToFCOISIcon[iTrackIndex]
    if FCOISMarkerIconForSetTracker == nil or FCOISMarkerIconForSetTracker == FCOIS_CON_ICON_ALL or FCOISMarkerIconForSetTracker > FCOIS.numVars.gFCONumFilterIcons then return false, nil end
    --No icon should be set via FCOIS (for SetTracker) so remove all curentlys et SetTracker marker icons
    if FCOISMarkerIconForSetTracker == FCOIS_CON_ICON_NONE then
        removeAllSetTrackerMarkerIcons = true
        --Get al SetTracker tracking states and the accordingly assigned FCOIS marker icons
        local STtrackingStates = SetTrack.GetMaxTrackStates()
        for i=0, (STtrackingStates-1), 1 do
            local FCOISMarkerIconForSetTrackerState = settings.setTrackerIndexToFCOISIcon[i]
            if FCOISMarkerIconForSetTrackerState ~= nil and FCOISMarkerIconForSetTrackerState ~= FCOIS_CON_ICON_NONE then
                setTrackerPossibleFCOISMarkerIcons[FCOISMarkerIconForSetTrackerState] = true
            end
        end
    end
    --Valid FCOIS icon was found, so go on and scan all items in the inventory & bank and mark the set with the marker icon

    --d("[FCOIS]checkSetTrackerTrackingStateAndMarkWithFCOISIcon - Icon: " .. tos(FCOISMarkerIconForSetTracker))

    local FCOIS_sv = FCOIS[getSavedVarsMarkedItemsTableName()]

    --Only check one item given by bagId and slotIndex? Or all icons in a bag?
    if p_bagId ~= nil and p_slotIndex ~= nil then
        --Check only one specific item
        --Get the FCOIS SetTracker settings for the given bagId
        local bagsToCheckOnlyOneBag = {
            [p_bagId]	= mappingVars.bagToSetTrackerSettings[p_bagId],
        }
        --No settings found? Abort here!
        if bagsToCheckOnlyOneBag[p_bagId] == nil then return false, nil end
        --Overwrite the bags to check with the given bag
        bagsToCheck = bagsToCheckOnlyOneBag
    end
    --for each bag to check: Check each slotIndex (or only the given one is p_slotIndex is not nil)
    for bagToCheck, isEnabled in pairs(bagsToCheck) do
        if isEnabled == true then
            --Initialize the loop return variable with "marked/unmarked successfully"
            local retVarBoolLoop = true

            --Only check one slotIndex?
            if p_slotIndex == nil then
                --============== CHECK ALL SLOTs in the CACHE (all items) ======================
                --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
                local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
                --Get the bag cache (all entries in that bag) or only one?
                for _, data in pairs(bagCache) do
                    local bag = data.bagId
                    local slot = data.slotIndex
                    if bag == nil or slot == nil then return false, nil end
                    local itemLinkLoop = gil(bag, slot)
                    if itemLinkLoop == nil then return false, nil end
                    local bIsSetItemLoop, sSetNameLoop = GetItemLinkSetInfo(itemLinkLoop, false)
                    --Is the scanned item a set and the name equals the given set part's name?
                    if bIsSetItemLoop and sSetNameLoop == sSetName then
                        local itemId = myGetItemInstanceIdNoControl(bag, slot, true)
                        if itemId == nil then return false, nil end

                        --Is the Set tracker state changed from old to new?
                        local FCOIS_OLD_MarkerIconForSetTracker
                        if setTrackerState ~= nil and doShow == true then
                            --Remove the old set tracker marker icon within FCOIS now
                            FCOIS_OLD_MarkerIconForSetTracker = settings.setTrackerIndexToFCOISIcon[setTrackerState]
                            if FCOIS_OLD_MarkerIconForSetTracker ~= nil and FCOIS_OLD_MarkerIconForSetTracker ~= FCOIS_CON_ICON_NONE and FCOIS_OLD_MarkerIconForSetTracker ~= FCOIS_CON_ICON_ALL then
                                --d(">Removing old marker icon first: " .. tos(FCOIS_OLD_MarkerIconForSetTracker))
                                FCOIS_sv[FCOIS_OLD_MarkerIconForSetTracker][itemId] = nil
                            end
                        end

                        --Remove all currently set SetTracker marker icons?
                        if removeAllSetTrackerMarkerIcons == true then
                            if FCOIS_OLD_MarkerIconForSetTracker ~= nil and setTrackerPossibleFCOISMarkerIcons[FCOIS_OLD_MarkerIconForSetTracker] == true then
                                setTrackerPossibleFCOISMarkerIcons[FCOIS_OLD_MarkerIconForSetTracker] = nil
                            end
                            local fcoisMarkerIconsToRemove = {}
                            for setTrackerPossibleMarkerIcon, isEnabledIcon in pairs(setTrackerPossibleFCOISMarkerIcons) do
                                if isEnabledIcon == true then
                                    table.insert(fcoisMarkerIconsToRemove, setTrackerPossibleMarkerIcon)
                                end
                            end
                            if fcoisMarkerIconsToRemove and #fcoisMarkerIconsToRemove > 0 then
                                for _, markerIcon in ipairs(fcoisMarkerIconsToRemove) do
                                    FCOIS_sv[markerIcon][itemId] = nil
                                end
                            end
                            retVarBoolLoop = true
                        else
                            --Check if item is already marked with this icon
                            local isAlreadyMarked = FCOIS_sv[FCOISMarkerIconForSetTracker][itemId] or false
                            --d(">isAlreadyMarked: " .. tos(isAlreadyMarked))
                            --Item is tracked (unequals -1) and is not a crafted set part (unequals 100)
                            if (iTrackIndex ~= -1 and iTrackIndex ~= 100) and doShow then
                                --Mark item now?
                                --Item is already marked
                                if isAlreadyMarked then
                                    retVarBoolLoop = true
                                else
                                    --d("Marked item at bag " .. tos(bag) .. ", slot: " .. tos(slot))
                                    --Mark the item now
                                    FCOIS_sv[FCOISMarkerIconForSetTracker][itemId] = true
                                    retVarBoolLoop = true
                                end
                                --Item is not tracked  anymore (equals -1)
                            elseif iTrackIndex == -1 or doShow == false then
                                --Not tracked set anymore (remove marker icon)
                                --Hide the marker on icon now?
                                --Item is not already marked
                                if not isAlreadyMarked then
                                    retVarBoolLoop = true
                                else
                                    --d("Unmarked item at bag " .. tos(bag) .. ", slot: " .. tos(slot))
                                    --Unmark the item now
                                    FCOIS_sv[FCOISMarkerIconForSetTracker][itemId] = nil
                                    retVarBoolLoop = true
                                end
                            end
                        end
                    end -- if bIsSetItemLoop ... -> is a set and the same name ...
                    if not retVarBoolLoop and retVar then
                        retVar = false
                    end
                end -- for ...

                --============== ONLY CHECK ONE SLOT (item) ====================================
            else --if p_slotIndex == nil then
                --d(">>> Checking only 1 bag ".. tos(p_bagId) .." and slot " .. tos(p_slotIndex))
                --Only check 1 slot in the bag p_bagId
                local bag = p_bagId
                local slot = p_slotIndex
                if bag == nil or slot == nil then return false, nil end
                local itemLinkLoop = gil(bag, slot)
                if itemLinkLoop == nil then return false, nil end
                local bIsSetItemLoop, sSetNameLoop = GetItemLinkSetInfo(itemLinkLoop, false)
                --Is the scanned item a set and the name equals the given set part's name?
                if bIsSetItemLoop and sSetNameLoop == sSetName then
                    local itemId = myGetItemInstanceIdNoControl(bag, slot, true)
                    if itemId == nil then return false, nil end

                    local removeAllSetTrackerFCOISMarkerIcons = false

                    --Is the Set tracker state changed from old to new?
                    if setTrackerState ~= nil and doShow then
                        --Remove the old set tracker marker icon within FCOIS now
                        local FCOIS_OLD_MarkerIconForSetTracker = settings.setTrackerIndexToFCOISIcon[setTrackerState]
                        if FCOIS_OLD_MarkerIconForSetTracker ~= nil and FCOIS_OLD_MarkerIconForSetTracker ~= FCOIS_CON_ICON_NONE and FCOIS_OLD_MarkerIconForSetTracker < FCOIS.numVars.gFCONumFilterIcons then
                            --d(">Removing old marker icon first: " .. tos(FCOIS_OLD_MarkerIconForSetTracker))
                            FCOIS_sv[FCOIS_OLD_MarkerIconForSetTracker][itemId] = nil
                        --Remove all marker icons?
                        elseif FCOIS_OLD_MarkerIconForSetTracker == FCOIS_CON_ICON_NONE then
                            removeAllSetTrackerFCOISMarkerIcons = true
                        end
                    end

                    --Remove all SetTracker related FCOIS marker icons on the item?
                    if removeAllSetTrackerFCOISMarkerIcons == true and setTrackerPossibleFCOISMarkerIcons ~= nil then
                        --Get al SetTracker tracking states and the accordingly assigned FCOIS marker icons
                        local fcoisMarkerIconsToRemove = {}
                        for setTrackerPossibleMarkerIcon, isEnabledIcon in pairs(setTrackerPossibleFCOISMarkerIcons) do
                            if isEnabledIcon == true then
                                table.insert(fcoisMarkerIconsToRemove, setTrackerPossibleMarkerIcon)
                            end
                        end
                        if fcoisMarkerIconsToRemove and #fcoisMarkerIconsToRemove > 0 then
                            for _, markerIcon in ipairs(fcoisMarkerIconsToRemove) do
                                FCOIS_sv[markerIcon][itemId] = nil
                            end
                        end
                        retVarBoolLoop = true
                    else
                        --Check if item is already marked with this icon
                        local isAlreadyMarked = FCOIS_sv[FCOISMarkerIconForSetTracker][itemId] or false
                        --d(">isAlreadyMarked: " .. tos(isAlreadyMarked))
                        --Item is tracked (unequals -1) and is not a crafted set part (unequals 100)
                        if (iTrackIndex ~= -1 and iTrackIndex ~= 100) and doShow then
                            --Mark item now?
                            --Item is already marked
                            if isAlreadyMarked then
                                retVarBoolLoop = true
                            else
                                --d("Marked item at bag " .. tos(bag) .. ", slot: " .. tos(slot))
                                --Mark the item now
                                FCOIS_sv[FCOISMarkerIconForSetTracker][itemId] = true
                                retVarBoolLoop = true
                            end
                            --Item is not tracked  anymore (equals -1)
                        elseif iTrackIndex == -1 or doShow == false then
                            --Not tracked set anymore (remove marker icon)
                            --Hide the marker on icon now?
                            --Item is not already marked
                            if not isAlreadyMarked then
                                retVarBoolLoop = true
                            else
                                --d("Unmarked item at bag " .. tos(bag) .. ", slot: " .. tos(slot))
                                --Unmark the item now
                                FCOIS_sv[FCOISMarkerIconForSetTracker][itemId] = nil
                                retVarBoolLoop = true
                            end
                        end
                    end
                end -- if bIsSetItemLoop ... -> is a set and the same name ...
                if not retVarBoolLoop and retVar then
                    retVar = false
                end
            end  --if p_slotIndex == nil then
            --=========== END IF .. ELSE ... ===============================================
        end -- isEnabled
    end -- for in pairs ...
    return retVar, FCOISMarkerIconForSetTracker
end

--function to scan inventories for set parts and mark them, if SetTracker addon is active
function otherAddons.SetTracker.checkAllItemsForSetTrackerTrackingState()
    --Is the SetTracker addon active and the marking of tracked items with FCOIS icons is active and the scan for tarcked items at reloadui/login is enabled?
    if SetTrack == nil or SetTrack.GetTrackingInfo == nil or not otherAddons.SetTracker.isActive
            or FCOIS.settingsVars.settings.autoMarkSetTrackerSets == false or FCOIS.settingsVars.settings.autoMarkSetTrackerSetsRescan == false then
        --d("[FCOIS]checkAllItemsForSetTrackerTrackingState - Aborted!")
        return false
    end
    --Was the SetTracker data mapping needed for FCOIS already loaded?
    otherAddons.SetTracker.GetSetTrackerSettingsAndBuildFCOISSetTrackerData()

    --Initialize the found set names table (against double checked set names)
    local foundSetnames = {}
    --Bags to check for set items
    local bagsToCheck = {
        [BAG_BACKPACK]	        = true,
        [BAG_WORN]		        = true,
        --[BAG_COMPANION_WORN]    = true,
        [BAG_BANK]		        = true,
    }
    --Is the user an ESO+ subscriber?
    if IsESOPlusSubscriber() then
        --Add the subscriber bank to the inventories to check
        if GetBagUseableSize(BAG_SUBSCRIBER_BANK) > 0 then
            bagsToCheck[BAG_SUBSCRIBER_BANK] = true
        end
    end
    --Add the houes bank bags
    local houseBagIds = mappingVars.houseBankBagIdToBag
    for _, bagHouseBankNumber in ipairs(houseBagIds) do
        if IsHouseBankBag(bagHouseBankNumber) then
            bagsToCheck[bagHouseBankNumber] = true
        end
    end

    --d("[FCOIS]checkAllItemsForSetTrackerTrackingState")
    for bagToCheck, isEnabled in pairs(bagsToCheck) do
        if isEnabled then
            --d(">Scanning bag " .. tos(bagToCheck))
            --Get the bag cache (all entries in that bag)
            --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
            local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
            for _, data in pairs(bagCache) do
                local bag = data.bagId
                local slot = data.slotIndex
                if bag == nil or slot == nil then return false end
                local itemLinkLoop = gil(bag, slot)
                if itemLinkLoop == nil then return false end
                --is the item a set part?
                local bIsSetItemLoop, sSetNameLoop = GetItemLinkSetInfo(itemLinkLoop, false)
                --Is the scanned item a set and the name equals the given set part's name?
                if bIsSetItemLoop and sSetNameLoop ~= nil and not foundSetnames[sSetNameLoop] then
                    --d(">New set name: " .. tos(sSetNameLoop))
                    --Add this set name to the found table so it isn't checked twice
                    foundSetnames[sSetNameLoop] = true

                    --Returns SetTracker data for the specified bag item as follows
                    --iTrackIndex - track state index 0 - 14, -1 means the set is not tracked and 100 means the set is crafted
                    --sTrackName - the user configured tracking name for the set
                    --sTrackColour - the user configured colour for the set ("RRGGBB")
                    --sTrackNotes - the user notes saved for the set
                    local iTrackIndex = SetTrack.GetTrackingInfo(bag, slot)
                    --Track index is not "not tracked" and not "a crafted set part"
                    if iTrackIndex ~= -1 and iTrackIndex ~= 100 then
                        --d(">TrackIndex found: " .. tos(iTrackIndex))
                        --Check all other items for this set part now and simualte:
                        -- that the last tracker state is unknown (nil)
                        -- that the item should be marked (true)
                        checkSetTrackerTrackingStateAndMarkWithFCOISIcon(sSetNameLoop, nil, iTrackIndex, true)
                    end
                end
            end -- for bagCache
        end
    end -- for bagToCheck
end

--Called from external addon SetTracker to show/hide the FCOIS marker icons for tracked set parts
-- or called from event EVENT_INVENTORY_SINGLE_SLOT_UPDATE callback function FCOItemSaver_Inv_Single_Slot_Update(...)
function otherAddons.SetTracker.updateSetTrackerMarker(bagId, slotIndex, setTrackerState, doShow, doUpdateInv, calledFromFCOISEventSingleSlotInvUpdate)
    calledFromFCOISEventSingleSlotInvUpdate = calledFromFCOISEventSingleSlotInvUpdate or false
    --d("[FCOIS.updateSetTrackerMarker] calledFromFCOISEventSingleSlotInvUpdate: " .. tos(calledFromFCOISEventSingleSlotInvUpdate))
    if bagId == nil or slotIndex == nil or SetTrack == nil or SetTrack.GetTrackingInfo == nil or SetTrack.GetTrackStateInfo == nil or not otherAddons.SetTracker.isActive
            or FCOIS.settingsVars.settings.autoMarkSetTrackerSets == false then return false end
    doShow = doShow or false
    doUpdateInv = doUpdateInv or false

    --d(">bag: " .. tos(bagId) .. ", slot: " .. tos(slotIndex) .. ", setTrackerState: " .. tos(setTrackerState) .. ", doShow: " .. tos(doShow) .. ", doUpdateInv: " .. tos(doUpdateInv))

    local retVarBool = true
    local FCOISMarkerIconForSetTrackerTrackIndex
    --Check if the item is a set part
    local itemLink = gil(bagId, slotIndex)
    if itemLink == nil then return false end
    local bIsSetItem, sSetName, _, _, _ = GetItemLinkSetInfo(itemLink, false)
    --Is the item a set item?
    if bIsSetItem and sSetName ~= nil and sSetName ~= "" then
        local iTrackIndex
        local sTrackName
        --Is the currentSetTrackerState given or is this a newly marked set, and isn't a set tracker state changed from old to new?
        if setTrackerState ~= nil and not doShow then
            iTrackIndex = setTrackerState
            local color = ""
            color, sTrackName = SetTrack.GetTrackStateInfo(iTrackIndex)
        else
            --Returns SetTracker data for the specified bag item as follows
            --iTrackIndex - track state index 0 - 14, -1 means the set is not tracked and 100 means the set is crafted
            --sTrackName - the user configured tracking name for the set
            --sTrackColour - the user configured colour for the set ("RRGGBB")
            --sTrackNotes - the user notes saved for the set
            iTrackIndex, sTrackName = SetTrack.GetTrackingInfo(bagId, slotIndex)
        end

        --Check all items now or only one specific new item in your bag?
        --> This function was called from EVENT_INVENTORY_SINGLE_SLOT_UPDATE callback function?
        --  Change the NIL values for bag and slot to the ones from this function's parameter!
        local p_bagId
        local p_slotIndex
        if calledFromFCOISEventSingleSlotInvUpdate then
            p_bagId		= bagId
            p_slotIndex	= slotIndex
        end
        --Check the SetTracker set trackings now and mark them with FCOIS marker icons
        retVarBool, FCOISMarkerIconForSetTrackerTrackIndex = checkSetTrackerTrackingStateAndMarkWithFCOISIcon(
                sSetName,
                setTrackerState,
                iTrackIndex,
                doShow,
                p_bagId, p_slotIndex
        )
        if retVarBool == nil then retVarBool = false end
    end -- if is set item ...
    --Update the inventories now to show the new/hidden marker icon?
    if retVarBool and doUpdateInv then
        --RefreshBackpack, etc.
        if (bagId == BAG_WORN and isCharacterShown())
          --or (bagId == BAG_COMPANION_WORN and isCompanionCharacterShown())
        then
            refreshEquipmentControl(nil, doShow, FCOISMarkerIconForSetTrackerTrackIndex)
        elseif bagId == BAG_BACKPACK or bagId == BAG_VIRTUAL
            or bagId == BAG_BANK or bagId == BAG_SUBSCRIBER_BANK
            or bagId == BAG_GUILDBANK or IsHouseBankBag(bagId) then
            filterBasics(false)
        end
    end
    return retVarBool
end
FCOIS.updateSetTrackerMarker = otherAddons.SetTracker.updateSetTrackerMarker


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Inventory Insight from Ashes (IIfA)
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--Inventory Insight From Ashes (IIFA) loaded now?
function FCOIS.CheckIfOtherAddonIIfAIsActive()
    if (IIfA ~= nil) then
        FCOIS.otherAddons.IIFAActive = true
    else
        FCOIS.otherAddons.IIFAActive = false
    end
end
local checkIfOtherAddonIIfAIsActive = FCOIS.CheckIfOtherAddonIIfAIsActive

--Get the itemInstance or the unique ID of an item at bagId and slotIndex, or at the itemLink
function FCOIS.GetItemInstanceOrUniqueId(bagId, slotIndex, itemLink, calledFromExternalAddon)
    if bagId == nil or slotIndex == nil then return 0, false end
    calledFromExternalAddon = calledFromExternalAddon or false
    local itemInstanceOrUniqueId = 0
    local isBagToBuildItemInstanceOrUniqueId = bagsToBuildIdFor[bagId] or false
    local allowedItemType
    --Should an itemInstance or unique ID be build for this bagId?
    if isBagToBuildItemInstanceOrUniqueId == true then
        itemLink = itemLink or gil(bagId,slotIndex)
        --d("[FCOIS.GetItemInstanceOrUniqueId] " .. itemLink .. ", bagId: " .. tos(bagId))
        --Are the FCOIS settings already loaded?
        checkIfFCOISSettingsWereLoaded(calledFromExternalAddon, not addonVars.gAddonLoaded)
        local settings = FCOIS.settingsVars.settings
        local useUniqueIds = settings.useUniqueIds or false
        local uniqueItemIdType = settings.uniqueItemIdType
    --[[
        local itemLinkItemType = GetItemLinkItemType(itemLink)
        local allowedUniqueIdItemType = allowedUniqueIdItemTypes[itemLinkItemType] or false
        --Is the FCOIS setting enabled to use unique IDs?
        if allowedUniqueIdItemType == true and useUniqueIds == true then
            if not uniqueItemIdType or uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then
                itemInstanceOrUniqueId = zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex))
            elseif uniqueItemIdType and uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE then
                --local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
                local itemInstanceId = GetItemId(bagId, slotIndex)
                itemInstanceOrUniqueId = FCOIS.CreateFCOISUniqueIdString(itemInstanceId, allowedUniqueIdItemType, bagId, slotIndex, itemLink)
                if settings.debug then debugMessage( "[getItemInstanceOrUniqueId]", strformat("bag: %s, slot: %s, itemLink: %s, itemInstanceId: %s, FCOISUniqueId: %s", tos(bagId), tos(slotIndex), tos(itemLink), tos(itemInstanceId), tos(itemInstanceOrUniqueId)), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            end
        else
            itemInstanceOrUniqueId = GetItemInstanceId(bagId, slotIndex)
        end
        ]]
        itemInstanceOrUniqueId, allowedItemType = getFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, nil, useUniqueIds, uniqueItemIdType)
        if settings.debug then debugMessage("[getItemInstanceOrUniqueId]", strformat("bag: %s, slot: %s, itemLink: %s, itemInstanceOrUniqueId: %s", tos(bagId), tos(slotIndex), tos(itemLink), tos(itemInstanceOrUniqueId)), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    end
    return itemInstanceOrUniqueId, isBagToBuildItemInstanceOrUniqueId
end
local getItemInstanceOrUniqueId = FCOIS.GetItemInstanceOrUniqueId

--compatibility function for other addons
function FCOIS.getItemInstanceOrUniqueId(bagId, slotIndex, itemLink)
    return getItemInstanceOrUniqueId(bagId, slotIndex, itemLink, true) --Change calledByExternalAddon always to true!
end

--Function to support Inventory Insight from Ashes addon. clickedDataLine is the right clicked row within the IIfA inventory frame.
--> Returns the itemInstance or uniqueId (signed or unsigned depending on parameter signToo),
--> bagId, slotIndex,
--> a table with the location names owning this item (BAG_BACKPACK or BAG_WORN -> non-account wide bags!)
---->This table contains the unique player id (as string)
----> of the player owning this item in his bag or worn. The value of the entry will be boolean true in order to simply check if
----> the currently logged in character is inside this table (for the marker icon update via bagId and slotIndex)
--> And a table with the location names owning this item (all other BAG_* bags -> account wide bags!).
---->This table contains the bag string (e.g. "Bank" or "CraftBag") as key and the bagId as value
function FCOIS.MyGetItemInstanceIdForIIfA(clickedDataLine, signToo)
    if IIfA == nil then return nil, nil, nil, nil, nil end
    --d("[FCOIS]MyGetItemInstanceIdForIIfA]")
    signToo = signToo or false
    --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids)
    local itemId
    local itemLink = clickedDataLine.link or clickedDataLine.itemLink
    if itemLink == nil or itemLink == "" then return nil, nil, nil, nil, nil end
    local settings = FCOIS.settingsVars.settings

    --Get the IIfA savedvars for the stored data
    local DBv3 = IIfA.database
    if DBv3 == nil then return nil, nil, nil, nil, nil end
    --Check if the item at the given itemLink can be virtual (materials -> craftbag) or
    --if the itemtype is something which is stored like the craftbag items ONLY with the itemId inside the IIfA savedvars!
    --> See function IIfA:GetItemKey(itemLink) in file IIfADataCollection.lua
    if IIfA.GetItemKey == nil or IIfA.DoesInventoryMatchList == nil then return nil, nil, nil, nil, nil end
    --Get the itemId (Craftbag and non researchable items) or itemLink (other items)
    local itemIdOrLink = IIfA:GetItemKey(itemLink)
    if itemIdOrLink == nil then return nil, nil, nil, nil, nil end

    --Now read the savedvars of the IIfA data with the key = itemIdOrLink
    -->ItemLink for normal items, and itemId for CraftBag items!

    --> If FCOIS accountwide marker icons are enabled: the current character is correct as the marker icons will apply to all characters,
    -->  and if not the current character is as well correct.
    --Now read the savedvars of IIfA data to get the bagId and slotIndex
    --[[
        The format in the IIfA savedvars (IIfA_Data) is:
        IIfA_Data =
        {
            ["Default"] =
            {
                ["@AccountName"] =
                {
                    ["$AccountWide"] =
                    {
                        ["Data"] =
                        {
                            ...
                            --Server location
                            ["EU"] =
                            {
                                -->IIfA.database from here
                                ["DBv3"] =
                                {
                                    --ItemLink key entry
                                    ["|H1:item:94857:363:50:0:0:0:0:0:0:0:0:0:0:0:1:67:0:1:0:10000:0|h|h"] =
                                    {
                                        ["locations"] =
                                        {
                                            --Guild Bank
                                            ["Finis Coronat Opus"] =
                                            {
                                                ["bagID"] = 3,
                                                ["bagSlot"] =
                                                {
                                                    [4806] = 1,
                                                },
                                            },
                                            --Bank
                                            ["Bank"] =
                                            {
                                                ["bagID"] = 6,
                                                ["bagSlot"] =
                                                {
                                                    [72] = 1,
                                                },
                                            },
                                            --UniquePlayerId
                                            ["8798292046226467"] =
                                            {
                                                ["bagID"] = 0,
                                                ["bagSlot"] =
                                                {
                                                    [3] = 1,
                                                    [...] = amount -- can be more than 1 entry in bagSlots if it's a guild bank (non-stacked items) or the inventory with non-stacked items!
                                                                   -- but the itemInstanceId build from the 1st entry in bagSlot should be the same in all, so (un)marking the 1st -> (un)marks all of them
                                                },
                                            },
                                        },
                                        ["itemName"] = "Grothdarrs Antlitz^Ng",
                                        ["itemQuality"] = 4,
                                        ["filterType"] = 2,
                                        ["itemInstanceOrUniqueId"] = 1234567890,
                                    },
                                    --itemId key entry (CraftBag or other materials etc.)
                                    ["4482"] =
                                    {
                                        ["locations"] =
                                        {
                                            ["CraftBag"] =
                                            {
                                                ["bagID"] = 5,
                                                ["bagSlot"] =
                                                {
                                                    --ItemId as well, not the craftbag slotIndex as this doesn't exist!
                                                    [4482] = 1,
                                                },
                                            },
                                        },
                                        ["itemName"] = "Kalziniumerz^ns",
                                        ["itemLink"] = "|H1:item:4482:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h",
                                        ["itemQuality"] = 1,
                                        ["filterType"] = 4,
                                    },

                               }, -- DBv3
                            }, -- EU
    ]]
    local bagId, slotIndex
    local ownedByLoggedInChar = false
    local isItemInAccountWideBags = false
    local itemFoundAtLocationTable = {}
    local itemFoundAtLocationTableAccountWide = {}
    --Open the entries below the itemId or itemLink
    if DBv3[itemIdOrLink] ~= nil then
        --Get the locations where this item is located and take the first one
        local DBv3ItemData = DBv3[itemIdOrLink]
        if DBv3ItemData.locations ~= nil then
            local DBv3Locations = DBv3ItemData.locations
            --Loop over the locations (character Ids, bank, etc.)
            for locationKey, locationData in pairs(DBv3Locations) do
                if locationKey ~= nil and locationData ~= nil then
                    --Does the location name and data fit to the selected inventory list filter (e.g. "All", or "Character 1" or "Guild banks", etc.)
                    if IIfA:DoesInventoryMatchList(locationKey, locationData) then
                        --Is the location data's bagID given
                        if locationData.bagID ~= nil then
                            --Is the bag the player inventory or player worn bag (as these can use the bagId and slotIndex to un/mark items directly)
                            if (locationData.bagID == BAG_BACKPACK or locationData.bagID == BAG_WORN) then
                                --Add the location found to the "where is this item located" table
                                itemFoundAtLocationTable[locationKey] = true
                            else
                                --Add the account wide bag entries to the other table with the key = string of bag, and value = bagId
                                --> These entries will be checked if bagId and slotIndex can be used or if the itemInstance or unique ID must be used
                                itemFoundAtLocationTableAccountWide[locationKey] = locationData.bagID
                            end
                        end
                    end
                end
            end

            --Check if the currently logged in user owns this item
            --Get the current char's unique ID and check if it's in the "worn by chars" table from the IIfA savedvars for this curently clicked item
            if FCOIS.loggedInCharUniqueId == nil or FCOIS.loggedInCharUniqueId == "" then
                FCOIS.loggedInCharUniqueId = tos(getCurrentlyLoggedInCharUniqueId())
            end
            ownedByLoggedInChar = itemFoundAtLocationTable[FCOIS.loggedInCharUniqueId] or false
            --Loop over the account wide item table and see if any entry exists
            isItemInAccountWideBags = false
            if itemFoundAtLocationTableAccountWide ~= nil then
                for _, _ in pairs(itemFoundAtLocationTableAccountWide) do
                    isItemInAccountWideBags = true
                    break -- exit the loop here
                end
            end
--d("[FCOIS]loggedInCharUniqueId: "..tos(FCOIS.loggedInCharUniqueId) .. ", ownedByLoggedInChar: " .. tos(ownedByLoggedInChar) .. ", isItemInAccountWideBags: " ..tos(isItemInAccountWideBags))

            --Item is owned by the currently logged in character? Then use bagId and slotIndex of that char
            if ownedByLoggedInChar then
                local currentLoggedInCharItemData = DBv3Locations[FCOIS.loggedInCharUniqueId]
                if currentLoggedInCharItemData ~= nil then
                    bagId = currentLoggedInCharItemData.bagID
                    if bagId ~= nil then
                        --Get the slotIndex table form that 1st location
                        if currentLoggedInCharItemData.bagSlot ~= nil then
                            local DBv3CurrentCharBagSlots = currentLoggedInCharItemData.bagSlot
                            --Get the first slotIndex from the table as each slotIndex will give the same itemId/data
                            for slotIndexNr, _ in pairs(DBv3CurrentCharBagSlots) do
                                slotIndex = slotIndexNr
                                break -- abort the loop after first found slotIndex
                            end
                        end
                    end
                end
                if bagId == nil or slotIndex == nil then return nil, nil, nil, nil, nil end

            --Item is not owned by the currently logged in char so use the itemInstanceOrUniqueId
            else
                local getItemInstaceOrUniqueId = false
                --Is this item in any account wide bag?
                if isItemInAccountWideBags then

                    -- Items in guild banks still got the bagId 3 in their IIfA savedvars, but the current guildbank could not reference the slotIndices anymore as the
                    -- current guild bank was changed. -->     Always use the itemInstance or uniqueId for the guild bank items.
                    local guildBankBagFound = false
                    --Or a house bank item and we are not in the house, or not the owner
                    local houseBankBagFoundAndNotInHouse = false

                    --Get the first account wide bagStr from the table of account wide bag entries
                    for accountWideBagStr, accountWideBagId in pairs(itemFoundAtLocationTableAccountWide) do
                        --Is the bagId a guild bank? Then do not check it and go on with the itemInstance or unique ID!
                        if accountWideBagId == BAG_GUILDBANK then
                            guildBankBagFound = true
                        elseif IsHouseBankBag(accountWideBagId) then
                            if not checkIfHouseBankBagAndInOwnHouse(accountWideBagId) then
                                houseBankBagFoundAndNotInHouse = true
                            end
                        else
                            --House bank bag and we are not in the house?
                            if accountWideBagStr ~= nil then
                                local accountWideBagItemData = DBv3Locations[accountWideBagStr]
                                if accountWideBagItemData ~= nil then
                                    --Get the slotIndex table form that 1st location
                                    if accountWideBagItemData.bagSlot ~= nil then
                                        local DBv3FirstAccountWideBagSlots = accountWideBagItemData.bagSlot
                                        --Get the first slotIndex from the table as each slotIndex will give the same itemId/data
                                        for slotIndexNr, _ in pairs(DBv3FirstAccountWideBagSlots) do
                                            slotIndex = slotIndexNr
                                            --Found a slotIndex? If not go on with next slotIndex (or bagSlot)
                                            if slotIndex ~= nil then
                                                --Set the bagId now
                                                bagId = accountWideBagId
                                                --Reset the guild bank bag/house bank bank found variable as another valid entry was found
                                                guildBankBagFound = false
                                                houseBankBagFoundAndNotInHouse = false
                                                break -- abort the loop after first found slotIndex
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    --Only a guild bank bag entry was found, so get the iteminstance or unqiue ID of it now
                    if guildBankBagFound or houseBankBagFoundAndNotInHouse then
                        getItemInstaceOrUniqueId = true
                    else
                        if bagId == nil or slotIndex == nil then return nil, nil, nil, nil, nil end
                    end
                else
                    getItemInstaceOrUniqueId = true
                end

                --No valid bagId and slotIndex found, so get the itemInstance or unique ID now
                if getItemInstaceOrUniqueId then
                    --Is the itemInstanceId or uniqueId given?
                    if DBv3ItemData ~= nil and DBv3ItemData.itemInstanceOrUniqueId ~= nil then
                        itemId = DBv3ItemData.itemInstanceOrUniqueId
                    end
                    if itemId == nil and (bagId == nil or slotIndex == nil) then return nil, nil, nil, nil, nil end
                end
            end

        end
    end
    local useUniqueIds = settings.useUniqueIds
    local uniqueItemIdType = settings.uniqueItemIdType
    local allowedItemType
    if settings.debug then debugMessage( "[MyGetItemInstanceIdForIIfA]","ownedByLoggedInChar: " .. tos(ownedByLoggedInChar) .. ", useUniqueIds: " .. tos(settings.useUniqueIds) .. ", allowedItemType: " .. tos(allowedItemType) .. ", bagId: " .. tos(bagId) .. ", slotIndex: " ..tos(slotIndex) .. ", itemId: " ..tos(itemId), true, FCOIS_DEBUG_DEPTH_ALL) end
    --Item owned by the currently logged in character,
    --or it's in the account wide bags and the itemId was not fetched yet (for guild bag items e.g.)
    --or the itemId is not fetched yet but bagId and slotIndex (to build it) are given, but bag is not worn or player inventory
    if ownedByLoggedInChar
        or (isItemInAccountWideBags and itemId == nil)
        or (itemId == nil and (bagId ~= nil and bagId ~= BAG_WORN and bagId ~= BAG_BACKPACK) and slotIndex ~= nil) then
        --Is the unique item ID enabled and the item's type is an allowed one(e.g. weapons, armor, ...)
        --Then use the unique item ID
        --Else use the non-unique item ID
        --d("[FCOIS.MyGetItemInstanceIdForIIfA] useUniqueIds: " .. tos(settings.useUniqueIds) .. ", allowedItemType: " .. tos(allowedItemType))
        --[[
        if settings.useUniqueIds and allowedItemType then
            local uniqueItemIdType = settings.uniqueItemIdType
            if not uniqueItemIdType or uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then
                itemId = zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex)) -- itemInstanceId contains the int64 value
            elseif uniqueItemIdType and uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE then
                --local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
                local itemIdOfItem = GetItemId(bagId, slotIndex)
                itemId = FCOIS.CreateFCOISUniqueIdString(itemIdOfItem, allowedItemType, bagId, slotIndex, itemLink)
                if settings.debug then debugMessage( "[MyGetItemInstanceIdForIIfA]", strformat("bag: %s, slot: %s, itemLink: %s, itemInstanceId: %s, FCOISUniqueId: %s", tos(bagId), tos(slotIndex), tos(itemLink), tos(itemInstanceId), tos(itemId)), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            end
        else
            itemId = GetItemInstanceId(bagId, slotIndex)
        end
        ]]
        itemId, allowedItemType = getFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, nil, useUniqueIds, uniqueItemIdType)
    end
    if signToo and (
            (not useUniqueIds or (useUniqueIds == true and allowedItemType == true))
            or (not ownedByLoggedInChar and not isItemInAccountWideBags)
    ) then
        itemId = signItemId(itemId, allowedItemType, nil, nil, bagId, slotIndex)
    end
--d("[FCOIS.MyGetItemInstanceIdForIIfA] itemIdOrLink: " .. itemIdOrLink .. ", itemInstanceOrUniqueId: " .. tos(itemId) .. ", bagId: " .. tos(bagId) .. ", slotIndex: " .. tos(slotIndex))
    return itemId, bagId, slotIndex, itemFoundAtLocationTable, itemFoundAtLocationTableAccountWide
end
local myGetItemInstanceIdForIIfA = FCOIS.MyGetItemInstanceIdForIIfA

--Is the addon InventoryInsight from Ashes active and is the current right-clicked row a row of this addon
--then return the itemInstanceId/uniqueItemId (depending on the FCOIS settings and the item's type) +
--bagId and slotIndex of the clicked item (from the IIfA savedvars) +
--a table with the player unique ids where this item is located
function FCOIS.CheckAndGetIIfAData(rowControl, parentControl)
    --Set the variable of IIfA active/or not
    checkIfOtherAddonIIfAIsActive()
    --Is IIfA active?
    if otherAddons.IIFAActive == true then
        --Get the itemLink from the dataLines
        local clickedDataLine
        if parentControl ~= nil and parentControl:GetName() == otherAddons.IIFAitemsListName then
            --Is the itemLink given in the right clicked row?
            local iifaItemLink
            if rowControl.itemLink ~= nil then
                iifaItemLink = rowControl.itemLink
            end
            --IIFA is active and we right-clicked a row there
            --Get the shown dataLines
            local dataLines = parentControl.dataLines
            --Get the current offset in the scroll list: Offset + clickedRowIndex = actual item entry in dataLines!
            local dataOffset = parentControl.dataOffset
            if dataLines ~= nil then
                --Get the currently right-clicked row number
                --The name is e.g. IIFA_ListItem_5, so the index is 5 (at the end)
                local clickedRowIndex
                if otherAddons.IIFAitemsListEntryPre ~= "" then
                    local clickedRowName = rowControl:GetName()
                    if clickedRowName ~= nil and clickedRowName ~= "" then
                        local startOfRowIndex = strlen(otherAddons.IIFAitemsListEntryPre) + 1
                        clickedRowIndex = tonumber(strsub(clickedRowName, startOfRowIndex))
                    end
                end
                --Is the clicked row found and is the row index valid?
                if clickedRowIndex ~= nil and clickedRowIndex > 0 and clickedRowIndex <= parentControl.maxLines then
                    --Build the actual clicked data entry's ID in the datalines
                    local dataLinesId = dataOffset + clickedRowIndex
                    if dataLines[dataLinesId] ~= nil then
                        clickedDataLine = dataLines[dataLinesId]
                        if iifaItemLink == nil or iifaItemLink == "" then
                            iifaItemLink = clickedDataLine.link
                        end
                    end
                end
            end
            --Found the itemlink of the clicked item?
            if clickedDataLine ~= nil and iifaItemLink ~= "" then
                --Get the itemInstanceId/uniqueItemId, bagId and slotIndex from the IIfA clicked dataLine
                local unsignedItemInstanceOrUniqueId, bagId, slotIndex, itemFoundAtLocationTable, itemFoundAtLocationTableAccountWide = myGetItemInstanceIdForIIfA(clickedDataLine, false) -- Do not sign as this will be done in other functions like FCOIS.MyGetItemDetails(bagId, slotIndex) or FCOIS.IsMarkedByItemInstanceId() later on!!!
                if unsignedItemInstanceOrUniqueId ~= nil or (bagId ~= nil and slotIndex ~= nil) then
            ---d("[FCOIS]<<<found: "  .. unsignedItemInstanceOrUniqueId, bagId, slotIndex)
                    return iifaItemLink, unsignedItemInstanceOrUniqueId, bagId, slotIndex, itemFoundAtLocationTable, itemFoundAtLocationTableAccountWide
                end
            end
        end
    end
    return nil, nil, nil, nil, nil, nil
end
local checkAndGetIIfAData = FCOIS.CheckAndGetIIfAData

--Check if any row within the IIfA addon was right clicked to show the context menu
-->Called within file FCOIS_ContextMenu.lua, function FCOIS.AddMark()
function FCOIS.CheckForIIfARightClickedRow(rowControl)
--d("[FCOIS.checkForIIfARightClickedRow] rowControl: " .. tos(rowControl:GetName()))
    --Check if an IIfA row was right clicked and if the needed data (itemInstace or uniqueId, bag and slot) are given for that row
    local itemLinkIIfA, itemInstanceOrUniqueIdIIfA, bagIdIIfA, slotIndexIIfA, ownedByCharsTableIIfA, itemIsInThisOtherBagsTableIIfA = checkAndGetIIfAData(rowControl, rowControl:GetParent())
    --Reset the IIfA clicked variables and set them again if correct values were determinded from IIfA savedvars
    FCOIS.IIfAclicked = nil
--d(">id: " ..tos(itemInstanceOrUniqueIdIIfA) .. ", bag: " .. tos(bagIdIIfA) .. ", slot: " .. tos(slotIndexIIfA))
    --Set the read IIfA saved variable data to the FCOIS global variable for the inventory right-clicked context menu row
    if itemInstanceOrUniqueIdIIfA ~= nil or (bagIdIIfA ~= nil and slotIndexIIfA ~= nil) then
        FCOIS.IIfAclicked = {}
        local IIfAclicked = FCOIS.IIfAclicked
        IIfAclicked.itemInstanceOrUniqueId = itemInstanceOrUniqueIdIIfA
        IIfAclicked.itemLink = itemLinkIIfA
        IIfAclicked.bagId = bagIdIIfA
        IIfAclicked.slotIndex = slotIndexIIfA
        IIfAclicked.ownedByChars = ownedByCharsTableIIfA
        IIfAclicked.inThisOtherBags = itemIsInThisOtherBagsTableIIfA
        --Not the owner of the house we are in or not in a house? Reset the bagid and slotIndex now!
        local isNotInHouseAndBagIsHouseBankBag = (bagIdIIfA ~= nil and IsHouseBankBag(bagIdIIfA) and (not checkIfInHouse() or not checkIfIsOwnerOfHouse()))
        --House bank bag but not in any house/not owner of the house we are in! -> Reset the bagId and slotIndex
        if isNotInHouseAndBagIsHouseBankBag then
            FCOIS.IIfAclicked.bagId = nil
            FCOIS.IIfAclicked.slotIndex = nil
        end
        return true
    end
    return false
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Recipe check addons: SousChef, CraftStoreFixedAndImproved
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Function to return the ID of the recipe addon used
function FCOIS.GetRecipeAddonUsed()
    local settings = FCOIS.settingsVars.settings
    local recipeAddonUsed = settings.recipeAddonUsed or 0
    if settings.debug then debugMessage("getRecipeAddonUsed",tos(recipeAddonUsed), true, FCOIS_DEBUG_DEPTH_SPAM, false) end
    return recipeAddonUsed
end
local getRecipeAddonUsed = FCOIS.GetRecipeAddonUsed

--Function to check which recipe addon handles the checks (enabled within the FCOIS settings)
function FCOIS.CheckIfRecipeAddonUsed()
    local retVar = false
    if (otherAddons.sousChefActive and (SousChef and SousChef.settings and SousChef.settings.showAltKnowledge))
    or (otherAddons.craftStoreFixedAndImprovedActive and CraftStoreFixedAndImprovedLongClassName ~= nil and CraftStoreFixedAndImprovedLongClassName.IsLearnable ~= nil) then
        retVar = true
    end
    if FCOIS.settingsVars.settings.debug then debugMessage("checkIfRecipeAddonUsed", tos(retVar), true, FCOIS_DEBUG_DEPTH_SPAM, false) end
    return retVar
end

--Function to check if the recipe addon is loaded
function FCOIS.CheckIfChosenRecipeAddonActive(recipeAddonId)
    if recipeAddonId == nil then recipeAddonId = getRecipeAddonUsed() end
    if recipeAddonId == 0 then return false end
    local retVar = false

    if recipeAddonId == FCOIS_RECIPE_ADDON_SOUSCHEF then
        retVar = (otherAddons.sousChefActive and SousChef.settings.showAltKnowledge) or false
    elseif recipeAddonId == FCOIS_RECIPE_ADDON_CSFAI then
        retVar = (otherAddons.craftStoreFixedAndImprovedActive and CraftStoreFixedAndImprovedLongClassName ~= nil and CraftStoreFixedAndImprovedLongClassName.IsLearnable ~= nil) or false
    end
    if FCOIS.settingsVars.settings.debug then debugMessage("checkIfChosenRecipeAddonActive","recipeAddonId: "..tos(recipeAddonId) .. ", retVar: " ..tos(retVar), true, FCOIS_DEBUG_DEPTH_SPAM, false) end
    return retVar
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Research check addons: ESO standard, CraftStoreFixedAndImproved, ResearchAssistant
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Function to return the ID of the research addon used
function FCOIS.GetResearchAddonUsed()
    local researchAddonUsed = FCOIS.settingsVars.settings.researchAddonUsed or 0
    return researchAddonUsed
end
local getResearchAddonUsed = FCOIS.GetResearchAddonUsed

--Function to check which research addon handles the checks (enabled within the FCOIS settings)
function FCOIS.CheckIfResearchAddonUsed()
    local retVar = false
    --Is the ESO standard setting chosen, then we do not need any additional addon enabled.
    local researchAddonId = getResearchAddonUsed()
    if researchAddonId == FCOIS_RESEARCH_ADDON_ESO_STANDARD then
        retVar = true
    else
        if (otherAddons.researchAssistantActive)
            or (otherAddons.craftStoreFixedAndImprovedActive and CraftStoreFixedAndImprovedLongClassName ~= nil and CraftStoreFixedAndImprovedLongClassName.IsResearchable ~= nil) then
            retVar = true
        end
    end
    return retVar
end

--Function to check if the research addon is loaded
function FCOIS.CheckIfChosenResearchAddonActive(researchAddonId)
    if researchAddonId == nil then researchAddonId = getResearchAddonUsed() end
    if researchAddonId == 0 then return false end
    local retVar = false

    if researchAddonId == FCOIS_RESEARCH_ADDON_ESO_STANDARD then
        retVar = true
    elseif researchAddonId == FCOIS_RESEARCH_ADDON_CSFAI then
        retVar = (otherAddons.craftStoreFixedAndImprovedActive and CraftStoreFixedAndImprovedLongClassName ~= nil and CraftStoreFixedAndImprovedLongClassName.IsResearchable ~= nil) or false
    elseif researchAddonId == FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT then
        retVar = otherAddons.researchAssistantActive or false
    end
    return retVar
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- ItemCooldownTracker
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--[[
    --==================================================================
    --ItemCooldownTracker API
    --==================================================================
    CDT.GetRelevantItemIds()
    returns a table containing all itemIds that are potential relevant for the prevention of opening (tracked itemIds of the addon)

]]
local function getItemCooldownTrackerRelevantItemIds()
    --#184
    if not ICDT then return end
    FCOIS.otherAddons.ItemCooldownTracker = FCOIS.otherAddons.ItemCooldownTracker or {}
    FCOIS.otherAddons.ItemCooldownTracker.relevantItemIds = {}
    local relevantItemIdsWithIndex = ICDT.GetRelevantItemIds()
    if relevantItemIdsWithIndex == nil or #relevantItemIdsWithIndex <= 0 then return end
    local relevantItemIds = {}
    for _, itemIdOfRelevance in ipairs(relevantItemIdsWithIndex) do
        relevantItemIds[itemIdOfRelevance] = true
    end
    --Todo DEBUG: For debugging add style page book "The bretons" too:  itemId 16425
    --relevantItemIds[16425] = true

    FCOIS.otherAddons.ItemCooldownTracker.relevantItemIds = relevantItemIds
end

function FCOIS.CheckIfItemCooldownTrackerRelevantItemIdAndMarkItem(bagId, slotIndex, itemLink)
    --#184
--d("[FCOIS]CheckIfItemCooldownTrackerRelevantItemIdAndMarkItem")
    if not ICDT then return false end
    local settings = FCOIS.settingsVars.settings
    local autoMarkItemCoolDownTrackerTrackedItems = settings.autoMarkItemCoolDownTrackerTrackedItems
    local itemCoolDownTrackerTrackedItemsMarkerIcon = settings.itemCoolDownTrackerTrackedItemsMarkerIcon
    if not autoMarkItemCoolDownTrackerTrackedItems
            or ( autoMarkItemCoolDownTrackerTrackedItems == true
                and (itemCoolDownTrackerTrackedItemsMarkerIcon == nil or itemCoolDownTrackerTrackedItemsMarkerIcon == FCOIS_CON_ICON_NONE))
    then return false end
    if not FCOIS.otherAddons.ItemCooldownTracker or not FCOIS.otherAddons.ItemCooldownTracker.relevantItemIds then
        getItemCooldownTrackerRelevantItemIds()
    end
    local relevantItemIds = FCOIS.otherAddons.ItemCooldownTracker.relevantItemIds
    if not relevantItemIds then return false end
    --[[
        ICDT.GetItemCooldown(itemId)
        for given itemId, returns
        -1                       --> item is not relevant (not trackable with addon)
        0                       --> item is tracked by current setting, but cooldown is expired
        number>0      --> cooldown is active, minutes left

        ICDT.FormatMinutes(minutesLeft)
        calculates the hours and minutes combination of given total minutes
        returns two values h, m
        Example: ICDT.FormatMinutes(131)   ->   2, 11
    ]]
    local itemId
    if itemLink ~= nil then
        itemId = GetItemLinkItemId(itemLink)
    else
        if bagId ~= nil and slotIndex ~= nil then
            itemId = GetItemId(bagId, slotIndex)
        end
    end
    if itemId == nil then return false end
    if not relevantItemIds[itemId] then return end

    local showIcon = false
    if itemLink == nil then
        itemLink = gil(bagId, slotIndex)
    end

    --Check the cooldown left
    local cooldownLeft = ICDT.GetItemCooldown(itemId)
    --[[
    --TODO For debugging
    if cooldownLeft == -1 and itemId == 16425 then
        cooldownLeft = 123
    end
    ]]
    --local cooldownLeftStr = ""
    if cooldownLeft == 0 then
        showIcon = false
        --cooldownLeftStr = "Cooldown left: None"
    elseif cooldownLeft > 0 then
        showIcon = true
        --local hoursLeft, minutesLeft = ICDT.FormatMinutes(cooldownLeft)
        --cooldownLeftStr = string.format("Cooldown left: %s hours, %s minutes", tos(hoursLeft), tos(minutesLeft))
    end

--d(">item: " .. itemLink .. ", showIcon: " ..tos(showIcon) .. ", icon: " ..tos(itemCoolDownTrackerTrackedItemsMarkerIcon))

    --Mark the item now
    if bagId == nil or slotIndex == nil then
        local fcoisItemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex, true)
        FCOIS.MarkItemByItemInstanceId(fcoisItemInstanceId, itemCoolDownTrackerTrackedItemsMarkerIcon, showIcon, itemLink, itemId, nil, true)
    else
        FCOIS.MarkItem(bagId, slotIndex, itemCoolDownTrackerTrackedItemsMarkerIcon, showIcon, true)
    end
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- AdvancedFilters (Updated)
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--Check if the itemCount addition to the inventory bagSpace is enabled in the AdvancedFilters settings
function FCOIS.CheckIfAdvancedFiltersItemCountIsEnabled()
    --Is the AddOnAdvancedFilters addon active and the function to refresh the shown item count below the inventory, at the "FreeSlot" label exists
    if AdvancedFilters ~= nil then
        local AF = AdvancedFilters
        local afUtil = AF.util
        if afUtil.updateInventoryInfoBarCountLabel ~= nil then
            --AdvancedFilters settings to hide the itemCount in the inventories is disabled?
            if AF.settings and AF.settings.hideItemCount == false then
                FCOIS.preventerVars.useAdvancedFiltersItemCountInInventories = true
                return true
            end
        end
    end
    return false
end


------------------------------------------------------------------------------------------------------------------------
--Check if another addon name is found and thus active
function FCOIS.CheckIfOtherAddonActive(addOnName)
    addOnName = addOnName or ""
    --Check if addon "Research Assistant" is active
    if(addOnName == "ResearchAssistant" or ResearchAssistant) then
        FCOIS.otherAddons.researchAssistantActive = true
    end
    --Check if addon "InventoryGridView" is active
    if(addOnName == "InventoryGridView" or InventoryGridView) then
        FCOIS.otherAddons.inventoryGridViewActive = true
    end
    --Check if addon "ChatMerchant" is active
    if(addOnName == "ChatMerchant") then
        FCOIS.otherAddons.chatMerchantActive = true
    end
    --Check if addon "PotionMaker" is active
    if(addOnName == "PotionMaker" or PotMaker) then
        FCOIS.otherAddons.potionMakerActive = true
    end
    --Check if addon "Votans Settings Menu" is active
    if(addOnName == "VotansSettingsMenu" or VOTANS_MENU_SETTINGS) then
        FCOIS.otherAddons.votansSettingsMenuActive = true
    end
    --Check if addon "SousChef" is active
    if(addOnName == "SousChef" or SousChef) then
        FCOIS.otherAddons.sousChefActive = true
    end
    --Check if addon "CraftStoreFixedAndImproved" is active
    if(addOnName == "CraftStoreFixedAndImproved" or CraftStoreFixedAndImprovedLongClassName) then
        FCOIS.otherAddons.craftStoreFixedAndImprovedActive = true
    end
    --Check if addon "CraftBagExtended" is active
    if(addOnName == "CraftBagExtended" or CraftBagExtended or CBE) then
        FCOIS.otherAddons.craftBagExtendedActive = true
    end
    --Check if addon "AwesomeGuildStore" is active
    if(addOnName == "AwesomeGuildStore" or AwesomeGuildStore) then
        FCOIS.otherAddons.AGSActive = true
    end
    --Check if addon "SetTracker" is active
    if(addOnName == "SetTracker" or SetTrack) then
        FCOIS.otherAddons.SetTracker.isActive = true
    end
    --Check if addon "AdvancedDisableControllerUI" is active
    if(addOnName == "AdvancedDisableControllerUI" or ADCUI) then
        FCOIS.otherAddons.ADCUIActive = true
    end
    --Check if addon "LazyWritCreator" is active
    if(addOnName == "DolgubonsLazyWritCreator" or WritCreater) then
        FCOIS.otherAddons.LazyWritCreatorActive = true
        --Overwrite the following functions to enabled automatic marking of writ created items!
        --WritCreater.masterWritCompletion = function(...) end -- Empty function, intended to be overwritten by other addons
        --WritCreater.writItemCompletion = function(...) end -- also empty
        if WritCreater.masterWritCompletion then
            WritCreater.masterWritCompletion = function(...)
                FCOIS.preventerVars.createdMasterWrit = true
                checkIfWritItemShouldBeMarked(...)
            end
        end
        if WritCreater.writItemCompletion then
            WritCreater.writItemCompletion = function(...)
                FCOIS.preventerVars.createdMasterWrit = false
                checkIfWritItemShouldBeMarked(...)
            end
        end
    end
    --Quality Sort
    if (addOnName == "QualitySort" or QualitySort) then
        FCOIS.otherAddons.qualitySortActive = true
    end
    --Inventory Insight From Ashes (IIFA)
    if (addOnName == "IIfA" or IIfA) then
        FCOIS.otherAddons.IIFAActive = true
        --Add entry to constants table for the keybinds/SHIFT+right mouse click inventory row patterns
        table.insert(checkVars.inventoryRowPatterns, "^" .. otherAddons.IIFAitemsListEntryPrePattern .. "*")         --Other addons: InventoryInsightFromAshes UI
    end
    --AdvancedFilters: Plugin FCO DuplicateItemsFilter
    if (addOnName == "AF_FCODuplicateItemsFilters" and AdvancedFilters) then
        FCOIS.otherAddons.AFFCODuplicateItemFilter = true
    end
end

--Check for other addons and react on them
function FCOIS.CheckIfOtherAddonsActiveAfterPlayerActivated()
    FCOIS.CheckIfOtherAddonActive()
    --Check if Inventory Gridview is active
    if (otherAddons.inventoryGridViewActive == false) then
        local gridViewControlName = GetControl(otherAddons.GRIDVIEWBUTTON) --wm:GetControlByName(otherAddons.GRIDVIEWBUTTON, "")
        if gridViewControlName ~= nil or InventoryGridView then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[Other addons]", "Addon Inventory Gridview is active", false) end
            FCOIS.otherAddons.inventoryGridViewActive = true
        end
    end
    --Check if Chat Merchant is active
    local chatMerchantControlName
    if (otherAddons.chatMerchantActive == false) then
        chatMerchantControlName = GetControl(otherAddons.CHATMERCHANTBUTTON) --wm:GetControlByName(otherAddons.CHATMERCHANTBUTTON, "")
        if chatMerchantControlName ~=  nil then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[Other addons]", "Addon ChatMerchant is active", false) end
            FCOIS.otherAddons.chatMerchantActive = true
        end
    end
    --Was ChatMerchant addon's control found now?
    if (otherAddons.chatMerchantActive == true) then
        if chatMerchantControlName ~=  nil then
            chatMerchantControlName:ClearAnchors()
            if (otherAddons.inventoryGridViewActive == true) then
                -- With Inventory Grid View activated
                chatMerchantControlName:SetAnchor(TOP, ZO_PlayerInventory, BOTTOM, -18, 6)
            else
                -- Without Inventory Grid View activated
                chatMerchantControlName:SetAnchor(TOP, ZO_PlayerInventory, BOTTOM, -10, 6)
            end
        end
    end
    --Inventory Insight From Ashes (IIFA) loaded now?
    checkIfOtherAddonIIfAIsActive()
end


-- ==================================================================
--  All external addons which have it's own inventory rows
-- ==================================================================
--Check if an update to the visible marker icons need to be done
function FCOIS.CheckIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate(rowControl, markId)
--d("[FCOIS]checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate-markId: " ..tos(markId))
    --Were all other marker icons removed as this marker icon got set?
    local demarksSell   = checkIfOtherDemarksSell(markId)
    local demarksDecon  = checkIfOtherDemarksDeconstruction(markId)
    if checkIfItemShouldBeDemarked(markId)
        --  Icon is not sell or sell at guild store
        --  and is the setting to remove sell/sell at guild store enabled if any other marker icon is set?
        or ( demarksSell == true or demarksDecon == true
    ) then
        --d(">item should be demarked")

        --Other addons "Inventory Insight" integration:
        --Update the complete row in the IIfA inventory frame
        if IIfA ~= nil and FCOIS.IIfAclicked ~= nil and IIfA.UpdateFCOISMarkerIcons ~= nil then
            local showFCOISMarkerIcons = IIfA:GetSettings().FCOISshowMarkerIcons
            IIfA:UpdateFCOISMarkerIcons(rowControl, showFCOISMarkerIcons, false, -1)
        end
    end
end