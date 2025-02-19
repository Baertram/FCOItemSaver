--Global array with all data of this addon
FCOIS = FCOIS or {}
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

local wm = WINDOW_MANAGER
local cm = CALLBACK_MANAGER
local SM = SCENE_MANAGER
local gameMenuIngameScene = SM:GetScene('gameMenuInGame')

local tos = tostring
local ton = tonumber
local strformat = string.format
local strlen = string.len
local strsub = string.sub
local strgsub = string.gsub
local strfind = string.find
local zo_strf = zo_strformat

local svAllServersTheSame   = FCOIS.svServerAllTheSameName
local svAllAccTheSameAcc    = FCOIS.svAllAccountsName

local fcoisLAMSettingsReferencePrefix = "FCOItemSaver_Settings_"
--Control name parts, prefix, suffix, tooltip suffix
local previewSelect = "Preview_Select"
local filterButton = "Filter"
--local libSetsSetSearchFavorite = "LibSetsSetSearchFavorite_" --#301
local colorSuffix = "_color"
local nameSuffix = "_name"
local optionsIcon = "options_icon"
local submenuSuffix = "_submenu"
local subMenuNamePattern = fcoisLAMSettingsReferencePrefix .. "MarkerIcon%s" .. submenuSuffix
local tooltipSuffix = "_TT"
local LAMopenedCounter = 0

local FCOISdefaultSettings
local FCOISsettings

--These localizations will contain keybinding texts only at this moment!
-->Will be updated as LAM menu is created again
local FCOISlocVars =    FCOIS.localizationVars
local locVars =         FCOISlocVars.fcois_loc

local mappingVars = FCOIS.mappingVars
local preChatVars = FCOIS.preChatVars
local noEntry = mappingVars.noEntry
local noEntryValue = mappingVars.noEntryValue
local currentStart = preChatVars.currentStart
local currentEnd   = preChatVars.currentEnd
local isIconEnabled
local numDynIcons
local iconId2FCOISIconNr = mappingVars.dynamicToIcon

local getCharacterName = FCOIS.GetCharacterName

local numVars = FCOIS.numVars
local numFilterPanels = numVars.gFCONumFilterInventoryTypes
local activeFilterPanelIds = mappingVars.activeFilterPanelIds
--local numFilterButtons = numVars.gFCONumFilters
local filterButtonsToCheck = FCOIS.checkVars.filterButtonsToCheck
local numFilterIcons = numVars.gFCONumFilterIcons
local numMaxDynIcons = numVars.gFCOMaxNumDynamicIcons
local markerIconTextures = FCOIS.textureVars.MARKER_TEXTURES

--The textures/marker icons names (just numbers)
local texturesList = {}
local maxTextureIcons = numVars.maxTextureIcons
for i=1, maxTextureIcons, 1 do
    texturesList[i] = tos(i)
end

local ZOsControlVars = FCOIS.ZOControlVars

local minIconSize = FCOIS.iconVars.minIconSize
local maxIconSize = FCOIS.iconVars.maxIconSize
local minIconOffsetLeft = FCOIS.iconVars.minIconOffsetLeft
local maxIconOffsetLeft = FCOIS.iconVars.maxIconOffsetLeft
local minIconOffsetTop  = FCOIS.iconVars.minIconOffsetTop
local maxIconOffsetTop  = FCOIS.iconVars.maxIconOffsetTop

local minFilterButtonWidth = FCOIS.filterButtonVars.minFilterButtonWidth
local maxFilterButtonWidth = FCOIS.filterButtonVars.maxFilterButtonWidth
local minFilterButtonHeight = FCOIS.filterButtonVars.minFilterButtonHeight
local maxFilterButtonHeight = FCOIS.filterButtonVars.maxFilterButtonHeight

FCOIS.worldName = FCOIS.worldName or GetWorldName()
local currentServerName     = FCOIS.worldName
local currentAccountName    = GetDisplayName()
local currentCharacterName  = ZO_CachedStrFormat(SI_UNIT_NAME, GetUnitName("player"))
local currentCharacterId    = GetCurrentCharacterId()
local currentServerNameMarked   = currentStart..currentServerName..currentEnd
local currentAccountNameMarked  = currentStart..currentAccountName..currentEnd
local currentCharacterNameMarked= currentStart..currentCharacterName..currentEnd
local serverNames = mappingVars.serverNames
local svAllAccountsName = FCOIS.svAllAccountsName

local FCOIS_LAM_SettingsMenuOpen_timeline
local doNotRunDropdownValueSetFunc = false

local editBoxesToSetTextTypes

local countAndUpdateEquippedArmorTypes = FCOIS.CountAndUpdateEquippedArmorTypes
local updateFCOISFilterButtonColorsAndTextures = FCOIS.UpdateFCOISFilterButtonColorsAndTextures
local changeContextMenuInvokerButtonColorByPanelId = FCOIS.ChangeContextMenuInvokerButtonColorByPanelId
local changeContextMenuEntryTexts = FCOIS.ChangeContextMenuEntryTexts
local scanInventoryItemsForAutomaticMarks = FCOIS.ScanInventoryItemsForAutomaticMarks
local scanInventory = FCOIS.ScanInventory
local checkIfAutomaticMarksAreDisabledAtBag = FCOIS.CheckIfAutomaticMarksAreDisabledAtBag
local rebuildAllowedCraftSkillsForCraftedMarking = FCOIS.RebuildAllowedCraftSkillsForCraftedMarking
local setDynamicIconAntiResearchCheck = FCOIS.SetDynamicIconAntiResearchCheck
local checkNeededLevel = FCOIS.CheckNeededLevel
local isRecipeAutoMarkDoable = FCOIS.IsRecipeAutoMarkDoable
local rebuildGearSetBaseVars = FCOIS.RebuildGearSetBaseVars
local getCharactersOfAccount = FCOIS.GetCharactersOfAccount
local hideItemLinkTooltip = FCOIS.HideItemLinkTooltip
local migrateMarkerIcons = FCOIS.MigrateMarkerIcons
local copySavedVars = FCOIS.CopySavedVars
local showConfirmationDialog = FCOIS.ShowConfirmationDialog
local showRememberUserAboutSavedVariablesBackupDialog = FCOIS.ShowRememberUserAboutSavedVariablesBackupDialog
local checkIfRecipeAddonUsed = FCOIS.CheckIfRecipeAddonUsed
local checkIfChosenRecipeAddonActive = FCOIS.CheckIfChosenRecipeAddonActive
local checkIfResearchAddonUsed                  = FCOIS.CheckIfResearchAddonUsed
local checkIfChosenResearchAddonActive          = FCOIS.CheckIfChosenResearchAddonActive
local updateAntiCheckAtPanelVariable            = FCOIS.UpdateAntiCheckAtPanelVariable
local refreshEquipmentControl                   = FCOIS.RefreshEquipmentControl
local filterBasics                              = FCOIS.FilterBasics
local setAllAddInvFlagButtonOffsetSettingsEqual = FCOIS.SetAllAddInvFlagButtonOffsetSettingsEqual
local reAnchorAdditionalInvButtons              = FCOIS.ReAnchorAdditionalInvButtons
local resetCreateFCOISUniqueIdStringLastVars    = FCOIS.ResetCreateFCOISUniqueIdStringLastVars
local isMotifsAutoMarkDoable = FCOIS.IsMotifsAutoMarkDoable -- #308
local checkIfMotifsAddonUsed = FCOIS.CheckIfMotifsAddonUsed -- #308
local checkIfChosenMotifsAddonActive = FCOIS.CheckIfChosenMotifsAddonActive -- #308
local getMotifsAddonUsed = FCOIS.GetMotifsAddonUsed -- #308

local getLAMMarkerIconsDropdown

--local getLibSetsSetSearchFavoriteCategories     = FCOIS.GetLibSetsSetSearchFavoriteCategories --#301


--Other addons
local GridListActivated                         = false
local InventoryGridViewActivated                = false


-- ============= Addon LAM dropdown choices/choicesValues/choicesTooltios - BEGIN ======================================
--The table with all the LAM dropdown controls that should get updated with marker icons and their name
local LAMdropdownsWithIconList                  = {}
--The table with all LAM submenus for marker icons where the name could be changed (gear, dynamic)
--local LAMsubmenusWithMarkerIconChangeableNames = {}

--Icons for keybinds, automatic marks etc.
local iconsList, iconsListNone, iconsListRecipe, iconsListValuesRecipe, iconsListWithAllEntry, iconsListWithAllEntryValues
local iconsListValues = {}
local iconsListValuesNone = {}

local noneEntryStr = locVars["options_dropdown_none"]
local noneEntryValue = 0

--The server/world/realm names dropdown
local srcServer     = noEntryValue
local targServer    = noEntryValue
local serverOptions = {}
local serverOptionsValues = {}
local serverOptionsTarget = {}
local serverOptionsValuesTarget = {}
--The account dropdown
local srcAcc        = noEntryValue
local targAcc       = noEntryValue
local accountSrcOptions = {}
local accountSrcOptionsValues = {}
local accountTargOptions = {}
local accountTargOptionsValues = {}
--The character dropdown
local srcChar       = noEntryValue
local targChar      = noEntryValue
local characterSrcOptions = {}
local characterSrcOptionsValues = {}
local characterTargOptions = {}
local characterTargOptionsValues = {}

--Other addons
local recipeAddonsList = {}
local recipeAddonsListValues = {}
local researchAddonsList = {}
local researchAddonsListValues = {}
local setCollectionAddonsList = {}
local setCollectionAddonsListValues = {}
local motifsAddonsList = {} --#308
local motifsAddonsListValues = {} --#308

--Backup & Restore & Restore from APIversion
local restoreChoices = {}
local restoreChoicesValues = {}
--Delete marker icons
local numIconsToDelete = 0
local markerIconsToDeleteType = 0
local markerIconTypeChoices = {}
local markerIconTypeChoicesValues = {}
local markerIconsToDeleteIcon = 0

--Languages
local languageOptions = {}
local languageOptionsValues = {}

--Saved variables
local savedVariablesOptions = {}
local savedVariablesOptionsValues = {}

-- Unique itemId choices
local uniqueItemIdTypeChoices = {}
local uniqueItemIdTypeChoicesTT = {}
local uniqueItemIdTypeChoicesValues = {
    [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE] =      FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE,
    [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE] =    FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE,
}
--The modifier key dropdown choices and values
local choicesModifierKeys = {}
local choicesModifierKeysValues = {
    KEY_SHIFT,
    KEY_ALT,
    KEY_CTRL,
    KEY_COMMAND
}
--Build the list of colored qualities for the settings
local colorMagic = GetItemQualityColor(ITEM_DISPLAY_QUALITY_MAGIC)
local colorArcane = GetItemQualityColor(ITEM_DISPLAY_QUALITY_ARCANE)
local colorArtifact = GetItemQualityColor(ITEM_DISPLAY_QUALITY_ARTIFACT)
local colorLegendary = GetItemQualityColor(ITEM_DISPLAY_QUALITY_LEGENDARY)
local qualityList = {}

local nonWishedChecksList = {}
local nonWishedChecksValuesList = {
    [1] = FCOIS_CON_NON_WISHED_TRAIT,       -- Only check the trait
    [2] = FCOIS_CON_NON_WISHED_LEVEL,       -- Level
    [3] = FCOIS_CON_NON_WISHED_QUALITY,     -- Quality
    [4] = FCOIS_CON_NON_WISHED_ALL,         -- All (all need to be true, combined)
    [5] = FCOIS_CON_NON_WISHED_ANY_OF_THEM, -- Any of them
}

--Globalize the mapping table for the backwards search of the index "levelIndex", which will be
--saved in the SavedVariables in the variable "FCOIS.settingsVars.settings.autoMarkSetsNonWishedLevel",
--to get the level value (e.g. 40, or CP120)
local maxLevel = mappingVars.maxLevel
local levelList = {}
mappingVars.allLevels = levelList

--The dropdown boxes for the armor, weapon and jewelry trait checkboxes
local traitsMapped = mappingVars.traits
local armorTraitControls = {}
local jewelryTraitControls = {}
local weaponTraitControls = {}
local weaponShieldTraitControls = {}
local traitData = {
    [1] = traitsMapped.armorTraits,         --Armor
    [2] = traitsMapped.jewelryTraits,       --Jewelry
    [3] = traitsMapped.weaponTraits,        --Weapons
    [4] = traitsMapped.weaponShieldTraits,  --Shields
}

-- ============= Addon LAM dropdown choices/choicesValues/choicesTooltios - END ======================================

local function checkIfNumberOrReset(valueToCheck, resetValue)
    if valueToCheck == nil or valueToCheck == "" then return resetValue end
    local newValueNumber = ton(valueToCheck)
    if newValueNumber == nil or type(newValueNumber) ~= "number" then
        newValueNumber = resetValue
    end
    return newValueNumber
end


--Update localization dependent variables for the LAM settings menu
local function updateLocalizedVariablesBeforeAddonMenu()
--d("[FCOIS]updateLocalizedVariablesBeforeAddonMenu")
    FCOISlocVars =    FCOIS.localizationVars
    locVars =         FCOISlocVars.fcois_loc

    --Languages
    languageOptions = {}
    languageOptionsValues = {}
    --  Add english language description behind language descriptions in other languages
    local function nvl(val) if val == nil then return "..." end return val end
    --local LV_Cur = locVars
    local LV_Eng = FCOISlocVars.localizationAll[FCOIS_CON_LANG_EN]
    for langId=1, numVars.languageCount do
        local s="options_language_dropdown_selection".. tos(langId)
        if locVars==LV_Eng then
            languageOptions[langId] = nvl(locVars[s])
        else
            languageOptions[langId] = nvl(locVars[s]) .. " (" .. nvl(LV_Eng[s]) .. ")"
        end

        languageOptionsValues[langId] = langId
        --[[
        FCOIS_CON_LANG_EN = 1
        FCOIS_CON_LANG_DE = 2
        FCOIS_CON_LANG_FR = 3
        FCOIS_CON_LANG_ES = 4
        FCOIS_CON_LANG_IT = 5
        FCOIS_CON_LANG_JP = 6
        FCOIS_CON_LANG_RU = 7
        ]]
    end

    --Saved variables
    savedVariablesOptions = {}
    savedVariablesOptionsValues = {}
    for saveModeType=1, FCOIS.addonVars.savedVarsNumSaveModeTypes do
        savedVariablesOptions[saveModeType] = locVars["options_savedVariables_dropdown_selection" ..tos(saveModeType)]
        savedVariablesOptionsValues[saveModeType] = saveModeType
    end

    -- Unique itemId choices
    uniqueItemIdTypeChoices = {
        [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE] =      locVars["options_unique_id_base_game"],
        [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE] =    locVars["options_uniqe_id_by_FCOIS"],
    }
    FCOIS.localizationVars.fcois_loc.uniqueItemIdTypeChoices = uniqueItemIdTypeChoices

    uniqueItemIdTypeChoicesTT = {
        [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE] =      locVars["options_unique_id_base_game" .. tooltipSuffix],
        [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE] =    locVars["options_uniqe_id_by_FCOIS" .. tooltipSuffix],
    }
    --The modifier key dropdown choices and values
    choicesModifierKeys = {
        locVars["KEY_SHIFT"],
        locVars["KEY_ALT"],
        locVars["KEY_CTRL"],
        locVars["KEY_COMMAND"],
    }
    qualityList = {
        --[ITEM_DISPLAY_QUALITY_TRASH] = locVars["options_quality_trash"],
        --[ITEM_DISPLAY_QUALITY_NORMAL] = locVars["options_quality_normal"],
        [1] = locVars["options_quality_OFF"],
        [ITEM_DISPLAY_QUALITY_MAGIC] 	 = colorMagic:Colorize(locVars["options_quality_magic"]),
        [ITEM_DISPLAY_QUALITY_ARCANE] 	 = colorArcane:Colorize(locVars["options_quality_arcane"]),
        [ITEM_DISPLAY_QUALITY_ARTIFACT]  = colorArtifact:Colorize(locVars["options_quality_artifact"]),
        [ITEM_DISPLAY_QUALITY_LEGENDARY] = colorLegendary:Colorize(locVars["options_quality_legendary"]),
    }
    levelList = {
        [1] = locVars["options_quality_OFF"],
    }
    --Add the normal levels first
    local levelIndex = 2 -- Add after the "Disabled" entry
    if mappingVars.levels ~= nil then
        for _, level in ipairs(mappingVars.levels) do
            levelList[levelIndex] = tos(level)
            levelIndex = levelIndex + 1
        end
    end
    --Afterwards add the CP ranks
    if mappingVars.CPlevels ~= nil then
        for _, CPRank in ipairs(mappingVars.CPlevels) do
            levelList[levelIndex] = tos("CP" .. CPRank)
            levelIndex = levelIndex + 1
        end
    end

    nonWishedChecksList = {
        locVars["options_header_traits"],
        locVars["options_level"],
        locVars["options_quality"],
        locVars["options_all"],
        locVars["options_any"],
    }
end
FCOIS.UpdateLocalizedVariablesBeforeAddonMenu = updateLocalizedVariablesBeforeAddonMenu



-- ============= Addon LAM settings functions - BEGIN ==================================================================
--Show the FCO ItemSaver FCOIS.settingsVars.settings panel
function FCOIS.ShowFCOItemSaverSettings()
    FCOIS.LAM:OpenToPanel(FCOIS.FCOSettingsPanel)
end
-- ============= Addon LAM settings functions - END ====================================================================


-- ============= local LAM control create helper functions - BEGIN ===========================================
--Function to create a LAM control
local dataTypesWithoutName = {
    ["description"] = true,
    ["texture"] = true,
}
local dataTypesWithoutGenericData = {
    ["header"] = true,
    ["submenu"] = true,
}

local dataTypesWithoutSetAndGetFunc = {
    ["button"] = true,
}

local function CreateControl(ref, name, tooltip, data, disabledChecks, getFunc, setFunc, defaultSettings, warning, isIconDropDown, scrollable)
    scrollable = scrollable or false
    if ref ~= nil then
        if strfind(ref, fcoisLAMSettingsReferencePrefix, 1) ~= 1 then
            data.reference = fcoisLAMSettingsReferencePrefix .. ref
        else
            data.reference = ref
        end
    end

    local dataType = data.type
    if dataType ~= nil and not dataTypesWithoutName[dataType] then
        data.name = name
        if not dataTypesWithoutGenericData[dataType] then
            data.tooltip = tooltip
            if not dataTypesWithoutSetAndGetFunc[dataType] then
                data.getFunc = getFunc
                data.setFunc = setFunc
                if defaultSettings ~= nil then
                    data.default = defaultSettings
                end
            else
                data.func = setFunc
            end
            if disabledChecks ~= nil then
                data.disabled = disabledChecks
            end
            data.scrollable = scrollable
            data.warning = warning
            --Is the created control a dropdown box containing the FCOIS marker icons?
            --Then add the reference to the list of dropboxes that need to be updated if an icon changes it's name or
            if isIconDropDown then
                if LAMdropdownsWithIconList ~= nil then
                    LAMdropdownsWithIconList[tos(data.reference)] = { ["choices"] = 'standard', ["choicesValues"] = iconsListValues, ["choicesTooltips"] = nil, ["scrollable"] = true }
                end
            end
        end
    end
    return data
end

--Function to create a dropdown box for the LAM panel
local function CreateDropdownBox(ref, name, tooltip, disabledChecks, getFunc, setFunc, defaultSettings, choicesList, choicesValuesList, choicesTooltipsList, warning, width, isIconDropDown, isScrollable)
    width = width or "full"
    return CreateControl(ref, name, tooltip, { type = "dropdown", choices = choicesList, choicesValues = choicesValuesList, choicesTooltips = choicesTooltipsList, scrollable = isScrollable, width = width }, disabledChecks, getFunc, setFunc, defaultSettings, warning, isIconDropDown, isScrollable)
end
-- ============= local settings control create helper functions - END =============================================




-- ============= local helper functions - BEGIN ====================================================================

--UniqueIDs - BEGIN ----------------------------------------------------------------------------------------------------
local function uniqueIdIsEnabledAndSetToFCOIS()
    local settings = FCOIS.settingsVars.settings
    if settings.useUniqueIds == true then
        return (settings.uniqueItemIdType == FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE) or false
    end
    return false
end
FCOIS.uniqueIdIsEnabledAndSetToFCOIS = uniqueIdIsEnabledAndSetToFCOIS

--UniqueIDs - END ------------------------------------------------------------------------------------------------------


--Map the texture path to the texture ID
local function GetFCOTextureId(texturePath)
    if texturePath == nil or texturePath == "" then return 0 end
    for textureId, texturePathString in pairs(markerIconTextures) do
        if	texturePathString == texturePath then
            return textureId
        end
    end
    return 0
end

--Set the text type of some edit boxes in the settings menu so the values entered are validated
local function setSettingsMenuEditBoxTextTypes()
    if not editBoxesToSetTextTypes then return end
    for controlName, textType in pairs(editBoxesToSetTextTypes) do
        if textType then
            local control = GetControl(controlName) --wm:GetControlByName(controlName, "")
            if control then
                if control.editbox and control.editbox.SetTextType then
                    control.editbox:SetTextType(textType)
                end
            end
        end
    end
end


--Server, Account, Character dropdown boxes - BEGIN --------------------------------------------------------------------
local function cleanName(nameStr, nameType, nameValue)
    if nameStr == nil or nameStr =="" or nameType == nil or nameType == "" then return end
    if nameValue ~= nil and nameValue == noEntry then return nameStr end
    local nameCleaned = ""
    if nameType == "server" then
        --Namevalue is given, or not, and it's another entry
        --Check for the currentStart and currentEnd values and remove them
        nameCleaned = strgsub(nameStr, currentStart, "", 1)
        nameCleaned = strgsub(nameCleaned, currentEnd, "", 1)
        return nameCleaned
    elseif nameType == "account" then
        --Namevalue is given and it's the AllAccounts entry?
        if nameValue then
            if nameValue == noEntryValue+2 then --AllAccounts entry?
                return svAllAccountsName
            elseif nameValue == noEntryValue+1 then --Current account entry?
                return currentAccountName
            end
        end
        --Namevalue is given, or not, and it's another entry
        --Check for the currentStart and currentEnd values and remove them
        nameCleaned = strgsub(nameStr, currentStart, "", 1)
        nameCleaned = strgsub(nameCleaned, currentEnd, "", 1)
        return nameCleaned
    elseif nameType == "character" then
        --Namevalue is given and it's the AllAccounts entry?
        if nameValue then
            if nameValue == noEntryValue+1 then --Current Character entry?
                return currentCharacterName
            end
        end
        --Namevalue is given, or not, and it's another entry
        --Check for the currentStart and currentEnd values and remove them
        nameCleaned = strgsub(nameStr, currentStart, "", 1)
        nameCleaned = strgsub(nameCleaned, currentEnd, "", 1)
        return nameCleaned
    end
    nameCleaned = nameStr
    return nameCleaned
end

local function reBuildServerOptions(updateSourceOrTarget)
    --Reset the server name and index tables
    serverOptions = {}
    serverOptionsValues = {}
    for serverIdx, serverName in ipairs(serverNames) do
        local serverNameStr = serverName
        if serverName == currentServerName then
            serverNameStr = currentServerNameMarked
        end
        if serverIdx > 1 then
            --Do we have server settings for the servername in the SavedVars?
            table.insert(serverOptionsTarget, serverNameStr)
            table.insert(serverOptionsValuesTarget, serverIdx)
            if FCOItemSaver_Settings and FCOItemSaver_Settings[serverName] then
                table.insert(serverOptions, serverNameStr)
                table.insert(serverOptionsValues, serverIdx)
            end
        else
            --Index 1: Always add "none" entry
            table.insert(serverOptions, serverName)
            table.insert(serverOptionsValues, serverIdx)
            table.insert(serverOptionsTarget, serverName)
            table.insert(serverOptionsValuesTarget, serverIdx)
        end
    end
    --Reset chosen dropdown values
    doNotRunDropdownValueSetFunc = true
    if updateSourceOrTarget == nil or updateSourceOrTarget == true then
        srcServer  = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Src_Server then
            FCOItemSaver_Settings_Copy_SV_Src_Server:UpdateValue(srcServer)
        end
        srcAcc  = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Src_Acc then
            FCOItemSaver_Settings_Copy_SV_Src_Acc:UpdateValue(srcAcc)
        end
        srcChar = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Src_Char then
            FCOItemSaver_Settings_Copy_SV_Src_Char:UpdateValue(srcChar)
        end
    end
    if updateSourceOrTarget == nil or updateSourceOrTarget == false then
        targServer = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Targ_Server then
            FCOItemSaver_Settings_Copy_SV_Src_Server:UpdateValue(targServer)
        end
        targAcc = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Targ_Acc then
            FCOItemSaver_Settings_Copy_SV_Targ_Acc:UpdateValue(targAcc)
        end
        targChar = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Targ_Char then
            FCOItemSaver_Settings_Copy_SV_Targ_Char:UpdateValue(targChar)
        end
    end
    doNotRunDropdownValueSetFunc = false
end

local function reBuildAccountOptions(updateSourceOrTarget)
    local currentAccountFoundInSv = false
    local allAccountsFoundInSV = false
    locVars = FCOISlocVars.fcois_loc

    --Reset the account name and index tables
    accountSrcOptions = {}
    accountSrcOptionsValues = {}
    accountTargOptions = {}
    accountTargOptionsValues = {}
    --**********************************************************************************************************************
    --**********************************************************************************************************************
    --The source server name
    local sourceServerName = serverNames[srcServer]
    --Source accounts
    --Add the no entry entry
    table.insert(accountSrcOptions, noEntry)
    table.insert(accountSrcOptionsValues, noEntryValue)
    if FCOItemSaver_Settings then
        local accCnt = 3 -- Preset with 3 so the 3rd item will be left empty for the "All accounts" entry
        --Get account names from the SavedVariables, for each server
        for serverName, serverData in pairs(FCOItemSaver_Settings) do
            if serverName == sourceServerName then
                for accountName, _ in pairs(serverData) do
                    --Do not add the current accountName again, and not the all accounts name
                    if accountName ~= currentAccountName and accountName ~= svAllAccountsName then
                        accCnt = accCnt + 1
                        table.insert(accountSrcOptions, accountName)
                        table.insert(accountSrcOptionsValues, accCnt)
                    elseif accountName == currentAccountName then
                        currentAccountFoundInSv = true
                    elseif accountName == svAllAccountsName then
                        allAccountsFoundInSV = true
                    end
                end
            end
        end
    end
    --Add current acount name at fixed positon 2! Color it red if it does not exist yet
    local currentAccountText = currentAccountNameMarked
    if not currentAccountFoundInSv then
        currentAccountText = "|cff0000" .. currentAccountText .. "|r"
    end
    table.insert(accountSrcOptions, currentAccountText)
    table.insert(accountSrcOptionsValues, noEntryValue+1)
    --Add all acounts name at fixed positon 3! Color it red if it does not exist yet
    local allAccountsText = locVars["options_savedVariables_dropdown_selection3"]
    if not allAccountsFoundInSV then
        allAccountsText = "|cff0000" .. allAccountsText .. "|r"
    end
    table.insert(accountSrcOptions, allAccountsText)
    table.insert(accountSrcOptionsValues, noEntryValue+2)
    --**********************************************************************************************************************
    --**********************************************************************************************************************
    --Target accounts
    allAccountsFoundInSV = false
    currentAccountFoundInSv = false
    --Copy the source to the target accounts
    --accountTargOptions          = ZO_ShallowTableCopy(accountSrcOptions)
    --accountTargOptionsValues    = ZO_ShallowTableCopy(accountSrcOptionsValues)
    --The target server name
    local targetServerName = serverNames[targServer]
    --Add the no entry entry
    table.insert(accountTargOptions, noEntry)
    table.insert(accountTargOptionsValues, noEntryValue)
    if FCOItemSaver_Settings then
        local accCnt = 3 -- Preset with 3 so the 3rd item will be left empty for the "All accounts" entry
        --Get account names from the SavedVariables, for each server
        for serverName, serverData in pairs(FCOItemSaver_Settings) do
            if serverName == targetServerName then
                for accountName, _ in pairs(serverData) do
                    --Do not add the current accountName again, and not the all accounts name
                    if accountName ~= currentAccountName and accountName ~= svAllAccountsName then
                        accCnt = accCnt + 1
                        local accNameTarg = accountName
                        table.insert(accountTargOptions, accNameTarg)
                        table.insert(accountTargOptionsValues, accCnt)
                    elseif accountName == currentAccountName then
                        currentAccountFoundInSv = true
                    elseif accountName == svAllAccountsName then
                        allAccountsFoundInSV = true
                    end
                end
            end
        end
    end
    --Add current acount name at fixed positon 2! Color it red if it does not exist yet
    currentAccountText = currentAccountNameMarked
    if not currentAccountFoundInSv then
        currentAccountText = "|cff0000" .. currentAccountText .. "|r"
    end
    table.insert(accountTargOptions, currentAccountText)
    table.insert(accountTargOptionsValues, noEntryValue+1)
    --Add all acounts name at fixed positon 3! Color it red if it does not exist yet
    allAccountsText = locVars["options_savedVariables_dropdown_selection3"]
    if not allAccountsFoundInSV then
        allAccountsText = "|cff0000" .. allAccountsText .. "|r"
    end
    table.insert(accountTargOptions, allAccountsText)
    table.insert(accountTargOptionsValues, noEntryValue+2)

    --Reset chosen dropdown values
    doNotRunDropdownValueSetFunc = true
    if updateSourceOrTarget == nil or updateSourceOrTarget == true then
        srcAcc  = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Src_Acc then
            FCOItemSaver_Settings_Copy_SV_Src_Acc:UpdateValue(srcAcc)
            FCOItemSaver_Settings_Copy_SV_Src_Acc:UpdateChoices(accountSrcOptions, accountSrcOptionsValues)
        end
        srcChar = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Src_Char then
            FCOItemSaver_Settings_Copy_SV_Src_Char:UpdateValue(srcChar)
        end
    end
    if updateSourceOrTarget == nil or updateSourceOrTarget == false then
        targAcc = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Targ_Acc then
            FCOItemSaver_Settings_Copy_SV_Targ_Acc:UpdateValue(targAcc)
            FCOItemSaver_Settings_Copy_SV_Targ_Acc:UpdateChoices(accountTargOptions, accountTargOptionsValues)
        end
        targChar = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Targ_Char then
            FCOItemSaver_Settings_Copy_SV_Targ_Char:UpdateValue(targChar)
        end
    end
    doNotRunDropdownValueSetFunc = false
end

local function reBuildCharacterOptions(updateSourceOrTarget)
    --Reset the server name and index tables
    characterSrcOptions = {}
    characterSrcOptionsValues = {}
    characterTargOptions = {}
    characterTargOptionsValues = {}
    local charactersOfAccount       = getCharactersOfAccount(true) --name as key
    if not charactersOfAccount then return end
    table.sort(charactersOfAccount) --sort by name
    local charactersOfAccountKeyId  = getCharactersOfAccount(false) --unique ID as key
    --Source characters
    --Add the no entry entry
    table.insert(characterSrcOptions, noEntry)
    table.insert(characterSrcOptionsValues, noEntryValue)
    --table.insert(characterSrcOptions, currentCharacterNameMarked)
    --table.insert(characterSrcOptionsValues, currentCharacterId)
    if FCOItemSaver_Settings then
        --Get account names from the SavedVariables, for each server
        for _, serverData in pairs(FCOItemSaver_Settings) do
            --For each accountName get the characters
            for _, accountData in pairs(serverData) do
                for characterId, _ in pairs(accountData) do
                    -- Do not use the $AccountWide entry or entries with starting @ (other account names)
                    if characterId ~= FCOIS.svAccountWideName and strsub(characterId, 1, 1) ~= "@" then
                        --Is the read entry a character ID number?
                        local characterIdNumber = ton(characterId)
                        if characterIdNumber and characterIdNumber > 0 then
                            --Get the character name for the characterId
                            local characterName = ""
                            --Do not add the current character again
                            if characterId ~= currentCharacterId then
                                characterName = getCharacterName(characterId, charactersOfAccountKeyId)
                            else
                                characterName = currentCharacterName
                            end
                            if characterName ~= nil and characterName ~= "" and characterId ~= nil then
                                table.insert(characterSrcOptions, characterName)
                                table.insert(characterSrcOptionsValues, characterId)
                            else
                                --The characterId and/or name are not given or unknown to the account
                                d(strformat("%s CharacterId %s is not a known character of the account %s!", FCOIS.preChatVars.preChatTextRed, tos(characterId), tos(currentAccountName)))
                            end
                        end
                    end
                end
            end
        end
    end
    --Target characters
    local targetServerName = serverNames[targServer]
    local targetAccName = accountTargOptions[targAcc]
    local targetAccNameClean = cleanName(targetAccName, "account", targAcc)
    --Add the no entry entry
    table.insert(characterTargOptions, noEntry)
    table.insert(characterTargOptionsValues, noEntryValue)
    --Add the current character (red if SV data is missing)
    if FCOItemSaver_Settings == nil or FCOItemSaver_Settings[targetServerName] == nil or FCOItemSaver_Settings[targetServerName][targetAccNameClean] == nil or FCOItemSaver_Settings[targetServerName][targetAccNameClean][tos(currentCharacterId)] == nil then
        table.insert(characterTargOptions, "|cFF0000" .. currentCharacterNameMarked .. "|r")
    else
        table.insert(characterTargOptions, currentCharacterNameMarked)
    end
    table.insert(characterTargOptionsValues, currentCharacterId)

    for charNameTarg, charIdTarg in pairs(charactersOfAccount) do
        if charIdTarg ~= currentCharacterId then
            --Check if the character exists on the actually chosen server and account already.
            --If not color the charactername red
            if FCOItemSaver_Settings == nil or FCOItemSaver_Settings[targetServerName] == nil or FCOItemSaver_Settings[targetServerName][targetAccNameClean] == nil or FCOItemSaver_Settings[targetServerName][targetAccNameClean][tos(charIdTarg)] == nil then
                local charNameWithColorActiveOrNot = "|cFF0000" .. charNameTarg .. "|r"
                table.insert(characterTargOptions, charNameWithColorActiveOrNot)
            else
                table.insert(characterTargOptions, charNameTarg)
            end
            table.insert(characterTargOptionsValues, charIdTarg)
        end
    end
    --Reset chosen dropdown values
    doNotRunDropdownValueSetFunc = true
    if updateSourceOrTarget == nil or updateSourceOrTarget == true then
        srcChar = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Src_Char then
            FCOItemSaver_Settings_Copy_SV_Src_Char:UpdateValue(srcChar)
        end
    end
    if updateSourceOrTarget == nil or updateSourceOrTarget == false then
        targChar = noEntryValue
        if FCOItemSaver_Settings_Copy_SV_Targ_Char then
            --Update the choices in total, as the re-usbale entries (menu pool controls) still got the disabled colors "red"
            FCOItemSaver_Settings_Copy_SV_Targ_Char.choices = {}
            FCOItemSaver_Settings_Copy_SV_Targ_Char:UpdateChoices(characterTargOptions, characterTargOptionsValues)
            FCOItemSaver_Settings_Copy_SV_Targ_Char:UpdateValue(targChar)
        end
    end
    doNotRunDropdownValueSetFunc = false
end
--Server, Account, Character dropdown boxes - BEGIN --------------------------------------------------------------------


--Backup / Restore - BEGIN --------------------------------------------------------------------
--Function to reset the backup edit control in the LAM settings to the current API version text
local backupEditCtrl
local function resetBackupEditToCurrentAPI()
    backupEditCtrl = backupEditCtrl or GetControl("FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT") --wm:GetControlByName("FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT", "")
    local apiVersion = FCOIS.APIversion
    if backupEditCtrl ~= nil then
        backupEditCtrl.editbox:SetText(apiVersion)
    end
    FCOIS.backup.apiVersion = apiVersion
    return apiVersion
end

--Function to check if the backup API version edit text is too short
local function isBackupEditAPITextTooShort()
    backupEditCtrl = backupEditCtrl or GetControl("FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT") --wm:GetControlByName("FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT", "")
    if backupEditCtrl ~= nil then
        local editText = backupEditCtrl.editbox:GetText()
        local apiVersionLength = FCOIS.APIVersionLength
        if editText and (editText == "" or strlen(editText) < apiVersionLength) then
            return true
        end
    end
    return false
end

--Read all restorable API versions from the savedvars to get a table with the API
--version and date + time when they were created
local function buildRestoreAPIVersionData(doUpdateDropdownValues)
    local foundRestoreData = {}
    local backupData = FCOISsettings.backupData
    if backupData ~= nil then
        restoreChoices = {}
        restoreChoicesValues = {}
        doUpdateDropdownValues = doUpdateDropdownValues or false
        for backupApiVersion, _ in pairs(backupData) do
            local dateInfo = tos(backupData[backupApiVersion].timestamp) or ""
            local restoreEntry = {}
            restoreEntry.apiVersion = backupApiVersion
            restoreEntry.timestamp  = dateInfo
            table.insert(foundRestoreData, restoreEntry)
            --Build the choices and choices values for the LAM dropdown box of restore api versions
            local tableIndex = #restoreChoices+1
            restoreChoices[tableIndex] = "[" .. tos(dateInfo) .. "] " .. tos(backupApiVersion)
            restoreChoicesValues[tableIndex] = ton(backupApiVersion)
        end
        --Update the choices and choicesValues in the LAM restore API verison dropdown now
        --> only needed if manually clicked the "refresh restorable backups" button
        if doUpdateDropdownValues == true then
            local restoreableBackupsDD = GetControl("FCOITEMSAVER_SETTINGS_RESTORE_API_VERSION_DROPDOWN") --wm:GetControlByName("FCOITEMSAVER_SETTINGS_RESTORE_API_VERSION_DROPDOWN", "")
            if restoreableBackupsDD then
                restoreableBackupsDD:UpdateChoices(restoreChoices, restoreChoicesValues)
                FCOIS.restore.apiVersion = nil
            end
        end
    end
    return foundRestoreData
end
FCOIS.BuildRestoreAPIVersionData = buildRestoreAPIVersionData
--Backup / Restore - END --------------------------------------------------------------------


--Marker icon delete - BEGIN --------------------------------------------------------------------
--Read all restorable API versions from the savedvars to get a table with the API
--version and date + time when they were created
local function buildMarkerIconsData(doUpdateDropdownValues)
    doUpdateDropdownValues = doUpdateDropdownValues or false
    locVars = FCOISlocVars.fcois_loc
    --[[
    addonVars.savedVarsMarkedItemsNames = {
        [false]                                         = savedVarsMarkedItems,
        [FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE]    = savedVarsMarkedItems,
        [FCOIS_CON_UNIQUE_ITEMID_TYPE_SLIGHTLY_UNIQUE]  = savedVarsMarkedItems .. "FCOISUnique",
    }
    ]]
    markerIconTypeChoices = {}
    markerIconTypeChoicesValues = {}

    local savedVarsMarkedItemsNames = FCOIS.addonVars.savedVarsMarkedItemsNames
    local subTablesAlreadyAdded = {}
    --Add the unique-ID types with different subTable names in the FCOIS SV now -> Each table only once
    for idx, saveIdType  in ipairs(uniqueItemIdTypeChoicesValues) do
        --Do not add the really unique ZOs entry as it shares the same SV table as the non-uniques and will be added below
        --together with the non-unique as a combined entry
        if saveIdType ~= FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE then
            local savedVarsMarkedItemsSubTableName = savedVarsMarkedItemsNames[saveIdType]
            if savedVarsMarkedItemsSubTableName ~= nil and savedVarsMarkedItemsSubTableName ~= "" and not subTablesAlreadyAdded[savedVarsMarkedItemsSubTableName] then
                local svMarkerIconsDataOfSaveIdType = FCOISsettings[savedVarsMarkedItemsSubTableName]
                if svMarkerIconsDataOfSaveIdType ~= nil and NonContiguousCount(svMarkerIconsDataOfSaveIdType) > 0 then
                    local savedIdTypeName = uniqueItemIdTypeChoices[saveIdType]
                    table.insert(markerIconTypeChoices, savedIdTypeName)
                    table.insert(markerIconTypeChoicesValues, saveIdType)
                end
            end
        end
    end
    --Insert a none entry with value 0 at index 1
    table.insert(markerIconTypeChoices, 1, noneEntryStr)
    table.insert(markerIconTypeChoicesValues, 1, noneEntryValue)
    local nonUniqueAndZOsUniqueSharedSVTable = savedVarsMarkedItemsNames[false]
    local svOfNonUniqueAndZOsUnique = FCOISsettings[nonUniqueAndZOsUniqueSharedSVTable]
    if svOfNonUniqueAndZOsUnique  ~= nil and NonContiguousCount(svOfNonUniqueAndZOsUnique) > 0 then
        --Insert a "non unique" / really unique entry with value false at index 2
        table.insert(markerIconTypeChoices, 2, locVars["options_non_unique_id"] .. "/" .. uniqueItemIdTypeChoices[FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE])
        table.insert(markerIconTypeChoicesValues, 2, false)
    end

    --Update the choices and choicesValues in the LAM delete marker icons dropdown now
    if doUpdateDropdownValues == true then
        local deletableMarkerIconsDD = GetControl("FCOITEMSAVER_SETTINGS_DELETE_MARKER_ICON_TYPE_DROPDOWN") --wm:GetControlByName("FCOITEMSAVER_SETTINGS_DELETE_MARKER_ICON_TYPE_DROPDOWN", "")
        if deletableMarkerIconsDD then
            deletableMarkerIconsDD:UpdateChoices(markerIconTypeChoices, markerIconTypeChoicesValues)
            markerIconsToDeleteType = noneEntryValue
        end
    end
    return markerIconTypeChoices, markerIconTypeChoicesValues
end
FCOIS.BuildMarkerIconsData = buildMarkerIconsData

local function checkIfMarkerIconsToDeleteExist()
    numIconsToDelete = 0
    if markerIconsToDeleteIcon ~= nil and markerIconsToDeleteIcon ~= 0
            and markerIconsToDeleteType ~= nil and markerIconsToDeleteType ~= noneEntryValue then
        local isAllIcons = (markerIconsToDeleteIcon == FCOIS_CON_ICON_ALL) or false
        if isAllIcons then return end

        local savedVarsMarkedItemsNames = FCOIS.addonVars.savedVarsMarkedItemsNames
        local markerIconsToDeleteTypeTable = savedVarsMarkedItemsNames[markerIconsToDeleteType]
        if markerIconsToDeleteTypeTable ~= nil and markerIconsToDeleteTypeTable ~= "" and FCOISsettings[markerIconsToDeleteTypeTable] ~= nil then
            if FCOISsettings[markerIconsToDeleteTypeTable][markerIconsToDeleteIcon] ~= nil then
                numIconsToDelete = NonContiguousCount(FCOISsettings[markerIconsToDeleteTypeTable][markerIconsToDeleteIcon])
            end
        end
    end
end
--Marker icon delete - END --------------------------------------------------------------------


--Other addons - BEGIN --------------------------------------------------------------------
--Get GridList or InventoryGridView icon's size
local function getGridAddonIconSize()
    --Slot size of the addon
    local gridSlotSize = 60
    if GridListActivated == true then
        gridSlotSize = (GridList and GridList.SV and GridList.SV.slot_size) or 52 --Standard GridList slot size is 52
    elseif InventoryGridViewActivated == true then
        gridSlotSize = (InventoryGridView and InventoryGridView.settings and InventoryGridView.settings.vars and InventoryGridView.settings.vars.gridIconSize) or 60 --Standard IGV slot size is 60
    end
    return gridSlotSize
end

local function removeInventoryFragment()
    --Hide the inventory scene
    gameMenuIngameScene:RemoveFragment(INVENTORY_FRAGMENT)
    gameMenuIngameScene:RemoveFragment(RIGHT_PANEL_BG_FRAGMENT)
    FCOIS.preventerVars.lamMenuOpenAndShowingInvPreviewForGridListAddon = false
end

--Preview the inventory fragment and background even in the LAM panel
local function previewInventoryFragment()
    --Only if the GridList addon is active and it's FCOIS settings submenu for the marker icons is currently opened
    if (GridListActivated == true or InventoryGridViewActivated == true) and FCOIS_LAM_SUBMENU_OTHER_ADDONS_GRIDLIST and FCOIS_LAM_SUBMENU_OTHER_ADDONS_GRIDLIST.open == true then
        if FCOIS.preventerVars.lamMenuOpenAndShowingInvPreviewForGridListAddon == false then
            --Show the inventory scene
            gameMenuIngameScene:AddFragment(INVENTORY_FRAGMENT)
            gameMenuIngameScene:AddFragment(RIGHT_PANEL_BG_FRAGMENT)
            FCOIS.preventerVars.lamMenuOpenAndShowingInvPreviewForGridListAddon = true
        else
            removeInventoryFragment()
        end
    end
end

--The list of recipe addons
local function buildRecipeAddonsList()
    local recipeAddonsAvailable = FCOIS.otherAddons.recipeAddonsSupported
    for recipeAddonIdx, recipeAddonName in pairs(recipeAddonsAvailable) do
        table.insert(recipeAddonsListValues, recipeAddonIdx)
        table.insert(recipeAddonsList, recipeAddonName)
    end
end

--The list for motifs #308
local function buildMotifsAddonsList()
    local motifAddonsAvailable = FCOIS.otherAddons.motifAddonsSupported
    for motifAddonIdx, motifAddonName in pairs(motifAddonsAvailable) do
        table.insert(motifsAddonsListValues, motifAddonIdx)
        table.insert(motifsAddonsList, motifAddonName)
    end
end


--The list of research addons
local function buildResearchAddonsList()
    local researchAddonsAvailable = FCOIS.otherAddons.researchAddonsSupported
    for researchAddonIdx, researchAddonName in pairs(researchAddonsAvailable) do
        local researchAddonNameColored = researchAddonName
        local colorRed = false
        if researchAddonIdx ~= FCOIS_RESEARCH_ADDON_ESO_STANDARD then
            if _G[researchAddonName] == nil then
                if researchAddonIdx == FCOIS_RESEARCH_ADDON_CSFAI then
                    if not FCOIS.otherAddons.craftStoreFixedAndImprovedActive then
                        colorRed = true
                    end
                else
                    colorRed = true
                end

            end
            if colorRed == true then
                researchAddonNameColored = "|cFF0000" .. researchAddonNameColored .. "|r"
            end
        end
        table.insert(researchAddonsListValues, researchAddonIdx)
        table.insert(researchAddonsList, researchAddonNameColored)
    end
end

--The list of Set collection addons
local function buildSetCollectionAddonsList()
    local setCollectionAddonsAvailable = FCOIS.otherAddons.setCollectionBookAddonsSupported
    for setCollectionAddonIdx, setCollectionAddonName in pairs(setCollectionAddonsAvailable) do
        table.insert(setCollectionAddonsListValues, setCollectionAddonIdx)
        table.insert(setCollectionAddonsList, setCollectionAddonName)
    end
end

local function checkAndRunAutomaticSetItemCollectionMarkerApply(setCollectionsType)
    --d("[FCOIS]checkAndRunAutomaticSetItemCollectionMarkerApply - setCollectionsType: " ..tos(setCollectionsType))
    FCOISsettings = FCOISsettings or FCOIS.settingsVars.settings
    isIconEnabled = isIconEnabled or FCOISsettings.isIconEnabled
    if FCOISsettings.autoMarkSetsItemCollectionBook == true and
            (
                    (FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon ~= FCOIS_CON_ICON_NONE and
                            isIconEnabled[FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon] == true) or
                            (FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon ~= FCOIS_CON_ICON_NONE and
                                    isIconEnabled[FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon] == true)
            )
    then
        scanInventoryItemsForAutomaticMarks(nil, nil, setCollectionsType, false)
    end
end
--Other addons - END --------------------------------------------------------------------


--Traits - BEGIN -------------------------------------------------------------------------------------------------------
local function buildTraitCheckboxes()
    if traitData == nil then return nil end
    locVars = FCOISlocVars.fcois_loc

    local typeToTable = {
        [1] = armorTraitControls,
        [2] = jewelryTraitControls,
        [3] = weaponTraitControls,
        [4] = weaponShieldTraitControls,
    }
    --Loop over all trait types
    for traitType, traitTypeData in pairs(traitData) do
        --Loop over each traitTypes's data
        for traitTypeItemTrait, traitTypeName in pairs(traitTypeData) do
            --local settingsVar = typeToSettings[traitType][traitTypeItemTrait]
            local ref = tos(traitType) .. "_" .. tos(traitTypeName)
            local name = traitTypeName
            local tooltip = traitTypeName
            local data = { type = "checkbox", width = "half" }
            local disabledFunc = function() return not FCOISsettings.autoMarkSets end
            local getFunc
            local setFunc
            local getFuncDD
            local setFuncDD
            local defaultSettings
            local defaultSettingsDD
            local disabledFuncDD
            --Armor
            if traitType == 1 then
                getFunc = function() return FCOISsettings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait] end
                getFuncDD = function() return FCOISsettings.autoMarkSetsCheckArmorTraitIcon[traitTypeItemTrait] end
                setFunc = function(value) FCOIS.settingsVars.settings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait] = value
                    if value == true then
                        scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                    end
                end
                setFuncDD = function(value) FCOISsettings.autoMarkSetsCheckArmorTraitIcon[traitTypeItemTrait] = value end
                defaultSettings     = FCOISdefaultSettings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait]
                defaultSettingsDD   = FCOISdefaultSettings.autoMarkSetsCheckArmorTraitIcon[traitTypeItemTrait]
                disabledFuncDD = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsCheckArmorTrait[traitTypeItemTrait] end
                --Jewelry
            elseif traitType == 2 then
                getFunc = function() return FCOISsettings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait] end
                getFuncDD = function() return FCOISsettings.autoMarkSetsCheckJewelryTraitIcon[traitTypeItemTrait] end
                setFunc = function(value) FCOIS.settingsVars.settings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait] = value
                    if value == true then
                        scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                    end
                end
                setFuncDD = function(value) FCOISsettings.autoMarkSetsCheckJewelryTraitIcon[traitTypeItemTrait] = value end
                defaultSettings     = FCOISdefaultSettings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait]
                defaultSettingsDD   = FCOISdefaultSettings.autoMarkSetsCheckJewelryTraitIcon[traitTypeItemTrait]
                disabledFuncDD = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsCheckJewelryTrait[traitTypeItemTrait] end
                --Weapons or shields
            elseif traitType == 3 or traitType == 4 then
                getFunc = function() return FCOISsettings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait] end
                getFuncDD = function() return FCOISsettings.autoMarkSetsCheckWeaponTraitIcon[traitTypeItemTrait] end
                setFunc = function(value) FCOIS.settingsVars.settings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait] = value
                    if value == true then
                        scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                    end
                end
                setFuncDD = function(value) FCOISsettings.autoMarkSetsCheckWeaponTraitIcon[traitTypeItemTrait] = value end
                defaultSettings     = FCOISdefaultSettings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait]
                defaultSettingsDD   = FCOISdefaultSettings.autoMarkSetsCheckWeaponTraitIcon[traitTypeItemTrait]
                disabledFuncDD = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsCheckWeaponTrait[traitTypeItemTrait] end
            end
            --Create the dropdownbox now
            local createdTraitCB = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdTraitCB ~= nil then
                table.insert(typeToTable[traitType], createdTraitCB)
                --Add an additional dropdownbox for the icon, for each trait
                --local settingsVarDD = typeToSettingsDD[traitType][traitTypeItemTrait]
                local refDD = ref .. "_DD"
                local nameDD = traitTypeName .. " " .. locVars[optionsIcon .. "1_texture"]
                local tooltipDD = "Icon " .. traitTypeName
                local createdIconTraitDDBox = CreateDropdownBox(refDD, nameDD, tooltipDD, disabledFuncDD, getFuncDD, setFuncDD, defaultSettingsDD, iconsList, iconsListValues, iconsList, nil, "half", true, true)
                if createdIconTraitDDBox ~= nil then
                    table.insert(typeToTable[traitType], createdIconTraitDDBox)
                end
            end
        end -- for traitTypeName, traitTypeItemTrait in pairs(traitTypeData) do
    end -- for traitType, traitTypeData in pairs(traitData) do
end
--Traits - END ---------------------------------------------------------------------------------------------------------


--Preview icon/color - BEGIN --------------------------------------------------------------------
--Get the preview control by help of the iconNr
local function getPreviewControlByIconNr(previewType, iconNr)
    return GetControl(fcoisLAMSettingsReferencePrefix .. tos(previewType) .. tos(iconNr) .. previewSelect) --wm:GetControlByName(fcoisLAMSettingsReferencePrefix .. tos(previewType) .. tos(iconNr) .. previewSelect, "")
end

local function changePreViewIconSize(previewType, iconNr, size, doNotUpdateMarkers)
    doNotUpdateMarkers = doNotUpdateMarkers or false
    local iconCtrl = getPreviewControlByIconNr(previewType, iconNr)
    if not iconCtrl or not size then return end
    iconCtrl:SetIconSize(size)
    if not doNotUpdateMarkers then
        --Set global variable to update the marker colors and textures
        FCOIS.preventerVars.gUpdateMarkersNow = true
    end
end

local function changePreviewIconColor(previewType, iconNr, r, g, b, a, doNotUpdateMarkers)
    doNotUpdateMarkers = doNotUpdateMarkers or false
    local iconCtrl = getPreviewControlByIconNr(previewType, iconNr)
    if not iconCtrl or not r or not g or not g or not a then return end
    iconCtrl:SetColor(ZO_ColorDef:New(r,g,b,a))
    if not doNotUpdateMarkers then
        --Set global variable to update the marker colors and textures
        FCOIS.preventerVars.gUpdateMarkersNow = true
    end
end

local function updateFilterButtonColorAndTexture(filterButtonNr, iconNr)
    local p_button = GetControl(ZOsControlVars.FCOISfilterButtonNames[filterButtonNr]) --wm:GetControlByName(ZOsControlVars.FCOISfilterButtonNames[filterButtonNr], "")
    if p_button == nil or filterButtonNr == nil or iconNr == nil then return end
    updateFCOISFilterButtonColorsAndTextures(iconNr, p_button, FCOIS_CON_FILTER_BUTTON_STATE_DO_NOT_UPDATE_COLOR)
end

local function changePreviewLabelText(previewType, iconNr, text, doNotUpdateMarkers, iconType) --#301 LibSets set search favorites
    doNotUpdateMarkers = doNotUpdateMarkers or false
    local iconCtrl = getPreviewControlByIconNr(previewType, iconNr)
    if not iconCtrl or not iconCtrl.label or not text then return end
    locVars = FCOISlocVars.fcois_loc

    if iconType == nil then
        iconCtrl.label:SetText(locVars[optionsIcon..tos(iconNr).."_texture"] .. ": " .. text)
    --#301 LibSets set search favorites
    elseif iconType == "LibSetsSetSearchFavorite" then
        iconCtrl.label:SetText(locVars[optionsIcon..tos(1).."_texture"] .. ": " .. text)
    end

    if not doNotUpdateMarkers then
        --Set global variable to update the marker colors and textures
        FCOIS.preventerVars.gUpdateMarkersNow = true
    end
end

--Set the preview icon values (width, height, color, etc.)
local function InitPreviewIcon(markerIconIndex)
    FCOISsettings = FCOISsettings or FCOIS.settingsVars.settings
    local iconSettings = FCOISsettings.icon[markerIconIndex]
    local preViewControl = _G[strformat(fcoisLAMSettingsReferencePrefix .. filterButton .. "%d" .. previewSelect, markerIconIndex)]
    if preViewControl == nil then return false end
    locVars = FCOISlocVars.fcois_loc

    preViewControl:SetColor(ZO_ColorDef:New(iconSettings.color))
    preViewControl:SetIconSize(iconSettings.size)
    --Show the curerntly selected iconIndex at the coor picker's name, behind the :
    local text = strformat("%s: %s", locVars[strformat(optionsIcon .. "%d_texture", markerIconIndex)], texturesList[iconSettings.texture])
    preViewControl.label:SetText(text)
end
--Preview icon/color - END --------------------------------------------------------------------

--Icon dropdown box sort order - BEGIN ---------------------------------------------------------------------------------
--Build the dropdown boxes for the icon sort order
--[[
local function buildIconSortOrderDropdowns()
    if numFilterIcons <= 0 then return nil end
    locVars = FCOISlocVars.fcois_loc
    --Get the FCOIS icon count
    --The return array of dropdown boxes for the LAM panel
    local createdIconSortDDBoxes = {}
    --Static values
    --Static dropdown entries
    for FCOISiconNr=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        local name = locVars[optionsIcon .. "_sort_" .. tos(FCOISiconNr)]
        local tooltip = locVars[optionsIcon .. "_sort_order" .. tooltipSuffix]
        if name ~= nil and name ~= "" then
            local ref = "Icon_Sort_Dropdown_" .. tos(FCOISiconNr)
            local getFunc = function() return FCOIS.settingsVars.settings.iconSortOrder[FCOISiconNr] end
            local setFunc = function(value)
                FCOIS.settingsVars.settings.icon[value].sortOrder = FCOISiconNr
                FCOIS.settingsVars.settings.iconSortOrder[FCOISiconNr] = value
                --checkAllSortOrderDDBoxesForDuplicates()
            end
            local defSettings = FCOISdefaultSettings.iconSortOrder[FCOISiconNr]
            --Create the dropdownbox now
            local createdIconSortDDBox = CreateDropdownBox(ref, name, tooltip, nil, getFunc, setFunc, defSettings, iconsList, iconsListValues, iconsList, nil, "full", true, true)
            if createdIconSortDDBox ~= nil then
                table.insert(createdIconSortDDBoxes, createdIconSortDDBox)
            end
        end
    end
    return createdIconSortDDBoxes
end
]]
--Icon dropdown box sort order - END -----------------------------------------------------------------------------------


--Update icon lists - BEGIN --------------------------------------------------------------------
local function updateIconsList(typeToBuild, withIcons, withNoneEntry, iconsListTmp, iconsListValuesTmp)
    getLAMMarkerIconsDropdown = getLAMMarkerIconsDropdown or FCOIS.GetLAMMarkerIconsDropdown

    --Build the icons & choicesValues list for the LAM icon dropdown boxes
    if iconsListTmp == nil or iconsListValuesTmp == nil then
        FCOIS.preventerVars.gCalledFromInternalFCOIS = true
        iconsListTmp, iconsListValuesTmp = getLAMMarkerIconsDropdown(typeToBuild, withIcons, withNoneEntry)
    end
    if not iconsListTmp or not iconsListValuesTmp then return end
    if typeToBuild == "standard" then
        if withNoneEntry == true then
            iconsListNone                   = iconsListTmp
            iconsListValuesNone             = iconsListValuesTmp
            FCOIS.LAMiconsListNone          = iconsListNone
            FCOIS.LAMiconsListValuesNone    = iconsListValuesNone
        else
            locVars = FCOISlocVars.fcois_loc

            iconsList                       = iconsListTmp
            iconsListValues                 = iconsListValuesTmp
            FCOIS.LAMiconsList              = iconsList
            FCOIS.LAMiconsListValues        = iconsListValues

            --Create/Update the iconsList with the all entries
            local l_iconsListWithAllEntry =         ZO_ShallowTableCopy(iconsList)
            table.insert(l_iconsListWithAllEntry, 1, locVars["options_dropdown_all"])
            local l_iconsListWithAllEntryValues =   ZO_ShallowTableCopy(iconsListValues)
            table.insert(l_iconsListWithAllEntryValues, 1, FCOIS_CON_ICON_ALL)
            iconsListWithAllEntry           =       l_iconsListWithAllEntry
            iconsListWithAllEntryValues     =       l_iconsListWithAllEntryValues
            FCOIS.LAMiconsListWithAllEntry       =  iconsListWithAllEntry
            FCOIS.LAMiconsListWithAllEntryValues =  iconsListWithAllEntryValues
        end
    elseif typeToBuild == "recipe" then
        iconsListRecipe                     = iconsListTmp
        iconsListValuesRecipe               = iconsListValuesTmp
        FCOIS.LAMiconsListRecipe            = iconsListRecipe
        FCOIS.LAMiconsListValuesRecipe      = iconsListValuesRecipe
    end
end

local function updateAllIconsList()
    --Build the icons & choicesValues list for the LAM icon dropdown boxes
    updateIconsList("standard", true, false, nil, nil)
    --Build the icons list with a first entry "None"
    updateIconsList("standard", true, true, nil, nil)
    --Build the icons list for recipes
    updateIconsList("recipe", true, true, nil, nil)
end

--Function to update the comboboxes of the LAM dropdowns holding the "iconList"/"iconsListStandardIconOnKeybind" entries
--if an icon gets disabled or renamed
local function updateIconListDropdownEntries()
    FCOIS.preventerVars.gUpdateMarkersNow = true
    if LAMdropdownsWithIconList == nil then return nil end
    getLAMMarkerIconsDropdown = getLAMMarkerIconsDropdown or FCOIS.GetLAMMarkerIconsDropdown

    for dropdownCtrlName, updateData in pairs(LAMdropdownsWithIconList) do
        local dropdownCtrl = GetControl(dropdownCtrlName) --wm:GetControlByName(dropdownCtrlName, "")
        if dropdownCtrl == nil or updateData == nil then return nil end
        if updateData["choices"] == nil then updateData["choices"] = "standard" end
        FCOIS.preventerVars.gCalledFromInternalFCOIS = true
        local choices, choicesValues, choicesTooltips = getLAMMarkerIconsDropdown(updateData["choices"], updateData["withIcons"], updateData["withNoneEntry"])
        dropdownCtrl:UpdateChoices(choices, choicesValues, choicesTooltips)

        --Update the FCOIS internal tables with the updated LAM dropdown icon lists
        updateIconsList(updateData["choices"], updateData["withIcons"], updateData["withNoneEntry"], choices, choicesValues)
    end
end
--Update icon lists - END --------------------------------------------------------------------

--Update submenu text - BEGIN --------------------------------------------------------------------
--Update the submenu name of a marker icon
local function updateMarkerIconSubmenuName(iconId, iconName)
    if iconId == nil then return end
    locVars = FCOISlocVars.fcois_loc

    --pattern for the dynamic icon submenu refernece is: fcoisLAMSettingsReferencePrefix .. "MarkerIcon" ..tos(iconId) .. submenuSuffix
    local subMenuRef = strformat(subMenuNamePattern, tos(iconId))
    local subMenuCtrl = GetControl(subMenuRef)
    if subMenuCtrl ~= nil then
        local name
        --Is a gear icon submenu?
        local gearIndex = mappingVars.iconToGear[iconId]
--d(">Found submenu: " ..tos(subMenuRef) .. ", isGear: " ..tos(gearIndex ~= nil or false))
        if gearIndex ~= nil then
            name = locVars[optionsIcon .. "s_gear" .. tos(mappingVars.iconToGear[iconId])]
        else
            --Dynamic icon submenu
            local dynIconNameStart = optionsIcon .. tos(iconId)
            name = locVars[dynIconNameStart .. colorSuffix]
        end
        local subMenuNameSuffix = ": \'" .. iconName .. "\'"
--d(">name: " .. tos(name) .. ", suffix: " ..tos(subMenuNameSuffix))
        if name and name ~= "" then
            name = name .. subMenuNameSuffix
        else
            name = subMenuNameSuffix
        end
        if name and name ~= "" then
            subMenuCtrl.data.name = name
            subMenuCtrl:UpdateValue()
        end
    end
end
--Update submenu text - END --------------------------------------------------------------------


--Update marker icon name - BEGIN --------------------------------------------------------------------
--If name of the marker icon is missing,  reset it to a default
local function defaultIconNameCheck(refCtrlName, iconName, iconId)
    if iconName == nil or iconName == "" then
        if iconId ~= nil then
            --Get the default icon Name
            FCOISdefaultSettings = FCOISdefaultSettings or FCOIS.settingsVars.defaults
            iconName = FCOISdefaultSettings.icon[iconId].name
        end
        --if iconName is still nil or "" use a generic default name
        if iconName == nil or iconName == "" then
            iconName = "!!! ERROR: Icon name missing !!!"
        end
    end
--d("[FCOIS]defaultIconNameCheck: " ..tos(iconName) .. ", refCtrlName: " ..tos(refCtrlName))
    if refCtrlName ~= nil and refCtrlName ~= "" then
        local refCtrl = GetControl(refCtrlName)
        if refCtrl ~= nil and refCtrl.editbox ~= nil then
--d(">ref was found, updating editbox now")
            --Prevent that UpdateValue of the editbox will call SetFunc again and produce an endless loop!
            FCOIS.preventerVars.doNotCheckForDefaultName = true
            --refCtrl:UpdateValue(false, iconName)
            refCtrl.editbox:SetText(iconName)
        end
    end
    --Update the submenu text with default submenu's text + ": " .. <the icon's name>
    updateMarkerIconSubmenuName(iconId, iconName)
    FCOIS.preventerVars.doNotCheckForDefaultName = false
    return iconName
end
--Update marker icon name - END --------------------------------------------------------------------


--Update marker icon enabled data - BEGIN --------------------------------------------------------------------
    local function updateMarkerIconsOutputOrder(sourceTab)
--d("[FCOIS]updateMarkerIconsOutputOrder")
        FCOIS.settingsVars.settings.markerIconsOutputOrder = {}
        for idx, data in ipairs(sourceTab) do
--d(">>idx: " ..tos(idx) .. "; value: " ..tos(data.value))
            --FCOIS.settingsVars.settings.icon[data.value].outputOrder = idx -- 20240504 -> Not used?
            FCOIS.settingsVars.settings.markerIconsOutputOrder[idx] = data.value
        end
    end

    --Update enabled and sort data, for the sort OrderListBoxWidgets
    local function updateEnabledMarkerIconsSortOrderListData(isInitialLAMCall) --#279
        isInitialLAMCall = isInitialLAMCall or false
        local settingsBase = FCOIS.settingsVars
        local settings = settingsBase.settings
        --local defaults = settingsBase.defaults
        --local l_isIconEnabled = settings.isIconEnabled

        local currentMarkerIconsOutputOrder = ZO_ShallowTableCopy(settings.markerIconsOutputOrder)
        local currentMarkerIconsOutputOrderEntries = ZO_ShallowTableCopy(settings.markerIconsOutputOrderEntries)
--FCOIS._debugCurrentMarkerIconsOutputOrder = currentMarkerIconsOutputOrder
--FCOIS._debugCurrentMarkerIconsOutputOrderEntries = currentMarkerIconsOutputOrderEntries

        local currentIconSortOrder = ZO_ShallowTableCopy(settings.iconSortOrder)
        local currentIconSortOrderEntries = ZO_ShallowTableCopy(settings.iconSortOrderEntries)
        --local defaultMarkerIconsOutputOrderEntries = defaults.markerIconsOutputOrderEntries
        --local defaultIconSortOrderEntries = defaults.iconSortOrderEntries


--d("[FCOIS]updateEnabledMarkerIconsSortOrderListData-isInitialLAMCall: " .. tos(isInitialLAMCall) ..", numIcons: " .. tos(FCOIS.numVars.gFCONumFilterIcons))

        --Get the updated markerIcon textures and names and recolor dis-/enabled entries properly
        FCOIS.preventerVars.gCalledFromInternalFCOIS = true
        local iconsListStandard, iconsListValuesStandard = FCOIS.GetLAMMarkerIconsDropdown("standard", true, false)

        --Reset the list variables for the LAM OrderListBox widgets
        FCOIS.settingsVars.settings.markerIconsOutputOrderEntries = {}
        FCOIS.settingsVars.settings.iconSortOrderEntries = {}


        --#279 20240329 - Rebuild this function and total defaults values to properly update the OrderListBox widgets!
        --Rebuild the list variables for the LAM OrderListBox widgets
        for iconNumber=FCOIS_CON_ICON_LOCK, FCOIS.numVars.gFCONumFilterIcons, 1 do
            local iconIndex = ZO_IndexOfElementInNumericallyIndexedTable(iconsListValuesStandard, iconNumber)
            local name = iconsListStandard[iconIndex] or "Icon " ..tos(iconNumber)

------------------------------------------------------------------------------------------------------------------------
            local currentMarkerIconOutputOrderIndex = ZO_IndexOfElementInNumericallyIndexedTable(currentMarkerIconsOutputOrder, iconNumber)
--d(">iconNumber: " ..tos(iconNumber) .. ", iconIndex: " .. tos(iconIndex) .. ", name: " ..tos(name) .. ", currentMarkerIconOutputOrderIndex: " .. tos(currentMarkerIconOutputOrderIndex))
            local existingOutputOrderEntry = currentMarkerIconsOutputOrderEntries[currentMarkerIconOutputOrderIndex]
            if existingOutputOrderEntry ~= nil then
--d(">>outputOrder exists: " ..tos(currentMarkerIconOutputOrderIndex))
                --Icon was ordered already: Reuse that already set value again, but update the name and tooltip (for the enabled marker icon state)
                FCOIS.settingsVars.settings.markerIconsOutputOrderEntries[currentMarkerIconOutputOrderIndex] = {
                    uniqueKey	= iconNumber,
                    value		= iconNumber,
                    text        = name,
                    tooltip     = name
                }
            else
--d(">>outputOrder: Using default")
                --Icon was not ordered already: Use default order = icon number
                FCOIS.settingsVars.settings.markerIconsOutputOrderEntries[iconNumber] = {
                    uniqueKey	= iconNumber,
                    value		= iconNumber,
                    text 		= name,
                    tooltip 	= name,
                }
            end

------------------------------------------------------------------------------------------------------------------------
            local currentMarkerIconContextMenuOrderIndex = ZO_IndexOfElementInNumericallyIndexedTable(currentIconSortOrder, iconNumber)
--d(">currentMarkerIconContextMenuOrderIndex: " .. tos(currentMarkerIconContextMenuOrderIndex))
            if currentIconSortOrderEntries[currentMarkerIconContextMenuOrderIndex] ~= nil then
--d(">>contextMenuOrder: Exist")
                --Icon was ordered already: Reuse that already set value again, but update the name and tooltip (for the enabled marker icon state)
                currentIconSortOrderEntries[currentMarkerIconContextMenuOrderIndex].text = name
                currentIconSortOrderEntries[currentMarkerIconContextMenuOrderIndex].tooltip = name
                FCOIS.settingsVars.settings.iconSortOrderEntries[currentMarkerIconContextMenuOrderIndex] = currentIconSortOrderEntries[currentMarkerIconContextMenuOrderIndex]
            else
--d(">>contextMenuOrder: Using default")
                --Icon was not ordered already: Use default order = icon number
                FCOIS.settingsVars.settings.iconSortOrderEntries[iconNumber] = {
                    uniqueKey	= iconNumber,
                    value		= iconNumber,
                    text 		= name,
                    tooltip 	= name,
                }
            end
        end


        if isInitialLAMCall == true then
            --#279 Update the markerIcons output order table too, based on the markerIconsOutputOrderEntries (LAMOrderListBox)
            updateMarkerIconsOutputOrder(FCOIS.settingsVars.settings.markerIconsOutputOrderEntries)
            return
        end

        --Update the LAM OrderlistBox data now
        if FCOItemSaver_Settings_IconSortOrder_Output_OrderListBox ~= nil then
            FCOItemSaver_Settings_IconSortOrder_Output_OrderListBox:UpdateValue(false, FCOIS.settingsVars.settings.markerIconsOutputOrderEntries) -- #279
        end
        if FCOItemSaver_Settings_IconSortOrder_OrderListBox ~= nil then
            FCOItemSaver_Settings_IconSortOrder_OrderListBox:UpdateValue(false, FCOIS.settingsVars.settings.iconSortOrderEntries) -- #279
        end
    end
--Update marker icon enabled data - END --------------------------------------------------------------------


-- ============= local helper functions - END ======================================================================


-- ============= run code once before LAM settings menu will be build - BEGIN ===========================================
local function runOnceBeforeLAMPanelGetsCreated()
    --Initialize the icon lists
    --updateAllIconsList() --Will load the FCOIS settings too early! Will be called again later at runOnceAsLAMPanelGetsCreated

    --Update the table of LAM dropdowns which use the icon lists
    LAMdropdownsWithIconList = {
        ["FCOItemSaver_Standard_Icon_On_Keybind_Dropdown"]              =           { ["choices"] = 'standard', ["choicesValues"] = iconsListValues,        ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = false, },
        ["FCOItemSaver_Icon_On_Automatic_Set_Part_Dropdown"]            =           { ["choices"] = 'standard', ["choicesValues"] = iconsListValues,        ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = false, },
        ["FCOItemSaver_Icon_On_Automatic_Non_Wished_Set_Part_Dropdown"] =           { ["choices"] = 'standard', ["choicesValues"] = iconsListValues,        ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = false, },
        ["FCOItemSaver_Icon_On_Automatic_Crafted_Items_Dropdown"]       =           { ["choices"] = 'standard', ["choicesValues"] = iconsListValues,        ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = false, },
        ["FCOItemSaver_Icon_On_Automatic_Recipe_Dropdown"]              =           { ["choices"] = 'standard', ["choicesValues"] = iconsListValues,        ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = false, },
        ["FCOItemSaver_Icon_On_Automatic_Motif_Dropdown"]               =           { ["choices"] = 'standard', ["choicesValues"] = iconsListValues,        ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = false, },
        ["FCOItemSaver_Icon_On_Automatic_Quality_Dropdown"]             =           { ["choices"] = 'standard', ["choicesValues"] = iconsListValues,        ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = false, },
        ["FCOItemSaver_Icon_On_Automatic_SetCollections_UnknownIcon_Dropdown"]  =   { ["choices"] = 'standard', ["choicesValues"] = iconsListValuesNone,    ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = true,  },
        ["FCOItemSaver_Icon_On_Automatic_SetCollections_KnownIcon_Dropdown"]    =   { ["choices"] = 'standard', ["choicesValues"] = iconsListValuesNone,    ["choicesTooltips"] = nil, ["withIcons"] = true, ["withNoneEntry"] = true,  },
    }
end

--Run code once before LAM panel gets created
runOnceBeforeLAMPanelGetsCreated()
-- ============= run code once before LAM settings menu will be build - END ===========================================





--======================================================================================================================
--======================================================================================================================
--======================================================================================================================
-- ============= LAM control creation as LAM panel get's opened - BEGIN ================================================
--======================================================================================================================
--======================================================================================================================
--======================================================================================================================

--==================== SetTracker - BEGIN ======================================
--Function to build the SetTracker dropdown boxes
--#302  SetTracker support disabled with FCOOIS v2.6.1, for versions <300
local function buildSetTrackerDDBoxes()
    if not FCOIS.otherAddons.SetTracker.isActive or not SetTrack or not SetTrack.GetMaxTrackStates then return nil end
    --Get the amount of tracking states
    local STtrackingStates = SetTrack.GetMaxTrackStates()
    if STtrackingStates == nil or STtrackingStates <= 0 then return false end
    locVars = FCOISlocVars.fcois_loc

    --Build the icons list with a first entry "None"
    updateIconsList("standard", true, true)

    --The return array for the LAM panel
    local createdSetTrackerDDBoxes = {}

    --Static values
    local disabledChecks = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end
    --Static dropdown entries
    local choicesTooltipsList = {}
    choicesTooltipsList[1] = locVars[optionsIcon .. "_none"]
    for _, FCOISiconNr in ipairs(iconsListValues) do
        --local iconDescription = "FCOItemSaver icon " .. tos(FCOISiconNr)
        local locNameStr = FCOISlocVars.iconEndStrArray[FCOISiconNr]
        local iconName = FCOIS.GetIconText(FCOISiconNr) or locVars[optionsIcon .. tos(FCOISiconNr) .. "_" .. locNameStr] or "Icon " .. tos(FCOISiconNr)
        --Add each FCOIS icon description to the list
        table.insert(choicesTooltipsList, iconName)
    end

    --For each SetTracker tracking state (set) build one label with the description and one dropdown box with the FCOIS icons
    for i=0, (STtrackingStates-1), 1 do
        local ref = "SetTracker_State_" .. tos(i)
        local name = ""
        local tooltip = ""
        if SetTrack.GetTrackStateInfo then
            local _, sTrackName, _ = SetTrack.GetTrackStateInfo(i)
            --Concatenate the standard SetTracker prefix string (SI_SETTRK_PREFIX_TRACKSTATE) for a tracked set and the number of the tracking state
            local sTrackNameStandard = GetString(SI_SETTRK_PREFIX_TRACKSTATE) .. tos(i)
            --Is the name specified for the setTracker state? Otherwise don't add it
            if sTrackName ~= nil and sTrackName ~= "" and sTrackName ~= sTrackNameStandard then
                --d(">> build FCOIS SetTracker dropdown boxes: " .. tos(sTrackName) .. ", sTrackNameStandard: " .. tos(sTrackNameStandard))
                local alternativeNameText = zo_strf(locVars["options_auto_mark_settrackersets_to_fcois_icon"], tos(i+1))
                name = sTrackName or alternativeNameText or "SetTracker state " .. tos(i+1)
                tooltip = alternativeNameText
            end
        end
        --Is the tracking state name determined?
        if name ~= "" then
            local getFunc = function() return FCOISsettings.setTrackerIndexToFCOISIcon[i] end
            local setFunc = function(value) FCOISsettings.setTrackerIndexToFCOISIcon[i] = value end
            local defaultSettings = FCOISsettings.setTrackerIndexToFCOISIcon[i]
            --Create the dropdownbox now
            local createdSetTrackerDDBox = CreateDropdownBox(ref, name, tooltip, disabledChecks, getFunc, setFunc, defaultSettings, iconsListNone, iconsListValuesNone, choicesTooltipsList, nil, "full", true, true)
            if createdSetTrackerDDBox ~= nil then
                table.insert(createdSetTrackerDDBoxes, createdSetTrackerDDBox)
            end
        end
    end
    return createdSetTrackerDDBoxes
end

local function LAMSubmenuDolgubonLazyWritCreator()
    local submenuControls = {}
    locVars = FCOISlocVars.fcois_loc

    if not FCOIS.otherAddons.LazyWritCreatorActive or WritCreater == nil then return submenuControls end

    submenuControls = {
        {
            type = "checkbox",
            name = locVars["options_auto_mark_crafted_writ_items"],
            tooltip = locVars["options_auto_mark_crafted_writ_items" .. tooltipSuffix],
            getFunc = function() return FCOISsettings.autoMarkCraftedWritItems end,
            setFunc = function(value)
                FCOISsettings.autoMarkCraftedWritItems = value
            end,
            disabled = function()
                return  not FCOIS.otherAddons.LazyWritCreatorActive
                        or (not isIconEnabled[FCOISsettings.autoMarkCraftedWritCreatorItemsIconNr] and isIconEnabled[FCOISsettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr])
            end,
            width = "full",
            default = FCOISdefaultSettings.autoMarkCraftedWritItems,
        },
        {
            type = 'dropdown',
            name = locVars["options_auto_mark_crafted_writ_items_icon"],
            tooltip = locVars["options_auto_mark_crafted_writ_items_icon" .. tooltipSuffix],
            choices = iconsList,
            choicesValues = iconsListValues,
            scrollable = true,
            getFunc = function() return FCOISsettings.autoMarkCraftedWritCreatorItemsIconNr
            end,
            setFunc = function(value)
                FCOISsettings.autoMarkCraftedWritCreatorItemsIconNr = value
                --Check if the icon needs to get the setting to skip the research check enabled
                if value ~= nil then
                    setDynamicIconAntiResearchCheck(value, true)
                end
            end,
            reference = "FCOItemSaver_Icon_On_Automatic_Crafted_Writ_Items_Dropdown",
            disabled = function() return not FCOIS.otherAddons.LazyWritCreatorActive or not FCOISsettings.autoMarkCraftedWritItems end,
            width = "half",
            default = FCOISdefaultSettings.autoMarkCraftedWritCreatorItemsIconNr,
        },
        {
            type = 'dropdown',
            name = locVars["options_auto_mark_crafted_masterwrit_items_icon"],
            tooltip = locVars["options_auto_mark_crafted_masterwrit_items_icon" .. tooltipSuffix],
            choices = iconsList,
            choicesValues = iconsListValues,
            scrollable = true,
            getFunc = function() return FCOISsettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr
            end,
            setFunc = function(value)
                FCOISsettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr = value
                --Check if the icon needs to get the setting to skip the research check enabled
                if value ~= nil then
                    setDynamicIconAntiResearchCheck(value, true)
                end
            end,
            reference = "FCOItemSaver_Icon_On_Automatic_Crafted_MasterWrit_Items_Dropdown",
            disabled = function() return not FCOIS.otherAddons.LazyWritCreatorActive or not FCOISsettings.autoMarkCraftedWritItems end,
            width = "half",
            default = FCOISdefaultSettings.autoMarkCraftedWritCreatorMasterWritItemsIconNr,
        },
    }
    return submenuControls
end

local function LAMSubmenuItemCooldownTracker() -- #306
    local submenuControls = {}
    locVars = FCOISlocVars.fcois_loc

    if not FCOIS.otherAddons.ItemCooldownTrackerActive then return submenuControls end

    submenuControls = {
        {
            type = "checkbox",
            name = locVars["options_automark_itemcooldowntracker"],
            tooltip = locVars["options_automark_itemcooldowntracker" .. tooltipSuffix],
            getFunc = function() return FCOISsettings.autoMarkItemCoolDownTrackerTrackedItems end,
            setFunc = function(value)
                FCOISsettings.autoMarkItemCoolDownTrackerTrackedItems = value
            end,
            width = "half",
            default = FCOISdefaultSettings.autoMarkItemCoolDownTrackerTrackedItems,
        },
        {
            type = 'dropdown',
            name = locVars["options_icon1_texture"],
            tooltip = locVars["options_automark_itemcooldowntracker_icon_TT" .. tooltipSuffix],
            choices = iconsList,
            choicesValues = iconsListValues,
            scrollable = true,
            getFunc = function() return FCOISsettings.itemCoolDownTrackerTrackedItemsMarkerIcon
            end,
            setFunc = function(value)
                FCOISsettings.itemCoolDownTrackerTrackedItemsMarkerIcon = value
            end,
            reference = "FCOItemSaver_Icon_On_Automatic_ItemCooldownTracker_Dropdown",
            disabled = function() return not FCOISsettings.autoMarkItemCoolDownTrackerTrackedItems end,
            width = "half",
            default = FCOISdefaultSettings.itemCoolDownTrackerTrackedItemsMarkerIcon,
        },

    }
    return submenuControls
end

-- Build a LAM SubMenu for the addon "SetTracker"
--#302 #307 SetTracker support disabled with FCOOIS v2.6.1, for versions <300
local function LAMSubmenuSetTracker()
    local submenuControls = {}
    locVars = FCOISlocVars.fcois_loc

    if not FCOIS.otherAddons.SetTracker.isActive or not SetTrack or not SetTrack.GetMaxTrackStates then return submenuControls end

    --------------------------------------------------------------------------------
    --Checkboxes
    local cbAutoMarkSetTracker = {
        type = "checkbox",
        name = locVars["options_auto_mark_settrackersets"],
        tooltip = locVars["options_auto_mark_settrackersets" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSets end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSets = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive end,
        requiresReload = true,
    }
    table.insert(submenuControls, cbAutoMarkSetTracker)
    local cbAutoMarkSetTrackerCheckAllIcons = {
        type = "checkbox",
        name = locVars["options_enable_auto_mark_check_all_icons"],
        tooltip = locVars["options_enable_auto_mark_check_all_icons" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsCheckAllIcons end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSetsCheckAllIcons = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
    }
    table.insert(submenuControls, cbAutoMarkSetTrackerCheckAllIcons)
    local cbAutoMarkSetTrackerTooltips = {
        type = "checkbox",
        name = locVars["options_auto_mark_settrackersets_show_tooltip_on_FCOIS_marker"],
        tooltip = locVars["options_auto_mark_settrackersets_show_tooltip_on_FCOIS_marker" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsShowTooltip end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSetsShowTooltip = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
    }
    table.insert(submenuControls, cbAutoMarkSetTrackerTooltips)
    local cbAutoMarkSetTrackerInv = {
        type = "checkbox",
        name = locVars["options_auto_mark_settrackersets_inv"],
        tooltip = locVars["options_auto_mark_settrackersets_inv" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsInv end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSetsInv = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
    }
    table.insert(submenuControls, cbAutoMarkSetTrackerInv)
    local cbAutoMarkSetTrackerWorn = {
        type = "checkbox",
        name = locVars["options_auto_mark_settrackersets_worn"],
        tooltip = locVars["options_auto_mark_settrackersets_worn" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsWorn end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSetsWorn = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
    }
    table.insert(submenuControls, cbAutoMarkSetTrackerWorn)
    local cbAutoMarkSetTrackerBank = {
        type = "checkbox",
        name = locVars["options_auto_mark_settrackersets_bank"],
        tooltip = locVars["options_auto_mark_settrackersets_bank" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsBank end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSetsBank = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
    }
    table.insert(submenuControls, cbAutoMarkSetTrackerBank)
    local cbAutoMarkSetTrackerGuildBank = {
        type = "checkbox",
        name = locVars["options_auto_mark_settrackersets_guildbank"],
        tooltip = locVars["options_auto_mark_settrackersets_guildbank" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsGuildBank end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSetsGuildBank = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
    }
    table.insert(submenuControls, cbAutoMarkSetTrackerGuildBank)
    local cbAutoMarkSetTrackerRescan = {
        type = "checkbox",
        name = locVars["options_auto_mark_settrackersets_rescan"],
        tooltip = locVars["options_auto_mark_settrackersets_rescan" .. tooltipSuffix],
        getFunc = function() return FCOISsettings.autoMarkSetTrackerSetsRescan end,
        setFunc = function(value)
            FCOISsettings.autoMarkSetTrackerSetsRescan = value
        end,
        width = "half",
        disabled = function() return not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets end,
    }
    table.insert(submenuControls, cbAutoMarkSetTrackerRescan)
    --Dropdown boxes
    --Is the SetTracker addon active?
    --if FCOIS.otherAddons.SetTracker.isActive and SetTrack and SetTrack.GetMaxTrackStates then
        local createdSetTrackerDDBoxes = buildSetTrackerDDBoxes()
        --Was the SetTracker submenu build?
        if createdSetTrackerDDBoxes ~= nil and #createdSetTrackerDDBoxes > 0 then
            for _, createdSetTrackerDDBox in pairs(createdSetTrackerDDBoxes) do
                table.insert(submenuControls, createdSetTrackerDDBox)
            end
        end
    --end
    --------------------------------------------------------------------------------
    return submenuControls
end
--==================== SetTracker - END ======================================


--==================== Normal & gear marker icons - BEGIN ===================================
--Build the complete submenus for the dynamic icons
local function buildNormalIconSubMenus(buildName)
    local buildGear = buildName ~= nil and buildName == "gear"
    local normalIconsSubMenus = {}
    locVars = FCOISlocVars.fcois_loc
    --[[
    --Each submenu starts with this header...
        {
            type = "submenu",
            name = locVars[optionsIcon .. "<iconNr>" .. colorSuffix],
            reference = strformat(subMenuNamePattern, tos(normalIconId)),
            controls =
            {
            ...
            },
        },
    ]]
    ------------------------------------------------------------------------------------------------------------------------
    --These LAM controls will be added at the end of the controls that are always added for all icons (e.g. color,
    --size, position)
    local specialControlsByIconId ={
        --Sell at guildstore icon
        [FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = {
            [1] = {
                --Only unbound items are allowed to be marked with this marker icon
                type = "checkbox",
                name = locVars[optionsIcon .. FCOIS_CON_ICON_SELL_AT_GUILDSTORE .."_only_unbound"],
                tooltip = locVars[optionsIcon .. FCOIS_CON_ICON_SELL_AT_GUILDSTORE .."_only_unbound" .. tooltipSuffix],
                getFunc = function() return FCOISsettings.allowOnlyUnbound[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
                setFunc = function(value) FCOISsettings.allowOnlyUnbound[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] = value
                end,
                width="half",
                disabled = function() return not isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE] end,
                default = FCOISdefaultSettings.allowOnlyUnbound[FCOIS_CON_ICON_SELL_AT_GUILDSTORE],
            },
        },
    }
    ------------------------------------------------------------------------------------------------------------------------
    --Create 1 submenu for each normal marker, dynamic, dynamic as gear icons
    for normalIconId=FCOIS_CON_ICON_LOCK, numVars.gFCONumNonDynamicAndGearIcons, 1 do
        local gearIndex = mappingVars.iconToGear[normalIconId]
        local isGearIcon = gearIndex ~= nil or false
        local addThisIcon = ((buildGear == true and isGearIcon == true) or (not buildGear and not isGearIcon)) or false
        if addThisIcon == true then
            --Clear the controls of the submenu
            local normalIconsSubMenusControls = {}

            --Variables
            local ref
            local name
            local tooltip
            local data = {}
            local disabledFunc, getFunc, setFunc, defaultSettings, createdControl

            local iconNameStart = optionsIcon .. tos(normalIconId)
            local iconSettings = FCOISsettings.icon[normalIconId]

            --Is a gear icon?
            if isGearIcon == true then
                ------------------------------------------------------------------------------------------------------------------------
                --Add the name edit box
                name = locVars[iconNameStart .. nameSuffix]
                local refOfGearIconEdit =  fcoisLAMSettingsReferencePrefix .. "GearSetNameEdit" .. gearIndex
                tooltip = locVars[iconNameStart .. nameSuffix .. tooltipSuffix]
                data = {
                    type = "editbox", width = "half",
                    --helpUrl = locVars[dynIconNameStart .. colorSuffix],
                }
                disabledFunc = function() return not isIconEnabled[normalIconId] end
                getFunc = function() return iconSettings.name end
                setFunc = function(newValue)
                    if not FCOIS.preventerVars.doNotCheckForDefaultName then
                        --Name of the marker icon is missing, so reset it to a default name
                        newValue = defaultIconNameCheck(refOfGearIconEdit, newValue, normalIconId)
                        FCOISsettings.icon[normalIconId].name = newValue
                        FCOIS.preventerVars.doUpdateLocalization = true
                        changeContextMenuEntryTexts(normalIconId)
                        --Update the icon list dropdown entries (name, enabled state, icon)
                        updateIconListDropdownEntries()
                    end
                end
                defaultSettings = FCOISdefaultSettings.icon[normalIconId].name --locVars[normalIconId .. nameSuffix]
                createdControl = CreateControl(refOfGearIconEdit, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(normalIconsSubMenusControls, createdControl)
                end
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Add the color picker
            name = locVars[iconNameStart .. colorSuffix]
            tooltip = locVars[iconNameStart .. colorSuffix .. tooltipSuffix]
            data = { type = "colorpicker", width = "half" }
            disabledFunc = function() return not isIconEnabled[normalIconId] end
            getFunc = function() return iconSettings.color.r, iconSettings.color.g, iconSettings.color.b, iconSettings.color.a end
            setFunc = function(r,g,b,a)
                FCOISsettings.icon[normalIconId].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
                changePreviewIconColor(filterButton, normalIconId, r, g, b, a)
            end
            defaultSettings = FCOISdefaultSettings.icon[normalIconId].color
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(normalIconsSubMenusControls, createdControl)
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Add the icon picker
            ref = fcoisLAMSettingsReferencePrefix .. filterButton.. tos(normalIconId) ..  previewSelect
            name = locVars[iconNameStart .. "_texture"]
            tooltip = locVars[iconNameStart .. "_texture" .. tooltipSuffix]
            data = { type = "iconpicker", width = "half", choices = markerIconTextures, choicesTooltips = texturesList, maxColumns=6, visibleRows=5, iconSize=iconSettings.size}
            disabledFunc = function() return not isIconEnabled[normalIconId] end
            getFunc = function() return markerIconTextures[iconSettings.texture] end
            setFunc = function(texturePath)
                local textureId = GetFCOTextureId(texturePath)
                if textureId ~= 0 then
                    FCOISsettings.icon[normalIconId].texture = textureId
                    changePreviewLabelText(filterButton, normalIconId, texturesList[textureId])
                    updateFilterButtonColorAndTexture(mappingVars.iconToFilterDefaults[normalIconId], normalIconId)
                    --Update the icon list dropdown entries (name, enabled state, icon)
                    updateIconListDropdownEntries()
                end
            end
            defaultSettings = markerIconTextures[iconSettings.texture]
            createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(normalIconsSubMenusControls, createdControl)
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Add the offsetX slider
            name = locVars["options_icon_offset_left"]
            tooltip = locVars["options_icon_offset_left" .. tooltipSuffix]
            data = { type = "slider", width = "half", min=minIconOffsetLeft, max=maxIconOffsetLeft, decimals=0, autoselect=true}
            disabledFunc = function() return not isIconEnabled[normalIconId] end
            getFunc = function() return iconSettings.offsets[LF_INVENTORY].left end
            setFunc = function(offsetX)
                FCOISsettings.icon[normalIconId].offsets[LF_INVENTORY].left = offsetX
            end
            defaultSettings = FCOISdefaultSettings.icon[normalIconId].offsets[LF_INVENTORY].left
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(normalIconsSubMenusControls, createdControl)
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Add the offsetY slider
            name = locVars["options_icon_offset_top"]
            tooltip = locVars["options_icon_offset_top" .. tooltipSuffix]
            data = { type = "slider", width = "half", min=minIconOffsetTop, max=maxIconOffsetTop, decimals=0, autoselect=true}
            disabledFunc = function() return not isIconEnabled[normalIconId] end
            getFunc = function() return iconSettings.offsets[LF_INVENTORY].top end
            setFunc = function(offsetY)
                FCOISsettings.icon[normalIconId].offsets[LF_INVENTORY].top = offsetY
            end
            defaultSettings = FCOISdefaultSettings.icon[normalIconId].offsets[LF_INVENTORY].top
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(normalIconsSubMenusControls, createdControl)
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Add the size slider
            name = locVars[iconNameStart .. "_size"]
            tooltip = locVars[iconNameStart .. "_size" .. tooltipSuffix]
            data = { type = "slider", width = "half", min=minIconSize, max=maxIconSize, decimals=0, autoselect=true}
            disabledFunc = function() return not isIconEnabled[normalIconId] end
            getFunc = function() return iconSettings.size end
            setFunc = function(size)
                FCOISsettings.icon[normalIconId].size = size
                changePreViewIconSize(filterButton, normalIconId, size)
            end
            defaultSettings = FCOISdefaultSettings.icon[normalIconId].size
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(normalIconsSubMenusControls, createdControl)
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Add the tooltip checkbox
            name = locVars[iconNameStart .. tooltipSuffix]
            tooltip = locVars[iconNameStart .. "_tooltip" .. tooltipSuffix]
            data = { type = "checkbox", width = "half"}
            disabledFunc = function() return not isIconEnabled[normalIconId] end
            getFunc = function() return FCOISsettings.showMarkerTooltip[normalIconId] end
            setFunc = function(value)
                FCOISsettings.icon[normalIconId].showMarkerTooltip[normalIconId] = value
                FCOIS.preventerVars.gUpdateMarkersNow = true
                FCOIS.preventerVars.doUpdateLocalization = true
            end
            defaultSettings = FCOISdefaultSettings.showMarkerTooltip[normalIconId]
            createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(normalIconsSubMenusControls, createdControl)
            end

            --Is a gear icon?
            if isGearIcon == true then
                ------------------------------------------------------------------------------------------------------------------------
                --Add the disable research (old: check for gear items) checkbox
                name = locVars["options_gear_disable_research_check"]
                tooltip = locVars["options_gear_disable_research_check" .. tooltipSuffix]
                data = { type = "checkbox", width = "half"}
                disabledFunc = function() return not isIconEnabled[normalIconId] end
                getFunc = function() return FCOISsettings.disableResearchCheck[normalIconId] end
                setFunc = function(value) FCOISsettings.disableResearchCheck[normalIconId] = value
                end
                defaultSettings = FCOISdefaultSettings.disableResearchCheck[normalIconId]
                createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(normalIconsSubMenusControls, createdControl)
                end
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Any additional special controls to add?
            local specialControlsForMarkerIcon = specialControlsByIconId[normalIconId]
            if specialControlsForMarkerIcon ~= nil then
                for _, specialControlData in ipairs(specialControlsForMarkerIcon) do
                    name = specialControlData.name
                    data = { type = specialControlData.type, width = specialControlData.width }
                    if name ~= nil and data ~= nil and data.type ~= nil then
                        tooltip = specialControlData.tooltip
                        disabledFunc = specialControlData.disabled
                        getFunc = specialControlData.getFunc
                        setFunc = specialControlData.setFunc
                        defaultSettings = specialControlData.default
                        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                        if createdControl ~= nil then
                            table.insert(normalIconsSubMenusControls, createdControl)
                        end
                    end
                end
            end

            ------------------------------------------------------------------------------------------------------------------------
            --Create the submenu header for the normal icon and assign the before build controls to it
            if normalIconsSubMenusControls ~= nil and #normalIconsSubMenusControls > 0 then
                ref = strformat(subMenuNamePattern, tos(normalIconId))
                if isGearIcon == true then
                    name = locVars[optionsIcon .. "s_gear" .. tos(mappingVars.iconToGear[normalIconId])] .. ": \'" .. iconSettings.name .. "\'"
                else
                    name = locVars[iconNameStart .. colorSuffix]
                end
                tooltip = ""
                data = { type = "submenu", controls = normalIconsSubMenusControls }
                local createdNormalconSubMenuSurrounding = CreateControl(ref, name, tooltip, data, nil, nil, nil, nil, nil)
                table.insert(normalIconsSubMenus, createdNormalconSubMenuSurrounding)
            end

        end
    end
    return normalIconsSubMenus
end

--Build the enable/disable checkboxes submenu for the normal and gear marker icons
local function buildNormalIconEnableCheckboxes(buildName)
    local buildGear = buildName ~= nil and buildName == "gear"
    local normalIconsEnabledCbs = {}
    locVars = FCOISlocVars.fcois_loc
    local standardSetFunc = function(p_iconId, p_value)
        FCOISsettings.isIconEnabled[p_iconId] = p_value
        if p_value == true then
            --Update the color of the dynamic icons's icon picker texture again as it was grayed out
            local iconSettings = FCOISsettings.icon[p_iconId]
            local iconColorSettings = iconSettings.color
            local r, g, b, a = iconColorSettings.r, iconColorSettings.g, iconColorSettings.b, iconColorSettings.a
            changePreviewIconColor(filterButton, p_iconId, r, g, b, a, true)
        end
        updateIconListDropdownEntries()
        updateEnabledMarkerIconsSortOrderListData()
        FCOIS.preventerVars.doUpdateLocalization = true
    end
    --Create 1 checkbox for each normal/gear icon, to enable/disable the normal/gear icon
    for normalIconId=FCOIS_CON_ICON_LOCK, numVars.gFCONumNonDynamicAndGearIcons, 1 do
        local isGearIcon = mappingVars.iconToGear[normalIconId] ~= nil or false
        local addThisIcon = ((buildGear == true and isGearIcon == true) or (not buildGear and not isGearIcon)) or false
        if addThisIcon == true then
            local name = locVars[optionsIcon .. normalIconId .. "_activate_text"]
            local tooltip = locVars[optionsIcon .. "_activate_text" .. tooltipSuffix]
            local data = { type = "checkbox", width = "half" }
            local disabledFunc = function() return false end
            local getFunc = function() return FCOISsettings.isIconEnabled[normalIconId] end
            local setFunc
            local defaultSettings = FCOISdefaultSettings.isIconEnabled[normalIconId]
            if buildGear == true then
                setFunc = function(value)
                    standardSetFunc(normalIconId, value)
                    --Hide the textures for gear icon
                    --Character equipment (create if not yet created and icon is enabled)
                    refreshEquipmentControl(nil, value, normalIconId)
                    filterBasics(true)
                    FCOIS.preventerVars.gChangedGears = true
                end
            else
                setFunc = function(value)
                    standardSetFunc(normalIconId, value)
                end
            end

            --Create the checkbox now
            local createdNormalIconEnableCB = CreateControl(name, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
            if createdNormalIconEnableCB ~= nil then
                table.insert(normalIconsEnabledCbs, createdNormalIconEnableCB)
            end
        end
    end
    return normalIconsEnabledCbs
end
--==================== Normal & gear marker - END ===================================


--==================== Dynamic marker icons submenu - BEGIN ===================================
--Build the enable/disable checkboxes submenu for the dynamic icons
local function buildDynamicIconEnableCheckboxes()
    iconId2FCOISIconNr = mappingVars.dynamicToIcon
    numDynIcons = FCOISsettings.numMaxDynamicIconsUsable
    locVars = FCOISlocVars.fcois_loc
    local dynamicIconsEnabledCbs = {}
    --Create 1 checkbox for each dynamic icon, to enable/disable the dynamic icon
    for dynIconId=1, numDynIcons, 1 do
        local fcoisDynIconNr = iconId2FCOISIconNr[dynIconId] --e.g. dynamic icon 1 = FCOIS icon ID 13, 2 = 14, and so on
        local iconSettings = FCOISsettings.icon[fcoisDynIconNr]
        local iconColorSettings = iconSettings.color
        --local fcoisLockDynMenuIconNr = iconId2FCOISIconLockDynMenuNr[dynIconId] --e.g. dynamic icon 1 = 2, 2 = 3, and so on

        local name = locVars[optionsIcon .. tos(fcoisDynIconNr) .. "_activate_text"]
        local tooltip = locVars[optionsIcon .. "_activate_text" .. tooltipSuffix]
        local data = { type = "checkbox", width = "half" }
        local disabledFunc = function() return false end
        local getFunc = function() return isIconEnabled[fcoisDynIconNr] end
        local setFunc = function(value)
            FCOISsettings.isIconEnabled[fcoisDynIconNr] = value
            if value == true then
                --Update the color of the dynamic icons's icon picker texture again as it was grayed out
                local r, g, b, a = iconColorSettings.r, iconColorSettings.g, iconColorSettings.b, iconColorSettings.a
                changePreviewIconColor(filterButton, fcoisDynIconNr, r, g, b, a, true)
            end
            --Update the icon list dropdown entries (name, enabled state, icon)
            updateIconListDropdownEntries()
            updateEnabledMarkerIconsSortOrderListData()
            FCOIS.preventerVars.doUpdateLocalization = true
        end
        local defaultSettings = FCOISdefaultSettings.isIconEnabled[fcoisDynIconNr]
        --Create the checkbox now
        local createdDynIconEnableCB = CreateControl(name, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdDynIconEnableCB ~= nil then
            table.insert(dynamicIconsEnabledCbs, createdDynIconEnableCB)
        end
    end
    return dynamicIconsEnabledCbs
end


--Build the complete submenus for the dynamic icons
local function buildDynamicIconSubMenus()
    iconId2FCOISIconNr = mappingVars.dynamicToIcon
    numDynIcons = FCOISsettings.numMaxDynamicIconsUsable
    locVars = FCOISlocVars.fcois_loc
    local dynIconsSubMenus = {}
    --[[
    --Each submenu starts with this header...
        {
            type = "submenu",
            name = locVars[optionsIcon .. "<iconNrOfDynIcon>" .. colorSuffix],
            reference = strformat(subMenuNamePattern, tos(dynIconId))
            controls =
            {
            ...
            },
        },
    ]]

    --Create 1 submenu for each dynamic icon
    for dynIconId=1, numDynIcons, 1 do
        local fcoisDynIconNr = iconId2FCOISIconNr[dynIconId] --e.g. dynamic icon 1 = FCOIS icon ID 13, 2 = 14, and so on
        --local fcoisLockDynMenuIconNr = iconId2FCOISIconLockDynMenuNr[dynIconId] --e.g. dynamic icon 1 = 2, 2 = 3, and so on

        --Clear the controls of the submenu
        local dynIconsSubMenusControls = {}

        --Variables
        local name
        local tooltip
        local data = {}
        local disabledFunc, getFunc, setFunc, defaultSettings, createdControl

        local dynIconNameStart = optionsIcon .. tos(fcoisDynIconNr)

        ------------------------------------------------------------------------------------------------------------------------
        --Add the name edit box
        name = locVars[dynIconNameStart .. colorSuffix]
        local refOfDynIconEditBox = fcoisLAMSettingsReferencePrefix .. "DynamicIconNameEdit" .. tos(dynIconId)
        tooltip = ""
        data = {
            type = "editbox", width = "half",
            --helpUrl = locVars[dynIconNameStart .. colorSuffix],
        }
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].name end
        setFunc = function(newValue)
            if not FCOIS.preventerVars.doNotCheckForDefaultName then
                --Name of the marker icon is missing, so reset it to a default name
                newValue = defaultIconNameCheck(refOfDynIconEditBox, newValue, fcoisDynIconNr)
                FCOISsettings.icon[fcoisDynIconNr].name = newValue
                FCOIS.preventerVars.doUpdateLocalization = true
                changeContextMenuEntryTexts(fcoisDynIconNr)
                --Update the icon list dropdown entries (name, enabled state, icon)
                updateIconListDropdownEntries()
            end
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].name --locVars[dynIconNameStart .. nameSuffix]
        createdControl = CreateControl(refOfDynIconEditBox, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end

        ------------------------------------------------------------------------------------------------------------------------
        --Add the color picker
        name = locVars[dynIconNameStart .. colorSuffix]
        tooltip = locVars[dynIconNameStart .. colorSuffix .. tooltipSuffix]
        data = { type = "colorpicker", width = "half" }
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function()
            local colorOfIcon = FCOISsettings.icon[fcoisDynIconNr].color
            return colorOfIcon.r, colorOfIcon.g, colorOfIcon.b, colorOfIcon.a end
        setFunc = function(r,g,b,a)
            FCOISsettings.icon[fcoisDynIconNr].color = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
            changePreviewIconColor(filterButton, fcoisDynIconNr, r, g, b, a)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].color
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end

        ------------------------------------------------------------------------------------------------------------------------
        --Add the icon picker
        local ref = fcoisLAMSettingsReferencePrefix .. filterButton.. tos(fcoisDynIconNr) ..  previewSelect
        name = locVars[dynIconNameStart .. "_texture"]
        tooltip = locVars[dynIconNameStart .. "_texture" .. tooltipSuffix]
        data = { type = "iconpicker", width = "half", choices = markerIconTextures, choicesTooltips = texturesList, maxColumns=6, visibleRows=5, iconSize=FCOISsettings.icon[fcoisDynIconNr].size}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return markerIconTextures[FCOISsettings.icon[fcoisDynIconNr].texture] end
        setFunc = function(texturePath)
            local textureId = GetFCOTextureId(texturePath)
            if textureId ~= 0 then
                FCOISsettings.icon[fcoisDynIconNr].texture = textureId
                changePreviewLabelText(filterButton, fcoisDynIconNr, texturesList[textureId])
                updateFilterButtonColorAndTexture(FCOIS_CON_FILTER_BUTTON_LOCKDYN, FCOIS_CON_ICON_LOCK)
                --Update the icon list dropdown entries (name, enabled state, icon)
                updateIconListDropdownEntries()
            end
        end
        defaultSettings = markerIconTextures[FCOISsettings.icon[fcoisDynIconNr].texture]
        createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end

        ------------------------------------------------------------------------------------------------------------------------
        --Add the size slider
        name = locVars[dynIconNameStart .. "_size"]
        tooltip = locVars[dynIconNameStart .. "_size" .. tooltipSuffix]
        data = { type = "slider", width = "half", min=minIconSize, max=maxIconSize, decimals=0, autoselect=true}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].size end
        setFunc = function(size)
            FCOISsettings.icon[fcoisDynIconNr].size = size
            changePreViewIconSize(filterButton, fcoisDynIconNr, size)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].size
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end

        ------------------------------------------------------------------------------------------------------------------------
        --Add the offsetX slider
        name = locVars[dynIconNameStart .. "_offsetX"]
        tooltip = locVars[dynIconNameStart .. "_offsetX" .. tooltipSuffix]
        data = { type = "slider", width = "half", min=minIconOffsetLeft, max=maxIconOffsetLeft, decimals=0, autoselect=true}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].offsets[LF_INVENTORY].left end
        setFunc = function(offsetX)
            FCOISsettings.icon[fcoisDynIconNr].offsets[LF_INVENTORY].left = offsetX
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].offsets[LF_INVENTORY].left
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end

        ------------------------------------------------------------------------------------------------------------------------
        --Add the offsetY slider
        name = locVars[dynIconNameStart .. "_offsetY"]
        tooltip = locVars[dynIconNameStart .. "_offsetY" .. tooltipSuffix]
        data = { type = "slider", width = "half", min=minIconOffsetTop, max=maxIconOffsetTop, decimals=0, autoselect=true}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].offsets[LF_INVENTORY].top end
        setFunc = function(offsetY)
            FCOISsettings.icon[fcoisDynIconNr].offsets[LF_INVENTORY].top = offsetY
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].offsets[LF_INVENTORY].top
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end

        ------------------------------------------------------------------------------------------------------------------------
        --Add the tooltip checkbox
        name = locVars[dynIconNameStart .. tooltipSuffix]
        tooltip = locVars[dynIconNameStart .. "_tooltip" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.showMarkerTooltip[fcoisDynIconNr] end
        setFunc = function(value)
            FCOISsettings.showMarkerTooltip[fcoisDynIconNr] = value
            FCOIS.preventerVars.gUpdateMarkersNow = true
            FCOIS.preventerVars.doUpdateLocalization = true
        end
        defaultSettings = FCOISdefaultSettings.showMarkerTooltip[fcoisDynIconNr]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the disable research (old: check for gear items) checkbox
        name = locVars["options_gear_disable_research_check"]
        tooltip = locVars["options_gear_disable_research_check" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.disableResearchCheck[fcoisDynIconNr] end
        setFunc = function(value) FCOISsettings.disableResearchCheck[fcoisDynIconNr] = value
        end
        defaultSettings = FCOISdefaultSettings.disableResearchCheck[fcoisDynIconNr]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the enable as gear checkbox
        name = locVars["options_gear_enable_as_gear"]
        tooltip = locVars["options_gear_enable_as_gear" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.iconIsGear[fcoisDynIconNr] end
        setFunc = function(value)
            FCOISsettings.iconIsGear[fcoisDynIconNr] = value
            --Now rebuild all other gear set values
            rebuildGearSetBaseVars(fcoisDynIconNr, value, false)
            FCOIS.preventerVars.doUpdateLocalization = true
        end
        defaultSettings = FCOISdefaultSettings.iconIsGear[fcoisDynIconNr]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the respect inventory flag icon state
        name = locVars["options_enable_block_marked_disable_with_flag"]
        tooltip = locVars["options_enable_block_marked_disable_with_flag" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].temporaryDisableByInventoryFlagIcon end
        setFunc = function(value)
            FCOISsettings.icon[fcoisDynIconNr].temporaryDisableByInventoryFlagIcon = value
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].temporaryDisableByInventoryFlagIcon
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the disable all other marker icons if this dyn. icon is set checkbox
        name = locVars["options_demark_all_others"]
        tooltip = locVars["options_demark_all_others" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].demarkAllOthers end
        setFunc = function(value)
            FCOISsettings.icon[fcoisDynIconNr].demarkAllOthers = value
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].demarkAllOthers
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the exclude non-dynamic (normal) icons to the disable all other marker icons if this dyn. icon is set checkbox
        name = locVars["options_demark_all_others_except_non_dynamic"]
        tooltip = locVars["options_demark_all_others_except_non_dynamic" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] or not FCOISsettings.icon[fcoisDynIconNr].demarkAllOthers or FCOISsettings.icon[fcoisDynIconNr].demarkAllOthersExcludeDynamic end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].demarkAllOthersExcludeNormal end
        setFunc = function(value)
            FCOISsettings.icon[fcoisDynIconNr].demarkAllOthersExcludeNormal = value
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].demarkAllOthersExcludeNormal
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the exclude dnaymic icons to the disable all other marker icons if this dyn. icon is set checkbox
        name = locVars["options_demark_all_others_except_dynamic"]
        tooltip = locVars["options_demark_all_others_except_dynamic" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] or not FCOISsettings.icon[fcoisDynIconNr].demarkAllOthers or FCOISsettings.icon[fcoisDynIconNr].demarkAllOthersExcludeNormal end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].demarkAllOthersExcludeDynamic end
        setFunc = function(value)
            FCOISsettings.icon[fcoisDynIconNr].demarkAllOthersExcludeDynamic = value
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].demarkAllOthersExcludeDynamic
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the "Prevent auto-marking  if marked with this icon" checkbox
        name = locVars["options_prevent_auto_marking_if_this_icon_set"]
        tooltip = locVars["options_prevent_auto_marking_if_this_icon_set" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].autoMarkPreventIfMarkedWithThis end
        setFunc = function(value)
            FCOISsettings.icon[fcoisDynIconNr].autoMarkPreventIfMarkedWithThis = value
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].autoMarkPreventIfMarkedWithThis
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the "Auto-remove if banked" checkbox
        name = locVars["options_auto_remove_if_banked"]
        tooltip = locVars["options_auto_remove_if_banked" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].autoRemoveMarkForBag[BAG_BANK] end
        setFunc = function(value)
            FCOISsettings.icon[fcoisDynIconNr].autoRemoveMarkForBag[BAG_BANK] = value
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].autoRemoveMarkForBag[BAG_BANK]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the "Auto-remove if guild banked" checkbox
        name = locVars["options_auto_remove_if_guild_banked"]
        tooltip = locVars["options_auto_remove_if_guild_banked" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].autoRemoveMarkForBag[BAG_GUILDBANK] end
        setFunc = function(value)
            FCOISsettings.icon[fcoisDynIconNr].autoRemoveMarkForBag[BAG_GUILDBANK] = value
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].autoRemoveMarkForBag[BAG_GUILDBANK]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the anti-destroy header
        name = locVars["options_header_anti_destroy"]
        data = { type = "header"}
        createdControl = CreateControl(nil, name, nil, data, nil, nil, nil, nil, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block destroy checkbox
        name = locVars["options_enable_block_destroying"]
        tooltip = locVars["options_enable_block_destroying" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_INVENTORY] end
        setFunc = function(value)
            updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_INVENTORY, value)
            --updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_INVENTORY_COMPANION, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_INVENTORY]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block selling checkbox
        name = locVars["options_enable_block_selling"]
        tooltip = locVars["options_enable_block_selling" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_VENDOR_SELL] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_VENDOR_SELL, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_VENDOR_SELL]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block sell in guildstore checkbox
        name = locVars["options_enable_block_selling_guild_store"]
        tooltip = locVars["options_enable_block_selling_guild_store" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_GUILDSTORE_SELL] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_GUILDSTORE_SELL, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_GUILDSTORE_SELL]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block fence selling checkbox
        name = locVars["options_enable_block_fence_selling"]
        tooltip = locVars["options_enable_block_fence_selling" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_SELL] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_FENCE_SELL, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_SELL]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block launder selling checkbox
        name = locVars["options_enable_block_launder_selling"]
        tooltip = locVars["options_enable_block_launder_selling" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_LAUNDER] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_FENCE_LAUNDER, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_FENCE_LAUNDER]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block trading checkbox
        name = locVars["options_enable_block_trading"]
        tooltip = locVars["options_enable_block_trading" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_TRADE] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_TRADE, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_TRADE]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block send by mail checkbox
        name = locVars["options_enable_block_sending_mail"]
        tooltip = locVars["options_enable_block_sending_mail" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_MAIL_SEND] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_MAIL_SEND, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_MAIL_SEND]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the headline "Crafting"
        name = locVars["options_header_crafting"] .. " - " .. locVars["options_header_anti_destroy"]
        tooltip = locVars["options_header_crafting"] .. " - " .. locVars["options_header_anti_destroy"]
        data = { type = "header" }
        createdControl = CreateControl(nil, name, tooltip, data, nil, nil, nil, nil, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block refinement checkbox
        name = locVars["options_enable_block_refinement"]
        tooltip = locVars["options_enable_block_refinement" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_REFINE] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_SMITHING_REFINE, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_REFINE]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block jewelry refinement checkbox
        name = locVars["options_enable_block_jewelry_refinement"]
        tooltip = locVars["options_enable_block_jewelry_refinement" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_REFINE] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_JEWELRY_REFINE, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_REFINE]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block deconstruction checkbox
        name = locVars["options_enable_block_deconstruction"]
        tooltip = locVars["options_enable_block_deconstruction" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_SMITHING_DECONSTRUCT, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_DECONSTRUCT]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block jewelry deconstruction checkbox
        name = locVars["options_enable_block_jewelry_deconstruction"]
        tooltip = locVars["options_enable_block_jewelry_deconstruction" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_DECONSTRUCT] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_JEWELRY_DECONSTRUCT, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_DECONSTRUCT]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block improvement checkbox
        name = locVars["options_enable_block_improvement"]
        tooltip = locVars["options_enable_block_improvement" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_SMITHING_IMPROVEMENT, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_IMPROVEMENT]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block jewelry improvement checkbox
        name = locVars["options_enable_block_jewelry_improvement"]
        tooltip = locVars["options_enable_block_jewelry_improvement" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_IMPROVEMENT] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_JEWELRY_IMPROVEMENT, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_IMPROVEMENT]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block research checkbox
        name = locVars["options_enable_block_research"]
        tooltip = locVars["options_enable_block_research" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_RESEARCH_DIALOG] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_SMITHING_RESEARCH_DIALOG, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_SMITHING_RESEARCH_DIALOG]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block jewelry research checkbox
        name = locVars["options_enable_block_jewelry_research"]
        tooltip = locVars["options_enable_block_jewelry_research" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_RESEARCH_DIALOG] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_JEWELRY_RESEARCH_DIALOG, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_JEWELRY_RESEARCH_DIALOG]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block enchanting creation checkbox
        name = locVars["options_enable_block_creation"]
        tooltip = locVars["options_enable_block_creation" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_CREATION] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_ENCHANTING_CREATION, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_CREATION]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block enchanting extraction checkbox
        name = locVars["options_enable_block_extraction"]
        tooltip = locVars["options_enable_block_extraction" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_EXTRACTION] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_ENCHANTING_EXTRACTION, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ENCHANTING_EXTRACTION]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block alchemy destroy checkbox
        name = locVars["options_enable_block_alchemy_destroy"]
        tooltip = locVars["options_enable_block_alchemy_destroy" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ALCHEMY_CREATION] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_ALCHEMY_CREATION, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_ALCHEMY_CREATION]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Add the block retrait checkbox
        name = locVars["options_enable_block_retrait"]
        tooltip = locVars["options_enable_block_retrait" .. tooltipSuffix]
        data = { type = "checkbox", width = "half"}
        disabledFunc = function() return not isIconEnabled[fcoisDynIconNr] end
        getFunc = function() return FCOISsettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_RETRAIT] end
        setFunc = function(value) updateAntiCheckAtPanelVariable(fcoisDynIconNr, LF_RETRAIT, value)
        end
        defaultSettings = FCOISdefaultSettings.icon[fcoisDynIconNr].antiCheckAtPanel[LF_RETRAIT]
        createdControl = CreateControl(nil, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
        if createdControl ~= nil then
            table.insert(dynIconsSubMenusControls, createdControl)
        end
        ------------------------------------------------------------------------------------------------------------------------
        --Create the submenu header for the dynamic icon and assign the before build controls to it
        if dynIconsSubMenusControls ~= nil and #dynIconsSubMenusControls > 0 then
            --ref = fcoisLAMSettingsReferencePrefix .. "DynamicIcon" ..tos(dynIconId) .. submenuSuffix
            ref = strformat(subMenuNamePattern, tos(fcoisDynIconNr))
            name = locVars[dynIconNameStart .. colorSuffix] .. ": \'" .. FCOISsettings.icon[fcoisDynIconNr].name .. "\'"
            tooltip = ""
            data = { type = "submenu", controls = dynIconsSubMenusControls }
            local createdDynIconSubMenuSurrounding = CreateControl(ref, name, tooltip, data, nil, nil, nil, nil, nil)
            table.insert(dynIconsSubMenus, createdDynIconSubMenuSurrounding)
        end
    end -- for traitTypeName, traitTypeItemTrait in pairs(traitTypeData) do
    return dynIconsSubMenus
end
--==================== Dynamic marker icons submenu - END ===================================


--==================== Filter buttons positions - BEGIN =====================================
--Build the complete submenus for the dynamic icons
local function buildFilterButtonsPositionsSubMenu()
    local function saveValueFilterButtonChecks(filterPanelId, filterButtonNr)
        if filterPanelId == LF_INVENTORY then
            FCOIS.UpdateFCOISFilterButtonsAtInventory(filterButtonNr)
        end
    end

    local filterButtonsPositionsSubMenu = {}
    --Add 1 button to set all filter panel ID settings to an equal value, the one of LF_INVENTORY
    --Add the filter button left edit box
    locVars = FCOISlocVars.fcois_loc
    local btnname    = locVars["options_filter_button_set_all_equal"]
    local btntooltip = locVars["options_filter_button_set_all_equal" .. tooltipSuffix]
    local btndata = { type = "button", width = "full", isDangerous="true"}
    local btndisabledFunc = function()
        for _, filterButtonNr in ipairs(filterButtonsToCheck) do
            if FCOISsettings.filterButtonData[filterButtonNr] == nil then return true end
            if FCOISsettings.filterButtonData[filterButtonNr][LF_INVENTORY] == nil then return true end
        end
        return false
    end
    local btnFunc = function()
        FCOIS.SetAllFCOISFilterButtonOffsetAndSizeSettingsEqual(LF_INVENTORY)
    end
    local btncreatedControl = CreateControl(nil, btnname, btntooltip, btndata, btndisabledFunc, nil, btnFunc, nil, locVars["options_filter_button_set_all_equal" .. tooltipSuffix])
    if btncreatedControl ~= nil then
        table.insert(filterButtonsPositionsSubMenu, btncreatedControl)
    end
    --Create a submenu for each LibFilters filter panel ID
    for filterPanelId=1, numFilterPanels, 1 do
        local isActiveFilterPanelId = activeFilterPanelIds[filterPanelId] or false
        if isActiveFilterPanelId then
            --Clear the controls of the submenu
            local filterButtonsPositionsSubMenuControls = {}
            --Create textfields for the filter button positions left + top and width + height
            for _, filterButtonNr in ipairs(filterButtonsToCheck) do
                --Variables
                local name
                local ref
                local tooltip
                local data = {}
                local disabledFunc, getFunc, setFunc, defaultSettings, createdControl
                ------------------------------------------------------------------------------------------------------------------------
                --Add the filter button header
                name    = locVars["options_filter_button" .. tos(filterButtonNr)]
                tooltip = locVars["options_filter_button" .. tos(filterButtonNr)]
                data = { type = "header", width = "full" }
                createdControl = CreateControl(nil, name, tooltip, data, nil, nil, nil, nil, nil)
                if createdControl ~= nil then
                    table.insert(filterButtonsPositionsSubMenuControls, createdControl)
                end
                --Add the filter button left edit box
                ref = fcoisLAMSettingsReferencePrefix .. "FilterButtonsPositionsAtPanel" .. tos(filterPanelId) .. "_" .. tos(filterButtonNr) .. "_LEFT"
                name    = locVars["options_filter_button" .. tos(filterButtonNr) .. "_left"]
                tooltip = locVars["options_filter_button" .. tos(filterButtonNr) .. "_left" .. tooltipSuffix]
                data = { type = "editbox", width = "half", textType = TEXT_TYPE_NUMERIC }
                disabledFunc = function() return false end
                getFunc = function() return FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["left"] end
                defaultSettings = FCOISdefaultSettings.filterButtonData[filterButtonNr][filterPanelId]["left"]
                setFunc = function(newValue)
                    FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["left"] = checkIfNumberOrReset(newValue, defaultSettings)
                    saveValueFilterButtonChecks(filterPanelId, filterButtonNr)
                end
                createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(filterButtonsPositionsSubMenuControls, createdControl)
                    editBoxesToSetTextTypes = editBoxesToSetTextTypes or {}
                    editBoxesToSetTextTypes[ref] = TEXT_TYPE_NUMERIC
                end
                --Add the filter button top edit box
                ref = fcoisLAMSettingsReferencePrefix .. "FilterButtonsPositionsAtPanel" .. tos(filterPanelId) .. "_" .. tos(filterButtonNr) .. "_TOP"
                name    = locVars["options_filter_button" .. tos(filterButtonNr) .. "_top"]
                tooltip = locVars["options_filter_button" .. tos(filterButtonNr) .. "_top" .. tooltipSuffix]
                data = { type = "editbox", width = "half", textType = TEXT_TYPE_NUMERIC }
                disabledFunc = function() return false end
                getFunc = function() return FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["top"] end
                defaultSettings = FCOISdefaultSettings.filterButtonData[filterButtonNr][filterPanelId]["top"]
                setFunc = function(newValue)
                    FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["top"] = checkIfNumberOrReset(newValue, defaultSettings)
                    saveValueFilterButtonChecks(filterPanelId, filterButtonNr)
                end
                createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(filterButtonsPositionsSubMenuControls, createdControl)
                    editBoxesToSetTextTypes = editBoxesToSetTextTypes or {}
                    editBoxesToSetTextTypes[ref] = TEXT_TYPE_NUMERIC
                end
                --Add the filter button width edit box
                ref = fcoisLAMSettingsReferencePrefix .. "FilterButtonsPositionsAtPanel" .. tos(filterPanelId) .. "_" .. tos(filterButtonNr) .. "_WIDTH"
                name    = locVars["options_filter_button" .. tos(filterButtonNr) .. "_width"]
                tooltip = locVars["options_filter_button" .. tos(filterButtonNr) .. "_width" .. tooltipSuffix]
                data = { type = "slider", width = "half", min = minFilterButtonWidth, max = maxFilterButtonWidth, decimals = 0, step = 1}
                disabledFunc = function() return false end
                getFunc = function() return FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["width"] end
                setFunc = function(newValue)
                    FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["width"] = ton(newValue)
                    saveValueFilterButtonChecks(filterPanelId, filterButtonNr)
                end
                defaultSettings = FCOISdefaultSettings.filterButtonData[filterButtonNr][filterPanelId]["width"]
                createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(filterButtonsPositionsSubMenuControls, createdControl)
                end
                --Add the filter button height edit box
                ref = fcoisLAMSettingsReferencePrefix .. "FilterButtonsPositionsAtPanel" .. tos(filterPanelId) .. "_" .. tos(filterButtonNr) .. "_HEIGHT"
                name    = locVars["options_filter_button" .. tos(filterButtonNr) .. "_height"]
                tooltip = locVars["options_filter_button" .. tos(filterButtonNr) .. "_height" .. tooltipSuffix]
                data = { type = "slider", width = "half", min = minFilterButtonHeight, max = maxFilterButtonHeight, decimals = 0, step = 1}
                disabledFunc = function() return false end
                getFunc = function() return FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["height"] end
                setFunc = function(newValue)
                    FCOISsettings.filterButtonData[filterButtonNr][filterPanelId]["height"] = ton(newValue)
                    saveValueFilterButtonChecks(filterPanelId, filterButtonNr)
                end
                defaultSettings = FCOISdefaultSettings.filterButtonData[filterButtonNr][filterPanelId]["height"]
                createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(filterButtonsPositionsSubMenuControls, createdControl)
                end
            end -- for numFilterButtons
            ------------------------------------------------------------------------------------------------------------------------
            --Create the submenu header for the libFilters filterPanel ID and assign the before build edit controls to it
            if filterButtonsPositionsSubMenuControls ~= nil and #filterButtonsPositionsSubMenuControls > 0 then
                local subMenuRef = fcoisLAMSettingsReferencePrefix .. "FilterButtonsPositionsAtPanel" .. tos(filterPanelId) .. submenuSuffix
                --local subMenuName = locVars["options_libFiltersFilterPanelIdName_" .. tos(filterPanelId)]
                local subMenuName = locVars["FCOIS_LibFilters_PanelIds"][filterPanelId] or locVars["options_libFiltersFilterPanelIdName_" .. tos(filterPanelId)]
                local subMenuTooltip = ""
                local subMenuData = { type = "submenu", controls = filterButtonsPositionsSubMenuControls }
                local createdFilterButtonsPositionsSubMenuSurrounding = CreateControl(subMenuRef, subMenuName, subMenuTooltip, subMenuData, nil, nil, nil, nil, nil)
                table.insert(filterButtonsPositionsSubMenu, createdFilterButtonsPositionsSubMenuSurrounding)
            end
        end -- is active filter panel ID?
    end -- for numFilterPanels
    return filterButtonsPositionsSubMenu
end
--==================== Filter buttons positions - END =====================================


--==================== Filter panel additional inventory context menu "flag" button positions - BEGIN =====================================
--Added with FCOIS v1.6.7
--Build the complete submenus for the addiitonal inventory context menu "flag" offset settings
local function buildAddInvContextMenuFlagButtonsPositionsSubMenu()
    FCOISsettings = FCOIS.settingsVars.settings

    local addInvFlagButtonsPositionsSubMenu = {}
    locVars = FCOISlocVars.fcois_loc
    --Add 1 button to set all filter panel ID settings to an equal value, the one of LF_INVENTORY
    --Add the filter button left edit box
    local btnname    = locVars["options_filter_button_set_all_equal"]
    local btntooltip = locVars["options_add_inv_flag_button_set_all_equal" .. tooltipSuffix]
    local btndata = { type = "button", width = "full", isDangerous="true"}
    local btndisabledFunc = function()
        return false
    end
    local btnFunc = function()
        setAllAddInvFlagButtonOffsetSettingsEqual(LF_INVENTORY)
    end
    local btncreatedControl = CreateControl(nil, btnname, btntooltip, btndata, btndisabledFunc, nil, btnFunc, nil, locVars["options_add_inv_flag_button_set_all_equal" .. tooltipSuffix])
    if btncreatedControl ~= nil then
        table.insert(addInvFlagButtonsPositionsSubMenu, btncreatedControl)
    end
    --Create a submenu for each LibFilters filter panel ID where the add. inv. context menu "flag" button is active
    local sortedAddInvBtnInvokers = FCOIS.contextMenuVars.sortedFilterPanelIdToContextMenuButtonInvoker
    for _, addInvBtnInvokerData in ipairs(sortedAddInvBtnInvokers) do
        local filterPanelId = addInvBtnInvokerData.filterPanelId
        if filterPanelId == nil then
            --Added as FR client user (via email esobzh@gmail.com) always got an error in line 2445, and after adding some workaround fixes with FCOSI v2.1.3 at the default settings the error message is:
            --#140: Error message at login -> related to fixed error 131
            -->Could not create editbox "Gauche:" FCOItemSaver_LAM
            -->Could not create editbox "Haute:" FCOItemSaver_LAM
            d("[FCOIS]DEBUG-SettingsMenu-buildAddInvContextMenuFlagButtonsPositionsSubMenu filterPanelId is nil! addInvBtnInvokerData sortIndex/name: " ..tos(addInvBtnInvokerData.sortIndex) .. "/" .. tos(addInvBtnInvokerData.name))
        else
            local isFCOISCustomFilterPanelId = false
            local typeFilterPanelId = type(filterPanelId)
            if typeFilterPanelId == "string" then
                isFCOISCustomFilterPanelId = true
            end

            local isActiveFilterPanelId = ((isFCOISCustomFilterPanelId == true and true) or (isFCOISCustomFilterPanelId == false and activeFilterPanelIds[filterPanelId])) or false
            if isActiveFilterPanelId and addInvBtnInvokerData and addInvBtnInvokerData.addInvButton then
                --Clear the controls of the submenu
                local addInvFlagButtonsPositionsSubMenuControls = {}
                --Create textfields for the add. inv. "flag" button positions left + top
                --Variables
                local ref
                local name
                local tooltip
                local data = {}
                local disabledFunc, getFunc, setFunc, defaultSettings, createdControl
                ------------------------------------------------------------------------------------------------------------------------
                --Add the button left edit box
                ref = fcoisLAMSettingsReferencePrefix .. "AddInvFlagButtonsPositionsAtPanel" .. tos(filterPanelId) .. "_LEFT"
                name    = locVars["options_filter_button1_left"]
                tooltip = locVars["options_filter_button1_left"]
                data = { type = "editbox", width = "half", textType = TEXT_TYPE_NUMERIC }
                disabledFunc = function() return false end
                getFunc = function() return FCOISsettings.FCOISAdditionalInventoriesButtonOffset[filterPanelId]["left"] end
                defaultSettings = FCOISdefaultSettings.FCOISAdditionalInventoriesButtonOffset[filterPanelId]["left"]
                setFunc = function(newValue)
                    FCOISsettings.FCOISAdditionalInventoriesButtonOffset[filterPanelId]["left"] = ton(newValue) -- checkIfNumberOrReset(newValue, defaultSettings) -- number check should be done via LAM control's textType TEXT_TYPE_NUMERIC already
                    reAnchorAdditionalInvButtons(filterPanelId)
                end
                createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(addInvFlagButtonsPositionsSubMenuControls, createdControl)
                    editBoxesToSetTextTypes = editBoxesToSetTextTypes or {}
                    editBoxesToSetTextTypes[ref] = TEXT_TYPE_NUMERIC
                end
                --Add the button top edit box
                ref = fcoisLAMSettingsReferencePrefix .. "AddInvFlagButtonsPositionsAtPanel" .. tos(filterPanelId) .. "_TOP"
                name    = locVars["options_filter_button1_top"]
                tooltip = locVars["options_filter_button1_top" .. tooltipSuffix]
                data = { type = "editbox", width = "half", textType = TEXT_TYPE_NUMERIC }
                disabledFunc = function() return false end
                getFunc = function() return FCOISsettings.FCOISAdditionalInventoriesButtonOffset[filterPanelId]["top"] end
                defaultSettings = FCOISdefaultSettings.FCOISAdditionalInventoriesButtonOffset[filterPanelId]["top"]
                setFunc = function(newValue)
                    FCOISsettings.FCOISAdditionalInventoriesButtonOffset[filterPanelId]["top"] = ton(newValue) -- checkIfNumberOrReset(newValue, defaultSettings) -- number check should be done via LAM control's textType TEXT_TYPE_NUMERIC already
                    reAnchorAdditionalInvButtons(filterPanelId)
                end
                createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, nil)
                if createdControl ~= nil then
                    table.insert(addInvFlagButtonsPositionsSubMenuControls, createdControl)
                    editBoxesToSetTextTypes = editBoxesToSetTextTypes or {}
                    editBoxesToSetTextTypes[ref] = TEXT_TYPE_NUMERIC
                end
                ------------------------------------------------------------------------------------------------------------------------
                --Create the submenu header for the libFilters filterPanel ID and assign the before build edit controls to it
                if addInvFlagButtonsPositionsSubMenuControls ~= nil and #addInvFlagButtonsPositionsSubMenuControls > 0 then
                    local subMenuRef = fcoisLAMSettingsReferencePrefix .. "AddInvFlagButtonsPositionsAtPanel" .. tos(filterPanelId) .. submenuSuffix
                    --local subMenuName = locVars["options_libFiltersFilterPanelIdName_" .. tos(filterPanelId)]
                    local subMenuName = locVars["FCOIS_LibFilters_PanelIds"][filterPanelId] or locVars["options_libFiltersFilterPanelIdName_" .. tos(filterPanelId)]
                    local subMenuTooltip = ""
                    local subMenuData = { type = "submenu", controls = addInvFlagButtonsPositionsSubMenuControls }
                    local createdaddInvFlagButtonsPositionsSubMenuSurrounding = CreateControl(subMenuRef, subMenuName, subMenuTooltip, subMenuData, nil, nil, nil, nil, nil)
                    table.insert(addInvFlagButtonsPositionsSubMenu, createdaddInvFlagButtonsPositionsSubMenuSurrounding)
                end
            end -- is active filter panel ID?
        end
    end -- for filterPanelId in addInvBtnInvokers
    return addInvFlagButtonsPositionsSubMenu
end
--==================== Filter panel additional inventory context menu "flag" button positions - END =====================================


--[[
--#301 LibSets set search favorites
--Currently disabled because it is unclear how to update the favorite icons properly if they get applied and removed,
--how to update FCOIS LAM settings then etc. Maybe easier to direclty use LibSet's textures as marker icons and create
--some special new marker icons via "plugin system"? > Future idea
local function buildLibSetsSetSearchCategorySubMenu()
    FCOISsettings = FCOIS.settingsVars.settings

    local libSetsSetSearchCategorySubMenu = {}

    local libSetsSetSearchCategoryData = getLibSetsSetSearchFavoriteCategories()
    if ZO_IsTableEmpty(libSetsSetSearchCategoryData) then return libSetsSetSearchCategorySubMenu end

    local LibSetsSetSearchFavoriteToFCOISMapping = FCOISsettings.LibSetsSetSearchFavoriteToFCOISMapping
    local iconSettings = FCOISsettings.icon[FCOIS_CON_ICON_DYNAMIC_1] --use default settings of first dynamic icon

    local optionsLibSetsSetSearchFavoritesCategoryName = locVars["options_LibSetsSetSearchFavoritesCategory"]

    --Map each LibSets set search category data to LibAddonMenu IconPicker controls
    for categoryIndex, categoryData in ipairs(libSetsSetSearchCategoryData) do
        local category = categoryData.category
        local categoryName = categoryData.categoryName or category
        local categoryTexture = categoryData.texture
        if category and categoryTexture then
            local ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, createdControl, createdDDControl

            --Add the current LibSets set search favorite category icon as texture, with the name of the category (for visual reference)
            ref = fcoisLAMSettingsReferencePrefix .. libSetsSetSearchFavorite.. category ..  "Icon"
            data = { type = "texture", image = categoryTexture, width = "half", imageWidth = 32, imageHeight=32 }
            disabledFunc = function() return FCOIS.libSets == nil or not FCOISsettings.autoMarkLibSetsSetSearchFavorites end
            defaultSettings = markerIconTextures[1]
            createdControl = CreateControl(ref, name, tooltip, data, disabledFunc, nil, nil, defaultSettings, nil)
            if createdControl ~= nil then
                table.insert(libSetsSetSearchCategorySubMenu, createdControl)
            end
            ref, name, tooltip, data, disabledFunc, getFunc, setFunc, defaultSettings, createdControl, createdDDControl = nil, nil, nil, nil, nil, nil, nil, nil, nil, nil

            --Add the dropdown with the FCOIS marker icons to choose the FCOIS marker icon for the LibSets set search favorite category
            local lamCtrlSetSearchCategoryTooltip = optionsLibSetsSetSearchFavoritesCategoryName .. " #" .. tos(categoryIndex)  .. ": " .. tos(categoryName)
            ref = fcoisLAMSettingsReferencePrefix .. libSetsSetSearchFavorite.. category ..  previewSelect
            name = categoryName
            tooltip = lamCtrlSetSearchCategoryTooltip
            disabledFunc = function() return FCOIS.libSets == nil or not FCOISsettings.autoMarkLibSetsSetSearchFavorites end
            getFunc = function() return LibSetsSetSearchFavoriteToFCOISMapping[category] end
            setFunc = function(markerIconNr)
                if markerIconNr == FCOIS_CON_ICON_NONE then
                    FCOISsettings.LibSetsSetSearchFavoriteToFCOISMappingRemoved[category] = markerIconNr
                    FCOISsettings.LibSetsSetSearchFavoriteToFCOISMapping[category] = nil
                else
                    FCOISsettings.LibSetsSetSearchFavoriteToFCOISMappingRemoved[category] = nil
                    FCOISsettings.LibSetsSetSearchFavoriteToFCOISMapping[category] = markerIconNr
                end
            end
            defaultSettings = FCOIS_CON_ICON_DYNAMIC_1
            createdDDControl = CreateDropdownBox(ref, name, tooltip, disabledFunc, getFunc, setFunc, defaultSettings, iconsListNone, iconsListValuesNone, iconsListNone, nil, "half", true, true)
            if createdDDControl ~= nil then
                table.insert(libSetsSetSearchCategorySubMenu, createdDDControl)
            end

        end
    end
    return libSetsSetSearchCategorySubMenu
end
]]


--======================================================================================================================
--======================================================================================================================
--======================================================================================================================
-- ============= LAM control creation as LAM panel get's opened - END ==================================================
--======================================================================================================================
--======================================================================================================================
--======================================================================================================================




-- ============= run code once as LAM settings menu will be build - BEGIN ===========================================
--Run code once as LAM panel gets created
local function showFCOISSettingsLoadingTexture(lamPanel)
    --Create and show the "FCOIS settings loading" texture (sand clock)
    FCOIS_LAM_MENU_IS_LOADING = wm:CreateControl(lamPanel:GetName() .. "_FCOIS_LAM_MENU_IS_LOADING_TEXTURE", lamPanel, CT_TEXTURE)
    FCOIS_LAM_MENU_IS_LOADING:SetDimensions(56, 56)
    FCOIS_LAM_MENU_IS_LOADING:SetTexture(FCOIS.textureVars.MARKER_TEXTURES[9]) --Sand clock
    FCOIS_LAM_MENU_IS_LOADING:SetColor(1, 0, 0, 1)
    FCOIS_LAM_MENU_IS_LOADING:SetDrawTier(DT_HIGH)
    FCOIS_LAM_MENU_IS_LOADING:ClearAnchors()
    FCOIS_LAM_MENU_IS_LOADING:SetAnchor(TOPRIGHT, lamPanel, TOPRIGHT, -64, -32)
    FCOIS_LAM_MENU_IS_LOADING:SetHandler("OnMouseEnter", function(ctrl)
        ZO_Tooltips_ShowTextTooltip(ctrl, BOTTOM, FCOISlocVars.fcois_loc["options_description_lam_menu_is_loading"])
    end)
    FCOIS_LAM_MENU_IS_LOADING:SetHandler("OnMouseExit", function()
        ZO_Tooltips_HideTextTooltip()
    end)
    FCOIS_LAM_MENU_IS_LOADING:SetMouseEnabled(true)
    FCOIS_LAM_MENU_IS_LOADING:SetHidden(false)
    local animation
    animation, FCOIS_LAM_SettingsMenuOpen_timeline = CreateSimpleAnimation(ANIMATION_SCALE, FCOIS_LAM_MENU_IS_LOADING, 750)
    animation:SetScaleValues(1, 1.75)
    animation:SetDuration(200)
    FCOIS_LAM_SettingsMenuOpen_timeline:SetPlaybackType(ANIMATION_PLAYBACK_PING_PONG, 10)
end


local function runOnceAsLAMPanelGetsCreated(lamPanel)
    locVars = FCOISlocVars.fcois_loc
    noneEntryStr = locVars["options_dropdown_none"]

    --Build the icons & choicesValues list for the LAM icon dropdown boxes (again)
    updateAllIconsList()

    --Build the other addons list for the LAM dropdown boxes
    buildRecipeAddonsList()
    buildResearchAddonsList()
    buildSetCollectionAddonsList()
    buildMotifsAddonsList() --#308

    --Rebuild the server, account and charaacter dropdowns etc.
    reBuildServerOptions()
    reBuildAccountOptions()
    reBuildCharacterOptions()

    --Build the LAM 2.x checkboxes for the traits now
    buildTraitCheckboxes()


    --Check if the user set ordering of context menu entries (marker icons) is valid, else use the default sorting
    -->With FCOIS 2.0.3 it should be always valid due to the usage of the LibAddonMenu-2.0 OrderListBox, and no dropdown boxes anymore!
    -->But just in case run the function here once as the LAM panel creates -> See function FCOIS.BuildAddonMenu()
    if FCOIS.CheckIfUserContextMenuSortOrderValid() == false then
        FCOIS.ResetUserContextMenuSortOrder()
    end

    --[Other addons]
    --GridList
    GridListActivated = GridList ~= nil or false
    --InventoryGridView
    InventoryGridViewActivated = (FCOIS.otherAddons.inventoryGridViewActive == true or InventoryGridView ~= nil) or false
    if InventoryGridViewActivated == true then FCOIS.otherAddons.inventoryGridViewActive = true end

    --Show the FCOIS is loading "snadclock" texture
    showFCOISSettingsLoadingTexture(lamPanel)

    FCOIS.APIversion = FCOIS.APIversion or GetAPIVersion()
    --Backup variables
    if FCOIS.backup == nil then FCOIS.backup = {} end
    FCOIS.backup.withDetails = false
    FCOIS.backup.doClearBackup = false
    FCOIS.backup.apiVersion = tos(FCOIS.APIversion)
    --Restore variables
    if FCOIS.restore == nil then FCOIS.restore = {} end
    FCOIS.restore.withDetails = false
    FCOIS.restore.apiVersion = nil
end
-- ============= run code once before LAM settings menu will be build - END ===========================================



--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
-- Build the LAM options menu
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
function FCOIS.BuildAddonMenu()
--d("[FCOIS]BuildAddonMenu")
    --Update the localizations as they might have been changed meanwhile
    -->Init via keybinds and updated from SavedVariables at event_add_on_loaded
    FCOISlocVars =    FCOIS.localizationVars
    locVars =         FCOISlocVars.fcois_loc

    --Update some settings for the libAddonMenu settings menu
    FCOIS.UpdateSettingsBeforeAddonMenu()

    --Update localizationDependent variables for the settings menu
    updateLocalizedVariablesBeforeAddonMenu()

    --Update the data for the enabled marker icons, for the sort OrderListBoxWidgets
    updateEnabledMarkerIconsSortOrderListData(true)

    --[Local variables to speed up stuff a bit]
    FCOISdefaultSettings =  FCOIS.settingsVars.defaults
    FCOISsettings =         FCOIS.settingsVars.settings
    isIconEnabled =         FCOISsettings.isIconEnabled
    numDynIcons =           FCOISsettings.numMaxDynamicIconsUsable
    local addonVars =       FCOIS.addonVars
    local addonFAQentry =   addonVars.FAQentry


    --[The LAM settings panel data]
    local panelData = {
        type 				= 'panel',
        name 				= addonVars.addonNameMenu,
        displayName 		= addonVars.addonNameMenuDisplay,
        author 				= addonVars.addonAuthor,
        version 			= addonVars.addonVersionOptions,
        registerForRefresh 	= true,
        registerForDefaults = true,
        slashCommand 		= "/fcoiss",
        website             = addonVars.website,
        feedback            = function() FCOIS.toggleFeedbackButton(true, true) end,
        donation            = addonVars.donation,
    }
    local FCOISLAMPanelName = addonVars.gAddonName .. "_LAM"
    --The LibAddonMenu2.0 settings panel reference variable
    local FCOSettingsPanel = FCOIS.LAM:RegisterAddonPanel(FCOISLAMPanelName, panelData)
    FCOIS.FCOSettingsPanel = FCOSettingsPanel


    --[Libraries]
    --LibShifterBox
    local lsb = FCOIS.libShifterBox
    local libShifterBoxes
    if lsb then
        libShifterBoxes = FCOIS.LibShifterBoxes
    end


    --[Run once as LAM panel get's created]
    runOnceAsLAMPanelGetsCreated(FCOSettingsPanel)

    --Updated variables after runOnce code was called
    local apiVersion =      FCOIS.APIversion
    local fcoBackup =       FCOIS.backup
    local fcoRestore =      FCOIS.restore

    --Build the dropdown box for the restorable API versions now
    buildRestoreAPIVersionData(false)

    --Build the dropdown box for the marker icon delete now
    buildMarkerIconsData(false)

    --[Submenus]
    --Other addons
    -- Creating LAM submenu for the SetTracker addon
    local SetTrackerSubmenuControls = LAMSubmenuSetTracker() --#307
    -- Creating LAM submenu for the ItemCooldownTracker addon
    local ItemCooldownTrackerSubmenuControls = LAMSubmenuItemCooldownTracker() --#306
    local WritCreatorSubmenuControls = LAMSubmenuDolgubonLazyWritCreator()


    --Marker icons
    --Build submenus for the normal and the gear marker icons
    local normalIconsSubMenus = buildNormalIconSubMenus()
    local gearIconsSubMenus   = buildNormalIconSubMenus("gear")
    --Build submenu for the normal & gear marker icon enable checkboxes
    local normalIconsEnabledCheckboxes = buildNormalIconEnableCheckboxes()
    local gearIconsEnabledCheckboxes = buildNormalIconEnableCheckboxes("gear")
    --Build submenu for the dynamic marker icons
    local dynIconsSubMenus = buildDynamicIconSubMenus()
    --Build submenu for the dynamic marker icon enable checkboxes
    local dynIconsEnabledCheckboxes = buildDynamicIconEnableCheckboxes()

    --Filter buttons
    --Build submenu for the filterButton positions
    local filterButtonsPositionsSubMenu = buildFilterButtonsPositionsSubMenu()
    --Build submenu for additional inventory flag button contextMenus
    local addInvFlagButtonsPositionsSubMenu = buildAddInvContextMenuFlagButtonsPositionsSubMenu()
    --Build submenu for LibSets set search favorites
    --local libSetsSetSearchFavoritesSubMenu = buildLibSetsSetSearchCategorySubMenu() --#301


    --==================== LAM callbacks - BEGIN =====================================
    --LAM 2.0 callback function if the panel was created
    local lamPanelCreationInitDone = false
    local function FCOLAMPanelCreated(panel)
        if panel ~= FCOIS.FCOSettingsPanel then return end
        --d("[FCOIS] SettingsPanel Created")
        --Update the filterIcon textures etc.
        if not lamPanelCreationInitDone then
            for markerIconIndex = FCOIS_CON_ICON_LOCK, numFilterIcons do
                InitPreviewIcon(markerIconIndex)
            end

            --Set the editbox TextType to validate the entered value
            setSettingsMenuEditBoxTextTypes(panel)

            --Remove the "FCOIS LAM Panel is loading" sand clock texture at the top right corner of the LAM panel
            if FCOIS_LAM_MENU_IS_LOADING and not FCOIS_LAM_MENU_IS_LOADING:IsHidden() then
                FCOIS_LAM_MENU_IS_LOADING:SetHidden(true)
                FCOIS_LAM_SettingsMenuOpen_timeline:Stop()
            end

            lamPanelCreationInitDone = true
            panel.controlsWereLoaded = true
        end
        --Check if the user set ordering of context menu entries (marker icons) is valid, else use the default sorting
        -->With FCOIS 2.0.3 it should be always valid due to the usage of the LibAddonMenu-2.0 OrderListBox, and no dropdown boxes anymore!
        -->But just in case run the function here once as the LAM panel creates -> See function FCOIS.BuildAddonMenu()
        --[[
        if FCOIS.CheckIfUserContextMenuSortOrderValid() == false then
            FCOIS.ResetUserContextMenuSortOrder()
        end
        ]]
        --Show the LAM menu container now
        --ChangeFCOISLamMenuVisibleState(false)
        --cm:UnregisterCallback("LAM-PanelControlsCreated")
    end

    --The panel opened callback function
    local function FCOLAMPanelOpened(panel)
        --d("[FCOIS] SettingsPanel Opened: " ..tos(panel.data.name))
        if panel ~= FCOIS.FCOSettingsPanel then return end
        hideItemLinkTooltip()

        LAMopenedCounter = LAMopenedCounter + 1
        FCOIS.CheckIfOtherAddonActive()

        if not panel.controlsWereLoaded == true or not lamPanelCreationInitDone == true then
            if FCOIS_LAM_MENU_IS_LOADING then
                FCOIS_LAM_MENU_IS_LOADING:SetHidden(false)
                FCOIS_LAM_SettingsMenuOpen_timeline:PlayFromStart()
            end
        end
        --Were the controls all loaded meanwhile? Hide the loading texture again
        if FCOIS_LAM_MENU_IS_LOADING and panel.controlsWereLoaded == true and lamPanelCreationInitDone == true then
            FCOIS_LAM_MENU_IS_LOADING:SetHidden(true)
            FCOIS_LAM_SettingsMenuOpen_timeline:Stop()
        end

        --Workaround for LibFeedback (as jumping to any other scene like mail will hide the FCOIS lam panel but will not unhide it again at next showing)
        local panelContainer = panel.container
        if panelContainer ~= nil and panelContainer:IsHidden() then
        --d(">FCOIS LAM panel container was unhidden again!")
            panelContainer:SetHidden(false)
        end
    end

    --The panel opened callback function
    local function FCOLAMPanelClosed(panel)
        --d("[FCOIS] SettingsPanel Closed: " ..tos(panel.data.name))
        if panel ~= FCOIS.FCOSettingsPanel then return end
        hideItemLinkTooltip()
        --d("[FCOIS] SettingsPanel Closed")

        --Was the inventory scene for the GridList preview enabled and not disabled? Hide it now
        if (GridListActivated == true or InventoryGridViewActivated == true) and FCOIS.preventerVars.lamMenuOpenAndShowingInvPreviewForGridListAddon == true then
            --Hide the inventory fragment
            removeInventoryFragment()
        end

        --Update the localization once if something changed that needs to update the localization
        if FCOIS.preventerVars.doUpdateLocalization == true then
            FCOIS.preventerVars.KeyBindingTexts = false
            --d("[FCOIS]LAM settings menu close: Update localization once")
            FCOIS.Localization()
            FCOIS.preventerVars.KeyBindingTexts = true
        end
    end

    --[[
    --Refresh LAM panel callback function
    local function FCOLAMPanelRefreshed(controlRefreshed)
        --Check if the control is our FCOIS submenu of other addons, GridList
        if not FCOIS.LAM or FCOIS.LAM.currentAddonPanel ~= FCOIS.FCOSettingsPanel then return end
    end
    ]]
    --==================== LAM callbacks - END =====================================


    --The option controls for the LAM 2.0 panel
    local optionsTable =
    {	-- BEGIN OF OPTIONS TABLE
        {
            type = 'description',
            text = locVars["options_description"],
            reference = "FCOItemSaver_LAM_Settings_Description_Header",
            --helpUrl = locVars["options_description"],
        },

        --==============================================================================
        {
            type = "submenu",
            name = locVars["options_header1"],
            controls =
            {
                {
                    type = 'dropdown',
                    name = locVars["options_language"],
                    tooltip = locVars["options_language" .. tooltipSuffix],
                    choices =       languageOptions,
                    choicesValues = languageOptionsValues,
                    getFunc = function() return FCOIS.settingsVars.defaultSettings.language end,
                    setFunc = function(value)
                        --[[
                        for i,v in pairs(languageOptions) do
                            if v == value then
                                if FCOIS.settingsVars.settings.debug then debugMessage( "[Settings]","language v: " .. tos(v) .. ", i: " .. tos(i), false) end
                                FCOIS.settingsVars.defaultSettings.language = i
                                --Tell the FCOISsettings that you have manually chosen the language and want to keep it
                                --Read in function Localization() after ReloadUI()
                                FCOISsettings.languageChosen = true
                                --locVars			  	 = locVars[i]
                                --ReloadUI()
                            end
                        end
                        ]]
                        FCOIS.settingsVars.defaultSettings.language = value
                        --Tell the FCOISsettings that you have manually chosen the language and want to keep it
                        --Read in function Localization() after ReloadUI()
                        FCOISsettings.languageChosen = true
                    end,
                    disabled = function() return FCOISsettings.alwaysUseClientLanguage end,
                    warning = locVars["options_language_description1"],
                    requiresReload = true,
                    --helpUrl = locVars["options_language"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_language_use_client"],
                    tooltip = locVars["options_language_use_client" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.alwaysUseClientLanguage end,
                    setFunc = function(value)
                        FCOISsettings.alwaysUseClientLanguage = value
                        --ReloadUI()
                    end,
                    warning = locVars["options_language_description1"],
                    requiresReload = true,
                    default = FCOISdefaultSettings.alwaysUseClientLanguage,
                    --helpUrl = locVars["options_language_use_client"],
                },

                {
                    type = 'dropdown',
                    name = locVars["options_savedvariables"],
                    tooltip = locVars["options_savedvariables" .. tooltipSuffix],
                    choices =       savedVariablesOptions,
                    choicesValues = savedVariablesOptionsValues,
                    getFunc = function() return FCOIS.settingsVars.defaultSettings.saveMode end,
                    setFunc = function(value)
                        --[[
                        for i,v in ipairs(savedVariablesOptions) do
                            if v == value then
                                if FCOIS.settingsVars.settings.debug then debugMessage( "[Settings]","save mode v: " .. tos(v) .. ", i: " .. tos(i), false) end
                                FCOIS.settingsVars.defaultSettings.saveMode = i
                                --ReloadUI()
                            end
                        end
                        ]]
                        FCOIS.settingsVars.defaultSettings.saveMode = value
                    end,
                    warning = locVars["options_language_description1"],
                    requiresReload = true,
                    --helpUrl = locVars["options_savedvariables" .. tooltipSuffix],
                    default = savedVariablesOptionsValues[2], -- Account wide
                },
                --Unique ID switch
                {
                    type = 'header',
                    name = locVars["options_header_uniqueids"],
                },
                {
                    type = 'description',
                    text = locVars["options_description_uniqueids"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_use_uniqueids"],
                    tooltip = locVars["options_use_uniqueids" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.useUniqueIds end,
                    setFunc = function(value)
                        --Remember the last used "is uniqueID enabled" state from before the change of this setting
                        -->Used in file /src/FCOIS_settings.lua, function scanBagsAndTransferMarkerIcon()
                        local lastUsedUniqueIdEnabled = FCOISsettings.useUniqueIds
                        FCOISsettings.lastUsedUniqueIdEnabled = lastUsedUniqueIdEnabled


                        --Old:
                        --Only set the "toggle" variable which will be read in file /src/FCOIS_Settings.lua, function FCOIS.afterSettings()
                        --and will change the variable FCOIS.settingsVars.settings.useUniqueIds then, after the reloadui has taken place!
                        -->This variable will start the migration dialog after the reloadui! See variable FCOIS.preventerVars.migrateItemMarkers
                        -->in file /src/FCOIS_Settings.lua, function FCOIS.afterSettings(), and file /src/FCOIS_Dialogs.lua, dialog "FCOIS_ASK_BEFORE_MIGRATE_DIALOG"
                        -->and function FCOIS.migrateItemInstanceIdMarkersToUniqueIdMarkers() in file /src/FCOIS_Settings.lua
                        FCOISsettings.useUniqueIdsToggle = value


                        --New: NO DIRECT change of the variable as else the dropdown box below would re-set this checkbox here
                        --if the LAM refresh for the controls is called (upon change of the dropdown box all other controls
                        --will refresh as well -> variable useUniqueIdsToggle is not used for the getfunc and thus the checkbox
                        --wil be disabled automatically again).
                        --FCOISsettings.useUniqueIds = value

                        --EDIT: Directly reload as this setting changes to make sure/safe the toggle variable is ONLY set
                        --and the useUniqueIds variable will be set in file src/FCOIS_Settings.lua, function FCOIS.afterSettings()
                        ReloadUI()
                    end,
                    warning = locVars["options_description_uniqueids"],
                    --requiresReload = true,
                    default = FCOISdefaultSettings.useUniqueIds,
                },
                {
                    type = 'dropdown',
                    name = locVars["options_use_uniqueids_type"],
                    tooltip = locVars["options_use_uniqueids_type" .. tooltipSuffix],
                    choices = uniqueItemIdTypeChoices,
                    choicesValues = uniqueItemIdTypeChoicesValues,
                    choicesTooltips = uniqueItemIdTypeChoicesTT,
                    getFunc = function() return FCOISsettings.uniqueItemIdType end,
                    setFunc = function(value)
                        --Remember the last used uniqueID type from before the change of this setting
                        -->Used in file /src/FCOIS_settings.lua, function scanBagsAndTransferMarkerIcon()
                        local lastUsedUniqueIdType = FCOISsettings.uniqueItemIdType
                        FCOISsettings.lastUsedUniqueIdType = lastUsedUniqueIdType
                        --Set the new unique type
                        FCOISsettings.uniqueItemIdType = value
                        ReloadUI()
                    end,
                    --requiresReload = true,
                    warning = locVars["options_use_uniqueids_type" .. tooltipSuffix],
                    --helpUrl = locVars["options_savedvariables" .. tooltipSuffix],
                    default = FCOISdefaultSettings.uniqueItemIdType,
                    disabled = function()
                        return not FCOISsettings.useUniqueIds
                    end
                },
                --==============================================================================
                --The parts of the uniqueId (these will build the uniqueId if the user has chosen the FCOIS internally
                --created uniqueId
                {
                    type = 'header',
                    name = locVars["options_unique_id_parts_header"],
                },
                {
                    type = "description",
                    text = locVars["options_unique_id_by_FCOIS_info"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_itemId"],
                    tooltip = locVars["options_unique_id_part_itemId"],
                    getFunc = function() return true end,
                    setFunc = function(value)
                        --Currntly the box is disabled as the itemId always needs to be added
                        --FCOISsettings.uniqueIdParts.itemId = value
                        FCOISsettings.uniqueIdParts.itemId = true
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = true,
                    disabled = function() return true end, --this cannot be removed but should be "shown as a part of the uniqueID"
                    width = "full",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_level"],
                    tooltip = locVars["options_unique_id_part_level"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.level end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.level = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.level,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_quality"],
                    tooltip = locVars["options_unique_id_part_quality"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.quality end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.quality = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.quality,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_stolen"],
                    tooltip = locVars["options_unique_id_part_stolen"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.isStolen end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.isStolen = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.isStolen,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_trait"],
                    tooltip = locVars["options_unique_id_part_trait"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.trait end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.trait = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.trait,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_enchantment"],
                    tooltip = locVars["options_unique_id_part_enchantment"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.enchantment end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.enchantment = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.enchantment,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_style"],
                    tooltip = locVars["options_unique_id_part_style"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.style end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.style = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.style,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_crafted"],
                    tooltip = locVars["options_unique_id_part_crafted"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.isCrafted end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.isCrafted = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.isCrafted,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_crafted_by"],
                    tooltip = locVars["options_unique_id_part_crafted_by"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.isCraftedBy end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.isCraftedBy = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.isCraftedBy,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() or not FCOISsettings.uniqueIdParts.isCrafted end,
                    width = "half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_unique_id_part_crownItem"],
                    tooltip = locVars["options_unique_id_part_crownItem"],
                    getFunc = function() return FCOISsettings.uniqueIdParts.isCrownItem end,
                    setFunc = function(value)
                        FCOISsettings.uniqueIdParts.isCrownItem = value
                        resetCreateFCOISUniqueIdStringLastVars()
                    end,
                    default = FCOISdefaultSettings.uniqueIdParts.isCrownItem,
                    disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                    width = "half",
                },


                --==============================================================================
                --LibShifterBox: ItemTypes for uniqueIds by FCOIS
                {
                    type = "custom",
                    reference = (lsb and libShifterBoxes[FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES].name) or "FCOITEMSAVER_LAM_CUSTOM___FCOIS_UNIQUEID_ITEMTYPES",
                    createFunc = function(customControl)
                        if not lsb then return end
                        FCOIS.createLibShifterBox(customControl, FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES)
                        --[[
                        --Currently not needed as a reloadui needs to be done to chnage the uniqueId and thus this disabled update will be done autoamtically at the LibShifterBox functions
                        customControl.UpdateDisabled = function(customControl)
d("[FCOIS]LAM - UpdateDisabled -> FCOIS_CON_LIBSHIFTERBOX_FCOISUNIQUEIDITEMTYPES")
                            if not uniqueIdIsEnabledAndSetToFCOIS() then

                            end
                        end
                        ]]
                    end,
                    width="full",
                    minHeight = 220,
                    --disabled = function() return not uniqueIdIsEnabledAndSetToFCOIS() end,
                },


                --==============================================================================
                --Migration
                {
                    type = 'submenu',
                    name = locVars["options_header_migration"],
                    controls = {
                        {
                            type = 'header',
                            name = locVars["options_header_migration_ids"],
                            --helpUrl = locVars["options_header_ZOsLock"],
                        },
                        --Migrate the item markers from itemInstanceid to UniqueId
                        {
                            type = "description",
                            text = locVars["options_migrate_ids_migration_log"],
                        },
                        {
                            type = "button",
                            name = locVars["options_migrate_uniqueids"],
                            tooltip = locVars["options_migrate_uniqueids" .. tooltipSuffix],
                            func = function()
                                if FCOISsettings.useUniqueIds == true then
                                    FCOIS.preventerVars.migrateToItemInstanceIds = false
                                    FCOIS.preventerVars.migrateToUniqueIds = true
                                    migrateMarkerIcons()
                                end
                            end,
                            isDangerous = true,
                            disabled = function() return not FCOISsettings.useUniqueIds end,
                            warning = locVars["options_migrate_uniqueids_warning"],
                            width="half",
                        },
                        {
                            type = "button",
                            name = locVars["options_migrate_iteminstanceids"],
                            tooltip = locVars["options_migrate_iteminstanceids" .. tooltipSuffix],
                            func = function()
                                if FCOISsettings.useUniqueIds == false then
                                    FCOIS.preventerVars.migrateToUniqueIds = false
                                    FCOIS.preventerVars.migrateToItemInstanceIds = true
                                    migrateMarkerIcons()
                                end
                            end,
                            isDangerous = true,
                            disabled = function() return FCOISsettings.useUniqueIds end,
                            warning = locVars["options_migrate_iteminstanceids_warning"],
                            width="half",
                        },

                        {
                            type = 'header',
                            name = locVars["options_header_ZOsLock"],
                            --helpUrl = locVars["options_header_ZOsLock"],
                        },
                        {
                            type = "button",
                            name = locVars["options_scan_ZOs_lock_functions"],
                            tooltip = locVars["options_scan_ZOs_lock_functions" .. tooltipSuffix],
                            func = function() FCOIS.ScanInventoriesForZOsLockedItems(true)
                            end,
                            isDangerous = true,
                            --disabled = function() return FCOISsettings.useZOsLockFunctions end,
                            warning = locVars["options_scan_ZOs_lock_functions_warning"],
                            width="half",
                            --helpUrl = locVars["options_scan_ZOs_lock_functions"],
                        },

                    }, -- submenu controls "migraion"
                },-- submenu "migraion"

            } -- controls submenu general options
        }, -- submenu general options
        --==============================================================================
        -- vvv OTHER ICONS vvv
        --==============================================================================
        {
            type = "submenu",
            name = locVars["options_header" .. colorSuffix],
            controls =
            {
                --==============================================================================
                --TESO standard lock icon
                {
                    type = 'header',
                    name = locVars["options_header_ZOsLock"],
                    --helpUrl = locVars["options_header_ZOsLock"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_use_ZOs_lock_functions"],
                    tooltip = locVars["options_use_ZOs_lock_functions" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.useZOsLockFunctions end,
                    setFunc = function(value) FCOISsettings.useZOsLockFunctions = value
                    end,
                    width="half",
                    default = FCOISdefaultSettings.useZOsLockFunctions,
                    --helpUrl = locVars["options_scan_ZOs_lock_functions"],
                },
                --==============================================================================
                {
                    type = "description",
                    text = locVars[optionsIcon .. "s_description"],
                },
                {
                    type = "submenu",
                    name = locVars[optionsIcon .. "s_non_gear"],
                    controls =
                    {
                        {
                            type = "description",
                            text = locVars[optionsIcon .. "s_non_gear_sets_description"],
                        },
                        --==============================================================================
                        --The submenus for all the normal icons
                        {
                            type = "submenu",
                            name = locVars[optionsIcon .. "s_non_gear"],
                            controls = normalIconsSubMenus
                        }, -- submenu non-gear icons
                        --==============================================================================
                        -- NORMAL ICONS enabled/disabled
                        {
                            type = "submenu",
                            name = locVars["options_header_enable_disable"],
                            controls = normalIconsEnabledCheckboxes
                        }, -- submenu normal icons enable/disable

                    } -- controls non-gear (normal) icons
                }, -- submenu non-gear (normal) icons
                --==============================================================================
                -- ^^^ OTHER ICONS ^^^
                --
                -- vvv GEAR SETS vvv
                --==============================================================================
                {
                    type = "submenu",
                    name = locVars[optionsIcon .. "s_gears"],
                    controls =
                    {
                        {
                            type = "description",
                            text = locVars[optionsIcon .. "s_gear_sets_description"],
                        },
                        --==============================================================================
                        --The submenus for all the gear icons
                        {
                            type = "submenu",
                            name = locVars[optionsIcon .. "s_gears"],
                            controls = gearIconsSubMenus
                        }, -- submenu gear icons
                        --==============================================================================
                        -- GEAR SETS enabled/disabled
                        {
                            type = "submenu",
                            name = locVars["options_header_enable_disable"],
                            controls = gearIconsEnabledCheckboxes
                        }, -- submenu gear sets enabled/disabled

                    } -- controls gear sets
                }, -- submenu gear sets

                --==============================================================================
                -- ^^^ GEAR SETS ^^^
                --==============================================================================

                --==============================================================================
                -- DYNAMIC ICONs
                --==============================================================================
                {
                    type = "submenu",
                    name = locVars[optionsIcon .. "s_dynamic"],
                    controls =
                    {

                        {
                            type = "description",
                            text = locVars[optionsIcon .. "s_dynamic_usable_warning"],
                        },
                        --==============================================================================
                        --Slider to change total possible dynamic icons -> Speedup for non-used dynamic icons (1-30)
                        {
                            type = "slider",
                            name = locVars[optionsIcon .. "s_dynamic_usable"],
                            tooltip = locVars[optionsIcon .. "s_dynamic_usable" .. tooltipSuffix],
                            min = 1,
                            max = numMaxDynIcons,
                            decimals = 0,
                            autoSelect = true,
                            getFunc = function() return FCOISsettings.numMaxDynamicIconsUsable end,
                            setFunc = function(numDynIconsTotalUsable)
                                if FCOISsettings.numMaxDynamicIconsUsable ~= numDynIconsTotalUsable then
                                    FCOIS.settingsVars.settings.numMaxDynamicIconsUsable = numDynIconsTotalUsable
                                    --Slider was manually changed: So disable the automatic "max dyn. icons enabled check" in file src/FCOIS_Settings.lua, function afterSettings()!
                                    FCOISsettings.addonFCOISChangedDynIconMaxUsableSlider = false

                                    --If the slider was changed, automatically disable dynamic icons with a number > than the max allowed one
                                    -->Will also be checked at FCOIS.AfterSettings() after the reloadUI was done!
                                    if numDynIconsTotalUsable > 0 then
                                        local icon2Dynamic = FCOIS.mappingVars.iconToDynamic

                                        for iconNr, isEnabled in ipairs(FCOISsettings.isIconEnabled) do
                                            if isEnabled == true then
                                                local dynamicIconNr = icon2Dynamic[iconNr]
                                                if dynamicIconNr ~= nil then
                                                    if dynamicIconNr > numDynIconsTotalUsable then
--d("[FCOIS-SettingsMenu]Automatically disabled dynamic icon #" .. tos(dynamicIconNr) .. " (iconNr: " .. tos(iconNr) .. "), as the slider numMaxDynamicIconsUsable prohibits it!")
                                                        FCOIS.settingsVars.settings.isIconEnabled[iconNr] = false
                                                    end
                                                end
                                            end
                                        end
                                    end
                                    --Reload the UI now to assure that all settings get updated properly directly!
                                    ReloadUI()
                                end
                            end,
                            width="full",
                            disabled = function() return false end,
                            default = FCOISdefaultSettings.numMaxDynamicIconsUsable,
                            requiresReload = true,
                        },

                        --==============================================================================
                        --The submenus for all the dynamic icons
                        {
                            type = "submenu",
                            name = locVars[optionsIcon .. "s_dynamic"],
                            controls = dynIconsSubMenus
                        },
                        --==============================================================================
                        -- Dynamic icons - Enable/Disable them
                        {
                            type = "submenu",
                            name = locVars["options_header_enable_disable"],
                            controls = dynIconsEnabledCheckboxes
                        },

                    },	-- controls DYNAMIC ICONs
                }, -- submenu DYNAMIC ICONs

                --==============================================================================
                -- ICON OPTIONS
                --=============================================================================================
                {
                    type = "submenu",
                    name = locVars["options_header_icon_options"],
                    controls =
                    {
                        --========= ICON SORT OPTIONS ==================================================
                        -- FCOIS Icon sort order - Output of marker icons - #278
                        {
                            type = "submenu",
                            name = locVars["options_header_sort_order_output"],
                            reference = "FCOItemSaver_Settings_IconSortOrder_Output_SubMenu",
                            controls = {

                                --[[
                                --FCOIS version 2.5.6
                                ]]

                                {
                                    type = "orderlistbox",
                                    name = locVars["options_header_sort_order_output"],
                                    tooltip = locVars["options_header_sort_order_output_TT"],
                                    listEntries = FCOIS.settingsVars.settings.markerIconsOutputOrderEntries,
                                    showPosition = true,
                                    getFunc = function()
--d("[FCOIS]LAM - getFunc: markerIconsOutputOrderEntries")
                                        return FCOIS.settingsVars.settings.markerIconsOutputOrderEntries
                                    end,
                                    setFunc = function(sortedSortListEntries)
--d("[FCOIS]LAM - setFunc: markerIconsOutputOrderEntries")
                                        --[[
        [1] = {
            value = "Value of the entry", -- or number or boolean or function returning the value of this entry
            uniqueKey = 1, --number of the unique key of this list entry. This will not change if the order changes. Will be used to identify the entry uniquely
            text  = "Text of this entry", -- or string id or function returning a string (optional)
            tooltip = "Tooltip text shown at this entry", -- or string id or function returning a string (optional)
        },                                        ]]
--FCOIS._debugMarkerIconsOutputOrder_SetFunc_sortedSortListEntries = sortedSortListEntries
                                        --sortedSortListEntries = FCOIS.settingsVars.settings.markerIconsOutputOrderEntries -> No! Currently it seems to be a copy  and thus update does not properly work!
                                        updateMarkerIconsOutputOrder(sortedSortListEntries)
                                    end,
                                    width="full",
                                    isExtraWide = true,
                                    minHeight = 250,
                                    maxHeight = 400,
                                    reference = "FCOItemSaver_Settings_IconSortOrder_Output_OrderListBox",
                                    --disabled = function() return false end,
                                    default = function()
 --d("[FCOIS]LAM - defauklt: markerIconsOutputOrderEntries")
                                        return FCOISdefaultSettings.markerIconsOutputOrderEntries
                                    end,
                                },
                            },

                        },
                        --========= ICON SORT OPTIONS ==================================================
                        -- FCOIS Icon sort order in context menus
                        {
                            type = "submenu",
                            name = locVars["options_header_sort_order"],
                            reference = "FCOItemSaver_Settings_IconSortOrder_SubMenu",
                            controls = {

                                --[[
                                --FCOIS version 2.0.3
                                ]]

                                {
                                    type =    "checkbox",
                                    name =    locVars[optionsIcon .. "_sort_order_add_inv_button_flag_too"],
                                    tooltip = locVars[optionsIcon .. "_sort_order_add_inv_button_flag_too" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.sortIconsInAdditionalInvFlagContextMenu end,
                                    setFunc = function(value) FCOIS.settingsVars.settings.sortIconsInAdditionalInvFlagContextMenu = value
                                    end,
                                    default = FCOISdefaultSettings.sortIconsInAdditionalInvFlagContextMenu,
                                },
                                {
                                    type = "orderlistbox",
                                    name = locVars["options_header_sort_order"],
                                    tooltip = locVars["options_header_sort_order"],
                                    listEntries = FCOISsettings.iconSortOrderEntries,
                                    showPosition = true,
                                    getFunc = function() return FCOISsettings.iconSortOrderEntries end,
                                    setFunc = function(sortedSortListEntries)
                                        --[[
        [1] = {
            value = "Value of the entry", -- or number or boolean or function returning the value of this entry
            uniqueKey = 1, --number of the unique key of this list entry. This will not change if the order changes. Will be used to identify the entry uniquely
            text  = "Text of this entry", -- or string id or function returning a string (optional)
            tooltip = "Tooltip text shown at this entry", -- or string id or function returning a string (optional)
        },                                        ]]
                                        for idx, data in ipairs(sortedSortListEntries) do
                                            FCOIS.settingsVars.settings.icon[data.value].sortOrder = idx
                                            FCOIS.settingsVars.settings.iconSortOrder[idx] = data.value
                                        end
                                    end,
                                    width="full",
                                    isExtraWide = true,
                                    minHeight = 250,
                                    maxHeight = 400,
                                    reference = "FCOItemSaver_Settings_IconSortOrder_OrderListBox",
                                    disabled = function() return not FCOISsettings.sortIconsInAdditionalInvFlagContextMenu end,
                                    default = FCOISdefaultSettings.iconSortOrderEntries,
                                },
                            },

                        },
                        --========= ICON POSITIONS ==================================================
                        {
                            type = "submenu",
                            name = locVars["options_header_pos"],
                            controls =
                            {
                                {
                                    type = "slider",
                                    name = locVars["options_pos_inventories"],
                                    tooltip = locVars["options_pos_inventories" .. tooltipSuffix],
                                    min = -10,
                                    max = 540,
                                    autoSelect = true,
                                    getFunc = function() return FCOISsettings.iconPosition.x end,
                                    setFunc = function(offset)
                                        FCOISsettings.iconPosition.x = offset
                                        --Set global variable to update the marker colors and textures
                                        FCOIS.preventerVars.gUpdateMarkersNow = true
                                    end,
                                    width="full",
                                    default = FCOISdefaultSettings.iconPosition.x,
                                },
                                {
                                    type = "slider",
                                    name = locVars["options_pos_crafting"],
                                    tooltip = locVars["options_pos_crafting" .. tooltipSuffix],
                                    min = -10,
                                    max = 540,
                                    autoSelect = true,
                                    getFunc = function() return FCOISsettings.iconPositionCrafting.x end,
                                    setFunc = function(offset)
                                        FCOISsettings.iconPositionCrafting.x = offset
                                        --Set global variable to update the marker colors and textures
                                        FCOIS.preventerVars.gUpdateMarkersNow = true
                                    end,
                                    width="full",
                                    default = FCOISdefaultSettings.iconPositionCrafting.x,
                                },
                                {
                                    type = "slider",
                                    name = locVars["options_pos_character_x"],
                                    tooltip = locVars["options_pos_character_x" .. tooltipSuffix],
                                    min = -15,
                                    max = 40,
                                    autoSelect = true,
                                    getFunc = function() return FCOISsettings.iconPositionCharacter.x end,
                                    setFunc = function(offset)
                                        FCOISsettings.iconPositionCharacter.x = offset
                                        --Set global variable to update the marker colors and textures
                                        FCOIS.preventerVars.gUpdateMarkersNow = true
                                    end,
                                    width="half",
                                    default = FCOISdefaultSettings.iconPositionCharacter.x,
                                },
                                {
                                    type = "slider",
                                    name = locVars["options_pos_character_y"],
                                    tooltip = locVars["options_pos_character_y" .. tooltipSuffix],
                                    min = -40,
                                    max = 15,
                                    autoSelect = true,
                                    getFunc = function() return FCOISsettings.iconPositionCharacter.y end,
                                    setFunc = function(offset)
                                        FCOISsettings.iconPositionCharacter.y = offset
                                        --Set global variable to update the marker colors and textures
                                        FCOIS.preventerVars.gUpdateMarkersNow = true
                                    end,
                                    width="half",
                                    default = FCOISdefaultSettings.iconPositionCharacter.y,
                                },
                                {
                                    type = "slider",
                                    name = locVars["options_size_character" .. tooltipSuffix],
                                    tooltip = locVars["options_size_character" .. tooltipSuffix],
                                    min = 10,
                                    max = 64,
                                    autoSelect = true,
                                    getFunc = function() return FCOISsettings.iconSizeCharacter end,
                                    setFunc = function(size)
                                        FCOISsettings.iconSizeCharacter = size
                                        --Set global variable to update the marker colors and textures
                                        FCOIS.preventerVars.gUpdateMarkersNow = true
                                    end,
                                    width="half",
                                    default = FCOISdefaultSettings.iconSizeCharacter,
                                },
                            } -- controls positions
                        }, -- submenu positions

                        --========= ICONSs - OTHER ADDONS ============================================
                        --Other addons
                        {
                            type = "submenu",
                            name = locVars["options_other_addons"],
                            controls =
                            {
                                --GridList
                                {
                                    type = "submenu",
                                    name = "Grid AddOns",
                                    disabled = function() return not InventoryGridViewActivated and not GridListActivated end,
                                    reference = "FCOIS_LAM_SUBMENU_OTHER_ADDONS_GRIDLIST",
                                    controls =
                                    {
                                        {
                                            type = "slider",
                                            name = "Grid AddOns: " .. locVars[optionsIcon .. "_offset_left"],
                                            tooltip = "Grid AddOns: ".. locVars[optionsIcon .. "_offset_left" .. tooltipSuffix],
                                            min = getGridAddonIconSize() * -1,
                                            max = getGridAddonIconSize(),
                                            autoSelect = true,
                                            getFunc = function() return FCOISsettings.markerIconOffset["GridList"].x end,
                                            setFunc = function(offset)
                                                FCOISsettings.markerIconOffset["GridList"].x = offset
                                                --Set global variable to update the marker colors and textures
                                                FCOIS.preventerVars.gUpdateMarkersNow = true
                                                --Should we update the marker textures, size and color?
                                                filterBasics(true)
                                            end,
                                            width="full",
                                            default = FCOISdefaultSettings.markerIconOffset["GridList"].x,
                                        },
                                        {
                                            type = "slider",
                                            name = "Grid AddOns: " .. locVars[optionsIcon .. "_offset_top"],
                                            tooltip = "Grid AddOns: ".. locVars[optionsIcon .. "_offset_top" .. tooltipSuffix],
                                            min = getGridAddonIconSize() * -1,
                                            max = getGridAddonIconSize(),
                                            autoSelect = true,
                                            getFunc = function() return FCOISsettings.markerIconOffset["GridList"].y end,
                                            setFunc = function(offset)
                                                FCOISsettings.markerIconOffset["GridList"].y = offset
                                                --Set global variable to update the marker colors and textures
                                                FCOIS.preventerVars.gUpdateMarkersNow = true
                                                --Should we update the marker textures, size and color?
                                                filterBasics(true)
                                            end,
                                            width="full",
                                            default = FCOISdefaultSettings.markerIconOffset["GridList"].y,
                                        },
                                        {
                                            type = "slider",
                                            name = "Grid AddOns: " .. locVars[optionsIcon .. "_scale"],
                                            tooltip = "Grid AddOns: ".. locVars[optionsIcon .. "_scale" .. tooltipSuffix],
                                            min = 1,
                                            max = 100,
                                            autoSelect = true,
                                            getFunc = function() return FCOISsettings.markerIconOffset["GridList"].scale end,
                                            setFunc = function(scale)
                                                FCOISsettings.markerIconOffset["GridList"].scale = scale
                                                --Set global variable to update the marker colors and textures
                                                FCOIS.preventerVars.gUpdateMarkersNow = true
                                                --Should we update the marker textures, size and color?
                                                filterBasics(true)
                                            end,
                                            width="full",
                                            default = FCOISdefaultSettings.markerIconOffset["GridList"].scale,
                                        },
                                        {
                                            type = "button",
                                            name = locVars["options_preview"],
                                            tooltip = locVars["options_preview"],
                                            func = function()
                                                previewInventoryFragment()
                                            end,
                                            width="full",
                                        },
                                    }, -- controls other addons: GridList
                                }, -- submenu other addons: GridList

                            } -- controls other addons
                        }, -- submenu other addons

                    } -- controls icon options
                }, -- submenu icon options
                --========= DEACTIVATED ICONS OPTIONS============================================

                {
                    type = "submenu",
                    name = locVars["options_header_deactivated_symbols"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_deactivated_symbols_apply_anti_checks"],
                            tooltip = locVars["options_deactivated_symbols_apply_anti_checks" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.checkDeactivatedIcons end,
                            setFunc = function(value) FCOISsettings.checkDeactivatedIcons = value
                            end,
                            default = FCOISdefaultSettings.checkDeactivatedIcons,
                        },
                    } -- controls deactivated items
                }, -- submenu deactivated items

            }, -- controls color and icons
        }, -- submenu color and icons

        --==============================================================================
        -- KEBYINDs
        --==============================================================================
        {
            type = "submenu",
            name = locVars["options_header_keybind_options"],
            controls = {
                {
                    type = "checkbox",
                    name = locVars["options_keybind_enable_chording"],
                    tooltip = locVars["options_keybind_enable_chording" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.enableKeybindChording end,
                    setFunc = function(value) FCOISsettings.enableKeybindChording = value
                        FCOIS.CheckKeybindingChording(value)
                    end,
                    width="full",
                },
                {
                    type = 'dropdown',
                    name = locVars[optionsIcon .. "_standard_on_keybind"],
                    tooltip = locVars[optionsIcon .. "_standard_on_keybind" .. tooltipSuffix],
                    choices = iconsList,
                    choicesValues = iconsListValues,
                    scrollable = true,
                    getFunc = function() return FCOISsettings.standardIconOnKeybind
                    end,
                    setFunc = function(value)
                        FCOISsettings.standardIconOnKeybind = value
                    end,
                    default = iconsList[FCOISdefaultSettings.standardIconOnKeybind],
                    reference = "FCOItemSaver_Standard_Icon_On_Keybind_Dropdown",
                    disabled = function() return FCOISsettings.cycleMarkerSymbolOnKeybind end,
                },
                {
                    type = "checkbox",
                    name = locVars[optionsIcon .. "_cycle_on_keybind"],
                    tooltip = locVars[optionsIcon .. "_cycle_on_keybind" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.cycleMarkerSymbolOnKeybind end,
                    setFunc = function(value) FCOISsettings.cycleMarkerSymbolOnKeybind = value
                    end,
                    width="full",
                },
                --Keybind for "Move all 'marked for sell' to junk"
                {
                    type = "checkbox",
                    name = locVars["options_keybind_move_marked_for_sell_to_junk_enabled"],
                    tooltip = locVars["options_keybind_move_marked_for_sell_to_junk_enabled" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.keybindMoveMarkedForSellToJunkEnabled end,
                    setFunc = function(value) FCOISsettings.keybindMoveMarkedForSellToJunkEnabled = value
                    end,
                    default = FCOISdefaultSettings.keybindMoveMarkedForSellToJunkEnabled,
                    width="full",
                },
                --Keybind for "Move item to junk"
                {
                    type = "checkbox",
                    name = locVars["options_keybind_move_item_to_junk_enabled"],
                    tooltip = locVars["options_keybind_move_item_to_junk_enabled" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.keybindMoveItemToJunkEnabled end,
                    setFunc = function(value) FCOISsettings.keybindMoveItemToJunkEnabled = value
                    end,
                    default = FCOISdefaultSettings.keybindMoveItemToJunkEnabled,
                    width="half",
                },
                {
                    type = "checkbox",
                    name = locVars["options_keybind_move_item_to_junk_add_sell_icon"],
                    tooltip = locVars["options_keybind_move_item_to_junk_add_sell_icon" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.keybindMoveItemToJunkAddSellIcon end,
                    setFunc = function(value) FCOISsettings.keybindMoveItemToJunkAddSellIcon = value
                    end,
                    default = FCOISdefaultSettings.keybindMoveItemToJunkAddSellIcon,
                    width="half",
                    disabled = function() return not FCOISsettings.keybindMoveItemToJunkEnabled end,
                },
            },  -- controls keybinds
        },  -- submenu keybinds

        --==============================================================================
        -- MARKINGs
        --==============================================================================
        {
            type = "submenu",
            name = locVars["options_header_marking_options"],
            controls =
            {

                {
                    type = "submenu",
                    name = locVars["options_header_marking_undo"],
                    controls =
                    {
                        {
                            type = "dropdown",
                            name = locVars["options_modifier_key"],
                            tooltip = locVars["options_modifier_key" .. tooltipSuffix],
                            choices = choicesModifierKeys,
                            choicesValues = choicesModifierKeysValues,
                            getFunc = function() return FCOISsettings.contextMenuClearMarkesModifierKey end,
                            setFunc = function(value) FCOISsettings.contextMenuClearMarkesModifierKey = value
                            end,
                            width="half",
                            default = FCOISdefaultSettings.contextMenuClearMarkesModifierKey,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_remove_all_markers_with_shift_rightclick"],
                            tooltip = locVars["options_remove_all_markers_with_shift_rightclick" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.contextMenuClearMarkesByShiftKey end,
                            setFunc = function(value) FCOISsettings.contextMenuClearMarkesByShiftKey = value
                            end,
                            width="half",
                            default = FCOISdefaultSettings.contextMenuClearMarkesByShiftKey,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_undo_use_different_filterpanels"],
                            tooltip = locVars["options_undo_use_different_filterpanels" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.useDifferentUndoFilterPanels end,
                            setFunc = function(value) FCOISsettings.useDifferentUndoFilterPanels = value
                            end,
                            disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
                            width="full",
                            default = FCOISdefaultSettings.useDifferentUndoFilterPanels,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_undo_add_context_menu_entry"],
                            tooltip = locVars["options_undo_add_context_menu_entry" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.addRemoveAllMarkerIconsToItemContextMenu end,
                            setFunc = function(value) FCOISsettings.addRemoveAllMarkerIconsToItemContextMenu = value
                            end,
                            width="full",
                            default = FCOISdefaultSettings.addRemoveAllMarkerIconsToItemContextMenu,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_undo_add_context_menu_entry_tooltip"],
                            tooltip = locVars["options_undo_add_context_menu_entry_tooltip" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.showTooltipAtRestoreLastMarked end,
                            setFunc = function(value) FCOISsettings.showTooltipAtRestoreLastMarked = value
                            end,
                            width="full",
                            disabled = function() return not FCOISsettings.addRemoveAllMarkerIconsToItemContextMenu end,
                            default = FCOISdefaultSettings.showTooltipAtRestoreLastMarked,
                        },
                    },
                },

                --==============================================================================
                --Equipment auto-marking
                {   -- Equipment
                    type = "submenu",
                    name = locVars["options_header_equipment"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_equipment_markall_gear"],
                            tooltip = locVars["options_equipment_markall_gear" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoMarkAllEquipment end,
                            setFunc = function(value) FCOISsettings.autoMarkAllEquipment = value
                            end,
                            default = FCOISdefaultSettings.autoMarkAllEquipment,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_equipment_markall_gear_add_weapons"],
                            tooltip = locVars["options_equipment_markall_gear_add_weapons" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoMarkAllWeapon end,
                            setFunc = function(value) FCOISsettings.autoMarkAllWeapon = value
                            end,
                            disabled = function() return not FCOISsettings.autoMarkAllEquipment end,
                            default = FCOISdefaultSettings.autoMarkAllWeapon,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_equipment_markall_gear_add_jewelry"],
                            tooltip = locVars["options_equipment_markall_gear_add_jewelry" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoMarkAllJewelry end,
                            setFunc = function(value) FCOISsettings.autoMarkAllJewelry = value
                            end,
                            disabled = function() return not FCOISsettings.autoMarkAllEquipment end,
                            default = FCOISdefaultSettings.autoMarkAllJewelry,
                        },
                    }, -- controls equipment auto-marking
                }, -- submenu equipment auto-marking

                --======== ITEM AUTOMATIC MARKING ==============================================
                {
                    type = "submenu",
                    name = locVars["options_header_items"],
                    controls =
                    {
                        {
                            type = "description",
                            text = locVars["options_description_automatic_marks"],
                            --helpUrl = strformat(addonFAQentry, tos(???))
                        },
                        --==============================================================================
                        --Auto-marking bags to scan
                        {
                            type = "submenu",
                            name = locVars["options_bags_to_scan"],
                            controls = {
                                {
                                    type = "description",
                                    text = locVars["options_bags_to_scan_automatic_marks_tt"],
                                },
                                {
                                    type    = "checkbox",
                                    name    = locVars["FCOIS_LibFilters_PanelIds"][LF_INVENTORY],
                                    tooltip = locVars["FCOIS_LibFilters_PanelIds"][LF_INVENTORY],
                                    getFunc = function() return FCOISsettings.autoMarkBagsToScan[BAG_BACKPACK] end,
                                    setFunc = function(value) FCOISsettings.autoMarkBagsToScan[BAG_BACKPACK] = value
                                    end,
                                    default = FCOISdefaultSettings.autoMarkBagsToScan[BAG_BACKPACK],
                                },
                                {
                                    type    = "checkbox",
                                    name    = locVars["FCOIS_LibFilters_PanelIds"][LF_BANK_WITHDRAW],
                                    tooltip = locVars["FCOIS_LibFilters_PanelIds"][LF_BANK_WITHDRAW],
                                    getFunc = function() return FCOISsettings.autoMarkBagsToScan[BAG_BANK] end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkBagsToScan[BAG_BANK] = value
                                        FCOISsettings.autoMarkBagsToScan[BAG_SUBSCRIBER_BANK] = value
                                    end,
                                    default = FCOISdefaultSettings.autoMarkBagsToScan[BAG_BANK],
                                },
                                {
                                    type    = "checkbox",
                                    name    = locVars["FCOIS_LibFilters_PanelIds"][LF_GUILDBANK_WITHDRAW],
                                    tooltip = locVars["FCOIS_LibFilters_PanelIds"][LF_GUILDBANK_WITHDRAW],
                                    getFunc = function() return FCOISsettings.autoMarkBagsToScan[BAG_GUILDBANK] end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkBagsToScan[BAG_GUILDBANK] = value
                                    end,
                                    default = FCOISdefaultSettings.autoMarkBagsToScan[BAG_GUILDBANK],
                                },
                                {
                                    type    = "checkbox",
                                    name    = locVars["FCOIS_LibFilters_PanelIds"][LF_HOUSE_BANK_WITHDRAW],
                                    tooltip = locVars["FCOIS_LibFilters_PanelIds"][LF_HOUSE_BANK_WITHDRAW],
                                    getFunc = function() return FCOISsettings.autoMarkBagsToScan[BAG_HOUSE_BANK_ONE] end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkBagsToScan[BAG_HOUSE_BANK_ONE] = value
                                    end,
                                    default = FCOISdefaultSettings.autoMarkBagsToScan[BAG_HOUSE_BANK_ONE],
                                },
                                {
                                    type    = "orderlistbox",
                                    name    = locVars["options_bags_to_scan_order"],
                                    tooltip = locVars["options_bags_to_scan_order" ..tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkBagsToScanOrder end,
                                    setFunc = function(orderedList)
                                        FCOISsettings.autoMarkBagsToScanOrder = orderedList
                                    end,
                                    minHeight = 100,
                                    maxHeight = 200,
                                    isExtraWide = true,
                                    showPosition = true,
                                    disabled = function() return checkIfAutomaticMarksAreDisabledAtBag() end,
                                    default = FCOISdefaultSettings.autoMarkBagsToScanOrder,
                                },
                                {
                                    type    = "checkbox",
                                    name    = locVars["options_bags_to_scan_chat_output"],
                                    tooltip = locVars["options_bags_to_scan_chat_output" ..tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkBagsChatOutput end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkBagsChatOutput = value
                                    end,
                                    default = FCOISdefaultSettings.autoMarkBagsChatOutput,
                                },
                                {
                                    type = "button",
                                    name = locVars["options_scan_automatic_marks_now"],
                                    tooltip = locVars["options_scan_automatic_marks_now" .. tooltipSuffix],
                                    func = function()
                                        scanInventory(nil, nil, FCOISsettings.autoMarkBagsChatOutput)
                                    end,
                                    isDangerous = false,
                                    disabled = function() return checkIfAutomaticMarksAreDisabledAtBag() end,
                                    width="full",
                                },
                            },
                        },
                        --==============================================================================
                        {  -- Sets
                            type = "submenu",
                            name = locVars["options_enable_auto_mark_sets"],
                            controls =
                            {
                                --==============================================================================
                                -- Set collection marker
                                {
                                    type = "submenu",
                                    name = locVars["options_header_set_collections"],
                                    reference = "FCOItemSaver_Settings_SetCollections_SubMenu",
                                    controls = {
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_sets_collection"],
                                            tooltip = locVars["options_enable_auto_mark_sets_collection" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsItemCollectionBook end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsItemCollectionBook = value
                                                if value == true then
                                                    checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsUnknown")
                                                    checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsKnown")
                                                end
                                            end,
                                            width = "full",
                                            default = FCOISdefaultSettings.autoMarkSetsItemCollectionBook,
                                        },
                                        {
                                            type = 'dropdown',
                                            name = locVars["options_auto_mark_sets_collection_unknown_icon"],
                                            tooltip = locVars["options_auto_mark_sets_collection_unknown_icon" .. tooltipSuffix],
                                            choices = iconsListNone,
                                            choicesValues = iconsListValuesNone,
                                            scrollable = true,
                                            getFunc = function() return FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon
                                            end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon = value
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsUnknown")
                                            end,
                                            reference = "FCOItemSaver_Icon_On_Automatic_SetCollections_UnknownIcon_Dropdown",
                                            disabled = function() return not FCOISsettings.autoMarkSetsItemCollectionBook end,
                                            width = "full",
                                            default = FCOISdefaultSettings.autoMarkSetsItemCollectionBookMissingIcon,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_auto_bind_missing_set_collection_pieces"],
                                            tooltip = locVars["options_auto_bind_missing_set_collection_pieces" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoBindMissingSetCollectionPiecesOnLoot end,
                                            setFunc = function(value)
                                                FCOISsettings.autoBindMissingSetCollectionPiecesOnLoot = value
                                            end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoBindMissingSetCollectionPiecesOnLoot,
                                            disabled = function() return not FCOISsettings.autoMarkSetsItemCollectionBook end,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_auto_bind_missing_set_collection_pieces_markKnown"],
                                            tooltip = locVars["options_auto_bind_missing_set_collection_pieces_markKnown" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoBindMissingSetCollectionPiecesOnLootMarkKnown end,
                                            setFunc = function(value)
                                                FCOISsettings.autoBindMissingSetCollectionPiecesOnLootMarkKnown = value
                                            end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoBindMissingSetCollectionPiecesOnLootMarkKnown,
                                            disabled = function()
                                                return not FCOISsettings.autoMarkSetsItemCollectionBook or not FCOISsettings.autoBindMissingSetCollectionPiecesOnLoot
                                                    or not FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon or FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon == FCOIS_CON_ICON_NONE
                                                    or FCOISsettings.autoMarkSetsItemCollectionBookAddonUsed ~= FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD
                                            end,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_auto_bind_missing_set_collection_pieces_to_chat"],
                                            tooltip = locVars["options_auto_bind_missing_set_collection_pieces_to_chat" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoBindMissingSetCollectionPiecesOnLootToChat end,
                                            setFunc = function(value)
                                                FCOISsettings.autoBindMissingSetCollectionPiecesOnLootToChat = value
                                            end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoBindMissingSetCollectionPiecesOnLootToChat,
                                            disabled = function()
                                                return not FCOISsettings.autoMarkSetsItemCollectionBook or not FCOISsettings.autoBindMissingSetCollectionPiecesOnLoot
                                                        or FCOISsettings.autoMarkSetsItemCollectionBookAddonUsed ~= FCOIS_SETS_COLLECTION_ADDON_ESO_STANDARD end,
                                        },
                                        {
                                            type = 'dropdown',
                                            name = locVars["options_auto_mark_sets_collection_known_icon"],
                                            tooltip = locVars["options_auto_mark_sets_collection_known_icon" .. tooltipSuffix],
                                            choices = iconsListNone,
                                            choicesValues = iconsListValuesNone,
                                            scrollable = true,
                                            getFunc = function() return FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon
                                            end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon = value
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsKnown")
                                            end,
                                            reference = "FCOItemSaver_Icon_On_Automatic_SetCollections_KnownIcon_Dropdown",
                                            disabled = function() return not FCOISsettings.autoMarkSetsItemCollectionBook end,
                                            width = "full",
                                            default = FCOISdefaultSettings.autoMarkSetsItemCollectionBookNonMissingIcon,
                                        },
                                        {
                                            type = 'dropdown',
                                            name = locVars["options_auto_mark_sets_collection_addon"],
                                            tooltip = locVars["options_auto_mark_sets_collection_addon" .. tooltipSuffix],
                                            choices = setCollectionAddonsList,
                                            choicesValues = setCollectionAddonsListValues,
                                            scrollable = true,
                                            getFunc = function() return FCOISsettings.autoMarkSetsItemCollectionBookAddonUsed
                                            end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsItemCollectionBookAddonUsed = value
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsUnknown")
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsKnown")
                                            end,
                                            reference = "FCOItemSaver_On_Automatic_SetCollections_Addon_Dropdown",
                                            disabled = function()
                                                if not FCOISsettings.autoMarkSetsItemCollectionBook then
                                                    return true
                                                else
                                                    if (FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon == FCOIS_CON_ICON_NONE or
                                                        not isIconEnabled[FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon]) and
                                                       (FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon == FCOIS_CON_ICON_NONE or
                                                        not isIconEnabled[FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon]) then
                                                        return true
                                                    end
                                                end
                                                return false
                                            end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoMarkSetsItemCollectionBookAddonUsed,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_only_current_account"],
                                            tooltip = locVars["options_only_current_account" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsItemCollectionBookOnlyCurrentAccount end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsItemCollectionBookOnlyCurrentAccount = value
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsUnknown")
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsKnown")
                                            end,
                                            disabled = function()
                                                return not FCOISsettings.autoMarkSetsItemCollectionBook or FCOISsettings.autoMarkSetsItemCollectionBookAddonUsed ~= FCOIS_SETS_COLLECTION_ADDON_LIBMULTIACCOUNTSETS
                                            end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoMarkSetsItemCollectionBookOnlyCurrentAccount,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_check_all_icons"],
                                            tooltip = locVars["options_enable_auto_mark_check_all_icons" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsItemCollectionBookCheckAllIcons end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsItemCollectionBookCheckAllIcons = value
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsUnknown")
                                                checkAndRunAutomaticSetItemCollectionMarkerApply("setItemCollectionsKnown")
                                            end,
                                            disabled = function() return not FCOISsettings.autoMarkSetsItemCollectionBook end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoMarkSetsItemCollectionBookCheckAllIcons,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_sets_in_chat"],
                                            tooltip = locVars["options_enable_auto_mark_sets_in_chat" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.showSetCollectionMarkedInChat end,
                                            setFunc = function(value)
                                                FCOISsettings.showSetCollectionMarkedInChat = value
                                            end,
                                            disabled = function()
                                                if not FCOISsettings.autoMarkSetsItemCollectionBook then
                                                    return true
                                                else
                                                    if (FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon == FCOIS_CON_ICON_NONE or
                                                        not isIconEnabled[FCOISsettings.autoMarkSetsItemCollectionBookMissingIcon]) and
                                                       (FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon == FCOIS_CON_ICON_NONE or
                                                        not isIconEnabled[FCOISsettings.autoMarkSetsItemCollectionBookNonMissingIcon]) then
                                                        return true
                                                    end
                                                end
                                                return false
                                            end,
                                            width = "half",
                                            default = FCOISdefaultSettings.showSetCollectionMarkedInChat,
                                        },


                                    }, -- controls submenu set collections
                                }, -- submenu set collections
                                --==============================================================================
                                -- Normal sets
                                {
                                    type = "submenu",
                                    name = locVars["options_enable_auto_mark_sets"],
                                    reference = "FCOItemSaver_Settings_NormalSets_SubMenu",
                                    controls = {
                                        --==============================================================================
                                        -- Exclude sets auto-marking
                                        {
                                            type = "submenu",
                                            name = locVars["options_header_exclude_sets"],
                                            reference = "FCOItemSaver_Settings_ExcludeSets_SubMenu",
                                            controls = {

                                                {
                                                    type = "description",
                                                    text = locVars["options_exclude_automark_sets_list_TT"],
                                                },

                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_exclude_automark_sets_list"],
                                                    tooltip = locVars["options_exclude_automark_sets_list" .. tooltipSuffix],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsExcludeSets end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsExcludeSets = value
                                                    end,
                                                    --disabled = function() end,
                                                    width = "half",
                                                    default = FCOISdefaultSettings.autoMarkSetsExcludeSets,
                                                },

                                                --LibShifterBox: Excluded sets --#304
                                                {
                                                    type = "custom",
                                                    reference = (lsb and libShifterBoxes[FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS].name) or "FCOITEMSAVER_LAM_CUSTOM___FCOIS_EXCLUDED_SETS",
                                                    createFunc = function(customControl)
                                                        if not lsb or not FCOIS.libSets then --#304
                                                            d("[FCOIS]ERROR - If you want to use the \'Auto mark excluded sets\' setting you must enable LibSets and LibShiferBox!")
                                                            return
                                                        end

                                                        FCOIS.createLibShifterBox(customControl, FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS)
                                                        --Will be called by the LAM panel automatically upon refresh of controls
                                                        customControl.UpdateDisabled = function(customControl)
                                                            if lsb and libShifterBoxes[FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS] then
                                                                FCOIS.updateLibShifterBoxState(customControl, nil, FCOIS_CON_LIBSHIFTERBOX_EXCLUDESETS)
                                                            end
                                                        end
                                                    end,
                                                    width="full",
                                                    minHeight = 220,
                                                    disabled = function() return FCOIS.libSets == nil end --or not FCOISsettings.autoMarkSetsExcludeSets end, --#304
                                                },

                                            } -- -- Exclude sets auto-marking controls
                                        }, ---- Exclude sets auto-marking submenu

                                        --==============================================================================
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_sets"],
                                            tooltip = locVars["options_enable_auto_mark_sets" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSets end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSets = value
                                                if (FCOISsettings.autoMarkSets == true) then
                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                end
                                            end,
                                            disabled = function() return not isIconEnabled[FCOISsettings.autoMarkSetsIconNr] end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoMarkSets,
                                        },
                                        {
                                            type = 'dropdown',
                                            name = locVars["options_auto_mark_sets_icon"],
                                            tooltip = locVars["options_auto_mark_sets_icon" .. tooltipSuffix],
                                            choices = iconsList,
                                            choicesValues = iconsListValues,
                                            scrollable = true,
                                            getFunc = function() return FCOISsettings.autoMarkSetsIconNr
                                            end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsIconNr = value
                                            end,
                                            reference = "FCOItemSaver_Icon_On_Automatic_Set_Part_Dropdown",
                                            disabled = function() return not FCOISsettings.autoMarkSets or FCOISsettings.autoMarkSetsOnlyTraits end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoMarkSetsIconNr,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_check_all_icons"],
                                            tooltip = locVars["options_enable_auto_mark_check_all_icons" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsCheckAllIcons end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsCheckAllIcons = value
                                                if (FCOISsettings.autoMarkSetsCheckAllIcons == true) then
                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                end
                                            end,
                                            disabled = function() return not FCOISsettings.autoMarkSets or FCOISsettings.autoMarkSetsOnlyTraits end,
                                            width = "full",
                                            default = FCOISdefaultSettings.autoMarkSetsCheckAllIcons,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_sets_all_gear_marker_icons"],
                                            tooltip = locVars["options_enable_auto_mark_sets_all_gear_marker_icons" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsCheckAllGearIcons end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsCheckAllGearIcons = value
                                                if (FCOISsettings.autoMarkSetsCheckAllGearIcons == true) then
                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                end
                                            end,
                                            disabled = function() return FCOISsettings.autoMarkSetsCheckAllIcons or (not isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets) or FCOISsettings.autoMarkSetsOnlyTraits end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoMarkSetsCheckAllGearIcons,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_sets_settracker_icons"],
                                            tooltip = locVars["options_enable_auto_mark_sets_settracker_icons" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsCheckAllSetTrackerIcons end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsCheckAllSetTrackerIcons = value
                                                if (FCOISsettings.autoMarkSetsCheckAllSetTrackerIcons == true) then
                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                end
                                            end,
                                            disabled = function() return not FCOISsettings.autoMarkSets or not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets or FCOISsettings.autoMarkSetsOnlyTraits end,
                                            width = "half",
                                            default = FCOISdefaultSettings.autoMarkSetsCheckAllSetTrackerIcons,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_sets_sell_icon"],
                                            tooltip = locVars["options_enable_auto_mark_sets_sell_icon" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsCheckSellIcons end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsCheckSellIcons = value
                                                if (FCOISsettings.autoMarkSetsCheckSellIcons == true) then
                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                end
                                            end,
                                            disabled = function() return FCOISsettings.autoMarkSetsCheckAllIcons or (not FCOISsettings.autoMarkSets or (not isIconEnabled[FCOIS_CON_ICON_SELL] and not isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE])) or FCOISsettings.autoMarkSetsOnlyTraits end,
                                            width = "full",
                                            default = FCOISdefaultSettings.autoMarkSetsCheckSellIcons,
                                        },
                                        {
                                            type = "checkbox",
                                            name = locVars["options_auto_mark_traits_only"],
                                            tooltip = locVars["options_auto_mark_traits_only" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkSetsOnlyTraits end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkSetsOnlyTraits = value
                                            end,
                                            disabled = function() return not FCOISsettings.autoMarkSets end,
                                            width = "full",
                                            default = FCOISdefaultSettings.autoMarkSetsOnlyTraits,
                                        },

                                        --==============================================================================
                                        -- Sets - Traits
                                        {
                                            type = "submenu",
                                            name = locVars["options_header_traits"],
                                            reference = "FCOItemSaver_Settings_Set_Traits_SubMenu",
                                            controls = {
                                                --==============================================================================
                                                -- Sets - Armor traits
                                                {
                                                    type = "submenu",
                                                    name = GetString(SI_ITEMTYPE45),
                                                    controls = armorTraitControls,
                                                }, -- sub menu armor tarits
                                                --==============================================================================
                                                -- Sets - Jewelry traits
                                                {
                                                    type = "submenu",
                                                    name = GetString(SI_GAMEPADITEMCATEGORY38) .. " " .. GetString(SI_SMITHING_HEADER_TRAIT),
                                                    controls = jewelryTraitControls,
                                                }, -- submenu jewelry traits
                                                --==============================================================================
                                                -- Sets - Weapon traits
                                                {
                                                    type = "submenu",
                                                    name = GetString(SI_ITEMTYPE46),
                                                    controls = weaponTraitControls,
                                                }, -- submenu weapon traits
                                                --==============================================================================
                                                -- Sets - Shield traits
                                                {
                                                    type = "submenu",
                                                    name = GetString(SI_TRADING_HOUSE_BROWSE_ARMOR_TYPE_SHIELD),
                                                    controls = weaponShieldTraitControls,
                                                }, -- submenu weapon traits
                                                --==============================================================================
                                                --Additional automatic-marking: Non-wished options
                                                {
                                                    type = "submenu",
                                                    name = locVars["options_header_non_wished"],
                                                    reference = "FCOItemSaver_Settings_Set_Traits_NonWished_SubMenu",
                                                    controls = {

                                                        {
                                                            type = "checkbox",
                                                            name = locVars["options_enable_auto_mark_sets_non_wished"],
                                                            tooltip = locVars["options_enable_auto_mark_sets_non_wished" .. tooltipSuffix],
                                                            getFunc = function() return FCOISsettings.autoMarkSetsNonWished end,
                                                            setFunc = function(value)
                                                                FCOISsettings.autoMarkSetsNonWished = value
                                                                if (FCOISsettings.autoMarkSetsNonWished == true) then
                                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                end

                                                            end,
                                                            disabled = function() return (not isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not FCOISsettings.autoMarkSets) end,
                                                            width = "half",
                                                            default = FCOISdefaultSettings.autoMarkSetsNonWished,
                                                        },
                                                        {
                                                            type = 'dropdown',
                                                            name = locVars["options_enable_auto_mark_sets_non_wished_icon"],
                                                            tooltip = locVars["options_enable_auto_mark_sets_non_wished_icon" .. tooltipSuffix],
                                                            choices = iconsList,
                                                            choicesValues = iconsListValues,
                                                            scrollable = true,
                                                            getFunc = function() return FCOISsettings.autoMarkSetsNonWishedIconNr
                                                            end,
                                                            setFunc = function(value)
                                                                FCOISsettings.autoMarkSetsNonWishedIconNr = value
                                                            end,
                                                            reference = "FCOItemSaver_Icon_On_Automatic_Non_Wished_Set_Part_Dropdown",
                                                            disabled = function() return (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished) end,
                                                            width = "half",
                                                            default = FCOISdefaultSettings.autoMarkSetsNonWishedIconNr,
                                                        },

                                                        {
                                                            type = "checkbox",
                                                            name = locVars["options_enable_auto_mark_sets_non_wished_char_below_level_50"],
                                                            tooltip = locVars["options_enable_auto_mark_sets_non_wished_char_below_level_50" .. tooltipSuffix],
                                                            getFunc = function() return FCOISsettings.autoMarkSetsNonWishedIfCharBelowLevel end,
                                                            setFunc = function(value)
                                                                FCOISsettings.autoMarkSetsNonWishedIfCharBelowLevel = value
                                                                if (FCOISsettings.autoMarkSetsNonWished == true) then
                                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                end
                                                            end,
                                                            disabled = function()
                                                                return (not FCOISsettings.autoMarkSetsNonWished
                                                                        or (not isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not FCOISsettings.autoMarkSets)) end,
                                                            width = "full",
                                                            default = FCOISdefaultSettings.autoMarkSetsNonWishedIfCharBelowLevel,
                                                        },

                                                        {
                                                            type = 'dropdown',
                                                            name = locVars["options_enable_auto_mark_sets_non_wished_checks"],
                                                            tooltip = locVars["options_enable_auto_mark_sets_non_wished_checks" .. tooltipSuffix],
                                                            choices = nonWishedChecksList,
                                                            choicesValues = nonWishedChecksValuesList,
                                                            --scrollable = true,
                                                            getFunc = function() return FCOISsettings.autoMarkSetsNonWishedChecks end,
                                                            setFunc = function(value)
                                                                FCOISsettings.autoMarkSetsNonWishedChecks = value
                                                                if (FCOISsettings.autoMarkSetsNonWishedChecks == true) then
                                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                end
                                                            end,
                                                            disabled = function()
                                                                return (FCOISsettings.autoMarkSetsNonWishedIfCharBelowLevel and not checkNeededLevel("player", maxLevel))
                                                                        or (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished
                                                                        or not isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not isIconEnabled[FCOIS_CON_ICON_SELL]) end,
                                                            width = "full",
                                                            default = FCOISdefaultSettings.autoMarkSetsNonWishedChecks,
                                                        },

                                                        {
                                                            type = 'dropdown',
                                                            name = locVars["options_enable_auto_mark_sets_non_wished_level"],
                                                            tooltip = locVars["options_enable_auto_mark_sets_non_wished_level" .. tooltipSuffix],
                                                            choices = levelList,
                                                            scrollable = true,
                                                            getFunc = function() return levelList[FCOISsettings.autoMarkSetsNonWishedLevel] end,
                                                            setFunc = function(value)
                                                                for i,v in pairs(levelList) do
                                                                    if v == value then
                                                                        FCOISsettings.autoMarkSetsNonWishedLevel = i
                                                                        if i ~= 1 then
                                                                            scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                        end
                                                                        break
                                                                    end
                                                                end
                                                            end,
                                                            disabled = function()
                                                                return (FCOISsettings.autoMarkSetsNonWishedIfCharBelowLevel and not checkNeededLevel("player", maxLevel))
                                                                        or (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished
                                                                        or not isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not isIconEnabled[FCOIS_CON_ICON_SELL]
                                                                        or (FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_ALL and FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_ANY_OF_THEM
                                                                            and FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_LEVEL)) end,
                                                            width = "full",
                                                            default = levelList[FCOISdefaultSettings.autoMarkSetsNonWishedLevel],
                                                        },

                                                        {
                                                            type = 'dropdown',
                                                            name = locVars["options_enable_auto_mark_sets_non_wished_quality"],
                                                            tooltip = locVars["options_enable_auto_mark_sets_non_wished_quality" .. tooltipSuffix],
                                                            choices = qualityList,
                                                            getFunc = function() return qualityList[FCOISsettings.autoMarkSetsNonWishedQuality] end,
                                                            setFunc = function(value)
                                                                for i,v in pairs(qualityList) do
                                                                    if v == value then
                                                                        FCOISsettings.autoMarkSetsNonWishedQuality = i
                                                                        if i ~= 1 then
                                                                            scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                        end
                                                                        break
                                                                    end
                                                                end
                                                            end,
                                                            disabled = function()
                                                                return (FCOISsettings.autoMarkSetsNonWishedIfCharBelowLevel and not checkNeededLevel("player", maxLevel))
                                                                        or (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished
                                                                        or not isIconEnabled[FCOISsettings.autoMarkSetsNonWishedIconNr] or not isIconEnabled[FCOIS_CON_ICON_SELL]
                                                                        or (FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_ALL and FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_ANY_OF_THEM
                                                                            and FCOISsettings.autoMarkSetsNonWishedChecks~=FCOIS_CON_NON_WISHED_QUALITY)) end,
                                                            width = "full",
                                                            default = qualityList[FCOISdefaultSettings.autoMarkSetsNonWishedQuality],
                                                        },
                                                        {
                                                            type = "checkbox",
                                                            name = locVars["options_enable_auto_mark_sets_non_wished_sell_others"],
                                                            tooltip = locVars["options_enable_auto_mark_sets_non_wished_sell_others" .. tooltipSuffix],
                                                            getFunc = function() return FCOISsettings.autoMarkSetsNonWishedSellOthers end,
                                                            setFunc = function(value)
                                                                FCOISsettings.autoMarkSetsNonWishedSellOthers = value
                                                                if (FCOISsettings.autoMarkSetsNonWishedSellOthers == true) then
                                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                                end
                                                            end,
                                                            disabled = function()
                                                                return (FCOISsettings.autoMarkSetsNonWishedIfCharBelowLevel and not checkNeededLevel("player", maxLevel))
                                                                        or (not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished
                                                                        or not isIconEnabled[FCOIS_CON_ICON_SELL]) end,
                                                            width = "full",
                                                            default = FCOISdefaultSettings.autoMarkSetsNonWishedSellOthers,
                                                        },
                                                    }, -- controls
                                                }, -- submenu non-wished

                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_enable_auto_mark_check_all_icons"],
                                                    tooltip = locVars["options_enable_auto_mark_check_all_icons" .. tooltipSuffix],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsWithTraitCheckAllIcons = value
                                                        if (FCOISsettings.autoMarkSetsWithTraitCheckAllIcons == true) then
                                                            scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end
                                                    end,
                                                    disabled = function() return not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished end,
                                                    width = "full",
                                                    default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckAllIcons,
                                                },
                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_enable_auto_mark_sets_all_gear_marker_icons"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_all_gear_marker_icons" .. tooltipSuffix],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllGearIcons end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsWithTraitCheckAllGearIcons = value
                                                        if (FCOISsettings.autoMarkSetsWithTraitCheckAllGearIcons == true) then
                                                            scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end
                                                    end,
                                                    disabled = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons or (not isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets or not FCOISsettings.autoMarkSetsNonWished) end,
                                                    width = "half",
                                                    default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckAllGearIcons,
                                                },
                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_enable_auto_mark_sets_settracker_icons"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_settracker_icons" .. tooltipSuffix],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons = value
                                                        if (FCOISsettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons == true) then
                                                            scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end
                                                    end,
                                                    disabled = function() return not FCOISsettings.autoMarkSets or not FCOIS.otherAddons.SetTracker.isActive or not FCOISsettings.autoMarkSetTrackerSets or not FCOISsettings.autoMarkSetsNonWished end,
                                                    width = "half",
                                                    default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckAllSetTrackerIcons,
                                                },
                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_enable_auto_mark_sets_sell_icon"],
                                                    tooltip = locVars["options_enable_auto_mark_sets_sell_icon" .. tooltipSuffix],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsWithTraitCheckSellIcons end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsWithTraitCheckSellIcons = value
                                                        if (FCOISsettings.autoMarkSetsWithTraitCheckSellIcons == true) then
                                                            scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end
                                                    end,
                                                    disabled = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons or (not FCOISsettings.autoMarkSets or (not isIconEnabled[FCOIS_CON_ICON_SELL] and not isIconEnabled[FCOIS_CON_ICON_SELL_AT_GUILDSTORE])) or not FCOISsettings.autoMarkSetsNonWished end,
                                                    width = "full",
                                                    default = FCOISdefaultSettings.autoMarkSetsWithTraitCheckSellIcons,
                                                },
                                                {
                                                    type = "checkbox",
                                                    name = locVars["options_auto_mark_traits_with_set_too"],
                                                    tooltip = locVars["options_auto_mark_traits_with_set_too" .. tooltipSuffix],
                                                    getFunc = function() return FCOISsettings.autoMarkSetsWithTraitIfAutoSetMarked end,
                                                    setFunc = function(value)
                                                        FCOISsettings.autoMarkSetsWithTraitIfAutoSetMarked = value
                                                        if (FCOISsettings.autoMarkSetsWithTraitIfAutoSetMarked == true) then
                                                            scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                        end
                                                    end,
                                                    width = "half",
                                                    disabled = function() return FCOISsettings.autoMarkSetsWithTraitCheckAllIcons or (not isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets) end,
                                                    default = FCOISdefaultSettings.autoMarkSetsWithTraitIfAutoSetMarked,
                                                },

                                            }, --Sets traits controls
                                        }, --Sets traits submenu

                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_sets_in_chat"],
                                            tooltip = locVars["options_enable_auto_mark_sets_in_chat" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.showSetsInChat end,
                                            setFunc = function(value)
                                                FCOISsettings.showSetsInChat = value
                                            end,
                                            disabled = function() return not isIconEnabled[FCOISsettings.autoMarkSetsIconNr] or not FCOISsettings.autoMarkSets end,
                                            width = "half",
                                            default = FCOISdefaultSettings.showSetsInChat,
                                        },


                                    }, -- normal sets controls

                                }, -- normal sets submenu


                                --==============================================================================
                                -- LibSets Set Search Favorites - #301
                                --[[
                                {
                                    type = "submenu",
                                    name = locVars["options_enable_auto_mark_LibSetsSetSearchFavorites"],
                                    reference = "FCOItemSaver_Settings_LibSetsSetSearchFavoriteCategories_SubMenu",
                                    controls = {

                                        {
                                            type = "checkbox",
                                            name = locVars["options_enable_auto_mark_LibSetsSetSearchFavorites"],
                                            tooltip = locVars["options_enable_auto_mark_LibSetsSetSearchFavorites" .. tooltipSuffix],
                                            getFunc = function() return FCOISsettings.autoMarkLibSetsSetSearchFavorites end,
                                            setFunc = function(value)
                                                FCOISsettings.autoMarkLibSetsSetSearchFavorites = value
                                                if (FCOISsettings.autoMarkLibSetsSetSearchFavorites == true) then
                                                    --scanInventoryItemsForAutomaticMarks(nil, nil, "sets", false)
                                                end
                                            end,
                                            disabled = function() return FCOIS.libSets == nil end,
                                            width = "full",
                                            default = FCOISdefaultSettings.autoMarkLibSetsSetSearchFavorites,
                                        },

                                        { -- Begin Submenu filter button position data
                                            type = "submenu",
                                            name = locVars["options_LibSetsSetSearchFavorites_Mapping"],
                                            controls = libSetsSetSearchFavoritesSubMenu,
                                        },

                                    }, -- -- LibSets Set Search Favorites controls
                                }, -- -- LibSets Set Search Favorites submenu
                                ]]


                                --==============================================================================
                                -- SetTracker auto-marking
                                {
                                    type = "submenu",
                                    name = locVars["options_header_settracker"],
                                    reference = "FCOItemSaver_Settings_SetTracker_SubMenu",
                                    controls = SetTrackerSubmenuControls, -- dynamically created dropdown controls for each SetTracker tracking state/index
                                    disabled = function() return not FCOIS.otherAddons.SetTracker.isActive end --#307

                                },

                                --==============================================================================
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_sets_already_bound"],
                                    tooltip = locVars["options_enable_auto_mark_sets_already_bound" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showBoundItemMarker end,
                                    setFunc = function(value)
                                        FCOISsettings.showBoundItemMarker = value
                                    end,
                                    width = "half",
                                    default = FCOISdefaultSettings.showBoundItemMarker,
                                },

                            } -- controls sets
                        }, -- submenu sets

                        --==============================================================================
                        --[[
                        {  -- Non sets armor, weapon, jewelry
                            type = "submenu",
                            name = locVars["options_enable_auto_mark_non_sets"],
                            controls =
                            {
--autoMarkArmorWeaponJewelry
                            },

                        },
                        ]]

                        --==============================================================================
                        {   -- Ornate
                            type = "submenu",
                            name = GetString(SI_ITEMTRAITTYPE10),
                            controls =
                            {
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_ornate_items"],
                                    tooltip = locVars["options_enable_auto_mark_ornate_items" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkOrnate end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkOrnate = value
                                        if (FCOISsettings.autoMarkOrnate == true) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "ornate", false)
                                        end
                                    end,
                                    width = "half",
                                    disabled = function() return not isIconEnabled[FCOIS_CON_ICON_SELL] end,
                                    default = FCOISdefaultSettings.autoMarkOrnate,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_ornate_items_in_chat"],
                                    tooltip = locVars["options_enable_auto_mark_ornate_items_in_chat" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showOrnateItemsInChat end,
                                    setFunc = function(value)
                                        FCOISsettings.showOrnateItemsInChat = value
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkOrnate or not isIconEnabled[FCOIS_CON_ICON_SELL] end,
                                    width = "half",
                                    default = FCOISdefaultSettings.showOrnateItemsInChat,
                                },
                            } -- controls ornate
                        }, -- submenu ornate
                        --==============================================================================
                        {   -- Intricate
                            type = "submenu",
                            name = GetString(SI_ITEMTRAITTYPE9),
                            controls =
                            {
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_intricate_items"],
                                    tooltip = locVars["options_enable_auto_mark_intricate_items" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkIntricate end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkIntricate = value
                                        if (FCOISsettings.autoMarkIntricate == true) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "intricate", false)
                                        end
                                    end,
                                    width = "half",
                                    disabled = function() return not isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
                                    default = FCOISdefaultSettings.autoMarkIntricate,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_intricate_items_in_chat"],
                                    tooltip = locVars["options_enable_auto_mark_intricate_items_in_chat" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showIntricateItemsInChat end,
                                    setFunc = function(value)
                                        FCOISsettings.showIntricateItemsInChat = value
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkIntricate or not isIconEnabled[FCOIS_CON_ICON_INTRICATE] end,
                                    width = "half",
                                    default = FCOISdefaultSettings.showIntricateItemsInChat,
                                },
                            } -- controls intrictae
                        }, -- submenu intrictae
                        --==============================================================================
                        {   -- Research
                            type = "submenu",
                            name = GetString(SI_SMITHING_TAB_RESEARCH),
                            controls =
                            {
                                {
                                    type = 'dropdown',
                                    name = locVars["options_auto_mark_addon"],
                                    tooltip = zo_strf(locVars["options_auto_mark_addon" .. tooltipSuffix], GetString(SI_SMITHING_TAB_RESEARCH)),
                                    choices = researchAddonsList,
                                    choicesValues = researchAddonsListValues,
                                    --scrollable = true,
                                    getFunc = function() return FCOISsettings.researchAddonUsed
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.researchAddonUsed = value

                                    end,
                                    --disabled = function() return not FCOISsettings.autoMarkResearch end,
                                    width = "half",
                                    default = FCOISdefaultSettings.researchAddonUsed,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_research_items"],
                                    tooltip = locVars["options_enable_auto_mark_research_items" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkResearch end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkResearch = value
                                        if (FCOISsettings.autoMarkResearch == true and checkIfResearchAddonUsed() and checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed)) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "research", false)
                                        end
                                    end,
                                    disabled = function() return not checkIfResearchAddonUsed() or not checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed) or not isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
                                    warning = locVars["options_enable_auto_mark_research_items_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkResearch,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_logged_in_char"],
                                    tooltip = locVars["options_logged_in_char" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkResearchOnlyLoggedInChar end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkResearchOnlyLoggedInChar = value
                                        if (FCOISsettings.autoMarkResearch == true and FCOISsettings.autoMarkResearchOnlyLoggedInChar == true and checkIfResearchAddonUsed() and checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed)) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "research", false)
                                        end
                                    end,
                                    disabled = function() return not checkIfResearchAddonUsed() or FCOISsettings.researchAddonUsed == FCOIS_RESEARCH_ADDON_ESO_STANDARD or FCOISsettings.researchAddonUsed == FCOIS_RESEARCH_ADDON_RESEARCHASSISTANT or not checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed) or not isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
                                    warning = locVars["options_enable_auto_mark_research_items_hint_logged_in_char"],
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkResearchOnlyLoggedInChar,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_check_all_icons"],
                                    tooltip = locVars["options_enable_auto_mark_check_all_icons" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkResearchCheckAllIcons end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkResearchCheckAllIcons = value
                                    end,
                                    width = "half",
                                    disabled = function() return not checkIfResearchAddonUsed() or not checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed) or not isIconEnabled[FCOIS_CON_ICON_RESEARCH] end,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_research_items_in_chat"],
                                    tooltip = locVars["options_enable_auto_mark_research_items_in_chat" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showResearchItemsInChat end,
                                    setFunc = function(value)
                                        FCOISsettings.showResearchItemsInChat = value
                                    end,
                                    disabled = function() return not checkIfResearchAddonUsed() or not checkIfChosenResearchAddonActive(FCOISsettings.researchAddonUsed) or not isIconEnabled[FCOIS_CON_ICON_RESEARCH] or not FCOISsettings.autoMarkResearch end,
                                    warning = locVars["options_enable_auto_mark_research_items_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.showResearchItemsInChat,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_wasted_research_scrolls"],
                                    tooltip = locVars["options_enable_auto_mark_wasted_research_scrolls" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkWastedResearchScrolls end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkWastedResearchScrolls = value
                                        if FCOISsettings.autoMarkWastedResearchScrolls then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "researchScrolls", false)
                                        end
                                    end,
                                    disabled = function() return (DetailedResearchScrolls == nil or DetailedResearchScrolls.GetWarningLine == nil) or not isIconEnabled[FCOIS_CON_ICON_LOCK] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.autoMarkWastedResearchScrolls,
                                },
                            } -- controls research
                        }, -- submenu research

                        --==============================================================================
                        {   -- Recipes
                            type = "submenu",
                            name = GetString(SI_ITEMTYPE29),
                            controls =
                            {
                                {
                                    type = 'dropdown',
                                    name = locVars["options_auto_mark_addon"],
                                    tooltip = zo_strf(locVars["options_auto_mark_addon" .. tooltipSuffix], GetString(SI_ITEMTYPE29)),
                                    choices = recipeAddonsList,
                                    choicesValues = recipeAddonsListValues,
                                    --scrollable = true,
                                    getFunc = function() return FCOISsettings.recipeAddonUsed
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.recipeAddonUsed = value

                                    end,
                                    --disabled = function() return not FCOISsettings.autoMarkRecipes end,
                                    width = "full",
                                    default = FCOISdefaultSettings.recipeAddonUsed,
                                    warning = locVars["options_enable_auto_mark_recipes_hint"],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_recipes"],
                                    tooltip = locVars["options_enable_auto_mark_recipes" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkRecipes end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkRecipes = value
                                        if (FCOISsettings.autoMarkRecipes == true and checkIfRecipeAddonUsed() and checkIfChosenRecipeAddonActive(FCOISsettings.recipeAddonUsed)) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "recipes", false)
                                        end
                                    end,
                                    disabled = function() return not isRecipeAutoMarkDoable(false, false, false) end,
                                    warning = locVars["options_enable_auto_mark_recipes_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkRecipes,
                                },
                                {
                                    type = 'dropdown',
                                    name = strformat(locVars["options_auto_mark_recipes_icon"], GetString(SI_INPUT_LANGUAGE_UNKNOWN)),
                                    tooltip = strformat(locVars["options_auto_mark_recipes_icon" .. tooltipSuffix], GetString(SI_INPUT_LANGUAGE_UNKNOWN)),
                                    --choices = iconsList,
                                    choices = iconsListRecipe,
                                    --choicesValues = iconsListValues,
                                    choicesValues = iconsListValuesRecipe,
                                    scrollable = true,
                                    getFunc = function() return FCOISsettings.autoMarkRecipesIconNr
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkRecipesIconNr = value
                                    end,
                                    reference = "FCOItemSaver_Icon_On_Automatic_Recipe_Dropdown",
                                    disabled = function() return not isRecipeAutoMarkDoable(true, false, false) end,
                                    width = "half",
                                    default = iconsListRecipe[FCOISdefaultSettings.autoMarkRecipesIconNr],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_recipes_this_char"],
                                    tooltip = locVars["options_auto_mark_recipes_this_char" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkRecipesOnlyThisChar end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkRecipesOnlyThisChar = value
                                        if (FCOISsettings.autoMarkRecipes == true and checkIfRecipeAddonUsed()) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "recipes", false)
                                        end
                                    end,
                                    disabled = function() return not isRecipeAutoMarkDoable(false, false, false) end,
                                    width = "full",
                                    default = FCOISdefaultSettings.autoMarkRecipesOnlyThisChar,
                                    warning = locVars["options_auto_mark_recipes_this_char" .. tooltipSuffix],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_known_recipes"],
                                    tooltip = locVars["options_enable_auto_mark_known_recipes" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkKnownRecipes end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkKnownRecipes = value
                                        if (FCOISsettings.autoMarkKnownRecipes == true and checkIfRecipeAddonUsed()) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "knownRecipes", false)
                                        end
                                    end,
                                    disabled = function() return not isRecipeAutoMarkDoable(false, false, false) end,
                                    warning = locVars["options_enable_auto_mark_recipes_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkKnownRecipes,
                                },
                                {
                                    type = 'dropdown',
                                    name = strformat(locVars["options_auto_mark_recipes_icon"], locVars["options_known"]),
                                    tooltip = strformat(locVars["options_auto_mark_recipes_icon"], locVars["options_known"]),
                                    --choices = iconsList,
                                    choices = iconsListRecipe,
                                    --choicesValues = iconsListValues,
                                    choicesValues = iconsListValuesRecipe,
                                    scrollable = true,
                                    getFunc = function() return FCOISsettings.autoMarkKnownRecipesIconNr
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkKnownRecipesIconNr = value
                                    end,
                                    reference = "FCOItemSaver_Icon_On_Automatic_Known_Recipe_Dropdown",
                                    disabled = function() return not FCOISsettings.autoMarkKnownRecipes or not isRecipeAutoMarkDoable(false, false, false) end,
                                    width = "half",
                                    default = iconsListRecipe[FCOISdefaultSettings.autoMarkKnownRecipesIconNr],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_recipes_in_chat"],
                                    tooltip = locVars["options_enable_auto_mark_recipes_in_chat" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showRecipesInChat end,
                                    setFunc = function(value)
                                        FCOISsettings.showRecipesInChat = value
                                    end,
                                    disabled = function() return not isRecipeAutoMarkDoable(true, true, false) end,
                                    warning = locVars["options_enable_auto_mark_recipes_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.showRecipesInChat,
                                },
                            } -- controls recipes
                        }, -- submenu recipes

                        --==============================================================================
                        {   -- Motifs --#308
                            type = "submenu",
                            name = GetString(SI_ITEMTYPE8),
                            controls =
                            {
                                {
                                    type = 'dropdown',
                                    name = locVars["options_auto_mark_addon"],
                                    tooltip = zo_strf(locVars["options_auto_mark_addon" .. tooltipSuffix], GetString(SI_ITEMTYPE8)),
                                    choices = motifsAddonsList,
                                    choicesValues = motifsAddonsListValues,
                                    --scrollable = true,
                                    getFunc = function() return FCOISsettings.motifsAddonUsed
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.motifsAddonUsed = value

                                    end,
                                    --disabled = function() return not FCOISsettings.autoMarkRecipes end,
                                    width = "full",
                                    default = FCOISdefaultSettings.motifsAddonUsed,
                                    warning = locVars["options_enable_auto_mark_motifs_hint"],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_motifs"],
                                    tooltip = locVars["options_enable_auto_mark_motifs" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkMotifs end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkMotifs = value
                                        if (FCOISsettings.autoMarkMotifs == true and checkIfMotifsAddonUsed() and checkIfChosenMotifsAddonActive(FCOISsettings.motifsAddonUsed)) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "motifs", false)
                                        end
                                    end,
                                    disabled = function() return not isMotifsAutoMarkDoable(false, false, false) end,
                                    warning = locVars["options_enable_auto_mark_motifs_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkMotifs,
                                },
                                {
                                    type = 'dropdown',
                                    name = strformat(locVars["options_auto_mark_motifs_icon"], GetString(SI_INPUT_LANGUAGE_UNKNOWN)),
                                    tooltip = strformat(locVars["options_auto_mark_motifs_icon" .. tooltipSuffix], GetString(SI_INPUT_LANGUAGE_UNKNOWN)),
                                    --choices = iconsList,
                                    choices = iconsListRecipe,
                                    --choicesValues = iconsListValues,
                                    choicesValues = iconsListValuesRecipe,
                                    scrollable = true,
                                    getFunc = function() return FCOISsettings.autoMarkMotifsIconNr
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkMotifsIconNr = value
                                    end,
                                    reference = "FCOItemSaver_Icon_On_Automatic_Motif_Dropdown",
                                    disabled = function() return not isMotifsAutoMarkDoable(true, false, false) end,
                                    width = "half",
                                    default = iconsListRecipe[FCOISdefaultSettings.autoMarkMotifsIconNr],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_motifs_this_char"],
                                    tooltip = locVars["options_auto_mark_motifs_this_char" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkMotifsOnlyThisChar end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkMotifsOnlyThisChar = value
                                        if (FCOISsettings.autoMarkMotifs == true and checkIfMotifsAddonUsed()) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "recipes", false)
                                        end
                                    end,
                                    disabled = function() return not isMotifsAutoMarkDoable(false, false, false) end,
                                    width = "full",
                                    default = FCOISdefaultSettings.autoMarkMotifsOnlyThisChar,
                                    warning = locVars["options_auto_mark_motifs_this_char" .. tooltipSuffix],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_known_motifs"],
                                    tooltip = locVars["options_enable_auto_mark_known_motifs" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkKnownMotifs end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkKnownMotifs = value
                                        if (FCOISsettings.autoMarkKnownMotifs == true and checkIfMotifsAddonUsed()) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "knownRecipes", false)
                                        end
                                    end,
                                    disabled = function() return not isMotifsAutoMarkDoable(false, false, false) end,
                                    warning = locVars["options_enable_auto_mark_motifs_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkKnownMotifs,
                                },
                                {
                                    type = 'dropdown',
                                    name = strformat(locVars["options_auto_mark_motifs_icon"], locVars["options_known"]),
                                    tooltip = strformat(locVars["options_auto_mark_motifs_icon"], locVars["options_known"]),
                                    --choices = iconsList,
                                    choices = iconsListRecipe,
                                    --choicesValues = iconsListValues,
                                    choicesValues = iconsListValuesRecipe,
                                    scrollable = true,
                                    getFunc = function() return FCOISsettings.autoMarkKnownMotifsIconNr
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkKnownMotifsIconNr = value
                                    end,
                                    reference = "FCOItemSaver_Icon_On_Automatic_Known_Motif_Dropdown",
                                    disabled = function() return not FCOISsettings.autoMarkKnownMotifs or not isMotifsAutoMarkDoable(false, false, false) end,
                                    width = "half",
                                    default = iconsListRecipe[FCOISdefaultSettings.autoMarkKnownMotifsIconNr],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_motifs_in_chat"],
                                    tooltip = locVars["options_enable_auto_mark_motifs_in_chat" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showMotifsInChat end,
                                    setFunc = function(value)
                                        FCOISsettings.showMotifsInChat = value
                                    end,
                                    disabled = function() return not isMotifsAutoMarkDoable(true, true, false) end,
                                    warning = locVars["options_enable_auto_mark_motifs_hint"],
                                    width = "half",
                                    default = FCOISdefaultSettings.showMotifsInChat,
                                },
                            } -- controls motifs
                        }, -- submenu motifs

                        --==============================================================================
                        {   -- Quality
                            type = "submenu",
                            name = locVars["options_enable_auto_mark_quality_items"],
                            controls =
                            {
                                {
                                    type = 'dropdown',
                                    name = locVars["options_enable_auto_mark_quality_items"],
                                    tooltip = locVars["options_enable_auto_mark_quality_items" .. tooltipSuffix],
                                    choices = qualityList,
                                    getFunc = function() return qualityList[FCOISsettings.autoMarkQuality] end,
                                    setFunc = function(value)
                                        for i,v in pairs(qualityList) do
                                            if v == value then
                                                FCOISsettings.autoMarkQuality = i
                                                if i ~= 1 then
                                                    scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
                                                end
                                                break
                                            end
                                        end
                                    end,
                                    width = "half",
                                    default = qualityList[FCOISdefaultSettings.autoMarkQuality],
                                },
                                {
                                    type = 'dropdown',
                                    name = locVars["options_auto_mark_quality_icon"],
                                    tooltip = locVars["options_auto_mark_quality_icon" .. tooltipSuffix],
                                    choices = iconsList,
                                    choicesValues = iconsListValues,
                                    scrollable = true,
                                    getFunc = function() return FCOISsettings.autoMarkQualityIconNr
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkQualityIconNr = value
                                    end,
                                    reference = "FCOItemSaver_Icon_On_Automatic_Quality_Dropdown",
                                    disabled = function() return FCOISsettings.autoMarkQuality == 1 end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkQualityIconNr,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_higher_quality_items"],
                                    tooltip = locVars["options_enable_auto_mark_higher_quality_items" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkHigherQuality end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkHigherQuality = value
                                        if FCOISsettings.autoMarkHigherQuality and FCOISsettings.autoMarkQuality ~= 1 and FCOISsettings.autoMarkQuality ~= ITEM_DISPLAY_QUALITY_LEGENDARY then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
                                        end
                                    end,
                                    disabled = function() return FCOISsettings.autoMarkQuality == 1 or not isIconEnabled[FCOISsettings.autoMarkQualityIconNr] or FCOISsettings.autoMarkQuality == ITEM_DISPLAY_QUALITY_LEGENDARY end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkHigherQuality,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_quality_icon_no_armor"],
                                    tooltip = locVars["options_auto_mark_quality_icon_no_armor" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkHigherQualityExcludeArmor end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkHigherQualityExcludeArmor = value
                                        if FCOISsettings.autoMarkHigherQuality and FCOISsettings.autoMarkQuality ~= 1 then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
                                        end
                                    end,
                                    disabled = function() return FCOISsettings.autoMarkQuality == 1 or not isIconEnabled[FCOISsettings.autoMarkQualityIconNr] end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkHigherQualityExcludeArmor,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_check_all_icons"],
                                    tooltip = locVars["options_enable_auto_mark_check_all_icons" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkQualityCheckAllIcons end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkQualityCheckAllIcons = value
                                        if (FCOISsettings.autoMarkQualityCheckAllIcons == true) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "quality", false)
                                        end
                                    end,
                                    disabled = function() return FCOISsettings.autoMarkQuality == 1 or not isIconEnabled[FCOISsettings.autoMarkQualityIconNr] end,
                                    width = "half",
                                    default = FCOISsettings.autoMarkQualityCheckAllIcons,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_quality_items_in_chat"],
                                    tooltip = locVars["options_enable_auto_mark_quality_items_in_chat" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showQualityItemsInChat end,
                                    setFunc = function(value)
                                        FCOISsettings.showQualityItemsInChat = value
                                    end,
                                    disabled = function() return FCOISsettings.autoMarkQuality == 1 or not isIconEnabled[FCOISsettings.autoMarkQualityIconNr] end,
                                    width = "half",
                                    default = FCOISdefaultSettings.showQualityItemsInChat,
                                },
                            } -- controls quality
                        }, -- submenu quality

                        --==============================================================================
                        {   --Crafted
                            type = "submenu",
                            name = GetString(SI_ITEM_FORMAT_STR_CRAFTED),
                            controls =
                            {
                                {   --Crafted "Writs"
                                    type = "submenu",
                                    name = "Writ Creator",
                                    controls = WritCreatorSubmenuControls,
                                    disabled = function() return not FCOIS.otherAddons.LazyWritCreatorActive or WritCreater == nil end,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items"],
                                    tooltip = locVars["options_auto_mark_crafted_items" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkCraftedItems end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkCraftedItems = value
                                    end,
                                    disabled = function() return not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkCraftedItems,
                                },
                                {
                                    type = 'dropdown',
                                    name = locVars["options_auto_mark_crafted_items_icon"],
                                    tooltip = locVars["options_auto_mark_crafted_items_icon" .. tooltipSuffix],
                                    choices = iconsList,
                                    choicesValues = iconsListValues,
                                    scrollable = true,
                                    getFunc = function() return FCOISsettings.autoMarkCraftedItemsIconNr
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkCraftedItemsIconNr = value
                                        --Check if the icon needs to get the setting to skip the research check enabled
                                        if value ~= nil then
                                            setDynamicIconAntiResearchCheck(value, true)
                                        end
                                    end,
                                    reference = "FCOItemSaver_Icon_On_Automatic_Crafted_Items_Dropdown",
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkCraftedItemsIconNr,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_sets"],
                                    tooltip = locVars["options_auto_mark_crafted_items_sets" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkCraftedItemsSets end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkCraftedItemsSets = value
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.autoMarkCraftedItemsSets,
                                },

                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_panel_alchemy"],
                                    tooltip = locVars["options_auto_mark_crafted_items_panel_alchemy" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ALCHEMY] end,
                                    setFunc = function(value)
                                        FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ALCHEMY] = value
                                        rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_ALCHEMY)
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ALCHEMY],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_panel_blacksmithing"],
                                    tooltip = locVars["options_auto_mark_crafted_items_panel_blacksmithing" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_BLACKSMITHING] end,
                                    setFunc = function(value)
                                        FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_BLACKSMITHING] = value
                                        rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_BLACKSMITHING)
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_BLACKSMITHING],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_panel_clothier"],
                                    tooltip = locVars["options_auto_mark_crafted_items_panel_clothier" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_CLOTHIER] end,
                                    setFunc = function(value)
                                        FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_CLOTHIER] = value
                                        rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_CLOTHIER)
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_CLOTHIER],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_panel_enchanting"],
                                    tooltip = locVars["options_auto_mark_crafted_items_panel_enchanting" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ENCHANTING] end,
                                    setFunc = function(value)
                                        FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ENCHANTING] = value
                                        rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_ENCHANTING)
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_ENCHANTING],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_panel_provisioning"],
                                    tooltip = locVars["options_auto_mark_crafted_items_panel_provisioning" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_PROVISIONING] end,
                                    setFunc = function(value)
                                        FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_PROVISIONING] = value
                                        rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_PROVISIONING)
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_PROVISIONING],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_panel_woodworking"],
                                    tooltip = locVars["options_auto_mark_crafted_items_panel_woodworking" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_WOODWORKING] end,
                                    setFunc = function(value)
                                        FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_WOODWORKING] = value
                                        rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_WOODWORKING)
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_WOODWORKING],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_auto_mark_crafted_items_panel_jewelry"],
                                    tooltip = locVars["options_auto_mark_crafted_items_panel_jewelry" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_JEWELRYCRAFTING] end,
                                    setFunc = function(value)
                                        FCOISsettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_JEWELRYCRAFTING] = value
                                        rebuildAllowedCraftSkillsForCraftedMarking(CRAFTING_TYPE_JEWELRYCRAFTING)
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkCraftedItems or not isIconEnabled[FCOISsettings.autoMarkCraftedItemsIconNr] end,
                                    width = "full",
                                    default = FCOISdefaultSettings.allowedCraftSkillsForCraftedMarking[CRAFTING_TYPE_JEWELRYCRAFTING],
                                },
                            } -- controls crafted items
                        }, -- submenu crafted items

                        --==============================================================================
                        {   -- New
                            type = "submenu",
                            name = locVars["options_header_items_mark_new"],
                            controls =
                            {
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_new_items"],
                                    tooltip = locVars["options_enable_auto_mark_new_items" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkNewItems end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkNewItems = value
                                        if (FCOISsettings.autoMarkNewItems == true) then
                                            scanInventoryItemsForAutomaticMarks(nil, nil, "new", false)
                                        end
                                    end,
                                    disabled = function() return not isIconEnabled[FCOISsettings.autoMarkNewIconNr] end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkNewItems,
                                },
                                {
                                    type = 'dropdown',
                                    name = locVars["options_auto_mark_new_items_icon"],
                                    tooltip = locVars["options_auto_mark_new_items_icon" .. tooltipSuffix],
                                    choices = iconsList,
                                    choicesValues = iconsListValues,
                                    scrollable = true,
                                    getFunc = function() return FCOISsettings.autoMarkNewIconNr
                                    end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkNewIconNr = value
                                    end,
                                    reference = "FCOItemSaver_Icon_On_Automatic_New_Item_Dropdown",
                                    disabled = function() return not FCOISsettings.autoMarkNewItems end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkNewIconNr,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_auto_mark_check_all_icons"],
                                    tooltip = locVars["options_enable_auto_mark_check_all_icons" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoMarkNewItemsCheckOthers end,
                                    setFunc = function(value)
                                        FCOISsettings.autoMarkNewItemsCheckOthers = value
                                    end,
                                    disabled = function() return not FCOISsettings.autoMarkNewItems or not isIconEnabled[FCOISsettings.autoMarkNewIconNr] end,
                                    width = "half",
                                    default = FCOISdefaultSettings.autoMarkNewItemsCheckOthers,
                                },
                            } -- controls new
                        }, -- submenu new

                        --==============================================================================
                        --Auto-marking "Item Cooldown Tracker"
                        {
                            type = "submenu",
                            name = locVars["options_automark_itemcooldowntracker_header"],
                            controls = ItemCooldownTrackerSubmenuControls,
                            disabled = function() return not FCOIS.otherAddons.ItemCooldownTrackerActive end --#306
                        },


                    } -- controls marking
                }, -- submenu marking


                --==============================================================================
                -- ITEM AUOMATIC MARKING - PREVENT
                --==============================================================================
                -- Do not mark automatically again, if ..
                {
                    type = "submenu",
                    name = locVars["options_header_items_prevent"],
                    controls =
                    {
                        -- Sell
                        {
                            type = "checkbox",
                            name = locVars["options_prevent_auto_marking_sell"],
                            tooltip = locVars["options_prevent_auto_marking_sell" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoMarkPreventIfMarkedForSell end,
                            setFunc = function(value)
                                FCOISsettings.autoMarkPreventIfMarkedForSell = value
                            end,
                            width = "full",
                            default = FCOISdefaultSettings.autoMarkPreventIfMarkedForSell,
                        },
                        -- Sell at guild store
                        {
                            type = "checkbox",
                            name = locVars["options_prevent_auto_marking_sell_guild_store"],
                            tooltip = locVars["options_prevent_auto_marking_sell_guild_store" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoMarkPreventIfMarkedForSellAtGuildStore end,
                            setFunc = function(value)
                                FCOISsettings.autoMarkPreventIfMarkedForSellAtGuildStore = value
                            end,
                            width = "full",
                            default = FCOISdefaultSettings.autoMarkPreventIfMarkedForSellAtGuildStore,
                        },
                        -- Deconstruction
                        {
                            type = "checkbox",
                            name = locVars["options_prevent_auto_marking_deconstruction"],
                            tooltip = locVars["options_prevent_auto_marking_deconstruction" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoMarkPreventIfMarkedForDeconstruction end,
                            setFunc = function(value)
                                FCOISsettings.autoMarkPreventIfMarkedForDeconstruction = value
                            end,
                            width = "full",
                            default = FCOISdefaultSettings.autoMarkPreventIfMarkedForDeconstruction,
                        },

                    },

                },

                --==============================================================================
                -- ITEM AUTOMATIC DE-MARKING
                --==============================================================================
                {
                    type = "submenu",
                    name = locVars["options_header_items_demark"],
                    controls =
                    {
                        {
                            type = "submenu",
                            name = locVars["options_header_items_demark_all"],
                            controls =
                            {
                                {
                                    type = "checkbox",
                                    name = locVars["options_demark_all_selling"],
                                    tooltip = locVars["options_demark_all_selling" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoDeMarkSell end,
                                    setFunc = function(value) FCOISsettings.autoDeMarkSell = value
                                    end,
                                    default = FCOISdefaultSettings.autoDeMarkSell,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_demark_all_selling_guild_store"],
                                    tooltip = locVars["options_demark_all_selling_guild_store" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoDeMarkSellInGuildStore end,
                                    setFunc = function(value) FCOISsettings.autoDeMarkSellInGuildStore = value
                                    end,
                                    default = FCOISdefaultSettings.autoDeMarkSellInGuildStore,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_demark_all_deconstruct"],
                                    tooltip = locVars["options_demark_all_deconstruct" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.autoDeMarkDeconstruct end,
                                    setFunc = function(value) FCOISsettings.autoDeMarkDeconstruct = value
                                    end,
                                    default = FCOISdefaultSettings.autoDeMarkDeconstruct,
                                },
                            },
                        },
                        ----------------------------------------------------------------------------------------------------
                        --Demark special
                        {
                            type = "checkbox",
                            name = locVars["options_demark_sell_on_others"],
                            tooltip = locVars["options_demark_sell_on_others" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoDeMarkSellOnOthers end,
                            setFunc = function(value) FCOISsettings.autoDeMarkSellOnOthers = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.autoDeMarkSellOnOthers,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_demark_on_others_exclusion_dynamic"],
                            tooltip = locVars["options_demark_on_others_exclusion_dynamic" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoDeMarkSellOnOthersExclusionDynamic end,
                            setFunc = function(value) FCOISsettings.autoDeMarkSellOnOthersExclusionDynamic = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.autoDeMarkSellOnOthersExclusionDynamic,
                            disabled = function() return not FCOISsettings.autoDeMarkSellOnOthers end,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_demark_sell_guild_store_on_others"],
                            tooltip = locVars["options_demark_sell_guild_store_on_others" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoDeMarkSellGuildStoreOnOthers end,
                            setFunc = function(value) FCOISsettings.autoDeMarkSellGuildStoreOnOthers = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.autoDeMarkSellGuildStoreOnOthers,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_demark_on_others_exclusion_dynamic"],
                            tooltip = locVars["options_demark_on_others_exclusion_dynamic" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoDeMarkSellGuildStoreOnOthersExclusionDynamic end,
                            setFunc = function(value) FCOISsettings.autoDeMarkSellGuildStoreOnOthersExclusionDynamic = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.autoDeMarkSellGuildStoreOnOthersExclusionDynamic,
                            disabled = function() return not FCOISsettings.autoDeMarkSellGuildStoreOnOthers end,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_demark_deconstruction_on_others"],
                            tooltip = locVars["options_demark_deconstruction_on_others" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoDeMarkDeconstructionOnOthers end,
                            setFunc = function(value) FCOISsettings.autoDeMarkDeconstructionOnOthers = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.autoDeMarkDeconstructionOnOthers,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_demark_on_others_exclusion_dynamic"],
                            tooltip = locVars["options_demark_on_others_exclusion_dynamic" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.autoDeMarkDeconstructionOnOthersExclusionDynamic end,
                            setFunc = function(value) FCOISsettings.autoDeMarkDeconstructionOnOthersExclusionDynamic = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.autoDeMarkDeconstructionOnOthersExclusionDynamic,
                            disabled = function() return not FCOISsettings.autoDeMarkDeconstructionOnOthers end,
                        },

                    } -- controls de-marking
                }, -- submenu de-marking


                --==============================================================================
                -- ITEM AUTOMATIC RE-MARKING
                --==============================================================================
                {
                    type = "submenu",
                    name = locVars["options_header_items_remark"],
                    controls = {
                        {
                            type = "checkbox",
                            name = locVars["options_remark_on_enchant"],
                            tooltip = locVars["options_remark_on_enchant" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.reApplyIconsAfterEnchanting end,
                            setFunc = function(value) FCOISsettings.reApplyIconsAfterEnchanting = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.reApplyIconsAfterEnchanting,
                            disabled = function() return false end,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_remark_on_improvement"],
                            tooltip = locVars["options_remark_on_improvement" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.reApplyIconsAfterImprovement end,
                            setFunc = function(value) FCOISsettings.reApplyIconsAfterImprovement = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.reApplyIconsAfterImprovement,
                            disabled = function() return false end,
                        },
                        { --#299
                            type = "checkbox",
                            name = locVars["options_remark_after_launderfence_leave"],
                            tooltip = locVars["options_remark_after_launderfence_leave" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.reApplyIconsAfterLaunderFenceRemove end,
                            setFunc = function(value) FCOISsettings.reApplyIconsAfterLaunderFenceRemove = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.reApplyIconsAfterLaunderFenceRemove,
                            disabled = function() return false end,
                        },


                    },

                },

            }, -- controls marking
        }, -- submenu marking

        --==============================================================================
        --		FILTERs
        --==============================================================================
        {
            type = "submenu",
            name = locVars["options_header_filters"],
            controls =
            {
                {
                    type = "checkbox",
                    name = locVars["options_filter_buttons_save_for_character"],
                    tooltip = locVars["options_filter_buttons_save_for_character" .. tooltipSuffix],
                    getFunc = function() return FCOIS.settingsVars.defaultSettings.filterButtonsSaveForCharacter end,
                    setFunc = function(value) FCOIS.settingsVars.defaultSettings.filterButtonsSaveForCharacter = value
                        ReloadUI("ingame")
                    end,
                    default = FCOIS.settingsVars.defaultSettings.filterButtonsSaveForCharacter,
                    disabled = function()
                        --If character savedvars are already enabled this option will be disabled
                        return FCOIS.settingsVars.defaultSettings.saveMode == 1
                    end,
                    requiresReload = true,
                },

                --==============================================================================
                --		Filter button positions
                --==============================================================================
                {
                    type = "submenu",
                    name = locVars["options_header_filter_buttons"],
                    controls =
                    {
                        {
                            type = "submenu",
                            name = locVars["options_header_filters"],
                            controls =
                            {
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_inventory"],
                                    tooltip = locVars["options_enable_filter_in_inventory" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowInventoryFilter end,
                                    setFunc = function(value) FCOISsettings.allowInventoryFilter = value
                                        --Hide the filter buttons at the filter panel Id
                                        FCOIS.UpdateFCOISFilterButtonsAtInventory(-1)
                                        --Unregister and reregister the inventory filter LF_INVENTORY
                                        FCOIS.EnableFilters(-100)
                                    end,
                                    default = FCOISdefaultSettings.allowInventoryFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_craftbag"],
                                    tooltip = locVars["options_enable_filter_in_craftbag" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowCraftBagFilter end,
                                    setFunc = function(value) FCOISsettings.allowCraftBagFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowCraftBagFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_bank"],
                                    tooltip = locVars["options_enable_filter_in_bank" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowBankFilter end,
                                    setFunc = function(value) FCOISsettings.allowBankFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowBankFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_guildbank"],
                                    tooltip = locVars["options_enable_filter_in_guildbank" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowGuildBankFilter end,
                                    setFunc = function(value) FCOISsettings.allowGuildBankFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowGuildBankFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_tradinghouse"],
                                    tooltip = locVars["options_enable_filter_in_tradinghouse" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowTradinghouseFilter end,
                                    setFunc = function(value) FCOISsettings.allowTradinghouseFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowTradinghouseFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_trade"],
                                    tooltip = locVars["options_enable_filter_in_trade" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowTradeFilter end,
                                    setFunc = function(value) FCOISsettings.allowTradeFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowTradeFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_mail"],
                                    tooltip = locVars["options_enable_filter_in_mail" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowMailFilter end,
                                    setFunc = function(value) FCOISsettings.allowMailFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowMailFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_store"],
                                    tooltip = locVars["options_enable_filter_in_store" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowVendorFilter end,
                                    setFunc = function(value) FCOISsettings.allowVendorFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowVendorFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_fence"],
                                    tooltip = locVars["options_enable_filter_in_fence" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowFenceFilter end,
                                    setFunc = function(value) FCOISsettings.allowFenceFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowFenceFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_launder"],
                                    tooltip = locVars["options_enable_filter_in_launder" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowLaunderFilter end,
                                    setFunc = function(value) FCOISsettings.allowLaunderFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowLaunderFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_refinement"],
                                    tooltip = locVars["options_enable_filter_in_refinement" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowRefinementFilter end,
                                    setFunc = function(value) FCOISsettings.allowRefinementFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowRefinementFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_jewelry_refinement"],
                                    tooltip = locVars["options_enable_filter_in_jewelry_refinement" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowJewelryRefinementFilter end,
                                    setFunc = function(value) FCOISsettings.allowJewelryRefinementFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowJewelryRefinementFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_deconstruction"],
                                    tooltip = locVars["options_enable_filter_in_deconstruction" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowDeconstructionFilter end,
                                    setFunc = function(value) FCOISsettings.allowDeconstructionFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowDeconstructionFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_jewelry_deconstruction"],
                                    tooltip = locVars["options_enable_filter_in_jewelry_deconstruction" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowJewelryDeconstructionFilter end,
                                    setFunc = function(value) FCOISsettings.allowJewelryDeconstructionFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowJewelryDeconstructionFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_improvement"],
                                    tooltip = locVars["options_enable_filter_in_improvement" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowImprovementFilter end,
                                    setFunc = function(value) FCOISsettings.allowImprovementFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowImprovementFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_jewelry_improvement"],
                                    tooltip = locVars["options_enable_filter_in_jewelry_improvement" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowJewelryImprovementFilter end,
                                    setFunc = function(value) FCOISsettings.allowJewelryImprovementFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowJewelryImprovementFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_research"],
                                    tooltip = locVars["options_enable_filter_in_research" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowResearchFilter end,
                                    setFunc = function(value) FCOISsettings.allowResearchFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowResearchFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_jewelry_research"],
                                    tooltip = locVars["options_enable_filter_in_jewelry_research" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowJewelryResearchFilter end,
                                    setFunc = function(value) FCOISsettings.allowJewelryResearchFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowJewelryResearchFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_enchanting"],
                                    tooltip = locVars["options_enable_filter_in_enchanting" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowEnchantingFilter end,
                                    setFunc = function(value) FCOISsettings.allowEnchantingFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowEnchantingFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_alchemy"],
                                    tooltip = locVars["options_enable_filter_in_alchemy" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowAlchemyFilter end,
                                    setFunc = function(value) FCOISsettings.allowAlchemyFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowAlchemyFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_retrait"],
                                    tooltip = locVars["options_enable_filter_in_retrait" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowRetraitFilter end,
                                    setFunc = function(value) FCOISsettings.allowRetraitFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowRetraitFilter,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_enable_filter_in_companion_inventory"],
                                    tooltip = locVars["options_enable_filter_in_companion_inventory" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.allowCompanionInventoryFilter end,
                                    setFunc = function(value) FCOISsettings.allowCompanionInventoryFilter = value
                                    end,
                                    default = FCOISdefaultSettings.allowCompanionInventoryFilter,
                                },
                                --==============================================================================
                                {
                                    type = "header",
                                    name = locVars["options_header_filter_chat"],
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_chat_filter_status"],
                                    tooltip = locVars["options_chat_filter_status" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showFilterStatusInChat end,
                                    setFunc = function(value) FCOISsettings.showFilterStatusInChat = value
                                    end,
                                    default = FCOISdefaultSettings.showFilterStatusInChat,
                                },
                            } -- controls filters
                        }, -- submenu filters

                        { -- Begin Submenu filter button position data
                            type = "submenu",
                            name = locVars["options_header_filter_buttons_position"],
                            controls = filterButtonsPositionsSubMenu
                        }, -- End submenu - Filter button position data
                        {
                            type = "checkbox",
                            name = locVars["options_filter_buttons_show" .. tooltipSuffix],
                            tooltip = locVars["options_filter_buttons_show_tooltip" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.showFilterButtonTooltip end,
                            setFunc = function(value) FCOISsettings.showFilterButtonTooltip = value
                            end,
                            default = FCOISdefaultSettings.showFilterButtonTooltip,
                        },
                    } -- controls filter buttons
                }, -- submenu filter buttons

                {
                    type = "checkbox",
                    name = locVars["options_enable_filtered_item_count"],
                    tooltip = locVars["options_enable_filtered_item_count" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showFilteredItemCount end,
                    setFunc = function(value)
                        FCOISsettings.showFilteredItemCount = value
                    end,
                    default = FCOISdefaultSettings.showFilteredItemCount,
                },

            } -- controls ALL filters
        }, -- submenu ALL filters


        --==============================================================================
        -- ANTI DESTROY
        --==============================================================================
        {
            type = "submenu",
            name = locVars["options_header_anti_destroy"],
            controls =
            {

                -- ANTI EQUIP
                {
                    type = "submenu",
                    name = locVars["options_header_anti_equip"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_askBeforeEquipBoundItems"],
                            tooltip = locVars["options_askBeforeEquipBoundItems" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.askBeforeEquipBoundItems end,
                            setFunc = function(value) FCOISsettings.askBeforeEquipBoundItems = value
                            end,
                            default = FCOISdefaultSettings.askBeforeEquipBoundItems,
                            --disabled = function() return FCOIS.APIversion > 100019 end, --Ask before bind will be introduced ingame with patch 3.1, API 100020
                        },
                    }, -- controls anti equip
                }, -- submenu anti equip
                {
                    type = "header",
                    name = locVars["options_header_destroy"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_destroying"],
                    tooltip = locVars["options_enable_block_destroying" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockDestroying end,
                    setFunc = function(value) FCOISsettings.blockDestroying = value
                        FCOISsettings.autoReenable_blockDestroying = value
                    end,
                    default = FCOISdefaultSettings.blockDestroying,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_destroying"],
                    tooltip = locVars["options_auto_reenable_block_destroying" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockDestroying end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockDestroying = value
                    end,
                    disabled = function() return not FCOISsettings.blockDestroying end,
                    default = FCOISdefaultSettings.autoReenable_blockDestroying,
                },
                {
                    type = "header",
                    name = locVars["options_header_refinement"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_refinement"],
                    tooltip = locVars["options_enable_block_refinement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockRefinement end,
                    setFunc = function(value) FCOISsettings.blockRefinement = value
                        FCOISsettings.autoReenable_blockRefinement = value
                    end,
                    default = FCOISdefaultSettings.blockRefinement,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_refinement"],
                    tooltip = locVars["options_auto_reenable_block_refinement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockRefinement end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockRefinement = value
                    end,
                    disabled = function() return not FCOISsettings.blockRefinement end,
                    default = FCOISdefaultSettings.autoReenable_blockRefinement,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_jewelry_refinement"],
                    tooltip = locVars["options_enable_block_jewelry_refinement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockJewelryRefinement end,
                    setFunc = function(value) FCOISsettings.blockJewelryRefinement = value
                        FCOISsettings.autoReenable_blockJewelryRefinement = value
                    end,
                    default = FCOISdefaultSettings.blockJewelryRefinement,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_jewelry_refinement"],
                    tooltip = locVars["options_auto_reenable_block_jewelry_refinement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockJewelryRefinement end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockJewelryRefinement = value
                    end,
                    disabled = function() return not FCOISsettings.blockJewelryRefinement end,
                    default = FCOISdefaultSettings.autoReenable_blockJewelryRefinement,
                },
                {
                    type = "header",
                    name = locVars["options_header_deconstruction"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_deconstruction"],
                    tooltip = locVars["options_enable_block_deconstruction" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockDeconstruction end,
                    setFunc = function(value) FCOISsettings.blockDeconstruction = value
                        FCOISsettings.autoReenable_blockDeconstruction = value
                    end,
                    default = FCOISdefaultSettings.blockDeconstruction,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_deconstruction"],
                    tooltip = locVars["options_auto_reenable_block_deconstruction" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockDeconstruction end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockDeconstruction = value
                    end,
                    disabled = function() return not FCOISsettings.blockDeconstruction end,
                    default = FCOISdefaultSettings.autoReenable_blockDeconstruction,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_jewelry_deconstruction"],
                    tooltip = locVars["options_enable_block_jewelry_deconstruction" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockJewelryDeconstruction end,
                    setFunc = function(value) FCOISsettings.blockJewelryDeconstruction = value
                        FCOISsettings.autoReenable_blockJewelryDeconstruction = value
                    end,
                    default = FCOISdefaultSettings.blockJewelryDeconstruction,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_jewelry_deconstruction"],
                    tooltip = locVars["options_auto_reenable_block_jewelry_deconstruction" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockJewelryDeconstruction end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockJewelryDeconstruction = value
                    end,
                    disabled = function() return not FCOISsettings.blockJewelryDeconstruction end,
                    default = FCOISdefaultSettings.autoReenable_blockJewelryDeconstruction,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_deconstruction_exception_intricate"],
                    tooltip = locVars["options_enable_block_deconstruction_exception_intricate" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowDeconstructIntricate end,
                    setFunc = function(value) FCOISsettings.allowDeconstructIntricate = value
                    end,
                    disabled = function() return not FCOISsettings.blockDeconstruction and not FCOISsettings.blockJewelryDeconstruction end,
                    default = FCOISdefaultSettings.allowDeconstructIntricate,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_deconstruction_exception_deconstruction"],
                    tooltip = locVars["options_enable_block_deconstruction_exception_deconstruction" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowDeconstructDeconstruction end,
                    setFunc = function(value) FCOISsettings.allowDeconstructDeconstruction = value
                    end,
                    disabled = function() return not FCOISsettings.blockDeconstruction and not FCOISsettings.blockJewelryDeconstruction end,
                    default = FCOISdefaultSettings.allowDeconstructDeconstruction,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_deconstruction_exception_deconstruction_all_markers"],
                    tooltip = locVars["options_enable_block_deconstruction_exception_deconstruction_all_markers" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowDeconstructDeconstructionWithMarkers end,
                    setFunc = function(value) FCOISsettings.allowDeconstructDeconstructionWithMarkers = value
                    end,
                    disabled = function() return (not FCOISsettings.blockDeconstruction and not FCOISsettings.blockJewelryDeconstruction) or not FCOISsettings.allowDeconstructDeconstruction end,
                    default = FCOISdefaultSettings.allowDeconstructDeconstructionWithMarkers,
                },
                {
                    type = "header",
                    name = locVars["options_header_improvement"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_improvement"],
                    tooltip = locVars["options_enable_block_improvement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockImprovement end,
                    setFunc = function(value) FCOISsettings.blockImprovement = value
                        FCOISsettings.autoReenable_blockImprovement = value
                    end,
                    default = FCOISdefaultSettings.blockImprovement,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_improvement"],
                    tooltip = locVars["options_auto_reenable_block_improvement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockImprovement end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockImprovement = value
                    end,
                    disabled = function() return not FCOISsettings.blockImprovement end,
                    default = FCOISdefaultSettings.autoReenable_blockImprovement,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_jewelry_improvement"],
                    tooltip = locVars["options_enable_block_jewelry_improvement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockJewelryImprovement end,
                    setFunc = function(value) FCOISsettings.blockJewelryImprovement = value
                        FCOISsettings.autoReenable_blockJewelryImprovement = value
                    end,
                    default = FCOISdefaultSettings.blockJewelryImprovement,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_jewelry_improvement"],
                    tooltip = locVars["options_auto_reenable_block_jewelry_improvement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockJewelryImprovement end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockJewelryImprovement = value
                    end,
                    disabled = function() return not FCOISsettings.blockJewelryImprovement end,
                    default = FCOISdefaultSettings.autoReenable_blockJewelryImprovement,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_improvement_exception_improvement"],
                    tooltip = locVars["options_enable_block_improvement_exception_improvement" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowImproveImprovement end,
                    setFunc = function(value) FCOISsettings.allowImproveImprovement = value
                    end,
                    disabled = function() return not FCOISsettings.blockImprovement and not FCOISsettings.blockJewelryImprovement end,
                    default = FCOISdefaultSettings.allowImproveImprovement,
                },
                {
                    type = "header",
                    name = locVars["options_header_research"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_research"],
                    tooltip = locVars["options_enable_block_research" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockResearchDialog end,
                    setFunc = function(value) FCOISsettings.blockResearchDialog = value
                    end,
                    default = FCOISdefaultSettings.blockResearchDialog,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_jewelry_research"],
                    tooltip = locVars["options_enable_block_jewelry_research" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockJewelryResearchDialog end,
                    setFunc = function(value) FCOISsettings.blockJewelryResearchDialog = value
                    end,
                    default = FCOISdefaultSettings.blockJewelryResearchDialog,
                },
                {
                    type = "checkbox",
                    name = locVars["options_research_filter"],
                    tooltip = locVars["options_research_filter" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowResearch end,
                    setFunc = function(value) FCOISsettings.allowResearch = value
                    end,
                    disabled = function() return (not FCOISsettings.blockResearchDialog and not FCOISsettings.blockJewelryResearchDialog) end,
                    default = FCOISdefaultSettings.allowResearch,
                },
                {
                    type = "header",
                    name = locVars["options_header_rune_creation"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_creation"],
                    tooltip = locVars["options_enable_block_creation" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockEnchantingCreation end,
                    setFunc = function(value) FCOISsettings.blockEnchantingCreation = value
                        FCOISsettings.autoReenable_blockEnchantingCreation = value
                    end,
                    default = FCOISdefaultSettings.blockEnchantingCreation,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_creation"],
                    tooltip = locVars["options_auto_reenable_block_creation" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockEnchantingCreation end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockEnchantingCreation = value
                    end,
                    disabled = function() return not FCOISsettings.blockEnchantingCreation end,
                    default = FCOISdefaultSettings.autoReenable_blockEnchantingCreation,
                },
                {
                    type = "header",
                    name = locVars["options_header_rune_extraction"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_extraction"],
                    tooltip = locVars["options_enable_block_extraction" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockEnchantingExtraction end,
                    setFunc = function(value) FCOISsettings.blockEnchantingExtraction = value
                        FCOISsettings.autoReenable_blockEnchantingExtraction = value
                    end,
                    default = FCOISdefaultSettings.blockEnchantingExtraction,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_extraction"],
                    tooltip = locVars["options_auto_reenable_block_extraction" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockEnchantingExtraction end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockEnchantingExtraction = value
                    end,
                    disabled = function() return not FCOISsettings.blockEnchantingExtraction end,
                    default = FCOISdefaultSettings.autoReenable_blockEnchantingExtraction,
                },
                {
                    type = "header",
                    name = locVars["options_header_sell"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_selling"],
                    tooltip = locVars["options_enable_block_selling" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockSelling end,
                    setFunc = function(value) FCOISsettings.blockSelling = value
                        FCOISsettings.autoReenable_blockSelling = value
                    end,
                    default = FCOISdefaultSettings.blockSelling,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_selling"],
                    tooltip = locVars["options_auto_reenable_block_selling" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockSelling end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockSelling = value
                    end,
                    disabled = function() return not FCOISsettings.blockSelling end,
                    default = FCOISdefaultSettings.autoReenable_blockSelling,
                },
                {
                    type = "checkbox",
                    name = locVars["options_block_selling_exception"],
                    tooltip = locVars["options_block_selling_exception" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowSellingForBlocked end,
                    setFunc = function(value) FCOISsettings.allowSellingForBlocked = value
                    end,
                    disabled = function() return not FCOISsettings.blockSelling end,
                    default = FCOISdefaultSettings.allowSellingForBlocked,
                },
                {
                    type = "checkbox",
                    name = locVars["options_block_selling_exception_intricate"],
                    tooltip = locVars["options_block_selling_exception_intricate" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowSellingForBlockedIntricate end,
                    setFunc = function(value) FCOISsettings.allowSellingForBlockedIntricate = value
                    end,
                    disabled = function() return not FCOISsettings.blockSelling end,
                    default = FCOISdefaultSettings.allowSellingForBlockedIntricate,
                },
                {
                    type = "checkbox",
                    name = locVars["options_block_selling_exception_ornate"],
                    tooltip = locVars["options_block_selling_exception_ornate" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowSellingForBlockedOrnate end,
                    setFunc = function(value) FCOISsettings.allowSellingForBlockedOrnate = value
                    end,
                    disabled = function() return not FCOISsettings.blockSelling and not FCOISsettings.blockSellingGuildStore end,
                    default = FCOISdefaultSettings.allowSellingForBlockedOrnate,
                },
                {
                    type = "header",
                    name = locVars["options_header_sell_at_guild_store"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_selling_guild_store"],
                    tooltip = locVars["options_enable_block_selling_guild_store" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockSellingGuildStore end,
                    setFunc = function(value) FCOISsettings.blockSellingGuildStore = value
                        FCOISsettings.autoReenable_blockSellingGuildStore = value
                    end,
                    default = FCOISdefaultSettings.blockSellingGuildStore,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_selling_guild_store"],
                    tooltip = locVars["options_auto_reenable_block_selling_guild_store" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockSellingGuildStore end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockSellingGuildStore = value
                    end,
                    disabled = function() return not FCOISsettings.blockSellingGuildStore end,
                    default = FCOISdefaultSettings.autoReenable_blockSellingGuildStore,
                },
                {
                    type = "checkbox",
                    name = locVars["options_block_selling_exception_guild_store"],
                    tooltip = locVars["options_block_selling_exception_guild_store" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowSellingInGuildStoreForBlocked end,
                    setFunc = function(value) FCOISsettings.allowSellingInGuildStoreForBlocked = value
                    end,
                    disabled = function() return not FCOISsettings.blockSellingGuildStore end,
                    default = FCOISdefaultSettings.allowSellingInGuildStoreForBlocked,
                },
                {
                    type = "checkbox",
                    name = locVars["options_block_selling_exception_intricate"],
                    tooltip = locVars["options_block_selling_exception_intricate" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowSellingGuildStoreForBlockedIntricate end,
                    setFunc = function(value) FCOISsettings.allowSellingGuildStoreForBlockedIntricate = value
                    end,
                    disabled = function() return not FCOISsettings.blockSellingGuildStore end,
                    default = FCOISdefaultSettings.allowSellingGuildStoreForBlockedIntricate,
                },
                {
                    type = "header",
                    name = locVars["options_header_guild_bank"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_guild_bank_without_withdraw"],
                    tooltip = locVars["options_enable_block_guild_bank_without_withdraw" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockGuildBankWithoutWithdraw end,
                    setFunc = function(value) FCOISsettings.blockGuildBankWithoutWithdraw = value
                    end,
                    default = FCOISdefaultSettings.blockGuildBankWithoutWithdraw,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_guild_bank_without_withdraw"],
                    tooltip = locVars["options_auto_reenable_block_guild_bank_without_withdraw" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockGuildBankWithoutWithdraw end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockGuildBankWithoutWithdraw = value
                    end,
                    default = FCOISdefaultSettings.autoReenable_blockGuildBankWithoutWithdraw,
                    disabled = function() return not FCOISsettings.blockGuildBankWithoutWithdraw end,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_disable_with_flag"],
                    tooltip = locVars["options_enable_block_marked_disable_with_flag" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockGuildBankWithoutWithdrawDisableWithFlag end,
                    setFunc = function(value) FCOISsettings.blockGuildBankWithoutWithdrawDisableWithFlag = value
                    end,
                    default = FCOISdefaultSettings.blockGuildBankWithoutWithdrawDisableWithFlag,
                },
                {
                    type = "header",
                    name = locVars["options_header_fence"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_fence_selling"],
                    tooltip = locVars["options_enable_block_fence_selling" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockFence end,
                    setFunc = function(value) FCOISsettings.blockFence = value
                        FCOISsettings.autoReenable_blockFenceSelling = value
                    end,
                    default = FCOISdefaultSettings.blockFence,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_fence_selling"],
                    tooltip = locVars["options_auto_reenable_block_fence_selling" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockFenceSelling end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockFenceSelling = value
                    end,
                    disabled = function() return not FCOISsettings.blockFence end,
                    default = FCOISdefaultSettings.autoReenable_blockFenceSelling,
                },
                {
                    type = "header",
                    name = locVars["options_header_launder"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_launder_selling"],
                    tooltip = locVars["options_enable_block_launder_selling" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockLaunder end,
                    setFunc = function(value) FCOISsettings.blockLaunder = value
                        FCOISsettings.autoReenable_blockLaunderSelling = value
                    end,
                    default = FCOISdefaultSettings.blockLaunder,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_launder_selling"],
                    tooltip = locVars["options_auto_reenable_block_launder_selling" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockLaunderSelling end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockLaunderSelling = value
                    end,
                    disabled = function() return not FCOISsettings.blockLaunder end,
                    default = FCOISdefaultSettings.autoReenable_blockLaunderSelling,
                },
                {
                    type = "header",
                    name = locVars["options_header_trade"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_trading"],
                    tooltip = locVars["options_enable_block_trading" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockTrading end,
                    setFunc = function(value) FCOISsettings.blockTrading = value
                        FCOISsettings.autoReenable_blockTrading = value
                    end,
                    default = FCOISdefaultSettings.blockTrading,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_trading"],
                    tooltip = locVars["options_auto_reenable_block_trading" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockTrading end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockTrading = value
                    end,
                    disabled = function() return not FCOISsettings.blockTrading end,
                    default = FCOISdefaultSettings.autoReenable_blockTrading,
                },
                {
                    type = "header",
                    name = locVars["options_header_mail"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_sending_mail"],
                    tooltip = locVars["options_enable_block_sending_mail" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockSendingByMail end,
                    setFunc = function(value) FCOISsettings.blockSendingByMail = value
                        FCOISsettings.autoReenable_blockSendingByMail = value
                    end,
                    default = FCOISdefaultSettings.blockSendingByMail,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_sending_mail"],
                    tooltip = locVars["options_auto_reenable_block_sending_mail" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockSendingByMail end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockSendingByMail = value
                    end,
                    disabled = function() return not FCOISsettings.blockSendingByMail end,
                    default = FCOISdefaultSettings.autoReenable_blockSendingByMail,
                },
                {
                    type = "header",
                    name = locVars["options_header_alchemy_destroy"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_alchemy_destroy"],
                    tooltip = locVars["options_enable_block_alchemy_destroy" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockAlchemyDestroy end,
                    setFunc = function(value) FCOISsettings.blockAlchemyDestroy = value
                        FCOISsettings.autoReenable_blockAlchemyDestroy = value
                    end,
                    default = FCOISdefaultSettings.blockAlchemyDestroy,
                },
                {
                    type = "checkbox",
                    name = locVars["options_auto_reenable_block_alchemy_destroy"],
                    tooltip = locVars["options_auto_reenable_block_alchemy_destroy" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.autoReenable_blockAlchemyDestroy end,
                    setFunc = function(value) FCOISsettings.autoReenable_blockAlchemyDestroy = value
                    end,
                    disabled = function() return not FCOISsettings.blockAlchemyDestroy end,
                    default = FCOISdefaultSettings.autoReenable_blockAlchemyDestroy,
                },
                {
                    type = "header",
                    name = locVars["options_header_transmutation"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_retrait"],
                    tooltip = locVars["options_enable_block_retrait" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockRetrait end,
                    setFunc = function(value) FCOISsettings.blockRetrait = value
                        FCOISsettings.autoReenable_blockRetrait = value
                    end,
                    default = FCOISdefaultSettings.blockRetrait,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_transmutation_dialog_max_withdraw"],
                    tooltip = locVars["options_enable_block_transmutation_dialog_max_withdraw" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showTransmutationGeodeLootDialog end,
                    setFunc = function(value) FCOISsettings.showTransmutationGeodeLootDialog = value
                    end,
                    default = FCOISdefaultSettings.showTransmutationGeodeLootDialog,
                },
                {
                    type = "header",
                    name = locVars["options_header_repair"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_allow_marked_repair"],
                    tooltip = locVars["options_allow_marked_repair" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedRepairKits end,
                    setFunc = function(value) FCOISsettings.blockMarkedRepairKits = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedRepairKits,
                },
                {
                    type = "header",
                    name = locVars["options_header_enchant"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_allow_marked_enchant"],
                    tooltip = locVars["options_allow_marked_enchant" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedGlyphs end,
                    setFunc = function(value) FCOISsettings.blockMarkedGlyphs = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedGlyphs,
                },
                {
                    type = "header",
                    name = locVars["options_header_containers"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_autoloot_container"],
                    tooltip = locVars["options_enable_block_autoloot_container" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockAutoLootContainer end,
                    setFunc = function(value) FCOISsettings.blockAutoLootContainer = value
                    end,
                    default = FCOISdefaultSettings.blockAutoLootContainer,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_disable_with_flag"],
                    tooltip = locVars["options_enable_block_marked_disable_with_flag" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedAutoLootContainerDisableWithFlag end,
                    setFunc = function(value) FCOISsettings.blockMarkedAutoLootContainerDisableWithFlag = value
                    end,
                    disabled = function() return not FCOISsettings.blockAutoLootContainer end,
                    default = FCOISdefaultSettings.blockMarkedAutoLootContainerDisableWithFlag,
                },
                {
                    type = "header",
                    name = locVars["options_header_recipes"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_recipes"],
                    tooltip = locVars["options_enable_block_marked_recipes" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedRecipes end,
                    setFunc = function(value) FCOISsettings.blockMarkedRecipes = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedRecipes,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_disable_with_flag"],
                    tooltip = locVars["options_enable_block_marked_disable_with_flag" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedRecipesDisableWithFlag end,
                    setFunc = function(value) FCOISsettings.blockMarkedRecipesDisableWithFlag = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedRecipesDisableWithFlag,
                },
                {
                    type = "header",
                    name = locVars["options_header_motifs"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_motifs"],
                    tooltip = locVars["options_enable_block_motifs" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedMotifs end,
                    setFunc = function(value) FCOISsettings.blockMarkedMotifs = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedMotifs,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_disable_with_flag"],
                    tooltip = locVars["options_enable_block_marked_disable_with_flag" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedMotifsDisableWithFlag end,
                    setFunc = function(value) FCOISsettings.blockMarkedMotifsDisableWithFlag = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedMotifsDisableWithFlag,
                },
                {
                    type = "header",
                    name = locVars["options_header_food"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_potions"],
                    tooltip = locVars["options_enable_block_potions" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedPotions end,
                    setFunc = function(value) FCOISsettings.blockMarkedPotions = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedPotions,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_food"],
                    tooltip = locVars["options_enable_block_food" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedFood end,
                    setFunc = function(value) FCOISsettings.blockMarkedFood = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedFood,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_disable_with_flag"],
                    tooltip = locVars["options_enable_block_marked_disable_with_flag" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedFoodDisableWithFlag end,
                    setFunc = function(value) FCOISsettings.blockMarkedFoodDisableWithFlag = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedFoodDisableWithFlag,
                },
                {
                    type = "header",
                    name = locVars["options_header_crownstore"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_crownstoreitems"],
                    tooltip = locVars["options_enable_block_crownstoreitems" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockCrownStoreItems end,
                    setFunc = function(value) FCOISsettings.blockCrownStoreItems = value
                    end,
                    default = FCOISdefaultSettings.blockCrownStoreItems,
                },
                {
                    type = "checkbox",
                    name = locVars["options_enable_block_marked_disable_with_flag"],
                    tooltip = locVars["options_enable_block_marked_disable_with_flag" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.blockMarkedCrownStoreItemDisableWithFlag end,
                    setFunc = function(value) FCOISsettings.blockMarkedCrownStoreItemDisableWithFlag = value
                    end,
                    default = FCOISdefaultSettings.blockMarkedCrownStoreItemDisableWithFlag,
                },
                {
                    type = "header",
                    name = locVars["options_header_junk"],
                },
                {
                    type = "submenu",
                    name = locVars["options_header_additional_inv_flag_context_menu"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_dont_unjunk_on_bulk_mark"],
                            tooltip = locVars["options_dont_unjunk_on_bulk_mark" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.dontUnjunkOnBulkMark end,
                            setFunc = function(value) FCOISsettings.dontUnjunkOnBulkMark = value
                            end,
                            default = FCOISdefaultSettings.dontUnjunkOnBulkMark,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_junk_item_marked_to_be_sold"],
                            tooltip = locVars["options_junk_item_marked_to_be_sold" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.junkItemsMarkedToBeSold end,
                            setFunc = function(value) FCOISsettings.junkItemsMarkedToBeSold = value
                            end,
                            default = FCOISdefaultSettings.junkItemsMarkedToBeSold,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_dont_unjunk_item_marked_to_be_sold"],
                            tooltip = locVars["options_dont_unjunk_item_marked_to_be_sold" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.dontUnJunkItemsMarkedToBeSold end,
                            setFunc = function(value) FCOISsettings.dontUnJunkItemsMarkedToBeSold = value
                            end,
                            default = FCOISdefaultSettings.dontUnJunkItemsMarkedToBeSold,
                        },
                    }, -- controls junk add. inv. flag context menu
                }, -- submenu junk add. inv. flag context menu
                {
                    type = "checkbox",
                    name = locVars["options_remove_context_menu_mark_as_junk"],
                    tooltip = locVars["options_remove_context_menu_mark_as_junk" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.removeMarkAsJunk end,
                    setFunc = function(value) FCOISsettings.removeMarkAsJunk = value
                    end,
                    default = FCOISdefaultSettings.removeMarkAsJunk,
                },
                {
                    type = "checkbox",
                    name = locVars["options_junk_item_marked_to_be_sold"],
                    tooltip = locVars["options_junk_item_marked_to_be_sold" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.allowMarkAsJunkForMarkedToBeSold end,
                    setFunc = function(value) FCOISsettings.allowMarkAsJunkForMarkedToBeSold = value
                    end,
                    disabled = function() return not FCOISsettings.removeMarkAsJunk end,
                    default = FCOISdefaultSettings.allowMarkAsJunkForMarkedToBeSold,
                },
                {
                    type = "checkbox",
                    name = locVars["options_dont_unjunk_on_normal_mark"],
                    tooltip = locVars["options_dont_unjunk_on_normal_mark" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.dontUnjunkOnNormalMark end,
                    setFunc = function(value) FCOISsettings.dontUnjunkOnNormalMark = value
                    end,
                    default = FCOISdefaultSettings.dontUnjunkOnNormalMark,
                },
                {
                    type = "header",
                    name = locVars["options_header_anti_output_options"],
                },
                {
                    type = "checkbox",
                    name = locVars["show_anti_messages_in_chat"],
                    tooltip = locVars["show_anti_messages_in_chat" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showAntiMessageInChat end,
                    setFunc = function(value) FCOISsettings.showAntiMessageInChat = value
                    end,
                    default = FCOISdefaultSettings.showAntiMessageInChat,
                },
                {
                    type = "checkbox",
                    name = locVars["show_anti_messages_as_alert"],
                    tooltip = locVars["show_anti_messages_as_alert" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showAntiMessageAsAlert end,
                    setFunc = function(value) FCOISsettings.showAntiMessageAsAlert = value
                    end,
                    default = FCOISdefaultSettings.showAntiMessageAsAlert,
                },
            } -- controls anti destroy
        }, -- submenu anti destroy

        --==============================================================================
        -- CONTEXT MENUs IN INVENTORY
        {
            type = "submenu",
            name = locVars["options_header_context_menu"],
            controls =
            {
                {
                    type = "submenu",
                    name = locVars["options_header_context_menu_inventory"],
                    controls =
                    {
                        {
                            type     = "submenu",
                            name     = locVars["options_header_context_menu_divider"],
                            tooltip = locVars["options_header_context_menu_divider" .. tooltipSuffix],
                            disabled = function() return FCOISsettings.useSubContextMenu end,
                            controls =
                            {
                                {
                                    type = "checkbox",
                                    name = locVars["options_show_contextmenu_divider"],
                                    tooltip = locVars["options_show_contextmenu_divider" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.showContextMenuDivider end,
                                    setFunc = function(value) FCOISsettings.showContextMenuDivider = value
                                    end,
                                    disabled = function() return FCOISsettings.useSubContextMenu end,
                                    default = FCOISdefaultSettings.showContextMenuDivider,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_contextmenu_divider_opens_settings"],
                                    tooltip = locVars["options_contextmenu_divider_opens_settings" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.contextMenuDividerShowsSettings end,
                                    setFunc = function(value)
                                        FCOISsettings.contextMenuDividerShowsSettings = value
                                        if FCOISsettings.contextMenuDividerShowsSettings then
                                            FCOISsettings.contextMenuDividerClearsMarkers = false
                                        end
                                    end,
                                    disabled = function()
                                        if FCOISsettings.useSubContextMenu then
                                            return true
                                        else
                                            if FCOISsettings.showContextMenuDivider then
                                                return FCOISsettings.contextMenuDividerClearsMarkers
                                            else
                                                return true
                                            end
                                        end
                                    end,
                                    default = FCOISdefaultSettings.contextMenuDividerShowsSettings,
                                },
                                {
                                    type = "checkbox",
                                    name = locVars["options_contextmenu_divider_clears_all_markers"],
                                    tooltip = locVars["options_contextmenu_divider_clears_all_markers" .. tooltipSuffix],
                                    getFunc = function() return FCOISsettings.contextMenuDividerClearsMarkers end,
                                    setFunc = function(value)
                                        FCOISsettings.contextMenuDividerClearsMarkers = value
                                        if FCOISsettings.contextMenuDividerClearsMarkers then
                                            FCOISsettings.contextMenuDividerShowsSettings = false
                                        end
                                    end,
                                    disabled = function()
                                        if FCOISsettings.useSubContextMenu then
                                            return true
                                        else
                                            if FCOISsettings.showContextMenuDivider then
                                                return FCOISsettings.contextMenuDividerShowsSettings
                                            else
                                                return true
                                            end
                                        end
                                    end,
                                    default = FCOISdefaultSettings.contextMenuDividerClearsMarkers,
                                },

                            } --controls divider in contextmenu
                        }, --submenu divider in contextmenu

                        {
                            type = "checkbox",
                            name = locVars["options_use_subcontextmenu"],
                            tooltip = locVars["options_use_subcontextmenu" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.useSubContextMenu end,
                            setFunc = function(value) FCOISsettings.useSubContextMenu = value
                            end,
                            default = FCOISdefaultSettings.useSubContextMenu,
                        },

                        {
                            type = "slider",
                            min  = 0,
                            max  = numDynIcons,
                            step = 1,
                            decimals = 0,
                            autoSelect = true,
                            name = locVars["options_contextmenu_use_dyn_submenu"],
                            tooltip = locVars["options_contextmenu_use_dyn_submenu" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.useDynSubMenuMaxCount end,
                            setFunc = function(value)
                                FCOISsettings.useDynSubMenuMaxCount = value
                            end,
                            disabled = function()
                                return FCOISsettings.useSubContextMenu
                            end,
                            default = FCOISdefaultSettings.useDynSubMenuMaxCount,
                        },

                        {
                            type = "slider",
                            min  = 0,
                            max  = 10,
                            step = 1,
                            decimals = 0,
                            autoSelect = true,
                            name = locVars["options_contextmenu_leading_spaces"],
                            tooltip = locVars["options_contextmenu_leading_spaces" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.addContextMenuLeadingSpaces end,
                            setFunc = function(value)
                                FCOISsettings.addContextMenuLeadingSpaces = value
                            end,
                            disabled = function()
                                return FCOISsettings.useSubContextMenu
                            end,
                            default = FCOISdefaultSettings.addContextMenuLeadingSpaces,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_contextmenu_use_custom_marked_normal" .. colorSuffix],
                            tooltip = locVars["options_contextmenu_use_custom_marked_normal" .. colorSuffix .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.useContextMenuCustomMarkedNormalColor end,
                            setFunc = function(value) FCOISsettings.useContextMenuCustomMarkedNormalColor = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.useContextMenuCustomMarkedNormalColor,
                        },
                        {
                            type = "colorpicker",
                            name = locVars["options_contextmenu_custom_marked_normal" .. colorSuffix],
                            tooltip = locVars["options_contextmenu_custom_marked_normal" .. colorSuffix .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.contextMenuCustomMarkedNormalColor.r, FCOISsettings.contextMenuCustomMarkedNormalColor.g, FCOISsettings.contextMenuCustomMarkedNormalColor.b, FCOISsettings.contextMenuCustomMarkedNormalColor.a end,
                            setFunc = function(r,g,b,a)
                                FCOISsettings.contextMenuCustomMarkedNormalColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
                            end,
                            width = "half",
                            disabled = function() return not FCOISsettings.useContextMenuCustomMarkedNormalColor end,
                            default = FCOISdefaultSettings.contextMenuCustomMarkedNormalColor,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_contextmenu_leading_icon"],
                            tooltip = locVars["options_contextmenu_leading_icon" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.addContextMenuLeadingMarkerIcon end,
                            setFunc = function(value) FCOISsettings.addContextMenuLeadingMarkerIcon = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.addContextMenuLeadingMarkerIcon,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_contextmenu_use_icon" .. colorSuffix],
                            tooltip = locVars["options_contextmenu_use_icon" .. colorSuffix .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.contextMenuEntryColorEqualsIconColor end,
                            setFunc = function(value) FCOISsettings.contextMenuEntryColorEqualsIconColor = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.contextMenuEntryColorEqualsIconColor,
                        },
                        {
                            type = "slider",
                            min  = 12,
                            max  = 40,
                            step = 2,
                            decimals = 0,
                            autoSelect = true,
                            name = locVars["options_contextmenu_leading_icon_size"],
                            tooltip = locVars["options_contextmenu_leading_icon_size" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.contextMenuLeadingIconSize end,
                            setFunc = function(value)
                                FCOISsettings.contextMenuLeadingIconSize = value
                            end,
                            disabled = function()
                                return not FCOISsettings.addContextMenuLeadingMarkerIcon
                            end,
                            default = FCOISdefaultSettings.contextMenuLeadingIconSize,
                        },
                        --Tooltip at context menu entry
                        {
                            type = "checkbox",
                            name = locVars["options_contextmenu_entries_enable_tooltip"],
                            tooltip = locVars["options_contextmenu_entries_enable_tooltip" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.contextMenuItemEntryShowTooltip end,
                            setFunc = function(value) FCOISsettings.contextMenuItemEntryShowTooltip = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.contextMenuItemEntryShowTooltip,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_contextmenu_entries_enable_tooltip_only_SHIFTkey"],
                            tooltip = locVars["options_contextmenu_entries_enable_tooltip_only_SHIFTkey" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.contextMenuItemEntryShowTooltipWithSHIFTKeyOnly end,
                            setFunc = function(value) FCOISsettings.contextMenuItemEntryShowTooltipWithSHIFTKeyOnly = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.contextMenuItemEntryShowTooltipWithSHIFTKeyOnly,
                            disabled = function() return not FCOISsettings.contextMenuItemEntryShowTooltip end,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_contextmenu_entries_tooltip_protectedpanels"],
                            tooltip = locVars["options_contextmenu_entries_tooltip_protectedpanels" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.contextMenuItemEntryTooltipProtectedPanels end,
                            setFunc = function(value) FCOISsettings.contextMenuItemEntryTooltipProtectedPanels = value
                            end,
                            width = "half",
                            default = FCOISdefaultSettings.contextMenuItemEntryTooltipProtectedPanels,
                            disabled = function() return not FCOISsettings.contextMenuItemEntryShowTooltip end,
                        },

                    } -- controls context menu at inventory
                }, -- submenu context menu at inventory

                --------------------------------------------------------------------------------------------------------

                {
                    type = "submenu",
                    name = locVars["options_header_context_menu_filter_buttons"],
                    controls =
                    {

                        {
                            type = "checkbox",
                            name = locVars["options_split_lockdyn_filter"],
                            tooltip = locVars["options_split_lockdyn_filter" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.splitLockDynFilter end,
                            setFunc = function(value) FCOISsettings.splitLockDynFilter = value
                                --Change the gear sets filter context-menu button's texture
                                local lockDynSplitFilterContextMenuButton = GetControl(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_LOCKDYN]) --wm:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_LOCKDYN], "")
                                if lockDynSplitFilterContextMenuButton ~= nil then
                                    updateFCOISFilterButtonColorsAndTextures(1, lockDynSplitFilterContextMenuButton, nil, LF_INVENTORY)
                                    filterBasics(true)
                                end
                            end,
                            default = FCOISdefaultSettings.splitLockDynFilter,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_split_gearsets_filter"],
                            tooltip = locVars["options_split_gearsets_filter" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.splitGearSetsFilter end,
                            setFunc = function(value) FCOISsettings.splitGearSetsFilter = value
                                --Change the gear sets filter context-menu button's texture
                                local gearSetSplitFilterContextMenuButton = GetControl(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS]) --wm:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_GEARSETS], "")
                                if gearSetSplitFilterContextMenuButton ~= nil then
                                    updateFCOISFilterButtonColorsAndTextures(2, gearSetSplitFilterContextMenuButton, nil, LF_INVENTORY)
                                    filterBasics(true)
                                end
                            end,
                            default = FCOISdefaultSettings.splitGearSetsFilter,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_split_resdecimp_filter"],
                            tooltip = locVars["options_split_resdecimp_filter" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.splitResearchDeconstructionImprovementFilter end,
                            setFunc = function(value) FCOISsettings.splitResearchDeconstructionImprovementFilter = value
                                --Change the gear sets filter context-menu button's texture
                                local resDecSplitFilterContextMenuButton = GetControl(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_RESDECIMP]) --wm:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_RESDECIMP], "")
                                if resDecSplitFilterContextMenuButton ~= nil then
                                    updateFCOISFilterButtonColorsAndTextures(3, resDecSplitFilterContextMenuButton, nil, LF_INVENTORY)
                                    filterBasics(true)
                                end
                            end,
                            default = FCOISdefaultSettings.splitResearchDeconstructionImprovementFilter,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_split_sellguildint_filter"],
                            tooltip = locVars["options_split_sellguildint_filter" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.splitSellGuildSellIntricateFilter end,
                            setFunc = function(value) FCOISsettings.splitSellGuildSellIntricateFilter = value
                                --Change the gear sets filter context-menu button's texture
                                local sellGuildIntSplitFilterContextMenuButton = GetControl(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT]) --wm:GetControlByName(FCOIS.ZOControlVars.FCOISfilterButtonNames[FCOIS_CON_FILTER_BUTTON_SELLGUILDINT], "")
                                if sellGuildIntSplitFilterContextMenuButton ~= nil then
                                    updateFCOISFilterButtonColorsAndTextures(4, sellGuildIntSplitFilterContextMenuButton, nil, LF_INVENTORY)
                                    filterBasics(true)
                                end
                            end,
                            default = FCOISdefaultSettings.splitSellGuildSellIntricateFilter,
                        },

                        {
                            type = "description",
                            text = locVars["options_filter_button_settings_logical_conjunctions"],
                        },

                        {
                            type = "checkbox",
                            name = locVars["options_filter_buttons_context_menu_show" .. tooltipSuffix],
                            tooltip = locVars["options_filter_buttons_context_menu_show_tooltip" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.showFilterButtonContextTooltip end,
                            setFunc = function(value) FCOISsettings.showFilterButtonContextTooltip = value
                            end,
                            disabled = function()
                                if     FCOISsettings.splitLockDynFilter == false
                                        and FCOISsettings.splitGearSetsFilter == false
                                        and FCOISsettings.splitResearchDeconstructionImprovementFilter == false
                                        and FCOISsettings.splitSellGuildSellIntricateFilter == false
                                then
                                    return true
                                else
                                    return false
                                end
                            end,
                            default = FCOISdefaultSettings.showFilterButtonContextTooltip,
                        },
                        {
                            type = "slider",
                            min  = 0,
                            max  = numDynIcons,
                            step = 1,
                            decimals = 0,
                            autoSelect = true,
                            name = locVars["options_context_menu_filter_buttons_max_icons"],
                            tooltip = locVars["options_context_menu_filter_buttons_max_icons" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.filterButtonContextMenuMaxIcons end,
                            setFunc = function(value)
                                FCOISsettings.filterButtonContextMenuMaxIcons = value
                            end,
                            disabled = function()
                                if     not FCOISsettings.splitLockDynFilter and not FCOISsettings.splitGearSetsFilter
                                        and not FCOISsettings.splitResearchDeconstructionImprovementFilter and not FCOISsettings.splitSellGuildSellIntricateFilter then
                                    return true
                                else
                                    return false
                                end
                            end,
                            default = FCOISdefaultSettings.filterButtonContextMenuMaxIcons,
                        },

                    } -- controls context menu at filter buttons
                }, -- submenu context menu at filter buttons

            } -- controls context menu
        }, -- submenu context menu

        --==============================================================================
        -- ADDITIONAL BUTTONS
        {
            type = "submenu",
            name = locVars["options_header_additional_buttons"],
            controls =
            {
                {
                    type = "checkbox",
                    name = locVars["options_additional_buttons_FCOIS_settings"],
                    tooltip = locVars["options_additional_buttons_FCOIS_settings" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showFCOISMenuBarButton end,
                    setFunc = function(value) FCOISsettings.showFCOISMenuBarButton = value
                        --FCOIS.AddAdditionalButtons("FCOSettings")
                    end,
                    disabled = function()
                        if VOTANS_MENU_SETTINGS and VOTANS_MENU_SETTINGS:IsMenuButtonEnabled() then
                            return true
                        else
                            return false
                        end
                    end,
                    default = FCOISdefaultSettings.showFCOISMenuBarButton,
                },
                {
                    type = "submenu",
                    name = locVars["options_additional_buttons_FCOIS_additional_options"],
                    helpUrl = strformat(addonFAQentry, tos(128)),
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_additional_buttons_FCOIS_additional_options"],
                            tooltip = locVars["options_additional_buttons_FCOIS_additional_options" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.showFCOISAdditionalInventoriesButton end,
                            setFunc = function(value) FCOISsettings.showFCOISAdditionalInventoriesButton = value
                                if value == false then
                                    --Change the button color of the context menu invoker
                                    changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
                                end
                                FCOIS.AddAdditionalButtons("FCOInventoriesContextMenuButtons")
                            end,
                            default = FCOISdefaultSettings.showFCOISAdditionalInventoriesButton,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_additional_buttons_FCOIS_additional_options_colorize"],
                            tooltip = locVars["options_additional_buttons_FCOIS_additional_options_colorize" .. tooltipSuffix],
                            getFunc = function() return FCOISsettings.colorizeFCOISAdditionalInventoriesButton end,
                            setFunc = function(value) FCOISsettings.colorizeFCOISAdditionalInventoriesButton = value
                                --Change the button color of the context menu invoker
                                changeContextMenuInvokerButtonColorByPanelId(LF_INVENTORY)
                            end,
                            disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
                            default = FCOISdefaultSettings.colorizeFCOISAdditionalInventoriesButton,
                        },
                        --[[
                    {
                        type = "slider",
                        min  = -500,
                        max  = 500,
                        step = 1,
                        decimals = 0,
                        autoSelect = true,
                        name = locVars["options_additional_buttons_FCOIS_additional_options_offsetx"],
                        tooltip = locVars["options_additional_buttons_FCOIS_additional_options_offsetx" .. tooltipSuffix],
                        getFunc = function() return FCOISsettings.FCOISAdditionalInventoriesButtonOffset.x end,
                        setFunc = function(value)
                            FCOISsettings.FCOISAdditionalInventoriesButtonOffset.x = value
                            --Update the additional inventory "flag" invoker button positions
                            reAnchorAdditionalInvButtons(true)
                        end,
                        disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
                        width = "half",
                        default = FCOISdefaultSettings.FCOISAdditionalInventoriesButtonOffset.x,
                    },
                   {
                       type = "slider",
                       min  = -500,
                       max  = 500,
                       step = 1,
                       decimals = 0,
                       autoSelect = true,
                       name = locVars["options_additional_buttons_FCOIS_additional_options_offsety"],
                       tooltip = locVars["options_additional_buttons_FCOIS_additional_options_offsety" .. tooltipSuffix],
                       getFunc = function() return FCOISsettings.FCOISAdditionalInventoriesButtonOffset.y end,
                       setFunc = function(value)
                           FCOISsettings.FCOISAdditionalInventoriesButtonOffset.y = value
                           --Update the additional inventory "flag" invoker button positions
                           reAnchorAdditionalInvButtons(true)
                       end,
                       disabled = function() return not FCOISsettings.showFCOISAdditionalInventoriesButton end,
                       width = "half",
                       default = FCOISdefaultSettings.FCOISAdditionalInventoriesButtonOffset.y,
                   },
]]
                        --Submenu with sliders for each filterPanelId to change the x and y offsets of the additional inventory context menu "flag" icon position
                        { -- Begin Submenu filter button position data
                            type = "submenu",
                            name = locVars["options_additional_buttons_FCOIS_additional_options_offsets"],
                            controls = addInvFlagButtonsPositionsSubMenu,
                        }, -- End submenu - Filter button position data

                    } -- controls additional buttons in inventories
                }, -- submenu  additional buttons in inventories

            } -- controls additional buttons
        }, -- submenu  additional buttons
        --==============================================================================
        -- CHARACTER
        {
            type = "submenu",
            name = locVars["options_header_character"],
            controls =
            {
                {
                    type = "checkbox",
                    name = locVars["options_tooltipatchar"],
                    tooltip = locVars["options_tooltipatchar" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showIconTooltipAtCharacter end,
                    setFunc = function(value) FCOISsettings.showIconTooltipAtCharacter = value
                    end,
                    default = FCOISdefaultSettings.showIconTooltipAtCharacter,
                },
                {
                    type = "header",
                    name = locVars["options_header_character_armor_type"],
                },
                {
                    type = "checkbox",
                    name = locVars["options_show_armor_type_icon"],
                    tooltip = locVars["options_show_armor_type_icon" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showArmorTypeIconAtCharacter end,
                    setFunc = function(value) FCOISsettings.showArmorTypeIconAtCharacter = value
                    end,
                    default = FCOISdefaultSettings.showArmorTypeIconAtCharacter,
                },
                {
                    type = "slider",
                    name = locVars["options_armor_type_icon_character_pos_x"],
                    tooltip = locVars["options_armor_type_icon_character_pos_x" .. tooltipSuffix],
                    min = -15,
                    max = 40,
                    autoSelect = true,
                    getFunc = function() return FCOISsettings.armorTypeIconAtCharacterX end,
                    setFunc = function(offset)
                        FCOISsettings.armorTypeIconAtCharacterX = offset
                        countAndUpdateEquippedArmorTypes()
                    end,
                    disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
                    width="half",
                    default = FCOISdefaultSettings.armorTypeIconAtCharacterX,
                },
                {
                    type = "slider",
                    name = locVars["options_armor_type_icon_character_pos_y"],
                    tooltip = locVars["options_armor_type_icon_character_pos_y" .. tooltipSuffix],
                    min = -15,
                    max = 40,
                    autoSelect = true,
                    getFunc = function() return FCOISsettings.armorTypeIconAtCharacterY end,
                    setFunc = function(offset)
                        FCOISsettings.armorTypeIconAtCharacterY = offset
                        countAndUpdateEquippedArmorTypes()
                    end,
                    disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
                    width="half",
                    default = FCOISdefaultSettings.armorTypeIconAtCharacterY,
                },
                {
                    type = "colorpicker",
                    name = locVars["options_armor_type_icon_character_light" .. colorSuffix],
                    tooltip = locVars["options_armor_type_icon_character_light" .. colorSuffix .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.armorTypeIconAtCharacterLightColor.r, FCOISsettings.armorTypeIconAtCharacterLightColor.g, FCOISsettings.armorTypeIconAtCharacterLightColor.b, FCOISsettings.armorTypeIconAtCharacterLightColor.a end,
                    setFunc = function(r,g,b,a)
                        FCOISsettings.armorTypeIconAtCharacterLightColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
                        countAndUpdateEquippedArmorTypes()
                    end,
                    width = "full",
                    disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
                    default = FCOISdefaultSettings.armorTypeIconAtCharacterLightColor,
                },
                {
                    type = "colorpicker",
                    name = locVars["options_armor_type_icon_character_medium" .. colorSuffix],
                    tooltip = locVars["options_armor_type_icon_character_medium" .. colorSuffix .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.armorTypeIconAtCharacterMediumColor.r, FCOISsettings.armorTypeIconAtCharacterMediumColor.g, FCOISsettings.armorTypeIconAtCharacterMediumColor.b, FCOISsettings.armorTypeIconAtCharacterMediumColor.a end,
                    setFunc = function(r,g,b,a)
                        FCOISsettings.armorTypeIconAtCharacterMediumColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
                        countAndUpdateEquippedArmorTypes()
                    end,
                    width = "full",
                    disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
                    default = FCOISdefaultSettings.armorTypeIconAtCharacterMediumColor,
                },
                {
                    type = "colorpicker",
                    name = locVars["options_armor_type_icon_character_heavy" .. colorSuffix],
                    tooltip = locVars["options_armor_type_icon_character_heavy" .. colorSuffix .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.armorTypeIconAtCharacterHeavyColor.r, FCOISsettings.armorTypeIconAtCharacterHeavyColor.g, FCOISsettings.armorTypeIconAtCharacterHeavyColor.b, FCOISsettings.armorTypeIconAtCharacterHeavyColor.a end,
                    setFunc = function(r,g,b,a)
                        FCOISsettings.armorTypeIconAtCharacterHeavyColor = {["r"] = r, ["g"] = g, ["b"] = b, ["a"] = a}
                        countAndUpdateEquippedArmorTypes()
                    end,
                    width = "full",
                    disabled = function() return not FCOISsettings.showArmorTypeIconAtCharacter end,
                    default = FCOISdefaultSettings.armorTypeIconAtCharacterHeavyColor,
                },
                {
                    type = "checkbox",
                    name = locVars["options_show_armor_type_header_text"],
                    tooltip = locVars["options_show_armor_type_header_text" .. tooltipSuffix],
                    getFunc = function() return FCOISsettings.showArmorTypeHeaderTextAtCharacter end,
                    setFunc = function(value) FCOISsettings.showArmorTypeHeaderTextAtCharacter = value
                    end,
                    default = FCOISdefaultSettings.showArmorTypeHeaderTextAtCharacter,
                },
            } -- controls character
        }, -- submenu chracter
        --=============================================================================================
        -- BACKUP & RESTORE & Delete
        {
            type = "submenu",
            name = locVars["options_header_backup_and_restore_and_delete"],
            controls =
            {
                --Marker icons backup
                {
                    type = "header",
                    name = locVars["options_header_marking_options"],
                },
                {
                    type = "submenu",
                    name = locVars["options_backup_marker_icons"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_backup_details"],
                            tooltip = locVars["options_backup_details" .. tooltipSuffix],
                            getFunc = function() return fcoBackup.withDetails end,
                            setFunc = function(value) fcoBackup.withDetails = value
                            end,
                            default = fcoBackup.withDetails,
                        },
                        {
                            type = "editbox",
                            name = locVars["options_backup_apiversion"],
                            tooltip = locVars["options_backup_apiversion" .. tooltipSuffix],
                            textType = TEXT_TYPE_NUMERIC,
                            getFunc = function() return fcoBackup.apiVersion end,
                            setFunc = function(value)
                                local resetToCurrentAPI = false
                                if value ~= "" then
                                    --String only contains numbers -> Does not contain alphanumeric characters (%w = alphanumeric characters, uppercase W = unequals w)
                                    local strLen = strlen(value)
                                    local apiLength = FCOIS.APIVersionLength
                                    local numValue = ton(value)
                                    local onlyDigits = (numValue ~= nil and numValue > 0) or false
                                    --Input text is >= API version length
                                    if strLen == apiLength then
                                        --API version text only contains numbers?
                                        if onlyDigits then
                                            fcoBackup.apiVersion = value
                                        else
                                            resetToCurrentAPI = true
                                        end
                                    elseif strLen > apiLength then
                                        resetToCurrentAPI = true
                                    end
                                else
                                    --Preset the empty edit field with current API version
                                    resetToCurrentAPI = true
                                end
                                --Reset the edit field to current API version due to false entries?
                                if resetToCurrentAPI then
                                    value = resetBackupEditToCurrentAPI()
                                end
                            end,
                            reference = "FCOITEMSAVER_SETTINGS_BACKUP_API_VERSION_EDIT",
                            default = apiVersion,
                        },
                        {
                            type = "checkbox",
                            name = locVars["options_backup_clear"],
                            tooltip = locVars["options_backup_clear" .. tooltipSuffix],
                            getFunc = function() return fcoBackup.doClearBackup end,
                            setFunc = function(value) fcoBackup.doClearBackup = value
                            end,
                            default = fcoBackup.doClearBackup,
                        },
                        --Backup the marker icons with the help of the unique IDs of each item now!
                        {
                            type = "button",
                            name = locVars["options_backup_marker_icons"],
                            tooltip = locVars["options_backup_marker_icons" .. tooltipSuffix],
                            func = function()
                                --Check the backup API version edit text and content
                                if isBackupEditAPITextTooShort() then
                                    resetBackupEditToCurrentAPI()
                                end
                                local title = locVars["options_backup_marker_icons"] .. " - API "
                                local body = locVars["options_backup_marker_icons_warning"]
                                --Show confirmation dialog
                                showConfirmationDialog("BackupMarkerIconsDialog",
                                        title .. tos(fcoBackup.apiVersion),
                                        body,
                                        function() FCOIS.PreBackup(fcoBackup.withDetails, fcoBackup.apiVersion, fcoBackup.doClearBackup) end,
                                        nil, nil, nil, true)
                                --backupType, withDetails, apiVersion, doClearBackup
                                --FCOIS.preBackup("unique", fcoBackup.withDetails, fcoBackup.apiVersion, fcoBackup.doClearBackup)
                            end,
                            --isDangerous = true,
                            disabled = function() return false end,
                            warning = locVars["options_backup_marker_icons_warning"],
                            width="half",
                        },
                    },
                },
                {
                    type = "submenu",
                    name = locVars["options_restore_marker_icons"],
                    controls =
                    {
                        {
                            type = "checkbox",
                            name = locVars["options_restore_details"],
                            tooltip = locVars["options_restore_details" .. tooltipSuffix],
                            getFunc = function() return fcoRestore.withDetails end,
                            setFunc = function(value) fcoRestore.withDetails = value
                            end,
                            default = fcoRestore.withDetails,
                        },
                        {
                            type = 'dropdown',
                            name = locVars["options_restore_apiversion"],
                            tooltip = locVars["options_restore_apiversion" .. tooltipSuffix],
                            choices = restoreChoices,
                            choicesValues = restoreChoicesValues,
                            getFunc = function() return fcoRestore.apiVersion end,
                            setFunc = function(value)
                                fcoRestore.apiVersion = value
                            end,
                            reference = "FCOITEMSAVER_SETTINGS_RESTORE_API_VERSION_DROPDOWN",
                            default = apiVersion,
                        },
                        --Restore the marker icons with the help of the unique IDs of each item now!
                        {
                            type = "button",
                            name = locVars["options_restore_marker_icons"],
                            tooltip = locVars["options_restore_marker_icons" .. tooltipSuffix],
                            func = function()
                                if fcoRestore.apiVersion ~= nil then
                                    --(restoreType, withDetails, apiVersion)
                                    --FCOIS.RestoreMarkerIcons("unique", fcoRestore.withDetails, fcoRestore.apiVersion)
                                    local title = locVars["options_restore_marker_icons"] .. " - API "
                                    local body = locVars["options_restore_marker_icons_warning"]
                                    --Show confirmation dialog
                                    showConfirmationDialog("RestoreMarkerIconsDialog",
                                            title .. tos(fcoRestore.apiVersion),
                                            body,
                                            function() FCOIS.PreRestore(fcoRestore.withDetails, fcoRestore.apiVersion) end,
                                            nil, nil, nil, true)
                                end
                            end,
                            --isDangerous = false,
                            disabled = function() return (fcoRestore.apiVersion == nil or #restoreChoicesValues == 0) or false end,
                            warning = locVars["options_restore_marker_icons_warning"],
                            width="half",
                        },
                        --Delete the selected backup data
                        {
                            type = "button",
                            name = locVars["options_restore_marker_icons_delete_selected"],
                            tooltip = locVars["options_restore_marker_icons_delete_selected" .. tooltipSuffix],
                            func = function()
                                if fcoRestore.apiVersion ~= nil then
                                    local title = locVars["options_restore_marker_icons_delete_selected"] .. " - API "
                                    local body = locVars["options_restore_marker_icons_delete_selected_warning2"]
                                    --Show confirmation dialog
                                    showConfirmationDialog("DeleteRestoreMarkerIconsDialog",
                                            title .. tos(fcoRestore.apiVersion),
                                            body,
                                            function() FCOIS.DeleteBackup(fcoRestore.apiVersion) end,
                                            nil, nil, nil, true)
                                end
                            end,
                            isDangerous = true,
                            disabled = function() return (fcoRestore.apiVersion == nil or #restoreChoicesValues == 0) or false end,
                            warning = locVars["options_restore_marker_icons_delete_selected_warning"],
                            width="half",
                            reference = "FCOITEMSAVER_SETTINGS_DELETE_API_VERSION_BUTTON",
                        },
                    },
                },
                -- Marker icons delete
                {
                    type = "submenu",
                    name = locVars["options_delete_marker_icons_header"],
                    controls = {
                        {
                            type = "description",
                            text = locVars["options_delete_marker_icons_desc"],
                        },
                        --Select the marker icons to delete dropdown
                        {
                            type = 'dropdown',
                            name = locVars["options_icon1_texture"],
                            tooltip = locVars["options_icon1_texture"],
                            choices = iconsListWithAllEntry,
                            choicesValues = iconsListWithAllEntryValues,
                            getFunc = function() return markerIconsToDeleteIcon end,
                            setFunc = function(value)
                                markerIconsToDeleteIcon = value
                                checkIfMarkerIconsToDeleteExist()
                            end,
                            reference = "FCOITEMSAVER_SETTINGS_DELETE_MARKER_ICON_DROPDOWN",
                            default = markerIconsToDeleteIcon,
                        },
                        --Select the marker icons type to delete dropdown
                        {
                            type = 'dropdown',
                            name = locVars["options_delete_marker_icons"],
                            tooltip = locVars["options_delete_marker_icons" .. tooltipSuffix],
                            choices = markerIconTypeChoices,
                            choicesValues = markerIconTypeChoicesValues,
                            getFunc = function() return markerIconsToDeleteType end,
                            setFunc = function(value)
                                markerIconsToDeleteType = value
                                checkIfMarkerIconsToDeleteExist()
                            end,
                            reference = "FCOITEMSAVER_SETTINGS_DELETE_MARKER_ICON_TYPE_DROPDOWN",
                            default = markerIconsToDeleteType,
                        },
                        --Delete the selected marker icons button
                        {
                            type = "button",
                            name = locVars["options_delete_marker_icons_button"],
                            tooltip = locVars["options_delete_marker_icons_button" .. tooltipSuffix],
                            func = function()
                                local isAllIcons = (markerIconsToDeleteIcon == FCOIS_CON_ICON_ALL) or false
                                if (numIconsToDelete > 0 or isAllIcons) or markerIconsToDeleteIcon ~= nil and markerIconsToDeleteIcon ~= 0
                                        and markerIconsToDeleteType ~= nil and markerIconsToDeleteType ~= noneEntryValue then
                                    local numIconsStr = ""
                                    if not isAllIcons then
                                        numIconsStr = " #" ..tos(numIconsToDelete)
                                    end
                                    local markerIconsToDeleteTypeStr = (type(markerIconsToDeleteType) == "number" and uniqueItemIdTypeChoices[markerIconsToDeleteType]) or (locVars["options_non_unique_id"] .. "/" .. uniqueItemIdTypeChoices[FCOIS_CON_UNIQUE_ITEMID_TYPE_REALLY_UNIQUE])
                                    local title = locVars["options_delete_marker_icons_button"]
                                    local body = locVars["options_delete_marker_icons_warning2"]
                                    local selectedIconName = FCOITEMSAVER_SETTINGS_DELETE_MARKER_ICON_DROPDOWN.combobox.m_comboBox.m_selectedItemText:GetText()
                                    --Show confirmation dialog
                                    showConfirmationDialog("DeleteMarkerIconsDialog",
                                            title .. " " .. tos(markerIconsToDeleteTypeStr),
                                            body .. "\nIcon: " ..tos(selectedIconName) .. tos(numIconsStr),
                                            function() FCOIS.DeleteMarkerIcons(markerIconsToDeleteType, markerIconsToDeleteIcon) end,
                                            nil, nil, nil, true)
                                end
                            end,
                            isDangerous = true,
                            disabled = function()
                                if not markerIconsToDeleteIcon or markerIconsToDeleteIcon == 0 then return true end
                                local isAllIcons = (markerIconsToDeleteIcon == FCOIS_CON_ICON_ALL) or false
                                return ((numIconsToDelete <= 0 and not isAllIcons) or markerIconsToDeleteType == nil or markerIconsToDeleteType == noneEntryValue) or false
                            end,
                            warning = locVars["options_delete_marker_icons_warning"],
                            width="half",
                        },
                    }
                },

            }, -- backup & restore controls
        }, -- backup & restore submenu
        --======================================================================================================================
        --Copy savedvars
        {
            type = "submenu",
            name = locVars["options_header_copy_sv"],
            controls =
            {
                --from server to server
                {
                    type = 'description',
                    text = locVars["options_description_copy_sv_server"],
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_source_server"],
                    tooltip = locVars["options_copy_sv_source_server"],
                    choices = serverOptions,
                    choicesValues = serverOptionsValues,
                    getFunc = function()
                        return srcServer
                    end,
                    setFunc = function(value)
                        if not doNotRunDropdownValueSetFunc then
                            srcServer = value
                            reBuildAccountOptions(true)
                        end
                        srcServer = value
                    end,
                    width = "half",
                    default = srcServer,
                    reference = "FCOItemSaver_Settings_Copy_SV_Src_Server"
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_target_server"],
                    tooltip = locVars["options_copy_sv_target_server"],
                    choices = serverOptionsTarget,
                    choicesValues = serverOptionsValuesTarget,
                    getFunc = function()
                        return targServer
                    end,
                    setFunc = function(value)
                        if not doNotRunDropdownValueSetFunc then
                            targServer = value
                            reBuildAccountOptions(false)
                        end
                        targServer = value
                    end,
                    width = "half",
                    default = targServer,
                    reference = "FCOItemSaver_Settings_Copy_SV_Targ_Server"
                },
                --[[
                {
                    type = "button",
                    name = locVars["options_copy_sv_to_server"],
                    tooltip = locVars["options_copy_sv_to_server" .. tooltipSuffix],
                    func = function()
                        local srcServerNameClean = cleanName(serverOptionsTarget[srcServer], "server")
                        local targServerNameClean = cleanName(serverOptionsTarget[targServer], "server")
                        FCOIS.copySavedVars(srcServerNameClean, targServerNameClean, nil, nil, nil, nil, false)
                        reBuildServerOptions()
                        reBuildAccountOptions()
                        reBuildCharacterOptions()
                    end,
                    isDangerous = true,
                    disabled = function()
                        return (FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound) or (srcServer == noEntryValue or targServer == noEntryValue or srcServer == targServer)
                    end,
                    warning = locVars["options_copy_sv_to_server_warning"],
                    width = "half",
                },
                {
                    type = "button",
                    name = locVars["options_delete_sv_on_server"],
                    tooltip = locVars["options_delete_sv_on_server" .. tooltipSuffix],
                    func = function()
                        local srcServerNameClean = cleanName(serverOptionsTarget[srcServer], "server")
                        local targServerNameClean = cleanName(serverOptionsTarget[targServer], "server")
                        FCOIS.copySavedVars(srcServerNameClean, targServerNameClean, nil, nil, nil, nil, true)
                        reBuildServerOptions()
                        reBuildAccountOptions()
                        reBuildCharacterOptions()
                    end,
                    isDangerous = true,
                    disabled = function()
                        local targetServerName = serverNames[targServer]
                        if (FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound)
                                or (targServer == noEntryValue or targetServerName == currentServerNameMarked)
                                or (targServer ~= noEntryValue and FCOItemSaver_Settings[targetServerName] == nil)
                        then
                            return true
                        end
                        return false
                    end,
                    warning = locVars["options_delete_sv_on_server" .. tooltipSuffix],
                    width = "half",
                },
                ]]
                --from account to (all)account
                {
                    type = 'description',
                    text = locVars["options_description_copy_sv_account"],
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_source_account"],
                    tooltip = locVars["options_copy_sv_source_account"],
                    choices = accountSrcOptions,
                    choicesValues = accountSrcOptionsValues,
                    getFunc = function()
                        return srcAcc
                    end,
                    setFunc = function(value)
                        srcAcc = value
                        if not doNotRunDropdownValueSetFunc then
                            reBuildCharacterOptions(true)
                        end
                    end,
                    width = "half",
                    default = srcAcc,
                    disabled = function()
                        return srcServer == noEntryValue
                    end,
                    reference = "FCOItemSaver_Settings_Copy_SV_Src_Acc"
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_target_account"],
                    tooltip = locVars["options_copy_sv_target_account"],
                    choices = accountTargOptions,
                    choicesValues = accountTargOptionsValues,
                    getFunc = function()
                        return targAcc
                    end,
                    setFunc = function(value)
                        targAcc = value
                        if not doNotRunDropdownValueSetFunc then
                            reBuildCharacterOptions(false)
                        end
                    end,
                    width = "half",
                    default = targAcc,
                    disabled = function()
                        return targServer == noEntryValue
                    end,
                    reference = "FCOItemSaver_Settings_Copy_SV_Targ_Acc"
                },
                --Copy SV account
                {
                    type = "button",
                    name = locVars["options_copy_sv_to_account"],
                    tooltip = locVars["options_copy_sv_to_account" .. tooltipSuffix],
                    func = function()
                        if FCOISsettings.remindUserAboutSavedVariablesBackup == true then
                            showRememberUserAboutSavedVariablesBackupDialog()
                        else
                            local srcServerNameClean = cleanName(serverOptionsTarget[srcServer], "server")
                            local targServerNameClean = cleanName(serverOptionsTarget[targServer], "server")
                            local srcAccNameClean = cleanName(serverOptionsTarget[srcAcc], "account", srcAcc)
                            local targAccNameClean = cleanName(serverOptionsTarget[targAcc], "account", targAcc)
                            copySavedVars(srcServerNameClean, targServerNameClean, srcAccNameClean, targAccNameClean,  nil, nil, false)
                            reBuildAccountOptions()
                            reBuildCharacterOptions()
                        end
                    end,
                    isDangerous = true,
                    disabled = function()
                        local srcServerName = serverNames[srcServer]
                        --local targetServerName = serverNames[targServer]
                        local targetAccName = accountTargOptions[targAcc]
                        --local targetAccNameClean = cleanName(targetAccName, "account", targAcc)
                        local srcAccNameClean = cleanName(serverOptionsTarget[srcAcc], "account", srcAcc)

                        if ((FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound)
                                or (srcServer == noEntryValue or targServer == noEntryValue or srcAcc == noEntryValue or targAcc == noEntryValue)
                                or (FCOItemSaver_Settings[srcServerName] == nil or FCOItemSaver_Settings[srcServerName][srcAccNameClean] == nil)
                        ) then
                            return true
                        else
                            --Source server and account + target server & account are the same?
                            --Only allow this if the source character is chosen and no target character is chosen!
                            -->To copy source server + account + character to target server + account
                            if srcServer == targServer and srcAcc == targAcc then
                                if srcChar == noEntryValue or targChar ~= noEntryValue then return true end
                            end
                        end
                        return false
                    end,
                    warning = locVars["options_copy_sv_to_server_warning"],
                    width = "half",
                    reference = "FCOItemSaver_Settings_Copy_SV_Targ_Acc_Button_Copy"
                },
                --Delete SV account
                {
                    type = "button",
                    name = locVars["options_delete_sv_account"],
                    tooltip = locVars["options_delete_sv_account" .. tooltipSuffix],
                    func = function()
                        if FCOISsettings.remindUserAboutSavedVariablesBackup == true then
                            showRememberUserAboutSavedVariablesBackupDialog()
                        else
                            local srcServerNameClean = cleanName(serverOptionsTarget[srcServer], "server")
                            local targServerNameClean = cleanName(serverOptionsTarget[targServer], "server")
                            local srcAccNameClean = cleanName(serverOptionsTarget[srcAcc], "account", srcAcc)
                            local targAccNameClean = cleanName(serverOptionsTarget[targAcc], "account", targAcc)
                            local forceReloadUI = false
                            FCOIS.worldName = FCOIS.worldName or GetWorldName()
                            if targServerNameClean == FCOIS.worldName and targAccNameClean == currentAccountName then forceReloadUI = true end
                            copySavedVars(srcServerNameClean, targServerNameClean, srcAccNameClean, targAccNameClean,  nil, nil, true, forceReloadUI)
                            reBuildAccountOptions()
                            reBuildCharacterOptions()
                        end
                    end,
                    isDangerous = true,
                    disabled = function()
                        local targetServerName = serverNames[targServer]
                        local targetAccName = accountTargOptions[targAcc]
                        local targetAccNameClean = cleanName(targetAccName, "account", targAcc)
                        if ((FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound)
                                or (targServer == noEntryValue or targAcc == noEntryValue)
                                or ( targServer ~= noEntryValue and targAcc ~= noEntryValue
                                and (
                                FCOItemSaver_Settings[targetServerName] == nil or FCOItemSaver_Settings[targetServerName][targetAccNameClean] == nil
                        )
                        )
                        ) then
                            return true
                        end
                        return false
                    end,
                    warning = locVars["options_delete_sv_account" .. tooltipSuffix],
                    width = "half",
                },
                --Copy SV to AllServersAndAllAccounts the same
                {
                    type = "button",
                    name = locVars["options_copy_sv_to_allserversallaccount"],
                    tooltip = locVars["options_copy_sv_to_allserversallaccount" .. tooltipSuffix],
                    func = function()
                        if FCOISsettings.remindUserAboutSavedVariablesBackup == true then
                            showRememberUserAboutSavedVariablesBackupDialog()
                        else
                            local srcServerNameClean = cleanName(serverOptionsTarget[srcServer], "server")
                            local srcAccNameClean = cleanName(serverOptionsTarget[srcAcc], "account", srcAcc)
                            copySavedVars(srcServerNameClean, nil, srcAccNameClean, nil, nil, nil, false, true, true)
                        end
                    end,
                    isDangerous = true,
                    disabled = function()
                        local srcServerName = serverNames[srcServer]
                        local srcAccNameClean = cleanName(serverOptionsTarget[srcAcc], "account", srcAcc)
                        if ((FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound)
                                or (srcServer == noEntryValue or srcAcc == noEntryValue)
                                or (FCOItemSaver_Settings[srcServerName] == nil or FCOItemSaver_Settings[srcServerName][srcAccNameClean] == nil)
                        ) then
                            return true
                        end
                        return false
                    end,
                    warning = locVars["options_copy_sv_to_allserversallaccount_warning"],
                    width = "half",
                    reference = "FCOItemSaver_Settings_Copy_SV_To_AllServersndAccountsTheSame_Button_Copy"
                },
                --Delete SV AllServersAndAllAccounts the same
                {
                    type = "button",
                    name = locVars["options_delete_sv_allserversallaccount"],
                    tooltip = locVars["options_delete_sv_allserversallaccount" .. tooltipSuffix],
                    func = function()
                        if FCOISsettings.remindUserAboutSavedVariablesBackup == true then
                            showRememberUserAboutSavedVariablesBackupDialog()
                        else
                            copySavedVars(nil, nil, nil, nil, nil, nil, true, true, true)
                        end
                    end,
                    isDangerous = true,
                    disabled = function()
                        return FCOItemSaver_Settings[svAllServersTheSame] == nil or FCOItemSaver_Settings[svAllServersTheSame][svAllAccTheSameAcc] == nil
                    end,
                    warning = locVars["options_delete_sv_allserversallaccount" .. tooltipSuffix],
                    width = "half",
                },

                --from character to character
                {
                    type = 'description',
                    text = locVars["options_description_copy_sv_character"],
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_source_character"],
                    tooltip = locVars["options_copy_sv_source_character"],
                    choices = characterSrcOptions,
                    choicesValues = characterSrcOptionsValues,
                    getFunc = function()
                        return srcChar
                    end,
                    setFunc = function(value)
                        srcChar = value
                        if FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button ~= nil and FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button ~= nil then
                            if targChar == noEntryValue then
                                --Copy character to account
                                FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button:SetText(locVars["options_copy_sv_account_to_char"])
                            else
                                if srcChar ~= noEntryValue and targChar ~= noEntryValue then
                                    --Copy character to character
                                    FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button:SetText(locVars["options_copy_sv_to_character"])
                                else
                                    --Copy character to account
                                    FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button:SetText(locVars["options_copy_sv_account_to_char"])
                                end
                            end
                        end
                        if FCOItemSaver_Settings_Copy_SV_Targ_Acc_Button_Copy ~= nil and FCOItemSaver_Settings_Copy_SV_Targ_Acc_Button_Copy.button ~= nil then
                            if srcChar ~= noEntryValue and targChar == noEntryValue then
                                --Copy character to account
                                FCOItemSaver_Settings_Copy_SV_Targ_Acc_Button_Copy.button:SetText(locVars["options_copy_sv_char_to_account"])
                            else
                                --Copy character to character
                                FCOItemSaver_Settings_Copy_SV_Targ_Acc_Button_Copy.button:SetText(locVars["options_copy_sv_to_account"])
                            end
                        end
                    end,
                    scrollable = true,
                    sort = "name-up",
                    width = "half",
                    default = srcChar,
                    disabled = function()
                        return srcServer == noEntryValue or srcAcc == noEntryValue or srcAcc == noEntryValue + 2
                    end,
                    reference = "FCOItemSaver_Settings_Copy_SV_Src_Char"
                },
                {
                    type = 'dropdown',
                    name = locVars["options_copy_sv_target_character"],
                    tooltip = locVars["options_copy_sv_target_character"],
                    choices = characterTargOptions,
                    choicesValues = characterTargOptionsValues,
                    getFunc = function()
                        return targChar
                    end,
                    setFunc = function(value)
                        targChar = value
                        if FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button ~= nil and FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button ~= nil then
                            if targChar == noEntryValue then
                                --Copy character to account
                                FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button:SetText(locVars["options_copy_sv_account_to_char"])
                            else
                                if srcChar ~= noEntryValue and targChar ~= noEntryValue then
                                    --Copy character to character
                                    FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button:SetText(locVars["options_copy_sv_to_character"])
                                else
                                    --Copy character to account
                                    FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button.button:SetText(locVars["options_copy_sv_account_to_char"])
                                end
                            end
                        end
                    end,
                    scrollable = true,
                    sort = "name-up",
                    width = "half",
                    default = targChar,
                    disabled = function()
                        return targServer == noEntryValue or targAcc == noEntryValue or targAcc == noEntryValue + 2
                    end,
                    reference = "FCOItemSaver_Settings_Copy_SV_Targ_Char"
                },
                {
                    type = "button",
                    name = locVars["options_copy_sv_account_to_char"],
                    tooltip = locVars["options_copy_sv_to_character" .. tooltipSuffix],
                    func = function()
                        if FCOISsettings.remindUserAboutSavedVariablesBackup == true then
                            showRememberUserAboutSavedVariablesBackupDialog()
                        else
                            local srcServerNameClean = cleanName(serverOptionsTarget[srcServer], "server")
                            local targServerNameClean = cleanName(serverOptionsTarget[targServer], "server")
                            local srcAccNameClean = cleanName(serverOptionsTarget[srcAcc], "account", srcAcc)
                            local targAccNameClean = cleanName(serverOptionsTarget[targAcc], "account", targAcc)
                            --Copy account -> target character?
                            if srcChar == nil or srcChar == "" then
                                copySavedVars(srcServerNameClean, targServerNameClean, srcAccNameClean, targAccNameClean,  tos(srcChar), tos(targChar), false)
                            else
                                --Copy source char -> target char
                                copySavedVars(srcServerNameClean, targServerNameClean, srcAccNameClean, targAccNameClean,  nil, tos(targChar), false)
                            end
                            reBuildCharacterOptions()
                        end
                    end,
                    isDangerous = true,
                    disabled = function()
                        return ((FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound)
                                or (srcServer == noEntryValue or targServer == noEntryValue
                                or srcAcc == noEntryValue or targAcc == noEntryValue
                                or targChar == noEntryValue --or srcChar == noEntryValue -> Needed since FCOIS v1.9.6: Copy account to char settings
                                or (srcServer == targServer and srcAcc == targAcc and srcChar == targChar)))
                    end,
                    warning = locVars["options_copy_sv_to_server_warning"],
                    width = "half",
                    reference = "FCOItemSaver_Settings_Copy_SV_Targ_Char_Copy_Button"
                },

                {
                    type = "button",
                    name = locVars["options_delete_sv_character"],
                    tooltip = locVars["options_delete_sv_character" .. tooltipSuffix],
                    func = function()
                        if FCOISsettings.remindUserAboutSavedVariablesBackup == true then
                            showRememberUserAboutSavedVariablesBackupDialog()
                        else
                            local srcServerNameClean = cleanName(serverOptionsTarget[srcServer], "server")
                            local targServerNameClean = cleanName(serverOptionsTarget[targServer], "server")
                            local srcAccNameClean = cleanName(serverOptionsTarget[srcAcc], "account", srcAcc)
                            local targAccNameClean = cleanName(serverOptionsTarget[targAcc], "account", targAcc)
                            local forceReloadUI = false
                            FCOIS.worldName = FCOIS.worldName or GetWorldName()
                            if targServerNameClean == FCOIS.worldName and targAccNameClean == currentAccountName and tos(targChar) == currentCharacterId then forceReloadUI = true end
                            copySavedVars(srcServerNameClean, targServerNameClean, srcAccNameClean, targAccNameClean,  tos(srcChar), tos(targChar), true, forceReloadUI)
                            reBuildCharacterOptions()
                        end
                    end,
                    isDangerous = true,
                    disabled = function()
                        local targetServerName = serverNames[targServer]
                        local targetAccName = accountTargOptions[targAcc]
                        local targetAccNameClean = cleanName(targetAccName, "account", targAcc)
                        if ((FCOIS.settingsNonServerDependendFound and FCOIS.defSettingsNonServerDependendFound)
                                or (targServer == noEntryValue or targAcc == noEntryValue or targChar == noEntryValue)
                                or ((targServer ~= noEntryValue and targAcc ~= noEntryValue and targChar ~= noEntryValue)
                                and (FCOItemSaver_Settings[targetServerName] == nil or FCOItemSaver_Settings[targetServerName][targetAccNameClean] == nil or FCOItemSaver_Settings[targetServerName][targetAccNameClean][tos(targChar)] == nil)))
                        then
                            return true
                        end
                        return false
                    end,
                    warning = locVars["options_delete_sv_character" .. tooltipSuffix],
                    width = "half",
                },
            }, --controls copy savedvars
        }, --submenu copy savedvars


    } -- END OF OPTIONS TABLE
    cm:RegisterCallback("LAM-PanelControlsCreated", FCOLAMPanelCreated)
    --cm:RegisterCallback("LAM-RefreshPanel", FCOLAMPanelRefreshed)
    cm:RegisterCallback("LAM-PanelOpened", FCOLAMPanelOpened)
    cm:RegisterCallback("LAM-PanelClosed", FCOLAMPanelClosed)


    FCOIS.LAM:RegisterOptionControls(FCOISLAMPanelName, optionsTable)
    --Show the LibFeedback icon top right at the LAM panel
    -->With LAM r27 moved to the LAM feedback link!
    --[[
    local origLAMOnEffectivelyShownHandler = FCOItemSaver_LAM:GetHandler("OnEffectivelyShown")
    FCOItemSaver_LAM:SetHandler("OnEffectivelyShown", function(...)
        if origLAMOnEffectivelyShownHandler ~= nil then
            origLAMOnEffectivelyShownHandler(...)
        end
        FCOIS.toggleFeedbackButton(true)
    end)
    --Hide the LibFeedBack icon
    local origLAMOnEffectivelyHiddenHandler = FCOItemSaver_LAM:GetHandler("OnEffectivelyHidden")
    FCOItemSaver_LAM:SetHandler("OnEffectivelyHidden", function(...)
        if origLAMOnEffectivelyHiddenHandler ~= nil then
            origLAMOnEffectivelyHiddenHandler(...)
        end
        FCOIS.toggleFeedbackButton(false)
    end)
    ]]
end
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~