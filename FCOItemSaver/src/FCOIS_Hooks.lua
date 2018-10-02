--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local ctrlVars = FCOIS.ZOControlVars
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
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

local function callTestHooks(activateTestHooks)
	--Change to a true to activate the tets hooks!
	activateTestHooks = activateTestHooks or false

	--Abort test hooks?
    if not activateTestHooks then return end

	--The test hooks start below:
--------------------------------------------------------------------------------
--[[
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
	]]
end
--==============================================================================

--==============================================================================
--			Override another function
--==============================================================================
-- Override a function, adding overridden function a first parameter.
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
    if( not FCOIS.eventHandlers or not FCOIS.eventHandlers[eventName] ) then return nil end
    --Get the global event handler function of an object name
    return FCOIS.eventHandlers[eventName][objName]
end

-- adds handler to the event handler list
local function SetEventHandler(eventName, objName, handler)
    if ( not FCOIS.eventHandlers[eventName] ) then FCOIS.eventHandlers[eventName] = {} end
    --Set the global event handler function for an object name
    FCOIS.eventHandlers[eventName][objName] = handler
end

-- puts given handler in front of the event handler of given object
local function PreHookHandler(eventName, control, handler)
    --d("[FCOIS] PreHookHandler - eventName: " .. tostring(eventName) .. ", control: " .. tostring(control:GetName()))
    if eventName == nil or eventName == "" or control == nil or handler == nil then return false end
    --Get the current objects event handler function
    local currentEventHandlerFunc = control:GetHandler(eventName)
    if currentEventHandlerFunc then
        --Save the event handler function to the global array (for later checks)
        SetEventHandler(eventName, control:GetName(), currentEventHandlerFunc)
    end
    --Assign the new event handler function which will be called first
    control:SetHandler(eventName, handler)
end

--==============================================================================
--			Context menu / right click / slot actions
--==============================================================================
--PreHook the global ZO_Menu hide function to show the PlayerProgressBar again at the character panel
ZO_PreHook("ZO_Menu_OnHide", function(ctrl)
    --Check if the character window is shown and if the current scene is the inventory scene
    if not ctrlVars.CHARACTER:IsHidden() and SCENE_MANAGER.currentScene.name == "inventory" then
        --Show the PlayerProgressBar again as the context menu closes
        FCOIS.ShowPlayerProgressBar(true)
    end
end)

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
            local itemLink = GetItemLink(bag, slotIndex)
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

--========= INVENTORY SLOT - PRIMARY ACTION =================================
--[[
--On doubleclick of an usable item
ZO_PreHook("ZO_InventorySlot_DoPrimaryAction", function(inventorySlot)
--d("[FCOIS]ZO_InventorySlot_DoPrimaryAction")
    if not ctrlVars.BACKPACK:IsHidden() then
        local retVar = FCOIS.useAddSlotActionCallbackFunc(inventorySlot)
        --Do the transmutation geode container checks now
        return retVar
    end
    return false
end)
]]

--AddContextMenuEntry -> SlotAction
--Pre Hook function for adding right click/context menu entries.
--Attention: Will be executed on mouse enter on a slot in inventories
--AND if you open the context menu by a mouse righ-click
--To distinguish these two "events" you can use: if self.m_contextMenuMode == true then
--true: Context-menu is open, false: Only mouse hoevered over the item
local function FCOItemSaver_AddSlotAction(self, actionStringId, ...)
    local settings = FCOIS.settingsVars.settings
    local mappingVars = FCOIS.mappingVars
    --d(">[FCOIS]FCOItemSaver_AddSlotAction-actionStringId: " ..tostring(actionStringId))
    --Is the ZOs player lock item functionality enabled?
    if not settings.useZOsLockFunctions then
        --Only execute if context menu is visible?
        if self.m_contextMenuMode then
            --Hide the context menu entry ZOs added to lock/unlock items
            if actionStringId == SI_ITEM_ACTION_MARK_AS_LOCKED or actionStringId == SI_ITEM_ACTION_UNMARK_AS_LOCKED then
                return true
            end
        end
    end

    local isNewSlot = self.m_inventorySlot ~= FCOIS.preventerVars.lastHoveredInvSlot
    if isNewSlot then
        FCOIS.preventerVars.lastHoveredInvSlot = self.m_inventorySlot
    end
    local parentControl
    local isShowingCharacter = not ctrlVars.CHARACTER:IsHidden()
    --Chracter equipment, or normal slot?
    if (isShowingCharacter) then
        parentControl = self.m_inventorySlot
    else
        parentControl = self.m_inventorySlot:GetParent()
    end
    --No parent found? Abort
    if parentControl == nil then return false end
    local parentName = parentControl:GetName()

    local bag, slotIndex = FCOIS.MyGetItemDetails(parentControl)
    --is the mouse only hovered over the item or was the right click mouse context menu shown?
    local mouseRightClickDone = self.m_contextMenuMode
    --Hide the inventory button contextMenu if shown and if we right clicked another item
    if mouseRightClickDone == true then
        if settings.debug then FCOIS.debugMessage( "[FCOIS]AddSlotAction-Parent: " .. parentName .. ", actionStringId: " .. tostring(actionStringId), true, FCOIS_DEBUG_DEPTH_ALL) end
        --Hide the context menu at last active panel
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)

        --Check if the character window is shown
        if isShowingCharacter then
