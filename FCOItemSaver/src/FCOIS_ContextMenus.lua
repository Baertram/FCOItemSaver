--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage
local debugItem = FCOIS.debugItem

local strsub = string.sub
local strlen = string.len
local zo_strf = zo_strformat

local wm = WINDOW_MANAGER

local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local myColorEnabled	= ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
local myColorDisabled	= ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_DISABLED))
local ctrlVars = FCOIS.ZOControlVars
local zoMenu = ctrlVars.ZOMenu

local getSavedVarsMarkedItemsTableName = FCOIS.GetSavedVarsMarkedItemsTableName
--local getFilterWhereBySettings = FCOIS.getFilterWhereBySettings
local checkIfProtectedSettingsEnabled = FCOIS.CheckIfProtectedSettingsEnabled
local checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
local myGetItemDetails = FCOIS.MyGetItemDetails
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local isItemProtectedAtASlotNow = FCOIS.IsItemProtectedAtASlotNow
local myGetItemInstanceId = FCOIS.MyGetItemInstanceId
local filterBasics = FCOIS.FilterBasics
local scanInventoryItemsForAutomaticMarks = FCOIS.ScanInventoryItemsForAutomaticMarks
local doCompanionItemChecks = FCOIS.DoCompanionItemChecks
local isItemResearchableNoControl = FCOIS.IsItemResearchableNoControl
local checkIfCharOrInvNeedsRingUpdate = FCOIS.CheckIfCharOrInvNeedsRingUpdate
local refreshEquipmentControl = FCOIS.RefreshEquipmentControl
local checkIfOtherDemarksSell = FCOIS.CheckIfOtherDemarksSell
local checkIfOtherDemarksDeconstruction = FCOIS.CheckIfOtherDemarksSell
local isItemResearchable = FCOIS.IsItemResearchable

local isRepairDialogShown = FCOIS.IsRepairDialogShown
local isEnchantDialogShown = FCOIS.IsEnchantDialogShown
local isResearchListDialogShown = FCOIS.IsResearchListDialogShown

local checkIfIsSpecialItem = FCOIS.CheckIfIsSpecialItem
local setItemIsJunk = FCOIS.SetItemIsJunk
local getUndoFilterPanel = FCOIS.GetUndoFilterPanel
local getCurrentSceneInfo = FCOIS.GetCurrentSceneInfo
local getIconsToRemove = FCOIS.GetIconsToRemove
local changeDialogButtonState = FCOIS.ChangeDialogButtonState

local isItemType = FCOIS.IsItemType
local isAutolootContainer = FCOIS.IsAutolootContainer
local isItemBound= FCOIS.IsItemBound
local isItemBindableAtAll = FCOIS.IsItemBindableAtAll

local isItemOwnerCompanion = FCOIS.IsItemOwnerCompanion
local doesPlayerInventoryCurrentFilterEqualCompanion = FCOIS.DoesPlayerInventoryCurrentFilterEqualCompanion
local checkIfItemShouldBeDemarked = FCOIS.CheckIfItemShouldBeDemarked

local getItemSaverControl = FCOIS.GetItemSaverControl
local isCharacterShown = FCOIS.IsCharacterShown
local isCompanionCharacterShown = FCOIS.IsCompanionCharacterShown
local checkIfHouseBankBagAndInOwnHouse = FCOIS.CheckIfHouseBankBagAndInOwnHouse
local getCurrentlyLoggedInCharUniqueId = FCOIS.GetCurrentlyLoggedInCharUniqueId
local changeAntiSettingsAccordingToFilterPanel = FCOIS.ChangeAntiSettingsAccordingToFilterPanel

local buildLocalizedFilterButtonContextMenuEntries = FCOIS.BuildLocalizedFilterButtonContextMenuEntries
local checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate = FCOIS.CheckIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate
local checkAndClearLastMarkedIcons = FCOIS.CheckAndClearLastMarkedIcons

local markAllEquipment = FCOIS.MarkAllEquipment
local checkIfRecipeAddonUsed = FCOIS.CheckIfRecipeAddonUsed
local checkIfResearchAddonUsed = FCOIS.CheckIfResearchAddonUsed
local checkIfChosenResearchAddonActive = FCOIS.CheckIfChosenResearchAddonActive

local destroySelectionHandler = FCOIS.DestroySelectionHandler
local deconstructionSelectionHandler 	= FCOIS.DeconstructionSelectionHandler
local checkIfGuildBankWithdrawAllowed = FCOIS.CheckIfGuildBankWithdrawAllowed

------------------------------------------------------------------------------------------------------------------------
--Get the context menu invoker button by help of the panel Id
local function getContextMenuInvokerButton(panelId)
    panelId = panelId or FCOIS.gFilterWhere
    if not panelId or panelId == 0 then return false end
    --Workaround: Craftbag stuff, check if active panel is the Craftbag
    if FCOIS.IsCraftbagPanelShown() then
        panelId = LF_CRAFTBAG
    end
    local contMenuVars = FCOIS.contextMenuVars
    local retVal = contMenuVars.filterPanelIdToContextMenuButtonInvoker[panelId].name
    if retVal ~= nil and retVal ~= "" then
        return retVal
    else
        return false
    end
end

--Is the owner of a ZO_Menu an FCOIS additional inventory flag button?
local function isMenuOwnerFCOISAdditionalFlagContextMenu(menuOwnerControlToCheck)
    menuOwnerControlToCheck = menuOwnerControlToCheck or getContextMenuInvokerButton()
    local contInvButtonControl = wm:GetControlByName(menuOwnerControlToCheck, "")
    if contInvButtonControl ~= nil then
        local menuOwner = GetMenuOwner()
        return (menuOwner ~= nil and menuOwner == contInvButtonControl) or false
    end
    return false
end

--Is a ZO_Menu visible
local function menuVisibleCheck(checkIfFCOISAddInvFlagOwner, menuOwnerControlToCheck)
    checkIfFCOISAddInvFlagOwner = checkIfFCOISAddInvFlagOwner or false
--d("[FCOIS]menuVisibleCheck-checkIfFCOISAddInvFlagOwner: " ..tostring(checkIfFCOISAddInvFlagOwner) .. ", menuOwnerControlToCheck: " ..tostring(menuOwnerControlToCheck))
    if IsMenuVisible then
        local isVisible = IsMenuVisible()
        --Check if the menu's parent is a FCOIS flag invoker button and ONLY then return true!
        if isVisible and checkIfFCOISAddInvFlagOwner == true then
            isVisible = isMenuOwnerFCOISAdditionalFlagContextMenu(menuOwnerControlToCheck)
        end
--d(">isVisible: " ..tostring(isVisible))
        return isVisible
    end
    return false
end

--Return the first data table of a bagId
local function getCharacterBagData(bagId)
    local bagCache = SHARED_INVENTORY:GetOrCreateBagCache(bagId)
    if bagCache and #bagCache > 0 then
        return bagCache
    end
end

--==========================================================================================================================================
--									FCOIS context menus
--==========================================================================================================================================

--Hide the context menu at the additional inventory flag button, if visible
function FCOIS.hideAdditionalInventoryFlagContextMenu(override)
    override = override or false
    local goOn = false
    if not override then
        goOn = menuVisibleCheck(true, nil) --Check if the menu's parent is a FCOIS flag invoker button and ONLY then return true!
    else
        goOn = true
    end
    if goOn then
        ClearMenu()
    end
end
local hideAdditionalInventoryFlagContextMenu = FCOIS.hideAdditionalInventoryFlagContextMenu


--Function that close the context-menu (if for example the user closes the inventory without
--choosing a option on the context-menu)
--This function also closes the filter button context-menus
function FCOIS.HideContextMenu(whichContextMenu)
--d("[FCOIS] FCOIS.hideContextMenu - whichContextMenu: " .. tostring(whichContextMenu))
    --Hide the context menus at the filter buttons
    if whichContextMenu == nil or whichContextMenu == -1 then
        FCOIS.HideContextMenu(FCOIS.gFilterWhere)
    else
        local contextMenu = FCOIS.contextMenu
        --Hide the lock & dynamic (LOCKDYN) split filter button context-menu
        if contextMenu.LockDynFilter[whichContextMenu] ~= nil then
            if not contextMenu.LockDynFilter[whichContextMenu]:IsHidden() then
                contextMenu.LockDynFilter[whichContextMenu]:SetHidden(true)
            end
        end
        --Hide the gear sets (GEARSETS) split filter button context-menu
        if contextMenu.GearSetFilter[whichContextMenu] ~= nil then
            if not contextMenu.GearSetFilter[whichContextMenu]:IsHidden() then
                contextMenu.GearSetFilter[whichContextMenu]:SetHidden(true)
            end
        end
        --Hide the RESEARCH & DECONSTRUCTION & IMPORVEMENT split filter button context-menu
        if contextMenu.ResDecImpFilter[whichContextMenu] ~= nil then
            if not contextMenu.ResDecImpFilter[whichContextMenu]:IsHidden() then
                contextMenu.ResDecImpFilter[whichContextMenu]:SetHidden(true)
            end
        end
        --Hide the SELL & SELL IN GUILD STORE & INTRICATE split filter button context-menu
        if contextMenu.SellGuildIntFilter[whichContextMenu] ~= nil then
            if not contextMenu.SellGuildIntFilter[whichContextMenu]:IsHidden() then
                contextMenu.SellGuildIntFilter[whichContextMenu]:SetHidden(true)
            end
        end
    end
    --Hide the context menu at the additional inventory flag button, if visible
    hideAdditionalInventoryFlagContextMenu()
end
local hideContextMenu = FCOIS.HideContextMenu


--========= Normal context menus =================================
--Create a table with additional context menu variables and values
--+ the entry "creatingAddon" to identify the custom context menu entries and related addon
function FCOIS.CreateContextMenuAdditionalData(additionalDataTable)
    local addonVars = FCOIS.addonVars
    additionalDataTable["creatingAddon"] = addonVars.gAddonNameShort
    return additionalDataTable
end
local createContextMenuAdditionalData = FCOIS.CreateContextMenuAdditionalData

--Function to show the tooltip at a ZO_Menu context menu entry, using library LibCustomMenu's function "runTooltip(control, inside)"
function FCOIS.ContextMenuEntryTooltipFunc(control, inside, data)
    --d("[FCOIS]FCOIS.contextMenuEntryTooltipFunc-control: " .. tostring(control:GetName()) .. ", inside: " ..tostring(inside))
    if not data then return end
    --Hide old text tooltips
    ZO_Tooltips_HideTextTooltip()
    if not inside or not zoMenu.items or not control or not control:IsMouseEnabled() then return end
    local settings = FCOIS.settingsVars.settings
    if not settings.contextMenuItemEntryShowTooltip then return end
    --Only show if SHIFT key is pressed?
    if settings.contextMenuItemEntryShowTooltipWithSHIFTKeyOnly then
        if not IsShiftKeyDown() then return end
    end
    --Check the selected menu index (row index)
    --index = zo_max(zo_min(index, #ZO_Menu.items), 1)
    --Check if the parentControl of the menu's item menu (e.g. the inventory row) is an allowed FCOIS control
    local menuOwner = zoMenu.owner
    if menuOwner and menuOwner.GetName then
        local menuOwnerName = menuOwner:GetName()
        if not menuOwnerName then return false end
        --FCOIS specific checks for allowed parent control names of the ZO_Menu owner
        local checkVars = FCOIS.checkVars
        local notAllowedContextMenuParentControls = checkVars.notAllowedContextMenuParentControls
        local notAllowedContextMenuControls = checkVars.notAllowedContextMenuControls
        local notAllowed = notAllowedContextMenuParentControls[menuOwnerName] or false
        if not notAllowed then notAllowed = notAllowedContextMenuControls[menuOwnerName] or false end
        if notAllowed then return false end
        --Build the text tooltip
        local addonVars = FCOIS.addonVars
        local textTooltip
        local tooltipData = data
        if tooltipData and tooltipData.creatingAddon and tooltipData.creatingAddon == addonVars.gAddonNameShort then
            textTooltip = tooltipData.text
            local tooltipAnchor = LEFT
            if tooltipData["align"] ~= nil then
                tooltipAnchor = tooltipData["align"]
            end
            --Show the text tooltip now
            ZO_Tooltips_ShowTextTooltip(control, tooltipAnchor, textTooltip)
        end
    else
        return false
    end
    return true -- Set to true so LibCustomMenu's function "runTooltip" won't try to show the text tooltip again
end
local contextMenuEntryTooltipFunc = FCOIS.ContextMenuEntryTooltipFunc

--Function to check if a tooltip should be added to a ZO_Menu item,
--build/enhance the tooltip text then and return the
--so the function contextMenuEntryTooltipFunc(control, inside, data) can show the tooltip later on via LibCustomMenu
function FCOIS.CheckBuildAndAddCustomMenuTooltip(align, tooltipText)
    --d("[FCOIS]CheckBuildAndAddCustomMenuTooltip")
    if not tooltipText or tooltipText == "" then return end
    local settings = FCOIS.settingsVars.settings
    if not settings.contextMenuItemEntryShowTooltip then return end
    return createContextMenuAdditionalData({ ["align"] = align, ["text"] = tooltipText})
end
local checkBuildAndAddCustomMenuTooltip = FCOIS.CheckBuildAndAddCustomMenuTooltip

--Function to reanchor the ZO menu more to the left so it isn't shown above the inventory
local function reAnchorMenu(menuCtrl, offsetX, offsetY)
    if offsetX == nil and offsetY == nil then return false end
    --Get the currently shown menu's width
    if not menuCtrl:IsHidden() then
        local menuWidth = menuCtrl:GetWidth()
        if menuWidth > 0 then
            local menuLeft = menuCtrl:GetLeft()
            if menuLeft >= 0 then
                local menuTop = menuCtrl:GetTop()
                if menuTop >= 0 then
                    --Move the menu the pixels of it's width to the left so it won't be shown above the control
                    local newOffsetX = menuLeft - menuWidth + offsetX -- the left of the anchor minus 5 pixels minus the width of the menu
                    local newOffsetY = menuTop + offsetY -- the left of the anchor minus 5 pixels minus the width of the menu
                    --:SetAnchor(anchorWhereOnThisControl, anchorToContol, anchorToControlWhere, offsetX, offsetY)
                    menuCtrl:ClearAnchors()
                    menuCtrl:SetAnchor(TOPLEFT, menuCtrl:GetParent(), TOPLEFT, newOffsetX, newOffsetY)
                end
            end
        end
    end
end

-- ========================================================================================================================
-- ========================================================================================================================
-- ========================================================================================================================
-- ============================================================
--         Inventories item context menu
-- ============================================================

function FCOIS.RefreshPopupDialogButtons(rowControl, override)
--d("[FCOIS]refreshPopupDialogButtons - rowName:  " ..tostring(rowControl:GetName()) .. ", override: " ..tostring(override))
    override = override or false
    if rowControl == nil then return nil end
    --To remove the active selected row again (was activated during mouse right click/context menu
    FCOIS.RefreshListDialog()
    --Button 1 must not be disabled if we are not inside the research popup (but inside the wayshrine port popup, or weapon enchant/charge popup, or the repair popup, ...)
    --Is the repair dialog shown?
    local isRepairItemDialog = isRepairDialogShown()
    local isEnchantItemDialog = isEnchantDialogShown()
    local isResearchItemDialog = isResearchListDialogShown()

    if not ctrlVars.RepairItemDialog:IsHidden() then
        local disableResearchNow = false
        if not override then

            --get the marked icons of the item
            if rowControl ~= nil and rowControl.dataEntry ~= nil and rowControl.dataEntry.data ~= nil then
                local bagId, slotIndex = myGetItemDetails(rowControl)
                if bagId ~= nil and slotIndex ~= nil then
--d(">bagId, slotIndex: " ..tostring(bagId) ..", " ..tostring(slotIndex) .. ", itemLink: " ..GetItemLink(bagId, slotIndex))
                    local _, markedIcons = FCOIS.IsMarked(bagId, slotIndex, -1)
                    if markedIcons then
                        local settings = FCOIS.settingsVars.settings
                        for iconId, iconIsMarked in pairs(markedIcons) do
                            --Is the current item marked?
                            if iconIsMarked then
--d(">markedIcon: " ..tostring(iconId))
                                --Research (or at least NO repair item dialog!)
                                if not isRepairItemDialog and not isEnchantItemDialog then
                                    --Was the marked icon the research icon?
                                    if iconId == FCOIS_CON_ICON_RESEARCH then
                                        --if researching of marked items is not allowed
                                        if not settings.allowResearch then
                                            disableResearchNow = true
                                            break
                                        end
                                    else
                                        --Why not using internal function with "calledFromExternalAddon" false?
                                        --disableResearchNow = FCOIS.callDeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, true, nil) --leave the panelId empty so the addon will detect it automatically!
                                        --                   FCOIS.DeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
                                        disableResearchNow = deconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, false, nil)
                                        --d(">>RepairItemDialog,refreshPopupDialogButtons-callDeconstructionHandler: " .. tostring(disableResearchNow))
                                        if disableResearchNow == true then break else if not disableResearchNow then disableResearchNow = false end end
                                    end
                                elseif isRepairItemDialog then
                                    --Repair item dialog
                                    --if usage of marked repair kits is not allowed
                                    if settings.blockMarkedRepairKits then
                                        disableResearchNow = true
                                        break
                                    end
                                elseif isEnchantItemDialog then
                                    --Enchant item dialog
                                    --if usage of marked glyphs is not allowed
                                    if settings.blockMarkedGlyphs then
                                        disableResearchNow = true
                                        break
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
--d(">>refreshPopupDialogButtons-disableResearchNow: " ..tostring(disableResearchNow))
        --Is the research not allowed?
        if disableResearchNow == true or override == true then
            rowControl.disableControl = true
            --Clear the current cursor
            ClearCursor()
            --Reset the selected row in the ZO_ListDialog1
            --local origOnSelectedCallback
            if not isResearchItemDialog then
--d(">>>other dialog!")
                ctrlVars.LIST_DIALOG.selectedControl = nil
                ctrlVars.LIST_DIALOG.selectedItem = nil
                rowControl:GetNamedChild("Selected"):SetHidden(true)
            else
                local NO_SELECTED_DATA = nil
                local NO_DATA_CONTROL = nil
                --local RESELECTING_DURING_REBUILD = true
                local NOT_RESELECTING_DURING_REBUILD = false
                local ANIMATE_INSTANTLY = true
                --[[
                local clearMenuNow = menuVisibleCheck() or false
                if clearMenuNow then ClearMenu() end
                ]]
                ZO_ScrollList_SelectData(ctrlVars.LIST_DIALOG, NO_SELECTED_DATA, NO_DATA_CONTROL, NOT_RESELECTING_DURING_REBUILD, ANIMATE_INSTANTLY)
            end
            --Disable the "Research" button in the popup
            changeDialogButtonState(ctrlVars.RepairItemDialog, 1, false)
        else
--d(">>>rowControl.disableControl = false")
            rowControl.disableControl = false
        end
    end -- if not ZO_ListDialog1:IsHidden() then
end
local refreshPopupDialogButtons = FCOIS.RefreshPopupDialogButtons

--The "onClicked" callback function for the right click/context menus to (un)mark an item
--> Called from file FCOIS_ContextMenu.lua, function "FCOIS.AddMark"
function FCOIS.MarkMe(rowControl, markId, updateNow, doUnmark, refreshPopupDialog)
--d("[FCOIS]MarkMe - refreshPopupDialog: " ..tostring(refreshPopupDialog))
    local doAbort = false
    local isNotInHouseAndBagIsHouseBankBag = false
    local itemLink
    local itemInstanceOrUniqueId
    if FCOIS.settingsVars.settings.debug then debugMessage( "[MarkMe]","markId: " .. tostring(markId) .. ", updateNow: " .. tostring(updateNow) .. ", doUnmark: " .. tostring(doUnmark) .. ", refreshPopupDialog: " .. tostring(refreshPopupDialog), FCOIS_DEBUG_DEPTH_ALL) end
    if FCOIS.gFilterWhere == nil then return end
    --Set the last used filter Id at the current panel
    local iconToFilter = FCOIS.mappingVars.iconToFilter
    FCOIS.lastVars.gLastFilterId[FCOIS.gFilterWhere] = iconToFilter[markId]

    --Reset the IIfA clicked variables
    local IIfAclickedData
    FCOIS.IIfAclicked = nil
	FCOIS.IIfAmouseOvered = nil
    --Get the rows bagId and slotIndex
    local iifaItemLink, itemInstanceOrUniqueIdIIfA, bagIdIIfA, slotIndexIIfA, charsTableIIfA, inThisOtherBagsTableIIfA = FCOIS.CheckAndGetIIfAData(rowControl, rowControl:GetParent())
    if itemInstanceOrUniqueIdIIfA ~= nil or (bagIdIIfA ~= nil and slotIndexIIfA ~= nil) then
--d("[FCOIS.MarkMe] IIfA clicked")
        FCOIS.IIfAclicked = {}
        FCOIS.IIfAclicked.itemInstanceOrUniqueId = itemInstanceOrUniqueIdIIfA
        FCOIS.IIfAclicked.itemLink = iifaItemLink
        FCOIS.IIfAclicked.bagId = bagIdIIfA
        FCOIS.IIfAclicked.slotIndex = slotIndexIIfA
        FCOIS.IIfAclicked.ownedByChars = charsTableIIfA
        FCOIS.IIfAclicked.inThisOtherBags = inThisOtherBagsTableIIfA
        --House bank bag?
        if IsHouseBankBag(bagIdIIfA) then
            --Not the owner of the house we are in or not in a house? Reset the bagid and slotIndex now!
            isNotInHouseAndBagIsHouseBankBag = not checkIfHouseBankBagAndInOwnHouse(bagIdIIfA)
        end
        --House bank bag but not in any house/not owner of the house we are in! -> Reset the bagId and slotIndex
        if isNotInHouseAndBagIsHouseBankBag then
--d(">house bank bag but not in any house/not owner of the house we are in!")
            FCOIS.IIfAclicked.bagId = nil
            FCOIS.IIfAclicked.slotIndex = nil
        end
        IIfAclickedData = FCOIS.IIfAclicked
    end
    local bagId, slotIndex = myGetItemDetails(rowControl) -- will internally take bag and slot from IIfAclicked table, if this data is given!
    --Bag and slotIndex are given, or is the bag a house bank and we are not in a house or not the owner of the house?
    if bagId == nil or slotIndex == nil then
--d(">no bag and slotIndex")
        --The addon Inventory Insight provided some data like the itemInstaceOrUniqueId from a right clicked row e.g.
        if IIfAclickedData ~= nil then
            if IIfAclickedData.itemInstanceOrUniqueId ~= nil then
--d(">itemInstanceOrUniqueId found")
                itemInstanceOrUniqueId = IIfAclickedData.itemInstanceOrUniqueId
                itemLink = IIfAclickedData.itemLink
            end
        end
    end

    --Is the marker icon Id given and we should got on?
    if markId ~= nil and doAbort == false then
--itemLink = GetItemLink(bagId, slotIndex)
--d("[FCOIS]MarkMe -  name: " .. rowControl:GetName() .. ", markId: " .. tostring(markId) .. ", doUnmark: " .. tostring(doUnmark) .. " [" .. itemLink .. "]")

        --bagId and slotIndex are given (for currently logged in character or craftbag)
        if bagId ~= nil and slotIndex ~= nil then
--d(">bagId and slotIndex: mark")
            --Unmark the item?
            if doUnmark == true then
                --UnMark the item now, and do not update inventory afterwards as it will be done further downwards!
                FCOIS.preventerVars.markerIconChangedManually = true
                FCOIS.MarkItem(bagId, slotIndex, markId, false, false)

            --Mark the item
            else
                --Check if all markers should be removed prior to setting a new marker.
                --Then set the new marker
                --and do not update the inventory afterwards as it will be done further downwards!
                FCOIS.preventerVars.markerIconChangedManually = true
                FCOIS.MarkItem(bagId, slotIndex, markId, true, false)
                --Are we marking an item inside a popup dialog, e.g. research or repair or enchant item?
                if not refreshPopupDialog then
                    --Is the item protected at a craft station, or the guild store sell tab, or marked as junk now?
                    isItemProtectedAtASlotNow(bagId, slotIndex, false, true)
                end
                --Check if the item mark removed other marks and if a row within another addon (like Inventory Insight) needs to be updated
                checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate(rowControl, markId)
                --Check if the item got an entry in FCOIS.lastMarkedIcons (filled within file src/FCOIS_MarkerIcons.lua, function FCOIS.ClearOrRestoreAllMarkers...))
                --and remove this entry now in order to be able to build a new entry properly via SHIFT + right mouse button
                checkAndClearLastMarkedIcons(bagId, slotIndex)
            end --if mark item ...

        --ItemInstanceOrUniqueId is given (for not logged in character or guild or house bank)
        elseif itemInstanceOrUniqueId ~= nil then
