--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local tos = tostring

local debugMessage = FCOIS.debugMessage

local ctrlVars = FCOIS.ZOControlVars
local backpackCtrl = ctrlVars.BACKPACK

local libFilters = FCOIS.libFilters

local getFilterWhereBySettings = FCOIS.GetFilterWhereBySettings
local isCompanionInventoryShown = FCOIS.IsCompanionInventoryShown

-- =====================================================================================================================
-- Refresh inventories etc. functions
-- =====================================================================================================================
--Update the count of filtered/shown items before the sortHeader "name" text
local function updateFilteredItemCountCheck(updateFilteredItemCount)
    if updateFilteredItemCount == true then
--d("[FCOIS]updateFilteredItemCountCheck - filterPaneldId: " ..tos(FCOIS.gFilterWhere))
        FCOIS.UpdateFilteredItemCountThrottled(FCOIS.gFilterWhere, 50)
    end
end

local function updateCraftingInventory(filterPanelOverride, isUniversalDeconNPC)
    isUniversalDeconNPC = isUniversalDeconNPC or false
    --Check if we are at a crafting station
    local filterType = FCOIS.gFilterWhere
    local locCraftType = GetCraftingInteractionType()
    local updateFilteredItemCount = false
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[UpdateCraftingInventory]","CraftingInteractionType: " .. tos(locCraftType), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]]updateCraftingInventory - craftType: " ..tos(locCraftType) .. ", filterPanelOverride: " ..tos(filterPanelOverride) .. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC))
    --Abort if we are not at a crafting station
    if not isUniversalDeconNPC and locCraftType == CRAFTING_TYPE_INVALID then return end

    local libFiltersUpdateWasCalled = false --#282

    --Check the current filter panel ID and the lastVars filterPanelId. If one is missing, override them with filterPanelOverride
    local gFilterWhereBefore, gLastFilterIdFilterWhere
    if filterPanelOverride ~= nil then
        gFilterWhereBefore       = FCOIS.gFilterWhere
        gLastFilterIdFilterWhere = FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]
        FCOIS.gFilterWhere = filterPanelOverride
        FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] = filterPanelOverride
    end
    filterType = FCOIS.gFilterWhere
    --Update the current shown inventory
    if libFilters ~= nil and filterType ~= nil and FCOIS.lastVars.gLastFilterId[filterType] ~= nil then
        --Get the current set settings for the filter panels
        FCOIS.gFilterWhere = getFilterWhereBySettings(filterType, false)
        filterType = FCOIS.gFilterWhere

