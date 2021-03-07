--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local gAddonName = FCOIS.addonVars.gAddonName
local ctrlVars = FCOIS.ZOControlVars
--==========================================================================================================================================
--													FCOIS EVENT callback functions
--==========================================================================================================================================

local scanInventory = FCOIS.scanInventory

--==============================================================================
--==================== START EVENT CALLBACK FUNCTIONS ==========================
--==============================================================================

--Event callback function if a retrait station is opened
local function FCOItemsaver_RetraitStationInteract(event)
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Retrait station interact", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    FCOIS.gFilterWhere = LF_RETRAIT
end

--Event callback function if a guild bank was swapped
local function FCOItemsaver_SelectGuildBank(_, guildBankId)
    --Store the current guild Id
    FCOIS.guildBankVars.guildBankId = guildBankId
end

--Event upon closing of a crafting station
local function FCOItemSaver_End_Crafting_Interact()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","End crafting", true, FCOIS_DEBUG_DEPTH_NORMAL) end

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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage("[EVENT]","Open store: " .. p_storeIndicator, true, FCOIS_DEBUG_DEPTH_NORMAL) end
    zo_callLater(function()
        --> The following 4 controls/buttons & the depending table entries will be known first as the vendor gets opened the first time.
        --> So they will be re-assigned within EVENT_OPEN_STORE in src/FCOIS_events.lua, function "FCOItemSaver_Open_Store()"
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUY       = ZO_StoreWindowMenuBarButton1
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL      = ZO_StoreWindowMenuBarButton2
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUYBACK   = ZO_StoreWindowMenuBarButton3
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_REPAIR    = ZO_StoreWindowMenuBarButton4
        FCOIS.ZOControlVars.vendorPanelMainMenuButtonControlSets = {
            ["Normal"] = {
                [1] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUY,
                [2] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL,
                [3] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUYBACK,
                [4] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_REPAIR,
            },
            ["Nuzhimeh"] = {
                [1] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL,
                [2] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUYBACK,
            },
        }

        --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
        if p_storeIndicator == "vendor" then
            --Preset the last active vendor button as the different vendor types can have different button counts
            --> The first will be always activated!
            local currentVendorType, vendorTypeButtonCount = FCOIS.GetCurrentVendorType(true)
--d("[FCOIS]FCOItemSaver_Open_Store, lastVendorButton. CurrentVendorType: " .. tostring(currentVendorType) .. ", vendorTypeButtonCount: " ..tostring(vendorTypeButtonCount))
            if currentVendorType ~= nil and currentVendorType ~= "" and vendorTypeButtonCount ~= nil then
                if vendorTypeButtonCount <= 2 then
                    FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_BUY
                else
                    FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_BUY
                end
            end

            --Check the current active panel and set FCOIS.gFilterWhere
            FCOIS.CheckFilterButtonsAtPanel(true, nil)

            --Done inside the PreHookedHandler "OnMouseUp" callback functions:
            local function checkCurrentVendorTypeAndGetLibFiltersPanelId(currentVendorMenuBarbuttonToCheck)
--d("[FCOIS]checkCurrentVendorTypeAndGetLibFiltersPanelId: " .. tostring(currentVendorMenuBarbuttonToCheck:GetName()))
                if currentVendorMenuBarbuttonToCheck == nil then return false end
                local libFiltersFilterPanelId
                --Get the current vendor type and count of menu buttons
                currentVendorType, vendorTypeButtonCount = FCOIS.GetCurrentVendorType(true)
                if currentVendorType ~= nil and currentVendorType ~= "" and vendorTypeButtonCount ~= nil then
                    if vendorTypeButtonCount == 2 then
                        --The vendor type is e.g. Nuzhimeh with only sell and buyback menu buttons
                        if currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_BUY then
                            libFiltersFilterPanelId = LF_VENDOR_SELL
                        elseif currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_SELL then
                            libFiltersFilterPanelId = LF_VENDOR_BUYBACK
                        end
                    elseif vendorTypeButtonCount == 3 then
                        --The vendor type is e.g. ??? with only buy, sell and buyback menu buttons, but no repair button.
                        if currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_BUY then
                            libFiltersFilterPanelId = LF_VENDOR_BUY
                        elseif currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_SELL then
                            libFiltersFilterPanelId = LF_VENDOR_SELL
                        elseif currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK then
                            libFiltersFilterPanelId = LF_VENDOR_BUYBACK
                        end

                    elseif vendorTypeButtonCount == 4 then
                        --The vendor type is e.g. Normal NPC with buy, sell, buyback and repair menu buttons.
                        if currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_BUY then
                            libFiltersFilterPanelId = LF_VENDOR_BUY
                        elseif currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_SELL then
                            libFiltersFilterPanelId = LF_VENDOR_SELL
                        elseif currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK then
                            libFiltersFilterPanelId = LF_VENDOR_BUYBACK
                        elseif currentVendorMenuBarbuttonToCheck == ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR then
                            libFiltersFilterPanelId = LF_VENDOR_REPAIR
                        end
                    end
                end
--d("<libFiltersFilterPanelId: " ..tostring(libFiltersFilterPanelId))
                return libFiltersFilterPanelId
            end
            --Check if there are shown 4 buttons in the vendor's menu bar (then it is a real vendor).
            --Or if there are only 2 buttons (it's the mobile vendor "Nuzhimeh" then).
            --> This needs to be done here in order to "move" the pressed button names:
            --> If the normal vendor is used the button names 1 to 4 are normal.
            --> If a mobile vendor is used the button name 1 is the "sell" tab (and not the buy tab) and the button name 2 is the "buyback" tab and not the
            --> sell tab.
            --======== VENDOR =====================================================
            --Pre Hook the menubar button's (buy, sell, buyback, repair) handler at the vendor
            local preHookButtonDoneCheck = FCOIS.preventerVars.preHookButtonDone
            if ctrlVars.VENDOR_MENUBAR_BUTTON_BUY ~= nil and not preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_BUY:GetName()] then
--d("Vendor button 1 name: " .. tostring(ctrlVars.VENDOR_MENUBAR_BUTTON_BUY:GetName()))
--d(">Vendor button 1 found")
                preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_BUY:GetName()] = true
                ZO_PreHookHandler(ctrlVars.VENDOR_MENUBAR_BUTTON_BUY, "OnMouseUp", function(control, button, upInside)
                    --d(">====================>\nvendor button 1, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastVendorButton:GetName())
                    if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastVendorButton~=ctrlVars.VENDOR_MENUBAR_BUTTON_BUY) then
                        FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_BUY
                        local fromPanelId = FCOIS.gFilterWhere or LF_INVENTORY
                        local toPanelId = checkCurrentVendorTypeAndGetLibFiltersPanelId(ctrlVars.VENDOR_MENUBAR_BUTTON_BUY)
                        zo_callLater(function() FCOIS.PreHookButtonHandler(fromPanelId, toPanelId) end, 50)
                    end
                end)
            end
            if ctrlVars.VENDOR_MENUBAR_BUTTON_SELL ~= nil and not preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_SELL:GetName()] then
                --d("Vendor button 2 name: " .. tostring(ctrlVars.VENDOR_MENUBAR_BUTTON_SELL:GetName()))
                --d(">Vendor button 2 found")
                preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_SELL:GetName()] = true
                ZO_PreHookHandler(ctrlVars.VENDOR_MENUBAR_BUTTON_SELL, "OnMouseUp", function(control, button, upInside)
                    --d(">====================>\nvendor button 2, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastVendorButton:GetName())
                    if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastVendorButton~=ctrlVars.VENDOR_MENUBAR_BUTTON_SELL) then
                        FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_SELL
                        local fromPanelId = FCOIS.gFilterWhere or LF_INVENTORY
                        local toPanelId = checkCurrentVendorTypeAndGetLibFiltersPanelId(ctrlVars.VENDOR_MENUBAR_BUTTON_SELL)
                        zo_callLater(function() FCOIS.PreHookButtonHandler(fromPanelId, toPanelId) end, 50)
                    end
                end)
            end
            if ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK ~= nil and not preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK:GetName()] then
                --d("Vendor button 3 name: " .. tostring(ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK:GetName()))
                --d(">Vendor button 3 found")
                preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK:GetName()] = true
                ZO_PreHookHandler(ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK, "OnMouseUp", function(control, button, upInside)
                    --d(">====================>\nvendor button 3, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastVendorButton:GetName())
                    if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastVendorButton~=ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK) then
                        FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK
                        local fromPanelId = FCOIS.gFilterWhere or LF_INVENTORY
                        local toPanelId = checkCurrentVendorTypeAndGetLibFiltersPanelId(ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK)
                        zo_callLater(function() FCOIS.PreHookButtonHandler(fromPanelId, toPanelId) end, 50)
                    end
                end)
            end
            if ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR ~= nil and not preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR:GetName()] then
                --d("Vendor button 4 name: " .. tostring(ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR:GetName()))
                --d(">Vendor button 4 found")
                preHookButtonDoneCheck[ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR:GetName()] = true
                ZO_PreHookHandler(ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR, "OnMouseUp", function(control, button, upInside)
                    --d(">====================>\nvendor button 4, button: " .. button .. ", upInside: " .. tostring(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastVendorButton:GetName())
                    if (button == MOUSE_BUTTON_INDEX_LEFT and upInside and FCOIS.lastVars.gLastVendorButton~=ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR) then
                        FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR
                        local fromPanelId = FCOIS.gFilterWhere or LF_INVENTORY
                        local toPanelId = checkCurrentVendorTypeAndGetLibFiltersPanelId(ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR)
                        zo_callLater(function() FCOIS.PreHookButtonHandler(fromPanelId, toPanelId) end, 50)
                    end
                end)
            end

        end
    end, 200) -- zo_callLater(function()
end

--Event upon closing of a vendor store
local function FCOItemSaver_Close_Store()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Close store", true, FCOIS_DEBUG_DEPTH_NORMAL) end

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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Open trading house", true, FCOIS_DEBUG_DEPTH_NORMAL) end

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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Close trading house", true, FCOIS_DEBUG_DEPTH_NORMAL) end

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

--Bank and guild bank callback function if a slot updates
local function FCOItemSaver_Inv_Single_Slot_Update_Bank(eventId, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange, triggeredByCharacterName, triggeredByDisplayName)
--d("[FCOItemSaver_Inv_Single_Slot_Update_Bank]bagId: " ..tostring(bagId) .. ", slotIndex: " ..tostring(slotId))
    FCOIS.checkIfBagShouldAutoRemoveMarkerIcons(bagId, slotId)
end

--Bank and guild bank callback function if a slot updates
local function FCOItemSaver_GuildBankItemAdded(eventId, slotId, addedByLocalPlayer, itemSoundCategory)
    --d("[FCOItemSaver_GuildBankItemAdded]bagId: " ..tostring(BAG_GUILDBANK) .. ", slotIndex: " ..tostring(slotId) .. ", addedByLocalPlayer: " ..tostring(addedByLocalPlayer))
    if not addedByLocalPlayer then return end
    FCOIS.checkIfBagShouldAutoRemoveMarkerIcons(BAG_GUILDBANK, slotId)
end

local function checkIfBankInventorySingleSlotUpdateEventNeedsToBeRegistered(bagId)
    local dynamicIconIds = FCOIS.mappingVars.dynamicToIcon
    local settings = FCOIS.settingsVars.settings
    --For each dynamic check if the setting to auto remove a marker icon is enabled
--d("[FCOIS]Register invSingleSlotUpdate check for bagId: " ..tostring(bagId))
    for _, dynamicIconId in ipairs(dynamicIconIds) do
        if settings.icon[dynamicIconId] and settings.icon[dynamicIconId].autoRemoveMarkForBag[bagId] and
            settings.icon[dynamicIconId].autoRemoveMarkForBag[bagId] == true then
            return true
        end
    end
    return false
end

--Event upon opening of a guild bank
local function FCOItemSaver_Open_Guild_Bank()
    FCOIS.preventerVars.gActiveFilterPanel = true
    local settings = FCOIS.settingsVars.settings
    if settings.debug then FCOIS.debugMessage( "[EVENT]","Open guild bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    FCOIS.preventerVars.blockGuildBankWithoutWithdrawAtGuildBankOpen = settings.blockGuildBankWithoutWithdraw

    if checkIfBankInventorySingleSlotUpdateEventNeedsToBeRegistered(BAG_GUILDBANK) == true then
        EVENT_MANAGER:RegisterForEvent(gAddonName.."_GUILDBANK", EVENT_GUILD_BANK_ITEM_ADDED, FCOItemSaver_GuildBankItemAdded)
        EVENT_MANAGER:AddFilterForEvent(gAddonName.."_GUILDBANK", EVENT_GUILD_BANK_ITEM_ADDED, REGISTER_FILTER_UNIT_TAG, "player")
    end
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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Close guild bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    EVENT_MANAGER:UnregisterForEvent(gAddonName.."_GUILDBANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)

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
    --Check the auto reenable Anti-* settings for the guild bank and react on them
    FCOIS.autoReenableAntiSettingsCheck("GUILDBANK")

    FCOIS.preventerVars.blockGuildBankWithoutWithdrawAtGuildBankOpen = nil
end

--Event upon opening of a player bank
local function FCOItemSaver_Open_Player_Bank(event, bagId)
    local isHouseBank = IsHouseBankBag(bagId) or false
    FCOIS.preventerVars.gActiveFilterPanel = true
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Open bank - bagId: " .. tostring(bagId) .. ", isHouseBank: " .. tostring(isHouseBank), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    if checkIfBankInventorySingleSlotUpdateEventNeedsToBeRegistered(BAG_BANK) == true then
        EVENT_MANAGER:RegisterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, FCOItemSaver_Inv_Single_Slot_Update_Bank)
        EVENT_MANAGER:AddFilterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
        EVENT_MANAGER:AddFilterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, BAG_BANK)
    end

    local filterPanelId = LF_BANK_WITHDRAW
    if isHouseBank then
        --Reset the last clicked bank button as it will always be the withdraw tab if you open the bank, and if the
        --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
        FCOIS.lastVars.gLastHouseBankButton = ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW
        filterPanelId = LF_HOUSE_BANK_WITHDRAW
        --Scan the house bank for non marked items, or items that need to be transfered from ZOs marker icons to FCOIS marker icons
        zo_callLater(function()
            --Scan for items that are locked by ZOs and should be transfered to FCOIS
            -->Disabled as this should only be done via the settings menu, manually!
            --FCOIS.scanInventoriesForZOsLockedItems(false, bagId)
            --Scan if house bank got items that should be marked automatically
            scanInventory(bagId, nil)
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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Close bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    EVENT_MANAGER:UnregisterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)

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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Start trading", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Change the button color of the context menu invoker
    FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_TRADE)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    FCOIS.CheckFilterButtonsAtPanel(true, LF_TRADE)
