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
--Check for local speed ups. FCOItemSaver.txt was checked until src/FCOIS_OtherAddons.lua
--____________________________
-- Current max bugs/features/ToDos: 146
--____________________________

------------------------------------------------------------------------------------------------------------------------

-- 76) 2020-04-12, Baertram
-- Open bank after login and try to remove/add a marker icon via keybind-> Insecure error call
--See addon comments by TagCdog at 2020-04-11
--[[
If in this specific order I mark an item as deconstructable and then try to deposit that same item into the bank, I get this error:
Again, it has to be in the bank's deposit tab with these back-to-back actions: Mark as deconstructable via keybind key -> Deposit via 'E' key.
If I hover to any other item and then come back to the deconstructable item there is no error.

EsoUI/Ingame/Inventory/InventorySlot.lua:741: Attempt to access a private function 'PickupInventoryItem' from insecure code. The callstack became untrusted 1 stack frame(s) from the top.
|rstack traceback:
EsoUI/Ingame/Inventory/InventorySlot.lua:741: in function 'TryBankItem'
|caaaaaa<Locals> inventorySlot = ud, bag = 1, index = 45, bankingBag = 2, canAlsoBePlacedInSubscriberBank = T </Locals>|r
EsoUI/Ingame/Inventory/InventorySlot.lua:1641: in function 'INDEX_ACTION_CALLBACK'
EsoUI/Ingame/Inventory/InventorySlotActions.lua:96: in function 'ZO_InventorySlotActions:DoPrimaryAction'
|caaaaaa<Locals> self = [table:1]{m_numContextMenuActions = 0, m_contextMenuMode = F, m_hasActions = T}, primaryAction = [table:2]{1 = "Einlagern"}, success = T </Locals>|r
EsoUI/Ingame/Inventory/ItemSlotActionController.lua:30: in function 'callback'
EsoUI/Libraries/ZO_KeybindStrip/ZO_KeybindStrip.lua:679: in function 'ZO_KeybindStrip:TryHandlingKeybindDown'
|caaaaaa<Locals> self = [table:3]{batchUpdating = F, allowDefaultExit = T, insertionId = 29}, keybind = "UI_SHORTCUT_PRIMARY", buttonOrEtherealDescriptor = ud, keybindButtonDescriptor = [table:4]{addedForSceneName = "bank", keybind = "UI_SHORTCUT_PRIMARY", order = 500, alignment = 3} </Locals>|r
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

--#92: 2020-08-10, Baertram     SettingsForAll settings, which save if you are using accountwide, character or allAccountsTheSame SavedVariables will get
--     deleted if you delete the "Account wide" settings from the FCOIS settings menu "SavedVariables copy/delete" options submenu!
--     E.g. use "AllAccountsTheSame" in the settings of account @Baertram-> This setting is stored in AccountWide settings @Baertram, version 999.
--     If you delete the account settings for @Baertram now, the chosen settings to use AllAccountsTheSame gets deleted as well!
--     These SettingsForAll need to migrate and be saved somewhere else, like in a special settings table "FCOItemSaver_Settings_General"!

--#115: 2021-05-13, Baertram  Reposition the additional inventory "flag" icons at crafting tables: Refine, deconstruction, improvement.
--                            and test if they also fit with AdvancedFilters enabled

--#116: ResearchAssistant: Items won't get marked (red rectangle of RA) at the bank after changing settings/reloadUI
--#129: 2021-06-01: Removing all marker icons via the add. inv. "flag" context menu does not remove companion item's marker icons
--#131: Error message at login:
--[[
user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2445: attempt to index a nil value
stack traceback:
user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2445: in function 'buildAddInvContextMenuFlagButtonsPositionsSubMenu'
|caaaaaa<Locals> addInvFlagButtonsPositionsSubMenu = [table:1]{}, btnname = "Set all equal", btntooltip = "This will set all the addition...", btndata = [table:2]{name = "Set all equal", width = "full", tooltip = "This will set all the addition...", warning = "This will set all the addition...", isDangerous = "true", scrollable = F, type = "button"}, btndisabledFunc = user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2408, btnFunc = user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2411, btncreatedControl = [table:2], sortedAddInvBtnInvokers = [table:3]{}, _ = 27, addInvBtnInvokerData = [table:4]{textureMouseOver = "/esoui/art/ava/tabicon_bg_scor...", name = "ZO_CompanionEquipment_Panel_Ke...", filterPanelId = 39, alignMain = 3, height = 32, textureNormal = "/esoui/art/ava/tabicon_bg_scor...", width = 32, alignBackup = 3, hideButton = T, tooltipAlign = 8, onMouseUpCallbackFunctionMouseButton = 2, textureClicked = "/esoui/art/ava/tabicon_bg_scor...", top = 110, left = -55, sortIndex = 27, addInvButton = T}, filterPanelId = 39, isActiveFilterPanelId = T, addInvFlagButtonsPositionsSubMenuControls = [table:5]{}, ref = "FCOItemSaver_Settings_AddInvFl...", name = "Left:", tooltip = "Left:", data = [table:6]{width = "half", type = "editbox"}, disabledFunc = user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2439, getFunc = user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2440, setFunc = user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2441 </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2485: in function 'FCOIS.BuildAddonMenu'
|caaaaaa<Locals> lsb = [table:7]{EVENT_ENTRY_MOVED = 3, DEFAULT_CATEGORY = "LSBDefCat", EVENT_LEFT_LIST_CLEARED = 4, EVENT_ENTRY_HIGHLIGHTED = 1, EVENT_RIGHT_LIST_CLEARED = 5, EVENT_ENTRY_UNHIGHLIGHTED = 2}, libShifterBoxes = [table:8]{}, srcServer = 1, targServer = 1, srcAcc = 1, targAcc = 1, srcChar = 1, targChar = 1, addonVars = [table:9]{FAQentry = "https://www.esoui.com/portal.p...", gAddonLoaded = F, addonVersionOptions = "2.1.1", authorPortal = "https://www.esoui.com/portal.p...", addonNameMenu = "FCO ItemSaver", addonAuthor = "|cFFFF00Baertram|r", addonNameContextMenuEntry = "     - |c22DD22FCO|r ItemSaver...", website = "https://www.esoui.com/download...", addonNameMenuDisplay = "|t32:32:FCOItemSaver/FCOIS.dds...", addonAuthorDisplayNamePTS = "@Baertram", gAddonNameShort = "FCOIS", addonAuthorDisplayNameNA = "@Baertram", addonVersionOptionsNumber = 2.11, savedVarVersion = 0.1, FAQwebsite = "https://www.esoui.com/portal.p...", gAddonName = "FCOItemSaver", savedVarName = "FCOItemSaver_Settings", gSettingsLoaded = T, feedback = "https://www.esoui.com/portal.p...", gPlayerActivated = F, addonAuthorDisplayNameEU = "@Baertram", donation = "https://www.esoui.com/portal.p..."}, addonFAQentry = "https://www.esoui.com/portal.p...", GridListActivated = F, InventoryGridViewActivated = T, getGridAddonIconSize = user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:372, isIconEnabled = [table:10]{1 = T}, numDynIcons = 15, panelData = [table:11]{name = "FCO ItemSaver", registerForRefresh = T, author = "|cFFFF00Baertram|r", displayName = "|t32:32:FCOItemSaver/FCOIS.dds...", donation = "https://www.esoui.com/portal.p...", website = "https://www.esoui.com/download...", version = "2.1.1", slashCommand = "/fcoiss", registerForDefaults = T, type = "panel"}, FCOSettingsPanel = ud, animation = ud, timeline = ud, apiVersion = 100035 </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_Events.lua:1128: in function 'FCOItemSaver_Loaded'
|caaaaaa<Locals> eventCode = 65536, addOnName = "FCOItemSaver", bagIdsToFilterForInvSingleSlotUpdate = [table:12]{1 = 1} </Locals>|r
]]

--#140: Error message at login -> related to fixed error 131
-->Could not create editbox "Gauche:" FCOItemSaver_LAM
-->Could not create editbox "Haute:" FCOItemSaver_LAM
----> Seems the fixed error message user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2445: attempt to index a nil value is causing this now

--#144, 2021-07-03, wambo (esoui addon comments): Crafting a new item and then trying to craft a rune via CraftStore will show error message
--> Only happens after improvement was done so maybe the EVENT_CRAFTING_END was not unregistered properly and the next event crafting end at the
--> enchanting panel checks the item of improvement then again!
--[[
Ok, found some weird behaviour again.

I crafted a clever alchemist belt, (it got the locked mark via FCOIS, not the ingame one), improved it.
Then I went to the enchanting table to craft a the enchant for it...
But that is prevented by FCOIS telling me "FCOIS Creation/Deconstruction not allowed: Belt of Clever Alchemist"

I removed all marks from the belt - same result.
It mustve been triggered by the creation of that item, bc just before I was crafting a jewel and weapon glyph (also disabled)
I was suspecting it had to do with CraftstoreRune - but it also prevented the Rune Crafted by Dolgubons Lazy Writ Creator.


Creation/Deconstruction not allowed: [|H0:item:72327:369:50:0:0:0:0:0:0:0:0:0:0:0:0:31:1:0:0:10000:0|h|h]hide stack
1. user:/AddOns/LibDebugLogger/Initialization.lua:162: in function 'LogChatMessage'show
2. EsoUI/Libraries/Utility/ZO_Hook.lua:18: in function 'AddDebugMessage'show
3. EsoUI/Libraries/Globals/DebugUtils.lua:7: in function 'EmitMessage'show
4. EsoUI/Libraries/Globals/DebugUtils.lua:43: in function 'd'show
5. user:/AddOns/FCOItemSaver/src/FCOIS_Protection.lua:49: in function 'FCOIS.outputItemProtectedMessage'show
6. user:/AddOns/FCOItemSaver/src/FCOIS_Protection.lua:666: in function 'FCOIS.ItemSelectionHandler'show
7. (tail call): ?
8. (tail call): ?
9. (tail call): ?
10. (tail call): ?
11. (tail call): ?
12. EsoUI/Libraries/Utility/ZO_Hook.lua:18: in function 'CraftEnchantingItem'show
13. user:/AddOns/CraftStoreFixedAndImproved/CraftStore.lua:1674: in function 'CS.RuneCreate'show
14. user:/AddOns/CraftStoreFixedAndImproved/CraftStore.lua:1799: in function '(anonymous)'
]]

--#145, 2021-07-08, demawi, FCOIS esoui comments, ContextMenu at bank get's vanilla items removed if FCOIS, Custom Item Preview and
-- Auto Category are enabled
--TODO Check if the menu's parent is a FCOIS flag invoker button and ONLY then return true!
--> file src/FCOIS_ContextMenu.lua, function FCOIS.hideAdditionalInventoryFlagContextMenu(override) -> menuVisibleCheck
--[[
--Compatibility functions
local function menuVisibleCheck()
    --New: Since API10030 - Typo was removed
    --TODO Check if the menu's parent is a FCOIS flag invoker button and ONLY then return true!
]]

--#146, 2021-07-10, Baertram, SHIFT + right mouse does not work at quickslots (inventory menu)


---------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed]
---------------------------------------------------------------------
--In progress: Since 2021-07-04
--#144


---------------------------------------------------------------------
--Since last update 2.1.8 - New version: 2.1.9 -> Updated 2021-06-??
---------------------------------------------------------------------

--[Fixed]


--[Changed]
--

--[Added]

--[Added on request]


--************************************************************************************************************************
--************************************************************************************************************************
--************************************************************************************************************************
------------------------------------------------------------------
--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local em = EVENT_MANAGER

-- =====================================================================================================================
--  Gamepad functions
-- =====================================================================================================================
function FCOIS.resetPreventerVariableAfterTime(eventRegisterName, preventerVariableName, newValue, resetAfterTimeMS)
    local eventNameStart = FCOIS.preventerVars._prevVarReset --"FCOIS_PreventerVariableReset_"
    if eventRegisterName == nil or eventRegisterName == "" or preventerVariableName == nil or preventerVariableName == "" or resetAfterTimeMS == nil then return end
    local eventName = eventNameStart .. tostring(eventRegisterName)
    em:UnregisterForUpdate(eventName)
    em:RegisterForUpdate(eventName, resetAfterTimeMS, function()
        em:UnregisterForUpdate(eventName)
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
        if FCOIS.CheckIfADCUIAndIsNotUsingGamepadMode() then
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
