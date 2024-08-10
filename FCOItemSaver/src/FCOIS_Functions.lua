--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local libFilters = FCOIS.libFilters

--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage
local preChatTextGreen = FCOIS.preChatVars.preChatTextGreen

--local lua
local tos = tostring
local ton = tonumber
local strformat = string.format
local strmatch = string.match
local tins = table.insert
local trem = table.remove
local tsort = table.sort

local em = EVENT_MANAGER
local wm = WINDOW_MANAGER

--Local ZOs API
local gccharid = GetCurrentCharacterId
local zo_strf = zo_strformat
local zostrspl = zo_strsplit
local zocstrfor = ZO_CachedStrFormat
local hashstr = HashString
local zogsid64 = zo_getSafeId64Key
local zocl = zo_callLater

local giid = GetItemId
local giiid = GetItemInstanceId
local giuid = GetItemUniqueId
local gin = GetItemName
local git = GetItemType
local gicn = GetItemCreatorName
local giac = GetItemActorCategory
local gitrait = GetItemTrait

local gil = GetItemLink
local giliid = GetItemLinkItemId
local gilit = GetItemLinkItemType
local gilrl = GetItemLinkRequiredLevel
local gilrcp = GetItemLinkRequiredChampionPoints
local gilti = GetItemLinkTraitInfo
local gilfq = GetItemLinkFunctionalQuality
local gilis = GetItemLinkItemStyle
local gilaeid = GetItemLinkAppliedEnchantId
local gilac = GetItemLinkActorCategory
local gilsetinf = GetItemLinkSetInfo
local gilbt = GetItemLinkBindType
local gilna = GetItemLinkName
local gilrril = GetItemLinkRecipeResultItemLink
local gilccid = GetItemLinkContainerCollectibleId
local giltinf = GetItemTraitInformationFromItemLink
local gilinf = GetItemLinkInfo

local gsgiinf = GetSoulGemItemInfo

local getUnitLvl = GetUnitLevel
local canStoreRepairFunc = CanStoreRepair
local isStoreEmptyFunc = IsStoreEmpty

local isilcr = IsItemLinkCrafted
local isilst = IsItemLinkStolen
local isilfcs = IsItemLinkFromCrownStore
local isilfcc = IsItemLinkFromCrownCrate
local isilbo = IsItemLinkBound
local iscvfplayer = IsCollectibleValidForPlayer

local addonVars = FCOIS.addonVars
local gAddonName = addonVars.gAddonName
local ctrlVars = FCOIS.ZOControlVars
local playerInvInvs = ctrlVars.playerInventoryInvs
local mappingVars = FCOIS.mappingVars
local bag2PlayerInv = mappingVars.bagToPlayerInv
local libFiltersPanelIdToInventory = mappingVars.libFiltersPanelIdToInventory

local checkVars = FCOIS.checkVars
local allowedSetItemTypes = checkVars.setItemTypes

local uniqueItemIdStringTemplate = "%s,%s,%s,%s,%s,%s,%s,%s,%s,%s" -- itemInstanceOrItemId,level,quality,trait,style,enchantment,isStolen,isCrafted,craftedByName,isCrownItem
--Junk marking/removing from junk
local itemsToMarkAsJunkMaxPerPackage = 10 --#291
local packagesToMarkAsJunkMax = 50 --#291
local delayToMarkAsJunkInBetweenPackages = 250 --#291




local allowedUniqueItemTypes = checkVars.uniqueIdItemTypes

local inventoryRowPatterns = checkVars.inventoryRowPatterns
local otherAddons = FCOIS.otherAddons
local IIFAitemsListEntryPrePattern = otherAddons.IIFAitemsListEntryPrePattern
local IIfAInvRowPatternToCheck = "^" .. IIFAitemsListEntryPrePattern .. "*"

local updateCraftingInventory = FCOIS.UpdateCraftingInventory --maybe nil here, will be updated further down in function FCOIS.CheckIfImprovedItemShouldBeReMarked_AfterImprovement()

local getGearIcons

local createFCOISUniqueIdString
local signItemId
local checkActivePanel
local checkRepetitivelyIfControlExists
local isVendorPanelShown

local isMarked
local isMarkedByItemInstanceId
local checkIfUniversalDeconstructionNPC
local isCompanionInventoryShown
local FCOISMarkItem

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
--d("[FCOIS]ThrottledUpdate, callbackName: " .. tos(callbackName))
    local args = {...}
    local function updateNow()
        em:UnregisterForUpdate(callbackName)
        callback(unpack(args))
    end
    em:UnregisterForUpdate(callbackName)
    em:RegisterForUpdate(callbackName, timer, updateNow)
end

--Added with API101043 - ZOs uses more and more DeferredInitialization meanwhile so we craete a wrapper function for that
local postHookedOnDeferredInitControls = {}
function FCOIS.onDeferredInitCheck(object, callbackFunc, preCheckFunc)
	if callbackFunc == nil then return end
	--PreCheck funtion is needed?
	local doNow = true
	if type(preCheckFunc) == "function" then
		doNow = preCheckFunc(object)
	end
	if not doNow then return end

	--No deferred init available? Run callback directly
	if object ~= nil then
		if object.OnDeferredInitialize == nil then
			callbackFunc(object)
		else
			if not postHookedOnDeferredInitControls[object] then
				SecurePostHook(object, "OnDeferredInitialize", function(...) callbackFunc(object, ...) end)
				postHookedOnDeferredInitControls[object] = true
			end
		end
	end
end


local alreadyActiveBlockedCallbackNames = {}
function FCOIS.OnlyCallOnceInTime(callbackName, timeToBlock, callback, ...)
    --d("[FCOIS]OnlyCallOnceInTime, callbackName: " .. tos(callbackName))
    --Do not call more than once if another same callbackName is active
    if alreadyActiveBlockedCallbackNames[callbackName] ~= nil then return end

    alreadyActiveBlockedCallbackNames[callbackName] = true

    local function resetAgain()
        em:UnregisterForUpdate(callbackName)
        alreadyActiveBlockedCallbackNames[callbackName] = nil
    end

    em:UnregisterForUpdate(callbackName)
    em:RegisterForUpdate(callbackName, timeToBlock, resetAgain)
    local args = {...}
    callback(unpack(args))
end

local function checkIfCompanionItem(bagId, slotIndex)
    return gilac(gil(bagId, slotIndex)) == GAMEPLAY_ACTOR_CATEGORY_COMPANION
end

local function processPackages(itemsToProcessTab, maxEntriesPerPackage, maxPackages, preCheckFunc, callbackFunc, callbackAfterEachEntry, delay, finalCallbackFunc)
    if itemsToProcessTab == nil or maxEntriesPerPackage == nil or type(callbackFunc) ~= "function" then return end
    if type(finalCallbackFunc) ~= "function" then finalCallbackFunc = nil end
    if type(preCheckFunc) ~= "function" then preCheckFunc = nil end
    if type(callbackAfterEachEntry) ~= "function" then callbackAfterEachEntry = nil end
    delay = delay or 250


    local retVar = false
    local retCount = 0
    local itemCount = #itemsToProcessTab
    maxPackages = maxPackages or 999
    if itemCount <= maxEntriesPerPackage then maxPackages = 1 end


    local packagesToProcess = {}

    local packagesEstimated = itemCount / maxEntriesPerPackage
    --ceil 7,5 to 8 e.g., and then use that as min package count but cut off at maxPackageCount
    local packagesCount = zo_clamp(packagesEstimated, zo_ceil(packagesEstimated), maxPackages)
    packagesCount = packagesCount or 1

--d("[FCOSI]processPackages - #itemsToProcessTab: " ..tos(itemsToProcessTab) .. ", entriesPerPack: " ..tos(maxEntriesPerPackage) ..", maxPacks: " ..tos(maxPackages) .. ", packagesEstimated: " ..tos(packagesEstimated) ..", packagesCount: " ..tos(packagesCount) ..", delay: " ..tos(delay))

    for packageCounter=1, packagesCount, 1 do
        local packageData = {}
        --StartPos = packageCounter * 25 items (or at item 1 if packageCounter is 1)
        local startPos
        if packageCounter == 1 then
            startPos = 1
        else
            startPos = ((packageCounter - 1) * maxEntriesPerPackage) + 1 -- As of 2nd package: Start at maxEntriesPerPackage + 1 (e.g. 10 + 1)
        end
        local endPos = startPos + (maxEntriesPerPackage - 1) --EndPos = StartItem (e.g. 1, or 11, or 21) + 9 items (in total 10 items each package).
        if startPos > itemCount then startPos = itemCount end
        if endPos > itemCount then endPos = itemCount end
        if endPos < startPos then endPos = startPos end

--d(">>startPos: " ..tos(startPos) .. ", endPos: " ..tos(endPos))

        for itemDataIndex=startPos, endPos, 1 do
            itemsToProcessTab[itemDataIndex].indexInOrigTable = itemDataIndex
            tins(packageData, itemsToProcessTab[itemDataIndex])
        end
        if #packageData > 0 then
