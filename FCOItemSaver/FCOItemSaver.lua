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

--#181, 2022-01-02, Baertram: Check filter slash command chat feedback: Does it show correct info about filter state and new logical conjunctions?


--#233  2022-06-26, Baertram: Add support for AwesomeGuildStores new feature "Sell at trading house, directly from bank"
--TODOS within AwesomeGuildStore:
-->Item drag protection: Working https://github.com/sirinsidiator/ESO-AwesomeGuildStore/blob/master/src/wrappers/SellTabWrapper.lua#L515 -> Calls ZO_InventorySlot_OnReceiveDrag then via "PickupEmoteById" hack
--> TODO !!! AwesomeGuildStore needs to update it's PreHooks of ZO_InventorySlot_OnStart Drag and ZO_InventorySlot_OnReceiveDrag !!!
-->Item drag protection error text: TODO -> Fix within AGS needed!

--#234  2022-06-26, Baertram: Add support for AwesomeGuildStores feature "Sell at trading house, directly from CraftBag"
--> FCOIS filterbuttons are not working (test together with CraftBagExtended, and both alone, and check LibFilters-3.0 CBE additions!!!)
--> https://github.com/sirinsidiator/ESO-AwesomeGuildStore/blob/master/src/wrappers/SellTabWrapper.lua#L714-L747

--#235  2022-06-30, Baertram: Companion marker at companion character doll looses the markers if a companion is dismissed and another is called
--> Maybe the same item is needed at both companions? Only visual bug, marker is still in SavedVariables and item is protected.

--#237 2022-03-14, 02:23, Papito, Feature request
--Sorry if this is explained somewhere, but is it possible to have the New items Automatic marking exclude item categories?
--A lot of junk items and white weapons/armor filll my inventory, I want them to be marked as sold, but I don't want it to apply to things like materials/consumables. Thank you

--#248 2022-08-18, Baertram, Feature request: Change LibShifterBox usage to LibAddonMenuDualListBox widget in settings etc.!


--#295 2022-12-05, Baertram, bug: After opening alchemy, enchanting, jewelry crafting, then clothier, then calling Giladil and talink to her to show the universal decon:
--[[
user:/AddOns/FCOItemSaver/src/Buttons/FCOIS_FilterButtons.lua:560: attempt to index a nil value
|rstack traceback:
user:/AddOns/FCOItemSaver/src/Buttons/FCOIS_FilterButtons.lua:560: in function 'FCOIS.CheckFCOISFilterButtonsAtPanel'
|caaaaaa<Locals> doUpdateLists = T, panelId = 16, hideFilterButtons = F, isUniversalDeconNPC = T, universalDeconFilterPanelIdBefore = 21, settings = [table:1]{}, buttonsParentCtrl = ud, filterPanel = 16, filterPanelIdToUse = 16, areFilterButtonEnabledAtPanelId = T, filterButtons = [table:2]{}, _ = 1, buttonNr = 1 </Locals>|r
user:/AddOns/FCOItemSaver/src/EventsHooks/FCOIS_Hooks.lua:1145: in function 'updateFilterAndAddInvFlagButtonsAtUniversalDeconstruction'
|caaaaaa<Locals> isHidden = F, LibFiltersFilterTypeAtUniversalDecon = 16, lastUniversalDeconFilterPanelId = 21, filterPanelIdPassedIn = 16, currentFilterPanelIdAtUniversalDecon = 16 </Locals>|r
user:/AddOns/FCOItemSaver/src/EventsHooks/FCOIS_Hooks.lua:1261: in function 'callback'
|caaaaaa<Locals> tab = [table:3]{iconOver = "EsoUI/Art/Inventory/inventory_...", key = "all", iconUp = "EsoUI/Art/Inventory/inventory_...", displayName = "Alles", iconDisabled = "EsoUI/Art/Inventory/inventory_...", iconDown = "EsoUI/Art/Inventory/inventory_..."}, craftingTypes = [table:4]{}, includeBanked = T, libFiltersFilterType = 16 </Locals>|r
/EsoUI/Libraries/Utility/ZO_CallbackObject.lua:132: in function 'ZO_CallbackObjectMixin:FireCallbacks'
|caaaaaa<Locals> self = [table:5]{fireCallbackDepth = 1}, eventName = "OnFilterChanged", registry = [table:6]{}, callbackInfoIndex = 2, callbackInfo = [table:7]{4 = F}, callback = user:/AddOns/FCOItemSaver/src/EventsHooks/FCOIS_Hooks.lua:1224, deleted = F </Locals>|r
/EsoUI/Ingame/Crafting/Keyboard/UniversalDeconstructionPanel_Keyboard.lua:171: in function 'ZO_UniversalDeconstructionPanel_Keyboard:OnFilterChanged'
|caaaaaa<Locals> self = [table:5], includeBankedItemsChecked = T, craftingTypeFilters = [table:4], currentTab = [table:3] </Locals>|r
/EsoUI/Ingame/Crafting/Keyboard/UniversalDeconstructionPanel_Keyboard.lua:228: in function 'ZO_UniversalDeconstructionInventory_Keyboard:ChangeFilter'
|caaaaaa<Locals> self = [table:8]{dirty = F, sortOrder = T, sortKey = "traitInformationSortOrder", performingFullRefresh = F}, filterData = [table:9]{disabled = "EsoUI/Art/Inventory/inventory_...", activeTabText = "Alles", highlight = "EsoUI/Art/Inventory/inventory_...", pressed = "EsoUI/Art/Inventory/inventory_...", tooltipText = "Alles", normal = "EsoUI/Art/Inventory/inventory_..."} </Locals>|r
/EsoUI/Ingame/Crafting/Keyboard/CraftingInventory.lua:148: in function 'callback'
|caaaaaa<Locals> tabData = [table:9] </Locals>|r
/EsoUI/Libraries/ZO_MenuBar/ZO_MenuBar.lua:287: in function 'MenuBarButton:Release'
|caaaaaa<Locals> self = [table:10]{m_highlightHidden = F, m_state = 1, m_locked = T}, upInside = T, skipAnimation = F, playerDriven = T, buttonData = [table:9] </Locals>|r
/EsoUI/Libraries/ZO_MenuBar/ZO_MenuBar.lua:657: in function 'ZO_MenuBarButtonTemplate_OnMouseUp'
|caaaaaa<Locals> self = ud, button = 1, upInside = T </Locals>|r
ZO_MainMenuCategoryBarButton1_MouseUp:3: in function '(main chunk)'
|caaaaaa<Locals> self = ud, button = 1, upInside = T, ctrl = F, alt = F, shift = F, command = F </Locals>|r
]]

