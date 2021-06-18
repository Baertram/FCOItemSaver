--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local wm = WINDOW_MANAGER
local addonVars = FCOIS.addonVars
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local ctrlVars = FCOIS.ZOControlVars
local mappingVars = FCOIS.mappingVars

local checkIfItemIsProtected = FCOIS.checkIfItemIsProtected
local myGetItemDetails = FCOIS.MyGetItemDetails
local isItemProtectedAtASlotNow = FCOIS.IsItemProtectedAtASlotNow
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local myGetItemInstanceId = FCOIS.MyGetItemInstanceId
local filterBasics = FCOIS.FilterBasics
local isCharacterShown = FCOIS.isCharacterShown
local isCompanionCharacterShown = FCOIS.isCompanionCharacterShown

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
            local bagId, slotIndex = myGetItemDetails(parent)
            if bagId == nil or slotIndex == nil then return end
            doHide = not FCOIS.isItemAlreadyBound(bagId, slotIndex)
        end
    end

    local InventoryGridViewActivated = (FCOIS.otherAddons.inventoryGridViewActive or InventoryGridView ~= nil) or false
    local GridListActivated          = GridList ~= nil

    --If not an equipped item: Get the row's/parent's image -> "Children "Button" of parent
    local parentsImage = parent:GetNamedChild("Button")
    if parentsImage ~= nil then
        --d("parentsImage: " .. parentsImage:GetName())
        local alreadyBoundTexture = "esoui/art/ava/avacapturebar_point_aldmeri.dds"
        local addonName = FCOIS.addonVars.gAddonName
        local setPartAlreadyBoundName = parent:GetName() .. addonName .. "AlreadyBoundIcon"
        if alreadyBoundTexture ~= nil then
            local setPartAlreadyBoundTexture
            setPartAlreadyBoundTexture = wm:GetControlByName(setPartAlreadyBoundName, "")
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
function FCOIS.CreateMarkerControl(parent, markerIconId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped)
--d("[FCOIS]CreateMarkerControl: " .. tostring(parent:GetName()) .. ", markerIconId: " ..tostring(markerIconId) .. ", pHideControl: " ..tostring(pHideControl) ..", pUnequipped: " ..tostring(pUnequipped))
    --No parent? Abort here
    if parent == nil then return nil end
    pArmorTypeIcon = pArmorTypeIcon or false
    pHideControl = pHideControl or false

    local InventoryGridViewActivated = (FCOIS.otherAddons.inventoryGridViewActive or InventoryGridView ~= nil) or false
    local GridListActivated          = GridList ~= nil

    --Preset the variable for control creation with false, if it is not given
    pCreateControlIfNotThere	= pCreateControlIfNotThere or false
    pUpdateAllEquipmentTooltips	= pUpdateAllEquipmentTooltips or false
    --Is the parent's owner control not the quickslot circle?
    if parent:GetOwningWindow() ~= ctrlVars.QUICKSLOT_CIRCLE then
        if pIsEquipmentSlot == nil then pIsEquipmentSlot = false end

        --Does the FCOItemSaver marker control exist already?
        local control = FCOIS.GetItemSaverControl(parent, markerIconId, false)
        local doHide = pHideControl
        --Item got unequipped? Hide all marker textures of the unequipped item
        if pIsEquipmentSlot == true and pUnequipped ~= nil and pUnequipped == true then
--d(">hide: true -> equipment slot got unequipped")
            doHide = true
        end

        local settings = FCOIS.settingsVars.settings
        --Should the control not be hidden? Then check it's marker settings and if a marker is set
        if not doHide then
            --Marker control for a disabled icon? Hide the icon then
            if not settings.isIconEnabled[markerIconId] then
                --Do not hide the texture anymore but do not create it to save memory
                --doHide = true
                return false
            else
                --Control should be shown
                local isItemProtected = checkIfItemIsProtected(markerIconId, myGetItemInstanceId(parent))
                doHide = not isItemProtected
--d(">>checkIfItemIsProtected result: " .. tostring(isItemProtected) .. ", doHide: " ..tostring(doHide))
            end
        end
        if doHide == nil then doHide = false end

        --Remove the sell icon and price if Inventory Grid View or Grid List addons are active
        if parent:GetWidth() - parent:GetHeight() < 5 then
            if parent:GetNamedChild("SellPrice") then
                parent:GetNamedChild("SellPrice"):SetHidden(true)
            end
        end

        --It does not exist yet, so create it now
        if control == parent or not control then
            --Abort here if control should be hiden and is not created yet
            if doHide == true and pCreateControlIfNotThere == false then
                ZO_Tooltips_HideTextTooltip()
                return
            end
            --If not aborted: Create the marker control now
            control = wm:CreateControl(parent:GetName() .. FCOIS.addonVars.gAddonName .. tostring(markerIconId), parent, CT_TEXTURE)
        end
        --Control did already exist or was created now
        if control ~= nil then
            --Hide or show the control now
            control:SetHidden(doHide)
            --Control should be shown?
            if not doHide then
                control:SetTexture(pTexture)
                local iconSettingsColor = settings.icon[markerIconId].color
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
                    control:SetDrawTier(DT_HIGH)
                else
                    control:SetDrawTier(DT_HIGH)
                    control:ClearAnchors()

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
                        local iconOffsetDefinedAtPanel = settings.icon[markerIconId].offsets[LF_INVENTORY]
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
            FCOIS.CreateToolTip(control, markerIconId, doHide, pUpdateAllEquipmentTooltips, pIsEquipmentSlot)
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
        --Todo: Test if creating them "On demand" (if shown, at scrolling) is more performant
        --doCreateMarkerControl = true
        doCreateAllTextures = true
    end
    local iconSettings = FCOIS.settingsVars.settings.icon
    local markerTextureVars = FCOIS.textureVars.MARKER_TEXTURES
    --All inventories
    if (whichTextures == 1 or doCreateAllTextures) then
        --Create textures in inventories
        --for all PLAYER_INVENTORY.inventories do ...
        for _,v in pairs(ctrlVars.playerInventoryInvs) do
            local listView = v.listView
            --Do not hook quest items
            if (listView and listView.dataTypes and listView.dataTypes[1]
                and (listView:GetName() ~= ctrlVars.INVENTORY_QUEST_NAME)) then
                local hookedFunctions = listView.dataTypes[1].setupCallback

                listView.dataTypes[1].setupCallback =
                function(rowControl, slot)
                    hookedFunctions(rowControl, slot)
                    --Do not execute if horse is changed
                    --The current game's SCENE and name (used for determining bank/guild bank deposit)
                    local currentScene, _ = FCOIS.getCurrentSceneInfo()
                    if currentScene ~= STABLES_SCENE then