--d(">>>inserted package with #entries: " ..tos(#packageData))
            tins(packagesToProcess, packageData)
        end
    end

    local packagesCountToProcess = #packagesToProcess
    if packagesCountToProcess > 0 then
--d(">packagesToProcess: " ..tos(packagesCountToProcess))
        --for each package use zo_callLater with a new delay of 250ms (increase at each package!) and junk mark the items
        local totalDelay = 0
        for packageIndex, packageData in ipairs(packagesToProcess) do
--d(">Package #: " ..tos(packageIndex) .. ", delay: " ..tos(totalDelay))
            zocl(function()
--d("!!!!>>Delayed package call! #" ..tos(packageIndex))
                for _, data in ipairs(packageData) do
                    local processNow = true
                    if preCheckFunc ~= nil then
                        processNow = preCheckFunc(data)
--d("!processNow: " ..tos(processNow))
                    end
                    if processNow == true then
                        local l_retVar = callbackFunc(data)
                        retCount = retCount + 1
                        if l_retVar == true then retVar = true end
--d("!l_retVar: " ..tos(l_retVar) .. "; retVar: " .. tos(retVar) ..", retCount: " ..tos(retCount))
                        if callbackAfterEachEntry ~= nil then
                            callbackAfterEachEntry(data, l_retVar)
                        end
                    end
                end
                --At last package delayed call: Do something?
                if packageIndex == packagesCountToProcess and finalCallbackFunc ~= nil then
                    finalCallbackFunc(retVar, retCount)
                end
            end, totalDelay)
            totalDelay = totalDelay + delay --increase delay by e.g. 250 milliseconds (default value) for each package
        end
    end
    return packagesCountToProcess
end
FCOIS.ProcessPackages = processPackages

function FCOIS.ResetMyGetItemInstanceIdLastVars()
    FCOIS.MyGetItemInstanceIdLast = {
        BagId = nil,
        SlotIndex = nil,
        Id = nil,
        IdSigned = nil,
    }
    --OLD:
    --FCOIS.MyGetItemInstanceIdLastBagId      = nil
    --FCOIS.MyGetItemInstanceIdLastSlotIndex  = nil
    --FCOIS.MyGetItemInstanceIdLastId         = nil
    --FCOIS.MyGetItemInstanceIdLastIdSigned   = nil
end
local resetMyGetItemInstanceIdLastVars = FCOIS.ResetMyGetItemInstanceIdLastVars

function FCOIS.ResetCreateFCOISUniqueIdStringLastVars()
    FCOIS.CreateFCOISUniqueIdStringLast = {
        LastUseType = nil,
        UnsignedItemInstanceId = nil,
        BagId = nil,
        SlotIndex = nil,
        ItemLink = nil,
        FCOISCreatedUniqueId = nil,
    }
    --OLD:
    --FCOIS.CreateFCOISUniqueIdStringLastLastUseType = nil
    --FCOIS.CreateFCOISUniqueIdStringLastLastUnsignedItemInstanceId = nil
    --FCOIS.CreateFCOISUniqueIdStringLastLastBagId = nil
    --FCOIS.CreateFCOISUniqueIdStringLastLastSlotIndex = nil
    --FCOIS.CreateFCOISUniqueIdStringLastLastItemLink = nil
    --FCOIS.CreateFCOISUniqueIdStringLastLastFCOISCreatedUniqueId = nil
end
local resetCreateFCOISUniqueIdStringLastVars = FCOIS.ResetCreateFCOISUniqueIdStringLastVars


--Set the variables for each panel where the number of filtered items can be found for the current inventory
function FCOIS.GetNumberOfFilteredItemsForEachPanel()
    local numberOfFilteredItems = FCOIS.numberOfFilteredItems

    local numFilterdItemsInv = ctrlVars.BACKPACK_LIST.data
    numberOfFilteredItems[LF_INVENTORY]              = numFilterdItemsInv
    --Same like inventory
    numberOfFilteredItems[LF_MAIL_SEND]              = numFilterdItemsInv
    numberOfFilteredItems[LF_TRADE]                  = numFilterdItemsInv
    numberOfFilteredItems[LF_GUILDSTORE_SELL]        = numFilterdItemsInv
    numberOfFilteredItems[LF_BANK_DEPOSIT]           = numFilterdItemsInv
    numberOfFilteredItems[LF_GUILDBANK_DEPOSIT]      = numFilterdItemsInv
    numberOfFilteredItems[LF_VENDOR_BUY]             = 0                      -- TODO FEATURE: Add as filter panel gets supported
    numberOfFilteredItems[LF_VENDOR_SELL]            = numFilterdItemsInv
    numberOfFilteredItems[LF_VENDOR_BUYBACK]         = 0                      -- TODO FEATURE: Add as filter panel gets supported
    numberOfFilteredItems[LF_VENDOR_REPAIR]          = 0                      -- TODO FEATURE: Add as filter panel gets supported
    numberOfFilteredItems[LF_FENCE_SELL]             = numFilterdItemsInv
    numberOfFilteredItems[LF_FENCE_LAUNDER]          = numFilterdItemsInv
    --Others
    numberOfFilteredItems[LF_BANK_WITHDRAW]          = ctrlVars.BANK.data
    numberOfFilteredItems[LF_GUILDBANK_WITHDRAW]     = ctrlVars.GUILD_BANK.data
    numberOfFilteredItems[LF_SMITHING_REFINE]        = ctrlVars.REFINEMENT.data
    numberOfFilteredItems[LF_SMITHING_DECONSTRUCT]   = ctrlVars.DECONSTRUCTION.data
    numberOfFilteredItems[LF_SMITHING_IMPROVEMENT]   = ctrlVars.IMPROVEMENT.data
    numberOfFilteredItems[LF_SMITHING_RESEARCH]      = 0 -- No item count should be shown at the research traits list
    numberOfFilteredItems[LF_SMITHING_RESEARCH_DIALOG] = 0 -- No item count should be shown inside the selected traits popup
    numberOfFilteredItems[LF_ALCHEMY_CREATION]       = ctrlVars.ALCHEMY_STATION.data
    numberOfFilteredItems[LF_ENCHANTING_CREATION]    = ctrlVars.ENCHANTING_STATION.data
    numberOfFilteredItems[LF_ENCHANTING_EXTRACTION]  = numberOfFilteredItems[LF_ENCHANTING_CREATION]
    numberOfFilteredItems[LF_CRAFTBAG]               = ctrlVars.CRAFTBAG_LIST.data
    numberOfFilteredItems[LF_RETRAIT]                = ctrlVars.RETRAIT_LIST.data
    numberOfFilteredItems[LF_HOUSE_BANK_WITHDRAW]    = ctrlVars.HOUSE_BANK.data
    numberOfFilteredItems[LF_JEWELRY_REFINE]         = numberOfFilteredItems[LF_SMITHING_REFINE]
    numberOfFilteredItems[LF_JEWELRY_DECONSTRUCT]    = numberOfFilteredItems[LF_SMITHING_DECONSTRUCT]
    numberOfFilteredItems[LF_JEWELRY_IMPROVEMENT]    = numberOfFilteredItems[LF_SMITHING_IMPROVEMENT]
    numberOfFilteredItems[LF_JEWELRY_RESEARCH]       = numberOfFilteredItems[LF_SMITHING_RESEARCH]
    numberOfFilteredItems[LF_JEWELRY_RESEARCH_DIALOG]= numberOfFilteredItems[LF_SMITHING_RESEARCH_DIALOG]
    numberOfFilteredItems[LF_QUICKSLOT]              = ctrlVars.QUICKSLOT_LIST ~= nil and ctrlVars.QUICKSLOT_LIST.data --Will be updated at DeferredInit again! See FCOIS_Hooks -> onDeferredInitCheck(ctrlVars.QUICKSLOT_KEYBOARD
    --Special numbers for e.g. quest items in inventory
    numberOfFilteredItems["INVENTORY_QUEST_ITEM"]    = playerInvInvs[INVENTORY_QUEST_ITEM].listView.data

    FCOIS.numberOfFilteredItems = numberOfFilteredItems
end

--==========================================================================================================================================
--                                          FCOIS - Is, Get, Set functions
--==========================================================================================================================================

--==============================================================================
-- Get instance & item ID functions
--==============================================================================
--Function to build an itemLink from the itemId. Code from addon "Dolgubon's Lazy Writ Creator"! Thx Dolgubon
function FCOIS.GetItemLinkFromItemId(itemId)
    return strformat("|H1:item:%d:%d:50:0:0:0:0:0:0:0:0:0:0:0:0:%d:%d:0:0:%d:0|h|h", itemId, 0, ITEMSTYLE_NONE, 0, 10000)
end

--Function to get the itemId from an itemLink
function FCOIS.GetItemIdFromItemLink(itemLink)
    return giliid(itemLink)
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

--Get the FCOItemSaver control
-->Check the name of a texture control and see if it exists, then return the control.
--> The control's name is the addon name + a nilable additional parameter "controlNameAddition" + the markerIconId
--> Used to create FCOIS marker icon texture controls with unique names in other addons like Inventory Insight from Ashes (IIfA)!
function FCOIS.GetItemSaverControl(parent, controlId, useParentFallback, controlNameAddition)
    if FCOIS.settingsVars.settings.debug then debugMessage( "[GetItemSaverControl]","Parent: " .. parent:GetName() .. ", ControlId: " .. tos(controlId) .. ", useParentFallback: " .. tos(useParentFallback), true, FCOIS_DEBUG_DEPTH_VERBOSE) end
    local textureNameAddition = (controlNameAddition ~= nil and controlNameAddition) or ""
    local retControl = parent:GetNamedChild(gAddonName .. textureNameAddition .. tos(controlId))
    --Use the parent control as a fallback?
    --e.g. Inside enchanting the parent control is the correct one already
    if retControl == nil and useParentFallback == true then
        return parent
    end
    return retControl
end

function FCOIS.MyGetItemNameNoControl(bagId, slotIndex)
    local name = "Not found"
    local itemData
    local playerInvId = bag2PlayerInv[bagId]
    if playerInvId == nil then return name end
    local invSlots = playerInvInvs[playerInvId].slots
    --CraftBag?
    if playerInvId == INVENTORY_CRAFT_BAG then
        local itemId = giid(bagId, slotIndex)
        itemId = (itemId ~= nil and itemId ~= 0 and itemId) or slotIndex
        itemData = invSlots[BAG_VIRTUAL][itemId] --CraftBag: slotIndex is the itemId of the item, not the inv slotIndex!
    else
        itemData = invSlots[bagId][slotIndex]
    end
    if(itemData ~= nil) then
        name = itemData.name
    end
    return name
end

function FCOIS.Mygin(rowControl)
    --Inventory Insight from Ashes support
    local IIfAclicked = FCOIS.IIfAclicked
    if IIfAclicked ~= nil then
        return gin(IIfAclicked.bagId, IIfAclicked.slotIndex)
    end

    if rowControl == nil then return end
    local dataEntry = rowControl.dataEntry
    --use rowControl = case to handle equiped items
    return (dataEntry == nil and rowControl.name) or dataEntry.data.name
end

function FCOIS.MyGetItemDetails(rowControl)
    --Inventory Insight from ashes support
    local IIfAclicked = FCOIS.IIfAclicked
    local doDebug = FCOIS.settingsVars.settings.debug
    if doDebug == true then FCOIS._rowControlMyGetItemDetails = rowControl end
    if IIfAclicked ~= nil then
        if doDebug == true then FCOIS._rowControlMyGetItemDetailsIIfAClicked = ZO_ShallowTableCopy(IIfAclicked) end
        return IIfAclicked.bagId, IIfAclicked.slotIndex
    end
    local bagId, slotIndex

    --gotta do this in case deconstruction, or player equipment
    local dataEntry = rowControl.dataEntry
    local isDataEntryNil = (dataEntry == nil and true) or false
    local dataEntryData = (isDataEntryNil == false and dataEntry.data) or nil

    --use rowControl = case to handle equiped items
    --bag/index = case to handle list dialog, list dialog uses index instead of slotIndex and bag instead of bagId...?
    if isDataEntryNil == true then
        bagId = rowControl.bagId
        slotIndex = rowControl.slotIndex
    else
        bagId = dataEntryData.bagId
        bagId = bagId or dataEntryData.bag
        slotIndex = dataEntryData.slotIndex
        slotIndex = slotIndex or dataEntryData.index
    end
    --Is the bagId still nil: Check if it's a questItem, or a store buy item
    if bagId == nil then
        if rowControl.questIndex ~= nil then
            if rowControl.GetParent then
                local parentCtrl = rowControl:GetParent()
                local parentDataEntry = parentCtrl.dataEntry.data
                bagId, slotIndex = BAG_BACKPACK, parentDataEntry.slotIndex
            end
            --Store buy
        elseif rowControl.slotType == SLOT_TYPE_STORE_BUY or rowControl.slotType == SLOT_TYPE_BUY_MULTIPLE then
            bagId = nil
            slotIndex = dataEntryData.slotIndex
            --[[
        elseif rowControl.index and rowControl.slotType then
            if rowControl.slotType == SLOT_TYPE_STORE_BUY or rowControl.slotType == SLOT_TYPE_BUY_MULTIPLE then
                return GetStoreItemLink(rowControl.index, LINK_STYLE_BRACKETS)

            elseif rowControl.slotType == SLOT_TYPE_STORE_BUYBACK then
                return GetBuybackItemLink(rowControl.index, LINK_STYLE_BRACKETS)
            end
]]
        end
    end
    return bagId, slotIndex
end
local myGetItemDetails = FCOIS.MyGetItemDetails

function FCOIS.MyGetItemDetailsByBagAndSlot(bagId, slotIndex)
    if bagId == nil or slotIndex == nil then return false end
    --Get the dataEntry / data from the bag cache
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
    if bagCache ~= nil and bagCache[slotIndex] ~= nil then
        return bagCache[slotIndex]
    end
    return nil
end

--Check if the given item ID is already a converted id64String (real uniqueId stored as String)
--or if its a , concatenated String of "<itemId>,<levelNumber>,<qualityId>,<traitId>,<styleId>,<enchantId>, ...." (uniqueId based on the data)
-->If not , concatenated String and uniqueIds are enabled: Convert it into an id64String
function FCOIS.CheckItemId(itemId, addonName)
    if itemId == nil then return end
    local retItemId = itemId
    --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids)
    if FCOIS.settingsVars.settings.useUniqueIds or checkIfAddonNameHasTemporarilyEnabledUniqueIds(addonName) == true then
        --Check if the given uniqueID is already transfered to the string, and if not do so
        if type(itemId) ~= "string" then
            retItemId = zogsid64(itemId)
        end
    end
    --d("FCOIS.checkItemId: " ..tos(retItemId))
    return retItemId
end

function FCOIS.GetFCOISMarkerIconUniqueIdAllowedItemType(bagId, slotIndex, uniqueItemIdType)
    local allowedItemtype
    local settings = FCOIS.settingsVars.settings
    --Non-unique itemIds are enabled so all itemTypes are allowed for the itemInstanceId markers
    if not settings.useUniqueIds then return true end

    if uniqueItemIdType == nil then
        uniqueItemIdType = settings.uniqueItemIdType
        uniqueItemIdType = uniqueItemIdType or FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE
    end
    local itemType = git(bagId, slotIndex)
    if uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then -- ZOs real unique IDs
        --Only armor and weapons and jewelry count as allowed itemType
        allowedItemtype = allowedUniqueItemTypes[itemType] or false
    else
        --All selected itemTypes at the settings of unique FCOIS marker icon IDs are allowed itemtypes
        allowedItemtype = settings.allowedFCOISUniqueIdItemTypes[itemType] or false
    end
    return allowedItemtype
end
local getFCOISMarkerIconUniqueIdAllowedItemType = FCOIS.GetFCOISMarkerIconUniqueIdAllowedItemType

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
                itemId = zogsid64(giuid(bagId, slotIndex))
            elseif uniqueIdsTypeForMarkerIcons == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE then --FCOIS onw build unique IDs
                itemId = createFCOISUniqueIdString(giid(bagId, slotIndex), bagId, slotIndex, nil)
            end
        end
    end
    if useNormalItemInstanceId == true then
        local itemInstanceId = giiid(bagId, slotIndex)
        --Sign the itemInstanceId now
        if signToo == true then
            --3rd parameter onlySign == true will force to sign the itemInstanceId without further checks
            itemId = signItemId(itemInstanceId, allowedItemType, true, nil, bagId, slotIndex)
        else
            --Will be signed later on, e.g. if this function here was called via function FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex, signToo)
            --where signToo == true -> Then FCOIS.SignItemId will be called from that function + updates internal variables
            itemId = itemInstanceId
        end
    end
    return itemId, allowedItemType
end
local getFCOISMarkerIconSavedVariablesItemId = FCOIS.GetFCOISMarkerIconSavedVariablesItemId

--Converts unsigned itemId to signed
--itemId is the itemId, or the itemInstaneId or the itemUniqueId
--allowedItemType is the itemType of the item (e.g. armor, weapon, jewelry) used for the uniqueId checks as non gear icons do not need to be saved with uniqueIds.
--If addonName parameter is given it will check if the temporary use of uniqueIds was enabled for this addon
--and use the unique Id then for the checks (even if the FCOIS settings are not enabled to use uniqueIds).
function FCOIS.SignItemId(itemId, allowedItemType, onlySign, addonName, bagId, slotIndex)
    signItemId = signItemId or FCOIS.SignItemId
    allowedItemType = allowedItemType or false
    onlySign = onlySign or false
    local itemIDTypeIsString = (type(itemId) == "string") or false

--Attention: Removing the comment in front of the following line will make the game client LAG a lot upon opening the inventory!
--d("[FCOIS.SignItemId] itemId: " ..tos(itemId) ..", allowedItemType: " .. tos(allowedItemType) .. ", onlySign: " .. tos(onlySign) ..", addonName: " ..tos(addonName))

    --Shall the function not only sign an itemInstanceId, but check if the unique IDs need to be created/checked?
    if not onlySign then
        local settings = FCOIS.settingsVars.settings
        --Support for base64 unique itemIds (e.g. an enchanted armor got the same ItemInstanceId but can have different unique IDs).
        --But only if the itemType was checked before and is an allowed itemtype for the unique ID checks (e.g. armor, weapons)
        --or the itemId is a string (which is the unique ID (ZOs and FCOIS) format)
        if (settings.useUniqueIds == true and allowedItemType == true)
            or addonName ~= nil and checkIfAddonNameHasTemporarilyEnabledUniqueIds(addonName) == true
            or itemIDTypeIsString == true then
            --itemId as string could be the int64UniqueId stored as String (really unique for each item!),
            --or since FCOIS v1.9.6 a , concatenated String of "<unsignedItemInstanceIdOrItemId>,<levelNumber>,<qualityId>,<traitId>,<styleId>,<enchantId>,<isStolen>,<isCrafted>..."
            --If it's not a string: Create one
            if not itemIDTypeIsString then
                local uniqueItemIdType = settings.uniqueItemIdType
                itemId, allowedItemType = getFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, allowedItemType, settings.useUniqueIds, uniqueItemIdType)
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
signItemId = FCOIS.SignItemId

--Get the item's instance id or unique ID
--OLD function before "dragon bones" patch
function FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex, signToo)
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage("[MyGetItemInstanceIdNoControl]", "bagId: " ..tos(bagId) .. ", slotIndex: " ..tos(slotIndex).. ", signToo: " ..tos(signToo), true, FCOIS_DEBUG_DEPTH_VERBOSE) end

    signToo = signToo or false
    --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids)
    local itemId
    local allowedItemType
    --Cache the last used bagId and slotIndex for the cached iteminstance or uniqueId
    -->Reset the last ID if he bagId or slotIndex changes
    local myGetItemInstanceIdLastData = FCOIS.MyGetItemInstanceIdLast
    if (bagId == nil or myGetItemInstanceIdLastData.BagId == nil or myGetItemInstanceIdLastData.BagId ~= bagId) or
            (slotIndex == nil or myGetItemInstanceIdLastData.SlotIndex== nil or myGetItemInstanceIdLastData.SlotIndex ~= slotIndex) then
        --d(">resetting cached bag, slot and itemIds")
        --Reset the cached last ID
        FCOIS.MyGetItemInstanceIdLast.Id = nil
        FCOIS.MyGetItemInstanceIdLast.IdSigned = nil
    end
    FCOIS.MyGetItemInstanceIdLast.BagId = bagId
    FCOIS.MyGetItemInstanceIdLast.SlotIndex = slotIndex

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
        if settings.debug then debugMessage("[MyGetItemInstanceIdNoControl]LF_INVENTORY_COMPANION", ">useUniqueIds: " .. tos(settings.useUniqueIds) .. ", allowedItemType: " .. tos(allowedItemType), true, FCOIS_DEBUG_DEPTH_VERBOSE) end
        --d("[FCOIS.MyGetItemInstanceINoControl] useUniqueIds: " .. tos(settings.useUniqueIds) .. ", allowedItemType: " .. tos(allowedItemType))

        --Use the cached itemId first
        itemId = myGetItemInstanceIdLastData.Id
        --If there was nothing cached: Build it new
        if itemId == nil then
            itemId, allowedItemType = getFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, nil, settings.useUniqueIds, settings.uniqueItemIdType, not signToo)
            --Cache the last ID so that loops won't rebuild the whole id for the same bagId + slotIndex (if all marker icons are checked)
            FCOIS.MyGetItemInstanceIdLast.Id = itemId
        end
        if settings.useUniqueIds == true and allowedItemType == true then
            --Prevent calling FCOIS.SignItemId:
            --Unique IDs do not need to be signed as only numbers get signed but uniqueIds are Strings
            return itemId, allowedItemType
        end
    end
    if signToo == true then
        if myGetItemInstanceIdLastData.IdSigned == nil then
            local itemInstanceIdSigned = signItemId(itemId, allowedItemType, nil, nil, bagId, slotIndex)
            FCOIS.MyGetItemInstanceIdLast.IdSigned = itemInstanceIdSigned
            return itemInstanceIdSigned, allowedItemType
        else
            return myGetItemInstanceIdLastData.IdSigned, allowedItemType
        end
    end
    return itemId, allowedItemType
end
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl

--LAGGY if applied to multiple items at once! So only use for backup.
-- itemId is basically what tells us that two items are the same thing,
-- but some types need additional data to determine if they are of the same strength (and value).
local function getItemIdentifierForBackup(bagId, slotIndex)
    --ItemLik fields/indices:
    --socket = enchantment
    --"linkStyle:type:id:quality:requiredLevel:socketItem:socketItemQuality:socketRequiredLevel:extraField1:extraField2:extraField3:extraField4:extraField5:extraField6:unused:unused:allFlags:style:crafted:bound:stolen:enchantCharges/condition:instanceData"
    local itemLink = gil(bagId, slotIndex)
    if itemLink == nil or itemLink == "" then return nil end
    local itemId
    if giliid ~= nil then
        itemId = ton(giliid(itemLink)) -- Function will be added soon, ZOS_ChipHilseberg added it on 14.02.2018 to the dev system internally
    else
        itemId = ton(giid(bagId, slotIndex))
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
    local itemType = gilit(itemLink)
    if(itemType == ITEMTYPE_WEAPON or itemType == ITEMTYPE_ARMOR) then
        local level = gilrl(itemLink)
        local cp = gilrcp(itemLink)
        --Is the unique item ID enabled and the item's type is an allowed one(e.g. weapons, armor, ...)
        local allowedItemType = allowedUniqueItemTypes[itemType] or false
        local useUniqueItemIdentifier = (settings.useUniqueIds and allowedItemType) or false
        local trait = gilti(itemLink)
        local quality = gilfq(itemLink)
        if useUniqueItemIdentifier then
            --Then check the enchantment + quality + level too
            --:socketItem: = 6, :socketItemQuality: = 7, :socketRequiredLevel: = 8
            local itemStyle = gilis(itemLink)
            local data = {zostrspl(":", itemLink:match("|H(.-)|h.-|h"))}
            local enchantment = tos(data[6]) ..",".. tos(data[7]).."," .. tos(data[8])
            --local quality = data[4]
            return strformat("%d,%d,%d,%d,%d,%d,%s", itemId, quality, trait, level, cp, itemStyle, enchantment)
        else
            --No enchantment checks
            return strformat("%d,%d,%d,%d,%d", itemId, quality, trait, level, cp)
        end
    elseif(itemType == ITEMTYPE_POISON or itemType == ITEMTYPE_POTION) then
        local level = gilrl(itemLink)
        local cp = gilrcp(itemLink)
        local data = {zostrspl(":", itemLink:match("|H(.-)|h.-|h"))}
        return strformat("%d,%d,%d,%s", itemId, level, cp, data[23])
    elseif(hasDifferentQualities[itemType]) then
        local quality = gilfq(itemLink)
        return strformat("%d,%d", itemId, quality)
    else
        return itemId
    end
end

function FCOIS.MyGetItemInstanceIdNoControlForBackup(bagId, slotIndex, signToo)
    signToo = signToo or false
    --Support for base64 unique itemids (e.g. an enchanted armor got the same ItemInstanceId but can have different unique ids)
    local buildItemIdentifier = getItemIdentifierForBackup(bagId, slotIndex)
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
        bagId, slotIndex = myGetItemDetails(rowControl)
    end
    --If the bagid and slotIndex are empty here the itemInstanceOrUniqueId will be read from FCOIS.IIfAclicked in function FCOIS.MyGetItemInstanceIdNoControl!
    local itemId = myGetItemInstanceIdNoControl(bagId, slotIndex, signToo)
    return itemId
end

function FCOIS.ExtractItemIdFromItemLink(itemLink)
    --if giliid ~= nil then
        return giliid(itemLink)
    --else
        --return ton(strmatch(itemLink,"|H%d:item:(%d+)"))
    --end
end

