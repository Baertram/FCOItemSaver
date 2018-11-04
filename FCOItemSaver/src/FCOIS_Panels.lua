--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

--==========================================================================================================================================
--                                          FCOIS - Panel functions
--==========================================================================================================================================

--Function to check if the currently shown panel is the craftbag
function FCOIS.isCraftbagPanelShown()
    local retVar = INVENTORY_CRAFT_BAG and not FCOIS.ZOControlVars.CRAFTBAG:IsHidden()
    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( "[FCOIS.isCraftbagPanelShown] result: " .. tostring(retVar), true, FCOIS_DEBUG_DEPTH_SPAM) end
    return retVar
end

--Check if the craftbag panel is currently active and change the panelid to craftbag, or the wished one.
--Change the parentPanelId too (e.g. mail send, or bank deposit) if the craftbag is active!
function FCOIS.checkCraftbagOrOtherActivePanel(wishedPanelId)
    if wishedPanelId == nil then return LF_INVENTORY, nil end
    local newPanelId
    local newParentPanelId
    --Workaround: Craftbag stuff, check if active panel is the Craftbag
    if FCOIS.isCraftbagPanelShown() then
        newPanelId = LF_CRAFTBAG
        --Check if last active shown filter panel was the craftbag (e.g. at the bank deposit tab) and update the
        --parent filter panel to mail now, because the craftbag scene "shown" callback function will not be called,
        --if you directly switch to the mail sent panel via keybind (and the craftbag panel there was last used).
        --The parent will be resettted to NIL again upon craftbag scene hiding which happens if you leave the mail sent panel.
        newParentPanelId = wishedPanelId
    else
        newPanelId = wishedPanelId
    end
    --d("[FCOIS.checkCraftbagOrOtherActivePanel - New panel id: " .. tostring(newPanelId) .. ", filterParent: " ..tostring(newParentPanelId))
    return newPanelId, newParentPanelId
end

--Get the "real" active panel.
--If you are at the bank e.g. panelId is 2 (FCOIS.gFilterWhere was set in event BANK_OPEN), but you could also be at the deposit tab which uses
--the normal inventory filters of panelId = 1. The same applies for mail, trade, and others
function FCOIS.checkActivePanel(comingFrom, overwriteFilterWhere)
    if overwriteFilterWhere == nil then overwriteFilterWhere = false end
    local inventoryName
    local ctrlVars = FCOIS.ZOControlVars

    --Get the current scene's name to be able to distinguish between bank, guildbank, mail etc. when changing to CBE's craftbag panels
    local currentSceneName = SCENE_MANAGER.currentScene.name
    --Debug
    if FCOIS.settingsVars.settings.debug then
        local oldFilterWhere
        if comingFrom == 0 or comingFrom == nil then
            --Get the current filter panel id
            oldFilterWhere = FCOIS.gFilterWhere
        else
            oldFilterWhere = comingFrom
        end
        FCOIS.debugMessage( "[FCOIS.checkActivePanel] Coming from/Before: " .. tostring(oldFilterWhere) .. ", overwriteFilterWhere: " .. tostring(overwriteFilterWhere) .. ", currentSceneName: " ..tostring(currentSceneName), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED)
    end