--d("[FCOIS]FCOItemSaver_AddSlotAction - Char window shown, Parent: " .. tostring(parentName))
            --Check if the parent control is a character slot
            if mappingVars.characterEquipmentArmorSlots[parentName] or
                mappingVars.characterEquipmentJewelrySlots[parentName] or
                mappingVars.characterEquipmentWeaponSlots[parentName] then
                --Hide the PlayerProgressBar so the context menu is shown completely
                FCOIS.ShowPlayerProgressBar(false)
            end
        end
    else
        if isNewSlot then
            if settings.debug then FCOIS.debugMessage( "[FCOIS]AddSlotAction-Parent: " .. parentName, true, FCOIS_DEBUG_DEPTH_ALL) end
        end
    end

    --Use item?
    if        actionStringId == SI_ITEM_ACTION_USE then
        --Is the item protected with any icon?
        local marked, _ = FCOIS.IsMarked(bag, slotIndex, -1)
        if marked and IsItemUsable(bag, slotIndex) then
            --If mail send or player trade panel is activated
            local isCurrentlyShowingMailSend 	= not ctrlVars.MAIL_SEND:IsHidden() and settings.blockSendingByMail
            local isCurrentlyShowingPlayerTrade = not ctrlVars.PLAYER_TRADE:IsHidden() and settings.blockTrading
            local isContainerWithAutoLootEnabled= FCOIS.isAutolootContainer(bag, slotIndex) and settings.blockAutoLootContainer
            local isARecipe		 				= FCOIS.isItemType(bag, slotIndex, ITEMTYPE_RECIPE) and settings.blockMarkedRecipes
            local isAStyleMotif					= FCOIS.isItemType(bag, slotIndex, ITEMTYPE_RACIAL_STYLE_MOTIF) and settings.blockMarkedMotifs
            local isAPotion					    = FCOIS.isItemType(bag, slotIndex, ITEMTYPE_POTION) and settings.blockMarkedPotions
            local isAFood					    = FCOIS.isItemType(bag, slotIndex, ITEMTYPE_FOOD) and settings.blockMarkedFood
            --local isARepairKit				  = FCOIS.isItemType(bag, slot, ITEMTYPE_TOOL)
            local isACrownStoreItem             = (FCOIS.isItemType(bag, slotIndex, ITEMTYPE_CROWN_ITEM) or FCOIS.isItemType(bag, slotIndex, ITEMTYPE_CROWN_REPAIR)) and settings.blockCrownStoreItems

            --d("[FCOIS]FCOItemSaver_AddSlotAction - PanelId: " .. tostring(FCOIS.gFilterWhere) .. ", isARecipe: " .. tostring(isARecipe) .. ", isAStyleMotif: " .. tostring(isAStyleMotif) .. ", isAFood: " .. tostring(isAFood))
            --Only if we are in the inventory
            if FCOIS.gFilterWhere == LF_INVENTORY then
                --See if the Anti-settings for the given panel are enabled or not
                local _, invAntiSettingsEnabled = FCOIS.getContextMenuAntiSettingsTextAndState(FCOIS.gFilterWhere, false)
                --d("[FCOIS]>> invAntiSettingsEnabled: " .. tostring(invAntiSettingsEnabled) ..", recipeFlag: ".. tostring(settings.blockMarkedRecipesDisableWithFlag) .. ", styleMotifFLag: " .. tostring(settings.blockMarkedMotifsDisableWithFlag) .. ", foodFlag: " .. tostring(settings.blockMarkedFoodDisableWithFlag))
                --The protective functions are not enabled (red flag in the inventory additional options flag icon)
                if not invAntiSettingsEnabled then
                    --Using/eating/drinking items for marked items is blocked, e.g. for recipes/style motifs?
                    --If the settings allow it: Change the blocked state to unblocked upon right-clicking the inventory additional options flag icon
                    --Recipes
                    if isARecipe and settings.blockMarkedRecipesDisableWithFlag then
                        isARecipe = false
                    end
                    --Style motifs
                    if isAStyleMotif and settings.blockMarkedMotifsDisableWithFlag then
                        isAStyleMotif = false
                    end
                    --Drink & food
                    if (isAFood or isAPotion) and settings.blockMarkedFoodDisableWithFlag then
                        isAFood = false
                        isAPotion = false
                    end
                    --Autoloot container
                    if isContainerWithAutoLootEnabled and settings.blockMarkedAutoLootContainerDisableWithFlag then
                        isContainerWithAutoLootEnabled = false
                    end
                    --Crown store item
                    if isACrownStoreItem and settings.blockMarkedCrownStoreItemDisableWithFlag then
                        isACrownStoreItem = false
                    end
                end
            end
            --Is any of the settings to protect enabled
            if    isCurrentlyShowingMailSend or isCurrentlyShowingPlayerTrade
                    or isContainerWithAutoLootEnabled
                    or isARecipe
                    or isAStyleMotif
                    or isAPotion
                    or isAFood
                    or isACrownStoreItem
            then
                --remove the context-menu entry for "use" (and the keybinding)
                return true
            end
        end

    --Enchant
    elseif actionStringId == SI_ITEM_ACTION_ENCHANT then
        --Remove enchant possibility for The Master's and Maelstrom weapons & shields
        if settings.blockSpecialItemsEnchantment then
            local specialItems = FCOIS.specialItems
            local isSpecialItem = FCOIS.checkIfIsSpecialItem(bag, slotIndex) or false
            return isSpecialItem --Remove the context menu entry for "enchant"
        end

    --Destroy item
    elseif    actionStringId == SI_ITEM_ACTION_DESTROY then

        --Only execute if context menu is visible?
        if mouseRightClickDone == false then
            --remove the context-menu entry for "use" (and the keybinding)
            return
        end

        --Abort if parent control cannot be found
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        return FCOIS.DestroySelectionHandler(bag, slotIndex, false, parentControl)

    --Add item to crafting station, improvement, enchanting, retrait table
    elseif actionStringId == SI_ITEM_ACTION_ADD_TO_CRAFT or actionStringId == SI_ITEM_ACTION_RESEARCH then --or actionStringId == SI_ITEM_ACTION_ADD_TO_RETRAIT then
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        return FCOIS.callDeconstructionSelectionHandler(bag, slotIndex, false)

    --Trade an item, mark item as junk, attach item to mail, sell item, launder item, add to trading house listing (sell there) or add to crafting station
    elseif actionStringId == SI_ITEM_ACTION_TRADE_ADD
            or actionStringId == SI_ITEM_ACTION_MAIL_ATTACH or actionStringId == SI_ITEM_ACTION_SELL
            or actionStringId == SI_ITEM_ACTION_LAUNDER
            --Anbieten / sell in guild shop
            or actionStringId == SI_TRADING_HOUSE_ADD_ITEM_TO_LISTING
            or (actionStringId == SI_ITEM_ACTION_MARK_AS_JUNK and settings.removeMarkAsJunk) then
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
        return FCOIS.callItemSelectionHandler(bag, slotIndex, false, false, false, false, false, false, false)

    --Equip
    elseif actionStringId == SI_ITEM_ACTION_EQUIP then
        --Check the current scene and see if we are at the store
        local currentScene = SCENE_MANAGER.currentScene.name
        local isStore = (currentScene and currentScene == "store") or false
        local isFence = (SCENE_MANAGER.currentScene == FENCE_SCENE) or false
        --Or are we in the guild store/trading house?
        local isCurrentlyShowingGuildStore = not ctrlVars.GUILD_STORE:IsHidden()
        --Or are we currently showing the mail send panel?
        local isMailSend = not ctrlVars.MAIL_SEND:IsHidden()
        --Or the player2player trade scene is shown?
        local isPlayer2PlayerTrade = not ctrlVars.PLAYER_TRADE:IsHidden()
        --Disable the "equip" entry for the above checked panels now so the standard keybind is not the "equip" one
        if isStore or isFence or isCurrentlyShowingGuildStore or isMailSend or isPlayer2PlayerTrade then
            --Is the item protected with any icon?
            local marked, _ = FCOIS.IsMarked(bag, slotIndex, -1)
            if marked then
                --remove the context-menu entry for "equip" (and the keybinding)
                return true
            end
        end

    --Bank deposit
    elseif actionStringId == SI_ITEM_ACTION_BANK_DEPOSIT then
        --Are we at the guild bank and is the protection setting for "non-withdrawable items" enabled?
        if settings.blockGuildBankWithoutWithdraw and (SCENE_MANAGER:GetCurrentScene():GetName() == "guildBank" or SCENE_MANAGER:GetCurrentScene():GetName() == "gamepad_guild_bank") then
            if FCOIS.guildBankVars.guildBankId == 0 then return true end
            return not FCOIS.checkIfGuildBankWithdrawAllowed(FCOIS.guildBankVars.guildBankId)
        end

    --Buy (at vendor)
    elseif actionStringId == SI_ITEM_ACTION_BUY or actionStringId == SI_ITEM_ACTION_BUY_MULTIPLE then

    --Buy back (at vendor)
    elseif actionStringId == SI_ITEM_ACTION_BUYBACK then

    --Repair (at vendor)
    elseif actionStringId == SI_ITEM_ACTION_REPAIR then


    --CraftBagExtended: Unpack item and add to mail
    elseif FCOIS.otherAddons.craftBagExtendedActive and actionStringId == SI_CBE_CRAFTBAG_MAIL_ATTACH then
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
        return FCOIS.callItemSelectionHandler(bag, slotIndex, false, false, false, false, false, false, false)

        --De-comment to show the other slot actions
        --else
        --d("actionStringId: " .. actionStringId .. " = " .. GetString(actionStringId))
    end
