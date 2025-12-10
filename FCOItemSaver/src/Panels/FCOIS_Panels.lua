--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local tos = tostring
local gil = GetItemLink

local libFilters = FCOIS.libFilters

local FCOIS_CON_DESTROY = FCOIS_CON_DESTROY
local FCOIS_CON_CONTAINER_AUTOOLOOT = FCOIS_CON_CONTAINER_AUTOOLOOT
local FCOIS_CON_RECIPE_USAGE = FCOIS_CON_RECIPE_USAGE
local FCOIS_CON_MOTIF_USAGE = FCOIS_CON_MOTIF_USAGE
local FCOIS_CON_COLLECTIBLE_USAGE = FCOIS_CON_COLLECTIBLE_USAGE
local FCOIS_CON_POTION_USAGE = FCOIS_CON_POTION_USAGE
local FCOIS_CON_FOOD_USAGE = FCOIS_CON_FOOD_USAGE
local FCOIS_CON_CROWN_ITEM = FCOIS_CON_CROWN_ITEM
local FCOIS_CON_FALLBACK = FCOIS_CON_FALLBACK
local FCOIS_CON_FILTER_BUTTONS_ALL          = FCOIS_CON_FILTER_BUTTONS_ALL
local FCOIS_CON_FILTER_BUTTON_STATUS_ALL = FCOIS_CON_FILTER_BUTTON_STATUS_ALL
local fallbackToDefaultDestroyWhereAreWe = FCOIS_CON_DESTROY

local LF_INVENTORY = LF_INVENTORY
local LF_BANK_WITHDRAW = LF_BANK_WITHDRAW
local LF_BANK_DEPOSIT = LF_BANK_DEPOSIT
local LF_GUILDBANK_DEPOSIT = LF_GUILDBANK_DEPOSIT
local LF_VENDOR_BUY = LF_VENDOR_BUY
local LF_VENDOR_SELL = LF_VENDOR_SELL
local LF_VENDOR_BUYBACK = LF_VENDOR_BUYBACK
local LF_GUILDSTORE_SELL = LF_GUILDSTORE_SELL
local LF_MAIL_SEND = LF_MAIL_SEND
local LF_TRADE = LF_TRADE
local LF_ENCHANTING_EXTRACTION = LF_ENCHANTING_EXTRACTION
local LF_ENCHANTING_CREATION = LF_ENCHANTING_CREATION
local LF_CRAFTBAG = LF_CRAFTBAG
local LF_HOUSE_BANK_DEPOSIT = LF_HOUSE_BANK_DEPOSIT
local LF_INVENTORY_COMPANION = LF_INVENTORY_COMPANION
local LF_FURNITURE_VAULT_DEPOSIT = LF_FURNITURE_VAULT_DEPOSIT

--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

local ctrlVars = FCOIS.ZOControlVars
local universalDeconGlobal = ctrlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL
--local universalDeconPanel = universalDeconGlobal and universalDeconGlobal.deconstructionPanel

local enchantingStation = ctrlVars.ENCHANTING_STATION
local enchantingModeToData = {
    [1] = { filterPanelId = LF_ENCHANTING_CREATION,     inventoryName = enchantingStation },
    [2] = { filterPanelId = LF_ENCHANTING_EXTRACTION,   inventoryName = enchantingStation },
}
local checkIfCBEorAGSActive

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
--local panelIdSupportedAtDeconNPC = mappingVars.panelIdSupportedAtUniversalDeconstructionNPC
--local panelIdByDeconNPCMenuBarTabButtonName = mappingVars.panelIdByUniversalDeconstructionNPCMenuBarTabButtonName

local libFiltersPanelIdToInventory = mappingVars.libFiltersPanelIdToInventoryControl
--local libFiltersPanelIdToCraftingPanelInventory = mappingVars.libFiltersPanelIdToCraftingPanelInventory

--local universalDeconInvCtrl = ctrlVars.UNIVERSAL_DECONSTRUCTION_INV
--local universaldDeconScene = ctrlVars.UNIVERSAL_DECONSTRUCTON_SCENE
--local universaldDeconMenuBarTabs = ctrlVars.UNIVERSAL_DECONSTRUCTION_MENUBAR_TABS
local checkIfCBEActive = FCOIS.CheckIfCBEActive --#309
local checkIfAGSActive = FCOIS.CheckIfAGSActive --#309
local checkIfAGSShowsCustomPanelAtGuildStore = FCOIS.CheckIfAGSShowsCustomPanelAtGuildStore --#309

local filterPanelIdToWhereAreWe
local whereAreWeToFilterPanelIdSpecial
local libFilters_GetCurrentFilterType
local libFilters_GetFilterTypeRespectingCraftType

--==========================================================================================================================================
--                                          FCOIS - Panel functions
--==========================================================================================================================================

