--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

--===================== ADDON Info =============================================
--Addon variables
FCOIS.addonVars = {}
--Addon variables
FCOIS.addonVars.addonVersionOptions 		= '1.6.1' -- version shown in the settings panel
FCOIS.addonVars.addonVersionOptionsNumber	= 1.61
FCOIS.addonVars.gAddonName					= "FCOItemSaver"
FCOIS.addonVars.gAddonNameShort             = "FCOIS"
FCOIS.addonVars.addonNameMenu				= "FCO ItemSaver"
FCOIS.addonVars.addonNameMenuDisplay		= "|c00FF00FCO |cFFFF00ItemSaver|r"
FCOIS.addonVars.addonNameContextMenuEntry   = "     - |c22DD22FCO|r ItemSaver -"
FCOIS.addonVars.addonAuthor 				= '|cFFFF00Baertram|r'
FCOIS.addonVars.addonAuthorDisplayNameEU  	= '@Baertram'
FCOIS.addonVars.addonAuthorDisplayNameNA  	= '@Baertram'
FCOIS.addonVars.addonAuthorDisplayNamePTS  	= '@Baertram'
FCOIS.addonVars.website 					= "https://www.esoui.com/downloads/info630-FCOItemSaver.html"
FCOIS.addonVars.FAQwebsite                  = "https://www.esoui.com/portal.php?id=136&a=faq"
FCOIS.addonVars.authorPortal                = "https://www.esoui.com/portal.php?&id=136"
FCOIS.addonVars.feedback                    = "https://www.esoui.com/portal.php?id=136&a=bugreport"
FCOIS.addonVars.donation                    = "https://www.esoui.com/portal.php?id=136&a=faq&faqid=131"
FCOIS.addonVars.gAddonLoaded				= false
FCOIS.addonVars.gPlayerActivated			= false
FCOIS.addonVars.gSettingsLoaded				= false

--SavedVariables constants
FCOIS.addonVars.savedVarName				= FCOIS.addonVars.gAddonName .. "_Settings"
FCOIS.addonVars.savedVarVersion		   		= 0.10 -- Changing this will reset all SavedVariables!
FCOIS.svDefaultName                         = "Default"
FCOIS.svAccountWideName                     = "$AccountWide"
FCOIS.svAllAccountsName                     = "$AllAccounts"
FCOIS.svSettingsForAllName                  = "SettingsForAll"
FCOIS.svSettingsName                        = "Settings"

--The global variable for the current mouseDown button
FCOIS.gMouseButtonDown = {}

--Data for the protection (colors, textures, ...)
FCOIS.protectedData = {}
FCOIS.protectedData.colors = {
    [false] = "|cDD2222",
    [true]  = "|c22DD22",
}
FCOIS.protectedData.textures = {
    [false] = "esoui/art/buttons/cancel_up.dds",
    [true]  = "esoui/art/buttons/accept_up.dds",
}
local protectedColors = FCOIS.protectedData.colors
local protectionOffColor    = protectedColors[false]
local protectionOnColor     = protectedColors[true]
--Local pre chat color variables
FCOIS.preChatVars = {}
--Uncolored "FCOIS" pre chat text for the chat output
FCOIS.preChatVars.preChatText = FCOIS.addonVars.gAddonNameShort
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
if FCOIS.LIBLA == nil and LibStub then FCOIS.LIBLA = LibStub:GetLibrary("LibLoadedAddons", true) end
if FCOIS.LIBLA == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibLoadedAddons")) return end

--Create the settings panel object of libAddonMenu 2.0
FCOIS.LAM = LibAddonMenu2
if FCOIS.LAM == nil and LibStub then FCOIS.LAM = LibStub('LibAddonMenu-2.0', true) end
if FCOIS.LAM == nil then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibAddonMenu-2.0")) return end

--The options panel of FCO ItemSaver
FCOIS.FCOSettingsPanel = nil

--Create the libMainMenu 2.0 object
FCOIS.LMM2 = LibMainMenu2
if FCOIS.LMM2 == nil and LibStub then FCOIS.LMM2 = LibStub("LibMainMenu-2.0", true) end
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
if FCOIS.LDIALOG == nil and LibStub then FCOIS.LDIALOG = LibStub('LibDialog', true) end
if not FCOIS.LDIALOG then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibDialog")) return end

--Initialize the library LibFeedback
FCOIS.libFeedback = LibFeedback
if FCOIS.libFeedback == nil and LibStub then FCOIS.libFeedback = LibStub:GetLibrary('LibFeedback', true) end
if not FCOIS.libFeedback then d(preVars.preChatTextRed .. string.format(libMissingErrorText, "LibFeedback")) return end

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
FCOIS_CON_CROWN_ITEM            = 900
FCOIS_CON_FALLBACK 				= 999

--Constant values for the FCOItemSaver filter buttons at the inventories (bottom)
FCOIS_CON_FILTER_BUTTON_LOCKDYN			= 1
FCOIS_CON_FILTER_BUTTON_GEARSETS		= 2
FCOIS_CON_FILTER_BUTTON_RESDECIMP		= 3
FCOIS_CON_FILTER_BUTTON_SELLGUILDINT	= 4
--The check variables/tables
FCOIS.checkVars = {}
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

--The table of number variables
FCOIS.numVars = {}
--Global value: Number of filter icons to choose by right click menu
FCOIS.numVars.languageCount = FCOIS_CON_LANG_MAX --English, German, French, Spanish, Italian, Japanese, Russian
--Global: Count of available inventory filter types (LF_INVENTORY, LF_BANK_WITHDRAW, etc. -> see above)
FCOIS.numVars.gFCONumFilterInventoryTypes = FCOIS.libFilters:GetMaxFilter() -- Maximum libFilters 2.0 filter types
--Global value: Number of filters
FCOIS.numVars.gFCONumFilters			= #FCOIS.checkVars.filterButtonsToCheck
--Global value: Number of non-dynamic and non gear set icons
FCOIS.numVars.gFCONumNonDynamicIcons	= 7
--Global value: Number of gear sets
FCOIS.numVars.gFCONumGearSetsStatic  	= 5
FCOIS.numVars.gFCONumGearSets			= FCOIS.numVars.gFCONumGearSetsStatic
--Global value: Number of non-dynamic normal + gear sets
FCOIS.numVars.gFCONumNonDynamicAndGearIcons	= FCOIS.numVars.gFCONumNonDynamicIcons + FCOIS.numVars.gFCONumGearSetsStatic
--Global value: Number of MAX dynamic icons
FCOIS.numVars.gFCOMaxNumDynamicIcons	= 30
--Global value: Number of dynamic icons
FCOIS.numVars.gFCONumDynamicIcons		= 10
local numMaxDynamicIcons                = FCOIS.numVars.gFCOMaxNumDynamicIcons

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
local markerIconsBefore = FCOIS_CON_ICON_INTRICATE --12
for dynIconNr = 1, numMaxDynamicIcons, 1 do
	markerIconsBefore = markerIconsBefore + 1
	_G["FCOIS_CON_ICON_DYNAMIC_" .. tostring(dynIconNr)] = markerIconsBefore
end
--The maximum marker icons variable
FCOIS.numVars.gFCONumFilterIcons = FCOIS_CON_ICON_DYNAMIC_30 --42, since FCOIS version 1.4.0

--Debug depth levels
FCOIS_DEBUG_DEPTH_NORMAL        = 1
FCOIS_DEBUG_DEPTH_DETAILED	    = 2
FCOIS_DEBUG_DEPTH_VERY_DETAILED	= 3
FCOIS_DEBUG_DEPTH_SPAM		    = 4
FCOIS_DEBUG_DEPTH_ALL			= 5

--The inventory row patterns for the supported keybindings and MouseOverControl checks (SHIFT+right mouse functions e.g.)
--See file src/FCOIS_Functions.lua, function FCOIS.GetBagAndSlotFromControlUnderMouse()
FCOIS.checkVars.inventoryRowPatterns = {
[1] = "^ZO_%a+Backpack%dRow%d%d*",                                          --Inventory backpack
[2] = "^ZO_%a+InventoryList%dRow%d%d*",                                     --Inventory backpack
[3] = "^ZO_CharacterEquipmentSlots.+$",                                     --Character
[4] = "^ZO_CraftBagList%dRow%d%d*",                                         --CraftBag
[5] = "^ZO_Smithing%aRefinementPanelInventoryBackpack%dRow%d%d*",           --Smithing refinement
[6] = "^ZO_RetraitStation_%a+RetraitPanelInventoryBackpack%dRow%d%d*",      --Retrait
[7] = "^ZO_QuickSlotList%dRow%d%d*",                                        --Quickslot
[8] = "^ZO_RepairWindowList%dRow%d%d*",                                     --Repair at vendor
--Other adons like IIfA will be added dynamically at EVENT_ON_ADDON_LOADED callback function
--See file src/FCOIS_Events.lua, call to function FCOIS.checkIfOtherAddonActive() -> See file
-- src/FCOIS_OtherAddons.lua, function FCOIS.checkIfOtherAddonActive()
}

--Array for the mapping between variables and values
FCOIS.mappingVars = {}
FCOIS.mappingVars.noEntry = "-------------"
FCOIS.mappingVars.noEntryValue = 1
local noEntry = FCOIS.mappingVars.noEntry
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
--Local equipment variables
FCOIS.equipmentVars = {}
--Local icon variables
FCOIS.iconVars = {}
--Local custom menu vars
FCOIS.customMenuVars = {}
--Local context menu relating variables
FCOIS.contextMenuVars			= {}
--Local inventory additional button variables
FCOIS.invAdditionalButtonVars = {}
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
FCOIS.contextMenuVars.contextMenuIndex 			= -1

