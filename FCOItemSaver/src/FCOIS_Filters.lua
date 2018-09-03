--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

--Create the filter object for addon libFilters 2.x
if FCOIS.libFilters == nil then
    FCOIS.libFilters = LibStub("LibFilters-2.0")
    --Initialize the libFilters 2.x filters
    FCOIS.libFilters:InitializeLibFilters()
end
--The local libFilters v2.x library instance
local libFilters = FCOIS.libFilters

--==========================================================================================================================================
--                                          FCOIS - Filter function for libFilters
--==========================================================================================================================================

-- =====================================================================================================================
--  Filter functions (used library: libFilters 2.x)
-- =====================================================================================================================

--The function to filter an item in your inventories
--return value "true" = Show item
--return value "false" = Hide (filter) item
local function filterItemNow(slotItemInstanceId)
    --Check for each filter the marked items
    local result = true
    local isFilterActivated
    local numFilters = FCOIS.numVars.gFCONumFilters
    local settings = FCOIS.settingsVars.settings
    for filterId=1, numFilters, 1 do
        --Check if filter is activated for current slot
        isFilterActivated = FCOIS.getSettingsIsFilterOn(filterId)
        --d("[FCOIS]filterItemNow - isFilterActivated: " .. tostring(isFilterActivated) .. ", filterId: " .. filterId)

        --Special treatment for filter type 1 as it handels the lock & the 4 dynamic marker icons
        if (filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN) then
            --Lock & dynamic 1 - 10
            if settings.lastLockDynFilterIconId[FCOIS.gFilterWhere] == nil or settings.lastLockDynFilterIconId[FCOIS.gFilterWhere] == -1 or not settings.splitLockDynFilter then

                --Filter 1 on
                if(isFilterActivated == true
                        and (
                FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                        or FCOIS.checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic")
                )
                ) then
                    return false
                    --Filter 1 "show only marked"
                elseif(isFilterActivated == -99) then
                    if (
                    FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                            or FCOIS.checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic")
                    ) then
                        return true
                    else
                        result = false
                    end
                    --Filter 1 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            else

                --LockDyn split enabled
                --Last used icon ID at the LockDyn filter split context menu is stored in variable settings.lastLockDynFilterIconId[panelId]
                --Filter 1 on
                if( isFilterActivated == true
                        and (FCOIS.checkIfItemIsProtected(settings.lastLockDynFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId) and settings.isIconEnabled[settings.lastLockDynFilterIconId[FCOIS.gFilterWhere]]) ) then
                    return false
                    --Filter 1 "show only marked"
                elseif( isFilterActivated == -99 ) then
                    return FCOIS.checkIfItemIsProtected(settings.lastLockDynFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId)
                    --Filter 1 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            end

            --Special treatment for filter type 2 as it handels "gear sets" marked items arrays 2, 4, 6, 7 and 8
        elseif (filterId == FCOIS_CON_FILTER_BUTTON_GEARSETS) then

            --Gear filter split disabled
            if settings.lastGearFilterIconId[FCOIS.gFilterWhere] == nil or settings.lastGearFilterIconId[FCOIS.gFilterWhere] == -1 or not settings.splitGearSetsFilter then

                --Filter 2 on
                if(isFilterActivated == true
                        and (
                FCOIS.checkIfItemIsProtected(nil, slotItemInstanceId, "gear")
                )
                ) then
                    return false
                    --Filter 2 "show only marked"
                elseif(isFilterActivated == -99) then
                    if (
                    FCOIS.checkIfItemIsProtected(nil, slotItemInstanceId, "gear")
                    ) then
                        return true
                    else
                        result = false
                    end
                    --Filter 2 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            else

                --Gear filter split enabled
                --Last used icon ID at the gear filter split context menu is stored in variable settings.lastGearFilterIconId[panelId]
                --Filter 2 on
                if( isFilterActivated == true and FCOIS.checkIfItemIsProtected(settings.lastGearFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId) ) then
                    return false
                    --Filter 2 "show only marked"
                elseif( isFilterActivated == -99 ) then
                    return FCOIS.checkIfItemIsProtected(settings.lastGearFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId)
                    --Filter 2 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            end

            --Special treatment for filter type 3, as the marked items are 3, 9 and 10
        elseif (filterId == FCOIS_CON_FILTER_BUTTON_RESDECIMP) then

            --Research, Deconstruction, Improvement filter split disabled
            if settings.lastResDecImpFilterIconId[FCOIS.gFilterWhere] == nil or settings.lastResDecImpFilterIconId[FCOIS.gFilterWhere] == -1 or not settings.splitResearchDeconstructionImprovementFilter then

                --Filter 3 on
                if(isFilterActivated == true
                        and (
                FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, slotItemInstanceId)
                        or FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, slotItemInstanceId)
                        or FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, slotItemInstanceId)
                )
                ) then
                    return false
                    --Filter 3 "show only marked"
                elseif(isFilterActivated == -99) then
                    if (
                    FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, slotItemInstanceId)
                            or FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, slotItemInstanceId)
                            or FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, slotItemInstanceId)
                    ) then
                        return true
                    else
                        result = false
                    end
                    --Filter 3 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            else

                --Research, Deconstruction, Improvement filter split ensabled
                --Last used icon ID at the research/deconstruction/improvement filter split context menu is stored in variable settings.lastResDecImpFilterIconId[panelId]
                --Filter 3 on
                if( isFilterActivated == true
                        and (FCOIS.checkIfItemIsProtected(settings.lastResDecImpFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId) and settings.isIconEnabled[settings.lastResDecImpFilterIconId[FCOIS.gFilterWhere]]) ) then
                    return false
                    --Filter 3 "show only marked"
                elseif( isFilterActivated == -99 ) then
                    return FCOIS.checkIfItemIsProtected(settings.lastResDecImpFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId)
                    --Filter 3 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            end

            --Special treatment for filter type 4, as the marked items are 5, 11 and 12
        elseif (filterId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT) then
            -- Split Sell, Sell in guild store & Intricate not activated in settings
            if settings.lastSellGuildIntFilterIconId[FCOIS.gFilterWhere] == nil or settings.lastSellGuildIntFilterIconId[FCOIS.gFilterWhere] == -1 or not settings.splitSellGuildSellIntricateFilter then

                --Filter 4 on
                if(isFilterActivated == true
                        and (
                FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL, slotItemInstanceId)
                        or  FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, slotItemInstanceId)
                        or  FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, slotItemInstanceId)
                )
                ) then
                    return false
                    --Filter 4 "show only marked"
                elseif(isFilterActivated == -99) then
                    if (
                    FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL, slotItemInstanceId)
                            or FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, slotItemInstanceId)
                            or FCOIS.checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, slotItemInstanceId)
                    ) then
                        return true
                    else
                        result = false
                    end
                    --Filter 4 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            else

                --Sell, Sell in guild store & Intricate filter split disabled
                --Last used icon ID at the Sell, Sell in guild store & Intricate filter split context menu is stored in variable settings.lastSellGuildIntFilterIconId[panelId]
                --Filter 4 on
                if( isFilterActivated == true and FCOIS.checkIfItemIsProtected(settings.lastSellGuildIntFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId) and settings.isIconEnabled[settings.lastSellGuildIntFilterIconId[FCOIS.gFilterWhere]]) then
                    return false
                    --Filter 4 "show only marked"
                elseif( isFilterActivated == -99 ) then
                    return FCOIS.checkIfItemIsProtected(settings.lastSellGuildIntFilterIconId[FCOIS.gFilterWhere], slotItemInstanceId)
                    --Filter 4 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            end

            -- Normal treatment here
        else
            -- Other filters
            if(isFilterActivated == true and FCOIS.checkIfItemIsProtected(filterId, slotItemInstanceId)) then
                return false
                --Other filter "show only marked"
            elseif(isFilterActivated == -99) then
                return FCOIS.checkIfItemIsProtected(filterId, slotItemInstanceId)
                --Other filters off
            else
                if (result ~= false) then
                    result = true
                end
            end
        end
    end
    return result
