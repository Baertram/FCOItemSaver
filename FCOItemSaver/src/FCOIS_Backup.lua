--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

--The standard allowed bags for the backup
local standardBackupAllowedBagTypes = {}
standardBackupAllowedBagTypes[BAG_WORN] 	= true
standardBackupAllowedBagTypes[BAG_BACKPACK] = true
standardBackupAllowedBagTypes[BAG_BANK] 	= true
standardBackupAllowedBagTypes[BAG_GUILDBANK]= true
standardBackupAllowedBagTypes[BAG_BUYBACK] 	= true
standardBackupAllowedBagTypes[BAG_VIRTUAL] 	= true --Craftbag
standardBackupAllowedBagTypes[BAG_COMPANION_WORN] 	= true
--The text for each bagtype
local locVars = FCOIS.localizationVars.fcois_loc
local bagIdToString = {
    [BAG_WORN] 		        = locVars["options_migrate_bag_type_" .. tostring(BAG_WORN)],
    [BAG_COMPANION_WORN]    = locVars["options_migrate_bag_type_" .. tostring(BAG_COMPANION_WORN)],
    [BAG_BACKPACK]          = locVars["options_migrate_bag_type_" .. tostring(BAG_BACKPACK)],
    [BAG_BANK] 		        = locVars["options_migrate_bag_type_" .. tostring(BAG_BANK)],
    [BAG_GUILDBANK]         = locVars["options_migrate_bag_type_" .. tostring(BAG_GUILDBANK)],
    [BAG_BUYBACK] 	        = locVars["options_migrate_bag_type_" .. tostring(BAG_BUYBACK)],
    [BAG_VIRTUAL] 	        = locVars["options_migrate_bag_type_" .. tostring(BAG_VIRTUAL)], --Craftbag
    [BAG_SUBSCRIBER_BANK]   = locVars["options_migrate_bag_type_" .. tostring(BAG_SUBSCRIBER_BANK)],
    [BAG_HOUSE_BANK_ONE]    = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_ONE)],
    [BAG_HOUSE_BANK_TWO]    = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_TWO)],
    [BAG_HOUSE_BANK_THREE]  = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_THREE)],
    [BAG_HOUSE_BANK_FOUR]   = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_FOUR)],
    [BAG_HOUSE_BANK_FIVE]   = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_FIVE)],
    [BAG_HOUSE_BANK_SIX]    = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_SIX)],
    [BAG_HOUSE_BANK_SEVEN]  = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_SEVEN)],
    [BAG_HOUSE_BANK_EIGHT]  = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_EIGHT)],
    [BAG_HOUSE_BANK_NINE]   = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_NINE)],
    [BAG_HOUSE_BANK_TEN]    = locVars["options_migrate_bag_type_" .. tostring(BAG_HOUSE_BANK_TEN)],
}


------------------------------------------------------------------------------------------------------------------------
-- BACKUP
------------------------------------------------------------------------------------------------------------------------

--Player is not in his house!
--Set variable for EVENT_PLAYER_ACTIVATED so the backup is called later after the port to the house
local function teleportToHouseAndBackupThen(backupType, withDetails, apiVersion, doClearBackup)
    --Set variable so the backup is done after the jump to the house
    --FCOIS.settingsVars.settings.doBackupAfterJumpToHouse = true
    --Jump to the own house now
    FCOIS.jumpToOwnHouse(backupType, withDetails, apiVersion, doClearBackup)
    --> Check EVENT_PLAYER_ACTIVATED in file FCOIS_events.lua now for the backup after jump to house!
end

--Pre-Backup funciton to jump to your house or start the backup now if you do not own any house yet
function FCOIS.preBackup(backupType, withDetails, apiVersion, doClearBackup)
--d("[FCOIS]FCOIS.preBackup")
    --Reset the preventer variable always here to prevent endless port loop attempt from this function FCOIS.preBackup -> EVENT_PLAYER_ACTIVATED -> FCOIS.preBackup ...
    FCOIS.settingsVars.settings.doBackupAfterJumpToHouse = false
    FCOIS.settingsVars.settings.backupParams = nil
    local preVars = FCOIS.preChatVars
    local doBackupNow = false
    local doAskForTeleportToOwnHouse = false
    local isOwningAHouse = FCOIS.checkIfOwningHouse()
    if isOwningAHouse then
