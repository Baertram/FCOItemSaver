    --Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

local tos = tostring
local strformat = string.format
local strlen = string.len


--===================== ADDON Info =============================================
--Addon variables
FCOIS.addonVars = {}
local addonVars = FCOIS.addonVars
--Addon variables
addonVars.addonVersionOptions 		    = '2.6.4' -- version shown in the settings panel
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
local esouiWWWAddonAuthorPortalFCOIS    = strformat(esouiWWW .. "/portal.php?&id=%s", tostring(esouiWWWAuthorId))
addonVars.website 					    = esouiWWW .. "/downloads/info630-FCOItemSaver.html"
addonVars.authorPortal                  = esouiWWWAddonAuthorPortalFCOIS
addonVars.FAQwebsite                    = esouiWWWAddonAuthorPortalFCOIS .. "&a=faq"
addonVars.feedback                      = esouiWWWAddonAuthorPortalFCOIS .. "&a=bugreport"
addonVars.FAQentry                      = addonVars.FAQwebsite .. "&faqid=%s"
addonVars.donation                      = strformat(addonVars.FAQwebsite .. "&faqid=%s", tostring(esouiWWWAddonDonationId))

--Variables for the addon's load state
addonVars.gAddonLoaded				= false
addonVars.gPlayerActivated			= false
addonVars.gSettingsLoaded			= false

local gAddonName = addonVars.gAddonName

--Dummy SCENE information for file FCOIS_functions.lua -> function FCOIS.getCurrentSceneInfo()
FCOIS.dummyScene = {
    ["name"] = gAddonName
}

--The table of number variables
FCOIS.numVars = {}
local numVars = FCOIS.numVars

--Constants for the unique itemId types
--FCOIS v1.9.6
FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE      = 1 --use base game's real uniqueIds by ZOs (even if items are totally the same, their id won't be the same)
FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE    = 2 --use FCOIS calculated uniqueIds based on item values like level,quality,enchantment,style,trait etc.
local maxIdTypes = FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE + 1
--The different types of IDs that can be used within FCOIS to mark items
numVars.idTypes                 = maxIdTypes
--The "lastusedType" constants for the "speed up" at function FCOIS.CreateFCOISUniqueIdString(itemId, bagId, slotIndex, itemLink)
FCOIS_CON_FCOISUNIQUEID_TYPE_BAGID_SLOTINDEX = 1
FCOIS_CON_FCOISUNIQUEID_TYPE_ITEMLINK = 2
numVars.lastUsedTypes = FCOIS_CON_FCOISUNIQUEID_TYPE_ITEMLINK

--The global variable for the use temporary "UniqueIds" API
FCOIS.temporaryUseUniqueIds = {}


--SavedVariables constants
local savedVarsMarkedItems = "markedItems"
addonVars.savedVarName				= gAddonName .. "_Settings"
addonVars.savedVarVersion		   	= 0.10 -- Changing this will reset all SavedVariables!
addonVars.savedVarsNumSaveModeTypes = 4 -- 1=Each character, 2=Account wide, 3=Each account saved the same, 4=Each server and account saved the same
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
FCOIS.svServerAllTheSameName        = "$AllServers"

--LibShifterBox boxName constants
FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES  = "FCOISuniqueIdItemTypes"
FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS             = "FCOISexcludedSets"

--The vendor type constants
FCOIS_CON_VENDOR_TYPE_NORMAL_NPC    = 1
FCOIS_CON_VENDOR_TYPE_PORTABLE      = 2

--For the localized icon texts, e.g. LAM icon dropdowns
local colorIconEndStr   = "color"
local nameIconEndStr    = "name"
FCOIS_CON_ICON_SUFFIX_COLOR =  colorIconEndStr
FCOIS_CON_ICON_SUFFIX_NAME  =  nameIconEndStr

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
local addonNameShort = addonVars.gAddonNameShort
FCOIS.preChatVars.preChatText = addonNameShort
--Green colored "FCOIS" pre text for the chat output
FCOIS.preChatVars.preChatTextGreen = protectionOnColor..addonNameShort.."|r "
--Red colored "FCOIS" pre text for the chat output
FCOIS.preChatVars.preChatTextRed = protectionOffColor..addonNameShort.."|r "
--Blue colored "FCOIS" pre text for the chat output
FCOIS.preChatVars.preChatTextBlue = "|c2222DD"..addonNameShort.."|r "
--Values for the "marked" entries
FCOIS.preChatVars.currentStart = "> "
FCOIS.preChatVars.currentEnd = " <"

--Error text constants
FCOIS.errorTexts = {}
FCOIS.errorTexts["libraryMissing"] = "ERROR: Needed library \'%s\' was not found. Addon is not working!"

--Get the current API version of the server, to distinguish code differences dependant on the API version
FCOIS.APIversion = GetAPIVersion()
FCOIS.APIVersionLength = strlen(FCOIS.APIversion) or 6

--======================================================================================================================
--                  LIBRARIES
--======================================================================================================================
FCOIS.libsLoadedProperly = false

local preVars = FCOIS.preChatVars
local libMissingErrorText = FCOIS.errorTexts["libraryMissing"]

--Initiliaze the library LibCustomMenu
if LibCustomMenu then FCOIS.LCM = LibCustomMenu else d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibCustomMenu")) return end

--Create the settings panel object of LibAddonMenu 2.0
FCOIS.LAM = LibAddonMenu2
if FCOIS.LAM == nil then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibAddonMenu-2.0")) return end

--The options panel of FCO ItemSaver
FCOIS.FCOSettingsPanel = nil

--Create the libMainMenu 2.0 object
FCOIS.LMM2 = LibMainMenu2
if FCOIS.LMM2 == nil then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibMainMenu-2.0")) return end
FCOIS.LMM2:Init()

--Create the filter object for addon libFilters 3.x
FCOIS.libFilters = {}
FCOIS.libFilters = LibFilters3
local libFilters = FCOIS.libFilters
if not libFilters then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibFilters-3.0")) return end
--Initialize the libFilters 3.x filters
libFilters:InitializeLibFilters()

--Initialize the library LibDialog
FCOIS.LDIALOG = LibDialog
if not FCOIS.LDIALOG then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibDialog")) return end

--Initialize the library LibFeedback
FCOIS.libFeedback = LibFeedback
--if FCOIS.libFeedback == nil and LibStub then FCOIS.libFeedback = LibStub:GetLibrary('LibFeedback', true) end
if not FCOIS.libFeedback then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibFeedback")) return end

--Initialize the library LibShifterBox
FCOIS.libShifterBox = LibShifterBox
if not FCOIS.libShifterBox == nil then d(preVars.preChatTextRed .. strformat(libMissingErrorText, "LibShifterBox")) return end

--Initialize the library LibSets
FCOIS.libSets = LibSets

--Initialize the library LibCharacterKnowledge
FCOIS.LCK = LibCharacterKnowledge


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Optional libraries
--LibMultiAccountSets
FCOIS.libMultiAccountSets = LibMultiAccountSets


--All libraries are loaded prolery?
FCOIS.libsLoadedProperly = true

FCOIS.mappingVars = {}
local mappingVars = FCOIS.mappingVars

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

mappingVars.langStrToLangConstant = {
    de = FCOIS_CON_LANG_DE,
    en = FCOIS_CON_LANG_EN,
    fr = FCOIS_CON_LANG_FR,
    es = FCOIS_CON_LANG_ES,
    it = FCOIS_CON_LANG_IT,
    jp = FCOIS_CON_LANG_JP,
    ru = FCOIS_CON_LANG_RU,
}
FCOIS.clientLanguage = GetCVar("language.2")

--Constant values for the whereAreWe panels
FCOIS_CON_WHEREAREWE_MIN        = 500
FCOIS_CON_DESTROY				= 710
FCOIS_CON_MAIL 					= 720
FCOIS_CON_TRADE 				= 730
FCOIS_CON_BUY					= 740
FCOIS_CON_SELL 					= 750
FCOIS_CON_BUYBACK				= 760
FCOIS_CON_REPAIR    			= 770
FCOIS_CON_IMPROVE 				= 780
FCOIS_CON_DECONSTRUCT 			= 790
FCOIS_CON_ENCHANT_EXTRACT 		= 800
FCOIS_CON_ENCHANT_CREATE 		= 810
FCOIS_CON_GUILD_STORE_SELL 		= 820
FCOIS_CON_FENCE_SELL 			= 830
FCOIS_CON_LAUNDER_SELL 			= 840
FCOIS_CON_ALCHEMY_DESTROY 		= 850
FCOIS_CON_CONTAINER_AUTOOLOOT 	= 860
FCOIS_CON_RECIPE_USAGE 			= 870
FCOIS_CON_MOTIF_USAGE 			= 880
FCOIS_CON_POTION_USAGE 			= 890
FCOIS_CON_FOOD_USAGE 			= 900
FCOIS_CON_CRAFTBAG_DESTROY		= 910
FCOIS_CON_REFINE				= 920
FCOIS_CON_RESEARCH				= 930
FCOIS_CON_RETRAIT               = 940
FCOIS_CON_REFINE				= 950
FCOIS_CON_JEWELRY_REFINE		= 960
FCOIS_CON_JEWELRY_DECONSTRUCT 	= 970
FCOIS_CON_JEWELRY_IMPROVE		= 980
FCOIS_CON_JEWELRY_RESEARCH		= 990
FCOIS_CON_RESEARCH_DIALOG       = 1000
FCOIS_CON_JEWELRY_RESEARCH_DIALOG = 1010
FCOIS_CON_GUILDBANK_DEPOSIT     = 1020
FCOIS_CON_COMPANION_DESTROY     = 1030
FCOIS_CON_CROWN_ITEM            = 9000
FCOIS_CON_FALLBACK 				= 9990

--Constant values for the FCOItemSaver filter buttons at the inventories (bottom)
FCOIS_CON_FILTER_BUTTON_LOCKDYN			= 1
FCOIS_CON_FILTER_BUTTON_GEARSETS		= 2
FCOIS_CON_FILTER_BUTTON_RESDECIMP		= 3
FCOIS_CON_FILTER_BUTTON_SELLGUILDINT	= 4
--Filter button state
FCOIS_CON_FILTER_BUTTON_STATE_GREEN     = true
FCOIS_CON_FILTER_BUTTON_STATE_YELLOW    = -99
FCOIS_CON_FILTER_BUTTON_STATE_RED       = false
--Filter button special states
FCOIS_CON_FILTER_BUTTON_STATE_DO_NOT_UPDATE_COLOR = -999 --Do not update the colors if called from FCOIS settings menu

--Prevention variables
FCOIS.preventerVars = {}
local preventerVars = FCOIS.preventerVars

--Filter buttons
--TODO FEATURE: As of 2022-03-11 the logical conjunctions of the filterButtons do not work properly if some are set to AND and some are set to OR
--So for now they will all change at the same time to AND or OR
--Change orr emove this preventerVariable to update them single again
preventerVars.filterButtonSettingsChangeAllToTheSame = true

--Filter button color
mappingVars.filterButtonColors = {
    [FCOIS_CON_FILTER_BUTTON_STATE_GREEN]     = { 0, 1, 0, 1 },
    [FCOIS_CON_FILTER_BUTTON_STATE_YELLOW]    = { 1, 1, 0, 1 },
    [FCOIS_CON_FILTER_BUTTON_STATE_RED]       = { 1, 0, 0, 1 },
}

--Custom filterPanelIds, not offical of LibFilters, only given within FCOIS (for the "flag" context menu buttons e.g.)
FCOIS_CON_LF_CHARACTER              = "character"
FCOIS_CON_LF_COMPANION_CHARACTER    = "companion_character"

FCOIS.customFilterPanelIds = {
    FCOIS_CON_LF_CHARACTER,
    FCOIS_CON_LF_COMPANION_CHARACTER
}

--The check variables/tables
FCOIS.checkVars = {}
local checkVars = FCOIS.checkVars
checkVars.filterButtonsToCheck = {
    [1] = FCOIS_CON_FILTER_BUTTON_LOCKDYN,
    [2] = FCOIS_CON_FILTER_BUTTON_GEARSETS,
    [3] = FCOIS_CON_FILTER_BUTTON_RESDECIMP,
    [4] = FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
}
checkVars.filterButtonSuffix = "_FilterButton"

--Constants for the automatic set item marking, non wished traits:
FCOIS_CON_NON_WISHED_TRAIT      = -1
FCOIS_CON_NON_WISHED_LEVEL      = 1
FCOIS_CON_NON_WISHED_QUALITY    = 2
FCOIS_CON_NON_WISHED_ALL        = 3
FCOIS_CON_NON_WISHED_ANY_OF_THEM = 99

--Build local localization/language variables which will be transfered to the real localization vars in file /src/FCOIS_localization.lua,
--in function Localization()
FCOIS.localLocalizationsVars = {}

--Global value: Number of filter icons to choose by right click menu
numVars.languageCount = FCOIS_CON_LANG_MAX --English, German, French, Spanish, Italian, Japanese, Russian
--Global: Count of available inventory filter types (LF_INVENTORY, LF_BANK_WITHDRAW, etc. -> see above)
numVars.gFCONumFilterInventoryTypes = FCOIS.libFilters:GetMaxFilterType()  -- Maximum libFilters 3.0 filter types
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
--The amount of markerIcons below the resDecImp context menu
numVars.resDecImpIconCount      = 3
--The amount of markerIcons below the sellGuildInt context menu
numVars.sellGuildIntIconCount   = 3

--The maximum number at the ITEMTYPE constants
local itemTypeMaxFallback = ITEMTYPE_ITERATION_END -- should be 71 -> ITEMTYPE_GROUP_REPAIR at date 2021-05-06
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
     2 = Gear set 1             (Gear static 1)
     3 = Research				(RES)
     4 = Gear set 2             (Gear static 2)
     5 = Sell					(SELL)
     6 = Gear set 3             (Gear static 3)
     7 = Gear set 4             (Gear static 4)
     8 = Gear set 5             (Gear static 5)
     9 = Deconstruction			(DEC)
    10 = Improvement			(IMP)
    11 = Sell at guild store	(GUILD)
    12 = Intricate				(INT)
    13 = Dynamic 1				(DYN)
    14 = Dynamic 2              (DYN)
    15 = Dynamic 3				(DYN)
    16 = Dynamic 4              (DYN)
    17 = Dynamic 5				(DYN)
    18 = Dynamic 6              (DYN)
    19 = Dynamic 7				(DYN)
    20 = Dynamic 8              (DYN)
    21 = Dynamic 9              (DYN)
    22 = Dynamic 10             (DYN)
    23 = Dynamic 11             (DYN)
    24 = Dynamic 12             (DYN)
    25 = Dynamic 13             (DYN)
    26 = Dynamic 14             (DYN)
    27 = Dynamic 15             (DYN)
    28 = Dynamic 16             (DYN)
    29 = Dynamic 17             (DYN)
    30 = Dynamic 18             (DYN)
    31 = Dynamic 19             (DYN)
    32 = Dynamic 20             (DYN)
    33 = Dynamic 21             (DYN)
    34 = Dynamic 22             (DYN)
    35 = Dynamic 23             (DYN)
    36 = Dynamic 24             (DYN)
    37 = Dynamic 25             (DYN)
    38 = Dynamic 26             (DYN)
    39 = Dynamic 27             (DYN)
    40 = Dynamic 28             (DYN)
    41 = Dynamic 29             (DYN)
    42 = Dynamic 30             (DYN)
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
FCOIS_DEBUG_DEPTH_VERBOSE       = 99
FCOIS_DEBUG_DEPTH_ALL			= 5

--The inventory row patterns for the supported keybindings and MouseOverControl checks (SHIFT+right mouse functions e.g.)
--See file src/FCOIS_Functions.lua, function FCOIS.GetBagAndSlotFromControlUnderMouse()
checkVars.inventoryRowPatterns = {
    "^ZO_%a+Backpack%dRow%d%d*",                                            --Inventory backpack
    "^ZO_%a+InventoryList%dRow%d%d*",                                       --Inventory backpack
    "^ZO_CharacterEquipmentSlots.+$",                                       --Character
    "^ZO_CraftBagList%dRow%d%d*",                                           --CraftBag
    "^ZO_Smithing%aRefinementPanelInventoryBackpack%dRow%d%d*",             --Smithing refinement
    "^ZO_RetraitStation_%a+RetraitPanelInventoryBackpack%dRow%d%d*",        --Retrait
    "^ZO_QuickSlot_Keyboard_TopLevelList%dRow%d%d*",                        --Quickslot
    "^ZO_RepairWindowList%dRow%d%d*",                                       --Repair at vendor
    "^ZO_ListDialog1List%dRow%d%d*",                                        --List dialog (Repair, Recharge, Enchant, Research)
    "^ZO_CompanionEquipment_Panel_.+List%dRow%d%d*",                        --Companion Inventory backpack
    "^ZO_CompanionCharacterWindow_.+_TopLevelEquipmentSlots.+$",            --Companion character
    "^ZO_UniversalDeconstructionTopLevel_%a+PanelInventoryBackpack%dRow%d%d*",-- #202 Universal deconstruction
--Other adons like IIfA will be added dynamically at EVENT_ON_ADDON_LOADED callback function
--See file src/FCOIS_Events.lua, call to function FCOIS.checkIfOtherAddonActive() -> See file
-- src/FCOIS_OtherAddons.lua, function FCOIS.checkIfOtherAddonActive()
}


