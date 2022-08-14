# FCOItemSaver
AddOn for the game Elder Scrolls Online: Saving your items so you do not accidently destroy/sell/deconstruct them + many other features.

--#238 2022-07-17, Baertram, Feature idea: Speed-up the AddMark function and cache some markId independent checks so that calls to he same function AddMark with the same bagId and slotIndex
-- can reuse the cached results. change of bagId or change of slotIndex will reset the cache.

--#241 2022-08-14, Baertram, Feature idea: Add "Remove all markers" entry to context menu


--______________________________________
-- Current max # of bugs/features/ToDos: 241
--______________________________________


--Todo for this patch
--#238
--#241


------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2022-08-14
------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------
--Changelog (last version: 2.3.1 - New version: 2.3.2) -    Updated last: 2022-08-14
-------------------------------------------------------------------------------------
--[Fixed]

--[Changed]


--[Added]
--#241 Added setting to add a "remove all"/"restore last marker icons" to the context menu of items. You need to enable this at the settings submenu "marker icons" -> "Undo".
--Undo entries saved by SHIFT+right mouse click (if enabled at the settings) or via this new context menu entry will be cleared if you manually set a new marker icon on the same item
--via the inventory context menu!
--Keybinds or mass-marking will not overwrite them.
--Added tooltip setting for that new setting (see above) to show the last marked marker icons at the item if you press and hold the SHIFT key

--[Added on request]
