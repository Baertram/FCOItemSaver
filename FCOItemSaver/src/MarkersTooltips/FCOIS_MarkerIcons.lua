--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local gAddonName = FCOIS.addonVars.gAddonName

local debugMessage = FCOIS.debugMessage

local wm = WINDOW_MANAGER
local tos = tostring

local gil = GetItemLink
local zosgdtt = ZO_ScrollList_GetDataTypeTable

local strfind = string.find

local addonVars = FCOIS.addonVars
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local ctrlVars = FCOIS.ZOControlVars
local mappingVars = FCOIS.mappingVars
local otherAddons = FCOIS.otherAddons

local checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
local myGetItemDetails = FCOIS.MyGetItemDetails
local isItemProtectedAtASlotNow = FCOIS.IsItemProtectedAtASlotNow
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local myGetItemInstanceId = FCOIS.MyGetItemInstanceId
local filterBasics = FCOIS.FilterBasics
local isCharacterShown = FCOIS.IsCharacterShown
local isCompanionCharacterShown = FCOIS.IsCompanionCharacterShown
local isStableSceneShown = FCOIS.IsStableSceneShown
local isItemAlreadyBound = FCOIS.IsItemAlreadyBound
local getItemSaverControl = FCOIS.GetItemSaverControl
local createToolTip = FCOIS.CreateToolTip
local isModifierKeyPressed = FCOIS.IsModifierKeyPressed

local clearOrRestoreAllMarkers
local refreshEquipmentControl

local isMarked
local isMarkedByItemInstanceId
local markItemByItemInstanceId
local markItem
local checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate
local getArmorType = FCOIS.GetArmorType

local checkIfCompanionInteractedAndCompanionInventoryIsShown = FCOIS.CheckIfCompanionInteractedAndCompanionInventoryIsShown

--Prevent duplicate SecurePostHooks added to the scrollList setupCallback functions #303
local onScrollListRowSetupCallback = FCOIS.onScrollListRowSetupCallback
--local inventoriesSecurePostHooksDone = FCOIS.inventoriesSecurePostHooksDone
local addInventorySecurePostHookDoneEntry = FCOIS.addInventorySecurePostHookDoneEntry
local checkIfInventorySecurePostHookWasDone = FCOIS.checkIfInventorySecurePostHookWasDone

local isIIFAActive
local checkAndGetIIfAData

--ItemCooldownTracker
local icdt = ICDT
local checkIfItemCooldownTrackerRelevantItemIdAndMarkItem = FCOIS.CheckIfItemCooldownTrackerRelevantItemIdAndMarkItem

--LibSets --#301
local libSets = FCOIS.libSets
--local applyLibSetsSetSearchFavoriteCategoryMarker = FCOIS.ApplyLibSetsSetSearchFavoriteCategoryMarker --#301


-- =====================================================================================================================
--  Other AddOns helper functions
-- =====================================================================================================================

-- GRID LIST: https://www.esoui.com/downloads/info2341-GridList.html ---
--Get the GridList inventoryList
local GridList_MODE_LIST, GridList_MODE_GRID = 1, 3
local function GridList_GetMode(inventoryType)
    if not inventoryType then return nil end
    if not GridList or not GridList.GetList then return end
    local control = GridList.GetList(inventoryType)
    if not control then return nil end
    local mode = control.mode
    return mode
end

local function GridList_IsSupportedInventory(inventoryType)
    if not inventoryType then return nil end
    if not GridList then return end
    local list = GridList.List
    if not list then return end
    for _, invToCompare in ipairs(list) do
        if invToCompare == inventoryType then return true  end
    end
    return false
end


-- =====================================================================================================================
--  Marker icon helper functions
-- =====================================================================================================================

-- =====================================================================================================================
--  Marker control / textures functions
-- =====================================================================================================================

--Get the drawlevel of a markerIconId
local function getMarkerIconDrawLevel(p_markerIconId)
    if p_markerIconId == nil or p_markerIconId <= 0 or p_markerIconId > numFilterIcons then return 1 end
    local drawLevel = 0
    local markerIconsOutputOrder = FCOIS.settingsVars.settings.markerIconsOutputOrder
    --Loop the setup marker icons output order from bottom to top, check if the markerIconId is the
    --passed in one. For each markerIconId increase the drawLevel by 1
    for i=#markerIconsOutputOrder, 1, -1 do
        drawLevel = drawLevel + 1
        if p_markerIconId == markerIconsOutputOrder[i] then
--d("[FCOIS]getMarkerIconDrawLevel-markerId: " ..tos(p_markerIconId) .. "; drawLevel: " ..tos(drawLevel))
            return drawLevel
        end
    end
    return 1 --default drawLevel -> Fallback
end



--Update marker icons for other addons that should add marker icons to inventory items
local function updateOtherAddonsInventoryMarkers(parent, bagId, slotIndex)
    --FCOIS v2.2.4 - ItemCooldownTracker
    if icdt ~= nil then
        if bagId == nil or slotIndex == nil then
            bagId, slotIndex = myGetItemDetails(parent)
        end
        if bagId == nil or slotIndex == nil then return end
        checkIfItemCooldownTrackerRelevantItemIdAndMarkItem(bagId, slotIndex, nil)
    end
end

--Update the "already bound set part" icon at the item's top right image edge
local function updateAlreadyBoundTexture(parent, pHideControl)
    if parent == nil then return end
    pHideControl = pHideControl or false
    --Hide the control if settings are disabled or the function parameter tells it to do so
    --Is the item a non-bound item? en hide it!
    local doHide
    local bagId, slotIndex
    if pHideControl then
        doHide = true
    else
        local showBoundItemMarker = FCOIS.settingsVars.settings.showBoundItemMarker
        doHide = not showBoundItemMarker
        if not doHide then
            --Get the bagId and slotIndex
            bagId, slotIndex = myGetItemDetails(parent)
            if bagId == nil or slotIndex == nil then return end
            doHide = not isItemAlreadyBound(bagId, slotIndex)
        end
    end

    local InventoryGridViewActivated = (otherAddons.inventoryGridViewActive or InventoryGridView ~= nil) or false
    local GridListActivated          = GridList ~= nil

    --If not an equipped item: Get the row's/parent's image -> "Children "Button" of parent
    local parentsImage = parent:GetNamedChild("Button")
    if parentsImage ~= nil then
        --d("parentsImage: " .. parentsImage:GetName())
        local alreadyBoundTexture = "esoui/art/ava/avacapturebar_point_aldmeri.dds"
        local addonName = gAddonName
        local setPartAlreadyBoundName = parent:GetName() .. addonName .. "AlreadyBoundIcon"
        if alreadyBoundTexture ~= nil then
            local setPartAlreadyBoundTexture
            setPartAlreadyBoundTexture = GetControl(setPartAlreadyBoundName) --wm:GetControlByName(setPartAlreadyBoundName, "")
            if setPartAlreadyBoundTexture == nil then
                setPartAlreadyBoundTexture = wm:CreateControl(setPartAlreadyBoundName, parentsImage, CT_TEXTURE)
            end
            if setPartAlreadyBoundTexture ~= nil then
                --d(">texture created")
                --Hide or show the control now
                setPartAlreadyBoundTexture:SetHidden(doHide)
                if not doHide then
                    setPartAlreadyBoundTexture:SetTexture(alreadyBoundTexture)
                    --setPartAlreadyBoundTexture:SetColor(1, 1, 1, 1)
                    setPartAlreadyBoundTexture:SetDrawTier(DT_HIGH)
                    setPartAlreadyBoundTexture:ClearAnchors()

                    local gridIsEnabled = false
                    if InventoryGridViewActivated == true or GridListActivated == true then
                        if InventoryGridViewActivated == true then
                            gridIsEnabled = true
                        else
                            --Only if GridList active: Check if it's GridMode is currently showing the grid or not
                            if GridListActivated == true then
                                --Is the GridList "GRID" view enabled?
                                local filterPanelId = FCOIS.gFilterWhere
                                --Is the FCOIS LAM settings menu curerntly open and we show the preview of the inventory?
                                if FCOIS.preventerVars.lamMenuOpenAndShowingInvPreviewForGridListAddon == true then
                                    filterPanelId = LF_INVENTORY
                                end
                                if filterPanelId then
                                    local inventoryType = FCOIS.GetInventoryTypeByFilterPanel(filterPanelId)
                                    if inventoryType ~= nil then
                                        --Is the inventory type a supported GridList inventory type?
                                        local isSupportedGridListInv = GridList_IsSupportedInventory(inventoryType)
                                        if isSupportedGridListInv == true then
                                            local gridViewModeOfInventoryType = GridList_GetMode(inventoryType)
                                            if gridViewModeOfInventoryType and gridViewModeOfInventoryType == GridList_MODE_GRID then
                                                --GridList grid is enabled
                                                gridIsEnabled = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    --The grid of one the grid addons is currently enabled?
                    if gridIsEnabled == true then
                        local offsetX = 0
                        local offsetY = 0
                        local dimensions = 48
                        local parentAnchor = parent
                        if GridListActivated == true then
                            dimensions = 96
                            parentAnchor = GetControl(parent, "Backdrop")
                            offsetX = -62
                            offsetY = -16
                        elseif InventoryGridViewActivated == true then
                            dimensions = 64
                            parentAnchor = GetControl(parent, "Backdrop")
                            offsetX = -44
                            offsetY = -14
                        end
                        setPartAlreadyBoundTexture:SetDimensions(dimensions, dimensions)
                        setPartAlreadyBoundTexture:SetAnchor(TOPLEFT, parentAnchor, TOPLEFT, offsetX, offsetY)
                    else
                        setPartAlreadyBoundTexture:SetDimensions(48, 48)
                        setPartAlreadyBoundTexture:SetAnchor(TOPLEFT, parentsImage, TOPRIGHT, -25, -8)
                    end
                end
            end
        end
    end
    return bagId, slotIndex
end

local function resetCharacterArmorTypeNumbers()
    --Reset the armor type counters
    FCOIS.countVars.countLightArmor		= 0
    FCOIS.countVars.countMediumArmor	= 0
    FCOIS.countVars.countHeavyArmor		= 0
    --Companion
    FCOIS.countVars.countCompanionLightArmor	= 0
    FCOIS.countVars.countCompanionMediumArmor	= 0
    FCOIS.countVars.countCompanionHeavyArmor	= 0
end