--Array for the mapping between variables and values
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
local otherAddons = FCOIS.otherAddons
    
-- Local variables for improvement
FCOIS.improvementVars = {}
-- Local variables for enchanting
FCOIS.enchantingVars = {}
FCOIS.enchantingVars.lastMarkerIcons = {}

--Last item's markers (set by clicking the divider if enabled in the settings)
FCOIS.lastMarkedIcons			= nil

--Entries for the context menu submenu entries, and the dynamic icons submenu entries
FCOIS.customMenuVars.customMenuSubEntries		= {}
FCOIS.customMenuVars.customMenuDynSubEntries	= {}
FCOIS.customMenuVars.customMenuCurrentCounter 	= 0
contextMenuVars.contextMenuIndex 			= -1

--Handlers for the check functions (see function FCOIS.IsItemprotected() in file FCOIS_Protection.lua)
checkVars.checkHandlers = {}
checkVars.checkHandlers["gear"]     = true
checkVars.checkHandlers["dynamic"]  = true

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
--to use these for the (un)marking of items (e.g. within addon Inventory Insight from Ashes, IIfA)
mappingVars.bagsToBuildItemInstanceOrUniqueIdFor =  {
    --non account wide, as it used bagId and slotIndex
    [BAG_WORN]              = true,
    [BAG_COMPANION_WORN]    = true,
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
        [FCOIS_CON_COMPANION_DESTROY]   = LF_INVENTORY_COMPANION,
}
--The array for the mapping between the LibFilters FilterPanelId and the "WhereAreWe" (e.g. used in ItemSelectionHandler function)
mappingVars.filterPanelIdToWhereAreWe = {}
for whereAreWe, filterPanelId in pairs(mappingVars.whereAreWeToFilterPanelId) do
    --For the companion: There is no extra "Anti companion destroy" option at dynamic icons, so just return the normal destroy constant
    --for it as well! Else the tooltip always says the protection is disabled.
    if filterPanelId == LF_INVENTORY_COMPANION then
        whereAreWe = FCOIS_CON_DESTROY
    end
    mappingVars.filterPanelIdToWhereAreWe[filterPanelId] = whereAreWe
end
--Mapping of the filterPanelId to whereAreWe constant, repsecting the crafting type
--2021-08-15 Only JewelryCrafting so far supported to differ refine, decon, improve, research and research dialog for normal/jewelry crafting
mappingVars.filterPanelIdToFilterPanelIdRespectingCrafttype = {}
    if libFilters.mapping and libFilters.mapping.filterTypeToFilterTypeRespectingCraftType ~= nil then
        mappingVars.filterPanelIdToFilterPanelIdRespectingCrafttype[CRAFTING_TYPE_JEWELRYCRAFTING] = libFilters.mapping.filterTypeToFilterTypeRespectingCraftType
    else
        mappingVars.filterPanelIdToFilterPanelIdRespectingCrafttype[CRAFTING_TYPE_JEWELRYCRAFTING] = {
            [LF_SMITHING_REFINE]            = LF_JEWELRY_REFINE,
            [LF_SMITHING_DECONSTRUCT]       = LF_JEWELRY_DECONSTRUCT,
            [LF_SMITHING_IMPROVEMENT]       = LF_JEWELRY_IMPROVEMENT,
            [LF_SMITHING_RESEARCH]          = LF_JEWELRY_RESEARCH,
            [LF_SMITHING_RESEARCH_DIALOG]   = LF_JEWELRY_RESEARCH_DIALOG,
        }
    end

--Mapping of the filterPanelIds which should change the "Ant-isettings" automatically if a panelId is changed
--> see file src/FCOIS_Panels.lua, function FCOIS.UpdateAntiCheckAtPanelVariable
mappingVars.dependingAntiCheckPanelIdsAtPanelId = {
    [LF_INVENTORY] = {
        LF_BANK_DEPOSIT,
        LF_GUILDBANK_DEPOSIT,
        LF_HOUSE_BANK_DEPOSIT,
        LF_BANK_WITHDRAW,
        LF_GUILDBANK_WITHDRAW,
        LF_HOUSE_BANK_WITHDRAW,
        LF_INVENTORY_COMPANION
    },
}

--Mapping of the filterPanelId to the block setting name
local filterPanelIdToBlockSettingName = {
    --blockDestroying will be always checked at first within function FCOIS.ChangeAntiSettingsAccordingToFilterPanel()
    --in file src/FCOIS_Settings.lua, using table FCOIS.checkVars.filterPanelIdsForAntiDestroy
    --and used within function FCOIS.CheckIfProtectedSettingsEnabled, in file src/FCOIS_Protection.lua
    -------------------------------------------------------------------
    --Direct/Single entries
    -------------------------------------------------------------------
    [LF_VENDOR_BUY]                 = "blockVendorBuy",
    [LF_VENDOR_SELL]                = "blockSelling",
    [LF_VENDOR_BUYBACK]             = "blockVendorBuyback",
    [LF_VENDOR_REPAIR]              = "blockVendorRepair",
    [LF_FENCE_SELL]                 = "blockFence",
    [LF_FENCE_LAUNDER]              = "blockLaunder",
    [LF_SMITHING_REFINE]            = "blockRefinement",
    [LF_SMITHING_DECONSTRUCT]       = "blockDeconstruction",
    [LF_SMITHING_IMPROVEMENT]       = "blockImprovement",
    [LF_SMITHING_RESEARCH]          = "blockResearch",
    [LF_SMITHING_RESEARCH_DIALOG]   = "blockResearch",
    [LF_GUILDSTORE_SELL]            = "blockSellingGuildStore",
    [LF_MAIL_SEND]                  = "blockSendingByMail",
    [LF_TRADE]                      = "blockTrading",
    [LF_ALCHEMY_CREATION]           = "blockAlchemyDestroy",
    [LF_ENCHANTING_CREATION]        = "blockEnchantingCreation",
    [LF_ENCHANTING_EXTRACTION]      = "blockEnchantingExtraction",
    [LF_RETRAIT]                    = "blockRetrait",
    [LF_JEWELRY_REFINE]             = "blockJewelryRefinement",
    [LF_JEWELRY_DECONSTRUCT]        = "blockJewelryDeconstruction",
    [LF_JEWELRY_IMPROVEMENT]        = "blockJewelryImprovement",
    [LF_JEWELRY_RESEARCH]           = "blockJewelryResearch",
    [LF_JEWELRY_RESEARCH_DIALOG]    = "blockJewelryResearch",
    [LF_GUILDBANK_DEPOSIT]          = "blockGuildBankWithoutWithdraw",
    -------------------------------------------------------------------
    --Other/Multi-entries
    -------------------------------------------------------------------
    -->CraftBag with CraftBageExtended active
        [LF_CRAFTBAG]                   = {
            callbackFunc = FCOIS.CheckIfCBEorAGSActive, --Will be nil at load but re-added at file src/FCOIS_OtherAddons.lua, below function FCOIS.CheckIfCBEorAGSActive!
            filterPanelToBlockSetting = {
                [LF_MAIL_SEND]          = "blockSendingByMail",
                [LF_GUILDSTORE_SELL]    = "blockSellingGuildStore",
                [LF_TRADE]              = "blockTrading",
                [LF_VENDOR_SELL]        = "blockSelling",
            }
        },
    -------------------------------------------------------------------
    --WhereAreWe entries
    -------------------------------------------------------------------
    --From FCOIS_CON_WHEREAREWE_MIN to higher values
    --Special entries for the call from ItemSelectionHandler() function's variable 'whereAreWe'
    [FCOIS_CON_DESTROY]				= "blockDestroying",			    --Destroying
    [FCOIS_CON_MAIL]				= "blockSendingByMail",     	    --Mail send
    [FCOIS_CON_TRADE]				= "blockTrading",				--Trading
    [FCOIS_CON_BUY]				    = "blockVendorBuy",              --Vendor buy
    [FCOIS_CON_SELL]				= "blockSelling",                --Vendor sell
    [FCOIS_CON_BUYBACK]				= "blockVendorBuyback",          --Vendor buyback
    [FCOIS_CON_REPAIR]				= "blockVendorRepair",           --Vendor repair
    [FCOIS_CON_REFINE]				= "blockRefinement",			    --Refinement",
    [FCOIS_CON_DECONSTRUCT]			= "blockDeconstruction",		    --Deconstruction
    [FCOIS_CON_IMPROVE]				= "blockImprovement",			--Improvement
    [FCOIS_CON_RESEARCH]			= true,   			                    --Research -> Always return true as there is no special option for anti-research and the protection is on
    [FCOIS_CON_RESEARCH_DIALOG] 	= "blockResearchDialog", 		--Research dialog
    [FCOIS_CON_JEWELRY_REFINE]		= "blockJewelryRefinement",		--Jewelry Refinement,
    [FCOIS_CON_JEWELRY_DECONSTRUCT]	= "blockJewelryDeconstruction",	--Jewelry Deconstruction
    [FCOIS_CON_JEWELRY_IMPROVE]		= "blockJewelryImprovement",		--Jewelry Improvement
    [FCOIS_CON_JEWELRY_RESEARCH]    = true, 								--Jewelry research -> Always return true as there is no special option for anti-jewelry research and the protection is on
    [FCOIS_CON_JEWELRY_RESEARCH_DIALOG] = "blockJewelryResearchDialog", --Jewelry research dialog
    [FCOIS_CON_ENCHANT_EXTRACT]		= "blockEnchantingExtraction",   --Enchanting extraction
    [FCOIS_CON_ENCHANT_CREATE]		= "blockEnchantingCreation",	    --Enchanting creation
    [FCOIS_CON_GUILD_STORE_SELL]	= "blockSellingGuildStore",	    --Guild store sell
    [FCOIS_CON_FENCE_SELL]			= "blockFence",                  --Fence sell
    [FCOIS_CON_LAUNDER_SELL]		= "blockLaunder",			    --Fence launder
    [FCOIS_CON_ALCHEMY_DESTROY]		= "blockAlchemyDestroy",		    --Alchemy destroy
    [FCOIS_CON_CONTAINER_AUTOOLOOT]	= "blockAutoLootContainer",	    --Auto loot container
    [FCOIS_CON_RECIPE_USAGE]   		= "blockMarkedRecipes", 		    --Recipe
    [FCOIS_CON_MOTIF_USAGE]			= "blockMarkedMotifs", 		    --Racial style motif
    [FCOIS_CON_POTION_USAGE]		= "blockMarkedPotions", 		    --Potion
    [FCOIS_CON_FOOD_USAGE]	   		= "blockMarkedFood", 		    --Food
    [FCOIS_CON_CROWN_ITEM]	   		= "blockCrownStoreItems", 		--Crown store items
    [FCOIS_CON_CRAFTBAG_DESTROY]	= "blockDestroying", 		    --Craftbag", destroying
    [FCOIS_CON_RETRAIT]	            = "blockRetrait", 			    --Retrait station", retrait
    [FCOIS_CON_COMPANION_DESTROY]	= "blockDestroying",			    --Companion inventory destroying
    [FCOIS_CON_FALLBACK]			= false,							    --Always return false. Used e.g. for the bank/guild bank deposit checks
}
mappingVars.filterPanelIdToBlockSettingName = filterPanelIdToBlockSettingName

--The mapping array for the block settings at deconstruction
--Used in function FCOIS.DeconstructionSelectionHandler in file src/FCOIS_Protection.lua
local deconPanelToBlockSettingsTable = {
    LF_SMITHING_DECONSTRUCT,
    LF_JEWELRY_DECONSTRUCT,
}
local deconPanelToBlockSettingsStrTab = {}
for _, filterPanelId in ipairs(deconPanelToBlockSettingsTable) do
    deconPanelToBlockSettingsStrTab[filterPanelId] = filterPanelIdToBlockSettingName[filterPanelId]
end
mappingVars.deconPanelToBlockSettingsStrTab = deconPanelToBlockSettingsStrTab

--The mapping array to skip the dyanmic icon checks, as the whereAreWe filter panel ID is related to single item checks!
--Used in function FCOIS.ItemSelectionHandler in file src/FCOIS_Protection.lua
local whereAreWeToSingleItemChecks = {
        [FCOIS_CON_CONTAINER_AUTOOLOOT]	= true,	--Auto loot container
        [FCOIS_CON_RECIPE_USAGE]		= true, --Recipe
        [FCOIS_CON_MOTIF_USAGE]			= true, --Racial style motif
        [FCOIS_CON_POTION_USAGE]		= true, --Potion
        [FCOIS_CON_FOOD_USAGE]			= true, --Food
        [FCOIS_CON_CROWN_ITEM]			= true, --Crown store item
    }
mappingVars.whereAreWeToSingleItemChecks = whereAreWeToSingleItemChecks

--The array with the alert message texts for every filterPanel
--> filled at src/FCOIS_Localization.lua, function FCOIS.Localization()
mappingVars.whereAreWeToAlertmessageText = {}

--The array with the medium text part for the context menu at filter buttons (e.g. tooltip)
--> filled at src/FCOIS_Localization.lua, function FCOIS.Localization()
mappingVars.filterPanelToFilterButtonMediumOutputText = {}

--The array with the "is filter active" setting "text". Used to check if the filter button is enabled at the panel
--via check to FCOIS.settingsVars.settings[FCOIS.mappingVars.filterPanelToFilterButtonFilterActiveSettingName[LF_*]]
--> Used in files src/FCOIS_Settings.lua, function FCOIS.GetFilterWhereBySettings and
--> src/FCOIS_FilterButtons.lua, local function filterStatusLoop (used in slash commands)
local allowInvFilterStr =           "allowInventoryFilter"
local allowEnchantFilter =          "allowEnchantingFilter"
local allowResearchFilter =         "allowResearchFilter"
local allowJewelryResearchFilter =  "allowJewelryResearchFilter"
mappingVars.filterPanelToFilterButtonFilterActiveSettingName = {
    [LF_INVENTORY] =                allowInvFilterStr,
    [LF_BANK_DEPOSIT] =             allowInvFilterStr,
    [LF_GUILDBANK_DEPOSIT] =        allowInvFilterStr,
    [LF_HOUSE_BANK_DEPOSIT] =       allowInvFilterStr,
    [LF_CRAFTBAG] =                 "allowCraftBagFilter",
    [LF_VENDOR_BUY] =               "allowVendorBuyFilter",
    [LF_VENDOR_SELL] =              "allowVendorFilter",
    [LF_VENDOR_BUYBACK] =           "allowVendorBuybackFilter",
    [LF_VENDOR_REPAIR] =            "allowVendorRepairFilter",
    [LF_FENCE_SELL] =               "allowFenceFilter",
    [LF_FENCE_LAUNDER] =            "allowLaunderFilter",
    [LF_BANK_WITHDRAW] =            "allowBankFilter",
    [LF_GUILDBANK_WITHDRAW] =       "allowGuildBankFilter",
    [LF_HOUSE_BANK_WITHDRAW] =      "allowBankFilter",
    [LF_GUILDSTORE_SELL] =          "allowTradinghouseFilter",
    [LF_SMITHING_REFINE] =          "allowRefinementFilter",
    [LF_SMITHING_DECONSTRUCT] =     "allowDeconstructionFilter",
    [LF_SMITHING_IMPROVEMENT] =     "allowImprovementFilter",
    [LF_SMITHING_RESEARCH] =        allowResearchFilter,
    [LF_SMITHING_RESEARCH_DIALOG] = allowResearchFilter,
    [LF_JEWELRY_REFINE] =           "allowJewelryRefinementFilter",
    [LF_JEWELRY_DECONSTRUCT] =      "allowJewelryDeconstructionFilter",
    [LF_JEWELRY_IMPROVEMENT] =      "allowJewelryImprovementFilter",
    [LF_JEWELRY_RESEARCH] =         allowJewelryResearchFilter,
    [LF_JEWELRY_RESEARCH_DIALOG] =  allowJewelryResearchFilter,
    [LF_MAIL_SEND] =                "allowMailFilter",
    [LF_TRADE] =                    "allowTradeFilter",
    [LF_ENCHANTING_EXTRACTION] =    allowEnchantFilter,
    [LF_ENCHANTING_CREATION] =      allowEnchantFilter,
    [LF_ALCHEMY_CREATION] =         "allowAlchemyFilter",
    [LF_RETRAIT] =                  "allowRetraitFilter",
    [LF_INVENTORY_COMPANION] =      "allowCompanionInventoryFilter",
}


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
    [LF_SMITHING_RESEARCH]          = true,  -- Enabled with #242, 2022-08-17
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
    [LF_JEWELRY_RESEARCH]		    = true,  -- Enabled with #242, 2022-08-17
    [LF_JEWELRY_RESEARCH_DIALOG]    = true,
    [LF_INVENTORY_COMPANION]        = true,
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