end

--Event upon closing of the trade panel
local function FCOItemSaver_Close_Trade_Panel()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","End trading", true, FCOIS_DEBUG_DEPTH_NORMAL) end

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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Action layer]","Popped] LayerIndex: " .. tostring(layerIndex) .. ", ActiveLayerIndex: " .. tostring(activeLayerIndex), false) end
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
    --EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOItemSaver_End_Crafting_Interact)

    --Abort if crafting station type is invalid
    if craftSkill == 0 then return end
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Crafting Interact: Craft skill: ".. tostring(craftSkill), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --ALCHEMY
    if craftSkill == CRAFTING_TYPE_ALCHEMY then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]",">ALCHEMY Crafting station opened]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
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

local updateSetTrackerMarker = FCOIS.updateSetTrackerMarker
--Inventory slot gets updated function
local function FCOItemSaver_Inv_Single_Slot_Update(_, bagId, slotId, isNewItem, itemSoundCategory, updateReason, stackCountChange, triggeredByCharacterName, triggeredByDisplayName)
    --Only updates for my own account!
    if triggeredByDisplayName and triggeredByDisplayName ~= GetDisplayName() then return end
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
    --Handled within eventFilters now!
    --if updateReason ~= INVENTORY_UPDATE_REASON_DEFAULT then return end
    --d(">2")
    --Abort here if we are arrested by a guard (thief system) as it will scan our inventory for stolen items and destroy them.
    --We don't need to scan it with our functions too at this case
    if IsUnderArrest() then return end
    --Do not execute if horse is changed
    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    local currentScene, _ = FCOIS.getCurrentSceneInfo()
    if currentScene == STABLES_SCENE then return end
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
                FCOIS.debugMessage( "[EVENT]","InventorySingleSlotUpdated==============", true, FCOIS_DEBUG_DEPTH_NORMAL)
                FCOIS.debugMessage( "[EVENT]",">NewItem=" .. tostring(isNewItem) .. ", bagId=" .. bagId .. ", slotIndex=" .. slotId .. ", updateReason=" .. tostring(updateReason), true, FCOIS_DEBUG_DEPTH_NORMAL)
            end
            --if(FCOIS.preventerVars.canUpdateInv == true) then
            --FCOIS.preventerVars.canUpdateInv = false
            zo_callLater(function()
                if settings.debug then FCOIS.debugMessage( "[EVENT]",">executed now! bagId=" .. bagId .. ", slotIndex=" .. slotId, true, FCOIS_DEBUG_DEPTH_NORMAL) end
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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Event]","OnInventorySlotUnLocked: bag: " .. tostring(bag) .. ", slot: " .. tostring(slot), true, FCOIS_DEBUG_DEPTH_NORMAL) end

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
-- Throws and error message if you try to drag&drop an item to a slot (mail, trade, ...)
--> First function called if you drag an item from the inventories:
----> Check file src/FCOIS_Hooks.lua, function FCOItemSaver_OnDragStart(...)
local function FCOItemSaver_OnInventorySlotLocked(self, bag, slot)
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Event]","OnInventorySlotLocked: bag: " .. tostring(bag) .. ", slot: " .. tostring(slot), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]EVENT_INVENTORY_SLOT_LOCKED-bagId: " ..tostring(bag) ..", slotIndex: " ..tostring(slot))

    FCOIS.preventerVars.gItemSlotIsLocked = true
    --Set: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
    FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = true
    --Is only a "split item" procedure run to split an item stack in the inventory?
    --Then do not do the anti-/protection checks.
    if FCOIS.preventerVars.splitItemStackDialogActive then
        FCOIS.preventerVars.splitItemStackDialogActive = false