end

--Filter callBack function for alchemy, refine deconstruction, improvement, retrait & enchanting panels
local function FilterSavedItems(bagId, slotIndex, ...)
    --local itemLink = GetItemLink(bagId, slotIndex)
    --d("[FCOIS] FilterSavedItems: " .. itemLink)
    --This function will be executed once for EACH ITEM SLOT in your inventory/bank,
    --if you open a crafting station
    --The returned value of this filter function must be either
    --true  - Show the slot
    --false - Hide the slot

    -- Return value variable initalization: Show the slot
    local slotItemInstanceId = FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex)

    --Get the filter result variable for the current item
    local itemIsShown = filterItemNow(slotItemInstanceId)

    -- Return the result if all filters were cross-checked and last filter is reached
    return itemIsShown
end

--filter callBack function for bags, bank, mail, trade, guild bank, guild store, vendor, launder, fence, etc.
local function FilterSavedItemsForShop(slot)
    --d("[FCOIS]FilterSavedItemsForShop")
    --This function will be executed once for EACH ITEM SLOT in your inventory
    --The returned value of this filter function must be either
    --true  - Show the slot
    --false - Hide the slot

    local slotItemInstanceId = FCOIS.MyGetItemInstanceId(slot)
    local itemIsShown = filterItemNow(slotItemInstanceId)

    -- Return the result if all filters were cross-checked and last filter is reached
    return itemIsShown
end