--d("[FCOIS]PlayerInventory.listView.dataTypes[1].setupCallback")
                        -- for all filters: Create/Update the icons
                        for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                            local iconSettingsOfMarkerIcon = iconSettings[i]
                            --createMarkerControl(parent, controlId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl)
                            createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                        end
                        --Add additional FCO point to the dataEntry.data slot
                        --FCOItemSaver_AddInfoToData(rowControl)
                        --Create and show the "already bound" set parts texture at the top-right edge of the inventory item
                        updateAlreadyBoundTexture(rowControl)
                    end
                end
            end
        end

        --[[
        for _,v in pairs(ctrlVars.playerInventoryInvs) do
            local listView = v.listView
            --Do not hook quest items
            if (listView and listView.dataTypes and listView.dataTypes[1] and (listView:GetName() ~= "ZO_PlayerInventoryQuest")) then
                SecurePostHook(listView.dataTypes[1].setupCallback, function(rowControl, slot)
                    --Do not execute if horse is changed
                    --The current game's SCENE and name (used for determining bank/guild bank deposit)
                    local currentScene, _ = FCOIS.getCurrentSceneInfo()
                    if currentScene ~= STABLES_SCENE then
                        -- for all filters: Create/Update the icons
                        for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                            --createMarkerControl(parent, controlId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl)
                            createMarkerControl(rowControl, i, iconSettings[i].size, iconSettings[i].size, markerTextureVars[iconSettings[i].texture], false, doCreateMarkerControl)
                        end
                        --Add additional FCO point to the dataEntry.data slot
                        --FCOItemSaver_AddInfoToData(rowControl)
                        --Create and show the "already bound" set parts texture at the top-right edge of the inventory item
                        updateAlreadyBoundTexture(rowControl)
                    end
                end)
            end
        end
        ]]
    end
     --Repair list
    if (whichTextures == 2 or doCreateAllTextures) then
        --Create textures in repair window
        local listView = ctrlVars.REPAIR_LIST
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
            function(rowControl, slot)
                hookedFunctions(rowControl, slot)

                --Do not execute if horse is changed
                --The current game's SCENE and name (used for determining bank/guild bank deposit)
                local currentScene, _ = FCOIS.getCurrentSceneInfo()
                if currentScene ~= STABLES_SCENE then
                    -- for all filters: Create/Update the icons
                    for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        local iconSettingsOfMarkerIcon = iconSettings[i]
                        createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                    end
                    --Add additional FCO point to the dataEntry.data slot
                    --FCOItemSaver_AddInfoToData(rowControl)
                end
            end
        end
    end
    --Player character / Companion character
    if (whichTextures == 3 or doCreateAllTextures) then
        -- Marker function for character equipment if character window is shown
        if ((isCharacterShown() or isCompanionCharacterShown()) or FCOIS.addonVars.gAddonLoaded == false) then
            FCOIS.RefreshEquipmentControl(nil, nil, nil, nil, true, nil)
        end
    end
    --Quickslot
    if (whichTextures == 4 or doCreateAllTextures) then
        -- Marker function for quickslots inventory
        local listView = ctrlVars.QUICKSLOT_LIST
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
            function(rowControl, slot)
                hookedFunctions(rowControl, slot)

                --Do not execute if horse is changed
                --The current game's SCENE and name (used for determining bank/guild bank deposit)
                local currentScene, _ = FCOIS.getCurrentSceneInfo()
                if currentScene ~= STABLES_SCENE then
                    -- for all filters: Create/Update the icons
                    for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        local iconSettingsOfMarkerIcon = iconSettings[i]
                        createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
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
        local listView = ctrlVars.RETRAIT_LIST
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
            function(rowControl, slot)
                hookedFunctions(rowControl, slot)

                --Do not execute if horse is changed
                --The current game's SCENE and name (used for determining bank/guild bank deposit)
                local currentScene, _ = FCOIS.getCurrentSceneInfo()
                if currentScene ~= STABLES_SCENE then
                    -- for all filters: Create/Update the icons
                    for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        local iconSettingsOfMarkerIcon = iconSettings[i]
                        createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
                    end
                    --Add additional FCO point to the dataEntry.data slot
                    --FCOItemSaver_AddInfoToData(rowControl)
                end
            end
        end
    end
    --Companion inventory
    if (whichTextures == 6 or doCreateAllTextures) then
        -- Marker function for companion inventory
        local listView = ctrlVars.COMPANION_INV_LIST
        --ZO_CompanionEquipment_Panel_KeyboardList1Row1
        if listView and listView.dataTypes and listView.dataTypes[1] then
            local hookedFunctions = listView.dataTypes[1].setupCallback

            listView.dataTypes[1].setupCallback =
            function(rowControl, slot)
                hookedFunctions(rowControl, slot)

                --Do not execute if horse is changed
                --The current game's SCENE and name (used for determining bank/guild bank deposit)
                local currentScene, _ = FCOIS.getCurrentSceneInfo()
                if currentScene ~= STABLES_SCENE then
                    --Workaround for the companion equipment inventory fragment's StateChange!
                    --The OnShowing will happen AFTER the inventory rows are updated. See file src/FCOIS_Hooks.lua,
                    --ctrlVars.COMPANION_INV_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
                    --Thus the filterPanelId is still on LF_INVENTORY and some panel checks for the dynamic marker icons, but
                    --also the static ones, will be handled incorrectly! To circumvent this set the filterPanelId here each
                    --time the inventory rows are updated!
                    --This value will be reset via the companion keyboard fragment stateChange to hide or hidden
                    FCOIS.gFilterWhere = LF_INVENTORY_COMPANION

                    -- for all filters: Create/Update the icons
                    for i=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        local iconSettingsOfMarkerIcon = iconSettings[i]
                        createMarkerControl(rowControl, i, iconSettingsOfMarkerIcon.size, iconSettingsOfMarkerIcon.size, markerTextureVars[iconSettingsOfMarkerIcon.texture], false, doCreateMarkerControl)
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
    if doDebug then FCOIS.debugMessage( "[checkMarker]","MarkerId: " .. tostring(markerId) .. ", CheckNow: " .. tostring(FCOIS.preventerVars.gUpdateMarkersNow) .. ", Gears changed: " .. tostring(FCOIS.preventerVars.gChangedGears), true, FCOIS_DEBUG_DEPTH_ALL) end

    --Should we update the marker textures, size and color?
    if FCOIS.preventerVars.gUpdateMarkersNow == true or FCOIS.preventerVars.gChangedGears == true then
        --Update the textures now
        FCOIS.RefreshBasics()

        if not FCOIS.preventerVars.gChangedGears then
            zo_callLater(function()
                --d("character hidden: " .. tostring(ctrlVars.CHARACTER:IsHidden()))
                if isCharacterShown() or isCompanionCharacterShown() then
                    FCOIS.RefreshEquipmentControl()
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
function FCOIS.checkAndClearLastMarkedIcons(bagId, slotIndex)
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
function FCOIS.checkIfClearOrRestoreAllMarkers(clickedRow, modifierKeyPressed, upInside, mouseButton, refreshPopupDialogButons, calledByKeybind)
    calledByKeybind = calledByKeybind or false
    --Enable clearing all markers by help of the SHIFT+right click?
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
--d("[FCOIS.checkIfClearOrRestoreAllMarkers]shiftKey: " ..tostring(IsShiftKeyDown()) .. ", upInside: " .. tostring(upInside) .. ", mouseButton: " .. tostring(mouseButton) .. ", setinGEnabled: " ..tostring(contextMenuClearMarkesByShiftKey))
    if ( modifierKeyPressed == true and contextMenuClearMarkesByShiftKey ) and  (calledByKeybind == true or (upInside and mouseButton == MOUSE_BUTTON_INDEX_RIGHT))  then
        refreshPopupDialogButons = refreshPopupDialogButons or false
        -- make sure control contains an item
        local bagId, slotIndex = myGetItemDetails(clickedRow)
        if bagId ~= nil and slotIndex ~= nil then
--d("[FCOIS] Clearing/Restoring all markers of the current item now! bag: " .. bagId .. ", slotIndex: " .. slotIndex .. " " .. GetItemLink(bagId, slotIndex))
            --Set the preventer variable now to suppress the context menu of inventory items
            if not calledByKeybind then
--d(">NO KEYBIND call: enabling dontShowInvContextMenu: true ")
                FCOIS.preventerVars.dontShowInvContextMenu = true
            end
--d("[FCOIS]checkIfClearOrRestoreAllMarkers - dontShowInvContextMenu: true")
            --Clear/Restore the markers now
            FCOIS.ClearOrRestoreAllMarkers(clickedRow, bagId, slotIndex)
            if refreshPopupDialogButons then
                --Unselect the item and disable the button of the popup dialog again
--d("[FCOIS]checkIfClearOrRestoreAllMarkers - refreshPopupDialog now")
                FCOIS.RefreshPopupDialogButtons(clickedRow, false)
            end
            --Is the character shown, then disable the context menu "hide" variable again as the order of hooks is not
            --the same like in the inventory and the context menu will be hidden twice in a row else!
            -->Only if no ZO_Dialog is used, as the variable FCOIS.preventerVars.dontShowInvContextMenu will be needed
            -->in the calling row hook of the ZO_ListDialog, and reset to false there!
            if not calledByKeybind and not refreshPopupDialogButons then
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

--Called per keybind: Get the current row the mouse is above and then remove or restore all marker icons
function FCOIS.RemoveAllMarkerIconsOrUndo()
--d("[FCOIS]RemoveAllMarkerIconsOrUndo")
    local mouseOverControl = wm:GetMouseOverControl()
    if mouseOverControl ~= nil then
        local contextMenuClearMarkesKey = FCOIS.settingsVars.settings.contextMenuClearMarkesModifierKey
        local isModifierKeyPressed = FCOIS.IsModifierKeyPressed(contextMenuClearMarkesKey)
        local refreshPopupDialogButons = FCOIS.preventerVars.isZoDialogContextMenu
--d(">mouseOverControl: " ..tostring(mouseOverControl:GetName()) ..", isModifierKeyPressed: " .. tostring(isModifierKeyPressed) .. ", refreshPopupDialogButons: " ..tostring(refreshPopupDialogButons))
        FCOIS.checkIfClearOrRestoreAllMarkers(mouseOverControl, isModifierKeyPressed, nil, nil, refreshPopupDialogButons, true) -- calledByKeybind = true
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
    if settings.debug then FCOIS.debugMessage( "[AddArmorTypeIconToEquipmentSlot]","EquipmentSlot: " .. equipmentSlotName .. ", armorType: " .. tostring(armorType), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

    local isCompanionCharacter = (equipmentSlotControl:GetParent() == ctrlVars.COMPANION_CHARACTER) or false
--d(">equipmentSlotName: " ..tostring(equipmentSlotName) .. ", isCompanionCharacter: " ..tostring(isCompanionCharacter))

    local armorTypeLabel = wm:GetControlByName("FCOIS_" .. equipmentSlotName .. "_ArmorTypeLabel")
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
local function updateEquipmentHeaderCountText(updateWhere)
    local isCompanionCharacter = (updateWhere == "companion_character") or false
    if isCompanionCharacter == true then
        --Check all equipment controls -> Companion
        if not isCompanionCharacterShown() then return end
    end

    local showArmorTypeHeaderTextAtCharacter = FCOIS.settingsVars.settings.showArmorTypeHeaderTextAtCharacter
    local updateWhereToCharacterApparelSection = mappingVars.characterApparelSection
    local charApparelSectionCtrl = updateWhereToCharacterApparelSection[updateWhere]
    if not charApparelSectionCtrl then return end

    if not showArmorTypeHeaderTextAtCharacter then
        charApparelSectionCtrl:SetText(GetString(SI_CHARACTER_EQUIP_SECTION_APPAREL))
        return
    end
    local countVars = FCOIS.countVars
    local locVars = FCOIS.localizationVars.fcois_loc
    if isCompanionCharacter == true then
        if countVars.countCompanionLightArmor ~= nil or countVars.countCompanionMediumArmor ~= nil or countVars.countCompanionHeavyArmor ~= nil then
            charApparelSectionCtrl:SetText(GetString(SI_CHARACTER_EQUIP_SECTION_APPAREL) .. " (" .. locVars["options_armor_type_icon_light_short"] .. ": " .. countVars.countCompanionLightArmor .. ", " .. locVars["options_armor_type_icon_medium_short"] .. ": " .. countVars.countCompanionMediumArmor .. ", " .. locVars["options_armor_type_icon_heavy_short"] .. ": " .. countVars.countCompanionHeavyArmor .. ")")
        end
    else
        if countVars.countLightArmor ~= nil or countVars.countMediumArmor ~= nil or countVars.countHeavyArmor ~= nil then
            charApparelSectionCtrl:SetText(GetString(SI_CHARACTER_EQUIP_SECTION_APPAREL) .. " (" .. locVars["options_armor_type_icon_light_short"] .. ": " .. countVars.countLightArmor .. ", " .. locVars["options_armor_type_icon_medium_short"] .. ": " .. countVars.countMediumArmor .. ", " .. locVars["options_armor_type_icon_heavy_short"] .. ": " .. countVars.countHeavyArmor .. ")")
        end
    end
end

--function to count and update the equipped armor parts of character and companion and to add the marker texture controls to the
--equipment slots via function FCOIS.RefreshEquipmentControl, if the function FCOIS.RefreshEquipmentControl was called without
--any equipmentSlot control, markerIconId etc., but parameter updateIfCharacterNotShown = true
function FCOIS.countAndUpdateEquippedArmorTypes(doRefreshControl, doCreateMarkerControl, markerIconId, updateIfCharacterNotShown)
--d("[FCOIS]countAndUpdateEquippedArmorTypes - doRefreshControl: " ..tostring(doRefreshControl) .. ", markerIconId: " ..tostring(markerIconId))
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
            equipmentSlotControl = wm:GetControlByName(equipmentSlotName, "")
            if equipmentSlotControl ~= nil then
                --Refresh each equipped item's marker icons
                if doRefreshControl then
                    FCOIS.RefreshEquipmentControl(equipmentSlotControl, doCreateMarkerControl, markerIconId, false, updateIfCharacterNotShown)
                end

                --Show the armor type icons at the player doll?
                AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, FCOIS.GetArmorType(equipmentSlotControl))
            end
        end
        --Update the equipment header text and show the amount of armor types equipped
        updateEquipmentHeaderCountText("character")
    end
    ------------------------------------------------------------------------------------------------------------------------
    --Check all equipment controls -> Companion
    if isCompanionCharacter == true then
--d(">companion character")
        equipmentSlotControl = nil
        local companionCharacterEquipmentSlotNameByIndex = mappingVars.companionCharacterEquipmentSlotNameByIndex
        for _, equipmentSlotName in pairs(companionCharacterEquipmentSlotNameByIndex) do
            --Get the control of the equipment slot
            equipmentSlotControl = wm:GetControlByName(equipmentSlotName, "")
            if equipmentSlotControl ~= nil then
                --Refresh each equipped item's marker icons
                if doRefreshControl then
                    FCOIS.RefreshEquipmentControl(equipmentSlotControl, doCreateMarkerControl, markerIconId, false, updateIfCharacterNotShown)
                end

                --Show the armor type icons at the player doll?
                AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, FCOIS.GetArmorType(equipmentSlotControl))
            end
        end
        --Update the equipment header text and show the amount of armor types equipped
        updateEquipmentHeaderCountText("companion_character")
    end
