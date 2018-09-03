--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local ctrlVars = FCOIS.ZOControlVars
--==========================================================================================================================================
--													FCOIS EVENT callback functions
--==========================================================================================================================================

--==============================================================================
--==================== START EVENT CALLBACK FUNCTIONS ==========================
--==============================================================================

--Event callback function if a retrait station is opened
local function FCOItemsaver_RetraitStationInteract(event)
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Retrait station interact", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    FCOIS.gFilterWhere = LF_RETRAIT
end

--Event callback function if a guild bank was swapped
local function FCOItemsaver_SelectGuildBank(_, guildBankId)
    --Store the current guild Id
    FCOIS.guildBankVars.guildBankId = guildBankId
end

--Event upon closing of a crafting station
local function FCOItemSaver_End_Crafting_Interact()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] End crafting", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if FCOIS.preventerVars.gNoCloseEvent == false then
        --Update the inventory filter buttons
        FCOIS.updateFilterButtonsInInv(-1)
        --Update the 4 inventory button's color
        FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
    end
    FCOIS.preventerVars.gNoCloseEvent      = false
    FCOIS.preventerVars.gActiveFilterPanel = false

    --Check if the Anti-* functions need to be enabled again
    FCOIS.autoReenableAntiSettingsCheck("CRAFTING_STATION")
end

--Event upon opening of a vendor store
local function FCOItemSaver_Open_Store(p_storeIndicator)
    FCOIS.preventerVars.gActiveFilterPanel = true

    p_storeIndicator = p_storeIndicator or "vendor"
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Open store: " .. p_storeIndicator, true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    if p_storeIndicator == "vendor" then
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_VENDOR_SELL)
        FCOIS.CheckFilterButtonsAtPanel(true, LF_VENDOR_SELL)
    end
end

--Event upon closing of a vendor store
local function FCOItemSaver_Close_Store()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Close store", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if FCOIS.preventerVars.gNoCloseEvent == false then
        --Update the inventory filter buttons
        FCOIS.updateFilterButtonsInInv(-1)
        --Update the 4 inventory button's color
        FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
    end
    FCOIS.preventerVars.gNoCloseEvent 	 = false
    FCOIS.preventerVars.gActiveFilterPanel = false

    --Check, if the Anti-* checks need to be enabled again
    FCOIS.autoReenableAntiSettingsCheck("STORE")
end

--Event upon opening of a guild store
local function FCOItemSaver_Open_Trading_House()
    FCOIS.preventerVars.gActiveFilterPanel = true
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Open trading house", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Change the button color of the context menu invoker
    FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_GUILDSTORE_SELL)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    FCOIS.CheckFilterButtonsAtPanel(true, LF_GUILDSTORE_SELL)

    --======== GUILD STORE SEARCH ==============================================
    local function PreHookGuildStoreSearchButtonOnMouseUp()
        --Update the ZOs control vars for FCOIS
        ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH = ZO_TradingHouseMenuBarButton1
        FCOIS.lastVars.gLastGuildStoreButton				  = ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH
        ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SELL   = ZO_TradingHouseMenuBarButton2
        ctrlVars.GUILD_STORE_MENUBAR_BUTTON_LIST   = ZO_TradingHouseMenuBarButton3

        if ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH ~= nil then
            --Pre Hook the 2 menubar button's (search and sell) at the guild store
            ZO_PreHookHandler(ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH, "OnMouseUp", function(_, button, upInside)
                --d("guild store button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastGuildStoreButton:GetName())
                --if (button == 1 and upInside and FCOIS.lastVars.gLastGuildStoreButton~=ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH) then
                if button == 1 and upInside then
                    --FCOIS.lastVars.gLastGuildStoreButton = ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH
                    --Close the contextMenu at the guild store sell window now
                    FCOIS.hideContextMenu(LF_GUILDSTORE_SELL)
                end
            end)
        end
    end
    --Check as long until the control "ZO_TradingHouseMenuBarButton1" exists, and then call the function in the 2nd parameter
    FCOIS.checkRepetivelyIfControlExists(ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH_NAME, PreHookGuildStoreSearchButtonOnMouseUp, 100, 10000)
end

--Event upon closing of a guild store
local function FCOItemSaver_Close_Trading_House()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Close trading house", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if FCOIS.preventerVars.gNoCloseEvent == false then
        --Update the inventory filter buttons
        FCOIS.updateFilterButtonsInInv(-1)
        --Update the 4 inventory button's color
        FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
    end
    FCOIS.preventerVars.gNoCloseEvent 	 = false
    FCOIS.preventerVars.gActiveFilterPanel = false

    --Check, if the Anti-* checks need to be enabled again
    FCOIS.autoReenableAntiSettingsCheck("GUILD_STORE")
end

--Event upon opening of a guild bank
local function FCOItemSaver_Open_Guild_Bank()
    FCOIS.preventerVars.gActiveFilterPanel = true
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Open guild bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Reset the last clicked guild bank button as it will always be the withdraw tab if you open the guild bank, and if the
    --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
    FCOIS.lastVars.gLastGuildBankButton = ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW

    --Change the button color of the context menu invoker
    FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_GUILDBANK_WITHDRAW)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    FCOIS.CheckFilterButtonsAtPanel(true, LF_GUILDBANK_WITHDRAW)
