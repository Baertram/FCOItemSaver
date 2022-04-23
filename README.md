# FCOItemSaver
AddOn for the game Elder Scrolls Online: Saving your items so you do not accidently destroy/sell/deconstruct them + many other features.


==Changelog for current beta version ==
```

---#221, 2022-04-17, Medic1985: Universal Decon: use the new assitant rag collector/ragpicker to decon my equip, I get an error massage only when I choose the last tab glyphs
--and go back to another tab. This is the message:
--[[
user:/AddOns/FCOItemSaver/src/FCOIS_FilterButtons.lua:559: attempt to index a nil value
stack traceback:
user:/AddOns/FCOItemSaver/src/FCOIS_FilterButtons.lua:559: in function 'FCOIS.CheckFCOISFilterButtonsAtPanel'
|caaaaaa<Locals> doUpdateLists = T, panelId = 33, hideFilterButtons = F, isUniversalDeconNPC = T, universalDeconFilterPanelIdBefore = 21, settings = [table:1]{}, buttonsParentCtrl = ud, filterPanel = 33, filterPanelIdToUse = 33, areFilterButtonEnabledAtPanelId = T, filterButtons = [table:2]{}, _ = 1, buttonNr = 1 </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_Hooks.lua:1095: in function 'updateFilterAndAddInvFlagButtonsAtUniversalDeconstruction'
|caaaaaa<Locals> isHidden = F, LibFiltersFilterTypeAtUniversalDecon = 33, lastUniversalDeconFilterPanelId = 21, filterPanelIdPassedIn = 33, currentFilterPanelIdAtUniversalDecon = 33 </Locals>|r
user:/AddOns/FCOItemSaver/src/FCOIS_Hooks.lua:1211: in function 'callback'
|caaaaaa<Locals> tab = [table:3]{iconOver = "EsoUI/Art/Crafting/jewelry_tab...", iconUp = "EsoUI/Art/Crafting/jewelry_tab...", iconDisabled = "EsoUI/Art/Crafting/jewelry_tab...", displayName = "Schmuck", key = "jewelry", iconDown = "EsoUI/Art/Crafting/jewelry_tab..."}, craftingTypes = [table:4]{}, includeBanked = T, libFiltersFilterType = 33 </Locals>|r
/EsoUI/Libraries/Utility/ZO_CallbackObject.lua:107: in function 'ZO_CallbackObjectMixin:FireCallbacks'
|caaaaaa<Locals> self = [table:5]{fireCallbackDepth = 1}, eventName = "OnFilterChanged", registry = [table:6]{}, callbackInfoIndex = 2, callbackInfo = [table:7]{3 = F}, callback = user:/AddOns/FCOItemSaver/src/FCOIS_Hooks.lua:1174, deleted = F </Locals>|r
/EsoUI/Ingame/Crafting/Keyboard/UniversalDeconstructionPanel_Keyboard.lua:171: in function 'ZO_UniversalDeconstructionPanel_Keyboard:OnFilterChanged'
|caaaaaa<Locals> self = [table:5], includeBankedItemsChecked = T, craftingTypeFilters = [table:4], currentTab = [table:3] </Locals>|r
/EsoUI/Ingame/Crafting/Keyboard/UniversalDeconstructionPanel_Keyboard.lua:228: in function 'ZO_UniversalDeconstructionInventory_Keyboard:ChangeFilter'
|caaaaaa<Locals> self = [table:8]{sortOrder = T, performingFullRefresh = F, sortKey = "traitInformationSortOrder", dirty = F}, filterData = [table:9]{activeTabText = "Schmuck", highlight = "EsoUI/Art/Crafting/jewelry_tab...", disabled = "EsoUI/Art/Crafting/jewelry_tab...", normal = "EsoUI/Art/Crafting/jewelry_tab...", pressed = "EsoUI/Art/Crafting/jewelry_tab..."} </Locals>|r
/EsoUI/Ingame/Crafting/Keyboard/CraftingInventory.lua:148: in function 'callback'
|caaaaaa<Locals> tabData = [table:9] </Locals>|r
/EsoUI/Libraries/ZO_MenuBar/ZO_MenuBar.lua:286: in function 'MenuBarButton:Release'
|caaaaaa<Locals> self = [table:10]{m_locked = T, m_highlightHidden = F, m_state = 1}, upInside = T, skipAnimation = F, playerDriven = T, buttonData = [table:9] </Locals>|r
/EsoUI/Libraries/ZO_MenuBar/ZO_MenuBar.lua:656: in function 'ZO_MenuBarButtonTemplate_OnMouseUp'
|caaaaaa<Locals> self = ud, button = 1, upInside = T </Locals>|r
ZO_MainMenuCategoryBarButton1_MouseUp:3: in function '(main chunk)'
|caaaaaa<Locals> self = ud, button = 1, upInside = T, ctrl = F, alt = F, shift = F, command = F </Locals>|r
]]


--______________________________________
-- Current max # of bugs/features/ToDos: 221
--______________________________________


------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2022-04-17
------------------------------------------------------------------------------------
--#221

-------------------------------------------------------------------------------------
--Changelog (last version: 2.2.5 - New version: 2.2.6) -    Updated last: 2022-04-17
-------------------------------------------------------------------------------------
--[Fixed]


--[Changed]
--ListViews of inventory/crafting tables use SecurePostHook now

--[Added]


--[Added on request]
```
