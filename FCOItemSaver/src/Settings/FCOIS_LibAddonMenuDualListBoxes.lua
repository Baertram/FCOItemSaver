--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

local strformat = string.format
local tos = tostring

local addonVars = FCOIS.addonVars
local addonName = addonVars.gAddonName
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local getSavedVarsMarkedItemsTableName = FCOIS.GetSavedVarsMarkedItemsTableName
local showItemLinkTooltip = FCOIS.ShowItemLinkTooltip
local hideItemLinkTooltip = FCOIS.HideItemLinkTooltip

if not FCOIS.libShifterBox then return end
local lsb = FCOIS.libShifterBox
local libShifterBoxes

local FCOISlocVars = FCOIS.localizationVars
local locVars      = FCOISlocVars.fcois_loc

--The LibShifterBoxes FCOIS uses:
--The box for the LAM settings panel FCOIS uniqueId itemTypes
local FCOISuniqueIdItemTypes = FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES   --FCOISuniqueIdItemTypes
local FCOISexcludedSets      = FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS              --FCOISexcludedSets

------------------------------------------------------------------------------------------------------------------------

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
    for k, dataTab in pairs(libShifterBoxes) do
        if dataTab.control ~= nil and dataTab.control == shifterBox then
            return k
        end
    end
    return nil
end