--d(">Owning a house")
        local isInHouse = FCOIS.checkIfInHouse()
        if isInHouse then
--d(">In house")
            local isInOwnHouse = FCOIS.checkIfIsOwnerOfHouse()
            if not isInOwnHouse then
--d(">In another owner's house: Ask for teleport now")
                doAskForTeleportToOwnHouse = true
            else
--d(">In own house! Backup now")
                --Player is in his house
                doBackupNow = true
            end
        else
--d(">Not in a house: Ask for teleport now")
            --Player owns a house but is not in the house: Ask to teleport there
            doAskForTeleportToOwnHouse = true
        end
    else
--d("Not owning a house! Backup now")
        --Player is not owning a house: Do the backup now
        doBackupNow = true
    end
    --Teleport to own house and backup then?
    if doAskForTeleportToOwnHouse then
        local title = preVars.preChatTextRed .. "?> Backup"
        local body = locVars["options_backup_ask_before_teleport_to_own_house"]
        --Show confirmation dialog: Teleport to own house?
        --FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
        FCOIS.ShowConfirmationDialog("TeleportToOwnHouseDialog", title, body, function() teleportToHouseAndBackupThen(backupType, withDetails, apiVersion, doClearBackup) end, function() FCOIS.backupMarkerIcons(backupType, withDetails, apiVersion, doClearBackup) end)
    --Do the backup now!
    elseif doBackupNow then
        FCOIS.backupMarkerIcons(backupType, withDetails, apiVersion, doClearBackup)
    end
end

