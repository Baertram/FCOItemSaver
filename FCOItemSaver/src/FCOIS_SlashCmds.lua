--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

local debugMessage = FCOIS.debugMessage

local strgmatch = string.gmatch
local strlower = string.lower
local strlen = string.len
local tos = tostring
local ton = tonumber

local showConfirmationDialog = FCOIS.ShowConfirmationDialog

local doFilter = FCOIS.DoFilter
local filterStatus = FCOIS.FilterStatus

local locVars = FCOIS.localizationVars.fcois_loc
-- =====================================================================================================================
--  Slash commands & command handler functions
-- =====================================================================================================================
--Show a help inside the chat
local function help()
    locVars = FCOIS.localizationVars.fcois_loc
    d(locVars["chatcommands_info"])
    d("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~")
    d(locVars["chatcommands_help"])
    d(locVars["chatcommands_status"])
    d(locVars["chatcommands_filterpanels"])
    for idx, filterPanelIdChatHelpLine in ipairs(locVars.filterPanelIdChatHelpLines) do
        local prefix = (idx > 1 and " >>") or " "
        d(prefix .. filterPanelIdChatHelpLine)
    end
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
    locVars = FCOIS.localizationVars.fcois_loc
    d(locVars["chatcommands_status_info"])
    --Check all filters, not silently (chat output: enabled)
    filterStatus(-1, false, false)
    d((FCOIS.settingsVars.settings.debug == true and locVars["chatcommands_debug_on"]) or locVars["chatcommands_debug_off"])
end

