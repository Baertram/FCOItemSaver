--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons

--==========================================================================================================================================
--									FCOIS Inventory scanning & automatic item marking
--==========================================================================================================================================

--Function do check if an array of icons is marked and thus protected
local function checkIfItemArrayIsProtected(iconIdArray, itemId)
    if iconIdArray == nil or #iconIdArray == 0 or itemId == nil then return false end
    local isProtected = false
    --Check each iconId in the arry now for a protection
    for i=1, #iconIdArray, 1 do
        isProtected = FCOIS.checkIfItemIsProtected(iconIdArray[i], itemId)
        if isProtected then break end
    end
    return isProtected
end

--Function to check if an item is allowed to be marked automatically with an icon
local function checkIfCanBeAutomaticallyMarked(bagId, slotIndex, itemId, checkType)
--d("[FCOIS] checkIfCanBeAutomaticallyMarked - bag: " .. tostring(bagId) .. ", slotIndex: " .. tostring(slotIndex) .. ", itemId: " .. tostring(itemId) .. ", checkType: " .. tostring(checkType))
    if (bagId == nil or slotIndex == nil) and itemId == nil then return false end
    if itemId == nil then
        itemId = FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex)
    end
    --Set the return variable
    local retVar = true
    --Get all icons of the item
    local isMarkedWithOneIcon, markedIcons = FCOIS.IsMarked(bagId, slotIndex, -1)
    if isMarkedWithOneIcon and markedIcons then
        local settings = FCOIS.settingsVars.settings
        --Loop over all icons of the item
        for iconId, iconIsMarked in pairs(markedIcons) do
            --Is the current icon marked?
            if iconIsMarked then
                --Do not automatically mark items if they got the deconstruction icon on them?
                if iconId == FCOIS_CON_ICON_DECONSTRUCTION and settings.autoMarkPreventIfMarkedForDeconstruction then
                    --d(">> Deconstruction item is marked and no others are allowed!")
                    retVar = false
                    break -- end the loop
                --Do not automatically mark items if they got the sell icon on them?
                elseif iconId == FCOIS_CON_ICON_SELL and settings.autoMarkPreventIfMarkedForSell then
                    --d(">> Sell item is marked and no others are allowed!")
                    retVar = false
                    break -- end the loop
                --Do not automatically mark items if they got the sell in guild store icon on them?
                elseif iconId == FCOIS_CON_ICON_SELL_AT_GUILDSTORE and settings.autoMarkPreventIfMarkedForSellAtGuildStore then
                    --d(">> Sell item at guild store is marked and no others are allowed!")
                    retVar = false
                    break -- end the loop
                end
            end
        end
    end
    --d("<< checkIfCanBeAutomaticallyMarked: " .. tostring(retVar))
    return retVar
end

--Do the additional checks for researchabel items (other addons, etc.)
local function automaticMarkingResearchAdditionalCheckFunc(p_itemData, p_checkFuncResult)
    --zo_callLater(function()
    --d("[FCOIS]automaticMarkingResearchAdditionalCheckFunc() bagId: " .. tostring(p_itemData.bagId))
    local bag2Inv = FCOIS.mappingVars.bagToPlayerInv
    local inv = bag2Inv[p_itemData.bagId]
    if inv == nil then return false, nil end
    --The inventory slots got moved one hierarchy down, as the slots got a subarray now
    local inventorySlots = PLAYER_INVENTORY.inventories[inv].slots[p_itemData.bagId]
    local retVar = false
    local itemDataEntry = inventorySlots[p_itemData.slotIndex]
    if itemDataEntry ~= nil then
        local settings = FCOIS.settingsVars.settings
        local bagId, slotIndex = p_itemData.bagId, p_itemData.slotIndex
        local itemLinkResearch = GetItemLink(bagId, slotIndex)
        local isResearchable = false
        --Only if coming from EVENT_INVENTORY_SINGLE_SLOT_UPDATE for new looted items as otherwise the dateEntry.data.researchAssistant exists properly!
        --Added function to Research Assistant but addon update is not released yet?
        local comingFromEventInvSingleSlotUpdate = FCOIS.preventerVars.eventInventorySingleSlotUpdate
        --ResearchAssistant should be used?
        local researchAddonId = FCOIS.getResearchAddonUsed()
        if researchAddonId == FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT then
            if comingFromEventInvSingleSlotUpdate and ResearchAssistant ~= nil and
                (ResearchAssistant.IsItemResearchableOrDuplicateWithSettingsCharacter ~= nil or ResearchAssistant.IsItemResearchableWithSettingsCharacter ~= nil) then
                isResearchable = false
                if ResearchAssistant.IsItemResearchableOrDuplicateWithSettingsCharacter ~= nil then
                    isResearchable = ResearchAssistant.IsItemResearchableOrDuplicateWithSettingsCharacter(bagId, slotIndex)
                    --return value could be true, false or "duplicate"
                    if isResearchable ~= true then isResearchable = false end
                else
                    isResearchable = ResearchAssistant.IsItemResearchableWithSettingsCharacter(bagId, slotIndex)
                end
            else
                isResearchable = (itemDataEntry.researchAssistant ~= nil and itemDataEntry.researchAssistant == 'researchable')
            end

        --CraftStoreFixedAndImproved
        elseif researchAddonId == FCOIS_RESEARCH_ADDON_CSFAI then
            isResearchable = false
            if (FCOIS.otherAddons.craftStoreFixedAndImprovedActive and CraftStoreFixedAndImprovedLongClassName ~= nil and CraftStoreFixedAndImprovedLongClassName.IsResearchable ~= nil) then
                if itemLinkResearch ~= nil then
                    local currentlyLoggedInCharOnly = settings.autoMarkResearchOnlyLoggedInChar
                    --Return value of function is a table containing an integer key and a table as value. This table got an integer 1 as key and the charname asvalue, and an integer 2 as key and a boolean var isResearchable [true/false] as value:
                    --table[1] = {[1] = "Glacies", [2] = false}, [2] = {[1] = "Baertram", [2] = true}, etc.
                    --If currentlyLoggedInCharOnly is set to true it will only contain the entry for the currently logged in char
                    local isResearchableCharTable = CraftStoreFixedAndImprovedLongClassName.IsResearchable(itemLinkResearch, currentlyLoggedInCharOnly)
                    if isResearchableCharTable ~= nil and type(isResearchableCharTable) == "table" then
                        for _, isResearchableTableForChar in ipairs(isResearchableCharTable) do
                            if type(isResearchableTableForChar) == "table" then
                                local charName, isResearchableTableValue = isResearchableTableForChar[1], isResearchableTableForChar[2]
                                if isResearchableTableValue == true then
                                    if currentlyLoggedInCharOnly == true then
                                        if FCOIS.currentlyLoggedInCharName ~= nil and FCOIS.currentlyLoggedInCharName ~= "" and charName == FCOIS.currentlyLoggedInCharName then
                                            isResearchable = true
                                        end
                                    else
                                        isResearchable = true
                                    end
                                    if isResearchable then
                                        --d(">researchable " .. itemLinkResearch .. ", currentlyLoggedInCharOnly: " ..tostring(currentlyLoggedInCharOnly) .. ", charName: " ..tostring(charName))
                                        break -- Exit the inner loop now as a researchable item for a character was found
                                    end
                                end
                            end
                        end
                    end
                end
            end

        --ESO standard research
        elseif researchAddonId == FCOIS_RESEARCH_ADDON_ESO_STANDARD then
            --d(">ESO standard research check")
            --Check if the item is researchable for currently logged in character via standard ESO function
            if (GetItemTraitInformation(bagId, slotIndex) == ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED) then
                isResearchable = true
            end
        end
        --d("[FCOIS]automaticMarkingResearchAdditionalCheckFunc, isResearchable: " .. tostring(isResearchable))
        return isResearchable, nil
    else
        retVar = false
    end
    return retVar, nil
    --end, 100)
end

