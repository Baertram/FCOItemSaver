--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local tos = tostring

local libFilters = FCOIS.libFilters

--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

local ctrlVars = FCOIS.ZOControlVars
local universalDeconGlobal = ctrlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL
local universalDeconPanel = universalDeconGlobal and universalDeconGlobal.deconstructionPanel

local hideContextMenu = FCOIS.HideContextMenu
local updateFCOISFilterButtonsAtInventory = FCOIS.UpdateFCOISFilterButtonsAtInventory
local updateFCOISFilterButtonColorsAndTextures = FCOIS.UpdateFCOISFilterButtonColorsAndTextures
local changeContextMenuInvokerButtonColorByPanelId = FCOIS.ChangeContextMenuInvokerButtonColorByPanelId
local autoReenableAntiSettingsCheck = FCOIS.AutoReenableAntiSettingsCheck

local isResearchListDialogShown = FCOIS.IsResearchListDialogShown
local isRetraitStationShown = FCOIS.IsRetraitStationShown
local getCurrentSceneInfo = FCOIS.GetCurrentSceneInfo
local isAutolootContainer = FCOIS.IsAutolootContainer
local isItemType = FCOIS.IsItemType
local isCompanionInventoryShown = FCOIS.IsCompanionInventoryShown
local getFilterWhereBySettings = FCOIS.GetFilterWhereBySettings
local mappingVars = FCOIS.mappingVars
local panelIdSupportedAtDeconNPC = mappingVars.panelIdSupportedAtUniversalDeconstructionNPC
local panelIdByDeconNPCMenuBarTabButtonName = mappingVars.panelIdByUniversalDeconstructionNPCMenuBarTabButtonName

local universalDeconInvCtrl = ctrlVars.UNIVERSAL_DECONSTRUCTION_INV
local universaldDeconScene = ctrlVars.UNIVERSAL_DECONSTRUCTON_SCENE
local universaldDeconMenuBarTabs = ctrlVars.UNIVERSAL_DECONSTRUCTION_MENUBAR_TABS

--==========================================================================================================================================
--                                          FCOIS - Panel functions
--==========================================================================================================================================

--Function to check a single item's type and get the whereAreWe ID
local function checkSingleItemProtection(p_bag, p_slotIndex, panelId, panelIdAtCall, calledFromExternalAddon)
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[checkSingleItemProtection]","panelId: " .. tos(panelId) .. ", calledFromExternalAddon: " ..tos(calledFromExternalAddon), true, FCOIS_DEBUG_DEPTH_ALL) end
    if p_bag == nil or p_slotIndex == nil then return false end
    local locWhereAreWe = FCOIS_CON_DESTROY

    local wasDragged = FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler

    --Are we trying to open a container with autoloot on?
    if (isAutolootContainer(p_bag, p_slotIndex)) then
        locWhereAreWe = FCOIS_CON_CONTAINER_AUTOOLOOT
        --Read recipe?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_RECIPE)) then
        locWhereAreWe = FCOIS_CON_RECIPE_USAGE
        --Read style motif?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_RACIAL_STYLE_MOTIF)) then
        locWhereAreWe = FCOIS_CON_MOTIF_USAGE
        --Drink potion?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_POTION)) then
        locWhereAreWe = FCOIS_CON_POTION_USAGE
        --Eat food?
    elseif (isItemType(p_bag, p_slotIndex, {ITEMTYPE_FOOD, ITEMTYPE_DRINK})) then
        locWhereAreWe = FCOIS_CON_FOOD_USAGE
        --Use crown store item?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_CROWN_ITEM) or isItemType(p_bag, p_slotIndex, ITEMTYPE_CROWN_REPAIR)) then
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
                if wasDragged then
                    --Return the fallback value "false" so the drag&drop/double click works and will not show "Destroy not allowed!"
                    --d(">SingleItemChecks: Drag&Drop handler -> whereAreWe = FCOIS_CON_FALLBACK")
                    locWhereAreWe = FCOIS_CON_FALLBACK
                    FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
                end
            end
        end
    end

    --Inventory -> QuickSlot is shown -> Item was dragged & dropped
    --#274 Fix usable items getting protected as drag&drop is taking place at quuckslot wheell
    if panelId == LF_INVENTORY and locWhereAreWe ~= FCOIS_CON_FALLBACK and ctrlVars.QUICKSLOT_KEYBOARD:AreQuickSlotsShowing() and wasDragged then
--d( "[checkSingleItemProtection]QUICKSLOT panelId: " .. tos(panelId) .. ", calledFromExternalAddon: " ..tos(calledFromExternalAddon) ..", panelIdAtCall: " ..tos(panelIdAtCall) .. ", locWhereAreWe: " ..tos(locWhereAreWe) )
        locWhereAreWe = FCOIS_CON_FALLBACK
    end

    if settings.debug then debugMessage( "[checkSingleItemProtection]", "<<< whereAreWeAfter: " .. tos(locWhereAreWe), true, FCOIS_DEBUG_DEPTH_ALL) end
    return locWhereAreWe
end

--Check if an item should be used or should be equipped (only LF_INVENTORY or LF_INVENTORY_COMPANION) via double click e.g.
--returns FCOIS_CON_FALLBACK as whereAreWe in that case and disables the further checks in ItemSelectionHandler this way
local function checkIfItemShouldBeUsedOrEquipped(p_whereAreWe, p_bag, p_slot, panelId, panelIdAtCall, calledFromExternalAddon)
--d("[FCOIS]checkIfItemShouldBeUsedOrEquipped")
    if p_whereAreWe ~= FCOIS_CON_FALLBACK then
        --Get the whereAreWe panel ID by checking the item's type etc. now and allow equipping items via double click e.g.
        --by returning the FCOIS_CON_FALLBACK value
        return checkSingleItemProtection(p_bag, p_slot, panelId, panelIdAtCall, calledFromExternalAddon)
    else
        return p_whereAreWe
    end
end