--The LibFilters panelIds of deconstruction with it's mapping to the other craftingType
mappingVars.deconstructablePanelIdToOtherCraftType = {
    --Deconstructable
    [LF_SMITHING_DECONSTRUCT] = LF_JEWELRY_DECONSTRUCT,
    [LF_JEWELRY_DECONSTRUCT]  = LF_SMITHING_DECONSTRUCT,
}

--#202 -v-
--function to search the UniversalDeconstruction tabs for it's key (displayName) and return the tab's table then
function FCOIS.GetDataFromUniversalDeconstructionMenuBar(key)
    local barToSearch = ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES
    if barToSearch then
        for _, v in ipairs(barToSearch) do
            if v.key and v.key == key then
                return v
            end
        end
    end
    return
end
local getDataFromUniversalDeconstructionMenuBar = FCOIS.GetDataFromUniversalDeconstructionMenuBar
--The LibFilters filterTypes which are supported at the universal deconstruction NPC e.g. 'Giladil'
--[[
mappingVars.panelIdSupportedAtUniversalDeconstructionNPC = {
    [LF_SMITHING_DECONSTRUCT]   = true,
    [LF_JEWELRY_DECONSTRUCT]    = true,
    [LF_ENCHANTING_EXTRACTION]  = true,
}
]]
mappingVars.panelIdSupportedAtUniversalDeconstructionNPC = libFilters.mapping.universalDeconFilterTypeToFilterBase

mappingVars.universalDeconFilterPanelIdToWhereAreWe = {
    [LF_SMITHING_DECONSTRUCT]   = FCOIS_CON_DECONSTRUCT,
    [LF_JEWELRY_DECONSTRUCT]    = FCOIS_CON_DECONSTRUCT,
    [LF_ENCHANTING_EXTRACTION]  = FCOIS_CON_ENCHANT_EXTRACT,
}

--The LibFilters-3.0 mapping between Universal Deconstructiona ctive tab and the LF_* filterType
local libFiltersUniversalDeconTabToFilterType = libFilters.mapping.universalDeconTabKeyToLibFiltersFilterType

--The NPC decon menuBars tab's buttons -> filterPanelId
mappingVars.panelIdByUniversalDeconstructionNPCMenuBarTabButtonName = {
    [getDataFromUniversalDeconstructionMenuBar("enchantments").displayName]   = libFiltersUniversalDeconTabToFilterType["enchantments"], --LF_ENCHANTING_EXTRACTION, --Glyphs
    [getDataFromUniversalDeconstructionMenuBar("jewelry").displayName]        = libFiltersUniversalDeconTabToFilterType["jewelry"],      --LF_JEWELRY_DECONSTRUCT,   --Jewelry
    [getDataFromUniversalDeconstructionMenuBar("armor").displayName]          = libFiltersUniversalDeconTabToFilterType["armor"],        --LF_SMITHING_DECONSTRUCT,  --Armor
    [getDataFromUniversalDeconstructionMenuBar("weapons").displayName]        = libFiltersUniversalDeconTabToFilterType["weapons"],      --LF_SMITHING_DECONSTRUCT,  --Weapons
    [getDataFromUniversalDeconstructionMenuBar("all").displayName]            = libFiltersUniversalDeconTabToFilterType["all"],          --LF_SMITHING_DECONSTRUCT,  --All
}


--FilterPanelIds which need the FCOIS.RefreshListDialog function
mappingVars.filterPanelIdForRefreshDialog = {
    [LF_SMITHING_RESEARCH_DIALOG] = true,
    [LF_JEWELRY_RESEARCH_DIALOG] =  true,
}
---^- #202

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
    [LF_INVENTORY_COMPANION]                    = FCOIS_CON_LIBFILTERS_STRING_PREFIX_FCOIS .. "CompanionInventoryFilter_",
}
--Mapping array for the LibFilters filter panel ID to filter function
--> This array will be filled in file src/FCOIS_Filters.lua, function "FCOIS.mapLibFiltersIds2FilterFunctionsNow()"
mappingVars.libFiltersId2filterFunction = {}

local function getHouseBankBagId()
    local houseBankBagId = GetBankingBag() or BAG_HOUSE_BANK_ONE
    return houseBankBagId
end

--Mapping array for the LibFilters filter panel ID to inventory bag ID (if relation is 1:1, else the entry will be nil
--and the relevant bagIds will be detected where needed by the help of LibFilters (using ZOs vanilla code to create virtual
--list of the bagIds needed, e.g. worn, inventory, bank for research) e.g. or manually in the FCOIS code!)
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
    [LF_INVENTORY_COMPANION]                    = BAG_BACKPACK,
}