--Do all the checks for the "automatic mark item with quality"
local function automaticMarkingQualityCheckFunc(p_bagId, p_slotIndex)
    --Check if item's quality is a selected, or higher one?
    local qualityCheck = false
    local itemQuality = FCOIS.GetItemQuality(p_bagId, p_slotIndex)
    --local itemLink = GetItemLink(p_bagId, p_slotIndex)
    --d(itemLink .. ", quality: " .. tostring(itemQuality))
    if not itemQuality then return false, nil end
    local settings = FCOIS.settingsVars.settings
    local autoMarkQuality = settings.autoMarkQuality
    if settings.autoMarkHigherQuality and autoMarkQuality < ITEM_QUALITY_LEGENDARY then
        qualityCheck = itemQuality and itemQuality ~= false and itemQuality >= autoMarkQuality
    else
        qualityCheck = itemQuality and itemQuality ~= false and itemQuality == autoMarkQuality
    end
    --Is the item marked due to it's quality? Then check if the item is a weapon or armor part and exclude the check if the settings tell so
    if qualityCheck and settings.autoMarkHigherQualityExcludeArmor then
        --[[
                            GetItemArmorType(*integer* _bagId_, *integer* _slotIndex_)
                            ** _Returns:_ *[ArmorType|#ArmorType]* _armorType_
        ]]
        local itemArmorType = GetItemArmorType(p_bagId, p_slotIndex)
        --The item is an armor? Then don't mark it
        if itemArmorType ~= ARMORTYPE_NONE then
            return false, nil
        end
        --[[
                            * GetItemWeaponType(*integer* _bagId_, *integer* _slotIndex_)
                            ** _Returns:_ *[WeaponType|#WeaponType]* _weaponType_
        ]]
        local itemWeaponType = GetItemWeaponType(p_bagId, p_slotIndex)
        --The item is a weapon? Then don't mark it
        if itemWeaponType ~= WEAPONTYPE_NONE then
            return false, nil
        end
        --[[
                        * GetItemLinkInfo(*string* _itemLink_)
                        ** _Returns:_ *string* _icon_, *integer* _sellPrice_, *bool* _meetsUsageRequirement_, *integer* _equipType_, *integer* _itemStyle_
        ]]
        --Check if the item is a jewelry by using the item's equipType
        local itemLink = GetItemLink(p_bagId, p_slotIndex)
        if itemLink ~= nil and itemLink ~= "" then
            local _, _, _, equipType = GetItemLinkInfo(itemLink)
            if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
                return false, nil
            end
        end
    end
    return qualityCheck, nil
end

--[[
--Check if the automatic marker icon for "crafted" was set, as a new part was crafted
local function checkIfAutomaticCraftedMarkerIconIsSet()
    --Mark new crafted item with the "crafted" icon?
    --Are we creating an item, is the setting for automark enabled and is the current crafting station allowed?
    local creatingItem = not FCOIS.ZOControlVars.CRAFTING_CREATION_PANEL:IsHidden()
d("[FCOIS] checkIfAutomaticCraftedMarkerIconIsSet, creatingItem: " .. tostring(creatingItem))
    if creatingItem then
        local allowedCraftSkills = FCOIS.allowedCraftSkillsForCraftedMarking
        local craftSkill = GetCraftingInteractionType()
        local allowedCraftingSkill = allowedCraftSkills[craftSkill] or false
        if creatingItem and allowedCraftingSkill and FCOIS.settingsVars.settings.autoMarkCraftedItems and FCOIS.settingsVars.settings.isIconEnabled[FCOIS.settingsVars.settings.autoMarkCraftedItemsIconNr] then
            return true
        end
    end
    return false
end
]]

--Do all the checks for the "automatic mark item as set"
local function automaticMarkingSetsCheckFunc(p_bagId, p_slotIndex)
    --Was the item crafted and the automatic "crafted" marker icon was set already, then abort here and do not set the "set" marker icon
    --if checkIfAutomaticCraftedMarkerIconIsSet() then return false end
--d("[FCOIS] automaticMarkingSetsCheckFunc - > go on...")
    --First check if the item is a special item like the Maelstrom weapon or shield, or The Master's weapon
    local isSpecialItem = FCOIS.checkIfIsSpecialItem(p_bagId, p_slotIndex)
    --if the item is special it should be automatically marked as a set part, without any further checks!
    --The 2nd return parameter contains a variable called "noFurtherChecksNeeded" = true then!
    local retDataNoFurtherChecksNeeded = {}
    retDataNoFurtherChecksNeeded["noFurtherChecksNeeded"] = true
    if isSpecialItem then return true, retDataNoFurtherChecksNeeded end

    --Check if item is a set part with the wished trait
    local isSetPartWithWishedTrait, isSetPartAndIsValidAndGotTrait, setPartTraitMarkerIcon, isSet = FCOIS.isItemSetPartWithTraitNoControl(p_bagId, p_slotIndex)
--d("[FCOIS]automaticMarkingSetsCheckFunc " .. GetItemLink(p_bagId, p_slotIndex) .. ": isSet: " .. tostring(isSet) .. ", isSetPartWithWishedTrait: " .. tostring(isSetPartWithWishedTrait) .. ", isSetPartAndIsValidAndGotTrait: " .. tostring(isSetPartAndIsValidAndGotTrait) .. ", setPartTraitMarkerIcon: " .. tostring(setPartTraitMarkerIcon))
    --Build the data table which will be returned to the calling function, and then passed to the next additionalCheckFunc "automaticMarkingSetsAdditionalCheckFunc" function
    --in parameter table "p_itemData.fromCheckFunc"
    local retData = {}
    retData["isSetPartWithWishedTrait"]         = isSetPartWithWishedTrait
    retData["isSetPartAndIsValidAndGotTrait"]   = isSetPartAndIsValidAndGotTrait
    retData["newMarkerIcon"]                    = setPartTraitMarkerIcon
    retData["noFurtherChecksNeeded"]            = not isSet -- If this item is no set, no further checks are needed!
    --Is the item a set part with a wished trait
    return isSetPartWithWishedTrait, retData
end

--Do all the additional checks for the "automatic mark item as set"
local function automaticMarkingSetsAdditionalCheckFunc(p_itemData, p_checkFuncResult)
--d("[FCOIS.automaticMarkingSetsAdditionalCheckFunc]")
    --Should all marker icons be checked first? Then it was done BEFORE function "checkFunc" already by help of "toDos.checkIfAnyIconIsMarkedAlready"
    --Get the data from the checkfunc
    local isSetPartWithWishedTrait
    local isSetPartAndIsValidAndGotTrait
    local newMarkerIcon
    local itemLink
--FCOid = p_itemData
    if p_itemData ~= nil and p_itemData.bagId ~= nil and p_itemData.slotIndex ~= nil then
        itemLink = GetItemLink(p_itemData.bagId, p_itemData.slotIndex)
    end
    if p_itemData.fromCheckFunc ~= nil then
        --Check if no further checks are needed and the item needs to be marked with the set icon
        if p_itemData.fromCheckFunc["noFurtherChecksNeeded"] == true then
            --Return the values "nil" and "nil" -> Needed to abort all further marker icons and chat messages now!
            --Changed on 2018-08-04 from false, nil. But until this time the first checkFunc aborted the 2snd additional checkfunc,
            --which is now always called via parameter "additionalCheckFuncForce = true" and thus the chat was spammed with Marked potion as set part...
--d("<<aborting!")
            return nil, nil
        else
            isSetPartWithWishedTrait          =  p_itemData.fromCheckFunc["isSetPartWithWishedTrait"]
            isSetPartAndIsValidAndGotTrait    =  p_itemData.fromCheckFunc["isSetPartAndIsValidAndGotTrait"]
            newMarkerIcon                     =  p_itemData.fromCheckFunc["newMarkerIcon"]
--d(">>" .. itemLink .. ", isSetPartWithATrait: " .. tostring(isSetPartAndIsValidAndGotTrait) .. ", isSetPartWithAWishedTrait: " .. tostring(isSetPartWithWishedTrait) .. ", traitMarkerIcon: " .. tostring(newMarkerIcon))
        end
    end
    local skipAllOtherChecks = false
    local nonWishedBecauseOfCharacterLevel = false
    --Local settings
    local settings = FCOIS.settingsVars.settings
    --Do the other additonal set checks
    local itemId = p_itemData.itemId
    local isProtected = false
    local checkOtherSetMarkerIcons = false
    --Build the array with the gear set icon ids
    local iconIdArray = {}
    local gearIconIdArray = {}
    local sellIconIdArray = {}
    local setTrackerIconIdArray = {}
    --The standard automatic marker icon for the sets
    local setsIconNr = settings.autoMarkSetsIconNr

--=== Non-Wished set items check for characters below level 50 =========================================================
    if settings.autoMarkSetsNonWished and settings.isIconEnabled[settings.autoMarkSetsNonWishedIconNr] and settings.autoMarkSetsNonWishedIfCharBelowLevel then
        --Get the actual logged in character level
        local isCharLevelAboveOrEqual = FCOIS.checkNeededLevel("player", 50)
        if not isCharLevelAboveOrEqual then
--d("[FCOIS]automaticMarkingSetsAdditionalCheckFunc, charLevelIsBelow")
            --Check the item's level if it is below level 50
            local itemLevel = GetItemLinkRequiredLevel(itemLink)
            local itemRequiredCP = GetItemLinkRequiredChampionPoints(itemLink)
            local maxPossibleCPLevel = GetChampionPointsPlayerProgressionCap() --API 100028 = 160
            if itemLevel < 50 or (itemLevel > 50 and itemRequiredCP < maxPossibleCPLevel) then
                --Character is below level 50, so mark all set items as "Non-Wished" now
                skipAllOtherChecks = true --Skip all other set checks now (except setting the non-wished icon!)
                nonWishedBecauseOfCharacterLevel = true
            end
        end
    end

--==== SET TRACKER addon integration - START ===========================================================================
    if not skipAllOtherChecks then

        local isSetTrackerAndIsMarkedWithOtherIconAlready = false
        if SetTrack and SetTrack.GetMaxTrackStates and FCOIS.otherAddons.SetTracker.isActive then
            --d(">check SetTracker addon")
            --If the option is enabled to check for all marker icons before checking SetTracker set icons: If the set part is alreay marked with
            --any of the marker icons it shouldn't be marked with another SetTracker set marker icon again
            if settings.autoMarkSetTrackerSetsCheckAllIcons then
                for iconNr = 1, numFilterIcons, 1 do
                    table.insert(setTrackerIconIdArray, iconNr)
                end
                if setTrackerIconIdArray ~= nil and #setTrackerIconIdArray > 0 then
                    isSetTrackerAndIsMarkedWithOtherIconAlready = checkIfItemArrayIsProtected(setTrackerIconIdArray, itemId) or false
                end
            end
            --If the option is enabled to check for all SetTracker set icons: If the set part is alreay marked with
            --any of the SetTracker set icons it shouldn't be marked with another set marker icon again.
            --If the option is enabled that the SetTracker marker should not be set if any other marker is already set this will be skipped too!
            if not isSetTrackerAndIsMarkedWithOtherIconAlready and settings.autoMarkSetTrackerSets and settings.autoMarkSetsCheckAllSetTrackerIcons then
                --Set the variable to check other icons
                checkOtherSetMarkerIcons = true
                --Reset the variable for the SetTracker icon checks
                setTrackerIconIdArray = {}
                --Add the SetTracker sets tracking icons now
                local STtrackingStates = SetTrack.GetMaxTrackStates()
                if STtrackingStates ~= nil and STtrackingStates > 0 then
                    --For each SetTracker tracking state (set) get the appropriate marker icon from FCOIS
                    for i=0, (STtrackingStates-1), 1 do
                        local setTrackerTrackingIcon = settings.setTrackerIndexToFCOISIcon[i]
                        if setTrackerTrackingIcon ~= nil then
                            table.insert(setTrackerIconIdArray, setTrackerTrackingIcon)
                        end
                    end
                    if setTrackerIconIdArray ~= nil and #setTrackerIconIdArray > 0 then
                        isSetTrackerAndIsMarkedWithOtherIconAlready = checkIfItemArrayIsProtected(setTrackerIconIdArray, itemId) or false
                    end
                end
            end
        end
        --==== SET TRACKER addon integration - END =============================================================================

        --==== Normal set marker icon - BEGIN ==================================================================================
        --Check if the item is marked with the automatic set icon alreay
        --table.insert(iconIdArray, setsIconNr)
        local isMarkedWithAutomaticSetMarkerIcon = FCOIS.checkIfItemIsProtected(setsIconNr, itemId) or false
        --==== Normal set marker icon - END ====================================================================================

        --==== Gear marker icons - BEGIN =======================================================================================
        --If the option is enabled to check for all gear set icons: If the set part is alreay marked with
        --any of the gear set icons it shouldn't be marked with another set marker icon again
        local isGearProtected = false
        if settings.autoMarkSetsCheckAllGearIcons then
            --d(">check all gear icons")
            --Set the variable to check other icons
            checkOtherSetMarkerIcons = true
            --Add the gear set icons now
            local iconIsGear = settings.iconIsGear
            for i=1, numFilterIcons, 1 do
                --Check if icon is a gear set icon and if it's enabled
                if iconIsGear[i] then
                    table.insert(gearIconIdArray, i)
                end
            end
            if gearIconIdArray ~= nil and #gearIconIdArray > 0 then
                isGearProtected = checkIfItemArrayIsProtected(gearIconIdArray, itemId)
            end
            --d(">isGearProtected: " .. tostring(isGearProtected))
        end
        --==== Gear marker icons - END =========================================================================================

        --==== Sell marker icons - BEGIN =======================================================================================
        --If the option is enabled to check for sell and sell in guild store icons: If the set part is alreay marked with
        --any of them it shouldn't be marked with another set marker icon again
        local isSellProtected = false
        if settings.autoMarkSetsCheckSellIcons and (settings.isIconEnabled[FCOIS_CON_ICON_SELL] or settings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE]) then
            --d(">check sell icons")
            --Set the variable to check other icons
            checkOtherSetMarkerIcons = true
            if settings.isIconEnabled[FCOIS_CON_ICON_SELL] then
                table.insert(sellIconIdArray, FCOIS_CON_ICON_SELL)
            end
            if settings.isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] then
                table.insert(sellIconIdArray, FCOIS_CON_ICON_SELL_AT_GUILDSTORE)
            end
            if sellIconIdArray ~= nil and #sellIconIdArray > 0 then
                isSellProtected = checkIfItemArrayIsProtected(sellIconIdArray, itemId)
            end
            --d(">isSellProtected: " .. tostring(isSellProtected))
        end
        --==== Sell marker icons - END =========================================================================================

        --==== Is item protected check - BEGIN =================================================================================
        --Check other set marker icons too? Or only the normal one
        --d(">isSetTrackerAndIsMarkedWithOtherIconAlready: " ..tostring(isSetTrackerAndIsMarkedWithOtherIconAlready))
        local checkOnlySetMarkerIcon = false
        if checkOtherSetMarkerIcons then
            if iconIdArray ~= nil and #iconIdArray > 0 then
                --Check all the marker icons in the table iconIdArray
                isProtected = isSetTrackerAndIsMarkedWithOtherIconAlready or isGearProtected or isSellProtected or checkIfItemArrayIsProtected(iconIdArray, itemId)
            else
                checkOnlySetMarkerIcon = true
            end
        else
            checkOnlySetMarkerIcon = true
        end
        if checkOnlySetMarkerIcon then
            --Only check the automatic sets marker icon
            isProtected = isSetTrackerAndIsMarkedWithOtherIconAlready or isGearProtected or isSellProtected or isMarkedWithAutomaticSetMarkerIcon
        end
        if not isProtected then isProtected = false end
