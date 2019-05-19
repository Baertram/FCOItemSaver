------------------------------------------------------------------
-- [Error messages to check] --
---------------------------------------------------------------------
--[ToDo list] --
-- 1) 2019-01-14 - Bugfix - Baertram
--Right clicking an item to show the context menu, and then left clicking somewhere else does not close the context menu on first click, but on 2nd click
--> Bug within LibCustomMenu -> >To be fixed by Votan?

-- 2) 2019-03-11 - Bugfix - Baertram
--Todo: IIfA UI: Set FCOIS marker icons by keybind for items without bagId and slotIndex (non-logged in chars!), by help of the itemLink and itemInstanceOrUniqueIdIIfA
--> See file src/FCOIS_functions.lua, function FCOIS.GetBagAndSlotFromControlUnderMouse(), at --IIfA support
--> marking via bagId and slotIndex does work BUT the list of IIfA is not refreshed until scrolling! SO this needs a fix as well.

-- 3) 2019-04-10 - Bugfix -  Reported by Kyoma on gitter.im
--Kyoma: Go to bank withdraw tab and use the keybind to mark with lock icon, then use keybind again to demark it.
--> Will produce an called by insecure code.
--> Why?
--Votan: item saver does ZO_PreHook("ZO_InventorySlot_ShowContextMenu",
-- Recomment to use libCustomMenu RegisterContextMenu
-- Should be a following error


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

------------------------------------------------------------------
--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

--===================== Libraries ==============================================
--Load libLoadedAddons
--FCOIS.LIBLA = LibStub:GetLibrary("LibLoadedAddons")
FCOIS.LIBLA = LibLoadedAddons
if FCOIS.LIBLA == nil and LibStub  then FCOIS.LIBLA = LibStub:GetLibrary("LibLoadedAddons") end

--Create the settings panel object of libAddonMenu 2.0
FCOIS.LAM = LibAddonMenu2
if FCOIS.LAM == nil and LibStub then FCOIS.LAM = LibStub('LibAddonMenu-2.0') end

--The options panel of FCO ItemSaver
FCOIS.FCOSettingsPanel = nil

--Create the libMainMenu 2.0 object
FCOIS.LMM2 = LibMainMenu2
if FCOIS.LMM2 == nil and LibStub then FCOIS.LMM2 = LibStub("LibMainMenu-2.0") end
FCOIS.LMM2:Init()

--Create the filter object for addon libFilters 3.x
FCOIS.libFilters = {}
FCOIS.libFilters = LibFilters3
if not FCOIS.libFilters then
    d(FCOIS.preChatVars.preChatTextRed .. " ERROR: Needed librray LibFilters-3.0 is not loaded. This addon will not work properly!")
    return
end
--Initialize the libFilters 3.x filters
FCOIS.libFilters:InitializeLibFilters()

--===================== ADDON Info =============================================
--Addon variables
FCOIS.addonVars = {}
FCOIS.addonVars.addonVersionOptions 		= '1.5.2' -- version shown in the settings panel
FCOIS.addonVars.addonVersionOptionsNumber	= 1.52
FCOIS.addonVars.gAddonName					= "FCOItemSaver"
FCOIS.addonVars.addonNameMenu				= "FCO ItemSaver"
FCOIS.addonVars.addonNameMenuDisplay		= "|c00FF00FCO |cFFFF00ItemSaver|r"
FCOIS.addonVars.addonAuthor 				= '|cFFFF00Baertram|r'
FCOIS.addonVars.addonAuthorDisplayNameEU  	= '@Baertram'
FCOIS.addonVars.addonAuthorDisplayNameNA  	= '@Baertram'
FCOIS.addonVars.addonAuthorDisplayNamePTS  	= '@Baertram'
FCOIS.addonVars.website 					= "https://www.esoui.com/downloads/info630-FCOItemSaver.html"
FCOIS.addonVars.FAQwebsite                  = "https://www.esoui.com/portal.php?id=136&a=faq"
FCOIS.addonVars.authorPortal                = "https://www.esoui.com/portal.php?&id=136"
FCOIS.addonVars.feedback                    = "https://www.esoui.com/portal.php?id=136&a=bugreport"
FCOIS.addonVars.donation                    = "https://www.esoui.com/portal.php?id=136&a=faq&faqid=131"
FCOIS.addonVars.savedVarVersion		   		= 0.10 -- Changing this will reset all SavedVariables!
FCOIS.addonVars.gAddonLoaded				= false
FCOIS.addonVars.gPlayerActivated			= false
FCOIS.addonVars.gSettingsLoaded				= false

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
