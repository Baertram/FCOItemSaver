    --Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

--===================== ADDON Info =============================================
--Addon variables
FCOIS.addonVars = {}
local addonVars = FCOIS.addonVars
--Addon variables
addonVars.addonVersionOptions 		    = '2.0.2' -- version shown in the settings panel
addonVars.addonVersionOptionsNumber	    = 2.02
--The addon name, normal and decorated with colors etc.
addonVars.gAddonName				    = "FCOItemSaver"
addonVars.gAddonNameShort               = "FCOIS"
addonVars.addonNameMenu				    = "FCO ItemSaver"
addonVars.addonNameMenuDisplay		    = "|t32:32:FCOItemSaver/FCOIS.dds|t |c00FF00FCO |cFFFF00ItemSaver|r"
addonVars.addonNameContextMenuEntry     = "     - |c22DD22FCO|r ItemSaver -"
addonVars.addonAuthor 				    = '|cFFFF00Baertram|r'
local authorDisplayName                 = '@Baertram'
addonVars.addonAuthorDisplayNameEU      = authorDisplayName
addonVars.addonAuthorDisplayNameNA      = authorDisplayName
addonVars.addonAuthorDisplayNamePTS     = authorDisplayName
local esouiWWWAuthorId                  = 136 -- Baertram ddon authorId at www.esoui.com
local esouiWWWAddonDonationId           = 131 -- FAQ etry Id for the donation
local esouiWWW                          = "https://www.esoui.com"
local esouiWWWAddonAuthorPortalFCOIS    = string.format(esouiWWW .. "/portal.php?&id=%s", tostring(esouiWWWAuthorId))
addonVars.website 					    = esouiWWW .. "/downloads/info630-FCOItemSaver.html"
addonVars.authorPortal                  = esouiWWWAddonAuthorPortalFCOIS
addonVars.FAQwebsite                    = esouiWWWAddonAuthorPortalFCOIS .. "&a=faq"
addonVars.feedback                      = esouiWWWAddonAuthorPortalFCOIS .. "&a=bugreport"
addonVars.donation                      = string.format(addonVars.FAQwebsite .. "&faqid=%s", tostring(esouiWWWAddonDonationId))

--Variables for the addon's load state
addonVars.gAddonLoaded				= false
addonVars.gPlayerActivated			= false
addonVars.gSettingsLoaded			= false

--Dummy SCENE information for file FCOIS_functions.lua -> function FCOIS.getCurrentSceneInfo()
FCOIS.dummyScene = {
    ["name"] = addonVars.gAddonName
}

--Constants for the unique itemId types
--FCOIS v1.9.6
FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE      = 1 --use base game's real uniqueIds by ZOs (even if items are totally the same, their id won't be the same)
FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE    = 2 --use FCOIS calculated uniqueIds based on item values like level,quality,enchantment,style,trait etc.
--The global variable for the use temporary "UniqueIds" API
FCOIS.temporaryUseUniqueIds = {}

--SavedVariables constants
local savedVarsMarkedItems = "markedItems"
addonVars.savedVarName				= addonVars.gAddonName .. "_Settings"
addonVars.savedVarVersion		   	= 0.10 -- Changing this will reset all SavedVariables!
--The subtables for the marked items. markedItems will be used for the non-unique and the ZOs really unique IDs.
--markedItemsFCOISUnique will be used for the FCOIS created unique IDs.
addonVars.savedVarsMarkedItemsNames = {
    [false]                                         = savedVarsMarkedItems,
    [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE]    = savedVarsMarkedItems,
    [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE]  = savedVarsMarkedItems .. "FCOISUnique",
}

FCOIS.svDefaultName                 = "Default"
FCOIS.svAccountWideName             = "$AccountWide"
FCOIS.svAllAccountsName             = "$AllAccounts"
FCOIS.svSettingsForAllName          = "SettingsForAll"
FCOIS.svSettingsName                = "Settings"
FCOIS.svSettingsForEachCharacterName= "SettingsForEachCharacter"

--The global variable for the current mouseDown button
FCOIS.gMouseButtonDown = {}

--Keybindings
FCOIS.keybinds = FCOIS.keybinds or {}

--Data for the protection (colors, textures, ...)
FCOIS.protectedData = {}
FCOIS.protectedData.colors = {
    [false]         = "|cDD2222",
    [true]          = "|c22DD22",
    ["non_active"]  = "|c808080",
}
FCOIS.protectedData.textures = {
    [false]         = "esoui/art/buttons/cancel_up.dds",
    [true]          = "esoui/art/buttons/accept_up.dds",
    ["non_active"]  = "esoui/art/buttons/cancel_up.dds",
}
local protectedColors = FCOIS.protectedData.colors
local protectionOffColor    = protectedColors[false]
local protectionOnColor     = protectedColors[true]
--Local pre chat color variables
FCOIS.preChatVars = {}
--Uncolored "FCOIS" pre chat text for the chat output
FCOIS.preChatVars.preChatText = addonVars.gAddonNameShort
--Green colored "FCOIS" pre text for the chat output
FCOIS.preChatVars.preChatTextGreen = protectionOnColor..FCOIS.preChatVars.preChatText.."|r "
--Red colored "FCOIS" pre text for the chat output
FCOIS.preChatVars.preChatTextRed = protectionOffColor..FCOIS.preChatVars.preChatText.."|r "
--Blue colored "FCOIS" pre text for the chat output
FCOIS.preChatVars.preChatTextBlue = "|c2222DD"..FCOIS.preChatVars.preChatText.."|r "
--Values for the "marked" entries
FCOIS.preChatVars.currentStart = "> "
FCOIS.preChatVars.currentEnd = " <"

--Error text constants
FCOIS.errorTexts = {}
FCOIS.errorTexts["libraryMissing"] = "ERROR: Needed library \'%s\' was not found. Addon is not working!"

--Get the current API version of the server, to distinguish code differences dependant on the API version
FCOIS.APIversion = GetAPIVersion()
FCOIS.APIVersionLength = string.len(FCOIS.APIversion) or 6

--======================================================================================================================
--                  LIBRARIES
--======================================================================================================================
FCOIS.libsLoadedProperly = false

local preVars = FCOIS.preChatVars
local libMissingErrorText = FCOIS.errorTexts["libraryMissing"]

--Load libLoadedAddons
FCOIS.LIBLA = LibLoadedAddons
if FCOIS.LIBLA == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibLoadedAddons")) return end

--Initiliaze the library LibCustomMenu
if LibCustomMenu then FCOIS.LCM = LibCustomMenu else d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibCustomMenu")) return end

--Create the settings panel object of LibAddonMenu 2.0
FCOIS.LAM = LibAddonMenu2
if FCOIS.LAM == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibAddonMenu-2.0")) return end

--The options panel of FCO ItemSaver
FCOIS.FCOSettingsPanel = nil

--Create the libMainMenu 2.0 object
FCOIS.LMM2 = LibMainMenu2
if FCOIS.LMM2 == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibMainMenu-2.0")) return end
FCOIS.LMM2:Init()

--Create the filter object for addon libFilters 3.x
FCOIS.libFilters = {}
FCOIS.libFilters = LibFilters3
if not FCOIS.libFilters then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibFilters-3.0")) return end
--Initialize the libFilters 3.x filters
FCOIS.libFilters:InitializeLibFilters()

--Initialize the library LibDialog
FCOIS.LDIALOG = LibDialog
if not FCOIS.LDIALOG then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibDialog")) return end

--Initialize the library LibFeedback
FCOIS.libFeedback = LibFeedback
if FCOIS.libFeedback == nil and LibStub then FCOIS.libFeedback = LibStub:GetLibrary('LibFeedback', true) end
if not FCOIS.libFeedback then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibFeedback")) return end

--Initialize the library LibShifterBox
FCOIS.libShifterBox = LibShifterBox
if not FCOIS.libShifterBox == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibShifterBox")) return end
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Optional libraries
--LibMultiAccountSets
FCOIS.libMultiAccountSets = LibMultiAccountSets


--All libraries are loaded prolery?
FCOIS.libsLoadedProperly = true

--==========================================================================================================================================
-- 															FCOIS CONSTANTS
--==========================================================================================================================================
--Constant values for the languages
FCOIS_CON_LANG_EN = 1
FCOIS_CON_LANG_DE = 2
FCOIS_CON_LANG_FR = 3
FCOIS_CON_LANG_ES = 4
FCOIS_CON_LANG_IT = 5
FCOIS_CON_LANG_JP = 6
FCOIS_CON_LANG_RU = 7
FCOIS_CON_LANG_MAX = FCOIS_CON_LANG_RU

--Constant values for the whereAreWe panels
FCOIS_CON_DESTROY				= 71
FCOIS_CON_MAIL 					= 72
FCOIS_CON_TRADE 				= 73
FCOIS_CON_BUY					= 74
FCOIS_CON_SELL 					= 75
FCOIS_CON_BUYBACK				= 76
FCOIS_CON_REPAIR    			= 77
FCOIS_CON_IMPROVE 				= 78
FCOIS_CON_DECONSTRUCT 			= 79
FCOIS_CON_ENCHANT_EXTRACT 		= 80
FCOIS_CON_ENCHANT_CREATE 		= 81
FCOIS_CON_GUILD_STORE_SELL 		= 82
FCOIS_CON_FENCE_SELL 			= 83
FCOIS_CON_LAUNDER_SELL 			= 84
FCOIS_CON_ALCHEMY_DESTROY 		= 85
FCOIS_CON_CONTAINER_AUTOOLOOT 	= 86
FCOIS_CON_RECIPE_USAGE 			= 87
FCOIS_CON_MOTIF_USAGE 			= 88
FCOIS_CON_POTION_USAGE 			= 89
FCOIS_CON_FOOD_USAGE 			= 90
FCOIS_CON_CRAFTBAG_DESTROY		= 91
FCOIS_CON_REFINE				= 92
FCOIS_CON_RESEARCH				= 93
FCOIS_CON_RETRAIT               = 94
FCOIS_CON_REFINE				= 95
FCOIS_CON_JEWELRY_REFINE		= 96
FCOIS_CON_JEWELRY_DECONSTRUCT 	= 97
FCOIS_CON_JEWELRY_IMPROVE		= 98
FCOIS_CON_JEWELRY_RESEARCH		= 99
FCOIS_CON_RESEARCH_DIALOG       = 100
FCOIS_CON_JEWELRY_RESEARCH_DIALOG = 101
FCOIS_CON_GUILDBANK_DEPOSIT     = 102
FCOIS_CON_CROWN_ITEM            = 900
FCOIS_CON_FALLBACK 				= 999

--Constant values for the FCOItemSaver filter buttons at the inventories (bottom)
FCOIS_CON_FILTER_BUTTON_LOCKDYN			= 1
FCOIS_CON_FILTER_BUTTON_GEARSETS		= 2
FCOIS_CON_FILTER_BUTTON_RESDECIMP		= 3
FCOIS_CON_FILTER_BUTTON_SELLGUILDINT	= 4

    --The check variables/tables
FCOIS.checkVars = {}
local checkVars = FCOIS.checkVars
FCOIS.checkVars.filterButtonsToCheck = {
    [1] = FCOIS_CON_FILTER_BUTTON_LOCKDYN,
    [2] = FCOIS_CON_FILTER_BUTTON_GEARSETS,
    [3] = FCOIS_CON_FILTER_BUTTON_RESDECIMP,
    [4] = FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
}
--Constants for the automatic set item marking, non wished traits:
FCOIS_CON_NON_WISHED_LEVEL      = 1
FCOIS_CON_NON_WISHED_QUALITY    = 2
FCOIS_CON_NON_WISHED_ALL        = 3


--Build local localization/language variables which will be transfered to the real localization vars in file /src/FCOIS_localization.lua,
--in function Localization()
FCOIS.localLocalizationsVars = {}

    --The table of number variables
FCOIS.numVars = {}
local numVars = FCOIS.numVars
--Global value: Number of filter icons to choose by right click menu
numVars.languageCount = FCOIS_CON_LANG_MAX --English, German, French, Spanish, Italian, Japanese, Russian
--Global: Count of available inventory filter types (LF_INVENTORY, LF_BANK_WITHDRAW, etc. -> see above)
numVars.gFCONumFilterInventoryTypes = FCOIS.libFilters.GetMaxFilterTypes and FCOIS.libFilters:GetMaxFilterTypes() or FCOIS.libFilters:GetMaxFilter() -- Maximum libFilters 3.0 filter types
--Global value: Number of filters
numVars.gFCONumFilters			= #checkVars.filterButtonsToCheck
--Global value: Number of non-dynamic and non gear set icons
numVars.gFCONumNonDynamicIcons	= 7
--Global value: Number of gear sets
numVars.gFCONumGearSetsStatic  	= 5
numVars.gFCONumGearSets			= numVars.gFCONumGearSetsStatic
--Global value: Number of non-dynamic normal + gear sets
numVars.gFCONumNonDynamicAndGearIcons	= numVars.gFCONumNonDynamicIcons + numVars.gFCONumGearSetsStatic
--Global value: Number of MAX dynamic icons
numVars.gFCOMaxNumDynamicIcons	= 30
--Global value: Number of dynamic icons
numVars.gFCONumDynamicIcons		= 10
local numMaxDynamicIcons        = numVars.gFCOMaxNumDynamicIcons

--The maximum number at the ITEMTYPE constants
local itemTypeMaxFallback = ITEMTYPE_GROUP_REPAIR --71, 2020-12-25
local itemTypeStringConstantPrefix = "SI_ITEMTYPE"
FCOIS.localLocalizationsVars.ItemTypes = {}
local maxItemTypesForLoop = 150
local maxItemTypesFound
--Now get all names of the ItemTypes, from 1 to maxItemTypesForLoop and check if the String constant exists.
--If yes: Update the maximum itemTypes found. If not: Abort and use the maximum itemTypes found for the numVars.maxItemType
for itemType = 1, maxItemTypesForLoop, 1 do
    local itemTypeText = ZO_CachedStrFormat(SI_UNIT_NAME, GetString(itemTypeStringConstantPrefix, itemType))
    if itemTypeText ~= nil and itemTypeText ~= 0 and itemTypeText ~= "" then
        FCOIS.localLocalizationsVars.ItemTypes[itemType] = itemTypeText
        maxItemTypesFound = itemType
    else
        break
    end
end
numVars.maxItemType = maxItemTypesFound or itemTypeMaxFallback

--Possible icon IDs
--and possible context menus for the filter buttons: RESDECIMP and SELLGUILDINT
--[[
     1 = Lock symbol            (LOCK)
     2 = Gear set 1
     3 = Research					(RES)
     4 = Gear set 2
     5 = Sell							(SELL)
     6 = Gear set 3
     7 = Gear set 4
     8 = Gear set 5
     9 = Deconstruction				(DEC)
    10 = Improvement				(IMP)
    11 = Sell at guild store			(GUILD)
    12 = Intricate						(INT)
    13 = Dynamic 1				(DYN)
    14 = Dynamic 2              (DYN)
    15 = Dynamic 3				(DYN)
    16 = Dynamic 4              (DYN)
    17 = Dynamic 5				(DYN)
    18 = Dynamic 6              (DYN)
    19 = Dynamic 7				(DYN)
    20 = Dynamic 8              (DYN)
    22 = Dynamic 9              (DYN)
    22 = Dynamic 10             (DYN)
    23 .. 42 = Dynamic 11 -- Dynamic 30 (DYN)
]]
--Constant values for the FCOItemSaver marker icons
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
--[[
----Changed to dynamically created variables and added to global namespace
]]
local dynamicIconPrefix = "FCOIS_CON_ICON_DYNAMIC_"
local markerIconsBefore = FCOIS_CON_ICON_INTRICATE --12
for dynIconNr = 1, numMaxDynamicIcons, 1 do
	markerIconsBefore = markerIconsBefore + 1
	_G[dynamicIconPrefix .. tostring(dynIconNr)] = markerIconsBefore
end
--The maximum marker icons variable
numVars.gFCONumFilterIcons = FCOIS_CON_ICON_DYNAMIC_30 --42, since FCOIS version 1.4.0
--Special icon constants
FCOIS_CON_ICON_ALL					= -1    --All marker icons
FCOIS_CON_ICON_NONE					= -100  --No marker icon selected


--Debug depth levels
FCOIS_DEBUG_DEPTH_QUICK_DEBUG   = 0
FCOIS_DEBUG_DEPTH_NORMAL        = 1
FCOIS_DEBUG_DEPTH_DETAILED	    = 2
FCOIS_DEBUG_DEPTH_VERY_DETAILED	= 3
FCOIS_DEBUG_DEPTH_SPAM		    = 4
FCOIS_DEBUG_DEPTH_ALL			= 5

--The inventory row patterns for the supported keybindings and MouseOverControl checks (SHIFT+right mouse functions e.g.)
--See file src/FCOIS_Functions.lua, function FCOIS.GetBagAndSlotFromControlUnderMouse()
checkVars.inventoryRowPatterns = {
[1] = "^ZO_%a+Backpack%dRow%d%d*",                                          --Inventory backpack
[2] = "^ZO_%a+InventoryList%dRow%d%d*",                                     --Inventory backpack
[3] = "^ZO_CharacterEquipmentSlots.+$",                                     --Character
[4] = "^ZO_CraftBagList%dRow%d%d*",                                         --CraftBag
[5] = "^ZO_Smithing%aRefinementPanelInventoryBackpack%dRow%d%d*",           --Smithing refinement
[6] = "^ZO_RetraitStation_%a+RetraitPanelInventoryBackpack%dRow%d%d*",      --Retrait
[7] = "^ZO_QuickSlotList%dRow%d%d*",                                        --Quickslot
[8] = "^ZO_RepairWindowList%dRow%d%d*",                                     --Repair at vendor
[9] = "^ZO_ListDialog1List%dRow%d%d*",                                      --List dialog (Repair, Recharge, Enchant, Research)
--Other adons like IIfA will be added dynamically at EVENT_ON_ADDON_LOADED callback function
--See file src/FCOIS_Events.lua, call to function FCOIS.checkIfOtherAddonActive() -> See file
-- src/FCOIS_OtherAddons.lua, function FCOIS.checkIfOtherAddonActive()
}


--Array for the mapping between variables and values
FCOIS.mappingVars = {}
local mappingVars = FCOIS.mappingVars
mappingVars.noEntry = "-------------"
mappingVars.noEntryValue = 1
local noEntry = mappingVars.noEntry
--Local last variables
FCOIS.lastVars = {}
--Local override variables
FCOIS.overrideVars = {}
--Local counter variables
FCOIS.countVars = {}
--Local guild bank variables
FCOIS.guildBankVars = {}
FCOIS.guildBankVars.guildBankId = 0
--Local filter button variables
FCOIS.filterButtonVars = {}
local filterButtonVars = FCOIS.filterButtonVars
--Local equipment variables
FCOIS.equipmentVars = {}
--Local icon variables
FCOIS.iconVars = {}
--Local custom menu vars
FCOIS.customMenuVars = {}
--Local context menu relating variables
FCOIS.contextMenuVars			= {}
local contextMenuVars = FCOIS.contextMenuVars
--Local inventory additional button variables
FCOIS.invAdditionalButtonVars = {}
local invAddButtonVars = FCOIS.invAdditionalButtonVars
-- Local variables for other addons
FCOIS.otherAddons = {}
-- Local variables for improvement
FCOIS.improvementVars = {}
--Handlers for the check functions (e.g. FCOIS.IsItemprotected() in file FCOIS_Protection.lua)
FCOIS.checkHandlers = {}

--Last item's markers (set by clicking the divider if enabled in the settings)
FCOIS.lastMarkedIcons			= nil

--Improvement re-marking of items
FCOIS.improvementVars.improvementBagId		= nil
FCOIS.improvementVars.improvementSlotIndex	= nil
FCOIS.improvementVars.improvementMarkedIcons = {}

--Entries for the context menu submenu entries, and the dynamic icons submenu entries
FCOIS.customMenuVars.customMenuSubEntries		= {}
FCOIS.customMenuVars.customMenuDynSubEntries	= {}
FCOIS.customMenuVars.customMenuCurrentCounter 	= 0
contextMenuVars.contextMenuIndex 			= -1

--The allowed check handlers (see function FCOIS.checkIfItemIsProtected() in file FCOIS_Protection.lua)
FCOIS.checkHandlers["gear"]     = true
FCOIS.checkHandlers["dynamic"]  = true