--Mapping array for the inventory bag ID to the LibFilters filter panel ID (if relation is 1:1!)
mappingVars.bagId2LibFiltersId = {
    [BAG_BACKPACK]          = LF_INVENTORY,
    [BAG_BANK]              = LF_BANK_WITHDRAW,
    [BAG_SUBSCRIBER_BANK]   = LF_BANK_WITHDRAW,
    [BAG_GUILDBANK]         = LF_GUILDBANK_WITHDRAW,
    [BAG_HOUSE_BANK_ONE]    = LF_HOUSE_BANK_WITHDRAW, --static: Use the first house bank bagId
    [BAG_VIRTUAL]           = LF_CRAFTBAG,
    --The following filterPanelIds do not own a dedicated bagId. Either they got multiple of the above ones connected,
    --or they also use only BAG_BACKPACK e.g.
    --The correct filterPanelId needs to be determined via the shown controls e.g. or via LibFilters 3
    --> See function FCOIS.GetFilterPanelIdByBagId() in file src/FCOIS_functions.lua
    --[nil]                 = LF_GUILDBANK_DEPOSIT,
    --[nil]                 = LF_BANK_DEPOSIT,
    --[nil]                 = LF_VENDOR_SELL,
    --[nil]                 = LF_SMITHING_REFINE,
    --[nil]                 = LF_SMITHING_DECONSTRUCT,
    --[nil]                 = LF_JEWELRY_REFIN,
    --[nil]                 = LF_SMITHING_IMPROVEMENT,
    --[nil]                 = LF_JEWELRY_DECONSTRUCT,
    --[nil]                 = LF_JEWELRY_IMPROVEMENT,
    --[nil]                 = LF_SMITHING_RESEARCH,
    --[nil]                 = LF_SMITHING_RESEARCH_DIALOG,
    --[nil]                 = LF_JEWELRY_RESEARCH,
    --[nil]                 = LF_JEWELRY_RESEARCH_DIALOG,
    --[nil]                 = LF_GUILDSTORE_SELL,
    --[nil]                 = LF_MAIL_SEND,
    --[nil]                 = LF_TRADE,
    --[nil]                 = LF_ENCHANTING_EXTRACTION,
    --[nil]                 = LF_ENCHANTING_CREATION,
    --[nil]                 = LF_FENCE_SELL,
    --[nil]                 = LF_FENCE_LAUNDER,
    --[nil]                 = LF_ALCHEMY_CREATION,
    --[nil]                 = LF_RETRAIT,
    --[nil]                 = LF_HOUSE_BANK_DEPOSIT,
    --[nil]                 = LF_INVENTORY_COMPANION,
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
    GUILD_HISTORY_KEYBOARD_SCENE, --#275 Fix guild history scene reference
    GUILD_CREATE_SCENE,
    NOTIFICATIONS_SCENE,
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

--[[

]]
--Improvable crafting skills
mappingVars.isImprovementCraftSkill = {
    [CRAFTING_TYPE_INVALID]         = false,
    [CRAFTING_TYPE_ALCHEMY]         = false,
    [CRAFTING_TYPE_ENCHANTING]      = false,
    [CRAFTING_TYPE_PROVISIONING]    = false,
    --Improvable ones
    [CRAFTING_TYPE_BLACKSMITHING]   = true,
    [CRAFTING_TYPE_CLOTHIER]        = true,
    [CRAFTING_TYPE_JEWELRYCRAFTING] = true,
    [CRAFTING_TYPE_WOODWORKING]     = true,
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
--The created filterButtons will be saved here, for each filterPanelId
filterButtonVars.filterButtons = {}
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
--Filter button offset Y at the research dialog
filterButtonVars.buttonOffsetYResearchDialog = 4

--Filter button offset on x axis, if InventoryGriView addon is active too
otherAddons.gGriedViewOffsetX			= 26
--Variables for the test if the Addon "Inventory Gridview" is enabled
otherAddons.GRIDVIEWBUTTON    		= "ZO_PlayerInventory_GridButton"

otherAddons.inventoryGridViewActive = false
--For the test, if the addon "Chat Merchant" is enabled
otherAddons.CHATMERCHANTBUTTON 		= "ZO_PlayerInventory_CMbutton"
otherAddons.chatMerchantActive 		= false
--For the test, if the addon "Research Assistant" is enabled
otherAddons.researchAssistantActive	= false
--For the test, if the addon "PotionMaker" is enabled
otherAddons.potionMakerActive		= false
--For the test, if the addon "Votans Settings Menu" is enabled
otherAddons.votansSettingsMenuActive= false
--For the test, if the addon "sousChef" is enabled
otherAddons.sousChefActive = false
--For the test, if the addon "CraftStoreFixedAndImprovedActive" is enabled
otherAddons.craftStoreFixedAndImprovedActive = false
--For the test, if the addon "CraftBagExtended" is enabled
otherAddons.craftBagExtendedActive = false
otherAddons.craftBagExtendedSupportedFilterPanels = {
    [LF_GUILDBANK_DEPOSIT]  =   true,
    [LF_BANK_DEPOSIT]       =   true,
    [LF_GUILDBANK_WITHDRAW] =   true, --Todo BUG?: Is this valid for CraftbagExtended, can we withdraw items there? Used in FCOIS_Hooks.lua -> ctrlVars.CRAFT_BAG_FRAGMENT StateChange
    [LF_MAIL_SEND]          =   true,
    [LF_GUILDSTORE_SELL]    =   true,
    [LF_TRADE]              =   true,
	[LF_VENDOR_SELL]		=   true,
    [LF_HOUSE_BANK_DEPOSIT] =   true,
}
--For the addon SetTracker
otherAddons.SetTracker = {}
otherAddons.SetTracker.isActive = false
--For the addon AwesomeGuildStore (Craftbag support at guild sell tab) is enabled
otherAddons.AGSActive = false
--For the addon AdvancedDisableController UI is enabled
otherAddons.ADCUIActive = false
--For the test, if the addon "LazyWritCreator" is enabled
otherAddons.LazyWritCreatorActive = false
--For the QualitySort addon which is moving the "name" sort header to the left by n (currently 80) pixles
otherAddons.qualitySortActive = false
otherAddons.QualitySortOffsetX = 80 + 1 -- +1 as there seems to be a small space left compared to the other positions: Moving "name" sort header to the left on x axis by this pixels. See file QualitySort.lua, line 256ff (function QualitySort.addSortByQuality(flag))
--For the AdvancedFilters plugin AF_FCODuplicateItemsFilter
otherAddons.AFFCODuplicateItemFilter = false
--For the Inventory Insight from ashes addon
otherAddons.IIFAActive = false
otherAddons.IIFAitemsListName = "IIFA_GUI_ListHolder"
otherAddons.IIFAitemsListEntryPre = "IIFA_ListItem_"
otherAddons.IIFAitemsListEntryPrePattern = otherAddons.IIFAitemsListEntryPre .. "%d"
--External addon constants
otherAddons.IIFAaddonCallName = "IIfA"
--Possible external addon call names
otherAddons.possibleExternalAddonCalls = {
    [1] = otherAddons.IIFAaddonCallName
}
--For the addon ItemCooldownTracker
otherAddons.ItemCooldownTrackerActive = false
--For the libarry LibCharacterKnowledge
otherAddons.libCharacterKnowledgeActive = false

--The recipe addons which are supported by FCOIS
FCOIS_RECIPE_ADDON_SOUSCHEF = 1
FCOIS_RECIPE_ADDON_CSFAI    = 2
FCOIS_RECIPE_ADDON_LIBCHARACTERKNOWLEDGE = 3
otherAddons.recipeAddonsSupported = {
    [FCOIS_RECIPE_ADDON_SOUSCHEF]   = "SousChef",
    [FCOIS_RECIPE_ADDON_CSFAI]      = "CraftStoreFixedAndImproved",
    [FCOIS_RECIPE_ADDON_LIBCHARACTERKNOWLEDGE] = "LibCharacterKnowledge",
}

--The research addons which are supported by FCOIS
FCOIS_RESEARCH_ADDON_ESO_STANDARD       = 1
FCOIS_RESEARCH_ADDON_CSFAI              = 2
FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT  = 3
otherAddons.researchAddonsSupported = {
    [FCOIS_RESEARCH_ADDON_ESO_STANDARD]         = "ESO Standard",
    [FCOIS_RESEARCH_ADDON_CSFAI]                = "CraftStoreFixedAndImproved",
    [FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT]    = "ResearchAssistant",
}

--The sets colleciton book addons whicha re supported by FCOIS
FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD        = 1
FCOIS_SETS_COLLECTION_ADDON_LIBMULTIACCOUNTSETS = 2
otherAddons.setCollectionBookAddonsSupported = {
    [FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD]         = "ESO Standard",
    [FCOIS_SETS_COLLECTION_ADDON_LIBMULTIACCOUNTSETS]  = "LibMultiAccountSets",
}

--The motif addons supported --#308
FCOIS_MOTIF_ADDON_LIBCHARACTERKNOWLEDGE = 1
otherAddons.motifAddonsSupported = {
    [FCOIS_MOTIF_ADDON_LIBCHARACTERKNOWLEDGE] = "LibCharacterKnowledge", --#308
}


--Variables for the anti-extraction functions
FCOIS.craftingPrevention = {}
FCOIS.craftingPrevention.extractSlot = nil
FCOIS.craftingPrevention.extractWhereAreWe = nil

FCOIS.ZOControlVars = {}
local ctrlVars = FCOIS.ZOControlVars

local listStr           = "List"
local contentsStr       = "Contents"
local backpackStr       = "Backpack"
local inventoryStr      = "Inventory"
local menuBarButtonStr  = "MenuBarButton%s"
local tabsButtonStr     = "TabsButton%s"

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
ctrlVars.inventories = inventories
--Control names of ZO* standard controls etc.
ctrlVars.FCOISfilterButtonNames = {
 [FCOIS_CON_FILTER_BUTTON_LOCKDYN] 		= "ZO_PlayerInventory_FilterButton1",
 [FCOIS_CON_FILTER_BUTTON_GEARSETS] 	= "ZO_PlayerInventory_FilterButton2",
 [FCOIS_CON_FILTER_BUTTON_RESDECIMP] 	= "ZO_PlayerInventory_FilterButton3",
 [FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]	= "ZO_PlayerInventory_FilterButton4",
}
ctrlVars.playerInventory                = PLAYER_INVENTORY
ctrlVars.playerInventoryInvs            = ctrlVars.playerInventory.inventories
ctrlVars.invSceneName                   = "inventory"
ctrlVars.INVENTORY_MANAGER              = ZO_InventoryManager
ctrlVars.INV				            = ZO_PlayerInventory
ctrlVars.INV_NAME					    = ctrlVars.INV:GetName()
ctrlVars.BACKPACK_LIST 				    = GetControl(ctrlVars.INV, listStr) -- ZO_PlayerInventoryList
ctrlVars.BACKPACK_BAG 				    = GetControl(ctrlVars.BACKPACK_LIST, contentsStr) -- ZO_PlayerInventoryListContents
ctrlVars.INV_MENUBAR_BUTTON_ITEMS	    = GetControl(ctrlVars.INV, strformat(menuBarButtonStr, "1")) --ZO_PlayerInventoryMenuBarButton1
ctrlVars.INV_MENUBAR_BUTTON_CRAFTBAG    = GetControl(ctrlVars.INV, strformat(menuBarButtonStr, "2")) --ZO_PlayerInventoryMenuBarButton2
ctrlVars.INV_MENUBAR_BUTTON_CURRENCIES  = GetControl(ctrlVars.INV, strformat(menuBarButtonStr, "3")) --ZO_PlayerInventoryMenuBarButton3
ctrlVars.INV_MENUBAR_BUTTON_QUESTS      = GetControl(ctrlVars.INV, strformat(menuBarButtonStr, "4")) --ZO_PlayerInventoryMenuBarButton4
ctrlVars.INV_MENUBAR_BUTTON_QUICKSLOTS  = GetControl(ctrlVars.INV, strformat(menuBarButtonStr, "5")) --ZO_PlayerInventoryMenuBarButton5
ctrlVars.BACKPACK 		    		    = GetControl(ctrlVars.INV, backpackStr) --ZO_PlayerInventoryBackpack

ctrlVars.companionInvSceneName          = "companionCharacterKeyboard"
ctrlVars.COMPANION_INV				    = COMPANION_EQUIPMENT_KEYBOARD
ctrlVars.COMPANION_INV_CONTROL		    = ctrlVars.COMPANION_INV.control
ctrlVars.COMPANION_INV_NAME			    = ctrlVars.COMPANION_INV_CONTROL:GetName()
ctrlVars.COMPANION_INV_LIST             = ctrlVars.COMPANION_INV.list
ctrlVars.COMPANION_INV_FRAGMENT         = COMPANION_EQUIPMENT_KEYBOARD_FRAGMENT
ctrlVars.COMPANION_CHARACTER_FRAGMENT   = COMPANION_CHARACTER_WINDOW_FRAGMENT
ctrlVars.COMPANION_CHARACTER            = ZO_CompanionCharacterWindow_Keyboard_TopLevel
ctrlVars.COMPANION_CHARACTER_NAME       = ctrlVars.COMPANION_CHARACTER:GetName()
ctrlVars.COMPANION_CHARACTER_EQUIPMENT_SLOTS_NAME = "ZO_CompanionCharacterWindow_Keyboard_TopLevelEquipmentSlots"
--ZO_CompanionEquipment_Panel_Keyboard

ctrlVars.CRAFTBAG					= ZO_CraftBag
ctrlVars.CRAFTBAG_LIST 			    = GetControl(ctrlVars.CRAFTBAG, listStr) -- ZO_CraftBagList
ctrlVars.CRAFTBAG_NAME				= ctrlVars.CRAFTBAG:GetName()
ctrlVars.CRAFTBAG_BAG				= GetControl(ctrlVars.CRAFTBAG_LIST, contentsStr) -- ZO_CraftBagListContents
ctrlVars.CRAFT_BAG_FRAGMENT         = CRAFT_BAG_FRAGMENT
ctrlVars.STORE				        = ZO_StoreWindow
ctrlVars.STORE_NAME                 = ctrlVars.STORE:GetName()
ctrlVars.VENDOR_SELL				= GetControl(ctrlVars.STORE, "ListSellToVendorArea") --ZO_StoreWindowListSellToVendorArea
ctrlVars.vendorSceneName            = "store"
--ctrlVars.VENDOR_SELL_NAME			= ctrlVars.VENDOR_SELL:GetName()
--> The following 4 controls/buttons & the depending table entries will be known first as the vendor gets opened the first time.
--> So they will be re-assigned within EVENT_OPEN_STORE in src/FCOIS_events.lua, function "FCOItemSaver_Open_Store()"
ctrlVars.VENDOR_MENUBAR_BUTTON_BUY       = GetControl(ctrlVars.STORE, strformat(menuBarButtonStr, "1")) -- ZO_StoreWindowMenuBarButton1
ctrlVars.VENDOR_MENUBAR_BUTTON_SELL      = GetControl(ctrlVars.STORE, strformat(menuBarButtonStr, "2")) -- ZO_StoreWindowMenuBarButton2
ctrlVars.VENDOR_MENUBAR_BUTTON_BUYBACK   = GetControl(ctrlVars.STORE, strformat(menuBarButtonStr, "3")) -- ZO_StoreWindowMenuBarButton3
ctrlVars.VENDOR_MENUBAR_BUTTON_REPAIR    = GetControl(ctrlVars.STORE, strformat(menuBarButtonStr, "4")) -- ZO_StoreWindowMenuBarButton4
ctrlVars.vendorPanelMainMenuButtonControlSets = {
    [FCOIS_CON_VENDOR_TYPE_NORMAL_NPC]  = {}, --4 buttons by default
    [FCOIS_CON_VENDOR_TYPE_PORTABLE]    = {}, --2 buttons by default
}
ctrlVars.STORE_BUY_BACK              = ZO_BuyBack
ctrlVars.STORE_BUY_BACK_NAME         = ctrlVars.STORE_BUY_BACK:GetName()
ctrlVars.STORE_BUY_BACK_LIST         = GetControl(ctrlVars.STORE_BUY_BACK, listStr) -- ZO_BuyBackList
--ctrlVars.STORE_BUY_BACK_LIST_BAG     = ZO_BuyBackListContents
ctrlVars.VENDOR_MAINMENU_BUTTON_BAR  = ""
--ctrlVars.FENCE						= ZO_Fence_Keyboard_WindowMenu
ctrlVars.FENCE_MANAGER               = FENCE_MANAGER
ctrlVars.FENCE_SCENE_NAME            = "fence_keyboard"
ctrlVars.REPAIR                      = ZO_RepairWindow
ctrlVars.REPAIR_NAME                 = ctrlVars.REPAIR:GetName()
ctrlVars.REPAIR_LIST				= GetControl(ctrlVars.REPAIR, listStr) -- ZO_RepairWindowList
ctrlVars.REPAIR_LIST_BAG 		    = GetControl(ctrlVars.REPAIR_LIST, contentsStr) -- ZO_RepairWindowListContents
ctrlVars.BANK_INV					= ZO_PlayerBank
ctrlVars.BANK_INV_NAME				= ctrlVars.BANK_INV:GetName()
ctrlVars.BANK			    		= GetControl(ctrlVars.BANK_INV, backpackStr) -- ZO_PlayerBankBackpack
ctrlVars.BANK_BAG		    		= GetControl(ctrlVars.BANK, contentsStr)
ctrlVars.BANK_MENUBAR_BUTTON_WITHDRAW	= GetControl(ctrlVars.BANK_INV, strformat(menuBarButtonStr, "1")) -- ZO_PlayerBankMenuBarButton1
ctrlVars.BANK_MENUBAR_BUTTON_DEPOSIT = GetControl(ctrlVars.BANK_INV, strformat(menuBarButtonStr, "2")) -- ZO_PlayerBankMenuBarButton2
ctrlVars.bankSceneName				= "bank"
ctrlVars.BANK_FRAGMENT              = BANK_FRAGMENT
ctrlVars.GUILD_BANK_INV 	    	= ZO_GuildBank
ctrlVars.GUILD_BANK_INV_NAME		= ctrlVars.GUILD_BANK_INV:GetName()
ctrlVars.GUILD_BANK 	    		= GetControl(ctrlVars.GUILD_BANK_INV, backpackStr) -- ZO_GuildBankBackpack
ctrlVars.GUILD_BANK_BAG    		    = GetControl(ctrlVars.GUILD_BANK, contentsStr) --ZO_GuildBankBackpackContents
ctrlVars.GUILD_BANK_MENUBAR_BUTTON_WITHDRAW	= GetControl(ctrlVars.GUILD_BANK_INV, strformat(menuBarButtonStr, "1")) -- ZO_GuildBankMenuBarButton1
ctrlVars.GUILD_BANK_MENUBAR_BUTTON_DEPOSIT = GetControl(ctrlVars.GUILD_BANK_INV, strformat(menuBarButtonStr, "2")) -- ZO_GuildBankMenuBarButton2
ctrlVars.guildBankSceneName		    = "guildBank"
ctrlVars.guildBankGamepadSceneName	= "gamepad_guild_bank"
ctrlVars.GUILD_STORE_KEYBOARD	    = TRADING_HOUSE
ctrlVars.GUILD_STORE				= ZO_TradingHouse
ctrlVars.GUILD_STORE_SCENE          = TRADING_HOUSE_SCENE
ctrlVars.tradingHouseSceneName	    = "tradinghouse"
------------------------------------------------------------------------------------------------------------------------
--2019-01-26: Support for API 100025 and 100026 controls!
ctrlVars.GUILD_STORE_SELL_SLOT	= GetControl(ctrlVars.GUILD_STORE, "PostItemPaneFormInfo") -- ZO_TradingHousePostItemPaneFormInfo
ctrlVars.GUILD_STORE_SELL_SLOT_NAME	= ctrlVars.GUILD_STORE_SELL_SLOT:GetName()
ctrlVars.GUILD_STORE_SELL_SLOT_ITEM	= GetControl(ctrlVars.GUILD_STORE_SELL_SLOT, "Item") -- ZO_TradingHousePostItemPaneFormInfoItem
------------------------------------------------------------------------------------------------------------------------
ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH = GetControl(ctrlVars.GUILD_STORE, strformat(menuBarButtonStr, "1")) -- ZO_TradingHouseMenuBarButton1
ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SEARCH_NAME = "ZO_TradingHouseMenuBarButton1"
ctrlVars.GUILD_STORE_MENUBAR_BUTTON_SELL = GetControl(ctrlVars.GUILD_STORE, strformat(menuBarButtonStr, "2")) -- ZO_TradingHouseMenuBarButton2
ctrlVars.GUILD_STORE_MENUBAR_BUTTON_LIST = GetControl(ctrlVars.GUILD_STORE, strformat(menuBarButtonStr, "3")) -- ZO_TradingHouseMenuBarButton3
ctrlVars.SMITHING                   = SMITHING
local smithingCtrl = ctrlVars.SMITHING
local refinementPanel = smithingCtrl.refinementPanel
local deconstructionPanel = smithingCtrl.deconstructionPanel
local improvementPanel = smithingCtrl.improvementPanel
local researchPanel = smithingCtrl.researchPanel
ctrlVars.SMITHING_CLASS             = ZO_Smithing
ctrlVars.SMITHING_PANEL             = ZO_SmithingTopLevel
ctrlVars.CRAFTING_CREATION_PANEL    = GetControl(ctrlVars.SMITHING_PANEL, "CreationPanel") -- ZO_SmithingTopLevelCreationPanel
ctrlVars.DECONSTRUCTION_PANEL	    = GetControl(ctrlVars.SMITHING_PANEL, "DeconstructionPanel") -- ZO_SmithingTopLevelDeconstructionPanel
ctrlVars.DECONSTRUCTION_INV		    = GetControl(ctrlVars.DECONSTRUCTION_PANEL, inventoryStr) -- ZO_SmithingTopLevelDeconstructionPanelInventory
ctrlVars.DECONSTRUCTION_INV_NAME	= ctrlVars.DECONSTRUCTION_INV:GetName()
ctrlVars.DECONSTRUCTION    		    = GetControl(ctrlVars.DECONSTRUCTION_INV, backpackStr) -- ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack
ctrlVars.DECONSTRUCTION_BAG 		= GetControl(ctrlVars.DECONSTRUCTION, contentsStr) -- ZO_SmithingTopLevelDeconstructionPanelInventoryBackpackContents
ctrlVars.DECONSTRUCTION_SLOT 		= GetControl(ctrlVars.DECONSTRUCTION_PANEL, "SlotContainerExtractionSlot") --ZO_SmithingTopLevelDeconstructionPanelSlotContainerExtractionSlot
ctrlVars.DECONSTRUCTION_BUTTON_ARMOR   = GetControl(ctrlVars.DECONSTRUCTION_INV, strformat(tabsButtonStr, "1")) --ZO_SmithingTopLevelDeconstructionPanelInventoryTabsButton1
ctrlVars.DECONSTRUCTION_BUTTON_WEAPONS = GetControl(ctrlVars.DECONSTRUCTION_INV, strformat(tabsButtonStr, "2")) --ZO_SmithingTopLevelDeconstructionPanelInventoryTabsButton2
--ctrlVars.SMITHING_MENUBAR_BUTTON_DECONSTRUCTION 		= ZO_SmithingTopLevelModeMenuBarButton3
-- -v- #202 UniversalDeconstruction - API101033 "Ascending Tide" added via universal deconstruction NPC "Giladil"
local universalDeconInv, universalDeconstructionPanel
ctrlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL = UNIVERSAL_DECONSTRUCTION
universalDeconstructionPanel = ctrlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL.deconstructionPanel
ctrlVars.UNIVERSAL_DECONSTRUCTION_BASE = ZO_UniversalDeconstructionTopLevel_Keyboard
ctrlVars.UNIVERSAL_DECONSTRUCTION_PANEL = GetControl(ctrlVars.UNIVERSAL_DECONSTRUCTION_BASE, "Panel") ---ZO_UniversalDeconstructionTopLevel_KeyboardPanel
ctrlVars.UNIVERSAL_DECONSTRUCTION_INV = GetControl(ctrlVars.UNIVERSAL_DECONSTRUCTION_PANEL, inventoryStr) ---ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventory
universalDeconInv = ctrlVars.UNIVERSAL_DECONSTRUCTION_INV
--ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_LIST  = universalDeconInv.list -> not existing!
ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_NAME	= universalDeconInv:GetName()
ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK = GetControl(universalDeconInv, backpackStr) -- ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryBackpack
ctrlVars.UNIVERSAL_DECONSTRUCTION_BAG 		= GetControl(ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK, contentsStr) -- ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryBackpackContents
ctrlVars.UNIVERSAL_DECONSTRUCTION_SLOT 		= GetControl(ctrlVars.UNIVERSAL_DECONSTRUCTION_PANEL, "SlotContainerExtractionSlot") --ZO_UniversalDeconstructionTopLevel_KeyboardPanelSlotContainerExtractionSlot
ctrlVars.UNIVERSAL_DECONSTRUCTION_MENUBAR_TABS = GetControl(universalDeconInv, "Tabs") --ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryTabs
--ctrlVars.UNIVERSAL_DECONSTRUCTION_BUTTON_ENCHANTING = GetControl(universalDeconInv, strformat(tabsButtonStr, "1")) --ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryTabsButton1
--ctrlVars.UNIVERSAL_DECONSTRUCTION_BUTTON_JEWELRY = GetControl(universalDeconInv, strformat(tabsButtonStr, "2")) --ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryTabsButton2
--ctrlVars.UNIVERSAL_DECONSTRUCTION_BUTTON_ARMOR = GetControl(universalDeconInv, strformat(tabsButtonStr, "3")) --ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryTabsButton3
--ctrlVars.UNIVERSAL_DECONSTRUCTION_BUTTON_WEAPONS = GetControl(universalDeconInv, strformat(tabsButtonStr, "4")) --ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryTabsButton4
--ctrlVars.UNIVERSAL_DECONSTRUCTION_BUTTON_ALL = GetControl(universalDeconInv, strformat(tabsButtonStr, "5")) --ZO_UniversalDeconstructionTopLevel_KeyboardPanelInventoryTabsButton5
ctrlVars.UNIVERSAL_DECONSTRUCTON_SCENE = UNIVERSAL_DECONSTRUCTION_KEYBOARD_SCENE
-- -^- #202
ctrlVars.REFINEMENT_PANEL		    = GetControl(ctrlVars.SMITHING_PANEL, "RefinementPanel") -- ZO_SmithingTopLevelRefinementPanel
ctrlVars.REFINEMENT_INV			    = GetControl(ctrlVars.REFINEMENT_PANEL, inventoryStr) -- ZO_SmithingTopLevelRefinementPanelInventory
ctrlVars.REFINEMENT_INV_NAME		= ctrlVars.REFINEMENT_INV:GetName()
ctrlVars.REFINEMENT    			    = GetControl(ctrlVars.REFINEMENT_INV, backpackStr) -- ZO_SmithingTopLevelRefinementPanelInventoryBackpack
ctrlVars.REFINEMENT_BAG 			= GetControl(ctrlVars.REFINEMENT, contentsStr) -- ZO_SmithingTopLevelRefinementPanelInventoryBackpackContents
ctrlVars.REFINEMENT_SLOT            = GetControl(ctrlVars.REFINEMENT_PANEL, "SlotContainerExtractionSlot") -- ZO_SmithingTopLevelRefinementPanelSlotContainerExtractionSlot
ctrlVars.IMPROVEMENT_PANEL          = GetControl(ctrlVars.SMITHING_PANEL, "ImprovementPanel") --ZO_SmithingTopLevelImprovementPanel
ctrlVars.IMPROVEMENT_INV  			= GetControl(ctrlVars.IMPROVEMENT_PANEL, inventoryStr) --ZO_SmithingTopLevelImprovementPanelInventory
ctrlVars.IMPROVEMENT_INV_NAME		= ctrlVars.IMPROVEMENT_INV:GetName()
ctrlVars.IMPROVEMENT    			= GetControl(ctrlVars.IMPROVEMENT_INV, backpackStr) --ZO_SmithingTopLevelImprovementPanelInventoryBackpack
ctrlVars.IMPROVEMENT_BAG  			= GetControl(ctrlVars.IMPROVEMENT, contentsStr) --ZO_SmithingTopLevelImprovementPanelInventoryBackpackContents
ctrlVars.IMPROVEMENT_BOOSTER_CONTAINER = GetControl(ctrlVars.IMPROVEMENT_PANEL, "BoosterContainer") --ZO_SmithingTopLevelImprovementPanelBoosterContainer
ctrlVars.IMPROVEMENT_SLOT 			= GetControl(ctrlVars.IMPROVEMENT_PANEL, "SlotContainerImprovementSlot") --ZO_SmithingTopLevelImprovementPanelSlotContainerImprovementSlot
ctrlVars.IMPROVEMENT_BUTTON_ARMOR   = GetControl(ctrlVars.IMPROVEMENT_INV, strformat(tabsButtonStr, "1")) --ZO_SmithingTopLevelImprovementPanelInventoryTabsButton1
ctrlVars.IMPROVEMENT_BUTTON_WEAPONS = GetControl(ctrlVars.IMPROVEMENT_INV, strformat(tabsButtonStr, "2")) --ZO_SmithingTopLevelImprovementPanelInventoryTabsButton2
--ctrlVars.SMITHING_MENUBAR_BUTTON_IMPROVEMENT 			= ZO_SmithingTopLevelModeMenuBarButton4
ctrlVars.RESEARCH    				= GetControl(ctrlVars.SMITHING_PANEL, "ResearchPanel") --ZO_SmithingTopLevelResearchPanel
ctrlVars.RESEARCH_NAME 				= ctrlVars.RESEARCH:GetName()
ctrlVars.RESEARCH_SELECT            = SMITHING_RESEARCH_SELECT
ctrlVars.LIST_DIALOG1               = ZO_ListDialog1
ctrlVars.ZODialog1                  = ZO_Dialog1
ctrlVars.RESEARCH_POPUP_TOP_DIVIDER       = GetControl(ctrlVars.LIST_DIALOG1, "Divider") --ZO_ListDialog1Divider
ctrlVars.RESEARCH_POPUP_TOP_DIVIDER_NAME  = ctrlVars.RESEARCH_POPUP_TOP_DIVIDER:GetName()
ctrlVars.LIST_DIALOG 	    		= GetControl(ctrlVars.LIST_DIALOG1, listStr) --ZO_ListDialog1List
ctrlVars.DIALOG_SPLIT_STACK_NAME    = "SPLIT_STACK"
ctrlVars.MAIL_SEND					= MAIL_SEND
ctrlVars.MAIL_SEND_SCENE            = MAIL_SEND_SCENE
ctrlVars.MAIL_SEND_NAME			    = ctrlVars.MAIL_SEND.control:GetName()
ctrlVars.mailSendSceneName		    = "mailSend"
ctrlVars.MAIL_SEND_ATTACHMENT_SLOTS = ctrlVars.MAIL_SEND.attachmentSlots
--ctrlVars.MAIL_INBOX				= ZO_MailInbox
ctrlVars.MAIL_ATTACHMENTS			= ctrlVars.MAIL_SEND.attachmentSlots
--ctrlVars.MAIL_MENUBAR_BUTTON_SEND  = ZO_MainMenuSceneGroupBarButton2
ctrlVars.PLAYER_TRADE				= TRADE
ctrlVars.PLAYER_TRADE_WINDOW        = TRADE_WINDOW
--ctrlVars.PLAYER_TRADE_NAME			= ctrlVars.PLAYER_TRADE.control:GetName()
ctrlVars.PLAYER_TRADE_ATTACHMENTS   = ctrlVars.PLAYER_TRADE.Columns[TRADE_ME]
ctrlVars.ENCHANTING                 = ENCHANTING
local enchanting =  ctrlVars.ENCHANTING
ctrlVars.ENCHANTING_CLASS    		= ZO_Enchanting
ctrlVars.ENCHANTING_PANEL           = ZO_EnchantingTopLevel
ctrlVars.ENCHANTING_INV             = GetControl(ctrlVars.ENCHANTING_PANEL, inventoryStr) --ZO_EnchantingTopLevelInventory
ctrlVars.ENCHANTING_INV_NAME        = ctrlVars.ENCHANTING_INV:GetName()
ctrlVars.ENCHANTING_STATION		    = GetControl(ctrlVars.ENCHANTING_INV, backpackStr) --ZO_EnchantingTopLevelInventoryBackpack
ctrlVars.ENCHANTING_STATION_NAME	= ctrlVars.ENCHANTING_STATION:GetName()
ctrlVars.ENCHANTING_STATION_BAG 	= GetControl(ctrlVars.ENCHANTING_STATION, contentsStr) --ZO_EnchantingTopLevelInventoryBackpackContents
--ctrlVars.ENCHANTING_STATION_MENUBAR_BUTTON_CREATION    = ZO_EnchantingTopLevelModeMenuBarButton1
--ctrlVars.ENCHANTING_STATION_MENUBAR_BUTTON_EXTRACTION  = ZO_EnchantingTopLevelModeMenuBarButton2
ctrlVars.ENCHANTING_RUNE_CONTAINER	= GetControl(ctrlVars.ENCHANTING_PANEL, "RuneSlotContainer") --ZO_EnchantingTopLevelRuneSlotContainer
ctrlVars.ENCHANTING_RUNE_CONTAINER_NAME	= ctrlVars.ENCHANTING_RUNE_CONTAINER:GetName()
ctrlVars.ENCHANTING_EXTRACTION_SLOT_CONTAINER  = GetControl(ctrlVars.ENCHANTING_PANEL, "ExtractionSlotContainer") --ZO_EnchantingTopLevelExtractionSlotContainer
ctrlVars.ENCHANTING_EXTRACTION_SLOT_CONTAINER_NAME  = ctrlVars.ENCHANTING_EXTRACTION_SLOT_CONTAINER:GetName()
ctrlVars.ENCHANTING_EXTRACTION_SLOT	    = GetControl(ctrlVars.ENCHANTING_EXTRACTION_SLOT_CONTAINER, "ExtractionSlot") --ZO_EnchantingTopLevelExtractionSlotContainerExtractionSlot
ctrlVars.ENCHANTING_EXTRACTION_SLOT_NAME    = ctrlVars.ENCHANTING_EXTRACTION_SLOT:GetName()
ctrlVars.ENCHANTING_RUNE_CONTAINER_POTENCY  = GetControl(ctrlVars.ENCHANTING_RUNE_CONTAINER, "PotencyRune") --ZO_EnchantingTopLevelRuneSlotContainerPotencyRune
ctrlVars.ENCHANTING_RUNE_CONTAINER_ESSENCE  = GetControl(ctrlVars.ENCHANTING_RUNE_CONTAINER, "EssenceRune") --ZO_EnchantingTopLevelRuneSlotContainerEssenceRune
ctrlVars.ENCHANTING_RUNE_CONTAINER_ASPECT   = GetControl(ctrlVars.ENCHANTING_RUNE_CONTAINER, "AspectRune") --ZO_EnchantingTopLevelRuneSlotContainerAspectRune
ctrlVars.ENCHANTING_APPLY_ENCHANT           = APPLY_ENCHANT
ctrlVars.ALCHEMY                            = ALCHEMY
ctrlVars.ALCHEMY_CLASS    		            = ZO_Alchemy
ctrlVars.ALCHEMY_PANEL                      = ctrlVars.ALCHEMY.control --ZO_AlchemyTopLevel
ctrlVars.ALCHEMY_INV				        = GetControl(ctrlVars.ALCHEMY_PANEL, inventoryStr) --ZO_AlchemyTopLevelInventory
ctrlVars.ALCHEMY_INV_NAME			        = ctrlVars.ALCHEMY_INV:GetName()
ctrlVars.ALCHEMY_STATION			        = GetControl(ctrlVars.ALCHEMY_INV, backpackStr) --ZO_AlchemyTopLevelInventoryBackpack
ctrlVars.ALCHEMY_STATION_NAME		        = ctrlVars.ALCHEMY_STATION:GetName()
ctrlVars.ALCHEMY_STATION_BAG		        = GetControl(ctrlVars.ALCHEMY_STATION, contentsStr) --ZO_AlchemyTopLevelInventoryBackpackContents
ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_CREATION    = GetControl(ctrlVars.ALCHEMY_PANEL, "Mode" .. strformat(menuBarButtonStr, "1")) --ZO_AlchemyTopLevelModeMenuBarButton1
ctrlVars.ALCHEMY_STATION_MENUBAR_BUTTON_POTIONMAKER = GetControl(ctrlVars.ALCHEMY_PANEL, "Mode" .. strformat(menuBarButtonStr, "2")) --ZO_AlchemyTopLevelModeMenuBarButton2
ctrlVars.ALCHEMY_SLOT_CONTAINER             = GetControl(ctrlVars.ALCHEMY_PANEL, "SlotContainer") --ZO_AlchemyTopLevelSlotContainer
ctrlVars.ALCHEMY_SLOT_CONTAINER_NAME        = ctrlVars.ALCHEMY_SLOT_CONTAINER:GetName()
ctrlVars.ALCHEMY_SOLVENT_SLOT               = GetControl(ctrlVars.ALCHEMY_SLOT_CONTAINER, "SolventSlot") --ZO_AlchemyTopLevelSlotContainerSolventSlot
ctrlVars.ALCHEMY_REAGENT_SLOT_NAME_PREFIX   = ctrlVars.ALCHEMY_SLOT_CONTAINER_NAME .. "ReagentSlot" --ZO_AlchemyTopLevelSlotContainerReagentSlot (for ZO_AlchemyTopLevelSlotContainerReagentSlot1 to 3)
ctrlVars.PROVISIONER                        = PROVISIONER
ctrlVars.PROVISIONER_PANEL                  = ctrlVars.PROVISIONER.control
local quickslotKeyboard                     = QUICKSLOT_KEYBOARD
ctrlVars.QUICKSLOT_KEYBOARD                 = quickslotKeyboard
local quickslot                             = (quickslotKeyboard ~= nil and quickslotKeyboard.control) or ZO_QuickSlot
ctrlVars.QUICKSLOT = quickslot
ctrlVars.QUICKSLOT_WINDOW                   = (quickslotKeyboard ~= nil and quickslotKeyboard) or QUICKSLOT_WINDOW
ctrlVars.QUICKSLOT_NAME                     = quickslot:GetName()
ctrlVars.QUICKSLOT_CIRCLE  		            = (quickslotKeyboard ~= nil and quickslotKeyboard.wheelControl) or GetControl(ctrlVars.QUICKSLOT, "Circle") --ZO_QuickSlotCircle
ctrlVars.QUICKSLOT_LIST			            = (quickslotKeyboard ~= nil and quickslotKeyboard.list) or GetControl(quickslot, listStr) --ZO_QuickSlotList
ctrlVars.QUICKSLOT_WHEEL_FRAGMENT_NAME      = "" --KEYBOARD_QUICKSLOT_CIRCLE_FRAGMENT
ctrlVars.DestroyItemDialog    		        = ESO_Dialogs["DESTROY_ITEM_PROMPT"]
ctrlVars.RepairKits                         = REPAIR_KITS
ctrlVars.RepairItemDialog                   = ctrlVars.LIST_DIALOG1 --ZO_ListDialog1
ctrlVars.RepairItemDialogName    	        = "REPAIR_ITEM"
ctrlVars.RepairItemDialogTitle              = SI_REPAIR_KIT_TITLE
ctrlVars.EnchantApply                       = APPLY_ENCHANT
ctrlVars.EnchantItemDialog                  = ctrlVars.LIST_DIALOG1 --ZO_ListDialog1
ctrlVars.EnchantItemDialogName    	        = "ENCHANTING"
ctrlVars.EnchantItemDialogTitle              = SI_ENCHANT_TITLE
ctrlVars.CHARACTER					        = ZO_Character
ctrlVars.CHARACTER_NAME 			        = ctrlVars.CHARACTER:GetName()
ctrlVars.CHARACTER_EQUIPMENT_SLOTS_NAME	    = "ZO_CharacterEquipmentSlots"

ctrlVars.PLAYER_PROGRESS_BAR                = ZO_PlayerProgress
ctrlVars.COMPANION_PROGRESS_BAR             = ZO_CompanionProgress_Keyboard_TopLevel

ctrlVars.CONTAINER_LOOT_LIST			    = ZO_LootAlphaContainerList
ctrlVars.CONTAINER_LOOT_LIST_CONTENTS       = GetControl(ctrlVars.CONTAINER_LOOT_LIST, "Contents")
ctrlVars.CONTAINER_LOOT_LIST_CONTENTS_NAME  = ctrlVars.CONTAINER_LOOT_LIST_CONTENTS:GetName()
--Transmutation / Retrait
if FCOIS.APIversion >= 100033 then
    --Markarth or newer
    ctrlVars.RETRAIT_KEYBOARD               = ZO_RETRAIT_KEYBOARD
    ctrlVars.RETRAIT_STATION_KEYBOARD       = ZO_RETRAIT_STATION_KEYBOARD
    ctrlVars.RETRAIT_KEYBOARD_INTERACT_SCENE = ctrlVars.RETRAIT_STATION_KEYBOARD.interactScene
    ctrlVars.RETRAIT_RETRAIT_PANEL	        = ctrlVars.RETRAIT_KEYBOARD
--[[
else
    --Stonethorn or older
    ctrlVars.RETRAIT_KEYBOARD               = ZO_RETRAIT_STATION_KEYBOARD
    ctrlVars.RETRAIT_STATION_KEYBOARD       = ctrlVars.RETRAIT_KEYBOARD
    ctrlVars.RETRAIT_KEYBOARD_INTERACT_SCENE = ctrlVars.RETRAIT_STATION_KEYBOARD.interactScene
    ctrlVars.RETRAIT_RETRAIT_PANEL	        = ctrlVars.RETRAIT_KEYBOARD.retraitPanel
]]
end
ctrlVars.RETRAIT					    = ZO_RetraitStation_Keyboard
ctrlVars.RETRAIT_PANEL                  = ZO_RetraitStation_KeyboardTopLevelRetraitPanel
ctrlVars.RETRAIT_PANEL_NAME             = ctrlVars.RETRAIT_PANEL:GetName()
ctrlVars.RETRAIT_INV                    = GetControl(ctrlVars.RETRAIT_PANEL, inventoryStr) --ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventory
ctrlVars.RETRAIT_INV_NAME		        = ctrlVars.RETRAIT_INV:GetName()
ctrlVars.RETRAIT_LIST			        = GetControl(ctrlVars.RETRAIT_INV, backpackStr) --ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpack
ctrlVars.RETRAIT_BAG					= GetControl(ctrlVars.RETRAIT_LIST, contentsStr) --ZO_RetraitStation_KeyboardTopLevelRetraitPanelInventoryBackpackContents
--House bank storage
ctrlVars.HOUSE_BANK_INV				    = ZO_HouseBank
ctrlVars.HOUSE_BANK					    = GetControl(ctrlVars.HOUSE_BANK_INV, backpackStr) --ZO_HouseBankBackpack
ctrlVars.HOUSE_BANK_BAG				    = GetControl(ctrlVars.HOUSE_BANK, contentsStr) --ZO_HouseBankBackpackContents
ctrlVars.HOUSE_BANK_INV_NAME			= ctrlVars.HOUSE_BANK_INV:GetName()
ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_WITHDRAW	= GetControl(ctrlVars.HOUSE_BANK_INV, strformat(menuBarButtonStr, 1)) --ZO_HouseBankMenuBarButton1
ctrlVars.HOUSE_BANK_MENUBAR_BUTTON_DEPOSIT	= GetControl(ctrlVars.HOUSE_BANK_INV, strformat(menuBarButtonStr, 2)) --ZO_HouseBankMenuBarButton2
ctrlVars.houseBankSceneName             = "houseBank"
--Equipment slots
--ctrlVars.equipmentSlotsName          = "ZO_CharacterEquipmentSlots"
--Housing
ctrlVars.housingBook = HOUSING_BOOK_KEYBOARD
ctrlVars.housingBookNavigation = ctrlVars.housingBook.navigationTree
--Quest in inventory
ctrlVars.INVENTORY_QUEST_NAME        = "ZO_PlayerInventoryQuest"


--Entries with "bought" houses within:
--ctrlVars.housingBookNavigation.rootNode.children[1].children[1].data:GetReferenceId() -> returns 31 e.g. the houesId which can be used to jump to
-->collectibleId (e.g. 1090)
-->collectibleIndex (e.g. 5)
ctrlVars.ZOMenu                         = ZO_Menu
ctrlVars.mainMenuCategoryBar            = ZO_MainMenuCategoryBar


-- #202 The mapping between the filterPanelId and the universal deconstruction controls to parent and anchor to
mappingVars.panelIdToUniversalDeconstructionNPCParentData = {}
if ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES ~= nil then
    mappingVars.panelIdToUniversalDeconstructionNPCParentData = {
        [LF_SMITHING_DECONSTRUCT]   = {
            parent      = universalDeconInv,
            anchorTo    = universalDeconInv,
        },
        [LF_JEWELRY_DECONSTRUCT]   = {
            parent      = universalDeconInv,
            anchorTo    = universalDeconInv,
        },
        [LF_ENCHANTING_EXTRACTION]   = {
            parent      = universalDeconInv,
            anchorTo    = universalDeconInv,
        },
    }

    --[[
    --The NPC decon filterPanelId to inventory to update
    mappingVars.universalDeconstructionNPCFilterPanelIdToInventory = {
        [LF_ENCHANTING_EXTRACTION]  = nil, --todo
        [LF_JEWELRY_DECONSTRUCT]    = nil, --todo
        [LF_SMITHING_DECONSTRUCT]   = nil, --todo
    }
    ]]
end

--Array for the inventories data
FCOIS.inventoryVars = {}
local inventoryVars = FCOIS.inventoryVars
--The inventory controls which get hooked for the marker texture controls.
    --
    ---hookListViewSetupCallback: ---> Currently NOT used as there are special checks needed - 2021-05-25
    -- Done in file /src/FCOIS_MarkerIcons.lua -> function FCOIS.CreateTextures(whichTextures)
    ---called by file /src/FCOIS_Events.lua -> function FCOItemSaver_Loaded -> FCOIS.CreateTextures(-1)
inventoryVars.markerControlInventories = {
    --[[
    ["hookListViewSetupCallback"] = {
        --all PLAYER_INVENTORY.inventories
        --todo 20250215
        --+
        [ctrlVars.REPAIR_LIST]          = true,
        [ctrlVars.CHARACTER]            = true,
        [ctrlVars.QUICKSLOT_LIST]       = true,
        [ctrlVars.RETRAIT_LIST]         = true,
    },
    ]]
-------------------------------------------------
    ---hookScrollSetupCallback: ---> Currently used
    ---Will be done in file /src/FCOIS_Hooks.lua -> function OnScrollListRowSetupCallback
    ---called by file /src/FCOIS_Hooks.lua -> different SecurePosthooks to crafting inventories e.g.
    ---Will be used to prevent duplicate marker texture icon apply calls.
    ["hookScrollSetupCallback"] = {
        [ctrlVars.REFINEMENT]           = true,
        [ctrlVars.DECONSTRUCTION]       = true,
        [ctrlVars.IMPROVEMENT]          = true,
        [ctrlVars.ENCHANTING_STATION]   = true,
        [ctrlVars.ALCHEMY_STATION]      = true,
        [ctrlVars.UNIVERSAL_DECONSTRUCTION_INV_BACKPACK] = true, --#202
    },
}


--The mapping array for libFilter filterType to the inventory type
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
	[LF_INVENTORY_COMPANION]    	= INVENTORY_BACKPACK,
}

--The mapping table between the LibFilters filterPanelId constant and the crafting inventories
--Used in function FCOIS.GetInventoryTypeByFilterPanel()
mappingVars.libFiltersPanelIdToCraftingPanelInventory = {
    [LF_ALCHEMY_CREATION]           = ctrlVars.ALCHEMY,
    [LF_RETRAIT]                    = ctrlVars.RETRAIT_RETRAIT_PANEL,
    [LF_SMITHING_REFINE]            = refinementPanel,
    [LF_SMITHING_CREATION]          = nil,
    [LF_SMITHING_DECONSTRUCT]       = deconstructionPanel,
    [LF_SMITHING_IMPROVEMENT]       = improvementPanel,
    [LF_SMITHING_RESEARCH]          = researchPanel, --#242 Added 4 filter buttons to research panels
    [LF_SMITHING_RESEARCH_DIALOG]   = nil,
    [LF_JEWELRY_REFINE]            = refinementPanel,
    [LF_JEWELRY_CREATION]          = nil,
    [LF_JEWELRY_DECONSTRUCT]       = deconstructionPanel,
    [LF_JEWELRY_IMPROVEMENT]       = improvementPanel,
    [LF_JEWELRY_RESEARCH]          = researchPanel, --#242 Added 4 filter buttons to research panels
    [LF_JEWELRY_RESEARCH_DIALOG]   = nil,
}

--The filterPanelId to crafting table slot (extraction, deconstruction, refine, retrait, alchemy, enchanting, ...) control
mappingVars.libFiltersPanelIdToCraftingPanelSlot = {
    [LF_ALCHEMY_CREATION]           = ctrlVars.ALCHEMY_SOLVENT_SLOT, --Solvents slot is the 1st, but it will also check the additional 3 reagent slots at FCOIS_Protection, func craftPrev.GetSlottedItemBagAndSlot()
    [LF_RETRAIT]                    = ctrlVars.RETRAIT_RETRAIT_PANEL.retraitSlot,
    [LF_SMITHING_REFINE]            = refinementPanel.extractionSlot,
    [LF_SMITHING_DECONSTRUCT]       = deconstructionPanel.extractionSlot,
    [LF_SMITHING_IMPROVEMENT]       = improvementPanel.improvementSlot,
    [LF_JEWELRY_REFINE]             = refinementPanel.extractionSlot,
    [LF_JEWELRY_DECONSTRUCT]        = deconstructionPanel.extractionSlot,
    [LF_JEWELRY_IMPROVEMENT]        = improvementPanel.improvementSlot,
    [LF_ENCHANTING_CREATION]        = enchanting.runeSlots, --#284
    [LF_ENCHANTING_EXTRACTION]      = enchanting.extractionSlot, --#284
}
if ZO_UNIVERSAL_DECONSTRUCTION_FILTER_TYPES ~= nil then
    local universalDeconPanelExtractionSlot = universalDeconstructionPanel.extractionSlot
    mappingVars.libFiltersPanelIdToUniversalCraftingPanelSlot = {
        [LF_SMITHING_DECONSTRUCT]       = universalDeconPanelExtractionSlot,
        [LF_JEWELRY_DECONSTRUCT]        = universalDeconPanelExtractionSlot,
        [LF_ENCHANTING_EXTRACTION]      = universalDeconPanelExtractionSlot,
    }
end

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
local deconTextureName              = ctrlVars.DECONSTRUCTION_INV_NAME .. "_FilterButton%sTexture" --#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel
local improveTextureName            = ctrlVars.IMPROVEMENT_INV_NAME .. "_FilterButton%sTexture"
local researchTextureName           = ctrlVars.RESEARCH_NAME .. "_FilterButton%sTexture"
local researchDialogTextureName     = ctrlVars.RESEARCH_POPUP_TOP_DIVIDER_NAME .. "_FilterButton%sTexture"
local companionInvTextureName       = ctrlVars.COMPANION_INV_NAME .. "_FilterButton%sTexture"
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
    [LF_INVENTORY_COMPANION]        = companionInvTextureName,
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
FCOIS.localizationVars.lTextMarkSpecial     = {}

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
checkVars.uniqueIdItemTypes = {
    [ITEMTYPE_ARMOR]        =   true,
    [ITEMTYPE_WEAPON]       =   true,
}
--The itemtypes that are allowed to be marked with unique item IDs created by FCOIS uniqueIDs (chosen by the user in the
--settings of the unique FCOIS itemId). All not listed item types (or listed with "false") will be saved with the
--non-unique itemInstanceId
--> See FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes
--->    filled in file /src/FCOIS_DefaultSettings.lua, and then managed in file /src/FCOIS_SettingsMenu.lua

--The allowed craftskills for automatic marking of "crafted" marker icon
-->Filled in file src/FCOIS_Functions.lua, function FCOIS.RebuildAllowedCraftSkillsForCraftedMarking(craftType)
--->Using SavedVariable settings (FCOIS.settingsVars.settings.allowedCraftSkillsForCraftedMarking) for the craftskills!
----> See file src/FCOIS_SettingsMenu.lua, function FCOIS.BuildAddonMenu, "options_auto_mark_crafted_items_panel_ ..."
checkVars.craftSkillsForCraftedMarking = {}

--The crafting creation panels, or the functions to check if they are shown
FCOIS.craftingCreatePanelControlsOrFunction = {}
--Drag & drop variables
FCOIS.dragAndDropVars = {}
FCOIS.dragAndDropVars.bag	= nil
FCOIS.dragAndDropVars.slot	= nil

---Prevention variables
preventerVars._prevVarReset = "FCOIS_PreventerVariableReset_"
preventerVars.gCalledFromInternalFCOIS = false --is an API function (or other functions which could load the SavedVariables) called from FCOIS internally
preventerVars.gLocalizationDone		= false
preventerVars.KeyBindingTexts		= false
preventerVars.gKeybindingLocalizationDone = false
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
preventerVars.migrateItemMarkersCalledFromPlayerActivated = false
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
preventerVars.enchantItemActive = false
preventerVars.doNotCheckForDefaultName = false
preventerVars.universalDeconSceneHidden = false

--The event handler array for OnMouseDoubleClick, Drag&Drop, etc.
FCOIS.eventHandlers = {}

--Table to map the FCOIS.settingsVars.settings filter state to the output text identifier
mappingVars.settingsFilterStateToText = {
	[tos(FCOIS_CON_FILTER_BUTTON_STATE_GREEN)]  = "on",
    [tos(FCOIS_CON_FILTER_BUTTON_STATE_YELLOW)] = "onlyfiltered",
    [tos(FCOIS_CON_FILTER_BUTTON_STATE_RED)]    = "off",
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
    ... see below at for dynIconNr=1, numMaxDynamicIcons do
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
    --... dynamic gear will be added here by code
}

--Will both be set in function FCOIS.RebuildGearSetBaseVars() upon event_palyer_activated or changed gear icons (dynamic ones)
mappingVars.iconToNonDynamicGear = {}
mappingVars.iconToDynamicGear = {}

--Table to map gearId to iconId. Will be enhanced by the dynamic icons which are enabled to be "gear".
--by function FCOIS.rebuildGearSetBaseVars() (in /src/FCOIS_Functions.lua), in EVENT_PLAYER_ACTIVATED callback
mappingVars.gearToIcon = {
    [1] = FCOIS_CON_ICON_GEAR_1,
    [2] = FCOIS_CON_ICON_GEAR_2,
    [3] = FCOIS_CON_ICON_GEAR_3,
    [4] = FCOIS_CON_ICON_GEAR_4,
    [5] = FCOIS_CON_ICON_GEAR_5,
    --... dynamic gear will be added here by code
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

--Table to see if the icon is blocked for usage if the item is reconstructed or retraited
mappingVars.iconIsBlockedBecauseOfRetrait = {
	[FCOIS_CON_ICON_RESEARCH]       = true,
    [FCOIS_CON_ICON_INTRICATE]      = true,
	[FCOIS_CON_ICON_SELL_AT_GUILDSTORE]	= true,
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
    [FCOIS_CON_ICON_DYNAMIC_1]			= true,
    [FCOIS_CON_ICON_DYNAMIC_2]			= true,
    ... see below at for dynIconNr=1, numMaxDynamicIcons do
]]
}