--==== Is item protected check - END ===================================================================================


    end --if not skipAllOtherChecks then
--==== Trait & non-wished trait checks - BEGIN =========================================================================
    --The item is not marked with any marker icon yet and it's not protected
    --> then check for non wished item traits
--d("> isProtected: " .. tostring(isProtected))
    local markWithNonWishedIcon = false
    local markWithNonWishedSellIcon = false
    if isProtected == false or nonWishedBecauseOfCharacterLevel == true then
        ------------------------------------------------------------------------------------------------------------------
        -- NON WISHED ITEM TRAIT CHECK - BEGIN
        -- Check if item is a set part with the wished trait and skip the "all marker icons check"!
        -- Is the item a set part, is valid and got non-wished traits, and should be marked with a non-wished marker icon?
        ------------------------------------------------------------------------------------------------------------------
        local nonWishedLevelFound = false
        local nonWishedQualityFound = false
        if (isSetPartWithWishedTrait == false or nonWishedBecauseOfCharacterLevel) and settings.autoMarkSetsNonWished and settings.isIconEnabled[settings.autoMarkSetsNonWishedIconNr] then
            --d(">non wished item trait check")
            if not nonWishedBecauseOfCharacterLevel then
                --Quality, level or botch checks?
                local doNonWishedQualityCheck   = (settings.autoMarkSetsNonWishedChecks==FCOIS_CON_NON_WISHED_ALL or settings.autoMarkSetsNonWishedChecks==FCOIS_CON_NON_WISHED_QUALITY) or false
                local doNonWishedLevelCheck     = (settings.autoMarkSetsNonWishedChecks==FCOIS_CON_NON_WISHED_ALL or settings.autoMarkSetsNonWishedChecks==FCOIS_CON_NON_WISHED_LEVEL) or false

                --If the item is a s set part "Check the item's level" is activated?
                if isSetPartAndIsValidAndGotTrait and doNonWishedLevelCheck and settings.autoMarkSetsNonWishedLevel ~= 1 then
                    local levelMapping = FCOIS.mappingVars.levels
                    local CPlevelMapping = FCOIS.mappingVars.CPlevels
                    local level2Threshold = FCOIS.mappingVars.levelToThreshold
                    local allLevels = FCOIS.mappingVars.allLevels
                    if levelMapping ~= nil and CPlevelMapping ~= nil and itemLink ~= nil and level2Threshold ~= nil and allLevels ~= nil then
                        local levelThreshold = tonumber(level2Threshold[tostring(allLevels[settings.autoMarkSetsNonWishedLevel])]) or 0
                        if levelThreshold ~= nil and levelThreshold > 0  then
                            --Get the item level and champion rank
                            local requiredLevel = GetItemLinkRequiredLevel(itemLink)
                            local requiredCPRank = GetItemLinkRequiredChampionPoints(itemLink)
                            --Is the item a ChampionRank item?
                            if requiredCPRank > 0 then
                                if requiredCPRank < levelThreshold then
                                    nonWishedLevelFound = true
                                end
                            else
                                --No CPs needed to wear this item
                                if requiredLevel < levelThreshold then
                                    nonWishedLevelFound = true
                                end
                            end
                        end
                    end
                    --Was a non wished level found? Then mark the item as non wished now
                    --if nonWishedLevelFound then
                    --Check if the item is a jewelry part and if the non-wished marker icon is the "deconstruction" icon
                    --replace it with the sell icon
                    --> Not needed nymore: FCOIS v1.3.6 as deconstruction of jewelry works too now since "Summerset" update
                    --if settings.autoMarkSetsNonWishedIconNr ~= FCOIS_CON_ICON_SELL then
                    --    local _, _, _, equipType = GetItemLinkInfo(itemLink)
                    --    if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
                    --        markWithNonWishedIcon = false
                    --        markWithNonWishedSellIcon = true
                    --    end
                    --end
                    --end
                end -- Non wished item level checks
                --Don't do quality checks etc. if the level checks were done already
                if isSetPartAndIsValidAndGotTrait and doNonWishedQualityCheck then
                    --Check the item's quality to mark it with the chosen non-wished icon, or the sell icon?
                    if settings.autoMarkSetsNonWishedQuality ~= 1 then
                        --d(">> non-wished quality check! Non-wished quality: " .. tostring(settings.autoMarkSetsNonWishedQuality))
                        --Check the item's quality now
                        local itemQuality = FCOIS.GetItemQuality(p_itemData.bagId, p_itemData.slotIndex)
                        if itemQuality ~= false then
                            nonWishedQualityFound = (itemQuality <= settings.autoMarkSetsNonWishedQuality) or false
                            --d("Quality: " .. tostring(itemQuality) .. ", check: " .. tostring(qualityCheck))
                            --Is the quality higher or equals the non-wished quality from the settings?
                            --if qualityCheck then
                            --else
                            --    --Mark with the sell icon
                            --    markWithNonWishedIcon = false
                            --    markWithNonWishedSellIcon = true
                            --end
                        end
                    end
                end
                --Was a level or quality or both combined found, matching to the non-wished settings?
                if (doNonWishedLevelCheck and doNonWishedQualityCheck and nonWishedLevelFound and nonWishedQualityFound)             -- Both
                        or (doNonWishedLevelCheck and not doNonWishedQualityCheck and nonWishedLevelFound and not nonWishedQualityFound)  -- Level
                        or (not doNonWishedLevelCheck and doNonWishedQualityCheck and not nonWishedLevelFound and nonWishedQualityFound) -- Quality
                then
                    markWithNonWishedIcon       = true
                    markWithNonWishedSellIcon   = false
                else
                    markWithNonWishedIcon       = false
                    markWithNonWishedSellIcon   = false
                    if settings.autoMarkSetsNonWishedSellOthers and settings.isIconEnabled[FCOIS_CON_ICON_SELL] then
                        --Don't do quality checks -> Mark with the non-wished icon
                        markWithNonWishedIcon       = false
                        markWithNonWishedSellIcon   = true
                    end
                end
            else
                --No other checks were needed and we need to mark the setItem with the non-wished marker icon now
                --as the character is below level 50 and the setting to mark then as non-wished is enabled
                markWithNonWishedIcon = true
            end --if not nonWishedBecauseOfCharacterLevel then
            --Mark with the non-wished icon now?
            if markWithNonWishedIcon or markWithNonWishedSellIcon then
                local nonWishedMarkerIcon
                if markWithNonWishedIcon then
                    nonWishedMarkerIcon = settings.autoMarkSetsNonWishedIconNr
                elseif markWithNonWishedSellIcon then
                    nonWishedMarkerIcon = FCOIS_CON_ICON_SELL
                end
                --Mark the item now
                FCOIS.MarkItem(p_itemData.bagId, p_itemData.slotIndex, nonWishedMarkerIcon, true, true)
                --Show the marked item in the chat with the clickable itemLink
                if settings.showSetsInChat then
                    if (itemLink ~= nil) then
                        local chatBegin = FCOIS.localizationVars.fcois_loc["marked"] or ""
                        local chatEnd 	= FCOIS.localizationVars.fcois_loc["set_part_non_wished_found"] or ""
                        d(chatBegin .. itemLink .. chatEnd)
                    end
                end
                --Return "true" so the function's expected result "false" is not met, and no marker icon gets set afterwards
                return true, nil
            end -- if markWithNonWishedIcon then
        end -- settings.autoMarkSetsNonWished
        ------------------------------------------------------------------------------------------------------------------
        -- NON WISHED ITEM TRAIT CHECK - END
        ------------------------------------------------------------------------------------------------------------------
    end
    --Skip all other checks?
    if not skipAllOtherChecks then

        ------------------------------------------------------------------------------------------------------------------
        -- WISHED ITEM TRAIT CHECK - BEGIN
        ------------------------------------------------------------------------------------------------------------------
        --Item is not non-wished trait and it is already marked with the set icon, or not marked with the set item:
        --Check if the trait icon needs to be applied.
        -->Depending on the settings for trais, like "Check all marker icons", "Check gear marker icons", "Check sell icons", "Check SetTracker icons"!
        local markWithTraitIcon = false
        if isSetPartWithWishedTrait and not markWithNonWishedIcon and not markWithNonWishedSellIcon
                and (not isMarkedWithAutomaticSetMarkerIcon or (isMarkedWithAutomaticSetMarkerIcon and settings.autoMarkSetsWithTraitIfAutoSetMarked)) then
            --d(">>>Trait marking checks start")
            --Check if any other marker icon can be set
            if settings.autoMarkSetsWithTraitCheckAllIcons and not isMarkedWithAutomaticSetMarkerIcon then
                local isMarkedWithAnyOtherIcon = false
                local allMarkerIconsArray = {}
                for iconNr = 1, numFilterIcons, 1 do
                    if iconNr ~= setsIconNr then
                        table.insert(allMarkerIconsArray, iconNr)
                    end
                end
                if allMarkerIconsArray ~= nil and #allMarkerIconsArray > 0 then
                    isMarkedWithAnyOtherIcon = checkIfItemArrayIsProtected(allMarkerIconsArray, itemId) or false
                end
                if not isMarkedWithAnyOtherIcon then
                    markWithTraitIcon = true
                end
            else
                --Check if any gear marker icon can be set
                if settings.autoMarkSetsWithTraitCheckAllGearIcons and not isGearProtected then
                    markWithTraitIcon = true
                    --Check if any SetTracker marker icon can be set
                elseif settings.autoMarkSetsWithTraitCheckAllSetTrackerIcons and not isSetTrackerAndIsMarkedWithOtherIconAlready then
                    markWithTraitIcon = true
                    --Check if any sell marker icon can be set
                elseif settings.autoMarkSetsWithTraitCheckSellIcons and not isSellProtected then
                    markWithTraitIcon = true
                    --None of the above settings is enabled: Just mark the item with teh trait icon
                else
                    markWithTraitIcon = true
                end
            end
        end
        --d(">>>markWithTraitIcon: " .. tostring(markWithTraitIcon))
        --if newMarkerIcon == nil then
        --    d(">markWithTraitIcon " .. tostring(markWithTraitIcon) .. ": markWithNonWishedIcon " .. tostring(markWithNonWishedIcon) .. ", markWithNonWishedSellIcon " .. tostring(markWithNonWishedSellIcon) ..
        --        ", isMarkedWithAutomaticSetMarkerIcon " .. tostring(isMarkedWithAutomaticSetMarkerIcon) .. ", settings.autoMarkSetsWithTraitIfAutoSetMarked " .. tostring(settings.autoMarkSetsWithTraitIfAutoSetMarked))
        --    if itemLink ~= nil then
        --        d(">Itemlink: " ..tostring(itemLink))
        --    else
        --        d(">Itemlink is missing!")
        --    end
        --end
        if markWithTraitIcon then
            --Mark the item with the trait marker icon now
            FCOIS.MarkItem(p_itemData.bagId, p_itemData.slotIndex, newMarkerIcon, true, true)
        end
        ------------------------------------------------------------------------------------------------------------------
        -- WISHED ITEM TRAIT CHECK - END
        ------------------------------------------------------------------------------------------------------------------
        --==== Trait & non-wished trait checks - END ===========================================================================

        --Set marker icon was set already, or only the trait should be marked and was marked successfully? Then abort here now
        --so the set icon won't be set later on in the calling function's "to do" entry
        if (markWithTraitIcon and settings.autoMarkSetsOnlyTraits) or isMarkedWithAutomaticSetMarkerIcon then return nil, nil end
        --Change the marker icon in the 1st checkFunc resultdata from the trait icon (if valid set part and trait was found)
        --to the normal "Set" marker icon now
        p_itemData.fromCheckFunc["newMarkerIcon"] = setsIconNr

        --Return true: No set marker icon will be set. Return false: Set marker icon will be set via calling function's "to do" entry
        return isProtected, nil
    end --if not skipAllOtherChecks then
    --Return true: No set marker icon will be set.
    return true, nil
