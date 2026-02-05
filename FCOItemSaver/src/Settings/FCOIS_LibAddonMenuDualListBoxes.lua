--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

local strformat = string.format

local FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES  = FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES
local FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS             = FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS
local FCOIS_CON_LIBSHIFTERBOX_FCOISALLOWEXCLUSION_MAIL = FCOIS_CON_LIBSHIFTERBOX_FCOISALLOWEXCLUSION_MAIL

local addonVars = FCOIS.addonVars
local addonName = addonVars.gAddonName
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons

local getSavedVarsMarkedItemsTableName = FCOIS.GetSavedVarsMarkedItemsTableName
local showItemLinkTooltip = FCOIS.ShowItemLinkTooltip
local hideItemLinkTooltip = FCOIS.HideItemLinkTooltip
local getIconText = FCOIS.GetIconText


if not FCOIS.libShifterBox then return end
local lsb = FCOIS.libShifterBox

local FCOISlocVars = FCOIS.localizationVars
local locVars      = FCOISlocVars.fcois_loc

FCOIS.LibShifterBoxes = {}

--The LibShifterBoxes FCOIS uses:
--The box for the LAM settings panel FCOIS uniqueId itemTypes
local FCOISuniqueIdItemTypes = FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES   --FCOISuniqueIdItemTypes
local FCOISexcludedSets      = FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS              --FCOISexcludedSets
local FCOISallowExclusionMail = FCOIS_CON_LIBSHIFTERBOX_FCOISALLOWEXCLUSION_MAIL --FCOISallowExclusionMail --#311

local libShifterBoxesWerePrepared = false
local function prepareFCOISLibShifterBoxes()
    if libShifterBoxesWerePrepared then return FCOIS.LibShifterBoxes end

    locVars = FCOISlocVars.fcois_loc

    local libShifterBoxes = {
        --ShortName = LAM control global name/reference
        --Itemtypes for FCOIS created uniqueIds
        [FCOISuniqueIdItemTypes] = {
            name = addonName .. "_LAM_CUSTOM___FCOIS_UNIQUEID_ITEMTYPES",
            customSettings = {
                leftList = {
                    title = locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_TITLE_LEFT"],
                },
                rightList = {
                    title = locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_TITLE_RIGHT"],
                },
                search = { enabled = true }, --#315
            },
            width       = 580,
            height      = 200,
            --Right's list default entries
            defaultRightListKeys = {
                ITEMTYPE_WEAPON, ITEMTYPE_ARMOR
            },
            --Controls
            lamCustomControl = nil,
            control = nil,
        },
        --Exclude sets
        [FCOISexcludedSets] = {
            name = addonName .. "_LAM_CUSTOM___FCOIS_EXCLUDED_SETS",
            customSettings = {
                leftList = {
                    title = locVars["options_exclude_automark_sets_included"],
                },
                rightList = {
                    title = locVars["options_exclude_automark_sets_list"],
                },
                search = { enabled = true }, --#315
            },
            width       = 450,
            height      = 200,
            --Right's list default entries
            defaultRightListKeys = {
            },
            --Controls
            lamCustomControl = nil,
            control = nil,
        },
        --Allow non-dynamic marker icons to exclude mail protection
        [FCOISallowExclusionMail] = {
            name = addonName .. "_LAM_CUSTOM___FCOIS_ALLOWEXCLUSION_MAIL",
            customSettings = {
                leftList = {
                    title = locVars["LIBSHIFTERBOX_FCOIS_ALLOWEXCLUSION_MAIL_TITLE_LEFT"],
                },
                rightList = {
                    title = locVars["LIBSHIFTERBOX_FCOIS_ALLOWEXCLUSION_MAIL_TITLE_RIGHT"],
                },
                search = { enabled = true }, --#315
            },
            width       = 450,
            height      = 150,
            --Right's list default entries
            defaultRightListKeys = {
            },
            --Controls
            lamCustomControl = nil,
            control = nil,
        },
    }
    FCOIS.LibShifterBoxes = libShifterBoxes
    libShifterBoxesWerePrepared = true
    return FCOIS.LibShifterBoxes
end
FCOIS.prepareFCOISLibShifterBoxes = prepareFCOISLibShifterBoxes



local function getLeftListEntriesFull(shifterBox)
    if not shifterBox then return end
    return shifterBox:GetLeftListEntriesFull()
end

local function getRightListEntriesFull(shifterBox)
    if not shifterBox then return end
    return shifterBox:GetRightListEntriesFull()
end

local function getBoxName(shifterBox)
    if not shifterBox then return end
    local libShifterBoxes = FCOIS.LibShifterBoxes
    for k, dataTab in pairs(libShifterBoxes) do
        if dataTab.control ~= nil and dataTab.control == shifterBox then
            return k
        end
    end
    return nil
end