end

--Event upon closing of a guild bank
local function FCOItemSaver_Close_Guild_Bank()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Close guild bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if FCOIS.preventerVars.gNoCloseEvent == false then
        --Update the inventory filter buttons
        FCOIS.updateFilterButtonsInInv(-1)
        --Update the 4 inventory button's color
        FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
    end
    FCOIS.preventerVars.gNoCloseEvent 	 = false
    FCOIS.preventerVars.gActiveFilterPanel = false

    --Check, if the Anti-* checks need to be enabled again
    FCOIS.autoReenableAntiSettingsCheck("DESTROY")
end

--Event upon opening of a player bank
local function FCOItemSaver_Open_Player_Bank(event, bagId)
    local isHouseBank = IsHouseBankBag(bagId) or false
    FCOIS.preventerVars.gActiveFilterPanel = true
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Open bank - bagId: " .. tostring(bagId) .. ", isHouseBank: " .. tostring(isHouseBank), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    local filterPanelId = LF_BANK_WITHDRAW
    if isHouseBank then
        --Reset the last clicked bank button as it will always be the withdraw tab if you open the bank, and if the
        --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
        FCOIS.lastVars.gLastHouseBankButton = ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW
        filterPanelId = LF_HOUSE_BANK_WITHDRAW
        --Scan the house bank for non marked items, or items that need to be transfered from ZOs marker icons to FCOIS marker icons
        zo_callLater(function()
            --Scan for items that are locked by ZOs and should be transfered to FCOIS
            FCOIS.scanInventoriesForZOsLockedItems(false, bagId)
            --Scan if house bank got items that should be marked automatically
            FCOIS.scanInventory(bagId, nil)
        end, 250)
    else
        --Reset the last clicked bank button as it will always be the withdraw tab if you open the bank, and if the
        --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
        FCOIS.lastVars.gLastBankButton = ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW
        filterPanelId = LF_BANK_WITHDRAW
    end
    --Change the button color of the context menu invoker
    FCOIS.changeContextMenuInvokerButtonColorByPanelId(filterPanelId)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    FCOIS.CheckFilterButtonsAtPanel(true, filterPanelId)
end

--Event upon closing of a player bank
local function FCOItemSaver_Close_Player_Bank()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Close bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if FCOIS.preventerVars.gNoCloseEvent == false then
        --Update the inventory filter buttons
        FCOIS.updateFilterButtonsInInv(-1)
        --Update the 4 inventory button's color
        FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
    end
    FCOIS.preventerVars.gNoCloseEvent 	 = false
    FCOIS.preventerVars.gActiveFilterPanel = false

    --Check, if the Anti-* checks need to be enabled again
    FCOIS.autoReenableAntiSettingsCheck("DESTROY")
end

--Event upon opening of the trade panel
local function FCOItemSaver_Open_Trade_Panel()
    FCOIS.preventerVars.gActiveFilterPanel = true
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Start trading", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Change the button color of the context menu invoker
    FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_TRADE)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    FCOIS.CheckFilterButtonsAtPanel(true, LF_TRADE)
end