--The mapping between the FCOIS settings ID and the real server name (for the SavedVars)
mappingVars.serverNames = {
    [1] = noEntry,           -- None
    [2] = "EU Megaserver",   -- EU
    [3] = "NA Megaserver",   -- US, North America
    [4] = "PTS",             -- PTS
}

--The bagId to player inventory type mapping
mappingVars.bagToPlayerInv = {
    [BAG_BACKPACK]          = INVENTORY_BACKPACK,
    [BAG_SUBSCRIBER_BANK]   = INVENTORY_BANK,
    [BAG_BANK]              = INVENTORY_BANK,
    [BAG_HOUSE_BANK_ONE]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_TWO]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_THREE]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_FOUR]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_FIVE]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_SIX]    = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_SEVEN]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_EIGHT]  = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_NINE]   = INVENTORY_HOUSE_BANK,
    [BAG_HOUSE_BANK_TEN]    = INVENTORY_HOUSE_BANK,
    [BAG_GUILDBANK]         = INVENTORY_GUILD_BANK,
    [BAG_VIRTUAL]           = INVENTORY_CRAFT_BAG,
}
--The mapping table for the bagIds where an itemInstanceId or uniqueId should be build for, in other addons, in order
--to use these for the (un)marking of items (e.g. within addon Inventory Insight from ashes, IIfA)
mappingVars.bagsToBuildItemInstanceOrUniqueIdFor =  {
    --non account wide, as it used bagId and slotIndex
    [BAG_WORN]              = true,
    --non account wide, as it used bagId and slotIndex
    [BAG_BACKPACK]          = true,
    --Account wide but guild bank bag contents will be "flushed" everytime you change the guild bank so you need the ID to identify items of non-current guild banks too
    [BAG_GUILDBANK]         = true,
    --Account wide but house bank bag contents will be "flushed" everytime you change the house bank so you need the ID to identify items of non-current house banks too
    [BAG_HOUSE_BANK_ONE]    = true,
    [BAG_HOUSE_BANK_TWO]    = true,
    [BAG_HOUSE_BANK_THREE]  = true,
    [BAG_HOUSE_BANK_FOUR]   = true,
    [BAG_HOUSE_BANK_FIVE]   = true,
    [BAG_HOUSE_BANK_SIX]    = true,
    [BAG_HOUSE_BANK_SEVEN]  = true,
    [BAG_HOUSE_BANK_EIGHT]  = true,
    [BAG_HOUSE_BANK_NINE]   = true,
    [BAG_HOUSE_BANK_TEN]    = true,
}
--The array for the mapping between the "WhereAreWe" (e.g. in ItemSelectionHandler function) and the filter panel ID
mappingVars.whereAreWeToFilterPanelId = {
    	[FCOIS_CON_DESTROY]				=	LF_INVENTORY,
    	[FCOIS_CON_MAIL]				=	LF_MAIL_SEND,
    	[FCOIS_CON_TRADE]				=	LF_TRADE,
    	[FCOIS_CON_BUY]				    =	LF_VENDOR_BUY,
        [FCOIS_CON_SELL]				=	LF_VENDOR_SELL,
        [FCOIS_CON_BUYBACK]				=	LF_VENDOR_BUYBACK,
        [FCOIS_CON_REPAIR]				=	LF_VENDOR_REPAIR,
    	[FCOIS_CON_REFINE]				=	LF_SMITHING_REFINE,
    	[FCOIS_CON_DECONSTRUCT]			=	LF_SMITHING_DECONSTRUCT,
		[FCOIS_CON_IMPROVE]				=	LF_SMITHING_IMPROVEMENT,
        [FCOIS_CON_RESEARCH]			=	LF_SMITHING_RESEARCH,
    	[FCOIS_CON_ENCHANT_EXTRACT]		=	LF_ENCHANTING_EXTRACTION,
    	[FCOIS_CON_ENCHANT_CREATE]		=	LF_ENCHANTING_CREATION,
    	[FCOIS_CON_GUILD_STORE_SELL]	=	LF_GUILDSTORE_SELL,
    	[FCOIS_CON_FENCE_SELL]			=	LF_FENCE_SELL,
    	[FCOIS_CON_LAUNDER_SELL]		=	LF_FENCE_LAUNDER,
    	[FCOIS_CON_ALCHEMY_DESTROY]		=	LF_ALCHEMY_CREATION,
    	[FCOIS_CON_CONTAINER_AUTOOLOOT]	=	LF_INVENTORY,
    	[FCOIS_CON_RECIPE_USAGE]		=	LF_INVENTORY,
    	[FCOIS_CON_MOTIF_USAGE]			=	LF_INVENTORY,
    	[FCOIS_CON_POTION_USAGE]		=	LF_INVENTORY,
    	[FCOIS_CON_FOOD_USAGE]			=	LF_INVENTORY,
    	[FCOIS_CON_CRAFTBAG_DESTROY]	=	LF_CRAFTBAG,
		[FCOIS_CON_RESEARCH]			=   LF_SMITHING_RESEARCH,
        [FCOIS_CON_FALLBACK]			=	LF_INVENTORY, -- Fallback. Used e.g. for the bank/guild bank deposit checks
        [FCOIS_CON_RETRAIT]             =   LF_RETRAIT,
        [FCOIS_CON_JEWELRY_REFINE]		=	LF_JEWELRY_REFINE,
        [FCOIS_CON_JEWELRY_DECONSTRUCT]	=	LF_JEWELRY_DECONSTRUCT,
        [FCOIS_CON_JEWELRY_IMPROVE]		=	LF_JEWELRY_IMPROVEMENT,
        [FCOIS_CON_JEWELRY_RESEARCH]	=   LF_JEWELRY_RESEARCH,
        [FCOIS_CON_RESEARCH_DIALOG]	    =   LF_SMITHING_RESEARCH_DIALOG,
        [FCOIS_CON_JEWELRY_RESEARCH_DIALOG] = LF_JEWELRY_RESEARCH_DIALOG,
}
--The array for the mapping between the LibFilters FilterPanelId and the "WhereAreWe" (e.g. used in ItemSelectionHandler function)
mappingVars.filterPanelIdToWhereAreWe = {}
for whereAreWe, filterPanelId in pairs(mappingVars.whereAreWeToFilterPanelId) do
    mappingVars.filterPanelIdToWhereAreWe[filterPanelId] = whereAreWe
end

--The array with the alert message texts for every filterPanel
mappingVars.whereAreWeToAlertmessageText = {}

--The active filter panel Ids (filter panel Id = inventory types above!)
mappingVars.activeFilterPanelIds			= {
	[LF_INVENTORY] 					= true,
	[LF_BANK_WITHDRAW] 			   	= true,
	[LF_BANK_DEPOSIT]				= true,
	[LF_GUILDBANK_WITHDRAW] 	    = true,
	[LF_GUILDBANK_DEPOSIT]	    	= true,
    [LF_VENDOR_BUY] 				= false, -- Disabled, as no filter buttons/marker icons needed atm.
	[LF_VENDOR_SELL] 				= true,
    [LF_VENDOR_BUYBACK]				= false, -- Disabled, as no filter buttons/marker icons needed atm.
    [LF_VENDOR_REPAIR] 				= false, -- Disabled, as no filter buttons/marker icons needed atm.
	[LF_GUILDSTORE_SELL] 	 		= true,
	[LF_SMITHING_REFINE]  			= true,
	[LF_SMITHING_DECONSTRUCT]  		= true,
	[LF_SMITHING_IMPROVEMENT]		= true,
    [LF_SMITHING_RESEARCH]          = false,  -- Disabled, as no filter buttons/marker icons needed atm.
    [LF_SMITHING_RESEARCH_DIALOG]   = true,
	[LF_MAIL_SEND] 					= true,
	[LF_TRADE] 						= true,
	[LF_ENCHANTING_CREATION]		= true,
	[LF_ENCHANTING_EXTRACTION]		= true,
	[LF_FENCE_SELL] 				= true,
	[LF_FENCE_LAUNDER]				= true,
	[LF_ALCHEMY_CREATION]			= true,
    [LF_CRAFTBAG]					= true,
    [LF_RETRAIT]                    = true,
    [LF_HOUSE_BANK_WITHDRAW]        = true,
    [LF_HOUSE_BANK_DEPOSIT]         = true,
	[LF_JEWELRY_REFINE]		        = true,
	[LF_JEWELRY_DECONSTRUCT]		= true,
	[LF_JEWELRY_IMPROVEMENT]		= true,
    [LF_JEWELRY_RESEARCH]		    = false,  -- Disabled, as no filter buttons/marker icons needed atm.
    [LF_JEWELRY_RESEARCH_DIALOG]   = true,
}

--The LibFilters panelIds where deconstruction can happen
mappingVars.panelIdToDeconstructable = {
    --Deconstructable
    [LF_SMITHING_DECONSTRUCT]       = true,
    [LF_JEWELRY_DECONSTRUCT]        = true,
    --Not deconstructable
    -->Filled in FCOIS_Settings.lua, function AfterSettings() upon load of the addon for all other
    -->panelIds (from table mappingVars.activeFilterPanelIds above) as key, and the value = false
}

--The mapping array between LibFilters IDs to their filter name string "prefix"
FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID    = 0
FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS        = addonVars.gAddonNameShort .. "_"
mappingVars.libFiltersIds2StringPrefix = {
    --Backup entry if string for LibFilters ID is not given inside this array!
    [FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID] = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "LibFiltersIdFilter_",
    --All other libFilter ID string prefixes
    [LF_INVENTORY]                              = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "PlayerInventoryFilter_",
    [LF_BANK_WITHDRAW]                          = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "PlayerBankFilter_",
    [LF_BANK_DEPOSIT]                           = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "PlayerBankInventoryFilter_",
    [LF_GUILDBANK_WITHDRAW]                     = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "GuildBankFilter_",
    [LF_GUILDBANK_DEPOSIT]                      = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "GuildBankInventoryFilter_",
    [LF_VENDOR_SELL]                            = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "VendorFilter_",
    [LF_SMITHING_REFINE]                        = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "RefinementFilter_",
    [LF_SMITHING_DECONSTRUCT]                   = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "DeconstructionFilter_",
    [LF_SMITHING_IMPROVEMENT]                   = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "ImprovementFilter_",
    [LF_JEWELRY_REFINE]                         = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "JewelryRefinementFilter_",
    [LF_JEWELRY_DECONSTRUCT]                    = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "JewelryDeconstructionFilter_",
    [LF_JEWELRY_IMPROVEMENT]                    = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "JewelryImprovementFilter_",
    [LF_SMITHING_RESEARCH]                      = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "ResearchFilter_",
    [LF_SMITHING_RESEARCH_DIALOG]               = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "ResearchDialogFilter_",
    [LF_JEWELRY_RESEARCH]                       = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "JewelryResearchFilter_",
    [LF_JEWELRY_RESEARCH_DIALOG]                = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "JewelryResearchDialogFilter_",
    [LF_GUILDSTORE_SELL]                        = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "GuildStoreSellFilter_",
    [LF_MAIL_SEND]                              = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "MailFilter_",
    [LF_TRADE]                                  = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "Player2PlayerFilter_",
    [LF_ENCHANTING_EXTRACTION]                  = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "EnchantingExtractionFilter_",
    [LF_ENCHANTING_CREATION]                    = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "EnchantingCreationFilter_",
    [LF_FENCE_SELL]                             = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "FenceFilter_",
    [LF_FENCE_LAUNDER]                          = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "LaunderFilter_",
    [LF_ALCHEMY_CREATION]                       = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "AlchemyFilter_",
    [LF_CRAFTBAG]                               = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "CraftBagFilter_",
    [LF_RETRAIT]                                = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "RetraitFilter_",
    [LF_HOUSE_BANK_WITHDRAW]                    = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "HouseBankFilter_",
    [LF_HOUSE_BANK_DEPOSIT]                     = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "HouseBankInventoryFilter_",
}
--Mapping array for the LibFilters filter panel ID to filter function
--> This array will be filled in file src/FCOIS_Filters.lua, function "FCOIS.mapLibFiltersIds2FilterFunctionsNow()"
mappingVars.libFiltersId2filterFunction = {}

local function getHouseBankBagId()
    local houseBankBagId = GetBankingBag() or BAG_HOUSE_BANK_ONE
    return houseBankBagId
end

--Mapping array for the LibFilters filter panel ID to inventory bag ID (if relation is 1:1!)
mappingVars.libFiltersId2BagId = {
    [LF_INVENTORY]                              = BAG_BACKPACK,
    [LF_BANK_WITHDRAW]                          = BAG_BANK,
    [LF_BANK_DEPOSIT]                           = BAG_BACKPACK,
    [LF_GUILDBANK_WITHDRAW]                     = BAG_GUILDBANK,
    [LF_GUILDBANK_DEPOSIT]                      = BAG_BACKPACK,
    [LF_VENDOR_SELL]                            = BAG_BACKPACK,
    [LF_SMITHING_REFINE]                        = nil,
    [LF_SMITHING_DECONSTRUCT]                   = nil,
    [LF_SMITHING_IMPROVEMENT]                   = nil,
    [LF_JEWELRY_REFINE]                         = nil,
    [LF_JEWELRY_DECONSTRUCT]                    = nil,
    [LF_JEWELRY_IMPROVEMENT]                    = nil,
    [LF_SMITHING_RESEARCH]                      = nil,
    [LF_SMITHING_RESEARCH_DIALOG]               = nil,
    [LF_JEWELRY_RESEARCH]                       = nil,
    [LF_JEWELRY_RESEARCH_DIALOG]                = nil,
    [LF_GUILDSTORE_SELL]                        = BAG_BACKPACK,
    [LF_MAIL_SEND]                              = BAG_BACKPACK,
    [LF_TRADE]                                  = BAG_BACKPACK,
    [LF_ENCHANTING_EXTRACTION]                  = nil,
    [LF_ENCHANTING_CREATION]                    = nil,
    [LF_FENCE_SELL]                             = BAG_BACKPACK,
    [LF_FENCE_LAUNDER]                          = BAG_BACKPACK,
    [LF_ALCHEMY_CREATION]                       = nil,
    [LF_CRAFTBAG]                               = BAG_VIRTUAL,
    [LF_RETRAIT]                                = nil,
    [LF_HOUSE_BANK_WITHDRAW]                    = getHouseBankBagId(),
    [LF_HOUSE_BANK_DEPOSIT]                     = BAG_BACKPACK,
}

--The scene names to add register a callback for StateChange to hide the FCOIS context menu(s).
mappingVars.sceneControlsToRegisterStateChangeForContextMenu = {
    MAIL_INBOX_SCENE,
    QUEST_JOURNAL_SCENE,
    KEYBOARD_GROUP_MENU_SCENE,
    LORE_LIBRARY_SCENE,
    LORE_READER_INVENTORY_SCENE,
    LORE_READER_LORE_LIBRARY_SCENE,
    LORE_READER_INTERACTION_SCENE,
    TREASURE_MAP_INVENTORY_SCENE,
    TREASURE_MAP_QUICK_SLOT_SCENE,
    GAME_MENU_SCENE,
    LEADERBOARDS_SCENE,
    WORLD_MAP_SCENE,
    HELP_CUSTOMER_SUPPORT_SCENE,
    FRIENDS_LIST_SCENE,
    IGNORE_LIST_SCENE,
    GUILD_HOME_SCENE,
    GUILD_ROSTER_SCENE,
    GUILD_RANKS_SCENE,
    GUILD_HERALDRY_SCENE,
    GUILD_HISTORY_SCENE,
    GUILD_CREATE_SCENE,
    NOTIFICATIONS_SCENE,
    GUILD_HISTORY_SCENE,
    CAMPAIGN_BROWSER_SCENE,
    CAMPAIGN_OVERVIEW_SCENE,
    STATS_SCENE,
    SIEGE_BAR_SCENE,
    CHAMPION_PERKS_SCENE,
}

--[[
    * CRAFTING_TYPE_ALCHEMY
    * CRAFTING_TYPE_BLACKSMITHING
    * CRAFTING_TYPE_CLOTHIER
    * CRAFTING_TYPE_ENCHANTING
    * CRAFTING_TYPE_INVALID
    * CRAFTING_TYPE_JEWELRYCRAFTING
    * CRAFTING_TYPE_PROVISIONING
    * CRAFTING_TYPE_WOODWORKING
]]
--The mapping table for crafting mode and type to the libFilters filter panel ID
mappingVars.craftingModeAndCraftingTypeToFilterPanelId = {
    [SMITHING_MODE_ROOT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_REFINE,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_REFINE,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_REFINE,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_REFINE,
    },
    [SMITHING_MODE_CREATION] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_CREATION,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_CREATION,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_CREATION,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_CREATION,
    },
    [SMITHING_MODE_REFINEMENT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_REFINE,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_REFINE,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_REFINE,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_REFINE,
    },
    [SMITHING_MODE_DECONSTRUCTION] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_DECONSTRUCT,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_DECONSTRUCT,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_DECONSTRUCT,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_DECONSTRUCT,
    },
    [SMITHING_MODE_IMPROVEMENT] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_IMPROVEMENT,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_IMPROVEMENT,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_IMPROVEMENT,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_IMPROVEMENT,
    },
    [SMITHING_MODE_RESEARCH] = {
        [CRAFTING_TYPE_JEWELRYCRAFTING] = LF_JEWELRY_RESEARCH,
        [CRAFTING_TYPE_BLACKSMITHING]   = LF_SMITHING_RESEARCH,
        [CRAFTING_TYPE_CLOTHIER]        = LF_SMITHING_RESEARCH,
        [CRAFTING_TYPE_WOODWORKING]     = LF_SMITHING_RESEARCH,
    },
}

--The supported vendor LibFilters panel IDs
mappingVars.supportedVendorPanels = {
    [LF_VENDOR_BUY]     = true,
    [LF_VENDOR_SELL]    = true,
    [LF_VENDOR_BUYBACK] = true,
    [LF_VENDOR_REPAIR]  = true,
}


--Global variable to tell where the filtering is currently needed (Inventory, Bank, Crafting Station, Guild Bank, Guild Store, Mail, Trading, Vendor, Enchanting table, fence)
-- Standard filtering: Inside player inventory (LF_INVENTORY)
FCOIS.gFilterWhere		   		= LF_INVENTORY
--Global variable to tell which filter panel is the parent of FCOIS.gFilterWhere.
--Needed for the CraftBag addon where the parent is the mail panel e.g. but the actual filterPanel is the CraftBag then
FCOIS.gFilterWhereParent		= nil
--Global variable to tell which filter was clicked/used by chat command at last
FCOIS.lastVars.gLastFilterId               = {}

--Available languages
FCOIS.langVars = {}
FCOIS.langVars.languages = {}
--Build the languages array
for i=1, numVars.languageCount do
	FCOIS.langVars.languages[i] = true
end

--Width and height for the icons
FCOIS.iconVars.minIconSize                          = 4
FCOIS.iconVars.maxIconSize                          = 48
FCOIS.iconVars.gIconWidth							= 32
FCOIS.iconVars.gIconHeight             				= 32
FCOIS.iconVars.minIconOffsetLeft                    = -30
FCOIS.iconVars.maxIconOffsetLeft                    = 525
FCOIS.iconVars.minIconOffsetTop                     = -30
FCOIS.iconVars.maxIconOffsetTop                     = 30

--Width and height for the equipment icons
FCOIS.equipmentVars.gEquipmentIconWidth 			= 20
FCOIS.equipmentVars.gEquipmentIconHeight			= 20
--Width and height for the equipment armor type icons
FCOIS.equipmentVars.gEquipmentArmorTypeIconHeight	= 16
FCOIS.equipmentVars.gEquipmentArmorTypeIconWidth 	= 16
--Width and height for the filter buttons - Default values
-->Will be read within file /Src/FCOIS_FilterButtons.lua, function GetFilterButtonDataByPanelId(libFiltersPanelId)
filterButtonVars.gFilterButtonWidth			        = 24
filterButtonVars.gFilterButtonHeight     	        = 24
filterButtonVars.minFilterButtonWidth               = 4
filterButtonVars.maxFilterButtonWidth               = 128
filterButtonVars.minFilterButtonHeight              = 4
filterButtonVars.maxFilterButtonHeight              = 128
--Left and top of the filter buttons
filterButtonVars.gFilterButtonTop			        = 6
filterButtonVars.gFilterButtonLeft	   		= {
 [FCOIS_CON_FILTER_BUTTON_LOCKDYN] 		= 0,
 [FCOIS_CON_FILTER_BUTTON_GEARSETS] 	= 24,
 [FCOIS_CON_FILTER_BUTTON_RESDECIMP] 	= 48,
 [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]	= 72,
}
--Filter button offset Y at the improvement panel bottom (due to the extra "improvement booster bar")
filterButtonVars.buttonOffsetYImprovement = 7

