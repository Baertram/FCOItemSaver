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
-- Current max bugs: 99
--____________________________

-- 1) 2019-01-14 - Bugfix - Baertram
--Right clicking an item to show the context menu, and then left clicking somewhere else does not close the context menu on first click, but on 2nd click
-->Todo: Bug within LibCustomMenu -> To be fixed by Votan?

--23) 2019-08-17 Check - Baertram
--Todo: Test if backup/restore is working properly with the "AllAccountsTheSame" settings enabled

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

-- 47) 2019-12-29 bug - Baertram
-- SHIFT +right click directly in guild bank's withdraw row does not work if the inventory was not at least opened once before
-- the guild bank was opened
--> File FCOIS_Hooks.lua, line 1332: ZO_PreHookHandler( ctrlVars.GUILD_BANK_BAG, "OnEffectivelyShown", FCOItemSaver_OnEffectivelyShown ) ->  function FCOItemSaver_OnEffectivelyShown -> function FCOItemSaver_InventoryItem_OnMouseUp
--> GuildBank withdraw: ZO_GuildBankBackpackContents only got child ZO_GuildBankBackpackLandingArea, but not rows if you directly open the guild bank after login/reloadui.
---> Guild bank needs more time to build the rows initially. So we need to wait here until they are build to register the hook!
--> If you switch to the guild bank deposit and back it got the rows then: ZO_GuildBankBackpack1RowN

-- 76) 2020-04-12, Baertram
-- Open bank after login and try to remove/add a marker icon via keybind-> Insecure error call
--See addon comments by TagCdog at 2020-04-11
--[[
If in this specific order I mark an item as deconstructable and then try to deposit that same item into the bank, I get this error:

EsoUI/Ingame/Inventory/InventorySlot.lua:736: Attempt to access a private function 'PickupInventoryItem' from insecure code. The callstack became untrusted 1 stack frame(s) from the top.
stack traceback:
EsoUI/Ingame/Inventory/InventorySlot.lua:736: in function 'TryBankItem'
|caaaaaa<Locals> inventorySlot = ud, bag = 1, index = 87, bankingBag = 2, canAlsoBePlacedInSubscriberBank = T </Locals>|r
EsoUI/Ingame/Inventory/InventorySlot.lua:1608: in function 'INDEX_ACTION_CALLBACK'
EsoUI/Ingame/Inventory/InventorySlotActions.lua:96: in function 'ZO_InventorySlotActions:DoPrimaryAction'
|caaaaaa<Locals> self = [table:1]{m_contextMenuMode = F, m_hasActions = T, m_numContextMenuActions = 0}, primaryAction = [table:2]{1 = "Deposit"}, success = T </Locals>|r
EsoUI/Ingame/Inventory/ItemSlotActionController.lua:30: in function 'callback'
EsoUI/Libraries/ZO_KeybindStrip/ZO_KeybindStrip.lua:645: in function 'ZO_KeybindStrip:TryHandlingKeybindDown'
|caaaaaa<Locals> self = [table:3]{allowDefaultExit = T, batchUpdating = F, insertionId = 678}, keybind = "UI_SHORTCUT_PRIMARY", buttonOrEtherealDescriptor = ud, keybindButtonDescriptor = [table:4]{order = 500, alignment = 3, keybind = "UI_SHORTCUT_PRIMARY", addedForSceneName = "bank", handledDown = T} </Locals>|r
(tail call): ?
(tail call): ?
]]

-- 79) 2020-05-28, User m-ree via FCOIS addon panel, bug #2646
-- Open a sealed writ from the inventory will throw an error message:
--1. Login
--2. Open inventory
--3. Choose inventory tab Consumable (or just scroll down in the All)
--4. Either hit E, or double-click, or R-click and select "Use" on a sealed writ
--[[
EsoUI/Ingame/Inventory/InventorySlot.lua:1101: Attempt to access a private function 'UseItem' from insecure code. The callstack became untrusted 1 stack frame(s) from the top.
stack traceback:
EsoUI/Ingame/Inventory/InventorySlot.lua:1101: in function 'TryUseItem'
EsoUI/Ingame/Inventory/InventorySlot.lua:1323: in function '(anonymous)'
(tail call): ?
(tail call): ?
EsoUI/Libraries/ZO_ContextMenus/ZO_ContextMenus.lua:451: in function 'ZO_Menu_ClickItem'
ZO_MenuItem1_MouseUp:4: in function '(main chunk)'
]]



--In progress: 2020-06-17
-- 80) 2020-06-14, Beartram, UniqueIds do not work properly anymore as they are really unique and items with the same itemInstanceId, and everything else also the same,
-- are still unique...
-- For weapons, armor and jewelry: Change all uniqueId checks to check the item's itemLink maybe or at least infos generated from it like level, quality, itemId, trait, style and enchantmentId.


