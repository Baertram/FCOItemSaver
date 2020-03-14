--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local libFilters = FCOIS.libFilters

-- =====================================================================================================================
-- Refresh inventories etc. functions
-- =====================================================================================================================
--Update the count of filtered/shown items before the sortHeader "name" text
local function updateFilteredItemCountCheck(updateFilteredItemCount)
    if updateFilteredItemCount == true then
--d("[FCOIS]updateFilteredItemCountCheck - filterPaneldId: " ..tostring(FCOIS.gFilterWhere))
        FCOIS.updateFilteredItemCountThrottled(FCOIS.gFilterWhere, 50)
    end
end

--The function to update the repair list
local function UpdateRepairList()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Refresh]", "UpdateRepairList", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the repair list
    FCOIS.RefreshRepairList()
end

--The function to update the quickslots inventory
local function UpdateQuickSlots()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Refresh]", "UpdateQuickSlots", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the quick slots inventory
    FCOIS.RefreshQuickSlots()
end

--The function to update the transmutation inventory
local function UpdateTransmutationList()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Refresh]", "UpdateTransmutationList", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the quick slots inventory
    FCOIS.RefreshTransmutation()
end

--Refresh the scroll lists
local function UpdateInventories()
    --Check if we are at a crafting station
    local craftInteractiontype = GetCraftingInteractionType()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateInventories]", "CraftingInteractionType: " .. tostring(craftInteractiontype), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Are we not inside a crafting station? Else abort as this function will only update the player inventory
    if craftInteractiontype ~= CRAFTING_TYPE_INVALID then return end

    --Update the current shown inventory
    if (libFilters ~= nil and FCOIS.gFilterWhere ~= nil and FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] ~= nil) then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateInventories]", "Filter Id: " ..tostring(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]) .. ", Filter panel Id: " .. tostring(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Get the current set settings for the filter panels
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(FCOIS.gFilterWhere, false)
        --Is the filter for this panel enabled in the FCOIS.settingsVars.settings?
        if FCOIS.settingsVars.settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"] == true then
            --Is the filter we have added the icon for currently enabled(registered)?
            --local isFilterEnabled = FCOIS.getSettingsIsFilterOn(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere], FCOIS.gFilterWhere)
            --if isFilterEnabled == true or isFilterEnabled == -99 then
            --if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateInventories]", "UpdaterName: " .. libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere], true, FCOIS_DEBUG_DEPTH_NORMAL) end
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

local function UpdateCraftingInventory(filterPanelOverride)
    --Check if we are at a crafting station
    local locCraftType = GetCraftingInteractionType()
    local updateFilteredItemCount = false
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory]","CraftingInteractionType: " .. tostring(locCraftType), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Abort if we are not at a crafting station
    if locCraftType == CRAFTING_TYPE_INVALID then return end

    --Check the current filter panel ID and the lastVars filterPanelId. If one is missing, override them with filterPanelOverride
    local gFiltewrWhereBefore, gLastFilterIdFilterWhere
    if filterPanelOverride ~= nil then
        gFiltewrWhereBefore = FCOIS.gFilterWhere
        gLastFilterIdFilterWhere = FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]
        FCOIS.gFilterWhere = filterPanelOverride
        FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] = filterPanelOverride
    end
    --Update the current shown inventory
    if (libFilters ~= nil and FCOIS.gFilterWhere ~= nil and FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] ~= nil) then
        --Get the current set settings for the filter panels
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(FCOIS.gFilterWhere, false)
        --Is the filter for this panel enabled in the FCOIS.settingsVars.settings?
        if FCOIS.settingsVars.settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"] == true then
            --Is the filter we have added the icon for currently enabled(registered)?
            --local isFilterEnabled = FCOIS.getSettingsIsFilterOn(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere], FCOIS.gFilterWhere)
            --if isFilterEnabled == true or isFilterEnabled == -99 then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory]", "Filter Id: " ..tostring(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]) .. ", Filter panel Id: " .. tostring(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --libFilterVars.inventoryUpdaters[libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere]]()
            libFilters:RequestUpdate( FCOIS.gFilterWhere )
            --end
        end
    end

    --Alchemy?
    if (locCraftType == CRAFTING_TYPE_ALCHEMY) then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory]","Alchemy refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Only refresh the scroll list
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.ALCHEMY_STATION)
        FCOIS.preventerVars.isInventoryListUpdating = false
        --updateFilteredItemCount = true -- TODO: Enable once alchemy filters are added!

        --Enchanting?
    elseif (locCraftType == CRAFTING_TYPE_ENCHANTING) then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory]","Enchanting refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Only refresh the scroll list
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.ENCHANTING_STATION)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true

    else
        --Other crafting stations

        --Refinement
        if (FCOIS.gFilterWhere == LF_SMITHING_REFINE or FCOIS.gFilterWhere == LF_JEWELRY_REFINE or not FCOIS.ZOControlVars.REFINEMENT:IsHidden()) then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory]","(Jewelry) Refinement refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Are we at a refinement panel?
            --Only refresh the scroll list
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.REFINEMENT)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true

            --Deconstruction
        elseif (FCOIS.gFilterWhere == LF_SMITHING_DECONSTRUCT or FCOIS.gFilterWhere == LF_JEWELRY_DECONSTRUCT) then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory]","(Jewelry) Deconstruction refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Are we at a deconstruction panel?
            --Only refresh the scroll list
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.DECONSTRUCTION)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true

            --Improvement
        elseif     (FCOIS.gFilterWhere == LF_SMITHING_IMPROVEMENT or FCOIS.gFilterWhere == LF_JEWELRY_IMPROVEMENT) then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[UpdateCraftingInventory]","(Jewelry) Improvement refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Are we at an improvement panel?
            --Only refresh the scroll list
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.IMPROVEMENT)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end

    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
    --Set the filterPanelIds back to normal, before they were overwritten
    if filterPanelOverride ~= nil then
        FCOIS.gFilterWhere = gFiltewrWhereBefore
        FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] = gLastFilterIdFilterWhere
    end
