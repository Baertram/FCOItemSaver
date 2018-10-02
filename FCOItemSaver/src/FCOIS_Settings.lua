--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

--==========================================================================================================================================
-- 										FCOIS settings & saved variables functions
--==========================================================================================================================================


local function NamesToIDSavedVars(serverWorldName)
    serverWorldName = serverWorldName or "Default"
    --Are the character settings enabled? If not abort here
    if (FCOIS.settingsVars.defaultSettings.saveMode ~= 1) then return nil end
    --Did we move the character name settings to character ID settings already?
    if not FCOIS.settingsVars.settings.namesToIDSavedVars then
        local doMove
        local charName
        local displayName = GetDisplayName()
        --Check all the characters of the account
        for i = 1, GetNumCharacters() do
            local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
            charName = name
            charName = zo_strformat(SI_UNIT_NAME, charName)
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
            FCOIS.settingsVars.settings.namesToIDSavedVars = true -- should not be necessary because data don't exist anymore in FCOItemSaver_Settings.Default[displayName][name]
        end
    end
end

--==============================================================================

--Choose the filter type
function FCOIS.getSettingsIsFilterOn(p_filterId, p_filterPanel)
    local result
    local settings = FCOIS.settingsVars.settings
    if (settings.splitFilters == true) then
        local p_filterPanelNew = p_filterPanel or FCOIS.gFilterWhere

        --New behaviour with filters
        result = settings.isFilterPanelOn[p_filterPanelNew][p_filterId]
        if result == nil then
            return false
        end
        if settings.debug then FCOIS.debugMessage( "[GetSettingsIsFilterOn] Filter Panel: " .. tostring(p_filterPanelNew) .. ", FilterId: " .. tostring(p_filterId) .. ", Result: " .. tostring(result), true, FCOIS_DEBUG_DEPTH_SPAM) end
        return result
    else
        --Old behaviour with filters
        result = settings.isFilterOn[p_filterId]
        if settings.debug then FCOIS.debugMessage( "[GetSettingsIsFilterOn] FilterId: " .. tostring(p_filterId) .. ", Result: " .. tostring(result), true, FCOIS_DEBUG_DEPTH_SPAM) end
        return result
    end
end

--Set the value of a filter type, and return it
function FCOIS.setSettingsIsFilterOn(p_filterId, p_value, p_filterPanel)
    local p_filterPanelNew = p_filterPanel or FCOIS.gFilterWhere
    local settings = FCOIS.settingsVars.settings
    if (settings.splitFilters == true) then
        --New behaviour with filters
        settings.isFilterPanelOn[p_filterPanelNew][p_filterId] = p_value
        if settings.debug then FCOIS.debugMessage( "[SetSettingsIsFilterOn] Filter Panel: " .. tostring(p_filterPanelNew) .. ", FilterId: " .. tostring(p_filterId) .. ", Value: " .. tostring(p_value), true, FCOIS_DEBUG_DEPTH_SPAM) end
    else
        --Old behaviour with filters
        settings.isFilterOn[p_filterId] = p_value
        if settings.debug then FCOIS.debugMessage( "[SetSettingsIsFilterOn] FilterId: " .. tostring(p_filterId) .. ", Value: " .. tostring(p_value), true, FCOIS_DEBUG_DEPTH_SPAM) end
    end
    --return the value
    return p_value
end