--Function to check a single item's type and get the whereAreWe ID. If we return FCOIS_CON_FALLBACK item should not be protected (e.g. at drag&drop or double click)
local function getWhereAreWeOnSingleItem(p_bag, p_slotIndex, panelId, panelIdAtCall, calledFromExternalAddon)
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[getWhereAreWeOnSingleItem]","panelId: " .. tos(panelId) .. ", calledFromExternalAddon: " ..tos(calledFromExternalAddon), true, FCOIS_DEBUG_DEPTH_ALL) end
    if p_bag == nil or p_slotIndex == nil then return false end
    local locWhereAreWe = FCOIS_CON_DESTROY

    local wasDragged = FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler

    local itemType = GetItemType(p_bag, p_slotIndex)

    --[[
    if itemType == ITEMTYPE_COLLECTIBLE then --for debugging --#318
        d("[FCOIS]checkSingleItemProtection -> collectible: " .. GetItemLink(p_bag, p_slotIndex))
    end
    ]]

    --Are we trying to open a container with autoloot on?
    if (isAutolootContainer(p_bag, p_slotIndex)) then
        locWhereAreWe = FCOIS_CON_CONTAINER_AUTOOLOOT
        --Read recipe?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_RECIPE, itemType)) then
        locWhereAreWe = FCOIS_CON_RECIPE_USAGE
        --Read style motif?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_RACIAL_STYLE_MOTIF, itemType)) then
        locWhereAreWe = FCOIS_CON_MOTIF_USAGE
        --Read golden collectible box style?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_COLLECTIBLE, itemType)) then --#318
        locWhereAreWe = FCOIS_CON_COLLECTIBLE_USAGE
--d(">locWhereAreWe = FCOIS_CON_COLLECTIBLE_USAGE")
        --Drink potion?
    elseif (isItemType(p_bag, p_slotIndex, ITEMTYPE_POTION, itemType)) then
        locWhereAreWe = FCOIS_CON_POTION_USAGE
        --Eat food?
    elseif (isItemType(p_bag, p_slotIndex, {ITEMTYPE_FOOD, ITEMTYPE_DRINK}, itemType)) then
        locWhereAreWe = FCOIS_CON_FOOD_USAGE
        --Use crown store item?
    elseif (isItemType(p_bag, p_slotIndex, {ITEMTYPE_CROWN_ITEM, ITEMTYPE_CROWN_REPAIR}, itemType)) then
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
    --#274 Fix usable items getting protected as drag&drop is taking place at quickslot wheel
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
--d("[FCOIS]checkIfItemShouldBeUsedOrEquipped - p_whereAreWe: " .. tos(p_whereAreWe))
    --Get the whereAreWe panel ID by checking the item's type etc. now and allow equipping items via double click e.g.
    --by returning the FCOIS_CON_FALLBACK value
    return ((p_whereAreWe ~= FCOIS_CON_FALLBACK and getWhereAreWeOnSingleItem(p_bag, p_slot, panelId, panelIdAtCall, calledFromExternalAddon))) or p_whereAreWe
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
    local whereAreWeDetermined
    local filterPanelIdDetermined = filterPanelId
    if getWhereAreWe == true then
        filterPanelIdToWhereAreWe = filterPanelIdToWhereAreWe or mappingVars.filterPanelIdToWhereAreWe
        whereAreWeDetermined = filterPanelIdToWhereAreWe[filterPanelIdDetermined]
--d("[FCOIS]getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType-filterPanelId: " ..tos(filterPanelId) .. ", whereAreWe: " .. tos(whereAreWeDetermined))
    end
    if not isDeconNPC then
        local craftType = GetCraftingInteractionType() --will be 0 if we are at a universal deconstruction NPC
        if craftType ~= CRAFTING_TYPE_INVALID then
            local filterPanelIdByCraftType
            --if libFilters and libFilters.GetFilterTypeRespectingCraftType then
                libFilters_GetFilterTypeRespectingCraftType = libFilters_GetFilterTypeRespectingCraftType or libFilters.GetFilterTypeRespectingCraftType
                filterPanelIdByCraftType = libFilters_GetFilterTypeRespectingCraftType(libFilters, filterPanelId, craftType)
--d("[FCOIS]LibFilters detected the filterPanelIdByCraftType: " ..tos(filterPanelIdByCraftType))
            --[[
            else
                local filterPanelIdToFilterPanelIdRespectingCrafttype = mappingVars.filterPanelIdToFilterPanelIdRespectingCrafttype
                filterPanelIdByCraftType = filterPanelIdToFilterPanelIdRespectingCrafttype[craftType] and filterPanelIdToFilterPanelIdRespectingCrafttype[craftType][filterPanelIdDetermined]
--d("[FCOIS]FCOIS detected the filterPanelIdByCraftType: " ..tos(filterPanelIdByCraftType))
            end
            ]]
            if filterPanelIdByCraftType ~= nil then filterPanelIdDetermined = filterPanelIdByCraftType end
            if getWhereAreWe == true then
                local whereAreWeByCraftType = filterPanelIdToWhereAreWe[filterPanelIdByCraftType]
                if whereAreWeByCraftType ~= nil then
                    whereAreWeDetermined = whereAreWeByCraftType
--d(">whereAreWe changed to carftType dependent: " ..tos(whereAreWeDetermined))
                end
            end
        end
    end
    if getWhereAreWe == true then
        return whereAreWeDetermined
    else
        return filterPanelIdDetermined
    end
end

