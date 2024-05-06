--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local tos = tostring
local tabins = table.insert

local debugMessage = FCOIS.debugMessage

local availableCtms = FCOIS.contextMenuVars.availableCtms

--==========================================================================================================================================
-- 															FCOIS LOCALIZATION
--==========================================================================================================================================
--Change the contextMenu "contextMenuType"'s filter button entries (e.g. remove dynamic gear from dynamics and move to gear contextMenu)
-->Update the array for the "contextMenuType"'s filter button context menu entries
function FCOIS.BuildLocalizedFilterButtonContextMenuEntries(contextMenuType)
    local localizedContextMenuEntries = {}

    --Available context menus
    if availableCtms == nil then return nil end
    local ctmType = tos(availableCtms[contextMenuType])
    if ctmType == nil or ctmType == "" then return nil end

    --Variables
    local settings =        FCOIS.settingsVars.settings
    local locVars =         FCOIS.localizationVars.fcois_loc
    local mappingVars =     FCOIS.mappingVars
    local numVars =         FCOIS.numVars
    local contextMenuVars = FCOIS.contextMenuVars
    local textureVars =     FCOIS.textureVars
    local buttonNamePrefix = contextMenuVars.buttonNamePrefix

    --Gear set / dynamic icon variables
    local iconIsGear =              settings.iconIsGear
    --local dynIconTotalCount =     FCOIS.numVars.gFCONumDynamicIcons
    local dynIconTotalCount   =     settings.numMaxDynamicIconsUsable
    local dynIconCounter2IconNr =   mappingVars.dynamicToIcon
    local isDynamicIcon =           mappingVars.iconIsDynamic
    local resDecImpIconTotalCount = numVars.resDecImpIconCount
    local sellGuildIntIconTotalCount = numVars.sellGuildIntIconCount

-----------------------------------------------------------------------------------------------
    --Lock, dynamic icons
    if contextMenuType == FCOIS_CON_FILTER_BUTTON_LOCKDYN then
        local buttonNamePrefixLockDyn = contextMenuVars.LockDynFilter.buttonNamePrefix
        --First add 2 entries, one for the * all and one for the lock icon
        local allEntry = {
            type = ctmType,
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = buttonNamePrefixLockDyn .. "1",
        }
        localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixLockDyn .. "1"] = allEntry
        local lockEntry = {
            type = ctmType,
            text = "",
            texture = textureVars.MARKER_TEXTURES[settings.icon[FCOIS_CON_ICON_LOCK].texture],
            textureColor = settings.icon[FCOIS_CON_ICON_LOCK].color,
            iconId = FCOIS_CON_ICON_LOCK,
            anchorButton = buttonNamePrefixLockDyn .. "1",
        }
        localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixLockDyn .. "2"] = lockEntry

        --Then add the dynamic icons, but only those which are not enabled to be a gear set
        local dynCounter = 2
        for dynIconCounter=1, dynIconTotalCount, 1 do
            local dynIconNr = dynIconCounter2IconNr[dynIconCounter]
            local isDynamic = isDynamicIcon[dynIconNr]
            local isGear    = iconIsGear[dynIconNr]
            if settings.isIconEnabled[dynIconNr] and isDynamic and not isGear then
                local iconData = settings.icon[dynIconNr]
                local dynEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[iconData.texture],
                    textureColor = iconData.color,
                    iconId = dynIconNr,
                    anchorButton = buttonNamePrefixLockDyn .. tos(dynCounter-1),
                }
                dynCounter = dynCounter + 1
                localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixLockDyn .. tos(dynCounter)] = dynEntry
            end
        end

