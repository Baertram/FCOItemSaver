--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

local tos = tostring
local strformat = string.format
local strfind = string.find
local zo_strf = zo_strformat
local tabins = table.insert

--Currently logged in account name
local accName             = GetDisplayName()
local currentCharId       = GetCurrentCharacterId()

--The SavedVariables local name
local addonVars         = FCOIS.addonVars
local addonSVname       = addonVars.savedVarName
local addonSVversion    = addonVars.savedVarVersion
local checkVars = FCOIS.checkVars
local checksToDo = checkVars.autoReenableAntiSettingsCheckWheres
local checksAll = checkVars.autoReenableAntiSettingsCheckWheresAll

--The allAccounts the same account name
local svDefaultName         = FCOIS.svDefaultName
local svAccountWideName     = FCOIS.svAccountWideName
local svAllAccTheSameAcc    = FCOIS.svAllAccountsName
local svSettingsForAllName  = FCOIS.svSettingsForAllName
local svSettingsName        = FCOIS.svSettingsName
local svAllServersTheSame   = FCOIS.svServerAllTheSameName
local svSettingsForEachCharacterName = FCOIS.svSettingsForEachCharacterName

local gMappingVars = FCOIS.mappingVars
--local filterPanelToFilterButtonMediumOutputText = gMappingVars.filterPanelToFilterButtonMediumOutputText
local filterPanelToFilterButtonFilterActiveSettingName = gMappingVars.filterPanelToFilterButtonFilterActiveSettingName

local getFCOISMarkerIconSavedVariablesItemId = FCOIS.GetFCOISMarkerIconSavedVariablesItemId
local rebuildAllowedCraftSkillsForCraftedMarking = FCOIS.RebuildAllowedCraftSkillsForCraftedMarking
local getNumberOfFilteredItemsForEachPanel = FCOIS.GetNumberOfFilteredItemsForEachPanel
local getCurrentlyLoggedInCharUniqueId = FCOIS.GetCurrentlyLoggedInCharUniqueId

local getCharactersOfAccount = FCOIS.GetCharactersOfAccount
local getCharacterName = FCOIS.GetCharacterName
local showConfirmationDialog = FCOIS.ShowConfirmationDialog

local showContextMenuForAddInvButtons
local onContextMenuForAddInvButtonsButtonMouseUp

local onlyCallOnceInTime = FCOIS.OnlyCallOnceInTime
local isItemProtectedAtASlotNow
local autoReenableAntiSettingsCheck

--==========================================================================================================================================
-- 										FCOIS settings & saved variables functions
--==========================================================================================================================================
local function splitStringWithDelimiter(stringVar, delimiter)
    if not stringVar or not delimiter then return end
    local retTab = {}
    for part in stringVar:gmatch("([^" .. delimiter .."]+)") do
        tabins(retTab, part)
    end
    return retTab
end

function FCOIS.GetSavedVarsMarkedItemsTableName(override)
    local markedItemsNames = addonVars.savedVarsMarkedItemsNames
    if override ~= nil then
        return markedItemsNames[override]
    else
        local settings = FCOIS.settingsVars.settings
        if settings.useUniqueIds == true then
            return markedItemsNames[settings.uniqueItemIdType]
        else
            return markedItemsNames[false]
        end
    end
end
local getSavedVarsMarkedItemsTableName = FCOIS.GetSavedVarsMarkedItemsTableName

--Check if the FCOIS settings were loaded already, or load them
--If called from another addon the parameter calledFromExternal must be true!
--If called internally before the addon's event_add_on_loaded (via keybinds e.g.) the parameter calledBeforeEventAddOnLoaded must be true:
-->The settings will be using "default" values then (e.g. for the selected language etc.) as the SavedVariables table will be provided FIRST at EVENT_ADD_ON_LOADED!
function FCOIS.CheckIfFCOISSettingsWereLoaded(calledFromExternal, calledBeforeEventAddOnLoaded)
    calledFromExternal = calledFromExternal or false
    calledBeforeEventAddOnLoaded = calledBeforeEventAddOnLoaded or false
    local gCalledFromInternalFCOIS = FCOIS.preventerVars.gCalledFromInternalFCOIS
    --If the parameter says it was called from an external addon but the variable which says it was called from FCOIS internally is set,
    --or the parameter says it was not called from an external addon but no internal FCOIS variable was set at the function call
    -->Change the parameter
    if calledFromExternal == true and gCalledFromInternalFCOIS == true then
        calledFromExternal = false
    elseif calledFromExternal == false and not gCalledFromInternalFCOIS then
        calledFromExternal = true
    end
--d("[FCOIS]CheckIfFCOISSettingsWereLoaded - calledBeforeEventAddOnLoaded: " .. tos(calledBeforeEventAddOnLoaded) .. ", calledFromExternal: " ..tos(calledFromExternal) .. ", FCOISInternal: " ..tos(gCalledFromInternalFCOIS))
    --Reset the "internal call" variable again
    FCOIS.preventerVars.gCalledFromInternalFCOIS = false

    local doSettingsChecks = true
    if FCOIS.addonVars.gSettingsLoaded == true then
        if not calledFromExternal then doSettingsChecks = false end
    end
    if doSettingsChecks == true then
        local settingsVars = FCOIS.settingsVars
        local settings = settingsVars ~= nil and settingsVars.settings
        local isFCOISSettingsTableGiven = (settingsVars ~= nil and settings ~= nil) or false
        if isFCOISSettingsTableGiven then
            local savedVarsMarkedItemsTableName = getSavedVarsMarkedItemsTableName(nil)
            if settings[savedVarsMarkedItemsTableName] ~= nil then
--d("<settings already loaded!")
                return true
            end
        end
    else
--d("<settings checks not needed, as settings were already loaded!")
        return true
    end
--d(">loading settings now...")
    return FCOIS.LoadUserSettings(calledFromExternal, false)
end
local checkIfFCOISSettingsWereLoaded = FCOIS.CheckIfFCOISSettingsWereLoaded

local function NamesToIDSavedVars(serverWorldName)
    serverWorldName = serverWorldName or svDefaultName
    --Are the character settings enabled? If not abort here
    if FCOIS.settingsVars.defaultSettings.saveMode ~= 1 then return nil end
    --Did we move the character name settings to character ID settings already?
    if not FCOIS.settingsVars.settings.namesToIDSavedVars then
        local doMove
        local charName
        local displayName = accName
        --Check all the characters of the account
        for i = 1, GetNumCharacters() do
            local name, _, _, _, _, _, _ = GetCharacterInfo(i)
            charName = name
            charName = zo_strf(SI_UNIT_NAME, charName)
            --If the current logged in character was found
            if GetUnitName("player") == name and FCOItemSaver_Settings[serverWorldName][displayName][charName] then
                doMove = true
                break -- exit the loop
            end
        end
        --Move the settings from the old character name ones to the new character ID settings now
        if doMove then
            FCOIS.settingsVars.settings = FCOItemSaver_Settings[serverWorldName][displayName][charName]
            --Set a flag that the settings were moved
            FCOIS.settingsVars.settings.namesToIDSavedVars = true
        end
    end
end

--==============================================================================

--Returns either the account wide "for each character individually",
--or the normal character saved "for each character", settings
function FCOIS.GetAccountWideCharacterOrNormalCharacterSettings()
    local settingsForAll = FCOIS.settingsVars.defaultSettings
    local saveMode = settingsForAll.saveMode
--d("[FCOIS]getAccountWideCharacterOrNormalCharacterSettings - saveMode: " ..tos(saveMode) .. ", filterForEachCharacter: " ..tos(settingsForAll.filterButtonsSaveForCharacter))
    local settingsSV
    --Character SavedVariables
    if saveMode == 1 then
        settingsSV = FCOIS.settingsVars.settings
    else
        --Account wide and AllAccountsTheSame account wide SavedVariables
        --FilterButton states are saved account wide but for each character individually?
        if settingsForAll.filterButtonsSaveForCharacter == true then
            local settingsSVBase = FCOIS.settingsVars.accountWideButForEachCharacterSettings
            settingsSV = settingsSVBase ~= nil and settingsSVBase[currentCharId]
        else
            settingsSV = FCOIS.settingsVars.settings
        end
    end
    return settingsSV
end
local getAccountWideCharacterOrNormalCharacterSettings = FCOIS.GetAccountWideCharacterOrNormalCharacterSettings


--Check if the filterButton's state is on/off/FCOIS_CON_FILTER_BUTTON_STATE_YELLOW (Show only marked)
function FCOIS.GetSettingsIsFilterOn(p_filterId, p_filterPanel)
    local p_filterPanelNew = p_filterPanel or FCOIS.gFilterWhere
    local result
    local baseSettings = FCOIS.settingsVars.settings
    local settings = getAccountWideCharacterOrNormalCharacterSettings()

    --New behaviour with filters
    settings.isFilterPanelOn[p_filterPanelNew] = settings.isFilterPanelOn[p_filterPanelNew] or {}
    result = settings.isFilterPanelOn[p_filterPanelNew][p_filterId]
    if result == nil then
        return false
    end
    if baseSettings.debug then debugMessage( "[GetSettingsIsFilterOn]","Filter Panel: " .. tos(p_filterPanelNew) .. ", FilterId: " .. tos(p_filterId) .. ", Result: " .. tos(result), true, FCOIS_DEBUG_DEPTH_VERBOSE) end
    return result
end

--Set the value of a filter type, and return it
function FCOIS.SetSettingsIsFilterOn(p_filterId, p_value, p_filterPanel)
    local p_filterPanelNew = p_filterPanel or FCOIS.gFilterWhere
    local baseSettings = FCOIS.settingsVars.settings
    local settings = getAccountWideCharacterOrNormalCharacterSettings()
    --New behaviour with filters
    settings.isFilterPanelOn[p_filterPanelNew] = settings.isFilterPanelOn[p_filterPanelNew] or {}
    settings.isFilterPanelOn[p_filterPanelNew][p_filterId] = p_value
    if baseSettings.debug then debugMessage( "[SetSettingsIsFilterOn]","Filter Panel: " .. tos(p_filterPanelNew) .. ", FilterId: " .. tos(p_filterId) .. ", Value: " .. tos(p_value), true, FCOIS_DEBUG_DEPTH_VERBOSE) end
    --return the value
    return p_value
end

-- Check the settings for the panels and return if they are enabled or disabled (e.g. the filter buttons [filters])
-- If 2nd param onlyAnti == true: p_filterWhere will be used, and updated with the current filterPanelId, if it was nil
function FCOIS.GetFilterWhereBySettings(p_filterWhere, onlyAnti)
    p_filterWhere = p_filterWhere or FCOIS.gFilterWhere
    onlyAnti = onlyAnti or false

    local settingsAllowed = FCOIS.settingsVars.settings
    if onlyAnti == false then
        FCOIS.settingsVars.settings.atPanelEnabled = FCOIS.settingsVars.settings.atPanelEnabled or {}
        FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere] = FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere] or {}
        --FCOIS 2021-11-14 Get setting's Is filter allowed via mapping table filterPanelToFilterButtonFilterActiveSettingName
        --Set the resultVar and update the FCOIS.settingsVars.settings.atPanelEnabled array
        FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed[filterPanelToFilterButtonFilterActiveSettingName[p_filterWhere]]
    end

    if settingsAllowed.debug then debugMessage( "[getFilterWhereBySettings]", tos(p_filterWhere) .. " = " .. tos(settingsAllowed.atPanelEnabled[p_filterWhere]["filters"]), true, FCOIS_DEBUG_DEPTH_SPAM) end
    return p_filterWhere
end

--This function will change the actual ANTI-DETSROY etc. settings according to the active filter panel ID (inventory, vendor, mail, trade, bank, etc.)
function FCOIS.ChangeAntiSettingsAccordingToFilterPanel(suppressRemoveProtectedItemsFromSlots)
    local filterPanelId = FCOIS.gFilterWhere
    if filterPanelId == nil then return nil end
    isItemProtectedAtASlotNow = isItemProtectedAtASlotNow or FCOIS.IsItemProtectedAtASlotNow
    local parentPanel = FCOIS.gFilterWhereParent