--Filter button offset on x axis, if InventoryGriView addon is active too
FCOIS.otherAddons.gGriedViewOffsetX			= 26
--Variables for the test if the Addon "Inventory Gridview" is enabled
FCOIS.otherAddons.GRIDVIEWBUTTON    		= "ZO_PlayerInventory_GridButton"

FCOIS.otherAddons.inventoryGridViewActive = false
--For the test, if the addon "Chat Merchant" is enabled
FCOIS.otherAddons.CHATMERCHANTBUTTON 		= "ZO_PlayerInventory_CMbutton"
FCOIS.otherAddons.chatMerchantActive 		= false
--For the test, if the addon "Research Assistant" is enabled
FCOIS.otherAddons.researchAssistantActive	= false
--For the test, if the addon "PotionMaker" is enabled
FCOIS.otherAddons.potionMakerActive		= false
--For the test, if the addon "Votans Settings Menu" is enabled
FCOIS.otherAddons.votansSettingsMenuActive= false
--For the test, if the addon "sousChef" is enabled
FCOIS.otherAddons.sousChefActive = false
--For the test, if the addon "CraftStoreFixedAndImprovedActive" is enabled
FCOIS.otherAddons.craftStoreFixedAndImprovedActive = false
--For the test, if the addon "CraftBagExtended" is enabled
FCOIS.otherAddons.craftBagExtendedActive = false
FCOIS.otherAddons.craftBagExtendedSupportedFilterPanels = {
    [LF_GUILDBANK_DEPOSIT]  =   true,
    [LF_BANK_DEPOSIT]       =   true,
    [LF_GUILDBANK_WITHDRAW] =   true,
    [LF_MAIL_SEND]          =   true,
    [LF_GUILDSTORE_SELL]    =   true,
    [LF_TRADE]              =   true,
	[LF_VENDOR_SELL]		=   true,
    [LF_HOUSE_BANK_DEPOSIT] =   true,
}
--For the addon SetTracker
FCOIS.otherAddons.SetTracker = {}
FCOIS.otherAddons.SetTracker.isActive = false
--For the addon AwesomeGuildStore (Craftbag support at guild sell tab) is enabled
FCOIS.otherAddons.AGSActive = false
--For the addon AdvancedDisableController UI is enabled
FCOIS.otherAddons.ADCUIActive = false
--For the test, if the addon "LazyWritCreator" is enabled
FCOIS.otherAddons.LazyWritCreatorActive = false
--For the QualitySort addon which is moving the "name" sort header to the left by n (currently 80) pixles
FCOIS.otherAddons.qualitySortActive = false
FCOIS.otherAddons.QualitySortOffsetX = 80 + 1 -- +1 as there seems to be a small space left compared to the other positions: Moving "name" sort header to the left on x axis by this pixels. See file QualitySort.lua, line 256ff (function QualitySort.addSortByQuality(flag))
--For the AdvancedFilters plugin AF_FCODuplicateItemsFilter
FCOIS.otherAddons.AFFCODuplicateItemFilter = false
--For the Inventory Insight from ashes addon
FCOIS.otherAddons.IIFAActive = false
FCOIS.otherAddons.IIFAitemsListName = "IIFA_GUI_ListHolder"
FCOIS.otherAddons.IIFAitemsListEntryPre = "IIFA_ListItem_"
FCOIS.otherAddons.IIFAitemsListEntryPrePattern = FCOIS.otherAddons.IIFAitemsListEntryPre .. "%d"
--External addon constants
FCOIS.otherAddons.IIFAaddonCallName = "IIfA"
--Possible external addon call names
FCOIS.otherAddons.possibleExternalAddonCalls = {
    [1] = FCOIS.otherAddons.IIFAaddonCallName
}
--The recipe addons which are supported by FCOIS
FCOIS_RECIPE_ADDON_SOUSCHEF = 1
FCOIS_RECIPE_ADDON_CSFAI    = 2
FCOIS.otherAddons.recipeAddonsSupported = {
    [FCOIS_RECIPE_ADDON_SOUSCHEF]   = "SousChef",
    [FCOIS_RECIPE_ADDON_CSFAI]      = "CraftStoreFixedAndImproved",
}

--The research addons which are supported by FCOIS
FCOIS_RESEARCH_ADDON_ESO_STANDARD       = 1
FCOIS_RESEARCH_ADDON_CSFAI              = 2
FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT  = 3
FCOIS.otherAddons.researchAddonsSupported = {
    [FCOIS_RESEARCH_ADDON_ESO_STANDARD]         = "ESO Standard",
    [FCOIS_RESEARCH_ADDON_CSFAI]                = "CraftStoreFixedAndImproved",
    [FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT]    = "ResearchAssistant",
}

--The sets colleciton book addons whicha re supported by FCOIS
FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD        = 1
FCOIS_SETS_COLLECTION_ADDON_LIBMULTIACCOUNTSETS = 2
FCOIS.otherAddons.setCollectionBookAddonsSupported = {
    [FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD]         = "ESO Standard",
    [FCOIS_SETS_COLLECTION_ADDON_LIBMULTIACCOUNTSETS]  = "LibMultiAccountSets",
}

--Variables for the anti-extraction functions
FCOIS.craftingPrevention = {}
FCOIS.craftingPrevention.extractSlot = nil
FCOIS.craftingPrevention.extractWhereAreWe = nil

FCOIS.ZOControlVars = {}
--Inventories and their searchBox controls
local inventories =
{
    [INVENTORY_BACKPACK] =
    {
        searchBox = ZO_PlayerInventorySearchBox,
    },
    [INVENTORY_QUEST_ITEM] =
    {
        searchBox = ZO_PlayerInventorySearchBox,
    },
    [INVENTORY_BANK] =
    {
        searchBox = ZO_PlayerBankSearchBox,
    },
    [INVENTORY_HOUSE_BANK] =
    {
        searchBox = ZO_HouseBankSearchBox,
    },
    [INVENTORY_GUILD_BANK] =
    {
        searchBox = ZO_GuildBankSearchBox,
    },
    [INVENTORY_CRAFT_BAG] =
    {
        searchBox = ZO_CraftBagSearchBox,
    },
}
FCOIS.ZOControlVars.inventories = inventories
--Control names of ZO* standard controls etc.
FCOIS.ZOControlVars.FCOISfilterButtonNames = {
 [FCOIS_CON_FILTER_BUTTON_LOCKDYN] 		= "ZO_PlayerInventory_FilterButton1",
 [FCOIS_CON_FILTER_BUTTON_GEARSETS] 	= "ZO_PlayerInventory_FilterButton2",
 [FCOIS_CON_FILTER_BUTTON_RESDECIMP] 	= "ZO_PlayerInventory_FilterButton3",
 [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]	= "ZO_PlayerInventory_FilterButton4",
}
FCOIS.ZOControlVars.invSceneName                = "inventory"
FCOIS.ZOControlVars.INVENTORY_MANAGER           = ZO_InventoryManager
FCOIS.ZOControlVars.INV				        	= ZO_PlayerInventory
FCOIS.ZOControlVars.INV_NAME					= FCOIS.ZOControlVars.INV:GetName()
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_ITEMS	= ZO_PlayerInventoryMenuBarButton1
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_CRAFTBAG = ZO_PlayerInventoryMenuBarButton2
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_CURRENCIES = ZO_PlayerInventoryMenuBarButton3
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_QUICKSLOTS = ZO_PlayerInventoryMenuBarButton4
FCOIS.ZOControlVars.BACKPACK 		    		= ZO_PlayerInventoryBackpack
FCOIS.ZOControlVars.CRAFTBAG					= ZO_CraftBag
FCOIS.ZOControlVars.CRAFTBAG_LIST 			    = ZO_CraftBagList
FCOIS.ZOControlVars.CRAFTBAG_NAME				= FCOIS.ZOControlVars.CRAFTBAG:GetName()
FCOIS.ZOControlVars.CRAFTBAG_BAG				= ZO_CraftBagListContents
FCOIS.ZOControlVars.CRAFT_BAG_FRAGMENT          = CRAFT_BAG_FRAGMENT
FCOIS.ZOControlVars.BACKPACK_LIST 				= ZO_PlayerInventoryList
FCOIS.ZOControlVars.BACKPACK_BAG 				= ZO_PlayerInventoryListContents
FCOIS.ZOControlVars.VENDOR_SELL				    = ZO_StoreWindowListSellToVendorArea
FCOIS.ZOControlVars.vendorSceneName             = "store"
--FCOIS.ZOControlVars.VENDOR_SELL_NAME			= FCOIS.ZOControlVars.VENDOR_SELL:GetName()
--> The following 4 controls/buttons & the depending table entries will be known first as the vendor gets opened the first time.
--> So they will be re-assigned within EVENT_OPEN_STORE in src/FCOIS_events.lua, function "FCOItemSaver_Open_Store()"
FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUY       = ZO_StoreWindowMenuBarButton1
FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL      = ZO_StoreWindowMenuBarButton2
FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUYBACK   = ZO_StoreWindowMenuBarButton3
FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_REPAIR    = ZO_StoreWindowMenuBarButton4
FCOIS.ZOControlVars.vendorPanelMainMenuButtonControlSets = {
    ["Normal"] = {
        [1] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUY,
        [2] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL,
        [3] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUYBACK,
        [4] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_REPAIR,
    },
    ["Nuzhimeh"] = {
        [1] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL,
        [2] = FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_BUYBACK,
    },
}
FCOIS.ZOControlVars.STORE                       = ZO_StoreWindow
FCOIS.ZOControlVars.STORE_NAME                  = FCOIS.ZOControlVars.STORE:GetName()
FCOIS.ZOControlVars.STORE_BUY_BACK              = ZO_BuyBack
FCOIS.ZOControlVars.STORE_BUY_BACK_NAME         = FCOIS.ZOControlVars.STORE_BUY_BACK:GetName()
FCOIS.ZOControlVars.STORE_BUY_BACK_LIST         = ZO_BuyBackList
--FCOIS.ZOControlVars.STORE_BUY_BACK_LIST_BAG     = ZO_BuyBackListContents
FCOIS.ZOControlVars.VENDOR_MAINMENU_BUTTON_BAR  = ""
--FCOIS.ZOControlVars.FENCE						= ZO_Fence_Keyboard_WindowMenu
FCOIS.ZOControlVars.FENCE_SCENE_NAME            = "fence_keyboard"
FCOIS.ZOControlVars.REPAIR                      = ZO_RepairWindow
FCOIS.ZOControlVars.REPAIR_NAME                 = FCOIS.ZOControlVars.REPAIR:GetName()
FCOIS.ZOControlVars.REPAIR_LIST				    = ZO_RepairWindowList
FCOIS.ZOControlVars.REPAIR_LIST_BAG 		    = ZO_RepairWindowListContents
FCOIS.ZOControlVars.BANK_INV					= ZO_PlayerBank
FCOIS.ZOControlVars.BANK_INV_NAME				= FCOIS.ZOControlVars.BANK_INV:GetName()
FCOIS.ZOControlVars.BANK			    		= ZO_PlayerBankBackpack
FCOIS.ZOControlVars.BANK_BAG		    		= ZO_PlayerBankBackpackContents
FCOIS.ZOControlVars.BANK_MENUBAR_BUTTON_WITHDRAW	= ZO_PlayerBankMenuBarButton1
FCOIS.ZOControlVars.BANK_MENUBAR_BUTTON_DEPOSIT = ZO_PlayerBankMenuBarButton2
FCOIS.ZOControlVars.bankSceneName				= "bank"
FCOIS.ZOControlVars.GUILD_BANK_INV 	    	= ZO_GuildBank
FCOIS.ZOControlVars.GUILD_BANK_INV_NAME		= FCOIS.ZOControlVars.GUILD_BANK_INV:GetName()
FCOIS.ZOControlVars.GUILD_BANK 	    		= ZO_GuildBankBackpack
FCOIS.ZOControlVars.GUILD_BANK_BAG    		= ZO_GuildBankBackpackContents
FCOIS.ZOControlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW	= ZO_GuildBankMenuBarButton1
FCOIS.ZOControlVars.GUILD_BANK_MENUBAR_BUTTON_DEPOSIT = ZO_GuildBankMenuBarButton2
FCOIS.ZOControlVars.guildBankSceneName		    = "guildBank"
FCOIS.ZOControlVars.guildBankGamepadSceneName	= "gamepad_guild_bank"
FCOIS.ZOControlVars.GUILD_STORE_KEYBOARD	= TRADING_HOUSE
FCOIS.ZOControlVars.GUILD_STORE				= ZO_TradingHouse
FCOIS.ZOControlVars.tradingHouseSceneName	= "tradinghouse"
------------------------------------------------------------------------------------------------------------------------
--2019-01-26: Support for API 100025 and 100026 controls!
FCOIS.ZOControlVars.GUILD_STORE_SELL_SLOT	= ZO_TradingHousePostItemPaneFormInfo
FCOIS.ZOControlVars.GUILD_STORE_SELL_SLOT_NAME	= FCOIS.ZOControlVars.GUILD_STORE_SELL_SLOT:GetName()
FCOIS.ZOControlVars.GUILD_STORE_SELL_SLOT_ITEM	= ZO_TradingHousePostItemPaneFormInfoItem
------------------------------------------------------------------------------------------------------------------------
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH = ZO_TradingHouseMenuBarButton1
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH_NAME = "ZO_TradingHouseMenuBarButton1"
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_SELL = ZO_TradingHouseMenuBarButton2
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_LIST = ZO_TradingHouseMenuBarButton3
FCOIS.ZOControlVars.SMITHING                = SMITHING
FCOIS.ZOControlVars.SMITHING                = SMITHING
FCOIS.ZOControlVars.SMITHING_CLASS          = ZO_Smithing
FCOIS.ZOControlVars.SMITHING_PANEL          = ZO_SmithingTopLevel
FCOIS.ZOControlVars.CRAFTING_CREATION_PANEL = ZO_SmithingTopLevelCreationPanel
FCOIS.ZOControlVars.DECONSTRUCTION_INV		= ZO_SmithingTopLevelDeconstructionPanelInventory
FCOIS.ZOControlVars.DECONSTRUCTION_INV_NAME	= FCOIS.ZOControlVars.DECONSTRUCTION_INV:GetName()
FCOIS.ZOControlVars.DECONSTRUCTION    		= ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack
FCOIS.ZOControlVars.DECONSTRUCTION_BAG 		= ZO_SmithingTopLevelDeconstructionPanelInventoryBackpackContents
FCOIS.ZOControlVars.DECONSTRUCTION_SLOT 		= ZO_SmithingTopLevelDeconstructionPanelSlotContainerExtractionSlot
FCOIS.ZOControlVars.DECONSTRUCTION_BUTTON_WEAPONS = ZO_SmithingTopLevelDeconstructionPanelInventoryTabsButton2
FCOIS.ZOControlVars.DECONSTRUCTION_BUTTON_ARMOR   = ZO_SmithingTopLevelDeconstructionPanelInventoryTabsButton1
--FCOIS.ZOControlVars.SMITHING_MENUBAR_BUTTON_DECONSTRUCTION 		= ZO_SmithingTopLevelModeMenuBarButton3
FCOIS.ZOControlVars.REFINEMENT_INV			= ZO_SmithingTopLevelRefinementPanelInventory
FCOIS.ZOControlVars.REFINEMENT_INV_NAME		= FCOIS.ZOControlVars.REFINEMENT_INV:GetName()
FCOIS.ZOControlVars.REFINEMENT    			= ZO_SmithingTopLevelRefinementPanelInventoryBackpack
FCOIS.ZOControlVars.REFINEMENT_BAG 			= ZO_SmithingTopLevelRefinementPanelInventoryBackpackContents
FCOIS.ZOControlVars.REFINEMENT_SLOT = ZO_SmithingTopLevelRefinementPanelSlotContainerExtractionSlot
FCOIS.ZOControlVars.IMPROVEMENT_INV  			= ZO_SmithingTopLevelImprovementPanelInventory
FCOIS.ZOControlVars.IMPROVEMENT_INV_NAME		= FCOIS.ZOControlVars.IMPROVEMENT_INV:GetName()
FCOIS.ZOControlVars.IMPROVEMENT    			= ZO_SmithingTopLevelImprovementPanelInventoryBackpack
FCOIS.ZOControlVars.IMPROVEMENT_BAG  			= ZO_SmithingTopLevelImprovementPanelInventoryBackpackContents
FCOIS.ZOControlVars.IMPROVEMENT_BOOSTER_CONTAINER = ZO_SmithingTopLevelImprovementPanelBoosterContainer
FCOIS.ZOControlVars.IMPROVEMENT_SLOT 			= ZO_SmithingTopLevelImprovementPanelSlotContainerImprovementSlot
FCOIS.ZOControlVars.IMPROVEMENT_BUTTON_WEAPONS = ZO_SmithingTopLevelImprovementPanelInventoryTabsButton2
FCOIS.ZOControlVars.IMPROVEMENT_BUTTON_ARMOR   = ZO_SmithingTopLevelImprovementPanelInventoryTabsButton1
--FCOIS.ZOControlVars.SMITHING_MENUBAR_BUTTON_IMPROVEMENT 			= ZO_SmithingTopLevelModeMenuBarButton4
FCOIS.ZOControlVars.RESEARCH    				= ZO_SmithingTopLevelResearchPanel
FCOIS.ZOControlVars.RESEARCH_NAME 				= FCOIS.ZOControlVars.RESEARCH:GetName()
FCOIS.ZOControlVars.RESEARCH_POPUP_TOP_DIVIDER       = ZO_ListDialog1Divider
FCOIS.ZOControlVars.RESEARCH_POPUP_TOP_DIVIDER_NAME  = FCOIS.ZOControlVars.RESEARCH_POPUP_TOP_DIVIDER:GetName()
FCOIS.ZOControlVars.LIST_DIALOG 	    		= ZO_ListDialog1List
FCOIS.ZOControlVars.DIALOG_SPLIT_STACK_NAME      = "SPLIT_STACK"
FCOIS.ZOControlVars.MAIL_SEND					= MAIL_SEND
FCOIS.ZOControlVars.MAIL_SEND_SCENE             = MAIL_SEND_SCENE
FCOIS.ZOControlVars.MAIL_SEND_NAME			    = FCOIS.ZOControlVars.MAIL_SEND.control:GetName()
FCOIS.ZOControlVars.mailSendSceneName		    = "mailSend"
FCOIS.ZOControlVars.MAIL_SEND_ATTACHMENT_SLOTS  = FCOIS.ZOControlVars.MAIL_SEND.attachmentSlots
--FCOIS.ZOControlVars.MAIL_INBOX				= ZO_MailInbox
FCOIS.ZOControlVars.MAIL_ATTACHMENTS			= FCOIS.ZOControlVars.MAIL_SEND.attachmentSlots
--FCOIS.ZOControlVars.MAIL_MENUBAR_BUTTON_SEND  = ZO_MainMenuSceneGroupBarButton2
FCOIS.ZOControlVars.PLAYER_TRADE				= TRADE
FCOIS.ZOControlVars.PLAYER_TRADE_WINDOW         = TRADE_WINDOW
--FCOIS.ZOControlVars.PLAYER_TRADE_NAME			= FCOIS.ZOControlVars.PLAYER_TRADE.control:GetName()
FCOIS.ZOControlVars.PLAYER_TRADE_ATTACHMENTS    = FCOIS.ZOControlVars.PLAYER_TRADE.Columns[TRADE_ME]
FCOIS.ZOControlVars.ENCHANTING                  = ENCHANTING
FCOIS.ZOControlVars.ENCHANTING_CLASS    		= ZO_Enchanting
FCOIS.ZOControlVars.ENCHANTING_INV          = ZO_EnchantingTopLevelInventory
FCOIS.ZOControlVars.ENCHANTING_INV_NAME     = FCOIS.ZOControlVars.ENCHANTING_INV:GetName()
FCOIS.ZOControlVars.ENCHANTING_STATION		= ZO_EnchantingTopLevelInventoryBackpack
FCOIS.ZOControlVars.ENCHANTING_STATION_NAME	= FCOIS.ZOControlVars.ENCHANTING_STATION:GetName()
FCOIS.ZOControlVars.ENCHANTING_STATION_BAG	= ZO_EnchantingTopLevelInventoryBackpackContents
--FCOIS.ZOControlVars.ENCHANTING_STATION_MENUBAR_BUTTON_CREATION    = ZO_EnchantingTopLevelModeMenuBarButton1
--FCOIS.ZOControlVars.ENCHANTING_STATION_MENUBAR_BUTTON_EXTRACTION  = ZO_EnchantingTopLevelModeMenuBarButton2
FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER	= ZO_EnchantingTopLevelRuneSlotContainer
FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER_NAME	= FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER:GetName()
FCOIS.ZOControlVars.ENCHANTING_EXTRACTION_SLOT	= ZO_EnchantingTopLevelExtractionSlotContainerExtractionSlot
FCOIS.ZOControlVars.ENCHANTING_EXTRACTION_SLOT_NAME = FCOIS.ZOControlVars.ENCHANTING_EXTRACTION_SLOT:GetName()
FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER_POTENCY = ZO_EnchantingTopLevelRuneSlotContainerPotencyRune
FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER_ESSENCE = ZO_EnchantingTopLevelRuneSlotContainerEssenceRune
FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER_ASPECT = ZO_EnchantingTopLevelRuneSlotContainerAspectRune
FCOIS.ZOControlVars.ALCHEMY                 = ALCHEMY
FCOIS.ZOControlVars.ALCHEMY_INV				= ZO_AlchemyTopLevelInventory
FCOIS.ZOControlVars.ALCHEMY_INV_NAME			= FCOIS.ZOControlVars.ALCHEMY_INV:GetName()
FCOIS.ZOControlVars.ALCHEMY_STATION			= ZO_AlchemyTopLevelInventoryBackpack
FCOIS.ZOControlVars.ALCHEMY_STATION_NAME		= FCOIS.ZOControlVars.ALCHEMY_STATION:GetName()
FCOIS.ZOControlVars.ALCHEMY_STATION_BAG		= ZO_AlchemyTopLevelInventoryBackpackContents
FCOIS.ZOControlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION = ZO_AlchemyTopLevelModeMenuBarButton1
FCOIS.ZOControlVars.ALCHEMY_STATION_MENUBAR_BUTTON_POTIONMAKER = ZO_AlchemyTopLevelModeMenuBarButton2
FCOIS.ZOControlVars.ALCHEMY_SLOT_CONTAINER = ZO_AlchemyTopLevelSlotContainer
FCOIS.ZOControlVars.ALCHEMY_SLOT_CONTAINER_NAME = FCOIS.ZOControlVars.ALCHEMY_SLOT_CONTAINER:GetName()
FCOIS.ZOControlVars.PROVISIONER             = PROVISIONER
FCOIS.ZOControlVars.PROVISIONER_PANEL = FCOIS.ZOControlVars.PROVISIONER.control
FCOIS.ZOControlVars.QUICKSLOT               = ZO_QuickSlot
FCOIS.ZOControlVars.QUICKSLOT_WINDOW        = QUICKSLOT_WINDOW
FCOIS.ZOControlVars.QUICKSLOT_NAME          = FCOIS.ZOControlVars.QUICKSLOT:GetName()
FCOIS.ZOControlVars.QUICKSLOT_CIRCLE  		= ZO_QuickSlotCircle
FCOIS.ZOControlVars.QUICKSLOT_LIST			= ZO_QuickSlotList
FCOIS.ZOControlVars.DestroyItemDialog    		= ESO_Dialogs["DESTROY_ITEM_PROMPT"]
FCOIS.ZOControlVars.RepairKits                  = REPAIR_KITS
FCOIS.ZOControlVars.RepairItemDialog            = ZO_ListDialog1
FCOIS.ZOControlVars.RepairItemDialogName    	= "REPAIR_ITEM"
FCOIS.ZOControlVars.RepairItemDialogTitle       = SI_REPAIR_KIT_TITLE
FCOIS.ZOControlVars.CHARACTER					= ZO_Character
FCOIS.ZOControlVars.CONTAINER_LOOT_LIST			= ZO_LootAlphaContainerList
FCOIS.ZOControlVars.CONTAINER_LOOT_LIST_CONTENTS= ZO_LootAlphaContainerListContents
FCOIS.ZOControlVars.CONTAINER_LOOT_LIST_CONTENTS_NAME= FCOIS.ZOControlVars.CONTAINER_LOOT_LIST_CONTENTS:GetName()
--Transmutation / Retrait
if FCOIS.APIversion >= 100033 then
    --Markarth or newer
    FCOIS.ZOControlVars.RETRAIT_KEYBOARD            = ZO_RETRAIT_KEYBOARD
    FCOIS.ZOControlVars.RETRAIT_STATION_KEYBOARD    = ZO_RETRAIT_STATION_KEYBOARD
    FCOIS.ZOControlVars.RETRAIT_KEYBOARD_INTERACT_SCENE = FCOIS.ZOControlVars.RETRAIT_STATION_KEYBOARD.interactScene
    FCOIS.ZOControlVars.RETRAIT_RETRAIT_PANEL	    = FCOIS.ZOControlVars.RETRAIT_KEYBOARD
