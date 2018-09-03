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
--libFilters 2.0
--Create the filter object for addon libFilters 2.x if not already done in FCOIS_Constants.lua file

--Load libLoadedAddons
FCOIS.LIBLA = LibStub:GetLibrary("LibLoadedAddons")

--Create the settings panel object of libAddonMenu 2.0
FCOIS.LAM = LibStub('LibAddonMenu-2.0')
--The options panel of FCO ItemSaver
FCOIS.FCOSettingsPanel = nil

--Create the libMainMenu 2.0 object
FCOIS.LMM2 = LibStub("LibMainMenu-2.0")
FCOIS.LMM2:Init()

--===================== ADDON Info =============================================
--Addon variables
FCOIS.addonVars = {}
FCOIS.addonVars.addonVersionOptions 		= '1.4.0' -- version shown in the settings panel
FCOIS.addonVars.addonVersionOptionsNumber	= 1.40
FCOIS.addonVars.gAddonName					= "FCOItemSaver"
FCOIS.addonVars.addonNameMenu				= "FCO ItemSaver"
FCOIS.addonVars.addonNameMenuDisplay		= "|c00FF00FCO |cFFFF00ItemSaver|r"
FCOIS.addonVars.addonAuthor 				= '|cFFFF00Baertram|r'
FCOIS.addonVars.addonAuthorDisplayNameEU  	= '@Baertram'
FCOIS.addonVars.addonAuthorDisplayNameNA  	= '@Baertram'
FCOIS.addonVars.addonAuthorDisplayNamePTS  	= '@Baertram'
FCOIS.addonVars.website 					= "https://www.esoui.com/downloads/info630-FCOItemSaver.html"
FCOIS.addonVars.FAQwebsite                  = "http://www.esoui.com/portal.php?id=136&a=faq"
FCOIS.addonVars.authorPortal                = "http://www.esoui.com/portal.php?&id=136"
FCOIS.addonVars.savedVarVersion		   		= 0.10 -- Changing this will reset all SavedVariables!
FCOIS.addonVars.gAddonLoaded				= false
FCOIS.addonVars.gPlayerActivated			= false
FCOIS.addonVars.gSettingsLoaded				= false

-- =====================================================================================================================
--  Addon initialization
-- =====================================================================================================================

-- Register the event "addon loaded" for this addon
local function FCOItemSaver_Initialized()
    --Set the event callback functions -> file FCOIS_Events.lua
    FCOIS.setEventCallbackFunctions()
end

--------------------------------------------------------------------------------
--- Call the start function for this addon, so the initialization is done
--------------------------------------------------------------------------------
FCOItemSaver_Initialized()
