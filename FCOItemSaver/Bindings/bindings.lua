--Global variable
FCOIS = FCOIS or {}
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local getLocText = FCOIS.GetLocText
local checkIfFCOISSettingsWereLoaded = FCOIS.CheckIfFCOISSettingsWereLoaded

function FCOIS.LoadKeybindings()
    --Load the user settings, if not done already.
    --FCOIS.preventerVars.gCalledFromInternalFCOIS = true
    --checkIfFCOISSettingsWereLoaded(false, not FCOIS.addonVars.gAddonLoaded)
    --Security check for gamepad mode!
    --if not FCOIS.settingsVars or not FCOIS.settingsVars.settings then return end

    --Keybinding texts
    --Filters
    ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER1",                           getLocText("SI_BINDING_NAME_FCOISFILTER1", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER2",                           getLocText("SI_BINDING_NAME_FCOISFILTER2", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER3",                           getLocText("SI_BINDING_NAME_FCOISFILTER3", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER4",                           getLocText("SI_BINDING_NAME_FCOISFILTER4", true))
    --Settings menu
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_SETTINGS_MENU",                    getLocText("SI_BINDING_NAME_FCOIS_SETTINGS_MENU", true))
    --Standard mark icon
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_WITH_STANDARD_ICON",     getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_WITH_STANDARD_ICON", true))
    --Cycle marker icon up
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_UP",               getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_UP", true))
    --Cycle marker icon down
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_DOWN",             getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_DOWN", true))
    --Static icons
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_1",                      getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_1", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_3",                      getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_3", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_5",                      getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_5", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_9",                      getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_9", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_10",                     getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_10", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_11",                     getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_11", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_12",                     getLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_12", true))

    --Junk sell marked items
    --Get the sell marker icon texture and replace the %s placeholder in SI_BINDING_NAME_FCOIS_JUNK_ALL_SELL with it
    if FCOIS.settingsVars.settings.icon then
        local sellIconData = FCOIS.settingsVars.settings.icon[FCOIS_CON_ICON_SELL]
        local sellMarkerIconTextueId = sellIconData.texture
        local sellIconTexture = FCOIS.textureVars.MARKER_TEXTURES[sellMarkerIconTextueId]
        local sellIconTextureText = ""
        if sellIconTexture then
            --local sellIconColor = sellIconData.color
            --local sellIconColorDef = ZO_ColorDef:New(sellIconColor.r, sellIconColor.g, sellIconColor.b, sellIconColor.a)
            --sellIconTextureText = sellIconColorDef:Colorize(zo_iconFormat(sellIconTexture, 24, 24))
            sellIconTextureText = zo_iconFormat(sellIconTexture, 32, 32)
            ZO_CreateStringId("SI_BINDING_NAME_FCOIS_JUNK_ALL_SELL",            getLocText("SI_BINDING_NAME_FCOIS_JUNK_ALL_SELL", true, {sellIconTextureText}))
        end
    end
    --Mark with sell icon (if enabled in settings) and junk item
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_JUNK_AND_MARK_SELL_ITEM",          getLocText("SI_BINDING_NAME_FCOIS_JUNK_AND_MARK_SELL_ITEM", true))
    ZO_CreateStringId("SI_BINDING_NAME_FCOIS_REMOVE_ALL_MARKER_ICONS_AND_UNDO", getLocText("SI_BINDING_NAME_FCOIS_REMOVE_ALL_MARKER_ICONS_AND_UNDO", true))
end

--Generate the keybinding texts for the static gear set icons
function FCOIS.GenerateStaticGearSetIconsKeybindingsTexts()
    --Gear sets
    local gearKeybindString = "SI_BINDING_NAME_FCOIS_MARK_GEAR_SET_"
    local numGearSets = FCOIS.numVars.gFCONumGearSets
    for gearNr = 1, numGearSets, 1 do
        ZO_CreateStringId(gearKeybindString .. tostring(gearNr),                getLocText(gearKeybindString .. tostring(gearNr), true))
    end
end

--Generate the keybinding texts for the enabled dynamic icons
function FCOIS.GenerateDynamicIconsKeybindingsTexts()
    --Dynamic icons
    local dynKeybindString  = "SI_BINDING_NAME_FCOIS_MARK_ITEM_"
    --local numDynIcons       = FCOIS.numVars.gFCONumDynamicIcons
    local numDynIcons       = FCOIS.settingsVars.settings.numMaxDynamicIconsUsable
    local dyn2Icon          = FCOIS.mappingVars.dynamicToIcon
    for dynNr = 1, numDynIcons, 1 do
        local dynIconNr = dyn2Icon[dynNr]
        ZO_CreateStringId(dynKeybindString .. tostring(dynIconNr),              getLocText(dynKeybindString .. tostring(dynIconNr), true))
    end
end