--Table to map dynamicId to iconId
mappingVars.dynamicToIcon = {
--[[
    [1]			= FCOIS_CON_ICON_DYNAMIC_1,
    [2]			= FCOIS_CON_ICON_DYNAMIC_2,
    ... see below at for dynIconNr=1, numMaxDynamicIcons do
]]
}

--Table to map iconId to dynamicId
mappingVars.iconToDynamic = {
--[[
    [FCOIS_CON_ICON_DYNAMIC_1]			= 1,
    [FCOIS_CON_ICON_DYNAMIC_2]			= 2,
    ... see below at for dynIconNr=1, numMaxDynamicIcons do
]]
}

--Mapping array for icon to lock & dynamic icons filter split
mappingVars.iconToLockDyn = {
    [FCOIS_CON_ICON_LOCK	 ]  = 1,
--[[
	[FCOIS_CON_ICON_DYNAMIC_1]  = 2,
	[FCOIS_CON_ICON_DYNAMIC_2]  = 3,
    ...
]]
}
--Mapping array for lock & dynamic icons filter split to it's icon
mappingVars.lockDynToIcon = {
	[1]  =  FCOIS_CON_ICON_LOCK,
--[[
	[2]  =  FCOIS_CON_ICON_DYNAMIC_1,
	[3]  =  FCOIS_CON_ICON_DYNAMIC_2,
    ...
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

--Mapping array for disabled marker icons at the companion inventory additional inventory "flag" context menu AND at the
--normal context menus AND at the keybindings, as companion items should not be marked with these icons!
mappingVars.iconIsDisabledAtCompanion = {
    [FCOIS_CON_ICON_RESEARCH]           = true,
    [FCOIS_CON_ICON_DECONSTRUCTION]     = true,
    [FCOIS_CON_ICON_IMPROVEMENT]        = true,
--    [FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = false,
    [FCOIS_CON_ICON_INTRICATE]          = true,
}

--LibFilters filterType constants of the panels that support the "companion items" inventory filterBar button
mappingVars.isCompanionSupportedPanel = {
    [LF_INVENTORY]          = true,
    [LF_MAIL_SEND]          = true,
    [LF_TRADE]              = true,
    [LF_BANK_DEPOSIT]       = true,
    [LF_BANK_WITHDRAW]      = true,
    [LF_GUILDBANK_DEPOSIT]  = true,
    [LF_GUILDBANK_WITHDRAW] = true,
    [LF_VENDOR_SELL]        = true,
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
checkVars.ornateItemTraits = {
	[ITEM_TRAIT_TYPE_ARMOR_ORNATE]   = true,
	[ITEM_TRAIT_TYPE_JEWELRY_ORNATE] = true,
	[ITEM_TRAIT_TYPE_WEAPON_ORNATE]  = true,
}
--Table with allowed item traits for intricate items
checkVars.intricateItemTraits = {
    [ITEM_TRAIT_TYPE_ARMOR_INTRICATE]   = true,
    [ITEM_TRAIT_TYPE_WEAPON_INTRICATE]  = true,
    [ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = true,
}
--Table with allowed item types for researching
checkVars.researchableItemTypes = {
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
checkVars.setItemTypes = {
	[ITEMTYPE_ARMOR]	= true,
	[ITEMTYPE_WEAPON]	= true,
}

--Table with NOT allowed parent control names. These cannot use the FCOItemSaver right click context menu entries
--for items (in the inventories)
checkVars.notAllowedContextMenuParentControls = {
	["ZO_QuestItemsListContents"] = true,
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
--that are checked inside src/FCOIS_ContextMenus.lua, function FCOIS.MarkMe(), as an item gets marked via the right-click context menu from the inventory,
--or via a keybinding: If item is protected again it must be removed from the crafting / etc. slot again!
--This will only work for currently shown invetories where the rows/items are shown and where a refinement/deconstruction/improve/extraction slot holds items
--> See file src/FCOIS_Protection.lua, function FCOIS.craftingPrevention.IsItemProtectedAtACraftSlotNow(bagId, slotIndex)
checkVars.allowedCraftingPanelIdsForMarkerRechecks = {
	[LF_SMITHING_REFINE] 		= true,
	[LF_SMITHING_DECONSTRUCT] 	= true,
	[LF_SMITHING_IMPROVEMENT] 	= true,
	[LF_ALCHEMY_CREATION] 		= true,
	[LF_ENCHANTING_CREATION] 	= true,
	[LF_ENCHANTING_EXTRACTION] 	= true,
    [LF_RETRAIT] 	            = true,
    [LF_JEWELRY_REFINE]		    = true,
    [LF_JEWELRY_DECONSTRUCT]	= true,
    [LF_JEWELRY_IMPROVEMENT]	= true,
}

--Mapping of the character/companion character screen to the apparel control where the number of light/medium/heavy armor
--pieces worn should be shown
mappingVars.characterApparelSection = {
    [FCOIS_CON_LF_CHARACTER]           = GetControl(ctrlVars.CHARACTER,            "ApparelSectionText"),
    [FCOIS_CON_LF_COMPANION_CHARACTER] = GetControl(ctrlVars.COMPANION_CHARACTER,  "ApparelSectionText"),
}

--Mapping between equipment slot and it's name suffix
local equipmentSlotToName = {
    [EQUIP_SLOT_HEAD]           = "Head",
    [EQUIP_SLOT_SHOULDERS]      = "Shoulder",
    [EQUIP_SLOT_HAND]           = "Glove",
    [EQUIP_SLOT_LEGS]           = "Leg",
    [EQUIP_SLOT_CHEST]          = "Chest",
    [EQUIP_SLOT_WAIST]          = "Belt",
    [EQUIP_SLOT_FEET]           = "Foot",
    [EQUIP_SLOT_COSTUME]        = "Costume",
    [EQUIP_SLOT_NECK]           = "Neck",
    [EQUIP_SLOT_RING1]          = "Ring1",
    [EQUIP_SLOT_RING2]          = "Ring2",
    [EQUIP_SLOT_MAIN_HAND]      = "MainHand",
    [EQUIP_SLOT_OFF_HAND]       = "OffHand",
    [EQUIP_SLOT_POISON]         = "Poison",
    [EQUIP_SLOT_BACKUP_MAIN]    = "BackupMain",
    [EQUIP_SLOT_BACKUP_OFF]     = "BackupOff",
    [EQUIP_SLOT_BACKUP_POISON]  = "BackupPoison",
}
mappingVars.equipmentSlotToName = equipmentSlotToName

--Mapping between the equipmentType and the slot where it is placed
local equipTypeToSlot = {
    [EQUIP_TYPE_HEAD] = EQUIP_SLOT_HEAD,
    [EQUIP_TYPE_SHOULDERS] = EQUIP_SLOT_SHOULDERS,
    [EQUIP_TYPE_HAND] = EQUIP_SLOT_HAND,
    [EQUIP_TYPE_LEGS] = EQUIP_SLOT_LEGS,
    [EQUIP_TYPE_CHEST] = EQUIP_SLOT_CHEST,
    [EQUIP_TYPE_WAIST] = EQUIP_SLOT_WAIST,
    [EQUIP_TYPE_FEET] = EQUIP_SLOT_FEET,
    [EQUIP_TYPE_COSTUME] = EQUIP_SLOT_COSTUME,
    [EQUIP_TYPE_NECK] = EQUIP_SLOT_NECK,
    [EQUIP_TYPE_RING] = EQUIP_SLOT_RING1,
    [EQUIP_TYPE_ONE_HAND] = EQUIP_SLOT_MAIN_HAND,
    [EQUIP_TYPE_TWO_HAND] = EQUIP_SLOT_MAIN_HAND,
    [EQUIP_TYPE_OFF_HAND] = EQUIP_SLOT_OFF_HAND,
    [EQUIP_TYPE_POISON] = EQUIP_SLOT_POISON,
}
mappingVars.equipTypeToSlot = equipTypeToSlot

--The character and companion equipment slots
--Table with all equipment slot names which can be updated with markes for the icons
--The index is the relating slotIndex of the bag BAG_WORN!
local equipmentSlotPrefix = ctrlVars.CHARACTER_EQUIPMENT_SLOTS_NAME --"ZO_CharacterEquipmentSlots"
local equipmentSlotCompanionPrefix = ctrlVars.COMPANION_CHARACTER_EQUIPMENT_SLOTS_NAME --ZO_CompanionCharacterWindow_Keyboard_TopLevelEquipmentSlots

mappingVars.characterEquipmentSlotNameByIndex = {}
mappingVars.companionCharacterEquipmentSlotNameByIndex = {}

    --The mapping table for the character equipment slots: Speed find without string.find in EventHandlers
mappingVars.characterEquipmentSlots = {}

for equipSlot, equipSlotName in pairs(equipmentSlotToName) do
    mappingVars.characterEquipmentSlotNameByIndex[equipSlot] = equipmentSlotPrefix .. equipSlotName
    mappingVars.companionCharacterEquipmentSlotNameByIndex[equipSlot] = equipmentSlotCompanionPrefix .. equipSlotName

    mappingVars.characterEquipmentSlots[equipmentSlotPrefix .. equipSlotName] = true
    mappingVars.characterEquipmentSlots[equipmentSlotCompanionPrefix .. equipSlotName] = true
end
local characterEquipmentSlotNameByIndex = mappingVars.characterEquipmentSlotNameByIndex
local companionCharacterEquipmentSlotNameByIndex = mappingVars.companionCharacterEquipmentSlotNameByIndex

--Table with the eqipment slot control names which are armor
mappingVars.characterEquipmentArmorSlots = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_HEAD]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_CHEST]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_SHOULDERS]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_WAIST]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_LEGS]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_FEET]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_HAND]] = true,
    --Companion
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_HEAD]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_CHEST]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_SHOULDERS]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_WAIST]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_LEGS]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_FEET]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_HAND]] = true,
}