--d("[FCOIS]<Split item dialog active!")
        return false
    end

    --Deconstruction at crafting station?
    if(not ctrlVars.DECONSTRUCTION_BAG:IsHidden() ) then
--d(">got here, calling deconstruction selection handler")
        -- check if deconstruction is forbidden
        -- if so, clear item hold by cursor
        if( FCOIS.callDeconstructionSelectionHandler(bag, slot, true) ) then
            --Remove the picked-up item from drag&drop cursor
            ClearCursor()
            FCOIS.preventerVars.splitItemStackDialogActive = false
            return false
        end

    --Picked up an item at another station, for bind, destroy, refine, improve, etc.?
    else
        local doShowItemBindDialog = false -- Always false since API 100019 where ZOs included it's "ask before bind to account" dialog
        -- check if destroying, improvement, sending or trading, etc. is forbidden
        -- and check if item is bindable (above)
        -- if so, clear item hold by cursor
        --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
        if( doShowItemBindDialog or FCOIS.callItemSelectionHandler(bag, slot, true, true, false, false, false, false, false) ) then
            --Remove the picked item from drag&drop cursor
            ClearCursor()
            FCOIS.preventerVars.splitItemStackDialogActive = false
            return false
        else
            FCOIS.preventerVars.splitItemStackDialogActive = false
            return false
        end
    end
    --Reset: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
    FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
    FCOIS.preventerVars.splitItemStackDialogActive = false