--d("[FCOIS.changeAntiSettingsAccordingToFilterPanel - FilterPanel: " .. filterPanelId .. ", FilterPanelParent: " .. tos(parentPanel))

    local currentSettings = FCOIS.settingsVars.settings
    local filterPanelIdToBlockSettingName = FCOIS.mappingVars.filterPanelIdToBlockSettingName
    local isSettingEnabled
    local settingNameToChange
    --------------------------------------------------------------------------------------------------------------------
    --The anti-destroy settings will be always checked as there are panels like LF_GUILDBANK_DEPOSIT which use the anti-destroy
    --AND anti guild bank deposit if no rights to withdraw again settings.
    --The filterPanelIds which need to be checked for anti-destroy
    local filterPanelIdsCheckForAntiDestroy = checkVars.filterPanelIdsForAntiDestroy
    --Get the current FCOIS.settingsVars.settings state and inverse them
    --1st check if anti-destroy is given
    local isFilterPanelIdCheckForAntiDestroyNeeded = filterPanelIdsCheckForAntiDestroy[filterPanelId] or false
    if isFilterPanelIdCheckForAntiDestroyNeeded == true then
        settingNameToChange = "blockDestroying"
    else
        --If not anti-destroy: 2ndly check for others
        local filterPanelIdToBlockSettingNameData = filterPanelIdToBlockSettingName[filterPanelId]
        --Is there a "multi-table" for the filterPanelId (e.g. LF_CRAFTBAG with CraftBagExtended)
        if filterPanelIdToBlockSettingNameData ~= nil then
            if type(filterPanelIdToBlockSettingNameData) == "table" then
                --e.g. CraftBag + CraftBagExtended
                local callbackFunc = filterPanelIdToBlockSettingNameData.callbackFunc
                local filterPanelsToSettingsData = filterPanelIdToBlockSettingNameData.filterPanelToBlockSetting
                if filterPanelsToSettingsData ~= nil then
                    local goOn = callbackFunc(parentPanel, filterPanelId)
                    if goOn == true then
                        settingNameToChange = filterPanelsToSettingsData[filterPanelId]
                    end
                end
            else
                --Single filterPanelId
                settingNameToChange = filterPanelIdToBlockSettingNameData
            end
        end
    end
    --------------------------------------------------------------------------------------------------------------------
    if not settingNameToChange or settingNameToChange == "" then return end
    isSettingEnabled = not currentSettings[settingNameToChange]
    FCOIS.settingsVars.settings[settingNameToChange] = isSettingEnabled
    --------------------------------------------------------------------------------------------------------------------
--d(">settingNameToChange: " .. tos(settingNameToChange) .. ", isSettingEnabled: " ..tos(isSettingEnabled))
    --Check if the settings are enabled now and if any item is slotted in the deconstruction/improvement/extraction/refine/retrait slot
    --> Then remove the item from the slot again if it's protected again now
    if isSettingEnabled and not suppressRemoveProtectedItemsFromSlots then --#286
        isItemProtectedAtASlotNow(nil, nil, false, true)
    end
    return isSettingEnabled
end


local function doAutoReenableAntiSettingsCheck(checkWhere)
--d("[FCOIS]Only called once doAutoReenableAntiSettingsCheck-checkWhere: " ..tos(checkWhere))
    if checkWhere == nil or checkWhere == "" then return false end
    --Should all checks be done now?
    if checkWhere == checksAll then
        autoReenableAntiSettingsCheck = autoReenableAntiSettingsCheck or FCOIS.AutoReenableAntiSettingsCheck
        --Get the checks to do and run them all after each other
        for _, checkWhereNow in ipairs(checksToDo) do
            if checkWhereNow ~= checksAll then
                autoReenableAntiSettingsCheck(checkWhereNow)
            end
        end
        return true
    end
    local settings = FCOIS.settingsVars.settings
    --"CRAFTING_STATION"?
    if checkWhere == checksToDo[1]  then
        --Reenable the Anti-Refinement methods if activated in the settings
        if settings.autoReenable_blockRefinement then
            settings.blockRefinement = true
        end
        --Reenable the Anti-Deconstruction methods if activated in the settings
        if settings.autoReenable_blockDeconstruction then
            settings.blockDeconstruction = true
        end
        --Reenable the Anti-Improvement methods if activated in the settings
        if settings.autoReenable_blockImprovement then
            settings.blockImprovement = true
        end
        --Reenable the Anti-Jewelry Refinement methods if activated in the settings
        if settings.autoReenable_blockJewelryRefinement then
            settings.blockJewelryRefinement = true
        end
        --Reenable the Anti-Jewelry Deconstruction methods if activated in the settings
        if settings.autoReenable_blockJewelryDeconstruction then
            settings.blockJewelryDeconstruction = true
        end
        --Reenable the Anti-Jewelry Improvement methods if activated in the settings
        if settings.autoReenable_blockJewelryImprovement then
            settings.blockJewelryImprovement = true
        end
        --Reenable the Anti-Enchanting creation methods if activated in the settings
        if settings.autoReenable_blockEnchantingCreation then
            settings.blockEnchantingCreation = true
        end
        --Reenable the Anti-Enchanting extraction methods if activated in the settings
        if settings.autoReenable_blockEnchantingExtraction then
            settings.blockEnchantingExtraction = true
        end
        --Reenable the Anti-Alchemy creation methods if activated in the settings
        if settings.autoReenable_blockAlchemyDestroy then
            settings.blockAlchemyDestroy = true
        end

        --"STORE"
    elseif checkWhere == checksToDo[2] then
        --FCOIS version 1.6.0 disabled as not yet implemented settings in the settingsMenu for this
        --[[
                --Reenable the Anti-Buy methods if activated in the settings
                if settings.autoReenable_blockVendorBuy then
                    settings.blockVendorBuy = true
                end
        ]]
        --Reenable the Anti-Sell methods if activated in the settings
        if settings.autoReenable_blockSelling then
            settings.blockSelling = true
        end
        --FCOIS version 1.6.0 disabled as not yet implemented settings in the settingsMenu for this
        --[[
                --Reenable the Anti-Buyback methods if activated in the settings
                if settings.autoReenable_blockVendorBuyback then
                    settings.blockVendorBuyback = true
                end
                --Reenable the Anti-Repair methods if activated in the settings
                if settings.autoReenable_blockVendorRepair then
                    settings.blockVendorRepair = true
                end
        ]]
        --Reenable the Fence Anti-Sell methods if activated in the settings
        if settings.autoReenable_blockFenceSelling then
            settings.blockFence = true
        end
        --Reenable the Fence Anti-Laundering methods if activated in the settings
        if settings.autoReenable_blockLaunderSelling then
            settings.blockLaunder = true
        end
        --"GUILD_STORE"
    elseif checkWhere == checksToDo[3] then
        --Reenable the Anti-Sell methods if activated in the settings
        if settings.autoReenable_blockSellingGuildStore then
            settings.blockSellingGuildStore = true
        end
        --"DESTROY"
    elseif checkWhere == checksToDo[4] then
        --Reenable the Anti-Destroy methods if activated in the settings
        --but do not enable it as we come back to the inventory from a container loot scene
        if not FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory then
            if settings.autoReenable_blockDestroying then
                settings.blockDestroying = true
            end
        end
        FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory = false
        --"TRADE"
    elseif checkWhere == checksToDo[5] then
        --Reenable the Anti-Trade methods if activated in the settings
        if settings.autoReenable_blockTrading then
            settings.blockTrading = true
        end
        --"MAIL"
    elseif checkWhere == checksToDo[6] then
        --Reenable the Anti-Mail methods if activated in the settings
        if settings.autoReenable_blockSendingByMail then
            settings.blockSendingByMail = true
        end
        --"RETRAIT"
    elseif checkWhere == checksToDo[7] then
        --Reenable the Anti-Retrait methods if activated in the settings
        if settings.autoReenable_blockRetrait then
            settings.blockRetrait = true
        end
        --"GUILDBANK"
    elseif checkWhere == checksToDo[8] then
        --Reenable the Anti-guild bank deposit if no withdraw rights exists
        --but only if it was enabled as the guild bank was opened (as it cannot be changed as the guildbank is open).
        if FCOIS.preventerVars.blockGuildBankWithoutWithdrawAtGuildBankOpen == false then return end
        if settings.autoReenable_blockGuildBankWithoutWithdraw then
            settings.blockGuildBankWithoutWithdraw = true
        end
    end
    --Workaround to enable the correct additional inventory context menu invoker button color for the normal inventory again
    --as multiple panels are using the LF_INVENTORY flag (mail, trade, inventory, ...)
    FCOIS.ChangeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
end

--Function to reenable the Anti-* settings again at a given check panel automatically (if the panel closes e.g.)
function FCOIS.AutoReenableAntiSettingsCheck(checkWhere)
    autoReenableAntiSettingsCheck = autoReenableAntiSettingsCheck or FCOIS.AutoReenableAntiSettingsCheck
    --d("[FCOIS.AutoReenableAntiSettingsCheck - checkWhere: " .. tos(checkWhere) .. ", filterPanel: " .. tos(FCOIS.gFilterWhere) .. ", lootListIsHidden: " .. tos(ZO_LootAlphaContainerList:IsHidden()) .. ", dontAutoReenableAntiSettings: " .. tos(FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory))

    --If mail send panel was opened the call order will be:
    --fcois_hooks -> 1. 1552 resetInventoryAntiSettings , 2. 1566 changeContextMenuInvokerButtonColorByPanelId, 3. 912 ctrlVars.mainMenuCategoryBar:OnShow autoReenableAntiSettingsCheck
    --As the button for the invenory, mail, player2player trade is physically the same it willupdate the button's color wrong according to anti-destroy instead of
    --anti-mail settings then! So the call to autoReenableAntiSettingsCheck cannot be done here anymore, except if autoReenableAntiSettingsCheck
    --would check if any panel (FCOIS.gFilterWhere) is shown which got the same "flag" button name as the LF_INVENTORY does
    local goOn = true
    local flagButtonNames = FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker
    local filterPanelId = FCOIS.gFilterWhere
    local currentPanelsFlagButton
    if filterPanelId ~= LF_INVENTORY then
        local inventoryFlagButton = flagButtonNames[LF_INVENTORY]
        currentPanelsFlagButton = flagButtonNames[filterPanelId]
        if currentPanelsFlagButton ~= nil and inventoryFlagButton.name == currentPanelsFlagButton.name then
            goOn = false
        end
    else
        currentPanelsFlagButton = flagButtonNames[LF_INVENTORY].name
    end
    if not goOn then return end
    --Only call once for the same checkWere (e.g. DESTROY) and ButtonName and FilterPanel within 50ms
    onlyCallOnceInTime("FCOIS_AutoReenableAntiSettingsCheck_" .. tos(checkWhere) .. "_" .. tos(filterPanelId) .. "_" .. tos(currentPanelsFlagButton), 50, doAutoReenableAntiSettingsCheck, checkWhere)
end
autoReenableAntiSettingsCheck = FCOIS.AutoReenableAntiSettingsCheck

--Function to reset the ANTI settings for the normal inventory
function FCOIS.ResetInventoryAntiSettings(currentSceneState)
    if currentSceneState == SCENE_SHOWING then
        autoReenableAntiSettingsCheck("DESTROY")
    elseif currentSceneState == SCENE_HIDDEN then
        if FCOIS.gFilterWhere == LF_RETRAIT then
            autoReenableAntiSettingsCheck("RETRAIT")
        end
    end
end

--==========================================================================================================================================
-- 															Scan and transfer / migrate
--==========================================================================================================================================

function FCOIS.ShowMigrationDebugLog()
    local settings = FCOIS.settingsVars.settings
    local migrationDebugLog = settings.migrationDebugLog
    if not migrationDebugLog or #migrationDebugLog == 0 then
        settings.migrationDebugLog = nil
        return
    end
    for _, textLine in ipairs(migrationDebugLog) do
        d(textLine)
    end
    settings.migrationDebugLog = nil