--Table with the eqipment slot control names which are weapons
mappingVars.characterEquipmentWeaponSlots = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_POISON]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_POISON]] = true,
    --Companion
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_POISON]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_POISON]] = true,
}

    --Table with the eqipment slot control names which are jewelry
mappingVars.characterEquipmentJewelrySlots = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_NECK]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = true,
    --Companion
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_NECK]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = true,
}

mappingVars.characterEquipmentRingSlots = {
    [EQUIP_SLOT_RING1] = characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1],
    [EQUIP_SLOT_RING2] = characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2],
}
mappingVars.characterCompanionEquipmentRingSlots = {
    --Companion
    [EQUIP_SLOT_RING1] = companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1],
    [EQUIP_SLOT_RING2] = companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2],
}

--Mapping table fo one ring to the other
mappingVars.equipmentJewelryRing2RingSlot = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2],
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1],
    --Companion
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2],
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1],
}

--Table with allowed control names for the character equipment weapon and offhand weapon slots
checkVars.allowedCharacterEquipmentWeaponControlNames = {
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
    --Companion
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_MAIN_HAND]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_MAIN]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
}
--Table with weapon backup slot names
checkVars.allowedCharacterEquipmentWeaponBackupControlNames = {
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
	[characterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
    --Companion
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_OFF_HAND]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_BACKUP_OFF]] = true,
}
--Table with allowed control names for the character equipment jewelry rings
checkVars.allowedCharacterEquipmentJewelryRingControlNames = {
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = true,
    [characterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = true,
    --Companion
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING1]] = true,
    [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_RING2]] = true,
}
--Table with allowed control names for the character equipment jewelry
checkVars.allowedCharacterEquipmentJewelryControlNames = mappingVars.characterEquipmentJewelrySlots

