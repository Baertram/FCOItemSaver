--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local ton = tonumber
local tos = tostring
local strformat = string.format

local gil = GetItemLink 
--local numIdTypes = FCOIS.numVars.idTypes

--local debugMessage = FCOIS.debugMessage
local checkIfIsOwnerOfHouse = FCOIS.CheckIfIsOwnerOfHouse
local checkIfOwningHouse = FCOIS.CheckIfOwningHouse
local checkIfInHouse = FCOIS.CheckIfInHouse
local showConfirmationDialog = FCOIS.ShowConfirmationDialog
local createFCOISUniqueIdString = FCOIS.CreateFCOISUniqueIdString
local signItemId = FCOIS.SignItemId

local isMarked
local isMarkedByItemInstanceId


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
local bagIdToString = {}
local locVars = FCOIS.localizationVars.fcois_loc
local migrateBagTypePrefix = "options_migrate_bag_type_"
local bagTypesToIterate = {
        [BAG_WORN] 		        = true,
        [BAG_COMPANION_WORN]    = true,
        [BAG_BACKPACK]          = true,
        [BAG_BANK] 		        = true,
        [BAG_GUILDBANK]         = true,
        [BAG_BUYBACK] 	        = true,
        [BAG_VIRTUAL] 	        = true,
        [BAG_SUBSCRIBER_BANK]   = true,
        [BAG_HOUSE_BANK_ONE]    = true,
        [BAG_HOUSE_BANK_TWO]    = true,
        [BAG_HOUSE_BANK_THREE]  = true,
        [BAG_HOUSE_BANK_FOUR]   = true,
        [BAG_HOUSE_BANK_FIVE]   = true,
        [BAG_HOUSE_BANK_SIX]    = true,
        [BAG_HOUSE_BANK_SEVEN]  = true,
        [BAG_HOUSE_BANK_EIGHT]  = true,
        [BAG_HOUSE_BANK_NINE]   = true,
        [BAG_HOUSE_BANK_TEN]    = true,
}

local function updateBagId2String()
    FCOIS.localizationVars = FCOIS.localizationVars or {}
    locVars = FCOIS.localizationVars.fcois_loc
    --[[
    bagIdToString = {
        [BAG_WORN] 		        = locVars["options_migrate_bag_type_" .. tos(BAG_WORN)],
        [BAG_COMPANION_WORN]    = locVars["options_migrate_bag_type_" .. tos(BAG_COMPANION_WORN)],
        [BAG_BACKPACK]          = locVars["options_migrate_bag_type_" .. tos(BAG_BACKPACK)],
        [BAG_BANK] 		        = locVars["options_migrate_bag_type_" .. tos(BAG_BANK)],
        [BAG_GUILDBANK]         = locVars["options_migrate_bag_type_" .. tos(BAG_GUILDBANK)],
        [BAG_BUYBACK] 	        = locVars["options_migrate_bag_type_" .. tos(BAG_BUYBACK)],
        [BAG_VIRTUAL] 	        = locVars["options_migrate_bag_type_" .. tos(BAG_VIRTUAL)], --Craftbag
        [BAG_SUBSCRIBER_BANK]   = locVars["options_migrate_bag_type_" .. tos(BAG_SUBSCRIBER_BANK)],
        [BAG_HOUSE_BANK_ONE]    = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_ONE)],
        [BAG_HOUSE_BANK_TWO]    = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_TWO)],
        [BAG_HOUSE_BANK_THREE]  = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_THREE)],
        [BAG_HOUSE_BANK_FOUR]   = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_FOUR)],
        [BAG_HOUSE_BANK_FIVE]   = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_FIVE)],
        [BAG_HOUSE_BANK_SIX]    = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_SIX)],
        [BAG_HOUSE_BANK_SEVEN]  = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_SEVEN)],
        [BAG_HOUSE_BANK_EIGHT]  = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_EIGHT)],
        [BAG_HOUSE_BANK_NINE]   = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_NINE)],
        [BAG_HOUSE_BANK_TEN]    = locVars["options_migrate_bag_type_" .. tos(BAG_HOUSE_BANK_TEN)],
    }
    ]]
    if locVars ~= nil then
        for bagTypeNr, isActivated in pairs(bagTypesToIterate) do
            if isActivated == true then
                bagIdToString[bagTypeNr] = locVars[migrateBagTypePrefix .. tos(bagTypeNr)]
            end
        end
    end
    FCOIS.localizationVars.bagIdToString = bagIdToString
