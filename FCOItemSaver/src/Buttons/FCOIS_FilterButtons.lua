--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

--local wm = WINDOW_MANAGER

local strfor = string.format
local tos    = tostring

local localizationVars = FCOIS.localizationVars
local locVars = localizationVars.fcois_loc

local addonVars = FCOIS.addonVars
local ctrlVars = FCOIS.ZOControlVars
local ctrlVarInv = ctrlVars.INV
local checkVars = FCOIS.checkVars
local filterButtonSuffix = checkVars.filterButtonSuffix
local gFilterPanelIdToTextureName = FCOIS.mappingVars.gFilterPanelIdToTextureName

local throttledUpdate = FCOIS.ThrottledUpdate

local numVars = FCOIS.numVars
local numFilters = numVars.gFCONumFilters

local gMappingVars = FCOIS.mappingVars
local filterButtonColors = gMappingVars.filterButtonColors
local settingsFilterStateToText = gMappingVars.settingsFilterStateToText

local availableCtms = FCOIS.contextMenuVars.availableCtms
local panelIdToUniversalDeconstructionParentData = FCOIS.mappingVars.panelIdToUniversalDeconstructionNPCParentData

local filterButtonsToCheck = FCOIS.checkVars.filterButtonsToCheck
local setSettingsIsFilterOn = FCOIS.SetSettingsIsFilterOn
local getSettingsIsFilterOn = FCOIS.GetSettingsIsFilterOn
local unregisterFilters = FCOIS.UnregisterFilters
local registerFilters = FCOIS.RegisterFilters
local filterBasics = FCOIS.FilterBasics
local getNumberOfFilteredItemsForEachPanel = FCOIS.GetNumberOfFilteredItemsForEachPanel
local getFilterWhereBySettings = FCOIS.GetFilterWhereBySettings
local getAccountWideCharacterOrNormalCharacterSettings = FCOIS.GetAccountWideCharacterOrNormalCharacterSettings

local refreshFilteredInventory = FCOIS.RefreshFilteredInventory
local addOrChangeFCOISFilterButton
local hideContextMenu
local showContextMenuAtFCOISFilterButton
local updateFCOISFilterButtonColorsAndTextures
local inventoryChangeFilterHook
local checkActivePanel
local checkMarker
local checkIfUniversalDeconstructionNPC

-- =====================================================================================================================
--  Filter state & chat output functions
-- =====================================================================================================================
--Write the info about the current filter state into the chat
--or build the tooltip text
local function outputFilterState(p_outputToChat, p_panelId, p_filterId, p_stateText)
    local filterText
    local preChatText
    local outputText
    local settings = FCOIS.settingsVars.settings
    local settingsOfFilterButtonStateAndIcon = getAccountWideCharacterOrNormalCharacterSettings()
    local mappingVars = FCOIS.mappingVars
    local preChatVars = FCOIS.preChatVars

    --Abort given because filter is/will be unregistered?
    if p_stateText == 'ABORT' then
        filterText = "_"
        preChatText = preChatVars.preChatTextRed
    else
        --Not aborted
        filterText = tos(p_filterId) .. "_"
        --Is the split lock & dynamic icons filter activated?
        if (p_filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN and settings.splitLockDynFilter)
                --Is the split research/deconstruction/improvement filter activated?
                or (p_filterId == FCOIS_CON_FILTER_BUTTON_RESDECIMP and settings.splitResearchDeconstructionImprovementFilter)
                --Is the split sell/sell in guild store/intricate filter activated?
                or (p_filterId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT and settings.splitSellGuildSellIntricateFilter) then
            filterText = filterText .. "split_"
        end
        preChatText = preChatVars.preChatTextGreen
    end

    if settings.debug then debugMessage( "[OutputFilterState]","OutputToChat: " .. tos(p_outputToChat) ..", filterPanelId: " ..tos(p_panelId)..", filterId: "..tos(p_filterId)..", stateText: " .. p_stateText, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[FCOIS]OutputFilterState-OutputToChat: " .. tos(p_outputToChat) ..", filterPanelId: " ..tos(p_panelId)..", filterId: "..tos(p_filterId)..", stateText: " .. p_stateText)
    localizationVars = FCOIS.localizationVars
    locVars = localizationVars.fcois_loc
    local filterStateText = locVars["filter" .. filterText .. p_stateText]
    local filterPanelToMediumOutputText = mappingVars.filterPanelToFilterButtonMediumOutputText
    --Create the outputText
    outputText = preChatText .. filterPanelToMediumOutputText[p_panelId] .. filterStateText

    --FCOIS v2.2.4 - Add the logical AND or logical OR conjunction information
    local filterButtonSettingsUseLogicalAND = settings.filterButtonSettings[p_panelId][p_filterId]["filterWithLogicalAND"]
    local logicalAndText = (filterButtonSettingsUseLogicalAND and locVars["options_filter_button_settings_filterWithLogicalAND_and"]) or locVars["options_filter_button_settings_filterWithLogicalAND_or"]
    local logicalTextColor = (filterButtonSettingsUseLogicalAND and "8D8D8D") or "FAFAFA"
    outputText = outputText .. "  |c4D4D4D<|c" .. logicalTextColor .. logicalAndText .. "|c4D4D4D>|r"

    --Add another tooltip line with the currently selected lock & dynamic icons filter?
    if p_filterId == FCOIS_CON_FILTER_BUTTON_LOCKDYN and settings.splitLockDynFilter then
        outputText = outputText .. "\n"
        local lastLockDynFilterIconId = settingsOfFilterButtonStateAndIcon.lastLockDynFilterIconId
        if lastLockDynFilterIconId[FCOIS.gFilterWhere] == -1 then
            outputText = outputText .. locVars["filter_lockdyn_all"]
        else
            local lockDynIconNr = lastLockDynFilterIconId[FCOIS.gFilterWhere]
            --One of the dynamic icons was selected?
            local isIconDynamic = mappingVars.iconIsDynamic
            if isIconDynamic[lockDynIconNr] then
                outputText = outputText .. settings.icon[lockDynIconNr].name
                --No dynamic icon selected (like icon 1, the "lock" icon)
            else
                outputText = outputText .. locVars["filter_lockdyn_" .. tos(lockDynIconNr)]
            end
        end

        --Add another tooltip line with the currently selected gear set filter?
    elseif p_filterId == FCOIS_CON_FILTER_BUTTON_GEARSETS and settings.splitGearSetsFilter then
        outputText = outputText .. "\n"
        local lastGearFilterIconId = settingsOfFilterButtonStateAndIcon.lastGearFilterIconId
        if lastGearFilterIconId[FCOIS.gFilterWhere] == -1 then
            outputText = outputText .. locVars["filter_gears_all"]
        else
            outputText = outputText .. settings.icon[lastGearFilterIconId[FCOIS.gFilterWhere]].name
        end

    elseif p_filterId == FCOIS_CON_FILTER_BUTTON_RESDECIMP and settings.splitResearchDeconstructionImprovementFilter then
        outputText = outputText .. "\n"
        local lastResDecImpFilterIconId = settingsOfFilterButtonStateAndIcon.lastResDecImpFilterIconId
        if lastResDecImpFilterIconId[FCOIS.gFilterWhere] == -1 then
            outputText = outputText .. locVars["filter_resdecimp_all"]
        else
            outputText = outputText .. locVars["filter_resdecimp_" .. tos(mappingVars.iconToResDecImp[lastResDecImpFilterIconId[FCOIS.gFilterWhere]])]
        end

    elseif p_filterId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT and settings.splitSellGuildSellIntricateFilter then
        outputText = outputText .. "\n"
        local lastSellGuildIntFilterIconId = settingsOfFilterButtonStateAndIcon.lastSellGuildIntFilterIconId
        if lastSellGuildIntFilterIconId[FCOIS.gFilterWhere] == -1 then
            outputText = outputText .. locVars["filter_sellguildint_all"]
        else
            outputText = outputText .. locVars["filter_sellguildint_" .. tos(mappingVars.iconToSellGuildInt[lastSellGuildIntFilterIconId[FCOIS.gFilterWhere]])]
        end
    end

--d("<<p_panelId/gFilterWhere: " ..tos(p_panelId) .. "/" .. tos(FCOIS.gFilterWhere))

    --Output to chat or return text only?
    if p_outputToChat == true then
        d(outputText)
    else
        return outputText
    end
end


-- =====================================================================================================================
--  Filter button functions
-- =====================================================================================================================
--Get the filter button data for each LibFilters panel, to distinguish e.g. the size and positions of the filter buttons at LF_INVENTORY
--from the size at LF_SMITHING_RESEARCH
function FCOIS.CheckAndTransferFCOISFilterButtonDataByPanelId(libFiltersPanelId, filterButtonNr)
    libFiltersPanelId = libFiltersPanelId or LF_INVENTORY
    local activeFilterPanelIds = FCOIS.mappingVars.activeFilterPanelIds
    local isActiveFilterPanelId = activeFilterPanelIds[libFiltersPanelId] or false
    if not isActiveFilterPanelId then return false end
    --Get the backup data if no settings were changed and saved yet
    local filterButtonDataAllPanelsBackup = FCOIS.filterButtonVars
    if filterButtonDataAllPanelsBackup == nil then return nil end
    --Check if the settings got data about the filterButton variables already for the given libFiltersPanelId
------------------------------------------------------------------------------------------------------------------------
    --Local function for check and transfer old settings structure to new settings structure
    local function checkAndTransferFilterButtonData(p_libFiltersPanelId, p_filterButtonNr)
        local settings = FCOIS.settingsVars.settings
        local left, top, width, height
        local useOldFilterButtonDataLeft = false
        local useOldFilterButtonDataTop = false
        local useOldFilterButtonDataWidth = false
        local useOldFilterButtonDataHeight = false
        --New settings
        if settings.filterButtonData ~= nil and settings.filterButtonData[p_filterButtonNr] ~= nil then
            settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId] = settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId] or {}
            local filterButtonDataForPanelId = settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId]
            if filterButtonDataForPanelId["left"] ~= nil and filterButtonDataForPanelId["left"] ~= 0 then
                --left = filterButtonDataForPanelId["left"]
            else
                useOldFilterButtonDataLeft = true
            end
            if filterButtonDataForPanelId["top"] ~= nil and filterButtonDataForPanelId["top"] ~= 0 then
                --top = filterButtonDataForPanelId["top"]
            else
                useOldFilterButtonDataTop = true
            end
            if filterButtonDataForPanelId["width"] ~= nil and filterButtonDataForPanelId["width"] ~= 0 then
                --width = filterButtonDataForPanelId["width"]
            else
                useOldFilterButtonDataWidth = true
            end
            if filterButtonDataForPanelId["height"] ~= nil and filterButtonDataForPanelId["height"] ~= 0 then
                --height = filterButtonDataForPanelId["height"]
            else
                useOldFilterButtonDataHeight = true
            end
        else
            useOldFilterButtonDataLeft      = true
            useOldFilterButtonDataTop       = true
            useOldFilterButtonDataWidth     = true
            useOldFilterButtonDataHeight    = true
        end
        --Determine filterButton data the old way (settings first, if not given: Use the default static values from constants)
        if useOldFilterButtonDataLeft or useOldFilterButtonDataTop then
            settings.filterButtonData = settings.filterButtonData or {}
            settings.filterButtonData[p_filterButtonNr] = settings.filterButtonData[p_filterButtonNr] or {}
            settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId] = settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId] or {}
            --Use the fallback value, and then clear the fallback value from the old settings
            if useOldFilterButtonDataLeft then
                if settings.filterButtonLeft[p_filterButtonNr] ~= nil then
                    left = settings.filterButtonLeft[p_filterButtonNr]
                else
                    --Use the leftfallback value for all panels
                    left = filterButtonDataAllPanelsBackup.gFilterButtonLeft[p_filterButtonNr]
                end
                --Clear the old settings data and transfer it to the new settings structure
                settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId]["left"] = left
                settings.filterButtonLeft[p_filterButtonNr] = nil
            end
            if useOldFilterButtonDataTop then
                if settings.filterButtonTop[p_filterButtonNr] ~= nil then
                    top = settings.filterButtonTop[p_filterButtonNr]
                else
                    --Use the top fallback value for all panels
                    top = filterButtonDataAllPanelsBackup.gFilterButtonTop
                end
                --Clear the old settings data and transfer it to the new settings structure
                settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId]["top"] = top
                settings.filterButtonTop[p_filterButtonNr] = nil
            end
            if useOldFilterButtonDataWidth then
                width = filterButtonDataAllPanelsBackup.gFilterButtonWidth
                --Clear the old settings data and transfer it to the new settings structure
                settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId]["width"] = width
            end
            if useOldFilterButtonDataHeight then
                height = filterButtonDataAllPanelsBackup.gFilterButtonHeight
                --Clear the old settings data and transfer it to the new settings structure
                settings.filterButtonData[p_filterButtonNr][p_libFiltersPanelId]["height"] = height
            end
        end
    end -- end of local function