end
local countAndUpdateEquippedArmorTypes = FCOIS.countAndUpdateEquippedArmorTypes

--Remove the armor type marker from character doll
function FCOIS.removeArmorTypeMarker(bagId, slotId)
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
    local equipmentSlotControl = wm:GetControlByName(equipmentSlotControlName, "")
    if equipmentSlotControl == nil then return false end

    --Check slightly delayed if item is (still) equipped
    --as drag&drop the icon to its previous position will call this funciton here too
    zo_callLater(function()
        if equipmentSlotControl.stackCount == 0 then
            --Hide the text control showing the armor type for this equipment slot
            local armorTypeLabel = wm:GetControlByName("FCOIS_" .. equipmentSlotControl:GetName() .. "_ArmorTypeLabel")
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
function FCOIS.checkWeaponOffHand(controlName, weaponTypeName, doCheckOffHand, doCheckBackupOffHand, echo)
--d("[FCOIS]checkWeaponOffHand")
    if echo then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[checkWeaponOffHand]", "ControlName: " .. controlName ..", WeaponTypeName: " .. weaponTypeName, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    end
    local weaponControl
    local weaponType
    local characterEquipmentSlotNameByIndex = mappingVars.characterEquipmentSlotNameByIndex

    --Check the offhand?
    if doCheckOffHand == true then
--d(">doCheckOffHand")
        if (controlName == characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]) then -- 'ZO_CharacterEquipmentSlotsOffHand'
            --Check if the weapon in the main slot is a 2hd weapon/staff
            weaponControl = wm:GetControlByName(characterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND], "") --"ZO_CharacterEquipmentSlotsMainHand"
            if weaponControl ~= nil then