end

--Check if other addons with an UI are enabled and shown and update their rows to show/hide FCOIS marker icons now
local function UpdateOtherAddonUIs()
   --Inventory Insight from Ashes
    FCOIS.checkIfOtherAddonIIfAIsActive()
    if IIfA ~= nil and IIFA_GUI ~= nil and not IIFA_GUI:IsHidden() and FCOIS.otherAddons.IIFAActive and IIfA.SetDataLinesData ~= nil then
--d(">UpdateOtherAddonUIs-IIfA found, trying to update now!")
        --IIfA:RefreshInventoryScroll() -- This will scroll to the top :-( We need to find a way to scroll back to the current scrollList index
        IIfA:SetDataLinesData()
    end

    --Check if AdvancedFilters is enabled and if the filter plugin FCO duplicate items is enabeld:
    --Update the dropdown box chosen filter
    if AdvancedFilters ~= nil and AdvancedFilters.util ~= nil and FCOIS.otherAddons and FCOIS.otherAddons.AFFCODuplicateItemFilter == true then
        local AF = AdvancedFilters
        --Is the filterplugin
        if AF.externalDropdownFilterPlugins and AF.externalDropdownFilterPlugins.AF_FCODuplicateItemsFilters then
            local isFiltering = AF.externalDropdownFilterPlugins.AF_FCODuplicateItemsFilters.isFiltering
--d(">UpdateOtherAddonUIs-AF_FCODuplicateItemsFilters found, isFiltering: " ..tostring(isFiltering))
            if isFiltering then
                if AF.util.ReApplyDropdownFilter then
                    --Reselect the last selected dropdown filter to apply the filter and update the inventory items again
                    AF.util.ReApplyDropdownFilter()
                end
            end
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
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FilterBasics]","onlyPlayer: " .. tostring(onlyPlayer), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]FilterBasics, onlyPlayer: " ..tostring(onlyPlayer))

    --Only update the lists if not currently already updating
    if (FCOIS.preventerVars.gFilteringBasics == false) then
        FCOIS.preventerVars.gFilteringBasics = true
        if (not FCOIS.ZOControlVars.QUICKSLOT_LIST:IsHidden() and onlyPlayer == false) then
            --UpdateInventories() -- NO FILTERS YET! So not needed to call libFilters:RequestUpdate(LF_QUICKSLOT)!
            UpdateQuickSlots()
            --UpdateOtherAddonUIs()
        elseif (not FCOIS.ZOControlVars.REPAIR_LIST:IsHidden() and onlyPlayer == false) then
            --UpdateInventories() -- NO FILTERS YET! So not needed to call libFilters:RequestUpdate(LF_VENDOR_REPAIR)!
            UpdateRepairList()
            --UpdateOtherAddonUIs()
        elseif (not FCOIS.ZOControlVars.RETRAIT_LIST:IsHidden() and onlyPlayer == false) then
            UpdateInventories()
            UpdateTransmutationList()
            UpdateOtherAddonUIs()
        elseif (onlyPlayer == true) then
            UpdateInventories()
            --Try to update other addon's UIs
            UpdateOtherAddonUIs()
        else
            --Try to update the normal and then the crafting inventories
            UpdateInventories()
            UpdateCraftingInventory()
            --Try to update other addon's UIs
            UpdateOtherAddonUIs()
        end
        FCOIS.preventerVars.gFilteringBasics = false
    end
