# FCOItemSaver
AddOn for the game Elder Scrolls Online: Saving your items so you do not accidently destroy/sell/deconstruct them + many other features.


==Changelog for current beta version ==
```

--#220, 2022-04-02, Caramoon, FCOIS comments: Using the crafting tables deconstruction to filter items with 2x green filters (lock, sell) and 1x yellow (decon) wills till show items
--which got the sell icon active (green> should be hidden) and the decon icon active (yellow > should be shown). Logical conjunction mode: ?? unknown, supposed: AND
--[[
So I recently notice an issue that popped up. When I'm at a crafting table, specifically in the deconstruction mode, when the filter for deconstruction flagged items is yellow (show only) the filter for selling/sell in guild/intricate doesn't have any effect. The happens at all four crafting station types.

The add-ons settings page says I'm running version 224, and everything should be up to date since I use Minion.

Here's a screenshot, and I can provide a video if I'm not describing it well enough.

https://imgur.com/a/hRtnAo7

(the two items are flagged both "decon" and "sell at guild trader")
]]

--____________________________
-- Current max bugs/features/ToDos: 220
--____________________________


------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2022-04-03
------------------------------------------------------------------------------------
--#220 Filter at crafting table deconstruction shows items marked for deconstruction AND sell in guildstore even though only decon marker icon filter is yellow (show only) but sell at guildstore amrker icon is green (hide), and the logical conjunction of the filters is set to AND -> Should check for yellow (only show) AND green (hide) = hide. But works like a logical OR conjunction here.

-------------------------------------------------------------------------------------
--Changelog (last version: 2.2.4 - New version: 2.2.5) -    Updated last: 2022-04-03
-------------------------------------------------------------------------------------
--[Fixed]
--#217 Error at mouse hover over inventory quest items
--#218 Error at LAM settings menu as LAM icon dropdowns are created
--#219 Non set collection items were tried to be bound and chat output told you they were bound


--[Changed]


--[Added]


--[Added on request]
```