end

local function addToMigrationDebugLog(init, debugLogTextLine)
    init = init or false
    local settings = FCOIS.settingsVars.settings
    if init == true then
        settings.migrationDebugLog = {}
    end
    local migrationDebugLog = settings.migrationDebugLog
    tabins(migrationDebugLog, debugLogTextLine)
end

--Transfer the non-unique/unique to unique/non-unique marker icons at the items
--> Started by the button in the FCOIS_SettingsMenu.lua, "General settings",
--> or via the dialog FCOIS_ASK_BEFORE_MIGRATE_DIALOG after a reloadui was done and the uniqueIds were enabled
local function scanBagsAndTransferMarkerIcon(toUnique)
    if toUnique == nil then return end
    local preChatVars = FCOIS.preChatVars

    --Are the FCOIS settings already loaded?
    checkIfFCOISSettingsWereLoaded(false, not addonVars.gAddonLoaded)
    local settings = FCOIS.settingsVars.settings
    local locVars = FCOIS.localizationVars.fcois_loc
    local migrationDebugLogLine = "///~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\\\\n"..preChatVars.preChatTextGreen .. zo_strf(locVars["options_migrate_start"], "->UniqueId: " ..tos(toUnique))
    d(migrationDebugLogLine)
    addToMigrationDebugLog(true, migrationDebugLogLine)

------------------------------------------------------------------------------------------------------------------------
    --The SavedVariables table name e.g. markedItems or markedItemsFCOISUnique
    local savedVarsMarkedItemsTableNameOld
    local savedVarsMarkedItemsTableNameNew
    local uniqueIdWasLastEnabled    = settings.lastUsedUniqueIdEnabled
    local uniqueIdTypeLastUsed      = settings.lastUsedUniqueIdType

    local useUniqueIds = settings.useUniqueIds
    local uniqueItemIdType = settings.uniqueItemIdType

    if uniqueIdWasLastEnabled == nil then
        --Unknown state of useUniqueId before reloadui -> Abort
        migrationDebugLogLine = preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "ERROR - Unknown state of useUniqueId before reloadui")
        d(migrationDebugLogLine)
        addToMigrationDebugLog(false, migrationDebugLogLine)
        return
    else
        if uniqueIdTypeLastUsed == nil then
            --Unknown state of uniqueItemIdType before reloadui -> Abort
            migrationDebugLogLine = preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "ERROR - Unknown state of chosen uniqueIdType before reloadui")
            d(migrationDebugLogLine)
            addToMigrationDebugLog(false, migrationDebugLogLine)
            return
        end
    end

    --Migrate to uniqueId (FCOISuniqueIds->ZOs uniqueIds / ZOsUniqueIds->FCOISuniqueIds / non-unique to ZOs unique / non-unique to FCOISunique
    if toUnique == true then
        if not useUniqueIds or uniqueItemIdType == nil then
            --Non-unique ID enabled -> Abort
            migrationDebugLogLine = preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "ERROR - Migration to uniqueId not possible if currently non-unique ID is enabled in the settings")
            d(migrationDebugLogLine)
            addToMigrationDebugLog(false, migrationDebugLogLine)
            return
        end

        --Was the uniqueID enabled before the migration? Migrating unique to unique then
        if uniqueIdWasLastEnabled == true then
            --Migrate from uniqueId to uniqueId: Check if the last used uniqueId type is not the same as now
            if uniqueIdTypeLastUsed ~= uniqueItemIdType then
                migrationDebugLogLine = preChatVars.preChatTextBlue .. strformat(locVars["options_migrate_uniqueId_to_uniqueId"], tos(uniqueIdTypeLastUsed), tos(uniqueItemIdType))
                d(migrationDebugLogLine)
                addToMigrationDebugLog(false, migrationDebugLogLine)
                --Get the old "from" SavedVariables table name -> non-unique entry
                savedVarsMarkedItemsTableNameOld = getSavedVarsMarkedItemsTableName(uniqueIdTypeLastUsed)
            else
                --Last used type was the same uniqueId type. No migration needed -> Abort
                migrationDebugLogLine = preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "No migration needed - Last used type was the same uniqueId type")
                d(migrationDebugLogLine)
                addToMigrationDebugLog(false, migrationDebugLogLine)
                return
            end
        --UniqueId was not enabled before. Migrating non-unique to unique
        else
            migrationDebugLogLine = preChatVars.preChatTextBlue .. strformat(locVars["options_migrate_non_uniqueId_to_uniqueId"], tos(uniqueItemIdType))
            d(migrationDebugLogLine)
            addToMigrationDebugLog(false, migrationDebugLogLine)
            --Get the old "from" SavedVariables table name -> non-unique entry
            savedVarsMarkedItemsTableNameOld = getSavedVarsMarkedItemsTableName(false)
        end

        --Migrate to SavedVariables NEW -> unique type from current settings
        savedVarsMarkedItemsTableNameNew = getSavedVarsMarkedItemsTableName(settings.uniqueItemIdType)

    --Migrate to non-uniqueId (FCOISuniqueIds->non-unique / ZOsUniqueIds->non-unique)
    else
        if useUniqueIds == true then
            --Unique ID enabled -> Abort
            migrationDebugLogLine =  preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "ERROR - Migration to non-uniqueId not possible if currently unique ID is enabled in the settings")
            d(migrationDebugLogLine)
            addToMigrationDebugLog(false, migrationDebugLogLine)
            return
        end

        --Was the uniqueID enabled before the migration? Migrating unique to non-unique then
        if uniqueIdWasLastEnabled == true then
            migrationDebugLogLine = preChatVars.preChatTextBlue .. strformat(locVars["options_migrate_uniqueId_to_non_uniqueId"], tos(uniqueIdTypeLastUsed))
            d(migrationDebugLogLine)
            addToMigrationDebugLog(false, migrationDebugLogLine)
            --Get the old "from" SavedVariables table name -> non-unique entry
            savedVarsMarkedItemsTableNameOld = getSavedVarsMarkedItemsTableName(uniqueIdTypeLastUsed)
        --UniqueId was not enabled before. Migrating non-unique to non-unique
        else
            --Last used type was the same non-uniqueId type. No migration needed -> Abort
            migrationDebugLogLine = preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "No migration needed - Last used was also non-unique ID")
            d(migrationDebugLogLine)
            addToMigrationDebugLog(false, migrationDebugLogLine)
            return
        end

        --Migrate to SavedVariables NEW -> Non-unique
        savedVarsMarkedItemsTableNameNew = getSavedVarsMarkedItemsTableName(false)
    end
    if not savedVarsMarkedItemsTableNameOld then
        migrationDebugLogLine = preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "ERROR - Last used SavedVariables table unknown")
        d(migrationDebugLogLine)
        addToMigrationDebugLog(false, migrationDebugLogLine)
        return
    end
    if not savedVarsMarkedItemsTableNameNew then
        migrationDebugLogLine = preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], "ERROR - New SavedVariables table unknown")
        d(migrationDebugLogLine)
        addToMigrationDebugLog(false, migrationDebugLogLine)
        return
    end
------------------------------------------------------------------------------------------------------------------------
    --Check the bag
    local bagsToCheck = {
        BAG_WORN,
        BAG_COMPANION_WORN,
        BAG_BACKPACK,
        BAG_BANK,
        BAG_GUILDBANK,
    }
    --Is the user an ESO+ subscriber?
    if IsESOPlusSubscriber() then
        --Add the subscriber bank to the inventories to check
        if GetBagUseableSize(BAG_SUBSCRIBER_BANK) > 0 then
            tabins(bagsToCheck, 5, BAG_SUBSCRIBER_BANK)
        end
    end

    --Loop over all bag types
    local numMigratedIcons = 0
    local numMigratedItems = 0
    for _, bagToCheck in pairs(bagsToCheck) do
        --Migration started for bag type
        migrationDebugLogLine = ">>>-------------------->>>" .. preChatVars.preChatTextGreen .. zo_strf(locVars["options_migrate_start"], locVars["options_migrate_bag_type_" .. bagToCheck])
        d(migrationDebugLogLine)
        addToMigrationDebugLog(false, migrationDebugLogLine)
        --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
        local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
        --Loop over the bag items and check each item in the bag for marker icons
        for _, data in pairs(bagCache) do
            local itemId
            local itemIdNew
            local bagId, slotIndex = data.bagId, data.slotIndex
            local allowedItemType
            local allowedItemTypeNew
------------------------------------------------------------------------------------------------------------------------
            --Transfer marker icon to unique ID
            if toUnique == true then
                --Build the itemID -> FROM
                -->Could be a uniqueId or a non-unique itemInstanceId
                itemId, allowedItemType = getFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, nil, uniqueIdWasLastEnabled, uniqueIdTypeLastUsed, nil)
                --[[
                if uniqueIdWasLastEnabled == true then
                    --UniqueId -> FROM
                    if allowedItemType == true then
                        --Check which uniqueId type is currently setup in the FCOIS settings
                        if not uniqueIdTypeLastUsed or uniqueIdTypeLastUsed == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then
                            itemId = zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex))
                        elseif uniqueIdTypeLastUsed and uniqueIdTypeLastUsed == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE then
                            local itemIdForUniqueId = GetItemId(bagId, slotIndex)
                            itemId = FCOIS.CreateFCOISUniqueIdString(itemIdForUniqueId, nil, bagId, slotIndex, nil)
                        end
                    else
                        --Non supported itemTypes will use the normal itemInstanceId
                        itemId = itemInstanceIdSigned
                    end
                else
                    --Non-uniqueId -> FROM
                    itemId = itemInstanceIdSigned
                end
                ]]
                --Build the newItemId -> TO
                itemIdNew, allowedItemTypeNew = getFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, nil, useUniqueIds, uniqueItemIdType, nil)
--d(">itemId: " ..tos(itemId)..", allowedItemType: " .. tos(allowedItemType) .. " - itemIdNew: " ..tos(itemIdNew)..", allowedItemTypeNew: " .. tos(allowedItemTypeNew))
                --[[
                if allowedItemType == true then
                    --Check which uniqueId type is currently setup in the FCOIS settings
                    if not uniqueItemIdType or uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then
                        itemIdNew = zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex))
                    elseif uniqueItemIdType and uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE then
                        local itemIdForUniqueId = GetItemId(bagId, slotIndex)
                        itemIdNew = FCOIS.CreateFCOISUniqueIdString(itemIdForUniqueId, nil, bagId, slotIndex, nil)
                    end
                else
                    --Non supported itemTypes will use the normal itemInstanceId
                    itemIdNew = itemInstanceIdSigned
                end
                ]]

------------------------------------------------------------------------------------------------------------------------
            --Transfer marker icon to non-unique ID
            else
                --Build the itemID -> FROM
                -->Could be only a non-unique itemInstanceId
                itemId, allowedItemType = getFCOISMarkerIconSavedVariablesItemId(bagId, slotIndex, nil, uniqueIdWasLastEnabled, uniqueIdTypeLastUsed)
                --[[
                if allowedItemType == true then
                    if not uniqueIdTypeLastUsed or uniqueIdTypeLastUsed == FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then
                        itemId = zo_getSafeId64Key(GetItemUniqueId(bagId, slotIndex))
                    elseif uniqueIdTypeLastUsed and uniqueIdTypeLastUsed == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE then
                        local itemIdForUniqueId = GetItemId(bagId, slotIndex)
                        itemId = FCOIS.CreateFCOISUniqueIdString(itemIdForUniqueId, nil, bagId, slotIndex, nil)
                    end
                else
                    itemId = itemInstanceIdSigned
                end
                ]]
                --Build the newItemId -> TO
                --Non uniqueId -> TO
                local itemInstanceId = GetItemInstanceId(bagId, slotIndex)
                local itemInstanceIdSigned = FCOIS.SignItemId(itemInstanceId, false, true, nil, bagId, slotIndex)
                itemIdNew = itemInstanceIdSigned
            end