--Check the commands ppl type to the chat
function FCOIS.Command_handler(args)
    locVars = FCOIS.localizationVars.fcois_loc
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
    for param in strgmatch(args, "([^%s]+)%s*") do
        if (param ~= nil and param ~= "") then
            options[#options+1] = strlower(param)
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
            withDetails = toboolean(tos(options[2])) or false
        end
        if options[3] ~= nil and options[3] ~= "" and strlen(options[3]) == FCOIS.APIVersionLength then
            apiVersion = ton(options[3])
        end
        if options[4] ~= nil and options[4] ~= "" then
            doClearBackup = toboolean(options[4]) or false
        end
        local title = locVars["options_backup_marker_icons"] .. " - API " .. tos(apiVersion)
        local body = locVars["options_backup_marker_icons_warning"]
        --Show confirmation dialog
        showConfirmationDialog("BackupMarkerIconsDialog", title, body, function() FCOIS.PreBackup(withDetails, apiVersion, doClearBackup) end, nil, nil, nil, true)
    elseif options[1] == "restore" or options[1] == "widerherstellung" then
        --Restore
        local withDetails = false
        local apiVersion = FCOIS.APIversion
        if options[2] ~= nil and options[2] ~= "" then
            withDetails = true
        end
        if options[3] ~= nil and options[3] ~= "" and strlen(options[3]) == FCOIS.APIVersionLength then
            apiVersion = ton(options[3])
        end
        local title = locVars["options_restore_marker_icons"] .. " - API " .. tos(apiVersion)
        local body = locVars["options_restore_marker_icons_warning"]
        --Show confirmation dialog
        showConfirmationDialog("RestoreMarkerIconsDialog", title, body, function() FCOIS.PreRestore(withDetails, apiVersion) end, nil, nil, nil, true)
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
            if value > FCOIS_DEBUG_DEPTH_VERBOSE then value = FCOIS_DEBUG_DEPTH_VERBOSE end
            if value > FCOIS_DEBUG_DEPTH_ALL and value < FCOIS_DEBUG_DEPTH_VERBOSE then value = FCOIS_DEBUG_DEPTH_ALL end
            settings.debugDepth = value
            d(preVars.preChatTextGreen .. locVars["chatcommands_debugdepth"] .. tos(value))
        else
            local value = options[2] -- 2nd parameter is the debug depth
            if value ~= nil then value = ton(value) end
            if value == nil or type(value) ~= "number" then
                value = 1
            end
            if value < FCOIS_DEBUG_DEPTH_NORMAL then value = FCOIS_DEBUG_DEPTH_NORMAL end
            if value > FCOIS_DEBUG_DEPTH_VERBOSE then value = FCOIS_DEBUG_DEPTH_VERBOSE end
            if value > FCOIS_DEBUG_DEPTH_ALL and value < FCOIS_DEBUG_DEPTH_VERBOSE then value = FCOIS_DEBUG_DEPTH_ALL end
            settings.debugDepth = value
            d(preVars.preChatTextGreen .. locVars["chatcommands_debugdepth"] .. tos(value))
        end
    --Filter chat commands
    else
        local opt3 = false
        if (options[3] ~= nil and (options[3] == false or options[3] == true or options[3] == "show")) then
            opt3 = true
            if 	   (options[3]=="show" or options[3]=="montre" or options[3]=="zeigen") then
                options[3] = FCOIS_CON_FILTER_BUTTON_STATE_YELLOW
            elseif (options[3]==true or options[3]=="true" or options[3]=="vrai" or options[3]=="an") then
                options[3] = 1
            elseif (options[3]==false or options[3]=="false" or options[3]=="faux" or options[3]=="aus") then
                options[3] = 2
            end
        end

        if(options[1] == "filter1" or options[1] == "filtre1") then
            if (opt3) then
                doFilter(ton(options[3]), nil, FCOIS_CON_FILTER_BUTTON_LOCKDYN, false, false, true, false, ton(options[2]))
            else
                if (options[2] ~= nil) then
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_LOCKDYN, false, false, true, false, ton(options[2]))
                else
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_LOCKDYN, false, false, true, false)
                end
            end
        elseif(options[1] == "filter2" or options[1] == "filtre2") then
            if (opt3) then
                doFilter(ton(options[3]), nil, FCOIS_CON_FILTER_BUTTON_GEARSETS, false, false, true, false, ton(options[2]))
            else
                if (options[2] ~= nil) then
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_GEARSETS, false, false, true, false, ton(options[2]))
                else
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_GEARSETS, false, false, true, false)
                end
            end
        elseif(options[1] == "filter3" or options[1] == "filtre3") then
            if (opt3) then
                doFilter(ton(options[3]), nil, FCOIS_CON_FILTER_BUTTON_RESDECIMP, false, false, true, false, ton(options[2]))
            else
                if (options[2] ~= nil) then
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_RESDECIMP, false, false, true, false, ton(options[2]))
                else
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_RESDECIMP, false, false, true, false)
                end
            end
        elseif(options[1] == "filter4" or options[1] == "filtre4") then
            if (opt3) then
                doFilter(ton(options[3]), nil, FCOIS_CON_FILTER_BUTTON_SELLGUILDINT, false, false, true, false, ton(options[2]))
            else
                if (options[2] ~= nil) then
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_SELLGUILDINT, false, false, true, false, ton(options[2]))
                else
                    doFilter(-1, nil, FCOIS_CON_FILTER_BUTTON_SELLGUILDINT, false, false, true, false)
                end
            end
        elseif(options[1] == "filtern" or options[1] == "filter" or options[1] == "filtres") then
            if (opt3) then
                for i=1, numFilters, 1 do
                    doFilter(ton(options[3]), nil, i, false, false, true, false, ton(options[2]))
                end
            else
                for i=1, numFilters, 1 do
                    if (options[2] ~= nil) then
                        doFilter(-1, nil, i, false, false, true, false, ton(options[2]))
                    else
                        doFilter(-1, nil, i, false, false, true, false)
                    end
                end
            end
        elseif(options[1] == "allean" or options[1] == "allon" or options[1] == "touson") then
            for i=1, numFilters, 1 do
                for j=1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
                    if actFilterPanelId[j] == true then
                        if (options[2] ~= nil) then
                            doFilter(1, nil, i, false, false, true, false, j, ton(options[2]))
                        else
                            doFilter(1, nil, i, false, false, true, false, j)
                        end
                    end
                end
            end
        elseif(options[1] == "alleaus" or options[1] == "alloff" or options[1] == "tousoff") then
            for i=1, numFilters, 1 do
                for j=1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
                    if actFilterPanelId[j] == true then
                        if (options[2] ~= nil) then
                            doFilter(2, nil, i, false, false, true, false, j, ton(options[2]))
                        else
                            doFilter(2, nil, i, false, false, true, false, j)
                        end
                    end
                end
            end
        elseif(options[1] == "allezeigen" or options[1] == "allshow" or options[1] == "tousmontre") then
            for i=1, numFilters, 1 do
                for j=1, FCOIS.numVars.gFCONumFilterInventoryTypes, 1 do
                    if actFilterPanelId[j] == true then
                        if (options[2] ~= nil) then
                            doFilter(FCOIS_CON_FILTER_BUTTON_STATE_YELLOW, nil, i, false, false, true, false, j, ton(options[2]))
                        else
                            doFilter(FCOIS_CON_FILTER_BUTTON_STATE_YELLOW, nil, i, false, false, true, false, j)
                        end
                    end
                end
            end
        end
    end
end
local commandHandler = FCOIS.Command_handler

--Register the slash commands
function FCOIS.RegisterSlashCommands()
    -- Register slash commands
    SLASH_COMMANDS["/fcoitemsaver"] = commandHandler
    SLASH_COMMANDS["/fcois"] 		= commandHandler
end