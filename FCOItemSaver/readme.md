FCO Item Saver
Short form: FCOIS

Frequently asked questions and answers for this addon
https://www.esoui.com/portal.php?id=136&a=faq

New feature: Backup & Restore. Check the changelog of version 1.2.2 and followings

This addon is not supporting the Gamepad/Controller user interface! You can use another adodn like "Disable Advanced Controller UI" to get the menus and inventory work with FCOIS, and use the controller ingame to fight etc. But the total gamepad UI for inventories won't work!

This addon is neither a copy or clone of ItemSaver. It's much more and works differently.

Application is Fast API ready

Last change:
Please read the changelog / click the changelog link at the addon popup inside Minion
https://www.esoui.com/downloads/info630-FCOItemSaver.html#changelog

What's the idea of this addon?
Do you want to get a better overview inside your inventory?
Did you also destroy an item you wanted to keep for higher levels, any research or just sell at the guild store?
Do you want to mark those items somehow so they are easily recognizable in your inventories?
Do you want to get an error message if you try to destroy/deconstruct/sell/trade/equip/read/use/mail/etc. any of your "special" items?
Do you want to confirm the equipping of bindable items before it gets bound to your account?
Do you use several different armor sets and want to mark each armor, weapon & jewelry item with an icon, so you can easily see and switch those sets?
Do you want to mark complete equipped items as a special set (heal, dd, tank, off-tank, quest, etc.)?
Do you want to automatically mark ornate items to select them with 1 click at a vendor?
Do you want to automatically mark intricate items to select them with 1 click at a deconstruction panel?
Do you want to automatically mark your researchable items that you need for your crafting skills (needs the addon "Research Assistant" activated)?
Do you want to automatically mark your set parts (filtered by their trait so only your divine and sharpened stuff gets marked)?
Do you want to automatically mark your non-wished set parts for selling & deconstruction, depending on their item quality?
Do you want to avoid depositing items to a guild bank where you are not able to withdraw (because of missing guild rights) them again?
Do you want to totally set up the marker icons you can use (color, texture, size, etc.)?
Do you want to setup the behaviour for each marker icon differently (save my items so they won't get destroyed but can be mailed, etc.)? -> "Dynamic" icons

This addon will help you with all these points, and many more!

List of features:
Distinguish between unique item IDs (different enchantment, level, style, ...) and non-unique item IDs (same name = same item)
Mark items with several icons (About 60 different icons to choose from) -> You can use keybindings to mark/unmark the icons too
Fully customizable icons (size, color, position, texture)
10 dynamic icons - Each icon can behave different at the same panel! e.g. block an item at the deconstruction panel but allow another one.
Hide/Show/Only show the marked items (filter them with 4 different filters, each assigned to different icons)
Remember each filter state for inventories (bank, player, trade, mail, deconstruction, improvement, enchanting creation, enchanting extraction, guild store, guild bank, craft bag)
Right-Click/Context menus + new buttons at inventories
SHIFT + Right click to remove/reset all shown marker icons (reset will only work until a realoadUI was done somehow, manually or by zone change etc.!)
Mark/Unmark all items at an inventory with one click
Mark/Unmark gear sets with one click
Undo your last action with one click
Block researching/enchanting/deconstruction/destruction/extraction/mail sending/trading/selling for marked items (does also block the keybindings for keyboard players!)
Show confirmation dialog before binding an item to your account (dialog shows the name and color of the item)
Define your own equipment gears (5 different possible, each of them can be disabled) by using different icons & names
Filter your inventories for all equipment gears, or choose one of the equipment gears from a dropdown list (right click the equipment gear filter icon at the bottom of your inventories to show a context-menu)
Filter your inventories for researchable/deconstructable/improvable items, or choose one of these from a dropdown list (right click the research filter icon at the bottom of your inventories to show a context-menu)
Automatically mark ornate items with an icon
Automatically mark intricate items with an icon
Automatically mark researchable items with an icon (addon "ResearchAssistant" must be installed and active!)
Automatically mark known recipes for selling at the guild store (addon "SousChef" must be installed and active and the option 'List Characters Who Know Recipe' must be enabled at the SousChef addon settings!)
Automatically mark unknown recipes (addon "SousChef" must be installed and active and the option 'List Characters Who Know Recipe' must be enabled at the SousChef addon settings!)
Automatically mark new crafted items with an icon (with the possibility to only mark new crafted set parts)
Automatically mark new gained set part items (from your loot) with an icon
Automatically mark set parts (choose which traits will be marked)
Automatically mark non-wished set parts (non chosen traits) with another icon, or make it dependent to the item's quality
Automatically mark set parts that are tracked via addon SetTracker with an FCOItemSaver icon
Block containers from auto looting, even if auto loot is enabled in standard ESO settings
Block recipes from beeing read if they are marked with an icon
Keybindings to filter icons at the current inventory
Keybindings to mark/demark items
Support for several addons, like "CraftBagExtended", "Research Assistant", "AdvancedFilters", "Inventory Grid View", "Khrill Merlin the Enchanter", "Quick Enchanter", "DoItAll", "Chat Merchant", "Dustman", "ESO Master Recipe List" and many other addons
Backup & restore of marked items (you need to do it manually before and after a patch where the itemInstanceIds might get changed by ZOs!). See below at "backup & restore" section.
And many other features
To check all features please have a look at the ingame settings menu.

New - Support for "AdvancedFilters" filter plugins:
Select FCOItemSaver marked items from AdvancedFilters dropdown boxes.
Install this addon: AdvancedFilters plugin - FCOItemSaver

For developers:
Please have a look at the developers section further down in this description text.

The changelog was moved to the appropriate panel, because Minion will finally be able to show the changelog correctly too. Please click on the blue text "Changelog" inside Minion's addon popup.


FCO ItemSaver was developed on base of ingeniousClowns Item Saver!
Meanwhile I've changed ALL the coding and added more icons, filters, features, removed some bugs and non wished behaviours, etc.

This addon eases the handling of your items inside your inventory, bank, player2player trading, mails, guild bank, vendors, guild stores, craft bag etc.
It will provide you 22 different icons (changeable - select from a long list of available icons) for your
inventory items which you can easily activate/remove by the right click mouse menu.
It will provide you with 5 selectable gear set (you choose the description and the icon!).
It will also provide you with the possibilities to mark complete sets at once, with/without weapons and with/without jewelry.

1st icon - Red lock: Intended to show this item as locked for later usage
2nd icon + 4th. icon - Green and light blue helmet: Intended to mark your current equipment (5 different gear sets are possible!) for an easier overview (especially at the repair stations)
3rd icon - Gray analysis icon: Intended to mark your next item(s) for reasearch
5th icon - Yellow coins: Mark item for later selling
6th icon - Another gear set 3
7th icon - Another gear set 4
8th icon - Another gear set 5
9th icon - Deconstruction
10th icon - Improvement
11th icon - Sell at guild store
12th icon - Intricate
13th - 30th icon - Dynamic icons

The following global variables are available for the different icon numbers:
Code:
        FCOIS_CON_ICON_LOCK					= 1
        FCOIS_CON_ICON_GEAR_1				= 2
        FCOIS_CON_ICON_RESEARCH				= 3
        FCOIS_CON_ICON_GEAR_2  				= 4
        FCOIS_CON_ICON_SELL					= 5
        FCOIS_CON_ICON_GEAR_3				= 6
        FCOIS_CON_ICON_GEAR_4				= 7
        FCOIS_CON_ICON_GEAR_5				= 8
        FCOIS_CON_ICON_DECONSTRUCTION		= 9
        FCOIS_CON_ICON_IMPROVEMENT			= 10
        FCOIS_CON_ICON_SELL_AT_GUILDSTORE	= 11
        FCOIS_CON_ICON_INTRICATE			= 12
        FCOIS_CON_ICON_DYNAMIC_1			= 13
        FCOIS_CON_ICON_DYNAMIC_2			= 14
        FCOIS_CON_ICON_DYNAMIC_3			= 15
        FCOIS_CON_ICON_DYNAMIC_4			= 16
        FCOIS_CON_ICON_DYNAMIC_5			= 17
        FCOIS_CON_ICON_DYNAMIC_6			= 18
        FCOIS_CON_ICON_DYNAMIC_7			= 19
        FCOIS_CON_ICON_DYNAMIC_8			= 20
        FCOIS_CON_ICON_DYNAMIC_9			= 21
        FCOIS_CON_ICON_DYNAMIC_10			= 22
        FCOIS_CON_ICON_DYNAMIC_11			= 23
        ...
        FCOIS_CON_ICON_DYNAMIC_30			= 42
In addition this addon provides you 4 filters to hide/show the marked items.
1 for locked items, 1 for the 5 equipment gears, 1 for the research/deconstruction/improvement items and 1 for selling/selling at guild store and intricate items.
You are even able to split the filter buttons, so they will remember their state for each of the above mentioned panels (inventory, crafting stations, vendors, guild stores, etc.)!

Each filter got 3 states, indicated like a traffic light: ON (green), ONLY SHOW MARKED ITEMS (yellow) and OFF (red).

How to use this addon?


Icons:
Simply right-click with your mouse on an item in your inventory/crafting station/bank/guild bank/etc. and choose one of the new "FCOItemSaver" menu entries.
Each item you enable an icon for will change the right-click menu text to the appropriate "disable" afterwards and it'll change the color of the enabled entry too.

Filters:
You are able to enable/disable the filters inside your inventory/the crafting stations/the bank/the guild bank/the trade panel/the mail panel/the vendor panel/the enchanting table creation&extraction, the craftbag and others by clicking the 4 icons at the bottom of your inventory.
Green icon: Filter is enabled. Marked items are hidden
Red icon: Filter is disabled. Marked items are shown.
Yellow icon: Filter is only showing marked items

The yellow filter will always weight more then the green filter. So enabling yellow filters will show the filter's items prior to hiding the other items only filtered with green!

You could also use chat commands to enable the filters.
If you just enter /fcois into the chat you will see a list of ALL chat commands.


Supported chat commands
'help' / 'list': Shows this information about the addon
'status' / '': Shows actually enabled filters
'filter1': Show/Hide category 1 (lock symbol) items
'filter2': Show/Hide category 2 (helmet symbol) items
'filter3': Show/Hide category 3 (research symbol) items
'filter4': Show/Hide category 4 (coins symbol) items
'filter': Show/Hide category 1 - 4 items
'alloff': Show categories 1 to 4 items
'allon': Hide categories 1 to 4 items
'allshow': Only show marked items of categories 1 to 4
'd':	Enable/Disable the debug mode with only some messages shown
-> Adds an entry to the context menu of inventories which shows you the bagId and slotIndex. If you click this entry the chat edit box will get a /zgoo entry where you only need to exchange
the placeholder <iconIdHere> with an FCOIS iconId, and you're able to check if the item is saved in the marker database. The addon will automatically calculate and show you the unique ID used
for that item).
'dd':	Enable/Disable the deep debug mode with more details
'ddd' <value>:	Set the deep debug depth. Value <value> is valid between 1 (less details) and 5 (full details)