local function checkAndUpdateRightListDefaultEntries(shifterBox, shifterBoxData)
    if shifterBox then
        local rightListEntries = shifterBox:GetRightListEntriesFull()
        if rightListEntries and NonContiguousCount(rightListEntries) == 0 then
            d(FCOIS.preChatVars.preChatTextRed .. locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_RIGHT_NON_EMPTY"])
            local defaultRightListKeys = shifterBoxData and shifterBoxData.defaultRightListKeys
            if defaultRightListKeys and #defaultRightListKeys > 0 then
                shifterBox:MoveEntriesToRightList(defaultRightListKeys)
            end
        end
    end
end

local function myShifterBoxEventEntryMovedCallbackFunction(shifterBox, key, value, categoryId, isDestListLeftList)
    if not shifterBox or not key then return end
    local boxName = getBoxName(shifterBox)
--d("LSB FCOIS, boxName: " ..tostring(boxName))
    if not boxName or boxName == "" then return end
    local shifterBoxData = libShifterBoxes[boxName]

    --Moved to the ?
    if isDestListLeftList == true then
        if boxName == FCOISuniqueIdItemTypes then
            --Moved to the left? Set SavedVariables value nil
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = nil
            --Check if any entry is left in the right list. If not:
            --Add the default values weapons and armor again and output a chat message.
            checkAndUpdateRightListDefaultEntries(shifterBox, shifterBoxData)

        elseif boxName == FCOISexcludedSets then
            hideItemLinkTooltip()
            --Moved to the left? Set SavedVariables value nil
            FCOIS.settingsVars.settings.autoMarkSetsExcludeSetsList[key] = nil
        end
    else
        if boxName == FCOISuniqueIdItemTypes then
            --Moved to the right? Save to SavedVariables with value true
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = true

        elseif boxName == FCOISexcludedSets then
            hideItemLinkTooltip()
            --Moved to the right? Save to SavedVariables with value true
            FCOIS.settingsVars.settings.autoMarkSetsExcludeSetsList[key] = true
        end
    end
end


local function updateLibShifterBoxEntries(parentCtrl, shifterBox, boxName)
    if not parentCtrl or not boxName or boxName == "" then return end
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end
    local settings = FCOIS.settingsVars.settings

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
        if FCOIS.libSets then
            local libSets = FCOIS.libSets
            local allSetNames = libSets.GetAllSetNames()
            local clientLang = FCOIS.clientLanguage
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
    end
    shifterBox:ClearLeftList()
    shifterBox:AddEntriesToLeftList(leftListEntries)

    shifterBox:ClearRightList()
    shifterBox:AddEntriesToRightList(rightListEntries)

    if boxName == FCOISuniqueIdItemTypes then
        checkAndUpdateRightListDefaultEntries(shifterBox, shifterBoxData)
    end
end

local function updateLibShifterBoxState(parentCtrl, shifterBox, boxName)
    if not parentCtrl or not boxName or boxName == "" then return end
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end

    local isEnabled = true
    --FCOIS uniqueId itemTypes
    if boxName == FCOISuniqueIdItemTypes then
        isEnabled = FCOIS.uniqueIdIsEnabledAndSetToFCOIS()
    elseif boxName == FCOISexcludedSets then
        isEnabled = (FCOIS.libSets ~= nil and FCOIS.settingsVars.settings.autoMarkSetsExcludeSets == true) or false
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



local function FCOISUniqueItemIdShifterBoxEventEntryMovedCallbackFunction(shifterBox, key, value, categoryId, isDestListLeftList)
--d("[FCOIS]Move entry LibShifterBox UniqueItemIds-key: " ..tos(key) .. ", value: " ..tos(value) .. ", toLeft: " ..tos(isDestListLeftList))
end



-----------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
-- The ShifterBox data for the LibAddonMenu widget LibAddonMenuDualListBox
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
FCOIS.LibShifterBoxes = {
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
            --[[
            callbackRegister = {
                --Add the callback function to the entry was moved event
                [lsb.EVENT_ENTRY_MOVED] = FCOISUniqueItemIdShifterBoxEventEntryMovedCallbackFunction,
            },
            ]]
        },
        width       = 580,
        height      = 200,
        --Right's list default entries
        --[[
        defaultRightListKeys = {
          ITEMTYPE_WEAPON, ITEMTYPE_ARMOR
        },
        ]]

        --Getter and setter
        -->The following 2 tables here are only locally used to store the visual table entries of the left and right lists.
        -->The real data is saved at the SavedVariable via 1 table, named "allowedFCOISUniqueIdItemTypes"
        currentLeftListEntries = {},
        currentRightListEntries = {},
        getFuncOfList = function(isLeftList)
d("[FCOIS]getFuncOfList-isLeftList: " ..tos(isLeftList))

            --Read FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes
            local settings = FCOIS.settingsVars.settings
            if isLeftList == nil or settings == nil then return end

            if not FCOISlocVars then FCOISlocVars = FCOIS.localizationVars end
            if not locVars or not locVars.ItemTypes then locVars = FCOISlocVars.fcois_loc end
            local itemTypes = locVars.ItemTypes

            if isLeftList == true then
d(">leftList")
                local currentLeftListEntries = FCOIS.LibShifterBoxes[FCOISuniqueIdItemTypes].currentLeftListEntries

                local allowedFCOISUniqueIdItemTypesLeftList = settings.allowedFCOISUniqueIdItemTypesLeftList
                for k,v in pairs(allowedFCOISUniqueIdItemTypesLeftList) do
                    currentLeftListEntries[k] = strformat("%s [%s]", itemTypes[k], tostring(k))
                end
                return currentLeftListEntries
            else
d(">rightList")
                local currentRightListEntries = FCOIS.LibShifterBoxes[FCOISuniqueIdItemTypes].currentRightListEntries

                local allowedFCOISUniqueIdItemTypesRightList = settings.allowedFCOISUniqueIdItemTypesRightList
                for k,v in pairs(allowedFCOISUniqueIdItemTypesRightList) do
d(">>Rvalue: " ..tos(v))
                    currentRightListEntries[k] = strformat("%s [%s]", itemTypes[k], tostring(k))
                end
                return currentRightListEntries
            end
        end,
        setFuncOfList = function(isLeftList, tableData)
d("[FCOIS]setFuncOfList-isLeftList: " ..tos(isLeftList))
FCOIS._tableDataOfLibShifterUniqueItemType = tableData
            --Write FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes
            if isLeftList == nil or tableData == nil then return end

            local currentLeftListEntries = FCOIS.LibShifterBoxes[FCOISuniqueIdItemTypes].currentLeftListEntries
            local currentRightListEntries = FCOIS.LibShifterBoxes[FCOISuniqueIdItemTypes].currentRightListEntries

            if isLeftList == true then
d(">leftList")
                for k, v in pairs(tableData) do
                    --Update the helper tables
                    currentLeftListEntries[k] = v
                    currentRightListEntries[k] = nil
d(">>key: " .. tos(k) .. ", value: " ..tos(v))
                end
                --Check if any entry is left in the right list. If not:
                --Add the default values weapons and armor again and output a chat message.
                --local shifterBoxData = FCOIS.LibShifterBoxes[FCOISuniqueIdItemTypes]
                --checkAndUpdateRightListDefaultEntries(shifterBoxData.control, shifterBoxData)

            else
d(">rightList")
                for k, v in pairs(tableData) do
                    --Update the helper tables
                    currentLeftListEntries[k] = nil
                    currentRightListEntries[k] = v
d(">>key: " .. tos(k) .. ", value: " ..tos(v))
                end
            end

            --Update the SavedVariables - Loop over all itemTypes and check where they currentyl are: Left or right
            local itemTypes = locVars.ItemTypes
            for k, v in ipairs(itemTypes) do
                if currentRightListEntries[k] ~= nil then
d(">>>set to right SV - key: " .. tos(k) .. ", value: " ..tos(v))
                    FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypesRightList[k] = true
                else
d(">>>set to left SV - key: " .. tos(k) .. ", value: " ..tos(v))
                    FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypesLeftList[k] = false
                    FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypesRightList[k] = nil
                end
            end

        end,

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
            }
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
}
libShifterBoxes = FCOIS.LibShifterBoxes


------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------
--Create a LibShifterBox for e.g. LAM settings panel
function FCOIS.createLibShifterBox(customControl, boxName)
    if not customControl or not boxName or boxName == "" then return end
    local boxData = libShifterBoxes[boxName]
    if not boxData then return end
    libShifterBoxes[boxName].lamCustomControl = customControl
    local shifterBox = lsb(addonName, boxName .. "_LSB", customControl, boxData.customSettings)
    libShifterBoxes[boxName].control = shifterBox
    --Update the shifter box entries and state
    updateLibShifterBox(customControl, shifterBox, boxName)
end