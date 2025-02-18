--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local libFilters = FCOIS.libFilters
 local otherAddons = FCOIS.otherAddons

local debugMessage                          = FCOIS.debugMessage

local tos                                   = tostring
local strformat                             = string.format
local strmatch                              = string.match
local tins                                  = table.insert

local giid                                  = GetItemId
local gil                                   = GetItemLink
local giet                                  = GetItemEquipType

local addonVars                             = FCOIS.addonVars
local addonName                             = addonVars.gAddonName

local CM                                    = CALLBACK_MANAGER

local ctrlVars                              = FCOIS.ZOControlVars
local invSceneName                          = ctrlVars.invSceneName

local backpackCtrl =            ctrlVars.BACKPACK
local characterCtrl =           ctrlVars.CHARACTER
local companionCharacterCtrl =  ctrlVars.COMPANION_CHARACTER
local houseBankCtrl =           ctrlVars.HOUSE_BANK_BAG
local guildBankCtrl =           ctrlVars.GUILD_BANK_BAG
local bankCtrl =                ctrlVars.BANK_BAG
--local deconstructionCtrl =      ctrlVars.DECONSTRUCTION_BAG
local universalDeconGlobal =    ctrlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL
local universalDeconPanel =     universalDeconGlobal and universalDeconGlobal.deconstructionPanel

local numFilterIcons                        = FCOIS.numVars.gFCONumFilterIcons
local mappingVarsTransm                     = FCOIS.mappingVars.containerTransmuation

local onDeferredInitCheck                   = FCOIS.onDeferredInitCheck

local checkBindableItems
local checkIfItemIsProtected                = FCOIS.CheckIfItemIsProtected
local myGetItemDetails                      = FCOIS.MyGetItemDetails
local isCraftBagItemDraggedToCraftingSlot   = FCOIS.IsCraftBagItemDraggedToCraftingSlot
local checkPreventCrafting                  = FCOIS.craftingPrevention.CheckPreventCrafting
local myGetItemInstanceId                   = FCOIS.MyGetItemInstanceId
local getCurrentSceneInfo                   = FCOIS.GetCurrentSceneInfo
local changeDialogButtonState               = FCOIS.ChangeDialogButtonState
local isRepairDialogShown                   = FCOIS.IsRepairDialogShown
local isEnchantDialogShown                  = FCOIS.IsEnchantDialogShown
local isSoulGem                             = FCOIS.IsSoulGem
local isItemType                            = FCOIS.IsItemType
local isCharacterShown                      = FCOIS.IsCharacterShown
local isCompanionCharacterShown             = FCOIS.IsCompanionCharacterShown
local resetInventoryAntiSettings            = FCOIS.ResetInventoryAntiSettings
local isSupportedInventoryRowPattern        = FCOIS.IsSupportedInventoryRowPattern
local isModifierKeyPressed                  = FCOIS.IsModifierKeyPressed
local isNoOtherModifierKeyPressed           = FCOIS.IsNoOtherModifierKeyPressed
local showProtectionDialog                  = FCOIS.ShowProtectionDialog
local showCompanionProgressBar              = FCOIS.ShowCompanionProgressBar
local showPlayerProgressBar                 = FCOIS.ShowPlayerProgressBar
local isDeconstructionHandlerNeeded         = FCOIS.IsDeconstructionHandlerNeeded
local getFilterWhereBySettings              = FCOIS.GetFilterWhereBySettings
local addInventorySecurePostHookDoneEntry   = FCOIS.addInventorySecurePostHookDoneEntry
local checkIfInventorySecurePostHookWasDone = FCOIS.checkIfInventorySecurePostHookWasDone

local removeArmorTypeMarker
local updateEquipmentSlotMarker
local filterBasics
local changeContextMenuEntryTexts
local localization
local checkAndShowTransmutationGeodeLootDialog
local checkIfClearOrRestoreAllMarkers
local hideContextMenu
local isVendorPanelShown
local callDeconstructionSelectionHandler
local callItemSelectionHandler
local createMarkerControl, addMarkerIconsToControl
local addMark
local updateEquipmentHeaderCountText

--LibCustomMenu
local lcm                                 = FCOIS.LCM


local checkIfUniversalDeconstructionNPC
local getCurrentFilterPanelIdAtDeconNPC

--==========================================================================================================================================
--									FCOIS Pre-Hooks & Hooks / Scene & Fragment callback functions
--==========================================================================================================================================

--==============================================================================
--TEST hooks
--==============================================================================
function FCOIS.TestHooks(activateTestHooks)
    if activateTestHooks ~= nil and type(activateTestHooks) == "boolean" then
        FCOIS.settingsVars.settings.testHooks = activateTestHooks
    else
        --Toggle the testhooks savedvars variable
        FCOIS.settingsVars.settings.testHooks = not FCOIS.settingsVars.settings.testHooks
    end
    --Show the test hooks variable
    d("[FCOIS] Test hooks: " .. tos(FCOIS.settingsVars.settings.testHooks))
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
local function override(objectTable, existingFunctionName, hookFunction)
    if (type(objectTable) == "string") then
        hookFunction         = existingFunctionName
        existingFunctionName = objectTable
        objectTable          = _G
    end
    local existingFn = objectTable[existingFunctionName]
    if ((existingFn ~= nil) and (type(existingFn) == "function")) then
        local newFn                       = function(...)
            return hookFunction(existingFn, ...)
        end
        objectTable[existingFunctionName] = newFn
    end
end

--==============================================================================
--			Pre-Hook Handler Methods
--==============================================================================
-- gets handler from the event handler list
local function getEventHandler(eventName, objName)
    local eventHandler = FCOIS.eventHandlers[eventName]
    if not eventHandler then return nil end
    --Get the global event handler function of an object name
    return eventHandler[objName]
end

-- adds handler to the event handler list
local function setEventHandler(eventName, objName, handler)
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

--==============================================================================
--			Context menu / right click / slot actions
--==============================================================================
--Check if the localization data of the context menu is given
local function checkAndUpdateContextMenuLocalizationData()
    --d("[FCOIS]checkAndUpdateContextMenuLocalizationData")
    local locVars              = FCOIS.localizationVars
    local doUpdateLocalization = false
    local settings             = FCOIS.settingsVars.settings
    if not locVars then
        doUpdateLocalization = true
    end
    if not doUpdateLocalization then
        local locEntriesToCheck = {
            ["lTextEquipmentMark"]   = true,
            ["lTextEquipmentDemark"] = true,
            ["lTextMark"]            = true,
            ["lTextDemark"]          = true,
        }
        for key, isToCheck in pairs(locEntriesToCheck) do
            if isToCheck == true and not doUpdateLocalization then
                if locVars[key] == nil then
                    --d(">key not found: " ..tos(key))
                    doUpdateLocalization = true
                    break
                end
                --Check if the texts for the filter icons exists
                for iconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                    local isIconEnabled = settings.isIconEnabled[iconId]
                    if locVars[key][iconId] == nil and isIconEnabled == true then
                        --d(">key's iconId not found: " ..tos(key) .. ", icon: " ..tos(iconId) .. ", iconEnabled: " .. tos(isIconEnabled))
                        doUpdateLocalization = true
                        break
                    end
                end
            end
        end
    end
    --Should the localization be rebuild now?
    if doUpdateLocalization == true then
        --d("[FCOIS]checkAndUpdateContextMenuLocalizationData - Update the localization now")
        --Re-Do the localization done variable and rebuild all localization
        localization = localization or FCOIS.Localization
        localization()
        --Overwrite the localized texts for the marker icons in the context menus
        changeContextMenuEntryTexts = changeContextMenuEntryTexts or FCOIS.ChangeContextMenuEntryTexts
        changeContextMenuEntryTexts(-1)
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
    local _, currentSceneName = getCurrentSceneInfo()
    if isCharacterShown() and currentSceneName == invSceneName then
        --Show the PlayerProgressBar again as the context menu closes
        showPlayerProgressBar(true)
    elseif isCompanionCharacterShown() and currentSceneName == ctrlVars.companionInvSceneName then
        --Show the CompanionProgressBar again as the context menu closes
        showCompanionProgressBar(true)
    end
end)

--Called before "Use" at a SlotAction. See function FCOIS_preUseAddSlotActionCallbackFunc and FCOIS.OverrideUseAddSlotAction
--and the Override function
function FCOIS.UseAddSlotActionCallbackFunc(self)
    --d("[FCOIS.useAddSlotActionCallbackFunc]")
    --is the option to show the protection dialog for transmuation geode containers enabled?
    local settings = FCOIS.settingsVars.settings
    if settings.showTransmutationGeodeLootDialog and not FCOIS.preventerVars.doNotShowProtectDialog then
        local bag, slotIndex
        local dataEntryData = self.dataEntry and self.dataEntry.data
        if dataEntryData then
            bag       = dataEntryData.bagId
            slotIndex = dataEntryData.slotIndex
        end
        if bag == nil or slotIndex == nil and self.m_inventorySlot ~= nil then
            bag, slotIndex = ZO_Inventory_GetBagAndIndex(self.m_inventorySlot)
        end
        if bag == nil or slotIndex == nil then return false end
        --Check if the item is a Transmutation geode container and usable
        local isContainer = isItemType(bag, slotIndex, ITEMTYPE_CONTAINER) or false
        --d(">Item is a container: " .. tos(isContainer))
        if isContainer == true then
            --local itemLink = gil(bag, slotIndex)
            local transmGeodenIds = mappingVarsTransm.geodeItemIds
            if transmGeodenIds == nil then return false end
            local itemId = giid(bag, slotIndex)
            --d(">itemId: " ..tos(itemId))
            if itemId == nil then return false end
            --Check the itemIds of the possible transmuation geodes against the current item
            if transmGeodenIds[itemId] then
                checkAndShowTransmutationGeodeLootDialog = checkAndShowTransmutationGeodeLootDialog or FCOIS.CheckAndShowTransmutationGeodeLootDialog
                local doShowTransmuationProtectionDialog, currentTransmCrystalCount, maxTransmCrystalCount = checkAndShowTransmutationGeodeLootDialog()
                --d(">doShowTransmuationProtectionDialog: " ..tos(doShowTransmuationProtectionDialog) .. ", current/max: " ..tos(currentTransmCrystalCount) .. "/" .. tos(maxTransmCrystalCount))
                if doShowTransmuationProtectionDialog == true then
                    local data       = {}
                    data.replaceVars = {}
                    tins(data.replaceVars, currentTransmCrystalCount)
                    tins(data.replaceVars, maxTransmCrystalCount)
                    data.callbackYes = function()
                        FCOIS.preventerVars.doNotShowProtectDialog = true
                        if IsProtectedFunction("UseItem") then
                            CallSecureProtected("UseItem", bag, slotIndex)
                        else
                            UseItem(bag, slotIndex)
                        end
                        FCOIS.preventerVars.doNotShowProtectDialog = false
                    end
                    data.callbackNo  = function() return true end
                    --Show the ask dialog now
                    local locVar     = FCOIS.localizationVars.fcois_loc
                    showProtectionDialog(locVar["options_enable_block_transmutation_dialog_title"], locVar["options_enable_block_transmutation_dialog_question"], data)
                    return true -- Abort the original use function here!
                end
            end
        end
    end
    return false -- Call the original function now
end
local useAddSlotActionCallbackFunc = FCOIS.UseAddSlotActionCallbackFunc

--Called at "Use" SlotAction, before the usage of the item
local function FCOIS_preUseAddSlotActionCallbackFunc(self, func, ...)
    --Check if the container needs to be opened
    local retVar = useAddSlotActionCallbackFunc(self) -- true: Abort the normal function "UseItem" so the container is not opened / false: call original function
    --d("[FCOIS_preUseAddSlotActionCallbackFunc] retVar: " .. tos(retVar))
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
    if (actionStringId == SI_ITEM_ACTION_USE and not backpackCtrl:IsHidden()) then
        return parentFunc(
                self, SI_ITEM_ACTION_USE,
                function(...) return FCOIS_preUseAddSlotActionCallbackFunc(self, actionCallback, ...) end,
                ...
        )
    end
    --Else execute the original "Use" function callback
    return parentFunc(self, actionStringId, actionCallback, ...)
end
local overrideUseAddSlotAction = FCOIS.OverrideUseAddSlotAction

--==============================================================================
--			ON EVENT Methods (drag/drop, doubleclick, ...)
--==============================================================================

-- handler function for inventory item controls' OnMouseUp event
function FCOIS.OnInventoryItemMouseUp(self, mouseButton, upInside, ctrlKey, altKey, shiftKey, ...)
--d("[FCOIS]InventoryItem_OnMouseUp] mouseButton: " .. tos(mouseButton) .. ", upInside: " .. tos(upInside).. ", ctrlKey: " .. tos(ctrlKey) .. ", altKey: " .. tos(altKey).. ", shiftKey: " .. tos(shiftKey) .. ", dontShowContextMenu: " ..tos(FCOIS.preventerVars.dontShowInvContextMenu))
    FCOIS.preventerVars.dontShowInvContextMenu = false
    --Enable clearing all markers by help of the <modifier key>+right click?
    local contextMenuClearMarkesKey            = FCOIS.settingsVars.settings.contextMenuClearMarkesModifierKey
    local isModifierKeyPressedNow              = isModifierKeyPressed(contextMenuClearMarkesKey)
    checkIfClearOrRestoreAllMarkers = checkIfClearOrRestoreAllMarkers or FCOIS.CheckIfClearOrRestoreAllMarkers
    checkIfClearOrRestoreAllMarkers(self, isModifierKeyPressedNow, upInside, mouseButton, false, false)
    --Call original callback function for event OnMouseUp of the iinventory item row/character equipment slot now
    --d("<end OnMouseUp")
    return false
end
local onInventoryItemMouseUp = FCOIS.OnInventoryItemMouseUp

--Add the OnMouseUp event handler to the scroll list's row control
local function addOnMouseUpEventHandlerToRow(rowControl)
--d("[FCOIS]addOnMouseUpEventHandlerToRow - rowControl: " ..tos(rowControl:GetName()) .. ", gFilterWhere: " ..tos(FCOIS.gFilterWhere))
    if not rowControl then return end
    --Only if the <modifier key> + right click settings is enabled within FCOIS
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
    if contextMenuClearMarkesByShiftKey == true then
        local rowName     = rowControl:GetName()
        --Is the row a supported inventory row pattern?
        local isInvRow, _ = isSupportedInventoryRowPattern(rowName)
        if isInvRow == true then
--d(">rowPattern is supported")
            -- Append OnMouseUp event of inventory item controls, for each row (children), if it is not already set there before inside the if via SetEventHandler(...)
            if not getEventHandler("OnMouseUp", rowName) then
                --Speed up: Only set boolean value to prevent addition of handler on the same row again (as you scroll, as the same rows are re-used in a pool!)
                setEventHandler("OnMouseUp", rowName, true)
                --Use ZOs function to PreHook the event handler now
                -->Throws isnecure error message as you use the context menu to "Destroy" an item! -> Tainting the inventory row handler code as the function OnMouseUp is overwrritten with the
                -->PreHook. So we use new ZOs way to do it via the additional applied handler with the own nameSpace "addonName" -> "FCOItemSaver"
                --[[
                ZO_PreHookHandler(rowControl, "OnMouseUp", function(...)
                    onInventoryItemMouseUp(...)
                end)
                ]]
                rowControl:SetHandler("OnMouseUp", function(...)
                    onInventoryItemMouseUp(...)
                end, addonName)
            end
        end
    end