--Event upon closing of the trade panel
local function FCOItemSaver_Close_Trade_Panel()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] End trading", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if FCOIS.preventerVars.gNoCloseEvent == false then
        --Update the inventory filter buttons
        FCOIS.updateFilterButtonsInInv(-1)
        --Update the 4 inventory button's color
        FCOIS.UpdateButtonColorsAndTextures(-1, nil, -1, LF_INVENTORY)
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
    end
    FCOIS.preventerVars.gNoCloseEvent 	 = false
    FCOIS.preventerVars.gActiveFilterPanel = false

    --Check, if the Anti-* checks need to be enabled again
    FCOIS.autoReenableAntiSettingsCheck("TRADE")
end

--[[
--event handler for ACTION LAYER POPPED
local function FCOItemsaver_OnActionLayerPopped(layerIndex, activeLayerIndex)
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Action layer popped] LayerIndex: " .. tostring(layerIndex) .. ", ActiveLayerIndex: " .. tostring(activeLayerIndex), false) end
    --ActiveLayerIndex = 3 will be opened in most cases
    if activeLayerIndex == 3 then
        --Hide the context menu at last active panel
        --TODO 2016-08-06 Validate that the action layer is 3 and not 2 anymore, and see if the context menu closing cannot be forced elsewhere properly
        --FCOIS.hideContextMenu(FCOIS.gFilterWhere)
    end
end
]]

--event handler for GAME_CAMERA_UI_MODE_CHANGED
local function FCOItemsaver_OnGameCameraUIModeChanged()
    if not IsGameCameraUIModeActive() then
        --d("[FCOIS] GAME_CAMERA_UI_MODE_CHANGED")
        --Hide the contxt menu if still open
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)
    end
end

--event handler for EVENT_CRAFT_STARTED
local function FCOItemSaver_Craft_Started(_, craftSkill)
--d("[FCOIS] EVENT CraftStarted - craftSkill: " .. tostring(craftSkill))
    --Check if new crafted item should be marked with the "crafted" marker icon
    FCOIS.checkIfCraftedItemShouldBeMarked(craftSkill)
    --Check if item get's improved and if the marker icons from before improvement should be remembered
    FCOIS.checkIfImprovedItemShouldBeReMarked_BeforeImprovement()
end

--event handler for EVENT_CRAFT_COMPLETED
local function FCOItemSaver_Craft_Completed()
--d("[FCOIS] EVENT CraftCompleted - newItemCrafted: " .. tostring(FCOIS.preventerVars.newItemCrafted))
    --Reset the variable to know if an item is getting into our bag after crafting complete
    FCOIS.preventerVars.newItemCrafted = false
    FCOIS.preventerVars.createdMasterWrit = nil
    FCOIS.preventerVars.writCreatorCreatedItem  = false
    --Check if item got improved and if the marker icons from before improvement should be re-marked on the improved item
    FCOIS.checkIfImprovedItemShouldBeReMarked_AfterImprovement()
end

--Event upon opening of a crafting station
local function FCOItemSaver_Crafting_Interact(_, craftSkill)
    FCOIS.preventerVars.gActiveFilterPanel = true
    --EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOItemSaver_End_Crafting_Interact)

    --Abort if crafting station type is invalid
    if craftSkill == 0 then return end
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Crafting Interact: Craft skill: ".. tostring(craftSkill), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --ALCHEMY
    if craftSkill == CRAFTING_TYPE_ALCHEMY then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[ALCHEMY Crafting station opened]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Hide the context menu at last active panel
        FCOIS.hideContextMenu(FCOIS.gFilterWhere)

        --If the addon PotionMaker is activated and got it's own Alchemy button activated too
        if FCOIS.otherAddons.potionMakerActive then
            --d("PotionMaker active and button exists -> Resetting last clicked button now")
            --Reset the variable for the last pressed button
            FCOIS.lastVars.gLastAlchemyButton = ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_POTIONMAKER
        end
        --Show the filter buttons at the alchemy station
        FCOIS.PreHookButtonHandler(nil, LF_ALCHEMY_CREATION)

    else
        --d("[FCOItemSaver_Crafting_Interact] FCOIS.gFilterWhere: " .. FCOIS.gFilterWhere)
        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
    end
end

local updateSetTrackerMarker = FCOIS.otherAddons.SetTracker.updateSetTrackerMarker
local scanInventory = FCOIS.scanInventory
--Inventory slot gets updated function
local function FCOItemSaver_Inv_Single_Slot_Update(_, bagId, slotId, isNewItem, itemSoundCategory, updateReason)
    --Do not mark or scan inventory if writcreater addon is crafting items
    if FCOIS.preventerVars.writCreatorCreatedItem then return false end
    local settings = FCOIS.settingsVars.settings
    --Scan new items in the player inventory and add markers OR update equipped/unequipped item markers
