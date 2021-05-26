--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end


local activeFilterPanelIds = FCOIS.mappingVars.activeFilterPanelIds
local numFilters = FCOIS.numVars.gFCONumFilters
local numFilterInventoryTypes = FCOIS.numVars.gFCONumFilterInventoryTypes

--The local libFilters v2.x library instance
local libFilters = FCOIS.libFilters

--The filter string names for each ID
local filterIds2Name = FCOIS.mappingVars.libFiltersIds2StringPrefix

local getFilterWhereBySettings = FCOIS.getFilterWhereBySettings
local getSettingsIsFilterOn = FCOIS.getSettingsIsFilterOn
local checkIfItemIsProtected = FCOIS.checkIfItemIsProtected
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local myGetItemInstanceId = FCOIS.MyGetItemInstanceId

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
    local settings = FCOIS.settingsVars.settings
    local settingsOfFilterButtonStateAndIcon = FCOIS.getAccountWideCharacterOrNormalCharacterSettings()
    if settingsOfFilterButtonStateAndIcon == nil then
        d("[FCOIS]ERROR - filterItemNow -> settingsOfFilterButtonStateAndIcon is NIL!")
        return
    end
    --Check each filter button and collect the "protected ones". Do not return or abort in between to assure that filters
    --at button 4 (e.g. says hide) will also be applied if button 3 already said "only show" -> Would result in show
    --instead of hide (due to filetr button 4).
    for filterId=1, numFilters, 1 do
        --Check if filter is activated for current slot
        isFilterActivated = getSettingsIsFilterOn(filterId)
        --d("[FCOIS]filterItemNow - isFilterActivated: " .. tostring(isFilterActivated) .. ", filterId: " .. filterId)
--Filter button 1-------------------------------------------------------------------------------------------------------
        --Special treatment for filter type 1 as it handels the lock & the 4 dynamic marker icons
        if filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
            local lastLockDynFilterIconId = settingsOfFilterButtonStateAndIcon.lastLockDynFilterIconId[FCOIS.gFilterWhere]
            --Lock & dynamic 1 - 10
            if lastLockDynFilterIconId == nil or lastLockDynFilterIconId == -1 or not settings.splitLockDynFilter then

                --Filter 1 on
                if(isFilterActivated == true
                        and (
                        checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                                or checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic")
                )
                ) then
                    result = false
                    --Filter 1 "show only marked"
                elseif(isFilterActivated == -99) then
                    if (
                            checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                                    or checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic")
                    ) then
                        result = true
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
                        and (checkIfItemIsProtected(lastLockDynFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastLockDynFilterIconId]) ) then
                    result = false
                    --Filter 1 "show only marked"
                elseif( isFilterActivated == -99 ) then
                    result = checkIfItemIsProtected(lastLockDynFilterIconId, slotItemInstanceId)
                    --Filter 1 off
                else
                    if (result ~= false) then
                        result = true
                    end
                end

            end

            --Filter button 2-------------------------------------------------------------------------------------------------------
            --Special treatment for filter type 2 as it handels "gear sets" marked items arrays 2, 4, 6, 7 and 8
        elseif filterId == FCOIS_CON_FILTER_BUTTON_GEARSETS then
            if result then
                local lastGearFilterIconId = settingsOfFilterButtonStateAndIcon.lastGearFilterIconId[FCOIS.gFilterWhere]
                --Gear filter split disabled
                if lastGearFilterIconId == nil or lastGearFilterIconId == -1 or not settings.splitGearSetsFilter then

                    --Filter 2 on
                    if(isFilterActivated == true
                            and (
                            checkIfItemIsProtected(nil, slotItemInstanceId, "gear")
                    )
                    ) then
                        result = false
                        --Filter 2 "show only marked"
                    elseif(isFilterActivated == -99) then
                        if (
                                checkIfItemIsProtected(nil, slotItemInstanceId, "gear")
                        ) then
                            result = true
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
                    if( isFilterActivated == true
                            and ( checkIfItemIsProtected(lastGearFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastGearFilterIconId]) ) then
                        result = false
                        --Filter 2 "show only marked"
                    elseif( isFilterActivated == -99 ) then
                        result = checkIfItemIsProtected(lastGearFilterIconId, slotItemInstanceId)
                        --Filter 2 off
                    else
                        if (result ~= false) then
                            result = true
                        end
                    end

                end
            end
            --Filter button 3-------------------------------------------------------------------------------------------------------
            --Special treatment for filter type 3, as the marked items are 3, 9 and 10
        elseif filterId == FCOIS_CON_FILTER_BUTTON_RESDECIMP then
            if result then
                local lastResDecImpFilterIconId = settingsOfFilterButtonStateAndIcon.lastResDecImpFilterIconId[FCOIS.gFilterWhere]
                --Research, Deconstruction, Improvement filter split disabled
                if lastResDecImpFilterIconId == nil or lastResDecImpFilterIconId == -1 or not settings.splitResearchDeconstructionImprovementFilter then

                    --Filter 3 on
                    if(isFilterActivated == true
                            and (
                            checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, slotItemInstanceId)
                                    or checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, slotItemInstanceId)
                                    or checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, slotItemInstanceId)
                    )
                    ) then
                        result = false
                        --Filter 3 "show only marked"
                    elseif(isFilterActivated == -99) then
                        if (
                                checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, slotItemInstanceId)
                                        or checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, slotItemInstanceId)
                                        or checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, slotItemInstanceId)
                        ) then
                            result = true
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
                            and (checkIfItemIsProtected(lastResDecImpFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastResDecImpFilterIconId]) ) then
                        return false
                        --Filter 3 "show only marked"
                    elseif( isFilterActivated == -99 ) then
                        result = checkIfItemIsProtected(lastResDecImpFilterIconId, slotItemInstanceId)
                        --Filter 3 off
                    else
                        if (result ~= false) then
                            result = true
                        end
                    end

                end
            end

