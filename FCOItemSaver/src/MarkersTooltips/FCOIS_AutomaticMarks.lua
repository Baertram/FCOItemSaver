--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage
local tos       = tostring
local ton       = tonumber
local strformat = string.format
local zo_strf   = zo_strformat
local tins      = table.insert

local gil       = GetItemLink
local gili      = GetItemLinkInfo
local giliid    = GetItemLinkItemId
local gilsi     = GetItemLinkSetInfo
local gilrl     = GetItemLinkRequiredLevel
local gilrcp    = GetItemLinkRequiredChampionPoints
local gcpppc    = GetChampionPointsPlayerProgressionCap

local giwt      = GetItemWeaponType
local giat      = GetItemArmorType
local giti      = GetItemTraitInformation

local iilscpu   = IsItemSetCollectionPieceUnlocked
local iilscp    = IsItemLinkSetCollectionPiece
local iilc      = IsItemLinkCrafted

local account = GetDisplayName()

local libSets = FCOIS.libSets

local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
--local getSavedVarsMarkedItemsTableName = FCOIS.GetSavedVarsMarkedItemsTableName

local lmas = FCOIS.libMultiAccountSets

local ctrlVars = FCOIS.ZOControlVars
local mappingVars = FCOIS.mappingVars
local otherAddons = FCOIS.otherAddons
local oaSetTracker = otherAddons.SetTracker --#302 SetTracker support disabled with FCOOIS v2.6.1, for versions <300

local checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local filterBasics = FCOIS.FilterBasics
local getFilterPanelIdText = FCOIS.GetFilterPanelIdText
local getFilterPanelIdByBagId = FCOIS.GetFilterPanelIdByBagId
local isItemResearchableNoControl = FCOIS.IsItemResearchableNoControl
local isItemOrnate = FCOIS.IsItemOrnate
local isItemIntricate = FCOIS.IsItemIntricate
local checkIfResearchScrollWouldBeWasted = FCOIS.CheckIfResearchScrollWouldBeWasted
local checkIfIsSpecialItem = FCOIS.CheckIfIsSpecialItem
local checkNeededLevel = FCOIS.CheckNeededLevel
local isItemSetPartWithTraitNoControl = FCOIS.IsItemSetPartWithTraitNoControl
local isRecipeAutoMarkDoable = FCOIS.IsRecipeAutoMarkDoable
local isRecipeKnown = FCOIS.IsRecipeKnown
local isMotifsAutoMarkDoable = FCOIS.IsMotifsAutoMarkDoable --#308
local isMotifKnown = FCOIS.IsMotifKnown                   --#308
local isItemSetAndNotExcluded = FCOIS.IsItemSetAndNotExcluded
local checkIfRecipeAddonUsed = FCOIS.CheckIfRecipeAddonUsed
local checkIfChosenRecipeAddonActive = FCOIS.CheckIfChosenRecipeAddonActive
local checkIfMotifsAddonUsed = FCOIS.CheckIfMotifsAddonUsed --#308
local checkIfChosenMotifsAddonActive = FCOIS.CheckIfChosenMotifsAddonActive --#308
local getResearchAddonUsed = FCOIS.GetResearchAddonUsed
local checkIfResearchAddonUsed = FCOIS.CheckIfResearchAddonUsed
local checkIfChosenResearchAddonActive = FCOIS.CheckIfChosenResearchAddonActive

local checkIfHouseOwnerAndInsideOwnHouse = FCOIS.CheckIfHouseOwnerAndInsideOwnHouse

local getItemQuality = FCOIS.GetItemQuality

local markItem
local isMarked

--==========================================================================================================================================
--									FCOIS Inventory scanning & automatic item marking
--==========================================================================================================================================

--Function do check if an array of icons is marked and thus protected
local function checkIfItemArrayIsProtected(iconIdArray, itemId)
    if iconIdArray == nil or #iconIdArray == 0 or itemId == nil then return false end
    local isProtected = false
    --Check each iconId in the arry now for a protection
    for i=1, #iconIdArray, 1 do
        isProtected = checkIfItemIsProtected(iconIdArray[i], itemId)
        if isProtected then break end
    end
    return isProtected
end

--Function to return if the automatic markings at a chosen bagId (or if nil then all bagIds) is disabled
function FCOIS.CheckIfAutomaticMarksAreDisabledAtBag(bagId)
    FCOIS.LoadUserSettings(false, false)
    for bagIdToScan, isEnabled in pairs(FCOIS.settingsVars.settings.autoMarkBagsToScan) do
        if bagId == nil then
            if isEnabled == true then return false end
        else
            if bagIdToScan == bagId then
                if isEnabled == true then return false end
            end
        end
    end
    return true
end
--local checkIfAutomaticMarksAreDisabledAtBag = FCOIS.CheckIfAutomaticMarksAreDisabledAtBag

--Function to check if an item is allowed to be marked automatically with another icon, from any of the "automatic marks"
local function checkIfCanBeAutomaticallyMarked(bagId, slotIndex, itemId, checkType)
--d("[FCOIS] checkIfCanBeAutomaticallyMarked - bag: " .. tos(bagId) .. ", slotIndex: " .. tos(slotIndex) .. ", itemId: " .. tos(itemId) .. ", checkType: " .. tos(checkType))
    if (bagId == nil or slotIndex == nil) and itemId == nil then return false end
    if itemId == nil then
        itemId = myGetItemInstanceIdNoControl(bagId, slotIndex)
    end

    isMarked = isMarked or FCOIS.IsMarked

    --Get all icons of the item
    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
    local isMarkedWithOneIcon, markedIcons = isMarked(bagId, slotIndex, -1)
    if isMarkedWithOneIcon and markedIcons then
        local settings = FCOIS.settingsVars.settings
        local iconIdToIsDnamicIcon = mappingVars.iconIsDynamic
        --Loop over all icons of the item
        for iconId, iconIsMarked in pairs(markedIcons) do
            --Is the current icon marked?
            if iconIsMarked == true then
                --Is the current icon an dynamic icon?
                local isDynIcon = iconIdToIsDnamicIcon[iconId] or false
                --Non dynamic icon
                if not isDynIcon then
                    --Do not automatically mark items if they got the deconstruction icon on them?
                    if (iconId == FCOIS_CON_ICON_DECONSTRUCTION and settings.autoMarkPreventIfMarkedForDeconstruction == true)
                    --Do not automatically mark items if they got the sell icon on them?
                    or (iconId == FCOIS_CON_ICON_SELL and settings.autoMarkPreventIfMarkedForSell == true)
                    --Do not automatically mark items if they got the sell in guild store icon on them?
                    or (iconId == FCOIS_CON_ICON_SELL_AT_GUILDSTORE and settings.autoMarkPreventIfMarkedForSellAtGuildStore == true)
                    then
                        return false
                    end

                --Dynamic icons
                else
                    --Check if the dynamic icon got the "Prevent automatic mark again if this icon is set" checkbox enabled
                    if settings.icon[iconId].autoMarkPreventIfMarkedWithThis == true then
--d("[FCOIS]AutomaticMarks-checkIfCanBeAutomaticallyMarked. DynIcon: " ..tos(iconId) .. " prevents automatic marks!")
                        return false
                    end
                end
            end
        end
    end
    return true
end