--Filter the player inventory
local function FilterPlayerInventory(filterId, panelId)
    local newFilterMethod = FCOIS.settingsVars.settings.splitFilters
    panelId = panelId or FCOIS.gFilterWhere

    --Filtering inside inventory is enabled in the FCOIS.settingsVars.settings?
    if (FCOIS.settingsVars.settings.allowInventoryFilter == true) then
        --Register only 1 filter in the player inventory
        if (filterId ~= -1) then
            if (newFilterMethod == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(panelId) .. "_" .. tostring(filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(panelId) .. "_" .. tostring(filterId), LF_INVENTORY, FilterSavedItemsForShop)
                end
            else
                if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerInventoryFilter" .. tostring(filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(filterId), LF_INVENTORY, FilterSavedItemsForShop)
                end
            end
        else
            --Register all the filters in the player inventory
            if (newFilterMethod) then
                for i=1, FCOIS.numVars.gFCONumFilters, 1 do
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(panelId) .. "_" .. tostring(i))) then
                        libFilters:RegisterFilter("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(panelId) .. "_" .. tostring(i), LF_INVENTORY, FilterSavedItemsForShop)
                    end
                end
            else
                for i=1, FCOIS.numVars.gFCONumFilters, 1 do
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerInventoryFilter" .. tostring(i))) then
                        libFilters:RegisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(i), LF_INVENTORY, FilterSavedItemsForShop)
                    end
                end
            end
        end

    else
        --Filtering inside inventory is NOT enabled in the FCOIS.settingsVars.settings
        if (newFilterMethod == true) then
            if (filterId ~= -1) then
                libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(panelId) .. "_" .. tostring(filterId), LF_INVENTORY)
            else
                for i=1, FCOIS.numVars.gFCONumFilters, 1 do
                    libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(panelId) .. "_" .. tostring(i), LF_INVENTORY)
                end
            end
        else
            if (filterId ~= -1) then
                libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(filterId))
            else
                for i=1, FCOIS.numVars.gFCONumFilters, 1 do
                    libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(i))
                end
            end
        end
    end
end

