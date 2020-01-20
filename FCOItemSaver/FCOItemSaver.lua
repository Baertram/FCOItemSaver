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
-- Current max bugs: 47
--____________________________

-- 1) 2019-01-14 - Bugfix - Baertram
--Right clicking an item to show the context menu, and then left clicking somewhere else does not close the context menu on first click, but on 2nd click
-->Todo: Bug within LibCustomMenu -> To be fixed by Votan?

--23) 2019-08-17 Check - Baertram
--Todo: Test if backup/restore is working properly with the "AllAccountsTheSame" settings enabled

--27) 2019-10-10 Bug - Baertram
-- Drag & drop of marked items directly from the CraftBagExtended panel to a mail slot works even if the FCOIS protection is enabled! SAme for player2player trade.

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

-- 41) 2019-10-25 Bug - Baertram
--Research and other ZO_ListDialogs: If you move the mouse over a row the keybindings of FCOIS get enabled. If you do not leave the row again and press the standard
--keybindings of the dialog (e.g. research) it will  not work but after closing the menu the UI is messed and something is broken!

-- 43) 2019-12-12 Bug - Baertram
-- Enchant item popup allows to use items which are marked and protected if you click twice on the items

-- 44) 2019-12-13 Change of code - Baertram
-- Try to use the listView's setupFunction instead of OnEffectivelyShown to register a secureposthook on the OnMouseUp etc. events to the inventory rows

-- 45) 2019-12-29 bug - Baertram
-- SHIFT + right mouse button will restore marker icons on items which got NEW into the inventory or got the same bagId + slotIndex like a before "saved"
-- (via shift+ right mouse) item had. But this item changed it's bagId and slotIndex now or even left the inventory (sold e.g.)
-- So the save should use the itemId/itemInstanceId or uniqueID instead and the restore as well!