--d("[FCOItemSaver_Inv_Single_Slot_Update] bagId: " .. bagId .. ", slot: " .. slotId..", isNewItem: " .. tostring(isNewItem)..", updateReason: " .. tostring(updateReason) .. ", FCOIS.newItemCrafted: " .. tostring(FCOIS.preventerVars.newItemCrafted))
    -- ===== Do some abort checks first =====
    --Mark new crafted item with the lock (or the chosen) icon?
    if FCOIS.preventerVars.newItemCrafted and bagId ~= nil and slotId ~= nil and isNewItem then
        FCOIS.preventerVars.newItemCrafted = false
        local writOrNonWritMarkUponCreation, craftMarkerIcon = FCOIS.isWritOrNonWritItemCraftedAndIsAllowedToBeMarked()
        if writOrNonWritMarkUponCreation and craftMarkerIcon ~= nil then
            --local itemLink = GetItemLink(bagId, slotId)
--d("[FCOIS]FCOItemSaver_Inv_Single_Slot_Update: New crafted item: " .. itemLink .. ", isWritAddonCreatedItem: " ..tostring(isWritAddonCreatedItem) .. ", markerIcon: " .. tostring(craftMarkerIcon))
            --Check slightly delayed if the crafted item should be marked
            zo_callLater(function()
                local markNow = true
                local isSetPart = FCOIS.isItemSetPartNoControl(bagId, slotId)
                --Only mark crafted set parts?
                if settings.autoMarkCraftedItemsSets then
                    --Only do this if not already set parts, which get "new" into your inventory, will get marked automatically
                    if isSetPart and settings.autoMarkSets then
                        markNow = false
                    end
                    markNow = isSetPart
                end
--d("[FCOIS]FCOItemSaver_Inv_Single_Slot_Update: New crafted item: " .. itemLink .. ", markerIcon: " .. tostring(craftMarkerIcon) .. ", isSetPart: " ..tostring(isSetPart) .. ", onlyMarkCraftedSets: " ..tostring(settings.autoMarkCraftedItemsSets) .. ", markNow: " ..tostring(markNow))

                --Mark item now?
                if markNow then
--d(">Mark item " ..itemLink .. " with icon: " .. tostring(craftMarkerIcon))
                    FCOIS.MarkItem(bagId, slotId, craftMarkerIcon, true, true)
                    --Prevent additional checks of the new crafted item
                    return false
                end
            end, 500) -- zo_callLater(function()
        end
    end

--d(">1")
    --ignore durability/dye update
    if updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT then return end
--d(">2")
    --Abort here if we are arrested by a guard (thief system) as it will scan our inventory for stolen items and destroy them.
    --We don't need to scan it with our functions too at this case
    if IsUnderArrest() then return end
    --Do not execute if horse is changed
    if SCENE_MANAGER:GetCurrentScene() == STABLES_SCENE then return end
    --Check if item in slot is still there
    if GetItemType(bagId, slotId) == ITEMTYPE_NONE then return end
--d(">3")

    --All bags except the equipment
    if bagId ~= BAG_WORN then
        --Abort if not new item is added to inventory
        if (not isNewItem) then return end
--d(">4")

        --Support for Roomba
        if Roomba and Roomba.WorkInProgress and Roomba.WorkInProgress() then return end

        --Only check for normal player inventory
        if (bagId == BAG_BACKPACK) then
            if settings.debug then
                FCOIS.debugMessage( "==============", true, FCOIS_DEBUG_DEPTH_NORMAL)
                FCOIS.debugMessage( "Event 'Single inventory slot updated' raised! NewItem=" .. tostring(isNewItem) .. ", bagId=" .. bagId .. ", slotIndex=" .. slotId .. ", updateReason=" .. tostring(updateReason), true, FCOIS_DEBUG_DEPTH_NORMAL)
            end
            --if(FCOIS.preventerVars.canUpdateInv == true) then
            --FCOIS.preventerVars.canUpdateInv = false
            zo_callLater(function()
                if settings.debug then FCOIS.debugMessage( "Event 'Single inventory slot updated' executed now! bagId=" .. bagId .. ", slotIndex=" .. slotId, true, FCOIS_DEBUG_DEPTH_NORMAL) end
                --Scan the inventory item for automatic marker icons which should be set
                FCOIS.preventerVars.eventInventorySingleSlotUpdate = true
                scanInventory(bagId, slotId)
                FCOIS.preventerVars.eventInventorySingleSlotUpdate = false

                -- ========================== SET TRACKER ===========================================================================================================================
                if SetTrack ~= nil and SetTrack.GetTrackingInfo ~= nil and FCOIS.otherAddons.SetTracker.isActive and settings.autoMarkSetTrackerSets then
                    --d("[FCOItemSaver_Inv_Single_Slot_Update] SetTracker checks")
                    --Check if item is a set part and update the marker icon if it's tracked with the addon "SetTracker"
                    --Returns SetTracker data for the specified bag item as follows
                    --iTrackIndex - track state index 0 - 14, -1 means the set is not tracked and 100 means the set is crafted
                    --sTrackName - the user configured tracking name for the set
                    --sTrackColour - the user configured colour for the set ("RRGGBB")
                    --sTrackNotes - the user notes saved for the set
                    local setTrackerState = SetTrack.GetTrackingInfo(bagId, slotId)				-- get SetTracker info about the current item at bagId, slotIndex
                    local doShow = true 														-- show the SetTracker icon on that new item
                    local doUpdateInv = true 													-- update the inventory if needed
                    local calledFromFCOISEventSingleSlotInvUpdate = true 						-- yes, the function gets called from that actualy EVENT callback function
                    updateSetTrackerMarker(bagId, slotId, setTrackerState, doShow, doUpdateInv, calledFromFCOISEventSingleSlotInvUpdate)
                end

                --New item
                local settingsAutoMarkNewItems = (settings.autoMarkNewItems and settings.isIconEnabled[settings.autoMarkNewIconNr]) or false
                if settingsAutoMarkNewItems == true then
                    --New item should be marked with a FCOIS marker icon now
                    FCOIS.MarkItem(bagId, slotId, settings.autoMarkNewIconNr, true, false)
                end
            end, 250)
            --FCOIS.preventerVars.canUpdateInv = true
            --end
        end

    --Equipment bag:  BAG_WORN (character equipment)
    else
        if slotId ~= nil then
            --Update the equipment slot control's markers
            FCOIS.updateEquipmentSlotMarker(slotId, 50)
        end
    end
end


-- handler function for EVENT_INVENTORY_SLOT_UNLOCKED global event
-- will be fired (after EVENT_INVENTORY_SLOT_LOCKED) if you have pickuped an item (e.g. by drag&drop) and drop it again
local function FCOItemSaver_OnInventorySlotUnLocked(self, bag, slot)
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Event] OnInventorySlotUnLocked: bag: " .. tostring(bag) .. ", slot: " .. tostring(slot), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    if bag == BAG_WORN and FCOIS.preventerVars.gItemSlotIsLocked == true then
        --If item was unequipped: Remove the armor type marker if necessary
        FCOIS.removeArmorTypeMarker(bag, slot)

        --Check all weapon slots and remove empty markers
        FCOIS.RemoveEmptyWeaponEquipmentMarkers(1200)
    end
    FCOIS.preventerVars.gItemSlotIsLocked = false
    --Reset: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
    FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
