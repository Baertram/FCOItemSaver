--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage
local debugErrorMessage2Chat = FCOIS.debugErrorMessage2Chat

local numVars = FCOIS.numVars
local mappingVars = FCOIS.mappingVars
local activeFilterPanelIds = FCOIS.mappingVars.activeFilterPanelIds
local numFilters = numVars.gFCONumFilters
local numFilterInventoryTypes = FCOIS.numVars.gFCONumFilterInventoryTypes

--The local libFilters v3.x library instance
local libFilters = FCOIS.libFilters
local isFilterRegistered = libFilters.IsFilterRegistered
local registerFilter = libFilters.RegisterFilter
local unregisterFilter = libFilters.UnregisterFilter


--The filter string names for each ID
local filterIds2Name = mappingVars.libFiltersIds2StringPrefix

local getFilterWhereBySettings = FCOIS.GetFilterWhereBySettings
local getSettingsIsFilterOn = FCOIS.GetSettingsIsFilterOn
local checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local myGetItemInstanceId = FCOIS.MyGetItemInstanceId

--==========================================================================================================================================
--                                          FCOIS - Filter function for LibFilters
--==========================================================================================================================================

-- =====================================================================================================================
--  Filter functions (used library: libFilters 3.x)
-- =====================================================================================================================

--The function to filter an item in your inventories
--return value "true" = Show item
--return value "false" = Hide (filter) item
local function filterItemNow(slotItemInstanceId)
    --Check for each filter the marked items
    local result = true
    local isFilterActivated
    local settings = FCOIS.settingsVars.settings
    local settingsOfFilterButtonStateAndIcon = FCOIS.GetAccountWideCharacterOrNormalCharacterSettings()
    if settingsOfFilterButtonStateAndIcon == nil then
        d("<<<[FCOIS]ERROR - filterItemNow -> settingsOfFilterButtonStateAndIcon is NIL!")
        return
    end
    --Check each filter button and collect the "protected ones". Do not return or abort in between to assure that filters
    --at button 4 (e.g. says hide) will also be applied if button 3 already said "only show" -> Would result in show
    --instead of hide (due to filter button 4).

    --->With FCOIS v2.2.4 new context menus with settings for the filter buttons where added at the filter buttons. You
    --->are now able to swithc between logical conjunction AND or OR and thus the filter results here need to sum up
    --->according to these settings (AND means all must apply. OR means any of them must apply).
    local filterButtonSettings = settings.filterButtonSettings
    local currentFilterPanelId = FCOIS.gFilterWhere     -- The currently filtered panelId (inventry, bank withdraw, mail, trade, etc.)
    --The 4 filter button's settings for the logical conjunction (true = AND, false = OR)
    local filterButtonSettingsForCurrentPanel = filterButtonSettings[currentFilterPanelId]
    local lockDynFilterWithLogicalAND =         filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_LOCKDYN].filterWithLogicalAND
    local gearSetsFilterWithLogicalAND =        filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_GEARSETS].filterWithLogicalAND
    local resDecImpFilterWithLogicalAND =       filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_RESDECIMP].filterWithLogicalAND
    local sellGuildIntFilterWithLogicalAND =    filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT].filterWithLogicalAND
    --Are all 4 filter buttons set to logical ALL conjunction?
    local allLogicalConjunctionsAreAND = (lockDynFilterWithLogicalAND == true and gearSetsFilterWithLogicalAND  == true
                                        and resDecImpFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true) or false
    local filterButtonLogicalConjunctionSettings = {
        [FCOIS_CON_FILTER_BUTTON_LOCKDYN] =         lockDynFilterWithLogicalAND,
		[FCOIS_CON_FILTER_BUTTON_GEARSETS] =        gearSetsFilterWithLogicalAND,
		[FCOIS_CON_FILTER_BUTTON_RESDECIMP] =       resDecImpFilterWithLogicalAND,
		[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] =    sellGuildIntFilterWithLogicalAND,
    }
    --The results of the logical conjunction checks done at each filter button (see below at the for filterId=1, numFilters, 1 do loop)
    local filterButtonLogicalConjunctionResults = {
        [FCOIS_CON_FILTER_BUTTON_LOCKDYN] =         true,
		[FCOIS_CON_FILTER_BUTTON_GEARSETS] =        true,
		[FCOIS_CON_FILTER_BUTTON_RESDECIMP] =       true,
		[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] =    true,
    }

    --Helper function to check if the filterButton's filter checks need to be done now, or if the current return variable's ("result")
    --boolean value already prevents this
    local function preCheckIfFilterButtonsFilterCheckNeedsToBeDone(filterButtonId)
        --Only run this filterButton's filter code if all filterButton's settings for the logical conjunction are set to AND and the result is still "true" (show item),
        --or the filter settings of the logical conjunction is set to OR for this filterButton and the filterResult for this button is still "true" (show item)
        return (allLogicalConjunctionsAreAND == true and result == true)
                or (filterButtonLogicalConjunctionSettings[filterButtonId] == false and filterButtonLogicalConjunctionResults[filterButtonId] == true)
    end


    for filterButtonId =1, numFilters, 1 do
        --Check if filter is activated for current filterButton
        isFilterActivated = getSettingsIsFilterOn(filterButtonId)
        --d("[FCOIS]filterItemNow - isFilterActivated: " .. tostring(isFilterActivated) .. ", filterId: " .. filterId)
