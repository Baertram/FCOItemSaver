--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local addonVars = FCOIS.addonVars
local addonName = addonVars.gAddonName
local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local getSavedVarsMarkedItemsTableName = FCOIS.getSavedVarsMarkedItemsTableName

if not FCOIS.libShifterBox then return end
local lsb = FCOIS.libShifterBox

local FCOISlocVars = FCOIS.localizationVars
local locVars      = FCOISlocVars.fcois_loc

--The LibShifterBoxes FCOIS uses:
--The box for the LAM settings panel FCOIS uniqueId itemTypes
local FCOISuniqueIdItemTypes = "FCOISuniqueIdItemTypes"

FCOIS.LibShifterBoxes = {
    --ShortName = LAM control global name/reference
    [FCOISuniqueIdItemTypes] = {
        name = addonName .. "_LAM_CUSTOM___FCOIS_UNIQUEID_ITEMTYPES",
        customSettings = {
            leftList = {
                title = locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_TITLE_LEFT"],
            },
            rightList = {
                title = locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_TITLE_RIGHT"],
            }
        },
        width       = 580,
        height      = 200,
        --List default entries
        defaultRightListKeys = {
          ITEMTYPE_WEAPON, ITEMTYPE_ARMOR
        },
        --Controls
        lamCustomControl = nil,
        control = nil,
    },
}
local libShifterBoxes = FCOIS.LibShifterBoxes

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

local function checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
    if shifterBox and rightListEntries and NonContiguousCount(rightListEntries) == 0 then
        d(FCOIS.preChatVars.preChatTextRed .. locVars["LIBSHIFTERBOX_FCOIS_UNIQUEID_ITEMTYPES_RIGHT_NON_EMPTY"])
        local defaultRightListKeys = shifterBoxData and shifterBoxData.defaultRightListKeys
        if defaultRightListKeys then
            shifterBox:MoveEntriesToRightList(defaultRightListKeys)
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
            --Moved to the left? Set SavedVariables value false
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = false
            --Check if any entry is left in the right list. If not:
            --Add the default values weapons and armor again and output a chat message.
            local rightListEntries = shifterBox:GetRightListEntriesFull()
            checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
        end
    else
        if boxName == FCOISuniqueIdItemTypes then
            --Moved to the right? Save to SavedVariables with value true
            FCOIS.settingsVars.settings.allowedFCOISUniqueIdItemTypes[key] = true
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
    local shifterBoxData = libShifterBoxes[boxName]
    shifterBox = shifterBox or shifterBoxData.control
    if not shifterBox then return end
    local settings = FCOIS.settingsVars.settings

    local leftListEntries = {}
    local rightListEntries = {}

    if boxName == FCOISuniqueIdItemTypes then
        if not locVars or not locVars.ItemTypes then return end

        local allowedFCOISUniqueIdItemTypes = settings.allowedFCOISUniqueIdItemTypes
        for k,v in pairs(allowedFCOISUniqueIdItemTypes) do
            if v == true then
                rightListEntries[k] = string.format("%s [%s]", locVars.ItemTypes[k], tostring(k))
            else
                leftListEntries[k] = string.format("%s [%s]", locVars.ItemTypes[k], tostring(k))
            end
        end
    end
    shifterBox:ClearLeftList()
    shifterBox:AddEntriesToLeftList(leftListEntries)

    shifterBox:ClearRightList()
    shifterBox:AddEntriesToRightList(rightListEntries)

    checkAndUpdateRightListDefaultEntries(shifterBox, rightListEntries, shifterBoxData)
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
    end

    parentCtrl:SetHidden(false)
    parentCtrl:SetMouseEnabled(isEnabled)
    shifterBox:SetHidden(false)
    shifterBox:SetEnabled(isEnabled)
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
    shifterBox:RegisterCallback(lsb.EVENT_ENTRY_MOVED, myShifterBoxEventEntryMovedCallbackFunction)
    --Add the callback as an entry was highlighted at the left side
    --shifterBox:RegisterCallback(lsb.EVENT_ENTRY_HIGHLIGHTED, myShifterBoxEventEntryHighlightedCallbackFunction)
end

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