--Check if a keybind of parameter "type" is allowed to be shown
local function checkIfKeybindIsAllowedToShow(type)
    if not type or type == "" then return end
    local typeToNotAllowedScenes = {
        ["moveSellMarkedToJunk"] = {
            --"bank",
            --"guildBank",
            "tradinghouse",
        }
    }
    local notAllwedSceneNamesOfType = typeToNotAllowedScenes[type]
    if notAllwedSceneNamesOfType then
        for _, notAllowedSceneName in ipairs(notAllwedSceneNamesOfType) do
            local sceneToHook = SCENE_MANAGER:GetScene(notAllowedSceneName)
            if sceneToHook and sceneToHook.state then
                local state = sceneToHook.state
                if state == SCENE_SHOWING or state == SCENE_SHOWN then
                    return false
                end
            end
        end
    end
    return true
end

--Visibility function for the add item to junk keybind
local function UpdateAndDisplayAddItemToJunkKeybind()
    --Load the user settings, if not done already
    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
    if not checkIfFCOISSettingsWereLoaded(false, not FCOIS.addonVars.gAddonLoaded) then return nil end
    --Is the setting enabled to show the keybind?
    return FCOIS.settingsVars.settings.keybindMoveItemToJunkEnabled
end

--Visibility function for the junk all sell marked items keybind
local function UpdateAndDisplayJunkSellKeybind()
    --Load the user settings, if not done already
    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
    if not checkIfFCOISSettingsWereLoaded(false, not FCOIS.addonVars.gAddonLoaded) then return nil end
    --Check if the currently visible scene/menu etc. are allowed for the "move sell marked to junk" keybind
    if not checkIfKeybindIsAllowedToShow("moveSellMarkedToJunk") then return false end
    --Is the setting enabled to show the keybind?
    return FCOIS.settingsVars.settings.keybindMoveMarkedForSellToJunkEnabled
end

local function JunkAllSellMarkedItems()
    --Load the user settings, if not done already
    FCOIS.preventerVars.gCalledFromInternalFCOIS = true
    if not checkIfFCOISSettingsWereLoaded(false, not FCOIS.addonVars.gAddonLoaded) then return nil end
    --Is the setting enabled to show the keybind?
    if not FCOIS.settingsVars.settings.keybindMoveMarkedForSellToJunkEnabled then return end
    --Junk the sell marked items now
    FCOIS.JunkMarkedItems({FCOIS_CON_ICON_SELL}, BAG_BACKPACK)
end

--Check if the keybindings modifier keys SHIFt/CTRL/ALT should be always enabled
--[[
    function KEYBINDING_MANAGER:IsChordingAlwaysEnabled()
        return KEYBINDING_MANAGER.chordingAlwaysEnabled
    end
]]
function FCOIS.CheckKeybindingChording(isEnabled)
    if isEnabled == nil then
        isEnabled = FCOIS.settingsVars.settings.enableKeybindChording
    end
    if isEnabled == true then
        --esoui\ingame\keybindings\keyboard\keybindings.lua
        function KEYBINDING_MANAGER:IsChordingAlwaysEnabled()
            return true
        end
    else
        function KEYBINDING_MANAGER:IsChordingAlwaysEnabled()
            return KEYBINDING_MANAGER.chordingAlwaysEnabled
        end
    end
end
local checkKeybindingChording = FCOIS.CheckKeybindingChording


--Inventory keybinds
function FCOIS.InitializeInventoryKeybind()
    FCOIS.keybinds = FCOIS.keybinds or {}
    FCOIS.keybinds["inventory"] =
    {
        alignment = KEYBIND_STRIP_ALIGN_CENTER,
        {
            name = GetString(SI_BINDING_NAME_FCOIS_JUNK_ALL_SELL),
            keybind = "FCOIS_JUNK_ALL_SELL",
            callback = JunkAllSellMarkedItems,
            visible = UpdateAndDisplayJunkSellKeybind,
        },
        {
            name = GetString(SI_BINDING_NAME_FCOIS_JUNK_AND_MARK_SELL_ITEM),
            keybind = "FCOIS_JUNK_AND_MARK_SELL_ITEM",
            callback = function()
                --d("[FCOIS]Keybind pressed for 'Junk item'")
                FCOIS.MarkAndRunOnItemByKeybind({FCOIS_CON_ICON_SELL}, 'junk')
            end,
            visible = UpdateAndDisplayAddItemToJunkKeybind,
        },
    }
    local invKeybinds = FCOIS.keybinds["inventory"]

    local function OnStateChanged(oldState, newState)
        if invKeybinds then
            if newState == SCENE_SHOWING then
                KEYBIND_STRIP:AddKeybindButtonGroup(invKeybinds)
            elseif newState == SCENE_HIDDEN then
                KEYBIND_STRIP:RemoveKeybindButtonGroup(invKeybinds)
            end
        end
    end
    INVENTORY_FRAGMENT:RegisterCallback("StateChange", OnStateChanged)

    --Is the keybind chording enabled?
    checkKeybindingChording(nil)
end