--d(">itemInstanceOrUniqueId: mark")
            --Unmark the item?
            if doUnmark == true then
                --UnMark the item now, and do not update inventory afterwards as the item is marked for a non-logged in character e.g.
                FCOIS.preventerVars.markerIconChangedManually = true
                FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, markId, false, itemLink)

            --Mark the item
            else
                --Check if all markers should be removed prior to setting a new marker.
                --Then set the new marker
                --and do not update the inventory afterwards as as the item is marked for a non-logged in character e.g.
                FCOIS.preventerVars.markerIconChangedManually = true
                FCOIS.MarkItemByItemInstanceId(itemInstanceOrUniqueId, markId, true, itemLink)
                --Check if the item mark removed other marks and if a row within another addon (like Inventory Insight) needs to be updated
                checkIfInventoryRowOfExternalAddonNeedsMarkerIconsUpdate(rowControl, markId)
            end --if mark item ...


        --Bag/slotIndex and itemInstanceOrUniqueId arte missing -> ABORT!
        else
--d("<<<ABORT: mark")
            doAbort = true
        end

        --Should we go on with further checks and marker control changes?
        if doAbort == false then
            --Show/Hide the marker control for the texture but only if not an IIfA entry was clicked
            local controlNameAddition = ""
            if FCOIS.IIfAclicked ~= nil then
                --Add the IIfA texture name part now -> See file AddOns/IIfA/plugins/FCOIS/IIfA_FCOIS.lua
                if FCOIS_IIfA_TEXTURE_CONTROL_NAME ~= nil then
                    controlNameAddition = FCOIS_IIfA_TEXTURE_CONTROL_NAME
                end
            end
            --Get the texture's control for the markId and hide/show it now
            getItemSaverControl(rowControl, markId, true, controlNameAddition):SetHidden(doUnmark)
            --Update the inventories now?
            if (updateNow == true) then
                --Inventory Insight from Ashes update of clicked row needed?
                if FCOIS.IIfAclicked ~= nil then
                    --The function FCOIS.GetItemSaverControl above already determined the IIfA texture control and set the visible state accordingly
                    --for the changed marker icon.
                    --Update the texture for the control now:
                    --Show the FCOIS marker icons at the line, if enabled in the settings (create them if needed)  -> File AddOns/IIfA/plugins/FCOIS/IIfA_FCOIS.lua
                    if IIfA ~= nil and IIfA.UpdateFCOISMarkerIcons ~= nil then
                        local showFCOISMarkerIcons = IIfA:GetSettings().FCOISshowMarkerIcons
                        IIfA:UpdateFCOISMarkerIcons(rowControl, showFCOISMarkerIcons, showFCOISMarkerIcons, markId)

                        --Now check if the inventory or character screen etc. are visible too (together with the IIfA inventory frame) and refresh these panels
                        --then too!
                        --Bag of clicked IIfA row is still given? This means the read data is from the currently logged in char, a craftbag item or a bank item.
                        --All other items are determined via the itemInstanceId as the bagId and slotIndex are ONLY build as the character of the item is logged in!!!
                        if FCOIS.IIfAclicked.bagId ~= nil then
                            --Character bag?
                            if FCOIS.IIfAclicked.bagId == BAG_WORN then
                                if FCOIS.IIfAclicked.slotIndex ~= nil then
                                    local ownedByLoggedInChar = false
                                    --Check if the clicked row's item is from the currently logged in char
                                    if FCOIS.IIfAclicked.ownedByChars ~= nil then
                                        --Get the current char's unique ID and check if it's in the "worn by chars" table from the IIfA savedvars for this curently clicked item
                                        if FCOIS.loggedInCharUniqueId == nil or FCOIS.loggedInCharUniqueId == "" then
                                            FCOIS.loggedInCharUniqueId = getCurrentlyLoggedInCharUniqueId()
                                        end
                                        ownedByLoggedInChar = FCOIS.IIfAclicked.ownedByChars[FCOIS.loggedInCharUniqueId] or false
                                    end
                                    --Yes it is owned by the currently logged in char
                                    if ownedByLoggedInChar then
                                        --Refresh character's equipment slot of the clicked item
                                        --Get the equipmentslot by the help of the slotIndex
                                        local slotIndexToEquiptmentSlotControlName = FCOIS.mappingVars.characterEquipmentSlotNameByIndex
                                        local equipmentSlotName = slotIndexToEquiptmentSlotControlName[FCOIS.IIfAclicked.slotIndex] or ""
                                        if equipmentSlotName ~= "" then
                                            local equipmentSlot = wm:GetControlByName(equipmentSlotName, "")
                                            if equipmentSlot ~= nil then
                                                --FCOIS.RefreshEquipmentControl(equipmentControl, doCreateMarkerControl, p_markId, dontCheckRings)
                                                FCOIS.RefreshEquipmentControl(equipmentSlot, not doUnmark, markId)
                                            end
                                        end
                                    end
                                end
                                --Inventory bag?
                            elseif FCOIS.IIfAclicked.bagId == BAG_BACKPACK
                                --Bank bag?
                                or (FCOIS.IIfAclicked.bagId == BAG_BANK or FCOIS.IIfAclicked.bagId == BAG_SUBSCRIBER_BANK)
                                --Guild bank bag?
                                or FCOIS.IIfAclicked.bagId == BAG_GUILDBANK
                                --House bank bag?
                                or IsHouseBankBag(FCOIS.IIfAclicked.bagId)
                                --CraftBag bag?
                                or FCOIS.IIfAclicked.bagId == BAG_VIRTUAL
                            then
                                --Update the marker icons at the relevant bag's inventory list
                                filterBasics(false)
                            end
                        end
                    end
                else
                    --Inventories or character equipment?
                    local parent = rowControl:GetParent()
                    if parent == ctrlVars.CHARACTER or parent == ctrlVars.COMPANION_CHARACTER then
                        FCOIS.RefreshEquipmentControl(rowControl, not doUnmark, markId)
                    --elseif parent:GetParent() == ctrlVars.QUICKSLOT_LIST then
                        --filterBasics(false)
                    else
                        filterBasics(false)
                    end
                    checkIfCharOrInvNeedsRingUpdate(bagId, slotIndex, parent, not doUnmark, markId)
                end
            else
                --Refresh the ZO_ListDialog1 popup now after right click/context menu was used?
                if refreshPopupDialog then
                    --Is the research dialog shown?
                    --[[
                    if isResearchListDialogShown() then
                        refreshListDialog(SMITHING_RESEARCH_SELECT)
                    end
                    ]]
                    --Refresh the ZO_ListDialog1 buttons
                    refreshPopupDialogButtons(rowControl, false)
                end
            end
        end -- doAbort
    end
    --Reset the IIfAclicked table again
    FCOIS.IIfAclicked = nil
    --Reset the variable for external addons, so marker icons won't be added automatically again (e.g. AlphaGear)
    FCOIS.preventerVars.markerIconChangedManually = false
end
local markMe = FCOIS.MarkMe