--Unregister all filters
function FCOIS.unregisterFilters(filterId, onlyPlayerInvFilter, filterPanelId)
    --Only remove filters for player inventory?
    if (onlyPlayerInvFilter == nil) then
        onlyPlayerInvFilter = false
    end
    --Only update a special panel, or all?
    local forVar, maxVar
    if (filterPanelId ~= nil) then
        forVar  = filterPanelId
        maxVar  = filterPanelId
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.unregisterFilters] FilterPanelId: " .. tostring(filterPanelId) .. ", filterId: " .. tostring(filterId) .. ", OnlyPlayerInvFilter: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    else
        forVar  = 1
        maxVar  = FCOIS.numVars.gFCONumFilterInventoryTypes
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.unregisterFilters] From panel Id: " .. tostring(forVar) .. ", To panel Id: " .. tostring(maxVar) .. ", filterId: " .. tostring(filterId) .. ", OnlyPlayerInvFilter: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end

    local unregisterArrayNew = {}
    --Unregister only 1 filter ID?
    if (filterId ~= nil and filterId ~= -1) then
        if (FCOIS.settingsVars.settings.splitFilters == true) then
            --New filter method
            for lFilterWhere=forVar, maxVar , 1 do
                if FCOIS.mappingVars.activeFilterPanelIds[lFilterWhere] == true then
                    if (onlyPlayerInvFilter == true) then
                        libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId))
                    else
                        unregisterArrayNew = {
                            [LF_INVENTORY] = "FCOItemSaver_PlayerInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_BANK_WITHDRAW] = "FCOItemSaver_PlayerBankFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_BANK_DEPOSIT] = "FCOItemSaver_PlayerBankInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_GUILDBANK_WITHDRAW] = "FCOItemSaver_GuildBankFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_GUILDBANK_DEPOSIT] = "FCOItemSaver_GuildBankInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_VENDOR_SELL] = "FCOItemSaver_VendorFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_SMITHING_REFINE] = "FCOItemSaver_RefinementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_SMITHING_DECONSTRUCT] = "FCOItemSaver_DeconstructionFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_SMITHING_IMPROVEMENT] = "FCOItemSaver_ImprovementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_JEWELRY_REFINE] = "FCOItemSaver_JewelryRefinementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_JEWELRY_DECONSTRUCT] = "FCOItemSaver_JewelryDeconstructionFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_JEWELRY_IMPROVEMENT] = "FCOItemSaver_JewelryImprovementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_GUILDSTORE_SELL] = "FCOItemSaver_GuildStoreSellFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_MAIL_SEND] = "FCOItemSaver_MailFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_TRADE] = "FCOItemSaver_Player2PlayerFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_ENCHANTING_EXTRACTION] = "FCOItemSaver_EnchantingExtractionFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_ENCHANTING_CREATION] = "FCOItemSaver_EnchantingCreationFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_FENCE_SELL] = "FCOItemSaver_FenceFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_FENCE_LAUNDER] = "FCOItemSaver_LaunderFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_ALCHEMY_CREATION] = "FCOItemSaver_AlchemyFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_CRAFTBAG] = "FCOItemSaver_CraftBagFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_RETRAIT] = "FCOItemSaver_RetraitFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_HOUSE_BANK_WITHDRAW] = "FCOItemSaver_HouseBankFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            [LF_HOUSE_BANK_DEPOSIT] = "FCOItemSaver_HouseBankInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                        }
                        if libFilters:IsFilterRegistered(unregisterArrayNew[lFilterWhere], lFilterWhere) then
                            --Unregister the registered filters for each panel
                            libFilters:UnregisterFilter(unregisterArrayNew[lFilterWhere], lFilterWhere)
                        end
                    end
                end
            end

        else -- if (FCOIS.settingsVars.settings.splitFilters == true) then
            --Old filter method
            if (onlyPlayerInvFilter == true) then
                libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(filterId))
            else
                --Unregister the registered filters
                libFilters:UnregisterFilter("FCOItemSaver_VendorFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_DeconstructionFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_ImprovementFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_GuildStoreSellFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_GuildBankFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_PlayerBankFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_Player2PlayerFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_MailFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_EnchantingCreationFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_EnchantingExtractionFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_FenceFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_LaunderFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_AlchemyFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_CraftBagFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_RetraitFilter" .. tostring(filterId))
                libFilters:UnregisterFilter("FCOItemSaver_HouseBankFilter" .. tostring(filterId))
            end
        end

    else

        -- Unregister all filter IDs
        if (FCOIS.settingsVars.settings.splitFilters == true or FCOIS.overrideVars.gSplitFilterOverride == true) then
            --New filter method
            for filterId=1, FCOIS.numVars.gFCONumFilters, 1 do
                for lFilterWhere=forVar, maxVar , 1 do
                    if FCOIS.mappingVars.activeFilterPanelIds[lFilterWhere] == true then
                        if (onlyPlayerInvFilter == true) then
                            libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId))
                        else
                            unregisterArrayNew = {
                                [LF_INVENTORY] = "FCOItemSaver_PlayerInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_BANK_WITHDRAW] = "FCOItemSaver_PlayerBankFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_BANK_DEPOSIT] = "FCOItemSaver_PlayerBankInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_GUILDBANK_WITHDRAW] = "FCOItemSaver_GuildBankFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_GUILDBANK_DEPOSIT] = "FCOItemSaver_GuildBankInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_VENDOR_SELL] = "FCOItemSaver_VendorFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_SMITHING_REFINE] = "FCOItemSaver_RefinementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_SMITHING_DECONSTRUCT] = "FCOItemSaver_DeconstructionFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_SMITHING_IMPROVEMENT] = "FCOItemSaver_ImprovementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_JEWELRY_REFINE] = "FCOItemSaver_JewelryRefinementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_JEWELRY_DECONSTRUCT] = "FCOItemSaver_JewelryDeconstructionFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_JEWELRY_IMPROVEMENT] = "FCOItemSaver_JewelryImprovementFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_GUILDSTORE_SELL] = "FCOItemSaver_GuildStoreSellFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_MAIL_SEND] = "FCOItemSaver_MailFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_TRADE] = "FCOItemSaver_Player2PlayerFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_ENCHANTING_EXTRACTION] = "FCOItemSaver_EnchantingExtractionFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_ENCHANTING_CREATION] = "FCOItemSaver_EnchantingCreationFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_FENCE_SELL] = "FCOItemSaver_FenceFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_FENCE_LAUNDER] = "FCOItemSaver_LaunderFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_ALCHEMY_CREATION] = "FCOItemSaver_AlchemyFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_CRAFTBAG] = "FCOItemSaver_CraftBagFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_RETRAIT] = "FCOItemSaver_RetraitFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_HOUSE_BANK_WITHDRAW] = "FCOItemSaver_HouseBankFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                                [LF_HOUSE_BANK_DEPOSIT] = "FCOItemSaver_HouseBankInventoryFilterNew" .. tostring(lFilterWhere) .. "_" .. tostring(filterId),
                            }
                            --Unregister the registered filters for each panel
                            libFilters:UnregisterFilter(unregisterArrayNew[lFilterWhere], lFilterWhere)
                        end
                    end
                end
            end

        elseif (FCOIS.settingsVars.settings.splitFilters == false or FCOIS.overrideVars.gSplitFilterOverride == true) then
            --Old filter method
            for filterId=1, FCOIS.numVars.gFCONumFilters, 1 do
                if (onlyPlayerInvFilter == true) then
                    libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(filterId))
                else
                    --Unregister the registered filters
                    libFilters:UnregisterFilter("FCOItemSaver_VendorFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_DeconstructionFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_ImprovementFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_GuildStoreSellFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_GuildBankFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_PlayerBankFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_PlayerInventoryFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_Player2PlayerFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_MailFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_EnchantingCreationFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_EnchantingExtractionFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_FenceFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_LaunderFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_AlchemyFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_CraftBagFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_RetraitFilter" .. tostring(filterId))
                    libFilters:UnregisterFilter("FCOItemSaver_HouseBankFilter" .. tostring(filterId))
                end
            end
        end
    end
end