Possible <filterPanel> values are (coming from library libFilters 2.0 !):
LF_INVENTORY = 1
LF_BANK_WITHDRAW = 2
LF_BANK_DEPOSIT = 3
LF_GUILDBANK_WITHDRAW = 4
LF_GUILDBANK_DEPOSIT = 5
LF_VENDOR_BUY = 6
LF_VENDOR_SELL = 7
LF_VENDOR_BUYBACK = 8
LF_VENDOR_REPAIR = 9
LF_GUILDSTORE_BROWSE = 10
LF_GUILDSTORE_SELL = 11
LF_MAIL_SEND = 12
LF_TRADE = 13
LF_SMITHING_REFINE = 14
LF_SMITHING_CREATION = 15
LF_SMITHING_DECONSTRUCT = 16
LF_SMITHING_IMPROVEMENT = 17
LF_SMITHING_RESEARCH = 18
LF_ALCHEMY_CREATION = 19
LF_ENCHANTING_CREATION = 20
LF_ENCHANTING_EXTRACTION = 21
LF_PROVISIONING_COOK = 22
LF_PROVISIONING_BREW = 23
LF_FENCE_SELL = 24
LF_FENCE_LAUNDER = 25
LF_CRAFTBAG = 26
LF_QUICKSLOT = 27
LF_RETRAIT = 28
LF_HOUSE_BANK_WITHDRAW = 29
LF_HOUSE_BANK_DEPOSIT = 30
LF_JEWELRY_REFINE = 31
LF_JEWELRY_CREATION = 32
LF_JEWELRY_DECONSTRUCT = 33
LF_JEWELRY_IMPROVEMENT = 34
LF_JEWELRY_RESEARCH = 35
LF_FILTER_MAX = LF_JEWELRY_RESEARCH --35