end -- automaticMarkingSetsAdditionalCheckFunc

--Function to scan a single item. Is needed so the return false won't abort scanning the whole inventory!
function FCOIS.scanInventoryItemForAutomaticMarks(bag, slot, scanType, toDos, doOverride)
    doOverride = doOverride or false
    --d("FCOIS]scanInventoryItemForAutomaticMarks-" .. il .. " bag: " ..tostring(bag) .. ", slot: " ..tostring(slot) .. ", scanType: " .. tostring(scanType) .. ", doOverride: " .. tostring(doOverride))
    --------------------------------------------------------------------------------
    --					Function starts											  --
    --------------------------------------------------------------------------------
    --Local return variables for the subfunction
    local checksWereDone			 = false
    local atLeastOneMarkerIconWasSet = false

    local settings = FCOIS.settingsVars.settings

    local function abortChecksNow(whereWasTheFunctionAborted)
        if settings.debug then
            whereWasTheFunctionAborted = whereWasTheFunctionAborted or "n/a"
            if whereWasTheFunctionAborted ~= "" then
                d("<<[FCOIS]ScanInvForAutomaticMarks \"" .. tostring(scanType) .. "\". Aborting! [" .. tostring(whereWasTheFunctionAborted) .. "]")
            else
                d("<<[FCOIS]ScanInvForAutomaticMarks \"" .. tostring(scanType) .. "\". Aborting!")
            end
        end
        return false, false
    end

    --------------------------------------------------------------------------------
    --Check only one bag & slot, or a whole inventory?
    if bag ~= nil and slot ~= nil then
        --Are the TO DOs given?
        if toDos == nil then if not settings.debug then return false, false else return abortChecksNow("ToDos are nil!") end end
        --d(">Todos found")

        --Check only one item slot
        --Is the inventory already scanned currently?
        if FCOIS.preventerVars.gScanningInv then
            --d("<<<!!! Aborting inv. scan. Scan already active - bag: " .. tostring(bag) .. ", slot: " .. tostring(slot) .. " scanType: " .. tostring(scanType) .. " !!!>>>")
            if not settings.debug then return false, false else return abortChecksNow("Scanning inv already")  end
        end
        local itemLink
