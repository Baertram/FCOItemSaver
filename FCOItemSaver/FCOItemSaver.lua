------------------------------------------------------------------
--FCOItemSaver.lua
--Author: Baertram
----------------------------------------------------------
--Check filename FCOIS_API.lua for global API functions!
----------------------------------------------------------
--[[
	Allows you to mark items with an icon so you know that you meant to save it for some reason.
	Prevent items from beeing destroyed/extracted/traded/mailed/deconstructed/improved or sold somehow.
	Including filters on/off/show only marked items inside inventories, crafting stations, banks, guild banks, guild stores, player 2 player trading, sending mail, fence, launder and craftbag
]]


--************************************************************************************************************************
--************************************************************************************************************************
--************************************************************************************************************************
------------------------------------------------------------------
-- [Error/bug & feature messages to check - CHANGELOG since last version] --
---------------------------------------------------------------------
--[ToDo list] --
--____________________________
-- Current max bugs: 53
--____________________________

-- 1) 2019-01-14 - Bugfix - Baertram
--Right clicking an item to show the context menu, and then left clicking somewhere else does not close the context menu on first click, but on 2nd click
-->Todo: Bug within LibCustomMenu -> To be fixed by Votan?

--23) 2019-08-17 Check - Baertram
--Todo: Test if backup/restore is working properly with the "AllAccountsTheSame" settings enabled

--27) 2019-10-10 Bug - Baertram
-- Drag & drop of marked items directly from the CraftBagExtended panel to a mail slot works even if the FCOIS protection is enabled! Same for player2player trade.
--> 2020-02-02: ZOs code does not call the event to lock/unlock items if you drag start/drag stop an item from the guild bank, craftbag panels. Also destroy event is not raised.
--> Asked ZOs for a fix here:  https://www.esoui.com/forums/showthread.php?t=8938

-- 40)  2019-11-04 Bug - Baertram
--lua error message if you use the context menu to destroy an item from inventory:
--[[
EsoUI/Ingame/Inventory/InventorySlot.lua:1060: Attempt to access a private function 'PickupInventoryItem' from insecure code. The callstack became untrusted 1 stack frame(s) from the top.
stack traceback:
EsoUI/Ingame/Inventory/InventorySlot.lua:1060: in function 'ZO_InventorySlot_InitiateDestroyItem'
EsoUI/Ingame/Inventory/InventorySlot.lua:1700: in function 'OnSelect'
EsoUI/Libraries/ZO_ContextMenus/ZO_ContextMenus.lua:453: in function 'ZO_Menu_ClickItem'
ZO_MenuItem1_MouseUp:4: in function '(main chunk)'
]]
--> src/FCOIS_Hooks.lua ->     ZO_PreHookHandler(ctrlVars.BACKPACK_BAG, "OnEffectivelyShown", FCOItemSaver_OnEffectivelyShown) -> FCOItemSaver_OnEffectivelyShown ->  ZO_PreHookHandler(childrenCtrl, "OnMouseUp", function(...)
--> causes the error message!

-- 44) 2019-12-13 Change of code - Baertram
-- Try to use the listView's setupFunction instead of OnEffectivelyShown to register a secureposthook on the OnMouseUp etc. events to the inventory rows

-- 45) 2019-12-29 bug - Baertram
-- SHIFT + right mouse button will restore marker icons on items which got NEW into the inventory or got the same bagId + slotIndex like a before "saved"
-- (via shift+ right mouse) item had. But this item changed it's bagId and slotIndex now or even left the inventory (sold e.g.)
-- So the save should use the itemId/itemInstanceId or uniqueID instead and the restore as well!
--> File FCOIS_MarkerIcons.lua, function FCOIS.checkIfClearOrRestoreAllMarkers()

-- 47) 2019-12-29 bug - Baertram
-- SHIFT +right click directly in guild bank's withdraw row does not work if the inventory was not at least opened once before
-- the guild bank was opened
--> File FCOIS_Hooks.lua, line 1332: ZO_PreHookHandler( ctrlVars.GUILD_BANK_BAG, "OnEffectivelyShown", FCOItemSaver_OnEffectivelyShown ) ->  function FCOItemSaver_OnEffectivelyShown -> function FCOItemSaver_InventoryItem_OnMouseUp
--> GuildBank withdraw: ZO_GuildBankBackpackContents only got child ZO_GuildBankBackpackLandingArea, but not rows if you directly open the guild bank after login/reloadui.
---> Guild bank needs more time to build the rows initially. So we need to wait here until they are build to register the hook!
--> If you switch to the guild bank deposit and back it got the rows then: ZO_GuildBankBackpack1RowN

