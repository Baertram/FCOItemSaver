--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local debugMessage = FCOIS.debugMessage

local tos = tostring
local strformat = string.format
local zo_strf = zo_strformat

local em = EVENT_MANAGER


local addonVars = FCOIS.addonVars
local gAddonName = addonVars.gAddonName
local ctrlVars = FCOIS.ZOControlVars
local guildStoreMenubarButtonSearchName = ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH_NAME
--==========================================================================================================================================
--													FCOIS EVENT callback functions
--==========================================================================================================================================

local resetMyGetItemInstanceIdLastVars = FCOIS.ResetMyGetItemInstanceIdLastVars
local resetCreateFCOISUniqueIdStringLastVars = FCOIS.ResetCreateFCOISUniqueIdStringLastVars
local otherAddons = FCOIS.otherAddons
local scanInventory = FCOIS.ScanInventory
local preHookMainMenuFilterButtonHandler = FCOIS.PreHookMainMenuFilterButtonHandler
local checkFCOISFilterButtonsAtPanel = FCOIS.CheckFCOISFilterButtonsAtPanel
local updateFCOISFilterButtonsAtInventory = FCOIS.UpdateFCOISFilterButtonsAtInventory
local changeContextMenuInvokerButtonColorByPanelId = FCOIS.ChangeContextMenuInvokerButtonColorByPanelId
local hideContextMenu = FCOIS.HideContextMenu
local checkIfAutomaticMarksAreDisabledAtBag = FCOIS.CheckIfAutomaticMarksAreDisabledAtBag
local checkIfIsImprovableCraftSkill = FCOIS.CheckIfIsImprovableCraftSkill
local checkIfImprovedItemShouldBeReMarked_AfterImprovement = FCOIS.CheckIfImprovedItemShouldBeReMarked_AfterImprovement
local checkIfImprovedItemShouldBeReMarked_BeforeImprovement = FCOIS.CheckIfImprovedItemShouldBeReMarked_BeforeImprovement
local checkIfCraftedItemShouldBeMarked = FCOIS.CheckIfCraftedItemShouldBeMarked
local onClosePanel = FCOIS.OnClosePanel
local autoReenableAntiSettingsCheck = FCOIS.AutoReenableAntiSettingsCheck
local removeArmorTypeMarker = FCOIS.RemoveArmorTypeMarker
local removeEmptyWeaponEquipmentMarkers = FCOIS.RemoveEmptyWeaponEquipmentMarkers
local filterBasics = FCOIS.FilterBasics
local updateEquipmentSlotMarker = FCOIS.UpdateEquipmentSlotMarker
local overrideDialogYesButton = FCOIS.OverrideDialogYesButton
local isWritOrNonWritItemCraftedAndIsAllowedToBeMarked = FCOIS.IsWritOrNonWritItemCraftedAndIsAllowedToBeMarked
local getCurrentSceneInfo = FCOIS.GetCurrentSceneInfo
local isItemSetPartNoControl = FCOIS.IsItemSetPartNoControl
local isItemOwnerCompanion             = FCOIS.IsItemOwnerCompanion
local checkRepetitivelyIfControlExists = FCOIS.CheckRepetitivelyIfControlExists
local isCharacterShown                 = FCOIS.IsCharacterShown
local isCompanionCharacterShown = FCOIS.IsCompanionCharacterShown
local rebuildGearSetBaseVars = FCOIS.RebuildGearSetBaseVars
local checkIfBagShouldAutoRemoveMarkerIcons = FCOIS.CheckIfBagShouldAutoRemoveMarkerIcons

local destroySelectionHandler =         FCOIS.DestroySelectionHandler
local getCurrentVendorType =            FCOIS.GetCurrentVendorType
local isDeconstructionHandlerNeeded =   FCOIS.IsDeconstructionHandlerNeeded

--==============================================================================
--==================== START EVENT CALLBACK FUNCTIONS ==========================
--==============================================================================

--Event callback function if a retrait station is opened
local function FCOItemsaver_RetraitStationInteract(event)
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Retrait station interact", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    FCOIS.gFilterWhere = LF_RETRAIT
end

--Event callback function if a guild bank was swapped
local function FCOItemsaver_SelectGuildBank(_, guildBankId)
    --Store the current guild Id
    FCOIS.guildBankVars.guildBankId = guildBankId
end