--Create a unique String as "uniqueID" for an allowed itemtype of an item:
--"<unsignedItemIdOrItemInstanceId>,<levelNumber>,<qualityId>,<traitId>,<styleId>,<enchantId>,<isStolen>,<isCrafted>,<craftedByName>"
-->Depending on the chosen uniqeId "parts" settings and the itemType of the item!
--Parameters bagId and slotIndex or itemLink must be given!
--If only the parameter itemLink is given the parameter unsignedItemInstanceId must be given as well, as there is no GetItemLinkIteminstaceId function :-(
--->If only itemLink is given, use the itemId here instead of the ItemInstanceId then, as some addons like IventoryInsight from ashes do not provide bagId and slotIndex at all!
--->Yes, changed to that way, also because the itemInstanceId always differs level/quality/enchantment etc. already and if we want to manually specify which parts the FCOIS uniqueId needs, we need to use the itemId as base!
--If bagId and slotIndex are given unsignedItemInstanceId can be nil (will be rebuild internally then).
--If allowedItemType (boolean) is not given then the itemType will be rebuild from the bagId & slotIndex, or the itemlink, and the value will be checked against FCOIS.checkVars.uniqueIdItemTypes[itemType] afterwards.
function FCOIS.CreateFCOISUniqueIdString(itemId, bagId, slotIndex, itemLink)
    local numVars = FCOIS.numVars
    createFCOISUniqueIdString = createFCOISUniqueIdString or FCOIS.CreateFCOISUniqueIdString
    --Either bag + slot or itemLink needs to be given
    if (not bagId or not slotIndex) and (not itemLink or itemLink == "") then return end
    --Get or use the itemLink
    if bagId and slotIndex and not itemLink then
        itemLink = gil(bagId, slotIndex)
    end
--d("[FCOIS]CreateFCOISUniqueIdString - " ..itemLink)
    if not itemLink or itemLink == "" then return end

    --Get the item's base data like itemInstanceId, level, quality
    if not itemId then
        if bagId and slotIndex then
            --Use the ItemInstanceId
            --unsignedItemInstanceId = giiid(bagId, slotIndex)
            --Use the itemId
            itemId = giid(bagId, slotIndex)
        else
            --No bag or slot? Use the itemId of the itemLink -> e.g. Addon Inventory Insight From Ashes
            -->TODO BUG OR WORKING?: This might become buggy if one extracts the first value of the returned String (the itemId in this case) and tries to get entries in the SavedVariables
            -->TODO BUG OR WORKING?: of "markedItems" using only this itemId, instead of the "signed" ItemInstanceId. One would need to check the inventory item's signed itemId and only if it
            -->TODO BUG OR WORKING?: matches get bagId and slotIndex of that item to do further checks
            itemId = giliid(itemLink)
        end
    end
    if not itemId then return end

    --------------------------------------------------------------------------------------------------------------------
    --Cache the last used unsignedItemInstanceId + bagId  + slotIndex,
    --or Cache the last used unsignedItemInstanceId + itemlink
    -->Reset the last ID if the combination changes
    --Last itemLink not known?
    local createFCOISUniqueIdStringLastData = FCOIS.CreateFCOISUniqueIdStringLast
    local lastUsedLastUsedType      = createFCOISUniqueIdStringLastData.LastUseType
    if lastUsedLastUsedType == nil or lastUsedLastUsedType > numVars.lastUsedTypes then
--d(">resetting all variables")
        --Reset all variables
        resetCreateFCOISUniqueIdStringLastVars()
    end

    local lastUsedItemInstanceId    = createFCOISUniqueIdStringLastData.UnsignedItemInstanceId
    local lastBagId                 = createFCOISUniqueIdStringLastData.BagId
    local lastSlotIndex             = createFCOISUniqueIdStringLastData.SlotIndex
    local lastItemLink              = createFCOISUniqueIdStringLastData.ItemLink
    local lastFCOISuniqueId         = createFCOISUniqueIdStringLastData.FCOISCreatedUniqueId

    --Did we cache something already?
    if lastUsedLastUsedType ~= nil and lastUsedItemInstanceId ~= nil and lastUsedItemInstanceId == itemId
        and lastFCOISuniqueId ~= nil then
        --unsignedItemInstanceId + bagId, slotIndex
        if lastUsedLastUsedType == FCOIS_CON_FCOISUNIQUEID_TYPE_BAGID_SLOTINDEX then
            if (bagId ~= nil and lastBagId ~= nil and bagId == lastBagId) and
               (slotIndex ~= nil and lastSlotIndex ~= nil and slotIndex == lastSlotIndex) then
--d("<returning cached bagId/slotIndex value: " ..tos(lastFCOISuniqueId))
                return lastFCOISuniqueId
            end
        --unsignedItemInstanceId + ItemLink
        elseif lastUsedLastUsedType == FCOIS_CON_FCOISUNIQUEID_TYPE_ITEMLINK then
            if (itemLink ~= nil and lastItemLink ~= nil and itemLink == lastItemLink) then
--d("<returning cached itemLink value: " ..tos(lastFCOISuniqueId))
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
    local itemType
    local level
    local quality
    local trait
    local style
    local enchantment
    local isStolen
    local isCrafted
    local craftedByName
    local isCrownItem

    if uniqueIdParts.level == true then
        local cpLevel = gilrcp(itemLink)
        if cpLevel ~= nil then
            level = cpLevel
        else
            level = gilrl(itemLink)
        end
    end
    if level == nil then level = "" end

    --Add item's quality to the uniqueId?
    if uniqueIdParts.quality == true then
        quality = gilfq(itemLink)
    end
    if quality == nil then quality = "" end

    --Get the values for the uniqueId parts depending on the itemType
    itemType = gilit(itemLink)
    if itemType == ITEMTYPE_ARMOR or itemType == ITEMTYPE_WEAPON then
        --Add item's trait to the uniqueId?
        if uniqueIdParts.trait == true then
            trait = gilti(itemLink)
        end
        if trait == nil then trait = "" end

        --Add item's enchantment to the uniqueId?
        if uniqueIdParts.enchantment == true then
            enchantment = gilaeid(itemLink)
        end
        if enchantment == nil then enchantment = "" end

        --Add item's style to the uniqueId?
        if uniqueIdParts.style == true then
            style = gilis(itemLink)
        end
        if style == nil then style = "" end

        --Add item's isCrafted state to the uniqueId?
        if uniqueIdParts.isCrafted == true then
            isCrafted = booleanToNumber(isilcr(itemLink))
            if isCrafted == 1 then
                if uniqueIdParts.isCraftedBy == true then
                    if bagId and slotIndex then
                        craftedByName = gicn(bagId, slotIndex)
                    end
                end
            end
        end
        if isCrafted == nil then isCrafted = 0 end
        if craftedByName == nil then craftedByName = ""
        else
            craftedByName = hashstr(craftedByName) --Create a hash number of the crafter's name
        end
    end

    --Add item's isStolen state to the uniqueId?
    if uniqueIdParts.isStolen == true then
        isStolen = booleanToNumber(isilst(itemLink))
    end
    if isStolen == nil then isStolen = 0 end

    --If item is a crown item add it to the uniqueId?
    if uniqueIdParts.isCrownItem == true then
        local isCrownStoreItem = isilfcs(itemLink) or isilfcc(itemLink)
        isCrownItem = booleanToNumber(isCrownStoreItem)
    end
    if isCrownItem == nil then isCrownItem = 0 end
    --------------------------------------------------------------------------------------------------------------------

    --Build the uniqueId string now
    local uniqueItemIdString = strformat(uniqueItemIdStringTemplate, itemId,
            tos(level),tos(quality),tos(trait),tos(style),tos(enchantment),
            tos(isStolen),
            tos(isCrafted),tos(craftedByName),
            tos(isCrownItem)
    )

    --------------------------------------------------------------------------------------------------------------------
    --Cache the current values and set the last used type
    resetCreateFCOISUniqueIdStringLastVars()
    local lastCreatedUniqueIDStringData = FCOIS.CreateFCOISUniqueIdStringLast
    lastCreatedUniqueIDStringData.UnsignedItemInstanceId = itemId
    if bagId ~= nil and slotIndex ~= nil then
        lastCreatedUniqueIDStringData.BagId        = bagId
        lastCreatedUniqueIDStringData.SlotIndex    = slotIndex
        lastCreatedUniqueIDStringData.ItemLink     = nil
        lastCreatedUniqueIDStringData.LastUseType  = FCOIS_CON_FCOISUNIQUEID_TYPE_BAGID_SLOTINDEX
    elseif itemLink ~= nil then
        lastCreatedUniqueIDStringData.ItemLink     = itemLink
        lastCreatedUniqueIDStringData.BagId        = nil
        lastCreatedUniqueIDStringData.SlotIndex    = nil
        lastCreatedUniqueIDStringData.LastUseType  = FCOIS_CON_FCOISUNIQUEID_TYPE_ITEMLINK
    end
    lastCreatedUniqueIDStringData.FCOISCreatedUniqueId = uniqueItemIdString
    --------------------------------------------------------------------------------------------------------------------

--d("<"..tos(uniqueItemIdString) .. ", lastUsedType: " .. tos(FCOIS.CreateFCOISUniqueIdStringLastLastUseType))
    return uniqueItemIdString
end
createFCOISUniqueIdString = FCOIS.CreateFCOISUniqueIdString

--  Check that icon is not sell or sell at guild store
--  and the setting to remove sell/sell at guild store is enabled if any other marker icon is set?
function FCOIS.CheckIfOtherDemarksSell(iconId)
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
local checkIfOtherDemarksSell = FCOIS.CheckIfOtherDemarksSell

--  Check that icon is not deconstruction
--  and the setting to remove deconstruction is enabled if any other marker icon is set?
--  Also check the exclusion of dynamic icons!
function FCOIS.CheckIfOtherDemarksDeconstruction(iconId)
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
local checkIfOtherDemarksDeconstruction = FCOIS.CheckIfOtherDemarksSell


--Check if all of the item's markers should be removed, if one marker icon "iconId" gets set
function FCOIS.CheckIfItemShouldBeDemarked(iconId)
    if iconId == nil then return false end
    local settings = FCOIS.settingsVars.settings
    --Check if all other marker icons should be removed as this marker icon get's set
    if settings.icon[iconId].demarkAllOthers then
        return true
    end
    local automaticDeMarkSettings = FCOIS.mappingVars.automaticDeMarkSettings
    local automaticDeMarkData = automaticDeMarkSettings[iconId]
    if not automaticDeMarkData then return false end
    if not settings[automaticDeMarkData] then
        return false
    else
        return true
    end
end

--==============================================================================
-- Get control functions
--==============================================================================
--Check as long until the control with the name controlName exists, and then call the function 'callbackFunc' in the 2nd parameter
--The checks will be done every 10ms or every 3rd parameter stepTocheckMS
--This function will automatically abort itsself after 4rd parameter 'autoAbortTimeMS' time in ms has passed. Standard value is 30 seconds
function FCOIS.CheckRepetitivelyIfControlExists(controlName, callbackFunc, stepTocheckMS, autoAbortTimeMS)
    if not callbackFunc or callbackFunc == nil then return false end
    checkRepetitivelyIfControlExists = checkRepetitivelyIfControlExists or FCOIS.CheckRepetitivelyIfControlExists
    --Automatically abort this repetively check-function after this time in milliseconds
    autoAbortTimeMS = autoAbortTimeMS or 30000
    --The milliseconds to wait for the next check
    stepTocheckMS = stepTocheckMS or 10
    --Build the event manager uinque control check updater name
    local checkControlname = addonVars.gAddonName .. "___" .. tos(controlName)
    --Build needed global variables
    if FCOIS.preventerVars.isControlCheckActive[checkControlname] == nil then FCOIS.preventerVars.isControlCheckActive[checkControlname] = false end
    if FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] == nil then FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] = 0 end
    --Get the control by help of it's name
    local control = GetControl(controlName) --wm:GetControlByName(controlName, "")
    --Check if control exists
    if control == nil then
        --d("[FCOIS.checkRepetivelyIfControlExists - control " .. tos(controlName) .. " does not exist so far...")
        --Control does not exist so check again in 10ms (variable -> stepTocheckMS)
        if FCOIS.preventerVars.isControlCheckActive[checkControlname] then
            em:UnregisterForUpdate(checkControlname)
            FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] = FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] + stepTocheckMS
            if FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] >= autoAbortTimeMS then
                --d("°°° [FCOIS.checkRepetivelyIfControlExists - control " .. tos(controlName) .. " was not found until now. ABORTING after " .. autoAbortTimeMS .. " ms now!!!")
                --d("[FCOIS.checkRepetivelyIfControlExists - ABORTED check " .. checkControlname)
                return false
            end
        else
            FCOIS.preventerVars.isControlCheckActive[checkControlname] = true
            FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] = 0
            --d("[FCOIS.checkRepetivelyIfControlExists - START check " .. checkControlname)
        end
        em:RegisterForUpdate(checkControlname, stepTocheckMS, function()
            checkRepetitivelyIfControlExists(controlName, callbackFunc, stepTocheckMS, autoAbortTimeMS)
        end)
    else
        --d("[FCOIS.checkRepetivelyIfControlExists - control " .. tos(controlName) .. " is finally here after " .. FCOIS.preventerVars.controlCheckActiveCounter[checkControlname] .. " ms!")
        --d("[FCOIS.checkRepetivelyIfControlExists - END check " .. checkControlname)
        --Control exists finally!
        em:UnregisterForUpdate(checkControlname)
        FCOIS.preventerVars.isControlCheckActive[checkControlname] = false
        --Execute the callback function now
        --d(">> Running callback function now...")
        callbackFunc()
        return true
    end
end
checkRepetitivelyIfControlExists = FCOIS.CheckRepetitivelyIfControlExists

--Check if a controlName is an inventory row pattern defined in file FCOIS_Constants.lua, table FCOIS.checkVars.inventoryRowPatterns
--Function returns as 1st return value a boolean isAnInventoryRowWithPattern, and as 2nd return value the pattern
function FCOIS.IsSupportedInventoryRowPattern(controlName)
    if not controlName then return false, nil end
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
    local mouseOverControl = wm:GetMouseOverControl()
    if mouseOverControl == nil then return end
--d("[FCOIS.GetBagAndSlotFromControlUnderMouse] " .. mouseOverControl:GetName())
    local bagId
    local slotIndex
    local itemLink
    local itemInstanceOrUniqueIdIIfA
    FCOIS.IIfAmouseOvered = nil
    if inventoryRowPatterns == nil then return end
    --For each inventory row pattern check if the current control mouseOverControl's name matches this pattern
    local mouseOverControlName = mouseOverControl:GetName()
--d(">row control name: " .. tos(mouseOverControlName))
    local isInvRow, patternToCheck = isSupportedInventoryRowPattern(mouseOverControlName)
    if isInvRow == true then
--d(">>row is supported pattern!")
        if patternToCheck == IIfAInvRowPatternToCheck then
            --Special treatment for the addon InventoryInsightFromAshes
            controlTypeBelowMouse = IIFAitemsListEntryPrePattern
            itemLink, itemInstanceOrUniqueIdIIfA, bagId, slotIndex = FCOIS.CheckAndGetIIfAData(mouseOverControl, mouseOverControl:GetParent())
            if bagId == nil or slotIndex == nil and itemInstanceOrUniqueIdIIfA ~= nil then
                FCOIS.IIfAmouseOvered = {}
                FCOIS.IIfAmouseOvered.itemLink = itemLink
                FCOIS.IIfAmouseOvered.itemInstanceOrUniqueId = itemInstanceOrUniqueIdIIfA
            end
        else
            bagId, slotIndex = myGetItemDetails(mouseOverControl)
        end
    end
    if bagId ~= nil and slotIndex ~= nil then
        return bagId, slotIndex, mouseOverControl, controlTypeBelowMouse
    else
        return false, nil, mouseOverControl, controlTypeBelowMouse
    end
end

--==============================================================================
-- Is Item functions
--==============================================================================
function FCOIS.DoesPlayerInventoryCurrentFilterEqual(inventoryVar, currentFilter)
    return (playerInvInvs[inventoryVar].currentFilter == currentFilter) or false
end
local doesPlayerInventoryCurrentFilterEqual = FCOIS.DoesPlayerInventoryCurrentFilterEqual

function FCOIS.DoesPlayerInventoryCurrentFilterEqualCompanion(panelId)
--d("[FCOIS]DoesPlayerInventoryCurrentFilterEqualCompanion - panelId: " ..tos(panelId))
    local invType = libFiltersPanelIdToInventory[panelId]
    if invType == nil then return end
    return doesPlayerInventoryCurrentFilterEqual(invType, ITEM_TYPE_DISPLAY_CATEGORY_COMPANION)
end

-- Check if an itemLink owner is a companion
function FCOIS.IsItemLinkOwnerCompanion(itemLink)
    return (gilac(itemLink) == GAMEPLAY_ACTOR_CATEGORY_COMPANION) or false
end
local isItemLinkOwnerCompanion = FCOIS.IsItemLinkOwnerCompanion

-- Check if an item owner is a companion
function FCOIS.IsItemOwnerCompanion(bagId, slotIndex, itemLink)
--d("[FCOIS]IsItemOwnerCompanion")
    if bagId ~= nil and slotIndex ~= nil then
        return (giac(bagId, slotIndex) == GAMEPLAY_ACTOR_CATEGORY_COMPANION) or false
    elseif itemLink ~= nil then
        return isItemLinkOwnerCompanion(itemLink)
    end
    return false
end
local isItemOwnerCompanion = FCOIS.IsItemOwnerCompanion


--Check if the icon (if provided! Must be provided for keybind checks, can be nil for additional inventory "flag" context menu checks) is
--one of the icons that cannot be applied to items that are companion owned (e.g. research, deconstruct, improve, sell at guildstore. intricate)
--Return value will be "allowed" (=true) or "blocked" (=false)
function FCOIS.DoCompanionItemChecks(bagId, slotIndex, iconId, isCompanionInventory, viaKeybind, removeAll, itemLink, isCompanionOnwed)
--d("[FCOIS]DoCompanionItemChecks " ..gil(bagId, slotIndex) .. ", iconId: " ..tos(iconId).. ", isCompanionInventory: " ..tos(isCompanionInventory) .. ", viaKeybind: " ..tos(viaKeybind))
    viaKeybind = viaKeybind or false
    --icon is not given but we try to apply a keybinding? Return "allowed" as fallback
    if viaKeybind == true and iconId == nil then
        return false --blocked
    end
    if isCompanionOnwed == nil then
        isCompanionOnwed = isItemOwnerCompanion(bagId, slotIndex, itemLink)
    end
--d(">isCompanionOnwed: " ..tos(isCompanionOnwed))
    if isCompanionOnwed == true then
        --No icon given (via add. inv. "flag" context menu)
        if iconId == nil then
            --All icons should be removed? Allow
            if removeAll == true then return true end
            return false --blocked
        end
        local iconsDisabledAtCompanion = FCOIS.mappingVars.iconIsDisabledAtCompanion
        --Icon that should not be applied to companion owned items
        local isIconDisabledAtCompanion = iconsDisabledAtCompanion[iconId] or false
        return not isIconDisabledAtCompanion --"blocked" or "allowed" (if not in table FCOIS.mappingVars.iconIsDisabledAtCompanion)
    end
    return true --allowed
