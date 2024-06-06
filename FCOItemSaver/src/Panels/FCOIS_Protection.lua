--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local tos = tostring
local tins = table.insert
local gil = GetItemLink

local debugMessage = FCOIS.debugMessage

local numFilterIcons = FCOIS.numVars.gFCONumFilterIcons
local ctrlVars = FCOIS.ZOControlVars
local deconstructionBag = ctrlVars.DECONSTRUCTION_BAG
local alchemyStation = ctrlVars.ALCHEMY_STATION
local enchantingStation = ctrlVars.ENCHANTING_STATION
local reagentSlotNamePrefix = ctrlVars.ALCHEMY_REAGENT_SLOT_NAME_PREFIX --ZO_AlchemyTopLevelSlotContainerReagentSlot

local checkVars = FCOIS.checkVars
local allowedCheckHandlers = checkVars.checkHandlers

local callItemSelectionHandler
local universalDeconFilterPanelIdToWhereAreWe = FCOIS.mappingVars.universalDeconFilterPanelIdToWhereAreWe

local getSavedVarsMarkedItemsTableName = FCOIS.GetSavedVarsMarkedItemsTableName
local signItemId = FCOIS.SignItemId
local myGetItemInstanceIdNoControl = FCOIS.MyGetItemInstanceIdNoControl
local isItemOrnate = FCOIS.IsItemOrnate
local checkIfFilterPanelIsDeconstructable = FCOIS.CheckIfFilterPanelIsDeconstructable
local checkIfDeconstructionNPC
local isSendingMail = FCOIS.IsSendingMail

local isResearchListDialogShown = FCOIS.IsResearchListDialogShown
local isRetraitStationShown = FCOIS.IsRetraitStationShown
local isItemAGlpyh = FCOIS.IsItemAGlpyh

local checkIfUniversaldDeconstructionNPC
local checkActivePanel
local isVendorPanelShown
local getWhereAreWe

local FCOIScdsh = FCOIS.callDeconstructionSelectionHandler

--===================================================================================
--	FCOIS Anti - *  - Methods to check if item is protected, or allowed to be ...
--===================================================================================

--Show an alert message
function FCOIS.ShowAlert(alertMsg)
    ZO_Alert(UI_ALERT_CATEGORY_ERROR, SOUNDS.NEGATIVE_CLICK, FCOIS.preChatVars.preChatTextRed .. alertMsg)
end
local showAlert = FCOIS.ShowAlert

--Function to show an chat error message and/or alert message that the item is protected
--Check if alert or chat message should be shown
function FCOIS.OutputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
    --d("[FCOIS]outputItemProtectedMessage - bag: " .. tos(bag) .. ", slot: " .. tos(slot) .. ", whereAreWe: " .. tos(whereAreWe) ..", overrideChatOutput: " .. tos(overrideChatOutput) .. ", suppressChatOutput: " .. tos(suppressChatOutput) .. ", overrideAlert: " .. tos(overrideAlert) .. ", suppressAlert: " .. tos(suppressAlert))
    if bag == nil or slot == nil then return false end
    if whereAreWe == nil then return false end
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    local retVar = false
    local settings = FCOIS.settingsVars.settings
    --Chat and/or alert message are enbaled or overwriting the settings is active?
    local chatOutputWished = not suppressChatOutput and (overrideChatOutput or settings.showAntiMessageInChat == true)
    local alertOutputWished = not suppressAlert and (overrideAlert or settings.showAntiMessageAsAlert == true)
    if chatOutputWished or alertOutputWished then
        --Get the itemLink
        local formattedItemName = gil(bag, slot)
        --Get the "whereAreWe" message text
        local whereAreWeToAlertmessageText = FCOIS.mappingVars.whereAreWeToAlertmessageText
        local whereAreWeMsgText = whereAreWeToAlertmessageText[whereAreWe] or "ERROR: Not allowed!"
        --d("whereAreWeMsgText: " .. tos(whereAreWeMsgText))
        --Build the protected message text
        local protectedMsg = whereAreWeMsgText .. " [" .. formattedItemName .. "]"
        --Show the message in the chat window?
        if chatOutputWished then
            d(protectedMsg)
            retVar = true
        end
        --Show the message as alert message at the top-right corner?
        if alertOutputWished then
            showAlert(protectedMsg)
            retVar = true
        end
    end
    return retVar
end
local outputItemProtectedMessage = FCOIS.OutputItemProtectedMessage

--Check the filterPanelId and if it should be protected against destroy, even if the currently protectedSettings are
--different than "Anti destroy", and then set the anti-destroy value to "on" so it always is blocked
function FCOIS.CheckFilterPanelForAlwaysOnDestroyProtection(filterPanelId)
--d(">CheckFilterPanelForAlwaysOnDestroyProtection")
    local filterPanelToAlwaysOnAntiDestroySetings = checkVars.filterPanelIdsForAntiDestroySettingsAlwaysOn
    local isProtectedDestroyIcon = filterPanelToAlwaysOnAntiDestroySetings[filterPanelId] or false
    return isProtectedDestroyIcon
end
local checkFilterPanelForAlwaysOnDestroyProtection = FCOIS.CheckFilterPanelForAlwaysOnDestroyProtection

--Check the filterPanelId and if it should be protected against destroy, even if the currently protectedSettings are
--different than "Anti destroy", and then use the current anti-destroy value for the proetction
function FCOIS.CheckFilterPanelForDestroyProtection(filterPanelId)
--d(">CheckFilterPanelForDestroyProtection")
    local filterPanelToAntiDestroySetings = checkVars.filterPanelIdsForAntiDestroyDoNotUseOtherAntiSettings
    local isProtectedDestroyIcon = filterPanelToAntiDestroySetings[filterPanelId] or false
    return isProtectedDestroyIcon
end
local checkFilterPanelForDestroyProtection = FCOIS.CheckFilterPanelForDestroyProtection


--Function to check if a normal icon is protected, or a dynamic icon is protected
--Will return the protection value (boolean) as 1st, and the anti-destroy protection value (boolean) as 2nd parameter
function FCOIS.CheckIfProtectedSettingsEnabled(filterPanel, iconNr, isDynamicIcon, checkAntiDetails, whereAreWe)
    if filterPanel == nil then return nil, false end
    isDynamicIcon = isDynamicIcon or false
    checkAntiDetails = checkAntiDetails or false
    local craftBagExtendedUsed = false
    local protectionVal
    local protectionValDestroy
    local protectionValues
------------------------------------------------------------------------------------------------------------------------
    -- Is CraftBagExtended addon active and are we at a subfilter panel of CBE (e.g. the mail CBE panel, where the anti-mail settings must be checked, and not the craftbag settings)?
    if FCOIS.gFilterWhere == LF_CRAFTBAG and FCOIS.gFilterWhereParent ~= nil then
        craftBagExtendedUsed = true
--d(">CBE filter parent panel active: " .. tos(FCOIS.gFilterWhereParent))
        filterPanel = FCOIS.gFilterWhereParent
    end
------------------------------------------------------------------------------------------------------------------------
--d("[FCOIS.checkIfProtectedSettingsEnabled - filterPanel: " .. tos(filterPanel) .. ", iconNr: " .. tos(iconNr) .. ", isDynamicIcon: " .. tos(isDynamicIcon) .. ", checkAntiDetails: " .. tos(checkAntiDetails) .. ", whereAreWe: " .. tos(whereAreWe))

    --Local mapping array for the filter panel ID -> the anti-settings
    local settings = FCOIS.settingsVars.settings
    local filterPanelIdToBlockSettingName = FCOIS.mappingVars.filterPanelIdToBlockSettingName
    --local filterPanelIdToBlockSettingNameOfFilterPanelId = filterPanelIdToBlockSettingName[filterPanel]
    local protectionSettings = {}
    for filterPanelId, blockSettingsData in pairs(filterPanelIdToBlockSettingName) do
        local typeOfData = type(blockSettingsData)
        if typeOfData == "string" then
            protectionSettings[filterPanelId] = protectionSettings[filterPanelId] or {}
            protectionSettings[filterPanelId][filterPanelId] = settings[blockSettingsData]
            --e.g. protectionSettings[LF_MAIL_SEND] = {[LF_MAIL_SEND]="blockSendingByMail"}
        elseif typeOfData == "table" then
            --If the given filterPanelId is a "parent" (like the craftbag) which can have multiple sub-filterPanelIds (inventory, mail, trade, guild store)
            if blockSettingsData.filterPanelToBlockSetting ~= nil then
                for filterPanelIdOfBlockSettingsData, blockSettingsDataBlockStr in pairs(blockSettingsData.filterPanelToBlockSetting) do
                    protectionSettings[filterPanelIdOfBlockSettingsData] = protectionSettings[filterPanelIdOfBlockSettingsData] or {}
                    protectionSettings[filterPanelIdOfBlockSettingsData][filterPanelId] = settings[blockSettingsDataBlockStr]
                    --e.g. protectionSettings[LF_MAIL_SEND] = {[LF_CRAFTBAG]="blockSendingByMail", ...}
                end
            end
        end
    end
------------------------------------------------------------------------------------------------------------------------
    --[[ OLD DATA before the for ... loop was created above!
    local protectionSettings = {
        --[LF_CRAFTBAG]   				= {[LF_CRAFTBAG]=settings.blockDestroying},
        [LF_VENDOR_BUY]   				= {[LF_VENDOR_BUY]=settings.blockVendorBuy},
        [LF_VENDOR_SELL]   				= {[LF_VENDOR_SELL]=settings.blockSelling, [LF_CRAFTBAG]=settings.blockSelling},
        [LF_VENDOR_BUYBACK]   			= {[LF_VENDOR_BUYBACK]=settings.blockVendorBuyback},
        [LF_VENDOR_REPAIR]   			= {[LF_VENDOR_REPAIR]=settings.blockVendorRepair},
        [LF_GUILDBANK_DEPOSIT] 			= {[LF_GUILDBANK_DEPOSIT]=settings.blockGuildBankWithoutWithdraw},
        [LF_GUILDSTORE_SELL] 			= {[LF_GUILDSTORE_SELL]=settings.blockSellingGuildStore, [LF_CRAFTBAG]=settings.blockSellingGuildStore},
        [LF_FENCE_SELL]					= {[LF_FENCE_SELL]=settings.blockFence},
        [LF_FENCE_LAUNDER]				= {[LF_FENCE_LAUNDER]=settings.blockLaunder},
        [LF_SMITHING_REFINE] 			= {[LF_SMITHING_REFINE]=settings.blockRefinement},
        [LF_SMITHING_DECONSTRUCT] 		= {[LF_SMITHING_DECONSTRUCT]=settings.blockDeconstruction},
        [LF_SMITHING_IMPROVEMENT]		= {[LF_SMITHING_IMPROVEMENT]=settings.blockImprovement},
        [LF_SMITHING_RESEARCH]			= {[LF_SMITHING_RESEARCH]=true}, 			                --Always say that items are blocked for research
        [LF_SMITHING_RESEARCH_DIALOG]	= {[LF_SMITHING_RESEARCH_DIALOG]=settings.blockResearchDialog},
        [LF_JEWELRY_REFINE] 			= {[LF_JEWELRY_REFINE]=settings.blockJewelryRefinement},
        [LF_JEWELRY_DECONSTRUCT] 		= {[LF_JEWELRY_DECONSTRUCT]=settings.blockJewelryDeconstruction},
        [LF_JEWELRY_IMPROVEMENT]		= {[LF_JEWELRY_IMPROVEMENT]=settings.blockJewelryImprovement},
        [LF_JEWELRY_RESEARCH]			= {[LF_JEWELRY_RESEARCH]=true}, 			                --Always say that items are blocked for research
        [LF_JEWELRY_RESEARCH_DIALOG]    = {[LF_JEWELRY_RESEARCH_DIALOG]=settings.blockJewelryResearchDialog},
        [LF_ENCHANTING_CREATION] 		= {[LF_ENCHANTING_CREATION]=settings.blockEnchantingCreation},
        [LF_ENCHANTING_EXTRACTION] 		= {[LF_ENCHANTING_EXTRACTION]=settings.blockEnchantingExtraction},
        [LF_ALCHEMY_CREATION] 			= {[LF_ALCHEMY_CREATION]=settings.blockAlchemyDestroy},
        [LF_MAIL_SEND] 					= {[LF_MAIL_SEND]=settings.blockSendingByMail, [LF_CRAFTBAG]=settings.blockSendingByMail},
        [LF_TRADE] 						= {[LF_TRADE]=settings.blockTrading, [LF_CRAFTBAG]=settings.blockTrading},
        [LF_RETRAIT] 					= {[LF_RETRAIT]=settings.blockRetrait},
        --Special entries for the call from ItemSelectionHandler() function's variable 'whereAreWe'
        [FCOIS_CON_CONTAINER_AUTOOLOOT]	= {[FCOIS_CON_CONTAINER_AUTOOLOOT]=settings.blockAutoLootContainer},	--Auto loot container
        [FCOIS_CON_RECIPE_USAGE]		= {[FCOIS_CON_RECIPE_USAGE]=settings.blockMarkedRecipes}, 		--Recipe
        [FCOIS_CON_MOTIF_USAGE]			= {[FCOIS_CON_MOTIF_USAGE]=settings.blockMarkedMotifs}, 		--Racial style motif
        [FCOIS_CON_POTION_USAGE]		= {[FCOIS_CON_POTION_USAGE]=settings.blockMarkedPotions}, 		--Potion
        [FCOIS_CON_FOOD_USAGE]			= {[FCOIS_CON_FOOD_USAGE]=settings.blockMarkedFood}, 		--Food
        [FCOIS_CON_CROWN_ITEM]			= {[FCOIS_CON_CROWN_ITEM]=settings.blockCrownStoreItems}, 	--Crown store item
    }
    ]]
    --Add the filterPanelIds which need to be checked for anti-destroy
    local filterPanelIdsCheckForAntiDestroy = FCOIS.checkVars.filterPanelIdsForAntiDestroy
    --For each entry in this anti-destroy check table add one line in libFiltersPanelIdToBlockSettings
    for libFiltersAntiDestroyCheckPanelId, _ in pairs(filterPanelIdsCheckForAntiDestroy) do
        --Check if there is already an entry in the protectionSettings table and add another subentry then
        --e.g. LF_GUILDBANK_DEPOSIT got the anti deposit if no rights to withdraw again + anti destroy settings!
        local conDestroyWhere = FCOIS_CON_DESTROY
        if libFiltersAntiDestroyCheckPanelId == LF_INVENTORY_COMPANION then
            conDestroyWhere = FCOIS_CON_COMPANION_DESTROY
        end
        if protectionSettings[libFiltersAntiDestroyCheckPanelId] then
            protectionSettings[libFiltersAntiDestroyCheckPanelId][conDestroyWhere] = settings.blockDestroying
        else
            protectionSettings[libFiltersAntiDestroyCheckPanelId] = {[conDestroyWhere]=settings.blockDestroying}
        end
    end
