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
-- Current max bugs: 78
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

-- 47) 2019-12-29 bug - Baertram
-- SHIFT +right click directly in guild bank's withdraw row does not work if the inventory was not at least opened once before
-- the guild bank was opened
--> File FCOIS_Hooks.lua, line 1332: ZO_PreHookHandler( ctrlVars.GUILD_BANK_BAG, "OnEffectivelyShown", FCOItemSaver_OnEffectivelyShown ) ->  function FCOItemSaver_OnEffectivelyShown -> function FCOItemSaver_InventoryItem_OnMouseUp
--> GuildBank withdraw: ZO_GuildBankBackpackContents only got child ZO_GuildBankBackpackLandingArea, but not rows if you directly open the guild bank after login/reloadui.
---> Guild bank needs more time to build the rows initially. So we need to wait here until they are build to register the hook!
--> If you switch to the guild bank deposit and back it got the rows then: ZO_GuildBankBackpack1RowN

-- 54) 2020-03-02 - OneSkyGod comments within FCOIS @www.esoui.com
-- Changing the 5th dynamic icon name -> lua error message
--[[
choices and choicesValues need to have the same size
stack traceback:
[C]: in function 'assert'
user:/AddOns/Tom/Libs/LibAddonMenu-2.0/LibAddonMenu-2.0/controls/dropdown.lua:125: in function 'UpdateChoices'
|caaaaaa<Locals> control = ud, choices = [table:1]{1 = "Lock"}, choicesValues = [table:2]{1 = 1}, choices = [table:1], choicesValues = [table:2], choicesTooltips = [table:3]{1 = "|c940000|t20:20:/esoui/art/cam..."} </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:223: in function 'updateIconListDropdownEntries'
|caaaaaa<Locals> dropdownCtrlName = "FCOItemSaver_Settings_1_Invigo...", updateData = [table:4]{scrollable = T, choices = "standard"}, dropdownCtrl = ud, choices = [table:1], choicesValues = [table:2] </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_SettingsMenu.lua:1084: in function 'setFunc'
|caaaaaa<Locals> newValue = "PVP" </Locals>|r
user:/AddOns/Tom/Libs/LibAddonMenu-2.0/LibAddonMenu-2.0/controls/editbox.lua:49: in function 'UpdateValue'
|caaaaaa<Locals> control = ud, forceDefault = F, value = "PVP" </Locals>|r
user:/AddOns/Tom/Libs/LibAddonMenu-2.0/LibAddonMenu-2.0/controls/editbox.lua:95: in function '(anonymous)'
|caaaaaa<Locals> self = ud </Locals>|r
[C]: in function 'LoseFocus'
EsoUI/Libraries/Globals/Globals.lua:51: in function 'OnGlobalMouseDown'
|caaaaaa<Locals> event = 65544, button = 1, focusEdit = ud </Locals>|r
]]

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

