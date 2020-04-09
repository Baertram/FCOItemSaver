--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

--==========================================================================================================================================
-- 															FCOIS LOCALIZATION
--==========================================================================================================================================

function FCOIS.buildLocalizedFilterButtonContextMenuEntries(contextMenuType)
    local localizedContextMenuEntries = {}

    --Available context menus
    local availableCtms = FCOIS.contextMenuVars.availableCtms
    if availableCtms == nil then return nil end
    local ctmType = tostring(availableCtms[contextMenuType])
    if ctmType == nil or ctmType == "" then return nil end

    --Variables
    local settings = FCOIS.settingsVars.settings
    local locVars = FCOIS.localizationVars.fcois_loc
    local contextMenuVars = FCOIS.contextMenuVars
    local textureVars = FCOIS.textureVars

    --Gear set / dynamic icon variables
    local iconIsGear = settings.iconIsGear
    --local dynIconTotalCount = FCOIS.numVars.gFCONumDynamicIcons
    local dynIconTotalCount   = settings.numMaxDynamicIconsUsable
    local dynIconCounter2IconNr = FCOIS.mappingVars.dynamicToIcon
    local isDynamicIcon = FCOIS.mappingVars.iconIsDynamic

-----------------------------------------------------------------------------------------------
    --Lock, dynamic icons
    if contextMenuType == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
        --First add 2 entries, one for the * all and one for the lock icon
        local allEntry = {
            type = ctmType,
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = contextMenuVars.LockDynFilter.buttonNamePrefix .. "1",
        }
        localizedContextMenuEntries[contextMenuVars.buttonNamePrefix .. contextMenuVars.LockDynFilter.buttonNamePrefix .. "1"] = allEntry
        local lockEntry = {
            type = ctmType,
            text = "",
            texture = textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_LOCK].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_LOCK].color,
            iconId = FCOIS_CON_ICON_LOCK,
            anchorButton =  contextMenuVars.LockDynFilter.buttonNamePrefix .. "1",
        }
        localizedContextMenuEntries[contextMenuVars.buttonNamePrefix .. contextMenuVars.LockDynFilter.buttonNamePrefix .. "2"] = lockEntry

        --Then add the dynamic icons, but only those which are not enabled to be a gear set
        local dynCounter = 2
        for dynIconCounter=1, dynIconTotalCount, 1 do
            local dynIconNr = dynIconCounter2IconNr[dynIconCounter]
            local isDynamic = isDynamicIcon[dynIconNr]
            local isGear    = iconIsGear[dynIconNr]
            if settings.isIconEnabled[dynIconNr] and isDynamic and not isGear then
                local dynEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[settings.icon[dynIconNr].texture],
                    textureColor = settings.icon[dynIconNr].color,
                    iconId = dynIconNr,
                    anchorButton =  contextMenuVars.LockDynFilter.buttonNamePrefix .. tostring(dynCounter-1),
                }
                dynCounter = dynCounter + 1
                localizedContextMenuEntries[contextMenuVars.buttonNamePrefix .. contextMenuVars.LockDynFilter.buttonNamePrefix .. tostring(dynCounter)] = dynEntry
            end
        end

