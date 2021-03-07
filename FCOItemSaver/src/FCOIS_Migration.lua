--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local getSavedVarsMarkedItemsTableName = FCOIS.getSavedVarsMarkedItemsTableName


--Check if the scanned item in function "scanInventoriesForZOsLockedItems" is marked with the ZOs saver icon (white/gray lock icon) and transfer it to FCOIS's icon 1 (lock)
function FCOIS.scanInventoriesForZOsLockedItemsAndTransfer(p_bagId, p_slotIndex)
    local foundAndTransferedOne
    --Scan for ZOs marked icons and transfer them to FCOIS marker icon 1 (lock symbol)
    if ( not FCOIS.preventerVars.gScanningInv and p_bagId ~= nil and p_slotIndex ~= nil ) then
        FCOIS.preventerVars.gScanningInv = true
        local itemId, allowedItemType = FCOIS.MyGetItemInstanceIdNoControl(p_bagId, p_slotIndex)
        --Is the item marked with ZOs marker function and not marked with FCOIS already
        if (itemId ~= nil and IsItemPlayerLocked(p_bagId, p_slotIndex)) then
            foundAndTransferedOne = true
            --Mark the item with FCOIS without checking if other markers should be removed etc. (see function FCOMarkMe())
            FCOIS[getSavedVarsMarkedItemsTableName()][FCOIS_CON_ICON_LOCK][FCOIS.SignItemId(itemId, allowedItemType, nil, nil, p_bagId, p_slotIndex)] = true
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
    --if FCOIS.settingsVars.settings.useZOsLockFunctions == true then return false end
    allInventories = allInventories or false
    if houseBankBagId ~= nil then
        allInventories = false
    end
    local debug = FCOIS.settingsVars.settings.debug
    local FCOISlocVars = FCOIS.localizationVars
    local locVars      = FCOISlocVars.fcois_loc

    --Only scan if not already scanning
    if FCOIS.preventerVars.gScanningInv == true then return false end
    if debug == true then
        FCOIS.debugMessage("scanInventoriesForZOsLockedItemsAndTransfer","Start ALL, allInventories: " ..tostring(allInventories), false, FCOIS_DEBUG_DEPTH_NORMAL, true)
    else
        d(locVars["migrate_ZOs_locks_to_FCOIS_locks_start"])
    end
    local atLeastOneZOsMarkedFound = false
    local allowedBagTypes = {}
    local allowedBagTypesCountMigrated = {}
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
        --Add house bank bagIds if we are in any of our houses
        local isInHouse = (FCOIS.checkIfOwningHouse() == true and FCOIS.checkIfInHouse() == true) or false
        if isInHouse == true then
            for p_houseBankBagId = BAG_HOUSE_BANK_ONE, BAG_HOUSE_BANK_TEN, 1 do
                if IsHouseBankBag(p_houseBankBagId) == true then
                    allowedBagTypes[p_houseBankBagId] = true
                end
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
    --Check if LibDebugLogger and the DebugLogViewer are active. Show their window/quickwindow (depending on it's settings)
    --or show the chat instead
    FCOIS.checkAndShowDebugOutputWindow()

    --Scan every item in the bag
    local itemDelay = 0
    local countItemsScanned = 0
    for bagType, allowed in pairs(allowedBagTypes) do
        zo_callLater(function()
            if allowed then
                allowedBagTypesCountMigrated[bagType] = 0
                zo_callLater(function()
                    if debug == true then
                        FCOIS.debugMessage("scanInventoriesForZOsLockedItemsAndTransfer",">Scanning bag ID: " ..tostring(bagType), false, FCOIS_DEBUG_DEPTH_NORMAL, true)
                    else
                        d(string.format(locVars["migrate_ZOs_locks_to_FCOIS_locks_bagId"], tostring(bagType)))
                    end
                    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagType)
                    local foundAndTransferedOne = false
                    if bagCache and #bagCache > 0 then
                        for _, data in pairs(bagCache) do
                            --Create batches of 50 items and then wait so the server won't kick us because of message spam
                            --Delay the next scanned package of 50 items by 250 milliseconds
                            zo_callLater(function()
                                foundAndTransferedOne = FCOIS.scanInventoriesForZOsLockedItemsAndTransfer(data.bagId, data.slotIndex)
                                countItemsScanned = countItemsScanned + 1
                                --At each 100 items: Increase the delay by a half second
                                if countItemsScanned % 50 == 0 then
                                    itemDelay = itemDelay + 250
                                end
                                --Any item was changed?
                                if foundAndTransferedOne == true then
                                    allowedBagTypesCountMigrated[bagType] = allowedBagTypesCountMigrated[bagType] + 1
                                    atLeastOneZOsMarkedFound = true
                                end
                            end, itemDelay)
                        end
                    end
                end, itemDelay)
            end
        end, itemDelay)
    end
    --Update the inventories
    zo_callLater(function()
        local countItemsMigrated = 0
        if atLeastOneZOsMarkedFound == true then
            FCOIS.FilterBasics(true)
            for bagType, lCountMigratedAtBagType in pairs(allowedBagTypesCountMigrated) do
                countItemsMigrated = countItemsMigrated + lCountMigratedAtBagType
                if debug == true then
                    FCOIS.debugMessage("scanInventoriesForZOsLockedItemsAndTransfer", ">migrated at the bag "..tostring(bagType)..": " ..tostring(lCountMigratedAtBagType), false, FCOIS_DEBUG_DEPTH_NORMAL, true)
                else
                    d(string.format(locVars["migrate_ZOs_locks_to_FCOIS_locks_migrated_at_bag"], tostring(bagType), tostring(lCountMigratedAtBagType)))
                end
            end
        end
        if debug == true then
            FCOIS.debugMessage("scanInventoriesForZOsLockedItemsAndTransfer", "End, allInventories: " ..tostring(allInventories) .. ", migrated/scanned total: " ..tostring(countItemsMigrated) .."/"..tostring(countItemsScanned), false, FCOIS_DEBUG_DEPTH_NORMAL, true)
        else
            d(string.format(locVars["migrate_ZOs_locks_to_FCOIS_locks_end"], tostring(countItemsMigrated), tostring(countItemsScanned)))
        end
    end, itemDelay + 2000)
end