-- 77) 2020-05-28, Beartram
-- Clicking the additional inventory context menu button with left mouse -> lua error message
--[[
user:/AddOns/FCOItemSaver/src/FCOIS_ContextMenus.lua:3019: operator .. is not supported for string .. nil
|rstack traceback:
user:/AddOns/FCOItemSaver/src/FCOIS_ContextMenus.lua:3019: in function 'addSortedButtonDataTableEntries'
|caaaaaa<Locals> sortedButtonData = [table:1]{index = 61, isDynamic = T, buttonNameStr = "ButtonContextMenu31", iconId = 16, isGear = F}, index = 61, buttonsIcon = 16, isGear = F, isDynamic = T, buttonData = [table:2]{iconId = 16, mark = T, anchorButton = "ButtonContextMenu30"}, buttonNameStr = "ButtonContextMenu31", dynamicNumber = 4 </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_ContextMenus.lua:3111: in function 'FCOIS.showContextMenuForAddInvButtons'
|caaaaaa<Locals> invAddContextMenuInvokerButton = ud, panelId = 1, settings = [table:3]{}, locVars = [table:4]{options_icon13_size_TT = "Größe des 1. dynamischen Fil...", button_context_menu_toggle_anti_deconstruct_on = "Aktiviere 'Anti-Verwerten'", options_header_settracker = "Set Tracker", button_context_menu_toggle_anti_buy_on = "Aktiviere 'Anti-Kauf'", rightclick_menu_add_all_gear5 = "Alle zu Gear 5 hinzufügen", options_auto_mark_settrackersets_worn = "Markiere Getragene", options_auto_mark_crafted_items_TT = "Wenn Sie diese Option aktivier...", chatcommands_status_filter4 = "Verkaufs Filter: AN", button_context_menu_mark_all_as_dynamic9 = "+ 9. dynamische", options_filter_button4_height = "Höhe:", options_enable_auto_mark_ornate_items_TT = "Automatisch Gegenstände mit h...", options_header_anti_output_options = "Ausgabe Optionen", options_filter_button3_width_TT = "Breite des Filter Knopf 3", options_armor_type_icon_medium_short = "M", options_header_additional_inv_flag_context_menu = "Zusätzl. Inventar |t24:24:/es...", options_icon27_TT = "Zeige Tooltip", options_icon22_size = "Größe", options_pos_inventories_TT = "Die X-Achsen Position der Symb...", button_context_menu_dont_improve_all = "- Aufwerten", options_icon11_activate_text = "Verkauf im Gildenladen aktivie...", options_icons_dynamic_usable_warning = "Dynamische Symbole sind die ni...", options_auto_mark_settrackersets_show_tooltip_on_FCOIS_marker_TT = "Zeige die SetTracker Set Notiz...", options_auto_mark_recipes_this_char_TT = "Wenn Sie diese Option aktivier...", options_icon19_tooltip_TT = "Zeige Tooltip am 7. dynamische...", options_libFiltersFilterPanelIdName_8 = "LibFilters - Filter Bereich 8...", options_header_additional_buttons = "Zusätzliche Knöpfe", options_icon23_texture_TT = "Symbol des 11. dynamischen Fil...", options_show_armor_type_header_text = "Zeige Rüstungsart Überschrif...", options_icon2_color = "Farbe", options_quality_normal = "Normal", options_contextmenu_divider_opens_settings_TT = "Ein Klick auf den Trenner im K...", options_icon4_activate_text = "Ausrüstung Set 2 aktivieren", options_icon7_activate_text = "Ausrüstung Set 4 aktivieren", options_contextmenu_use_dyn_submenu_TT = "Nutze ein Untermenü für die ...", options_auto_mark_crafted_writ_items_TT = "Wenn Sie diese Option aktivier...", options_auto_mark_crafted_items = "Markiere hergestellte Gegenstä...", rightclick_menu_add_all_gear4 = "Alle zu Gear 4 hinzufügen", ornate_item_found = "] als höherer Verkaufspreis g...", options_icon13_size = "Größe", button_context_menu_undo = "< Änderung rückgängig mache...", options_tooltipatchar_TT = "Zeige den Tooltip auch im Char...", filter_enchantingstation_creation = "[Verzauberungsstation Herstell...", options_icon6_color_TT = "Farbe für das Symbol der Gear...", options_enable_auto_mark_new_items_TT = "Automatisch neue Gegenstände ...", options_contextmenu_divider_clears_all_markers_TT = "Ein Klick auf den Trenner im K...", options_auto_mark_recipes_this_char = "Nur für diesen Charakter", options_icon22_size_TT = "Größe des 10. dynamischen Fi...", rightclick_menu_mark_dynamic5 = "Markiere mit 5. dynamischen", options_icon18_activate_text = "Aktiviere 6. dynamische", options_icon14_texture = "Symbol"}, locContextEntriesVars = [table:5]{menu_add_deconstruction_text = "Verwerten vormerken", menu_add_intricate_text = "Als aufwendig markieren", menu_remove_lock_text = "Sperre entfernen", menu_add_lock_text = "Sperre setzen", menu_add_research_text = "Analyse vormerken", menu_remove_intricate_text = "Aufwendig zurücknehmen", menu_remove_sell_text = "Verkauf zurücknehmen", menu_remove_deconstruction_text = "Verwerten zurücknehmen", menu_remove_research_text = "Analyse zurücknehmen", menu_remove_improvement_text = "Aufwerten zurücknehmen", menu_add_improvement_text = "Aufwerten vormerken", menu_add_sell_to_guild_text = "Zum Verkauf im Gildenladen vor...", menu_remove_sell_to_guild_text = "Verkauf im Gildenladen zurück...", menu_add_sell_text = "Zum Verkauf vormerken"}, _ = 26, countDynIconsEnabled = 14, useDynSubMenu = F, icon2Gear = [table:6]{2 = 1}, icon2Dynamic = [table:7]{32 = 20}, isIconGear = [table:8]{1 = F}, isIconDynamic = [table:9]{1 = F}, sortAddInvFlagContextMenu = T, parentName = "ZO_PlayerInventory", myFont = "ZoFontGame", textPrefix = [table:10]{(null) = "+ ", (null) = "- "}, subMenuEntriesGear = [table:11]{}, subMenuEntriesDynamic = [table:12]{}, subMenuEntriesDynamicAdd = [table:13]{}, subMenuEntriesDynamicRemove = [table:14]{} </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_AdditionalButtons.lua:117: in function '(anonymous)'
]]

---------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed]
---------------------------------------------------------------------
--Since last update 1.9.2 - New version: 1.9.3
---------------------------------------------------------------------
--[Fixed]
--#77 Clicking the additional inventory context menu button with left mouse -> lua error message user:/AddOns/FCOItemSaver/src/FCOIS_ContextMenus.lua:3019: operator .. is not supported for string .. nil

--[Changed]

--[Added]
--

--[Added on request]
--#78 Keybind to remove all marker icons/to restore removed marker icon (same like <modifier key> [CTRL/ALT/SHIFT]+right mouse in the settings->marks->undo)

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
