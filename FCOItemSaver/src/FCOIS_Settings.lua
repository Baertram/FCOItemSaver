--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

--The SavedVariables local name
local addonSVname       = FCOIS.addonVars.savedVarName
local addonSVversion    = FCOIS.addonVars.savedVarVersion

--The allAccounts the same account name
local svDefaultName         = FCOIS.svDefaultName
local svAccountWideName     = FCOIS.svAccountWideName
local svAllAccTheSameAcc    = FCOIS.svAllAccountsName
local svSettingsForAllName  = FCOIS.svSettingsForAllName
local svSettingsName        = FCOIS.svSettingsName
--==========================================================================================================================================
-- 										FCOIS settings & saved variables functions
--==========================================================================================================================================


local function NamesToIDSavedVars(serverWorldName)
    serverWorldName = serverWorldName or svDefaultName
    --Are the character settings enabled? If not abort here
    if (FCOIS.settingsVars.defaultSettings.saveMode ~= 1) then return nil end
    --Did we move the character name settings to character ID settings already?
    if not FCOIS.settingsVars.settings.namesToIDSavedVars then
        local doMove
        local charName
        local displayName = GetDisplayName()
        --Check all the characters of the account
        for i = 1, GetNumCharacters() do
            local name, _, _, _, _, _, _ = GetCharacterInfo(i)
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
        settings.isFilterPanelOn[p_filterPanelNew] = settings.isFilterPanelOn[p_filterPanelNew] or {}
        result = settings.isFilterPanelOn[p_filterPanelNew][p_filterId]
        if result == nil then
            return false
        end
        if settings.debug then FCOIS.debugMessage( "[GetSettingsIsFilterOn]","Filter Panel: " .. tostring(p_filterPanelNew) .. ", FilterId: " .. tostring(p_filterId) .. ", Result: " .. tostring(result), true, FCOIS_DEBUG_DEPTH_SPAM) end
        return result
    end
end