------------------------------------------------------------------------------------------------------------------------

            --Is the itemId FROM and TO given?
            -->Both IDs do not need to be different as the migration could use different SavedVariables subtables,
            -->e.g. for nonUniqueIds "markedItems" and for uniqueIDsFCOIS the table "markedItemsFCOISUnique"
            if itemId ~= nil and itemIdNew ~= nil then
                local increaseNumMigratedItems = true
                local markedItemsVarOld = FCOIS.settingsVars.settings[savedVarsMarkedItemsTableNameOld]
                --Check if the item is marked with any icon
                for iconId = FCOIS_CON_ICON_LOCK, FCOIS.numVars.gFCONumFilterIcons, 1 do
                    local isMarked = markedItemsVarOld[iconId][itemId]
                    if isMarked == nil then isMarked = false end
                    --Is the icon marked?
                    if isMarked == true then
                        --Transfer the marker icon from the old one to the new one
                        FCOIS.settingsVars.settings[savedVarsMarkedItemsTableNameNew][iconId] = FCOIS.settingsVars.settings[savedVarsMarkedItemsTableNameNew][iconId] or {}
                        FCOIS.settingsVars.settings[savedVarsMarkedItemsTableNameNew][iconId][itemIdNew] = true
                        numMigratedIcons = numMigratedIcons + 1
                        if increaseNumMigratedItems then
                            numMigratedItems = numMigratedItems + 1
                            increaseNumMigratedItems = false
                        end
                    end
                end
            end
        end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
        --Migration results for bag type
        migrationDebugLogLine = preChatVars.preChatTextBlue .. zo_strf(locVars["options_migrate_results"], numMigratedIcons, numMigratedItems)
        d(migrationDebugLogLine)
        addToMigrationDebugLog(false, migrationDebugLogLine)
        --Migration end for bag type
        migrationDebugLogLine = "==============================" .. preChatVars.preChatTextRed .. zo_strf(locVars["options_migrate_end"], locVars["options_migrate_bag_type_" .. bagToCheck])
        d(migrationDebugLogLine)
        addToMigrationDebugLog(false, migrationDebugLogLine)
    end -- for bagType
    --Reset the "migration needs to be done" variable
    FCOIS.preventerVars.migrateItemMarkers = false

    return numMigratedItems
end

--Migrate the marker icons from the non-unique ItemInstanceIds to the uniqueIds
function FCOIS.MigrateMarkerIcons()
    local prevVars = FCOIS.preventerVars
    local settings = FCOIS.settingsVars.settings
    local itemsMigrated
    if prevVars.migrateToUniqueIds == true or settings.useUniqueIds == true then
        itemsMigrated = scanBagsAndTransferMarkerIcon(true)
    elseif prevVars.migrateToItemInstanceIds == true or settings.useUniqueIds == false then
        itemsMigrated = scanBagsAndTransferMarkerIcon(false)
    end
    --Reset some variables
    FCOIS.preventerVars.migrateItemMarkers = false
    FCOIS.preventerVars.migrateToUniqueIds = false
    FCOIS.preventerVars.migrateToItemInstanceIds = false

    --Reload the UI to update all settings table properly
    if itemsMigrated ~= nil and itemsMigrated > 0 then
        local locVars = FCOIS.localizationVars.fcois_loc
        local reloadUIText = FCOIS.preChatVars.preChatTextRed .. " " .. strformat(locVars["reloadui"], "3")
        d(reloadUIText)
        ZO_Alert(UI_ALERT_CATEGORY_ALERT, SOUNDS.LOCKPICKING_CHAMBER_STRESS, reloadUIText)
        zo_callLater(function() ReloadUI("ingame")  end, 3000)
    else
        settings.migrationDebugLog = nil
    end
end


--==========================================================================================================================================
-- 															FCOIS USER-SETTINGS (SavedVars)
--==========================================================================================================================================

--Do some "before settings" stuff
function FCOIS.BeforeSettings()

end