--d(">FCOIS.gFilterWhere: " ..tos(filterType))
        --Is the filter for this panel enabled in the settings?
        if settings.atPanelEnabled[filterType]["filters"] == true then
            --Is the filter we have added the icon for currently enabled(registered)?
            --local isFilterEnabled = FCOIS.getSettingsIsFilterOn(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere], FCOIS.gFilterWhere)
            --if isFilterEnabled == FCOIS_CON_FILTER_BUTTON_STATE_GREEN or isFilterEnabled == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
            if settings.debug then debugMessage( "[UpdateCraftingInventory]", "Filter Id: " ..tos(FCOIS.lastVars.gLastFilterId[filterType]) .. ", Filter panel Id: " .. tos(filterType), true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --libFilterVars.inventoryUpdaters[libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere]]()
            libFiltersUpdateWasCalled = true --#282
            libFilters:RequestUpdate(filterType)
            --end
        end
    end


    if not libFiltersUpdateWasCalled then --#282
        --Alchemy?
        if not isUniversalDeconNPC and locCraftType == CRAFTING_TYPE_ALCHEMY then
            --d(">alchemy refresh")
            if settings.debug then debugMessage( "[UpdateCraftingInventory]","Alchemy refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Only refresh the scroll list
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.ALCHEMY_STATION)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true -- TODO FEATURE: LF_ALCHEMY_CREATION Enable once alchemy filters are added! #290

            --Enchanting?
        elseif (not isUniversalDeconNPC and locCraftType == CRAFTING_TYPE_ENCHANTING) or (isUniversalDeconNPC and filterType == LF_ENCHANTING_EXTRACTION) then
            --d(">enchanting refresh")
            if settings.debug then debugMessage( "[UpdateCraftingInventory]","Enchanting refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --Only refresh the scroll list
            FCOIS.preventerVars.isInventoryListUpdating = true
            local invToUpdate
            if not isUniversalDeconNPC then
                invToUpdate = ctrlVars.ENCHANTING_STATION
            else
                invToUpdate = ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK
            end
            ZO_ScrollList_RefreshVisible(invToUpdate)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true

        else
            --Other crafting stations

            --Refinement
            if filterType == LF_SMITHING_REFINE or filterType == LF_JEWELRY_REFINE or not ctrlVars.REFINEMENT:IsHidden() then
                --d(">refinement refresh")
                if settings.debug then debugMessage( "[UpdateCraftingInventory]","(Jewelry) Refinement refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
                --Are we at a refinement panel?
                --Only refresh the scroll list
                FCOIS.preventerVars.isInventoryListUpdating = true
                ZO_ScrollList_RefreshVisible(ctrlVars.REFINEMENT)
                FCOIS.preventerVars.isInventoryListUpdating = false
                updateFilteredItemCount = true

                --Deconstruction
            elseif filterType == LF_SMITHING_DECONSTRUCT or filterType == LF_JEWELRY_DECONSTRUCT then
                --d(">deconstruction refresh")
                if settings.debug then debugMessage( "[UpdateCraftingInventory]","(Jewelry) Deconstruction refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
                --Are we at a deconstruction panel?
                --Only refresh the scroll list
                FCOIS.preventerVars.isInventoryListUpdating = true
                local invToUpdate
                if not isUniversalDeconNPC then
                    invToUpdate = ctrlVars.DECONSTRUCTION
                else
                    invToUpdate = ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK
                end
                ZO_ScrollList_RefreshVisible(invToUpdate)
                FCOIS.preventerVars.isInventoryListUpdating = false
                updateFilteredItemCount = true

                --Improvement
            elseif filterType == LF_SMITHING_IMPROVEMENT or filterType == LF_JEWELRY_IMPROVEMENT then
                --d(">improvement refresh")
                if settings.debug then debugMessage( "[UpdateCraftingInventory]","(Jewelry) Improvement refresh", true, FCOIS_DEBUG_DEPTH_NORMAL) end
                --Are we at an improvement panel?
                --Only refresh the scroll list
                FCOIS.preventerVars.isInventoryListUpdating = true
                ZO_ScrollList_RefreshVisible(ctrlVars.IMPROVEMENT)
                FCOIS.preventerVars.isInventoryListUpdating = false
                updateFilteredItemCount = true
            end

        end
    else
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
    --Set the filterPanelIds back to normal, before they were overwritten
    if filterPanelOverride ~= nil then
        FCOIS.gFilterWhere = gFilterWhereBefore
        FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] = gLastFilterIdFilterWhere
    end
end
FCOIS.UpdateCraftingInventory = updateCraftingInventory

--Refresh the backpack list
function FCOIS.RefreshBackpack(liFiltersUpdateWasCalled)
--d("[FCOIS]RefreshBackpack")
    local updateFilteredItemCount = false

    if not liFiltersUpdateWasCalled then --#282
        --Added with patch to API 100015 -> New craft bag
        if INVENTORY_CRAFT_BAG and not ctrlVars.CRAFTBAG:IsHidden() then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshBackpack]","Craftbag refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ctrlVars.playerInventory:UpdateList(INVENTORY_CRAFT_BAG)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        else
            --d(">normal inv")
            --Refresh the normal inventory
            if not backpackCtrl:IsHidden() then
                --d(">>refreshing")
                if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshBackpack]","Backpack refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
                FCOIS.preventerVars.isInventoryListUpdating = true
                ZO_ScrollList_RefreshVisible(backpackCtrl)
                FCOIS.preventerVars.isInventoryListUpdating = false
                updateFilteredItemCount = true
            end
        end
    else
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end
local refreshBackpack = FCOIS.RefreshBackpack

