--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage
local tos = tostring

--local wm = WINDOW_MANAGER

local mappingVars = FCOIS.mappingVars
local otherAddons = FCOIS.otherAddons
local preChatVars = FCOIS.preChatVars
local preChatTextGreen = preChatVars.preChatTextGreen

local checkIfProtectedSettingsEnabled = FCOIS.CheckIfProtectedSettingsEnabled
local myGetItemDetails = FCOIS.MyGetItemDetails

local isDynamicGearIcon
local isMarked
local isMarkedByItemInstanceId
local checkAndGetIIfAData
local getIconText

-- =====================================================================================================================
--  Tooltip functions
-- =====================================================================================================================

--Create the tooltip for the marker texture - BuildTooltip
local createToolTip
function FCOIS.CreateToolTip(markerControl, markerId, doHide, pUpdateAllEquipmentTooltips, pIsEquipmentSlot, calledByExternalAddonName, tooltipAdditionText)
    local doAbort = false
    --IIfA addon call constant
    local IIfAaddonCallConst = otherAddons.IIFAaddonCallName
    --Initialize the possible external addon call table
    local externalAddonCall = {}
    local possibleExternalAddonCalls = otherAddons.possibleExternalAddonCalls
    if possibleExternalAddonCalls ~= nil and #possibleExternalAddonCalls > 0 then
        for _, externalAddonName in ipairs(possibleExternalAddonCalls) do
            externalAddonCall[externalAddonName] = false
        end
    end
    doHide = doHide or false
    pUpdateAllEquipmentTooltips = pUpdateAllEquipmentTooltips or false
    pIsEquipmentSlot = pIsEquipmentSlot or false
    calledByExternalAddonName = calledByExternalAddonName or ""
    local settings = FCOIS.settingsVars.settings
    if markerControl == nil or markerId == nil then doAbort = true end

    isDynamicGearIcon = isDynamicGearIcon or FCOIS.IsDynamicGearIcon
    isMarked = isMarked or FCOIS.IsMarked
    isMarkedByItemInstanceId = isMarkedByItemInstanceId or FCOIS.IsMarkedByItemInstanceId
    checkAndGetIIfAData = checkAndGetIIfAData or FCOIS.CheckAndGetIIfAData

    --[[
    if not doAbort then
        if settings.debug then debugMessage( "[CreateToolTip]","MarkerControl: " .. markerControl:GetName() .. ", markerId: " .. tostring(markerId) .. ", doHide: " .. tostring(doHide) .. "EquipmentSlot: " .. tostring(pIsEquipmentSlot), true, FCOIS_DEBUG_DEPTH_ALL) end
    else
        if settings.debug then debugMessage( "[CreateToolTip]", "<<Aborting!", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    end
    ]]

    --If the character tooltips are disabled - Abort here
    if pIsEquipmentSlot and not settings.showIconTooltipAtCharacter then doAbort = true end

    --Set a tooltip?
    if not doAbort and settings.showMarkerTooltip[markerId] == true and markerControl ~= nil then
        local tooltipText = ""
        local tooltipGearText = ""
        local finalTooltipText = ""
        local markedCounter = 0
        local markedGear = 0
        local equipmentMarkerControlName
        local protectedData = FCOIS.protectedData
        local protectedColor = protectedData.colors
        local protectionEnabledColor = protectedColor[true]
        local protectionDisabledColor = protectedColor[false]
        local fcoisLoc                = FCOIS.localizationVars.fcois_loc
        local iconGearTooltipText     = fcoisLoc["options_icon_gear_tooltip_text"]
        local iconGearsTooltipText    = fcoisLoc["options_icon_gears_tooltip_text"]

        local panelId = FCOIS.gFilterWhere
        local filterPanelIdToWhereAreWe = mappingVars.filterPanelIdToWhereAreWe
        local whereAreWe = filterPanelIdToWhereAreWe[panelId]
--d("[FCOIS]CreateToolTip - filterPanelId: " ..tostring(panelId) .. ", whereAreWe: " ..tostring(whereAreWe))

        --Are we adding a tooltip to an equipment slot?
        if settings.showIconTooltipAtCharacter and pUpdateAllEquipmentTooltips then
            --Get current controls name
            equipmentMarkerControlName = markerControl:GetName()
            --to strip N characters from the end, you can use negative end index:
            --equipmentMarkerControlName = equipmentMarkerControlName:sub(1, -1-FCOIS.gFCOMaxDigitsForIcons)
            --New replacement method, faster by pattern
            equipmentMarkerControlName = equipmentMarkerControlName:gsub("%d+$", "")
        end

        --Check if the item is marked with several icons
        local markedIcons = {}

        local markersParentControl = markerControl:GetParent()
        local itemLink, itemInstanceOrUniqueId, bagId, slotIndex
        --Did any other addon call this function or was it called internally from FCOIS?
        if calledByExternalAddonName ~= nil and calledByExternalAddonName ~= "" then
            --Inventory insight from Ashes called this function to update it's FCOIS marker textures with the tooltip
            if calledByExternalAddonName == IIfAaddonCallConst then
                --Set variable for IIfAcall to true
                externalAddonCall[IIfAaddonCallConst] = true
                --Check if an IIfA row was right clicked and if the needed data (itemInstace or uniqueId, bag and slot) are given for that row
                local itemLinkIIfA, itemInstanceOrUniqueIdIIfA, bagIdIIfA, slotIndexIIfA = checkAndGetIIfAData(markersParentControl, markersParentControl:GetParent())
                itemLink, itemInstanceOrUniqueId, bagId, slotIndex = itemLinkIIfA, itemInstanceOrUniqueIdIIfA, bagIdIIfA, slotIndexIIfA
            end
        else
            bagId, slotIndex = myGetItemDetails(markersParentControl)
        end
        local iconIsDynamic = mappingVars.iconIsDynamic
        --is the bagId and slotIndex given?
        if bagId ~= nil or slotIndex ~= nil then
            --d("[FCOIS]CreateToolTip - bagId: " .. tostring(bagId) .. ", slotIndex: " .. tostring(slotIndex))
            FCOIS.preventerVars.gCalledFromInternalFCOIS = true
            --FCOIS.IsMarked(bag, slot, iconIds, excludeIconIds)
            local _, markedIconsBagSlot = isMarked(bagId, slotIndex, -1, nil)
            markedIcons = markedIconsBagSlot
        --is only the itemInstance or unique ID given?
        elseif itemInstanceOrUniqueId ~= nil then
            --d("[FCOIS]CreateToolTip - itemInstanceOrUniqueId: " .. tostring(itemInstanceOrUniqueId))
            FCOIS.preventerVars.gCalledFromInternalFCOIS = true
            --isMarkedByItemInstanceId(itemInstanceId, iconIds, excludeIconIds)
            local _, markedIconsItemInstanceOrUniqueId = isMarkedByItemInstanceId(itemInstanceOrUniqueId, -1, nil)
            markedIcons = markedIconsItemInstanceOrUniqueId
        end
        if markedIcons then
            --For each marked icon ID
            for iconId, iconIsMarked in pairs(markedIcons) do
                local iconIsEnabled = settings.isIconEnabled[iconId]
                if iconIsMarked and settings.showMarkerTooltip[iconId] then
                    markedCounter = markedCounter + 1
                    --Tooltip for any gear set?
                    local isGearIcon = settings.iconIsGear
                    if isGearIcon[iconId] then
                        local colorForText = ""
                        markedGear = markedGear + 1
                        if tooltipGearText ~= "" then tooltipGearText = tooltipGearText .. "\n" end
                        local isDynamicGearIconMarker = isDynamicGearIcon(iconId) or false
                        local gearSettingsEnabled, isDestroyProtected = checkIfProtectedSettingsEnabled(panelId, iconId, isDynamicGearIconMarker, true, whereAreWe)
                        if not gearSettingsEnabled and isDestroyProtected then
                            gearSettingsEnabled = isDestroyProtected
                        end
                        --Colorize the tooltip now so one always can see if the settings for this tooltip at the current panel are enabled!
                        if gearSettingsEnabled then
                            colorForText = protectionEnabledColor
                        else
                            colorForText = protectionDisabledColor
                        end
                        local gearName = ""
                        --Mark the disabled gear sets gray in the tooltip
                        if not iconIsEnabled then
                            gearName = "|c404040" .. gearName .. "|r"
                        else
                            gearName = colorForText .. settings.icon[iconId].name .. "\r"
                        end
                        tooltipGearText = tooltipGearText .. gearName
                    else
                        --No gear
                        if tooltipText ~= "" then tooltipText = tooltipText .. "\n" end
                        local iconName = ""
                        --Is the icon a dynamic one?
                        if iconIsDynamic[iconId] then
                            iconName = settings.icon[iconId].name
                            --Mark the disabled icons gray in the tooltip
                            if iconIsEnabled then
                                local colorForText = ""
                                --Is the addon IIfA requesting the tooltip text? Then don't colorize the text of the icon by the help of the protective settings!
                                if externalAddonCall[IIfAaddonCallConst] == false then
                                    --Check if the current dynamic icons's settings are enabled at the given panel
                                    --Call with 3rd parameter "isDynamicIcon" = true to skip "is dynamic icon check" inside the function again
--d(">TooltipDynIconCheck: " ..tostring(iconId) .. ", name: " ..tostring(iconName) .. ", panelId: " ..tostring(panelId) .. ", whereAreWe: " ..tostring(whereAreWe))
                                    local dynamicSettingsEnabled, isDestroyProtected = checkIfProtectedSettingsEnabled(panelId, iconId, true, true, whereAreWe)
--d(">dynamicSettingsEnabled: " ..tostring(dynamicSettingsEnabled) .. ", isDestroyProtected: " ..tostring(isDestroyProtected))
                                    if not dynamicSettingsEnabled and isDestroyProtected then
                                        dynamicSettingsEnabled = isDestroyProtected
                                    end
                                    --Colorize the tooltip now so one always can see if the settings for this tooltip at the current panel are enabled!
                                    if dynamicSettingsEnabled then
                                        colorForText = protectionEnabledColor
                                    else
                                        colorForText = protectionDisabledColor
                                    end
                                end
                                iconName = colorForText .. iconName .. "|r"
                            end
                        --No gear and no dynamic icon -> Static icon!
                        else
                            local colorForText = ""
                            local normalSettingsEnabled, isDestroyProtected = checkIfProtectedSettingsEnabled(panelId, iconId, nil, true, whereAreWe)
                            if not normalSettingsEnabled and isDestroyProtected then
                                normalSettingsEnabled = isDestroyProtected
                            end
                            if normalSettingsEnabled then
                                colorForText = protectionEnabledColor
                            else
                                colorForText = protectionDisabledColor
                            end
                            iconName = colorForText .. fcoisLoc["options_icon" .. tostring(iconId) .. "_tooltip_text"] .. "|r"
                        end
                        --Gray out disabled icon
                        if not iconIsEnabled then
                            iconName = "|c404040" .. iconName .. "|r"
                        end
                        tooltipText = tooltipText .. iconName
                    end

                    --As only one marker was changed in the equipped items all markes for this item must be updated too (except the currently used marker ID)
                    if settings.showIconTooltipAtCharacter and iconId ~= markerId and pUpdateAllEquipmentTooltips then
                        --Replace current control name ending by the current iconId
                        local equipmentMarkerControlNewName = equipmentMarkerControlName .. tostring(iconId)
                        --get the control by it's name
                        local equipmentMarkerControl = GetControl(equipmentMarkerControlNewName) --wm:GetControlByName(equipmentMarkerControlNewName, "")
                        if equipmentMarkerControl ~= nil then
                            createToolTip(equipmentMarkerControl, iconId, doHide, false, nil, nil, nil)
                        end
                    end
                end
            end -- for each marked icon ID
            --Build the final tooltip text
            if markedCounter == 1 then
                --Build the tooltip for only 1 marked icon
                --Tooltip for any gear set?
                --local iconIsGear = mappingVars.iconIsGear
                local iconIsGear = settings.iconIsGear
                --[[
                if (iconIsGear[markerId]) then
                    finalTooltipText = preChatTextGreen .. " " .. iconGearTooltipText .. settings.icon[markerId].name
                elseif (iconIsDynamic[markerId]) then
                    finalTooltipText = preChatTextGreen .. " " .. tooltipText
                else
                    finalTooltipText = preChatTextGreen .. " " .. locVars["options_icon" .. tostring(markerId) .. "_tooltip_text"]
                end
                ]]
                if (iconIsGear[markerId]) then
                    finalTooltipText = preChatTextGreen .. " " .. iconGearTooltipText .. tooltipGearText
                elseif (iconIsDynamic[markerId]) then
                    finalTooltipText = preChatTextGreen .. " " .. tooltipText
                else
                    finalTooltipText = preChatTextGreen .. " " .. tooltipText
                end
            else
                finalTooltipText = preChatTextGreen .. "\n"
                --Build the tooltip text for several marked icons
                if     tooltipGearText ~= "" and tooltipText ~= "" then
                    finalTooltipText = finalTooltipText .. tooltipText .. "\n\n"
                    if markedGear > 1 then
                        finalTooltipText = finalTooltipText .. iconGearsTooltipText .. "\n"
                    else
                        finalTooltipText = finalTooltipText .. iconGearTooltipText
                    end
                    finalTooltipText = finalTooltipText .. tooltipGearText
                elseif tooltipGearText ~= "" and tooltipText == "" then
                    if markedGear > 1 then
                        finalTooltipText = finalTooltipText .. iconGearsTooltipText .. "\n"
                    else
                        finalTooltipText = finalTooltipText .. iconGearTooltipText
                    end
                    finalTooltipText = finalTooltipText .. tooltipGearText
                elseif tooltipGearText == "" and tooltipText ~= "" then
                    finalTooltipText = finalTooltipText .. tooltipText
                end
            end

            if finalTooltipText ~= nil then
                --Is an additional tooltip text given from another addon, which should be added to the tooltip of FCOIS marker icons?
                --e.g. "Stolen" or "Worn" info
                if tooltipAdditionText ~= nil and tooltipAdditionText ~= "" then
                    local tooltipAdditionTextSpacer = "\n"
                    finalTooltipText = finalTooltipText .. tooltipAdditionTextSpacer .. tooltipAdditionText
                end

                --====================================================================================================================================
                -- SetTracker - BEGIN
                --====================================================================================================================================
                --SetTracker Addon is active and the set note should be added to FCOIS marker icon tooltips?
                --#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300
                local isSetTrackerActive = otherAddons.SetTracker.isActive
                if    bagId ~= nil and slotIndex ~= nil and isSetTrackerActive and SetTrack ~= nil and SetTrack.GetTrackingInfo ~= nil
                        and settings.autoMarkSetTrackerSets and settings.autoMarkSetTrackerSetsShowTooltip then
                    --Get the set note text for the current item
                    local iTrackIndex, sTrackName, sTrackColour, sTrackNotes = SetTrack.GetTrackingInfo(bagId, slotIndex)
                    if iTrackIndex ~= -1 and iTrackIndex ~= 100 then
                        local setTrackerSetNote = sTrackNotes
                        if setTrackerSetNote and setTrackerSetNote ~= "" then
                            local setTrackerHeadline = fcoisLoc["options_header_settracker"] or "Set Tracker"
                            if sTrackName ~= nil and sTrackName ~= "" then
                                if sTrackColour ~= nil and sTrackColour ~= "" then
                                    --Colorize the headline with the SetTracker trackingColor
                                    sTrackName = "|c" .. tostring(sTrackColour) .. sTrackName .. "|r"
                                end
                                --Add the headline to the notes -> The tracked name
                                setTrackerHeadline =  setTrackerHeadline .. " [" .. sTrackName .. "]:"
                                if setTrackerHeadline ~= nil and setTrackerHeadline ~= "" then
                                    setTrackerSetNote = setTrackerHeadline .. "\n" .. setTrackerSetNote
                                end
                            end
                            finalTooltipText = finalTooltipText .. "\n\n" .. setTrackerSetNote
                        end
                    end
                end
                --====================================================================================================================================
                -- SetTracker - END
                --====================================================================================================================================
            else
                --Is an additional tooltip text given from another addon, which should be added to the tooltip of FCOIS marker icons?
                --e.g. "Stolen" or "Worn" info
                if tooltipAdditionText ~= nil and tooltipAdditionText ~= "" then
                    finalTooltipText = tooltipAdditionText
                end
            end
            --is the tooltip text given now?
            if finalTooltipText ~= nil then
                markerControl:SetMouseEnabled(true)
                markerControl:SetDrawTier(DT_HIGH)
                markerControl.tooltipText = finalTooltipText
                if markerControl:GetHandler("OnMouseEnter") == nil then
                    markerControl:SetHandler("OnMouseEnter", function(self)
                        local showTooltip = settings.showMarkerTooltip[markerId]
                        if showTooltip == true then
                            ZO_Tooltips_ShowTextTooltip(self, BOTTOM, self.tooltipText)
                        else
                            ZO_Tooltips_HideTextTooltip()
                        end
                    end)
                end
                if markerControl:GetHandler("OnMouseExit") == nil then
                    markerControl:SetHandler("OnMouseExit", function(self)
                        ZO_Tooltips_HideTextTooltip()
                    end)
                end
            end

        else
            doAbort = true
        end
    else
        doAbort = true
    end

    --Abort?
    if doAbort then
        markerControl:SetMouseEnabled(false)
        markerControl:SetDrawTier(DT_MEDIUM)
        ZO_Tooltips_HideTextTooltip()
    end
end
createToolTip = FCOIS.CreateToolTip

function FCOIS.BuildMarkerIconsTooltipText(markerIcons, newLineStr, onlyMarkedCount)
    onlyMarkedCount = onlyMarkedCount or false
    newLineStr = newLineStr or "\n"
    local countMarked = 0
    local countTotal = 0
    local tooltipTextOfMarkerIcons = ""

    local locVars
    local locVarsFCO

    for iconId, iconIsMarked in pairs(markerIcons) do
        countTotal = countTotal + 1
        if iconIsMarked == true then
            countMarked = countMarked + 1
            if not onlyMarkedCount then
                locVars = locVars or FCOIS.localizationVars
                locVarsFCO = locVarsFCO or locVars.fcois_loc

                --Build the tooltip text for SHIFT+ mouse over at the context menu entry to show the icons last marked
                if tooltipTextOfMarkerIcons ~= "" then
                    tooltipTextOfMarkerIcons = tooltipTextOfMarkerIcons .. newLineStr
                end
                getIconText = getIconText or FCOIS.GetIconText
                local iconName = getIconText(iconId, true, false, false) or tos(iconId)
                tooltipTextOfMarkerIcons = tooltipTextOfMarkerIcons .. iconName
            end
        end
    end
    return tooltipTextOfMarkerIcons, countMarked, countTotal
end

--Build the tooltip for e.g. a marker icon's context menu entry and show which panel is protected at this marker icon
function FCOIS.BuildMarkerIconProtectedWhereTooltip(markId)
    --local icon2Dyn = mappingVars.iconIsDynamic
    local locVars = FCOIS.localizationVars
    local locVarsFCO = locVars.fcois_loc
    local protectedAtStr = "[" .. locVarsFCO["protection_at_panel"] .. "]"
    local filterPanelNames = locVarsFCO["FCOIS_LibFilters_PanelIds"]
    local activeFilterPanelIds = mappingVars.activeFilterPanelIds
    local protectedData = FCOIS.protectedData
    local protectedColorPrefixes = protectedData.colors
    local protectedTextures = protectedData.textures
    local filterPanelIdToWhereAreWe = mappingVars.filterPanelIdToWhereAreWe
    local panelId = FCOIS.gFilterWhere
    --For each possible filterPanelId:
    for libFilterPanelId, isActivated in pairs(activeFilterPanelIds) do
        if isActivated then
            --Get the name of the filter panelId
            local filterPanelName = filterPanelNames[libFilterPanelId]
            if filterPanelName and filterPanelName ~= "" then
                --Check the protection of the markerIcon there
                local whereAreWe = filterPanelIdToWhereAreWe[libFilterPanelId]
                local isProtected, isDestroyProtected = checkIfProtectedSettingsEnabled(libFilterPanelId, markId, nil, true, whereAreWe)
                if not isProtected and isDestroyProtected then
                    isProtected = isDestroyProtected
                end
                if isProtected == nil then isProtected = "non_active" end
                local protectedColorPrefix = protectedColorPrefixes[isProtected]
                local protectedTexture = protectedTextures[isProtected]
                --Add the texture to the filterpanelName
                --filterPanelName = zo_strformat(filterPanelName .. " <<1>>", zo_iconFormat(protectedTexture, 20, 20))
                filterPanelName = zo_iconTextFormatNoSpace(protectedTexture, 20, 20, filterPanelName, protectedColorPrefix)
                --Is the filterPanelId the current filterPanelid? Then add the [ in front and ]aat the end
                if libFilterPanelId == panelId then
                    filterPanelName = "[  " .. filterPanelName .. "  ]"
                end
                --And then add the texture, afterwards the name of the panel colorized to the text output
                protectedAtStr = protectedAtStr .. "\n" .. protectedColorPrefix .. filterPanelName .. "|r"
            end
        end
    end
    return protectedAtStr
end