--Filter button 1-------------------------------------------------------------------------------------------------------
        --Special treatment for filter type 1 as it handles the lock & all the dynamic marker icons
        if filterButtonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
            if preCheckIfFilterButtonsFilterCheckNeedsToBeDone(filterButtonId) == true then
                local lastLockDynFilterIconId = settingsOfFilterButtonStateAndIcon.lastLockDynFilterIconId[FCOIS.gFilterWhere]
                --Lock & dynamic 1 - 10
                if lastLockDynFilterIconId == nil or lastLockDynFilterIconId == -1 or not settings.splitLockDynFilter then

                    --Filter 1 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and ( checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                                    or checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic") ) then
                        result = false
                        --Filter 1 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        if checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                                or checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic") then
                            result = true
                        else
                            result = false
                        end
                        --Filter 1 off
                    else
                        if result ~= false then
                            result = true
                        end
                    end

                else

                    --LockDyn split enabled
                    --Last used icon ID at the LockDyn filter split context menu is stored in variable settings.lastLockDynFilterIconId[panelId]
                    --Filter 1 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (checkIfItemIsProtected(lastLockDynFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastLockDynFilterIconId]) then
                        result = false
                        --Filter 1 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        result = checkIfItemIsProtected(lastLockDynFilterIconId, slotItemInstanceId)
                        --Filter 1 off
                    else
                        if result ~= false then
                            result = true
                        end
                    end

                end
            end
            if not result and not lockDynFilterWithLogicalAND then
                filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_LOCKDYN] = result
            end

            --Filter button 2-------------------------------------------------------------------------------------------------------
            --Special treatment for filter type 2 as it handels "gear sets" marked items arrays 2, 4, 6, 7 and 8
        elseif filterButtonId == FCOIS_CON_FILTER_BUTTON_GEARSETS then
            if result or (not gearSetsFilterWithLogicalAND and filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_GEARSETS]) then
                local lastGearFilterIconId = settingsOfFilterButtonStateAndIcon.lastGearFilterIconId[FCOIS.gFilterWhere]
                --Gear filter split disabled
                if lastGearFilterIconId == nil or lastGearFilterIconId == -1 or not settings.splitGearSetsFilter then

                    --Filter 2 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN and (checkIfItemIsProtected(nil, slotItemInstanceId, "gear")) then
                        result = false
                        --Filter 2 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        if checkIfItemIsProtected(nil, slotItemInstanceId, "gear") then
                            result = true
                        else
                            result = false
                        end
                        --Filter 2 off
                    else
                        if result ~= false then
                            result = true
                        end
                    end

                else

                    --Gear filter split enabled
                    --Last used icon ID at the gear filter split context menu is stored in variable settings.lastGearFilterIconId[panelId]
                    --Filter 2 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (checkIfItemIsProtected(lastGearFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastGearFilterIconId]) then
                        result = false
                        --Filter 2 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW  then
                        result = checkIfItemIsProtected(lastGearFilterIconId, slotItemInstanceId)
                        --Filter 2 off
                    else
                        if result ~= false then
                            result = true
                        end
                    end

                end
            end
            if not result and not gearSetsFilterWithLogicalAND then
                filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_GEARSETS] = result
            end

            --Filter button 3-------------------------------------------------------------------------------------------------------
            --Special treatment for filter type 3, as the marked items are 3, 9 and 10
        elseif filterButtonId == FCOIS_CON_FILTER_BUTTON_RESDECIMP then
            if result or (not resDecImpFilterWithLogicalAND and filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_RESDECIMP]) then
                local lastResDecImpFilterIconId = settingsOfFilterButtonStateAndIcon.lastResDecImpFilterIconId[FCOIS.gFilterWhere]
                --Research, Deconstruction, Improvement filter split disabled
                if lastResDecImpFilterIconId == nil or lastResDecImpFilterIconId == -1 or not settings.splitResearchDeconstructionImprovementFilter then

                    --Filter 3 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (
                            checkIfItemIsProtected(FCOIS_CON_ICON_RESEARCH, slotItemInstanceId)
                                    or checkIfItemIsProtected(FCOIS_CON_ICON_DECONSTRUCTION, slotItemInstanceId)
                                    or checkIfItemIsProtected(FCOIS_CON_ICON_IMPROVEMENT, slotItemInstanceId)

                    ) then
                        result = false
                        --Filter 3 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
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
                        if result ~= false then
                            result = true
                        end
                    end

                else

                    --Research, Deconstruction, Improvement filter split ensabled
                    --Last used icon ID at the research/deconstruction/improvement filter split context menu is stored in variable settings.lastResDecImpFilterIconId[panelId]
                    --Filter 3 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (checkIfItemIsProtected(lastResDecImpFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastResDecImpFilterIconId]) then
                        return false
                        --Filter 3 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        result = checkIfItemIsProtected(lastResDecImpFilterIconId, slotItemInstanceId)
                        --Filter 3 off
                    else
                        if result ~= false then
                            result = true
                        end
                    end

                end
            end
            if not result and not resDecImpFilterWithLogicalAND then
                filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_RESDECIMP] = result
            end