end
updateBagId2String()

local idTypeToName = {
    [false]                                         = "Non unique",
    [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE]    = "ZOS unique",
    [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE]  = "FCOIS unique",
}


------------------------------------------------------------------------------------------------------------------------
-- BACKUP
------------------------------------------------------------------------------------------------------------------------

--Player is not in his house!
--Set variable for EVENT_PLAYER_ACTIVATED so the backup is called later after the port to the house
local function teleportToHouseAndBackupThen(withDetails, apiVersion, doClearBackup)
    --Set variable so the backup is done after the jump to the house
    --FCOIS.settingsVars.settings.doBackupAfterJumpToHouse = true
    --Jump to the own house now
    FCOIS.JumpToOwnHouse(withDetails, apiVersion, doClearBackup)
    --> Check EVENT_PLAYER_ACTIVATED in file FCOIS_events.lua now for the backup after jump to house!
end

--Restore the marker icons from the saved variables. A backup is needed in the savedvars, which can be manually triggered from the settings
function FCOIS.BackupMarkerIcons(withDetails, apiVersion, doClearBackup)
    local secondsSinceMidnight = GetSecondsSinceMidnight()
    local currentTimeStamp = GetTimeStamp()
    local settings = FCOIS.settingsVars.settings
    settings.backupData = settings.backupData or {}
    local backupData = settings.backupData
    local preVars = FCOIS.preChatVars

    isMarked = isMarked or FCOIS.IsMarked
    isMarkedByItemInstanceId = isMarkedByItemInstanceId or FCOIS.IsMarkedByItemInstanceId

    updateBagId2String()

    --Get the current API version of the server, to distinguish code differences dependant on the API version
    FCOIS.APIversion = GetAPIVersion()
    local apiVersionToUse
    if apiVersion ~= nil then
        --Use the specified api version
        apiVersionToUse = apiVersion
    else
        apiVersionToUse = FCOIS.APIversion
    end
    apiVersionToUse = ton(apiVersionToUse)

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
    local isOwningAHouse = checkIfOwningHouse()
    local isInOwnHouse = checkIfInHouse() and checkIfIsOwnerOfHouse()
    if isOwningAHouse and isInOwnHouse then
        local houseBankBagIdToBag = FCOIS.mappingVars.houseBankBagIdToBag
        for _, houseBankBagId in ipairs(houseBankBagIdToBag) do
            if houseBankBagId ~= nil and IsHouseBankBag(houseBankBagId) then
                --Add the house bank bags
                allowedBagTypes[houseBankBagId] = true
            end
        end
    end
    --Backup the marked items with their non-unique, ZOS unique and FCOIS-unique item Ids now?
    --Get the current date
    local currentDate = GetDateStringFromTimestamp(currentTimeStamp)
    --Get the current time
    local isENClient = (GetCVar("Language.2") == "en") or false
    local lCLOCK_FORMAT = (isENClient and TIME_FORMAT_PRECISION_TWELVE_HOUR) or TIME_FORMAT_PRECISION_TWENTY_FOUR_HOUR
    local lTIME_FORMAT = (isENClient and TIME_FORMAT_STYLE_CLOCK_TIME) or TIME_FORMAT_STYLE_COLONS
    local currentTime = ZO_FormatTime(secondsSinceMidnight, lTIME_FORMAT, lCLOCK_FORMAT)
    local localDateAndTimeStr = currentDate .. ", " .. currentTime

    d("\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    d(preVars.preChatTextGreen .. ">>> Backup of marked items non-uniqueId/unique IDs (ZOs, FCOIS) started >>>")
    d(">Backup parameters: show details: " ..tos(withDetails) .. ", using API version " ..tos(apiVersionToUse) .. ", clear existing backup with same API version: " ..tos(doClearBackup))
    --FCOIS uniqueId part settings
    d(">!!!Attention!!! The backup of the FCOIS uniqueIds will be done with the current FCOIS uiqueID settings!\nRestore would be working if you change the FCOIS uniqueId settings meanwhile BUT your marker icons would not find the items anymore then!\nSo keep the FCOIS uniqueId settings untouched before your restore or you might loose markers.")
    d(">Current FCOIS uniqueId parts are: ")
    local uniqueIdParts = settings.uniqueIdParts
    for uniqueIdPartName, uniqueIdPartValue in pairs(uniqueIdParts) do
        d(">" ..tos(uniqueIdPartName) .." = " .. tos(uniqueIdPartValue))
    end

    if isOwningAHouse and not isInOwnHouse then
        d(preVars.preChatTextRed .. "?> HOUSE STORAGE: Please travel to one of your houses in order to backup the house storage banks too!\nPlease follow this advice and redo the backup afterwards!")
    end

    --Clear the last backup for the specified APIversion?
    if doClearBackup then
        if backupData and backupData[apiVersionToUse] ~= nil then
            backupData[apiVersionToUse] = nil
        end
    end
    --Create backup data table new
    if backupData and backupData[apiVersionToUse] == nil then
        backupData[apiVersionToUse] = {}
    end
    --Add the current date and time to the backup info
    backupData[apiVersionToUse].timestamp = localDateAndTimeStr
    --Add the FCOIS uniqueId parts used to do the backup
    backupData[apiVersionToUse].FCOISuniqueIdParts = ZO_ShallowTableCopy(uniqueIdParts)

    --All given bags get scanned now for marked items and if marked, saved to the SavedVars with their unique ID.
    --The housebank can only be accessed if inside a house!
    --The guild bank can only be accessed if opend at lest once before (may be not up2date as the backup runs as other users could have changed the guild bank meanwhile!)
    local totalItems = 0
    local totalMarkedItems = 0
    for bagType, allowed in pairs(allowedBagTypes) do
        if allowed == true then
            --Do the new backup now
            if bagIdToString[bagType] ~= nil then
                local bagStr = bagIdToString[bagType]
                if bagStr == nil then bagStr = "???" end
                d(preVars.preChatTextBlue .. "!> Starting backup of bag: \'" ..tos(bagStr) .. "\'")
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
                                FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                                isItemMarked, markedIcons = isMarked(bagId, slotIndex, -1)
                            else
                                --Craftbag. Item's slotIndex is the itemId.
                                -->Overwrite it with the itemInstanceid
                                --Use another function here to check if item is marked and which marker icons are set (itemInstanceId get#s signed in there!)
                                FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                                local itemInstanceId = data.itemInstanceId
                                isItemMarked, markedIcons = isMarkedByItemInstanceId(itemInstanceId, -1)
                            end
                            --Is the item marked with any marker icon?
                            if isItemMarked then
                                local nonUniqueId
                                local zosUniqueId
                                local FCOISUniqueId
                                --if bagType ~= BAG_VIRTUAL then
                                nonUniqueId =     signItemId(GetItemInstanceId(bagId, slotIndex), nil, true, nil, bagId, slotIndex)
                                zosUniqueId =     zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex))
                                FCOISUniqueId =   createFCOISUniqueIdString(nil, bagId, slotIndex, nil)
                                --[[
                                else
                                    --CraftBag, slotIndex is the itemId. So get the uniqueId from the data.
                                    nonUniqueId =     signItemId(data.itemInstanceId, nil, true, nil, nil, nil)
                                    zosUniqueId =     data.uniqueId
                                    FCOISUniqueId =   createFCOISUniqueIdString(nil, bagId, slotIndex, nil)
                                end
                                ]]
                                local markerIconIdsToSaved = {
                                    [false]                                         = nonUniqueId,
                                    [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE]    = zosUniqueId,
                                    [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE]  = FCOISUniqueId,
                                }

                                local iconsStr
                                local itemLink
                                local updateDone = false
                                local counterLoops = 0
                                for idTypeIndex, markerIconItemIdToSave in pairs(markerIconIdsToSaved) do
                                    if markerIconItemIdToSave ~= nil and markerIconItemIdToSave ~= "" then
                                        counterLoops = counterLoops + 1
                                        --d(">item is marked: " ..tos(id64Str))
                                        --Is the item already in the backup data? Then update it
                                        if withDetails and counterLoops == 1 then
                                            iconsStr = ""
                                            --if bagType ~= BAG_VIRTUAL then
                                            itemLink = gil(bagId, slotIndex)
                                            --else
                                            --CraftBag, slotIndex is the itemId. So get the itemLink from the data.
                                            --    itemLink = data.lnk
                                            --end
                                            --d(">" .. itemLink)
                                        end
                                        --Add the unique ID to the savedvars backup section.
                                        --Is the item already in the backup data? Then update/overwrite it
                                        if backupData[apiVersionToUse][markerIconItemIdToSave] ~= nil then
                                            updateDone = true
                                        else
                                            backupData[apiVersionToUse][markerIconItemIdToSave] = {}
                                        end
                                        --Now add all found set marker icons of this item below the uniqueItemId
                                        for iconId, isMarkedIcon in pairs(markedIcons) do
                                            --Is the icon marked for this item? Then save it to the backup data
                                            if isMarkedIcon == true then
                                                backupData[apiVersionToUse][markerIconItemIdToSave][iconId] = true
                                                if counterLoops == 1 then
                                                    foundMarkedMarkerIconsOnItems = foundMarkedMarkerIconsOnItems + 1
                                                    if withDetails then
                                                        if iconsStr == "" then
                                                            iconsStr = tos(iconId)
                                                        else
                                                            iconsStr = iconsStr .. "," .. tos(iconId)
                                                        end
                                                    end
                                                end
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
                        d(preVars.preChatTextBlue .. "<! Finished backup of bag: \'" ..tos(bagStr) .. "\'.\n--->Backuped " .. tos(foundMarkedMarkerIconsOnItems) .. " icons at " .. tos(foundMarkedItems + updatedMarkedItems) .." marked items (" .. tos(updatedMarkedItems) .. " did already exist and were updated), of " .. tos(foundItemsInBag) .. " total items in bag")
                    end
                    d("====================")
                    totalMarkedItems = totalMarkedItems + ( foundMarkedItems + updatedMarkedItems )
                    totalItems = totalItems + foundItemsInBag
                end
            else
                d(preVars.preChatTextRed .. "!> Backup aborted, bagType unknown \'" ..tos(bagType) .. "\'")
                d("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
                return false
            end
        end
    end
    d("!>>> Total backuped/found items: " .. tos(totalMarkedItems) .. "/" .. tos(totalItems))
    d(preVars.preChatTextGreen .. "<<< Backup finished for API version " ..tos(apiVersionToUse) .. " <<<")
    d("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
    --Update the settings restore API versions dropdownbox
    FCOIS.BuildRestoreAPIVersionData(true)
end
local backupMarkerIcons = FCOIS.BackupMarkerIcons

--Pre-Backup funciton to jump to your house or start the backup now if you do not own any house yet
function FCOIS.PreBackup(withDetails, apiVersion, doClearBackup)
--d("[FCOIS]FCOIS.preBackup")
    locVars = FCOIS.localizationVars.fcois_loc
    --Reset the preventer variable always here to prevent endless port loop attempt from this function FCOIS.preBackup -> EVENT_PLAYER_ACTIVATED -> FCOIS.preBackup ...
    FCOIS.settingsVars.settings.doBackupAfterJumpToHouse = false
    FCOIS.settingsVars.settings.backupParams = nil
    local preVars = FCOIS.preChatVars
    local doBackupNow = false
    local doAskForTeleportToOwnHouse = false
    local isOwningAHouse = checkIfOwningHouse()
    if isOwningAHouse then
--d(">Owning a house")
        local isInHouse = checkIfInHouse()
        if isInHouse then
--d(">In house")
            local isInOwnHouse = checkIfIsOwnerOfHouse()
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
        --showConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
        showConfirmationDialog("TeleportToOwnHouseDialog",
                title,
                body,
                function() teleportToHouseAndBackupThen(withDetails, apiVersion, doClearBackup) end,
                function() backupMarkerIcons(withDetails, apiVersion, doClearBackup) end)
    --Do the backup now!
    elseif doBackupNow then
        backupMarkerIcons(withDetails, apiVersion, doClearBackup)
    end
end


------------------------------------------------------------------------------------------------------------------------
-- RESTORE
------------------------------------------------------------------------------------------------------------------------

--Get the marked items count in a backup set of a bag
local function getMarkedItemsInBackupSet(backupSetOfAPI)
    if backupSetOfAPI == nil then return 0, 0, 0, 0 end
    local skipMe = {
        ["FCOISuniqueIdParts"] =    true,
        ["timestamp"] =             true,
    }
    local backupSetEntriesNonUnique = 0
    local backupSetEntriesZOsUnique = 0
    local backupSetEntriesFCOISUnique = 0
    local backupSetEntriesTotal = 0
    for key, _ in pairs(backupSetOfAPI) do
        if not skipMe[key] then
            backupSetEntriesTotal = backupSetEntriesTotal + 1

            local typeOfKey = type(key)
            if typeOfKey == "number" then
                --Non-unique
                backupSetEntriesNonUnique = backupSetEntriesNonUnique + 1
            elseif typeOfKey == "string" then
                if string.find(key, ",") ~= nil then
                    --FCOIS unique
                    backupSetEntriesFCOISUnique = backupSetEntriesFCOISUnique + 1
                else
                    --ZOs unique
                    backupSetEntriesZOsUnique = backupSetEntriesZOsUnique + 1
                end
            end
        end
    end
    return backupSetEntriesTotal, backupSetEntriesNonUnique, backupSetEntriesZOsUnique, backupSetEntriesFCOISUnique
end

--Restore the marker icons from the saved variables. A backup is nedded in the savedvars, which can be manually triggered from the settings
function FCOIS.RestoreMarkerIcons(withDetails, apiVersion)
    local settings = FCOIS.settingsVars.settings
    local backupData = settings.backupData
    local preVars = FCOIS.preChatVars

    updateBagId2String()

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
    apiVersion = ton(apiVersion)
    lastApiVersion = ton(lastApiVersion)

    d("\n\n>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>")
    if apiVersion == lastApiVersion then
        if backupData[apiVersion] == nil then
            d(preVars.preChatTextRed .. "?> Restore of marked items not possible: Backup for specified API version "..tos(apiVersion) .." not found! <<<")
            return false
        end
    else
        if backupData[apiVersion] == nil and backupData[lastApiVersion] == nil then
            d(preVars.preChatTextRed .. "?> Restore of marked items not possible: Backup for current " .. tos(apiVersion) .. " or last API version " .. tos(lastApiVersion) .. " not found! <<<")
            return false
        end
    end

    d(preVars.preChatTextGreen .. ">>> Restore of marked items by the help of the unique IDs started >>>")
    if backupData[apiVersion] ~= nil then
        d(preVars.preChatTextGreen .. "!> Restoring backup of API version " ..tos(apiVersion))
        apiVersionToUse = apiVersion
    elseif backupData[lastApiVersion] ~= nil then
        d(preVars.preChatTextGreen .. "!> Restoring backup of last API version " .. tos(lastApiVersion))
        apiVersionToUse = lastApiVersion
    end
    --Check if the backupset got the needed data
    if not backupData or not backupData[apiVersionToUse] then
        d(preVars.preChatTextRed .. "?> Restore of marked items not possible: Backup for API version " .. tos(apiVersionToUse) .. " not found! <<<")
        return false
    end
    apiVersionToUse = tonumber(apiVersionToUse)

    --Check if current FCOIS uniqueId settings are the same as the backuped ones
    local uniqueIdZOsSettingsDifferFromBackup = false
    local uniqueIdParts = settings.uniqueIdParts
    local uniqueIdPartsOfBackup = backupData[apiVersionToUse].FCOISuniqueIdParts
    d(">Checking if your current FCOIS unique-Id settings (See \'General settings -> Unique ID -> Dropdown FCOIS unique and checkboxes below\') are matching the backuped data...")
    for uniqueIdPartName, uniqueIdPartValue in pairs(uniqueIdParts) do
        local uniqueIdPartsValueOfBackup = uniqueIdPartsOfBackup[uniqueIdPartName]
        if uniqueIdPartsValueOfBackup == nil then
            d(string.format(">!!!|cFF0000ERROR|r \'%s\' was not backuped, but current value at settings is: %s", tos(uniqueIdPartName), tos(uniqueIdPartValue)))
            uniqueIdZOsSettingsDifferFromBackup = true
        elseif uniqueIdPartsValueOfBackup ~= uniqueIdPartValue then
            d(string.format(">!!!|cFF0000ERROR|r \'%s\' was backuped with value %s, current value at settings is: %s", tos(uniqueIdPartName), tos(uniqueIdPartsValueOfBackup), tos(uniqueIdPartValue)))
            uniqueIdZOsSettingsDifferFromBackup = true
        end
    end
    if uniqueIdZOsSettingsDifferFromBackup == true then
        d("<ERROR Aborting the restore as the FCOIS uniuqe-ID settings do not match the backup. Please change your current FCOIS unique settings to the above noted backup-settings first to restore these marker icons properly!")
        return
    end

    --Get the marked items in the backup set of this bag
    local markedItemsInBackupSet, backupSetEntriesNonUnique, backupSetEntriesZOsUnique, backupSetEntriesFCOISUnique = getMarkedItemsInBackupSet(backupData[apiVersionToUse])
    d(string.format("!> Marked items in backup set total: %s -> non-unique: %s, ZOS unique: %s, FCOIS unique: %s", tos(markedItemsInBackupSet), tos(backupSetEntriesNonUnique), tos(backupSetEntriesZOsUnique),tos(backupSetEntriesFCOISUnique)))

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
    local isOwningAHouse = checkIfOwningHouse()
    local isInOwnHouse = checkIfInHouse() and checkIfIsOwnerOfHouse()
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
            d(preVars.preChatTextBlue .. "!> Starting restore of bag: \'" ..tos(bagStr) .. "\'")
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
                        --Get the item's ID types and check all against the backuped data
                        local nonUniqueId =     signItemId(GetItemInstanceId(bagId, slotIndex), nil, true, nil, bagId, slotIndex)
                        local zosUniqueId =     zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex))
                        local FCOISUniqueId =   createFCOISUniqueIdString(nil, bagId, slotIndex, nil)
                        local markerIconIdsToCheck = {
                            [false]                                         = nonUniqueId,
                            [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE]    = zosUniqueId,
                            [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE]  = FCOISUniqueId,
                        }
                        local firstFound = true
                        for idTypeIndex, markerIconItemIdToCheck in pairs(markerIconIdsToCheck) do
                            local itemIdMarkers = backupData[apiVersion][markerIconItemIdToCheck]
                            --Is the item in the backup data with this ID? Then retsore it
                            if itemIdMarkers ~= nil then
                                --Get the saved backup data of this item in the bag
                                --Get the icons from the backupDataSet
                                local iconsStr
                                local itemLink
                                if withDetails then
                                    iconsStr = ""
                                    itemLink = gil(bagId, slotIndex)
                                end
                                for iconId, isMarked in pairs(itemIdMarkers) do
                                    if isMarked == true and type(iconId) == "number" then
                                        --Mark the item again with all found icon markers
                                        FCOIS.MarkItem(bagId, slotIndex, iconId, true, false)
                                        if firstFound then
                                            foundMarkedMarkerIconsOnItems = foundMarkedMarkerIconsOnItems + 1
                                        end
                                        if withDetails then
                                            if iconsStr == "" then
                                                iconsStr = tos(iconId)
                                            else
                                                iconsStr = iconsStr .. "," .. tos(iconId)
                                            end
                                        end
                                    end
                                end
                                if withDetails then
                                    local idType = idTypeToName[idTypeIndex]
                                    d(strformat(">restored \'%s\' icons[%s] for %s", idType, iconsStr, itemLink))
                                end
                                if firstFound then
                                    --Increase the counter
                                    foundMarkedItems = foundMarkedItems + 1
                                    firstFound = false
                                end
                            end
                        end
                        foundItemsInBag = foundItemsInBag + 1
                    end
                end
                if not bagTypRestoreFailed then
                    d(preVars.preChatTextBlue .. "<! Finished restore of bag: \'" ..tos(bagStr) .. "\'.\n--->Re-Marked " .. tos(foundMarkedMarkerIconsOnItems) .. " icons on " .. tos(foundMarkedItems) .." items, of " .. tos(foundItemsInBag) .. " total items in bag")
                end
                d("====================")
                totalMarkedItems = totalMarkedItems + foundMarkedItems
                totalItems = totalItems + foundItemsInBag
            end
        end
    end
    d(string.format("!>> Marked items in backup set total: %s -> non-unique: %s, ZOS unique: %s, FCOIS unique: %s", tos(markedItemsInBackupSet), tos(backupSetEntriesNonUnique), tos(backupSetEntriesZOsUnique),tos(backupSetEntriesFCOISUnique)))
    d("!>>> Total re-marked/found items: " .. tos(totalMarkedItems) .. "/" .. tos(totalItems))
    d(preVars.preChatTextGreen .. "<<< Restore finished <<<")
    d("<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<")