end


--==============================================================================
--			ON EVENT Methods (drag/drop, doubleclick, ...)
--==============================================================================

-- handler function for character window item controls' OnMouseDoubleClick event
local function FCOItemSaver_CharacterItem_OnMouseDoubleClick(self, ...)
    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    local bagId, slotId

    -- make sure control contains an item
    if( self.dataEntry and self.dataEntry.data ) then
        bagId = self.dataEntry.data.bagId
        slotId = self.dataEntry.data.slotIndex
    else
        if( self.slotIndex and self.bagId ) then
            bagId  = self.bagId
            slotId = self.slotIndex
        end
    end

    -- call the original handler function
    local func = GetEventHandler("OnMouseDoubleClick", self:GetName())
    if ( not func ) then return false end

    return func(self, ...)
end

-- handler function for inventory item controls' OnMouseUp event
local function FCOItemSaver_InventoryItem_OnMouseUp(self, mouseButton, upInside, ctrlKey, altKey, shiftKey, ...)
--d("[FCOIS]InventoryItem_OnMouseUp] mouseButton: " .. tostring(mouseButton) .. ", upInside: " .. tostring(upInside).. ", ctrlKey: " .. tostring(ctrlKey) .. ", altKey: " .. tostring(altKey).. ", shiftKey: " .. tostring(shiftKey))
    FCOIS.preventerVars.dontShowInvContextMenu = false
    --Enable clearing all markers by help of the SHIFT+right click?
    FCOIS.checkIfClearOrRestoreAllMarkers(self, shiftKey, upInside, mouseButton, false)
    --Call original callback function for event OnMouseUp of the iinventory item row/character equipment slot now
    return false
end

-- handler function for inventory item controls' OnMouseDoubleClick event
local function FCOItemSaver_InventoryItem_OnMouseDoubleClick(self, ...)
--d("[FCOIS]InventoryItem_OnMouseDoubleClick]")
    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    local bagId, slotId
    -- make sure control contains an item
    if( self.dataEntry and self.dataEntry.data ) then
        bagId = self.dataEntry.data.bagId
        slotId = self.dataEntry.data.slotIndex
    else
        if( self.slotIndex and self.bagId ) then
            bagId  = self.bagId
            slotId = self.slotIndex
        end
    end

    if( bagId ~= nil and slotId ~= nil ) then
        --Set: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
        FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = true

        -- Inside deconstruction?
        if(not ctrlVars.DECONSTRUCTION_BAG:IsHidden() ) then
            -- check if deconstruction is forbidden
            -- if so, return false to prevent selection of the item
            if( FCOIS.callDeconstructionSelectionHandler(bagId, slotId, true) ) then
                ClearCursor()
                return false
            end
            --Others
        else
            --check if item interaction is forbidden
            --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
            if( FCOIS.callItemSelectionHandler(bagId, slotId, true, false, false, false, false, false, false) ) then
                ClearCursor()
                -- item is not allowed to work with return false to prevent selection of the item
                return false
            end
        end
        --Reset: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
        FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
    end

    -- call the original handler function
    local func = GetEventHandler("OnMouseDoubleClick", self:GetName())
    if ( not func ) then return false end

    return func(self, ...)
end

-- handler function for character equipment double click -> OnEffectivelyShown function
local function FCOItemSaver_CharacterOnEffectivelyShown(self, ...)
    if ( not self ) then return false end
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
    local equipmentSlotName
--d("[FCOItemSaver_CharacterOnEffectivelyShown]: " .. self:GetName())
    for i = 1, self:GetNumChildren() do
        -- override OnMouseDoubleClick event of character window item controls, for each row (children)
        equipmentSlotName = ctrlVars.CHARACTER:GetChild(i):GetName()
        if equipmentSlotName ~= nil then
            if(string.find(equipmentSlotName, "ZO_CharacterEquipmentSlots")) then
--d(">EquipmentSlot: " ..tostring(equipmentSlotName))
                local currentCharChild = self:GetChild(i)
                if currentCharChild ~= nil then
                    if( currentCharChild:GetHandler("OnMouseDoubleClick") ~= FCOItemSaver_CharacterItem_OnMouseDoubleClick ) then
                        --Mouse double click event
                        PreHookHandler( "OnMouseDoubleClick", currentCharChild, FCOItemSaver_CharacterItem_OnMouseDoubleClick)
                    end
                    if contextMenuClearMarkesByShiftKey then
                        --Mouse up event for the SHIFT+right mouse button
                        if( not GetEventHandler("OnMouseUp", equipmentSlotName) ) then
--d(">>Set event handler: OnMouseUp")
                            --is not working as it'll overwrite the original OnMouseUp callback function totally somehow :-(
                            --PreHookHandler( "OnMouseUp", childrenCtrl, FCOItemSaver_InventoryItem_OnMouseUp)
                            --Add the custom event handler function to a global list so it won't be added twice
                            SetEventHandler("OnMouseUp", equipmentSlotName, FCOItemSaver_InventoryItem_OnMouseUp)
                            --Use ZO function to PreHook the event handler now
                            ZO_PreHookHandler(currentCharChild, "OnMouseUp", function(...)
                                FCOItemSaver_InventoryItem_OnMouseUp(...)
                            end)
                        end
                    end
                end
            end
        end
    end
    -- call the original handler function
    local func = GetEventHandler("OnEffectivelyShown", self:GetName())
    if ( not func ) then return false end
    return func(self, ...)
end

-- handler function for new shown bag & slotindex (during scrolling e.g.) -> register double click event for the new shown items -> OnEffectivelyShown function
local function FCOItemSaver_OnEffectivelyShown(self, ...)
    --Should we update the marker textures, size and color?
    FCOIS.checkMarker(-1)
    if ( not self ) then return false end
    local isABankWithdraw = (self == ctrlVars.BANK_BAG or self == ctrlVars.GUILD_BANK_BAG or self == ctrlVars.HOUSE_BANK_BAG)
--d("[FCOItemSaver_OnEffectivelyShown]: " .. self:GetName() .. ", isABankWithdraw: " .. tostring(isABankWithdraw))
    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
    local isCharacter = (self == ctrlVars.CHARACTER) or false
    for i = 1, self:GetNumChildren() do
        local childrenCtrl = self:GetChild(i)
        --Do not add protection double click functions to bank/guild bank withdraw and character!
        if not isABankWithdraw and not isCharacter then
            -- Append OnMouseDoubleClick event of inventory item controls, for each row (children)
            if( childrenCtrl:GetHandler("OnMouseDoubleClick") ~= FCOItemSaver_InventoryItem_OnMouseDoubleClick ) then
                PreHookHandler( "OnMouseDoubleClick", childrenCtrl, FCOItemSaver_InventoryItem_OnMouseDoubleClick)
            end
        end

        --Enable clearing all markers by help of the SHIFT+right click?
        if contextMenuClearMarkesByShiftKey then
            local childrenName = childrenCtrl:GetName()
            -- Append OnMouseUp event of inventory item controls, for each row (children), if it is not already set there before inside the if via SetEventHandler(...)
            if( not GetEventHandler("OnMouseUp", childrenName) ) then
                --is not working as it'll overwrite the original OnMouseUp callback function totally somehow :-(
                --PreHookHandler( "OnMouseUp", childrenCtrl, FCOItemSaver_InventoryItem_OnMouseUp)
                --Add the custom event handler function to a global list so it won't be added twice
                SetEventHandler("OnMouseUp", childrenName, FCOItemSaver_InventoryItem_OnMouseUp)
                --Use ZO function to PreHook the event handler now
                ZO_PreHookHandler(childrenCtrl, "OnMouseUp", function(...)
                    FCOItemSaver_InventoryItem_OnMouseUp(...)
                end)
            end
        end
    end
    -- call the original handler function
    local func = GetEventHandler("OnEffectivelyShown", self:GetName())
    if ( not func ) then return false end
    return func(self, ...)