--Filter button 4-------------------------------------------------------------------------------------------------------
            --Special treatment for filter type 4, as the marked items are 5, 11 and 12
        elseif filterButtonId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT then
            if result or (not sellGuildIntFilterWithLogicalAND and filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]) then
                local lastSellGuildIntFilterIconId = settingsOfFilterButtonStateAndIcon.lastSellGuildIntFilterIconId[FCOIS.gFilterWhere]
                -- Split Sell, Sell in guild store & Intricate not activated in settings
                if lastSellGuildIntFilterIconId == nil or lastSellGuildIntFilterIconId == -1 or not settings.splitSellGuildSellIntricateFilter then

                    --Filter 4 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (
                            checkIfItemIsProtected(FCOIS_CON_ICON_SELL, slotItemInstanceId)
                                    or checkIfItemIsProtected(FCOIS_CON_ICON_SELL_AT_GUILDSTORE, slotItemInstanceId)
                                    or checkIfItemIsProtected(FCOIS_CON_ICON_INTRICATE, slotItemInstanceId)
                    ) then
                        result = false
                        --Filter 4 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
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
                        if result ~= false then
                            result = true
                        end
                    end

                else

                    --Sell, Sell in guild store & Intricate filter split disabled
                    --Last used icon ID at the Sell, Sell in guild store & Intricate filter split context menu is stored in variable settings.lastSellGuildIntFilterIconId[panelId]
                    --Filter 4 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and checkIfItemIsProtected(lastSellGuildIntFilterIconId, slotItemInstanceId) and settings.isIconEnabled[lastSellGuildIntFilterIconId] then
                        result = false
                        --Filter 4 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        return checkIfItemIsProtected(lastSellGuildIntFilterIconId, slotItemInstanceId)
                        --Filter 4 off
                    else
                        if result ~= false then
                            result = true
                        end
                    end

                end
            end
            if not result and not sellGuildIntFilterWithLogicalAND then
                filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] = result
            end