--Do the additional checks for researchabel items (other addons, etc.)
local function automaticMarkingResearchAdditionalCheckFunc(p_itemData, p_checkFuncResult)
    --zo_callLater(function()
    --d("[FCOIS]automaticMarkingResearchAdditionalCheckFunc() bagId: " .. tos(p_itemData.bagId))
    local bag2Inv = mappingVars.bagToPlayerInv
    local inv = bag2Inv[p_itemData.bagId]
    if inv == nil then return false, nil end
    --The inventory slots got moved one hierarchy down, as the slots got a subarray now
    local playerInv = ctrlVars.playerInventoryInvs
    local playerInvOfInvVar = playerInv and playerInv[inv]
    local playerInvSlots = playerInvOfInvVar and playerInvOfInvVar.slots
    if not playerInvSlots then return end
    local inventorySlots = playerInvSlots[p_itemData.bagId]
    local retVar = false
    local itemDataEntry = inventorySlots[p_itemData.slotIndex]
    if itemDataEntry ~= nil then
        local settings = FCOIS.settingsVars.settings
        local bagId, slotIndex = p_itemData.bagId, p_itemData.slotIndex
        local itemLinkResearch = gil(bagId, slotIndex)
        local isResearchable = false
        --Only if coming from EVENT_INVENTORY_SINGLE_SLOT_UPDATE for new looted items as otherwise the dateEntry.data.researchAssistant exists properly!
        --Added function to Research Assistant but addon update is not released yet?
        local comingFromEventInvSingleSlotUpdate = FCOIS.preventerVars.eventInventorySingleSlotUpdate
        --ResearchAssistant should be used?
        local researchAddonId = getResearchAddonUsed()
        if researchAddonId == FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT then
            local isItemResearchableOrDuplicateWithSettingsCharacter = (ResearchAssistant.IsItemResearchableOrDuplicateWithSettingsCharacter ~= nil) or false
            if comingFromEventInvSingleSlotUpdate and ResearchAssistant ~= nil and
                    (isItemResearchableOrDuplicateWithSettingsCharacter == true or ResearchAssistant.IsItemResearchableWithSettingsCharacter ~= nil) then
                isResearchable = false
                if isItemResearchableOrDuplicateWithSettingsCharacter == true then
                    isResearchable = ResearchAssistant.IsItemResearchableOrDuplicateWithSettingsCharacter(bagId, slotIndex)
                    --return value could be true, false or "duplicate"
                    if isResearchable ~= true then isResearchable = false end
                else
                    isResearchable = ResearchAssistant.IsItemResearchableWithSettingsCharacter(bagId, slotIndex)
                end
            else
                isResearchable = (itemDataEntry.researchAssistant ~= nil and itemDataEntry.researchAssistant == 'researchable')
                --If this function was called from reloadui/login scanning the itemDataEntry.researchAssistant at the bank might be nil
                if (not itemDataEntry.researchAssistant or isResearchable == false) and (bagId == BAG_BANK or bagId == BAG_SUBSCRIBER_BANK or bagId == BAG_GUILDBANK) then
                    isResearchable = ResearchAssistant.IsItemResearchableOrDuplicateWithSettingsCharacter(bagId, slotIndex)
                    --return value could be true, false or "duplicate"
                    if isResearchable ~= true then isResearchable = false end
                else
                    isResearchable = (itemDataEntry.researchAssistant ~= nil and itemDataEntry.researchAssistant == 'researchable')
                end
            end

            --CraftStoreFixedAndImproved
        elseif researchAddonId == FCOIS_RESEARCH_ADDON_CSFAI then
            isResearchable = false
            if (otherAddons.craftStoreFixedAndImprovedActive and CraftStoreFixedAndImprovedLongClassName ~= nil and CraftStoreFixedAndImprovedLongClassName.IsResearchable ~= nil) then
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
                                        --d(">researchable " .. itemLinkResearch .. ", currentlyLoggedInCharOnly: " ..tos(currentlyLoggedInCharOnly) .. ", charName: " ..tos(charName))
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
            if giti(bagId, slotIndex) == ITEM_TRAIT_INFORMATION_CAN_BE_RESEARCHED then
                isResearchable = true
            end
        end
        --d("[FCOIS]automaticMarkingResearchAdditionalCheckFunc, isResearchable: " .. tos(isResearchable))
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
    local itemQuality = getItemQuality(p_bagId, p_slotIndex)
    --local itemLink = gil(p_bagId, p_slotIndex)
--d(itemLink .. ", quality: " .. tos(itemQuality))
    if not itemQuality then return false, nil end
    local settings = FCOIS.settingsVars.settings
    local autoMarkQuality = settings.autoMarkQuality
    if settings.autoMarkHigherQuality and autoMarkQuality < ITEM_DISPLAY_QUALITY_LEGENDARY then
        qualityCheck = itemQuality and itemQuality ~= false and itemQuality >= autoMarkQuality
    else
        qualityCheck = itemQuality and itemQuality ~= false and itemQuality == autoMarkQuality
    end
    --Is the item marked due to it's quality? Then check if the item is a weapon or armor part and exclude the check if the settings tell so
    if qualityCheck and settings.autoMarkHigherQualityExcludeArmor then
        --[[
                            giat(*integer* _bagId_, *integer* _slotIndex_)
                            ** _Returns:_ *[ArmorType|#ArmorType]* _armorType_
        ]]
        local itemArmorType = giat(p_bagId, p_slotIndex)
        --The item is an armor? Then don't mark it
        if itemArmorType ~= ARMORTYPE_NONE then
            return false, nil
        end
        --[[
                            * giwt(*integer* _bagId_, *integer* _slotIndex_)
                            ** _Returns:_ *[WeaponType|#WeaponType]* _weaponType_
        ]]
        local itemWeaponType = giwt(p_bagId, p_slotIndex)
        --The item is a weapon? Then don't mark it
        if itemWeaponType ~= WEAPONTYPE_NONE then
            return false, nil
        end
        --[[
                        * gili(*string* _itemLink_)
                        ** _Returns:_ *string* _icon_, *integer* _sellPrice_, *bool* _meetsUsageRequirement_, *integer* _equipType_, *integer* _itemStyle_
        ]]
        --Check if the item is a jewelry by using the item's equipType
        local itemLink = gil(p_bagId, p_slotIndex)
        if itemLink ~= nil and itemLink ~= "" then
            local _, _, _, equipType = gili(itemLink)
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
d("[FCOIS] checkIfAutomaticCraftedMarkerIconIsSet, creatingItem: " .. tos(creatingItem))
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

--Set item collection book checks
local locVars
local LMAS_isItemSetCollectionItemLinkUnlockedForAccount = lmas ~= nil and lmas.IsItemSetCollectionItemLinkUnlockedForAccount
local LMAS_getAccountList = lmas ~= nil and lmas.GetAccountList
--Check for set collections bok items (known/unknown) and return a boolean if the item should get marked + 2nd param the table with the checkFuncResultData for the
--.additionalCheckFunc, containing the newMarkerIcon = markerIcon to use for the MarkItem functions later on in the toDos processing
local function automaticMarkingSetsCollectionBookCheckFunc(p_bagId, p_slotIndex, knownOrUnknown)
    local doDebug = false --TODO DEBUG disable after debugging (p_bagId == BAG_BACKPACK and true) or false
    --local doDebug = (p_bagId == BAG_BACKPACK and true) or false
    if doDebug then d("automaticMarkingSetsCollectionBookCheckFunc - knownOrUnknown: " ..tos(knownOrUnknown)) end
    if knownOrUnknown == nil or p_bagId == nil or p_slotIndex == nil then return nil, nil end
    local settings = FCOIS.settingsVars.settings
    if not settings.autoMarkSetsItemCollectionBook then return nil, nil end

    isMarked = isMarked or FCOIS.IsMarked

    local itemLink = gil(p_bagId, p_slotIndex)
    --No self crafted set items!
    if iilc(itemLink) then return false, nil end
    local hasSet = gilsi(itemLink, false)
    if not hasSet then return false, nil end
    --Only item set collection pieces
    local isSetCollectionPiece = iilscp(itemLink)
    if not isSetCollectionPiece then return false, nil end

    local autoBindMissingSetCollectionPiecesOnLoot = settings.autoBindMissingSetCollectionPiecesOnLoot
    local autoMarkSetsItemCollectionBookAddonUsed = settings.autoMarkSetsItemCollectionBookAddonUsed
    local autoMarkSetsItemCollectionBookMissingIcon = settings.autoMarkSetsItemCollectionBookMissingIcon
    local autoMarkSetsItemCollectionBookNonMissingIcon = settings.autoMarkSetsItemCollectionBookNonMissingIcon
    local missingAndNonMissingIconsNone = (autoMarkSetsItemCollectionBookMissingIcon == FCOIS_CON_ICON_NONE and autoMarkSetsItemCollectionBookNonMissingIcon == FCOIS_CON_ICON_NONE and true) or false

    local isGuildBank = (p_bagId == BAG_GUILDBANK and true) or false --#231

    --Bind unknown?
    if doDebug then d(">>autoBindMissingSetCollectionPiecesOnLoot: " ..tos(autoBindMissingSetCollectionPiecesOnLoot) .. ", knownOrUnknown: " ..tos(knownOrUnknown)) end
    if autoBindMissingSetCollectionPiecesOnLoot == true then
        --Only go on if not scanning any GuildBank item, and if unknown checks are done
        if isGuildBank == true or knownOrUnknown ~= false then return nil, nil end
    else
        if ( autoMarkSetsItemCollectionBookAddonUsed == nil
                or missingAndNonMissingIconsNone == true
                or (knownOrUnknown == false and autoMarkSetsItemCollectionBookMissingIcon == nil)
                or (knownOrUnknown == true and autoMarkSetsItemCollectionBookNonMissingIcon == nil)
        )
        then
            if doDebug then d("<abort - autoMarkSetsItemCollectionBookAddonUsed: " ..tos(autoMarkSetsItemCollectionBookAddonUsed) .. ", missingAndNonMissingIconsNone: " ..tos(missingAndNonMissingIconsNone) .. ", MissingIcon: " ..tos(autoMarkSetsItemCollectionBookMissingIcon) .. ", KnownIcon: " ..tos(autoMarkSetsItemCollectionBookNonMissingIcon)) end
            return nil, nil
        end
    end

    local isIconEnabled = settings.isIconEnabled
    if doDebug then d(">automaticMarkingSetsCollectionBookCheckFunc: " ..tos(itemLink)) end

    local autoMarkSetsItemCollectionBookMissingItems    = (knownOrUnknown == false and autoMarkSetsItemCollectionBookMissingIcon > 0 and isIconEnabled[autoMarkSetsItemCollectionBookMissingIcon] == true) or false
    local autoMarkSetsItemCollectionBookKnownItemsBase  = (autoMarkSetsItemCollectionBookNonMissingIcon > 0 and isIconEnabled[autoMarkSetsItemCollectionBookNonMissingIcon] == true) or false
    local autoMarkSetsItemCollectionBookKnownItems      = (autoMarkSetsItemCollectionBookKnownItemsBase and knownOrUnknown == true) or false

    if doDebug then  d(">>autoMarkSetsItemCollectionBookMissingItems: " ..tos(autoMarkSetsItemCollectionBookMissingItems) .. ", autoMarkSetsItemCollectionBookKnownItemsBase: " ..tos(autoMarkSetsItemCollectionBookKnownItemsBase) .. ", autoMarkSetsItemCollectionBookKnownItems: " ..tos(autoMarkSetsItemCollectionBookKnownItems)) end

    if not autoBindMissingSetCollectionPiecesOnLoot and (not autoMarkSetsItemCollectionBookMissingItems and not autoMarkSetsItemCollectionBookKnownItems) then return nil, nil end

    local wasMarkedForSetCollectionsBook = false
    local markerIcon

    --Automatic binding of missing set collection book items
    local function autoBindMissingSetCollectionBookItem()
        --#250 2022-09-19 - BOP items will not enter the IF below :-(
        local isBoundItem = IsItemBound(p_bagId, p_slotIndex)
        if doDebug then  d(">>>>>autoBindMissingSetCollectionBookItem: " .. itemLink .. ", isBoundItem: " ..tos(isBoundItem) .. ", BOPTradeable: " ..tos(IsItemBoPAndTradeable(p_bagId, p_slotIndex)) .. ", BindType: " ..tos(GetItemBindType(p_bagId, p_slotIndex))) end
        if not isBoundItem or (isBoundItem == true and (IsItemBoPAndTradeable(p_bagId, p_slotIndex) or GetItemBindType(p_bagId, p_slotIndex) == BIND_TYPE_ON_PICKUP)) then
            if not isBoundItem then BindItem(p_bagId, p_slotIndex) end
            if settings.autoBindMissingSetCollectionPiecesOnLootToChat == true then
                locVars = locVars or FCOIS.localizationVars.fcois_loc
                if doDebug then d("[FCOIS]" .. strformat(locVars["chat_output_missing_set_collection_piece_was_bound"], itemLink)) end
            end
            --Mark as known after bind now, instead of mark as unknown?
            if settings.autoBindMissingSetCollectionPiecesOnLootMarkKnown == true and autoMarkSetsItemCollectionBookKnownItemsBase == true then
                markerIcon = autoMarkSetsItemCollectionBookNonMissingIcon
                if doDebug then d("!!>updated marker icon to known set collection") end
            end
        end
    end


    --Mark items for the sets collection book for the currently logegd in account's ESO standard API functions
    if autoMarkSetsItemCollectionBookAddonUsed == FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD then
        local isKnownSetCollectionItem = iilscpu(giliid(itemLink))
        if doDebug then d(">>isKnownSetCollectionItem: " ..tos(isKnownSetCollectionItem)) end
        if isKnownSetCollectionItem == true and autoMarkSetsItemCollectionBookKnownItems == true then
            --Non missing items?
            markerIcon = autoMarkSetsItemCollectionBookNonMissingIcon
            if doDebug then d(">>>markeIcon: known icon") end
        elseif not isKnownSetCollectionItem then
            if doDebug then d(">>unknown set collection item") end
            if autoMarkSetsItemCollectionBookMissingItems == true then
                --Missing items?
                markerIcon = autoMarkSetsItemCollectionBookMissingIcon
                if doDebug then  d(">>markeIcon: missing icon") end
            end
            --Auto bind missing set collection pieces?
            if not isGuildBank and autoBindMissingSetCollectionPiecesOnLoot == true then
                autoBindMissingSetCollectionBookItem()
            end
        end
        if markerIcon == nil or markerIcon <= 0 then return nil, nil end

        local isAlreadyMarked = false
        if settings.autoMarkSetsItemCollectionBookCheckAllIcons == true then
            --Check if any other icon is applied already
            FCOIS.preventerVars.gCalledFromInternalFCOIS = true
            isAlreadyMarked = isMarked(p_bagId, p_slotIndex, -1, nil)
        end
        if doDebug then d(">>>isAlreadyMarked: " ..tos(isAlreadyMarked)) end
        if isAlreadyMarked == false then
            --FCOIS.MarkItem(p_bagId, p_slotIndex, markerIcon) --do not mark here! Will be done in the further function calls of the todDos!
            wasMarkedForSetCollectionsBook = true
        end

        ------------------------------------------------------------------------------------------------------------------------
    else
        local useLibMultiAccountSets = (lmas ~= nil and autoMarkSetsItemCollectionBookAddonUsed == FCOIS_SETS_COLLECTION_ADDON_LIBMULTIACCOUNTSETS and true) or false
        if lmas then
            LMAS_isItemSetCollectionItemLinkUnlockedForAccount = LMAS_isItemSetCollectionItemLinkUnlockedForAccount or lmas.IsItemSetCollectionItemLinkUnlockedForAccount
            LMAS_getAccountList = LMAS_getAccountList or lmas.GetAccountList
        end

        --Mark items for the sets collection book for the currently logegd in account's, or other existing accounts, via
        --LibMultiAccountSets
        if useLibMultiAccountSets == true then

            --[[
                LibMultiAccountSets.GetNumItemSetCollectionSlotsUnlockedForAccount( account, itemSetId )
                * Built-in counterpart: GetNumItemSetCollectionSlotsUnlocked

                LibMultiAccountSets.IsItemSetCollectionSlotUnlockedForAccount( account, itemSetId, slot )
                * Built-in counterpart: IsItemSetCollectionSlotUnlocked

                LibMultiAccountSets.IsItemSetCollectionPieceUnlockedForAccount( account, pieceId )
                * Built-in counterpart: IsItemSetCollectionPieceUnlocked

                LibMultiAccountSets.GetItemReconstructionCurrencyOptionCostForAccount( account, itemSetId, currencyType )
                * Built-in counterpart: GetItemReconstructionCurrencyOptionCost


                LibMultiAccountSets.IsItemSetCollectionItemLinkUnlockedForAccount( account, itemLink )
                * Return type: boolean

                LibMultiAccountSets.GetAccountList( excludeCurrentAccount )
                * Return type: table/array of strings

                LibMultiAccountSets.GetItemCollectionAndTradabilityStatus( accounts, itemLink, itemSource )
                * itemLink can be nil if itemSource is supplied
                * itemSource is a table containing bagId, slotIndex, who, tradeIndex and/or lootId and can be omitted if itemLink is supplied
                * If accounts is a single account string, the return will be one of the following values:
                LibMultiAccountSets.ITEM_UNCOLLECTIBLE        -- Not a collectible set item
                LibMultiAccountSets.ITEM_COLLECTED            -- Collected by the specified account
                LibMultiAccountSets.ITEM_UNCOLLECTED_TRADE    -- Not collected by and tradeable with the specified account
                LibMultiAccountSets.ITEM_UNCOLLECTED_NOTRADE  -- Not collected by and not tradeable with the specified account
                LibMultiAccountSets.ITEM_UNCOLLECTED_UNKTRADE -- Not collected by the specified account, with unknown trade eligibility
                * If accounts is a list of multiple accounts or is omitted (all accounts), the return be either:
                LibMultiAccountSets.ITEM_UNCOLLECTIBLE, if the item is not a collectible set item
                A table of status codes for each account (see above)

                LibMultiAccountSets.OpenSettingsPanel( )
                * Return type: N/A
            ]]
            --Only mark items for the currently logged in account?
            if settings.autoMarkSetsItemCollectionBookOnlyCurrentAccount == true then
                local isKnownSetCollectionItem = LMAS_isItemSetCollectionItemLinkUnlockedForAccount( account, itemLink )
                if isKnownSetCollectionItem == true and autoMarkSetsItemCollectionBookKnownItems == true then
                    --Non missing items?
                    markerIcon = autoMarkSetsItemCollectionBookNonMissingIcon
                elseif not isKnownSetCollectionItem and autoMarkSetsItemCollectionBookMissingItems == true then
                    --Missing items?
                    markerIcon = autoMarkSetsItemCollectionBookMissingIcon
                    --Auto bind missing set collection pieces?
                    if not isGuildBank and autoBindMissingSetCollectionPiecesOnLoot == true then
                        autoBindMissingSetCollectionBookItem()
                    end
                end
                if markerIcon == nil or markerIcon <= 0 then return nil, nil end

                local isAlreadyMarked = false
                if settings.autoMarkSetsItemCollectionBookCheckAllIcons == true then
                    --Check if any other icon is applied already
                    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                    isAlreadyMarked = isMarked(p_bagId, p_slotIndex, -1, nil)
                end
                if isAlreadyMarked == false then
                    --FCOIS.MarkItem(p_bagId, p_slotIndex, markerIcon) --do not mark here! Will be done in the further function calls of the todDos!
                    wasMarkedForSetCollectionsBook = true
                end
            else
                --Mark for all accounts
                local myAccounts = LMAS_getAccountList()
                if myAccounts == nil then return nil, nil end

                --local wasMarkedForSetCollectionsBookLoop = false
                local isAlreadyMarked = false
                if settings.autoMarkSetsItemCollectionBookCheckAllIcons == true then
                    --Check if any other icon is applied already
                    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                    isAlreadyMarked = isMarked(p_bagId, p_slotIndex, -1, nil)
                end

                --Loop all accounts:
                for _, accountName in ipairs(myAccounts) do
                    markerIcon = nil
                    local isKnownSetCollectionItem = LMAS_isItemSetCollectionItemLinkUnlockedForAccount( accountName, itemLink )
                    if isKnownSetCollectionItem == true and autoMarkSetsItemCollectionBookKnownItems == true then
                        --Non missing items?
                        markerIcon = autoMarkSetsItemCollectionBookNonMissingIcon
                    elseif not isKnownSetCollectionItem and autoMarkSetsItemCollectionBookMissingItems == true then
                        --Missing items?
                        markerIcon = autoMarkSetsItemCollectionBookMissingIcon
                    end
                    if markerIcon ~= nil and markerIcon > 0 and isAlreadyMarked == false then
                        --FCOIS.MarkItem(p_bagId, p_slotIndex, markerIcon) --do not mark here! Will be done in the further function calls of the todDos!
                        --Any account needs/already owns this item and a marker icon was applied to this item?
                        wasMarkedForSetCollectionsBook = true
                        break --leave the for ... loop
                    end
                end --for
            end
        end
    end

    local checkFuncReturnData
    if markerIcon ~= nil then
        if doDebug then  d(">>>markerIcon for checkFuncReturnData.newMarkerIcon: " ..tos(markerIcon)) end
        --pass in the markerIcon to the additionalCheckFunc and toDos.icon
        checkFuncReturnData = {
            newMarkerIcon = markerIcon
        }
    end
    return wasMarkedForSetCollectionsBook, checkFuncReturnData
end

    --[[
    --#301 Do all the checks for the "automatic mark item with LibSets"
    local applyLibSetsSetSearchFavoriteCategoryMarker = FCOIS.ApplyLibSetsSetSearchFavoriteCategoryMarker --#301
    local function automaticMarkingLibSetsCheckFunc(p_bagId, p_slotIndex, setId) --#301
        --todo 20241204 --#301
        --Mark, or remove the mark now -> Checks are done in applyLibSetsSetSearchFavoriteCategoryMarker
        applyLibSetsSetSearchFavoriteCategoryMarker = applyLibSetsSetSearchFavoriteCategoryMarker or FCOIS.ApplyLibSetsSetSearchFavoriteCategoryMarker
        local wasIconApplied = applyLibSetsSetSearchFavoriteCategoryMarker(nil, p_bagId, p_slotIndex, nil, nil, setId)
        return wasIconApplied, nil
    end
    ]]

    --Do all the checks for the "automatic mark item as set"
    local function automaticMarkingSetsCheckFunc(p_bagId, p_slotIndex)
        --Todo DEBUG: Change to "false" after debugging!
        local isDebuggingCase = false
        --[[
        if p_bagId == 1 and p_slotIndex == 26 then
            d("[FCOIS]automaticMarkingSetsCheckFunc: " .. gil(p_bagId, p_slotIndex))
            isDebuggingCase = true
        end
        ]]

        --First check if the item is a special item like the Maelstrom weapon or shield, or The Master's weapon
        local isSpecialItem = checkIfIsSpecialItem(p_bagId, p_slotIndex)

        --The 2nd return parameter contains a variable called "noFurtherChecksNeeded" = true then!
        local retDataNoFurtherChecksNeeded = {}
        retDataNoFurtherChecksNeeded["noFurtherChecksNeeded"] = false

        --Check if the item needs a set collection book marker icon
        --[[
        local wasMarkedForSetItemCollectionBook = automaticMarkingSetsCollectionBookCheckFunc(p_bagId, p_slotIndex)
        if wasMarkedForSetItemCollectionBook == true then
            --Shall we stop here (see 9 lines below) at some circumstances?
            --isSpecialItem = true
        end
        ]]

        --Was the item crafted and the automatic "crafted" marker icon was set already, then abort here and do not set the "set" marker icon
        --if checkIfAutomaticCraftedMarkerIconIsSet() then return false end
        if isDebuggingCase then d("[FCOIS] automaticMarkingSetsCheckFunc - > go on...") end

        --if the item is special it should be automatically marked as a set part, without any further checks!
        if isSpecialItem == true then
            retDataNoFurtherChecksNeeded["noFurtherChecksNeeded"] = true
            return true, retDataNoFurtherChecksNeeded
        end

        --Check if item is a set part with the wished trait
        local isSetPartWithWishedTrait, isSetPartAndIsValidAndGotTrait, setPartTraitMarkerIcon, isSet = isItemSetPartWithTraitNoControl(p_bagId, p_slotIndex)
        if isDebuggingCase then d("[FCOIS]automaticMarkingSetsCheckFunc " .. gil(p_bagId, p_slotIndex) .. ": isSet: " .. tos(isSet) .. ", isSetPartWithWishedTrait: " .. tos(isSetPartWithWishedTrait) .. ", isSetPartAndIsValidAndGotTrait: " .. tos(isSetPartAndIsValidAndGotTrait) .. ", setPartTraitMarkerIcon: " .. tos(setPartTraitMarkerIcon)) end
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

        local isDebuggingCase = false
        markItem = markItem or FCOIS.MarkItem

        if p_itemData ~= nil and p_itemData.bagId ~= nil and p_itemData.slotIndex ~= nil then
            itemLink = gil(p_itemData.bagId, p_itemData.slotIndex)
            --Todo DEBUG: Comment again after debugging!
            --[[
            if p_itemData.bagId == BAG_BACKPACK and p_itemData.slotIndex == 25 then --Bogen des Leerenrufers
                d("[FCOIS]automaticMarkingSetsAdditionalCheckFunc: " .. itemLink)
                isDebuggingCase = true
            end
            ]]
        end
        if p_itemData.fromCheckFunc ~= nil then
            local fromCheckFunc = p_itemData.fromCheckFunc
            --Check if no further checks are needed and the item needs to be marked with the set icon
            if fromCheckFunc["noFurtherChecksNeeded"] == true then
                --Return the values "nil" and "nil" -> Needed to abort all further marker icons and chat messages now!
                --Changed on 2018-08-04 from false, nil. But until this time the first checkFunc aborted the 2nd additional checkfunc,
                --which is now always called via parameter "additionalCheckFuncForce = true" and thus the chat was spammed with Marked potion as set part...
                --d("<<aborting due to: noFurtherChecksNeeded!")
                return nil, nil
            else
                isSetPartWithWishedTrait          =  fromCheckFunc["isSetPartWithWishedTrait"]
                isSetPartAndIsValidAndGotTrait    =  fromCheckFunc["isSetPartAndIsValidAndGotTrait"]
                newMarkerIcon                     =  fromCheckFunc["newMarkerIcon"]
                --d(">>" .. itemLink .. ", isSetPartWithATrait: " .. tos(isSetPartAndIsValidAndGotTrait) .. ", isSetPartWithAWishedTrait: " .. tos(isSetPartWithWishedTrait) .. ", traitMarkerIcon: " .. tos(newMarkerIcon))
            end
        end

        local skipAllOtherChecks = false
        local nonWishedBecauseOfCharacterLevel = false
        --Local settings
        local settings = FCOIS.settingsVars.settings
        local isIconEnabled = settings.isIconEnabled
        --Do the other additonal set checks
        local itemId = p_itemData.itemId
        local isProtected = false
        local checkOtherSetMarkerIcons = false
        --Build the array with the gear set icon ids
        local iconIdArray = {}
        local gearIconIdArray = {}
        local sellIconIdArray = {}
        local setTrackerIconIdArray = {} --#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300
        --The standard automatic marker icon for the sets
        local setsIconNr = settings.autoMarkSetsIconNr
        local isMarkedWithAutomaticSetMarkerIcon
        local isSellProtected
        local isGearProtected
        local isSetTrackerAndIsMarkedWithOtherIconAlready --#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300

        --=== Non-Wished set items check for characters below level 50 =========================================================
        if settings.autoMarkSetsNonWished == true and isIconEnabled[settings.autoMarkSetsNonWishedIconNr] and settings.autoMarkSetsNonWishedIfCharBelowLevel then
            local levelToCheck = mappingVars.maxLevel --50
            --Get the actual logged in character level
            local isCharLevelAboveOrEqual = checkNeededLevel("player", levelToCheck)
            if not isCharLevelAboveOrEqual then
                if isDebuggingCase then d("[FCOIS]automaticMarkingSetsAdditionalCheckFunc, charLevelIsBelow") end
                --Check the item's level if it is below level 50
                local itemLevel = gilrl(itemLink)
                local itemRequiredCP = gilrcp(itemLink)
                local maxPossibleCPLevel = gcpppc() --API 100028 = 160
                if itemLevel < levelToCheck or (itemLevel > levelToCheck and itemRequiredCP < maxPossibleCPLevel) then
                    --Character is below level 50, so mark all set items as "Non-Wished" now
                    skipAllOtherChecks = true --Skip all other set checks now (except setting the non-wished icon!)
                    nonWishedBecauseOfCharacterLevel = true
                end
            end
        end

        --==== SET TRACKER addon integration - START ===========================================================================
        --The items will be marked via the addon "SetTracker"'s function "setLinkMarkState(_itemLink, nState, _ibag, _iindex)"
        --in file SetTracker.lua, which will call FCOItemSaver's function "oaSetTracker.updateSetTrackerMarker"
        --in file FCOIS_OtherAddons.lua as the inventories are scanned!
        ---> So these automatic checks are done "later" !
        if not skipAllOtherChecks then
            isSetTrackerAndIsMarkedWithOtherIconAlready = false
            --#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300
            if SetTrack and SetTrack.GetMaxTrackStates and oaSetTracker.isActive and settings.autoMarkSetTrackerSets then
                if isDebuggingCase then d(">check SetTracker addon") end
                --If the option is enabled to check for all marker icons before checking SetTracker set icons:
                --If the set part is alreay marked with any of the marker icons it shouldn't be marked with another SetTracker set marker icon again
                if settings.autoMarkSetTrackerSetsCheckAllIcons then
                    for iconNr = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        tins(setTrackerIconIdArray, iconNr)
                    end
                    if setTrackerIconIdArray ~= nil and #setTrackerIconIdArray > 0 then
                        isSetTrackerAndIsMarkedWithOtherIconAlready = checkIfItemArrayIsProtected(setTrackerIconIdArray, itemId) or false
                    end
                end
                --If the option is enabled to check for all SetTracker set icons:
                --If the set part is alreay marked with any of the SetTracker set icons it shouldn't be marked with another set marker icon again.
                --If the option is enabled that the SetTracker marker should not be set if any other marker is already set this will be skipped too!
                if not isSetTrackerAndIsMarkedWithOtherIconAlready and settings.autoMarkSetsCheckAllSetTrackerIcons then
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
                            if setTrackerTrackingIcon ~= nil and setTrackerTrackingIcon ~= FCOIS_CON_ICON_NONE then
                                tins(setTrackerIconIdArray, setTrackerTrackingIcon)
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
            --Check if the item is marked with the automatic set icon already
            --tins(iconIdArray, setsIconNr)
            isMarkedWithAutomaticSetMarkerIcon = checkIfItemIsProtected(setsIconNr, itemId) or false
            --==== Normal set marker icon - END ====================================================================================

            --==== Gear marker icons - BEGIN =======================================================================================
            --If the option is enabled to check for all gear set icons: If the set part is alreay marked with
            --any of the gear set icons it shouldn't be marked with another set marker icon again
            isGearProtected = false
            if settings.autoMarkSetsCheckAllGearIcons == true then
                --d(">check all gear icons")
                --Set the variable to check other icons
                checkOtherSetMarkerIcons = true
                --Add the gear set icons now
                local iconIsGear = settings.iconIsGear
                for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                    --Check if icon is a gear set icon and if it's enabled
                    if iconIsGear[i] then
                        tins(gearIconIdArray, i)
                    end
                end
                if gearIconIdArray ~= nil and #gearIconIdArray > 0 then
                    isGearProtected = checkIfItemArrayIsProtected(gearIconIdArray, itemId)
                end
                --d(">isGearProtected: " .. tos(isGearProtected))
            end
            --==== Gear marker icons - END =========================================================================================

            --==== Sell marker icons - BEGIN =======================================================================================
            --If the option is enabled to check for sell and sell in guild store icons: If the set part is already marked with
            --any of them it shouldn't be marked with another set marker icon again
            isSellProtected = false
            if settings.autoMarkSetsCheckSellIcons == true and (isIconEnabled[FCOIS_CON_ICON_SELL] or isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE]) then
                --d(">check sell icons")
                --Set the variable to check other icons
                checkOtherSetMarkerIcons = true
                if isIconEnabled[FCOIS_CON_ICON_SELL] then
                    tins(sellIconIdArray, FCOIS_CON_ICON_SELL)
                end
                if isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] then
                    tins(sellIconIdArray, FCOIS_CON_ICON_SELL_AT_GUILDSTORE)
                end
                if sellIconIdArray ~= nil and #sellIconIdArray > 0 then
                    isSellProtected = checkIfItemArrayIsProtected(sellIconIdArray, itemId)
                end
                --d(">isSellProtected: " .. tos(isSellProtected))
            end
            --==== Sell marker icons - END =========================================================================================

            --==== Is item protected check - BEGIN =================================================================================
            --Check other set marker icons too? Or only the normal one
            if isDebuggingCase then d(">isSetTrackerAndIsMarkedWithOtherIconAlready: " .. tos(isSetTrackerAndIsMarkedWithOtherIconAlready)) end
            local checkOnlySetMarkerIcon = false
            if checkOtherSetMarkerIcons == true then
                if isDebuggingCase then d(">checkOtherSetMarkerIcons: true") end
                if iconIdArray ~= nil and #iconIdArray > 0 then
                    --Check all the marker icons in the table iconIdArray
                    local isItemArrayProtected = checkIfItemArrayIsProtected(iconIdArray, itemId)
                    isProtected = isSetTrackerAndIsMarkedWithOtherIconAlready or isGearProtected or isSellProtected or isItemArrayProtected
                    if isDebuggingCase then d(">isSetTrackerAndIsMarkedWithOtherIconAlready: " ..tos(isSetTrackerAndIsMarkedWithOtherIconAlready) .. ", isGearProtected: " ..tos(isGearProtected) .. ", isSellProtected: " ..tos(isSellProtected) .. ", isItemArrayProtected: " ..tos(isItemArrayProtected)) end
                else
                    checkOnlySetMarkerIcon = true
                    if isDebuggingCase then d(">checkOnlySetMarkerIcon: true") end
                end
            else
                checkOnlySetMarkerIcon = true
                if isDebuggingCase then d(">checkOnlySetMarkerIcon 2: true") end
            end
            if checkOnlySetMarkerIcon then
                --Only check the automatic sets marker icon
                isProtected = (isSetTrackerAndIsMarkedWithOtherIconAlready or isGearProtected or isSellProtected or isMarkedWithAutomaticSetMarkerIcon) or false
                if isDebuggingCase then d(">isSetTrackerAndIsMarkedWithOtherIconAlready: " ..tos(isSetTrackerAndIsMarkedWithOtherIconAlready) .. ", isGearProtected: " ..tos(isGearProtected) .. ", isSellProtected: " ..tos(isSellProtected) .. ", isMarkedWithAutomaticSetMarkerIcon: " ..tos(isMarkedWithAutomaticSetMarkerIcon)) end
            end
            if not isProtected then isProtected = false end
            --==== Is item protected check - END ===================================================================================


        end --if not skipAllOtherChecks then


        --==== Trait & non-wished trait checks - BEGIN =========================================================================
        --The item is not marked with any marker icon yet and it's not protected
        --> then check for non wished item traits
        if isDebuggingCase then d("> isProtected: " .. tos(isProtected)) end
        local markWithNonWishedIcon = false
        local markWithNonWishedSellIcon = false
        if isProtected == false or nonWishedBecauseOfCharacterLevel == true then
            ------------------------------------------------------------------------------------------------------------------
            -- NON WISHED ITEM TRAIT CHECK - BEGIN
            -- Check if item is a set part with the wished trait and skip the "all marker icons check"!
            -- Is the item a set part, is valid and got a non-wished trait, and should be marked with a non-wished marker icon?
            ------------------------------------------------------------------------------------------------------------------
            local nonWishedLevelFound = false
            local nonWishedQualityFound = false
            if (isSetPartWithWishedTrait == false or nonWishedBecauseOfCharacterLevel == true)
                    and settings.autoMarkSetsNonWished and isIconEnabled[settings.autoMarkSetsNonWishedIconNr] then

                if isDebuggingCase then d(">non wished item trait check") end
                if not nonWishedBecauseOfCharacterLevel then
                    local autoMarkSetsNonWishedChecks = settings.autoMarkSetsNonWishedChecks

                    local autoMarkSetsNonWishedChecksAllEnabled = (autoMarkSetsNonWishedChecks == FCOIS_CON_NON_WISHED_ALL) or false
                    local autoMarkSetsNonWishedChecksAnyEnabled = (autoMarkSetsNonWishedChecks == FCOIS_CON_NON_WISHED_ANY_OF_THEM) or false --bug #228
                    local autoMarkSetsNonWishedChecksTraitEnabled = (autoMarkSetsNonWishedChecks == FCOIS_CON_NON_WISHED_TRAIT) or false --bug #228
                    local doNonWishedQualityCheck   = (autoMarkSetsNonWishedChecksAllEnabled or autoMarkSetsNonWishedChecksAnyEnabled or autoMarkSetsNonWishedChecks==FCOIS_CON_NON_WISHED_QUALITY) or false
                    local doNonWishedLevelCheck     = (autoMarkSetsNonWishedChecksAllEnabled or autoMarkSetsNonWishedChecksAnyEnabled or autoMarkSetsNonWishedChecks==FCOIS_CON_NON_WISHED_LEVEL) or false

                    if isDebuggingCase then d(">all: " ..tos(autoMarkSetsNonWishedChecksAllEnabled) .. ", any: " ..tos(autoMarkSetsNonWishedChecksAnyEnabled) .. ", trait: " ..tos(autoMarkSetsNonWishedChecksTraitEnabled) .. ", quality: " ..tos(doNonWishedQualityCheck) .. ", level: " ..tos(doNonWishedLevelCheck)) end

                    --Do we need to simulate the normal trait checks, no quality/level, because the "detail" settings are disabled
                    --at quality/level?
                    if not autoMarkSetsNonWishedChecksTraitEnabled then
                        --Level check and quality check are enabled due to the ALL/ANY checks enabled selection,
                        --but both are set to "Disabled" within the detail dropdown box?
                        if autoMarkSetsNonWishedChecksAllEnabled == true
                                and (
                                settings.autoMarkSetsNonWishedLevel == 1    --Disabled--
                                        and settings.autoMarkSetsNonWishedQuality == 1  --Disabled--
                        ) then
                            --Simulate normal trait check "only"
                            autoMarkSetsNonWishedChecksTraitEnabled = true
                        end
                    else
                        --Do ALL or ANY checks? Then disable only trait base check
                        if autoMarkSetsNonWishedChecksAllEnabled == true or autoMarkSetsNonWishedChecksAnyEnabled == true then
                            autoMarkSetsNonWishedChecksTraitEnabled = false
                        end
                    end

                    if isDebuggingCase then d(">setPartValidWithTrait: " ..tos(isSetPartAndIsValidAndGotTrait) .. ", trait: " ..tos(autoMarkSetsNonWishedChecksTraitEnabled)) end

                    if isSetPartAndIsValidAndGotTrait == true then
                        --Only check the wished trait? Skip the other checks below then, except if ALL checks need to be done
                        if not autoMarkSetsNonWishedChecksTraitEnabled then
                            --If the item is a s set part "Check the item's level" is activated?
                            if doNonWishedLevelCheck == true then
                                if settings.autoMarkSetsNonWishedLevel ~= 1 then
                                    local levelMapping = mappingVars.levels
                                    local CPlevelMapping = mappingVars.CPlevels
                                    local level2Threshold = mappingVars.levelToThreshold
                                    local allLevels = mappingVars.allLevels
                                    if levelMapping ~= nil and CPlevelMapping ~= nil and itemLink ~= nil and level2Threshold ~= nil and allLevels ~= nil then
                                        local levelThreshold = ton(level2Threshold[tos(allLevels[settings.autoMarkSetsNonWishedLevel])]) or 0
                                        if levelThreshold ~= nil and levelThreshold > 0  then
                                            --Get the item level and champion rank
                                            local requiredLevel = gilrl(itemLink)
                                            local requiredCPRank = gilrcp(itemLink)
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
                                    --    local _, _, _, equipType = gili(itemLink)
                                    --    if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
                                    --        markWithNonWishedIcon = false
                                    --        markWithNonWishedSellIcon = true
                                    --    end
                                    --end
                                    --end
                                else
                                    --Level check is set to disabled at the detail dropdown -> Simulate the level check as successfull
                                    nonWishedLevelFound = true
                                end
                                if isDebuggingCase then d("[FCOIS]>level check: " ..tos(nonWishedLevelFound)) end
                            end -- Non wished item level checks

                            --Quality checks
                            if doNonWishedQualityCheck == true then
                                if settings.autoMarkSetsNonWishedQuality ~= 1 then
                                    --Check the item's quality to mark it with the chosen non-wished icon, or the sell icon?
                                    if isDebuggingCase then d(">> non-wished quality check! Non-wished quality: " .. tos(settings.autoMarkSetsNonWishedQuality)) end
                                    --Check the item's quality now
                                    local itemQuality = getItemQuality(p_itemData.bagId, p_itemData.slotIndex)
                                    if itemQuality ~= false then
                                        nonWishedQualityFound = (itemQuality <= settings.autoMarkSetsNonWishedQuality) or false
                                        --d("Quality: " .. tos(itemQuality) .. ", check: " .. tos(qualityCheck))
                                        --Is the quality higher or equals the non-wished quality from the settings?
                                        --if qualityCheck then
                                        --else
                                        --    --Mark with the sell icon
                                        --    markWithNonWishedIcon = false
                                        --    markWithNonWishedSellIcon = true
                                        --end
                                    end
                                else
                                    --Quality check is set to disabled at the detail dropdown -> Simulate the quality check as successfull
                                    nonWishedQualityFound = true
                                end
                                if isDebuggingCase then d("[FCOIS]>quality check: " ..tos(nonWishedQualityFound)) end
                            end
                        else
                            if isDebuggingCase then d("[FCOIS]>trait check") end
                        end --only check wished-trait
                    end --isSetPartAndIsValidAndGotTrait

                    local levelCheckSuccessfull =   (doNonWishedLevelCheck == true and nonWishedLevelFound == true and true) or false
                    local qualityCheckSuccessfull = (doNonWishedQualityCheck == true and nonWishedQualityFound == true and true) or false

                    if isDebuggingCase then d(">levelCheck: " ..tos(levelCheckSuccessfull) .. ", qualityCheck: " ..tos(qualityCheckSuccessfull)) end

                    --Was a level or quality or both combined found, matching to the non-wished settings?
                    if ( autoMarkSetsNonWishedChecksTraitEnabled == true and isSetPartAndIsValidAndGotTrait == true ) -- Only trait check
                            or ( autoMarkSetsNonWishedChecksAnyEnabled == true and (levelCheckSuccessfull == true or qualityCheckSuccessfull == true) )  --Any check
                            or ( autoMarkSetsNonWishedChecksAllEnabled == true and (levelCheckSuccessfull == true and qualityCheckSuccessfull == true) ) --All checks in combination
                            or (not autoMarkSetsNonWishedChecksAnyEnabled and not autoMarkSetsNonWishedChecksAllEnabled and (levelCheckSuccessfull == true or qualityCheckSuccessfull == true)) --Level or quality
                    then
                        if isDebuggingCase then d(">NonWishedCheck: Quality, level, trait, or all") end
                        markWithNonWishedIcon       = true
                        markWithNonWishedSellIcon   = false
                    else
                        if isDebuggingCase then d(">NonWishedCheck: No non-wished found!") end
                        markWithNonWishedIcon       = false
                        markWithNonWishedSellIcon   = false
                        if settings.autoMarkSetsNonWishedSellOthers and isIconEnabled[FCOIS_CON_ICON_SELL] then
                            if isDebuggingCase then d(">NonWishedCheck: Mark non-wished with sell icon") end
                            --Don't do quality checks -> Mark with the non-wished icon
                            markWithNonWishedIcon       = false
                            markWithNonWishedSellIcon   = true
                        end
                    end
                else
                    if isDebuggingCase then d(">NonWishedCheck: Because of char level") end
                    --No other checks were needed and we need to mark the setItem with the non-wished marker icon now
                    --as the character is below level 50 and the setting to mark then as non-wished is enabled
                    markWithNonWishedIcon = true
                end --if not nonWishedBecauseOfCharacterLevel then

                --Mark with the non-wished icon now?
                if markWithNonWishedIcon == true or markWithNonWishedSellIcon == true then
                    if isDebuggingCase then d("<<<Marking with NonWished(Sell)Icon now!") end
                    local nonWishedMarkerIcon
                    if markWithNonWishedIcon == true then
                        nonWishedMarkerIcon = settings.autoMarkSetsNonWishedIconNr
                    elseif markWithNonWishedSellIcon == true then
                        nonWishedMarkerIcon = FCOIS_CON_ICON_SELL
                    end
                    --FCOIS.MarkItem - Mark the item now
                    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                    markItem(p_itemData.bagId, p_itemData.slotIndex, nonWishedMarkerIcon, true, true)
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
                if isDebuggingCase then d(">>>Trait marking checks start") end
                --Check if any other marker icon can be set
                if settings.autoMarkSetsWithTraitCheckAllIcons and not isMarkedWithAutomaticSetMarkerIcon then
                    local isMarkedWithAnyOtherIcon = false
                    local allMarkerIconsArray = {}
                    for iconNr = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        if iconNr ~= setsIconNr then
                            tins(allMarkerIconsArray, iconNr)
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
            if isDebuggingCase then d(">>>markWithTraitIcon: " .. tos(markWithTraitIcon)) end
            --if newMarkerIcon == nil then
            --    d(">markWithTraitIcon " .. tos(markWithTraitIcon) .. ": markWithNonWishedIcon " .. tos(markWithNonWishedIcon) .. ", markWithNonWishedSellIcon " .. tos(markWithNonWishedSellIcon) ..
            --        ", isMarkedWithAutomaticSetMarkerIcon " .. tos(isMarkedWithAutomaticSetMarkerIcon) .. ", settings.autoMarkSetsWithTraitIfAutoSetMarked " .. tos(settings.autoMarkSetsWithTraitIfAutoSetMarked))
            --    if itemLink ~= nil then
            --        d(">Itemlink: " ..tos(itemLink))
            --    else
            --        d(">Itemlink is missing!")
            --    end
            --end
            if markWithTraitIcon then
                --FCOIS.MarkItem - Mark the item with the trait marker icon now
                FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                markItem(p_itemData.bagId, p_itemData.slotIndex, newMarkerIcon, true, true)
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
        --TODO DEBUG: Debugging added with FCOIS v2.0.0, change to "true" to debug and define "il" and items to debug below at --TODO: Comment after debugging!
        local doDebug = false -- ((bag == BAG_BACKPACK and (scanType == "setItemCollectionsUnknown" or scanType == "setItemCollectionsKnown")) and true) or false
        local il

        markItem = markItem or FCOIS.MarkItem

        --TODO DEBUG: Comment after debugging!
        --il = gil(bag, slot)
        if doDebug then
            d("FCOIS]scanInventoryItemForAutomaticMarks-" .. il .. ", bag: " ..tos(bag) .. ", slot: " ..tos(slot) .. ", scanType: " .. tos(scanType) .. ", doOverride: " .. tos(doOverride))
        end
        --------------------------------------------------------------------------------
        --					Function starts											  --
        --------------------------------------------------------------------------------
        --Local return variables for the subfunction
        local checksWereDone			 = false
        local atLeastOneMarkerIconWasSet = false

        local settings = FCOIS.settingsVars.settings

        local function abortChecksNow(whereWasTheFunctionAborted)
            --For debugging only:
            --TODO DEBUG: For debugging the doDebug variable is used here too (change it above)
            local specialCaseMet = doDebug

            if settings.debug == true or specialCaseMet == true then
                if whereWasTheFunctionAborted then
                    whereWasTheFunctionAborted = " " .. tos(whereWasTheFunctionAborted)
                end
                debugMessage( "[ScanInvForAutomaticMarks]", strformat(tos(scanType) .. ": Aborting!%s", tos(whereWasTheFunctionAborted)), true, FCOIS_DEBUG_DEPTH_NORMAL)
                if specialCaseMet == true then
                    d( strformat("[ScanInvForAutomaticMarks]" .. tos(scanType) .. ": Aborting!%s", tos(whereWasTheFunctionAborted)) )
                end
            end
            return false, false
        end

        --------------------------------------------------------------------------------
        --Check only one bag & slot, or a whole inventory?
        if bag ~= nil and slot ~= nil then
            --Are the TO DOs given?
            if toDos == nil then return abortChecksNow("ToDos are nil!") end
            --d(">Todos found")

            --Check only one item slot
            --Is the inventory already scanned currently?
            if FCOIS.preventerVars.gScanningInv then
                --d("<<<!!! Aborting inv. scan. Scan already active - bag: " .. tos(bag) .. ", slot: " .. tos(slot) .. " scanType: " .. tos(scanType) .. " !!!>>>")
                return abortChecksNow("Scanning inv already")
            end
            local itemLink
            FCOIS.preventerVars.gScanningInv = true

            --------------------------------------------------------------------------------
            --					Execute the TODOs now									  --
            --------------------------------------------------------------------------------
            --1) Icon check 1
            --Check if the marker icon is given and enabled
            if toDos.icon ~= nil and settings.isIconEnabled[toDos.icon] then
                if doDebug then d(">Active icon found for '" .. tos(scanType) .. "': " .. tos(toDos.icon)) end
            else
                if doDebug then d(">No icon provided, determining it later again via the check and additionalCheckFunc!") end
            end

            local forceAdditionalCheckFunc = false
            --2) Settings enabled?
            --Check if the settings to automatically mark the item is enabled
            local checkResult
            if toDos.check ~= nil then
                if type(toDos.check) == "function" then
                    checkResult = toDos.check(bag, slot)
                else
                    checkResult = toDos.check
                end
                if doDebug then
                    d(">Check active: " .. tos(checkResult) .. " (" .. tos(toDos.result) .. "/" .. tos(toDos.resultNot) .. ")")
                end
                --Result should equal the check variable
                if toDos.result ~= nil then
                    --Result does NOT equal check variable -> abort
                    if checkResult ~= toDos.result then return abortChecksNow("Check value " .. tos(checkResult) .. " <> result " .. tos(toDos.result)) end
                    --Result should NOT equal the check variable
                elseif toDos.resultNot ~= nil then
                    --Result equals check variable -> abort
                    if checkResult == toDos.resultNot then return abortChecksNow("Check value " .. tos(checkResult) .. " <> result NOT " .. tos(toDos.resultNot)) end
                else
                    --No expected result given? Abort
                    return abortChecksNow("No expected result given")
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
                if doDebug then
                    d(">Other addons active: " .. tos(checkOtherAddonResult) .. " (" .. tos(toDos.resultOtherAddon) .. "/" .. tos(toDos.resultNotOtherAddon) .. ")")
                end
                --Result should equal the other addons check variable
                if toDos.resultOtherAddon ~= nil then
                    --Result does NOT equal other addons check variable -> abort
                    if checkOtherAddonResult ~= toDos.resultOtherAddon then return abortChecksNow("Check other addon value " .. tos(checkOtherAddonResult) .. " <> result other addon value " .. tos(toDos.resultOtherAddon)) end
                    --Result should NOT equal the other addons check variable
                elseif toDos.resultNotOtherAddon ~= nil then
                    --Result equals other addons check variable -> abort
                    if checkOtherAddonResult == toDos.resultNotOtherAddon then return abortChecksNow("Check other addon value " .. tos(checkOtherAddonResult) .. " <> result NOT other addon value" .. tos(toDos.resultNotOtherAddon)) end
                else
                    --No expected result given? Abort
                    return abortChecksNow("No expected other addon result given")
                end
            end

            --4) Run the preCheckFunc (if asked for) to see if the item should be scanned for the scanType
            --The variable for the pre check function result
            local preCheckFuncResult = false
            --The variable tha can be returned from the preCheckFunc as 2nd parameter: The new icon that should be used to mark the icon, instead of the todos.IconId
            local preCheckFuncResultData
            if toDos.preCheckFunc ~= nil then
                if type(toDos.preCheckFunc) == "function" then
                    --The pre-check is a function, so call it with the bagId and slotIndex
                    preCheckFuncResult, preCheckFuncResultData = toDos.preCheckFunc(bag, slot)
                else
                    --The check is no function but a variable
                    preCheckFuncResult = toDos.preCheckFunc
                end
                if doDebug then
                    d(">Pre-Check func active: " .. tos(preCheckFuncResult) .. " (" .. tos(toDos.resultPreCheckFunc) .. "/" .. tos(toDos.resultNotPreCheckFunc) .. ")")
                end
                --Was the check successfull?
                if preCheckFuncResult == nil then return abortChecksNow("Pre-CheckFuncResult is nil!") end
                if toDos.resultPreCheckFunc ~= nil then
                    --Result does NOT equal check func result -> abort
                    if preCheckFuncResult ~= toDos.resultPreCheckFunc then return abortChecksNow("Pre-CheckFunc " .. tos(preCheckFuncResult) .. " <> Pre-CheckFuncResult " .. tos(toDos.resultPreCheckFunc)) end
                    --Result should NOT equal the check func result
                elseif toDos.resultNotPreCheckFunc ~= nil then
                    --Result equals check func result -> abort
                    if preCheckFuncResult == toDos.resultNotPreCheckFunc then return abortChecksNow("Pre-CheckFunc " .. tos(preCheckFuncResult) .. " <> NOT Pre-CheckFuncResult " .. tos(toDos.resultNotPreCheckFunc)) end
                else
                    --No expected result given? Abort
                    return abortChecksNow("Pre-Check func or result not used")
                end
            end

            --5) Build the itemInstanceId and check if the item is protected already, and
            --	  if the item can be automatically marked
            --The variable for the check function result
            local checkFuncResult = false
            --The table that can be returned from the checkFunc as 2nd parameter: The table could contain a newMarkerIcon entry for the new icon that should be used to mark the icon, instead of the todos.IconId
            local checkFuncResultData
            --The variable for the additional check function result
            local additionalCheckFuncResult = false
            --The variable tha can be returned from the additionalCheckFunc as 2nd parameter: The new icon that should be used to mark the icon, instead of the todos.IconId
            local additionalCheckFuncResultData
            --The item's instance iD
            local itemId
            itemId = myGetItemInstanceIdNoControl(bag, slot, false)
            --Is the itemInstanceId/uniqueId not given,
            --or the item cannot be automatically marked (anymore),
            --  or the item is already marked with the wished icon
            --  or the item is already marked with any icon, if enabled to be checked
            local isItemProtected = true
            local canBeAutomaticallyMarked = true
            local iconIsMarkedAllreadyAllowed = (toDos.iconIsMarkedAllreadyAllowed ~= nil and toDos.iconIsMarkedAllreadyAllowed) or false
            if itemId ~= nil then
                canBeAutomaticallyMarked = checkIfCanBeAutomaticallyMarked(bag, slot, itemId, scanType)
                if canBeAutomaticallyMarked == true then
                    if toDos.checkIfAnyIconIsMarkedAlready ~= nil and toDos.checkIfAnyIconIsMarkedAlready == true then
                        local iconIdArray = {}
                        local doAddIconNow = false
                        for iconNr = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                            doAddIconNow = true
                            if iconIsMarkedAllreadyAllowed and iconNr == toDos.icon then doAddIconNow = false end
                            if doAddIconNow then
                                tins(iconIdArray, iconNr)
                            end
                        end
                        isItemProtected = checkIfItemArrayIsProtected(iconIdArray, itemId)
                    else
                        if not iconIsMarkedAllreadyAllowed then
                            isItemProtected = checkIfItemIsProtected(toDos.icon, itemId)
                        else
                            isItemProtected = false
                        end
                    end
                end
            end
            if itemId == nil or not canBeAutomaticallyMarked or isItemProtected	then
                if doDebug then
                    if not il then
                        il = gil(bag, slot)
                    end
                    d("<-- ABORTED [".. il .. "] - ItemId: " .. tos(itemId) .. ", scanType: " .. tos(scanType) .. ", checkIfItemIsProtected: " .. tos(isItemProtected) .. " -> Should be: false, checkIfCanBeAutomaticallyMarked: (" .. tos(canBeAutomaticallyMarked) .." -> Should be: true)")
                end
                return abortChecksNow("ItemId nil?: " .. tos(itemId) .. ", canBeAutomaticallyMarked false/nil?: " .. tos(canBeAutomaticallyMarked) .. ", isItemProtected true?: " .. tos(isItemProtected))
            end

            --6) Check function needs to be run?
            if toDos.checkFunc ~= nil then
                if type(toDos.checkFunc) == "function" then
                    --The check is a function, so call it with the bagId and slotIndex
                    --The result will be a boolean value, and the 2nd return parameter is a table containing addiitonal info for the following "additional" checkFuncs
                    checkFuncResult, checkFuncResultData = toDos.checkFunc(bag, slot, preCheckFuncResultData)
                else
                    --The check is no function but a variable
                    checkFuncResult = toDos.checkFunc
                end
                --Is the additionalCheckFunc foced to be executed?
                if toDos.additionalCheckFuncForce ~= nil then
                    if type(toDos.additionalCheckFuncForce) == "function" then
                        forceAdditionalCheckFunc = toDos.additionalCheckFuncForce(bag, slot, checkFuncResultData)
                    elseif  type(toDos.additionalCheckFuncForce) == "boolean" then
                        forceAdditionalCheckFunc = toDos.additionalCheckFuncForce
                    else
                        forceAdditionalCheckFunc = true
                    end
                end
                if doDebug then
                    d(">Check func active: " .. tos(checkFuncResult) .. " (" .. tos(toDos.resultCheckFunc) .. "/" .. tos(toDos.resultNotCheckFunc) .. "), forceAdditionalCheckFunc: " .. tos(forceAdditionalCheckFunc))
                end
                --Was the check successfull?
                if checkFuncResult == nil and not forceAdditionalCheckFunc then return abortChecksNow("CheckFuncResult is nil and no force to go on is active!") end
                --Result should equal the check func result
                if not forceAdditionalCheckFunc then
                    if toDos.resultCheckFunc ~= nil then
                        --Result does NOT equal check func result -> abort
                        if checkFuncResult ~= toDos.resultCheckFunc then return abortChecksNow("CheckFunc " .. tos(checkFuncResult) .. " <> CheckFuncResult " .. tos(toDos.resultCheckFunc)) end
                        --Result should NOT equal the check func result
                    elseif toDos.resultNotCheckFunc ~= nil then
                        --Result equals check func result -> abort
                        if checkFuncResult == toDos.resultNotCheckFunc then return abortChecksNow("CheckFunc " .. tos(checkFuncResult) .. " <> NOT CheckFuncResult " .. tos(toDos.resultNotCheckFunc)) end
                    else
                        --No expected result given? Abort
                        return abortChecksNow("Check func or result not used")
                    end
                    --Result was okay, so check if we need to go on with marker icon etc.
                    -->Only if the icon to be marked was not provided. The checkFunc needs to mark the item then and we abort here if this was done!
                    if toDos.checkFuncMarksItem ~= nil and toDos.icon == nil then
                        local checkFuncMarksItemResult
                        if type(toDos.checkFuncMarksItem) == "function" then
                            checkFuncMarksItemResult = toDos.checkFuncMarksItem(bag, slot)
                        else
                            checkFuncMarksItemResult = toDos.checkFuncMarksItem
                        end
                        if checkFuncMarksItemResult == true then
                            return abortChecksNow("Check func marked the item already")
                        end
                    end
                end
            end

            --7) Additional check function should be executed?
            if toDos.additionalCheckFunc ~= nil then
                if type(toDos.additionalCheckFunc) == "function" then
                    --Build the itemData table for the checkfunc
                    local itemData
                    itemData = {}
                    itemData.bagId		= bag
                    itemData.slotIndex	= slot
                    itemData.itemId		= itemId
                    itemData.scanType	= scanType
                    --if checkFuncResultData ~= nil then
                    itemData.fromCheckFunc = nil
                    if checkFuncResultData ~= nil then
                        itemData.fromCheckFunc = checkFuncResultData
                    elseif preCheckFuncResultData ~= nil then
                        itemData.fromCheckFunc = preCheckFuncResultData
                    end
                    --end
                    if itemData == nil then return abortChecksNow("Additional check func, itemdata is nil!") end
                    --The check is a function, so call it with the itemData table and the current check func result variable
                    additionalCheckFuncResult, additionalCheckFuncResultData = toDos.additionalCheckFunc(itemData, checkFuncResult)
                else
                    --The check is no function but a variable
                    additionalCheckFuncResult = toDos.additionalCheckFunc
                end
                if doDebug then
                    d(">Add. check func active: " .. tos(additionalCheckFuncResult) .. " (" .. tos(toDos.resultAdditionalCheckFunc) .. "/" .. tos(toDos.resultNotAdditionalCheckFunc) .. ")")
                end
                --Was the check successfull?
                if additionalCheckFuncResult == nil then return abortChecksNow("Additional check func result is nil!") end
                --Result should equal the add. check func result
                if toDos.resultAdditionalCheckFunc ~= nil then
                    --Result does NOT equal add. check func result -> abort
                    if additionalCheckFuncResult ~= toDos.resultAdditionalCheckFunc then return abortChecksNow("Additional check func " .. tos(additionalCheckFuncResult) .. " <> Additional check func result " .. tos(toDos.resultAdditionalCheckFunc)) end
                    --Result should NOT equal the add. check func result
                elseif toDos.resultNotAdditionalCheckFunc ~= nil then
                    --Result equals add. check func result -> abort
                    if additionalCheckFuncResult == toDos.resultNotAdditionalCheckFunc then return abortChecksNow("Additional check func " .. tos(additionalCheckFuncResult) .. " <> NOT Additional check func result " .. tos(toDos.resultNotAdditionalCheckFunc)) end
                else
                    --No expected result given? Abort
                    return abortChecksNow("Additional check func or result not given!")
                end
            end

            --8) Icon check 2
            --Check if the marker icon is given and enabled
            local additionalCheckFuncResultDataNewMarkerIcon = (additionalCheckFuncResultData ~= nil and additionalCheckFuncResultData.newMarkerIcon ~= nil and additionalCheckFuncResultData.newMarkerIcon) or nil
            local checkFuncResultDataNewMarkerIcon = (checkFuncResultData ~= nil and checkFuncResultData.newMarkerIcon ~= nil and checkFuncResultData.newMarkerIcon) or nil
            if not toDos.icon then
                --is the icon not given but the return table of the additionalCheckFunc provided an alternative icon?
                local abortCuzOfNoIcon = true
                if additionalCheckFuncResultDataNewMarkerIcon ~= nil then
                    abortCuzOfNoIcon = false
                    if doDebug then
                        d(">Active icon not given/Not enabled, but using additionalCheckFuncResultData.newMarkerIcon for '" .. tos(scanType) .. "': " .. tos(additionalCheckFuncResultData.newMarkerIcon))
                    end
                else
                    --is the icon not given but the return table of the checkFunc provided an alternative icon?
                    if checkFuncResultDataNewMarkerIcon ~= nil then
                        abortCuzOfNoIcon = false
                        if doDebug then
                            d(">Active icon no given/Not enabled, but using checkFuncResult.newMarkerIcon for '" .. tos(scanType) .. "': " .. tos(checkFuncResultData.newMarkerIcon))
                        end
                    end
                end
                if abortCuzOfNoIcon == true then
                    return abortChecksNow("Icon not given/not enabled in (additional)checkFuncResultData: " .. tos(toDos.icon))
                end
            end

            --Compare the two 2nd parameters (new marker icon IDs) of checkFunc and additionalCheckFunc.
            --Use the later one returned that is not nil as the new marker icon for the item
            local newMarkerIcon
            if toDos.icon ~= nil then
                if type(toDos.icon) == "function" then
                    newMarkerIcon = toDos.icon(bag, slot)
                else
                    newMarkerIcon = toDos.icon
                end
                if doDebug then
                    d(">newMarkerIcon taken from todos.icon")
                end
            end
            if additionalCheckFuncResultDataNewMarkerIcon ~= nil then
                if doDebug then
                    d(">newMarkerIcon taken from add. check func newMarkerIcon")
                end
                newMarkerIcon = additionalCheckFuncResultDataNewMarkerIcon
            else
                if doDebug then
                    d(">newMarkerIcon taken from check func newMarkerIcon")
                end
                if checkFuncResultDataNewMarkerIcon ~= nil then
                    newMarkerIcon = checkFuncResultDataNewMarkerIcon
                end
            end
            --Set the return variable with the info, that the checks were done for at least one item
            checksWereDone = true
            if doDebug then
                d(">Checks were done")
            end

            --9) Mark the item now
            --Item was checked and should be marked now
            --FCOIS.MarkItem(bag, slot, iconId, showIcon, updateInventories)
            FCOIS.preventerVars.gCalledFromInternalFCOIS = true
            markItem(bag, slot, newMarkerIcon, true, false)
            --Set the return variable with the info, that at least one marker icon was set
            atLeastOneMarkerIconWasSet = true

            --9) Show chat output?
            --d(">Chat output: " .. tos(toDos.chatOutput))
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
                itemLink = gil(bag, slot)
                --Show the marked item in the chat with the clickable itemLink
                if (itemLink ~= nil) then
                    d(chatBegin .. itemLink .. chatEnd)
                end
                --local scanTypeCapitalText
                --scanTypeCapitalText = zo_strf("<<C:1>>", scanType)
                --d(">scanType: " .. tos(scanType) ..", scanTypeCapital: " .. tos(scanTypeCapitalText))
            else
                --Show the marked item in the chat via debug message
                local scanTypeCapitalText
                scanTypeCapitalText = zo_strf("<<C:1>>", scanType)
                if settings.debug then debugMessage( "[ScanInventoryFor".. scanTypeCapitalText or tos(scanType) .."]", chatBegin .. itemLink .. chatEnd, false) end
            end
        end -- if bag ~= nil and slot ~= nil then
        --Return the functions return variables now
        if doDebug then
            d("<<< retun checksWereDone: " .. tos(checksWereDone) .. ", atLeastOneMarkerIconWasSet: " .. tos(atLeastOneMarkerIconWasSet))
        end
        return checksWereDone, atLeastOneMarkerIconWasSet
    end -- Single item scan function scanInventoryItemForAutomaticMarks(bag, slot, scanType)
    local scanInventoryItemForAutomaticMarks = FCOIS.scanInventoryItemForAutomaticMarks

    local function houseBankBagChecks(bagId)
        if IsHouseBankBag(bagId) == true then
            return checkIfHouseOwnerAndInsideOwnHouse()
        end
        return nil
    end

    local function getBagsToScanForAutomaticMarks(bag)
        --d("[FCOIS]getBagsToScanForAutomaticMarks - bagId: " ..tos(bagId))
        local onlyUpdatePlayerInv = true
        local bagIdsToScanNow = {}
        --Scan a dedicated bag
        if bag ~= nil then
            local houseCheckResult = houseBankBagChecks(bag)
            if houseCheckResult == true then
                tins(bagIdsToScanNow, bag)
                onlyUpdatePlayerInv = false
                --Not in an own house? No access to the own house bank then!
            elseif houseCheckResult == nil then
                tins(bagIdsToScanNow, bag)
                if bag ~= BAG_BACKPACK then
                    if bag == BAG_BANK == true then
                        tins(bagIdsToScanNow, BAG_SUBSCRIBER_BANK)
                    end
                    onlyUpdatePlayerInv = false
                end
            end

        else
            --Scan multiple bags -> Get the enbaled bags and the scan order
            local settings = FCOIS.settingsVars.settings
            local bagsToScan, bagScanOrder = ZO_ShallowTableCopy(settings.autoMarkBagsToScan), ZO_ShallowTableCopy(settings.autoMarkBagsToScanOrder)
            --FCOIS._settingsAutoMarkBagsToScan = bagsToScan
            --FCOIS._settingsAutoMarkBagsToScanOrder = bagScanOrder

            --Scan the bank? Also scan the subscriber bank than!
            if bagsToScan[BAG_BANK] == true then
                --d(">found BAG_BANK -> Adding BAG_SUBSCRIBER_BANK")
                bagsToScan[BAG_SUBSCRIBER_BANK] = true
                local insertIdx
                for scanIndex, bagData in ipairs(bagScanOrder) do
                    if bagData.value == BAG_BANK then
                        insertIdx = scanIndex + 1
                        --d(">insertIdx of BAG_SUBSCRIBER_BANK: " ..tos(insertIdx))
                        break
                    end
                end
                if insertIdx ~= nil then
                    tins(bagScanOrder, insertIdx, { value = BAG_SUBSCRIBER_BANK, uniqueKey = BAG_SUBSCRIBER_BANK, text = "BAG_SUBSCRIBER_BANK", tooltip = "BAG_SUBSCRIBER_BANK" })
                end
            end
            --House bank bag should be scanned as well?
            if bagsToScan[BAG_HOUSE_BANK_ONE] == true then
                local houseCheckResult = houseBankBagChecks(BAG_HOUSE_BANK_ONE)
                --Not in an own house? No access to the own house bank then!
                if houseCheckResult == nil then
                    bagsToScan[BAG_HOUSE_BANK_ONE] = false
                end
            end
            bagIdsToScanNow = {}
            for scanIndex, bagData in ipairs(bagScanOrder) do
                local bagValue = bagData.value
                if bagsToScan[bagValue] == true then
                    tins(bagIdsToScanNow, bagValue)
                    if bagValue ~= BAG_BACKPACK then
                        onlyUpdatePlayerInv = false
                    end
                end
            end
        end

        return bagIdsToScanNow, onlyUpdatePlayerInv
    end


    --Function to do the scans for automatic marker icons (multiple items)
    function FCOIS.ScanInventoryItemsForAutomaticMarks(bag, slot, scanType, updateInv)
        updateInv = updateInv or false
        if not scanType then return false end
        local settings = FCOIS.settingsVars.settings
        local fcoisLoc = FCOIS.localizationVars.fcois_loc
        --d("FCOIS]scanInventoryItemsForAutomaticMarks- bag: " ..tos(bag) .. ", slot: " ..tos(slot) .. ", scanType: " .. tos(scanType) .. ", updateInv: " .. tos(updateInv))
        --------------------------------------------------------------------------------
        --The table with the information "what should be done and marked how" for each scan type
        --This table contains a short scanType (e.g. "scan for unknown recipes" -> "recipes" as the key.
        --Below the key there is another table containing the information, what should be checked (check),
        --and how should it be done (result = expected result / resultNot = not expected result),
        --are there any other addons involved (checkOtherAddon),
        --and what are their expected results (resultOtherAddon, resultNotOtherAddon),
        --which marker icon of FCOIS will be used to mark the item (icon),
        --are there any check functions to be executed if result or resultNot are not the only values to compare
        --(checkFunc, resultCheckFunc, resultNotCheckFunc),
        --is after the checkFunc any other function to be called (resultAdditionalCheckFunc, resultNotAdditionalCheckFunc),
        --and should the marked item info output to the chat (chatOutput, chatBegin, chatEnd)
        local scanTypeToDo = {
            ---------------------------- Quality -----------------------------------
            ["quality"] = {
                check				= settings.autoMarkQuality,
                result 				= nil,
                resultNot			= 1,
                checkOtherAddon		= nil,
                resultOtherAddon   	= nil,
                resultNotOtherAddon	= nil,
                icon				= settings.autoMarkQualityIconNr,
                checkIfAnyIconIsMarkedAlready = settings.autoMarkQualityCheckAllIcons,
                checkFunc			= automaticMarkingQualityCheckFunc,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= true,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = true,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showQualityItemsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["quality_item_found"],
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
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is ornate
                    return isItemOrnate(p_bagId, p_slotIndex), nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showOrnateItemsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["ornate_item_found"],
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
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is intricate
                    return isItemIntricate(p_bagId, p_slotIndex), nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                chatOutput			= settings.showIntricateItemsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["intricate_item_found"],
            },
            ---------------------------- Researchable items-------------------------
            ["research"] = {
                check				= settings.autoMarkResearch,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= function()
                    return (checkIfResearchAddonUsed() and checkIfChosenResearchAddonActive()) or false
                end,
                resultOtherAddon   	= true,
                resultNotOtherAddon	= nil,
                icon				= FCOIS_CON_ICON_RESEARCH,
                checkIfAnyIconIsMarkedAlready = settings.autoMarkResearchCheckAllIcons,
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is researchable
                    local isItemResearchable, wasItemReconstructedOrRetraited = isItemResearchableNoControl(p_bagId, p_slotIndex, nil)
                    if isItemResearchable and wasItemReconstructedOrRetraited == true then
                        isItemResearchable = false
                    end
                    --d(">>>isItemResearchable: " ..tos(isItemResearchable))
                    return isItemResearchable, nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = false, --Only call the additional check func if no icon/marker was found/appliey until now!
                additionalCheckFunc = function(p_itemData, p_checkFuncResult)
                    return automaticMarkingResearchAdditionalCheckFunc(p_itemData, p_checkFuncResult), nil
                end,
                resultAdditionalCheckFunc = true,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showResearchItemsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["research_item_found"],
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
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is a researhc scroll which would be wasted, if used
                    return checkIfResearchScrollWouldBeWasted(p_bagId, p_slotIndex), nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                chatOutput			= settings.showResearchItemsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["researchScroll_item_found"],
            },
            ---------------------------- Unknown recipes ---------------------------
            ["recipes"] = {
                check				= settings.autoMarkRecipes,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= function()
                    return checkIfRecipeAddonUsed() and checkIfChosenRecipeAddonActive()
                end,
                resultOtherAddon   	= true,
                resultNotOtherAddon	= nil,
                icon				= settings.autoMarkRecipesIconNr,
                checkIfAnyIconIsMarkedAlready = nil,
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is an unknown recipe
                    return isRecipeKnown(p_bagId, p_slotIndex, false), nil
                end,
                resultPreCheckFunc  = false,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showRecipesInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["unknown_recipe_found"],
            },
            ---------------------------- Known recipes ---------------------------
            ["knownRecipes"] = {
                check				= settings.autoMarkKnownRecipes,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= function()
                    return checkIfRecipeAddonUsed() and checkIfChosenRecipeAddonActive()
                end,
                resultOtherAddon   	= true,
                resultNotOtherAddon	= nil,
                icon				= settings.autoMarkKnownRecipesIconNr,
                checkIfAnyIconIsMarkedAlready = nil,
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is a known recipe
                    return isRecipeKnown(p_bagId, p_slotIndex, true), nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showRecipesInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["known_recipe_found"],
            },
            ---------------------------- Unknown recipes ---------------------------
            ["motifs"] = { --#308
                check				= settings.autoMarkMotifs,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= function()
                    return checkIfMotifsAddonUsed() and checkIfChosenMotifsAddonActive()
                end,
                resultOtherAddon   	= true,
                resultNotOtherAddon	= nil,
                icon				= settings.autoMarkMotifsIconNr,
                checkIfAnyIconIsMarkedAlready = nil,
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is an unknown motif
                    return isMotifKnown(p_bagId, p_slotIndex, false), nil
                end,
                resultPreCheckFunc  = false,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showMotifsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["unknown_motif_found"],
            },
            ---------------------------- Known motifs ---------------------------
            ["knownMotifs"] = { --#308
                check				= settings.autoMarkKnownMotifs,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= function()
                    return checkIfMotifsAddonUsed() and checkIfChosenMotifsAddonActive()
                end,
                resultOtherAddon   	= true,
                resultNotOtherAddon	= nil,
                icon				= settings.autoMarkKnownMotifsIconNr,
                checkIfAnyIconIsMarkedAlready = nil,
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is a known motif
                    return isMotifKnown(p_bagId, p_slotIndex, true), nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= nil,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showMotifsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["known_motif_found"],
            },
            ---------------------------- Set collection items ----------------------------------
            ["setItemCollectionsUnknown"] = {
                check				= settings.autoMarkSetsItemCollectionBook,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= nil,
                resultOtherAddon   	= nil,
                resultNotOtherAddon	= nil,
                --Do not check here! Else it will abort due to not enabled icon if ONLY auto-bind is enabled. Icon will be determined in function automaticMarkingSetsCollectionBookCheckFunc and passed on
                --in returned 2nd parameter checkFuncData.newMarkerIcon
                --icon				= settings.autoMarkSetsItemCollectionBookMissingIcon,
                iconIsMarkedAllreadyAllowed = nil,
                checkIfAnyIconIsMarkedAlready = nil,
                checkFunc			= function(p_bagId, p_slotIndex)
                    return automaticMarkingSetsCollectionBookCheckFunc(p_bagId, p_slotIndex, false)
                end,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= true,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showSetCollectionMarkedInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["set_collection_part_unknown_found"],
            },
            ------------------------------------------------------------------------
            ["setItemCollectionsKnown"] = {
                check				= settings.autoMarkSetsItemCollectionBook,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= nil,
                resultOtherAddon   	= nil,
                resultNotOtherAddon	= nil,
                icon				= settings.autoMarkSetsItemCollectionBookNonMissingIcon,
                iconIsMarkedAllreadyAllowed = nil,
                checkIfAnyIconIsMarkedAlready = nil,
                checkFunc			= function(p_bagId, p_slotIndex)
                    return automaticMarkingSetsCollectionBookCheckFunc(p_bagId, p_slotIndex, true)
                end,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= true,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil,
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showSetCollectionMarkedInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["set_collection_part_known_found"],
            },
            ---------------------------- Set parts ----------------------------------
            ["sets"] = {
                check				= settings.autoMarkSets,
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= nil,
                resultOtherAddon   	= nil,
                resultNotOtherAddon	= nil,
                icon				= settings.autoMarkSetsIconNr,
                iconIsMarkedAllreadyAllowed = true,
                checkIfAnyIconIsMarkedAlready = settings.autoMarkSetsCheckAllIcons,
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is a set item
                    return isItemSetAndNotExcluded(p_bagId, p_slotIndex), nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= automaticMarkingSetsCheckFunc,
                checkFuncMarksItem  = nil,
                resultCheckFunc 	= true,
                resultNotCheckFunc 	= nil,
                --"Forced" the call of the addtional checkFunction at the automatic item marker checks
                --even if the normal checkFunc already returned a valid result/marker icon change
                additionalCheckFuncForce = true, -- force the call of the additional check func!
                additionalCheckFunc = automaticMarkingSetsAdditionalCheckFunc,
                resultAdditionalCheckFunc = false,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showSetsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["set_part_found"],
            },
            ---------------------------- LibSets Set search favorite categories #301 ----------------------------------------
            --[[
            ["LibSetsSetSearchFavoriteCategoryMarkers"] = { --#301 LibSets set search favorite category marker icons
                check				= nil, --settings.autoMarkLibSetsSetSearchFavorites, --todo: Could be disabled in settings and marks need to be removed then?
                result 				= true,
                resultNot			= nil,
                checkOtherAddon		= function()
                    return libSets ~= nil
                end,
                resultOtherAddon   	= true,
                resultNotOtherAddon	= nil,
                --Do not check here! Else it will abort due to not enabled icon if ONLY auto-bind is enabled. Icon will be determined in function automaticMarkingLibSetsCheckFunc and passed on
                --in returned 2nd parameter checkFuncData.newMarkerIcon
                icon				= nil,
                iconIsMarkedAllreadyAllowed = true,
                checkIfAnyIconIsMarkedAlready = nil,
                preCheckFunc        = function(p_bagId, p_slotIndex)
                    --Check if item is a set item
                    return isItemSetAndNotExcluded(p_bagId, p_slotIndex), nil
                end,
                resultPreCheckFunc  = true,
                resultNotPreCheckFunc = nil,
                checkFunc			= automaticMarkingLibSetsCheckFunc,
                checkFuncMarksItem  = true,
                resultCheckFunc 	= nil,
                resultNotCheckFunc 	= nil,
                additionalCheckFuncForce = nil, -- force the call of the additional check func!
                additionalCheckFunc = nil,
                resultAdditionalCheckFunc = nil,
                resultNotAdditionalCheckFunc = nil,
                chatOutput			= settings.showSetsInChat,
                chatBegin			= fcoisLoc["marked"],
                chatEnd				= fcoisLoc["LibSetsSetSearchFavoriteCategory_part_found"],
            },
            ]]
        } -- scantypeToDo
        --------------------------------------------------------------------------------
        --------------------------------------------------------------------------------
        --		Function start                                                        --
        --------------------------------------------------------------------------------
        --Local variables for the return
        local onlyUpdatePlayerInv = true
        local checksWereDoneLoop			 = false
        local atLeastOneMarkerIconWasSetLoop = false
        --Is the scantype given: Get the todos ->
        --Get the array below the scanType with the functions and stepts to check
        local toDos = scanTypeToDo[scanType]
        if toDos == nil then return false, false end

        --Check only one bag & slot, or a whole inventory?
        if bag ~= nil and slot ~= nil then
            --todo DEBUG: comment again after debug
            --[[
            if scanType == "setItemCollectionsUnknown" then
                d(">scanning: " ..GetItemLink(bag, slot))
            end
            ]]

            --Single item check
            checksWereDoneLoop, atLeastOneMarkerIconWasSetLoop = scanInventoryItemForAutomaticMarks(bag, slot, scanType, toDos)
            FCOIS.preventerVars.gScanningInv = false
        else
            if bag == nil and slot ~= nil then
                return
            end
            local bagIdsToScanNow
            --Get the bagIds that should be scanned, in teh user chosen order
            bagIdsToScanNow, onlyUpdatePlayerInv = getBagsToScanForAutomaticMarks(bag)
            local atLeastOneMarkerIconWasSetInForLoop 	= false
            for _, bagToCheck in ipairs(bagIdsToScanNow) do
                --d("[FCOIS]--> Scan whole inventory, bag: " .. tos(bagToCheck))
                --Get the bag cache (all entries in that bag)
                --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
                local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
                --Local variables for the for ... loop
                local checksWereDoneInForLoop			 	= false

                --For each item in that bag
                for _, data in pairs(bagCache) do
                    local bagId 	= data.bagId
                    local slotIndex = data.slotIndex
                    if bagId ~= nil and slotIndex ~= nil then
                        checksWereDoneInForLoop			 		= false
                        atLeastOneMarkerIconWasSetInForLoop 	= false
                        --Recursively call this function here
                        checksWereDoneInForLoop, atLeastOneMarkerIconWasSetInForLoop = scanInventoryItemForAutomaticMarks(bagId, slotIndex, scanType, toDos)
                        --d(">Whole bag item check. checksWereDoneLoop: " ..tos(checksWereDoneLoop) .. ", atLeastOneMarkerIconWasSetLoop: " ..tos(atLeastOneMarkerIconWasSetLoop))
                        --Update the calling functions return variables
                        if not checksWereDoneLoop then checksWereDoneLoop = checksWereDoneInForLoop end
                        if not atLeastOneMarkerIconWasSetLoop then atLeastOneMarkerIconWasSetLoop = atLeastOneMarkerIconWasSetInForLoop end
                    end
                end
            end
            --Reset the variable, that the inventories are not currently scanned
            FCOIS.preventerVars.gScanningInv = false
        end
        --------------------------------------------------------------------------------
        --				Function ends												  --
        --------------------------------------------------------------------------------
        --d("[FCOIS]>Scaning inv ended")

        --Was at least one item found that could be marked?
        if updateInv and atLeastOneMarkerIconWasSetLoop == true then
            --Update the inventory tabs to show the marker textures
            filterBasics(onlyUpdatePlayerInv)
        end

        --------------------------------------------------------------------------------
        --Return the functions return variables now
        --d("<<< retun checksWereDoneLoop: " .. tos(checksWereDoneLoop) .. ", atLeastOneMarkerIconWasSetLoop: " .. tos(atLeastOneMarkerIconWasSetLoop) .. ", scanType: " .. tos(scanType))
        return checksWereDoneLoop, atLeastOneMarkerIconWasSetLoop
    end
    local scanInventoryItemsForAutomaticMarks = FCOIS.ScanInventoryItemsForAutomaticMarks


    --Local function to scan a single inventory item
    -->checksAlreadyDoneTable was filled in function FCOIS.scanInventory with the results needed for the checks (performance gain!)
    function FCOIS.ScanInventorySingle(p_bagId, p_slotIndex, checksAlreadyDoneTable)
        --d("[ScanInventorySingle] bag: " .. tos(p_bagId) .. ", slot: " .. tos(p_slotIndex) .. ", scanningInv: " .. tos(FCOIS.preventerVars.gScanningInv))
        local updateInv = false
        local settings = FCOIS.settingsVars.settings
        local isIconEnabledSettings = settings.isIconEnabled
        if FCOIS.preventerVars.gScanningInv == false then
            if settings.debug then debugMessage( "[ScanInventorySingle]","Start", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --d("[ScanInventorySingle] Start - checksAlreadyDoneTable['recipes']: " ..tos(checksAlreadyDoneTable["recipes"]))
            -- Update only one item in inventory
            -- bagId AND slotIndex are given?
            if (p_bagId ~= nil and p_slotIndex ~= nil) then
                --Is the bag a HouseBank then check if we own a house and are in any owned house at the moment
                if houseBankBagChecks(p_bagId) == false then return end

                --Get item's instance or uniqueId
                local itemId = myGetItemInstanceIdNoControl(p_bagId, p_slotIndex, false)
                --d(">itemId: " ..tos(itemId))
                if itemId ~= nil then

                    --(Other addons)
                    --LibSets - Set search favorites category markers --#301
                    --[[
                    if (checksAlreadyDoneTable ~= nil and libSets ~= nil and checksAlreadyDoneTable["LibSetsSetSearchFavoriteCategoryMarkers"] == true) then
                        local _, libSetsSetPartChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "LibSetsSetSearchFavoriteCategoryMarkers", false)
                        if not updateInv and libSetsSetPartChanged then
                            updateInv = true
                        end
                    end
                    ]]

                    --1)
                    --Mark set items
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["sets"] == true) or (
                            (settings.autoMarkSets == true and isIconEnabledSettings[settings.autoMarkSetsIconNr])) then
                        local _, setPartChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "sets", false)
                        if not updateInv and setPartChanged then
                            updateInv = true
                        end
                    end

                    --2)
                    --Mark set collection book items
                    if settings.autoMarkSetsItemCollectionBook == true then
                        local autoBindMissingSetCollectionPiecesOnLoot = settings.autoBindMissingSetCollectionPiecesOnLoot
                        --d(">autoMarkSetsItemCollectionBook: " ..tos(true) .. ", autoBindMissingSetCollectionPiecesOnLoot: " ..tos(autoBindMissingSetCollectionPiecesOnLoot) ..", alreadyChecksDoneTab: " ..tos(checksAlreadyDoneTable["setItemCollectionsUnknown"]))
                        local _, setCollectionItemChanged
                        if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["setItemCollectionsUnknown"] == true) or (
                                autoBindMissingSetCollectionPiecesOnLoot == true or
                                        (not autoBindMissingSetCollectionPiecesOnLoot and settings.autoMarkSetsItemCollectionBookMissingIcon ~= FCOIS_CON_ICON_NONE and
                                                isIconEnabledSettings[settings.autoMarkSetsItemCollectionBookMissingIcon] == true)) then
                            --d(">>scan for unknown")
                            _, setCollectionItemChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "setItemCollectionsUnknown", false)
                        end
                        if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["setItemCollectionsKnown"] == true) or (
                                settings.autoMarkSetsItemCollectionBookNonMissingIcon ~= FCOIS_CON_ICON_NONE and
                                        isIconEnabledSettings[settings.autoMarkSetsItemCollectionBookNonMissingIcon] == true) then
                            --d(">>scan for known")
                            _, setCollectionItemChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "setItemCollectionsKnown", false)
                        end
                        if not updateInv and setCollectionItemChanged then
                            updateInv = true
                        end
                    end

                    --3)
                    --Update ornate items
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["ornate"] == true) or (
                            (settings.autoMarkOrnate == true and isIconEnabledSettings[FCOIS_CON_ICON_SELL]) ) then
                        local _, ornateChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "ornate", false)
                        if not updateInv and ornateChanged then
                            updateInv = true
                        end
                    end

                    --4)
                    --Update intricate items
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["intricate"] == true) or (
                            (settings.autoMarkIntricate == true and isIconEnabledSettings[FCOIS_CON_ICON_INTRICATE])) then
                        local _, intricateChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "intricate", false)
                        if not updateInv and intricateChanged then
                            updateInv = true
                        end
                    end

                    --5)
                    --Update researchable items
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["research"] == true) or (
                            (settings.autoMarkResearch == true and checkIfResearchAddonUsed() and checkIfChosenResearchAddonActive() and isIconEnabledSettings[FCOIS_CON_ICON_RESEARCH])) then
                        --local itemLink = gil(p_bagId, p_slotIndex)
                        --d(">scanInvSingle, research scan reached for: " .. itemLink)
                        local _, researchableChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "research", false)
                        if not updateInv and researchableChanged then
                            updateInv = true
                        end
                    end

                    --6)
                    --Update research scrolls (time reduction for crafting research) items
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["researchScrolls"] == true) or (
                            ((DetailedResearchScrolls ~= nil and DetailedResearchScrolls.GetWarningLine ~= nil) and settings.autoMarkWastedResearchScrolls == true and isIconEnabledSettings[FCOIS_CON_ICON_LOCK])) then
                        local _, researchScrollWastedChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "researchScrolls", false)
                        if not updateInv and researchScrollWastedChanged then
                            updateInv = true
                        end
                    end

                    --7)
                    --Update unknown recipes
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["recipes"] == true) or (
                            isRecipeAutoMarkDoable(true, false, true)) then
                        --local itemLink = gil(p_bagId, p_slotIndex)
                        --d(">scanInvSingle, unknown recipe scan reached for: " .. itemLink)
                        local _, recipeChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "recipes", false)
                        if not updateInv and recipeChanged then
                            updateInv = true
                        end
                    end

                    --8)
                    --Update known recipes
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["knownRecipes"] == true) or (
                            isRecipeAutoMarkDoable(false, true, true)) then
                        local _, recipeChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "knownRecipes", false)
                        if not updateInv and recipeChanged then
                            updateInv = true
                        end
                    end

                    --9)
                    --Update unknown motifs --#308
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["motifs"] == true) or (
                            isMotifsAutoMarkDoable(true, false, true)) then
                        --local itemLink = gil(p_bagId, p_slotIndex)
                        --d(">scanInvSingle, unknown motifs scan reached for: " .. itemLink)
                        local _, recipeChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "motifs", false)
                        if not updateInv and recipeChanged then
                            updateInv = true
                        end
                    end

                    --10)
                    --Update known recipes --#308
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["knownMotifs"] == true) or (
                            isMotifsAutoMarkDoable(false, true, true)) then
                        local _, recipeChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "knownMotifs", false)
                        if not updateInv and recipeChanged then
                            updateInv = true
                        end
                    end

                    --11)
                    --Check for item quality
                    if (checksAlreadyDoneTable ~= nil and checksAlreadyDoneTable["quality"] == true) or (
                            (settings.autoMarkQuality ~= 1 and isIconEnabledSettings[settings.autoMarkQualityIconNr])) then
                        local _, qualityChanged = scanInventoryItemsForAutomaticMarks(p_bagId, p_slotIndex, "quality", false)
                        if not updateInv and qualityChanged then
                            updateInv = true
                        end
                    end
                end -- if (itemId ~= nil) then
            end --if (p_bagId ~= nil and p_slotIndex ~= nil) then
            --Inventory scan is latest finished here
            --FCOIS.preventerVars.gScanningInv = false
        end
        if settings.debug then debugMessage( "[ScanInventorySingle]","End", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        --d("[ScanInventorySingle] END, updateInv: " .. tos(updateInv))
        return updateInv
    end
    local scanInventorySingle = FCOIS.ScanInventorySingle


    --Scan the inventory for ornate and/or researchable, setCollectionBook known/unknown, quality, recipes knonw/unknown, research scrolls or set items,
    --and other automatic marks or marks to be removed (LibSets set search favorite category marker icons)
    function FCOIS.ScanInventory(p_bagId, p_slotIndex, doEcho)
        doEcho = doEcho or false
        local settings = FCOIS.settingsVars.settings
        --Do not scan now if the unique item IDs got just enabled before the reloadui
        if FCOIS.preventerVars.doNotScanInv == true then
            if settings.useUniqueIds then
                d(FCOIS.preChatVars.preChatTextRed .. FCOIS.localizationVars.fcois_loc["options_migrate_unique_inv_scan_not_done"])
            end
            FCOIS.preventerVars.doNotScanInv = false
            return false
        end
        --d("[ScanInventory] bag: " .. tos(p_bagId) .. ", slot: " .. tos(p_slotIndex) .. ", scanningInv: " .. tos(FCOIS.preventerVars.gScanningInv))
        --Inventory scan is alreay active? Do not start another one!
        if FCOIS.preventerVars.gScanningInv == true then return end

        local updateInv = false
        local isIconEnabledSettings = settings.isIconEnabled

        local isRecipeAddonActive = (checkIfRecipeAddonUsed() and checkIfChosenRecipeAddonActive()) or false
        local isMotifsAddonActive = (checkIfMotifsAddonUsed() and checkIfChosenMotifsAddonActive()) or false --#308
        local isResearchAddonActive = (checkIfResearchAddonUsed() and checkIfChosenResearchAddonActive() and isIconEnabledSettings[FCOIS_CON_ICON_RESEARCH]) or false
        local isResearchScrollsAddonActive = (DetailedResearchScrolls ~= nil and DetailedResearchScrolls.GetWarningLine ~= nil and settings.autoMarkWastedResearchScrolls == true and isIconEnabledSettings[FCOIS_CON_ICON_LOCK]) or false

        local autoMarkSetsItemCollectionBook = settings.autoMarkSetsItemCollectionBook
        local autoBindMissingSetCollectionPiecesOnLoot = settings.autoBindMissingSetCollectionPiecesOnLoot

        --Automatic marking of ornate, intricate, researchable items (researchAssistant or other research addon needed, or ESO base game marks for researchabel items), unknown recipes (SousChef or other recipe addon is needed!), set parts, quality items, set collection book items is activated?
        local checksAlreadyDoneTable = {}
        checksAlreadyDoneTable["ornate"]                    = (settings.autoMarkOrnate == true and isIconEnabledSettings[FCOIS_CON_ICON_SELL])
        checksAlreadyDoneTable["intricate"]                 = (settings.autoMarkIntricate == true and isIconEnabledSettings[FCOIS_CON_ICON_INTRICATE])
        checksAlreadyDoneTable["research"]                  = (isResearchAddonActive and settings.autoMarkResearch == true)
        checksAlreadyDoneTable["researchScrolls"]           = isResearchScrollsAddonActive
        checksAlreadyDoneTable["quality"]                   = (settings.autoMarkQuality ~= 1 and isIconEnabledSettings[settings.autoMarkQualityIconNr])
        checksAlreadyDoneTable["recipes"]                   = (isRecipeAddonActive and settings.autoMarkRecipes == true and isIconEnabledSettings[settings.autoMarkRecipesIconNr])
        checksAlreadyDoneTable["knownRecipes"]              = (isRecipeAddonActive and settings.autoMarkKnownRecipes == true and isIconEnabledSettings[settings.AutoMarkKnownRecipesIconNr])
        checksAlreadyDoneTable["motifs"]                    = (isMotifsAddonActive and settings.autoMarkMotifs == true and isIconEnabledSettings[settings.autoMarkMotifsIconNr]) -- #308
        checksAlreadyDoneTable["knownMotifs"]               = (isMotifsAddonActive and settings.autoMarkKnownMotifs == true and isIconEnabledSettings[settings.AutoMarkKnownMotifsIconNr]) -- #308
        checksAlreadyDoneTable["setItemCollectionsUnknown"] = (autoMarkSetsItemCollectionBook == true and (autoBindMissingSetCollectionPiecesOnLoot == true or (not autoBindMissingSetCollectionPiecesOnLoot == true and settings.autoMarkSetsItemCollectionBookMissingIcon ~= FCOIS_CON_ICON_NONE and isIconEnabledSettings[settings.autoMarkSetsItemCollectionBookMissingIcon] == true)))
        checksAlreadyDoneTable["setItemCollectionsKnown"]   = (autoMarkSetsItemCollectionBook == true and (settings.autoMarkSetsItemCollectionBookNonMissingIcon ~= FCOIS_CON_ICON_NONE and isIconEnabledSettings[settings.autoMarkSetsItemCollectionBookNonMissingIcon] == true))
        checksAlreadyDoneTable["sets"]                      = (settings.autoMarkSets == true and isIconEnabledSettings[settings.autoMarkSetsIconNr])
        --checksAlreadyDoneTable["LibSetsSetSearchFavoriteCategoryMarkers"] = (libSets ~= nil and libSets.GetSetSearchFavoriteCategories ~= nil) --#301

        local isCheckNecessary = false
        for _, isCheckNecessaryAtCheckType in pairs(checksAlreadyDoneTable) do
            if isCheckNecessaryAtCheckType == true then
                isCheckNecessary = true
                break -- leave the loop
            end
        end

        if isCheckNecessary == true then
            --d("-Scanning needed-")
            local fcoisLoc = FCOIS.localizationVars.fcois_loc
            local preVars  = FCOIS.preChatVars
            local prefixFCOISGreen = preVars.preChatTextGreen
            local prefixFCOISRed = preVars.preChatTextRed
            local onlyUpdatePlayerInv = true

            -- Scan the whole inventory because no bagId and slotIndex are given
            if p_bagId == nil or p_slotIndex == nil then
                --d("[ScanInventory] Start ALL")
                if settings.debug then debugMessage( "[ScanInventory]","Start ALL", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

                if p_bagId == nil and p_slotIndex ~= nil then
                    return
                end

                local bagIdsToScanNow
                --Get the bagIds that should be scanned, in teh user chosen order
                bagIdsToScanNow, onlyUpdatePlayerInv = getBagsToScanForAutomaticMarks(p_bagId)
                --FCOIS._bagIdsToScanNow = bagIdsToScanNow
                --FCOIS._onlyUpdatePlayerInv = onlyUpdatePlayerInv

                --Get the bag cache (all entries in that bag)
                --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
                for _, bagToCheck in ipairs(bagIdsToScanNow) do
                    local filterPanelId, filterPanelText
                    if doEcho == true then
                        filterPanelId = getFilterPanelIdByBagId(bagToCheck)
                        filterPanelText = getFilterPanelIdText(filterPanelId)
                        if bagToCheck == BAG_SUBSCRIBER_BANK then
                            filterPanelText = filterPanelText .. " - ESO+"
                        end
                        d(strformat(prefixFCOISGreen .. " " .. fcoisLoc["options_scan_automatic_marks_scan_bag"], filterPanelText))
                    end
                    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
                    local updateInvLoop = false
                    for _, data in pairs(bagCache) do
                        updateInvLoop = false
                        updateInvLoop = scanInventorySingle(data.bagId, data.slotIndex, checksAlreadyDoneTable)
                        if not updateInv then updateInv = updateInvLoop end
                    end
                    if doEcho == true then
                        d(strformat(prefixFCOISRed .. " " .. fcoisLoc["options_scan_automatic_marks_scan_bag_finished"], filterPanelText))
                    end
                end
                if settings.debug then debugMessage( "[ScanInventory]","End ALL", false, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                --d("[ScanInventory] END ALL")

            else
                --d("[ScanInventory] Start ONE ITEM")
                -- Scan only one item?
                if p_bagId ~= nil and p_slotIndex ~= nil then
                    updateInv = scanInventorySingle(p_bagId, p_slotIndex, checksAlreadyDoneTable)
                end
                --d("[ScanInventory] End ONE ITEM")
            end

            --[[
            --Reset recently removed LibSets set search favorite category mapping to FCOIS marker icons
            -->todo: 20241205 How do we only do it after all bags have been scanned, and not directly afer the first bag has been scanned?
            if libSets ~= nil then --#301 LibSets set search favorites
                settings.LibSetsSetSearchFavoriteToFCOISMappingRemoved = {}
            end
            ]]

            --Update the inventories?
            if updateInv == true then
                filterBasics(onlyUpdatePlayerInv)
            end

        end --if isCheckNecessary then
    end