--d("[FCOIS.checkActivePanel] comingFrom: " .. tostring(comingFrom) .. ", overwriteFilterWhere: " ..tostring(overwriteFilterWhere))

    --Player bank
    if (currentSceneName ~= nil and currentSceneName == ctrlVars.bankSceneName and not ctrlVars.BANK:IsHidden()) or comingFrom == LF_BANK_WITHDRAW then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_BANK_WITHDRAW)
        inventoryName = ctrlVars.BANK_INV
    --House bank
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars.houseBankSceneName and not ctrlVars.HOUSE_BANK:IsHidden()) or comingFrom == LF_HOUSE_BANK_WITHDRAW then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_HOUSE_BANK_WITHDRAW)
        inventoryName = ctrlVars.HOUSE_BANK_INV
    --Player inventory at bank (deposit)
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars.bankSceneName and ctrlVars.BANK:IsHidden()) or comingFrom == LF_BANK_DEPOSIT then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_BANK_DEPOSIT)
        inventoryName = ctrlVars.INV
    --Player inventory at house bank (deposit)
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars.houseBankSceneName and ctrlVars.HOUSE_BANK:IsHidden()) or comingFrom == LF_HOUSE_BANK_DEPOSIT then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_HOUSE_BANK_DEPOSIT)
        inventoryName = ctrlVars.INV
    --Guild bank
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars.guildBankSceneName and not ctrlVars.GUILD_BANK:IsHidden()) or comingFrom == LF_GUILDBANK_WITHDRAW then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_GUILDBANK_WITHDRAW)
        inventoryName = ctrlVars.GUILD_BANK_INV
    --Player inventory at guild bank (deposit)
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars.guildBankSceneName and ctrlVars.GUILD_BANK:IsHidden()) or comingFrom == LF_GUILDBANK_DEPOSIT then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_GUILDBANK_DEPOSIT)
        inventoryName = ctrlVars.INV
    --Trading house / Guild store
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars.tradingHouseSceneName and not ctrlVars.GUILD_STORE:IsHidden()) or comingFrom == LF_GUILDSTORE_SELL then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_GUILDSTORE_SELL)
        inventoryName = ctrlVars.INV
    --Vendor buy
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars.vendorSceneName) or comingFrom == LF_VENDOR_BUY) and not ctrlVars.STORE:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_VENDOR_BUY)
        --inventoryName = ctrlVars.VENDOR_SELL
        inventoryName = ctrlVars.INV
    --Vendor sell (not showing the buy, buyback or repair tabs and showing the player inventory or the craftbag panel)
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars.vendorSceneName) or comingFrom == LF_VENDOR_SELL)
        and (ctrlVars.STORE:IsHidden() and ctrlVars.STORE_BUY_BACK:IsHidden() and ctrlVars.REPAIR_LIST:IsHidden()) then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_VENDOR_SELL)
        --inventoryName = ctrlVars.VENDOR_SELL
        inventoryName = ctrlVars.INV
    --Vendor buyback
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars.vendorSceneName) or comingFrom == LF_VENDOR_BUYBACK) and not ctrlVars.STORE_BUY_BACK:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_VENDOR_BUYBACK)
        --inventoryName = ctrlVars.VENDOR_SELL
        inventoryName = ctrlVars.INV
    --Vendor repair
    elseif ((currentSceneName ~= nil and currentSceneName == ctrlVars.vendorSceneName) or comingFrom == LF_VENDOR_REPAIR) and not ctrlVars.REPAIR_LIST:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_VENDOR_REPAIR)
        --inventoryName = ctrlVars.VENDOR_SELL
        inventoryName = ctrlVars.INV
    --Fence
    elseif comingFrom == LF_FENCE_SELL then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_FENCE_SELL)
        --inventoryName = ctrlVars.FENCE
        inventoryName = ctrlVars.INV
    --Launder
    elseif comingFrom == LF_FENCE_LAUNDER then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_FENCE_LAUNDER)
        --inventoriyName = ctrlVars.LAUNDER
        inventoryName = ctrlVars.INV
    --Mail
    elseif (currentSceneName ~= nil and currentSceneName == ctrlVars.mailSendSceneName and not ctrlVars.MAIL_SEND:IsHidden()) or comingFrom == LF_MAIL_SEND then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_MAIL_SEND)
        --inventoryName = ctrlVars.MAIL_SEND
        inventoryName = ctrlVars.INV
    --Trade
    elseif not ctrlVars.PLAYER_TRADE:IsHidden() or comingFrom == LF_TRADE then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_TRADE)
        --inventoryName = ctrlVars.PLAYER_TRADE
        inventoryName = ctrlVars.INV
    --Enchanting creation mode
    elseif comingFrom == LF_ENCHANTING_CREATION then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_ENCHANTING_CREATION)
        inventoryName = ctrlVars.ENCHANTING_STATION
    --Enchanting extraction mode
    elseif comingFrom == LF_ENCHANTING_EXTRACTION then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_ENCHANTING_EXTRACTION)
        inventoryName = ctrlVars.ENCHANTING_STATION
    --Enchanting
    elseif comingFrom == "ENCHANTING" then
        --Determine which enchanting mode is used
        --Enchanting creation mode
        if ctrlVars.ENCHANTING.enchantingMode == 1 then
            --Update the filterPanelId
            comingFrom = LF_ENCHANTING_CREATION
            FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_ENCHANTING_CREATION)
            inventoryName = ctrlVars.ENCHANTING_STATION
        --Enchanting extraction mode
        elseif ctrlVars.ENCHANTING.enchantingMode == 2 then
            --Update the filterPanelId
            comingFrom = LF_ENCHANTING_EXTRACTION
            FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_ENCHANTING_EXTRACTION)
            inventoryName = ctrlVars.ENCHANTING_STATION
        end
    --Alchemy
    elseif not ctrlVars.ALCHEMY_STATION:IsHidden() or comingFrom == LF_ALCHEMY_CREATION then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_ALCHEMY_CREATION)
        inventoryName = ctrlVars.ALCHEMY_INV
    --Refinement
    elseif not ctrlVars.REFINEMENT_INV:IsHidden() or (comingFrom == LF_SMITHING_REFINE or comingFrom == LF_JEWELRY_REFINE) then
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_REFINE
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_REFINE
        end
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(filterPanelId)
        inventoryName = ctrlVars.REFINEMENT_INV
    --Deconstruction
    elseif not ctrlVars.DECONSTRUCTION_INV:IsHidden() or (comingFrom == LF_SMITHING_DECONSTRUCT or comingFrom == LF_JEWELRY_DECONSTRUCT) then
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_DECONSTRUCT
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_DECONSTRUCT
        end
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(filterPanelId)
        inventoryName = ctrlVars.DECONSTRUCTION_INV
    --Improvement
    elseif not ctrlVars.IMPROVEMENT_INV:IsHidden() or (comingFrom == LF_SMITHING_IMPROVEMENT or comingFrom == LF_JEWELRY_IMPROVEMENT) then
        local craftType = GetCraftingInteractionType()
        local filterPanelId = LF_SMITHING_IMPROVEMENT
        if craftType == CRAFTING_TYPE_JEWELRYCRAFTING then
            filterPanelId = LF_JEWELRY_IMPROVEMENT
        end
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(filterPanelId)
        inventoryName = ctrlVars.IMPROVEMENT_INV
    --Retrait
    elseif (FCOIS.isRetraitStationShown() or comingFrom == LF_RETRAIT) then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_RETRAIT)
        inventoryName = ctrlVars.RETRAIT_INV
    --Player inventory
    elseif not ctrlVars.INV:IsHidden() then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_INVENTORY)
        inventoryName = ctrlVars.INV
    --Craft bag
    elseif (not ctrlVars.CRAFTBAG:IsHidden() or comingFrom == LF_CRAFTBAG) then
        --Update the filterPanelId
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_CRAFTBAG)
        inventoryName = ctrlVars.CRAFTBAG
    else
        --Update the filterPanelId with a standard value
        FCOIS.gFilterWhere = FCOIS.getFilterWhereBySettings(LF_INVENTORY)
        inventoryName = ctrlVars.INV
    end

    --Set the return variable for the currently active filter panel
    local panelType = FCOIS.gFilterWhere

    --Overwrite the FCOIS panelID with the one from the function parameter?
    --(e.g. at the CraftBag Extended mail panel the filterPanel will be LF_MAIL. This will be moved to the "parent panel". And the filterPanel will be overwritten with LF_CRAFTBAG)
    if overwriteFilterWhere then
        FCOIS.gFilterWhere = overwriteFilterWhere
        --CraftBagExtended is active?
        if overwriteFilterWhere == LF_CRAFTBAG and FCOIS.checkIfCBEorAGSActive(FCOIS.gFilterWhereParent, true) then
            inventoryName = ctrlVars.CRAFTBAG
        end
    end

    if FCOIS.settingsVars.settings.debug then FCOIS.debugMessage( ">> after: " .. tostring(FCOIS.gFilterWhere) .. ", filterParentPanel: " .. tostring(panelType), true, FCOIS_DEBUG_DEPTH_VERY_DETAILED) end

    --Return the found inventory variable (e.g. ZO_PlayerInventory) and the LibFilters filter panel ID (e.g. LF_BANK_WITHDRAW)
    return inventoryName, panelType
end

--Function to set the anti checks at a panel variable to true or false
--and change depending anti check panels accordingly
function FCOIS.updateAntiCheckAtPanelVariable(iconNr, panelId, value)
    value = value or false
    if iconNr == nil or panelId == nil then return false end
    --Check depending panelIds
    --Inventory
    if panelId == LF_INVENTORY then
        --Must change the bank, guild bank and house bank withdraw/deposit panels as well
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_BANK_DEPOSIT] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_GUILDBANK_DEPOSIT] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_HOUSE_BANK_DEPOSIT] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_BANK_WITHDRAW] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_GUILDBANK_WITHDRAW] = value
        FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[LF_HOUSE_BANK_WITHDRAW] = value
    end
    --All others (including LF_INVENTORY)
    FCOIS.settingsVars.settings.icon[iconNr].antiCheckAtPanel[panelId] = value
end