--Function to check if the currently shown panel is the craftbag
function FCOIS.IsCraftbagPanelShown()
    local retVar = INVENTORY_CRAFT_BAG and not FCOIS.ZOControlVars.CRAFTBAG:IsHidden()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[isCraftbagPanelShown]", "result: " .. tos(retVar), true, FCOIS_DEBUG_DEPTH_SPAM) end
    return retVar
end
local isCraftbagPanelShown = FCOIS.IsCraftbagPanelShown

--Check if the craftbag panel is currently active and change the panelid to craftbag, or the wished one.
--Change the parentPanelId too (e.g. mail send, or bank deposit) if the craftbag is active!
function FCOIS.CheckCraftbagOrOtherActivePanel(wishedPanelId)
    if wishedPanelId == nil then return LF_INVENTORY, nil end
    local newPanelId
    local newParentPanelId
    --Workaround: Craftbag stuff, check if active panel is the Craftbag
    if isCraftbagPanelShown() then
        newPanelId = LF_CRAFTBAG
        --Check if last active shown filter panel was the craftbag (e.g. at the bank deposit tab) and update the
        --parent filter panel to mail now, because the craftbag scene "shown" callback function will not be called,
        --if you directly switch to the mail sent panel via keybind (and the craftbag panel there was last used).
        --The parent will be resettted to NIL again upon craftbag scene hiding which happens if you leave the mail sent panel.
        newParentPanelId = wishedPanelId
    else
        newPanelId = wishedPanelId
    end
    --d("[FCOIS.checkCraftbagOrOtherActivePanel - New panel id: " .. tos(newPanelId) .. ", filterParent: " ..tos(newParentPanelId))
    return newPanelId, newParentPanelId
end

-- -v- #202
--Check if universal Deconstruction NPC "Giladil"
local isUniversalDeconstructionPanelShown
function FCOIS.CheckIfUniversalDeconstructionNPC(filterPanelIdComingFrom)
    --d("[FCOIS]CheckIfUniversalDeconstructionNPC")
    isUniversalDeconstructionPanelShown = isUniversalDeconstructionPanelShown or libFilters.IsUniversalDeconstructionPanelShown
    if isUniversalDeconstructionPanelShown == nil then return false end
    return isUniversalDeconstructionPanelShown(filterPanelIdComingFrom)
end
local checkIfUniversaldDeconstructionNPC = FCOIS.CheckIfUniversalDeconstructionNPC

function FCOIS.GetCurrentFilterPanelIdAtDeconNPC(filterPanelIdPassedIn)
    local filterPanelIdDetected = filterPanelIdPassedIn
    local isDeconstuctionNPC = checkIfUniversaldDeconstructionNPC(filterPanelIdPassedIn)
--d("[FCOIS]GetCurrentFilterPanelIdAtDeconNPC - filterPanel: " ..tos(filterPanelIdPassedIn) .. ", FCOIS.universalDeconPanelId: " ..tos(universalDeconGlobal.FCOIScurrentFilterPanelId) .. ", isDeconstuctionNPC: " ..tos(isDeconstuctionNPC))
    universalDeconGlobal.FCOIScurrentFilterPanelId = nil
    if not isDeconstuctionNPC then return filterPanelIdPassedIn, false end
    universalDeconGlobal.FCOIScurrentFilterPanelId = filterPanelIdDetected
    return filterPanelIdDetected, isDeconstuctionNPC
end
local getCurrentFilterPanelIdAtDeconNPC = FCOIS.GetCurrentFilterPanelIdAtDeconNPC
-- -^- #202

--Get the whereAreWe constant based on the passed in filterType, respecting the craftingType OR the 3rd "are we are a universal deconstruction NPC" parameter
local function getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(filterPanelId, getWhereAreWe, isDeconNPC)
    if getWhereAreWe == nil then return end
    local filterPanelIdToWhereAreWe
    local whereAreWeDetermined
    local filterPanelIdDetermined = filterPanelId
    if getWhereAreWe == true then
        filterPanelIdToWhereAreWe = mappingVars.filterPanelIdToWhereAreWe
        whereAreWeDetermined = filterPanelIdToWhereAreWe[filterPanelIdDetermined]
    end
    if not isDeconNPC then
        local craftType = GetCraftingInteractionType() --will be 0 if we are at a universal deconstruction NPC
        if craftType ~= CRAFTING_TYPE_INVALID then
            local filterPanelIdByCraftType
            if libFilters and libFilters.GetFilterTypeRespectingCraftType then
                filterPanelIdByCraftType = libFilters:GetFilterTypeRespectingCraftType(filterPanelId, craftType)
--d("[FCOIS]LibFilters detected the filterPanelIdByCraftType: " ..tos(filterPanelIdByCraftType))
            else
                local filterPanelIdToFilterPanelIdRespectingCrafttype = mappingVars.filterPanelIdToFilterPanelIdRespectingCrafttype
                filterPanelIdByCraftType = filterPanelIdToFilterPanelIdRespectingCrafttype[craftType] and filterPanelIdToFilterPanelIdRespectingCrafttype[craftType][filterPanelIdDetermined]
--d("[FCOIS]FCOIS detected the filterPanelIdByCraftType: " ..tos(filterPanelIdByCraftType))
            end
            if filterPanelIdByCraftType ~= nil then filterPanelIdDetermined = filterPanelIdByCraftType end
            if getWhereAreWe == true then
                local whereAreWeByCraftType = filterPanelIdToWhereAreWe[filterPanelIdByCraftType]
                if whereAreWeByCraftType ~= nil then whereAreWeDetermined = whereAreWeByCraftType end
            end
        end
    end
    if getWhereAreWe == true then
        return whereAreWeDetermined
    else
        return filterPanelIdDetermined
    end
end