-- Check the settings for the panels and return if they are enabled or disabled (e.g. the filter buttons [filters])
function FCOIS.getFilterWhereBySettings(p_filterWhere, onlyAnti)
    p_filterWhere = p_filterWhere or FCOIS.gFilterWhere
    onlyAnti = onlyAnti or false

    local settingsAllowed = FCOIS.settingsVars.settings
    if onlyAnti == false then
        --Set the resultVar and update the FCOIS.settingsVars.settings.atPanelEnabled array
        if     (p_filterWhere == LF_INVENTORY or p_filterWhere == LF_BANK_DEPOSIT or p_filterWhere == LF_GUILDBANK_DEPOSIT or p_filterWhere == LF_HOUSE_BANK_DEPOSIT) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowInventoryFilter
        elseif (p_filterWhere == LF_CRAFTBAG) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowCraftBagFilter
        elseif (p_filterWhere == LF_VENDOR_BUY) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowVendorBuyFilter
        elseif (p_filterWhere == LF_VENDOR_SELL) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowVendorFilter
        elseif (p_filterWhere == LF_VENDOR_BUYBACK) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowVendorBuybackFilter
        elseif (p_filterWhere == LF_VENDOR_REPAIR) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowVendorRepairFilter
        elseif (p_filterWhere == LF_FENCE_SELL) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowFenceFilter
        elseif (p_filterWhere == LF_FENCE_LAUNDER) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowLaunderFilter
        elseif (p_filterWhere == LF_SMITHING_REFINE ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowRefinementFilter
        elseif (p_filterWhere == LF_SMITHING_DECONSTRUCT ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowDeconstructionFilter
        elseif (p_filterWhere == LF_SMITHING_IMPROVEMENT ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowImprovementFilter
        elseif (p_filterWhere == LF_ENCHANTING_EXTRACTION ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowEnchantingFilter
        elseif (p_filterWhere == LF_ENCHANTING_CREATION ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowEnchantingFilter
        elseif (p_filterWhere == LF_BANK_WITHDRAW) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowBankFilter
        elseif (p_filterWhere == LF_GUILDBANK_WITHDRAW) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowGuildBankFilter
        elseif (p_filterWhere == LF_GUILDSTORE_SELL) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowTradinghouseFilter
        elseif (p_filterWhere == LF_TRADE) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowTradeFilter
        elseif (p_filterWhere == LF_MAIL_SEND) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowMailFilter
        elseif (p_filterWhere == LF_ALCHEMY_CREATION) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowAlchemyFilter
        elseif (p_filterWhere == LF_RETRAIT) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowRetraitFilter
        elseif (p_filterWhere == LF_HOUSE_BANK_WITHDRAW) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowBankFilter
        elseif (p_filterWhere == LF_JEWELRY_REFINE ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowJewelryRefinementFilter
        elseif (p_filterWhere == LF_JEWELRY_DECONSTRUCT ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowJewelryDeconstructionFilter
        elseif (p_filterWhere == LF_JEWELRY_IMPROVEMENT ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowJewelryImprovementFilter
        end
    end

    if settingsAllowed.debug then FCOIS.debugMessage( "[FCOIS.getFilterWhereBySettings] " .. tostring(p_filterWhere) .. " = " .. tostring(settingsAllowed.atPanelEnabled[p_filterWhere]["filters"]), true, FCOIS_DEBUG_DEPTH_SPAM) end
    return p_filterWhere
end

--Function to reset the ANTI settings for the normal inventory
function FCOIS.resetInventoryAntiSettings(currentSceneState)
    if currentSceneState == SCENE_SHOWING then
        FCOIS.autoReenableAntiSettingsCheck("DESTROY")
    elseif currentSceneState == SCENE_HIDDEN then
        if FCOIS.gFilterWhere == LF_RETRAIT then
            FCOIS.autoReenableAntiSettingsCheck("RETRAIT")
        end
    end
end

--This function will change the actual ANTI-DETSROY etc. settings according to the active filter panel ID (inventory, vendor, mail, trade, bank, etc.)
function FCOIS.changeAntiSettingsAccordingToFilterPanel()
    if FCOIS.gFilterWhere == nil then return false end
--d("[FCOIS.changeAntiSettingsAccordingToFilterPanel - FilterPanel: " .. FCOIS.gFilterWhere .. ", FilterPanelParent: " .. tostring(FCOIS.gFilterWhereParent))

    local currentSettings = FCOIS.settingsVars.settings
    local isSettingEnabled = false

    --Get the current FCOIS.settingsVars.settings state and inverse them
    if   FCOIS.gFilterWhere == LF_INVENTORY or FCOIS.gFilterWhere == LF_BANK_WITHDRAW or FCOIS.gFilterWhere == LF_GUILDBANK_WITHDRAW
        or FCOIS.gFilterWhere == LF_BANK_DEPOSIT or FCOIS.gFilterWhere == LF_GUILDBANK_DEPOSIT or FCOIS.gFilterWhere == LF_HOUSE_BANK_WITHDRAW then
        FCOIS.settingsVars.settings.blockDestroying = not currentSettings.blockDestroying
        isSettingEnabled = FCOIS.settingsVars.settings.blockDestroying

    --CraftBag and CraftBagExtended addon
    elseif FCOIS.gFilterWhere == LF_CRAFTBAG then
        --As the CraftBag can be active at the mail send, trade, guild store sell and guild bank panels too we need to check if we are currently using the
        --addon CraftBagExtended and if the parent panel ID (FCOIS.gFilterWhereParent) is one of the above mentioned
        -- -> See callback function for CRAFT_BAG_FRAGMENT in the PreHooks section!
        if FCOIS.checkIfCBEorAGSActive(FCOIS.gFilterWhereParent) then
            local parentPanel = FCOIS.gFilterWhereParent
            --The parent panel for the craftbag is the bank deposit panel
            --or the parent panel for the craftbag is the guild bank deposit panel
            if 	parentPanel == LF_BANK_DEPOSIT or parentPanel == LF_GUILDBANK_DEPOSIT then
                FCOIS.settingsVars.settings.blockDestroying = not currentSettings.blockDestroying
                isSettingEnabled = FCOIS.settingsVars.settings.blockDestroying
            --The parent panel for the craftbag is the mail send panel
            elseif	parentPanel == LF_MAIL_SEND then
                FCOIS.settingsVars.settings.blockSendingByMail = not currentSettings.blockSendingByMail
                isSettingEnabled = FCOIS.settingsVars.settings.blockSendingByMail
            --The parent panel for the craftbag is the guild store sell panel
            elseif	parentPanel == LF_GUILDSTORE_SELL then
                FCOIS.settingsVars.settings.blockSellingGuildStore = not currentSettings.blockSellingGuildStore
                isSettingEnabled = FCOIS.settingsVars.settings.blockSellingGuildStore
            --The parent panel for the craftbag is the trade panel
            elseif	parentPanel == LF_TRADE then
                FCOIS.settingsVars.settings.blockTrading = not currentSettings.blockTrading
                isSettingEnabled = FCOIS.settingsVars.settings.blockTrading
            end
        else
            FCOIS.settingsVars.settings.blockDestroying = not currentSettings.blockDestroying
            isSettingEnabled = FCOIS.settingsVars.settings.blockDestroying
        end

    elseif FCOIS.gFilterWhere == LF_VENDOR_SELL then
        FCOIS.settingsVars.settings.blockSelling = not currentSettings.blockSelling
        isSettingEnabled = FCOIS.settingsVars.settings.blockSelling
    elseif FCOIS.gFilterWhere == LF_FENCE_SELL then
        FCOIS.settingsVars.settings.blockFence = not currentSettings.blockFence
        isSettingEnabled = FCOIS.settingsVars.settings.blockFence
    elseif FCOIS.gFilterWhere == LF_FENCE_LAUNDER then
        FCOIS.settingsVars.settings.blockLaunder = not currentSettings.blockLaunder
        isSettingEnabled = FCOIS.settingsVars.settings.blockLaunder
    elseif FCOIS.gFilterWhere == LF_SMITHING_REFINE then
        FCOIS.settingsVars.settings.blockRefinement = not currentSettings.blockRefinement
        isSettingEnabled = FCOIS.settingsVars.settings.blockRefinement
    elseif FCOIS.gFilterWhere == LF_SMITHING_DECONSTRUCT then
        FCOIS.settingsVars.settings.blockDeconstruction = not currentSettings.blockDeconstruction
        isSettingEnabled = FCOIS.settingsVars.settings.blockDeconstruction
    elseif FCOIS.gFilterWhere == LF_SMITHING_IMPROVEMENT then
        FCOIS.settingsVars.settings.blockImprovement = not currentSettings.blockImprovement
        isSettingEnabled = FCOIS.settingsVars.settings.blockImprovement
    elseif FCOIS.gFilterWhere == LF_GUILDSTORE_SELL then
        FCOIS.settingsVars.settings.blockSellingGuildStore = not currentSettings.blockSellingGuildStore
        isSettingEnabled = FCOIS.settingsVars.settings.blockSellingGuildStore
    elseif FCOIS.gFilterWhere == LF_MAIL_SEND then
        FCOIS.settingsVars.settings.blockSendingByMail = not currentSettings.blockSendingByMail
        isSettingEnabled = FCOIS.settingsVars.settings.blockSendingByMail
    elseif FCOIS.gFilterWhere == LF_TRADE then
        FCOIS.settingsVars.settings.blockTrading = not currentSettings.blockTrading
        isSettingEnabled = FCOIS.settingsVars.settings.blockTrading
    elseif FCOIS.gFilterWhere == LF_ENCHANTING_CREATION then
        FCOIS.settingsVars.settings.blockEnchantingCreation = not currentSettings.blockEnchantingCreation
        isSettingEnabled = FCOIS.settingsVars.settings.blockEnchantingCreation
    elseif FCOIS.gFilterWhere == LF_ENCHANTING_EXTRACTION then
        FCOIS.settingsVars.settings.blockEnchantingExtraction = not currentSettings.blockEnchantingExtraction
        isSettingEnabled = FCOIS.settingsVars.settings.blockEnchantingExtraction
    elseif FCOIS.gFilterWhere == LF_RETRAIT then
        FCOIS.settingsVars.settings.blockRetrait = not currentSettings.blockRetrait
        isSettingEnabled = FCOIS.settingsVars.settings.blockRetrait
    elseif FCOIS.gFilterWhere == LF_JEWELRY_REFINE then
        FCOIS.settingsVars.settings.blockJewelryRefinement = not currentSettings.blockJewelryRefinement
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryRefinement
    elseif FCOIS.gFilterWhere == LF_JEWELRY_DECONSTRUCT then
        FCOIS.settingsVars.settings.blockJewelryDeconstruction = not currentSettings.blockJewelryDeconstruction
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryDeconstruction
    elseif FCOIS.gFilterWhere == LF_JEWELRY_IMPROVEMENT then
        FCOIS.settingsVars.settings.blockJewelryImprovement = not currentSettings.blockJewelryImprovement
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryImprovement
    else
        FCOIS.settingsVars.settings.blockDestroying = not currentSettings.blockDestroying
        isSettingEnabled = FCOIS.settingsVars.settings.blockDestroying
    end

    --Check if the settings are enabled now and if any item is slotted in the deconstruction/improvement/extraction/refine slot
    --> Then remove the item from the slot again if it's protected again now
    if isSettingEnabled then
        --Get the bagId and slotIndex of a slotted item
        local bagId, slotIndex = FCOIS.craftingPrevention.GetSlottedItemBagAndSlot()
        if bagId ~= nil and slotIndex ~= nil then
            --Then check if they are protected and remove them from the slot again
            FCOIS.craftingPrevention.IsItemProtectedAtACraftSlotNow(bagId, slotIndex)
        end
    end
end

--Function to reenable the Anti-* settings again
function FCOIS.autoReenableAntiSettingsCheck(checkWhere)
    --d("[FCOIS.autoReenableAntiSettingsCheck - checkWhere: " .. tostring(checkWhere) .. ", lootListIsHidden: " .. tostring(ZO_LootAlphaContainerList:IsHidden()) .. ", dontAutoReenableAntiSettings: " .. tostring(FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory))
    if checkWhere == nil or checkWhere == "" then return false end
    --Should all checks be done now?
    if checkWhere == "-ALL-" then
        local checksToDo = {
            [1] = "CRAFTING_STATION",
            [2] = "STORE",
            [3]	= "GUILD_STORE",
            [4] = "DESTROY",
            [5] = "TRADE",
            [6] = "MAIL",
            [7] = "RETRAIT",
        }
        --Get the checks to do and run them all after each other
        for _, checkWhereNow in ipairs(checksToDo) do
            if checkWhereNow ~= "-ALL-" then
                FCOIS.autoReenableAntiSettingsCheck(checkWhereNow)
            end
        end
        return true
    end
    local settings = FCOIS.settingsVars.settings
    if checkWhere == "CRAFTING_STATION" then
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

    elseif checkWhere == "STORE" then
        --Reenable the Anti-Sell methods if activated in the settings
        if settings.autoReenable_blockSelling then
            settings.blockSelling = true
        end
        --Reenable the Fence Anti-Sell methods if activated in the settings
        if settings.autoReenable_blockFenceSelling then
            settings.blockFence = true
        end
        --Reenable the Fence Anti-Laundering methods if activated in the settings
        if settings.autoReenable_blockLaunderSelling then
            settings.blockLaunder = true
        end

    elseif checkWhere == "GUILD_STORE" then
        --Reenable the Anti-Sell methods if activated in the settings
        if settings.autoReenable_blockSellingGuildStore then
            settings.blockSellingGuildStore = true
        end

    elseif checkWhere == "MAIL" then
        --Reenable the Anti-Mail methods if activated in the settings
        if settings.autoReenable_blockSendingByMail then
            settings.blockSendingByMail = true
        end

    elseif checkWhere == "TRADE" then
        --Reenable the Anti-Trade methods if activated in the settings
        if settings.autoReenable_blockTrading then
            settings.blockTrading = true
        end

    elseif checkWhere == "RETRAIT" then
        --Reenable the Anti-Retrait methods if activated in the settings
        if settings.autoReenable_blockRetrait then
            settings.blockRetrait = true
        end

    elseif checkWhere == "DESTROY" then
        --Reenable the Anti-Destroy methods if activated in the settings
        --but do not enable it as we come back to the inventory from a container loot scene
        if not FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory then
            if settings.autoReenable_blockDestroying then
                settings.blockDestroying = true
            end
        end
        FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory = false
    end
    --Workaround to enable the correct additional inventory context menu invoker button color for the normal inventory again
    FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
end


--==========================================================================================================================================
-- 															Scan and transfer / migrate
--==========================================================================================================================================


--Transfer the non-unique/unique to unique/non-unique marker icons at the items
--> Button in the FCOIS_SettingsMenu.lua, "General settings"
local function scanBagsAndTransferMarkerIcon(toUnique)
    if toUnique == nil then return false end
    --Check the bag
    local bagsToCheck = {
        [0] = BAG_WORN,
        [1] = BAG_BACKPACK,
        [2] = BAG_BANK,
        --[3] = BAG_GUILDBANK,
    }
    --Is the user an ESO+ subscriber?
    if IsESOPlusSubscriber() then
        --Add the subscriber bank to the inventories to check
        if GetBagUseableSize(BAG_SUBSCRIBER_BANK) > 0 then
            local ind = #bagsToCheck + 1
            bagsToCheck[ind] = BAG_SUBSCRIBER_BANK
        end
    end
    local locVars = FCOIS.localizationVars.fcois_loc
    --Loop over all bag types
    for _, bagToCheck in pairs(bagsToCheck) do
        local numMigratedIcons = 0
        local numMigratedItems = 0
        --Migration started for bag type
        d(FCOIS.preChatVars.preChatTextGreen .. zo_strformat(locVars["options_migrate_start"], locVars["options_migrate_bag_type_" .. bagToCheck]))
        --local bagCache = SHARED_INVENTORY:GenerateFullSlotData(nil, bagToCheck)
        local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagToCheck)
        --Loop over the bag items and check each item in the bag for marker icons
        for _, data in pairs(bagCache) do
            local itemId
            local itemIdNew
            --Transfer marker icon to unique ID
            if toUnique then
                --Build the item ID (ItemInstanceId)
                local itemInstanceId = GetItemInstanceId(data.bagId, data.slotIndex)
                itemId = FCOIS.SignItemId(itemInstanceId, false, true)
                local uniqueId = zo_getSafeId64Key(GetItemUniqueId(data.bagId, data.slotIndex))
                itemIdNew = uniqueId

            --Transfer marker icon to non-unique ID
            else
                local uniqueId = zo_getSafeId64Key(GetItemUniqueId(data.bagId, data.slotIndex))
                itemId = uniqueId
                local itemInstanceId = GetItemInstanceId(data.bagId, data.slotIndex)
                itemIdNew = FCOIS.SignItemId(itemInstanceId, false, true)

            end
            --Is the itemId (unique or non-unique) given?
            if itemId ~= nil and itemIdNew ~= nil then
                local increaseNumMigratedItems = true
                --Check if the item is marked with any icon
                for iconId = 1, FCOIS.numVars.gFCONumFilterIcons, 1 do
                    local isMarked = FCOIS.markedItems[iconId][itemId]
                    if isMarked == nil then isMarked = false end
                    --Is the icon marked?
                    if isMarked then
                        --Transfer the marker icon from the old one to the new one
                        FCOIS.markedItems[iconId][itemIdNew] = true
                        numMigratedIcons = numMigratedIcons + 1
                        if increaseNumMigratedItems then
                            numMigratedItems = numMigratedItems + 1
                            increaseNumMigratedItems = false
                        end
                    end
                end
            end
        end
        --Migration results for bag type
        d(FCOIS.preChatVars.preChatTextBlue .. zo_strformat(locVars["options_migrate_results"], numMigratedIcons, numMigratedItems))
        --Migration end for bag type
        d(FCOIS.preChatVars.preChatTextRed .. zo_strformat(locVars["options_migrate_end"], locVars["options_migrate_bag_type_" .. bagToCheck]))
    end -- for bagType
    --Reset the "migration needs to be done" variable
    FCOIS.preventerVars.migrateItemMarkers = false
end

--Migrate the marker icons from the non-unique ItemInstanceIds to the uniqueIds
function FCOIS.migrateItemInstanceIdMarkersToUniqueIdMarkers()
    --Are the unique IDs enabled?
    if FCOIS.settingsVars.settings.useUniqueIds then
        scanBagsAndTransferMarkerIcon(true)
    end
end

--Migrate the marker icons from the non-unique ItemInstanceIds to the uniqueIds
function FCOIS.migrateUniqueIdMarkersToItemInstanceIdMarkers()
    --Are the unique IDs enabled?
    if not FCOIS.settingsVars.settings.useUniqueIds then
        scanBagsAndTransferMarkerIcon(false)
    end
end


--==========================================================================================================================================
-- 															FCOIS USER-SETTINGS (SavedVars)
--==========================================================================================================================================

--Do some "before settings" stuff
function FCOIS.beforeSettings()

end

--Do some "after settings" stuff
function FCOIS.afterSettings()
    local settings = FCOIS.settingsVars.settings
    --Set the split filters to true as old "non-split filters" method is not supported anymore!
    settings.splitFilters = true

    --Preset global variable for item destroying
    FCOIS.preventerVars.gAllowDestroyItem = not settings.blockDestroying
    -- Get the marked items for each filter from the settings (or defaults, if not set yet)
    for markedItemsId = 1, FCOIS.numVars.gFCONumFilterIcons, 1 do
        FCOIS.markedItems[markedItemsId] = settings.markedItems[markedItemsId]
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
    settings.useUniqueIdsToggle = nil

    --Set the variables for each panel where the number of filtered items can be found for the current inventory
    FCOIS.numberOfFilteredItems[LF_INVENTORY]              = ZO_PlayerInventoryList.data
    --Same like inventory
    FCOIS.numberOfFilteredItems[LF_MAIL_SEND]              = FCOIS.numberOfFilteredItems[LF_INVENTORY]
    FCOIS.numberOfFilteredItems[LF_TRADE]                  = FCOIS.numberOfFilteredItems[LF_INVENTORY]
    FCOIS.numberOfFilteredItems[LF_GUILDSTORE_SELL]        = FCOIS.numberOfFilteredItems[LF_INVENTORY]
    FCOIS.numberOfFilteredItems[LF_BANK_DEPOSIT]           = FCOIS.numberOfFilteredItems[LF_INVENTORY]
    FCOIS.numberOfFilteredItems[LF_VENDOR_SELL]            = FCOIS.numberOfFilteredItems[LF_INVENTORY]
    FCOIS.numberOfFilteredItems[LF_FENCE_SELL]             = FCOIS.numberOfFilteredItems[LF_INVENTORY]
    FCOIS.numberOfFilteredItems[LF_FENCE_LAUNDER]          = FCOIS.numberOfFilteredItems[LF_INVENTORY]
    --Others
    FCOIS.numberOfFilteredItems[LF_BANK_WITHDRAW]          = ZO_PlayerBankBackpack.data
    FCOIS.numberOfFilteredItems[LF_GUILDBANK_WITHDRAW]     = ZO_GuildBankBackpack.data
    FCOIS.numberOfFilteredItems[LF_SMITHING_REFINE]        = ZO_SmithingTopLevelRefinementPanelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_SMITHING_DECONSTRUCT]   = ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_SMITHING_IMPROVEMENT]   = ZO_SmithingTopLevelImprovementPanelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_ALCHEMY_CREATION]       = ZO_AlchemyTopLevelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_ENCHANTING_CREATION]    = ZO_EnchantingTopLevelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_ENCHANTING_EXTRACTION]  = ZO_EnchantingTopLevelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_CRAFTBAG]               = ZO_CraftBagList.data
    FCOIS.numberOfFilteredItems[LF_RETRAIT]                = ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_HOUSE_BANK_WITHDRAW]    = ZO_HouseBankBackpack.data
    FCOIS.numberOfFilteredItems[LF_JEWELRY_REFINE]         = ZO_SmithingTopLevelRefinementPanelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_JEWELRY_DECONSTRUCT]    = ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack.data
    FCOIS.numberOfFilteredItems[LF_JEWELRY_IMPROVEMENT]    = ZO_SmithingTopLevelImprovementPanelInventoryBackpack.data

    --The crafting station creation panel controls or a function to check if it's currently active
    FCOIS.craftingCreatePanelControlsOrFunction = {
        [CRAFTING_TYPE_ALCHEMY]         = FCOIS.IsAlchemyPanelCreationShown,
        [CRAFTING_TYPE_BLACKSMITHING] 	= FCOIS.ZOControlVars.CRAFTING_CREATION_PANEL,
        [CRAFTING_TYPE_CLOTHIER] 		= FCOIS.ZOControlVars.CRAFTING_CREATION_PANEL,
        [CRAFTING_TYPE_ENCHANTING] 		= FCOIS.IsEnchantingPanelCreationShown,
        [CRAFTING_TYPE_INVALID] 		= FCOIS.ZOControlVars.CRAFTING_CREATION_PANEL,
        [CRAFTING_TYPE_PROVISIONING] 	= FCOIS.ZOControlVars.PROVISIONER_PANEL,
        [CRAFTING_TYPE_WOODWORKING] 	= FCOIS.ZOControlVars.CRAFTING_CREATION_PANEL,
        [CRAFTING_TYPE_JEWELRYCRAFTING]	= FCOIS.ZOControlVars.CRAFTING_CREATION_PANEL,
    }

    --Rebuild the allowed craft skills from the settings
    FCOIS.rebuildAllowedCraftSkillsForCraftedMarking()