--This function will add the FCOIS entries to the right-click context menu of e.g. inventory items
--The function will be called multiple times, for each marker icon once. If you want to check if it was the first time it got called
--you can use the boolean variable "firstAdd"
-->Called from file FCOIS_Hooks.lua, function FCOIS.CreateHooks() -> ZO_InventorySlot_ShowContextMenu_For_FCOItemSaver (LibCustomMenu) ... and ctrlVars.LIST_DIALOG.dataTypes[1].setupCallback
function FCOIS.AddMark(rowControl, markId, isEquipmentSlot, refreshPopupDialog, useSubMenu)
    useSubMenu = useSubMenu or false
    local parentName = rowControl:GetParent():GetName()
    local controlName = rowControl:GetName()
    if parentName == nil or controlName == nil then return end
    local settings = FCOIS.settingsVars.settings
    local mappingVars = FCOIS.mappingVars
    local checkVars = FCOIS.checkVars

    local isIconEnabled = settings.isIconEnabled
    if not isIconEnabled[markId] then return false end

    local isDynamicIcon = mappingVars.iconIsDynamic
    --local isGearIcon = mappingVars.iconIsGear
    local isGearIcon = settings.iconIsGear
    local notAllowedParentCtrls = checkVars.notAllowedContextMenuParentControls
    local notAllowedCtrls       = checkVars.notAllowedContextMenuControls
    local researchableIcons     = mappingVars.iconIsResearchable
    local iconsDisabledAtCompanion = mappingVars.iconIsDisabledAtCompanion
    local allowedCharacterCtrls = checkVars.allowedCharacterEquipmentWeaponControlNames
    local allowedCharacterJewelryControls = checkVars.allowedCharacterEquipmentJewelryControlNames
    local customMenuVars = FCOIS.customMenuVars

    --Initialization of variables
    local firstAdd = false
    local lastAdd = false
    local myFont
    local colDef
    local buttonText = ""
    local isEquipmentSlotContextmenu = false
    local _, countDynIconsEnabled = FCOIS.countMarkerIconsEnabled()
    local useDynSubMenu = (settings.useDynSubMenuMaxCount > 0 and  countDynIconsEnabled >= settings.useDynSubMenuMaxCount) or false
    local isDynamic = isDynamicIcon[markId] or false
    local isGear = isGearIcon[markId] or false
    local isResearchAble = researchableIcons[markId] or false
    local isIconDisabledAtCompanion = iconsDisabledAtCompanion[markId] or false

    ------------------------------------------------------------------------------------------------------------------------
    local notAllowed = false
    local notAllowedCollectible = false
    --[[
    --Todo: --Why did I not allow collectibles here? Maybe as collectibles were inside the inventories and not directly moved to the collectibles?
    local collectibleId
    local dataEntryOfControl = rowControl.dataEntry
    if dataEntryOfControl and dataEntryOfControl.data then
        collectibleId = dataEntryOfControl.data.collectibleId
        --Fix for Unboxer (and maybe other) addon(s): It always sets the collectibleId to 0 also for non collectible items! Normally it would be NIL.
        notAllowedCollectible = (collectibleId and collectibleId > 0) or false
    end
    ]]
    --If quickslots are shown and the collectibles subfilters are selected: Do not allow the FCOIS context menu
    -->Will still show on quest items! So we need to extra check the currentFilter.descriptor
    --Also do not show at normal inventory quest items
    local quickSlotsHidden = ctrlVars.QUICKSLOT:IsHidden()
    local quickSlotsCurrentFilter = ctrlVars.QUICKSLOT_WINDOW.currentFilter
    local quickSlotsCurrentFilterDescriptor  = quickSlotsCurrentFilter and quickSlotsCurrentFilter.descriptor
    local quickslotCurrentFilterIsNotAllowed = (quickSlotsCurrentFilter ~= nil and (quickSlotsCurrentFilter.extraInfo ~= nil or quickSlotsCurrentFilterDescriptor == 26)) or false

    local questItemsInventoryShown = false --TODO

    notAllowed                               = (notAllowedCollectible or notAllowedParentCtrls[parentName] or notAllowedCtrls[controlName]
            --Quickslots
            or ( not quickSlotsHidden and quickslotCurrentFilterIsNotAllowed)
            --Inventory quest items
            or questItemsInventoryShown
        ) or false
    --[[
    if customMenuVars.customMenuCurrentCounter == 1 then
    d("[FCOIS]AddMark - CollectibleId: " ..tostring(collectibleId) .. ", notAllowedCollectible: " ..tostring(notAllowedCollectible) .. ", notAllowed: " ..tostring(notAllowed))
    end
    ]]


    ------------------------------------------------------------------------------------------------------------------------
    --Introduced with FCOIS version 1.0.6
    --Get bagId and slotIndex
    local bag, slotId
    if not notAllowed then
        --Were the bagId and slotIndex already set from IIfA savedvars?
        if FCOIS.IIfAclicked ~= nil then
            bag = FCOIS.IIfAclicked.bagId
            slotId = FCOIS.IIfAclicked.slotIndex
        else
            bag, slotId = myGetItemDetails(rowControl)
        end
        --Check if item is a quickslot item at the 'ALL' subfilter but got no bagId or no slotIndex
        if bag == nil and slotId == nil and not quickSlotsHidden and quickSlotsCurrentFilterDescriptor == 0 then
            notAllowed = true
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    local allowedCharCtrl = allowedCharacterCtrls[controlName] or false
    local allowedCharJewelryControl = allowedCharacterJewelryControls[controlName] or false
    local doCheckOnlyUnbound = settings.allowOnlyUnbound[markId]
    local refreshList
    local contextMenuEntryTextPre = ""
    local contextMenuSubMenuEntryTextPre = ""
    local preventerVars = FCOIS.preventerVars
    local doResearchTraitCheck = checkVars.researchTraitCheck
    local addonVars = FCOIS.addonVars

    --Are we adding the first new entry in the context menu?
    if customMenuVars.customMenuCurrentCounter == 1 then
        firstAdd = true
        lastAdd = false
        --To prevent spamming only output the debug message once for the first added context menu item
        if settings.debug then debugMessage( "[AddMark]", "Parent: " .. parentName .. ", Control: " .. controlName .. ", IsEquipmentSlot: " ..tostring(isEquipmentSlot) .. ", useSubMenu: " .. tostring(useSubMenu), true, FCOIS_DEBUG_DEPTH_NORMAL) end
        --d("[FCOIS.AddMark - Parent: " .. parentName .. ", Control: " .. controlName .. ", IsEquipmentSlot: " ..tostring(isEquipmentSlot) .. ", useSubMenu: " .. tostring(useSubMenu))
        --Check if we clicked a row within the IIfA addon.
        --Will clear (nil) and then fill the table FCOIS.IIfAclicked if itemLink, itemInstanceId, bagId and slotId were found
        --> See file FCOIS_OtherAddons.lua, IIfA
        FCOIS.CheckForIIfARightClickedRow(rowControl)
    else
        if preventerVars.buildingInvContextMenuEntries == false then
            lastAdd = true
            firstAdd = false
            --Dev. info: Reset of the IIfA clicked row variables cannot be done here!
            --As the variables will be NIL then BEFORE the last checks were done (within FCOIS.isItemResearchable() e.g.)
            --It will be NILed further more down after the ShowMenu() function was called for the last entry
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --For equipment slots:
    -- Only go on if markId == static gear marker icons 2, 4, 6, 7 or 8 (gear sets 1 to 5) or dynamic icons setup as gear
    --and an item is equipped (rowControl.stackCount ~= 0)
    if isEquipmentSlot == true then
        if (not isGear and (rowControl.stackCount ~= nil and rowControl.stackCount == 0)) then
            --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            return
            --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        end
        --For 2handed weapons/staffs: Only go on if the current equipment slot is not
        --the 1st weapon set's backup or the 2nd weapon set's backup
        if FCOIS.checkWeaponOffHand(controlName, "2hdall", true, true, firstAdd) == true then return end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --===========================================================================================================
    --Check if the right click menu should be updated. Only allowed panels and menus apply!
    -- Check two tables for parent and control names. If current control and parent are not in the relating table
    -- the contextmenu will be enhanced with FCOItemSaver entries.
    --And check it the item is a collectibel (in quickslots e.g.) and then do not allow the FCOIS context menus
    if notAllowed == true then
        --Not allowed parent or control is given -> Abort here
        if firstAdd == true then
            if settings.debug then debugMessage( "[AddMark]","Not allowed parent '" .. tostring(parentName) .. "' or control '" .. tostring(controlName) .. "' -> Aborted!", true, FCOIS_DEBUG_DEPTH_NORMAL) end
        end
        --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
        return
        --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    end
    ------------------------------------------------------------------------------------------------------------------------

    --Define the font of the context menu entries
    if myFont == nil then
        if not IsInGamepadPreferredMode() then
            myFont = "ZoFontGame"
        else
            myFont = "ZoFontGamepad22"
        end
    end
    --Define the standard color of the context menu entries
    colDef = ZO_ColorDef:New(GetInterfaceColor(INTERFACE_COLOR_TYPE_TEXT_COLORS, INTERFACE_TEXT_COLOR_NORMAL))
    ------------------------------------------------------------------------------------------------------------------------


    -- Equipment gear (static gear marker icons 1, 2, 3, 4, 5), Research, Improve, Deconstruct, Intricate or dynamic icons
    --Check if the icon is allowed for research and if the research-enabled check is set in the settings
    --and if the itemType is a researchable one, and if the item got a trait so research makes sense (only for non-dynamic icons!)
    if isResearchAble or isDynamic then
        local doResearchItemGotTraitCheck = doResearchTraitCheck[markId] or false
        -- Check if item is researchable (as only researchable items can work as equipment too)
        local isResearchable, wasRetraitedOrReconstructed = isItemResearchable(rowControl, markId, doResearchItemGotTraitCheck)
        if not isResearchable then
            return false
        end
        if wasRetraitedOrReconstructed == true then
            if mappingVars.iconIsBlockedBecauseOfRetrait[markId] == true then
                return false
            end
        end
    end

    --Is the setting for "mark all equipped items at once" activated and we are handling an equipment slot
    --and are we trying to add options for gear 1, 2, 3, 4, 5?
    if settings.autoMarkAllEquipment == true then
        if isEquipmentSlot == true and isGear then
            isEquipmentSlotContextmenu = true
            if settings.autoMarkAllWeapon == false then
                if allowedCharCtrl then
                    isEquipmentSlotContextmenu = false
                end
            end
            if settings.autoMarkAllJewelry == false and isEquipmentSlotContextmenu == true then
                if allowedCharJewelryControl then
                    isEquipmentSlotContextmenu = false
                end
            end
        end
    else
        isEquipmentSlotContextmenu = false
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Check with item's bagId and slotIndex
    if bag ~= nil and slotId ~= nil then
        --Check if an item is not-bound yet and only allow to mark it if it's still unbound
        if doCheckOnlyUnbound then
            local isBound = isItemBound(bag, slotId) or false
            --The item is already bound but it should only be un-bound to allow the marker icon
            --> Remove the marker icon from the context menu
            if isBound then return false end
        end

        --Companion owned item and possible icon that should not be applied to context menu?
        if isIconDisabledAtCompanion == true and isItemOwnerCompanion(bag, slotId) == true then
            return false
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Update the list / popup dialog list?
    if refreshPopupDialog == true then
        refreshList = false
    else
        refreshList = true
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Add a divider as first item, between standard ESO and FCOIS context menu entries?
    --Use sub menu entries for the item's context menu?
    --If inside the context menu not the subMenu should be used: Indent the context menu entries with spaces for a better readability?
    if not useSubMenu and settings.addContextMenuLeadingSpaces > 0 then
        --Add spaces in front of each context menu entry to indent them a bit
        for i=1, settings.addContextMenuLeadingSpaces do
            contextMenuEntryTextPre = contextMenuEntryTextPre .. " "
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Colorize the entrys in the context menu with icon colors?
    if settings.contextMenuEntryColorEqualsIconColor then
        --Colorize the entries like the icon's color, or with the normal color?
        colDef = ZO_ColorDef:New(settings.icon[markId].color)
    end
    --Add the marker icon as leading info to the text of each context menu entry?
    if settings.addContextMenuLeadingMarkerIcon then
        --Get the texture
        local textures = FCOIS.textureVars.MARKER_TEXTURES
        local texturesSize = FCOIS.textureVars.MARKER_TEXTURES_SIZE
        local markerIconTextureId = settings.icon[markId].texture
        local markerIconForContextMenuEntry = textures[markerIconTextureId]
        --Get the color of the texture
        local texWidth, texHeight
        --Resize special icons
        if texturesSize[markerIconTextureId] ~= nil and
                texturesSize[markerIconTextureId].width ~= nil and texturesSize[markerIconTextureId].height ~= nil and
                texturesSize[markerIconTextureId].width > 0 and texturesSize[markerIconTextureId].height > 0 then
            texWidth, texHeight = texturesSize[markerIconTextureId].width, texturesSize[markerIconTextureId].height
        else
            texWidth = settings.contextMenuLeadingIconSize
            texHeight = settings.contextMenuLeadingIconSize
        end
        --Get the texture string
        local textureString = zo_iconFormatInheritColor(markerIconForContextMenuEntry, texWidth, texHeight)
        --Colorize the texture with the color choosen in the settings
        buttonText = colDef:Colorize(textureString)
        if buttonText ~= nil then
            if texturesSize[markerIconTextureId] ~= nil and texturesSize[markerIconTextureId].contextMenuOffsetLeft ~= nil and texturesSize[markerIconTextureId].contextMenuOffsetLeft > 0 then
                buttonText = " |u"..tonumber(texturesSize[markerIconTextureId].contextMenuOffsetLeft)..":0::|u" .. buttonText
            end
        end
    else
        --No icon, only colorize the entries
        buttonText = colDef:Colorize(buttonText)
    end
    if useSubMenu then
        contextMenuSubMenuEntryTextPre = contextMenuSubMenuEntryTextPre .. buttonText
    else
        if useDynSubMenu then
            contextMenuSubMenuEntryTextPre = contextMenuSubMenuEntryTextPre .. buttonText
        end
        contextMenuEntryTextPre = contextMenuEntryTextPre .. buttonText
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Tooltip at context menu entry align
    local tooltipAlign = LEFT
    if isEquipmentSlot then
        tooltipAlign = RIGHT
    end

    local locVars = FCOIS.localizationVars
    local locVarsFCOIS = locVars.fcois_loc
    local contMenuVars = FCOIS.contextMenuVars
    contMenuVars.contextMenuIndex = -1
    local newSubEntry = {}
    local newDynSubEntry = {}
    --If the first icon/option is present: No submenu for the FCOIS marker icons enabled.
    if not useSubMenu and firstAdd then
        --Add an information line to the context menu to split the FCOIS options from the rest/standard
        local tooltipText = ""
        if settings.showContextMenuDivider then
            local callbackFnc
            local menuItemType
            if settings.contextMenuDividerShowsSettings then
                callbackFnc = function() FCOIS.ShowFCOItemSaverSettings() end
                menuItemType = MENU_ADD_OPTION_LABEL
                tooltipText = locVarsFCOIS["options_contextmenu_divider_opens_settings_TT"]

            elseif settings.contextMenuDividerClearsMarkers
                    and not isEquipmentSlot and ctrlVars.LIST_DIALOG:IsHidden() then
                callbackFnc = function() FCOIS.ClearOrRestoreAllMarkers(rowControl) end
                menuItemType = MENU_ADD_OPTION_LABEL
                tooltipText = locVarsFCOIS["options_contextmenu_divider_clears_all_markers_TT"]

            else
                callbackFnc = function() end
                menuItemType = MENU_ADD_OPTION_LABEL
                tooltipText = ""
            end
            --                              AddCustomMenuItem(mytext, myfunction, itemType, myFont, normalColor, highlightColor, itemYPad, horizontalAlignment, customMenuItemData)
            contMenuVars.contextMenuIndex = AddCustomMenuItem(addonVars.addonNameContextMenuEntry, function() callbackFnc() end, menuItemType, nil, nil, nil, nil, nil)
            if tooltipText and tooltipText ~= "" then
                AddCustomMenuTooltip(function(control, inside)
                    local tooltipData=checkBuildAndAddCustomMenuTooltip(tooltipAlign, tooltipText)
                    contextMenuEntryTooltipFunc(control, inside, tooltipData) end,
                        contMenuVars.contextMenuIndex)
            end
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Is debugging enabled? Then add the current item's bagId and slotIndex to the context menu with a callback funciton to put the info into the chat for the ZGOO addon
    if firstAdd and settings.debug then
        local bagId, slotIndex
        --Were the bagId and slotIndex already set from IIfA savedvars?
        if FCOIS.IIfAclicked ~= nil then
            bagId = FCOIS.IIfAclicked.bagId
            slotIndex = FCOIS.IIfAclicked.slotIndex
        else
            bagId, slotIndex = myGetItemDetails(rowControl)
        end
        AddCustomMenuItem("---[DEBUG>   Bag: " .. tostring(bagId) .. " / Slot: " .. tostring(slotIndex) .. " ]---", function() debugItem(bagId, slotIndex) end, MENU_ADD_OPTION_LABEL)
    end

    --Is the current markId already set at the item?
    local isMarkIdProtected = checkIfItemIsProtected(markId, myGetItemInstanceId(rowControl))
    local newAddedMenuIndex

    --Build the tooltiptext for the current markId's menuItem
    local tooltipText = ""
    if settings.contextMenuItemEntryShowTooltip then
        if settings.contextMenuItemEntryTooltipProtectedPanels then
            tooltipText = FCOIS.buildMarkerIconProtectedWhereTooltip(markId)
        end
    end

    ------------------------------------------------------------------------------------------------------------------------
    --Add the equipment right click / context menu entries
    if isEquipmentSlotContextmenu == true then

        -- Add/Update the right click menu item for character slot now
        if not isMarkIdProtected then
            if useSubMenu then
                newSubEntry = {
                    label = contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentMark[markId],
                    callback = function()  markAllEquipment(rowControl, markId, refreshList, false) end,
                    myfont          = myFont,
                    normalColor     = colDef,
                    highlightColor  = colDef,
                    tooltip         = function(control, inside)
                        local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentMark[markId] .. "\n" .. tooltipText)
                        contextMenuEntryTooltipFunc(control, inside, data)
                    end,
                }
            else
                --use the submenu for the dynamic icons?
                if isDynamic and useDynSubMenu then
                    newDynSubEntry = {
                        label = contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentMark[markId],
                        callback = function() markAllEquipment(rowControl, markId, refreshList, false) end,
                        myfont          = myFont,
                        normalColor     = colDef,
                        highlightColor  = colDef,
                        tooltip         = function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentMark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data)
                        end,
                    }
                else
                    --AddMenuItem(locVars.lTextEquipmentMark[markId], function() markAllEquipment(rowControl, markId, refreshList, false) end, MENU_ADD_OPTION_LABEL)
                    --d("[FCOIS]AddMark - markId: " ..tostring(markId) .. ", text: " ..tostring(locVars.lTextEquipmentMark[markId]))
                    newAddedMenuIndex = AddCustomMenuItem(contextMenuEntryTextPre .. locVars.lTextEquipmentMark[markId], function()  markAllEquipment(rowControl, markId, refreshList, false) end, MENU_ADD_OPTION_LABEL, myFont, colDef, colDef, nil, nil)
                    if tooltipText and tooltipText ~= "" then
                        AddCustomMenuTooltip(function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuEntryTextPre .. locVars.lTextEquipmentMark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data) end,
                                newAddedMenuIndex)
                    end
                end
            end
        else
            if useSubMenu then
                if settings.useContextMenuCustomMarkedNormalColor then
                    newSubEntry = {
                        label = contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId],
                        callback = function() markAllEquipment(rowControl, markId, refreshList, true) end,
                        myfont = "ZoFontGame",
                        normalColor = ZO_ColorDef:New(settings.contextMenuCustomMarkedNormalColor),
                        myfont          = myFont,
                        highlightColor  = colDef,
                        tooltip         = function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data)
                        end,
                    }
                else
                    newSubEntry = {
                        label = contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId],
                        callback = function() markAllEquipment(rowControl, markId, refreshList, true) end,
                        myfont          = myFont,
                        normalColor     = colDef,
                        highlightColor  = colDef,
                        tooltip         = function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data)
                        end,
                    }
                end
            else
                --AddMenuItem(locVars.lTextEquipmentDemark[markId], function() markAllEquipment(rowControl, markId, refreshList, true) end, MENU_ADD_OPTION_LABEL)
                if settings.useContextMenuCustomMarkedNormalColor then
                    --use the submenu for the dynamic icons?
                    if isDynamic and useDynSubMenu then
                        newDynSubEntry = {
                            label = contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId],
                            callback = function() markAllEquipment(rowControl, markId, refreshList, true) end,
                            myfont = "ZoFontGame",
                            normalColor = ZO_ColorDef:New(settings.contextMenuCustomMarkedNormalColor),
                            myfont          = myFont,
                            highlightColor  = colDef,
                            tooltip         = function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data)
                            end,
                        }
                    else
                        newAddedMenuIndex = AddCustomMenuItem(contextMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId], function() markAllEquipment(rowControl, markId, refreshList, true) end, MENU_ADD_OPTION_LABEL, myFont, ZO_ColorDef:New(settings.contextMenuCustomMarkedNormalColor), colDef, nil, nil)
                        if tooltipText and tooltipText ~= "" then
                            AddCustomMenuTooltip(function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data) end,
                                    newAddedMenuIndex)
                        end
                    end
                else
                    --use the submenu for the dynamic icons?
                    if isDynamic and useDynSubMenu then
                        newDynSubEntry = {
                            label = contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId],
                            callback = function() markAllEquipment(rowControl, markId, refreshList, true) end,
                            myfont          = myFont,
                            normalColor     = colDef,
                            highlightColor  = colDef,
                            tooltip         = function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data)
                            end,
                        }
                    else
                        newAddedMenuIndex = AddCustomMenuItem(contextMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId], function() markAllEquipment(rowControl, markId, refreshList, true) end, MENU_ADD_OPTION_LABEL, myFont, colDef, colDef, nil, nil)
                        if tooltipText and tooltipText ~= "" then
                            AddCustomMenuTooltip(function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuEntryTextPre .. locVars.lTextEquipmentDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data) end,
                                    newAddedMenuIndex)
                        end
                    end
                end
            end
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the normal (e.g. inventory) right click / context menu entries
    else

        --AddCustomMenuItem(mytext, myfunction, itemType, myfont, normalColor, highlightColor, itemYPad)

        -- Add/Update the right click menu item now
        if(not isMarkIdProtected) then
            if useSubMenu then
                newSubEntry = {
                    label = contextMenuSubMenuEntryTextPre .. locVars.lTextMark[markId],
                    callback = function() markMe(rowControl, markId, refreshList, false, refreshPopupDialog) end,
                    myfont          = myFont,
                    normalColor     = colDef,
                    highlightColor  = colDef,
                    tooltip         = function(control, inside)
                        local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextMark[markId] .. "\n" .. tooltipText)
                        contextMenuEntryTooltipFunc(control, inside, data)
                    end,
                }
            else
                --use the submenu for the dynamic icons?
                if isDynamic and useDynSubMenu then
                    newDynSubEntry = {
                        label = contextMenuSubMenuEntryTextPre .. locVars.lTextMark[markId],
                        callback = function() markMe(rowControl, markId, refreshList, false, refreshPopupDialog) end,
                        myfont          = myFont,
                        normalColor     = colDef,
                        highlightColor  = colDef,
                        tooltip         = function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextMark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data)
                        end,
                    }
                else
                    --AddMenuItem(contextMenuEntryTextPre .. locVars.lTextMark[markId], function() markMe(rowControl, markId, refreshList, false, refreshPopupDialog) end, MENU_ADD_OPTION_LABEL)
                    newAddedMenuIndex = AddCustomMenuItem(contextMenuEntryTextPre .. locVars.lTextMark[markId], function() markMe(rowControl, markId, refreshList, false, refreshPopupDialog) end, MENU_ADD_OPTION_LABEL, myFont, colDef, colDef, nil, nil)
                    if tooltipText and tooltipText ~= "" then
                        AddCustomMenuTooltip(function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuEntryTextPre .. locVars.lTextMark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data) end,
                                newAddedMenuIndex)
                    end
                end
            end
        else
            if useSubMenu then
                if settings.useContextMenuCustomMarkedNormalColor then
                    newSubEntry = {
                        label = contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId],
                        callback = function() markMe(rowControl, markId, refreshList, true, refreshPopupDialog) end,
                        myfont = "ZoFontGame",
                        normalColor = ZO_ColorDef:New(settings.contextMenuCustomMarkedNormalColor),
                        myfont          = myFont,
                        highlightColor  = colDef,
                        tooltip         = function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data)
                        end,
                    }
                else
                    newSubEntry = {
                        label = contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId],
                        callback = function() markMe(rowControl, markId, refreshList, true, refreshPopupDialog) end,
                        myfont          = myFont,
                        normalColor     = colDef,
                        highlightColor  = colDef,
                        tooltip         = function(control, inside)
                            local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId] .. "\n" .. tooltipText)
                            contextMenuEntryTooltipFunc(control, inside, data)
                        end,
                    }
                end
            else
                --AddMenuItem(locVars.lTextDemark[markId], function() markMe(rowControl, markId, refreshList, true, refreshPopupDialog) end, MENU_ADD_OPTION_LABEL)
                if settings.useContextMenuCustomMarkedNormalColor then
                    --use the submenu for the dynamic icons?
                    if isDynamic and useDynSubMenu then
                        newDynSubEntry = {
                            label = contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId],
                            callback = function() markMe(rowControl, markId, refreshList, true, refreshPopupDialog) end,
                            myfont = "ZoFontGame",
                            normalColor = ZO_ColorDef:New(settings.contextMenuCustomMarkedNormalColor),
                            myfont          = myFont,
                            highlightColor  = colDef,
                            tooltip         = function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data)
                            end,
                        }
                    else
                        newAddedMenuIndex = AddCustomMenuItem(contextMenuEntryTextPre .. locVars.lTextDemark[markId], function() markMe(rowControl, markId, refreshList, true, refreshPopupDialog) end, MENU_ADD_OPTION_LABEL, myFont, ZO_ColorDef:New(settings.contextMenuCustomMarkedNormalColor), colDef, nil, nil)
                        if tooltipText and tooltipText ~= "" then
                            AddCustomMenuTooltip(function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuEntryTextPre .. locVars.lTextDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data) end,
                                    newAddedMenuIndex)
                        end
                    end
                else
                    --use the submenu for the dynamic icons?
                    if isDynamic and useDynSubMenu then
                        newDynSubEntry = {
                            label = contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId],
                            callback = function() markMe(rowControl, markId, refreshList, true, refreshPopupDialog) end,
                            myfont          = myFont,
                            normalColor     = colDef,
                            highlightColor  = colDef,
                            tooltip         = function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuSubMenuEntryTextPre .. locVars.lTextDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data)
                            end,
                        }
                    else
                        newAddedMenuIndex = AddCustomMenuItem(contextMenuEntryTextPre .. locVars.lTextDemark[markId], function() markMe(rowControl, markId, refreshList, true, refreshPopupDialog) end, MENU_ADD_OPTION_LABEL, myFont, colDef, colDef, nil, nil)
                        if tooltipText and tooltipText ~= "" then
                            AddCustomMenuTooltip(function(control, inside)
                                local data=checkBuildAndAddCustomMenuTooltip(tooltipAlign, contextMenuEntryTextPre .. locVars.lTextDemark[markId] .. "\n" .. tooltipText)
                                contextMenuEntryTooltipFunc(control, inside, data) end,
                                    newAddedMenuIndex)
                        end
                    end
                end
            end
        end

    end
    ------------------------------------------------------------------------------------------------------------------------
    --Show the menu now!
    if useSubMenu then
        --Add the submenu to the context menu
        table.insert(customMenuVars.customMenuSubEntries, newSubEntry)
    else
        --Is the submenu for the dynamic icons enabled?
        if useDynSubMenu then
            --Add the submenu of dynamic icons to the context menu now
            table.insert(customMenuVars.customMenuDynSubEntries, newDynSubEntry)
        end

        --Show the new added menu entries inside the context menu borders
        --Do not remove this or context menu is not working anymore in ZO_Dialog1 !
        ShowMenu(rowControl)
        --Last context menu entry was added?
        if preventerVars.buildingInvContextMenuEntries == false then
            --Reset the IIfA clicked row variables again if the last entry of the context menu was added!
            FCOIS.IIfAclicked = nil
        end

        --Modify the spacer context menu entry so it isn't enabled for the mouse
        if firstAdd and settings.showContextMenuDivider and contMenuVars ~= nil and contMenuVars.contextMenuIndex  ~= nil and contMenuVars.contextMenuIndex ~= -1 then
            local contextMenuItemControl = zoMenu.items[contMenuVars.contextMenuIndex].item
            if contextMenuItemControl ~= nil then
                --Overwrite onMouseEnter events
                if ( (contextMenuItemControl.creatingAddon and contextMenuItemControl.creatingAddon == addonVars.gAddonNameShort) and
                        ((isEquipmentSlot) or (not ctrlVars.LIST_DIALOG:IsHidden())
                                or (not settings.contextMenuDividerShowsSettings and not settings.contextMenuDividerClearsMarkers)) ) then
                    contextMenuItemControl:SetMouseEnabled(false)
                    --Reenable the mouse for this menu item if the menu closes. See file /src/FCOIS_Hooks.lua, function  PreHook to ZO_Menu_OnHide
                    FCOIS.preventerVars.disabledContextMenuItemIndex = contMenuVars.contextMenuIndex
                else
                    contextMenuItemControl:SetMouseEnabled(true)
                end
            end
        end
    end
end

--Function to update the localized strings for the right-click context menu entries in the slotActions
local function setSlotActionContextMenuTexts()
--d("[FCOIS] setSlotActionContextMenuTexts")
    local locContEntries = FCOIS.localizationVars.contextEntries
    if locContEntries == nil then return false end
    --Mapping vars
    local mappingVars = FCOIS.mappingVars
    local iconToGear = mappingVars.iconToGear
    --Set texts for the right-click item menus
    FCOIS.localizationVars.lTextMark = {
        locContEntries.menu_add_lock_text,
        locContEntries.menu_add_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_1]],
        locContEntries.menu_add_research_text,
        locContEntries.menu_add_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_2]],
        locContEntries.menu_add_sell_text,
        locContEntries.menu_add_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_3]],
        locContEntries.menu_add_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_4]],
        locContEntries.menu_add_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_5]],
        locContEntries.menu_add_deconstruction_text,
        locContEntries.menu_add_improvement_text,
        locContEntries.menu_add_sell_to_guild_text,
        locContEntries.menu_add_intricate_text,
    }
    FCOIS.localizationVars.lTextDemark = {
        locContEntries.menu_remove_lock_text,
        locContEntries.menu_remove_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_1]],
        locContEntries.menu_remove_research_text,
        locContEntries.menu_remove_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_2]],
        locContEntries.menu_remove_sell_text,
        locContEntries.menu_remove_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_3]],
        locContEntries.menu_remove_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_4]],
        locContEntries.menu_remove_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_5]],
        locContEntries.menu_remove_deconstruction_text,
        locContEntries.menu_remove_improvement_text,
        locContEntries.menu_remove_sell_to_guild_text,
        locContEntries.menu_remove_intricate_text,
    }

    --Set texts for the right-click equipment item menus
    FCOIS.localizationVars.lTextEquipmentMark = {
        locContEntries.menu_add_lock_text,
        locContEntries.menu_add_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_1]],
        locContEntries.menu_add_research_text,
        locContEntries.menu_add_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_2]],
        locContEntries.menu_add_sell_text,
        locContEntries.menu_add_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_3]],
        locContEntries.menu_add_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_4]],
        locContEntries.menu_add_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_5]],
        locContEntries.menu_add_deconstruction_text,
        locContEntries.menu_add_improvement_text,
        locContEntries.menu_add_sell_to_guild_text,
        locContEntries.menu_add_intricate_text,
    }
    FCOIS.localizationVars.lTextEquipmentDemark = {
        locContEntries.menu_remove_lock_text,
        locContEntries.menu_remove_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_1]],
        locContEntries.menu_remove_research_text,
        locContEntries.menu_remove_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_2]],
        locContEntries.menu_remove_sell_text,
        locContEntries.menu_remove_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_3]],
        locContEntries.menu_remove_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_4]],
        locContEntries.menu_remove_all_gear_text[iconToGear[FCOIS_CON_ICON_GEAR_5]],
        locContEntries.menu_remove_deconstruction_text,
        locContEntries.menu_remove_improvement_text,
        locContEntries.menu_remove_sell_to_guild_text,
        locContEntries.menu_remove_intricate_text,
    }

    --Add the dynamic icon entries to the tables
    --local numDynIcons = FCOIS.numVars.gFCONumDynamicIcons
    local settings = FCOIS.settingsVars.settings
    local numDynIcons   = settings.numMaxDynamicIconsUsable
    local dynIconCounter2IconNr = FCOIS.mappingVars.dynamicToIcon
    local isDynamicIcon = FCOIS.mappingVars.iconIsDynamic
    --Check if the dynamic icon is a gear icon
    local iconIsGear = settings.iconIsGear
    local currentGearNr = FCOIS.numVars.gFCONumGearSetsStatic

    for dynamicIconId=1, numDynIcons do
        local dynIconNr = dynIconCounter2IconNr[dynamicIconId]
        local isDynIcon = isDynamicIcon[dynIconNr]
        if isDynIcon then
            if iconIsGear[dynIconNr] then
                currentGearNr = currentGearNr + 1
                table.insert(FCOIS.localizationVars.lTextMark,              locContEntries.menu_add_gear_text[currentGearNr])
                table.insert(FCOIS.localizationVars.lTextDemark,            locContEntries.menu_remove_gear_text[currentGearNr])
                table.insert(FCOIS.localizationVars.lTextEquipmentMark,     locContEntries.menu_add_all_gear_text[currentGearNr])
                table.insert(FCOIS.localizationVars.lTextEquipmentDemark,   locContEntries.menu_remove_all_gear_text[currentGearNr])
            else
    --d(">>Dyn icon: " ..tostring(dynamicIconId) .. ", mapped icon nr: " .. tostring(dynIconNr) ..", text-> lTextEquipmentMark: " ..tostring(locContEntries.menu_add_dynamic_text[dynamicIconId]))
                table.insert(FCOIS.localizationVars.lTextMark,              locContEntries.menu_add_dynamic_text[dynamicIconId])
                table.insert(FCOIS.localizationVars.lTextDemark,            locContEntries.menu_remove_dynamic_text[dynamicIconId])
                table.insert(FCOIS.localizationVars.lTextEquipmentMark,     locContEntries.menu_add_dynamic_text[dynamicIconId])
                table.insert(FCOIS.localizationVars.lTextEquipmentDemark,   locContEntries.menu_remove_dynamic_text[dynamicIconId])
            end
        end
    end

end