------------------------------------------------------------------------------------------------------------------------
    --Is a button to check given?
    if filterButtonNr ~= nil and filterButtonNr ~= -1 then
        checkAndTransferFilterButtonData(libFiltersPanelId, filterButtonNr)
        return true
    else
        --local filterButtonsToCheck = FCOIS.checkVars.filterButtonsToCheck
        if filterButtonsToCheck ~= nil then
            --Check each filter button's settings
            for _, filterButtonNrLoop in ipairs(filterButtonsToCheck) do
                checkAndTransferFilterButtonData(libFiltersPanelId, filterButtonNrLoop)
            end
            return true
        end
    end
    return nil
end
local checkAndTransferFCOISFilterButtonDataByPanelId = FCOIS.CheckAndTransferFCOISFilterButtonDataByPanelId

--Set all the filter button settings equal/to the same value of a given filter panel ID
function FCOIS.SetAllFCOISFilterButtonOffsetAndSizeSettingsEqual(filterPanelIdSource)
    if filterPanelIdSource == nil then return false end
    --local filterButtonsToCheck = FCOIS.checkVars.filterButtonsToCheck
    if filterButtonsToCheck ~= nil then
        local settings = FCOIS.settingsVars.settings
        local activeFilterPanelIds = FCOIS.mappingVars.activeFilterPanelIds
        --Check each filter button's settings
        for _, filterButtonNr in ipairs(filterButtonsToCheck) do
            for filterPanelIdTarget, active in pairs(activeFilterPanelIds) do
                if active and filterPanelIdSource ~= filterPanelIdTarget then
                    --Copy source settings to target settings
                    if settings.filterButtonData ~= nil and settings.filterButtonData[filterButtonNr] ~= nil then
                        --Get source settings
                        local sourceSettings = ZO_DeepTableCopy(settings.filterButtonData[filterButtonNr][filterPanelIdSource])
                        if sourceSettings ~= nil then
                            FCOIS.settingsVars.settings.filterButtonData[filterButtonNr][filterPanelIdTarget] = {}
                            FCOIS.settingsVars.settings.filterButtonData[filterButtonNr][filterPanelIdTarget] = sourceSettings
                        end
                    end
                end
            end
        end
        return true
    end
    return false
end

--Add/Change the 4 FCOIS filter buttons at the inventory's bottom row
function FCOIS.UpdateFCOISFilterButtonsAtInventory(buttonId)
    addOrChangeFCOISFilterButton = addOrChangeFCOISFilterButton or FCOIS.AddOrChangeFCOISFilterButton
    -- This function will only add the inventory buttons!
    -- All other buttons will be added as the relating panel (bank, store, deconstruction, etc.) will be shown the first time.
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[updateFilterButtonsInInv]","buttonId: " .. tos(buttonId) .. ", numFilters: ".. tos(numFilters) .. ", InvFiltering: " .. tos(settings.allowInventoryFilter), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY)
    local currentFilterPanelId = FCOIS.gFilterWhere
    checkIfUniversalDeconstructionNPC  = checkIfUniversalDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC   -- #202
    local isUniversalDeconNPC = checkIfUniversalDeconstructionNPC(currentFilterPanelId)                                 -- #202