-- Other----------------------------------------------------------------------------------------------------------------
        -- Normal treatment here
        else
            if result then
                -- Other filters
                if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN and checkIfItemIsProtected(filterButtonId, slotItemInstanceId) then
                    result = false
                    --Other filter "show only marked"
                elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                    result = checkIfItemIsProtected(filterButtonId, slotItemInstanceId)
                    --Other filters off
                else
                    if result ~= false then
                        result = true
                    end
                end
            end
        end -- if filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
    end

    --------------------------------------------------------------------------------------------------------------------
    -- Return the filter result and check for logical OR conjunctions, if needed
    --------------------------------------------------------------------------------------------------------------------
    --All conjunctions are logically AND -> All checks were done above already. Return the result now
    if allLogicalConjunctionsAreAND == true then
        return result
    else
        --Check the logical conjunctions now according to the filterButton settings
        --local resultBeforeLogicalConjunction = result
        local resultAfterLogicalConjunction = true

        local filterButton1Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_LOCKDYN]
        local filterButton2Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_GEARSETS]
        local filterButton3Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_RESDECIMP]
        local filterButton4Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]

        --==========================
        -- Logical OR
        --==========================
        ----------------------------
        --4 buttons with logical OR
        ----------------------------
        if not lockDynFilterWithLogicalAND and not gearSetsFilterWithLogicalAND
                and not resDecImpFilterWithLogicalAND and not sellGuildIntFilterWithLogicalAND then
            resultAfterLogicalConjunction = filterButton1Result
                        or filterButton2Result
                        or filterButton3Result
                        or filterButton4Result
        else
            ----------------------------
            --3 buttons with logical OR / 1 button with logical AND
            ----------------------------
            if not lockDynFilterWithLogicalAND and not gearSetsFilterWithLogicalAND
                    and not resDecImpFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton2Result
                        or filterButton3Result)
                        and filterButton4Result
            elseif not lockDynFilterWithLogicalAND and not gearSetsFilterWithLogicalAND
                    and not sellGuildIntFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton2Result
                        or filterButton4Result)
                        and filterButton3Result
            elseif not lockDynFilterWithLogicalAND and not resDecImpFilterWithLogicalAND
                    and not sellGuildIntFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton3Result
                        or filterButton4Result)
                        and filterButton2Result
            elseif not gearSetsFilterWithLogicalAND and not resDecImpFilterWithLogicalAND
                    and not sellGuildIntFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton2Result
                        or filterButton3Result
                        or filterButton4Result)
                        and filterButton1Result

            ----------------------------
            --2 buttons with logical OR / 2 buttons with logical AND
            ----------------------------
            elseif not lockDynFilterWithLogicalAND and not gearSetsFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton2Result)
                        and filterButton3Result
                        and filterButton4Result
            elseif not lockDynFilterWithLogicalAND and not resDecImpFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton3Result)
                        and filterButton2Result
                        and filterButton4Result
            elseif not lockDynFilterWithLogicalAND and not sellGuildIntFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton4Result)
                        and filterButton2Result
                        and filterButton3Result
            elseif not gearSetsFilterWithLogicalAND and not resDecImpFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton2Result
                        or filterButton3Result)
                        and filterButton1Result
                        and filterButton4Result
            elseif not gearSetsFilterWithLogicalAND and not sellGuildIntFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton2Result
                        or filterButton4Result)
                        and filterButton1Result
                        and filterButton3Result
            elseif not resDecImpFilterWithLogicalAND and not sellGuildIntFilterWithLogicalAND then
                resultAfterLogicalConjunction = (filterButton3Result
                        or filterButton4Result)
                        and filterButton1Result
                        and filterButton2Result

            ----------------------------
            --1 button with logical OR / 3 buttons with logical AND
            ----------------------------
            elseif not lockDynFilterWithLogicalAND then
                resultAfterLogicalConjunction = filterButton1Result
                        or (filterButton2Result
                        and filterButton3Result
                        and filterButton4Result)
            elseif not gearSetsFilterWithLogicalAND then
                resultAfterLogicalConjunction = filterButton2Result
                        or (filterButton1Result
                        and filterButton3Result
                        and filterButton4Result)
            elseif not resDecImpFilterWithLogicalAND then
                resultAfterLogicalConjunction = filterButton3Result
                        or (filterButton1Result
                        and filterButton2Result
                        and filterButton4Result)
            elseif not sellGuildIntFilterWithLogicalAND then
                resultAfterLogicalConjunction = filterButton4Result
                        or (filterButton1Result
                        and filterButton2Result
                        and filterButton3Result)
            end
        end


        return resultAfterLogicalConjunction
    end
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
    --Return the result if all filters were cross-checked and last filter is reached
    return filterItemNow(slotItemInstanceId)
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
    -- Return the result if all filters were cross-checked and last filter is reached
    return filterItemNow(slotItemInstanceId)
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
            if not isFilterRegistered(libFilters, filterNameInv) then
                registerFilter(libFilters, filterNameInv, LF_INVENTORY, FilterSavedItemsForSlot)
            end
        else
            --Register all the filters in the player inventory
            for i=1, numFilters, 1 do
                local filterNameInvLoop = invFilterStringPrefix .. tostring(panelId) .. "_" .. tostring(i)
                if not isFilterRegistered(libFilters, filterNameInvLoop) then
                    registerFilter(libFilters, filterNameInv, LF_INVENTORY, FilterSavedItemsForSlot)
                end
            end
        end
    else
        --Filtering inside inventory is NOT enabled in the settings: Unregister the filters
        --UnRegister only 1 filter in the player inventory
        if filterId ~= -1 then
            unregisterFilter(libFilters, filterNameInv, LF_INVENTORY)
        else
            --UnRegister all the filters in the player inventory
            for i=1, numFilters, 1 do
                local filterNameInvLoop = invFilterStringPrefix .. tostring(panelId) .. "_" .. tostring(i)
                unregisterFilter(libFilters, filterNameInvLoop, LF_INVENTORY)
            end
        end
    end
