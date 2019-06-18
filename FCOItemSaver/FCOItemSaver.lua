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

-- 4) 2019-06-18 - Bugfix - Baertram (on user report in comments, Ivo_ESO
--Research assistant duplicate items will be auto marked with FCOIS even if another researchable one was already marked
--> See file src/FCOIS_AutomaticMarks.lua, function


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

--===================== ADDON Info =============================================
--Addon variables
FCOIS.addonVars = {}
FCOIS.addonVars.addonVersionOptions 		= '1.5.6' -- version shown in the settings panel
FCOIS.addonVars.addonVersionOptionsNumber	= 1.56
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
--  Gamepad functions
-- =====================================================================================================================
--Is the gamepad mode enabled in the ESO settings?
function FCOIS.FCOItemSaver_CheckGamePadMode()
    FCOIS.preventerVars = FCOIS.preventerVars or {}
    --Gamepad enabled?
    if IsInGamepadPreferredMode() then
        --Gamepad enabled but addon AdvancedDisableControllerUI is enabled and is not showing the gamepad mode for the inventory,
        --but the normal inventory
        if FCOIS.checkIfADCUIAndIsNotUsingGamepadMode() then
            return false
        else
            if FCOIS.preventerVars.noGamePadMoudeSupportTextOutput == false then
                FCOIS.preventerVars.noGamePadMoudeSupportTextOutput = true
                --Normal gamepad mode is enabled -> Abort with error message "not supported!"
                local noGamepadModeSupportedLanguageTexts = {
                    ["en"]	=	"FCO ItemSaver does not support the gamepad mode! Please change the mode to keyboard at the settings.",
                    ["de"]	=	"FCO ItemSaver unterstützt den Gamepad Modus nicht! Bitte wechsel in den Optionen zum Tastatur Modus.",
                    ["fr"]	=	"FCO ItemSaver ne prend pas en charge le mode de gamepad! S'il vous plaît changer le mode de clavier au niveau des réglages.",
                    ["es"]	=	"FCO ItemSaver no es compatible con el modo de mando de juegos! Por favor, cambie el modo de teclado en la configuración.",
                    ["it"]	=	"FCO ItemSaver non supporta la modalità di gamepad! Si prega di cambiare la modalità di tastiera con le impostazioni.",
                    ["jp"]	=	"FCO ItemSaverはゲームパッドモードをサポートしません！設定でキーボードモードに変更してください。",
                    ["ru"]	=	"FCO ItemSaver нe пoддepживaeт peжим гeймпaдa! Пoжaлуйcтa, cмeнитe в нacтpoйкax peжим нa клaвиaтуpу.",
                }
                local lang = GetCVar("language.2")
                local noGamepadModeSupportedText = noGamepadModeSupportedLanguageTexts[lang] or noGamepadModeSupportedLanguageTexts["en"]
                d(FCOIS.preChatVars.preChatTextRed .. noGamepadModeSupportedText)
            end
            return true
        end
    else
        --Gamepad not enabled
        return false
    end
end


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
