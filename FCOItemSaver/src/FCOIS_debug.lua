--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

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

--Show an error message to the chat, using text with placeholders (defined in file Localization/FCOItemSaverLoc.lua, array english["ERROR_MESSAGES"]
--(where english is the language to use).
--errorMessage: The key of the array english["ERROR_MESSAGES"]
--errorId:      The subtable of the array english["ERROR_MESSAGES"][errorMessage] -> english["ERROR_MESSAGES"][errorMessage][errorId)
--errorData:    A table with number key from 1 to n, containing the placeholder replacement texts for the errorMessage within english["ERROR_MESSAGES"][errorMessage][errorId)
--              A placeholder must be defined like this in the errrorText: <<1>> or <<2>> and so on -> To support function zo_strformat
function FCOIS.errorMessage2Chat(errorMessage, errorId, errorData)
    if errorMessage == nil or errorMessage == "" or errorId == nil or type(errorId) ~= "number" or errorData == nil then return nil end
    local preVars           = FCOIS.preChatVars
    local FCOISlocVars      = FCOIS.localizationVars
    local locVars           = FCOISlocVars.fcois_loc
    local errorMessageToLongText = locVars["ERROR_MESSAGES"][errorMessage][errorId] or ""
    if errorMessageToLongText == nil or errorMessageToLongText == "" then return nil end
    local errorMessageWithVariables = ""
    if #errorData == 1 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1])
    elseif #errorData == 2 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[1])
    elseif #errorData == 3 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3])
    elseif #errorData == 4 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3], errorData[4])
    elseif #errorData == 5 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3], errorData[4], errorData[5])
    elseif #errorData == 6 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3], errorData[4], errorData[5], errorData[6])
    elseif #errorData == 7 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3], errorData[4], errorData[5], errorData[6], errorData[7])
    elseif #errorData == 8 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3], errorData[4], errorData[5], errorData[6], errorData[7], errorData[8])
    elseif #errorData == 9 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3], errorData[4], errorData[5], errorData[6], errorData[7], errorData[8], errorData[9])
    elseif #errorData == 10 then
        errorMessageWithVariables = zo_strformat(errorMessageToLongText, errorData[1], errorData[2], errorData[3], errorData[4], errorData[5], errorData[6], errorData[7], errorData[8], errorData[9], errorData[10])
    end
    d(preVars.preChatTextRed .. ">=================== ERROR ===================>")
    d( errorMessageWithVariables)
    d("Please provide this info to @Baertram on the EU Megaserver and/or conact him via PM and/or comment to the FCOItemSaver addon at www.esoui.com.\n" ..
            "You can reach this website via the FCOItemSaver settings menu (at the top of the settings menu is the link to the website). Use chat command /fcoiss to open the settings menu!\nMany thanks.")
    d(preVars.preChatTextRed .. "<=================== ERROR ===================<")
end