end

--Is the companion interacted with and is the companion inventory shown? Used within file src/FCOIS_MarkerIcons.lua, function FCOIS.CreateTextures
--at call to addMarkerIconsToZOListViewNow
function FCOIS.CheckIfCompanionInteractedAndCompanionInventoryIsShown()
    isCompanionInventoryShown = isCompanionInventoryShown or FCOIS.IsCompanionInventoryShown
    local currentLibFiltersFilterType
    local isCompanionInventoryShownNow = isCompanionInventoryShown()
    if isCompanionInventoryShownNow == true then
        currentLibFiltersFilterType = LF_INVENTORY_COMPANION
    end
    return currentLibFiltersFilterType
end

--Is the item bound or stolen it cannot be sold at a guild store
--#252
function FCOIS.IsUnboundAndNotStolenItemChecks(bagId, slotIndex, iconId, isBoundPassedIn, doCheckOnlyUnbound, isStolenPassedIn, doCheckOnlyNotStolen)
    if iconId == FCOIS_CON_ICON_SELL_AT_GUILDSTORE then
        doCheckOnlyNotStolen = true
    end
    doCheckOnlyNotStolen = doCheckOnlyNotStolen or false
    local isAllowed = true
    local isBound = isBoundPassedIn
    local isStolen = isStolenPassedIn
    if isBound == nil then
        isBound = IsItemBound(bagId, slotIndex)
    end
    if isBound == true then
        if doCheckOnlyUnbound == nil then
            doCheckOnlyUnbound = FCOIS.settingsVars.settings.allowOnlyUnbound[iconId]
        end
        doCheckOnlyUnbound = doCheckOnlyUnbound or false
        if doCheckOnlyUnbound == true then
            isAllowed = false
        end
    end
    if isStolen == nil then
        isStolen = IsItemStolen(bagId, slotIndex)
    end
    if isAllowed == true and doCheckOnlyNotStolen == true and isStolen == true then
        isAllowed = false
    end
    return isAllowed, isBound, isStolen
end

function FCOIS.IsItemType(bag, slot, itemTypes)
    if not itemTypes then return false end
    local isItemTypeVar
    if type(itemTypes) == "table" then
        for _, itemType in ipairs(itemTypes) do
            isItemTypeVar = (git(bag, slot) == itemType)
            if isItemTypeVar == true then return true end
        end
    else
        return (git(bag, slot) == itemTypes)
    end
    return false
end

function FCOIS.IsItemAGlpyh(bag, slot)
    if bag == nil or slot == nil then return false end
    local glypItemTypesAllowed = {
        [ITEMTYPE_GLYPH_ARMOR] =    true,
        [ITEMTYPE_GLYPH_JEWELRY] =  true,
        [ITEMTYPE_GLYPH_WEAPON] =   true,

    }
    local itemType = git(bag, slot)
    --[[
    local isArmorGlyph		= (itemType == ITEMTYPE_GLYPH_ARMOR)
    local isJewelryGlyph	= (itemType == ITEMTYPE_GLYPH_JEWELRY)
    local isWeaponGlyph		= (itemType == ITEMTYPE_GLYPH_WEAPON)
    local resultVar = (isArmorGlyph or isJewelryGlyph or isWeaponGlyph)
    ]]
    local resultVar = glypItemTypesAllowed[itemType] or false
    --d("[FCOIS.isItemAGlpyh - isArmorGlyph: ".. tos(isArmorGlyph) .. ", isJewelryGlyph: " .. tos(isJewelryGlyph) .. ", isWeaponGlyph: " .. tos(isWeaponGlyph) .. " - return: " .. tos(resultVar))
    return resultVar
end

function FCOIS.IsItemSetAndNotExcluded(bag, slot)
    if bag == nil or slot == nil then return false end
    local isAllowedSet, _, _, _, _, setId = gilsetinf(gil(bag, slot), false)
    if isAllowedSet == true and setId ~= nil then
        local settings = FCOIS.settingsVars.settings
        if settings.autoMarkSetsExcludeSets == true then
            local autoMarkSetsExcludeSetsList = settings.autoMarkSetsExcludeSetsList
            if autoMarkSetsExcludeSetsList[setId] == true then
                isAllowedSet = false
            end
        end
    end
    return isAllowedSet
end


--Check if an item is already bound to your account
function FCOIS.IsItemAlreadyBound(bagId, slotIndex)
    --Only check bound set parts
    local itemType = git(bagId, slotIndex)
    local isAllowedItemType = allowedSetItemTypes[itemType]
    if not isAllowedItemType then return false end
    local itemLink = gil(bagId, slotIndex)
    if itemLink then
        --Is the item bound?
        return isilbo(itemLink)
    else
        return nil
    end
end

--Check if an item could be bound
function FCOIS.IsItemBindableAtAll(bagId, slotIndex)
    local itemLink = gil(bagId, slotIndex)
    if itemLink then
        --Is item a bindable type
        local bindType = gilbt(itemLink)
        if bindType ~= BIND_TYPE_NONE and bindType ~= BIND_TYPE_UNSET then
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
local isItemBindableAtAll = FCOIS.IsItemBindableAtAll

--Check if an item is already bound
function FCOIS.IsItemBound(bagId, slotIndex)
    local itemLink = gil(bagId, slotIndex)
    if itemLink then
        --Bound?
        return isilbo(itemLink)
    else
        return nil
    end
end
local isItemBound = FCOIS.IsItemBound

--Check if an item can be bound to your account and if it is not already bound
function FCOIS.IsItemBindable(bagId, slotIndex)
    local itemLink = gil(bagId, slotIndex)
    if itemLink then
        --Bound
        local isBound = isItemBound(bagId, slotIndex) or false
        if(isBound) then
            --Item is already bound
            return false
        else
            return isItemBindableAtAll(bagId, slotIndex) or false
        end
    else
        return nil
    end
end

--Is the item a container and is autoloot enabled in the ESO settings
function FCOIS.IsAutolootContainer(bag, slot)
    return (git(bag, slot) == ITEMTYPE_CONTAINER and GetSetting(SETTING_TYPE_LOOT, LOOT_SETTING_AUTO_LOOT)=="1")
end

function FCOIS.IsContainerCollectible(bag, slot)
    local itemLink = gil(bag, slot)
    if not itemLink then return false end
    local itemtype, specializedItemType = gilit(itemLink)
    local specializedItemtypesOfContainers = {
        [SPECIALIZED_ITEMTYPE_CONTAINER_STYLE_PAGE] = true,
        [SPECIALIZED_ITEMTYPE_COLLECTIBLE_STYLE_PAGE] = true,
        [SPECIALIZED_ITEMTYPE_CONTAINER] = true,

    }
    if not specializedItemtypesOfContainers[specializedItemType] then return false end

    local containerCollectibleId = gilccid(itemLink)
    local isValidForPlayer = iscvfplayer(containerCollectibleId)
    if isValidForPlayer then
        --local isUnlocked = IsCollectibleUnlocked(containerCollectibleId)
        return true
    end
    return false
end

--Function to check it the item is a soulgem
function FCOIS.IsSoulGem(bagId, slotIndex)
    if bagId == nil or slotIndex == nil then return nil end
    local isSoulGem = (gsgiinf(bagId, slotIndex) > 0) or false
    if not isSoulGem then
        --Special check for crown store soul gems as GetSoulGemItemInfo returns 0 for them...
        local itemType, specializedItemType = git(bagId, slotIndex)
        if itemType == ITEMTYPE_SOUL_GEM and specializedItemType == SPECIALIZED_ITEMTYPE_SOUL_GEM then isSoulGem = true end
    end
    return isSoulGem
end

--Is the item a recipe and is it known by one of your chars? Boolean expectedResult will give the
--true (known recipe) or false (unknown recipe) parameter
function FCOIS.IsRecipeKnown(bagId, slotIndex, expectedResult)
    expectedResult = expectedResult or false
    --Check if any recipe addon is used and available
    if not FCOIS.CheckIfRecipeAddonUsed() then return nil end
    --Get the recipe addon used to check for known/unknown state
    local recipeAddonUsed = FCOIS.GetRecipeAddonUsed()
    if recipeAddonUsed == nil or recipeAddonUsed == "" then return nil end
    --Get the itemLink
    local itemLink = gil(bagId, slotIndex)
    if itemLink == "" then return nil end
    -- item is a recipe
    if gilit(itemLink) ~= ITEMTYPE_RECIPE then return nil end
    local settingsBase = FCOIS.settingsVars
    local settings = settingsBase.settings
    local useAccountWideSettings = (settingsBase.defaultSettings.saveMode == 2) or false
    local autoMarkRecipesOnlyThisChar = settings.autoMarkRecipesOnlyThisChar
    --local recipeUnknownIconNr = settings.autoMarkRecipesIconNr
    --local recipeKnownIconNr = settings.autoMarkKnownRecipesIconNr
    local currentCharName = zocstrfor(SI_UNIT_NAME, GetUnitName("player"))
    local currentCharId = tos(gccharid())
    local known

    if settings.debug then debugMessage("isRecipeKnown", gil(bagId, slotIndex) .. ", expectedResult: " ..tos(expectedResult) .. ", recipeAddonUsed: " ..tos(recipeAddonUsed) .. ", autoMarkRecipesOnlyThisChar: " ..tos(autoMarkRecipesOnlyThisChar), true, FCOIS_DEBUG_DEPTH_SPAM, false) end
--d("[FCOIS]isRecipeKnown ".. gil(bagId, slotIndex) .. ", expectedResult: " ..tos(expectedResult) .. ", recipeAddonUsed: " ..tos(recipeAddonUsed) .. ", autoMarkRecipesOnlyThisChar: " ..tos(autoMarkRecipesOnlyThisChar))

    --SousChef
    if recipeAddonUsed == FCOIS_RECIPE_ADDON_SOUSCHEF then
--d(">using SousChef")
--Get recipe info from Sous Chef addon
        if SousChef and SousChef.Utility then
            local sousChefUtility = SousChef.Utility
            local sousChefSettings = SousChef.settings
            if sousChefSettings and sousChefSettings.showAltKnowledge and sousChefSettings.Cookbook then
                local resultLink = gilrril(itemLink)
                local knownByUsersTable = sousChefSettings.Cookbook[sousChefUtility.CleanString(gilna(resultLink))]
                --FCOIS._knownByUsersTable = knownByUsersTable
                if knownByUsersTable ~= nil then
                    local currentCharacterName = ""
                    if autoMarkRecipesOnlyThisChar == true then
                        --Only check if recipe is known for the currently logged in unique character ID?
                        currentCharacterName = currentCharId
                    else
                        ---TODO FEATURE Check if recipe is known for any of your characters, not only the main provisioner char from SousChef settings ?!

                        --Check if recipe is known for your main provisioning character
                        local recipeMainChar = sousChefSettings.mainChar
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
                    known = false
                end
                return known
            end
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

--d(">>checking char:  " ..tos(charToCheck) .. ", isCraftStoreMainCrafterChar: " ..tos(isCraftStoreMainCrafterChar) .. ", knownLoop: " ..tos(knownLoop))
                        --Is the expected result already the knownState of the recipe at this char? Then go on with the
                        --next char
                        if expectedResult ~= isLearnable then
                            --Is the char the crafter main char? Or wasn't any main crafter set
                            --If autoMarkRecipesOnlyThisChar == true then the table only got 1 line with the current character!
                            if autoMarkRecipesOnlyThisChar then
--d("<<onlyThisChar -> knownLoop: " ..tos(knownLoop))
                                --Return the first line's known entry
                                return knownLoop
                            else
                                --Is the main Crafter set? Then only check his/her recipe's known/unknown state
                                local goOn = true
                                if isCraftStoreMainCrafterCharSet == true then
--d(">>main crafter char is set")
                                    goOn = isCraftStoreMainCrafterChar
                                end
--d(">>>goOn: " ..tos(goOn))
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
function FCOIS.IsRecipeAutoMarkDoable(checkIfSettingToAutoMarkIsEnabled, knownRecipesIconCheck, doIconCheck)
--d("[FCOIS]isRecipeAutoMarkDoable - knownRecipesIconCheck: "..tos(knownRecipesIconCheck))
    checkIfSettingToAutoMarkIsEnabled = checkIfSettingToAutoMarkIsEnabled or false
    knownRecipesIconCheck = knownRecipesIconCheck or false
    doIconCheck = doIconCheck or false
    local settings = FCOIS.settingsVars.settings
    local retVar = false
    local iconCheck
    if doIconCheck then
        if knownRecipesIconCheck == true then
            iconCheck = settings.isIconEnabled[settings.autoMarkKnownRecipesIconNr]
        else
            iconCheck = settings.isIconEnabled[settings.autoMarkRecipesIconNr]
        end
    end
    local isRecipeAutoMarkPrerequisitesMet = (FCOIS.CheckIfRecipeAddonUsed() and FCOIS.CheckIfChosenRecipeAddonActive(settings.recipeAddonUsed)) or false
--d(">isRecipeAutoMarkPrerequisitesMet: " ..tos(isRecipeAutoMarkPrerequisitesMet))
    if doIconCheck and isRecipeAutoMarkPrerequisitesMet then
        isRecipeAutoMarkPrerequisitesMet = (isRecipeAutoMarkPrerequisitesMet and iconCheck) or false
    end
    if checkIfSettingToAutoMarkIsEnabled and knownRecipesIconCheck then
        retVar = isRecipeAutoMarkPrerequisitesMet and (settings.autoMarkRecipes or settings.autoMarkKnownRecipes)
    elseif checkIfSettingToAutoMarkIsEnabled and not knownRecipesIconCheck then
        retVar = isRecipeAutoMarkPrerequisitesMet and settings.autoMarkRecipes
    elseif not checkIfSettingToAutoMarkIsEnabled and knownRecipesIconCheck then
        retVar = isRecipeAutoMarkPrerequisitesMet and settings.autoMarkKnownRecipes
    else
        retVar = isRecipeAutoMarkPrerequisitesMet
    end
--d("<retVar: " ..tos(retVar))
    return retVar
end

--Is the item a set part?
function FCOIS.IsItemSetPartNoControl(bagId, slotIndex)
    local retVal = false
    local itemLink = gil(bagId, slotIndex)
    if itemLink ~= "" then
        -- Get the item's type
        local itemType = gilit(itemLink)
        if itemType ~= nil then
            local allowed = allowedSetItemTypes[itemType] or false
            if allowed then
                --Get the set item information
                local hasSet, _, _, _, _ = gilsetinf(itemLink, false)
                retVal = hasSet
            end
        end
    end
    return retVal
end