end

--Executed if item should be destroyed manually
local function FCOItemSaver_OnMouseRequestDestroyItem(_, bagId, slotIndex, _, _, needsConfirm)
--d("[FCOS]FCOItemSaver_OnMouseRequestDestroyItem")
    FCOIS.preventerVars.splitItemStackDialogActive = false
    --Hide the context menu at last active panel
    FCOIS.hideContextMenu(FCOIS.gFilterWhere)

    if not needsConfirm then
        FCOIS.preventerVars.gAllowDestroyItem = false

        if( bagId and slotIndex ) then
            FCOIS.preventerVars.gAllowDestroyItem = not FCOIS.DestroySelectionHandler(bagId, slotIndex, true)
            --Hide the "YES" button of the destroy dialog and disable keybind
            FCOIS.overrideDialogYesButton(FCOIS.ZOControlVars.ZODialog1)
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

    --FCOIS version 1.4.8
    --Reset the flag "temporary use unique IDs" of other addons
    if FCOIS.temporaryUseUniqueIds ~= nil then
        FCOIS.temporaryUseUniqueIds = {}
    end

    --Was the item ID type changed to unique IDs: Show the migrate data from old item IDs to unique itemIDs now
    -->Was set in src/FCIS_Settings.lua, function FCOIS.afterSettings() after a reloadui was done due to the LAM
    -->settings uniqueId change
    if FCOIS.preventerVars.migrateItemMarkers == true then
        FCOIS.ShowAskBeforeMigrateDialog()
    end