--Do some "after settings" stuff
function FCOIS.AfterSettings()
    showContextMenuForAddInvButtons = showContextMenuForAddInvButtons or FCOIS.ShowContextMenuForAddInvButtons
    onContextMenuForAddInvButtonsButtonMouseUp = onContextMenuForAddInvButtonsButtonMouseUp or FCOIS.OnContextMenuForAddInvButtonsButtonMouseUp

    local settings = FCOIS.settingsVars.settings
    local numLibFiltersFilterPanelIds = FCOIS.numVars.gFCONumFilterInventoryTypes
    local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
    local icon2Dynamic = FCOIS.mappingVars.iconToDynamic
    local iconIsDynamic = FCOIS.mappingVars.iconIsDynamic
    local mappingVars = FCOIS.mappingVars
    local ctrlVars = FCOIS.ZOControlVars

    --Set the split filters to nil as it was removed years ago!
    settings.splitFilters = nil

    --FCOIS v1.9.6 UniqueId changes to real unique by ZOs (ESO standard) or FCOIS unique (self made)
    --Standard value: Really unique by ZOs
    if settings.uniqueItemIdType == nil then settings.uniqueItemIdType = FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE end

    --Introduced with FCOIS version 1.5.2: Dynamic icons global settings slider to set dynamic icons max total count enabled.
    --Check if the current value of the settings slider was set due to an update of the addon and check if the user was using more than the
    --default value of the enabled dynamic icons already: If so set the slider to the users max value so his dyn icons are all enabled
    --Set the value from the settings to the global constant now:
    FCOIS.numVars.gFCONumDynamicIcons = settings.numMaxDynamicIconsUsable
    --Did the addon update and the max usable dyn. icons slider was introduced?
    if settings.addonFCOISChangedDynIconMaxUsableSlider == nil then
        FCOIS.settingsVars.settings.addonFCOISChangedDynIconMaxUsableSlider = true
    end
    local maxUsableDynIconNr = 0
    if settings.addonFCOISChangedDynIconMaxUsableSlider == true then
        --Check if the user got more dyn. icons enabled as the current value of the usable dyn. icons is set (standard value is: 10)
        --Loop over iconsEnabled in settings and check if the number of dynIcons is > then the currently total usable number
        --local firstDynIconNr = FCOIS.numVars.gFCONumNonDynamicAndGearIcons + 1 --Start at icon# 13 = Dyn. icon #1
        for iconNr, isEnabled in ipairs(settings.isIconEnabled) do
            if isEnabled == true then
                local dynamicIconNr = icon2Dynamic[iconNr]
                if dynamicIconNr ~= nil then
                    if maxUsableDynIconNr < dynamicIconNr then
                        maxUsableDynIconNr = dynamicIconNr
                    end
                end
            end
        end
        --Fallback
        if maxUsableDynIconNr == nil then
            maxUsableDynIconNr = 10
        end
        if maxUsableDynIconNr > 0 then
            --Update the global variable with the current number of usable dyn. icons from the settings
            FCOIS.settingsVars.settings.numMaxDynamicIconsUsable    = maxUsableDynIconNr
            FCOIS.numVars.gFCONumDynamicIcons                       = maxUsableDynIconNr
        end
    end
    --Reset the settings value to false so the checks won't be done on next change again!
    if settings.addonFCOISChangedDynIconMaxUsableSlider == true then
        FCOIS.settingsVars.settings.addonFCOISChangedDynIconMaxUsableSlider = false
    end

    --FCOIS v2.4.5 If the "max dynamic icons" slider was changed and a reloadUI took place:
    --Check if the dynmic icon disabled is still enabled at the marker icons and disable them
    if settings.numMaxDynamicIconsUsable > 0 then
        for iconNr, isEnabled in ipairs(settings.isIconEnabled) do
            if isEnabled == true then
                local dynamicIconNr = icon2Dynamic[iconNr]
                if dynamicIconNr ~= nil then
                    if dynamicIconNr > settings.numMaxDynamicIconsUsable then
                        d("[FCOIS-SettingsMenu]Automatically disabled dynamic icon #" .. tos(dynamicIconNr) .. " (iconNr: " .. tos(iconNr) .. "), as the slider numMaxDynamicIconsUsable prohibits it!")
                        FCOIS.settingsVars.settings.isIconEnabled[iconNr] = false
                    end
                end
            end
        end
    end

    --FCOIS v1.8.0
    --Check if the currently set value of "show dynamic icons in submenus if enabled number of dynamic icons is > then x" is above the
    --value of total enabled dynamic icons (currently set maximum usable dynamicIcons via the slider in the marker icons->dynamic settings).
    --if so: Set it to the curerntly maximum enabled dynamic icons
    if settings.useDynSubMenuMaxCount > 0 and settings.numMaxDynamicIconsUsable > 0 then
        if settings.useDynSubMenuMaxCount > settings.numMaxDynamicIconsUsable then
            settings.useDynSubMenuMaxCount = settings.numMaxDynamicIconsUsable
        end
    end

    --FCOIS 2.1.3 - Fix for missing default settings at Companion Inventory
    if FCOIS.settingsVars.defaults.FCOISAdditionalInventoriesButtonOffset[LF_INVENTORY_COMPANION] == nil or
            ( FCOIS.settingsVars.defaults.FCOISAdditionalInventoriesButtonOffset[LF_INVENTORY_COMPANION] ~= nil and
                    (FCOIS.settingsVars.defaults.FCOISAdditionalInventoriesButtonOffset[LF_INVENTORY_COMPANION].top == nil or
                            FCOIS.settingsVars.defaults.FCOISAdditionalInventoriesButtonOffset[LF_INVENTORY_COMPANION].left == nil)) then
        FCOIS.settingsVars.defaults.FCOISAdditionalInventoriesButtonOffset[LF_INVENTORY_COMPANION] = {
            ["top"] = 0,
            ["left"] = 0,
        }
    end

    --Build the additional inventory "flag" context menu button data, which depends on the here before set values
    --FCOIS.numVars.gFCONumDynamicIcons and FCOIS.settingsVars.settings.numMaxDynamicIconsUsable
    --> See file src/FCOIS_ContextMenus.lua, function FCOIS.buildAdditionalInventoryFlagContextMenuData(calledFromFCOISSettings)
    FCOIS.BuildAdditionalInventoryFlagContextMenuData(true)

    --Preset global variable for item destroying
    FCOIS.preventerVars.gAllowDestroyItem = not settings.blockDestroying
    local savedVarsMarkedItemsTableName = getSavedVarsMarkedItemsTableName()

    -- Get the marked items for each filter from the settings (or defaults, if not set yet)
    for filterIconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        -->FCOIS v1.9.6 - Remove old entries with FCOIS[getSavedVarsMarkedItemsTableName()][filterIconId][itemIdOrUniqueIdString] = false from SV
        for itemOrUniqueId, isMarked in pairs(settings[savedVarsMarkedItemsTableName][filterIconId]) do
            if itemOrUniqueId ~= nil and isMarked == false then
                FCOIS.settingsVars.settings[savedVarsMarkedItemsTableName][filterIconId][itemOrUniqueId] = nil
            end
        end
        -->Link FCOIS[getSavedVarsMarkedItemsTableName()] to the SavedVariables
        FCOIS[savedVarsMarkedItemsTableName][filterIconId] = settings[savedVarsMarkedItemsTableName][filterIconId]
    end
    --The automatic set marker icon name was changed from autoMarkSetsGearIconNr to autoMarkSetsIconNr
    if settings.autoMarkSetsGearIconNr ~= nil then
        settings.autoMarkSetsIconNr = settings.autoMarkSetsGearIconNr
        FCOIS.settingsVars.defaults.autoMarkSetsGearIconNr = nil
        settings.autoMarkSetsGearIconNr = nil
    end
    --Added with FCOIS 1.0.0
    --Is the item ID save method changed from itemInstanceID to itemUniqueID?
    settings.doNotScanInv = nil
    FCOIS.preventerVars.doNotScanInv = false
    FCOIS.preventerVars.migrateItemMarkers = false
    if settings.useUniqueIdsToggle ~= nil then
        --Set the settings to use unique IDs, or non-unique IDs. If nothing was chosen in the settings the defaultSettings value "false" (non-unique) will be used.
        settings.useUniqueIds = settings.useUniqueIdsToggle
        FCOIS.preventerVars.doNotScanInv = true
        FCOIS.preventerVars.migrateItemMarkers = true
    end
    --Reset the toggle for the unique/non-unique settings menu toggle
    -->See file src/FCOIS_Functions.lua
    settings.useUniqueIdsToggle = nil

    --Set the variables for each panel where the number of filtered items can be found for the current inventory
    getNumberOfFilteredItemsForEachPanel()

    --The crafting station creation panel controls or a function to check if it's currently active
    local craftingCreationPanel = ctrlVars.CRAFTING_CREATION_PANEL
    FCOIS.craftingCreatePanelControlsOrFunction = {
        [CRAFTING_TYPE_ALCHEMY]         = FCOIS.IsAlchemyPanelCreationShown,
        [CRAFTING_TYPE_BLACKSMITHING] 	= craftingCreationPanel,
        [CRAFTING_TYPE_CLOTHIER] 		= craftingCreationPanel,
        [CRAFTING_TYPE_ENCHANTING] 		= FCOIS.IsEnchantingPanelCreationShown,
        [CRAFTING_TYPE_INVALID] 		= craftingCreationPanel,
        [CRAFTING_TYPE_PROVISIONING] 	= ctrlVars.PROVISIONER_PANEL,
        [CRAFTING_TYPE_WOODWORKING] 	= craftingCreationPanel,
        [CRAFTING_TYPE_JEWELRYCRAFTING]	= craftingCreationPanel,
    }

    --Rebuild the allowed craft skills from the settings
    rebuildAllowedCraftSkillsForCraftedMarking()

    --Added with FCOIS v1.6.7
    --Check if the values at the add. inv. context menu "flag" button offsets are properly set, or
    --reset them
    local apiVersion = FCOIS.APIversion
    local addInvButtonOffsets = settings.FCOISAdditionalInventoriesButtonOffset
    local anchorVarsAddInvButtons = FCOIS.anchorVars.additionalInventoryFlagButton[apiVersion]
    FCOIS.settingsVars.settings.FCOISAdditionalInventoriesButtonOffset["left"] = nil --remove wrong added values -> left and top should be in a subtable of filterPanelId!
    FCOIS.settingsVars.settings.FCOISAdditionalInventoriesButtonOffset["top"] = nil --remove wrong added values -> left and top should be in a subtable of filterPanelId!
    --Loop over the anchorVars and get each panel of the additional inv buttons (e.g. LF_INVENTORY, LF_BANK_WITHDRAW, ...)
    local function fixAnchorVarsLeftAndTopOffsets(p_addInvButtonOffsetsForPanel, p_panelId)
        if p_addInvButtonOffsetsForPanel["left"] == "" or type(p_addInvButtonOffsetsForPanel["left"]) == "string" or tonumber(p_addInvButtonOffsetsForPanel["left"]) == nil then
            FCOIS.settingsVars.settings.FCOISAdditionalInventoriesButtonOffset[p_panelId]["left"] = 0
            --d("[FCOIS]fixAnchorVarsLeftAndTopOffsets-left-filterPanel: " ..tos(p_panelId) .. ", current: " .. tos(p_addInvButtonOffsetsForPanel["top"]) .. "->reset to 0!")
        end
        if p_addInvButtonOffsetsForPanel["top"] == "" or type(p_addInvButtonOffsetsForPanel["top"]) == "string" or tonumber(p_addInvButtonOffsetsForPanel["top"]) == nil then
            --[[ For debugging -- FCOIS v2.4.9
                d("[FCOIS]fixAnchorVarsLeftAndTopOffsets-top-filterPanel: " ..tos(p_panelId) .. ", current: " .. tos(p_addInvButtonOffsetsForPanel["top"]) .. "->reset to 0!")
                if p_addInvButtonOffsetsForPanel["top"] == "" then
                    d(">empty string")
                end
                if type(p_addInvButtonOffsetsForPanel["top"]) == "string" then
                    d(">string detected")
                end
                if tonumber(p_addInvButtonOffsetsForPanel["top"]) == nil then
                    d(">no number")
                end
                ]]
            FCOIS.settingsVars.settings.FCOISAdditionalInventoriesButtonOffset[p_panelId]["top"] = 0
        end
    end
    if anchorVarsAddInvButtons then
        for panelId, _ in pairs(anchorVarsAddInvButtons) do
            local addInvButtonOffsetsForPanel = addInvButtonOffsets[panelId]
            if addInvButtonOffsetsForPanel then
                fixAnchorVarsLeftAndTopOffsets(addInvButtonOffsetsForPanel, panelId)
            end

            --FCOIS.ReAnchorAdditionalInvButtons(panelId)
        end
        --1 extra call to LF_ENCHANTING_EXTRACTION as it is not added to FCOIS.anchorVars.additionalInventoryFlagButton[apiVersion], because it re-usess LF_ENCHANTING_CREATION
        local addInvButtonOffsetsForPanel = addInvButtonOffsets[LF_ENCHANTING_EXTRACTION]
        if addInvButtonOffsetsForPanel then
            fixAnchorVarsLeftAndTopOffsets(addInvButtonOffsetsForPanel, LF_ENCHANTING_EXTRACTION)

            --FCOIS.ReAnchorAdditionalInvButtons(LF_ENCHANTING_EXTRACTION)
        end
    end

    --Added with FCOIS v1.9.9
    FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId] = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId] or {}
    FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].isFilterPanelOn                = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].isFilterPanelOn or {}
    --Create the helper arrays for the filter button context menus
    FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastLockDynFilterIconId        = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastLockDynFilterIconId or {}
    FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastGearFilterIconId           = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastGearFilterIconId or {}
    FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastResDecImpFilterIconId      = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastResDecImpFilterIconId or {}
    FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastSellGuildIntFilterIconId   = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastSellGuildIntFilterIconId or {}

    --Added with FCOIS v1.7.4
    --For each panelId add an entry to for the non-deconstructable Libfilters panelIds
    local panelIdToDeconstructable = mappingVars.panelIdToDeconstructable
    local activeFilterPanelIds = mappingVars.activeFilterPanelIds
    if panelIdToDeconstructable ~= nil and activeFilterPanelIds ~= nil then
        for panelId, _ in pairs(activeFilterPanelIds) do
            if panelIdToDeconstructable[panelId] == nil then
                FCOIS.mappingVars.panelIdToDeconstructable[panelId] = false
            end
            --Added with FCOIS v1.9.9
            FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].isFilterPanelOn[panelId]               = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].isFilterPanelOn[panelId] or {false, false, false, false}
            --Create the helper arrays for the filter button context menus
            FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastLockDynFilterIconId[panelId]       = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastLockDynFilterIconId[panelId] or -1
            FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastGearFilterIconId[panelId]          = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastGearFilterIconId[panelId] or -1
            FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastResDecImpFilterIconId[panelId]     = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastResDecImpFilterIconId[panelId] or -1
            FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastSellGuildIntFilterIconId[panelId]  = FCOIS.settingsVars.accountWideButForEachCharacterSettings[currentCharId].lastSellGuildIntFilterIconId[panelId] or -1

            --Added with FCOIS v2.4.4 #244 Fix LF_SMITHING_RESEARCH/LF_JEWELRY_RESEARCH entries for last selected markerIcon at the 4 filter buttons right click context menus, and preset with -1 "all icons"
            FCOIS.settingsVars.settings.lastLockDynFilterIconId[panelId] =      FCOIS.settingsVars.settings.lastLockDynFilterIconId[panelId] or -1
            FCOIS.settingsVars.settings.lastGearFilterIconId[panelId] =         FCOIS.settingsVars.settings.lastGearFilterIconId[panelId] or -1
            FCOIS.settingsVars.settings.lastResDecImpFilterIconId[panelId]  =   FCOIS.settingsVars.settings.lastResDecImpFilterIconId[panelId] or -1
            FCOIS.settingsVars.settings.lastSellGuildIntFilterIconId[panelId] = FCOIS.settingsVars.settings.lastSellGuildIntFilterIconId[panelId] or -1
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --  Build the additional inventory "flag" context menu button data
    ------------------------------------------------------------------------------------------------------------------------
    --Constants
    local addInvBtnInvokers = FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker
    local ancVars = FCOIS.anchorVars
    local locVars = FCOIS.localizationVars.fcois_loc
    --Non changing values
    local showAddInvContextMenuFunc = showContextMenuForAddInvButtons
    local showAddInvContextMenuMouseUpFunc = onContextMenuForAddInvButtonsButtonMouseUp
    --The "flag" textures
    local invAddButtonVars = FCOIS.invAdditionalButtonVars
    local texNormal = invAddButtonVars.texNormal
    local texMouseOver = invAddButtonVars.texMouseOver
    --Other variables
    local mouseButtonRight = MOUSE_BUTTON_INDEX_RIGHT
    local text
    local font
    local tooltip = locVars["button_context_menu_tooltip"]
    local anchorTooltip = RIGHT
    local texClicked = texMouseOver
    local width  = 32
    local height = 32
    local alignMain = TOPLEFT
    local alignBackup = TOPLEFT
    local doHide = not settings.showFCOISAdditionalInventoriesButton

    --Loop over each additional inventory "flag" invoker button from the constants and check if it's "really adding" a new button.
    --if so: update some values of these buttons
    for panelId, buttonData in pairs(addInvBtnInvokers) do
        if panelId ~= nil and buttonData ~= nil and buttonData.addInvButton and buttonData.name ~= nil and buttonData.name ~= "" then
            buttonData.callbackFunction = showAddInvContextMenuFunc
            buttonData.onMouseUpCallbackFunction = showAddInvContextMenuMouseUpFunc
            buttonData.onMouseUpCallbackFunctionMouseButton = mouseButtonRight
            buttonData.text = text
            buttonData.font = font
            buttonData.tooltipText = tooltip
            buttonData.tooltipAlign = anchorTooltip
            buttonData.textureNormal = texNormal
            buttonData.textureMouseOver = texMouseOver
            buttonData.textureClicked = texClicked
            buttonData.width = width
            buttonData.height = height
            buttonData.left = ancVars.additionalInventoryFlagButton[apiVersion][panelId].left
            buttonData.top = ancVars.additionalInventoryFlagButton[apiVersion][panelId].top
            buttonData.alignMain = ancVars.additionalInventoryFlagButton[apiVersion][panelId].anchorMyPoint or alignMain
            buttonData.alignBackup = ancVars.additionalInventoryFlagButton[apiVersion][panelId].anchorToPoint or alignBackup
            buttonData.alignControl = ancVars.additionalInventoryFlagButton[apiVersion][panelId].anchorControl
            buttonData.hideButton = doHide
            --buttonData.updateOtherInvokerButtonsState
        end
    end

    --Since FCOIS version 1.4.4
    --Transfer old settings of filter button offsets, width and height to the new settings structure
    -->See file src/FCOIS_FilterButtons.lua, function FCOIS.CheckAndTransferFilterButtonDataByPanelId(libFiltersPanelId, filterButtonNr)
    local checkAndTransferFCOISFilterButtonDataByPanelId = FCOIS.CheckAndTransferFCOISFilterButtonDataByPanelId
    local filterButtonsToCheck = checkVars.filterButtonsToCheck
    if filterButtonsToCheck ~= nil then
        for _, filterButtonNr in ipairs(filterButtonsToCheck) do
            for libFiltersPanelId = 1, numLibFiltersFilterPanelIds, 1 do
                checkAndTransferFCOISFilterButtonDataByPanelId(libFiltersPanelId, filterButtonNr)
            end
        end -- for filterbuttonsToCheck ...
    end

    --Since FCOS version 1.6.0
    --Resetting the vendorBuyBack and vendorRepair protection to false as there is no setting to change this yet in the settings menu
    FCOIS.settingsVars.settings.blockVendorBuy      = false
    FCOIS.settingsVars.settings.blockVendorBuyback  = false
    FCOIS.settingsVars.settings.blockVendorRepair   = false -- to block the destroy
    --Update the dynamic icons as well, but enable the protection by default to block destroying,
    --as drag&drop of an item at the vendor repair panel will try to destroy the item
    for filterIconHelper = FCOIS_CON_ICON_LOCK, numFilterIcons do
        if iconIsDynamic[filterIconHelper] then
            for filterIconHelperPanel = 1, numLibFiltersFilterPanelIds, 1 do
                --Disable some filter panel IDs at the vendor!
                if filterIconHelperPanel == LF_VENDOR_BUY or filterIconHelperPanel == LF_VENDOR_BUYBACK or filterIconHelperPanel == LF_VENDOR_REPAIR then
                    FCOIS.settingsVars.settings.icon[filterIconHelper].antiCheckAtPanel[filterIconHelperPanel] = false
                end
                --Added with FCOIS version 1.6.7
                --Resetting the dynamic icons filterpanel protection settings for GuildStore withdraw and CarftBag to nil as there is no protection available
                --and the tooltips etc. should show these as "grey" entries without protection!
                if filterIconHelperPanel == LF_GUILDBANK_WITHDRAW or filterIconHelperPanel == LF_CRAFTBAG then
                    FCOIS.settingsVars.settings.icon[filterIconHelper].antiCheckAtPanel[filterIconHelperPanel] = nil
                end
            end
        end
    end

    --Introduced with FCOIS v2.2.4 2021-11-15 Add default values for new filterButtonSettings, if they are missing
    if FCOIS.settingsVars.settings.filterButtonSettings == nil then
        FCOIS.settingsVars.settings.filterButtonSettings = ZO_ShallowTableCopy(FCOIS.settingsVars.defaults.filterButtonSettings)
    end

    --Added with FCOIS v2.2.4
    --#189 FCOIS uniqueIds item markers got saved into SavedVariables table "markedItems", but they should only be saved to "markedItemsFCOISUnique"
    if FCOIS.settingsVars.settings.cleanedFCOISUniqueInNonUnique == nil then
        local markedItemsInSV = FCOIS.settingsVars.settings.markedItems
        if markedItemsInSV ~= nil then
            for markerIconNr, _ in ipairs(markedItemsInSV) do
                for itemInstanceOrZOsUniqueId, isMarked in pairs(markedItemsInSV) do
                    if isMarked == true and type(itemInstanceOrZOsUniqueId) == "string" and strfind(itemInstanceOrZOsUniqueId, ",") ~= nil then
                        --FCOIS unique-ID saved to normal markerIcons table -> Delete
                        --d(">Found FCOISUniqueID in normal markedItems table: " ..tos(itemInstanceOrZOsUniqueId))
                        FCOIS.settingsVars.settings.markedItems[markerIconNr][itemInstanceOrZOsUniqueId] = nil
                    end
                end
            end
        end
        FCOIS.settingsVars.settings.cleanedFCOISUniqueInNonUnique = true
    end


    --Added with FCOIS v2.2.4
    --#192 FCOIS uniqueIds contain "nil" strings which consume too much space. Change these to "" instead, as function FCOIS.CreateFCOISUniqueIdString uses too now
    if FCOIS.settingsVars.settings.cleanedFCOISUniqueNILEntries == nil then
        local markedItemsFCOISUniqueInSV = FCOIS.settingsVars.settings.markedItemsFCOISUnique
        local newPart                    = ""
        if markedItemsFCOISUniqueInSV ~= nil then
            for markerIconNr, markedItemsData in ipairs(markedItemsFCOISUniqueInSV) do
                for FCOISuniqueIdOfItem, isMarked in pairs(markedItemsData) do
                    if isMarked == true and type(FCOISuniqueIdOfItem) == "string" and strfind(FCOISuniqueIdOfItem, ",") ~= nil then
                        local partsOfFCOISUniqueId = splitStringWithDelimiter(FCOISuniqueIdOfItem, ",")
                        if partsOfFCOISUniqueId ~= nil and #partsOfFCOISUniqueId > 0 then
                            local newFCOISUniqueId = ""
                            local wasFCOISUniqueIdChanged = false
                            for idx, part in ipairs(partsOfFCOISUniqueId) do
                                --Always keep the itemID at first part
                                if idx > 1 and (part == "nil" or part == "?") then
                                    part = newPart
                                    wasFCOISUniqueIdChanged = true
                                end
                                newFCOISUniqueId = newFCOISUniqueId .. part
                                if idx < #partsOfFCOISUniqueId then
                                    newFCOISUniqueId = newFCOISUniqueId .. ","
                                end
                            end
                            if wasFCOISUniqueIdChanged == true then
                                --d(">changed FCOIS uniqueId from: " ..tos(FCOISuniqueIdOfItem) .. " to: " ..tos(newFCOISUniqueId))
                                --Remove old FCOISUniqueId
                                FCOIS.settingsVars.settings.markedItemsFCOISUnique[markerIconNr][FCOISuniqueIdOfItem] = nil
                                --Add new corrected one
                                FCOIS.settingsVars.settings.markedItemsFCOISUnique[markerIconNr][newFCOISUniqueId] = true
                            end
                        end
                    end
                end
            end
        end
        FCOIS.settingsVars.settings.cleanedFCOISUniqueNILEntries = true
    end