-----------------------------------------------------------------------------------------------
    --Gear sets
    elseif contextMenuType == FCOIS_CON_FILTER_BUTTON_GEARSETS then
        --First add 1 entry for the * all
        local allEntry = {
            type = ctmType,
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = contextMenuVars.buttonNamePrefix .. contextMenuVars.GearSetFilter.buttonNamePrefix .. "1",
        }
        localizedContextMenuEntries[contextMenuVars.buttonNamePrefix .. contextMenuVars.GearSetFilter.buttonNamePrefix .. "1"] = allEntry
        --Then add the gear set buttons dynamically
        local gearIconTotalCount = FCOIS.numVars.gFCONumGearSetsStatic
        local gearIconCounter2IconNr = FCOIS.mappingVars.gearToIcon
        --local isGearIcon = FCOIS.mappingVars.iconIsGear
        local gearsCounter = 1
        for gearIconCounter=1, gearIconTotalCount, 1 do
            local gearIconNr = gearIconCounter2IconNr[gearIconCounter]
            local isGear = iconIsGear[gearIconNr]
            if settings.isIconEnabled[gearIconNr] and isGear then
                local gearEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[settings.icon[gearIconNr].texture],
                    textureColor = settings.icon[gearIconNr].color,
                    iconId = gearIconNr,
                    anchorButton =  contextMenuVars.GearSetFilter.buttonNamePrefix .. tostring(gearsCounter-1),
                }
                gearsCounter = gearsCounter + 1
                localizedContextMenuEntries[contextMenuVars.buttonNamePrefix .. contextMenuVars.GearSetFilter.buttonNamePrefix .. tostring(gearsCounter)] = gearEntry
            end
        end
        --After the static gear set icons add the dynamic icons which are marked to be a gear set
        for dynIconCounter=1, dynIconTotalCount, 1 do
            local dynIconNr = dynIconCounter2IconNr[dynIconCounter]
            local isDynamic = isDynamicIcon[dynIconNr]
            local isGear    = iconIsGear[dynIconNr]
            if settings.isIconEnabled[dynIconNr] and isDynamic and isGear then
                local gearEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[settings.icon[dynIconNr].texture],
                    textureColor = settings.icon[dynIconNr].color,
                    iconId = dynIconNr,
                    anchorButton =  contextMenuVars.GearSetFilter.buttonNamePrefix .. tostring(gearsCounter-1),
                }
                gearsCounter = gearsCounter + 1
                localizedContextMenuEntries[contextMenuVars.buttonNamePrefix .. contextMenuVars.GearSetFilter.buttonNamePrefix .. tostring(gearsCounter)] = gearEntry
            end
        end

-----------------------------------------------------------------------------------------------
    --Research, deconstruction, improvement
    elseif contextMenuType == FCOIS_CON_FILTER_BUTTON_RESDECIMP then
--TODO: See function afterLocalization below and make it more dyanmically

-----------------------------------------------------------------------------------------------
    --Sell, sell in guild store, Intricate
    elseif contextMenuType == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT then
--TODO: See function afterLocalization below and make it more dyanmically
    end
    --Return the build context menu entries
    return localizedContextMenuEntries
end