end

--Callback function for start a new drag&drop operation
local function FCOItemSaver_OnDragStart(inventorySlot)
    if inventorySlot == nil then return end
    local cursorContentType = GetCursorContentType()
    --d("[OnDragStart] cursorContentType: " .. tostring(cursorContentType) .. "/" .. tostring(MOUSE_CONTENT_INVENTORY_ITEM))
    --if(cursorContentType == MOUSE_CONTENT_EMPTY) then return end

    local bag
    local slot
    if inventorySlot.dataEntry ~= nil and inventorySlot.dataEntry.data ~= nil then
        bag		= inventorySlot.dataEntry.data.bagId
        slot	= inventorySlot.dataEntry.data.slotIndex
    elseif inventorySlot.bagId ~= nil and inventorySlot.slotIndex ~= nil then
        bag		= inventorySlot.bagId
        slot	= inventorySlot.slotIndex
    end
    FCOIS.dragAndDropVars.bag = nil
    FCOIS.dragAndDropVars.slot = nil
    if bag == nil or slot == nil then return end
    FCOIS.dragAndDropVars.bag = bag
    FCOIS.dragAndDropVars.slot = slot
end

--Callback function for receive a dragged inventory item
local function FCOItemSaver_OnReceiveDrag(inventorySlot)
    --FCOinvs = inventorySlot
    local cursorContentType = GetCursorContentType()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[OnReceiveDrag] cursorContentType: " .. tostring(cursorContentType) .. "/" .. tostring(MOUSE_CONTENT_INVENTORY_ITEM) .. ", invSlotType: " .. tostring(inventorySlot.slotType) .. "/" .. tostring(SLOT_TYPE_EQUIPMENT), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    -- if there is an inventory item on the cursor:
    if cursorContentType ~= MOUSE_CONTENT_INVENTORY_ITEM and cursorContentType ~= MOUSE_CONTENT_EQUIPPED_ITEM then return end

    -- and the slot type we're dropping it on is an equip slot:
    if inventorySlot.slotType == SLOT_TYPE_EQUIPMENT then
        local bag
        local slot
        --Was the drag started with another item then the dropped item slot?
        if FCOIS.dragAndDropVars.bag ~= nil and FCOIS.dragAndDropVars.slot ~= nil then
            bag			= FCOIS.dragAndDropVars.bag
            slot		= FCOIS.dragAndDropVars.slot
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

--Function to update the on mouse double click (OnEffectivelyShown) functions for new visible inventory rows
function FCOIS.UpdateOnEffectivelyShownRows(delay)
    delay = delay or 0
    --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
    if not ctrlVars.REFINEMENT_BAG:IsHidden() then
        zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.REFINEMENT_BAG) end, delay)
    elseif not ctrlVars.DECONSTRUCTION_BAG:IsHidden() then
        zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.DECONSTRUCTION_BAG) end, delay)
    elseif not ctrlVars.IMPROVEMENT_BAG:IsHidden() then
        zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.IMPROVEMENT_BAG) end, delay)
    elseif not ctrlVars.ENCHANTING_STATION_BAG:IsHidden() then
        zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.ENCHANTING_STATION_BAG) end, delay)
    elseif not ctrlVars.ALCHEMY_STATION_BAG:IsHidden() then
        zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.ALCHEMY_STATION_BAG) end, delay)
    elseif not ctrlVars.RETRAIT_BAG:IsHidden() then
        zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.RETRAIT_BAG) end, delay)
    end
end