--Event upon opening of a vendor store
local vendorCheckFuncInitialized = false
local checkCurrentVendorTypeAndGetLibFiltersPanelId
local function FCOItemSaver_Open_Store(p_storeIndicator)
    FCOIS.preventerVars.gActiveFilterPanel = true
    p_storeIndicator = p_storeIndicator or "vendor"
    if FCOIS.settingsVars.settings.debug then debugMessage("[EVENT]","Open store: " .. p_storeIndicator, true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Reset the anti-destroy settings if needed (e.g. bank was opened directly after inventory was closed, without calling other panels in between)
    onClosePanel(LF_INVENTORY, nil, "DESTROY")

    zo_callLater(function()
        --> The following 4 controls/buttons & the depending table entries will be known first as the vendor gets opened the first time.
        --> So they will be re-assigned within EVENT_OPEN_STORE in src/FCOIS_events.lua, function "FCOItemSaver_Open_Store()"
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUY       = ZO_StoreWindowMenuBarButton1
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL      = ZO_StoreWindowMenuBarButton2
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUYBACK   = ZO_StoreWindowMenuBarButton3
        FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_REPAIR    = ZO_StoreWindowMenuBarButton4
        local ctrlVarsVendor = FCOIS.ZOControlVars
        ctrlVarsVendor.vendorPanelMainMenuButtonControlSets = {
            [FCOIS_CON_VENDOR_TYPE_NORMAL_NPC] = {
                [1] = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUY,
                [2] = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_SELL,
                [3] = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUYBACK,
                [4] = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_REPAIR,
            },
            [FCOIS_CON_VENDOR_TYPE_PORTABLE] = {
                [1] = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_SELL,
                [2] = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUYBACK,
            },
        }


        --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
        if p_storeIndicator == "vendor" then
            local preHookButtonDoneCheck = FCOIS.preventerVars.preHookButtonDone

            local vendorBuyButton = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUY
            local vendorBuyButtonName = vendorBuyButton and vendorBuyButton:GetName()
            local vendorSellButton = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_SELL
            local vendorSellButtonName = vendorSellButton and vendorSellButton:GetName()
            local vendorBuyBackButton = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUYBACK
            local vendorBuyBackButtonName = vendorBuyBackButton and vendorBuyBackButton:GetName()
            local vendorRepairButton = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_REPAIR
            local vendorRepairButtonName = vendorRepairButton and vendorRepairButton:GetName()

            if not vendorCheckFuncInitialized then
                function checkCurrentVendorTypeAndGetLibFiltersPanelId(currentVendorMenuBarButtonToCheck)
                    --d("[FCOIS]checkCurrentVendorTypeAndGetLibFiltersPanelId: " .. tos(currentVendorMenuBarbuttonToCheck:GetName()))
                    if currentVendorMenuBarButtonToCheck == nil then return end
                    local libFiltersFilterPanelId
                    --Get the current vendor type and count of menu buttons
                    local currentVendorType, vendorTypeButtonCount = getCurrentVendorType(true)
                    if currentVendorType ~= nil and currentVendorType ~= "" and vendorTypeButtonCount ~= nil then
                        if vendorTypeButtonCount == 2 then
                            --The vendor type is e.g. Nuzhimeh with only sell and buyback menu buttons
                            if currentVendorMenuBarButtonToCheck == vendorBuyButton then
                                libFiltersFilterPanelId = LF_VENDOR_SELL
                            elseif currentVendorMenuBarButtonToCheck == vendorSellButton then
                                libFiltersFilterPanelId = LF_VENDOR_BUYBACK
                            end
                        elseif vendorTypeButtonCount == 3 then
                            --The vendor type is e.g. ??? with only buy, sell and buyback menu buttons, but no repair button.
                            if currentVendorMenuBarButtonToCheck == vendorBuyButton then
                                libFiltersFilterPanelId = LF_VENDOR_BUY
                            elseif currentVendorMenuBarButtonToCheck == vendorSellButton then
                                libFiltersFilterPanelId = LF_VENDOR_SELL
                            elseif currentVendorMenuBarButtonToCheck == vendorBuyBackButton then
                                libFiltersFilterPanelId = LF_VENDOR_BUYBACK
                            end

                        elseif vendorTypeButtonCount == 4 then
                            --The vendor type is e.g. Normal NPC with buy, sell, buyback and repair menu buttons.
                            if currentVendorMenuBarButtonToCheck == vendorBuyButton then
                                libFiltersFilterPanelId = LF_VENDOR_BUY
                            elseif currentVendorMenuBarButtonToCheck == vendorSellButton then
                                libFiltersFilterPanelId = LF_VENDOR_SELL
                            elseif currentVendorMenuBarButtonToCheck == vendorBuyBackButton then
                                libFiltersFilterPanelId = LF_VENDOR_BUYBACK
                            elseif currentVendorMenuBarButtonToCheck == vendorRepairButton then
                                libFiltersFilterPanelId = LF_VENDOR_REPAIR
                            end
                        end
                    end
                    --d("<libFiltersFilterPanelId: " ..tos(libFiltersFilterPanelId))
                    return libFiltersFilterPanelId
                end
                vendorCheckFuncInitialized = true
            end

            --Preset the last active vendor button as the different vendor types can have different button counts
            --> The first will be always activated!
            --[[
            local currentVendorType, vendorTypeButtonCount = getCurrentVendorType(true)
            --d("[FCOIS]FCOItemSaver_Open_Store, lastVendorButton. CurrentVendorType: " .. tos(currentVendorType) .. ", vendorTypeButtonCount: " ..tos(vendorTypeButtonCount))
            if currentVendorType ~= nil and currentVendorType ~= "" and vendorTypeButtonCount ~= nil then
                if vendorTypeButtonCount <= 2 then
                    FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_BUY
                else
                    FCOIS.lastVars.gLastVendorButton = ctrlVars.VENDOR_MENUBAR_BUTTON_BUY
                end
            end
            ]]
            FCOIS.lastVars.gLastVendorButton = ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUY
            local lastVars = FCOIS.lastVars

            --Check the current active panel and set FCOIS.gFilterWhere
            -- doUpdateLists, panelId, overwriteFilterWhere, hideFilterButtons, isUniversalDeconNPC, universalDeconFilterPanelIdBefore
            checkFCOISFilterButtonsAtPanel(true, nil, nil, nil, nil, nil)


            --Check if there are shown 4 buttons in the vendor's menu bar (then it is a real vendor).
            --Or if there are only 2 buttons (it's the mobile vendor e.g. "Nuzhimeh" then).
            --> This needs to be done here in order to "move" the pressed button names:
            --> If the normal vendor is used the button names 1 to 4 are normal.
            --> If a mobile vendor is used the button name 1 is the "sell" tab (and not the buy tab) and the button name 2 is the "buyback" tab and not the
            --> sell tab.
            --======== VENDOR =====================================================

            local function updateVendorPanelByButtonControl(buttonControl, mouseButton, upInside)
                    if (mouseButton == MOUSE_BUTTON_INDEX_LEFT and upInside and lastVars.gLastVendorButton~=buttonControl) then
                        FCOIS.lastVars.gLastVendorButton = buttonControl
                        local fromPanelId = FCOIS.gFilterWhere
                        fromPanelId = fromPanelId or LF_INVENTORY
                        local toPanelId = checkCurrentVendorTypeAndGetLibFiltersPanelId(buttonControl)
--d("[FCOIS]VendorPanelButtonClick >fromPanelId: " ..tos(fromPanelId) .. ", toPanelId: " ..tos(toPanelId))
                        --Bugfix #208 Update the current filterType already to the global FCOIS variable in order to let any "refresh" of the vendor UI
                        --use the correct one already! Else the scene/fragment shown callback will raise a LibFilters refresh -> which then calls runFilters
                        --and thus the FCOIS registered filtercallback function at /src/FCOIS_Filters.lua -> function shouldItemBeShownAfterBeenFiltered
                        --which will fail with a lua error as LF_VENDOR_BUY would be stilla ctive even though we switched to LF_VENDOR_SELL already
                        if toPanelId ~= nil then
                            FCOIS.gFilterWhere = toPanelId
                        end
                        --FCOIS.gFilterWhere will be normally updated here, delayed, so that the FCOIS.CheckActivePanel function detects the UI etc. propelry!
                        zo_callLater(function() preHookMainMenuFilterButtonHandler(fromPanelId, toPanelId) end, 50)
                    end
            end

            --Pre Hook the menubar button's (buy, sell, buyback, repair) handler at the vendor
            if vendorBuyButton ~= nil and not preHookButtonDoneCheck[vendorBuyButtonName] then
                --d("Vendor button 1 name: " .. tos(ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUY:GetName()))
                --d(">Vendor button 1 found")
                preHookButtonDoneCheck[vendorBuyButtonName] = true
                ZO_PreHookHandler(vendorBuyButton, "OnMouseUp", function(control, button, upInside)
                    updateVendorPanelByButtonControl(control, button, upInside)
                end)
            end
            if vendorSellButton ~= nil and not preHookButtonDoneCheck[vendorSellButtonName] then
                --d("Vendor button 2 name: " .. tos(ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_SELL:GetName()))
                --d(">Vendor button 2 found")
                preHookButtonDoneCheck[vendorSellButtonName] = true
                ZO_PreHookHandler(vendorSellButton, "OnMouseUp", function(control, button, upInside)
                    --d(">====================>\nvendor button 2, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastVendorButton:GetName())
                    updateVendorPanelByButtonControl(control, button, upInside)
                end)
            end
            if vendorBuyBackButton ~= nil and not preHookButtonDoneCheck[vendorBuyBackButtonName] then
                --d("Vendor button 3 name: " .. tos(ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_BUYBACK:GetName()))
                --d(">Vendor button 3 found")
                preHookButtonDoneCheck[vendorBuyBackButtonName] = true
                ZO_PreHookHandler(vendorBuyBackButton, "OnMouseUp", function(control, button, upInside)
                    --d(">====================>\nvendor button 3, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastVendorButton:GetName())
                    updateVendorPanelByButtonControl(control, button, upInside)
                end)
            end
            if vendorRepairButton ~= nil and not preHookButtonDoneCheck[vendorRepairButtonName] then
                --d("Vendor button 4 name: " .. tos(ctrlVarsVendor.VENDOR_MENUBAR_BUTTON_REPAIR:GetName()))
                --d(">Vendor button 4 found")
                preHookButtonDoneCheck[vendorRepairButtonName] = true
                ZO_PreHookHandler(vendorRepairButton, "OnMouseUp", function(control, button, upInside)
                    --d(">====================>\nvendor button 4, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastVendorButton:GetName())
                    updateVendorPanelByButtonControl(control, button, upInside)
                end)
            end

        end
    end, 200) -- zo_callLater(function()
end

--Event upon closing of a vendor store
local function FCOItemSaver_Close_Store()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Close store", true, FCOIS_DEBUG_DEPTH_NORMAL) end

--d("[FCOIS][EVENT]Close store - gFilterWhere: " ..tos(FCOIS.gFilterWhere))

    onClosePanel(FCOIS.gFilterWhere, LF_INVENTORY, "STORE")
end

--Event upon opening of a guild store
local function FCOItemSaver_Open_Trading_House()
    FCOIS.preventerVars.gActiveFilterPanel = true
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Open trading house", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    local filterPanelId = LF_GUILDSTORE_SELL
    --Special case for AwesomeGuildStore -> directly sell to guild store from custom bank fragment
    -->Will fire (why ever???) after any item was listed at the the guild store sell tab, and changes FCOIS.gFilterWhere that way
    if otherAddons ~= nil and otherAddons.AGSActive ~= nil and ctrlVars.GUILD_STORE_SCENE:IsShowing() then
        --Is the bank fragment shown?
        if ctrlVars.BANK_FRAGMENT:IsShowing() or FCOIS.gFilterWhere == LF_BANK_WITHDRAW then
            filterPanelId = LF_BANK_WITHDRAW
        end
    end

    --Reset the anti-destroy settings if needed (e.g. bank was opened directly after inventory was closed, without calling other panels in between)
    onClosePanel(LF_INVENTORY, nil, "DESTROY")

    --Change the button color of the context menu invoker
    changeContextMenuInvokerButtonColorByPanelId(filterPanelId)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    checkFCOISFilterButtonsAtPanel(true, filterPanelId)

    --======== GUILD STORE SEARCH ==============================================
    local function PreHookGuildStoreSearchButtonOnMouseUp()
        --Update the ZOs control vars for FCOIS
        ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH  = ZO_TradingHouseMenuBarButton1
        FCOIS.lastVars.gLastGuildStoreButton	    = ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH
        ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SELL    = ZO_TradingHouseMenuBarButton2
        ctrlVars.GUILD_STORE_MENUBAR_BUTTON_LIST    = ZO_TradingHouseMenuBarButton3

        if ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH ~= nil then
            --Pre Hook the 2 menubar button's (search and sell) at the guild store
            ZO_PreHookHandler(ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH, "OnMouseUp", function(_, button, upInside)
                --d("guild store button 1, button: " .. button .. ", upInside: " .. tos(upInside) .. ", lastButton: " .. FCOIS.lastVars.gLastGuildStoreButton:GetName())
                --if (button == 1 and upInside and FCOIS.lastVars.gLastGuildStoreButton~=ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH) then
                if button == MOUSE_BUTTON_INDEX_LEFT and upInside then
                    --FCOIS.lastVars.gLastGuildStoreButton = ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH
                    --Close the contextMenu at the guild store sell window now
                    hideContextMenu(LF_GUILDSTORE_SELL)
                end
            end)
        end
    end
    --Check as long until the control "ZO_TradingHouseMenuBarButton1" exists, and then call the function in the 2nd parameter
    checkRepetitivelyIfControlExists(guildStoreMenubarButtonSearchName, PreHookGuildStoreSearchButtonOnMouseUp, 100, 10000)
end

--Event upon closing of a guild store
local function FCOItemSaver_Close_Trading_House()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Close trading house", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    onClosePanel(FCOIS.gFilterWhere, LF_INVENTORY, "GUILD_STORE")
end

--Bank and guild bank callback function if a slot updates
local function FCOItemSaver_Inv_Single_Slot_Update_Bank(eventId, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange, triggeredByCharacterName, triggeredByDisplayName)
--d("[FCOItemSaver_Inv_Single_Slot_Update_Bank]bagId: " ..tos(bagId) .. ", slotIndex: " ..tos(slotId))
    checkIfBagShouldAutoRemoveMarkerIcons(bagId, slotId)
end

--Bank and guild bank callback function if a slot updates
local function FCOItemSaver_GuildBankItemAdded(eventId, slotId, addedByLocalPlayer, itemSoundCategory)
    --d("[FCOItemSaver_GuildBankItemAdded]bagId: " ..tos(BAG_GUILDBANK) .. ", slotIndex: " ..tos(slotId) .. ", addedByLocalPlayer: " ..tos(addedByLocalPlayer))
    if not addedByLocalPlayer then return end
    checkIfBagShouldAutoRemoveMarkerIcons(BAG_GUILDBANK, slotId)
end

local function checkIfBankInventorySingleSlotUpdateEventNeedsToBeRegistered(bagId)
    local dynamicIconIds = FCOIS.mappingVars.dynamicToIcon
    local settings = FCOIS.settingsVars.settings
    --For each dynamic check if the setting to auto remove a marker icon is enabled
--d("[FCOIS]Register invSingleSlotUpdate check for bagId: " ..tos(bagId))
    for _, dynamicIconId in ipairs(dynamicIconIds) do
        if settings.icon[dynamicIconId] and settings.icon[dynamicIconId].autoRemoveMarkForBag[bagId] and
            settings.icon[dynamicIconId].autoRemoveMarkForBag[bagId] == true then
            return true
        end
    end
    return false
end

local function FCOItemSaver_Guild_Bank_Items_Ready(eventId)
    --Scan if guild bank got items that should be marked automatically
    if not checkIfAutomaticMarksAreDisabledAtBag(BAG_GUILDBANK) then
        scanInventory(BAG_GUILDBANK, nil, FCOIS.settingsVars.settings.autoMarkBagsChatOutput)
    end
end

--Event upon opening of a guild bank
local function FCOItemSaver_Open_Guild_Bank()
    FCOIS.preventerVars.gActiveFilterPanel = true
    --Reset the anti-destroy settings if needed (e.g. bank was opened directly after inventory was closed, without calling other panels in between)
    onClosePanel(LF_INVENTORY, nil, "DESTROY")

    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[EVENT]","Open guild bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    FCOIS.preventerVars.blockGuildBankWithoutWithdrawAtGuildBankOpen = settings.blockGuildBankWithoutWithdraw

    if checkIfBankInventorySingleSlotUpdateEventNeedsToBeRegistered(BAG_GUILDBANK) == true then
        em:RegisterForEvent(gAddonName.."_GUILDBANK", EVENT_GUILD_BANK_ITEM_ADDED, FCOItemSaver_GuildBankItemAdded)
        em:AddFilterForEvent(gAddonName.."_GUILDBANK", EVENT_GUILD_BANK_ITEM_ADDED, REGISTER_FILTER_UNIT_TAG, "player")
    end
    --Reset the last clicked guild bank button as it will always be the withdraw tab if you open the guild bank, and if the
    --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
    FCOIS.lastVars.gLastGuildBankButton = ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW

    --Change the button color of the context menu invoker
    changeContextMenuInvokerButtonColorByPanelId(LF_GUILDBANK_WITHDRAW)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    checkFCOISFilterButtonsAtPanel(true, LF_GUILDBANK_WITHDRAW)

    em:RegisterForEvent(gAddonName.."_GUILDBANK_ITEMS_READY", EVENT_GUILD_BANK_ITEMS_READY, FCOItemSaver_Guild_Bank_Items_Ready)
end

--Event upon closing of a guild bank
local function FCOItemSaver_Close_Guild_Bank()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Close guild bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    em:UnregisterForEvent(gAddonName.."_GUILDBANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)
    em:UnregisterForEvent(gAddonName.."_GUILDBANK_ITEMS_READY", EVENT_GUILD_BANK_ITEMS_READY)

    onClosePanel(FCOIS.gFilterWhere, LF_INVENTORY, {"DESTROY", "GUILDBANK"})

    FCOIS.preventerVars.blockGuildBankWithoutWithdrawAtGuildBankOpen = nil
end

--Event upon opening of a player bank
local function FCOItemSaver_Open_Player_Bank(event, bagId)
    --Special case for AwesomeGuildStore -> directly sell to guild store from custom bank fragment
    -->Will fire (why ever???) after any item was listed at the the guild store sell tab, and changes FCOIS.gFilterWhere that way
    if otherAddons ~= nil and otherAddons.AGSActive ~= nil and ctrlVars.GUILD_STORE_SCENE:IsShowing() then
        return
    end

    local isHouseBank = IsHouseBankBag(bagId) or false
    FCOIS.preventerVars.gActiveFilterPanel = true
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[EVENT]","Open bank - bagId: " .. tos(bagId) .. ", isHouseBank: " .. tos(isHouseBank), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Reset the anti-destroy settings if needed (e.g. bank was opened directly after inventory was closed, without calling other panels in between)
    onClosePanel(LF_INVENTORY, nil, "DESTROY")

    if bagId == BAG_BANK or bagId == BAG_SUBSCRIBER_BANK then
        if checkIfBankInventorySingleSlotUpdateEventNeedsToBeRegistered(BAG_BANK) == true then
            em:RegisterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, FCOItemSaver_Inv_Single_Slot_Update_Bank)
            em:AddFilterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
            em:AddFilterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, bagId)
        end
    end

    local filterPanelId = LF_BANK_WITHDRAW
    if isHouseBank then
        --Reset the last clicked bank button as it will always be the withdraw tab if you open the bank, and if the
        --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
        FCOIS.lastVars.gLastHouseBankButton = ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW
        filterPanelId = LF_HOUSE_BANK_WITHDRAW
        --Scan the house bank for non marked items, or items that need to be transfered from ZOs marker icons to FCOIS marker icons
        -->Only use BAG_HOUSE_BANK_ONE for the "isAutomaticMarksEnabled check" as only this 1 bagId will be used within the tables of the settings
        -->and counts for all 10 possible house bank bags!
        if not checkIfAutomaticMarksAreDisabledAtBag(BAG_HOUSE_BANK_ONE) then
            zo_callLater(function()
                --Scan for items that are locked by ZOs and should be transfered to FCOIS
                -->Disabled as this should only be done via the settings menu, manually!
                --FCOIS.scanInventoriesForZOsLockedItems(false, bagId)
                --Scan if house bank got items that should be marked automatically
                scanInventory(bagId, nil, FCOIS.settingsVars.settings.autoMarkBagsChatOutput)
            end, 250)
        end
    else
        --Reset the last clicked bank button as it will always be the withdraw tab if you open the bank, and if the
        --deposit button was the last one clicked it won't change the filter buttons as it thinks it is still active
        FCOIS.lastVars.gLastBankButton = ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW
        filterPanelId = LF_BANK_WITHDRAW
        --Scan if player bank got items that should be marked automatically
        if not checkIfAutomaticMarksAreDisabledAtBag(bagId) then
            zo_callLater(function()
                scanInventory(bagId, nil, settings.autoMarkBagsChatOutput)
            end, 250)
        end
    end
    --Change the button color of the context menu invoker
    changeContextMenuInvokerButtonColorByPanelId(filterPanelId)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    checkFCOISFilterButtonsAtPanel(true, filterPanelId)
end

--Event upon closing of a player bank
local function FCOItemSaver_Close_Player_Bank()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Close bank", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    em:UnregisterForEvent(gAddonName.."_BANK", EVENT_INVENTORY_SINGLE_SLOT_UPDATE)

    onClosePanel(FCOIS.gFilterWhere, LF_INVENTORY, "DESTROY")
end

--Event upon closing of the trade panel
local function FCOItemSaver_Close_Trade_Panel()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","End trading", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    em:UnregisterForEvent(gAddonName, EVENT_TRADE_CANCELED)
    em:UnregisterForEvent(gAddonName, EVENT_TRADE_SUCCEEDED)
    em:UnregisterForEvent(gAddonName, EVENT_TRADE_FAILED)

    onClosePanel(FCOIS.gFilterWhere, LF_INVENTORY, "TRADE")
end

--Event upon opening of the trade panel
local function FCOItemSaver_Open_Trade_Panel()
    FCOIS.preventerVars.gActiveFilterPanel = true
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Start trading", true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Reset the anti-destroy settings if needed (e.g. bank was opened directly after inventory was closed, without calling other panels in between)
    onClosePanel(LF_INVENTORY, nil, "DESTROY")

    em:RegisterForEvent(gAddonName, EVENT_TRADE_CANCELED, FCOItemSaver_Close_Trade_Panel)
    em:RegisterForEvent(gAddonName, EVENT_TRADE_SUCCEEDED, FCOItemSaver_Close_Trade_Panel)
    em:RegisterForEvent(gAddonName, EVENT_TRADE_FAILED, FCOItemSaver_Close_Trade_Panel)

    --Change the button color of the context menu invoker
    changeContextMenuInvokerButtonColorByPanelId(LF_TRADE)
    --Check the filter buttons and create them if they are not there. Update the inventory afterwards too
    checkFCOISFilterButtonsAtPanel(true, LF_TRADE)
end

--[[
--event handler for ACTION LAYER POPPED
local function FCOItemsaver_OnActionLayerPopped(layerIndex, activeLayerIndex)
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Action layer]","Popped] LayerIndex: " .. tos(layerIndex) .. ", ActiveLayerIndex: " .. tos(activeLayerIndex), false) end
    --ActiveLayerIndex = 3 will be opened in most cases
    if activeLayerIndex == 3 then
        --Hide the context menu at last active panel
        --TODO 2016-08-06 Validate that the action layer is 3 and not 2 anymore, and see if the context menu closing cannot be forced elsewhere properly
        --hideContextMenu(FCOIS.gFilterWhere)
    end
end
]]

--event handler for GAME_CAMERA_UI_MODE_CHANGED
local function FCOItemsaver_OnGameCameraUIModeChanged()
    if not IsGameCameraUIModeActive() then
        --d("[FCOIS] GAME_CAMERA_UI_MODE_CHANGED")
        --Hide the contxt menu if still open
        hideContextMenu(FCOIS.gFilterWhere)
    end
end

local function unregisterCraftStartedEvents()
    em:UnregisterForEvent(gAddonName, EVENT_CRAFT_COMPLETED)
    em:UnregisterForEvent(gAddonName, EVENT_CRAFT_FAILED)
end

local function FCOItemSaver_Craft_Failed(eventId, craftSkill)
    unregisterCraftStartedEvents()
end


--Event upon closing of a crafting station
local function FCOItemSaver_End_Crafting_Interact()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","End crafting", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    unregisterCraftStartedEvents()

    onClosePanel(FCOIS.gFilterWhere, LF_INVENTORY, "CRAFTING_STATION")
end

--event handler for EVENT_CRAFT_COMPLETED
local function FCOItemSaver_Craft_Completed(eventId, craftSkill)
--d("[FCOIS] EVENT CraftCompleted - newItemCrafted: " .. tos(FCOIS.preventerVars.newItemCrafted))
    --Reset the variable to know if an item is getting into our bag after crafting complete
    FCOIS.preventerVars.newItemCrafted = false
    FCOIS.preventerVars.createdMasterWrit = nil
    FCOIS.preventerVars.writCreatorCreatedItem  = false

    --Check if item got improved and if the marker icons from before improvement should be re-marked on the improved item
    if checkIfIsImprovableCraftSkill(craftSkill) == true then
        checkIfImprovedItemShouldBeReMarked_AfterImprovement()
    end
    unregisterCraftStartedEvents()
end

--event handler for EVENT_CRAFT_STARTED
local function FCOItemSaver_Craft_Started(_, craftSkill)
    em:RegisterForEvent(gAddonName, EVENT_CRAFT_COMPLETED,  FCOItemSaver_Craft_Completed)
    em:RegisterForEvent(gAddonName, EVENT_CRAFT_FAILED, FCOItemSaver_Craft_Failed)

--d("[FCOIS] EVENT CraftStarted - craftSkill: " .. tos(craftSkill))
    --Check if new crafted item should be marked with the "crafted" marker icon
    checkIfCraftedItemShouldBeMarked(craftSkill)

    --Check if item get's improved and if the marker icons from before improvement should be remembered
    if checkIfIsImprovableCraftSkill(craftSkill) == true then
--d(">>is improvable craftskill")
        checkIfImprovedItemShouldBeReMarked_BeforeImprovement()
    end
end

--Event upon opening of a crafting station
local function FCOItemSaver_Crafting_Interact(_, craftSkill)
--d("[FCOIS]EVENT_CRAFTING_STATION_INTERACT-craftSkill: " ..tos(craftSkill))
    FCOIS.preventerVars.gActiveFilterPanel = true
    --em:RegisterForEvent(gAddonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOItemSaver_End_Crafting_Interact)

    --Abort if crafting station type is invalid
    if craftSkill == 0 then return end
    if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","Crafting Interact: Craft skill: ".. tos(craftSkill), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Reset the anti-destroy settings if needed (e.g. bank was opened directly after inventory was closed, without calling other panels in between)
    onClosePanel(LF_INVENTORY, nil, "DESTROY")

    --ALCHEMY
    if craftSkill == CRAFTING_TYPE_ALCHEMY then
        if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]",">ALCHEMY Crafting station opened]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Hide the context menu at last active panel
        hideContextMenu(FCOIS.gFilterWhere)

        --If the addon PotionMaker is activated and got it's own Alchemy button activated too
        if otherAddons.potionMakerActive then
            --d("PotionMaker active and button exists -> Resetting last clicked button now")
            --Reset the variable for the last pressed button
            FCOIS.lastVars.gLastAlchemyButton = ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_POTIONMAKER
        end
        --Show the filter buttons at the alchemy station
        preHookMainMenuFilterButtonHandler(nil, LF_ALCHEMY_CREATION)

    else
--d("[FCOItemSaver_Crafting_Interact] FCOIS.gFilterWhere: " .. FCOIS.gFilterWhere)
        --Change the button color of the context menu invoker
        changeContextMenuInvokerButtonColorByPanelId(FCOIS.gFilterWhere)
    end
end

local updateSetTrackerMarker = FCOIS.updateSetTrackerMarker --#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300
--Inventory slot gets updated function
local function FCOItemSaver_Inv_Single_Slot_Update(_, bagId, slotId, isNewItem, itemSoundCategory, updateReason, stackCountChange, triggeredByCharacterName, triggeredByDisplayName)
    --Only updates for my own account!
    if triggeredByDisplayName and triggeredByDisplayName ~= GetDisplayName() then return end
    --Do not mark or scan inventory if writcreater addon is crafting items
    if FCOIS.preventerVars.writCreatorCreatedItem then return false end
    local settings = FCOIS.settingsVars.settings
    --Scan new items in the player inventory and add markers OR update equipped/unequipped item markers
    --d("[FCOItemSaver_Inv_Single_Slot_Update] bagId: " .. bagId .. ", slot: " .. slotId..", isNewItem: " .. tos(isNewItem)..", updateReason: " .. tos(updateReason) .. ", FCOIS.newItemCrafted: " .. tos(FCOIS.preventerVars.newItemCrafted))
    -- ===== Do some abort checks first =====
    --Mark new crafted item with the lock (or the chosen) icon?
    if FCOIS.preventerVars.newItemCrafted and bagId ~= nil and slotId ~= nil then --and isNewItem then
        FCOIS.preventerVars.newItemCrafted = false
        local writOrNonWritMarkUponCreation, craftMarkerIcon = isWritOrNonWritItemCraftedAndIsAllowedToBeMarked()
        if writOrNonWritMarkUponCreation and craftMarkerIcon ~= nil then
            --local itemLink = GetItemLink(bagId, slotId)
            --d("[FCOIS]FCOItemSaver_Inv_Single_Slot_Update: New crafted item: " .. itemLink .. ", isWritAddonCreatedItem: " ..tos(isWritAddonCreatedItem) .. ", markerIcon: " .. tos(craftMarkerIcon))
            --Check slightly delayed if the crafted item should be marked
            zo_callLater(function()
                local markNow = true
                local isSetPart = isItemSetPartNoControl(bagId, slotId)
                --Only mark crafted set parts?
                if settings.autoMarkCraftedItemsSets then
                    --Only do this if not already set parts, which get "new" into your inventory, will get marked automatically
                    if isSetPart and settings.autoMarkSets then
                        markNow = false
                    end
                    markNow = isSetPart
                end
                --d("[FCOIS]FCOItemSaver_Inv_Single_Slot_Update: New crafted item: " .. itemLink .. ", markerIcon: " .. tos(craftMarkerIcon) .. ", isSetPart: " ..tos(isSetPart) .. ", onlyMarkCraftedSets: " ..tos(settings.autoMarkCraftedItemsSets) .. ", markNow: " ..tos(markNow))

                --Mark item now?
                if markNow then
                    --d(">Mark item " ..itemLink .. " with icon: " .. tos(craftMarkerIcon))
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
    local currentScene, _ = getCurrentSceneInfo()
    if currentScene == STABLES_SCENE then return end
    --Check if item in slot is still there
    if GetItemType(bagId, slotId) == ITEMTYPE_NONE then return end
    --d(">3")

    --All bags except the equipment
    if bagId ~= BAG_WORN and bagId ~= BAG_COMPANION_WORN then
        --Abort if not new item is added to inventory
        --if (not isNewItem) then return end
        --d(">4")

        --Support for Roomba
        if Roomba and Roomba.WorkInProgress and Roomba.WorkInProgress() then return end

        --Only check for normal player inventory
        --if (bagId == BAG_BACKPACK) then
        if settings.debug then
            debugMessage( "[EVENT]","InventorySingleSlotUpdated==============", true, FCOIS_DEBUG_DEPTH_NORMAL)
            debugMessage( "[EVENT]",">NewItem=" .. tos(isNewItem) .. ", bagId=" .. bagId .. ", slotIndex=" .. slotId .. ", updateReason=" .. tos(updateReason), true, FCOIS_DEBUG_DEPTH_NORMAL)
        end
        --if(FCOIS.preventerVars.canUpdateInv == true) then
        --FCOIS.preventerVars.canUpdateInv = false
        zo_callLater(function()
            if settings.debug then debugMessage( "[EVENT]",">executed now! bagId=" .. bagId .. ", slotIndex=" .. slotId, true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Scan the inventory item for automatic marker icons which should be set
            if not checkIfAutomaticMarksAreDisabledAtBag(bagId) then
                FCOIS.preventerVars.eventInventorySingleSlotUpdate = true
                scanInventory(bagId, slotId, false) --no chat output!
                FCOIS.preventerVars.eventInventorySingleSlotUpdate = false
            end

            -- ========================== SET TRACKER ===========================================================================================================================
            --#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300
            if SetTrack ~= nil and SetTrack.GetTrackingInfo ~= nil then
                local otherAddonsSetTracker = otherAddons.SetTracker
                if otherAddonsSetTracker.isActive and settings.autoMarkSetTrackerSets then
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
            end

            --New item
            local settingsAutoMarkNewItems = (settings.autoMarkNewItems and settings.isIconEnabled[settings.autoMarkNewIconNr]) or false
            if settingsAutoMarkNewItems == true then
                local markWithNewNow = true
                if settings.autoMarkNewItemsCheckOthers == true then
                    local isMarked, _ = FCOIS.IsMarked(bagId, slotId, -1)
                    if isMarked == true then markWithNewNow = false end
                end
                if markWithNewNow == true then
                    --New item should be marked with a FCOIS marker icon now
                    FCOIS.MarkItem(bagId, slotId, settings.autoMarkNewIconNr, true, false)
                end
            end
        end, 250)
        --FCOIS.preventerVars.canUpdateInv = true
        --end
        --end

        --Equipment bag:  BAG_WORN (character equipment) or BAG_COMPANION_WORN (companion equipment)
    else
        if slotId ~= nil then
            --Update the equipment slot control's markers
            updateEquipmentSlotMarker(slotId, 50)
        end
    end
end

-- handler function for EVENT_INVENTORY_SLOT_UNLOCKED global event
-- will be fired (after EVENT_INVENTORY_SLOT_LOCKED) if you have pickuped an item (e.g. by drag&drop) and drop it again
local function FCOItemSaver_OnInventorySlotUnLocked(self, bag, slot)
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Event]","OnInventorySlotUnLocked: bag: " .. tos(bag) .. ", slot: " .. tos(slot), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]EVENT_INVENTORY_SLOT_UNLOCKED-bagId: " ..tos(bag) ..", slotIndex: " ..tos(slot))

    if (bag == BAG_WORN or bag == BAG_COMPANION_WORN) and FCOIS.preventerVars.gItemSlotIsLocked == true then
        --If item was unequipped: Remove the armor type marker if necessary
        removeArmorTypeMarker(bag, slot)

        --Check all weapon slots and remove empty markers
        removeEmptyWeaponEquipmentMarkers()

        --Update the player invenory row markers
        filterBasics(true)
    end
    FCOIS.preventerVars.gItemSlotIsLocked = false
    --Reset: Tell function ItemSelectionHandler that a drag&drop or doubleclick event was raised so it's not blocking the equip/use/etc. functions
    FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
end
FCOIS.OnInventorySlotUnLocked = FCOItemSaver_OnInventorySlotUnLocked

-- handler function for EVENT_INVENTORY_SLOT_LOCKED global event
-- will be fired (before EVENT_CURSOR_PICKUP) if you pickup an item (e.g. by drag&drop)
-- Throws and error message if you try to drag&drop an item to a slot (mail, trade, ...)
--> First function called if you drag an item from the inventories:
----> Check file src/FCOIS_Hooks.lua, function FCOItemSaver_OnDragStart(...)
local function FCOItemSaver_OnInventorySlotLocked(self, bag, slot)
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Event]","OnInventorySlotLocked: bag: " .. tos(bag) .. ", slot: " .. tos(slot) .. ", FCOIS.gFilterWhere: " ..tos(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]EVENT_INVENTORY_SLOT_LOCKED-bagId: " ..tos(bag) ..", slotIndex: " ..tos(slot))

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
    if isDeconstructionHandlerNeeded() then
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
        --local doShowItemBindDialog = false -- Always false since API 100019 where ZOs included it's "ask before bind to account" dialog
        -- check if destroying, improvement, sending or trading, etc. is forbidden
        -- and check if item is bindable (above)
        -- if so, clear item hold by cursor
        --                                bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId, isDragAndDrop, panelIdParent
        if FCOIS.callItemSelectionHandler(bag, slot, true, true, false, true, false, false, nil, true, nil) then
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
FCOIS.OnInventorySlotLocked = FCOItemSaver_OnInventorySlotLocked