end

--Unregister all filters
function FCOIS.UnregisterFilters(filterId, onlyPlayerInvFilter, filterPanelId)
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
        if settings.debug then debugMessage( "[unregisterFilters]","FilterPanelId: " .. tostring(filterPanelId) .. ", filterId: " .. tostring(filterId) .. ", OnlyPlayerInvFilter: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    else
        forVar  = 1
        maxVar  = numFilterInventoryTypes
        if settings.debug then debugMessage( "[unregisterFilters]","From panel Id: " .. tostring(forVar) .. ", To panel Id: " .. tostring(maxVar) .. ", filterId: " .. tostring(filterId) .. ", OnlyPlayerInvFilter: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end

    local unregisterArrayNew = {}
    --Unregister only 1 filter ID?
    if (filterId ~= nil and filterId ~= -1) then
        --New filter method
        for lFilterWhere=forVar, maxVar , 1 do
            if activeFilterPanelIds[lFilterWhere] == true then
                if onlyPlayerInvFilter == true then
                    local invFilterStringPrefix = filterIds2Name[LF_INVENTORY] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
                    unregisterFilter(libFilters, invFilterStringPrefix .. tostring(lFilterWhere) .. "_" .. tostring(filterId))
                else
                    unregisterArrayNew = {}
                    --Dynamically add the LibFilters panel IDs with their prefix string to the unregister array
                    for libFiltersPanelId, filterNamePrefix in pairs(filterIds2Name) do
                        --Do not add the BACKUP panelId!
                        if libFiltersPanelId ~= FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID then
                            unregisterArrayNew[libFiltersPanelId] = filterNamePrefix .. tostring(lFilterWhere) .. "_" .. tostring(filterId)
                        end
                    end
                    if isFilterRegistered(libFilters, unregisterArrayNew[lFilterWhere], lFilterWhere) then
                        --Unregister the registered filters for each panel
                        unregisterFilter(libFilters, unregisterArrayNew[lFilterWhere], lFilterWhere)
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
                    if onlyPlayerInvFilter == true then
                        local invFilterStringPrefix = filterIds2Name[LF_INVENTORY] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
                        unregisterFilter(libFilters, invFilterStringPrefix .. tostring(lFilterWhere) .. "_" .. tostring(filterIdLoop))
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
                        unregisterFilter(libFilters, unregisterArrayNew[lFilterWhere], lFilterWhere)
                    end
                end
            end
        end
    end
end

--Helper function for method FCOIS.RegisterFilters
local function registerFilterId(p_onlyPlayerInvFilter, p_filterId, p_panelId)
--d("[FCOIS]registerFilterId - filterId: " ..tostring(p_filterId) .. ", panelId: " ..tostring(p_panelId) .. ", onlyPlayerInv: " ..tostring(p_onlyPlayerInvFilter))
    --Only register inventory filters?
    if p_onlyPlayerInvFilter == true or p_panelId == LF_INVENTORY then
        --Player inventory -> Only if activated in settings
        FilterPlayerInventory(p_filterId, p_panelId)
    else
        local settings = FCOIS.settingsVars.settings
        --Debugging
        --local isFilteringAtPanelEnabledBefore = settings.atPanelEnabled[p_panelId]["filters"] or false
        --Is the setting for the filter on? Check and update variable
        getFilterWhereBySettings(p_panelId, false)
        --Read the variable now
        local isFilteringAtPanelEnabled = settings.atPanelEnabled[p_panelId]["filters"] or false
        --Get the filter function now
        local filterFunctions = mappingVars.libFiltersId2filterFunction
        local filterFunction = filterFunctions[p_panelId]
        local filterIdStringPrefix = filterIds2Name[p_panelId] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
        --Security checks
        if not isFilteringAtPanelEnabled or filterIdStringPrefix == nil or filterIdStringPrefix == "" or filterFunction == nil or type(filterFunction) ~= "function" then
            local errorData = {
                [1] = p_filterId,
                [2] = p_panelId,
            }
            debugErrorMessage2Chat("registerFilterId", 1, errorData)
            return nil
        end
        --(Re)register the filter function at the panel_id now
        local filterString = filterIdStringPrefix .. tostring(p_panelId) .. "_" .. tostring(p_filterId)
--d(">filterEnabledBefore: " ..tostring(isFilteringAtPanelEnabledBefore) .. ", enabledNow: " ..tostring(isFilteringAtPanelEnabled) .. ", filterName: " ..filterString)
        if not isFilterRegistered(libFilters, filterString) then
            registerFilter(libFilters, filterString, p_panelId, filterFunction)
--       else
--d(">>>Filter is already registered!")
        end
    end
end

--Register the filters by help of library libFilters
function FCOIS.RegisterFilters(filterId, onlyPlayerInvFilter, p_FilterPanelId)
    --Only register filters for player inventory?
    onlyPlayerInvFilter = onlyPlayerInvFilter or false

    local settings = FCOIS.settingsVars.settings
    --Register only 1 filter ID?
    if (filterId ~= nil and filterId ~= -1) then
        --Register only one filter ID

        --New or old behaviour of filtering?
        --New filtering using panels
        if settings.debug then debugMessage( "[registerFilters]","Panel: " .. tostring(p_FilterPanelId) .. ", OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter) .. ", filterId: " .. tostring(filterId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
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
                    if settings.debug then debugMessage( "[registerFilters]","Panel: " .. tostring(forVar) .. ", filterIdLoop: " .. tostring(filterIdLoop) .. ", OnlyPlayerInv: " .. tostring(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                    --register the filters for the given panels
                    registerFilterId(onlyPlayerInvFilter, filterIdLoop, lFilterWhere)
                end
            end
        end

    end -- only 1 filter ID or all filter IDs?
end

--Function to fill the filter functions for each LibFilters panel ID
function FCOIS.MapLibFiltersIds2FilterFunctionsNow()
    FCOIS.mappingVars.libFiltersId2filterFunction = {}
    local filterTypesUsingInventorySlotFilterFunction = {}
    local filterTypesUsingBagIdAndSlotIndexFilterFunction = {}

    --Dynamic code for LibFilters-3.0 version >= r3.0
    local libFiltersMapping = FCOIS.libFilters.mapping
    if libFiltersMapping ~= nil then
        filterTypesUsingInventorySlotFilterFunction =     libFiltersMapping.filterTypesUsingInventorySlotFilterFunction
        filterTypesUsingBagIdAndSlotIndexFilterFunction = libFiltersMapping.filterTypesUsingBagIdAndSlotIndexFilterFunction
    else
        --Fixed code for LibFilters-3.0 version < r3.0
        --Using function FilterSavedItemsForSlot
        filterTypesUsingInventorySlotFilterFunction = {
            [LF_INVENTORY]                              = true,
            [LF_BANK_WITHDRAW]                          = true,
            [LF_BANK_DEPOSIT]                           = true,
            [LF_GUILDBANK_WITHDRAW]                     = true,
            [LF_GUILDBANK_DEPOSIT]                      = true,
            [LF_VENDOR_SELL]                            = true,
            [LF_GUILDSTORE_SELL]                        = true,
            [LF_MAIL_SEND]                              = true,
            [LF_TRADE]                                  = true,
            [LF_FENCE_SELL]                             = true,
            [LF_FENCE_LAUNDER]                          = true,
            [LF_CRAFTBAG]                               = true,
            [LF_HOUSE_BANK_WITHDRAW]                    = true,
            [LF_HOUSE_BANK_DEPOSIT]                     = true,
            [LF_INVENTORY_COMPANION]                    = true,
        }
        --Using function FilterSavedItemsForBagIdAndSlotIndex
        filterTypesUsingBagIdAndSlotIndexFilterFunction = {
            [LF_SMITHING_REFINE]                        = true,
            [LF_SMITHING_DECONSTRUCT]                   = true,
            [LF_SMITHING_IMPROVEMENT]                   = true,
            [LF_SMITHING_RESEARCH]                      = true,
            [LF_SMITHING_RESEARCH_DIALOG]               = true,
            [LF_JEWELRY_REFINE]                         = true,
            [LF_JEWELRY_DECONSTRUCT]                    = true,
            [LF_JEWELRY_IMPROVEMENT]                    = true,
            [LF_JEWELRY_RESEARCH]                       = true,
            [LF_JEWELRY_RESEARCH_DIALOG]                = true,
            [LF_ENCHANTING_CREATION]                    = true,
            [LF_ENCHANTING_EXTRACTION]                  = true,
            [LF_RETRAIT]                                = true,
            [LF_ALCHEMY_CREATION]                       = true,
        }
    end

    if filterTypesUsingInventorySlotFilterFunction then
        for filterPanelId, isUsing in pairs(filterTypesUsingInventorySlotFilterFunction) do
            if isUsing then
                FCOIS.mappingVars.libFiltersId2filterFunction[filterPanelId] = FilterSavedItemsForSlot
            end
        end
    else
        d("[FCOIS]ERROR - Filter function for filter types using inventorySlots were not found!")
    end
    if filterTypesUsingBagIdAndSlotIndexFilterFunction then
        for filterPanelId, isUsing in pairs(filterTypesUsingBagIdAndSlotIndexFilterFunction) do
            if isUsing then
                FCOIS.mappingVars.libFiltersId2filterFunction[filterPanelId] = FilterSavedItemsForBagIdAndSlotIndex
            end
        end
    else
        d("[FCOIS]ERROR - Filter function for filter types using bagId&slotIndex were not found!")
    end
end