--d("[FCOIS.updateFilterButtonsInInv] buttonId: " ..tos(buttonId) .. ", filterId: " ..tostring(currentFilterPanelId))
    -- Update the filter enable/disable buttons to the inventory, bank, crafting stations, enchantment station, guild store, guild bank, vendor, trade, alchemy and mail panels
    if buttonId == nil or buttonId == -1 then

        --Change the filter buttons & callback functions
        for _, buttonNr in ipairs(filterButtonsToCheck) do
            --Check the filter button's offsets, width and height at the given LibFilters panel ID
            checkAndTransferFCOISFilterButtonDataByPanelId(currentFilterPanelId, buttonNr)
            local filterButtonData = settings.filterButtonData[buttonNr][currentFilterPanelId]
            if filterButtonData ~= nil then
                if settings.debug then debugMessage( "[updateFilterButtonsInInv]","Next buttonId " .. tos(buttonNr) .. " at panel [" .. currentFilterPanelId  .. "]-left: " .. tos(filterButtonData["left"]).. ", top: " .. tos(filterButtonData["top"]).. ", width: " .. tos(filterButtonData["width"]).. ", height: " .. tos(filterButtonData["height"]), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d(">FilterButtonData at panel [" .. currentFilterPanelId  .. "] of button " ..tos(buttonNr) .." - left: " .. tos(filterButtonData["left"]).. ", top: " .. tos(filterButtonData["top"]).. ", width: " .. tos(filterButtonData["width"]).. ", height: " .. tos(filterButtonData["height"]))
                --Get the filter button control (create or modify) and reanchor  it
                addOrChangeFCOISFilterButton(ctrlVarInv, buttonNr, filterButtonData["width"], filterButtonData["height"], filterButtonData["left"], filterButtonData["top"], not settings.allowInventoryFilter, currentFilterPanelId, isUniversalDeconNPC) -- #202
            end
        end
    else
        --Check the filter button's offsets, width and height at the given LibFilters panel ID
        checkAndTransferFCOISFilterButtonDataByPanelId(currentFilterPanelId, buttonId)
        local filterButtonData = settings.filterButtonData[buttonId][currentFilterPanelId]
        if filterButtonData ~= nil then
            addOrChangeFCOISFilterButton(ctrlVarInv, buttonId, filterButtonData["width"], filterButtonData["height"], filterButtonData["left"], filterButtonData["top"], not settings.allowInventoryFilter, currentFilterPanelId, isUniversalDeconNPC) -- #202
        end
    end
end

--Update the filter button colors and textures, depending on the filters (and chosen sub-filter icons)
function FCOIS.UpdateFCOISFilterButtonColorsAndTextures(p_buttonId, p_button, p_status, p_filterPanelId)
    updateFCOISFilterButtonColorsAndTextures = updateFCOISFilterButtonColorsAndTextures or FCOIS.UpdateFCOISFilterButtonColorsAndTextures
    local p_statusText = p_status or "Not changed!"
    p_filterPanelId = p_filterPanelId or FCOIS.gFilterWhere
    local settings = FCOIS.settingsVars.settings
    local settingsOfFilterButtonStateAndIcon = getAccountWideCharacterOrNormalCharacterSettings()

    local filterToIcon = FCOIS.mappingVars.filterToIcon
    local texVars = FCOIS.textureVars
    local texMarkerVars = texVars.MARKER_TEXTURES
    local texMarkerVars_SIZE = texVars.MARKER_TEXTURES_SIZE

    local updateTextureSizeIndex
    local btnName = ">< No button ><"
    if p_button ~= nil then
        btnName = p_button:GetName()
    end

    if settings.debug then debugMessage( "[UpdateButtonColorsAndTextures]","Button: " .. btnName .. ", ButtonId: " .. tos(p_buttonId) .. ", Status: " .. tos(p_status) .. ", FilterPanelId: " .. tos(p_filterPanelId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[FCOIS]UpdateButtonColorsAndTextures-Button: " .. btnName .. ", ButtonId: " .. tos(p_buttonId) .. ", Status: " .. tos(p_status) .. ", FilterPanelId: " .. tos(p_filterPanelId))
    local texture
    --local offset
    if p_buttonId == -1 or p_status == -1 then
        -- for Schleife für 4 Buttons -> Initialisierung beim Laden des Addons
        -- Läd für die Ansicht p_filterPanelId die Farben der 4 Filter Buttons
        for i=1, numFilters, 1 do
            updateFCOISFilterButtonColorsAndTextures(i, nil, getSettingsIsFilterOn(i, p_filterPanelId), p_filterPanelId)
        end

    else --if (p_buttonId == -1 or p_status == -1) then
        local textureNameOfFilterButton = strfor(gFilterPanelIdToTextureName[p_filterPanelId], p_buttonId)
        texture  = GetControl(textureNameOfFilterButton) --wm:GetControlByName(textureNameOfFilterButton, "")
        --Does texture exist now?
        if texture ~= nil then
            --Is the gear sets split filter button context-menu active and are we trying to change the texture of the gear sets button?
            if p_buttonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN and settings.splitLockDynFilter then
                --Are all icons, lock & 4 dynamic ones, selected?
                local lastLockDynFilterIconId = settingsOfFilterButtonStateAndIcon.lastLockDynFilterIconId
                if lastLockDynFilterIconId[p_filterPanelId] == -1 then
                    texture:SetTexture(texVars.allLockDyn)
                    updateTextureSizeIndex = "LockDyn"
                    --Only one of the icons is selected
                else
                    updateTextureSizeIndex = settings.icon[lastLockDynFilterIconId[p_filterPanelId]].texture
                    texture:SetTexture(texMarkerVars[updateTextureSizeIndex])
                end
                --Is the gear sets split filter button context-menu active and are we trying to change the texture of the gear sets button?
            elseif p_buttonId == FCOIS_CON_FILTER_BUTTON_GEARSETS and settings.splitGearSetsFilter then
                --Are all gear sets selected?
                local lastGearFilterIconId = settingsOfFilterButtonStateAndIcon.lastGearFilterIconId
                if lastGearFilterIconId[p_filterPanelId] == -1 then
                    texture:SetTexture(texVars.allGearSets)
                    updateTextureSizeIndex = "Gear"
                    --Only one of the gear sets is selected
                else
                    updateTextureSizeIndex = settings.icon[lastGearFilterIconId[p_filterPanelId]].texture
                    texture:SetTexture(texMarkerVars[updateTextureSizeIndex])
                end
            elseif p_buttonId == FCOIS_CON_FILTER_BUTTON_RESDECIMP and settings.splitResearchDeconstructionImprovementFilter then
                --Are all entries seleted (Research, Deconstruction, Improvement)?
                local lastResDecImpFilterIconId = settingsOfFilterButtonStateAndIcon.lastResDecImpFilterIconId
                if lastResDecImpFilterIconId[p_filterPanelId] == -1 then
                    texture:SetTexture(texVars.allResDecImp)
                    updateTextureSizeIndex = "ResDecImp"
                    --Only one of the options is selected
                else
                    updateTextureSizeIndex = settings.icon[lastResDecImpFilterIconId[p_filterPanelId]].texture
                    texture:SetTexture(texMarkerVars[updateTextureSizeIndex])
                end
            elseif p_buttonId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT and settings.splitSellGuildSellIntricateFilter then
                --Are all entries seleted (Sell, Sell in guild store & Intricate)?
                local lastSellGuildIntFilterIconId = settingsOfFilterButtonStateAndIcon.lastSellGuildIntFilterIconId
                if lastSellGuildIntFilterIconId[p_filterPanelId] == -1 then
                    texture:SetTexture(texVars.allSellGuildInt)
                    updateTextureSizeIndex = "SellGuildInt"
                    --Only one of the options is selected
                else
                    updateTextureSizeIndex = settings.icon[lastSellGuildIntFilterIconId[p_filterPanelId]].texture
                    texture:SetTexture(texMarkerVars[updateTextureSizeIndex])
                end
            else
                --Workaround to show at least a default texure, if none is found
                local iconId = filterToIcon[p_buttonId] or 1
                if (texMarkerVars[settings.icon[iconId].texture] ~= nil) then
                    --Set the texture now
                    updateTextureSizeIndex = settings.icon[iconId].texture
                    texture:SetTexture(texMarkerVars[updateTextureSizeIndex])
                else
                    --Set fallback texture now
                    updateTextureSizeIndex = iconId
                    texture:SetTexture(texMarkerVars[updateTextureSizeIndex])
                    --Set the fallback texture to the settings menu
                    settings.icon[iconId].texture = iconId
                end
            end -- if p_buttonId == 1 and settings...

            --Get current status and reset the current texture color
            if ((   p_buttonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN or p_buttonId == FCOIS_CON_FILTER_BUTTON_GEARSETS
                    or p_buttonId == FCOIS_CON_FILTER_BUTTON_RESDECIMP or p_buttonId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT) and p_statusText == "Not changed!") then
                p_status = getSettingsIsFilterOn(p_buttonId, p_filterPanelId)
            end

            --Only update colors if wished. FCOIS_CON_FILTER_BUTTON_STATE_DO_NOT_UPDATE_COLOR will be set in FCOIS settings menu e.g. when you update the filter button's color there
            if p_status ~= FCOIS_CON_FILTER_BUTTON_STATE_DO_NOT_UPDATE_COLOR then
                --Update the color of the filterbutton dependend on the state (FCOIS_CON_FILTER_BUTTON_STATE_GREEN, FCOIS_CON_FILTER_BUTTON_STATE_YELLOW, FCOIS_CON_FILTER_BUTTON_STATE_RED
                texture:SetColor(unpack(filterButtonColors[p_status]))
            end -- if p_status ~= -FCOIS_CON_FILTER_BUTTON_STATE_DO_NOT_UPDATE_COLOR then
        --else
            --d("<<<[FCOIS]ERROR-FilterButton texture control not found: " ..tos(textureNameOfFilterButton) .. ", filterPanelId: " ..tos(p_filterPanelId) .. ", buttonNr: " ..tos(p_buttonId))
        end -- iftexture ~= nil then

    end -- if p_buttonId == -1 or p_status == -1 then

    --Update the texture's size now
    if updateTextureSizeIndex ~= nil and texture ~= nil then
        local parentWindow = texture:GetParent()
        --local pLeft = texture:GetLeft()
        --local pTop  = texture:GetTop()

        --Get the new texture size by help of the index/index string
        if updateTextureSizeIndex == "LockDyn" then
            texture:ClearAnchors()
            texture:SetDimensions(texVars.allLockDynWidth, texVars.allLockDynHeight)
            texture:SetAnchorFill()
            --texture:SetAnchor(TOP, parentWindow, BOTTOM, pLeft, pTop)

            --Get the new texture size by help of the index/index string
        elseif updateTextureSizeIndex == "Gear" then
            texture:ClearAnchors()
            texture:SetDimensions(texVars.allGearSetsWidth, texVars.allGearSetsHeight)
            texture:SetAnchorFill()
            --texture:SetAnchor(TOP, parentWindow, BOTTOM, pLeft, pTop)

        elseif updateTextureSizeIndex == "ResDecImp" then
            texture:ClearAnchors()
            texture:SetDimensions(texVars.allResDecImpWidth, texVars.allResDecImpHeight)
            texture:SetAnchorFill()
            --texture:SetAnchor(TOP, parentWindow, BOTTOM, pLeft, pTop)

        elseif updateTextureSizeIndex == "SellGuildInt" then
            texture:ClearAnchors()
            texture:SetDimensions(texVars.allSellGuildIntWidth, texVars.allSellGuildIntHeight)
            texture:SetAnchorFill()
            --texture:SetAnchor(TOP, parentWindow, BOTTOM, pLeft, pTop)

        elseif type(updateTextureSizeIndex) == "number" then
            if texMarkerVars_SIZE[updateTextureSizeIndex] ~= nil and
                    texMarkerVars_SIZE[updateTextureSizeIndex].width ~= nil and texMarkerVars_SIZE[updateTextureSizeIndex].height ~= nil and
                    texMarkerVars_SIZE[updateTextureSizeIndex].width > 0 and texMarkerVars_SIZE[updateTextureSizeIndex].height > 0 then
                texture:ClearAnchors()
                texture:SetDimensions(texMarkerVars_SIZE[updateTextureSizeIndex].width, texMarkerVars_SIZE[updateTextureSizeIndex].height)
                --texture:SetAnchorFill()
                texture:SetAnchor(TOP, parentWindow, BOTTOM, texMarkerVars_SIZE[updateTextureSizeIndex].offsetLeft, texMarkerVars_SIZE[updateTextureSizeIndex].offsetTop)
            else
                texture:ClearAnchors()
                local filterButtonVars = FCOIS.filterButtonVars
                texture:SetDimensions(filterButtonVars.gFilterButtonWidth, filterButtonVars.gFilterButtonHeight)
                texture:SetAnchorFill()
                --texture:SetAnchor(TOP, parentWindow, BOTTOM, pLeft, pTop)
            end
        end
    end
end
updateFCOISFilterButtonColorsAndTextures = FCOIS.UpdateFCOISFilterButtonColorsAndTextures


-- -v- #202
local function getUniversalDeconstructionNPCParentAndAnchor(p_FilterPanelId)
--d("[FCOIS]getUniversalDeconstructionNPCParentAndAnchor-p_FilterPanelId: " ..tos(p_FilterPanelId))
    local universalDeconParentDataByPanelId = panelIdToUniversalDeconstructionParentData[p_FilterPanelId]
    return universalDeconParentDataByPanelId.parent, universalDeconParentDataByPanelId.anchorTo
end
-- -^- #202


--Check if the 4 filter buttons exist at the selected panel "panelId" and create them if they are missing
--Update the color and texture of the buttons too
function FCOIS.CheckFCOISFilterButtonsAtPanel(doUpdateLists, panelId, overwriteFilterWhere, hideFilterButtons, isUniversalDeconNPC, universalDeconFilterPanelIdBefore)
    hideFilterButtons = hideFilterButtons or false
    isUniversalDeconNPC = isUniversalDeconNPC or false
    addOrChangeFCOISFilterButton = addOrChangeFCOISFilterButton or FCOIS.AddOrChangeFCOISFilterButton
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[CheckFilterButtonsAtPanel]","Start - Check panel ID: " ..tos(panelId) .. ", overwriteFilterWhere: " .. tos(overwriteFilterWhere) .. ", hideFilterButtons: " .. tos(hideFilterButtons).. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC) .. ", universalDeconFilterPanelIdBefore: " ..tos(universalDeconFilterPanelIdBefore), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[FCOIS.CheckFilterButtonsAtPanel - panelId: " .. tos(panelId) .. ", gFilterWhere: " .. tos(FCOIS.gFilterWhere) .. ", UseFilters: " .. tos(settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"]) .. ", hideFilterButtons: " ..tos(hideFilterButtons).. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC) .. ", universalDeconFilterPanelIdBefore: " ..tos(universalDeconFilterPanelIdBefore))

    --Should we update the marker textures, size and color?
    checkMarker = checkMarker or FCOIS.CheckMarker
    checkMarker(-1)

    --Get the currently shown panel and update FCOIS.gFilterWhere with the "goingTo" value (called from e.g. FCOIS.PreHookMainMenuFilterButtonHandler)
    checkActivePanel = checkActivePanel or FCOIS.CheckActivePanel
    local buttonsParentCtrl, filterPanel = checkActivePanel(panelId, overwriteFilterWhere, isUniversalDeconNPC) -- #202
    local filterPanelIdToUse = FCOIS.gFilterWhere

--d(">buttonParentName: " .. tos(buttonsParentCtrl:GetName()) .. ", FilterPanelId/ParentPanelId/gFilterWhere:: " .. tos(filterPanelIdToUse) .. "/" .. tos(filterPanel) .. "/" .. tos(FCOIS.gFilterWhere))

    --Is an inventory found? The parent will be the filter button's parent
    if buttonsParentCtrl ~= nil then
        if settings.debug then debugMessage("[CheckFilterButtonsAtPanel]", buttonsParentCtrl:GetName() .. ", FilterPanelId: " .. tos(filterPanelIdToUse) .. ", UseFilters: " .. tos(settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"]), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        --local filterButtonVars = FCOIS.filterButtonVars
        --Is the setting enabled to use the filters at this panel?
        local areFilterButtonEnabledAtPanelId = false
        if hideFilterButtons == false then areFilterButtonEnabledAtPanelId = (settings.atPanelEnabled[filterPanelIdToUse]["filters"] == true and true) or false end --#266
--d(">areFilterButtonEnabledAtPanelId: " ..tos(areFilterButtonEnabledAtPanelId) .. ", hideFilterButtons: " .. tos(hideFilterButtons) .. "; settings: " ..tos(settings.atPanelEnabled[filterPanelIdToUse]["filters"]))
        local filterBtn
        local isFilterActivated
        local filterButtons = FCOIS.filterButtonVars.filterButtons

        --For debugging only!
        if isUniversalDeconNPC == true then
--d(">>>>>>>>>>> CheckFCOISFilterButtonsAtPanel - UniversalDecon >>>>>>>")
        end

        --Change the filter buttons & callback functions
        for _, buttonNr in ipairs(filterButtonsToCheck) do
            --#202 Hide the last shown buttons at the universal deconstruction UI, if they are not the same to use for the current
            if isUniversalDeconNPC == true then
--d("button: " ..tos(buttonNr) ..", before: " .. tos(universalDeconFilterPanelIdBefore) .. ", now: " ..tos(filterPanelIdToUse))
                if universalDeconFilterPanelIdBefore ~= nil then
--d(">universalDeconFilterPanelIdBefore NOT nil")
                    if universalDeconFilterPanelIdBefore ~= filterPanelIdToUse then
--d(">>current and old panel differ")
                        if filterButtons[universalDeconFilterPanelIdBefore] == nil then
--d(">>>filterButtons["..tos(universalDeconFilterPanelIdBefore).."] do NOT exist")
                            --The filterButtons of the jewelry decon. re-use the normal decon filterButtonControls. Though the "1st" opened at the normal crafting tables will be only saved
                            --to table FCOIS.filterButtonVars.filterButtons-> filterButtons
                            --So we need to check here which button exist, LF_JEWELRY_DECONSTRUCT or LF_SMITHING_DECONSTRUCT, and use it
                            if universalDeconFilterPanelIdBefore == LF_JEWELRY_DECONSTRUCT or universalDeconFilterPanelIdBefore == LF_SMITHING_DECONSTRUCT then
--d(">>>>swithching jewelry decon<>smithing decon")
                                --Switch the deconstructable filterType to the other crafting types filterType, e.g. LF_JEWELRY_DECONSTRUCT -> LF_SMITHING_DECONSTRUCT
                                -->to get the correct filterbutton variables (which get reused) from FCOIS.filterButtonVars.filterButtons
                                universalDeconFilterPanelIdBefore = FCOIS.mappingVars.deconstructablePanelIdToOtherCraftType[universalDeconFilterPanelIdBefore]
                            else
--d(">>>>swithching enchanting create<>extract")
                                --Switch the deconstructable filterType to the other crafting types filterType, e.g. LF_ENCHANTING_CREATION -> LF_ENCHANTING_EXTRACTION
                                -->to get the correct filterbutton variables (which get reused) from FCOIS.filterButtonVars.filterButtons
                                if universalDeconFilterPanelIdBefore == LF_ENCHANTING_CREATION then
                                    universalDeconFilterPanelIdBefore = LF_ENCHANTING_EXTRACTION
                                elseif universalDeconFilterPanelIdBefore == LF_ENCHANTING_EXTRACTION then
                                    universalDeconFilterPanelIdBefore = LF_ENCHANTING_CREATION
                                end
                            end
                        else
--d(">>>filterButtons["..tos(universalDeconFilterPanelIdBefore).."] exist")
                        end
                    else
--d(">current and old panel are the same")
                    end

                    --Stil nil?
                    if filterButtons[universalDeconFilterPanelIdBefore] ~= nil then
--d(">filterButtons["..tos(universalDeconFilterPanelIdBefore).."] will be hidden now!")
                        --[[
                        user:/AddOns/FCOItemSaver/src/Buttons/FCOIS_FilterButtons.lua:603: attempt to index a nil value
                        stack traceback:
                        user:/AddOns/FCOItemSaver/src/Buttons/FCOIS_FilterButtons.lua:603: in function 'FCOIS.CheckFCOISFilterButtonsAtPanel'
                        |caaaaaa<Locals> doUpdateLists = T, panelId = 16, hideFilterButtons = F, isUniversalDeconNPC = T, universalDeconFilterPanelIdBefore = 21,
                        settings = [table:1]{}, buttonsParentCtrl = ud, filterPanel = 16, filterPanelIdToUse = 16, areFilterButtonEnabledAtPanelId = T, filterButtons = [table:2]{}, _ = 1,
                        buttonNr = 1 </Locals>|r
                        ]]
                        local universalDeconNPCButton = filterButtons[universalDeconFilterPanelIdBefore][buttonNr]
                        if universalDeconNPCButton ~= nil then
                            local universalDeconNPCButtonName = universalDeconNPCButton:GetName()
                            --d(">universal decon NPC button: " ..tos(universalDeconNPCButtonName))
                            local oldUniversalDeconButton = GetControl(universalDeconNPCButtonName)
                            if oldUniversalDeconButton ~= nil then
                                --d(">>oldUniversalDeconButton found")
                                if not oldUniversalDeconButton:IsHidden() then
                                    oldUniversalDeconButton:SetHidden(true)
                                    oldUniversalDeconButton:SetMouseEnabled(false)
                                end
                            end
                        else
--d("<universalDeconNPCButton is NIL - panel: " ..tos(universalDeconFilterPanelIdBefore) .. "; button: " ..tos(buttonNr))
                        end
                    else
--d("<filterButtons["..tos(universalDeconFilterPanelIdBefore).."] are NIL!")
                    end

                end
            end

            --Check the filter button's offsets, width and height at the given LibFilters panel ID
            checkAndTransferFCOISFilterButtonDataByPanelId(filterPanelIdToUse, buttonNr)
            local filterButtonData = settings.filterButtonData[buttonNr][filterPanelIdToUse]
            if filterButtonData ~= nil then
--d(">FilterButtonData at panel [" .. filterPanelIdToUse  .. "] of button " ..tos(buttonNr) .." - left: " .. tos(filterButtonData["left"]).. ", top: " .. tos(filterButtonData["top"]).. ", width: " .. tos(filterButtonData["width"]).. ", height: " .. tos(filterButtonData["height"]) .. ", filterButtonsEnabledAtPanel: " ..tos(areFilterButtonEnabledAtPanelId))
                --Get the filter button control (create or modify) and reanchor  it
                filterBtn = addOrChangeFCOISFilterButton(buttonsParentCtrl, buttonNr,
                                filterButtonData["width"], filterButtonData["height"], filterButtonData["left"], filterButtonData["top"],
                                not areFilterButtonEnabledAtPanelId, filterPanelIdToUse, isUniversalDeconNPC) -- #202
                if areFilterButtonEnabledAtPanelId == true then
                    --Colorize the button and update the tooltips + filter functions
                    if filterBtn ~= nil then
                        --Get the filter's state
                        isFilterActivated = getSettingsIsFilterOn(buttonNr, filterPanelIdToUse)
--d(">>isFilterActivatedAtButton #: " ..tos(buttonNr) ..": " ..tos(isFilterActivated))
                        --Update the button's color
                        updateFCOISFilterButtonColorsAndTextures(buttonNr, filterBtn, isFilterActivated, filterPanelIdToUse)
                        --(Re)register the filter (for the given panel)?
                        if isFilterActivated == false then
                            unregisterFilters(buttonNr, false, filterPanelIdToUse)
                        else
                            registerFilters(buttonNr, false, filterPanelIdToUse)
                        end
                    end
                else
--d("<filterButton not enabled")
                    --Unregister the filter as the settings don't want a button and filter here
                    unregisterFilters(-1, false, filterPanelIdToUse)
                end
            end
        end

        --Should the curent panel's iventory list be updated?
        if (doUpdateLists == true and areFilterButtonEnabledAtPanelId) then
--d(">>>Filter update called")
            refreshFilteredInventory(filterPanelIdToUse, false, true)
        end

        --Update the itemCount before the sortHeader "name" at the new panel
        inventoryChangeFilterHook = inventoryChangeFilterHook or FCOIS.InventoryChangeFilterHook
        inventoryChangeFilterHook(filterPanelIdToUse, "[FCOIS]CheckFilterButtonsAtPanel")
    end
    return buttonsParentCtrl, filterPanel
end
local checkFCOISFilterButtonsAtPanel = FCOIS.CheckFCOISFilterButtonsAtPanel

--PreHook function for panel menu buttons (vanilla UI filter buttons like "Armor", "Weapons",  etc.) at banks, crafting stations, mail panel, trading, etc.
-->Used to update the 4 FCOIS filter buttons at the inventory -> checkFCOISFilterButtonsAtPanel
-->and the additional "flag" inventory context menu buttons and their color (current protection enabled state) -> FCOIS.ChangeContextMenuInvokerButtonColorByPanelId
function FCOIS.PreHookMainMenuFilterButtonHandler(comingFrom, goingTo)
    FCOIS.preventerVars.gActiveFilterPanel = true
    FCOIS.preventerVars.gPreHookButtonHandlerCallActive = true
    if FCOIS.settingsVars.settings.debug then
        debugMessage( "[PreHookButtonHandler]",">>>~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~<<<", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED)
        debugMessage( "[PreHookButtonHandler]","Coming from panel ID: " ..tos(comingFrom)..", going to panel ID: " .. tos(goingTo), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED)
    end
--d("[PreHookButtonHandler] Coming from panel ID: " ..tos(comingFrom) .. ", going to panel ID: " .. tos(goingTo))

    --Hide the context menu at last active panel
    hideContextMenu = hideContextMenu or FCOIS.HideContextMenu
    hideContextMenu(comingFrom)

    --Update the number of filtered items at the sort header "name"?
    -->Shown within AdvancedFilters addon, at the inventory bottom line where the bagSpace and bankSpace items are shown!
    --FCOIS.updateFilteredItemCount(goingTo)

    --If the craftbag panel is shown: Abort here and let the callback function of the craftbag scene do the rest.
    --> See file src/FCOIS_hooks.lua, function FCOIS.CreateHooks(), CRAFT_BAG_FRAGMENT:RegisterCallback("StateChange", ...)
    if FCOIS.IsCraftbagPanelShown() then
--d(">> Craftbag panel is shown -> abort!")
        FCOIS.preventerVars.gPreHookButtonHandlerCallActive = false
        return false
    end

    --Update context menu invoker buttons, except for these where no additional inventory "flag" button exists (e.g. Alchemy)
    local contextMenuInventoryFlagInvokerData = FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker
    if contextMenuInventoryFlagInvokerData[comingFrom] then
        --Change the button color of the context menu invoker button (flag)
        FCOIS.ChangeContextMenuInvokerButtonColorByPanelId(goingTo)
    end

    --Check the filter buttons and create them if they are not there
    checkFCOISFilterButtonsAtPanel(true, goingTo, nil, nil, nil, nil)

    FCOIS.preventerVars.gPreHookButtonHandlerCallActive = false

    --Return false to call the normal callback handler of the button afterwards
    return false
end

--Function is executed as the filter buttons in the inventories are pressed
--Enable/Enable and only show marked items/Disable a filter or disable all filters
local function doFilter(onoff, p_button, filterButtonId, beQuiet, doFilterBasicsPlayer, doUpdateButtonColorsAndTextures, onlyPlayerInvFilter, p_FilterPanelId, isUniversalDecon)
--d("[FCOIS]DoFilter - filterButtonId: " ..tos(filterButtonId) .. ", filterPanelId/gFilterWhere: " ..tos(p_FilterPanelId) .. "/" ..tos(FCOIS.gFilterWhere) ..", isUniversalDecon: " ..tos(isUniversalDecon))
    --Check if the current filter panel Id is given
    if p_FilterPanelId == nil then
        --For initialization, called from function EnableFilters()
        if onoff == -100 then
            p_FilterPanelId = LF_INVENTORY
        else
            p_FilterPanelId = FCOIS.gFilterWhere
        end
    end
    -- -v- #202
    checkIfUniversalDeconstructionNPC  = checkIfUniversalDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC
    local isUniversalDeconNPC = isUniversalDecon
    if isUniversalDeconNPC == nil then
        isUniversalDeconNPC = checkIfUniversalDeconstructionNPC(p_FilterPanelId)
    end
    -- -^- #202

    --Check if the settings are enabled for the current panel
    p_FilterPanelId = getFilterWhereBySettings(p_FilterPanelId, false)
--d(">p_FilterPanelId: " ..tos(p_FilterPanelId))
    local settings = FCOIS.settingsVars.settings
    local lastVars = FCOIS.lastVars

    --Set the last used filter Id
    lastVars.gLastFilterId[p_FilterPanelId] = filterButtonId

    --Hide the button FCOIS.contextMenu if shown and button was clicked
    if p_button ~= nil then
        hideContextMenu = hideContextMenu or FCOIS.HideContextMenu
        hideContextMenu(p_FilterPanelId)
    end

    --Only perform the check if we are not initializing the addon, called from function EnableFilters()
    if onoff ~= -100 then
        --Check if we are in the player inventory
        if p_FilterPanelId == LF_INVENTORY then
            --we are in the player inventory (or in the banks at the deposit inventories, or at mail sending, or trading)
            onlyPlayerInvFilter 	= true
            doFilterBasicsPlayer	= true
        end
    end

    --============================================================================
    -- ABORT HERE IF the settings for the current filter panel Id is not enabled
    --============================================================================
    if settings.atPanelEnabled[p_FilterPanelId]["filters"] == nil or settings.atPanelEnabled[p_FilterPanelId]["filters"] == false then
        --Unregister the filter
        unregisterFilters(filterButtonId, onlyPlayerInvFilter, p_FilterPanelId)

        if settings.debug then debugMessage( "[DoFilter]", "!!! ABORT !!! " .. onoff .. ", filterId: " .. filterButtonId .. ", FilterPanelId: " .. tos(p_FilterPanelId) .. ", beQuiet: " .. tos(beQuiet), false) end

        --Give chat output if beQuiet is false
        if beQuiet == false then
            outputFilterState(true, p_FilterPanelId, filterButtonId, 'ABORT')
        end

        --Abort function here now
        return
    end
    --============================================================================

    if settings.debug then debugMessage( "[DoFilter]", "State: " .. onoff .. ", filterId: " .. filterButtonId .. ", beQuiet: " .. tos(beQuiet) .. ", doFilterBasiscsPlayer: " .. tos(doFilterBasicsPlayer) .. ", doUpdateButtonColorsAndTextures: " .. tos(doUpdateButtonColorsAndTextures) .. ", onlyPlayerInvFilter: " .. tos(onlyPlayerInvFilter) .. ", FilterPanelId: " .. tos(p_FilterPanelId), false) end

    --Fallback solution if filterPanelId is still empty
    if p_FilterPanelId == nil or p_FilterPanelId == 0 then
        d("[FCOIS] ERROR - doFilter("..tos(filterButtonId).."): No filter panel ID given!")
        return
    end

    local isFilterActive
    -- Change the filter value in the settings
    if onoff == 1 then
        isFilterActive = setSettingsIsFilterOn(filterButtonId, FCOIS_CON_FILTER_BUTTON_STATE_GREEN, p_FilterPanelId)
    elseif onoff == 2 then
        isFilterActive = setSettingsIsFilterOn(filterButtonId, FCOIS_CON_FILTER_BUTTON_STATE_RED, p_FilterPanelId)
    elseif onoff == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
        isFilterActive = setSettingsIsFilterOn(filterButtonId, FCOIS_CON_FILTER_BUTTON_STATE_YELLOW, p_FilterPanelId)
    else
        -- Should the filter be changed to next state?
        if onoff == -1 then
            isFilterActive = getSettingsIsFilterOn(filterButtonId, p_FilterPanelId)

            --Filter is on? Turn it off
            if isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_GREEN then
                isFilterActive = setSettingsIsFilterOn(filterButtonId, FCOIS_CON_FILTER_BUTTON_STATE_RED, p_FilterPanelId)
                --Filter is off? Only show filtered
            elseif isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_RED then
                isFilterActive = setSettingsIsFilterOn(filterButtonId, FCOIS_CON_FILTER_BUTTON_STATE_YELLOW, p_FilterPanelId)
            --Filter only shows filtered? Turn it on
            elseif isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
                isFilterActive = setSettingsIsFilterOn(filterButtonId, FCOIS_CON_FILTER_BUTTON_STATE_GREEN, p_FilterPanelId)
            end
            --elseif (onoff == -100) then
            --For initialization (onoff = -100) the filter will be kept as read from the settings
        end
    end

    --Register / Unregister the libFilter filters
    local registerFiltersNow = false

    --------------------------------------------------------------------------------
    -- Initializing from function EnableFilters() at e.g. addon loading
    --------------------------------------------------------------------------------
    --Are we initializing from function EnableFilters() ?
    if onoff == -100 then

        --Unregister all old filters if the addon is already loaded and filters have been registered before.
        --This happens only by function Enablefilters() called after addon has been fully loaded (e.g. the settings menu "Split filters")
        if addonVars.gAddonLoaded == true then
            unregisterFilters(filterButtonId)
        end

        --Only update panel LF_INVENTORY (player inventory)
        local panels = LF_INVENTORY

        --Check for each panel if filters are enabled
        isFilterActive = nil
        isFilterActive = getSettingsIsFilterOn(filterButtonId, panels)

        --Filter is ON
        if    isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_GREEN then
            -- Set the filters to be registered
            registerFiltersNow = true
        --Filter is OFF
        elseif isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_RED then
            -- Set the filters to stay unregistered
            registerFiltersNow = false
        --Filter is ONLY SHOWING MARKED ITEMS (-99)
        elseif isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
            -- Set the filters to be registered again
            registerFiltersNow = true
        end

        --Register the filters now
        if registerFiltersNow == true then
            registerFilters(filterButtonId, onlyPlayerInvFilter, panels)
        end

        -- Update the colors of the 4 "player inventory" filter buttons. All others will be updated upon opening (on event)
        if (filterButtonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN and panels == LF_INVENTORY and doUpdateButtonColorsAndTextures == true) then
            updateFCOISFilterButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)
        end

        --------------------------------------------------------------------------------
        -- Responding to a filter button OnClicked() event or a chat command
        --------------------------------------------------------------------------------
    else -- if onoff == -100 then
        local filterActiveText = tos(isFilterActive)

        --We are not initializing -> Check filter state
        --The NEW filter status was set by function setSettingsIsFilterOn() at the beginning of this function
        --be determined here once again
        if isFilterActive == nil then
            isFilterActive = getSettingsIsFilterOn(filterButtonId, p_FilterPanelId)
            --Is the new filter status still not set initialize it with "false"
            if isFilterActive == nil then
                isFilterActive = setSettingsIsFilterOn(filterButtonId, false, p_FilterPanelId)
            end
        end

        -- Filter is "OFF"
        if isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_RED then

            -- Output "filter off" text
            if (settings.deepDebug or (beQuiet == false and settings.showFilterStatusInChat == true)) then
                outputFilterState(true, p_FilterPanelId, filterButtonId, settingsFilterStateToText[filterActiveText]) --'off'
            end

            -- Set the filters to stay unregistered
            registerFiltersNow = false

            -- Unregister all old filters for the given filterId and panel
            unregisterFilters(filterButtonId, onlyPlayerInvFilter, p_FilterPanelId)

            -- Filter is "ON"
        elseif isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_GREEN then

            -- Output "filter on" text
            if (settings.deepDebug or (beQuiet == false and settings.showFilterStatusInChat == true)) then
                outputFilterState(true, p_FilterPanelId, filterButtonId, settingsFilterStateToText[filterActiveText]) --'on'
            end

            -- Unregister all old filters for the given filterId and panel
            unregisterFilters(filterButtonId, onlyPlayerInvFilter, p_FilterPanelId)

            -- Set the filters to be registered
            registerFiltersNow = true

        --Filter got value "-99"
        --Special treatment for filter to show only marked items (yellow)
        elseif isFilterActive == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then

            -- Output "show only marked" text
            if (settings.deepDebug or (beQuiet == false and settings.showFilterStatusInChat == true)) then
                outputFilterState(true, p_FilterPanelId, filterButtonId, settingsFilterStateToText[filterActiveText]) --'onlyfiltered'
            end

            -- Unregister all old filters for the given filterId and panel
            unregisterFilters(filterButtonId, onlyPlayerInvFilter, p_FilterPanelId)

            -- Set the filters to be registered again
            registerFiltersNow = true

        end

        --=====================================================================================================
        --Register filters now?
        if registerFiltersNow == true then
            --(Re)register the filter (for the given panel again)
            registerFilters(filterButtonId, onlyPlayerInvFilter, p_FilterPanelId)
        end

    end -- if (onoff == -100) then

    --Refresh the inventories scroll lists (the inventories itsself are updated within libFilters until version r14!
    --> As version r15 was implemented the inventory refresh must be done within the addons!)
    --Only update if button was clicked manually or this is the last call to this function dofilter()
    --from function enableFilters() (at initialization of this addon e.g.)
    if onoff ~= -100 or (onoff == -100 and filterButtonId == numFilters) then
--d("[FCOIS]DoFilterNow-filterPanelid: " ..FCOIS.gFilterWhere .. ", doFilterBasicsPlayer: " ..tos(doFilterBasicsPlayer) .. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC))
        --Update all inventories (false) / only the player inventory (true)
        filterBasics(doFilterBasicsPlayer, isUniversalDeconNPC)
    end

    --Update the colors of the changed buttons inside the inventory panels, but only
    --if we are not coming from addon initialization
    if onoff ~= -100 and doUpdateButtonColorsAndTextures == true then
        updateFCOISFilterButtonColorsAndTextures(filterButtonId, nil, isFilterActive, p_FilterPanelId)
    end
    --FCOIS.updateFilteredItemCount(p_FilterPanelId)
end
FCOIS.DoFilter = doFilter
FCOIS.doFilter = doFilter -- fallback naming with non-capital "d" (maybe other addons call the function)


--Enable the filters
function FCOIS.EnableFilters(p_onoff)
    -- Enable the filters for the different panels (inventory, deconstruction, guild store, etc.)
    for filters = 1, numFilters, 1 do
        --function doFilter(onoff, p_button, filterId, beQuiet, doFilterBasicsPlayer, doUpdateButtonColorsAndTextures, onlyPlayerInvFilter, p_FilterPanelId)
        doFilter(p_onoff, nil, filters, true, true, true, true)
    end
end

--Helper function for function filterStatus
local function filterStatusLoop(filterId, silent, givenArray, p_atLeastOneFilterActive)
    local returnArray = {}
    local atLeastOneFilterActive = p_atLeastOneFilterActive

    --Is an array already prepared?
    local numFilterInvTypes = FCOIS.numVars.gFCONumFilterInventoryTypes
    local activeFilterPanelIds = FCOIS.mappingVars.activeFilterPanelIds
    if #givenArray == 0 then
        --Create 2-dimensional arrays for the filters
        for help_inv = 1, numFilterInvTypes, 1 do
            if activeFilterPanelIds[help_inv] == true then
                returnArray[help_inv] = {false, false, false, false}
            end
        end
    else
        --Array was already given, so use it
        returnArray = givenArray
    end

    local mappingVars = FCOIS.mappingVars
    localizationVars = FCOIS.localizationVars
    locVars = localizationVars.fcois_loc
    local settings = FCOIS.settingsVars.settings
    local filterPanelToFilterButtonMediumOutputText = mappingVars.filterPanelToFilterButtonMediumOutputText
    local filterPanelToFilterButtonFilterActiveSettingName = mappingVars.filterPanelToFilterButtonFilterActiveSettingName
    
    -- Check only one filter
    for j=1, numFilterInvTypes, 1 do
        if activeFilterPanelIds[j] == true then
            if getSettingsIsFilterOn(filterId, j) then
                returnArray[j][filterId] = true
                atLeastOneFilterActive = true
                local statusFilterIdText = locVars["chatcommands_status_filter" .. tos(filterId)]
--FCOIS 2021-11-14 Use filterPanelToFilterButtonMediumOutputText[j] and settings[filterPanelToFilterButtonFilterActiveSettingName[j]] below!
                returnArray[j][filterId] = settings[filterPanelToFilterButtonFilterActiveSettingName[j]]
--d(">j: " ..tos(j) .. ", filterId: " ..tos(filterId))
                if not silent then
                    d(filterPanelToFilterButtonMediumOutputText[j] .. statusFilterIdText)
                end
--[[ Replaced by code lines above
                if     (j == LF_INVENTORY or j == LF_BANK_DEPOSIT or j == LF_GUILDBANK_DEPOSIT or j == LF_HOUSE_BANK_DEPOSIT) then
                    returnArray[j][filterId] = settings.allowInventoryFilter
                    if (not silent) then
                        d(locVars["filter_inventory"] .. statusFilterIdText)
                    end

                elseif (j == LF_CRAFTBAG) then
                    returnArray[j][filterId] = settings.allowCraftBagFilter
                    if (not silent) then
                        d(locVars["filter_craftbag"] .. statusFilterIdText)
                    end
                elseif     (j == LF_VENDOR_BUY) then
                    returnArray[j][filterId] = settings.allowVendorBuyFilter
                    if (not silent) then
                        d(locVars["filter_buy"] .. statusFilterIdText)
                    end
                elseif     (j == LF_VENDOR_SELL) then
                    returnArray[j][filterId] = settings.allowVendorFilter
                    if (not silent) then
                        d(locVars["filter_store"] .. statusFilterIdText)
                    end
                elseif     (j == LF_VENDOR_BUYBACK) then
                    returnArray[j][filterId] = settings.allowVendorBuybackFilter
                    if (not silent) then
                        d(locVars["filter_buyback"] .. statusFilterIdText)
                    end
                elseif     (j == LF_VENDOR_REPAIR) then
                    returnArray[j][filterId] = settings.allowVendorRepairFilter
                    if (not silent) then
                        d(locVars["filter_repair"] .. statusFilterIdText)
                    end
                elseif     (j == LF_FENCE_SELL) then
                    returnArray[j][filterId] = settings.allowFenceFilter
                    if (not silent) then
                        d(locVars["filter_fence"] .. statusFilterIdText)
                    end
                elseif     (j == LF_FENCE_LAUNDER) then
                    returnArray[j][filterId] = settings.allowLaunderFilter
                    if (not silent) then
                        d(locVars["filter_launder"] .. statusFilterIdText)
                    end
                elseif (j == LF_GUILDBANK_WITHDRAW) then
                    returnArray[j][filterId] = settings.allowGuildBankFilter
                    if (not silent) then
                        d(locVars["filter_guildbank"] .. statusFilterIdText)
                    end
                elseif (j == LF_GUILDSTORE_SELL) then
                    returnArray[j][filterId] = settings.allowTradinghouseFilter
                    if (not silent) then
                        d(locVars["filter_guildstore"] .. statusFilterIdText)
                    end
                elseif (j == LF_BANK_WITHDRAW or j == LF_HOUSE_BANK_WITHDRAW) then
                    returnArray[j][filterId] = settings.allowBankFilter
                    if (not silent) then
                        d(locVars["filter_bank"] .. statusFilterIdText)
                    end
                elseif (j == LF_SMITHING_REFINE) then
                    returnArray[j][filterId] = settings.allowRefinementFilter
                    if (not silent) then
                        d(locVars["filter_refinement"] .. statusFilterIdText)
                    end
                elseif (j == LF_SMITHING_DECONSTRUCT) then
                    returnArray[j][filterId] = settings.allowDeconstructionFilter
                    if (not silent) then
                        d(locVars["filter_deconstruction"] .. statusFilterIdText)
                    end
                elseif (j == LF_SMITHING_IMPROVEMENT) then
                    returnArray[j][filterId] = settings.allowImprovementFilter
                    if (not silent) then
                        d(locVars["filter_improvement"] .. statusFilterIdText)
                    end
                elseif (j == LF_SMITHING_RESEARCH) then
                    returnArray[j][filterId] = settings.allowResearchFilter
                    if (not silent) then
                        d(locVars["filter_research"] .. statusFilterIdText)
                    end
                elseif (j == LF_JEWELRY_REFINE) then
                    returnArray[j][filterId] = settings.allowJewelryRefinementFilter
                    if (not silent) then
                        d(locVars["filter_jewelry_refinement"] .. statusFilterIdText)
                    end
                elseif (j == LF_JEWELRY_DECONSTRUCT) then
                    returnArray[j][filterId] = settings.allowJewelryDeconstructionFilter
                    if (not silent) then
                        d(locVars["filter_jewelry_deconstruction"] .. statusFilterIdText)
                    end
                elseif (j == LF_JEWELRY_IMPROVEMENT) then
                    returnArray[j][filterId] = settings.allowJewelryImprovementFilter
                    if (not silent) then
                        d(locVars["filter_jewelry_improvement"] .. statusFilterIdText)
                    end
                elseif (j == LF_JEWELRY_RESEARCH) then
                    returnArray[j][filterId] = settings.allowJewelryResearchFilter
                    if (not silent) then
                        d(locVars["filter_jewelry_research"] .. statusFilterIdText)
                    end
                elseif (j == LF_MAIL_SEND) then
                    returnArray[j][filterId] = settings.allowMailFilter
                    if (not silent) then
                        d(locVars["filter_mail"] .. statusFilterIdText)
                    end
                elseif (j == LF_TRADE) then
                    returnArray[j][filterId] = settings.allowTradeFilter
                    if (not silent) then
                        d(locVars["filter_trade"] .. statusFilterIdText)
                    end
                elseif (j == LF_ENCHANTING_EXTRACTION) then
                    returnArray[j][filterId] = settings.allowEnchantingFilter
                    if (not silent) then
                        d(locVars["filter_enchantingstation_extraction"] .. statusFilterIdText)
                    end
                elseif (j==LF_ENCHANTING_CREATION) then
                    returnArray[j][filterId] = settings.allowEnchantingFilter
                    if (not silent) then
                        d(locVars["filter_enchantingstation_creation"] .. statusFilterIdText)
                    end
                elseif (j == LF_INVENTORY_COMPANION) then
                    returnArray[j][filterId] = settings.allowCompanionInventoryFilter
                    if (not silent) then
                        d(locVars["filter_companion_inventory"] .. statusFilterIdText)
                    end
                end
]]
            end -- if getSettingsIsFilterOn(filterId, j) then
        end
    end -- for j=1, ...

    return returnArray, atLeastOneFilterActive
end

--Check a filter status
function FCOIS.FilterStatus(filterId, silent, doReturnFilterStatus)
    --Prepare the return array
    local retArray = {}
    local atLeastOneFilterActive = false
    localizationVars = FCOIS.localizationVars
    locVars = localizationVars.fcois_loc

    if filterId ~= -1 then
        retArray, atLeastOneFilterActive = filterStatusLoop(filterId, silent)
    else
        -- Check all filters
        for i=1, numFilters, 1 do
            retArray, atLeastOneFilterActive = filterStatusLoop(i, silent, retArray, atLeastOneFilterActive)
        end
    end

    --Was at least one active filter found and chat output is enabled?
    if atLeastOneFilterActive == false and silent == false then
        --local locVars = FCOIS.localizationVars.fcois_loc
        d(locVars["chatcommands_status_nofilters"])
    end

    --Return the array with filter states?
    if doReturnFilterStatus == true then
        return retArray
    end
end

--Add the filter buttons to the inventory/bank/mail/trade/guild bank/guild store/crafting stations panels
--and change them upon opening a new filter panel (update the button id, button filter panel, tooltips, callback functions)
function FCOIS.AddOrChangeFCOISFilterButton(parentCtrl, buttonId, pWidth, pHeight, pLeft, pTop, hide, p_FilterPanelId, isUniversalDeconNPC)
    if not parentCtrl then return end
    local parentName
    --Attention: parentCtrl passed in will be used for the name of the buttons!!!
    local parentToUse = parentCtrl --this parent here is only used for the button:SetParent(parentToUse) and the CreateControl function.

    --Get the current filter panel Id
    p_FilterPanelId = p_FilterPanelId or FCOIS.gFilterWhere
    -- -v- #202
    checkIfUniversalDeconstructionNPC = checkIfUniversalDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC
    if isUniversalDeconNPC == nil then isUniversalDeconNPC = checkIfUniversalDeconstructionNPC(p_FilterPanelId) end
    local universalDeconAnchorTo
    if isUniversalDeconNPC == true then
        parentToUse, universalDeconAnchorTo = getUniversalDeconstructionNPCParentAndAnchor(p_FilterPanelId)
    end
    -- -^- #202

    showContextMenuAtFCOISFilterButton = showContextMenuAtFCOISFilterButton or FCOIS.ShowContextMenuAtFCOISFilterButton

    local settings = FCOIS.settingsVars.settings
    if settings.debug then
        parentName = parentName or parentCtrl:GetName()
        debugMessage( "[AddOrChangeFilterButton]", parentName .. ", buttonId: " .. buttonId .. ", filterPanelId: " .. p_FilterPanelId .. ", hide: " .. tos(hide) .. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC) .. ", parentToUse: " ..tos(parentToUse:GetName()), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED)
    end
--d("[FCOIS.AddOrChangeFilterButton] " .. parentCtrl:GetName() .. ", buttonId: " .. buttonId .. ", filterPanelId: " .. p_FilterPanelId .. ", hide: " .. tos(hide) .. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC) .. ", parentToUse: " ..tos(parentToUse:GetName()))
    local tooltipText
    local button = parentCtrl:GetNamedChild(filterButtonSuffix .. tos(buttonId))

    local filterButtonVars = FCOIS.filterButtonVars

    -- -v- #202
    local function reAnchorButton(p_button)
        p_button:ClearAnchors()
        --Place the buttons at the bottom of the inventory.
        --Special treatment for improvement panel here, because the "Booster container" is located at the bottom and the buttons
        --will be shown above him, not below (as he gives the BOTTOM anchor) of the inventory
        if (p_FilterPanelId == LF_SMITHING_IMPROVEMENT or p_FilterPanelId == LF_JEWELRY_IMPROVEMENT) then
            pTop = pTop + filterButtonVars.buttonOffsetYImprovement
            p_button:SetAnchor(TOP, ctrlVars.IMPROVEMENT_BOOSTER_CONTAINER, BOTTOM, pLeft, pTop)
            --Special treatment for research "popup" panel here, because the filter buttons should be added to the top divider of the popup
        elseif (p_FilterPanelId == LF_SMITHING_RESEARCH_DIALOG  or p_FilterPanelId == LF_JEWELRY_RESEARCH_DIALOG ) then
            pTop = pTop + filterButtonVars.buttonOffsetYResearchDialog
            p_button:SetAnchor(TOP, ctrlVars.RESEARCH_POPUP_TOP_DIVIDER, BOTTOM, pLeft, pTop)
            --All other inventories and panels
        else
--d(">>reAnchorButton - isUniversalDeconNPC: " ..tos(isUniversalDeconNPC))
            if isUniversalDeconNPC == true then
                p_button:SetAnchor(TOP, universalDeconAnchorTo, BOTTOM, pLeft, pTop)
            else
                p_button:SetAnchor(TOP, parentCtrl, BOTTOM, pLeft, pTop)
            end
        end
    end
    -- -^- #202

    --Hide the button?
    if hide == true then
--d(">hide button")
        if button then
            button:SetParent(parentToUse) --#202 set the parent to the original inventory again, not to the universal deconstruction inventory
            button:SetHidden(true)
            reAnchorButton(button)
        end
        -- If we reach here hide is enabled. Return nil then
        return nil
    end

    local buttonExists = true
    --Create the button?
    if not button then
--d(">no button yet")
        buttonExists = false
        -- create it
        parentName = parentName or parentCtrl:GetName()
        button = CreateControl(parentName .. filterButtonSuffix .. tos(buttonId), parentToUse, CT_BUTTON) -- #202
        if not button then return nil end
        --Save the created buttons
        FCOIS.filterButtonVars.filterButtons[p_FilterPanelId] = FCOIS.filterButtonVars.filterButtons[p_FilterPanelId] or {}
        FCOIS.filterButtonVars.filterButtons[p_FilterPanelId][buttonId] = button

        if settings.debug then debugMessage( "[AddOrChangeFilterButton]", "+++ ADD ButtonName=" .. button:GetName() .. ", Width/Height: " .. pWidth .. "/" .. pHeight .. ", Left/Top: " .. pLeft .. "/" .. pTop, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        local texVars = FCOIS.textureVars
        local texMarkerVars = texVars.MARKER_TEXTURES

--d(">+++ FCOIS.AddOrChangeFilterButton: ADD ButtonName=" .. button:GetName() .. ", Width/Height: " .. pWidth .. "/" .. pHeight .. ", Left/Top: " .. pLeft .. "/" .. pTop)

        --Create the texture for the button to hold the image
        local texture = CreateControl(button:GetName() .. "Texture", button, CT_TEXTURE)
        texture:SetAnchorFill()
        --Are the inventory filter buttons split into several filter ids + context menu?
        if settings.splitLockDynFilter and buttonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
            texture:SetTexture(texMarkerVars[texVars.allLockDyn])
        elseif settings.splitGearSetsFilter and buttonId == FCOIS_CON_FILTER_BUTTON_GEARSETS then
            texture:SetTexture(texMarkerVars[texVars.allGearSets])
        elseif settings.splitResearchDeconstructionImprovementFilter and buttonId == FCOIS_CON_FILTER_BUTTON_RESDECIMP then
            texture:SetTexture(texMarkerVars[texVars.allResDecImp])
        elseif settings.splitSellGuildSellIntricateFilter and buttonId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT then
            texture:SetTexture(texMarkerVars[texVars.allSellGuildInt])
        else
            --Workaround to show at least a default texure, if none is found
            local iconSettings = settings.icon[buttonId]
            local buttonTextureOfSettings = iconSettings ~= nil and iconSettings.texture
            if texMarkerVars[buttonTextureOfSettings] ~= nil then
                --Set the texture now
                texture:SetTexture(texMarkerVars[buttonTextureOfSettings])
            else
                --Set fallback texture now
                texture:SetTexture(texMarkerVars[buttonId])
                --Set the fallback texture to the settings menu
                settings.icon[buttonId].texture = buttonId
            end
        end
    end -- if not button then

    --Update the button's personal variables -> Passed to OnMouse* handlers!
    button.FCOfilterPanelId     = p_FilterPanelId
    button.FCObuttonId		    = buttonId
    button.FCOisUniversalDecon  = isUniversalDeconNPC -- #202

    --Button already existed?
    if buttonExists then
        button:SetParent(parentToUse) --#202 set the parent to the original inventory again, not to the universal deconstruction inventory
--d("-> FCOIS.AddOrChangeFilterButton: CHANGE ButtonName=" .. button:GetName() .. ", Width/Height: " .. pWidth .. "/" .. pHeight .. ", Left/Top: " .. pLeft .. "/" .. pTop)
        if settings.debug then debugMessage( "[AddOrChangeFilterButton]", ">> CHANGE ButtonName=" .. button:GetName() .. ", Width/Height: " .. pWidth .. "/" .. pHeight .. ", Left/Top: " .. pLeft .. "/" .. pTop, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end

    --Set/Update handlers
    --Set/Update a tooltip?
    button:SetHandler("OnMouseEnter", nil)
    button:SetHandler("OnMouseEnter", function(buttonMouseEntered)
        if settings.showFilterButtonTooltip == true then
            --local panelId = FCOIS.gFilterWhere -- #202
            local panelId = buttonMouseEntered.FCOfilterPanelId or FCOIS.gFilterWhere -- #202
--d(">FilterButton:OnMouseEnter - panelId: " ..tos(panelId))
            local contextMenu = FCOIS.contextMenu
            local showToolTip = true
            --Don't show a tooltip if the context menu for LOCKDYN is shown at the filter button
            local contextMenuFilterButton1 = contextMenu.LockDynFilter[panelId]
            if contextMenuFilterButton1 ~= nil then
                showToolTip = contextMenuFilterButton1:IsHidden()
            end
            --Don't show a tooltip if the context menu for gear sets is shown at the filter button
            local contextMenuFilterButton2 = contextMenu.GearSetFilter[panelId]
            if contextMenuFilterButton2 ~= nil then
                showToolTip = contextMenuFilterButton2:IsHidden()
            end
            --Don't show a tooltip if the context menu for research, deconstruction & improvement is shown at the filter button
            local contextMenuFilterButton3 = contextMenu.ResDecImpFilter[panelId]
            if showToolTip and contextMenuFilterButton3 ~= nil then
                showToolTip = contextMenuFilterButton3:IsHidden()
            end
            --Don't show a tooltip if the context menu for sell, sell at guild store & intricate is shown at the filter button
            local contextMenuFilterButton4 = contextMenu.SellGuildIntFilter[panelId]
            if showToolTip and contextMenuFilterButton4 ~= nil then
                showToolTip = contextMenuFilterButton4:IsHidden()
            end
            if showToolTip then
                tooltipText = outputFilterState(false, panelId, buttonMouseEntered.FCObuttonId, settingsFilterStateToText[tos(getSettingsIsFilterOn(buttonMouseEntered.FCObuttonId, panelId))])
                if tooltipText ~= "" then
                    ZO_Tooltips_ShowTextTooltip(buttonMouseEntered, BOTTOM, tooltipText)
                end
            end
        else
            ZO_Tooltips_HideTextTooltip()
        end
    end)
    button:SetHandler("OnMouseExit", nil)
    button:SetHandler("OnMouseExit", function()
        ZO_Tooltips_HideTextTooltip()
    end)

    --Overwrite the callback function of the button so it is channging the correct panel filter
    --as mail, trade, bank, guild bank, and others all use the ZO_PlayerInventory buttons to filter!
    button:SetHandler("OnClicked", nil)
    button:SetHandler("OnClicked", function(buttonClicked)
        if settings.debug then debugMessage( "[FilterButton OnClicked]", "=========>", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        if settings.debug then debugMessage( "[FilterButton OnClicked]", "ButtonName: " .. buttonClicked:GetName() .. ", ButtonId: " .. buttonClicked.FCObuttonId .. ", PanelId (global): " .. FCOIS.gFilterWhere .. ", PanelId (button): " .. buttonClicked.FCOfilterPanelId, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        --Change the filter according to the filter button's data
        doFilter(-1, buttonClicked, buttonClicked.FCObuttonId, false, false, true, false, buttonClicked.FCOfilterPanelId, button.FCOisUniversalDecon)
        --Show the tooltip at the filter button
        if settings.showFilterButtonTooltip then
            tooltipText = outputFilterState(false, buttonClicked.FCOfilterPanelId, buttonClicked.FCObuttonId, settingsFilterStateToText[tos(getSettingsIsFilterOn(buttonClicked.FCObuttonId, buttonClicked.FCOfilterPanelId))])
            if tooltipText ~= "" then
                ZO_Tooltips_ShowTextTooltip(buttonClicked, BOTTOM, tooltipText)
            end
        else
            --Hide the tooltip
            ZO_Tooltips_HideTextTooltip()
        end
    end)

    --Set the mouse up handler for the filter button -> e.g. right click -> context menu to select one filter icon (or * for all)
    button:SetHandler("OnMouseUp", nil)
    button:SetHandler("OnMouseUp", function(buttonOnMouseUp, mouseButton, upInside, ctrl, alt, shift, command)
        --button 1= left mouse button / 2= right mouse button
        local doBuildContextMenu = false
        --Right click/mouse button 2 context menu hook part:
        if mouseButton == MOUSE_BUTTON_INDEX_RIGHT and upInside then
            local filterButtonContextMenuType = availableCtms[buttonId]
            showContextMenuAtFCOISFilterButton = showContextMenuAtFCOISFilterButton or FCOIS.ShowContextMenuAtFCOISFilterButton

            --Hide the tooltip
            ZO_Tooltips_HideTextTooltip()

            local isShiftPressed = shift or IsShiftKeyDown()
            --d("[FCOIS]FilterButton right click handler - panelId: " ..tos(FCOIS.gFilterWhere) .. ", isShiftPressed: " ..tos(isShiftPressed))
            if isShiftPressed == true then
                --Reset the filterButtons selected filterIcon to * ("All")
                showContextMenuAtFCOISFilterButton(buttonOnMouseUp, buttonOnMouseUp.FCOfilterPanelId, filterButtonContextMenuType, true)
                return
            end

            local contextMenu = FCOIS.contextMenu
            local panelId = FCOIS.gFilterWhere

            --Build the context menu for the lock & dynamic icons
            --Only do this if the right mouse button was pressed and filter button ID is 1 (lock)
            if buttonId == FCOIS_CON_FILTER_BUTTON_LOCKDYN and settings.splitLockDynFilter then
                --Hide the lockdyn split filter button context-menu
                local contextMenuFilterButton1 = contextMenu.LockDynFilter[panelId]
                if contextMenuFilterButton1 ~= nil then
                    if not contextMenuFilterButton1:IsHidden() then
                        contextMenuFilterButton1:SetHidden(true)
                    else
                        doBuildContextMenu = true
                    end
                else
                    doBuildContextMenu = true
                end
                --Build the context menu for the gear sets filter button, if activated
                --Only do this if the right mouse button was pressed and filter button ID is 2 (gear sets)
            elseif buttonId == FCOIS_CON_FILTER_BUTTON_GEARSETS and settings.splitGearSetsFilter then
                --Hide the gear sets split filter button context-menu
                local contextMenuFilterButton2 = contextMenu.GearSetFilter[panelId]
                if contextMenuFilterButton2 ~= nil then
                    if not contextMenuFilterButton2:IsHidden() then
                        contextMenuFilterButton2:SetHidden(true)
                    else
                        doBuildContextMenu = true
                    end
                else
                    doBuildContextMenu = true
                end
                --Build the context menu for the research filter button, if activated
                --Only do this if the right mouse button was pressed and filter button ID is 3 (research)
            elseif buttonId == FCOIS_CON_FILTER_BUTTON_RESDECIMP and settings.splitResearchDeconstructionImprovementFilter then
                --Hide the RESEARCH & DECONSTRUCTION & IMPORVEMENT button context-menu
                local contextMenuFilterButton3 = contextMenu.ResDecImpFilter[panelId]
                if contextMenuFilterButton3 ~= nil then
                    if not contextMenuFilterButton3:IsHidden() then
                        contextMenuFilterButton3:SetHidden(true)
                    else
                        doBuildContextMenu = true
                    end
                else
                    doBuildContextMenu = true
                end
                --Build the context menu for the sell filter button, if activated
                --Only do this if the right mouse button was pressed and filter button ID is 4 (sell)
            elseif buttonId == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT and settings.splitSellGuildSellIntricateFilter then
                --Hide the SELL & SELL AT GUILD STORE & INTRICATE button context-menu
                local contextMenuFilterButton4 = contextMenu.SellGuildIntFilter[panelId]
                if contextMenuFilterButton4 ~= nil then
                    if not contextMenuFilterButton4:IsHidden() then
                        contextMenuFilterButton4:SetHidden(true)
                    else
                        doBuildContextMenu = true
                    end
                else
                    doBuildContextMenu = true
                end
            end
            --Get the context menu type ("LockDyn", "Gear," ResDecImp" or "SellGuildInt") via the constant of the filterbutton
            if doBuildContextMenu == true then
                if filterButtonContextMenuType ~= nil then
                    --Build and show the context menu for the lockdyn
                    showContextMenuAtFCOISFilterButton(buttonOnMouseUp, buttonOnMouseUp.FCOfilterPanelId, filterButtonContextMenuType, false)
                end
            end
        end
    end)

    -- setup & modify button's size, position etc.
--d(">dimensions: " ..tos(pWidth) .. "/" ..tos(pHeight) .. ", gFilterWhere: " ..tos(FCOIS.gFilterWhere))
    button:SetDimensions(pWidth, pHeight)
    --Move the button more to the right, if standard left values are used and GridView Addon is activated
    local panelId = FCOIS.gFilterWhere
    local filterButtonDataLockDyn       = settings.filterButtonData[FCOIS_CON_FILTER_BUTTON_LOCKDYN][panelId]
    local filterButtonDataGearSets      = settings.filterButtonData[FCOIS_CON_FILTER_BUTTON_GEARSETS][panelId]
    local filterButtonDataResDecImp     = settings.filterButtonData[FCOIS_CON_FILTER_BUTTON_RESDECIMP][panelId]
    local filterButtonDataSellGuildInt  = settings.filterButtonData[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT][panelId]
    if (FCOIS.otherAddons.inventoryGridViewActive == true
            --[[
                and ( settings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_LOCKDYN] == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_LOCKDYN]
                and settings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_GEARSETS] == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_GEARSETS]
                and settings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_RESDECIMP] == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_RESDECIMP]
                and settings.filterButtonLeft[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT])
            ]]
            and (
            filterButtonDataLockDyn["left"]         == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_LOCKDYN]
                    and filterButtonDataGearSets["left"]        == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_GEARSETS]
                    and filterButtonDataResDecImp["left"]       == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_RESDECIMP]
                    and filterButtonDataSellGuildInt["left"]    == filterButtonVars.gFilterButtonLeft[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]
    )
    ) then
        pLeft = pLeft + FCOIS.otherAddons.gGriedViewOffsetX
    end

    reAnchorButton(button) -- #202
    button:SetFont("ZoFontGameSmall")

    --Update the filter button's z-axis and the layer
    button:SetDrawTier(DT_HIGH)
    button:SetDrawLayer(DL_OVERLAY)
    button:SetDrawLevel(5) --high level to overlay others

    --Show the button and make it react on mouse input