--Executed if item should be destroyed manually
local function FCOItemSaver_OnMouseRequestDestroyItem(_, bagId, slotIndex, _, _, needsConfirm)
--d("[FCOS]FCOItemSaver_OnMouseRequestDestroyItem - needsConfirm: " ..tos(needsConfirm) .. " - " .. GetItemLink(bagId, slotIndex))
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Event]","OnMouseRequestDestroyItem: bag: " .. tos(bagId) .. ", slot: " .. tos(slotIndex) .. ", needsConfirm: " ..tos(needsConfirm), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    FCOIS.preventerVars.splitItemStackDialogActive = false
    --Hide the context menu at last active panel
    hideContextMenu(FCOIS.gFilterWhere)

    if not needsConfirm then
        FCOIS.preventerVars.gAllowDestroyItem = false

        if( bagId and slotIndex ) then
            FCOIS.preventerVars.gAllowDestroyItem = not destroySelectionHandler(bagId, slotIndex, true)
            --Hide the "YES" button of the destroy dialog and disable keybind
            overrideDialogYesButton(FCOIS.ZOControlVars.ZODialog1)
        end
    end
end

--[[
local function FCOItemSaver_OnCursorPickup(eventCode, cursorType, param1, param2, param3, param4, param5, param6, itemSoundCategory)
d("[FCOIS]FCOItemSaver_OnCursorPickup - cursorType: " ..tos(MOUSE_CONTENT_EQUIPPED_ITEM) .. ", param1: " ..tos(param1) .. ", param2: " ..tos(param2) .. ", param3: " ..tos(param3).. ", param4: " ..tos(param4) .. ", param5: " ..tos(param5) .. ", param6: " ..tos(param6))
    local charIsShown = isCharacterShown()
    local companionCharIsShown = isCompanionCharacterShown()
    if not charIsShown and not companionCharIsShown then return end
    if cursorType == MOUSE_CONTENT_EQUIPPED_ITEM then
        --Character item picked up
        d(">Character item picked up")

    elseif cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
        --Inventory item picked up
        local bag, slotIndex = GetCursorBagId() or tonumber(param1), GetCursorSlotIndex() or tonumber(param2) --Dragged bagId, slotIndex (should be the same as param1 and param2)
d(">"..GetItemLink(bag, slotIndex))
        if GetItemEquipType(bag, slotIndex) == EQUIP_TYPE_INVALID then return end
        --Is the item a companion item? And is the companion character shown?
        local isCompanionOwnedtem = GetItemActorCategory(bag, slotIndex) == GAMEPLAY_ACTOR_CATEGORY_COMPANION
        if companionCharIsShown then
            if not isCompanionOwnedtem then return end
        else
            if isCompanionOwnedtem then return end
        end
        d(">Equippable inv item picked up")
    end
end
]]