--Table with weapon and jewelry slot names for equipment checks
checkVars.equipmentSlotsNames = {
    ["no_auto_mark"] = {
		[characterEquipmentSlotNameByIndex[EQUIP_SLOT_COSTUME]] = true,
		--Companion
        [companionCharacterEquipmentSlotNameByIndex[EQUIP_SLOT_COSTUME]] = true,
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
--The item trait informatin that is not allowed for research
checkVars.itemTraitInformationNotResearchable = {
    [ITEM_TRAIT_INFORMATION_RETRAITED]      = true,
    [ITEM_TRAIT_INFORMATION_RECONSTRUCTED]  = true,
}

--The possible checkWere panels for the antiSettings reenable checks
--See file src/FCOIS_Settings.lua, function FCOIS.AutoReenableAntiSettingsCheck(checkWhere)
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
--The filter panelIds which need to be checked if anti-destroy is checked
checkVars.filterPanelIdsForAntiDestroy = {
    [LF_INVENTORY]              = true,
    [LF_BANK_WITHDRAW]          = true,
    [LF_HOUSE_BANK_WITHDRAW]    = true,
    [LF_BANK_DEPOSIT]           = true,
    [LF_GUILDBANK_DEPOSIT]      = true,
    [LF_HOUSE_BANK_DEPOSIT]     = true,
    [LF_INVENTORY_COMPANION]    = true,
    --FCOIS custom LibFilters filterPanelId
    [FCOIS_CON_LF_CHARACTER]            = true,
    [FCOIS_CON_LF_COMPANION_CHARACTER]  = true,
}

--In anti-destroy checks always set the anti-destroy settings to "on" for these panels as there might be no setting switch or other needs
checkVars.filterPanelIdsForAntiDestroySettingsAlwaysOn = {
    [LF_VENDOR_REPAIR] = true,          --check anti-destroy as there is no other setting at vendor repair
}

--In anti-destroy checks do not use the other anti-* settings a panel might have. ONLY use anti-destroy!
checkVars.filterPanelIdsForAntiDestroyDoNotUseOtherAntiSettings = {
    [LF_GUILDBANK_DEPOSIT] = true,      --use anti-destroy at the destroy item handler as anti-deposit is the wrong setting :-) -> to reflect the "flag"'s icon color state
}

--Alowed fence and launder filterypes --#299
checkVars.allowedFenceOrLaunderTypes = {
    [LF_FENCE_SELL] = true,
    [LF_FENCE_LAUNDER] = true,
}
--Allowed motifs itemTypes --#308
checkVars.allowedMotifsItemTypes = {
    [ITEMTYPE_RACIAL_STYLE_MOTIF] = true,
    [ITEMTYPE_CONTAINER] = true,
}

--BagId to SetTracker addon settings in FCOIS --#302 SetTracker support disabled with FCOOIS v2.6.1, for versions <300
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
--> Filled in function FCOIS.BuildAdditionalInventoryFlagContextMenuData(calledFromFCOISSettings)
contextMenuVars.buttonContextMenuToIconId = {}
--The index of the mapping table for context menu buttons to icon id
--> Filled in function FCOIS.BuildAdditionalInventoryFlagContextMenuData(calledFromFCOISSettings)
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
local availableCtms = contextMenuVars.availableCtms

--The self-build contextMenus (filter buttons)
FCOIS.contextMenu = {}
local fcoisContextMenu = FCOIS.contextMenu
--The context menu for the lock & dynmic icons filter button
fcoisContextMenu.LockDynFilter 	= {}
fcoisContextMenu.LockDynFilterName = availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN] .. "Filter"
fcoisContextMenu.ContextMenuLockDynFilterName = "ContextMenu" .. fcoisContextMenu.LockDynFilterName
fcoisContextMenu.LockDynFilter.bdSelectedLine = {}
--Lock & dynamic icons filter split context menu variables
contextMenuVars.LockDynFilter	= {}
contextMenuVars.LockDynFilter.maxWidth		= contextMenuVars.filterButtons.maxWidth
contextMenuVars.LockDynFilter.maxHeight		= 288 -- OLD: 288 before additional 20 dynamic icons were added
contextMenuVars.LockDynFilter.entryHeight	    = contextMenuVars.filterButtons.entryHeight
--The prefix of the LockDynFilter entries
contextMenuVars.LockDynFilter.buttonNamePrefix = availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN] .. "Filter"
--The entries in the following mapping array
contextMenuVars.LockDynFilter.buttonContextMenuToIconIdEntries = 32 -- OLD: 12 before additional 20 dynamic icons were added
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.LockDynFilter.buttonContextMenuToIconIdIndex = {}
for index=1, contextMenuVars.LockDynFilter.buttonContextMenuToIconIdEntries do
	table.insert(contextMenuVars.LockDynFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. contextMenuVars.LockDynFilter.buttonNamePrefix .. index)
end

--The context menu for the gear sets filter button
fcoisContextMenu.GearSetFilter 	= {}
fcoisContextMenu.GearSetFilterName = availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS] .. "Filter"
fcoisContextMenu.ContextMenuGearSetFilterName = "ContextMenu" .. fcoisContextMenu.GearSetFilterName
fcoisContextMenu.GearSetFilter.bdSelectedLine = {}
--Gear set filter split context menu variables
contextMenuVars.GearSetFilter	= {}
contextMenuVars.GearSetFilter.maxWidth		= contextMenuVars.filterButtons.maxWidth
contextMenuVars.GearSetFilter.maxHeight		= 144
contextMenuVars.GearSetFilter.entryHeight	    = contextMenuVars.filterButtons.entryHeight
--The prefix of the GearSetFilter entries
contextMenuVars.GearSetFilter.buttonNamePrefix = availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS] .. "Filter"
--The entries in the following mapping array
contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries = 6
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex = {}
for index=1, contextMenuVars.GearSetFilter.buttonContextMenuToIconIdEntries do
	table.insert(contextMenuVars.GearSetFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. contextMenuVars.GearSetFilter.buttonNamePrefix .. index)
end

--The context menu for the RESEARCH & DECONSTRUCTION & IMPORVEMENT filter button
fcoisContextMenu.ResDecImpFilter 	= {}
fcoisContextMenu.ResDecImpFilterName =  availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP] .. "Filter"
fcoisContextMenu.ContextMenuResDecImpFilterName = "ContextMenu" .. fcoisContextMenu.ResDecImpFilterName
fcoisContextMenu.ResDecImpFilter.bdSelectedLine = {}
--Research/Deconstruction filter split context menu variables
contextMenuVars.ResDecImpFilter	= {}
contextMenuVars.ResDecImpFilter.maxWidth      = contextMenuVars.filterButtons.maxWidth
contextMenuVars.ResDecImpFilter.maxHeight	    = 96
contextMenuVars.ResDecImpFilter.entryHeight	= contextMenuVars.filterButtons.entryHeight
--The prefix of the ResDecImpFilter entries
contextMenuVars.ResDecImpFilter.buttonNamePrefix = availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP] .. "Filter"
--The entries in the following mapping array
contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdEntries = 4
--The index of the mapping table for context menu buttons to icon id
contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdIndex = {}
for index=1, contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdEntries do
	table.insert(contextMenuVars.ResDecImpFilter.buttonContextMenuToIconIdIndex, buttonNamePrefix .. contextMenuVars.ResDecImpFilter.buttonNamePrefix .. index)
end

--The context menu for the SELL & SELL IN GUILD STORE & INTRICATE  filter button
fcoisContextMenu.SellGuildIntFilter 	= {}
fcoisContextMenu.SellGuildIntFilterName = availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] .. "Filter"
fcoisContextMenu.ContextMenuSellGuildIntFilterName = "ContextMenu" .. fcoisContextMenu.SellGuildIntFilterName
fcoisContextMenu.SellGuildIntFilter.bdSelectedLine = {}
--Sell/Guild sell/Intricate filter split context menu variables
contextMenuVars.SellGuildIntFilter	= {}
contextMenuVars.SellGuildIntFilter.maxWidth       = contextMenuVars.filterButtons.maxWidth
contextMenuVars.SellGuildIntFilter.maxHeight      = 96
contextMenuVars.SellGuildIntFilter.entryHeight    = contextMenuVars.filterButtons.entryHeight
--The prefix of the SellGuildIntFilter entries
contextMenuVars.SellGuildIntFilter.buttonNamePrefix = availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT] .. "Filter"
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
	[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]] 		= FCOIS_CON_FILTER_BUTTON_LOCKDYN,
	[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]]		= FCOIS_CON_FILTER_BUTTON_GEARSETS,
	[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]] 	    = FCOIS_CON_FILTER_BUTTON_RESDECIMP,
	[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]]	= FCOIS_CON_FILTER_BUTTON_SELLGUILDINT,
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
invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions = ctrlVars.DECONSTRUCTION_INV_NAME .. additionalFCOISInvContextmenuButtonNameString --#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel
invAddButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions = ctrlVars.IMPROVEMENT_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.alchemyTopLevelInventoryButtonAdditionalOptions = ctrlVars.ALCHEMY_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.enchantingTopLevelInventoryButtonAdditionalOptions = ctrlVars.ENCHANTING_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.craftBagInventoryButtonAdditionalOptions = ctrlVars.CRAFTBAG_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.retraitInventoryButtonAdditionalOptions = ctrlVars.RETRAIT_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.houseBankInventoryButtonAdditionalOptions = ctrlVars.HOUSE_BANK_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.companionInventoryFCOAdditionalOptionsButton = ctrlVars.COMPANION_INV_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.characterFCOAdditionalOptionsButton = ctrlVars.CHARACTER_NAME .. additionalFCOISInvContextmenuButtonNameString
invAddButtonVars.companionCharacterFCOAdditionalOptionsButton = ctrlVars.COMPANION_CHARACTER_NAME .. additionalFCOISInvContextmenuButtonNameString