--Create the marker controls, holding the icon textures
--Will be created/updated as inventories get updated row by row (scrolling) -> by the help of function "CreateTextures()"
--Will also add/show/hide the small "is the set item already bound" icon at the top-right edge of the item's image (children "Button" of parent)
-->Only adds the texture if it does not already exist and if the marker icon is enabled!
--->If pCreateControlIfNotThere == false: If a texture control is enabled and should be shown it will be created either way, else it would make no sense!
function FCOIS.CreateMarkerControl(parent, markerIconId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped, pDrawLevel, pIsIconEnabled)
--d("[FCOIS]CreateMarkerControl: " .. tos(parent:GetName()) .. ", markerIconId: " ..tos(markerIconId) .. ", pHideControl: " ..tos(pHideControl) ..", pUnequipped: " ..tos(pUnequipped))
    --No parent? Abort here
    if parent == nil then return nil end
    pArmorTypeIcon = pArmorTypeIcon or false
    pHideControl = pHideControl or false

    local InventoryGridViewActivated = (otherAddons.inventoryGridViewActive or InventoryGridView ~= nil) or false
    local GridListActivated          = GridList ~= nil

    --Preset the variable for control creation with false, if it is not given
    pCreateControlIfNotThere	= pCreateControlIfNotThere or false
    pUpdateAllEquipmentTooltips	= pUpdateAllEquipmentTooltips or false

    --Is the parent's owner control not the quickslot circle?
    if parent:GetOwningWindow() ~= ctrlVars.QUICKSLOT_CIRCLE then
        if pIsEquipmentSlot == nil then pIsEquipmentSlot = false end

        local settings = FCOIS.settingsVars.settings
        if pIsIconEnabled == nil then pIsIconEnabled = settings.isIconEnabled[markerIconId] end

        --Hide the control explicitly or hide it because the marker icon is not enabled?
        local doHide = pHideControl == true or not pIsIconEnabled

        --Does the FCOItemSaver marker control exist already?
        local control = getItemSaverControl(parent, markerIconId, false, nil)

        --Item got unequipped? Hide all marker textures of the unequipped item
        if pIsEquipmentSlot == true and pUnequipped ~= nil and pUnequipped == true then
            --d(">hide: true -> equipment slot got unequipped")
            doHide = true
        end

        --Should the control not be hidden? Then check it's marker settings and if a marker is set
        if not doHide then
            --Marker control for a disabled icon? Hide the icon then
            if not pIsIconEnabled then
                if control ~= nil then control:SetHidden(true) end --#281
                --Abort here now as markerIcon is disabled
                return false
            else
                --Marker icon is enabled: Control should be shown, so check if the current item go that marker icon applied
                local isItemProtected = checkIfItemIsProtected(markerIconId, myGetItemInstanceId(parent))
                doHide = not isItemProtected
                --d(">>checkIfItemIsProtected result: " .. tos(isItemProtected) .. ", doHide: " ..tos(doHide))
            end
        end
        if doHide == nil then doHide = false end

        --Remove the sell icon and price if Inventory Grid View or Grid List addons are active
        if parent:GetWidth() - parent:GetHeight() < 5 then
            if parent:GetNamedChild("SellPrice") then
                parent:GetNamedChild("SellPrice"):SetHidden(true)
            end
        end

        --It does not exist yet, or it fall-back to the parent control?
        if control == parent or control == nil then
            --Abort here if control should be hiden and is not created yet
            if doHide == true and pCreateControlIfNotThere == false then
                ZO_Tooltips_HideTextTooltip()
                return
            end

            --If not aborted: Create the marker control now
            --#281 -v-
            -->Only do this if pCreateControlIfNotThere == true (explicitly asking to create the texture control)
            -->or the markerIcon is actually enabled
            -->and the marker icon is applied to the current item -> and thus shold be visually shown
            if (pCreateControlIfNotThere == true or pIsIconEnabled == true) and not doHide then
            --#281 -^-
                control = wm:CreateControl(parent:GetName() .. gAddonName .. tos(markerIconId), parent, CT_TEXTURE)
            end --#281
        end

        --Control did already exist or was created now
        if control ~= nil then
            --Hide or show the control now
            control:SetHidden(doHide)

            --Control should be shown?
            if not doHide then
                local iconSettings = settings.icon[markerIconId]

                --DrawLevel was passed in? Else try to detect it from settings
                if pDrawLevel == nil then
                    --Get the marker Icons drawLevel via settings.markerIconsOutputOrder table etc. -> see function addMarkerIconsToControl
                    pDrawLevel = getMarkerIconDrawLevel(markerIconId) --#278
--                else
--                    if markerIconId == 1 or markerIconId == 3 then
--d("[FCOIS]CreateMarkerControl-markerId: " ..tos(iconSettings.name) .. " /" ..tos(markerIconId) .. "; drawLevel: " ..tos(pDrawLevel))
--                    end
                end

                control:SetTexture(pTexture)
                local iconSettingsColor = iconSettings.color
                control:SetColor(iconSettingsColor.r, iconSettingsColor.g, iconSettingsColor.b, iconSettingsColor.a)
                --Marker was created/updated for the character equipment slots?
                local gridIsEnabled = false
                if pIsEquipmentSlot == true then
                    control:ClearAnchors()
                    control:SetDimensions(pWidth, pHeight)
                    --Move the marker controls of equipment slots according to settings
                    --control:SetAnchor(BOTTOMLEFT, parent, BOTTOMLEFT, -6, 5)
                    local iconPositionCharacter = settings.iconPositionCharacter
                    control:SetAnchor(BOTTOMLEFT, parent, BOTTOMLEFT, iconPositionCharacter.x, iconPositionCharacter.y)
                    control:SetDrawLayer(DL_BACKGROUND)
                    control:SetDrawTier(DT_HIGH)
                    control:SetDrawLevel(pDrawLevel)
                else
                    control:ClearAnchors()
                    control:SetDrawLayer(DL_BACKGROUND)
                    control:SetDrawTier(DT_HIGH)
                    control:SetDrawLevel(pDrawLevel)

                    --Is one of the grid addons enabled?
                    local gridListOffSetLeft
                    local gridListOffSetTop
                    if InventoryGridViewActivated == true or GridListActivated == true then
                        if InventoryGridViewActivated == true then
                            gridIsEnabled = true
                        else
                            --Only if GridList active: Check if it's GridMode is currently showing the grid or not
                            if GridListActivated == true then
                                --Is the GridList "GRID" view enabled?
                                local filterPanelId = FCOIS.gFilterWhere
                                --Is the FCOIS LAM settings menu curerntly open and we show the preview of the inventory?
                                if FCOIS.preventerVars.lamMenuOpenAndShowingInvPreviewForGridListAddon == true then
                                    filterPanelId = LF_INVENTORY
                                end
                                if filterPanelId then
                                    local inventoryType = FCOIS.GetInventoryTypeByFilterPanel(filterPanelId)
                                    if inventoryType ~= nil then
                                        --Is the inventory type a supported GridList inventory type?
                                        local isSupportedGridListInv = GridList_IsSupportedInventory(inventoryType)
                                        if isSupportedGridListInv == true then
                                            local gridViewModeOfInventoryType = GridList_GetMode(inventoryType)
                                            if gridViewModeOfInventoryType and gridViewModeOfInventoryType == GridList_MODE_GRID then
                                                --GridList grid is enabled
                                                gridIsEnabled = true
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    --The grid of one the grid addons is currently enabled?
                    if gridIsEnabled == true then
                        gridListOffSetLeft = settings.markerIconOffset["GridList"].x
                        gridListOffSetTop = settings.markerIconOffset["GridList"].y
                        local scale = settings.markerIconOffset["GridList"].scale
                        if scale <= 0 then scale = 1 end
                        if scale > 100 then scale = 100 end
                        if pWidth > 0 and pHeight > 0 then
                            local newWidth = (pWidth / 100) * scale
                            local newHeight = (pHeight / 100) * scale
                            if scale == 100 or (newWidth ~= pWidth or newHeight ~= pHeight) then
                                control:SetDimensions(newWidth, newHeight)
                            end
                        end
                        control:SetAnchor(CENTER, parent, BOTTOMLEFT, gridListOffSetLeft, gridListOffSetTop)
                    else
                        --Normal icons without InventoryGridView or GridList grid
                        control:SetDimensions(pWidth, pHeight)
                        --Get the currently active filter panel ID and map the appropriate inventory for the icon X axis offset
                        local filterPanelIdToIconOffset = mappingVars.filterPanelIdToIconOffset
                        local iconPosition = settings.iconPosition
                        local iconOffset = filterPanelIdToIconOffset[FCOIS.gFilterWhere] or iconPosition
                        --get the offsets defined at the filterPanel for each icon (and defiend at the icon itsself for the inventory row)
                        local iconOffsetDefinedAtPanel = iconSettings.offsets[LF_INVENTORY]
                        --Now add the iconOffset defined at each panel
                        local totalOffSetLeft = iconOffset.x + iconOffsetDefinedAtPanel.left
                        local totalOffSetTop = iconOffset.y + iconOffsetDefinedAtPanel.top
                        control:SetAnchor(LEFT, parent, LEFT, totalOffSetLeft, totalOffSetTop)
                    end

                    --Add the OnMouseDown event handler to open the context menu of the inventory if right clicking on a texture control
                    if control:GetHandler("OnMouseUp") == nil then
                        control:SetHandler("OnMouseUp", function(self, mouseButton, upInside, ctrlKey, altKey, shiftKey, ...)
                            if mouseButton == MOUSE_BUTTON_INDEX_RIGHT and upInside then
                                local invRow = self:GetParent()
                                if invRow ~= nil then
                                    local onMouseUpHandler = invRow:GetHandler("OnMouseUp")
                                    if onMouseUpHandler ~= nil then
                                        onMouseUpHandler(invRow, mouseButton, upInside, ctrlKey, altKey, shiftKey, ...)
                                    end
                                end
                            end
                        end, addonVars.gAddonName)
                    end
                end
            end  -- if not doHide then
            --Set the tooltip if wished
            createToolTip(control, markerIconId, doHide, pUpdateAllEquipmentTooltips, pIsEquipmentSlot, nil, nil)
            return control
        else
            return nil
        end
    else
        --Quickslot Circle
        return nil
    end
end
local createMarkerControl = FCOIS.CreateMarkerControl


