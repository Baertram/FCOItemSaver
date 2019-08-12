--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local ctrlVars = FCOIS.ZOControlVars

--===================================================================================
--	FCOIS Anti - *  - Methods to check if item is protected, or allowed to be ...
--===================================================================================

--Show an alert message
function FCOIS.showAlert(alertMsg)
    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, FCOIS.preChatVars.preChatTextRed .. alertMsg)
end

--Function to show an chat error message and/or alert message that the item is protected
--Check if alert or chat message should be shown
function FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
    --d("[FCOIS]outputItemProtectedMessage - bag: " .. tostring(bag) .. ", slot: " .. tostring(slot) .. ", whereAreWe: " .. tostring(whereAreWe) ..", overrideChatOutput: " .. tostring(overrideChatOutput) .. ", suppressChatOutput: " .. tostring(suppressChatOutput) .. ", overrideAlert: " .. tostring(overrideAlert) .. ", suppressAlert: " .. tostring(suppressAlert))
    if bag == nil or slot == nil then return false end
    if whereAreWe == nil then return false end
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    local retVar = false
    --Chat and/or alert message are enbaled or overwriting the settings is active?
    local chatOutputWished = not suppressChatOutput and (overrideChatOutput or FCOIS.settingsVars.settings.showAntiMessageInChat == true)
    local alertOutputWished = not suppressAlert and (overrideAlert or FCOIS.settingsVars.settings.showAntiMessageAsAlert == true)
    if chatOutputWished or alertOutputWished then
        --Get the itemLink
        local formattedItemName = GetItemLink(bag, slot)
        --Get the "whereAreWe" message text
        local whereAreWeToAlertmessageText = FCOIS.mappingVars.whereAreWeToAlertmessageText
        local whereAreWeMsgText = whereAreWeToAlertmessageText[whereAreWe] or "ERROR: Not allowed!"
        --d("whereAreWeMsgText: " .. tostring(whereAreWeMsgText))
        --Build the protected message text
        local protectedMsg = whereAreWeMsgText .. " [" .. formattedItemName .. "]"
        --Show the message in the chat window?
        if chatOutputWished then
            d(protectedMsg)
            retVar = true
        end
        --Show the message as alert message at the top-right corner?
        if alertOutputWished then
            FCOIS.showAlert(protectedMsg)
            retVar = true
        end
    end
    return retVar
end

--Function to check if a normal icon is protected, or a dynamic icon is protected
--checktype is the filterPanelId or the whereAreWe type from function ItemSelectionHandler
function FCOIS.checkIfProtectedSettingsEnabled(checkType, iconNr, isDynamicIcon, checkAntiDetails, whereAreWe)
    if checkType == nil then return false end
    if iconNr == nil then return false end
    isDynamicIcon = isDynamicIcon or false
    checkAntiDetails = checkAntiDetails or false
--d("[FCOIS.checkIfProtectedSettingsEnabled - checkType: " .. tostring(checkType) .. ", iconNr: " .. tostring(iconNr) .. ", checkAntiDetails: " .. tostring(checkAntiDetails) .. ", whereAreWe: " .. tostring(whereAreWe))
    local protectionVal = false
    --Local mapping array for the filter panel ID -> the anti-settings
    local settings = FCOIS.settingsVars.settings
    local protectionSettings = {
        [LF_CRAFTBAG]   				= settings.blockDestroying,
        [LF_VENDOR_BUY]   				= settings.blockVendorBuy,
        [LF_VENDOR_SELL]   				= settings.blockSelling,
        [LF_VENDOR_BUYBACK]   			= settings.blockVendorBuyback,
        [LF_VENDOR_REPAIR]   			= settings.blockVendorRepair,
        [LF_GUILDSTORE_SELL] 			= settings.blockSellingGuildStore,
        [LF_FENCE_SELL]					= settings.blockFence,
        [LF_FENCE_LAUNDER]				= settings.blockLaunder,
        [LF_SMITHING_REFINE] 			= settings.blockRefinement,
        [LF_SMITHING_DECONSTRUCT] 		= settings.blockDeconstruction,
        [LF_SMITHING_IMPROVEMENT]		= settings.blockImprovement,
        [LF_SMITHING_RESEARCH]			= true, 			                --Always say that items are blocked for research
        [LF_SMITHING_RESEARCH_DIALOG]	= settings.blockResearchDialog,
        [LF_JEWELRY_REFINE] 			= settings.blockJewelryRefinement,
        [LF_JEWELRY_DECONSTRUCT] 		= settings.blockJewelryDeconstruction,
        [LF_JEWELRY_IMPROVEMENT]		= settings.blockJewelryImprovement,
        [LF_JEWELRY_RESEARCH]			= true, 			                --Always say that items are blocked for research
        [LF_JEWELRY_RESEARCH_DIALOG]    = settings.blockJewelryResearchDialog,
        [LF_ENCHANTING_CREATION] 		= settings.blockEnchantingCreation,
        [LF_ENCHANTING_EXTRACTION] 		= settings.blockEnchantingExtraction,
        [LF_ALCHEMY_CREATION] 			= settings.blockAlchemyDestroy,
        [LF_MAIL_SEND] 					= settings.blockSendingByMail,
        [LF_TRADE] 						= settings.blockTrading,
        [LF_RETRAIT] 					= settings.blockRetrait,
        --Special entries for the call from ItemSelectionHandler() function's variable 'whereAreWe'
        [FCOIS_CON_CONTAINER_AUTOOLOOT]	= settings.blockAutoLootContainer,	--Auto loot container
        [FCOIS_CON_RECIPE_USAGE]		= settings.blockMarkedRecipes, 		--Recipe
        [FCOIS_CON_MOTIF_USAGE]			= settings.blockMarkedMotifs, 		--Racial style motif
        [FCOIS_CON_POTION_USAGE]		= settings.blockMarkedPotions, 		--Potion
        [FCOIS_CON_FOOD_USAGE]			= settings.blockMarkedFood, 		--Food
        [FCOIS_CON_CROWN_ITEM]			= settings.blockCrownStoreItems, 	--Crown store item
    }
    --The filterPanelIds which need to be checked for anti-destroy
    local filterPanelIdsCheckForAntiDestroy = FCOIS.checkVars.filterPanelIdsForAntiDestroy
    --For each entry in this anti-destroy check table add one line in libFiltersPanelIdToBlockSettings
    for libFiltersAntiDestroyCheckPanelId, _ in pairs(filterPanelIdsCheckForAntiDestroy) do
        protectionSettings[libFiltersAntiDestroyCheckPanelId] = settings.blockDestroying
    end

    -- Is CraftBagExtended addon active and are we at a subfilter panel of CBE (e.g. the mail CBE panel, where the anti-mail settings must be checked, and not the craftbag settings)?
    if FCOIS.gFilterWhereParent ~= nil then
        --d("Subfilter active: " .. tostring(FCOIS.gFilterWhereParent))
        checkType = FCOIS.gFilterWhereParent
    end
    --Dynamic icon or not?
    local icon2Dyn = FCOIS.mappingVars.iconIsDynamic
    --Dynamic icon?
    if isDynamicIcon or icon2Dyn[iconNr] then
        --d("Dynamic icon")
        --Get the protection
        protectionVal = settings.icon[iconNr].antiCheckAtPanel[checkType]
--d(">iconNr: " .. tostring(iconNr) .. ", checkAtPanelChecks: " .. tostring(protectionVal))
        --Is the dynamic icon protected at the current panel?
        if protectionVal then
            --The protective functions are not enabled (red flag is set in the inventory additional options flag icon, or the current panel got no additional inventory button, e.g. the crafting research tab or the research popup dialog)?
            local _, invAntiSettingsEnabled = FCOIS.getContextMenuAntiSettingsTextAndState(checkType, false)
            if not invAntiSettingsEnabled then
                --Check if the temporary disabling of the protection is enabled, if the user uses the inventory "flag" icon and sets it to red
                local isDynIconSettingForProtectionTemporaryDisabledByInvFlag = settings.icon[iconNr].temporaryDisableByInventoryFlagIcon or false
                if isDynIconSettingForProtectionTemporaryDisabledByInvFlag then
--The dynamic icon is temporary not protected at this panel!
--d(">>Dyn icon protection disabled by inventory flag icon!")
                    protectionVal = false
                end
            end
        end
    else
        --d("Non dynamic icon")
        --Non dynamic
        protectionVal = protectionSettings[checkType]
    end
    --============== SPECIAL ITEM & ICON CHECKS ====================================
    --Check details for the current filter panel too? e.g. check if items marked for deconstruction are allowed to be deconstructed at the deconstruction panel
    if checkAntiDetails and whereAreWe ~= nil then
        --After checking dynamic icon settings check the global extra checks now (e.g. if selling an icon at the vendor sell panel is allowed if the icon is marked with the 'sell' icon)
        --If current checked panel = sell or guild store sell or fence sell
        if (whereAreWe == FCOIS_CON_SELL or whereAreWe == FCOIS_CON_GUILD_STORE_SELL or whereAreWe == FCOIS_CON_FENCE_SELL) then
            --If current checked panel = guild store sell and the filterId equals = sell in guild store
            if (whereAreWe==FCOIS_CON_GUILD_STORE_SELL) then
                -- If the item is marked for guild store selling,
                -- and the settings to allow selling of marked guild store items is enabled -> Abort here
                if iconNr==FCOIS_CON_ICON_SELL_AT_GUILDSTORE then
                    if settings.allowSellingInGuildStoreForBlocked == true then
                        protectionVal = false
                    end
                elseif iconNr==FCOIS_CON_ICON_SELL then
                    if settings.allowSellingForBlocked == true then
                        protectionVal = false
                    end
                    --Is the item marked as intricate and the selling of intricate items in the guild store is enabled? -> Abort here
                elseif iconNr==FCOIS_CON_ICON_INTRICATE then
                    if settings.allowSellingGuildStoreForBlockedIntricate == true then
                        protectionVal = false
                    end
                end

            --If current checked panel not equals sell / sell at fence / sell at guildstore
            else
                -- and the item is marked for selling
                if (iconNr==FCOIS_CON_ICON_SELL) then
                    --If the settings to allow selling of marked items is enabled -> Abort here
                    if settings.allowSellingForBlocked == true then
                        protectionVal = false
                    --if filter Id equals "Ornate" and the item is marked for selling,
                    --and the settings to allow selling of marked ornate items is enabled -> Abort here
                    elseif settings.allowSellingForBlockedOrnate == true then
                        protectionVal = false
                    end

                --If current checked panel = sell or guild store sell or fence sell and filter Id equals "Intricate" and the item is marked as intricate,
                --and the settings to allow selling of marked Intricate items is enabled -> Abort here
                elseif iconNr==FCOIS_CON_ICON_INTRICATE then
                    --Selling of intricate marked items is allowed? -> Abort here
                    if settings.allowSellingForBlockedIntricate == true then
                        protectionVal = false
                    end
                end
            end

        --Improve icon and item or jewelry item, and settings allow them to be improved?
        elseif (iconNr==FCOIS_CON_ICON_IMPROVEMENT and (whereAreWe == FCOIS_CON_IMPROVE or whereAreWe == FCOIS_CON_JEWELRY_IMPROVE) and settings.allowImproveImprovement == true) then
            protectionVal = false
        --Extraction of glyphs or deconstruction of items/jewelry with deconstruction icon
        elseif (iconNr==FCOIS_CON_ICON_DECONSTRUCTION and (whereAreWe == FCOIS_CON_ENCHANT_EXTRACT or whereAreWe == FCOIS_CON_DECONSTRUCT or whereAreWe == FCOIS_CON_JEWELRY_DECONSTRUCT) and settings.allowDeconstructDeconstruction == true) then
            protectionVal = false
        --If current checked panel = deconstruction or jewelry deconstruction and the item is marked as intricate,
        --and the settings to allow deconstruction of marked Intricate items is enabled -> Abort here
        elseif (iconNr==FCOIS_CON_ICON_INTRICATE and (whereAreWe == FCOIS_CON_DECONSTRUCT or whereAreWe == FCOIS_CON_JEWELRY_DECONSTRUCT) and settings.allowDeconstructIntricate == true) then
            protectionVal = false
        --If the checked panel is the research popup dialog and the icon is the research icon
        elseif (iconNr==FCOIS_CON_ICON_RESEARCH and (whereAreWe == FCOIS_CON_RESEARCH_DIALOG or whereAreWe == FCOIS_CON_JEWELRY_RESEARCH_DIALOG) and settings.allowResearch == true) then
            protectionVal = false
        end
    end
    if protectionVal == nil then protectionVal = false end