end
local restoreMarkerIcons = FCOIS.RestoreMarkerIcons

--Stuff to do before restore can be started
function FCOIS.PreRestore(withDetails, apiVersion)
    restoreMarkerIcons(withDetails, apiVersion)
end

------------------------------------------------------------------------------------------------------------------------
-- DELETE BACKUP
------------------------------------------------------------------------------------------------------------------------
--[[
local function disableDeleteLAMButton()
    if FCOITEMSAVER_SETTINGS_DELETE_API_VERSION_BUTTON ~= nil and FCOITEMSAVER_SETTINGS_DELETE_API_VERSION_BUTTON.button ~= nil then
        FCOIS.restore.apiVersion = nil
        FCOITEMSAVER_SETTINGS_DELETE_API_VERSION_BUTTON.button:SetEnabled(false)
    end
end
]]

function FCOIS.DeleteBackup(apiVersionToDelete)
--d("[FCOIS.DeleteBackup]apiVersion: " ..tos(apiVersionToDelete))
    if apiVersionToDelete == nil then return false end
    local settings = FCOIS.settingsVars.settings
    local backupData = settings.backupData
    local preVars = FCOIS.preChatVars
    apiVersionToDelete = ton(apiVersionToDelete)
    --Is the backup existing which should be deleted?
    if backupData[apiVersionToDelete] == nil then
        d(preVars.preChatTextRed .. "?> Backup for specified API version "..tos(apiVersionToDelete) .." not found! <<<")
        --disableDeleteLAMButton()
        return false
    else
        --Delete the backup now
        FCOIS.settingsVars.settings.backupData[apiVersionToDelete] = nil
        d(preVars.preChatTextGreen .. "?> Backup for specified API version "..tos(apiVersionToDelete) .." was deleted! <<<")
        --Update the list of restorable backups now in the settings dropdown
        FCOIS.BuildRestoreAPIVersionData(true)
        --disableDeleteLAMButton()
        return true
    end