------------------------------------------------------------------------------------------------------------------------
    --Do checks with the icon?
    if iconNr ~= nil then
        --Dynamic icon or not?
        local icon2Dyn = FCOIS.mappingVars.iconIsDynamic
        --Dynamic icon?
        if isDynamicIcon or icon2Dyn[iconNr] then
            --d("Dynamic icon")
            --Get the protection
            protectionVal = settings.icon[iconNr].antiCheckAtPanel[filterPanel]
--d(">DynIconNr: " .. tos(iconNr) .. ", checkAtPanelChecks: " .. tos(protectionVal))
            --Is the dynamic icon protected at the current panel?
            if protectionVal == true then
                --The protective functions are not enabled (red flag is set in the inventory additional options flag icon, or the current panel got no additional inventory button, e.g. the crafting research tab or the research popup dialog)?
                local _, invAntiSettingsEnabled = FCOIS.GetContextMenuAntiSettingsTextAndState(filterPanel, false)
--d(">invAntiSettingsEnabled: " ..tos(invAntiSettingsEnabled))
                if not invAntiSettingsEnabled then
                    --Check if the temporary disabling of the protection is enabled, if the user uses the inventory "flag" icon and sets it to red
                    local isDynIconSettingForProtectionTemporaryDisabledByInvFlag = settings.icon[iconNr].temporaryDisableByInventoryFlagIcon or false
                    if isDynIconSettingForProtectionTemporaryDisabledByInvFlag == true then
                        --The dynamic icon is temporary not protected at this panel!
--d(">>Dyn icon protection disabled by inventory flag icon!")
                        protectionVal = false
                    end
                end
            end
        else
--d("Non dynamic icon")
            --Non dynamic
            protectionValues = protectionSettings[filterPanel]
        end
    else
--d("No icon")
        protectionValues = protectionSettings[filterPanel]
    end
------------------------------------------------------------------------------------------------------------------------
    --============== SPECIAL ITEM & ICON CHECKS ====================================
    --Special treatment for the protectionValue and the AntiDestroy protectionValue
    --Found one or more protection values? Check each now to
    if protectionValues ~= nil then
        local antiDestroyCons = {
            [FCOIS_CON_DESTROY] = true,
            [FCOIS_CON_COMPANION_DESTROY] = true,
        }
--d(">>>Anti-Destroy checks")
        --Entries look like this:
        --[LF_INVENTORY] 			        = {[FCOIS_CON_DESTROY]=settings.blockDestroying},
        --or this if multiple entries:
        --[LF_GUILDBANK_DEPOSIT] 			= {[LF_GUILDBANK_DEPOSIT]=settings.blockGuildBankWithoutWithdraw, [FCOIS_CON_DESTROY]=settings.blockDestroying},
        for key, value in pairs(protectionValues) do
            --Is the CraftBag the active panel and are we at a non-standard craftbag extended panel (mail, trade, bank)?
            --Then get the settings from the LF_CRAFTBAG subentry!
            if craftBagExtendedUsed then
                --Anti destroy settings? CraftBag got no anti-destroy!
                protectionValDestroy = nil
                --Other panel anti settings?
                if key == LF_CRAFTBAG then
                    protectionVal = value
--d(">CraftBag protectionVal: " ..tos(protectionVal))
                end
            else
                --Anti destroy settings?
                if antiDestroyCons[key] then
                    protectionValDestroy = value
--d(">Destroy protectionVal: " ..tos(protectionValDestroy))
                --Other panel anti settings?
                elseif key == filterPanel then
                    protectionVal = value
--d(">Anti: checkType: " .. tos(checkType) .. ", protectionVal: " ..tos(protectionVal))
                end
            end
        end
    end
------------------------------------------------------------------------------------------------------------------------
    --============== SPECIAL ITEM & ICON CHECKS ====================================
    --Check details for the current filter panel too? e.g. check if items marked for deconstruction are allowed to be deconstructed at the deconstruction panel
    if iconNr ~= nil and checkAntiDetails == true and whereAreWe ~= nil then
--d(">>checkAntiDetails checks")
        --After checking dynamic icon settings check the global extra checks now (e.g. if selling an icon at the vendor sell panel is allowed if the icon is marked with the 'sell' icon)
        --If current checked panel = sell or guild store sell or fence sell
        if (whereAreWe == FCOIS_CON_SELL or whereAreWe == FCOIS_CON_GUILD_STORE_SELL or whereAreWe == FCOIS_CON_FENCE_SELL) then
            --If current checked panel = guild store sell and the filterId equals = sell in guild store
            if (whereAreWe==FCOIS_CON_GUILD_STORE_SELL) then
                -- If the item is marked for guild store selling,
                -- and the settings to allow selling of marked guild store items is enabled -> Abort here
                if iconNr==FCOIS_CON_ICON_SELL_AT_GUILDSTORE then
                    if settings.allowSellingInGuildStoreForBlocked == true then
                        protectionVal = false
                    end
                elseif iconNr==FCOIS_CON_ICON_SELL then
                    if settings.allowSellingForBlocked == true then
                        protectionVal = false
                    end
                    --Is the item marked as intricate and the selling of intricate items in the guild store is enabled? -> Abort here
                elseif iconNr==FCOIS_CON_ICON_INTRICATE then
                    if settings.allowSellingGuildStoreForBlockedIntricate == true then
                        protectionVal = false
                    end
                end

                --If current checked panel not equals sell / sell at fence / sell at guildstore
            else
                -- and the item is marked for selling
                if (iconNr==FCOIS_CON_ICON_SELL) then
                    --If the settings to allow selling of marked items is enabled -> Abort here
                    if settings.allowSellingForBlocked == true then
                        protectionVal = false
                        --if filter Id equals "Ornate" and the item is marked for selling,
                        --and the settings to allow selling of marked ornate items is enabled -> Abort here
                    elseif settings.allowSellingForBlockedOrnate == true then
                        protectionVal = false
                    end

                    --If current checked panel = sell or guild store sell or fence sell and filter Id equals "Intricate" and the item is marked as intricate,
                    --and the settings to allow selling of marked Intricate items is enabled -> Abort here
                elseif iconNr==FCOIS_CON_ICON_INTRICATE then
                    --Selling of intricate marked items is allowed? -> Abort here
                    if settings.allowSellingForBlockedIntricate == true then
                        protectionVal = false
                    end
                end
            end

            --Improve icon and item or jewelry item, and settings allow them to be improved?
        elseif (iconNr==FCOIS_CON_ICON_IMPROVEMENT and (whereAreWe == FCOIS_CON_IMPROVE or whereAreWe == FCOIS_CON_JEWELRY_IMPROVE) and settings.allowImproveImprovement == true) then
            protectionVal = false
            --Extraction of glyphs or deconstruction of items/jewelry with deconstruction icon
        elseif (iconNr==FCOIS_CON_ICON_DECONSTRUCTION and (whereAreWe == FCOIS_CON_ENCHANT_EXTRACT or whereAreWe == FCOIS_CON_DECONSTRUCT or whereAreWe == FCOIS_CON_JEWELRY_DECONSTRUCT) and settings.allowDeconstructDeconstruction == true) then
            protectionVal = false
            --If current checked panel = deconstruction or jewelry deconstruction and the item is marked as intricate,
            --and the settings to allow deconstruction of marked Intricate items is enabled -> Abort here
        elseif (iconNr==FCOIS_CON_ICON_INTRICATE and (whereAreWe == FCOIS_CON_DECONSTRUCT or whereAreWe == FCOIS_CON_JEWELRY_DECONSTRUCT) and settings.allowDeconstructIntricate == true) then
            protectionVal = false
            --If the checked panel is the research popup dialog and the icon is the research icon
        elseif (iconNr==FCOIS_CON_ICON_RESEARCH and settings.allowResearch == true and (whereAreWe == FCOIS_CON_RESEARCH or whereAreWe == FCOIS_CON_JEWELRY_RESEARCH or whereAreWe == FCOIS_CON_RESEARCH_DIALOG or whereAreWe == FCOIS_CON_JEWELRY_RESEARCH_DIALOG)) then
            protectionVal = false
        end
    end
------------------------------------------------------------------------------------------------------------------------
--d(">Icon: " .. tos(iconNr) .. ", protection enabled: " .. tos(protectionVal) .. ", protectionDestroy: " .. tos(protectionValDestroy))
    return protectionVal, protectionValDestroy
end
local checkIfProtectedSettingsEnabled = FCOIS.CheckIfProtectedSettingsEnabled


--Function to check if the item is marked ("protected") with the icon number. The icon must be enabled or the settings must tell to check disabled icons as well, in order to
--say the item is protected! No further settings are checked, so if you need to see if a marker icon is protected at a filterPanelId you need to use the function
--checkIfProtectedSettingsEnabled(checkType, iconNr, isDynamicIcon, checkAntiDetails, whereAreWe) instead
--2nd parameter itemId is the item's instance id or the unique item's id
--3rd parameter allows a handler like "gear" or "dynamic" to check all gear set or all dyanmic icons at once (in a loop)
-->Carefull: If "dynamic" is passed in as checkHandler it will return true for ALL dynamic icons, also if they belong to dynamic "gear" icons! You can change this by passing in the last parameter
-->checkHandlerExcludeIcons
--4th parameter addonName (String):	Can be left NIL! The unique addon name which was used to temporarily enable the uniqueIdm usage for the item checks.
-----                               -> See FCOIS API function "FCOIS.UseTemporaryUniqueIds(addonName, doUse)"
--5th parameter savedVarsTableNameForMarkers (String): The SavedVariables table name for the marker icons, if any special table is used
--6th parameter checkHandlerExcludeIcons (table): Provide a table of key number <iconId> = value boolean <shouldBeExcluded> which should be excluded as the specialCheckHandler (3rd parameter) is used
local checkIfItemIsProtected
function FCOIS.CheckIfItemIsProtected(iconId, itemId, checkHandler, addonName, savedVarsTableNameForMarkers, checkHandlerExcludeIcons)
    if itemId == nil or (iconId == nil and checkHandler == nil) then return false end
--===============================================================================================================================
---v- ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION -v-
--    ATTENTION: Enabling this debug message will lag the client A LOT and even might crash it!
--===============================================================================================================================
--d("FCOIS.checkIfItemIsProtected -  iconId: " .. tos(iconId) .. ", itemId: " .. tos(signItemId(itemId)) .. ", checkHandler: " .. tos(checkHandler) .. ", addonName: " .. tos(addonName))
--===============================================================================================================================
---^- ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION ATTENTION -^-
--===============================================================================================================================
    savedVarsTableNameForMarkers = savedVarsTableNameForMarkers or getSavedVarsMarkedItemsTableName()
    ------------------------------------------------------
    --	Check in a loop, for gear sets and dynamic icons:
    -------------------------------------------------------
    --If the check handler is given we need to check if it is an allowed one
    if checkHandler ~= nil and checkHandler ~= "" then
        if not allowedCheckHandlers[checkHandler] then return false end
        checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
        local mappingVars = FCOIS.mappingVars
        --Recursively check all the marker icons from the check handler range, e.g. all gear sets or all dynamic icons
        if checkHandler == "gear" then
            local itemIsProtectedWithGear = false
            local gearIcons = mappingVars.gearToIcon
            for _, gearIconNr in pairs(gearIcons) do
                if gearIconNr ~= nil then
                    if not checkHandlerExcludeIcons or (checkHandlerExcludeIcons and not checkHandlerExcludeIcons[gearIconNr]) then
                        local itemIsProtectedWithGearLoop = checkIfItemIsProtected(gearIconNr, itemId, nil, addonName, savedVarsTableNameForMarkers)
                        --Is the current gear's icon protecting the item then return "protected" (true)
                        if itemIsProtectedWithGearLoop then return true end
                    end
                end
            end
            return itemIsProtectedWithGear

        elseif checkHandler == "dynamic" then
            local itemIsProtectedWithDynamic = false
            local dynamicIcons = mappingVars.dynamicToIcon
            for _, dynamicIconNr in pairs(dynamicIcons) do
                if dynamicIconNr ~= nil then
                    if not checkHandlerExcludeIcons or (checkHandlerExcludeIcons and not checkHandlerExcludeIcons[dynamicIconNr]) then
                        local itemIsProtectedWithDynamicLoop = checkIfItemIsProtected(dynamicIconNr, itemId, nil, addonName, savedVarsTableNameForMarkers)
                        --Is the current dynamic's icon protecting the item then return "protected" (true)
                        if itemIsProtectedWithDynamicLoop then return true end
                    end
                end
            end
            return itemIsProtectedWithDynamic
        end
    end
    -------------------------------------------------------
    --	Check without loop (called from a loop mabye for gear sets and dynamic icons):
    -------------------------------------------------------
    --Item is not enabled
    local itemIsMarked
    local settings = FCOIS.settingsVars.settings
    local isIconEnabled = settings.isIconEnabled[iconId]
    --Is the item enabled, or is the item disabled and the setting to check disabled icons too is enabled?
    if isIconEnabled or (not isIconEnabled and settings.checkDeactivatedIcons) then
        --Workaround to return a not-marked icon, if the icon is disabled, so the icon won't be removed
        -- >> Set & unset in function "FCOIS.ClearOrRestoreAllMarkers"
        if not isIconEnabled and FCOIS.preventerVars.doFalseOverride then