end

-- handler function for EVENT_INVENTORY_SLOT_LOCKED global event
-- will be fired (before EVENT_CURSOR_PICKUP) if you pickup an item (e.g. by drag&drop)
local function FCOItemSaver_OnInventorySlotLocked(self, bag, slot)
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Event] OnInventorySlotLocked: bag: " .. tostring(bag) .. ", slot: " .. tostring(slot), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    FCOIS.preventerVars.gItemSlotIsLocked = true
    --Set: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
    FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = true

    --Deconstruction at crafting station?
    if(not ctrlVars.DECONSTRUCTION_BAG:IsHidden() ) then
        -- check if deconstruction is forbidden
        -- if so, clear item hold by cursor
        if( FCOIS.callDeconstructionSelectionHandler(bag, slot, true) ) then
            --Remove the picked item from drag&drop cursor
            ClearCursor()
            return false
        end

    --Picked up an item at another station, for bind, destroy, refine, improve, etc.?
    else
        local doShowItemBindDialog = false -- Always false since API 100019 where ZOs included it's "ask before bind to account" dialog
        -- check if destroying, improvement, sending or trading is forbidden
        -- and check if item is bindable (above)
        -- if so, clear item hold by cursor
        --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
        if( doShowItemBindDialog or FCOIS.callItemSelectionHandler(bag, slot, true, true, false, false, false, false, false) ) then
            --Remove the picked item from drag&drop cursor
            ClearCursor()
            return false
        else
            return false
        end
    end
    --Reset: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
    FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