end

--A setupCallback function for the scrolllists of the inventories.
--> Will add the FCOIS marker icons if they get visible and add the OnMouseUp handlers to the rows to support the SHIFT+right mouse button features
local function onScrollListRowSetupCallback(rowControl, data, selected, onlyOnMouseUpHandlers)
    --d("[FCOIS]OnScrollListRow:SetupCallback - gFilterWhere: " ..tos(FCOIS.gFilterWhere))
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

    if not onlyOnMouseUpHandlers then
        --Duplicate call to FCOIS.CreateMarkerControl -> needed for "at least some" of the inventories,
        --like the crafting tables. But we need to filter the update of the marker controls for the others,
        --like normal inventories!
        -- For some inventories like crafting tables: Create/Update the icons
        local inventoryVars            = FCOIS.inventoryVars
        local hookScrollSetupCallbacks = inventoryVars.markerControlInventories and inventoryVars.markerControlInventories.hookScrollSetupCallback
        if hookScrollSetupCallbacks[inventoryListControl] ~= nil then
            --d(">>it's a valid crafting inventory scrollList setupCallback")
            --[[
            createMarkerControl = createMarkerControl or FCOIS.CreateMarkerControl

            local settings            = FCOIS.settingsVars.settings
            local iconSettings        = settings.icon
            local iconVars            = FCOIS.iconVars
            local textureVars         = FCOIS.textureVars

            for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                local iconData = iconSettings[i]
                createMarkerControl(rowControl, i, iconData.size or iconVars.gIconWidth, iconData.size or iconVars.gIconWidth, textureVars.MARKER_TEXTURES[iconData.texture])
            end
            ]]

            --#278
            addMarkerIconsToControl = addMarkerIconsToControl or FCOIS.AddMarkerIconsToControl
            addMarkerIconsToControl(rowControl, nil)
        end
    end
    --Add additional FCO point to the dataEntry.data slot
    --FCOItemSaver_AddInfoToData(rowControl)

    --Update the mouse double click handler OnEffectivelyShown() at the row
    addOnMouseUpEventHandlerToRow(rowControl)
end
FCOIS.onScrollListRowSetupCallback = onScrollListRowSetupCallback

--Prehook function to ZO_InventorySlot_DoPrimaryAction to secure items as doubleclick or keybind of primary was raised
local function FCOItemSaver_OnInventorySlot_DoPrimaryAction(inventorySlot)
    checkIfUniversalDeconstructionNPC = checkIfUniversalDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC
--d("FCOItemSaver_OnInventorySlot_DoPrimaryAction")
    local doNotCallOriginalZO_InventorySlot_DoPrimaryAction = false
    --Hide the context menu at last active panel
    hideContextMenu = hideContextMenu or FCOIS.HideContextMenu
    hideContextMenu(FCOIS.gFilterWhere)
    --Check if SHIFT key is pressed and if settings to use SHIFT key + right mouse to remove/restore marker icons on the inventory row is enabled
    -->Then do not call the double click handler here
    local settings                         = FCOIS.settingsVars.settings
    local contextMenuClearMarkesByShiftKey = settings.contextMenuClearMarkesByShiftKey
    local contextMenuClearMarkesKey        = settings.contextMenuClearMarkesModifierKey
    if contextMenuClearMarkesByShiftKey == true and isModifierKeyPressed(contextMenuClearMarkesKey) then return false end

    --Check where we are
    local parent          = inventorySlot:GetParent()
    local isABankWithdraw = (parent == bankCtrl or parent == guildBankCtrl or parent == houseBankCtrl)
    local isCharacter     = (parent == characterCtrl) or false
    isVendorPanelShown = isVendorPanelShown or FCOIS.IsVendorPanelShown
    local isVendorRepair  = isVendorPanelShown(LF_VENDOR_REPAIR, false) or false

    --Special case for AwesomeGuildStore -> directly sell to guild store from custom bank fragment
    -->Will be detected as bank here, but actually is guild store sell!
    if isABankWithdraw == true and FCOIS.gFilterWhere == LF_BANK_WITHDRAW and otherAddons.AGSActive ~= nil
        and ctrlVars.GUILD_STORE_SCENE:IsShowing() and ctrlVars.BANK_FRAGMENT:IsShowing() then
        isABankWithdraw = false
    end

    --Do not add protection double click functions to bank/guild bank withdraw and character, and vendor repair
--d(">[FCOIS]FCOItemSaver_OnInventorySlot_DoPrimaryAction - " .. tos(inventorySlot:GetName()) .. ", isBankWithdraw: " ..tos(isABankWithdraw) .. ", isCharacter: " ..tos(isCharacter) .. ", isVendorRepair: " ..tos(isVendorRepair))
    if not isABankWithdraw and not isCharacter and not isVendorRepair then
        --Get the slected inv. row's dataEntry.data with bagId and slotIndex
        local bagId, slotId = myGetItemDetails(inventorySlot)
        if bagId ~= nil and slotId ~= nil then
            --Set: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
            FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = true

            -- Inside deconstruction?
            if isDeconstructionHandlerNeeded() then -- #202
                -- #202
                -- check if deconstruction is forbidden
                -- if so, return true to prevent call of the original function ZO_InventorySlot_DoPrimaryAction of the item
                callDeconstructionSelectionHandler = callDeconstructionSelectionHandler or FCOIS.callDeconstructionSelectionHandler
                if callDeconstructionSelectionHandler(bagId, slotId, true) == true then
                    doNotCallOriginalZO_InventorySlot_DoPrimaryAction = true
                end
                --Others
            else
                --check if item interaction is forbidden
                --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
                callItemSelectionHandler = callItemSelectionHandler or FCOIS.callItemSelectionHandler
                --                         (bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId, panelIdParent)
                if callItemSelectionHandler(bagId, slotId, true, false, false, false, false, false, false, nil, nil) then
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
            --else
            --Refresh the visible inventory row
            --filterBasics = filterBasics or FCOIS.FilterBasics
            --filterBasics(true)
        end
    end
    return doNotCallOriginalZO_InventorySlot_DoPrimaryAction
end

-- handler function for character equipment double click -> OnEffectivelyShown function
local characterEquipmentSlots          = FCOIS.mappingVars.characterEquipmentSlots
local function FCOItemSaver_CharacterOnEffectivelyShown(self, ...)
    if (not self) then return false end
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
    local equipmentSlotName
    characterEquipmentSlots = characterEquipmentSlots or FCOIS.mappingVars.characterEquipmentSlots
    --local isCompanionCharacter = (companionCharacterCtrl:IsHidden() == false) or false
    --local characterBaseCtrl = (isCompanionCharacter == true and companionCharacterCtrl) or characterCtrl
--d("[FCOItemSaver_CharacterOnEffectivelyShown]: " .. self:GetName() .. ", isCompanionCharacter: " ..tos(isCompanionCharacter))
    for i = 1, self:GetNumChildren() do
        -- override OnMouseDoubleClick event of character window item controls, for each row (children)
        local currentCharChild = self:GetChild(i)
        if currentCharChild ~= nil then
            equipmentSlotName = currentCharChild:GetName()
            if equipmentSlotName ~= nil then
                local isEquipmentSlot = characterEquipmentSlots[equipmentSlotName] or false
                --if(string.find(equipmentSlotName, "ZO_CharacterEquipmentSlots")) then
                if isEquipmentSlot == true then