local function updateEquipmentSlotOfDraggedItem(equipSlot, equipType, wasUnequipped, icCompanionChar)
--d("updateEquipmentSlotOfDraggedItem")
    local unequippedToDropControl = {
        --Unequipped
        [true]  = {
            [true]  = ctrlVars.COMPANION_INV_CONTROL,           --Companion Inventory: ZO_CompanionEquipment_Panel_Keyboard
            [false] = ctrlVars.INV,                             --Player inventory: ZO_PlayerInventory
        },
        --Equipped
        [false]  = {
            [true]  = ctrlVars.COMPANION_CHARACTER,     --Companion character
            [false] = ctrlVars.CHARACTER,               --Normal character
        }
    }
    --Was the item dropped on a supported drop control?
    local dropToControl = unequippedToDropControl[wasUnequipped][icCompanionChar]
    if not dropToControl or not dropToControl.IsHidden or dropToControl:IsHidden() then return end
    local mouseOverControl = moc()
--d(">dropToControl: " .. tos(dropToControl:GetName()) ..", moc: " .. tos(mouseOverControl:GetName()) .. ", mocOwner: " .. tos(mouseOverControl:GetOwningWindow():GetName()))
    if not mouseOverControl or not mouseOverControl.GetOwningWindow then return end
    if mouseOverControl:GetOwningWindow() ~= dropToControl then return end

    equipSlot = equipSlot or FCOIS.mappingVars.equipTypeToSlot[equipType]
    if not equipSlot then return end