-----------------------------------------------------------------------------------------------
    --Gear sets
    elseif contextMenuType == FCOIS_CON_FILTER_BUTTON_GEARSETS then
        local buttonNamePrefixGearSet = contextMenuVars.GearSetFilter.buttonNamePrefix
        --First add 1 entry for the * all
        local allEntry = {
            type = ctmType,
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = buttonNamePrefix .. buttonNamePrefixGearSet .. "1",
        }
        localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixGearSet .. "1"] = allEntry
        --Then add the gear set buttons dynamically
        local gearIconTotalCount = FCOIS.numVars.gFCONumGearSetsStatic
        local gearIconCounter2IconNr = FCOIS.mappingVars.gearToIcon
        --local isGearIcon = FCOIS.mappingVars.iconIsGear
        local gearsCounter = 1
        for gearIconCounter=1, gearIconTotalCount, 1 do
            local gearIconNr = gearIconCounter2IconNr[gearIconCounter]
            local isGear = iconIsGear[gearIconNr]
            if settings.isIconEnabled[gearIconNr] and isGear then
                local iconData = settings.icon[gearIconNr]
                local gearEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[iconData.texture],
                    textureColor = iconData.color,
                    iconId = gearIconNr,
                    anchorButton = buttonNamePrefixGearSet .. tos(gearsCounter-1),
                }
                gearsCounter = gearsCounter + 1
                localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixGearSet .. tos(gearsCounter)] = gearEntry
            end
        end
        --After the static gear set icons add the dynamic icons which are marked to be a gear set
        for dynIconCounter=1, dynIconTotalCount, 1 do
            local dynIconNr = dynIconCounter2IconNr[dynIconCounter]
            local isDynamic = isDynamicIcon[dynIconNr]
            local isGear    = iconIsGear[dynIconNr]
            if settings.isIconEnabled[dynIconNr] and isDynamic and isGear then
                local iconData = settings.icon[dynIconNr]
                local gearEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[iconData.texture],
                    textureColor = iconData.color,
                    iconId = dynIconNr,
                    anchorButton =  buttonNamePrefixGearSet .. tos(gearsCounter-1),
                }
                gearsCounter = gearsCounter + 1
                localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixGearSet .. tos(gearsCounter)] = gearEntry
            end
        end

-----------------------------------------------------------------------------------------------
    --Research, deconstruction, improvement
    elseif contextMenuType == FCOIS_CON_FILTER_BUTTON_RESDECIMP then
        local buttonNamePrefixResDecImp = contextMenuVars.ResDecImpFilter.buttonNamePrefix
        --First add 1 entry for the * all
        local allEntry = {
            type = ctmType,
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = buttonNamePrefix .. buttonNamePrefixResDecImp .. "1",
        }
        localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixResDecImp .. "1"] = allEntry

        local resDecImpCounter = 1
        for resDecImpIconCounter=1, resDecImpIconTotalCount, 1 do
            local resDecImpIcon = mappingVars.resDecImpToIcon[resDecImpIconCounter]
            if resDecImpIcon ~= nil and settings.isIconEnabled[resDecImpIcon] then
                local iconData = settings.icon[resDecImpIcon]
                local resDecImpEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[iconData.texture],
                    textureColor = iconData.color,
                    iconId = resDecImpIcon,
                    anchorButton =  buttonNamePrefixResDecImp .. tos(resDecImpCounter-1),
                }
                resDecImpCounter = resDecImpCounter + 1
                localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixResDecImp .. tos(resDecImpCounter)] = resDecImpEntry
            end
        end

-----------------------------------------------------------------------------------------------
    --Sell, sell in guild store, Intricate
    elseif contextMenuType == FCOIS_CON_FILTER_BUTTON_SELLGUILDINT then
        local buttonNamePrefixSellGuildInt = contextMenuVars.SellGuildIntFilter.buttonNamePrefix
        --First add 1 entry for the * all
        local allEntry = {
            type = ctmType,
            text = locVars["button_context_menu_gear_sets_all"],
            texture = "",
            textureColor = nil,
            iconId = -1,
            anchorButton = buttonNamePrefix .. buttonNamePrefixSellGuildInt .. "1",
        }
        localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixSellGuildInt .. "1"] = allEntry

        local sellGuildIntCounter = 1
        for sellGuildIntIconCounter=1, sellGuildIntIconTotalCount, 1 do
            local sellGuildIntIcon = mappingVars.sellGuildIntToIcon[sellGuildIntIconCounter]
            if sellGuildIntIcon ~= nil and settings.isIconEnabled[sellGuildIntIcon] then
                local iconData = settings.icon[sellGuildIntIcon]
                local sellGuildIntEntry = {
                    type = ctmType,
                    text = "",
                    texture = textureVars.MARKER_TEXTURES[iconData.texture],
                    textureColor = iconData.color,
                    iconId = sellGuildIntIcon,
                    anchorButton =  buttonNamePrefixSellGuildInt .. tos(sellGuildIntCounter-1),
                }
                sellGuildIntCounter = sellGuildIntCounter + 1
                localizedContextMenuEntries[buttonNamePrefix .. buttonNamePrefixSellGuildInt .. tos(sellGuildIntCounter)] = sellGuildIntEntry
            end
        end
    end
    --Return the build context menu entries
    return localizedContextMenuEntries
