--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local ctrlVars = FCOIS.ZOControlVars

--==========================================================================================================================================
--                                          FCOIS - Base & helper functions
--==========================================================================================================================================
local function booleanToNumber(boolValue)
    boolValue = boolValue or false
    if type(boolValue) ~= "boolean" then return end
    local mapBoolToNumberTab = {
        [false] = 0,
        [true]  = 1,
    }
    return mapBoolToNumberTab[boolValue] or 0
end


--A throttle updater function to run updates not too ofter
function FCOIS.ThrottledUpdate(callbackName, timer, callback, ...)
--d("[FCOIS]ThrottledUpdate, callbackName: " .. tostring(callbackName))
    local args = {...}
    local function Update()
        EVENT_MANAGER:UnregisterForUpdate(callbackName)
        callback(unpack(args))
    end
    EVENT_MANAGER:UnregisterForUpdate(callbackName)
    EVENT_MANAGER:RegisterForUpdate(callbackName, timer, Update)
end


--Set the variables for each panel where the number of filtered items can be found for the current inventory
function FCOIS.getNumberOfFilteredItemsForEachPanel()
    local numFilterdItemsInv = ctrlVars.BACKPACK_LIST.data
    FCOIS.numberOfFilteredItems[LF_INVENTORY]              = numFilterdItemsInv
    --Same like inventory
    FCOIS.numberOfFilteredItems[LF_MAIL_SEND]              = numFilterdItemsInv
    FCOIS.numberOfFilteredItems[LF_TRADE]                  = numFilterdItemsInv
    FCOIS.numberOfFilteredItems[LF_GUILDSTORE_SELL]        = numFilterdItemsInv
    FCOIS.numberOfFilteredItems[LF_BANK_DEPOSIT]           = numFilterdItemsInv
    FCOIS.numberOfFilteredItems[LF_GUILDBANK_DEPOSIT]      = numFilterdItemsInv
    FCOIS.numberOfFilteredItems[LF_VENDOR_BUY]             = 0 -- TODO: Add as filter panel gets supported
    FCOIS.numberOfFilteredItems[LF_VENDOR_SELL]            = numFilterdItemsInv
    FCOIS.numberOfFilteredItems[LF_VENDOR_BUYBACK]         = 0 -- TODO: Add as filter panel gets supported
    FCOIS.numberOfFilteredItems[LF_VENDOR_REPAIR]          = 0 -- TODO: Add as filter panel gets supported
    FCOIS.numberOfFilteredItems[LF_FENCE_SELL]             = numFilterdItemsInv
    FCOIS.numberOfFilteredItems[LF_FENCE_LAUNDER]          = numFilterdItemsInv
    --Others
    FCOIS.numberOfFilteredItems[LF_BANK_WITHDRAW]          = ctrlVars.BANK.data
    FCOIS.numberOfFilteredItems[LF_GUILDBANK_WITHDRAW]     = ctrlVars.GUILD_BANK.data
    FCOIS.numberOfFilteredItems[LF_SMITHING_REFINE]        = ctrlVars.REFINEMENT.data
    FCOIS.numberOfFilteredItems[LF_SMITHING_DECONSTRUCT]   = ctrlVars.DECONSTRUCTION.data
    FCOIS.numberOfFilteredItems[LF_SMITHING_IMPROVEMENT]   = ctrlVars.IMPROVEMENT.data
    FCOIS.numberOfFilteredItems[LF_SMITHING_RESEARCH]      = 0 -- No item count should be shown at the research traits list
    FCOIS.numberOfFilteredItems[LF_SMITHING_RESEARCH_DIALOG] = 0 -- No item count should be shown inside the selected traits popup
    FCOIS.numberOfFilteredItems[LF_ALCHEMY_CREATION]       = ctrlVars.ALCHEMY_STATION.data
    FCOIS.numberOfFilteredItems[LF_ENCHANTING_CREATION]    = ctrlVars.ENCHANTING_STATION.data
    FCOIS.numberOfFilteredItems[LF_ENCHANTING_EXTRACTION]  = FCOIS.numberOfFilteredItems[LF_ENCHANTING_CREATION]
    FCOIS.numberOfFilteredItems[LF_CRAFTBAG]               = ctrlVars.CRAFTBAG_LIST.data
    FCOIS.numberOfFilteredItems[LF_RETRAIT]                = ctrlVars.RETRAIT_LIST.data
    FCOIS.numberOfFilteredItems[LF_HOUSE_BANK_WITHDRAW]    = ctrlVars.HOUSE_BANK.data
    FCOIS.numberOfFilteredItems[LF_JEWELRY_REFINE]         = FCOIS.numberOfFilteredItems[LF_SMITHING_REFINE]
    FCOIS.numberOfFilteredItems[LF_JEWELRY_DECONSTRUCT]    = FCOIS.numberOfFilteredItems[LF_SMITHING_DECONSTRUCT]
    FCOIS.numberOfFilteredItems[LF_JEWELRY_IMPROVEMENT]    = FCOIS.numberOfFilteredItems[LF_SMITHING_IMPROVEMENT]
    FCOIS.numberOfFilteredItems[LF_JEWELRY_RESEARCH]       = FCOIS.numberOfFilteredItems[LF_SMITHING_RESEARCH]
    FCOIS.numberOfFilteredItems[LF_JEWELRY_RESEARCH_DIALOG]= FCOIS.numberOfFilteredItems[LF_SMITHING_RESEARCH_DIALOG]
    FCOIS.numberOfFilteredItems[LF_QUICKSLOT]              = ctrlVars.QUICKSLOT_WINDOW.list.data
    --Special numbers for e.g. quest items in inventory
    FCOIS.numberOfFilteredItems["INVENTORY_QUEST_ITEM"]    = PLAYER_INVENTORY.inventories[INVENTORY_QUEST_ITEM].listView.data

end


--==========================================================================================================================================
--                                          FCOIS - Is, Get, Set functions
--==========================================================================================================================================

--==============================================================================
-- Get instance & item ID functions
--==============================================================================
--Function to build an itemLink from the itemId. Code from addon "Dolgubon's Lazy Writ Creator"! Thx Dolgubon
function FCOIS.getItemLinkFromItemId(itemId)
    return string.format("|H1:item:%d:%d:50:0:0:0:0:0:0:0:0:0:0:0:0:%d:%d:0:0:%d:0|h|h", itemId, 0, ITEMSTYLE_NONE, 0, 10000)
end

--Function to get the itemId from an itemLink
function FCOIS.getItemIdFromItemLink(itemLink)
    return GetItemLinkItemId(itemLink)
end

--Check if the given addonName had enabled the temporary uniqueId checks
local function checkIfAddonNameHasTemporarilyEnabledUniqueIds(addonName)
    if addonName ~= nil and addonName ~= "" and FCOIS.temporaryUseUniqueIds ~= nil and FCOIS.temporaryUseUniqueIds[addonName] ~= nil then
        return FCOIS.temporaryUseUniqueIds[addonName]
    end
    return false
end

--[[
local function checkItemIdIsString(itemId)
    local retItemId = itemId

    return retItemId
end
]]

--Check if the given item ID is already a converted id64String (real uniqueId stored as String)
--or if its a , concatenated String of "<itemId>,<levelNumber>,<qualityId>,<traitId>,<styleId>,<enchantId>, ...." (uniqueId based on the data)
-->If not , concatenated String and uniqueIds are enabled: Convert it into an id64String
function FCOIS.checkItemId(itemId, addonName)
    if itemId == nil then return end
    local retItemId = itemId
    --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids)
    if FCOIS.settingsVars.settings.useUniqueIds or checkIfAddonNameHasTemporarilyEnabledUniqueIds(addonName) == true then
        --Check if the given uniqueID is already transfered to the string, and if not do so
        if type(itemId) ~= "string" then
            retItemId = zo_getSafeId64Key(itemId)
        end
    end
    --d("FCOIS.checkItemId: " ..tostring(retItemId))
    return retItemId
end

function FCOIS.getFCOISMarkerIconUniqueIdAllowedItemType(bagId, slotIndex, uniqueItemIdType)
    local allowedItemtype
    local settings = FCOIS.settingsVars.settings
    if uniqueItemIdType == nil then
        if settings.useUniqueIds == true then
            uniqueItemIdType = settings.uniqueItemIdType
            uniqueItemIdType = uniqueItemIdType or FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE
        else
            --Non-unique itemIds are enabled so all itemTypes are allowed for the itemInstanceId markers
            return true
        end
    end
    if uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then -- ZOs real unique IDs
        --Only armor and weapons and jewelry count as allowed itemType
        allowedItemtype = FCOIS.allowedUniqueIdItemTypes[GetItemType(bagId, slotIndex)] or false
    else
        --All selected itemTypes at the settings of unique FCOIS marker icon IDs are allowed itemtypes
        allowedItemtype = settings.allowedFCOISUniqueIdItemTypes[GetItemType(bagId, slotIndex)] or false
    end
    return allowedItemtype
end
local getFCOISMarkerIconUniqueIdAllowedItemType = FCOIS.getFCOISMarkerIconUniqueIdAllowedItemType

--Get the itemInstanceId for non-unique or the unique ZOs id or the FCOIS created unique id, depending on the settings
function FCOIS.GetFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, allowedItemType, useUniqueIds, uniqueItemIdType, signToo)
    if bagId == nil or slotIndex == nil then
        return nil, allowedItemType
    end
    signToo = signToo or false
    local itemId
    local useNormalItemInstanceId = true
    if useUniqueIds == nil or uniqueItemIdType == nil then
        local settings = FCOIS.settingsVars.settings
        useUniqueIds = settings.useUniqueIds
        uniqueItemIdType = settings.uniqueItemIdType
    end
    local useUniqueIdsForMarkerIcons = useUniqueIds
    local uniqueIdsTypeForMarkerIcons = uniqueItemIdType

    if useUniqueIdsForMarkerIcons == true then
        allowedItemType = allowedItemType or getFCOISMarkerIconUniqueIdAllowedItemType(bagId, slotIndex, uniqueIdsTypeForMarkerIcons)
        if allowedItemType == true then
            useNormalItemInstanceId = false
            if not uniqueIdsTypeForMarkerIcons or uniqueIdsTypeForMarkerIcons == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then -- ZOs real unique IDs
                itemId = zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex))
            elseif uniqueIdsTypeForMarkerIcons == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE then --FCOIS onw build unique IDs
                itemId = FCOIS.CreateFCOISUniqueIdString(GetItemId(bagId, slotIndex), allowedItemType, bagId, slotIndex, nil)
            end
        end
    end
    if useNormalItemInstanceId == true then
        local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
        --Sign the itemInstanceId now
        if signToo == true then
            --3rd parameter onlySign == true will force to sign the itemInstanceId without further checks
            itemId = FCOIS.SignItemId(itemInstanceId, allowedItemType, true, nil, bagId, slotIndex)
        else
            --Will be signed later on, e.g. if this function here was called via function FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex, signToo)
            --where signToo == true -> Then FCOIS.SignItemId will be called from that function + updates internal variables
            itemId = itemInstanceId
        end
    end
    return itemId, allowedItemType
end
local GetFCOISMarkerIconSavedVariablesItemId = FCOIS.GetFCOISMarkerIconSavedVariablesItemId

--Get the item's instance id or unique ID
--OLD function before "dragon bones" patch
function FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex, signToo)
--d("[FCOIS]MyGetItemInstanceIdNoControl - bagId: " ..tostring(bagId) .. ", slotIndex: " ..tostring(slotIndex).. ", signToo: " ..tostring(signToo) )
    signToo = signToo or false
    --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids)
    local itemId
    local allowedItemType
    --Cache the last used bagId and slotIndex for the cached iteminstance or uniqueId
    -->Reset the last ID if he bagId or slotIndex changes
    if (bagId == nil or FCOIS.MyGetItemInstanceIdLastBagId == nil or FCOIS.MyGetItemInstanceIdLastBagId ~= bagId) or
        (slotIndex == nil or FCOIS.MyGetItemInstanceIdLastSlotIndex== nil or FCOIS.MyGetItemInstanceIdLastSlotIndex ~= slotIndex) then
--d(">resetting cached bag, slot and itemIds")
        --Reset the cached last ID
        FCOIS.MyGetItemInstanceIdLastId = nil
        FCOIS.MyGetItemInstanceIdLastIdSigned = nil
    end
    FCOIS.MyGetItemInstanceIdLastBagId = bagId
    FCOIS.MyGetItemInstanceIdLastSlotIndex = slotIndex

    --Is the bagId and slotIndex empty: Read the itemInstanceOrUniqueId from the FCOIS.IIfAclicked table (if filled)
    if bagId == nil or slotIndex == nil then
        local IIfAclicked = FCOIS.IIfAclicked
        if IIfAclicked ~= nil then
            itemId = IIfAclicked.itemInstanceOrUniqueId
        end

    --bagId and slotIndex are given already
    else
        --Is the unique item ID enabled and the item's type is an allowed one(e.g. weapons, armor, ...)
        --Then use the unique item ID
        --Else use the non-unique item ID
        local settings = FCOIS.settingsVars.settings
        if settings.debug then FCOIS.debugMessage( "[MyGetItemInstanceIdNoControl]","useUniqueIds: " .. tostring(settings.useUniqueIds) .. ", allowedItemType: " .. tostring(allowedItemType), true, FCOIS_DEBUG_DEPTH_ALL) end
        --d("[FCOIS.MyGetItemInstanceINoControl] useUniqueIds: " .. tostring(settings.useUniqueIds) .. ", allowedItemType: " .. tostring(allowedItemType))

        --Use the cached itemId first
        itemId = FCOIS.MyGetItemInstanceIdLastId
        --If there was nothing cached: Build it new
        if itemId == nil then
            itemId, allowedItemType = GetFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, nil, settings.useUniqueIds, settings.uniqueItemIdType, not signToo)
            --Cache the last ID so that loops won't rebuild the whole id for the same bagId + slotIndex (if all marker icons are checked)
            FCOIS.MyGetItemInstanceIdLastId = itemId
        end
        if settings.useUniqueIds == true and allowedItemType == true then
            --Prevent calling FCOIS.SignItemId:
            --Unique IDs do not need to be signed as only numbers get signed but uniqueIds are Strings
            return itemId, allowedItemType
        end
    end
    if signToo == true then
        if FCOIS.MyGetItemInstanceIdLastIdSigned == nil then
            local itemInstanceIdSigned = FCOIS.SignItemId(itemId, allowedItemType, nil, nil, bagId, slotIndex)
            FCOIS.MyGetItemInstanceIdLastIdSigned = itemInstanceIdSigned
            return itemInstanceIdSigned
        else
            return FCOIS.MyGetItemInstanceIdLastIdSigned
        end
    end
    return itemId, allowedItemType
end