------------------------------------------------------------------------------------------------------------------------
--  Build the additional inventory "flag" context menu button data
------------------------------------------------------------------------------------------------------------------------
    --Constants
    local addInvBtnInvokers = FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker
    local apiVersion = FCOIS.APIversion
    local ancVars = FCOIS.anchorVars
    local locVars = FCOIS.localizationVars.fcois_loc
    --Non changing values
    local showAddInvContextMenuFunc = FCOIS.showContextMenuForAddInvButtons
    local showAddInvContextMenuMouseUpFunc = FCOIS.onContextMenuForAddInvButtonsButtonMouseUp
    local mouseButtonRight = MOUSE_BUTTON_INDEX_RIGHT
    local text
    local font
    local tooltip = locVars["button_context_menu_tooltip"]
    local anchorTooltip = RIGHT
    local texNormal = "/esoui/art/ava/tabicon_bg_score_inactive.dds"
    local texMouseOver = "/esoui/art/ava/tabicon_bg_score_disabled.dds"
    local texClicked = texMouseOver
    local width  = 32
    local height = 32
    local alignMain = BOTTOM
    local alignBackup = TOP
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
            buttonData.alignMain = alignMain
            buttonData.alignBackup = alignBackup
            buttonData.alignControl = ancVars.additionalInventoryFlagButton[apiVersion][panelId].anchorControl
            buttonData.hideButton = doHide
        end
    end
