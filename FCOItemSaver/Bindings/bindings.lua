--Global variable
FCOIS = FCOIS or {}
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end
--Keybinding texts

--Filters
ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER1",                       FCOIS.GetLocText("SI_BINDING_NAME_FCOISFILTER1", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER2",                       FCOIS.GetLocText("SI_BINDING_NAME_FCOISFILTER2", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER3",                       FCOIS.GetLocText("SI_BINDING_NAME_FCOISFILTER3", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOISFILTER4",                       FCOIS.GetLocText("SI_BINDING_NAME_FCOISFILTER4", true))
--Settings menu
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_SETTINGS_MENU",                FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_SETTINGS_MENU", true))
--Standard mark icon
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_WITH_STANDARD_ICON", FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_WITH_STANDARD_ICON", true))
--Cycle marker icon up
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_UP",           FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_UP", true))
--Cycle marker icon down
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_DOWN",         FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_CYCLE_DOWN", true))
--Static icons
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_1",                  FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_1", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_3",                  FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_3", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_5",                  FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_5", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_9",                  FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_9", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_10",                 FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_10", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_11",                 FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_11", true))
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_MARK_ITEM_12",                 FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_MARK_ITEM_12", true))
--Junk sell marked items
ZO_CreateStringId("SI_BINDING_NAME_FCOIS_JUNK_ALL_SELL",                FCOIS.GetLocText("SI_BINDING_NAME_FCOIS_JUNK_ALL_SELL", true))


--Generate the keybinding texts for the static gear set icons
function FCOIS.generateStaticGearSetIconsKeybindingsTexts()
    --Gear sets
    local gearKeybindString = "SI_BINDING_NAME_FCOIS_MARK_GEAR_SET_"
    local numGearSets = FCOIS.numVars.gFCONumGearSets
    for gearNr = 1, numGearSets, 1 do
        ZO_CreateStringId(gearKeybindString .. tostring(gearNr),        FCOIS.GetLocText(gearKeybindString .. tostring(gearNr), true))
    end
end

--Generate the keybinding texts for the enabled dynamic icons
function FCOIS.generateDynamicIconsKeybindingsTexts()
    --Dynamic icons
    local dynKeybindString  = "SI_BINDING_NAME_FCOIS_MARK_ITEM_"
    --local numDynIcons       = FCOIS.numVars.gFCONumDynamicIcons
    local settings          = FCOIS.settingsVars.settings
    local numDynIcons       = settings.numMaxDynamicIconsUsable
    local dyn2Icon          = FCOIS.mappingVars.dynamicToIcon
    for dynNr = 1, numDynIcons, 1 do
        local dynIconNr = dyn2Icon[dynNr]
        ZO_CreateStringId(dynKeybindString .. tostring(dynIconNr),      FCOIS.GetLocText(dynKeybindString .. tostring(dynIconNr), true))
    end
end

--Visibility function for the junk all sell marked items keybind
local function UpdateAndDisplayJunkSellKeybind()
    --Load the user settings, if not done already
    if not FCOIS.checkIfFCOISSettingsWereLoaded(true) then return nil end
    --Is the setting enabled to show the keybind?
    return FCOIS.settingsVars.settings.keybindMoveMarkedForSellToJunkEnabled
end

local function JunkAllSellMarkedItems()
    --Load the user settings, if not done already
    if not FCOIS.checkIfFCOISSettingsWereLoaded(true) then return nil end
    --Is the setting enabled to show the keybind?
    if not FCOIS.settingsVars.settings.keybindMoveMarkedForSellToJunkEnabled then return end
    --Junk the sell marked items now
    FCOIS.JunkMarkedItems({FCOIS_CON_ICON_SELL}, BAG_BACKPACK)
end

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
end