--Refresh the companion inventory
function FCOIS.RefreshCompanionInventory(liFiltersUpdateWasCalled)
    local updateFilteredItemCount = false

    if not liFiltersUpdateWasCalled then --#282
        if isCompanionInventoryShown() then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshCompanionInventory]","Companion inv. refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.COMPANION_INV_LIST)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end
    --else
        --updateFilteredItemCount = true
    end
    --updateFilteredItemCountCheck(updateFilteredItemCount)
end
local refreshCompanionInventory = FCOIS.RefreshCompanionInventory

--Refresh the bank list
function FCOIS.RefreshBank(liFiltersUpdateWasCalled)
    local updateFilteredItemCount = false

    if not liFiltersUpdateWasCalled then --#282
        if not ctrlVars.BANK:IsHidden() then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshBank]","Bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.BANK)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        elseif not ctrlVars.HOUSE_BANK:IsHidden() then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshBank]","House Bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.HOUSE_BANK)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end
    else
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end
local refreshBank = FCOIS.RefreshBank


--Refresh the guild bank list
function FCOIS.RefreshGuildBank(liFiltersUpdateWasCalled)
--d("[FCOIS]RefreshGuildBank")
    local updateFilteredItemCount = false

    if not liFiltersUpdateWasCalled then --#282
        if not ctrlVars.GUILD_BANK:IsHidden() then
            --d(">Guild bank refresh")
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshGuildBank]","Guild bank refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.GUILD_BANK)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end
    else
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end
local refreshGuildBank = FCOIS.RefreshGuildBank

--Refresh the repair list
function FCOIS.RefreshRepairList(liFiltersUpdateWasCalled)
    local updateFilteredItemCount = false
    
    if not liFiltersUpdateWasCalled then --#282
        if not ctrlVars.REPAIR_LIST:IsHidden() then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshRepairList]","Repair list refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.REPAIR_LIST)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end
    else
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end
local refreshRepairList = FCOIS.RefreshRepairList


--Refresh the quickslot list
function FCOIS.RefreshQuickSlots(liFiltersUpdateWasCalled)
    local updateFilteredItemCount = false
    
    if not liFiltersUpdateWasCalled then --#282
        if not ctrlVars.QUICKSLOT_LIST:IsHidden() then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshQuickSlots]","Quickslot refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.QUICKSLOT_LIST)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end
    else
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end
local refreshQuickSlots = FCOIS.RefreshQuickSlots

function FCOIS.RefreshTransmutation(liFiltersUpdateWasCalled)
    local updateFilteredItemCount = false
    
    if not liFiltersUpdateWasCalled then --#282
        if not ctrlVars.RETRAIT_LIST:IsHidden() then
            if FCOIS.settingsVars.settings.debug then debugMessage( "[RefreshTransmutation]","Transmutation panel refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
            FCOIS.preventerVars.isInventoryListUpdating = true
            ZO_ScrollList_RefreshVisible(ctrlVars.RETRAIT_LIST)
            FCOIS.preventerVars.isInventoryListUpdating = false
            updateFilteredItemCount = true
        end
    else
        updateFilteredItemCount = true
    end
    updateFilteredItemCountCheck(updateFilteredItemCount)
end
local refreshTransmutation = FCOIS.RefreshTransmutation

--Refresh the list dialog 1 scroll list (ZO_ListDialog1List)
function FCOIS.RefreshListDialog(rebuildItems, filterPanelId)
    rebuildItems = rebuildItems or false
--d("[FCOIS]RefreshListDialog - rebuildItems: " .. tos(rebuildItems) .. ", filterPanelId: " .. tos(filterPanelId))
    local refreshListDialogNow = false
    if not ctrlVars.LIST_DIALOG:IsHidden() then
        if FCOIS.settingsVars.settings.debug then debugMessage( "[FCOIS.RefreshListDialog]","List Dialog refresh", true, FCOIS_DEBUG_DEPTH_DETAILED) end
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
            ZO_ScrollList_RefreshVisible(ctrlVars.LIST_DIALOG)
        end
        FCOIS.preventerVars.isInventoryListUpdating = false
    end
end
local refreshListDialog = FCOIS.RefreshListDialog

--Refresh the crafting tables inventopry list
function FCOIS.RefreshCrafting(filterPanelOverride)
    updateCraftingInventory(filterPanelOverride, false)
end
--local refreshCrafting = FCOIS.RefreshCrafting

--Update the scroll list controls for the player inventories
function FCOIS.RefreshBasics(liFiltersUpdateWasCalled)
    refreshBackpack(liFiltersUpdateWasCalled)
    refreshCompanionInventory(liFiltersUpdateWasCalled)
    refreshBank(liFiltersUpdateWasCalled)
    refreshGuildBank(liFiltersUpdateWasCalled)
end
local refreshBasics = FCOIS.RefreshBasics

--The function to update the repair list
local function updateRepairList()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Refresh]", "UpdateRepairList", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the repair list
    refreshRepairList()