--d(">button unhidden!")
    button:SetHidden(false)
    button:SetMouseEnabled(true)

    --Return the new created/changed button control
    return button
end
addOrChangeFCOISFilterButton = FCOIS.AddOrChangeFCOISFilterButton

-- =====================================================================================================================
--  Filter button itemCount functions
-- =====================================================================================================================
--Get the sort header where the filtered item count should be added as pre-text
function FCOIS.GetSortHeaderControl(filterPanelId)
    filterPanelId = filterPanelId or FCOIS.gFilterWhere
    local sortHeaderVars = FCOIS.sortHeaderVars
    local sortHeaderName = sortHeaderVars.name[filterPanelId]
    if not sortHeaderName then return end
    local sortHeaderCtrl = GetControl(sortHeaderName) --wm:GetControlByName(sortHeaderName, "")
    if sortHeaderCtrl == nil then return  end
    return sortHeaderCtrl
end
local getSortHeaderControl = FCOIS.GetSortHeaderControl

--Reset the sort header control for a giveb filterPanelId
function FCOIS.ResetSortHeaderCount(filterPanelId, sortHeaderCtrlToReset)
    filterPanelId = filterPanelId or FCOIS.gFilterWhere
    --d(">>[FCOIS]resetSortHeaderCount, filterPanelId: " .. tos(filterPanelId))
    if sortHeaderCtrlToReset == nil then
        sortHeaderCtrlToReset = getSortHeaderControl(filterPanelId)
    end
    if sortHeaderCtrlToReset == nil then return false end
    local origSortHeaderText = GetString(SI_INVENTORY_SORT_TYPE_NAME)
    sortHeaderCtrlToReset:SetText(origSortHeaderText)
    return true