--LAGGY if applied to multiple items at once! So only use for backup.
-- itemId is basically what tells us that two items are the same thing,
-- but some types need additional data to determine if they are of the same strength (and value).
local function GetItemIdentifierForBackup(bagId, slotIndex)
    --ItemLik fields/indices:
    --socket = enchantment
    --"linkStyle:type:id:quality:requiredLevel:socketItem:socketItemQuality:socketRequiredLevel:extraField1:extraField2:extraField3:extraField4:extraField5:extraField6:unused:unused:allFlags:style:crafted:bound:stolen:enchantCharges/condition:instanceData"
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink == nil or itemLink == "" then return nil end
    local itemId
    if GetItemLinkItemId ~= nil then
        itemId = tonumber(GetItemLinkItemId(itemLink)) -- Function will be added soon, ZOS_ChipHilseberg added it on 14.02.2018 to the dev system internally
    else
        itemId = tonumber(GetItemId(bagId, slotIndex))
    end
    --These itemTypes use different qualities
    local hasDifferentQualities = {
        [ITEMTYPE_GLYPH_ARMOR] = true,
        [ITEMTYPE_GLYPH_JEWELRY] = true,
        [ITEMTYPE_GLYPH_WEAPON] = true,
        [ITEMTYPE_DRINK] = true,
        [ITEMTYPE_FOOD] = true,
    }
    local settings = FCOIS.settingsVars.settings
    --Get the item type and some info about enchantment and level etc.
    local itemType = GetItemLinkItemType(itemLink)
    if(itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR) then
        local level = GetItemLinkRequiredLevel(itemLink)
        local cp = GetItemLinkRequiredChampionPoints(itemLink)
        --Is the unique item ID enabled and the item's type is an allowed one(e.g. weapons, armor, ...)
        local allowedItemType = FCOIS.allowedUniqueIdItemTypes[itemType] or false
        local useUniqueItemIdentifier = (settings.useUniqueIds and allowedItemType) or false
        local trait = GetItemLinkTraitInfo(itemLink)
        local quality = GetItemLinkFunctionalQuality(itemLink)
        if useUniqueItemIdentifier then
            --Then check the enchantment + quality + level too
            --:socketItem: = 6, :socketItemQuality: = 7, :socketRequiredLevel: = 8
            local itemStyle = GetItemLinkItemStyle(itemLink)
            local data = {zo_strsplit(":", itemLink:match("|H(.-)|h.-|h"))}
            local enchantment = tostring(data[6]) ..",".. tostring(data[7]).."," .. tostring(data[8])
            --local quality = data[4]
            return string.format("%d,%d,%d,%d,%d,%d,%s", itemId, quality, trait, level, cp, itemStyle, enchantment)
        else
            --No enchantment checks
            return string.format("%d,%d,%d,%d,%d", itemId, quality, trait, level, cp)
        end
    elseif(itemType == ITEMTYPE_POISON or itemType == ITEMTYPE_POTION) then
        local level = GetItemLinkRequiredLevel(itemLink)
        local cp = GetItemLinkRequiredChampionPoints(itemLink)
        local data = {zo_strsplit(":", itemLink:match("|H(.-)|h.-|h"))}
        return string.format("%d,%d,%d,%s", itemId, level, cp, data[23])
    elseif(hasDifferentQualities[itemType]) then
        local quality = GetItemLinkFunctionalQuality(itemLink)
        return string.format("%d,%d", itemId, quality)
    else
        return itemId
    end
end

function FCOIS.MyGetItemInstanceIdNoControlForBackup(bagId, slotIndex, signToo)
    signToo = signToo or false
    --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids)
    local buildItemIdentifier = GetItemIdentifierForBackup(bagId, slotIndex)
    if buildItemIdentifier == nil or buildItemIdentifier == false then return nil end
    return buildItemIdentifier
end


function FCOIS.MyGetItemInstanceId(rowControl, signToo)
    signToo = signToo or false
    local bagId, slotIndex
    --Inventory Insight from ashes support
    if FCOIS.IIfAclicked ~= nil then
        bagId, slotIndex = FCOIS.IIfAclicked.bagId, FCOIS.IIfAclicked.slotIndex
    else
        bagId, slotIndex = FCOIS.MyGetItemDetails(rowControl)
    end
    --If the bagid and slotIndex are empty here the itemInstanceOrUniqueId will be read from FCOIS.IIfAclicked in function FCOIS.MyGetItemInstanceIdNoControl!
    local itemId = FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex, signToo)
    return itemId
end

function FCOIS.extractItemIdFromItemLink(itemLink)
    if GetItemLinkItemId ~= nil then
        return GetItemLinkItemId(itemLink)
    else
        return tonumber(string.match(itemLink,"|H%d:item:(%d+)"))
    end
end

--Create a unique String as "uniqueID" for an allowed itemtype of an item:
--"<unsignedItemIdOrItemInstanceId>,<levelNumber>,<qualityId>,<traitId>,<styleId>,<enchantId>,<isStolen>,<isCrafted>,<craftedByName>"
-->Depending on the chosen uniqeId "parts" settings and the itemType of the item!
--Parameters bagId and slotIndex or itemLink must be given!
--If only the parameter itemLink is given the parameter unsignedItemInstanceId must be given as well, as there is no GetItemLinkIteminstaceId function :-(
-->TODO: Maybe, if only itemLink is given, use the itemId here instead of the ItemInstanceId then, as some addons like IventoryInsight from ashes do not provide bagId and slotIndex at all!
-->Yes, changed to that way, also because the itemInstanceId always differs level/quality/enchantment etc. already and if we want to manually specify which parts the FCOIS uniqueId needs, we need to use the itemId as base!
--If bagId and slotIndex are given unsignedItemInstanceId can be nil (will be rebuild internally then).
--If allowedItemType (boolean) is not given then the itemType will be rebuild from the bagId & slotIndex, or the itemlink, and the value will be checked against FCOIS.allowedUniqueIdItemTypes[itemType] afterwards.
function FCOIS.CreateFCOISUniqueIdString(itemId, bagId, slotIndex, itemLink)
    --Either bag + slot or itemLink needs to be given
    if (not bagId or not slotIndex) and (not itemLink or itemLink == "") then return end
    --Get or use the itemLink
    if bagId and slotIndex and not itemLink then
        itemLink = GetItemLink(bagId, slotIndex)
    end
--d("[FCOIS]CreateFCOISUniqueIdString - " ..itemLink)
    if not itemLink or itemLink == "" then return end

    --Get the item's base data like itemInstanceId, level, quality
    if not itemId then
        if bagId and slotIndex then
            --Use the ItemInstanceId
            --unsignedItemInstanceId = GetItemInstanceId(bagId, slotIndex)
            --Use the itemId
            itemId = GetItemId(bagId, slotIndex)
        else
            --No bag or slot? Use the itemId of the itemLink -> e..g Addon Inventory Insight From Ashes
            -->TODO: This might become buggy if one extracts the first value of the returned String (the itemId in this case) and tries to get entries in the SavedVariables
            -->TODO: of "markedItems" using only this itemId, instead of the "signed" ItemInstanceId. One would need to check the inventory item's signed itemId and if it
            -->TODO: matches get bagId and slotIndex of that item to do further checks
            itemId = GetItemLinkItemId(itemLink)
        end
    end
    if not itemId then return end

    --------------------------------------------------------------------------------------------------------------------
    --Cache the last used unsignedItemInstanceId + bagId  + slotIndex,
    --or Cache the last used unsignedItemInstanceId + itemlink
    -->Reset the last ID if the combination changes
    --Last itemLink not known?
    local lastUsedLastUsedType      = FCOIS.CreateFCOISUniqueIdStringLastLastUseType
    if lastUsedLastUsedType == nil or lastUsedLastUsedType > 2 then
--d(">resetting all variables")
        --Reset all variables
        FCOIS.CreateFCOISUniqueIdStringLastLastUseType              = nil
        FCOIS.CreateFCOISUniqueIdStringLastUnsignedItemInstanceId   = nil
        FCOIS.CreateFCOISUniqueIdStringLastBagId                    = nil
        FCOIS.CreateFCOISUniqueIdStringLastSlotIndex                = nil
        FCOIS.CreateFCOISUniqueIdStringLastItemLink                 = nil
        FCOIS.CreateFCOISUniqueIdStringLastFCOISCreatedUniqueId     = nil
    end

    local lastUsedItemInstanceId    = FCOIS.CreateFCOISUniqueIdStringLastUnsignedItemInstanceId
    local lastFCOISuniqueId         = FCOIS.CreateFCOISUniqueIdStringLastFCOISCreatedUniqueId
    local lastBagId                 = FCOIS.CreateFCOISUniqueIdStringLastBagId
    local lastSlotIndex             = FCOIS.CreateFCOISUniqueIdStringLastSlotIndex
    local lastItemLink              = FCOIS.CreateFCOISUniqueIdStringLastItemLink

    --Did we cache something already?
    if lastUsedLastUsedType ~= nil and lastUsedItemInstanceId ~= nil and lastUsedItemInstanceId == itemId
        and lastFCOISuniqueId ~= nil then
        --unsignedItemInstanceId + bagId, slotIndex
        if lastUsedLastUsedType == 1 then
            if (bagId ~= nil and lastBagId ~= nil and bagId == lastBagId) and
               (slotIndex ~= nil and lastSlotIndex ~= nil and slotIndex == lastSlotIndex) then
--d("<returning cached bagId/slotIndex value: " ..tostring(lastFCOISuniqueId))
                return lastFCOISuniqueId
            end
        --unsignedItemInstanceId + ItemLink
        elseif lastUsedLastUsedType == 2 then
            if (itemLink ~= nil and lastItemLink ~= nil and itemLink == lastItemLink) then
--d("<returning cached itemLink value: " ..tostring(lastFCOISuniqueId))
                return lastFCOISuniqueId
            end
        end
    end

    --------------------------------------------------------------------------------------------------------------------
    --Get the values for the uniqueId parts, depending on the part settings
    --Get the parts for the unique ID to build
    local settings = FCOIS.settingsVars.settings
    local uniqueIdParts = settings.uniqueIdParts
    if not uniqueIdParts then return end

    --Add item's level to the uniqueId?
    local level
    local quality
    local trait
    local style
    local enchantment
    local isStolen
    local isCrafted
    local craftedByName

    if uniqueIdParts.level == true then
        local cpLevel = GetItemLinkRequiredChampionPoints(itemLink)
        if cpLevel ~= nil then
            level = cpLevel
        else
            level = GetItemLinkRequiredLevel(itemLink)
        end
    end
    if level == nil then level = 0 end

    --Add item's quality to the uniqueId?
    if uniqueIdParts.quality == true then
        quality = GetItemLinkFunctionalQuality(itemLink)
    end
    if quality == nil then quality = 0 end

    --Get the values for the uniqueId parts depending on the itemType
    if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
        --Add item's trait to the uniqueId?
        if uniqueIdParts.trait == true then
            trait = GetItemLinkTraitInfo(itemLink)
        end
        if trait == nil then trait = 0 end

        --Add item's enchantment to the uniqueId?
        if uniqueIdParts.enchantment == true then
            enchantment = GetItemLinkAppliedEnchantId(itemLink)
        end
        if enchantment == nil then enchantment = 0 end

        --Add item's style to the uniqueId?
        if uniqueIdParts.style == true then
            style = GetItemLinkItemStyle(itemLink)
        end
        if style == nil then style = 0 end

        --Add item's isCrafted state to the uniqueId?
        if uniqueIdParts.isCrafted == true then
            isCrafted = booleanToNumber(IsItemLinkCrafted(itemLink))
            if isCrafted == 1 then
                if uniqueIdParts.isCraftedBy == true then
                    if bagId and slotIndex then
                        craftedByName = GetItemCreatorName(bagId, slotIndex)
                    end
                end
            end
        end
        if isCrafted == nil then isCrafted = 0 end
        if craftedByName == nil then craftedByName = "?"
        else
            craftedByName = HashString(craftedByName) --Create a hash number of the crafter's name
        end
    end

    --Add item's isStolen state to the uniqueId?
    if uniqueIdParts.isStolen == true then
        isStolen = booleanToNumber(IsItemLinkStolen(itemLink))
    end
    if isStolen == nil then isStolen = 0 end
    --------------------------------------------------------------------------------------------------------------------

    --Build the uniqueId string now
    local uniqueItemIdStringTemplate = "%s,%s,%s,%s,%s,%s,%s,%s,%s" -- itemInstanceOrItemId,level,quality,trait,style,enchantment,isStolen,isCrafted,craftedByName
    local uniqueItemIdString
    uniqueItemIdString = string.format(uniqueItemIdStringTemplate, itemId,tostring(level),tostring(quality),tostring(trait),tostring(style),tostring(enchantment),tostring(isStolen),tostring(isCrafted), tostring(craftedByName))

    --------------------------------------------------------------------------------------------------------------------
    --Cache the current values and set the last used type
    FCOIS.CreateFCOISUniqueIdStringLastUnsignedItemInstanceId = itemId
    if bagId ~= nil and slotIndex ~= nil then
        FCOIS.CreateFCOISUniqueIdStringLastBagId        = bagId
        FCOIS.CreateFCOISUniqueIdStringLastSlotIndex    = slotIndex
        FCOIS.CreateFCOISUniqueIdStringLastItemLink     = nil
        FCOIS.CreateFCOISUniqueIdStringLastLastUseType  = 1
    elseif itemLink ~= nil then
        FCOIS.CreateFCOISUniqueIdStringLastItemLink     = itemLink
        FCOIS.CreateFCOISUniqueIdStringLastBagId        = nil
        FCOIS.CreateFCOISUniqueIdStringLastSlotIndex    = nil
        FCOIS.CreateFCOISUniqueIdStringLastLastUseType  = 2
    end
    FCOIS.CreateFCOISUniqueIdStringLastFCOISCreatedUniqueId = uniqueItemIdString
    --------------------------------------------------------------------------------------------------------------------

--d("<"..tostring(uniqueItemIdString) .. ", lastUsedType: " .. tostring(FCOIS.CreateFCOISUniqueIdStringLastLastUseType))
    return uniqueItemIdString
end

--Converts unsigned itemId to signed
--itemId is the itemId, or the itemInstaneId or the itemUniqueId
--allowedItemType is the itemType of the item (e.g. armor, weapon, jewelry) used for the uniqueId checks as non gear icons do not need to be saved with uniqueIds.
--If addonName parameter is given it will check if the temporary use of uniqueIds was enabled for this addon
--and use the unique Id then for the checks (even if the FCOIS settings are not enabled to use uniqueIds).
function FCOIS.SignItemId(itemId, allowedItemType, onlySign, addonName, bagId, slotIndex)
    allowedItemType = allowedItemType or false
    onlySign = onlySign or false
    local itemIDTypeIsString = (type(itemId) == "string") or false

--Attention: Removing the comment in front of the following line will make the game client LAG a lot upon opening the inventory!
--d("[FCOIS.SignItemId] itemId: " ..tostring(itemId) ..", allowedItemType: " .. tostring(allowedItemType) .. ", onlySign: " .. tostring(onlySign) ..", addonName: " ..tostring(addonName))

    --Shall the function not only sign an itemInstanceId, but check if the unique IDs need to be created/checked?
    if not onlySign then
        local settings = FCOIS.settingsVars.settings
        --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids).
        --But only if the itemType was checked before and is an allowed itemtype for the unique ID checks (e.g. armor, weapons)
        --or the itemId is a string (which is the unique ID format)
        if (settings.useUniqueIds == true and allowedItemType == true)
            or checkIfAddonNameHasTemporarilyEnabledUniqueIds(addonName) == true
            or itemIDTypeIsString == true then
            --itemId as string could be the int64UniqueId stored as String (really unique for each item!),
            --or since FCOIS v1.9.6 a , concatenated String of "<unsignedItemInstanceIdOrItemId>,<levelNumber>,<qualityId>,<traitId>,<styleId>,<enchantId>,<isStolen>,<isCrafted>..."
            --If it's not a string: Create one
            if not itemIDTypeIsString then
                local uniqueItemIdType = settings.uniqueItemIdType
                itemId, allowedItemType = GetFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, allowedItemType, settings.useUniqueIds, uniqueItemIdType)
            end
            --Return given string "unique ID" itemId without signing it. UniqueIds do not need a sign!
            return itemId
        end
    end

    --Only sign the itemId if it is a number and if it's a positive value (else it was signed already, or is a uniqueId's String!)
    if itemId and not itemIDTypeIsString and itemId > 0 then
        local SIGNED_INT_MAX = 2^32 / 2 - 1
        local INT_MAX 		 = 2^32
        if itemId > SIGNED_INT_MAX then
            itemId = itemId - INT_MAX
        end
    end
    return itemId
