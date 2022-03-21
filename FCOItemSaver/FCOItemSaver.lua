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
--#129: 2021-06-01: Removing all marker icons via the add. inv. "flag" context menu does not remove companion item's marker icons
--#156: 2021-08-18, Baertram, bug: Enchanting an item does not re-apply the already marked icons (also consider icons that were saved for the items before? Add setting for "Check all others")
--#157: 2021-08-18, Baertram, bug: Character doll ring/weapon marker icons do not update properly (both 2 rings were unequipped via double click or drag and drop: on drag of 1 ring back to the right!!! slot the marker icons do not update, or equip 1 ring to the left and then use double click to equp the 2nd ring to the right slot).
--And if you drag another ring to a slot where a ring was already equipped the marker icons do neither update all!
--#158: 2021-08-18, Baertram, bug: Character doll ring/weapon marker icons do not remove all if SHIFT+right click is used on 1 ring (and the 2nd ring is identical)

--#174: 2021-10-31, Baertram, bug: If Inventory Insight from Ashes is enabled: Select "All" tab or any tab where items are shown which are on other characters. Find one item on another char
--                                 having any iocn set e.g. "sell". Right click it remove the sell icon, and then set it again. Sometimes the worn items and inventory (maybe all items somehow)
--                                 now show the removed/applied marker icon "sell" on them?!

--#176: 2021-11-14, Baertram, feature: Add submenu to 4 filter buttons, with setting to change the filter between AND & OR filter conjunction behaviour.
--Remembers the state for each filterPanel

--#178: 2021-12-03, Onigar (Addon comments), bug:
--[[ So at the bank deposit tab you got only the "green lock" FCOIS filterbutton set (right clicked the filter button -> chose the "lock" icon explicitly ->
    Then left clicked the filter button to turn it green -> will only filter out, hide, the lock marked items)?
    Or is it the green * button (right click first filterButton and choose the most otp entry "*"-> then left click the filter button to turn it green ->
    will filter out, hide, the lock and all dynamic icons).
    And as you deposit (via keybind? via drag & drop? via double click? Any difference here?) some other items (do they need to be marked with any
    FCOIS marker icon or could it also be any other non marked item?) all of sudden the filtered items with a lock/dynamic marker icon are shown in the
    bank deposit list again.
]]

--#181, 2022-01-02, Baertram: Check filter slash command chat feedback: Does it show correct info about filter state and new logical conjuncions?


--____________________________
-- Current max bugs/features/ToDos: 216
--____________________________


------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2022-03-19
------------------------------------------------------------------------------------
--#176 -> Test: Errors occured with OR filters, and mixed AND + OR filters
--Added checks if functions/API functions are called internally or from external (other addons) -> Still ongoing TODO


-------------------------------------------------------------------------------------
--Changelog (last version: 2.2.3 - New version: 2.2.4) -    Updated last: 2022-03-19
-------------------------------------------------------------------------------------
--[Fixed]
--Added debug file /src/FCOIS_Debug.lua to the txt file again
--Debug functions will use local speed up variable now
--Added more local speed-ups in several files
--Missing command handler function in API function FCOIS.ChangeFilter
--Removed duplicate calls to localization
--Removed duplicate calls to settings loading
--Added more speed-up local variables (tooltips, marker icons, API function calls)
--Fixed LAM settings menu editboxes for number values to disallow strings/empty strings and reset to default number if value is wrong--#175: lua error bad argument #1 to 'pairs' (table/struct expected, got nil) after improving items and leaving the improve station directly. Important: If you do not wait ~1-2 seconds after improvement has visually finished the automatic re-applied marker icons might fail to apply if you have left the improvement table meanwhile!
--#177: With filterButton 1 and 2 at yellow state: items without markerIcon of filter 1 (but being a dynamic gear of filter 2) will not filter (hide)
--#179: Gear or dynamic icons name could be empty and raise lua error messages. If left empty they will directly reset to the default name (English) now
--#180: GetItemInstanceId error upon mouse over at inventory quest items
--#182: FCOIS uniqueIds were saved with wrong values. Only the first parameter itemId was correct so they showed properly, but the differences like stolen, crafted, level, quality were never checked and saved properly.
--Attention: You need to remove and re-apply the markers for your items if you want to save them properly with all data now! Else the old marker strings with the itemId and every other value "the same" will be kept and used!
--You can use the new settings at "Backup &restore & delete", submenu "Delete" -> Delete all marker icons for FCOIS unique ones to mass-remove the old entries. And then use automatic marks like set items etc. to remark them new!
--#187: Delete backuped markerIcons was not removing some API versions properly
--#189: FCOIS uniqueIds item markers got saved into SavedVariables table "markedItems", but they should only be saved to "markedItemsFCOISUnique"
--#191: Switching from FCOIS unique to non-unique item markers will not show ANY marker icon at the inventories. If the migration dialog appears and is aborted the UI will be reloaded to fix this
--#192, FCOIS unique item marker strings contain the text "nil". This was changed to "" to reduce the size if the SVs
--#193: FCOIS settings menu disappears in total after using LibFeedbacks -> Send mail feature, and re-opening the settings a 2nd time after that
--#194: If the submenu for dynamic icons is enabled at the context menus: Using SHIFT+right mouse to remove/readd all marker icons to the item will still show the "Dynamic" submenu at banks/vendors/crafting
--#195: Fixed detection of owned house (for backup auto port suggestion to house, to access the house storage data)
--#197: Migration of non-unique item markers to FCOISunique itemMarkers does not work properly
--#198: Enchanting did not recognize the filters correctly and was not always protecting the items at extraction as it thought it is LF_INVENTORY
--#199: Companion equipment character sometimes is not showing the armor type labels L/M/H
--#200: The chosen language is not updated in localization of the settings menu properly
--#203: Mass moving to junk/removing from junk will kick you from the server because of message spam. Junk move will be done in 50 items packages now, with a 250ms delay in between each package.
--#204: Fixed error message in FCOIS.GetSavedVarsMarkedItemsTableName if loaded from other addons before FCOIS SavedVariables were loaded properly (e.g. IIfA)
--#207: Companion equipment character markers will not be shown properly at companion's character doll
--#208: Switching from vendor buy to sell panel raises a lua error
--#213,214: Automatic set collection markers and auto bind unknown items even if no unknown set collections marker icon was selected, and fixed settings menu to allow the seection of LibMultiAccountSets and auto bind missing set collections
--#215: Porting to house dialog (as you backup marker icons) was throwing a LibDialog error
--#216: /fcois help chat command shows all filter panel IDs possible now and /fcois command does not throw a lua error message anymore