--d("!!!!!> Scanning - bag: " .. tostring(bag) .. ", slot: " .. tostring(slot) .. " " .. itemLink .. " scanType: " .. tostring(scanType) .. " <!!!!!")
        FCOIS.preventerVars.gScanningInv = true

        --------------------------------------------------------------------------------
        --					Execute the TODOs now									  --
        --------------------------------------------------------------------------------
        local forceAdditionalCheckFunc = false
        --1) Icon
        --Check if the marker icon is given and enabled
        if not toDos.icon or not settings.isIconEnabled[toDos.icon] then if not settings.debug then return false, false else return abortChecksNow("Icon not given/not enabled: " ..tostring(toDos.icon)) end  end
        --d(">Active icon found for '" .. tostring(scanType) .. "': " .. tostring(toDos.icon))

        --2) Settings enabled?
        --Check if the settings to automatically mark the item is enabled
        local checkResult
        if toDos.check ~= nil then
            if type(toDos.check) == "function" then
                checkResult = toDos.check(bag, slot)
            else
                checkResult = toDos.check
            end
            --d(">Check active: " .. tostring(checkResult) .. " (" .. tostring(toDos.result) .. "/" .. tostring(toDos.resultNot) .. ")")
            --Result should equal the check variable
            if toDos.result ~= nil then
                --Result does NOT equal check variable -> abort
                if checkResult ~= toDos.result then if not settings.debug then return false, false else return abortChecksNow("Check value " .. tostring(checkResult) .. " <> result " ..tostring(toDos.result)) end  end
            --Result should NOT equal the check variable
            elseif toDos.resultNot ~= nil then
                --Result equals check variable -> abort
                if checkResult == toDos.resultNot then if not settings.debug then return false, false else return abortChecksNow("Check value " .. tostring(checkResult) .. " <> result NOT " ..tostring(toDos.resultNot)) end  end
            else
                --No expected result given? Abort
                if not settings.debug then return false, false else return abortChecksNow("No expected result given")  end
            end
        end

        --3) Other addons needed?
        --Check if the settings to automatically mark the item is enabled
        local checkOtherAddonResult
        if toDos.checkOtherAddon ~= nil then
            if type(toDos.checkOtherAddon) == "function" then
                checkOtherAddonResult = toDos.checkOtherAddon(bag, slot)
            else
                checkOtherAddonResult = toDos.checkOtherAddon
            end
            --d(">Other addons active: " .. tostring(toDos.checkOtherAddon) .. " (" .. tostring(toDos.resultOtherAddon) .. "/" .. tostring(toDos.resultNotOtherAddon) .. ")")
            --Result should equal the other addons check variable
            if toDos.resultOtherAddon ~= nil then
                --Result does NOT equal other addons check variable -> abort
                if checkOtherAddonResult ~= toDos.resultOtherAddon then if not settings.debug then return false, false else return abortChecksNow("Check other addon value " .. tostring(checkOtherAddonResult) .. " <> result other addon value " ..tostring(toDos.resultOtherAddon)) end  end
            --Result should NOT equal the other addons check variable
            elseif toDos.resultNotOtherAddon ~= nil then
                --Result equals other addons check variable -> abort
                if checkOtherAddonResult == toDos.resultNotOtherAddon then if not settings.debug then return false, false else return abortChecksNow("Check other addon value " .. tostring(checkOtherAddonResult) .. " <> result NOT other addon value" ..tostring(toDos.resultNotOtherAddon)) end  end
            else
                --No expected result given? Abort
                if not settings.debug then return false, false else return abortChecksNow("No expected other addon result given") end
            end
        end

        --4) Build the itemInstanceId and check if the item is protected already, and
        --	  if the item can be automatically marked

        --The variable for the check function result
        local checkFuncResult = false
        --The variable tha can be returned from the checkFunc as 2nd parameter: The new icon that should be used to mark the icon, instead of the todos.IconId
        local checkFuncResultData
        --The variable for the additional check function result
        local additionalCheckFuncResult = false
        --The variable tha can be returned from the additionalCheckFunc as 2nd parameter: The new icon that should be used to mark the icon, instead of the todos.IconId
        local additionalCheckFuncResultData
        --The item's instance iD
        local itemId
        itemId = FCOIS.MyGetItemInstanceIdNoControl(bag, slot, false)
        --Is the itemInstanceId/uniqueId not given,
        --or the item cannot be automatically marked (anymore),
        --  or the item is already marked with the wished icon
        --  or the item is already marked with any icon, if enabled to be checked
        local isItemProtected = true
        local canBeAutomaticallyMarked = true
        local iconIsMarkedAllreadyAllowed = (toDos.iconIsMarkedAllreadyAllowed ~= nil and toDos.iconIsMarkedAllreadyAllowed) or false
        if 	itemId ~= nil then
            canBeAutomaticallyMarked = checkIfCanBeAutomaticallyMarked(bag, slot, itemId, scanType)
            if canBeAutomaticallyMarked then
                if toDos.checkIfAnyIconIsMarkedAlready ~= nil and toDos.checkIfAnyIconIsMarkedAlready == true then
                    local iconIdArray = {}
                    local doAddIconNow = false
                    for iconNr = 1, numFilterIcons, 1 do
                        doAddIconNow = true
                        if iconIsMarkedAllreadyAllowed and iconNr == toDos.icon then doAddIconNow = false end
                        if doAddIconNow then
                            table.insert(iconIdArray, iconNr)
                        end
                    end
                    isItemProtected = checkIfItemArrayIsProtected(iconIdArray, itemId)
                else
                    if not iconIsMarkedAllreadyAllowed then
                        isItemProtected = FCOIS.checkIfItemIsProtected(toDos.icon, itemId)
                    else
                        isItemProtected = false
                    end
                end
            end
        end
        if itemId == nil or not canBeAutomaticallyMarked or isItemProtected	then
            --d("<-- ABORTED [".. itemLink .. "] - ItemId: " .. tostring(itemId) .. ", scanType: " .. tostring(scanType) .. ", FCOIS.checkIfItemIsProtected: " .. tostring(isItemProtected) .. " -> Should be: false, checkIfCanBeAutomaticallyMarked: (" .. tostring(canBeAutomaticallyMarked) .." -> Should be: true)")
            if not settings.debug then return false, false else return abortChecksNow("ItemId nil?: " .. tostring(itemId) .. ", canBeAutomaticallyMarked false/nil?: " ..tostring(canBeAutomaticallyMarked) .. ", isItemProtected true?: " ..tostring(isItemProtected)) end
        end

        --5) Check function needs to be run?
        if toDos.checkFunc ~= nil then
            if type(toDos.checkFunc) == "function" then
                --The check is a function, so call it with the bagId and slotIndex
                checkFuncResult, checkFuncResultData = toDos.checkFunc(bag, slot)
            else
                --The check is no function but a variable
                checkFuncResult = toDos.checkFunc
            end
            --Is the additionalCheckFunc foced to be executed?
            if toDos.additionalCheckFuncForce ~= nil then
                if type(toDos.additionalCheckFuncForce) == "function" then
                    forceAdditionalCheckFunc = toDos.additionalCheckFuncForce
                elseif  type(toDos.additionalCheckFuncForce) == "boolean" then
                    forceAdditionalCheckFunc = toDos.additionalCheckFuncForce
                else
                    forceAdditionalCheckFunc = true
                end
            end

            --d(">Check func active: " .. tostring(checkFuncResult) .. " (" .. tostring(toDos.resultCheckFunc) .. "/" .. tostring(toDos.resultNotCheckFunc) .. "), forceAdditionalCheckFunc: " ..tostring(forceAdditionalCheckFunc))
            --Was the check successfull?
            if checkFuncResult == nil and not forceAdditionalCheckFunc then if not settings.debug then return false, false else return abortChecksNow("CheckFuncResult is nil and no force to go on is active!") end  end
            --Result should equal the check func result
            if not forceAdditionalCheckFunc then
                if toDos.resultCheckFunc ~= nil then
                    --Result does NOT equal check func result -> abort
                    if checkFuncResult ~= toDos.resultCheckFunc then if not settings.debug then return false, false else return abortChecksNow("CheckFunc " .. tostring(checkFuncResult) .. " <> CheckFuncResult " ..tostring(toDos.resultCheckFunc)) end  end
                --Result should NOT equal the check func result
                elseif toDos.resultNotCheckFunc ~= nil then
                    --Result equals check func result -> abort
                    if checkFuncResult == toDos.resultNotCheckFunc then if not settings.debug then return false, false else return abortChecksNow("CheckFunc " .. tostring(checkFuncResult) .. " <> NOT CheckFuncResult " ..tostring(toDos.resultNotCheckFunc)) end  end
                else
                    --No expected result given? Abort
                    if not settings.debug then return false, false else return abortChecksNow("Check func or result not used")  end
                end
            end
        end

        --6) Additional check function should be executed?
        if toDos.additionalCheckFunc ~= nil then
            if type(toDos.additionalCheckFunc) == "function" then
                --Build the itemData table for the checkfunc
                local itemData
                itemData = {}
                itemData.bagId		= bag
                itemData.slotIndex	= slot
                itemData.itemId		= itemId
                itemData.scanType	= scanType
                if checkFuncResultData ~= nil then
                    itemData.fromCheckFunc = {}
                    itemData.fromCheckFunc = checkFuncResultData
                end
                if itemData == nil then if not settings.debug then return false, false else return abortChecksNow("Additional check func, itemdata is nil!") end  end
                --The check is a function, so call it with the itemData table and the current check func result variable
                additionalCheckFuncResult, additionalCheckFuncResultData = toDos.additionalCheckFunc(itemData, checkFuncResult)
            else
                --The check is no function but a variable
                additionalCheckFuncResult = toDos.additionalCheckFunc
            end