local function addMarkerIconsToControl(rowControl, pDoCreateMarkerControl, pIsEquipmentSlot, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped)
    if rowControl == nil then return end
    pDoCreateMarkerControl = pDoCreateMarkerControl or false
    pIsEquipmentSlot = pIsEquipmentSlot or false

    local settings = FCOIS.settingsVars.settings
    local iconSettings = settings.icon
    local iconVars = FCOIS.iconVars
    local equipVars = FCOIS.equipmentVars
    local markerTextureVars = FCOIS.textureVars.MARKER_TEXTURES
    local isIconEnabled = settings.isIconEnabled
    local iconSizeForCharacterPanel = settings.iconSizeCharacter

    -- for all filters: Create/Update the icons
    --> ZO ScrollList rows
    --[[
    for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        local iconSettingsOfMarkerIcon = iconSettings[i]
        createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
    end
    ]]

    --[[
    From FCOIS_Hooks.lua, function onScrollListRowSetupCallback(rowControl, data)
        local settings            = FCOIS.settingsVars.settings
        local iconSettings        = settings.icon
        local iconVars            = FCOIS.iconVars
        local textureVars         = FCOIS.textureVars

        for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            local iconData = iconSettings[i]
            createMarkerControl(rowControl, i, iconData.size or iconVars.gIconWidth, iconData.size or iconVars.gIconWidth, textureVars.MARKER_TEXTURES[iconData.texture])
        end
    ]]

    --[[ From FCOIS_MarkerIcons.lua, function FCOIS.RemoveEmptyWeaponEquipmentMarkers(delay)
        --Remove the markers for the filter icons at the equipment slot
        local width = settings.iconSizeCharacter or equipVars.gEquipmentIconWidth
        local height = settings.iconSizeCharacter or equipVars.gEquipmentIconHeight
        for markerIconId=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            --3rd last parameter = doHide (true)
            createMarkerControl(equipmentControl, markerIconId, width, height, texVars.MARKER_TEXTURES[settings.icon[markerIconId].texture], true, false, false, false, true, nil, nil)
        end
    ]]

    --[[
    From FCOIS_Hooks.lua, local function smithingResearchListDialogSetupCallback(rowControl, slot)
        local iconVars            = FCOIS.iconVars
        local textureVars         = FCOIS.textureVars

        -- Create/Update all the icons for the current dialog row
        for iconNumb = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            local iconData = settings.icon[iconNumb]
            FCOIS.CreateMarkerControl(rowControl, iconNumb, iconData.size or iconVars.gIconWidth, iconData.size or iconVars.gIconWidth, textureVars.MARKER_TEXTURES[iconData.texture])
        end -- for i = 1, numFilterIcons, 1 do
    ]]

    --#278 Add on request: OrderListBox widget to control order of the marker icons created -> DrawLevel
    --20240328 read settings order of the marker icons output (LibAddonMenuOrderListBox), and then add the icons in that order
    local markerIconsOutputOrder = settings.markerIconsOutputOrder
    --From last to first icon order -> So that last icon will be created first, and then 2nd last overlays it, and so on until 1st icon is created on top
    local drawLevel = 0
    for i=#markerIconsOutputOrder, 1, -1 do
        drawLevel = drawLevel + 1
        local markerIconId = markerIconsOutputOrder[i]
        local iconSettingsOfMarkerIcon = iconSettings[markerIconId]

        local iconWidth, iconHeight
        if pIsEquipmentSlot == true then
            iconWidth = iconSizeForCharacterPanel or equipVars.gEquipmentIconWidth
            iconHeight = iconSizeForCharacterPanel or equipVars.gEquipmentIconHeight
        else
            local iconSize = iconSettingsOfMarkerIcon.size
            iconWidth = iconSize or iconVars.gIconWidth
            iconHeight = iconSize or iconVars.gIconHeight
        end

        --d(">createMarkerIcon at pos #" ..tos(idx) .. ": " ..tos(markerIconId) .. " - " .. tos(iconSettingsOfMarkerIcon.name))
        --createMarkerControl(parent, markerIconId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped, pDrawLevel)
        createMarkerControl(rowControl, markerIconId, iconWidth, iconHeight, markerTextureVars[iconSettingsOfMarkerIcon.texture], pIsEquipmentSlot, pDoCreateMarkerControl, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped, drawLevel, isIconEnabled[markerIconId])
    end
end
FCOIS.AddMarkerIconsToControl = addMarkerIconsToControl


local function addMarkerIconsToZOListViewNow(rowControl, slot, doCreateMarkerControl, libFiltersFilterTypeToUse, updateAlreadyBound, updateOtherAddonsInvMarkers)
    --Do not execute if horse is changed
    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    if not isStableSceneShown() then
        --d("[FCOIS]addMarkerIconsToZOLitsViewNow - setupCallback")
        updateAlreadyBound = updateAlreadyBound or false
        updateOtherAddonsInvMarkers = updateOtherAddonsInvMarkers or false

        --Change FCOIS.gFilterWhere upon drag&drop of items, or upon OnMouse* functions?
        -->e.g. at the companion inventory
        if libFiltersFilterTypeToUse ~= nil then
            if type(libFiltersFilterTypeToUse) == "function" then
                local filterPanelIdNew = libFiltersFilterTypeToUse()
                if filterPanelIdNew ~= nil then
                    FCOIS.gFilterWhere = filterPanelIdNew
                end
            else
                FCOIS.gFilterWhere = libFiltersFilterTypeToUse
            end
        end

        local bagId, slotIndex

        --Add the marker icons to the control now
        --addMarkerIconsToControl(rowControl, pDoCreateMarkerControl, pIsEquipmentSlot, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped)
        addMarkerIconsToControl(rowControl, doCreateMarkerControl, false, nil, nil, nil, nil)

        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Create and show the "already bound" set parts texture at the top-right edge of the inventory item
        if updateAlreadyBound == true then
            bagId, slotIndex = updateAlreadyBoundTexture(rowControl)
        end

        --Update marker icons for other addons that should add marker icons to inventory items
        if updateOtherAddonsInvMarkers == true then
            bagId, slotIndex = updateOtherAddonsInventoryMarkers(rowControl, bagId, slotIndex)
        end

        --#301 FCOIS v2.6.1 LibSets set search favorite categories marker icons
        -->todo Is this really needed here as the marker icons are applied on FCOIS.ScanInventory too already?
        --[[
        if libSets ~= nil then
            if bagId == nil or slotIndex == nil then
                bagId, slotIndex = myGetItemDetails(parent)
            end
            if bagId == nil or slotIndex == nil then return end
            applyLibSetsSetSearchFavoriteCategoryMarker(rowControl, bagId, slotIndex, nil, nil, nil)
        end
        ]]
    end
end