end

--Executed if item should be destroyed manually
local function FCOItemSaver_OnMouseRequestDestroyItem(eventCode, bagId, slotIndex, itemCount, name, needsConfirm)
    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if not needsConfirm then
        --Only react if anti destroy setting is enabled
        if (not FCOIS.settingsVars.settings.blockDestroying) then
            FCOIS.preventerVars.gAllowDestroyItem = true
            return nil
        end

        FCOIS.preventerVars.gAllowDestroyItem = false

        if( bagId and slotIndex ) then
            FCOIS.preventerVars.gAllowDestroyItem = not FCOIS.DestroySelectionHandler(bagId, slotIndex, true)
            --Hide the "YES" button of the destroy dialog and disable keybind
            FCOIS.overrideDialogYesButton(ZO_Dialog1)
        end
    end
end

--==============================================================================
--===================== END EVENT CALLBACK FUNCTIONS============================
--==============================================================================


--==============================================================================
--   ================== BEGIN AddOn's EVENT CALLBACK FUNCTIONS ==============
--==============================================================================
-- =====================================================================================================================
--  Player activated functions
-- =====================================================================================================================

--Function to check if something should be done at Player Activated event (e.g. mark items in inventories etc.)
function FCOIS.checkForPlayerActivatedTasks()
    --Set Tracker item marking - Scan inventories on login/reloadui?
    local otherAddons = FCOIS.otherAddons
    local settings = FCOIS.settingsVars.settings
    if settings.autoMarkSetTrackerSetsRescan and otherAddons.SetTracker.isActive
            and SetTrack ~= nil and SetTrack.GetTrackingInfo ~= nil and SetTrack.GetTrackStateInfo ~= nil
            and settings.autoMarkSetTrackerSets then
        --d("[FCOIS.checkForPlayerActivatedTasks - Rescan for SetTracker set parts")
        otherAddons.SetTracker.checkAllItemsForSetTrackerTrackingState()
    end

    --Was the item ID type changed to unique IDs: Show the migrate data from old item IDs to unique itemIDs now
    if FCOIS.preventerVars.migrateItemMarkers then
        FCOIS.ShowAskBeforeMigrateDialog()
    end

--TODO: Not working as event_player_activated doesn't get fired after a port to a house...
--[[
    --Added with FCOIS version 1.2.1 -> Backup & restore of marker icons depending on unique item IDs
    -->BACKUP: After a jump to the house we need to start the backup now including the house banks.
    -->Check if we ported to a house:
    if settings.doBackupAfterJumpToHouse then
        local preVars = FCOIS.preChatVars
        zo_callLater(function()
            d(preVars.preChatTextGreen .. "--- Backup after jump to house is activated ---\n\n")
            --get the backup params if specified
            local backupType = "unique"
            local withDetails = false
            local apiVersion = FCOIS.APIversion or GetAPIVersion()
            local doClearBackup = false
            local backupParams = FCOIS.settingsVars.settings.backupParams
            if backupParams ~= nil then
                backupType      = backupParams.backupType
                withDetails     = backupParams.withDetails
                apiVersion      = backupParams.apiVersion
                doClearBackup   = backupParams.doClearBackup
            end
            --Call the preBackup function to check if owning a house and if inside a house now, then start the backup (port to house is not done automatically from here anymore to prevent endless ports!)
            --Show confirmation dialog
            local locVars = FCOIS.localizationVars.fcois_loc
            local title = locVars["options_backup_marker_icons"] .. " - API " .. tostring(apiVersion)
            local body = locVars["options_backup_marker_icons_warning"]
            FCOIS.ShowConfirmationDialog("BackupMarkerIconsDialog", title, body, function() FCOIS.preBackup(backupType, withDetails, apiVersion, doClearBackup) end)
            --Reset the variables again
            FCOIS.settingsVars.settings.doBackupAfterJumpToHouse = false
        end, 1000)
    end
]]
end