end -- AfterSettings


--Do some updates to the SavedVariables before the addon menu is created
function FCOIS.UpdateSettingsBeforeAddonMenu()
    --SetTracker addon
    FCOIS.otherAddons.SetTracker.GetSetTrackerSettingsAndBuildFCOISSetTrackerData()  --#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300

    --Introduced with FCOIS v0.8.8b
    --Create the armor, jewelry and weapon trait automatic marking arrays and preset them with "true",
    --so all armor, jewelry and weapon set pats will be marked
    --Armor
    local traits = FCOIS.mappingVars.traits
    local armorTraits = traits.armorTraits
    --Jewelry
    local jewelryTraits = traits.jewelryTraits
    --Weapons
    local weaponTraits = traits.weaponTraits
    --Shields
    local weaponShieldTraits = traits.weaponShieldTraits
    --The chosne icon for the set parts
    local settings = FCOIS.settingsVars.settings
    local chosenSetIcon = settings.autoMarkSetsIconNr
    --Check armor
    for armorTraitNumber, _ in pairs(armorTraits) do
        if settings.autoMarkSetsCheckArmorTrait[armorTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTrait[armorTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if settings.autoMarkSetsCheckArmorTraitIcon[armorTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTraitIcon[armorTraitNumber] = chosenSetIcon
        end
    end
    --Check jewelry
    for jewelryTraitNumber, _ in pairs(jewelryTraits) do
        if settings.autoMarkSetsCheckJewelryTrait[jewelryTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTrait[jewelryTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if settings.autoMarkSetsCheckJewelryTraitIcon[jewelryTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTraitIcon[jewelryTraitNumber] = chosenSetIcon
        end
    end
    --Check weapons
    for weaponTraitNumber, _ in pairs(weaponTraits) do
        if settings.autoMarkSetsCheckWeaponTrait[weaponTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[weaponTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if settings.autoMarkSetsCheckWeaponTraitIcon[weaponTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTraitIcon[weaponTraitNumber] = chosenSetIcon
        end
    end
    --Check shields
    for weaponShieldTraitNumber, _ in pairs(weaponShieldTraits) do
        if settings.autoMarkSetsCheckWeaponTrait[weaponShieldTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[weaponShieldTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if settings.autoMarkSetsCheckWeaponTraitIcon[weaponShieldTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTraitIcon[weaponShieldTraitNumber] = chosenSetIcon
        end
    end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- Load the SavedVariables now
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--Load the SavedVariables now
function FCOIS.LoadUserSettings(calledFromExternal, isFromEventAddOnLoaded)
    calledFromExternal = calledFromExternal or false
    isFromEventAddOnLoaded = isFromEventAddOnLoaded or false
--TODO DEBUG: Uncomment for debugging
--if GetDisplayName() == "@Baertram" then d("[FCOIS]LoadUserSettings - calledFromExternal: " ..tos(calledFromExternal) .. ", isFromEventAddOnLoaded: " ..tos(isFromEventAddOnLoaded)) end
    if calledFromExternal == true then
        FCOIS.addonVars.gSettingsLoaded = false
        if FCOIS.FCOItemSaver_CheckGamePadMode() then return false end
    end
    if isFromEventAddOnLoaded == true or not FCOIS.addonVars.gSettingsLoaded then
        --Build the default settings
        FCOIS.BuildDefaultSettings()

        --Get the server name
        FCOIS.worldName = GetWorldName()
        local world = FCOIS.worldName

        --Call the "Before SavedVars loading" function (e.g. migrate non-server dependent settings to server settings)
        FCOIS.BeforeSettings()

        --=========== BEGIN - SAVED VARIABLES ==========================================
        FCOIS.settingsVars.defaultSettings = {}
        FCOIS.settingsVars.settings = {}
        FCOIS.settingsVars.accountWideButForEachCharacterSettings = {}
        --------------------------------------------------------------------------------------------------------------------
        -- Migration of non-server dependent settings to server-dependent settings
        --------------------------------------------------------------------------------------------------------------------
        FCOIS.defSettingsNonServerDependendFound = false
        FCOIS.settingsNonServerDependendFound    = false
        local checkForMigrateDefDefaults    = { ["saveMode"] = 999 }                -- Set easy to check value for defaults to check if SavedVars were already there or not
        local checkForMigrateDefaults       = { ["alwaysUseClientLanguage"] = 999 } -- Set easy to check value for defaults to check if SavedVars were already there or not
        ------------------------------------------------------------------------------------------------------------------------
        --Added with FCOIS version 1.5.7: AccountWide settings can be saved equal for all accounts. Therefor the ZO_SavedVars:NewAccountWide function's last parameter "AccountName"
        --will be used, if the saveMode is 3 (AllAccountsTheSame).
        --Added with FCOIS version 1.3.5: Server saved settings (EU, NA, PTS)
        --Load the Non-Server dependent savedvars (from the SavedVars[svDefaultName] profile), if they exist.
        -- !!! Do NOT specify default "fallback" values as then the defaults would be ALWAYS found and used !!!
        --Load the old user's default settings from SavedVariables file -> Account wide of basic version 999 at first, without Servername as last parameter, to get existing data

        --FCOIS v1.9.6: Get the old SV data w/o server dependent values
        local oldDefaultSettings = ZO_SavedVars:NewAccountWide(addonSVname, 999, svSettingsForAllName, checkForMigrateDefDefaults, nil)
        --FCOIS._oldDefaultSettings = oldDefaultSettings
        --Check, by help of basic version 999, if the settings should be loaded for each character or account wide
        --Use the current addon version to read the FCOIS.settingsVars.settings now
        local oldSettings = {}
        --Load the old user's settings from SavedVariables file -> Account/Character data, depending on the old defaultSettings, without Servername as last parameter, to get existing data
        if oldDefaultSettings.saveMode == 1 then
            --Each character of an account different
            --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
            oldSettings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, checkForMigrateDefaults, nil)
            --Transfer the data from the name to the unique ID SavedVars now
            NamesToIDSavedVars()
        elseif oldDefaultSettings.saveMode == 3 then
            --All accounts the same settings
            oldSettings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, checkForMigrateDefaults, nil, svAllAccTheSameAcc)
            --All others use account wide
        else
            --Account wide settings
            oldSettings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, checkForMigrateDefaults, nil, nil)
        end
        --FCOIS._oldSettings = oldSettings
        ------------------------------------------------------------------------------------------------------------------------
        --Check if existing non-server dependent settings were found
        -->The values of oldDefaultSettings["saveMode"] or oldSettings["alwaysUseClientLanguage"] would be different then 999
        -->which get's set by checkForMigrateDefDefaults or checkForMigrateDefaults above, if the tables were not existing before!
        if oldDefaultSettings ~= nil and oldSettings ~= nil then
            --Is the entry "saveMode" given? Need to migrate old data then!
            if oldDefaultSettings["saveMode"] ~= 999 then
                FCOIS.defSettingsNonServerDependendFound = true
            end
            --Is the entry "alwaysUseClientLanguage" given? Need to migrate old data then!
            if oldSettings["alwaysUseClientLanguage"] ~= 999 then
                FCOIS.settingsNonServerDependendFound = true
            end
        end
        --AccountName must start with @
        local displayName = accName
        if strfind(displayName, "@") ~= 1 then
            displayName = "@" .. displayName
        end
        ------------------------------------------------------------------------------------------------------------------------
        --If server dependent settings were found (or it's a new installation of FCOIS -> Server dependent variables will be used from the start, using default settings)
        -->Use these ZO_SavedVariables now for the addon!
        if (FCOIS.defSettingsNonServerDependendFound == false and FCOIS.settingsNonServerDependendFound == false) then
            debugMessage("LoadUserSettings", "Using server (" .. world .. ") dependent SavedVars", true, FCOIS_DEBUG_DEPTH_NORMAL)
            --Reset the old default non-server dependent settings, if they still exist
            --FCOItemSaver_Settings["Default"] = nil
            if FCOItemSaver_Settings[svDefaultName] then FCOItemSaver_Settings[svDefaultName] = nil end

            local defaultSavedVariables = FCOIS.settingsVars.defaults

            --Get the new server dependent settings
            --Load the user's settings from SavedVariables file -> Account wide of basic version 999 at first
            FCOIS.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(addonSVname, 999, svSettingsForAllName, FCOIS.settingsVars.firstRunSettings, world, nil)
            --Check, by help of basic version 999, if the settings should be loaded for each character or account wide
            --Use the current addon version to read the FCOIS.settingsVars.settings now
            if FCOIS.settingsVars.defaultSettings.saveMode == 1 then
                --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, defaultSavedVariables, world)
                --Transfer the data from the name to the unique ID SavedVars now
                NamesToIDSavedVars(world)
            elseif FCOIS.settingsVars.defaultSettings.saveMode == 2 then
                --Account wide settings
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, defaultSavedVariables, world, nil)
            elseif FCOIS.settingsVars.defaultSettings.saveMode == 3 then
                --All accounts the same settings
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, defaultSavedVariables, world, svAllAccTheSameAcc)
                --Added with FCOIS version 2.2.4 Settings all the same for all Accounts and all servers
            elseif FCOIS.settingsVars.defaultSettings.saveMode == 4 then
                --All servers and accounts the same
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, defaultSavedVariables, svAllServersTheSame, svAllAccTheSameAcc)
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Non-server dependent settings were found. Migrate them to server dependent ones
        else
            -- Disable non-server dependent settings and save them to the server dependent ones now
            d("|cFF0000>>=====================================================>>|r")
            local debugMsg = "[FCOIS]Found non-server dependent SavedVars -> Migrating them now to server (" .. world .. ") dependent settings"
            d(debugMsg)
            debugMessage("LoadUserSettings", debugMsg, true, FCOIS_DEBUG_DEPTH_NORMAL)
            --First the settings for all
            --Copy the non-server dependent SV data determined above to a new table without "link"
            local oldDefSettings = FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsForAllName]
            local currentNonServerDependentDefSettingsCopy = ZO_DeepTableCopy(oldDefSettings)
            --Reset the non-server dependent savedvars now! -> See confirmation dialog below
            FCOIS.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(addonSVname, 999, svSettingsForAllName, currentNonServerDependentDefSettingsCopy, world, nil)
            --Then the other settings
            --Copy the non-server dependent SV data determined above to a new table without "link"
            oldSettings = FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsName]
            local currentNonServerDependentSettingsCopy = ZO_DeepTableCopy(oldSettings)
            --Reset the non-server dependent savedvars now! -> See confirmation dialog below
            --FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsName] = nil -- if you want to only remove the settings, otherwise just nil one of the parent tables
            --FCOItemSaver_Settings[svDefaultName] = nil --reset the whole table now

            --Initialize the server-dependent settings with no values
            if oldDefSettings.saveMode == 1 then
                --Each character
                --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, currentNonServerDependentSettingsCopy, world)
            elseif oldDefSettings.saveMode == 2 then
                --Account wide
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, world, nil)
            elseif oldDefSettings.saveMode == 3 then
                --All accounts the same settings
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, world, svAllAccTheSameAcc)
            end
            --d("[FCOIS]SavedVars were migrated:\nPlease either type /reloadui into the chat and press the RETURN key,\n or logout now in order to save the data to your SavedVariables properly!")
            --Show UI dialog now too
            local locVars = FCOIS.localizationVars.fcois_loc
            local preVars = FCOIS.preChatVars
            local title = preVars.preChatTextRed .. "?> SavedVariables migration to server: " .. world
            local body = locVars["options_migrate_settings_ask_before_to_server"]
            --Show confirmation dialog: Migration to server dependent savedvariables done. Reload UI now?
            --FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
            showConfirmationDialog("ReloadUIAfterSavedVarsMigration", title, body,
            --Yes button
                    function()
                        --Clear the non-server depenent SavedVars now
                        FCOItemSaver_Settings[svDefaultName] = nil --reset the whole table now
                        --Reload the UI
                        ReloadUI()
                    end,
            --Abort/No button was pressed
                    function()
                        --Clear the server dependent data
                        FCOItemSaver_Settings[world] = nil

                        --Revert the savedvars to non-server dependent
                        FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsForAllName] = currentNonServerDependentDefSettingsCopy
                        FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsName]       = currentNonServerDependentSettingsCopy
                        --Assign the current SavedVards properly to the internally used variables of FCOIS again, but without server name (-> last parameter = nil, use svDefaultName table key!
                        if oldDefSettings.saveMode == 1 then
                            --Each charater
                            --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                            FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, currentNonServerDependentSettingsCopy, nil)
                        elseif oldDefSettings.saveMode == 2 then
                            --Account wide
                            FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, nil, nil)
                        elseif oldDefSettings.saveMode == 3 then
                            --All accounts the same settings
                            FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, nil, svAllAccTheSameAcc)
                        end
                        d("[FCOIS]!!! SavedVars were not migrated yet !!!\nYou are still using the non-server dependent settings!\nPlease reload the UI to see the migration dialog again.")
                        d("|cFF0000<<=====================================================<<|r")
                    end
            )
        end

        --The SettingsForAll was setup to save the filter buttons for each character individually?
        if FCOIS.settingsVars.defaultSettings.filterButtonsSaveForCharacter == true then
            local saveMode = FCOIS.settingsVars.defaultSettings.saveMode
            --Character wide settings are enabled: Do nothing as it will be handled automatically
            --But for accountWide and AllAccountsTheSame and allServersAndAccountsTheSame
            if saveMode == 2 or saveMode == 3 or saveMode == 4 then
                local accountNameToUse --will be nil in case of SaveMode 2 to use the logged in @accountName
                local worldToUse = world
                if saveMode == 3 or saveMode == 4 then accountNameToUse = svAllAccTheSameAcc end
                if saveMode == 4 then worldToUse = svAllServersTheSame end

                --Account wide settings are enabled: Load the extra SavedVariables for the account wide "per character" settings
                FCOIS.settingsVars.accountWideButForEachCharacterSettings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsForEachCharacterName, FCOIS.settingsVars.accountWideButForEachCharacterDefaults, worldToUse, accountNameToUse)
            end
        end

        --=========== END - SAVED VARIABLES ============================================

        --Load the current needed workarounds/fixes
        FCOIS.LoadWorkarounds()

        --Do some "after settings "stuff
        FCOIS.AfterSettings()

        --Set settings = loaded
        FCOIS.addonVars.gSettingsLoaded = true
    end
    if calledFromExternal == true then FCOIS.addonVars.gSettingsLoaded = false end
    --=============================================================================================================
    return true