Possible <filterValue>: true / false / show
'filter1 <filterPanel> <filterValue>': Hide <true> / show <false> / only show marked <show> items of catergory 1 (lock symbol) at panel <filterPanel>
'filter2 <filterPanel> <filterValue>': Hide <true> / show <false> / only show marked <show> items of catergory 2 (helmet symbol) at panel <filterPanel>
'filter3 <filterPanel> <filterValue>': Hide <true> / show <false> / only show marked <show> items of catergory 3 (research symbol) at panel <filterPanel>
'filter4 <filterPanel> <filterValue>': Hide <true> / show <false> / only show marked <show> items of catergory 4 (coins symbol) at panel <filterPanel>
'filter <filterPanel> <filterValue>': Hide <true> / show <false> / only show marked <show> items of catergory 1 to 4 at panel <filterPanel>
'allon <filterPanel>': Hide categories 1 to 4 at panel <filterPanel>
'alloff <filterPanel>': Show categories 1 to 4 at panel <filterPanel>
'allshow <filterPanel>': Only show marked items of the categories 1 to 4 at panel <filterPanel>
'debug': Enable/Disable debug messages. [Attention] This will flood your local chat!

Compatibility
FCOIS is NOT compatible with the gamepad mode!
If you like to use ONLY the gamepad: I'm sorry. I cannot support this (due to missing hardware and time).
If you want to use the gamepad to play, and use keyboard + mouse look-a-like menus, use this addon here which supports FCOIS:
Advanced Disable Controller UI

