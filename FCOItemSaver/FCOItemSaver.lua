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
---------------------------------------------------------------------
-- [TODO LONGTIME errors list -> find a way to reproduce/fix them] --
---------------------------------------------------------------------
-- #58) bug, Using dynamic icons as submenu will show the dynamic icons submenu out of bounds and not clickable + sometimes hide other non-dynamic icons (e.g. sell in guildstore) in the normal context menu then
---> Problem is that ZOs code is not raising the events like inside the normal inventories.
--Asked for a fix/support [URL="https://www.esoui.com/forums/showthread.php?t=8938"]in this forum thread[/URL]

-- #76) 2020-04-12, bug, Baertram
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

-- #79) 2020-05-28, bug, User m-ree via FCOIS addon panel, bug #2646
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


--#84) 2020-06-27, FEATURE - Malvarot - Automatic marks Quality will also tag set items "again" if the checkbox "check all other markers" at the quality settings is enabled.
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

--#92: 2020-08-10, bug, Baertram     SettingsForAll settings, which save if you are using accountwide, character or allAccountsTheSame SavedVariables will get
--     deleted if you delete the "Account wide" settings from the FCOIS settings menu "SavedVariables copy/delete" options submenu!
--     E.g. use "AllAccountsTheSame" in the settings of account @Baertram-> This setting is stored in AccountWide settings @Baertram, version 999.
--     If you delete the account settings for @Baertram now, the chosen settings to use AllAccountsTheSame gets deleted as well!
--     These SettingsForAll need to migrate and be saved somewhere else, like in a special settings table "FCOItemSaver_Settings_General"!

--#115: 2021-05-13, bug, Baertram  Reposition the additional inventory "flag" icons at crafting tables: Refine, deconstruction, improvement.
--                            and test if they also fit with AdvancedFilters enabled

--#131: bug, Error message at login:
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

--#140: bug, Error message at login -> related to fixed error 131
-->Could not create editbox "Gauche:" FCOItemSaver_LAM
-->Could not create editbox "Haute:" FCOItemSaver_LAM
----> Seems the fixed error message user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:2445: attempt to index a nil value is causing this now
--> Not reproducable?!


---------------------------------------------------------------------
--[TODO Current Errors and features list - Find a way to reproduce/fix/add them] --
--[General]Check for local speed ups. FCOItemSaver.txt was checked until src/FCOIS_Tooltips.lua -> as of 2021-08-18
--#156: 2021-08-18, Baertram, bug: Enchanting an item does not re-apply the already marked icons (also consider icons that were saved for the items before? Add setting for "Check all others")
--#157: 2021-08-18, Baertram, bug: Character doll ring/weapon marker icons do not update properly (both 2 rings were unequipped via double click or drag and drop: on drag of 1 ring back to the right!!! slot the marker icons do not update, or equip 1 ring to the left and then use double click to equp the 2nd ring to the right slot).
--And if you drag another ring to a slot where a ring was already equipped the marker icons do neither update all!
--#158: 2021-08-18, Baertram, bug: Character doll ring/weapon marker icons do not remove all if SHIFT+right click is used on 1 ring (and the 2nd ring is identical)

--#174: 2021-10-31, Baertram, bug: If Inventory Insight from Ashes is enabled: Select "All" tab or any tab where items are shown which are on other characters. Find one item on another char
--                                 having any iocn set e.g. "sell". Right click it remove the sell icon, and then set it again. Sometimes the worn items and inventory (maybe all items somehow)
--                                 now show the removed/applied marker icon "sell" on them?!

--#176: 2021-11-14, Baertram, feature: Add submenu to 4 filter buttons, with setting to change the filter between AND & OR filter conjunction behaviour.
--Remembers the state for each filterPanel. -> Implemented but currently ONLY with AND or OR for all 4 buttons the same! -> Maybe split up per filter button one day...

--#178: 2021-12-03, Onigar (Addon comments), bug:
--[[ So at the bank deposit tab you got only the "green lock" FCOIS filterbutton set (right clicked the filter button -> chose the "lock" icon explicitly ->
    Then left clicked the filter button to turn it green -> will only filter out, hide, the lock marked items)?
    Or is it the green * button (right click first filterButton and choose the most top entry "*"-> then left click the filter button to turn it green ->
    will filter out, hide, the lock and all dynamic icons).
    And as you deposit (via keybind? via drag & drop? via double click? Any difference here?) some other items (do they need to be marked with any
    FCOIS marker icon or could it also be any other non marked item?) all of sudden the filtered items with a lock/dynamic marker icon are shown in the
    bank deposit list again.
]]

--#176, 2021-10-12, Baertram: Errors occured with OR filters, and mixed AND + OR filters -> Currently only ALL or or ALL AND can be enabled!
--#181, 2022-01-02, Baertram: Check filter slash command chat feedback: Does it show correct info about filter state and new logical conjuncions?

--#225  2022-04-24, Baertram: Savedvariables copy from server EU -> PTS "All accounts the same" or "Chosen account" does not work. Reloadui is done but
--settings were not copied properly


