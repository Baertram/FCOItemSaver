--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local tos = tostring

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

local getAccountWideCharacterOrNormalCharacterSettings
local getFilterWhereBySettings = FCOIS.GetFilterWhereBySettings
local getSettingsIsFilterOn = FCOIS.GetSettingsIsFilterOn
local checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local myGetItemInstanceId = FCOIS.MyGetItemInstanceId


--==========================================================================================================================================
--                                          FCOIS - Filter function for LibFilters
--==========================================================================================================================================
--function shouldItemBeShownAfterBeenFiltered: filters the items accordingly to the filterButtons at the inventory. Called from FilterSavedItemsForSlot or FilterSavedItemsForBagIdAndSlotIndex
--function FilterSavedItemsForSlot: Used to filter inventories with a slot table (player inv, bank, etc.), via LibFilters' runFilters() function
--function FilterSavedItemsForBagIdAndSlotIndex: Used to filter inventories with a bagId, slotIndex (crafting tables e.g.), via LibFilters' runFilters() function as the inventory gets updated/refreshed


-- =====================================================================================================================
--  Filter functions (used library: libFilters 3.x)
-- =====================================================================================================================
--The function to filter an item in your inventories
--return value "true" = Show item
--return value "false" = Hide (filter) item
local function shouldItemBeShownAfterBeenFiltered(slotItemInstanceId, slot)
    --Check for each filter the marked items
    local result = true
    local isFilterActivated

    getAccountWideCharacterOrNormalCharacterSettings = getAccountWideCharacterOrNormalCharacterSettings or FCOIS.GetAccountWideCharacterOrNormalCharacterSettings
    local settingsOfFilterButtonStateAndIcon = getAccountWideCharacterOrNormalCharacterSettings()
    if settingsOfFilterButtonStateAndIcon == nil then
        d("<<<[FCOIS]ERROR - shouldItemBeShownAfterFilter -> settingsOfFilterButtonStateAndIcon is NIL!")
        return
    end

    local settings = FCOIS.settingsVars.settings
    --local isIconEnabled = settings.isIconEnabled

    --\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
    --TODO DEBUG: Debugging only! Remove again if not needed
    local doDebugOutput = false
    local bagId, slotIndex, itemLink
    --[[
    bagId, slotIndex = FCOIS.MyGetItemDetails(slot)
    --2021-12-04, bag item at char Hlewang:
    local isdebugSlotIndex = {
        [63] =  true,   --Ring der unermesslichen Dunkelheit
    }
    if bagId == 1 and isdebugSlotIndex[slotIndex] then
        doDebugOutput = true
    end
    if doDebugOutput then
        itemLink = (bagId ~= nil and slotIndex ~= nil and GetItemLink(bagId, slotIndex))
        d(">================================================================>")
        d("[FCOIS]>=====>shouldItemBeShownAfterFilter: " ..tos(itemLink))
    end
    ]]

    --TODO FEATURE 2022-04-05 Filtering with logical OR does not work properly that way.
    --TODO FEATURE   We need to split this functions code below up so that OR (or AND & OR combined) filtering will be working differently in total!
    --TODO FEATURE   Else the "result" will mix and give false results in total.

    --[[
    [Does work]
    -4x logical AND: All combinations

    -4x logical OR: 1st filter button + no other filter button: All combinations
    -4x logical OR: 1st filter button + 2nd filter button: 1st button yellow, 2nd button yellow (but not with 2nd button red? And only works with standard gear marker icons (not with dynamic gear marker icons!)
    -4x logical OR: 1st filter button + 3rd filter button: 1st button yellow, 3rd button yellow (but not with 3rd button red?)
    -4x logical OR: 1st filter button + 4th filter button: 1st button yellow, 4th button yellow (but not with 4th button red?)
    -4x logical OR: 1st filter button + 2nd filter button + 3rd filter button + 4th filter button: All butons yellow (but does not work wit any of them red?)

    [Does not work]
    -All other combinations


    ]]
    --////////////////////////////////////////////////////////////////////////////////

    -------------------------------------------------------------------------------------------------------
    --Check each filter button and collect the "protected ones". Do not return or abort in between to assure that filters
    --at button 4 (e.g. says hide) will also be applied if button 3 already said "only show" -> Would result in show
    --instead of hide (due to filter button 4).
    ---NEW: With FCOIS v2.2.4 new context menus with settings for the filter buttons where added at the filter buttons. You
    --->are now able to swithc between logical conjunction AND or OR and thus the filter results here need to sum up
    --->according to these settings (AND means all must apply. OR means any of them must apply).
    local filterButtonSettings = settings.filterButtonSettings
    local currentFilterPanelId = FCOIS.gFilterWhere     -- The currently filtered panelId (inventory, bank withdraw, mail, trade, etc.)
    local filterButtonSettingsForCurrentPanel = filterButtonSettings[currentFilterPanelId]
    if filterButtonSettingsForCurrentPanel == nil then
        d("[FCOIS]ERROR filterButtonSettingsForCurrentPanel = nil! gFilterWhere: " ..tos(currentFilterPanelId))
        return
    end

    if doDebugOutput then
        d(">FCOIS.gFilterWhere: " ..tos(currentFilterPanelId) .. ", filterButtonSettingsForCurrentPanel: " ..tos(filterButtonSettingsForCurrentPanel))
    end

    --The 4 filter button's settings for the logical conjunction (true = AND, false = OR)
    -------------------------------------------------------------------------------------------------------
    local lockDynFilterWithLogicalAND =         filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_LOCKDYN].filterWithLogicalAND
    local gearSetsFilterWithLogicalAND =        filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_GEARSETS].filterWithLogicalAND
    local resDecImpFilterWithLogicalAND =       filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_RESDECIMP].filterWithLogicalAND
    local sellGuildIntFilterWithLogicalAND =    filterButtonSettingsForCurrentPanel[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT].filterWithLogicalAND
    --Are all 4 filter buttons set to logical ALL conjunction?
    local allLogicalConjunctionsAreAND = (lockDynFilterWithLogicalAND == true and gearSetsFilterWithLogicalAND  == true
            and resDecImpFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true) or false
    --Are all 4 filter buttons set to logical OR conjunction?
    local allLogicalConjunctionsAreOR = (not allLogicalConjunctionsAreAND and lockDynFilterWithLogicalAND == false and gearSetsFilterWithLogicalAND  == false
            and resDecImpFilterWithLogicalAND == false and sellGuildIntFilterWithLogicalAND == false) or false
    --> only used if at least 1 logical OR conjunciton is enabled
    local filterButtonLogicalConjunctionSettings = {
        [FCOIS_CON_FILTER_BUTTON_LOCKDYN] =         lockDynFilterWithLogicalAND,
        [FCOIS_CON_FILTER_BUTTON_GEARSETS] =        gearSetsFilterWithLogicalAND,
        [FCOIS_CON_FILTER_BUTTON_RESDECIMP] =       resDecImpFilterWithLogicalAND,
        [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] =    sellGuildIntFilterWithLogicalAND,
    }
    --The results of the logical conjunction checks done at each filter button (see below at the for filterId=1, numFilters, 1 do loop)
    --> only used if at least 1 logical OR conjunciton is enabled
    local filterButtonLogicalConjunctionResults = {
        [FCOIS_CON_FILTER_BUTTON_LOCKDYN] =         true,
        [FCOIS_CON_FILTER_BUTTON_GEARSETS] =        true,
        [FCOIS_CON_FILTER_BUTTON_RESDECIMP] =       true,
        [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] =    true,
    }
    --The filter button states (true: green, false: red, -99: yellow)
    --> only used if at least 1 logical OR conjunciton is enabled
    local filterButtonStates = {
        [FCOIS_CON_FILTER_BUTTON_LOCKDYN] =         true,
        [FCOIS_CON_FILTER_BUTTON_GEARSETS] =        true,
        [FCOIS_CON_FILTER_BUTTON_RESDECIMP] =       true,
        [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] =    true,
    }

    --The table with the dynamic gear icons,which should be excluded at the normal filterButton1 "dynamic" protection checks
    local excludeDynamicGearIconsTab = mappingVars.iconToDynamicGear

    -------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    --Helper function to check if the filterButton's filter checks need to be done now, or if the current return variable's ("result")
    --boolean value already prevents this
    local function preCheckIfFilterButtonsFilterCheckNeedsToBeDone(filterButtonId, currentValue, filterButtonState)
        if doDebugOutput then d(">>preCheckFilterButton - button: " ..tos(filterButtonId) .. ", result: " ..tos(currentValue) .. ", filterButtonState: " ..tos(filterButtonState)) end
        --Only run this filterButton's filter code if all filterButton's settings for the logical conjunction are set to AND and the result overall is still "true" (show item)
        if allLogicalConjunctionsAreAND == true then
            local retVar = (filterButtonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN and true) or currentValue
            if doDebugOutput then d(">allLogicalConjunctionsAreAND - return:  " ..tos(retVar)) end
            -->Return true for the 1st filter button as the checks start with it
            -->If the overall result is false the logical AND will return false already for all buttons and no further checks are needed!
            return retVar
        else
            filterButtonStates[filterButtonId] = filterButtonState
            --Else if the filter settings of the logical conjunction is set to OR for any of the filterButtons:
            --If this filterButton's logical conjunction is set to OR
            if filterButtonLogicalConjunctionSettings[filterButtonId] == false then
                --if doDebugOutput then d("<2") end
                -->Do the checks independent from the overall "result". Only do the check if the result of the currentfilterButton's checks still is true
                return filterButtonLogicalConjunctionResults[filterButtonId] == true
            else
                --if doDebugOutput then d("<3") end
                --Current filter button is set to logical AND, so return the overall result
                return (filterButtonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN and true) or currentValue
            end
        end
        --if doDebugOutput then d("<4") end
        --All other cases: Return false so that no checks are done
        return false
    end


    --Helper function for the "red" filter button state
    local function getRedFilterButtonResult(filterButtonId, currentResult)
        --All filter button's logical conjunctions are set to AND?
        if allLogicalConjunctionsAreAND then
            --"Show" only the items if the currentResult (total result of all filter buttons checked already) is still "true"
            if currentResult ~= false then
                return true
            end
        else
            --Not all filter button's logical conjunctions are set to OR?
            if not allLogicalConjunctionsAreOR then
                --"Show" only the items if the currentResult (total result of all filter buttons checked already) is still "true"
                if currentResult ~= false then
                    return true
                end
            else
                --If all filter button's logical conjunctions are set to logical OR: "Show" all red filter button's marker icons
                return true
            end
        end
        return currentResult
    end


    --Helper function for the "green" filter button state at any filter button, and check if the result at that button
    --is already "false", then hide the item
    local function getAnyGreenFilterButtonResult(currentResult)
        --Only if overall result is currently still true (show items) and not all logical conjunctions are set to AND
        if currentResult == true and not allLogicalConjunctionsAreAND then
            for filterButtonIdOfAllFilterButtons=1, numFilters, 1 do
                --The filter buttons' logical conjunction is OR
                if filterButtonSettingsForCurrentPanel[filterButtonIdOfAllFilterButtons].filterWithLogicalAND == false
                    --and filter button state is "green" (hide)
                    and filterButtonStates[filterButtonIdOfAllFilterButtons] == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                    and filterButtonLogicalConjunctionResults[filterButtonIdOfAllFilterButtons] == false then
                    if doDebugOutput then d(">>>>getAnyGreenResult-["..tos(filterButtonIdOfAllFilterButtons).."]: false") end
                    return false
                end
            end
        end
        return currentResult
    end

    --Helper function to update the resuls of the logical OR conjunction filter button checks
    local function updateLogicalConjunctionResultsOfFilterButton(filterButtonId, newValue, p_isFilterActivated)
        --Only update if any filter button's logical OR conjunction is enabled
        if not allLogicalConjunctionsAreAND
            --ALWAYS update the result of the filterButton checks to the table filterButtonLogicalConjunctionResults

            ----if the result of the filterButton checks is false (as default value at the filter button is true = showFilteredItem)
            --and newValue == false
            ----and the current filterButton's logical conjunction is set to OR
            --and filterButtonLogicalConjunctionSettings[filterButtonId] == false
                ----and the current button's logical OR result is still true -> optional, as already checking for "newValue" being == false should be enough
                ----and filterButtonLogicalConjunctionResults[filterButtonId] == true
        then
            if doDebugOutput then d(">>>updateLogicalResult: " .. tos(newValue)) end
            filterButtonLogicalConjunctionResults[filterButtonId] = newValue
        end
    end
    -------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------
    -------------------------------------------------------------------------------------------------------

    for filterButtonId=1, numFilters, 1 do
        --Check if filter is activated for current filterButton
        isFilterActivated = getSettingsIsFilterOn(filterButtonId)
        if doDebugOutput then
            d(">button ["..tos(filterButtonId).."], state: " .. tos(isFilterActivated))
        end