--d(">Icon: " .. iconNr .. ", protection enabled: " .. tostring(protectionVal))
    return protectionVal
end

--Function to check if the item is marked ("protected") with the icon number. The icon must be enabled or the settings must tell to check disabled icons as well, in order to
--say the item is protected! No further settings are checked, so if you need to see if a marker icon is protected at a filterPanelId you need to use the function
--FCOIS.checkIfProtectedSettingsEnabled(checkType, iconNr, isDynamicIcon, checkAntiDetails, whereAreWe) instead
--2nd parameter itemId is the item's instance id or the unique item's id
--3rd parameter allows a handler like "gear" or "dynamic" to check all gear set or all dyanmic icons at once (in a loop)
--4th parameter addonName (String):	Can be left NIL! The unique addon name which was used to temporarily enable the uniqueIdm usage for the item checks.
-----                               -> See FCOIS API function "FCOIS.UseTemporaryUniqueIds(addonName, doUse)"
function FCOIS.checkIfItemIsProtected(iconId, itemId, checkHandler, addonName)
    if itemId == nil or (iconId == nil and checkHandler == nil) then return false end
--d("FCOIS.checkIfItemIsProtected -  iconId: " .. tostring(iconId) .. ", itemId: " .. tostring(FCOIS.SignItemId(itemId)) .. ", checkHandler: " .. tostring(checkHandler) .. ", addonName: " .. tostring(addonName))
    ------------------------------------------------------
    --	Check in a loop, for gear sets and dynamic icons:
    -------------------------------------------------------
    --If the check handler is given we need to check if it is an allowed one
    if checkHandler ~= nil and checkHandler ~= "" then
        local allowedCheckHandlers = FCOIS.checkHandlers
        if not allowedCheckHandlers[checkHandler] then return false end
        --Recursively check all the marker icons from the check handler range, e.g. all gear sets or all dynamic icons
        if checkHandler == "gear" then
            local itemIsProtectedWithGear = false
            local gearIcons = FCOIS.mappingVars.gearToIcon
            for _, gearIconNr in pairs(gearIcons) do
                if gearIconNr ~= nil then
                    local itemIsProtectedWithGearLoop = FCOIS.checkIfItemIsProtected(gearIconNr, itemId, nil, addonName)
                    --Is the current gear's icon protecting the item then return "protected" (true)
                    if itemIsProtectedWithGearLoop then return true end
                end
            end
            return itemIsProtectedWithGear

        elseif checkHandler == "dynamic" then
            local itemIsProtectedWithDynamic = false
            local dynamicIcons = FCOIS.mappingVars.dynamicToIcon
            for _, dynamicIconNr in pairs(dynamicIcons) do
                if dynamicIconNr ~= nil then
                    local itemIsProtectedWithDynamicLoop = FCOIS.checkIfItemIsProtected(dynamicIconNr, itemId, nil, addonName)
                    --Is the current dynamic's icon protecting the item then return "protected" (true)
                    if itemIsProtectedWithDynamicLoop then return true end
                end
            end
            return itemIsProtectedWithDynamic
        end
    end
    -------------------------------------------------------
    --	Check without loop (called from a loop mabye for gear sets and dynamic icons):
    -------------------------------------------------------
    --Item is not enabled
    local itemIsMarked
    local settings = FCOIS.settingsVars.settings
    local isIconEnabled = settings.isIconEnabled[iconId]
    --Is the item enabled, or is the item disabled and the setting to check disabled icons too is enabled?
    if (   (isIconEnabled)
            or (not isIconEnabled and settings.checkDeactivatedIcons) ) then
        --Workaround to return a not-marked icon, if the icon is disabled, so the icon won't be removed
        -- >> Set & unset in function "FCOIS.ClearOrRestoreAllMarkers"
        if (not isIconEnabled and FCOIS.preventerVars.doFalseOverride) then
--d("FCOIS.checkIfItemIsProtected - Icon is disabled -> will not be filtered here (but protected)!")
            return false
        end
        --Check if the item is marked with the icon
        itemIsMarked = FCOIS.markedItems[iconId][FCOIS.SignItemId(itemId, nil, nil, addonName)]
    end
    if itemIsMarked == nil then itemIsMarked = false end
    --d("FCOIS.checkIfItemIsProtected - itemIsMarked: " .. tostring(itemIsMarked))
    return itemIsMarked
end

--Check the filterPanelId and if it should be protected against destroy, even if the currently protectedSettings are
--different than "Anti destroy"
function FCOIS.ckeckFilterPanelForDestroyProtection(filterPanelId)
    local filterPanelToAntiDestroySetings = {
        [LF_VENDOR_REPAIR] = true,
    }
    local isProtected = filterPanelToAntiDestroySetings[filterPanelId] or false
    return isProtected
end

-- Fired when user selects an item to destroy.
-- Warns user if the item is marked with any of the filter icons
function FCOIS.DestroySelectionHandler(bag, slot, echo, parentControl)
    echo = echo or false
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[DestroySelectionHandler] Bag: " .. tostring(bag) .. ", Slot: " .. tostring(slot) ..", filterPanelId: " .. tostring(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_SPAM) end
    --Are we at the vendor repair panel?
    local isVendorRepair = FCOIS.IsVendorPanelShown(LF_VENDOR_REPAIR, false) or false
    --Are we coming from the character window?
    if not isVendorRepair and (bag == BAG_WORN and parentControl ~= nil) then
        FCOIS.preventerVars.gCheckEquipmentSlots = true
    end
--d("[DestroySelectionHandler] Bag: " .. tostring(bag) .. ", Slot: " .. tostring(slot) ..", echo: " .. tostring(echo) .. ", filterPanelId: " .. tostring(FCOIS.gFilterWhere) .. ", isVendorRepair: " ..tostring(isVendorRepair) .. ", checkEquipmentSlots: " .. tostring(FCOIS.preventerVars.gCheckEquipmentSlots))

    -- get (unique) instance id of the item
    local id = FCOIS.MyGetItemInstanceIdNoControl(bag, slot)

    -- if item is in any protection list, warn user
    for iconIdToCheck=1, numFilterIcons, 1 do
        if( FCOIS.checkIfItemIsProtected(iconIdToCheck, id) ) then
            --Check if the anti-settings are enabled (and if a dynamic icon is used)
            local isProtectedIcon = FCOIS.checkIfProtectedSettingsEnabled(FCOIS.gFilterWhere, iconIdToCheck)
            --FCOIS version 1.6.0
            --Local hack to change the protectionValue of icons to "true" if certain filterPanels are checked.
            --But only for the destroy checks!
            if not isProtectedIcon then isProtectedIcon = FCOIS.ckeckFilterPanelForDestroyProtection(FCOIS.gFilterWhere) end
            if isProtectedIcon then
                --Show alert message?
                if (echo == true) then
                    --Check if alert or chat message should be shown
                    --function FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                    FCOIS.outputItemProtectedMessage(bag, slot, FCOIS_CON_DESTROY, false, false, false, false)
                end
                return true
            end
        end
    end
    return false
end