--Set the value of a filter type, and return it
function FCOIS.setSettingsIsFilterOn(p_filterId, p_value, p_filterPanel)
    local p_filterPanelNew = p_filterPanel or FCOIS.gFilterWhere
    local settings = FCOIS.settingsVars.settings
    if (settings.splitFilters == true) then
        --New behaviour with filters
        settings.isFilterPanelOn[p_filterPanelNew] = settings.isFilterPanelOn[p_filterPanelNew] or {}
        settings.isFilterPanelOn[p_filterPanelNew][p_filterId] = p_value
        if settings.debug then FCOIS.debugMessage( "[SetSettingsIsFilterOn]","Filter Panel: " .. tostring(p_filterPanelNew) .. ", FilterId: " .. tostring(p_filterId) .. ", Value: " .. tostring(p_value), true, FCOIS_DEBUG_DEPTH_SPAM) end
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
        FCOIS.settingsVars.settings.atPanelEnabled = FCOIS.settingsVars.settings.atPanelEnabled or {}
        FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere] = FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere] or {}
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
        elseif (p_filterWhere == LF_SMITHING_RESEARCH ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowResearchFilter
        elseif (p_filterWhere == LF_SMITHING_RESEARCH_DIALOG ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowResearchFilter
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
        elseif (p_filterWhere == LF_JEWELRY_RESEARCH ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowJewelryResearchFilter
        elseif (p_filterWhere == LF_JEWELRY_RESEARCH_DIALOG ) then
            FCOIS.settingsVars.settings.atPanelEnabled[p_filterWhere]["filters"] = settingsAllowed.allowJewelryResearchFilter
        end
    end

    if settingsAllowed.debug then FCOIS.debugMessage( "[getFilterWhereBySettings]", tostring(p_filterWhere) .. " = " .. tostring(settingsAllowed.atPanelEnabled[p_filterWhere]["filters"]), true, FCOIS_DEBUG_DEPTH_SPAM) end
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
    local filterPanelId = FCOIS.gFilterWhere
    if filterPanelId == nil then return nil end
    local parentPanel = FCOIS.gFilterWhereParent
--d("[FCOIS.changeAntiSettingsAccordingToFilterPanel - FilterPanel: " .. filterPanelId .. ", FilterPanelParent: " .. tostring(parentPanel))

    local currentSettings = FCOIS.settingsVars.settings
    local isSettingEnabled

    --The anti-destroy settings will be always checked as there are panels like LF_GUILDBANK_DEPOSIT which use the anti-destroy
    --AND anti guiild bank deposit if no rights to withdraw again settings.
    --The filterPanelIds which need to be checked for anti-destroy
    local filterPanelIdsCheckForAntiDestroy = FCOIS.checkVars.filterPanelIdsForAntiDestroy
    --Get the current FCOIS.settingsVars.settings state and inverse them
    local isFilterPanelIdCheckForAntiDestroyNeeded = filterPanelIdsCheckForAntiDestroy[filterPanelId] or false
    if isFilterPanelIdCheckForAntiDestroyNeeded then
        FCOIS.settingsVars.settings.blockDestroying = not currentSettings.blockDestroying
        isSettingEnabled = FCOIS.settingsVars.settings.blockDestroying
    end
    --------------------------------------------------------------------------------------------------------------------
    --CraftBag and CraftBagExtended addon
    if filterPanelId == LF_CRAFTBAG then
        --As the CraftBag can be active at the mail send, trade, guild store sell and guild bank panels too we need to check if we are currently using the
        --addon CraftBagExtended and if the parent panel ID (filterPanelIdParent) is one of the above mentioned
        -- -> See callback function for CRAFT_BAG_FRAGMENT in the PreHooks section!
        if FCOIS.checkIfCBEorAGSActive(parentPanel) then
            --The parent panel for the craftbag is the bank deposit panel
            --or the parent panel for the craftbag is the guild bank deposit panel
            if 	parentPanel == LF_BANK_DEPOSIT or parentPanel == LF_GUILDBANK_DEPOSIT then
                --Do not return a value so that the NIL returned will change the add. inv. context menu "flag" button to be non colored at the CraftBag
                --FCOIS.settingsVars.settings.blockDestroying = not currentSettings.blockDestroying
                --isSettingEnabled = FCOIS.settingsVars.settings.blockDestroying

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
                --The parent panel for the craftbag is the vendor sell panel
            elseif	parentPanel == LF_VENDOR_SELL then
                FCOIS.settingsVars.settings.blockSelling = not currentSettings.blockSelling
                isSettingEnabled = FCOIS.settingsVars.settings.blockSelling
            end
        end
        --------------------------------------------------------------------------------------------------------------------
    elseif filterPanelId == LF_VENDOR_BUY then
        FCOIS.settingsVars.settings.blockVendorBuy = not currentSettings.blockVendorBuy
        isSettingEnabled = FCOIS.settingsVars.settings.blockVendorBuy
    elseif filterPanelId == LF_VENDOR_SELL then
        FCOIS.settingsVars.settings.blockSelling = not currentSettings.blockSelling
        isSettingEnabled = FCOIS.settingsVars.settings.blockSelling
    elseif filterPanelId == LF_VENDOR_BUYBACK then
        FCOIS.settingsVars.settings.blockVendorBuyback = not currentSettings.blockVendorBuyback
        isSettingEnabled = FCOIS.settingsVars.settings.blockVendorBuyback
    elseif filterPanelId == LF_VENDOR_REPAIR then
        FCOIS.settingsVars.settings.blockVendorRepair = not currentSettings.blockVendorRepair
        isSettingEnabled = FCOIS.settingsVars.settings.blockVendorRepair
    elseif filterPanelId == LF_FENCE_SELL then
        FCOIS.settingsVars.settings.blockFence = not currentSettings.blockFence
        isSettingEnabled = FCOIS.settingsVars.settings.blockFence
    elseif filterPanelId == LF_FENCE_LAUNDER then
        FCOIS.settingsVars.settings.blockLaunder = not currentSettings.blockLaunder
        isSettingEnabled = FCOIS.settingsVars.settings.blockLaunder
    elseif filterPanelId == LF_SMITHING_REFINE then
        FCOIS.settingsVars.settings.blockRefinement = not currentSettings.blockRefinement
        isSettingEnabled = FCOIS.settingsVars.settings.blockRefinement
    elseif filterPanelId == LF_SMITHING_DECONSTRUCT then
        FCOIS.settingsVars.settings.blockDeconstruction = not currentSettings.blockDeconstruction
        isSettingEnabled = FCOIS.settingsVars.settings.blockDeconstruction
    elseif filterPanelId == LF_SMITHING_IMPROVEMENT then
        FCOIS.settingsVars.settings.blockImprovement = not currentSettings.blockImprovement
        isSettingEnabled = FCOIS.settingsVars.settings.blockImprovement
    elseif filterPanelId == LF_SMITHING_RESEARCH then
        FCOIS.settingsVars.settings.blockResearch = not currentSettings.blockResearch
        isSettingEnabled = FCOIS.settingsVars.settings.blockResearch
    elseif filterPanelId == LF_SMITHING_RESEARCH_DIALOG then
        FCOIS.settingsVars.settings.blockResearchDialog = not currentSettings.blockResearchDialog
        isSettingEnabled = FCOIS.settingsVars.settings.blockResearch
    elseif filterPanelId == LF_GUILDSTORE_SELL then
        FCOIS.settingsVars.settings.blockSellingGuildStore = not currentSettings.blockSellingGuildStore
        isSettingEnabled = FCOIS.settingsVars.settings.blockSellingGuildStore
    elseif filterPanelId == LF_MAIL_SEND then
        FCOIS.settingsVars.settings.blockSendingByMail = not currentSettings.blockSendingByMail
        isSettingEnabled = FCOIS.settingsVars.settings.blockSendingByMail
    elseif filterPanelId == LF_TRADE then
        FCOIS.settingsVars.settings.blockTrading = not currentSettings.blockTrading
        isSettingEnabled = FCOIS.settingsVars.settings.blockTrading
    elseif filterPanelId == LF_ENCHANTING_CREATION then
        FCOIS.settingsVars.settings.blockEnchantingCreation = not currentSettings.blockEnchantingCreation
        isSettingEnabled = FCOIS.settingsVars.settings.blockEnchantingCreation
    elseif filterPanelId == LF_ENCHANTING_EXTRACTION then
        FCOIS.settingsVars.settings.blockEnchantingExtraction = not currentSettings.blockEnchantingExtraction
        isSettingEnabled = FCOIS.settingsVars.settings.blockEnchantingExtraction
    elseif filterPanelId == LF_RETRAIT then
        FCOIS.settingsVars.settings.blockRetrait = not currentSettings.blockRetrait
        isSettingEnabled = FCOIS.settingsVars.settings.blockRetrait
    elseif filterPanelId == LF_JEWELRY_REFINE then
        FCOIS.settingsVars.settings.blockJewelryRefinement = not currentSettings.blockJewelryRefinement
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryRefinement
    elseif filterPanelId == LF_JEWELRY_DECONSTRUCT then
        FCOIS.settingsVars.settings.blockJewelryDeconstruction = not currentSettings.blockJewelryDeconstruction
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryDeconstruction
    elseif filterPanelId == LF_JEWELRY_IMPROVEMENT then
        FCOIS.settingsVars.settings.blockJewelryImprovement = not currentSettings.blockJewelryImprovement
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryImprovement
    elseif filterPanelId == LF_JEWELRY_RESEARCH then
        FCOIS.settingsVars.settings.blockJewelryResearch = not currentSettings.blockJewelryResearch
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryResearch
    elseif filterPanelId == LF_JEWELRY_RESEARCH_DIALOG then
        FCOIS.settingsVars.settings.blockJewelryResearchDialog = not currentSettings.blockJewelryResearchDialog
        isSettingEnabled = FCOIS.settingsVars.settings.blockJewelryResearch
    elseif filterPanelId == LF_GUILDBANK_DEPOSIT then
        FCOIS.settingsVars.settings.blockGuildBankWithoutWithdraw = not currentSettings.blockGuildBankWithoutWithdraw
        isSettingEnabled = FCOIS.settingsVars.settings.blockGuildBankWithoutWithdraw
    end

--d(">isSettingEnabled: " ..tostring(isSettingEnabled))

    --Check if the settings are enabled now and if any item is slotted in the deconstruction/improvement/extraction/refine slot
    --> Then remove the item from the slot again if it's protected again now
    if isSettingEnabled then
        FCOIS.IsItemProtectedAtASlotNow(nil, nil, false, true)
    end
    return isSettingEnabled
end

--Function to reenable the Anti-* settings again at a given check panel automatically (if the panel closes e.g.)
function FCOIS.autoReenableAntiSettingsCheck(checkWhere)
    --d("[FCOIS.autoReenableAntiSettingsCheck - checkWhere: " .. tostring(checkWhere) .. ", lootListIsHidden: " .. tostring(ZO_LootAlphaContainerList:IsHidden()) .. ", dontAutoReenableAntiSettings: " .. tostring(FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory))
    if checkWhere == nil or checkWhere == "" then return false end
    local checksToDo = FCOIS.checkVars.autoReenableAntiSettingsCheckWheres
    local checksAll = FCOIS.checkVars.autoReenableAntiSettingsCheckWheresAll
    --Should all checks be done now?
    if checkWhere == checksAll then
        --Get the checks to do and run them all after each other
        for _, checkWhereNow in ipairs(checksToDo) do
            if checkWhereNow ~= checksAll then
                FCOIS.autoReenableAntiSettingsCheck(checkWhereNow)
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
        if settings.autoReenable_blockGuildBankWithoutWithdraw then
            settings.blockGuildBankWithoutWithdraw = true
        end
    end
    --Workaround to enable the correct additional inventory context menu invoker button color for the normal inventory again
    --as multiple panels are using the LF_INVENTORY flag (mail, trade, inventory, ...)
    FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
end


--==========================================================================================================================================
-- 															Scan and transfer / migrate
--==========================================================================================================================================


--Transfer the non-unique/unique to unique/non-unique marker icons at the items
--> Started by the button in the FCOIS_SettingsMenu.lua, "General settings"
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
                itemId = FCOIS.SignItemId(itemInstanceId, false, true, nil)
                local uniqueId = zo_getSafeId64Key(GetItemUniqueId(data.bagId, data.slotIndex))
                itemIdNew = uniqueId

            --Transfer marker icon to non-unique ID
            else
                local uniqueId = zo_getSafeId64Key(GetItemUniqueId(data.bagId, data.slotIndex))
                itemId = uniqueId
                local itemInstanceId = GetItemInstanceId(data.bagId, data.slotIndex)
                itemIdNew = FCOIS.SignItemId(itemInstanceId, false, true, nil)

            end
            --Is the itemId (unique or non-unique) given?
            if itemId ~= nil and itemIdNew ~= nil then
                local increaseNumMigratedItems = true
                --Check if the item is marked with any icon
                for iconId = FCOIS_CON_ICON_LOCK, FCOIS.numVars.gFCONumFilterIcons, 1 do
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
    if FCOIS.settingsVars.settings.useUniqueIds == true then
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
    local numLibFiltersFilterPanelIds = FCOIS.numVars.gFCONumFilterInventoryTypes
    local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
    local icon2Dynamic = FCOIS.mappingVars.iconToDynamic
    local iconIsDynamic = FCOIS.mappingVars.iconIsDynamic
    local mappingVars = FCOIS.mappingVars

    --Set the split filters to true as old "non-split filters" method is not supported anymore!
    settings.splitFilters = true

    --Introduced with FCOIS version 1.5.2: Dynamic icons global settings slider to set dynamic icons max total count enabled.
    --Check if the current value of the settings slider was set due to an update of the addon and check if the user was using more than the
    --default value of the enabled dynamic icons already: If so set the slider to the users max value so his dyn icons are all enabled
    --Set the valuie from the settings to the global constant now:
    FCOIS.numVars.gFCONumDynamicIcons = settings.numMaxDynamicIconsUsable
    --Did the addon update and the max usable dyn. icons slider was introduced?
    if settings.addonFCOISChangedDynIconMaxUsableSlider == nil then
        FCOIS.settingsVars.settings.addonFCOISChangedDynIconMaxUsableSlider = true
    end
    local maxUsableDynIconNr = 0
    if settings.addonFCOISChangedDynIconMaxUsableSlider then
        --Check if the user got more dyn. icons enabled as the current value of the usable dyn. icons is set (standard value is: 10)
        --Loop over iconsEnabled in settings and check if the number of dynIcons is > then the currently total usable number
        --local firstDynIconNr = FCOIS.numVars.gFCONumNonDynamicAndGearIcons + 1 --Start at icon# 13 = Dyn. icon #1
        for dynIconNr, isEnabled in ipairs(settings.isIconEnabled) do
            if isEnabled then
                maxUsableDynIconNr = icon2Dynamic[dynIconNr]
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
    --FCOIS v1.8.0
    --Check if the currently set value of "show dynamic icons in submenus if enabled number of dynamic icons is > then x" is above the
    --value of total enabled dynamic icons (currently set maximum usable dynamicIcons via the slider in the marker icons->dynamic settings).
    --if so: Set it to the curerntly maximum enabled dynamic icons
    if settings.useDynSubMenuMaxCount > 0 and settings.numMaxDynamicIconsUsable > 0 then
        if settings.useDynSubMenuMaxCount > settings.numMaxDynamicIconsUsable then
            settings.useDynSubMenuMaxCount = settings.numMaxDynamicIconsUsable
        end
    end

    --Build the additional inventory "flag" context menu button data, which depends on the here before set values
    --FCOIS.numVars.gFCONumDynamicIcons and FCOIS.settingsVars.settings.numMaxDynamicIconsUsable
    --> See file src/FCOIS_ContextMenus.lua, function FCOIS.buildAdditionalInventoryFlagContextMenuData(calledFromFCOISSettings)
    FCOIS.buildAdditionalInventoryFlagContextMenuData(true)

    --Preset global variable for item destroying
    FCOIS.preventerVars.gAllowDestroyItem = not settings.blockDestroying
    -- Get the marked items for each filter from the settings (or defaults, if not set yet)
    for filterIconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        FCOIS.markedItems[filterIconId] = settings.markedItems[filterIconId]
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
    FCOIS.getNumberOfFilteredItemsForEachPanel()

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

    --Added with FCOIS v1.6.7
    --Check if the values at the add. inv. context menu "flag" button offsets are properly set, or
    --reset them
    local apiVersion = FCOIS.APIversion
    local addInvButtonOffsets = settings.FCOISAdditionalInventoriesButtonOffset
    local anchorVarsAddInvButtons = FCOIS.anchorVars.additionalInventoryFlagButton[apiVersion]
    --Loop over the anchorVars and get each panel of the additional inv buttons (e.g. LF_INVENTORY, LF_BANK_WITHDRAW, ...)
    if anchorVarsAddInvButtons then
        for panelId, _ in pairs(anchorVarsAddInvButtons) do
            local addInvButtonOffsetsForPanel = addInvButtonOffsets[panelId]
            if addInvButtonOffsetsForPanel then
                if tonumber(addInvButtonOffsetsForPanel["left"]) == nil then
                    addInvButtonOffsetsForPanel["left"] = 0
                end
                if tonumber(addInvButtonOffsetsForPanel["top"]) == nil then
                    addInvButtonOffsetsForPanel["top"] = 0
                end
            end
        end
    end

    --Added with FCOIS v1.7.4
    --For each panelId add an entry to for the non-deconstructable Libfilters panelIds
    local panelIdToDeconstructable = mappingVars.panelIdToDeconstructable
    local activeFilterPanelIds = mappingVars.activeFilterPanelIds
    if panelIdToDeconstructable and activeFilterPanelIds then
        for panelId, _ in pairs(activeFilterPanelIds) do
            if panelIdToDeconstructable[panelId] == nil then
                FCOIS.mappingVars.panelIdToDeconstructable[panelId] = false
            end
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
    local showAddInvContextMenuFunc = FCOIS.showContextMenuForAddInvButtons
    local showAddInvContextMenuMouseUpFunc = FCOIS.onContextMenuForAddInvButtonsButtonMouseUp
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
            buttonData.alignMain = alignMain
            buttonData.alignBackup = alignBackup
            buttonData.alignControl = ancVars.additionalInventoryFlagButton[apiVersion][panelId].anchorControl
            buttonData.hideButton = doHide
        end
    end

    --Since FCOIS version 1.4.4
    --Transfer old settings of filter button offsets, width and height to the new settings structure
    -->See file src/FCOIS_FilterButtons.lua, function FCOIS.CheckAndTransferFilterButtonDataByPanelId(libFiltersPanelId, filterButtonNr)
    local filterButtonsToCheck = FCOIS.checkVars.filterButtonsToCheck
    if filterButtonsToCheck ~= nil then
        for _, filterButtonNr in ipairs(filterButtonsToCheck) do
            for libFiltersPanelId = 1, numLibFiltersFilterPanelIds, 1 do
                FCOIS.CheckAndTransferFilterButtonDataByPanelId(libFiltersPanelId, filterButtonNr)
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
end

--Do some updates to the SavedVariables before the addon menu is created
function FCOIS.updateSettingsBeforeAddonMenu()
    --SetTracker addon
    FCOIS.otherAddons.SetTracker.GetSetTrackerSettingsAndBuildFCOISSetTrackerData()

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
--Check if the FCOIS settings were loaded already, or load them
function FCOIS.checkIfFCOISSettingsWereLoaded(calledFromExternal)
    calledFromExternal = calledFromExternal or false
    if not calledFromExternal or (FCOIS and FCOIS.settingsVars and FCOIS.settingsVars.settings and FCOIS.settingsVars.settings.markedItems) then return true end
    return FCOIS.LoadUserSettings(calledFromExternal)
end

--Load the SavedVariables now
function FCOIS.LoadUserSettings(calledFromExternal)
    calledFromExternal = calledFromExternal or false
    if calledFromExternal then
        FCOIS.addonVars.gSettingsLoaded = false
        if FCOIS.FCOItemSaver_CheckGamePadMode() then return false end
    end
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
        ------------------------------------------------------------------------------------------------------------------------
        --Added with FCOIS version 1.5.7: AccountWide settings can be saved equal for all accounts. Therefor the ZO_SavedVars:NewAccountWide function's last parameter "AccountName"
        --will be used, if the saveMode is 3 (AllAccountsTheSame).
        --Added with FCOIS version 1.3.5: Server saved settings (EU, NA, PTS)
        --Load the Non-Server dependent savedvars (from the SavedVars[svDefaultName] profile), if they exist.
        -- !!! Do NOT specify default "fallback" values as then the defaults would be ALWAYS found and used !!!
        --Load the old user's default settings from SavedVariables file -> Account wide of basic version 999 at first, without Servername as last parameter, to get existing data
        local oldDefaultSettings = ZO_SavedVars:NewAccountWide(addonSVname, 999, svSettingsForAllName, checkForMigrateDefDefaults, nil)
        --Check, by help of basic version 999, if the settings should be loaded for each character or account wide
        --Use the current addon version to read the FCOIS.settingsVars.settings now
        local oldSettings = {}
        --Load the old user's settings from SavedVariables file -> Account/Character data, depending on the old defaultSettings, without Servername as last parameter, to get existing data
        if (oldDefaultSettings.saveMode == 1) then
        --Each character of an account different
            --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
            oldSettings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, checkForMigrateDefaults, nil)
            --Transfer the data from the name to the unique ID SavedVars now
            NamesToIDSavedVars()
        elseif (oldDefaultSettings.saveMode == 2) then
        --Account wide settings
            oldSettings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, checkForMigrateDefaults, nil, nil)
        elseif (oldDefaultSettings.saveMode == 3) then
        --All accounts the same settings
            oldSettings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, checkForMigrateDefaults, nil, svAllAccTheSameAcc)
        else
            oldSettings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, checkForMigrateDefaults, nil, nil)
        end
        ------------------------------------------------------------------------------------------------------------------------
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
        ------------------------------------------------------------------------------------------------------------------------
        --If server dependent settings were found or it's a new installation of FCOIS
        if freshFCOISInstall or (FCOIS.defSettingsNonServerDependendFound == false and FCOIS.settingsNonServerDependendFound == false) then
            --d("[FCOIS]Using server (" .. world .. ") dependent SavedVars")
            --Reset the old default non-server dependent settings
            FCOItemSaver_Settings[svDefaultName] = nil
            --Get the new server dependent settings
            --Load the user's settings from SavedVariables file -> Account wide of basic version 999 at first
            FCOIS.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(addonSVname, 999, svSettingsForAllName, FCOIS.settingsVars.firstRunSettings, world, nil)
            --Check, by help of basic version 999, if the settings should be loaded for each character or account wide
            --Use the current addon version to read the FCOIS.settingsVars.settings now
            if (FCOIS.settingsVars.defaultSettings.saveMode == 1) then
                --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, FCOIS.settingsVars.defaults, world)
                --Transfer the data from the name to the unique ID SavedVars now
                NamesToIDSavedVars(world)
            --Account wide settings
            elseif (FCOIS.settingsVars.defaultSettings.saveMode == 2) then
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, FCOIS.settingsVars.defaults, world, nil)
            --All accounts the same settings
            elseif (FCOIS.settingsVars.defaultSettings.saveMode == 3) then
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, FCOIS.settingsVars.defaults, world, svAllAccTheSameAcc)
            else
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, FCOIS.settingsVars.defaults, world, nil)
            end
        ------------------------------------------------------------------------------------------------------------------------
        --Non-server dependent settings were found. Migrate them to server dependent ones
        else
            -- Disable non-server dependent settings and save them to the server dependent ones now
            d("|cFF0000>>=====================================================>>|r")
            d("[FCOIS]Found non-server dependent SavedVars -> Migrating them now to server (" .. world .. ") dependent settings")
            --First the settings for all
            --Copy the non-server dependent SV data determined above to a new table without "link"
            local oldDefSettings = FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsForAllName]
            local currentNonServerDependentDefSettingsCopy = ZO_DeepTableCopy(oldDefSettings)
            --Reset the non-server dependent savedvars now! -> See confirmation dialog below
            --FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsForAllName] = nil -- if you want to only remove the settings, otherwise just nil one of the parent tables
            FCOIS.settingsVars.defaultSettings = ZO_SavedVars:NewAccountWide(addonSVname, 999, svSettingsForAllName, currentNonServerDependentDefSettingsCopy, world, nil)
            --Then the other settings
            --Copy the non-server dependent SV data determined above to a new table without "link"
            oldSettings = FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsName]
            local currentNonServerDependentSettingsCopy = ZO_DeepTableCopy(oldSettings)
            --Reset the non-server dependent savedvars now! -> See confirmation dialog below
            --FCOItemSaver_Settings[svDefaultName][displayName][svAccountWideName][svSettingsName] = nil -- if you want to only remove the settings, otherwise just nil one of the parent tables
            --FCOItemSaver_Settings[svDefaultName] = nil --reset the whole table now

            --Initialize the server-dependent settings with no values
            if (oldDefSettings.saveMode == 1) then
                --Each character
                --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, currentNonServerDependentSettingsCopy, world)
            elseif (oldDefSettings.saveMode == 2) then
                --Account wide
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, world, nil)
            elseif (oldDefSettings.saveMode == 3) then
                --All accounts the same settings
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, world, svAllAccTheSameAcc)
            else
                FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, world, nil)
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
                    if (oldDefSettings.saveMode == 1) then
                        --Each charater
                        --Changed: Use the saved variables for single characters from the unique character ID and not the name anymore, so they are character rename save!
                        FCOIS.settingsVars.settings = ZO_SavedVars:NewCharacterIdSettings(addonSVname, addonSVversion , svSettingsName, currentNonServerDependentSettingsCopy, nil)
                    elseif (oldDefSettings.saveMode == 2) then
                        --Account wide
                        FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, nil, nil)
                    elseif (oldDefSettings.saveMode == 3) then
                        --All accounts the same settings
                        FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, nil, svAllAccTheSameAcc)
                    else
                        FCOIS.settingsVars.settings = ZO_SavedVars:NewAccountWide(addonSVname, addonSVversion, svSettingsName, currentNonServerDependentSettingsCopy, nil, nil)
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
    return true