--d("FCOIS.checkIfItemIsProtected - Icon is disabled -> will not be filtered here (but protected)!")
            return false
        end
        --Check if the item is marked with the icon
        if FCOIS[savedVarsTableNameForMarkers][iconId] then
            itemIsMarked = FCOIS[savedVarsTableNameForMarkers][iconId][signItemId(itemId, nil, nil, addonName, nil, nil)]
        else
            --Error message
            debugMessage("[checkIfItemIsProtected]","itemIsMarked = FCOIS[savedVarsTableNameForMarkers][iconId] -> Missing iconId ("..tos(iconId)..") subtable for SV table ("..tos(savedVarsTableNameForMarkers) ..")", false, FCOIS_DEBUG_DEPTH_NORMAL, false, true)
        end
    end
    if itemIsMarked == nil then itemIsMarked = false end
--d("FCOIS.checkIfItemIsProtected - itemIsMarked: " .. tos(itemIsMarked))
    return itemIsMarked
end
checkIfItemIsProtected = FCOIS.CheckIfItemIsProtected
FCOIS.checkIfItemIsProtected = checkIfItemIsProtected --backwards compatibility (lower case function name)


-- Fired when user selects an item to destroy.
-- Warns user if the item is marked with any of the filter icons
function FCOIS.DestroySelectionHandler(bag, slot, echo, parentControl)
    echo = echo or false
    if FCOIS.settingsVars.settings.debug then debugMessage( "[DestroySelectionHandler]","Bag: " .. tos(bag) .. ", Slot: " .. tos(slot) ..", filterPanelId: " .. tos(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_SPAM) end
    --Are we at the vendor repair panel?
    isVendorPanelShown = isVendorPanelShown or FCOIS.IsVendorPanelShown
    local isVendorRepair = isVendorPanelShown(LF_VENDOR_REPAIR, false) or false
    --Are we coming from the character window?
    if not isVendorRepair and ((bag == BAG_WORN or bag == BAG_COMPANION_WORN) and parentControl ~= nil) then
        FCOIS.preventerVars.gCheckEquipmentSlots = true
    end
--d("[DestroySelectionHandler] Bag: " .. tos(bag) .. ", Slot: " .. tos(slot) ..", echo: " .. tos(echo) .. ", filterPanelId: " .. tos(FCOIS.gFilterWhere) .. ", isVendorRepair: " ..tos(isVendorRepair) .. ", checkEquipmentSlots: " .. tos(FCOIS.preventerVars.gCheckEquipmentSlots))

    -- get (unique) instance id of the item
    local itemId = myGetItemInstanceIdNoControl(bag, slot)

    -- if item is in any protection list, warn user
    for iconIdToCheck=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        if checkIfItemIsProtected(iconIdToCheck, itemId) then
            local currentFilterPanelId = FCOIS.gFilterWhere
            --Check if the anti-settings are enabled (and if a dynamic icon is used)
            local isProtectedIcon, isProtectedDestroyIcon = checkIfProtectedSettingsEnabled(currentFilterPanelId, iconIdToCheck, nil, nil, nil)
--d(">>isProtectedIcon: " .. tos(isProtectedIcon) .. ", isProtectedDestroyIcon: " ..tos(isProtectedDestroyIcon))
            --FCOIS version 1.6.0
            --Local hack to change the protectionValue of icons to "true" if certain filterPanels are checked.
            if not isProtectedDestroyIcon then isProtectedDestroyIcon = checkFilterPanelForAlwaysOnDestroyProtection(currentFilterPanelId) end
--d(">>isProtectedDestroyIconAlwaysOn: " ..tos(isProtectedDestroyIcon))

            --If the anti-destroy settings, or the "always on" or the special panel checks all do not say "anti-destroy" is enabled: Use the normal panel's anti-* settings instead
            --to determine the anti-destroy state
            if not isProtectedDestroyIcon then
--d(">>>using isProtectedIcon as anti-destroy!")
                --Check if the filterPanelid should ONLY use the anti-destroy settings and not other anti-settings (e.g. Guild bank deposit)
                if not checkFilterPanelForDestroyProtection(currentFilterPanelId) then
                    isProtectedDestroyIcon = isProtectedIcon
                end
            end

            --Anti-destroy is enabled?
            if isProtectedDestroyIcon == true then
                --Show alert message?
                if (echo == true) then
                    --Check if alert or chat message should be shown
                    --function outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                    outputItemProtectedMessage(bag, slot, FCOIS_CON_DESTROY, false, false, false, false)
                end
                return true
            end
        end
    end
    return false
end

--============================== ITEM SELECTION HANDLER ===================================================================================
-- Fired when user selects an item by drag&drop, doubleclick etc.
-- Warns user if the item is marked with any of the filter icons and if the marked icon protects the item at teh current filterPanelId
function FCOIS.ItemSelectionHandler(bag, slot, echo, isDragAndDrop, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId, panelIdParent)
    if bag == nil or slot == nil then return true end
    local doDebug = false
    --TODO DEBUG: enable to show d messages for debugging
    --[[
    if GetDisplayName() == "@Baertram" and bag == 5 and slot == 883 then --bug #272 20231205 -> Alchemy station, dynamic icon not protected
        FCOIS.preventerVars.doDebugItemSelectionHandler = true
    end
    ]]
    if FCOIS.preventerVars.doDebugItemSelectionHandler == true then
        doDebug = true
        FCOIS.preventerVars.doDebugItemSelectionHandler = false
    end

    echo = echo or false
    isDragAndDrop = isDragAndDrop or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false
    calledFromExternalAddon = calledFromExternalAddon or false

    local settings = FCOIS.settingsVars.settings
    local mappingVars = FCOIS.mappingVars

    if settings.debug then debugMessage( "[ItemSelectionHandler]", "Bag: " .. tos(bag) .. ", Slot: " .. tos(slot) .. ", echo: " .. tos(echo) .. ", isDragAndDrop: " .. tos(isDragAndDrop) .. ", overrideChatOutput: " .. tos(overrideChatOutput) .. ", suppressChatOutput: " .. tos(suppressChatOutput) .. ", overrideAlert: " .. tos(overrideAlert) .. ", suppressAlert: " .. tos(suppressAlert) .. ", calledFromExternalAddon: " .. tos(calledFromExternalAddon) .. ", panelId: " .. tos(panelId) .. ", panelIdParent: " .. tos(panelId).. ", FCOIS.gFilterWhere: " ..tos(FCOIS.gFilterWhere), true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d("[FCOIS]ItemSelectionHandler - Bag: " .. tos(bag) .. ", Slot: " .. tos(slot) .. ", echo: " .. tos(echo) .. ", isDragAndDrop: " .. tos(isDragAndDrop) .. ", overrideChatOutput: " .. tos(overrideChatOutput) .. ", suppressChatOutput: " .. tos(suppressChatOutput) .. ", overrideAlert: " .. tos(overrideAlert) .. ", suppressAlert: " .. tos(suppressAlert) .. ", calledFromExternalAddon: " .. tos(calledFromExternalAddon) .. ", panelId: " .. tos(panelId) .. ", panelIdParent: " .. tos(panelId)) end

    --Panel at the call of the function
    local panelIdAtCall = panelId

    --======= MAPPING ==============================================================
    --The mapping table for the filter panel ID which is needed for the dynamic icon checks later
    local whereAreWeToFilterPanelId = mappingVars.whereAreWeToFilterPanelId
    --Mapping array for the whereAreWe to anti-settings. Returns the anti-settings from the current settings, or false (not protected) as a constant if there is no anti-setting available.
    --The constant false values will be taken care of in other checks after this table check was done then.
    --local settingNameOfBlock = filterPanelIdToBlockSettingName[filterPanel]
    local whereAreWeToIsBlocked = {
--[[
        [FCOIS_CON_DESTROY]				= settings.blockDestroying,			    --Destroying
        [FCOIS_CON_MAIL]				= settings.blockSendingByMail,     	    --Mail send
        [FCOIS_CON_TRADE]				= settings.blockTrading,				--Trading
        [FCOIS_CON_BUY]				    = settings.blockVendorBuy,              --Vendor buy
        [FCOIS_CON_SELL]				= settings.blockSelling,                --Vendor sell
        [FCOIS_CON_BUYBACK]				= settings.blockVendorBuyback,          --Vendor buyback
        [FCOIS_CON_REPAIR]				= settings.blockVendorRepair,           --Vendor repair
        [FCOIS_CON_REFINE]				= settings.blockRefinement,			    --Refinement,
        [FCOIS_CON_DECONSTRUCT]			= settings.blockDeconstruction,		    --Deconstruction
        [FCOIS_CON_IMPROVE]				= settings.blockImprovement,			--Improvement
        [FCOIS_CON_RESEARCH]			= true,   			                    --Research -> Always return true as there is no special option for anti-research and the protection is on
        [FCOIS_CON_RESEARCH_DIALOG] 	= settings.blockResearchDialog, 		--Research dialog
        [FCOIS_CON_JEWELRY_REFINE]		= settings.blockJewelryRefinement,		--Jewelry Refinement,
        [FCOIS_CON_JEWELRY_DECONSTRUCT]	= settings.blockJewelryDeconstruction,	--Jewelry Deconstruction
        [FCOIS_CON_JEWELRY_IMPROVE]		= settings.blockJewelryImprovement,		--Jewelry Improvement
        [FCOIS_CON_JEWELRY_RESEARCH]    = true, 								--Jewelry research -> Always return true as there is no special option for anti-jewelry research and the protection is on
        [FCOIS_CON_JEWELRY_RESEARCH_DIALOG] = settings.blockJewelryResearchDialog, --Jewelry research dialog
        [FCOIS_CON_ENCHANT_EXTRACT]		= settings.blockEnchantingExtraction,   --Enchanting extraction
        [FCOIS_CON_ENCHANT_CREATE]		= settings.blockEnchantingCreation,	    --Enchanting creation
        [FCOIS_CON_GUILD_STORE_SELL]	= settings.blockSellingGuildStore,	    --Guild store sell
        [FCOIS_CON_FENCE_SELL]			= settings.blockFence,                  --Fence sell
        [FCOIS_CON_LAUNDER_SELL]		= settings.blockLaunder,			    --Fence launder
        [FCOIS_CON_ALCHEMY_DESTROY]		= settings.blockAlchemyDestroy,		    --Alchemy destroy
        [FCOIS_CON_CONTAINER_AUTOOLOOT]	= settings.blockAutoLootContainer,	    --Auto loot container
        [FCOIS_CON_RECIPE_USAGE]   		= settings.blockMarkedRecipes, 		    --Recipe
        [FCOIS_CON_MOTIF_USAGE]			= settings.blockMarkedMotifs, 		    --Racial style motif
        [FCOIS_CON_POTION_USAGE]		= settings.blockMarkedPotions, 		    --Potion
        [FCOIS_CON_FOOD_USAGE]	   		= settings.blockMarkedFood, 		    --Food
        [FCOIS_CON_CROWN_ITEM]	   		= settings.blockCrownStoreItems, 		--Crown store items
        [FCOIS_CON_CRAFTBAG_DESTROY]	= settings.blockDestroying, 		    --Craftbag, destroying
        [FCOIS_CON_RETRAIT]	            = settings.blockRetrait, 			    --Retrait station, retrait
        [FCOIS_CON_COMPANION_DESTROY]	= settings.blockDestroying,			    --Companion inventory destroying
        [FCOIS_CON_FALLBACK]			= false,							    --Always return false. Used e.g. for the bank/guild bank deposit checks
]]
    }
    local filterPanelIdToBlockSettingName = mappingVars.filterPanelIdToBlockSettingName
    for whereAreWeId, blockSettingsData in pairs(filterPanelIdToBlockSettingName) do
        if whereAreWeId >= FCOIS_CON_WHEREAREWE_MIN then
            local typeOfData = type(blockSettingsData)
            if typeOfData == "string" then
                whereAreWeToIsBlocked[whereAreWeId] = settings[blockSettingsData]
            else
                whereAreWeToIsBlocked[whereAreWeId] = blockSettingsData
            end
        end
    end

    --The mapping array to skip the dyanmic icon checks, as the whereAreWe filter panel ID is related to single item checks!
    local whereAreWeToSingleItemChecks = mappingVars.whereAreWeToSingleItemChecks
    --Mapping array for the alertMessages
    --local whereAreWeToAlertmessageText = mappingVars.whereAreWeToAlertmessageText

    --======= VARIABLEs ============================================================
    --The return value for this function, initiated with "true" = "block"
    local isBlocked = true
    -- Get the item instance id of the item
    local itemId = myGetItemInstanceIdNoControl(bag, slot)
    if itemId == nil then return false end
    --The return variable for the "check all icons" for ... loop
    local isBlockedLoop = false
    local isBlockedLoopDestroy = false
    --The return variable for "is any marker icon set?"
    local markedWithOneIcon = false
    --The filterPanelId was specified in the parameters? Or not, then use the current filterPanelId the addon stores
    panelId = panelId or FCOIS.gFilterWhere

    --======= WHERE ARE WE? ========================================================
    --The number for the orientation (which filter panel ID and which sub-checks were done -> for the chat output and the alert message determination)
    getWhereAreWe = getWhereAreWe or FCOIS.GetWhereAreWe
    --WhereAreWe: FCOIS_CON_* constant to show where we currently are filtering and checking protections
    local whereAreWe = getWhereAreWe(panelId, panelIdAtCall, panelIdParent, bag, slot, isDragAndDrop, calledFromExternalAddon)

    --Error: wheerAreWe is NIL!
    if whereAreWe == nil then
        local itemLink = "bag: " ..tos(bag) .. ", slot: " .. tos(slot)
        if bag and slot then
            itemLink = gil(bag, slot)
        end
        local errorData = {
            [1] = panelId,
            [2] = itemLink,
            [3] = isDragAndDrop,
            [4] = calledFromExternalAddon,
        }
        FCOIS.debugErrorMessage2Chat("whereAreWeNIL", 1, errorData)
        return true
    end

    --======= GLOBAL ANTI-CHECKs ===================================================
    --Get the anti-settings for the whereAreWe panel number now
    isBlocked = whereAreWeToIsBlocked[whereAreWe]
    --Check if single items checks should be done (like "check a recipe" or "potion")
    local singleItemChecks = whereAreWeToSingleItemChecks[whereAreWe] or false

    if settings.debug then debugMessage( "[ItemSelectionHandler]",">Where are we: " .. tos(whereAreWe) .. ", isBlocked: " .. tos(isBlocked) .. ", singleItemChecks: " .. tos(singleItemChecks) .. ", panelId: " .. tos(panelId), true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d(">Where are we: " .. tos(whereAreWe) .. ", isBlocked: " .. tos(isBlocked) .. ", singleItemChecks: " .. tos(singleItemChecks) .. ", panelId: " .. tos(panelId) .. ", id: " ..tos(itemId)) end

    --======= SPECIAL CHECKS - RECIPES, STYLE MOTIFS, FOOD =========================
    -- Check if the recipe/style motif/food/crown store item is not protected because the current anti-destroy option is disabled
    -- by help of the addiitonal inventory options flag icon (red flag)
    if panelId == LF_INVENTORY and singleItemChecks then
        --See if the Anti-settings for the given panel are enabled or not
        --The protective functions are not enabled (red flag in the inventory additional options flag icon or the current panel got no additional inventory button, e.g. the crafting research tab)
        local _, invAntiSettingsEnabled = FCOIS.GetContextMenuAntiSettingsTextAndState(panelId, false)
        if not invAntiSettingsEnabled then
            --Using/eating/drinking items for marked items is blocked, e.g. for recipes/style motifs?
            --If the settings allow it: Change the blocked state to unblocked upon right-clicking the inventory additional options flag icon
            --Recipes
            if whereAreWe == FCOIS_CON_RECIPE_USAGE and settings.blockMarkedRecipesDisableWithFlag then
                --Using the recipe by help of a doubleclick is allowed
                if doDebug then d("[FCOIS] ItemSelectionHandler - Recipe is allowed with doubleclick") end
                return false
            end
            --Style motifs
            if whereAreWe == FCOIS_CON_MOTIF_USAGE and settings.blockMarkedMotifsDisableWithFlag then
                --Using the style motif by help of a doubleclick is allowed
                if doDebug then d("[FCOIS] ItemSelectionHandler - Style motif is allowed with doubleclick") end
                return false
            end
            --Drink & food
            if (whereAreWe == FCOIS_CON_FOOD_USAGE or whereAreWe == FCOIS_CON_POTION_USAGE) and settings.blockMarkedFoodDisableWithFlag then
                --Using the food by help of a doubleclick is allowed
                if doDebug then d("[FCOIS] ItemSelectionHandler - Potion/Food is allowed with doubleclick") end
                return false
            end
            --Autoloot container
            if whereAreWe == FCOIS_CON_CONTAINER_AUTOOLOOT and settings.blockMarkedAutoLootContainerDisableWithFlag then
                --Using the auto loot container by help of a doubleclick is allowed
                if doDebug then d("[FCOIS] ItemSelectionHandler - Autloot container is allowed with doubleclick") end
                return false
            end
            --Crown store items
            if whereAreWe == FCOIS_CON_CROWN_ITEM and settings.blockMarkedCrownStoreItemDisableWithFlag then
                --Using the crown store item by help a doubleclick is allowed
                if doDebug then d("[FCOIS] ItemSelectionHandler - Crown store item is allowed with doubleclick") end
                return false
            end
        end -- if not invAntiSettingsEnabled then
    end

    --======= CHECKs AGAINST ICONs =================================================
    -- If item is in any protection list, warn user.
    -- First check all marker icons on the item now:
    local mappedIsDynIcon = mappingVars.iconIsDynamic
    for iconIdToCheck=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        if settings.debug then debugMessage("[ItemSelectionHandler]",">icon: " .. iconIdToCheck, true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d("[FCOIS]ItemSelectionHandler - icon: " .. iconIdToCheck) end
        --Check if the item is marked with the icon
        if checkIfItemIsProtected(iconIdToCheck, itemId) then
            markedWithOneIcon = true
            local isDynamicIcon = mappedIsDynIcon[iconIdToCheck]
            if settings.debug then debugMessage("[ItemSelectionHandler]",">> Item is protected with the icon " .. iconIdToCheck .. ", isDynamic: " .. tos(isDynamicIcon), true, FCOIS_DEBUG_DEPTH_SPAM) end
            if doDebug then d(">> Item is protected with the icon " .. iconIdToCheck .. ", isDynamic: " .. tos(isDynamicIcon)) end
            --Reset the return variable for each icon again to the global block variable!
            isBlockedLoop = isBlocked
            --Is the current filterPanelId not 999 (fallback, e.g. bank withdraw or bank deposit, guild bank withdraw or guild bank deposit, ...)
            --Return the global setting "isBlocked" then so the ItemDestroyHandler is managing the anti-destroy functions!
            if whereAreWe ~= FCOIS_CON_FALLBACK then
if doDebug then d(">>WhereAreWe <> FCOIS_CON_FALLBACK") end
                --Check if the current icon in the loop is an dynamic icon which can have special anti-settings (icon depending, not overall check depending!)
                --============== DYNAMIC ICON CHECKS - START ===================================
                --Is the icon a dynamic icon?
                if isDynamicIcon then
                    if settings.debug then debugMessage("[ItemSelectionHandler]",">>> dynamic icon", true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d(">>> dynamic icon") end
                    --The filterPanelId (determined by whereAreWe) given to function checkIfProtectedSettingsEnabled here is just LF_INVENTORY for the item related checks
                    --(recipes, autoloot container, bank deposit, guild bank deposit, etc.)
                    --This would return the wrong settings and thus it is checked before, if the whereAreWe panel id is related to single item checks.
                    --If so: The dynamic icon checks are not executed, but only the before checked single item check settings value is returned again by the help of whereAreWeToIsBlocked[whereAreWe]
                    if not singleItemChecks then
                        --Check the settings again now to see if this icon's dyanmic anti-settings are enabled for the given panel "whereAreWe"
                        --Call with 3rd parameter "isDynamicIcon" = true to skip "is dynamic icon check" inside the function again
                        local filterPanelIdOfWhereAreWe = whereAreWeToFilterPanelId[whereAreWe]
                        isBlockedLoop, isBlockedLoopDestroy = checkIfProtectedSettingsEnabled(filterPanelIdOfWhereAreWe, iconIdToCheck, true, nil, nil)
                        if doDebug then d(">dynIcon->checkIfProtectedSettingsEnabled-filterPanelIdOfWhereAreWe: " ..tos(filterPanelIdOfWhereAreWe) .. ", panelId: " ..tos(panelId) .. ",isBlockedLoop: " ..tos(isBlockedLoop) .. ", isBlockedLoopDestroy: " ..tos(isBlockedLoopDestroy)) end
                        if not isBlockedLoop and isBlockedLoopDestroy == true then
                            isBlockedLoop = isBlockedLoopDestroy
                        end
                        if settings.debug then debugMessage("[ItemSelectionHandler]",">>>> Dyn 1, isBlockedLoop: " .. tos(isBlockedLoop), true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d(">>>> Dyn 1, isBlockedLoop: " .. tos(isBlockedLoop)) end
                    end
                    --Does the dynamic icon block the item and was it not globally blocked before?
                    --Then we need to check some global stuff from before again (like the item's type -> recipe/autoloot container/style motif/potion/food/etc.)
                    --and return the settings from there to get the 'real' anti-settings block state
                    if singleItemChecks and (isBlockedLoop ~= isBlocked) then
                        if settings.debug then debugMessage("[ItemSelectionHandler]",">>>> Dyn 2, singleItemChecks: " .. tos(singleItemChecks) .. ", isBlocked: " .. tos(isBlocked), true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d(">>>> Dyn 2, singleItemChecks: " .. tos(singleItemChecks) .. ", isBlocked: " .. tos(isBlocked)) end
                        --The dynmic icon is blocking but the global settings did not block before.
                        --Check the whereAreWe settings again now, to get special settings for the autoloot container/recipes/etc.
                        isBlockedLoop = isBlocked
                    end
                end
                --============== DYNAMIC ICON CHECKS - END =====================================
            --else
if doDebug then d(">WhereAreWe is: " ..tos(whereAreWe) .." -> No further checks were done!") end
            end -- if not whereAreWe == FCOIS_CON_FALLBACK then
            --============== SPECIAL ITEM & ICON CHECKS - START (non-dynamic!) ====================================
            if not isDynamicIcon then
                --After checking dynamic icon settings check the global extra checks now (e.g. if selling an icon at the vendor sell panel is allowed if the icon is marked with the 'sell' icon)
                --If current checked panel = sell or guild store sell or fence sell
                if (whereAreWe == FCOIS_CON_SELL or whereAreWe == FCOIS_CON_GUILD_STORE_SELL or whereAreWe == FCOIS_CON_FENCE_SELL) then
                    --If current checked panel = sell and the item is marked for selling
                    if (iconIdToCheck==FCOIS_CON_ICON_SELL) then
                        --If the settings to allow selling of marked items is enabled -> Abort here
                        if settings.allowSellingForBlocked == true then
                            isBlockedLoop = false
                        --if filter Id equals "Ornate" and the item is marked for selling,
                        --and the settings to allow selling of marked ornate items is enabled
                        --and the item is ornate -> Abort here
                        elseif settings.allowSellingForBlockedOrnate == true and isItemOrnate(bag, slot) then
                            isBlockedLoop = false
                        end
                    --If current checked panel = guild store sell and the filterId equals = sell in guild store and the item is marked for guild store selling,
                    --and the settings to allow selling of marked guild store items is enabled -> Abort here
                    elseif (iconIdToCheck==FCOIS_CON_ICON_SELL_AT_GUILDSTORE and whereAreWe==FCOIS_CON_GUILD_STORE_SELL and settings.allowSellingInGuildStoreForBlocked == true) then
if doDebug then d(">>selling non-dynamic at guild store is allowed!") end
                        isBlockedLoop = false
                    --If current checked panel = sell or guild store sell or fence sell and filter Id equals "Intricate" and the item is marked as intricate,
                    --and the settings to allow selling of marked intricate items is enabled -> Abort here
                    elseif (iconIdToCheck==FCOIS_CON_ICON_INTRICATE) then
                       if whereAreWe==FCOIS_CON_GUILD_STORE_SELL then
                           if settings.allowSellingGuildStoreForBlockedIntricate == true then
                               isBlockedLoop = false
                           end
                       else
                          if settings.allowSellingForBlockedIntricate == true then
                            isBlockedLoop = false
                          end
                       end
                    end
                --Improve icon and item or jewelry item, and settings allow them to be improved?
                elseif (iconIdToCheck==FCOIS_CON_ICON_IMPROVEMENT and (whereAreWe == FCOIS_CON_IMPROVE or whereAreWe == FCOIS_CON_JEWELRY_IMPROVE) and settings.allowImproveImprovement == true) then
                    isBlockedLoop = false
                --Extraction of glyphs with deconstruction item
                elseif (iconIdToCheck==FCOIS_CON_ICON_DECONSTRUCTION and whereAreWe == FCOIS_CON_ENCHANT_EXTRACT and settings.allowDeconstructDeconstruction == true) then
                    --Check if the itemtype is a glyph
                    isBlockedLoop = not isItemAGlpyh(bag, slot)
if doDebug then d(">>IsItemAGlpyh: " .. tos(not isBlockedLoop) .. ", isBlockedLoop: " .. tos(isBlockedLoop)) end
                --Research and research marker icon is allowed to be used at research panel and research dialog?
                elseif ((iconIdToCheck==FCOIS_CON_ICON_RESEARCH and settings.allowResearch == true) and (whereAreWe == FCOIS_CON_RESEARCH or whereAreWe == FCOIS_CON_JEWELRY_RESEARCH or whereAreWe == FCOIS_CON_RESEARCH_DIALOG or whereAreWe == FCOIS_CON_JEWELRY_RESEARCH_DIALOG)) then
                    isBlockedLoop = false
                end
                --============== SPECIAL ITEM & ICON CHECKS - END (non-dynamic) ====================================
            end --	if not isDynamicIcon then
            --======= ITEM IS BLOCKED ! - START ============================================
            --Abort here if at least one marker icon was set and it is protecting the item!
            if isBlockedLoop == true then
                if settings.debug then debugMessage("[ItemSelectionHandler]",">isBlockedLoop: true -> Item is protected!", true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d("isBlockedLoop: true -> Item is protected! echo: " ..tos(echo)) end
                --Show text in chat or alert message now?
                if echo == true then
                    if doDebug then d(">item echo - whereAreWe: " .. tos(whereAreWe) .. ", overrideChatOutput: " .. tos(overrideChatOutput) .. ", suppressChatOutput: " .. tos(suppressChatOutput) .. ", overrideAlert: " .. tos(overrideAlert) .. ", suppressAlert: " .. tos(suppressAlert)) end
                    --Check if alert or chat message should be shown
                    --                         bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert
                    outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                end
                --Abort here as at least 1 icon is marked for the current item and the protection for this icon (globally or dynamically per icon) is enabled here!
                return true
            end -- if isBlockedLoop == true
            --======= ITEM IS BLOCKED ! - END ==============================================
        end -- if( checkIfItemIsProtected(iconIdToCheck, id) ) then
    end -- for

    --======= RETURN ===============================================================
    --Is the item marked with any of the marker icons? Don't block it
    if not markedWithOneIcon and (isBlockedLoop or isBlocked) then
        if settings.debug then debugMessage("[ItemSelectionHandler]","<not marked with one icon -> Abort 'false'", true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d("not marked with one icon -> Abort 'false'") end
        return false
    end
    --Were all icons checked and everything was not blocked? Then return false to unblock the icon
    if not isBlockedLoop then
        if settings.debug then debugMessage("[ItemSelectionHandler]","<not blocked in loop -> Abort 'false'", true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d("not blocked in loop -> Abort 'false'") end
        return false
    end
    --Else return the global block value from before the icon checks
    if settings.debug then debugMessage("[ItemSelectionHandler]","<return isBlocked: " .. tos(isBlocked), true, FCOIS_DEBUG_DEPTH_SPAM) end
if doDebug then d("return isBlocked: " .. tos(isBlocked)) end
    return isBlocked
end -- ItemSelectionHandler

--=============== DECONSTRUCTION SELECTION HANDLER ========================================================================================
-- fired when user selects an item to deconstruct
-- warns user if the item is marked with any of the filter icons
function FCOIS.DeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId)
    checkIfDeconstructionNPC = checkIfDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC
    if bag == nil or slot == nil then return true end
    echo = echo or false
    overrideChatOutput = overrideChatOutput or false
    suppressChatOutput = suppressChatOutput or false
    overrideAlert = overrideAlert or false
    suppressAlert = suppressAlert or false

    local doDebug = false --TODO DEBUG: enable to show d messages for debugging
    if FCOIS.preventerVars.doDebugDeconstructionSelectionHandler then
        doDebug = true
        FCOIS.preventerVars.doDebugDeconstructionSelectionHandler = false
    end

    local settings = FCOIS.settingsVars.settings
    local mappingVars = FCOIS.mappingVars

    --> GOT HERE FROM CONTEXT MENU ENTRY FOR "ADD ITEM TO CRAFT" e.g.
    -- Is user not at the deconstruction panel or the panelId is given from the function call but it is NOT the deconstruction panel at a crafting station?
    --Get the current craftingtype
    local craftingTypeIsDeconstructable = false
    local craftingType
    if calledFromExternalAddon then
        local craftingTypesWithDeconstruction = {
            [CRAFTING_TYPE_BLACKSMITHING] =     true,
            [CRAFTING_TYPE_CLOTHIER] =          true,
            [CRAFTING_TYPE_JEWELRYCRAFTING] =   true,
            [CRAFTING_TYPE_WOODWORKING] =       true,
        }
        craftingType = GetCraftingInteractionType()
        craftingTypeIsDeconstructable = craftingTypesWithDeconstruction[craftingType] or false
    end
    local isDeconstructablePanelId = (panelId ~= nil and checkIfFilterPanelIsDeconstructable(panelId)) or false
    local noDeconstructionShouldBeDone = true
    if (deconstructionBag ~= nil and not deconstructionBag:IsHidden())
            or checkIfDeconstructionNPC(FCOIS.gFilterWhere) -- #202
            or (calledFromExternalAddon and craftingTypeIsDeconstructable == true) or isDeconstructablePanelId == true then
        noDeconstructionShouldBeDone = false
    end

    if settings.debug then debugMessage( "[DeconstructionSelectionHandler]","Bag: " .. tos(bag) .. ", Slot: " .. tos(slot) .. ", echo: " .. tos(echo) .. ", overrideChatOutput: " .. tos(overrideChatOutput) .. ", suppressChatOutput: " .. tos(suppressChatOutput) .. ", overrideAlert: " .. tos(overrideAlert) .. ", suppressAlert: " .. tos(suppressAlert) .. ", calledFromExternalAddon: " .. tos(calledFromExternalAddon) .. ", panelId: " .. tos(panelId).. ", craftingType: " .. tos(craftingType) .. ", craftingTypeIsDeconstructable: " ..tos(craftingTypeIsDeconstructable).. ", noDeconstructionShouldBeDone: " ..tos(noDeconstructionShouldBeDone), true, FCOIS_DEBUG_DEPTH_SPAM) end
    if doDebug then d("[FCOIS]DeconstructionSelectionHandler - panelId: " ..tos(panelId) .. ", calledFromExternalAddon: " ..tos(calledFromExternalAddon) .. "->craftingType: " .. tos(craftingType) .. ", craftingTypeIsDeconstructable: " ..tos(craftingTypeIsDeconstructable).. ", noDeconstructionShouldBeDone: " ..tos(noDeconstructionShouldBeDone)) end
    --Call the itemSelectionHandler for everything else then Deconstruction now?
    if noDeconstructionShouldBeDone == true then
        local craftingPrevention = FCOIS.craftingPrevention
        --No deconstruction -> Use ItemSelectionHandler function to run the Anti-* protection checks
        if ( (calledFromExternalAddon and panelId ~= nil and isDeconstructablePanelId == false)
                or checkIfFilterPanelIsDeconstructable(FCOIS.gFilterWhere) == false
                or not alchemyStation:IsHidden()
                or not enchantingStation:IsHidden()
                or craftingPrevention.IsShowingRefinement()
                or craftingPrevention.IsShowingImprovement()
                or craftingPrevention.IsShowingResearch()
                or isResearchListDialogShown()
                or isRetraitStationShown()
        ) then
            if doDebug == true then
                FCOIS.preventerVars.doDebugItemSelectionHandler = true
            end
            callItemSelectionHandler = callItemSelectionHandler or FCOIS.callItemSelectionHandler
            return callItemSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId, nil, nil)
        else
            return false
        end
    end

    --Call the deconstruction handler stuff now for deconstruction!
    --The mapping table for the current deconstruction panel
    local deconPanelToBlockSettingsStrTab = mappingVars.deconPanelToBlockSettingsStrTab
    local deconPanelToBlockSettings = {}
    for filterPanelId, settingsBlockStr in pairs(deconPanelToBlockSettingsStrTab) do
        deconPanelToBlockSettings[filterPanelId] = settings[settingsBlockStr]
    end

    -- get instance id of the item, this value is persistant across all game
    local itemId = myGetItemInstanceIdNoControl(bag, slot)
    if itemId == nil then return false end
    --Is the panelId given? If not determine it
    local inventoryVar
    if panelId == nil then
        checkActivePanel = checkActivePanel or FCOIS.CheckActivePanel
        --comingFrom, overwriteFilterWhere, isDeconNPC
        --#202 set comingFrom to LF_SMITHING_DECONSTRUCT if panelId was nil, in order to call the deconstruction checks properly!
        inventoryVar, panelId = checkActivePanel(LF_SMITHING_DECONSTRUCT, false, nil)
    end

    -- If anti-(jewelry) deconstruction is globally active
    local isBlocked = deconPanelToBlockSettings[panelId] or false
    if doDebug then d("[FCOIS]DeconstructionSelectionHandler - panelId: " ..tos(panelId) .. ", isBlocked: " ..tos(isBlocked)) end
    --> We cannot return false here if deconstruction is globaly enabled because the dynamic icons have their own checks for deconstruction/jewelry deconstruction

    local isBlockedLoop = true
    local isBlockedLoopDestroy = false
    local isAnyIconProtected = false
    local markedWithOneIcon = false
    -- if item is in any protection list, warn user
    for iconToCheck=FCOIS_CON_ICON_LOCK, numFilterIcons, 1 do
        --d(">checking icon: " .. iconToCheck)
        --Is the item marked with an icon?
        --iconId, itemId, checkHandler, addonName, savedVarsTableNameForMarkers, checkHandlerExcludeIcons
        if checkIfItemIsProtected(iconToCheck, itemId, nil, nil, nil, nil) then
            --d(">> Decon: Item is protected with the icon " .. iconToCheck)
            markedWithOneIcon = true
            --Reset the return variable for each icon again to the global block variable!
            isBlockedLoop = isBlocked
            --Check if the current icon in the loop is an dynamic icon which can have special anti-settings (icon depending, not overall check depending!)
            local isDynamicIcon = mappingVars.iconIsDynamic[iconToCheck]
            --============== DYNAMIC ICON CHECKS - START ===================================
            --Is the icon a dynamic icon?
            if isDynamicIcon then
                --Check the settings again now to see if this icon's dyanmic anti-settings are enabled for the given panel "whereAreWe"
                --Call with 3rd parameter "isDynamicIcon" = true to skip "is dynamic icon check" inside the function again
                --filterPanel, iconNr, isDynamicIcon, checkAntiDetails, whereAreWe
                isBlockedLoop, isBlockedLoopDestroy = checkIfProtectedSettingsEnabled(panelId, iconToCheck, true, nil, nil) --panelId could be LF_SMITHING_DECONSTRUCT or LF_JEWELRY_DECONSTRUCT
                if not isBlockedLoop and isBlockedLoopDestroy then
                    isBlockedLoop = isBlockedLoopDestroy
                end
                if doDebug then d("Dynamic icon protection check for panel '" .. tos(LF_SMITHING_DECONSTRUCT) .."' returned: " .. tos(isBlockedLoop)) end
            end
            --============== DYNAMIC ICON CHECKS - END =====================================

            --============== SPECIAL ITEM & ICON CHECKS ====================================
            --Icon for deconstruction, and settings allow deconstruction?
            if iconToCheck == FCOIS_CON_ICON_DECONSTRUCTION and settings.allowDeconstructDeconstruction then
                --dont block item: Set loop variable to false so isAnyIconProtected and isBlockedLoop are not true!
                isBlockedLoop = false
                --Is the setting enabled to allow deconstruction for items marked for deconstruction, even if other marker icons are active?
                if settings.allowDeconstructDeconstructionWithMarkers == true then
                    if doDebug then d(">>>>> Decon icon enabled and allows decon of all other markers! -> Aborting here") end
                    --Abort the loop over the other icons now
                    return false
                end
                --Icon for intricate, and settings allows deconstruction?
            elseif iconToCheck==FCOIS_CON_ICON_INTRICATE and settings.allowDeconstructIntricate then
                --dont block item: Set loop variable to false so isAnyIconProtected and isBlockedLoop are not true!
                isBlockedLoop = false
            end

            --Is the current looped icon protected?
            if not isAnyIconProtected and isBlockedLoop then
                isAnyIconProtected = true
            end
        end -- if checkIfItemIsProtected(iconToCheck, id) then
    end -- for iconToCheck=1, numFilterIcons, 1 do

    --======= ITEM IS BLOCKED ! - START ============================================
    if isAnyIconProtected then
        if doDebug then d(">anyIconIsprotected: true") end
        if (echo == true) then
            --d(">> decon echo")
            --Check if alert or chat message should be shown
            outputItemProtectedMessage(bag, slot, FCOIS_CON_DECONSTRUCT, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
        end -- if echo == true
        return true
    end
    --======= ITEM IS BLOCKED ! - END ==============================================

    --======= RETURN ===============================================================
    --Is the item not marked with any of the marker icons? Don't block it
    if not markedWithOneIcon and (isAnyIconProtected or isBlocked) then
        if doDebug then d("Decon: not marked with one icon -> Abort 'false'") end
        return false
    end
    --Were all icons checked and everything was not blocked? Then return false to unblock the icon
    if not isAnyIconProtected then
        if doDebug then d("Decon: not blocked in loop -> Abort 'false'") end
        return false
    end
    --Else return the global block value from before the icon checks
    if doDebug then d("Decon: return isBlocked: " .. tos(isBlocked)) end
    return isBlocked
end -- DeconstructionSelectionHandler


-- ==================================================================================
-- Crafting prevention (mark item at craftstation -> remove from crafting slot again
-- ==================================================================================
--Functions for the extraction protection
local craftPrev = FCOIS.craftingPrevention
function craftPrev.IsShowingEnchantmentCreation()
    return not ctrlVars.ENCHANTING_RUNE_CONTAINER:IsHidden() or ctrlVars.SMITHING:IsCreating()
end
local isShowingEnchantmentCreation = craftPrev.IsShowingEnchantmentCreation

function craftPrev.IsShowingEnchantmentExtraction()
    return not ctrlVars.ENCHANTING_EXTRACTION_SLOT:IsHidden()
end
local isShowingEnchantmentExtraction = craftPrev.IsShowingEnchantmentExtraction

function craftPrev.IsShowingEnchantment()
    if isShowingEnchantmentCreation() or isShowingEnchantmentExtraction() then
        return true
    end
    return false
end
local isShowingEnchantment = craftPrev.IsShowingEnchantment

function craftPrev.IsShowingDeconstruction()
    return not ctrlVars.DECONSTRUCTION_SLOT:IsHidden() --or ctrlVars.SMITHING:IsDeconstructing()
end
local isShowingDeconstruction = craftPrev.IsShowingDeconstruction

function craftPrev.IsShowingImprovement()
    return not ctrlVars.IMPROVEMENT_SLOT:IsHidden() --or ctrlVars.SMITHING:IsImproving() --only checks if the tab is activated!
end
local isShowingImprovement = craftPrev.IsShowingImprovement

function craftPrev.IsShowingRefinement()
    return not ctrlVars.REFINEMENT_SLOT:IsHidden() --or ctrlVars.SMITHING:IsExtracting()
end
local isShowingRefinement = craftPrev.IsShowingRefinement

function craftPrev.IsShowingResearch()
    return not ctrlVars.RESEARCH:IsHidden()
end
local isShowingResearch = craftPrev.IsShowingResearch
function craftPrev.IsShowingAlchemy()
    return not ctrlVars.ALCHEMY_SLOT_CONTAINER:IsHidden()
end
local isShowingAlchemy = craftPrev.IsShowingAlchemy

function craftPrev.IsShowingProvisioner()
    return not ctrlVars.PROVISIONER_PANEL:IsHidden()
end
local isShowingProvisioner = craftPrev.IsShowingProvisioner

local function isShowingProvisionerFilterType(filterType)
    local retVar = isShowingProvisioner()
    if retVar then
        return ctrlVars.PROVISIONER.filterType == filterType
    end
    return false
end

function craftPrev.IsShowingProvisionerCook()
    return isShowingProvisionerFilterType(PROVISIONER_SPECIAL_INGREDIENT_TYPE_SPICES)
end
local isShowingProvisionerCook = craftPrev.IsShowingProvisionerCook()

function craftPrev.IsShowingProvisionerBrew()
    return isShowingProvisionerFilterType(PROVISIONER_SPECIAL_INGREDIENT_TYPE_FLAVORING)
end
local isShowingProvisionerBrew = craftPrev.IsShowingProvisionerBrew()

--Returns the crafting slot for the deconstruction, improvement, extraction, retrait etc.
function craftPrev.GetCraftingSlotControl(libFiltersPanelId)
    local isRetraitShown = isRetraitStationShown()
    local isCraftingStationShown = ZO_CraftingUtils_IsCraftingWindowOpen() and ctrlVars.RESEARCH:IsHidden() -- No crafting slot at research!
--d("[FCOIS]craftingPrevention.GetCraftingSlotControl()-libFiltersPanelId: " ..tos(libFiltersPanelId) ..", isCraftingStationShown: " ..tos(isCraftingStationShown) ..", isRetraitShown: " ..tos(isRetraitShown))
    local isValidPanelShown = isRetraitShown or isCraftingStationShown
    local craftingStationSlot
    --local craftingStationSlots
    --Crafting station shown?
    if isValidPanelShown then
        libFiltersPanelId = libFiltersPanelId or FCOIS.gFilterWhere
        checkIfUniversaldDeconstructionNPC = checkIfUniversaldDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC
        local isUniversalDeconNPC = checkIfUniversaldDeconstructionNPC(libFiltersPanelId)
        local craftingPanelSlots
--d(">searching crafting slot now for panelId: " ..tos(libFiltersPanelId) .. ", isUniversalDeconNPC: " ..tos(isUniversalDeconNPC))
        if not isUniversalDeconNPC then
            craftingPanelSlots = FCOIS.mappingVars.libFiltersPanelIdToCraftingPanelSlot
        else
            craftingPanelSlots = FCOIS.mappingVars.libFiltersPanelIdToUniversalCraftingPanelSlot
        end
        craftingStationSlot = craftingPanelSlots[libFiltersPanelId]
    end
    return craftingStationSlot
end
local getCraftingSlotControl = craftPrev.GetCraftingSlotControl

--Returns the bagId and slotIndex of a slotted item in the deconstruction/improvement/refine/enchant extraction slot
--With ESO update Scalebreaker the multi-craft and deconstruct/extract is supported by the game. You are able to add multiple items with a
--left mouse click to the slot and the items added are then in the subtable "items" of the deconstruction/extraction slot.
--This function checks if there are multiple items and returns the table of slotted items now as 3rd return parameter
function craftPrev.GetSlottedItemBagAndSlot()
--d("[FCOIS]craftingPrevention.GetSlottedItemBagAndSlot()")
    local isRetraitShown = isRetraitStationShown()
    local isCraftingStationShown = ZO_CraftingUtils_IsCraftingWindowOpen() and ctrlVars.RESEARCH:IsHidden() -- No crafting slot at research!
    local isValidPanelShown = isRetraitShown or isCraftingStationShown
    local bagId, slotIndex, slottedItems
    local craftingStationSlot
    --local craftingStationSlots
    --Crafting station shown?
    if isValidPanelShown then
        local currentFilterPanelId = FCOIS.gFilterWhere
--d(">valid panel shown, filterPanelId: " ..tos(currentFilterPanelId))
        craftingStationSlot = getCraftingSlotControl(currentFilterPanelId)
        --Is the crafting slot found, get the bagId and slotIndex of the slotted item now
        if craftingStationSlot ~= nil then
--d(">found slot")
            --Enchanting creation got 3 slots, not only 1
            if currentFilterPanelId == LF_ENCHANTING_CREATION then
--d(">>enchanting creation")
                if craftingStationSlot and type(craftingStationSlot) == "table" then
                    slottedItems = {}
                    for _, craftingStationSlotData in ipairs(craftingStationSlot) do
                        if craftingStationSlotData and craftingStationSlotData.items and #craftingStationSlotData.items > 0 then
                            for _, slottedItemData in ipairs(craftingStationSlotData.items) do
                                tins(slottedItems, slottedItemData)
                            end
                        end
                    end
                end
            elseif currentFilterPanelId == LF_ALCHEMY_CREATION then
                --d(">>Alchemy slots")
                --We got 4 slots to protect here now: 1 solvent ZO_AlchemyTopLevelSlotContainerSolventSlot and 3 reagents ZO_AlchemyTopLevelSlotContainerReagentSlot1 to 3
                -->craftingStationSlot will only contain the data of the SolventSlot!
                -->We need to add all 4 slots to the slotetdItems table

                --Solvent slot got any item slotted?
                if craftingStationSlot.bagId ~= nil and craftingStationSlot.slotIndex ~= nil then
                    slottedItems = {}
                    tins(slottedItems, { bagId=craftingStationSlot.bagId, slotIndex=craftingStationSlot.slotIndex })
                end

                --Check the 3 reagent slots too
                for i=1, 3, 1 do
                    local reagentSlot = GetControl(reagentSlotNamePrefix .. tos(i))
                    if reagentSlot ~= nil and reagentSlot.bagId ~= nil and reagentSlot.slotIndex ~= nil then
                        slottedItems = slottedItems or {}
                        tins(slottedItems, { bagId=reagentSlot.bagId, slotIndex=reagentSlot.slotIndex })
                    end
                end

            else
--d(">>others")
                --All others got just 1 slot
                if craftingStationSlot.GetBagAndSlot then
--d(">>func GetBagAndSlot was available")
                    bagId, slotIndex = craftingStationSlot:GetBagAndSlot()
                end
                slottedItems = craftingStationSlot.items
            end
        else
--d("<ERROR: CraftingSlot not found!")
        end
    end
    return bagId, slotIndex, slottedItems
end
local getSlottedItemBagAndSlot = craftPrev.GetSlottedItemBagAndSlot

function craftPrev.GetExtractionSlotAndWhereAreWe()
    checkIfUniversaldDeconstructionNPC = checkIfUniversaldDeconstructionNPC or FCOIS.CheckIfUniversalDeconstructionNPC
    local currentFilterId = FCOIS.gFilterWhere
    if checkIfUniversaldDeconstructionNPC(currentFilterId) then
        local whereAreWeAtUniversalDecon = universalDeconFilterPanelIdToWhereAreWe[currentFilterId]
        return ctrlVars.UNIVERSAL_DECONSTRUCTION_SLOT, whereAreWeAtUniversalDecon, ctrlVars.UNIVERSAL_DECONSTRUCTION_GLOBAL
    elseif isShowingEnchantmentExtraction() or currentFilterId == LF_ENCHANTING_EXTRACTION then
        return ctrlVars.ENCHANTING_EXTRACTION_SLOT, FCOIS_CON_ENCHANT_EXTRACT, ctrlVars.ENCHANTING
    elseif isShowingEnchantmentCreation() or currentFilterId == LF_ENCHANTING_CREATION then
        return ctrlVars.ENCHANTING_RUNE_CONTAINER, FCOIS_CON_ENCHANT_CREATE, ctrlVars.ENCHANTING -- Is the parent control for potency, essence and aspect rune slots!
    elseif isShowingDeconstruction() or currentFilterId == LF_SMITHING_DECONSTRUCT or currentFilterId == LF_JEWELRY_DECONSTRUCT then
        return ctrlVars.DECONSTRUCTION_SLOT, FCOIS_CON_DECONSTRUCT, ctrlVars.SMITHING
    elseif isShowingImprovement() or currentFilterId == LF_SMITHING_IMPROVEMENT or currentFilterId == LF_JEWELRY_IMPROVEMENT then
        return ctrlVars.IMPROVEMENT_SLOT, FCOIS_CON_IMPROVE, ctrlVars.SMITHING
    elseif isShowingRefinement() or currentFilterId == LF_SMITHING_REFINE or currentFilterId == LF_JEWELRY_REFINE then
        return ctrlVars.REFINEMENT_SLOT, FCOIS_CON_REFINE, ctrlVars.SMITHING
    elseif isShowingAlchemy() or currentFilterId == LF_ALCHEMY_CREATION then
        return ctrlVars.ALCHEMY_SOLVENT_SLOT, FCOIS_CON_ALCHEMY_DESTROY, ctrlVars.ALCHEMY
    end
end
local getExtractionSlotAndWhereAreWe = craftPrev.GetExtractionSlotAndWhereAreWe

--Remove an item from a crafting extraction/refinement slot
function craftPrev.RemoveItemFromCraftSlot(bagId, slotIndex, isSlotted)
--d("[FCOIS]craftingPrevention.RemoveItemFromCraftSlot - bagId: " ..tos(bagId) .. ", slot: " ..tos(slotIndex) .. ", isSlotted: " ..tos(isSlotted))
    if bagId == nil or slotIndex == nil then return false end
    isSlotted = isSlotted or false
    --Get the "WhereAreWe" constant by the help of the active deconstruction/extraction crafting panel
    local whereAreWe
    --The global crafting stations variable
    local craftingSlotVar
    local craftingStationVar
    craftingSlotVar, whereAreWe, craftingStationVar = getExtractionSlotAndWhereAreWe()
    if craftingStationVar == nil then return false end
    --Check if the item is slotted at the crafting station
    if not isSlotted then
        isSlotted = craftingStationVar:IsItemAlreadySlottedToCraft(bagId, slotIndex)

        --Bugfix #93 from 2020-08-18: After the improvement was done the function SMITHING:IsItemAlreadySlottedToCraft(bagId, slotIndex) will return false for
        --an already slotted item. So we cannot rely on this result!
        --We need to check if the slot control contains any item...
        if not isSlotted then
            --Manually check the slotted items and if found, set isSlotted to true
            local slottedItems
            bagId, slotIndex, slottedItems = getSlottedItemBagAndSlot()
            if slottedItems ~= nil then
--d(">craftingSlot found")
                isSlotted = true
            end
        end
    end
--d(">whereAreWe: " .. tos(whereAreWe) .. ", isSlotted: " ..tos(isSlotted) .. ", craftingStationVar: " .. tos(craftingStationVar.control:GetName()))
    --Item is not slotted so abort here
    if not isSlotted then return false end
    --Unequip the item from the crafting slot again
    craftingStationVar:RemoveItemFromCraft(bagId, slotIndex)
    --Check if alert or chat message should be shown
    --function outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
    outputItemProtectedMessage(bagId, slotIndex, whereAreWe, true, false, false, false)
end
local removeItemFromCraftSlot = craftPrev.RemoveItemFromCraftSlot

--Function to check if items for extraction/deconstruction/improvement are currently saved (got saved after adding them to the extraction slot)
function craftPrev.CheckPreventCrafting(override, extractSlot, extractWhereAreWe)
--d("[FCOIS]craftPrev.CheckPreventCrafting")
    override = override or false
    --Initialize the return variable with false so this PreHook function won't abort the extraction
    local retVar = false
    --Reset variables
    craftPrev.extractSlot = nil
    craftPrev.extractWhereAreWe = nil
    --Get the extraction container and function
    if not override then
        craftPrev.extractSlot, craftPrev.extractWhereAreWe = getExtractionSlotAndWhereAreWe()
    else
        --Used for recursively called 3 enchanting creation rune slots
        craftPrev.extractSlot = extractSlot
        craftPrev.extractWhereAreWe = extractWhereAreWe
    end
    if craftPrev.extractSlot == nil or craftPrev.extractWhereAreWe == nil then return false end
    --d("[FCOIS]craftingPrevention.CheckPreventCrafting - whereAreWe: " .. tos(craftPrev.extractWhereAreWe))
    --Check if the current extraction slot item is protected and abort if so
    --get the bagId and slotIndex of the item that should be extracted
    local bagId
    local slotIndex
    if craftPrev.extractWhereAreWe ~= FCOIS_CON_ENCHANT_CREATE or (override and extractWhereAreWe == FCOIS_CON_ENCHANT_CREATE) then
        bagId     = craftPrev.extractSlot.bagId
        slotIndex = craftPrev.extractSlot.slotIndex
    else
        --At enchanting creation there are 3 slots to check: aspect, potency and essence rune:
        --ZO_EnchantingTopLevelRuneSlotContainerPotencyRune
        --ZO_EnchantingTopLevelRuneSlotContainerEssenceRune
        --ZO_EnchantingTopLevelRuneSlotContainerAspectRune
        --Recursively call this function to remove the marked runes
        local enchantingCreationSlos = {
            [1] = ctrlVars.ENCHANTING_RUNE_CONTAINER_POTENCY,
            [2] = ctrlVars.ENCHANTING_RUNE_CONTAINER_ESSENCE,
            [3] = ctrlVars.ENCHANTING_RUNE_CONTAINER_ASPECT,
        }
        local retVarLoop = false
        local locCheckPreventCrafting = craftPrev.CheckPreventCrafting
        for i=1, 3 do
            local runeSlot = enchantingCreationSlos[i]
            if runeSlot ~= nil then
                local returnVar = false
                --Call function recursively and override with the 3 enchanting creation rune slots
                returnVar = locCheckPreventCrafting(true, runeSlot, FCOIS_CON_ENCHANT_CREATE)
                --Only overwrite the reurn variable for the loop if the value is "true" -> Abort the extract function
                if not retVarLoop then
                    retVarLoop = returnVar
                end
            end
        end
        --Call/Skip the original create function now -> If runes were removed it will be skipped!
        return retVarLoop
    end
    --Is an item put into the extraction slot?
    if bagId ~= nil and slotIndex ~= nil then
        FCOIScdsh = FCOIScdsh or FCOIS.callDeconstructionSelectionHandler
        return FCOIScdsh(bagId, slotIndex, true, false, false, false)
    end
    --Reset variables again
    craftPrev.extractSlot = nil
    craftPrev.extractWhereAreWe = nil
    return retVar
end

--Remove an item from the retrait slot
function craftPrev.RemoveItemFromRetraitSlot(bagId, slotIndex, isSlotted)
    --d("[craftPrev.RemoveItemFromRetraitSlot] isSlotted: " ..tos(isSlotted))
    if bagId == nil or slotIndex == nil then return false end
    isSlotted = isSlotted or false
    --Are we at an enchanting station?
    --The global retrait station variable
    if ctrlVars.RETRAIT_INV:IsHidden() then return false end
    local retraitStationVar = ctrlVars.RETRAIT_RETRAIT_PANEL
    --The "WhereAreWe" constant for the retrait station
    local whereAreWe = FCOIS_CON_RETRAIT
    --Check if the item is slotted at the retrait station
    if not isSlotted then
        isSlotted = retraitStationVar:IsItemAlreadySlottedToCraft(bagId, slotIndex)
        --d(">isSlotted: " ..tos(isSlotted))
    end
    --Item is not slotted so abort here
    if not isSlotted then return false end
--d(">removing item from trait station slot")
    --Unequip the item from the crafting slot again
    retraitStationVar:RemoveItemFromRetrait() --bagId, slotIndex)
    --Check if alert or chat message should be shown
    --function outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
    outputItemProtectedMessage(bagId, slotIndex, whereAreWe, true, false, false, false)
end
local removeItemFromRetraitSlot = craftPrev.RemoveItemFromRetraitSlot

--This function scans the currently shown inventory rows data for the same itemInstanceId which the bagId and slotIndex
--given as parameters got. If another item with the same itemInstanceId is found the function returns the bagId and slotIndex.
--As multiple same items could be found each found item will be added to the return table!
function FCOIS.CheckCurrentInventoryRowsDataForItemInstanceId(bagIdToSkip, slotIndexToSkip)
--d("[FCOIS].checkCurrentInventoryRowsDataForItemInstanceId")
    if bagIdToSkip == nil or slotIndexToSkip == nil then return end
    local itemInstanceIdToFind = GetItemInstanceId(bagIdToSkip, slotIndexToSkip)
    if itemInstanceIdToFind == nil then return end
    local foundBagdIdAndSlotIndices
    local filterPanelsIdToInv = FCOIS.mappingVars.gFilterPanelIdToInv
    --Get the currently shown inventory container for the inventory list with the rows and it's data
    --e.g. SMITHING.deconstructionPanel.inventory.list.data[1].data.itemInstanceId
    local inventoryContainerVar = filterPanelsIdToInv[FCOIS.gFilterWhere]
    if inventoryContainerVar == nil then return false end
    --Get the data of the inventoryContainer (the rows)
    local dataRows = inventoryContainerVar.data
    if dataRows == nil then return end
    for _, rowData in ipairs(dataRows) do
        local rowDataData = rowData.data
        if rowDataData and rowDataData.bagId and rowDataData.slotIndex and rowDataData.slotIndex ~= slotIndexToSkip then
            local itemInstanceIdToCompare = rowDataData.itemInstanceId
            if itemInstanceIdToCompare ~= nil and itemInstanceIdToCompare == itemInstanceIdToFind then
                --Add item bagId and slotIndex to the return table
                foundBagdIdAndSlotIndices = foundBagdIdAndSlotIndices or {}
                tins(foundBagdIdAndSlotIndices, {["bagId"] = rowDataData.bagId, ["slotIndex"] = rowDataData.slotIndex })
            end
        end
    end
    return foundBagdIdAndSlotIndices
end
local checkCurrentInventoryRowsDataForItemInstanceId = FCOIS.CheckCurrentInventoryRowsDataForItemInstanceId

--Is the item protected at a crafting table's slot now
function craftPrev.IsItemProtectedAtACraftSlotNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    --[[
    if bagId and slotIndex then
        local itemLink = gil(bagId, slotIndex)
        d("[FCOIS]craftingPrevention.IsItemProtectedAtACraftSlotNow: " ..itemLink)
    else
        d("[FCOIS]craftingPrevention.IsItemProtectedAtACraftSlotNow - No bagId or slotIndex given!")
    end
    ]]
    --Are we inside a crafting or retrait station?
    local isRetraitShown = isRetraitStationShown()
    local slottedItems
    local isCraftingStationShown = not isRetraitShown and ZO_CraftingUtils_IsCraftingWindowOpen() and ctrlVars.RESEARCH:IsHidden() -- No crafting slot at research!
--d(">isCraftingStationShown: " .. tos(isCraftingStationShown) .. ", isRetraitShown: " ..tos(isRetraitShown) .. ", filterPanelId: " ..tos(FCOIS.gFilterWhere))
    if isCraftingStationShown or isRetraitShown then
        local allowedCraftingPanelIdsForMarkerRechecks = FCOIS.checkVars.allowedCraftingPanelIdsForMarkerRechecks
        --Check if a refine/deconstruct/create glyph/extract/improve/create alchemy panel is shown
        if allowedCraftingPanelIdsForMarkerRechecks[FCOIS.gFilterWhere] then
            --Is the bagId and slotIndex nil then get the slotted item's bagId and slotIndex now
            if bagId == nil and slotIndex == nil then
                bagId, slotIndex, slottedItems = getSlottedItemBagAndSlot()
            end
            --local helper function to check the protection and remove the item from the craft slot
            local function checkProtectionAndRemoveFromSlotIfProtected(p_bagId, p_slotIndex)
--d("~~~~~~~~~  checkProtectionAndRemoveFromSlotIfProtected: " .. gil(p_bagId, p_slotIndex) .. " ~~~~~~~~~")
                local retVar = false
                --Check if the item is currently slotted at a crafting station's extraction slot. If the item is proteced remove it from the extraction slot again!
                --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
                FCOIScdsh = FCOIScdsh or FCOIS.callDeconstructionSelectionHandler
                local isProtected = FCOIScdsh(p_bagId, p_slotIndex, false, false, true, false, true, false)
                --Item is protected?
--d(">item " .. gil(p_bagId, p_slotIndex) .. " is protected: " ..tos(isProtected))
                if isProtected then
                    if isRetraitShown then
                        --d("Item is protected! Remove it from the retrait slot and output error message now")
                        removeItemFromRetraitSlot(p_bagId, p_slotIndex, false)
                        retVar = true
                    else
--d("Item is protected! Remove it from the crafting slot and output error message now")
                        removeItemFromCraftSlot(p_bagId, p_slotIndex, false)
                        retVar = true
                    end
                end
                return retVar
            end
            --Table with all slotted items is given?
            if (bagId == nil or slotIndex == nil) and slottedItems ~= nil then
--d(">table with slotted items given")
                --For each table entry check if the item is protected and remove where needed
                for _, slottedData in ipairs(slottedItems) do
                    if slottedData.bagId and slottedData.slotIndex then
                        checkProtectionAndRemoveFromSlotIfProtected(slottedData.bagId , slottedData.slotIndex)
                        --This item is (n)ot protected, but maybe the same item in another inventory slotIndex is currently slotted to the crafting slot
                        --and got protected as you marked the currently checked item (which is not slotted).
                        -->Scan the currently visible inventory rows for such items and if they are slotted.
                        if scanOtherInvItemsIfSlotted then
--local itemLink = gil(slottedData.bagId, slottedData.slotIndex)
--d(">checking slotted items: " ..itemLink)

                            local foundBagdIdAndSlotIndices = checkCurrentInventoryRowsDataForItemInstanceId(slottedData.bagId, slottedData.slotIndex)
                            if foundBagdIdAndSlotIndices ~= nil then
                                for _, invItemData in ipairs(foundBagdIdAndSlotIndices) do
                                    checkProtectionAndRemoveFromSlotIfProtected(invItemData.bagId, invItemData.slotIndex)
                                end
                            end
                        end
                    end
                end
            --Only 1 item is checked
            elseif bagId ~= nil and slotIndex ~= nil then
                checkProtectionAndRemoveFromSlotIfProtected(bagId, slotIndex)
                --This item is (not) protected, but maybe the same item in another inventory slotIndex is currently slotted to the crafting slot
                --and got protected as you marked the currently checked item (which is not slotted).
                -->Scan the currently visible inventory rows for such items and if they are slotted.
                if scanOtherInvItemsIfSlotted then
                    local foundBagdIdAndSlotIndices = checkCurrentInventoryRowsDataForItemInstanceId(bagId, slotIndex)
                    if foundBagdIdAndSlotIndices ~= nil then
                        for _, invItemData in ipairs(foundBagdIdAndSlotIndices) do
                            checkProtectionAndRemoveFromSlotIfProtected(invItemData.bagId, invItemData.slotIndex)
                        end
                    end
                end
            end
        end
    end
end
local isItemProtectedAtACraftSlotNow = craftPrev.IsItemProtectedAtACraftSlotNow

--Function to check if a crafting panel is shown and if an item from the craftbag got dragged to the
--slot of the crafting station
function FCOIS.IsCraftBagItemDraggedToCraftingSlot(panelId, bagId, slotIndex)
    --Check if a filter panel parent (e.g. Craftbag panel is active at the mail send panel = Mail send is the parent)
    local parentPanelId = FCOIS.gFilterWhereParent
    if parentPanelId == nil then
        parentPanelId = FCOIS.gFilterWhere
    end
    panelId = panelId or parentPanelId
    local panelIdToCheckFunc = {
        [LF_SMITHING_REFINE]        = isShowingRefinement,
        [LF_ENCHANTING_CREATION]    = isShowingEnchantment, -- Check which one is shown, creation or extraction
        --Enchanting creation and extraction are both handled via the creation hook!
        --[LF_ENCHANTING_EXTRACTION]  = craftPrev.IsShowingEnchantmentExtraction,
        [LF_ALCHEMY_CREATION]       = isShowingAlchemy,
        [LF_PROVISIONING_COOK]      = isShowingProvisionerCook,
        [LF_PROVISIONING_BREW]      = isShowingProvisionerBrew,
    }
    local checkFunc = panelIdToCheckFunc[panelId]
    if checkFunc == nil then return false end
--d("[FCOIS] Received item drag at crafting station")
    if checkFunc() and bagId ~= nil then
        --local itemLink = gil(bagId, slotIndex)
--d(">" .. itemLink .. " - bag: " ..tos(bagId) .. ", slotIndex: " ..tos(slotIndex))
        --Is the item from the craftbag?
        if bagId == BAG_VIRTUAL then
--d(">Craftbag item")
            -- bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId, isDragAndDrop, panelIdParent
            if( FCOIS.callItemSelectionHandler(bagId, slotIndex, true, true, false, true, false, false, nil, true, nil) ) then
                --d(">Item is protected so don't allow the drop!")
                --Remove the picked item from drag&drop cursor
                ClearCursor()
                return true
            end
        end
    end
end

--Function to check if an item is protected at the guild store sell tab now, after it got marked with a marker icon.
--If so: Remove the item from the guild store's sell slot again, if it is slotted
function FCOIS.IsItemProtectedAtTheGuildStoreSellTabNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    if not ctrlVars.GUILD_STORE:IsHidden() and ctrlVars.GUILD_STORE_KEYBOARD:IsInSellMode() then
        --Check if marked item is currently in the "sell slot" and remove it again, if it is protected
        if (ctrlVars.GUILD_STORE_SELL_SLOT_ITEM ~= nil and (ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.bagId ~= nil and ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.slotIndex ~= nil)
                and     (bagId ~= nil and slotIndex ~= nil and ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.bagId == bagId and ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.slotIndex == slotIndex)
                    or  (bagId == nil and slotIndex == nil) )
        then
            bagId = ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.bagId
            slotIndex = ctrlVars.GUILD_STORE_SELL_SLOT_ITEM.slotIndex
            --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
            --Be sure to set calledFromExternalAddon = true here as otherwise the guild store sell checks aren't done, because
            --the DeconstructionSelectionhandler will not call the ItemSelectionHandler then!
            --                                                           bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon, panelId
            FCOIScdsh = FCOIScdsh or FCOIS.callDeconstructionSelectionHandler
            local isProtected = FCOIScdsh(bagId, slotIndex, false, false, true, false, true, true, nil)
--d("[FCOIS]IsItemProtectedAtTheGuildStoreSellTabNow GuildStore - isProtected: " ..tos(isProtected))
            --Item is protected?
            if isProtected == true then
--d("GuildStore: Item is protected! Output error message now")
                --Remove the item from the guild store sell slot
                --If AwesomeGuildStore is active the normal SetPendingItemPost does not work, so we use the same as AGS uses to unslot items
                if FCOIS.otherAddons.AGSActive == true then
                    --TRADING_HOUSE:OnPendingPostItemUpdated
                    ctrlVars.playerInventory:OnInventorySlotUnlocked(bagId, slotIndex)
                    ctrlVars.GUILD_STORE_KEYBOARD:OnPendingPostItemUpdated(0, false)
                else
                    --BAG_BACKPACK is used as even CraftBag items get moved to the bagpack before listing them! Even with addon CraftBagExtended
                    SetPendingItemPost(BAG_BACKPACK, 0, 0)
                end
                local whereAreWe = FCOIS_CON_GUILD_STORE_SELL
                --function outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                outputItemProtectedMessage(bagId, slotIndex, whereAreWe, true, false, false, false)
            end
        end
    end
end
local isItemProtectedAtTheGuildStoreSellTabNow = FCOIS.IsItemProtectedAtTheGuildStoreSellTabNow

function FCOIS.AreItemsProtectedAtMailSendPanel(bagId, slotIndex, doNotRemoveJustWarn)
    local wasProtected = false
    if not isSendingMail() then return false end

    local attachmentSlotsParent = ctrlVars.MAIL_ATTACHMENTS
    --Check each of the attachmenmt slots
    for i = 1, MAIL_MAX_ATTACHED_ITEMS do
        -- Return value would be 1 if item is slotted in this attachment slot
        if GetQueuedItemAttachmentInfo(i) ~= 0 then
            --Get the slot i's slotIndex
            local slotControl = attachmentSlotsParent[i]
            --Search the slotControl slotIndex and compare it with the actually checked item's slotIndex
            if (slotControl ~= nil
                and     (bagId ~= nil and slotIndex ~= nil and slotControl.bagId ~= nil and slotControl.bagId == bagId and slotControl.slotIndex ~= nil and slotControl.slotIndex == slotIndex)
                    or  (bagId == nil and slotIndex == nil and slotControl.bagId ~= nil and slotControl.slotIndex ~= nil) )
            then
                --Item was found: Check if it is protected now
--d("[FCOIS]MarkMe ProtectedAtSlotNow - callDeconstructionSelectionHandler without echo")
                --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
                --Be sure to set calledFromExternalAddon = true here as otherwise the guild store sell checks aren't done, because
                --the DeconstructionSelectionhandler will not call the ItemSelectionHandler then!
                FCOIScdsh = FCOIScdsh or FCOIS.callDeconstructionSelectionHandler
                local isProtected = FCOIScdsh(slotControl.bagId, slotControl.slotIndex, false, false, true, false, true, true)
                --Item is protected?
                if isProtected then
                    --#263 Do not remove, just warn, if mail panel was reopened
                    if not doNotRemoveJustWarn then
                        --Item is protected now, so remove it from the mail attachment slot again
                        RemoveQueuedItemAttachment(i)
                    end
                    local whereAreWe = FCOIS_CON_MAIL
                    --function outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                    outputItemProtectedMessage(slotControl.bagId, slotControl.slotIndex, whereAreWe, true, false, false, false)
                end
                wasProtected = isProtected
            end
        end
    end
    return wasProtected
end
local areItemsProtectedAtMailSendPanel = FCOIS.AreItemsProtectedAtMailSendPanel

--Function to check if an item is protected at a libFilters filter panel ID now, after it got marked with a marker icon.
--If so: Remove the item from the panel's slot again, if it is slotted
function FCOIS.IsItemProtectedAtPanelNow(bagId, slotIndex, panelId, scanOtherInvItemsIfSlotted, doNotRemoveJustWarn)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    doNotRemoveJustWarn = doNotRemoveJustWarn or false
    panelId = panelId or FCOIS.gFilterWhere
--d("[FCOIS]IsItemProtectedAtPanelNow-bagId: " ..tos(bagId) .. ", slotIndex: " ..tos(slotIndex) .. ", panelId: " ..tos(panelId) .. ", scanOtherInvItemsIfSlotted: " ..tos(scanOtherInvItemsIfSlotted))
    if panelId == nil then return nil end
    --Mail send
    if panelId == LF_MAIL_SEND then
        --local wasProtected
        areItemsProtectedAtMailSendPanel(bagId, slotIndex, doNotRemoveJustWarn)

    --Player2Player trade
    elseif panelId == LF_TRADE then
        local playerTrade = ctrlVars.PLAYER_TRADE
        local playerTradeWindow = ctrlVars.PLAYER_TRADE_WINDOW
        if (playerTradeWindow and playerTradeWindow:IsTrading()) or (playerTrade and not playerTrade.control:IsHidden()) or not ctrlVars.PLAYER_TRADE_ATTACHMENTS:IsHidden() then
            --local functions for mail send checks
            local function CheckTradeAttachments()
                for i = 1, TRADE_NUM_SLOTS do
                    local bagIdTradeSlot, slotIndexTradeSlot = GetTradeItemBagAndSlot(TRADE_ME, i)
                    if (bagIdTradeSlot and slotIndexTradeSlot
                        and     (bagId ~= nil and slotIndex ~= nil and bagIdTradeSlot == bagId and slotIndexTradeSlot == slotIndex)
                            or  (bagId == nil and slotIndex == nil))
                    then
                        --Item was found: Check if it is protected now
                        --d("[FCOIS]MarkMe ProtectedAtSlotNow - callDeconstructionSelectionHandler without echo")
                        --FCOIS.callDeconstructionSelectionHandler(bag, slot, echo, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert, calledFromExternalAddon)
                        --Be sure to set calledFromExternalAddon = true here as otherwise the guild store sell checks aren't done, because
                        --the DeconstructionSelectionhandler will not call the ItemSelectionHandler then!
                        FCOIScdsh = FCOIScdsh or FCOIS.callDeconstructionSelectionHandler
                        local isProtected = FCOIScdsh(bagIdTradeSlot, slotIndexTradeSlot, false, false, true, false, true, true)
                        --Item is protected?
                        if isProtected then
                            TradeRemoveItem(i)
                            local whereAreWe = FCOIS_CON_TRADE
                            --function outputItemProtectedMessage(bag, slot, whereAreWe, overrideChatOutput, suppressChatOutput, overrideAlert, suppressAlert)
                            outputItemProtectedMessage(bagIdTradeSlot, slotIndexTradeSlot, whereAreWe, true, false, false, false)
                        end
                    end
                end
            end
            --Check the attachments now and unslot them if they are protected now
            CheckTradeAttachments()
        end
    end
end
local isItemProtectedAtPanelNow = FCOIS.IsItemProtectedAtPanelNow

--Is the item marked as junk? Remove it from junk again if a non-junkable marker icon was set now
--> Only remove from bulk
---- if setting to not remove normal (keybind/context menu) marked items from junk is disabled
---- if setting to not remove bulk (additional inventory "flag" icon) marked items from junk is disabled
function FCOIS.CheckIfIsJunkItem(bagId, slotIndex, bulkMark, scanOtherInvItemsIfSlotted)
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    if bagId == nil or slotIndex == nil then return false end
    bulkMark = bulkMark or false
    if IsItemJunk(bagId, slotIndex) and FCOIS.IsJunkLocked(bagId, slotIndex) then
        local settings = FCOIS.settingsVars.settings
        --Are we bulk marking the item and is the option to "not remove items from junk on bulk mark" enabled?
        if bulkMark then
            local dontUnjunkOnBulkMark = settings.dontUnjunkOnBulkMark
            if dontUnjunkOnBulkMark then return false end
        else
            local dontUnjunkOnNormalMark = settings.dontUnjunkOnNormalMark
            if dontUnjunkOnNormalMark then return false end
        end
        --Unjunk the marked item now
        SetItemIsJunk(bagId, slotIndex, false)
    end
end
local checkIfIsJunkItem = FCOIS.CheckIfIsJunkItem

--Function to check if an item is protected at a slot (crafting, junk, mail, trade, etc.) at the moment, and if so,
--remove it from the slot/junk now.
--Parameter bulkMark is used for the junk checks, if the additional inventory "flag" icon context menu is used for mass-junk/unjunk
function FCOIS.IsItemProtectedAtASlotNow(bagId, slotIndex, bulkMark, scanOtherInvItemsIfSlotted)
    bulkMark = bulkMark or false
    scanOtherInvItemsIfSlotted = scanOtherInvItemsIfSlotted or false
    --Check if the item was marked and then needs to be protected, if it's slotted at a crafting/retrait station!
    isItemProtectedAtACraftSlotNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    --Are we inside the guild store's sell tab?
    isItemProtectedAtTheGuildStoreSellTabNow(bagId, slotIndex, scanOtherInvItemsIfSlotted)
    --Check if the item is protected at the junk tab now
    checkIfIsJunkItem(bagId, slotIndex, bulkMark, scanOtherInvItemsIfSlotted)
    --Check if the item is protected at any other panel now
    local panelIdToUse = FCOIS.gFilterWhere
    --Check if we are at the CraftBag and another parent panel needs to be checked:
    if panelIdToUse == LF_CRAFTBAG then
        --As the CraftBag can be active at the mail send, trade, guild store sell and guild bank panels too we need to check if we are currently using the
        --addon CraftBagExtended and if the parent panel ID (filterPanelIdParent) is one of the above mentioned
        -- -> See callback function for CRAFT_BAG_FRAGMENT in the PreHooks section!
        if FCOIS.CheckIfCBEorAGSActive(FCOIS.gFilterWhereParent) then
            panelIdToUse = FCOIS.gFilterWhereParent
        end
    end
    isItemProtectedAtPanelNow(bagId, slotIndex, panelIdToUse, scanOtherInvItemsIfSlotted)
end

--Check if withdraw from guild bank is allowed, or block deposit of items
function FCOIS.CheckIfGuildBankWithdrawAllowed(currentGuildBank)
    if not currentGuildBank then return false end
    --Check if the "anti-guild bank deposit if no withdraw rights are given" protection is enabled
    if not FCOIS.settingsVars.settings.blockGuildBankWithoutWithdraw then return false end
    --Check if the player got the rights to withdraw items from the guild bank
    local retVal = DoesPlayerHaveGuildPermission(currentGuildBank, GUILD_PERMISSION_BANK_WITHDRAW)
    return retVal
end

--Transmutation geode loot protection so you do not loot 50 crystals if you already got 199 of max 200
--Get the currency amount of the transmuation crystals and the maximum value
local function getTransmutationCrystalAmount()
    local transmCrystalCount    = GetCurrencyAmount(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT)
    local transmCrystalCountMax = GetMaxPossibleCurrency(CURT_CHAOTIC_CREATIA, CURRENCY_LOCATION_ACCOUNT)
    return transmCrystalCount, transmCrystalCountMax
end

--Check if the transmutation crystals are above the threshold value of "max" minus "maximum looted crystals"
-- and show a dialog then that asks if you really want to loot the transmuation geode
function FCOIS.CheckAndShowTransmutationGeodeLootDialog()
    --d("[FCOIS.checkAndShowTransmutationGeodeLootDialog]")
    local settings = FCOIS.settingsVars.settings
    if not settings.showTransmutationGeodeLootDialog or CURT_CHAOTIC_CREATIA == nil or not IsCurrencyValid(CURT_CHAOTIC_CREATIA) then return false end
    local maximumLootedTrasmCrystals = 50 -- currently max 50 crystals can be looted from the PvP/AvA stuff
    local curCurrent, curMax = getTransmutationCrystalAmount()
    if curCurrent >= (curMax - maximumLootedTrasmCrystals) then
        --Show the dialog if the return value is true
        --d("[FCOIS]TRANSMUTATION LOOT DIALOG!")
        --Return true so the normal loot function is not called!
        return true, curCurrent, curMax
    else
        --Do not show a dialog and loot the crystals from the geode as normal
        return false, 0, 0
    end
end