--d(">>updating equipment slot: " ..tos(equipSlot))
    --Update the marker control of the new equipped item
    updateEquipmentSlotMarker(equipSlot, 300, wasUnequipped)
    --Refresh the inventory, if shown, to update the marker icons at the unequipped item's inventory row
    filterBasics(true)
end

local function FCOItemSaver_OnCursorDropped(eventCode, cursorType, param1, param2, param3, param4, param5, param6)
--d("[FCOIS]FCOItemSaver_OnCursorDropped - cursorType: " ..tos(MOUSE_CONTENT_EQUIPPED_ITEM) .. ", param1: " ..tos(param1) .. ", param2: " ..tos(param2) .. ", param3: " ..tos(param3).. ", param4: " ..tos(param4) .. ", param5: " ..tos(param5) .. ", param6: " ..tos(param6))
    local charIsShown = isCharacterShown()
    local companionCharIsShown = isCompanionCharacterShown()
    if not charIsShown and not companionCharIsShown then return end
    local bag, slotIndex
    if cursorType == MOUSE_CONTENT_EQUIPPED_ITEM then
        bag, slotIndex = GetCursorBagId() or ((companionCharIsShown and BAG_COMPANION_WORN) or BAG_WORN), GetCursorSlotIndex() or tonumber(param1)
    elseif cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
        bag, slotIndex = GetCursorBagId() or tonumber(param1), GetCursorSlotIndex() or tonumber(param2) --Dragged bagId, slotIndex (should be the same as param1 and param2)
    end