--d(">found weapon at main hand: " ..GetItemLink(weaponControl.bagId, weaponControl.slotIndex))
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
            weaponControl = wm:GetControlByName(characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN], "") -- "ZO_CharacterEquipmentSlotsBackupMain"
            if weaponControl ~= nil then
--d(">found weapon at backup main hand: " ..GetItemLink(weaponControl.bagId, weaponControl.slotIndex))
                weaponType = GetItemWeaponType(weaponControl.bagId, weaponControl.slotIndex)
                if (weaponType ~= nil) then
                    return checkWeaponType(weaponType, weaponTypeName)
                end
            end
        end
    end

    return false
end
local checkWeaponOffHand = FCOIS.checkWeaponOffHand


--Function to check empty weapon slots (Main & Offhand) and remove markers. Needed a delay ~1200ms to work properly before
--Blackwood PTS API100035. Now the value can be lowered to 150ms
function FCOIS.RemoveEmptyWeaponEquipmentMarkers(delay)
    --If he delay is below ??? the marker icons at backup weapon slots won't be removed properly e.g. as you drag&drop/doubleclick
    --a 2hd weapon and 2x1hd weapons were equipped. Backup weapon (2nd 1hd) got a marker icon which will stay at the 2nd weapon then!
    delay = delay or 150
