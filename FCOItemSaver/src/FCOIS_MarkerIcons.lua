--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons

-- =====================================================================================================================
--  Tooltip functions
-- =====================================================================================================================

--Create the tooltip for the marker texture - BuildTooltip
local function CreateToolTip(markerControl, markerId, doHide, pUpdateAllEquipmentTooltips, pIsEquipmentSlot, calledByExternalAddonName, tooltipAdditionText)
    local doAbort = false
    --IIfA addon call constant
    local IIfAaddonCallConst = FCOIS.otherAddons.IIFAaddonCallName
    --Initialize the possible external addon call table
    local externalAddonCall = {}
    local possibleExternalAddonCalls = FCOIS.otherAddons.possibleExternalAddonCalls
    if possibleExternalAddonCalls ~= nil and #possibleExternalAddonCalls > 0 then
        for idx, externalAddonName in ipairs(possibleExternalAddonCalls) do
            externalAddonCall[externalAddonName] = false
        end
    end
    doHide = doHide or false
    pUpdateAllEquipmentTooltips = pUpdateAllEquipmentTooltips or false
    pIsEquipmentSlot = pIsEquipmentSlot or false
    calledByExternalAddonName = calledByExternalAddonName or ""
    local settings = FCOIS.settingsVars.settings
    if markerControl == nil or markerId == nil then doAbort = true end

    --[[
        if not doAbort then
            --if settings.debug then FCOIS.debugMessage( "[CreateToolTip] MarkerControl: " .. markerControl:GetName() .. ", markerId: " .. tostring(markerId) .. ", doHide: " .. tostring(doHide) .. "EquipmentSlot: " .. tostring(pIsEquipmentSlot), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        else
            if settings.debug then FCOIS.debugMessage( "[CreateToolTip] Aborting!", true, FCOIS_DEBUG_DEPTH_NORMAL) end
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
        local locVars = FCOIS.localizationVars.fcois_loc

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
                local itemLinkIIfA, itemInstanceOrUniqueIdIIfA, bagIdIIfA, slotIndexIIfA = FCOIS.checkAndGetIIfAData(markersParentControl, markersParentControl:GetParent())
                itemLink, itemInstanceOrUniqueId, bagId, slotIndex = itemLinkIIfA, itemInstanceOrUniqueIdIIfA, bagIdIIfA, slotIndexIIfA
            end
        else
            bagId, slotIndex = FCOIS.MyGetItemDetails(markersParentControl)
        end
        local iconIsDynamic = FCOIS.mappingVars.iconIsDynamic
        --is the bagid and slotIndex given?
        if bagId ~= nil or slotIndex ~= nil then
--d("[FCOIS]CreateToolTip - bagId: " .. tostring(bagId) .. ", slotIndex: " .. tostring(slotIndex))
            --FCOIS.IsMarked(bag, slot, iconIds, excludeIconIds)
            local _, markedIconsBagSlot = FCOIS.IsMarked(bagId, slotIndex, -1, nil)
            markedIcons = markedIconsBagSlot
        --is only the itemInstance or unique ID given?
        elseif itemInstanceOrUniqueId ~= nil then
            --d("[FCOIS]CreateToolTip - itemInstanceOrUniqueId: " .. tostring(itemInstanceOrUniqueId))
            --FCOIS.IsMarkedByItemInstanceId(itemInstanceId, iconIds, excludeIconIds)
            local _, markedIconsItemInstanceOrUniqueId = FCOIS.IsMarkedByItemInstanceId(itemInstanceOrUniqueId, -1, nil)
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
                    if (isGearIcon[iconId]) then
                        markedGear = markedGear + 1
                        if tooltipGearText ~= "" then tooltipGearText = tooltipGearText .. "\n" end
                        local gearName = settings.icon[iconId].name
                        --Mark the disabled gear sets gray in the tooltip
                        if not iconIsEnabled then
                            gearName = "|c404040" .. gearName .. "|r"
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
                                    local dynamicSettingsEnabled = FCOIS.checkIfProtectedSettingsEnabled(FCOIS.gFilterWhere, iconId, true) or false
                                    --Colorize the tooltip now so one always can see if the settings for this tooltip at the current panel are enabled!
                                    if dynamicSettingsEnabled then
                                        colorForText = "|c00FF00"
                                    else
                                        colorForText = "|cFF0000"
                                    end
                                end
                                iconName = colorForText .. iconName .. "|r"
                            end
                        else
                            iconName = locVars["options_icon" .. tostring(iconId) .. "_tooltip_text"]
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
                        local equipmentMarkerControl = WINDOW_MANAGER:GetControlByName(equipmentMarkerControlNewName, "")
                        if equipmentMarkerControl ~= nil then
                            CreateToolTip(equipmentMarkerControl, iconId, doHide, false)
                        end
                    end
                end
            end -- for each marked icon ID
            local preChatVars = FCOIS.preChatVars
            --Build the final tooltip text
            if markedCounter == 1 then
                --Build the tooltip for only 1 marked icon
                --Tooltip for any gear set?
                --local iconIsGear = FCOIS.mappingVars.iconIsGear
                local iconIsGear = settings.iconIsGear
                if (iconIsGear[markerId]) then
                    finalTooltipText = preChatVars.preChatTextGreen .. " " .. locVars["options_icon_gear_tooltip_text"] .. settings.icon[markerId].name
                elseif (iconIsDynamic[markerId]) then
                    finalTooltipText = preChatVars.preChatTextGreen .. " " .. tooltipText
                else
                    finalTooltipText = preChatVars.preChatTextGreen .. " " .. locVars["options_icon" .. tostring(markerId) .. "_tooltip_text"]
                end
            else
                finalTooltipText = preChatVars.preChatTextGreen .. "\n"
                --Build the tooltip text for several marked icons
                if     tooltipGearText ~= "" and tooltipText ~= "" then
                    finalTooltipText = finalTooltipText .. tooltipText .. "\n\n"
                    if markedGear > 1 then
                        finalTooltipText = finalTooltipText .. locVars["options_icon_gears_tooltip_text"] .. "\n"
                    else
                        finalTooltipText = finalTooltipText .. locVars["options_icon_gear_tooltip_text"]
                    end
                    finalTooltipText = finalTooltipText .. tooltipGearText
                elseif tooltipGearText ~= "" and tooltipText == "" then
                    if markedGear > 1 then
                        finalTooltipText = finalTooltipText .. locVars["options_icon_gears_tooltip_text"] .. "\n"
                    else
                        finalTooltipText = finalTooltipText .. locVars["options_icon_gear_tooltip_text"]
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
                local isSetTrackerActive = FCOIS.otherAddons.SetTracker.isActive
                if    bagId ~= nil and slotIndex ~= nil and isSetTrackerActive and SetTrack ~= nil and SetTrack.GetTrackingInfo ~= nil
                        and settings.autoMarkSetTrackerSets and settings.autoMarkSetTrackerSetsShowTooltip then
                    --Get the set note text for the current item
                    local iTrackIndex, sTrackName, sTrackColour, sTrackNotes = SetTrack.GetTrackingInfo(bagId, slotIndex)
                    if iTrackIndex ~= -1 and iTrackIndex ~= 100 then
                        local setTrackerSetNote = sTrackNotes
                        if setTrackerSetNote and setTrackerSetNote ~= "" then
                            local setTrackerHeadline = locVars["options_header_settracker"] or "Set Tracker"
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
FCOIS.CreateToolTip = CreateToolTip

-- =====================================================================================================================
--  Marker control / textures functions
-- =====================================================================================================================
--Update the "already bound set part" icon at the item's top right image edge
local function updateAlreadyBoundTexture(parent, pHideControl)
    if parent == nil then return end
    pHideControl = pHideControl or false
    --Hide the control if settings are disabled or the function parameter tells it to do so
    --Is the item a non-bound item? en hide it!
    local doHide
    if pHideControl then
        doHide = true
    else
        local showBoundItemMarker = FCOIS.settingsVars.settings.showBoundItemMarker
        doHide = not showBoundItemMarker
        if not doHide then
            --Get the bagId and slotIndex
            local bagId, slotIndex = FCOIS.MyGetItemDetails(parent)
            if bagId == nil or slotIndex == nil then return end
            doHide = not FCOIS.isItemAlreadyBound(bagId, slotIndex)
        end
    end
    --If not an equipped item: Get the row's/parent's image -> "Children "Button" of parent
    local parentsImage = parent:GetNamedChild("Button")
    if parentsImage ~= nil then
        --d("parentsImage: " .. parentsImage:GetName())
        local alreadyBoundTexture = "esoui/art/ava/avacapturebar_point_aldmeri.dds"
        local addonName = FCOIS.addonVars.gAddonName
        local setPartAlreadyBoundName = parent:GetName() .. addonName .. "AlreadyBoundIcon"
        if alreadyBoundTexture ~= nil then
            local setPartAlreadyBoundTexture
            setPartAlreadyBoundTexture = WINDOW_MANAGER:GetControlByName(setPartAlreadyBoundName, "")
            if setPartAlreadyBoundTexture == nil then
                setPartAlreadyBoundTexture= WINDOW_MANAGER:CreateControl(setPartAlreadyBoundName, parentsImage, CT_TEXTURE)
            end
            if setPartAlreadyBoundTexture ~= nil then
                --d(">texture created")
                --Hide or show the control now
                setPartAlreadyBoundTexture:SetHidden(doHide)
                if not doHide then
                    setPartAlreadyBoundTexture:SetDimensions(48, 48)
                    setPartAlreadyBoundTexture:SetTexture(alreadyBoundTexture)
                    --setPartAlreadyBoundTexture:SetColor(1, 1, 1, 1)
                    setPartAlreadyBoundTexture:SetDrawTier(DT_HIGH)
                    setPartAlreadyBoundTexture:ClearAnchors()
                    setPartAlreadyBoundTexture:SetAnchor(TOPLEFT, parentsImage, TOPRIGHT, -25, -8)
                end
            end
        end
    end
end

--Create the marker controls, holding the icon textures
--Will be created/updated as inventories get updated row by row (scrolling) -> by the help of function "CreateTextures()"
--Will also add/show/hide the small "is the set item already bound" icon at the top-right edge of the item's image (children "Button" of parent
-->Only adds the texture if it does not already exist and if the marker icon is enabled!
function FCOIS.CreateMarkerControl(parent, controlId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl)
    --No parent? Abort here
    if parent == nil then return nil end
    --d(">>FCOIS.CreateMarkerControl: " .. tostring(parent:GetName()))
    pArmorTypeIcon = pArmorTypeIcon or false
    pHideControl = pHideControl or false

    local InventoryGridViewActivated = false

    --Preset the variable for control creation with false, if it is not given
    pCreateControlIfNotThere	= pCreateControlIfNotThere or false
    pUpdateAllEquipmentTooltips	= pUpdateAllEquipmentTooltips or false
    --Is the parent's owner control not the quickslot circle?
    local ctrlVars = FCOIS.ZOControlVars
    if(parent:GetOwningWindow() ~= ctrlVars.QUICKSLOT_CIRCLE) then
        if pIsEquipmentSlot == nil then pIsEquipmentSlot = false end

        --Does the FCOItemSaver marker control exist already?
        local control = FCOIS.GetItemSaverControl(parent, controlId, false)
        local doHide = pHideControl

        local settings = FCOIS.settingsVars.settings
        --Should the control not be hidden? Then check it's marker settings and if a marker is set
        if not doHide then
            --Marker control for a disabled icon? Hide the icon then
            if not settings.isIconEnabled[controlId] then
                --Do not hide the texture anymore but do not create it to save memory
                --doHide = true
                return false
            else
                --Control should be shown
                doHide = not FCOIS.checkIfItemIsProtected(controlId, FCOIS.MyGetItemInstanceId(parent))
            end
        end
        if doHide == nil then doHide = false end

        --Remove the sell icon and price if Inventory gridview is active
        if(parent:GetWidth() - parent:GetHeight() < 5) then
            if(parent:GetNamedChild("SellPrice")) then
                parent:GetNamedChild("SellPrice"):SetHidden(true)
            end
            InventoryGridViewActivated = true
        end

        --It does not exist yet, so create it now
        if(control == parent or not control) then
            --Abort here if control should be hiden and is not created yet
            if doHide == true and pCreateControlIfNotThere == false then
                ZO_Tooltips_HideTextTooltip()
                return
            end
            --If not aborted: Create the marker control now
            local addonName = FCOIS.addonVars.gAddonName
            control = WINDOW_MANAGER:CreateControl(parent:GetName() .. addonName .. tostring(controlId), parent, CT_TEXTURE)
        end
        --Control did already exist or was created now
        if control ~= nil then
            --Hide or show the control now
            control:SetHidden(doHide)

            if not doHide then
                control:SetDimensions(pWidth, pHeight)
                control:SetTexture(pTexture)
                local iconSettingsColor = settings.icon[controlId].color
                control:SetColor(iconSettingsColor.r, iconSettingsColor.g, iconSettingsColor.b, iconSettingsColor.a)
                --Marker was created/updated for the character equipment slots?
                if pIsEquipmentSlot == true then
                    control:ClearAnchors()
                    --Move the marker controls of equipment slots according to settings
                    --control:SetAnchor(BOTTOMLEFT, parent, BOTTOMLEFT, -6, 5)
                    local iconPositionCharacter = settings.iconPositionCharacter
                    control:SetAnchor(BOTTOMLEFT, parent, BOTTOMLEFT, iconPositionCharacter.x, iconPositionCharacter.y)
                    control:SetDrawTier(DT_HIGH)
                else
                    if InventoryGridViewActivated == true then
                        control:SetDrawTier(DT_HIGH)
                        control:ClearAnchors()
                        control:SetAnchor(CENTER, parent, BOTTOMLEFT, 12, -12)
                    else
                        control:SetDrawTier(DT_HIGH)
                        control:ClearAnchors()
                        --Get the currently active filter panel ID and map the appropriate inventory for the icon X axis offset
                        local filterPanelIdToIconOffset = FCOIS.mappingVars.filterPanelIdToIconOffset
                        local iconPosition = settings.iconPosition
                        local iconOffset = filterPanelIdToIconOffset[FCOIS.gFilterWhere] or iconPosition
                        control:SetAnchor(LEFT, parent, LEFT, iconOffset.x, iconOffset.y)
                    end
                end

            end  -- if not doHide then
            --Set the tooltip if wished
            CreateToolTip(control, controlId, doHide, pUpdateAllEquipmentTooltips, pIsEquipmentSlot)
            return control
        else
            return nil
        end
    else
        --Quickslot Circle
        return nil
    end
end

--Create the textures inside inventories etc.
function FCOIS.CreateTextures(whichTextures)

    local doCreateMarkerControl = false
    local doCreateAllTextures = false
    if whichTextures == -1 then
        doCreateMarkerControl = true
        doCreateAllTextures = true
    end
    local iconSettings = FCOIS.settingsVars.settings.icon
    local markerTextureVars = FCOIS.textureVars.MARKER_TEXTURES
    --All inventories
    if (whichTextures == 1 or doCreateAllTextures) then
        --Create textures in inventories
        for _,v in pairs(PLAYER_INVENTORY.inventories) do
            local listView = v.listView
            --Do not hook quest items
            if (listView and listView.dataTypes and listView.dataTypes[1] and (listView:GetName() ~= "ZO_PlayerInventoryQuest")) then
                local hookedFunctions = listView.dataTypes[1].setupCallback

                listView.dataTypes[1].setupCallback =
                function(rowControl, slot)
                    hookedFunctions(rowControl, slot)
                    --Do not execute if horse is changed
                    if SCENE_MANAGER:GetCurrentScene() ~= STABLES_SCENE then
                        -- for all filters: Create/Update the icons
                        for i=1, numFilterIcons, 1 do
                            --FCOIS.CreateMarkerControl(parent, controlId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl)
                            FCOIS.CreateMarkerControl(rowControl, i, iconSettings[i].size, iconSettings[i].size, markerTextureVars[iconSettings[i].texture], false, doCreateMarkerControl)
                        end
                        --Add additional FCO point to the dataEntry.data slot
                        --FCOItemSaver_AddInfoToData(rowControl)
                        --Create and show the "already bound" set parts texture at the top-right edge of the inventory item
                        updateAlreadyBoundTexture(rowControl)
                    end
                end
            end
        end
    end
    --Repair list
    if (whichTextures == 2 or doCreateAllTextures) then
        --Create textures in repair window
        local listView = FCOIS.ZOControlVars.REPAIR_LIST
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
            function(rowControl, slot)
                hookedFunctions(rowControl, slot)

                --Do not execute if horse is changed
                if SCENE_MANAGER:GetCurrentScene() ~= STABLES_SCENE then
                    -- for all filters: Create/Update the icons
                    for i=1, numFilterIcons, 1 do
                        FCOIS.CreateMarkerControl(rowControl, i, iconSettings[i].size, iconSettings[i].size, markerTextureVars[iconSettings[i].texture], false, doCreateMarkerControl)
                    end
                    --Add additional FCO point to the dataEntry.data slot
                    --FCOItemSaver_AddInfoToData(rowControl)
                end
            end
        end
    end
    --Player character
    if (whichTextures == 3 or doCreateAllTextures) then
        -- Marker function for character equipment if character window is shown
        if (not FCOIS.ZOControlVars.CHARACTER:IsHidden() or FCOIS.addonVars.gAddonLoaded == false) then
            FCOIS.RefreshEquipmentControl()
        end
    end
    --Quickslot
    if (whichTextures == 4 or doCreateAllTextures) then
        -- Marker function for quickslots inventory
        local listView = FCOIS.ZOControlVars.QUICKSLOT_LIST
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
            function(rowControl, slot)
                hookedFunctions(rowControl, slot)

                --Do not execute if horse is changed
                if SCENE_MANAGER:GetCurrentScene() ~= STABLES_SCENE then
                    -- for all filters: Create/Update the icons
                    for i=1, numFilterIcons, 1 do
                        FCOIS.CreateMarkerControl(rowControl, i, iconSettings[i].size, iconSettings[i].size, markerTextureVars[iconSettings[i].texture], false, doCreateMarkerControl)
                    end
                    --Add additional FCO point to the dataEntry.data slot
                    --FCOItemSaver_AddInfoToData(rowControl)
                end
            end
        end
    end
    --Transmuation
    if (whichTextures == 5 or doCreateAllTextures) then
        --Create textures in repair window
        local listView = FCOIS.ZOControlVars.RETRAIT_LIST
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
            function(rowControl, slot)
                hookedFunctions(rowControl, slot)

                --Do not execute if horse is changed
                if SCENE_MANAGER:GetCurrentScene() ~= STABLES_SCENE then
                    -- for all filters: Create/Update the icons
                    for i=1, numFilterIcons, 1 do
                        FCOIS.CreateMarkerControl(rowControl, i, iconSettings[i].size, iconSettings[i].size, markerTextureVars[iconSettings[i].texture], false, doCreateMarkerControl)
                    end
                    --Add additional FCO point to the dataEntry.data slot
                    --FCOItemSaver_AddInfoToData(rowControl)
                end
            end
        end
    end
end

--Check if marker textures on the inventories row should be refreshed
function FCOIS.checkMarker(markerId)
    markerId = markerId or -1
    local doDebug = FCOIS.settingsVars.settings.debug
    if doDebug then FCOIS.debugMessage( "[FCOIS.checkMarker] MarkerId: " .. tostring(markerId) .. ", CheckNow: " .. tostring(FCOIS.preventerVars.gUpdateMarkersNow) .. ", Gears changed: " .. tostring(FCOIS.preventerVars.gChangedGears), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

    --Should we update the marker textures, size and color?
    if FCOIS.preventerVars.gUpdateMarkersNow == true or FCOIS.preventerVars.gChangedGears == true then
        --Update the textures now
        FCOIS.RefreshBackpack()
        FCOIS.RefreshBank()
        FCOIS.RefreshGuildBank()

        if not FCOIS.preventerVars.gChangedGears then
            zo_callLater(function()
                --d("character hidden: " .. tostring(FCOIS.ZOControlVars.CHARACTER:IsHidden()))
                if not FCOIS.ZOControlVars.CHARACTER:IsHidden() then
                    FCOIS.RefreshEquipmentControl()
                end
            end, 100)
        end

        --Set the global preventer variable back to false
        FCOIS.preventerVars.gUpdateMarkersNow = false
        FCOIS.preventerVars.gChangedGears	  = false
    end
end

--Clear all current markers of the selected row
function FCOIS.ClearOrRestoreAllMarkers(rowControl, bagId, slotIndex)
    --d("FCOIS [FCOIS.ClearOrRestoreAllMarkers]")
    if rowControl == nil then return end
    if bagId == nil or slotIndex == nil then
        bagId, slotIndex = FCOIS.MyGetItemDetails(rowControl)
    end
    if bagId == nil or slotIndex == nil then return false end
    local isCharacterShown = not FCOIS.ZOControlVars.CHARACTER:IsHidden()
    local lastMarkedIcons = FCOIS.lastMarkedIcons
    FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = false
    --Restore temporarily saved marker icons
    if lastMarkedIcons ~= nil and lastMarkedIcons[bagId] ~= nil and lastMarkedIcons[bagId][slotIndex] ~= nil then
        --d("restore - bag: " .. bagId .. ", slotIndex: " .. slotIndex)
        --Restore saved markers for the current item?
        local loc_counter = 1
        for iconId, iconIsMarked in pairs(lastMarkedIcons[bagId][slotIndex]) do
            --Reset all markers
            FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = (loc_counter == #lastMarkedIcons[bagId][slotIndex])
            --Refresh the control now to update the set marker icons?
            local refreshNow = isCharacterShown or (loc_counter == #lastMarkedIcons[bagId][slotIndex])
            FCOIS.MarkItem(bagId, slotIndex, iconId, iconIsMarked, refreshNow)
            --Check if the item needs to be removed from a craft slot or the guild store sell tab now
            FCOIS.IsItemProtectedAtASlotNow(bagId, slotIndex)
            loc_counter = loc_counter + 1
        end
        --Reset the last saved marker array for the current item
        lastMarkedIcons[bagId][slotIndex] = nil
        FCOIS.lastMarkedIcons[bagId][slotIndex] = nil

    --Clear all marker icons
    else
        --d("clear")
        --Clear all markers of current item
        local currentMarkedIcons = {}
        local currentMarkedIconsUnchanged = {}
        --local itemInstanceId = FCOIS.MyGetItemInstanceIdNoControl(bagId, slotIndex)
        --Return false for marked icons, where the icon id is disabled in the settings
        FCOIS.preventerVars.doFalseOverride = true
        local _, currentMarkedIcons = FCOIS.IsMarked(bagId, slotIndex, -1)
        --Reset to normal return values for marked & en-/disabled icons now
        FCOIS.preventerVars.doFalseOverride = false
        --Build the backup array with normal marked icons now
        local _, currentMarkedIconsUnchanged = FCOIS.IsMarked(bagId, slotIndex, -1)

        --For each marked icon of the currently improved item:
        --Set the icons/markers of the previous item again
        if currentMarkedIcons and #currentMarkedIcons > 0 then
            --Create the arrays if any marker icon is set currently
            if FCOIS.lastMarkedIcons == nil then FCOIS.lastMarkedIcons = {} end
            if FCOIS.lastMarkedIcons[bagId] == nil then FCOIS.lastMarkedIcons[bagId] = {} end
            if FCOIS.lastMarkedIcons[bagId][slotIndex] == nil then FCOIS.lastMarkedIcons[bagId][slotIndex] = {} end
            --Counter vars
            local loc_counter = 1
            local loc_marked_counter = 0
            --Loop over each of the marker icons and remove them
            for iconId, iconIsMarked in pairs(currentMarkedIcons) do
                --Only go on if item is marked or is the last marker (to update the inventory afterwards)
                if iconIsMarked or (loc_counter == #currentMarkedIcons) then
                    if iconIsMarked then
                        loc_marked_counter = loc_marked_counter + 1
                    end
                    FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = (loc_counter == #currentMarkedIcons)
                    --Refresh the control now to update the cleared marker icons?
                    local refreshNow = isCharacterShown or ((loc_counter == #currentMarkedIcons) and loc_marked_counter > 0)
                    --Remove all markers
                    FCOIS.MarkItem(bagId, slotIndex, iconId, false, refreshNow)
                end
                loc_counter = loc_counter + 1
            end
            --Only save the last saved markers if any marker was set
            if loc_marked_counter > 0 then
                FCOIS.lastMarkedIcons[bagId][slotIndex] = currentMarkedIconsUnchanged
            end
        end
    end
end

function FCOIS.checkIfClearOrRestoreAllMarkers(clickedRow, shiftKey, upInside, mouseButton, refreshPopupDialogButons)
--d("[FCOIS.checkIfClearOrRestoreAllMarkers]")
    --Enable clearing all markers by help of the SHIFT+right click?
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
    if shiftKey == true and upInside and mouseButton == MOUSE_BUTTON_INDEX_RIGHT and contextMenuClearMarkesByShiftKey then
        refreshPopupDialogButons = refreshPopupDialogButons or false
        -- make sure control contains an item
        local bagId, slotIndex = FCOIS.MyGetItemDetails(clickedRow)
        if bagId ~= nil and slotIndex ~= nil then
--d("[FCOIS] Clearing/Restoring all markers of the current item now! bag: " .. bagId .. ", slotIndex: " .. slotIndex)
            --Set the preventer variable now to suppress the context menu of inventory items
            FCOIS.preventerVars.dontShowInvContextMenu = true
--d("[FCOIS]checkIfClearOrRestoreAllMarkers - dontShowInvContextMenu: true")
            --Clear/Restore the markers now
            FCOIS.ClearOrRestoreAllMarkers(clickedRow, bagId, slotIndex)
            if refreshPopupDialogButons then
                --Unselect the item and disable the button of the popup dialog again
                FCOIS.refreshPopupDialogButtons(clickedRow, false)
            end
            --Is the character sshown, then disable the context menu "hide" variable again as the order of hooks is not
            --the same like in the inventory and the context menu will be hidden twice  in a row else!
            local isCharacter = (bagId == BAG_WORN) and not FCOIS.ZOControlVars.CHARACTER:IsHidden()
            if isCharacter then
                FCOIS.preventerVars.dontShowInvContextMenu = false
            end
        end
    end
end

-- =====================================================================================================================
--  Equipment functions
-- =====================================================================================================================

--Function to add an icon for the equipped armor type (light, medium, heavy) to an equipment slot control
local function AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, armorType)
    if equipmentSlotControl == nil then return false end
    local characterEquipmentArmorSlots = FCOIS.mappingVars.characterEquipmentArmorSlots
    --Check if the equipment slot control is an armor control
    if not characterEquipmentArmorSlots[equipmentSlotControl:GetName()] then return false end
    if armorType == nil or armorType == ARMORTYPE_NONE then return false end
    local settings = FCOIS.settingsVars.settings
    if settings.debug then FCOIS.debugMessage( "[AddArmorTypeIconToEquipmentSlot] EquipmentSlot: " .. equipmentSlotControl:GetName() .. ", armorType: " .. tostring(armorType), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

    local armorTypeLabel = WINDOW_MANAGER:GetControlByName("FCOIS_" .. equipmentSlotControl:GetName() .. "_ArmorTypeLabel")
    if settings.showArmorTypeIconAtCharacter then
        if armorTypeLabel == nil then
            armorTypeLabel = WINDOW_MANAGER:CreateControl("FCOIS_" .. equipmentSlotControl:GetName() .. "_ArmorTypeLabel", equipmentSlotControl, CT_LABEL)
        end
        if armorTypeLabel ~= nil then
            armorTypeLabel:SetFont("ZoFontAlert")
            armorTypeLabel:SetScale(0.6)
            armorTypeLabel:SetDrawLayer(DL_OVERLAY)
            armorTypeLabel:SetDrawTier(DT_HIGH)
            armorTypeLabel:SetAnchor(TOPRIGHT, equipmentSlotControl, TOPRIGHT, settings.armorTypeIconAtCharacterX, settings.armorTypeIconAtCharacterY)
            armorTypeLabel:SetDimensions(20,20)
            armorTypeLabel:SetHidden(false)
        end
    else
        --Hide the label if it exists
        if armorTypeLabel ~= nil then
            armorTypeLabel:SetHidden(true)
        end
    end

    local locVars = FCOIS.localizationVars.fcois_loc
    --Count the different equipped armor parts and show the icon at the player doll, if enabled in the settings
    if 		armorType == ARMORTYPE_LIGHT then
        FCOIS.countVars.countLightArmor = FCOIS.countVars.countLightArmor + 1
        if settings.showArmorTypeIconAtCharacter and armorTypeLabel ~= nil then
            armorTypeLabel:SetText(locVars["options_armor_type_icon_light_short"])
            armorTypeLabel:SetColor(settings.armorTypeIconAtCharacterLightColor.r, settings.armorTypeIconAtCharacterLightColor.g, settings.armorTypeIconAtCharacterLightColor.b, settings.armorTypeIconAtCharacterLightColor.a)
        end
    elseif	armorType == ARMORTYPE_MEDIUM then
        FCOIS.countVars.countMediumArmor = FCOIS.countVars.countMediumArmor + 1
        if settings.showArmorTypeIconAtCharacter and armorTypeLabel ~= nil then
            armorTypeLabel:SetText(locVars["options_armor_type_icon_medium_short"])
            armorTypeLabel:SetColor(settings.armorTypeIconAtCharacterMediumColor.r, settings.armorTypeIconAtCharacterMediumColor.g, settings.armorTypeIconAtCharacterMediumColor.b, settings.armorTypeIconAtCharacterMediumColor.a)
        end
    elseif	armorType == ARMORTYPE_HEAVY then
        FCOIS.countVars.countHeavyArmor = FCOIS.countVars.countHeavyArmor + 1
        if settings.showArmorTypeIconAtCharacter and armorTypeLabel ~= nil then
            armorTypeLabel:SetText(locVars["options_armor_type_icon_heavy_short"])
            armorTypeLabel:SetColor(settings.armorTypeIconAtCharacterHeavyColor.r, settings.armorTypeIconAtCharacterHeavyColor.g, settings.armorTypeIconAtCharacterHeavyColor.b, settings.armorTypeIconAtCharacterHeavyColor.a)
        end
    end
end

--Update the equipment header text with the information about the amount of equipped armor types
local function updateEquipmentHeaderCountText()
    local showArmorTypeHeaderTextAtCharacter = FCOIS.settingsVars.settings.showArmorTypeHeaderTextAtCharacter
    if not showArmorTypeHeaderTextAtCharacter then
        ZO_CharacterApparelSectionText:SetText(GetString(SI_CHARACTER_EQUIP_SECTION_APPAREL))
        return
    end
    local countVars = FCOIS.countVars
    local locVars = FCOIS.localizationVars.fcois_loc
    if ZO_CharacterApparelSectionText ~= nil and
            countVars.countLightArmor ~= nil and countVars.countMediumArmor ~= nil and countVars.countHeavyArmor ~= nil then
        ZO_CharacterApparelSectionText:SetText(GetString(SI_CHARACTER_EQUIP_SECTION_APPAREL) .. " (" .. locVars["options_armor_type_icon_light_short"] .. ": " .. countVars.countLightArmor .. ", " .. locVars["options_armor_type_icon_medium_short"] .. ": " .. countVars.countMediumArmor .. ", " .. locVars["options_armor_type_icon_heavy_short"] .. ": " .. countVars.countHeavyArmor .. ")")
    end
end

--function to count and update the equipped aromor parts
function FCOIS.countAndUpdateEquippedArmorTypes()
    --Reset the armor type counters
    FCOIS.countVars.countLightArmor		= 0
    FCOIS.countVars.countMediumArmor	= 0
    FCOIS.countVars.countHeavyArmor		= 0

    --Check all equipment controls
    local equipmentSlotControl
    local characterEquipmentSlotNameByIndex = FCOIS.mappingVars.characterEquipmentSlotNameByIndex
    for _, equipmentSlotName in pairs(characterEquipmentSlotNameByIndex) do
        --Get the control of the equipment slot
        equipmentSlotControl = WINDOW_MANAGER:GetControlByName(equipmentSlotName, "")
        if equipmentSlotControl ~= nil then
            --Show the armor type icons at the player doll?
            AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, FCOIS.GetArmorType(equipmentSlotControl))
        end
    end
    --Update the equipment header text and show the amount of armor types equipped
    updateEquipmentHeaderCountText()
end

--Remove the armor type marker from character doll
function FCOIS.removeArmorTypeMarker(bagId, slotId)
    local settings = FCOIS.settingsVars.settings
    local characterEquipmentSlotNameByIndex = FCOIS.mappingVars.characterEquipmentSlotNameByIndex
    if not settings.showArmorTypeIconAtCharacter then return false end
    if bagId == nil or slotId == nil then return false end
    local equipmentSlotControlName = characterEquipmentSlotNameByIndex[slotId]
    if equipmentSlotControlName == nil then return false end
    local equipmentSlotControl = WINDOW_MANAGER:GetControlByName(equipmentSlotControlName, "")
    if equipmentSlotControl == nil then return false end

    --Check slightly delayed if item is (still) equipped
    --as drag&drop the icon to its previous position will call this funciton here too
    zo_callLater(function()
        if equipmentSlotControl.stackCount == 0 then
            --Hide the text control showing the armor type for this equipment slot
            local armorTypeLabel = WINDOW_MANAGER:GetControlByName("FCOIS_" .. equipmentSlotControl:GetName() .. "_ArmorTypeLabel")
            if armorTypeLabel == nil then return true end
            armorTypeLabel:SetHidden(true)
        end
    end, 250)
end

--Function to check empty weapon slots and remove markers
function FCOIS.RemoveEmptyWeaponEquipmentMarkers(delay)
    delay = delay or 0
    --Call delayed as the equipment needs to be unequipped first
    zo_callLater(function()
        local allowedCharacterEquipmentWeaponControlNames = FCOIS.checkVars.allowedCharacterEquipmentWeaponControlNames
        local allowedCharacterEquipmentWeaponBackupControlNames = FCOIS.checkVars.allowedCharacterEquipmentWeaponBackupControlNames
        local equipVars = FCOIS.equipmentVars
        local settings = FCOIS.settingsVars.settings
        local texVars = FCOIS.textureVars
        --For each weapon equipment control: check the empty markers and remove them
        for equipmentControlName, _ in pairs(allowedCharacterEquipmentWeaponControlNames) do
            if settings.debug then FCOIS.debugMessage( "[FCOIS.RemoveEmptyWeaponEquipmentMarkers] equipmentControl: " .. equipmentControlName ..", delay: " .. delay, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            if equipmentControlName ~= nil and equipmentControlName ~= "" then
                local equipmentControl = WINDOW_MANAGER:GetControlByName(equipmentControlName, "")
                if equipmentControl ~= nil then
                    --Check if the current equipment slot name is a weapon backup slot
                    local twoHandedWeaponOffHand = false
                    if allowedCharacterEquipmentWeaponBackupControlNames[equipmentControlName] then
                        --Check if the slot contains a 2hd weapon
                        twoHandedWeaponOffHand = FCOIS.checkWeaponOffHand(equipmentControlName, "2hdall", true, true, true)
                    end
                    --Check if the equipment control got something equipped or it's a backup weapon slot containing a 2hd weapon
                    if equipmentControl.stackCount == 0 or twoHandedWeaponOffHand then
                        --Remove the markers for the filter icons at the equipment slot
                        for j=1, numFilterIcons, 1 do
                            --Last parameter = doHide (true)
                            FCOIS.CreateMarkerControl(equipmentControl, j, equipVars.gEquipmentIconWidth, equipVars.gEquipmentIconHeight, texVars.MARKER_TEXTURES[settings.icon[j].texture], true, false, false, false, true)
                        end
                    end
                end
            end
        end
    end, delay)
end

--The function to refresh the equipped items and their markers
function FCOIS.RefreshEquipmentControl(equipmentControl, doCreateMarkerControl, p_markId, dontCheckRings)
    dontCheckRings = dontCheckRings or false
    --Preset the value for "Create control if not existing yet" with false
    doCreateMarkerControl = doCreateMarkerControl or false
    local equipVars = FCOIS.equipmentVars
    local texVars = FCOIS.textureVars
    local settings = FCOIS.settingsVars.settings
    local checkVars = FCOIS.checkVars

    --is the equipment control already given?
    if equipmentControl ~= nil then
        --Check all marker ids?
        if p_markId == nil or p_markId == 0 then
            if settings.debug then FCOIS.debugMessage( "[FCOIS.RefreshEquipmentControl] Control: " .. equipmentControl:GetName() .. ", Create: " .. tostring(doCreateMarkerControl) .. ", MarkId: ALL", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Add/Update the markers for the filter icons at the equipment slot
            for j=1, numFilterIcons, 1 do
                FCOIS.CreateMarkerControl(equipmentControl, j, equipVars.gEquipmentIconWidth, equipVars.gEquipmentIconHeight, texVars.MARKER_TEXTURES[settings.icon[j].texture], true, doCreateMarkerControl, false)
            end
            --Only check a specific marker id
        else
            if settings.debug then FCOIS.debugMessage( "[FCOIS.RefreshEquipmentControl] Control: " .. equipmentControl:GetName() .. ", Create: " .. tostring(doCreateMarkerControl) .. ", MarkId: " .. tostring(p_markId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Add/Update the marker p_markId for the filter icons at the equipment slot
            FCOIS.CreateMarkerControl(equipmentControl, p_markId, equipVars.gEquipmentIconWidth, equipVars.gEquipmentIconHeight, texVars.MARKER_TEXTURES[settings.icon[p_markId].texture], true, doCreateMarkerControl, true)
        end

        --Are we chaning equipped weapons? Update the markers and remove 2hd weapon markers
        local equipControlName = equipmentControl:GetName()
        if equipControlName ~= nil and equipControlName ~= "" then
--d("[FCOIS.RefreshEquipmentControl] name: " ..tostring(equipControlName))
            if checkVars.allowedCharacterEquipmentWeaponControlNames[equipControlName] then
                --Check if the offhand weapons are 2hd weapons and remove the markers then
                FCOIS.RemoveEmptyWeaponEquipmentMarkers(1200)
            end

            --Is the equipment slot a ring? Then check if the same ring is equipped at the other slot and mark/demark it too
            local isRing = (p_markId ~= nil and not dontCheckRings and checkVars.allowedCharacterEquipmentJewelryRingControlNames[equipControlName]) or false
            if isRing then
                local bag, slot = FCOIS.MyGetItemDetails(equipmentControl)
                if bag == nil or slot == nil then return false end
                local itemId = FCOIS.MyGetItemInstanceIdNoControl(bag, slot, true)
                local doHide = not FCOIS.checkIfItemIsProtected(p_markId, itemId)
                if itemId == nil then return false end
                --Get the other ring
                local mappingOfRings = FCOIS.mappingVars.equipmentJewelryRing2RingSlot
                local otherRingSlotName = mappingOfRings[equipControlName]
                local otherRingControl = WINDOW_MANAGER:GetControlByName(otherRingSlotName, "")
                --Compare the item Ids/Unique itemIds (if enabled)
                if otherRingControl ~= nil then
                    --Get the bag and slot
                    local bagRing2, slotRing2 = FCOIS.MyGetItemDetails(otherRingControl)
                    if bagRing2 ~= nil and slotRing2 ~= nil then
                        --Get the itemId and compare it with the other ring
                        local itemIdOtherRing = FCOIS.MyGetItemInstanceIdNoControl(bagRing2, slotRing2, true)
                        if itemId == itemIdOtherRing then
                            local doMarkRing = not doHide
                            FCOIS.MarkItem(bagRing2, slotRing2, p_markId, doMarkRing, false)
                            --Update the texture, create it if not there yet
                            --!!!ATTENTION!!! Recursive call of function, so set last parameter "dontCheckRings" = true to prevent endless loop between ring1 and ring2 and ring1 and ...!
                            FCOIS.RefreshEquipmentControl(otherRingControl, true, p_markId, true)
                        end
                    end
                end
            end
        end

    --Equipment control is not given yet, or unknown
    else
        if settings.debug then FCOIS.debugMessage( "[FCOIS.RefreshEquipmentControl] ALL CONTROLS! Create: " .. tostring(doCreateMarkerControl) .. ", MarkId: " .. tostring(p_markId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        --Reset the armor type counters
        FCOIS.countVars.countLightArmor		= 0
        FCOIS.countVars.countMediumArmor	= 0
        FCOIS.countVars.countHeavyArmor		= 0

        --Check all equipment controls
        local equipmentSlotControl
        for _, equipmentSlotName in pairs(FCOIS.mappingVars.characterEquipmentSlotNameByIndex) do
            --Get the control of the equipment slot
            equipmentSlotControl = WINDOW_MANAGER:GetControlByName(equipmentSlotName, "")
            if equipmentSlotControl ~= nil then
                --Refresh each equipped item's marker icons
                FCOIS.RefreshEquipmentControl(equipmentSlotControl, doCreateMarkerControl, p_markId)
                --Show the armor type icons at the player doll?
                AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, FCOIS.GetArmorType(equipmentSlotControl))
            end
        end

        --Update the equipment header text and show the amount of armor types equipped
        updateEquipmentHeaderCountText()
    end
end

--Update one specific equipment slot by help of the slotIndex
function FCOIS.updateEquipmentSlotMarker(slotIndex, delay)
    local ctrlVars = FCOIS.ZOControlVars
    --Only execute if character window is shown
    if (not ctrlVars.CHARACTER:IsHidden() and slotIndex ~= nil) then
        local mappingVars = FCOIS.mappingVars
        delay = delay or 0
        if delay > 0 then
            zo_callLater(function()
                FCOIS.updateEquipmentSlotMarker(slotIndex, 0)
            end, delay)
        else
            --Get the equipment control by help of the slotIndex
            local equipSlotControlName = mappingVars.characterEquipmentSlotNameByIndex[slotIndex]
            local equipSlotControl
            if equipSlotControlName ~= nil and equipSlotControlName ~= "" then
                if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.updateEquipmentSlotMarker] control name="..equipSlotControlName..", slotIndex: " .. slotIndex, true, FCOIS_DEBUG_DEPTH_NORMAL) end
                equipSlotControl = WINDOW_MANAGER:GetControlByName(equipSlotControlName, "")
            end
            if equipSlotControl ~= nil then
                --Add or refresh the equipped items, create marker control if not already there
                FCOIS.RefreshEquipmentControl(equipSlotControl, true)
                --Check if the equipment slot control is an armor control
                if mappingVars.characterEquipmentArmorSlots[equipSlotControl:GetName()] then
                    --Count the now equipped armor types and update the text at the character window armor header text
                    FCOIS.countAndUpdateEquippedArmorTypes()
                end
            end
        end
    end
end

--The callback function for the right click/context menus to mark all equipment items with one click
function FCOIS.MarkAllEquipment(rowControl, markId, updateNow, doHide)
    if FCOIS.gFilterWhere == nil then return end
    --Set the last used filter Id
    FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] = FCOIS.mappingVars.iconToFilter[markId]

    local equipmentControl
    local equipmentSlotName
    local dontChange
    local itemId
    local settings = FCOIS.settingsVars.settings
    local checkVars = FCOIS.checkVars
    local ctrlVars = FCOIS.ZOControlVars

    --Get each equipped item
    for i=1, ctrlVars.CHARACTER:GetNumChildren() do
        dontChange = false
        equipmentSlotName = ctrlVars.CHARACTER:GetChild(i):GetName()
--d("[FCOIS.MarkAllEquipment]equipmentSlotName: " ..tostring(equipmentSlotName))
        if settings.debug then FCOIS.debugMessage( "[FCOIS.MarkAllEquipment] MarkId: " .. tostring(markId) .. ", EquipmentSlot: "..equipmentSlotName..", no_auto_mark: " .. tostring(checkVars.equipmentSlotsNames["no_auto_mark"][equipmentSlotName])) end
        --Is the current equipment slot a changeable one?
        if(string.find(equipmentSlotName, ctrlVars.equipmentSlotsName)) then
            --Only mark weapons too if enabled in settings
            if ( (settings.autoMarkAllWeapon == false and checkVars.allowedCharacterEquipmentWeaponControlNames[equipmentSlotName] == true)
                    --Only mark jewelry too if enabled in settings
                    or (settings.autoMarkAllJewelry == false and checkVars.allowedCharacterEquipmentJewelryControlNames[equipmentSlotName] == true) ) then
                dontChange = true
            end
            --Still need to change the texture and un-/mark item?
            if dontChange == false then
                dontChange = checkVars.equipmentSlotsNames["no_auto_mark"][equipmentSlotName] or false
            end
            --Are we allowed to change the marker?
            if (dontChange == false) then
                --get the control of the current equipment slot
                equipmentControl = ctrlVars.CHARACTER:GetChild(i)
                if (equipmentControl ~= nil) then
                    --get the itemid
                    local bag, slot = FCOIS.MyGetItemDetails(equipmentControl)
                    if markId ~= nil and bag ~= nil and slot ~= nil then
                        itemId = FCOIS.MyGetItemInstanceIdNoControl(bag, slot, true)
                        if doHide == true then
                            --FCOIS.markedItems[markId][itemId] = nil
                            FCOIS.MarkItem(bag, slot, markId, false, false)
                        else
                            --FCOIS.markedItems[markId][itemId] = true
                            FCOIS.MarkItem(bag, slot, markId, true, false)
                        end
                        --Update the texture, create it if not there yet
                        FCOIS.RefreshEquipmentControl(equipmentControl, true, markId)
                    end
                end
            end
        end
    end
    --if (updateNow == true) then
    --FCOIS.FilterBasics(false)
    --end
end

-- Check the weapon type
local function checkWeaponType(p_weaponType, p_check)
    if (p_check == nil or p_check == '') then
        p_check = '1hd'
    end
    if (p_weaponType ~= nil) then
        local checkVarsWeaponType = FCOIS.checkVars
        if checkVarsWeaponType[p_check] and checkVarsWeaponType[p_check][p_weaponType] then
            return true
        end
    end
    return false
end

--Check if the current equipment slot is the offhand or backup offhand slot
function FCOIS.checkWeaponOffHand(controlName, weaponTypeName, doCheckOffHand, doCheckBackupOffHand, echo)
    if echo then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.checkWeaponOffHand] ControlName: " .. controlName ..", WeaponTypeName: " .. weaponTypeName, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end
    local weaponControl
    local weaponType
    local characterEquipmentSlotNameByIndex = FCOIS.mappingVars.characterEquipmentSlotNameByIndex

    --Check the offhand?
    if doCheckOffHand == true then
        if (controlName == characterEquipmentSlotNameByIndex[5]) then -- 'ZO_CharacterEquipmentSlotsOffHand'
            --Check if the weapon in the main slot is a 2hd weapon/staff
            weaponControl = WINDOW_MANAGER:GetControlByName(characterEquipmentSlotNameByIndex[4], "") --"ZO_CharacterEquipmentSlotsMainHand"
            if (weaponControl ~= nil) then
                weaponType = GetItemWeaponType(weaponControl.bagId, weaponControl.slotIndex)
                if (weaponType ~= nil) then
                    return checkWeaponType(weaponType, weaponTypeName)
                end
            end
        end
    end

    --Check the backup offhand?
    if doCheckBackupOffHand == true then
        if (controlName == characterEquipmentSlotNameByIndex[21]) then -- 'ZO_CharacterEquipmentSlotsBackupOff'
            --Check if the weapon in the backup slot is a 2hd weapon/staff
            weaponControl = WINDOW_MANAGER:GetControlByName(characterEquipmentSlotNameByIndex[20], "") -- "ZO_CharacterEquipmentSlotsBackupMain"
            if (weaponControl ~= nil) then
                weaponType = GetItemWeaponType(weaponControl.bagId, weaponControl.slotIndex)
                if (weaponType ~= nil) then
                    return checkWeaponType(weaponType, weaponTypeName)
                end
            end
        end
    end

    return false
end