end

--The function to update the quickslots inventory
local function updateQuickSlots()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Refresh]", "UpdateQuickSlots", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the quick slots inventory
    refreshQuickSlots()
end

--The function to update the transmutation inventory
local function updateTransmutationList()
    if FCOIS.settingsVars.settings.debug then debugMessage( "[Refresh]", "UpdateTransmutationList", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Update the scroll list controls for the quick slots inventory
    refreshTransmutation()
end

--Refresh the scroll lists
local function updateInventories()
    --Check if we are at a crafting station
    local craftInteractiontype = GetCraftingInteractionType()
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[UpdateInventories]", "CraftingInteractionType: " .. tos(craftInteractiontype), true, FCOIS_DEBUG_DEPTH_NORMAL) end
    --Are we not inside a crafting station? Else abort as this function will only update the player inventory
    if craftInteractiontype ~= CRAFTING_TYPE_INVALID then return end

    local liFiltersUpdateWasCalled = false

    --Update the current shown inventory
    local lastFilterId = FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere]
    if (libFilters ~= nil and FCOIS.gFilterWhere ~= nil and lastFilterId ~= nil) then
        if settings.debug then debugMessage( "[UpdateInventories]", "Filter Id: " ..tos(lastFilterId) .. ", Filter panel Id: " .. tos(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --Get the current set settings for the filter panels
        FCOIS.gFilterWhere = getFilterWhereBySettings(FCOIS.gFilterWhere, false)
        --Is the filter for this panel enabled in the settings?
        if settings.atPanelEnabled[FCOIS.gFilterWhere]["filters"] == true then
--d("[FCOIS]UpdateInventories-libFiters:RequestUpdate("..tos(FCOIS.gFilterWhere)..")")
            --Is the filter we have added the icon for currently enabled(registered)?
            --local isFilterEnabled = FCOIS.getSettingsIsFilterOn(FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere], FCOIS.gFilterWhere)
            --if isFilterEnabled == FCOIS_CON_FILTER_BUTTON_STATE_GREEN or isFilterEnabled == FCOIS_CON_FILTER_BUTTON_STATE_YELLOW then
            --if settings.debug then debugMessage( "[UpdateInventories]", "UpdaterName: " .. libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere], true, FCOIS_DEBUG_DEPTH_NORMAL) end
            --libFilterVars.inventoryUpdaters[libFilterVars.filterTypeToUpdaterName[FCOIS.gFilterWhere]]()
            liFiltersUpdateWasCalled = true --#282
            libFilters:RequestUpdate(FCOIS.gFilterWhere)
            --end
        end
    end

    refreshBasics(liFiltersUpdateWasCalled)
    refreshListDialog()
end

local function updateUniversalDeconstructionInventory(currentFilterPanelId)
--d("FCOIS]updateUniversalDeconstructionInventory - currentFilterPanelId: " ..tos(currentFilterPanelId))
    currentFilterPanelId = currentFilterPanelId or FCOIS.gFilterWhere
    --Update the currently shown inventory for that deconstruction
    --local universalDeconstructionNPCFilterPanelIdToInventory = FCOIS.mappingVars.universalDeconstructionNPCFilterPanelIdToInventory
    --local invToUpdate = universalDeconstructionNPCFilterPanelIdToInventory[currentFilterPanelId]
    --if not invToUpdate then return end
    updateCraftingInventory(currentFilterPanelId, ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES ~= nil)
