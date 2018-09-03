--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
local libFilters = FCOIS.libFilters

-- =====================================================================================================================
-- Refresh inventories etc. functions
-- =====================================================================================================================
--The function to update the repair list
local function UpdateRepairList()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateRepairList]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the repair list
    FCOIS.RefreshRepairList()
end

--The function to update the quickslots inventory
local function UpdateQuickSlots()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateQuickSlots]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the quick slots inventory
    FCOIS.RefreshQuickSlots()
end

--The function to update the transmutation inventory
local function UpdateTransmutationList()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateTransmutationList]", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the quick slots inventory
    FCOIS.RefreshTransmutation()
end

--Refresh the scroll lists
local function UpdateInventories()
    --Check if we are at a crafting station
    local craftInteractiontype = GetCraftingInteractionType()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateInventories] CraftingInteractionType: " .. tostring(craftInteractiontype), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Are we not inside a crafting station? Else abort as this function will only update the player inventory
    if craftInteractiontype ~= CRAFTING_TYPE_INVALID then return end

    --Update the current shown inventory
    if (libFilters ~= nil and FCOIS.gFilterWhere ~= nil and FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] ~= nil) then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "Filter Id: " ..tostring(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]) .. ", Filter panel Id: " .. tostring(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Get the current set settings for the filter panels
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(FCOIS.gFilterWhere, false)
        --Is the filter for this panel enabled in the FCOIS.settingsVars.settings?
        if FCOIS.settingsVars.settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"] == true then
            --Is the filter we have added the icon for currently enabled(registered)?
            --local isFilterEnabled = FCOIS.getSettingsIsFilterOn(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere], FCOIS.gFilterWhere)
            --if isFilterEnabled == true or isFilterEnabled == -99 then
            --if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "UpdaterName: " .. libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere], true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --libFilterVars.inventoryUpdaters[libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere]]()
            libFilters:RequestUpdate( FCOIS.gFilterWhere )
            --end
        end
    end

    --Update the scroll list controls for the player inventories
    FCOIS.RefreshBackpack()
    FCOIS.RefreshBank()
    FCOIS.RefreshGuildBank()
    FCOIS.RefreshListDialog()
end

local function UpdateCraftingInventory()
    --Check if we are at a crafting station
    local locCraftType = GetCraftingInteractionType()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory] CraftingInteractionType: " .. tostring(locCraftType), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Abort if we are not at a crafting station
    if locCraftType == CRAFTING_TYPE_INVALID then return end

    --Update the current shown inventory
    if (libFilters ~= nil and FCOIS.gFilterWhere ~= nil and FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] ~= nil) then
        --Get the current set settings for the filter panels
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(FCOIS.gFilterWhere, false)
        --Is the filter for this panel enabled in the FCOIS.settingsVars.settings?
        if FCOIS.settingsVars.settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"] == true then
            --Is the filter we have added the icon for currently enabled(registered)?
            --local isFilterEnabled = FCOIS.getSettingsIsFilterOn(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere], FCOIS.gFilterWhere)
            --if isFilterEnabled == true or isFilterEnabled == -99 then
            --if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "Filter Id: " ..tostring(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]) .. ", Filter panel Id: " .. tostring(FCOIS.gFilterWhere) .. ", UpdaterName: " .. libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere], true, FCOIS_DEBUG_DEPTH_NORMAL) end
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "Filter Id: " ..tostring(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]) .. ", Filter panel Id: " .. tostring(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --libFilterVars.inventoryUpdaters[libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere]]()
            libFilters:RequestUpdate( FCOIS.gFilterWhere )
            --end
        end
    end

    --Alchemy?
    if (locCraftType == CRAFTING_TYPE_ALCHEMY) then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory] Alchemy refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Only refresh the scroll list
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.ALCHEMY_STATION)
        FCOIS.updateFilteredItemCount()

    --Enchanting?
    elseif (locCraftType == CRAFTING_TYPE_ENCHANTING) then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory] Enchanting refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Only refresh the scroll list
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.ENCHANTING_STATION)
        FCOIS.updateFilteredItemCount()

    else
    --Other crafting stations

        --Refinement
        if (FCOIS.gFilterWhere == LF_SMITHING_REFINE or FCOIS.gFilterWhere == LF_JEWELRY_REFINE or not FCOIS.ZOControlVars.REFINEMENT:IsHidden()) then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory] (Jewelry) Refinement refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Are we at a refinement panel?
            --Only refresh the scroll list
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.REFINEMENT)
            FCOIS.updateFilteredItemCount()

        --Deconstruction
        elseif (FCOIS.gFilterWhere == LF_SMITHING_DECONSTRUCT or FCOIS.gFilterWhere == LF_JEWELRY_DECONSTRUCT) then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory] (Jewelry) Deconstruction refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Are we at a deconstruction panel?
            --Only refresh the scroll list
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.DECONSTRUCTION)
            FCOIS.updateFilteredItemCount()

        --Improvement
        elseif     (FCOIS.gFilterWhere == LF_SMITHING_IMPROVEMENT or FCOIS.gFilterWhere == LF_JEWELRY_IMPROVEMENT) then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory] (Jewelry) Improvement refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Are we at an improvement panel?
            --Only refresh the scroll list
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.IMPROVEMENT)
            FCOIS.updateFilteredItemCount()
        end
    end
