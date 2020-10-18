--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

-- =====================================================================================================================
--  Slash commands & command handler functions
-- =====================================================================================================================
--Show a help inside the chat
local function help()
    local locVars = FCOIS.localizationVars.fcois_loc
    d(locVars["chatcommands_info"])
    d("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    d(locVars["chatcommands_help"])
    d(locVars["chatcommands_status"])
    d(locVars["chatcommands_filterpanels"])
    d(locVars["chatcommands_filterpanels2"])
    d(locVars["chatcommands_filtervalues"])
    d(locVars["chatcommands_filter1_new"])
    d(locVars["chatcommands_filter2_new"])
    d(locVars["chatcommands_filter3_new"])
    d(locVars["chatcommands_filter4_new"])
    d(locVars["chatcommands_filter_new"])
    d(locVars["chatcommands_filteron_new"])
    d(locVars["chatcommands_filteroff_new"])
    d(locVars["chatcommands_filtershow_new"])
    d(locVars["chatcommands_debug"])
end

--Show a status inside the chat
local function status()
    local locVars = FCOIS.localizationVars.fcois_loc
    d(locVars["chatcommands_status_info"])

    --Check all filters, not silently (chat output: enabled)
    FCOIS.filterStatus(-1, false, false)

    if (FCOIS.settingsVars.settings.debug == true) then
        d(locVars["chatcommands_debug_on"])
    else
        d(locVars["chatcommands_debug_off"])
    end
end

--Check the commands ppl type to the chat
function FCOIS.command_handler(args)
    local locVars = FCOIS.localizationVars.fcois_loc
    local preVars = FCOIS.preChatVars
    local settings = FCOIS.settingsVars.settings
    local numFilters = FCOIS.numVars.gFCONumFilters
    local actFilterPanelId = FCOIS.mappingVars.activeFilterPanelIds

    local function toboolean(value)
        if value == "1" or value == 1 or value == "true" or value == true then
            return true
        elseif value == "0" or value == 0 or value == "false" or value == false then
            return false
        end
        return false
    end

    --Parse the arguments string
    local options = {}
    --local searchResult = {} --old: searchResult = { string.match(args, "^(%S*)%s*(.-)$") }
    for param in string.gmatch(args, "([^%s]+)%s*") do
        if (param ~= nil and param ~= "") then
            options[#options+1] = string.lower(param)
        end
    end

    --Help / status
    if(options[1] == "help" or options[1] == "hilfe" or options[1] == "list" or options[1] == "aide") then
        help()
    elseif(#options == 0 or options[1] == "status" or options[1] == "") then
        status()

    elseif(options[1] == "bug" or options[1] == "fehler" or options[1] == "erreur"
        or options[1] == "feedback" or options[1] == "msg" or options[1] == "nachricht" or options[1] == "retour" or options[1] == "message"
        or options[1] == "donate" or options[1] == "spende" or options[1] == "don") then
        FCOIS.toggleFeedbackButton(nil, true)

    --Backup & restore
    elseif options[1] == "backup" or options[1] == "sicherung" then
        --Backup
        local withDetails = false
        local doClearBackup = false
        local apiVersion = FCOIS.APIversion
        if options[2] ~= nil and options[2] ~= "" then
            withDetails = toboolean(tostring(options[2])) or false
        end
        if options[3] ~= nil and options[3] ~= "" and string.len(options[3]) == FCOIS.APIVersionLength then
            apiVersion = tonumber(options[3])
        end
        if options[4] ~= nil and options[4] ~= "" then
            doClearBackup = toboolean(options[4]) or false
        end
        local title = locVars["options_backup_marker_icons"] .. " - API " .. tostring(apiVersion)
        local body = locVars["options_backup_marker_icons_warning"]
        --Show confirmation dialog
        FCOIS.ShowConfirmationDialog("BackupMarkerIconsDialog", title, body, function() FCOIS.preBackup("unique", withDetails, apiVersion, doClearBackup) end, nil, nil, nil, true)
    elseif options[1] == "restore" or options[1] == "widerherstellung" then
        --Restore
        local withDetails = false
        local apiVersion = FCOIS.APIversion
        if options[2] ~= nil and options[2] ~= "" then
            withDetails = true
        end
        if options[3] ~= nil and options[3] ~= "" and string.len(options[3]) == FCOIS.APIVersionLength then
            apiVersion = tonumber(options[3])
        end
        local title = locVars["options_restore_marker_icons"] .. " - API " .. tostring(apiVersion)
        local body = locVars["options_restore_marker_icons_warning"]
        --Show confirmation dialog
        FCOIS.ShowConfirmationDialog("RestoreMarkerIconsDialog", title, body, function() FCOIS.preRestore("unique", withDetails, apiVersion) end, nil, nil, nil, true)
    --Debug chat commands
    elseif(options[1] == "debug" or options[1] == "d") then
        settings.debug = not settings.debug
        if (settings.debug == true) then
            d(preVars.preChatTextGreen .. locVars["chatcommands_debug_on"])
        else
            settings.deepDebug = false
            d(preVars.preChatTextRed .. locVars["chatcommands_debug_off"])
        end
    elseif(options[1] == "deepdebug" or options[1] == "dd") then
        settings.deepDebug = not settings.deepDebug
        if (settings.deepDebug == true) then
            settings.debug = true
            d(preVars.preChatTextGreen .. locVars["chatcommands_deepdebug_on"])
        else
            settings.debug = false
            d(preVars.preChatTextRed .. locVars["chatcommands_deepdebug_off"])
        end
    elseif(options[1] == "deepdebugdepth" or options[1] == "ddd") then
        if options[2] == nil then
            local value = settings.debugDepth
            if value < FCOIS_DEBUG_DEPTH_NORMAL then value = FCOIS_DEBUG_DEPTH_NORMAL end
            if value > FCOIS_DEBUG_DEPTH_ALL then value = FCOIS_DEBUG_DEPTH_ALL end
            settings.debugDepth = value
            d(preVars.preChatTextGreen .. locVars["chatcommands_debugdepth"] .. tostring(value))
        else
            local value = options[2] -- 2nd parameter is the debug depth
            if value ~= nil then value = tonumber(value) end
            if value == nil or type(value) ~= "number" then
                value = 1
            end
            if value < FCOIS_DEBUG_DEPTH_NORMAL then value = FCOIS_DEBUG_DEPTH_NORMAL end
            if value > FCOIS_DEBUG_DEPTH_ALL then value = FCOIS_DEBUG_DEPTH_ALL end
            settings.debugDepth = value
            d(preVars.preChatTextGreen .. locVars["chatcommands_debugdepth"] .. tostring(value))
        end
    --Filter chat commands
    else
        local opt3 = false
        if (options[3] ~= nil and (options[3] == false or options[3] == true or options[3] == "show")) then
            opt3 = true
            if 	   (options[3]=="show" or options[3]=="montre" or options[3]=="zeigen") then
                options[3] = -99
            elseif (options[3]==true or options[3]=="true" or options[3]=="vrai" or options[3]=="an") then
                options[3] = 1
            elseif (options[3]==false or options[3]=="false" or options[3]=="faux" or options[3]=="aus") then
                options[3] = 2
            end
        end

        if(options[1] == "filter1" or options[1] == "filtre1") then
            if (opt3) then
                FCOIS.doFilter(tonumber(options[3]), nil, FCOIS_CON_FILTER_BUTTON_LOCKDYN, false, false, true, false, tonumber(options[2]))
            else
                if (options[2] ~= nil) then
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_LOCKDYN, false, false, true, false, tonumber(options[2]))
                else
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_LOCKDYN, false, false, true, false)
                end
            end
        elseif(options[1] == "filter2" or options[1] == "filtre2") then
            if (opt3) then
                FCOIS.doFilter(tonumber(options[3]), nil, FCOIS_CON_FILTER_BUTTON_GEARSETS, false, false, true, false, tonumber(options[2]))
            else
                if (options[2] ~= nil) then
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_GEARSETS, false, false, true, false, tonumber(options[2]))
                else
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_GEARSETS, false, false, true, false)
                end
            end
        elseif(options[1] == "filter3" or options[1] == "filtre3") then
            if (opt3) then
                FCOIS.doFilter(tonumber(options[3]), nil, FCOIS_CON_FILTER_BUTTON_RESDECIMP, false, false, true, false, tonumber(options[2]))
            else
                if (options[2] ~= nil) then
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_RESDECIMP, false, false, true, false, tonumber(options[2]))
                else
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_RESDECIMP, false, false, true, false)
                end
            end
        elseif(options[1] == "filter4" or options[1] == "filtre4") then
            if (opt3) then
                FCOIS.doFilter(tonumber(options[3]), nil, FCOIS_CON_FILTER_BUTTON_SELLGUILDINT, false, false, true, false, tonumber(options[2]))
            else
                if (options[2] ~= nil) then
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_SELLGUILDINT, false, false, true, false, tonumber(options[2]))
                else
                    FCOIS.doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_SELLGUILDINT, false, false, true, false)
                end
            end
        elseif(options[1] == "filtern" or options[1] == "filter" or options[1] == "filtres") then
            if (opt3) then
                for i=1, numFilters, 1 do
                    FCOIS.doFilter(tonumber(options[3]), nil, i, false, false, true, false, tonumber(options[2]))
                end
            else
                for i=1, numFilters, 1 do
                    if (options[2] ~= nil) then
                        FCOIS.doFilter(-1, nil, i, false, false, true, false, tonumber(options[2]))
                    else
                        FCOIS.doFilter(-1, nil, i, false, false, true, false)
                    end
                end
            end
        elseif(options[1] == "allean" or options[1] == "allon" or options[1] == "touson") then
            for i=1, numFilters, 1 do
                for j=1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
                    if actFilterPanelId[j] == true then
                        if (options[2] ~= nil) then
                            FCOIS.doFilter(1, nil, i, false, false, true, false, j, tonumber(options[2]))
                        else
                            FCOIS.doFilter(1, nil, i, false, false, true, false, j)
                        end
                    end
                end
            end
        elseif(options[1] == "alleaus" or options[1] == "alloff" or options[1] == "tousoff") then
            for i=1, numFilters, 1 do
                for j=1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
                    if actFilterPanelId[j] == true then
                        if (options[2] ~= nil) then
                            FCOIS.doFilter(2, nil, i, false, false, true, false, j, tonumber(options[2]))
                        else
                            FCOIS.doFilter(2, nil, i, false, false, true, false, j)
                        end
                    end
                end
            end
        elseif(options[1] == "allezeigen" or options[1] == "allshow" or options[1] == "tousmontre") then
            for i=1, numFilters, 1 do
                for j=1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
                    if actFilterPanelId[j] == true then
                        if (options[2] ~= nil) then
                            FCOIS.doFilter(-99, nil, i, false, false, true, false, j, tonumber(options[2]))
                        else
                            FCOIS.doFilter(-99, nil, i, false, false, true, false, j)
                        end
                    end
                end
            end
        end
    end
end

--Register the slash commands
function FCOIS.RegisterSlashCommands()
    -- Register slash commands
    SLASH_COMMANDS["/fcoitemsaver"] = FCOIS.command_handler
    SLASH_COMMANDS["/fcois"] 		= FCOIS.command_handler
end