--Filter button 4-------------------------------------------------------------------------------------------------------
            --Special treatment for filter type 4, as the marked items are 5, 11 and 12
        elseif filterId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT then
            if result then
                local lastSellGuildIntFilterIconId = settingsOfFilterButtonStateAndIcon.lastSellGuildIntFilterIconId[FCOIS.gFilterWhere]
                -- Split Sell, Sell in guild store & Intricate not activated in settings
                if lastSellGuildIntFilterIconId == nil or lastSellGuildIntFilterIconId == -1 or not settings.splitSellGuildSellIntricateFilter then

                    --Filter 4 on
                    if(isFilterActivated == true
                            and (
                            checkIfItemIsProtected(FCOIS_CON_ICON_SELL, slotItemInstanceId)
                                    or  checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, slotItemInstanceId)
                                    or  checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, slotItemInstanceId)
                    )
                    ) then
                        result = false
                        --Filter 4 "show only marked"
                    elseif(isFilterActivated == -99) then
                        if (
                                checkIfItemIsProtected(FCOIS_CON_ICON_SELL, slotItemInstanceId)
                                        or checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, slotItemInstanceId)
                                        or checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, slotItemInstanceId)
                        ) then
                            result = true
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
                    if( isFilterActivated == true
                            and checkIfItemIsProtected(lastSellGuildIntFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastSellGuildIntFilterIconId]) then
                        result = false
                        --Filter 4 "show only marked"
                    elseif( isFilterActivated == -99 ) then
                        return checkIfItemIsProtected(lastSellGuildIntFilterIconId, slotItemInstanceId)
                        --Filter 4 off
                    else
                        if (result ~= false) then
                            result = true
                        end
                    end

                end
            end
-- Other----------------------------------------------------------------------------------------------------------------
        -- Normal treatment here
        else
            if result then
                -- Other filters
                if(isFilterActivated == true and checkIfItemIsProtected(filterId, slotItemInstanceId)) then
                    result = false
                    --Other filter "show only marked"
                elseif(isFilterActivated == -99) then
                    result = checkIfItemIsProtected(filterId, slotItemInstanceId)
                    --Other filters off
                else
                    if (result ~= false) then
                        result = true
                    end
                end
            end
        end -- if filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
    end
    return result
end