--d(">Add. check func active: " .. tostring(additionalCheckFuncResult) .. " (" .. tostring(toDos.resultAdditionalCheckFunc) .. "/" .. tostring(toDos.resultNotAdditionalCheckFunc) .. ")")
            --Was the check successfull?
            if additionalCheckFuncResult == nil then if not settings.debug then return false, false else return abortChecksNow("Additional check func result is nil!") end  end
            --Result should equal the add. check func result
            if toDos.resultAdditionalCheckFunc ~= nil then
                --Result does NOT equal add. check func result -> abort
                if additionalCheckFuncResult ~= toDos.resultAdditionalCheckFunc then if not settings.debug then return false, false else return abortChecksNow("Additional check func " ..tostring(additionalCheckFuncResult) .. " <> Additional check func result " .. tostring(toDos.resultAdditionalCheckFunc)) end  end
            --Result should NOT equal the add. check func result
            elseif toDos.resultNotAdditionalCheckFunc ~= nil then
                --Result equals add. check func result -> abort
                if additionalCheckFuncResult == toDos.resultNotAdditionalCheckFunc then if not settings.debug then return false, false else return abortChecksNow("Additional check func " ..tostring(additionalCheckFuncResult) .. " <> NOT Additional check func result " .. tostring(toDos.resultNotAdditionalCheckFunc)) end  end
            else
                --No expected result given? Abort
                if not settings.debug then return false, false else return abortChecksNow("Additional check func or result not given!")  end
            end
        end
--d(">got here, addCheckfuncMarkerIcon")
        --Compare the two 2nd parameters (new marker icon IDs) of checkFunc and additionalCheckFunc.
        --Use the later one returned that is not nil as the new marker icon for the item
        local newMarkerIcon
        if type(toDos.icon) == "function" then
            newMarkerIcon = todos.icon(bag, slot)
        else
            newMarkerIcon = toDos.icon
        end
        if additionalCheckFuncResultData ~= nil and additionalCheckFuncResultData.newMarkerIcon ~= nil then
--d(">newMarkerIcon taken from add. check func newMarkerIcon")
            newMarkerIcon = additionalCheckFuncResultData.newMarkerIcon
        else
            if checkFuncResultData ~= nil and checkFuncResultData.newMarkerIcon ~= nil then
                newMarkerIcon = checkFuncResultData.newMarkerIcon
            end
        end
        --Set the return variable with the info, that the checks were done for at least one item
        checksWereDone = true
        --d(">Checks were done")

        --7) Mark the item now
        --Item was checked and should be marked now
        --FCOIS.MarkItem(bag, slot, iconId, showIcon, updateInventories)
        FCOIS.MarkItem(bag, slot, newMarkerIcon, true, false)
        --Set the return variable with the info, that at least one marker icon was set
        atLeastOneMarkerIconWasSet = true
        --8) Show chat output?

        --d(">Chat output: " .. tostring(toDos.chatOutput))
        --Show the marked item in the chat now?
        local chatOutput
        if type(toDos.chatOutput) == "function" then
            chatOutput = toDos.chatOutput(bag, slot)
        else
            chatOutput = toDos.chatOutput
        end
        local chatBegin
        if type(toDos.chatBegin) == "function" then
            chatBegin = toDos.chatBegin(bag, slot)
        else
            chatBegin = toDos.chatBegin
        end
        local chatEnd
        if type(toDos.chatEnd) == "function" then
            chatEnd = toDos.chatEnd(bag, slot)
        else
            chatEnd = toDos.chatEnd
        end
        if chatOutput or doOverride then
            itemLink = GetItemLink(bag, slot)
            --Show the marked item in the chat with the clickable itemLink
            if (itemLink ~= nil) then
                d(chatBegin .. itemLink .. chatEnd)
            end
            --local scanTypeCapitalText
            --scanTypeCapitalText = zo_strformat("<<C:1>>", scanType)
            --d(">scanType: " .. tostring(scanType) ..", scanTypeCapital: " .. tostring(scanTypeCapitalText))
        else
            --Show the marked item in the chat via debug message
            local scanTypeCapitalText
            scanTypeCapitalText = zo_strformat("<<C:1>>", scanType)
            if settings.debug then FCOIS.debugMessage( "[ScanInventoryFor".. scanTypeCapitalText or tostring(scanType) .."]", chatBegin .. itemLink .. chatEnd, false) end
        end
    end -- if bag ~= nil and slot ~= nil then
    --Return the functions return variables now
    --d("<<< retun checksWereDone: " .. tostring(checksWereDone) .. ", atLeastOneMarkerIconWasSet: " .. tostring(atLeastOneMarkerIconWasSet))
    return checksWereDone, atLeastOneMarkerIconWasSet
end -- Single item scan function scanInventoryItemForAutomaticMarks(bag, slot, scanType)
local scanInventoryItemForAutomaticMarks = FCOIS.scanInventoryItemForAutomaticMarks

--Function to check if the addtional checkFunction needs to be called for a call type
local function getAdditionalCheckFuncForce(callType)
--d("[FCOIS]getAdditionalCheckFuncForce, callType: " .. tostring(callType))
    if callType == nil then return false end
    local addCheckFuncNeedsToBeCalled = false

    if callType == "sets" then
        addCheckFuncNeedsToBeCalled = true
    end
    return addCheckFuncNeedsToBeCalled
end

--Function to do the scans for automatic marker icons (multiple items)
function FCOIS.scanInventoryItemsForAutomaticMarks(bag, slot, scanType, updateInv)
    updateInv = updateInv or false
    if not scanType then return false end
    local settings = FCOIS.settingsVars.settings
