# FCOItemSaver
AddOn for the game Elder Scrolls Online: Saving your items so you do not accidently destroy/sell/deconstruct them + many other features.


==Changelog for current PTS API101033==
```
------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2022-03-02
------------------------------------------------------------------------------------
--#176 -> Test: Errors occured with OR filters, and mixed AND + OR filters
--Added checks if functions/API functions are called internally or from external (other addons) -> Still ongoing TODO

-------------------------------------------------------------------------------------
--Changelog (last version: 2.2.3 - New version: 2.2.4) -    Updated last: 2022-03-02
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
--#200: The chosen language is not updated in localization of the settings menu properly
--#204: Fixed error message in FCOIS.GetSavedVarsMarkedItemsTableName if loaded from other addons before FCOIS SavedVariables were loaded properly (e.g. IIfA)

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
--#202 FilterButtons and addiitonal inventory flag context menu button added to universal deconstruction panel. The filter's and filterButtons and contextMenus re-use the selected protection
--     methods etc. of smithing deconstuction/jewelry deconstruction/enchanting extraction! If the "All" tab is selected at the universal decon panel, which includes all types of the
--     deconstructable/extractable item types, the smithing deconstruction buttons and context menu buttons are show, but the checks will still be done "per item", so that glyphs are protected too!
--#203: Mass moving to junk/removing from junk will kick you from the server because of message spam. Junk move will be done in 50 items packages now, with a 250ms delay in between each package.


--[Added on request]
--#176 Add submenu to 4 filter buttons, with setting to change the filter between AND & OR filter conjunction behaviour. Remembers the state for each filterPanel
--->Screenshot showing the new context menu "Filter settings" at the filter button: https://i.imgur.com/32AHUNS.png
--->Screenshot link for tooltip showing new logical conjunction AND/OR state: https://i.imgur.com/yj2UIOe.png
--#183 Add new SavedVariables saving independent to Server and AccountName -> "All servers and accounts the same"
--#185 Add possibility to only reset the SavedVariables of stored marker icons, but keep the other settings. See settings menu bakup & restored & delete -> new submenu "Delete"
```