-- Change the inventories item right click menu texts to the chosen settings value
function FCOIS.ChangeContextMenuEntryTexts(iconId)
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[changeContextMenuEntryTexts]","iconId: " .. tostring(iconId), true, FCOIS_DEBUG_DEPTH_ALL) end
    local locContEntries = FCOIS.localizationVars.contextEntries
    if locContEntries == nil then return false end
    --d("[FCOIS] FCOIS.changeContextMenuEntryTexts - iconId: " .. tostring(iconId))
    local updateSlotActionTextsNow = false
    local locVars = FCOIS.localizationVars.fcois_loc
    local dynamicIcons = FCOIS.mappingVars.iconIsDynamic
    --local gearIcons = FCOIS.mappingVars.iconIsGear
    local gearIcons = settings.iconIsGear

    --Update all icon texts?
    if iconId == -1 then
        FCOIS.preventerVars.buildingSlotActionTexts = false
        --Reset the localization array variables
        locContEntries.menu_add_gear_text = {}
        locContEntries.menu_remove_gear_text = {}
        locContEntries.menu_add_all_gear_text = {}
        locContEntries.menu_remove_all_gear_text = {}
        locContEntries.menu_add_dynamic_text = {}
        locContEntries.menu_remove_dynamic_text = {}

        --Loop over all icons and build the texts for the context menus now
        for p_iconId=FCOIS_CON_ICON_LOCK, numFilterIcons do
            FCOIS.preventerVars.buildingSlotActionTexts = true
            --Recursively call this function for each iconId
            FCOIS.ChangeContextMenuEntryTexts(p_iconId)
            FCOIS.preventerVars.buildingSlotActionTexts = false
            updateSlotActionTextsNow = true
        end

        --Update only one icons text
    else -- if iconId == -1 then
        --Create tables if empty until now
        if  locContEntries.menu_add_gear_text == nil then
            locContEntries.menu_add_gear_text = {}
        end
        if  locContEntries.menu_remove_gear_text == nil then
            locContEntries.menu_remove_gear_text = {}
        end
        if  locContEntries.menu_add_all_gear_text == nil then
            locContEntries.menu_add_all_gear_text = {}
        end
        if  locContEntries.menu_remove_all_gear_text == nil then
            locContEntries.menu_remove_all_gear_text = {}
        end
        if  locContEntries.menu_add_dynamic_text == nil then
            locContEntries.menu_add_dynamic_text = {}
        end
        if  locContEntries.menu_remove_dynamic_text == nil then
            locContEntries.menu_remove_dynamic_text = {}
        end

        local isGearIcon 	= gearIcons[iconId]
        local isDynamicIcon = dynamicIcons[iconId]
        --d(">Icon (" .. iconId .. "): isGear: ".. tostring(isGearIcon) .. ", isDynamic: " ..tostring(isDynamicIcon))

        --Is the icon a gear set?
        if isGearIcon then
            local l_gearId = FCOIS.mappingVars.iconToGear[iconId]
            --d("gearId: " .. tostring(l_gearId) .. ", name: " ..tostring(settings.icon[iconId].name))
            if l_gearId ~= nil then
                if(settings.icon[iconId].name ~= nil and settings.icon[iconId].name ~= '' and settings.icon[iconId].name ~= locVars["rightclick_menu_add_gear" .. l_gearId]) then
                    locContEntries.menu_add_gear_text[l_gearId] 	    = locVars["rightclick_menu_add_start_gear"] .. settings.icon[iconId].name
                    locContEntries.menu_remove_gear_text[l_gearId] 	    = locVars["rightclick_menu_remove_start_gear"] .. settings.icon[iconId].name
                    locContEntries.menu_add_all_gear_text[l_gearId]     = locVars["rightclick_menu_add_all_start_gear"] .. settings.icon[iconId].name
                    locContEntries.menu_remove_all_gear_text[l_gearId]  = locVars["rightclick_menu_remove_all_start_gear"] .. settings.icon[iconId].name
                else
                    locContEntries.menu_add_gear_text[l_gearId] 	    = locVars["rightclick_menu_add_gear" .. l_gearId]
                    locContEntries.menu_remove_gear_text[l_gearId] 	    = locVars["rightclick_menu_remove_gear" .. l_gearId]
                    locContEntries.menu_add_all_gear_text[l_gearId]     = locVars["rightclick_menu_add_all_gear" .. l_gearId]
                    locContEntries.menu_remove_all_gear_text[l_gearId]  = locVars["rightclick_menu_remove_all_gear" .. l_gearId]
                end
                updateSlotActionTextsNow = true
            end
        end
        --Is the icon a dynamic settings icon? Dynamic icons can be dynamic + gear icons!
        if isDynamicIcon then
            local l_dynamicId = FCOIS.mappingVars.iconToDynamic[iconId]
            if l_dynamicId ~= nil then
                if(settings.icon[iconId].name ~= nil and settings.icon[iconId].name ~= '' and settings.icon[iconId].name ~= locVars["rightclick_menu_add_dynamic"] .. l_dynamicId) then
                    locContEntries.menu_add_dynamic_text[l_dynamicId] 	= settings.icon[iconId].name
                    locContEntries.menu_remove_dynamic_text[l_dynamicId]= settings.icon[iconId].name
                else
                    locContEntries.menu_add_dynamic_text[l_dynamicId] 	= locVars["rightclick_menu_add_dynamic"] .. l_dynamicId
                    locContEntries.menu_remove_dynamic_text[l_dynamicId]= locVars["rightclick_menu_remove_dynamic"] .. l_dynamicId
                end
                updateSlotActionTextsNow = true
            end
        end

    end -- if iconId == -1 then

    --Update the texts in the right-click context menu's slotaction entries now?
    if not FCOIS.preventerVars.buildingSlotActionTexts and updateSlotActionTextsNow then
        setSlotActionContextMenuTexts()
    end
end
local changeContextMenuEntryTexts = FCOIS.ChangeContextMenuEntryTexts

--Reset the user's icon sort order to the default values again
function FCOIS.ResetUserContextMenuSortOrder()
--d("[FCOIS]resetUserContextMenuSortOrder")
    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[resetUserContextMenuSortOrder]", "executed", true, FCOIS_DEBUG_DEPTH_NORMAL) end
    local defaults = FCOIS.settingsVars.defaults
    local retVar = false
    --For each icon get the default sort order and reset it so the LAM dropdown boxes show the standard sort order again
    for iconId = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        settings.icon[iconId].sortOrder = defaults.icon[iconId].sortOrder
        settings.iconSortOrder[iconId]  = defaults.iconSortOrder[iconId]
    end
    retVar = true
    return retVar
end
local resetUserContextMenuSortOrder = FCOIS.ResetUserContextMenuSortOrder

--Check if the user specified a valid context menu ordering
-->With FCOIS 2.0.3 it should be always valid due to the usage of the LibAddonMenu-2.0 OrderListBox, and no dropdown boxes anymore!
function FCOIS.CheckIfUserContextMenuSortOrderValid(returnDuplicates)
    returnDuplicates = returnDuplicates or false
--d("[FCOIS.checkIfUserContextMenuSortOrderValid] - returnDuplicates: " .. tostring(returnDuplicates))
    local resultVar = true
    local checkDuplicateTable = {}
    local duplicatesTable = {}
    local settings = FCOIS.settingsVars.settings
    --local defaults = FCOIS.settingsVars.defaults
    --check each iconId if there are duplicates in the custom user sort order for the context menu
    for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        if not checkDuplicateTable[settings.icon[i].sortOrder] then
--d("> added sortOrder " .. i)
            checkDuplicateTable[settings.icon[i].sortOrder] = true
        else
--d(">>> Sort order " .. settings.icon[i].sortOrder .. " is duplicate!")
            resultVar = false
            if not returnDuplicates then
                break -- end the loop here
            else
                duplicatesTable[settings.icon[i].sortOrder] = { iconNr = i, sortOrder = settings.icon[i].sortOrder, duplicate = true }
            end
        end
    end
    if not returnDuplicates then
        return resultVar, nil
    else
        local rescanDuplicatesTable = {}
        --Add each icon to the duplicates table and mark those as duplicate which are in the checkDuplicateTable table
        --First add all icons with the standard settings and isDuplicate = false
        for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            if duplicatesTable[i] == nil then
                --d(">Added sort order " .. tostring(i) .. " to the duplicates info table")
                duplicatesTable[i] = { iconNr = i, sortOrder = settings.icon[i].sortOrder, duplicate = false }
            else
                --The current sortOrder was already in the duplicate table. Remember it for the 2nd scan -> Get already added duplicates
                --and rescan all other entries -> Set the isDuplicate flag to true where the same sortOrder is found
                table.insert(rescanDuplicatesTable, duplicatesTable[i])
            end
        end
        --Then rescan the table again and put all duplicate entries (compared via the sort order)'s isDuplicate flag to true
        --d(">Rescan the duplicates now...")
        for _, rescanData in ipairs(rescanDuplicatesTable) do
            -- Is the sortOrder given?
            if rescanData.sortOrder ~= nil then
                --d(">Rescan sortOrder: " .. tostring(rescanData.sortOrder))
                --Check each icon in the duplicate table
                for i = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                    if duplicatesTable[i] ~= nil and duplicatesTable[i].sortOrder == rescanData.sortOrder and duplicatesTable[i].iconNr ~= rescanData.iconNr then
                        --d(">Found another duplicate at icon " .. tostring(duplicatesTable[i].iconNr))
                        duplicatesTable[i].duplicate = true
                    end
                end
            end
        end
        return resultVar, duplicatesTable
    end
end
--local checkIfUserContextMenuSortOrderValid = FCOIS.CheckIfUserContextMenuSortOrderValid


-- ========================================================================================================================
-- ========================================================================================================================
-- ========================================================================================================================
-- ============================================================
--         Filter button context menu
-- ============================================================

--The filter button's context menu OnMouseEnter event callback function
local function ContextMenuFilterButtonOnMouseEnter(button, contextMenuType, iconId, returnAsText)
    returnAsText = returnAsText or false
    local settings = FCOIS.settingsVars.settings
    local locVars = FCOIS.localizationVars.fcois_loc
    local contMenuVars = FCOIS.contextMenuVars
    local availableCtms = contMenuVars.availableCtms
    local iconSettings = settings.icon

    --Set a tooltip?
    local tooltipText
    if settings.showFilterButtonContextTooltip == true then
        --LockDyn
        if contextMenuType == availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN] then
            if iconId == -1 then
                tooltipText = locVars["button_context_menu_all_markers_tooltip"]
            else
                --One of the dynamic icons was selected?
                if FCOIS.mappingVars.iconIsDynamic[iconId] then
                    tooltipText = iconSettings[iconId].name
                --No dynamic icon selected (like icon 1, the "lock" icon)
                else
                    tooltipText = locVars["filter_lockdyn_" .. tostring(iconId)]
                end
            end
            if tooltipText ~= "" and not returnAsText then
                ZO_Tooltips_ShowTextTooltip(button, LEFT, tooltipText)
            end

        --Gear
        elseif contextMenuType == availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS] then
            if iconId == -1 then
                tooltipText = locVars["button_context_menu_gear_sets_all_tooltip"]
            else
                tooltipText = iconSettings[iconId].name
            end
            if tooltipText ~= "" and not returnAsText then
                ZO_Tooltips_ShowTextTooltip(button, LEFT, tooltipText)
            end


        --ResDecImp
        elseif contextMenuType == availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP] then
            if iconId == -1 then
                tooltipText = locVars["button_context_menu_all_markers_tooltip"]
            else
                tooltipText = locVars["options_icon" .. iconId .. "_color"]
            end
            if tooltipText ~= "" and not returnAsText then
                ZO_Tooltips_ShowTextTooltip(button, LEFT, tooltipText)
            end

        --SellGuildInt
        elseif contextMenuType == availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] then
            if iconId == -1 then
                tooltipText = locVars["button_context_menu_all_markers_tooltip"]
            else
                tooltipText = locVars["options_icon" .. iconId .. "_color"]
            end
            if tooltipText ~= "" and not returnAsText then
                ZO_Tooltips_ShowTextTooltip(button, LEFT, tooltipText)
            end
        end
    else
        ZO_Tooltips_HideTextTooltip()
    end
    if tooltipText ~= "" and returnAsText then
        return tooltipText
    end
end

--The filter button's context menu Onclicked callback function
local function ContextMenuFCOISFilterButtonOnClicked(button, contextMenuType, iconId, filterPanelId)
    if button == nil then return end
    if contextMenuType == nil then return end
    if iconId == nil then return end
    filterPanelId = filterPanelId or FCOIS.gFilterWhere
    local contMenuButtonClickedVars = FCOIS.mappingVars.contextMenuButtonClickedMenuToButton
    local buttonNr = contMenuButtonClickedVars[contextMenuType]
    if buttonNr == nil then return end
    local iconToFilter = FCOIS.mappingVars.iconToFilter
    local lastVars = FCOIS.lastVars

    --Get the contextmenu variables
    local ctmVars = FCOIS.ctmVars[contextMenuType]
    ctmVars.lastIcon[filterPanelId] = iconId

    if FCOIS.settingsVars.settings.debug then debugMessage( "[ContextMenuFilterButtonOnClicked]","ContextMenuType: " .. contextMenuType .. ", clicked button: " .. button:GetName() .. ", IconId: " .. tostring(iconId) .. ", filterPanelId: " .. tostring(filterPanelId), true, FCOIS_DEBUG_DEPTH_NORMAL) end
--d("[FCOIS]ContextMenuFilterButtonOnClicked - ContextMenuType: " .. contextMenuType .. ", clicked button: " .. button:GetName() .. ", buttonNr: " .. tostring(buttonNr) ..", IconId: " .. tostring(iconId) .. ", filterPanelId: " .. tostring(filterPanelId))
    if iconId ~= nil then
        --Update the last filter ID (determined by the used icon) for the correct inventory refresh
        if iconId ~= -1 then
            lastVars.gLastFilterId[filterPanelId] = iconToFilter[iconId]
        else
            lastVars.gLastFilterId[filterPanelId] = -1
        end
        --Update the inventory
        filterBasics()
        --Change the gear sets filter context-menu button's texture
        --FCOIS.UpdateButtonColorsAndTextures(p_buttonId, p_button, p_status, p_filterPanelId)
        FCOIS.UpdateFCOISFilterButtonColorsAndTextures(buttonNr, button, nil, filterPanelId)--FCOIS.gFilterWhere)
    end
end

--Function to check how many marker icons in the context menu are enabled in the settings.
local function getFilterButonContextMenuActiveIcons(contextMenuType)
    if contextMenuType == nil then return nil end
    --Get the contextmenu variables
    -->ctmVars are deifned within the file FCOIS_localization.lua
    local ctmVars = FCOIS.ctmVars[contextMenuType]
    local filterContextMenuButtonTemplate = ctmVars.buttonTemplate
    local filterContextMenuButtonTemplateIndex = ctmVars.buttonTemplateIndex
    local iconsActiveInContextMenu = 0
    local isIconEnabled = FCOIS.settingsVars.settings.isIconEnabled
    for _, buttonNameStr in ipairs(filterContextMenuButtonTemplateIndex) do
        local buttonData = filterContextMenuButtonTemplate[buttonNameStr]
        if buttonData ~= nil and buttonData.iconId ~= nil then
            if isIconEnabled[buttonData.iconId] then
                iconsActiveInContextMenu = iconsActiveInContextMenu + 1
            end
        end
    end
    --Always add 1 to the active icons as the * icon ("all") is always shown!
    return iconsActiveInContextMenu + 1
end

function FCOIS.RebuildFilterButtonContextMenuVars()
--d("[FCOIS] rebuildFilterButtonContextMenuVars")
    --Update the filter buttons context menu vars now
    local invGearFilterBtnEntryHeight = FCOIS.contextMenuVars.GearSetFilter.entryHeight
    local numGearSetsActive = FCOIS.numVars.gFCONumGearSets
    --d("=============================================")
    --The new height is the entry height multiplied by the amount of gear sets active + 1 entry for the * (show all gears enty)
    local newMaxHeight = invGearFilterBtnEntryHeight * (numGearSetsActive + 1)
    --d(">>>>>numGearSetsActive: " ..tostring(numGearSetsActive) .. ", newMaxHeight: " ..tostring(newMaxHeight))
    FCOIS.contextMenuVars.GearSetFilter.maxHeight = newMaxHeight or 144

    --Rebuild the entries in the gear set filter button context menu (* for all gear sets, and then each active gear set = +1 new row)
    FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries = numGearSetsActive + 1 -- Gear sets active + the * context menu entry for "all gear sets"
    --The index of the mapping table for context menu buttons to icon id
    FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex = {}
    for index=1, FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries do
        table.insert(FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex, FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.GearSetFilter.buttonNamePrefix .. index)
    end

    --Change the context menu filter button variables and entries
    --The function FCOIS.showContextMenuFilterButton will loop over filterContextMenuButtonTemplateIndex in ipairs and use data of filterContextMenuButtonTemplate to
    --get the icon and the name etc. and build the dropdown context menu entries. So the variables buttonTemplate and buttonTemplateIndex of the dynamic and the gear icons
    --must be updated now for this function in order to have the correct ordered and enabled icon entries!
    --> The entries of ctmVars.buttonTemplate / ctmVars.buttonTemplateIndex come from the file FCOIS_Localization.lua in function afterLocalization()
    --> and there they come from the variables: ctmVars[ctmName].cmVars.buttonContextMenuToIconId and ctmVars[ctmName].cmVars.buttonContextMenuToIconIdIndex.
    -->These entries again come from the function buildLocalizedFilterButtonContextMenuEntries() in FCOIS_Localization.lua.
    -->
    --Needed context menu variables
    local availableCtms = FCOIS.contextMenuVars.availableCtms
    local ctmVars = FCOIS.ctmVars
    --Now change the contextMenu filter button entries of dynamics: Remove dynamic gear icons
    --Update the array for the LockDyn filter button context menu entries
    FCOIS.contextMenuVars.LockDynFilter.buttonContextMenuToIconId = buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_LOCKDYN)
    --Get the name of the context menu LockDyn
    local ctmName = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN])
    ctmVars[ctmName].cmVars                 = FCOIS.contextMenuVars.LockDynFilter
    ctmVars[ctmName].buttonTemplate 		= ctmVars[ctmName].cmVars.buttonContextMenuToIconId
    ctmVars[ctmName].buttonTemplateIndex 	= ctmVars[ctmName].cmVars.buttonContextMenuToIconIdIndex

    --Now change the contextMenu filter button entries of gear: Add the dynamic gear icons
    --Update the array for the Gear set filter button context menu entries
    --Get the name of the context menu Gear
    FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconId = buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_GEARSETS)
    ctmName = ""
    ctmName = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS])
    ctmVars[ctmName].cmVars                 = FCOIS.contextMenuVars.GearSetFilter
    ctmVars[ctmName].buttonTemplate 		= ctmVars[ctmName].cmVars.buttonContextMenuToIconId
    ctmVars[ctmName].buttonTemplateIndex 	= ctmVars[ctmName].cmVars.buttonContextMenuToIconIdIndex
end

--Function to sort (non)submenu entries for the context menu by help of the custom addon's icon sort order settings
local function sortContextMenuEntries(menuEntriesUnsorted)
    if menuEntriesUnsorted == nil then return menuEntriesUnsorted end
    local settings = FCOIS.settingsVars.settings
    --Check if the icon sort order is valid
    local userOrderValid = true --checkIfUserContextMenuSortOrderValid()
    --If not, reset the icon sort order
    if not userOrderValid then
        resetUserContextMenuSortOrder()
    end
    --Read all submenu entries
    local menuEntriesSorted = {}
    local FCOfilterButtonContextMenu = {}
    local contextMenuEntriesAdded = 0
    local iconStarFound = false
    for iconId, subMenuData in pairs(menuEntriesUnsorted) do
        --Get the sort order of the icon from the settings
        --is the entry the * button with iconid == -1?
        if iconId == -1 then
            iconStarFound = true
            contextMenuEntriesAdded = contextMenuEntriesAdded + 1
        else
            local iconSortOder = settings.icon[iconId].sortOrder
            --Add the sort order to the sorted table now
            if iconSortOder > 0 and iconSortOder <= numFilterIcons then
                --Initialize the context menu entry at the new index
                FCOfilterButtonContextMenu[iconSortOder] = nil
                FCOfilterButtonContextMenu[iconSortOder] = {}
                FCOfilterButtonContextMenu[iconSortOder] = subMenuData
                --Increase the counter for added context menu entries
                contextMenuEntriesAdded = contextMenuEntriesAdded + 1
            end -- if newOrderId > 0 and newOrderId <= numFilterIcons then
        end
    end
    --Add them to the sorted table with the sort order they got from the settings
    if contextMenuEntriesAdded > 0 then
        --Was the * button in the unsorted table? Then add it at first to the sorted table again
        if iconStarFound then
            table.insert(menuEntriesSorted, menuEntriesUnsorted[-1])
        end
        --Check each filter icon in the table (= sort order key)
        for j = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
            --If the sort order is in the table -> Add it to the output table
            if FCOfilterButtonContextMenu[j] ~= nil then
                table.insert(menuEntriesSorted, FCOfilterButtonContextMenu[j])
            end
        end
    end
    return menuEntriesSorted
end