-- 46) 2019-12-29 bug - Baertram
-- Error message in Guild bank withdraw, after using inventory, bank and guild store before!
--Clicking left on the additional inventory flag icon:
--[[
user:/AddOns/FCOItemSaver/src/FCOIS_ContextMenus.lua:2993: operator .. is not supported for string .. nil
stack traceback:
user:/AddOns/FCOItemSaver/src/FCOIS_ContextMenus.lua:2993: in function 'addSortedButtonDataTableEntries'
|caaaaaa<Locals> sortedButtonData = [table:1]{isDynamic = T, index = 31, iconId = 16, isGear = F, buttonNameStr = "ButtonContextMenu31"},
index = 31, buttonsIcon = 16, isGear = F, isDynamic = T, buttonData = [table:2]{iconId = 16, anchorButton = "ButtonContextMenu30", mark = T},
buttonNameStr = "ButtonContextMenu31", dynamicNumber = 4 </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_ContextMenus.lua:3073: in function 'FCOIS.showContextMenuForAddInvButtons'
|caaaaaa<Locals> invAddContextMenuInvokerButton = ud, panelId = 4, settings = [table:3]{}, locVars = [table:4]{
options_prevent_auto_marking_sell_guild_store = "Verhindere Auto-Mark. (Verkauf...",
options_libFiltersFilterPanelIdName_14 = "LibFilters - Filter Bereich 14...",
options_auto_mark_crafted_items_TT = "Wenn Sie diese Option aktivier...",
options_enable_auto_mark_sets_settracker_icons = "Prüfe SetTracker Sets",
options_icon25_texture_TT = "Symbol des 13. dynamischen Fil...",
button_context_menu_toggle_anti_deconstruct_off = "Deaktiviere 'Anti-Verwerten'",
filter1_onlyfiltered = "Schloß Filter ZEIGT NUR GEFIL...",
options_libFiltersFilterPanelIdName_29 = "LibFilters - Filter Bereich 29...",
options_icon7_name = "Gear 4",
chatcommands_filtershow = "|cFFFFFF'allezeigen'|cFFFF00: ...",
options_libFiltersFilterPanelIdName_31 = "LibFilters - Filter Bereich 31...",
button_context_menu_unmark_all_as_dynamic2 = "- 2. dynamische",
options_libFiltersFilterPanelIdName_8 = "LibFilters - Filter Bereich 8...",
options_icon14_enabled_TT = "Das 2. dynamische Symbol ist a...",
show_anti_messages_as_alert = "Warnung im Fehler Fenster anze...",
button_context_menu_toggle_anti_sell_off = "Deaktiviere 'Anti-Verkauf'",
options_header_items_demark = "Automatische De-Markierung",
options_additional_buttons_FCOIS_additional_options_colorize = "Färbe zusätzl.
Optionen in I...", options_quality_legendary = "Legendär",
SI_BINDING_NAME_FCOIS_MARK_ITEM_1 = "'Schloss' Symbol markieren",
options_auto_mark_addon = "Zu verwendendes Addon",
options_enable_auto_mark_check_all_icons = "Prüfe alle Anderen",
filter1_split_onlyfiltered = "Filter ZEIGT NUR GEFILTERTE",
SI_BINDING_NAME_FCOIS_MARK_ITEM_21 = "Markiere mit dynamischen Symbo...",
options_auto_reenable_block_refinement = "Reaktiviere Anti-Veredeln auto...",
options_enable_filter_in_jewelry_refinement_TT = "Ermöglicht es dir die markier...",
chatcommands_status_info = "|c00FF00FCO|cFFFF00Item Saver|...",
rightclick_menu_lock = "Sperre setzen",
options_block_selling_exception_intricate = "Erlaube Verkauf von aufwendige...", show_anti_messages_in_chat = "Warnung im Chat anzeigen", options_contextmenu_entries_tooltip_protectedpanels_TT = "Zeige den aktuellen Schutz-Sta...", options_icon4_tooltip_TT = "Tooltip beim Gear 2 Symbol anz...", options_enable_auto_mark_sets_non_wished_level = "Level Schwelle <", options_quality_trash = "Trödel", button_context_menu_unmark_all_as_dynamic11 = "- 11. dynamische", rightclick_menu_add_all_start_gear = "Alle hinzufügen zu ", options_additional_buttons_FCOIS_additional_options_offsetx = "Position X", filter_sellguildint_3 = "Aufwendig", options_enable_auto_mark_research_items = "Analysierbare Items", options_enable_filter_in_deconstruction_TT = "Ermöglicht es dir die markier...", options_libFiltersFilterPanelIdName_7 = "LibFilters - Filter Bereich 7...", options_contextmenu_entries_tooltip_protectedpanels = "Zeige Schutz-Status im Tooltip...", options_icon_sort_15 = "15.", filter_lockdyn_13 = "2. dynamische", options_auto_mark_crafted_items = "Markiere hergestellte Gegenstä...", options_icon7_TT = "Tooltip anzeigen", options_armor_type_icon_character_pos_y_TT = "Wähle die Y-Achsen Position f...", options_demark_all_deconstruct = "Demarkiere alle bei 'Verwerten...", options_auto_reenable_block_selling_guild_store = "Reaktiviere Gildenladen Anti-V...", options_quality_artifact = "Artefakt"}, locContextEntriesVars = [table:5]{menu_remove_deconstruction_text = "Verwerten zurücknehmen", menu_add_deconstruction_text = "Verwerten vormerken", menu_add_lock_text = "Sperre setzen", menu_add_research_text = "Analyse vormerken", menu_add_improvement_text = "Aufwerten vormerken", menu_remove_sell_text = "Verkauf zurücknehmen", menu_add_sell_text = "Zum Verkauf vormerken", menu_add_sell_to_guild_text = "Zum Verkauf im Gildenladen vor...", menu_remove_research_text = "Analyse zurücknehmen", menu_remove_improvement_text = "Aufwerten zurücknehmen", menu_remove_intricate_text = "Aufwendig zurücknehmen", menu_remove_lock_text = "Sperre entfernen", menu_add_intricate_text = "Als aufwendig markieren", menu_remove_sell_to_guild_text = "Verkauf im Gildenladen zurück..."}, _ = 26, countDynIconsEnabled = 14, useDynSubMenu = F, icon2Gear = [table:6]{2 = 1}, icon2Dynamic = [table:7]{32 = 20}, isIconGear = [table:8]{1 = F}, isIconDynamic = [table:9]{1 = F}, sortAddInvFlagContextMenu = T, parentName = "ZO_GuildBank", myFont = "ZoFontGame", textPrefix = [table:10]{(null) = "+ ", (null) = "- "}, subMenuEntriesGear = [table:11]{}, subMenuEntriesDynamic = [table:12]{}, subMenuEntriesDynamicAdd = [table:13]{}, subMenuEntriesDynamicRemove = [table:14]{} </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_AdditionalButtons.lua:117: in function '(anonymous)'
]]

-- 47) 2019-12-29 bug - Baertram
-- SHIFT +right click directly in guild bank's withdraw row (with addon Perfect Pixel enabled!) does not work if the inventory was not at least opened once before
-- the guild bank was opened


---------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed]
---------------------------------------------------------------------
--Since last update - New version: 1.7.3
---------------------------------------------------------------------
--[Fixed]
--

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