end

-- Fires each time after addons were loaded and player is ready to move (after each zone change too)
local function FCOItemSaver_Player_Activated(...)
--d("[FCOIS]EVENT_PLAYER_ACTIVATED")
    --Prevent this event to be fired again and again upon each zone change
    EVENT_MANAGER:UnregisterForEvent(gAddonName, EVENT_PLAYER_ACTIVATED)

    --Reset cached values
    FCOIS.MyGetItemInstanceIdLastBagId      = nil
    FCOIS.MyGetItemInstanceIdLastSlotIndex  = nil
    FCOIS.MyGetItemInstanceIdLastId         = nil
    FCOIS.MyGetItemInstanceIdLastIdSigned   = nil

    FCOIS.CreateFCOISUniqueIdStringLastLastUseType            = nil
    FCOIS.CreateFCOISUniqueIdStringLastUnsignedItemInstanceId = nil
    FCOIS.CreateFCOISUniqueIdStringLastBagId = nil
    FCOIS.CreateFCOISUniqueIdStringLastSlotIndex = nil
    FCOIS.CreateFCOISUniqueIdStringLastItemLink = nil
    FCOIS.CreateFCOISUniqueIdStringLastFCOISCreatedUniqueId = nil

    --Do not go on if libraries are not loaded properly
    if not FCOIS.libsLoadedProperly then
        --Output missing library text to chat
        local preVars = FCOIS.preChatVars
        local libMissingErrorText = FCOIS.errorTexts["libraryMissing"]
        --libLoadedAddons
        if FCOIS.LIBLA == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibLoadedAddons")) end
        --LibAddonMenu 2.0
        if FCOIS.LAM == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibAddonMenu-2.0")) end
        --LibMainMenu 2.0
        if FCOIS.LMM2 == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibMainMenu-2.0")) end
        --libFilters 3.x
        if not FCOIS.libFilters then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibFilters-3.0")) end
        --LibDialog
        if not FCOIS.LDIALOG then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibDialog")) end
        --LibFeedback
        if not FCOIS.libFeedback then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibFeedback")) end
        return
    end

    --Disable this addon if we are in GamePad mode
    if not FCOIS.FCOItemSaver_CheckGamePadMode(true) then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","Player activated", true, FCOIS_DEBUG_DEPTH_NORMAL) end

        --Get the currently logged in character name
        FCOIS.currentlyLoggedInCharName = zo_strformat(SI_UNIT_NAME, GetUnitName("player"))

        --Check if other Addons active now, as the addons should all have been loaded
        FCOIS.CheckIfOtherAddonsActiveAfterPlayerActivated()

        --Map the LibFilters panel IDs to their filter functions
        --> See file src/FCOIS_Filters.lua, function "FCOIS.mapLibFiltersIds2FilterFunctionsNow()"
        FCOIS.mapLibFiltersIds2FilterFunctionsNow()

        --Add/update the filter buttons, but only if not done already in addon initialization
        if FCOIS.addonVars.gAddonLoaded == false then
            FCOIS.updateFilterButtonsInInv(-1)
        end
        FCOIS.addonVars.gAddonLoaded = false

        --Rebuild the gear set variables like the mapping tables for the filter buttons, etc.
        --Must be called once before FCOIS.changeContextMenuEntryTexts(-1) to build the mapping tables + settings.iconIsGear!
        --3rd parameter "calledFromEventPlayerActivated" will tell the function to NOT call FCOIS.changeContextMenuEntryTexts internally
        --as it will be called with -1 (all icons) just below!
        FCOIS.rebuildGearSetBaseVars(nil, nil, true)

        --Overwrite the localized texts for the equipment gears, if changed in the settings
        FCOIS.changeContextMenuEntryTexts(-1)

        --Change the button color of the context menu invoker
        FCOIS.changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)

        --Check inventory for ornate, intricate, set parts, recipes, researchable items and mark them
        --but only scan once as addon loads
        if FCOIS.preventerVars.gAddonStartupInProgress then
            FCOIS.preventerVars.gAddonStartupInProgress = false
            --Delay the call to "scanInventory" so the other addons like CraftStore FixedAndImproved are working properly with their research/recipe functions
            zo_callLater(function() scanInventory() end, 500)
        end

        --Update the itemCount in the inventory sort headers, if needed
        FCOIS.updateFilteredItemCountThrottled(LF_INVENTORY, 50, "EVENT_Player_Activated")

        FCOIS.addonVars.gPlayerActivated = true

        --Check if something should be done at player activated event
        FCOIS.checkForPlayerActivatedTasks()
    end