else
    --Stonethorn or older
    FCOIS.ZOControlVars.RETRAIT_KEYBOARD            = ZO_RETRAIT_STATION_KEYBOARD
    FCOIS.ZOControlVars.RETRAIT_STATION_KEYBOARD    = FCOIS.ZOControlVars.RETRAIT_KEYBOARD
    FCOIS.ZOControlVars.RETRAIT_KEYBOARD_INTERACT_SCENE = FCOIS.ZOControlVars.RETRAIT_STATION_KEYBOARD.interactScene
    FCOIS.ZOControlVars.RETRAIT_RETRAIT_PANEL	    = FCOIS.ZOControlVars.RETRAIT_KEYBOARD.retraitPanel
end
FCOIS.ZOControlVars.RETRAIT					    = ZO_RetraitStation_Keyboard
FCOIS.ZOControlVars.RETRAIT_INV                 = ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventory
FCOIS.ZOControlVars.RETRAIT_INV_NAME		    = FCOIS.ZOControlVars.RETRAIT_INV:GetName()
FCOIS.ZOControlVars.RETRAIT_LIST			    = ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpack
FCOIS.ZOControlVars.RETRAIT_BAG					= ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpackContents
FCOIS.ZOControlVars.RETRAIT_PANEL  	            = ZO_RetraitStation_KeyboardTopLevelRetraitPanel
FCOIS.ZOControlVars.RETRAIT_PANEL_NAME          = FCOIS.ZOControlVars.RETRAIT_PANEL:GetName()
--House bank storage
FCOIS.ZOControlVars.HOUSE_BANK					= ZO_HouseBankBackpack
FCOIS.ZOControlVars.HOUSE_BANK_BAG				= ZO_HouseBankBackpackContents
FCOIS.ZOControlVars.HOUSE_BANK_INV				= ZO_HouseBank
FCOIS.ZOControlVars.HOUSE_BANK_INV_NAME			= FCOIS.ZOControlVars.HOUSE_BANK_INV:GetName()
FCOIS.ZOControlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW	= ZO_HouseBankMenuBarButton1
FCOIS.ZOControlVars.HOUSE_BANK_MENUBAR_BUTTON_DEPOSIT	= ZO_HouseBankMenuBarButton2
FCOIS.ZOControlVars.houseBankSceneName          = "houseBank"
--Equipment slots
FCOIS.ZOControlVars.equipmentSlotsName          = "ZO_CharacterEquipmentSlots"
--Housing
FCOIS.ZOControlVars.housingBook = HOUSING_BOOK_KEYBOARD
FCOIS.ZOControlVars.housingBookNavigation = FCOIS.ZOControlVars.housingBook.navigationTree
--Entries with "bought" houses within:
--FCOIS.ZOControlVars.housingBookNavigation.rootNode.children[1].children[1].data:GetReferenceId() -> returns 31 e.g. the houesId which can be used to jump to
-->collectibleId (e.g. 1090)
-->collectibleIndex (e.g. 5)
FCOIS.ZOControlVars.ZOMenu                      = ZO_Menu
FCOIS.ZOControlVars.ZODialog1                   = ZO_Dialog1
FCOIS.ZOControlVars.mainMenuCategoryBar         = ZO_MainMenuCategoryBar
local ctrlVars = FCOIS.ZOControlVars


--Array for the inventories data
FCOIS.inventoryVars = {}
local inventoryVars = FCOIS.inventoryVars
--The inventory controls which get hooked for the marker texture controls.
    ---hookListViewSetupCallback: Will be done in file /src/FCOIS_MarkerIcons.lua -> function FCOIS.CreateTextures(whichTextures)
    ---called by file /src/FCOIS_Events.lua -> function FCOItemSaver_Loaded -> FCOIS.CreateTextures(-1)
    ---hookScrollSetupCallback: Will be done in file /src/FCOIS_Hooks.lua -> function OnScrollListRowSetupCallback
    ---called by file /src/FCOIS_Hooks.lua -> different SecurePosthooks to crafting inventories e.g.
---Will be used to prevent duplicate marker texture icon apply calls.
inventoryVars.markerControlInventories = {
    ["hookListViewSetupCallback"] = {
        --all PLAYER_INVENTORY.inventories
        --+
        [ctrlVars.REPAIR_LIST]          = true,
        [ctrlVars.CHARACTER]            = true,
        [ctrlVars.QUICKSLOT_LIST]       = true,
        [ctrlVars.RETRAIT_LIST]         = true,
    },
-------------------------------------------------
    ["hookScrollSetupCallback"] = {
        [ctrlVars.REFINEMENT]           = true,
        [ctrlVars.DECONSTRUCTION]       = true,
        [ctrlVars.IMPROVEMENT]          = true,
        [ctrlVars.ENCHANTING_STATION]   = true,
        [ctrlVars.ALCHEMY_STATION]      = true,
    },
}


--The mapping array for libFilter inventory type to inventory backpack type
--Used in function FCOIS.GetInventoryTypeByFilterPanel()
mappingVars.libFiltersPanelIdToInventory = {
	[LF_INVENTORY] 					= INVENTORY_BACKPACK,
	[LF_BANK_WITHDRAW] 				= INVENTORY_BANK,
	[LF_BANK_DEPOSIT]				= INVENTORY_BACKPACK,
	[LF_GUILDBANK_WITHDRAW] 		= INVENTORY_GUILD_BANK,
	[LF_GUILDBANK_DEPOSIT]    		= INVENTORY_BACKPACK,
	[LF_VENDOR_BUY] 				= INVENTORY_BACKPACK,
    [LF_VENDOR_SELL] 				= INVENTORY_BACKPACK,
    [LF_VENDOR_BUYBACK]				= INVENTORY_BACKPACK,
    [LF_VENDOR_REPAIR] 				= INVENTORY_BACKPACK,
	[LF_GUILDSTORE_SELL] 	 		= INVENTORY_BACKPACK,
	[LF_MAIL_SEND] 					= INVENTORY_BACKPACK,
	[LF_TRADE] 						= INVENTORY_BACKPACK,
	[LF_FENCE_SELL] 				= INVENTORY_BACKPACK,
	[LF_FENCE_LAUNDER]				= INVENTORY_BACKPACK,
    [LF_CRAFTBAG]					= INVENTORY_CRAFT_BAG,
    [LF_HOUSE_BANK_WITHDRAW]        = INVENTORY_HOUSE_BANK,
    [LF_HOUSE_BANK_DEPOSIT]			= INVENTORY_BACKPACK,
    [LF_QUICKSLOT]                  = ctrlVars.QUICKSLOT_WINDOW,
}

--The mapping table between the LibFilters filterPaneLid constant and the crafting inventories
--Used in function FCOIS.GetInventoryTypeByFilterPanel()
mappingVars.libFiltersPanelIdToCraftingPanelInventory = {
    [LF_ALCHEMY_CREATION]           = ctrlVars.ALCHEMY,
    [LF_RETRAIT]                    = ctrlVars.RETRAIT_RETRAIT_PANEL,
    [LF_SMITHING_REFINE]            = ctrlVars.SMITHING.refinementPanel,
    [LF_SMITHING_CREATION]          = nil,
    [LF_SMITHING_DECONSTRUCT]       = ctrlVars.SMITHING.deconstructionPanel,
    [LF_SMITHING_IMPROVEMENT]       = ctrlVars.SMITHING.improvementPanel,
    [LF_SMITHING_RESEARCH]          = nil,
    [LF_SMITHING_RESEARCH_DIALOG]   = nil,
    [LF_JEWELRY_REFINE]            = ctrlVars.SMITHING.refinementPanel,
    [LF_JEWELRY_CREATION]          = nil,
    [LF_JEWELRY_DECONSTRUCT]       = ctrlVars.SMITHING.deconstructionPanel,
    [LF_JEWELRY_IMPROVEMENT]       = ctrlVars.SMITHING.improvementPanel,
    [LF_JEWELRY_RESEARCH]          = nil,
    [LF_JEWELRY_RESEARCH_DIALOG]   = nil,
}

--The filterPanelId to crafting table slot (extraction, deconstruction, refine, retrait, ...) control
mappingVars.libFiltersPanelIdToCraftingPanelSlot = {
    [LF_RETRAIT]                    = ctrlVars.RETRAIT_RETRAIT_PANEL.retraitSlot,
    [LF_SMITHING_REFINE]            = ctrlVars.SMITHING.refinementPanel.extractionSlot,
    [LF_SMITHING_DECONSTRUCT]       = ctrlVars.SMITHING.deconstructionPanel.extractionSlot,
    [LF_SMITHING_IMPROVEMENT]       = ctrlVars.SMITHING.improvementPanel.improvementSlot,
    [LF_JEWELRY_REFINE]             = ctrlVars.SMITHING.refinementPanel.extractionSlot,
    [LF_JEWELRY_DECONSTRUCT]        = ctrlVars.SMITHING.deconstructionPanel.extractionSlot,
    [LF_JEWELRY_IMPROVEMENT]        = ctrlVars.SMITHING.improvementPanel.improvementSlot,
}

--The crafting panelIds which should show FCOIS filter buttons
mappingVars.craftingPanelsWithFCOISFilterButtons = {
    ["ALCHEMY"] = {
        [LF_ALCHEMY_CREATION]           = { usesFCOISFilterButtons = true,  panelControl = ctrlVars.ALCHEMY }
    },
    ["RETRAIT"] = {
        [LF_RETRAIT]                    = { usesFCOISFilterButtons = true,  panelControl = ctrlVars.RETRAIT_RETRAIT_PANEL }
    },
    ["SMITHING"] = {
        [LF_SMITHING_REFINE]            = { usesFCOISFilterButtons = true,  panelControl = ctrlVars.SMITHING.refinementPanel},
        [LF_SMITHING_CREATION]          = { usesFCOISFilterButtons = false, panelControl = nil},
        [LF_SMITHING_DECONSTRUCT]       = { usesFCOISFilterButtons = true,  panelControl = ctrlVars.SMITHING.deconstructionPanel},
        [LF_SMITHING_IMPROVEMENT]       = { usesFCOISFilterButtons = true,  panelControl = ctrlVars.SMITHING.improvementPanel},
        [LF_SMITHING_RESEARCH]          = { usesFCOISFilterButtons = false, panelControl = nil},
        [LF_SMITHING_RESEARCH_DIALOG]   = { usesFCOISFilterButtons = false, panelControl = nil},
    },
}
--The mapping table between the LibFilters filterPaneLid constant and the crafting inventories
mappingVars.libFiltersPanelIdToCraftingPanelInventory = {
    [LF_ALCHEMY_CREATION]           = ctrlVars.ALCHEMY,
    [LF_RETRAIT]                    = ctrlVars.RETRAIT_RETRAIT_PANEL,
    [LF_SMITHING_REFINE]            = ctrlVars.SMITHING.refinementPanel,
    [LF_SMITHING_CREATION]          = nil,
    [LF_SMITHING_DECONSTRUCT]       = ctrlVars.SMITHING.deconstructionPanel,
    [LF_SMITHING_IMPROVEMENT]       = ctrlVars.SMITHING.improvementPanel,
    [LF_SMITHING_RESEARCH]          = nil,
    [LF_SMITHING_RESEARCH_DIALOG]   = nil,
    [LF_JEWELRY_REFINE]            = ctrlVars.SMITHING.refinementPanel,
    [LF_JEWELRY_CREATION]          = nil,
    [LF_JEWELRY_DECONSTRUCT]       = ctrlVars.SMITHING.deconstructionPanel,
    [LF_JEWELRY_IMPROVEMENT]       = ctrlVars.SMITHING.improvementPanel,
    [LF_JEWELRY_RESEARCH]          = nil,
    [LF_JEWELRY_RESEARCH_DIALOG]   = nil,
}