--Create the textures inside inventories etc.
--The inventories of the crafting tables are build inside function /src/FCOIS_Hook.lua
--> See function OnScrollListRowSetupCallback(rowControl, data)
--> for e.g. SecurePostHook(ctrlVars.DECONSTRUCTION.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)
function FCOIS.CreateTextures(whichTextures)

    local doCreateMarkerControl = false
    local doCreateAllTextures = false

    if whichTextures == -1 then
        --Crate the texture controls for the marker icons?
        --If this is set to true each inventory row will automatically get 1 new texture control child for each marker icon
        --doCreateMarkerControl = true --Creating them "On demand" (if shown, at scrolling) shiuld be more performant
        doCreateAllTextures = true
    end
    --All inventories
    if (whichTextures == 1 or doCreateAllTextures) then
        --Create textures in inventories
        --for all PLAYER_INVENTORY.inventories do ...

        for _,v in pairs(ctrlVars.playerInventoryInvs) do
            local listView = v.listView
            --Do not hook quest items
            if (listView and listView.dataTypes and listView.dataTypes[1]
                and not checkIfInventorySecurePostHookWasDone(listView, listView.dataTypes[1]) --#303
                and (listView:GetName() ~= ctrlVars.INVENTORY_QUEST_NAME)) then

                --local hookedFunctions = listView.dataTypes[1].setupCallback
                --listView.dataTypes[1].setupCallback =
                SecurePostHook(zosgdtt(listView, 1), "setupCallback",
                        function(rowControl, slot)
                            --hookedFunctions(rowControl, slot)
                            addMarkerIconsToZOListViewNow(rowControl, slot, doCreateMarkerControl, nil, true, true)
                            onScrollListRowSetupCallback(rowControl, nil, true)

                            --[[
                            --Do not execute if horse is changed
                            --The current game's SCENE and name (used for determining bank/guild bank deposit)
                            if not isStableSceneShown() then
                                --d("[FCOIS]PlayerInventory.listView.dataTypes[1].setupCallback")
                                -- for all filters: Create/Update the icons
                                for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                                    local iconSettingsOfMarkerIcon = iconSettings[i]
                                    --createMarkerControl(parent, controlId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl)
                                    createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                                end
                                --Add additional FCO point to the dataEntry.data slot
                                --FCOItemSaver_AddInfoToData(rowControl)
                                --Create and show the "already bound" set parts texture at the top-right edge of the inventory item
                                updateAlreadyBoundTexture(rowControl)
                                --Update marker icons for other addons that should add marker icons to inventory items
                                updateOtherAddonsInventoryMarkers(rowControl)
                            end
                            ]]
                        end
                )
                addInventorySecurePostHookDoneEntry(listView, listView.dataTypes[1]) --#303
            end
        end
    end
     --Repair list
    if (whichTextures == 2 or doCreateAllTextures) then
        --Create textures in repair window
        local listView = ctrlVars.REPAIR_LIST
        if listView and listView.dataTypes and listView.dataTypes[1]
            and not checkIfInventorySecurePostHookWasDone(listView, listView.dataTypes[1]) then --#303
            --local hookedFunctions = listView.dataTypes[1].setupCallback

            --listView.dataTypes[1].setupCallback =
            SecurePostHook(zosgdtt(listView, 1), "setupCallback",
                    function(rowControl, slot)
                        --hookedFunctions(rowControl, slot)
                        addMarkerIconsToZOListViewNow(rowControl, slot, doCreateMarkerControl, nil, false, false)
                        onScrollListRowSetupCallback(rowControl, nil, true)

                        --[[
                        --Do not execute if horse is changed
                        --The current game's SCENE and name (used for determining bank/guild bank deposit)
                        if not isStableSceneShown() then
                            -- for all filters: Create/Update the icons
                            for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                                local iconSettingsOfMarkerIcon = iconSettings[i]
                                createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                            end
                            --Add additional FCO point to the dataEntry.data slot
                            --FCOItemSaver_AddInfoToData(rowControl)
                        end
                        ]]
                    end
            )
            addInventorySecurePostHookDoneEntry(listView, listView.dataTypes[1]) --#303
        end
    end
    --Player character / Companion character
    if (whichTextures == 3 or doCreateAllTextures) then
        -- Marker function for character equipment if character window is shown
        if ((isCharacterShown() or isCompanionCharacterShown()) or FCOIS.addonVars.gAddonLoaded == false) then
            refreshEquipmentControl = refreshEquipmentControl or FCOIS.RefreshEquipmentControl
            refreshEquipmentControl(nil, nil, nil, nil, true, nil)
        end
    end
    --Quickslot
    if (whichTextures == 4 or doCreateAllTextures) then
        -- Marker function for quickslots inventory
        local listView = ctrlVars.QUICKSLOT_LIST
        -->Quickslots get initilizaed on first open with OnDeferredInit now so maybe the list is not there properly yet! Check FCOIS.CreateHooks -> onDeferredInitCheck(ctrlVars.QUICKSLOT_KEYBOARD,
        if listView and listView.dataTypes and listView.dataTypes[1]
            and not checkIfInventorySecurePostHookWasDone(listView, listView.dataTypes[1]) then --#303
            --local hookedFunctions = listView.dataTypes[1].setupCallback

            --listView.dataTypes[1].setupCallback =
            SecurePostHook(zosgdtt(listView, 1), "setupCallback",
                    function(rowControl, slot)
                        --hookedFunctions(rowControl, slot)

                        addMarkerIconsToZOListViewNow(rowControl, slot, doCreateMarkerControl, nil, false, false)
                        onScrollListRowSetupCallback(rowControl, nil, true)

                        --[[
                        --Do not execute if horse is changed
                        --The current game's SCENE and name (used for determining bank/guild bank deposit)
                        if not isStableSceneShown() then
                            -- for all filters: Create/Update the icons
                            for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                                local iconSettingsOfMarkerIcon = iconSettings[i]
                                createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                            end
                            --Add additional FCO point to the dataEntry.data slot
                            --FCOItemSaver_AddInfoToData(rowControl)
                        end
                        ]]
                    end
            )
            addInventorySecurePostHookDoneEntry(listView, listView.dataTypes[1]) --#303
        end
    end
    --Transmuation
    if (whichTextures == 5 or doCreateAllTextures) then ---->FCOIS.CreateHooks() adds the onMouseUpHandlers
        --Create textures in repair window
        local listView = ctrlVars.RETRAIT_LIST
        if listView and listView.dataTypes and listView.dataTypes[1]
            and not checkIfInventorySecurePostHookWasDone(listView, listView.dataTypes[1]) then --#303
            --local hookedFunctions = listView.dataTypes[1].setupCallback

            --listView.dataTypes[1].setupCallback =
            SecurePostHook(zosgdtt(listView, 1), "setupCallback",
                    function(rowControl, slot)
                        --hookedFunctions(rowControl, slot)

                        addMarkerIconsToZOListViewNow(rowControl, slot, doCreateMarkerControl, nil, false, false)
                        onScrollListRowSetupCallback(rowControl, nil, true)
                        --[[
                        --Do not execute if horse is changed
                        --The current game's SCENE and name (used for determining bank/guild bank deposit)
                        if not isStableSceneShown() then
                            -- for all filters: Create/Update the icons
                            for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                                local iconSettingsOfMarkerIcon = iconSettings[i]
                                createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                            end
                            --Add additional FCO point to the dataEntry.data slot
                            --FCOItemSaver_AddInfoToData(rowControl)
                        end
                        ]]
                    end
            )
            addInventorySecurePostHookDoneEntry(listView, listView.dataTypes[1]) --#303
        end
    end
    --Companion inventory
    if (whichTextures == 6 or doCreateAllTextures) then
        -- Marker function for companion inventory
        local listView = ctrlVars.COMPANION_INV_LIST
        --ZO_CompanionEquipment_Panel_KeyboardList1Row1
        if listView and listView.dataTypes and listView.dataTypes[1]
            and not checkIfInventorySecurePostHookWasDone(listView, listView.dataTypes[1]) then --#303
            --local hookedFunctions = listView.dataTypes[1].setupCallback

            --listView.dataTypes[1].setupCallback =
            SecurePostHook(zosgdtt(listView, 1), "setupCallback",
                    function(rowControl, slot)
                        --hookedFunctions(rowControl, slot)

                        --At the companion inventory list: Add the LF_INVENTORY_COMPANION explicitly so that right click and drag&drop changes the
                        --value of FCOIS.gFilterWhere properly again
                        --Bug #236 (also maybe #178)
                        --Seems that the /EsoUI/Ingame/Companion/Keyboard/CompanionEquipment_Keyboard.lua companion inventory not only affects the companion's
                        --inventory as you interact with the companion BUT also all companion items in your normal inventory and bank deposits!
                        --So we need to do an additional check if the companion is currently interacted with and the companion menu is opened...

                        -- TODO OBSOLETE?: 20240604 Check if the below is still needed then
                        -->Attention: After right click/drag/drop (inventory slot locked) a re-evaluation needs to be done to assure that the
                        --            "real shown panel" is updated to FCOIS.gFilterWhere again. e.g. drag&drop any companion item at the
                        --            normal inventory (and trying to desroy it) will change FCOIS.gFilterWhere to LF_INVENTORY_COMPANION and
                        --            after that it needs to become LF_INVENTORY properly again!
                        --            Will be fixed now by preventing the companion

                        addMarkerIconsToZOListViewNow(rowControl, slot, doCreateMarkerControl, checkIfCompanionInteractedAndCompanionInventoryIsShown, false, false)
                        onScrollListRowSetupCallback(rowControl, nil, true)
                        --[[
                        --Do not execute if horse is changed
                        --The current game's SCENE and name (used for determining bank/guild bank deposit)
                        if not isStableSceneShown() then
                            --Workaround for the companion equipment inventory fragment's StateChange!
                            --The OnShowing will happen AFTER the inventory rows are updated. See file src/FCOIS_Hooks.lua,
                            --ctrlVars.COMPANION_INV_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                            --Thus the filterPanelId is still on LF_INVENTORY and some panel checks for the dynamic marker icons, but
                            --also the static ones, will be handled incorrectly! To circumvent this set the filterPanelId here each
                            --time the inventory rows are updated!
                            --This value will be reset via the companion keyboard fragment stateChange to hide or hidden
                            FCOIS.gFilterWhere = LF_INVENTORY_COMPANION

                            -- for all filters: Create/Update the icons
                            for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                                local iconSettingsOfMarkerIcon = iconSettings[i]
                                createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                            end
                            --Add additional FCO point to the dataEntry.data slot
                            --FCOItemSaver_AddInfoToData(rowControl)
                        end
                        ]]
                    end
            )
            addInventorySecurePostHookDoneEntry(listView, listView.dataTypes[1]) --#303
        end
    end
end

--Check if marker textures on the inventories row should be refreshed
function FCOIS.CheckMarker(markerId)
    markerId = markerId or -1
    local doDebug = FCOIS.settingsVars.settings.debug
    if doDebug then debugMessage( "[CheckMarker]","MarkerId: " .. tos(markerId) .. ", CheckNow: " .. tos(FCOIS.preventerVars.gUpdateMarkersNow) .. ", Gears changed: " .. tos(FCOIS.preventerVars.gChangedGears), true, FCOIS_DEBUG_DEPTH_ALL) end

    --Should we update the marker textures, size and color?
    if FCOIS.preventerVars.gUpdateMarkersNow == true or FCOIS.preventerVars.gChangedGears == true then
        --Update the textures now
        FCOIS.RefreshBasics()

        if not FCOIS.preventerVars.gChangedGears then
            zo_callLater(function()
                --d("character hidden: " .. tos(ctrlVars.CHARACTER:IsHidden()))
                if isCharacterShown() or isCompanionCharacterShown() then
                    refreshEquipmentControl = refreshEquipmentControl or FCOIS.RefreshEquipmentControl
                    refreshEquipmentControl()
                end
            end, 100)
        end
        --Set the global preventer variable back to false
        FCOIS.preventerVars.gUpdateMarkersNow = false
        FCOIS.preventerVars.gChangedGears	  = false
    end
end

--Check if the item got an entry in FCOIS.lastMarkedIcons (filled within file src/FCOIS_MarkerIcons.lua, function FCOIS.ClearOrRestoreAllMarkers...))
--and remove this entry now in order to be able to build a new entry properly via SHIFT + right mouse button
function FCOIS.CheckAndClearLastMarkedIcons(bagId, slotIndex)
    if not FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey then return false end
    if bagId == nil or slotIndex == nil then return false end
    local lastMarkedIcons = FCOIS.lastMarkedIcons
    --Is a restorable temporarily saved marker icon entry given in the table?
    if lastMarkedIcons ~= nil and lastMarkedIcons[bagId] ~= nil and lastMarkedIcons[bagId][slotIndex] ~= nil then
        --Delete it so it can be build new later on via SHIFT + right mouse button on an inventory row
        lastMarkedIcons[bagId][slotIndex] = nil
        FCOIS.lastMarkedIcons[bagId][slotIndex] = nil
    end
end

--Function to check if SHIFT+right mouse was used on an inventory row to clear/restore all the marker icons (from before -> undo table)
function FCOIS.CheckIfClearOrRestoreAllMarkers(clickedRow, modifierKeyPressed, upInside, mouseButton, refreshPopupDialogButons, calledByKeybind, calledByContextMenu, wasIIfARowClicked)
    calledByKeybind = calledByKeybind or false
    calledByContextMenu = calledByContextMenu or false
    wasIIfARowClicked = wasIIfARowClicked or false
    --Enable clearing all markers by help of the SHIFT+right click?
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
--d("[FCOIS.checkIfClearOrRestoreAllMarkers]shiftKey: " ..tos(IsShiftKeyDown()) .. ", upInside: " .. tos(upInside) .. ", mouseButton: " .. tos(mouseButton) .. ", settingEnabled: " ..tos(contextMenuClearMarkesByShiftKey) .. ", modifierKeyPressed: " ..tos(modifierKeyPressed) .. ", calledByKeybind: " ..tos(calledByKeybind) .. ", calledByContextMenu: " ..tos(calledByContextMenu) .. ", wasIIfARowClicked: " ..tos(wasIIfARowClicked))
    if ((calledByContextMenu == true
        or calledByKeybind == true)
        or (contextMenuClearMarkesByShiftKey and modifierKeyPressed == true and upInside and mouseButton == MOUSE_BUTTON_INDEX_RIGHT)
    )  then
        refreshPopupDialogButons = refreshPopupDialogButons or false
        -- make sure control contains an item
        local bagId, slotIndex = myGetItemDetails(clickedRow)
        --bagId and slotIndex could be nil here if called from IIfA UI!
        if isIIFAActive == nil then isIIFAActive = FCOIS.otherAddons.IIFAActive end
--d(">bagId: " ..tos(bagId) ..", slotIndex: " ..tos(slotIndex) .. ", isIIFAActive: " .. tos(isIIFAActive) .. ", wasIIfARowClicked: " ..tos(wasIIfARowClicked))
        if (bagId ~= nil and slotIndex ~= nil) or (isIIFAActive == true and wasIIfARowClicked == true) then
--d(">Clearing/Restoring all markers of the current item now! bag: " .. bagId .. ", slotIndex: " .. slotIndex .. " " .. gil(bagId, slotIndex))
            --Set the preventer variable now to suppress the context menu of inventory items
            if not calledByKeybind and not calledByContextMenu then
--d(">NO KEYBIND call: enabling dontShowInvContextMenu: true ")
                FCOIS.preventerVars.dontShowInvContextMenu = true
            end
--d("[FCOIS]checkIfClearOrRestoreAllMarkers - dontShowInvContextMenu: true")
            --Clear/Restore the markers now
            clearOrRestoreAllMarkers(clickedRow, bagId, slotIndex, false, wasIIfARowClicked)
            if refreshPopupDialogButons then
                --Unselect the item and disable the button of the popup dialog again
--d("[FCOIS]checkIfClearOrRestoreAllMarkers - refreshPopupDialog now")
                FCOIS.RefreshPopupDialogButtons(clickedRow, false)
            end
            --Is the character shown, then disable the context menu "hide" variable again as the order of hooks is not
            --the same like in the inventory and the context menu will be hidden twice in a row else!
            -->Only if no ZO_Dialog is used, as the variable FCOIS.preventerVars.dontShowInvContextMenu will be needed
            -->in the calling row hook of the ZO_ListDialog, and reset to false there!
            if not calledByKeybind and not calledByContextMenu and not refreshPopupDialogButons then
                --local isCharacter = (bagId == BAG_WORN and isCharacterShown()) or false
                --local isCompanionCharacter = (bagId == BAG_COMPANION_WORN and isCompanionCharacterShown()) or false
                --if isCharacter == true or isCompanionCharacter == true then
--d(">NO KEYBIND call: changing dontShowInvContextMenu to false again!")
                FCOIS.preventerVars.dontShowInvContextMenu = false
                --end
            end
        end
    end
end
local checkIfClearOrRestoreAllMarkers = FCOIS.CheckIfClearOrRestoreAllMarkers