end

--Refresh the backpack list
function FCOIS.RefreshBackpack()
    local updateFilteredItemCount = false
    --Added with patch to API 100015 -> New craft bag
    if INVENTORY_CRAFT_BAG and not FCOIS.ZOControlVars.CRAFTBAG:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBackpack]","Craftbag refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        PLAYER_INVENTORY:UpdateList(INVENTORY_CRAFT_BAG)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true
    else
        --Refresh the normal inventory
        if not FCOIS.ZOControlVars.BACKPACK:IsHidden() then
            if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBackpack]","Backpack refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.BACKPACK)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end

--Refresh the bank list
function FCOIS.RefreshBank()
    local updateFilteredItemCount = false
    if not FCOIS.ZOControlVars.BANK:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBank]","Bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.BANK)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true
    elseif not FCOIS.ZOControlVars.HOUSE_BANK:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshBank]","House Bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.HOUSE_BANK)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end

--Refresh the guild bank list
function FCOIS.RefreshGuildBank()
    local updateFilteredItemCount = false
    if not FCOIS.ZOControlVars.GUILD_BANK:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshGuildBank]","Guild bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.GUILD_BANK)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end

--Refresh the repair list
function FCOIS.RefreshRepairList()
    local updateFilteredItemCount = false
    if not FCOIS.ZOControlVars.REPAIR_LIST:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshRepairList]","Repair list refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.REPAIR_LIST)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end

--Refresh the quickslot list
function FCOIS.RefreshQuickSlots()
    local updateFilteredItemCount = false
    if not FCOIS.ZOControlVars.QUICKSLOT_LIST:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshQuickSlots]","Quickslot refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.QUICKSLOT_LIST)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end

function FCOIS.RefreshTransmutation()
    local updateFilteredItemCount = false
    if not FCOIS.ZOControlVars.RETRAIT_LIST:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[RefreshTransmutation]","Transmutation panel refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.RETRAIT_LIST)
        FCOIS.preventerVars.isInventoryListUpdating = false
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end

--Refresh the list dialog 1 scroll list (ZO_ListDialog1List)
function FCOIS.RefreshListDialog(rebuildItems, filterPanelId)
    rebuildItems = rebuildItems or false
--d("[FCOIS]RefreshListDialog - rebuildItems: " .. tostring(rebuildItems) .. ", filterPanelId: " .. tostring(filterPanelId))
    local refreshListDialogNow = false
    if not FCOIS.ZOControlVars.LIST_DIALOG:IsHidden() then
        if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.RefreshListDialog]","List Dialog refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
        FCOIS.preventerVars.isInventoryListUpdating = true
        --Rebuild the whole ZO_ListDialog1List ?
        if rebuildItems and filterPanelId ~= nil then
            --Is the function to update a dialog from LibFilters given?
            if FCOIS.libFilters and FCOIS.libFilters.RequestUpdate then
                FCOIS.libFilters:RequestUpdate(filterPanelId)
            else
                refreshListDialogNow = true
            end
        else
            refreshListDialogNow = true
        end
        if refreshListDialogNow then
            --Refresh the visible contents if the list dialog
            ZO_ScrollList_RefreshVisible(FCOIS.ZOControlVars.LIST_DIALOG)
        end
        FCOIS.preventerVars.isInventoryListUpdating = false
    end
end

--Refresh the crafting tables inventopry list
function FCOIS.RefreshCrafting(filterPanelOverride)
    UpdateCraftingInventory(filterPanelOverride)
end