------------------------------------------------------------------------------------------------------------------------------------------
--Filter button 1-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
        --Treatment for filter button 1 as it handles the lock markerIcon 1 & all the dynamic marker icons FCOIS_CON_ICON_DYNAMIC_1 to FCOIS_CON_ICON_DYNAMIC_n
        if filterButtonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
            if preCheckIfFilterButtonsFilterCheckNeedsToBeDone(filterButtonId, result, isFilterActivated) == true then
                local lastLockDynFilterIconId = settingsOfFilterButtonStateAndIcon.lastLockDynFilterIconId[currentFilterPanelId]
                --Lock & dynamic icons
                if lastLockDynFilterIconId == nil or lastLockDynFilterIconId == -1 or not settings.splitLockDynFilter then

                    --Filter 1 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN then
                        if ( checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                                --Exclude dynmic icons marked as gear here as they belong to filterButton 2
                                or checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic", nil, nil, excludeDynamicGearIconsTab) ) then
                            result = false --always "hide", no matter if logical AND or OR is used!
                        end
                    --Filter 1 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        if checkIfItemIsProtected(FCOIS_CON_ICON_LOCK, slotItemInstanceId)
                                --Exclude dynmic icons "enabled to be gear" here as they belong to filterButton 2 (FCOIS_CON_FILTER_BUTTON_GEARSETS)
                                or checkIfItemIsProtected(nil, slotItemInstanceId, "dynamic", nil, nil, excludeDynamicGearIconsTab) then
                            result = true --always "show", no matter if logical AND or OR is used!
                        else
                            result = (not lockDynFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                    --Filter 1 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                else

                    --LockDyn split enabled
                    --Last used icon ID at the LockDyn filter split context menu is stored in variable settings.lastLockDynFilterIconId[panelId]
                    --Filter 1 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN then
                        if checkIfItemIsProtected(lastLockDynFilterIconId, slotItemInstanceId) then --and isIconEnabled[lastLockDynFilterIconId] then
                            result = false --always "hide", no matter if logical AND or OR is used!
                        end
                        --Filter 1 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        if checkIfItemIsProtected(lastLockDynFilterIconId, slotItemInstanceId) then
                            result = true --always "show", no matter if logical AND or OR is used!
                        else
                            result = (not lockDynFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                        --Filter 1 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                end
                if doDebugOutput then d(">>[" ..tos(filterButtonId) .. "] " .. tos(isFilterActivated) .." (icon: " .. tos(lastLockDynFilterIconId == nil and "*" or lastLockDynFilterIconId) .."): "..tos(result)) end
                updateLogicalConjunctionResultsOfFilterButton(FCOIS_CON_FILTER_BUTTON_LOCKDYN, result, isFilterActivated)
            end
------------------------------------------------------------------------------------------------------------------------------------------
--Filter button 2-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
            --Treatment for filter button 2 as it handles "gear sets" marked items arrays 2, 4, 6, 7 and 8 and special treatment for dynamic icons "enabled to be gear".
            --Attention: As dynamic icons belong to FCOIS_CON_FILTER_BUTTON_LOCKDYN by design but can be marked as gear, and thus belong to FCOIS_CON_FILTER_BUTTON_GEARSETS then,
            --          they need to be excluded from filterButton 1 (FCOIS_CON_FILTER_BUTTON_LOCKDYN) checks above via the 5th parameter "excludedIconIds" of function checkIfItemIsProtected above!
        elseif filterButtonId == FCOIS_CON_FILTER_BUTTON_GEARSETS then
            if preCheckIfFilterButtonsFilterCheckNeedsToBeDone(filterButtonId, result, isFilterActivated) == true then
                local lastGearFilterIconId = settingsOfFilterButtonStateAndIcon.lastGearFilterIconId[currentFilterPanelId]
                --Gear filter split disabled
                if lastGearFilterIconId == nil or lastGearFilterIconId == -1 or not settings.splitGearSetsFilter then

                    --Filter 2 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (checkIfItemIsProtected(nil, slotItemInstanceId, "gear")) then
                        result = false
                        --Filter 2 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        if checkIfItemIsProtected(nil, slotItemInstanceId, "gear") then
                            result = true
                        else
                            result = (not gearSetsFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                        --Filter 2 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                else

                    --Gear filter split enabled
                    --Last used icon ID at the gear filter split context menu is stored in variable settings.lastGearFilterIconId[panelId]
                    --Filter 2 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (checkIfItemIsProtected(lastGearFilterIconId, slotItemInstanceId)) then --and isIconEnabled[lastGearFilterIconId]
                        result = false
                        --Filter 2 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW  then
                        if checkIfItemIsProtected(lastGearFilterIconId, slotItemInstanceId) then
                            result = true
                        else
                            result = (not gearSetsFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                        --Filter 2 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                end
                if doDebugOutput then d(">>[" ..tos(filterButtonId) .. "] " .. tos(isFilterActivated) .." (icon: " .. tos(lastGearFilterIconId == nil and "*" or lastGearFilterIconId) .."): "..tos(result)) end
                updateLogicalConjunctionResultsOfFilterButton(FCOIS_CON_FILTER_BUTTON_GEARSETS, result, isFilterActivated)
            end

------------------------------------------------------------------------------------------------------------------------------------------
--Filter button 3-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
        --Treatment for filter type 3: Marker icons are 3, 9 and 10
        elseif filterButtonId == FCOIS_CON_FILTER_BUTTON_RESDECIMP then
            if preCheckIfFilterButtonsFilterCheckNeedsToBeDone(filterButtonId, result, isFilterActivated) == true then
                local lastResDecImpFilterIconId = settingsOfFilterButtonStateAndIcon.lastResDecImpFilterIconId[currentFilterPanelId]
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
                            result = (not resDecImpFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                        --Filter 3 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                else

                    --Research, Deconstruction, Improvement filter split ensabled
                    --Last used icon ID at the research/deconstruction/improvement filter split context menu is stored in variable settings.lastResDecImpFilterIconId[panelId]
                    --Filter 3 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (checkIfItemIsProtected(lastResDecImpFilterIconId, slotItemInstanceId)) then --and isIconEnabled[lastResDecImpFilterIconId]
                        result = false
                        --Filter 3 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        if checkIfItemIsProtected(lastResDecImpFilterIconId, slotItemInstanceId) then
                            result = true
                        else
                            result = (not resDecImpFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                        --Filter 3 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                end
                if doDebugOutput then d(">>[" ..tos(filterButtonId) .. "] " .. tos(isFilterActivated) .." (icon: " .. tos(lastResDecImpFilterIconId == nil and "*" or lastResDecImpFilterIconId) .."): "..tos(result)) end
                updateLogicalConjunctionResultsOfFilterButton(FCOIS_CON_FILTER_BUTTON_RESDECIMP, result, isFilterActivated)
            end

------------------------------------------------------------------------------------------------------------------------------------------
--Filter button 4-------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
        --Treatment for filter button 4: Marker icons are 5, 11 and 12
        elseif filterButtonId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT then
            if preCheckIfFilterButtonsFilterCheckNeedsToBeDone(filterButtonId, result, isFilterActivated) == true then
                local lastSellGuildIntFilterIconId = settingsOfFilterButtonStateAndIcon.lastSellGuildIntFilterIconId[currentFilterPanelId]
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
                            result = (not sellGuildIntFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                        --Filter 4 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                else

                    --Sell, Sell in guild store & Intricate filter split disabled
                    --Last used icon ID at the Sell, Sell in guild store & Intricate filter split context menu is stored in variable settings.lastSellGuildIntFilterIconId[panelId]
                    --Filter 4 on
                    if isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_GREEN
                            and (checkIfItemIsProtected(lastSellGuildIntFilterIconId, slotItemInstanceId)) then -- and isIconEnabled[lastSellGuildIntFilterIconId]
                        result = false
                        --Filter 4 "show only marked"
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                        if checkIfItemIsProtected(lastSellGuildIntFilterIconId, slotItemInstanceId) then
                            result = true
                        else
                            result = (not sellGuildIntFilterWithLogicalAND and true) or false --"hide" if logical AND, "show" if logical OR is used!
                        end
                        --Filter 4 off
                    elseif isFilterActivated == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                        result = getRedFilterButtonResult(filterButtonId, result)
                    end

                end
                if doDebugOutput then d(">>[" ..tos(filterButtonId) .. "] " .. tos(isFilterActivated) .." (icon: " .. tos(lastSellGuildIntFilterIconId == nil and "*" or lastSellGuildIntFilterIconId) .."): "..tos(result)) end
                updateLogicalConjunctionResultsOfFilterButton(FCOIS_CON_FILTER_BUTTON_SELLGUILDINT, result, isFilterActivated)
            end

------------------------------------------------------------------------------------------------------------------------------------------
-- Other----------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------
        -- Normal treatment here for all other filter buttons (currently there are only 4 so this should never be called?!)
        else
            d("[FCOIS]ERROR - Filter button number must be between 1 and 4. Current: " ..tostring(filterButtonId))
            return true -- always allow then
            --[[
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
if doDebugOutput then d(">>[filterButton>4???] " .. tos(isFilterActivated) .. ": " .. tos(result)) end
            ]]
        end -- if filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
    end

------------------------------------------------------------------------------------------------------------------------------------------
-- Return the filter result and check for logical OR conjunctions, if needed
--  -> return value "true"  = Show item
--  -> return value "false" = Hide (filter) item
------------------------------------------------------------------------------------------------------------------------------------------

    --All conjunctions are logically AND -> All checks were done above already. Return the overall "result" variable now
    if allLogicalConjunctionsAreAND == true then
        --==========================
        -- Logical AND at all 4 filter buttons
        --==========================
        if doDebugOutput then  d("[FCOIS]====== AND result: " ..tos(result)) end
        return result
------------------------------------------------------------------------------------------------------------------------------------------
    else
        --Not all logical concuntions are AND, any/all is/are OR

        --The state at each filterButton
        local filterButton1State = filterButtonStates[FCOIS_CON_FILTER_BUTTON_LOCKDYN]
        local filterButton2State = filterButtonStates[FCOIS_CON_FILTER_BUTTON_GEARSETS]
        local filterButton3State = filterButtonStates[FCOIS_CON_FILTER_BUTTON_RESDECIMP]
        local filterButton4State = filterButtonStates[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]
        --Are all 4 filter buttons state's set to "green" (hide)?
        local allFilterButtonStatesAreGreen = (filterButton1State == FCOIS_CON_FILTER_BUTTON_STATE_GREEN and
                                                filterButton2State == FCOIS_CON_FILTER_BUTTON_STATE_GREEN and
                                                filterButton3State == FCOIS_CON_FILTER_BUTTON_STATE_GREEN and
                                                filterButton4State == FCOIS_CON_FILTER_BUTTON_STATE_GREEN) or false
        local allFilterButtonStatesAreYellow = (filterButton1State == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW and
                                                filterButton2State == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW and
                                                filterButton3State == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW and
                                                filterButton4State == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW) or false
        local allFilterButtonStatesAreRed = (filterButton1State == FCOIS_CON_FILTER_BUTTON_STATE_RED and
                                                filterButton2State == FCOIS_CON_FILTER_BUTTON_STATE_RED and
                                                filterButton3State == FCOIS_CON_FILTER_BUTTON_STATE_RED and
                                                filterButton4State == FCOIS_CON_FILTER_BUTTON_STATE_RED) or false
        --The result at each filterButton
        local filterButton1Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_LOCKDYN]
        local filterButton2Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_GEARSETS]
        local filterButton3Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_RESDECIMP]
        local filterButton4Result = filterButtonLogicalConjunctionResults[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]
        --All filter buttons equal "show" item?
        local allFilterButtonResultsEqualShowItem = (filterButton1Result == true and
                                                filterButton2Result == true and
                                                filterButton3Result == true and
                                                filterButton4Result == true) or false
        local logicalANDOfAllResults = filterButton1Result and filterButton2Result and filterButton3Result
                                        and filterButton4Result
        local logicalOROfAllResults = filterButton1Result or filterButton2Result or filterButton3Result
                                        or filterButton4Result

        local resultAfterLogicalConjunction = true -- Initial value: true = show the item (not filtered)
        if doDebugOutput then d(string.format("[FCOIS]Button results: %s, %s, %s, %s - Result: %s, ORResult: %s",tos(filterButton1Result),tos(filterButton2Result),tos(filterButton3Result),tos(filterButton4Result),tos(result),tos(logicalOROfAllResults))) end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
        --Check the logical conjunctions now according to the filter button settings, state and the number of OR & AND
        --conjunctions
        --==========================
        -- Logical OR at ALL of the 4 filter buttons
        --==========================
        if allLogicalConjunctionsAreOR then
            if doDebugOutput then d("[FCOIS]====== 4x OR") end

            --If all 4 filter buttons state's are set to "green" (hide): hide, or show if not marked at all -> Same as 4x logical AND conjunction
            if allFilterButtonStatesAreGreen then
                resultAfterLogicalConjunction = logicalANDOfAllResults --result
            ------------------------------------------------------------------------------------------------------------------------
            --If all 4 filter buttons state's are set to "yellow" (show only): show, or hide if not marked at all -> Same as 4x logical AND conjunction
            elseif allFilterButtonStatesAreYellow then
                resultAfterLogicalConjunction = logicalOROfAllResults
            ------------------------------------------------------------------------------------------------------------------------
            --If all 4 filter buttons state's are set to "red" (show): Show it -> Same as 4x logical AND conjunction
            elseif allFilterButtonStatesAreRed then
                resultAfterLogicalConjunction = true
            ------------------------------------------------------------------------------------------------------------------------
            --If all 4 filter buttons state's are set to different states: Do further checks
            else
                --All filter buttons say "show" item? Okay -> Show it
                if allFilterButtonResultsEqualShowItem then
                    resultAfterLogicalConjunction = true -- show

                --Is any of the filter button's result "false" (hide item)?
                else
                    --Check if any of the filter buttons' state is "green" and update the overall OR result
                    logicalOROfAllResults = getAnyGreenFilterButtonResult(logicalOROfAllResults)

                    --The filter buttons need to be combined with a logical OR conjunction
                    resultAfterLogicalConjunction = logicalOROfAllResults
                end
            end
------------------------------------------------------------------------------------------------------------------------
        else
            --==========================
            -- Logical OR at ANY of the 4 filter buttons
            --==========================
            ----------------------------
            --3 buttons with logical OR / 1 button with logical AND
            ----------------------------
            if not lockDynFilterWithLogicalAND and not gearSetsFilterWithLogicalAND
                    and not resDecImpFilterWithLogicalAND and sellGuildIntFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 3x OR 1") end
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton2Result
                        or filterButton3Result)
                        and filterButton4Result
            elseif not lockDynFilterWithLogicalAND and not gearSetsFilterWithLogicalAND
                    and not sellGuildIntFilterWithLogicalAND and resDecImpFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 3x OR 2") end
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton2Result
                        or filterButton4Result)
                        and filterButton3Result
            elseif not lockDynFilterWithLogicalAND and not resDecImpFilterWithLogicalAND
                    and not sellGuildIntFilterWithLogicalAND and gearSetsFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 3x OR 3") end
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton3Result
                        or filterButton4Result)
                        and filterButton2Result
            elseif not gearSetsFilterWithLogicalAND and not resDecImpFilterWithLogicalAND
                    and not sellGuildIntFilterWithLogicalAND and lockDynFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 3x OR 3") end
                resultAfterLogicalConjunction = (filterButton2Result
                        or filterButton3Result
                        or filterButton4Result)
                        and filterButton1Result
                ------------------------------------------------------------------------------------------------------------------------
                ----------------------------
                --2 buttons with logical OR / 2 buttons with logical AND
                ----------------------------
            elseif not lockDynFilterWithLogicalAND and not gearSetsFilterWithLogicalAND
                    and resDecImpFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 2x OR 1") end
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton2Result)
                        and filterButton3Result
                        and filterButton4Result
            elseif not lockDynFilterWithLogicalAND and not resDecImpFilterWithLogicalAND
                    and gearSetsFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 2x OR 2") end
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton3Result)
                        and filterButton2Result
                        and filterButton4Result
            elseif not lockDynFilterWithLogicalAND and not sellGuildIntFilterWithLogicalAND
                    and gearSetsFilterWithLogicalAND == true and resDecImpFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 2x OR 3") end
                resultAfterLogicalConjunction = (filterButton1Result
                        or filterButton4Result)
                        and filterButton2Result
                        and filterButton3Result
            elseif not gearSetsFilterWithLogicalAND and not resDecImpFilterWithLogicalAND
                    and lockDynFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 2x OR 3") end
                resultAfterLogicalConjunction = (filterButton2Result
                        or filterButton3Result)
                        and filterButton1Result
                        and filterButton4Result
            elseif not gearSetsFilterWithLogicalAND and not sellGuildIntFilterWithLogicalAND
                    and lockDynFilterWithLogicalAND == true and resDecImpFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 2x OR 4") end
                resultAfterLogicalConjunction = (filterButton2Result
                        or filterButton4Result)
                        and filterButton1Result
                        and filterButton3Result
            elseif not resDecImpFilterWithLogicalAND and not sellGuildIntFilterWithLogicalAND
                    and lockDynFilterWithLogicalAND == true and gearSetsFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 2x OR 5") end
                resultAfterLogicalConjunction = (filterButton3Result
                        or filterButton4Result)
                        and filterButton1Result
                        and filterButton2Result
                ------------------------------------------------------------------------------------------------------------------------
                ----------------------------
                --1 button with logical OR / 3 buttons with logical AND
                ----------------------------
            elseif not lockDynFilterWithLogicalAND
                    and gearSetsFilterWithLogicalAND == true and resDecImpFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 1x OR 1") end
                resultAfterLogicalConjunction = filterButton1Result
                        or (filterButton2Result
                        and filterButton3Result
                        and filterButton4Result)
            elseif not gearSetsFilterWithLogicalAND
                    and lockDynFilterWithLogicalAND == true and resDecImpFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 1x OR 2") end
                resultAfterLogicalConjunction = filterButton2Result
                        or (filterButton1Result
                        and filterButton3Result
                        and filterButton4Result)
            elseif not resDecImpFilterWithLogicalAND
                    and lockDynFilterWithLogicalAND == true and gearSetsFilterWithLogicalAND == true and sellGuildIntFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 1x OR 3") end
                resultAfterLogicalConjunction = filterButton3Result
                        or (filterButton1Result
                        and filterButton2Result
                        and filterButton4Result)
            elseif not sellGuildIntFilterWithLogicalAND
                    and lockDynFilterWithLogicalAND == true and gearSetsFilterWithLogicalAND == true and resDecImpFilterWithLogicalAND == true then
                if doDebugOutput then d("[FCOIS]====== 1x OR 4") end
                resultAfterLogicalConjunction = filterButton4Result
                        or (filterButton1Result
                        and filterButton2Result
                        and filterButton3Result)
            end
        end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
        if doDebugOutput then
            d("<<result AND & OR: " .. tos(resultAfterLogicalConjunction))

            FCOIS._debugFilterLogicalConjunctions = FCOIS._debugFilterLogicalConjunctions or {}
            local dflc = FCOIS._debugFilterLogicalConjunctions
            dflc[bagId] = dflc[bagId] or {}
            dflc[bagId][slotIndex] = {
                item = itemLink,
                lockDynFilterState = filterButton1State,
                lockDynFilterLog = lockDynFilterWithLogicalAND,
                gearSetsFilterState = filterButton2State,
                gearSetsFilterLog = gearSetsFilterWithLogicalAND,
                resDecImpFilterState = filterButton3State,
                resDecImpFilterLog = resDecImpFilterWithLogicalAND,
                sellGuildIntFilterState = filterButton4State,
                sellGuildIntFilterLog = sellGuildIntFilterWithLogicalAND,
                result = result,
                resultAfterLogicalConjunction = resultAfterLogicalConjunction,
            }
        end
        return resultAfterLogicalConjunction
    end
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--Filter callBack function for alchemy, refine, deconstruction, improvement, retrait & enchanting panels
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
    return shouldItemBeShownAfterBeenFiltered(slotItemInstanceId, { bagId = bagId, slotIndex = slotIndex })
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
    return shouldItemBeShownAfterBeenFiltered(slotItemInstanceId, slot)