--============================================================================================================================================================
--===== HOOKS BEGIN ==========================================================================================================================================
--============================================================================================================================================================
--Create the hooks & pre-hooks
function FCOIS.CreateHooks()
    local settings = FCOIS.settingsVars.settings
    local locVars = FCOIS.localizationVars.fcois_loc

    --========= INVENTORY SLOT - SHOW CONTEXT MENU =================================
    -- Hook functions for the inventory/store contextmenus
    ZO_PreHook("ZO_InventorySlot_ShowContextMenu", function(rowControl)
        local prevVars = FCOIS.preventerVars
        FCOIS.preventerVars.buildingInvContextMenuEntries = false
        --As this prehook is called before the character OnMouseUp funciton is called:
        --If the SHIFT+right mouse button option is enabled and the SHIFT key is pressed and the character is shown.
        --Then hide the context menu
        local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
        local isCharacterShown = not FCOIS.ZOControlVars.CHARACTER:IsHidden()

    --d("[FCOIS]ZO_InventorySlot_ShowContextMenu - dontShowInvContextMenu: " ..tostring(FCOIS.preventerVars.dontShowInvContextMenu) .. ", isCharacterShown: " ..tostring(isCharacterShown))
        --Clear the sub context menu entries
        FCOIS.customMenuVars.customMenuSubEntries = {}
        FCOIS.customMenuVars.customMenuDynSubEntries = {}
        FCOIS.customMenuVars.customMenuCurrentCounter = 0

        --if the context menu should not be shown, because all marker icons were removed
        -- hide it now
        if prevVars.dontShowInvContextMenu == false and isCharacterShown and contextMenuClearMarkesByShiftKey and IsShiftKeyDown() then
--d(">FCOIS context menu, shift key is down")
            FCOIS.preventerVars.dontShowInvContextMenu = true
        end
        if prevVars.dontShowInvContextMenu then
--d(">FCOIS context menu, hiding it!")
            FCOIS.preventerVars.dontShowInvContextMenu = false
            --Hide the context menu now by returning true in this preHook and not calling the "context menu show" function
            return true
        end

        --Call a little bit later so the context menu is already created
        zo_callLater(function()
            --Reset the IIfA clicked variables
            FCOIS.IIfAclicked = nil

            local noGear
            local gearId

            local parentControl = rowControl:GetParent()

            local FCOcontextMenu = {}

            --Check if the user set ordering is valid, else use the default sorting
            local userOrderValid = FCOIS.checkIfUserContextMenuSortOrderValid()
            local resetSortOrderDone = false

            local contextMenuEntriesAdded = 0
            --check each iconId and build a sorted context menu then
            local useSubContextMenu     = settings.useSubContextMenu
            local countIconsEnabled, countDynIconsEnabled = FCOIS.countMarkerIconsEnabled()
            local useDynSubContextMenu  = (settings.useDynSubMenuMaxCount > 0 and  countDynIconsEnabled >= settings.useDynSubMenuMaxCount) or false
            for iconId = 1, numFilterIcons, 1 do
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
                for j = 1, numFilterIcons, 1 do
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
                        --ClearMenu()
                        if FCOIS.customMenuVars.customMenuSubEntries ~= nil and #FCOIS.customMenuVars.customMenuSubEntries > 0 then
                            AddCustomSubMenuItem("|c22DD22FCO|r ItemSaver", FCOIS.customMenuVars.customMenuSubEntries)
                        else
                            if FCOIS.customMenuVars.customMenuDynSubEntries ~= nil and #FCOIS.customMenuVars.customMenuDynSubEntries > 0 then
                                local dynamicSubMenuEntryHeaderText = locVars["options_icons_dynamic"]
                                if settings.addContextMenuLeadingMarkerIcon then
                                    dynamicSubMenuEntryHeaderText = "  " .. dynamicSubMenuEntryHeaderText
                                end
                                AddCustomSubMenuItem(dynamicSubMenuEntryHeaderText, FCOIS.customMenuVars.customMenuDynSubEntries)
                            end
                        end
                        ShowMenu()
                    end, 30)
                end
            end -- if contextMenuEntriesAdded > 0 then
            FCOIS.preventerVars.buildingInvContextMenuEntries = false
        end, 30) -- zo_callLater
    end)

    --========= ZO_DIALOG1 / DESTROY DIALOG ========================================
    --Destroy item dialog button 2 ("Abort") hook
    ZO_PreHook(ctrlVars.DestroyItemDialog.buttons[2], "callback", function()
        --Get the "YES" button of the destroy dialog
        local button1 = ZO_Dialog1:GetNamedChild("Button1")
        if button1 == nil then return false end
        --Reset the "YES" button of the dialog again after a few seconds
        zo_callLater(function()
            if ZO_Dialog1 ~= nil and button1 ~= nil then
                ZO_Dialog1:SetKeyboardEnabled(false)
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
            if settings.debug then FCOIS.debugMessage( "[EquipItem] bagId: " .. bagId .. ", slotIndex: " .. slotIndex .. ", equipSlotIndex: " ..tostring(equipSlotIndex), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[EquipItem] bagId: " .. bagId .. ", slotIndex: " .. slotIndex .. ", equipSlotIndex: " ..tostring(equipSlotIndex))

            --Check if the item is bound on equip and show dialog to acceppt the binding before (if enabled in the settings)
            return FCOIS.CheckBindableItems(bagId, slotIndex, equipSlotIndex)
        end
    end)

    --========= UNEQUIP ITEM =======================================================
    ZO_PreHook("UnequipItem", function(equipSlot)
        if equipSlot ~= nil then
            if settings.debug then FCOIS.debugMessage( "[UnequipItem] slotIndex: " .. equipSlot, true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --If item was unequipped: Remove the armor type marker if necessary
            FCOIS.removeArmorTypeMarker(BAG_WORN, equipSlot)
            --Update the marker control of the new equipped item
            FCOIS.updateEquipmentSlotMarker(equipSlot, 1000)
        end
    end)

    --========= MENU BARS ==========================================================
    --Preehook the menu bar shown event to update the character equipment section if it is shown
    ZO_PreHookHandler(ZO_MainMenuCategoryBar, "OnShow", function()
        if settings.debug then FCOIS.debugMessage( "[Hook] Main Menu Category Bar: OnShow") end

        --Hide the context menu
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)

        --Update the character's equipment markers, if the character screen is shown
        if not ctrlVars.CHARACTER:IsHidden() then
            FCOIS.RefreshEquipmentControl()
        end

        --Update the dialog button 1 to show and respond again, if an item was tried to destroyed
        --Get the "yes" button control of the destroy popup window
        if FCOIS.preventerVars.wasDestroyDone then
            local button1 = ZO_Dialog1:GetNamedChild("Button1")
            if button1 then
                button1:SetEnabled(true)
                button1:SetMouseEnabled(true)
                button1:SetHidden(false)
                button1:SetKeybindEnabled(true)
                ZO_Dialog1:SetKeyboardEnabled(false)
                FCOIS.preventerVars.wasDestroyDone = false
            end
        end

        --Check, if the Anti-* checks need to be enabled again
        FCOIS.autoReenableAntiSettingsCheck("DESTROY")
    end)

    --========= REFINEMENT =========================================================
    --Pre Hook the refinement for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.REFINEMENT_BAG, FCOItemSaver_OnEffectivelyShown )
    --PreHook the receiver function of drag&drop at the refinement panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.SMITHING, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        return FCOIS.isCraftBagItemDraggedToCraftingSlot(LF_SMITHING_REFINE, bagId, slotIndex)
    end)

    local hookedFunctions = ctrlVars.REFINEMENT.dataTypes[1].setupCallback
    ctrlVars.REFINEMENT.dataTypes[1].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)
        -- for all filters: Create/Update the icons
        for i = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, i, settings.icon[i].size or FCOIS.iconVars.gIconWidth, settings.icon[i].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[i].texture])
        end
        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
        FCOIS.UpdateOnEffectivelyShownRows()
    end

    --========= DECONSTRUCTION =====================================================
    --Pre Hook the deconstruction for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.DECONSTRUCTION_BAG, FCOItemSaver_OnEffectivelyShown )
    local hookedFunctions = ctrlVars.DECONSTRUCTION.dataTypes[1].setupCallback
    ctrlVars.DECONSTRUCTION.dataTypes[1].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)
        -- for all filters: Create/Update the icons
        for i = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, i, settings.icon[i].size or FCOIS.iconVars.gIconWidth, settings.icon[i].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[i].texture])
        end
        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
        FCOIS.UpdateOnEffectivelyShownRows()
    end

    --========= IMPROVEMENT ========================================================
    --Pre Hook the improvement for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.IMPROVEMENT_BAG, FCOItemSaver_OnEffectivelyShown )
    local hookedFunctions = ctrlVars.IMPROVEMENT.dataTypes[1].setupCallback
    ctrlVars.IMPROVEMENT.dataTypes[1].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)
        -- for all filters: Create/Update the icons
        for i = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, i, settings.icon[i].size or FCOIS.iconVars.gIconWidth, settings.icon[i].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[i].texture])
        end
        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
        FCOIS.UpdateOnEffectivelyShownRows()
    end

    --========= ENCHANTING =========================================================
    --Pre Hook the enchanting table for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.ENCHANTING_STATION_BAG, FCOItemSaver_OnEffectivelyShown )
    --PreHook the receiver function of drag&drop at the refinement panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.ENCHANTING, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        --Rune creation & extraction!
        return FCOIS.isCraftBagItemDraggedToCraftingSlot(LF_ENCHANTING_CREATION, bagId, slotIndex)
    end)

    local hookedFunctions = ctrlVars.ENCHANTING_STATION.dataTypes[1].setupCallback
    ctrlVars.ENCHANTING_STATION.dataTypes[1].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)
        -- for all filters: Create/Update the icons
        for i = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, i, settings.icon[i].size or FCOIS.iconVars.gIconWidth, settings.icon[i].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[i].texture])
        end
        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
        FCOIS.UpdateOnEffectivelyShownRows()
    end

    --========= ALCHEMY ============================================================
    --Solvents
    --Pre Hook the alchemy table for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.ALCHEMY_STATION_BAG, FCOItemSaver_OnEffectivelyShown )
    --PreHook the receiver function of drag&drop at the refinement panel as items from the craftbag won't fire
    --the event EVENT_INVENTORY_SLOT_LOCKED :-(
    ZO_PreHook(ctrlVars.ALCHEMY, "OnItemReceiveDrag", function(ctrl, slotControl, bagId, slotIndex)
        --Alchemy creation
        return FCOIS.isCraftBagItemDraggedToCraftingSlot(LF_ALCHEMY_CREATION, bagId, slotIndex)
    end)


    local hookedFunctions = ctrlVars.ALCHEMY_STATION.dataTypes[1].setupCallback
    ctrlVars.ALCHEMY_STATION.dataTypes[1].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)
        -- for all filters: Create/Update the icons
        for i = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, i, settings.icon[i].size or FCOIS.iconVars.gIconWidth, settings.icon[i].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[i].texture])
        end
        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
        FCOIS.UpdateOnEffectivelyShownRows()
    end
    --Reagents
    local hookedFunctions = ctrlVars.ALCHEMY_STATION.dataTypes[2].setupCallback
    ctrlVars.ALCHEMY_STATION.dataTypes[2].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)
        -- for all filters: Create/Update the icons
        for i = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, i, settings.icon[i].size or FCOIS.iconVars.gIconWidth, settings.icon[i].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[i].texture])
        end
        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
        FCOIS.UpdateOnEffectivelyShownRows()
    end

    --========= RETRAIT =========================================================
    --Pre Hook the retrait table for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.RETRAIT_BAG, FCOItemSaver_OnEffectivelyShown )
    local hookedFunctions = ctrlVars.RETRAIT_LIST.dataTypes[1].setupCallback
    ctrlVars.RETRAIT_LIST.dataTypes[1].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)
        -- for all filters: Create/Update the icons
        for i = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, i, settings.icon[i].size or FCOIS.iconVars.gIconWidth, settings.icon[i].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[i].texture])
        end
        --Add additional FCO point to the dataEntry.data slot
        --FCOItemSaver_AddInfoToData(rowControl)
        --Update the mouse double click handler OnEffectivelyShown() for the crafting stations, as new inventory rows could have been added
        FCOIS.UpdateOnEffectivelyShownRows()
    end

    --========= RESEARCH LIST / ListDialog (also repair, enchant, charge, etc.) ======================================================
    local hookedFunctions = ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback
    ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback = function(rowControl, slot)
        hookedFunctions(rowControl, slot)

        local data = rowControl.dataEntry.data

        --Check if rowControl is a soulgem
        --GLOBALOL = data
        local isSoulGem = false
        if(data and GetSoulGemItemInfo(data.bag, data.index) > 0) then
            isSoulGem = true
        end

        local myItemInstanceIdOfControl = FCOIS.MyGetItemInstanceId(rowControl)
        local disableControl = false

        --Suspend the source code here a bit as the list dialog name etc. will be given after a few milliseconds
        zo_callLater(function()

            --Current dialog is the repair item dialog?
            local isRepairDialog = ZO_Dialogs_IsShowing(ctrlVars.RepairItemDialogName)

            -- Check the rowControl if the item is marked and update the OnMouseUp functions and the color of the item row then
            for iconId = 1, numFilterIcons, 1 do
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
                        if (isRepairDialog and settings.blockMarkedRepairKits) or (not isRepairDialog) then
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
                end

            end -- for j = 1, numFilterIcons, 1 do

            --Get here after for loop is left by a "break" and item is not researchable
            if disableControl == true then
                --Change the color of the item to red
                rowControl:GetNamedChild("Name"):SetColor(0.75, 0, 0, 1)
            end

        end, 150) -- zo_callLater(function()...)

        --Pre-Hook the list dialog's rows

        --Pre-Hook the handler "OnMouseUp" event for the rowControl to disable the researching of the item,
        --but still enable the right click/context menu:
        --Show context menu at mouse button 2, but keep the normal OnMouseUp handler as well
        ZO_PreHookHandler(rowControl, "OnMouseUp", function(control, button, upInside, ctrlKey, altKey, shiftKey, ...)
            if settings.debug then FCOIS.debugMessage( "Clicked: " ..control:GetName() .. ", MouseButton: " .. tostring(button), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --button 1= left mouse button / 2= right mouse button

            --Right click/mouse button 2 context menu together with shift key
            --Clear all marker icons on the item
            FCOIS.checkIfClearOrRestoreAllMarkers(rowControl, shiftKey, upInside, button, true)

            --Right click/mouse button 2 context menu hook part:
            if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then
                --Was the shift key clicked and the setting to remove/readd marker icons via shift+right mouse button is enabled
                -->Checked within function FCOIS.checkIfClearOrRestoreAllMarkers above!
                --if the context menu should not be shown, because all marker icons were removed
                -- hide it now
                if shiftKey then
                    local contextMenuClearMarkesByShiftKey = FCOIS.settingsVars.settings.contextMenuClearMarkesByShiftKey
                    if contextMenuClearMarkesByShiftKey and FCOIS.preventerVars.dontShowInvContextMenu then
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
                --check each iconId and build a sorted context menu then
                for iconId = 1, numFilterIcons, 1 do
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
                            FCOcontextMenu[newOrderId].refreshPopup	= true -- Refresh the ZO_Dialog popup entries now
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
                    --Clear the menu
                    ClearMenu()
                    --Add the context menu entries now
                    for j = 1, numFilterIcons, 1 do
                        if FCOcontextMenu[j] ~= nil then
                            --FCOIS.AddMark(rowControl, markId, isEquipmentSlot, refreshPopupDialog, useSubMenu)
                            --Increase the global counter for the added context menu entries so the function FCOIS.AddMark can react on it
                            FCOIS.customMenuVars.customMenuCurrentCounter = FCOIS.customMenuVars.customMenuCurrentCounter + 1
                            FCOIS.AddMark(FCOcontextMenu[j].control, FCOcontextMenu[j].iconId, FCOcontextMenu[j].isEquip, FCOcontextMenu[j].refreshPopup, FCOcontextMenu[j].useSubMenu)
                        end
                    end
                end

            end -- if button == MOUSE_BUTTON_INDEX_RIGHT and upInside then

            --Disable the usage/research/etc. of this item
            if disableControl == true then
                --Do nothing (true tells the handler function that everything was achieved already in this function
                --and the normal "hooked" functions don't need to be run afterwards)
                -- -> All handling will be done in function MarkMe() as the dialog list will be refreshed!
                return true

            else -- if disableControl == false
                --Is the row selected?
                if ctrlVars.LIST_DIALOG.selectedControl ~= nil then
                    --Enable the "use" button again, as it will be disabled before if the item won't be usable
                    WINDOW_MANAGER:GetControlByName("ZO_ListDialog1Button1", ""):SetEnabled(true)
                end
            end -- if disableControl == true

        end) -- ZO_PreHookHandler(rowControl, "OnMouseUp"...

        -- Create/Update all the icons for the current dialog row
        for iconNumb = 1, numFilterIcons, 1 do
            FCOIS.CreateMarkerControl(rowControl, iconNumb, settings.icon[iconNumb].size or FCOIS.iconVars.gIconWidth, settings.icon[iconNumb].size or FCOIS.iconVars.gIconWidth, FCOIS.textureVars.MARKER_TEXTURES[settings.icon[iconNumb].texture])
        end -- for i = 1, numFilterIcons, 1 do

    end -- list dialog 1 pre-hook (e.g. research, repair item, enchant, charge, etc.)

    --======== INVENTORY ===========================================================
    --Pre Hook the inventory for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.BACKPACK_BAG, FCOItemSaver_OnEffectivelyShown )

    --======== CRAFTBAG ===========================================================
    --Pre Hook the craftbag for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.CRAFTBAG_BAG, FCOItemSaver_OnEffectivelyShown )
    --ONLY if the craftbag is active
    --Pre Hook the 2 menubar button's (items and crafting bag) handler at the inventory
    ZO_PreHookHandler(ctrlVars.INV_MENUBAR_BUTTON_ITEMS, "OnMouseUp", function(control, button, upInside)
        --d("inv button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastInvButton:GetName())
        if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastInvButton~=ctrlVars.INV_MENUBAR_BUTTON_ITEMS) then
            FCOIS.lastVars.gLastInvButton = ctrlVars.INV_MENUBAR_BUTTON_ITEMS
            zo_callLater(function() FCOIS.PreHookButtonHandler(LF_CRAFTBAG, LF_INVENTORY) end, 50)
        end
    end)
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

    --======== LOOT SCENE ===========================================================
    --Register a callback function for the loot scene
    --Register a callback function for the inventory scene
    LOOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[LOOT_SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        if newState == SCENE_HIDING then
            --If the inventory was shown at last and the loot panel was opened (by using a container e.g.) the
            --anti-destroy settings have to be reenabled if the loot scene closes again
            FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory = true
            --d("Don't auto reenable anti-settings in invntory!")
        end
    end)

    --======== CHARACTER ===========================================================
    --Pre Hook the character window for prevention methods
    PreHookHandler( "OnEffectivelyShown", ctrlVars.CHARACTER, FCOItemSaver_CharacterOnEffectivelyShown )

    --======== RIGHT CLICK / CONTEXT MENU ==========================================
    --Pre Hook the right click/context menu addition of items
    ZO_PreHook(ZO_InventorySlotActions, "AddSlotAction", FCOItemSaver_AddSlotAction)
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
        if settings.debug then FCOIS.debugMessage( "[FENCE_MANAGER:OnFenceClosed]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
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

    --======== BANK ================================================================
    --Pre Hook the bank withdraw panel for mouse right click function SHIFT + RMB
    PreHookHandler( "OnEffectivelyShown", ctrlVars.BANK_BAG, FCOItemSaver_OnEffectivelyShown )

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
    --Pre Hook the house bank withdraw panel for mouse right click function SHIFT + RMB
    PreHookHandler( "OnEffectivelyShown", ctrlVars.HOUSE_BANK_BAG, FCOItemSaver_OnEffectivelyShown )

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
    --Pre Hook the bank withdraw panel for mouse right click function SHIFT + RMB
    PreHookHandler( "OnEffectivelyShown",ctrlVars.GUILD_BANK_BAG, FCOItemSaver_OnEffectivelyShown )

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
    --Prehook the smithing function SetMode() which gets executed as the smithing tabs are changed
    local origSmithingSetMode = ZO_Smithing.SetMode
    ZO_Smithing.SetMode = function(smithingCtrl, mode, ...)
        local retVar = origSmithingSetMode(smithingCtrl, mode, ...)

        --Hide the context menu at last active panel
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)

        if settings.debug then FCOIS.debugMessage( "[SMITHING:SetMode] Mode: " .. tostring(mode), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        --Get the filter panel ID by crafting type (to distinguish jewelry crafting and normal)
        local craftingModeAndCraftingTypeToFilterPanelId = FCOIS.mappingVars.craftingModeAndCraftingTypeToFilterPanelId
        local craftingType = GetCraftingInteractionType()
        local filterPanelId
        --Refinement
        if mode == SMITHING_MODE_REFINMENT then
            filterPanelId = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_REFINE
            FCOIS.PreHookButtonHandler(FCOIS.gFilterWhere, filterPanelId)
        --Creation
        --elseif mode == SMITHING_MODE_CREATION then
        --	FCOIS.gFilterWhere = LF_SMITHING_CREATION
        --Deconstruction
        elseif mode == SMITHING_MODE_DECONSTRUCTION then
            filterPanelId = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_DECONSTRUCT
            FCOIS.PreHookButtonHandler(FCOIS.gFilterWhere, filterPanelId)
        --Improvement
        elseif mode == SMITHING_MODE_IMPROVEMENT then
            filterPanelId = craftingModeAndCraftingTypeToFilterPanelId[mode][craftingType] or LF_SMITHING_IMPROVEMENT
            FCOIS.PreHookButtonHandler(FCOIS.gFilterWhere, filterPanelId)
        --Research
        --elseif mode == SMITHING_MODE_RESEARCH then
            --FCOIS.PreHookButtonHandler(FCOIS.gFilterWhere, LF_SMITHING_RESEARCH)
        end

        --d("[FCOIS]smithingSetMode- mode: " ..tostring(mode) .. ", craftType: " ..tostring(craftingType) .. ", filterPanelId: " ..tostring(filterPanelId) .. ", filterWhere: " ..tostring(FCOIS.gFilterWhere))

        --Go on with original function
        return retVar
    end

    --======== ENCHANTING ==========================================================
    --Prehook the enchanting function SetEnchantingMode() which gets executed as the enchanting tabs are changed
    local origEnchantingSetEnchantMode = ZO_Enchanting.SetEnchantingMode
    ZO_Enchanting.SetEnchantingMode = function(enchantingCtrl, enchantingMode, ...)
        local retVar = origEnchantingSetEnchantMode(enchantingCtrl, enchantingMode, ...)

        --Hide the context menu at last active panel
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)

        if settings.debug then FCOIS.debugMessage( "[ENCHANTING:SetEnchantingMode] EnchantingMode: " .. tostring(enchantingMode), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --[[ enchantingMode could be:
            ENCHANTING_MODE_CREATION
            ENCHANTING_MODE_EXTRACTION
        ]]
        --Creation
        if     enchantingMode == ENCHANTING_MODE_CREATION then
            FCOIS.PreHookButtonHandler(LF_ENCHANTING_EXTRACTION, LF_ENCHANTING_CREATION)
            --zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.ENCHANTING_STATION_BAG) end, 100)
            --Extraction
        elseif enchantingMode == ENCHANTING_MODE_EXTRACTION then
            FCOIS.PreHookButtonHandler(LF_ENCHANTING_CREATION, LF_ENCHANTING_EXTRACTION)
            --zo_callLater(function() FCOItemSaver_OnEffectivelyShown(ctrlVars.ENCHANTING_STATION_BAG) end, 100)
        end
        --Go on with original function
        return retVar
    end

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
    CRAFT_BAG_FRAGMENT:RegisterCallback("StateChange", function(oldState, newState)
        --[[ possible states are:
            SCENE_FRAGMENT_SHOWN = "shown"
            SCENE_FRAGMENT_HIDDEN = "hidden"
            SCENE_FRAGMENT_SHOWING = "showing"
            SCENE_FRAGMENT_HIDING = "hiding"
        ]]--

        --d("[FCOIS] CraftBag Fragment state change")
        --Hide the context menu at the active panel
        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        if 	newState == SCENE_FRAGMENT_SHOWING then
            if settings.debug then FCOIS.debugMessage( "Callback fragment CRAFTBAG: Showing", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Reset the parent panel ID
            FCOIS.gFilterWhereParent = nil

            --Check the filter buttons and create them if they are not there
            FCOIS.CheckFilterButtonsAtPanel(true, LF_CRAFTBAG, LF_CRAFTBAG) --overwrite with LF_CRAFTBAG so it'll create and update the buttons for the craftbag panel, and not the CBE subpanels (mail, trade, bank, guild bank, etc.)

            --Update the inventory context menu ("flag" icon) so it uses the correct "anti-settings" and the correct colour and right-click callback function
            --depending on the currently shown craftbag "parent" (inventory, mail send, guild bank, guild store)
            local currentPanel, parentPanel = FCOIS.checkActivePanel(FCOIS.gFilterWhere, LF_CRAFTBAG)
            if settings.debug then FCOIS.debugMessage( ">Parent panel: " .. tostring(parentPanel), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
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
                    if settings.debug then FCOIS.debugMessage( ">supported craftbag parent panel: " .. tostring(FCOIS.gFilterWhereParent), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
                end
            end
            --Change the additional context-menu button's color in the inventory (Craft Bag button)
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_CRAFTBAG)

            --				elseif 	newState == SCENE_FRAGMENT_SHOWN then
            --	d("Callback fragment CRAFTBAG: Shown")

            --				elseif 	newState == SCENE_FRAGMENT_HIDING then
            --	d("Callback fragment CRAFTBAG: Hiding")

--------------------------------------------------------------------------------------------------------------------
        elseif  newState == SCENE_FRAGMENT_HIDDEN then
            if settings.debug then FCOIS.debugMessage( "Callback fragment CRAFTBAG: Hidden", true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Reset the CraftBag filter parent panel ID
            FCOIS.gFilterWhereParent = nil
            --Hide the context menu at last active panel
            FCOIS.hideContextMenu(LF_CRAFTBAG)
            --Get the new active filter panel ID -> FCOIS.gFilterWhere
            FCOIS.checkActivePanel(FCOIS.gFilterWhere)
            if settings.debug then FCOIS.debugMessage( ">new panel: " .. tostring(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
            --Check the filter buttons and create them if they are not there
            --FCOIS.CheckFilterButtonsAtPanel(true, FCOIS.gFilterWhere)
            --Change the additional context-menu button's color in the inventory (new active filter panel ID)
            FCOIS.changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
        end
    end)

    --======== MAIL INBOX ================================================================
    --Register a callback function for the mail inbox scene
    MAIL_INBOX_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[MAIL_INBOX_SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== MAIL SEND ================================================================
    --Register a callback function for the mail send scene
    MAIL_SEND_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[MAIL_SEND_SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

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

    --======== QUEST JOURNAL ================================================================
    --Register a callback function for the quest journal scene
    QUEST_JOURNAL_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[QUEST JOURNAL SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== GROUP LIST ================================================================
    --Register a callback function for the group list scene
    local groupScene = KEYBOARD_GROUP_MENU_SCENE
    groupScene:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[KEYBOARD_GROUP_MENU_SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== LORE LIBRARY ================================================================
    --Register a callback function for the lore library scene
    LORE_LIBRARY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[LORE LIBRARY SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== LORE READER INVENTORY ================================================================
    --Register a callback function for the lore reader inventory scene
    LORE_READER_INVENTORY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[LORE READER INVENTORY SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== LORE READER LORE LIBRARY ================================================================
    --Register a callback function for the lore library scene
    LORE_READER_LORE_LIBRARY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[LORE READER LORE LIBRARY SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== LORE READER INTERACTION ================================================================
    --Register a callback function for the lore reader interaction scene
    LORE_READER_INTERACTION_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[LORE READER INTERACTION SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)
    end)

    --======== TREASURE MAP INVENTORY ================================================================
    --Register a callback function for the treasure map inventory scene
    TREASURE_MAP_INVENTORY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[TREASURE MAP INVENTORY SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)
    end)

    --======== TREASURE MAP QUICK SLOT ================================================================
    --Register a callback function for the treasure map quick slot scene
    TREASURE_MAP_QUICK_SLOT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[TREASURE MAP QUICK SLOT SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)
    end)

    --======== GAME MENU ================================================================
    --Register a callback function for the game menu scene
    GAME_MENU_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[GAME MENU SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== LEADERBOARD ================================================================
    --Register a callback function for the leaderboard scene
    LEADERBOARDS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[LEADERBOARDS SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== WORLD MAP ================================================================
    --Register a callback function for the wolrd map scene
    WORLD_MAP_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[WORLD MAP SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== HELP CUSTOMER SUPPORT ================================================================
    --Register a callback function for the help customer support scene
    HELP_CUSTOMER_SUPPORT_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[HELP CUSTOMER SUPPORT SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== FRIENDS LIST ================================================================
    --Register a callback function for the friends list scene
    FRIENDS_LIST_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[FRIENDS LIST SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== IGNORE LIST ================================================================
    --Register a callback function for the ignore list scene
    IGNORE_LIST_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[IGNORE LIST SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== GUILD HOME ================================================================
    --Register a callback function for the guild home scene
    GUILD_HOME_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[GUILD HOME SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)
    end)

    --======== GUILD ROSTER ================================================================
    --Register a callback function for the guild roster scene
    GUILD_ROSTER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[GUILD ROSTER SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== GUILD RANKS ================================================================
    --Register a callback function for the guild ranks scene
    GUILD_RANKS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[GUILD RANKS SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== GUILD HERALDRY ================================================================
    --Register a callback function for the guild heraldry scene
    GUILD_HERALDRY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[GUILD HERALDRY SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== GUILD HISTORY ================================================================
    --Register a callback function for the guild history scene
    GUILD_HISTORY_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[GUILD HISTORY SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== GUILD CREATE ================================================================
    --Register a callback function for the guild create scene
    GUILD_CREATE_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[GUILD CREATE SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== NOTIFICATIONS ================================================================
    --Register a callback function for the notifications scene
    NOTIFICATIONS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[NOTIFICATIONS SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== CAMPAIGN BROWSER ================================================================
    --Register a callback function for the campaign browser scene
    CAMPAIGN_BROWSER_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[CAMPAIGN BROWSER SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== CAMPAIGN OVERVIEW ================================================================
    --Register a callback function for the campaign overview scene
    CAMPAIGN_OVERVIEW_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[CAMPAIGN OVERVIEW SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== STATS ================================================================
    --Register a callback function for the stats scene
    STATS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[STATS SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)
    end)

    --======== SIEGE BAR ================================================================
    --Register a callback function for the siege bar scene
    SIEGE_BAR_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[SIEGE BAR SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== CHAMPION PERKS ===========================================================
    CHAMPION_PERKS_SCENE:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[CHAMPION PERKS SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        FCOIS.sceneCallbackHideContextMenu(oldState, newState)

        --If the inventory was shown at last and the mail panel was opened directly with shown inventory the settings for the anti-destroy won't be updted!
        --So do this here now:
        FCOIS.resetInventoryAntiSettings(newState)
    end)

    --======== RETRAIT ================================================================
    --Register a callback function for the siege bar scene
    ZO_RETRAIT_STATION_KEYBOARD.interactScene:RegisterCallback("StateChange", function(oldState, newState)
        if settings.debug then FCOIS.debugMessage( "[RETRAIT SCENE] State: " .. tostring(newState), true, FCOIS_DEBUG_DEPTH_NORMAL) end
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
    ZO_PreHook(SMITHING.improvementPanel, "Improve", function()
        return FCOIS.craftingPrevention.CheckPreventCrafting()
    end)

    --======== TEST HOOKS =============================================================================
    --Call some test hooks
    --callTestHooks(settings.testHooks)

end  -- function CreateHooks()
--============================================================================================================================================================
--===== HOOKS END ============================================================================================================================================
--============================================================================================================================================================