--Determine which filterPanelId is currently active and set the whereAreWe variable
function FCOIS.GetWhereAreWe(panelId, panelIdAtCall, panelIdParent, bag, slot, isDragAndDrop, calledFromExternalAddon)
    --The number for the orientation (which filter panel ID and which sub-checks were done -> for the chat output and the alert message determination)
    local whereAreWe = FCOIS_CON_DESTROY
    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    local currentScene, currentSceneName = getCurrentSceneInfo()
    --Local settings pointer
    --local settings = FCOIS.settingsVars.settings
    local otherAddons = FCOIS.otherAddons

    --universal Deconstruction NPC is used?
    local isDeconNPC = checkIfUniversaldDeconstructionNPC(panelId)

    --======= WhereAreWe determination ============================================================
    --*********************************************************************************************************************************************************************************
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --CraftBagExtended at a mail send panel, the bank, guild bank, guild store, store or trade?
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    if not isDeconNPC and otherAddons.craftBagExtendedActive and INVENTORY_CRAFT_BAG and ((calledFromExternalAddon and panelId == LF_CRAFTBAG) or (not calledFromExternalAddon and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden()))) then
        panelIdParent = panelIdParent or FCOIS.gFilterWhereParent
        --Inside mail panel?
        if (calledFromExternalAddon and panelIdParent == LF_MAIL_SEND) or (not calledFromExternalAddon and (not ctrlVars.MAIL_SEND.control:IsHidden() or FCOIS.gFilterWhereParent == LF_MAIL_SEND)) then
            whereAreWe = FCOIS_CON_MAIL
            --Inside trading player 2 player panel?
        elseif (calledFromExternalAddon and panelIdParent == LF_TRADE) or (not calledFromExternalAddon and (not ctrlVars.PLAYER_TRADE.control:IsHidden() or FCOIS.gFilterWhereParent == LF_TRADE)) then
            whereAreWe = FCOIS_CON_TRADE
            --Are we at the store scene
        elseif currentSceneName == ctrlVars.vendorSceneName or (panelIdParent == LF_VENDOR_BUY or panelIdParent == LF_VENDOR_SELL or panelIdParent == LF_VENDOR_BUYBACK or panelIdParent == LF_VENDOR_SELL) then
            --Vendor buy
            if (calledFromExternalAddon and panelIdParent == LF_VENDOR_BUY) or (not calledFromExternalAddon and (FCOIS.gFilterWhereParent == LF_VENDOR_BUY or (not ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_BUY
                --Vendor sell
            elseif (calledFromExternalAddon and panelIdParent == LF_VENDOR_SELL) or (not calledFromExternalAddon and (FCOIS.gFilterWhereParent == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and not ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_SELL
                --Vendor buyback
            elseif (calledFromExternalAddon and panelIdParent == LF_VENDOR_BUYBACK) or (not calledFromExternalAddon and (FCOIS.gFilterWhereParent == LF_VENDOR_BUYBACK or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and not ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_BUYBACK
                --Vendor repair
            elseif (calledFromExternalAddon and panelIdParent == LF_VENDOR_SELL) or (not calledFromExternalAddon and (FCOIS.gFilterWhereParent == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and not ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_REPAIR
            end
            --Inside guild store selling?
        elseif (calledFromExternalAddon and panelIdParent == LF_GUILDSTORE_SELL) or (not calledFromExternalAddon and (not ctrlVars.GUILD_STORE:IsHidden() or FCOIS.gFilterWhereParent == LF_GUILDSTORE_SELL)) then
            whereAreWe = FCOIS_CON_GUILD_STORE_SELL
            --[[
            --There is no CraftBag or CraftBagExtended at a guild bank withdraw panel!
            --Are we at a guild bank and trying to withdraw some items by double clicking it?
            elseif (not ctrlVars.GUILD_BANK:IsHidden() or FCOIS.gFilterWhereParent == LF_GUILDBANK_WITHDRAW) then
                --TODO: Why FCOIS_CON_SELL here for Guildstore withdraw??? To test!
                whereAreWe = FCOIS_CON_SELL
            ]]
            --Are we at the inventory/bank/guild bank/house bank and trying to use/equip/deposit an item?
        elseif (calledFromExternalAddon and (panelIdParent == LF_BANK_DEPOSIT or panelIdParent == LF_GUILDBANK_DEPOSIT or panelIdParent == LF_HOUSE_BANK_DEPOSIT)) or (not calledFromExternalAddon and (FCOIS.gFilterWhereParent == LF_BANK_DEPOSIT or FCOIS.gFilterWhereParent == LF_GUILDBANK_DEPOSIT or FCOIS.gFilterWhereParent == LF_HOUSE_BANK_DEPOSIT)) then
            --Check if player or guild or house bank is active by checking current scene in scene manager, or using ZOs API functions
            if (IsGuildBankOpen() or IsBankOpen() or (currentSceneName ~= nil and (currentSceneName == ctrlVars.bankSceneName or currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.houseBankSceneName))) then
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
                whereAreWe = checkSingleItemProtection(bag, slot, panelId, panelIdAtCall, calledFromExternalAddon)
            end
            --Are we in the normal craftbag?
        else
            whereAreWe = FCOIS_CON_CRAFTBAG_DESTROY
        end

    --*********************************************************************************************************************************************************************************
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --Awesome Guild Store - Guild Store sell + sell directly from Bank
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --AwesomeGuildStore addon is active - We are at the guild store "sell" tab and are selling from the bank
    elseif (not isDeconNPC and otherAddons.AGSActive and ctrlVars.GUILD_STORE_SCENE:IsShowing()
        and ((calledFromExternalAddon and panelId == LF_BANK_WITHDRAW) or (not calledFromExternalAddon and (panelId == LF_BANK_WITHDRAW or ctrlVars.BANK_FRAGMENT:IsShowing())))) then
--d(">AwesomeGuildStore GuildStoreSell from bank - filterPanelId: " .. tos(panelId) ..", isDragAndDrop: " ..tos(isDragAndDrop))
        whereAreWe = FCOIS_CON_GUILD_STORE_SELL

    --*********************************************************************************************************************************************************************************
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --No Craftbag panels
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    else -- if FCOIS.otherAddons.craftBagExtendedActive and INVENTORY_CRAFT_BAG and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden()) then

        --Are we at an universal deconstruction NPC?
        if isDeconNPC == true then
            --d(">decon NPC! panelId: " .. tos(panelId) ..", isDragAndDrop: " ..tos(isDragAndDrop))
            whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(panelId, true, isDeconNPC)
            --*********************************************************************************************************************************************************************************
        else
            --Inside mail panel?
            if (calledFromExternalAddon and panelId == LF_MAIL_SEND) or (not calledFromExternalAddon and (not ctrlVars.MAIL_SEND.control:IsHidden() or panelId == LF_MAIL_SEND)) then
                whereAreWe = FCOIS_CON_MAIL
                --Inside trading player 2 player panel?
            elseif (calledFromExternalAddon and panelId == LF_TRADE) or (not calledFromExternalAddon and (not ctrlVars.PLAYER_TRADE.control:IsHidden() or panelId == LF_TRADE)) then
                whereAreWe = FCOIS_CON_TRADE
                --Are we at the store scene?
            elseif (calledFromExternalAddon and (panelId == LF_VENDOR_BUY or panelId == LF_VENDOR_SELL or panelId == LF_VENDOR_BUYBACK or panelId == LF_VENDOR_REPAIR)) or (not calledFromExternalAddon and (currentSceneName == ctrlVars.vendorSceneName or panelId == LF_VENDOR_BUY or panelId == LF_VENDOR_SELL or panelId == LF_VENDOR_BUYBACK or panelId == LF_VENDOR_REPAIR)) then
                --Vendor buy
                if (calledFromExternalAddon and panelId == LF_VENDOR_BUY) or (not calledFromExternalAddon and (panelId == LF_VENDOR_BUY or (not ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                    whereAreWe = FCOIS_CON_BUY
                    --Vendor sell
                elseif (calledFromExternalAddon and panelId == LF_VENDOR_SELL) or (not calledFromExternalAddon and (panelId == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and not ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                    whereAreWe = FCOIS_CON_SELL
                    --Vendor buyback
                elseif (calledFromExternalAddon and panelId == LF_VENDOR_BUYBACK) or (not calledFromExternalAddon and (panelId == LF_VENDOR_BUYBACK or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and not ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                    whereAreWe = FCOIS_CON_BUYBACK
                    --Vendor repair
                elseif (calledFromExternalAddon and panelId == LF_VENDOR_REPAIR) or (not calledFromExternalAddon and (panelId == LF_VENDOR_REPAIR or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and not ctrlVars.REPAIR_LIST:IsHidden()))) then
                    whereAreWe = FCOIS_CON_REPAIR
                end
                --Fence/Launder scene
            elseif (calledFromExternalAddon and (panelId == LF_FENCE_SELL or panelId == LF_FENCE_LAUNDER)) or (not calledFromExternalAddon and (currentSceneName == ctrlVars.FENCE_SCENE_NAME or panelId == LF_FENCE_SELL or panelId == LF_FENCE_LAUNDER)) then
                --Inside fence sell?
                if (calledFromExternalAddon and panelId == LF_FENCE_SELL) or (not calledFromExternalAddon and ((FENCE_KEYBOARD ~= nil and FENCE_KEYBOARD.mode ~= nil and FENCE_KEYBOARD.mode == ZO_MODE_STORE_SELL_STOLEN) or panelId == LF_FENCE_SELL)) then
                    whereAreWe = FCOIS_CON_FENCE_SELL
                    --Inside launder sell?
                elseif (calledFromExternalAddon and panelId == LF_FENCE_LAUNDER) or (not calledFromExternalAddon and ((FENCE_KEYBOARD ~= nil and FENCE_KEYBOARD.mode ~= nil and FENCE_KEYBOARD.mode == ZO_MODE_STORE_LAUNDER) or panelId == LF_FENCE_LAUNDER)) then
                    whereAreWe = FCOIS_CON_LAUNDER_SELL
                end
                --Inside crafting station refinement
            elseif (calledFromExternalAddon and (panelId == LF_SMITHING_REFINE or panelId == LF_JEWELRY_REFINE)) or (not calledFromExternalAddon and (not ctrlVars.REFINEMENT:IsHidden() or (panelId == LF_SMITHING_REFINE or panelId == LF_JEWELRY_REFINE))) then
                --[[
                local craftType = GetCraftingInteractionType()
                if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                    whereAreWe = FCOIS_CON_JEWELRY_REFINE
                else
                    whereAreWe = FCOIS_CON_REFINE
                end
                ]]
                whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_REFINE, true)
                --Inside crafting station deconstruction
            elseif (calledFromExternalAddon and (panelId == LF_SMITHING_DECONSTRUCT or panelId == LF_JEWELRY_DECONSTRUCT)) or (not calledFromExternalAddon and (not ctrlVars.DECONSTRUCTION:IsHidden() or (panelId == LF_SMITHING_DECONSTRUCT or panelId == LF_JEWELRY_DECONSTRUCT))) then
                --[[
                local craftType = GetCraftingInteractionType()
                if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                    whereAreWe = FCOIS_CON_JEWELRY_DECONSTRUCT
                else
                    whereAreWe = FCOIS_CON_DECONSTRUCT
                end
                ]]
                whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_DECONSTRUCT, true)
                --Inside crafting station improvement
            elseif (calledFromExternalAddon and (panelId == LF_SMITHING_IMPROVEMENT or panelId == LF_JEWELRY_IMPROVEMENT)) or (not calledFromExternalAddon and (not ctrlVars.IMPROVEMENT:IsHidden() or (panelId == LF_SMITHING_IMPROVEMENT or panelId == LF_JEWELRY_IMPROVEMENT))) then
                --[[local craftType = GetCraftingInteractionType()
                if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                    whereAreWe = FCOIS_CON_JEWELRY_IMPROVE
                else
                    whereAreWe = FCOIS_CON_IMPROVE
                end
                ]]
                whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_IMPROVEMENT, true)
                --Are we at the crafting stations research panel's popup list dialog?
            elseif (calledFromExternalAddon and (panelId == LF_SMITHING_RESEARCH_DIALOG or panelId == LF_JEWELRY_RESEARCH_DIALOG)) or (not calledFromExternalAddon and (isResearchListDialogShown() or (panelId == LF_SMITHING_RESEARCH_DIALOG or panelId == LF_JEWELRY_RESEARCH_DIALOG))) then
                --[[local craftType = GetCraftingInteractionType()
                if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                    whereAreWe = FCOIS_CON_JEWELRY_RESEARCH_DIALOG
                else
                    whereAreWe = FCOIS_CON_RESEARCH_DIALOG
                end
                ]]
                whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_RESEARCH_DIALOG, true)
                --Are we at the crafting stations research panel?
            elseif (calledFromExternalAddon and (panelId == LF_SMITHING_RESEARCH or panelId == LF_JEWELRY_RESEARCH)) or (not calledFromExternalAddon and (not ctrlVars.RESEARCH:IsHidden() or (panelId == LF_SMITHING_RESEARCH or panelId == LF_JEWELRY_RESEARCH))) then
                --[[local craftType = GetCraftingInteractionType()
                if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
                    whereAreWe = FCOIS_CON_JEWELRY_RESEARCH
                else
                    whereAreWe = FCOIS_CON_RESEARCH
                end
                ]]
                whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_RESEARCH, true)
                --Inside enchanting station
            elseif (calledFromExternalAddon and (panelId == LF_ENCHANTING_EXTRACTION or panelId == LF_ENCHANTING_CREATION)) or (not calledFromExternalAddon and (not ctrlVars.ENCHANTING_STATION:IsHidden() or (panelId == LF_ENCHANTING_EXTRACTION or panelId == LF_ENCHANTING_CREATION))) then
                --Enchanting Extraction panel?
                local enchantingMode = ENCHANTING:GetEnchantingMode()
                if panelId == LF_ENCHANTING_EXTRACTION or enchantingMode == ENCHANTING_MODE_EXTRACTION then
                    whereAreWe = FCOIS_CON_ENCHANT_EXTRACT
                    --Enchanting Creation panel?
                elseif panelId == LF_ENCHANTING_CREATION or enchantingMode == ENCHANTING_MODE_CREATION then
                    whereAreWe = FCOIS_CON_ENCHANT_CREATE
                end
                --Inside guild store selling?
            elseif (calledFromExternalAddon and panelId == LF_GUILDSTORE_SELL) or (not calledFromExternalAddon and (not ctrlVars.GUILD_STORE:IsHidden() or panelId == LF_GUILDSTORE_SELL)) then
                whereAreWe = FCOIS_CON_GUILD_STORE_SELL
                --Are we at the alchemy station?
            elseif (calledFromExternalAddon and panelId == LF_ALCHEMY_CREATION) or (not calledFromExternalAddon and (not ctrlVars.ALCHEMY_STATION:IsHidden() or panelId == LF_ALCHEMY_CREATION)) then
                whereAreWe = FCOIS_CON_ALCHEMY_DESTROY
                --Are we at a bank and trying to withdraw some items by double clicking it?
            elseif (calledFromExternalAddon and panelId == LF_BANK_WITHDRAW) or (not calledFromExternalAddon and (not ctrlVars.BANK:IsHidden() or panelId == LF_BANK_WITHDRAW)) then
                --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                whereAreWe = FCOIS_CON_FALLBACK
            elseif (calledFromExternalAddon and panelId == LF_HOUSE_BANK_WITHDRAW) or (not calledFromExternalAddon and (not ctrlVars.HOUSE_BANK:IsHidden() or panelId == LF_HOUSE_BANK_WITHDRAW)) then
                --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                whereAreWe = FCOIS_CON_FALLBACK
                --Are we at a guild bank and trying to withdraw some items by double clicking it?
            elseif (calledFromExternalAddon and panelId == LF_GUILDBANK_WITHDRAW) or (not calledFromExternalAddon and (not ctrlVars.GUILD_BANK:IsHidden() or panelId == LF_GUILDBANK_WITHDRAW)) then
                --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                whereAreWe = FCOIS_CON_FALLBACK
                --Are we at a transmutation/retrait station?
            elseif (calledFromExternalAddon and panelId == LF_RETRAIT) or (not calledFromExternalAddon and (isRetraitStationShown() or panelId == LF_RETRAIT)) then
                --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                whereAreWe = FCOIS_CON_RETRAIT
                -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                --Are we at a companion inventory?
            elseif (calledFromExternalAddon and panelId == LF_INVENTORY_COMPANION) or (not calledFromExternalAddon and (isCompanionInventoryShown() or panelId == LF_INVENTORY_COMPANION)) then
                whereAreWe = FCOIS_CON_COMPANION_DESTROY
                whereAreWe = checkIfItemShouldBeUsedOrEquipped(whereAreWe, bag, slot, panelId, panelIdAtCall, calledFromExternalAddon)
                -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                --Are we at the inventory/bank/guild bank and trying to use/equip/deposit an item?
            elseif (calledFromExternalAddon and (panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT))
                    or (not calledFromExternalAddon and (not ctrlVars.BACKPACK:IsHidden() or panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT)) then
                --Check if player or guild bank is active by checking current scene in scene manager
                if (calledFromExternalAddon and (panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT))
                        or (not calledFromExternalAddon and (IsGuildBankOpen() or IsBankOpen() or (currentSceneName ~= nil and (currentSceneName == ctrlVars.bankSceneName or currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.houseBankSceneName)))) then
                    --If bank/guild bank/house deposit tab is active
                    if (calledFromExternalAddon and (panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT)) or (not calledFromExternalAddon and ((ctrlVars.BANK:IsHidden() and ctrlVars.GUILD_BANK:IsHidden() and ctrlVars.HOUSE_BANK:IsHidden()) or (panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT))) then
                        --If the item is double clicked + marked deposit it, instead of blocking the deposit
                        --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                        whereAreWe = FCOIS_CON_FALLBACK
                        --Abort the checks here as items are always allowed to deposit at the bank/guildbank/house bank deposit tab
                        --but only if you do not use the mouse drag&drop (or context menu destroy)
                        if not isDragAndDrop then return false end
                    end
                end
                --Only do the item checks if the item should not be deposited at a bank/guild bank/house bank
                whereAreWe = checkIfItemShouldBeUsedOrEquipped(whereAreWe, bag, slot, panelId, panelIdAtCall, calledFromExternalAddon)
                -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                --All others: We are trying to destroy an item
            else
                whereAreWe = FCOIS_CON_DESTROY
            end
        end
    end --if FCOIS.otherAddons.craftBagExtendedActive and INVENTORY_CRAFT_BAG and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden()) then
    --*********************************************************************************************************************************************************************************
    --d("[FCOIS.GetWhereAreWe]panelId: " .. tos(panelId) .. ", panelIdAtCall: " .. tos(panelIdAtCall) .. ", calledFromExternalAddon: " ..tos(calledFromExternalAddon))
    return whereAreWe
end


--Get the "real" active panel.
--If you are at the bank e.g. panelId is 2 (FCOIS.gFilterWhere was set in event BANK_OPEN), but you could also be at the deposit tab which uses
--the normal inventory filters of panelId = 1. The same applies for mail, trade, and others
function FCOIS.CheckActivePanel(comingFrom, overwriteFilterWhere, isDeconNPC)
    if overwriteFilterWhere == nil then overwriteFilterWhere = false end
    local inventoryName
    local ctrlVars2 = FCOIS.ZOControlVars

    --Get the current scene's name to be able to distinguish between bank, guildbank, mail etc. when changing to CBE's craftbag panels
    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    local currentScene, currentSceneName = getCurrentSceneInfo()
    --Debug
    if FCOIS.settingsVars.settings.debug then
        local oldFilterWhere
        if comingFrom == 0 or comingFrom == nil then
            --Get the current filter panel id
            oldFilterWhere = FCOIS.gFilterWhere
        else
            oldFilterWhere = comingFrom
        end
        debugMessage( "[checkActivePanel]","Coming from/Before: " .. tos(oldFilterWhere) .. ", overwriteFilterWhere: " .. tos(overwriteFilterWhere) .. ", currentSceneName: " ..tos(currentSceneName), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED)
    end

    -- -v- #202 Universal deconstruction?
--d("[FCOIS.checkActivePanel] comingFrom/Before: " .. tos(comingFrom) .. ", isDeconNPC: " .. tos(isDeconNPC) .. ", overwriteFilterWhere: " ..tos(overwriteFilterWhere).. ", currentSceneName: " ..tos(currentSceneName))
    --universal Deconstruction NPC "Giladil"
    --> Return the original buttonParent via inventoryName so that we can create the buttons and then re-anchor them!
    --> But update the FCOIS.gFilterWhere with the current set filterPanelId at UNIVERSAL_DECONSTRUCTION.FCOIScurrentFilterPanelId
    if isDeconNPC == nil then isDeconNPC = checkIfUniversaldDeconstructionNPC(comingFrom) end
    if isDeconNPC == true then
--d(">>isDeconNPC: true")
        if universalDeconGlobal.FCOIScurrentFilterPanelId ~= nil then
            FCOIS.gFilterWhere = universalDeconGlobal.FCOIScurrentFilterPanelId
        else
            FCOIS.gFilterWhere = getCurrentFilterPanelIdAtDeconNPC(comingFrom)
        end
    end
    -- -^- #202 Universal deconstruction?
    ------------------------------------------------------------------------------------------------------------------------
    --Player bank
    if ((currentSceneName ~= nil and currentSceneName == ctrlVars2.bankSceneName) and not ctrlVars2.BANK:IsHidden()) or comingFrom == LF_BANK_WITHDRAW then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_BANK_WITHDRAW)
        inventoryName = ctrlVars2.BANK_INV
        --House bank
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.houseBankSceneName) and not ctrlVars2.HOUSE_BANK:IsHidden()) or comingFrom == LF_HOUSE_BANK_WITHDRAW then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_HOUSE_BANK_WITHDRAW)
        inventoryName = ctrlVars2.HOUSE_BANK_INV
        --Player inventory at bank (deposit)
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.bankSceneName) and ctrlVars2.BANK:IsHidden()) or comingFrom == LF_BANK_DEPOSIT then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_BANK_DEPOSIT)
        inventoryName = ctrlVars2.INV
        --Player inventory at house bank (deposit)
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.houseBankSceneName) and ctrlVars2.HOUSE_BANK:IsHidden()) or comingFrom == LF_HOUSE_BANK_DEPOSIT then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_HOUSE_BANK_DEPOSIT)
        inventoryName = ctrlVars2.INV
        --Guild bank
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.guildBankSceneName) and not ctrlVars2.GUILD_BANK:IsHidden()) or comingFrom == LF_GUILDBANK_WITHDRAW then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_GUILDBANK_WITHDRAW)
        inventoryName = ctrlVars2.GUILD_BANK_INV
        --Player inventory at guild bank (deposit)
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.guildBankSceneName) and ctrlVars2.GUILD_BANK:IsHidden()) or comingFrom == LF_GUILDBANK_DEPOSIT then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_GUILDBANK_DEPOSIT)
        inventoryName = ctrlVars2.INV
        --Trading house / Guild store
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars2.tradingHouseSceneName and not ctrlVars2.GUILD_STORE:IsHidden()) or comingFrom == LF_GUILDSTORE_SELL then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_GUILDSTORE_SELL)
        inventoryName = ctrlVars2.INV
        --Vendor buy
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.vendorSceneName) or comingFrom == LF_VENDOR_BUY) and not ctrlVars2.STORE:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_VENDOR_BUY)
        --inventoryName = ctrlVars2.VENDOR_SELL
        inventoryName = ctrlVars2.INV
        --Vendor sell (not showing the buy, buyback or repair tabs and showing the player inventory or the craftbag panel)
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.vendorSceneName) or comingFrom == LF_VENDOR_SELL)
            and (ctrlVars2.STORE:IsHidden() and ctrlVars2.STORE_BUY_BACK:IsHidden() and ctrlVars2.REPAIR_LIST:IsHidden()) then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_VENDOR_SELL)
        --inventoryName = ctrlVars2.VENDOR_SELL
        inventoryName = ctrlVars2.INV
        --Vendor buyback
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.vendorSceneName) or comingFrom == LF_VENDOR_BUYBACK) and not ctrlVars2.STORE_BUY_BACK:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_VENDOR_BUYBACK)
        --inventoryName = ctrlVars2.VENDOR_SELL
        inventoryName = ctrlVars2.INV
        --Vendor repair
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars2.vendorSceneName) or comingFrom == LF_VENDOR_REPAIR) and not ctrlVars2.REPAIR_LIST:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_VENDOR_REPAIR)
        --inventoryName = ctrlVars2.VENDOR_SELL
        inventoryName = ctrlVars2.INV
        --Fence
    elseif comingFrom == LF_FENCE_SELL then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_FENCE_SELL)
        --inventoryName = ctrlVars2.FENCE
        inventoryName = ctrlVars2.INV
        --Launder
    elseif comingFrom == LF_FENCE_LAUNDER then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_FENCE_LAUNDER)
        --inventoriyName = ctrlVars2.LAUNDER
        inventoryName = ctrlVars2.INV
        --Mail
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars2.mailSendSceneName and not ctrlVars2.MAIL_SEND.control:IsHidden()) or comingFrom == LF_MAIL_SEND then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_MAIL_SEND)
        --inventoryName = ctrlVars2.MAIL_SEND
        inventoryName = ctrlVars2.INV
        --Trade
    elseif not ctrlVars2.PLAYER_TRADE.control:IsHidden() or comingFrom == LF_TRADE then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_TRADE)
        --inventoryName = ctrlVars2.PLAYER_TRADE
        inventoryName = ctrlVars2.INV
        --Enchanting creation mode
    elseif comingFrom == LF_ENCHANTING_CREATION then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_ENCHANTING_CREATION)
        inventoryName = ctrlVars2.ENCHANTING_STATION
        --Enchanting extraction mode
    elseif comingFrom == LF_ENCHANTING_EXTRACTION then
        --Update the filterPanelId
        if not isDeconNPC then
            FCOIS.gFilterWhere = getFilterWhereBySettings(LF_ENCHANTING_EXTRACTION)
        end
        inventoryName = ctrlVars2.ENCHANTING_STATION
        --Enchanting
    elseif comingFrom == "ENCHANTING" then
        --Determine which enchanting mode is used
        --Enchanting creation mode
        if ctrlVars2.ENCHANTING.enchantingMode == 1 then
            --Update the filterPanelId
            comingFrom = LF_ENCHANTING_CREATION
            FCOIS.gFilterWhere = getFilterWhereBySettings(LF_ENCHANTING_CREATION)
            inventoryName = ctrlVars2.ENCHANTING_STATION
            --Enchanting extraction mode
        elseif ctrlVars2.ENCHANTING.enchantingMode == 2 then
            --Update the filterPanelId
            comingFrom = LF_ENCHANTING_EXTRACTION
            if not isDeconNPC then
                FCOIS.gFilterWhere = getFilterWhereBySettings(LF_ENCHANTING_EXTRACTION)
            end
            inventoryName = ctrlVars2.ENCHANTING_STATION
        end
        --Alchemy
    elseif not ctrlVars2.ALCHEMY_STATION:IsHidden() or comingFrom == LF_ALCHEMY_CREATION then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_ALCHEMY_CREATION)
        inventoryName = ctrlVars2.ALCHEMY_INV
        --Refinement
    elseif not ctrlVars2.REFINEMENT_INV:IsHidden() or (comingFrom == LF_SMITHING_REFINE or comingFrom == LF_JEWELRY_REFINE) then
        --[[
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_REFINE
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_REFINE
        end
        ]]
        local filterPanelId = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_REFINE, false, false)
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(filterPanelId)
        inventoryName = ctrlVars2.REFINEMENT_INV
        --Deconstruction
    elseif (not ctrlVars2.DECONSTRUCTION_INV:IsHidden() or (comingFrom == LF_SMITHING_DECONSTRUCT or comingFrom == LF_JEWELRY_DECONSTRUCT)) then
        --[[
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_DECONSTRUCT
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_DECONSTRUCT
        end
        ]]
        if not isDeconNPC then
            local filterPanelId = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_DECONSTRUCT, false, false)
            --Update the filterPanelId
            FCOIS.gFilterWhere = getFilterWhereBySettings(filterPanelId)
        end
        inventoryName = ctrlVars2.DECONSTRUCTION_INV
        --Improvement
    elseif not ctrlVars2.IMPROVEMENT_INV:IsHidden() or (comingFrom == LF_SMITHING_IMPROVEMENT or comingFrom == LF_JEWELRY_IMPROVEMENT) then
        --[[
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_IMPROVEMENT
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_IMPROVEMENT
        end
        ]]
        local filterPanelId = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_IMPROVEMENT, false, false)
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(filterPanelId)
        inventoryName = ctrlVars2.IMPROVEMENT_INV
        --Research dialog
    elseif isResearchListDialogShown() or (comingFrom == LF_SMITHING_RESEARCH_DIALOG or comingFrom == LF_JEWELRY_RESEARCH_DIALOG) then
        --[[
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_RESEARCH_DIALOG
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_RESEARCH_DIALOG
        end
        ]]
        local filterPanelId = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_RESEARCH_DIALOG, false, false)
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(filterPanelId)
        inventoryName = ctrlVars2.RESEARCH_POPUP_TOP_DIVIDER
        --Research
    elseif not ctrlVars2.RESEARCH:IsHidden() or (comingFrom == LF_SMITHING_RESEARCH or comingFrom == LF_JEWELRY_RESEARCH) then
        --[[
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_RESEARCH
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_RESEARCH
        end
        ]]
        local filterPanelId = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_RESEARCH, false, false)
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(filterPanelId)
        inventoryName = ctrlVars2.RESEARCH
        --Retrait
    elseif (isRetraitStationShown() or comingFrom == LF_RETRAIT) then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_RETRAIT)
        inventoryName = ctrlVars2.RETRAIT_INV
        --Companion inventory
    elseif (isCompanionInventoryShown() or comingFrom == LF_INVENTORY_COMPANION) then