local function getWhereAreWeInventorySpecial(whereAreWe, calledFromExternalAddon, panelId, panelIdAtCall, bag, slot, isDragAndDrop)
--d("[FCOIS]getWhereAreWeInventorySpecial-whereAreWe: " ..tos(whereAreWe) .. ", panelId: " ..tos(panelId))

    --Are we at a companion inventory?
    if (calledFromExternalAddon and (panelId == LF_INVENTORY_COMPANION or whereAreWe == FCOIS_CON_COMPANION_DESTROY))
        or (not calledFromExternalAddon and (whereAreWe == FCOIS_CON_COMPANION_DESTROY or (isCompanionInventoryShown() or panelId == LF_INVENTORY_COMPANION))) then
        whereAreWe = checkIfItemShouldBeUsedOrEquipped(FCOIS_CON_COMPANION_DESTROY, bag, slot, panelId, panelIdAtCall, calledFromExternalAddon)

    --Are we at the inventory/bank/guild bank/furniture vault and trying to use/equip/deposit an item?
    elseif (calledFromExternalAddon and (panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT or panelId == LF_FURNITURE_VAULT_DEPOSIT))
            or (not calledFromExternalAddon and (not ctrlVars.BACKPACK:IsHidden() or panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT or panelId == LF_FURNITURE_VAULT_DEPOSIT)) then
--d(">PLAYER_INVENTORY or deposit bank")
        local _, currentSceneName = getCurrentSceneInfo()

        --Check if player inventory, player bank, guild bank or furniture vault is active by checking current scene in scene manager
        if (calledFromExternalAddon and (panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT)) -- or panelId == LF_FURNITURE_VAULT_DEPOSIT
                or (not calledFromExternalAddon and (IsGuildBankOpen() or IsBankOpen() or (currentSceneName ~= nil and (currentSceneName == ctrlVars.bankSceneName or currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.houseBankSceneName)))) then --or currentSceneName == ctrlVars.furnitureVaultSceneName
            --If bank/guild bank/house deposit tab is active
            if (calledFromExternalAddon and (panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT)) or (not calledFromExternalAddon and ((ctrlVars.BANK:IsHidden() and ctrlVars.GUILD_BANK:IsHidden() and ctrlVars.HOUSE_BANK:IsHidden()) or (panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT))) then
    --d(">>deposit bank")
                --If the item is double clicked + marked deposit it, instead of blocking the deposit
                --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                whereAreWe = FCOIS_CON_FALLBACK
                --Abort the checks here as items are always allowed to deposit at the bank/guildbank/house bank deposit tab
                --but only if you do not use the mouse drag&drop (or context menu destroy)
                if not isDragAndDrop then
--d("<[ABORT]no drag&drop, returning FALSE!")
                    return false, true
                end
            end
        end
        --Only do the item checks if the item should not be deposited at a bank/guild bank/house bank
        whereAreWe = checkIfItemShouldBeUsedOrEquipped(whereAreWe, bag, slot, panelId, panelIdAtCall, calledFromExternalAddon)
--d(">whereAreWe ItemUsage: " .. tos(whereAreWe))
    end
    return whereAreWe, nil
end

local function getWhereAreWeByPanelOrLibFilters(calledFromExternalAddon, filterPanelId, panelIdAtCall, bag, slot, isDragAndDrop) --#2025_999
    local isItemDepositToBankProcess
    libFilters_GetCurrentFilterType = libFilters_GetCurrentFilterType or libFilters.GetCurrentFilterType
--d("[FCOIS]getWhereAreByPanelOrLibFilters-External: " ..tos(calledFromExternalAddon) .. ", filterPanelId: " .. tos(filterPanelId) .. "/FCOIS.gFilterWhere: " .. tos(FCOIS.gFilterWhere))
    if filterPanelId == nil then
        --if called from an external addon the panelId needs to be passed in, or else we cannot assure the correct panelId checked!
        if calledFromExternalAddon then return fallbackToDefaultDestroyWhereAreWe, nil end

        --Not calling externall but no panelId -- Try to find the panelId by help of the active control, scene, fragment, userdata etc. -> using LibFilters-3.0
        filterPanelId = libFilters_GetCurrentFilterType(libFilters)
--d(">filterPanelId determined by LibFilters: " .. tos(filterPanelId))
    end
    --Fallback: We are trying to destroy an item
    if filterPanelId == nil then return fallbackToDefaultDestroyWhereAreWe, nil end

    --Get whereArWe by the filterPanelId, and craftingType
    local whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(filterPanelId, true, false)
--d(">>whereAreWe by filterPanelId: " .. tos(whereAreWe))

    --WhereAreWe was not determined or is the fallback entry or any special entry for inventory item usage e.g.:
    --Check if we are at companion inventory, or normal inventory or bank deposits etc.
    whereAreWeToFilterPanelIdSpecial = whereAreWeToFilterPanelIdSpecial or mappingVars.whereAreWeToFilterPanelIdSpecial
    if whereAreWe == nil or (whereAreWe == fallbackToDefaultDestroyWhereAreWe or whereAreWeToFilterPanelIdSpecial[whereAreWe] ~= nil) then
        whereAreWe, isItemDepositToBankProcess = getWhereAreWeInventorySpecial(whereAreWe, calledFromExternalAddon, filterPanelId, panelIdAtCall, bag, slot, isDragAndDrop)
    end
--d(">>whereAreWe: " .. tos(whereAreWe) .. ", isItemDepositToBankProcess: " ..tos(isItemDepositToBankProcess))
    return whereAreWe, isItemDepositToBankProcess
end