--Mapping for the house bank BAG numbers
--[[
        * BAG_HOUSE_BANK_EIGHT
        * BAG_HOUSE_BANK_FIVE
        * BAG_HOUSE_BANK_FOUR
        * BAG_HOUSE_BANK_NINE
        * BAG_HOUSE_BANK_ONE
        * BAG_HOUSE_BANK_SEVEN
        * BAG_HOUSE_BANK_SIX
        * BAG_HOUSE_BANK_TEN
        * BAG_HOUSE_BANK_THREE
        * BAG_HOUSE_BANK_TWO

    * IsHouseBankBag(*[Bag|#Bag]* _bag_)
    ** _Returns:_ *bool* _isHouseBankBag_
]]
mappingVars.houseBankBagIdToBag = {
    [1]  = BAG_HOUSE_BANK_ONE,
    [2]  = BAG_HOUSE_BANK_TWO,
    [3]  = BAG_HOUSE_BANK_THREE,
    [4]  = BAG_HOUSE_BANK_FOUR,
    [5]  = BAG_HOUSE_BANK_FIVE,
    [6]  = BAG_HOUSE_BANK_SIX,
    [7]  = BAG_HOUSE_BANK_SEVEN,
    [8]  = BAG_HOUSE_BANK_EIGHT,
    [9]  = BAG_HOUSE_BANK_NINE,
    [10] = BAG_HOUSE_BANK_TEN,
}

--The last clicked enchanting panel top menu bar button
--FCOIS.lastVars.gLastEnchantingButton			= ctrlVars.ENCHANTING_STATION_MENUBAR_BUTTON_CREATION
--FCOIS.lastVars.gLastSmithingButton				= ctrlVars.SMITHING_MENUBAR_BUTTON_DECONSTRUCTION
FCOIS.lastVars.gLastBankButton					= ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW
FCOIS.lastVars.gLastHouseBankButton				= ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW
FCOIS.lastVars.gLastGuildBankButton   			= ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW
FCOIS.lastVars.gLastGuildStoreButton			= ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH
--FCOIS.lastVars.gLastVendorButton				= ctrlVars.VENDOR_MENUBAR_BUTTON_SELL -> See file src/FCOIS_events.lua, function FCOItemSaver_Open_Store()
--FCOIS.lastVars.gLastMailButton         		= ctrlVars.MAIL_MENUBAR_BUTTON_SEND
FCOIS.lastVars.gLastAlchemyButton				= ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION
FCOIS.lastVars.gLastSmithingDeconstructionSubFilterButton 	= ctrlVars.DECONSTRUCTION_BUTTON_WEAPONS
FCOIS.lastVars.gLastSmithingImprovementSubFilterButton 	= ctrlVars.IMPROVEMENT_BUTTON_WEAPONS
--FCOIS.lastVars.gLastEnchantingSubFilterButton 	= ctrlVars.ENCHANTING_BUTTON_GLYPHS
FCOIS.lastVars.gLastInvButton					= ctrlVars.INV_MENUBAR_BUTTON_ITEMS

--The mapping array for filterPanelId to shown inventories
mappingVars.gFilterPanelIdToInv = {
	[LF_INVENTORY] 							= ctrlVars.BACKPACK,
	[LF_CRAFTBAG] 							= ctrlVars.CRAFTBAG,
    [LF_BANK_WITHDRAW] 						= ctrlVars.BANK,
	[LF_BANK_DEPOSIT]						= ctrlVars.BACKPACK,
	[LF_GUILDBANK_WITHDRAW] 			   	= ctrlVars.GUILD_BANK,
	[LF_GUILDBANK_DEPOSIT]					= ctrlVars.BACKPACK,
    [LF_VENDOR_BUY] 						= ctrlVars.BACKPACK,
	[LF_VENDOR_SELL] 						= ctrlVars.BACKPACK,
    [LF_VENDOR_BUYBACK]						= ctrlVars.BACKPACK,
    [LF_VENDOR_REPAIR] 						= ctrlVars.BACKPACK,
    [LF_SMITHING_REFINE]					= ctrlVars.REFINEMENT,
	[LF_SMITHING_DECONSTRUCT]  				= ctrlVars.DECONSTRUCTION,
	[LF_SMITHING_IMPROVEMENT]				= ctrlVars.IMPROVEMENT,
	[LF_GUILDSTORE_SELL] 	 		   		= ctrlVars.BACKPACK,
	[LF_MAIL_SEND] 							= ctrlVars.BACKPACK,
	[LF_TRADE] 				   				= ctrlVars.BACKPACK,
    [LF_ENCHANTING_CREATION]				= ctrlVars.ENCHANTING_STATION,
	[LF_ENCHANTING_EXTRACTION]	 			= ctrlVars.ENCHANTING_STATION,
	[LF_FENCE_SELL]							= ctrlVars.BACKPACK,
	[LF_FENCE_LAUNDER]						= ctrlVars.BACKPACK,
    [LF_ALCHEMY_CREATION]					= ctrlVars.ALCHEMY_STATION,
    [LF_RETRAIT]						    = ctrlVars.BACKPACK,
    [LF_HOUSE_BANK_WITHDRAW]				= ctrlVars.HOUSE_BANK,
    [LF_HOUSE_BANK_DEPOSIT]					= ctrlVars.BACKPACK,
    [LF_JEWELRY_REFINE]		                = ctrlVars.REFINEMENT,
    [LF_JEWELRY_DECONSTRUCT]		        = ctrlVars.DECONSTRUCTION,
    [LF_JEWELRY_IMPROVEMENT]		        = ctrlVars.IMPROVEMENT,
}

--The array for the texture names of each panel Id
local invTextureName                = ctrlVars.INV_NAME .. "_FilterButton%sTexture"
local refineTextureName             = ctrlVars.REFINEMENT_INV_NAME .. "_FilterButton%sTexture"
local enchantTextureName            = ctrlVars.ENCHANTING_STATION_NAME .. "_FilterButton%sTexture"
local deconTextureName              = ctrlVars.DECONSTRUCTION_INV_NAME .. "_FilterButton%sTexture"
local improveTextureName            = ctrlVars.IMPROVEMENT_INV_NAME .. "_FilterButton%sTexture"
local researchTextureName           = ctrlVars.RESEARCH_NAME .. "_FilterButton%sTexture"
local researchDialogTextureName     = ctrlVars.RESEARCH_POPUP_TOP_DIVIDER_NAME .. "_FilterButton%sTexture"
mappingVars.gFilterPanelIdToTextureName = {
	[LF_INVENTORY] 					= invTextureName,
	[LF_CRAFTBAG] 					= ctrlVars.CRAFTBAG_NAME .. "_FilterButton%sTexture",
    [LF_SMITHING_REFINE]			= refineTextureName,
    [LF_SMITHING_DECONSTRUCT] 		= deconTextureName,
	[LF_SMITHING_IMPROVEMENT] 		= improveTextureName,
    [LF_SMITHING_RESEARCH] 		    = researchTextureName,
    [LF_SMITHING_RESEARCH_DIALOG]   = researchDialogTextureName,
	[LF_VENDOR_BUY] 				= invTextureName,
    [LF_VENDOR_SELL] 				= invTextureName,
    [LF_VENDOR_BUYBACK]				= invTextureName,
    [LF_VENDOR_REPAIR] 				= invTextureName,
	[LF_GUILDBANK_WITHDRAW]			= ctrlVars.GUILD_BANK_INV_NAME .. "_FilterButton%sTexture",
	[LF_GUILDBANK_DEPOSIT] 			= invTextureName,
	[LF_GUILDSTORE_SELL] 			= invTextureName,
	[LF_BANK_WITHDRAW] 				= ctrlVars.BANK_INV_NAME .. "_FilterButton%sTexture",
	[LF_BANK_DEPOSIT] 				= invTextureName,
	[LF_ENCHANTING_EXTRACTION] 		= enchantTextureName,
	[LF_ENCHANTING_CREATION] 		= enchantTextureName,
	[LF_MAIL_SEND] 					= invTextureName,
	[LF_TRADE] 						= invTextureName,
	[LF_FENCE_SELL] 				= invTextureName,
	[LF_FENCE_LAUNDER] 				= invTextureName,
	[LF_ALCHEMY_CREATION] 			= ctrlVars.ALCHEMY_INV_NAME .. "_FilterButton%sTexture",
    [LF_RETRAIT] 		            = ctrlVars.RETRAIT_INV_NAME .. "_FilterButton%sTexture",
    [LF_HOUSE_BANK_WITHDRAW]		= ctrlVars.HOUSE_BANK_INV_NAME .. "_FilterButton%sTexture",
    [LF_HOUSE_BANK_DEPOSIT] 		= invTextureName,
    [LF_JEWELRY_REFINE]		        = refineTextureName,
    [LF_JEWELRY_DECONSTRUCT]		= deconTextureName,
    [LF_JEWELRY_IMPROVEMENT]		= improveTextureName,
    [LF_JEWELRY_RESEARCH] 		    = researchTextureName,
    [LF_JEWELRY_RESEARCH_DIALOG]    = researchDialogTextureName,
}

--The icons to choose from
FCOIS.textureVars = {}
FCOIS.textureVars.allLockDyn  			= [[/esoui/art/help/help_tabicon_trial_up.dds]]
FCOIS.textureVars.allLockDynWidth		= 24
FCOIS.textureVars.allLockDynHeight		= 24
FCOIS.textureVars.allGearSets  			= [[/esoui/art/crafting/smithing_tabicon_armorset_up.dds]]
FCOIS.textureVars.allGearSetsWidth		= 24
FCOIS.textureVars.allGearSetsHeight		= 24
FCOIS.textureVars.allResDecImp 			= [[/esoui/art/crafting/smithing_tabicon_weaponset_up.dds]]
FCOIS.textureVars.allResDecImpWidth		= 24
FCOIS.textureVars.allResDecImpHeight	= 24
FCOIS.textureVars.allSellGuildInt 		= [[/esoui/art/icons/item_generic_coinbag.dds]]
FCOIS.textureVars.allSellGuildIntWidth	= 20
FCOIS.textureVars.allSellGuildIntHeight	= 20
--> See filename FCOIS_Textures.lua for the texture filenames of the marker icons etc.

--Arrays for the right click/context menu entries
FCOIS.localizationVars = {}
FCOIS.localizationVars.localizationAll 		= {}
FCOIS.localizationVars.fcois_loc 	 	    = {}
FCOIS.localizationVars.lTextMark 		    = {}
FCOIS.localizationVars.lTextDemark 	        = {}
FCOIS.localizationVars.contextEntries       = {}
FCOIS.localizationVars.lTextEquipmentMark   = {}
FCOIS.localizationVars.lTextEquipmentDemark = {}

FCOIS.settingsVars	= {}
FCOIS.settingsVars.settings			= {}
FCOIS.settingsVars.accountWideButForEachCharacterSettings = {}
FCOIS.settingsVars.defaultSettings	= {}
FCOIS.settingsVars.firstRunSettings   = {}
FCOIS.settingsVars.defaults			= {}
FCOIS.settingsVars.accountWideButForEachCharacterDefaults = {}

FCOIS.markedItems = {}
FCOIS.markedItemsFCOISUnique = {}
local numFilters = numVars.gFCONumFilters
for i = 1, numFilters, 1 do
	FCOIS.markedItems[i] = {}
	FCOIS.markedItemsFCOISUnique[i] = {}
end

--The itemtypes that are allowed to be marked with unique item IDs by ZOS uniqueIDs
--All not listed item types (or listed with "false") will be saved with the non-unique itemInstanceId
FCOIS.allowedUniqueIdItemTypes = {
    [ITEMTYPE_ARMOR]        =   true,
    [ITEMTYPE_WEAPON]       =   true,
}
--The itemtypes that are allowed to be marked with unique item IDs created by FCOIS uniqueIDs (chosen by the user in the
--settings of the unique FCOIS itemId). All not listed item types (or listed with "false") will be saved with the
--non-unique itemInstanceId
--> See FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes
--->    filled in file /src/FCOIS_DefaultSettings.lua, and then managed in file /src/FCOIS_SettingsMenu.lua

--The allowed craftskills for automatic marking of "crafted" marker icon
-->Filled in file src/FCOIS_Functions.lua, function FCOIS.rebuildAllowedCraftSkillsForCraftedMarking(craftType)
--->Using SavedVariable settings (FCOIS.settingsVars.settings.allowedCraftSkillsForCraftedMarking) for the craftskills!
----> See file src/FCOIS_SettingsMenu.lua, function FCOIS.BuildAddonMenu, "options_auto_mark_crafted_items_panel_ ..."
FCOIS.allowedCraftSkillsForCraftedMarking = {}
--The crafting creation panels, or the functions to check if they are shown
FCOIS.craftingCreatePanelControlsOrFunction = {}
--Drag & drop variables
FCOIS.dragAndDropVars = {}
FCOIS.dragAndDropVars.bag	= nil
FCOIS.dragAndDropVars.slot	= nil
--Prevention variables
FCOIS.preventerVars = {}
local preventerVars = FCOIS.preventerVars
preventerVars._prevVarReset = "FCOIS_PreventerVariableReset_"
preventerVars.gLocalizationDone		= false
preventerVars.KeyBindingTexts		= false
preventerVars.gScanningInv	    	= false
--preventerVars.canUpdateInv 	   		= true
preventerVars.gFilteringBasics		= false
preventerVars.gActiveFilterPanel	= false
preventerVars.gNoCloseEvent 		= false
preventerVars.gAllowDestroyItem		= false
preventerVars.wasDestroyDone        = false
preventerVars.gItemSlotIsLocked 	= false
preventerVars.gCheckEquipmentSlots  = false
preventerVars.gUpdateMarkersNow		= false
preventerVars.gChangedGears			= false
preventerVars.gContextCreated		= {}
preventerVars.gLockDynFilterContextCreated = {}
preventerVars.gGearSetFilterContextCreated = {}
preventerVars.gResDecImpFilterContextCreated = {}
preventerVars.gSellGuildIntFilterContextCreated = {}
preventerVars.askBeforeEquipDialogRetVal = false
preventerVars.gOverrideInvUpdateAfterMarkItem = false
preventerVars.doFalseOverride = false
preventerVars.newItemCrafted = false
--preventerVars.ZOsPlayerItemLockEnabled = true -- implemented with API 1000015 by ZOs: Lock items in inventory. Items will get dataEntry "isPlayerLocked = true"
preventerVars.isControlCheckActive = {}
preventerVars.controlCheckActiveCounter = {}
preventerVars.buildingSlotActionTexts = false
preventerVars.dontShowInvContextMenu = false
preventerVars.markItemAntiEndlessLoop = false
preventerVars.dontAutoReenableAntiSettingsInInventory = false
preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
preventerVars.noGamePadModeSupportTextOutput = false
preventerVars.contextMenuUpdateLoopLastLoop = false
preventerVars.doNotScanInv = false
preventerVars.migrateItemMarkers = false
preventerVars.migrateToUniqueIds = false
preventerVars.migrateToItemInstanceIds = false
preventerVars.gAddonStartupInProgress = false
preventerVars.lastHoveredInvSlot = nil
preventerVars.createdMasterWrit= false
preventerVars.writCreatorCreatedItem = false
preventerVars.eventInventorySingleSlotUpdate = false
preventerVars.resetNonServerDependentSavedVars = false
preventerVars.preHookButtonDone = {}
preventerVars.gPreHookButtonHandlerCallActive = false
preventerVars.craftBagSceneShowInProgress = false
preventerVars.markerIconChangedManually = false
preventerVars.isInventoryListUpdating = false
preventerVars.gRestoringMarkerIcons = false
preventerVars.gClearingMarkerIcons = false
preventerVars.gMarkItemLastIconInLoop = false
preventerVars.repairDialogOnRepairKitSelectedOverwrite = false
preventerVars.ZO_ListDialog1ResearchIsOpen = false
preventerVars.splitItemStackDialogActive = false
preventerVars.splitItemStackDialogButtonCallbacks = false
preventerVars.useAdvancedFiltersItemCountInInventories = false
preventerVars.dontUpdateFilteredItemCount                     = false
preventerVars.lamMenuOpenAndShowingInvPreviewForGridListAddon = false
preventerVars.isZoDialogContextMenu = false

--The event handler array for OnMouseDoubleClick, Drag&Drop, etc.
FCOIS.eventHandlers = {}

--Table to map the FCOIS.settingsVars.settings filter state to the output text identifier
mappingVars.settingsFilterStateToText = {
	["true"]  = "on",
    ["false"] = "off",
    ["-99"]   = "onlyfiltered",
}

--Table to map iconId to relating filterId
mappingVars.iconToFilterDefaults = {
	[FCOIS_CON_ICON_LOCK]				= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_GEAR_1]				= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[FCOIS_CON_ICON_RESEARCH]			= FCOIS_CON_FILTER_BUTTON_RESDECIMP,
	[FCOIS_CON_ICON_GEAR_2]  			= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[FCOIS_CON_ICON_SELL]				= FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
	[FCOIS_CON_ICON_GEAR_3]				= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[FCOIS_CON_ICON_GEAR_4]				= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[FCOIS_CON_ICON_GEAR_5]				= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[FCOIS_CON_ICON_DECONSTRUCTION]		= FCOIS_CON_FILTER_BUTTON_RESDECIMP,
	[FCOIS_CON_ICON_IMPROVEMENT]   		= FCOIS_CON_FILTER_BUTTON_RESDECIMP,
	[FCOIS_CON_ICON_SELL_AT_GUILDSTORE]	= FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
	[FCOIS_CON_ICON_INTRICATE]			= FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
--[[
    [FCOIS_CON_ICON_DYNAMIC_1]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_2]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_3]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_4]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_5]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_6]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_7]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_8]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_9]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_10]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_11]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_12]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_13]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_14]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_15]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_16]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_17]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_18]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_19]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_20]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_21]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_22]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_23]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_24]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_25]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_26]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_27]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_28]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_29]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS_CON_ICON_DYNAMIC_30]			= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
]]
}
mappingVars.iconToFilter = {}

--Table to map filterId to relating iconId
--As filters can have several icons only the main iconId of this filterId is maintained here
mappingVars.filterToIcon = {
    [1]	= FCOIS_CON_ICON_LOCK,
    [2]	= FCOIS_CON_ICON_GEAR_1,
    [3]	= FCOIS_CON_ICON_RESEARCH,
    [4]	= FCOIS_CON_ICON_SELL,
}

--The static gear icons
mappingVars.isStaticGearIcon = {
    [FCOIS_CON_ICON_GEAR_1] = true,
    [FCOIS_CON_ICON_GEAR_2] = true,
    [FCOIS_CON_ICON_GEAR_3] = true,
    [FCOIS_CON_ICON_GEAR_4] = true,
    [FCOIS_CON_ICON_GEAR_5] = true,
}

--Table to map iconId to gearId. Will be enhanced by the dynamic icons which are enabled to be "gear"
--by function FCOIS.rebuildGearSetBaseVars() (in /src/FCOIS_Functions.lua), in EVENT_PLAYER_ACTIVATED callback
mappingVars.iconToGear = {
    [FCOIS_CON_ICON_GEAR_1] = 1,
    [FCOIS_CON_ICON_GEAR_2] = 2,
    [FCOIS_CON_ICON_GEAR_3] = 3,
    [FCOIS_CON_ICON_GEAR_4] = 4,
    [FCOIS_CON_ICON_GEAR_5] = 5,
}

--Table to map gearId to iconId. Will be enhanced by the dynamic icons which are enabled to be "gear".
--by function FCOIS.rebuildGearSetBaseVars() (in /src/FCOIS_Functions.lua), in EVENT_PLAYER_ACTIVATED callback
mappingVars.gearToIcon = {
    [1] = FCOIS_CON_ICON_GEAR_1,
    [2] = FCOIS_CON_ICON_GEAR_2,
    [3] = FCOIS_CON_ICON_GEAR_3,
    [4] = FCOIS_CON_ICON_GEAR_4,
    [5] = FCOIS_CON_ICON_GEAR_5,
}

--Table to see if the icon is researchable
mappingVars.iconIsResearchable = {
	[FCOIS_CON_ICON_GEAR_1]         = true,
	[FCOIS_CON_ICON_RESEARCH]       = true,
	[FCOIS_CON_ICON_GEAR_2]         = true,
	[FCOIS_CON_ICON_GEAR_3]         = true,
	[FCOIS_CON_ICON_GEAR_4]         = true,
	[FCOIS_CON_ICON_GEAR_5]         = true,
	[FCOIS_CON_ICON_DECONSTRUCTION] = true,
	[FCOIS_CON_ICON_IMPROVEMENT]    = true,
    [FCOIS_CON_ICON_INTRICATE]      = true,
}

--Table to see if the icon is a dynamic icon
mappingVars.iconIsDynamic = {
	[FCOIS_CON_ICON_LOCK]				= false,
	[FCOIS_CON_ICON_GEAR_1]				= false,
	[FCOIS_CON_ICON_RESEARCH]			= false,
	[FCOIS_CON_ICON_GEAR_2]  			= false,
	[FCOIS_CON_ICON_SELL]				= false,
	[FCOIS_CON_ICON_GEAR_3]				= false,
	[FCOIS_CON_ICON_GEAR_4]				= false,
	[FCOIS_CON_ICON_GEAR_5]				= false,
	[FCOIS_CON_ICON_DECONSTRUCTION]		= false,
	[FCOIS_CON_ICON_IMPROVEMENT]   		= false,
	[FCOIS_CON_ICON_SELL_AT_GUILDSTORE]	= false,
	[FCOIS_CON_ICON_INTRICATE]			= false,
--[[
	[FCOIS_CON_ICON_DYNAMIC_1]          = true,
	[FCOIS_CON_ICON_DYNAMIC_2]          = true,
	..
]]
}

--Table to map dynamicId to iconId
mappingVars.dynamicToIcon = {
--[[
	[1] = FCOIS_CON_ICON_DYNAMIC_1,
	[2] = FCOIS_CON_ICON_DYNAMIC_2,
	[3] = FCOIS_CON_ICON_DYNAMIC_3,
	[4] = FCOIS_CON_ICON_DYNAMIC_4,
	[5] = FCOIS_CON_ICON_DYNAMIC_5,
	[6] = FCOIS_CON_ICON_DYNAMIC_6,
	[7] = FCOIS_CON_ICON_DYNAMIC_7,
	[8] = FCOIS_CON_ICON_DYNAMIC_8,
	[9] = FCOIS_CON_ICON_DYNAMIC_9,
	[10] = FCOIS_CON_ICON_DYNAMIC_10,
    [11] = FCOIS_CON_ICON_DYNAMIC_11,
    [12] = FCOIS_CON_ICON_DYNAMIC_12,
    [13] = FCOIS_CON_ICON_DYNAMIC_13,
    [14] = FCOIS_CON_ICON_DYNAMIC_14,
    [15] = FCOIS_CON_ICON_DYNAMIC_15,
    [16] = FCOIS_CON_ICON_DYNAMIC_16,
    [17] = FCOIS_CON_ICON_DYNAMIC_17,
    [18] = FCOIS_CON_ICON_DYNAMIC_18,
    [19] = FCOIS_CON_ICON_DYNAMIC_19,
    [20] = FCOIS_CON_ICON_DYNAMIC_20,
    [21] = FCOIS_CON_ICON_DYNAMIC_21,
    [22] = FCOIS_CON_ICON_DYNAMIC_22,
    [23] = FCOIS_CON_ICON_DYNAMIC_23,
    [24] = FCOIS_CON_ICON_DYNAMIC_24,
    [25] = FCOIS_CON_ICON_DYNAMIC_25,
    [26] = FCOIS_CON_ICON_DYNAMIC_26,
    [27] = FCOIS_CON_ICON_DYNAMIC_27,
    [28] = FCOIS_CON_ICON_DYNAMIC_28,
    [29] = FCOIS_CON_ICON_DYNAMIC_29,
    [30] = FCOIS_CON_ICON_DYNAMIC_30,
]]
}