--Called per keybind: Get the current row the mouse is above and then remove or restore all marker icons
function FCOIS.RemoveAllMarkerIconsOrUndo()
--d("[FCOIS]RemoveAllMarkerIconsOrUndo")
    local mouseOverControl = wm:GetMouseOverControl()
    if mouseOverControl ~= nil then
        local contextMenuClearMarkesKey = FCOIS.settingsVars.settings.contextMenuClearMarkesModifierKey
        local isModifierKeyPressedResult = isModifierKeyPressed(contextMenuClearMarkesKey)
        local refreshPopupDialogButons = FCOIS.preventerVars.isZoDialogContextMenu
--d(">mouseOverControl: " ..tos(mouseOverControl:GetName()) ..", contextMenuClearMarkesKey: " ..tos(contextMenuClearMarkesKey) .. ", isModifierKeyPressed: " .. tos(isModifierKeyPressedResult) .. ", refreshPopupDialogButons: " ..tos(refreshPopupDialogButons))
        checkIfClearOrRestoreAllMarkers(mouseOverControl, isModifierKeyPressedResult, nil, nil, refreshPopupDialogButons, true, false, nil) -- calledByKeybind = true
    end
end

-- =====================================================================================================================
--  Equipment functions
-- =====================================================================================================================

--Function to add an icon for the equipped armor type (light, medium, heavy) to an equipment slot control
local function AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, armorType)
    if equipmentSlotControl == nil then return false end
    local characterEquipmentArmorSlots = mappingVars.characterEquipmentArmorSlots
    local equipmentSlotName = equipmentSlotControl:GetName()

    --Check if the equipment slot control is an armor control
    if not characterEquipmentArmorSlots[equipmentSlotName] then return false end
    if armorType == nil or armorType == ARMORTYPE_NONE then return false end
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[AddArmorTypeIconToEquipmentSlot]","EquipmentSlot: " .. equipmentSlotName .. ", armorType: " .. tos(armorType), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

    local isCompanionCharacter = (equipmentSlotControl:GetParent() == ctrlVars.COMPANION_CHARACTER) or false
--d(">equipmentSlotName: " ..tos(equipmentSlotName) .. ", isCompanionCharacter: " ..tos(isCompanionCharacter))

    local armorTypeLabel = GetControl("FCOIS_" .. equipmentSlotName .."_ArmorTypeLabel") --wm:GetControlByName("FCOIS_" .. equipmentSlotName .. "_ArmorTypeLabel")
    if settings.showArmorTypeIconAtCharacter then
        if armorTypeLabel == nil then
            armorTypeLabel = wm:CreateControl("FCOIS_" .. equipmentSlotName .. "_ArmorTypeLabel", equipmentSlotControl, CT_LABEL)
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
        if isCompanionCharacter == true then
            FCOIS.countVars.countCompanionLightArmor = FCOIS.countVars.countCompanionLightArmor + 1
        else
            FCOIS.countVars.countLightArmor = FCOIS.countVars.countLightArmor + 1
        end
        if settings.showArmorTypeIconAtCharacter and armorTypeLabel ~= nil then
            armorTypeLabel:SetText(locVars["options_armor_type_icon_light_short"])
            armorTypeLabel:SetColor(settings.armorTypeIconAtCharacterLightColor.r, settings.armorTypeIconAtCharacterLightColor.g, settings.armorTypeIconAtCharacterLightColor.b, settings.armorTypeIconAtCharacterLightColor.a)
        end
    elseif	armorType == ARMORTYPE_MEDIUM then
        if isCompanionCharacter == true then
            FCOIS.countVars.countCompanionMediumArmor = FCOIS.countVars.countCompanionMediumArmor + 1
        else
            FCOIS.countVars.countMediumArmor = FCOIS.countVars.countMediumArmor + 1
        end
        if settings.showArmorTypeIconAtCharacter and armorTypeLabel ~= nil then
            armorTypeLabel:SetText(locVars["options_armor_type_icon_medium_short"])
            armorTypeLabel:SetColor(settings.armorTypeIconAtCharacterMediumColor.r, settings.armorTypeIconAtCharacterMediumColor.g, settings.armorTypeIconAtCharacterMediumColor.b, settings.armorTypeIconAtCharacterMediumColor.a)
        end
    elseif	armorType == ARMORTYPE_HEAVY then
        if isCompanionCharacter == true then
            FCOIS.countVars.countCompanionHeavyArmor = FCOIS.countVars.countCompanionHeavyArmor + 1
        else
            FCOIS.countVars.countHeavyArmor = FCOIS.countVars.countHeavyArmor + 1
        end
        if settings.showArmorTypeIconAtCharacter and armorTypeLabel ~= nil then
            armorTypeLabel:SetText(locVars["options_armor_type_icon_heavy_short"])
            armorTypeLabel:SetColor(settings.armorTypeIconAtCharacterHeavyColor.r, settings.armorTypeIconAtCharacterHeavyColor.g, settings.armorTypeIconAtCharacterHeavyColor.b, settings.armorTypeIconAtCharacterHeavyColor.a)
        end
    end
end

--Update the equipment header text with the information about the amount of equipped armor types
local armorText = GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_APPAREL) --#288
local function updateEquipmentHeaderCountText(updateWhere)
    local isCompanionCharacter = (updateWhere == FCOIS_CON_LF_COMPANION_CHARACTER) or false
    if isCompanionCharacter == true then
        --Check all equipment controls -> Companion
        if not isCompanionCharacterShown() then return end
    end

    local showArmorTypeHeaderTextAtCharacter = FCOIS.settingsVars.settings.showArmorTypeHeaderTextAtCharacter
    local updateWhereToCharacterApparelSection = mappingVars.characterApparelSection
    local charApparelSectionCtrl = updateWhereToCharacterApparelSection[updateWhere]
    if not charApparelSectionCtrl then return end

    if not showArmorTypeHeaderTextAtCharacter then
        charApparelSectionCtrl:SetText(armorText)
        return
    end
    local countVars = FCOIS.countVars
    local locVars = FCOIS.localizationVars.fcois_loc
    if isCompanionCharacter == true then
        if countVars.countCompanionLightArmor ~= nil or countVars.countCompanionMediumArmor ~= nil or countVars.countCompanionHeavyArmor ~= nil then
            charApparelSectionCtrl:SetText(armorText .. " (" .. locVars["options_armor_type_icon_light_short"] .. ": " .. countVars.countCompanionLightArmor .. ", " .. locVars["options_armor_type_icon_medium_short"] .. ": " .. countVars.countCompanionMediumArmor .. ", " .. locVars["options_armor_type_icon_heavy_short"] .. ": " .. countVars.countCompanionHeavyArmor .. ")")
        end
    else
        if countVars.countLightArmor ~= nil or countVars.countMediumArmor ~= nil or countVars.countHeavyArmor ~= nil then
            charApparelSectionCtrl:SetText(armorText .. " (" .. locVars["options_armor_type_icon_light_short"] .. ": " .. countVars.countLightArmor .. ", " .. locVars["options_armor_type_icon_medium_short"] .. ": " .. countVars.countMediumArmor .. ", " .. locVars["options_armor_type_icon_heavy_short"] .. ": " .. countVars.countHeavyArmor .. ")")
        end
    end
end
FCOIS.UpdateEquipmentHeaderCountText = updateEquipmentHeaderCountText

--function to count and update the equipped armor parts of character and companion and to add the marker texture controls to the
--equipment slots via function FCOIS.RefreshEquipmentControl, if the function FCOIS.RefreshEquipmentControl was called without
--any equipmentSlot control, markerIconId etc., but parameter updateIfCharacterNotShown = true
function FCOIS.CountAndUpdateEquippedArmorTypes(doRefreshControl, doCreateMarkerControl, markerIconId, updateIfCharacterNotShown)
--d("[FCOIS]countAndUpdateEquippedArmorTypes - doRefreshControl: " ..tos(doRefreshControl) .. ", markerIconId: " ..tos(markerIconId))
    doRefreshControl = doRefreshControl or false
    updateIfCharacterNotShown = updateIfCharacterNotShown or false
    local isCharacter = isCharacterShown()
    local isCompanionCharacter = isCompanionCharacterShown()
    if not updateIfCharacterNotShown and not isCharacter and not isCompanionCharacter then return end
    if updateIfCharacterNotShown == true then
        isCharacter = true
        isCompanionCharacter = true
    end

    --Reset the armor type counters
    resetCharacterArmorTypeNumbers()

    --Check all equipment controls -> Player
    local equipmentSlotControl
    local characterEquipmentSlotNameByIndex = mappingVars.characterEquipmentSlotNameByIndex
    if isCharacter == true then
--d(">character")
        for _, equipmentSlotName in pairs(characterEquipmentSlotNameByIndex) do
            --Get the control of the equipment slot
            equipmentSlotControl = GetControl(equipmentSlotName) --wm:GetControlByName(equipmentSlotName, "")
            if equipmentSlotControl ~= nil then
                --Refresh each equipped item's marker icons
                if doRefreshControl then
                    refreshEquipmentControl = refreshEquipmentControl or FCOIS.RefreshEquipmentControl
                    refreshEquipmentControl(equipmentSlotControl, doCreateMarkerControl, markerIconId, false, updateIfCharacterNotShown)
                end

                --Show the armor type icons at the player doll?
                AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, getArmorType(equipmentSlotControl))
            end
        end
        --Update the equipment header text and show the amount of armor types equipped
        updateEquipmentHeaderCountText(FCOIS_CON_LF_CHARACTER)
    end
    ------------------------------------------------------------------------------------------------------------------------
    --Check all equipment controls -> Companion
    if isCompanionCharacter == true then
--d(">companion character")
        equipmentSlotControl = nil
        local companionCharacterEquipmentSlotNameByIndex = mappingVars.companionCharacterEquipmentSlotNameByIndex
        for _, equipmentSlotName in pairs(companionCharacterEquipmentSlotNameByIndex) do
            --Get the control of the equipment slot
            equipmentSlotControl = GetControl(equipmentSlotName) --wm:GetControlByName(equipmentSlotName, "")
            if equipmentSlotControl ~= nil then
                --Refresh each equipped item's marker icons
                if doRefreshControl then
                    refreshEquipmentControl = refreshEquipmentControl or FCOIS.RefreshEquipmentControl
                    refreshEquipmentControl(equipmentSlotControl, doCreateMarkerControl, markerIconId, false, updateIfCharacterNotShown)
                end

                --Show the armor type icons at the player doll?
                AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, getArmorType(equipmentSlotControl))
            end
        end
        --Update the equipment header text and show the amount of armor types equipped
        updateEquipmentHeaderCountText(FCOIS_CON_LF_COMPANION_CHARACTER)
    end
end
local countAndUpdateEquippedArmorTypes = FCOIS.CountAndUpdateEquippedArmorTypes