end

--Copy SavedVariables from one server, account and/or character to another
function FCOIS.copySavedVars(srcServer, targServer, srcAcc, targAcc, srcCharId, targCharId, onlyDelete, forceReloadUI)
    onlyDelete = onlyDelete or false
    forceReloadUI = forceReloadUI or false
    local copyServer = false
    local copyAcc = false
    local copyChar = false
    local deleteServer = false
    local deleteAcc = false
    local deleteChar = false
    --------------------------------------------------------------------------------------------------------------------
    --What should be done checks?
    if srcServer == nil or targServer == nil then return nil end
    if srcCharId ~= nil and targCharId ~= nil then
        if onlyDelete then
            deleteChar = true
        else
            copyChar = true
        end
    end
    if not copyChar and not deleteChar and srcAcc ~= nil and targAcc ~= nil then
        if onlyDelete then
            deleteAcc = true
        else
            copyAcc = true
        end
    end
    if not copyChar and not copyAcc and not deleteChar and not deleteAcc then
        if onlyDelete then
            deleteServer = true
        else
            copyServer = true
        end
    end
    --Nothing to do? Abort here
    if not copyServer and not deleteServer and not copyAcc and not deleteAcc and not copyChar and not deleteChar then return end
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    local mappingVars = FCOIS.mappingVars
    local noEntry = mappingVars.noEntry
    local noEntryValue = tostring(mappingVars.noEntryValue)
    --Get some settings
    local settingsVars = FCOIS.settingsVars
    local useAccountWideSV      = (settingsVars.defaultSettings.saveMode == 2 or settingsVars.defaultSettings.saveMode == 3) or false
    local useAllAccountSameSV   = settingsVars.defaultSettings.saveMode == 3 or false
    local svDefToCopy
    local svToCopy
    local currentlyLoggedInUserId = FCOIS.getCurrentlyLoggedInCharUniqueId()
    local displayName = GetDisplayName()
    local accountName = displayName
    if useAllAccountSameSV then
        accountName = svAllAccTheSameAcc
    end
    local showReloadUIDialog = false

    --d("[FCOIS.copySavedVars]srcServer: " .. tostring(srcServer) .. ", targServer: " ..tostring(targServer).. ", srcAccount: " .. tostring(srcAcc) .. ", targAccount: " ..tostring(targAcc).. ", srcChar: " .. tostring(srcCharId) .. ", targChar: " ..tostring(targCharId).. ", onlyDelete: " .. tostring(onlyDelete))
    --d(">copyServer: " .. tostring(copyServer) .. ", deleteServer: " ..tostring(deleteServer).. ", copyAccount: " .. tostring(copyAcc) .. ", deleteAccount: " ..tostring(deleteAcc).. ", copyChar: " .. tostring(copyChar) .. ", deleteChar: " ..tostring(deleteChar))

    --Security check
    if ((srcServer == noEntry or targServer == noEntry) and onlyDelete == false) or (targServer == noEntry and onlyDelete == true) then return end
    --What is to do now?
    --------------------------------------------------------------------------------------------------------------------
    --Copy
    if not onlyDelete then
        if copyServer then
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
        end
    --------------------------------------------------------------------------------------------------------------------
    else
        --Delete
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
    end -- delete

    --------------------------------------------------------------------------------------------------------------------
    --Shall we delete something or eere the tables to copy filled properly now?
    if not onlyDelete and svDefToCopy ~= nil and svToCopy ~= nil then
        --The default table got the language entry and the normal settings table got the markedItems entry?
        if svDefToCopy["language"] ~= nil and svToCopy["markedItems"] ~= nil then
            if FCOItemSaver_Settings[targServer] == nil then FCOItemSaver_Settings[targServer] = {} end
            --Source data is valid. Now build the target data
            if useAccountWideSV then
                --Account wide settings
                if copyServer then
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
                elseif copyAcc then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName] == nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][svAccountWideName][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                elseif copyChar then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId] == nil then FCOItemSaver_Settings[targServer][targAcc][targCharId] = {} end
                    --Check if def settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsForAllName] = svDefToCopy
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                end

            else
                --Character settings enabled.
                if copyServer then
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
                elseif copyAcc then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId] == nil then FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId] = {} end
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][currentlyLoggedInUserId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                elseif copyChar then
                    if FCOItemSaver_Settings[targServer][targAcc] == nil then FCOItemSaver_Settings[targServer][targAcc] = {} end
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId] == nil then FCOItemSaver_Settings[targServer][targAcc][targCharId] = {} end
                    --Check if settings are given and reset them, then set them to the source values
                    if FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] ~= nil then FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = nil end
                    FCOItemSaver_Settings[targServer][targAcc][targCharId][svSettingsName] = svToCopy
                    showReloadUIDialog = true
                end
            end
        end
    end
    --------------------------------------------------------------------------------------------------------------------
    --Now check if we are logged in to the target server and reload the user interface to get the copied data to the internal savedvars
    if showReloadUIDialog then
        if forceReloadUI then ReloadUI() end
        local world = GetWorldName()
        if world == targServer then
            local titleVar = "SavedVariables: "
            if srcServer ~= noEntry then titleVar = titleVar .. "\"" .. srcServer ..  "\"" end
            titleVar = titleVar .. " -> \"" .. targServer .. "\""
            local locVars = FCOIS.localizationVars.fcois_loc
            local questionVar = ""
            if copyServer or deleteServer then
                if copyServer then
                    questionVar = zo_strformat(locVars["question_copy_sv_server_reloadui"], srcServer, targServer, tostring(useAccountWideSV))
                else
                    questionVar = zo_strformat(locVars["question_delete_sv_server_reloadui"], targServer, tostring(useAccountWideSV))
                end
            elseif copyAcc or deleteAcc then
                if copyAcc then
                    questionVar = zo_strformat(locVars["question_copy_sv_account_reloadui"], srcServer, srcAcc, targServer, targAcc, tostring(useAccountWideSV))
                else
                    questionVar = zo_strformat(locVars["question_delete_sv_account_reloadui"], targServer, targAcc, tostring(useAccountWideSV))
                end
            elseif copyChar or deleteChar then
                local characterTable = FCOIS.getCharactersOfAccount(false)
                local srcCharName
                local targCharName = FCOIS.getCharacterName(targCharId, characterTable)
                if copyChar then
                    srcCharName = FCOIS.getCharacterName(srcCharId, characterTable)
                    questionVar = zo_strformat(locVars["question_copy_sv_character_reloadui"], srcServer, srcAcc, srcCharName, targServer, targAcc, targCharName, tostring(useAccountWideSV))
                else
                    questionVar = zo_strformat(locVars["question_delete_sv_character_reloadui"], targServer, targAcc, targCharName, tostring(useAccountWideSV))
                end
            end
            --Show confirmation dialog: ReloadUI now?
            --FCOIS.ShowConfirmationDialog(dialogName, title, body, callbackYes, callbackNo, data)
            FCOIS.ShowConfirmationDialog("ReloadUIAfterSVServer2ServerCopyDialog", titleVar, questionVar, function() ReloadUI() end, function() end)
        end
    end
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    return false
end