--#233  2022-06-26, Baertram: Add support for AwesomeGuildStores new feature "Sell at trading house, directly from bank"
--TODOS within AwesomeGuildStore:
-->Item drag protection: Working https://github.com/sirinsidiator/ESO-AwesomeGuildStore/blob/master/src/wrappers/SellTabWrapper.lua#L515 -> Calls ZO_InventorySlot_OnReceiveDrag then via "PickupEmoteById" hack
--> TODO !!! AwesomeGuildStore needs to update it's PreHooks of ZO_InventorySlot_OnStart Drag and ZO_InventorySlot_OnReceiveDrag !!!
-->Item drag protection error text: TODO -> Fix within AGS needed!

--#234  2022-06-26, Baertram: Add support for AwesomeGuildStores feature "Sell at trading house, directly from CraftBag"
--> FCOIS filterbuttons are not working (test together with CraftBagExtended, and both alone, and check LibFilters-3.0 CBE additions!!!)
--> https://github.com/sirinsidiator/ESO-AwesomeGuildStore/blob/master/src/wrappers/SellTabWrapper.lua#L714-L747

--#235  2022-06-30, Baertram: Companion marker at companion character doll looses the marker if a companion is dismissed and another is called
--> Maybe the same item is needed at both companions? Only visual bug, marker is still in SavedVariables and item is protected.

--#237 2022-03-14, 02:23, Papito, Feature request
--Sorry if this is explained somewhere, but is it possible to have the New items Automatic marking exclude item categories?
--A lot of junk items and white weapons/armor filll my inventory, I want them to be marked as sold, but I don't want it to apply to things like materials/consumables. Thank you

--#239 2022-07-17, Baertram, bug: AwesomeGuildStore - Directly switching from custom "Sell from bank" button to "Sell from inventory" button will enable FCOIS.gFilterWhere = LF_INVENTORY
--instead of LF_GUILD_STORE_SELL
-->Maybe event_bank_closed?

--#248 2022-08-18, Baertram, Feature request: Change LibShifterBox usage to LibAddonMenuDualListBox widget in settings etc.!

--#257 2022-11-28, Octopuss, comments:  I tried to remove all icons from the settings menu
--[[
user:/AddOns/FCOItemSaver/src/BackupMigration/FCOIS_BackupRestoreDelete.lua:686: operator .. is not supported for string .. nil
stack traceback:
user:/AddOns/FCOItemSaver/src/BackupMigration/FCOIS_BackupRestoreDelete.lua:686: in function 'FCOIS.DeleteMarkerIcons'
|caaaaaa<Locals> markerIconsToDeleteType = 2, markerIconsToDeleteIcon = -1, preVars = [table:1]{currentStart = "> ", preChatText = "FCOIS", currentEnd = " <", preChatTextGreen = "|c22DD22FCOIS|r ", preChatTextBlue = "|c2222DDFCOIS|r ", preChatTextRed = "|cDD2222FCOIS|r "}, uniqueItemIdTypeChoices = [table:2]{}, savedVarsMarkedItemsNames = [table:3]{(null) = "markedItems", 1 = "markedItems"}, allIcons = T, iconStr = "All icons", markerIconsToDeleteTypeTable = "markedItemsFCOISUnique" </Locals>|r
user:/AddOns/FCOItemSaver/src/Settings/FCOIS_SettingsMenu.lua:7654: in function 'm_callback'
/EsoUI/Libraries/ZO_Dialog/ZO_Dialog.lua:111: in function 'HandleCallback'
|caaaaaa<Locals> clickedButton = ud, dialog = ud, instanceId = 1 </Locals>|r
/EsoUI/Libraries/ZO_KeybindButton/ZO_KeybindButton.lua:194: in function 'ZO_KeybindButtonMixin:OnClicked'
|caaaaaa<Locals> self = ud, visible = T </Locals>|r
/EsoUI/Libraries/ZO_KeybindButton/ZO_KeybindButton.lua:265: in function 'ZO_KeybindButtonTemplate_OnMouseUp'
|caaaaaa<Locals> self = ud, button = 1, upInside = T </Locals>|r
ZO_Dialog1Button2_MouseUp:3: in function '(main chunk)'
|caaaaaa<Locals> self = ud, button = 1, upInside = T, ctrl = F, alt = F, shift = F, command = F </Locals>|r
]]

--#258 2022-11-27, Octopuss, comments: Keybind for remove all marks/undo does not work
--[[I have since deleted the savedvars and redid all settings from scratch (ouch) just to make sure I have clean baseline (and to get rid of all the marks).
So now I assigned PgUp to the "remove all marks" bind, added a lock icon to a random item in the inventory, moused over it with the cursor, pressed PgUp, and nothing happened.
"Remove all icons" context menu entry works just fine.
]]

--______________________________________
-- Current max # of bugs/features/ToDos: 258
--______________________________________


------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2022-12-04
------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------
--Changelog (last version: 2.4.3- New version: 2.4.4) -    Updated last: 2022-13-04
-------------------------------------------------------------------------------------
--[Fixed]
--#257
--#258

--[Changed]
--

--[Added]
--

--[Added on request]
--


--************************************************************************************************************************
--************************************************************************************************************************
--************************************************************************************************************************


------------------------------------------------------------------
-- START OF ADDON CODE
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