end

--[[
--* EVENT_GLOBAL_MOUSE_DOWN (*[MouseButtonIndex|#MouseButtonIndex]* _button_, *bool* _ctrl_, *bool* _alt_, *bool* _shift_, *bool* _command_)
local function FCOItemSaver_EventMouseButtonDown(_, button)
    FCOIS.gMouseButtonDown[button] = true
end
--* EVENT_GLOBAL_MOUSE_UP (*[MouseButtonIndex|#MouseButtonIndex]* _button_, *bool* _ctrl_, *bool* _alt_, *bool* _shift_, *bool* _command_)
local function FCOItemSaver_EventMouseButtonUp(_, button)
    FCOIS.gMouseButtonDown[button] = false
end
]]

--Addon is now loading and building up
local function FCOItemSaver_Loaded(eventCode, addOnName)
    --Reset cached values
    FCOIS.MyGetItemInstanceIdLastBagId      = nil
    FCOIS.MyGetItemInstanceIdLastSlotIndex  = nil
    FCOIS.MyGetItemInstanceIdLastId         = nil
    FCOIS.MyGetItemInstanceIdLastIdSigned   = nil

    FCOIS.CreateFCOISUniqueIdStringLastLastUseType = nil
    FCOIS.CreateFCOISUniqueIdStringLastUnsignedItemInstanceId = nil
    FCOIS.CreateFCOISUniqueIdStringLastBagId = nil
    FCOIS.CreateFCOISUniqueIdStringLastSlotIndex = nil
    FCOIS.CreateFCOISUniqueIdStringLastItemLink = nil
    FCOIS.CreateFCOISUniqueIdStringLastFCOISCreatedUniqueId = nil

    --Libraries were loaded properly?
    if FCOIS.libsLoadedProperly then
        --Check if another addon name is found and thus active
        FCOIS.checkIfOtherAddonActive(addOnName)
        --Check if gamepad mode is deactivated?
        --Is this addon found?
        if(addOnName ~= gAddonName) then
            return
        end
        if FCOIS.settingsVars.settings ~= nil and FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]","FCOItemSaver Loaded]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --d("[FCOIS -Event- FCOItemSaver_Loaded]")

        --Unregister this event again so it isn't fired again after this addon has beend recognized
        EVENT_MANAGER:UnregisterForEvent(gAddonName, EVENT_ADD_ON_LOADED)

        --Create the LibDebugLogger loggers: See file src/FCOIS_debug.lua
        FCOIS.CreateLoggers()

        --Register for the zone change/player ready event
        EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_PLAYER_ACTIVATED, FCOItemSaver_Player_Activated)

        if not FCOIS.FCOItemSaver_CheckGamePadMode(true) then

            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]", "Addon loading begins...", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            FCOIS.addonVars.gAddonLoaded = false
            FCOIS.preventerVars.gAddonStartupInProgress = true

            -- Registers addon to loadedAddon library LibLoadedAddons
            FCOIS.LIBLA:RegisterAddon(gAddonName, FCOIS.addonVars.addonVersionOptionsNumber)

            --Register for Crafting stations opened & closed (integer eventCode,number craftSkill, boolean sameStation)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_CRAFTING_STATION_INTERACT, FCOItemSaver_Crafting_Interact)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOItemSaver_End_Crafting_Interact)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_CRAFT_STARTED, FCOItemSaver_Craft_Started)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_CRAFT_COMPLETED, FCOItemSaver_Craft_Completed)
            --Register for Store opened & closed
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_OPEN_STORE, function() FCOItemSaver_Open_Store("vendor") end)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_CLOSE_STORE, FCOItemSaver_Close_Store)
            --Register for Trading house (guild store) opened & closed
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_OPEN_TRADING_HOUSE, FCOItemSaver_Open_Trading_House)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_CLOSE_TRADING_HOUSE, FCOItemSaver_Close_Trading_House)
            --Register for Guild Bank opened & closed
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_OPEN_GUILD_BANK, FCOItemSaver_Open_Guild_Bank)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_CLOSE_GUILD_BANK, FCOItemSaver_Close_Guild_Bank)
            --Register for Player's Bank opened & closed
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_OPEN_BANK, FCOItemSaver_Open_Player_Bank)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_CLOSE_BANK, FCOItemSaver_Close_Player_Bank)
            --Register for Trade panel opened & closed
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_TRADE_INVITE_ACCEPTED, FCOItemSaver_Open_Trade_Panel)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_TRADE_CANCELED, FCOItemSaver_Close_Trade_Panel)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_TRADE_SUCCEEDED, FCOItemSaver_Close_Trade_Panel)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_TRADE_FAILED, FCOItemSaver_Close_Trade_Panel)
            --Register for player inventory slot update
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, FCOItemSaver_Inv_Single_Slot_Update)
            EVENT_MANAGER:AddFilterForEvent(gAddonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
            EVENT_MANAGER:AddFilterForEvent(gAddonName, EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
            --Register the callback function for an update of the inventory slots
            --SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", FCOItemSaver_OnSharedSingleSlotUpdate)
            --Events for destruction & destroy prevention
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_INVENTORY_SLOT_LOCKED, FCOItemSaver_OnInventorySlotLocked)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_INVENTORY_SLOT_UNLOCKED, FCOItemSaver_OnInventorySlotUnLocked)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_MOUSE_REQUEST_DESTROY_ITEM, FCOItemSaver_OnMouseRequestDestroyItem)
            --Event if an action layer changes
            --EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_ACTION_LAYER_POPPED, FCOItemsaver_OnActionLayerPopped)
            --EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_ACTION_LAYER_PUSHED, FCOItemsaver_OnActionLayerPushed)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_GAME_CAMERA_UI_MODE_CHANGED, FCOItemsaver_OnGameCameraUIModeChanged)
            --Guild bank is selected
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_GUILD_BANK_SELECTED, FCOItemsaver_SelectGuildBank)
            --Retrait station is interacted with
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_RETRAIT_STATION_INTERACT_START, FCOItemsaver_RetraitStationInteract)
            --Global mouse down/up event
            --[[
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_GLOBAL_MOUSE_DOWN, FCOItemSaver_EventMouseButtonDown)
            EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_GLOBAL_MOUSE_UP, FCOItemSaver_EventMouseButtonUp)
            ]]

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

            --Do keybinding stuff
            FCOIS.InitializeInventoryKeybind()

            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[EVENT]", "Addon startup finished!", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        end --gamepad active check
    else
        FCOIS.addonVars.gAddonLoaded = false
        --Libraries were not loaded properly!
    end
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
    EVENT_MANAGER:RegisterForEvent(gAddonName, EVENT_ADD_ON_LOADED, FCOItemSaver_Loaded)
end