--d(">droppedItem: "..GetItemLink(bag, slotIndex))
    local equipType = GetItemEquipType(bag, slotIndex)
    if equipType == EQUIP_TYPE_INVALID then return end
    local isCompanionOwnedtem = isItemOwnerCompanion(bag, slotIndex)
    if companionCharIsShown then
        if not isCompanionOwnedtem then return end
    else
        if isCompanionOwnedtem then return end
    end
    if cursorType == MOUSE_CONTENT_EQUIPPED_ITEM then
        --Character item dropped - Update the appropriate equipmentSlot of the itemType
--d(">Char item dropped")
        updateEquipmentSlotOfDraggedItem(slotIndex, equipType, true, companionCharIsShown)

    elseif cursorType == MOUSE_CONTENT_INVENTORY_ITEM then
        --Inventory item dropped on char? - Update the appropriate equipmentSlot of the itemType
--d(">Equippable inv item dropped")
        updateEquipmentSlotOfDraggedItem(nil, equipType, false, companionCharIsShown)
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
    local settings = FCOIS.settingsVars.settings
    if settings.autoMarkSetTrackerSetsRescan then
        local otherAddonsSetTracker = otherAddons.SetTracker
        if otherAddonsSetTracker.isActive
                and SetTrack ~= nil and SetTrack.GetTrackingInfo ~= nil and SetTrack.GetTrackStateInfo ~= nil
                and settings.autoMarkSetTrackerSets then
            --d("[FCOIS.checkForPlayerActivatedTasks - Rescan for SetTracker set parts")
            otherAddonsSetTracker.checkAllItemsForSetTrackerTrackingState()
        end
    end

    --FCOIS version 1.4.8
    --Reset the flag "temporary use unique IDs" of other addons
    if FCOIS.temporaryUseUniqueIds ~= nil then
        FCOIS.temporaryUseUniqueIds = {}
    end

    --Was the item ID type changed to (non) unique IDs: Show the migrate data from old item IDs to unique itemIDs/or from unique IDs to non-unique now.
    -->Was set in src/FCIS_Settings.lua, function FCOIS.afterSettings() after a reloadui was done due to the LAM settings uniqueId change
    FCOIS.preventerVars.migrateItemMarkersCalledFromPlayerActivated = false
    if FCOIS.preventerVars.migrateItemMarkers == true then
        --this will raise a reloadui if you choose to not migrate any markers, so that the settings are updated properly and markers are shwown correctly
        FCOIS.preventerVars.migrateItemMarkersCalledFromPlayerActivated = true
        FCOIS.ShowAskBeforeMigrateDialog()
    else
        --Was any migration done and the reloadui after that had happened? Show the migration log then
        FCOIS.ShowMigrationDebugLog()
    end
