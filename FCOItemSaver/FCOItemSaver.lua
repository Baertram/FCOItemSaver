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
-- Current max bugs: 51
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

-- 41) 2019-10-25 Bug - Baertram
--Research and other ZO_ListDialogs: If you move the mouse over a row the keybindings of FCOIS get enabled. If you do not leave the row again and press the standard
--keybindings of the dialog (e.g. research) it will not work but after closing the menu the UI is messed and something is broken!

-- 43) 2019-12-12 Bug - Baertram
-- Enchant item popup allows to use items which are marked and protected if you click twice on the same item row.
--> Analysis: FCOIS_Hooks.lua- --========= RESEARCH LIST / ListDialog (also repair, enchant, charge, etc.) - ZO_Dialog1 -> ZO_PreHookHandler(rowControl, "OnMouseUp" ->
--> if upInside then -> FCOIS.refreshPopupDialogButtons(rowControl, false) -> FCOIS_ContextMenus.lua -> function FCOIS.refreshPopupDialogButtons ->
--> if not ctrlVars.RepairItemDialog:IsHidden() then -> disableResearchNow = FCOIS.DeconstructionSelectionHandler(bagId, slotIndex, false, true, true, true, true, false, nil)
-->Tests: If paraemeter calledFromExternalAddon is set to false the protection function will return "false" in the dialogs if you click an item's row
-->where an icon is marked and protects this item! So why does it return false if calledFromExternalAddon is set to "false" ???


-- 44) 2019-12-13 Change of code - Baertram
-- Try to use the listView's setupFunction instead of OnEffectivelyShown to register a secureposthook on the OnMouseUp etc. events to the inventory rows

-- 45) 2019-12-29 bug - Baertram
-- SHIFT + right mouse button will restore marker icons on items which got NEW into the inventory or got the same bagId + slotIndex like a before "saved"
-- (via shift+ right mouse) item had. But this item changed it's bagId and slotIndex now or even left the inventory (sold e.g.)
-- So the save should use the itemId/itemInstanceId or uniqueID instead and the restore as well!
--> File FCOIS_MarkerIcons.lua, function FCOIS.checkIfClearOrRestoreAllMarkers()

-- 46) 2019-12-29 bug - Baertram
-- Error message in Guild bank withdraw, after using inventory, bank and guild store before!
--Clicking left on the additional inventory flag icon:
--[[
!!!WICHTIG: Zeile 3007 (nicht mehr 2993) in FCOIS version 1.4.7!!!!
--> buttonText = textPrefix[buttonData.mark] .. locContextEntriesVars.menu_add_dynamic_text[dynamicNumber]
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
options_block_selling_exception_intricate = "Erlaube Verkauf von aufwendige...", show_anti_messages_in_chat = "Warnung im Chat anzeigen", options_contextmenu_entries_tooltip_protectedpanels_TT = "Zeige den aktuellen Schutz-Sta...", options_icon4_tooltip_TT = "Tooltip beim Gear 2 Symbol anz...", options_enable_auto_mark_sets_non_wished_level = "Level Schwelle <", options_quality_trash = "Trödel", button_context_menu_unmark_all_as_dynamic11 = "- 11. dynamische", rightclick_menu_add_all_start_gear = "Alle hinzufügen zu ", options_additional_buttons_FCOIS_additional_options_offsetx = "Position X", filter_sellguildint_3 = "Aufwendig", options_enable_auto_mark_research_items = "Analysierbare Items", options_enable_filter_in_deconstruction_TT = "Ermöglicht es dir die markier...", options_libFiltersFilterPanelIdName_7 = "LibFilters - Filter Bereich 7...", options_contextmenu_entries_tooltip_protectedpanels = "Zeige Schutz-Status im Tooltip...", options_icon_sort_15 = "15.", filter_lockdyn_13 = "2. dynamische", options_auto_mark_crafted_items = "Markiere hergestellte Gegenstä...", options_icon7_TT = "Tooltip anzeigen", options_armor_type_icon_character_pos_y_TT = "Wähle die Y-Achsen Position f...", options_demark_all_deconstruct = "Demarkiere alle bei 'Verwerten...", options_auto_reenable_block_selling_guild_store = "Reaktiviere Gildenladen Anti-V...", options_quality_artifact = "Artefakt"},
locContextEntriesVars = [table:5]
{menu_remove_deconstruction_text = "Verwerten zurücknehmen",
menu_add_deconstruction_text = "Verwerten vormerken",
menu_add_lock_text = "Sperre setzen",
menu_add_research_text = "Analyse vormerken",
menu_add_improvement_text = "Aufwerten vormerken",
menu_remove_sell_text = "Verkauf zurücknehmen",
menu_add_sell_text = "Zum Verkauf vormerken",
menu_add_sell_to_guild_text = "Zum Verkauf im Gildenladen vor...",
menu_remove_research_text = "Analyse zurücknehmen",
menu_remove_improvement_text = "Aufwerten zurücknehmen",
menu_remove_intricate_text = "Aufwendig zurücknehmen",
menu_remove_lock_text = "Sperre entfernen",
menu_add_intricate_text = "Als aufwendig markieren",
menu_remove_sell_to_guild_text = "Verkauf im Gildenladen zurück..."
},
_ = 26, countDynIconsEnabled = 14, useDynSubMenu = F, icon2Gear = [table:6]{2 = 1}, icon2Dynamic = [table:7]{32 = 20}, isIconGear = [table:8]{1 = F}, isIconDynamic = [table:9]{1 = F}, sortAddInvFlagContextMenu = T, parentName = "ZO_GuildBank", myFont = "ZoFontGame", textPrefix = [table:10]{(null) = "+ ", (null) = "- "}, subMenuEntriesGear = [table:11]{}, subMenuEntriesDynamic = [table:12]{}, subMenuEntriesDynamicAdd = [table:13]{}, subMenuEntriesDynamicRemove = [table:14]{} </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_AdditionalButtons.lua:117: in function '(anonymous)'
]]
--> Seems locContextEntriesVars.that menu_add_dynamic_text is NIL in these cases, so where is menu_add_dynamic_text added to locContextEntriesVars?
---> locContextEntriesVars = FCOIS.localizationVars.contextEntries  -> In file FCOIS_Localization.lua, line 425 inside function FCOIS.Localization()
---> FCOIS.localizationVars.contextEntries.menu_add_dynamic_text = {} in line 434 so the table should exist at least but it doesn't in these cases?
----> Also done in file FCOIS_ContextMenu.lua, function FCOIS.changeContextMenuEntryTexts line 1427
-------> Entries: line 502: table.insert(contextEntries.menu_add_dynamic_text, locTexts["rightclick_menu_mark_dynamic" .. tostring(dynIconNr)])