--d("FCOIS]scanInventoryItemsForAutomaticMarks-" .. il .. " bag: " ..tostring(bag) .. ", slot: " ..tostring(slot) .. ", scanType: " .. tostring(scanType) .. ", updateInv: " .. tostring(updateInv))
    --------------------------------------------------------------------------------
    --The table with the information "what should be done and marked how" for each scan type
    --This table contains a short scanType (e.g. "scan for unknown recipes" -> "recipes" as the key.
    --Below the key there is another table containing the information, what should be checked,
    --and how should it be done, are there any other addons involved, and what are the expected results,
    --which marker icon of FCOIS will be used to mark the item, and should the marked item be written to
    --the chat
    local scanTypeToDo = {
        ---------------------------- Quality -----------------------------------
        ["quality"] = {
            check				= settings.autoMarkQuality,
            result 				= nil,
            resultNot			= 1,
            checkOtherAddon		= nil,
            resultOtherAddon   	= nil,
            resultNotOtherAddon	= nil,
            icon				=           settings.autoMarkQualityIconNr,
            checkIfAnyIconIsMarkedAlready = settings.autoMarkQualityCheckAllIcons,
            checkFunc			= automaticMarkingQualityCheckFunc,
            resultCheckFunc 	= true,
            resultNotCheckFunc 	= nil,
            additionalCheckFunc = nil,
            resultAdditionalCheckFunc = true,
            resultNotAdditionalCheckFunc = nil,
            chatOutput			= settings.showQualityItemsInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["quality_item_found"],
        },
        ---------------------------- Ornate ------------------------------------
        ["ornate"] = {
            check				= settings.autoMarkOrnate,
            result 				= true,
            resultNot  			= nil,
            checkOtherAddon		= nil,
            resultOtherAddon   	= nil,
            resultNotOtherAddon	= nil,
            icon				= FCOIS_CON_ICON_SELL,
            checkIfAnyIconIsMarkedAlready = nil,
            checkFunc			= function(p_bagId, p_slotIndex)
                --Check if item is ornate
                return FCOIS.isItemOrnate(p_bagId, p_slotIndex), nil
            end,
            resultCheckFunc 	= true,
            resultNotCheckFunc 	= nil,
            additionalCheckFunc = nil,
            resultAdditionalCheckFunc = nil,
            resultNotAdditionalCheckFunc = nil,
            chatOutput			= settings.showOrnateItemsInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["ornate_item_found"],
        },
        ---------------------------- Intricate ---------------------------------
        ["intricate"] = {
            check				= settings.autoMarkIntricate,
            result 				= true,
            resultNot			= nil,
            checkOtherAddon		= nil,
            resultOtherAddon   	= nil,
            resultNotOtherAddon	= nil,
            icon				= FCOIS_CON_ICON_INTRICATE,
            checkIfAnyIconIsMarkedAlready = nil,
            checkFunc			= function(p_bagId, p_slotIndex)
                --Check if item is intricate
                return FCOIS.isItemIntricate(p_bagId, p_slotIndex), nil
            end,
            resultCheckFunc 	= true,
            resultNotCheckFunc 	= nil,
            additionalCheckFunc = nil,
            chatOutput			= settings.showIntricateItemsInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["intricate_item_found"],
        },
        ---------------------------- Researchable items-------------------------
        ["research"] = {
            check				= settings.autoMarkResearch,
            result 				= true,
            resultNot			= nil,
            checkOtherAddon		= function() return (FCOIS.checkIfResearchAddonUsed() and FCOIS.checkIfChosenResearchAddonActive()) or false end,
            resultOtherAddon   	= true,
            resultNotOtherAddon	= nil,
            icon				= FCOIS_CON_ICON_RESEARCH,
            checkIfAnyIconIsMarkedAlready = nil,
            checkFunc			= function(p_bagId, p_slotIndex)
                --Check if item is researchable
                local isItemResearchable = FCOIS.isItemResearchableNoControl(p_bagId, p_slotIndex, nil)
--d(">>>isItemResearchable: " ..tostring(isItemResearchable))
                return isItemResearchable, nil
            end,
            resultCheckFunc 	= true,
            resultNotCheckFunc 	= nil,
            additionalCheckFunc = function(p_itemData, p_checkFuncResult)
                return automaticMarkingResearchAdditionalCheckFunc(p_itemData, p_checkFuncResult), nil
            end,
            resultAdditionalCheckFunc = true,
            resultNotAdditionalCheckFunc = nil,
            chatOutput			= settings.showResearchItemsInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["research_item_found"],
        },
        ---------------------------- Research scrolls-------------------------------
        ["researchScrolls"] = {
            check				= settings.autoMarkWastedResearchScrolls,
            result 				= true,
            resultNot			= nil,
            checkOtherAddon		= nil,
            resultOtherAddon   	= nil,
            resultNotOtherAddon	= nil,
            icon				= FCOIS_CON_ICON_LOCK,
            checkIfAnyIconIsMarkedAlready = nil,
            checkFunc			= function(p_bagId, p_slotIndex)
                --Check if item is intricate
                return FCOIS.checkIfResearchScrollWouldBeWasted(p_bagId, p_slotIndex), nil
            end,
            resultCheckFunc 	= true,
            resultNotCheckFunc 	= nil,
            additionalCheckFunc = nil,
            chatOutput			= settings.showResearchItemsInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["researchScroll_item_found"],
        },
        ---------------------------- Unknown recipes ---------------------------
        ["recipes"] = {
            check				= settings.autoMarkRecipes,
            result 				= true,
            resultNot			= nil,
            checkOtherAddon		= function() return FCOIS.checkIfRecipeAddonUsed() and FCOIS.checkIfChosenRecipeAddonActive() end,
            resultOtherAddon   	= true,
            resultNotOtherAddon	= nil,
            icon				= settings.autoMarkRecipesIconNr,
            checkIfAnyIconIsMarkedAlready = nil,
            checkFunc			= function(p_bagId, p_slotIndex)
                --Check if item is an unknown recipe
                return FCOIS.isRecipeKnown(p_bagId, p_slotIndex, false), nil
            end,
            resultCheckFunc 	= false,
            resultNotCheckFunc 	= nil,
            additionalCheckFunc = nil,
            resultAdditionalCheckFunc = nil,
            resultNotAdditionalCheckFunc = nil,
            chatOutput			= settings.showRecipesInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["unknown_recipe_found"],
        },
        ---------------------------- Known recipes ---------------------------
        ["knownRecipes"] = {
            check				= settings.autoMarkKnownRecipes,
            result 				= true,
            resultNot			= nil,
            checkOtherAddon		= function() return FCOIS.checkIfRecipeAddonUsed() and FCOIS.checkIfChosenRecipeAddonActive() end,
            resultOtherAddon   	= true,
            resultNotOtherAddon	= nil,
            icon				= settings.autoMarkKnownRecipesIconNr,
            checkIfAnyIconIsMarkedAlready = nil,
            checkFunc			= function(p_bagId, p_slotIndex)
                --Check if item is an known recipe
                local resultVar1, resultVar2 = FCOIS.isRecipeKnown(p_bagId, p_slotIndex, true), nil
                return resultVar1, resultVar2
            end,
            resultCheckFunc 	= true,
            resultNotCheckFunc 	= nil,
            additionalCheckFunc = nil,
            resultAdditionalCheckFunc = nil,
            resultNotAdditionalCheckFunc = nil,
            chatOutput			= settings.showRecipesInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["known_recipe_found"],
        },
        ---------------------------- Set parts----------------------------------
        ["sets"] = {
            check				= settings.autoMarkSets,
            result 				= true,
            resultNot			= nil,
            checkOtherAddon		= nil,
            resultOtherAddon   	= nil,
            resultNotOtherAddon	= nil,
            icon				=           settings.autoMarkSetsIconNr,
            iconIsMarkedAllreadyAllowed = true,
            checkIfAnyIconIsMarkedAlready = settings.autoMarkSetsCheckAllIcons,
            checkFunc			= automaticMarkingSetsCheckFunc,
            resultCheckFunc 	= true,
            resultNotCheckFunc 	= nil,
            additionalCheckFuncForce = function() return getAdditionalCheckFuncForce("sets") end, -- force the call of the additional check func!
            additionalCheckFunc = automaticMarkingSetsAdditionalCheckFunc,
            resultAdditionalCheckFunc = false,
            resultNotAdditionalCheckFunc = nil,
            chatOutput			= settings.showSetsInChat,
            chatBegin			= FCOIS.localizationVars.fcois_loc["marked"],
            chatEnd				= FCOIS.localizationVars.fcois_loc["set_part_found"],
            ------------------------------------------------------------------------
        },
    } -- scantypeToDo
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--		Function start                                                        --
--------------------------------------------------------------------------------
    --Local variables for the return
    local checksWereDoneLoop			 = false
    local atLeastOneMarkerIconWasSetLoop = false
    --Is the scantype given: Get the todos ->
    --Get the array below the scanType with the functions and stepts to check
    local toDos = scanTypeToDo[scanType]
    if toDos == nil then return false, false end

    --Check only one bag & slot, or a whole inventory?
    if bag ~= nil and slot ~= nil then
        --Single item check
        checksWereDoneLoop, atLeastOneMarkerIconWasSetLoop = scanInventoryItemForAutomaticMarks(bag, slot, scanType, toDos)
        FCOIS.preventerVars.gScanningInv = false
    else
        --Check a whole inventory?
        local bagToCheck = bag or BAG_BACKPACK
        --d("[FCOIS]--> Scan whole inventory, bag: " .. tostring(bagToCheck))
        --Get the bag cache (all entries in that bag)
        --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
        local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
        --Local variables for the for ... loop
        local checksWereDoneInForLoop			 	= false
        local atLeastOneMarkerIconWasSetInForLoop 	= false

        --For each item in that bag
        for _, data in pairs(bagCache) do
            local bagId 	= data.bagId
            local slotIndex = data.slotIndex
            if bagId ~= nil and slotIndex ~= nil then
                checksWereDoneInForLoop			 		= false
                atLeastOneMarkerIconWasSetInForLoop 	= false
                --Recursively call this function here
                checksWereDoneInForLoop, atLeastOneMarkerIconWasSetInForLoop = scanInventoryItemForAutomaticMarks(bagId, slotIndex, scanType, toDos)
--d(">Whole bag item check. checksWereDoneLoop: " ..tostring(checksWereDoneLoop) .. ", atLeastOneMarkerIconWasSetLoop: " ..tostring(atLeastOneMarkerIconWasSetLoop))
                --Update the calling functions return variables
                if not checksWereDoneLoop then checksWereDoneLoop = checksWereDoneInForLoop end
                if not atLeastOneMarkerIconWasSetLoop then atLeastOneMarkerIconWasSetLoop = atLeastOneMarkerIconWasSetInForLoop end
                --Reset the variable, that the inventories are not currently scanned
                FCOIS.preventerVars.gScanningInv = false
            end
        end
    end
    --------------------------------------------------------------------------------
    --				Function ends												  --
    --------------------------------------------------------------------------------
    --d("[FCOIS]>Scaning inv ended")

    --Was at least one item found that could be marked?
    if updateInv and atLeastOneMarkerIconWasSetLoop == true then
        --Update the inventory tabs to show the marker textures
        FCOIS.FilterBasics(true)
    end

    --------------------------------------------------------------------------------
    --Return the functions return variables now
    --d("<<< retun checksWereDoneLoop: " .. tostring(checksWereDoneLoop) .. ", atLeastOneMarkerIconWasSetLoop: " .. tostring(atLeastOneMarkerIconWasSetLoop) .. ", scanType: " .. tostring(scanType))
    return checksWereDoneLoop, atLeastOneMarkerIconWasSetLoop
end
local scanInventoryItemsForAutomaticMarks = FCOIS.scanInventoryItemsForAutomaticMarks

--Local function to scan a single inventory item
function FCOIS.scanInventorySingle(p_bagId, p_slotIndex)
--d("[ScanInventorySingle] bag: " .. tostring(p_bagId) .. ", slot: " .. tostring(p_slotIndex) .. ", scanningInv: " .. tostring(FCOIS.preventerVars.gScanningInv))
    local updateInv = false
    local settings = FCOIS.settingsVars.settings
    if FCOIS.preventerVars.gScanningInv == false then
        if settings.debug then FCOIS.debugMessage( "[ScanInventorySingle]","Start", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[ScanInventorySingle] Start")
        -- Update only one item in inventory
        -- bagId AND slotIndex are given?
        if (p_bagId ~= nil and p_slotIndex ~= nil) then
            --Check if item is researchable
            local itemId = FCOIS.MyGetItemInstanceIdNoControl(p_bagId, p_slotIndex, false)
            if (itemId ~= nil) then

                --Update ornate items
                if (settings.autoMarkOrnate == true and settings.isIconEnabled[FCOIS_CON_ICON_SELL]) then
                    local _, ornateChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "ornate", false)
                    if not updateInv and ornateChanged then
                        updateInv = true
                    end
                end

                --Update intricate items
                if (settings.autoMarkIntricate == true and settings.isIconEnabled[FCOIS_CON_ICON_INTRICATE]) then
                    local _, intricateChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "intricate", false)
                    if not updateInv and intricateChanged then
                        updateInv = true
                    end
                end

                --Update researchable items
                if (settings.autoMarkResearch == true and FCOIS.checkIfResearchAddonUsed() and FCOIS.checkIfChosenResearchAddonActive() and settings.isIconEnabled[FCOIS_CON_ICON_RESEARCH]) then
