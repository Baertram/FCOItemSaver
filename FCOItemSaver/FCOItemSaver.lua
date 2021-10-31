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

--____________________________
-- Current max bugs/features/ToDos: 174
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

--#116: 2021-05-24: ResearchAssistant: Items won't get marked (red rectangle of RA) at the bank after changing settings/reloadUI

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

--#154, 2021-08-16, Baertram, bug: Improving an item does not re-apply the improve icon (if quality below gold)
--#155, 2021-08-17, Baertram, bug: Improving an item does not re-apply the already marked icons

--#170, 2021-10-07, sirinsidiator, bug:
--[[hey. ich hab mit FCOIS seit einer weile das problem, dass ich beim besuch einer crafting station gelockte items sehe, obwohl die eigentlich ausgeblendet wären.
repro:
1) crafting station besuchen
2) crafting station verlassen
3) crafting station sofort wieder öffnen
wenn ich das mache, dann sehe ich alle gelockten items bis ich z.b. auf den refine tab und zurück wechsel
]]

---------------------------------------------------------------------
--[ToDo list] --
--Check for local speed ups. FCOItemSaver.txt was checked until src/FCOIS_Tooltips.lua -> as of 2021-08-18
--#129: 2021-06-01: Removing all marker icons via the add. inv. "flag" context menu does not remove companion item's marker icons
--#156: 2021-08-18, Baertram, bug: Enchanting an item does not re-apply the already marked icons (also consider icons that were saved for the items before? add setting for "Check all others")
--#157: 2021-08-18, Baertram, bug: Character doll ring/weapon marker icons do not update properly (both 2 rings were unequipped via double click or drag and drop: on drag of 1 ring back to the right!!! slot the marker icons do not update, or equip 1 ring to the left and then use double click to equp the 2nd ring to the right slot).
--And if you drag another ring to a slot where a ring was already equipped the marker icons do neither update all!
--#158: 2021-08-18, Baertram, bug: Character doll ring/weapon marker icons do not remove all if SHIFT+right click is used on 1 ring (and the 2nd ring is identical)

--#168: 2021-09-19, Baertram, bug: Refinement smithing is not removing items from slot if marker icon is applied (via context menu or keybind)
--#169: 2021-10-07, Baertram, bug: Refinement smithing/enchanting creation is not filtering the FCOIS filters at first open if AdvancedFilters and FCOCraftFilter are enabled as well
--     (maybe even not without these enabled). Changing to e.g. enchanting extarction and back to creation fixes this?!
--#170: 2021-10-07, sirinsidiator, bug: Crafting station re-opens shows locked items (filters do not seem to apply) until e.g. refine tab was opened, and other tab re-opened
--#174: 2021-10-31, Baertram, bug: If Iventory Insight from Ashes is enabled: Select "All" tab or any tab where items are shown which are on other characters. Find one item on another char
--                                 having any iocn set e.g. "sell". Right click it remove the sell icon, and then set it again. Sometimes the worn items and inventory (maybe all items somehow)
--                                 now show the removed/applied marker icon "sell" on them?!
---------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed]
---------------------------------------------------------------------
--In progress: Updated last 2021-10-25

---------------------------------------------------------------------
--Since last update 2.2.2 - New version: 2.2.3 -> Changelog updated last: 2021-10-31
---------------------------------------------------------------------

--[Fixed]
--#154: Improving an item does not re-apply the improve icon (if quality below legendary)
--#168: Refinement smithing is not removing items from slot if marker icon is applied (via context menu or keybind)
--#169: First open of refinement/enchanting will not filter the filters properly
--#170: Re-opening craft station will not apply filters properly
--#171: Improving an item does not re-apply the already marked icons. Though the inventory shows the before applied marker icons until you scroll -> then they are gone
--#173 Keybind for "RemoveAll"/"UndoAll" was not working if modifier key (e.g. SHIFT key) for <modifierKey>+RightMouseButton (FCOIS settings) was not used in the keybind too


--[Changed]


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