-- Fires each time after addons were loaded and player is ready to move (after each zone change too)
local function FCOItemSaver_Player_Activated(...)
--d("[FCOIS]EVENT_PLAYER_ACTIVATED")
    --Prevent this event to be fired again and again upon each zone change
    EVENT_MANAGER:UnregisterForEvent(FCOIS.addonVars.gAddonName, EVENT_PLAYER_ACTIVATED)

    --Disable this addon if we are in GamePad mode
    if not FCOIS.FCOItemSaver_CheckGamePadMode() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT] Player activated", true, FCOIS_DEBUG_DEPTH_NORMAL) end

        --Check if other Addons active now, as the addons should all have been loaded
        FCOIS.CheckIfOtherAddonsActiveAfterPlayerActivated()

        --Add/update the filter buttons, but only if not done already in addon initialization
        if FCOIS.addonVars.gAddonLoaded == false then
            FCOIS.updateFilterButtonsInInv(-1)
        end
        FCOIS.addonVars.gAddonLoaded = false

        --Rebuild the gear set variables like the mapping tables for the filter buttons, etc.
        --Must be called once before FCOIS.changeContextMenuEntryTexts(-1) to build the mapping tables + settings.iconIsGear!
        FCOIS.rebuildGearSetBaseVars(nil, nil)

        --Overwrite the localized texts for the equipment gears, if changed in the settings
        FCOIS.changeContextMenuEntryTexts(-1)

        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)

        --Check inventory for ornate, intricate, set parts, recipes, researchable items and mark them
        --but only scan once as addon loads
        if FCOIS.preventerVars.gAddonStartupInProgress then
            FCOIS.preventerVars.gAddonStartupInProgress = false
            FCOIS.scanInventory()
        end

        FCOIS.addonVars.gPlayerActivated = true

        --Check if something should be done at player activated event
        FCOIS.checkForPlayerActivatedTasks()
    end
end

--Addon is now loading and building up
local function FCOItemSaver_Loaded(eventCode, addOnName)
    --Check if another addon name is found and thus active
    FCOIS.checkIfOtherAddonActive(addOnName)
    --Check if gamepad mode is deactivated?
    --Is this addon found?
    if(addOnName ~= FCOIS.addonVars.gAddonName) then
        return
    end
    if FCOIS.settingsVars.settings ~= nil and FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS -Event- FCOItemSaver_Loaded]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS -Event- FCOItemSaver_Loaded]")

    if not FCOIS.FCOItemSaver_CheckGamePadMode() then
        --Unregister this event again so it isn't fired again after this addon has beend recognized
        EVENT_MANAGER:UnregisterForEvent(FCOIS.addonVars.gAddonName, EVENT_ADD_ON_LOADED)

        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Addon loading begins...]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        FCOIS.addonVars.gAddonLoaded = false

        FCOIS.preventerVars.gAddonStartupInProgress = true

        --=============================================================================================================
        --	LOAD USER SETTINGS
        --=============================================================================================================
        FCOIS.LoadUserSettings()

        -- Set Localization
        FCOIS.preventerVars.KeyBindingTexts = false
        FCOIS.Localization()

        --Build the addon settings menu
        FCOIS.BuildAddonMenu()

        --Create the icon textures
        FCOIS.CreateTextures(-1)

        --Create the hooks
        FCOIS.CreateHooks()

        --Check inventory for ornate, intricate, set parts, recipes, researchable items and mark them
--        FCOIS.scanInventory()

        --Build the inventory filter buttons and add them to the panels
        FCOIS.updateFilterButtonsInInv(-1)

        --Initialize the filters
        FCOIS.EnableFilters(-100)

        -- Register slash commands
        FCOIS.RegisterSlashCommands()

        --Add the additional buttons, controlled by the FCOIS settings
        --e.g. quick access settings button to the main menu, or the context menu invoker buttons at the inventories (flag icon)
        FCOIS.AddAdditionalButtons(-1)

        --Initialize the custom dialogs
        --Ask before bind dialog (parameter = XML dialog control)
        FCOIS.AskBeforeBindDialogInitialize(FCOISAskBeforeBindDialogXML)
        --Ask before migrate dialog (parameter = XML dialog control)
        FCOIS.AskBeforeMigrateDialogInitialize(FCOISAskBeforeMigrateDialogXML)
        --Ask before protection dialog (parameter = XML dialog control)
        FCOIS.AskProtectionDialogInitialize(FCOISAskProtectionDialogXML)

        --Check the auto reenable Anti-* settings and react on them
        FCOIS.autoReenableAntiSettingsCheck("-ALL-")

        --Set the addon loaded variable
        FCOIS.addonVars.gAddonLoaded = true

        -- Registers addon to loadedAddon library
        FCOIS.LIBLA:RegisterAddon(FCOIS.addonVars.gAddonName, FCOIS.addonVars.addonVersionOptionsNumber)

        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Addon startup finished!]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    end --gamepad active check
