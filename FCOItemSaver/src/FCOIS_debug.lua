--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

--==========================================================================================================================================
--									FCOIS - Debugging
--==========================================================================================================================================

--Output debug message in chat
function FCOIS.debugMessage(msg_text, deep, depthNeeded)
    depthNeeded = depthNeeded or FCOIS_DEBUG_DEPTH_ALL
    local settings = FCOIS.settingsVars.settings
    local preVars = FCOIS.preChatVars
--d("[FCOIS.debugMessage] deep: " .. tostring(deep) ..", depthNeeded: " .. tostring(depthNeeded))
    if (deep and not settings.deepDebug) then
        return
    elseif (deep and settings.deepDebug) then
        --Is the debug depth in the settings specified (chat command /fcois ddd <value>)?
        settings.debugDepth = settings.debugDepth or 1
        --If the needed debug depth is lower/equals the settings debug depth the message will be shown
        if depthNeeded > settings.debugDepth then return end
    end
    if (settings.debug == true) then
        if deep then
            --Blue colored "FCOIS" at the start of the string
            d(preVars.preChatTextBlue .. msg_text)
        else
            --Green colored "FCOIS" at the start of the string
            d(preVars.preChatTextGreen .. msg_text)
        end
    end
end

--Debug function to show the current item's (below the mouse) iteminstance id (signed through FCOIS function FCOIS.SignItemId()) in chat
function FCOIS.debugItem(p_bagId, p_slotIndex)
    local bag, slot
    if p_bagId ~= nil and p_slotIndex ~= nil then
        bag		= p_bagId
        slot	= p_slotIndex
    else
        bag, slot = FCOIS.GetBagAndSlotFromControlUnderMouse()
    end
    if bag and slot then
        --local itemName = FCOIS.MyGetItemNameNoControl(bag, slot)
        local itemId = FCOIS.MyGetItemInstanceIdNoControl(bag, slot, true)
        local itemLink = GetItemLink(bag, slot, LINK_STYLE_DEFAULT)
        d("[FCOIS] " .. itemLink .." - bag: " .. tostring(bag) .. ", slot: " .. tostring(slot) .. ", FCOIS_ItemId: " .. tostring(itemId))
        ZO_ChatWindowTextEntryEditBox:SetText("/zgoo FCOIS.markedItems[<iconIdHere>]["..itemId.."]")
    end
end