--[Changed]
--Changed load order of debug file to earlier loading
--Removed duplicate code and strings for the filter button's "allowed to filter" functions
--FCOIS settings button at the main menu changed it's look from the -> arrow to the "FCOIS filter/lock icon" to dinstinguish it from other addons (e.g. Votans Settings Menu)
--#186 Update the gear and dynamic icons submenu to show the gear/dynamic icon name in the submenu text


--[Added]
--Added new constants for filter button states: FCOIS_CON_FILTER_BUTTON_STATE_RED, FCOIS_CON_FILTER_BUTTON_STATE_GREEN and FCOIS_CON_FILTER_BUTTON_STATE_YELLOW
--Added new constant for special filter button state: Do not update colors = FCOIS_CON_FILTER_BUTTON_STATE_DO_NOT_UPDATE_COLOR
--New looted missing set item pieces can be bound automatically (new setting), shown in chat (new setting) and be marked as unknown (exisitng settings) or known (new setting) set colelction pieces
--Added API function function FCOIS.GetGearIcons(onlyNonDynamicOnes, onlyDynamicOnes)
--Added IsCrownItem to the possible FCOIS unique-ID parts
--If you press SHIFT key and right mouse on the filter button this will reset the selected filter icon at the button to the * ("All") entry
--#184 Added automatic marking of needed scrolls etc. with ItemCooldownTracker API
--#188 Enable backup and restore for all 3 saved itemIds (non unique, ZOs unique and FCOIS unique). ZOs unique and non-unique can only be saved and restored together!
--#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel. The filter's and filterButtons and contextMenus re-use the selected protection
--     methods etc. of smithing deconstuction/jewelry deconstruction/enchanting extraction! If the "All" tab is selected at the universal decon panel, which includes all types of the
--     deconstructable/extractable item types, the smithing deconstruction buttons and context menu buttons are show, but the checks will still be done "per item", so that glyphs are protected too!


--[Added on request]
--#176 Add submenu to 4 filter buttons, with setting to change the filter between AND & OR filter conjunction behaviour. Remembers the state for each filterPanel
-->Due to current problems filtering combinations of logicla AND and OR the filterButtons will change ALL filterButtons logical conjunction settings between AND or OR at the same time!
--->Screenshot showing the new context menu "Filter settings" at the filter button: https://i.imgur.com/32AHUNS.png
--->Screenshot link for tooltip showing new logical conjunction AND/OR state: https://i.imgur.com/yj2UIOe.png
--#183 Add new SavedVariables saving independent to Server and AccountName -> "All servers and accounts the same"
--#185 Add possibility to only reset the SavedVariables of stored marker icons, but keep the other settings. See settings menu bakup & restored & delete -> new submenu "Delete"


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