end


------------------------------------------------------------------------------------------------------------------------
-- DELETE MARKER ICONS
------------------------------------------------------------------------------------------------------------------------

function FCOIS.DeleteMarkerIcons(markerIconsToDeleteType, markerIconsToDeleteIcon)
    if markerIconsToDeleteType == nil or markerIconsToDeleteIcon == nil or markerIconsToDeleteIcon == 0 then return end
    local preVars = FCOIS.preChatVars
    locVars = FCOIS.localizationVars.fcois_loc
    local uniqueItemIdTypeChoices = locVars.uniqueItemIdTypeChoices
    local savedVarsMarkedItemsNames = FCOIS.addonVars.savedVarsMarkedItemsNames
    local allIcons = markerIconsToDeleteIcon == FCOIS_CON_ICON_ALL or false
    local iconStr = (allIcons == true and "All icons") or tos(markerIconsToDeleteIcon)

    local markerIconsToDeleteTypeTable = savedVarsMarkedItemsNames[markerIconsToDeleteType]
--d(">uniqueItemIdTypeChoices[markerIconsToDeleteType]: " ..tos(uniqueItemIdTypeChoices[markerIconsToDeleteType]))
--d(">locVars[options_non_unique_id]: " ..tos(locVars["options_non_unique_id"]))
--d(">uniqueItemIdTypeChoices[FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE]: " ..tos(uniqueItemIdTypeChoices[FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE]))
    local markerIconsToDeleteTypeStr = (type(markerIconsToDeleteType) == "number" and uniqueItemIdTypeChoices[markerIconsToDeleteType]) or (locVars["options_non_unique_id"] .. "/" .. uniqueItemIdTypeChoices[FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE])
    --Was the SV subTable name determined?
    if markerIconsToDeleteTypeTable == nil or markerIconsToDeleteTypeTable == "" then
        d(preVars.preChatTextRed .. "?> Marker icons \'" .. iconStr .. "\' SavedVariables table name for specified ID type \'"..tos(markerIconsToDeleteTypeStr) .."\' not found! <<<")
        return false
    end

    local showError = false
    --Is the marker icons subtable existing which should be deleted?
    if FCOIS.settingsVars.settings[markerIconsToDeleteTypeTable] == nil then
        showError = true
    end
    if not showError and not allIcons then
        if FCOIS.settingsVars.settings[markerIconsToDeleteTypeTable][markerIconsToDeleteIcon] == nil then
            showError = true
        end
    end
    if showError then
        d(preVars.preChatTextRed .. "?> Marker icons \'" .. iconStr .. "\'  for specified ID type \'"..tos(markerIconsToDeleteTypeStr) .."\' not found! <<<")
        return false
    end

    --Delete the marker icons subtable now
    local wasDeleted = false
    if allIcons == true then
        FCOIS.settingsVars.settings[markerIconsToDeleteTypeTable] = nil
        wasDeleted = true
    else
        if FCOIS.settingsVars.settings[markerIconsToDeleteTypeTable][markerIconsToDeleteIcon] ~= nil then
            FCOIS.settingsVars.settings[markerIconsToDeleteTypeTable][markerIconsToDeleteIcon] = nil
            wasDeleted = true
        end
    end
    if wasDeleted == true then
        d(preVars.preChatTextGreen .. "?> Marker icons \'" .. iconStr .. "\' for specified ID type \'"..tos(markerIconsToDeleteTypeStr) .."\' were deleted from SV subtable \'" .. tos(markerIconsToDeleteTypeTable) .. "\'! \nYour UI will be reloaded now to update the SavedVariables properly. <<<")
        --Reload the UI now
        ReloadUI("ingame")
        return true
    end
end