--d("[FCOIS]RemoveEmptyWeaponEquipmentMarkers - delay: " .. tostring(delay))
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
            if settings.debug then FCOIS.debugMessage( "[RemoveEmptyWeaponEquipmentMarkers]","equipmentControl: " .. equipmentControlName ..", delay: " .. delay, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d(">>equipmentControl: " .. tostring(equipmentControlName))
            if equipmentControlName ~= nil and equipmentControlName ~= "" then
                local equipmentControl = wm:GetControlByName(equipmentControlName, "")
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
                        local width = settings.iconSizeCharacter or equipVars.gEquipmentIconWidth
                        local height = settings.iconSizeCharacter or equipVars.gEquipmentIconHeight
                        for markerIconId=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                            --Last parameter = doHide (true)
                            createMarkerControl(equipmentControl, markerIconId, width, height, texVars.MARKER_TEXTURES[settings.icon[markerIconId].texture], true, false, false, false, true)
                        end
                    end
                end
            end
        end
    end, delay)
end
local removeEmptyWeaponEquipmentMarkers = FCOIS.RemoveEmptyWeaponEquipmentMarkers

--The function to refresh the equipped items and their markers
function FCOIS.RefreshEquipmentControl(equipmentControl, doCreateMarkerControl, p_markId, dontCheckRings, updateIfCharacterNotShown, unequipped)
--d("[FCOIS]RefreshEquipmentControl-doCreateMarkerControl: " ..tostring(doCreateMarkerControl) .. ", unequipped: " ..tostring(unequipped))
    dontCheckRings = dontCheckRings or false
    --Preset the value for "Create control if not existing yet" with false
    doCreateMarkerControl = doCreateMarkerControl or false
    updateIfCharacterNotShown = updateIfCharacterNotShown or false
    unequipped = unequipped or false
    local isCharacter = isCharacterShown()
    local isCompanionCharacter = isCompanionCharacterShown()
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
            if settings.debug then FCOIS.debugMessage( "[RefreshEquipmentControl]","Control: " .. equipmentControl:GetName() .. ", Create: " .. tostring(doCreateMarkerControl) .. ", MarkId: ALL", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Add/Update the markers for the filter icons at the equipment slot
            hideControl = false
            for markerIconId=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                --parent, markerIconId, pWidth, pHeight, pTexture, pIsEquipmentSlot, pCreateControlIfNotThere, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped
                createMarkerControl(equipmentControl, markerIconId, width, height, texVars.MARKER_TEXTURES[settings.icon[markerIconId].texture], true, doCreateMarkerControl, hideControl, nil, nil, unequipped)
            end
        --Only check a specific marker id
        else
--d(">checkMarkerIcon: " ..tostring(p_markId))
            if settings.debug then FCOIS.debugMessage( "[RefreshEquipmentControl]","Control: " .. equipmentControl:GetName() .. ", Create: " .. tostring(doCreateMarkerControl) .. ", MarkId: " .. tostring(p_markId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            hideControl = true
            --Add/Update the marker p_markId for the filter icons at the equipment slot
            createMarkerControl(equipmentControl, p_markId, width, height, texVars.MARKER_TEXTURES[settings.icon[p_markId].texture], true, doCreateMarkerControl, hideControl, nil, nil, unequipped)
        end

        --Are we chaning equipped weapons? Update the markers and remove 2hd weapon markers
        local equipControlName = equipmentControl:GetName()
        if equipControlName ~= nil and equipControlName ~= "" then
--d("[FCOIS.RefreshEquipmentControl] name: " ..tostring(equipControlName))
            if checkVars.allowedCharacterEquipmentWeaponControlNames[equipControlName] then
                --Check if the offhand weapons are 2hd weapons and remove the markers then
                removeEmptyWeaponEquipmentMarkers()
            end

            --Is the equipment slot a ring? Then check if the same ring is equipped at the other slot and update the marker icon visibility too
            --But not if the 1st ring got unequipped, as the marker icon on still equipped rings need to be kept!
            local isRing = (not dontCheckRings and checkVars.allowedCharacterEquipmentJewelryRingControlNames[equipControlName]) or false
--d(">isRing: " ..tostring(isRing))
            if isRing == true and not unequipped  then
                local bag, slot = myGetItemDetails(equipmentControl)
--d(">bag: " ..tostring(bag) .. ", slotIndex: " ..tostring(slot))
                if bag == nil or slot == nil then return false end
                --Most unequips fail here as the slot got no data anymore and thus the itemId will be nil! This is why unequipping was disabled at the isring == true and not unequipped check!
                local itemId = myGetItemInstanceIdNoControl(bag, slot, true)
--d(">itemId: " ..tostring(itemId))
                if itemId == nil then return false end
                local isRingMarked, _ = FCOIS.IsMarked(bag, slot, -1)
                local doHide = not isRingMarked
--d(">doHide: " ..tostring(doHide))
                --Get the other ring
                local mappingOfRings = mappingVars.equipmentJewelryRing2RingSlot
                local otherRingSlotName = mappingOfRings[equipControlName]
--d(">otherRingSlotName: " ..tostring(otherRingSlotName))
                local otherRingControl = wm:GetControlByName(otherRingSlotName, "")
                --Compare the item Ids/Unique itemIds (if enabled)
                if otherRingControl ~= nil and otherRingControl:IsHidden() == false then
                    --Get the bag and slot
                    local bagRing2, slotRing2 = myGetItemDetails(otherRingControl)
                    if bagRing2 ~= nil and slotRing2 ~= nil then
                        --Get the itemId and compare it with the other ring
                        local itemIdOtherRing = myGetItemInstanceIdNoControl(bagRing2, slotRing2, true)
--d(">>other ring, itemId: " .. tostring(itemIdOtherRing) ..", " .. GetItemLink(bagRing2, slotRing2))
                        if itemId == itemIdOtherRing then
                            --local doMarkRing = not doHide
                            --Marking of ring is not needed as it was marked already and the itemInstaceId/uniqueId should be the same ->
                            --Thus marks will be "visible" after refreshing the slot's marker control!
                            --FCOIS.MarkItem(bagRing2, slotRing2, p_markId, doMarkRing, false)
                            --Update the texture, create it if not there yet

                            --!!!ATTENTION!!! Recursive call of function, so set 4th parameter "dontCheckRings" = true to prevent endless loop between ring1->ring2->ring1->...!
                            FCOIS.RefreshEquipmentControl(otherRingControl, true, p_markId, true, updateIfCharacterNotShown, unequipped)
                        end
                    end
                end
            end
        end

    --Equipment control is not given yet, or unknown
    else
        if settings.debug then FCOIS.debugMessage( "[RefreshEquipmentControl]","ALL CONTROLS! Create: " .. tostring(doCreateMarkerControl) .. ", MarkId: " .. tostring(p_markId), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
        --[[
        --Reset the armor type counters
        resetCharacterArmorTypeNumbers()

        --Check all equipment controls
        local equipmentSlotControl
        for _, equipmentSlotName in pairs(mappingVars.characterEquipmentSlotNameByIndex) do
            --Get the control of the equipment slot
            equipmentSlotControl = wm:GetControlByName(equipmentSlotName, "")
            if equipmentSlotControl ~= nil then
                --Refresh each equipped item's marker icons
                FCOIS.RefreshEquipmentControl(equipmentSlotControl, doCreateMarkerControl, p_markId)
                --Show the armor type icons at the player doll?
                AddArmorTypeIconToEquipmentSlot(equipmentSlotControl, FCOIS.GetArmorType(equipmentSlotControl))
            end
        end

        --Update the equipment header text and show the amount of armor types equipped
        updateEquipmentHeaderCountText()
        ]]
        countAndUpdateEquippedArmorTypes(true, doCreateMarkerControl, p_markId, updateIfCharacterNotShown)
    end
end
local refreshEquipmentControl = FCOIS.RefreshEquipmentControl

--Update one specific equipment slot by help of the slotIndex
function FCOIS.updateEquipmentSlotMarker(slotIndex, delay, unequipped)
--d("[FCOIS]updateEquipmentSlotMarker-slotIndex: " ..tostring(slotIndex).. ", delay: " ..tostring(delay) .. ", unequipped: " ..tostring(unequipped))
    --Only execute if character window is shown
    if slotIndex ~= nil then
        delay = delay or 0
        if delay > 0 then
            zo_callLater(function()
                FCOIS.updateEquipmentSlotMarker(slotIndex, 0, unequipped)
            end, delay)
        else
            local isCharacter = isCharacterShown()
            local isCompanionCharacter = isCompanionCharacterShown()
--d(">isCharacter: " ..tostring(isCharacter) .. ", isCompanionCharacter: " ..tostring(isCompanionCharacter))
            if not isCharacter and not isCompanionCharacter then return end

            local armorSlots = mappingVars.characterEquipmentArmorSlots

            local equipSlotControlName
            if isCompanionCharacter == true then
                equipSlotControlName = mappingVars.companionCharacterEquipmentSlotNameByIndex[slotIndex]
            else
                equipSlotControlName = mappingVars.characterEquipmentSlotNameByIndex[slotIndex]
            end
--d(">equipSlotControlName: " ..tostring(equipSlotControlName))
            --Get the equipment control by help of the slotIndex
            local equipSlotControl
            if equipSlotControlName ~= nil and equipSlotControlName ~= "" then
                if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[updateEquipmentSlotMarker]","control name="..equipSlotControlName..", slotIndex: " .. slotIndex, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                equipSlotControl = wm:GetControlByName(equipSlotControlName, "")
--d(">>isHidden: " ..tostring(equipSlotControl:IsHidden()))
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

--The callback function for the right click/context menus to mark all equipment items with one click
function FCOIS.MarkAllEquipment(rowControl, markId, updateNow, doHide)
    if FCOIS.gFilterWhere == nil then return end

    local isCharacter = isCharacterShown()
    local isCompanionCharacter = isCompanionCharacterShown()
    if not isCharacter and not isCompanionCharacter then return end

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
--d("[FCOIS.MarkAllEquipment]equipmentSlotName: " ..tostring(equipmentSlotName))
        if settings.debug then FCOIS.debugMessage( "[MarkAllEquipment]","MarkId: " .. tostring(markId) .. ", EquipmentSlot: "..equipmentSlotName..", no_auto_mark: " .. tostring(checkVars.equipmentSlotsNames["no_auto_mark"][equipmentSlotName])) end
        --Is the current equipment slot a changeable one?
        if string.find(equipmentSlotName, equipmentSlotsCtrlName) then
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
                    if doHide == true then
                        FCOIS.MarkItem(bag, slot, markId, false, false)
                    else
                        FCOIS.MarkItem(bag, slot, markId, true, false)
                    end
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
        local ringControl1 = ringEquipmentControlsTable[EQUIP_SLOT_RING1] ~= nil and wm:GetControlByName(ringEquipmentControlsTable[EQUIP_SLOT_RING1])
        if ringControl1 ~= nil then
            refreshEquipmentControl(ringControl1, p_doMark,  p_markId, nil, nil, nil)
        end
        local ringControl2 = ringEquipmentControlsTable[EQUIP_SLOT_RING2] ~= nil and wm:GetControlByName(ringEquipmentControlsTable[EQUIP_SLOT_RING2])
        if ringControl2 ~= nil then
            refreshEquipmentControl(ringControl2, p_doMark,  p_markId, nil, nil, nil)
        end
    end
end
local checkIfCharOrInvNeedsRingUpdate = FCOIS.CheckIfCharOrInvNeedsRingUpdate


--Clear all current markers of the selected row, or restore all marker icons from the undo table
function FCOIS.ClearOrRestoreAllMarkers(rowControl, bagId, slotIndex)
--d("[FCOIS]ClearOrRestoreAllMarkers")
    if rowControl == nil then return end
    if bagId == nil or slotIndex == nil then
        bagId, slotIndex = myGetItemDetails(rowControl)
    end
    if bagId == nil or slotIndex == nil then return false end
    local isCharacterShownVar          = (bagId == BAG_WORN and isCharacterShown()) or false
    local isCompanionCharacterShownVar = (bagId == BAG_COMPANION_WORN and isCompanionCharacterShown()) or false
    local lastMarkedIcons              = FCOIS.lastMarkedIcons
    FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = false
    FCOIS.preventerVars.gRestoringMarkerIcons = false
    FCOIS.preventerVars.gClearingMarkerIcons = false
    --Get the item's itemInstanceId (FCOIS style) and check if there are any marker icons saved in the undo list
    local fcoisItemInstanceId = myGetItemInstanceId(rowControl, true)
    local itemLink = GetItemLink(bagId, slotIndex)
--d(">item: " .. itemLink .. ", itemInstanceId FCOIS: " ..tostring(fcoisItemInstanceId))
    if fcoisItemInstanceId ~= nil then
        local alreadyRemovedMarkersForThatBagAndItem = (lastMarkedIcons ~= nil and lastMarkedIcons[fcoisItemInstanceId]) or nil
        if alreadyRemovedMarkersForThatBagAndItem ~= nil then

            --Marker icons were removed already for this item in this bag, so restore them now
            --Restore saved markers for the current item?
            local loc_counter = 1
            for iconId, iconIsMarked in pairs(alreadyRemovedMarkersForThatBagAndItem) do
                --Reset all markers
                --Refresh the control now to update the set marker icons?
                local refreshNow = isCharacterShownVar or isCompanionCharacterShownVar or FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem
    --d(">iconId: " ..tostring(iconId) .. ", isMarked: " .. tostring(iconIsMarked) .. ", refreshNow: " ..tostring(refreshNow))
                --Set global preventer variable so no other marker icons will be set/removed during the restore
                FCOIS.preventerVars.gRestoringMarkerIcons = true
                --FCOIS.MarkItem(bagId, slotIndex, iconId, iconIsMarked, refreshNow)
                --FCOIS.preventerVars.markerIconChangedManually = true
                FCOIS.MarkItemByItemInstanceId(fcoisItemInstanceId, iconId, iconIsMarked, itemLink, nil, nil, refreshNow)
                --Reset the global preventer variable
                FCOIS.preventerVars.gRestoringMarkerIcons = false
                --Check if the item mark removed other marks and if a row within another addon (like Inventory Insight) needs to be updated
                FCOIS.checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate(rowControl, iconId)
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

            --Marker icons were not removed yet for this item in this bag.
            --So remove them now
            --Clear all markers of current item
            --local itemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
            --Return false for marked icons, where the icon id is disabled in the settings
            FCOIS.preventerVars.doFalseOverride = true
            --local _, currentMarkedIcons = FCOIS.IsMarked(bagId, slotIndex, -1)
            local _, currentMarkedIcons = FCOIS.IsMarkedByItemInstanceId(fcoisItemInstanceId, -1, nil, nil)
            --Reset to normal return values for marked & en-/disabled icons now
            FCOIS.preventerVars.doFalseOverride = false
            --For each marked icon of the currently improved item:
            --Set the icons/markers of the previous item again
            if currentMarkedIcons and #currentMarkedIcons > 0 then
                --Build the backup array with normal marked icons now
                --local _, currentMarkedIconsUnchanged = FCOIS.IsMarked(bagId, slotIndex, -1)
                local currentMarkedIconsUnchanged = ZO_DeepTableCopy(currentMarkedIcons)
                --Create the arrays if any marker icon is set currently
                FCOIS.lastMarkedIcons = FCOIS.lastMarkedIcons or {}
                FCOIS.lastMarkedIcons[fcoisItemInstanceId] = FCOIS.lastMarkedIcons[fcoisItemInstanceId] or {}
                --Counter vars
                local loc_counter = 1
                local loc_marked_counter = 0
                local iconIdsToBackup = {}
                --Loop over each of the marker icons and remove them
                for iconId, iconIsMarked in pairs(currentMarkedIcons) do
    --d(">iconId: " .. tostring(iconId) .. ", loc_counter: " .. tostring(loc_counter))
                    --Only go on if item is marked or is the last marker (to update the inventory afterwards)
                    if iconIsMarked == true then
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
--d(">removing marker icon: " .. tostring(iconId))
                    --Set global preventer variable so no other marker icons will be set/removed during the clear
                    FCOIS.preventerVars.gClearingMarkerIcons = true
                    --FCOIS.MarkItem(bagId, slotIndex, iconId, false, refreshNow)
                    FCOIS.MarkItemByItemInstanceId(fcoisItemInstanceId, iconIdsToBackup, false, itemLink, nil, nil, refreshNow)
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
    end

    --[[ OLD- Use Bag and SlotId- Fails if the slotIndices change in the bags!
    --Restore temporarily saved marker icons
    if lastMarkedIcons ~= nil and lastMarkedIcons[bagId] ~= nil and lastMarkedIcons[bagId][slotIndex] ~= nil then
--d("restore - bag: " .. bagId .. ", slotIndex: " .. slotIndex .. " " .. GetItemLink(bagId, slotIndex))
        --Restore saved markers for the current item?
        local loc_counter = 1
        local lastMarkedIconsToRestore = lastMarkedIcons[bagId][slotIndex]
        for iconId, iconIsMarked in pairs(lastMarkedIconsToRestore) do
            --Reset all markers
            --Refresh the control now to update the set marker icons?
            local refreshNow = isCharacterShown or FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem
--d(">iconId: " ..tostring(iconId) .. ", isMarked: " .. tostring(iconIsMarked) .. ", refreshNow: " ..tostring(refreshNow))
            --Set global preventer variable so no other marker icons will be set/removed during the restore
            FCOIS.preventerVars.gRestoringMarkerIcons = true
            FCOIS.MarkItem(bagId, slotIndex, iconId, iconIsMarked, refreshNow)
            --Reset the global preventer variable
            FCOIS.preventerVars.gRestoringMarkerIcons = false
            --Check if the item needs to be removed from a craft slot or the guild store sell tab now
            isItemProtectedAtASlotNow(bagId, slotIndex, false, true)
            loc_counter = loc_counter + 1
        end
        --Reset the last saved marker array for the current item
        lastMarkedIcons[bagId][slotIndex] = nil
        FCOIS.lastMarkedIcons[bagId][slotIndex] = nil
        if loc_counter > 1 then
            --Refresh the inventory list now to hide removed marker icons
            filterBasics(false)
        end

    --Clear all marker icons
    else
--d("clear")
        --Clear all markers of current item
        --local itemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
        --Return false for marked icons, where the icon id is disabled in the settings
        FCOIS.preventerVars.doFalseOverride = true
        local _, currentMarkedIcons = FCOIS.IsMarked(bagId, slotIndex, -1)
        --Reset to normal return values for marked & en-/disabled icons now
        FCOIS.preventerVars.doFalseOverride = false
        --For each marked icon of the currently improved item:
        --Set the icons/markers of the previous item again
        if currentMarkedIcons and #currentMarkedIcons > 0 then
            --Build the backup array with normal marked icons now
            --local _, currentMarkedIconsUnchanged = FCOIS.IsMarked(bagId, slotIndex, -1)
            local currentMarkedIconsUnchanged = ZO_DeepTableCopy(currentMarkedIcons)
            --Create the arrays if any marker icon is set currently
            FCOIS.lastMarkedIcons = FCOIS.lastMarkedIcons or {}
            FCOIS.lastMarkedIcons[bagId] = FCOIS.lastMarkedIcons[bagId] or {}
            FCOIS.lastMarkedIcons[bagId][slotIndex] = FCOIS.lastMarkedIcons[bagId][slotIndex] or {}
            --Counter vars
            local loc_counter = 1
            local loc_marked_counter = 0
            --Loop over each of the marker icons and remove them
            for iconId, iconIsMarked in pairs(currentMarkedIcons) do
--d(">iconId: " .. tostring(iconId) .. ", loc_counter: " .. tostring(loc_counter))
                --Only go on if item is marked or is the last marker (to update the inventory afterwards)
                if iconIsMarked then
                    loc_marked_counter = loc_marked_counter + 1
                    --Refresh the control now to update the cleared marker icons?
                    local refreshNow = isCharacterShown or FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem
                    --Remove marker icon
--d(">removing marker icon: " .. tostring(iconId))
                    --Set global preventer variable so no other marker icons will be set/removed during the clear
                    FCOIS.preventerVars.gClearingMarkerIcons = true
                    FCOIS.MarkItem(bagId, slotIndex, iconId, false, refreshNow)
                    --Reset the global preventer variable
                    FCOIS.preventerVars.gClearingMarkerIcons = false
                end
                loc_counter = loc_counter + 1
            end
            --Only save the last active marker icons if any marker icon was removed
            if loc_marked_counter > 0 then
                FCOIS.lastMarkedIcons[bagId][slotIndex] = currentMarkedIconsUnchanged
                --Refresh the inventory list now to hide removed marker icons
                filterBasics(false)
            end
        end
    end
    ]]
    FCOIS.preventerVars.gRestoringMarkerIcons = false
    FCOIS.preventerVars.gClearingMarkerIcons = false
end