--Table to map iconId to dynamicId
mappingVars.iconToDynamic = {
--[[
	[FCOIS_CON_ICON_DYNAMIC_1] = 1,
	[FCOIS_CON_ICON_DYNAMIC_2] = 2,
	[FCOIS_CON_ICON_DYNAMIC_3] = 3,
	[FCOIS_CON_ICON_DYNAMIC_4] = 4,
	[FCOIS_CON_ICON_DYNAMIC_5] = 5,
	[FCOIS_CON_ICON_DYNAMIC_6] = 6,
	[FCOIS_CON_ICON_DYNAMIC_7] = 7,
	[FCOIS_CON_ICON_DYNAMIC_8] = 8,
	[FCOIS_CON_ICON_DYNAMIC_9] = 9,
	[FCOIS_CON_ICON_DYNAMIC_10]= 10,
    [FCOIS_CON_ICON_DYNAMIC_11]= 11,
    [FCOIS_CON_ICON_DYNAMIC_12]= 12,
    [FCOIS_CON_ICON_DYNAMIC_13]= 13,
    [FCOIS_CON_ICON_DYNAMIC_14]= 14,
    [FCOIS_CON_ICON_DYNAMIC_15]= 15,
    [FCOIS_CON_ICON_DYNAMIC_16]= 16,
    [FCOIS_CON_ICON_DYNAMIC_17]= 17,
    [FCOIS_CON_ICON_DYNAMIC_18]= 18,
    [FCOIS_CON_ICON_DYNAMIC_19]= 19,
    [FCOIS_CON_ICON_DYNAMIC_20]= 20,
    [FCOIS_CON_ICON_DYNAMIC_21]= 21,
    [FCOIS_CON_ICON_DYNAMIC_22]= 22,
    [FCOIS_CON_ICON_DYNAMIC_23]= 23,
    [FCOIS_CON_ICON_DYNAMIC_24]= 24,
    [FCOIS_CON_ICON_DYNAMIC_25]= 25,
    [FCOIS_CON_ICON_DYNAMIC_26]= 26,
    [FCOIS_CON_ICON_DYNAMIC_27]= 27,
    [FCOIS_CON_ICON_DYNAMIC_28]= 28,
    [FCOIS_CON_ICON_DYNAMIC_29]= 29,
    [FCOIS_CON_ICON_DYNAMIC_30]= 30,
]]
}

--Mapping array for icon to lock & dynamic icons filter split
mappingVars.iconToLockDyn = {
    [FCOIS_CON_ICON_LOCK	 ]  = 1,
--[[
	[FCOIS_CON_ICON_DYNAMIC_1]  = 2,
	[FCOIS_CON_ICON_DYNAMIC_2]  = 3,
	[FCOIS_CON_ICON_DYNAMIC_3]  = 4,
	[FCOIS_CON_ICON_DYNAMIC_4]  = 5,
	[FCOIS_CON_ICON_DYNAMIC_5]  = 6,
	[FCOIS_CON_ICON_DYNAMIC_6]  = 7,
	[FCOIS_CON_ICON_DYNAMIC_7]  = 8,
	[FCOIS_CON_ICON_DYNAMIC_8]  = 9,
	[FCOIS_CON_ICON_DYNAMIC_9]  = 10,
	[FCOIS_CON_ICON_DYNAMIC_10] = 11,
    [FCOIS_CON_ICON_DYNAMIC_11]= 12,
    [FCOIS_CON_ICON_DYNAMIC_12]= 13,
    [FCOIS_CON_ICON_DYNAMIC_13]= 14,
    [FCOIS_CON_ICON_DYNAMIC_14]= 15,
    [FCOIS_CON_ICON_DYNAMIC_15]= 16,
    [FCOIS_CON_ICON_DYNAMIC_16]= 17,
    [FCOIS_CON_ICON_DYNAMIC_17]= 18,
    [FCOIS_CON_ICON_DYNAMIC_18]= 19,
    [FCOIS_CON_ICON_DYNAMIC_19]= 20,
    [FCOIS_CON_ICON_DYNAMIC_20]= 21,
    [FCOIS_CON_ICON_DYNAMIC_21]= 22,
    [FCOIS_CON_ICON_DYNAMIC_22]= 23,
    [FCOIS_CON_ICON_DYNAMIC_23]= 24,
    [FCOIS_CON_ICON_DYNAMIC_24]= 25,
    [FCOIS_CON_ICON_DYNAMIC_25]= 26,
    [FCOIS_CON_ICON_DYNAMIC_26]= 27,
    [FCOIS_CON_ICON_DYNAMIC_27]= 28,
    [FCOIS_CON_ICON_DYNAMIC_28]= 29,
    [FCOIS_CON_ICON_DYNAMIC_29]= 30,
    [FCOIS_CON_ICON_DYNAMIC_30]= 31,
]]
}
--Mapping array for lock & dynamic icons filter split to it's icon
mappingVars.lockDynToIcon = {
	[1]  =  FCOIS_CON_ICON_LOCK,
--[[
	[2]  =  FCOIS_CON_ICON_DYNAMIC_1,
	[3]  =  FCOIS_CON_ICON_DYNAMIC_2,
	[4]  =  FCOIS_CON_ICON_DYNAMIC_3,
    [5]  =  FCOIS_CON_ICON_DYNAMIC_4,
	[6]	 =  FCOIS_CON_ICON_DYNAMIC_5,
	[7]	 =  FCOIS_CON_ICON_DYNAMIC_6,
	[8]	 =  FCOIS_CON_ICON_DYNAMIC_7,
	[9]	 =  FCOIS_CON_ICON_DYNAMIC_8,
	[10] =  FCOIS_CON_ICON_DYNAMIC_9,
	[11] =  FCOIS_CON_ICON_DYNAMIC_10,
    [12] = FCOIS_CON_ICON_DYNAMIC_11,
    [13] = FCOIS_CON_ICON_DYNAMIC_12,
    [14] = FCOIS_CON_ICON_DYNAMIC_13,
    [15] = FCOIS_CON_ICON_DYNAMIC_14,
    [16] = FCOIS_CON_ICON_DYNAMIC_15,
    [17] = FCOIS_CON_ICON_DYNAMIC_16,
    [18] = FCOIS_CON_ICON_DYNAMIC_17,
    [19] = FCOIS_CON_ICON_DYNAMIC_18,
    [20] = FCOIS_CON_ICON_DYNAMIC_19,
    [21] = FCOIS_CON_ICON_DYNAMIC_20,
    [22] = FCOIS_CON_ICON_DYNAMIC_21,
    [23] = FCOIS_CON_ICON_DYNAMIC_22,
    [24] = FCOIS_CON_ICON_DYNAMIC_23,
    [25] = FCOIS_CON_ICON_DYNAMIC_24,
    [26] = FCOIS_CON_ICON_DYNAMIC_25,
    [27] = FCOIS_CON_ICON_DYNAMIC_26,
    [28] = FCOIS_CON_ICON_DYNAMIC_27,
    [29] = FCOIS_CON_ICON_DYNAMIC_28,
    [30] = FCOIS_CON_ICON_DYNAMIC_29,
    [31] = FCOIS_CON_ICON_DYNAMIC_30,
]]
}

--Add the dynamic icons to the different mapping tables. Use a loop from dynamicIcon 1 to maximum of possible dynamic ones
for dynIconNr=1, numMaxDynamicIcons do
    local dynIconValue = _G[dynamicIconPrefix .. tostring(dynIconNr)]
    mappingVars.iconToFilterDefaults[dynIconValue] = FCOIS_CON_FILTER_BUTTON_LOCKDYN
    mappingVars.iconIsDynamic[dynIconValue] = true
    mappingVars.dynamicToIcon[dynIconNr]    = dynIconValue
    mappingVars.iconToDynamic[dynIconValue] = dynIconNr
    mappingVars.iconToLockDyn[dynIconValue] = 1 + dynIconNr
    mappingVars.lockDynToIcon[1 + dynIconNr] = dynIconValue
end


--Mapping array for icon to research/deconstruction/improvement filter split
mappingVars.iconToResDecImp = {
	[FCOIS_CON_ICON_RESEARCH]  		= 1,
	[FCOIS_CON_ICON_DECONSTRUCTION] = 2,
	[FCOIS_CON_ICON_IMPROVEMENT] 	= 3,
}

--Mapping array for research/deconstruction/improvement filter split to it's icon
mappingVars.resDecImpToIcon = {
	[1]  = FCOIS_CON_ICON_RESEARCH,
	[2]  = FCOIS_CON_ICON_DECONSTRUCTION,
	[3]  = FCOIS_CON_ICON_IMPROVEMENT,
}

--Mapping array for icon to sell/sell in guild store/intricate filter split
mappingVars.iconToSellGuildInt = {
    [FCOIS_CON_ICON_SELL]  				= 1,
    [FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = 2,
    [FCOIS_CON_ICON_INTRICATE] 			= 3,
}

--Mapping array for sell/sell in guild store/intricate filter split to it's icon
mappingVars.sellGuildIntToIcon = {
    [1] = FCOIS_CON_ICON_SELL,
    [2] = FCOIS_CON_ICON_SELL_AT_GUILDSTORE,
    [3] = FCOIS_CON_ICON_INTRICATE,
}

--Table with the weapon types for the main&offhand checks
checkVars.weaponTypeCheckTable = {
   ["1hd"] = {
	[WEAPONTYPE_AXE] = true,
	[WEAPONTYPE_DAGGER] = true,
	[WEAPONTYPE_HAMMER] = true,
	[WEAPONTYPE_SWORD] = true,
   },
   ["2hd"] = {
	[WEAPONTYPE_TWO_HANDED_AXE] = true,
	[WEAPONTYPE_TWO_HANDED_HAMMER] = true,
	[WEAPONTYPE_TWO_HANDED_SWORD] = true,
   },
   ["2hdall"] = {
	[WEAPONTYPE_TWO_HANDED_AXE] = true,
	[WEAPONTYPE_TWO_HANDED_HAMMER] = true,
	[WEAPONTYPE_TWO_HANDED_SWORD] = true,
	[WEAPONTYPE_BOW] = true,
	[WEAPONTYPE_FIRE_STAFF] = true,
	[WEAPONTYPE_LIGHTNING_STAFF] = true,
	[WEAPONTYPE_FROST_STAFF] = true,
	[WEAPONTYPE_HEALING_STAFF] = true,
   },
   ["staff"] = {
	[WEAPONTYPE_FIRE_STAFF] = true,
	[WEAPONTYPE_LIGHTNING_STAFF] = true,
	[WEAPONTYPE_FROST_STAFF] = true,
	[WEAPONTYPE_HEALING_STAFF] = true,
   },
   ["sword"] = {
	[WEAPONTYPE_SWORD] = true,
   },
   ["swordall"] = {
	[WEAPONTYPE_SWORD] = true,
	[WEAPONTYPE_TWO_HANDED_SWORD] = true,
   },
   ["axe"] = {
	[WEAPONTYPE_AXE] = true,
   },
   ["axeall"] = {
	[WEAPONTYPE_AXE] = true,
	[WEAPONTYPE_TWO_HANDED_AXE] = true,
   },
   ["dagger"] = {
	[WEAPONTYPE_DAGGER] = true,
   },
   ["hammer"] = {
	[WEAPONTYPE_HAMMER] = true,
   },
   ["hammerall"] = {
	[WEAPONTYPE_HAMMER] = true,
	[WEAPONTYPE_TWO_HANDED_HAMMER] = true,
   },
   ["bow"] = {
	[WEAPONTYPE_BOW] = true,
   },
   ["shield"] = {
	[WEAPONTYPE_SHIELD] = true,
   },
   ["firestaff"] = {
	[WEAPONTYPE_FIRE_STAFF] = true,
   },
   ["lightningstaff"] = {
	[WEAPONTYPE_LIGHTNING_STAFF] = true,
   },
   ["froststaff"] = {
	[WEAPONTYPE_FROST_STAFF] = true,
   },
   ["healingstaff"] = {
	[WEAPONTYPE_HEALING_STAFF] = true,
   },
   ["rune"] = {
	[WEAPONTYPE_RUNE] = true,
   },
   }
--Table with allowed item traits for ornate items
checkVars.allowedOrnateItemTraits = {
	[ITEM_TRAIT_TYPE_ARMOR_ORNATE]   = true,
	[ITEM_TRAIT_TYPE_JEWELRY_ORNATE] = true,
	[ITEM_TRAIT_TYPE_WEAPON_ORNATE]  = true,
}
--Table with allowed item traits for intricate items
checkVars.allowedIntricateItemTraits = {
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE]   = true,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE]  = true,
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = true,
}
--Table with allowed item types for researching
checkVars.allowedResearchableItemTypes = {
   	[ITEMTYPE_ARMOR]			=
    {
    	allowed = true,
        isGlpyh = false,
    },
    [ITEMTYPE_WEAPON]   		= true,
    {
    	allowed = true,
        isGlpyh = false,
    },
	[ITEMTYPE_COSTUME]			=
    {
    	allowed = true,
        isGlpyh = false,
    },
	[ITEMTYPE_DISGUISE] 		=
    {
    	allowed = true,
        isGlpyh = false,
    },
    --Glyphs
 	[ITEMTYPE_GLYPH_ARMOR] 		=
    {
    	allowed = true,
        isGlpyh = true,
        allowedIcons = {
        	[FCOIS_CON_ICON_DECONSTRUCTION] = true,
        }
    },
	[ITEMTYPE_GLYPH_JEWELRY] 	=
    {
    	allowed = true,
        isGlpyh = true,
        allowedIcons = {
        	[FCOIS_CON_ICON_DECONSTRUCTION] = true,
        }
    },
	[ITEMTYPE_GLYPH_WEAPON] 	=
    {
    	allowed = true,
        isGlpyh = true,
        allowedIcons = {
        	[FCOIS_CON_ICON_DECONSTRUCTION] = true,
        }
    },
}

--Table with the allowed set item types
checkVars.allowedSetItemTypes = {
	[ITEMTYPE_ARMOR]	= true,
	[ITEMTYPE_WEAPON]	= true,
}

--Table with NOT allowed parent control names. These cannot use the FCOItemSaver right click context menu entries
--for items (in the inventories)
checkVars.notAllowedContextMenuParentControls = {
	["ZO_StoreWindowListContents"] = true,
	["ZO_BuyBackListContents"] = true,
	["ZO_PlayerInventoryQuestContents"] = true,
	["ZO_SmithingTopLevelImprovementPanel"] = true,
    ["ZO_SmithingTopLevelResearchPanelResearchLineListList"] = true,
	["ZO_SmithingTopLevelCreationPanelPatternListList"] = true,
	["ZO_SmithingTopLevelCreationPanelMaterialListList"] = true,
	["ZO_SmithingTopLevelCreationPanelStyleListList"] = true,
	["ZO_SmithingTopLevelCreationPanelTraitListList"] = true,
	--["ZO_AlchemyTopLevelInventoryBackpackContents"] = true,
	["ZO_MailInboxMessage"] = true,
	["ZO_MailSend"] = true,
    ["ZO_TradingHouseItemPaneSearchResultsContents"] = true,
    ["ZO_TradingHousePostedItemsListContents"] = true,
--		["ZO_QuickSlotListContents"] = true,
    ["ZO_InventoryWalletListContents"] = true,
    [ctrlVars.CONTAINER_LOOT_LIST_CONTENTS_NAME] = true,
    [ctrlVars.RETRAIT_PANEL_NAME] = true,

}
--Table with NOT allowed control names. These cannot use the FCOItemSaver right click context menu entries
--for items (in the inventories)
checkVars.notAllowedContextMenuControls = {
	["ZO_SmithingTopLevelRefinementPanelSlotContainer"] = true,
	["ZO_SmithingTopLevelDeconstructionPanelSlotContainer"] = true,
	[ctrlVars.ALCHEMY_SLOT_CONTAINER_NAME] = true,
	[ctrlVars.ENCHANTING_RUNE_CONTAINER_NAME] = true,
    [ctrlVars.ENCHANTING_EXTRACTION_SLOT_NAME] = true,
	["ZO_ApplyEnchantPanel"] = true,
	["ZO_SoulGemItemChargerPanel"] = true,
    ["ZO_SoulGemItemChargerPanelImprovementPreviewContainer"] = true,
    [ctrlVars.GUILD_STORE_SELL_SLOT_NAME] = true,
}
--Table with allowed libFilters panelIds (LF_*) for the additional inventory "flag" context menu's "JUNK" entry
--> See file src/FCOIS_ContextMenu.lua, function FCOIS.showContextMenuForAddInvButtons(invAddContextMenuInvokerButton)
checkVars.allowedJunkFlagContextMenuFilterPanelIds = {
    [LF_INVENTORY]              = true,
    [LF_TRADE]                  = true,
    [LF_MAIL_SEND]              = true,
    [LF_BANK_WITHDRAW]          = true,
    [LF_BANK_DEPOSIT]           = true,
    [LF_GUILDBANK_WITHDRAW]     = true,
    [LF_GUILDBANK_DEPOSIT]      = true,
    [LF_VENDOR_SELL]            = true,
    [LF_CRAFTBAG]               = true,
    [LF_HOUSE_BANK_WITHDRAW]    = true,
    [LF_HOUSE_BANK_DEPOSIT]     = true,
}

--Table with allowed panel IDs for the "crafting station"'s refinement/rune create/extraction/deconstruction/improvement/research slots
--that are checked inside function MarkMe(), as an item gets marked via the right-click context menu from the inventory,
--or via a keybinding: If item is protected again it must be removed from the crafting / etc. slot again!
--> See file src/FCOIS_Protection.lua, function FCOIS.craftingPrevention.IsItemProtectedAtACraftSlotNow(bagId, slotIndex)
checkVars.allowedCraftingPanelIdsForMarkerRechecks = {
	[LF_SMITHING_REFINE] 		= true,
	[LF_SMITHING_DECONSTRUCT] 	= true,
	[LF_SMITHING_IMPROVEMENT] 	= true,
	[LF_SMITHING_RESEARCH] 		= false,
	[LF_ALCHEMY_CREATION] 		= true,
	[LF_ENCHANTING_CREATION] 	= true,
	[LF_ENCHANTING_EXTRACTION] 	= true,
    [LF_RETRAIT] 	            = true,
    [LF_JEWELRY_REFINE]		    = true,
    [LF_JEWELRY_DECONSTRUCT]	= true,
    [LF_JEWELRY_IMPROVEMENT]	= true,
    [LF_JEWELRY_RESEARCH] 		= false,
}

--The character equipment slots
--Table with all equipment slot names which can be updated with markes for the icons
--The index is the relating slotIndex of the bag BAG_WORN!
local equipmentSlotPrefix = "ZO_CharacterEquipmentSlots"
mappingVars.characterEquipmentSlotNameByIndex = {
    [EQUIP_SLOT_HEAD]           = equipmentSlotPrefix .. "Head",
    [EQUIP_SLOT_SHOULDERS]      = equipmentSlotPrefix .. "Shoulder",
    [EQUIP_SLOT_HAND]           = equipmentSlotPrefix .. "Glove",
    [EQUIP_SLOT_LEGS]           = equipmentSlotPrefix .. "Leg",
    [EQUIP_SLOT_CHEST]          = equipmentSlotPrefix .. "Chest",
    [EQUIP_SLOT_WAIST]          = equipmentSlotPrefix .. "Belt",
    [EQUIP_SLOT_FEET]           = equipmentSlotPrefix .. "Foot",
    [EQUIP_SLOT_COSTUME]        = equipmentSlotPrefix .. "Costume",
    [EQUIP_SLOT_NECK]           = equipmentSlotPrefix .. "Neck",
    [EQUIP_SLOT_RING1]          = equipmentSlotPrefix .. "Ring1",
    [EQUIP_SLOT_RING2]          = equipmentSlotPrefix .. "Ring2",
    [EQUIP_SLOT_MAIN_HAND]      = equipmentSlotPrefix .. "MainHand",
    [EQUIP_SLOT_OFF_HAND]       = equipmentSlotPrefix .. "OffHand",
    [EQUIP_SLOT_POISON]         = equipmentSlotPrefix .. "Poison",
    [EQUIP_SLOT_BACKUP_MAIN]    = equipmentSlotPrefix .. "BackupMain",
    [EQUIP_SLOT_BACKUP_OFF]     = equipmentSlotPrefix .. "BackupOff",
    [EQUIP_SLOT_BACKUP_POISON]  = equipmentSlotPrefix .. "BackupPoison",
}
local characterEquipmentSlotNameByIndex = mappingVars.characterEquipmentSlotNameByIndex

--The mapping table for the character equipment slots: Speed find without string.find in EventHandlers
mappingVars.characterEquipmentSlots = {
    [equipmentSlotPrefix .. "Head"] = true,
    [equipmentSlotPrefix .. "Shoulder"] = true,
    [equipmentSlotPrefix .. "Glove"] = true,
    [equipmentSlotPrefix .. "Leg"] = true,
    [equipmentSlotPrefix .. "Chest"] = true,
    [equipmentSlotPrefix .. "Belt"] = true,
    [equipmentSlotPrefix .. "Foot"] = true,
    [equipmentSlotPrefix .. "Costume"] = true,
    [equipmentSlotPrefix .. "Neck"] = true,
    [equipmentSlotPrefix .. "Ring1"] = true,
    [equipmentSlotPrefix .. "Ring2"] = true,
    [equipmentSlotPrefix .. "MainHand"] = true,
    [equipmentSlotPrefix .. "OffHand"] = true,
    [equipmentSlotPrefix .. "Poison"] = true,
    [equipmentSlotPrefix .. "BackupMain"] = true,
    [equipmentSlotPrefix .. "BackupOff"] = true,
    [equipmentSlotPrefix .. "BackupPoison"] = true,
}