--#267, 2023-04-19, dackjaniels, gitter: Additional inventory flag icon jumps at universal decon. if switched panels, and sometimes even hides. PP was enabled!

--#268, 2021-11-09, silvereyes, bug report
--[[
bad argument #1 to 'pairs' (table/struct expected, got nil)
stack traceback:
[C]: in function 'pairs'
user:/AddOns/FCOItemSaver/src/FCOIS_Functions.lua:2120: in function 'func'
|caaaaaa<Locals> bagId = 1, slotIndex = 16, iconsRemarked = 0 </Locals>|r
/EsoUI/Libraries/Globals/globalapi.lua:227: in function '(anonymous)'

Steps to reproduce:
Open a crafting station
Go to the improvement tab
Filter the items with a text filter so that only the item to improve is shown. Not sure if this is part of the base game, or Votan's Search Box, which I have installed.
Mark the item with an FCOItemSaver mark, like selling at guild store.
Deactivate anti improve
Improve the item all the way to legendary so that it becomes ineligible to improve

I'm guessing that the same sort of thing can happen any time a marked item becomes ineligible for the inventory list. For example, maybe after right click > bind a marked item in the guild store selling tab or mail send tab. I haven't tested that, though. Should be a fairly easy nil check either way.
]]


--#280 For future version of LibScrollableMenu, where LibCustomMenu was updated to be compatible too:
 -->Make FCOIS context menu and ZO_Menu stuff compatible with experimental LibScrollableMenu version where LSM will take over Inventory context menu creation from ZO_Menu/LibCustomMenu

--#297 Add scribing script automatic markers via LibCharacterKnowlege (but these need to be character dependend markers, is that possible? Or are account wide markers also possible -> only mark "unknwon for any other char")


--______________________________________
-- Current max # of bugs/features/ToDos: 307
--______________________________________

--Open/To work on this patch:


--=== Not started yet ===
--#301 Add LibSets set search favorites as marker icons of FCOIS to the inventories -> Maybe create a kind of "plugin system" that other addons can use to pass in a settings submenu, and some marker icons and textures of that other addon


------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2025-02-18
------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--Changelog (last version: 2.6.2 - New version: 2.6.3) -    Updated last: 2025-02-18
-------------------------------------------------------------------------------------
--[Fixed]
--#306 Fixed ItemCooldownTracker support, and reduced workload (building the LAM menu only if addon is active)
--#307 Fixed SetTracker settings submenu, and reduced workload (building the LAM menu only if addon is active)

--[Changed]


--[Added]
--#299 At launder/fence using SHIFT+right click or keybind to remove all marker icons should auto re-apply those to the same item once the fence/launder closes (enable at settings menu "Automatic Re-marks")


--[Added on request]


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