end

--==============================================================================
--   ================== END AddOn's EVENT CALLBACK FUNCTIONS ================
--==============================================================================

--Set the callback functions for the events that can happen
function FCOIS.setEventCallbackFunctions()
    --==================================================================================================================================================================================================
    -- EVENTs CALLBACK FUNCTIONS
    --==================================================================================================================================================================================================
    --Register the addon's loaded callback function
    EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_ADD_ON_LOADED, FCOItemSaver_Loaded)

    --Disable this addon if we are in GamePad mode
    if not FCOIS.FCOItemSaver_CheckGamePadMode() then
        --Register for the zone change/player ready event
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_PLAYER_ACTIVATED, FCOItemSaver_Player_Activated)
        --Register for Crafting stations opened & closed (integer eventCode,number craftSkill, boolean sameStation)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_CRAFTING_STATION_INTERACT, FCOItemSaver_Crafting_Interact)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOItemSaver_End_Crafting_Interact)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_CRAFT_STARTED, FCOItemSaver_Craft_Started)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_CRAFT_COMPLETED, FCOItemSaver_Craft_Completed)
        --Register for Store opened & closed
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_OPEN_STORE, function() FCOItemSaver_Open_Store("vendor") end)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_CLOSE_STORE, FCOItemSaver_Close_Store)
        --Register for Trading house (guild store) opened & closed
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_OPEN_TRADING_HOUSE, FCOItemSaver_Open_Trading_House)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_CLOSE_TRADING_HOUSE, FCOItemSaver_Close_Trading_House)
        --Register for Guild Bank opened & closed
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_OPEN_GUILD_BANK, FCOItemSaver_Open_Guild_Bank)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_CLOSE_GUILD_BANK, FCOItemSaver_Close_Guild_Bank)
        --Register for Player's Bank opened & closed
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_OPEN_BANK, FCOItemSaver_Open_Player_Bank)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_CLOSE_BANK, FCOItemSaver_Close_Player_Bank)
        --Register for Trade panel opened & closed
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_TRADE_INVITE_ACCEPTED, FCOItemSaver_Open_Trade_Panel)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_TRADE_CANCELED, FCOItemSaver_Close_Trade_Panel)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_TRADE_SUCCEEDED, FCOItemSaver_Close_Trade_Panel)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_TRADE_FAILED, FCOItemSaver_Close_Trade_Panel)
        --Register for player inventory slot update
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, FCOItemSaver_Inv_Single_Slot_Update)
        EVENT_MANAGER:AddFilterForEvent(FCOIS.addonVars.gAddonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        --Register the callback function for an update of the inventory slots
        --SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", FCOItemSaver_OnSharedSingleSlotUpdate)
        --Events for destruction & destroy prevention
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_INVENTORY_SLOT_LOCKED, FCOItemSaver_OnInventorySlotLocked)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_INVENTORY_SLOT_UNLOCKED, FCOItemSaver_OnInventorySlotUnLocked)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_MOUSE_REQUEST_DESTROY_ITEM, FCOItemSaver_OnMouseRequestDestroyItem)
        --Event if an action layer changes
        --EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_ACTION_LAYER_POPPED, FCOItemsaver_OnActionLayerPopped)
        --EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_ACTION_LAYER_PUSHED, FCOItemsaver_OnActionLayerPushed)
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_GAME_CAMERA_UI_MODE_CHANGED, FCOItemsaver_OnGameCameraUIModeChanged)
        --Guild bank is selected
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_GUILD_BANK_SELECTED, FCOItemsaver_SelectGuildBank)
        --Retrait station is interacted with
        EVENT_MANAGER:RegisterForEvent(FCOIS.addonVars.gAddonName, EVENT_RETRAIT_STATION_INTERACT_START, FCOItemsaver_RetraitStationInteract)
    end
end