end

--Do some updates to the SavedVariables before the addon menu is created
function FCOIS.updateSettingsBeforeAddonMenu()
    --SetTracker addon
    --Support for addon 'SetTracker': Get the number of allowed indices of SetTracker and
    --build a mapping array for SetTracker index -> FCOIS marker icon
    if FCOIS.otherAddons.SetTracker.isActive and SetTrack and SetTrack.GetMaxTrackStates then
        local STtrackingStates = SetTrack.GetMaxTrackStates()
        for i=0, (STtrackingStates-1), 1 do
            if FCOIS.settingsVars.settings.setTrackerIndexToFCOISIcon[i] == nil then
                FCOIS.settingsVars.settings.setTrackerIndexToFCOISIcon[i] = 1
            end
        end

        --BagId to SetTracker addon settings in FCOIS
        FCOIS.mappingVars.bagToSetTrackerSettings = {
            [BAG_WORN]		        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsWorn,
            [BAG_BACKPACK]	        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsInv,
            [BAG_BANK]		        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsBank,
            [BAG_GUILDBANK]	        = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsGuildBank,
            [BAG_SUBSCRIBER_BANK]   = FCOIS.settingsVars.settings.autoMarkSetTrackerSetsBank,
        }
    end
    --Introduced with FCOIS v0.8.8b
    --Create the armor, jewelry and weapon trait automatic marking arrays and preset them with "true",
    --so all armor, jewelry and weapon set pats will be marked
    --Armor
    local armorTraits = FCOIS.mappingVars.traits.armorTraits
    --Jewelry
    local jewelryTraits = FCOIS.mappingVars.traits.jewelryTraits
    --Weapons
    local weaponTraits = FCOIS.mappingVars.traits.weaponTraits
    --Shields
    local weaponShieldTraits = FCOIS.mappingVars.traits.weaponShieldTraits
    --The chosne icon for the set parts
    local chosenSetIcon = FCOIS.settingsVars.settings.autoMarkSetsIconNr
    --Check armor
    for armorTraitNumber, _ in pairs(armorTraits) do
        if FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTrait[armorTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTrait[armorTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTraitIcon[armorTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTraitIcon[armorTraitNumber] = chosenSetIcon
        end
    end
    --Check jewelry
    for jewelryTraitNumber, _ in pairs(jewelryTraits) do
        if FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTrait[jewelryTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTrait[jewelryTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTraitIcon[jewelryTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTraitIcon[jewelryTraitNumber] = chosenSetIcon
        end
    end
    --Check weapons
    for weaponTraitNumber, _ in pairs(weaponTraits) do
        if FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[weaponTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[weaponTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTraitIcon[weaponTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTraitIcon[weaponTraitNumber] = chosenSetIcon
        end
    end
    --Check shields
    for weaponShieldTraitNumber, _ in pairs(weaponShieldTraits) do
        if FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[weaponShieldTraitNumber] == nil then
            FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[weaponShieldTraitNumber] = true
        end
        --Preset the icon for the trait, if not chosen yet
        if FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTraitIcon[weaponShieldTraitNumber] == nil then
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
function FCOIS.LoadUserSettings(calledFromExternal)
    calledFromExternal = calledFromExternal or false
    if calledFromExternal then FCOIS.addonVars.gSettingsLoaded = false end
    if not FCOIS.addonVars.gSettingsLoaded then
        --Build the default settings
        FCOIS.buildDefaultSettings()

        --Get the server name
        FCOIS.worldName = GetWorldName()
        local world = FCOIS.worldName

        --Call the "Before SavedVars loading" function (e.g. migrate non-server dependent settings to server settings)
        FCOIS.beforeSettings()

        --=========== BEGIN - SAVED VARIABLES ==========================================
        FCOIS.settingsVars.defaultSettings = {}
        FCOIS.settingsVars.settings = {}
        --------------------------------------------------------------------------------------------------------------------
        -- Migration of non-server dependent settings to server-dependent settings
        --------------------------------------------------------------------------------------------------------------------
        FCOIS.defSettingsNonServerDependendFound = false
        FCOIS.settingsNonServerDependendFound    = false
        local checkForMigrateDefDefaults    = { ["saveMode"] = 999 }                -- Set easy to check value for defaults to check if SavedVars were already there or not
        local checkForMigrateDefaults       = { ["alwaysUseClientLanguage"] = 999 } -- Set easy to check value for defaults to check if SavedVars were already there or not

        --Added with FCOIS version 1.3.5: Server saved settings (EU, NA, PTS)
        --Load the Non-Server dependent savedvars (from the SavedVars["default"] profile), if they exist.
        -- !!! Do NOT specify default "fallback" values as then the defaults would be ALWAYS found and used !!!
        --Load the old user's default settings from SavedVariables file -> Account wide of basic version 999 at first, without Servername as last parameter, to get existing data
        local oldDefaultSettings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", 999, "SettingsForAll", checkForMigrateDefDefaults)
        --Check, by help of basic version 999, if the settings should be loaded for each character or account wide
        --Use the current addon version to read the FCOIS.settingsVars.settings now
        local oldSettings = {}
        --Load the old user's settings from SavedVariables file -> Account/Character data, depending on the old defaultSettings, without Servername as last parameter, to get existing data
        if (oldDefaultSettings.saveMode == 1) then
            --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
            oldSettings = ZO_SavedVars:NewCharacterIdSettings(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion , "Settings", checkForMigrateDefaults)
            --Transfer the data from the name to the unique ID SavedVars now
            NamesToIDSavedVars()
        elseif (oldDefaultSettings.saveMode == 2) then
            oldSettings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", checkForMigrateDefaults)
        else
            oldSettings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", checkForMigrateDefaults)
        end

        --If non-server dependent settings were found
        --Check if they are not only containing the "version" or "GetInterfaceForCharacter" entries which always get
        --created with new SavedVars (even if they do not contain any other values or defaults)
        local freshFCOISInstall = false
        if oldDefaultSettings ~= nil and oldSettings ~= nil then
            --Is the entry "saveMode" given? Need to migrate old data then!
            if oldDefaultSettings["saveMode"] ~= 999 then
                FCOIS.defSettingsNonServerDependendFound = true
            else
                freshFCOISInstall = true
            end
            --Is the entry "markedItems" given? Need to migrate old data then!
            if oldSettings["alwaysUseClientLanguage"] ~= 999 then
                FCOIS.settingsNonServerDependendFound = true
            else
                freshFCOISInstall = true
            end
        else
            freshFCOISInstall = true
        end
        local displayName = GetDisplayName()
        if string.find(displayName, "@") ~= 1 then
            displayName = "@" .. displayName
        end

        --If server dependent settings were found or it's a new installation of FCOIS
        if freshFCOISInstall or (FCOIS.defSettingsNonServerDependendFound == false and FCOIS.settingsNonServerDependendFound == false) then
            --d("[FCOIS]Using server (" .. world .. ") dependent SavedVars")
            --Reset the old default non-server dependent settings
            FCOItemSaver_Settings["Default"] = nil
            --Get the new server dependent settings
            --Load the user's settings from SavedVariables file -> Account wide of basic version 999 at first
            FCOIS.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", 999, "SettingsForAll", FCOIS.settingsVars.firstRunSettings, world)
            --Check, by help of basic version 999, if the settings should be loaded for each character or account wide
            --Use the current addon version to read the FCOIS.settingsVars.settings now
            if (FCOIS.settingsVars.defaultSettings.saveMode == 1) then
                --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion , "Settings", FCOIS.settingsVars.defaults, world)
                --Transfer the data from the name to the unique ID SavedVars now
                NamesToIDSavedVars(world)

            elseif (FCOIS.settingsVars.defaultSettings.saveMode == 2) then
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", FCOIS.settingsVars.defaults, world)
            else
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", FCOIS.settingsVars.defaults, world)
            end

        --Non-server dependent settings were found. Migrate them to server dependent ones
        else
            -- Disable non-server dependent settings and save them to the server dependent ones now
            d("|cFF0000>>=====================================================>>|r")
            d("[FCOIS]Found non-server dependent SavedVars -> Migrating them now to server (" .. world .. ") dependent settings")
            local defSettings = {}
            --First the settings for all
            --Copy the non-server dependent SV data determined above to a new table without "link"
            local oldDefSettings = FCOItemSaver_Settings["Default"][displayName]["$AccountWide"]["SettingsForAll"]
            local currentNonServerDependentDefSettingsCopy = ZO_DeepTableCopy(oldDefSettings)
            --Reset the non-server dependent savedvars now! -> See confirmation dialog below
            --FCOItemSaver_Settings["Default"][displayName]["$AccountWide"]["SettingsForAll"] = nil -- if you want to only remove the settings, otherwise just nil one of the parent tables
            FCOIS.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", 999, "SettingsForAll", currentNonServerDependentDefSettingsCopy, world)
            --Then the other settings
            --Copy the non-server dependent SV data determined above to a new table without "link"
            oldSettings = FCOItemSaver_Settings["Default"][displayName]["$AccountWide"]["Settings"]
            local currentNonServerDependentSettingsCopy = ZO_DeepTableCopy(oldSettings)
            --Reset the non-server dependent savedvars now! -> See confirmation dialog below
            --FCOItemSaver_Settings["Default"][displayName]["$AccountWide"]["Settings"] = nil -- if you want to only remove the settings, otherwise just nil one of the parent tables
            --FCOItemSaver_Settings["Default"] = nil --reset the whole table now

            --Initialize the server-dependent settings with no values
            if (oldDefSettings.saveMode == 1) then
                --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion , "Settings", currentNonServerDependentSettingsCopy, world)
            elseif (oldDefSettings.saveMode == 2) then
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", currentNonServerDependentSettingsCopy, world)
            else
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", currentNonServerDependentSettingsCopy, world)
            end
            --d("[FCOIS]SavedVars were migrated:\nPlease either type /reloadui into the chat and press the RETURN key,\n or logout now in order to save the data to your SavedVariables properly!")
            --Show UI dialog now too
            local locVars = FCOIS.localizationVars.fcois_loc
            local preVars = FCOIS.preChatVars
            local title = preVars.preChatTextRed .. "?> SavedVariables migration to server: " .. world
            local body = locVars["options_migrate_settings_ask_before_to_server"]
            --Show confirmation dialog: Migration to server dependent savedvariables done. Reload UI now?
            --FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
            FCOIS.ShowConfirmationDialog("ReloadUIAfterSavedVarsMigration", title, body,
                --Yes button
                function()
                    --Clear the non-server depenent SavedVars now
                    FCOItemSaver_Settings["Default"] = nil --reset the whole table now
                    --Reload the UI
                    ReloadUI()
                end,
                --Abort/No button was pressed
                function()
                    --Clear the server dependent data
                    FCOItemSaver_Settings[world] = nil

                    --Revert the savedvars to non-server dependent
                    FCOItemSaver_Settings["Default"][displayName]["$AccountWide"]["SettingsForAll"] = currentNonServerDependentDefSettingsCopy
                    FCOItemSaver_Settings["Default"][displayName]["$AccountWide"]["Settings"]       = currentNonServerDependentSettingsCopy
                    --Assign the current SavedVards properly to the internally used variables of FCOIS again, but without server name (-> last parameter = nil, use "default" table key!
                    if (oldDefSettings.saveMode == 1) then
                        --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                        FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion , "Settings", currentNonServerDependentSettingsCopy, nil)
                    elseif (oldDefSettings.saveMode == 2) then
                        FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", currentNonServerDependentSettingsCopy, nil)
                    else
                        FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(FCOIS.addonVars.gAddonName .. "_Settings", FCOIS.addonVars.savedVarVersion, "Settings", currentNonServerDependentSettingsCopy, nil)
                    end
                    d("[FCOIS]!!! SavedVars were not migrated now !!!\nYou are still using the non-server dependent settings!\nPlease reload the UI to see the migration dialog again.")
                    d("|cFF0000<<=====================================================<<|r")
                end
            )
        end
        --=========== END - SAVED VARIABLES ============================================

        --Load the current needed workarounds/fixes
        FCOIS.LoadWorkarounds()

        --Do some "after settings "stuff
        FCOIS.afterSettings()

        --Set settings = loaded
        FCOIS.addonVars.gSettingsLoaded = true
    end
    if calledFromExternal then FCOIS.addonVars.gSettingsLoaded = false end
    --=============================================================================================================
end

--Copy SavedVariables from one server to another
function FCOIS.copySavedVarsFromServerToServer(srcServer, targServer, onlyDelete)
    onlyDelete = onlyDelete or false
    if srcServer == nil or targServer == nil or srcServer == targServer or (srcServer == 1 and not onlyDelete) or targServer == 1 then return nil end
    --Map the server settings ID from the LAM panel to it's name
    local mapServerSettingIdToName = FCOIS.mappingVars.serverNames
    local srcServerName = mapServerSettingIdToName[srcServer]
    local targServerName = mapServerSettingIdToName[targServer]
    if srcServerName == nil or srcServerName == "" or targServerName == nil or targServerName == "" then return nil end

--d("[FCOIS.copySavedVarsFromServerToServer]srcServer: " .. tostring(srcServerName) .. ", targServer: " ..tostring(targServerName).. ", onlyDelete: " .. tostring(onlyDelete))

    local settingsVars = FCOIS.settingsVars
    local settings = settingsVars.settings
    local useAccountWideSV = (settingsVars.defaultSettings.saveMode == 2) or false
    local displayName = GetDisplayName()
    local svDefToCopy = {}
    local svToCopy = {}
    local svDefTarget = {}
    local svTarget = {}
    local currentlyLoggedInUserId = 0

    --Account wide settings enabled?
    if not onlyDelete then
        if useAccountWideSV then
            svDefToCopy = FCOItemSaver_Settings[srcServerName][displayName]["$AccountWide"]["SettingsForAll"]
            svToCopy    = FCOItemSaver_Settings[srcServerName][displayName]["$AccountWide"]["Settings"]
        else
            --Character settings enabled. Get the currently logged in character ID
            currentlyLoggedInUserId = FCOIS.getCurrentlyLoggedInCharUniqueId()
            if currentlyLoggedInUserId == nil or currentlyLoggedInUserId == 0 then return nil end
            svDefToCopy = FCOItemSaver_Settings[srcServerName][displayName][currentlyLoggedInUserId]["SettingsForAll"]
            svToCopy    = FCOItemSaver_Settings[srcServerName][displayName][currentlyLoggedInUserId]["Settings"]
        end
    else
        if not useAccountWideSV then
            currentlyLoggedInUserId = FCOIS.getCurrentlyLoggedInCharUniqueId()
            if currentlyLoggedInUserId == nil or currentlyLoggedInUserId == 0 then return nil end
        end
    end
    --Did we find the source server SavedVars data?
    if onlyDelete or (svDefToCopy ~= nil and svToCopy ~= nil) then
        --Check if the data got valid entries
        if onlyDelete or (svDefToCopy["language"] ~= nil and svToCopy["markedItems"] ~= nil) then
            --Source data is valid. Now build the target data
            if useAccountWideSV then
                --Account wide settings
                --Check if def settings are given and reset them, then set them to the source values
                if not onlyDelete then
                    if FCOItemSaver_Settings[targServerName] == nil then FCOItemSaver_Settings[targServerName] = {} end
                    if FCOItemSaver_Settings[targServerName][displayName] == nil then FCOItemSaver_Settings[targServerName][displayName] = {} end
                    if FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"] == nil then FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"] = {} end
                    if FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"]["SettingsForAll"] ~= nil then
                        FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"]["SettingsForAll"] = nil
                    end
                    FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"]["SettingsForAll"] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"]["Settings"] ~= nil then
                        FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"]["Settings"] = nil
                    end
                    FCOItemSaver_Settings[targServerName][displayName]["$AccountWide"]["Settings"] = svToCopy
                else
                    FCOItemSaver_Settings[targServerName] = nil
                end

            else
                --Character settings enabled.
                --Check if def settings are given and reset them, then set them to the source values
                if not onlyDelete then
                    if FCOItemSaver_Settings[targServerName] == nil then FCOItemSaver_Settings[targServerName] = {} end
                    if FCOItemSaver_Settings[targServerName][displayName] == nil then FCOItemSaver_Settings[targServerName][displayName] = {} end
                    if FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId] == nil then FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId] = {} end
                    if FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId]["SettingsForAll"] ~= nil then
                        FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId]["SettingsForAll"] = nil
                    end
                    FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId]["SettingsForAll"] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId]["Settings"] ~= nil then
                        FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId]["Settings"] = nil
                    end
                    FCOItemSaver_Settings[targServerName][displayName][currentlyLoggedInUserId]["Settings"] = svToCopy
                else
                    FCOItemSaver_Settings[targServerName] = nil
                end
            end
            --Now check if we are logged in to the target server and reload the user interface to get the copied data to the internal savedvars
            if not onlyDelete then
                local world = GetWorldName()
                if world == targServerName then
                    local titleVar = "SavedVariables: \"" .. srcServerName ..  "\" -> \"" .. targServerName .. "\""
                    local locVars = FCOIS.localizationVars.fcois_loc
                    local questionVar = zo_strformat(locVars["question_copy_sv_reloadui"], srcServerName, targServerName, tostring(useAccountWideSV))
                    --Show confirmation dialog: ReloadUI now?
                    --FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
                    FCOIS.ShowConfirmationDialog("ReloadUIAfterSVServer2ServerCopyDialog", titleVar, questionVar, function() ReloadUI() end, function() end)
                end
            end
            return true
        end
    end
    return false
end