-- 47) 2019-12-29 bug - Baertram
-- SHIFT +right click directly in guild bank's withdraw row does not work if the inventory was not at least opened once before
-- the guild bank was opened
--> File FCOIS_Hooks.lua, line 1332: ZO_PreHookHandler( ctrlVars.GUILD_BANK_BAG, "OnEffectivelyShown", FCOItemSaver_OnEffectivelyShown ) ->  function FCOItemSaver_OnEffectivelyShown -> function FCOItemSaver_InventoryItem_OnMouseUp
--> GuildBank withdraw: ZO_GuildBankBackpackContents only got child ZO_GuildBankBackpackLandingArea, but not rows if you directly open the guild bank after login/reloadui.
---> Guild bank needs more time to build the rows initially. So we need to wait here until they are build to register the hook!
--> If you switch to the guild bank deposit and back it got the rows then: ZO_GuildBankBackpack1RowN

-- 48) 2020-01-29 bug - Baertram
-- Changed function's call of ItemSelection and DeconstructionHandler parameter "CalledFromExternalAddon" to be false if called from inside FCOIS
-- and this makes bug #43 (ZO_ListDialog protected item row clicked twice -> item can be used even if protected) be solved but creates other bugs:
-- Guild store item sell -> CraftBagExtended panel!!!: Tooltip says e.g. dyanmic icons like Quality are not protected and allows selling but the setting of this dynamic icon
-- says it is protected!
-- So it's some problem with CBE and other panels, maybe also happens at the mail and trade panels!

-- 49) 2020-02-01 bug - Baertram
-- CraftBagExtended panel additional inventory "flag" button was grey and not able to change the "Anti sell at guildstore" protection

-- 50) 2020-02-01 bug - Baertram
-- Using the left click context menu on an additional inventory "flag" context menu button, and then selecting the "Disable/Enable anti-" protection entry will
-- not update the tooltips of the marker icons properly. Whereas right clicking the "flag" icon does update the tooltips!
--> See file FCOIS_ContextMenus.lua, function ContextMenuForAddInvButtonsOnClicked -> isTOGGLEANTISETTINGSButton boolean ->

-- 51) 2020-01-20 bug - Baertram
-- Typing error in function IsMenuVisisble was fixed by ZOs. Adopt the code to support both function names (wrong and correct)


---------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed]
---------------------------------------------------------------------
--Since last update 1.7.3 - New version: 1.7.4
---------------------------------------------------------------------
--[Fixed]
--#41: Research and other ZO_ListDialogs: Keybindings of vanilla UI and FCOIS will both work on dialogs now and not destroy the UI keys afterwards
--#43: Double click on dialog item made it selectable even if the item was protected
--#46: Fixed the error message in Guild bank withdraw, after using inventory, bank and guild store before and clicking left on the additional inventory "flag" icon to show the context menu.
--> This is only a temporary fix to suppress the error message as I was not able to rebuild this error and need more input how and when it happens.
---> Added a debug message for my own account to see when it happens again and maybe collect some info how to fix it finally to "not happen" anymore.
--#48: CraftBagExtended items at GuildStore sell panel were not protected properly anymore after #44 was fixed
--#49: CraftBagExtended panel additional inventory "flag" button was grey and not able to change the "Anti sell at guildstore" protection
--#50: Additional inventory "flag" button entry "Disable/Enable anti-*" did not update the marker icon tooltips properly to reflect the current protection state, and did not remove slotted and protected items from an extraction/sell/etc. slot automatically
--#51: Typo in function IsMenuVisisble was removed. Adopted code.

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