end
local resetSortHeaderCount = FCOIS.ResetSortHeaderCount

--Get the currently shown items count of the filterPanelId
function FCOIS.GetFilteredItemCountAtPanel(libFiltersPanelId, panelIdOrInventoryTypeString)
    libFiltersPanelId = libFiltersPanelId or FCOIS.gFilterWhere
    local filteredItemsArray
    local numberOfFilteredItems = 0
    if panelIdOrInventoryTypeString ~= nil and libFiltersPanelId ~= panelIdOrInventoryTypeString and type(panelIdOrInventoryTypeString) == "string" then
        --Was the content of this table not build yet? Try to reload it now
        if FCOIS.numberOfFilteredItems[panelIdOrInventoryTypeString] == nil then
            getNumberOfFilteredItemsForEachPanel()
        end
        filteredItemsArray = FCOIS.numberOfFilteredItems[panelIdOrInventoryTypeString]
    else
        filteredItemsArray = FCOIS.numberOfFilteredItems[libFiltersPanelId]
    end
--d("[FCOIS]getFilteredItemCountAtPanel, filterPanelId: " .. tos(libFiltersPanelId) .. ", inventoryType: " .. tos(panelIdOrInventoryTypeString))
    if filteredItemsArray == nil then
        return 0
    end
    if type(filteredItemsArray) == "table" then
        numberOfFilteredItems = #filteredItemsArray
    else
        numberOfFilteredItems = filteredItemsArray
    end
    if not numberOfFilteredItems or numberOfFilteredItems <= 0 then return 0 end
    return numberOfFilteredItems