--Do some "After localization" stuff
local function afterLocalization()
    --Local speed up variables
    local settings = FCOIS.settingsVars.settings
    local defaults = FCOIS.settingsVars.defaults
    local locVars = FCOIS.localizationVars.fcois_loc

    --Update the texts depending on localization
    defaults.icon[FCOIS_CON_ICON_GEAR_1].name    = locVars["options_icon2_name"]
    defaults.icon[FCOIS_CON_ICON_GEAR_2].name    = locVars["options_icon4_name"]
    defaults.icon[FCOIS_CON_ICON_GEAR_3].name    = locVars["options_icon6_name"]
    defaults.icon[FCOIS_CON_ICON_GEAR_4].name    = locVars["options_icon7_name"]
    defaults.icon[FCOIS_CON_ICON_GEAR_5].name    = locVars["options_icon8_name"]
    if (settings.icon[FCOIS_CON_ICON_GEAR_1].name == "") then
        settings.icon[FCOIS_CON_ICON_GEAR_1].name = defaults.icon[FCOIS_CON_ICON_GEAR_1].name
    end
    if (settings.icon[FCOIS_CON_ICON_GEAR_2].name == "") then
        settings.icon[FCOIS_CON_ICON_GEAR_2].name = defaults.icon[FCOIS_CON_ICON_GEAR_2].name
    end
    if (settings.icon[FCOIS_CON_ICON_GEAR_3].name == "") then
        settings.icon[FCOIS_CON_ICON_GEAR_3].name = defaults.icon[FCOIS_CON_ICON_GEAR_3].name
    end
    if (settings.icon[FCOIS_CON_ICON_GEAR_4].name == "") then
        settings.icon[FCOIS_CON_ICON_GEAR_4].name = defaults.icon[FCOIS_CON_ICON_GEAR_4].name
    end
    if (settings.icon[FCOIS_CON_ICON_GEAR_5].name == "") then
        settings.icon[FCOIS_CON_ICON_GEAR_5].name = defaults.icon[FCOIS_CON_ICON_GEAR_5].name
    end
    --Was the standard icon name for the keybinding changed before, or not?
    if settings.standardIconNameOnKeybind == "" then
        --It wasn't changed so update it according to the localized language
        local iconEndStrArray = FCOIS.localizationVars.iconEndStrArray
        local locIconNameStr = locVars["options_icon" .. tostring(1) .. "_" .. iconEndStrArray[1]]
        settings.standardIconNameOnKeybind = locIconNameStr
    end

    --Added with FCOIS v1.5.2
    --Dynamic icon texts localized
    FCOIS.generateLocalizedDynamicIconTexts()
    --Static keybinding texts
    FCOIS.generateStaticGearSetIconsKeybindingsTexts()
    --Dynamic keybinding texts
    FCOIS.generateDynamicIconsKeybindingsTexts()

    --Added with FCOIS v0.8.8d
    --Dynamic arrays for the inventory filter button's context menus:
    --The available contextmenus at the filter buttons
    local availableCtms = FCOIS.contextMenuVars.availableCtms
    --The array for the LockDyn filter button context menu entries
    FCOIS.contextMenuVars.LockDynFilter.buttonContextMenuToIconId = FCOIS.buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_LOCKDYN)

    --The mapping table for gear set split filter context menu buttons to icon id
    FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconId = FCOIS.buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_GEARSETS)

    --The mapping table for RESEARCH & DECONSTRUCTION & IMPORVEMENT split filter context menu buttons to icon id
    FCOIS.contextMenuVars.ResDecImpFilter.buttonContextMenuToIconId = {
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "1"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]),
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "1",
        },
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "2"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]),
            text = "",
            texture = FCOIS.textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_RESEARCH].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_RESEARCH].color,
            iconId = FCOIS_CON_ICON_RESEARCH,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "1",
        },
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "3"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]),
            text = "",
            texture = FCOIS.textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_DECONSTRUCTION].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_DECONSTRUCTION].color,
            iconId = FCOIS_CON_ICON_DECONSTRUCTION,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "2",
        },
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "4"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]),
            text = "",
            texture = FCOIS.textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_IMPROVEMENT].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_IMPROVEMENT].color,
            iconId = FCOIS_CON_ICON_IMPROVEMENT,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.ResDecImpFilter.buttonNamePrefix .. "3",
        },
    }

    --The mapping table for SELL & SELL IN GUILD STORE & INTRICATE split filter context menu buttons to icon id
    FCOIS.contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconId = {
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "1"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]),
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "1",
        },
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "2"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]),
            text = "",
            texture = FCOIS.textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_SELL].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_SELL].color,
            iconId = FCOIS_CON_ICON_SELL,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "1",
        },
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "3"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]),
            text = "",
            texture = FCOIS.textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_SELL_AT_GUILDSTORE].color,
            iconId = FCOIS_CON_ICON_SELL_AT_GUILDSTORE,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "2",
        },
        [FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "4"] = {
            type = tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]),
            text = "",
            texture = FCOIS.textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_INTRICATE].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_INTRICATE].color,
            iconId = FCOIS_CON_ICON_INTRICATE,
            anchorButton = FCOIS.contextMenuVars.buttonNamePrefix .. FCOIS.contextMenuVars.SellGuildIntFilter.buttonNamePrefix .. "3",
        },
    }

    --Added with FCOIS v0.8.8d
    --Build the global contextmenu variables for the filter button context menus
    FCOIS.ctmVars = {}
    local ctmVars = FCOIS.ctmVars
    local contextMenu = FCOIS.contextMenu
    local contextMenuVars = FCOIS.contextMenuVars
    local mappingVars = FCOIS.mappingVars
    local preventerVars = FCOIS.preventerVars

    --Set the mapping array for the filter buttons context menu to settings
    mappingVars.contextMenuFilterButtonTypeToSettings = {
        --========= LOCK & DYNAMIC ICONS CONTEXT MENU===================================
        [tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN])] 		= settings.splitLockDynFilter,
        --========= GEAR SETS CONTEXT MENU =============================================
        [tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS])] 	= settings.splitGearSetsFilter,
        --========= RESEARCH & DECONSTRUCTION & IMPORVEMENT CONTEXT MENU =============================
        [tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP])] 	= settings.splitResearchDeconstructionImprovementFilter,
        --========= SELL & SELL AT GUILD STORE & INTRICATE CONTEXT MENU =============================
        [tostring(availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT])] = settings.splitSellGuildSellIntricateFilter,
    }
    --For each available contextmenu type (at filter buttons) build the needed arrays
    for ctmNumber=1, #availableCtms, 1 do
        local ctmName = availableCtms[ctmNumber]
        ctmVars[ctmName] = {}
        ctmVars[ctmName].cmAtPanel = {}
        ctmVars[ctmName].cmVars = {}
        ctmVars[ctmName].cmFilterName = ""
        ctmVars[ctmName].lastIcon = {}
        ctmVars[ctmName].buttonTemplate = {}
        ctmVars[ctmName].buttonTemplateIndex = {}
        ctmVars[ctmName].mappingIcons = {}
        ctmVars[ctmName].pVars = {}
    end
    --Prepare the variables for each contextmenu type
    --LockDyn
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].cmAtPanel 		    = contextMenu.LockDynFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].cmVars 			    = contextMenuVars.LockDynFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].lastIcon 			= settings.lastLockDynFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].cmFilterName 		= contextMenu.ContextMenuLockDynFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].mappingIcons 		= mappingVars.lockDynToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].pVars 			    = preventerVars.gLockDynFilterContextCreated
    --Gear
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].cmAtPanel 		    = contextMenu.GearSetFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].cmVars 			= contextMenuVars.GearSetFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].lastIcon 		   	= settings.lastGearFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].cmFilterName 		= contextMenu.ContextMenuGearSetFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].mappingIcons 		= mappingVars.gearToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].pVars 			    = preventerVars.gGearSetFilterContextCreated
    --ResDecImp
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].cmAtPanel 		= contextMenu.ResDecImpFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].cmVars 			= contextMenuVars.ResDecImpFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].lastIcon 		    = settings.lastResDecImpFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].cmFilterName 	    = contextMenu.ContextMenuResDecImpFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].mappingIcons 	    = mappingVars.resDecImpToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].pVars 			= preventerVars.gResDecImpFilterContextCreated
    --SellGuildInt
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].cmAtPanel 	    = contextMenu.SellGuildIntFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].cmVars 		= contextMenuVars.SellGuildIntFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].lastIcon 		= settings.lastSellGuildIntFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].cmFilterName	= contextMenu.ContextMenuSellGuildIntFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].mappingIcons	= mappingVars.sellGuildIntToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].pVars 		    = preventerVars.gSellGuildIntFilterContextCreated
    --for each available contextmenu (at filter buttons) build the needed arrays
    for ctmNumber=1, #availableCtms, 1 do
        local ctmName = availableCtms[ctmNumber]
        ctmVars[ctmName].buttonTemplate 		= ctmVars[ctmName].cmVars.buttonContextMenuToIconId
        ctmVars[ctmName].buttonTemplateIndex 	= ctmVars[ctmName].cmVars.buttonContextMenuToIconIdIndex
    end