end

--  Check that icon is not sell or sell at guild store
--  and the setting to remove sell/sell at guild store is enabled if any other marker icon is set?
function FCOIS.checkIfOtherDemarksSell(iconId)
    if iconId == nil then return false end
    local settings = FCOIS.settingsVars.settings
    local iconIsDynamic = FCOIS.mappingVars.iconIsDynamic[iconId]
    if iconId ~= FCOIS_CON_ICON_SELL and settings.autoDeMarkSellOnOthers == true then
        --Dynamic exclusion is enabled?
        if settings.autoDeMarkSellOnOthersExclusionDynamic == true then
            return not iconIsDynamic
        end
        return true
    elseif iconId ~= FCOIS_CON_ICON_SELL_AT_GUILDSTORE and settings.autoDeMarkSellGuildStoreOnOthers == true then
        --Dynamic icon exclusion is enabled?
        if settings.autoDeMarkSellGuildStoreOnOthersExclusionDynamic == true then
            return not iconIsDynamic
        end
        return true
    end
    return false
end

--  Check that icon is not deconstruction
--  and the setting to remove deconstruction is enabled if any other marker icon is set?
--  Also check the exclusion of dynamic icons!
function FCOIS.checkIfOtherDemarksDeconstruction(iconId)
    if iconId == nil then return false end
    local settings = FCOIS.settingsVars.settings
    local iconIsDynamic = FCOIS.mappingVars.iconIsDynamic[iconId]
    if iconId ~= FCOIS_CON_ICON_DECONSTRUCTION and settings.autoDeMarkDeconstructionOnOthers == true then
        --Dynamic icon exclusion is enabled?
        if settings.autoDeMarkDeconstructionOnOthersExclusionDynamic == true then
            return not iconIsDynamic
        end
        return true
    end
    return false
end

--Check if all of the item's markers should be removed, if one marker icon "iconId" gets set
function FCOIS.checkIfItemShouldBeDemarked(iconId)
    if iconId == nil then return false end
    local settings = FCOIS.settingsVars.settings
    --Check if all other marker icons should be removed as this marker icon get's set
    if settings.icon[iconId].demarkAllOthers then
        return true
    end
    --Sell icon and remove all other marker icons set
    if (iconId == FCOIS_CON_ICON_SELL and settings.autoDeMarkSell)
            --Sell in guild store icon and remove all other marker icons set
            or	(iconId == FCOIS_CON_ICON_SELL_AT_GUILDSTORE and settings.autoDeMarkSellInGuildStore)
            --Deconstruction
            or 	(iconId == FCOIS_CON_ICON_DECONSTRUCTION and settings.autoDeMarkDeconstruct) then
        return true
    end
    return false
end

--==============================================================================
-- Get control functions
--==============================================================================
--Check as long until the control with the name controlName exists, and then call the function 'callbackFunc' in the 2nd parameter
--The checks will be done every 10ms or every 3rd parameter MS
--This function will automatically abort itsself after 4rd parameter 'autoAbortTimeMS' time in ms has passed. Standard value is 30 seconds
function FCOIS.checkRepetivelyIfControlExists(controlName, callbackFunc, stepTocheckMS, autoAbortTimeMS)
    if not callbackFunc or callbackFunc == nil then return false end
    --Automatically abort this repetively check-function after this time in milliseconds
    autoAbortTimeMS = autoAbortTimeMS or 30000
    --The milliseconds to wait for the next check
    stepTocheckMS = stepTocheckMS or 10
    --Build the event manager uinque control check updater name
    local checkControlname = FCOIS.addonVars.gAddonName .. "___" .. tostring(controlName)
    --Build needed global variables
    if FCOIS.preventerVars.isControlCheckActive[checkControlname] == nil then FCOIS.preventerVars.isControlCheckActive[checkControlname] = false end
    if FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] == nil then FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] = 0 end
    --Get the control by help of it's name
    local control = WINDOW_MANAGER:GetControlByName(controlName, "")
    --Check if control exists
    if control == nil then
        --d("[FCOIS.checkRepetivelyIfControlExists - control " .. tostring(controlName) .. " does not exist so far...")
        --Control does not exist so check again in 10ms (variable -> stepTocheckMS)
        if FCOIS.preventerVars.isControlCheckActive[checkControlname] then
            EVENT_MANAGER:UnregisterForUpdate(checkControlname)
            FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] = FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] + stepTocheckMS
            if FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] >= autoAbortTimeMS then
                --d("°°° [FCOIS.checkRepetivelyIfControlExists - control " .. tostring(controlName) .. " was not found until now. ABORTING after " .. autoAbortTimeMS .. " ms now!!!")
                --d("[FCOIS.checkRepetivelyIfControlExists - ABORTED check " .. checkControlname)
                return false
            end
        else
            FCOIS.preventerVars.isControlCheckActive[checkControlname] = true
            FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] = 0
            --d("[FCOIS.checkRepetivelyIfControlExists - START check " .. checkControlname)
        end
        EVENT_MANAGER:RegisterForUpdate(checkControlname, checkMS, function()
            FCOIS.checkRepetivelyIfControlExists(controlName, callbackFunc, autoAbortTimeMS)
        end)
    else
        --d("[FCOIS.checkRepetivelyIfControlExists - control " .. tostring(controlName) .. " is finally here after " .. FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] .. " ms!")
        --d("[FCOIS.checkRepetivelyIfControlExists - END check " .. checkControlname)
        --Control exists finally!
        EVENT_MANAGER:UnregisterForUpdate(checkControlname)
        FCOIS.preventerVars.isControlCheckActive[checkControlname] = false
        --Execute the callback function now
        --d(">> Running callback function now...")
        callbackFunc()
        return true
    end
end

--Check if a controlName is an inventory row pattern defined in file FCOIS_Constants.lua, table FCOIS.checkVars.inventoryRowPatterns
--Function returns as 1st return value a boolean isAnInventoryRowWithPattern, and as 2nd return value the pattern
function FCOIS.IsSupportedInventoryRowPattern(controlName)
    if not controlName then return false, nil end
    local inventoryRowPatterns = FCOIS.checkVars.inventoryRowPatterns
    if not inventoryRowPatterns then return false, nil end
    for _, patternToCheck in ipairs(inventoryRowPatterns) do
        if controlName:find(patternToCheck) ~= nil then
            return true, patternToCheck
        end
    end
    return false, nil
end
local isSupportedInventoryRowPattern = FCOIS.IsSupportedInventoryRowPattern

--Get the bagid and slotIndex from the item below the mouse cursor.
--And get the control hovered over, the controlType (e.g. Inventory, CraftBag, .. or other addon's UI like Inventory Insigh from Ashes row)
-->Returns bagId, slotIndex, controlBelowMouse, controlTypeBelowMouse
function FCOIS.GetBagAndSlotFromControlUnderMouse()
--d("[FCOIS]GetBagAndSlotFromControlUnderMouse")
    --The control type below the mouse
    local controlTypeBelowMouse = false
    --Get the control below the mouse cursor
    local mouseOverControl = WINDOW_MANAGER:GetMouseOverControl()
    if mouseOverControl == nil then return end
--d("[FCOIS.GetBagAndSlotFromControlUnderMouse] " .. mouseOverControl:GetName())
    local bagId
    local slotIndex
    local itemLink
    local itemInstanceOrUniqueIdIIfA
    FCOIS.IIfAmouseOvered = nil
    local inventoryRowPatterns = FCOIS.checkVars.inventoryRowPatterns
    if inventoryRowPatterns == nil then return end
    --For each inventory row pattern check if the current control mouseOverControl's name matches this pattern
    local mouseOverControlName = mouseOverControl:GetName()
    local otherAddons = FCOIS.otherAddons
    local IIFAitemsListEntryPrePattern = otherAddons.IIFAitemsListEntryPrePattern
    local IIfAInvRowPatternToCheck = "^" .. IIFAitemsListEntryPrePattern .. "*"
--d(">found pattern: " ..tostring(patternToCheck) .. " in row " .. tostring(mouseOverControlName))
    local isInvRow, patternToCheck = isSupportedInventoryRowPattern(mouseOverControlName)
    if isInvRow == true then
        if patternToCheck ~= IIfAInvRowPatternToCheck then
            bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        else
            --Special treatment for the addon InventoryInsightFromAshes
            controlTypeBelowMouse = IIFAitemsListEntryPrePattern
            itemLink, itemInstanceOrUniqueIdIIfA, bagId, slotIndex = FCOIS.checkAndGetIIfAData(mouseOverControl, mouseOverControl:GetParent())
            if bagId == nil or slotIndex == nil and itemInstanceOrUniqueIdIIfA ~= nil then
                FCOIS.IIfAmouseOvered = {}
                FCOIS.IIfAmouseOvered.itemLink = itemLink
                FCOIS.IIfAmouseOvered.itemInstanceOrUniqueId = itemInstanceOrUniqueIdIIfA
            end
        end
    end
--[[
    --if it's a backpack row or child of one -> PRE API 1000015
    if mouseOverControl:GetName():find("^ZO_%a+Backpack%dRow%d%d*") then
        if mouseOverControl:GetName():find("^ZO_%a+Backpack%dRow%d%d*$") then
            bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        else
            mouseOverControl = mouseOverControl:GetParent()
            if mouseOverControl:GetName():find("^ZO_%a+Backpack%dRow%d%d*$") then
                bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
            end
        end
        --if it's a backpack row or child of one -> Since API 1000015
    elseif mouseOverControl:GetName():find("^ZO_%a+InventoryList%dRow%d%d*") then
        if mouseOverControl:GetName():find("^ZO_%a+InventoryList%dRow%d%d*$") then
            bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        else
            mouseOverControl = mouseOverControl:GetParent()
            if mouseOverControl:GetName():find("^ZO_%a+InventoryList%dRow%d%d*$") then
                bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
            end
        end
        --CRAFTBAG: if it's a backpack row or child of one -> Since API 1000015
    elseif mouseOverControl:GetName():find("^ZO_CraftBagList%dRow%d%d*") then
        if mouseOverControl:GetName():find("^ZO_CraftBagList%dRow%d%d*$") then
            bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        else
            mouseOverControl = mouseOverControl:GetParent()
            if mouseOverControl:GetName():find("^ZO_CraftBagList%dRow%d%d*$") then
                bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
            end
        end
        --if it's a RETRAIT station row or child of one -> Since API 1000015
        --ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpack1Row1
    elseif mouseOverControl:GetName():find("^ZO_RetraitStation_%a+RetraitPanelInventoryBackpack%dRow%d%d*") then
        if mouseOverControl:GetName():find("^ZO_RetraitStation_%a+RetraitPanelInventoryBackpack%dRow%d%d*$") then
            bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        else
            mouseOverControl = mouseOverControl:GetParent()
            if mouseOverControl:GetName():find("^ZO_RetraitStation_%a+RetraitPanelInventoryBackpack%dRow%d%d*$") then
                bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
            end
        end
        --Character
    elseif mouseOverControl:GetName():find("^ZO_CharacterEquipmentSlots.+$") then
        bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        --Quickslot
    elseif mouseOverControl:GetName():find("^ZO_QuickSlotList%dRow%d%d*") then
        bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        --Vendor rebuy
    elseif mouseOverControl:GetName():find("^ZO_RepairWindowList%dRow%d%d*") then
        bagId, slotIndex = FCOIS.MyGetItemDetails(mouseOverControl)
        --IIfA support
    elseif mouseOverControl:GetName():find("^" .. FCOIS.otherAddons.IIFAitemsListEntryPrePattern .. "*") then
        controlTypeBelowMouse = FCOIS.otherAddons.IIFAitemsListEntryPrePattern
        itemLink, itemInstanceOrUniqueIdIIfA, bagId, slotIndex = FCOIS.checkAndGetIIfAData(mouseOverControl, mouseOverControl:GetParent())
        if bagId == nil or slotIndex == nil and itemInstanceOrUniqueIdIIfA ~= nil then
            FCOIS.IIfAmouseOvered = {}
            FCOIS.IIfAmouseOvered.itemLink = itemLink
            FCOIS.IIfAmouseOvered.itemInstanceOrUniqueId = itemInstanceOrUniqueIdIIfA
        end
    end
]]
    if bagId ~= nil and slotIndex ~= nil then
        return bagId, slotIndex, mouseOverControl, controlTypeBelowMouse
    else
        return false, nil, mouseOverControl, controlTypeBelowMouse
    end
end

--Get the FCOItemSaver control
-->Check the name of a texture control and see if it exists, then return the control.
--> The control's name is the addon name + a nilable additional parameter "controlNameAddition" + the markerIconId
--> Used to create FCOIS marker icon texture controls with unique names in other addons like Inventory Insight from Ashes (IIfA)!
function FCOIS.GetItemSaverControl(parent, controlId, useParentFallback, controlNameAddition)
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[GetItemSaverControl]","Parent: " .. parent:GetName() .. ", ControlId: " .. tostring(controlId) .. ", useParentFallback: " .. tostring(useParentFallback), true, FCOIS_DEBUG_DEPTH_ALL) end
    local textureNameAddition = ""
    if controlNameAddition ~= nil then
        textureNameAddition = controlNameAddition
    end
    local retControl = parent:GetNamedChild(FCOIS.addonVars.gAddonName .. textureNameAddition .. tostring(controlId))

    --Use the parent control as a fallback?
    if useParentFallback == true then
        --e.g. Inside enchanting the parent control is the correct one already
        if (retControl == nil) then
            retControl = parent
        end
    end
    return retControl
end

function FCOIS.MyGetItemNameNoControl(bagId, slotIndex)
    local name = "Not found"
    local itemData
    local bagIdToPlayerInv = FCOIS.mappingVars.bagToPlayerInv
    local playerInvId = bagIdToPlayerInv[bagId]
    if playerInvId == nil then return name end
    --CraftBag?
    if playerInvId == INVENTORY_CRAFT_BAG then
        local itemId = GetItemId(bagId, slotIndex)
        if itemId == nil or itemId == 0 then itemId = slotIndex end
        itemData = PLAYER_INVENTORY.inventories[playerInvId].slots[BAG_VIRTUAL][itemId] --slotIndex is the itemId of the item, not the inv slotIndex!
    else
        itemData = PLAYER_INVENTORY.inventories[playerInvId].slots[bagId][slotIndex]
    end
    if(itemData ~= nil) then
        name = itemData.name
    end
    return name
end

function FCOIS.MyGetItemName(rowControl)
    --Inventory Insight from ashes support
    if FCOIS.IIfAclicked ~= nil then
        return GetItemName(FCOIS.IIfAclicked.bagId, FCOIS.IIfAclicked.slotIndex)
    end
    local name
    if (rowControl == nil) then return end
    local dataEntry = rowControl.dataEntry

    --case to handle equiped items
    if(not dataEntry) then
        name = rowControl.name
    else
        name = dataEntry.data.name
    end
    return name
end

function FCOIS.MyGetItemDetails(rowControl)
    --Inventory Insight from ashes support
    if FCOIS.IIfAclicked ~= nil then
        return FCOIS.IIfAclicked.bagId, FCOIS.IIfAclicked.slotIndex
    end
    local bagId, slotIndex

    --gotta do this in case deconstruction, or player equipment
    local dataEntry = rowControl.dataEntry

    --case to handle equiped items
    if(not dataEntry) then
        bagId = rowControl.bagId
        slotIndex = rowControl.slotIndex
    else
        bagId = dataEntry.data.bagId
        slotIndex = dataEntry.data.slotIndex
    end

    --case to handle list dialog, list dialog uses index instead of slotIndex and bag instead of bagId...?
    if(dataEntry and not bagId and not slotIndex) then
        bagId = rowControl.dataEntry.data.bag
        slotIndex = rowControl.dataEntry.data.index
    end

    return bagId, slotIndex
end

function FCOIS.MyGetItemDetailsByBagAndSlot(bagId, slotIndex)
    if bagId == nil or slotIndex == nil then return false end
    --Get the dataEntry / data from the bag cache
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
    if bagCache ~= nil and bagCache[slotIndex] ~= nil then
        return bagCache[slotIndex]
    end
    return nil
end

--==============================================================================
-- is Item functions
--==============================================================================
function FCOIS.isItemType(bag, slot, itemTypes)
    if not itemTypes then return false end
    local isItemTypeVar
    if type(itemTypes) == "table" then
        for _, itemType in ipairs(itemTypes) do
            isItemTypeVar = (GetItemType(bag, slot) == itemType)
            if isItemTypeVar == true then return true end
        end
    else
        return (GetItemType(bag, slot) == itemTypes)
    end
    return false
end

function FCOIS.isItemAGlpyh(bag, slot)
    if bag == nil or slot == nil then return false end
    local isArmorGlyph		= (GetItemType(bag, slot) == ITEMTYPE_GLYPH_ARMOR)
    local isJewelryGlyph	= (GetItemType(bag, slot) == ITEMTYPE_GLYPH_JEWELRY)
    local isWeaponGlyph		= (GetItemType(bag, slot) == ITEMTYPE_GLYPH_WEAPON)
    local resultVar = (isArmorGlyph or isJewelryGlyph or isWeaponGlyph)
    --d("[FCOIS.isItemAGlpyh - isArmorGlyph: ".. tostring(isArmorGlyph) .. ", isJewelryGlyph: " .. tostring(isJewelryGlyph) .. ", isWeaponGlyph: " .. tostring(isWeaponGlyph) .. " - return: " .. tostring(resultVar))
    return resultVar
end

--Check if an item is already bound to your account
function FCOIS.isItemAlreadyBound(bagId, slotIndex)
    --Only check bound set parts
    local itemType = GetItemType(bagId, slotIndex)
    local isAllowedItemType = FCOIS.checkVars.allowedSetItemTypes[itemType]
    if not isAllowedItemType then return false end
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink then
        --Is the item bound?
        return  IsItemLinkBound(itemLink)
    else
        return nil
    end
end

--Check if an item could be bound
function FCOIS.isItemBindableAtAll(bagId, slotIndex)
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink then
        --Is item a bindable type
        local bindType = GetItemLinkBindType(itemLink)
        if(bindType ~= BIND_TYPE_NONE and bindType ~= BIND_TYPE_UNSET) then
            --Item can still be bound
            return true
        else
            --Item is no bindable type
            return false
        end
    else
        return nil
    end
end

--Check if an item is already bound
function FCOIS.isItemBound(bagId, slotIndex)
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink then
        --Bound?
        return IsItemLinkBound(itemLink)
    else
        return nil
    end
end

--Check if an item can be bound to your account and if it is not already bound
function FCOIS.isItemBindable(bagId, slotIndex)
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink then
        --Bound
        local isBound = FCOIS.isItemBound(bagId, slotIndex) or false
        if(isBound) then
            --Item is already bound
            return false
        else
            return FCOIS.isItemBindableAtAll(bagId, slotIndex) or false
        end
    else
        return nil
    end
end

--Is the item a container and is autoloot enabled in the ESO settings
function FCOIS.isAutolootContainer(bag, slot)
    return (GetItemType(bag, slot) == ITEMTYPE_CONTAINER and GetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT)=="1")