--Helper function for method FCOIS.registerFilters when FCOIS.settingsVars.settings.splitFilters == true
local function registerFilterId(p_onlyPlayerInvFilter, p_filterId, p_panelId)
    --Get the current LAF (filter type, e.g. LF_INVENTORY, LF_BANK_WITHDRAW, etc.)
    --local lf = libFilters:GetCurrentLAF()
    --if lf == nil then lf = LF_INVENTORY end

    if (p_onlyPlayerInvFilter == true) then
        --Player inventory -> Only if activated in settings
        FilterPlayerInventory(p_filterId, p_panelId)
    else

        --(Re)register the filters for each panel
        if     (p_panelId == LF_INVENTORY) then
            FilterPlayerInventory(p_filterId, p_panelId)

        elseif (p_panelId == LF_CRAFTBAG) then
            -- Filter craft bag panels
            if (FCOIS.settingsVars.settings.allowCraftBagFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_CraftBagFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_CraftBagFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_CRAFTBAG, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_BANK_WITHDRAW) then
            -- Filter player bank panels
            if (FCOIS.settingsVars.settings.allowBankFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerBankFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_PlayerBankFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_BANK_WITHDRAW, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_BANK_DEPOSIT) then
            -- Filter player bank inventory panel
            if (FCOIS.settingsVars.settings.allowInventoryFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerBankInventoryFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_PlayerBankInventoryFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_BANK_DEPOSIT, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_HOUSE_BANK_WITHDRAW) then
            -- Filter house bank panels
            if (FCOIS.settingsVars.settings.allowBankFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_HouseBankFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_HouseBankFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_HOUSE_BANK_WITHDRAW, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_HOUSE_BANK_DEPOSIT) then
            -- Filter house bank inventory panel
            if (FCOIS.settingsVars.settings.allowInventoryFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_HouseBankInventoryFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_HouseBankInventoryFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_HOUSE_BANK_DEPOSIT, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_GUILDBANK_WITHDRAW) then
            -- Filter guildbank panels
            if (FCOIS.settingsVars.settings.allowGuildBankFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_GuildBankFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_GuildBankFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_GUILDBANK_WITHDRAW, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_GUILDBANK_DEPOSIT) then
            -- Filter guildbank inventory panel
            if (FCOIS.settingsVars.settings.allowInventoryFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_GuildBankInventoryFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_GuildBankInventoryFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_GUILDBANK_DEPOSIT, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_VENDOR_SELL) then
            -- Filter stores
            if (FCOIS.settingsVars.settings.allowVendorFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_VendorFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    -- Register the before chosen filter type and function
                    libFilters:RegisterFilter("FCOItemSaver_VendorFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_VENDOR_SELL, FilterSavedItemsForShop)
                end
            end
        elseif (p_panelId == LF_FENCE_SELL) then
            -- Filter fence
            if (FCOIS.settingsVars.settings.allowFenceFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_FenceFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    -- Register the before chosen filter type and function
                    libFilters:RegisterFilter("FCOItemSaver_FenceFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_FENCE_SELL, FilterSavedItemsForShop)
                end
            end
        elseif (p_panelId == LF_FENCE_LAUNDER) then
            -- Filter fence
            if (FCOIS.settingsVars.settings.allowLaunderFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_LaunderFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    -- Register the before chosen filter type and function
                    libFilters:RegisterFilter("FCOItemSaver_LaunderFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_FENCE_LAUNDER, FilterSavedItemsForShop)
                end
            end
        elseif (p_panelId == LF_SMITHING_REFINE) then
            -- Filter refinement panels
            if (FCOIS.settingsVars.settings.allowRefinementFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_RefinementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_RefinementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_SMITHING_REFINE, FilterSavedItems)
                end
            end
        elseif (p_panelId == LF_SMITHING_DECONSTRUCT) then
            -- Filter deconstruction panels
            if (FCOIS.settingsVars.settings.allowDeconstructionFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_DeconstructionFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_DeconstructionFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_SMITHING_DECONSTRUCT, FilterSavedItems)
                end
            end
        elseif (p_panelId == LF_SMITHING_IMPROVEMENT) then
            -- Filter improvement panels
            if (FCOIS.settingsVars.settings.allowImprovementFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_ImprovementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_ImprovementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_SMITHING_IMPROVEMENT, FilterSavedItems)
                end
            end
        elseif (p_panelId == LF_JEWELRY_REFINE) then
            -- Filter jewelry refinement panels
            if (FCOIS.settingsVars.settings.allowJewelryRefinementFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryRefinementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_JewelryRefinementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_JEWELRY_REFINE, FilterSavedItems)
                end
            end
        elseif (p_panelId == LF_JEWELRY_DECONSTRUCT) then
            -- Filter jewelry deconstruction panels
            if (FCOIS.settingsVars.settings.allowJewelryDeconstructionFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryDeconstructionFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_JewelryDeconstructionFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_JEWELRY_DECONSTRUCT, FilterSavedItems)
                end
            end
        elseif (p_panelId == LF_JEWELRY_IMPROVEMENT) then
            -- Filter jewelry improvement panels
            if (FCOIS.settingsVars.settings.allowJewelryImprovementFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryImprovementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_JewelryImprovementFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_JEWELRY_IMPROVEMENT, FilterSavedItems)
                end
            end

        elseif (p_panelId == LF_GUILDSTORE_SELL) then
            -- Filter guildstore panels
            if (FCOIS.settingsVars.settings.allowTradinghouseFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_GuildStoreSellFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_GuildStoreSellFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_GUILDSTORE_SELL, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_MAIL_SEND) then
            --Mail
            if (FCOIS.settingsVars.settings.allowMailFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_MailFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_MailFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_MAIL_SEND, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_TRADE) then
            --Player2player trading
            if (FCOIS.settingsVars.settings.allowTradeFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_Player2PlayerFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_Player2PlayerFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_TRADE, FilterSavedItemsForShop)
                end
            end

        elseif (p_panelId == LF_ENCHANTING_EXTRACTION) then
            -- Filter enchanting panels
            if (FCOIS.settingsVars.settings.allowEnchantingFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_EnchantingExtractionFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_EnchantingExtractionFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_ENCHANTING_EXTRACTION, FilterSavedItems)
                end
            end

        elseif (p_panelId == LF_ENCHANTING_CREATION) then
            -- Filter enchanting panels
            if (FCOIS.settingsVars.settings.allowEnchantingFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_EnchantingCreationFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_EnchantingCreationFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_ENCHANTING_CREATION, FilterSavedItems)
                end
            end

        elseif (p_panelId == LF_ALCHEMY_CREATION) then
            -- Filter alchemy panels
            if (FCOIS.settingsVars.settings.allowAlchemyFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_AlchemyFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_AlchemyFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_ALCHEMY_CREATION, FilterSavedItems)
                end
            end

        elseif (p_panelId == LF_RETRAIT) then
--d("[FCOIS]registerFilterId - Retrait: " .. tostring(p_onlyPlayerInvFilter) .. ", " .. tostring(p_filterId) .. ", " .. tostring(p_panelId))
            -- Filter alchemy panels
            if (FCOIS.settingsVars.settings.allowRetraitFilter == true) then
                if(not libFilters:IsFilterRegistered("FCOItemSaver_RetraitFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId))) then
                    libFilters:RegisterFilter("FCOItemSaver_RetraitFilterNew" .. tostring(p_panelId) .. "_" .. tostring(p_filterId), LF_RETRAIT, FilterSavedItems)
                end
            end

        end

    end
end

--Register the filters by help of library libFilters
function FCOIS.registerFilters(filterId, onlyPlayerInvFilter, p_FilterPanelId)
    --Only register filters for player inventory?
    if (onlyPlayerInvFilter == nil) then
        onlyPlayerInvFilter = false
    end
    local settings = FCOIS.settingsVars.settings
    --Register only 1 filter ID?
    if (filterId ~= nil and filterId ~= -1) then
        --Register only one filter ID

        --New or old behaviour of filtering?
        if (settings.splitFilters == true) then
            --New filtering using panels
            if settings.debug then FCOIS.debugMessage( "[FCOIS.registerFilters] Panel: " .. tostring(p_FilterPanelId) .. ", OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter) .. ", filterId: " .. tostring(filterId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

            --Register the filter for the given panel ID and filter ID
            registerFilterId(onlyPlayerInvFilter, filterId, p_FilterPanelId)

        else
            -- Old filter behaviour without panels
            if settings.debug then FCOIS.debugMessage( "[FCOIS.registerFilters] filterId: " .. tostring(filterId) .. ", OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

            if (onlyPlayerInvFilter == true) then
                --Player inventory -> Only if activated in settings
                FilterPlayerInventory(filterId)
            else

                -- Filter craft bag
                if (settings.allowCraftBagFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_CraftBagFilter" .. tostring(p_filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_CraftBagFilter" .. tostring(p_filterId), LF_CRAFTBAG, FilterSavedItemsForShop)
                    end
                end

                -- Filter vendor
                if (settings.allowVendorFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_VendorFilter" .. tostring(filterId))) then
                        -- Register the before chosen filter type and function
                        libFilters:RegisterFilter("FCOItemSaver_VendorFilter" .. tostring(filterId), LF_VENDOR_SELL, FilterSavedItemsForShop)
                    end
                end

                -- Filter refinement panels
                if (settings.allowRefinementFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_RefinementFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_RefinementFilter" .. tostring(filterId), LF_SMITHING_REFINE, FilterSavedItems)
                    end
                end

                -- Filter deconstruction panels
                if (settings.allowDeconstructionFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_DeconstructionFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_DeconstructionFilter" .. tostring(filterId), LF_SMITHING_DECONSTRUCT, FilterSavedItems)
                    end
                end

                -- Filter improvement panels
                if (settings.allowImprovementFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_ImprovementFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_ImprovementFilter" .. tostring(filterId), LF_SMITHING_IMPROVEMENT, FilterSavedItems)
                    end
                end

                -- Filter jewelry refinement panels
                if (settings.allowJewelryRefinementFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryRefinementFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_JewelryRefinementFilter" .. tostring(filterId), LF_JEWELRY_REFINE, FilterSavedItems)
                    end
                end

                -- Filter jewelry deconstruction panels
                if (settings.allowJewelryDeconstructionFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryDeconstructionFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_JewelryDeconstructionFilter" .. tostring(filterId), LF_JEWELRY_DECONSTRUCT, FilterSavedItems)
                    end
                end

                -- Filter jewelry improvement panels
                if (settings.allowJewelryImprovementFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryImprovementFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_JewelryImprovementFilter" .. tostring(filterId), LF_JEWELRY_IMPROVEMENT, FilterSavedItems)
                    end
                end

                -- Filter enchanting panels
                if (settings.allowEnchantingFilter == true) then
                    if      ENCHANTING.enchantingMode == 1 then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_EnchantingCreationFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_EnchantingCreationFilter" .. tostring(filterId), LF_ENCHANTING_CREATION, FilterSavedItems)
                        end
                    elseif ENCHANTING.enchantingMode == 2 then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_EnchantingExtractionFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_EnchantingExtractionFilter" .. tostring(filterId), LF_ENCHANTING_EXTRACTION, FilterSavedItems)
                        end
                    end
                end

                -- Filter alchemy panels
                if (settings.allowAlchemyFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_AlchemyFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_AlchemyFilter" .. tostring(filterId), LF_ALCHEMY_CREATION, FilterSavedItems)
                    end
                end

                -- Filter player bank panels
                if (settings.allowBankFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerBankFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_PlayerBankFilter" .. tostring(filterId), LF_BANK_WITHDRAW, FilterSavedItemsForShop)
                    end
                end

                -- Filter house bank panels
                if (settings.allowBankFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_HouseBankFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_HouseBankFilter" .. tostring(filterId), LF_HOUSE_BANK_WITHDRAW, FilterSavedItemsForShop)
                    end
                end

                -- Filter guildbank panels
                if (settings.allowGuildBankFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_GuildBankFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_GuildBankFilter" .. tostring(filterId), LF_GUILDBANK_WITHDRAW, FilterSavedItemsForShop)
                    end
                end

                -- Filter guildstore panels
                if (settings.allowTradinghouseFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_GuildStoreSellFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_GuildStoreSellFilter" .. tostring(filterId), LF_GUILDSTORE_SELL, FilterSavedItemsForShop)
                    end
                end

                -- Filter fence
                if (settings.allowFenceFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_FenceFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_FenceFilter" .. tostring(filterId), LF_FENCE_SELL, FilterSavedItemsForShop)
                    end
                end

                -- Filter launder
                if (settings.allowLaunderFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_LaunderFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_LaunderFilter" .. tostring(filterId), LF_FENCE_LAUNDER, FilterSavedItemsForShop)
                    end
                end

                -- Filter retrait station
                if (settings.allowRetraitFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_RetraitFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_RetraitFilter" .. tostring(filterId), LF_RETRAIT, FilterSavedItems)
                    end
                end

                -- !!!!!												   !!!!!
                -- !!!!! In addition always activate the following filters !!!!!
                -- !!!!!												   !!!!!
                --Player inventory -> Only if activated in settings
                FilterPlayerInventory(filterId)

                --Player2player trading
                if (settings.allowTradeFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_Player2PlayerFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_Player2PlayerFilter" .. tostring(filterId), LF_TRADE, FilterSavedItemsForShop)
                    end
                end
                --Mail
                if (settings.allowMailFilter == true) then
                    if(not libFilters:IsFilterRegistered("FCOItemSaver_MailFilter" .. tostring(filterId))) then
                        libFilters:RegisterFilter("FCOItemSaver_MailFilter" .. tostring(filterId), LF_MAIL_SEND, FilterSavedItemsForShop)
                    end
                end
            end
        end  --new filter method?

    else
        --Register all filter IDs

        if (settings.splitFilters == true) then
            --Using panels

            --Only update a special panel, or all?
            local forVar, maxVar
            if (p_FilterPanelId == nil) then
                forVar  = 1
                maxVar  = FCOIS.numVars.gFCONumFilterInventoryTypes
            end

            for filterId=1, FCOIS.numVars.gFCONumFilters, 1 do
                for lFilterWhere=forVar, maxVar , 1 do
                    if FCOIS.mappingVars.activeFilterPanelIds[lFilterWhere] == true then
                        if settings.debug then FCOIS.debugMessage( "[FCOIS.registerFilters] Panel: " .. tostring(forVar) .. ", filterId: " .. tostring(filterId) .. ", OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                        --register the filters for the given panels
                        registerFilterId(onlyPlayerInvFilter, filterId, lFilterWhere)
                    end
                end
            end

        else
            --NOT using panels (old method)
            if settings.debug then FCOIS.debugMessage( "[FCOIS.registerFilters] All filters!, OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

            for filterId=1, FCOIS.numVars.gFCONumFilters, 1 do
                if (onlyPlayerInvFilter == true) then
                    --Player inventory -> Only if activated in settings
                    FilterPlayerInventory(filterId)
                else

                    -- Filter craft bag
                    if (settings.allowCraftBagFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_CraftBagFilter" .. tostring(p_filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_CraftBagFilter" .. tostring(p_filterId), LF_CRAFTBAG, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter stores
                    if (settings.allowVendorFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_VendorFilter" .. tostring(filterId))) then
                            -- Register the before chosen filter type and function
                            libFilters:RegisterFilter("FCOItemSaver_VendorFilter" .. tostring(filterId), LF_VENDOR_SELL, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter refinement panels
                    if (settings.allowRefinementFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_RefinementFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_RefinementFilter" .. tostring(filterId), LF_SMITHING_REFINE, FilterSavedItems)
                        end
                    end

                    -- Filter deconstruction panels
                    if (settings.allowDeconstructionFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_DeconstructionFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_DeconstructionFilter" .. tostring(filterId), LF_SMITHING_DECONSTRUCT, FilterSavedItems)
                        end
                    end

                    -- Filter improvement panels
                    if (settings.allowImprovementFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_ImprovementFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_ImprovementFilter" .. tostring(filterId), LF_SMITHING_IMPROVEMENT, FilterSavedItems)
                        end
                    end

                    -- Filter jewelry refinement panels
                    if (settings.allowJewelryRefinementFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryRefinementFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_JewelryRefinementFilter" .. tostring(filterId), LF_JEWELRY_REFINE, FilterSavedItems)
                        end
                    end

                    -- Filter jewelry deconstruction panels
                    if (settings.allowJewelryDeconstructionFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryDeconstructionFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_JewelryDeconstructionFilter" .. tostring(filterId), LF_JEWELRY_DECONSTRUCT, FilterSavedItems)
                        end
                    end

                    -- Filter jewelry improvement panels
                    if (settings.allowJewelryImprovementFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_JewelryImprovementFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_JewelryImprovementFilter" .. tostring(filterId), LF_JEWELRY_IMPROVEMENT, FilterSavedItems)
                        end
                    end

                    -- Filter enchanting panels
                    if (settings.allowEnchantingFilter == true) then
                        if      ENCHANTING.enchantingMode == 1 then
                            if(not libFilters:IsFilterRegistered("FCOItemSaver_EnchantingCreationFilter" .. tostring(filterId))) then
                                libFilters:RegisterFilter("FCOItemSaver_EnchantingCreationFilter" .. tostring(filterId), LF_ENCHANTING_CREATION, FilterSavedItems)
                            end
                        elseif ENCHANTING.enchantingMode == 2 then
                            if(not libFilters:IsFilterRegistered("FCOItemSaver_EnchantingExtractionFilter" .. tostring(filterId))) then
                                libFilters:RegisterFilter("FCOItemSaver_EnchantingExtractionFilter" .. tostring(filterId), LF_ENCHANTING_EXTRACTION, FilterSavedItems)
                            end
                        end
                    end

                    -- Filter alchemy panels
                    if (settings.allowAlchemyFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_AlchemyFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_AlchemyFilter" .. tostring(filterId), LF_ALCHEMY_CREATION, FilterSavedItems)
                        end
                    end

                    -- Filter player bank panels
                    if (settings.allowBankFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_PlayerBankFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_PlayerBankFilter" .. tostring(filterId), LF_BANK_WITHDRAW, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter house bank panels
                    if (settings.allowBankFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_HouseBankFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_HouseBankFilter" .. tostring(filterId), LF_HOUSE_BANK_WITHDRAW, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter guildbank panels
                    if (settings.allowGuildBankFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_GuildBankFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_GuildBankFilter" .. tostring(filterId), LF_GUILDBANK_WITHDRAW, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter guildstore panels
                    if (settings.allowTradinghouseFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_GuildStoreSellFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_GuildStoreSellFilter" .. tostring(filterId), LF_GUILDSTORE_SELL, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter fence
                    if (settings.allowFenceFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_FenceFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_FenceFilter" .. tostring(filterId), LF_FENCE_SELL, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter launder
                    if (settings.allowLaunderFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_LaunderFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_LaunderFilter" .. tostring(filterId), LF_FENCE_LAUNDER, FilterSavedItemsForShop)
                        end
                    end

                    -- Filter retrait station
                    if (settings.allowRetraitFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_RetraitFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_RetraitFilter" .. tostring(filterId), LF_RETRAIT, FilterSavedItems)
                        end
                    end

                    -- !!!!!												   !!!!!
                    -- !!!!! In addition always activate the following filters !!!!!
                    -- !!!!!												   !!!!!
                    --Player inventory -> Only if activated in settings
                    FilterPlayerInventory(filterId)

                    --Player2player trading
                    if (settings.allowTradeFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_Player2PlayerFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_Player2PlayerFilter" .. tostring(filterId), LF_TRADE, FilterSavedItemsForShop)
                        end
                    end
                    --Mail
                    if (settings.allowMailFilter == true) then
                        if(not libFilters:IsFilterRegistered("FCOItemSaver_MailFilter" .. tostring(filterId))) then
                            libFilters:RegisterFilter("FCOItemSaver_MailFilter" .. tostring(filterId), LF_MAIL_SEND, FilterSavedItemsForShop)
                        end
                    end
                end
            end
        end

    end -- only 1 filter ID or all filter IDs?
end