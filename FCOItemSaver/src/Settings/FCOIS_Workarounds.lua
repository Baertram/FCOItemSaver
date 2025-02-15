--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

--==========================================================================================================================================
--                                          FCOIS - CURRENT NEEDED WORKAROUNDS & FIXES
--==========================================================================================================================================
--Apply current needed fixes and workarounds because of other addons/libraries etc.
function FCOIS.LoadWorkarounds()
	local numLibFiltersFilterPanelIds   = FCOIS.numVars.gFCONumFilterInventoryTypes

    local settings = FCOIS.settingsVars.settings
    --FCOIS v0.7.8
    --The array to map the marker icon offsets for each filter panel ID
    FCOIS.mappingVars.filterPanelIdToIconOffset = {
        [LF_INVENTORY] 					= settings.iconPosition,
        [LF_SMITHING_REFINE]			= settings.iconPositionCrafting,
        [LF_SMITHING_DECONSTRUCT]		= settings.iconPositionCrafting,
        [LF_SMITHING_IMPROVEMENT] 		= settings.iconPositionCrafting,
        [LF_SMITHING_RESEARCH] 			= settings.iconPositionCrafting,
        [LF_SMITHING_RESEARCH_DIALOG]   = settings.iconPositionCrafting,
        [LF_JEWELRY_REFINE]			    = settings.iconPositionCrafting,
        [LF_JEWELRY_DECONSTRUCT]		= settings.iconPositionCrafting,
        [LF_JEWELRY_IMPROVEMENT] 		= settings.iconPositionCrafting,
        [LF_JEWELRY_RESEARCH] 			= settings.iconPositionCrafting,
        [LF_JEWELRY_RESEARCH_DIALOG]    = settings.iconPositionCrafting,
        [LF_VENDOR_SELL] 				= settings.iconPosition,
        [LF_GUILDBANK_WITHDRAW] 		= settings.iconPosition,
        [LF_GUILDBANK_DEPOSIT]			= settings.iconPosition,
        [LF_GUILDSTORE_SELL] 			= settings.iconPosition,
        [LF_BANK_WITHDRAW] 				= settings.iconPosition,
        [LF_BANK_DEPOSIT] 				= settings.iconPosition,
        [LF_HOUSE_BANK_WITHDRAW] 		= settings.iconPosition,
        [LF_HOUSE_BANK_DEPOSIT] 		= settings.iconPosition,
        [LF_ENCHANTING_EXTRACTION] 		= settings.iconPositionCrafting,
        [LF_ENCHANTING_CREATION] 		= settings.iconPositionCrafting,
        [LF_MAIL_SEND] 					= settings.iconPosition,
        [LF_TRADE] 						= settings.iconPosition,
        [LF_FENCE_SELL] 				= settings.iconPosition,
        [LF_FENCE_LAUNDER] 				= settings.iconPosition,
        [LF_ALCHEMY_CREATION] 			= settings.iconPositionCrafting,
        [LF_CRAFTBAG] 					= settings.iconPosition, -- Workaround: Craftbag, added with API 100015
        [LF_INVENTORY_COMPANION]		= settings.iconPosition, --Added with FCOIS v.2.1.0
    }

    --FCOIS v0.7.8b
    --Workaround to update the icon enabled array for the gear sets, by help of the old gearEnabled array
    --so the users keep their settings
    if settings.isGearEnabled ~= nil then
        for gearId = 1, FCOIS.numVars.gFCONumGearSets, 1 do
            if settings.isGearEnabled[gearId] ~= nil then
                --Overwrite the current setting of isIconEnabled with the old isGearEnabled settings
                settings.isIconEnabled[FCOIS.mappingVars.gearToIcon[gearId]] = settings.isGearEnabled[gearId]
                --Remove the old used variable now
                settings.isGearEnabled[gearId] = nil
            end
        end
        --Remove the old array
        settings.isGearEnabled = nil
    end

    --FCOIS v0.8.7h
    --For dynamic icons:
    --Update the anti settings at the panels where there is no own option to change it (bank deposit, guild bank deposit,
    --bank withdraw, guild bank withdraw, ...)
    --so the Anti-Destroy and ItemSelectionHandler functions return the anti-settings "enabled"
    local updateAntiCheckAtPanelVariable = FCOIS.UpdateAntiCheckAtPanelVariable
    for iconNr, _ in pairs(FCOIS.mappingVars.iconToDynamic) do
        if settings.icon[iconNr] ~= nil then
            --#295 Fix missing antiPanel settings to reset to default values
            if settings.icon[iconNr].antiCheckAtPanel == nil then
                settings.icon[iconNr].antiCheckAtPanel = {}
                --For each filterPanelId do some checks and add icon settings settings data:
                for filterIconHelperPanel = 1, numLibFiltersFilterPanelIds, 1 do
                    local valueToSet = false
                    if filterIconHelperPanel == LF_SMITHING_RESEARCH_DIALOG or filterIconHelperPanel == LF_JEWELRY_RESEARCH_DIALOG or
                        filterIconHelperPanel == LF_INVENTORY_COMPANION then
                        valueToSet = true
                    end
                    settings.icon[iconNr].antiCheckAtPanel[filterIconHelperPanel] = valueToSet
                end
            end

            local invValue = settings.icon[iconNr].antiCheckAtPanel[LF_INVENTORY]
            updateAntiCheckAtPanelVariable(iconNr, LF_INVENTORY, invValue)
            --FCOIS v.0.8.8i
            --Also update the crafting station research panel and set it to true for all dynamic icons
            updateAntiCheckAtPanelVariable(iconNr, LF_SMITHING_RESEARCH, true)
            --FCOIS v.1.4.4
            updateAntiCheckAtPanelVariable(iconNr, LF_JEWELRY_RESEARCH, true)
            --FCOIS v.2.1.0 --> FCOIS 2.1.9: Done within updateAntiCheckAtPanelVariable for LF_INVENTORY!
            --updateAntiCheckAtPanelVariable(iconNr, LF_INVENTORY_COMPANION, true)
        end
    end
end