--Filter callBack function for alchemy, refine deconstruction, improvement, retrait & enchanting panels
local function FilterSavedItemsForBagIdAndSlotIndex(bagId, slotIndex, ...)
    --local itemLink = GetItemLink(bagId, slotIndex)
    --d("[FCOIS] FilterSavedItemsForBagIdAndSlotIndex: " .. itemLink)
    --This function will be executed once for EACH ITEM SLOT in your inventory/bank,
    --if you open a crafting station
    --The returned value of this filter function must be either
    --true  - Show the slot
    --false - Hide the slot
    -- Return value variable initalization: Show the slot
    local slotItemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
    --Get the filter result variable for the current item
    local itemIsShown = filterItemNow(slotItemInstanceId)
    -- Return the result if all filters were cross-checked and last filter is reached
    return itemIsShown
end

--filter callBack function for bags, bank, mail, trade, guild bank, guild store, vendor, launder, fence, etc.
local function FilterSavedItemsForSlot(slot)
    --d("[FCOIS]FilterSavedItemsForSlot")
    --This function will be executed once for EACH ITEM SLOT in your inventory
    --The returned value of this filter function must be either
    --true  - Show the slot
    --false - Hide the slot
    -- Return value variable initalization: Show the slot
    local slotItemInstanceId = myGetItemInstanceId(slot)
    --Get the filter result variable for the current item
    local itemIsShown = filterItemNow(slotItemInstanceId)
    -- Return the result if all filters were cross-checked and last filter is reached
    return itemIsShown
end

--Filter the player inventory
local function FilterPlayerInventory(filterId, panelId)
    local allowInvFilter = FCOIS.settingsVars.settings.allowInventoryFilter
    panelId = panelId or FCOIS.gFilterWhere

    --Filtering inside inventory is enabled in the settings?
    local invFilterStringPrefix = filterIds2Name[LF_INVENTORY] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
    local filterNameInv = invFilterStringPrefix .. tostring(panelId) .. "_" .. tostring(filterId)
    if allowInvFilter == true then
        --Register only 1 filter in the player inventory
        if filterId ~= -1 then
            if not libFilters:IsFilterRegistered(filterNameInv) then
                libFilters:RegisterFilter(filterNameInv, LF_INVENTORY, FilterSavedItemsForSlot)
            end
        else
            --Register all the filters in the player inventory
            for i=1, numFilters, 1 do
                local filterNameInvLoop = invFilterStringPrefix .. tostring(panelId) .. "_" .. tostring(i)
                if not libFilters:IsFilterRegistered(filterNameInvLoop) then
                    libFilters:RegisterFilter(filterNameInv, LF_INVENTORY, FilterSavedItemsForSlot)
                end
            end
        end
    else
        --Filtering inside inventory is NOT enabled in the settings: Unregister the filters
        --UnRegister only 1 filter in the player inventory
        if filterId ~= -1 then
            libFilters:UnregisterFilter(filterNameInv, LF_INVENTORY)
        else
            --UnRegister all the filters in the player inventory
            for i=1, numFilters, 1 do
                local filterNameInvLoop = invFilterStringPrefix .. tostring(panelId) .. "_" .. tostring(i)
                libFilters:UnregisterFilter(filterNameInvLoop, LF_INVENTORY)
            end
        end
    end
end