--Determine which filterPanelId is currently active and set the whereAreWe variable
function FCOIS.GetWhereAreWe(panelId, panelIdAtCall, panelIdParent, bag, slot, isDragAndDrop, calledFromExternalAddon)
    local isItemDepositToBankProcess
    --The number for the orientation (which filter panel ID and which sub-checks were done -> for the chat output and the alert message determination)
    local whereAreWe = fallbackToDefaultDestroyWhereAreWe --Fall back to DESTROY
    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    local _, currentSceneName = getCurrentSceneInfo()
    --Local settings pointer
    --local settings = FCOIS.settingsVars.settings
    --local otherAddons = FCOIS.otherAddons

    --universal Deconstruction NPC is used?
    local isDeconNPC = checkIfUniversaldDeconstructionNPC(panelId)

    local parentFilterPanelId = FCOIS.gFilterWhereParent --#309

    --======= WhereAreWe determination ============================================================
    local cbeActive, agsActive, agsShowsCustomPanelAtGuildStore
    if not isDeconNPC then --#309
        cbeActive = checkIfCBEActive(nil, true)     --#309
        agsActive = checkIfAGSActive(nil, true)     --#309
        agsShowsCustomPanelAtGuildStore = checkIfAGSShowsCustomPanelAtGuildStore(panelId, agsActive) --#309
    end

    --todo debugging --#2025_999
    --[[
    if panelId == LF_MAIL_SEND or panelIdAtCall == LF_MAIL_SEND then
        d("[FCOIS]GetWhereAreWe-" .. gil(bag, slot) .. ", isDragAndDrop: " ..tos(isDragAndDrop) ..", panelId: " ..tos(panelId) .. ", panelIdAtCall: " .. tos(panelIdAtCall) .. ", panelIdParent: " .. tos(panelIdParent) .. ", parentFilterPanelId: " ..tos(parentFilterPanelId) ..", calledFromExternalAddon: " ..tos(calledFromExternalAddon).. ", isDeconNPC: " ..tos(isDeconNPC))
    end
    ]]

    --*********************************************************************************************************************************************************************************
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --CraftBagExtended at a mail send panel, the bank, guild bank, guild store, store or trade?
    --Or AwesomeGuildStore's craftbag at guild store --#309
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    if not isDeconNPC and cbeActive and INVENTORY_CRAFT_BAG and ((calledFromExternalAddon and panelId == LF_CRAFTBAG) or (not calledFromExternalAddon and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden()))) then
        panelIdParent = panelIdParent or parentFilterPanelId
        --Inside mail panel?
        if (calledFromExternalAddon and panelIdParent == LF_MAIL_SEND) or (not calledFromExternalAddon and (not ctrlVars.MAIL_SEND.control:IsHidden() or parentFilterPanelId == LF_MAIL_SEND)) then
            whereAreWe = FCOIS_CON_MAIL
            --Inside trading player 2 player panel?
        elseif (calledFromExternalAddon and panelIdParent == LF_TRADE) or (not calledFromExternalAddon and (not ctrlVars.PLAYER_TRADE.control:IsHidden() or parentFilterPanelId == LF_TRADE)) then
            whereAreWe = FCOIS_CON_TRADE
            --Are we at the store scene
        elseif currentSceneName == ctrlVars.vendorSceneName or (panelIdParent == LF_VENDOR_BUY or panelIdParent == LF_VENDOR_SELL or panelIdParent == LF_VENDOR_BUYBACK or panelIdParent == LF_VENDOR_SELL) then
            --Vendor buy
            if (calledFromExternalAddon and panelIdParent == LF_VENDOR_BUY) or (not calledFromExternalAddon and (parentFilterPanelId == LF_VENDOR_BUY or (not ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_BUY
                --Vendor sell
            elseif (calledFromExternalAddon and panelIdParent == LF_VENDOR_SELL) or (not calledFromExternalAddon and (parentFilterPanelId == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and not ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_SELL
                --Vendor buyback
            elseif (calledFromExternalAddon and panelIdParent == LF_VENDOR_BUYBACK) or (not calledFromExternalAddon and (parentFilterPanelId == LF_VENDOR_BUYBACK or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and not ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_BUYBACK
                --Vendor repair
            elseif (calledFromExternalAddon and panelIdParent == LF_VENDOR_SELL) or (not calledFromExternalAddon and (parentFilterPanelId == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and not ctrlVars.REPAIR_LIST:IsHidden()))) then
                whereAreWe = FCOIS_CON_REPAIR
            end
        --Inside guild store selling?
        elseif (calledFromExternalAddon and panelIdParent == LF_GUILDSTORE_SELL) or (not calledFromExternalAddon and (not ctrlVars.GUILD_STORE:IsHidden() or parentFilterPanelId == LF_GUILDSTORE_SELL)) then
            --There is a CraftBag at a guild bank withdraw panel, but only if AwesomeGuildStore is enabled
            if agsShowsCustomPanelAtGuildStore then         --#309
                whereAreWe = FCOIS_CON_GUILD_STORE_SELL
            else
                whereAreWe = FCOIS_CON_CRAFTBAG_DESTROY     --#309
            end
            --[[
            --Are we at a guild bank and trying to withdraw some items by double clicking it?
            elseif (not ctrlVars.GUILD_BANK:IsHidden() or parentFilterPanelId == LF_GUILDBANK_WITHDRAW) then
                --TODO: Why FCOIS_CON_SELL here for Guildstore withdraw??? To test!
                whereAreWe = FCOIS_CON_SELL
            ]]
            --Are we at the inventory/bank/guild bank/house bank and trying to use/equip/deposit an item?
        elseif (calledFromExternalAddon and (panelIdParent == LF_BANK_DEPOSIT or panelIdParent == LF_GUILDBANK_DEPOSIT or panelIdParent == LF_HOUSE_BANK_DEPOSIT)) or (not calledFromExternalAddon and (parentFilterPanelId == LF_BANK_DEPOSIT or parentFilterPanelId == LF_GUILDBANK_DEPOSIT or parentFilterPanelId == LF_HOUSE_BANK_DEPOSIT)) then
            --Check if player or guild or house bank is active by checking current scene in scene manager, or using ZOs API functions
            if (IsGuildBankOpen() or IsBankOpen() or (currentSceneName ~= nil and (currentSceneName == ctrlVars.bankSceneName or currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.houseBankSceneName))) then
                --If bank/guild bank/house bank deposit tab is active
                if ctrlVars.BANK:IsHidden() and ctrlVars.GUILD_BANK:IsHidden() and ctrlVars.HOUSE_BANK:IsHidden() and ctrlVars.FURNITURE_VAULT:IsHidden() then
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
                whereAreWe = getWhereAreWeOnSingleItem(bag, slot, panelId, panelIdAtCall, calledFromExternalAddon)
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
    elseif (not isDeconNPC and agsShowsCustomPanelAtGuildStore) then  --#309
        panelIdParent = panelIdParent or parentFilterPanelId
        if (INVENTORY_CRAFT_BAG and ((calledFromExternalAddon and panelId == LF_CRAFTBAG) or (not calledFromExternalAddon and (panelId == LF_CRAFTBAG or not ctrlVars.CRAFTBAG:IsHidden())))) then --#309
            whereAreWe = FCOIS_CON_GUILD_STORE_SELL

        elseif ((calledFromExternalAddon and panelId == LF_BANK_WITHDRAW) or (not calledFromExternalAddon and (panelId == LF_BANK_WITHDRAW or ctrlVars.BANK_FRAGMENT:IsShowing()))) then --#309
            whereAreWe = FCOIS_CON_GUILD_STORE_SELL

        else
            --whereAreWe = FCOIS_CON_GUILD_STORE_SELL
            --Fallback - Should not happen --#309
            whereAreWe = fallbackToDefaultDestroyWhereAreWe
        end




    --*********************************************************************************************************************************************************************************
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --No Craftbag or other addon's custom panels
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    --------------------------------------------------------------------------------------------------------------------
    else

        --Are we at an universal deconstruction NPC?
        if isDeconNPC == true then
            --d(">decon NPC! panelId: " .. tos(panelId) ..", isDragAndDrop: " ..tos(isDragAndDrop))
            whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(panelId, true, isDeconNPC)
            --*********************************************************************************************************************************************************************************

        else
            whereAreWe, isItemDepositToBankProcess = getWhereAreWeByPanelOrLibFilters(calledFromExternalAddon, panelId, panelIdAtCall, bag, slot, isDragAndDrop) --#2025_999
            --Did the inventory/banks deposit check return false as we did not drag&drop (and thus wanted to destroy an item) -> then return false here too!
            if whereAreWe == false and isItemDepositToBankProcess == true then return false end

            --[[
                --Inside mail panel?
                if (calledFromExternalAddon and panelId == LF_MAIL_SEND) or (not calledFromExternalAddon and (not ctrlVars.MAIL_SEND.control:IsHidden() or panelId == LF_MAIL_SEND)) then
                    whereAreWe = FCOIS_CON_MAIL     --OK
                    --Inside trading player 2 player panel?
                elseif (calledFromExternalAddon and panelId == LF_TRADE) or (not calledFromExternalAddon and (not ctrlVars.PLAYER_TRADE.control:IsHidden() or panelId == LF_TRADE)) then
                    whereAreWe = FCOIS_CON_TRADE    --OK
                    --Are we at the store scene?
                elseif (calledFromExternalAddon and (panelId == LF_VENDOR_BUY or panelId == LF_VENDOR_SELL or panelId == LF_VENDOR_BUYBACK or panelId == LF_VENDOR_REPAIR)) or (not calledFromExternalAddon and (currentSceneName == ctrlVars.vendorSceneName or panelId == LF_VENDOR_BUY or panelId == LF_VENDOR_SELL or panelId == LF_VENDOR_BUYBACK or panelId == LF_VENDOR_REPAIR)) then
                    --Vendor buy
                    if (calledFromExternalAddon and panelId == LF_VENDOR_BUY) or (not calledFromExternalAddon and (panelId == LF_VENDOR_BUY or (not ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                        whereAreWe = FCOIS_CON_BUY    --OK
                        --Vendor sell
                    elseif (calledFromExternalAddon and panelId == LF_VENDOR_SELL) or (not calledFromExternalAddon and (panelId == LF_VENDOR_SELL or (ctrlVars.STORE:IsHidden() and not ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                        whereAreWe = FCOIS_CON_SELL    --OK
                        --Vendor buyback
                    elseif (calledFromExternalAddon and panelId == LF_VENDOR_BUYBACK) or (not calledFromExternalAddon and (panelId == LF_VENDOR_BUYBACK or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and not ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()))) then
                        whereAreWe = FCOIS_CON_BUYBACK    --OK
                        --Vendor repair
                    elseif (calledFromExternalAddon and panelId == LF_VENDOR_REPAIR) or (not calledFromExternalAddon and (panelId == LF_VENDOR_REPAIR or (ctrlVars.STORE:IsHidden() and ctrlVars.BACKPACK_BAG:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and not ctrlVars.REPAIR_LIST:IsHidden()))) then
                        whereAreWe = FCOIS_CON_REPAIR    --OK
                    end
                    --Fence/Launder scene
                elseif (calledFromExternalAddon and (panelId == LF_FENCE_SELL or panelId == LF_FENCE_LAUNDER)) or (not calledFromExternalAddon and (currentSceneName == ctrlVars.FENCE_SCENE_NAME or panelId == LF_FENCE_SELL or panelId == LF_FENCE_LAUNDER)) then
                    --Inside fence sell?
                    if (calledFromExternalAddon and panelId == LF_FENCE_SELL) or (not calledFromExternalAddon and ((FENCE_KEYBOARD ~= nil and FENCE_KEYBOARD.mode ~= nil and FENCE_KEYBOARD.mode == ZO_MODE_STORE_SELL_STOLEN) or panelId == LF_FENCE_SELL)) then
                        whereAreWe = FCOIS_CON_FENCE_SELL    --OK
                        --Inside launder sell?
                    elseif (calledFromExternalAddon and panelId == LF_FENCE_LAUNDER) or (not calledFromExternalAddon and ((FENCE_KEYBOARD ~= nil and FENCE_KEYBOARD.mode ~= nil and FENCE_KEYBOARD.mode == ZO_MODE_STORE_LAUNDER) or panelId == LF_FENCE_LAUNDER)) then
                        whereAreWe = FCOIS_CON_LAUNDER_SELL    --OK
                    end
                    --Inside crafting station refinement
                elseif (calledFromExternalAddon and (panelId == LF_SMITHING_REFINE or panelId == LF_JEWELRY_REFINE)) or (not calledFromExternalAddon and (not ctrlVars.REFINEMENT:IsHidden() or (panelId == LF_SMITHING_REFINE or panelId == LF_JEWELRY_REFINE))) then
                    whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_REFINE, true)
                    --Inside crafting station deconstruction
                elseif (calledFromExternalAddon and (panelId == LF_SMITHING_DECONSTRUCT or panelId == LF_JEWELRY_DECONSTRUCT)) or (not calledFromExternalAddon and (not ctrlVars.DECONSTRUCTION:IsHidden() or (panelId == LF_SMITHING_DECONSTRUCT or panelId == LF_JEWELRY_DECONSTRUCT))) then
                    whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_DECONSTRUCT, true)
                    --Inside crafting station improvement
                elseif (calledFromExternalAddon and (panelId == LF_SMITHING_IMPROVEMENT or panelId == LF_JEWELRY_IMPROVEMENT)) or (not calledFromExternalAddon and (not ctrlVars.IMPROVEMENT:IsHidden() or (panelId == LF_SMITHING_IMPROVEMENT or panelId == LF_JEWELRY_IMPROVEMENT))) then
                    whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_IMPROVEMENT, true)
                    --Are we at the crafting stations research panel's popup list dialog?
                elseif (calledFromExternalAddon and (panelId == LF_SMITHING_RESEARCH_DIALOG or panelId == LF_JEWELRY_RESEARCH_DIALOG)) or (not calledFromExternalAddon and (isResearchListDialogShown() or (panelId == LF_SMITHING_RESEARCH_DIALOG or panelId == LF_JEWELRY_RESEARCH_DIALOG))) then
                    whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_RESEARCH_DIALOG, true)
                    --Are we at the crafting stations research panel?
                elseif (calledFromExternalAddon and (panelId == LF_SMITHING_RESEARCH or panelId == LF_JEWELRY_RESEARCH)) or (not calledFromExternalAddon and (not ctrlVars.RESEARCH:IsHidden() or (panelId == LF_SMITHING_RESEARCH or panelId == LF_JEWELRY_RESEARCH))) then
                    whereAreWe = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(LF_SMITHING_RESEARCH, true)
                    --Inside enchanting station
                elseif (calledFromExternalAddon and (panelId == LF_ENCHANTING_EXTRACTION or panelId == LF_ENCHANTING_CREATION)) or (not calledFromExternalAddon and (not ctrlVars.ENCHANTING_STATION:IsHidden() or (panelId == LF_ENCHANTING_EXTRACTION or panelId == LF_ENCHANTING_CREATION))) then
                    --Enchanting Extraction panel?
                    local enchantingMode = ENCHANTING:GetEnchantingMode()
                    if panelId == LF_ENCHANTING_EXTRACTION or enchantingMode == ENCHANTING_MODE_EXTRACTION then
                        whereAreWe = FCOIS_CON_ENCHANT_EXTRACT    --OK
                        --Enchanting Creation panel?
                    elseif panelId == LF_ENCHANTING_CREATION or enchantingMode == ENCHANTING_MODE_CREATION then
                        whereAreWe = FCOIS_CON_ENCHANT_CREATE    --OK
                    end
                    --Inside guild store selling?
                elseif (calledFromExternalAddon and panelId == LF_GUILDSTORE_SELL) or (not calledFromExternalAddon and (not ctrlVars.GUILD_STORE:IsHidden() or panelId == LF_GUILDSTORE_SELL)) then
                    whereAreWe = FCOIS_CON_GUILD_STORE_SELL    --OK
                    --Are we at the alchemy station?
                elseif (calledFromExternalAddon and panelId == LF_ALCHEMY_CREATION) or (not calledFromExternalAddon and (not ctrlVars.ALCHEMY_STATION:IsHidden() or panelId == LF_ALCHEMY_CREATION)) then
                    whereAreWe = FCOIS_CON_ALCHEMY_DESTROY    --OK
                    --Are we at a furniture vault and trying to withdraw some items by double clicking it?
                elseif (calledFromExternalAddon and panelId == LF_FURNITURE_VAULT_WITHDRAW) or (not calledFromExternalAddon and (not ctrlVars.FURNITURE_VAULT:IsHidden() or panelId == LF_FURNITURE_VAULT_WITHDRAW)) then
                    --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                    whereAreWe = FCOIS_CON_FALLBACK    --OK
                    --Are we at a bank and trying to withdraw some items by double clicking it?
                elseif (calledFromExternalAddon and panelId == LF_BANK_WITHDRAW) or (not calledFromExternalAddon and (not ctrlVars.BANK:IsHidden() or panelId == LF_BANK_WITHDRAW)) then
                    --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                    whereAreWe = FCOIS_CON_FALLBACK  --OK
                elseif (calledFromExternalAddon and panelId == LF_HOUSE_BANK_WITHDRAW) or (not calledFromExternalAddon and (not ctrlVars.HOUSE_BANK:IsHidden() or panelId == LF_HOUSE_BANK_WITHDRAW)) then
                    --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                    whereAreWe = FCOIS_CON_FALLBACK  --OK
                    --Are we at a guild bank and trying to withdraw some items by double clicking it?
                elseif (calledFromExternalAddon and panelId == LF_GUILDBANK_WITHDRAW) or (not calledFromExternalAddon and (not ctrlVars.GUILD_BANK:IsHidden() or panelId == LF_GUILDBANK_WITHDRAW)) then
                    --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                    whereAreWe = FCOIS_CON_FALLBACK  --OK
                    --Are we at a transmutation/retrait station?
                elseif (calledFromExternalAddon and panelId == LF_RETRAIT) or (not calledFromExternalAddon and (isRetraitStationShown() or panelId == LF_RETRAIT)) then
                    --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                    whereAreWe = FCOIS_CON_RETRAIT  --OK
                    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    --Are we at a companion inventory?
                elseif (calledFromExternalAddon and panelId == LF_INVENTORY_COMPANION) or (not calledFromExternalAddon and (isCompanionInventoryShown() or panelId == LF_INVENTORY_COMPANION)) then
                    whereAreWe = FCOIS_CON_COMPANION_DESTROY   --OK  --OK
                    whereAreWe = checkIfItemShouldBeUsedOrEquipped(whereAreWe, bag, slot, panelId, panelIdAtCall, calledFromExternalAddon)  --OK
                    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    --Are we at the inventory/bank/guild bank and trying to use/equip/deposit an item?
                elseif (calledFromExternalAddon and (panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT or panelId == LF_FURNITURE_VAULT_DEPOSIT))
                        or (not calledFromExternalAddon and (not ctrlVars.BACKPACK:IsHidden() or panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT or panelId == LF_FURNITURE_VAULT_DEPOSIT)) then
                    --Check if player or guild bank is active by checking current scene in scene manager
                    if (calledFromExternalAddon and (panelId == LF_INVENTORY or panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT or panelId == LF_FURNITURE_VAULT_DEPOSIT))
                            or (not calledFromExternalAddon and (IsGuildBankOpen() or IsBankOpen() or (currentSceneName ~= nil and (currentSceneName == ctrlVars.bankSceneName or currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.houseBankSceneName or currentSceneName == ctrlVars.furnitureVaultSceneName)))) then
                        --If bank/guild bank/house deposit tab is active
                        if (calledFromExternalAddon and (panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT)) or (not calledFromExternalAddon and ((ctrlVars.BANK:IsHidden() and ctrlVars.GUILD_BANK:IsHidden() and ctrlVars.HOUSE_BANK:IsHidden()) or (panelId == LF_BANK_DEPOSIT or panelId == LF_GUILDBANK_DEPOSIT or panelId == LF_HOUSE_BANK_DEPOSIT))) then
                            --If the item is double clicked + marked deposit it, instead of blocking the deposit
                            --Set whereAreWe to FCOIS_CON_FALLBACK so the anti-settings mapping function returns "false"
                            whereAreWe = FCOIS_CON_FALLBACK   --OK
                            --Abort the checks here as items are always allowed to deposit at the bank/guildbank/house bank deposit tab
                            --but only if you do not use the mouse drag&drop (or context menu destroy)
                            if not isDragAndDrop then return false end   --OK
                        end
                    end
                    --Only do the item checks if the item should not be deposited at a bank/guild bank/house bank
                    whereAreWe = checkIfItemShouldBeUsedOrEquipped(whereAreWe, bag, slot, panelId, panelIdAtCall, calledFromExternalAddon) --OK
                    -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
                    --All others: We are trying to destroy an item
                else
                    whereAreWe = FCOIS_CON_DESTROY  --OK
                end
                ]]
            whereAreWe = whereAreWe or fallbackToDefaultDestroyWhereAreWe ---FCOIS_CON_DESTROY
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
    local updateGFilterWhere
    local inventoryName
    local origComingFrom = comingFrom
    --local ctrlVars2 = FCOIS.ZOControlVars

    local doDebugHere = false --origComingFrom == nil or origComingFrom == LF_SMITHING_RESEARCH_DIALOG --todo: change to true to debug the function

    --Get the current scene's name to be able to distinguish between bank, guildbank, mail etc. when changing to CBE's craftbag panels
    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    --local currentScene, currentSceneName = getCurrentSceneInfo()
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

    ------------------------------------------------------------------------------------------------------------------------
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
    --Use LibFilters to detect the currently shown filterPanelId
    libFilters_GetCurrentFilterType = libFilters_GetCurrentFilterType or libFilters.GetCurrentFilterType --#2025_999
    local currentFilterPanelId = libFilters_GetCurrentFilterType(libFilters)
    --[[
    if currentFilterPanelId ~= comingFrom and GetDisplayName() == "@Baertram" then
        d("[FCOIS]CheckActivePanel - Error. LibFilters current filterPanelID: " .. tos(currentFilterPanelId) .. ", comingFrom: " .. tos(comingFrom))
    end
    ]]
    if doDebugHere then d("[FCOIS]CheckActivePanel - LibFilters current filterPanelID: " .. tos(currentFilterPanelId) .. ", comingFrom: " .. tos(comingFrom)) end
    currentFilterPanelId = currentFilterPanelId or comingFrom

    ------------------------------------------------------------------------------------------------------------------------
    --Check crafting type relevant filterTypes (e.g. deconstruction could be smithing or jewelry, depending on the craft type)
    if not isDeconNPC then
        currentFilterPanelId = getWhereAreWeOrFilterPanelIdByPanelIdRespectingCraftType(currentFilterPanelId, false, false)
        if doDebugHere then d(">crafting filterPanelId: " .. tos(currentFilterPanelId)) end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Update the filterPanelId with a standard value
    if currentFilterPanelId == nil then
        currentFilterPanelId = LF_INVENTORY --Fallback value: Normal player inventory
        if doDebugHere then d("<FALLBACK filterPanelId to LF_INVENTORY: " .. tos(currentFilterPanelId)) end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Special cases for the inventoryName detection
    --ENCHANTING
    if origComingFrom == "ENCHANTING" then
        enchantingStation = enchantingStation or ctrlVars.ENCHANTING_STATION
        --Determine which enchanting mode is used
        local currentEnchantingModeData = enchantingModeToData[ctrlVars.ENCHANTING.enchantingMode]
        if currentEnchantingModeData ~= nil then
            updateGFilterWhere = currentEnchantingModeData.filterPanelId
            comingFrom = updateGFilterWhere
            inventoryName = currentEnchantingModeData.inventoryName
            if doDebugHere then d(">ENCHANTING special filterPanelId: " .. tos(updateGFilterWhere)) end
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Normal cases (take already prefileld inventoryName, if given)
    inventoryName = inventoryName or libFiltersPanelIdToInventory[currentFilterPanelId]
    if doDebugHere then d(">>InventoryName: " .. tos(inventoryName)) end

    --Special cases updating FCOIS.gFilterWhere
    updateGFilterWhere = updateGFilterWhere or currentFilterPanelId
    if doDebugHere then d(">>updateGFilterWhere: " .. tos(updateGFilterWhere)) end

    ------------------------------------------------------------------------------------------------------------------------
    --Enchanting extraction
    if origComingFrom == LF_ENCHANTING_EXTRACTION then
        updateGFilterWhere = nil
        --At universal deconstruction we do not overwrite the current filterPanelId
        if not isDeconNPC then
            updateGFilterWhere = LF_ENCHANTING_EXTRACTION
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    if updateGFilterWhere ~= nil then
        if doDebugHere then d(">>updateGFilterWhere AT UPDATE: " .. tos(updateGFilterWhere)) end
        --Standard cases of updating FCOIS.gFilterWhere
        FCOIS.gFilterWhere = getFilterWhereBySettings(updateGFilterWhere)
    end
    ------------------------------------------------------------------------------------------------------------------------

    --Set the return variable for the currently active filter panel
    local panelType = FCOIS.gFilterWhere

    --Overwrite the FCOIS panelID with the one from the function parameter?
    --(e.g. at the CraftBag Extended mail panel the filterPanel will be LF_MAIL. This will be moved to the "parent panel". And the filterPanel will be overwritten with LF_CRAFTBAG)
    if overwriteFilterWhere ~= nil then
        FCOIS.gFilterWhere = overwriteFilterWhere
        if overwriteFilterWhere == LF_CRAFTBAG then
            --CraftBagExtended is active?
            checkIfCBEorAGSActive = checkIfCBEorAGSActive or FCOIS.CheckIfCBEorAGSActive
            if checkIfCBEorAGSActive(FCOIS.gFilterWhereParent, true) then
                inventoryName = ctrlVars.CRAFTBAG
            end
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
    --value = value or false --#2025_999
    if iconNr == nil or panelId == nil then return false end
    --Check depending panelIds
    --e.g. inventory: Must change the bank, guild bank and house bank withdraw/deposit panels as well
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
                updateFCOISFilterButtonsAtInventory(FCOIS_CON_FILTER_BUTTONS_ALL)
            end
--d(">FCOIS.gFilterWhere1.2: " .. tos(FCOIS.gFilterWhere))

            --Update the 4 inventory button's color
            updateFCOISFilterButtonColorsAndTextures(FCOIS_CON_FILTER_BUTTONS_ALL, nil, FCOIS_CON_FILTER_BUTTON_STATUS_ALL, panelIdToShow)
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