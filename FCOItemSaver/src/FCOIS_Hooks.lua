--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local ctrlVars = FCOIS.ZOControlVars
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
--LibCustomMenu
local lcm = FCOIS.LCM

--==========================================================================================================================================
--									FCOIS Pre-Hooks & Hooks / Scene & Fragment callback functions
--==========================================================================================================================================

--==============================================================================
	--TEST hooks
--==============================================================================
function FCOIS.testHooks(activateTestHooks)
    if activateTestHooks ~= nil and type(activateTestHooks) == "boolean" then
		FCOIS.settingsVars.settings.testHooks = activateTestHooks
    else
		--Toggle the testhooks savedvars variable
		FCOIS.settingsVars.settings.testHooks = not FCOIS.settingsVars.settings.testHooks
    end
    --Show the test hooks variable
    d("[FCOIS] Test hooks: " .. tostring(FCOIS.settingsVars.settings.testHooks))
	--Reload the UI
    ReloadUI()
end

--[[
local function callTestHooks(activateTestHooks)
	--Change to a true to activate the tets hooks!
	activateTestHooks = activateTestHooks or false

	--Abort test hooks?
    if not activateTestHooks then return end

	--The test hooks start below:
--------------------------------------------------------------------------------

	--Smithing station, deconstruction panel, button "weapons", SetState function
	ZO_PreHook(ZO_SmithingTopLevelDeconstructionPanelInventoryTabsButton2.m_object, "SetState", function(smithing_obj, state)
d("Prehook ZO_SmithingTopLevelDeconstructionPanelInventoryTabsButton2:SetState()")
		if state ~= nil then
	    	if state == 1 then
	        	d("Activated deconstruction, weapons")
	    	elseif state == 0 then
	        	d("Deactivated deconstruction, weapons")
	       	end
	    end
	end)
end
]]
--==============================================================================

--==============================================================================
--			Override another function
--==============================================================================
-- Override a function, adding overridden function as first parameter to the new callback function.
--> Taken from addon ContainerPeek, thanks to author "Sparq"!!!
---> http://www.esoui.com/downloads/info1126-ContainerPeek.html
local function Override(objectTable, existingFunctionName, hookFunction)
    if (type(objectTable) == "string") then
        hookFunction = existingFunctionName
        existingFunctionName = objectTable
        objectTable = _G
    end
    local existingFn = objectTable[existingFunctionName]
    if ((existingFn ~= nil) and (type(existingFn) == "function")) then
        local newFn = function(...)
            return hookFunction(existingFn, ...)
        end
        objectTable[existingFunctionName] = newFn
    end
end

--==============================================================================
--			Pre-Hook Handler Methods
--==============================================================================
-- gets handler from the event handler list
local function GetEventHandler(eventName, objName)
    if not FCOIS.eventHandlers or not FCOIS.eventHandlers[eventName] then return nil end
    --Get the global event handler function of an object name
    return FCOIS.eventHandlers[eventName][objName]
end

-- adds handler to the event handler list
local function SetEventHandler(eventName, objName, handler)
    FCOIS.eventHandlers[eventName] = FCOIS.eventHandlers[eventName] or {}
    --Set the global event handler function for an object name
    --FCOIS.eventHandlers[eventName][objName] = handler
    --Speed up: Just set boolean value
    if handler == true then
        FCOIS.eventHandlers[eventName][objName] = handler
    else
        FCOIS.eventHandlers[eventName][objName] = nil
    end
end

--Add the OnMouseUp event handler to the scroll list's row control
local function addOnMouseUpEventHandlerToRow(rowControl)
--d("[FCOIS]addOnMouseUpEventHandlerToRow - rowControl: " ..tostring(rowControl:GetName()))
    if not rowControl then return end
    --Only if the <modifier key> + right click settings is enabled within FCOIS
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
    if contextMenuClearMarkesByShiftKey == true then
        local rowName = rowControl:GetName()
        --Is the row a supported inventory row pattern?
        local isInvRow, _ = FCOIS.IsSupportedInventoryRowPattern(rowName)
        if isInvRow == true then
            -- Append OnMouseUp event of inventory item controls, for each row (children), if it is not already set there before inside the if via SetEventHandler(...)
            if( not GetEventHandler("OnMouseUp", rowName) ) then
                --Speed up: Only set boolean value to prevent addition of handler on the same row again (as you scroll, as the same rows are re-used in a pool!)
                SetEventHandler("OnMouseUp", rowName, true)
                --Use ZOs function to PreHook the event handler now
                ZO_PreHookHandler(rowControl, "OnMouseUp", function(...)
                    FCOIS.OnInventoryItemMouseUp(...)
                end)
            end
        end
    end
end


--A setupCallback function for the scrolllists of the inventories.
--> Will add the FCOIS marker icons if they get visible and add the OnMouseUp handlers to the rows to support the SHIFT+right mouse button features
local function OnScrollListRowSetupCallback(rowControl, data)
    --d("[FCOIS]OnScrollListRow:SetupCallback")
    if not rowControl then
        d("[FCOIS]ERROR: OnScrollListRowSetupCallback - rowControl is missing!")
        return
    end
    --Row is e.g. ZO_SmithingTopLevelRefinementPanelInventoryBackpack1Row1
    --Parent will be ZO_SmithingTopLevelRefinementPanelInventoryBackpackContents
    --It's parent will be ZO_SmithingTopLevelRefinementPanelInventoryBackpack
    local inventoryListControl = rowControl:GetParent():GetParent()
    if not inventoryListControl then
        d("[FCOIS]ERROR: OnScrollListRowSetupCallback - inventoryListControl is missing!")
        return
    end

    --Duplicate call to FCOIS.CreateMarkerControl or neede for "at least some" of the inventories,
    --like the crafting tables? Yes. But we need to filter the update of the marker controls for the others
    --like normal inventories!
    -- For some inventories like crafting tables: Create/Update the icons
    local inventoryVars = FCOIS.inventoryVars
    local hookScrollSetupCallbacks = inventoryVars.markerControlInventories and inventoryVars.markerControlInventories.hookScrollSetupCallback
    if hookScrollSetupCallbacks[inventoryListControl] ~= nil then
--d(">>it's a valid scrollList setupCallback")
        local settings = FCOIS.settingsVars.settings
        local iconVars = FCOIS.iconVars
        local textureVars = FCOIS.textureVars

        for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            local iconData = settings.icon[i]
            FCOIS.CreateMarkerControl(rowControl, i, iconData.size or iconVars.gIconWidth, iconData.size or iconVars.gIconWidth, textureVars.MARKER_TEXTURES[iconData.texture])
        end
    end

    --Add additional FCO point to the dataEntry.data slot
    --FCOItemSaver_AddInfoToData(rowControl)

    --Update the mouse double click handler OnEffectivelyShown() at the row
    addOnMouseUpEventHandlerToRow(rowControl)
end


--==============================================================================
--			Context menu / right click / slot actions
--==============================================================================
--Check if the localization data of the context menu is given
local function checkAndUpdateContextMenuLocalizationData()
--d("[FCOIS]checkAndUpdateContextMenuLocalizationData")
    local locVars = FCOIS.localizationVars
    local doUpdateLocalization = false
    local settings = FCOIS.settingsVars.settings
    if not locVars then
        doUpdateLocalization = true
    end
    if not doUpdateLocalization then
        local locEntriesToCheck = {
            ["lTextEquipmentMark"]      = true,
            ["lTextEquipmentDemark"]    = true,
            ["lTextMark"]               = true,
            ["lTextDemark"]             = true,
        }
        for key, isToCheck in pairs(locEntriesToCheck) do
            if isToCheck == true and not doUpdateLocalization then
                if locVars[key] == nil then
--d(">key not found: " ..tostring(key))
                    doUpdateLocalization = true
                    break
                end
                --Check if the texts for the filter icons exists
                for iconId=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                    local isIconEnabled = settings.isIconEnabled[iconId]
                    if locVars[key][iconId] == nil and isIconEnabled == true then
--d(">key's iconId not found: " ..tostring(key) .. ", icon: " ..tostring(iconId) .. ", iconEnabled: " .. tostring(isIconEnabled))
                        doUpdateLocalization = true
                        break
                    end
                end
            end
        end
    end
    --Should the localization be rebuild now?
    if doUpdateLocalization == true then
d("[FCOIS]checkAndUpdateContextMenuLocalizationData - Update the localization now")
        --Re-Do the localization done variable and rebuild all localization
        FCOIS.Localization()
        --Overwrite the localized texts for the marker icons in the context menus
        FCOIS.changeContextMenuEntryTexts(-1)
    end
end


--PreHook the global ZO_Menu hide function to show the PlayerProgressBar again at the character panel
ZO_PreHook("ZO_Menu_OnHide", function()
--d("[FCOIS]ZO_Menu_OnHide")
    --Check if a context menu item was disabled for the mouse and enable it again
    local settings = FCOIS.settingsVars.settings
    local prevVars = FCOIS.preventerVars
    if settings.showContextMenuDivider and prevVars.disabledContextMenuItemIndex ~= nil and prevVars.disabledContextMenuItemIndex ~= -1 then
        local contextMenuItemControl = ctrlVars.ZOMenu.items[prevVars.disabledContextMenuItemIndex].item
        if contextMenuItemControl then
            contextMenuItemControl:SetMouseEnabled(true)
            FCOIS.preventerVars.disabledContextMenuItemIndex = -1
        end
    end
    --Check if the character window is shown and if the current scene is the inventory scene
    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    local _, currentSceneName = FCOIS.getCurrentSceneInfo()
    if not ctrlVars.CHARACTER:IsHidden() and currentSceneName == ctrlVars.invSceneName  then
        --Show the PlayerProgressBar again as the context menu closes
        FCOIS.ShowPlayerProgressBar(true)
    end
end)

