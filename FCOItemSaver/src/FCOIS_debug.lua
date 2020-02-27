--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end
local preVars = FCOIS.preChatVars
local addonVars = FCOIS.addonVars
--==========================================================================================================================================
--									FCOIS - Debugging
--==========================================================================================================================================

--Create the loggers for the different debug depths via LibDebugLogger
function FCOIS.CreateLoggers()
    if not LibDebugLogger then return end
    FCOIS.loggers = {}
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_NORMAL] = LibDebugLogger(addonVars.gAddonName)
    local loggerBase = FCOIS.loggers[FCOIS_DEBUG_DEPTH_NORMAL]
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_DETAILED] = {}
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_VERY_DETAILED] = {}
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_SPAM] = {}
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_ALL] = {}
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_DETAILED] = loggerBase:Create("DEBUG_DETAILED")
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_VERY_DETAILED] = loggerBase:Create("DEBUG_VERY_DETAILED")
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_SPAM] = loggerBase:Create("DEBUG_SPAM")
    FCOIS.loggers[FCOIS_DEBUG_DEPTH_ALL] = loggerBase:Create("DEBUG_ALL")
end

--Output debug message in chat
function FCOIS.debugMessage(msg_text_header, msg_text, deep, depthNeeded)
    depthNeeded = depthNeeded or FCOIS_DEBUG_DEPTH_ALL
    local settings = FCOIS.settingsVars.settings
    if (deep and not settings.deepDebug) then
        return
    elseif (deep and settings.deepDebug) then
        --Is the debug depth in the settings specified (chat command /fcois ddd <value>)?
        settings.debugDepth = settings.debugDepth or 1
        --If the needed debug depth is lower/equals the settings debug depth the message will be shown
        if depthNeeded > settings.debugDepth then return end
    end
    if (settings.debug == true) then
        if not msg_text_header and not msg_text or (msg_text_header ~= nil and msg_text_header == "") or (msg_text ~= nil and msg_text == "") then return end
        --[[
        logger:Debug("A debug message")
        logger:Info("An", "info", "message") -- multiple arguments are passed through tostring and concatenated with a space in between
        logger:Warn("A %s message: %d", "formatted", 123) -- if the first parameter contains formatting strings, the logger will pass all arguments through string.format instead
        local subLogger = logger:Create("verbose") -- this will create a separate logger with a combined tag "MyAddon/verbose".
        subLogger:SetEnabled(false) -- turn the new logger off
        ]]
        local loggers = FCOIS.loggers
        local loggerBase = loggers[FCOIS_DEBUG_DEPTH_NORMAL]
        if loggerBase then
            if deep == true then
                if loggers[depthNeeded] ~= nil then
                    --A debug message header was given: Create a sublogger for it
                    if msg_text_header and msg_text_header ~= "" then
                        if loggers[depthNeeded][msg_text_header] == nil then
                            loggers[depthNeeded][msg_text_header]:Create(msg_text_header)
                        end
                        loggers[depthNeeded][msg_text_header]:Debug(msg_text)
                    else
                        loggers[depthNeeded]:Debug(msg_text)
                    end
                else
                    loggerBase:Debug(msg_text)
                end
            else
                loggerBase:Debug(msg_text)
            end
        else
            --Use old Chat debugging output
            local msg = msg_text
            local preColor
            if msg_text_header and msg_text_header ~= "" then
                msg = msg_text_header .. msg_text
            end
            if deep == true then
                preColor = preVars.preChatTextBlue
            else
                preColor = preVars.preChatTextGreen
            end
            if msg and msg ~= "" then
                d(preColor .. msg)
            end
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