--Remove the armor type marker from character doll
function FCOIS.RemoveArmorTypeMarker(bagId, slotId)
--d("[FCOIS]RemoveArmorTypeMarker - item: " ..gil(bagId, slotId))
    local settings = FCOIS.settingsVars.settings
    if not settings.showArmorTypeIconAtCharacter then return false end
    if bagId == nil or slotId == nil then return false end
    local characterEquipmentSlotNameByIndex

    local isCompanionCharacter = isCompanionCharacterShown()
    if isCompanionCharacter == true then
        if bagId == BAG_WORN then bagId = BAG_COMPANION_WORN end
        characterEquipmentSlotNameByIndex = mappingVars.companionCharacterEquipmentSlotNameByIndex
    else
        characterEquipmentSlotNameByIndex = mappingVars.characterEquipmentSlotNameByIndex
    end
    local equipmentSlotControlName = characterEquipmentSlotNameByIndex[slotId]
    if equipmentSlotControlName == nil then return false end
    local equipmentSlotControl = GetControl(equipmentSlotControlName) --wm:GetControlByName(equipmentSlotControlName, "")
    if equipmentSlotControl == nil then return false end

    --Check slightly delayed if item is (still) equipped
    --as drag&drop the icon to its previous position will call this funciton here too
    zo_callLater(function()
        if equipmentSlotControl.stackCount == 0 then
            --Hide the text control showing the armor type for this equipment slot
            local armorTypeLabel = GetControl("FCOIS_" .. equipmentSlotControl:GetName() .. "_ArmorTypeLabel") --wm:GetControlByName("FCOIS_" .. equipmentSlotControl:GetName() .. "_ArmorTypeLabel")
            if armorTypeLabel == nil then return true end
            armorTypeLabel:SetHidden(true)
        end
    end, 250)
end


-- Check the weapon type
local function checkWeaponType(p_weaponType, p_check)
    if (p_check == nil or p_check == '') then
        p_check = '1hd'
    end
    if (p_weaponType ~= nil) then
        local checkVarsWeaponType = FCOIS.checkVars.weaponTypeCheckTable
        if checkVarsWeaponType[p_check] and checkVarsWeaponType[p_check][p_weaponType] then
            return true
        end
    end
    return false
end

--Check if the current equipment slot is the offhand or backup offhand slot
local characterEquipmentSlotNameByIndex = mappingVars.characterEquipmentSlotNameByIndex
function FCOIS.CheckWeaponOffHand(controlName, weaponTypeName, doCheckOffHand, doCheckBackupOffHand, echo)
--d("[FCOIS]checkWeaponOffHand")
    if echo then
        if FCOIS.settingsVars.settings.debug then debugMessage( "[checkWeaponOffHand]", "ControlName: " .. controlName ..", WeaponTypeName: " .. weaponTypeName, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end
    local weaponControl
    local weaponType
    characterEquipmentSlotNameByIndex = characterEquipmentSlotNameByIndex or mappingVars.characterEquipmentSlotNameByIndex

    --Check the offhand?
    if doCheckOffHand == true then
--d(">doCheckOffHand")
        if (controlName == characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]) then -- 'ZO_CharacterEquipmentSlotsOffHand'
            --Check if the weapon in the main slot is a 2hd weapon/staff
            weaponControl = GetControl(characterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND]) --wm:GetControlByName(characterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND], "") --"ZO_CharacterEquipmentSlotsMainHand"
            if weaponControl ~= nil then
--d(">found weapon at main hand: " ..gil(weaponControl.bagId, weaponControl.slotIndex))
                weaponType = GetItemWeaponType(weaponControl.bagId, weaponControl.slotIndex)
                if (weaponType ~= nil) then
                    return checkWeaponType(weaponType, weaponTypeName)
                end
            end
        end
    end

    --Check the backup offhand?
    if doCheckBackupOffHand == true then
--d(">doCheckBackupOffHand")
        if (controlName == characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]) then -- 'ZO_CharacterEquipmentSlotsBackupOff'
            --Check if the weapon in the backup slot is a 2hd weapon/staff
            weaponControl = GetControl(characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN]) --wm:GetControlByName(characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN], "") -- "ZO_CharacterEquipmentSlotsBackupMain"
            if weaponControl ~= nil then
--d(">found weapon at backup main hand: " ..gil(weaponControl.bagId, weaponControl.slotIndex))
                weaponType = GetItemWeaponType(weaponControl.bagId, weaponControl.slotIndex)
                if (weaponType ~= nil) then
                    return checkWeaponType(weaponType, weaponTypeName)
                end
            end
        end
    end

    return false
end
local checkWeaponOffHand = FCOIS.CheckWeaponOffHand


--Function to check empty weapon slots (Main & Offhand) and remove markers. Needed a delay ~1200ms to work properly before
--Blackwood PTS API100035. Now the value can be lowered to 150ms
function FCOIS.RemoveEmptyWeaponEquipmentMarkers(delay)
    --If he delay is below ??? the marker icons at backup weapon slots won't be removed properly e.g. as you drag&drop/doubleclick
    --a 2hd weapon and 2x1hd weapons were equipped. Backup weapon (2nd 1hd) got a marker icon which will stay at the 2nd weapon then!
    delay = delay or 150