end

--Check if other addons with an UI are enabled and shown and update their rows to show/hide FCOIS marker icons now
local function updateOtherAddonUIs()
   --Inventory Insight from Ashes
    FCOIS.CheckIfOtherAddonIIfAIsActive()
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
--d(">UpdateOtherAddonUIs-AF_FCODuplicateItemsFilters found, isFiltering: " ..tos(isFiltering))
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
local checkIfDeconstructionNPC
function FCOIS.FilterBasics(onlyPlayer, isUniversalDeconNPC)
    local currentFilterPanelId = FCOIS.gFilterWhere
    checkIfDeconstructionNPC = checkIfDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC

    --Check if we are in the player inventory
    if not backpackCtrl:IsHidden() then
        --we are in the player inventory (or in the banks at the deposit inventories, or at mail sending, or trading)
        onlyPlayer = true
    end
    if FCOIS.settingsVars.settings.debug then debugMessage( "[FilterBasics]","onlyPlayer: " .. tos(onlyPlayer), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]FilterBasics, onlyPlayer: " ..tos(onlyPlayer) .. ", filterPanel: " ..tos(currentFilterPanelId) .. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC))

    --Only update the lists if not currently already updating
    if FCOIS.preventerVars.gFilteringBasics == false then

        FCOIS.preventerVars.gFilteringBasics = true
        if onlyPlayer == true then
            --d(">>onlyPlayer or companionInv")
            updateInventories()
            --Try to update other addon's UIs
            updateOtherAddonUIs()
        else
            -- -v- #202 Is the universal Deconstruction NPC shown?
            if isUniversalDeconNPC == nil then
                isUniversalDeconNPC = checkIfDeconstructionNPC(currentFilterPanelId)
            end
            if isUniversalDeconNPC == true then
                updateUniversalDeconstructionInventory(currentFilterPanelId)
            -- -^- #202 Is the universal Deconstruction NPC shown?
            -------------------------------------------------------------------
            elseif not ctrlVars.QUICKSLOT_LIST:IsHidden() then
                --d(">>quickSlots")
                --UpdateInventories() -- NO FILTERS YET! So not needed to call libFilters:RequestUpdate(LF_QUICKSLOT)!
                updateQuickSlots()
                --UpdateOtherAddonUIs()
            elseif not ctrlVars.REPAIR_LIST:IsHidden() then
                --d(">>repairList")
                --UpdateInventories() -- NO FILTERS YET! So not needed to call libFilters:RequestUpdate(LF_VENDOR_REPAIR)!
                updateRepairList()
                --UpdateOtherAddonUIs()
            elseif not ctrlVars.RETRAIT_LIST:IsHidden() then
                --d(">>retraitList")
                updateInventories()
                updateTransmutationList()
                updateOtherAddonUIs()
            elseif isCompanionInventoryShown() then
                --d(">>onlyPlayer or companionInv")
                updateInventories()
                --Try to update other addon's UIs
                updateOtherAddonUIs()
            else
                --d(">>inv, crafting inv")
                --Try to update the normal and then the crafting inventories
                updateInventories()
                updateCraftingInventory(nil, false)
                --Try to update other addon's UIs
                updateOtherAddonUIs()
            end

        end
        FCOIS.preventerVars.gFilteringBasics = false
    end
end
local filterBasics = FCOIS.FilterBasics


--Refresh the inventories or a list dialog
function FCOIS.RefreshFilteredInventory(filterPanelId, updateOnlyPlayerInv, rebuildItems)
    local filterPanelIdForRefreshDialog = FCOIS.mappingVars.filterPanelIdForRefreshDialog
    if filterPanelIdForRefreshDialog[filterPanelId] then
        refreshListDialog(rebuildItems, filterPanelId)
    else
        filterBasics(updateOnlyPlayerInv)
    end
end