--d(">EquipmentSlot: " ..tos(equipmentSlotName))
                    if contextMenuClearMarkesByShiftKey == true then
                        --Mouse up event for the SHIFT+right mouse button
                        if (not getEventHandler("OnMouseUp", equipmentSlotName)) then
                            --d(">>Set event handler: OnMouseUp")
                            --Add the custom event handler function to a global list so it won't be added twice
                            --Speed up: Only set boolean
                            setEventHandler("OnMouseUp", equipmentSlotName, true)
                            --Use ZO function to PreHook the event handler now
                            ZO_PreHookHandler(currentCharChild, "OnMouseUp", function(...)
                                onInventoryItemMouseUp(...)
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
--d("[FCOIS]FCOItemSaver_OnDragStart-cursorContentType: " .. tos(cursorContentType) .. "/" .. tos(MOUSE_CONTENT_INVENTORY_ITEM))
    --cursorContentType is in 99% of the cases = MOUSE_CONTENT_EMPTY, even if an inventory item gets dragged
    --#233 Workaround for AwesomeGuildSTore which "simulates" an inventory item pickup by sending an emote pickup, to make the "sell from bank fragment" work at the
    --guild store sell panel: https://github.com/sirinsidiator/ESO-AwesomeGuildStore/blob/master/src/wrappers/SellTabWrapper.lua#L518
    if cursorContentType == MOUSE_CONTENT_EMPTY or (otherAddons.AGSActive and cursorContentType == MOUSE_CONTENT_EMOTE) then
        inventorySlot = ZO_InventorySlot_GetInventorySlotComponents(inventorySlot)
    end
--FCOIS._dragStartInventorySlot = inventorySlot

    --FCOIS._inventorySlot=inventorySlot
    FCOIS.dragAndDropVars.bag  = nil
    FCOIS.dragAndDropVars.slot = nil
    local bag, slot = myGetItemDetails(inventorySlot)
    if bag == nil or slot == nil then bag, slot = ZO_Inventory_GetBagAndIndex(inventorySlot) end
--d(">bag, slot: " .. tos(bag) .. ", " .. tos(slot))
    if bag == nil or slot == nil then return end
    FCOIS.dragAndDropVars.bag  = bag
    FCOIS.dragAndDropVars.slot = slot

    --#233 Workaround for AwesomeGuildStore -> "Sell directly from bank". The EVENT_INVENTORY_SLOT_LOCKED will not fire here as
    --sirinsidiator uses
    if otherAddons.AGSActive and cursorContentType == MOUSE_CONTENT_EMOTE
            and ctrlVars.GUILD_STORE_SCENE:IsShowing() and ctrlVars.BANK_FRAGMENT:IsShowing()
            and inventorySlot ~= nil and inventorySlot.slotType == SLOT_TYPE_BANK_ITEM and ZO_InventorySlot_GetStackCount(inventorySlot) > 0 then
--d(">dragStart of inventorySlot at guild store sell - AGS enabled")
        --Simulate firing the EVENT_INVENTORY_SLOT_LOCKED now
        local _
        FCOIS.OnInventorySlotLocked(_, bag, slot)
        FCOIS.OnInventorySlotUnLocked(_, bag, slot)
        --d("<[FCOIS]return true - DragStart")
        return true
    end
end

--Callback function for receive a dragged inventory item. Used for:
--1. Drop of an item at an equipment slot -> Aswk before bind dialog
--2. If CraftBagExtended addon is enabled: Drop of any craftbag item at the mail send/player trade panel as the Drag function will not be
--   executed properly for CraftBag rows. So we need to check if the item is protected and cancel the drop here!
local slotTypeMailOrTrade = {
    [SLOT_TYPE_MAIL_QUEUED_ATTACHMENT] = true,
    [SLOT_TYPE_MAIL_ATTACHMENT] = true,
    [SLOT_TYPE_MY_TRADE] = true
}
local function FCOItemSaver_OnReceiveDrag(inventorySlot)
    --FCOinvs = inventorySlot
    local cursorContentType = GetCursorContentType()
    if FCOIS.settingsVars.settings.debug then debugMessage("[OnReceiveDrag]", "cursorContentType: " .. tos(cursorContentType) .. "/" .. tos(MOUSE_CONTENT_INVENTORY_ITEM) .. ", invSlotType: " .. tos(inventorySlot.slotType) .. "/" .. tos(SLOT_TYPE_EQUIPMENT), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]FCOItemSaver_OnReceiveDrag, cursorContentType: " ..tos(cursorContentType))

    -- if there is an inventory item on the cursor:
    if cursorContentType ~= MOUSE_CONTENT_INVENTORY_ITEM and cursorContentType ~= MOUSE_CONTENT_EQUIPPED_ITEM then return end
    local slotType = inventorySlot.slotType
    local isMailOrTradeSlotType = slotTypeMailOrTrade[slotType] or false
    -- and the slot type we're dropping it on is an equip slot:
    if slotType == SLOT_TYPE_EQUIPMENT then
        local bag
        local slot
        local dragAndDropVars = FCOIS.dragAndDropVars
        --Was the drag started with another item then the dropped item slot?
        if dragAndDropVars.bag ~= nil and dragAndDropVars.slot ~= nil then
            bag  = dragAndDropVars.bag
            slot = dragAndDropVars.slot
            --receiveSlot = inventorySlot.slotIndex
        else
            --get bagid and SlotIndex from receiving inventorySlot -> Makes no sense as the bind dialog shows the wrong item then!
            --bag   = inventorySlot.bagId
            --slot	= inventorySlot.slotIndex
            --Abort here as it makes no sense to try to equip an item that you are already wearing :-D
            --Clear the old values from drag start now
            FCOIS.dragAndDropVars.bag  = nil
            FCOIS.dragAndDropVars.slot = nil
        end
        if bag == nil or slot == nil then return end
        --Is item bindable and equipable?
        --ZOS provides the item bind dialog for all items themselves now! But FCOIS.CheckBindableItems will respect this and
        --only return true/show the dialog of FCOIS if it's enabled in the settings and the ZOs functions somehow returned
        --false
        local doShowItemBindDialog = false
        if isCharacterShown() or isCompanionCharacterShown() then
            local equipSucceeds, _ = IsEquipable(bag, slot)
            --Check if we need to show the "Ask before bind" dialog as the item get's dropped at an equipment slot
            checkBindableItems = checkBindableItems or FCOIS.CheckBindableItems
            if equipSucceeds and checkBindableItems(bag, slot, nil, true) then
                doShowItemBindDialog = true
            end
        end

        --Clear the old values from drag start now
        FCOIS.dragAndDropVars.bag  = nil
        FCOIS.dragAndDropVars.slot = nil
        -- check if destroying, improvement, sending or trading is forbidden
        -- and check if item is bindable (above)
        -- if so, clear item hold by cursor
        if doShowItemBindDialog then
            --Remove the picked item from drag&drop cursor
            ClearCursor()
        end
        return false
        --elseif slotType == SLOT_TYPE_MAIL_QUEUED_ATTACHMENT or slotType == SLOT_TYPE_MAIL_ATTACHMENT or slotType == SLOT_TYPE_MY_TRADE then
    elseif isMailOrTradeSlotType == true then
        local bagId     = GetCursorBagId()
        local slotIndex = GetCursorSlotIndex()
        if not bagId or not slotIndex then return false end
        --CraftBag item was dragged and dropped?
        if bagId == BAG_VIRTUAL then
            --Check if the item is protected
            --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
            callItemSelectionHandler = callItemSelectionHandler or FCOIS.callItemSelectionHandler
            local isProtected = callItemSelectionHandler(bagId, slotIndex, true, true, false, false, false, false, false, nil)
            if isProtected == true then
                --Remove the picked item from drag&drop cursor
                ClearCursor()
                return true
            end
        end
    end

    --#233 Fix for PreHook of AGS -> return true here instead
    if otherAddons.AGSActive ~= nil and cursorContentType == MOUSE_CONTENT_EMOTE
            and ctrlVars.GUILD_STORE_SCENE:IsShowing() and ctrlVars.BANK_FRAGMENT:IsShowing() then
        --d("<[FCOIS]return true - DragReceive")
        return true
    end
end


--==============================================================================
--      Hook Methods (update inventory rows and add doubleclick event, scene hook callbacks, etc.
--==============================================================================

--Callback function for scenes to hide the context menu of inventory buttons
function FCOIS.SceneCallbackHideContextMenu(oldState, newState, overrideFilterPanel)
    --d("[FCOIS.sceneCallbackHideContextMenu")
    --When e.g. the mail inbox panel is showing up
    if newState == SCENE_SHOWING or SCENE_FRAGMENT_SHOWING then
        if overrideFilterPanel == nil then
            overrideFilterPanel = FCOIS.gFilterWhere
        end
        --Hide the context menu at last active panel
        hideContextMenu = hideContextMenu or FCOIS.HideContextMenu
        hideContextMenu(overrideFilterPanel)
    end
end
local sceneCallbackHideContextMenu = FCOIS.SceneCallbackHideContextMenu


--============================================================================================================================================================
--===== HOOKS BEGIN ==========================================================================================================================================
--============================================================================================================================================================
local function specialContextMenuKeysCheckAndActions()
    local settings                         = FCOIS.settingsVars.settings
    local contextMenuClearMarkesByShiftKey = settings.contextMenuClearMarkesByShiftKey
    local contextMenuClearMarkesKey        = settings.contextMenuClearMarkesModifierKey
    if contextMenuClearMarkesByShiftKey == true and lcm and lcm.EnableSpecialKeyContextMenu then lcm:EnableSpecialKeyContextMenu(contextMenuClearMarkesKey) end
    return contextMenuClearMarkesByShiftKey
end

--Create the hooks & pre-hooks -> Only can be called once then it will be NIL! to prevent double hooks
function FCOIS.CreateHooks()
    local settings                           = FCOIS.settingsVars.settings
    local locVars                            = FCOIS.localizationVars.fcois_loc
    local mappingVars                        = FCOIS.mappingVars

    local preHookMainMenuFilterButtonHandler = FCOIS.PreHookMainMenuFilterButtonHandler
    --Check if thesame mainMenuBarButton get's pressed twice or if a button was changed
    local function mainMenuBarButtonFilterButtonHandler(mouseButon, isUpInside, lastButtonVar, buttonControlClicked, comingFrom, goingTo, delay)
        if (mouseButon == MOUSE_BUTTON_INDEX_LEFT and isUpInside and FCOIS.lastVars[lastButtonVar] ~= buttonControlClicked) then
            FCOIS.lastVars[lastButtonVar] = buttonControlClicked
            if comingFrom == nil or goingTo == nil or comingFrom == goingTo then return end
            zo_callLater(function() preHookMainMenuFilterButtonHandler(comingFrom, goingTo) end, delay or 50)
        end
    end

    local checkFCOISFilterButtonsAtPanel                     = FCOIS.CheckFCOISFilterButtonsAtPanel

    --Show/Update the filter buttons at the research list again
    local function showOrUpdateResearchFilterButtons()
        local researchFiterTypeToUpdate = LF_SMITHING_RESEARCH
        if GetCraftingInteractionType() == CRAFTING_TYPE_JEWELRYCRAFTING then
            researchFiterTypeToUpdate = LF_JEWELRY_RESEARCH
        end
        checkFCOISFilterButtonsAtPanel(true, researchFiterTypeToUpdate)
    end


    --local updateFCOISFilterButtonsAtInventory                = FCOIS.UpdateFCOISFilterButtonsAtInventory
    --local updateFCOISFilterButtonColorsAndTextures           = FCOIS.UpdateFCOISFilterButtonColorsAndTextures
    hideContextMenu = hideContextMenu or FCOIS.HideContextMenu
    local changeContextMenuInvokerButtonColorByPanelId       = FCOIS.ChangeContextMenuInvokerButtonColorByPanelId
    local reParentAndAnchorContextMenuInvokerButtons         = FCOIS.ReParentAndAnchorContextMenuInvokerButtons
    local resetContextMenuInvokerButtonColorToDefaultPanelId = FCOIS.ResetContextMenuInvokerButtonColorToDefaultPanelId
    local autoReenableAntiSettingsCheck                      = FCOIS.AutoReenableAntiSettingsCheck
    checkIfClearOrRestoreAllMarkers = checkIfClearOrRestoreAllMarkers or FCOIS.CheckIfClearOrRestoreAllMarkers

    local isResearchListDialogShown                          = FCOIS.IsResearchListDialogShown
    local refreshPopupDialogButtons                          = FCOIS.RefreshPopupDialogButtons
    local refreshEquipmentControl                            = FCOIS.RefreshEquipmentControl

    local checkCraftbagOrOtherActivePanel                    = FCOIS.CheckCraftbagOrOtherActivePanel
    local updateFilteredItemCountThrottled                   = FCOIS.UpdateFilteredItemCountThrottled
    local onClosePanel                                       = FCOIS.OnClosePanel
    local invContextMenuAddSlotAction                        = FCOIS.InvContextMenuAddSlotAction
    local checkIfEnchantingInventoryItemShouldBeReMarked_AfterEnchanting = FCOIS.CheckIfEnchantingInventoryItemShouldBeReMarked_AfterEnchanting

    local prepareReApplyRemovedFenceOrLaunderMarkerIcons     = FCOIS.PrepareReApplyRemovedFenceOrLaunderMarkerIcons
    local reApplyRemovedFenceOrLaunderMarkerIcons            = FCOIS.ReApplyRemovedFenceOrLaunderMarkerIcons


    --Set the global filter panel ID to LF_INVENTORY again (otherwise it would stay the same like before, e.g. craftbag, and block the drag&drop!)
    local function resetToInventoryAndHideContextMenu()
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY)
        --Hide the context menus
        zo_callLater(function()
            hideContextMenu(LF_INVENTORY)
        end, 50)
    end

    --========= INVENTORY SLOT - SHOW CONTEXT MENU =================================
    local function ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver(rowControl, slotActions, ctrl, alt, shift, command)
        shift                                             = shift or IsShiftKeyDown()
        alt                                               = alt or IsAltKeyDown()
        ctrl                                              = ctrl or IsControlKeyDown()
        local prevVars                                    = FCOIS.preventerVars
        --d("ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver - shift: " ..tos(shift) .. ", dontShowInvContextMenu: " ..tos(prevVars.dontShowInvContextMenu))
        FCOIS.preventerVars.buildingInvContextMenuEntries = false
        --As this prehook is called before the character OnMouseUp function is called:
        --If the SHIFT+right mouse button option is enabled and the SHIFT key is pressed and the character is shown.
        --Then hide the context menu
        local contextMenuClearMarkesKey                   = settings.contextMenuClearMarkesModifierKey
        local contextMenuClearMarkesByShiftKey            = specialContextMenuKeysCheckAndActions()
        --d("HHHHHHHHHHHHH[FCOIS]ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver - contextMenuClearMarkesByShiftKey: " ..tos(contextMenuClearMarkesByShiftKey) .. ", preventCOntextMenu: " .. tos(prevVars.dontShowInvContextMenu) .. ", modifierPressed: " .. tos(isModifierKeyPressed(contextMenuClearMarkesKey)) ..", noOtherModifierpressed: " ..tos(isNoOtherModifierKeyPressed(contextMenuClearMarkesKey)))
        --#194: bugfix
        --local isCharacterShownNow = isCharacterShown()
        --local isCompanionCharacterShownNow = isCompanionCharacterShown()

        --d("[FCOIS]ZO_InventorySlot_ShowContextMenu - filterPanel: " .. tos(FCOIS.gFilterWhere))
        --Clear the sub context menu entries
        FCOIS.customMenuVars.customMenuSubEntries         = {}
        FCOIS.customMenuVars.customMenuDynSubEntries      = {}
        FCOIS.customMenuVars.customMenuCurrentCounter     = 0

        --if the context menu should not be shown, because all marker icons were removed
        -- hide it now
        if prevVars.dontShowInvContextMenu == false and contextMenuClearMarkesByShiftKey == true
                and (isModifierKeyPressed(contextMenuClearMarkesKey) and isNoOtherModifierKeyPressed(contextMenuClearMarkesKey))
        --#194: Checking for the character here will show the dynamic icons submenu context menu (customMenuDynSubEntries) as standalone, if enabled!
        --and (isCharacterShownNow or isCompanionCharacterShownNow)
        then
            --d(">FCOIS context menu, modifier key is down -> Preventing contextMenu now")
            FCOIS.preventerVars.dontShowInvContextMenu = true
            prevVars = FCOIS.preventerVars
        end
        if prevVars.dontShowInvContextMenu == true then
            --d(">FCOIS context menu, hiding it!")
            --Hide the context menu now by returning true in this preHook and not calling the "context menu show" function
            --Nil the current menu ZO_Menu so it does not show (anti-flickering)
            ClearMenu()
            --2024-11-11 LibScrollableMenu is enabled and it is used to replace ZO_Menu? Clear LSM entries now too so it does not show any empty LSM context menu
            -->!!!Only happens if Tamriel Trade Center is nabled too!!! So must be an issue how TTC hooks into the inventory context menu?
            -->Because FCOIS.ShouldInventoryContextMenuBeHiddden() returns false as  FCOIS.preventerVars.dontShowInvContextMenu below was reset to false already!
            -->So we need to delay the reset a bit
            zo_callLater(function()
                --d("[FCOIS]resetting preventerVars.dontShowInvContextMenu to false")
                FCOIS.preventerVars.dontShowInvContextMenu = false
            end, 0) --Call at next frame so next ShowMenu() of TTC etc. do not get the preventer variable reset?
            return true
        end

        --Call a little bit later so the context menu is already created
        --zo_callLater(function()
        --Reset the IIfA clicked variables
        FCOIS.IIfAclicked             = nil

        local parentControl           = rowControl:GetParent()

        local FCOcontextMenu          = {}

        --Check if the user set ordering is valid, else use the default sorting
        -->With FCOIS 2.0.3 it should be always valid due to the usage of the LibAddonMenu-2.0 OrderListBox, and no dropdown boxes anymore!
        local userOrderValid          = true --FCOIS.checkIfUserContextMenuSortOrderValid()
        local resetSortOrderDone      = false

        local contextMenuEntriesAdded = 0
        --Check each iconId and build a sorted context menu then
        local useSubContextMenu       = settings.useSubContextMenu
        FCOIS.preventerVars.gCalledFromInternalFCOIS = true
        local _, countDynIconsEnabled = FCOIS.CountMarkerIconsEnabled()
        local useDynSubContextMenu    = (settings.useDynSubMenuMaxCount > 0 and countDynIconsEnabled >= settings.useDynSubMenuMaxCount) or false
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
                        resetSortOrderDone = FCOIS.ResetUserContextMenuSortOrder()
                    end
                    --Use the default sort order as the other one is not valid!
                    newOrderId = FCOIS.settingsVars.defaults.icon[iconId].sortOrder
                end
                if newOrderId > 0 and newOrderId <= numFilterIcons then
                    --Initialize the context menu entry at the new index
                    FCOcontextMenu[newOrderId] = nil
                    FCOcontextMenu[newOrderId] = {}
                    --Is the current control an equipment control?
                    local isEquipControl       = (parentControl == characterCtrl or parentControl == companionCharacterCtrl)
                    if (isEquipControl) then
                        FCOcontextMenu[newOrderId].control = rowControl
                    else
                        FCOcontextMenu[newOrderId].control = parentControl
                    end
                    FCOcontextMenu[newOrderId].iconId       = iconId
                    FCOcontextMenu[newOrderId].refreshPopup = false
                    FCOcontextMenu[newOrderId].isEquip      = isEquipControl
                    FCOcontextMenu[newOrderId].useSubMenu   = useSubContextMenu
                    --Increase the counter for added context menu entries
                    contextMenuEntriesAdded                 = contextMenuEntriesAdded + 1
                end -- if newOrderId > 0 and newOrderId <= numFilterIcons then
            end -- if settings.isIconEnabled[iconId] then
        end -- for

        --Are there any context menu entries?
        if contextMenuEntriesAdded > 0 then
            local addedCounter                                = 0
            FCOIS.preventerVars.buildingInvContextMenuEntries = true
            --Check if the localization data of the context menu is given
            checkAndUpdateContextMenuLocalizationData()
            addMark = addMark or FCOIS.AddMark
            for j = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                local FCOcontextMenuEntry = FCOcontextMenu[j]
                if FCOcontextMenuEntry ~= nil then
                    addedCounter = addedCounter + 1
                    --Is the currently added entry with AddMark the "last one in this context menu"?
                    --> Needed to set the preventer variable buildingInvContextMenuEntries for the function AddMark so the IIfA addon is recognized properly!
                    --d(">addedCounter: " ..tos(addedCounter) .. "-contextMenuEntriesAdded: " ..tos(contextMenuEntriesAdded))
                    if addedCounter >= contextMenuEntriesAdded then
                        --Last entry in custom context menu reached -> Used in FCOIS.AddMark for lastAdd variable
                        FCOIS.preventerVars.buildingInvContextMenuEntries = false
                    end
                    --FCOIS.AddMark(rowControl, markId, isEquipmentSlot, refreshPopupDialog, useSubMenu)
                    --Increase the global counter for the added context menu entries so the function FCOIS.AddMark can react on it
                    FCOIS.customMenuVars.customMenuCurrentCounter = FCOIS.customMenuVars.customMenuCurrentCounter + 1
                    addMark(FCOcontextMenuEntry.control, FCOcontextMenuEntry.iconId, FCOcontextMenuEntry.isEquip, FCOcontextMenuEntry.refreshPopup, FCOcontextMenuEntry.useSubMenu, addedCounter >= contextMenuEntriesAdded)
                end
            end

            --As the (dynamic) sub menu entries were build, show them now
            if useSubContextMenu or useDynSubContextMenu then
                --#280 Test:
                --Was called delayed to let the table FCOIS.customMenuVars.customMenuSubEntries be build and finished within function FCOIS.AddMark
                --but it should be finished properly before this code runs? Remove the zo_callLater
                --zo_callLater(function()
                local customMenuSubEntries = FCOIS.customMenuVars.customMenuSubEntries
                if customMenuSubEntries ~= nil and #customMenuSubEntries > 0 then
                    AddCustomSubMenuItem("|c22DD22FCO|r ItemSaver", customMenuSubEntries)
                else
                    local customMenuDynSubEntries = FCOIS.customMenuVars.customMenuDynSubEntries
                    if customMenuDynSubEntries ~= nil and #customMenuDynSubEntries > 0 then
                        local dynamicSubMenuEntryHeaderText = locVars["options_icons_dynamic"]
                        if settings.addContextMenuLeadingMarkerIcon then
                            dynamicSubMenuEntryHeaderText = "  " .. dynamicSubMenuEntryHeaderText
                        end
                        AddCustomSubMenuItem(dynamicSubMenuEntryHeaderText, customMenuDynSubEntries)
                    end
                end
                --Do not remove or dynamic submenu in contextmenus will not be shown!
                --#280 Keep this ShowMenu enabled here, or the submenu entry with the submenu entries will not show!
                ShowMenu(rowControl)
                --end, 30)
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
        d(FCOIS.preChatVars.preChatTextRed .. strformat(libMissingErrorText, "LibCustomMenu"))
    end


    --========= ZO_DIALOG1 / DESTROY DIALOG ========================================
    --Destroy item dialog button 2 ("Abort") hook
    ZO_PreHook(ctrlVars.DestroyItemDialog.buttons[2], "callback", function()
        --Get the "YES" button of the destroy dialog
        local dialog1 = ctrlVars.ZODialog1
        local button1 = dialog1:GetNamedChild("Button1")
        if button1 == nil then return false end
        --Reset the "YES" button of the dialog again after a few seconds
        zo_callLater(function()
            if dialog1 ~= nil and button1 ~= nil then
                dialog1:SetKeyboardEnabled(false)
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
    --ZOS provides the item bind dialog for all items themselves now! But FCOIS.CheckBindableItems will respect this and
    --only return true/show the dialog of FCOIS if it's enabled in the settings and the ZOs functions somehow returned
    --false
    ZO_PreHook("EquipItem", function(bagId, slotIndex, equipSlotIndex)
        --If we got here the DoEquip function in file ingame/inventory/inventoryslot.lua was called already and the ZOs anti-equip dialog was already shown, or
        --not shown because function "ZO_InventorySlot_WillItemBecomeBoundOnEquip(bag, index)" did not return true.
        --So check if the item is still unbound and bindable and show an "Ask before equip" dialog if it's enabled in the settings
        if bagId ~= nil and slotIndex ~= nil then
            if settings.debug then debugMessage("[EquipItem]", "bagId: " .. bagId .. ", slotIndex: " .. slotIndex .. ", equipSlotIndex: " .. tos(equipSlotIndex), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --d("[EquipItem] bagId: " .. bagId .. ", slotIndex: " .. slotIndex .. ", equipSlotIndex: " ..tos(equipSlotIndex))
            --Check if the item is bound on equip and show dialog to acceppt the binding before (if enabled in the settings)
            checkBindableItems = checkBindableItems or FCOIS.CheckBindableItems
            return checkBindableItems(bagId, slotIndex, equipSlotIndex)
        end
    end)

    SecurePostHook("RequestEquipItem", function(bagId, slotIndex, bagWorn, equipSlot)
        --No equipslot given? Determine it via the itemType
        if equipSlot == nil and bagId ~= nil and slotIndex ~= nil then
            local equipType = giet(bagId, slotIndex)
            equipSlot       = mappingVars.equipTypeToSlot[equipType]
        end
        --d("[FCOIS]RequestEquipItem-bagId: " ..tos(bagId) .. ", slotIndex: " ..tos(slotIndex) .. ", bagWorn: " ..tos(bagWorn) .. ", equipSlotIndex: " .. tos(equipSlot) .. " " .. gil(bagId, slotIndex))
        if settings.debug then debugMessage("[RequestEquipItem]", "bagId: " .. tos(bagId) .. ", slotIndex: " .. tos(slotIndex) .. ", bagWorn: " .. tos(bagWorn) .. ", equipSlotIndex: " .. tos(equipSlot), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Update the marker control of the new equipped item
        updateEquipmentSlotMarker = updateEquipmentSlotMarker or FCOIS.UpdateEquipmentSlotMarker
        updateEquipmentSlotMarker(equipSlot, 300, false)
        --Refresh the inventory, if shown, to update the marker icons at the unequipped item's inventory row
        filterBasics = filterBasics or FCOIS.FilterBasics
        filterBasics(true)
    end)

    --========= UNEQUIP ITEM =======================================================
    --ZO_PreHook("UnequipItem", function(equipSlot)
    SecurePostHook("RequestUnequipItem", function(bagId, equipSlot)
        if bagId ~= nil and equipSlot ~= nil then
            if settings.debug then debugMessage("[RequestUnequipItem]", "bagId: " .. tos(bagId) .. ", equipSlotIndex: " .. equipSlot, true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --d("[FCOIS]RequestUnEquipItem-bagId: " ..tos(bagId) .. ", equipSlotIndex: " .. tos(equipSlot) .. " " .. gil(bagId, equipSlot))
            --If item was unequipped: Remove the armor type marker if necessary
            removeArmorTypeMarker = removeArmorTypeMarker or FCOIS.RemoveArmorTypeMarker
            removeArmorTypeMarker(bagId, equipSlot) -->BAG_WORN will be updated to BAG_COMPANION_WORN internally!
            --Update the marker control of the new equipped item
            updateEquipmentSlotMarker = updateEquipmentSlotMarker or FCOIS.UpdateEquipmentSlotMarker
            updateEquipmentSlotMarker(equipSlot, 300, true)
            --Refresh the inventory, if shown, to update the marker icons at the unequipped item's inventory row
            filterBasics = filterBasics or FCOIS.FilterBasics
            filterBasics(true)
        end
    end)
    --========= MENU BARS ==========================================================
    --Preehook the menu bar shown event to update the character equipment section if it is shown
    ZO_PreHookHandler(ctrlVars.mainMenuCategoryBar, "OnShow", function()
        if settings.debug then debugMessage("[Main Menu Category Bar]", "OnShow") end
        --d("[Main Menu Category Bar]OnShow")
        --Hide the context menu
        hideContextMenu(FCOIS.gFilterWhere)

        --Update the character's equipment markers, if the character screen is shown
        if isCharacterShown() then
            --d(">RefreshEquipmentControl -> ALL")
            refreshEquipmentControl(nil, nil, nil, nil, nil, nil)
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
        --If mail send panel was opened the call order will be:
        --fcois_hooks -> 1. 1552 resetInventoryAntiSettings , 2. 1566 changeContextMenuInvokerButtonColorByPanelId, 3. 912 ctrlVars.mainMenuCategoryBar:OnShow autoReenableAntiSettingsCheck
        --As the button for the invenory, mail, player2player trade is physically the same it willupdate the button's color wrong according to anti-destroy instead of
        --anti-mail settings then! So the call to autoReenableAntiSettingsCheck cannot be done here anymore, except if autoReenableAntiSettingsCheck
        --would check if any panel (FCOIS.gFilterWhere) is shown which got the same "flag" button name as the LF_INVENTORY does
        autoReenableAntiSettingsCheck("DESTROY")
    end)

    --========= REFINEMENT =========================================================
    --Pre Hook the refinement for prevention methods
    --PreHook the receiver function of drag&drop at the refinement panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.SMITHING, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        return isCraftBagItemDraggedToCraftingSlot(LF_SMITHING_REFINE, bagId, slotIndex)
    end)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the refine inventory list
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.REFINEMENT, ctrlVars.REFINEMENT.dataTypes[1]) then --#303
        SecurePostHook(ctrlVars.REFINEMENT.dataTypes[1], "setupCallback", onScrollListRowSetupCallback)
        addInventorySecurePostHookDoneEntry(ctrlVars.REFINEMENT, ctrlVars.REFINEMENT.dataTypes[1])
    end


    --========= DECONSTRUCTION =====================================================
    --Pre Hook the deconstruction for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the deconstruction inventory list
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.DECONSTRUCTION, ctrlVars.DECONSTRUCTION.dataTypes[1]) then --#303
        SecurePostHook(ctrlVars.DECONSTRUCTION.dataTypes[1], "setupCallback", onScrollListRowSetupCallback)
        addInventorySecurePostHookDoneEntry(ctrlVars.DECONSTRUCTION, ctrlVars.DECONSTRUCTION.dataTypes[1])
    end


    --======== UNIVERSAL DECONSTRUCTION =================================================
    -- -v- #202
    getCurrentFilterPanelIdAtDeconNPC = getCurrentFilterPanelIdAtDeconNPC or FCOIS.GetCurrentFilterPanelIdAtDeconNPC
    --[[
    --Old before LibFilters-3.0 v339 - No panel callbacks for "shown" and "hidden" used
        local universalDeconstructionPanel = universalDeconGlobal.deconstructionPanel
        local detectActiveUniversalDeconstructionTab = libFilters.DetectUniversalDeconstructionPanelActiveTab
    ]]

    --Pre Hook the universal deconstruction for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the universal deconstruction inventory list
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK, ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK.dataTypes[1]) then --#303
        SecurePostHook(ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK.dataTypes[1], "setupCallback", onScrollListRowSetupCallback)
        addInventorySecurePostHookDoneEntry(ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK, ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK.dataTypes[1])
    end


    --Hide and reAnchor the last shown filterPanel filter buttons at the UniversalDeconstruction UI -> As the smithing/jewelry/enchanting filetrButtons
    --get re-used here we need to hide them properly again and re-anchor them to their original filterPanel ctrls/UIs
    local function reAnchorAndHideLastUniversalDeconPanelFilterAndAddFlagButtons(lastFilterPanelIdAtUniversalDecon)
        if lastFilterPanelIdAtUniversalDecon == nil then lastFilterPanelIdAtUniversalDecon = FCOIS.gFilterWhere end
        --d(">[FCOIS]reAnchorAndHideLastUniversalDeconFilterPanelButtons - lastFilterPanelIdAtUniversalDecon: " ..tos(lastFilterPanelIdAtUniversalDecon) .. ", current: " ..tos(universalDeconGlobal.FCOIScurrentFilterPanelId))
        --Reset the filterButtons and the additional inventory flag button to their default parents at e.g.
        --LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACTION
        reParentAndAnchorContextMenuInvokerButtons(lastFilterPanelIdAtUniversalDecon, nil)
    end

    --Add StateChange callback to UNIVERSAL_DECONSTRUCTION_KEYBOARD_SCENE (ctrlVars.UNIVERSAL_DECONSTRUCTON_SCENE) and
    --at SHOWN detect the current panel and set FCOIS.gFilterWhere + add buttons + add flag icon (reanchor LF_SMITHING_DECONSTRUCT [buttons ALL, ARMOR, WEAPON]
    --and LF_JEWELRY_DECONSTRUCT [buttons JEWELRY] and LF_ENCHANTING_EXTRACT [buttons ENCHANTING], and at HIDING reanchor them to their normal parents
    -- and set FCOIS.gFilterWhere to LF_INVENTORY again)
    local function updateFilterAndAddInvFlagButtonsAtUniversalDeconstruction(isHidden, LibFiltersFilterTypeAtUniversalDecon)
        isHidden = isHidden or false

        if not isHidden then
            local lastUniversalDeconFilterPanelId = universalDeconGlobal.FCOIScurrentFilterPanelId
            --LF_SMITHING_DECONSTRUCT needs to be passed in as valid filterPanel! It maybe not the correct filterPanel, so it is determined internally
            local filterPanelIdPassedIn
            if LibFiltersFilterTypeAtUniversalDecon ~= nil then
                filterPanelIdPassedIn = LibFiltersFilterTypeAtUniversalDecon
            else
                filterPanelIdPassedIn = universalDeconGlobal.FCOIScurrentFilterPanelId
            end
            --d("[FCOIS]UniversalDecon - Setting filterPanelId to: " ..tos(filterPanelIdPassedIn))
            if filterPanelIdPassedIn == nil then filterPanelIdPassedIn = LF_SMITHING_DECONSTRUCT end
            --Update universalDeconGlobal.FCOIScurrentFilterPanelId
            local currentFilterPanelIdAtUniversalDecon = getCurrentFilterPanelIdAtDeconNPC(filterPanelIdPassedIn)
            --d(">Setting filterPanelId to: " ..tos(currentFilterPanelIdAtUniversalDecon))
            if currentFilterPanelIdAtUniversalDecon ~= nil then
                --if FCOIS.gFilterWhere ~= currentFilterPanelIdAtUniversalDecon then --#267
                if lastUniversalDeconFilterPanelId ~= nil and lastUniversalDeconFilterPanelId ~= currentFilterPanelIdAtUniversalDecon then
                    reAnchorAndHideLastUniversalDeconPanelFilterAndAddFlagButtons(lastUniversalDeconFilterPanelId)
                end

                FCOIS.gFilterWhere = getFilterWhereBySettings(currentFilterPanelIdAtUniversalDecon) --#266

                --Re-anchor the filterButtons and the additional inventory flag button from their default parents at e.g.
                --LF_SMITHING_DECONSTRUCT, LF_JEWELRY_DECONSTRUCT and LF_ENCHANTING_EXTRACTION to
                --their new parent control UNIVERSAL_DECONSTRUCTION.control ...
                -->Re-Parent and Re-Anchor he filterButtons and the additional inventory "flag" button from old panel to current panel
                reParentAndAnchorContextMenuInvokerButtons(nil, currentFilterPanelIdAtUniversalDecon)
                --Change the button color of the context menu invoker
                changeContextMenuInvokerButtonColorByPanelId(currentFilterPanelIdAtUniversalDecon)
                --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
                -->Will reParent and reAnchor the filterButtons too!
                --doUpdateLists, panelId, overwriteFilterWhere, hideFilterButtons, isUniversalDeconNPC
                checkFCOISFilterButtonsAtPanel(true, currentFilterPanelIdAtUniversalDecon, nil, nil, true, lastUniversalDeconFilterPanelId) --#202 universal deconstruction
                --else --#267
                --d(">Same filterPanel at last and current UniversalDecon!")

                --end --#267
            end
        else
            --d("[FCOIS]UniversalDecon panel HIDDEN")
            reAnchorAndHideLastUniversalDeconPanelFilterAndAddFlagButtons(universalDeconGlobal.FCOIScurrentFilterPanelId)
        end
    end

    ctrlVars.UNIVERSAL_DECONSTRUCTON_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        --d("[FCOIS] UniversalDeconstruction Scene state change to: " ..tos(newState))
        --Hide the context menu at the active panel
        sceneCallbackHideContextMenu(oldState, newState)

        --Normal scene shown/hidden callbacks to show/hide (& reanchor) the additional inventory flag buttons and the filterButtonss
        if newState == SCENE_HIDING then
            --Hide the context menu at universal decon panel
            local filterTypeToHide = universalDeconGlobal.FCOIScurrentFilterPanelId
            if filterTypeToHide == nil then filterTypeToHide = LF_SMITHING_DECONSTRUCT end
            hideContextMenu(filterTypeToHide)
        elseif newState == SCENE_HIDDEN then
            --d("[FCOIS]UniversalDecon scene hidden - resetting universalDeconGlobal.FCOIScurrentFilterPanelId to nil")
            universalDeconGlobal.FCOIScurrentFilterPanelId = nil

            --Hide context menus and update inventory filterButtons + re-enable the ANTI deconstruction/ANTI enchanting protection if needed
            onClosePanel(nil, LF_INVENTORY, "CRAFTING_STATION")
            --Reset the filterPanelId to inventory
            FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY)
        end
    end)

    -- -^- #202


    --New with LibFilters-3.0 v339 panel callbacks:
    --======== UNIVERSAL DECONSTRUCTION ===========================================================
    --Check if UniversalDeconstruction is shown
    local libFilters_getUniversalDeconstructionPanelActiveTabFilterType = libFilters.GetUniversalDeconstructionPanelActiveTabFilterType
    local function FCOItemSaver_CheckIfUniversalDeconIsShownAndAddButtons(stateStr, universalDeconSelectedTabNow)
        --d("[FCOItemSaver_CheckIfUniversalDeconIsShownAndAddButton]stateStr: " ..tos(stateStr) .. ", tab: " ..tos(universalDeconSelectedTabNow))
        libFilters_getUniversalDeconstructionPanelActiveTabFilterType = libFilters_getUniversalDeconstructionPanelActiveTabFilterType or libFilters.GetUniversalDeconstructionPanelActiveTabFilterType
        local currentUniversalDeconFilterType, universalDeconCurrentTab = libFilters_getUniversalDeconstructionPanelActiveTabFilterType(nil)
        local isUniversalDecon = (currentUniversalDeconFilterType ~= nil and universalDeconCurrentTab ~= nil and universalDeconCurrentTab == universalDeconSelectedTabNow and true) or false
        --d(">isUnivDecon: " ..tos(isUniversalDecon) .. ", currentFilterType: " ..tos(currentUniversalDeconFilterType) .. ", currentTab: " ..tos(universalDeconCurrentTab))
        if isUniversalDecon == true then
            --Was the panel shown or hidden?
            local isShown = (stateStr == SCENE_SHOWN and true) or false
            --If hidden: Hide context menus and filter buttons, unregister filters
            if isShown == false then
                local filterTypeToHide = universalDeconGlobal.FCOIScurrentFilterPanelId
                --d("[FCOIS]universalDeconstructionPanel HIDDEN - " ..tos(universalDeconCurrentTab) .. ", LibFiltersFilterType: " ..tos(currentUniversalDeconFilterType) .. ", filterTypeLastTab: " ..tos(filterTypeToHide))
                hideContextMenu(filterTypeToHide)
                --Hide buttons and set the actual panel to LF_INVENTORY
                updateFilterAndAddInvFlagButtonsAtUniversalDeconstruction(true, nil)
            else
                --d("[FCOIS]universalDeconstructionPanel SHOWN - " ..tos(universalDeconCurrentTab) .. ", LibFiltersFilterType: " ..tos(currentUniversalDeconFilterType))
                --If shown: Show filter buttons and register filters, and update FCOIS.gFilterWhere (only if the tab change also changed the LF* FilterType)
                -->The last tab's filterType, before the chane, will be added to universalDeconGlobal.FCOIScurrentFilterPanelId
                updateFilterAndAddInvFlagButtonsAtUniversalDeconstruction(false, currentUniversalDeconFilterType)
            end

        end
    end

    --[[
        callbackName,
        filterType,
        stateStr,
        isInGamepadMode,
        fragmentOrSceneOrControl,
        lReferencesToFilterType,
        universalDeconSelectedTabNow
    ]]
    local function libFiltersUniversalDeconShownOrHiddenCallback(isShown, callbackName, filterType, stateStr, isInGamepadMode, fragmentOrSceneOrControl, lReferencesToFilterType, universalDeconSelectedTabNow)
        --d("[FCOIS]UNIVERSAL_DECONSTRUCTION - CALLBACK - " ..tos(callbackName) .. ", state: "..tos(stateStr) .. ", filterType: " ..tos(filterType) ..", isInGamepadMode: " ..tos(isInGamepadMode) .. ", universalDeconSelectedTabNow: " ..tos(universalDeconSelectedTabNow))
        FCOItemSaver_CheckIfUniversalDeconIsShownAndAddButtons(stateStr, universalDeconSelectedTabNow)
    end
    local callbackNameUniversalDeconDeconAllShown = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, true, nil, "all")
    local callbackNameUniversalDeconDeconAllHidden = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, false, nil, "all")
    CM:RegisterCallback(callbackNameUniversalDeconDeconAllShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconDeconAllHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconDeconArmorShown = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, true, nil, "armor")
    local callbackNameUniversalDeconDeconArmorHidden = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, false, nil, "armor")
    CM:RegisterCallback(callbackNameUniversalDeconDeconArmorShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconDeconArmorHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconDeconWeaponsShown = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, true, nil, "weapons")
    local callbackNameUniversalDeconDeconWeaponsHidden = libFilters:RegisterCallbackName(addonName, LF_SMITHING_DECONSTRUCT, false, nil, "weapons")
    CM:RegisterCallback(callbackNameUniversalDeconDeconWeaponsShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconDeconWeaponsHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconJewelryDeconShown = libFilters:RegisterCallbackName(addonName, LF_JEWELRY_DECONSTRUCT, true, nil, "jewelry")
    local callbackNameUniversalDeconJewelryDeconHidden = libFilters:RegisterCallbackName(addonName, LF_JEWELRY_DECONSTRUCT, false, nil, "jewelry")
    CM:RegisterCallback(callbackNameUniversalDeconJewelryDeconShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconJewelryDeconHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)
    local callbackNameUniversalDeconEnchantingShown = libFilters:RegisterCallbackName(addonName, LF_ENCHANTING_EXTRACTION, true, nil, "enchantments")
    local callbackNameUniversalDeconEnchantingHidden = libFilters:RegisterCallbackName(addonName, LF_ENCHANTING_EXTRACTION, false, nil, "enchantments")
    CM:RegisterCallback(callbackNameUniversalDeconEnchantingShown, function(...) libFiltersUniversalDeconShownOrHiddenCallback(true, ...) end)
    CM:RegisterCallback(callbackNameUniversalDeconEnchantingHidden, function(...) libFiltersUniversalDeconShownOrHiddenCallback(false, ...) end)


    --========= IMPROVEMENT ========================================================
    --Pre Hook the improvement for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the improvement inventory list
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.IMPROVEMENT, ctrlVars.IMPROVEMENT.dataTypes[1]) then --#303
        SecurePostHook(ctrlVars.IMPROVEMENT.dataTypes[1], "setupCallback", onScrollListRowSetupCallback)
        addInventorySecurePostHookDoneEntry(ctrlVars.IMPROVEMENT, ctrlVars.IMPROVEMENT.dataTypes[1])
    end

    --========= ENCHANTING =========================================================
    --Pre Hook the enchanting table for prevention methods
    --PreHook the receiver function of drag&drop at the enchanting panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.ENCHANTING, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        --Rune creation & extraction!
        return isCraftBagItemDraggedToCraftingSlot(LF_ENCHANTING_CREATION, bagId, slotIndex)
    end)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the enchanting inventory list
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.ENCHANTING_STATION, ctrlVars.ENCHANTING_STATION.dataTypes[1]) then --#303
        SecurePostHook(ctrlVars.ENCHANTING_STATION.dataTypes[1], "setupCallback", onScrollListRowSetupCallback)
        addInventorySecurePostHookDoneEntry(ctrlVars.ENCHANTING_STATION, ctrlVars.ENCHANTING_STATION.dataTypes[1])
    end
    --PreHook the enchant function to re-apply marker icons on the same enchanted item
    -->Before enchanting dialog will be called
    ZO_PreHook(ctrlVars.ENCHANTING_APPLY_ENCHANT, "BeginItemImprovement", function(self, bagId, slotIndex)
        FCOIS.CheckIfEnchantingItemShouldBeReMarked_BeforeEnchanting(bagId, slotIndex)
    end)
    SecurePostHook("EnchantItem", function(bagId, slotIndex, selectedDataBag, selectedDataIndex)
        FCOIS.preventerVars.enchantItemActive = false
        if not FCOIS.settingsVars.settings.reApplyIconsAfterEnchanting then return end
        local enchantingVarsLastMarkerIcons = FCOIS.enchantingVars.lastMarkerIcons[bagId] and FCOIS.enchantingVars.lastMarkerIcons[bagId][slotIndex]
        if enchantingVarsLastMarkerIcons == nil then return end
        FCOIS.preventerVars.enchantItemActive = true
    end)
    local enchantPopupDialogCustomControl = ESO_Dialogs["ENCHANTING"].customControl()
    if enchantPopupDialogCustomControl ~= nil then
        ZO_PostHookHandler(enchantPopupDialogCustomControl, "OnHide", function()
            checkIfEnchantingInventoryItemShouldBeReMarked_AfterEnchanting()
        end)
    end

    --========= RETRAIT =========================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the retrait inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.RETRAIT_LIST, ctrlVars.RETRAIT_LIST.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.RETRAIT_LIST.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(ctrlVars.RETRAIT_LIST, ctrlVars.RETRAIT_LIST.dataTypes[1], true)
    end
    ]]


    --========= RESEARCH LIST - POPUP / ListDialog OnShow/OnHide ======================================================
    local researchPopupDialogCustomControl = ESO_Dialogs["SMITHING_RESEARCH_SELECT"].customControl()
    if researchPopupDialogCustomControl ~= nil then
        ZO_PreHookHandler(researchPopupDialogCustomControl, "OnShow", function()
            --d("[FCOIS]SMITHING_RESEARCH_SELECT PreHook:OnShow")
            --As this OnShow function will be also called for other ZO_ListDialog1 dialogs...
            --Check if we are at the research popup dialog
            if not isResearchListDialogShown() then return false end
            FCOIS.preventerVars.ZO_ListDialog1ResearchIsOpen = true
            --Check the filter buttons and create them if they are not there.
            checkFCOISFilterButtonsAtPanel(true, LF_SMITHING_RESEARCH_DIALOG)
        end)
        ZO_PreHookHandler(researchPopupDialogCustomControl, "OnHide", function()
            --d("[FCOIS]SMITHING_RESEARCH_SELECT PreHook:OnHide")
            --Check if we are at the research popup dialog
            if not FCOIS.preventerVars.ZO_ListDialog1ResearchIsOpen then return false end
            FCOIS.preventerVars.ZO_ListDialog1ResearchIsOpen = false
            --Hide the filter buttons at LF_SMITHING_RESEARCH_DIALOG (or LF_JEWELRY_RESEARCH_DIALOG, which will be
            --determined dynamically within function FCOIS.CheckActivePanel in function FCOIS.CheckFilterButtonsAtPanel)
            checkFCOISFilterButtonsAtPanel(false, LF_SMITHING_RESEARCH_DIALOG, nil, true) -- Last parameter: Hide filter buttons
            --Show/Update the filter buttons at the research list again
            showOrUpdateResearchFilterButtons()
        end)
    end
    --========= RESEARCH LIST / ListDialog (also repair, enchant, charge, etc.) - ZO_Dialog1 ======================================================
    --Original setupCallback function
    local hookedResearchListFunctions = ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback

    --function for the research list preHook
    local function smithingResearchListDialogSetupCallback(rowControl, slot)
        --Call the original row's setupCallback function
        hookedResearchListFunctions(rowControl, slot)
        --d("[".. os.date("%c", GetTimeStamp()) .."]>enabling the control's row again")
        --Reset the row so it is enabled
        rowControl.disableControl = false
        --[[
        createMarkerControl = createMarkerControl or FCOIS.CreateMarkerControl

        local iconVars            = FCOIS.iconVars
        local textureVars         = FCOIS.textureVars

        -- Create/Update all the icons for the current dialog row
        for iconNumb = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            local iconData = settings.icon[iconNumb]
            createMarkerControl(rowControl, iconNumb, iconData.size or iconVars.gIconWidth, iconData.size or iconVars.gIconWidth, textureVars.MARKER_TEXTURES[iconData.texture])
        end -- for i = 1, numFilterIcons, 1 do
        ]]
        --addMarkerIconsToControl(rowControl, pDoCreateMarkerControl, pIsEquipmentSlot, pUpdateAllEquipmentTooltips, pArmorTypeIcon, pHideControl, pUnequipped)
        addMarkerIconsToControl = addMarkerIconsToControl or FCOIS.AddMarkerIconsToControl
        addMarkerIconsToControl(rowControl, false, false, nil, nil, nil, nil)

        --Get the row's bag and slotIndex
        local bagId, slotIndex = myGetItemDetails(rowControl)
        --Check if rowControl is a soulgem
        local isSoulGemNow     = false
        if bagId and slotIndex then
            isSoulGemNow = isSoulGem(bagId, slotIndex)
        end
        local myItemInstanceIdOfControl = myGetItemInstanceId(rowControl)

        --Current dialog is the repair item dialog?
        local isRepairDialog            = isRepairDialogShown()
        local isEnchantDialog           = isEnchantDialogShown()
        local disableControl            = false

        -- Check the rowControl if the item is marked and update the OnMouseUp functions and the color of the item row then
        for iconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            local iconIsProtected = checkIfItemIsProtected(iconId, myItemInstanceIdOfControl)

            --Special research icon handling
            if iconId == FCOIS_CON_ICON_RESEARCH then
                if (not isSoulGemNow and iconIsProtected) then

                    --Not inside the repair dialog and settings allow research of "marked for research" items?
                    if (not isRepairDialog and not isEnchantDialog) and not settings.allowResearch then
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
                if (not isSoulGemNow and iconIsProtected) then
                    if (isRepairDialog and settings.blockMarkedRepairKits) then
                        disableControl = true
                        break -- leave for ... do loop of iconIds
                    elseif (isEnchantDialog and settings.blockMarkedGlyphs) then
                        disableControl = true
                        break -- leave for ... do loop of iconIds
                    elseif not isRepairDialog and not isEnchantDialog then
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
            if settings.debug then debugMessage("[Research dialog control-OnMouseUp]", "Clicked: " .. control:GetName() .. ", MouseButton: " .. tos(button), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --button 1= left mouse button / 2= right mouse button
            --d("[FCOIS Hooks-ResearchDialog:OnMouseUp handler]Clicked: " ..control:GetName() .. ", MouseButton: " .. tos(button) .. ", Shift: " ..tos(shiftKey))

            --Right click/mouse button 2 context menu hook part:
            if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
                local contextMenuClearMarkesKey = FCOIS.settingsVars.settings.contextMenuClearMarkesModifierKey
                local isModifierKeyPressedNow   = isModifierKeyPressed(contextMenuClearMarkesKey)
                --d(">isModifierKeyPressed: " ..tos(isModifierKeyPressedNow) .. ", noOthermodifierKeyPressed: " ..tos(isNoOtherModifierKeyPressed(contextMenuClearMarkesKey)))
                --Was the shift key clicked?
                if isModifierKeyPressedNow == true and isNoOtherModifierKeyPressed(contextMenuClearMarkesKey) then
                    FCOIS.preventerVars.isZoDialogContextMenu = true
                    --Right click/mouse button 2 context menu together with shift key: Clear/Restore all marker icons on the item?
                    --If the setting to remove/readd marker icons via shift+right mouse button is enabled:
                    checkIfClearOrRestoreAllMarkers(rowControl, isModifierKeyPressedNow, upInside, button, true, false)
                    --If the context menu should not be shown, because all marker icons were removed
                    -- hide it now
                    if FCOIS.ShouldInventoryContextMenuBeHiddden() then
                        FCOIS.preventerVars.isZoDialogContextMenu  = false
                        FCOIS.preventerVars.dontShowInvContextMenu = false
                        --Hide the context menu now by returning true in this preHook and not calling the "context menu show" function
                        return true
                    end
                end

                FCOIS.preventerVars.buildingInvContextMenuEntries = true

                --Build the context menu for the research dialog now. Will be shown via function FCOIS.MarkMe then
                local FCOcontextMenu          = {}
                --Check if the user set ordeirng is valid, else use the standard sorting
                -->With FCOIS 2.0.3 it should be always valid due to the usage of the LibAddonMenu-2.0 OrderListBox, and no dropdown boxes anymore!
                local userOrderValid          = true --FCOIS.CheckIfUserContextMenuSortOrderValid()
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
                            FCOcontextMenu[newOrderId]              = nil
                            FCOcontextMenu[newOrderId]              = {}
                            FCOcontextMenu[newOrderId].control      = rowControl
                            FCOcontextMenu[newOrderId].iconId       = iconId
                            FCOcontextMenu[newOrderId].refreshPopup = true -- Refresh the ZO_ListDialog1 popup entries now
                            FCOcontextMenu[newOrderId].isEquip      = false
                            FCOcontextMenu[newOrderId].useSubMenu   = false
                            --Increase the counter for added context menu entries
                            contextMenuEntriesAdded                 = contextMenuEntriesAdded + 1
                        end -- if newOrderId > 0 and newOrderId <= numFilterIcons then
                    end -- if settings.isIconEnabled[iconId] then
                end -- for

                --Are there any context menu entries?
                if contextMenuEntriesAdded > 0 then
                    local addedCounter = 0
                    --Reset the counter for the FCOIS.AddMark function
                    FCOIS.customMenuVars.customMenuCurrentCounter = 0
                    --Clear the menu completely (should be empty by default as it does not exist on the dialogs)
                    ClearMenu()
                    --Add the context menu entries now
                    addMark = addMark or FCOIS.AddMark
                    for j = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                        if FCOcontextMenu[j] ~= nil then
                            addedCounter = addedCounter + 1
                            --Is the currently added entry with AddMark the "last one in this context menu"?
                            --> Needed to set the preventer variable buildingInvContextMenuEntries for the function AddMark so the IIfA addon is recognized properly!
                            if addedCounter >= contextMenuEntriesAdded then
                                --Last entry in custom context menu reached -> Used in FCOIS.AddMark for lastAdd variable
                                FCOIS.preventerVars.buildingInvContextMenuEntries = false
                            end
                            --FCOIS.AddMark(rowControl, markId, isEquipmentSlot, refreshPopupDialog, useSubMenu)
                            --Increase the global counter for the added context menu entries so the function FCOIS.AddMark can react on it
                            FCOIS.customMenuVars.customMenuCurrentCounter = FCOIS.customMenuVars.customMenuCurrentCounter + 1
                            addMark(FCOcontextMenu[j].control, FCOcontextMenu[j].iconId, FCOcontextMenu[j].isEquip, FCOcontextMenu[j].refreshPopup, FCOcontextMenu[j].useSubMenu, addedCounter >= contextMenuEntriesAdded)
                        end
                    end
                end

            end -- Mouse button checks

            --Mouse button was released on the row?
            if upInside then
                --d("[FCOIS]upInside: " ..tos(upInside) .. ", disable: " ..tos(rowControl.disableControl) .. ", isSoulGem: " ..tos(isSoulGem))
                --Check if the clicked row got marker icons which protect this item!
                refreshPopupDialogButtons(rowControl, false)
                local dialog = ctrlVars.RepairItemDialog
                --Should this row be protected and disabled buttons and keybindings
                if rowControl.disableControl == true and not isSoulGemNow == true then
                    --d("MouseUpInside, rowControl.disableControl-> true")
                    --Do nothing (true tells the handler function that everything was achieved already in this function
                    --and the normal "hooked" functions don't need to be run afterwards)
                    -- -> All handling will be done in file src/FCOIS_ContextMenus.lua, function MarkMe() as the dialog list will be refreshed!
                    changeDialogButtonState(dialog, 1, false)
                    FCOIS.preventerVars.isZoDialogContextMenu = false
                    return true
                else
                    -- if disableControl == false
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
                            changeDialogButtonState(dialog, 1, enableResearchButton)
                        end
                    end, 20)
                end -- if disableControl == true
            end
            FCOIS.preventerVars.isZoDialogContextMenu = false
        end) -- ZO_PreHookHandler(rowControl, "OnMouseUp"...
    end-- ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback -> list dialog 1 pre-hook (e.g. research, repair item, enchant, charge, etc.)

    --Pre-Hook the list dialog's rows
    ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback = smithingResearchListDialogSetupCallback

    --======== INVENTORY ===========================================================
    --Pre Hook the inventory for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the backpack inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(backpackCtrl, backpackCtrl.dataTypes[1], true) then --#303
        SecurePostHook(backpackCtrl.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(backpackCtrl, backpackCtrl.dataTypes[1], true)
    end
    ]]
    --PreHook the primary action keybind in inventories
    ZO_PreHook("ZO_InventorySlot_DoPrimaryAction", FCOItemSaver_OnInventorySlot_DoPrimaryAction)


    --=============================================================================
    --#202 bugfix for undaunted vendor -> press I to open inventory -> error message because FCOIS.gFilterWhere was 6
    --LF_VENDOR_SELL still -> Error message at /src/FCOIS_Filters.lua -> function shouldItemBeShownAfterBeenFiltered row
    --116: if filterButtonSettingsForCurrentPanel == nil then
    local invSceneWasShown = false
    local invScene = SCENE_MANAGER:GetScene(invSceneName)
    invScene:RegisterCallback("StateChange", function(oldState, newState)
        if newState == SCENE_SHOWING or newState == SCENE_SHOWN then
            --d(">Scene invenory state change: " ..tos(newState))
            FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY)

            --Added with FCOIS v2.4.9 ReAnchor the inventory additionalInventoryFlag button now so changed data is reflected after reloadui
            --on first open of the inventory, without having to open the settings menu first!
            if newState == SCENE_SHOWN and invSceneWasShown == false then
                --d(">>calling ReAnchorAdditionalInvButtons(LF_INVENTORY)")
                invSceneWasShown = true

                FCOIS.ReAnchorAdditionalInvButtons(LF_INVENTORY)
            end
        end
    end)

    --======== CRAFTBAG ===========================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the craftbag inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.CRAFTBAG_LIST, ctrlVars.CRAFTBAG_LIST.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.CRAFTBAG_LIST.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(ctrlVars.CRAFTBAG_LIST, ctrlVars.CRAFTBAG_LIST.dataTypes[1], true)
    end
    ]]

    --ONLY if the craftbag is active
    --Pre Hook the 2 menubar button's (items and crafting bag) handler at the inventory
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_ITEMS, "OnMouseUp", function(control, button, upInside)
        --d("inv button 1, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastInvButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastInvButton", ctrlVars.INV_MENUBAR_BUTTON_ITEMS, LF_CRAFTBAG, LF_INVENTORY, nil)
    end)
    --[[
    --API 100029 Dragonhold - Insecure call of ZO_StackSplitSource_DragStart if this PreHookHandler is used
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_CRAFTBAG, "OnMouseUp", function(control, button, upInside)
        --d("inv button 2, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastInvButton:GetName())
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
        if settings.debug then debugMessage("[LOOT_SCENE]", "State: " .. tos(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        if newState == SCENE_HIDING then
            --If the inventory was shown at last and the loot panel was opened (by using a container e.g.) the
            --anti-destroy settings have to be reenabled if the loot scene closes again
            FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory = true
            --d("Don't auto reenable anti-settings in invntory!")
        end
    end)

    --======== CHARACTER ===========================================================
    --Pre Hook the character window for prevention methods
    ZO_PostHookHandler(characterCtrl, "OnEffectivelyShown", FCOItemSaver_CharacterOnEffectivelyShown)

    --======== COMPANION CHARACTER ===========================================================
    --Pre Hook the companion character window for prevention methods
    ZO_PostHookHandler(companionCharacterCtrl, "OnEffectivelyShown", FCOItemSaver_CharacterOnEffectivelyShown)

    --======== RIGHT CLICK / CONTEXT MENU ==========================================
    --Pre Hook the right click/context menu addition of items
    ZO_PreHook(ZO_InventorySlotActions, "AddSlotAction", invContextMenuAddSlotAction)

    --Override ZO_InventorySlotActions:AddSlotAction with own function FCOIS.OverrideUseAddSlotAction,
    --which will call the original function, but wil do some checks before (e.g. if it is a container
    --and contains transmutation crystals etc.)
    override(ZO_InventorySlotActions, "AddSlotAction", overrideUseAddSlotAction)

    --======== CURRENCIES (in inventory) ===========================================
    --Pre Hook the 3rd menubar button (Currencies) handler at the player inventory
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_CURRENCIES, "OnMouseUp", function(control, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
            resetToInventoryAndHideContextMenu()
        end
    end)

    --======== QUICK SLOTS =========================================================
    --Pre Hook the quickslots for prevention methods
    --Register a secure posthook on visibility change of a scrolllist's row -> At the backpack inventory list
    --dataTypes[1] = normal inventory items
    --dataTypes[2] = quest items
    --dataTypes[3] = collectibles
    --SecurePostHook(ctrlVars.QUICKSLOT_LIST.dataTypes[1], "setupCallback", onScrollListRowSetupCallback)
    onDeferredInitCheck(ctrlVars.QUICKSLOT_KEYBOARD, function()
        --Create the marker icons for quickslots
        if ctrlVars.QUICKSLOT_KEYBOARD.OnDeferredInitialize ~= nil then
            FCOIS.CreateTextures(4) --quickslots
            --Update the number of filtered items count variables
            FCOIS.numberOfFilteredItems[LF_QUICKSLOT] = ctrlVars.QUICKSLOT_LIST.data
        end

        --Hook the quickslots list rows setupFunction
        -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
        --[[
        if not checkIfInventorySecurePostHookWasDone(ctrlVars.QUICKSLOT_LIST, ctrlVars.QUICKSLOT_LIST.dataTypes[1], true) then --#303
            SecurePostHook(ctrlVars.QUICKSLOT_LIST.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
            addInventorySecurePostHookDoneEntry(ctrlVars.QUICKSLOT_LIST, ctrlVars.QUICKSLOT_LIST.dataTypes[1], true)
        end
        ]]
    end, nil)

    --Pre Hook the 5th menubar button (Quickslots) handler at the player inventory
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_QUICKSLOTS, "OnMouseUp", function(control, button, upInside)
        if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
            --todo FEATURE: add inventory filter buttons for quickslot filtering?
            resetToInventoryAndHideContextMenu()
        end
    end)

    --======== FENCE & LAUNDER =====================================================
    --Pre Hook the fence and launder "enter" and "fence closed" functions
    --[[ --#299
    ZO_PreHook(FENCE_MANAGER, "OnEnterSell", function(...)
        FCOIS.FenceLaunderMode = 1
        zo_callLater(function() preHookMainMenuFilterButtonHandler(LF_FENCE_LAUNDER, LF_FENCE_SELL) end, 50)
    end)
    ZO_PreHook(FENCE_MANAGER, "OnEnterLaunder", function(...)
        FCOIS.FenceLaunderMode = 2
        zo_callLater(function() preHookMainMenuFilterButtonHandler(LF_FENCE_SELL, LF_FENCE_LAUNDER) end, 50)
    end)
    ZO_PreHook(FENCE_MANAGER, "OnFenceClosed", function(...)
        FCOIS.FenceLaunderMode = nil
        if settings.debug then debugMessage("[FENCE_MANAGER]", "OnFenceClosed", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Avoid the filter panel ID change if the fence_manager is called from a normal vendor, which closes the store:
        --If you directly open the mail panel at the vendor the current panel ID will be reset to LF_INVENTORY and this would be not true!
        if FCOIS.preventerVars.gNoCloseEvent == false then
            resetContextMenuInvokerButtonColorToDefaultPanelId()
        end
    end)
    ]]
    -- #299 -v-
    local fenceManager = ctrlVars.FENCE_MANAGER
    fenceManager:RegisterCallback("FenceEnterSell", function(...)
--d("[FCOIS]FenceEnterSell")
        FCOIS.FenceLaunderMode = LF_FENCE_SELL
        --Prepare for any items got the marker icons removed at fence
        prepareReApplyRemovedFenceOrLaunderMarkerIcons(FCOIS.FenceLaunderMode)

        zo_callLater(function() preHookMainMenuFilterButtonHandler(LF_FENCE_LAUNDER, LF_FENCE_SELL) end, 50)
    end)
    fenceManager:RegisterCallback("FenceEnterLaunder", function(...)
--d("[FCOIS]FenceEnterLaunder")
        FCOIS.FenceLaunderMode = LF_FENCE_LAUNDER
        --Prepare for any items got the marker icons removed at launder
        prepareReApplyRemovedFenceOrLaunderMarkerIcons(FCOIS.FenceLaunderMode)

        zo_callLater(function() preHookMainMenuFilterButtonHandler(LF_FENCE_SELL, LF_FENCE_LAUNDER) end, 50)
    end)
    fenceManager:RegisterCallback("FenceClosed", function(...)
--d("[FCOIS]FenceClosed")
        FCOIS.FenceLaunderMode = nil
        if settings.debug then debugMessage("[FENCE_MANAGER]", "OnFenceClosed", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Check if any items got the marker icons removed and reapply them, if needed
        reApplyRemovedFenceOrLaunderMarkerIcons()

        --Avoid the filter panel ID change if the fence_manager is called from a normal vendor, which closes the store:
        --If you directly open the mail panel at the vendor the current panel ID will be reset to LF_INVENTORY and this would be not true!
        if FCOIS.preventerVars.gNoCloseEvent == false then
            resetContextMenuInvokerButtonColorToDefaultPanelId()
        end
    end)
    -- #299 -^-




    --======== VENDOR =====================================================
    --Pre Hook the menubar button's (buy, sell, buyback, repair) handler at the vendor
    --> Will be done in event callback function for EVENT_OPEN_STORE + a delay as the buttons are not created before!
    ---> See file src/FCOIS_events.lua, function 'FCOItemSaver_OpenStore("vendor")'
    --Register a secure posthook on visibility change of a scrolllist's row -> At the vendor inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.REPAIR_LIST, ctrlVars.REPAIR_LIST.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.REPAIR_LIST.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(ctrlVars.REPAIR_LIST, ctrlVars.REPAIR_LIST.dataTypes[1], true)
    end
    ]]

    --======== BANK ================================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the bank inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.BANK, ctrlVars.BANK.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.BANK.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(ctrlVars.BANK, ctrlVars.BANK.dataTypes[1], true)
    end
    ]]

    --Pre Hook the 2 menubar button's (take and deposit) handler at the bank
    ZO_PreHookHandler(ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW, "OnMouseUp", function(control, button, upInside)
        --d("bank button 1, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastBankButton", ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW, LF_BANK_DEPOSIT, LF_BANK_WITHDRAW, nil)
    end)
    ZO_PreHookHandler(ctrlVars.BANK_MENUBAR_BUTTON_DEPOSIT, "OnMouseUp", function(control, button, upInside)
        --d("bank button 2, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastBankButton", ctrlVars.BANK_MENUBAR_BUTTON_DEPOSIT, LF_BANK_WITHDRAW, LF_BANK_DEPOSIT, nil)
    end)

    --Bank fragment - May be added to other scenes where it was not added to by vanilla UI, e.g. AwesomeGuildStore adds the fragment to the guild store sell scene
    ctrlVars.BANK_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then debugMessage("[BANK_FRAGMENT]", "State: " .. tos(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --If the trading house scene is currently shown and AwesomeGuildStore is active:
        --AGS's "sell directly from bank" is activated
        if otherAddons.AGSActive == true and ctrlVars.GUILD_STORE_SCENE:IsShowing() then
            if newState == SCENE_FRAGMENT_SHOWING then
                --d("[FCOIS]Guild trader sell scene is shown - Bank fragment showing")
                local filterPanelId = LF_BANK_WITHDRAW
                FCOIS.preventerVars.gActiveFilterPanel = true
                --Reset the anti-destroy settings if needed (e.g. bank was opened directly after inventory was closed, without calling other panels in between)
                onClosePanel(LF_GUILDSTORE_SELL, filterPanelId, "DESTROY")
                --Reset the last clicked bank button as it will always be the withdraw tab if you open the bank, and if the
                --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
                FCOIS.lastVars.gLastBankButton = ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW
                FCOIS.gFilterWhere = getFilterWhereBySettings(filterPanelId)
                --[[
                --Scan if player bank got items that should be marked automatically
                if not checkIfAutomaticMarksAreDisabledAtBag(bagId) then
                    zo_callLater(function()
                        scanInventory(bagId, nil, settings.autoMarkBagsChatOutput)
                    end, 250)
                end
                ]]
                --Change the button color of the context menu invoker
                --changeContextMenuInvokerButtonColorByPanelId(filterPanelId) --> Called by "onClosePanel" above already
                --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
                checkFCOISFilterButtonsAtPanel(true, filterPanelId)

            elseif newState == SCENE_FRAGMENT_HIDING then
                --d("[FCOIS]Guild trader sell scene is shown - Bank fragment hiding")
                local toPanelId = LF_GUILDSTORE_SELL
                FCOIS.gFilterWhere = getFilterWhereBySettings(toPanelId)
                --d(">FCOIS.gFilterWhere: " .. tos(FCOIS.gFilterWhere))
                onClosePanel(LF_BANK_WITHDRAW, toPanelId, "DESTROY")
                --d(">FCOIS.gFilterWhere2: " .. tos(FCOIS.gFilterWhere))
            end
        end
    end)


    --======== HOUSE BANK ================================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the house bank inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.HOUSE_BANK, ctrlVars.HOUSE_BANK.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.HOUSE_BANK.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(ctrlVars.HOUSE_BANK, ctrlVars.HOUSE_BANK.dataTypes[1], true)
    end
    ]]

    --Pre Hook the 2 menubar button's (take and deposit) handler at the bank
    ZO_PreHookHandler(ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW, "OnMouseUp", function(control, button, upInside)
        --d("house bank button 1, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastHouseBankButton", ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW, LF_HOUSE_BANK_DEPOSIT, LF_HOUSE_BANK_WITHDRAW, nil)
    end)
    ZO_PreHookHandler(ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_DEPOSIT, "OnMouseUp", function(control, button, upInside)
        --d("house bank button 2, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastBankButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastHouseBankButton", ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_DEPOSIT, LF_HOUSE_BANK_WITHDRAW, LF_HOUSE_BANK_DEPOSIT, nil)
    end)

    --======== GUILD BANK ==========================================================
    --Register a secure posthook on visibility change of a scrolllist's row -> At the guld bank inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.GUILD_BANK, ctrlVars.GUILD_BANK.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.BANK.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(ctrlVars.GUILD_BANK, ctrlVars.GUILD_BANK.dataTypes[1], true)
    end
    ]]

    --Pre Hook the 2 menubar button's (take and deposit) handler at the guild bank
    ZO_PreHookHandler(ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW, "OnMouseUp", function(control, button, upInside)
        --d("guild bank button 1, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastGuildBankButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastGuildBankButton", ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW, LF_GUILDBANK_DEPOSIT, LF_GUILDBANK_WITHDRAW, nil)
    end)
    ZO_PreHookHandler(ctrlVars.GUILD_BANK_MENUBAR_BUTTON_DEPOSIT, "OnMouseUp", function(control, button, upInside)
        --d("guild bank button 2, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastGuildBankButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastGuildBankButton", ctrlVars.GUILD_BANK_MENUBAR_BUTTON_DEPOSIT, LF_GUILDBANK_WITHDRAW, LF_GUILDBANK_DEPOSIT, nil)
    end)
    --======== SMITHING =============================================================
    local function smithingSetModeHook(smithingCtrl, mode, ...)
        --Hide the context menu at last active panel
        hideContextMenu(FCOIS.gFilterWhere)

        if settings.debug then debugMessage("[SMITHING:SetMode]", "Mode: " .. tos(mode), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        local craftingType                               = GetCraftingInteractionType()
        --d("[FCOIS]smithingSetModeHook-mode: " ..tos(mode) .. ", craftingType: " ..tos(craftingType) .. ", currentFilterPanel: " ..tos(FCOIS.gFilterWhere))
        if not mode then return end

        --Get the filter panel ID by crafting type (to distinguish jewelry crafting and normal)
        local craftingModeAndCraftingTypeToFilterPanelId = mappingVars.craftingModeAndCraftingTypeToFilterPanelId
        local filterPanelId
        local showFCOISFilterButtons                     = false
        --zo_callLater(function()
        --Refinement
        if mode == SMITHING_MODE_REFINMENT then
            filterPanelId          = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_REFINE
            showFCOISFilterButtons = true
            --Creation -- Not supported
            --elseif mode == SMITHING_MODE_CREATION then
            --filterPanelId          = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_CREATION
            --showFCOISFilterButtons = true
            --Deconstruction
        elseif mode == SMITHING_MODE_DECONSTRUCTION then
            filterPanelId          = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_DECONSTRUCT
            showFCOISFilterButtons = true
            --Improvement
        elseif mode == SMITHING_MODE_IMPROVEMENT then
            filterPanelId          = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_IMPROVEMENT
            showFCOISFilterButtons = true
            --Research
        elseif mode == SMITHING_MODE_RESEARCH then
            filterPanelId          = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_RESEARCH
            showFCOISFilterButtons = true

            --Show/Update the filter buttons at the research list again
            --showOrUpdateResearchFilterButtons()
        end
        --d(">>filterPanelId: " ..tos(filterPanelId))

        if showFCOISFilterButtons == true and FCOIS.gFilterWhere ~= nil and filterPanelId ~= nil then
            --apply to the crafting panel at re-open of the panel/at first open of the refinement panel
            --delay of a few ms (or 0 to skip call to next frame) to let the filters get registered properly
            zo_callLater(function()
                --d(">preHookMainMenuFilterButtonHandler, comingFrom: " ..tos(FCOIS.gFilterWhere) .. ", goingTo: " ..tos(filterPanelId))
                preHookMainMenuFilterButtonHandler(FCOIS.gFilterWhere, filterPanelId)
            end, 0)
        end
    end
    --New with API100029 Dragonhold
    SecurePostHook(ctrlVars.SMITHING_CLASS, "SetMode", smithingSetModeHook)

    --======== ENCHANTING =============================================================
    local function enchantingPreHook()
        --Hide the context menu at last active panel
        hideContextMenu(FCOIS.gFilterWhere)
        --Call delayed with 0ms to call it on next frame in order to let the filterFunctions work properly in function
        --preHookMainMenuFilterButtonHandler -> registerFilter and refresh of inventory
        zo_callLater(function()
            local enchantingCtrl = ctrlVars.ENCHANTING
            if enchantingCtrl:IsSceneShowing() then
                --local enchantingMode = enchantingCtrl.enchantingMode
                local enchantingMode = enchantingCtrl:GetEnchantingMode()
                if settings.debug then debugMessage("[ENCHANTING:OnModeUpdated]", "EnchantingMode: " .. tos(enchantingMode), true, FCOIS_DEBUG_DEPTH_NORMAL) end

                --d("[FCOIS]Hook ZO_Enchanting.SetEnchantingMode/OnModeUpdated - Mode: " ..tos(enchantingMode))
                --Creation
                if enchantingMode == ENCHANTING_MODE_CREATION then
                    preHookMainMenuFilterButtonHandler(LF_ENCHANTING_EXTRACTION, LF_ENCHANTING_CREATION)
                    --Extraction
                elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
                    preHookMainMenuFilterButtonHandler(LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION)
                else
                    resetContextMenuInvokerButtonColorToDefaultPanelId()
                end
            end
        end, 0)
        --Go on with original function --> Only for PreHook!
        --return false
    end
    --Posthook the enchanting function SetEnchantingMode() which gets executed as the enchanting tabs are changed
    --ZO_Enchanting:SetEnchantingMode does not exist anymore (PTS -> Scalebreaker) and was replaced by ZO_Enchanting:OnModeUpdated()
    --SecurePostHook(ctrlVars.ENCHANTING, "OnModeUpdated", enchantingPreHook)
    SecurePostHook(ctrlVars.ENCHANTING_CLASS, "OnModeUpdated", enchantingPreHook)

    --======== ALCHEMY =============================================================
    --Prehook the alchemy function which gets executed as the alchemy tabs are changed
    ZO_PreHookHandler(ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION, "OnMouseUp", function(control, button, upInside)
        --d("Alchemy button 1, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastAlchemyButton:GetName())
        mainMenuBarButtonFilterButtonHandler(button, upInside, "gLastAlchemyButton", ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION, LF_ALCHEMY_CREATION, nil, nil)
    end)

    --PreHook the receiver function of drag&drop at the alchemy panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.ALCHEMY, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        --Alchemy creation
        return isCraftBagItemDraggedToCraftingSlot(LF_ALCHEMY_CREATION, bagId, slotIndex)
    end)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the alchemy solvent inventory list
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.ALCHEMY_STATION, ctrlVars.ALCHEMY_STATION.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.ALCHEMY_STATION.dataTypes[1], "setupCallback", onScrollListRowSetupCallback)
        addInventorySecurePostHookDoneEntry(ctrlVars.ALCHEMY_STATION, ctrlVars.ALCHEMY_STATION.dataTypes[1], true)
    end
    --Register a secure posthook on visibility change of a scrolllist's row -> At the alchemy reagent inventory list
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.ALCHEMY_STATION, ctrlVars.ALCHEMY_STATION.dataTypes[2], true) then --#303
        SecurePostHook(ctrlVars.ALCHEMY_STATION.dataTypes[2], "setupCallback", onScrollListRowSetupCallback)
        addInventorySecurePostHookDoneEntry(ctrlVars.ALCHEMY_STATION, ctrlVars.ALCHEMY_STATION.dataTypes[2], true)
    end



    --Another Prehook will be done at the event callback function for the crafting station interact, when the alchemy station
    --gets opened as the PotionMaker addon button will be created then
    local function alchemyPreHook(selfZO_Alchemy, mode)
        --d("[FCOIS]alchemyPreHook-mode: " ..tos(mode))
        --Hide the context menu at last active panel
        local activeFilterPanel = FCOIS.gFilterWhere
        hideContextMenu(activeFilterPanel)
        --Call delayed with 0ms to call it on next frame in order to let the filterFunctions work properly in function
        --preHookMainMenuFilterButtonHandler -> registerFilter and refresh of inventory
        --zo_callLater(function()
        --Creation
        if mode == ZO_ALCHEMY_MODE_CREATION then
            preHookMainMenuFilterButtonHandler(activeFilterPanel, LF_ALCHEMY_CREATION)
        else
            resetContextMenuInvokerButtonColorToDefaultPanelId()
        end
        --end, 0)
        --Go on with original function --> Only for PreHook!
        --return false
    end
    --Posthook the enchanting function SetEnchantingMode() which gets executed as the enchanting tabs are changed
    --ZO_Enchanting:SetEnchantingMode does not exist anymore (PTS -> Scalebreaker) and was replaced by ZO_Enchanting:OnModeUpdated()
    --SecurePostHook(ctrlVars.ENCHANTING, "OnModeUpdated", enchantingPreHook)
    SecurePostHook(ctrlVars.ALCHEMY_CLASS, "SetMode", alchemyPreHook)


    --======== CRAFTBAG FRAGMNET=========================================================
    --Register a callback function to the CraftBag fragment state, if the addon CraftBagextended is active
    --to be able to show filter buttons etc. at the mail craftbag and bank craftbag panel as well
    ctrlVars.CRAFT_BAG_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        --d("[FCOIS] CraftBag Fragment state change")
        --Hide the context menu at the active panel
        sceneCallbackHideContextMenu(oldState, newState)

        if newState == SCENE_FRAGMENT_SHOWING then
            --d("[FCOIS]CraftBag SCENE_FRAGMENT_SHOWING")
            FCOIS.preventerVars.craftBagSceneShowInProgress = true
            if settings.debug then debugMessage("[CRAFT_BAG_FRAGMENT]", "Showing", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Reset the parent panel ID
            FCOIS.gFilterWhereParent = nil

            --Check the filter buttons at the CraftBag panel and create them if they are not there. Return the parent filter panel ID if given (e.g. LF_MAIL)
            local _, parentPanel     = checkFCOISFilterButtonsAtPanel(true, LF_CRAFTBAG, LF_CRAFTBAG) --overwrite with LF_CRAFTBAG so it'll create and update the buttons for the craftbag panel, and not the CBE subpanels (mail, trade, bank, vendor, guild bank, etc.)
            --Update the inventory context menu ("flag" icon) so it uses the correct "anti-settings" and the correct colour and right-click callback function
            --depending on the currently shown craftbag "parent" (inventory, mail send, guild bank, guild store)
            if parentPanel == nil then
                _, parentPanel = FCOIS.CheckActivePanel(FCOIS.gFilterWhere, LF_CRAFTBAG)
            end

            if settings.debug then debugMessage("[CRAFT_BAG_FRAGMENT]", ">Parent panel: " .. tos(parentPanel), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

            --Update the current filter panel ID to "CraftBag"
            FCOIS.gFilterWhere   = getFilterWhereBySettings(LF_CRAFTBAG)

            --Are we showing a CBE subpanel of another parent panel?
            local cbeOrAGSActive = FCOIS.CheckIfCBEorAGSActive(FCOIS.gFilterWhereParent, true)
            if cbeOrAGSActive and parentPanel ~= nil then
                --The parent panel for the craftbag can be one of these
                local supportedPanels = FCOIS.otherAddons.craftBagExtendedSupportedFilterPanels
                if supportedPanels[parentPanel] then
                    --Set the global CBE parentPanel ID to e.g. mail send, vendor, guild bank, bank, trade, ...
                    FCOIS.gFilterWhereParent = parentPanel
                    if settings.debug then debugMessage("[CRAFT_BAG_FRAGMENT]", ">supported craftbag parent panel: " .. tos(FCOIS.gFilterWhereParent), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                end
            end
            --Change the additional context-menu button's color in the inventory (Craft Bag button)
            --d("<CraftBag: SCENE_FRAGMENT_SHOWING, before changeContextMenuInvokerButtonColorByPanelId(LF_CRAFTBAG)")
            changeContextMenuInvokerButtonColorByPanelId(LF_CRAFTBAG)

            --				elseif 	newState == SCENE_FRAGMENT_SHOWN then
            --	d("Callback fragment CRAFTBAG: Shown")

            --				elseif 	newState == SCENE_FRAGMENT_HIDING then
            --	d("Callback fragment CRAFTBAG: Hiding")
            FCOIS.preventerVars.craftBagSceneShowInProgress = false
            --------------------------------------------------------------------------------------------------------------------
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            --d("[FCOIS]CraftBag SCENE_FRAGMENT_HIDDEN")
            if settings.debug then debugMessage("[CRAFT_BAG_FRAGMENT]", "Hidden", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Reset the CraftBag filter parent panel ID
            FCOIS.gFilterWhereParent = nil
            --Hide the context menu at last active panel
            hideContextMenu(LF_CRAFTBAG)

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
            checkFCOISFilterButtonsAtPanel(true, nil)
            if settings.debug then debugMessage("[CRAFT_BAG_FRAGMENT]", ">new panel: " .. tos(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Change the additional context-menu button's color in the inventory (new active filter panel ID)
            --d("<CraftBag: SCENE_FRAGMENT_HIDDEN before changeContextMenuInvokerButtonColorByPanelId(" .. FCOIS.gFilterWhere .. ")")
            changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
            --end, 50)
        end
    end)
    --======== MAIL SEND ================================================================
    --Register a callback function for the mail send scene
    ctrlVars.MAIL_SEND_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then debugMessage("[MAIL_SEND_SCENE]", "State: " .. tos(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updated!
        --So do this here now:
        resetInventoryAntiSettings(newState)

        --When the mail send panel is showing up
        if newState == SCENE_SHOWING then
            --Check if craftbag is active and change filter panel and parent panel accordingly
            FCOIS.gFilterWhere, FCOIS.gFilterWhereParent = checkCraftbagOrOtherActivePanel(LF_MAIL_SEND)

            --Check if another filter panel was already opened and we are coming form there before the CLOSE EVENT function was called
            if FCOIS.preventerVars.gActiveFilterPanel == true then
                --Set the "No Close Event" flag so the called close event won't override gFilterWhere and update the filter button colors and callback handlers
                FCOIS.preventerVars.gNoCloseEvent = true
            end

            --Change the button color of the context menu invoker
            changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
            --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
            checkFCOISFilterButtonsAtPanel(true, FCOIS.gFilterWhere)

            --When the mail send panel is hiding
        elseif newState == SCENE_HIDING then
            --d("mail scene hiding")
            --Update the current filter panel ID to "Mail"
            FCOIS.gFilterWhere = getFilterWhereBySettings(LF_MAIL_SEND)

            --Hide the context menu at mail panel
            hideContextMenu(FCOIS.gFilterWhere)

            --When the mail send panel is hidden
        elseif newState == SCENE_HIDDEN then
            --d("mail scene hidden")

            onClosePanel(nil, LF_INVENTORY, "MAIL")
        end
    end)

    ZO_PreHook("SendMail", function()
        --#263 Check if atatched items and if those are protected (after reopening the mail send panel e.g.) and abort sending them
        if FCOIS.AreItemsProtectedAtMailSendPanel(nil, nil, true) then
            --d("[FCOIS]PROTECTED SendMail")
            return true
        end
        --d("[FCOIS]PreHook SendMail")
        return false
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
                    if settings.debug then debugMessage("[" .. tos(sceneName) .. "]", "State: " .. tos(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
                    sceneCallbackHideContextMenu(oldState, newState)
                    --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
                    --So do this here now:
                    resetInventoryAntiSettings(newState)
                end)
            end
        end
    end


    --======== RETRAIT ================================================================
    --Register a callback function for the retrait scene
    ctrlVars.RETRAIT_KEYBOARD_INTERACT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then debugMessage("[RETRAIT SCENE]", "State: " .. tos(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        sceneCallbackHideContextMenu(oldState, newState)
        if newState == SCENE_SHOWING then
            --Check if craftbag is active and change filter panel and parent panel accordingly
            FCOIS.gFilterWhere, FCOIS.gFilterWhereParent = checkCraftbagOrOtherActivePanel(LF_RETRAIT)

            --Check if another filter panel was already opened and we are coming form there before the CLOSE EVENT function was called
            --if FCOIS.preventerVars.gActiveFilterPanel == true then
            --Set the "No Close Event" flag so the called close event won't override gFilterWhere and update the filter button colors and callback handlers
            --    FCOIS.preventerVars.gNoCloseEvent = true
            --end

            --Change the button color of the context menu invoker
            changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
            --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
            checkFCOISFilterButtonsAtPanel(true, LF_RETRAIT)

        elseif newState == SCENE_HIDING then
            --Update the current filter panel ID to "Retrait"
            FCOIS.gFilterWhere = getFilterWhereBySettings(LF_RETRAIT)

            --Hide the context menu at the retrait panel
            hideContextMenu(FCOIS.gFilterWhere)

            --When the retrait panel is hidden
        elseif newState == SCENE_HIDDEN then
            onClosePanel(nil, LF_INVENTORY, "RETRAIT")
        end
    end)

    --======== COMPANION INVENTORY ================================================================
    --Register a callback function for the companion inventory fragment
    --Attention: This fragment will be showing AFTER the companion inventory rows get updated...
    --So the active filterPanelId will be updated to LF_INVENTORY_COMPANION as the companion inventory rows are updated
    -->See file src/FCOIS_MarkerIcons.lua, function FCOIS.CreateTextures with whichTextures = 6
    ctrlVars.COMPANION_INV_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then debugMessage("[COMPANION EQUIPMENT FRAGMENT]", "State: " .. tos(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --d("[COMPANION EQUIPMENT FRAGMENT]","State: " .. tos(newState))
        sceneCallbackHideContextMenu(oldState, newState)
        if newState == SCENE_FRAGMENT_SHOWING then
            --Check if craftbag is active and change filter panel and parent panel accordingly
            FCOIS.gFilterWhere, FCOIS.gFilterWhereParent = checkCraftbagOrOtherActivePanel(LF_INVENTORY_COMPANION)
            --d(">FCOIS.gFilterWhere: " ..tos(FCOIS.gFilterWhere))
            --Check if another filter panel was already opened and we are coming form there before the CLOSE EVENT function was called
            --if FCOIS.preventerVars.gActiveFilterPanel == true then
            --Set the "No Close Event" flag so the called close event won't override gFilterWhere and update the filter button colors and callback handlers
            --    FCOIS.preventerVars.gNoCloseEvent = true
            --end

            --Change the button color of the context menu invoker
            changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
            --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
            checkFCOISFilterButtonsAtPanel(true, LF_INVENTORY_COMPANION)

        elseif newState == SCENE_FRAGMENT_HIDING then
            --Update the current filter panel ID to "Companion inventory"
            FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY_COMPANION)

            --Hide the context menu at companion inventory panel
            hideContextMenu(FCOIS.gFilterWhere)

            --When the companion inventory panel is hidden
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            onClosePanel(nil, LF_INVENTORY, "DESTROY")
        end
    end)
    --Register a secure posthook on visibility change of a scrolllist's row -> At the companion inventory list
    -->#303 Was added via FCOIS.CreateTextures already so here we only need to add the onMouseUpHandlers!
    --[[
    if not checkIfInventorySecurePostHookWasDone(ctrlVars.COMPANION_INV_LIST, ctrlVars.COMPANION_INV_LIST.dataTypes[1], true) then --#303
        SecurePostHook(ctrlVars.COMPANION_INV_LIST.dataTypes[1], "setupCallback", function(rowControl, data) onScrollListRowSetupCallback(rowControl, data, true) end)
        addInventorySecurePostHookDoneEntry(ctrlVars.COMPANION_INV_LIST, ctrlVars.COMPANION_INV_LIST.dataTypes[1], true)
    end
    ]]

    --Register a fragment state change on the companion character window, to update it's equipment controls
    ctrlVars.COMPANION_CHARACTER_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then debugMessage("[COMPANION CHARACTER FRAGMENT]", "State: " .. tos(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --d("[COMPANION CHARACTER FRAGMENT]","State: " .. tos(newState))
        if newState == SCENE_FRAGMENT_SHOWING then
            changeContextMenuInvokerButtonColorByPanelId(FCOIS_CON_LF_COMPANION_CHARACTER)

            --Check if craftbag is active and change filter panel and parent panel accordingly
            --FCOIS.gFilterWhere, FCOIS.gFilterWhereParent = checkCraftbagOrOtherActivePanel(LF_INVENTORY_COMPANION)
        elseif newState == SCENE_FRAGMENT_SHOWN then
            --Update the character's equipment markers, if the companion character screen is shown
            --d(">RefreshEquipmentControl -> COMPANION")
            refreshEquipmentControl(nil, nil, nil, nil, nil, nil)

        elseif newState == SCENE_FRAGMENT_HIDING then
            --Update the current filter panel ID to "Companion inventory"
            --FCOIS.gFilterWhere = LF_INVENTORY_COMPANION

            --When the companion character panel is hidden
        elseif newState == SCENE_FRAGMENT_HIDDEN then
            --changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
            resetContextMenuInvokerButtonColorToDefaultPanelId()
        end
    end)

    --======== Extraction / Refinement / Deconstruction / Improvement functions =======================
    --PreHook the enchanting extract function to check if no marked item is currently in the extraction slot
    ZO_PreHook("ExtractEnchantingItem", function()
        return checkPreventCrafting()
    end)
    --PreHook the enchanting create function to check if no marked item is currently in the creation slot
    ZO_PreHook("CraftEnchantingItem", function()
        return checkPreventCrafting()
    end)
    --PreHook the crafting refine/extract function to check if no marked item is currently in the extraction slot
    ZO_PreHook("ExtractOrRefineSmithingItem", function()
        return checkPreventCrafting()
    end)
    --PreHook the crafting improvement function to check if no marked item is currently in the improvement slot
    ZO_PreHook(ctrlVars.SMITHING.improvementPanel, "Improve", function()
        return checkPreventCrafting()
    end)

    --======== Stack split dialog - Callback function for button 1 (Yes) ===============================
    --PreHook stack split dialog YES button function to set the preventer variable to disable the item protection/anti-checks
    ZO_PreHook("ZO_Dialogs_ShowDialog", function(dialogName, inventorySlotControl)
        --d("[FCOIS]ZO_Dialogs_ShowDialog, dialogName: " ..tos(dialogName) .. ", splitItemStackDialogButtonCallbacks: " .. tos(FCOIS.preventerVars.splitItemStackDialogButtonCallbacks))
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
        --d("[FCOIS]ZO_InventoryLandingArea_DropCursorInBag, splitItemStackDialogActive: " ..tos(FCOIS.preventerVars.splitItemStackDialogActive))
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
    --ZO_PreHook(ctrlVars.playerInventory, "ChangeFilter", function() d("[FCOIS]Player_Inventory ChangeFilter") updateFilteredItemCountThrottled(filterPanelId, delay) end)
    --Smithing
    local smithingCtrl = ctrlVars.SMITHING
    ZO_PreHook(smithingCtrl.refinementPanel.inventory, "ChangeFilter", function() updateFilteredItemCountThrottled(nil, 50, "Smithing refine - ChangeFilter") end)
    ZO_PreHook(smithingCtrl.deconstructionPanel.inventory, "ChangeFilter", function() updateFilteredItemCountThrottled(nil, 50, "Smithing decon - ChangeFilter") end)
    ZO_PreHook(smithingCtrl.improvementPanel.inventory, "ChangeFilter", function() updateFilteredItemCountThrottled(nil, 50, "Smithing improve - ChangeFilter") end)
    --Retrait
    ZO_PreHook(ctrlVars.RETRAIT_RETRAIT_PANEL.inventory, "ChangeFilter", function() updateFilteredItemCountThrottled(nil, 50, "Retrait - ChangeFilter") end)
    --Enchanting
    ZO_PreHook(ctrlVars.ENCHANTING.inventory, "ChangeFilter", function() updateFilteredItemCountThrottled(nil, 50, "Enchanting - ChangeFilter") end)
    --PreHook the QuickSlotWindow change filter function
    local function changeFilterQuickSlot(self, filterData)
        updateFilteredItemCountThrottled(LF_QUICKSLOT, 50, "Quickslots - ChangeFilter")
    end
    ZO_PreHook(ctrlVars.QUICKSLOT_WINDOW, "ChangeFilter", changeFilterQuickSlot)
    --Update the count of items filtered if text search boxes are used (ZOs or Votans Search Box)
    ZO_PreHook(ctrlVars.INVENTORY_MANAGER, "UpdateEmptyBagLabel", function(ctrl, inventoryType, isEmptyList)
        local inventories = ctrlVars.inventories
        if not inventories then return false end
        --Check if the currently active focus in inside a search box
        local inventory = inventories[inventoryType]
        local searchBox
        --Normal inventory update without searchBox changed
        local delay     = 50
        if inventory then
            local goOn             = false
            local searchBoxIsEmpty = false
            searchBox              = inventory.searchBox
            if searchBox and searchBox.GetText then
                local searchBoxText = searchBox:GetText()
                searchBoxIsEmpty    = (searchBoxText == "") or false
                if not searchBoxIsEmpty then
                    --Check if the contents of the searchbox are not only spaces
                    local searchBoxTextWithoutSpaces = strmatch(searchBoxText, "%S") -- %S = NOT a space
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
                goOn  = true
            elseif not searchBox or (searchBox and searchBoxIsEmpty) then
                --Delay for normal label update
                delay = 50
                goOn  = true
            end
            if not goOn then return false end
        end
        --d("[FCOIS]UpdateEmptyBagLabel, isEmptyList: " ..tos(isEmptyList))
        --Update the count of filtered/shown items before the sortHeader "name" text
        local filterPanelId = FCOIS.gFilterWhere
        --Special checks for the filterPanelId, for e.g. "QUEST items"
        if inventoryType == INVENTORY_QUEST_ITEM then
            filterPanelId = "INVENTORY_QUEST_ITEM"
        end
        updateFilteredItemCountThrottled(filterPanelId, delay, "ZO_InventoryManager - UpdateEmptyBagLabel")
    end)

    --Update inventory slot labels
    --[[ --todo 20250215 This is a local function! So how do we add our code to the local UpdateInventorySlots function, maybe by hooking into the slotsLabel:SetText function?
         --todo or is this even needed here? Maybe it's taken care of automatically via FCOIS' UpdateEmptyBagLabel hook?
    ZO_PreHook("UpdateInventorySlots", function()
        --d("[FCOIS]UpdateInventorySlots")
        --This variable (FCOIS.preventerVars.dontUpdateFilteredItemCount) is set within file src/FCOIS_FilterButtons.lua, function FCOIS.updateFilteredItemCount
        --if the addon AdvancedFilters is used, and the AF itemCount is enabled (next to the inventory free slots labels),
        --and FCOIS is calling the function AF.util.updateInventoryInfoBarCountLabel.
        -->Otherwise we would create an endless loop here which will be AF.util.updateInventoryInfoBarCountLabel -> UpdateInventorySlots ->
        --PreHook in FCOIS to function UpdateInventorySlots -> updateFilteredItemCountThrottled -> FCOIS.updateFilteredItemCount -> AF.util.updateInventoryInfoBarCountLabel ...
        if not FCOIS.preventerVars.dontUpdateFilteredItemCount then
            updateFilteredItemCountThrottled(nil, 50, "UpdateInventorySlots")
        end
    end)
    ]]

    --#288 Inventory's player/companion headerline at the character screen -> "Armor" or "Armor hidden"
    SecurePostHook(PLAYER_INVENTORY, "UpdateApparelSection", function(selfVar)
        --[[
        if ZO_CharacterApparelSectionText then
            local isApparelHidden = IsEquipSlotVisualCategoryHidden(EQUIP_SLOT_VISUAL_CATEGORY_APPAREL, GAMEPLAY_ACTOR_CATEGORY_PLAYER)
            local apparelString = isApparelHidden and GetString(SI_CHARACTER_EQUIP_APPAREL_HIDDEN) or GetString("SI_EQUIPSLOTVISUALCATEGORY", EQUIP_SLOT_VISUAL_CATEGORY_APPAREL)
            ZO_CharacterApparelSectionText:SetText(apparelString)
        end
        ]]
        updateEquipmentHeaderCountText = updateEquipmentHeaderCountText or FCOIS.UpdateEquipmentHeaderCountText
        updateEquipmentHeaderCountText(FCOIS_CON_LF_CHARACTER)
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
    ZO_PreHook(ctrlVars.playerInventory, "OnInventorySlotLocked", function(ctrl, bagId, slotIndex)
        d("[FCOIS]OnInventorySlotLocked, bagId: " ..tos(bagId) .. ", slotIndex: " ..tos(slotIndex))
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

    FCOIS.CreateHooks = function() d("[FCOIS]ERROR - Do not call FCOIS.CreateHooks again!")  end
end  -- function CreateHooks()
--============================================================================================================================================================
--===== HOOKS END ============================================================================================================================================
--============================================================================================================================================================