end
local getFilteredItemCountAtPanel = FCOIS.GetFilteredItemCountAtPanel

--Update the filtered item count at the panel
function FCOIS.UpdateFilteredItemCount(panelId, calledFrom)
    panelId = panelId or FCOIS.gFilterWhere
    calledFrom = calledFrom or ""
    local libFiltersPanelId = panelId
    --Special checks for the non supported filterPanelIds (Inventory types) liek quest items
    if panelId == "INVENTORY_QUEST_ITEM" then
        libFiltersPanelId = LF_INVENTORY
    end
    local showFilteredItemCount = FCOIS.settingsVars.settings.showFilteredItemCount
--d(">[FCOIS]updateFilteredItemCount->".. calledFrom .. " - panelId: " ..tos(panelId) .. ", libFiltersPanelId: " ..tos(libFiltersPanelId) .. ", showFilteredItemCount: " .. tos(showFilteredItemCount))
    local sortHeaderCtrl = FCOIS.GetSortHeaderControl(libFiltersPanelId)
    --Reset the sortheader text to the original one
    if sortHeaderCtrl then resetSortHeaderCount(libFiltersPanelId, sortHeaderCtrl) end
    --AdvancedFilters version 1.5.0.6 adds filtered item count at the bottom inventory lines. So FCOIS does not need to show this anymore if AdvancedFilters has enabled this setting.
    FCOIS.preventerVars.useAdvancedFiltersItemCountInInventories = FCOIS.CheckIfAdvancedFiltersItemCountIsEnabled()
    if FCOIS.preventerVars.useAdvancedFiltersItemCountInInventories then
        --d(">>>[AF]filtered itemCount is used")
        --Update the AdvancedFilters item count
        zo_callLater(function()
            local afUtil = AdvancedFilters.util
            if afUtil.UpdateCraftingInventoryFilteredCount then
                --Set this to prevent endless loop!
                FCOIS.preventerVars.dontUpdateFilteredItemCount = true
                afUtil.UpdateCraftingInventoryFilteredCount(nil) --invType: nil
                FCOIS.preventerVars.dontUpdateFilteredItemCount = false
            end
        end, 50)
    end
    --Should the item count be shown at the name sort header? If not -> Abort here now
    if not showFilteredItemCount then return false end
    --Update the item count at the sort header?
    if libFiltersPanelId == nil then return false end
    if not sortHeaderCtrl then return false end
    if not FCOIS.numberOfFilteredItems or not FCOIS.numberOfFilteredItems[libFiltersPanelId] then
        return false end
    --Get the item number of the current inventory, slightly delayed as the filters need to be run first
    zo_callLater(function()
        local numberOfFilteredItems = getFilteredItemCountAtPanel(libFiltersPanelId, panelId)
        if not numberOfFilteredItems or numberOfFilteredItems <= 0 then
            --Sortheader text was reset already at the beginning of this function -> Abort here now
            return false
        end
        --Build the new sort header text now: "(<number>) NAME"
        local preTextIncludingFilteredItemNumber = "(" .. numberOfFilteredItems .. ") "
        local origSortHeaderText = GetString(SI_INVENTORY_SORT_TYPE_NAME)
        sortHeaderCtrl:SetText(preTextIncludingFilteredItemNumber .. origSortHeaderText)
    end, 50)