--The mapping between the panel (libFilters filter ID LF_*) and the button data -> See file FCOIS_settings.lua -> function AfterSettings() for additional added data
--and file FCOIS_constants.lua at the bottom for the anchorvars for each API version.
--Entries without a parent and without "addInvButton" boolean == true will not be added again as another panel (like LF_INVENTORY) is reused for the button.
--The entry is only there to get the button's name for the functions in file "fcoisContextMenus.lua" to show/hide it.
--> To check what entries the context menu below this invokerButton will create/show check the file src/fcoisContextMenus.lua, function FCOIS.showContextMenuForAddInvButtons(invokerButton)
contextMenuVars.filterPanelIdToContextMenuButtonInvoker = {
	[LF_INVENTORY] 					= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.INV,
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,
        ["sortIndex"]     = 1,
        ["updateOtherInvokerButtonsState"] = {
            [1] = {
                filterPanel     = FCOIS_CON_LF_CHARACTER,
                requirementFunc = function() return FCOIS.IsCharacterShown() end,
            }
        },
        ["updateActivePanelDataOnShowContextMenu"] = true, --as the button is the same for LF_MAIL_SEND etc. we need to read fCOIS.gFilterWhere to get the active filterPanelId etc.
    },
    --Added with API 100015 for the crafting bags that you only got access too if you are an ESO+ subscriber
    [LF_CRAFTBAG]					= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.CRAFTBAG,
        ["name"]          = invAddButtonVars.craftBagInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 2,
    },
	[LF_MAIL_SEND] 					= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 3,
    },
	[LF_TRADE] 						= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 4,
    },
	[LF_BANK_WITHDRAW] 				= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.BANK_INV,
        ["name"]          = invAddButtonVars.playerBankWithdrawButtonAdditionalOptions,
        ["sortIndex"]     = 5,
    },
	[LF_BANK_DEPOSIT] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 6,
    },
	[LF_GUILDBANK_WITHDRAW] 		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.GUILD_BANK_INV,
        ["name"]          = invAddButtonVars.guildBankFCOWithdrawButtonAdditionalOptions,
        ["sortIndex"]     = 7,
    },
	[LF_GUILDBANK_DEPOSIT]			= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 8,
    },
    --Added with API 100022 Dragon bones: House storage, named House bank
    [LF_HOUSE_BANK_WITHDRAW]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.HOUSE_BANK_INV,
        ["name"]          = invAddButtonVars.houseBankInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 9,
    },
    [LF_HOUSE_BANK_DEPOSIT]			= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 10,
    },
	[LF_GUILDSTORE_SELL] 	 		= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 11,
    },
    [LF_VENDOR_BUY] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 12,
    },
    [LF_VENDOR_SELL] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                     --Same like inventory
        ["sortIndex"]     = 13,
    },
    [LF_VENDOR_BUYBACK] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 14,
    },
	[LF_VENDOR_REPAIR] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 15,
    },
	[LF_FENCE_SELL] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 16,
    },
	[LF_FENCE_LAUNDER] 				= {
        ["name"]          = invAddButtonVars.playerInventoryFCOAdditionalOptionsButton,                      --Same like inventory
        ["sortIndex"]     = 17,
    },
    [LF_SMITHING_REFINE]		   	= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.REFINEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 18,
    },
    [LF_SMITHING_DECONSTRUCT]  		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.DECONSTRUCTION_INV, --#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel
        ["name"]          = invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 19,
    },
    [LF_SMITHING_IMPROVEMENT]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.IMPROVEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 20,
    },
	[LF_ALCHEMY_CREATION] = {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.ALCHEMY_INV,
        ["name"]          = invAddButtonVars.alchemyTopLevelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 20,
    },
	[LF_ENCHANTING_CREATION]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.ENCHANTING_INV,
        ["name"]          = invAddButtonVars.enchantingTopLevelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 21,
        ["readCurrentActiveFilterPanelId"] = true,
    },
	[LF_ENCHANTING_EXTRACTION]		= {
        ["name"]          = invAddButtonVars.enchantingTopLevelInventoryButtonAdditionalOptions,             --Same like enchanting creation
        ["sortIndex"]     = 22,
    },
    --Added with API 100021 Clockwork city: Retrait of items
    [LF_RETRAIT]                    = {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.RETRAIT_INV,
        ["name"]          = invAddButtonVars.retraitInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 23,
    },
    --Added with API 100023 Summerset: SMITHING for jewelry
    [LF_JEWELRY_REFINE]		   	= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.REFINEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelRefinementPanelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 24,
    },
    [LF_JEWELRY_DECONSTRUCT]  		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.DECONSTRUCTION_INV, --#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel
        ["name"]          = invAddButtonVars.smithingTopLevelDeconstructionPanelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 25,
    },
    [LF_JEWELRY_IMPROVEMENT]		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.IMPROVEMENT_INV,
        ["name"]          = invAddButtonVars.smithingTopLevelImprovementPanelInventoryButtonAdditionalOptions,
        ["sortIndex"]     = 26,
    },
	[LF_INVENTORY_COMPANION] 		= {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.COMPANION_INV_CONTROL,
        ["name"]          = invAddButtonVars.companionInventoryFCOAdditionalOptionsButton,
        ["sortIndex"]     = 27,
        ["updateOtherInvokerButtonsState"] = {
            [1] = {
                filterPanel     = FCOIS_CON_LF_COMPANION_CHARACTER,
                requirementFunc = function() return FCOIS.IsCompanionCharacterShown() end,
            }
        }
    },
--======================================================================================================================
    --Special entries without LibFilters filterPanelId -> FCOIS custom filterPanels
    --> Will also be added to contextMenuVars.sortedFilterPanelIdToContextMenuButtonInvoker
    --Character
    [FCOIS_CON_LF_CHARACTER] = {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.CHARACTER,
        ["name"]          = invAddButtonVars.characterFCOAdditionalOptionsButton,
        ["filterPanelId"] = FCOIS_CON_LF_CHARACTER, --Used within function AddButton to provide the custom non-LibFilters filterPanelId to function FCOIS.ShowContextMenuForAddInvButtons
        ["updateOtherInvokerButtonsState"] = {
            [1] = {
                filterPanel     = LF_INVENTORY,
                requirementFunc = function() return FCOIS.IsInventoryShown() end,
            }
        },
        ["sortIndex"]     = 28,
    },
    --Companion character
    [FCOIS_CON_LF_COMPANION_CHARACTER] = {
        ["addInvButton"]  = true,
        ["parent"]        = ctrlVars.COMPANION_CHARACTER,
        ["name"]          = invAddButtonVars.companionCharacterFCOAdditionalOptionsButton,
        ["filterPanelId"] = FCOIS_CON_LF_COMPANION_CHARACTER, --Used within function AddButton to provide the custom non-LibFilters filterPanelId to function FCOIS.ShowContextMenuForAddInvButtons
        ["updateOtherInvokerButtonsState"] = {
            [1] = {
                filterPanel     = LF_INVENTORY_COMPANION,
                requirementFunc = function() return FCOIS.IsCompanionInventoryShown() end,
            }
        },
        ["sortIndex"]     = 29,
    },
}
--Resort the panels by their sort number attribut given
local sortedAddInvBtnInvokersNoGapIndex = {}
for filterPanelId, addInvBtnInvokerData in pairs(FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker) do
    --local typeFilterPanelId = type(filterPanelId)
    --if typeFilterPanelId == "number" then
        addInvBtnInvokerData.filterPanelId = filterPanelId
        table.insert(sortedAddInvBtnInvokersNoGapIndex, addInvBtnInvokerData)
    --else
        --Special data for non LibFilters panels, e.g. character
        -->Do not add to re-position sortIndex table as they cannot be moved via settings!
    --end
end
table.sort(sortedAddInvBtnInvokersNoGapIndex, function(a, b) return a.sortIndex < b.sortIndex  end)
contextMenuVars.sortedFilterPanelIdToContextMenuButtonInvoker = sortedAddInvBtnInvokersNoGapIndex

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
    [LF_SMITHING_DECONSTRUCT]   = ctrlVars.DECONSTRUCTION_INV_NAME .. sortByNameNameStr, --#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel
    [LF_SMITHING_IMPROVEMENT]   = ctrlVars.IMPROVEMENT_INV_NAME .. sortByNameNameStr,
    [LF_ALCHEMY_CREATION]       = ctrlVars.ALCHEMY_INV_NAME .. sortByNameNameStr,
    [LF_ENCHANTING_CREATION]    = ctrlVars.ENCHANTING_INV_NAME .. sortByNameNameStr,
    [LF_CRAFTBAG]               = ctrlVars.CRAFTBAG_NAME .. sortByNameNameStr,
    [LF_RETRAIT]                = ctrlVars.RETRAIT_INV_NAME .. sortByNameNameStr,
    [LF_HOUSE_BANK_WITHDRAW]	= ctrlVars.HOUSE_BANK_INV_NAME .. sortByNameNameStr,
    [LF_QUICKSLOT]              = ctrlVars.QUICKSLOT_NAME .. sortByNameNameStr,
    [LF_INVENTORY_COMPANION]    = ctrlVars.COMPANION_INV_NAME .. sortByNameNameStr,
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
mappingVars.maxLevel = GetMaxLevel() --50 API 101034
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
    [LF_SMITHING_RESEARCH]		= "",       --research does not show any additional "flag" button as there is no mass marking possible and the protection is neither checked. Only filters will apply! -> No shown inv list with items
    [LF_SMITHING_RESEARCH_DIALOG] = "",     --research dialog does not show any additional "flag" button as the ZO_ListDialog1 custom control won't properly work with it. Only filters will apply!
    [LF_GUILDSTORE_SELL] 	 	= buttonContextMenuSell,
    [LF_MAIL_SEND] 				= buttonContextMenuToggleAntiPrefix .."mail_",
    [LF_TRADE] 					= buttonContextMenuToggleAntiPrefix .."trade_",
    [LF_ALCHEMY_CREATION]       = buttonContextMenuToggleAntiPrefix .."alchemy_",
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
    [LF_JEWELRY_RESEARCH]		= "",       --research does not show any additional "flag" button as there is no mass marking possible and the protection is neither checked. Only filters will apply! -> No shown inv list with items
    [LF_JEWELRY_RESEARCH_DIALOG] = "",      --research dialog does not show any additional "flag" button as the ZO_ListDialog1 custom control won't properly work with it. Only filters will apply!
    [LF_INVENTORY_COMPANION]    = buttonContextMenuDestroy,
--======================================================================================================================
    --Special entries without LibFilters filterPanelId -> FCOIS custom filterPanels
    --Character
    [FCOIS_CON_LF_CHARACTER]            = buttonContextMenuDestroy,
    --Companion character
    [FCOIS_CON_LF_COMPANION_CHARACTER]  = buttonContextMenuDestroy,
}

--The mapping between filterPanelIds and there special Anti-Settings which need an own contextmenu entry
mappingVars.filterPanelGotSpecialSettingsEntryInContextMenu = {
    [LF_GUILDBANK_DEPOSIT] = "blockGuildBankWithoutWithdraw",
}

--The maping table for the text at the context menu that the special anti-settings should show there
mappingVars.contextMenuSpecialAntiButtonsAtPanel = {
    [LF_GUILDBANK_DEPOSIT] = buttonContextMenuToggleAntiPrefix .."guild_bank_deposit_without_withdraw_rights_",
}


--The mapping table of the automatic DeMark icon to it's settings variable
-->Checked in /src/FCOIS_Functions.lua, function FCOIS.CheckIfItemShouldBeDemarked(iconId)
mappingVars.automaticDeMarkSettings = {
    [FCOIS_CON_ICON_SELL] =                 "autoDeMarkSell",
    [FCOIS_CON_ICON_SELL_AT_GUILDSTORE] =   "autoDeMarkSellInGuildStore",
    [FCOIS_CON_ICON_DECONSTRUCTION] =       "autoDeMarkDeconstruct",
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
local varX2 = -20
local varY2 = 64
--Last updated with API101042 - 20240507
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
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].top                  = varY2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].defaultLeft          = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_REFINE].defaultTop           = varY2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].anchorControl   = ctrlVars.DECONSTRUCTION_INV --#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].top             = varY2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_DECONSTRUCT].defaultTop      = varY2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT] = {}
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].anchorControl   = ctrlVars.IMPROVEMENT_INV
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].top             = varY2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_SMITHING_IMPROVEMENT].defaultTop      = varY2
anchorVarsAddInvButtonsFill[100021][LF_ALCHEMY_CREATION] = {}
anchorVarsAddInvButtonsFill[100021][LF_ALCHEMY_CREATION] .anchorControl   = ctrlVars.ALCHEMY_INV
anchorVarsAddInvButtonsFill[100021][LF_ALCHEMY_CREATION].left             = varX2
anchorVarsAddInvButtonsFill[100021][LF_ALCHEMY_CREATION].top              = varY1
anchorVarsAddInvButtonsFill[100021][LF_ALCHEMY_CREATION].defaultLeft      = varX2
anchorVarsAddInvButtonsFill[100021][LF_ALCHEMY_CREATION].defaultTop       = varY1
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION] = {}
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION] .anchorControl   = ctrlVars.ENCHANTING_INV
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].left             = varX2
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].top              = varY2
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].defaultLeft      = varX2
anchorVarsAddInvButtonsFill[100021][LF_ENCHANTING_CREATION].defaultTop       = varY2
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
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].top                  = varY2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].defaultLeft          = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_REFINE].defaultTop           = varY2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].anchorControl   = ctrlVars.DECONSTRUCTION_INV --#202 FilterButtons and additional inventory flag context menu button added to universal deconstruction panel
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].top             = varY2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_DECONSTRUCT].defaultTop      = varY2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT] = {}
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].anchorControl   = ctrlVars.IMPROVEMENT_INV
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].left            = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].top             = varY2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].defaultLeft     = varX2
anchorVarsAddInvButtonsFill[100021][LF_JEWELRY_IMPROVEMENT].defaultTop      = varY2
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY_COMPANION] = {}
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY_COMPANION].anchorControl   = ctrlVars.COMPANION_INV_CONTROL
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY_COMPANION].left            = -55
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY_COMPANION].top             = 110
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY_COMPANION].defaultLeft     = -55
anchorVarsAddInvButtonsFill[100021][LF_INVENTORY_COMPANION].defaultTop      = 110
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER] = {}
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER].anchorControl   = ctrlVars.CHARACTER
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER].anchorMyPoint   = TOPLEFT
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER].anchorToPoint   = TOPRIGHT
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER].left            = -16
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER].top             = 0
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER].defaultLeft     = -16
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_CHARACTER].defaultTop      = 0
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER] = {}
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER].anchorControl   = ctrlVars.COMPANION_CHARACTER
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER].anchorMyPoint   = TOPLEFT
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER].anchorToPoint   = TOPRIGHT
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER].left            = -16
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER].top             = 0
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER].defaultLeft     = -16
anchorVarsAddInvButtonsFill[100021][FCOIS_CON_LF_COMPANION_CHARACTER].defaultTop      = 0
--Is the current API version unequal one of the above one?
anchorVarsAddInvButtonsFill[FCOIS.APIversion] = {}
-->Not working with for in pairs loop :-( So we need to copy the contents!
--Use the anchor controls and settings of API 100021
--setmetatable(anchorVarsAddInvButtons[FCOIS.APIversion], {__index = anchorVarsAddInvButtons[100021]})
anchorVarsAddInvButtonsFill[FCOIS.APIversion] = anchorVarsAddInvButtonsFill[100021]

--The ordinal endings of the different languages
mappingVars.iconNrToOrdinalStr = {
    --English
    [1] = {
        [1]  = "st",
        [2]  = "nd",
        [3]  = "rd",
        [21] = "st",
        [22] = "nd",
        [23] = "rd",
        [31] = "st",
        [32] = "nd",
        [33] = "rd",
    },
    --French
    [3] = {
        [1]  = "premier",
        [2]  = "deuxième",
        [3]  = "troisième",
        [4]  = "quatrième",
        [5]  = "cinquième",
        [6]  = "sixième",
        [7]  = "septième",
        [8]  = "huitième",
        [9]  = "neuvième",
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

--#303
FCOIS.inventoriesSecurePostHooksDone = {}