--The allowed check handlers (see function FCOIS.checkIfItemIsProtected() in file FCOIS_Protection.lua)
FCOIS.checkHandlers["gear"]     = true
FCOIS.checkHandlers["dynamic"]  = true

--The mapping between the FCOIS settings ID and the real server name (for the SavedVars)
FCOIS.mappingVars.serverNames = {
    [1] = noEntry,           -- None
    [2] = "EU Megaserver",   -- EU
    [3] = "NA Megaserver",   -- US, North America
    [4] = "PTS",             -- PTS
}

--The bagId to player inventory type mapping
FCOIS.mappingVars.bagToPlayerInv = {
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
--The mapping table for the bagIds where an itemInstanceId or uniqueId should be build for in other addons in order
--to use these for the (un)marking of items (e.g. within addon Inventory Insight from ashes, IIfA)
FCOIS.mappingVars.bagsToBuildItemInstanceOrUniqueIdFor =  {
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
FCOIS.mappingVars.whereAreWeToFilterPanelId = {
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
FCOIS.mappingVars.filterPanelIdToWhereAreWe = {}
for whereAreWe, filterPanelId in pairs(FCOIS.mappingVars.whereAreWeToFilterPanelId) do
    FCOIS.mappingVars.filterPanelIdToWhereAreWe[filterPanelId] = whereAreWe
end

--The array with the alert message texts for every filterPanel
FCOIS.mappingVars.whereAreWeToAlertmessageText = {}

--The active filter panel Ids (filter panel Id = inventory types above!)
FCOIS.mappingVars.activeFilterPanelIds			= {
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

--The mapping array for libFilter inventory type to inventory backpack type
FCOIS.mappingVars.InvToInventoryType = {
	[LF_INVENTORY] 					= INVENTORY_BACKPACK,
	[LF_BANK_WITHDRAW] 				= INVENTORY_BANK,
	[LF_BANK_DEPOSIT]				= INVENTORY_BACKPACK,
	[LF_GUILDBANK_WITHDRAW] 		= INVENTORY_GUILD_BANK,
	[LF_GUILDBANK_DEPOSIT]    		= INVENTORY_BACKPACK,
	[LF_VENDOR_BUY] 				= INVENTORY_BACKPACK,
    [LF_VENDOR_SELL] 				= INVENTORY_BACKPACK,
    [LF_VENDOR_BUYBACK]				= INVENTORY_BACKPACK,
    [LF_VENDOR_REPAIR] 				= INVENTORY_BACKPACK,
	[LF_SMITHING_REFINE]  			= INVENTORY_BACKPACK,
	[LF_SMITHING_DECONSTRUCT]  		= INVENTORY_BACKPACK,
	[LF_SMITHING_IMPROVEMENT]		= INVENTORY_BACKPACK,
	[LF_GUILDSTORE_SELL] 	 		= INVENTORY_BACKPACK,
	[LF_MAIL_SEND] 					= INVENTORY_BACKPACK,
	[LF_TRADE] 						= INVENTORY_BACKPACK,
	[LF_ENCHANTING_CREATION]		= INVENTORY_BACKPACK,
	[LF_ENCHANTING_EXTRACTION]		= INVENTORY_BACKPACK,
	[LF_FENCE_SELL] 				= INVENTORY_BACKPACK,
	[LF_FENCE_LAUNDER]				= INVENTORY_BACKPACK,
    [LF_CRAFTBAG]					= INVENTORY_CRAFT_BAG,
    [LF_RETRAIT]                    = INVENTORY_BACKPACK,
    [LF_HOUSE_BANK_WITHDRAW]        = INVENTORY_HOUSE_BANK,
    [LF_HOUSE_BANK_DEPOSIT]			= INVENTORY_BACKPACK,
	[LF_JEWELRY_REFINE]		        = INVENTORY_BACKPACK,
    [LF_JEWELRY_DECONSTRUCT]		= INVENTORY_BACKPACK,
    [LF_JEWELRY_IMPROVEMENT]		= INVENTORY_BACKPACK,
}
--The mapping array between LibFilters IDs to their filter name string "prefix"
FCOIS_CON_LIBFILTERS_STRING_PREFIX_BACKUP_ID    = 0
FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS        = FCOIS.addonVars.gAddonNameShort .. "_"
FCOIS.mappingVars.libFiltersIds2StringPrefix = {
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
FCOIS.mappingVars.libFiltersId2filterFunction = {}

local function getHouseBankBagId()
    local houseBankBagId = GetBankingBag() or BAG_HOUSE_BANK_ONE
    return houseBankBagId
end

--Mapping array for the LibFilters filter panel ID to inventory bag ID (if relation is 1:1!)
FCOIS.mappingVars.libFiltersId2BagId = {
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
FCOIS.mappingVars.craftingModeAndCraftingTypeToFilterPanelId = {
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

--The supported vendor LibFilters 2.0 panel IDs
FCOIS.mappingVars.supportedVendorPanels = {
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
--variable to override the changed "split filters" settings at function UnregisterFilters()
FCOIS.overrideVars.gSplitFilterOverride		= false

--Available languages
FCOIS.langVars = {}
FCOIS.langVars.languages = {}
--Build the languages array
for i=1, FCOIS.numVars.languageCount do
	FCOIS.langVars.languages[i] = true
end

--Width and height for the icons
FCOIS.iconVars.minIconSize                          = 4
FCOIS.iconVars.maxIconSize                          = 48
FCOIS.iconVars.gIconWidth							= 32
FCOIS.iconVars.gIconHeight             				= 32
--Width and height for the equipment icons
FCOIS.equipmentVars.gEquipmentIconWidth 			= 20
FCOIS.equipmentVars.gEquipmentIconHeight			= 20
--Width and height for the equipment armor type icons
FCOIS.equipmentVars.gEquipmentArmorTypeIconHeight	= 16
FCOIS.equipmentVars.gEquipmentArmorTypeIconWidth 	= 16
--Width and height for the filter buttons - Default values
-->Will be read within file /Src/FCOIS_FilterButtons.lua, function GetFilterButtonDataByPanelId(libFiltersPanelId)
FCOIS.filterButtonVars.gFilterButtonWidth			= 24
FCOIS.filterButtonVars.gFilterButtonHeight     		= 24
FCOIS.filterButtonVars.minFilterButtonWidth         = 4
FCOIS.filterButtonVars.maxFilterButtonWidth         = 128
FCOIS.filterButtonVars.minFilterButtonHeight        = 4
FCOIS.filterButtonVars.maxFilterButtonHeight        = 128
--Left and top of the filter buttons
FCOIS.filterButtonVars.gFilterButtonTop				= 6
FCOIS.filterButtonVars.gFilterButtonLeft	   		= {
 [FCOIS_CON_FILTER_BUTTON_LOCKDYN] 		= -70,
 [FCOIS_CON_FILTER_BUTTON_GEARSETS] 	= -46,
 [FCOIS_CON_FILTER_BUTTON_RESDECIMP] 	= -22,
 [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]	= 2,
}
--Filter button offset Y at the improvement panel bottom (due to the extra "improvement booster bar")
FCOIS.filterButtonVars.buttonOffsetYImprovement = 7

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
FCOIS.ZOControlVars.INV				        	= ZO_PlayerInventory
FCOIS.ZOControlVars.INV_NAME					= FCOIS.ZOControlVars.INV:GetName()
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_ITEMS	= ZO_PlayerInventoryMenuBarButton1
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_CRAFTBAG = ZO_PlayerInventoryMenuBarButton2
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_CURRENCIES = ZO_PlayerInventoryMenuBarButton3
FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_QUICKSLOTS = ZO_PlayerInventoryMenuBarButton4
FCOIS.ZOControlVars.BACKPACK 		    		= ZO_PlayerInventoryBackpack
FCOIS.ZOControlVars.CRAFTBAG					= ZO_CraftBag
FCOIS.ZOControlVars.CRAFTBAG_NAME				= FCOIS.ZOControlVars.CRAFTBAG:GetName()
FCOIS.ZOControlVars.CRAFTBAG_BAG				= ZO_CraftBagListContents
--New since 1000016
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
FCOIS.ZOControlVars.STORE_BUY_BACK              = ZO_BuyBackListContents
FCOIS.ZOControlVars.VENDOR_MAINMENU_BUTTON_BAR  = ""
--FCOIS.ZOControlVars.FENCE						= ZO_Fence_Keyboard_WindowMenu
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
FCOIS.ZOControlVars.GUILD_STORE_SELL_SLOT_ITEM	= ZO_TradingHousePostItemPaneFormInfoItem
------------------------------------------------------------------------------------------------------------------------
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH = ZO_TradingHouseMenuBarButton1
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH_NAME = "ZO_TradingHouseMenuBarButton1"
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_SELL = ZO_TradingHouseMenuBarButton2
FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_LIST = ZO_TradingHouseMenuBarButton3
FCOIS.ZOControlVars.SMITHING                = SMITHING
FCOIS.ZOControlVars.SMITHING = SMITHING
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
FCOIS.ZOControlVars.RESEARCH_POPUP_TOP_DIVIDER  = ZO_ListDialog1Divider
FCOIS.ZOControlVars.LIST_DIALOG 	    		= ZO_ListDialog1List
FCOIS.ZOControlVars.DIALOG_SPLIT_STACK_NAME      = "SPLIT_STACK"
FCOIS.ZOControlVars.MAIL_SEND					= MAIL_SEND
FCOIS.ZOControlVars.MAIL_SEND_NAME			    = FCOIS.ZOControlVars.MAIL_SEND.control:GetName()
FCOIS.ZOControlVars.mailSendSceneName		    = "mailSend"
--FCOIS.ZOControlVars.MAIL_INBOX				= ZO_MailInbox
FCOIS.ZOControlVars.MAIL_ATTACHMENTS			= FCOIS.ZOControlVars.MAIL_SEND.attachmentSlots
--FCOIS.ZOControlVars.MAIL_MENUBAR_BUTTON_SEND  = ZO_MainMenuSceneGroupBarButton2
FCOIS.ZOControlVars.PLAYER_TRADE				= TRADE
FCOIS.ZOControlVars.PLAYER_TRADE_WINDOW         = TRADE_WINDOW
--FCOIS.ZOControlVars.PLAYER_TRADE_NAME			= FCOIS.ZOControlVars.PLAYER_TRADE.control:GetName()
FCOIS.ZOControlVars.PLAYER_TRADE_ATTACHMENTS    = FCOIS.ZOControlVars.PLAYER_TRADE.Columns[TRADE_ME]
FCOIS.ZOControlVars.ENCHANTING                  = ENCHANTING
--FCOIS.ZOControlVars.ENCHANTING				= ZO_Enchanting
FCOIS.ZOControlVars.ENCHANTING_STATION		= ZO_EnchantingTopLevelInventoryBackpack
FCOIS.ZOControlVars.ENCHANTING_STATION_NAME	= FCOIS.ZOControlVars.ENCHANTING_STATION:GetName()
FCOIS.ZOControlVars.ENCHANTING_STATION_BAG	= ZO_EnchantingTopLevelInventoryBackpackContents
--FCOIS.ZOControlVars.ENCHANTING_STATION_MENUBAR_BUTTON_CREATION    = ZO_EnchantingTopLevelModeMenuBarButton1
--FCOIS.ZOControlVars.ENCHANTING_STATION_MENUBAR_BUTTON_EXTRACTION  = ZO_EnchantingTopLevelModeMenuBarButton2
FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER	= ZO_EnchantingTopLevelRuneSlotContainer
FCOIS.ZOControlVars.ENCHANTING_EXTRACTION_SLOT	= ZO_EnchantingTopLevelExtractionSlotContainerExtractionSlot
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
FCOIS.ZOControlVars.PROVISIONER             = PROVISIONER
FCOIS.ZOControlVars.PROVISIONER_PANEL = FCOIS.ZOControlVars.PROVISIONER.control
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
--Transmutation
FCOIS.ZOControlVars.RETRAIT					    = ZO_RetraitStation_Keyboard
FCOIS.ZOControlVars.RETRAIT_RETRAIT_PANEL	    = ZO_RETRAIT_STATION_KEYBOARD.retraitPanel
FCOIS.ZOControlVars.RETRAIT_INV                 = ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventory
FCOIS.ZOControlVars.RETRAIT_INV_NAME		    = FCOIS.ZOControlVars.RETRAIT_INV:GetName()
FCOIS.ZOControlVars.RETRAIT_LIST			    = ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpack
FCOIS.ZOControlVars.RETRAIT_BAG					= ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpackContents
FCOIS.ZOControlVars.RETRAIT_PANEL  	            = ZO_RetraitStation_KeyboardTopLevelRetraitPanel
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
FCOIS.ZOControlVars.ZODialog1 = ZO_Dialog1

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
FCOIS.mappingVars.houseBankBagIdToBag = {
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
--FCOIS.lastVars.gLastEnchantingButton			= FCOIS.ZOControlVars.ENCHANTING_STATION_MENUBAR_BUTTON_CREATION
--FCOIS.lastVars.gLastSmithingButton				= FCOIS.ZOControlVars.SMITHING_MENUBAR_BUTTON_DECONSTRUCTION
FCOIS.lastVars.gLastBankButton					= FCOIS.ZOControlVars.BANK_MENUBAR_BUTTON_WITHDRAW
FCOIS.lastVars.gLastHouseBankButton				= FCOIS.ZOControlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW
FCOIS.lastVars.gLastGuildBankButton   			= FCOIS.ZOControlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW
FCOIS.lastVars.gLastGuildStoreButton			= FCOIS.ZOControlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH
--FCOIS.lastVars.gLastVendorButton				= FCOIS.ZOControlVars.VENDOR_MENUBAR_BUTTON_SELL -> See file src/FCOIS_events.lua, function FCOItemSaver_Open_Store()
--FCOIS.lastVars.gLastMailButton         		= FCOIS.ZOControlVars.MAIL_MENUBAR_BUTTON_SEND
FCOIS.lastVars.gLastAlchemyButton				= FCOIS.ZOControlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION
FCOIS.lastVars.gLastSmithingDeconstructionSubFilterButton 	= FCOIS.ZOControlVars.DECONSTRUCTION_BUTTON_WEAPONS
FCOIS.lastVars.gLastSmithingImprovementSubFilterButton 	= FCOIS.ZOControlVars.IMPROVEMENT_BUTTON_WEAPONS
--FCOIS.lastVars.gLastEnchantingSubFilterButton 	= FCOIS.ZOControlVars.ENCHANTING_BUTTON_GLYPHS
FCOIS.lastVars.gLastInvButton					= FCOIS.ZOControlVars.INV_MENUBAR_BUTTON_ITEMS

--The mapping array for filterPanelId to shown inventories
FCOIS.mappingVars.gFilterPanelIdToInv = {
	[LF_INVENTORY] 							= FCOIS.ZOControlVars.BACKPACK,
	[LF_CRAFTBAG] 							= FCOIS.ZOControlVars.CRAFTBAG,
    [LF_BANK_WITHDRAW] 						= FCOIS.ZOControlVars.BANK,
	[LF_BANK_DEPOSIT]						= FCOIS.ZOControlVars.BACKPACK,
	[LF_GUILDBANK_WITHDRAW] 			   	= FCOIS.ZOControlVars.GUILD_BANK,
	[LF_GUILDBANK_DEPOSIT]					= FCOIS.ZOControlVars.BACKPACK,
    [LF_VENDOR_BUY] 						= FCOIS.ZOControlVars.BACKPACK,
	[LF_VENDOR_SELL] 						= FCOIS.ZOControlVars.BACKPACK,
    [LF_VENDOR_BUYBACK]						= FCOIS.ZOControlVars.BACKPACK,
    [LF_VENDOR_REPAIR] 						= FCOIS.ZOControlVars.BACKPACK,
    [LF_SMITHING_REFINE]					= FCOIS.ZOControlVars.REFINEMENT,
	[LF_SMITHING_DECONSTRUCT]  				= FCOIS.ZOControlVars.DECONSTRUCTION,
	[LF_SMITHING_IMPROVEMENT]				= FCOIS.ZOControlVars.IMPROVEMENT,
	[LF_GUILDSTORE_SELL] 	 		   		= FCOIS.ZOControlVars.BACKPACK,
	[LF_MAIL_SEND] 							= FCOIS.ZOControlVars.BACKPACK,
	[LF_TRADE] 				   				= FCOIS.ZOControlVars.BACKPACK,
    [LF_ENCHANTING_CREATION]				= FCOIS.ZOControlVars.ENCHANTING_STATION,
	[LF_ENCHANTING_EXTRACTION]	 			= FCOIS.ZOControlVars.ENCHANTING_STATION,
	[LF_FENCE_SELL]							= FCOIS.ZOControlVars.BACKPACK,
	[LF_FENCE_LAUNDER]						= FCOIS.ZOControlVars.BACKPACK,
    [LF_ALCHEMY_CREATION]					= FCOIS.ZOControlVars.ALCHEMY_STATION,
    [LF_RETRAIT]						    = FCOIS.ZOControlVars.BACKPACK,
    [LF_HOUSE_BANK_WITHDRAW]				= FCOIS.ZOControlVars.HOUSE_BANK,
    [LF_HOUSE_BANK_DEPOSIT]					= FCOIS.ZOControlVars.BACKPACK,
    [LF_JEWELRY_REFINE]		                = FCOIS.ZOControlVars.REFINEMENT,
    [LF_JEWELRY_DECONSTRUCT]		        = FCOIS.ZOControlVars.DECONSTRUCTION,
    [LF_JEWELRY_IMPROVEMENT]		        = FCOIS.ZOControlVars.IMPROVEMENT,
}

--The array for the texture names of each panel Id
local invTextureName = FCOIS.ZOControlVars.INV_NAME .. "_FilterButton%sTexture"
local refineTextureName = FCOIS.ZOControlVars.REFINEMENT_INV_NAME .. "_FilterButton%sTexture"
local enchantTextureName = FCOIS.ZOControlVars.ENCHANTING_STATION_NAME .. "_FilterButton%sTexture"
local deconTextureName = FCOIS.ZOControlVars.DECONSTRUCTION_INV_NAME .. "_FilterButton%sTexture"
local improveTextureName = FCOIS.ZOControlVars.IMPROVEMENT_INV_NAME .. "_FilterButton%sTexture"
local researchTextureName = FCOIS.ZOControlVars.RESEARCH:GetName() .. "_FilterButton%sTexture"
local researchDialogTextureName = FCOIS.ZOControlVars.RESEARCH_POPUP_TOP_DIVIDER:GetName() .. "_FilterButton%sTexture"
FCOIS.mappingVars.gFilterPanelIdToTextureName = {
	[LF_INVENTORY] 					= invTextureName,
	[LF_CRAFTBAG] 					= FCOIS.ZOControlVars.CRAFTBAG_NAME .. "_FilterButton%sTexture",
    [LF_SMITHING_REFINE]			= refineTextureName,
    [LF_SMITHING_DECONSTRUCT] 		= deconTextureName,
	[LF_SMITHING_IMPROVEMENT] 		= improveTextureName,
    [LF_SMITHING_RESEARCH] 		    = researchTextureName,
    [LF_SMITHING_RESEARCH_DIALOG]   = researchDialogTextureName,
	[LF_VENDOR_BUY] 				= invTextureName,
    [LF_VENDOR_SELL] 				= invTextureName,
    [LF_VENDOR_BUYBACK]				= invTextureName,
    [LF_VENDOR_REPAIR] 				= invTextureName,
	[LF_GUILDBANK_WITHDRAW]			= FCOIS.ZOControlVars.GUILD_BANK_INV_NAME .. "_FilterButton%sTexture",
	[LF_GUILDBANK_DEPOSIT] 			= invTextureName,
	[LF_GUILDSTORE_SELL] 			= invTextureName,
	[LF_BANK_WITHDRAW] 				= FCOIS.ZOControlVars.BANK_INV_NAME .. "_FilterButton%sTexture",
	[LF_BANK_DEPOSIT] 				= invTextureName,
	[LF_ENCHANTING_EXTRACTION] 		= enchantTextureName,
	[LF_ENCHANTING_CREATION] 		= enchantTextureName,
	[LF_MAIL_SEND] 					= invTextureName,
	[LF_TRADE] 						= invTextureName,
	[LF_FENCE_SELL] 				= invTextureName,
	[LF_FENCE_LAUNDER] 				= invTextureName,
	[LF_ALCHEMY_CREATION] 			= FCOIS.ZOControlVars.ALCHEMY_INV_NAME .. "_FilterButton%sTexture",
    [LF_RETRAIT] 		            = FCOIS.ZOControlVars.RETRAIT_INV_NAME .. "_FilterButton%sTexture",
    [LF_HOUSE_BANK_WITHDRAW]		= FCOIS.ZOControlVars.HOUSE_BANK_INV_NAME .. "_FilterButton%sTexture",
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
FCOIS.settingsVars.defaultSettings	= {}
FCOIS.settingsVars.firstRunSettings   = {}
FCOIS.settingsVars.defaults			= {}

FCOIS.markedItems = {}
for i = 1, FCOIS.numVars.gFCONumFilters, 1 do
	FCOIS.markedItems[i] = {}
end

--The itemtypes that are allowed to be marked with unique item IDs
--All not listed item types (or listed with "false") will be saved with the non-unique item ID
FCOIS.allowedUniqueIdItemTypes = {
    [ITEMTYPE_ARMOR]        =   true,
--    [ITEMTYPE_MASTER_WRIT]  =   true,
    [ITEMTYPE_WEAPON]       =   true,
}
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
FCOIS.preventerVars.gLocalizationDone		= false
FCOIS.preventerVars.KeyBindingTexts		= false
FCOIS.preventerVars.gScanningInv	    	= false
--FCOIS.preventerVars.canUpdateInv 	   		= true
FCOIS.preventerVars.gFilteringBasics		= false
FCOIS.preventerVars.gActiveFilterPanel	= false
FCOIS.preventerVars.gNoCloseEvent 		= false
FCOIS.preventerVars.gAllowDestroyItem		= false
FCOIS.preventerVars.wasDestroyDone        = false
FCOIS.preventerVars.gItemSlotIsLocked 	= false
FCOIS.preventerVars.gCheckEquipmentSlots  = false
FCOIS.preventerVars.gUpdateMarkersNow		= false
FCOIS.preventerVars.gChangedGears			= false
FCOIS.preventerVars.gContextCreated		= {}
FCOIS.preventerVars.gLockDynFilterContextCreated = {}
FCOIS.preventerVars.gGearSetFilterContextCreated = {}
FCOIS.preventerVars.gResDecImpFilterContextCreated = {}
FCOIS.preventerVars.gSellGuildIntFilterContextCreated = {}
FCOIS.preventerVars.askBeforeEquipDialogRetVal = false
FCOIS.preventerVars.gOverrideInvUpdateAfterMarkItem = false
FCOIS.preventerVars.doFalseOverride = false
FCOIS.preventerVars.newItemCrafted = false
--FCOIS.preventerVars.ZOsPlayerItemLockEnabled = true -- implemented with API 1000015 by ZOs: Lock items in inventory. Items will get dataEntry "isPlayerLocked = true"
FCOIS.preventerVars.isControlCheckActive = {}
FCOIS.preventerVars.controlCheckActiveCounter = {}
FCOIS.preventerVars.buildingSlotActionTexts = false
FCOIS.preventerVars.dontShowInvContextMenu = false
FCOIS.preventerVars.markItemAntiEndlessLoop = false
FCOIS.preventerVars.dontAutoReenableAntiSettingsInInventory = false
FCOIS.preventerVars.dragAndDropOrDoubleClickItemSelectionHandler = false
FCOIS.preventerVars.noGamePadModeSupportTextOutput = false
FCOIS.preventerVars.contextMenuUpdateLoopLastLoop = false
FCOIS.preventerVars.doNotScanInv = false
FCOIS.preventerVars.migrateItemMarkers = false
FCOIS.preventerVars.gAddonStartupInProgress = false
FCOIS.preventerVars.lastHoveredInvSlot = nil
FCOIS.preventerVars.createdMasterWrit= false
FCOIS.preventerVars.writCreatorCreatedItem = false
FCOIS.preventerVars.eventInventorySingleSlotUpdate = false
FCOIS.preventerVars.resetNonServerDependentSavedVars = false
FCOIS.preventerVars.preHookButtonDone = {}
FCOIS.preventerVars.gPreHookButtonHandlerCallActive = false
FCOIS.preventerVars.craftBagSceneShowInProgress = false
FCOIS.preventerVars.markerIconChangedManually = false
FCOIS.preventerVars.isInventoryListUpdating = false
FCOIS.preventerVars.gRestoringMarkerIcons = false
FCOIS.preventerVars.gClearingMarkerIcons = false
FCOIS.preventerVars.gMarkItemLastIconInLoop = false
FCOIS.preventerVars.repairDialogOnRepairKitSelectedOverwrite = false
FCOIS.preventerVars.ZO_ListDialog1ResearchIsOpen = false
FCOIS.preventerVars.splitItemStackDialogActive = false
FCOIS.preventerVars.splitItemStackDialogButtonCallbacks = false
FCOIS.preventerVars.useAdvancedFiltersItemCountInInventories = false
FCOIS.preventerVars.dontUpdateFilteredItemCount = false

--The event handler array for OnMouseDoubleClick, Drag&Drop, etc.
FCOIS.eventHandlers = {}

--Table to map the FCOIS.settingsVars.settings filter state to the output text identifier
FCOIS.mappingVars.settingsFilterStateToText = {
	["true"]  = "on",
    ["false"] = "off",
    ["-99"]   = "onlyfiltered",
}

--Table to map iconId to relating filterId
FCOIS.mappingVars.iconToFilterDefaults = {
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
}
FCOIS.mappingVars.iconToFilter = {}

--Table to map filterId to relating iconId
--As filters can have several icons only the main iconId of this filterId is maintained here
FCOIS.mappingVars.filterToIcon = {
    [1]	= FCOIS_CON_ICON_LOCK,
    [2]	= FCOIS_CON_ICON_GEAR_1,
    [3]	= FCOIS_CON_ICON_RESEARCH,
    [4]	= FCOIS_CON_ICON_SELL,
}

--The static gear icons
FCOIS.mappingVars.isStaticGearIcon = {
    [FCOIS_CON_ICON_GEAR_1] = true,
    [FCOIS_CON_ICON_GEAR_2] = true,
    [FCOIS_CON_ICON_GEAR_3] = true,
    [FCOIS_CON_ICON_GEAR_4] = true,
    [FCOIS_CON_ICON_GEAR_5] = true,
}

--Table to map iconId to gearId
FCOIS.mappingVars.iconToGear = {
    [FCOIS_CON_ICON_GEAR_1] = 1,
    [FCOIS_CON_ICON_GEAR_2] = 2,
    [FCOIS_CON_ICON_GEAR_3] = 3,
    [FCOIS_CON_ICON_GEAR_4] = 4,
    [FCOIS_CON_ICON_GEAR_5] = 5,
}

--Table to map gearId to iconId
FCOIS.mappingVars.gearToIcon = {
    [1] = FCOIS_CON_ICON_GEAR_1,
    [2] = FCOIS_CON_ICON_GEAR_2,
    [3] = FCOIS_CON_ICON_GEAR_3,
    [4] = FCOIS_CON_ICON_GEAR_4,
    [5] = FCOIS_CON_ICON_GEAR_5,
}

--Table to see if the icon is researchable
FCOIS.mappingVars.iconIsResearchable = {
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
FCOIS.mappingVars.iconIsDynamic = {
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
	[FCOIS_CON_ICON_DYNAMIC_1]			= true,
	[FCOIS_CON_ICON_DYNAMIC_2]			= true,
	[FCOIS_CON_ICON_DYNAMIC_3]			= true,
	[FCOIS_CON_ICON_DYNAMIC_4]			= true,
	[FCOIS_CON_ICON_DYNAMIC_5]			= true,
	[FCOIS_CON_ICON_DYNAMIC_6]			= true,
	[FCOIS_CON_ICON_DYNAMIC_7]			= true,
	[FCOIS_CON_ICON_DYNAMIC_8]			= true,
	[FCOIS_CON_ICON_DYNAMIC_9]			= true,
	[FCOIS_CON_ICON_DYNAMIC_10]			= true,
    [FCOIS_CON_ICON_DYNAMIC_11]        = true,
    [FCOIS_CON_ICON_DYNAMIC_12]        = true,
    [FCOIS_CON_ICON_DYNAMIC_13]        = true,
    [FCOIS_CON_ICON_DYNAMIC_14]        = true,
    [FCOIS_CON_ICON_DYNAMIC_15]        = true,
    [FCOIS_CON_ICON_DYNAMIC_16]        = true,
    [FCOIS_CON_ICON_DYNAMIC_17]        = true,
    [FCOIS_CON_ICON_DYNAMIC_18]        = true,
    [FCOIS_CON_ICON_DYNAMIC_19]        = true,
    [FCOIS_CON_ICON_DYNAMIC_20]        = true,
    [FCOIS_CON_ICON_DYNAMIC_21]        = true,
    [FCOIS_CON_ICON_DYNAMIC_22]        = true,
    [FCOIS_CON_ICON_DYNAMIC_23]        = true,
    [FCOIS_CON_ICON_DYNAMIC_24]        = true,
    [FCOIS_CON_ICON_DYNAMIC_25]        = true,
    [FCOIS_CON_ICON_DYNAMIC_26]        = true,
    [FCOIS_CON_ICON_DYNAMIC_27]        = true,
    [FCOIS_CON_ICON_DYNAMIC_28]        = true,
    [FCOIS_CON_ICON_DYNAMIC_29]        = true,
    [FCOIS_CON_ICON_DYNAMIC_30]        = true,
}

--Table to map dynamicId to iconId
FCOIS.mappingVars.dynamicToIcon = {
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
}

--Table to map iconId to dynamicId
FCOIS.mappingVars.iconToDynamic = {
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
}

--Mapping array for icon to lock & dynamic icons filter split
FCOIS.mappingVars.iconToLockDyn = {
    [FCOIS_CON_ICON_LOCK	 ]  = 1,
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
}
--Mapping array for lock & dynamic icons filter split to it's icon
FCOIS.mappingVars.lockDynToIcon = {
	[1]  =  FCOIS_CON_ICON_LOCK,
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
}

--Mapping array for icon to research/deconstruction/improvement filter split
FCOIS.mappingVars.iconToResDecImp = {
	[FCOIS_CON_ICON_RESEARCH]  		= 1,
	[FCOIS_CON_ICON_DECONSTRUCTION] = 2,
	[FCOIS_CON_ICON_IMPROVEMENT] 	= 3,
}

--Mapping array for research/deconstruction/improvement filter split to it's icon
FCOIS.mappingVars.resDecImpToIcon = {
	[1]  = FCOIS_CON_ICON_RESEARCH,
	[2]  = FCOIS_CON_ICON_DECONSTRUCTION,
	[3]  = FCOIS_CON_ICON_IMPROVEMENT,
}

--Mapping array for icon to sell/sell in guild store/intricate filter split
FCOIS.mappingVars.iconToSellGuildInt = {
    [FCOIS_CON_ICON_SELL]  				= 1,
    [FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = 2,
    [FCOIS_CON_ICON_INTRICATE] 			= 3,
}

--Mapping array for sell/sell in guild store/intricate filter split to it's icon
FCOIS.mappingVars.sellGuildIntToIcon = {
    [1] = FCOIS_CON_ICON_SELL,
    [2] = FCOIS_CON_ICON_SELL_AT_GUILDSTORE,
    [3] = FCOIS_CON_ICON_INTRICATE,
}

--Table with the weapon types for the main&offhand checks
FCOIS.checkVars.weaponTypeCheckTable = {
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
FCOIS.checkVars.allowedOrnateItemTraits = {
	[ITEM_TRAIT_TYPE_ARMOR_ORNATE]   = true,
	[ITEM_TRAIT_TYPE_JEWELRY_ORNATE] = true,
	[ITEM_TRAIT_TYPE_WEAPON_ORNATE]  = true,
}
--Table with allowed item traits for intricate items
FCOIS.checkVars.allowedIntricateItemTraits = {
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE]   = true,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE]  = true,
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = true,
}
--Table with allowed item types for researching
FCOIS.checkVars.allowedResearchableItemTypes = {
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
FCOIS.checkVars.allowedSetItemTypes = {
	[ITEMTYPE_ARMOR]	= true,
	[ITEMTYPE_WEAPON]	= true,
}

--Table with NOT allowed parent control names. These cannot use the FCOItemSaver right click context menu entries
--for items (in the inventories)
FCOIS.checkVars.notAllowedContextMenuParentControls = {
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
    [FCOIS.ZOControlVars.CONTAINER_LOOT_LIST_CONTENTS:GetName()] = true,
    [FCOIS.ZOControlVars.RETRAIT_PANEL:GetName()] = true,

}
--Table with NOT allowed control names. These cannot use the FCOItemSaver right click context menu entries
--for items (in the inventories)
FCOIS.checkVars.notAllowedContextMenuControls = {
	["ZO_SmithingTopLevelRefinementPanelSlotContainer"] = true,
	["ZO_SmithingTopLevelDeconstructionPanelSlotContainer"] = true,
	[FCOIS.ZOControlVars.ALCHEMY_SLOT_CONTAINER:GetName()] = true,
	[FCOIS.ZOControlVars.ENCHANTING_RUNE_CONTAINER:GetName()] = true,
    [FCOIS.ZOControlVars.ENCHANTING_EXTRACTION_SLOT:GetName()] = true,
	["ZO_ApplyEnchantPanel"] = true,
	["ZO_SoulGemItemChargerPanel"] = true,
    ["ZO_SoulGemItemChargerPanelImprovementPreviewContainer"] = true,
    [FCOIS.ZOControlVars.GUILD_STORE_SELL_SLOT:GetName()] = true,
}
--Table with allowed libFilters panelIds (LF_*) for the additional inventory "flag" context menu's "JUNK" entry
--> See file src/FCOIS_ContextMenu.lua, function FCOIS.showContextMenuForAddInvButtons(invAddContextMenuInvokerButton)
FCOIS.checkVars.allowedJunkFlagContextMenuFilterPanelIds = {
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
FCOIS.checkVars.allowedCraftingPanelIdsForMarkerRechecks = {
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
--Table with allowed control names for the character equipment weapon and offhand weapon slots
FCOIS.checkVars.allowedCharacterEquipmentWeaponControlNames = {
	['ZO_CharacterEquipmentSlotsMainHand'] = true,
	['ZO_CharacterEquipmentSlotsOffHand'] = true,
	['ZO_CharacterEquipmentSlotsBackupMain'] = true,
	['ZO_CharacterEquipmentSlotsBackupOff'] = true,
   }
--Table with weapon backup slot names
FCOIS.checkVars.allowedCharacterEquipmentWeaponBackupControlNames = {
	['ZO_CharacterEquipmentSlotsOffHand'] = true,
	['ZO_CharacterEquipmentSlotsBackupOff'] = true,
   }
--Table with allowed control names for the character equipment jewelry rings
FCOIS.checkVars.allowedCharacterEquipmentJewelryRingControlNames = {
    ['ZO_CharacterEquipmentSlotsRing1'] = true,
    ['ZO_CharacterEquipmentSlotsRing2'] = true,
}
--Table with allowed control names for the character equipment jewelry
FCOIS.checkVars.allowedCharacterEquipmentJewelryControlNames = {
	['ZO_CharacterEquipmentSlotsNeck'] = true,
	['ZO_CharacterEquipmentSlotsRing1'] = true,
	['ZO_CharacterEquipmentSlotsRing2'] = true,
}
--Table with weapon and jewelry slot names for equipment checks
FCOIS.checkVars.equipmentSlotsNames = {
    ["no_auto_mark"] = {
		["ZO_CharacterEquipmentSlotsCostume"] = true,
    }
}

--The check table to check on which inventory filterTypes the junk entries in the additional inventory "flag"
--context menus should not be added!
FCOIS.checkVars.doNotShowJunkAdditionalContextMenuEntryFilterTypes = {
    [ITEMFILTERTYPE_QUICKSLOT]  = true,
    [ITEMFILTERTYPE_QUEST]      = true,
}

--The markerIcons which should do a trait check on the items if they will be checked for research
FCOIS.checkVars.researchTraitCheck = {
    [FCOIS_CON_ICON_RESEARCH] = true,
}
--The item traits which are not allowed for research
FCOIS.checkVars.researchTraitCheckTraitsNotAllowed = {
    [ITEM_TRAIT_TYPE_NONE]              = true,
    [ITEM_TRAIT_TYPE_ARMOR_ORNATE]      = true,
    [ITEM_TRAIT_TYPE_JEWELRY_ORNATE]    = true,
    [ITEM_TRAIT_TYPE_WEAPON_ORNATE]     = true,
}
--The possible checkWere panels for the antiSettings reenable checks
--See file src/FCOIS_Settings.lua, function FCOIS.autoReenableAntiSettingsCheck(checkWhere)
FCOIS.checkVars.autoReenableAntiSettingsCheckWheres = {
    [1] = "CRAFTING_STATION",
    [2] = "STORE",
    [3]	= "GUILD_STORE",
    [4] = "DESTROY",
    [5] = "TRADE",
    [6] = "MAIL",
    [7] = "RETRAIT",
}
--The entry for "all" the antisettings reenable panel checks above
FCOIS.checkVars.autoReenableAntiSettingsCheckWheresAll = "-ALL-"
--The filter panelÍds which need to be checked if anti-destroy is checked
FCOIS.checkVars.filterPanelIdsForAntiDestroy = {
    [LF_INVENTORY]          = true,
    [LF_BANK_WITHDRAW]      = true,
    [LF_GUILDBANK_WITHDRAW] = true,
    [LF_HOUSE_BANK_WITHDRAW]= true,
    [LF_BANK_DEPOSIT]       = true,
    [LF_GUILDBANK_DEPOSIT]  = true,
    [LF_HOUSE_BANK_DEPOSIT] = true,
}
--Table with all equipment slot names which can be updated with markes for the icons
--The index is the relating slotIndex of the bag BAG_WORN!
FCOIS.mappingVars.characterEquipmentSlotNameByIndex = {
	[0] = "ZO_CharacterEquipmentSlotsHead",
	[1] = "ZO_CharacterEquipmentSlotsNeck",
	[2] = "ZO_CharacterEquipmentSlotsChest",
	[3] = "ZO_CharacterEquipmentSlotsShoulder",
	[4] = "ZO_CharacterEquipmentSlotsMainHand",
	[5] = "ZO_CharacterEquipmentSlotsOffHand",
	[6] = "ZO_CharacterEquipmentSlotsBelt",
	[8] = "ZO_CharacterEquipmentSlotsLeg",
	[9] = "ZO_CharacterEquipmentSlotsFoot",
	[10] = "ZO_CharacterEquipmentSlotsCostume",
	[11] = "ZO_CharacterEquipmentSlotsRing1",
	[12] = "ZO_CharacterEquipmentSlotsRing2",
    [13] = "ZO_CharacterEquipmentSlotsPoison",
	[14] = "ZO_CharacterEquipmentSlotsBackupPoison",
	[16] = "ZO_CharacterEquipmentSlotsGlove",
	[20] = "ZO_CharacterEquipmentSlotsBackupMain",
	[21] = "ZO_CharacterEquipmentSlotsBackupOff",
}
--Table with the eqipment slot control names which are armor
FCOIS.mappingVars.characterEquipmentArmorSlots = {
	['ZO_CharacterEquipmentSlotsHead'] = true,
	['ZO_CharacterEquipmentSlotsChest'] = true,
	['ZO_CharacterEquipmentSlotsShoulder'] = true,
	['ZO_CharacterEquipmentSlotsBelt'] = true,
	['ZO_CharacterEquipmentSlotsLeg'] = true,
	['ZO_CharacterEquipmentSlotsFoot'] = true,
	['ZO_CharacterEquipmentSlotsGlove'] = true,
}

--Table with the eqipment slot control names which are jewelry
FCOIS.mappingVars.characterEquipmentJewelrySlots = {
	['ZO_CharacterEquipmentSlotsNeck'] = true,
	['ZO_CharacterEquipmentSlotsRing1'] = true,
	['ZO_CharacterEquipmentSlotsRing2'] = true,
}

--Table with the eqipment slot control names which are weapons
FCOIS.mappingVars.characterEquipmentWeaponSlots = {
	['ZO_CharacterEquipmentSlotsMainHand'] = true,
	['ZO_CharacterEquipmentSlotsOffHand'] = true,
	['ZO_CharacterEquipmentSlotsPoison'] = true,
	['ZO_CharacterEquipmentSlotsBackupMain'] = true,
	['ZO_CharacterEquipmentSlotsBackupOff'] = true,
	['ZO_CharacterEquipmentSlotsBackupPoiosn'] = true,
}

--Mapping table fo one ring to the other
FCOIS.mappingVars.equipmentJewelryRing2RingSlot = {
    ['ZO_CharacterEquipmentSlotsRing1'] = 'ZO_CharacterEquipmentSlotsRing2',
    ['ZO_CharacterEquipmentSlotsRing2'] = 'ZO_CharacterEquipmentSlotsRing1',
}

--BagId to SetTracker addon settings in FCOIS
FCOIS.mappingVars.bagToSetTrackerSettings = {
	--[[ Will be filled as the settings got loaded
		--> See function updateSettingsBeforeAddonMenu
    ]]
}

--The traits of armor, jewelry or weapon
FCOIS.mappingVars.traits = {}
--Armor
FCOIS.mappingVars.traits.armorTraits = {
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
FCOIS.mappingVars.traits.jewelryTraits = {
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
FCOIS.mappingVars.traits.weaponTraits = {
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
FCOIS.mappingVars.traits.weaponShieldTraits = {
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
FCOIS.contextMenuVars.buttonContextMenuToIconId = {}
--The index of the mapping table for context menu buttons to icon id
FCOIS.contextMenuVars.buttonContextMenuToIconIdIndex = {}
--The table for the context menu marker icons in the additional inventory "flag" context menu, but only non-dynamic icons
FCOIS.contextMenuVars.buttonContextMenuNonDynamicIcons = {
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
FCOIS.contextMenuVars.maxWidth			= 275
FCOIS.contextMenuVars.maxHeight			= 880 -- old 880 before dynamic icons 11 to 30 were added, more old 721 before 6 new dynamic icons 5 to 10 were added, even more older 561 before the first 4 dynamic icons were added
FCOIS.contextMenuVars.entryHeight		= 20
FCOIS.contextMenuVars.maxCharactersInLine = 32
--Context menu variables for filter buttons
FCOIS.contextMenuVars.filterButtons = {}
FCOIS.contextMenuVars.filterButtons.maxWidth = 24
FCOIS.contextMenuVars.filterButtons.entryHeight = 24

--The table with the undo entries for last changes by context menu
FCOIS.contextMenuVars.undoMarkedItems = {}
--The name prefix of the context menu inventory buttons
FCOIS.contextMenuVars.buttonNamePrefix = "ButtonContextMenu"
local buttonNamePrefix = FCOIS.contextMenuVars.buttonNamePrefix

--The available contextmenus at the filter buttons
FCOIS.contextMenuVars.availableCtms = {
    [FCOIS_CON_FILTER_BUTTON_LOCKDYN]       = "LockDyn",
    [FCOIS_CON_FILTER_BUTTON_GEARSETS]      = "Gear",
    [FCOIS_CON_FILTER_BUTTON_RESDECIMP]     = "ResDecImp",
    [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]  = "SellGuildInt",
}

--The self-build contextMenus (filter buttons)
FCOIS.contextMenu = {}
--The context menu for the lock & dynmic icons filter button
FCOIS.contextMenu.LockDynFilter 	= {}
FCOIS.contextMenu.LockDynFilterName = FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN] .. "Filter"
FCOIS.contextMenu.ContextMenuLockDynFilterName = "ContextMenu" .. FCOIS.contextMenu.LockDynFilterName
FCOIS.contextMenu.LockDynFilter.bdSelectedLine = {}
--Lock & dynamic icons filter split context menu variables
FCOIS.contextMenuVars.LockDynFilter	= {}
FCOIS.contextMenuVars.LockDynFilter.maxWidth		= FCOIS.contextMenuVars.filterButtons.maxWidth
FCOIS.contextMenuVars.LockDynFilter.maxHeight		= 288 -- OLD: 288 before additional 20 dynamic icons were added
FCOIS.contextMenuVars.LockDynFilter.entryHeight	    = FCOIS.contextMenuVars.filterButtons.entryHeight
--The prefix of the LockDynFilter entries
FCOIS.contextMenuVars.LockDynFilter.buttonNamePrefix = FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN] .. "Filter"
--The entries in the following mapping array
FCOIS.contextMenuVars.LockDynFilter.buttonContextMenuToIconIdEntries = 32 -- OLD: 12 before additional 20 dynamic icons were added
--The index of the mapping table for context menu buttons to icon id
FCOIS.contextMenuVars.LockDynFilter.buttonContextMenuToIconIdIndex = {}
for index=1, FCOIS.contextMenuVars.LockDynFilter.buttonContextMenuToIconIdEntries do
	table.insert(FCOIS.contextMenuVars.LockDynFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. FCOIS.contextMenuVars.LockDynFilter.buttonNamePrefix .. index)
end

--The context menu for the gear sets filter button
FCOIS.contextMenu.GearSetFilter 	= {}
FCOIS.contextMenu.GearSetFilterName = FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS] .. "Filter"
FCOIS.contextMenu.ContextMenuGearSetFilterName = "ContextMenu" .. FCOIS.contextMenu.GearSetFilterName
FCOIS.contextMenu.GearSetFilter.bdSelectedLine = {}
--Gear set filter split context menu variables
FCOIS.contextMenuVars.GearSetFilter	= {}
FCOIS.contextMenuVars.GearSetFilter.maxWidth		= FCOIS.contextMenuVars.filterButtons.maxWidth
FCOIS.contextMenuVars.GearSetFilter.maxHeight		= 144
FCOIS.contextMenuVars.GearSetFilter.entryHeight	    = FCOIS.contextMenuVars.filterButtons.entryHeight
--The prefix of the GearSetFilter entries
FCOIS.contextMenuVars.GearSetFilter.buttonNamePrefix = FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS] .. "Filter"
--The entries in the following mapping array
FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries = 6
--The index of the mapping table for context menu buttons to icon id
FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex = {}
for index=1, FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries do
	table.insert(FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. FCOIS.contextMenuVars.GearSetFilter.buttonNamePrefix .. index)
end

--The context menu for the RESEARCH & DECONSTRUCTION & IMPORVEMENT filter button
FCOIS.contextMenu.ResDecImpFilter 	= {}
FCOIS.contextMenu.ResDecImpFilterName =  FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP] .. "Filter"
FCOIS.contextMenu.ContextMenuResDecImpFilterName = "ContextMenu" .. FCOIS.contextMenu.ResDecImpFilterName
FCOIS.contextMenu.ResDecImpFilter.bdSelectedLine = {}
--Research/Deconstruction filter split context menu variables
FCOIS.contextMenuVars.ResDecImpFilter	= {}
FCOIS.contextMenuVars.ResDecImpFilter.maxWidth      = FCOIS.contextMenuVars.filterButtons.maxWidth
FCOIS.contextMenuVars.ResDecImpFilter.maxHeight	    = 96
FCOIS.contextMenuVars.ResDecImpFilter.entryHeight	= FCOIS.contextMenuVars.filterButtons.entryHeight
--The prefix of the ResDecImpFilter entries
FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix = FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP] .. "Filter"
--The entries in the following mapping array
FCOIS.contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdEntries = 4
--The index of the mapping table for context menu buttons to icon id
FCOIS.contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdIndex = {}
for index=1, FCOIS.contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdEntries do
	table.insert(FCOIS.contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. index)
end

--The context menu for the SELL & SELL IN GUILD STORE & INTRICATE  filter button
FCOIS.contextMenu.SellGuildIntFilter 	= {}
FCOIS.contextMenu.SellGuildIntFilterName = FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] .. "Filter"
FCOIS.contextMenu.ContextMenuSellGuildIntFilterName = "ContextMenu" .. FCOIS.contextMenu.SellGuildIntFilterName
FCOIS.contextMenu.SellGuildIntFilter.bdSelectedLine = {}
--Sell/Guild sell/Intricate filter split context menu variables
FCOIS.contextMenuVars.SellGuildIntFilter	= {}
FCOIS.contextMenuVars.SellGuildIntFilter.maxWidth       = FCOIS.contextMenuVars.filterButtons.maxWidth
FCOIS.contextMenuVars.SellGuildIntFilter.maxHeight      = 96
FCOIS.contextMenuVars.SellGuildIntFilter.entryHeight    = FCOIS.contextMenuVars.filterButtons.entryHeight
--The prefix of the SellGuildIntFilter entries
FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix = FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] .. "Filter"
--The entries in the following mapping array
FCOIS.contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdEntries = 4
--The index of the mapping table for context menu buttons to icon id
FCOIS.contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdIndex = {}
for index=1, FCOIS.contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdEntries do
	table.insert(FCOIS.contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. index)
end

--Mapping array fo the filter button context menu types and their settings
FCOIS.mappingVars.contextMenuFilterButtonTypeToSettings = {}

--Mapping for the context menu type to it's filter button
FCOIS.mappingVars.contextMenuButtonClickedMenuToButton = {
	[FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]] 		= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]]		= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]] 	= FCOIS_CON_FILTER_BUTTON_RESDECIMP,
	[FCOIS.contextMenuVars.availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]]	= FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
}

--The textures for the button context menu, selected item
FCOIS.contextMenuVars.menuInfo =
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
for i=1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
	if FCOIS.mappingVars.activeFilterPanelIds[i] == true then
		--Additional inventory "flag" button context menus
		FCOIS.preventerVars.gContextCreated[i] 				        = false
		--Inventory filter buttons context menus
        --Lock & dynamic filter button context menus
        FCOIS.preventerVars.gLockDynFilterContextCreated[i]	        = false
	    FCOIS.contextMenu.LockDynFilter[i]	  	 			        = nil
	    FCOIS.contextMenu.LockDynFilter.bdSelectedLine[i]		    = nil
		--Gear sets filter button context menus
        FCOIS.preventerVars.gGearSetFilterContextCreated[i]	        = false
	    FCOIS.contextMenu.GearSetFilter[i]	  	 			        = nil
	    FCOIS.contextMenu.GearSetFilter.bdSelectedLine[i]		    = nil
		--Research, Deconstruction, Improvement filter button context menus
        FCOIS.contextMenu.ResDecImpFilter[i]	  	 			    = nil
	    FCOIS.contextMenu.ResDecImpFilter.bdSelectedLine[i]	        = nil
		FCOIS.preventerVars.gResDecImpFilterContextCreated[i]	    = false
        --Sell/Sell in guild store/intricate filter button context menus
        FCOIS.contextMenu.SellGuildIntFilter[i]	  	 			    = nil
        FCOIS.contextMenu.SellGuildIntFilter.bdSelectedLine[i]	    = nil
        FCOIS.preventerVars.gSellGuildIntFilterContextCreated[i]	= false
		--Initialize the variable for the last choosen filter button
        FCOIS.lastVars.gLastFilterId[i]                             = LF_INVENTORY
    end
end

--The mapping table for the additional inventory context menu invoker buttons, their name, their parent and their settings
local additionalFCOISInvContextmenuButtonNameString = "ButtonFCOISAdditionalOptions"
FCOIS.invAdditionalButtonVars.playerInventoryFCOAdditionalOptionsButton = "ZO_PlayerInventory" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.playerBankWithdrawButtonAdditionalOptions = "ZO_PlayerBankWithdraw" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.guildBankFCOWithdrawButtonAdditionalOptions = "ZO_GuildBankWithdraw" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions = "ZO_SmithingTopLevelRefinementPanelInventory" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions = "ZO_SmithingTopLevelDeconstructionPanelInventory" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions = "ZO_SmithingTopLevelImprovementPanelInventory" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.enchantingTopLevelInventoryButtonAdditionalOptions = "ZO_EnchantingTopLevelInventory" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.craftBagInventoryButtonAdditionalOptions = "ZO_CraftBag" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.retraitInventoryButtonAdditionalOptions = "ZO_RetraitStation_Keyboard" .. additionalFCOISInvContextmenuButtonNameString
FCOIS.invAdditionalButtonVars.houseBankInventoryButtonAdditionalOptions = "ZO_HouseBank" .. additionalFCOISInvContextmenuButtonNameString
local invAddButtonVars = FCOIS.invAdditionalButtonVars
--The mapping between the panel (libFilters filter ID LF_*) and the button data -> See file FCOIS_settings.lua -> function AfterSettings() for additional added data
--and file FCOIS_constants.lua at the bottom for the anchorvars for each API version.
--Entries without a parent and without "addInvButton" boolean == true will not be added again as another panel (like LF_INVENTORY) is reused for the button.
--The entry is only there to get the button's name for the functions in file "FCOIS_ContextMenus.lua" to show/hide it.
--> To check what entries the context menu below this invokerButton will create/show check the file src/FCOIS_ContextMenus.lua, function FCOIS.showContextMenuForAddInvButtons(invokerButton)
FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker = {
	[LF_INVENTORY] 					= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_PlayerInventorySortBy,
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton
    },
	[LF_BANK_WITHDRAW] 				= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_PlayerBankSortBy,
        ["name"]          = invAddButtonVars.playerBankWithdrawButtonAdditionalOptions
    },
	[LF_BANK_DEPOSIT] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
	[LF_GUILDBANK_WITHDRAW] 		= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_GuildBankSortBy,
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
        ["parent"]        = ZO_SmithingTopLevelRefinementPanelInventorySortBy,
        ["name"]          = invAddButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions
    },
    [LF_SMITHING_DECONSTRUCT]  		= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_SmithingTopLevelDeconstructionPanelInventorySortBy,
        ["name"]          = invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions
    },
    [LF_SMITHING_IMPROVEMENT]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_SmithingTopLevelImprovementPanelInventorySortBy,
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
        ["parent"]        = ZO_EnchantingTopLevelInventorySortBy,
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
        ["parent"]        = ZO_CraftBagSortBy,
        ["name"]          = invAddButtonVars.craftBagInventoryButtonAdditionalOptions
    },
    --Added with API 100021 Clockwork city: Retrait of items
    [LF_RETRAIT]                    = {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventorySortBy,
        ["name"]          = invAddButtonVars.retraitInventoryButtonAdditionalOptions
    },
    --Added with API 100022 Dragon bones: House storage, named House bank
    [LF_HOUSE_BANK_WITHDRAW]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_HouseBankSortBy,
        ["name"]          = invAddButtonVars.houseBankInventoryButtonAdditionalOptions
    },
    [LF_HOUSE_BANK_DEPOSIT]			= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton                      --Same like inventory
    },
    --Added with API 100023 Summerset: SMITHING for jewelry
    [LF_JEWELRY_REFINE]		   	= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_SmithingTopLevelRefinementPanelInventorySortBy,
        ["name"]          = invAddButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions
    },
    [LF_JEWELRY_DECONSTRUCT]  		= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_SmithingTopLevelDeconstructionPanelInventorySortBy,
        ["name"]          = invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions
    },
    [LF_JEWELRY_IMPROVEMENT]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ZO_SmithingTopLevelImprovementPanelInventorySortBy,
        ["name"]          = invAddButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions
    },

}