end
local updateFilteredItemCount = FCOIS.UpdateFilteredItemCount

--Hook the inventorie's (and crafting inventory) UpdateFilter functions in order to
--update the itemCount at the sort headers properly
-->Will be called each time an inventory filter changes, e.g. from All to Armor, or from Weapons to Materials
function FCOIS.InventoryChangeFilterHook(filterPanelId, calledFrom)
    filterPanelId = filterPanelId or FCOIS.gFilterWhere
    --[[
    if calledFrom ~= nil then
        d("[FCOIS]inventoryChangeFilterHook, calledFrom: " .. tos(calledFrom))
    else
        d("[FCOIS]inventoryChangeFilterHook")
    end
    ]]
    --Only go on if the update for the item count is for the currently visible filterPanelId
    if filterPanelId ~= FCOIS.gFilterWhere then return end
    updateFilteredItemCount(filterPanelId, calledFrom)
end
inventoryChangeFilterHook = FCOIS.InventoryChangeFilterHook

--Update the shown filteredItem count at the inventories, but throttled with a delay and only once if updates are tried
--to be done several times after another
function FCOIS.UpdateFilteredItemCountThrottled(filterPanelId, delay, calledFromWhere)
    filterPanelId = filterPanelId or FCOIS.gFilterWhere
    delay = delay or 250
    calledFromWhere = calledFromWhere or ""
--d("[FCOIS]updateFilteredItemCountThrottled->" .. calledFromWhere .. " - filterPanelId: " ..tos(filterPanelId) .. ", delay: " ..tos(delay))
    --Only go on if the update for the item count is for the currently visible filterPanelId
    if filterPanelId ~= FCOIS.gFilterWhere then return end
    --Update the count of filtered/shown items before the sortHeader "name" text
    throttledUpdate("FCOIS_UpdateItemCount_" .. filterPanelId, delay, inventoryChangeFilterHook, filterPanelId, "[FCOIS]updateFilteredItemCountThrottled->" .. calledFromWhere)
end