end

--Copy SavedVariables from one server, account and/or character to another
function FCOIS.CopySavedVars(srcServer, targServer, srcAcc, targAcc, srcCharId, targCharId, onlyDelete, forceReloadUI, toAllServersAndAccountsTheSame)
--d(strformat("[FCOIS]copySavedVars srcServer: %s, targServer: %s, srcAcc: %s, targAcc: %s, srcCharId: %s, targCharId: %s, onlyDelete: %s, forceReloadUI: %s, toAllServersAndAccountsTheSame: %s",
    --tos(srcServer), tos(targServer), tos(srcAcc), tos(targAcc), tos(srcCharId), tos(targCharId), tos(onlyDelete), tos(forceReloadUI), tos(toAllServersAndAccountsTheSame)))
    onlyDelete = onlyDelete or false
    forceReloadUI = forceReloadUI or false
    toAllServersAndAccountsTheSame = toAllServersAndAccountsTheSame or false
    local copyServer = false
    local copyAcc = false
    local copyChar = false
    local copyAccToChar = false
    local copyCharToAcc = false
    local deleteServer = false
    local deleteAcc = false
    local deleteChar = false
    --------------------------------------------------------------------------------------------------------------------
    --"What should be done" checks?
    if srcServer == nil or targServer == nil then
        if not toAllServersAndAccountsTheSame then
            return nil
        end
    end
    if srcCharId ~= nil and targCharId ~= nil then
        if onlyDelete then
            deleteChar = true
        else
            copyChar = true
        end
    else
        if srcCharId == nil and targCharId ~= nil and srcAcc ~= nil and targAcc ~= nil then
            if onlyDelete then
                deleteChar = true
            else
                copyAccToChar = true
            end

        end
    end
    if not copyAccToChar and not copyChar and not deleteChar and srcAcc ~= nil and targAcc ~= nil then
        if onlyDelete then
            deleteAcc = true
        else
            copyAcc = true
        end
    end
    if not copyAccToChar and not copyChar and not copyAcc and not deleteChar and not deleteAcc then
        if onlyDelete then
            deleteServer = true
        else
            copyServer = true
        end
    end
    if toAllServersAndAccountsTheSame == true then
        if onlyDelete then
            deleteServer = true
        else
            copyServer = true
        end
    end

    --Nothing to do? Abort here
    if not copyServer and not deleteServer and not copyAcc and not deleteAcc and not copyChar and not deleteChar and not copyAccToChar and not copyCharToAcc then return end

    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    local mappingVars = FCOIS.mappingVars
    local noEntry = mappingVars.noEntry
    local noEntryValue = tos(mappingVars.noEntryValue)
    --Get some settings
    local settingsVars = FCOIS.settingsVars
    local defSettingsSaveMode = settingsVars.defaultSettings.saveMode
    local useAccountWideSV      = (defSettingsSaveMode == 2 or defSettingsSaveMode == 3) or false
    local useAllAccountSameSV   = defSettingsSaveMode == 3 or false
    local svDefToCopy
    local svToCopy
    local currentlyLoggedInUserId = getCurrentlyLoggedInCharUniqueId()
    local displayName = accName
    local accountName = displayName
    if useAllAccountSameSV then
        accountName = svAllAccTheSameAcc
    end
    local showReloadUIDialog = false

    --d("[FCOIS.copySavedVars]srcServer: " .. tos(srcServer) .. ", targServer: " ..tos(targServer).. ", srcAccount: " .. tos(srcAcc) .. ", targAccount: " ..tos(targAcc).. ", srcChar: " .. tos(srcCharId) .. ", targChar: " ..tos(targCharId).. ", onlyDelete: " .. tos(onlyDelete))
    --d(">copyServer: " .. tos(copyServer) .. ", deleteServer: " ..tos(deleteServer).. ", copyAccount: " .. tos(copyAcc) .. ", deleteAccount: " ..tos(deleteAcc).. ", copyChar: " .. tos(copyChar) .. ", deleteChar: " ..tos(deleteChar))

    --Security check
    if ((srcServer == noEntry or targServer == noEntry) and onlyDelete == false) or (targServer == noEntry and onlyDelete == true) then return end
    --What is to do now?
    --------------------------------------------------------------------------------------------------------------------
    --Copy
    if not onlyDelete then
        if copyServer then
            --if toAllServersAndAccountsTheSame == true then
                --2022-01-30 #183 Added "toAllServersAndAccountsTheSame" parameter to copy SV to profile svAllServersTheSame and account svAllAccTheSameAcc SavedVariables

            --else
                --[[
                            --Account wide settings enabled?
                            if useAccountWideSV then
                                svDefToCopy = FCOItemSaver_Settings[srcServer][accountName][svAccountWideName][svSettingsForAllName]
                                svToCopy    = FCOItemSaver_Settings[srcServer][accountName][svAccountWideName][svSettingsName]
                            else
                                --Character settings enabled. Get the currently logged in character ID
                                if currentlyLoggedInUserId == nil or currentlyLoggedInUserId == 0 then return nil end
                                svDefToCopy = FCOItemSaver_Settings[srcServer][displayName][svAccountWideName][svSettingsForAllName]
                                svToCopy    = FCOItemSaver_Settings[srcServer][displayName][currentlyLoggedInUserId][svSettingsName]
                            end
                ]]
            --end

        elseif copyAcc then
            if srcAcc == noEntry or targAcc == noEntry then return end
            --DefaultForAll settings are always account wide!
            --Account wide settings enabled?
            if useAccountWideSV then
                svDefToCopy = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsForAllName]
                svToCopy    = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsName]
            else
                --Character settings enabled?
                if currentlyLoggedInUserId == nil or currentlyLoggedInUserId == 0 then return nil end
                svDefToCopy = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsForAllName]
                svToCopy    = FCOItemSaver_Settings[srcServer][srcAcc][currentlyLoggedInUserId][svSettingsName]
            end
        elseif copyChar then
            if srcAcc == noEntry or targAcc == noEntry then return end
            if srcCharId == noEntryValue or targCharId == noEntryValue then return end
            --If we copy a character this will be done with AccountWide settings enabled the same as with character settings enabled
            svDefToCopy = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsForAllName]
            svToCopy    = FCOItemSaver_Settings[srcServer][srcAcc][srcCharId][svSettingsName]

        --Added with FCOIS v1.9.6: Copy chosen source account settings to chosen destination character settings
        elseif copyAccToChar then
            if srcAcc == noEntry or targAcc == noEntry then return end
            if targCharId == noEntryValue then return end
            svDefToCopy = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsForAllName]
            svToCopy    = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsName]
        --Added with FCOIS v1.9.6: Copy chosen source character settings to chosen destination account settings
        elseif copyCharToAcc then
            if srcAcc == noEntry or targAcc == noEntry then return end
            if srcCharId == noEntryValue then return end
            svDefToCopy = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsForAllName]
            svToCopy    = FCOItemSaver_Settings[srcServer][srcAcc][srcCharId][svSettingsName]
        end
    --------------------------------------------------------------------------------------------------------------------
    else
        --Delete
        --Delete all servers and accounts the same
        if toAllServersAndAccountsTheSame == true then
            --2022-01-30 #183 add "toAllServersAndAccountsTheSame" parameter to copy SV to profile svAllServersTheSame and account svAllAccTheSameAcc SavedVariables
            if FCOItemSaver_Settings[svAllServersTheSame] ~= nil then
                if deleteServer then
                    if FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc] ~= nil then
                        FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc] = nil
                        FCOItemSaver_Settings[svAllServersTheSame] = nil
                        showReloadUIDialog = true
                    end
                end
            end
        --Delete other (server, account, char)
        else
            if FCOItemSaver_Settings[targServer] ~= nil then
                if deleteServer then
                    --[[
                    FCOItemSaver_Settings[targServer] = nil
                    showReloadUIDialog = true
                    ]]
                elseif deleteAcc then
                    if targAcc == noEntry then return end
                    if FCOItemSaver_Settings[targServer][targAcc] ~= nil then
                        FCOItemSaver_Settings[targServer][targAcc] = nil
                        showReloadUIDialog = true
                    end
                elseif deleteChar then
                    if targAcc == noEntry then return end
                    if targCharId == noEntryValue then return end
                    if FCOItemSaver_Settings[targServer][targAcc] ~= nil then
                        if FCOItemSaver_Settings[targServer][targAcc][targCharId] ~= nil then
                            FCOItemSaver_Settings[targServer][targAcc][targCharId] = nil
                            showReloadUIDialog = true
                        end
                    end
                end
            end
        end
    end -- delete

    --------------------------------------------------------------------------------------------------------------------
    --Shall copy something?
    --Server, account, char
    if not onlyDelete and svDefToCopy ~= nil and svToCopy ~= nil then
        --d(">go on with copy/delete!")
        --The default table got the language entry and the normal settings table got the markedItems entry?
        if svDefToCopy["language"] ~= nil and (svToCopy["markedItems"] ~= nil or svToCopy["markedItemsFCOISUnique"] ~= nil) then
            --d(">>found def language and markedItems")
            if FCOItemSaver_Settings[targServer] == nil then FCOItemSaver_Settings[targServer] = {} end
            --Source data is valid. Now build the target data
            if useAccountWideSV == true then
                --Account wide settings
                if copyServer == true then
                    --[[
                    if FCOItemSaver_Settings[targServer][accountName] == nil then FCOItemSaver_Settings[targServer][accountName] = {} end
                    if FCOItemSaver_Settings[targServer][accountName][svAccountWideName] == nil then FCOItemSaver_Settings[targServer][accountName][svAccountWideName] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][accountName][svAccountWideName][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][accountName][svAccountWideName][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][accountName][svAccountWideName][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][accountName][svAccountWideName][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][accountName][svAccountWideName][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][accountName][svAccountWideName][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                    ]]
                elseif copyAcc == true then
                    --d(">>>copy account")
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName] == nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                elseif copyChar == true then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId] == nil then FCOItemSaver_Settings[targServer][targAcc][targCharId] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                    --Added with FCOIS v1.9.6: Copy account settings to character settings
                elseif copyAccToChar == true then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId] == nil then FCOItemSaver_Settings[targServer][targAcc][targCharId] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                    --Added with FCOIS v1.9.6: Copy character settings to account settings
                elseif copyCharToAcc == true then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName] == nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                end

            else
                --Character settings enabled.
                if copyServer == true then
                    --[[
                    if FCOItemSaver_Settings[targServer][displayName] == nil then FCOItemSaver_Settings[targServer][displayName] = {} end
                    if FCOItemSaver_Settings[targServer][displayName][svAccountWideName] == nil then FCOItemSaver_Settings[targServer][displayName][svAccountWideName] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][displayName][svAccountWideName][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][displayName][svAccountWideName][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][displayName][svAccountWideName][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][displayName][svAccountWideName][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][displayName][svAccountWideName][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][displayName][svAccountWideName][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                    ]]
                elseif copyAcc == true then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId] == nil then FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId] = {} end
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                elseif copyChar == true then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId] == nil then FCOItemSaver_Settings[targServer][targAcc][targCharId] = {} end
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                    --Added with FCOIS v1.9.6: Copy account settings to character settings
                elseif copyAccToChar == true then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId] == nil then FCOItemSaver_Settings[targServer][targAcc][targCharId] = {} end
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                    --Added with FCOIS v1.9.6: Copy character settings to account settings
                elseif copyCharToAcc == true then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId] == nil then FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId] = {} end
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                end
            end
        end

    --Copy to All servers and accounts the same
    elseif not onlyDelete and toAllServersAndAccountsTheSame == true then
        --2022-01-30 #183 Added "toAllServersAndAccountsTheSame" parameter to copy SV to profile svAllServersTheSame and account svAllAccTheSameAcc SavedVariables
        svDefToCopy = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsForAllName]
        svToCopy    = FCOItemSaver_Settings[srcServer][srcAcc][svAccountWideName][svSettingsName]
        if FCOItemSaver_Settings[svAllServersTheSame] == nil then FCOItemSaver_Settings[svAllServersTheSame] = {} end
        if FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc] == nil then FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc] = {} end
        if FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName] == nil then FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName] = {} end
        --Check if def settings are given and reset them, then set them to the source values
        if FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName][svSettingsForAllName] = nil end
        FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName][svSettingsForAllName] = svDefToCopy
        --Check if settings are given and reset them, then set them to the source values
        if FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName][svSettingsName] ~= nil then FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName][svSettingsName] = nil end
        FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc][svAccountWideName][svSettingsName] = svToCopy
        showReloadUIDialog = true
    end