local function checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
    if shifterBox and rightListEntries and NonContiguousCount(rightListEntries) == 0 then
        d(FCOIS.preChatVars.preChatTextRed .. locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_RIGHT_NON_EMPTY"])
        local defaultRightListKeys = shifterBoxData and shifterBoxData.defaultRightListKeys
        if defaultRightListKeys and #defaultRightListKeys > 0 then
            shifterBox:MoveEntriesToRightList(defaultRightListKeys)
        end
    end
end

local function myShifterBoxEventEntryMovedCallbackFunction(shifterBox, key, value, categoryId, isDestListLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--d("LSB FCOIS, boxName: " ..tostring(boxName))
    if not boxName or boxName == "" then return end
    local libShifterBoxes = FCOIS.LibShifterBoxes
    local shifterBoxData = libShifterBoxes[boxName]

    --Moved to the ?
    if isDestListLeftList == true then
        if boxName == FCOISuniqueIdItemTypes then
            --Moved to the left? Set SavedVariables value nil
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = nil
            --Check if any entry is left in the right list. If not:
            --Add the default values weapons and armor again and output a chat message.
            local rightListEntries = shifterBox:GetRightListEntriesFull()
            checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)

        elseif boxName == FCOISexcludedSets then
            hideItemLinkTooltip()
            --Moved to the left? Set SavedVariables value nil
            FCOIS.settingsVars.settings.autoMarkSetsExcludeSetsList[key] = nil
        elseif boxName == FCOISallowExclusionMail then --#311
            hideItemLinkTooltip()
            --Moved to the left? Set SavedVariables value nil
            FCOIS.settingsVars.settings.allowExclusionMailFor[key] = nil
        end
    else
        if boxName == FCOISuniqueIdItemTypes then
            --Moved to the right? Save to SavedVariables with value true
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = true

        elseif boxName == FCOISexcludedSets then
            hideItemLinkTooltip()
            --Moved to the right? Save to SavedVariables with value true
            FCOIS.settingsVars.settings.autoMarkSetsExcludeSetsList[key] = true
        elseif boxName == FCOISallowExclusionMail then --#311
            hideItemLinkTooltip()
            --Moved to the right? Set SavedVariables value true
            FCOIS.settingsVars.settings.allowExclusionMailFor[key] = true
        end
    end
end

--[[
local function myShifterBoxEventEntryHighlightedCallbackFunction(control, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
    if not boxName or boxName == "" then return end

FCOIS._lsbHighlightedControl = control

    if isLeftList == true then
        if boxName == FCOISuniqueIdItemTypes then

        end
    else
        if boxName == FCOISuniqueIdItemTypes then

        end
    end
end
]]

local function updateLibShifterBoxEntries(parentCtrl, shifterBox, boxName)
    if not parentCtrl or not boxName or boxName == "" then return end
    local libShifterBoxes = FCOIS.LibShifterBoxes
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end
    local settings = FCOIS.settingsVars.settings

    local clientLang = FCOIS.clientLanguage


    local leftListEntries = {}
    local rightListEntries = {}

    --FCOIS custom UniqueId
    if boxName == FCOISuniqueIdItemTypes then
        if not FCOISlocVars then FCOISlocVars = FCOIS.localizationVars end
        if not locVars or not locVars.ItemTypes then locVars = FCOISlocVars.fcois_loc end
        local itemTypes = locVars.ItemTypes

        local allowedFCOISUniqueIdItemTypes = settings.allowedFCOISUniqueIdItemTypes
        for k,v in pairs(allowedFCOISUniqueIdItemTypes) do
            if v == true then
                rightListEntries[k] = strformat("%s [%s]", itemTypes[k], tostring(k))
            else
                leftListEntries[k] = strformat("%s [%s]", itemTypes[k], tostring(k))
            end
        end

        --Excluded sets
    elseif boxName == FCOISexcludedSets then
        --LibSets is given?
        local libSets = FCOIS.libSets
        if libSets then --#304
            local allSetNames = libSets.GetAllSetNames()
            if allSetNames ~= nil then
                local autoMarkSetsExcludeSetsList = settings.autoMarkSetsExcludeSetsList
                for setId, setNamesTable in pairs(allSetNames) do
                    --local setItemId = libSets.GetSetItemId(setId)
                    -->How to add this to the data table of setNamesTable[clientLang] which will be added via AddEntriesToLeftList
                    -->Currently not possible with LibShifterBox
                    if autoMarkSetsExcludeSetsList[setId]~= nil then
                        rightListEntries[setId] = setNamesTable[clientLang]
                    else
                        leftListEntries[setId] = setNamesTable[clientLang]
                    end
                end
            end
        end
    --Allow mail --#311
    elseif boxName == FCOISallowExclusionMail then --#311
        local mappingVars = FCOIS.mappingVars
        local iconIsDynamic = mappingVars.iconIsDynamic
        if iconIsDynamic ~= nil then
            local allowExclusionMailFor = settings.allowExclusionMailFor
            local iconIsGear = settings.iconIsGear
            local optionsIcon = "options_icon"

            getIconText = getIconText or FCOIS.GetIconText

            for markerIconId, isDynamic in pairs(iconIsDynamic) do
                if not isDynamic and not iconIsGear[markerIconId] then
                    local locNameStr = FCOISlocVars.iconEndStrArray[markerIconId]
                    local markerIconName = getIconText(markerIconId, true, true, false) or locVars[optionsIcon .. tostring(markerIconId) .. "_" .. locNameStr] or "Icon " .. tostring(markerIconId)

                    if allowExclusionMailFor[markerIconId] ~= nil then
                        rightListEntries[markerIconId] = markerIconName
                    else
                        leftListEntries[markerIconId] = markerIconName
                    end
                end
            end
        end
    end
    shifterBox:ClearLeftList()
    shifterBox:AddEntriesToLeftList(leftListEntries)

    shifterBox:ClearRightList()
    shifterBox:AddEntriesToRightList(rightListEntries)

    if boxName == FCOISuniqueIdItemTypes then
        checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
    end
end

local function updateLibShifterBoxState(parentCtrl, shifterBox, boxName)
    if not parentCtrl or not boxName or boxName == "" then return end
    local libShifterBoxes = FCOIS.LibShifterBoxes
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end

    local settings = FCOIS.settingsVars.settings

    local isEnabled = true
    --FCOIS uniqueId itemTypes
    if boxName == FCOISuniqueIdItemTypes then
        isEnabled = FCOIS.uniqueIdIsEnabledAndSetToFCOIS()
    elseif boxName == FCOISexcludedSets then
        isEnabled = (FCOIS.libSets ~= nil and settings.autoMarkSetsExcludeSets == true) or false --#304
    elseif boxName == FCOISallowExclusionMail then --#311
        isEnabled = (settings.allowExclusionMail == true) or false --#311
    end

    parentCtrl:SetHidden(false)
    parentCtrl:SetMouseEnabled(isEnabled)
    shifterBox:SetHidden(false)
    shifterBox:SetEnabled(isEnabled)
end
FCOIS.updateLibShifterBoxState = updateLibShifterBoxState

local function myShifterBoxEventEntryHighlightedCallbackFunction(selectedRow, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--df("LSB FCOIS, boxName: %s, key: %s, value: %s", tostring(boxName), tostring(key), tostring(value))
    if not boxName or boxName == "" then return end

    if boxName == FCOISexcludedSets then
        local anchorVar1 = RIGHT
        local anchorVar2 = LEFT
        if not isLeftList then
            anchorVar1 = LEFT
            anchorVar2 = RIGHT
        end
        showItemLinkTooltip(selectedRow, selectedRow, anchorVar1, 5, 0, anchorVar2)
    end
end

local function myShifterBoxEventEntryUnHighlightedCallbackFunction(selectedRow, shifterBox, key, value, categoryId, isLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--d("LSB FCOIS, boxName: " ..tostring(boxName))
    if not boxName or boxName == "" then return end

    if boxName == FCOISexcludedSets then
        hideItemLinkTooltip()
    end
end

local function updateLibShifterBox(parentCtrl, shifterBox, boxName)
    if not parentCtrl or not boxName or boxName == "" then return end
    local libShifterBoxes = FCOIS.LibShifterBoxes
    local shifterBoxData = libShifterBoxes[boxName]
    if not shifterBoxData then return end
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end

    parentCtrl:SetResizeToFitDescendents(true)

    shifterBox:SetAnchor(TOPLEFT, parentCtrl, TOPLEFT, 0, 0) -- will automatically call ClearAnchors
    shifterBox:SetDimensions(shifterBoxData.width, shifterBoxData.height)

    --Add the entries to the left and right shifter box
    updateLibShifterBoxEntries(parentCtrl, shifterBox, boxName)
    --Update the enabled state of the shifter box
    updateLibShifterBoxState(parentCtrl, shifterBox, boxName)

    --Add the callback function to the entry was moved event
    shifterBox:RegisterCallback(lsb.EVENT_ENTRY_MOVED,          myShifterBoxEventEntryMovedCallbackFunction)
    --Add the callback as an entry was highlighted at the left side
    shifterBox:RegisterCallback(lsb.EVENT_ENTRY_HIGHLIGHTED,    myShifterBoxEventEntryHighlightedCallbackFunction)
    shifterBox:RegisterCallback(lsb.EVENT_ENTRY_UNHIGHLIGHTED,  myShifterBoxEventEntryUnHighlightedCallbackFunction)
end

------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Create a LibShifterBox for e.g. LAM settings panel
function FCOIS.createLibShifterBox(customControl, boxName)
    if not customControl or not boxName or boxName == "" then return end

    prepareFCOISLibShifterBoxes()
    local libShifterBoxes = FCOIS.LibShifterBoxes
    local boxData = libShifterBoxes[boxName]
    if not boxData then return end

    libShifterBoxes[boxName].lamCustomControl = customControl
                         --uniqueAddonName, uniqueShifterBoxName, parentControl, customSettings, anchorOptions, dimensionOptions, leftListEntries, rightListEntries
    local shifterBox = lsb(addonName, boxName .. "_LSB", customControl, boxData.customSettings, nil, nil, nil, nil)
    libShifterBoxes[boxName].control = shifterBox

    --Update the shifter box entries and state
    updateLibShifterBox(customControl, shifterBox, boxName)
end