--84) 2020-06-27, Malvarot - Automatic marks Quality will also tag set items "again" if the checkbox "check all other markers" at the quality settings is enabled.
--                           e.g. set item markes get applied and after that quality as well, allthough set item markers were applied already and "check others" should prevent this
--   Order of checking these automatic marks:
--      Sets (wichtig: trait erwünscht > trait egal > trait unerwünscht diese reihenfolge beibehalten),
--      qualität
--      research
--      intricate
--      ornate,
--      Rest (gear). Neu kann bleiben, rest is separat
--      Oder Reihenfolge wählbar für: sets, intricate, ornate, qualität, research
--[[
Also, gestern hab ich folgendes eingestellt:
Automatic Marking -> Set -> automatic set marking: ON
Automatic Marking -> Set -> dynamic mark 4 ("undefined")
Automatic Marking -> Set -> only trait markers: ON
Automatic Marking -> Set -> Trait -> Armor -> infused: ON: gear mark 3 ("good")
Automatic Marking -> Set -> Trait -> Armor -> invigorating: OFF
Automatic Marking -> Quality -> artifact (blau)*: dynamic mark 5** ("new")
Automatic Marking -> Quality -> mark higher quality too: ON
Automatic Marking -> Quality -> check all other markers: ON
* soll eigentlich lila sein, zum testen auf blau da ich keine legendary items hab
** soll eigentlich wie die set items, welche nicht via trait markiert werden, dynamic mark 4 ("undefined") bekommen, aber zum debuggen hab ich es auf 5 ("new") gestellt, damit es sich unterscheiden lässt.

Verhalten:
Grüne Rüstung ohne Set: kein Mark
Grüne Set Rüstung mit invigorating: dynamic mark 4 ("undefined")
Grüne Set Rüstung mit infused: gear mark 3 ("good)
Blaue/Lila Rüstung ohne Set: dynamic mark 5 ("new")

Falsch:
Blaue/Lila Set Rüstung mit invigorating: dynamic mark 4 ("undefined") + dynamic mark 5 ("new")
Blaue/Lila Set Rüstung mit infused: gear mark 3 ("good) + dynamic mark 5 ("new")

Erwartetes Verhalten:
Blaue/Lila Set Rüstung mit invigorating: dynamic mark 4 ("undefined")
Blaue/Lila Set Rüstung mit infused: gear mark 3 ("good)
]]

--#92: 2020-08-10, Baertram     SettingsForAll settings, which save if you are using accountwide, character or allaccountsthesame SavedVariables will get
--     deleted if you delete the "Account wide" settings from the FCOIS settings menu "SavedVariables copy/delete" options submenu!
--     E.g. use "AllAccountsTheSame" in the settings of accounbt @Baertram-> This setting is stored in AccountWide settings @Baertram, version 999.
--     If you delete the account settings for @Baertram now, the chosen settings to sue AllAccountsTheSame gets deleted as well!
--     These SettingsForAll need to migrate and be saved somewhere else, like in a special settings table "FCOItemSaver_Settings_General"!

--#96: 2020-10-12, M-Ree   Trying to change dynamic icon name gives an error (https://www.esoui.com/portal.php?id=136&a=viewbug&bugid=3212)
-- Tested on live NA 2020-10-18 and wa snot able to reproduce this error message. Asked for exact steps by email
--[[
When I try to change the dynamic icon's name, once hitting Enter, I get:
Icon number -- 1, trying to change to "PvP".
Did you change the slider "Max number of dynamic icons" in the settings before you changed the name of the dynamic icon?
Yes, 3 to 5
Did the game do a reloadui at this time automatically?
Yes
Did it finish that reloadui properly or was there some error message, or did your client crash e.g.?
Yes, and the red "wait while stuff is built blah blah" hourglass vanished

choices and choicesTooltips need to have the same size
stack traceback:
[C]: in function 'assert'
user:/AddOns/HarvestMap/Libs/LibAddonMenu-2.0/LibAddonMenu-2.0/controls/dropdown.lua:137: in function 'UpdateChoices'
|caaaaaa<Locals> control = ud, choices = [table:1]{1 = "Lock"}, choicesValues = [table:2]{1 = 1}, choices = [table:1], choicesValues = [table:2],
choicesTooltips = [table:3]{1 = "- No icon -"} </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:289: in function 'updateIconListDropdownEntries'
|caaaaaa<Locals> dropdownCtrlName = "FCOItemSaver_Settings_SetTrack...", updateData = [table:4]{scrollable = T, choices = "standard"},
dropdownCtrl = ud, choices = [table:1], choicesValues = [table:2] </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:1180: in function 'setFunc'
|caaaaaa<Locals> newValue = "1st dynamic" </Locals>|r
user:/AddOns/HarvestMap/Libs/LibAddonMenu-2.0/LibAddonMenu-2.0/controls/editbox.lua:60: in function 'UpdateValue'
|caaaaaa<Locals> control = ud, forceDefault = F, value = "1st dynamic" </Locals>|r
user:/AddOns/HarvestMap/Libs/LibAddonMenu-2.0/LibAddonMenu-2.0/controls/editbox.lua:109: in function '(anonymous)'
|caaaaaa<Locals> self = ud </Locals>|r
[C]: in function 'LoseFocus'
EsoUI/Libraries/Globals/Globals.lua:51: in function 'OnGlobalMouseDown'
|caaaaaa<Locals> event = 65544, button = 1, focusEdit = ud </Locals>|r
]]

--#97: 2020-08-28, Piperman124  Set items get marked with impenetrable icon even though they were marked already before
--Seems if I clear all marks and then run the auto marking for set parts it applies to everything not marked with
--another set part item this way but running it again will add impen to everything even if it's already marked with divines etc.


---------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed]
---------------------------------------------------------------------
--Since last update 1.9.8 - New version: 1.9.9
---------------------------------------------------------------------
--[Fixed]
--#27 Drag & drop of marked items directly from the CraftBagExtended panel to a mail/player trade slot works even if the FCOIS protection is enabled!
--#98 Error message upon opening settings menu saying that LAM could not create a dropdown box of characters if you used SavedVariables containing characterId data from another account
--#99 Drink items are now protected against usage in the inventory, if marked

--[Changed]

--[Added]
-- New settings at dynamic icons: Auto-remove marker icon upon (guild)bank deposit

--[Added on request]


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
    local eventNameStart = FCOIS.preventerVars._prevVarReset --"FCOIS_PreventerVariableReset_"
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