--Table with the eqipment slot control names which are armor
mappingVars.characterEquipmentArmorSlots = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_HEAD]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_CHEST]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_SHOULDERS]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_WAIST]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_LEGS]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_FEET]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_HAND]] = true,
}

--Table with the eqipment slot control names which are jewelry
mappingVars.characterEquipmentJewelrySlots = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_NECK]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = true,
}

--Table with the eqipment slot control names which are weapons
mappingVars.characterEquipmentWeaponSlots = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_POISON]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_POISON]] = true,
}

--Mapping table fo one ring to the other
mappingVars.equipmentJewelryRing2RingSlot = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2],
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1],
}

--Table with allowed control names for the character equipment weapon and offhand weapon slots
checkVars.allowedCharacterEquipmentWeaponControlNames = {
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
   }
--Table with weapon backup slot names
checkVars.allowedCharacterEquipmentWeaponBackupControlNames = {
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
   }
--Table with allowed control names for the character equipment jewelry rings
checkVars.allowedCharacterEquipmentJewelryRingControlNames = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = true,
}
--Table with allowed control names for the character equipment jewelry
checkVars.allowedCharacterEquipmentJewelryControlNames = mappingVars.characterEquipmentJewelrySlots

--Table with weapon and jewelry slot names for equipment checks
checkVars.equipmentSlotsNames = {
    ["no_auto_mark"] = {
		[characterEquipmentSlotNameByIndex[EQUIP_SLOT_COSTUME]] = true,
    }
}

--The check table to check on which inventory filterTypes the junk entries in the additional inventory "flag"
--context menus should not be added!
checkVars.doNotShowJunkAdditionalContextMenuEntryFilterTypes = {
    [ITEMFILTERTYPE_QUICKSLOT]  = true,
    [ITEMFILTERTYPE_QUEST]      = true,
}

--The markerIcons which should do a trait check on the items if they will be checked for research
checkVars.researchTraitCheck = {
    [FCOIS_CON_ICON_RESEARCH] = true,
}
--The item traits which are not allowed for research
checkVars.researchTraitCheckTraitsNotAllowed = {
    [ITEM_TRAIT_TYPE_NONE]              = true,
    [ITEM_TRAIT_TYPE_ARMOR_ORNATE]      = true,
    [ITEM_TRAIT_TYPE_JEWELRY_ORNATE]    = true,
    [ITEM_TRAIT_TYPE_WEAPON_ORNATE]     = true,
}
--The possible checkWere panels for the antiSettings reenable checks
--See file src/FCOIS_Settings.lua, function FCOIS.autoReenableAntiSettingsCheck(checkWhere)
checkVars.autoReenableAntiSettingsCheckWheres = {
    [1] = "CRAFTING_STATION",
    [2] = "STORE",
    [3]	= "GUILD_STORE",
    [4] = "DESTROY",
    [5] = "TRADE",
    [6] = "MAIL",
    [7] = "RETRAIT",
    [8] = "GUILDBANK",
}
--The entry for "all" the antisettings reenable panel checks above
checkVars.autoReenableAntiSettingsCheckWheresAll = "-ALL-"
--The filter panelÍds which need to be checked if anti-destroy is checked
checkVars.filterPanelIdsForAntiDestroy = {
    [LF_INVENTORY]          = true,
    [LF_BANK_WITHDRAW]      = true,
    [LF_HOUSE_BANK_WITHDRAW]= true,
    [LF_BANK_DEPOSIT]       = true,
    [LF_GUILDBANK_DEPOSIT]  = true,
    [LF_HOUSE_BANK_DEPOSIT] = true,
}

--BagId to SetTracker addon settings in FCOIS
mappingVars.bagToSetTrackerSettings = {
	--[[ Will be filled as the settings got loaded
		--> See function updateSettingsBeforeAddonMenu
    ]]
}

--The traits of armor, jewelry or weapon
mappingVars.traits = {}
--Armor
mappingVars.traits.armorTraits = {
    --Divines
    [ITEM_TRAIT_TYPE_ARMOR_DIVINES] = GetString(SI_ITEMTRAITTYPE18),
    --Impenetrable
    [ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = GetString(SI_ITEMTRAITTYPE12),
    --Infused
    [ITEM_TRAIT_TYPE_ARMOR_INFUSED]  = GetString(SI_ITEMTRAITTYPE4),
    --Intricate
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE]  = GetString(SI_ITEMTRAITTYPE9),
    --Nirnhoned
    [ITEM_TRAIT_TYPE_ARMOR_NIRNHONED] = GetString(SI_ITEMTRAITTYPE25),
    --Ornate
    [ITEM_TRAIT_TYPE_ARMOR_ORNATE] = GetString(SI_ITEMTRAITTYPE19),
    --Prosperous
    [ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS] = GetString(SI_ITEMTRAITTYPE17),
    --Reinforced
    [ITEM_TRAIT_TYPE_ARMOR_REINFORCED] = GetString(SI_ITEMTRAITTYPE13),
    --Sturdy
    [ITEM_TRAIT_TYPE_ARMOR_STURDY] = GetString(SI_ITEMTRAITTYPE11),
    --Training
    [ITEM_TRAIT_TYPE_ARMOR_TRAINING] = GetString(SI_ITEMTRAITTYPE15),
    --Well fitted
    [ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED] = GetString(SI_ITEMTRAITTYPE14),
}
--Jewelry
mappingVars.traits.jewelryTraits = {
	[ITEM_TRAIT_TYPE_JEWELRY_ARCANE]		= GetString(SI_ITEMTRAITTYPE22),
	[ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY]	= GetString(SI_ITEMTRAITTYPE31),
	[ITEM_TRAIT_TYPE_JEWELRY_HARMONY] 		= GetString(SI_ITEMTRAITTYPE29),
	[ITEM_TRAIT_TYPE_JEWELRY_HEALTHY] 		= GetString(SI_ITEMTRAITTYPE21),
	[ITEM_TRAIT_TYPE_JEWELRY_INFUSED] 		= GetString(SI_ITEMTRAITTYPE33),
	[ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] 	= GetString(SI_ITEMTRAITTYPE27),
	[ITEM_TRAIT_TYPE_JEWELRY_ORNATE] 		= GetString(SI_ITEMTRAITTYPE24),
	[ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE] 	= GetString(SI_ITEMTRAITTYPE32),
	[ITEM_TRAIT_TYPE_JEWELRY_ROBUST] 		= GetString(SI_ITEMTRAITTYPE23),
	[ITEM_TRAIT_TYPE_JEWELRY_SWIFT] 		= GetString(SI_ITEMTRAITTYPE28),
	[ITEM_TRAIT_TYPE_JEWELRY_TRIUNE] 		= GetString(SI_ITEMTRAITTYPE30),
}
--Weapons
mappingVars.traits.weaponTraits = {
	-- WEAPONS
    --Charged
    [ITEM_TRAIT_TYPE_WEAPON_CHARGED]  = GetString(SI_ITEMTRAITTYPE2),
    --Decisive
    [ITEM_TRAIT_TYPE_WEAPON_DECISIVE]  = GetString(SI_ITEMTRAITTYPE8),
    --Defending
    [ITEM_TRAIT_TYPE_WEAPON_DEFENDING]  = GetString(SI_ITEMTRAITTYPE5),
    --Infused
    [ITEM_TRAIT_TYPE_WEAPON_INFUSED] = GetString(SI_ITEMTRAITTYPE4),
    --Intricate
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE]  = GetString(SI_ITEMTRAITTYPE9),
    --Nirnhoned
    [ITEM_TRAIT_TYPE_WEAPON_NIRNHONED] = GetString(SI_ITEMTRAITTYPE25),
    --Ornate
    [ITEM_TRAIT_TYPE_WEAPON_ORNATE] = GetString(SI_ITEMTRAITTYPE10),
    --Powered
    [ITEM_TRAIT_TYPE_WEAPON_POWERED]  = GetString(SI_ITEMTRAITTYPE1),
    --Precise
    [ITEM_TRAIT_TYPE_WEAPON_PRECISE]  = GetString(SI_ITEMTRAITTYPE3),
    --Sharpened
    [ITEM_TRAIT_TYPE_WEAPON_SHARPENED]  = GetString(SI_ITEMTRAITTYPE7),
    --Training
    [ITEM_TRAIT_TYPE_WEAPON_TRAINING]  = GetString(SI_ITEMTRAITTYPE6),
}

--SHIELDs (SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_SHIELD)
mappingVars.traits.weaponShieldTraits = {
	--Sturdy
	[ITEM_TRAIT_TYPE_ARMOR_STURDY] = GetString(SI_ITEMTRAITTYPE11),
	--Impenetrable
	[ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = GetString(SI_ITEMTRAITTYPE12),
	--Reinforced
	[ITEM_TRAIT_TYPE_ARMOR_REINFORCED] = GetString(SI_ITEMTRAITTYPE13),
	--Well fitted
	[ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED] = GetString(SI_ITEMTRAITTYPE14),
	--Training
	[ITEM_TRAIT_TYPE_ARMOR_TRAINING] = GetString(SI_ITEMTRAITTYPE15),
	--Infused
	[ITEM_TRAIT_TYPE_ARMOR_INFUSED]  = GetString(SI_ITEMTRAITTYPE4),
	--Prosperous & Exploration
	[ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS] = GetString(SI_ITEMTRAITTYPE17),
	--Exploration
	--[ITEM_TRAIT_TYPE_ARMOR_EXPLORATION] = GetString(SI_ITEMTRAITTYPE17),
	--Divines
	[ITEM_TRAIT_TYPE_ARMOR_DIVINES] = GetString(SI_ITEMTRAITTYPE18),
	--Intricate
	[ITEM_TRAIT_TYPE_ARMOR_INTRICATE]  = GetString(SI_ITEMTRAITTYPE9),
	--Nirnhoned
	[ITEM_TRAIT_TYPE_ARMOR_NIRNHONED] = GetString(SI_ITEMTRAITTYPE25),
	--Ornate
	[ITEM_TRAIT_TYPE_ARMOR_ORNATE] = GetString(SI_ITEMTRAITTYPE19),
}

--The mapping table for the additional inventory context menu buttons (flag icon) to icon id
contextMenuVars.buttonContextMenuToIconId = {}
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.buttonContextMenuToIconIdIndex = {}
--The table for the context menu marker icons in the additional inventory "flag" context menu, but only non-dynamic icons
contextMenuVars.buttonContextMenuNonDynamicIcons = {
    [1]     = FCOIS_CON_ICON_LOCK,
    [2]     = FCOIS_CON_ICON_GEAR_1,
    [3]     = FCOIS_CON_ICON_GEAR_2,
    [4]     = FCOIS_CON_ICON_GEAR_3,
    [5]     = FCOIS_CON_ICON_GEAR_4,
    [6]     = FCOIS_CON_ICON_GEAR_5,
    [7]     = FCOIS_CON_ICON_RESEARCH,
    [8]     = FCOIS_CON_ICON_DECONSTRUCTION,
    [9]     = FCOIS_CON_ICON_IMPROVEMENT,
    [10]    = FCOIS_CON_ICON_SELL,
    [11]    = FCOIS_CON_ICON_SELL_AT_GUILDSTORE,
    [12]    = FCOIS_CON_ICON_INTRICATE,
}

--Context menu variables for additional inventory buttons ("flag" icon)
contextMenuVars.maxWidth			= 275
contextMenuVars.maxHeight			= 880 -- old 880 before dynamic icons 11 to 30 were added, more old 721 before 6 new dynamic icons 5 to 10 were added, even more older 561 before the first 4 dynamic icons were added
contextMenuVars.entryHeight		= 20
contextMenuVars.maxCharactersInLine = 32
--Context menu variables for filter buttons
contextMenuVars.filterButtons = {}
contextMenuVars.filterButtons.maxWidth = 24
contextMenuVars.filterButtons.entryHeight = 24

--The table with the undo entries for last changes by context menu
contextMenuVars.undoMarkedItems = {}
--The name prefix of the context menu inventory buttons
contextMenuVars.buttonNamePrefix = "ButtonContextMenu"
local buttonNamePrefix = contextMenuVars.buttonNamePrefix

--The available contextmenus at the filter buttons
contextMenuVars.availableCtms = {
    [FCOIS_CON_FILTER_BUTTON_LOCKDYN]       = "LockDyn",
    [FCOIS_CON_FILTER_BUTTON_GEARSETS]      = "Gear",
    [FCOIS_CON_FILTER_BUTTON_RESDECIMP]     = "ResDecImp",
    [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]  = "SellGuildInt",
}

--The self-build contextMenus (filter buttons)
FCOIS.contextMenu = {}
local fcoisContextMenu = FCOIS.contextMenu
--The context menu for the lock & dynmic icons filter button
fcoisContextMenu.LockDynFilter 	= {}
fcoisContextMenu.LockDynFilterName = contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN] .. "Filter"
fcoisContextMenu.ContextMenuLockDynFilterName = "ContextMenu" .. fcoisContextMenu.LockDynFilterName
fcoisContextMenu.LockDynFilter.bdSelectedLine = {}
--Lock & dynamic icons filter split context menu variables
contextMenuVars.LockDynFilter	= {}
contextMenuVars.LockDynFilter.maxWidth		= contextMenuVars.filterButtons.maxWidth
contextMenuVars.LockDynFilter.maxHeight		= 288 -- OLD: 288 before additional 20 dynamic icons were added
contextMenuVars.LockDynFilter.entryHeight	    = contextMenuVars.filterButtons.entryHeight
--The prefix of the LockDynFilter entries
contextMenuVars.LockDynFilter.buttonNamePrefix = contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN] .. "Filter"
--The entries in the following mapping array
contextMenuVars.LockDynFilter.buttonContextMenuToIconIdEntries = 32 -- OLD: 12 before additional 20 dynamic icons were added
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.LockDynFilter.buttonContextMenuToIconIdIndex = {}
for index=1, contextMenuVars.LockDynFilter.buttonContextMenuToIconIdEntries do
	table.insert(contextMenuVars.LockDynFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. contextMenuVars.LockDynFilter.buttonNamePrefix .. index)
end

--The context menu for the gear sets filter button
fcoisContextMenu.GearSetFilter 	= {}
fcoisContextMenu.GearSetFilterName = contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS] .. "Filter"
fcoisContextMenu.ContextMenuGearSetFilterName = "ContextMenu" .. fcoisContextMenu.GearSetFilterName
fcoisContextMenu.GearSetFilter.bdSelectedLine = {}
--Gear set filter split context menu variables
contextMenuVars.GearSetFilter	= {}
contextMenuVars.GearSetFilter.maxWidth		= contextMenuVars.filterButtons.maxWidth
contextMenuVars.GearSetFilter.maxHeight		= 144
contextMenuVars.GearSetFilter.entryHeight	    = contextMenuVars.filterButtons.entryHeight
--The prefix of the GearSetFilter entries
contextMenuVars.GearSetFilter.buttonNamePrefix = contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS] .. "Filter"
--The entries in the following mapping array
contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries = 6
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex = {}
for index=1, contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries do
	table.insert(contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. contextMenuVars.GearSetFilter.buttonNamePrefix .. index)
end

--The context menu for the RESEARCH & DECONSTRUCTION & IMPORVEMENT filter button
fcoisContextMenu.ResDecImpFilter 	= {}
fcoisContextMenu.ResDecImpFilterName =  contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP] .. "Filter"
fcoisContextMenu.ContextMenuResDecImpFilterName = "ContextMenu" .. fcoisContextMenu.ResDecImpFilterName
fcoisContextMenu.ResDecImpFilter.bdSelectedLine = {}
--Research/Deconstruction filter split context menu variables
contextMenuVars.ResDecImpFilter	= {}
contextMenuVars.ResDecImpFilter.maxWidth      = contextMenuVars.filterButtons.maxWidth
contextMenuVars.ResDecImpFilter.maxHeight	    = 96
contextMenuVars.ResDecImpFilter.entryHeight	= contextMenuVars.filterButtons.entryHeight
--The prefix of the ResDecImpFilter entries
contextMenuVars.ResDecImpFilter.buttonNamePrefix = contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP] .. "Filter"
--The entries in the following mapping array
contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdEntries = 4
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdIndex = {}
for index=1, contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdEntries do
	table.insert(contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. contextMenuVars.ResDecImpFilter.buttonNamePrefix .. index)
end

--The context menu for the SELL & SELL IN GUILD STORE & INTRICATE  filter button
fcoisContextMenu.SellGuildIntFilter 	= {}
fcoisContextMenu.SellGuildIntFilterName = contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] .. "Filter"
fcoisContextMenu.ContextMenuSellGuildIntFilterName = "ContextMenu" .. fcoisContextMenu.SellGuildIntFilterName
fcoisContextMenu.SellGuildIntFilter.bdSelectedLine = {}
--Sell/Guild sell/Intricate filter split context menu variables
contextMenuVars.SellGuildIntFilter	= {}
contextMenuVars.SellGuildIntFilter.maxWidth       = contextMenuVars.filterButtons.maxWidth
contextMenuVars.SellGuildIntFilter.maxHeight      = 96
contextMenuVars.SellGuildIntFilter.entryHeight    = contextMenuVars.filterButtons.entryHeight
--The prefix of the SellGuildIntFilter entries
contextMenuVars.SellGuildIntFilter.buttonNamePrefix = contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] .. "Filter"
--The entries in the following mapping array
contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdEntries = 4
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdIndex = {}
for index=1, contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdEntries do
	table.insert(contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. index)
end

--Mapping array fo the filter button context menu types and their settings
mappingVars.contextMenuFilterButtonTypeToSettings = {}

--Mapping for the context menu type to it's filter button
mappingVars.contextMenuButtonClickedMenuToButton = {
	[contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]] 		= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]]		= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]] 	    = FCOIS_CON_FILTER_BUTTON_RESDECIMP,
	[contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]]	= FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
}

--The textures for the button context menu, selected item
contextMenuVars.menuInfo =
{
	[MENU_TYPE_DEFAULT] =
    {
        backdropEdge       = "EsoUI/Art/miscellaneous/insethighlight_edge.dds",
        backdropCenter     = "EsoUI/Art/miscellaneous/insethighlight_center.dds",
        backdropInsets     = {16,16,-16,-16},
        backdropEdgeWidth  = 128,
        backdropEdgeHeight = 16,
    }
}
--Initialize the inventory (additional/filter) button context menus & variables used
for i=1, numVars.gFCONumFilterInventoryTypes, 1 do
	if mappingVars.activeFilterPanelIds[i] == true then
		--Additional inventory "flag" button context menus
		preventerVars.gContextCreated[i] 				        = false
		--Inventory filter buttons context menus
        --Lock & dynamic filter button context menus
        preventerVars.gLockDynFilterContextCreated[i]	        = false
	    fcoisContextMenu.LockDynFilter[i]	  	 			        = nil
	    fcoisContextMenu.LockDynFilter.bdSelectedLine[i]		    = nil
		--Gear sets filter button context menus
        preventerVars.gGearSetFilterContextCreated[i]	        = false
	    fcoisContextMenu.GearSetFilter[i]	  	 			        = nil
	    fcoisContextMenu.GearSetFilter.bdSelectedLine[i]		    = nil
		--Research, Deconstruction, Improvement filter button context menus
        fcoisContextMenu.ResDecImpFilter[i]	  	 			    = nil
	    fcoisContextMenu.ResDecImpFilter.bdSelectedLine[i]	        = nil
		preventerVars.gResDecImpFilterContextCreated[i]	    = false
        --Sell/Sell in guild store/intricate filter button context menus
        fcoisContextMenu.SellGuildIntFilter[i]	  	 			    = nil
        fcoisContextMenu.SellGuildIntFilter.bdSelectedLine[i]	    = nil
        preventerVars.gSellGuildIntFilterContextCreated[i]	= false
		--Initialize the variable for the last choosen filter button
        FCOIS.lastVars.gLastFilterId[i]                             = LF_INVENTORY
    end
end