--d("[FCOIS]RemoveEmptyWeaponEquipmentMarkers - delay: " .. tos(delay))
    --Call delayed as the equipment needs to be unequipped first
    zo_callLater(function()
        local isCharacter = isCharacterShown()
        local isCompanionCharacter = isCompanionCharacterShown()
        if not isCharacter and not isCompanionCharacter then return end
--d(">char chown")
        local checkVars = FCOIS.checkVars
        local allowedCharacterEquipmentWeaponControlNames = checkVars.allowedCharacterEquipmentWeaponControlNames
        local allowedCharacterEquipmentWeaponBackupControlNames = checkVars.allowedCharacterEquipmentWeaponBackupControlNames
        local equipVars = FCOIS.equipmentVars
        local settings = FCOIS.settingsVars.settings
        local texVars = FCOIS.textureVars
        --For each weapon equipment control: check the empty markers and remove them
        for equipmentControlName, _ in pairs(allowedCharacterEquipmentWeaponControlNames) do
            if settings.debug then debugMessage( "[RemoveEmptyWeaponEquipmentMarkers]","equipmentControl: " .. equipmentControlName ..", delay: " .. delay, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d(">>equipmentControl: " .. tos(equipmentControlName))
            if equipmentControlName ~= nil and equipmentControlName ~= "" then
                local equipmentControl = GetControl(equipmentControlName) --wm:GetControlByName(equipmentControlName, "")
                if equipmentControl ~= nil then -- and equipmentControl:IsHidden() == false then
                    --Check if the current equipment slot name is a weapon backup slot
                    local twoHandedWeaponOffHand = false
                    if allowedCharacterEquipmentWeaponBackupControlNames[equipmentControlName] then
                        --Check if the slot contains a 2hd weapon
                        twoHandedWeaponOffHand = checkWeaponOffHand(equipmentControlName, "2hdall", true, true, true)
                    end
                    --Check if the equipment control got something equipped or it's a backup weapon slot containing a 2hd weapon
                    if equipmentControl.stackCount == 0 or twoHandedWeaponOffHand then
                        --Remove the markers for the filter icons at the equipment slot
                        --[[
                        local width = settings.iconSizeCharacter or equipVars.gEquipmentIconWidth
                        local height = settings.iconSizeCharacter or equipVars.gEquipmentIconHeight
                        for markerIconId=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                            --3rd last parameter = doHide (true)
                            --createMarkerControl(parent, markerIconId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped, pDrawLevel)
                            createMarkerControl(equipmentControl, markerIconId, width, height, texVars.MARKER_TEXTURES[settings.icon[markerIconId].texture], true, false, false, false, true, nil, nil)
                        end
                        ]]
                        --addMarkerIconsToControl(rowControl, pDoCreateMarkerControl, pIsEquipmentSlot, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped)
                        addMarkerIconsToControl(equipmentControl, false, true, false, false, true, nil)
                    end
                end
            end
        end
    end, delay)
end
local removeEmptyWeaponEquipmentMarkers = FCOIS.RemoveEmptyWeaponEquipmentMarkers

--The function to refresh the equipped items and their markers
function FCOIS.RefreshEquipmentControl(equipmentControl, doCreateMarkerControl, p_markId, dontCheckRings, updateIfCharacterNotShown, unequipped)
--d("[FCOIS]RefreshEquipmentControl-doCreateMarkerControl: " ..tos(doCreateMarkerControl) .. ", p_markId: " .. tos(p_markId) ..", dontCheckRings: " ..tos(dontCheckRings) ..", updateIfCharacterNotShown: "..tos(updateIfCharacterNotShown) .. ", unequipped: " ..tos(unequipped))
    dontCheckRings = dontCheckRings or false
    --Preset the value for "Create control if not existing yet" with false
    doCreateMarkerControl = doCreateMarkerControl or false
    updateIfCharacterNotShown = updateIfCharacterNotShown or false
    unequipped = unequipped or false
    local isCharacter = isCharacterShown()
    local isCompanionCharacter = isCompanionCharacterShown()

--d(">isCharacter: " ..tos(isCharacter) .. ", isCompanionCharacter: " ..tos(isCompanionCharacter))


    if not updateIfCharacterNotShown and not isCharacter and not isCompanionCharacter then return end

--d(">1")
    local equipVars = FCOIS.equipmentVars
    local texVars = FCOIS.textureVars
    local settings = FCOIS.settingsVars.settings
    local checkVars = FCOIS.checkVars
    local hideControl

    --is the equipment control already given?
    if equipmentControl ~= nil then -- and equipmentControl:IsHidden() == false then
        local width = settings.iconSizeCharacter or equipVars.gEquipmentIconWidth
        local height = settings.iconSizeCharacter or equipVars.gEquipmentIconHeight
        --Check all marker ids?
        if p_markId == nil or p_markId == 0 then
--d(">checkAllMarkerIcons")
            if settings.debug then debugMessage( "[RefreshEquipmentControl]","Control: " .. equipmentControl:GetName() .. ", Create: " .. tos(doCreateMarkerControl) .. ", MarkId: ALL", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Add/Update the markers for the filter icons at the equipment slot
            hideControl = false
            --[[
            for markerIconId=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                --parent, markerIconId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped
                createMarkerControl(equipmentControl, markerIconId, width, height, texVars.MARKER_TEXTURES[settings.icon[markerIconId].texture], true, doCreateMarkerControl, hideControl, nil, nil, unequipped)
            end
            ]]
            --addMarkerIconsToControl(rowControl, pDoCreateMarkerControl, pIsEquipmentSlot, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped)
            addMarkerIconsToControl(equipmentControl, doCreateMarkerControl, true, hideControl --[[ todo 20240328 is pUpdateAllEquipmentTooltips=hideControl("false") correct here? ]], nil, hideControl, unequipped)
        --Only check a specific marker id
        else
--d(">CheckMarkerIcon: " ..tos(p_markId))
           --Changing one specific markerIcon p_markId -> e.g. from FCOIS.MarkMe() function (right clicking any item to apply/remove a marker icon -> at character panel)
           if settings.debug then debugMessage( "[RefreshEquipmentControl]","Control: " .. equipmentControl:GetName() .. ", Create: " .. tos(doCreateMarkerControl) .. ", MarkId: " .. tos(p_markId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            hideControl = true
            --Add/Update the marker p_markId for the filter icons at the equipment slot
                                --parent, markerIconId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped, pDrawLevel, pIsIconEnabled
            createMarkerControl(equipmentControl, p_markId, width, height, texVars.MARKER_TEXTURES[settings.icon[p_markId].texture], true, doCreateMarkerControl, hideControl, nil, nil, unequipped, nil, settings.isIconEnabled[p_markId])
        end

        --Are we chaning equipped weapons? Update the markers and remove 2hd weapon markers
        local equipControlName = equipmentControl:GetName()
        if equipControlName ~= nil and equipControlName ~= "" then
--d("[FCOIS.RefreshEquipmentControl] name: " ..tos(equipControlName))
            if checkVars.allowedCharacterEquipmentWeaponControlNames[equipControlName] then
                --Check if the offhand weapons are 2hd weapons and remove the markers then
                removeEmptyWeaponEquipmentMarkers()
            end

            --Is the equipment slot a ring? Then check if the same ring is equipped at the other slot and update the marker icon visibility too
            --But not if the 1st ring got unequipped, as the marker icon on still equipped rings need to be kept!
            local isRing = (not dontCheckRings and checkVars.allowedCharacterEquipmentJewelryRingControlNames[equipControlName]) or false
--d(">isRing: " ..tos(isRing))
            if isRing == true and not unequipped  then
                local bag, slot = myGetItemDetails(equipmentControl)
--d(">bag: " ..tos(bag) .. ", slotIndex: " ..tos(slot))
                if bag == nil or slot == nil then return false end
                --Most unequips fail here as the slot got no data anymore and thus the itemId will be nil! This is why unequipping was disabled at the isring == true and not unequipped check!
                local itemId = myGetItemInstanceIdNoControl(bag, slot, true)
--d(">itemId: " ..tos(itemId))
                if itemId == nil then return false end
                local isRingMarked, _ = FCOIS.IsMarked(bag, slot, -1)
                local doHide = not isRingMarked
--d(">doHide: " ..tos(doHide))
                --Get the other ring
                local mappingOfRings = mappingVars.equipmentJewelryRing2RingSlot
                local otherRingSlotName = mappingOfRings[equipControlName]
--d(">otherRingSlotName: " ..tos(otherRingSlotName))
                local otherRingControl = GetControl(otherRingSlotName) --wm:GetControlByName(otherRingSlotName, "")
                --Compare the item Ids/Unique itemIds (if enabled)
                if otherRingControl ~= nil and otherRingControl:IsHidden() == false then
                    --Get the bag and slot
                    local bagRing2, slotRing2 = myGetItemDetails(otherRingControl)
                    if bagRing2 ~= nil and slotRing2 ~= nil then
                        --Get the itemId and compare it with the other ring
                        local itemIdOtherRing = myGetItemInstanceIdNoControl(bagRing2, slotRing2, true)
--d(">>other ring, itemId: " .. tos(itemIdOtherRing) ..", " .. gil(bagRing2, slotRing2))
                        if itemId == itemIdOtherRing then
                            refreshEquipmentControl = refreshEquipmentControl or FCOIS.RefreshEquipmentControl

                            --local doMarkRing = not doHide
                            --Marking of ring is not needed as it was marked already and the itemInstaceId/uniqueId should be the same ->
                            --Thus marks will be "visible" after refreshing the slot's marker control!
                            --FCOIS.MarkItem(bagRing2, slotRing2, p_markId, doMarkRing, false)
                            --Update the texture, create it if not there yet

                            --!!!ATTENTION!!! Recursive call of function, so set 4th parameter "dontCheckRings" = true to prevent endless loop between ring1->ring2->ring1->...!
                            refreshEquipmentControl(otherRingControl, true, p_markId, true, updateIfCharacterNotShown, unequipped)
                        end
                    end
                end
            end
        end

    --Equipment control is not given yet, or unknown
    else
--d(">equipment control = nil")
        if settings.debug then debugMessage( "[RefreshEquipmentControl]","ALL CONTROLS! Create: " .. tos(doCreateMarkerControl) .. ", MarkId: " .. tos(p_markId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        --[[
        --Reset the armor type counters
        resetCharacterArmorTypeNumbers()

        --Check all equipment controls
        local equipmentSlotControl
        for _, equipmentSlotName in pairs(mappingVars.characterEquipmentSlotNameByIndex) do
            --Get the control of the equipment slot
            equipmentSlotControl = GetControl(equipmentSlotName) --wm:GetControlByName(equipmentSlotName, "")
            if equipmentSlotControl ~= nil then
                --Refresh each equipped item's marker icons
                FCOIS.RefreshEquipmentControl(equipmentSlotControl, doCreateMarkerControl, p_markId)
                --Show the armor type icons at the player doll?
                AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, getArmorType(equipmentSlotControl))
            end
        end

        --Update the equipment header text and show the amount of armor types equipped
        updateEquipmentHeaderCountText()
        ]]
        countAndUpdateEquippedArmorTypes(true, doCreateMarkerControl, p_markId, updateIfCharacterNotShown)
    end
end
refreshEquipmentControl = FCOIS.RefreshEquipmentControl

--Update one specific equipment slot by help of the slotIndex
local updateEquipmentSlotMarker = FCOIS.UpdateEquipmentSlotMarker
function FCOIS.UpdateEquipmentSlotMarker(slotIndex, delay, unequipped)
--d("[FCOIS]updateEquipmentSlotMarker-slotIndex: " ..tos(slotIndex).. ", delay: " ..tos(delay) .. ", unequipped: " ..tos(unequipped))
    --Only execute if character window is shown
    if slotIndex ~= nil then
        delay = delay or 0
        if delay > 0 then
            updateEquipmentSlotMarker = updateEquipmentSlotMarker or FCOIS.UpdateEquipmentSlotMarker
            zo_callLater(function()
                updateEquipmentSlotMarker(slotIndex, 0, unequipped)
            end, delay)
        else
            local isCharacter = isCharacterShown()
            local isCompanionCharacter = isCompanionCharacterShown()
--d(">isCharacter: " ..tos(isCharacter) .. ", isCompanionCharacter: " ..tos(isCompanionCharacter))
            if not isCharacter and not isCompanionCharacter then return end

            local armorSlots = mappingVars.characterEquipmentArmorSlots

            local equipSlotControlName
            if isCompanionCharacter == true then
                equipSlotControlName = mappingVars.companionCharacterEquipmentSlotNameByIndex[slotIndex]
            else
                equipSlotControlName = mappingVars.characterEquipmentSlotNameByIndex[slotIndex]
            end
--d(">equipSlotControlName: " ..tos(equipSlotControlName))
            --Get the equipment control by help of the slotIndex
            local equipSlotControl
            if equipSlotControlName ~= nil and equipSlotControlName ~= "" then
                if FCOIS.settingsVars.settings.debug then debugMessage( "[updateEquipmentSlotMarker]","control name="..equipSlotControlName..", slotIndex: " .. slotIndex, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                equipSlotControl = GetControl(equipSlotControlName) --wm:GetControlByName(equipSlotControlName, "")
--d(">>isHidden: " ..tos(equipSlotControl:IsHidden()))
                if equipSlotControl ~= nil then --and equipSlotControl:IsHidden() == false then
                    --Add or refresh the equipped items, create marker control if not already there
                    --equipmentControl, doCreateMarkerControl, p_markId, dontCheckRings, updateIfCharacterNotShown, unequipped
--d(">>calling refreshEquipmentControl")
                    refreshEquipmentControl(equipSlotControl, true, nil, nil, nil, unequipped)
                    --Check if the equipment slot control is an armor control
                    if armorSlots[equipSlotControlName] ~= nil then
                        --Count the now equipped armor types and update the text at the character window armor header text
                        countAndUpdateEquippedArmorTypes()
                    end
                end
            end
        end
    end
end
updateEquipmentSlotMarker = FCOIS.UpdateEquipmentSlotMarker

--The callback function for the right click/context menus to mark all equipment items with one click
function FCOIS.MarkAllEquipment(rowControl, markId, updateNow, doHide)
    if FCOIS.gFilterWhere == nil then return end

    local isCharacter = isCharacterShown()
    local isCompanionCharacter = isCompanionCharacterShown()
    if not isCharacter and not isCompanionCharacter then return end

    markItemByItemInstanceId = markItemByItemInstanceId or FCOIS.MarkItemByItemInstanceId
    markItem = markItem or FCOIS.MarkItem

    --Set the last used filter Id
    FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] = mappingVars.iconToFilter[markId]

    local equipmentControl
    local equipmentSlotName
    local dontChange
    local itemId
    local settings = FCOIS.settingsVars.settings
    local checkVars = FCOIS.checkVars

    local characterCtrl = ctrlVars.CHARACTER
    local equipmentSlotsCtrlName = ctrlVars.CHARACTER_EQUIPMENT_SLOTS_NAME
    if isCompanionCharacter == true then
        characterCtrl = ctrlVars.COMPANION_CHARACTER
        equipmentSlotsCtrlName = ctrlVars.COMPANION_CHARACTER_EQUIPMENT_SLOTS_NAME
    end

    --Get each equipped item
    for i=1, characterCtrl:GetNumChildren() do
        dontChange = false
        equipmentControl = characterCtrl:GetChild(i)
        equipmentSlotName = equipmentControl:GetName()
--d("[FCOIS.MarkAllEquipment]equipmentSlotName: " ..tos(equipmentSlotName))
        if settings.debug then debugMessage( "[MarkAllEquipment]","MarkId: " .. tos(markId) .. ", EquipmentSlot: "..equipmentSlotName..", no_auto_mark: " .. tos(checkVars.equipmentSlotsNames["no_auto_mark"][equipmentSlotName])) end
        --Is the current equipment slot a changeable one?
        if strfind(equipmentSlotName, equipmentSlotsCtrlName) then
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
            if dontChange == false and equipmentControl ~= nil then
                --get the itemid
                local bag, slot = myGetItemDetails(equipmentControl)
                if markId ~= nil and bag ~= nil and slot ~= nil then
                    itemId = myGetItemInstanceIdNoControl(bag, slot, true)
                    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                    markItem(bag, slot, markId, not doHide, false)
                    --Update the texture, create it if not there yet
                    refreshEquipmentControl(equipmentControl, true, markId)
                end
            end
        end
    end
    --if (updateNow == true) then
    --filterBasics(false)
    --end
end


--Companion or char is shown? Check if the item was a ring: Update the character equipmentSlots of rings as well then
--as 1 ring marked/unmarked at the inventory needs to update the visibility of the marker control at the character panel too
function FCOIS.CheckIfCharOrInvNeedsRingUpdate(p_bagId, p_slotIndex, p_parent, p_doMark, p_markId)
    local isCompanionCharShown = isCompanionCharacterShown()
    local isCharShown = isCharacterShown()
    if not isCharShown and not isCompanionCharShown then return end
    local itemEquipTyp = GetItemEquipType(p_bagId, p_slotIndex)
    if itemEquipTyp ~= EQUIP_TYPE_RING then return end
    if p_parent == ctrlVars.CHARACTER or p_parent == ctrlVars.COMPANION_CHARACTER then
        filterBasics(true)
    else
        --Get the ring equipment controls and update them
        local ringEquipmentControlsTable
        if isCharShown then
            ringEquipmentControlsTable = mappingVars.characterEquipmentRingSlots
        else
            ringEquipmentControlsTable = mappingVars.characterCompanionEquipmentRingSlots
        end
        local ringControl1 = ringEquipmentControlsTable[EQUIP_SLOT_RING1] ~= nil and GetControl(ringEquipmentControlsTable[EQUIP_SLOT_RING1]) --wm:GetControlByName(ringEquipmentControlsTable[EQUIP_SLOT_RING1])
        if ringControl1 ~= nil then
            refreshEquipmentControl(ringControl1, p_doMark,  p_markId, nil, nil, nil)
        end
        local ringControl2 = ringEquipmentControlsTable[EQUIP_SLOT_RING2] ~= nil and GetControl(ringEquipmentControlsTable[EQUIP_SLOT_RING2]) --wm:GetControlByName(ringEquipmentControlsTable[EQUIP_SLOT_RING2])
        if ringControl2 ~= nil then
            refreshEquipmentControl(ringControl2, p_doMark,  p_markId, nil, nil, nil)
        end
    end
end
local checkIfCharOrInvNeedsRingUpdate = FCOIS.CheckIfCharOrInvNeedsRingUpdate


--Clear all current markers of the selected row, or restore all marker icons from the undo table
--If parameter onlyFeedback is set to true the function returns 1 if marker icons are currently set and can be removed
--or 2 if marker icons were already removed and saved for a restore, or it returns -1 if both is not possible
function FCOIS.ClearOrRestoreAllMarkers(rowControl, bagId, slotIndex, onlyFeedback, wasIIfARowClicked)
--d("[FCOIS]ClearOrRestoreAllMarkers - onlyFeedback: " ..tos(onlyFeedback) .. ", wasIIfARowClicked: " ..tos(wasIIfARowClicked))
    if rowControl == nil then return nil, nil end
    onlyFeedback = onlyFeedback or false
    wasIIfARowClicked = wasIIfARowClicked or false
    if bagId == nil or slotIndex == nil then
        bagId, slotIndex = myGetItemDetails(rowControl)
    end
    if ((bagId == nil or slotIndex == nil) and not wasIIfARowClicked) then return nil, nil end

    isMarked = isMarked or FCOIS.IsMarked
    isMarkedByItemInstanceId = isMarkedByItemInstanceId or FCOIS.IsMarkedByItemInstanceId
    markItemByItemInstanceId = markItemByItemInstanceId or FCOIS.MarkItemByItemInstanceId
    checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate = checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate or FCOIS.CheckIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate

    --Could be that FCOIS.MarkMe was not called and thus FCOIS.IIfAclicked is nil!
    local fcoisItemInstanceId
    local itemLink
    if wasIIfARowClicked == true and (FCOIS.IIfAclicked == nil or FCOIS.IIfAclicked.itemInstanceOrUniqueId == nil) then
        checkAndGetIIfAData = checkAndGetIIfAData or FCOIS.CheckAndGetIIfAData
        local iifaItemLink, itemInstanceOrUniqueIdIIfA, bagIdIIfA, slotIndexIIfA, charsTableIIfA, inThisOtherBagsTableIIfA = checkAndGetIIfAData(rowControl, rowControl:GetParent())
        fcoisItemInstanceId = itemInstanceOrUniqueIdIIfA
        itemLink = iifaItemLink
        bagId = bagIdIIfA
        slotIndex = slotIndexIIfA
--d(">updated fcoisItemInstanceId: " ..tos(fcoisItemInstanceId) .. ", bagId: " ..tos(bagId) .. ", slotIndex: " ..tos(slotIndex))
    end

    local isCharacterShownVar          = (((bagId ~= nil and bagId == BAG_WORN) or wasIIfARowClicked == true) and isCharacterShown()) or false
    local isCompanionCharacterShownVar = (((bagId ~= nil and bagId == BAG_COMPANION_WORN) or wasIIfARowClicked == true) and isCompanionCharacterShown()) or false
    local lastMarkedIcons              = FCOIS.lastMarkedIcons
    FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = false
    FCOIS.preventerVars.gRestoringMarkerIcons = false
    FCOIS.preventerVars.gClearingMarkerIcons = false
    --Get the item's itemInstanceId (FCOIS style) and check if there are any marker icons saved in the undo list
    if fcoisItemInstanceId == nil then
        fcoisItemInstanceId = myGetItemInstanceId(rowControl, true)
    end
    if bagId ~= nil and slotIndex ~= nil and itemLink == nil then
        itemLink = gil(bagId, slotIndex)
    end
--d(">item: " .. tos(itemLink) .. ", itemInstanceId FCOIS: " ..tos(fcoisItemInstanceId) .. ", isCharacterShownVar: " ..tos(isCharacterShownVar).. ", isCompanionCharacterShownVar: " ..tos(isCompanionCharacterShownVar) .. ", invUpdateForce: " ..tos(FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem))
    if fcoisItemInstanceId ~= nil then
        local alreadyRemovedMarkersForThatBagAndItem = (lastMarkedIcons ~= nil and lastMarkedIcons[fcoisItemInstanceId] ~= nil and lastMarkedIcons[fcoisItemInstanceId]) or nil
        if alreadyRemovedMarkersForThatBagAndItem ~= nil then
--d(">>restoring marker icons")
            if onlyFeedback == true then
                return 2, alreadyRemovedMarkersForThatBagAndItem
            end

            --Marker icons were removed already for this item in this bag, so restore them now
            --Restore saved markers for the current item?
            local loc_counter = 1
            for iconId, iconIsMarked in pairs(alreadyRemovedMarkersForThatBagAndItem) do
                --Reset all markers
                --Refresh the control now to update the set marker icons?
                local refreshNow = isCharacterShownVar or isCompanionCharacterShownVar or FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem
    --d(">iconId: " ..tos(iconId) .. ", isMarked: " .. tos(iconIsMarked) .. ", refreshNow: " ..tos(refreshNow))
                --Set global preventer variable so no other marker icons will be set/removed during the restore
                FCOIS.preventerVars.gRestoringMarkerIcons = true
                --FCOIS.MarkItem(bagId, slotIndex, iconId, iconIsMarked, refreshNow)
                --FCOIS.preventerVars.markerIconChangedManually = true
                FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                markItemByItemInstanceId(fcoisItemInstanceId, iconId, iconIsMarked, itemLink, nil, nil, refreshNow)
                --Reset the global preventer variable
                FCOIS.preventerVars.gRestoringMarkerIcons = false
                --Check if the item mark removed other marks and if a row within another addon (like Inventory Insight) needs to be updated
                checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate(rowControl, iconId)
                loc_counter = loc_counter + 1
            end
            --Reset the last saved marker array for the current item
            FCOIS.lastMarkedIcons[fcoisItemInstanceId] = nil
            if loc_counter > 1 then
                --Refresh the inventory list now to hide removed marker icons
                filterBasics(false)
                --Check if the item needs to be removed from a craft slot or the guild store sell tab now
                isItemProtectedAtASlotNow(bagId, slotIndex, false, true)
                --Check if item is a ring and the char/inv needs an update on a same ring item
                checkIfCharOrInvNeedsRingUpdate(bagId, slotIndex, rowControl:GetParent(), true, nil)
            end

        else
--d(">>removing marker icons")
            --Marker icons were not removed yet for this item in this bag.
            --So remove them now
            --Clear all markers of current item
            --local itemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
            --Return false for marked icons, where the icon id is disabled in the settings
            FCOIS.preventerVars.doFalseOverride = true
            --local _, currentMarkedIcons = FCOIS.IsMarked(bagId, slotIndex, -1)
            FCOIS.preventerVars.gCalledFromInternalFCOIS = true
            local _, currentMarkedIcons = isMarkedByItemInstanceId(fcoisItemInstanceId, -1, nil, nil)
            --Reset to normal return values for marked & en-/disabled icons now
            FCOIS.preventerVars.doFalseOverride = false
            --For each marked icon of the currently improved item:
            --Set the icons/markers of the previous item again
--d(">currentMarkedIcons: " .. tos(#currentMarkedIcons))
            if currentMarkedIcons ~= nil and #currentMarkedIcons > 0 then
                --Build the backup array with normal marked icons now
                --local _, currentMarkedIconsUnchanged = FCOIS.IsMarked(bagId, slotIndex, -1)
                local currentMarkedIconsUnchanged = ZO_DeepTableCopy(currentMarkedIcons)
                --Create the arrays if any marker icon is set currently
                if not onlyFeedback then
                    FCOIS.lastMarkedIcons = FCOIS.lastMarkedIcons or {}
                    FCOIS.lastMarkedIcons[fcoisItemInstanceId] = FCOIS.lastMarkedIcons[fcoisItemInstanceId] or {}
                end
                --Counter vars
                local loc_counter = 1
                local loc_marked_counter = 0
                local iconIdsToBackup = {}
                --Loop over each of the marker icons and remove them
                for iconId, iconIsMarked in pairs(currentMarkedIcons) do
--d(">iconId: " .. tos(iconId) .. ", loc_counter: " .. tos(loc_counter))
                    --Only go on if item is marked or is the last marker (to update the inventory afterwards)
                    if iconIsMarked == true then
                        if onlyFeedback == true then
                            return 1, nil
                        end

                        loc_marked_counter = loc_marked_counter + 1
                        table.insert(iconIdsToBackup, iconId)
                    end
                    loc_counter = loc_counter + 1
                end
                --Only save the last active marker icons if any marker icon was removed
                if loc_marked_counter > 0 then
                    --Refresh the control now to update the cleared marker icons?
                    local refreshNow = isCharacterShownVar or isCompanionCharacterShownVar or FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem
                    --Remove marker icon
--d(">removing marker icons now")
                    --Set global preventer variable so no other marker icons will be set/removed during the clear
                    FCOIS.preventerVars.gClearingMarkerIcons = true
                    --FCOIS.MarkItem(bagId, slotIndex, iconId, false, refreshNow)
                    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
                    markItemByItemInstanceId(fcoisItemInstanceId, iconIdsToBackup, false, itemLink, nil, nil, refreshNow)
                    --Reset the global preventer variable
                    FCOIS.preventerVars.gClearingMarkerIcons = false
                    --Save the previous state of the marker icons on the item
                    FCOIS.lastMarkedIcons[fcoisItemInstanceId] = currentMarkedIconsUnchanged
                    --Refresh the inventory list now to hide removed marker icons
                    filterBasics(false)
                    --Check if item is a ring and the char/inv needs an update on a same ring item
                    checkIfCharOrInvNeedsRingUpdate(bagId, slotIndex, rowControl:GetParent(), false, nil)
                end
            end

        end
        if onlyFeedback == true then
            return -1, nil
        end
    end
    FCOIS.preventerVars.gRestoringMarkerIcons = false
    FCOIS.preventerVars.gClearingMarkerIcons = false
end
clearOrRestoreAllMarkers = FCOIS.ClearOrRestoreAllMarkers