-Compatible with "Advanced Filters & plugins"
-Compatible with "Research Assistant"
-Compatible with "Inventory Grid View"
-Compatible with "Chat Merchant"
-Compatible with "Merlin the Enchanter"
-Compatible with "Quick Enchanter"
-Compatible with "DoItAll"
-Compatible with "Dustman"
-Compatible with "CraftBagExtended"
-Compatible with "SetTracker"
-Compatible with "DolgubonsLazyWritCreator"
-Compatible with "Inventory Insight"
-Compatible with "Inventory Manager"
-Compatible with "Auto Category"
-Compatible with many other addons


Known bugs
-Items having the same name and level will automatically get the icons activated/deactivated if you only enable it for one of them. As the items got no unique ID and the item names are the same too, this bug comes from the ZOS developers and I can't fix this.

Please report any further bugs via my author portal bugs panel. Thanks.
Thx for your interest.

Many thanks to the following people:
-Lumber, for his French translations
-Snoopy, for his French translations
-maward00, for the bugfix with the research filter
-vaagventje, for the idea to fix the bug with automatically junked items and for many, many bug testing and new ideas!
-Garkin, who is always a helping hand with much knowledge!
-Ayantir, for translating the addon into French
-Circonian, who helped a lot during debugging and testing the performance
-merlight, who recoded the libFilters library and removed some performance bottlenecks with other addons
-Randactyl, for maintaining libFilters and AdvancedFilters
-Kwisatz, for translating into Spanish and French
-Chou, for translating very much into French (French players, visit this website: http://www.elderscrolls-online.fr)
-ForgottenLight, for translating the addon into Russian
-k0ta0uchi, BowMoreLover for translating the addon into Japanese
-Llwydd, for translating the addon into French

For developers

You can check if FCO ItemSaver is loaded and PlayerActivated event has run by using this code:
Lua Code:
If FCOIS then
            ---FCO ItemSaver is loaded
            --Now check if PlayerActivated already run for the addon
            If FCOIS.addonVars.gPlayerActivated then
            --Player activated event finished for FCOIS
            end
        end
Or you could use the library "LibLoadedAddons" to check if the addon is loaded properly.
The library entry for FCOIS is added after the PlayerActivated event was fired, not before!
Lua Code:
local FCOIS_isLoaded, FCOIS_Version = libLoadedAddons:IsAddonLoaded('FCOItemSaver')
        if FCOIS_isLoaded then
            ---FCO ItemSaver is loaded and PlayerActivated was loaded
            d("[FCOItemSaver] is loaded with version " .. tostring(FCOIS_Version))
        end

API functions
There are several API functions to check if an item is filtered, is protected, is protected at a special filter panel (bank withdraw, guildbank deposit, mail send, player 2 player trade, etc.).
Please check the file "FCOIS_API.lua" within the addon folder. The functions are in there and described by their comments.

Backup & Restore of marked items
As the game sometimes changes the itemInstanceIds which the addon relies on to save your marker icons, and you are not always using the unique item IDs to save your marker icons (check ingame addon settings -> general settings -> unique item IDs)
you somehow need to have a backup and restore function for your set marker icons.
The following chat commands (and an addon settings menu entry for Backup & restore) are avilable, which you can use before a patch to backup, and after a patch to restore your set marker icons on your items.
!!! Attention !!! Guild banks:
If you want to backup/restore guild bank marker icons you must open each guild bank at least once before you do the backup/restore or the addon is not able to read the data from it. And the guild bank is not static so other users might change it as well after you had opened them.
So the addon is only using the known info at the time you have opened it!
House storages:
If you want to backup/restore your house banks you need to be in one of your houses as you do the backup/restore!
-> So please open the guild banks once and then port into your house to do a full backup/restore!

The backup/restore will use the game's API version [use this command to get it printed into the chat: /script d(GetAPIVersion()) ] to backup to/restore from. 
You can specify a different API version if you like to to save it to another value/load from this specified value.
If you do not specify an API version via chat commands the game will use the current version for backup, and the current version for restore. If, e.g. after a patch, the current API version got no backuped data, the addon
automatically will try the last API version for the restore (saved data from before the patch)!

Chat commands:
-Chat command for backup (<...> are optional parameters!)
/fcois backup <withDetails> <apiversion> <doClearBackup>

<withDetails> values: true=show each backuped item in chat/false: do not show any backuped item in chat
<apiversion> value:nnnnnn=6digit game API version which you can specify to save the backup with this apiversion. If not specified the current apiversion of the game is used
<doClearBackup> values: true=clear the specified apiversion backup before a new one is started/false=do not clear and keep old backupdata of thespecified api version

-Chat command for restore (<...> are optional parameters!)
/fcois restore <withDetails> <apiversion>
<withDetails> values: true=show each restored item in chat/false: do not show any restored item in chat
<apiversion> value:nnnnnn=6digit game API version which you can specify to load the backup from. If not specified the current apiversion of the game is used and if there is no backupdata for the current apiversion the last apiversion will be checked (e.g. after a patch the apiversion raised and your backup got the last apiversion saved -> the addon will automatically find it then)




Donation
If you like whyt I did and want more features, just want to thank me or say hi, you can send me some comments, ideas, wishes, items or even ingame gold to account "@baertram" on the EU server. I'm happy about any feedback!
Please use the bugs panel to report any found new bugs.