--Restore the marker icons from the saved variables. A backup is nedded in the savedvars, which can be manually triggered from the settings
function FCOIS.backupMarkerIcons(backupType, withDetails, apiVersion, doClearBackup)
    local secondsSinceMidnight = GetSecondsSinceMidnight()
    local currentTimeStamp = GetTimeStamp()
    backupType = backupType or "unique"
    local settings = FCOIS.settingsVars.settings
    local backupData = settings.backupData
    local preVars = FCOIS.preChatVars

    --Get the current API version of the server, to distinguish code differences dependant on the API version
    FCOIS.APIversion = GetAPIVersion()
    local apiVersionToUse
    if apiVersion ~= nil then
        --Use the specified api version
        apiVersionToUse = apiVersion
    else
        apiVersionToUse = FCOIS.APIversion
    end
    apiVersionToUse = tonumber(apiVersionToUse)

    --Scan all the inventories of the player (bank, bag, guild bank, craftbag, buyback, ESO+ subscriber bank, house banks, etc.)
    local allowedBagTypes = standardBackupAllowedBagTypes
    --Is the user an ESO+ subscriber?
    if IsESOPlusSubscriber() then
        --Add the subscriber bank to the inventories to check
        if GetBagUseableSize(BAG_SUBSCRIBER_BANK) > 0 then
            allowedBagTypes[BAG_SUBSCRIBER_BANK] = true
        end
    end
    --Add the house banks
    local isOwningAHouse = FCOIS.checkIfOwningHouse()
    local isInOwnHouse = FCOIS.checkIfInHouse() and FCOIS.checkIfIsOwnerOfHouse()
    if isOwningAHouse and isInOwnHouse then
        local houseBankBagIdToBag = FCOIS.mappingVars.houseBankBagIdToBag
        for _, houseBankBagId in ipairs(houseBankBagIdToBag) do
            if houseBankBagId ~= nil and IsHouseBankBag(houseBankBagId) then
                --Add the house bank bags
                allowedBagTypes[houseBankBagId] = true
            end
        end
    end
    --Backup the marked items with their unique item Ids now?
    if backupType == "unique" then
        --Get the current date
        local currentDate = GetDateStringFromTimestamp(currentTimeStamp)
        --Get the current time
        local isENClient = (GetCVar("Language.2") == "en") or false
        local lCLOCK_FORMAT = (isENClient and TIME_FORMAT_PRECISION_TWELVE_HOUR) or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
        local lTIME_FORMAT = (isENClient and TIME_FORMAT_STYLE_CLOCK_TIME) or TIME_FORMAT_STYLE_COLONS
        local currentTime = ZO_FormatTime(secondsSinceMidnight, lTIME_FORMAT, lCLOCK_FORMAT)
        local localDateAndTimeStr = currentDate .. ", " .. currentTime

        d("\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        d(preVars.preChatTextGreen .. ">>> Backup of marked items by the help of the unique IDs started >>>")
        d(">Backup parameters: show details: " ..tostring(withDetails) .. ", using API version " ..tostring(apiVersionToUse) .. ", clear existing backup with same API version: " ..tostring(doClearBackup))
        if isOwningAHouse and not isInOwnHouse then
            d(preVars.preChatTextRed .. "?> HOUSE STORAGE: Please travel to one of your houses in order to backup the house storage banks too!\nPlease follow this advice and redo the backup afterwards!")
        end

        --Clear the last backup for the specified APIversion?
        if doClearBackup then
            if backupData[apiVersionToUse] ~= nil then
                backupData[apiVersionToUse] = nil
            end
        end
        --Create backup data table new
        if backupData and backupData[apiVersionToUse] == nil then
            backupData[apiVersionToUse] = {}
        end
        --Add the current date and time to the backup info
        backupData[apiVersionToUse].timestamp = localDateAndTimeStr

        --All given bags get scanned now for marked items and if marked, saved to the SavedVars with their unique ID.
        --The housebank can only be accessed if inside a house!
        --The guild bank can only be accessed if opend at lest once before (may be not up2date as the backup runs as other users could have changed the guild bank meanwhile!)
        local totalItems = 0
        local totalMarkedItems = 0
        for bagType, allowed in pairs(allowedBagTypes) do
            if allowed then
                --Do the new backup now
                local bagStr = bagIdToString[bagType] or "???"
                d(preVars.preChatTextBlue .. "!> Starting backup of bag: \'" ..tostring(bagStr) .. "\'")
                local bagTypBackupFailed = false
                local foundMarkedItems = 0
                local updatedMarkedItems = 0
                local foundMarkedMarkerIconsOnItems = 0
                local foundItemsInBag = 0
                local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagType)
                if bagCache ~= nil then
                    --Guild bank checks
                    if bagType == BAG_GUILDBANK then
                        local itemsInBag = #bagCache or 0
                        if itemsInBag == 0 then
                            d(preVars.preChatTextRed .. "?> Please open EACH guild bank which you want to backup at least once before starting the backup!\nOtherwise no items will be accessible by this addon.\nPlease follow this advice and redo the backup afterwards!")
                            bagTypBackupFailed = true
                        end
                    end
                    for _, data in pairs(bagCache) do
                        local bagId = data.bagId
                        local slotIndex = data.slotIndex
                        if bagId ~= nil and slotIndex ~= nil then
                            local isItemMarked
                            local markedIcons
                            --Is the bagtype not the craftbag? As the craftbag's slotIndex is the item's itemId!
                            if bagType ~= BAG_VIRTUAL then
                                isItemMarked, markedIcons = FCOIS.IsMarked(bagId, slotIndex, -1)
                            else
                                --Craftbag. Item's slotIndex is the itemId.
                                -->Overwrite it with the itemInstanceid
                                --Use another function here to check if item is marked and which marker icons are set (itemInstanceId get#s signed in there!)
                                local itemInstanceId = data.itemInstanceId
                                isItemMarked, markedIcons = FCOIS.IsMarkedByItemInstanceId(itemInstanceId, -1)
                            end
                            --Is the item marked with any marker icon?
                            if isItemMarked then
                                --Get the item's unique ID
                                local uniqueItemId
                                --Is the bagtype not the craftbag? As the craftbag's slotIndex is the item's itemId!
                                if bagType ~= BAG_VIRTUAL then
                                    uniqueItemId = GetItemUniqueId(bagId, slotIndex)
                                else
                                    --CraftBag, slotIndex is the itemId. So get the uniqueId from the data.
                                    uniqueItemId = data.uniqueId
                                end
                                local id64Str = zo_getSafeId64Key(uniqueItemId)
--d(">item is marked: " ..tostring(id64Str))
                                --Is the item already in the backup data? Then update it
                                local iconsStr
                                local itemLink
                                if withDetails then
                                    iconsStr = ""
                                    if bagType ~= BAG_VIRTUAL then
                                        itemLink = GetItemLink(bagId, slotIndex)
                                    else
                                        --CraftBag, slotIndex is the itemId. So get the itemLink from the data.
                                        itemLink = data.lnk
                                    end
--d(">" .. itemLink)
                                end
                                --Add the unique ID to the savedvars backup section.
                                --Is the item already in the backup data? Then update/overwrite it
                                local updateDone = false
                                if backupData[apiVersionToUse][id64Str] ~= nil then
                                    updateDone = true
                                else
                                    backupData[apiVersionToUse][id64Str] = {}
                                end
                                --Now add all found set marker icons of this item below the uniqueItemId
                                for iconId, isMarked in pairs(markedIcons) do
                                    --Is the icon marked for this item? Then save it to the backup data
                                    if isMarked == true then
                                        backupData[apiVersionToUse][id64Str][iconId] = isMarked
                                        foundMarkedMarkerIconsOnItems = foundMarkedMarkerIconsOnItems + 1
                                        if withDetails then
                                            if iconsStr == "" then
                                                iconsStr = tostring(iconId)
                                            else
                                                iconsStr = iconsStr .. "," .. tostring(iconId)
                                            end
                                        end
                                    end
                                end
                                if withDetails and iconsStr ~= nil and iconsStr ~= "" and itemLink ~= nil then
                                    d(">backuped icons["..iconsStr.."] for " .. itemLink)
                                end
                                if updateDone then
                                    updatedMarkedItems = updatedMarkedItems + 1
                                else
                                    foundMarkedItems = foundMarkedItems + 1
                                end
                            end
                            foundItemsInBag = foundItemsInBag + 1
                        end
                    end
                    if not bagTypBackupFailed then
                        d(preVars.preChatTextBlue .. "<! Finished backup of bag: \'" ..tostring(bagStr) .. "\'.\n--->Backuped " .. tostring(foundMarkedMarkerIconsOnItems) .. " icons at " .. tostring(foundMarkedItems + updatedMarkedItems) .." marked items (" .. tostring(updatedMarkedItems) .. " did already exist and were updated), of " .. tostring(foundItemsInBag) .. " total items in bag")
                    end
                    d("====================")
                    totalMarkedItems = totalMarkedItems + ( foundMarkedItems + updatedMarkedItems )
                    totalItems = totalItems + foundItemsInBag
                end
            end
        end
        d("!>>> Total backuped/found items: " .. tostring(totalMarkedItems) .. "/" .. tostring(totalItems))
        d(preVars.preChatTextGreen .. "<<< Backup finished for API version " ..tostring(apiVersionToUse) .. " <<<")
        d("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
        --Update the settings restore API versions dropdownbox
        FCOIS.buildRestoreAPIVersionData(true)
    end
end


------------------------------------------------------------------------------------------------------------------------
-- RESTORE
------------------------------------------------------------------------------------------------------------------------

--Stuff to do before restore can be started
function FCOIS.preRestore(restoreType, withDetails, apiVersion)
    FCOIS.restoreMarkerIcons(restoreType, withDetails, apiVersion)
end

--Get the marked items count in a backup set of a bag
local function getMarkedItemsInBackupSet(backupSetOfAPI)
    if backupSetOfAPI == nil then return 0 end
    local backupSetEntries = 0
    for _, _ in pairs(backupSetOfAPI) do
        backupSetEntries = backupSetEntries + 1
    end
    return backupSetEntries
end

--Restore the marker icons from the saved variables. A backup is nedded in the savedvars, which can be manually triggered from the settings
function FCOIS.restoreMarkerIcons(restoreType, withDetails, apiVersion)
    restoreType = restoreType or "unique"
    local settings = FCOIS.settingsVars.settings
    local backupData = settings.backupData
    local preVars = FCOIS.preChatVars

    --Get the current API version of the server, to distinguish code differences dependant on the API version
    FCOIS.APIversion = GetAPIVersion()
    local lastApiVersion
    local apiVersionToUse
    if apiVersion ~= nil then
        --Set both the same in order to let the check later fail if both are not given
        lastApiVersion = apiVersion
    else
        apiVersion = FCOIS.APIversion
        lastApiVersion = apiVersion - 1
    end
    apiVersionToUse = tonumber(apiVersionToUse)

    --Retsore the marked items with their unique item Ids now?
    if restoreType == "unique" then
        d("\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
        if apiVersion == lastApiVersion then
            if backupData[apiVersion] == nil then
                d(preVars.preChatTextRed .. "?> Restore of marked items not possible: Backup for specified API version "..tostring(apiVersion) .." not found! <<<")
                return false
            end
        else
            if backupData[apiVersion] == nil and backupData[lastApiVersion] == nil then
                d(preVars.preChatTextRed .. "?> Restore of marked items not possible: Backup for current " .. tostring(apiVersion) .. " or last API version " .. tostring(lastApiVersion) .. " not found! <<<")
                return false
            end
        end

        d(preVars.preChatTextGreen .. ">>> Restore of marked items by the help of the unique IDs started >>>")
        if backupData[apiVersion] ~= nil then
            d(preVars.preChatTextGreen .. "!> Restoring backup of API version " ..tostring(apiVersion))
            apiVersionToUse = apiVersion
        elseif backupData[lastApiVersion] ~= nil then
            d(preVars.preChatTextGreen .. "!> Restoring backup of last API version " .. tostring(lastApiVersion))
            apiVersionToUse = lastApiVersion
        end
        --Check if the backupset got the needed data
        if not backupData or not backupData[apiVersionToUse] then
            d(preVars.preChatTextRed .. "?> Restore of marked items not possible: Backup for API version " .. tostring(apiVersionToUse) .. " not found! <<<")
            return false
        end
        apiVersionToUse = tonumber(apiVersionToUse)

        --Get the marked items in the backup set of this bag
        local markedItemsInBackupSet = getMarkedItemsInBackupSet(backupData[apiVersionToUse]) or 0
        d("!> Marked items in backup set: " ..tostring(markedItemsInBackupSet))

        --Scan all the inventories of the player (bank, bag, guild bank, craftbag, buyback, ESO+ subscriber bank, house banks, etc.)
        local allowedBagTypes = standardBackupAllowedBagTypes
        --Is the user an ESO+ subscriber?
        if IsESOPlusSubscriber() then
            --Add the subscriber bank to the inventories to check
            if GetBagUseableSize(BAG_SUBSCRIBER_BANK) > 0 then
                allowedBagTypes[BAG_SUBSCRIBER_BANK] = true
            end
        end
        --Add the house banks
        local isOwningAHouse = FCOIS.checkIfOwningHouse()
        local isInOwnHouse = FCOIS.checkIfInHouse() and FCOIS.checkIfIsOwnerOfHouse()
        if isOwningAHouse and isInOwnHouse then
            local houseBankBagIdToBag = FCOIS.mappingVars.houseBankBagIdToBag
            for _, houseBankBagId in ipairs(houseBankBagIdToBag) do
                if houseBankBagId ~= nil and IsHouseBankBag(houseBankBagId) then
                    --Add the house bank bags
                    allowedBagTypes[houseBankBagId] = true
                end
            end
        end
        if isOwningAHouse and not isInOwnHouse then
            d(preVars.preChatTextRed .. "?> HOUSE STORAGE BANK: Restore of marked items from house banks not possible! Please visit one of your houses so the addon can restore the house banks too!\nPlease follow this advice and redo the restore afterwards.")
        end
        local totalItems = 0
        local totalMarkedItems = 0
        for bagType, allowed in pairs(allowedBagTypes) do
            if allowed then
                --Do the new backup now
                local bagStr = bagIdToString[bagType] or "???"
                d(preVars.preChatTextBlue .. "!> Starting restore of bag: \'" ..tostring(bagStr) .. "\'")
                local bagTypRestoreFailed = false
                local foundMarkedItems = 0
                local foundMarkedMarkerIconsOnItems = 0
                local foundItemsInBag = 0
                local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagType)
                if bagCache ~= nil then
                    --Guild bank checks
                    if bagType == BAG_GUILDBANK then
                        local itemsInBag = #bagCache or 0
                        if itemsInBag == 0 then
                            d(preVars.preChatTextRed .. "?> Please open EACH guild bank which you want to restore at least once before starting the restore!\nOtherwise no items will be accessible by this addon.\nPlease follow this advice and redo the restore afterwards!")
                            bagTypRestoreFailed = true
                        end
                    end
                    for _, data in pairs(bagCache) do
                        local bagId = data.bagId
                        local slotIndex = data.slotIndex
                        if bagId ~= nil and slotIndex ~= nil then
                            --Get the item's unique ID
                            local uniqueItemId = GetItemUniqueId(bagId, slotIndex)
                            local id64Str = zo_getSafeId64Key(uniqueItemId)
                            --Is the item in the backup data with this unique ID? Then retsore it
                            if backupData[apiVersion][id64Str] ~= nil then
                                --Get the saved backup data of this item in the bag
                                local uniqueItemIdMarkers = backupData[apiVersion][id64Str]
                                --Get the icons from the backupDataSet
                                local iconsStr
                                local itemLink
                                if withDetails then
                                    iconsStr = ""
                                    itemLink = GetItemLink(bagId, slotIndex)
                                end
                                for iconId, isMarked in pairs(uniqueItemIdMarkers) do
                                    if type(iconId) == "number" and isMarked then
                                        --Mark the item again with all found icon markers
                                        FCOIS.MarkItem(bagId, slotIndex, iconId, true, false)
                                        foundMarkedMarkerIconsOnItems = foundMarkedMarkerIconsOnItems + 1
                                        if withDetails then
                                            if iconsStr == "" then
                                                iconsStr = tostring(iconId)
                                            else
                                                iconsStr = iconsStr .. "," .. tostring(iconId)
                                            end
                                        end
                                    end
                                end
                                if withDetails then
                                    d(">restored icons["..iconsStr.."] for " .. itemLink)
                                end
                                --Increase the counter
                                foundMarkedItems = foundMarkedItems + 1
                            end
                            foundItemsInBag = foundItemsInBag + 1
                        end
                    end
                    if not bagTypRestoreFailed then
                        d(preVars.preChatTextBlue .. "<! Finished restore of bag: \'" ..tostring(bagStr) .. "\'.\n--->Re-Marked " .. tostring(foundMarkedMarkerIconsOnItems) .. " icons on " .. tostring(foundMarkedItems) .." items, of " .. tostring(foundItemsInBag) .. " total items in bag")
                    end
                    d("====================")
                    totalMarkedItems = totalMarkedItems + foundMarkedItems
                    totalItems = totalItems + foundItemsInBag
                end
            end
        end
        d("!>>> Total re-marked/in backup set/found items: " .. tostring(totalMarkedItems) .. "/" .. tostring(markedItemsInBackupSet) .. "/" .. tostring(totalItems))
        d(preVars.preChatTextGreen .. "<<< Restore finished <<<")
        d("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
    end
end


------------------------------------------------------------------------------------------------------------------------
-- DELETE BACKUP
------------------------------------------------------------------------------------------------------------------------

function FCOIS.deleteBackup(backupType, apiVersionToDelete)
    backupType = backupType or "unique"
    if apiVersionToDelete == nil then return false end
    local settings = FCOIS.settingsVars.settings
    local backupData = settings.backupData
    local preVars = FCOIS.preChatVars
    --Is the backup existing which should be deleted?
    if backupData[apiVersionToDelete] == nil then
        d(preVars.preChatTextRed .. "?> Backup for specified API version "..tostring(apiVersion) .." not found! <<<")
        return false
    else
        --Delete the backup now
        backupData[apiVersionToDelete] = nil
        d(preVars.preChatTextGreen .. "?> Backup for specified API version "..tostring(apiVersion) .." was deleted! <<<")
        --Update the list of restorable backups now in the settings dropdown
        FCOIS.buildRestoreAPIVersionData(true)
        return true
    end
end