--Constants for the filter item number sort header entries "name" at the filter panels
FCOIS.sortHeaderVars = {}
local sortByNameNameStr = "SortByNameName"
local sortHeaderNames = {
    [LF_INVENTORY]              = "ZO_PlayerInventory" .. sortByNameNameStr,
    [LF_VENDOR_BUY]             = "ZO_StoreWindow" .. sortByNameNameStr,
    [LF_VENDOR_BUYBACK]         = "ZO_BuyBack" .. sortByNameNameStr,
    [LF_VENDOR_REPAIR]          = "ZO_RepairWindow" .. sortByNameNameStr,
    [LF_BANK_WITHDRAW]          = "ZO_PlayerBank" .. sortByNameNameStr,
    [LF_GUILDBANK_WITHDRAW]     = "ZO_GuildBank" .. sortByNameNameStr,
    [LF_SMITHING_REFINE]        = "ZO_SmithingTopLevelRefinementPanelInventory" .. sortByNameNameStr,
    [LF_SMITHING_DECONSTRUCT]   = "ZO_SmithingTopLevelDeconstructionPanelInventory" .. sortByNameNameStr,
    [LF_SMITHING_IMPROVEMENT]   = "ZO_SmithingTopLevelImprovementPanelInventory" .. sortByNameNameStr,
    [LF_ALCHEMY_CREATION]       = "ZO_AlchemyTopLevelInventory" .. sortByNameNameStr,
    [LF_ENCHANTING_CREATION]    = "ZO_EnchantingTopLevelInventory" .. sortByNameNameStr,
    [LF_CRAFTBAG]               = "ZO_CraftBag" .. sortByNameNameStr,
    [LF_RETRAIT]                = "ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventory" .. sortByNameNameStr,
    [LF_HOUSE_BANK_WITHDRAW]	= "ZO_HouseBank" .. sortByNameNameStr,
    [LF_QUICKSLOT]              = "ZO_QuickSlot" .. sortByNameNameStr,
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
FCOIS.mappingVars.levels = {
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
FCOIS.mappingVars.maxCPLevel = GetChampionPointsPlayerProgressionCap() -- The current maxmium of Champion ranks
FCOIS.mappingVars.CPlevels = {}
local cpCnt = 1
for cpRank = 10, FCOIS.mappingVars.maxCPLevel, 10 do
    FCOIS.mappingVars.CPlevels[cpCnt] = cpRank
    cpCnt = cpCnt + 1
end
--Build the level 2 threshold mapping array for the settingsmenu dropdownbox value -> comparison with item's level
FCOIS.mappingVars.levelToThreshold = {}
if FCOIS.mappingVars.levels ~= nil then
    for _, level in ipairs(FCOIS.mappingVars.levels) do
        if level > 0 then
            FCOIS.mappingVars.levelToThreshold[tostring(level)] = level
        end
    end
end
--Afterwards add the CP ranks
if FCOIS.mappingVars.CPlevels ~= nil then
    for _, CPRank in ipairs(FCOIS.mappingVars.CPlevels) do
        if CPRank > 0 then
            FCOIS.mappingVars.levelToThreshold[tostring("CP") .. CPRank] = CPRank
        end
    end
end
--Global "all levels" table. Will be filled in file "FCOIS_SettingsMenu.lua" in function "FCOIS.BuildAddonMenu()"
--as the levelList array is build for the LAM dropdown box (for the automatic marking -> non-wished -> levels)
FCOIS.mappingVars.allLevels = {}

--The additional inventory flag context menu anti-* settings buttons
local buttonContextMenuDestroy  = "button_context_menu_toggle_anti_destroy_"
local buttonContextMenuSell     = "button_context_menu_toggle_anti_sell_"
local buttonContextMenuRefine   = "button_context_menu_toggle_anti_refine_"
local buttonContextMenuDecon    = "button_context_menu_toggle_anti_deconstruct_"
local buttonContextMenuImprove  = "button_context_menu_toggle_anti_improve_"
FCOIS.mappingVars.contextMenuAntiButtonsAtPanel = {
    [LF_INVENTORY] 				= buttonContextMenuDestroy,
    [LF_BANK_WITHDRAW] 			= buttonContextMenuDestroy,
    [LF_BANK_DEPOSIT] 			= buttonContextMenuDestroy,
    [LF_GUILDBANK_WITHDRAW] 	= buttonContextMenuDestroy,
    [LF_GUILDBANK_DEPOSIT]		= buttonContextMenuDestroy,
    [LF_VENDOR_BUY] 			= "button_context_menu_toggle_anti_buy_",
    [LF_VENDOR_SELL] 			= buttonContextMenuSell,
    [LF_VENDOR_BUYBACK] 		= "button_context_menu_toggle_anti_buyback_",
    [LF_VENDOR_REPAIR] 			= "button_context_menu_toggle_anti_repair_",
    [LF_SMITHING_REFINE]  		= buttonContextMenuRefine,
    [LF_SMITHING_DECONSTRUCT]  	= buttonContextMenuDecon,
    [LF_SMITHING_IMPROVEMENT]	= buttonContextMenuImprove,
    [LF_SMITHING_RESEARCH]		= "",
    [LF_SMITHING_RESEARCH_DIALOG] = "",
    [LF_GUILDSTORE_SELL] 	 	= buttonContextMenuSell,
    [LF_MAIL_SEND] 				= "button_context_menu_toggle_anti_mail_",
    [LF_TRADE] 					= "button_context_menu_toggle_anti_trade_",
    [LF_ENCHANTING_CREATION]	= "button_context_menu_toggle_anti_create_",
    [LF_ENCHANTING_EXTRACTION]	= "button_context_menu_toggle_anti_extract_",
    [LF_FENCE_SELL] 			= "button_context_menu_toggle_anti_fence_sell_",
    [LF_FENCE_LAUNDER] 			= "button_context_menu_toggle_anti_launder_sell_",
    [LF_CRAFTBAG]				= buttonContextMenuDestroy,
    [LF_RETRAIT]				= "button_context_menu_toggle_anti_retrait_",
    [LF_HOUSE_BANK_WITHDRAW]    = buttonContextMenuDestroy,
    [LF_HOUSE_BANK_DEPOSIT] 	= buttonContextMenuDestroy,
    [LF_JEWELRY_REFINE]  		= buttonContextMenuRefine,
    [LF_JEWELRY_DECONSTRUCT]  	= buttonContextMenuDecon,
    [LF_JEWELRY_IMPROVEMENT]	= buttonContextMenuImprove,
    [LF_JEWELRY_RESEARCH]		= "",
    [LF_JEWELRY_RESEARCH_DIALOG] = "",
}

--Mapping for the Transmuation Geode container ItemIds (and flavor text)
FCOIS.mappingVars.containerTransmuation = {}
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
FCOIS.mappingVars.containerTransmuation.geodeItemIds = {}
local geodeItemIds = FCOIS.mappingVars.containerTransmuation.geodeItemIds
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
--Current API version, starting with "Clockwork"
anchorVarsAddInvButtonsFill[100021] = {}
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY] = {}
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].anchorControl              = ZO_PlayerInventorySortByStatusIcon
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].left                       = -16
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].top                        = 32
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].defaultLeft                = -16
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY].defaultTop                 = 32
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW] = {}
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].anchorControl          = ZO_PlayerBankSortByStatusIcon
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].left                   = -16
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].top                    = 32
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].defaultLeft            = -16
anchorVarsAddInvButtonsFill[100021][LF_BANK_WITHDRAW].defaultTop             = 32
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW] = {}
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].anchorControl     = ZO_GuildBankSortByName
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].left              = -233
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].top               = 26
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].defaultLeft       = -233
anchorVarsAddInvButtonsFill[100021][LF_GUILDBANK_WITHDRAW].defaultTop        = 26
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].anchorControl        = ZO_SmithingTopLevelRefinementPanelInventorySortByName
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].left                 = -233
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].top                  = 26
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].defaultLeft          = -233
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].defaultTop           = 26
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].anchorControl   = ZO_SmithingTopLevelDeconstructionPanelInventorySortByName
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].left            = -238
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].top             = 26
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].defaultLeft     = -238
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].defaultTop      = 26
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].anchorControl   = ZO_SmithingTopLevelImprovementPanelInventorySortByName
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].left            = -238
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].top             = 26
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].defaultLeft     = -238
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].defaultTop      = 26
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION] = {}
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION] .anchorControl   = ZO_EnchantingTopLevelInventorySortByName
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].left             = -233
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].top              = 26
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].defaultLeft      = -233
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].defaultTop       = 26
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG] = {}
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].anchorControl               = ZO_CraftBagSortByName
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].left                        = -233
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].top                         = 26
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].defaultLeft                 = -233
anchorVarsAddInvButtonsFill[100021][LF_CRAFTBAG].defaultTop                  = 26
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT] = {}
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].anchorControl               = ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventorySortByNameName
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].left                        = -233
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].top                         = 26
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].defaultLeft                 = -233
anchorVarsAddInvButtonsFill[100021][LF_RETRAIT].defaultTop                  = 26
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW] = {}
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].anchorControl   = ZO_HouseBankSortByName
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].left            = -233
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].top             = 26
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].defaultLeft     = -233
anchorVarsAddInvButtonsFill[100021][LF_HOUSE_BANK_WITHDRAW].defaultTop      = 26
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].anchorControl        = ZO_SmithingTopLevelRefinementPanelInventorySortByName
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].left                 = -233
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].top                  = 26
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].defaultLeft          = -233
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].defaultTop           = 26
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].anchorControl   = ZO_SmithingTopLevelDeconstructionPanelInventorySortByName
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].left            = -238
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].top             = 26
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].defaultLeft     = -238
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].defaultTop      = 26
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].anchorControl   = ZO_SmithingTopLevelImprovementPanelInventorySortByName
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].left            = -238
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].top             = 26
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].defaultLeft     = -238
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].defaultTop      = 26
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
FCOIS.mappingVars.adjustAdditionalFlagButtonOffsetForPanel = {
    [ZO_CraftBagSortBy]     = true,
    [ZO_GuildBankSortBy]    = true,
    [ZO_SmithingTopLevelRefinementPanelInventorySortBy]     = true,
    [ZO_SmithingTopLevelDeconstructionPanelInventorySortBy] = true,
    [ZO_SmithingTopLevelImprovementPanelInventorySortBy]    = true,
    [ZO_EnchantingTopLevelInventorySortBy] = true,
    [ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventorySortByName] = true,
}
--The ordinal endings of the different languages
FCOIS.mappingVars.iconNrToOrdinalStr = {
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

--The global variable for the use temporary "UniqueIds" API
FCOIS.temporaryUseUniqueIds = {}