---------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed]
---------------------------------------------------------------------
--Since last update 1.7.4 - New version: 1.7.5
---------------------------------------------------------------------
--[Fixed]
--#53: API function CallItemSelectionHandler parameter isDragAndDrop moved to the last parameter as intended

--[Added]
--

--[Added on request]
--

--************************************************************************************************************************
--************************************************************************************************************************
--************************************************************************************************************************
------------------------------------------------------------------
--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

-- =====================================================================================================================
--  Gamepad functions
-- =====================================================================================================================
function FCOIS.resetPreventerVariableAfterTime(eventRegisterName, preventerVariableName, newValue, resetAfterTimeMS)
    local eventNameStart = "FCOIS_PreventerVariableReset_"
    if eventRegisterName == nil or eventRegisterName == "" or preventerVariableName == nil or preventerVariableName == "" or resetAfterTimeMS == nil then return end
    local eventName = eventNameStart .. tostring(eventRegisterName)
    EVENT_MANAGER:UnregisterForUpdate(eventName)
    EVENT_MANAGER:RegisterForUpdate(eventName, resetAfterTimeMS, function()
        EVENT_MANAGER:UnregisterForUpdate(eventName)
        if FCOIS.preventerVars == nil or FCOIS.preventerVars[preventerVariableName] == nil then return end
        FCOIS.preventerVars[preventerVariableName] = newValue
    end)
end

--Is the gamepad mode enabled in the ESO settings?
function FCOIS.FCOItemSaver_CheckGamePadMode(showChatOutputOverride)
    showChatOutputOverride = showChatOutputOverride or false
    FCOIS.preventerVars = FCOIS.preventerVars or {}
    --Gamepad enabled?
    if IsInGamepadPreferredMode() then
        --Gamepad enabled but addon AdvancedDisableControllerUI is enabled and is not showing the gamepad mode for the inventory,
        --but the normal inventory
        if FCOIS.checkIfADCUIAndIsNotUsingGamepadMode() then
            return false
        else
            if showChatOutputOverride or FCOIS.preventerVars.noGamePadModeSupportTextOutput == false then
                FCOIS.preventerVars.noGamePadModeSupportTextOutput = true
                --Reset the anti-chat spam variable FCOIS.preventerVars.noGamePadModeSupportTextOutput again after 3 seconds
                FCOIS.resetPreventerVariableAfterTime("noGamePadModeSupportTextOutput", "noGamePadModeSupportTextOutput", false, 3000)
                --Normal gamepad mode is enabled -> Abort with error message "not supported!"
                local noGamepadModeSupportedLanguageTexts = {
                    ["en"]	=	"FCO ItemSaver does not support the gamepad mode! Please change the mode to keyboard at the settings.",
                    ["de"]	=	"FCO ItemSaver unterstützt den Gamepad Modus nicht! Bitte wechsel in den Optionen zum Tastatur Modus.",
                    ["fr"]	=	"FCO ItemSaver ne prend pas en charge le mode de gamepad! S'il vous plaît changer le mode de clavier au niveau des réglages.",
                    ["es"]	=	"FCO ItemSaver no es compatible con el modo de mando de juegos! Por favor, cambie el modo de teclado en la configuración.",
                    ["it"]	=	"FCO ItemSaver non supporta la modalità di gamepad! Si prega di cambiare la modalità di tastiera con le impostazioni.",
                    ["jp"]	=	"FCO ItemSaverはゲームパッドモードをサポートしません！設定でキーボードモードに変更してください。",
                    ["ru"]	=	"FCO ItemSaver нe пoддepживaeт peжим гeймпaдa! Пoжaлуйcтa, cмeнитe в нacтpoйкax peжим нa клaвиaтуpу.",
                }
                local lang = GetCVar("language.2")
                local noGamepadModeSupportedText = noGamepadModeSupportedLanguageTexts[lang] or noGamepadModeSupportedLanguageTexts["en"]
                d(FCOIS.preChatVars.preChatTextRed .. noGamepadModeSupportedText)
            end
            return true
        end
    else
        --Gamepad not enabled
        return false
    end
end

-- =====================================================================================================================
--  Addon initialization
-- =====================================================================================================================
FCOIS.currentlyLoggedInCharName = ""

-- Register the event "addon loaded" for this addon
local function FCOItemSaver_Initialized()
    --Set the event callback functions -> file FCOIS_Events.lua
    FCOIS.setEventCallbackFunctions()
end

--------------------------------------------------------------------------------
--- Call the start function for this addon, so the initialization is done
--------------------------------------------------------------------------------
FCOItemSaver_Initialized()