--Called before "Use" at a SlotAction. See function FCOIS_preUseAddSlotActionCallbackFunc and FCOIS.OverrideUseAddSlotAction
--and the Override function
function FCOIS.useAddSlotActionCallbackFunc(self)
    --d("[FCOIS.useAddSlotActionCallbackFunc]")
    --is the option to show the protection dialog for transmuation geode containers enabled?
    local settings = FCOIS.settingsVars.settings
    if settings.showTransmutationGeodeLootDialog and not FCOIS.preventerVars.doNotShowProtectDialog then
        local bag, slotIndex
        if self.dataEntry and self.dataEntry.data and self.dataEntry.data.bagId and self.dataEntry.data.slotIndex then
            bag = self.dataEntry.data.bagId
            slotIndex = self.dataEntry.data.slotIndex
        else
            if self.m_inventorySlot ~= nil then
                bag, slotIndex = ZO_Inventory_GetBagAndIndex(self.m_inventorySlot)
            end
        end
        if bag == nil or slotIndex == nil then return false end
        --Check if the item is a Transmutation geode container and usable
        local isContainer = FCOIS.isItemType(bag, slotIndex, ITEMTYPE_CONTAINER) or false
        --d(">Item is a container: " .. tostring(isContainer))
        if isContainer == true then
            --local itemLink = GetItemLink(bag, slotIndex)
            local mappingVarsTransm = FCOIS.mappingVars.containerTransmuation
            if mappingVarsTransm == nil then return false end
            local transmGeodenIds = mappingVarsTransm.geodeItemIds
            if transmGeodenIds == nil then return false end
            local itemId = GetItemId(bag, slotIndex)
            --d(">itemId: " ..tostring(itemId))
            if itemId == nil then return false end
            --Check the itemIds of the possible transmuation geodes against the current item
            if transmGeodenIds[itemId] then
                local doShowTransmuationProtectionDialog, currentTransmCrystalCount, maxTransmCrystalCount = FCOIS.checkAndShowTransmutationGeodeLootDialog()
                --d(">doShowTransmuationProtectionDialog: " ..tostring(doShowTransmuationProtectionDialog) .. ", current/max: " ..tostring(currentTransmCrystalCount) .. "/" .. tostring(maxTransmCrystalCount))
                if doShowTransmuationProtectionDialog == true then
                    local data = {}
                    data.replaceVars = {}
                    table.insert(data.replaceVars, currentTransmCrystalCount)
                    table.insert(data.replaceVars, maxTransmCrystalCount)
                    data.callbackYes = function()
                        FCOIS.preventerVars.doNotShowProtectDialog = true
                        if IsProtectedFunction("UseItem") then
                            CallSecureProtected("UseItem", bag, slotIndex)
                        else
                            UseItem(bag, slotIndex)
                        end
                        FCOIS.preventerVars.doNotShowProtectDialog = false
                    end
                    data.callbackNo = function() return true end
                    --Show the ask dialog now
                    local locVar = FCOIS.localizationVars.fcois_loc
                    FCOIS.showProtectionDialog(locVar["options_enable_block_transmutation_dialog_title"], locVar["options_enable_block_transmutation_dialog_question"], data)
                    return true -- Abort the original use function here!
                end
            end
        end
    end
    return false -- Call the original function now
end

--Called at "Use" SlotAction, before the usage of the item
local function FCOIS_preUseAddSlotActionCallbackFunc(self, func, ...)
    --Check if the container needs to be opened
    local retVar = FCOIS.useAddSlotActionCallbackFunc(self) -- true: Abort the normal function "UseItem" so the container is not opened / false: call original function
    --d("[FCOIS_preUseAddSlotActionCallbackFunc] retVar: " .. tostring(retVar))
    --Nothing protected? Then call the original function
    if retVar == false then
        return func(...)
    else
        return true
    end
end

-- Override the "Use" SlotAction, make it not open the container if it's e.g. a transmutation container
-- and you already have at least 150 transmuation crystals
function FCOIS.OverrideUseAddSlotAction(parentFunc, self, actionStringId, actionCallback, ...)
    --d("[FCOIS.OverrideUseAddSlotAction]")
    --Is the item a container
    if (not ctrlVars.BACKPACK:IsHidden() and actionStringId == SI_ITEM_ACTION_USE) then
        return parentFunc(
            self, SI_ITEM_ACTION_USE,
            function(...) return FCOIS_preUseAddSlotActionCallbackFunc(self, actionCallback, ...) end,
            ...
        )
    end
    --Else execute the original "Use" function callback
    return parentFunc(self, actionStringId, actionCallback, ...)
end

--==============================================================================
--			ON EVENT Methods (drag/drop, doubleclick, ...)
--==============================================================================

-- handler function for inventory item controls' OnMouseUp event
function FCOIS.OnInventoryItemMouseUp(self, mouseButton, upInside, ctrlKey, altKey, shiftKey, ...)
    --d("[FCOIS]InventoryItem_OnMouseUp] mouseButton: " .. tostring(mouseButton) .. ", upInside: " .. tostring(upInside).. ", ctrlKey: " .. tostring(ctrlKey) .. ", altKey: " .. tostring(altKey).. ", shiftKey: " .. tostring(shiftKey))
    FCOIS.preventerVars.dontShowInvContextMenu = false
    --Enable clearing all markers by help of the <modifier key>+right click?
    local contextMenuClearMarkesKey = FCOIS.settingsVars.settings.contextMenuClearMarkesModifierKey
    local isModifierKeyPressed = FCOIS.IsModifierKeyPressed(contextMenuClearMarkesKey)
    FCOIS.checkIfClearOrRestoreAllMarkers(self, isModifierKeyPressed, upInside, mouseButton, false)
    --Call original callback function for event OnMouseUp of the iinventory item row/character equipment slot now
    return false
end

--Prehook function to ZO_InventorySlot_DoPrimaryAction to secure items as doubleclick or keybind of primary was raised
local function FCOItemSaver_OnInventorySlot_DoPrimaryAction(inventorySlot)
    local doNotCallOriginalZO_InventorySlot_DoPrimaryAction = false
    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)
    --Check if SHIFT key is pressed and if settings to use SHIFT key + right mouse to remove/restore marker icons on the inventory row is enabled
    -->Then do not call the double click handler here
    local settings = FCOIS.settingsVars.settings
    local contextMenuClearMarkesByShiftKey = settings.contextMenuClearMarkesByShiftKey
    local contextMenuClearMarkesKey = settings.contextMenuClearMarkesModifierKey
    if contextMenuClearMarkesByShiftKey == true and FCOIS.IsModifierKeyPressed(contextMenuClearMarkesKey) then return false end

    --Check where we are
    local parent = inventorySlot:GetParent()
    local isABankWithdraw = (parent == ctrlVars.BANK_BAG or parent == ctrlVars.GUILD_BANK_BAG or parent == ctrlVars.HOUSE_BANK_BAG)
    local isCharacter = (parent == ctrlVars.CHARACTER) or false
    local isVendorRepair = FCOIS.IsVendorPanelShown(LF_VENDOR_REPAIR, false) or false
    --Do not add protection double click functions to bank/guild bank withdraw and character, and vendor repair
--d(">[FCOIS]FCOItemSaver_OnInventorySlot_DoPrimaryAction - " .. tostring(inventorySlot:GetName()) .. ", isBankWithdraw: " ..tostring(isABankWithdraw) .. ", isCharacter: " ..tostring(isCharacter) .. ", isVendorRepair: " ..tostring(isVendorRepair))
    if not isABankWithdraw and not isCharacter and not isVendorRepair then
        --Get the slected inv. row'S dataEntry.data with bagId and slotIndex
        local bagId, slotId = FCOIS.MyGetItemDetails(inventorySlot)
        if( bagId ~= nil and slotId ~= nil ) then
            --Set: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
            FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = true

            -- Inside deconstruction?
            if(not ctrlVars.DECONSTRUCTION_BAG:IsHidden() ) then
                -- check if deconstruction is forbidden
                -- if so, return true to prevent call of the original function ZO_InventorySlot_DoPrimaryAction of the item
                if( FCOIS.callDeconstructionSelectionHandler(bagId, slotId, true) ) then
                    doNotCallOriginalZO_InventorySlot_DoPrimaryAction = true
                end
                --Others
            else
                --check if item interaction is forbidden
                --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
                if( FCOIS.callItemSelectionHandler(bagId, slotId, true, false, false, false, false, false, false) ) then
                    -- item is not allowed to work with, prevent call of the original function ZO_InventorySlot_DoPrimaryAction of the item
                    doNotCallOriginalZO_InventorySlot_DoPrimaryAction = true
                end
            end
            --Reset: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
            FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
        end
        --Clear the cursor now as the item is protected?
        if doNotCallOriginalZO_InventorySlot_DoPrimaryAction == true then
            ClearCursor()
        end
    end
    return doNotCallOriginalZO_InventorySlot_DoPrimaryAction
end

-- handler function for character equipment double click -> OnEffectivelyShown function
local function FCOItemSaver_CharacterOnEffectivelyShown(self, ...)
    if ( not self ) then return false end
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
    local equipmentSlotName
    local characterEquipmentSlots = FCOIS.mappingVars.characterEquipmentSlots
--d("[FCOItemSaver_CharacterOnEffectivelyShown]: " .. self:GetName())
    for i = 1, self:GetNumChildren() do
        -- override OnMouseDoubleClick event of character window item controls, for each row (children)
        equipmentSlotName = ctrlVars.CHARACTER:GetChild(i):GetName()
        if equipmentSlotName ~= nil then
            local isEquipmentSlot = characterEquipmentSlots[equipmentSlotName] or false
            --if(string.find(equipmentSlotName, "ZO_CharacterEquipmentSlots")) then
            if isEquipmentSlot == true then
--d(">EquipmentSlot: " ..tostring(equipmentSlotName))
                local currentCharChild = self:GetChild(i)
                if currentCharChild ~= nil then
                    if contextMenuClearMarkesByShiftKey == true then
                        --Mouse up event for the SHIFT+right mouse button
                        if( not GetEventHandler("OnMouseUp", equipmentSlotName) ) then
--d(">>Set event handler: OnMouseUp")
                            --Add the custom event handler function to a global list so it won't be added twice
                            --Speed up: Only set boolean
                            SetEventHandler("OnMouseUp", equipmentSlotName, true)
                            --Use ZO function to PreHook the event handler now
                            ZO_PreHookHandler(currentCharChild, "OnMouseUp", function(...)
                                FCOIS.OnInventoryItemMouseUp(...)
                            end)
                        end
                    end
                end
            end
        end
    end
    --[[
    -- call the original handler function
    local func = GetEventHandler("OnEffectivelyShown", self:GetName())
    if ( not func ) then return false end
    return func(self, ...)
    ]]
    --Call the original OnEffectivelyShown handler function now
    return false
end

--Callback function for start a new drag&drop operation
--After the item was picked from the inventory the event EVENT_INVENTORY_SLOT_LOCKED will be called, as the item get's locked against changes
--Check file src/FCOIS_Events.lua, function FCOItemSaver_OnInventorySlotLocked() for the further checks of a dragged item -> Protections and error messages
local function FCOItemSaver_OnDragStart(inventorySlot)
    if inventorySlot == nil then return end
    local cursorContentType = GetCursorContentType()
--d("[FCOIS]FCOItemSaver_OnDragStart-cursorContentType: " .. tostring(cursorContentType) .. "/" .. tostring(MOUSE_CONTENT_INVENTORY_ITEM))
    --cursorContentType is in 99% of the cases = MOUSE_CONTENT_EMPTY, even if an inventory item gets dragged
    if cursorContentType == MOUSE_CONTENT_EMPTY then
        inventorySlot = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    end
--FCOIS._inventorySlot=inventorySlot
    FCOIS.dragAndDropVars.bag = nil
    FCOIS.dragAndDropVars.slot = nil
    local bag, slot = FCOIS.MyGetItemDetails(inventorySlot)
    if bag == nil or slot == nil then bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot) end
--d(">bag, slot: " .. tostring(bag) .. ", " .. tostring(slot))
    if bag == nil or slot == nil then return end
    FCOIS.dragAndDropVars.bag = bag
    FCOIS.dragAndDropVars.slot = slot
end