end

------------------------------------------------------------------------------------------------------------------------

--The function to update the inventories and lists after an item was un/marked
function FCOIS.FilterBasics(onlyPlayer)
    --Check if we are in the player inventory
    if not FCOIS.ZOControlVars.BACKPACK:IsHidden() then
        --we are in the player inventory (or in the banks at the deposit inventories, or at mail sending, or trading)
        onlyPlayer = true
    end

    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.FilterBasics] onlyPlayer: " .. tostring(onlyPlayer), true, FCOIS_DEBUG_DEPTH_NORMAL) end

    --Only update the lists if not currently already updating
    if (FCOIS.preventerVars.gFilteringBasics == false) then
        FCOIS.preventerVars.gFilteringBasics = true
        if (not FCOIS.ZOControlVars.QUICKSLOT_LIST:IsHidden() and onlyPlayer == false) then
            --UpdateInventories() -- NO FILTERS YET! So not needed to call libFilters:RequestUpdate(LF_QUICKSLOT)!
            UpdateQuickSlots()
        elseif (not FCOIS.ZOControlVars.REPAIR_LIST:IsHidden() and onlyPlayer == false) then
            --UpdateInventories() -- NO FILTERS YET! So not needed to call libFilters:RequestUpdate(LF_VENDOR_REPAIR)!
            UpdateRepairList()
        elseif (not FCOIS.ZOControlVars.RETRAIT_LIST:IsHidden() and onlyPlayer == false) then
            UpdateInventories()
            UpdateTransmutationList()
        elseif (onlyPlayer == true) then
            UpdateInventories()
        else
            --Try to update the normal and then the crafting inventories
            UpdateInventories()
            UpdateCraftingInventory()
        end
        FCOIS.preventerVars.gFilteringBasics = false
    end
end

--Refresh the backpack list
function FCOIS.RefreshBackpack()
    --Added with patch to API 100015 -> New craft bag
    if INVENTORY_CRAFT_BAG and not FCOIS.ZOControlVars.CRAFTBAG:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBackpack] Craftbag refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        PLAYER_INVENTORY:UpdateList(INVENTORY_CRAFT_BAG)
        FCOIS.updateFilteredItemCount()
    else
        --Refresh the normal inventory
        if not FCOIS.ZOControlVars.BACKPACK:IsHidden() then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBackpack] Backpack refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.BACKPACK)
            FCOIS.updateFilteredItemCount()
        end
    end
end

--Refresh the bank list
function FCOIS.RefreshBank()
    if not FCOIS.ZOControlVars.BANK:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBank] Bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.BANK)
        FCOIS.updateFilteredItemCount()
    elseif not FCOIS.ZOControlVars.HOUSE_BANK:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBank] House Bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.HOUSE_BANK)
        FCOIS.updateFilteredItemCount()
    end
end

--Refresh the guild bank list
function FCOIS.RefreshGuildBank()
    if not FCOIS.ZOControlVars.GUILD_BANK:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshGuildBank] Guild bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.GUILD_BANK)
        FCOIS.updateFilteredItemCount()
    end
end

--Refresh the repair list
function FCOIS.RefreshRepairList()
    if not FCOIS.ZOControlVars.REPAIR_LIST:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshRepairList] Repair list refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.REPAIR_LIST)
        FCOIS.updateFilteredItemCount()
    end
end

--Refresh the quickslot list
function FCOIS.RefreshQuickSlots()
    if not FCOIS.ZOControlVars.QUICKSLOT_LIST:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshQuickSlots] Quickslot refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.QUICKSLOT_LIST)
        FCOIS.updateFilteredItemCount()
    end
end

function FCOIS.RefreshTransmutation()
    if not FCOIS.ZOControlVars.RETRAIT_LIST:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshTransmutation] Transmutation panel refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.RETRAIT_LIST)
        FCOIS.updateFilteredItemCount()
    end
end

--Refresh the list dialog 1 scroll list
function FCOIS.RefreshListDialog()
    if not FCOIS.ZOControlVars.LIST_DIALOG:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.RefreshListDialog] List Dialog refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.LIST_DIALOG)
    end
end