--Function that display the LOCKDYN context menu after the player right-clicks on the FCOIS filter button on the inventory
--or shows the context menu for the GEARs, RESEARCH & DECONSTRUCTION & IMPORVEMENT or SELL & SELL AT GUILD STORE & INTRICATE filter button
function FCOIS.ShowContextMenuAtFCOISFilterButton(parentButton, p_FilterPanelId, contextMenuType)

    p_FilterPanelId = p_FilterPanelId or FCOIS.gFilterWhere
    if parentButton == nil or p_FilterPanelId == nil or p_FilterPanelId == 0 then return end

    if FCOIS.settingsVars.settings.debug then debugMessage( "[showContextMenuFilterButton]","Parent name: " .. parentButton:GetName() .. ", Type: " .. contextMenuType .. ", PanelId: " .. FCOIS.gFilterWhere, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
--d("[FCOIS.showContextMenuFilterButton] Parent name: " .. parentButton:GetName() .. ", Type: " .. contextMenuType .. ", PanelId: " .. FCOIS.gFilterWhere)
--d("[FCOIS]showContextMenuAtFCOISFilterButton - panelId: " ..tostring(p_FilterPanelId))

    local mappingVars = FCOIS.mappingVars

    --Get the settings for the filter button context menu type and check if the context menu is enabled at this filter button
    local contextMenuFilterButtonsTypeToSettings = mappingVars.contextMenuFilterButtonTypeToSettings
    if not contextMenuFilterButtonsTypeToSettings[contextMenuType] then
        --ContextMenu is not enabled at the filterbutton: ABORT here!
        return
    end

    --Get the contextmenu variables
    local ctmVars = FCOIS.ctmVars[contextMenuType]
    local settings = FCOIS.settingsVars.settings
    --local contMenuVars = FCOIS.contextMenuVars
    local isGear = settings.iconIsGear
    local availableCtms = FCOIS.contextMenuVars.availableCtms
    local localizationVars = FCOIS.localizationVars.fcois_loc
    local isGearContextMenuType = (contextMenuType == availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]) or false
    local isLockDynContextMenuType = (contextMenuType == availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]) or false

    --Build the context menu and show it
    local myFont
    if myFont == nil then
        if not IsInGamepadPreferredMode() then
            myFont = "ZoFontGame"
        else
            myFont = "ZoFontGamepad22"
        end
    end

    --Clear the last context menu entries
    ClearMenu()

    --Get the active icon count in the context menu
    local useSubMenu = false
    local activeIconsInCtm = getFilterButonContextMenuActiveIcons(contextMenuType)
    --Are we in the "LockDyn" contextmenu type, and are there more icons in the contextmenu than allowed to show at once?
    --Build a sub-contextmenu for the dynamic icons in the contexmenu
    local setContMaxIcons = settings.filterButtonContextMenuMaxIcons
    if (isLockDynContextMenuType or isGearContextMenuType) and (setContMaxIcons > 0 and activeIconsInCtm > setContMaxIcons) then
        useSubMenu = true
    end

    local subMenuEntriesDynamic = {}
    local subMenuEntriesDynamicGear = {}
    local menuEntriesToSort = {}
    local menuEntriesToShow = {}
    --Loop over the inventory context menu template table and build each button + anchor the following buttons to the ones before.
    --Add them to the table "menuEntriesToSort" and then check the custom sort order and sort them accordingly.
    --After that show the sorted context menu entries
    local filterButtonContextMenuButtonTemplate = ctmVars.buttonTemplate
    local filterButtonContextMenuButtonTemplateIndex = ctmVars.buttonTemplateIndex
    for _, buttonNameStr in ipairs(filterButtonContextMenuButtonTemplateIndex) do
        local buttonData = filterButtonContextMenuButtonTemplate[buttonNameStr]
        local buttonText
        if buttonData ~= nil and (buttonData.iconId ~= nil and (buttonData.iconId == -1 or settings.isIconEnabled[buttonData.iconId])) and ((buttonData.text ~= nil and buttonData.text ~= "") or (buttonData.texture ~= nil and buttonData.texture ~= "")) then
            ---The standard color for the context menu entries
            local colDef = ZO_ColorDef:New(1, 1, 1, 1)
            --The icon which the filter button context menu button affects
            local buttonsIcon = buttonData.iconId
            --Text
            if (buttonData.text ~= nil and buttonData.text ~= "") then
                buttonText = buttonData.text
                --Texture
            elseif (buttonData.texture ~= nil and buttonData.texture ~= "") then
                --Standard width and height for the contextmenu entry textures
                local texWidth, texHeight = 24, 24
                --Check if the texture's size needs to be adjusted (e.g. the coin icon needs to be smaller)
                local updateTextureSizeIndex = settings.icon[buttonsIcon].texture
                local texVars = FCOIS.textureVars
                local texVarsSize = texVars.MARKER_TEXTURES_SIZE
                if texVarsSize[updateTextureSizeIndex] ~= nil and
                        texVarsSize[updateTextureSizeIndex].width ~= nil and texVarsSize[updateTextureSizeIndex].height ~= nil and
                        texVarsSize[updateTextureSizeIndex].width > 0 and texVarsSize[updateTextureSizeIndex].height > 0 then
                    texWidth, texHeight = texVarsSize[updateTextureSizeIndex].width, texVarsSize[updateTextureSizeIndex].height
                end
                --Get the texture string
                local textureString = zo_iconFormatInheritColor(buttonData.texture, texWidth, texHeight)
                --Colorize the texture with the color choosen in the settings
                colDef = ZO_ColorDef:New(settings.icon[buttonsIcon].color)
                buttonText = colDef:Colorize(textureString)
                --Is there an offset inside the context menus for this texture?
                if texVarsSize[updateTextureSizeIndex] ~= nil and texVarsSize[updateTextureSizeIndex].contextMenuOffsetLeft ~= nil and texVarsSize[updateTextureSizeIndex].contextMenuOffsetLeft > 0 then
                    --Add one space width the context menu offsets pixel width
                    buttonText = " |u"..tonumber(texVarsSize[updateTextureSizeIndex].contextMenuOffsetLeft)..":0::|u" .. buttonText
                end
            end
            --Put two spaces before the * character
            if buttonText == "*" then buttonText = "  *" end
            --Show the tooltip of the context menu entry?
            if settings.showFilterButtonContextTooltip == true then
                local tooltipText = ContextMenuFilterButtonOnMouseEnter(parentButton, contextMenuType, buttonsIcon, true)
                if tooltipText ~= nil and tooltipText ~= "" then
                    buttonText = buttonText .. " " .. tooltipText
                end
            else
                --Move the text a bit to the right to make it look like center text aligned
                buttonText = "  " .. buttonText
            end

            --Is the icon a dynamic item?
            local dynamicIcons = mappingVars.iconIsDynamic
            local isDynamic = dynamicIcons[buttonsIcon]
            if isDynamic then
                --Use a submenu for the dynamic entries?
                if useSubMenu then
                    local subMenuEntryDynamic = {
                        label 		    = buttonText,
                        callback 	    = function() ContextMenuFCOISFilterButtonOnClicked(parentButton, contextMenuType, buttonsIcon, p_FilterPanelId) end,
                        myfont          = myFont,
                        normalColor     = colDef,
                        highlightColor  = colDef,
                    }
                    --Is the icon a dynamic gear icon?
                    if isGearContextMenuType and isGear[buttonsIcon] then
                        --table.insert(subMenuEntriesDynamicGear, subMenuEntryDynamic)
                        subMenuEntriesDynamicGear[buttonsIcon] = subMenuEntryDynamic
                    elseif isLockDynContextMenuType then
                        --table.insert(subMenuEntriesDynamic, subMenuEntryDynamic)
                        subMenuEntriesDynamic[buttonsIcon] = subMenuEntryDynamic
                    end
                end
            end
            --Normal icons, or dynamic without submenu
            if not isDynamic or (isDynamic and not useSubMenu) then
                --Add the entry for the context menu now
                --AddCustomMenuItem(mytext, myfunction, itemType, myfont, normalColor, highlightColor, itemYPad)
                --AddCustomMenuItem(buttonText, function() ContextMenuFilterButtonOnClicked(parentButton, contextMenuType, buttonsIcon, p_FilterPanelId) end, MENU_ADD_OPTION_LABEL, myFont, colDef, colDef)
                local menuEntryToSort = {}
                menuEntryToSort.mytext = buttonText
                menuEntryToSort.myfunction = function() ContextMenuFCOISFilterButtonOnClicked(parentButton, contextMenuType, buttonsIcon, p_FilterPanelId) end
                menuEntryToSort.itemType = MENU_ADD_OPTION_LABEL
                menuEntryToSort.myfont = myFont
                menuEntryToSort.normalColor = colDef
                menuEntryToSort.highlightColor = colDef
                menuEntriesToSort[buttonsIcon] = menuEntryToSort
            end
        end -- if buttonNameStr ~= "" and buttonData ~= nil and buttonData.iconId ~= nil and buttonData.mark ~= nil then
    end -- for index, buttonNameStr in ipairs(invContextMenuButtonTemplateIndex) do
    --Sort the normal non-submenu entries now
    menuEntriesToShow = sortContextMenuEntries(menuEntriesToSort)
    --Output the sorted context menu entries now
    if menuEntriesToShow ~= nil then
        for _, menuEntryToShowData in ipairs(menuEntriesToShow) do
            AddCustomMenuItem(menuEntryToShowData.mytext, menuEntryToShowData.myfunction, menuEntryToShowData.itemType, menuEntryToShowData.myfont, menuEntryToShowData.normalColor, menuEntryToShowData.highlightColor)
        end
    end

    --Build a submenu for the dynamic & dynamic gear set icons
    --Dynamic icons submenu
    if useSubMenu then
        --Gear icons or dynamic gear icons?
        if isGearContextMenuType then
            --Sort the dynamic gear submenu entries by the custom sort order
            local subMenuEntriesDynamicGearSorted = sortContextMenuEntries(subMenuEntriesDynamicGear)

            --Add the dynamic gear submenu
            --AddCustomSubMenuItem(mytext, entries, myfont, normalColor, highlightColor, itemYPad)
            AddCustomSubMenuItem("  " .. localizationVars["options_icons_dynamic_gear"], subMenuEntriesDynamicGearSorted, myFont, myColorEnabled, myColorEnabled)

        --Dynamic icons?
        elseif isLockDynContextMenuType then
            --Sort the dynamic gear submenu entries by the custom sort order
            local subMenuEntriesDynamicSorted = sortContextMenuEntries(subMenuEntriesDynamic)

            --Add the dynamic submenu
            --AddCustomSubMenuItem(mytext, entries, myfont, normalColor, highlightColor, itemYPad)
            AddCustomSubMenuItem("  " .. localizationVars["options_icons_dynamic"], subMenuEntriesDynamicSorted, myFont, myColorEnabled, myColorEnabled)
        end
    end
    --Show the context menu now
    ShowMenu(parentButton)
    --Reanchor the menu more to the left and bottom
    reAnchorMenu(zoMenu, -5, -2)
end


--*********************************************************************************************************************************************************************************
--*********************************************************************************************************************************************************************************
--*********************************************************************************************************************************************************************************
-- ========================================================================================================================
-- ========================================================================================================================
-- ========================================================================================================================
-- ============================================================
--         Additional inventory button "flag" context menu
-- ============================================================
--*********************************************************************************************************************************************************************************
--*********************************************************************************************************************************************************************************
--*********************************************************************************************************************************************************************************
--*********************************************************************************************************************************************************************************
--*********************************************************************************************************************************************************************************
--*********************************************************************************************************************************************************************************

--Function to remove slotted but now protected items from the slots of extract/sell/etc. panels and
--update the tooltips of the items to show their new protection state properly
local function removeSlottedProtectedItemsAndUpdateTooltips(settingsStateAfterChange)
    --Check if the protection got enabled again and if any items are shown at the different slots (extract, deconstruct, mail, trade, ...)
    if settingsStateAfterChange == true then
        --Let the function use bagId = nil and slotIndex = nil to automatically find the items at the different slots and remove them if needed
        isItemProtectedAtASlotNow(nil, nil, false, true)
    end
    --Update the tooltips at the items to reflect the protection state properly. But only update the currently visible ones
    --A refresh of the visible scroll list should be enough to refresh the marker icons and tooltips
    filterBasics()
end

--Function to build the additional inventory "flag" context menu entries according to the enabled marker icons and the maximum set dynamic icons
-->Added with FCOIS v1.5.4
function FCOIS.BuildAdditionalInventoryFlagContextMenuData(calledFromFCOISSettings)
    calledFromFCOISSettings = calledFromFCOISSettings or false
    if not calledFromFCOISSettings then return false end

    local buttonNamePrefix = FCOIS.contextMenuVars.buttonNamePrefix
    --The set maximum dynamic icons
    local numDynamicIcons                   = FCOIS.numVars.gFCONumDynamicIcons
    --The entries in the following mapping array. The entry number is needed to anchor the REMOVE_ALL_GEARS button correctly!
    local numNonDynamicAndGearIcons = FCOIS.numVars.gFCONumNonDynamicAndGearIcons --or 12 -- As fallback value: dated 2018-10-03
    local buttonContextMenuToIconIdEntryCount = ((numNonDynamicAndGearIcons)*2) --or 24 -- As fallback value: dated 2018-10-03
    --FCOIS.contextMenuVars.buttonContextMenuToIconIdEntries = 84 --OLD: 44 before additional 20 dynamic icons were added
    FCOIS.contextMenuVars.buttonContextMenuToIconIdEntries = (buttonContextMenuToIconIdEntryCount+(numDynamicIcons*2)) --or 84 -- As fallback value: dated 2018-10-03
    local maxContextMenuEntries = FCOIS.contextMenuVars.buttonContextMenuToIconIdEntries --or 84 -- As fallback value: dated 2018-10-03
    --The tables handling the buttonNames, the anchor buttons, the markerIds etc.
    local contextMenuVars = FCOIS.contextMenuVars
    local buttonContextMenuIcons                = contextMenuVars.buttonContextMenuNonDynamicIcons
    local buttonContextMenuToIconIdTable        = contextMenuVars.buttonContextMenuToIconId
    local buttonContextMenuToIconIdIndexTable   = contextMenuVars.buttonContextMenuToIconIdIndex

    local iconIndex = 1
    for index=1, maxContextMenuEntries do
        --Insert the icon indices
        table.insert(buttonContextMenuToIconIdIndexTable, buttonNamePrefix .. index)

        --Is the current index <= buttonContextMenuToIconIdEntryCount so no dynamic icons will be affected:
        -->Dynamic icons will be added after this loop here!
        if index <= buttonContextMenuToIconIdEntryCount then
            local anchorEntryIndex = index - 1
            if index == 1 then anchorEntryIndex = 1 end
            local entryKey = buttonNamePrefix .. tostring(index)
            local entryData = {}
            local markerIconForContextMenuEntryAtIndex = buttonContextMenuIcons[iconIndex] --icon index of the last icon
            entryData.iconId = markerIconForContextMenuEntryAtIndex
            --index is even, value = false. Else: Value = true
            entryData.mark = true
            if index % 2 == 0 then
                --Only increase the iconIndex if the number is even, so the next icon in next loop will be increased
                iconIndex = iconIndex + 1
                entryData.mark = false
            end
            entryData.anchorButton = buttonNamePrefix .. tostring(anchorEntryIndex)
            if entryKey ~= nil and entryKey ~= "" and entryData ~= nil then
                buttonContextMenuToIconIdTable[entryKey] = entryData
            end
        end
    end
    --Dynamic context menu entries
    if buttonContextMenuToIconIdTable ~= nil then
        --Actual count of context menu entries should be sum of "non-dynamic + gear sets", multiplied by 2 (because of "mark" and "unmark" context menu entries)
        if buttonContextMenuToIconIdEntryCount ~= nil and buttonContextMenuToIconIdEntryCount > 0 and maxContextMenuEntries ~= nil and maxContextMenuEntries > 0 then
            local dynIconCounter = 1
            --Maxmium count of context menu entries should be sum of "non-dynamic + gear sets + dynamic", multiplied by 2 (because of "mark" and "unmark" context menu entries), and subracted 1
            for entryNumber = buttonContextMenuToIconIdEntryCount+1, maxContextMenuEntries do
                local entryKey = buttonNamePrefix .. tostring(entryNumber)
                local entryData = {}
                entryData.iconId = _G["FCOIS_CON_ICON_DYNAMIC_" .. tostring(dynIconCounter)]
                --entryNumber is even, value = false. Else: Value = true
                entryData.mark = true
                if entryNumber % 2 == 0 then
                    --Only increase the counter if the number is even, so the next icon in next loop will be increased
                    dynIconCounter = dynIconCounter + 1
                    entryData.mark = false
                end
                entryData. anchorButton = buttonNamePrefix .. tostring(entryNumber-1)
                if entryKey ~= nil and entryKey ~= "" and entryData ~= nil then
                    buttonContextMenuToIconIdTable[entryKey] = entryData
                end
            end
        end
    end
end