--Callback function for receive a dragged inventory item. Used for:
--1. Drop of an item at an equipment slot -> Aswk before bind dialog
--2. If CraftBagExtended addon is enabled: Drop of any craftbag item at the mail send/player trade panel as the Drag function will not be
--   executed properly for CraftBag rows. So we need to check if the item is protected and cancel the drop here!
local function FCOItemSaver_OnReceiveDrag(inventorySlot)
    --FCOinvs = inventorySlot
    local cursorContentType = GetCursorContentType()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[OnReceiveDrag]","cursorContentType: " .. tostring(cursorContentType) .. "/" .. tostring(MOUSE_CONTENT_INVENTORY_ITEM) .. ", invSlotType: " .. tostring(inventorySlot.slotType) .. "/" .. tostring(SLOT_TYPE_EQUIPMENT), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]FCOItemSaver_OnReceiveDrag, cursorContentType: " ..tostring(cursorContentType))

    -- if there is an inventory item on the cursor:
    if cursorContentType ~= MOUSE_CONTENT_INVENTORY_ITEM and cursorContentType ~= MOUSE_CONTENT_EQUIPPED_ITEM then return end
    local slotType = inventorySlot.slotType
    -- and the slot type we're dropping it on is an equip slot:
    if slotType == SLOT_TYPE_EQUIPMENT then
        local bag
        local slot
        local dragAndDropVars = FCOIS.dragAndDropVars
        --Was the drag started with another item then the dropped item slot?
        if dragAndDropVars.bag ~= nil and dragAndDropVars.slot ~= nil then
            bag			= dragAndDropVars.bag
            slot		= dragAndDropVars.slot
            --receiveSlot = inventorySlot.slotIndex
        else
            --get bagid and SlotIndex from receiving inventorySlot -> Makes no sense as the bind dialog shows the wrong item then!
            --bag   = inventorySlot.bagId
            --slot	= inventorySlot.slotIndex
            --Abort here as it makes no sense to try to equip an item that you are already wearing :-D
            --Clear the old values from drag start now
            FCOIS.dragAndDropVars.bag = nil
            FCOIS.dragAndDropVars.slot = nil
        end
        if bag == nil or slot == nil then return end
        --Is item bindable and equipable?
        local doShowItemBindDialog = false
        if ( not ctrlVars.CHARACTER:IsHidden() ) then
            local equipSucceeds, _ = IsEquipable(bag, slot)
            --Check if we need to show the "Ask before bind" dialog as the item get's dropped at an equipment slot
            if equipSucceeds and FCOIS.CheckBindableItems(bag, slot, nil, true) then
                doShowItemBindDialog = true
            end
        end

        --Clear the old values from drag start now
        FCOIS.dragAndDropVars.bag = nil
        FCOIS.dragAndDropVars.slot = nil
        -- check if destroying, improvement, sending or trading is forbidden
        -- and check if item is bindable (above)
        -- if so, clear item hold by cursor
        if( doShowItemBindDialog ) then
            --Remove the picked item from drag&drop cursor
            ClearCursor()
        end
        return false
    elseif slotType == SLOT_TYPE_MAIL_QUEUED_ATTACHMENT or slotType == SLOT_TYPE_MAIL_ATTACHMENT or slotType == SLOT_TYPE_MY_TRADE then
        local bagId = GetCursorBagId()
        local slotIndex = GetCursorSlotIndex()
        if not bagId or not slotIndex then return false end
        --CraftBag item was dragged and dropped?
        if bagId == BAG_VIRTUAL then
            --Check if the item is protected
            --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
            local isProtected = FCOIS.callItemSelectionHandler(bagId, slotIndex, true, true, false, false, false, false, false, nil)
            if isProtected == true then
                --Remove the picked item from drag&drop cursor
                ClearCursor()
                return true
            end
        end
    end
end