--d(">[FCOIS]CheckActivePanel - Companion inventory -> FCOIS.gFilterWhere = LF_INVENTORY_COMPANION - LF3 isCompInvShown: " ..tos(libFilters:IsCompanionInventoryShown()))
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY_COMPANION)
        inventoryName = ctrlVars2.COMPANION_INV_CONTROL
        --Player inventory
    elseif not ctrlVars2.INV:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY)
        inventoryName = ctrlVars2.INV
        --Craft bag
    elseif (not ctrlVars2.CRAFTBAG:IsHidden() or comingFrom == LF_CRAFTBAG) then
        --Update the filterPanelId
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_CRAFTBAG)
        inventoryName = ctrlVars2.CRAFTBAG

    else
        --Update the filterPanelId with a standard value
        FCOIS.gFilterWhere = getFilterWhereBySettings(LF_INVENTORY)
        inventoryName = ctrlVars2.INV
    end
    --end     -- #202 Universal deconstruction?

    --Set the return variable for the currently active filter panel
    local panelType = FCOIS.gFilterWhere

    --Overwrite the FCOIS panelID with the one from the function parameter?
    --(e.g. at the CraftBag Extended mail panel the filterPanel will be LF_MAIL. This will be moved to the "parent panel". And the filterPanel will be overwritten with LF_CRAFTBAG)
    if overwriteFilterWhere then
        FCOIS.gFilterWhere = overwriteFilterWhere
        --CraftBagExtended is active?
        if overwriteFilterWhere == LF_CRAFTBAG and FCOIS.CheckIfCBEorAGSActive(FCOIS.gFilterWhereParent, true) then
            inventoryName = ctrlVars2.CRAFTBAG
        end
    end

    if FCOIS.settingsVars.settings.debug then debugMessage( "[checkActivePanel]",">> after: " .. tos(FCOIS.gFilterWhere) .. ", inventoryName: " .. tos(inventoryName) .. ", filterParentPanel: " .. tos(panelType), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    --d("[FCOIS.checkActivePanel]>> after: " .. tos(FCOIS.gFilterWhere) .. ", inventoryName: " .. tos(inventoryName) .. ", filterParentPanel: " .. tos(panelType))
    --d( ">> after: " .. tos(FCOIS.gFilterWhere) .. ", inventoryName: " .. tos(inventoryName) .. ", filterParentPanel: " .. tos(panelType))

    --Return the found inventory variable (e.g. ZO_PlayerInventory) and the LibFilters filter panel ID (e.g. LF_BANK_WITHDRAW)
    return inventoryName, panelType
end

--Function to set the anti checks at a panel variable to true or false
--and change depending anti check panels accordingly
-->Used in files src/FCOIS_SettingsMenu.lua and src/FCOIS_Workarounds.lua
function FCOIS.UpdateAntiCheckAtPanelVariable(iconNr, panelId, value)
    value = value or false
    if iconNr == nil or panelId == nil then return false end
    --Check depending panelIds
    --[[
    --Inventory
    if panelId == LF_INVENTORY then
        --Must change the bank, guild bank and house bank withdraw/deposit panels as well
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_BANK_DEPOSIT] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_GUILDBANK_DEPOSIT] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_HOUSE_BANK_DEPOSIT] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_BANK_WITHDRAW] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_GUILDBANK_WITHDRAW] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_HOUSE_BANK_WITHDRAW] = value
    end
    ]]
    local dependingAntiCheckPaneIldsAtPanelId = mappingVars.dependingAntiCheckPanelIdsAtPanelId
    local dependingPanelIds = dependingAntiCheckPaneIldsAtPanelId[panelId]
    if dependingPanelIds ~= nil then
        for _, dependingPanelId in ipairs(dependingPanelIds) do
            FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[dependingPanelId] = value
        end
    end
    --All others (including LF_INVENTORY)
    FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[panelId] = value