end


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------

--Filter the player inventory
local function FilterPlayerInventory(filterId, panelId)
    local allowInvFilter = FCOIS.settingsVars.settings.allowInventoryFilter
    panelId = panelId or FCOIS.gFilterWhere

    --Filtering inside inventory is enabled in the settings?
    local invFilterStringPrefix = filterIds2Name[LF_INVENTORY] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
    local filterNameInv = invFilterStringPrefix .. tos(panelId) .. "_" .. tos(filterId)
    if allowInvFilter == true then
        --Register only 1 filter in the player inventory
        if filterId ~= -1 then
            if not isFilterRegistered(libFilters, filterNameInv) then
                registerFilter(libFilters, filterNameInv, LF_INVENTORY, FilterSavedItemsForSlot)
            end
        else
            --Register all the filters in the player inventory
            for i=1, numFilters, 1 do
                local filterNameInvLoop = invFilterStringPrefix .. tos(panelId) .. "_" .. tos(i)
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
                local filterNameInvLoop = invFilterStringPrefix .. tos(panelId) .. "_" .. tos(i)
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
        if settings.debug then debugMessage( "[unregisterFilters]","FilterPanelId: " .. tos(filterPanelId) .. ", filterId: " .. tos(filterId) .. ", OnlyPlayerInvFilter: " .. tos(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    else
        forVar  = 1
        maxVar  = numFilterInventoryTypes
        if settings.debug then debugMessage( "[unregisterFilters]","From panel Id: " .. tos(forVar) .. ", To panel Id: " .. tos(maxVar) .. ", filterId: " .. tos(filterId) .. ", OnlyPlayerInvFilter: " .. tos(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end

    local unregisterArrayNew = {}
    --Unregister only 1 filter ID?
    if (filterId ~= nil and filterId ~= -1) then
        --New filter method
        for lFilterWhere=forVar, maxVar , 1 do
            if activeFilterPanelIds[lFilterWhere] == true then
                if onlyPlayerInvFilter == true then
                    local invFilterStringPrefix = filterIds2Name[LF_INVENTORY] or filterIds2Name[FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID]
                    unregisterFilter(libFilters, invFilterStringPrefix .. tos(lFilterWhere) .. "_" .. tos(filterId))
                else
                    unregisterArrayNew = {}
                    --Dynamically add the LibFilters panel IDs with their prefix string to the unregister array
                    for libFiltersPanelId, filterNamePrefix in pairs(filterIds2Name) do
                        --Do not add the BACKUP panelId!
                        if libFiltersPanelId ~= FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID then
                            unregisterArrayNew[libFiltersPanelId] = filterNamePrefix .. tos(lFilterWhere) .. "_" .. tos(filterId)
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
                        unregisterFilter(libFilters, invFilterStringPrefix .. tos(lFilterWhere) .. "_" .. tos(filterIdLoop))
                    else
                        unregisterArrayNew = {}
                        --Dynamically add the LibFilters panel IDs with their prefix string to the unregister array
                        for libFiltersPanelId, filterNamePrefix in pairs(filterIds2Name) do
                            --Do not add the BACKUP panelId!
                            if libFiltersPanelId ~= FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID then
                                unregisterArrayNew[libFiltersPanelId] = filterNamePrefix .. tos(lFilterWhere) .. "_" .. tos(filterIdLoop)
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
--d("[FCOIS]registerFilterId - filterId: " ..tos(p_filterId) .. ", panelId: " ..tos(p_panelId) .. ", onlyPlayerInv: " ..tos(p_onlyPlayerInvFilter))
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
        local filterString = filterIdStringPrefix .. tos(p_panelId) .. "_" .. tos(p_filterId)
--d(">filterEnabledBefore: " ..tos(isFilteringAtPanelEnabledBefore) .. ", enabledNow: " ..tos(isFilteringAtPanelEnabled) .. ", filterName: " ..filterString)
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
        if settings.debug then debugMessage( "[registerFilters]","Panel: " .. tos(p_FilterPanelId) .. ", OnlyPlayerInv: " .. tos(onlyPlayerInvFilter) .. ", filterId: " .. tos(filterId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
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
                    if settings.debug then debugMessage( "[registerFilters]","Panel: " .. tos(forVar) .. ", filterIdLoop: " .. tos(filterIdLoop) .. ", OnlyPlayerInv: " .. tos(onlyPlayerInvFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
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
    assert(libFiltersMapping ~= nil and libFiltersMapping.filterTypesUsingInventorySlotFilterFunction ~= nil and libFiltersMapping.filterTypesUsingBagIdAndSlotIndexFilterFunction,
            "[FCOIS]LibFilters3 was not loaded with the needed version r3.x, including \'mapping.filterTypesUsingInventorySlotFilterFunction\'")
    if libFiltersMapping ~= nil then
        filterTypesUsingInventorySlotFilterFunction =     libFiltersMapping.filterTypesUsingInventorySlotFilterFunction
        filterTypesUsingBagIdAndSlotIndexFilterFunction = libFiltersMapping.filterTypesUsingBagIdAndSlotIndexFilterFunction
    --else
        --Fixed code for LibFilters-3.0 version < r3.0
        --Using function FilterSavedItemsForSlot
        -->Removed at 2022-08-22 as LibFilters 3 was updated and FCOIS depends on the most current version!
        --[[
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
        ]]
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