end

--Function to check it the item is a soulgem
function FCOIS.isSoulGem(bagId, slotIndex)
    if bagId == nil or slotIndex == nil then return nil end
    local isSoulGem = (GetSoulGemItemInfo(bagId, slotIndex) > 0) or false
    if not isSoulGem then
        --Special check for crown store soul gems as GetSoulGemItemInfo returns 0 for them...
        local itemType, specializedItemType = GetItemType(bagId, slotIndex)
        if itemType == ITEMTYPE_SOUL_GEM and specializedItemType == SPECIALIZED_ITEMTYPE_SOUL_GEM then isSoulGem = true end
    end
    return isSoulGem
end

--Is the item a recipe and is it known by one of your chars? Boolean expectedResult will give the
--true (known recipe) or false (unknown recipe) parameter
function FCOIS.isRecipeKnown(bagId, slotIndex, expectedResult)
    expectedResult = expectedResult or false
    --Check if any recipe addon is used and available
    if not FCOIS.checkIfRecipeAddonUsed() then return nil end
    --Get the recipe addon used to check for known/unknown state
    local recipeAddonUsed = FCOIS.getRecipeAddonUsed()
    if recipeAddonUsed == nil or recipeAddonUsed == "" then return nil end
    --Get the itemLink
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink == "" then return nil end
    -- item is a recipe
    if GetItemLinkItemType(itemLink) ~= ITEMTYPE_RECIPE then return nil end
    local settingsBase = FCOIS.settingsVars
    local settings = settingsBase.settings
    local useAccountWideSettings = (settingsBase.defaultSettings.saveMode == 2) or false
    local autoMarkRecipesOnlyThisChar = settings.autoMarkRecipesOnlyThisChar
    --local recipeUnknownIconNr = settings.autoMarkRecipesIconNr
    --local recipeKnownIconNr = settings.autoMarkKnownRecipesIconNr
    local currentCharName = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName("player"))
    local currentCharId = tostring(GetCurrentCharacterId())
    local known

    if settings.debug then FCOIS.debugMessage("isRecipeKnown", GetItemLink(bagId, slotIndex) .. ", expectedResult: " ..tostring(expectedResult) .. ", recipeAddonUsed: " ..tostring(recipeAddonUsed) .. ", autoMarkRecipesOnlyThisChar: " ..tostring(autoMarkRecipesOnlyThisChar), true, FCOIS_DEBUG_DEPTH_SPAM, false) end
--d("[FCOIS]isRecipeKnown ".. GetItemLink(bagId, slotIndex) .. ", expectedResult: " ..tostring(expectedResult) .. ", recipeAddonUsed: " ..tostring(recipeAddonUsed) .. ", autoMarkRecipesOnlyThisChar: " ..tostring(autoMarkRecipesOnlyThisChar))

    --SousChef
    if recipeAddonUsed == FCOIS_RECIPE_ADDON_SOUSCHEF then
--d(">using SousChef")
        --Get recipe info from Sous Chef addon
        if SousChef and SousChef.settings and SousChef.settings.showAltKnowledge and SousChef.settings.Cookbook and SousChef.Utility then
            local resultLink = GetItemLinkRecipeResultItemLink(itemLink)
            local knownByUsersTable = SousChef.settings.Cookbook[SousChef.Utility.CleanString(GetItemLinkName(resultLink))]
--FCOIS._knownByUsersTable = knownByUsersTable
            if knownByUsersTable ~= nil then
                local currentCharacterName = ""
                if autoMarkRecipesOnlyThisChar == true then
                    --Only check if recipe is known for the current character?
                    currentCharacterName = currentCharId
                else
                    --Check if recipe is known for your main provisioning character
                    local recipeMainChar = SousChef.settings.mainChar
                    if recipeMainChar == "(current)" then
                        recipeMainChar = currentCharId
                    end
                    currentCharacterName = recipeMainChar
                end
                if currentCharacterName and currentCharacterName ~= "(current)" and currentCharacterName ~= "" then
                    known = knownByUsersTable[currentCharacterName] or false
                end
            else
                --Not known yet by any char!
                return false
            end
            return known
        end
        ------------------------------------------------------------------------------------------------------------------------
        --CraftStoreFixedAndImproved
    elseif recipeAddonUsed == FCOIS_RECIPE_ADDON_CSFAI then
--d("CraftStoreFixedAndImproved is used for recipes")
        --Get recipe info from Sous Chef addon
        if CraftStoreFixedAndImprovedLongClassName ~= nil and CraftStoreFixedAndImprovedLongClassName.IsLearnable ~= nil then
            --Data is returned as a table in the format of [index] = {[1] = name, [2] = can be learned}
            local knownByUsersTable = CraftStoreFixedAndImprovedLongClassName.IsLearnable(itemLink, autoMarkRecipesOnlyThisChar)
--FCOIS._knownByUsersTable = knownByUsersTable
            local knownLoop
            local isCraftStoreMainCrafterCharSet = false
            if knownByUsersTable ~= nil then
                local currentCharacterName = ""
                if autoMarkRecipesOnlyThisChar then
                    --Only check if recipe is known for the current character?
                    currentCharacterName = currentCharName
                else
                    --Check if recipe is known for your main character. As CraftStore can only select 1 main char at the
                    --character selection list (right click a char to set it as main) we will check this char.
                    -->If no main char was selected all other chars will be checked!
                    local recipeMainChar = CraftStoreFixedAndImprovedLongClassName.Account.mainchar
                    if recipeMainChar == false then
                        recipeMainChar = ""
                    else
                        isCraftStoreMainCrafterCharSet = true
                    end
--FCOIS._recipeMainChar = recipeMainChar
                    currentCharacterName = recipeMainChar
                end
--FCOIS._currentCharacterName = currentCharacterName
                if currentCharacterName ~= nil then
                    --Read table with characternames
                    --table is in the format of [index] = {[1] = String name, [2] = boolean canBeLearned}
                    for _, knownDataOfChar in ipairs(knownByUsersTable) do
                        local needsAccountWideSettings = false
                        local charToCheck = knownDataOfChar[1]
                        --Check if another char is able to learn the recipe
                        if charToCheck ~= currentCharName then
                            needsAccountWideSettings = true
                        end
                        local isCraftStoreMainCrafterChar = (isCraftStoreMainCrafterCharSet and charToCheck == currentCharacterName) or false
                        --Is the recipe know or unknown to the char?
                        local isLearnable = knownDataOfChar[2]
                        knownLoop = not isLearnable

--d(">>checking char:  " ..tostring(charToCheck) .. ", isCraftStoreMainCrafterChar: " ..tostring(isCraftStoreMainCrafterChar) .. ", knownLoop: " ..tostring(knownLoop))
                        --Is the expected result already the knownState of the recipe at this char? Then go on with the
                        --next char
                        if expectedResult ~= isLearnable then
                            --Is the char the crafter main char? Or wasn't any main crafter set
                            --If autoMarkRecipesOnlyThisChar == true then the table only got 1 line with the current character!
                            if autoMarkRecipesOnlyThisChar then
    --d("<<onlyThisChar -> knownLoop: " ..tostring(knownLoop))
                                --Return the first line's known entry
                                return knownLoop
                            else
                                --Is the main Crafter set? Then only check his/her recipe's known/unknown state
                                local goOn = true
                                if isCraftStoreMainCrafterCharSet == true then
--d(">>main crafter char is set")
                                    goOn = isCraftStoreMainCrafterChar
                                end
--d(">>>goOn: " ..tostring(goOn))
                                if goOn == true then
                                    --Mark it for the other char, but only possible if account wide settings are enabled!
                                    --And if the expected result of this function call equals the "known state" of the recipe
                                    if needsAccountWideSettings == false or (needsAccountWideSettings == true and useAccountWideSettings == true) then
                                        --Should an unkown recipe be marked and is the recipe not known for the current char in the loop?
                                        if expectedResult == false and knownLoop == false then
        --d(">>>>>marking item as UNknown recipe!")
                                            --Mark the item now as it can be learned on another char!
                                            --FCOIS.MarkItem(bagId, slotIndex, recipeUnknownIconNr)
                                            --Abort the loop over the chars now as acount wide settings are enabled and the
                                            --recipe was marked, or it was the currently logged in char
                                            return false
                                            --Should a known recipe be marked?
                                        elseif expectedResult == true and knownLoop == true then
        --d(">>>>>marking item as known recipe!")
                                            --Mark the item now as it can be learned on another char!
                                            --FCOIS.MarkItem(bagId, slotIndex, recipeKnownIconNr)
                                            --Abort the loop over the chars now as acount wide settings are enabled and the
                                            --recipe was marked, or it was the currently logged in char
                                            return true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return nil
end

--Check if the recipe addon chosen is active, the marker icon too and the setting to automark it is enabled
function FCOIS.isRecipeAutoMarkDoable(checkIfSettingToAutoMarkIsEnabled, knownRecipesIconCheck, doIconCheck)
    checkIfSettingToAutoMarkIsEnabled = checkIfSettingToAutoMarkIsEnabled or false
    knownRecipesIconCheck = knownRecipesIconCheck or false
    doIconCheck = doIconCheck or false
    local settings = FCOIS.settingsVars.settings
    local retVar = false
    local iconCheck
    if doIconCheck then
        if knownRecipesIconCheck then
            iconCheck = settings.isIconEnabled[settings.autoMarkKnownRecipesIconNr]
        else
            iconCheck = settings.isIconEnabled[settings.autoMarkRecipesIconNr]
        end
    end
    local isRecipeAutoMarkPrerequisites = (FCOIS.checkIfRecipeAddonUsed() and FCOIS.checkIfChosenRecipeAddonActive(settings.recipeAddonUsed)) or false
    if doIconCheck and isRecipeAutoMarkPrerequisites then
        isRecipeAutoMarkPrerequisites = (isRecipeAutoMarkPrerequisites and iconCheck) or false
    end
    if checkIfSettingToAutoMarkIsEnabled and knownRecipesIconCheck then
        retVar = isRecipeAutoMarkPrerequisites and (settings.autoMarkRecipes or settings.autoMarkKnownRecipes)
    elseif checkIfSettingToAutoMarkIsEnabled and not knownRecipesIconCheck then
        retVar = isRecipeAutoMarkPrerequisites and settings.autoMarkRecipes
    elseif not checkIfSettingToAutoMarkIsEnabled and knownRecipesIconCheck then
        retVar = isRecipeAutoMarkPrerequisites and settings.autoMarkKnownRecipes
    else
        retVar = isRecipeAutoMarkPrerequisites
    end
    return retVar
end

--Is the item a set part?
function FCOIS.isItemSetPartNoControl(bagId, slotIndex)
    local retVal = false
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink ~= "" then
        -- Get the item's type
        local itemType = GetItemLinkItemType(itemLink)
        if itemType ~= nil then
            local allowedItemTypes = FCOIS.checkVars.allowedSetItemTypes
            local allowed = allowedItemTypes[itemType] or false
            if allowed then
                --Get the set item information
                local hasSet, _, _, _, _ = GetItemLinkSetInfo(itemLink)
                retVal = hasSet
            end
        end
    end
    return retVal
end