--Unregister all filters
function FCOIS.unregisterFilters(filterId, onlyPlayerInvFilter, filterPanelId)
    --Only remove filters for player inventory?
    if onlyPlayerInvFilter == nil then
        onlyPlayerInvFilter = false
    end
    local settings = FCOIS.settingsVars.settings
    --Only update a special panel, or all?
    local forVar, maxVar
    if filterPanelId ~= nil then
        forVar  = filterPanelId
        maxVar  = filterPanelId
        if settings.debug then FCOIS.debugMessage( "[unregisterFilters]","FilterPanelId: " .. tostring(filterPanelId) .. ", filterId: " .. tostring(filterId) .. ", OnlyPlayerInvFilter: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    else
        forVar  = 1
        maxVar  = numFilterInventoryTypes
        if settings.debug then FCOIS.debugMessage( "[unregisterFilters]","From panel Id: " .. tostring(forVar) .. ", To panel Id: " .. tostring(maxVar) .. ", filterId: " .. tostring(filterId) .. ", OnlyPlayerInvFilter: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end

    local unregisterArrayNew = {}
    --Unregister only 1 filter ID?
    if (filterId ~= nil and filterId ~= -1) then
        --New filter method
        for lFilterWhere=forVar, maxVar , 1 do
            if activeFilterPanelIds[lFilterWhere] == true then
                if onlyPlayerInvFilter == true then
                    local invFilterStringPrefix = filterIds2Name[LF_INVENTORY] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
                    libFilters:UnregisterFilter(invFilterStringPrefix .. tostring(lFilterWhere) .. "_" .. tostring(filterId))
                else
                    unregisterArrayNew = {}
                    --Dynamically add the LibFilters panel IDs with their prefix string to the unregister array
                    for libFiltersPanelId, filterNamePrefix in pairs(filterIds2Name) do
                        --Do not add the BACKUP panelId!
                        if libFiltersPanelId ~= FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID then
                            unregisterArrayNew[libFiltersPanelId] = filterNamePrefix .. tostring(lFilterWhere) .. "_" .. tostring(filterId)
                        end
                    end
                    if libFilters:IsFilterRegistered(unregisterArrayNew[lFilterWhere], lFilterWhere) then
                        --Unregister the registered filters for each panel
                        libFilters:UnregisterFilter(unregisterArrayNew[lFilterWhere], lFilterWhere)
                    end
                end
            end
        end

    else

        -- Unregister all filter IDs
        --New filter method
        for filterIdLoop=1, numFilters, 1 do
            for lFilterWhere=forVar, maxVar , 1 do
                if activeFilterPanelIds[lFilterWhere] == true then
                    if (onlyPlayerInvFilter == true) then
                        local invFilterStringPrefix = filterIds2Name[LF_INVENTORY] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
                        libFilters:UnregisterFilter(invFilterStringPrefix .. tostring(lFilterWhere) .. "_" .. tostring(filterIdLoop))
                    else
                        unregisterArrayNew = {}
                        --Dynamically add the LibFilters panel IDs with their prefix string to the unregister array
                        for libFiltersPanelId, filterNamePrefix in pairs(filterIds2Name) do
                            --Do not add the BACKUP panelId!
                            if libFiltersPanelId ~= FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID then
                                unregisterArrayNew[libFiltersPanelId] = filterNamePrefix .. tostring(lFilterWhere) .. "_" .. tostring(filterIdLoop)
                            end
                        end
                        --Unregister the registered filters for each panel
                        libFilters:UnregisterFilter(unregisterArrayNew[lFilterWhere], lFilterWhere)
                    end
                end
            end
        end
    end
end

--Helper function for method FCOIS.registerFilters
local function registerFilterId(p_onlyPlayerInvFilter, p_filterId, p_panelId)
    --Get the current LAF (filter type, e.g. LF_INVENTORY, LF_BANK_WITHDRAW, etc.)
    --local lf = libFilters:GetCurrentLAF()

    --Only register inventory filters?
    if (p_onlyPlayerInvFilter == true or p_panelId == LF_INVENTORY) then
        --Player inventory -> Only if activated in settings
        FilterPlayerInventory(p_filterId, p_panelId)
    else
        local settings = FCOIS.settingsVars.settings
        --Is the setting for the filter on? Check and update variable
        getFilterWhereBySettings(p_panelId, false)
        --Read the variable now
        local isFilteringAtPanelEnabled = settings.atPanelEnabled[p_panelId]["filters"] or false
        --Get the filter function now
        local filterFunctions = FCOIS.mappingVars.libFiltersId2filterFunction
        local filterFunction = filterFunctions[p_panelId]
        local filterIdStringPrefix = filterIds2Name[p_panelId] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
        --Security checks
        if not isFilteringAtPanelEnabled or filterIdStringPrefix == nil or filterIdStringPrefix == "" or filterFunction == nil or type(filterFunction) ~= "function" then
            local errorData = {
                [1] = p_filterId,
                [2] = p_panelId,
            }
            FCOIS.errorMessage2Chat("registerFilterId", 1, errorData)
            return nil
        end
        --(Re)register the filter function at the panel_id now
        local filterString = filterIdStringPrefix .. tostring(p_panelId) .. "_" .. tostring(p_filterId)
        if(not libFilters:IsFilterRegistered(filterString)) then
            libFilters:RegisterFilter(filterString, p_panelId, filterFunction)
        end
    end
end

--Register the filters by help of library libFilters
function FCOIS.registerFilters(filterId, onlyPlayerInvFilter, p_FilterPanelId)
    --Only register filters for player inventory?
    onlyPlayerInvFilter = onlyPlayerInvFilter or false

    local settings = FCOIS.settingsVars.settings
    --Register only 1 filter ID?
    if (filterId ~= nil and filterId ~= -1) then
        --Register only one filter ID

        --New or old behaviour of filtering?
        --New filtering using panels
        if settings.debug then FCOIS.debugMessage( "[registerFilters]","Panel: " .. tostring(p_FilterPanelId) .. ", OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter) .. ", filterId: " .. tostring(filterId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        --Register the filter for the given panel ID and filter ID
        registerFilterId(onlyPlayerInvFilter, filterId, p_FilterPanelId)

    else
        --Register all filter IDs
        --Using filters for each libFilters panel id
        --Only update a special panel, or all?
        local forVar, maxVar
        if (p_FilterPanelId == nil) then
            forVar  = 1
            maxVar  = numFilterInventoryTypes
        end

        for filterIdLoop=1, numFilters, 1 do
            for lFilterWhere=forVar, maxVar , 1 do
                if activeFilterPanelIds[lFilterWhere] == true then
                    if settings.debug then FCOIS.debugMessage( "[registerFilters]","Panel: " .. tostring(forVar) .. ", filterIdLoop: " .. tostring(filterIdLoop) .. ", OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                    --register the filters for the given panels
                    registerFilterId(onlyPlayerInvFilter, filterIdLoop, lFilterWhere)
                end
            end
        end

    end -- only 1 filter ID or all filter IDs?
end

--Function to fill the filter functions for each LibFilters panel ID
function FCOIS.mapLibFiltersIds2FilterFunctionsNow()
    FCOIS.mappingVars.libFiltersId2filterFunction = {
        --Filter function with inventorySlot
        [LF_INVENTORY]                              = FilterSavedItemsForSlot,
        [LF_BANK_WITHDRAW]                          = FilterSavedItemsForSlot,
        [LF_BANK_DEPOSIT]                           = FilterSavedItemsForSlot,
        [LF_GUILDBANK_WITHDRAW]                     = FilterSavedItemsForSlot,
        [LF_GUILDBANK_DEPOSIT]                      = FilterSavedItemsForSlot,
        [LF_VENDOR_SELL]                            = FilterSavedItemsForSlot,
        [LF_GUILDSTORE_SELL]                        = FilterSavedItemsForSlot,
        [LF_MAIL_SEND]                              = FilterSavedItemsForSlot,
        [LF_TRADE]                                  = FilterSavedItemsForSlot,
        [LF_FENCE_SELL]                             = FilterSavedItemsForSlot,
        [LF_FENCE_LAUNDER]                          = FilterSavedItemsForSlot,
        [LF_CRAFTBAG]                               = FilterSavedItemsForSlot,
        [LF_HOUSE_BANK_WITHDRAW]                    = FilterSavedItemsForSlot,
        [LF_HOUSE_BANK_DEPOSIT]                     = FilterSavedItemsForSlot,
        [LF_INVENTORY_COMPANION]                    = FilterSavedItemsForSlot,
        --Filter function with bagId and slotIndex
        [LF_SMITHING_REFINE]                        = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_SMITHING_DECONSTRUCT]                   = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_SMITHING_IMPROVEMENT]                   = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_SMITHING_RESEARCH]                      = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_SMITHING_RESEARCH_DIALOG]               = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_JEWELRY_REFINE]                         = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_JEWELRY_DECONSTRUCT]                    = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_JEWELRY_IMPROVEMENT]                    = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_JEWELRY_RESEARCH]                       = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_JEWELRY_RESEARCH_DIALOG]                = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_ENCHANTING_CREATION]                    = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_ENCHANTING_EXTRACTION]                  = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_RETRAIT]                                = FilterSavedItemsForBagIdAndSlotIndex,
        [LF_ALCHEMY_CREATION]                       = FilterSavedItemsForBagIdAndSlotIndex,
    }
end