--The additional inventory "flag" context menu textures (-> the flag icon)
invAddButtonVars.texNormal = "/esoui/art/ava/tabicon_bg_score_inactive.dds"
invAddButtonVars.texMouseOver = "/esoui/art/ava/tabicon_bg_score_disabled.dds"
--The mapping table for the additional inventory "flag" context menu invoker buttons, their name, their parent and their settings
local additionalFCOISInvContextmenuButtonNameString = "ButtonFCOISAdditionalOptions"
invAddButtonVars.playerInventoryFCOAdditionalOptionsButton = ctrlVars.INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.playerBankWithdrawButtonAdditionalOptions = "FCOIS_PlayerBankWithdraw" .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.guildBankFCOWithdrawButtonAdditionalOptions = "FCOIS_GuildBankWithdraw" .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions = ctrlVars.REFINEMENT_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions = ctrlVars.DECONSTRUCTION_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions = ctrlVars.IMPROVEMENT_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.enchantingTopLevelInventoryButtonAdditionalOptions = ctrlVars.ENCHANTING_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.craftBagInventoryButtonAdditionalOptions = ctrlVars.CRAFTBAG_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.retraitInventoryButtonAdditionalOptions = ctrlVars.RETRAIT_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.houseBankInventoryButtonAdditionalOptions = ctrlVars.HOUSE_BANK_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
--The mapping between the panel (libFilters filter ID LF_*) and the button data -> See file FCOIS_settings.lua -> function AfterSettings() for additional added data
--and file FCOIS_constants.lua at the bottom for the anchorvars for each API version.
--Entries without a parent and without "addInvButton" boolean == true will not be added again as another panel (like LF_INVENTORY) is reused for the button.
--The entry is only there to get the button's name for the functions in file "fcoisContextMenus.lua" to show/hide it.
--> To check what entries the context menu below this invokerButton will create/show check the file src/fcoisContextMenus.lua, function FCOIS.showContextMenuForAddInvButtons(invokerButton)
contextMenuVars.filterPanelIdToContextMenuButtonInvoker = {
	[LF_INVENTORY] 					= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.INV,
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton
    },
	[LF_BANK_WITHDRAW] 				= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.BANK_INV,
        ["name"]          = invAddButtonVars.playerBankWithdrawButtonAdditionalOptions
    },
	[LF_BANK_DEPOSIT] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
	[LF_GUILDBANK_WITHDRAW] 		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.GUILD_BANK_INV,
        ["name"]          = invAddButtonVars.guildBankFCOWithdrawButtonAdditionalOptions
    },
	[LF_GUILDBANK_DEPOSIT]			= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
    [LF_VENDOR_BUY] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
    [LF_VENDOR_SELL] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
    [LF_VENDOR_BUYBACK] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
	[LF_VENDOR_REPAIR] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
    [LF_SMITHING_REFINE]		   	= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.REFINEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions
    },
    [LF_SMITHING_DECONSTRUCT]  		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.DECONSTRUCTION_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions
    },
    [LF_SMITHING_IMPROVEMENT]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.IMPROVEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions
    },
	[LF_GUILDSTORE_SELL] 	 		= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
	[LF_MAIL_SEND] 					= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
	[LF_TRADE] 						= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
	[LF_ENCHANTING_CREATION]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.ENCHANTING_INV,
        ["name"]          = invAddButtonVars.enchantingTopLevelInventoryButtonAdditionalOptions
    },
	[LF_ENCHANTING_EXTRACTION]		= {
        ["name"]          = invAddButtonVars.enchantingTopLevelInventoryButtonAdditionalOptions             --Same like enchanting creation
    },
	[LF_FENCE_SELL] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
	[LF_FENCE_LAUNDER] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
    --Added with API 100015 for the crafting bags that you only got access too if you are an ESO+ subscriber
    [LF_CRAFTBAG]					= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.CRAFTBAG,
        ["name"]          = invAddButtonVars.craftBagInventoryButtonAdditionalOptions
    },
    --Added with API 100021 Clockwork city: Retrait of items
    [LF_RETRAIT]                    = {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.RETRAIT_INV,
        ["name"]          = invAddButtonVars.retraitInventoryButtonAdditionalOptions
    },
    --Added with API 100022 Dragon bones: House storage, named House bank
    [LF_HOUSE_BANK_WITHDRAW]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.HOUSE_BANK_INV,
        ["name"]          = invAddButtonVars.houseBankInventoryButtonAdditionalOptions
    },
    [LF_HOUSE_BANK_DEPOSIT]			= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
    --Added with API 100023 Summerset: SMITHING for jewelry
    [LF_JEWELRY_REFINE]		   	= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.REFINEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions
    },
    [LF_JEWELRY_DECONSTRUCT]  		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.DECONSTRUCTION_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions
    },
    [LF_JEWELRY_IMPROVEMENT]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.IMPROVEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions
    },

}

--Constants for the filter item number sort header entries "name" at the filter panels
FCOIS.sortHeaderVars = {}
local sortByNameNameStr = "SortByNameName"
local sortHeaderNames = {
    [LF_INVENTORY]              = ctrlVars.INV_NAME .. sortByNameNameStr,
    [LF_VENDOR_BUY]             = ctrlVars.STORE_NAME .. sortByNameNameStr,
    [LF_VENDOR_BUYBACK]         = ctrlVars.STORE_BUY_BACK_NAME .. sortByNameNameStr,
    [LF_VENDOR_REPAIR]          = ctrlVars.REPAIR_NAME .. sortByNameNameStr,
    [LF_BANK_DEPOSIT]           = ctrlVars.INV_NAME .. sortByNameNameStr,
    [LF_BANK_WITHDRAW]          = ctrlVars.BANK_INV_NAME .. sortByNameNameStr,
    [LF_GUILDBANK_DEPOSIT]      = ctrlVars.INV_NAME .. sortByNameNameStr,
    [LF_GUILDBANK_WITHDRAW]     = ctrlVars.GUILD_BANK_INV_NAME .. sortByNameNameStr,
    [LF_SMITHING_REFINE]        = ctrlVars.REFINEMENT_INV_NAME .. sortByNameNameStr,
    [LF_SMITHING_DECONSTRUCT]   = ctrlVars.DECONSTRUCTION_INV_NAME .. sortByNameNameStr,
    [LF_SMITHING_IMPROVEMENT]   = ctrlVars.IMPROVEMENT_INV_NAME .. sortByNameNameStr,
    [LF_ALCHEMY_CREATION]       = ctrlVars.ALCHEMY_INV_NAME .. sortByNameNameStr,
    [LF_ENCHANTING_CREATION]    = ctrlVars.ENCHANTING_INV_NAME .. sortByNameNameStr,
    [LF_CRAFTBAG]               = ctrlVars.CRAFTBAG_NAME .. sortByNameNameStr,
    [LF_RETRAIT]                = ctrlVars.RETRAIT_INV_NAME .. sortByNameNameStr,
    [LF_HOUSE_BANK_WITHDRAW]	= ctrlVars.HOUSE_BANK_INV_NAME .. sortByNameNameStr,
    [LF_QUICKSLOT]              = ctrlVars.QUICKSLOT_NAME .. sortByNameNameStr,
}
local sortHeaderInventoryName = sortHeaderNames[LF_INVENTORY]
sortHeaderNames[LF_MAIL_SEND]              = sortHeaderInventoryName
sortHeaderNames[LF_TRADE]                  = sortHeaderInventoryName
sortHeaderNames[LF_GUILDSTORE_SELL]        = sortHeaderInventoryName
sortHeaderNames[LF_BANK_DEPOSIT]           = sortHeaderInventoryName
sortHeaderNames[LF_GUILDBANK_DEPOSIT]      = sortHeaderInventoryName
sortHeaderNames[LF_VENDOR_SELL]            = sortHeaderInventoryName
sortHeaderNames[LF_FENCE_SELL]             = sortHeaderInventoryName
sortHeaderNames[LF_FENCE_LAUNDER]          = sortHeaderInventoryName
sortHeaderNames[LF_HOUSE_BANK_DEPOSIT]     = sortHeaderInventoryName
sortHeaderNames[LF_JEWELRY_REFINE]         = sortHeaderNames[LF_SMITHING_REFINE]
sortHeaderNames[LF_JEWELRY_DECONSTRUCT]    = sortHeaderNames[LF_SMITHING_DECONSTRUCT]
sortHeaderNames[LF_JEWELRY_IMPROVEMENT]    = sortHeaderNames[LF_SMITHING_IMPROVEMENT]
sortHeaderNames[LF_ENCHANTING_EXTRACTION]  = sortHeaderNames[LF_ENCHANTING_CREATION]
--The sort header name lookup table
FCOIS.sortHeaderVars.name = sortHeaderNames

--The variable containing the number of filtered items at the different panels
FCOIS.numberOfFilteredItems = {}

--Levels
mappingVars.levels = {
    [1] = 5,
    [2] = 10,
    [3] = 15,
    [4] = 20,
    [5] = 25,
    [6] = 30,
    [7] = 35,
    [8] = 40,
    [9] = 45,
    [10] = 50,
}
--Champion ranks
mappingVars.maxCPLevel = GetChampionPointsPlayerProgressionCap() -- The current maxmium of Champion ranks
mappingVars.CPlevels = {}
local cpCnt = 1
for cpRank = 10, mappingVars.maxCPLevel, 10 do
    mappingVars.CPlevels[cpCnt] = cpRank
    cpCnt = cpCnt + 1
end
--Build the level 2 threshold mapping array for the settingsmenu dropdownbox value -> comparison with item's level
mappingVars.levelToThreshold = {}
if mappingVars.levels ~= nil then
    for _, level in ipairs(mappingVars.levels) do
        if level > 0 then
            mappingVars.levelToThreshold[tostring(level)] = level
        end
    end
end
--Afterwards add the CP ranks
if mappingVars.CPlevels ~= nil then
    for _, CPRank in ipairs(mappingVars.CPlevels) do
        if CPRank > 0 then
            mappingVars.levelToThreshold[tostring("CP") .. CPRank] = CPRank
        end
    end
end
--Global "all levels" table. Will be filled in file "FCOIS_SettingsMenu.lua" in function "FCOIS.BuildAddonMenu()"
--as the levelList array is build for the LAM dropdown box (for the automatic marking -> non-wished -> levels)
mappingVars.allLevels = {}

--The additional inventory flag context menu anti-* settings buttons
local buttonContextMenuToggleAntiPrefix = "button_context_menu_toggle_anti_"
local buttonContextMenuDestroy  = buttonContextMenuToggleAntiPrefix .."destroy_"
local buttonContextMenuSell     = buttonContextMenuToggleAntiPrefix .."sell_"
local buttonContextMenuRefine   = buttonContextMenuToggleAntiPrefix .."refine_"
local buttonContextMenuDecon    = buttonContextMenuToggleAntiPrefix .."deconstruct_"
local buttonContextMenuImprove  = buttonContextMenuToggleAntiPrefix .."improve_"
mappingVars.contextMenuAntiButtonsAtPanel = {
    [LF_INVENTORY] 				= buttonContextMenuDestroy,
    [LF_BANK_WITHDRAW] 			= buttonContextMenuDestroy,
    [LF_BANK_DEPOSIT] 			= buttonContextMenuDestroy,
    [LF_GUILDBANK_WITHDRAW] 	= buttonContextMenuDestroy,
    [LF_GUILDBANK_DEPOSIT]		= buttonContextMenuDestroy,
    [LF_VENDOR_BUY] 			= buttonContextMenuToggleAntiPrefix .."buy_",
    [LF_VENDOR_SELL] 			= buttonContextMenuSell,
    [LF_VENDOR_BUYBACK] 		= buttonContextMenuToggleAntiPrefix .."buyback_",
    [LF_VENDOR_REPAIR] 			= buttonContextMenuToggleAntiPrefix .."repair_",
    [LF_SMITHING_REFINE]  		= buttonContextMenuRefine,
    [LF_SMITHING_DECONSTRUCT]  	= buttonContextMenuDecon,
    [LF_SMITHING_IMPROVEMENT]	= buttonContextMenuImprove,
    [LF_SMITHING_RESEARCH]		= "",
    [LF_SMITHING_RESEARCH_DIALOG] = "",
    [LF_GUILDSTORE_SELL] 	 	= buttonContextMenuSell,
    [LF_MAIL_SEND] 				= buttonContextMenuToggleAntiPrefix .."mail_",
    [LF_TRADE] 					= buttonContextMenuToggleAntiPrefix .."trade_",
    [LF_ENCHANTING_CREATION]	= buttonContextMenuToggleAntiPrefix .."create_",
    [LF_ENCHANTING_EXTRACTION]	= buttonContextMenuToggleAntiPrefix .."extract_",
    [LF_FENCE_SELL] 			= buttonContextMenuToggleAntiPrefix .."fence_sell_",
    [LF_FENCE_LAUNDER] 			= buttonContextMenuToggleAntiPrefix .."launder_sell_",
    [LF_CRAFTBAG]				= buttonContextMenuDestroy,
    [LF_RETRAIT]				= buttonContextMenuToggleAntiPrefix .."retrait_",
    [LF_HOUSE_BANK_WITHDRAW]    = buttonContextMenuDestroy,
    [LF_HOUSE_BANK_DEPOSIT] 	= buttonContextMenuDestroy,
    [LF_JEWELRY_REFINE]  		= buttonContextMenuRefine,
    [LF_JEWELRY_DECONSTRUCT]  	= buttonContextMenuDecon,
    [LF_JEWELRY_IMPROVEMENT]	= buttonContextMenuImprove,
    [LF_JEWELRY_RESEARCH]		= "",
    [LF_JEWELRY_RESEARCH_DIALOG] = "",
}

--Mapping for the Transmuation Geode container ItemIds (and flavor text)
mappingVars.containerTransmuation = {}
--Using addon "Item finder" /finditem geode
--[[
Beginning search for "geode"
ID #134583: [Transmutationsgeode]                       1 crystal
ID #134588: [Transmutationsgeode]                       5 crystals
ID #134589: [Uncracked Transmutation Geode]             1-10 crystals
ID #134590: [Transmutationsgeode]                       10 crystals
ID #134591: [Transmutationsgeode]                       50 crystals
ID #134595: [Endlose Transmutationsgeode des Testers]   Only contains more geodes! No crystals! ---> PTS
ID #134618: [Intakte Transmutationsgeode]               4-25 crystals
ID #134622: [Intakte Transmutationsgeode]               1-3 crystals
ID #134623: [Intakte Transmutationsgeode]               1-10 crystals
Finished search. Total results: 9
]]
mappingVars.containerTransmuation.geodeItemIds = {}
local geodeItemIds = mappingVars.containerTransmuation.geodeItemIds
geodeItemIds[134583] = true -- 1
geodeItemIds[134588] = true -- 5
geodeItemIds[134589] = true -- 1-10
geodeItemIds[134590] = true -- 10
geodeItemIds[134591] = true -- 50
geodeItemIds[134618] = true -- 4-25
geodeItemIds[134622] = true -- 1-3
geodeItemIds[134623] = true -- 1-10
geodeItemIds[134595] = true -- Endless geode, reveiling 200 crystals and geodes

------------------------------------------------------------------------------------------------------------------------
--Special item'S itemID (Master weapons, Mahlstrom weapons, etc.)
--> Removd with API 100021 as Maelstrom and Master weapons can be enchanted normally now!
FCOIS.specialItems = {}

--Constant values for the additional inventories "flag" button anchor controls
--dependent on the API version of the game
FCOIS.anchorVars = {}
FCOIS.anchorVars.additionalInventoryFlagButton = {}
local anchorVarsAddInvButtonsFill = FCOIS.anchorVars.additionalInventoryFlagButton
--Current API version, starting with "Clockwork city"
local varX1 = -20
local varY1 = 104
--local varX2 = -101
local varX2 = -20
anchorVarsAddInvButtonsFill[100021] = {}
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY] = {}
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].anchorControl              = ctrlVars.INV
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].left                       = varX1
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].top                        = varY1
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].defaultLeft                = varX1
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].defaultTop                 = varY1
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW] = {}
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].anchorControl          = ctrlVars.BANK_INV
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].left                   = varX1
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].top                    = varY1
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].defaultLeft            = varX1
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].defaultTop             = varY1
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW] = {}
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].anchorControl     = ctrlVars.GUILD_BANK_INV
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].left              = varX1
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].top               = varY1
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].defaultLeft       = varX1
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].defaultTop        = varY1
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].anchorControl        = ctrlVars.REFINEMENT_INV
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].left                 = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].top                  = varY1
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].defaultLeft          = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].defaultTop           = varY1
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].anchorControl   = ctrlVars.DECONSTRUCTION_INV
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].top             = varY1
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].defaultTop      = varY1
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].anchorControl   = ctrlVars.IMPROVEMENT_INV
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].top             = varY1
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].defaultTop      = varY1
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION] = {}
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION] .anchorControl   = ctrlVars.ENCHANTING_INV
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].left             = varX2
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].top              = varY1
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].defaultLeft      = varX2
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].defaultTop       = varY1
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG] = {}
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].anchorControl               = ctrlVars.CRAFTBAG
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].left                        = varX2
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].top                         = varY1
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].defaultLeft                 = varX2
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].defaultTop                  = varY1
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT] = {}
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].anchorControl               = ctrlVars.RETRAIT_INV
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].left                        = varX2
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].top                         = varY1
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].defaultLeft                 = varX2
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].defaultTop                  = varY1
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW] = {}
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].anchorControl   = ctrlVars.HOUSE_BANK_INV
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].left            = varX1
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].top             = varY1
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].defaultLeft     = varX1
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].defaultTop      = varY1
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].anchorControl        = ctrlVars.REFINEMENT_INV
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].left                 = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].top                  = varY1
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].defaultLeft          = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].defaultTop           = varY1
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].anchorControl   = ctrlVars.DECONSTRUCTION_INV
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].top             = varY1
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].defaultTop      = varY1
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].anchorControl   = ctrlVars.IMPROVEMENT_INV
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].top             = varY1
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].defaultTop      = varY1
--Is the current API version unequal one of the above ones?
if FCOIS.APIversion >= 100021 then
	anchorVarsAddInvButtonsFill[FCOIS.APIversion] = {}
    local anchorVarsAddInvButtons = FCOIS.anchorVars.additionalInventoryFlagButton
    -->Not working with for in pairs loop :-( So we need to copy the contents!
    --Use the anchor controls and settings of API 100021
    --setmetatable(anchorVarsAddInvButtons[FCOIS.APIversion], {__index = anchorVarsAddInvButtons[100021]})
    anchorVarsAddInvButtonsFill[FCOIS.APIversion] = anchorVarsAddInvButtons[100021]
end

--For the addon QualitySort: Add some panels where the x axis offset of the additional inventory "flag" button needs to be adjusted
--[[
--FCOIS v1.6.7 - Deactivated
mappingVars.adjustAdditionalFlagButtonOffsetForPanel = {
    [ctrlVars.CRAFTBAG]     = true,
    [ctrlVars.GUILD_BANK_INV]    = true,
    [ctrlVars.REFINEMENT_INV]     = true,
    [ctrlVars.DECONSTRUCTION_INV] = true,
    [ctrlVars.IMPROVEMENT_INV]    = true,
    [ctrlVars.ENCHANTING_INV] = true,
    [ctrlVars.RETRAIT_INV] = true,
}
]]
--The ordinal endings of the different languages
mappingVars.iconNrToOrdinalStr = {
    --English
    [1] =    {
        [1] = "st",
        [2] = "nd",
        [3] = "rd",
        [21] = "st",
        [22] = "nd",
        [23] = "rd",
        [31] = "st",
        [32] = "nd",
        [33] = "rd",
    },
    --French
    [3] =    {
        [1] = "premier",
        [2] = "deuxième",
        [3] = "troisième",
        [4] = "quatrième",
        [5] = "cinquième",
        [6] = "sixième",
        [7] = "septième",
        [8] = "huitième",
        [9] = "neuvième",
        [10] = "dixième",
        [11] = "onzième",
        [12] = "douzième",
        [13] = "treizième",
        [14] = "quatorzième",
        [15] = "quinzième",
        [16] = "seizième",
        [17] = "dix-septième",
        [18] = "dix-huitième",
        [19] = "dix-neuvième",
        [20] = "vingtième",
        [21] = "vingt-et-unième",
        [22] = "vingt-deuxième",
        [23] = "vingt-troisième",
        [24] = "vingt-quatrième",
        [25] = "vingt-cinquième",
        [26] = "vingt-sixième",
        [27] = "vingt-septième",
        [28] = "vingt-huitième",
        [29] = "vingt-neuvième",
        [30] = "trentième",
    },
}