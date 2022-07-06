# FCOItemSaver
AddOn for the game Elder Scrolls Online: Saving your items so you do not accidently destroy/sell/deconstruct them + many other features.


==Changelog for current beta version ==
```
--______________________________________
-- Current max # of bugs/features/ToDos: 235
--______________________________________


--Todo for this patch
--#233
--TODOS within AwesomeGuildStore:
-->Item drag protection: Working https://github.com/sirinsidiator/ESO-AwesomeGuildStore/blob/master/src/wrappers/SellTabWrapper.lua#L515 -> Calls ZO_InventorySlot_OnReceiveDrag then via "PickupEmoteById" hack
--> TODO !!! AwesomeGuildStore needs to update it's PreHooks of ZO_InventorySlot_OnStart Drag and ZO_InventorySlot_OnReceiveDrag !!!
-->Item drag protection error text: TODO -> Fix within AGS needed!

------------------------------------------------------------------------------------
-- Currently worked on [Added/Fixed/Changed] -              Updated last 2022-07-06
------------------------------------------------------------------------------------
--#233



-------------------------------------------------------------------------------------
--Changelog (last version: 2.2.8 - New version: 2.2.9) -    Updated last: 2022-07-06
-------------------------------------------------------------------------------------
--[Fixed]
--#233 Add support for AwesomeGuildStore and AGS "Sell directly from bank" feature
-->Filter butons: Working
-->Filter buttons after listing an item: Working
-->Item click protection: Working
-->Item click protection error text: Working
-->Item automatic unslot as protected: Working
--TODOS within AwesomeGuildStore:
-->Item drag protection & error text are not working due to PreHooks & return true of AGS in ZO_InventorySlot_OnStart and ZO_InventorySlot_OnReceiveDrag


--[Changed]


--[Added]


--[Added on request]


```