--Function to build the text for the toggle buttons (Anti-Deconstruct, Anti-Destroy, Anti-Sell, etc.)
--The function will return as first parameter the text and as second parameter a boolean value: true if the protective setting for the current panel is enabled, and false if not
function FCOIS.GetContextMenuAntiSettingsTextAndState(p_filterWhere, buildText)
--d("[FCOIS] FCOIS.getContextMenuAntiSettingsTextAndState - filterPanelIdAtCall: " ..tostring(p_filterWhere) .. ", buildText: " ..tostring(buildText))
    if p_filterWhere == nil or p_filterWhere == 0 then p_filterWhere = FCOIS.gFilterWhere end
    if p_filterWhere == nil or p_filterWhere == 0 then return end
    buildText = buildText or false
    local useCraftBagExtendedPanel = false
    local filterPanelToCheck = p_filterWhere

    local settings = FCOIS.settingsVars.settings
    if settings.debug then debugMessage( "[getContextMenuAntiSettingsTextAndState]","PanelId: " .. p_filterWhere .. ", BuildText: " .. tostring(buildText), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

    --Update the Anti-* settings for the panel
    -->TODO 2021--06-23:
    -->As the 2nd param is true this won#t update anything? Just will use p_filterWhere and do nothing with it?
    -->So this can be commented?
    --getFilterWhereBySettings(p_filterWhere, true)

    local currentSettingsState
    local currentSettingsStateDestroy
    if p_filterWhere == LF_CRAFTBAG then
        --As the CraftBag can be active at the mail send, trade, vendor sell, guild store sell and guild bank panels too we need to check if we are currently using the
        --addon CraftBagExtended and if the parent panel ID (FCOIS.gFilterWhereParent) is one of the above mentioned
        -- -> See callback function for CRAFT_BAG_FRAGMENT in the PreHooks section!
        if FCOIS.CheckIfCBEorAGSActive(FCOIS.gFilterWhereParent) then
            filterPanelToCheck = FCOIS.gFilterWhereParent
            useCraftBagExtendedPanel = true
        end
    end
--d(">filterPanelToCheck: " ..tostring(filterPanelToCheck))
    currentSettingsState, currentSettingsStateDestroy = checkIfProtectedSettingsEnabled(filterPanelToCheck, nil, nil, nil, nil)
--d(">currentSettingsState: " ..tostring(currentSettingsState) .. ", currentSettingsStateDestroy: " ..tostring(currentSettingsStateDestroy))
    if not currentSettingsState and currentSettingsStateDestroy ~= nil then
        currentSettingsState = currentSettingsStateDestroy
    end

    --Build the text too?
    local retStrVal = ""
    if buildText then
        --No current settings state? Then return nil, for the text and the state
        if currentSettingsState == nil then
            return nil, nil
        end
        local locVars = FCOIS.localizationVars.fcois_loc
        --Mapping array for the on/off text
        local mappingButtonOnOffText = {
            ["true"]  = "off",
            ["false"] = "on",
        }
        local onOffText = mappingButtonOnOffText[tostring(currentSettingsState)]
        if onOffText ~= "" then
            --Mapping array for the localized button texts
            local mappingButtonText = FCOIS.mappingVars.contextMenuAntiButtonsAtPanel
            local btnText = ""
            --As the CraftBag can be active at the mail send, trade, sell, guild store sell and guild bank panels too we need to check if we are currently using the
            --addon CraftBagExtended and if the parent panel ID (FCOIS.gFilterWhereParent) is one of the above mentioned
            -- -> See callback function for CRAFT_BAG_FRAGMENT in the PreHooks section! File src/FCOIS_hooks.lua, search for "CRAFT_BAG_FRAGMENT"
            if useCraftBagExtendedPanel then
                --Let the context menu button text be the one from the parent panel, and not the currently active (CraftBag) panel
                btnText = mappingButtonText[FCOIS.gFilterWhereParent]
            else
                btnText = mappingButtonText[p_filterWhere]
            end
            if btnText ~= "" then
                btnText = btnText .. onOffText
                if btnText ~= "" then
                    retStrVal = locVars[btnText]
                end
            else
                retStrVal = ""
            end
        end
        if retStrVal == "" then retStrVal = "N/A" end
    end
    return retStrVal, currentSettingsState
end
local getContextMenuAntiSettingsTextAndState = FCOIS.GetContextMenuAntiSettingsTextAndState

--Returns the color for the context menu button if the "anti" settings is enabled or disabled
local function getContextMenuAntiSettingsColor(settingIsEnabled, override)
    override = override or false
    local retCol = {}
    local settings = FCOIS.settingsVars.settings
    if not override and not settings.colorizeFCOISAdditionalInventoriesButton then
        retCol = {
            ["r"] = 1,
            ["g"] = 1,
            ["b"] = 1,
            ["a"] = 1,
        }
    else
        if settingIsEnabled == true then
            retCol = {
                ["r"] = 0,
                ["g"] = 1,
                ["b"] = 0,
                ["a"] = 1,
            }
        elseif settingIsEnabled == false then
            retCol = {
                ["r"] = 1,
                ["g"] = 0,
                ["b"] = 0,
                ["a"] = 1,
            }
        elseif settingIsEnabled == "non_active" then
            retCol = {
                ["r"] = 128/100,
                ["g"] = 128/100,
                ["b"] = 128/100,
                ["a"] = 1,
            }
        end
    end
    return retCol["r"], retCol["g"], retCol["b"], retCol["a"]
end

--Change the context menu invoker button's color by help of the button control and the anti-* settings state, but do not
--change the given invoker button but other buttons also possibly shown at the current button's panel
local function changeContextMenuInvokerButtonColorOfOtherButton(contextMenuInvokerButton, settingsEnabled)
    if not contextMenuInvokerButton then return false end
    local settingStateForColor
    if settingsEnabled == nil then
        settingStateForColor = "non_active"
    else
        settingStateForColor = settingsEnabled
    end
    local colR, colG, colB, colA = getContextMenuAntiSettingsColor(settingStateForColor)
--d("[FCOIS]changeContextMenuInvokerButtonColorOfOtherButton - contextMenuInvokerButton: " .. contextMenuInvokerButton:GetName() .. ", settingsEnabled: " .. tostring(settingsEnabled))

    --Check if the current invoker button's panel got other invoker buttons shown, or similar ones like the character or companion character at the inventory panel
    local updateOtherInvokerButtonsState = contextMenuInvokerButton.buttonData and contextMenuInvokerButton.buttonData.updateOtherInvokerButtonsState
    if updateOtherInvokerButtonsState ~= nil then
        for _, otherInvokerButtonDataToUpdate in pairs(updateOtherInvokerButtonsState) do
            if otherInvokerButtonDataToUpdate.filterPanel ~= nil then
                local goOn = true
                if otherInvokerButtonDataToUpdate.requirementFunc ~= nil then
                    goOn = otherInvokerButtonDataToUpdate.requirementFunc(otherInvokerButtonDataToUpdate)
                end
                if goOn == true then
                    local otherButtonDataName = getContextMenuInvokerButton(otherInvokerButtonDataToUpdate.filterPanel)
                    if otherButtonDataName ~= nil then
                        --Update the other context menu "flag" button's color according to the current settings state
                        local contInvButTexture = wm:GetControlByName(otherButtonDataName, "Texture")
                        if contInvButTexture then
                            contInvButTexture:SetColor(colR, colG, colB, colA)
                        end
                    end
                end
            end
        end
    end
end

--Change the context menu invoker button's color by help of the button control and the anti-* settings state
local function changeContextMenuInvokerButtonColor(contextMenuInvokerButton, settingsEnabled)
    if not contextMenuInvokerButton then return false end
    local settingStateForColor
    if settingsEnabled == nil then
        settingStateForColor = "non_active"
    else
        settingStateForColor = settingsEnabled
    end
--d("[FCOIS]changeContextMenuInvokerButtonColor - contextMenuInvokerButton: " .. contextMenuInvokerButton:GetName() .. ", settingsEnabled: " .. tostring(settingsEnabled))

    --Update the context menu "flag" button's color according to the current settings state
    local colR, colG, colB, colA = getContextMenuAntiSettingsColor(settingStateForColor)
    local contInvButTexture = wm:GetControlByName(contextMenuInvokerButton:GetName(), "Texture")
    if contInvButTexture then
        contInvButTexture:SetColor(colR, colG, colB, colA)
    end
    --Check for other panels also active (FCOIS custom filterPanel Ids like the character), and updte it's protection color as well
    changeContextMenuInvokerButtonColorOfOtherButton(contextMenuInvokerButton, settingsEnabled)
end

--Change the context menu invoker button's color by help of the current panel ID
function FCOIS.ChangeContextMenuInvokerButtonColorByPanelId(panelId)
    panelId = panelId or FCOIS.gFilterWhere
    if FCOIS.settingsVars.settings.debug then debugMessage( "[changeContextMenuInvokerButtonColorByPanelId]","PanelId: " .. panelId, true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end
    if not panelId or panelId == 0 then return false end
    --Change the color of the context menu invoker button now
    --First see if the setitngs for the given panel are enabled or not
    local _, settingsEnabled = getContextMenuAntiSettingsTextAndState(panelId, false)
    local contextMenuInvokerButtonName = getContextMenuInvokerButton(panelId)
    if contextMenuInvokerButtonName ~= "" and contextMenuInvokerButtonName ~= false then
--d("[FCOIS.ChangeContextMenuInvokerButtonColorByPanelId: " .. contextMenuInvokerButtonName .. ", settings: " .. tostring(settingsEnabled))
        local contextMenuInvokerButton = wm:GetControlByName(contextMenuInvokerButtonName, "")
        if contextMenuInvokerButton then
            changeContextMenuInvokerButtonColor(contextMenuInvokerButton, settingsEnabled)
        end
    end
end

--The context menu OnClicked callback function for the additional inventory flag context menu buttons/entries
local function contextMenuForAddInvButtonsOnClicked(buttonCtrl, iconId, doMark, specialButtonType, panelId)
--d("[FCOIS]ContextMenuForAddInvButtonsOnClicked - buttonCtrl: " .. tostring(buttonCtrl:GetName())  .. ", iconId: " .. tostring(iconId)  .. ", doMark: " .. tostring(doMark)  .. ", specialButtonType: " .. tostring(specialButtonType) ..", panelId: " ..tostring(panelId))
    --Table for the allowed special button types, if iconId = nil and doMark = nil
    local settings = FCOIS.settingsVars.settings
    local mappingVars = FCOIS.mappingVars
    local contMenuVars = FCOIS.contextMenuVars

    panelId = panelId or FCOIS.gFilterWhere

    local allowedSpecialButtonTypes = {
        ["quality"]                     = {allowed = true, icon = settings.autoMarkQualityIconNr},
        ["intricate"]                   = {allowed = true, icon = FCOIS_CON_ICON_INTRICATE},
        ["ornate"]                      = {allowed = true, icon = FCOIS_CON_ICON_SELL},
        ["research"]                    = {allowed = true, icon = FCOIS_CON_ICON_RESEARCH},
        ["researchScrolls"]             = {allowed = true, icon = FCOIS_CON_ICON_LOCK},
        ["recipes"]                     = {allowed = true, icon = settings.autoMarkRecipesIconNr},
        ["knownRecipes"]                = {allowed = true, icon = settings.autoMarkKnownRecipesIconNr},
        ["sets"]                        = {allowed = true, icon = settings.autoMarkSetsIconNr},
        ["setItemCollectionsUnknown"]   = {allowed = true, icon = settings.autoMarkSetsItemCollectionBookMissingIcon},
        ["setItemCollectionsKnown"]     = {allowed = true, icon = settings.autoMarkSetsItemCollectionBookNonMissingIcon},
    }

    local isCompanionInventory = false
    --local iconsDisabledAtCompanion = mappingVars.iconIsDisabledAtCompanion
    local isCharacter = (panelId == FCOIS_CON_LF_CHARACTER) or false
    local isCompanionCharacter = (panelId == FCOIS_CON_LF_COMPANION_CHARACTER) or false

    local isUNDOButton 			 		= (specialButtonType == "UNDO") or false
    local isREMOVEALLGEARSButton 		= (specialButtonType == "REMOVE_ALL_GEAR") or false
    local isREMOVEALLButton 	 		= (specialButtonType == "REMOVE_ALL") or false
    local isTOGGLEANTISETTINGSButton	= (specialButtonType == "ANTI_SETTINGS") or false
    local isMARKALLASJUNKButton	        = (specialButtonType == "JUNK_CHECK_ALL") or false
    local isMARKALLASNOJUNKButton	    = (specialButtonType == "UNJUNK_CHECK_ALL") or false

    local atLeastOneMarkerChanged = false
    --Get the filter panel for the undo stuff
    local filterPanelToSaveUndoTo = getUndoFilterPanel(panelId)

    local INVENTORY_TO_SEARCH
    local contextmenuType
    local isSpecialFilterPanel = false
    --==================================================================================================================
    --Special panelIds not provided by LibFilters:
    if type(panelId) == "string" then
        if isCharacter then
            INVENTORY_TO_SEARCH = ctrlVars.CHARACTER
            contextmenuType = "CHARACTER"
            isSpecialFilterPanel = true
        elseif isCompanionCharacter then
            INVENTORY_TO_SEARCH = ctrlVars.COMPANION_CHARACTER
            contextmenuType = "COMPANION_CHARACTER"
            isSpecialFilterPanel = true
        end

    --==================================================================================================================
    else
        --LibFilters panelIds:
        --(Jewelry) Refinement panel?
        if (panelId == LF_SMITHING_REFINE or panelId == LF_JEWELRY_REFINE) then
            INVENTORY_TO_SEARCH = ctrlVars.REFINEMENT
            contextmenuType = "REFINEMENT"
            --(Jewelry) Deconstruction panel?
        elseif (panelId == LF_SMITHING_DECONSTRUCT or panelId == LF_JEWELRY_DECONSTRUCT) then
            INVENTORY_TO_SEARCH = ctrlVars.DECONSTRUCTION
            contextmenuType = "DECONSTRUCTION"
        elseif (panelId == LF_SMITHING_IMPROVEMENT or panelId == LF_JEWELRY_IMPROVEMENT) then
            --(Jewelry) Improvement panel?
            INVENTORY_TO_SEARCH = ctrlVars.IMPROVEMENT
            contextmenuType = "IMPROVEMENT"
        elseif panelId == LF_ENCHANTING_CREATION then
            --Enchanting creation
            INVENTORY_TO_SEARCH = ctrlVars.ENCHANTING_STATION
            contextmenuType = "ENCHANTING CREATION"
        elseif panelId == LF_ENCHANTING_EXTRACTION then
            --Enchanting extraction
            contextmenuType = "ENCHANTING EXTRACTION"
            INVENTORY_TO_SEARCH = ctrlVars.ENCHANTING_STATION
        elseif panelId == LF_RETRAIT then
            --Retrait / Transmutation station
            contextmenuType = "RETRAIT"
            INVENTORY_TO_SEARCH = ctrlVars.RETRAIT_LIST
        elseif panelId == LF_HOUSE_BANK_WITHDRAW then
            --House Banks
            contextmenuType = "HOUSEBANK"
            INVENTORY_TO_SEARCH = ctrlVars.HOUSE_BANK
        elseif panelId == LF_INVENTORY_COMPANION then
            --Companion
            isCompanionInventory = true
            contextmenuType = "COMPANION_INVENTORY"
            INVENTORY_TO_SEARCH = ctrlVars.COMPANION_INV_LIST
        else
            --Inventory (mail, trade, etc.) or bank or craftbag (if other addons enabled the craftbag at mail panel etc.)
            --Get the current inventorytype
            local inventoryType = FCOIS.GetInventoryTypeByFilterPanel(panelId)
            if inventoryType == INVENTORY_CRAFT_BAG then
                contextmenuType = "CRAFTBAG"
            else
                contextmenuType = "INVENTORY"
            end
            --All non-filtered items will be in this list here:
            --ctrlVars.playerInventoryInvs[inventoryType].data[1-28].data   .bagId & ... .slotIndex
            if inventoryType == nil then
                d("[FCOIS] -ERROR- ContextMenuForAddInvButtonsOnClicked - Inventory type for filter panel ID \"" .. panelId .. "\" is not set!")
                return false
            end
            INVENTORY_TO_SEARCH = ctrlVars.playerInventoryInvs[inventoryType].listView
        end
    end
    --==================================================================================================================
    --d("FCOIS]ContextMenuForAddInvButtonsOnClicked - INVENTORY_TO_SEARCH: " .. INVENTORY_TO_SEARCH:GetName() .. ", contextmenuType: " .. contextmenuType)

    --No inventory to search in given? Abort here!
    if INVENTORY_TO_SEARCH == nil then return end
    --Do we need to detect the inventory to search data table, or is it given already?
    --Special filterPanel types like the player or companion inventory needs to build up a table of the worn
    --items first!
    local inventoryData = (not isSpecialFilterPanel and INVENTORY_TO_SEARCH.data) or {}
    if isSpecialFilterPanel == true then
        if isCharacter == true then
            --Get all equipment slots of the currently equipped items: BAG_WORN
            inventoryData = getCharacterBagData(BAG_WORN)
        elseif isCompanionCharacter == true then
            --Get all equipment slots of the currently equipped items of the companion: BAG_COMPANION_WORN
            inventoryData = getCharacterBagData(BAG_COMPANION_WORN)
        end
    end
--FCOIS._AddContextMenuFlagInventory = inventoryData
    if not inventoryData or (inventoryData and #inventoryData == 0) then return end
    --==================================================================================================================
    --==================================================================================================================
    --Are we marking/unmarking items or are we undoing the last change at this current panel?
    if not isUNDOButton and not isREMOVEALLGEARSButton and not isREMOVEALLButton
       and not isTOGGLEANTISETTINGSButton and not isMARKALLASJUNKButton and not isMARKALLASNOJUNKButton then
        --Check if this icon is enabled in the settings, or abort here
        if iconId == nil then
            if specialButtonType ~= nil and allowedSpecialButtonTypes[specialButtonType] ~= nil and allowedSpecialButtonTypes[specialButtonType].icon ~= nil then
                iconId = allowedSpecialButtonTypes[specialButtonType].icon
            end
        end
        if iconId ~= nil then
            if not settings.isIconEnabled[iconId] then return end
        else
            if specialButtonType == nil then return end
        end
        if settings.debug then debugMessage( "[ContextMenuForAddInvButtonsOnClicked]", "Clicked "..contextmenuType.." context menu button, IconId: " .. tostring(iconId) .. ", Mark: " .. tostring(doMark) ..", specialButtonType: " .. tostring(specialButtonType), true, FCOIS_DEBUG_DEPTH_NORMAL) end

        --Check all "currently shown -> non filtered!" items in the given inventory
        if (iconId ~= nil and doMark ~= nil) or (specialButtonType ~= nil and allowedSpecialButtonTypes[specialButtonType].allowed) then
--d(">Checking bag data...")
            --Get the current inventorytype
            --local inventoryType = mappingVars.InvToInventoryType[panelId]
            --All non-filtered items will be in this list here:
            local data
            local bagId
            local slotIndex
            local myItemInstanceId
            local allowedToMark = false
            local undoTableCleared = false
            --The entry of the "Undo" table, stored with the key bag, slotIndex of each changed item
            local undoEntry

            --FCOIS.its = inventoryData
            --d("[FCOIS]ContextMenuForAddInvButtonsOnClicked")
            local doCheckOnlyUnbound = settings.allowOnlyUnbound[iconId]
            --Loop over each not-filtered item data in the current inventory
            for _,v in pairs(inventoryData) do
                --Initialize the "is item markable/researchable" variable
                allowedToMark = true
                --Get the data from current unfiltered inventory item
                -->getSingleBagData created a table where v is the itemData already. There does not exist a "data" subtable!
                data = (not isSpecialFilterPanel and v.data) or v
                if v ~= nil and data ~= nil then
                    --get the bag and slot from current unfiltered inventory item
                    bagId     = data.bagId
                    slotIndex = data.slotIndex
                    if bagId ~= nil and slotIndex ~= nil then
                        --Introduced with FCOIS version 1.0.6
                        --Check if an item is not-bound yet and only allow to mark it if it's unbound
                        --Only ehck if item should be marked!
                        if doMark then
                            local isItemABindableOne = isItemBindableAtAll(bagId, slotIndex) or false
                            --Is the item bindable and already bound, or unbound
                            if doCheckOnlyUnbound and isItemABindableOne then
                                local isBound = isItemBound(bagId, slotIndex) or false
                                --The item is allowed to be marked, if the item is not bound
                                allowedToMark = not isBound
                            end
                        end
                        --Should the item be marked? Then go on with further checks
                        if allowedToMark == true then
                            -- Check if equipment gear 1, 2, 3, 4, 5 or research is possible
                            if iconId ~= nil and mappingVars.iconIsResearchable[iconId] then
                                local wasItemReconstructedOrRetraited = false
                                -- Check if item is researchable (as only researchable items can work as equipment too)
                                allowedToMark, wasItemReconstructedOrRetraited = isItemResearchableNoControl(bagId, slotIndex, iconId)
                                if allowedToMark and wasItemReconstructedOrRetraited == true then
                                    if mappingVars.iconIsBlockedBecauseOfRetrait[iconId] == true then
                                        allowedToMark = false
                                    end
                                end
                            end
                        end
                        if allowedToMark == true then
                            allowedToMark = doCompanionItemChecks(bagId, slotIndex, iconId, isCompanionInventory, false, nil, nil)
                        end
--d("> " .. GetItemLink(bagId, slotIndex) .. ", allowedToMark: " ..tostring(allowedToMark))
                        --Finally: Is the item allowed to be marked with this iconId?
                        if allowedToMark == true then
                            myItemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
                            if myItemInstanceId ~= nil then
                                --Clear the undo table once at the current panelId (keep all other panelIds !)
                                if not undoTableCleared then
                                    contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo] = {}
                                    undoTableCleared = true
                                end
                                --Set the old marker value in the undo table
                                undoEntry = {}
                                undoEntry.bagId = bagId
                                undoEntry.slotIndex = slotIndex
                                undoEntry.iconId = iconId
                                local markerChangedAtBagAndSlot = false
                                --Mark: True
                                if doMark == true then
                                    --Check if the item is not marked already
                                    if not checkIfItemIsProtected(iconId, myItemInstanceId) then
                                        --Check if all icons should be demarked if this icon gets set
                                        local iconShouldDemarkAllOthers = checkIfItemShouldBeDemarked(iconId)
                                        if iconShouldDemarkAllOthers then
                                            --Check if the item is marked with any icon (except the current one)
                                            local isMarked, markedIconsArray = FCOIS.IsMarked(bagId, slotIndex, -1, iconId)
                                            --Add all other removed icons to the undo tab, if they are set
                                            if isMarked then
                                                for iconNr, iconIsMarked in pairs(markedIconsArray) do
                                                    --Check if the icon is set
                                                    --Add the icon to the undo table now
                                                    if iconIsMarked then
                                                        local undoEntryIconsRemoved = {}
                                                        undoEntryIconsRemoved.bagId = bagId
                                                        undoEntryIconsRemoved.slotIndex = slotIndex
                                                        undoEntryIconsRemoved.iconId = iconNr
                                                        table.insert(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo], undoEntryIconsRemoved)
                                                    end
                                                end
                                            end
                                        end
                                        --Check if the sell/sell at guild store icon should be demarked if this icon gets set
                                        local iconShouldDemarkSell = checkIfOtherDemarksSell(iconId)
                                        local iconShouldDemarkDecon = checkIfOtherDemarksDeconstruction(iconId)
                                        if iconShouldDemarkSell == true or iconShouldDemarkDecon == true then
                                            --Get the icons to remove
                                            local iconsToRemove = {}
                                            iconsToRemove = getIconsToRemove(bagId, slotIndex, nil, iconId, iconShouldDemarkSell, iconShouldDemarkDecon)
                                            --Is the item marked with any of the icons that should be removed?
                                            if iconsToRemove ~= nil and FCOIS.IsMarked(bagId, slotIndex, iconsToRemove) then
                                                --For each icon that should be removed, do:
                                                for _, iconToRemove in pairs(iconsToRemove) do
                                                    --Add the icons which will get removed to the undo tab
                                                    --Set the old marker value in the undo table
                                                    local undoEntryIconsRemoved = {}
                                                    undoEntryIconsRemoved.bagId = bagId
                                                    undoEntryIconsRemoved.slotIndex = slotIndex
                                                    undoEntryIconsRemoved.iconId = iconToRemove
                                                    table.insert(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo], undoEntryIconsRemoved)
                                                end
                                            end
                                        end
                                        FCOIS.MarkItem(bagId, slotIndex, iconId, true, false)
                                        --Is the item protected at a craft station or the guild store sell tab now or marked as junk now?
                                        -->Enable 3rd parameter "bulk" for the additional inventory "flag" icon
                                        isItemProtectedAtASlotNow(bagId, slotIndex, true, true)
                                        atLeastOneMarkerChanged = true
                                        markerChangedAtBagAndSlot = true
                                        --Old value: False
                                        undoEntry.marked = false
                                    else
                                    end
                                    --Mark: False
                                elseif doMark == false then
                                    --Check if the item is marked already
                                    if checkIfItemIsProtected(iconId, myItemInstanceId) then
                                        FCOIS.MarkItem(bagId, slotIndex, iconId, false, false)
                                        atLeastOneMarkerChanged = true
                                        markerChangedAtBagAndSlot = true
                                        --Old value: True
                                        undoEntry.marked = true
                                    end
                                    --Mark: nil & specialButtonType is given
                                elseif doMark == nil and specialButtonType ~= nil then
                                    local checksWereDoneLoop, atLeastOneMarkerChangedLoop = false, false
                                    checksWereDoneLoop, atLeastOneMarkerChangedLoop = scanInventoryItemsForAutomaticMarks(bagId, slotIndex, specialButtonType, true)
                                    --Old value:
                                    undoEntry.marked = not atLeastOneMarkerChangedLoop
                                    markerChangedAtBagAndSlot = atLeastOneMarkerChangedLoop
                                    if atLeastOneMarkerChangedLoop then atLeastOneMarkerChanged = true end
                                end
                                --If marker was changed at current bag and slotIndex
                                if markerChangedAtBagAndSlot then
                                    --Set the old marker value in the undo table
                                    table.insert(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo], undoEntry)
                                end
                            end

                        end -- if allowedToMark == true ...
                    end
                end
            end --for _,v in pairs(PLAYER_INV...

        end

    --==================================================================================================================
    --==================================================================================================================
    else -- if not isUNDOButton then ...

    --==================================================================================================================
        --UNDO
        if isUNDOButton then
            --Undo the last change at this panel Id
            if settings.debug then debugMessage( "[ContextMenuForAddInvButtonsOnClicked]", "Clicked "..contextmenuType.." context menu button. Will undo last change at panel " .. tostring(panelId) .. " now!", true, FCOIS_DEBUG_DEPTH_NORMAL) end

            atLeastOneMarkerChanged = false
            --local undoEntry

            --Is there a backup set for the current panelId ?
            if #contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo] > 0 then
                local myItemInstanceId
                local savedVarsMarkedItemsTableName = getSavedVarsMarkedItemsTableName()

                for i=1, #contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo], 1 do
                    if   contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].bagId ~= nil
                            and contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].slotIndex ~= nil
                            and contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].iconId ~= nil
                            and contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].marked ~= nil then

                        --d("[UNDO] slotIndex: " .. tostring(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].slotIndex) .. ", bag: " .. tostring(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].bagId) .. ", iconId: " .. tostring(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].iconId) .. ", marked: " .. tostring(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].marked))
                        myItemInstanceId = myGetItemInstanceIdNoControl(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].bagId, contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].slotIndex, true)
                        if myItemInstanceId ~= nil then
                            --Undo the last changes now
                            FCOIS[savedVarsMarkedItemsTableName][contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].iconId][myItemInstanceId] = contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].marked
                            atLeastOneMarkerChanged = true

                            --Update the undo table with the previous "mark" value so we are able to redo the undo again
                            contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].marked = not contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo][i].marked
                        end

                    end
                end

            end --if contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo] and #contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo] > 0 then

    --==================================================================================================================
        --REMOVE ALL GEARS
        elseif isREMOVEALLGEARSButton then

            if settings.debug then debugMessage( "[ContextMenuForAddInvButtonsOnClicked]", "Clicked "..contextmenuType.." context menu button, Remove ALL GEARS", true, FCOIS_DEBUG_DEPTH_NORMAL) end

            --Get the current inventorytype
            --local inventoryType = mappingVars.InvToInventoryType[panelId]
            --All non-filtered items will be in this list here:
            --ctrlVars.playerInventoryInvs[inventoryType].data[1-28].data   .bagId & ... .slotIndex
            local data
            local bagId
            local slotIndex
            local myItemInstanceId
            local allowedToMark = false
            local undoTableCleared = false
            local undoEntry

            --Loop over each not-filtered item data in the current inventory
            for _,v in pairs(inventoryData) do
                --Initialize the "is item markable/researchable" variable
                allowedToMark = false

                --Get the data from current unfiltered inventory item
                -->getSingleBagData created a table where v is the itemData already. There does not exist a "data" subtable!
                data = (not isSpecialFilterPanel and v.data) or v
                if v ~= nil and data ~= nil then
                    --get the bag and slot from current unfiltered inventory item
                    bagId     = data.bagId
                    slotIndex = data.slotIndex
                    if bagId ~= nil and slotIndex ~= nil then
                        allowedToMark = doCompanionItemChecks(bagId, slotIndex, nil, isCompanionInventory, false, nil, nil)
                        if allowedToMark == true then
                            myItemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
                            if myItemInstanceId ~= nil then

                                --Check all equipment gear icon IDs: 2, 4, 6, 7 and 8
                                --Map the iconIds of the 5 gear sets to the actual counter
                                for iconIdLoop, _ in pairs(mappingVars.iconToGear) do
                                    -- -v- NEW after implementing settings.disableResearchCheck
                                    allowedToMark = isItemResearchableNoControl(bagId, slotIndex, iconIdLoop)
                                    if allowedToMark then
                                        -- -^- NEW after implementing settings.disableResearchCheck

                                        --Check if the item is marked already AND if the icon is enabled in the settings
                                        if checkIfItemIsProtected(iconIdLoop, myItemInstanceId) then

                                            --Clear the undo table once at the current panelId (keep all other panelIds !)
                                            if not undoTableCleared then
                                                contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo] = {}
                                                undoTableCleared = true
                                            end

                                            --d("[REMOVE ALL GEARS] ADD slotIndex: " .. tostring(slotIndex) .. ", bag: " .. tostring(bagId) .. ", iconId: " .. tostring(iconIdLoop) .. ", marked: false")

                                            --Remove the marker for the current gear set item
                                            FCOIS.MarkItem(bagId, slotIndex, iconIdLoop, false, false)

                                            --Set the old marker value in the undo table
                                            undoEntry = {}
                                            undoEntry.bagId = bagId
                                            undoEntry.slotIndex = slotIndex
                                            undoEntry.iconId = iconIdLoop
                                            undoEntry.marked = true
                                            --Set the old marker value in the undo table
                                            table.insert(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo], undoEntry)

                                            atLeastOneMarkerChanged = true
                                        end
                                        -- -v- NEW after implementing settings.disableResearchCheck
                                    end
                                    -- -^- NEW after implementing settings.disableResearchCheck

                                end -- for iconIdLoop, gearId ...
                            end
                        end --if allowedToMark == true then
                    end
                end
            end --for _,v in pairs(PLAYER_INV...

    --==================================================================================================================
        --REMOVE ALL
        elseif isREMOVEALLButton then

            if settings.debug then debugMessage( "[ContextMenuForAddInvButtonsOnClicked]", "Clicked "..contextmenuType.." context menu button, Remove ALL", true, FCOIS_DEBUG_DEPTH_NORMAL) end

            --Get the current inventorytype
            --local inventoryType = mappingVars.InvToInventoryType[panelId]
            --All non-filtered items will be in this list here:
            --ctrlVars.playerInventoryInvs[inventoryType].data[1-28].data   .bagId & ... .slotIndex
            local data
            local bagId
            local slotIndex
            local myItemInstanceId
            local undoTableCleared = false
            local undoEntry
            local allowedToMark = false

            --Loop over each not-filtered item data in the current inventory
            for _,v in pairs(inventoryData) do
                --Get the data from current unfiltered inventory item
                -->getSingleBagData created a table where v is the itemData already. There does not exist a "data" subtable!
                data = (not isSpecialFilterPanel and v.data) or v
                if v ~= nil and data ~= nil then
                    --get the bag and slot from current unfiltered inventory item
                    bagId     = data.bagId
                    slotIndex = data.slotIndex
                    if bagId ~= nil and slotIndex ~= nil then
                        allowedToMark = doCompanionItemChecks(bagId, slotIndex, nil, isCompanionInventory, false, true, nil)
                        if allowedToMark == true then
                            myItemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
                            if myItemInstanceId ~= nil then
                                --Check all icon Ids
                                for iconIdLoop = FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
                                    --Check if the item is marked already AND if the settings for this marker icon is activated
                                    if checkIfItemIsProtected(iconIdLoop, myItemInstanceId) then
                                        --Clear the undo table once at the current panelId (keep all other panelIds !)
                                        if not undoTableCleared then
                                            contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo] = {}
                                            undoTableCleared = true
                                        end

                                        --d("[REMOVE ALL] ADD slotIndex: " .. tostring(slotIndex) .. ", bag: " .. tostring(bagId) .. ", iconId: " .. tostring(iconIdLoop) .. ", marked: false")

                                        --Remove the marker for the current gear set item
                                        FCOIS.MarkItem(bagId, slotIndex, iconIdLoop, false, false)

                                        --Set the old marker value in the undo table
                                        undoEntry = {}
                                        undoEntry.bagId = bagId
                                        undoEntry.slotIndex = slotIndex
                                        undoEntry.iconId = iconIdLoop
                                        undoEntry.marked = true
                                        table.insert(contMenuVars.undoMarkedItems[filterPanelToSaveUndoTo], undoEntry)

                                        atLeastOneMarkerChanged = true
                                    end
                                end -- for iconIdLoop = 1, numFilterIcons, 1 do
                            end
                        end --if allowedToMark == true then
                    end
                end
            end --for _,v in pairs(PLAYER_INV...

    --==================================================================================================================
        -- TOGGLEANTISETTINGS
        elseif isTOGGLEANTISETTINGSButton then

            if settings.debug then debugMessage( "[ContextMenuForAddInvButtonsOnClicked]", "Clicked "..contextmenuType.." context menu button, TOGGLE ANTI SETTINGS", true, FCOIS_DEBUG_DEPTH_NORMAL) end

            --Invert the active anti-setting (false->true / true->false)
            local isSettingEnabledNew = changeAntiSettingsAccordingToFilterPanel()
            local dummy, settingsEnabled
            if isSettingEnabledNew ~= nil then
                --Update the buttons text and get the settings state
                dummy, settingsEnabled = getContextMenuAntiSettingsTextAndState(panelId, false)
            else
                settingsEnabled = nil
            end
            --Change the color of the context menu invoker button now
            if buttonCtrl ~= nil then
                changeContextMenuInvokerButtonColor(buttonCtrl, settingsEnabled)
            end
            --Remove protected items from a slot and update tooltips now
            removeSlottedProtectedItemsAndUpdateTooltips(isSettingEnabledNew)

    --==================================================================================================================
        --Mark all as junk/UNmark all junked
        elseif isMARKALLASJUNKButton or isMARKALLASNOJUNKButton then
            --Get the current inventorytype
            --local inventoryType = mappingVars.InvToInventoryType[panelId]
            --All non-filtered items will be in this list here:
            --ctrlVars.playerInventoryInvs[inventoryType].data[1-28].data   .bagId & ... .slotIndex
            local data
            local bagId
            local slotIndex
            local myItemInstanceId
            local undoTableCleared = false
            local undoEntry

            --Loop over each not-filtered item data in the current inventory
            for _,v in pairs(inventoryData) do
                --Get the data from current unfiltered inventory item
                -->getSingleBagData created a table where v is the itemData already. There does not exist a "data" subtable!
                data = (not isSpecialFilterPanel and v.data) or v
                if v ~= nil and data ~= nil then
                    --get the bag and slot from current unfiltered inventory item
                    bagId     = data.bagId
                    slotIndex = data.slotIndex
                    if bagId ~= nil and slotIndex ~= nil then
                        myItemInstanceId = myGetItemInstanceIdNoControl(bagId, slotIndex)
                        if myItemInstanceId ~= nil then
                            local isProtectedWithIcon = false
                            --Mark all as junk
                            if isMARKALLASJUNKButton then
                                local isMarked, isMarkedWithIconsTable = FCOIS.IsMarked(bagId, slotIndex, -1)
                                if isMarked and isMarkedWithIconsTable ~= nil then
                                    --Check each marked marker icon. If any marker icon is set disallow the junk
                                    for iconNrLoop, isIconMarked in pairs(isMarkedWithIconsTable) do
                                        if isIconMarked then
                                            --Check if the setting to only junk items which are only "marked to be sold" is enabled
                                            if settings.junkItemsMarkedToBeSold and iconNrLoop == FCOIS_CON_ICON_SELL then
                                                --Marked with sell icon and allowed to mark as junk
                                            else
                                                --Marked with any other icon? Disallow junk!
                                                isProtectedWithIcon = true
                                                break -- exit the loop
                                            end
                                        end
                                    end
                                end
                                --Check all icon Ids, if item is protected (only if item should be marked as junk! Not neccessary if item should be removed from junk)
                                if not isProtectedWithIcon then
                                    if settings.debug then debugMessage( "[ContextMenuForAddInvButtonsOnClicked]", "Clicked "..contextmenuType.." context menu button, MARK ALL AS JUNK", true, FCOIS_DEBUG_DEPTH_NORMAL) end
                                    setItemIsJunk(bagId, slotIndex, true)
                                end
                                --UnMark all junk items
                            elseif isMARKALLASNOJUNKButton then
                                --Check if the setting to only unjunk items which are not being "marked to be sold" is enabled
                                if settings.dontUnJunkItemsMarkedToBeSold then
                                    local isMarked, isMarkedWithIconsTable = FCOIS.IsMarked(bagId, slotIndex, -1)
                                    if isMarked and isMarkedWithIconsTable ~= nil then
                                        --Check each marked marker icon. If only the "sell icon" is set disallow the unjunk!
                                        for iconNrLoop, isIconMarked in pairs(isMarkedWithIconsTable) do
                                            if isIconMarked then
                                                --Marked with sell icon? Disallow unjunk
                                                if iconNrLoop == FCOIS_CON_ICON_SELL then
                                                    isProtectedWithIcon = true
                                                    --Marked with any other icon? Allow unjunk
                                                else
                                                    isProtectedWithIcon = false
                                                    break -- exit the loop
                                                end
                                            end
                                        end
                                    end
                                end
                                if not isProtectedWithIcon then
                                    if settings.debug then debugMessage( "[ContextMenuForAddInvButtonsOnClicked]", "Clicked "..contextmenuType.." context menu button, REMOVE ALL FROM JUNK", true, FCOIS_DEBUG_DEPTH_NORMAL) end
                                    setItemIsJunk(bagId, slotIndex, false)
                                end
                            end
                        end
                    end
                end
            end --for _,v in pairs(PLAYER_INV...

        end  -- if isUNDOButton ... elseif ...
    end -- if not isUNDOButton and not isREMOVEALLGEARSButton and not isREMOVEALLButton and not isTOGGLEANTISETTINGSButton then
    --==================================================================================================================
    --==================================================================================================================

    --Did at least one marker change?
    if atLeastOneMarkerChanged == true then
        if isCharacter or isCompanionCharacter then
            refreshEquipmentControl(nil, doMark, iconId)
        end
        --Update the inventory & markers
        filterBasics(false)
    end
end

--Function that is called upon OnMouseUp event on the additional inventory "flag" context menu button's right mouse click to change the protection
function FCOIS.onContextMenuForAddInvButtonsButtonMouseUp(inventoryAdditionalContextMenuInvokerButton, mouseButton, upInside)
--d("[FCOIS]onContextMenuForAddInvButtonsButtonMouseUp, invokerButton: " .. tostring(inventoryAdditionalContextMenuInvokerButton:GetName()))
    if FCOIS.settingsVars.settings.debug then debugMessage( "[onContextMenuForAddInvButtonsButtonMouseUp]","invokerButton: " .. tostring(inventoryAdditionalContextMenuInvokerButton:GetName()) .. ", panelId: " .. tostring(FCOIS.gFilterWhere) .. ", mouseButton: " .. tostring(mouseButton), true, FCOIS_DEBUG_DEPTH_ALL) end
    --Only go on if the context menu is not currently shown
    if not menuVisibleCheck(true, inventoryAdditionalContextMenuInvokerButton) then
        local filterPanel = FCOIS.gFilterWhere
        --Hide the other filter button context menus first
        hideContextMenu(filterPanel)
        --Check if the ANTI-settings are enabled at the current panel
        local _, settingsEnabled = getContextMenuAntiSettingsTextAndState(filterPanel, false)
        if settingsEnabled == nil then
            --Change the additional inventory context menu button's color to the "not active" state
            changeContextMenuInvokerButtonColor(inventoryAdditionalContextMenuInvokerButton, nil)
            return false
        end
        --Invert the active setting (false->true / true->false)
        changeAntiSettingsAccordingToFilterPanel()
        local settingsStateAfterChange = not settingsEnabled
        --Change the additional inventory context menu button's color to the new anti-setting state
        changeContextMenuInvokerButtonColor(inventoryAdditionalContextMenuInvokerButton, settingsStateAfterChange)
        --Update the items slotted and protected and the tooltips
        removeSlottedProtectedItemsAndUpdateTooltips(settingsStateAfterChange)
    end
end

--Function that display the context menu after the player clicks with left mouse button on the additional inventory "flag" button
-- on the top left corner of the inventories (left to the "name" sort header)
function FCOIS.ShowContextMenuForAddInvButtons(invAddContextMenuInvokerButton, buttonDataOfInvokerButton)
    --FCOIS v.0.8.8d
    --Add ZOs ZO_Menu contextMenu entries via addon library libCustomMenu
    local filterPanelIdOfButtonData = buttonDataOfInvokerButton and buttonDataOfInvokerButton.filterPanelId
    local panelId = filterPanelIdOfButtonData
    if panelId == nil then panelId = FCOIS.gFilterWhere end

    local mappingVars = FCOIS.mappingVars
    local localizationVars = FCOIS.localizationVars
    local locContextEntriesVars = localizationVars.contextEntries

    --Is a menu already shown?
    if (GetMenuOwner(invAddContextMenuInvokerButton) and menuVisibleCheck()==true) then
        --Hide the actual contextmenu first
        hideContextMenu(panelId)
    else
        local settings = FCOIS.settingsVars.settings
        --Fallback: Was the localization not done properly?
        if locContextEntriesVars.menu_add_dynamic_text == nil or locContextEntriesVars.menu_remove_dynamic_text == nil
                or locContextEntriesVars.menu_add_all_text == nil or locContextEntriesVars.menu_remove_all_text == nil then
            FCOIS.preventerVars.KeyBindingTexts = false
            FCOIS.preventerVars.gLocalizationDone = false
            --d("[FCOIS]showContextMenuForAddInvButtons -> Localization fix")
            FCOIS.Localization()
        end
        local locVars = localizationVars.fcois_loc

        local _, countDynIconsEnabled = FCOIS.countMarkerIconsEnabled()
        local useDynSubMenu = (settings.useDynSubMenuMaxCount > 0 and countDynIconsEnabled >= settings.useDynSubMenuMaxCount) or false
        local icon2Gear = mappingVars.iconToGear
        local icon2Dynamic = mappingVars.iconToDynamic
        --local isIconGear	= mappingVars.iconIsGear
        local isIconGear = settings.iconIsGear
        local isIconDynamic = mappingVars.iconIsDynamic
        local iconsDisabledAtCompanionInv = mappingVars.iconIsDisabledAtCompanion
        local sortAddInvFlagContextMenu = settings.sortIconsInAdditionalInvFlagContextMenu
        local contextMenuVars = FCOIS.contextMenuVars
        local isCompanionSupportedPanel = mappingVars.isCompanionSupportedPanel

        local isCompanionInventory = (panelId == LF_INVENTORY_COMPANION)
                or (isCompanionSupportedPanel[panelId] and doesPlayerInventoryCurrentFilterEqualCompanion(panelId)) or false
        local isCharacter = (panelId == FCOIS_CON_LF_CHARACTER) or false
        local isCompanionCharacter = (panelId == FCOIS_CON_LF_COMPANION_CHARACTER) or false
        --d("[FCOIS]showContextMenuForAddInvButtons, countDynIconsEnabled: " ..tostring(countDynIconsEnabled) .. ", useDynSubMenu: " ..tostring(useDynSubMenu) .. ", sortAddInvFlagContextMenu: " ..tostring(sortAddInvFlagContextMenu))

        local parentName = invAddContextMenuInvokerButton:GetParent():GetName()
        local myFont
        if myFont == nil then
            if not IsInGamepadPreferredMode() then
                myFont = "ZoFontGame"
            else
                myFont = "ZoFontGamepad22"
            end
        end

        if settings.debug then debugMessage( "[showContextMenuForAddInvButtons]","invokerButton: " .. tostring(invAddContextMenuInvokerButton:GetName()) .. ", parentName: " .. tostring(parentName) .. ", panelId: " .. tostring(panelId), true, FCOIS_DEBUG_DEPTH_ALL) end

        --Clear the last context menu entries
        ClearMenu()

        --Add the new entries
        --Dynamic entries first
        local textPrefix = {
            ["nil"]   = "",
            ["true"]  = "+ ",
            ["false"] = "- ",
        }
        local subMenuEntriesGear = {}
        local subMenuEntriesDynamic = {}
        local subMenuEntriesDynamicAdd = {}
        local subMenuEntriesDynamicRemove = {}
        local subMenuEntriesAutomaticMarking = {}

        --The inventory additional flag context menu invoker button
        local btnCtrlName = contextMenuVars.filterPanelIdToContextMenuButtonInvoker[panelId].name
        local btnCtrl
        if btnCtrlName ~= nil and btnCtrlName ~= "" then
            btnCtrl = wm:GetControlByName(btnCtrlName, "")
        end
        --Loop over the inventory context menu template table and build each button + anchor the following buttons to the ones before
        local invContextMenuButtonTemplate = contextMenuVars.buttonContextMenuToIconId
        local invContextMenuButtonTemplateIndex = contextMenuVars.buttonContextMenuToIconIdIndex
        local gearAdded = false
        local dynamicAdded = false
        local otherAdded = false

        --Is the sorting enabled then check the sort order and reset it if not valid
        if sortAddInvFlagContextMenu then
            --if not checkIfUserContextMenuSortOrderValid() then resetUserContextMenuSortOrder() end
        end
        local maxNewOrderId = 0
        local contextMenuEntriesAdded = 0
        local FCOAddInvFlagButtonContextMenuWithKeyGap = {}
        local FCOAddInvFlagButtonContextMenu = {}
        --For each icon check if it is enabled and then add an entry to internal tables.
        --Check if the entries should be sorted and then add them in the chosen sort order (settings) order.
        --This internal tables will be added to the context menus afterwards
        for index, buttonNameStr in ipairs(invContextMenuButtonTemplateIndex) do
            local buttonData = invContextMenuButtonTemplate[buttonNameStr]
            local newOrderId = 0
            if buttonData ~= nil then
                local buttonsIcon = buttonData.iconId
                if (buttonsIcon ~= nil and settings.isIconEnabled[buttonsIcon]) and buttonData.mark ~= nil then
                    local isIconDisabledAtCompanionInv = ((isCompanionInventory == true or isCompanionCharacter == true) and iconsDisabledAtCompanionInv[buttonsIcon] == true) or false
                    if not isIconDisabledAtCompanionInv then
                        --The icon which the button affects -> Gets the text that should be displayed
                        local isGear	= isIconGear[buttonsIcon]
                        local isDynamic = isIconDynamic[buttonsIcon]
                        --Use the custom sort order as it is valid, or do not sort and use the iconId instead as sortIndex
                        if sortAddInvFlagContextMenu then
                            newOrderId = settings.icon[buttonsIcon].sortOrder
                        else
                            newOrderId = buttonsIcon
                        end
                        if newOrderId > 0 and newOrderId <= numFilterIcons then
                            --Initialize the context menu entry at the new index
                            --Entry could be one for "mark" (+) and one for "unmark" (-) so the table needs to be kept if it already exists
                            FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId] = FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId] or {}
                            --Add subtable for mark (1=true) and unmark (0=false)
                            local trueOrFalseInteger = -1
                            if buttonData.mark == true then
                                trueOrFalseInteger = 1
                            elseif buttonData.mark == false then
                                trueOrFalseInteger = 0
                            end
                            if trueOrFalseInteger > -1 then
                                FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId][trueOrFalseInteger] = {}
                                --Is the current control an equipment control?
                                FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId][trueOrFalseInteger].index	        = index
                                FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId][trueOrFalseInteger].iconId	        = buttonsIcon
                                FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId][trueOrFalseInteger].isGear         = isGear
                                FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId][trueOrFalseInteger].isDynamic      = isDynamic
                                FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId][trueOrFalseInteger].buttonData     = buttonData
                                FCOAddInvFlagButtonContextMenuWithKeyGap[newOrderId][trueOrFalseInteger].buttonNameStr  = buttonNameStr
                                --Increase the counter for added context menu entries
                                contextMenuEntriesAdded = contextMenuEntriesAdded + 1
                                --Remember the maximum sortOrder id
                                if newOrderId > 0 and newOrderId > maxNewOrderId then maxNewOrderId = newOrderId end
                            end
                        end
                    end --if not isIconDisabledAtCompanionInv then
                end -- if buttonNameStr ~= "" and buttonData ~= nil and buttonData.iconId ~= nil and buttonData.mark ~= nil then
            end
        end -- for index, buttonNameStr in ipairs(invContextMenuButtonTemplateIndex) do
        --As the table FCOAddInvFlagButtonContextMenu could contain entries with "gaps" as key (icons could be disabled and therefor "skipped")
        --we need to rearrange the table key to be a non-gap integer value
        if maxNewOrderId <= 0 or FCOAddInvFlagButtonContextMenuWithKeyGap[maxNewOrderId] == nil then return end
        local tableKeyNonGap = 1
        for tableIndexWithGap=1, maxNewOrderId, 1 do
            if FCOAddInvFlagButtonContextMenuWithKeyGap[tableIndexWithGap] ~= nil then
                FCOAddInvFlagButtonContextMenu[tableKeyNonGap] = FCOAddInvFlagButtonContextMenuWithKeyGap[tableIndexWithGap]
                tableKeyNonGap = tableKeyNonGap + 1
            end
        end

        --Added with v1.5.5
        --Sorted table of normal, gear set and dynamic icons must be looped and added to the context menu then
        if FCOAddInvFlagButtonContextMenu ~= nil and #FCOAddInvFlagButtonContextMenu > 0 and contextMenuEntriesAdded > 0 then
            ------------------------------------------------------------------------------------------------------------------------
            --Helper function to add the table entries of sorted button data, + and -
            local function addSortedButtonDataTableEntries(sortedButtonData)
                local index         = sortedButtonData.index
                local buttonsIcon   = sortedButtonData.iconId
                local isGear	    = sortedButtonData.isGear
                local isDynamic     = sortedButtonData.isDynamic
                local buttonData    = sortedButtonData.buttonData
                local buttonNameStr = sortedButtonData.buttonNameStr
                local buttonText
                --Does the button set or remove the icon? (mark)
                if buttonData.mark then
                    --Is the icon a gear item?
                    if isGear then
                        --Get the gear number
                        local gearNumber = icon2Gear[buttonsIcon]
                        --Is the buttons text not given? Create it again
                        if not locContextEntriesVars.menu_add_all_gear_text or not locContextEntriesVars.menu_add_all_gear_text[gearNumber] then
                            changeContextMenuEntryTexts(buttonsIcon)
                        end
                        buttonText = locContextEntriesVars.menu_add_all_gear_text[gearNumber]
                        local subMenuEntryGear = {
                            label 		= buttonText,
                            callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, buttonsIcon, buttonData.mark, nil, panelId) end,
                        }
                        table.insert(subMenuEntriesGear, subMenuEntryGear)
                        gearAdded = true
                        --Is the icon a dynamic icon?
                    elseif isDynamic then
                        --Get the dynamic number
                        local dynamicNumber = icon2Dynamic[buttonsIcon]
                        --Is the buttons text not given? Create it again
                        if not locContextEntriesVars.menu_add_dynamic_text or not locContextEntriesVars.menu_add_dynamic_text[dynamicNumber] then
                            changeContextMenuEntryTexts(buttonsIcon)
                        end
                        buttonText = textPrefix[tostring(buttonData.mark)] .. locContextEntriesVars.menu_add_dynamic_text[dynamicNumber]
                        local subMenuEntryDynamic = {
                            label 		= buttonText,
                            callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, buttonsIcon, buttonData.mark, nil, panelId) end,
                        }
                        --Are too many dynamic icons enabled to show them in one context menu?
                        if useDynSubMenu then
                            --Split the one submenu into two, one for + and one for -
                            table.insert(subMenuEntriesDynamicAdd, subMenuEntryDynamic)
                        else
                            table.insert(subMenuEntriesDynamic, subMenuEntryDynamic)
                        end
                        dynamicAdded = true
                        --Normal icons
                    else
                        buttonText = locContextEntriesVars.menu_add_all_text[buttonsIcon]
                    end
                    --Remove the icon (unmark)
                else
                    --Is the icon a gear item?
                    if isGear then
                        --Get the gear number
                        local gearNumber = icon2Gear[buttonsIcon]
                        --Is the buttons text not given? Create it again
                        if not locContextEntriesVars.menu_remove_all_gear_text or not locContextEntriesVars.menu_remove_all_gear_text[gearNumber] then
                            changeContextMenuEntryTexts(buttonsIcon)
                        end
                        buttonText = locContextEntriesVars.menu_remove_all_gear_text[gearNumber]
                        local subMenuEntryGear = {
                            label 		= buttonText,
                            callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, buttonsIcon, buttonData.mark, nil, panelId) end,
                        }
                        table.insert(subMenuEntriesGear, subMenuEntryGear)
                        gearAdded = true
                        --Is the icon a dynamic icon?
                    elseif isDynamic then
                        --Get the dynamic number
                        local dynamicNumber = icon2Dynamic[buttonsIcon]
                        --Is the buttons text not given? Create it again
                        if not locContextEntriesVars.menu_remove_dynamic_text or not locContextEntriesVars.menu_remove_dynamic_text[dynamicNumber] then
                            if GetDisplayName() == "@Baertram" then
                                d("[FCOIS]showContextMenuForAddInvButtons-Dynamic icon: " ..tostring(buttonsIcon).."(" .. tostring(dynamicNumber).."), menu_remove_dynamic_text: " ..tostring(locContextEntriesVars.menu_remove_dynamic_text) .. ", menu_remove_dynamic_text[dynamicNumber]: " ..tostring(locContextEntriesVars.menu_remove_dynamic_text[dynamicNumber]))
                            else
                                changeContextMenuEntryTexts(buttonsIcon)
                            end
                        end
                        buttonText = textPrefix[tostring(buttonData.mark)] .. locContextEntriesVars.menu_remove_dynamic_text[dynamicNumber]
                        local subMenuEntryDynamic = {
                            label 		= buttonText,
                            callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, buttonsIcon, buttonData.mark, nil, panelId) end,
                        }
                        --Are too many dynamic icons enabled to show them in one context menu?
                        if useDynSubMenu then
                            --Split the one submenu into two, one for + and one for -
                            table.insert(subMenuEntriesDynamicRemove, subMenuEntryDynamic)
                        else
                            table.insert(subMenuEntriesDynamic, subMenuEntryDynamic)
                        end
                        dynamicAdded = true
                        --Normal icons
                    else
                        buttonText = locContextEntriesVars.menu_remove_all_text[buttonsIcon]
                    end
                end
                --ERROR Handling
                if buttonText == nil then
                    local errorData = {
                        [1] = index,
                        [2] = buttonNameStr,
                        [3] = buttonData.iconId,
                        [4] = buttonData.mark,
                    }
                    FCOIS.debugErrorMessage2Chat("showContextMenuForAddInvButtons", 1, errorData)
                    return nil
                end
                --is the button's text too long? Then shorten it and show ... at the end
                if strlen(buttonText) > contextMenuVars.maxCharactersInLine then
                    buttonText = strsub(buttonText, 1, contextMenuVars.maxCharactersInLine) .. " ..."
                end
                --Add the non gear and non dynamic icons to the normal menu
                if not isGear and not isDynamic then
                    --Add the entry for the context menu now
                    AddCustomMenuItem(buttonText, function() contextMenuForAddInvButtonsOnClicked(btnCtrl, buttonsIcon, buttonData.mark, nil, panelId) end, MENU_ADD_OPTION_LABEL)
                    otherAdded = true
                end
            end -- function addSortedButtonDataTableEntries()
            ------------------------------------------------------------------------------------------------------------------------
            --Check all entries of the pre-sorted data tabloe and create the context menu entries in the output tables for LibContextMenu now
            for sortOrderId, sortedButtonDataTable in ipairs(FCOAddInvFlagButtonContextMenu) do
                --Check the mark=false and mark=true subtable entries and add them to the sorted output after another.
                --First + mark and then - mark
                if sortedButtonDataTable[1] ~= nil then
                    addSortedButtonDataTableEntries(sortedButtonDataTable[1])
                end
                if sortedButtonDataTable[0] ~= nil then
                    addSortedButtonDataTableEntries(sortedButtonDataTable[0])
                end
            end --for buttonsIcon, sortedButtonData in ipairs(FCOAddInvFlagButtonContextMenu) do
        end -- if contextMenuEntriesAdded > 0 then

        --Static entries at the end
        --Context menu button REMOVE ALL GEARS
        if gearAdded then
            local subMenuEntryGear = {
                label 		= locVars["button_context_menu_remove_all_gears"],
                callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "REMOVE_ALL_GEAR", panelId) end,
            }
            table.insert(subMenuEntriesGear, subMenuEntryGear)
            --Add the gear submenu
            AddCustomSubMenuItem("  " .. locVars["options_icons_gears"], subMenuEntriesGear)
        end

        --Dynamic icons submenu
        if dynamicAdded then
            --Are too many dynamic icons enabled to show them in one context menu?
            if useDynSubMenu then
                --Add the dynamic submenu with + and - entries
                AddCustomSubMenuItem(" + " .. locVars["options_icons_dynamic"], subMenuEntriesDynamicAdd)
                AddCustomSubMenuItem(" - " .. locVars["options_icons_dynamic"], subMenuEntriesDynamicRemove)
            else
                --Add the dynamic submenu with + and - entries
                AddCustomSubMenuItem("  " .. locVars["options_icons_dynamic"], subMenuEntriesDynamic)
            end
        end

        local subMenuEntryAutomaticMarking
        if isCompanionInventory == false and isCompanionCharacter == false then
            --Add submenu for the automatic marking
            --Unknown set collection items
            subMenuEntryAutomaticMarking = {
                label 		= locVars["options_enable_auto_mark_unknown_set_collection_items"],
                callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "setItemCollectionsUnknown", panelId) end,
                disabled	= function() return not settings.autoMarkSetsItemCollectionBook or (settings.autoMarkSetsItemCollectionBookMissingIcon == FCOIS_CON_ICON_NONE or not settings.isIconEnabled[settings.autoMarkSetsItemCollectionBookMissingIcon] == true) end,
            }
            table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
            --Known set collection items
            subMenuEntryAutomaticMarking = {
                label 		= locVars["options_enable_auto_mark_known_set_collection_items"],
                callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "setItemCollectionsKnown", panelId) end,
                disabled	= function() return not settings.autoMarkSetsItemCollectionBook or (settings.autoMarkSetsItemCollectionBookIcon == FCOIS_CON_ICON_NONE or not settings.isIconEnabled[settings.autoMarkSetsItemCollectionBookNonMissingIcon] == true) end,
            }
            table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
            --Sets
            subMenuEntryAutomaticMarking = {
                label 		= locVars["options_enable_auto_mark_sets"],
                callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "sets", panelId) end,
                disabled	= function() return not settings.autoMarkSets or not settings.isIconEnabled[settings.autoMarkSetsIconNr] end,
            }
            table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
            --Ornate
            subMenuEntryAutomaticMarking = {
                label 		= GetString(SI_ITEMTRAITTYPE10),
                callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "ornate", panelId) end,
                disabled	= function() return not settings.autoMarkOrnate or not settings.isIconEnabled[FCOIS_CON_ICON_SELL] end,
            }
            table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
            --Intricate
            subMenuEntryAutomaticMarking = {
                label 		= GetString(SI_ITEMTRAITTYPE9),
                callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "intricate", panelId) end,
                disabled	= function() return not settings.autoMarkIntricate or not settings.isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
            }
            table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
            --Research
            subMenuEntryAutomaticMarking = {
                label 		= GetString(SI_SMITHING_TAB_RESEARCH),
                callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "research", panelId) end,
                disabled	= function() return not settings.autoMarkResearch or not settings.isIconEnabled[FCOIS_CON_ICON_RESEARCH] or (not checkIfResearchAddonUsed() or not checkIfChosenResearchAddonActive(settings.researchAddonUsed)) end,
            }
            table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)

            if isCharacter == false then
                --Research scrolls
                subMenuEntryAutomaticMarking = {
                    label 		= GetString(SI_SMITHING_TAB_RESEARCH) .. " " .. GetString(SI_SPECIALIZEDITEMTYPE105),
                    callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "researchScrolls", panelId) end,
                    disabled	= function() return ((DetailedResearchScrolls == nil or DetailedResearchScrolls.GetWarningLine == nil) or not settings.autoMarkWastedResearchScrolls or not settings.isIconEnabled[FCOIS_CON_ICON_LOCK]) end,
                }
                table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
                --Unknown recipes
                subMenuEntryAutomaticMarking = {
                    label 		= GetString(SI_ITEM_FORMAT_STR_UNKNOWN_RECIPE),
                    callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "recipes", panelId) end,
                    disabled	= function() return not settings.autoMarkRecipes or not checkIfRecipeAddonUsed() or not settings.isIconEnabled[settings.autoMarkRecipesIconNr] end,
                }
                table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
                --Known recipes
                subMenuEntryAutomaticMarking = {
                    label 		= zo_strf(GetString(SI_ITEM_FORMAT_STR_KNOWN_ITEM_TYPE), GetString(SI_ITEMTYPE29)),
                    callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "knownRecipes", panelId) end,
                    disabled	= function() return not settings.autoMarkKnownRecipes or not checkIfRecipeAddonUsed() or not settings.isIconEnabled[settings.autoMarkKnownRecipesIconNr] end,
                }
                table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
            end
        end
        --Quality
        subMenuEntryAutomaticMarking = {
            label 		= locVars["options_enable_auto_mark_quality_items"],
            callback 	= function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "quality", panelId) end,
            disabled	= function() return not settings.autoMarkQuality or settings.autoMarkQuality == 1 or not settings.isIconEnabled[settings.autoMarkQualityIconNr] end,
        }
        table.insert(subMenuEntriesAutomaticMarking, subMenuEntryAutomaticMarking)
        --Add the automatic marking submenu
        AddCustomSubMenuItem("  " .. locVars["options_header_items"], subMenuEntriesAutomaticMarking)

        --Context menu button REMOVE ALL
        if gearAdded or dynamicAdded or otherAdded then
            AddCustomMenuItem("|cFF0000" .. locVars["button_context_menu_demark_all"] .."|r", function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "REMOVE_ALL", panelId) end, MENU_ADD_OPTION_LABEL)
        end

        --Context menu buttons for "Anti-*" settings
        --Get the anti settings text for the current filter panel
        local antiButtonText, _ = getContextMenuAntiSettingsTextAndState(panelId, true)
        --d("[FCOIS.showContextMenuForAddInvButtons]panelId: " ..tostring(panelId))
        if antiButtonText ~= nil and antiButtonText ~= "" then
            AddCustomMenuItem(antiButtonText, function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "ANTI_SETTINGS", panelId) end, MENU_ADD_OPTION_LABEL)
        end

        --Context menu "Add all to junk" or "Remove all from junk" (if on the junk tab in inventories) button
        --> Only for allowed libFilters filterIds LF_*
        local allowedJunkFlagContextMenuFilterPanelIds = FCOIS.checkVars.allowedJunkFlagContextMenuFilterPanelIds
        local allowedJunkContextMenuEntryFilterPanel = allowedJunkFlagContextMenuFilterPanelIds[panelId] or false
        if allowedJunkContextMenuEntryFilterPanel then
            --AddCustomMenuItem(mytext, myfunction, itemType, myfont, normalColor, highlightColor, itemYPad)
            --Check if the currently shown inventory filterType is the "Junk" tab
            local addAllToJunkButtonText = ""
            --Get the currently shown inventory's BAG type
            local activeBagId = FCOIS.GetActiveBagIdByFilterPanelId(panelId)
            if activeBagId ~= nil then
                local activeInvType = FCOIS.GetActiveInventoryTypeByBagId(activeBagId)
                if activeInvType ~= nil then
                    local currentInvFilter = ctrlVars.playerInventoryInvs[activeInvType].currentFilter or nil
                    if currentInvFilter ~= nil then
                        --Where should the context menu entry not be shown, e.g. quest items?
                        local doNotShowJunkAdditionalContextMenuEntryFilterTypes = FCOIS.checkVars.doNotShowJunkAdditionalContextMenuEntryFilterTypes
                        local doNotShowJunkAdditionalContextMenuEntryFilterType = doNotShowJunkAdditionalContextMenuEntryFilterTypes[currentInvFilter] or false
                        if not doNotShowJunkAdditionalContextMenuEntryFilterType then
                            local isJunkTabActive, isJunkTabActiveCheckOne = false
                            if activeBagId == BAG_BACKPACK then
                                isJunkTabActiveCheckOne = HasAnyJunk(activeBagId) or false
                            else
                                isJunkTabActiveCheckOne = true
                            end
                            isJunkTabActive = (isJunkTabActiveCheckOne and currentInvFilter == ITEMFILTERTYPE_JUNK) or false
                            local junkModificator = ""
                            --Is the junk tab shown? Add "Remove all from junk" entry
                            if isJunkTabActive then
                                addAllToJunkButtonText = locVars["button_context_menu_removeAllFromJunk"]
                                junkModificator = "UNJUNK_CHECK_ALL"
                                --No junk tab is shown: Add "Add all to junk" entry
                            else
                                addAllToJunkButtonText = locVars["button_context_menu_addAllToJunk"]
                                junkModificator = "JUNK_CHECK_ALL"
                            end
                            local myColor
                            myColor = myColorEnabled
                            AddCustomMenuItem(addAllToJunkButtonText, function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, junkModificator, panelId) end, MENU_ADD_OPTION_LABEL, myFont, myColor)
                        end
                    end
                end
            end
        end

        --Context menu UNDO button
        --AddCustomMenuItem(mytext, myfunction, itemType, myfont, normalColor, highlightColor, itemYPad)
        local undoButtonText = locVars["button_context_menu_undo"]
        local myColor
        --Is there a backup set for the current panelId ?
        if #contextMenuVars.undoMarkedItems[panelId] > 0 then
            myColor = myColorEnabled
        else
            myColor = myColorDisabled
        end
        AddCustomMenuItem(undoButtonText, function() contextMenuForAddInvButtonsOnClicked(btnCtrl, nil, nil, "UNDO", panelId) end, MENU_ADD_OPTION_LABEL, myFont, myColor)

        --Show the context menu at the clicked invoker button now
        ShowMenu(invAddContextMenuInvokerButton)
        --Reanchor the menu more to the left
        if not isCharacter and not isCompanionCharacter then
            reAnchorMenu(zoMenu, -5, 0)
        end
    end