--d(">showReloadUIDialog: " ..tos(showReloadUIDialog) .. ", toAllServersAndAccountsTheSame: " ..tos(toAllServersAndAccountsTheSame))

    --------------------------------------------------------------------------------------------------------------------
    --Now check if we are logged in to the target server and reload the user interface to get the copied data to the internal savedvars
    if showReloadUIDialog == true then
        if forceReloadUI == true or toAllServersAndAccountsTheSame == true then ReloadUI() end
        if toAllServersAndAccountsTheSame == false then
            local world = GetWorldName()
            if world == targServer then
--d(">world == targetServer")
                local titleVar = "SavedVariables: "
                if srcServer ~= noEntry then titleVar = titleVar .. "\"" .. srcServer ..  "\"" end
                titleVar = titleVar .. " -> \"" .. targServer .. "\""
                local locVars = FCOIS.localizationVars.fcois_loc
                local questionVar = ""
                if copyServer or deleteServer then
                    if copyServer then
                        questionVar = zo_strf(locVars["question_copy_sv_server_reloadui"], srcServer, targServer, tos(useAccountWideSV))
                    else
                        questionVar = zo_strf(locVars["question_delete_sv_server_reloadui"], targServer, tos(useAccountWideSV))
                    end
                elseif copyAcc or deleteAcc then
                    if copyAcc then
                        questionVar = zo_strf(locVars["question_copy_sv_account_reloadui"], srcServer, srcAcc, targServer, targAcc, tos(useAccountWideSV))
                    else
                        questionVar = zo_strf(locVars["question_delete_sv_account_reloadui"], targServer, targAcc, tos(useAccountWideSV))
                    end
                elseif copyChar or deleteChar then
                    local characterTable = getCharactersOfAccount(false)
                    local srcCharName
                    local targCharName = getCharacterName(targCharId, characterTable)
                    if copyChar then
                        srcCharName = getCharacterName(srcCharId, characterTable)
                        questionVar = zo_strf(locVars["question_copy_sv_character_reloadui"], srcServer, srcAcc, srcCharName, targServer, targAcc, targCharName, tos(useAccountWideSV))
                    else
                        questionVar = zo_strf(locVars["question_delete_sv_character_reloadui"], targServer, targAcc, targCharName, tos(useAccountWideSV))
                    end
                    --Added with FCOIS v1.9.6: Copy account settings to character settings
                elseif copyAccToChar then
                    local characterTable = getCharactersOfAccount(false)
                    local targCharName = getCharacterName(targCharId, characterTable)
                    questionVar = zo_strf(locVars["question_copy_sv_account_to_char_reloadui"], srcServer, srcAcc, targServer, targAcc, targCharName, tos(useAccountWideSV))
                    --Added with FCOIS v1.9.6: Copy character settings to account settings
                elseif copyCharToAcc then
                    local characterTable = getCharactersOfAccount(false)
                    local srcCharName = getCharacterName(srcCharId, characterTable)
                    questionVar = zo_strf(locVars["question_copy_sv_char_to_account_reloadui"], srcServer, srcAcc, srcCharName, targServer, targAcc, tos(useAccountWideSV))
                end
--d(">>show confrim. dialog: ReloadUI after SV copy/delete")
                --Show confirmation dialog: ReloadUI now?
                --FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
                --dialogName, title, body, callbackYes, callbackNo, callbackSetup, data, forceUpdate
                showConfirmationDialog("ReloadUIAfterSVServer2ServerCopyDialog", titleVar, questionVar,
                        function() ReloadUI() end,
                        function() end
                )
            end
        end
    end
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    return false
end