--Is the item a set part and got some selected traits (chosen in the addon's "automatic marking" -> "sets" settings)?
function FCOIS.IsItemSetPartWithTraitNoControl(bagId, slotIndex)
--d("FCOIS.isItemSetPartWithTraitNoControl")
    local isSetPartWithWishedTrait = false
    local isSetPartAndIsValidAndGotTrait = false
    local isSet = false
    local setPartTraitIcon
    local settings = FCOIS.settingsVars.settings
    local itemLink = gil(bagId, slotIndex)
    if itemLink and itemLink ~= "" then
--d(">Item: " .. itemLink)
        local itemType = gilit(itemLink)
        -- Get the item's type
        if itemType ~= nil then
--d(">itemType: " ..tos(itemType))
            local allowed = allowedSetItemTypes[itemType] or false
            if allowed then
--d(">allowed")
                --Get the set item information
                local hasSet = gilsetinf(itemLink)
                -- item is a set
                if hasSet == true then
                    isSet = true
--d(">has set")
                    --Check the item's trait now, according to it's item type
                    --[[
                        * gilti(*string* _itemLink_)
                        ** _Returns:_ *[ItemTraitType|#ItemTraitType]* _traitType_, *string* _traitDescription_, *integer* _traitSubtype_, *string* _traitSubtypeName_, *string* _traitSubtypeDescription_
                    ]]
                    local itemTraitType = gilti(itemLink)
                    if itemTraitType ~= nil then
--d(">itemTraitType: " ..tos(itemTraitType))
                        --Armor / Jewelry
                        if itemType == ITEMTYPE_ARMOR then
                            --Distinguish between armor and jewelry by checking the equip type
                            --[[
                                * EQUIP_TYPE_NECK
                                * EQUIP_TYPE_RING
                                * gilinf((*string* _itemLink_)
                                ** _Returns:_ *string* _icon_, *integer* _sellPrice_, *bool* _meetsUsageRequirement_, *integer* _equipType_, *integer* _itemStyle_
                            ]]
                            local _, _, _, equipType = gilinf(itemLink)
                            if equipType ~= nil then
                                if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
                                    --Jewelry
                                    if settings.autoMarkSetsCheckJewelryTrait[itemTraitType] ~= nil then
                                        isSetPartWithWishedTrait = settings.autoMarkSetsCheckJewelryTrait[itemTraitType]
                                        setPartTraitIcon = settings.autoMarkSetsCheckJewelryTraitIcon[itemTraitType]
                                        isSetPartAndIsValidAndGotTrait = true
                                    end
                                else
                                    --Armor
                                    if settings.autoMarkSetsCheckArmorTrait[itemTraitType] ~= nil then
                                        isSetPartWithWishedTrait = settings.autoMarkSetsCheckArmorTrait[itemTraitType]
                                        setPartTraitIcon = settings.autoMarkSetsCheckArmorTraitIcon[itemTraitType]
                                        isSetPartAndIsValidAndGotTrait = true
                                    end
                                end
                            end
                            --Weapon or shields
                        elseif itemType == ITEMTYPE_WEAPON then
                            if settings.autoMarkSetsCheckWeaponTrait[itemTraitType] ~= nil then
                                isSetPartWithWishedTrait = settings.autoMarkSetsCheckWeaponTrait[itemTraitType]
                                setPartTraitIcon = settings.autoMarkSetsCheckWeaponTraitIcon[itemTraitType]
                                isSetPartAndIsValidAndGotTrait = true
                            end
                        end
                    end -- if itemTraitType ~= nil then
                end -- if hasSet then
            end -- if allowed then
        end -- if itemType ~= nil then
    end -- if itemLink ~= "" then

    --If this is not a wished trait, clear the marker icon
    if not isSetPartWithWishedTrait then
        setPartTraitIcon = nil
    end

    return isSetPartWithWishedTrait, isSetPartAndIsValidAndGotTrait, setPartTraitIcon, isSet
end

--Function used to check if the item was retraited or reconstructed and thus cannot be researched anymore
-->Will remove the research marker icon at context menus then
function FCOIS.IsItemLinkReconStructedOrRetraited(itemLink)
    if itemLink == nil then return false end
    --Check if the item was reconstructed or retraited
    local itemTraitInformationNotResearchable = checkVars.itemTraitInformationNotResearchable
    local itemTraitInformation = giltinf(itemLink)
    return itemTraitInformationNotResearchable[itemTraitInformation] or false
end
local isItemLinkReconStructedOrRetraited = FCOIS.IsItemLinkReconStructedOrRetraited

--Function used in FCOIS.isItemLinkResearchable() and FCOIS.isItemResearchableNoControl()
local function isResearchableItemTypeCheck(itemType, markId)
    local retVal = false
    local allowedTab = {}
    allowedTab = checkVars.researchableItemTypes[itemType]
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
function FCOIS.IsItemLinkResearchable(itemLink, markId, doTraitCheck)
    if itemLink == nil then return false end

    local retVal = false
    local retValReconstructedOrRetraited = false
    doTraitCheck = doTraitCheck or false
    --Check if the item is virtually researchable as the settings is enabled to allow marking of non researchable items as gear/dynamic
    markId = markId or nil
    if markId ~= nil then
        local settings = FCOIS.settingsVars.settings
        retVal = settings.disableResearchCheck[markId] or false
    end
    retValReconstructedOrRetraited = isItemLinkReconStructedOrRetraited(itemLink)
    --Check the item's type (Armor, weapon, jewelry e.g. are researchable)
    if retVal == false then
        local itemType = gilit(itemLink)
        if itemType == nil then return false, retValReconstructedOrRetraited end
        retVal = isResearchableItemTypeCheck(itemType, markId)
    end
    --Check the item's trait (no trait-> No research)
    if retVal == true and doTraitCheck then
        local itemTraitType = gilti(itemLink)
        local itemTraiTypesNotAllowedForResearch = checkVars.researchTraitCheckTraitsNotAllowed
        local itemTraitTypeNotAllowedForResearch = itemTraiTypesNotAllowedForResearch[itemTraitType] or false
        if itemTraitType == nil or itemTraitTypeNotAllowedForResearch then return false, retValReconstructedOrRetraited end
    end
--d("[FCOIS.isItemLinkResearchable] retVal: " .. tos(retVal))
    return retVal, retValReconstructedOrRetraited
end
local isItemLinkResearchable = FCOIS.IsItemLinkResearchable

-- Is the item researchable?
function FCOIS.IsItemResearchableNoControl(bagId, slotIndex, markId, doTraitCheck)
    if bagId == nil or slotIndex == nil then return false, false end
    --Check if the item is virtually researchable as the settings is enabled to allow marking of non-researchable items as gear/dynamic
    markId = markId or nil
    local itemLink = gil(bagId, slotIndex)
    local retVal, retVal2 = isItemLinkResearchable(itemLink, markId, doTraitCheck)
--d("[FCOIS.isItemResearchableNoControl] retVal: " .. tos(retVal))
    return retVal, retVal2
end

-- Is the item researchable?
-- Is the item researchable?
function FCOIS.IsItemResearchable(p_rowControl, markId, doTraitCheck)
    if p_rowControl == nil then return false, false end
    local bag, slotIndex
    local retVal = false
    local retVal2 = false
    local IIfArowControlCheck = (FCOIS.IIfAclicked ~= nil) or false
--d("[FCOIS.isItemResearchable] " ..tos(p_rowControl:GetName()) .. ", markId: " ..tos(markId) .. ", IIfArowCheck: " ..tos(IIfArowControlCheck))
    --Inventory Insight from ashes support
    if IIfArowControlCheck then
        bag, slotIndex = FCOIS.IIfAclicked.bagId, FCOIS.IIfAclicked.slotIndex
    else
        bag, slotIndex = myGetItemDetails(p_rowControl)
    end
    local itemLink
    if bag == nil or slotIndex == nil then
        --Was a row in IIfA inventory frame clicked and does function FCOIS.AddMark check if the item is researchable now?
        if IIfArowControlCheck then
            --Get the itemLink of the clicked item from the IIfA rowcontrol
            itemLink = FCOIS.IIfAclicked.itemLink
        end
    else
        itemLink = gil(bag, slotIndex)
    end
    if itemLink ~= nil then
        retVal, retVal2 = isItemLinkResearchable(itemLink, markId, doTraitCheck)
    end
    return retVal, retVal2
end


-- Is the item an ornate one?
function FCOIS.IsItemOrnate(bagId, slotIndex)
    local isOrnate = false
    local itemTrait = gitrait(bagId, slotIndex)
    local allowedOrnateItemTraits = checkVars.ornateItemTraits
    isOrnate = allowedOrnateItemTraits[itemTrait] or false
--local itemLink = gil(bagId, slotIndex)
--d("[FCOIS]isItemOrnate: " .. itemLink .. " -> " .. tos(isOrnate))
    return isOrnate
end

-- Is the item an intricate one?
function FCOIS.IsItemIntricate(bagId, slotIndex)
    local isIntricate = false
    local allowedIntricateItemTraits = checkVars.intricateItemTraits
    local itemTrait = gitrait(bagId, slotIndex)
    isIntricate = allowedIntricateItemTraits[itemTrait] or false
--local itemLink = gil(bagId, slotIndex)
--d("[FCOIS]isItemIntricate: " .. itemLink .. " -> " .. tos(isIntricate))
    return isIntricate
end

--Check if the item is a "super item" (special enchantment with set bonus!)
function FCOIS.IsItemSuperitem(bagId, slotIndex)
    if bagId == nil or slotIndex == nil then return false end
    local itemLink = gil(bagId, slotIndex)
    local hasSet, _, numBonuses = gilsetinf(itemLink, false)
    if hasSet and numBonuses == 1 then
        -- Superitem
        return true
    end
    return false
end

--Are we deconstructing, improving, extracting an item, and not creating it at any craft station?
function FCOIS.IsNotCreatingCraftItem()
    local isNotCreatingCraftItemNow = false
    if ZO_CraftingUtils_IsCraftingWindowOpen() then
        --Smithing
        if not ctrlVars.SMITHING_PANEL:IsHidden() then
            if ctrlVars.SMITHING.mode == nil or ctrlVars.SMITHING.mode ~= SMITHING_MODE_CREATION then
                isNotCreatingCraftItemNow = true
            end
            --Enchanting
        elseif not ctrlVars.ENCHANTING_STATION:IsHidden() then
            if ctrlVars.ENCHANTING.enchantingMode == nil or ctrlVars.ENCHANTING.enchantingMode ~= ENCHANTING_MODE_CREATION then
                isNotCreatingCraftItemNow = true
            end
            --Alchemy
        elseif not ctrlVars.ALCHEMY_INV:IsHidden() then
            if ctrlVars.ALCHEMY.mode == nil or ctrlVars.ALCHEMY.mode ~= ZO_ALCHEMY_MODE_CREATION then
                isNotCreatingCraftItemNow = true
            end
            --Provisioning
        elseif not ctrlVars.PROVISIONER_PANEL:IsHidden() then
            --Provisioner can only create (cook/brew)
            isNotCreatingCraftItemNow = false
        end
    else
        isNotCreatingCraftItemNow = true
    end
--d("[FCOIS]isNotCreatingCraftItem - result: " .. tos(isNotCreatingCraftItem))
    return isNotCreatingCraftItemNow
end
local isNotCreatingCraftItem = FCOIS.IsNotCreatingCraftItem

--Check if the LibFilters panelId is a panel Id which allows deconstruction
function FCOIS.CheckIfFilterPanelIsDeconstructable(panelId)
    panelId = panelId or FCOIS.gFilterWhere
    if panelId == nil then return nil end
    local deconstructablePanels = FCOIS.mappingVars.panelIdToDeconstructable
    local panelIsDeconstructable = deconstructablePanels[panelId] or false
    return panelIsDeconstructable
end

function FCOIS.IsDeconstructionHandlerNeeded() --#202
    checkIfUniversalDeconstructionNPC = checkIfUniversalDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC
    return not ctrlVars.DECONSTRUCTION_BAG:IsHidden() or checkIfUniversalDeconstructionNPC()
end

--Check if the writ or non-writ item is crafted and should be marked wih the "crafted" marker icon
function FCOIS.IsWritOrNonWritItemCraftedAndIsAllowedToBeMarked()
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
    --d("<retVar: " .. tos(retVar) .. ", craftMarkerIcon: " .. tos(craftMarkerIcon))
    return retVar, craftMarkerIcon
end

function FCOIS.IsSendingMail()
    local mailSend = FCOIS.ZOControlVars.MAIL_SEND
    if mailSend and not mailSend:IsHidden() then
        return true
    elseif MAIL_MANAGER_GAMEPAD and MAIL_MANAGER_GAMEPAD:GetSend():IsAttachingItems() then
        return true
    end
    return false
end

--==============================================================================
-- Is dialog functions
--==============================================================================

--Is the research list dialog shown?
function FCOIS.IsResearchListDialogShown()
    if libFilters.IsListDialogShown then
        return libFilters.IsListDialogShown(libFilters, nil, ctrlVars.RESEARCH)
    else
        local listDialog = ZO_InventorySlot_GetItemListDialog()
        local data = listDialog and listDialog.control and listDialog.control.data
        if data == nil then return false end
        local owner = data.owner
        if owner == nil or owner.control == nil then return false end
        return owner.control == ctrlVars.RESEARCH and not listDialog.control:IsHidden()
    end
end

--Is the repair item dialog shown?
function FCOIS.IsRepairDialogShown()
    local isRepairDialogShown = false
    local repairDialog = ctrlVars.RepairItemDialog
    --Fastest detection: Use the title of the dialog! The other both methods seem to need a small delay before the dialog data/control is updated :-(
    if repairDialog ~= nil then
        isRepairDialogShown = (repairDialog.info and repairDialog.info.title and repairDialog.info.title.text and repairDialog.info.title.text == ctrlVars.RepairItemDialogTitle) or false
    else
        isRepairDialogShown = ZO_Dialogs_IsShowing(ctrlVars.RepairItemDialogName)
        if not isRepairDialogShown then
            local repairKits = ctrlVars.RepairKits
            if repairKits and repairKits.control then
                isRepairDialogShown = not repairKits.control:IsHidden()
            end
        end
    end
    return isRepairDialogShown
end

--Is the enchant item dialog shown?
function FCOIS.IsEnchantDialogShown()
    local isEnchantDialogShown = false
    local enchantDialog = ctrlVars.EnchantItemDialog
    --Fastest detection: Use the title of the dialog! The other both methods seem to need a small delay before the dialog data/control is updated :-(
    if enchantDialog ~= nil then
        isEnchantDialogShown = (enchantDialog.info and enchantDialog.info.title and enchantDialog.info.title.text and enchantDialog.info.title.text == ctrlVars.EnchantItemDialogTitle) or false
    else
        isEnchantDialogShown = ZO_Dialogs_IsShowing(ctrlVars.EnchantItemDialogName)
        if not isEnchantDialogShown then
            local enchantApply = ctrlVars.EnchantApply
            if enchantApply and enchantApply.control then
                isEnchantDialogShown = not enchantApply.control:IsHidden()
            end
        end
    end
    return isEnchantDialogShown
end


--==============================================================================
-- Dialog functions
--==============================================================================
--Function to change the button #  state and keybind of a dialog now
function FCOIS.ChangeDialogButtonState(dialog, buttonNr, stateBool)
--d("[FCOIS]changeDialogButtonState-dialog: " ..tos(dialog) .. ", button: " ..tos(buttonNr) .. ", stateBool: " ..tos(stateBool))
    if not dialog or not buttonNr then return end
    stateBool = stateBool or false
    --GetControl(ctrlVars.RepairItemDialog, "Button" .. tos(buttonNr)) --wm:GetControlByName(ctrlVars.RepairItemDialog, "Button" .. tos(buttonNr)):SetEnabled(enableResearchButton)
    -- Activate or deactivate a button...use BSTATE_NORMAL to activate and BSTATE_DISABLED to deactivate
    local buttonState = (stateBool and BSTATE_NORMAL) or BSTATE_DISABLED
    ZO_Dialogs_UpdateButtonState(dialog, 1, buttonState)
    local buttonControl = ctrlVars.RepairItemDialog:GetNamedChild("Button" .. tos(buttonNr))
    if buttonControl and buttonControl.SetKeybindEnabled then buttonControl:SetKeybindEnabled(stateBool) end
end

--==============================================================================
-- Get Item functions
--==============================================================================
function FCOIS.GetItemQuality(bagId, slotIndex)
    --get the item link
    local itemLink = gil(bagId, slotIndex)
    if itemLink == nil then return false end
    -- Gets the item quality
    local itemQuality = gilfq(itemLink)
    if not itemQuality then return false end
    return itemQuality
end

--Check which marker icons should be removed, if this marker icon gets set
function FCOIS.GetIconsToRemove(bag, slot, itemInstanceOrUniqueId, curentlyCheckedIconId, demarksSell, demarksDecon)
    if (bag == nil or slot==nil) and itemInstanceOrUniqueId == nil then return end

    isMarked = isMarked or FCOIS.IsMarked
    isMarkedByItemInstanceId = isMarkedByItemInstanceId or FCOIS.IsMarkedByItemInstanceId

    local iconsToRemove = {}
    local settings = FCOIS.settingsVars.settings
    demarksSell = demarksSell or checkIfOtherDemarksSell(curentlyCheckedIconId)
    demarksDecon = demarksDecon or checkIfOtherDemarksDeconstruction(curentlyCheckedIconId)
    if demarksSell == true then
        if settings.autoDeMarkSellOnOthers == true and (
                (bag and slot and isMarked(bag, slot, { FCOIS_CON_ICON_SELL }))
            or  (itemInstanceOrUniqueId and isMarkedByItemInstanceId(itemInstanceOrUniqueId, { FCOIS_CON_ICON_SELL }))
        ) then
            iconsToRemove[FCOIS_CON_ICON_SELL] = FCOIS_CON_ICON_SELL
        end
        if settings.autoDeMarkSellGuildStoreOnOthers == true and (
               (bag and slot and isMarked(bag, slot, { FCOIS_CON_ICON_SELL_AT_GUILDSTORE }))
            or (itemInstanceOrUniqueId and isMarkedByItemInstanceId(itemInstanceOrUniqueId, { FCOIS_CON_ICON_SELL_AT_GUILDSTORE }))
        ) then
            iconsToRemove[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = FCOIS_CON_ICON_SELL_AT_GUILDSTORE
        end
    end
    if demarksDecon == true then
        if settings.autoDeMarkDeconstructionOnOthers == true and (
                (bag and slot and isMarked(bag, slot, { FCOIS_CON_ICON_DECONSTRUCTION }))
                or (itemInstanceOrUniqueId and isMarkedByItemInstanceId(itemInstanceOrUniqueId, { FCOIS_CON_ICON_DECONSTRUCTION }))
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
--d("[FCOIS]GetActiveBagIdByFilterPanelId, filterPanelId: " ..tos(filterPanelId) .. " -> ERROR!")
        return nil
    end
    local filterPanelIdToBagId = FCOIS.mappingVars.libFiltersId2BagId
    local activeBagId = filterPanelIdToBagId[filterPanelId] or nil
--d("[FCOIS]GetActiveBagIdByFilterPanelId, filterPanelId: " ..tos(filterPanelId) .. ", bagId: " ..tos(activeBagId))
    return activeBagId
end

--Get the inventory type by help of the inventory's bagId
function FCOIS.GetActiveInventoryTypeByBagId(bagId)
    if bagId == nil then
--d("[FCOIS]GetActiveInventoryTypeByBagId, bagId: " ..tos(bagId) .. " -> ERROR!")
        return nil
    end
    local bagIdToPlayerInv = FCOIS.mappingVars.bagToPlayerInv
    local playerInvId = bagIdToPlayerInv[bagId] or nil
--d("[FCOIS]GetActiveInventoryTypeByBagId, bagId: " ..tos(bagId) .. ", playerInvId: " ..tos(playerInvId))
    return playerInvId
end

--======================================================================================================================
-- Get functions
--======================================================================================================================
--Get the current scene and scene name
--If no scene_manager is given or no scene can be determined the dummy scene FCOIS will be returned (table containing only a name)
function FCOIS.GetCurrentSceneInfo()
    if not SCENE_MANAGER then return FCOIS.dummyScene, "" end
    local currentScene = SCENE_MANAGER:GetCurrentScene()
    local currentSceneName = ""
    if not currentScene then currentScene = FCOIS.dummyScene end
    currentSceneName = currentScene.name
    return currentScene, currentSceneName
end
local getCurrentSceneInfo = FCOIS.GetCurrentSceneInfo

--Is the stable scene currently shown?
function FCOIS.IsStableSceneShown()
    local currentScene, _ = getCurrentSceneInfo()
    return (currentScene == STABLES_SCENE) or false
end

--Get the effective level of a unitTag and check if it's above or equals a specified "needed level".
--Returns boolean true if level is above or equal the parameter neededLevel
--Returns boolean false if level is below the parameter neededLevel
function FCOIS.CheckNeededLevel(unitTag, neededLevel)
    if unitTag == nil or neededLevel == nil or type(neededLevel) ~= "number" then return false end
    local gotNeededLevel = false
    local charLevel = getUnitLvl(unitTag)
    if not charLevel then return false end
    gotNeededLevel = (charLevel >= neededLevel) or false
    return gotNeededLevel
end

--Get the type of the vendor used currently.
-- FCOIS_CON_VENDOR_TYPE_NORMAL_NPC = NPC vendor
-- FCOIS_CON_VENDOR_TYPE_PORTABLE   = The mobile vendor you can buy in the crown store, called Nuzhimeh
function FCOIS.GetCurrentVendorType(vendorPanelIsShown)
    vendorPanelIsShown = vendorPanelIsShown or false
    isVendorPanelShown = isVendorPanelShown or FCOIS.IsVendorPanelShown
    local isVendorPanelShownNow = isVendorPanelShown(nil, vendorPanelIsShown)
    if not isVendorPanelShownNow then
--d("[FCOIS]GetCurrentVendorType: No vendor panel shown. >Abort!")
        return ""
    end
    local retVar = ""
    local vendorButtonCount = 2
    --Are we able to buy something in this store?
    if not isStoreEmptyFunc() then vendorButtonCount = vendorButtonCount +1 end
    --Are we able to repair something in this store?
    if canStoreRepairFunc() then vendorButtonCount = vendorButtonCount +1 end
    --Are there 4 buttons at the vendor menu bar?
    if vendorButtonCount == 4 then
        retVar = FCOIS_CON_VENDOR_TYPE_NORMAL_NPC
    --Are there only 3 buttons at the vendor menu bar?
    elseif vendorButtonCount == 3 then
        retVar = FCOIS_CON_VENDOR_TYPE_PORTABLE
    --Are there only 2 buttons at the vendor menu bar?
    elseif vendorButtonCount == 2 then
        retVar = FCOIS_CON_VENDOR_TYPE_PORTABLE
    end
    return retVar, vendorButtonCount
end

--Function to get the filter panel for the undo methods (SHIFT+right mouse on items)
function FCOIS.GetUndoFilterPanel(panelId)
    local settings = FCOIS.settingsVars.settings
    local undoFilterPanelSettings = settings.contextMenuClearMarkesByShiftKey and settings.useDifferentUndoFilterPanels
    if undoFilterPanelSettings then
        local actualFilterPanelId = panelId or FCOIS.gFilterWhere
        return actualFilterPanelId
    end
    --Fallback filterPanelId if settings for UNDO saved for different filterPanelIds is disabled or SHIFT+right mouse = undo/redo disabled
    return LF_INVENTORY
end

--Function to get the armor type of an equipped item
function FCOIS.GetArmorType(equipmentSlotControl)
    if equipmentSlotControl == nil then return false end
    local bagId
    local slotIndex
    bagId, slotIndex = myGetItemDetails(equipmentSlotControl)
    local armorType = GetItemArmorType(bagId, slotIndex)
    --d("[GetArmorType] bag: " .. bagId .. ", slot: " .. slotIndex .. " --- armorType: " .. tos(armorType))
    return armorType
end


--======================================================================================================================
-- Set functions
--======================================================================================================================
--Set an item as junk + remove all marker icons on it / remove item from junk -> via additional inventory "flag" context menu
--#291 Mass moving to junk/unmoving from junk will get you server kicked for message spam
local moveToJunkQueue = {}
local moveFromJunkQueue = {}
local moveToJunkQueueActive = false
local moveFromJunkQueueActive = false
--todo DEBUG Remove comment for debugging
--[[
FCOIS.JunkQueue = {
    _moveToJunkQueue = moveToJunkQueue,
    _moveFromJunkQueue = moveFromJunkQueue,
    moveToJunkQueueActive = moveToJunkQueueActive,
    moveFromJunkQueueActive = moveFromJunkQueueActive,
}
]]

function FCOIS.SetItemIsJunkNow(bagId, slotIndex, isJunk, isCompanionItem)
    if bagId == nil or slotIndex == nil or isJunk == nil then return false end
    if isCompanionItem == nil then
        isCompanionItem = checkIfCompanionItem(bagId, slotIndex)
    end
    --Mark as junk?
    if not isJunk or (isJunk and not IsItemJunk(bagId, slotIndex, isCompanionItem)) then
        SetItemIsJunk(bagId, slotIndex, isJunk, isCompanionItem)
        if isJunk == true then
            --Are there any marker icons on the item? Remove them if moved to junk
            isMarked = isMarked or FCOIS.IsMarked
            FCOISMarkItem = FCOISMarkItem or FCOIS.MarkItem

            local anyMarkerIconSetOnItemToJunk, markerIconsOnItemToJunk = isMarked(bagId, slotIndex, -1)
            if anyMarkerIconSetOnItemToJunk == true then
                --Remove all marker icons, except "Sell"
                for iconIdWhichWasSetBeforeAlready, isIconMarked in pairs(markerIconsOnItemToJunk) do
                    if iconIdWhichWasSetBeforeAlready ~= FCOIS_CON_ICON_SELL and isIconMarked == true then
                        FCOISMarkItem(bagId, slotIndex, iconIdWhichWasSetBeforeAlready, false, false) -- No inventory update needed as the item will be moved to the junk tab now!
                    end
                end
            end
        end
    end
    return true
end
local setItemIsJunkNow = FCOIS.SetItemIsJunkNow

local function isAnyJunkQueueActive()
    return moveToJunkQueueActive or moveFromJunkQueueActive
end

local function outputJunkQueueActiveInfo(isJunk)
    if isJunk == "both" then
        if isAnyJunkQueueActive() then
            local itemsLeftToJunk = #moveToJunkQueue
            local itemsLeftFromJunk = #moveFromJunkQueue
            local itemsLeftToProcess = (itemsLeftToJunk + itemsLeftFromJunk) or 0
            if itemsLeftToProcess > 0 then
                df("[FCOIS]The \"Move to\" or \"Move from\" Junk features are currently active - Items left: %q - Please try again later", tos(itemsLeftToProcess))
                return true
            else
                moveToJunkQueueActive = false
                moveFromJunkQueueActive = false
            end
        end
    else
        if isJunk == true then
            if moveToJunkQueueActive then
                local itemsLeftToJunk = #moveToJunkQueue
                if itemsLeftToJunk > 0 then
                    df("[FCOIS]The \"Move to\" Junk features are currently active - Items left: %q - Please try again later", tos(itemsLeftToJunk))
                    return true
                end
            end
        else
            if moveFromJunkQueueActive then
                local itemsLeftFromJunk = #moveFromJunkQueue
                if itemsLeftFromJunk > 0 then
                    df("[FCOIS]The \"Move from\" Junk features are currently active - Items left: %q - Please try again later", tos(itemsLeftFromJunk))
                    return true
                end
            end
        end
    end
    return false
end

local function canItemBeMarkedAsJunkByPackageData(data, isJunk)
    if isJunk == true then
        local goOn = true
        local bagId, slotIndex = data.bagId, data.slotIndex
        local isCompanionItem = checkIfCompanionItem(bagId, slotIndex)
        if isCompanionItem == true then
--d(">isCompanionItem")
            goOn = false

            --2024-06-06 Add support for FCOCompanion's companion junk?
            if FCOCO then
                local fcoCompanionSavedVars
                if FCOCO.GetCompanionJunkSavedVars then
                    fcoCompanionSavedVars = FCOCO.GetCompanionJunkSavedVars()
                else
                    fcoCompanionSavedVars = FCOCO.settingsVars.settingsPerToon
                end
                if fcoCompanionSavedVars and fcoCompanionSavedVars.enableCompanionItemJunk == true then
--d(">>FCOCO companion junk is enabled!")
                    goOn = true
                end
            end
        end
--d(">>goOn? " ..tos(goOn) .. " " ..GetItemLink(bagId, slotIndex))
        if goOn == true then
            return CanItemBeMarkedAsJunk(bagId, slotIndex, isCompanionItem)
        else
            return false
        end
    else
        return true
    end
end

--Called from FCOIS.ProcessJunkQueue -> processJunkQueueItems
local function setItemAsJunkOrRemoveFromJunkByPackageData(data, isJunk)
    if isJunk == true then
        moveToJunkQueueActive = true
    else
        moveFromJunkQueueActive = true
    end
    return setItemIsJunkNow(data.bagId, data.slotIndex, isJunk, nil)
end

--Calling this function will remove table indices and thus make indices of 2nd package not work anymore!
--[[
local function junkQueueCallbackAfterEachEntry(data, wasSuccessfull, isJunk)
--d("[FCOIS]CallbackAfterEachEntry - wasSuccessfull: " ..tos(wasSuccessfull) .. ", isJunk: " ..tos(isJunk))
    if wasSuccessfull == true then
        if isJunk == true then
            local posOfData = data.indexInOrigTable or ZO_IndexOfElementInNumericallyIndexedTable(moveToJunkQueue, data)
--d(">posOfData: " ..tos(posOfData))
            if posOfData ~= nil and moveToJunkQueue[posOfData] ~= nil then
                table.remove(moveToJunkQueue, posOfData)
--d("<removed from moveToJunkQueue")
            end
        else
            local posOfData = data.indexInOrigTable or ZO_IndexOfElementInNumericallyIndexedTable(moveFromJunkQueue, data)
--d("<posOfData: " ..tos(posOfData))
            if posOfData ~= nil and moveFromJunkQueue[posOfData] ~= nil then
                table.remove(moveFromJunkQueue, posOfData)
--d("<removed from moveFromJunkQueue")
            end
        end
    end
end
]]


local function prcocessJunkQueueItems(queueTab, startIndex, callbackFunc, callbackAfterEachEntry, delay, isJunk)
    if queueTab == nil or type(callbackFunc) ~= "function" or type(isJunk) ~= "boolean" then return end
    startIndex = startIndex or 1
    delay = delay or delayToMarkAsJunkInBetweenPackages

--d("[FCOIS]prcocessJunkQueueItems - queueTab: " ..tos(queueTab) .. ", startIndex: " ..tos(startIndex) .. ", isJunk: " ..tos(isJunk))


    local function finalCallbackFunc(l_retVar, l_retCount, l_isJunk)
--d("[FCOIS]finalCallbackFunc - l_retVar: " ..tos(l_retVar) .. ", l_retCount: " .. tos(l_retCount))
        if l_retVar == true then
            local locVarJunkedItemCount = ""
            if l_isJunk == true then
                locVarJunkedItemCount = FCOIS.GetLocText("fcois_junked_item_count", false)
            else
                locVarJunkedItemCount = FCOIS.GetLocText("fcois_unjunked_item_count", false)
            end
            d(strformat(preChatTextGreen .. locVarJunkedItemCount, tos(l_retCount)))
        end
--d("<CLEARING TABLES!")
        if l_isJunk == true then
            moveToJunkQueueActive = false
            moveToJunkQueue = {}
        else
            moveFromJunkQueueActive = false
            moveFromJunkQueue = {}
        end
    end

    local packagesCountToProcess = processPackages(queueTab, itemsToMarkAsJunkMaxPerPackage, packagesToMarkAsJunkMax,
            function(data) return canItemBeMarkedAsJunkByPackageData(data, isJunk) end,
            function(data) return callbackFunc(data, isJunk) end,
            (callbackAfterEachEntry ~= nil and function(data, wasSuccessfull) return callbackAfterEachEntry(data, wasSuccessfull, isJunk) end) or nil,
            delay,
            function(retVar, count) finalCallbackFunc(retVar, count, isJunk) end
    ) --max 50 packages à 10 items = 500 items (guild bank size)
end

local processJunkQueue
function FCOIS.ProcessJunkQueue(isJunk, delay, skipOutput)
    if isJunk == nil then return end
    if skipOutput == nil then skipOutput = false end
    processJunkQueue = processJunkQueue or FCOIS.ProcessJunkQueue

--d("[FCOIS]ProcessJunkQueue - isJunk: " ..tos(isJunk) .. ", delay: " ..tos(delay) .. ", skipOutput: " ..tos(skipOutput))

    if not skipOutput and outputJunkQueueActiveInfo(isJunk) then
        return
    end
    delay = delay or delayToMarkAsJunkInBetweenPackages

    if isJunk == "both" then
        --Both queues -- First move to Junk, then back
        processJunkQueue(true, delay, true)
        processJunkQueue(false, delay, true)

    else
        --Only 1 queue
        if isJunk == true then
            prcocessJunkQueueItems(moveToJunkQueue, 1, setItemAsJunkOrRemoveFromJunkByPackageData, nil, delay, true)
        else
            prcocessJunkQueueItems(moveFromJunkQueue, 1, setItemAsJunkOrRemoveFromJunkByPackageData, nil, delay, false)
        end
    end
end
processJunkQueue = FCOIS.ProcessJunkQueue

local function nonDuplicateAddToQueue(bagId, slotIndex, isJunk)
    local entryToAdd = { bagId = bagId, slotIndex = slotIndex }
    local tableToAdd = (isJunk == true and moveToJunkQueue) or moveFromJunkQueue
--d("[FCOIS]nonDuplicateAddToQueue - isJunk: " ..tos(isJunk) .. " " .. GetItemLink(bagId, slotIndex))

    --Add to junk/unjunk queue, if not already in there
    if ZO_IsElementInNumericallyIndexedTable(tableToAdd, entryToAdd) then
--d("<already in table!")
        return false
    end
    tins(tableToAdd, entryToAdd)
--d(">Added to table")
    return true
end

--#291 Add items to the junk/unjunk queues and then process the queues with a delay of 150ms in between (after each entry)
-->From FCOIS add. Inv. "flag" context menus
--> From Keybind it is using FCOIS.JunkMarkedItems(markerIconsMarkedOnItems, bagId) running packages of 25 items each with delay in between
function FCOIS.SetItemIsJunk(bagId, slotIndex, isJunk)
    if bagId == nil or slotIndex == nil then return false end
    isJunk = isJunk or false

    --Also add to the queues while they are currently processed? Yes, should be fine. All that could happen is moving items to junk and removing it from junk again directly
    return nonDuplicateAddToQueue(bagId, slotIndex, isJunk)
end


--Set the anti-research check for a dynamic icon
function FCOIS.SetDynamicIconAntiResearchCheck(iconNr, value)
    value = value or false
    --d("FCOIS]setDynamicIconAntiResearchCheck - iconNr: " .. tos(iconNr) .. ", value: " .. tos(value))
    if iconNr == nil then return false end
    local isIconDynamic = FCOIS.mappingVars.iconIsDynamic
    if isIconDynamic[iconNr] then
        FCOIS.settingsVars.settings.disableResearchCheck[iconNr] = value
    end
end

--Rebuild the allowed craft skills from the settings
function FCOIS.RebuildAllowedCraftSkillsForCraftedMarking(craftType)
    local settings = FCOIS.settingsVars.settings
    if craftType == nil then
        --reset the table to keep only the crafting_type_invalid
        FCOIS.checkVars.craftSkillsForCraftedMarking = {
            [CRAFTING_TYPE_INVALID] 		= false,
        }
        --Then rebuild the other crafting_types from the settings and add them to the table
        for craftTypeLoop, value in ipairs(settings.allowedCraftSkillsForCraftedMarking) do
            if craftTypeLoop ~= CRAFTING_TYPE_INVALID then
                FCOIS.checkVars.craftSkillsForCraftedMarking[craftTypeLoop] = value
            end
        end
    else
        --Only set the value for the wished craftType
        FCOIS.checkVars.craftSkillsForCraftedMarking[craftType] = settings.allowedCraftSkillsForCraftedMarking[craftType]
    end
end


--======================================================================================================================
-- Check functions
--======================================================================================================================

--Check if the item is a special item like the Maelstrom weapon or shield, or The Master's weapon
--> Called in file FCOIS_Hooks.lua, function FCOItemSaver_AddSlotAction
--  upon right clicking an item to show the context menu for "Enchant"
--  and at the automatic set item marking
function FCOIS.CheckIfIsSpecialItem(p_bagId, p_slotIndex)
    if p_bagId == nil or  p_slotIndex == nil then return nil end
    local specialItems = FCOIS.specialItems
    local itemId = giid(p_bagId, p_slotIndex)
    if itemId == nil then return nil end
    if specialItems[itemId] then
        return true
    end
    return false
end

--Check if a research scroll is usable or if the time left for research is less
function FCOIS.CheckIfResearchScrollWouldBeWasted(bag, slotId)
    if bag == nil or slotId == nil or DetailedResearchScrolls == nil or DetailedResearchScrolls.GetWarningLine == nil then return nil end
    local itemLink = gil(bag, slotId)
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
function FCOIS.CheckIfCraftedItemShouldBeMarked(craftSkill, overwrite)
--d("FCOIS.checkIfCraftedItemShouldBeMarked - craftSkill: " .. tos(craftSkill) .. ", overwrite: " .. tos(overwrite))
    --Mark new crafted item with the "crafted" icon?
    overwrite = overwrite or false
    --Overwritten to set "Item is currently crafted" to true?
    if overwrite then return true end
    FCOIS.preventerVars.newItemCrafted = overwrite or false

    --Are we creating an item, is the setting for automark enabled and is the current crafting station allowed to mark the crafted items (set in the settings)?
    local allowedCraftSkills = checkVars.craftSkillsForCraftedMarking
    local allowedCraftingSkill = allowedCraftSkills[craftSkill] or false
--d(">allowedCraftingSkill: " .. tos(allowedCraftingSkill))
    if not allowedCraftingSkill then return false end

    --Are we deconstructing, improving, extracting an item, and not creating it?
    local notCreating = isNotCreatingCraftItem()
    if notCreating then return false end

    --Writ marking of items takes place in another function from library libLazyCrafting -> See file src/FCOIS_OtherAddons.lua, function FCOIS.checkIfWritItemShouldBeMarked
    --LibLazyCrafting:IsPerformingCraftProcess() --> returns boolean, type of crafting, addon that requested the craft
    local writCreatedItem, _, _ = FCOIS.CheckLazyWritCreatorCraftedItem()
    if writCreatedItem then return false end

    local craftingCreatePanel = FCOIS.craftingCreatePanelControlsOrFunction[craftSkill]
    local craftingCreatePanelResult = false
    if craftingCreatePanel == nil then return false end
    if type(craftingCreatePanel) == "function" then
        --Function
        craftingCreatePanelResult = craftingCreatePanel()
        --d(">function: " ..tos(craftingCreatePanelResult))
    elseif type(craftingCreatePanel) == "boolean" then
        --Function result value
        craftingCreatePanelResult = craftingCreatePanel
        --d(">boolean: " ..tos(craftingCreatePanelResult))
    else
        --Control
        if craftingCreatePanel.IsHidden then
            craftingCreatePanelResult = not craftingCreatePanel:IsHidden()
            --d(">control not hidden: " .. tos(craftingCreatePanelResult))
        end
    end

    --Are we creating an item manually (Crafting stations "Create" panel is open?
    local creatingItem = craftingCreatePanelResult or false
    --d(">>creatingItem: " .. tos(creatingItem) .. ", craftSkill: " .. tos(craftSkill) .. ", allowedCraftingSkill: " ..tos(allowedCraftingSkill))
    if creatingItem and allowedCraftingSkill then
        --Set the variable to know if an item is getting into our bag after crafting complete
        FCOIS.preventerVars.newItemCrafted = true
    end
end

--Improvement--
function FCOIS.ResetImprovementVarsForReMark(bagId, slotIndex)
--d("[FCOIS]ResetImprovementVarsForReMark - bagId: " ..tos(bagId) ..", slotIndex: " ..tos(slotIndex))

    --Reset the remembered improvement vars for the bagId and slotIndex
    if FCOIS.improvementVars[bagId] then
        if FCOIS.improvementVars[bagId][slotIndex] then
            FCOIS.improvementVars[bagId][slotIndex] = nil
        end
        if NonContiguousCount(FCOIS.improvementVars[bagId]) == 0 then
            FCOIS.improvementVars[bagId] = nil
        end
    end
end
local resetImprovementVarsForReMark = FCOIS.ResetImprovementVarsForReMark

function FCOIS.CheckIfIsImprovableCraftSkill(craftSkill)
    return mappingVars.isImprovementCraftSkill[craftSkill] or false
end


--Check if item get's improved and if the marker icons from before improvement should be remembered
--Start function to remmeber the marker icons before improvement
function FCOIS.CheckIfImprovedItemShouldBeReMarked_BeforeImprovement()
--d("[FCOIS]CheckIfImprovedItemShouldBeReMarked_BeforeImprovement - reApply: " ..tos(FCOIS.settingsVars.settings.reApplyIconsAfterImprovement))
    if not FCOIS.settingsVars.settings.reApplyIconsAfterImprovement then return end
    --Are we at smithing improvement
    local improvementSlot = ctrlVars.IMPROVEMENT_SLOT
    if ctrlVars.IMPROVEMENT_INV:IsHidden() or improvementSlot == nil then
        return false
    end
    --Clear the remembered improvement marker icons
    local bagId, slotIndex = improvementSlot.bagId, improvementSlot.slotIndex
--d(">current item to improve: " .. gil(bagId, slotIndex))
    resetImprovementVarsForReMark(bagId, slotIndex)

    --Check if the item is marked with several icons
    isMarked = isMarked or FCOIS.IsMarked
    local isMarkedIcon, markedIcons = isMarked(bagId, slotIndex, -1)
    if isMarkedIcon == true then
--d(">>item was marked before improvement")
        --Remember the bagId and slotIndex of the slotted item that will be improved
        FCOIS.improvementVars[bagId] = FCOIS.improvementVars[bagId] or {}
        FCOIS.improvementVars[bagId][slotIndex] = markedIcons
    end
end

--Check if item get's improved and if the marker icons from before improvement should be remembered
--End function to re-mark the marker icons after improvement
function FCOIS.CheckIfImprovedItemShouldBeReMarked_AfterImprovement()
--d("[FCOIS]CheckIfImprovedItemShouldBeReMarked_AfterImprovement")
    if not FCOIS.settingsVars.settings.reApplyIconsAfterImprovement then return end
    --Only at a shown smithing improvement table
    if ctrlVars.IMPROVEMENT_INV:IsHidden() then return false end


    local uniqueUpdaterName = gAddonName .. "_AutoReAddMarkerAfterImprove"
    local function callDelayedReAddMarkerIconsAfterImproveNow()
        em:UnregisterForUpdate(uniqueUpdaterName)

        --Check the iprovement variables of the last improved items
        local iconsRemarked = 0
        for bagId, slotIndices in pairs(FCOIS.improvementVars) do
            if slotIndices == nil or NonContiguousCount(slotIndices) == 0 then
                --Reset the improvement remember variables for the ones which do not need to be marked/are buggy
                FCOIS.improvementVars[bagId] = nil
            else
                for slotIndex, markedIcons in pairs(slotIndices) do
                    --For each marked icon of the currently improved item:
                    --Set the icons/markers of the previous item again (-> copy marker icons from before improvement to the improved item)
                    for iconId, iconIsMarked in pairs(markedIcons) do
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
        --d(">icon: " ..tos(iconId) .. ", doRemarkThisMarkerIcon: " ..tos(doRemarkThisMarkerIcon))
                            if doRemarkThisMarkerIcon == true then
                                --Inventory update will be automatcally done after improvement of any item -> At the end via "updateCraftingInventory"
                                FCOIS.MarkItem(bagId, slotIndex, iconId, true, false)
                                iconsRemarked = iconsRemarked + 1
                            end
                        end
                    end
                    --Reset the improvement remember variables for the ones which were marked/were buggy (no marked icons table given)
                    FCOIS.improvementVars[bagId][slotIndex] = nil
                end
                if NonContiguousCount(slotIndices) == 0 then
                    FCOIS.improvementVars[bagId] = nil
                end
            end
        end
        --Refresh the crafting inventory now
        if iconsRemarked > 0 then
            if ctrlVars.IMPROVEMENT_INV:IsHidden() then return false end
            --d(">>reMarked icons: " ..tos(iconsRemarked))
            updateCraftingInventory = updateCraftingInventory or FCOIS.UpdateCraftingInventory
            updateCraftingInventory()
        end
    end --local function callDelayedNow()

    --Delay the call here in order to re-mark the item after the quality has changed and the item's itemLink and data
    --was rebuild so that the marker icons will apply to the correct itemInstance or uniqueId.
    --Call a function once after 2 seconds. If another register happens in the same time because another item was improved
    --during the 2 seconds wait time, the timer will reset and restart.
    em:UnregisterForUpdate(uniqueUpdaterName)
    em:RegisterForUpdate(uniqueUpdaterName, 2000, callDelayedReAddMarkerIconsAfterImproveNow)
end

--Enchanting of items in your inventory
function FCOIS.ResetEnchantingInventoryVarsForReMark(bagId, slotIndex)
    if FCOIS.enchantingVars.lastMarkerIcons[bagId] and FCOIS.enchantingVars.lastMarkerIcons[bagId][slotIndex] then
        FCOIS.enchantingVars.lastMarkerIcons[bagId][slotIndex] = nil
    end
end
local resetEnchantingInventoryVarsForReMark = FCOIS.ResetEnchantingInventoryVarsForReMark

--Check if item get's improved and if the marker icons from before improvement should be remembered
--Start function to remmeber the marker icons before improvement
function FCOIS.CheckIfEnchantingItemShouldBeReMarked_BeforeEnchanting(bagId, slotIndex)
    FCOIS.preventerVars.enchantItemActive = false
    --Clear the remembered enchanting marker icons
    resetEnchantingInventoryVarsForReMark(bagId, slotIndex)
    --Remember the current marker icons if setting is enabled to re-apply old marker icons on enchanting
    if not FCOIS.settingsVars.settings.reApplyIconsAfterEnchanting then return end

    isMarked = isMarked or FCOIS.IsMarked
    local isMarkedIcon, markerIcons = isMarked(bagId, slotIndex, -1, nil)
    if not isMarkedIcon then return end
--d(">>marked with icons!")
    FCOIS.enchantingVars.lastMarkerIcons[bagId] = FCOIS.enchantingVars.lastMarkerIcons[bagId] or {}
    FCOIS.enchantingVars.lastMarkerIcons[bagId][slotIndex] = markerIcons
end

--Check if item get's improved and if the marker icons from before improvement should be remembered
--End function to re-mark the marker icons after improvement
function FCOIS.CheckIfEnchantingInventoryItemShouldBeReMarked_AfterEnchanting()
    if not FCOIS.settingsVars.settings.reApplyIconsAfterEnchanting or not FCOIS.preventerVars.enchantItemActive then return end
    FCOIS.preventerVars.enchantItemActive = false

    local applyEnchant = ctrlVars.ENCHANTING_APPLY_ENCHANT
    local bagId, slotIndex = applyEnchant.currentBag, applyEnchant.currentIndex
    if not bagId or not slotIndex then return end
--d(">item: " .. gil(bagId, slotIndex))
    local enchantingVarsLastMarkerIcons = FCOIS.enchantingVars.lastMarkerIcons[bagId]
    local oldMarkerIcons = enchantingVarsLastMarkerIcons[slotIndex]
    if not oldMarkerIcons then return end
    local newMarkerIcons = {}
    for iconId, isMarkedIcon in pairs(oldMarkerIcons) do
        if isMarkedIcon == true then
            tins(newMarkerIcons, iconId)
        end
    end
    if #newMarkerIcons == 0 then return end
    --Re-Mark now and clear enchanted bagId and slotIndex slightly delayed
    zocl(function()
--d(">>re-marking now: " ..gil(bagId, slotIndex))
        FCOIS.MarkItem(bagId, slotIndex, newMarkerIcons, true, true)
        FCOIS.enchantingVars.lastMarkerIcons[bagId][slotIndex] = nil
        FCOIS.preventerVars.enchantItemActive = false
        --Reset the improvement remember variables again
        resetEnchantingInventoryVarsForReMark(bagId, slotIndex)
    end, 200)
end

--======================================================================================================================
-- Is shown functions
--======================================================================================================================
--Is the inventory control shown
function FCOIS.IsInventoryShown()
    if libFilters.IsInventoryShown then
        return libFilters:IsInventoryShown()
    end
    return not ctrlVars.INV:IsHidden()
end

--Is the companion inventory control shown
function FCOIS.IsCompanionInventoryShown()
    if libFilters.IsCompanionInventoryShown then
        return libFilters:IsCompanionInventoryShown()
    end
    return not ctrlVars.COMPANION_INV_CONTROL:IsHidden()
end
isCompanionInventoryShown = FCOIS.IsCompanionInventoryShown

--Is the character control shown
function FCOIS.IsCharacterShown()
    if libFilters.IsCharacterShown then
        return libFilters:IsCharacterShown()
    end
    return not ctrlVars.CHARACTER:IsHidden()
end
local isCharacterShown = FCOIS.IsCharacterShown

--Is the companion character control shown
function FCOIS.IsCompanionCharacterShown()
    local isCompanionCharShown = false
    if libFilters.IsCompanionCharacterShown then
        isCompanionCharShown = libFilters:IsCompanionCharacterShown()
    end
    if not isCompanionCharShown then
        return not ctrlVars.COMPANION_CHARACTER:IsHidden()
    end
    return isCompanionCharShown
end
local isCompanionCharacterShown = FCOIS.IsCompanionCharacterShown


--Is the retrait station shown?
function FCOIS.IsRetraitStationShown()
    if libFilters.IsRetraitStationShown then
        return libFilters:IsRetraitStationShown()
    end
    return ZO_RETRAIT_STATION_MANAGER:IsRetraitSceneShowing()
end

--Check if the Enchanting panel is shown
function FCOIS.IsEnchantingPanelShown(enchantingMode)
    --d("[FCOIS]IsEnchantingPanelShown - enchantingMode: " ..tos(enchantingMode))
    if libFilters.IsEnchantingShown then
        return libFilters:IsEnchantingShown(enchantingMode)
    end
    if enchantingMode == ENCHANTING_MODE_NONE or (enchantingMode ~= ENCHANTING_MODE_CREATION and enchantingMode ~= ENCHANTING_MODE_EXTRACTION and enchantingMode ~= ENCHANTING_MODE_RECIPES) then return false end
    local retVar = false
    if ctrlVars.ENCHANTING_STATION ~= nil and not ctrlVars.ENCHANTING_STATION:IsHidden() then
        if ctrlVars.ENCHANTING.GetEnchantingMode ~= nil then
            retVar = ctrlVars.ENCHANTING:GetEnchantingMode() == enchantingMode
        end
    end
    return retVar
end

--Check if the Enchanting glyph creation panel is shown
function FCOIS.IsEnchantingPanelCreationShown()
    --d("[FCOIS]IsEnchantingPanelShown")
    if libFilters.IsEnchantingShown then
        return libFilters:IsEnchantingShown(ENCHANTING_MODE_CREATION)
    end
    local retVar = false
    if ctrlVars.ENCHANTING_STATION ~= nil and not ctrlVars.ENCHANTING_STATION:IsHidden() then
        if ctrlVars.ENCHANTING.GetEnchantingMode ~= nil then
            --d(">2 EnchMode: " .. tos(ctrlVars.ENCHANTING:GetEnchantingMode()))
            retVar =  (ctrlVars.ENCHANTING:GetEnchantingMode() == ENCHANTING_MODE_CREATION)
        end
    end
    --d("<result: " .. tos(retVar))
    return retVar
end

--Check if the Alchemy creation panel is shown
function FCOIS.IsAlchemyPanelCreationShown()
    --d("[FCOIS]IsAlchemyPanelCreationShown")
    if libFilters.IsAlchemyShown then
        return libFilters:IsAlchemyShown(ZO_ALCHEMY_MODE_CREATION)
    end
    local retVar = false
    if ctrlVars.ALCHEMY_INV ~= nil and not ctrlVars.ALCHEMY_INV:IsHidden() then
        if ctrlVars.ALCHEMY.mode ~= nil then
            --d(">2 AlchemyMode: " .. tos(ctrlVars.ALCHEMY.mode))
            retVar =  (ctrlVars.ALCHEMY.mode == ZO_ALCHEMY_MODE_CREATION)
        end
    end
    --d("<result: " .. tos(retVar))
    return retVar
end

--Check if any of the vendor panels (buy, sell, buyback, repair) are shown
function FCOIS.IsVendorPanelShown(vendorPanelId, overwrite)
    overwrite = overwrite or false
    isVendorPanelShown = isVendorPanelShown or FCOIS.IsVendorPanelShown
--d("FCOIS.IsVendorPanelShown, vendorPanelId: " .. tos(vendorPanelId) .. ", overwrite: " .. tos(overwrite))
    if overwrite then return true end
    --Check the scene name if it is the "vendor" scene
    local currentSceneName = SCENE_MANAGER.currentScene.name
    if currentSceneName == nil or currentSceneName ~= ctrlVars.vendorSceneName then
--d("<1, sceneName: " ..tos(currentSceneName))
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
--d("<retVar: " ..tos(retVar))
    return retVar
end
isVendorPanelShown = FCOIS.IsVendorPanelShown


-- =====================================================================================================================
--  Other functions
-- =====================================================================================================================
--Show/Hide the player progress bar
function FCOIS.ShowPlayerProgressBar(doShow)
    --d("[FCOIS] ShowPlayerProgressBar - doShow: " .. tos(doShow))
    if not isCharacterShown() then return false end
    local playerProgressBar = ctrlVars.PLAYER_PROGRESS_BAR
    if playerProgressBar ~= nil then playerProgressBar:SetHidden(not doShow) end
end

--Show/Hide the companion progress bar
function FCOIS.ShowCompanionProgressBar(doShow)
    --d("[FCOIS] ShowCompanionProgressBar - doShow: " .. tos(doShow))
    if not isCompanionCharacterShown() then return false end
    local companionProgressBar = ctrlVars.COMPANION_PROGRESS_BAR
    if companionProgressBar ~= nil then companionProgressBar:SetHidden(not doShow) end
end


-- =====================================================================================================================
--  House functions
-- =====================================================================================================================
local function getFirstOwnedHouse()
    local houseId
    --[[
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
            -- SI_COLLECTIBLEUNLOCKSTATE0: Locked
            -- SI_COLLECTIBLEUNLOCKSTATE2: Unlocked
            local compareTextForUnlocked = GetString(SI_COLLECTIBLEUNLOCKSTATE2)
            if houseListFirstEntryData.name == compareTextForUnlocked then
                --There is at least one unlocked house!
                --Get the first entry of the unlocked houses now.
                local firstUnlockedHouseRow = housesListInCollections.children[1]
                if firstUnlockedHouseRow ~= nil then
                    local firstUnlockedHouseData = firstUnlockedHouseRow.data
                    if firstUnlockedHouseData ~= nil then
                        --Get the reference ID of the house for the teleport
                        houseId = firstUnlockedHouseData:GetReferenceId() or 0
                    end
                end
            end
        end
    end
    ]]
    houseId = GetHousingPrimaryHouse()
    if houseId == nil or houseId <= 0 then
        --local hasPrimaryResidence = false
        for collectibleId, collectibleData in pairs(ZO_COLLECTIBLE_DATA_MANAGER.collectibleIdToDataMap) do
            if collectibleData.categoryType == COLLECTIBLE_CATEGORY_TYPE_HOUSE then
                if collectibleData:IsUnlocked() then
                    return collectibleData.referenceId --> HouseId
                end
                --if collectibleData:IsPrimaryResidence() then
                --end
            end
        end
    end
    return houseId
end


--Is the player owning a house?
function FCOIS.CheckIfOwningHouse()
    --Houses at map list was not build or no owned/unlocked house found, so check if a primary house is set
    local houseId = getFirstOwnedHouse()
    if houseId == nil or houseId <= 0 then
        --List of all houses on the map, owned and not owned ones
        --> The list will only be there if one has opened the map and clicked the "houses" tab at least once!!!
        local housesOnMap = WORLD_MAP_HOUSES_DATA:GetHouseList()
        if housesOnMap and #housesOnMap > 0 then
            for _, houseData in ipairs(housesOnMap) do
                if houseData.unlocked ~= nil and houseData.unlocked == true then
                    return true
                end
            end
        end
    else
        return true
    end
    return false
end

--Check if the player is in a house
function FCOIS.CheckIfInHouse()
    local inHouse = (GetCurrentZoneHouseId() ~= 0) or false
    if not inHouse then
        local x,y,z,rotRad = GetPlayerWorldPositionInHouse()
        if x == 0 and y == 0 and z == 0 and rotRad == 0 then
            return false -- not in a house
        end
    end
    return true -- in a house
end
local checkIfInHouse = FCOIS.CheckIfInHouse

--Check if the player owns the house
function FCOIS.CheckIfIsOwnerOfHouse()
    return IsOwnerOfCurrentHouse() or false
end
local checkIfIsOwnerOfHouse = FCOIS.CheckIfIsOwnerOfHouse

--Check if the bagId is a house bank bag and we are in our own house
function FCOIS.CheckIfHouseBankBagAndInOwnHouse(bagId)
    local retVar = (bagId ~= nil and IsHouseBankBag(bagId) and checkIfInHouse() and checkIfIsOwnerOfHouse) or false
--d("[FCOIS.checkIfHouseBankBagAndInOwnHouse] bagId: " ..tos(bagId) .. ", houseBankBagAndInOwnHouse: " ..tos(retVar))
    return retVar
end

--Check if I'm an owner of a house and I'm curerntly in a house
function FCOIS.CheckIfHouseOwnerAndInsideOwnHouse()
    local retVar = (checkIfInHouse() and checkIfIsOwnerOfHouse()) or false
--d("[FCOIS.checkIfHouseBankBagAndInOwnHouse] bagId: " ..tos(bagId) .. ", houseBankBagAndInOwnHouse: " ..tos(retVar))
    return retVar
end

--Jump to one of the players own houses
function FCOIS.JumpToOwnHouse(withDetails, apiVersion, doClearBackup)
    if not CanJumpToHouseFromCurrentLocation() then
        d("[FCOIS]You cannot jump to a house from your current location!")
        return
    end
    local houseId = getFirstOwnedHouse()
    if houseId == nil or houseId <= 0 then return end

    --Save the parameters so we can use them after reloadui/jump to house in EVENT_PLAYER_ACTIVATED again
    local backupParams = {}
    backupParams.withDetails    = withDetails
    backupParams.apiVersion     = apiVersion
    backupParams.doClearBackup  = doClearBackup
    FCOIS.settingsVars.settings.backupParams = {}
    FCOIS.settingsVars.settings.backupParams = backupParams
    --Teleport to the house id now
    RequestJumpToHouse(houseId, false)
end

-- =====================================================================================================================
--  Confirmation dialog functions
-- =====================================================================================================================
--Function to show a confirmation dialog
function FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, callbackSetup, data, forceUpdate)
--d("[FCOIS]ShowConfirmationDialog - dialogName: " ..tos(dialogName) .. ", title: " ..tos(title) .. ", body: " ..tos(body))
    local libDialog = FCOIS.LDIALOG
    addonVars = FCOIS.addonVars
    local addonName = addonVars.gAddonName
    --Force the dialog to be updated with the title, text, etc.?
    forceUpdate = forceUpdate or false
    --Check if the dialog exists already, and if not register it
    local existingDialogs = libDialog.dialogs
    if forceUpdate == true or existingDialogs[addonName] == nil or existingDialogs[addonName][dialogName] == nil then
        libDialog:RegisterDialog(addonName, dialogName, title, body, callbackYes, callbackNo, callbackSetup, forceUpdate)
    end

--d(">show dialog now")
    --Show the dialog now
    libDialog:ShowDialog(addonName, dialogName, data)
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
----> Sort by value and rebuild key via tsort(FCOIS.mappingVars.gearToIcon)
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
    tsort(FCOIS.mappingVars.gearToIcon)
    local tableToCopyFrom = FCOIS.mappingVars.gearToIcon
    --Clear the table to sort
    FCOIS.mappingVars.iconToGear = {}
    --Loop over the table to sort from
    for gearNr, iconNr in ipairs(tableToCopyFrom) do
        --Transfer the values from the sorted table to the non-sorted table ([gearIconNr] = gearNr)
        FCOIS.mappingVars.iconToGear[iconNr] = gearNr
    end
end

--Function to rebuild the gear set values (icons, ids, names, context menu values, dynamicGear, nonDynamicGear, etc.)
--Called at event_player_activated and if some gear settings change in the settings menu (dynamic marker icons -> enabled as gear e.g.)
function FCOIS.RebuildGearSetBaseVars(iconNr, value, calledFromEventPlayerActivated)
--d("FCOIS]rebuildGearSetBaseVars-calledFromEventPlayerActivated: " ..tos(calledFromEventPlayerActivated))
    calledFromEventPlayerActivated = calledFromEventPlayerActivated or false
    local numVars = FCOIS.numVars
    local settings = FCOIS.settingsVars.settings
    local iconIsGear = settings.iconIsGear
    if iconIsGear == nil then return end
    --Set the 5 static gear icons as standard "isGear" = true
    --local staticGears = numVars.gFCONumGearSetsStatic

    local changeContextMenuEntryTexts = FCOIS.ChangeContextMenuEntryTexts
    local rebuildFilterButtonContextMenuVars = FCOIS.RebuildFilterButtonContextMenuVars

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
            local currentMaxGearSets = numVars.gFCONumGearSets
--d(">iconNrLoop: " ..tos(iconNrLoop) .. ", isGear: " ..tos(isGear) .. ", currentMaxGearSets: " .. tos(currentMaxGearSets))
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
--d(">>is gear! gearCounter: " .. tos(gearCounter) .. ", newMaxGearSets: " ..tos(currentMaxGearSets))
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
					--trem(FCOIS.mappingVars.iconToGear, iconNrLoop) -- to retain table indices
                end
                --Reset the mapping of gear number to icon
                if gearNr ~= nil and gearNr > 0 and FCOIS.mappingVars.gearToIcon[gearNr] ~= nil then
                    --FCOIS.mappingVars.gearToIcon[gearNr] = nil
					trem(FCOIS.mappingVars.gearToIcon, gearNr) -- to retain table indices
                end
--d(">>NOT a gear! gearNr: " .. tos(gearNr) .. ", newMaxGearSets: " ..tos(currentMaxGearSets))
            end
            --Set the new current gear sets number
            FCOIS.numVars.gFCONumGearSets = currentMaxGearSets

            --Update the context menu texts for this icon
            --but not if this function was called from Event_Player_Activated as the same function will be called just after
            --FCOIS.rebuildGearSetBaseVars for all icons (-1) already!
            if not calledFromEventPlayerActivated then
                changeContextMenuEntryTexts(iconNrLoop)
            end
        end -- for ... loop

        --Sort the tables iconToGear and gearToIcon again
        sortGearSetMappingTables()

        --Rebuild the context menu variables for the dynamic and gear icons
        rebuildFilterButtonContextMenuVars()

------------------------------------------------------------------------------------------------------------------------
--Update only one entry
------------------------------------------------------------------------------------------------------------------------
    else
--d("[FCOIS]rebuildGearSetBaseVars - single icon: "..tos(iconNr) .." and value: " ..tos(value))
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
--d(">gearCounter: " ..tos(gearCounter))
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
				--trem(FCOIS.mappingVars.iconToGear, iconNr) -- to retain table indices
            end
            --Reset the mapping of gear number to icon
            if gearNr ~= nil and gearNr > 0 and FCOIS.mappingVars.gearToIcon[gearNr] ~= nil then
                --FCOIS.mappingVars.gearToIcon[gearNr] = nil
				trem(FCOIS.mappingVars.gearToIcon, gearNr) -- to retain table indices
            end
        end

        --Maximum gear set number
        --Get the current max and increase/decrease it, depending on the value
        local currentMaxGearSets = numVars.gFCONumGearSets
--d(">currentMaxGearSets: " ..tos(currentMaxGearSets))
        if value then
            currentMaxGearSets = currentMaxGearSets + 1
        else
            currentMaxGearSets = currentMaxGearSets - 1
        end
        --Set the new current gear sets number
        FCOIS.numVars.gFCONumGearSets = currentMaxGearSets
--d(">newMaxGearSets: " ..tos(FCOIS.numVars.gFCONumGearSets))

        --Update the context menu texts for this icon
        changeContextMenuEntryTexts(iconNr)

        --Sort the tables iconToGear and gearToIcon again
        sortGearSetMappingTables()

        --Rebuild the context menu variables for the dynamic and gear icons
        rebuildFilterButtonContextMenuVars()
    end

    --Update FCOIS with the gear icons
    getGearIcons = getGearIcons or FCOIS.GetGearIcons
    FCOIS.mappingVars.iconToNonDynamicGear = getGearIcons(false)
    FCOIS.mappingVars.iconToDynamicGear = getGearIcons(true)
end

-- =====================================================================================================================
--  Icon into string functions
-- =====================================================================================================================
function FCOIS.BuildIconText(text, iconId, iconRight, noColor)
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
function FCOIS.GetCurrentlyLoggedInCharUniqueId()
    --[[
        local loggedInCharUniqueId = 0
        local loggedInName = GetUnitName("player")
        --Check all the characters of the account
        for i = 1, GetNumCharacters() do
            local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
            local charName = zo_strf(SI_UNIT_NAME, name)
            --If the current logged in character was found
            if loggedInName == charName or loggedInName == name then
                loggedInCharUniqueId = characterId
                break -- exit the loop
            end
        end
        return tos(loggedInCharUniqueId)
        ]]
    return gccharid()
end

--Function to get all characters of the currently logged in @account: server's unique characterID and non unique name.
--Returns a table:nilable with 2 possible variants, either the character ID is key and the name is the value,
--or vice versa.
--Parameter boolean, keyIsCharName:
-->True: the key of the returned table is the character name
-->False: the key of the returned table is the unique character ID (standard)
function FCOIS.GetCharactersOfAccount(keyIsCharName)
    keyIsCharName = keyIsCharName or false
    local charactersOfAccount
    --Check all the characters of the account
    for i = 1, GetNumCharacters() do
        local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
        local charName = zo_strf(SI_UNIT_NAME, name)
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
local getCharactersOfAccount = FCOIS.GetCharactersOfAccount

--Get the character name using it's unique characterId.
--If the 2nd parameter characterTable is given it needs to be a table generated via function FCOIS.getCharactersOfAccount.
--At best the key is the unique characterId, it not it can be the characterName as well.
function FCOIS.GetCharacterName(characterId, characterTable)
    if characterId == nil then return nil end
    local keyIsName = false
    local characterName
    if characterTable == nil then
        characterTable =  getCharactersOfAccount(false)
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
    --d("[FCOIS]--> Scan whole inventory, bag: " .. tos(bagToCheck))
    --Get the bag cache (all entries in that bag)
    --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
    if not bagCache then return end
    local retVar = false
    local junkedItemCount = 0
    local itemsToMarkAsJunk = {}
    isMarked = isMarked or FCOIS.IsMarked
    for _, data in pairs(bagCache) do
        local p_bagId, slotIndex = data.bagId, data.slotIndex
        local isMarkedIcon, _ = isMarked(p_bagId, slotIndex, markerIconsMarkedOnItems, nil)
        local isCompanionItem = checkIfCompanionItem(bagId, slotIndex)
        if isMarkedIcon and not IsItemJunk(p_bagId, slotIndex, isCompanionItem) then
            tins(itemsToMarkAsJunk, data)
        end
    end

    local isJunk = true --moving to junk here
    local itemCountToJunk = #itemsToMarkAsJunk
--d("[FCOIS]JunkMarkedItems - itemCountToJunk: " ..tos(itemCountToJunk))
    if itemCountToJunk > 0 then
        --#203 & #291 Fix kicked from server because of too many items added/removed from junk!
        local function finalCallbackFunc(l_retVar, l_retCount, l_isJunk)
            if l_retVar == true then
                local locVarJunkedItemCount = FCOIS.GetLocText("fcois_junked_item_count", false)
                d(strformat(preChatTextGreen .. locVarJunkedItemCount, tos(l_retCount)))
            end
            --d("<CLEARING TABLES!")
            if l_isJunk == true then
                moveToJunkQueueActive = false
                moveToJunkQueue = {}
            else
                moveFromJunkQueueActive = false
                moveFromJunkQueue = {}
            end
        end
        local packagesCountToProcess = processPackages(itemsToMarkAsJunk, itemsToMarkAsJunkMaxPerPackage, packagesToMarkAsJunkMax,
                function(data) return canItemBeMarkedAsJunkByPackageData(data, isJunk) end,
                function(data) return setItemAsJunkOrRemoveFromJunkByPackageData(data, isJunk) end,
                nil,
                delayToMarkAsJunkInBetweenPackages,
                function(retVar, retCount) finalCallbackFunc(retVar, retCount, isJunk) end --#293
        ) --max 50 packages à 10 items = 500 items (guild bank size)
    end
    return retVar
end

--Get the inventoryType by help of the LibFilters filterPanelId
function FCOIS.GetInventoryTypeByFilterPanel(p_filterPanelId)
    p_filterPanelId = p_filterPanelId or FCOIS.gFilterWhere
    if p_filterPanelId == nil then return nil end
    local inventoryType
    mappingVars = FCOIS.mappingVars
    local libFiltersPanelIdToCraftingPanelInventory = mappingVars.libFiltersPanelIdToCraftingPanelInventory
    local libFiltersPanelIdToNormalInventory = mappingVars.libFiltersPanelIdToInventory

    --Is the craftbag active and additional addons like CraftBagExtended show the craftbag at the bank or mail panel?
    if FCOIS.CheckIfCBEorAGSActive(FCOIS.gFilterWhereParent, true) and INVENTORY_CRAFT_BAG and not ctrlVars.CRAFTBAG:IsHidden() then
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
function FCOIS.CheckIfBagShouldAutoRemoveMarkerIcons(bagId, slotIndex)
--d("[FCOIS]checkIfBagShouldAutoRemoveMarkerIcons")
    if not bagId or not slotIndex or git(bagId, slotIndex) == ITEMTYPE_NONE then return end
    local iconsToAutoRemove = {}
    --Get the FCOIS marker icons at the item
    local dynamicIconIds = FCOIS.mappingVars.dynamicToIcon
    isMarked = isMarked or FCOIS.IsMarked
    local isMarkedIcon, markedDynamicIcons = isMarked(bagId, slotIndex, dynamicIconIds, nil)
    if isMarkedIcon == true then
        local settings = FCOIS.settingsVars.settings
        --For each dynamic check if the setting to auto remove a marker icon is enabled
        for dynamicIconId, isMarkedDnyIcon in ipairs(markedDynamicIcons) do
            if isMarkedDnyIcon == true and settings.icon[dynamicIconId].autoRemoveMarkForBag[bagId] == true then
--d(">checking bag: " ..tos(bagId) .. "> " ..gil(bagId, slotIndex) .. ", dynIconShouldBeRemoved: " ..tos(dynamicIconId))
                tins(iconsToAutoRemove, dynamicIconId)
            end
        end
        --Remove these marker icons now
        if iconsToAutoRemove and #iconsToAutoRemove > 0 then
            FCOIS.MarkItem(bagId, slotIndex, iconsToAutoRemove, false, true)
        end
    end
end

------------------------------------------------
--- Tooltip functions
------------------------------------------------
function FCOIS.HideItemLinkTooltip()
    ClearTooltip(FCOISItemTooltip)
end
local hideItemLinkTooltip = FCOIS.HideItemLinkTooltip

function FCOIS.ShowItemLinkTooltip(control, parent, anchor1, offsetX, offsetY, anchor2)
    if control == nil or control.dataEntry == nil or control.dataEntry.data == nil or control.dataEntry.data.key == nil then
        hideItemLinkTooltip()
        return nil
    end
    local libSets = FCOIS.libSets
    if not libSets then return end
    local data = control.dataEntry.data
    local setItemId = data.setItemId or libSets.GetSetItemId(data.key)
    if setItemId ~= nil then
        local itemLinkOfSetItemId = libSets.buildItemLink(setItemId)
        if itemLinkOfSetItemId ~= nil and itemLinkOfSetItemId ~= "" then
            anchor1 = anchor1 or TOPRIGHT
            anchor2 = anchor2 or TOPLEFT
            offsetX = offsetX or -100
            offsetY = offsetY or 0
            InitializeTooltip(FCOISItemTooltip, parent, anchor1, offsetX, offsetY, anchor2)
            FCOISItemTooltip:SetLink(itemLinkOfSetItemId)
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

--function to return the LibFilters 3.0 filterPanelId constant LF* by the help of the inventory bagId
function FCOIS.GetFilterPanelIdByBagId(bagId)
--d("[FCOIS]GetFilterPanelIdByBagId - bagId: " ..tos(bagId))
    if not bagId then return end
    local mappingVars = FCOIS.mappingVars
    local bagIdToFilterPanelId = mappingVars.bagId2LibFiltersId

    if IsHouseBankBag(bagId) then bagId = BAG_HOUSE_BANK_ONE end
    local filterPanelId = bagIdToFilterPanelId[bagId]
    if filterPanelId == nil then
        checkActivePanel = checkActivePanel or FCOIS.CheckActivePanel
        ---> Special filterPanelId checks via the currently opened panel controls e.g.
        local comingFrom = FCOIS.gFilterWhere
        local _, filterPanelIdNew = checkActivePanel(comingFrom, false)
        filterPanelId = filterPanelIdNew
    end
--d("<filterPanelId: " ..tos(filterPanelId))
    return filterPanelId
end