--============================== ITEM SELECTION HANDLER ===================================================================================
--Determine which filterPanelId is currently active and set the whereAreWe variable
function FCOIS.getWhereAreWe(panelId, panelIdAtCall, bag, slot, isDragAndDrop, calledFromExternalAddon)
    --The number for the orientation (which filter panel ID and which sub-checks were done -> for the chat output and the alert message determination)
    local whereAreWe = FCOIS_CON_DESTROY
    --The current game's SCENE name (used for determining bank/guild bank deposit)
    local currentSceneName = SCENE_MANAGER.currentScene.name
    --Local settings pointer
    local settings = FCOIS.settingsVars.settings

    --======= FUNCTIONs ============================================================
    --Function to check a single item's type and get the whereAreWe panel ID
    local function checkSingleItemProtection(p_bag, p_slotIndex, whereAreWeBefore)
        if settings.debug then FCOIS.debugMessage( ">>checkSingleItemProtection - panelId: " .. tostring(panelId) .. ", whereAreWeBefore: " .. tostring(whereAreWeBefore), true, FCOIS_DEBUG_DEPTH_ALL) end
        if p_bag == nil or p_slotIndex == nil then return false end
        local locWhereAreWe = FCOIS_CON_DESTROY
        --Are we trying to open a container with autoloot on?
        if (FCOIS.isAutolootContainer(p_bag, p_slotIndex)) then
            locWhereAreWe = FCOIS_CON_CONTAINER_AUTOOLOOT
            --Read recipe?
        elseif (FCOIS.isItemType(p_bag, p_slotIndex, ITEMTYPE_RECIPE)) then
            locWhereAreWe = FCOIS_CON_RECIPE_USAGE
            --Read style motif?
        elseif (FCOIS.isItemType(p_bag, p_slotIndex, ITEMTYPE_RACIAL_STYLE_MOTIF)) then
            locWhereAreWe = FCOIS_CON_MOTIF_USAGE
            --Drink potion?
        elseif (FCOIS.isItemType(p_bag, p_slotIndex, ITEMTYPE_POTION)) then
            locWhereAreWe = FCOIS_CON_POTION_USAGE
            --Eat food?
        elseif (FCOIS.isItemType(p_bag, p_slotIndex, ITEMTYPE_FOOD)) then
            locWhereAreWe = FCOIS_CON_FOOD_USAGE
            --Use crown store item?
        elseif (FCOIS.isItemType(p_bag, p_slotIndex, ITEMTYPE_CROWN_ITEM) or FCOIS.isItemType(p_bag, p_slotIndex, ITEMTYPE_CROWN_REPAIR)) then
            locWhereAreWe = FCOIS_CON_CROWN_ITEM
            --Other items are allowed!
        else
            --If the panelId was given at the call set the whereAreWe type to the fallback to return false -> Allow the equip/usage of the item
            --Else use the "Anti-Destroy" method to allow the API function "FCOIS.IsDestroyLocked" to function correct
            if panelIdAtCall ~= nil then
                --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false" and allows the usage/equipping/etc.
                locWhereAreWe = FCOIS_CON_FALLBACK
            else
                --PanelId was NIL as the function got called.
                --Check if the function was called internally, or from another addon (by the help of API functions).
                if not calledFromExternalAddon then
                    --Called internally, no filterPanelId was given. Current filterPanelId is the globally active one FCOIS.gFilterWhere
                    --Could be called during drag&drop or doubleclick functions of the addon
                    if FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler then
                        --Return the fallback value "false" so the drag&drop/double click works and will not show "Destroy not allowed!"
                        --d(">SingleItemChecks: Drag&Drop handler -> whereAreWe = FCOIS_CON_FALLBACK")
                        locWhereAreWe = FCOIS_CON_FALLBACK
                        FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
                    end
                end
            end
        end
        if settings.debug then FCOIS.debugMessage( "<<< whereAreWeAfter: " .. tostring(locWhereAreWe), true, FCOIS_DEBUG_DEPTH_ALL) end
        return locWhereAreWe
    end

    --======= WhereAreWe determination ============================================================
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --CraftBagExtended at a mail send panel, the bank, guild bank, guild store, store or trade?
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    if FCOIS.otherAddons.craftBagExtendedActive and INVENTORY_CRAFT_BAG and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden()) then
        --Inside mail panel?
        if (not ctrlVars.MAIL_SEND.control:IsHidden() or FCOIS.gFilterWhereParent == LF_MAIL_SEND) then
            whereAreWe = FCOIS_CON_MAIL
            --Inside trading player 2 player panel?
        elseif (not ctrlVars.PLAYER_TRADE.control:IsHidden() or FCOIS.gFilterWhereParent == LF_TRADE) then
            whereAreWe = FCOIS_CON_TRADE
            --Are we at the store scene
        elseif currentSceneName == "store" then
            --Vendor buy
            if (FCOIS.gFilterWhereParent == LF_VENDOR_BUY or (not ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_BUY
                --Vendor sell
            elseif (FCOIS.gFilterWhereParent == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and not ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_SELL
                --Vendor buyback
            elseif (FCOIS.gFilterWhereParent == LF_VENDOR_BUYBACK or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and not ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_BUYBACK
                --Vendor repair
            elseif (FCOIS.gFilterWhereParent == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and not ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_REPAIR
            end
            --Inside guild store selling?
        elseif (not ctrlVars.GUILD_STORE:IsHidden() or FCOIS.gFilterWhereParent == LF_GUILDSTORE_SELL) then
            whereAreWe = FCOIS_CON_GUILD_STORE_SELL
            --[[
            --There is no CraftBag or CraftBagExtended at a guild bank withdraw panel!
            --Are we at a guild bank and trying to withdraw some items by double clicking it?
            elseif (not ctrlVars.GUILD_BANK:IsHidden() or FCOIS.gFilterWhereParent == LF_GUILDBANK_WITHDRAW) then
                --TODO: Why FCOIS_CON_SELL here for Guildstore withdraw??? To test!
                whereAreWe = FCOIS_CON_SELL
            ]]
            --Are we at the inventory/bank/guild bank/house bank and trying to use/equip/deposit an item?
        elseif (FCOIS.gFilterWhereParent == LF_BANK_DEPOSIT or FCOIS.gFilterWhereParent == LF_GUILDBANK_DEPOSIT or FCOIS.gFilterWhereParent == LF_HOUSE_BANK_DEPOSIT) then
            --Check if player or guild bank is active by checking current scene in scene manager
            if currentSceneName ~= nil and (currentSceneName == ctrlVars.bankSceneName or currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.houseBankSceneName) then
                --If bank/guild bank/house bank deposit tab is active
                if ctrlVars.BANK:IsHidden() and ctrlVars.GUILD_BANK:IsHidden() and ctrlVars.HOUSE_BANK:IsHidden() then
                    --If the item is double clicked + marked deposit it, instead of blocking the deposition
                    --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                    whereAreWe = FCOIS_CON_FALLBACK
                    --Abort the checks here as items are always allowed to deposit at the bank/guildbank deposit tab, even from the craftbag
                    --but only if you do not use the mouse drag&drop (or context menu destroy)
                    if not isDragAndDrop then return false end
                end
            end
            --Only do the item checks if the item should not be depositted at a bank/guild bank
            if whereAreWe ~= FCOIS_CON_FALLBACK then
                --Get the whereAreWe panel ID by checking the item's type etc. now
                whereAreWe = checkSingleItemProtection(bag, slot, whereAreWe)
            end
            --Are we in the normal craftbag?
        else
            whereAreWe = FCOIS_CON_CRAFTBAG_DESTROY
        end

        --------------------------------------------------------------------------------------------------------------------
        --------------------------------------------------------------------------------------------------------------------
        --------------------------------------------------------------------------------------------------------------------
        --No Craftbag panels
        --------------------------------------------------------------------------------------------------------------------
        --------------------------------------------------------------------------------------------------------------------
        --------------------------------------------------------------------------------------------------------------------
    else -- if FCOIS.otherAddons.craftBagExtendedActive and INVENTORY_CRAFT_BAG and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden()) then

        --Inside mail panel?
        if (not ctrlVars.MAIL_SEND.control:IsHidden() or panelId == LF_MAIL_SEND) then
            whereAreWe = FCOIS_CON_MAIL
            --Inside trading player 2 player panel?
        elseif (not ctrlVars.PLAYER_TRADE.control:IsHidden() or panelId == LF_TRADE) then
            whereAreWe = FCOIS_CON_TRADE
            --Are we at the store scene?
        elseif currentSceneName == "store" then
            --Vendor buy
            if (panelId == LF_VENDOR_BUY or (not ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_BUY
                --Vendor sell
            elseif (panelId == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and not ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_SELL
                --Vendor buyback
            elseif (panelId == LF_VENDOR_BUYBACK or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and not ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_BUYBACK
                --Vendor repair
            elseif (panelId == LF_VENDOR_REPAIR or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and not ctrlVars.REPAIR_LIST:IsHidden())) then
                whereAreWe = FCOIS_CON_REPAIR
            end
            --Fence/Launder scene
        elseif currentSceneName == "fence_keyboard" then
            --Inside fence sell?
            if ((FENCE_KEYBOARD ~= nil and FENCE_KEYBOARD.mode ~= nil and FENCE_KEYBOARD.mode == ZO_MODE_STORE_SELL_STOLEN) or panelId == LF_FENCE_SELL) then
                whereAreWe = FCOIS_CON_FENCE_SELL
                --Inside launder sell?
            elseif ((FENCE_KEYBOARD ~= nil and FENCE_KEYBOARD.mode ~= nil and FENCE_KEYBOARD.mode == ZO_MODE_STORE_LAUNDER) or panelId == LF_FENCE_LAUNDER) then
                whereAreWe = FCOIS_CON_LAUNDER_SELL
            end
            --Inside crafting station refinement
        elseif (not ctrlVars.REFINEMENT:IsHidden() or (panelId == LF_SMITHING_REFINE or panelId == LF_JEWELRY_DECONSTRUCT)) then
            local craftType = GetCraftingInteractionType()
            if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                whereAreWe = FCOIS_CON_JEWELRY_REFINE
            else
                whereAreWe = FCOIS_CON_REFINE
            end
            --Inside crafting station deconstruction
        elseif (not ctrlVars.DECONSTRUCTION:IsHidden() or (panelId == LF_SMITHING_DECONSTRUCT or panelId == LF_JEWELRY_DECONSTRUCT)) then
            local craftType = GetCraftingInteractionType()
            if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                whereAreWe = FCOIS_CON_JEWELRY_DECONSTRUCT
            else
                whereAreWe = FCOIS_CON_DECONSTRUCT
            end
            --Inside crafting station improvement
        elseif (not ctrlVars.IMPROVEMENT:IsHidden() or (panelId == LF_SMITHING_IMPROVEMENT or panelId == LF_JEWELRY_DECONSTRUCT)) then
            local craftType = GetCraftingInteractionType()
            if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                whereAreWe = FCOIS_CON_JEWELRY_IMPROVE
            else
                whereAreWe = FCOIS_CON_IMPROVE
            end
            --Are we at the crafting stations research panel's popup list dialog?
        elseif (FCOIS.isResearchListDialogShown() or (panelId == LF_SMITHING_RESEARCH_DIALOG or panelId == LF_JEWELRY_RESEARCH_DIALOG)) then
            local craftType = GetCraftingInteractionType()
            if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                whereAreWe = FCOIS_CON_JEWELRY_RESEARCH_DIALOG
            else
                whereAreWe = FCOIS_CON_RESEARCH_DIALOG
            end
            --Are we at the crafting stations research panel?
        elseif (not ctrlVars.RESEARCH:IsHidden() or (panelId == LF_SMITHING_RESEARCH or panelId == LF_JEWELRY_RESEARCH)) then
            local craftType = GetCraftingInteractionType()
            if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                whereAreWe = FCOIS_CON_JEWELRY_RESEARCH
            else
                whereAreWe = FCOIS_CON_RESEARCH
            end
            --Inside enchanting station
        elseif (not ctrlVars.ENCHANTING_STATION:IsHidden() or (panelId == LF_ENCHANTING_EXTRACTION or panelId == LF_ENCHANTING_CREATION)) then
            --Enchanting Extraction panel?
            if panelId == LF_ENCHANTING_EXTRACTION or ENCHANTING.enchantingMode == 2 then
                whereAreWe = FCOIS_CON_ENCHANT_EXTRACT
                --Enchanting Creation panel?
            elseif panelId == LF_ENCHANTING_CREATION or ENCHANTING.enchantingMode == 1 then
                whereAreWe = FCOIS_CON_ENCHANT_CREATE
            end
            --Inside guild store selling?
        elseif (not ctrlVars.GUILD_STORE:IsHidden() or panelId == LF_GUILDSTORE_SELL) then
            whereAreWe = FCOIS_CON_GUILD_STORE_SELL
            --Are we at the alchemy station?
        elseif (not ctrlVars.ALCHEMY_STATION:IsHidden() or panelId == LF_ALCHEMY_CREATION) then
            whereAreWe = FCOIS_CON_ALCHEMY_DESTROY
            --Are we at a bank and trying to withdraw some items by double clicking it?
        elseif (not ctrlVars.BANK:IsHidden() or panelId == LF_BANK_WITHDRAW) then
            --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
            whereAreWe = FCOIS_CON_FALLBACK
        elseif (not ctrlVars.HOUSE_BANK:IsHidden() or panelId == LF_HOUSE_BANK_WITHDRAW) then
            --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
            whereAreWe = FCOIS_CON_FALLBACK
            --Are we at a guild bank and trying to withdraw some items by double clicking it?
        elseif (not ctrlVars.GUILD_BANK:IsHidden() or panelId == LF_GUILDBANK_WITHDRAW) then
            --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
            whereAreWe = FCOIS_CON_FALLBACK
            --Are we at a transmutation/retrait station?
        elseif (FCOIS.isRetraitStationShown() or panelId == LF_RETRAIT) then
            --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
            whereAreWe = FCOIS_CON_RETRAIT
            --Are we at the inventory/bank/guild bank and trying to use/equip/deposit an item?
        elseif (not ctrlVars.BACKPACK:IsHidden() or panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT) then
            --Check if player or guild bank is active by checking current scene in scene manager
            if currentSceneName ~= nil and (currentSceneName == ctrlVars.bankSceneName or currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.houseBankSceneName) then
                --If bank/guild bank deposit tab is active
                if ctrlVars.BANK:IsHidden() and ctrlVars.GUILD_BANK:IsHidden() and ctrlVars.HOUSE_BANK:IsHidden() then
                    --If the item is double clicked + marked deposit it, instead of blocking the deposition
                    --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                    whereAreWe = FCOIS_CON_FALLBACK
                    --Abort the checks here as items are always allowed to deposit at the bank/guildbank deposit tab
                    --but only if you do not use the mouse drag&drop (or context menu destroy)
                    if not isDragAndDrop then return false end
                end
            end
            --Only do the item checks if the item should not be deposited at a bank/guild bank
            if whereAreWe ~= FCOIS_CON_FALLBACK then
                --Get the whereAreWe panel ID by checking the item's type etc. now
                whereAreWe = checkSingleItemProtection(bag, slot)
            end
            --All others: We are trying to destroy an item
        else
            whereAreWe = FCOIS_CON_DESTROY
        end
    end --if FCOIS.otherAddons.craftBagExtendedActive and INVENTORY_CRAFT_BAG and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden()) then
    return whereAreWe
end

-- Fired when user selects an item by drag&drop, doubleclick etc.
-- Warns user if the item is marked with any of the filter icons and if the marked icon protects the item at teh current filterPanelId
function FCOIS.ItemSelectionHandler(bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
    if bag == nil or slot == nil then return true end
    echo = echo or false
    isDragAndDrop = isDragAndDrop or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    calledFromExternalAddon = calledFromExternalAddon or false

    local settings = FCOIS.settingsVars.settings

    if settings.debug then FCOIS.debugMessage( "[ItemSelectionHandler] Bag: " .. tostring(bag) .. ", Slot: " .. tostring(slot) .. ", echo: " .. tostring(echo) .. ", isDragAndDrop: " .. tostring(isDragAndDrop) .. ", overrideChatOutput: " .. tostring(overrideChatOutput) .. ", suppressChatOutput: " .. tostring(suppressChatOutput) .. ", overrideAlert: " .. tostring(overrideAlert) .. ", suppressAlert: " .. tostring(suppressAlert) .. ", calledFromExternalAddon: " .. tostring(calledFromExternalAddon) .. ", panelId: " .. tostring(panelId), true, FCOIS_DEBUG_DEPTH_SPAM) end
--d("[FCOIS]ItemSelectionHandler - Bag: " .. tostring(bag) .. ", Slot: " .. tostring(slot) .. ", Echo: " .. tostring(echo) .. ", overrideChatOutput: " .. tostring(overrideChatOutput) .. ", suppressChatOutput: " .. tostring(suppressChatOutput) .. ", overrideAlert: " .. tostring(overrideAlert) .. ", suppressAlert: " .. tostring(suppressAlert) .. ", calledFromExternalAddon: " .. tostring(calledFromExternalAddon) .. ", panelId: " .. tostring(panelId))

    --Panel at the call of the function
    local panelIdAtCall = panelId

    --======= MAPPING ==============================================================
    --The mapping table for the filter panel ID which is needed for the dynamic icon checks later
    local whereAreWeToFilterPanelId = FCOIS.mappingVars.whereAreWeToFilterPanelId
    --Mapping array for the whereAreWe to anti-settings. Returns the anti-settings from the current settings, or false (not protected) as a constant if there is no anti-setting available.
    --The constant false values will be taken care of in other checks after this table check was done then.
    local whereAreWeToIsBlocked = {
        [FCOIS_CON_DESTROY]				= settings.blockDestroying,			    --Destroying
        [FCOIS_CON_MAIL]				= settings.blockSendingByMail,     	    --Mail send
        [FCOIS_CON_TRADE]				= settings.blockTrading,				--Trading
        [FCOIS_CON_BUY]				    = settings.blockVendorBuy,              --Vendor buy
        [FCOIS_CON_SELL]				= settings.blockSelling,                --Vendor sell
        [FCOIS_CON_BUYBACK]				= settings.blockVendorBuyback,          --Vendor buyback
        [FCOIS_CON_REPAIR]				= settings.blockVendorRepair,           --Vendor repair
        [FCOIS_CON_REFINE]				= settings.blockRefinement,			    --Refinement,
        [FCOIS_CON_DECONSTRUCT]			= settings.blockDeconstruction,		    --Deconstruction
        [FCOIS_CON_IMPROVE]				= settings.blockImprovement,			--Improvement
        [FCOIS_CON_RESEARCH]			= true, 								--Research -> Always return true as there is no special option for anti-research and the protection is on
        [FCOIS_CON_RESEARCH_DIALOG] 	= true, 								--Research dialog -> Always return true as there is no special option for anti-research and the protection is on
        [FCOIS_CON_JEWELRY_REFINE]		= settings.blockJewelryRefinement,		--Jewelry Refinement,
        [FCOIS_CON_JEWELRY_DECONSTRUCT]	= settings.blockJewelryDeconstruction,	--Jewelry Deconstruction
        [FCOIS_CON_JEWELRY_IMPROVE]		= settings.blockJewelryImprovement,		--Jewelry Improvement
        [FCOIS_CON_JEWELRY_RESEARCH]    = true, 								--Jewelry research -> Always return true as there is no special option for anti-jewelry research and the protection is on
        [FCOIS_CON_JEWELRY_RESEARCH_DIALOG] = true, 							--Jewelry research dialog -> Always return true as there is no special option for anti-jewelry research and the protection is on
        [FCOIS_CON_ENCHANT_EXTRACT]		= settings.blockEnchantingExtraction,   --Enchanting extraction
        [FCOIS_CON_ENCHANT_CREATE]		= settings.blockEnchantingCreation,	    --Enchanting creation
        [FCOIS_CON_GUILD_STORE_SELL]	= settings.blockSellingGuildStore,	    --Guild store sell
        [FCOIS_CON_FENCE_SELL]			= settings.blockFence,                  --Fence sell
        [FCOIS_CON_LAUNDER_SELL]		= settings.blockLaunder,			    --Fence launder
        [FCOIS_CON_ALCHEMY_DESTROY]		= settings.blockAlchemyDestroy,		    --Alchemy destroy
        [FCOIS_CON_CONTAINER_AUTOOLOOT]	= settings.blockAutoLootContainer,	    --Auto loot container
        [FCOIS_CON_RECIPE_USAGE]   		= settings.blockMarkedRecipes, 		    --Recipe
        [FCOIS_CON_MOTIF_USAGE]			= settings.blockMarkedMotifs, 		    --Racial style motif
        [FCOIS_CON_POTION_USAGE]		= settings.blockMarkedPotions, 		    --Potion
        [FCOIS_CON_FOOD_USAGE]	   		= settings.blockMarkedFood, 		    --Food
        [FCOIS_CON_CROWN_ITEM]	   		= settings.blockCrownStoreItems, 		--Crown store items
        [FCOIS_CON_CRAFTBAG_DESTROY]	= settings.blockDestroying, 		    --Craftbag, destroying
        [FCOIS_CON_RETRAIT]	            = settings.blockRetrait, 			    --Retrait station, retrait
        [FCOIS_CON_FALLBACK]			= false,							    --Always return false. Used e.g. for the bank/guild bank deposit checks
    }
    --Mapping array for the alertMessages
    --local whereAreWeToAlertmessageText = FCOIS.mappingVars.whereAreWeToAlertmessageText
    --The mapping array to skip the dyanmic icon checks, as the whereAreWe filter panel ID is related to single item checks!
    local whereAreWeToSingleItemChecks = {
        [FCOIS_CON_CONTAINER_AUTOOLOOT]	= true,	--Auto loot container
        [FCOIS_CON_RECIPE_USAGE]		= true, --Recipe
        [FCOIS_CON_MOTIF_USAGE]			= true, --Racial style motif
        [FCOIS_CON_POTION_USAGE]		= true, --Potion
        [FCOIS_CON_FOOD_USAGE]			= true, --Food
        [FCOIS_CON_CROWN_ITEM]			= true, --Crown store item
    }
    --======= VARIABLEs ============================================================
    --The return value for this function, initiated with "true" = "block"
    local isBlocked = true
    -- Get instance id of the item
    local id = FCOIS.MyGetItemInstanceIdNoControl(bag, slot)
    if id == nil then return false end
    --The return variable for the "check all icons" for ... loop
    local isBlockedLoop = false
    --The return variable for "is any marker icon set?"
    local markedWithOneIcon = false
    --The filterPanelId was specified in the parameters? Or not, then use the current filterPanelId the addon stores
    panelId = panelId or FCOIS.gFilterWhere

    --======= WHERE ARE WE? ========================================================
    --The number for the orientation (which filter panel ID and which sub-checks were done -> for the chat output and the alert message determination)
    local whereAreWe = FCOIS.getWhereAreWe(panelId, panelIdAtCall, bag, slot, isDragAndDrop, calledFromExternalAddon)

    --======= GLOBAL ANTI-CHECKs ===================================================
    --Get the anti-settings for the whereAreWe panel number now
    isBlocked = whereAreWeToIsBlocked[whereAreWe]
    --Check if single items checks should be done (like "check a recipe" or "potion")
    local singleItemChecks = whereAreWeToSingleItemChecks[whereAreWe]

--d(">Where are we: " .. tostring(whereAreWe) .. ", isBlocked: " .. tostring(isBlocked) .. ", singleItemChecks: " .. tostring(singleItemChecks) .. ", panelId: " .. tostring(panelId))

    --======= SPECIAL CHECKS - RECIPES, STYLE MOTIFS, FOOD =========================
    -- Check if the recipe/style motif/food/crown store item is not protected because the current anti-destroy option is disabled
    -- by help of the addiitonal inventory options flag icon (red flag)
    if panelId == LF_INVENTORY and singleItemChecks then
        --See if the Anti-settings for the given panel are enabled or not
        --The protective functions are not enabled (red flag in the inventory additional options flag icon or the current panel got no additional inventory button, e.g. the crafting research tab)
        local _, invAntiSettingsEnabled = FCOIS.getContextMenuAntiSettingsTextAndState(panelId, false)
        if not invAntiSettingsEnabled then
            --Using/eating/drinking items for marked items is blocked, e.g. for recipes/style motifs?
            --If the settings allow it: Change the blocked state to unblocked upon right-clicking the inventory additional options flag icon
            --Recipes
            if whereAreWe == FCOIS_CON_RECIPE_USAGE and settings.blockMarkedRecipesDisableWithFlag then
                --Using the recipe by help of a doubleclick is allowed
                --d("[FCOIS] ItemSelectionHandler - Recipe is allowed with doubleclick")
                return false
            end
            --Style motifs
            if whereAreWe == FCOIS_CON_MOTIF_USAGE and settings.blockMarkedMotifsDisableWithFlag then
                --Using the style motif by help of a doubleclick is allowed
                --d("[FCOIS] ItemSelectionHandler - Style motif is allowed with doubleclick")
                return false
            end
            --Drink & food
            if (whereAreWe == FCOIS_CON_FOOD_USAGE or whereAreWe == FCOIS_CON_POTION_USAGE) and settings.blockMarkedFoodDisableWithFlag then
                --Using the food by help of a doubleclick is allowed
                --d("[FCOIS] ItemSelectionHandler - Potion/Food is allowed with doubleclick")
                return false
            end
            --Autoloot container
            if whereAreWe == FCOIS_CON_CONTAINER_AUTOOLOOT and settings.blockMarkedAutoLootContainerDisableWithFlag then
                --Using the auto loot container by help of a doubleclick is allowed
                --d("[FCOIS] ItemSelectionHandler - Autloot container is allowed with doubleclick")
                return false
            end
            --Crown store items
            if whereAreWe == FCOIS_CON_CROWN_ITEM and settings.blockMarkedCrownStoreItemDisableWithFlag then
                --Using the crown store item by help a doubleclick is allowed
                --d("[FCOIS] ItemSelectionHandler - Crown store item is allowed with doubleclick")
                return false
            end
        end -- if not invAntiSettingsEnabled then
    end

    --======= CHECKs AGAINST ICONs =================================================
    -- If item is in any protection list, warn user.
    -- First check all marker icons on the item now:
    local mappedIsDynIcon = FCOIS.mappingVars.iconIsDynamic
    for iconIdToCheck=1, numFilterIcons, 1 do
--d("[FCOIS]ItemSelectionHandler - icon: " .. iconIdToCheck)
        --Check if the item is marked with the icon
        if( FCOIS.checkIfItemIsProtected(iconIdToCheck, id) ) then
            markedWithOneIcon = true
            local isDynamicIcon = mappedIsDynIcon[iconIdToCheck]
--d(">> Item is protected with the icon " .. iconIdToCheck .. ", isDynamic: " .. tostring(isDynamicIcon))
            --Reset the return variable for each icon again to the global block variable!
            isBlockedLoop = isBlocked
            --Is the current filterPanelId not 99 (fallback, e.g. bank withdraw or bank deposit, guild bank withdraw or guild bank deposit, ...)
            --Return the global setting "isBlocked" then so the ItemDestroyHandler is managing the anti-destroy functions!
            if whereAreWe ~= FCOIS_CON_FALLBACK then
                --d(">>WhereAreWe <> FCOIS_CON_FALLBACK")
                --Check if the current icon in the loop is an dynamic icon which can have special anti-settings (icon depending, not overall check depending!)
                --============== DYNAMIC ICON CHECKS - START ===================================
                --Is the icon a dynamic icon?
                if isDynamicIcon then
--d(">>> dynamic icon")
                    --The filterPanelId (determined by whereAreWe) given to function FCOIS.checkIfProtectedSettingsEnabled here is just LF_INVENTORY for the item related checks
                    --(recipes, autoloot container, bank deposit, guild bank deposit, etc.)
                    --This would return the wrong settings and thus it is checked before, if the whereAreWe panel id is related to single item checks.
                    --If so: The dynamic icon checks are not executed, but only the before checked single item check settings value is returned again by the help of whereAreWeToIsBlocked[whereAreWe]
                    if not singleItemChecks then
                        --Check the settings again now to see if this icon's dyanmic anti-settings are enabled for the given panel "whereAreWe"
                        --Call with 3rd parameter "isDynamicIcon" = true to skip "is dynamic icon check" inside the function again
                        isBlockedLoop = FCOIS.checkIfProtectedSettingsEnabled(whereAreWeToFilterPanelId[whereAreWe], iconIdToCheck, true)
--d(">>>> Dyn 1, isBlockedLoop: " .. tostring(isBlockedLoop))
                    end
                    --Does the dynamic icon block the item and was it not globally blocked before?
                    --Then we need to check some global stuff from before again (like the item's type -> recipe/autoloot container/style motif/potion/food/etc.)
                    --and return the settings from there to get the 'real' anti-settings block state
                    if singleItemChecks and (isBlockedLoop ~= isBlocked) then
--d(">>>> Dyn 2, singleItemChecks: " .. tostring(singleItemChecks) .. ", isBlocked: " .. tostring(isBlocked))
                        --The dynmic icon is blocking but the global settings did not block before.
                        --Check the whereAreWe settings again now, to get special settings for the autoloot container/recipes/etc.
                        isBlockedLoop = isBlocked
                    end
                end
                --============== DYNAMIC ICON CHECKS - END =====================================
            end -- if not whereAreWe == FCOIS_CON_FALLBACK then
            --============== SPECIAL ITEM & ICON CHECKS - START (non-dynamic!) ====================================
            if not isDynamicIcon then
                --After checking dynamic icon settings check the global extra checks now (e.g. if selling an icon at the vendor sell panel is allowed if the icon is marked with the 'sell' icon)
                --If current checked panel = sell or guild store sell or fence sell
                if (whereAreWe == FCOIS_CON_SELL or whereAreWe == FCOIS_CON_GUILD_STORE_SELL or whereAreWe == FCOIS_CON_FENCE_SELL) then
                    --If current checked panel = sell and the item is marked for selling
                    if (iconIdToCheck==FCOIS_CON_ICON_SELL) then
                        --If the settings to allow selling of marked items is enabled -> Abort here
                        if settings.allowSellingForBlocked == true then
                            isBlockedLoop = false
                        --if filter Id equals "Ornate" and the item is marked for selling,
                        --and the settings to allow selling of marked ornate items is enabled
                        --and the item is ornate -> Abort here
                        elseif settings.allowSellingForBlockedOrnate == true and FCOIS.isItemOrnate(bag, slot) then
                            isBlockedLoop = false
                        end
                    --If current checked panel = guild store sell and the filterId equals = sell in guild store and the item is marked for guild store selling,
                    --and the settings to allow selling of marked guild store items is enabled -> Abort here
                    elseif (iconIdToCheck==FCOIS_CON_ICON_SELL_AT_GUILDSTORE and whereAreWe==FCOIS_CON_GUILD_STORE_SELL and settings.allowSellingInGuildStoreForBlocked == true) then
                        --d(">>selling non-dynamic at guild store is allowed!")
                        isBlockedLoop = false
                    --If current checked panel = sell or guild store sell or fence sell and filter Id equals "Intricate" and the item is marked as intricate,
                    --and the settings to allow selling of marked intricate items is enabled -> Abort here
                    elseif (iconIdToCheck==FCOIS_CON_ICON_INTRICATE) then
                       if whereAreWe==FCOIS_CON_GUILD_STORE_SELL then
                           if settings.allowSellingGuildStoreForBlockedIntricate == true then
                               isBlockedLoop = false
                           end
                       else
                           if settings.allowSellingForBlockedIntricate == true then
                               isBlockedLoop = false
                           end
                       end
                    end
                --Improve icon and item or jewelry item, and settings allow them to be improved?
                elseif (iconIdToCheck==FCOIS_CON_ICON_IMPROVEMENT and (whereAreWe == FCOIS_CON_IMPROVE or whereAreWe == FCOIS_CON_JEWELRY_IMPROVE) and settings.allowImproveImprovement == true) then
                    isBlockedLoop = false
                --Extraction of glyphs with deconstruction item
                elseif (iconIdToCheck==FCOIS_CON_ICON_DECONSTRUCTION and whereAreWe == FCOIS_CON_ENCHANT_EXTRACT and settings.allowDeconstructDeconstruction == true) then
                    --Check if the itemtype is a glyph
                    isBlockedLoop = not FCOIS.isItemAGlpyh(bag, slot)
                    --d(">>IsItemAGlpyh: " .. tostring(not isBlockedLoop) .. ", isBlockedLoop: " .. tostring(isBlockedLoop))
                --Research and research marker icon is allowed to be used?
                elseif (iconIdToCheck==FCOIS_CON_ICON_RESEARCH and whereAreWe == FCOIS_CON_RESEARCH and settings.allowResearch == true) then
                    isBlockedLoop = false
                end
                --============== SPECIAL ITEM & ICON CHECKS - END (non-dynamic) ====================================
            end --	if not isDynamicIcon then
            --======= ITEM IS BLOCKED ! - START ============================================
            --Abort here if at least one marker icon was set and it is protecting the item!
            if isBlockedLoop == true then
--d("isBlockedLoop: true -> Item is protected!")
                --Show text in chat or alert message now?
                if echo == true then
                    --d(">item echo - whereAreWe: " .. tostring(whereAreWe) .. ", overrideChatOutput: " .. tostring(overrideChatOutput) .. ", suppressChatOutput: " .. tostring(suppressChatOutput) .. ", overrideAlert: " .. tostring(overrideAlert) .. ", suppressAlert: " .. tostring(suppressAlert))
                    --Check if alert or chat message should be shown
                    FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                end
                --Abort here as at least 1 icon is marked for the current item and the protection for this icon (globally or dynamically per icon) is enabled here!
                return true
            end -- if isBlockedLoop == true
            --======= ITEM IS BLOCKED ! - END ==============================================
        end -- if( FCOIS.checkIfItemIsProtected(iconIdToCheck, id) ) then
    end -- for

    --======= RETURN ===============================================================
    --Is the item marked with any of the marker icons? Don't block it
    if not markedWithOneIcon and (isBlockedLoop or isBlocked) then
--d("not marked with one icon -> Abort 'false'")
        return false
    end
    --Were all icons checked and everything was not blocked? Then return false to unblock the icon
    if not isBlockedLoop then
--d("not blocked in loop -> Abort 'false'")
        return false
    end
    --Else return the global block value from before the icon checks
--d("return isBlocked: " .. tostring(isBlocked))
    return isBlocked
end -- ItemSelectionHandler


--=============== DECONSTRUCTION SELECTION HANDLER ========================================================================================
-- fired when user selects an item to deconstruct
-- warns user if the item is marked with any of the filter icons
function FCOIS.DeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
    if bag == nil or slot == nil then return true end
    echo = echo or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false

    local settings = FCOIS.settingsVars.settings

    if settings.debug then FCOIS.debugMessage( "[DeconstructionSelectionHandler] Bag: " .. tostring(bag) .. ", Slot: " .. tostring(slot) .. ", echo: " .. tostring(echo) .. ", overrideChatOutput: " .. tostring(overrideChatOutput) .. ", suppressChatOutput: " .. tostring(suppressChatOutput) .. ", overrideAlert: " .. tostring(overrideAlert) .. ", suppressAlert: " .. tostring(suppressAlert) .. ", calledFromExternalAddon: " .. tostring(calledFromExternalAddon) .. ", panelId: " .. tostring(panelId), true, FCOIS_DEBUG_DEPTH_SPAM) end
    --> GOT HERE FROM CONTEXT MENU ENTRY FOR "ADD ITEM TO CRAFT" e.g.
    -- Is user not at the deconstruction panel or the panelId is given from the function call but it is NOT the deconstruction panel at a crafting station?
    --Get the current craftingtype
    local craftingTypeIsDeconstuctable = false
    local craftingType
    if calledFromExternalAddon then
        local craftingTypesWithDeconstruction = {
            [CRAFTING_TYPE_BLACKSMITHING] = true,
            [CRAFTING_TYPE_CLOTHIER] = true,
            [CRAFTING_TYPE_JEWELRYCRAFTING] = true,
            [CRAFTING_TYPE_WOODWORKING] = true,
        }
        craftingType = GetCraftingInteractionType()
        craftingTypeIsDeconstuctable = craftingTypesWithDeconstruction[craftingType] or false
    end
    local noDeconstructionShouldBeDone = true
    if (ctrlVars.DECONSTRUCTION_BAG ~= nil and not ctrlVars.DECONSTRUCTION_BAG:IsHidden()) or (calledFromExternalAddon and craftingTypeIsDeconstuctable) or (panelId ~= nil and (panelId == LF_SMITHING_DECONSTRUCT or panelId == LF_JEWELRY_DECONSTRUCT)) then
        noDeconstructionShouldBeDone = false
    end

--d("[FCOIS]DeconstructionSelectionHandler - panelId: " ..tostring(panelId) .. ", calledFromExternalAddon: " ..tostring(calledFromExternalAddon) .. "->craftingType: " .. tostring(craftingType) .. ", craftingTypeIsDeconstuctable: " ..tostring(craftingTypeIsDeconstuctable).. ", noDeconstructionShouldBeDone: " ..tostring(noDeconstructionShouldBeDone))
    --Call the itemSelectionHandler for everything else then Deconstruction now?
    if( noDeconstructionShouldBeDone ) then
        --d("No deconstruction ->  Use ItemSelectionHandler")
        if ( calledFromExternalAddon
                or (not ctrlVars.ALCHEMY_STATION:IsHidden() or FCOIS.gFilterWhere == LF_ALCHEMY_CREATION or (calledFromExternalAddon and (panelId==LF_ALCHEMY_CREATION)))
                or (not ctrlVars.ENCHANTING_STATION:IsHidden() or FCOIS.gFilterWhere == LF_ENCHANTING_CREATION or FCOIS.gFilterWhere == LF_ENCHANTING_EXTRACTION or (calledFromExternalAddon and (panelId==LF_ENCHANTING_CREATION or panelId==LF_ENCHANTING_EXTRACTION)))
                or (FCOIS.craftingPrevention.IsShowingRefinement() or FCOIS.gFilterWhere == LF_SMITHING_REFINE or FCOIS.gFilterWhere == LF_JEWELRY_REFINE or (calledFromExternalAddon and (panelId==LF_SMITHING_REFINE or panelId==LF_JEWELRY_REFINE)))
                or (FCOIS.craftingPrevention.IsShowingImprovement() or FCOIS.gFilterWhere == LF_SMITHING_IMPROVEMENT or FCOIS.gFilterWhere == LF_JEWELRY_IMPROVEMENT or (calledFromExternalAddon and (panelId==LF_SMITHING_IMPROVEMENT or panelId==LF_JEWELRY_IMPROVEMENT)))
                or (FCOIS.craftingPrevention.IsShowingResearch() or FCOIS.gFilterWhere == LF_SMITHING_RESEARCH or FCOIS.gFilterWhere == LF_JEWELRY_RESEARCH or (calledFromExternalAddon and (panelId==LF_SMITHING_RESEARCH or panelId==LF_JEWELRY_RESEARCH)))
                or (FCOIS.isResearchListDialogShown() or FCOIS.gFilterWhere == LF_SMITHING_RESEARCH_DIALOG or FCOIS.gFilterWhere == LF_JEWELRY_RESEARCH_DIALOG or (calledFromExternalAddon and (panelId==LF_SMITHING_RESEARCH_DIALOG or panelId==LF_JEWELRY_RESEARCH_DIALOG)))
                or (FCOIS.isRetraitStationShown() or FCOIS.gFilterWhere == LF_RETRAIT or (calledFromExternalAddon and panelId==LF_RETRAIT))
        ) then
            --or (not ctrlVars.GUILD_STORE:IsHidden() or FCOIS.gFilterWhere == LF_GUILDSTORE_SELL) ) then
            return FCOIS.callItemSelectionHandler(bag, slot, echo, false, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, false, panelId)
        else
            return false
        end
    end
    --Call the deconstruction handler stuff now for deconstruction!
    --The mapping table for the current deconstruction panel
    local deconPanelToBlockSettings = {
        [LF_SMITHING_DECONSTRUCT]   = settings.blockDeconstruction,
        [LF_JEWELRY_DECONSTRUCT]    = settings.blockJewelryDeconstruction,
    }
    -- get instance id of the item, this value is persistant across all game
    local id = FCOIS.MyGetItemInstanceIdNoControl(bag, slot)
    if id == nil then return false end
    --Is the panelId given? If not determine it
    local inventoryVar
    if panelId == nil then
        inventoryVar, panelId = FCOIS.checkActivePanel(nil, false)
    end
    -- If anti-(jewelry) deconstruction is globally active
    local isBlocked = deconPanelToBlockSettings[panelId] or false
--d("[FCOIS]DeconstructionSelectionHandler - panelId: " ..tostring(panelId) .. ", isBlocked: " ..tostring(isBlocked))
    --> We cannot return false here if deconstruction is globally enabled because the dynamic icons have their own checks for deconstruction/jewelry deconstruction

    local isBlockedLoop = true
    local isAnyIconProtected = false
    local markedWithOneIcon = false
    -- if item is in any protection list, warn user
    for iconToCheck=1, numFilterIcons, 1 do
        --d(">checking icon: " .. iconToCheck)
        --Is the item marked with an icon?
        if FCOIS.checkIfItemIsProtected(iconToCheck, id) then
            --d(">> Decon: Item is protected with the icon " .. iconToCheck)
            markedWithOneIcon = true
            --Reset the return variable for each icon again to the global block variable!
            isBlockedLoop = isBlocked
            --Check if the current icon in the loop is an dynamic icon which can have special anti-settings (icon depending, not overall check depending!)
            local isDynamicIcon = FCOIS.mappingVars.iconIsDynamic[iconToCheck]
            --============== DYNAMIC ICON CHECKS - START ===================================
            --Is the icon a dynamic icon?
            if isDynamicIcon then
                --Check the settings again now to see if this icon's dyanmic anti-settings are enabled for the given panel "whereAreWe"
                --Call with 3rd parameter "isDynamicIcon" = true to skip "is dynamic icon check" inside the function again
                isBlockedLoop = FCOIS.checkIfProtectedSettingsEnabled(panelId, iconToCheck, true) --panelId could be LF_SMITHING_DECONSTRUCT or LF_JEWELRY_DECONSTRUCT
                --d("Dynamic icon protection check for panel '" .. tostring(LF_SMITHING_DECONSTRUCT) .."' returned: " .. tostring(isBlockedLoop))
            end
            --============== DYNAMIC ICON CHECKS - END =====================================

            --============== SPECIAL ITEM & ICON CHECKS ====================================
            --Icon for deconstruction, and settings allow deconstruction?
            if iconToCheck == FCOIS_CON_ICON_DECONSTRUCTION and settings.allowDeconstructDeconstruction then
                --dont block item: Set loop variable to false so isAnyIconProtected and isBlockedLoop are not true!
                isBlockedLoop = false
                --Is the setting enabled to allow deconstruction for items marked for deconstruction, even if other marker icons are active?
                if settings.allowDeconstructDeconstructionWithMarkers == true then
                    --d(">>>>> Decon icon enabled and allows decon of all other markers! -> Aborting here")
                    --Abort the loop over the other icons now
                    return false
                end
                --Icon for intricate, and settings allows deconstruction?
            elseif iconToCheck==FCOIS_CON_ICON_INTRICATE and settings.allowDeconstructIntricate then
                --dont block item: Set loop variable to false so isAnyIconProtected and isBlockedLoop are not true!
                isBlockedLoop = false
            end

            --Is the current looped icon protected?
            if not isAnyIconProtected and isBlockedLoop then
                isAnyIconProtected = true
            end
        end -- if FCOIS.checkIfItemIsProtected(iconToCheck, id) then
    end -- for iconToCheck=1, numFilterIcons, 1 do

    --======= ITEM IS BLOCKED ! - START ============================================
    if isAnyIconProtected then
        if (echo == true) then
            --d(">> decon echo")
            --Check if alert or chat message should be shown
            FCOIS.outputItemProtectedMessage(bag, slot, FCOIS_CON_DECONSTRUCT, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
        end -- if echo == true
        return true
    end
    --======= ITEM IS BLOCKED ! - END ==============================================

    --======= RETURN ===============================================================
    --Is the item not marked with any of the marker icons? Don't block it
    if not markedWithOneIcon and (isAnyIconProtected or isBlocked) then
        --d("Decon: not marked with one icon -> Abort 'false'")
        return false
    end
    --Were all icons checked and everything was not blocked? Then return false to unblock the icon
    if not isAnyIconProtected then
        --d("Decon: not blocked in loop -> Abort 'false'")
        return false
    end
    --Else return the global block value from before the icon checks
    --d("Decon: return isBlocked: " .. tostring(isBlocked))
    return isBlocked
end -- DeconstructionSelectionHandler


-- ==================================================================================
-- Crafting prevention (mark item at craftstation -> remove from crafting slot again
-- ==================================================================================
--Functions for the extraction protection
function FCOIS.craftingPrevention.IsShowingEnchantment()
    if FCOIS.craftingPrevention.IsShowingEnchantmentCreation() or FCOIS.craftingPrevention.IsShowingEnchantmentExtraction() then
        return true
    end
    return false
end
function FCOIS.craftingPrevention.IsShowingEnchantmentCreation()
    return not ctrlVars.ENCHANTING_RUNE_CONTAINER:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingEnchantmentExtraction()
    return not ctrlVars.ENCHANTING_EXTRACTION_SLOT:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingDeconstruction()
    return not ctrlVars.DECONSTRUCTION_SLOT:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingImprovement()
    return not ctrlVars.IMPROVEMENT_SLOT:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingRefinement()
    return not ctrlVars.REFINEMENT_SLOT:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingResearch()
    return not ctrlVars.RESEARCH:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingAlchemy()
    return not ctrlVars.ALCHEMY_SLOT_CONTAINER:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingProvisioner()
    return not ctrlVars.PROVISIONER_PANEL:IsHidden()
end
function FCOIS.craftingPrevention.IsShowingProvisionerCook()
    local retVar = FCOIS.craftingPrevention.IsShowingProvisioner()
    if retVar then
        return ctrlVars.PROVISIONER.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES
    end
    return false
end
function FCOIS.craftingPrevention.IsShowingProvisionerBrew()
    local retVar = FCOIS.craftingPrevention.IsShowingProvisioner()
    if retVar then
        return ctrlVars.PROVISIONER.filterType == PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING
    end
    return false
end

function FCOIS.craftingPrevention.GetExtractionSlotAndWhereAreWe()
    if FCOIS.craftingPrevention.IsShowingEnchantmentExtraction() then
        return ctrlVars.ENCHANTING_EXTRACTION_SLOT, FCOIS_CON_ENCHANT_EXTRACT
    elseif FCOIS.craftingPrevention.IsShowingEnchantmentCreation() then
        return ctrlVars.ENCHANTING_RUNE_CONTAINER, FCOIS_CON_ENCHANT_CREATE -- Is the parent control for potency, essence and aspect rune slots!
    elseif FCOIS.craftingPrevention.IsShowingDeconstruction() then
        return ctrlVars.DECONSTRUCTION_SLOT, FCOIS_CON_DECONSTRUCT
    elseif FCOIS.craftingPrevention.IsShowingImprovement() then
        return ctrlVars.IMPROVEMENT_SLOT, FCOIS_CON_IMPROVE
    --elseif FCOIS.craftingPrevention.IsShowingRefinement() then
        --return ctrlVars.REFINEMENT_SLOT, FCOIS_CON_REFINE
    end
end
local GetExtractionSlotAndWhereAreWe = FCOIS.craftingPrevention.GetExtractionSlotAndWhereAreWe

--Remove an item from a crafting extraction/refinement slot
function FCOIS.craftingPrevention.RemoveItemFromCraftSlot(bagId, slotIndex, isSlotted)
--d("[FCOIS]craftingPrevention.RemoveItemFromCraftSlot")
    if bagId == nil or slotIndex == nil then return false end
    isSlotted = isSlotted or false
    --Get the "WhereAreWe" constant by the help of the active deconstruction/extraction crafting panel
    local whereAreWe
    --The global crafting stations variable
    local craftingStationVar
    local craftPrev = FCOIS.craftingPrevention
    --Are we at an enchanting station?
    if craftPrev.IsShowingEnchantmentExtraction() then
        craftingStationVar = ctrlVars.ENCHANTING
        whereAreWe = FCOIS_CON_ENCHANT_EXTRACT
    elseif craftPrev.IsShowingEnchantmentCreation() then
        craftingStationVar = ctrlVars.ENCHANTING
        whereAreWe = FCOIS_CON_ENCHANT_CREATE
    elseif craftPrev.IsShowingDeconstruction() then
        craftingStationVar = ctrlVars.SMITHING
        whereAreWe = FCOIS_CON_DECONSTRUCT
    elseif craftPrev.IsShowingImprovement() then
        craftingStationVar = ctrlVars.SMITHING
        whereAreWe = FCOIS_CON_IMPROVE
    elseif craftPrev.IsShowingRefinement() then
        craftingStationVar = ctrlVars.SMITHING
        whereAreWe = FCOIS_CON_REFINE
    elseif craftPrev.IsShowingAlchemy() then
        craftingStationVar = ctrlVars.ALCHEMY
        whereAreWe = FCOIS_CON_ALCHEMY_DESTROY
    end
    if craftingStationVar == nil then return false end
    --Check if the item is slotted at the crafting station
    if not isSlotted then
        isSlotted = craftingStationVar:IsItemAlreadySlottedToCraft(bagId, slotIndex)
    end
--d(">whereAreWe: " .. tostring(whereAreWe) .. ", isSlotted: " ..tostring(isSlotted) .. ", craftingStationVar: " .. tostring(craftingStationVar.control:GetName()))
    --Item is not slotted so abort here
    if not isSlotted then return false end
    --Unequip the item from the crafting slot again
    craftingStationVar:RemoveItemFromCraft(bagId, slotIndex)
    --Check if alert or chat message should be shown
    --function FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
    FCOIS.outputItemProtectedMessage(bagId, slotIndex, whereAreWe, true, false, false, false)
end
local RemoveItemFromCraftSlot = FCOIS.craftingPrevention.RemoveItemFromCraftSlot

--Function to check if items for extraction/deconstruction/improvement are currently saved (got saved after adding them to the extraction slot)
function FCOIS.craftingPrevention.CheckPreventCrafting(override, extractSlot, extractWhereAreWe)
    override = override or false
    --Initialize the return variable with false so this PreHook function won't abort the extraction
    local retVar = false
    --Reset variables
    FCOIS.craftingPrevention.extractSlot = nil
    FCOIS.craftingPrevention.extractWhereAreWe = nil
    --Get the extraction container and function
    if not override then
        FCOIS.craftingPrevention.extractSlot, FCOIS.craftingPrevention.extractWhereAreWe = GetExtractionSlotAndWhereAreWe()
    else
        --Used for recursively called 3 enchanting creation rune slots
        FCOIS.craftingPrevention.extractSlot = extractSlot
        FCOIS.craftingPrevention.extractWhereAreWe = extractWhereAreWe
    end
    if FCOIS.craftingPrevention.extractSlot == nil or FCOIS.craftingPrevention.extractWhereAreWe == nil then return false end
    --d("[FCOIS]craftingPrevention.CheckPreventCrafting - whereAreWe: " .. tostring(FCOIS.craftingPrevention.extractWhereAreWe))
    --Check if the current extraction slot item is protected and abort if so
    --get the bagId and slotIndex of the item that should be extracted
    local bagId
    local slotIndex
    if FCOIS.craftingPrevention.extractWhereAreWe ~= FCOIS_CON_ENCHANT_CREATE or (override and extractWhereAreWe == FCOIS_CON_ENCHANT_CREATE) then
        bagId     = FCOIS.craftingPrevention.extractSlot.bagId
        slotIndex = FCOIS.craftingPrevention.extractSlot.slotIndex
    else
        --At enchanting creation there are 3 slots to check: aspect, potency and essence rune:
        --ZO_EnchantingTopLevelRuneSlotContainerPotencyRune
        --ZO_EnchantingTopLevelRuneSlotContainerEssenceRune
        --ZO_EnchantingTopLevelRuneSlotContainerAspectRune
        --Recursively call this function to remove the marked runes
        local enchantingCreationSlos = {
            [1] = ctrlVars.ENCHANTING_RUNE_CONTAINER_POTENCY,
            [2] = ctrlVars.ENCHANTING_RUNE_CONTAINER_ESSENCE,
            [3] = ctrlVars.ENCHANTING_RUNE_CONTAINER_ASPECT,
        }
        local retVarLoop = false
        local locCheckPreventCrafting = FCOIS.craftingPrevention.CheckPreventCrafting
        for i=1, 3 do
            local runeSlot = enchantingCreationSlos[i]
            if runeSlot ~= nil then
                local returnVar = false
                --Call function recursively and override with the 3 enchanting creation rune slots
                returnVar = locCheckPreventCrafting(true, runeSlot, FCOIS_CON_ENCHANT_CREATE)
                --Only overwrite the reurn variable for the loop if the value is "true" -> Abort the extract function
                if not retVarLoop then
                    retVarLoop = returnVar
                end
            end
        end
        --Call/Skip the original create function now -> If runes were removed it will be skipped!
        return retVarLoop
    end
    --Is an item put into the extraction slot?
    if bagId ~= nil and slotIndex ~= nil then
        return FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, true, false, false, false)
    end
    --Reset variables again
    FCOIS.craftingPrevention.extractSlot = nil
    FCOIS.craftingPrevention.extractWhereAreWe = nil
    return retVar
end

--Remove an item from the retrait slot
function FCOIS.craftingPrevention.RemoveItemFromRetraitSlot(bagId, slotIndex, isSlotted)
    --d("[FCOIS.craftingPrevention.RemoveItemFromRetraitSlot] isSlotted: " ..tostring(isSlotted))
    if bagId == nil or slotIndex == nil then return false end
    isSlotted = isSlotted or false
    --Are we at an enchanting station?
    --The global retrait station variable
    if ctrlVars.RETRAIT_INV:IsHidden() then return false end
    local retraitStationVar = ctrlVars.RETRAIT_RETRAIT_PANEL
    --The "WhereAreWe" constant for the retrait station
    local whereAreWe = FCOIS_CON_RETRAIT
    --Check if the item is slotted at the retrait station
    if not isSlotted then
        isSlotted = retraitStationVar:IsItemAlreadySlottedToCraft(bagId, slotIndex)
        --d(">isSlotted: " ..tostring(isSlotted))
    end
    --Item is not slotted so abort here
    if not isSlotted then return false end
--d(">removing item from trait station slot")
    --Unequip the item from the crafting slot again
    retraitStationVar:RemoveItemFromRetrait() --bagId, slotIndex)
    --Check if alert or chat message should be shown
    --function FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
    FCOIS.outputItemProtectedMessage(bagId, slotIndex, whereAreWe, true, false, false, false)
end
local RemoveItemFromRetraitSlot = FCOIS.craftingPrevention.RemoveItemFromRetraitSlot

--Returns the bagId and slotIndex of a slotted item in the deconstruction/improvement/refine/enchant extraction slot
--With ESO update Scalebreaker the multi-craft and deconstruct/extract is supported by the game. You are able to add multiple items with a
--left mouse click to the slot and the items added are then in the subtable "items" of the deconstruction/extraction slot.
--This function checks if there are multiple items and returns the table of slotted items now as 3rd return parameter
function FCOIS.craftingPrevention.GetSlottedItemBagAndSlot()
    local isRetraitShown = FCOIS.isRetraitStationShown()
    local isCraftingStationShown = ZO_CraftingUtils_IsCraftingWindowOpen() and ctrlVars.RESEARCH:IsHidden() -- No crafting slot at research!
    local bagId, slotIndex, slottedItems
    local craftingStationSlot
        --Crafting station shown?
    if isCraftingStationShown then
        --Refinement
        if FCOIS.gFilterWhere == LF_SMITHING_REFINE or FCOIS.gFilterWhere == LF_JEWELRY_REFINE then
            craftingStationSlot = ctrlVars.SMITHING.refinementPanel.extractionSlot

        --Deconstruction
        elseif FCOIS.gFilterWhere == LF_SMITHING_DECONSTRUCT or FCOIS.gFilterWhere == LF_JEWELRY_DECONSTRUCT then
            craftingStationSlot = ctrlVars.SMITHING.deconstructionPanel.extractionSlot

        --Improvement
        elseif FCOIS.gFilterWhere == LF_SMITHING_IMPROVEMENT or FCOIS.gFilterWhere == LF_JEWELRY_IMPROVEMENT then
            craftingStationSlot = ctrlVars.SMITHING.improvementPanel.improvementSlot

        --Enchanting extraction
        elseif FCOIS.gFilterWhere == LF_ENCHANTING_EXTRACTION then
            craftingStationSlot = ctrlVars.ENCHANTING.extractionSlot
        end

    --Retrait station shown?
    elseif isRetraitShown then
        craftingStationSlot = ctrlVars.RETRAIT_RETRAIT_PANEL.retraitSlot
    end
    --Is the crafting slot found, get the bagId and slotIndex of the slotted item now
    if craftingStationSlot ~= nil then
        if craftingStationSlot.GetBagAndSlot then
            bagId, slotIndex = craftingStationSlot:GetBagAndSlot()
        end
        slottedItems = craftingStationSlot.items
    end
    return bagId, slotIndex, slottedItems
end
local GetSlottedItemBagAndSlot = FCOIS.craftingPrevention.GetSlottedItemBagAndSlot

--This function scans the currently shown inventory rows data for the same itemInstanceId which the bagId and slotIndex
--given as parameters got. If another item with the same itemInstanceId is found the function returns the bagId and slotIndex.
--As multiple same items could be found each found item will be added to the return table!
function FCOIS.checkCurrentInventoryRowsDataForItemInstanceId(bagIdToSkip, slotIndexToSkip)
--d("[FCOIS].checkCurrentInventoryRowsDataForItemInstanceId")
    if bagIdToSkip == nil or slotIndexToSkip == nil then return end
    local itemInstanceIdToFind = GetItemInstanceId(bagIdToSkip, slotIndexToSkip)
    if itemInstanceIdToFind == nil then return end
    local foundBagdIdAndSlotIndices
    local filterPanelsIdToInv = FCOIS.mappingVars.gFilterPanelIdToInv
    --Get the currently shown inventory container for the inventory list with the rows and it's data
    --e.g. SMITHING.deconstructionPanel.inventory.list.data[1].data.itemInstanceId
    local inventoryContainerVar = filterPanelsIdToInv[FCOIS.gFilterWhere]
    if inventoryContainerVar == nil then return false end
    --Get the data of the inventoryContainer (the rows)
    local dataRows = inventoryContainerVar.data
    if dataRows == nil then return end
    for _, rowData in ipairs(dataRows) do
        local rowDataData = rowData.data
        if rowDataData and rowDataData.bagId and rowDataData.slotIndex and rowDataData.slotIndex ~= slotIndexToSkip then
            local itemInstanceIdToCompare = rowDataData.itemInstanceId
            if itemInstanceIdToCompare ~= nil and itemInstanceIdToCompare == itemInstanceIdToFind then
                --Add item bagId and slotIndex to the return table
                foundBagdIdAndSlotIndices = foundBagdIdAndSlotIndices or {}
                table.insert(foundBagdIdAndSlotIndices, {["bagId"] = rowDataData.bagId, ["slotIndex"] = rowDataData.slotIndex })
            end
        end
    end
    return foundBagdIdAndSlotIndices
end

--Is the item protected at a crafting table's slot now
function FCOIS.craftingPrevention.IsItemProtectedAtACraftSlotNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
--local itemLink = GetItemLink(bagId, slotIndex)
--d("[FCOIS]craftingPrevention.IsItemProtectedAtACraftSlotNow: " ..itemLink)
    --Are we inside a crafting or retrait station?
    local isRetraitShown = FCOIS.isRetraitStationShown()
    local slottedItems
    local isCraftingStationShown = not isRetraitShown and ZO_CraftingUtils_IsCraftingWindowOpen() and ctrlVars.RESEARCH:IsHidden() -- No crafting slot at research!
--d(">isCraftingStationShown: " .. tostring(isCraftingStationShown) .. ", isRetraitShown: " ..tostring(isRetraitShown) .. ", filterPanelId: " ..tostring(FCOIS.gFilterWhere))
    if isCraftingStationShown or isRetraitShown then
        local allowedCraftingPanelIdsForMarkerRechecks = FCOIS.checkVars.allowedCraftingPanelIdsForMarkerRechecks
        --Check if a refine/deconstruct/create glyph/extract/improve/create alchemy panel is shown
        if allowedCraftingPanelIdsForMarkerRechecks[FCOIS.gFilterWhere] then
            --Is the bagId and slotIndex nil then get the slotted item's bagId and slotIndex now
            if bagId == nil and slotIndex == nil then
                bagId, slotIndex, slottedItems = GetSlottedItemBagAndSlot()
            end
            --local helper function to check the protection and remove the item from the craft slot
            local function checkProtectionAndRemoveFromSlotIfProtected(p_bagId, p_slotIndex)
                local retVar = false
                --Check if the item is currently slotted at a crafting station's extraction slot. If the item is proteced remove it from the extraction slot again!
                --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
                local isProtected = FCOIS.callDeconstructionSelectionHandler(p_bagId, p_slotIndex, false, false, true, false, true, false)
                --Item is protected?
                if isProtected then
                    if isRetraitShown then
                        --d("Item is protected! Remove it from the retrait slot and output error message now")
                        RemoveItemFromRetraitSlot(p_bagId, p_slotIndex, false)
                        retVar = true
                    else
                        --d("Item is protected! Remove it from the crafting slot and output error message now")
                        RemoveItemFromCraftSlot(p_bagId, p_slotIndex, false)
                        retVar = true
                    end
                end
                return retVar
            end
            --Table with all slotted items is given?
            if (bagId == nil or slotIndex == nil) and slottedItems ~= nil then
                --For each table entry check if the item is protected and remove where needed
                for _, slottedData in ipairs(slottedItems) do
                    if slottedData.bagId and slottedData.slotIndex then
                        checkProtectionAndRemoveFromSlotIfProtected(slottedData.bagId , slottedData.slotIndex)
                        --This item is (n)ot protected, but maybe the same item in another inventory slotIndex is currently slotted to the crafting slot
                        --and got protected as you marked the currently checked item (which is not slotted).
                        -->Scan the currently visible inventory rows for such items and if they are slotted.
                        if scanOtherInvItemsIfSlotted then
                            local foundBagdIdAndSlotIndices = FCOIS.checkCurrentInventoryRowsDataForItemInstanceId(slottedData.bagId, slottedData.slotIndex)
                            if foundBagdIdAndSlotIndices ~= nil then
                                for _, invItemData in ipairs(foundBagdIdAndSlotIndices) do
                                    checkProtectionAndRemoveFromSlotIfProtected(invItemData.bagId, invItemData.slotIndex)
                                end
                            end
                        end
                    end
                end
            --Only 1 item is checked
            elseif bagId ~= nil and slotIndex ~= nil then
                checkProtectionAndRemoveFromSlotIfProtected(bagId, slotIndex)
                --This item is (not) protected, but maybe the same item in another inventory slotIndex is currently slotted to the crafting slot
                --and got protected as you marked the currently checked item (which is not slotted).
                -->Scan the currently visible inventory rows for such items and if they are slotted.
                if scanOtherInvItemsIfSlotted then
                    local foundBagdIdAndSlotIndices = FCOIS.checkCurrentInventoryRowsDataForItemInstanceId(bagId, slotIndex)
                    if foundBagdIdAndSlotIndices ~= nil then
                        for _, invItemData in ipairs(foundBagdIdAndSlotIndices) do
                            checkProtectionAndRemoveFromSlotIfProtected(invItemData.bagId, invItemData.slotIndex)
                        end
                    end
                end
            end
        end
    end
end
local IsItemProtectedAtACraftSlotNow = FCOIS.craftingPrevention.IsItemProtectedAtACraftSlotNow

--Function to check if a crafting panel is shown and if an item from the craftbag got dragged to the
--slot of the crafting station
function FCOIS.isCraftBagItemDraggedToCraftingSlot(panelId, bagId, slotIndex)
    --Check if a filter panel parent (e.g. Craftbag panel is active at the mail send panel = Mail send is the parent)
    local parentPanelId = FCOIS.gFilterWhereParent
    if parentPanelId == nil then
        parentPanelId = FCOIS.gFilterWhere
    end
    panelId = panelId or parentPanelId
    local panelIdToCheckFunc = {
        [LF_SMITHING_REFINE]        = FCOIS.craftingPrevention.IsShowingRefinement,
        [LF_ENCHANTING_CREATION]    = FCOIS.craftingPrevention.IsShowingEnchantment, -- Check which one is shown, creation or extraction
        --Enchanting creation and extraction are both handled via the creation hook!
        --[LF_ENCHANTING_EXTRACTION]  = FCOIS.craftingPrevention.IsShowingEnchantmentExtraction,
        [LF_ALCHEMY_CREATION]       = FCOIS.craftingPrevention.IsShowingAlchemy,
        [LF_PROVISIONING_COOK]      = FCOIS.craftingPrevention.IsShowingProvisionerCook,
        [LF_PROVISIONING_BREW]      = FCOIS.craftingPrevention.IsShowingProvisionerBrew,
    }
    local checkFunc = panelIdToCheckFunc[panelId]
    if checkFunc == nil then return false end
--d("[FCOIS] Received item drag at crafting station")
    if checkFunc() and bagId ~= nil then
        --local itemLink = GetItemLink(bagId, slotIndex)
--d(">" .. itemLink .. " - bag: " ..tostring(bagId) .. ", slotIndex: " ..tostring(slotIndex))
        --Is the item from the craftbag?
        if bagId == BAG_VIRTUAL then
--d(">Craftbag item")
            --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
            if( FCOIS.callItemSelectionHandler(bagId, slotIndex, true, true, false, false, false, false, false) ) then
                --d(">Item is protected so don't allow the drop!")
                --Remove the picked item from drag&drop cursor
                ClearCursor()
                return true
            end
        end
    end
end

--Function to check if an item is protected at the guild store sell tab now, after it got marked with a marker icon.
--If so: Remove the item from the guild store's sell slot again, if it is slotted
function FCOIS.IsItemProtectedAtTheGuildStoreSellTabNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    if not ctrlVars.GUILD_STORE:IsHidden() and ctrlVars.GUILD_STORE_KEYBOARD:IsInSellMode() then
        --Check if marked item is currently in the "sell slot" and remove it again, if it is protected
        if (ctrlVars.GUILD_STORE_SELL_SLOT_ITEM ~= nil and (ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.bagId ~= nil and ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.slotIndex ~= nil)
                and     (bagId ~= nil and slotIndex ~= nil and ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.bagId == bagId and ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.slotIndex == slotIndex)
                    or  (bagId == nil and slotIndex == nil) )
        then
            bagId = ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.bagId
            slotIndex = ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.slotIndex
            --d("[FCOIS]MarkMe GuildStore - callDeconstructionSelectionHandler without echo")
            --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
            --Be sure to set calledFromExternalAddon = true here as otherwise the guild store sell checks aren't done, because
            --the DeconstructionSelectionhandler will not call the ItemSelectionHandler then!
            local isProtected = FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, false, true, false, true, true)
            --Item is protected?
            if isProtected then
                --d("GuildStore: Item is protected! Output error message now")
                --Remove the item from the guild store sell slot
                --BAG_BACKPACK is used as even CraftBag items get moved to the bagpack before listing them! Even with addon CraftBagExtended
                SetPendingItemPost(BAG_BACKPACK, 0, 0)
                local whereAreWe = FCOIS_CON_GUILD_STORE_SELL
                --function FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                FCOIS.outputItemProtectedMessage(bagId, slotIndex, whereAreWe, true, false, false, false)
            end
        end
    end
end

--Function to check if an item is protected at a libFilters filter panel ID now, after it got marked with a marker icon.
--If so: Remove the item from the panel's slot again, if it is slotted
function FCOIS.IsItemProtectedAtPanelNow(bagId, slotIndex, panelId, scanOtherInvItemsIfSlotted)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    panelId = panelId or FCOIS.gFilterWhere
    if panelId == nil then return nil end
    --Mail send
    if panelId == LF_MAIL_SEND then
        if (ctrlVars.MAIL_SEND and not ctrlVars.MAIL_SEND.control:IsHidden()) or not ctrlVars.MAIL_ATTACHMENTS:IsHidden() then
            local function CheckAttachments()
                --Check each of the attachmenmt slots
                for i = 1, MAIL_MAX_ATTACHED_ITEMS do
                    -- Return value would be 1 if item is slotted in this attachment slot
                    if GetQueuedItemAttachmentInfo(i) ~= 0 then
                        --Get the slot i's slotIndex
                        local attachmentSlotsParent = ctrlVars.MAIL_ATTACHMENTS
                        local slotControl = attachmentSlotsParent[i]
                        --Search the slotControl slotIndex and compare it with the actually checked item's slotIndex
                        if (slotControl ~= nil
                            and     (bagId ~= nil and slotIndex ~= nil and slotControl.bagId ~= nil and slotControl.bagId == bagId and slotControl.slotIndex ~= nil and slotControl.slotIndex == slotIndex)
                                or  (bagId == nil and slotIndex == nil and slotControl.bagId ~= nil and slotControl.slotIndex ~= nil) )
                        then
                            --Item was found: Check if it is protected now
                            --d("[FCOIS]MarkMe ProtectedAtSlotNow - callDeconstructionSelectionHandler without echo")
                            --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
                            --Be sure to set calledFromExternalAddon = true here as otherwise the guild store sell checks aren't done, because
                            --the DeconstructionSelectionhandler will not call the ItemSelectionHandler then!
                            local isProtected = FCOIS.callDeconstructionSelectionHandler(slotControl.bagId, slotControl.slotIndex, false, false, true, false, true, true)
                            --Item is protected?
                            if isProtected then
                                --Item is protected now, so remove it from the mail attachment slot again
                                RemoveQueuedItemAttachment(i)
                                local whereAreWe = FCOIS_CON_MAIL
                                --function FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                                FCOIS.outputItemProtectedMessage(slotControl.bagId, slotControl.slotIndex, whereAreWe, true, false, false, false)
                            end
                        end
                    end
                end
            end
            --Check the attachments now and unslot them if they are protected now
            CheckAttachments()
        end

    --Player2Player trade
    elseif panelId == LF_TRADE then
        if (ctrlVars.PLAYER_TRADE_WINDOW and ctrlVars.PLAYER_TRADE_WINDOW:IsTrading()) or (ctrlVars.PLAYER_TRADE and not ctrlVars.PLAYER_TRADE.control:IsHidden()) or not ctrlVars.PLAYER_TRADE_ATTACHMENTS:IsHidden() then
            --local functions for mail send checks
            local function CheckTradeAttachments()
                for i = 1, TRADE_NUM_SLOTS do
                    local bagIdTradeSlot, slotIndexTradeSlot = GetTradeItemBagAndSlot(TRADE_ME, i)
                    if (bagIdTradeSlot and slotIndexTradeSlot
                        and     (bagId ~= nil and slotIndex ~= nil and bagIdTradeSlot == bagId and slotIndexTradeSlot == slotIndex)
                            or  (bagId == nil and slotIndex == nil))
                    then
                        --Item was found: Check if it is protected now
                        --d("[FCOIS]MarkMe ProtectedAtSlotNow - callDeconstructionSelectionHandler without echo")
                        --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
                        --Be sure to set calledFromExternalAddon = true here as otherwise the guild store sell checks aren't done, because
                        --the DeconstructionSelectionhandler will not call the ItemSelectionHandler then!
                        local isProtected = FCOIS.callDeconstructionSelectionHandler(bagIdTradeSlot, slotIndexTradeSlot, false, false, true, false, true, true)
                        --Item is protected?
                        if isProtected then
                            TradeRemoveItem(i)
                            local whereAreWe = FCOIS_CON_TRADE
                            --function FCOIS.outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                            FCOIS.outputItemProtectedMessage(bagIdTradeSlot, slotIndexTradeSlot, whereAreWe, true, false, false, false)
                        end
                    end
                end
            end
            --Check the attachments now and unslot them if they are protected now
            CheckTradeAttachments()
        end
    end
end

--Is the item marked as junk? Remove it from junk again if a non-junkable marker icon was set now
--> Only remove from bulk
---- if setting to not remove normal (keybind/context menu) marked items from junk is disabled
---- if setting to not remove bulk (additional inventory "flag" icon) marked items from junk is disabled
function FCOIS.checkIfIsJunkItem(bagId, slotIndex, bulkMark, scanOtherInvItemsIfSlotted)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    if bagId == nil or slotIndex == nil then return false end
    bulkMark = bulkMark or false
    if IsItemJunk(bagId, slotIndex) and FCOIS.IsJunkLocked(bagId, slotIndex) then
        local settings = FCOIS.settingsVars.settings
        --Are we bulk marking the item and is the option to "not remove items from junk on bulk mark" enabled?
        if bulkMark then
            local dontUnjunkOnBulkMark = settings.dontUnjunkOnBulkMark
            if dontUnjunkOnBulkMark then return false end
        else
            local dontUnjunkOnNormalMark = settings.dontUnjunkOnNormalMark
            if dontUnjunkOnNormalMark then return false end
        end
        --Unjunk the marked item now
        SetItemIsJunk(bagId, slotIndex, false)
    end
end

--Function to check if an item is protected at a slot (crafting, junk, mail, trade, etc.) at the moment, and if so,
--remove it from the slot/junk now.
--Parameter bulkMark is used for the junk checks, if the additional inventory "flag" icon context menu is used for mass-junk/unjunk
function FCOIS.IsItemProtectedAtASlotNow(bagId, slotIndex, bulkMark, scanOtherInvItemsIfSlotted)
    bulkMark = bulkMark or false
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    --Check if the item was marked and then needs to be protected, if it's slotted at a crafting/retrait station!
    IsItemProtectedAtACraftSlotNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    --Are we inside the guild store's sell tab?
    FCOIS.IsItemProtectedAtTheGuildStoreSellTabNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    --Check if the item is protected at the junk tab now
    FCOIS.checkIfIsJunkItem(bagId, slotIndex, bulkMark, scanOtherInvItemsIfSlotted)
    --Check if the item is protected at any other panel now
    FCOIS.IsItemProtectedAtPanelNow(bagId, slotIndex, FCOIS.gFilterWhere, scanOtherInvItemsIfSlotted)
end

--Check if withdraw from guild bank is allowed, or block deposit of items
function FCOIS.checkIfGuildBankWithdrawAllowed(currentGuildBank)
    --if DoesPlayerHaveGuildPermission(currentGuildBank, GUILD_PERMISSION_BANK_DEPOSIT) and DoesPlayerHaveGuildPermission(currentGuildBank, GUILD_PERMISSION_BANK_WITHDRAW) then
    local retVal = DoesPlayerHaveGuildPermission(currentGuildBank, GUILD_PERMISSION_BANK_WITHDRAW)
    --d("[FCOIS] FCOIS.checkIfGuildBankWithdrawAllowed: " .. tostring(retVal))
    return retVal
end

--Transmutation geode loot protection so you do not loot 50 crystals if you already got 199 of max 200
--Get the currency amount of the transmuation crystals and the maximum value
local function getTransmutationCrystalAmount()
    local transmCrystalCount    = GetCurrencyAmount(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT)
    local transmCrystalCountMax = GetMaxPossibleCurrency(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT)
    return transmCrystalCount, transmCrystalCountMax
end

--Check if the transmutation crystals are above the threshold value of "max" minus "maximum looted crystals"
-- and show a dialog then that asks if you really want to loot the transmuation geode
function FCOIS.checkAndShowTransmutationGeodeLootDialog()
    --d("[FCOIS.checkAndShowTransmutationGeodeLootDialog]")
    local settings = FCOIS.settingsVars.settings
    if not settings.showTransmutationGeodeLootDialog or CURT_CHAOTIC_CREATIA == nil or not IsCurrencyValid(CURT_CHAOTIC_CREATIA) then return false end
    local maximumLootedTrasmCrystals = 50 -- currently max 50 crystals can be looted from the PvP/AvA stuff
    local curCurrent, curMax = getTransmutationCrystalAmount()
    if curCurrent >= (curMax - maximumLootedTrasmCrystals) then
        --Show the dialog if the return value is true
        --d("[FCOIS]TRANSMUTATION LOOT DIALOG!")
        --Return true so the normal loot function is not called!
        return true, curCurrent, curMax
    else
        --Do not show a dialog and loot the crystals from the geode as normal
        return false, 0, 0
    end
end