--Is the item a set part and got some selected traits (chosen in the addon's "automatic marking" -> "sets" settings)?
function FCOIS.isItemSetPartWithTraitNoControl(bagId, slotIndex)
--d("FCOIS.isItemSetPartWithTraitNoControl")
    local isSetPartWithWishedTrait = false
    local isSetPartAndIsValidAndGotTrait = false
    local isSet = false
    local setPartTraitIcon
    local settings = FCOIS.settingsVars.settings
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink ~= "" then
--d(">Item: " .. itemLink)
        local itemType = GetItemLinkItemType(itemLink)
        -- Get the item's type
        if itemType ~= nil then
--d(">itemType: " ..tostring(itemType))
            local allowedItemTypes = FCOIS.checkVars.allowedSetItemTypes
            local allowed = allowedItemTypes[itemType] or false
            if allowed then
--d(">allowed")
                --Get the set item information
                local hasSet = GetItemLinkSetInfo(itemLink)
                -- item is a set
                if hasSet then
                    isSet = true
--d(">has set")
                    --Check the item's trait now, according to it's item type
                    --[[
                        * GetItemLinkTraitInfo(*string* _itemLink_)
                        ** _Returns:_ *[ItemTraitType|#ItemTraitType]* _traitType_, *string* _traitDescription_, *integer* _traitSubtype_, *string* _traitSubtypeName_, *string* _traitSubtypeDescription_
                    ]]
                    local itemTraitType = GetItemLinkTraitInfo(itemLink)
                    if itemTraitType ~= nil then
--d(">itemTraitType: " ..tostring(itemTraitType))
                        --Armor / Jewelry
                        if itemType == ITEMTYPE_ARMOR then
                            --Distinguish between armor and jewelry by checking the equip type
                            --[[
                                * EQUIP_TYPE_NECK
                                * EQUIP_TYPE_RING
                                * GetItemLinkInfo(*string* _itemLink_)
                                ** _Returns:_ *string* _icon_, *integer* _sellPrice_, *bool* _meetsUsageRequirement_, *integer* _equipType_, *integer* _itemStyle_
                            ]]
                            local _, _, _, equipType = GetItemLinkInfo(itemLink)
                            if equipType ~= nil then
                                if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
                                    --Jewelry
                                    if settings.autoMarkSetsCheckJewelryTrait[itemTraitType] ~= nil then
                                        isSetPartWithWishedTrait = settings.autoMarkSetsCheckJewelryTrait[itemTraitType]
                                        if isSetPartWithWishedTrait then
                                            setPartTraitIcon = settings.autoMarkSetsCheckJewelryTraitIcon[itemTraitType] or nil
                                        end
                                        isSetPartAndIsValidAndGotTrait = true
                                    end
                                else
                                    --Armor
                                    if settings.autoMarkSetsCheckArmorTrait[itemTraitType] ~= nil then
                                        isSetPartWithWishedTrait = settings.autoMarkSetsCheckArmorTrait[itemTraitType]
                                        if isSetPartWithWishedTrait then
                                            setPartTraitIcon = settings.autoMarkSetsCheckArmorTraitIcon[itemTraitType] or nil
                                        end
                                        isSetPartAndIsValidAndGotTrait = true
                                    end
                                end
                            end
                            --Weapon or shields
                        elseif itemType == ITEMTYPE_WEAPON then
                            if settings.autoMarkSetsCheckWeaponTrait[itemTraitType] ~= nil then
                                isSetPartWithWishedTrait = settings.autoMarkSetsCheckWeaponTrait[itemTraitType]
                                if isSetPartWithWishedTrait then
                                    setPartTraitIcon = settings.autoMarkSetsCheckWeaponTraitIcon[itemTraitType] or nil
                                end
                                isSetPartAndIsValidAndGotTrait = true
                            end
                        end
                    end -- if itemTraitType ~= nil then
                end -- if hasSet then
            end -- if allowed then
        end -- if itemType ~= nil then
    end -- if itemLink ~= "" then
    return isSetPartWithWishedTrait, isSetPartAndIsValidAndGotTrait, setPartTraitIcon, isSet
end

--Function used in FCOIS.isItemLinkResearchable() and FCOIS.isItemResearchableNoControl()
local function isResearchableItemTypeCheck(itemType, markId)
    local retVal = false
    local allowedTab = {}
    local checkVars = FCOIS.checkVars
    allowedTab = checkVars.allowedResearchableItemTypes[itemType]
    if allowedTab == nil then return false end
    if markId == nil then
        retVal = allowedTab.allowed and not allowedTab.isGlpyh
    else
        if allowedTab.allowedIcons == nil then
            --All icons are allowed for this item type
            if allowedTab.allowed then
                retVal = true
            end
        else
            --Only some of the marker icons are allowed to use for this item type (e.g. glyphs are only allowed to be marked with the deconstruction icon)
            if allowedTab.allowed and allowedTab.allowedIcons[markId] then
                retVal = true
            end
        end
    end
    return retVal
end

-- Check if an itemLink is researchable
function FCOIS.isItemLinkResearchable(itemLink, markId, doTraitCheck)
    if itemLink == nil then return false end
    local retVal = false
    doTraitCheck = doTraitCheck or false
    --Check if the item is virtually researchable as the settings is enabled to allow marking of non researchable items as gear/dynamic
    markId = markId or nil
    if markId ~= nil then
        local settings = FCOIS.settingsVars.settings
        retVal = settings.disableResearchCheck[markId] or false
    end
    --Check the item's type (Armor, weapon, jewelry e.g. are researchable)
    if retVal == false then
        local itemType = GetItemLinkItemType(itemLink)
        if itemType == nil then return false end
        retVal = isResearchableItemTypeCheck(itemType, markId)
    end
    --Check the item's trait (no trait-> No research)
    if retVal == true and doTraitCheck then
        local itemTraitType = GetItemLinkTraitInfo(itemLink)
        local itemTraiTypesNotAllowedForResearch = FCOIS.checkVars.researchTraitCheckTraitsNotAllowed
        local itemTraitTypeNotAllowedForResearch = itemTraiTypesNotAllowedForResearch[itemTraitType] or false
        if itemTraitType == nil or itemTraitTypeNotAllowedForResearch then return false end
    end
--d("[FCOIS.isItemLinkResearchable] retVal: " .. tostring(retVal))
    return retVal
end

-- Is the item researchable?
function FCOIS.isItemResearchableNoControl(bagId, slotIndex, markId, doTraitCheck)
    if bagId == nil or slotIndex == nil then return false end
    --Check if the item is virtually researchable as the settings is enabled to allow marking of non-researchable items as gear/dynamic
    markId = markId or nil
    local itemLink = GetItemLink(bagId, slotIndex)
    local retVal = FCOIS.isItemLinkResearchable(itemLink, markId, doTraitCheck)
--d("[FCOIS.isItemResearchableNoControl] retVal: " .. tostring(retVal))
    return retVal
end

-- Is the item researchable?
function FCOIS.isItemResearchable(p_rowControl, markId, doTraitCheck)
    if p_rowControl == nil then return false end
    local bag, slotIndex
    local retVal = false
    local IIfArowControlCheck = (FCOIS.IIfAclicked ~= nil) or false
--d("[FCOIS.isItemResearchable] " ..tostring(p_rowControl:GetName()) .. ", markId: " ..tostring(markId) .. ", IIfArowCheck: " ..tostring(IIfArowControlCheck))
    --Inventory Insight from ashes support
    if IIfArowControlCheck then
        bag, slotIndex = FCOIS.IIfAclicked.bagId, FCOIS.IIfAclicked.slotIndex
    else
        bag, slotIndex = FCOIS.MyGetItemDetails(p_rowControl)
    end
    local itemLink
    if bag == nil or slotIndex == nil then
        --Was a row in IIfA inventory frame clicked and does function FCOIS.AddMark check if the item is researchable now?
        if IIfArowControlCheck then
            --Get the itemLink of the clicked item from the IIfA rowcontrol
            itemLink = FCOIS.IIfAclicked.itemLink
        end
    else
        itemLink = GetItemLink(bag, slotIndex)
    end
    if itemLink ~= nil then
        retVal = FCOIS.isItemLinkResearchable(itemLink, markId, doTraitCheck)
    end
    return retVal
end

-- Is the item an ornate one?
function FCOIS.isItemOrnate(bagId, slotIndex)
    local isOrnate = false
    local itemTrait = GetItemTrait(bagId, slotIndex)
    local allowedOrnateItemTraits = FCOIS.checkVars.allowedOrnateItemTraits
    isOrnate = allowedOrnateItemTraits[itemTrait] or false
--local itemLink = GetItemLink(bagId, slotIndex)
--d("[FCOIS]isItemOrnate: " .. itemLink .. " -> " .. tostring(isOrnate))
    return isOrnate
end

-- Is the item an intricate one?
function FCOIS.isItemIntricate(bagId, slotIndex)
    local isIntricate = false
    local allowedIntricateItemTraits = FCOIS.checkVars.allowedIntricateItemTraits
    local itemTrait = GetItemTrait(bagId, slotIndex)
    isIntricate = allowedIntricateItemTraits[itemTrait] or false
--local itemLink = GetItemLink(bagId, slotIndex)
--d("[FCOIS]isItemIntricate: " .. itemLink .. " -> " .. tostring(isIntricate))
    return isIntricate
end

--Check if the item is a "super item" (special enchantment with set bonus!
function FCOIS.isItemSuperitem(bagId, slotIndex)
    if bagId == nil or slotIndex == nil then return false end
    local itemLink = GetItemLink(bagId, slotIndex)
    local hasSet, _, numBonuses = GetItemLinkSetInfo(itemLink, false)
    if hasSet and numBonuses == 1 then
        -- Superitem
        return true
    end
    return false
end

--Are we deconstructing, improving, extracting an item, and not creating it at any craft station?
function FCOIS.isNotCreatingCraftItem()
    local isNotCreatingCraftItem = false
    if ZO_CraftingUtils_IsCraftingWindowOpen() then
        --Smithing
        if not ctrlVars.SMITHING_PANEL:IsHidden() then
            if ctrlVars.SMITHING.mode == nil or ctrlVars.SMITHING.mode ~= SMITHING_MODE_CREATION then
                isNotCreatingCraftItem = true
            end
            --Enchanting
        elseif not ctrlVars.ENCHANTING_STATION:IsHidden() then
            if ctrlVars.ENCHANTING.enchantingMode == nil or ctrlVars.ENCHANTING.enchantingMode ~= ENCHANTING_MODE_CREATION then
                isNotCreatingCraftItem = true
            end
            --Alchemy
        elseif not ctrlVars.ALCHEMY_INV:IsHidden() then
            if ctrlVars.ALCHEMY.mode == nil or ctrlVars.ALCHEMY.mode ~= ZO_ALCHEMY_MODE_CREATION then
                isNotCreatingCraftItem = true
            end
            --Provisioning
        elseif not ctrlVars.PROVISIONER_PANEL:IsHidden() then
            --Provisioner can only create (cook/brew)
            isNotCreatingCraftItem = false
        end
    else
        isNotCreatingCraftItem = true
    end
--d("[FCOIS]isNotCreatingCraftItem - result: " .. tostring(isNotCreatingCraftItem))
    return isNotCreatingCraftItem
end

--Check if the LibFilters panelId is a panel Id which allows deconstruction
function FCOIS.checkIfFilterPanelIsDeconstructable(panelId)
    panelId = panelId or FCOIS.gFilterWhere
    if panelId == nil then return nil end
    local deconstructablePanels = FCOIS.mappingVars.panelIdToDeconstructable
    local panelIsDeconstructable = deconstructablePanels[panelId] or false
    return panelIsDeconstructable
end

--Check if the writ or non-writ item is crafted and should be marked wih the "crafted" marker icon
function FCOIS.isWritOrNonWritItemCraftedAndIsAllowedToBeMarked()
    --d("[FCOIS]isWritOrNonWritItemCraftedAndIsAllowedToBeMarked")
    local retVar = false
    local craftMarkerIcon
    local settings = FCOIS.settingsVars.settings
    local preventerVars = FCOIS.preventerVars
    local isWritAddonCreatedItem = preventerVars.writCreatorCreatedItem
    if settings.autoMarkCraftedItems or (isWritAddonCreatedItem) then
        --Check which icon should be used (Normal "crafted" or "WritCreater" icon
        local craftedItemMarkerIcons = {
            ["normal"] = settings.autoMarkCraftedItemsIconNr,
        }
        local writCreatorMarkerIcons = {
            [true]  = settings.autoMarkCraftedWritCreatorMasterWritItemsIconNr,
            [false] = settings.autoMarkCraftedWritCreatorItemsIconNr,
        }
        --Standard crafted item marker icon
        craftMarkerIcon = craftedItemMarkerIcons["normal"]
        if isWritAddonCreatedItem then
            craftMarkerIcon = writCreatorMarkerIcons[preventerVars.writCreatorIsMasterWrit]
        end
        --Is the needed icon enabled?
        if not settings.isIconEnabled[craftMarkerIcon] then return false, nil end
        retVar = true
    end
    --d("<retVar: " .. tostring(retVar) .. ", craftMarkerIcon: " .. tostring(craftMarkerIcon))
    return retVar, craftMarkerIcon
end

--==============================================================================
-- Is dialog functions
--==============================================================================

--Is the research list dialog shown?
function FCOIS.isResearchListDialogShown()
    local listDialog = ZO_InventorySlot_GetItemListDialog()
    if listDialog == nil or listDialog.control == nil or listDialog.control.data == nil then return false end
    local data = listDialog.control.data
    if data.owner == nil or data.owner.control == nil then return false end
    return not listDialog.control:IsHidden() and data.owner.control == ctrlVars.RESEARCH
end

--Is the repair item dialog shown?
function FCOIS.isRepairDialogShown()
    local isRepairDialogShown = false
    local repairDialog = FCOIS.ZOControlVars.RepairItemDialog
    --Fastest detection: Use the title of the dialog! The other both methods seem to need a small delay before the dialog data/control is updated :-(
    if repairDialog ~= nil then
        isRepairDialogShown = (repairDialog.info and repairDialog.info.title and repairDialog.info.title.text and repairDialog.info.title.text == FCOIS.ZOControlVars.RepairItemDialogTitle) or false
    else
        isRepairDialogShown = ZO_Dialogs_IsShowing(ctrlVars.RepairItemDialogName)
        if not isRepairDialogShown then
            local repairKits = FCOIS.ZOControlVars.RepairKits
            if repairKits and repairKits.control then
                isRepairDialogShown = not repairKits.control:IsHidden()
            end
        end
    end
    return isRepairDialogShown
end

--==============================================================================
-- Dialog functions
--==============================================================================
--Function to change the button #  state and keybind of a dialog now
function FCOIS.changeDialogButtonState(dialog, buttonNr, stateBool)
--d("[FCOIS]changeDialogButtonState-dialog: " ..tostring(dialog) .. ", button: " ..tostring(buttonNr) .. ", stateBool: " ..tostring(stateBool))
    if not dialog or not buttonNr then return end
    stateBool = stateBool or false
    --WINDOW_MANAGER:GetControlByName(ctrlVars.RepairItemDialog, "Button" .. tostring(buttonNr)):SetEnabled(enableResearchButton)
    -- Activate or deactivate a button...use BSTATE_NORMAL to activate and BSTATE_DISABLED to deactivate
    local buttonState = (stateBool and BSTATE_NORMAL) or BSTATE_DISABLED
    ZO_Dialogs_UpdateButtonState(dialog, 1, buttonState)
    local buttonControl = ctrlVars.RepairItemDialog:GetNamedChild("Button" .. tostring(buttonNr))
    if buttonControl and buttonControl.SetKeybindEnabled then buttonControl:SetKeybindEnabled(stateBool) end
end

--==============================================================================
-- Get Item functions
--==============================================================================
function FCOIS.GetItemQuality(bagId, slotIndex)
    --get the item link
    local itemLink = GetItemLink(bagId, slotIndex)
    if itemLink == nil then return false end
    -- Gets the item quality
    local itemQuality = GetItemLinkFunctionalQuality(itemLink)
    if not itemQuality then return false end
    return itemQuality
end

--Check which marker icons should be removed, if this marker icon gets set
function FCOIS.getIconsToRemove(bag, slot, itemInstanceOrUniqueId, curentlyCheckedIconId, demarksSell, demarksDecon)
    if (bag == nil or slot==nil) and itemInstanceOrUniqueId == nil then return end
    local iconsToRemove = {}
    local settings = FCOIS.settingsVars.settings
    demarksSell = demarksSell or FCOIS.checkIfOtherDemarksSell(curentlyCheckedIconId)
    demarksDecon = demarksDecon or FCOIS.checkIfOtherDemarksDeconstruction(curentlyCheckedIconId)
    if demarksSell == true then
        if settings.autoDeMarkSellOnOthers == true and (
                (bag and slot and FCOIS.IsMarked(bag, slot, { FCOIS_CON_ICON_SELL }))
            or  (itemInstanceOrUniqueId and FCOIS.IsMarkedByItemInstanceId(itemInstanceOrUniqueId, { FCOIS_CON_ICON_SELL }))
        ) then
            iconsToRemove[FCOIS_CON_ICON_SELL] = FCOIS_CON_ICON_SELL
        end
        if settings.autoDeMarkSellGuildStoreOnOthers == true and (
               (bag and slot and FCOIS.IsMarked(bag, slot, { FCOIS_CON_ICON_SELL_AT_GUILDSTORE }))
            or (itemInstanceOrUniqueId and FCOIS.IsMarkedByItemInstanceId(itemInstanceOrUniqueId, { FCOIS_CON_ICON_SELL_AT_GUILDSTORE }))
        ) then
            iconsToRemove[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = FCOIS_CON_ICON_SELL_AT_GUILDSTORE
        end
    end
    if demarksDecon == true then
        if settings.autoDeMarkDeconstructionOnOthers == true and (
                (bag and slot and FCOIS.IsMarked(bag, slot, { FCOIS_CON_ICON_DECONSTRUCTION }))
                or (itemInstanceOrUniqueId and FCOIS.IsMarkedByItemInstanceId(itemInstanceOrUniqueId, { FCOIS_CON_ICON_DECONSTRUCTION }))
        ) then
            iconsToRemove[FCOIS_CON_ICON_DECONSTRUCTION] = FCOIS_CON_ICON_DECONSTRUCTION
        end
    end
    --Return the marker icon ids now, that should be removed
    return iconsToRemove
end


--======================================================================================================================
-- Get "active" functions
--======================================================================================================================
--Function to get the active inventory bagId by help of the libFilters 2.0 filter panel ID
function FCOIS.GetActiveBagIdByFilterPanelId(filterPanelId)
    filterPanelId = filterPanelId or FCOIS.gFilterWhere
    if filterPanelId == nil or filterPanelId == 0 then
--d("[FCOIS]GetActiveBagIdByFilterPanelId, filterPanelId: " ..tostring(filterPanelId) .. " -> ERROR!")
        return nil
    end
    local filterPanelIdToBagId = FCOIS.mappingVars.libFiltersId2BagId
    local activeBagId = filterPanelIdToBagId[filterPanelId] or nil
--d("[FCOIS]GetActiveBagIdByFilterPanelId, filterPanelId: " ..tostring(filterPanelId) .. ", bagId: " ..tostring(activeBagId))
    return activeBagId
end

--Get the inventory type by help of the inventory's bagId
function FCOIS.GetActiveInventoryTypeByBagId(bagId)
    if bagId == nil then
--d("[FCOIS]GetActiveInventoryTypeByBagId, bagId: " ..tostring(bagId) .. " -> ERROR!")
        return nil
    end
    local bagIdToPlayerInv = FCOIS.mappingVars.bagToPlayerInv
    local playerInvId = bagIdToPlayerInv[bagId] or nil
--d("[FCOIS]GetActiveInventoryTypeByBagId, bagId: " ..tostring(bagId) .. ", playerInvId: " ..tostring(playerInvId))
    return playerInvId
end

--======================================================================================================================
-- Get functions
--======================================================================================================================
--Get the current scene and scene name
--If no scene_manager is given or no scene can be determined the dummy scene FCOIS will be returned (table containing only a name)
function FCOIS.getCurrentSceneInfo()
    if not SCENE_MANAGER then return FCOIS.dummyScene, "" end
    local currentScene = SCENE_MANAGER:GetCurrentScene()
    local currentSceneName = ""
    if not currentScene then currentScene = FCOIS.dummyScene end
    currentSceneName = currentScene.name
    return currentScene, currentSceneName
end

--Get the effective level of a unitTag and check if it's above or equals a specified "needed level".
--Returns boolean true if level is above or equal the parameter neededLevel
--Returns boolean false if level is below the parameter neededLevel
function FCOIS.checkNeededLevel(unitTag, neededLevel)
    if unitTag == nil or neededLevel == nil or type(neededLevel) ~= "number" then return false end
    local gotNeededLevel = false
    local charLevel = GetUnitLevel(unitTag)
    if not charLevel then return false end
    gotNeededLevel = (charLevel >= neededLevel) or false
    return gotNeededLevel
end

--Get the type of the vendor used currently.
-- "Normal"     = NPC vendor
-- "Nuzhimeh"   = The mobile vendor you can buy in the crown store, called Nuzhimeh
function FCOIS.GetCurrentVendorType(vendorPanelIsShown)
    vendorPanelIsShown = vendorPanelIsShown or false
    local isVendorPanelShown = FCOIS.IsVendorPanelShown(nil, vendorPanelIsShown)
    if not isVendorPanelShown then
--d("[FCOIS]GetCurrentVendorType: No vendor panel shown. >Abort!")
        return "" end
    local retVar = ""
    local vendorButtonCount = 2
    --Are we able to buy something in this store?
    if not IsStoreEmpty() then vendorButtonCount = vendorButtonCount +1 end
    --Are we able to repair something in this store?
    if CanStoreRepair() then vendorButtonCount = vendorButtonCount +1 end
    --Are there 4 buttons at the vendor menu bar?
    if vendorButtonCount == 4 then
        retVar = "Normal"
    --Are there only 3 buttons at the vendor menu bar?
    elseif vendorButtonCount == 3 then
        retVar = "Nuzhimeh"
    --Are there only 2 buttons at the vendor menu bar?
    elseif vendorButtonCount == 2 then
        retVar = "Nuzhimeh"
    end
    return retVar, vendorButtonCount
end

--Function to get the filter panel for the undo methods (SHIFT+right mouse on items)
function FCOIS.getUndoFilterPanel()
    local filterPanelNormal = LF_INVENTORY
    local settings = FCOIS.settingsVars.settings
    local undoFilterPanelSettings = settings.contextMenuClearMarkesByShiftKey and settings.useDifferentUndoFilterPanels
    if undoFilterPanelSettings then
        return FCOIS.gFilterWhere
    end
    return filterPanelNormal
end

--Function to get the armor type of an equipped item
function FCOIS.GetArmorType(equipmentSlotControl)
    if equipmentSlotControl == nil then return false end
    local bagId
    local slotIndex
    bagId, slotIndex = FCOIS.MyGetItemDetails(equipmentSlotControl)
    local armorType = GetItemArmorType(bagId, slotIndex)
    --d("[GetArmorType] bag: " .. bagId .. ", slot: " .. slotIndex .. " --- armorType: " .. tostring(armorType))
    return armorType
end


--======================================================================================================================
-- Set functions
--======================================================================================================================
--Set an item as junk + remove all marker icons on it / remove item from junk -> via additional inventory "flag" context menu
function FCOIS.setItemIsJunk(bagId, slotIndex, isJunk)
    if bagId == nil or slotIndex == nil then return false end
    isJunk = isJunk or false
    --Mark as junk?
    if isJunk == true then
        --Are there any marker icons on the item?
        local anyMarkerIconSetOnItemToJunk, markerIconsOnItemToJunk = FCOIS.IsMarked(bagId, slotIndex, -1)
        if anyMarkerIconSetOnItemToJunk then
            --Check if item can be junked
            --Remove all marker icons
            for iconIdWhichWasSetBeforeAlready, isIconMarked in pairs(markerIconsOnItemToJunk) do
                if isIconMarked then
                    FCOIS.MarkItem(bagId, slotIndex, iconIdWhichWasSetBeforeAlready, false, false) -- No inventory update needed as the item will be moved to the junk tab now!
                end
            end
        end
    end
    SetItemIsJunk(bagId, slotIndex, isJunk)
end

--Set the anti-research check for a dynamic icon
function FCOIS.setDynamicIconAntiResearchCheck(iconNr, value)
    value = value or false
    --d("FCOIS]setDynamicIconAntiResearchCheck - iconNr: " .. tostring(iconNr) .. ", value: " .. tostring(value))
    if iconNr == nil then return false end
    local isIconDynamic = FCOIS.mappingVars.iconIsDynamic
    if isIconDynamic[iconNr] then
        FCOIS.settingsVars.settings.disableResearchCheck[iconNr] = value
    end
end

--Rebuild the allowed craft skills from the settings
function FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(craftType)
    if craftType == nil then
        --reset the table to keep only the crafting_type_invalid
        FCOIS.allowedCraftSkillsForCraftedMarking = {
            [CRAFTING_TYPE_INVALID] 		= false,
        }
        --Then rebuild the other crafting_types from the settings and add them to the table
        local craftSkillsAllowedForMarksAfterCrafted = FCOIS.settingsVars.settings.allowedCraftSkillsForCraftedMarking
        for craftTypeLoop, value in ipairs(craftSkillsAllowedForMarksAfterCrafted) do
            if craftTypeLoop ~= CRAFTING_TYPE_INVALID then
                FCOIS.allowedCraftSkillsForCraftedMarking[craftTypeLoop] = value
            end
        end
    else
        --Only set the value for the wished craftType
        FCOIS.allowedCraftSkillsForCraftedMarking[craftType] = FCOIS.settingsVars.settings.allowedCraftSkillsForCraftedMarking[craftType]
    end
end


--======================================================================================================================
-- Check functions
--======================================================================================================================

--Check if the item is a special item like the Maelstrom weapon or shield, or The Master's weapon
--> Called in file FCOIS_Hooks.lua, function FCOItemSaver_AddSlotAction
--  upon right clicking an item to show the context menu for "Enchant"
function FCOIS.checkIfIsSpecialItem(p_bagId, p_slotIndex)
    if p_bagId == nil or  p_slotIndex == nil then return nil end
    local specialItems = FCOIS.specialItems
    local itemId = GetItemId(p_bagId, p_slotIndex)
    if itemId == nil then return nil end
    if specialItems[itemId] then
        return true
    end
    return false
end

--Check if a research scroll is usable or if the time left for research is less
function FCOIS.checkIfResearchScrollWouldBeWasted(bag, slotId)
    if bag == nil or slotId == nil or DetailedResearchScrolls == nil or DetailedResearchScrolls.GetWarningLine == nil then return nil end
    local itemLink = GetItemLink(bag, slotId)
    if itemLink == nil or itemLink == "" then return false end
    local isResearchScrollAndWouldBeWasted = DetailedResearchScrolls:GetWarningLine(itemLink)
    --The function returns the string "Less than y research timeslots available with x days time left", or nil if nothing found or wrong itemType
    if isResearchScrollAndWouldBeWasted == nil then
        isResearchScrollAndWouldBeWasted = false
    else
        isResearchScrollAndWouldBeWasted = true
    end
    return isResearchScrollAndWouldBeWasted
end


--Crafting create--

--Check if the new crafted item should be marked with the "crafted" marker icon
function FCOIS.checkIfCraftedItemShouldBeMarked(craftSkill, overwrite)
--d("FCOIS.checkIfCraftedItemShouldBeMarked - craftSkill: " .. tostring(craftSkill) .. ", overwrite: " .. tostring(overwrite))
    --Mark new crafted item with the "crafted" icon?
    overwrite = overwrite or false
    --Overwritten to set "Item is currently crafted" to true?
    if overwrite then return true end
    FCOIS.preventerVars.newItemCrafted = overwrite or false

    --Are we creating an item, is the setting for automark enabled and is the current crafting station allowed to mark the crafted items (set in the settings)?
    local allowedCraftSkills = FCOIS.allowedCraftSkillsForCraftedMarking
    local allowedCraftingSkill = allowedCraftSkills[craftSkill] or false
--d(">allowedCraftingSkill: " .. tostring(allowedCraftingSkill))
    if not allowedCraftingSkill then return false end

    --Are we deconstructing, improving, extracting an item, and not creating it?
    local notCreating = FCOIS.isNotCreatingCraftItem()
    if notCreating then return false end

    --Writ marking of items takes place in another function from library libLazyCrafting -> See file src/FCOIS_OtherAddons.lua, function FCOIS.checkIfWritItemShouldBeMarked
    --LibLazyCrafting:IsPerformingCraftProcess() --> returns boolean, type of crafting, addon that requested the craft
    local writCreatedItem, _, _ = FCOIS.checkLazyWritCreatorCraftedItem()
    if writCreatedItem then return false end

    local craftingCreatePanel = FCOIS.craftingCreatePanelControlsOrFunction[craftSkill]
    local craftingCreatePanelResult = false
    if craftingCreatePanel == nil then return false end
    if type(craftingCreatePanel) == "function" then
        --Function
        craftingCreatePanelResult = craftingCreatePanel()
        --d(">function: " ..tostring(craftingCreatePanelResult))
    elseif type(craftingCreatePanel) == "boolean" then
        --Function result value
        craftingCreatePanelResult = craftingCreatePanel
        --d(">boolean: " ..tostring(craftingCreatePanelResult))
    else
        --Control
        if craftingCreatePanel.IsHidden then
            craftingCreatePanelResult = not craftingCreatePanel:IsHidden()
            --d(">control not hidden: " .. tostring(craftingCreatePanelResult))
        end
    end

    --Are we creating an item manually (Crafting stations "Create" panel is open?
    local creatingItem = craftingCreatePanelResult or false
    --d(">>creatingItem: " .. tostring(creatingItem) .. ", craftSkill: " .. tostring(craftSkill) .. ", allowedCraftingSkill: " ..tostring(allowedCraftingSkill))
    if creatingItem and allowedCraftingSkill then
        --Set the variable to know if an item is getting into our bag after crafting complete
        FCOIS.preventerVars.newItemCrafted = true
    end
end

--Improvement--

--Check if item get's improved and if the marker icons from before improvement should be remembered
--Start function to remmeber the marker icons before improvement
function FCOIS.checkIfImprovedItemShouldBeReMarked_BeforeImprovement()
    --Only at smithing improvement
    local impVars = FCOIS.improvementVars
    if ctrlVars.IMPROVEMENT_INV:IsHidden() then
        --Clear the remembered improvement marker icons
        impVars.improvementBagId = nil
        impVars.improvementSlotIndex = nil
        impVars.improvementMarkedIcons = {}
        return false
    end
    if ctrlVars.IMPROVEMENT_SLOT == nil then return false end
    impVars.improvementBagId		= ctrlVars.IMPROVEMENT_SLOT.bagId
    impVars.improvementSlotIndex	= ctrlVars.IMPROVEMENT_SLOT.slotIndex

    --Check if the item is marked with several icons
    impVars.improvementMarkedIcons = {}
    local _, markedIcons = FCOIS.IsMarked(impVars.improvementBagId, impVars.improvementSlotIndex, -1)
    impVars.improvementMarkedIcons = markedIcons
end

--Check if item get's improved and if the marker icons from before improvement should be remembered
--End function to re-mark the marker icons after improvement
function FCOIS.checkIfImprovedItemShouldBeReMarked_AfterImprovement()
    --Only at smithing improvement
    if ctrlVars.IMPROVEMENT_INV:IsHidden() then return false end
    local impVars = FCOIS.improvementVars
    if impVars.improvementBagId == nil or impVars.improvementSlotIndex == nil then
        --Reset the remembered improvement marker icons
        impVars.improvementMarkedIcons = {}
        return false
    end
    --For each marked icon of the currently improved item:
    --Set the icons/markers of the previous item again (-> copy marker icons from before improvement to the improved item)
    if impVars.improvementMarkedIcons and #impVars.improvementMarkedIcons > 0 then
        local bagId, slotIndex = impVars.improvementBagId, impVars.improvementSlotIndex
        for iconId, iconIsMarked in pairs(impVars.improvementMarkedIcons) do
            if iconIsMarked == true then
                local doRemarkThisMarkerIcon = true
                --Is the item the FCOIS improve marker icon?
                if iconId == FCOIS_CON_ICON_IMPROVEMENT then
                    --Is the item already at the maximum quality?
                    local itemQuality = GetItemFunctionalQuality(bagId, slotIndex)
                    if itemQuality and itemQuality >= ITEM_FUNCTIONAL_QUALITY_LEGENDARY then
                        --Then do not re-apply this marker icon!
                        doRemarkThisMarkerIcon = false
                    end
                end
                if doRemarkThisMarkerIcon == true then
                    --Inventory update will be automatcally done after each improvement of an item
                    FCOIS.MarkItem(bagId, slotIndex, iconId, true, false)
                end
            end
        end
    end
    --Reset the improvement remember variables again
    impVars.improvementMarkedIcons = {}
    impVars.improvementBagId		= nil
    impVars.improvementSlotIndex	= nil
end

--======================================================================================================================
-- Is shown functions
--======================================================================================================================
--Is the retrait station shown?
function FCOIS.isRetraitStationShown()
    return ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing()
end

--Check if the Enchanting panel is shown
function FCOIS.IsEnchantingPanelShown(enchantingMode)
    --d("[FCOIS]IsEnchantingPanelShown - enchantingMode: " ..tostring(enchantingMode))
    if enchantingMode == ENCHANTING_MODE_NONE or (enchantingMode ~= ENCHANTING_MODE_CREATION and enchantingMode ~= ENCHANTING_MODE_EXTRACTION and enchantingMode ~= ENCHANTING_MODE_RECIPES) then return false end
    local retVar = false
    if ctrlVars.ENCHANTING_STATION ~= nil and not ctrlVars.ENCHANTING_STATION:IsHidden() then
        if ctrlVars.ENCHANTING.GetEnchantingMode ~= nil then
            retVar =  ctrlVars.ENCHANTING:GetEnchantingMode() == enchantingMode
        end
    end
    return retVar
end

--Check if the Enchanting glyph creation panel is shown
function FCOIS.IsEnchantingPanelCreationShown()
    --d("[FCOIS]IsEnchantingPanelShown")
    local retVar = false
    if ctrlVars.ENCHANTING_STATION ~= nil and not ctrlVars.ENCHANTING_STATION:IsHidden() then
        if ctrlVars.ENCHANTING.GetEnchantingMode ~= nil then
            --d(">2 EnchMode: " .. tostring(ctrlVars.ENCHANTING:GetEnchantingMode()))
            retVar =  (ctrlVars.ENCHANTING:GetEnchantingMode() == ENCHANTING_MODE_CREATION)
        end
    end
    --d("<result: " .. tostring(retVar))
    return retVar
end

--Check if the Alchemy creation panel is shown
function FCOIS.IsAlchemyPanelCreationShown()
    --d("[FCOIS]IsAlchemyPanelCreationShown")
    local retVar = false
    if ctrlVars.ALCHEMY_INV ~= nil and not ctrlVars.ALCHEMY_INV:IsHidden() then
        if ctrlVars.ALCHEMY.mode ~= nil then
            --d(">2 AlchemyMode: " .. tostring(ctrlVars.ALCHEMY.mode))
            retVar =  (ctrlVars.ALCHEMY.mode == ZO_ALCHEMY_MODE_CREATION)
        end
    end
    --d("<result: " .. tostring(retVar))
    return retVar
end

--Check if any of the vendor panels (buy, sell, buyback, repair) are shown
function FCOIS.IsVendorPanelShown(vendorPanelId, overwrite)
    overwrite = overwrite or false
--d("FCOIS.IsVendorPanelShown, vendorPanelId: " .. tostring(vendorPanelId) .. ", overwrite: " .. tostring(overwrite))
    if overwrite then return true end
    --Check the scene name if it is the "vendor" scene
    local currentSceneName = SCENE_MANAGER.currentScene.name
    if currentSceneName == nil or currentSceneName ~= ctrlVars.vendorSceneName then
--d("<1, sceneName: " ..tostring(currentSceneName))
        return false end
    local vendorLibFilterIds = FCOIS.mappingVars.supportedVendorPanels
    local isVendorPanelChecked = false
    if vendorPanelId ~= nil then
        isVendorPanelChecked = vendorLibFilterIds[vendorPanelId] or false
        if not isVendorPanelChecked then return false end
    end
    local retVar = false
    if vendorPanelId ~= nil then
        --Vendor Buy
        if vendorPanelId ==     LF_VENDOR_BUY then
            retVar = not ctrlVars.STORE:IsHidden() or false
        --Vendor Sell (PlayerInventory or CraftBag are shown and all other vendor panels are hidden)
        elseif vendorPanelId == LF_VENDOR_SELL then
            retVar = ((ctrlVars.STORE:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()) and (not ctrlVars.BACKPACK_BAG:IsHidden() or not ctrlVars.CRAFTBAG_BAG:IsHidden())) or false
        --Vendor Buyback
        elseif vendorPanelId == LF_VENDOR_BUYBACK then
            retVar = not ctrlVars.STORE_BUY_BACK:IsHidden() or false
        --Vendor Repair
        elseif vendorPanelId == LF_VENDOR_REPAIR then
            retVar = not ctrlVars.REPAIR_LIST:IsHidden() or false
        end
    else
--d("2")
        --Check each panel
        retVar = ((not ctrlVars.STORE:IsHidden() or not ctrlVars.VENDOR_SELL:IsHidden() or not ctrlVars.STORE_BUY_BACK:IsHidden() or not ctrlVars.REPAIR_LIST:IsHidden())
                  or (not ctrlVars.BACKPACK_BAG:IsHidden() or not ctrlVars.CRAFTBAG_BAG:IsHidden())) or false
    end
--d("<retVar: " ..tostring(retVar))
    return retVar
end


-- =====================================================================================================================
--  Other functions
-- =====================================================================================================================
--Show/Hide the player progress bar
function FCOIS.ShowPlayerProgressBar(doShow)
    --d("[FCOIS] ShowPlayerProgressBar - doShow: " .. tostring(doShow))
    if FCOIS.ZOControlVars.CHARACTER:IsHidden() then return false end
    if ZO_PlayerProgress ~= nil then ZO_PlayerProgress:SetHidden(not doShow) end
end

-- =====================================================================================================================
--  House functions
-- =====================================================================================================================
--Is the player owning a house?
function FCOIS.checkIfOwningHouse()
    --List of all houses on the map, owned and not owned ones
    --> The list will only be ther eif one has opened the map and clicked the "houses" tab at least once!!!
    local housesOnMap = WORLD_MAP_HOUSES_DATA:GetHouseList()
    if housesOnMap and #housesOnMap > 0 then
        for _, houseData in ipairs(housesOnMap) do
            if houseData.unlocked ~= nil and houseData.unlocked == true then
                return true
            end
        end
    end
    --Houses at map list was not build or no owned/unlocked house found, so check if a primary house is set
    return  (GetHousingPrimaryHouse() ~= 0) or false
end

--Check if the player is in a house
function FCOIS.checkIfInHouse()
    local inHouse = (GetCurrentZoneHouseId() ~= 0) or false
    if not inHouse then
        local x,y,z,rotRad = GetPlayerWorldPositionInHouse()
        if x == 0 and y == 0 and z == 0 and rotRad == 0 then
            return false -- not in a house
        end
    end
    return true -- in a house
end

--Check if the player owns the house
function FCOIS.checkIfIsOwnerOfHouse()
    return IsOwnerOfCurrentHouse() or false
end

--Check if the bagId is a house bank bag and we are in our own house
function FCOIS.checkIfHouseBankBagAndInOwnHouse(bagId)
    local retVar = (bagId ~= nil and IsHouseBankBag(bagId) and FCOIS.checkIfInHouse() and FCOIS.checkIfIsOwnerOfHouse) or false
--d("[FCOIS.checkIfHouseBankBagAndInOwnHouse] bagId: " ..tostring(bagId) .. ", houseBankBagAndInOwnHouse: " ..tostring(retVar))
    return retVar
end

--Jump to one of the players own houses
function FCOIS.jumpToOwnHouse(backupType, withDetails, apiVersion, doClearBackup)
    --GetCurrentZoneHouseId() gets the id for the current house the player is in, and can be used for "RequestJumpToHouse" function
    --Jump to my own house
    --TODO: JumpToHouse(GetUnitDisplayName("player")) --not working for my own house, so how can I port to my own house via API?
    --TODO: * RequestJumpToHouse(*integer* _houseId_) --loop over all collectibles and check for houses and then get the houesId form the collectible?
    --or:
    --local node = ???
    --local n_known, n_name, _, _, _, _, poi, _, _ = GetFastTravelNodeInfo(node)
    --CHAT_SYSTEM:AddMessage("Porting to " .. n_name .. "!")
    --FastTravelToNode(node) --where node is the wayshrine = house
    --====================================================================================
    --Entries with "bought" houses within the collecitons:
    --FCOIS.ZOControlVars.housingBookNavigation.rootNode.children[1].children[1].data:GetReferenceId() -> returns 31 e.g. the houesId which can be used to jump to
    -->collectibleId (e.g. 1090)
    -->collectibleIndex (e.g. 5)
    --The list of houses in the collections. 1st row should contain the bought ones, 2nd row the locked ones.
    --If you do not own any the 1st row is the locked ones!
    --Only way to distinguish them is by help of a text: Unlocked/Locked (German: Freigeschaltet/Nicht freigeschaltet)
    --which is available at: FCOIS.ZOControlVars.housingBookNavigation.rootNode.children[1].data (or via function FCOIS.ZOControlVars.housingBookNavigation.rootNode.children[1]:GetData()) = "Freigeschaltet" (unlocked) / "Nicht freigeschaltet" (locked)
    local housesListInCollections = FCOIS.ZOControlVars.housingBookNavigation.rootNode.children[1]
    if housesListInCollections ~= nil then
        --Check if the houselist contains an unlocked item
        local houseListFirstEntryData = housesListInCollections:GetData() or ""
        if houseListFirstEntryData ~= nil and houseListFirstEntryData ~= "" then
            --Compare the text in the data with "Freigeschaltet" (unlocked) text
            -->TODO: Constant for GetString(unlocked) needs to be determined from eso strings for the comparison
            -- SI_COLLECTIBLEUNLOCKSTATE0: Locked
            -- SI_COLLECTIBLEUNLOCKSTATE2: Unlocked
            local compareTextForUnlocked = GetString(SI_COLLECTIBLEUNLOCKSTATE2)
            if houseListFirstEntryData == compareTextForUnlocked then
                --There is at least one unlocked house!
                --Get the first entry of the unlocked houses now.
                local firstUnlockedHouseRow = housesListInCollections.children[1]
                if firstUnlockedHouseRow ~= nil then
                    local firstUnlockedHouseData = firstUnlockedHouseRow.data
                    if firstUnlockedHouseData ~= nil then
                        --Get the reference ID of the house for the teleport
                        local houseId = firstUnlockedHouseData:GetReferenceId() or 0
                        if houseId ~= 0 then
                            --Save the parameters so we can use them after reloadui/jump to house in EVENT_PLAYER_ACTIVATED again
                            local backupParams = {}
                            backupParams.backupType     = backupType
                            backupParams.withDetails    = withDetails
                            backupParams.apiVersion     = apiVersion
                            backupParams.doClearBackup  = doClearBackup
                            FCOIS.settingsVars.settings.backupParams = {}
                            FCOIS.settingsVars.settings.backupParams = backupParams
                            --Teleport nto the house id now
                            RequestJumpToHouse(houseId)
                        end
                    end
                end
            end
        end
    end

end

-- =====================================================================================================================
--  Confirmation dialog functions
-- =====================================================================================================================
--Function to show a confirmation dialog
function FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, callbackSetup, data, forceUpdate)
    local libDialog = FCOIS.LDIALOG
    local addonVars = FCOIS.addonVars
    --Force the dialog to be updated with the title, text, etc.?
    forceUpdate = forceUpdate or false
    --Check if the dialog exists already, and if not register it
    local existingDialogs = libDialog.dialogs
    if forceUpdate or existingDialogs[addonVars.gAddonName] == nil or existingDialogs[addonVars.gAddonName][dialogName] == nil then
        libDialog:RegisterDialog(addonVars.gAddonName, dialogName, title, body, callbackYes, callbackNo, callbackSetup, forceUpdate)
    end
    --Show the dialog now
    libDialog:ShowDialog(addonVars.gAddonName, dialogName, data)
end

-- =====================================================================================================================
--  Gear set functions
-- =====================================================================================================================
--Function to sort the gear set mapping tables again
-->Will NOT sort table FCOIS.mappingVars.gearToIcon as the keys are consistent and ordered via table.remove etc.
--> key = value
--> [1] = 2,
--> [2] = 4,
--> [3] = 6,
--> [4] = 7,
--> [5] = 8,
----> Sort by value and rebuild key via table.sort(FCOIS.mappingVars.gearToIcon)
-------------------------------------------------
-->Will sort table FCOIS.mappingVars.iconToGear:
--> key = value
--> [2] = 1,
--> [4] = 2,
--> [6] = 3,
--> [7] = 4,
--> [8] = 5,
-- Entries can get deleted in between here by setting them to NIL as table.remove does not work, because the table
-- does not use a consistent integer key.
-- So the removed entries need to be resorted here in order to set the value to the appropriate "next" gear set number
--> here in this example 6!
--> [13] = 7,
----> Sort by value, condense gaps, and keep key
local function sortGearSetMappingTables()
    if FCOIS.mappingVars.gearToIcon == nil then return false end
    --Sort the table to sort from
    table.sort(FCOIS.mappingVars.gearToIcon)
    local tableToCopyFrom = FCOIS.mappingVars.gearToIcon
    --Clear the table to sort
    FCOIS.mappingVars.iconToGear = {}
    --Loop over the table to sort from
    for gearNr, iconNr in ipairs(tableToCopyFrom) do
        --Transfer the values from the sorted table to the non-sorted table ([gearIconNr] = gearNr)
        FCOIS.mappingVars.iconToGear[iconNr] = gearNr
    end
end

--Function to rebuild the gear set values (icons, ids, names, context menu values, etc.)
function FCOIS.rebuildGearSetBaseVars(iconNr, value, calledFromEventPlayerActivated)
--d("FCOIS]rebuildGearSetBaseVars-calledFromEventPlayerActivated: " ..tostring(calledFromEventPlayerActivated))
    calledFromEventPlayerActivated = calledFromEventPlayerActivated or false
    local settings = FCOIS.settingsVars.settings
    local iconIsGear = settings.iconIsGear
    if iconIsGear == nil then return end
    --Set the 5 static gear icons as standard "isGear" = true
    --local staticGears = FCOIS.numVars.gFCONumGearSetsStatic

------------------------------------------------------------------------------------------------------------------------
--Update all entries
------------------------------------------------------------------------------------------------------------------------
    if iconNr == nil and value == nil then
        local gearCounter = 0
        --Reset the active gear sets
        FCOIS.numVars.gFCONumGearSets = 0
        --loop over all icons which are marked as gear, or are one of the 5 static gear icons
--d("[FCOIS]rebuildGearSetBaseVars - all icons")
        for iconNrLoop, isGear in pairs(iconIsGear) do
            --Maximum gear set number
            --Get the current max and increase/decrease it, depending on the value
            local currentMaxGearSets = FCOIS.numVars.gFCONumGearSets
--d(">iconNrLoop: " ..tostring(iconNrLoop) .. ", isGear: " ..tostring(isGear) .. ", currentMaxGearSets: " .. tostring(currentMaxGearSets))
            ------------------------------------------------------------------------------------------------------------------------
            --Icon is marked as gear
            ------------------------------------------------------------------------------------------------------------------------
            if isGear then
                gearCounter = gearCounter + 1
                --The mapping of icon to filter button number
                FCOIS.mappingVars.iconToFilter[iconNrLoop] = FCOIS_CON_FILTER_BUTTON_GEARSETS
                --The mapping of icon to gear number
                FCOIS.mappingVars.iconToGear[iconNrLoop] = gearCounter
                --The mapping of gear number to icon
                FCOIS.mappingVars.gearToIcon[gearCounter] = iconNrLoop
                --Increase the maximum gear sets
                currentMaxGearSets = currentMaxGearSets + 1
--d(">>is gear! gearCounter: " .. tostring(gearCounter) .. ", newMaxGearSets: " ..tostring(currentMaxGearSets))
            ------------------------------------------------------------------------------------------------------------------------
            --Icon is not marked as gear
            ------------------------------------------------------------------------------------------------------------------------
            else
                --Reset the icon to filter mapping to the default value
                local icon2filterDef = FCOIS.mappingVars.iconToFilterDefaults
                FCOIS.mappingVars.iconToFilter[iconNrLoop] = icon2filterDef[iconNrLoop]
                --Reset the mapping of icon to gear number
                local gearNr = 0
                if FCOIS.mappingVars.iconToGear[iconNrLoop] ~= nil then
                    gearNr = FCOIS.mappingVars.iconToGear[iconNrLoop]
                    FCOIS.mappingVars.iconToGear[iconNrLoop] = nil -- as the table got no consistent digit key table.remove does not work
					--table.remove(FCOIS.mappingVars.iconToGear, iconNrLoop) -- to retain table indices
                end
                --Reset the mapping of gear number to icon
                if gearNr ~= nil and gearNr > 0 and FCOIS.mappingVars.gearToIcon[gearNr] ~= nil then
                    --FCOIS.mappingVars.gearToIcon[gearNr] = nil
					table.remove(FCOIS.mappingVars.gearToIcon, gearNr) -- to retain table indices
                end
--d(">>NOT a gear! gearNr: " .. tostring(gearNr) .. ", newMaxGearSets: " ..tostring(currentMaxGearSets))
            end
            --Set the new current gear sets number
            FCOIS.numVars.gFCONumGearSets = currentMaxGearSets

            --Update the context menu texts for this icon
            --but not if this function was called from Event_Player_Activated as the same function will be called just after
            --FCOIS.rebuildGearSetBaseVars for all icons (-1) already!
            if not calledFromEventPlayerActivated then
                FCOIS.changeContextMenuEntryTexts(iconNrLoop)
            end
        end -- for ... loop

        --Sort the tables iconToGear and gearToIcon again
        sortGearSetMappingTables()

        --Rebuild the context menu variables for the dynamic and gear icons
        FCOIS.rebuildFilterButtonContextMenuVars()

------------------------------------------------------------------------------------------------------------------------
--Update only one entry
------------------------------------------------------------------------------------------------------------------------
    else
--d("[FCOIS]rebuildGearSetBaseVars - single icon: "..tostring(iconNr) .." and value: " ..tostring(value))
        ------------------------------------------------------------------------------------------------------------------------
        --Single icon is marked as gear
        ------------------------------------------------------------------------------------------------------------------------
        if value then
            local gearCounter = 0
            for _, isGear in pairs(iconIsGear) do
                if isGear then
                    gearCounter = gearCounter + 1
                end
            end
--d(">gearCounter: " ..tostring(gearCounter))
            --The mapping of icon to filter button number
            FCOIS.mappingVars.iconToFilter[iconNr] = FCOIS_CON_FILTER_BUTTON_GEARSETS
            --The mapping of icon to gear number
            FCOIS.mappingVars.iconToGear[iconNr] = gearCounter
            --The mapping of gear number to icon
            FCOIS.mappingVars.gearToIcon[gearCounter] = iconNr
        ------------------------------------------------------------------------------------------------------------------------
        --Single icon is not marked as gear
        ------------------------------------------------------------------------------------------------------------------------
        else
            --Reset the icon to filter mapping to the default value
            local icon2filterDef = FCOIS.mappingVars.iconToFilterDefaults
            FCOIS.mappingVars.iconToFilter[iconNr] = icon2filterDef[iconNr]
            --Reset the mapping of icon to gear number
            local gearNr = 0
            if FCOIS.mappingVars.iconToGear[iconNr] ~= nil then
                gearNr = FCOIS.mappingVars.iconToGear[iconNr]
                FCOIS.mappingVars.iconToGear[iconNr] = nil -- as the table got no consistent digit key table.remove does not work
				--table.remove(FCOIS.mappingVars.iconToGear, iconNr) -- to retain table indices
            end
            --Reset the mapping of gear number to icon
            if gearNr ~= nil and gearNr > 0 and FCOIS.mappingVars.gearToIcon[gearNr] ~= nil then
                --FCOIS.mappingVars.gearToIcon[gearNr] = nil
				table.remove(FCOIS.mappingVars.gearToIcon, gearNr) -- to retain table indices
            end
        end

        --Maximum gear set number
        --Get the current max and increase/decrease it, depending on the value
        local currentMaxGearSets = FCOIS.numVars.gFCONumGearSets
--d(">currentMaxGearSets: " ..tostring(currentMaxGearSets))
        if value then
            currentMaxGearSets = currentMaxGearSets + 1
        else
            currentMaxGearSets = currentMaxGearSets - 1
        end
        --Set the new current gear sets number
        FCOIS.numVars.gFCONumGearSets = currentMaxGearSets
--d(">newMaxGearSets: " ..tostring(FCOIS.numVars.gFCONumGearSets))

        --Update the context menu texts for this icon
        FCOIS.changeContextMenuEntryTexts(iconNr)

        --Sort the tables iconToGear and gearToIcon again
        sortGearSetMappingTables()

        --Rebuild the context menu variables for the dynamic and gear icons
        FCOIS.rebuildFilterButtonContextMenuVars()
    end

end

-- =====================================================================================================================
--  Icon into string functions
-- =====================================================================================================================
function FCOIS.buildIconText(text, iconId, iconRight, noColor)
    if iconId == nil then return text end
    noColor = noColor or false
    iconRight = iconRight or false
    local itemIconText = text
    --Get the texture name of the icon
    local textureVars = FCOIS.textureVars.MARKER_TEXTURES
    if textureVars == nil then return text end
    local settingsIcon = FCOIS.settingsVars.settings.icon
    local iconTextureString = textureVars[settingsIcon[iconId].texture]
    if iconTextureString ~= nil and iconTextureString ~= "" then
        --Prepare the texture string
        local textureString = zo_iconFormatInheritColor(iconTextureString, 20, 20)
        --Add the color to the icon?
        if not noColor then
            --Colorize the entries like the icon's color, or with the normal color?
            local colDef = ZO_ColorDef:New(settingsIcon[iconId].color)
            --Colorize the texture with the color choosen in the settings
            local iconTextureStringColored = colDef:Colorize(textureString)
            textureString = iconTextureStringColored
        end
        --Show the icon right or left to the text?
        if iconRight then
            --Icon at the right
            itemIconText = text .. " " .. textureString
        else
            --Icon at the left
            itemIconText = textureString .. " " .. text
        end
    end
    return itemIconText
end

-- =====================================================================================================================
--  Character functions
-- =====================================================================================================================
--Get the currently logged in character's unique ID
function FCOIS.getCurrentlyLoggedInCharUniqueId()
    --[[
        local loggedInCharUniqueId = 0
        local loggedInName = GetUnitName("player")
        --Check all the characters of the account
        for i = 1, GetNumCharacters() do
            local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
            local charName = zo_strformat(SI_UNIT_NAME, name)
            --If the current logged in character was found
            if loggedInName == charName or loggedInName == name then
                loggedInCharUniqueId = characterId
                break -- exit the loop
            end
        end
        return tostring(loggedInCharUniqueId)
        ]]
    return GetCurrentCharacterId()
end

--Get the currently logged in account's characters as table, with the name as key and the characterId as value,
--or the characterId as key and the character name as key (depending in boolean parameter keyIsCharName)
--Function to get all characters of the account, ID and name.
--Returns a table with 2 possible variants, either the character ID is key and the name is the value,
--or vice versa.
--Parameter boolean, keyIsCharName:
-->True: the key of the returned table is the character name
-->False: the key of the returned table is the unique cahracter ID (standard)
function FCOIS.getCharactersOfAccount(keyIsCharName)
    keyIsCharName = keyIsCharName or false
    local charactersOfAccount
    --Check all the characters of the account
    for i = 1, GetNumCharacters() do
        local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
        local charName = zo_strformat(SI_UNIT_NAME, name)
        if characterId ~= nil and charName ~= "" then
            if charactersOfAccount == nil then charactersOfAccount = {} end
            if keyIsCharName then
                charactersOfAccount[charName]   = characterId
            else
                charactersOfAccount[characterId]= charName
            end
        end
    end
    return charactersOfAccount
end

--Get the character name using it's unique characterId.
--If the 2nd parameter characterTable is given it needs to be a table generated via function FCOIS.getCharactersOfAccount.
--At best the key is the unique characterId, it not it can be the characterName as well.
function FCOIS.getCharacterName(characterId, characterTable)
    if characterId == nil then return nil end
    local keyIsName = false
    local characterName
    if characterTable == nil then
        characterTable =  FCOIS.getCharactersOfAccount(false)
    else
        --Check if the characterTable got the uniqueId or the name as key
        for key, _ in pairs(characterTable) do
            if type(key) == "String" then
                keyIsName = true
                break -- end the for loop
            end
        end
    end
    --Key of the table is a name?
    if keyIsName then
        --Key of the table is an unique ID?
        for charName, charId in pairs(characterTable) do
            if charId == characterId then return charName end
        end
    else
        characterName = characterTable[characterId]
    end
    if not characterName or characterName == "" then return end
    return characterName
end

--Junk all items marked with a/some marker icons
function FCOIS.JunkMarkedItems(markerIconsMarkedOnItems, bagId)
    --d("[FCOIS]Junk all marked for sell item in inventory now!")
    if bagId == nil or markerIconsMarkedOnItems == nil then return end
    --Scan the bag for any of the marked items and transfer them to the Junk now
    local bagToCheck = bagId
    --d("[FCOIS]--> Scan whole inventory, bag: " .. tostring(bagToCheck))
    --Get the bag cache (all entries in that bag)
    --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
    if not bagCache then return end
    local retVar = false
    local junkedItemCount = 0
    for _, data in pairs(bagCache) do
        local isMarked, _ = FCOIS.IsMarked(data.bagId, data.slotIndex, markerIconsMarkedOnItems, nil)
        if isMarked and isMarked == true and not IsItemJunk(data.bagId, data.slotIndex) then
            SetItemIsJunk(data.bagId, data.slotIndex, true)
            junkedItemCount = junkedItemCount + 1
            retVar = true
        end
    end
    if retVar == true then
        local locVarJunkedItemCount = FCOIS.GetLocText("fcois_junked_item_count", false)
        d(string.format(FCOIS.preChatVars.preChatTextGreen .. locVarJunkedItemCount, tostring(junkedItemCount)))
    end
    return retVar
end

--Get the inventoryType by help of the LibFilters filterPanelId
function FCOIS.GetInventoryTypeByFilterPanel(p_filterPanelId)
    p_filterPanelId = p_filterPanelId or FCOIS.gFilterWhere
    if p_filterPanelId == nil then return nil end
    local inventoryType
    local mappingVars = FCOIS.mappingVars
    local libFiltersPanelIdToCraftingPanelInventory = mappingVars.libFiltersPanelIdToCraftingPanelInventory
    local libFiltersPanelIdToNormalInventory = mappingVars.libFiltersPanelIdToInventory

    --Is the craftbag active and additional addons like CraftBagExtended show the craftbag at the bank or mail panel?
    if FCOIS.checkIfCBEorAGSActive(FCOIS.gFilterWhereParent, true) and INVENTORY_CRAFT_BAG and not ctrlVars.CRAFTBAG:IsHidden() then
        inventoryType = INVENTORY_CRAFT_BAG
    else
        --Is the filterpanelId a crafting table?
        inventoryType = libFiltersPanelIdToCraftingPanelInventory[p_filterPanelId] or nil
        --Else: Is it a normal panel
        if inventoryType == nil then
            inventoryType = libFiltersPanelIdToNormalInventory[p_filterPanelId] or nil
        end
    end
    return inventoryType
end

--Check if any item moved to a bagId should run some "auto demark" checks
function FCOIS.checkIfBagShouldAutoRemoveMarkerIcons(bagId, slotIndex)
--d("[FCOIS]checkIfBagShouldAutoRemoveMarkerIcons")
    if not bagId or not slotIndex or GetItemType(bagId, slotIndex) == ITEMTYPE_NONE then return end
    local iconsToAutoRemove = {}
    --Get the FCOIS marker icons at the item
    local dynamicIconIds = FCOIS.mappingVars.dynamicToIcon
    local isMarked, markedDynamicIcons = FCOIS.IsMarked(bagId, slotIndex, dynamicIconIds, nil)
    if isMarked == true then
        local settings = FCOIS.settingsVars.settings
        --For each dynamic check if the setting to auto remove a marker icon is enabled
        for dynamicIconId, isMarkedDnyIcon in ipairs(markedDynamicIcons) do
            if isMarkedDnyIcon == true and settings.icon[dynamicIconId].autoRemoveMarkForBag[bagId] == true then
--d(">checking bag: " ..tostring(bagId) .. "> " ..GetItemLink(bagId, slotIndex) .. ", dynIconShouldBeRemoved: " ..tostring(dynamicIconId))
                table.insert(iconsToAutoRemove, dynamicIconId)
            end
        end
        --Remove these marker icons now
        if iconsToAutoRemove and #iconsToAutoRemove > 0 then
            FCOIS.MarkItem(bagId, slotIndex, iconsToAutoRemove, false, true)
        end
    end
end

--==========================================================================================================================================
--                                          FCOIS - Keyboard helper functions
--==========================================================================================================================================
--Is a modifier key pressed? SHIFT, ALT, CTRL, COMMAND (only on MAC platform!)
function FCOIS.IsModifierKeyPressed(modKey)
    if modKey == nil then return end
    if modKey == KEY_SHIFT then
        return IsShiftKeyDown()
    elseif modKey == KEY_ALT then
        return IsAltKeyDown()
    elseif modKey == KEY_CTRL then
        return IsControlKeyDown()
    elseif modKey == KEY_COMMAND then
        return IsCommandKeyDown()
    end
    return false
end

--Check if no othe rmodifier key is pressed except the specified one
function FCOIS.IsNoOtherModifierKeyPressed(modKey)
    if modKey == nil then return end
    if modKey == KEY_SHIFT then
        return not IsAltKeyDown() and not IsControlKeyDown() and not IsCommandKeyDown()
    elseif modKey == KEY_ALT then
        return not IsShiftKeyDown() and not IsControlKeyDown() and not IsCommandKeyDown()
    elseif modKey == KEY_CTRL then
        return not IsAltKeyDown() and not IsShiftKeyDown() and not IsCommandKeyDown()
    elseif modKey == KEY_COMMAND then
        return not IsAltKeyDown() and not IsControlKeyDown() and not IsShiftKeyDown()
    end
    return false
end