end

-- Fires each time after addons were loaded and player is ready to move (after each zone change too)
local function FCOItemSaver_Player_Activated(...)
--d("[FCOIS]EVENT_PLAYER_ACTIVATED")
    --Prevent this event to be fired again and again upon each zone change
    em:UnregisterForEvent(gAddonName, EVENT_PLAYER_ACTIVATED)

    --Reset cached values
    resetMyGetItemInstanceIdLastVars()
    resetCreateFCOISUniqueIdStringLastVars()

    --Do not go on if libraries are not loaded properly
    if not FCOIS.libsLoadedProperly then
        --Output missing library text to chat
        local preVars = FCOIS.preChatVars
        local libMissingErrorText = FCOIS.errorTexts["libraryMissing"]
        --LibAddonMenu 2.0
        if FCOIS.LAM == nil then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibAddonMenu-2.0")) end
        --LibMainMenu 2.0
        if FCOIS.LMM2 == nil then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibMainMenu-2.0")) end
        --libFilters 3.x
        if not FCOIS.libFilters then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibFilters-3.0")) end
        --LibDialog
        if not FCOIS.LDIALOG then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibDialog")) end
        --LibFeedback
        if not FCOIS.libFeedback then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibFeedback")) end
        return
    end

    --Disable this addon if we are in GamePad mode
    if not FCOIS.FCOItemSaver_CheckGamePadMode(true) then
        local settings = FCOIS.settingsVars.settings
        if settings.debug then debugMessage( "[EVENT]","Player activated", true, FCOIS_DEBUG_DEPTH_NORMAL) end

        --Get the currently logged in character name
        FCOIS.currentlyLoggedInCharName = zo_strf(SI_UNIT_NAME, GetUnitName("player"))

        --Check if other Addons active now, as the addons should all have been loaded
        FCOIS.CheckIfOtherAddonsActiveAfterPlayerActivated()

        --Map the LibFilters panel IDs to their filter functions
        --> See file src/FCOIS_Filters.lua, function "FCOIS.mapLibFiltersIds2FilterFunctionsNow()"
        FCOIS.MapLibFiltersIds2FilterFunctionsNow()

        --Add/update the filter buttons, but only if not done already in addon initialization
        if FCOIS.addonVars.gAddonLoaded == false then
            updateFCOISFilterButtonsAtInventory(-1)
        end
        --FCOIS.addonVars.gAddonLoaded = false --If disabled here the LoadSettings function will get wrong values!

        --Rebuild the gear set variables like the mapping tables for the filter buttons, etc.
        --Must be called once before FCOIS.changeContextMenuEntryTexts(-1) to build the mapping tables + settings.iconIsGear!
        --3rd parameter "calledFromEventPlayerActivated" will tell the function to NOT call FCOIS.changeContextMenuEntryTexts internally
        --as it will be called with -1 (all icons) just below!
        rebuildGearSetBaseVars(nil, nil, true)

        --Overwrite the localized texts for the equipment gears, if changed in the settings
        FCOIS.ChangeContextMenuEntryTexts(-1)

        --Change the button color of the context menu invoker
        changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)

        --Check inventory for ornate, intricate, set parts, recipes, researchable items and mark them
        --but only scan once as addon loads
        if FCOIS.preventerVars.gAddonStartupInProgress then
            FCOIS.preventerVars.gAddonStartupInProgress = false
            --Delay the call to "scanInventory" so the other addons like CraftStoreFixedAndImproved are working properly with their research/recipe functions
            zo_callLater(function() scanInventory(nil, nil, settings.autoMarkBagsChatOutput) end, 500)
        end

        --Update the itemCount in the inventory sort headers, if needed
        FCOIS.UpdateFilteredItemCountThrottled(LF_INVENTORY, 50, "EVENT_Player_Activated")

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
    resetMyGetItemInstanceIdLastVars()
    resetCreateFCOISUniqueIdStringLastVars()

    --Libraries were loaded properly?
    if FCOIS.libsLoadedProperly then
        --Check if another addon name is found and thus active
        FCOIS.CheckIfOtherAddonActive(addOnName)
        --Check if gamepad mode is deactivated?
        --Is this addon found?
        if(addOnName ~= gAddonName) then
            return
        end
        if FCOIS.settingsVars.settings ~= nil and FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]","FCOItemSaver Loaded]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --d("[FCOIS -Event- FCOItemSaver_Loaded]")

        --Unregister this event again so it isn't fired again after this addon has beend recognized
        em:UnregisterForEvent(gAddonName, EVENT_ADD_ON_LOADED)

        --Create the LibDebugLogger loggers: See file src/FCOIS_debug.lua
        FCOIS.CreateLoggers()

        --Register for the zone change/player ready event
        em:RegisterForEvent(gAddonName, EVENT_PLAYER_ACTIVATED, FCOItemSaver_Player_Activated)

        if not FCOIS.FCOItemSaver_CheckGamePadMode(true) then

            if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]", "Addon loading begins...", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            FCOIS.addonVars.gAddonLoaded = false
            FCOIS.preventerVars.gAddonStartupInProgress = true

            --Register for Crafting stations opened & closed (integer eventCode,number craftSkill, boolean sameStation)
            em:RegisterForEvent(gAddonName, EVENT_CRAFTING_STATION_INTERACT, FCOItemSaver_Crafting_Interact)
            em:RegisterForEvent(gAddonName, EVENT_END_CRAFTING_STATION_INTERACT, FCOItemSaver_End_Crafting_Interact)
            em:RegisterForEvent(gAddonName, EVENT_CRAFT_STARTED, FCOItemSaver_Craft_Started)
            --Register for Store opened & closed
            em:RegisterForEvent(gAddonName, EVENT_OPEN_STORE, function() FCOItemSaver_Open_Store("vendor") end)
            em:RegisterForEvent(gAddonName, EVENT_CLOSE_STORE, FCOItemSaver_Close_Store)
            --Register for Trading house (guild store) opened & closed
            em:RegisterForEvent(gAddonName, EVENT_OPEN_TRADING_HOUSE, FCOItemSaver_Open_Trading_House)
            em:RegisterForEvent(gAddonName, EVENT_CLOSE_TRADING_HOUSE, FCOItemSaver_Close_Trading_House)
            --Register for Guild Bank opened & closed
            em:RegisterForEvent(gAddonName, EVENT_OPEN_GUILD_BANK, FCOItemSaver_Open_Guild_Bank)
            em:RegisterForEvent(gAddonName, EVENT_CLOSE_GUILD_BANK, FCOItemSaver_Close_Guild_Bank)
            --Register for Player's Bank opened & closed
            em:RegisterForEvent(gAddonName, EVENT_OPEN_BANK, FCOItemSaver_Open_Player_Bank)
            em:RegisterForEvent(gAddonName, EVENT_CLOSE_BANK, FCOItemSaver_Close_Player_Bank)
            --Register for Trade panel opened & closed
            em:RegisterForEvent(gAddonName, EVENT_TRADE_INVITE_ACCEPTED, FCOItemSaver_Open_Trade_Panel)
            --Register for player inventory slot update
            local bagIdsToFilterForInvSingleSlotUpdate = {
                BAG_BACKPACK,
                BAG_WORN,
                BAG_COMPANION_WORN,
            }
            for _, bagIdToFilter in ipairs(bagIdsToFilterForInvSingleSlotUpdate) do
                em:RegisterForEvent(gAddonName .. "_EVENT_INVENTORY_SINGLE_SLOT_UPDATE" ..tos(bagIdToFilter), EVENT_INVENTORY_SINGLE_SLOT_UPDATE, FCOItemSaver_Inv_Single_Slot_Update)
                em:AddFilterForEvent(gAddonName .. "_EVENT_INVENTORY_SINGLE_SLOT_UPDATE" ..tos(bagIdToFilter), EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_UNIT_TAG, "player")
                em:AddFilterForEvent(gAddonName .. "_EVENT_INVENTORY_SINGLE_SLOT_UPDATE" ..tos(bagIdToFilter), EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
                em:AddFilterForEvent(gAddonName .. "_EVENT_INVENTORY_SINGLE_SLOT_UPDATE" ..tos(bagIdToFilter), EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_IS_NEW_ITEM, true)
                em:AddFilterForEvent(gAddonName .. "_EVENT_INVENTORY_SINGLE_SLOT_UPDATE" ..tos(bagIdToFilter), EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_BAG_ID, bagIdToFilter)
            end
            --Register the callback function for an update of the inventory slots
            --SHARED_INVENTORY:RegisterCallback("SingleSlotInventoryUpdate", FCOItemSaver_OnSharedSingleSlotUpdate)
            --Events for destruction & destroy prevention
            em:RegisterForEvent(gAddonName, EVENT_INVENTORY_SLOT_LOCKED, FCOItemSaver_OnInventorySlotLocked)
            em:RegisterForEvent(gAddonName, EVENT_INVENTORY_SLOT_UNLOCKED, FCOItemSaver_OnInventorySlotUnLocked)
            em:RegisterForEvent(gAddonName, EVENT_MOUSE_REQUEST_DESTROY_ITEM, FCOItemSaver_OnMouseRequestDestroyItem)

            --ZO_Character - Drag & drop of items
            --em:RegisterForEvent(gAddonName, EVENT_CURSOR_PICKUP, FCOItemSaver_OnCursorPickup)
            em:RegisterForEvent(gAddonName, EVENT_CURSOR_DROPPED, FCOItemSaver_OnCursorDropped)

            --Event if an action layer changes
            --em:RegisterForEvent(gAddonName, EVENT_ACTION_LAYER_POPPED, FCOItemsaver_OnActionLayerPopped)
            --em:RegisterForEvent(gAddonName, EVENT_ACTION_LAYER_PUSHED, FCOItemsaver_OnActionLayerPushed)
            em:RegisterForEvent(gAddonName, EVENT_GAME_CAMERA_UI_MODE_CHANGED, FCOItemsaver_OnGameCameraUIModeChanged)
            --Guild bank is selected
            em:RegisterForEvent(gAddonName, EVENT_GUILD_BANK_SELECTED, FCOItemsaver_SelectGuildBank)
            --Retrait station is interacted with
            em:RegisterForEvent(gAddonName, EVENT_RETRAIT_STATION_INTERACT_START, FCOItemsaver_RetraitStationInteract)
            --Global mouse down/up event
            --[[
            em:RegisterForEvent(gAddonName, EVENT_GLOBAL_MOUSE_DOWN, FCOItemSaver_EventMouseButtonDown)
            em:RegisterForEvent(gAddonName, EVENT_GLOBAL_MOUSE_UP, FCOItemSaver_EventMouseButtonUp)
            ]]

            --=============================================================================================================
            --	LOAD USER SETTINGS
            --=============================================================================================================
            FCOIS.LoadUserSettings(false, true) --force load the settings again, if they were loaded before by any external addon

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
            updateFCOISFilterButtonsAtInventory(-1)

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
            autoReenableAntiSettingsCheck("-ALL-")

            --Set the addon loaded variable
            FCOIS.addonVars.gAddonLoaded = true

            --Do inventory keybinding stuff (for junk mark etc.)
            FCOIS.InitializeInventoryKeybind()

            --Load other things like library dependent actions
            --FCOIS.RegisterLibSetsCallbacks() --#301

            if FCOIS.settingsVars.settings.debug then debugMessage( "[EVENT]", "Addon startup finished!", true, FCOIS_DEBUG_DEPTH_NORMAL) end
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
    em:RegisterForEvent(gAddonName, EVENT_ADD_ON_LOADED, FCOItemSaver_Loaded)
end