--==============================================================================
--      Hook Methods (update inventory rows and add doubleclick event, scene hook callbacks, etc.
--==============================================================================

--Callback function for scenes to hide the context menu of inventory buttons
function FCOIS.sceneCallbackHideContextMenu(oldState, newState, overrideFilterPanel)
    --d("[FCOIS.sceneCallbackHideContextMenu")
    --When e.g. the mail inbox panel is showing up
    if newState == SCENE_SHOWING or SCENE_FRAGMENT_SHOWING then
        if overrideFilterPanel == nil then
            overrideFilterPanel = FCOIS.gFilterWhere
        end
        --Hide the context menu at last active panel
        FCOIS.hideContextMenu(overrideFilterPanel)
    end
end


--============================================================================================================================================================
--===== HOOKS BEGIN ==========================================================================================================================================
--============================================================================================================================================================
local function specialContextMenuKeysCheckAndActions()
    local settings = FCOIS.settingsVars.settings
    local contextMenuClearMarkesByShiftKey = settings.contextMenuClearMarkesByShiftKey
    local contextMenuClearMarkesKey = settings.contextMenuClearMarkesModifierKey
    if contextMenuClearMarkesByShiftKey == true and lcm and lcm.EnableSpecialKeyContextMenu then lcm:EnableSpecialKeyContextMenu(contextMenuClearMarkesKey) end
    return contextMenuClearMarkesByShiftKey
end

--Create the hooks & pre-hooks
function FCOIS.CreateHooks()
    local settings = FCOIS.settingsVars.settings
    local locVars = FCOIS.localizationVars.fcois_loc
    local mappingVars = FCOIS.mappingVars

    --========= INVENTORY SLOT - SHOW CONTEXT MENU =================================
    local function ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver(rowControl, slotActions, ctrl, alt, shift, command)
        shift = shift or IsShiftKeyDown()
        alt = alt or IsAltKeyDown()
        ctrl = ctrl or IsControlKeyDown()
        local prevVars = FCOIS.preventerVars
        FCOIS.preventerVars.buildingInvContextMenuEntries = false
        --As this prehook is called before the character OnMouseUp function is called:
        --If the SHIFT+right mouse button option is enabled and the SHIFT key is pressed and the character is shown.
        --Then hide the context menu
        local contextMenuClearMarkesKey = settings.contextMenuClearMarkesModifierKey
        local contextMenuClearMarkesByShiftKey = specialContextMenuKeysCheckAndActions()

        local isCharacterShown = not FCOIS.ZOControlVars.CHARACTER:IsHidden()

        --d("[FCOIS]ZO_InventorySlot_ShowContextMenu - dontShowInvContextMenu: " ..tostring(FCOIS.preventerVars.dontShowInvContextMenu) .. ", isCharacterShown: " ..tostring(isCharacterShown))
        --Clear the sub context menu entries
        FCOIS.customMenuVars.customMenuSubEntries = {}
        FCOIS.customMenuVars.customMenuDynSubEntries = {}
        FCOIS.customMenuVars.customMenuCurrentCounter = 0

        --if the context menu should not be shown, because all marker icons were removed
        -- hide it now
        if prevVars.dontShowInvContextMenu == false and isCharacterShown and contextMenuClearMarkesByShiftKey == true
                and (FCOIS.IsModifierKeyPressed(contextMenuClearMarkesKey) and FCOIS.IsNoOtherModifierKeyPressed(contextMenuClearMarkesKey)) then
            --d(">FCOIS context menu, shift key is down")
            FCOIS.preventerVars.dontShowInvContextMenu = true
        end
        if prevVars.dontShowInvContextMenu then
            --d(">FCOIS context menu, hiding it!")
            FCOIS.preventerVars.dontShowInvContextMenu = false
            --Hide the context menu now by returning true in this preHook and not calling the "context menu show" function
            --Nil the current menu ZO_Menu so it does not show (anti-flickering)
            ClearMenu()
            return true
        end

        --Call a little bit later so the context menu is already created
        --zo_callLater(function()
        --Reset the IIfA clicked variables
        FCOIS.IIfAclicked = nil

        local parentControl = rowControl:GetParent()

        local FCOcontextMenu = {}

        --Check if the user set ordering is valid, else use the default sorting
        local userOrderValid = FCOIS.checkIfUserContextMenuSortOrderValid()
        local resetSortOrderDone = false

        local contextMenuEntriesAdded = 0
        --check each iconId and build a sorted context menu then
        local useSubContextMenu     = settings.useSubContextMenu
        local _, countDynIconsEnabled = FCOIS.countMarkerIconsEnabled()
        local useDynSubContextMenu  = (settings.useDynSubMenuMaxCount > 0 and  countDynIconsEnabled >= settings.useDynSubMenuMaxCount) or false
        for iconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            --Check if the icon (including gear sets) is enabled
            if settings.isIconEnabled[iconId] then
                --Re-order the context menu entries by defaults, or with user settings
                local newOrderId = 0
                if userOrderValid then
                    --Use the custom sort order as it is valid!
                    newOrderId = settings.icon[iconId].sortOrder
                else
                    --Reset the sort order to the default values now - Only once for the first icon where this happens
                    if not resetSortOrderDone then
                        resetSortOrderDone = FCOIS.resetUserContextMenuSortOrder()
                    end
                    --Use the default sort order as the other one is not valid!
                    newOrderId = FCOIS.settingsVars.defaults.icon[iconId].sortOrder
                end
                if newOrderId > 0 and newOrderId <= numFilterIcons then
                    --Initialize the context menu entry at the new index
                    FCOcontextMenu[newOrderId] = nil
                    FCOcontextMenu[newOrderId] = {}
                    --Is the current control an equipment control?
                    local isEquipControl = (parentControl == ctrlVars.CHARACTER)
                    if(isEquipControl) then
                        FCOcontextMenu[newOrderId].control		= rowControl
                    else
                        FCOcontextMenu[newOrderId].control		= parentControl
                    end
                    FCOcontextMenu[newOrderId].iconId		= iconId
                    FCOcontextMenu[newOrderId].refreshPopup	= false
                    FCOcontextMenu[newOrderId].isEquip		= isEquipControl
                    FCOcontextMenu[newOrderId].useSubMenu	= useSubContextMenu
                    --Increase the counter for added context menu entries
                    contextMenuEntriesAdded = contextMenuEntriesAdded + 1
                end -- if newOrderId > 0 and newOrderId <= numFilterIcons then
            end -- if settings.isIconEnabled[iconId] then
        end -- for

        --Are there any context menu entries?
        if contextMenuEntriesAdded > 0 then
            local addedCounter = 0
            FCOIS.preventerVars.buildingInvContextMenuEntries = true
            --Check if the localization data of the context menu is given
            checkAndUpdateContextMenuLocalizationData()
            for j = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                if FCOcontextMenu[j] ~= nil then
                    addedCounter = addedCounter + 1
                    --Is the currently added entry with AddMark the "last one in this context menu"?
                    --> Needed to set the preventer variable buildingInvContextMenuEntries for the function AddMark so the IIfA addon is recognized properly!
                    if addedCounter == contextMenuEntriesAdded then
                        --Last entry in custom context menu reached
                        FCOIS.preventerVars.buildingInvContextMenuEntries = false
                    end
                    --FCOIS.AddMark(rowControl, markId, isEquipmentSlot, refreshPopupDialog, useSubMenu)
                    --Increase the global counter for the added context menu entries so the function FCOIS.AddMark can react on it
                    FCOIS.customMenuVars.customMenuCurrentCounter = FCOIS.customMenuVars.customMenuCurrentCounter + 1
                    FCOIS.AddMark(FCOcontextMenu[j].control, FCOcontextMenu[j].iconId, FCOcontextMenu[j].isEquip, FCOcontextMenu[j].refreshPopup, FCOcontextMenu[j].useSubMenu)
                end
            end

            --As the (dynamic) sub menu entries were build, show them now
            if useSubContextMenu or useDynSubContextMenu then
                zo_callLater(function()
                    local customMenuSubEntries = FCOIS.customMenuVars.customMenuSubEntries
                    if customMenuSubEntries ~= nil and #customMenuSubEntries > 0 then
                        AddCustomSubMenuItem("|c22DD22FCO|r ItemSaver", customMenuSubEntries)
                    else
                        if FCOIS.customMenuVars.customMenuDynSubEntries ~= nil and #FCOIS.customMenuVars.customMenuDynSubEntries > 0 then
                            local dynamicSubMenuEntryHeaderText = locVars["options_icons_dynamic"]
                            if settings.addContextMenuLeadingMarkerIcon then
                                dynamicSubMenuEntryHeaderText = "  " .. dynamicSubMenuEntryHeaderText
                            end
                            AddCustomSubMenuItem(dynamicSubMenuEntryHeaderText, FCOIS.customMenuVars.customMenuDynSubEntries)
                        end
                    end
                    --Do not remove or dynamic submenu in contextmenus will be missing boundaries!
                    ShowMenu(rowControl)
                end, 30)
            end
        end -- if contextMenuEntriesAdded > 0 then
        FCOIS.preventerVars.buildingInvContextMenuEntries = false
        --end, 30) -- zo_callLater
    end -- function ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver(rowControl, slotActions)

    -- Hook functions for the inventory/store contextmenus
    --ZO_PreHook("ZO_InventorySlot_ShowContextMenu", function(rowControl)
    --    ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver(rowControl)
    --end)
    -->Use LibCustomMenu for this!
    -->Check if the function to register a special context menu (with shift, alt, ctrl, control keys!) exists and use this,
    -->or the normal RegisterContextMenu function
    if lcm then
        if lcm.RegisterSpecialKeyContextMenu then
            lcm:RegisterSpecialKeyContextMenu(ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver)
        end
        lcm:RegisterContextMenu(ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver)
    else
        local libMissingErrorText = FCOIS.errorTexts["libraryMissing"]
        d(FCOIS.preChatVars.preChatTextRed .. string.format(libMissingErrorText, "LibCustomMenu"))
    end


    --========= ZO_DIALOG1 / DESTROY DIALOG ========================================
    --Destroy item dialog button 2 ("Abort") hook
    ZO_PreHook(ctrlVars.DestroyItemDialog.buttons[2], "callback", function()
        --Get the "YES" button of the destroy dialog
        local button1 = FCOIS.ZOControlVars.ZODialog1:GetNamedChild("Button1")
        if button1 == nil then return false end
        --Reset the "YES" button of the dialog again after a few seconds
        zo_callLater(function()
            if FCOIS.ZOControlVars.ZODialog1 ~= nil and button1 ~= nil then
                FCOIS.ZOControlVars.ZODialog1:SetKeyboardEnabled(false)
                button1:SetText(GetString(SI_YES))
                button1:SetClickSound(SOUNDS.DIALOG_ACCEPT)
                button1:SetEnabled(true)
                button1:SetMouseEnabled(true)
                button1:SetHidden(false)
                button1:SetKeybindEnabled(true)
            end
        end, 100)
        return false
    end)

    --========= START DRAG FROM INVENTORY ==========================================
    ZO_PreHook("ZO_InventorySlot_OnDragStart", FCOItemSaver_OnDragStart)

    --========= DROP ITEM AT CHARACTER SLOT ========================================
    ZO_PreHook("ZO_InventorySlot_OnReceiveDrag", FCOItemSaver_OnReceiveDrag)

    --========= EQUIP ITEM =========================================================
    ZO_PreHook("EquipItem", function(bagId, slotIndex, equipSlotIndex)
        --If we got here the DoEquip function in file ingame/inventory/inventoryslot.lua was called already and the ZOs anti-equip dialog was already shown, or
        --not shown because function "ZO_InventorySlot_WillItemBecomeBoundOnEquip(bag, index)" did not return true.
        --So check if the item is still unbound and bindable and show an "Ask before equip" dialog if it's enabled in the settings
        if bagId ~= nil and slotIndex ~= nil then
            if settings.debug then FCOIS.debugMessage( "[EquipItem]","bagId: " .. bagId .. ", slotIndex: " .. slotIndex .. ", equipSlotIndex: " ..tostring(equipSlotIndex), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --d("[EquipItem] bagId: " .. bagId .. ", slotIndex: " .. slotIndex .. ", equipSlotIndex: " ..tostring(equipSlotIndex))

            --Check if the item is bound on equip and show dialog to acceppt the binding before (if enabled in the settings)
            return FCOIS.CheckBindableItems(bagId, slotIndex, equipSlotIndex)
        end
    end)

    --========= UNEQUIP ITEM =======================================================
    ZO_PreHook("UnequipItem", function(equipSlot)
        if equipSlot ~= nil then
            if settings.debug then FCOIS.debugMessage( "[UnequipItem]","slotIndex: " .. equipSlot, true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --If item was unequipped: Remove the armor type marker if necessary
            FCOIS.removeArmorTypeMarker(BAG_WORN, equipSlot)
            --Update the marker control of the new equipped item
            FCOIS.updateEquipmentSlotMarker(equipSlot, 1000)
        end
    end)
    --========= MENU BARS ==========================================================
    --Preehook the menu bar shown event to update the character equipment section if it is shown
    ZO_PreHookHandler(ctrlVars.mainMenuCategoryBar, "OnShow", function()
        if settings.debug then FCOIS.debugMessage( "[Main Menu Category Bar]","OnShow") end

        --Hide the context menu
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)

        --Update the character's equipment markers, if the character screen is shown
        if not ctrlVars.CHARACTER:IsHidden() then
            FCOIS.RefreshEquipmentControl()
        end

        --Update the dialog button 1 to show and respond again, if an item was tried to destroyed
        --Get the "yes" button control of the destroy popup window
        if FCOIS.preventerVars.wasDestroyDone then
            local button1 = FCOIS.ZOControlVars.ZODialog1:GetNamedChild("Button1")
            if button1 then
                button1:SetEnabled(true)
                button1:SetMouseEnabled(true)
                button1:SetHidden(false)
                button1:SetKeybindEnabled(true)
                FCOIS.ZOControlVars.ZODialog1:SetKeyboardEnabled(false)
                FCOIS.preventerVars.wasDestroyDone = false
            end
        end

        --Check, if the Anti-* checks need to be enabled again
        FCOIS.autoReenableAntiSettingsCheck("DESTROY")
    end)

    --========= REFINEMENT =========================================================
    --Pre Hook the refinement for prevention methods
    --PreHook the receiver function of drag&drop at the refinement panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.SMITHING, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        return FCOIS.isCraftBagItemDraggedToCraftingSlot(LF_SMITHING_REFINE, bagId, slotIndex)
    end)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the refine inventory list
    SecurePostHook(ctrlVars.REFINEMENT.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --========= DECONSTRUCTION =====================================================
    --Pre Hook the deconstruction for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the deconstruction inventory list
    SecurePostHook(ctrlVars.DECONSTRUCTION.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)


    --========= IMPROVEMENT ========================================================
    --Pre Hook the improvement for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the improvement inventory list
    SecurePostHook(ctrlVars.IMPROVEMENT.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --========= ENCHANTING =========================================================
    --Pre Hook the enchanting table for prevention methods
    --PreHook the receiver function of drag&drop at the refinement panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.ENCHANTING, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        --Rune creation & extraction!
        return FCOIS.isCraftBagItemDraggedToCraftingSlot(LF_ENCHANTING_CREATION, bagId, slotIndex)
    end)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the enchanting inventory list
    SecurePostHook(ctrlVars.ENCHANTING_STATION.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --========= ALCHEMY ============================================================
    --PreHook the receiver function of drag&drop at the refinement panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.ALCHEMY, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        --Alchemy creation
        return FCOIS.isCraftBagItemDraggedToCraftingSlot(LF_ALCHEMY_CREATION, bagId, slotIndex)
    end)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the alchemy solvent inventory list
    SecurePostHook(ctrlVars.ALCHEMY_STATION.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the alchemy reagent inventory list
    SecurePostHook(ctrlVars.ALCHEMY_STATION.dataTypes[2], "setupCallback", OnScrollListRowSetupCallback)

    --========= RETRAIT =========================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the retrait inventory list
    SecurePostHook(ctrlVars.RETRAIT_LIST.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --========= RESEARCH LIST / ListDialog OnShow/OnHide ======================================================
    local researchPopupDialogCustomControl = ESO_Dialogs["SMITHING_RESEARCH_SELECT"].customControl()
    if researchPopupDialogCustomControl ~= nil then
        ZO_PreHookHandler(researchPopupDialogCustomControl, "OnShow", function()
            --d("[FCOIS]SMITHING_RESEARCH_SELECT PreHook:OnShow")
            --As this OnShow function will be also called for other ZO_ListDialog1 dialogs...
            --Check if we are at the research popup dialog
            if not FCOIS.isResearchListDialogShown() then return false end
            FCOIS.preventerVars.ZO_ListDialog1ResearchIsOpen = true
            --Check the filter buttons and create them if they are not there.
            FCOIS.CheckFilterButtonsAtPanel(true, LF_SMITHING_RESEARCH_DIALOG)
        end)
        ZO_PreHookHandler(researchPopupDialogCustomControl, "OnHide", function()
            --d("[FCOIS]SMITHING_RESEARCH_SELECT PreHook:OnHide")
            --Check if we are at the research popup dialog
            if not FCOIS.preventerVars.ZO_ListDialog1ResearchIsOpen then return false end
            FCOIS.preventerVars.ZO_ListDialog1ResearchIsOpen = false
            --Hide the filter buttons at LF_SMITHING_RESEARCH_DIALOG (or LF_JEWELRY_RESEARCH_DIALOG, which will be
            --determined dynamically within function FCOIS.CheckActivePanel in function FCOIS.CheckFilterButtonsAtPanel)
            FCOIS.CheckFilterButtonsAtPanel(false, LF_SMITHING_RESEARCH_DIALOG, nil, true) -- Last parameter: Hide filter buttons
        end)
    end
    --========= RESEARCH LIST / ListDialog (also repair, enchant, charge, etc.) - ZO_Dialog1 ======================================================
    --Original setupCallback function
    local hookedResearchListFunctions = ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback
    --Pre-Hook the list dialog's rows
    ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback = function(rowControl, slot)
        --Call the original row's setupCallback function
        hookedResearchListFunctions(rowControl, slot)
        --d("[".. os.date("%c", GetTimeStamp()) .."]>enabling the control's row again")
        --Reset the row so it is enabled
        rowControl.disableControl = false

        local iconVars = FCOIS.iconVars
        local textureVars = FCOIS.textureVars

        -- Create/Update all the icons for the current dialog row
        for iconNumb = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            local iconData = settings.icon[iconNumb]
            FCOIS.CreateMarkerControl(rowControl, iconNumb, iconData.size or iconVars.gIconWidth, iconData.size or iconVars.gIconWidth, textureVars.MARKER_TEXTURES[iconData.texture])
        end -- for i = 1, numFilterIcons, 1 do

        --Get the row's bag and slotIndex
        local bagId, slotIndex = FCOIS.MyGetItemDetails(rowControl)
        --Check if rowControl is a soulgem
        local isSoulGem = false
        if bagId and slotIndex then
            isSoulGem = FCOIS.isSoulGem(bagId, slotIndex)
        end
        local myItemInstanceIdOfControl = FCOIS.MyGetItemInstanceId(rowControl)

        --Current dialog is the repair item dialog?
        local isRepairDialog = FCOIS.isRepairDialogShown()
        local disableControl = false

        -- Check the rowControl if the item is marked and update the OnMouseUp functions and the color of the item row then
        for iconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            local iconIsProtected = FCOIS.checkIfItemIsProtected(iconId, myItemInstanceIdOfControl)

            --Special research icon handling
            if iconId == FCOIS_CON_ICON_RESEARCH then
                if(not isSoulGem and iconIsProtected) then

                    --Not inside the repair dialog and settings allow research of "marked for research" items?
                    if not isRepairDialog and not settings.allowResearch then
                        disableControl = true
                        break -- leave for ... do loop
                    else
                        if not disableControl then
                            disableControl = false
                        end
                    end
                else
                    if not disableControl then
                        disableControl = false
                    end
                end

                --All other icons
            else
                if(not isSoulGem and iconIsProtected) then
                    if (isRepairDialog and settings.blockMarkedRepairKits) then
                        disableControl = true
                        break -- leave for ... do loop of iconIds
                    elseif not isRepairDialog then
                        --Is the icon a dynamic icon? Check if research at the popup dialog is allowed
                        disableControl = FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, false, nil) --leave the panelId empty so the addon will detect it automatically!
                        if disableControl == true then break else disableControl = false end
                    else
                        if not disableControl then
                            disableControl = false
                        end
                    end
                else
                    if not disableControl then
                        disableControl = false
                    end
                end
            end

        end -- for j = 1, numFilterIcons, 1 do

        --Set an attribute to the row which can be checked in other functions of the rowControl too!
        rowControl.disableControl = disableControl

        --Get here after for loop is left by a "break" and item is not researchable
        if rowControl.disableControl == true then
            --Change the color of the item to red
            rowControl:GetNamedChild("Name"):SetColor(0.75, 0, 0, 1)
        end

        --Pre-Hook the handler "OnMouseUp" event for the rowControl to disable the researching of the item,
        --but still enable the right click/context menu:
        --Show context menu at mouse button 2, but keep the normal OnMouseUp handler as well
        ZO_PreHookHandler(rowControl, "OnMouseUp", function(control, button, upInside, ctrlKey, altKey, shiftKey, command)
            if settings.debug then FCOIS.debugMessage( "[Research dialog control-OnMouseUp]","Clicked: " ..control:GetName() .. ", MouseButton: " .. tostring(button), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --button 1= left mouse button / 2= right mouse button
            --d("[FCOIS Hooks-ResearchDialog:OnMouseUp handler]Clicked: " ..control:GetName() .. ", MouseButton: " .. tostring(button) .. ", Shift: " ..tostring(shiftKey))

            --Right click/mouse button 2 context menu hook part:
            if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
                local contextMenuClearMarkesKey = FCOIS.settingsVars.settings.contextMenuClearMarkesModifierKey
                local isModifierKeyPressed = FCOIS.IsModifierKeyPressed(contextMenuClearMarkesKey)
                --Was the shift key clicked?
                if isModifierKeyPressed == true and FCOIS.IsNoOtherModifierKeyPressed(contextMenuClearMarkesKey) then
                    FCOIS.preventerVars.isZoDialogContextMenu = true
                    --Right click/mouse button 2 context menu together with shift key: Clear/Restore all marker icons on the item?
                    --If the setting to remove/readd marker icons via shift+right mouse button is enabled:
                    FCOIS.checkIfClearOrRestoreAllMarkers(rowControl, isModifierKeyPressed, upInside, button, true)
                    --If the context menu should not be shown, because all marker icons were removed
                    -- hide it now
                    if FCOIS.ShouldInventoryContextMenuBeHiddden() then
                        FCOIS.preventerVars.isZoDialogContextMenu = false
                        FCOIS.preventerVars.dontShowInvContextMenu = false
                        --Hide the context menu now by returning true in this preHook and not calling the "context menu show" function
                        return true
                    end
                end
                --Build the context menu for the research dialog now. Will be shown via function FCOIS.MarkMe then
                local FCOcontextMenu = {}
                --Check if the user set ordeirng is valid, else use the standard sorting
                local userOrderValid = FCOIS.checkIfUserContextMenuSortOrderValid()
                local contextMenuEntriesAdded = 0
                --Check if the localization data of the context menu is given
                checkAndUpdateContextMenuLocalizationData()
                --check each iconId and build a sorted context menu then
                for iconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                    --Check if the icon (including gear sets) is enabled
                    if settings.isIconEnabled[iconId] then
                        --Re-order the context menu entries by defaults, or with user settings
                        local newOrderId = 0
                        if userOrderValid then
                            newOrderId = settings.icon[iconId].sortOrder
                        else
                            newOrderId = FCOIS.settingsVars.defaults.icon[iconId].sortOrder
                        end
                        if newOrderId > 0 and newOrderId <= numFilterIcons then
                            --Initialize the context menu entry at the new index
                            FCOcontextMenu[newOrderId] = nil
                            FCOcontextMenu[newOrderId] = {}
                            FCOcontextMenu[newOrderId].control		= rowControl
                            FCOcontextMenu[newOrderId].iconId		= iconId
                            FCOcontextMenu[newOrderId].refreshPopup	= true -- Refresh the ZO_ListDialog1 popup entries now
                            FCOcontextMenu[newOrderId].isEquip		= false
                            FCOcontextMenu[newOrderId].useSubMenu	= false
                            --Increase the counter for added context menu entries
                            contextMenuEntriesAdded = contextMenuEntriesAdded + 1
                        end -- if newOrderId > 0 and newOrderId <= numFilterIcons then
                    end -- if settings.isIconEnabled[iconId] then
                end -- for

                --Are there any context menu entries?
                if contextMenuEntriesAdded > 0 then
                    --Reset the counter for the FCOIS.AddMark function
                    FCOIS.customMenuVars.customMenuCurrentCounter = 0
                    --Clear the menu completely (should be empty by default as it does not exist on the dialogs)
                    ClearMenu()
                    --Add the context menu entries now
                    for j = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        if FCOcontextMenu[j] ~= nil then
                            --FCOIS.AddMark(rowControl, markId, isEquipmentSlot, refreshPopupDialog, useSubMenu)
                            --Increase the global counter for the added context menu entries so the function FCOIS.AddMark can react on it
                            FCOIS.customMenuVars.customMenuCurrentCounter = FCOIS.customMenuVars.customMenuCurrentCounter + 1
                            FCOIS.AddMark(FCOcontextMenu[j].control, FCOcontextMenu[j].iconId, FCOcontextMenu[j].isEquip, FCOcontextMenu[j].refreshPopup, FCOcontextMenu[j].useSubMenu)
                        end
                    end
                end

            end -- Mouse button checks

            --Mouse button was released on the row?
            if upInside then
--d("[FCOIS]upInside: " ..tostring(upInside) .. ", disable: " ..tostring(rowControl.disableControl) .. ", isSoulGem: " ..tostring(isSoulGem))
                --Check if the clicked row got marker icons which protect this item!
                FCOIS.refreshPopupDialogButtons(rowControl, false)
                local dialog = ctrlVars.RepairItemDialog
                --Should this row be protected and disabled buttons and keybindings
                if rowControl.disableControl == true and not isSoulGem == true then
                    --d("MouseUpInside, rowControl.disableControl-> true")
                    --Do nothing (true tells the handler function that everything was achieved already in this function
                    --and the normal "hooked" functions don't need to be run afterwards)
                    -- -> All handling will be done in file src/FCOIS_ContextMenus.lua, function MarkMe() as the dialog list will be refreshed!
                    FCOIS.changeDialogButtonState(dialog, 1, false)
                    FCOIS.preventerVars.isZoDialogContextMenu = false
                    return true
                else -- if disableControl == false
                    --d("MouseUpInside, rowControl.disableControl-> false")
                    --Is the row selected? Check with a slight delay to assure the row gets updated and the selectedControl was set!
                    zo_callLater(function()
                        local selectedControl = ZO_ScrollList_GetSelectedControl(ctrlVars.LIST_DIALOG)
                        if selectedControl then
                            local enableResearchButton = false
                            if not selectedControl.disableControl then
                                --Enable the "use" button again, as it will be disabled before if the item won't be usable
                                enableResearchButton = true
                            else
                                --Disable the "use" button again, as the control is disabled!
                                enableResearchButton = false
                            end
                            FCOIS.changeDialogButtonState(dialog, 1, enableResearchButton)
                        end
                    end, 20)
                end -- if disableControl == true
            end
            FCOIS.preventerVars.isZoDialogContextMenu = false
        end) -- ZO_PreHookHandler(rowControl, "OnMouseUp"...

    end -- ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback -> list dialog 1 pre-hook (e.g. research, repair item, enchant, charge, etc.)

    --======== INVENTORY ===========================================================
    --Pre Hook the inventory for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the backpack inventory list
    SecurePostHook(ctrlVars.BACKPACK.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)
    --PreHook the primary action keybind in inventories
    ZO_PreHook("ZO_InventorySlot_DoPrimaryAction", FCOItemSaver_OnInventorySlot_DoPrimaryAction)

    --======== CRAFTBAG ===========================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the craftbag inventory list
    SecurePostHook(ctrlVars.CRAFTBAG_LIST.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)
    --ONLY if the craftbag is active
    --Pre Hook the 2 menubar button's (items and crafting bag) handler at the inventory
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_ITEMS, "OnMouseUp", function(control, button, upInside)
        --d("inv button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastInvButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastInvButton~=ctrlVars.INV_MENUBAR_BUTTON_ITEMS) then
            FCOIS.lastVars.gLastInvButton = ctrlVars.INV_MENUBAR_BUTTON_ITEMS
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_CRAFTBAG, LF_INVENTORY) end, 50)
        end
    end)
    --[[
    --API 100029 Dragonhold - Insecure call of ZO_StackSplitSource_DragStart if this PreHookHandler is used
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_CRAFTBAG, "OnMouseUp", function(control, button, upInside)
        --d("inv button 2, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastInvButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastInvButton~=ctrlVars.INV_MENUBAR_BUTTON_CRAFTBAG) then
            FCOIS.lastVars.gLastInvButton = ctrlVars.INV_MENUBAR_BUTTON_CRAFTBAG

            -- If CraftBagExtended is active: The button prehook will be moved and executed in craftbag's fragment "showing" callback function, for state "shown"
            -- so it needn't be added here
            if not FCOIS.otherAddons.craftBagExtendedActive then
                zo_callLater(function() FCOIS.PreHookButtonHandler(LF_INVENTORY, LF_CRAFTBAG) end, 50)
            end
        end
    end)
    ]]
    --======== LOOT SCENE ===========================================================
    --Register a callback function for the loot scene
    --Register a callback function for the inventory scene
    LOOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[LOOT_SCENE]","State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        if newState == SCENE_HIDING then
            --If the inventory was shown at last and the loot panel was opened (by using a container e.g.) the
            --anti-destroy settings have to be reenabled if the loot scene closes again
            FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory = true
            --d("Don't auto reenable anti-settings in invntory!")
        end
    end)

    --======== CHARACTER ===========================================================
    --Pre Hook the character window for prevention methods
    ZO_PostHookHandler( ctrlVars.CHARACTER, "OnEffectivelyShown", FCOItemSaver_CharacterOnEffectivelyShown )

    --======== RIGHT CLICK / CONTEXT MENU ==========================================
    --Pre Hook the right click/context menu addition of items
    ZO_PreHook(ZO_InventorySlotActions, "AddSlotAction", FCOIS.InvContextMenuAddSlotAction)

    --Override ZO_InventorySlotActions:AddSlotAction with own function FCOIS.OverrideUseAddSlotAction,
    --which will call the original function, but wil do some checks before (e.g. if it is a container
    --and contains transmutation crystals etc.)
    Override(ZO_InventorySlotActions, "AddSlotAction", FCOIS.OverrideUseAddSlotAction)

    --======== CURRENCIES (in inventory) ===========================================
    --Pre Hook the 3rd menubar button (Currencies) handler at the player inventory
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_CURRENCIES, "OnMouseUp", function(control, button, upInside)
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside) then
            --Set the global filter panel ID to LF_INVENTORY again (otherwise it would stay the same like before, e.g. craftbag, and block the drag&drop!)
            FCOIS.gFilterWhere = LF_INVENTORY
            --Hide the context menus
            zo_callLater(function()
                FCOIS.hideContextMenu(LF_INVENTORY)
            end, 50)
        end
    end)

    --======== QUICK SLOTS =========================================================
    --Pre Hook the 4th menubar button (Quickslots) handler at the player inventory
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_QUICKSLOTS, "OnMouseUp", function(control, button, upInside)
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside) then
            --Set the global filter panel ID to LF_INVENTORY again (otherwise it would stay the same like before, e.g. craftbag, and block the drag&drop!)
            FCOIS.gFilterWhere = LF_INVENTORY
            --Hide the context menus
            zo_callLater(function()
                if not ctrlVars.QUICKSLOT_CIRCLE:IsHidden() then
                    FCOIS.hideContextMenu(LF_INVENTORY)
                end
            end, 50)
        end
    end)

    --======== FENCE & LAUNDER =====================================================
    --Pre Hook the fence and launder "enter" and "fence closed" functions
    ZO_PreHook(FENCE_MANAGER, "OnEnterSell", function(...)
        zo_callLater(function() FCOIS.PreHookButtonHandler(LF_FENCE_LAUNDER, LF_FENCE_SELL) end, 50)
    end)
    ZO_PreHook(FENCE_MANAGER, "OnEnterLaunder", function(...)
        zo_callLater(function() FCOIS.PreHookButtonHandler(LF_FENCE_SELL, LF_FENCE_LAUNDER) end, 50)
    end)
    ZO_PreHook(FENCE_MANAGER, "OnFenceClosed", function(...)
        if settings.debug then FCOIS.debugMessage( "[FENCE_MANAGER]", "OnFenceClosed", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Avoid the filter panel ID change if the fence_manager is called from a normal vendor, which closes the store:
        --If you directly open the mail panel at the vendor the current panel ID will be reset to LF_INVENTORY and this would be not true!
        if FCOIS.preventerVars.gNoCloseEvent == false then
            FCOIS.gFilterWhere = LF_INVENTORY
            --Change the button color of the context menu invoker
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
        end
    end)

    --======== VENDOR =====================================================
    --Pre Hook the menubar button's (buy, sell, buyback, repair) handler at the vendor
    --> Will be done in event callback function for EVENT_OPEN_STORE + a delay as the buttons are not created before!
    ---> See file src/FCOIS_events.lua, function 'FCOItemSaver_OpenStore("vendor")'
    --Register a secure posthook on visibility change of a scrolllist's row -> At the vendor inventory list
    SecurePostHook(ctrlVars.REPAIR_LIST.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --======== BANK ================================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the bank inventory list
    SecurePostHook(ctrlVars.BANK.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --Pre Hook the 2 menubar button's (take and deposit) handler at the bank
    ZO_PreHookHandler(ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW, "OnMouseUp", function(control, button, upInside)
        --d("bank button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastBankButton~=ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW) then
            FCOIS.lastVars.gLastBankButton = ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_BANK_DEPOSIT, LF_BANK_WITHDRAW) end, 50)
        end
    end)
    ZO_PreHookHandler(ctrlVars.BANK_MENUBAR_BUTTON_DEPOSIT, "OnMouseUp", function(control, button, upInside)
        --d("bank button 2, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastBankButton~=ctrlVars.BANK_MENUBAR_BUTTON_DEPOSIT) then
            FCOIS.lastVars.gLastBankButton = ctrlVars.BANK_MENUBAR_BUTTON_DEPOSIT
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_BANK_WITHDRAW, LF_BANK_DEPOSIT) end, 50)
        end
    end)

    --======== HOUSE BANK ================================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the house bank inventory list
    SecurePostHook(ctrlVars.HOUSE_BANK.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --Pre Hook the 2 menubar button's (take and deposit) handler at the bank
    ZO_PreHookHandler(ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW, "OnMouseUp", function(control, button, upInside)
        --d("house bank button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastHouseBankButton~=ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW) then
            FCOIS.lastVars.gLastHouseBankButton = ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_HOUSE_BANK_DEPOSIT, LF_HOUSE_BANK_WITHDRAW) end, 50)
        end
    end)
    ZO_PreHookHandler(ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_DEPOSIT, "OnMouseUp", function(control, button, upInside)
        --d("house bank button 2, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastHouseBankButton~=ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_DEPOSIT) then
            FCOIS.lastVars.gLastHouseBankButton = ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_DEPOSIT
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_HOUSE_BANK_WITHDRAW, LF_HOUSE_BANK_DEPOSIT) end, 50)
        end
    end)

    --======== GUILD BANK ==========================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the guld bank inventory list
    SecurePostHook(ctrlVars.GUILD_BANK.dataTypes[1], "setupCallback", OnScrollListRowSetupCallback)

    --Pre Hook the 2 menubar button's (take and deposit) handler at the guild bank
    ZO_PreHookHandler(ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW, "OnMouseUp", function(control, button, upInside)
        --d("guild bank button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastGuildBankButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastGuildBankButton~=ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW) then
            FCOIS.lastVars.gLastGuildBankButton = ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_GUILDBANK_DEPOSIT, LF_GUILDBANK_WITHDRAW) end, 50)
        end
    end)
    ZO_PreHookHandler(ctrlVars.GUILD_BANK_MENUBAR_BUTTON_DEPOSIT, "OnMouseUp", function(control, button, upInside)
        --d("guild bank button 2, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastGuildBankButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastGuildBankButton~=ctrlVars.GUILD_BANK_MENUBAR_BUTTON_DEPOSIT) then
            FCOIS.lastVars.gLastGuildBankButton = ctrlVars.GUILD_BANK_MENUBAR_BUTTON_DEPOSIT
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_GUILDBANK_WITHDRAW, LF_GUILDBANK_DEPOSIT) end, 50)
        end
    end)
    --======== SMITHING =============================================================
    local function smithingSetModeHook(smithingCtrl, mode, ...)
        --Hide the context menu at last active panel
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)

        if settings.debug then FCOIS.debugMessage( "[SMITHING:SetMode]","Mode: " .. tostring(mode), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        --Get the filter panel ID by crafting type (to distinguish jewelry crafting and normal)
        local craftingModeAndCraftingTypeToFilterPanelId = FCOIS.mappingVars.craftingModeAndCraftingTypeToFilterPanelId
        local craftingType = GetCraftingInteractionType()
        local filterPanelId
        local showFCOISFilterButtons = false
        --zo_callLater(function()
        --Refinement
        if mode == SMITHING_MODE_REFINMENT then
            filterPanelId = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_REFINE
            showFCOISFilterButtons = true
            --Creation
            --elseif mode == SMITHING_MODE_CREATION then
            --	FCOIS.gFilterWhere = LF_SMITHING_CREATION
            --Deconstruction
        elseif mode == SMITHING_MODE_DECONSTRUCTION then
            filterPanelId = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_DECONSTRUCT
            showFCOISFilterButtons = true
            --Improvement
        elseif mode == SMITHING_MODE_IMPROVEMENT then
            filterPanelId = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_IMPROVEMENT
            showFCOISFilterButtons = true
            --Research
        --elseif mode == SMITHING_MODE_RESEARCH then
        --FCOIS.PreHookButtonHandler(FCOIS.gFilterWhere, LF_SMITHING_RESEARCH)
        end
        if showFCOISFilterButtons == true and mode and FCOIS.gFilterWhere and filterPanelId then
            --d("[FCOIS]smithingSetMode- mode: " ..tostring(mode) .. ", craftType: " ..tostring(craftingType) .. ", filterPanelId: " ..tostring(filterPanelId) .. ", filterWhere: " ..tostring(FCOIS.gFilterWhere))
            FCOIS.PreHookButtonHandler(FCOIS.gFilterWhere, filterPanelId)
        end
    end
    --New with API100029 Dragonhold
    SecurePostHook(ctrlVars.SMITHING_CLASS, "SetMode", smithingSetModeHook)

    --======== ENCHANTING =============================================================
    local function enchantingPreHook()
        --Hide the context menu at last active panel
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)
        if ctrlVars.ENCHANTING:IsSceneShowing() then
            local enchantingMode = ctrlVars.ENCHANTING.enchantingMode
            if settings.debug then FCOIS.debugMessage( "[ENCHANTING:OnModeUpdated]","EnchantingMode: " .. tostring(enchantingMode), true, FCOIS_DEBUG_DEPTH_NORMAL) end

            --d("[FCOIS]Hook ZO_Enchanting.SetEnchantingMode/OnModeUpdated - Mode: " ..tostring(enchantingMode))
            --Creation
            if     enchantingMode == ENCHANTING_MODE_CREATION then
                FCOIS.PreHookButtonHandler(LF_ENCHANTING_EXTRACTION, LF_ENCHANTING_CREATION)
                --Extraction
            elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
                FCOIS.PreHookButtonHandler(LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION)
            end
        end
        --Go on with original function
        return false
    end
    --Posthook the enchanting function SetEnchantingMode() which gets executed as the enchanting tabs are changed
    --ZO_Enchanting:SetEnchantingMode does not exist anymore (PTS -> Scalebreaker) and was replaced by ZO_Enchanting:OnModeUpdated()
    SecurePostHook(ctrlVars.ENCHANTING_CLASS, "OnModeUpdated", enchantingPreHook)

    --======== ALCHEMY =============================================================
    --Prehook the alchemy function which gets executed as the alchemy tabs are changed
    ZO_PreHookHandler(ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION, "OnMouseUp", function(control, button, upInside)
        --d("Alchemy button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastAlchemyButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside) then
            if (FCOIS.otherAddons.potionMakerActive and FCOIS.lastVars.gLastAlchemyButton~=ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION) then
                FCOIS.lastVars.gLastAlchemyButton = ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION
                --zo_callLater(function() FCOIS.PreHookButtonHandler(nil, LF_ALCHEMY_CREATION) end, 50)
            else
                --zo_callLater(function() FCOIS.PreHookButtonHandler(nil, LF_ALCHEMY_CREATION) end, 50)
            end
        end
    end)

    --Another Prehook will be done at the event callback function for the crafting station interact, when the alchemy station
    --gets opened as the PotionMaker addon button will be created then

    --======== CRAFTBAG FRAGMNET=========================================================
    --Register a callback function to the CraftBag fragment state, if the addon CraftBagextended is active
    --to be able to show filter buttons etc. at the mail craftbag and bank craftbag panel as well
    ctrlVars.CRAFT_BAG_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        --d("[FCOIS] CraftBag Fragment state change")
        --Hide the context menu at the active panel
        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        if 	newState == SCENE_FRAGMENT_SHOWING then
            --d("[FCOIS]CraftBag SCENE_FRAGMENT_SHOWING")
            FCOIS.preventerVars.craftBagSceneShowInProgress = true
            if settings.debug then FCOIS.debugMessage( "[CRAFT_BAG_FRAGMENT]","Showing", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Reset the parent panel ID
            FCOIS.gFilterWhereParent = nil

            --Check the filter buttons at the CraftBag panel and create them if they are not there. Return the parent filter panel ID if given (e.g. LF_MAIL)
            local _, parentPanel = FCOIS.CheckFilterButtonsAtPanel(true, LF_CRAFTBAG, LF_CRAFTBAG) --overwrite with LF_CRAFTBAG so it'll create and update the buttons for the craftbag panel, and not the CBE subpanels (mail, trade, bank, vendor, guild bank, etc.)
            --Update the inventory context menu ("flag" icon) so it uses the correct "anti-settings" and the correct colour and right-click callback function
            --depending on the currently shown craftbag "parent" (inventory, mail send, guild bank, guild store)
            if parentPanel == nil then
                _, parentPanel = FCOIS.checkActivePanel(FCOIS.gFilterWhere, LF_CRAFTBAG)
            end

            if settings.debug then FCOIS.debugMessage( "[CRAFT_BAG_FRAGMENT]", ">Parent panel: " .. tostring(parentPanel), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

            --Update the current filter panel ID to "CraftBag"
            FCOIS.gFilterWhere = LF_CRAFTBAG

            --Are we showing a CBE subpanel of another parent panel?
            local cbeOrAGSActive = FCOIS.checkIfCBEorAGSActive(FCOIS.gFilterWhereParent, true)
            if cbeOrAGSActive and parentPanel ~= nil then
                --The parent panel for the craftbag can be one of these
                local supportedPanels = FCOIS.otherAddons.craftBagExtendedSupportedFilterPanels
                if supportedPanels[parentPanel] then
                    --Set the global CBE parentPanel ID to e.g. mail send, vendor, guild bank, bank, trade, ...
                    FCOIS.gFilterWhereParent = parentPanel
                    if settings.debug then FCOIS.debugMessage( "[CRAFT_BAG_FRAGMENT]", ">supported craftbag parent panel: " .. tostring(FCOIS.gFilterWhereParent), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                end
            end
            --Change the additional context-menu button's color in the inventory (Craft Bag button)
            --d("<CraftBag: SCENE_FRAGMENT_SHOWING, before changeContextMenuInvokerButtonColorByPanelId(LF_CRAFTBAG)")
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_CRAFTBAG)

            --				elseif 	newState == SCENE_FRAGMENT_SHOWN then
            --	d("Callback fragment CRAFTBAG: Shown")

            --				elseif 	newState == SCENE_FRAGMENT_HIDING then
            --	d("Callback fragment CRAFTBAG: Hiding")
            FCOIS.preventerVars.craftBagSceneShowInProgress = false
            --------------------------------------------------------------------------------------------------------------------
        elseif  newState == SCENE_FRAGMENT_HIDDEN then
            --d("[FCOIS]CraftBag SCENE_FRAGMENT_HIDDEN")
            if settings.debug then FCOIS.debugMessage( "[CRAFT_BAG_FRAGMENT]", "Hidden", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Reset the CraftBag filter parent panel ID
            FCOIS.gFilterWhereParent = nil
            --Hide the context menu at last active panel
            FCOIS.hideContextMenu(LF_CRAFTBAG)

            --Needs to be done here as changing the CraftBag at the mail panel e.g. will not call PreHookButtonHandler function!
            --So we need to get the active filter panel ID after the craftbag was closed again, and update the additional inventory flag icon at thius panel too.
            --> Wait a few milliseconds for the function FCOIS.PreHookButtonHandler to be run (if it is run! Won't be run e.g if the craftbag scene get's closed/changed
            --> via a keybind/ESC key or by other means then the click on another inventory button!)
            --zo_callLater(function()
            --If the delayed hide craftbag scene stuff gets into a new craftbag scene show call:
            --Abort the hide functions now
            if FCOIS.preventerVars.craftBagSceneShowInProgress then
                --d("<CraftBag SCENE_FRAGMENT_HIDDEN: craftBagSceneShowInProgress 1 ->Abort!")
                FCOIS.preventerVars.gPreHookButtonHandlerCallActive = false
                return false
            end
            -->Check within this time if FCOIS.PreHookButtonHandler function was called and do not execute the craftbag_scene_hidden->checkActivePanel stuff then!
            if FCOIS.preventerVars.gPreHookButtonHandlerCallActive then
                --d("<CraftBag SCENE_FRAGMENT_HIDDEN: PreeHookButtonHandler already called ->Abort!")
                FCOIS.preventerVars.gPreHookButtonHandlerCallActive = false
                return false
            end
            --Get the new active filter panel ID -> FCOIS.gFilterWhere (in function CheckFilterButtonAtPanel the function FCOIS.checkActivePanel will be called!)
            --Check the filter buttons and create them if they are not there. Be sure to leave the filterPanelId = nil so it will be properly new determined
            --by help of the shown control (names), and not only the libFilters constant LF_*!
            FCOIS.CheckFilterButtonsAtPanel(true, nil)
            if settings.debug then FCOIS.debugMessage( "[CRAFT_BAG_FRAGMENT]", ">new panel: " .. tostring(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Change the additional context-menu button's color in the inventory (new active filter panel ID)
            --d("<CraftBag: SCENE_FRAGMENT_HIDDEN before changeContextMenuInvokerButtonColorByPanelId(" .. FCOIS.gFilterWhere .. ")")
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
            --end, 50)
        end
    end)
    --======== MAIL SEND ================================================================
    --Register a callback function for the mail send scene
    ctrlVars.MAIL_SEND_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[MAIL_SEND_SCENE]","State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updated!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)

        --When the mail send panel is showing up
        if newState == SCENE_SHOWING then
            --Check if craftbag is active and change filter panel and parent panel accordingly
            FCOIS.gFilterWhere, FCOIS.gFilterWhereParent = FCOIS.checkCraftbagOrOtherActivePanel(LF_MAIL_SEND)

            --Check if another filter panel was already opened and we are coming form there before the CLOSE EVENT function was called
            if FCOIS.preventerVars.gActiveFilterPanel == true then
                --Set the "No Close Event" flag so the called close event won't override gFilterWhere and update the filter button colors and callback handlers
                FCOIS.preventerVars.gNoCloseEvent = true
            end

            --Change the button color of the context menu invoker
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
            --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
            FCOIS.CheckFilterButtonsAtPanel(true, FCOIS.gFilterWhere)

            --When the mail send panel is hiding
        elseif newState == SCENE_HIDING then
            --d("mail scene hiding")
            --Update the current filter panel ID to "Mail"
            FCOIS.gFilterWhere = LF_MAIL_SEND

            --Hide the context menu at mail panel
            FCOIS.hideContextMenu(FCOIS.gFilterWhere)

            --When the mail send panel is hidden
        elseif newState == SCENE_HIDDEN then
            --d("mail scene hidden")

            --Update the inventory filter buttons
            FCOIS.updateFilterButtonsInInv(-1)
            --Update the 4 inventory button's color
            FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)

            FCOIS.preventerVars.gActiveFilterPanel = false
            FCOIS.preventerVars.gNoCloseEvent = false

            --Change the button color of the context menu invoker
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
            --Check, if the Anti-* checks need to be enabled again
            FCOIS.autoReenableAntiSettingsCheck("MAIL")
        end
    end)
    --======== SCENE CALLBACKS (see FCOIS.mappingVars.sceneControlsToRegisterStateChangeForContextMenu) ================
    --Code to loop over scenes and creae a callback function for them.
    --The scene names to add register a callback for StateChange to hide the FCOIS context menu(s).
    local sceneControlsToRegisterStateChangeForContextMenu = mappingVars.sceneControlsToRegisterStateChangeForContextMenu
    if sceneControlsToRegisterStateChangeForContextMenu then
        for _, sceneControl in ipairs(sceneControlsToRegisterStateChangeForContextMenu) do
            if sceneControl ~= nil and sceneControl.RegisterCallback then
                sceneControl:RegisterCallback("StateChange", function(oldState, newState)
                    local sceneName = sceneControl.name or "UNKNOWN SCENE NAME"
                    if settings.debug then FCOIS.debugMessage( "[" .. tostring(sceneName) .. "]","State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
                    FCOIS.sceneCallbackHideContextMenu(oldState, newState)
                    --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
                    --So do this here now:
                    FCOIS.resetInventoryAntiSettings(newState)
                end)
            end
        end
    end
    --======== RETRAIT ================================================================
    --Register a callback function for the siege bar scene
    ctrlVars.RETRAIT_KEYBOARD_INTERACT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[RETRAIT SCENE]","State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        FCOIS.sceneCallbackHideContextMenu(oldState, newState)
        if     newState == SCENE_SHOWING then
            --Check if craftbag is active and change filter panel and parent panel accordingly
            FCOIS.gFilterWhere, FCOIS.gFilterWhereParent = FCOIS.checkCraftbagOrOtherActivePanel(LF_RETRAIT)

            --Check if another filter panel was already opened and we are coming form there before the CLOSE EVENT function was called
            --if FCOIS.preventerVars.gActiveFilterPanel == true then
            --Set the "No Close Event" flag so the called close event won't override gFilterWhere and update the filter button colors and callback handlers
            --    FCOIS.preventerVars.gNoCloseEvent = true
            --end

            --Change the button color of the context menu invoker
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
            --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
            FCOIS.CheckFilterButtonsAtPanel(true, LF_RETRAIT)

        elseif newState == SCENE_HIDING then
            --Update the current filter panel ID to "Retrait"
            FCOIS.gFilterWhere = LF_RETRAIT

            --Hide the context menu at mail panel
            FCOIS.hideContextMenu(FCOIS.gFilterWhere)

            --When the mail send panel is hidden
        elseif newState == SCENE_HIDDEN then
            --Update the inventory filter buttons
            FCOIS.updateFilterButtonsInInv(-1)
            --Update the 4 inventory button's color
            FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)

            FCOIS.preventerVars.gActiveFilterPanel = false
            FCOIS.preventerVars.gNoCloseEvent = false

            --Change the button color of the context menu invoker
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
            --Check, if the Anti-* checks need to be enabled again
            FCOIS.autoReenableAntiSettingsCheck("RETRAIT")
        end
    end)


    --======== Extraction / Refinement / Deconstruction / Improvement functions =======================
    --PreHook the enchanting extract function to check if no marked item is currently in the extraction slot
    ZO_PreHook("ExtractEnchantingItem", function()
        return FCOIS.craftingPrevention.CheckPreventCrafting()
    end)
    --PreHook the enchanting create function to check if no marked item is currently in the creation slot
    ZO_PreHook("CraftEnchantingItem", function()
        return FCOIS.craftingPrevention.CheckPreventCrafting()
    end)
    --PreHook the crafting refine/extract function to check if no marked item is currently in the extraction slot
    ZO_PreHook("ExtractOrRefineSmithingItem", function()
        return FCOIS.craftingPrevention.CheckPreventCrafting()
    end)
    --PreHook the crafting improvement function to check if no marked item is currently in the improvement slot
    ZO_PreHook(ctrlVars.SMITHING.improvementPanel, "Improve", function()
        return FCOIS.craftingPrevention.CheckPreventCrafting()
    end)

    --======== Stack split dialog - Callback function for button 1 (Yes) ===============================
    --PreHook stack split dialog YES button function to set the preventer variable to disable the item protection/anti-checks
    ZO_PreHook("ZO_Dialogs_ShowDialog", function(dialogName, inventorySlotControl)
        --d("[FCOIS]ZO_Dialogs_ShowDialog, dialogName: " ..tostring(dialogName) .. ", splitItemStackDialogButtonCallbacks: " .. tostring(FCOIS.preventerVars.splitItemStackDialogButtonCallbacks))
        if FCOIS.preventerVars.splitItemStackDialogButtonCallbacks then return false end
        zo_callLater(function()
            if ZO_Dialogs_IsShowing(ctrlVars.DIALOG_SPLIT_STACK_NAME) then
                local dialog = ZO_Dialogs_FindDialog(dialogName)
                if dialog then
                    local NUM_DIALOG_BUTTONS = dialog.numButtons or 2 --YES and NO
                    for i = 1, NUM_DIALOG_BUTTONS do
                        local btn = dialog.info.buttons[i]
                        if btn ~= nil and btn.callback ~= nil then
                            if btn.text and btn.text == SI_INVENTORY_SPLIT_STACK then
                                ZO_PreHook(btn, "callback", function()
                                    --PreHook the callback function for the YES button
                                    FCOIS.preventerVars.splitItemStackDialogActive = true
                                end)
                                FCOIS.preventerVars.splitItemStackDialogButtonCallbacks = true
                            else
                                ZO_PreHook(btn, "callback", function()
                                    --PreHook the callback function for the NO button
                                    FCOIS.preventerVars.splitItemStackDialogActive = false
                                end)
                            end
                        end
                    end
                end
            end
        end, 50)
    end)
    --This functiuon will be called from the stack split dialog if the dialog button YES is pressed
    ZO_PreHook("ZO_InventoryLandingArea_DropCursorInBag", function(bagId)
        --d("[FCOIS]ZO_InventoryLandingArea_DropCursorInBag, splitItemStackDialogActive: " ..tostring(FCOIS.preventerVars.splitItemStackDialogActive))
        --Split stack dialog was active and clicked/used the keybind for "YES"
        FCOIS.preventerVars.splitItemStackDialogActive = true
    end)

    --======== General dialog hooks ============================================================
    local resetZOsDialogVariables = FCOIS.resetZOsDialogVariables -- See file src/FCOIS_Dialogs.lua
    --Is the dialog close keybind pressed?
    ZO_PreHook("ZO_Dialogs_CloseKeybindPressed", function()
        resetZOsDialogVariables()
    end)
    --Is the dialog close keybind pressed?
    ZO_PreHook("ZO_Dialogs_ReleaseAllDialogsOfName", function(dialogName)
        if dialogName == ctrlVars.DIALOG_SPLIT_STACK_NAME then
            resetZOsDialogVariables()
        end
    end)

    --======== Hooks at the inventory and crafting filter functions ==================================
    --Player Inventory
    --ZO_PreHook(PLAYER_INVENTORY, "ChangeFilter", function() d("[FCOIS]Player_Inventory ChangeFilter") FCOIS.updateFilteredItemCountThrottled(filterPanelId, delay) end)
    --Smithing
    ZO_PreHook(ctrlVars.SMITHING.refinementPanel.inventory,         "ChangeFilter", function() FCOIS.updateFilteredItemCountThrottled(nil, 50, "Smithing refine - ChangeFilter") end)
    ZO_PreHook(ctrlVars.SMITHING.deconstructionPanel.inventory,     "ChangeFilter", function() FCOIS.updateFilteredItemCountThrottled(nil, 50, "Smithing decon - ChangeFilter") end)
    ZO_PreHook(ctrlVars.SMITHING.improvementPanel.inventory,        "ChangeFilter", function() FCOIS.updateFilteredItemCountThrottled(nil, 50, "Smithing improve - ChangeFilter") end)
    --Retrait
    ZO_PreHook(ctrlVars.RETRAIT_RETRAIT_PANEL.inventory,            "ChangeFilter", function() FCOIS.updateFilteredItemCountThrottled(nil, 50, "Retrait - ChangeFilter") end)
    --Enchanting
    ZO_PreHook(ctrlVars.ENCHANTING.inventory,                       "ChangeFilter", function() FCOIS.updateFilteredItemCountThrottled(nil, 50, "Enchanting - ChangeFilter") end)
    --PreHook the QuickSlotWindow change filter function
    local function ChangeFilterQuickSlot(self, filterData)
        FCOIS.updateFilteredItemCountThrottled(LF_QUICKSLOT, 50, "Quickslots - ChangeFilter")
    end
    ZO_PreHook(ctrlVars.QUICKSLOT_WINDOW, "ChangeFilter", ChangeFilterQuickSlot)
    --Update the count of items filtered if text search boxes are used (ZOs or Votans Search Box)
    ZO_PreHook(ctrlVars.INVENTORY_MANAGER, "UpdateEmptyBagLabel", function(ctrl, inventoryType, isEmptyList)
        local inventories = ctrlVars.inventories
        if not inventories then return false end
        --Check if the currently active focus in inside a search box
        local inventory = inventories[inventoryType]
        local searchBox
        --Normal inventory update without searchBox changed
        local delay = 50
        if inventory then
            local goOn = false
            local searchBoxIsEmpty = false
            searchBox = inventory.searchBox
            if searchBox and searchBox.GetText then
                local searchBoxText = searchBox:GetText()
                searchBoxIsEmpty = (searchBoxText == "") or false
                if not searchBoxIsEmpty then
                    --Check if the contents of the searchbox are not only spaces
                    local searchBoxTextWithoutSpaces = string.match(searchBoxText, "%S") -- %S = NOT a space
                    if searchBoxTextWithoutSpaces and searchBoxTextWithoutSpaces ~= "" then
                        goOn = true
                    else
                        searchBoxIsEmpty = true
                    end
                end
            end
            --SearchBox exists and is not empty
            if searchBox and not searchBoxIsEmpty then
                --Delay for search box updated
                delay = 250
                goOn = true
            elseif not searchBox or (searchBox and searchBoxIsEmpty) then
                --Delay for normal label update
                delay = 50
                goOn = true
            end
            if not goOn then return false end
        end
        --d("[FCOIS]UpdateEmptyBagLabel, isEmptyList: " ..tostring(isEmptyList))
        --Update the count of filtered/shown items before the sortHeader "name" text
        local filterPanelId  = FCOIS.gFilterWhere
        --Special checks for the filterPanelId, for e.g. "QUEST items"
        if inventoryType == INVENTORY_QUEST_ITEM then
            filterPanelId = "INVENTORY_QUEST_ITEM"
        end
        FCOIS.updateFilteredItemCountThrottled(filterPanelId, delay, "ZO_InventoryManager - UpdateEmptyBagLabel")
    end)
    --Update inventory slot labels
    ZO_PreHook("UpdateInventorySlots", function()
        --d("[FCOIS]UpdateInventorySlots")
        --This variable (FCOIS.preventerVars.dontUpdateFilteredItemCount) is set within file src/FCOIS_FilterButtons.lua, function FCOIS.updateFilteredItemCount 
        --if the addon AdvancedFilters is used, and the AF itemCount is enabled (next to the inventory free slots labels),
        --and FCOIS is calling the function AF.util.updateInventoryInfoBarCountLabel.
        -->Otherwise we would create an endless loop here which will be AF.util.updateInventoryInfoBarCountLabel -> UpdateInventorySlots ->
        --PreHook in FCOIS to function UpdateInventorySlots -> FCOIS.updateFilteredItemCountThrottled -> FCOIS.updateFilteredItemCount -> AF.util.updateInventoryInfoBarCountLabel ...
        if not FCOIS.preventerVars.dontUpdateFilteredItemCount then
            FCOIS.updateFilteredItemCountThrottled(nil, 50, "UpdateInventorySlots")
        end
    end)

    --[[
    local mailSendAttachmentSlots = FCOIS.ZOControlVars.MAIL_SEND.attachmentSlots
    if mailSendAttachmentSlots ~= nil then
        for _, attachmentSlot in ipairs(mailSendAttachmentSlots) do

        end
    end
    ]]

    --Test if CraftBag raises OnInventorySlotLocked as well
    --[[
    ZO_PreHook(PLAYER_INVENTORY, "OnInventorySlotLocked", function(ctrl, bagId, slotIndex)
        d("[FCOIS]OnInventorySlotLocked, bagId: " ..tostring(bagId) .. ", slotIndex: " ..tostring(slotIndex))
    end)
    ]]

    --Prevent researching!
    --[[
    ZO_PreHook("ResearchSmithingTrait", function()
        d("[FCOIS]Research would be started now, but aborting 'ResearchSmithingTrait' now!")
        return true
    end)
    ]]

    --======== TEST HOOKS =============================================================================
    --Call some test hooks
    --callTestHooks(settings.testHooks)

end  -- function CreateHooks()
--============================================================================================================================================================
--===== HOOKS END ============================================================================================================================================
--============================================================================================================================================================