end



------------------------------------------------------------------------------------------------------------------------
--========= INVENTORY SLOT - SLOT ACTIONs =================================
--AddContextMenuEntry -> SlotAction
--Pre Hook function for adding right click/context menu entries.
--Attention: Will be executed on mouse enter on a slot in inventories
--AND if you open the context menu by a mouse righ-click
--To distinguish these two "events" you can use: if self.m_contextMenuMode == true then
--true: Context-menu is open, false: Only mouse hoevered over the item
function FCOIS.InvContextMenuAddSlotAction(self, actionStringId, ...)
    local settings = FCOIS.settingsVars.settings
    local mappingVars = FCOIS.mappingVars
    --d(">[FCOIS]FCOIS.InvContextMenuAddSlotAction-actionStringId: " ..tostring(actionStringId))
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

    --The current game's SCENE and name (used for determining bank/guild bank deposit)
    local currentScene, currentSceneName = getCurrentSceneInfo()
    local isNewSlot = self.m_inventorySlot ~= FCOIS.preventerVars.lastHoveredInvSlot
    if isNewSlot then
        FCOIS.preventerVars.lastHoveredInvSlot = self.m_inventorySlot
    end
    local parentControl
    local isShowingCharacter = isCharacterShown()
    local isShowingCompanionCharacter = isCompanionCharacterShown()
    --Chracter equipment, or normal slot?
    if isShowingCharacter or isShowingCompanionCharacter then
        parentControl = self.m_inventorySlot
    else
        parentControl = self.m_inventorySlot:GetParent()
    end
    --No parent found? Abort
    if parentControl == nil then return false end
    local parentName = parentControl:GetName()

    local bag, slotIndex = myGetItemDetails(parentControl)
    --is the mouse only hovered over the item or was the right click mouse context menu shown?
    local mouseRightClickDone = self.m_contextMenuMode
    --Hide the inventory button contextMenu if shown and if we right clicked another item
    if mouseRightClickDone == true then
        if settings.debug then debugMessage( "[AddSlotAction]","Parent: " .. parentName .. ", actionStringId: " .. tostring(actionStringId), true, FCOIS_DEBUG_DEPTH_ALL) end
        --Hide the context menu at last active panel
        hideContextMenu(FCOIS.gFilterWhere)

        --Check if the character window is shown
        if isShowingCharacter or isShowingCompanionCharacter then
            --d("[FCOIS]FCOItemSaver_AddSlotAction - Char window shown, Parent: " .. tostring(parentName))
            --Check if the parent control is a character slot
            if mappingVars.characterEquipmentArmorSlots[parentName] or
                    mappingVars.characterEquipmentJewelrySlots[parentName] or
                    mappingVars.characterEquipmentWeaponSlots[parentName] then
                --Hide the PlayerProgressBar so the context menu is shown completely
                if isShowingCharacter then FCOIS.ShowPlayerProgressBar(false) end
                --Hide the CompanionProgressBar so the context menu is shown completely
                if isShowingCompanionCharacter then FCOIS.ShowCompanionProgressBar(false) end
            end
        end
    else
        if isNewSlot then
            if settings.debug then debugMessage( "[AddSlotAction]",">newSlot! Parent: " .. parentName, true, FCOIS_DEBUG_DEPTH_ALL) end
        end
    end

    local callItemSelectionHandler = FCOIS.callItemSelectionHandler

    --Use item?
    if        actionStringId == SI_ITEM_ACTION_USE then
        --Is the item protected with any icon?
        local marked, _ = FCOIS.IsMarked(bag, slotIndex, -1)
        if marked and IsItemUsable(bag, slotIndex) then
            --If mail send or player trade panel is activated
            local isCurrentlyShowingMailSend 	= not ctrlVars.MAIL_SEND.control:IsHidden() and settings.blockSendingByMail
            local isCurrentlyShowingPlayerTrade = not ctrlVars.PLAYER_TRADE.control:IsHidden() and settings.blockTrading
            local isContainerWithAutoLootEnabled= isAutolootContainer(bag, slotIndex) and settings.blockAutoLootContainer
            local isARecipe		 				= isItemType(bag, slotIndex, ITEMTYPE_RECIPE) and settings.blockMarkedRecipes
            local isAStyleMotif					= isItemType(bag, slotIndex, ITEMTYPE_RACIAL_STYLE_MOTIF) and settings.blockMarkedMotifs
            local isAPotion					    = isItemType(bag, slotIndex, ITEMTYPE_POTION) and settings.blockMarkedPotions
            local isAFood					    = isItemType(bag, slotIndex, ITEMTYPE_FOOD) and settings.blockMarkedFood
            --local isARepairKit				  = isItemType(bag, slot, ITEMTYPE_TOOL)
            local isACrownStoreItem             = (isItemType(bag, slotIndex, ITEMTYPE_CROWN_ITEM) or isItemType(bag, slotIndex, ITEMTYPE_CROWN_REPAIR)) and settings.blockCrownStoreItems

            --d("[FCOIS]FCOItemSaver_AddSlotAction - PanelId: " .. tostring(FCOIS.gFilterWhere) .. ", isARecipe: " .. tostring(isARecipe) .. ", isAStyleMotif: " .. tostring(isAStyleMotif) .. ", isAFood: " .. tostring(isAFood))
            --Only if we are in the inventory
            if FCOIS.gFilterWhere == LF_INVENTORY then
                --See if the Anti-settings for the given panel is enabled or not
                local _, invAntiSettingsEnabled = getContextMenuAntiSettingsTextAndState(FCOIS.gFilterWhere, false)
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
            local isSpecialItem = checkIfIsSpecialItem(bag, slotIndex) or false
            return isSpecialItem --Remove the context menu entry for "enchant"
        end

    --Destroy item
    elseif    actionStringId == SI_ITEM_ACTION_DESTROY then

        --Only execute if context menu is visible?
        if mouseRightClickDone == false then
            --remove the context-menu entry for "destroy" (and the keybinding)
            return
        end

        --Abort if parent control cannot be found
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        return destroySelectionHandler(bag, slotIndex, false, parentControl)

    --Add item to crafting station, improvement, enchanting, retrait table
    elseif actionStringId == SI_ITEM_ACTION_ADD_TO_CRAFT or actionStringId == SI_ITEM_ACTION_RESEARCH then --or actionStringId == SI_ITEM_ACTION_ADD_TO_RETRAIT then
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        return FCOIS.callDeconstructionSelectionHandler(bag, slotIndex, false)

        --Trade an item, mark item as junk, attach item to mail, sell item, launder item, add to trading house listing (sell there) or add to crafting station
    elseif actionStringId == SI_ITEM_ACTION_TRADE_ADD
            or actionStringId == SI_ITEM_ACTION_MAIL_ATTACH or actionStringId == SI_ITEM_ACTION_SELL
            or actionStringId == SI_ITEM_ACTION_LAUNDER
            --Anbieten / sell in guild shop
            or actionStringId == SI_TRADING_HOUSE_ADD_ITEM_TO_LISTING then
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
        return callItemSelectionHandler(bag, slotIndex, false, false, false, false, false, false, false)

        --Should the "Junk item" context menu entry be hidden if any marker icon is set?
    elseif actionStringId == SI_ITEM_ACTION_MARK_AS_JUNK and settings.removeMarkAsJunk then
        --Check the marker icons
        local isMarkedJunk, markedWithThisIconsJunk = FCOIS.IsMarked(bag, slotIndex, -1)
        if isMarkedJunk then
            --Allowed to junk if only marked with the junk icon?
            if settings.allowMarkAsJunkForMarkedToBeSold then
                local isJunkContextMenuEntryForbidden = false
                for iconNrJunkMarked, iconJunkIsMarked in pairs(markedWithThisIconsJunk) do
                    if iconJunkIsMarked then
                        if iconNrJunkMarked ~= FCOIS_CON_ICON_SELL then
                            isJunkContextMenuEntryForbidden = true
                            break -- exit the loop
                        end
                    end
                end
                --Hide the context menu entry if any other than the "sell" marker icon is set
                return isJunkContextMenuEntryForbidden
            else
                --Hide the context menu entry as any marker icon is set
                return true
            end
        end

        --Equip
    elseif actionStringId == SI_ITEM_ACTION_EQUIP then
        local isStore = currentSceneName == ctrlVars.vendorSceneName or false
        local isFence = currentScene == FENCE_SCENE or false
        --Or are we in the guild store/trading house?
        local isCurrentlyShowingGuildStore = not ctrlVars.GUILD_STORE:IsHidden()
        --Or are we currently showing the mail send panel?
        local isMailSend = not ctrlVars.MAIL_SEND.control:IsHidden()
        --Or the player2player trade scene is shown?
        local isPlayer2PlayerTrade = not ctrlVars.PLAYER_TRADE.control:IsHidden()
        --Disable the "equip" entry for the above checked panels now so the standard keybind is not the "equip" one
        if isStore or isFence or isCurrentlyShowingGuildStore or isMailSend or isPlayer2PlayerTrade then
            --Is the item protected with any icon?
            local marked, _ = FCOIS.IsMarked(bag, slotIndex, -1)
            if marked then
                --remove the context-menu entry for "equip" (and the keybinding)
                return true
            end
        end

        --Guild bank/Bank deposit
    elseif actionStringId == SI_ITEM_ACTION_BANK_DEPOSIT then
        --Are we at the guild bank and is the protection setting for "non-withdrawable items" enabled?
        if settings.blockGuildBankWithoutWithdraw then
            if (currentSceneName == ctrlVars.guildBankSceneName or currentSceneName == ctrlVars.guildBankGamepadSceneName) then
                local currentGuildBankId = FCOIS.guildBankVars.guildBankId
                if currentGuildBankId == 0 then return true end
                return not checkIfGuildBankWithdrawAllowed(currentGuildBankId)
            end
        end

    --[[
    --Buy (at vendor)
    elseif actionStringId == SI_ITEM_ACTION_BUY or actionStringId == SI_ITEM_ACTION_BUY_MULTIPLE then

    --Buy back (at vendor)
    elseif actionStringId == SI_ITEM_ACTION_BUYBACK then

    --Repair (at vendor)
    elseif actionStringId == SI_ITEM_ACTION_REPAIR then
    ]]

        --CraftBagExtended: Unpack item and add to mail, sell, trade
    elseif FCOIS.otherAddons.craftBagExtendedActive and
            (actionStringId == SI_CBE_CRAFTBAG_MAIL_ATTACH or actionStringId == SI_CBE_CRAFTBAG_SELL_QUANTITY or actionStringId == SI_CBE_CRAFTBAG_TRADE_ADD) then
        --Is item marked with any of the FCOItemSaver icons? Then don't show the actionStringId in the contextmenu
        --  bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
        return callItemSelectionHandler(bag, slotIndex, false, false, false, false, false, false, false)

        --De-comment to show the other slot actions
        --else
        --d("actionStringId: " .. actionStringId .. " = " .. GetString(actionStringId))
    end
end