end

--Run some functions as a panel gets closed/hidden (e.g. sthe store, crafting tables etc.)
--and re-enable the protection if it was disabled, and the setting to auto-reenable it is enabled
function FCOIS.OnClosePanel(panelIdClosed, panelIdToShow, autoReEnableCheck)
--d("[FCOIS]OnClosePanel-panelIdClosed: " ..tos(panelIdClosed) .. ", panelIdToShow: " ..tos(panelIdToShow) .. ", autoReEnableCheck: " ..tos(autoReEnableCheck))
    --Hide the context menu at last active panel
    if panelIdClosed ~= nil then
        hideContextMenu(panelIdClosed)
    end

--d(">FCOIS.gFilterWhere1.1: " .. tos(FCOIS.gFilterWhere))

    if FCOIS.preventerVars.gNoCloseEvent == false then
        --Update the inventory filter buttons
        if panelIdToShow ~= nil then
            if  panelIdToShow == LF_INVENTORY then
                updateFCOISFilterButtonsAtInventory(-1)
            end
--d(">FCOIS.gFilterWhere1.2: " .. tos(FCOIS.gFilterWhere))

            --Update the 4 inventory button's color
            updateFCOISFilterButtonColorsAndTextures(-1, nil, -1, panelIdToShow)
--d(">FCOIS.gFilterWhere1.3: " .. tos(FCOIS.gFilterWhere))
            --Change the button color of the context menu invoker
            changeContextMenuInvokerButtonColorByPanelId(panelIdToShow)
--d(">FCOIS.gFilterWhere1.4: " .. tos(FCOIS.gFilterWhere))
        end
    end
    FCOIS.preventerVars.gNoCloseEvent 	 = false
    FCOIS.preventerVars.gActiveFilterPanel = false

    --Check, if the Anti-* checks need to be enabled again
    if autoReEnableCheck ~= nil then
        if type(autoReEnableCheck) == "table" then
            for _, autoReEnableCheckName in ipairs(autoReEnableCheck) do
                autoReenableAntiSettingsCheck(autoReEnableCheckName)
            end
        else
            autoReenableAntiSettingsCheck(autoReEnableCheck)
--d(">FCOIS.gFilterWhere1.5: " .. tos(FCOIS.gFilterWhere))
        end
    end
end