end

--Localized texts etc.
function FCOIS.Localization()
    local preventerVars = FCOIS.preventerVars
    local defSettings = FCOIS.settingsVars.defaultSettings
    local langVars = FCOIS.langVars
--d("[FCOIS] Localization - Start, keybindings: " .. tostring(preventerVars.KeyBindingTexts) ..", useClientLang: " .. tostring(FCOIS.settingsVars.settings.alwaysUseClientLanguage))

    --Was localization already done during keybindings? Then abort here
    if preventerVars.KeyBindingTexts == true and preventerVars.gLocalizationDone == true then return end
    --Fallback to english variable
    local fallbackToEnglish = false
    --Always use the client's language?
    if not FCOIS.settingsVars.settings.alwaysUseClientLanguage then
        --Was a language chosen already?
        if not FCOIS.settingsVars.settings.languageChosen then
            --d("[FCOIS] Localization: Fallback to english. Keybindings: " .. tostring(preventerVars.KeyBindingTexts) .. ", language chosen: " .. tostring(FCOIS.settingsVars.settings.languageChosen) .. ", defaultLanguage: " .. tostring(defSettings.language))
            if defSettings.language == nil then
                --d("[FCOIS] Localization: defaultSettings.language is NIL -> Fallback to english now")
                fallbackToEnglish = true
            else
                --Is the languages array filled and the language is not valid (not in the language array with the value "true")?
                if langVars.languages ~= nil and #langVars.languages > 0 and not langVars.languages[defSettings.language] then
                    fallbackToEnglish = true
                    --d("[FCOIS] Localization: defaultSettings.language is ~= " .. i .. ", and this language # is not valid -> Fallback to english now")
                end
            end
        end
    end
    --d("[FCOIS] localization, fallBackToEnglish: " .. tostring(fallbackToEnglish))
    --Fallback to english language now
    if (fallbackToEnglish) then defSettings.language = FCOIS_CON_LANG_EN end
    --Is the standard language english set?
    if FCOIS.settingsVars.settings.alwaysUseClientLanguage or (preventerVars.KeyBindingTexts or (defSettings.language == FCOIS_CON_LANG_EN and not FCOIS.settingsVars.settings.languageChosen)) then
        --d("[FCOIS] localization: Language chosen is false or always use client language is true!")
        local lang = GetCVar("language.2")
        --Check for supported languages
        if(lang == "de") then
            defSettings.language = FCOIS_CON_LANG_DE
        elseif (lang == "en") then
            defSettings.language = FCOIS_CON_LANG_EN
        elseif (lang == "fr") then
            defSettings.language = FCOIS_CON_LANG_FR
        elseif (lang == "es") then
            defSettings.language = FCOIS_CON_LANG_ES
        elseif (lang == "it") then
            defSettings.language = FCOIS_CON_LANG_IT
        elseif (lang == "jp") then
            defSettings.language = FCOIS_CON_LANG_JP
        elseif (lang == "ru") then
            defSettings.language = FCOIS_CON_LANG_RU
        else
            defSettings.language = FCOIS_CON_LANG_EN
        end
    end
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[Localization]","default settings, language: " .. tostring(defSettings.language), false) end
    --d("[FCOIS] localization: default settings, language: " .. tostring(defSettings.language))
    --Get the localized texts from the localization file
    local locVars = FCOIS.localizationVars
    locVars.fcois_loc = locVars.localizationAll[defSettings.language]

    --The localization end string array
    locVars.iconEndStrArray = {
        [1]  = "color",
        [2]  = "name",
        [3]  = "color",
        [4]  = "name",
        [5]  = "color",
        [6]  = "name",
        [7]  = "name",
        [8]  = "name",
        [9]  = "color",
        [10] = "color",
        [11] = "color",
        [12] = "color",
        --Dynamic icons
        -->Added dynamically in this function, a bit more to the bottom in the source code
    }

    preventerVars.gLocalizationDone = true
    --Abort here if we only needed the keybinding texts
    if preventerVars.KeyBindingTexts == true then return end

    --Local variable for a faster array parsing
    local locTexts = locVars.fcois_loc
    local contextEntries = locVars.contextEntries

    --Initialize arrays
    contextEntries.menu_add_all_text			= {}
    contextEntries.menu_remove_all_text			= {}
    contextEntries.menu_add_gear_text			= {}
    contextEntries.menu_remove_gear_text		= {}
    contextEntries.menu_add_all_gear_text		= {}
    contextEntries.menu_remove_all_gear_text	= {}
    contextEntries.menu_add_dynamic_text		= {}
    contextEntries.menu_remove_dynamic_text		= {}

    --Prepare the texts for the right click menus
    --Add
    contextEntries.menu_add_lock_text  	   		= locTexts["rightclick_menu_lock"]
    contextEntries.menu_add_gear_text[1]	  	= locTexts["rightclick_menu_add_gear1"]
    contextEntries.menu_add_research_text    	= locTexts["rightclick_menu_mark_analysis"]
    contextEntries.menu_add_gear_text[2]	  	= locTexts["rightclick_menu_add_gear2"]
    contextEntries.menu_add_sell_text 	 		= locTexts["rightclick_menu_mark_sell"]
    contextEntries.menu_add_gear_text[3] 	  	= locTexts["rightclick_menu_add_gear3"]
    contextEntries.menu_add_gear_text[4] 	  	= locTexts["rightclick_menu_add_gear4"]
    contextEntries.menu_add_gear_text[5] 	  	= locTexts["rightclick_menu_add_gear5"]
    contextEntries.menu_add_deconstruction_text	= locTexts["rightclick_menu_mark_deconstruction"]
    contextEntries.menu_add_improvement_text   	= locTexts["rightclick_menu_mark_improvement"]
    contextEntries.menu_add_sell_to_guild_text 	= locTexts["rightclick_menu_mark_sell_in_guild_store"]
    contextEntries.menu_add_intricate_text     	= locTexts["rightclick_menu_mark_intricate"]
    --Add all
    contextEntries.menu_add_all_gear_text[1]  	= locTexts["rightclick_menu_add_all_gear1"]
    contextEntries.menu_add_all_gear_text[2]  	= locTexts["rightclick_menu_add_all_gear2"]
    contextEntries.menu_add_all_gear_text[3]  	= locTexts["rightclick_menu_add_all_gear3"]
    contextEntries.menu_add_all_gear_text[4]  	= locTexts["rightclick_menu_add_all_gear4"]
    contextEntries.menu_add_all_gear_text[5]  	= locTexts["rightclick_menu_add_all_gear5"]
    --Remove
    contextEntries.menu_remove_lock_text  	  	= locTexts["rightclick_menu_unlock"]
    contextEntries.menu_remove_gear_text[1]		= locTexts["rightclick_menu_remove_gear1"]
    contextEntries.menu_remove_research_text  	= locTexts["rightclick_menu_demark_analysis"]
    contextEntries.menu_remove_gear_text[2]		= locTexts["rightclick_menu_remove_gear2"]
    contextEntries.menu_remove_sell_text 	 	= locTexts["rightclick_menu_demark_sell"]
    contextEntries.menu_remove_gear_text[3]   	= locTexts["rightclick_menu_remove_gear3"]
    contextEntries.menu_remove_gear_text[4]   	= locTexts["rightclick_menu_remove_gear4"]
    contextEntries.menu_remove_gear_text[5]		= locTexts["rightclick_menu_remove_gear5"]
    contextEntries.menu_remove_deconstruction_text = locTexts["rightclick_menu_demark_deconstruction"]
    contextEntries.menu_remove_improvement_text = locTexts["rightclick_menu_demark_improvement"]
    contextEntries.menu_remove_sell_to_guild_text= locTexts["rightclick_menu_demark_sell_in_guild_store"]
    contextEntries.menu_remove_intricate_text  	= locTexts["rightclick_menu_demark_intricate"]
    --Remove all
    contextEntries.menu_remove_all_gear_text[1] = locTexts["rightclick_menu_remove_all_gear1"]
    contextEntries.menu_remove_all_gear_text[2] = locTexts["rightclick_menu_remove_all_gear2"]
    contextEntries.menu_remove_all_gear_text[3] = locTexts["rightclick_menu_remove_all_gear3"]
    contextEntries.menu_remove_all_gear_text[4] = locTexts["rightclick_menu_remove_all_gear4"]
    contextEntries.menu_remove_all_gear_text[5] = locTexts["rightclick_menu_remove_all_gear5"]
    --Add all/remove all additional inventory button (flag) context menu
    contextEntries.menu_add_all_text[FCOIS_CON_ICON_LOCK] 		            = locTexts["button_context_menu_lock_all"]
    contextEntries.menu_remove_all_text[FCOIS_CON_ICON_LOCK] 		        = locTexts["button_context_menu_unlock_all"]
    contextEntries.menu_add_all_text[FCOIS_CON_ICON_RESEARCH] 		        = locTexts["button_context_menu_research_all"]
    contextEntries.menu_remove_all_text[FCOIS_CON_ICON_RESEARCH] 		    = locTexts["button_context_menu_dont_research_all"]
    contextEntries.menu_add_all_text[FCOIS_CON_ICON_SELL] 		            = locTexts["button_context_menu_sell_all"]
    contextEntries.menu_remove_all_text[FCOIS_CON_ICON_SELL] 		        = locTexts["button_context_menu_dont_sell_all"]
    contextEntries.menu_add_all_text[FCOIS_CON_ICON_DECONSTRUCTION] 		= locTexts["button_context_menu_deconstruct_all"]
    contextEntries.menu_remove_all_text[FCOIS_CON_ICON_DECONSTRUCTION] 		= locTexts["button_context_menu_dont_deconstruct_all"]
    contextEntries.menu_add_all_text[FCOIS_CON_ICON_IMPROVEMENT]  		    = locTexts["button_context_menu_improve_all"]
    contextEntries.menu_remove_all_text[FCOIS_CON_ICON_IMPROVEMENT] 	    = locTexts["button_context_menu_dont_improve_all"]
    contextEntries.menu_add_all_text[FCOIS_CON_ICON_SELL_AT_GUILDSTORE]  	= locTexts["button_context_menu_sell_all_in_guild_store"]
    contextEntries.menu_remove_all_text[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] 	= locTexts["button_context_menu_dont_sell_all_in_guild_store"]
    contextEntries.menu_add_all_text[FCOIS_CON_ICON_INTRICATE]  		    = locTexts["button_context_menu_mark_all_as_intricate"]
    contextEntries.menu_remove_all_text[FCOIS_CON_ICON_INTRICATE] 	        = locTexts["button_context_menu_unmark_all_as_intricate"]
    --Add the dynamic icon entries to the tables
    --local numDynIcons = FCOIS.numVars.gFCONumDynamicIcons
    local numDynIcons   = FCOIS.settingsVars.settings.numMaxDynamicIconsUsable
    local dynIconCounter2IconNr = FCOIS.mappingVars.dynamicToIcon
    local isDynamicIcon = FCOIS.mappingVars.iconIsDynamic
    for dynamicIconId=1, numDynIcons, 1 do
        local dynIconNr = dynIconCounter2IconNr[dynamicIconId]
        if isDynamicIcon[dynIconNr] then
            --Icon end string
            table.insert(FCOIS.localizationVars.iconEndStrArray, "color")
            --Add dynamic right click menu
            table.insert(contextEntries.menu_add_dynamic_text, locTexts["rightclick_menu_mark_dynamic" .. tostring(dynIconNr)])
            --Remove dynamic right click menu
            table.insert(contextEntries.menu_remove_dynamic_text, locTexts["rightclick_menu_demark_dynamic".. tostring(dynIconNr)])
            --Add all dynamic right click menu
            table.insert(contextEntries.menu_add_all_text, locTexts["button_context_menu_mark_all_as_dynamic".. tostring(dynIconNr)])
            --remove all dynamic right click menu
            table.insert(contextEntries.menu_remove_all_text, locTexts["button_context_menu_unmark_all_as_dynamic".. tostring(dynIconNr)])
        end
    end
    --Set the alert message texts as an item gets checked against anti-* (localized!)
    FCOIS.mappingVars.whereAreWeToAlertmessageText = {
        [FCOIS_CON_DESTROY]				=	locTexts["destroying_not_allowed"],
        [FCOIS_CON_MAIL]				=	locTexts["sendbymail_not_allowed"],
        [FCOIS_CON_TRADE]				=	locTexts["trading_not_allowed"],
        [FCOIS_CON_SELL]				=	locTexts["selling_not_allowed"],
        [FCOIS_CON_REFINE]				=	locTexts["refinement_not_allowed"],
        [FCOIS_CON_IMPROVE]				=	locTexts["improvement_not_allowed"],
        [FCOIS_CON_DECONSTRUCT]			=	locTexts["deconstruction_not_allowed"],
        [FCOIS_CON_RESEARCH]	        =	locTexts["research_not_allowed"],
        [FCOIS_CON_JEWELRY_REFINE]		=	locTexts["refinement_not_allowed"],
        [FCOIS_CON_JEWELRY_DECONSTRUCT]	=	locTexts["deconstruction_not_allowed"],
        [FCOIS_CON_JEWELRY_IMPROVE]		=	locTexts["improvement_not_allowed"],
        [FCOIS_CON_JEWELRY_RESEARCH]	=	locTexts["research_not_allowed"],
        [FCOIS_CON_ENCHANT_EXTRACT]		=	locTexts["enchanting_extraction_not_allowed"],
        [FCOIS_CON_ENCHANT_CREATE]		=	locTexts["enchanting_creation_not_allowed"],
        [FCOIS_CON_GUILD_STORE_SELL]	=	locTexts["guild_store_sell_not_allowed"],
        [FCOIS_CON_FENCE_SELL]			=	locTexts["fence_selling_not_allowed"],
        [FCOIS_CON_LAUNDER_SELL]		=	locTexts["launder_selling_not_allowed"],
        [FCOIS_CON_ALCHEMY_DESTROY]		=	locTexts["alchemy_destroy_not_allowed"],
        [FCOIS_CON_CONTAINER_AUTOOLOOT]	=	locTexts["container_autoloot_not_allowed"],
        [FCOIS_CON_RECIPE_USAGE]		=	locTexts["recipe_usage_not_allowed"],
        [FCOIS_CON_MOTIF_USAGE]			=	locTexts["motif_usage_not_allowed"],
        [FCOIS_CON_POTION_USAGE]		=	locTexts["potion_usage_not_allowed"],
        [FCOIS_CON_FOOD_USAGE]			=	locTexts["food_usage_not_allowed"],
        [FCOIS_CON_CROWN_ITEM]			=	locTexts["crown_item_usage_not_allowed"],
        [FCOIS_CON_CRAFTBAG_DESTROY]	=	locTexts["destroying_not_allowed"],
        [FCOIS_CON_RETRAIT]	            =	locTexts["retrait_not_allowed"],
        [FCOIS_CON_FALLBACK]			=   locTexts["destroying_not_allowed"],  -- Fallback: Destroying not allowed (used at bank deposit, guild bank deposit, bank withdraw, guild bank withdraw, ...)
    }
    --Do some "after localization" stuff
    afterLocalization()
end