end
local buildLocalizedFilterButtonContextMenuEntries = FCOIS.BuildLocalizedFilterButtonContextMenuEntries


--Do some "After localization" stuff
local function afterLocalization()
    --Local speed up variables
    local settings = FCOIS.settingsVars.settings
    local settingsOfFilterButtonStateAndIcon = FCOIS.GetAccountWideCharacterOrNormalCharacterSettings()
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
        local locIconNameStr = locVars["options_icon" .. tos(1) .. "_" .. iconEndStrArray[1]]
        settings.standardIconNameOnKeybind = locIconNameStr
    end

    --Added with FCOIS v2.2.4
    FCOIS.LoadKeybindings()
    --Added with FCOIS v1.5.2
    --Dynamic icon texts localized
    FCOIS.GenerateLocalizedDynamicIconTexts()
    --Static keybinding texts
    FCOIS.GenerateStaticGearSetIconsKeybindingsTexts()
    --Dynamic keybinding texts
    FCOIS.GenerateDynamicIconsKeybindingsTexts()

    --Added with FCOIS v0.8.8d
    --Dynamic arrays for the inventory filter button's context menus:
    --The available contextmenus at the filter buttons
    --The array for the LockDyn filter button context menu entries
    FCOIS.contextMenuVars.LockDynFilter.buttonContextMenuToIconId = buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_LOCKDYN)
    --The mapping table for gear set split filter context menu buttons to icon id
    FCOIS.contextMenuVars.GearSetFilter.buttonContextMenuToIconId = buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_GEARSETS)
    --The mapping table for RESEARCH & DECONSTRUCTION & IMPROVEMENT split filter context menu buttons to icon id
    FCOIS.contextMenuVars.ResDecImpFilter.buttonContextMenuToIconId = buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_RESDECIMP)
    --The mapping table for SELL & SELL IN GUILD STORE & INTRICATE split filter context menu buttons to icon id
    FCOIS.contextMenuVars.SellGuildIntFilter.buttonContextMenuToIconId = buildLocalizedFilterButtonContextMenuEntries(FCOIS_CON_FILTER_BUTTON_SELLGUILDINT)

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
        [tos(availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN])] 		= settings.splitLockDynFilter,
        --========= GEAR SETS CONTEXT MENU =============================================
        [tos(availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS])] 	= settings.splitGearSetsFilter,
        --========= RESEARCH & DECONSTRUCTION & IMPORVEMENT CONTEXT MENU =============================
        [tos(availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP])] 	= settings.splitResearchDeconstructionImprovementFilter,
        --========= SELL & SELL AT GUILD STORE & INTRICATE CONTEXT MENU =============================
        [tos(availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT])] = settings.splitSellGuildSellIntricateFilter,
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
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].lastIcon 			= settingsOfFilterButtonStateAndIcon.lastLockDynFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].cmFilterName 		= contextMenu.ContextMenuLockDynFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].mappingIcons 		= mappingVars.lockDynToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_LOCKDYN]].pVars 			    = preventerVars.gLockDynFilterContextCreated
    --Gear
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].cmAtPanel 		    = contextMenu.GearSetFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].cmVars 			= contextMenuVars.GearSetFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].lastIcon 		   	= settingsOfFilterButtonStateAndIcon.lastGearFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].cmFilterName 		= contextMenu.ContextMenuGearSetFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].mappingIcons 		= mappingVars.gearToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_GEARSETS]].pVars 			    = preventerVars.gGearSetFilterContextCreated
    --ResDecImp
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].cmAtPanel 		= contextMenu.ResDecImpFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].cmVars 			= contextMenuVars.ResDecImpFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].lastIcon 		    = settingsOfFilterButtonStateAndIcon.lastResDecImpFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].cmFilterName 	    = contextMenu.ContextMenuResDecImpFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].mappingIcons 	    = mappingVars.resDecImpToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_RESDECIMP]].pVars 			= preventerVars.gResDecImpFilterContextCreated
    --SellGuildInt
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].cmAtPanel 	    = contextMenu.SellGuildIntFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].cmVars 		= contextMenuVars.SellGuildIntFilter
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].lastIcon 		= settingsOfFilterButtonStateAndIcon.lastSellGuildIntFilterIconId
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].cmFilterName	= contextMenu.ContextMenuSellGuildIntFilterName
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].mappingIcons	= mappingVars.sellGuildIntToIcon
    ctmVars[availableCtms[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]].pVars 		    = preventerVars.gSellGuildIntFilterContextCreated
    --for each available contextmenu (at filter buttons) build the needed arrays
    for ctmNumber=1, #availableCtms, 1 do
        local ctmName = availableCtms[ctmNumber]
        ctmVars[ctmName].buttonTemplate 		= ctmVars[ctmName].cmVars.buttonContextMenuToIconId
        ctmVars[ctmName].buttonTemplateIndex 	= ctmVars[ctmName].cmVars.buttonContextMenuToIconIdIndex
    end

    --Added with FCOIS v2.0.3
    --Build the iconSortOrderEntries table for the settings menu -> LAM2 widget "order list box"
    --local optionsIcon = "options_icon"
    --local tooltipSuffix = "_TT"
    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
    local iconsListStandard, iconsListValuesStandard = FCOIS.GetLAMMarkerIconsDropdown("standard", true, false)

    FCOIS.settingsVars.defaults.iconSortOrderEntries = {}
    for currentSortIdx, iconNumber in ipairs(defaults.iconSortOrder) do
        if settings.isIconEnabled[iconNumber] then
            --[[
                --Example entry
                [1] = {
                    value = "Value of the entry", -- or number or boolean or function returning the value of this entry
                    uniqueKey = 1, --number of the unique key of this list entry. This will not change if the order changes. Will be used to identify the entry uniquely
                    text  = "Text of this entry", -- or string id or function returning a string (optional)
                    tooltip = "Tooltip text shown at this entry", -- or string id or function returning a string (optional)
                },
            ]]

            local iconIndex = ZO_IndexOfElementInNumericallyIndexedTable(iconsListValuesStandard, iconNumber)
            local name = iconsListStandard[iconIndex] or "Icon " ..tos(iconNumber)
            local tooltip = name

            FCOIS.settingsVars.defaults.iconSortOrderEntries[currentSortIdx] = {
                uniqueKey	= iconNumber,
                value		= iconNumber,
                text 		= name,
                tooltip 	= tooltip,
            }
        end
    end
    if not settings.iconSortOrderEntries or (settings.iconSortOrderEntries and #settings.iconSortOrderEntries == 0) then
        FCOIS.settingsVars.settings.iconSortOrderEntries = FCOIS.settingsVars.defaults.iconSortOrderEntries
    end

    --Added with FCOIS v2.5.6 - #278
    --Build the markerIconsOutputOrder table for the settings menu -> LAM2 widget "order list box"
    FCOIS.settingsVars.defaults.markerIconsOutputOrderEntries = {}
    for currentSortIdx, iconNumber in ipairs(defaults.iconSortOrder) do
        --if settings.isIconEnabled[iconNumber] then
        --[[
            --Example entry
            [1] = {
                value = "Value of the entry", -- or number or boolean or function returning the value of this entry
                uniqueKey = 1, --number of the unique key of this list entry. This will not change if the order changes. Will be used to identify the entry uniquely
                text  = "Text of this entry", -- or string id or function returning a string (optional)
                tooltip = "Tooltip text shown at this entry", -- or string id or function returning a string (optional)
            },
        ]]

        local iconIndex = ZO_IndexOfElementInNumericallyIndexedTable(iconsListValuesStandard, iconNumber)
        local name = iconsListStandard[iconIndex] or "Icon " ..tos(iconNumber)
        local tooltip = name

        FCOIS.settingsVars.defaults.markerIconsOutputOrderEntries[currentSortIdx] = {
            uniqueKey	= iconNumber,
            value		= iconNumber,
            text 		= name,
            tooltip 	= tooltip,
        }
        --end
    end
    if not settings.markerIconsOutputOrderEntries or (settings.markerIconsOutputOrderEntries and #settings.markerIconsOutputOrderEntries == 0) then
--d("[FCOIS]Loading SavedVars' markerIconsOutputOrderEntries from defaults!")
        FCOIS.settingsVars.settings.markerIconsOutputOrderEntries = FCOIS.settingsVars.defaults.markerIconsOutputOrderEntries
    end
    --This new sortOrderOutputSetting was not opened in LAM menu yet (first login with new data e.g.)?
    if ZO_IsTableEmpty(settings.markerIconsOutputOrder) then
--d("[FCOIS]Loading SavedVars' markerIconsOutputOrder from markerIconsOutputOrderEntries!")
        for idx, data in ipairs(FCOIS.settingsVars.settings.markerIconsOutputOrderEntries) do
            FCOIS.settingsVars.settings.markerIconsOutputOrder[idx] = data.value
        end
    end


    --Added with FCOIS v2.1.0 - Bag scan order for automatic marks
    for _, defaultData in ipairs(FCOIS.settingsVars.defaults.autoMarkBagsToScanOrder) do
        if defaultData.uniqueKey ~= nil then
            local textVar = locVars["FCOIS_LibFilters_PanelIds"][defaultData.uniqueKey]
            defaultData.text = textVar
            defaultData.tooltip = textVar
        end
    end

    if not settings.autoMarkBagsToScanOrder or (settings.autoMarkBagsToScanOrder and #settings.autoMarkBagsToScanOrder == 0) then
        FCOIS.settingsVars.settings.autoMarkBagsToScanOrder = ZO_ShallowTableCopy(FCOIS.settingsVars.defaults.autoMarkBagsToScanOrder)
    else
        if settings.autoMarkBagsToScanOrder and #settings.autoMarkBagsToScanOrder > 0 then
            --Default values were added here and are missing in the settings? Add them
            if #FCOIS.settingsVars.defaults.autoMarkBagsToScanOrder ~= #settings.autoMarkBagsToScanOrder then
                for _, defaultData in ipairs(FCOIS.settingsVars.defaults.autoMarkBagsToScanOrder) do
                    local found = false
                    for _, settingsData in ipairs(settings.autoMarkBagsToScanOrder) do
                        if not found and settingsData.uniqueKey == defaultData.uniqueKey then
                            found = true
                            break
                        end
                    end
                    if found == false then
                        tabins(FCOIS.settingsVars.settings.autoMarkBagsToScanOrder, defaultData)
                    end
                end
            end

            --Update missing text and tooltips
            for _, entryData in ipairs(settings.autoMarkBagsToScanOrder) do
                local uniqueKey = entryData.uniqueKey
                if uniqueKey ~= nil and (entryData.text == nil or entryData.text == "") then
                    local textVar = locVars["FCOIS_LibFilters_PanelIds"][uniqueKey]
                    entryData.text = textVar
                    entryData.tooltip = textVar
                end
            end
        end
    end
end

--Localized texts etc.
function FCOIS.Localization()
    local preventerVars = FCOIS.preventerVars
    local defSettings = FCOIS.settingsVars.defaultSettings
    local settings = FCOIS.settingsVars.settings
    local alwaysUseClientLang = settings.alwaysUseClientLanguage
    local langVars = FCOIS.langVars
    local colorIconEndStr   = FCOIS_CON_ICON_SUFFIX_COLOR
    local nameIconEndStr    = FCOIS_CON_ICON_SUFFIX_NAME

--d("[FCOIS] Localization - Start, keybindings: " .. tos(preventerVars.KeyBindingTexts) ..", useClientLang: " .. tos(alwaysUseClientLang) .. ", localizationDone: " ..tos(preventerVars.gLocalizationDone))

    --Was localization already done during keybindings? Then abort here
    -->Settings at keybindings are not loaded properly as it happens before EVENT_ADD_ON_LOADED and SavedVariables were not "there" already
    -->So we cannot abort here and need to update the texts again at least once properly -> preventerVars.gLocalizationDone check alone !
    if preventerVars.KeyBindingTexts == true and preventerVars.gKeybindingLocalizationDone == true then
        preventerVars.KeyBindingTexts = false
        return
    end
    --Abort here if localization was done at least once properly already to the end of this function, including afterLocalization etc.
    -->Exclude a forced update of the localization variables via preventerVars.doUpdateLocalization
    if preventerVars.gLocalizationDone == true and not preventerVars.doUpdateLocalization then
        return
    end

    --Fallback to english variable
    local fallbackToEnglish = false
    --Always use the client's language?
    if not alwaysUseClientLang then
        --Was a language chosen already?
        if not settings.languageChosen then
--d(">Fallback to english. Keybindings: " .. tos(preventerVars.KeyBindingTexts) .. ", language chosen: " .. tos(settings.languageChosen) .. ", defaultLanguage: " .. tos(defSettings.language))
            if defSettings.language == nil then
--d(">>defaultSettings.language is NIL -> Fallback to english now")
                fallbackToEnglish = true
            else
                --Is the languages array filled and the language is not valid (not in the language array with the value "true")?
                if langVars.languages ~= nil and #langVars.languages > 0 and not langVars.languages[defSettings.language] then
                    fallbackToEnglish = true
--d(">>defaultSettings.language is ~= " .. tos(defSettings.language) .. ", and this language # is not valid -> Fallback to english now")
                end
            end
        end
    end
--d(">fallBackToEnglish: " .. tos(fallbackToEnglish))
    --Fallback to english language now
    if fallbackToEnglish then defSettings.language = FCOIS_CON_LANG_EN end
    --Is the standard language english set?
    if alwaysUseClientLang or (defSettings.language == FCOIS_CON_LANG_EN and not settings.languageChosen) then
--d(">>Language chosen is false or always use client language is true!")
        --Check for supported languages
        local lang = FCOIS.clientLanguage
        local langStrToLangConstant = FCOIS.mappingVars.langStrToLangConstant
        defSettings.language = langStrToLangConstant[lang] or FCOIS_CON_LANG_EN
    end
    if settings.debug then debugMessage( "[Localization]","default settings, language: " .. tos(defSettings.language), false) end
--d(">default settings, language: " .. tos(defSettings.language))
    --Get the localized texts from the localization file
    local locVars = FCOIS.localizationVars
    FCOIS.localizationVars.fcois_loc = locVars.localizationAll[defSettings.language]
--d(">got here: locVars.fcois_loc was overwritten!")

    --The localization end string array
    FCOIS.localizationVars.iconEndStrArray = {
        [1]  = colorIconEndStr,
        [2]  = nameIconEndStr,
        [3]  = colorIconEndStr,
        [4]  = nameIconEndStr,
        [5]  = colorIconEndStr,
        [6]  = nameIconEndStr,
        [7]  = nameIconEndStr,
        [8]  = nameIconEndStr,
        [9]  = colorIconEndStr,
        [10] = colorIconEndStr,
        [11] = colorIconEndStr,
        [12] = colorIconEndStr,
        --Dynamic icons
        -->Added dynamically in this function, a bit more to the bottom in the source code
    }

    --Abort here if we only needed the keybinding texts, as further down other texts are build (marker icons, settings menu, etc.)
    if preventerVars.KeyBindingTexts == true then
        preventerVars.gKeybindingLocalizationDone = true
        preventerVars.KeyBindingTexts = false
        return
    end

--d(">>>>> Building localization for settingsMenu and markerIcons etc.")
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
    --Remove all/Restore last marker icons
    contextEntries.menu_remove_all_icons_text  	= locTexts["rightclick_menu_remove_all"]
    contextEntries.menu_restore_last_icons_text	= locTexts["rightclick_menu_restore_last"]
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
            tabins(FCOIS.localizationVars.iconEndStrArray, colorIconEndStr)
            --Add dynamic right click menu
            tabins(contextEntries.menu_add_dynamic_text,      locTexts["rightclick_menu_mark_dynamic" .. tos(dynIconNr)])
            --Remove dynamic right click menu
            tabins(contextEntries.menu_remove_dynamic_text,   locTexts["rightclick_menu_demark_dynamic".. tos(dynIconNr)])
            --Add all dynamic right click menu
            tabins(contextEntries.menu_add_all_text,          locTexts["button_context_menu_mark_all_as_dynamic".. tos(dynIconNr)])
            --remove all dynamic right click menu
            tabins(contextEntries.menu_remove_all_text,       locTexts["button_context_menu_unmark_all_as_dynamic".. tos(dynIconNr)])
        end
    end
    --Set the alert message texts as an item gets checked against anti-* (localized!)
    FCOIS.mappingVars.whereAreWeToAlertmessageText = {
        [FCOIS_CON_DESTROY]				=	locTexts["destroying_not_allowed"],
        [FCOIS_CON_COMPANION_DESTROY]	=	locTexts["destroying_not_allowed"],
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

    --The medium part of the outputText at the filterButtons (context menu tooltip e.g.)
    FCOIS.mappingVars.filterPanelToFilterButtonMediumOutputText = {
        [LF_INVENTORY]                          = locTexts["filter_inventory"],
        [LF_BANK_DEPOSIT]                       = locTexts["filter_inventory"],
        [LF_GUILDBANK_DEPOSIT]                  = locTexts["filter_inventory"],
        [LF_HOUSE_BANK_DEPOSIT]                 = locTexts["filter_inventory"],
        [LF_CRAFTBAG]                           = locTexts["filter_craftbag"],
        [LF_GUILDBANK_WITHDRAW]                 = locTexts["filter_guildbank"],
        [LF_GUILDSTORE_SELL]                    = locTexts["filter_guildstore"],
        [LF_BANK_WITHDRAW]                      = locTexts["filter_bank"],
        [LF_SMITHING_REFINE]                    = locTexts["filter_refinement"],
        [LF_SMITHING_DECONSTRUCT]               = locTexts["filter_deconstruction"],
        [LF_SMITHING_IMPROVEMENT]               = locTexts["filter_improvement"],
        [LF_SMITHING_RESEARCH]                  = locTexts["filter_research"],
        [LF_SMITHING_RESEARCH_DIALOG]           = locTexts["filter_research"],
        [LF_JEWELRY_REFINE]                     = locTexts["filter_jewelry_refinement"],
        [LF_JEWELRY_DECONSTRUCT]                = locTexts["filter_jewelry_deconstruction"],
        [LF_JEWELRY_IMPROVEMENT]                = locTexts["filter_jewelry_improvement"],
        [LF_JEWELRY_RESEARCH]                   = locTexts["filter_jewelry_research"],
        [LF_JEWELRY_RESEARCH_DIALOG]            = locTexts["filter_jewelry_research"],
        [LF_ENCHANTING_EXTRACTION]              = locTexts["filter_enchantingstation_extraction"],
        [LF_ENCHANTING_CREATION]                = locTexts["filter_enchantingstation_creation"],
        [LF_VENDOR_BUY]                         = locTexts["filter_buy"],
        [LF_VENDOR_SELL]                        = locTexts["filter_store"],
        [LF_VENDOR_BUYBACK]                     = locTexts["filter_buyback"],
        [LF_VENDOR_REPAIR]                      = locTexts["filter_repair"],
        [LF_FENCE_SELL]                         = locTexts["filter_fence"],
        [LF_FENCE_LAUNDER]                      = locTexts["filter_launder"],
        [LF_MAIL_SEND]                          = locTexts["filter_mail"],
        [LF_TRADE]                              = locTexts["filter_trade"],
        [LF_ALCHEMY_CREATION]                   = locTexts["filter_alchemy"],
        [LF_RETRAIT]                            = locTexts["filter_retrait"],
        [LF_HOUSE_BANK_WITHDRAW]                = locTexts["filter_house_bank"],
        [LF_INVENTORY_COMPANION]                = locTexts["filter_companion_inventory"],
    }

    --Add the local localized tables from the constants, e.g. the ItemTypes subTable for the LibShifterBox uniqueId itemTypes
    local localLocalizationsVars = FCOIS.localLocalizationsVars
    if localLocalizationsVars ~= nil then
        for key, valueTab in pairs(localLocalizationsVars) do
            if locVars.fcois_loc[key] == nil then
                FCOIS.localizationVars.fcois_loc[key] = ZO_ShallowTableCopy(valueTab)
            end
        end
    end

    --Do some "after localization" stuff
    afterLocalization()

    --Reset the variable for the "force localization update"
    FCOIS.preventerVars.doUpdateLocalization = false

    --Localization was done at least once properly now
    FCOIS.preventerVars.gLocalizationDone = true
end
local localization = FCOIS.Localization

--Get the localized filterPanel translation of the LibFilters 3.0 filterPanel constants LF*
function FCOIS.GetFilterPanelIdText(filterPanelId)
    filterPanelId = filterPanelId or FCOIS.gFilterWhere
    local preventerVars = FCOIS.preventerVars
    if not preventerVars.gLocalizationDone then
        localization()
    end
    local locVars = FCOIS.localizationVars.fcois_loc
    local retText = locVars and locVars["FCOIS_LibFilters_PanelIds"] and locVars["FCOIS_LibFilters_PanelIds"][filterPanelId] or "n/a"
    return retText
end