--local itemLink = GetItemLink(p_bagId, p_slotIndex)
--d(">scanInvSingle, research scan reached for: " .. itemLink)
                    local _, researchableChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "research", false)
                    if not updateInv and researchableChanged then
                        updateInv = true
                    end
                end

                --Update research scrolls (time reduction for crafting research) items
                if ((DetailedResearchScrolls ~= nil and DetailedResearchScrolls.GetWarningLine ~= nil) and settings.autoMarkWastedResearchScrolls == true and settings.isIconEnabled[FCOIS_CON_ICON_LOCK]) then
                    local _, researchScrollWastedChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "researchScrolls", false)
                    if not updateInv and researchScrollWastedChanged then
                        updateInv = true
                    end
                end

                --Check for item quality
                if (settings.autoMarkQuality ~= 1 and settings.isIconEnabled[settings.autoMarkQualityIconNr]) then
                    local _, qualityChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "quality", false)
                    if not updateInv and qualityChanged then
                        updateInv = true
                    end
                end

                --Update unknown recipes
                if FCOIS.isRecipeAutoMarkDoable(true, false, true) then
                    local _, recipeChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "recipes", false)
                    if not updateInv and recipeChanged then
                        updateInv = true
                    end
                end

                --Update known recipes
                if FCOIS.isRecipeAutoMarkDoable(false, true, true) then
                    local _, recipeChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "knownRecipes", false)
                    if not updateInv and recipeChanged then
                        updateInv = true
                    end
                end

                --Mark set parts
                if (settings.autoMarkSets == true and settings.isIconEnabled[settings.autoMarkSetsIconNr]) then
                    local _, setPartChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "sets", false)
                    if not updateInv and setPartChanged then
                        updateInv = true
                    end
                end
            end -- if (itemId ~= nil) then
        end --if (p_bagId ~= nil and p_slotIndex ~= nil) then
        --Inventory scan is latest finished here
        --FCOIS.preventerVars.gScanningInv = false
    end
    if settings.debug then FCOIS.debugMessage( "[ScanInventorySingle]","End", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[ScanInventorySingle] END, updateInv: " .. tostring(updateInv))
    return updateInv
end
local scanInventorySingle = FCOIS.scanInventorySingle

--Scan the inventory for ornate and/or researchable items
function FCOIS.scanInventory(p_bagId, p_slotIndex)
    --Do not scan now if the unique item IDs got just enabled before the reloadui
    if FCOIS.preventerVars.doNotScanInv then
        if FCOIS.settingsVars.settings.useUniqueIds then
            d(FCOIS.preChatVars.preChatTextRed .. FCOIS.localizationVars.fcois_loc["options_migrate_unique_inv_scan_not_done"])
        end
        FCOIS.preventerVars.doNotScanInv = false
        return false
    end
--d("[ScanInventory] bag: " .. tostring(p_bagId) .. ", slot: " .. tostring(p_slotIndex) .. ", scanningInv: " .. tostring(FCOIS.preventerVars.gScanningInv))
    local updateInv = false
    local settings = FCOIS.settingsVars.settings
    local isRecipeAddonActive = (FCOIS.checkIfRecipeAddonUsed() and FCOIS.checkIfChosenRecipeAddonActive()) or false
    local isResearchAddonActive = (FCOIS.checkIfResearchAddonUsed() and FCOIS.checkIfChosenResearchAddonActive() and settings.isIconEnabled[FCOIS_CON_ICON_RESEARCH]) or false
    local isResearchScrollsAddonActive = (DetailedResearchScrolls ~= nil and DetailedResearchScrolls.GetWarningLine ~= nil and settings.isIconEnabled[FCOIS_CON_ICON_LOCK]) or false
--d(">isResearchAddonActive: " ..tostring(isResearchAddonActive))
    --Automatic marking of ornate, intricate, researchable items (researchAssistant or other research addon needed, or ESO base game marks for researchabel items), unknown recipes (SousChef or other recipe addon is needed!), set parts, quality items is activated?
    local isCheckNecessary = (
               (settings.autoMarkOrnate == true and settings.isIconEnabled[FCOIS_CON_ICON_SELL])
            or (settings.autoMarkIntricate == true and settings.isIconEnabled[FCOIS_CON_ICON_INTRICATE])
            or (isResearchAddonActive and settings.autoMarkResearch == true )
            or (settings.autoMarkQuality ~= 1 and settings.isIconEnabled[settings.autoMarkQualityIconNr])
            or (isRecipeAddonActive and settings.autoMarkRecipes == true and settings.isIconEnabled[settings.autoMarkRecipesIconNr])
            or (isRecipeAddonActive and settings.autoMarkKnownRecipes == true and settings.isIconEnabled[settings.AutoMarkKnownRecipesIconNr])
            or (settings.autoMarkSets == true and settings.isIconEnabled[settings.autoMarkSetsIconNr])
            or (isResearchScrollsAddonActive and settings.autoMarkWastedResearchScrolls == true)
            ) and FCOIS.preventerVars.gScanningInv == false
    if isCheckNecessary then

        -- Scan the whole inventory because no bagId and slotIndex are given
        if p_bagId == nil or p_slotIndex == nil then
--d("[ScanInventory] Start ALL")
            if settings.debug then FCOIS.debugMessage( "[ScanInventory]","Start ALL", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Check a whole inventory?
            local bagToCheck = p_bagId or BAG_BACKPACK
--d("[FCOIS]--> Scan whole inventory, bag: " .. tostring(bagToCheck))
            --Get the bag cache (all entries in that bag)
            --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
            local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
            local updateInvLoop = false
            for _, data in pairs(bagCache) do
                updateInvLoop = false
                updateInvLoop = scanInventorySingle(data.bagId, data.slotIndex)
                if not updateInv then updateInv = updateInvLoop end
            end
            if settings.debug then FCOIS.debugMessage( "[ScanInventory]","End ALL", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[ScanInventory] END ALL")

        else
            --d("[ScanInventory] Start ONE ITEM")
            -- Scan only one item?
            if p_bagId ~= nil and p_slotIndex ~= nil then
                updateInv = scanInventorySingle(p_bagId, p_slotIndex)
            end
            --d("[ScanInventory] End ONE ITEM")
        end

        --Update the inventories?
        if updateInv == true then
            FCOIS.FilterBasics(true)
        end
    end --if isCheckNecessary then
end

--Check if the scanned item in function "scanInventoriesForZOsLockedItems" is marked with the ZOs saver icon (white/gray lock icon) and transfer it to FCOIS's icon 1 (lock)
function FCOIS.scanInventoriesForZOsLockedItemsAndTransfer(p_bagId, p_slotIndex)
    local foundAndTransferedOne
    --Scan for ZOs marked icons and transfer them to FCOIS marker icon 1 (lock symbol)
    if ( not FCOIS.preventerVars.gScanningInv and p_bagId ~= nil and p_slotIndex ~= nil ) then
        FCOIS.preventerVars.gScanningInv = true
        local itemId = FCOIS.MyGetItemInstanceIdNoControl(p_bagId, p_slotIndex)
        --Is the item marked with ZOs marker function and not marked with FCOIS already
        if (itemId ~= nil and IsItemPlayerLocked(p_bagId, p_slotIndex)) then
            foundAndTransferedOne = true
            --Mark the item with FCOIS without checking if other markers should be removed etc. (see function FCOMarkMe())
            FCOIS.markedItems[1][FCOIS.SignItemId(itemId, nil, nil, nil)] = true
            --Unmark the item with ZOs functions
            SetItemIsPlayerLocked(p_bagId, p_slotIndex, false)
        end
        FCOIS.preventerVars.gScanningInv = false
    end
    return foundAndTransferedOne
end

--Scan the inventory for ZOs locked items and transfer them to FCOIS marker icons
function FCOIS.scanInventoriesForZOsLockedItems(allInventories, houseBankBagId)
    --Only run if the ZOs build in marker functions are disabled!
    if FCOIS.settingsVars.settings.useZOsLockFunctions then return false end
    allInventories = allInventories or false
    if houseBankBagId ~= nil then
        allInventories = false
        allInventories = false
    end

    --Only scan if not already scanning
    if FCOIS.preventerVars.gScanningInv then return false end
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[scanInventoriesForZOsLockedItemsAndTransfer]","Start ALL, allInventories: " ..tostring(allInventories), false) end
    local atLeastOneZOsMarkedFound = false
    local allowedBagTypes = {}
    if allInventories then
        --Scan all the inventories of the player (bank, bag, guild bank, craftbag, etc.)
        allowedBagTypes = {
            [BAG_BACKPACK] 	= true,
            [BAG_BANK] 		= true,
            [BAG_BUYBACK] 	= false,
            [BAG_GUILDBANK] = false,
            [BAG_VIRTUAL] 	= false, --Craftbag
            [BAG_WORN] 		= true,
        }
        --Is the user an ESO+ subscriber?
        if IsESOPlusSubscriber() then
            --Add the subscriber bank to the inventories to check
            if GetBagUseableSize(BAG_SUBSCRIBER_BANK) > 0 then
                allowedBagTypes[BAG_SUBSCRIBER_BANK] = true
            end
        end

    else
        if houseBankBagId ~= nil and IsHouseBankBag(houseBankBagId) then
            --Add the house bank bags
            allowedBagTypes[houseBankBagId] = true
        else
            --Scan only the player inventory
            allowedBagTypes = {
                [BAG_BACKPACK] 	= true,
            }
        end
    end
    --Scan every item in the bag
    for bagType, allowed in pairs(allowedBagTypes) do
        if allowed then
            --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagType)
            local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagType)
            local foundAndTransferedOne = false
            for _, data in pairs(bagCache) do
                foundAndTransferedOne = FCOIS.scanInventoriesForZOsLockedItemsAndTransfer(data.bagId, data.slotIndex)
                if foundAndTransferedOne then
                    atLeastOneZOsMarkedFound = true
                end
            end
        end
    end
    --Update the inventories
    if atLeastOneZOsMarkedFound == true then
        FCOIS.FilterBasics(true)
    end
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[scanInventoriesForZOsLockedItems]", "End, allInventories: " ..tostring(allInventories), false) end
end