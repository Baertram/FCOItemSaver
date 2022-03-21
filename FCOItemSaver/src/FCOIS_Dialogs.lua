--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

--local debugMessage = FCOIS.debugMessage
local zo_strf = zo_strformat
local gil = GetItemLink 

local isItemBindable = FCOIS.IsItemBindable

--==============================================================================
--			Dialog functions
--==============================================================================

--Format the text for the dialog
local function getFormattedDialogText(text, params)
    if (text) then
        if(params and #params > 0) then
            text = zo_strf(text, unpack(params))
        elseif(type(text) == "number") then
            text = GetString(text)
        end
    else
        text = ""
    end
    return text
end

--==============================================================================
--			Destroy dialog changes
--==============================================================================
--Modify the destroy dialog's YES button
function FCOIS.OverrideDialogYesButton(dialog)
    --Get the "yes" button control of the destroy popup window
    --FCOdialog = dialog
    local button1 = dialog:GetNamedChild("Button1")
    if button1 == nil then return false end
    local ctrlVars = FCOIS.ZOControlVars
    local destroyItemDialog = ctrlVars.DestroyItemDialog

    if dialog.info == destroyItemDialog then
        --Use standard behaviour of "YES" button in destroy dialog
        button1:SetText(GetString(SI_YES))
        button1:SetClickSound(SOUNDS.DIALOG_ACCEPT)
        button1.m_callback = destroyItemDialog.buttons[1].callback
        button1:SetEnabled(true)
        button1:SetMouseEnabled(true)
        button1:SetHidden(false)
        button1:SetKeybindEnabled(true)

        if not FCOIS.preventerVars.gAllowDestroyItem then
            --Set global variable so the next time the menu is opened the "YES" button of the dialog ZO_Dialog1 gets reset
            FCOIS.preventerVars.wasDestroyDone = true

            --Use own behaviour of "YES" button in destroy dialog:
            --Button's text will change to "NO"
            --Button will be set invisible and callback method changes so that
            --using a keybind will press ESC key instead
            button1:SetText(GetString(SI_NO))
            button1:SetClickSound(SOUNDS.DIALOG_DECLINE)
            button1.m_callback = destroyItemDialog.noChoiceCallback
            button1:SetMouseEnabled(false)
            button1:SetHidden(true)
            button1:SetKeybindEnabled(false)
        end
    else
        --All other dialogs
        ctrlVars.ZODialog1:SetKeyboardEnabled(false)
        button1:SetEnabled(true)
        button1:SetMouseEnabled(true)
        button1:SetHidden(false)
        button1:SetKeybindEnabled(true)
    end
end


--==============================================================================
--			Custom dialog: Ask before bind dialog
--==============================================================================
--The callback function for the "Accept" button at the FCO custom dialog for "Ask on equip"
local function FCOAcceptDialogChanges(dialog)
    --globDialog = dialog
    if dialog.data.bag ~= nil and dialog.data.slot ~= nil then
        --Set global var to allow equip of item
        FCOIS.preventerVars.askBeforeEquipDialogRetVal = true
        --Equip the item now
        --local itemLink = gil(dialog.data.bag, dialog.data.slot)
--d(">[FCOAcceptDialogChanges]Equipping " .. itemLink .. " now - equipSlot: " .. tostring(dialog.data.equipSlot))
        local dialogData = dialog.data
        if dialogData.equipSlot ~= nil then
            EquipItem(dialogData.bag, dialogData.slot, dialogData.equipSlot)
        else
            EquipItem(dialogData.bag, dialogData.slot)
        end
        --reset the global var again
        FCOIS.preventerVars.askBeforeEquipDialogRetVal = false
    end
end

--function to initialize the ask before binding an item dialog
function FCOIS.AskBeforeBindDialogInitialize(control)
    local content   = GetControl(control, "Content")
    local acceptBtn = GetControl(control, "Accept")
    local cancelBtn = GetControl(control, "Cancel")
    local descLabel = GetControl(content, "Text")

    ZO_Dialogs_RegisterCustomDialog("FCOIS_ASK_BEFORE_BIND_DIALOG", {
        customControl = control,
        title = { text = FCOIS.preChatVars.preChatTextRed .. FCOIS.localizationVars.fcois_loc["options_header_anti_equip"]  },
        mainText = { text = FCOIS.localizationVars.fcois_loc["options_anti_equip_question"] },
        setup = function(_, data)
            FCOIS.preventerVars.askBeforeEquipDialogRetVal = false
            --Format the dialog text: Show the item's name inside
            local itemLink = gil(data.bag, data.slot)
            local params = {itemLink}
            local formattedText = getFormattedDialogText(FCOIS.localizationVars.fcois_loc["options_anti_equip_question"], params)
            descLabel:SetText(formattedText)
        end,
        noChoiceCallback = function()
            --Simulate the button "cancel" click
            FCOIS.preventerVars.askBeforeEquipDialogRetVal = false
        end,
        buttons =
        {
            {
                control = acceptBtn,
                text = SI_DIALOG_ACCEPT,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog) FCOAcceptDialogChanges(dialog) end,
            },
            {
                control = cancelBtn,
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
                callback = function()
                    FCOIS.preventerVars.askBeforeEquipDialogRetVal = false
                end,
            },
        },
    })
end

--Function to check if an item is bindable and show an dialog to ask the user if the item should be bound to the account, if enabled
function FCOIS.AskBeforeBindDialogCallback(bagId, slotIndex, equipSlotIndex, contextMenuActive)
--d("[FCOIS.AskBeforeBindDialogCallback] AskbeforeBind: " .. tostring(FCOIS.settingsVars.settings.askBeforeEquipBoundItems) .. ", bag: " .. tostring(bagId) .. ", slot: " .. tostring(slotIndex) .. ", equipSlotIndex: " .. tostring(equipSlotIndex) .. ", contextMenu: " ..tostring(contextMenuActive))
    if FCOIS.settingsVars.settings.askBeforeEquipBoundItems then
        if contextMenuActive then
            ZO_Dialogs_ShowDialog("FCOIS_ASK_BEFORE_BIND_DIALOG", {bag=bagId, slot=slotIndex, equipSlot=equipSlotIndex})
            return true --to prevent function EquipItem(bagId, slotIndex) from the original call we have PreHooked here. Will be called from the dialog then if pressed "Yes"
        else
            --Execute function EquipItem(bagId, slotIndex)
            return false
        end
    else
        FCOIS.preventerVars.askBeforeEquipDialogRetVal = true
        --Execute function EquipItem(bagId, slotIndex)
        return false
    end
end
local askBeforeBindDialogCallback = FCOIS.AskBeforeBindDialogCallback

--Function to check if item is bindable and show a question dialog then (used in file FCOIS_Hooks.lua in PreHook of function "EQUIP ITEM")
--and at file FCOIS_hooks.lua in function "FCOItemSaver_OnReceiveDrag(inventorySlot)"
--Will only show the FCOIS dialog to ask before equip if the settings therefor are enabled and the ZOs function (ZO_InventorySlot_WillItemBecomeBoundOnEquip(bag, slot) returns false and thus does not ask before bind!
function FCOIS.CheckBindableItems(bagId, slotIndex, equipSlotIndex, dragAndDropped)
    dragAndDropped = dragAndDropped or false
    local retVar = false
--d("[CheckBindableItems] settings: " .. tostring(FCOIS.settingsVars.settings.askBeforeEquipBoundItems) .. ", Preventer askBeforeEquipDialogRetVal: " .. tostring(FCOIS.preventerVars.askBeforeEquipDialogRetVal) .. "dragAndDropped: " ..tostring(dragAndDropped))
    if FCOIS.settingsVars.settings.askBeforeEquipBoundItems == true and FCOIS.preventerVars.askBeforeEquipDialogRetVal == false then
        --Is the ZOs function to ask before bind is returning false but the item is still unbound and bindable?
        if not ZO_InventorySlot_WillItemBecomeBoundOnEquip(bagId, slotIndex) and isItemBindable(bagId, slotIndex) then
            --Check if the item is BOP but tradeable and return false, as ZOs is using it's own dialog to ask before bind here!
            --local stillBOPButTradeable = IsItemBoPAndTradeable(bagId, slotIndex) and (GetItemBoPTimeRemainingSeconds(bagId, slotIndex) > 0)
            --if stillBOPButTradeable then return false end
            local retVal = askBeforeBindDialogCallback(bagId, slotIndex, equipSlotIndex, true)
            --Returning true will skip the "real" EquipItem(bag, slot) function! But the FCOIS dialog will be shown then
            return retVal
        else
            --Item cannot be bound:
            --Equip the item now
            return retVar
        end
    else
        --Settings for "Ask before equip" is dsabled, so:
        --Equip the item now
        return retVar
    end
end

--==============================================================================
--			Custom dialog: Ask before migration dialog
--==============================================================================

--function to initialize the ask before binding an item dialog
function FCOIS.AskBeforeMigrateDialogInitialize(control)
    local localVars = FCOIS.localizationVars.fcois_loc
    local content   = GetControl(control, "Content")
    local acceptBtn = GetControl(control, "Accept")
    local cancelBtn = GetControl(control, "Cancel")
    local descLabel = GetControl(content, "Text")

    local titleText = ""
    if FCOIS.settingsVars.settings.useUniqueIds then
        titleText = FCOIS.preChatVars.preChatTextRed .. localVars["options_migrate_uniqueids"]
    else
        titleText = FCOIS.preChatVars.preChatTextRed .. localVars["options_migrate_uniqueids"]
    end

    local function resetMigrateMarkerIcons(p_dialog)
        FCOIS.preventerVars.migrateItemMarkers = false
        FCOIS.preventerVars.migrateToUniqueIds = false
        FCOIS.preventerVars.migrateToItemInstanceIds = false
        --If event player activated raised the migrate marker icon IDs dialog: A reloadUI is needed if we abort the
        --dialog in order to update the settings properly and show the marker icons in the inventories properly
        if FCOIS.preventerVars.migrateItemMarkersCalledFromPlayerActivated then
            d("[FCOIS]Migration of marker icon IDs aborted. Reloading the UI now to update the settings properly!")
            ReloadUI("ingame")
        end
    end

    --The migrate non-unique/unique to unique/non-unique item IDs
    ZO_Dialogs_RegisterCustomDialog("FCOIS_ASK_BEFORE_MIGRATE_DIALOG", {
        customControl = control,
        title = { text = titleText  },
        mainText = { text = "" },
        setup = function(_, data)
            local formattedText = ""
            if FCOIS.settingsVars.settings.useUniqueIds == true then
                formattedText = localVars["options_migrate_uniqueids_dialog"]
            else
                formattedText = localVars["options_migrate_nonuniqueids_dialog"]
            end
            descLabel:SetText(formattedText .. "\n\n" .. localVars["options_migrate_ids_migration_log_dialog"])
        end,
        noChoiceCallback = resetMigrateMarkerIcons,
        buttons =
        {
            {
                control = acceptBtn,
                text = SI_DIALOG_ACCEPT,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                    FCOIS.MigrateMarkerIcons()
                end,
            },
            {
                control = cancelBtn,
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
                callback = resetMigrateMarkerIcons,
            },
        },
    })
end

--Show the ask before migrate dialog
function FCOIS.ShowAskBeforeMigrateDialog()
    ZO_Dialogs_ShowDialog("FCOIS_ASK_BEFORE_MIGRATE_DIALOG", {})
end

--==============================================================================
--			Custom dialog: Ask to protect an item
--==============================================================================

--function to initialize the ask protection question dialog
function FCOIS.AskProtectionDialogInitialize(control)
    local content   = GetControl(control, "Content")
    local acceptBtn = GetControl(control, "Accept")
    local cancelBtn = GetControl(control, "Cancel")
    local titleLabel = GetControl(control, "Title")
    local descLabel = GetControl(content, "Text")
    local okFunc
    local abortFunc

    ZO_Dialogs_RegisterCustomDialog("FCOIS_ASK_PROTECTION_DIALOG", {
        customControl = control,
        title = { text = "Title" },
        mainText = { text = "Question" },
        setup = function(_, data)
            titleLabel:SetText(data.title)
            descLabel:SetText(data.question)
            local callbackData = data.callbackData
            if callbackData.yes then
                okFunc = callbackData.yes
            end
            if okFunc == nil or type(okFunc) ~= "function" then
                okFunc = function() end
            end
            if callbackData.no then
                abortFunc = callbackData.no
            end
            if abortFunc == nil or type(abortFunc) ~= "function" then
                abortFunc = function() end
            end
        end,
        noChoiceCallback = function()
            abortFunc()
        end,
        buttons =
        {
            {
                control = acceptBtn,
                text = SI_DIALOG_ACCEPT,
                keybind = "DIALOG_PRIMARY",
                callback = function(dialog)
                    okFunc()
                end,
            },
            {
                control = cancelBtn,
                text = SI_DIALOG_CANCEL,
                keybind = "DIALOG_NEGATIVE",
                callback = function(dialog)
                    abortFunc()
                end,
            },
        },
    })
end

--Show a protection dialog with a question and dynamic text and callback function
--Pressing yes will excute the data.callbackYes function
--Pressing no will execute the data.callbackNo function
function FCOIS.ShowProtectionDialog(titleVar, questionVar, data)
    if titleVar == nil or questionVar == nil or data == nil then return false end
    --Get the callback functions for the yes and no buttons
    local callbackYes
    local callbackNo
    if data.callbackYes then
        callbackYes = data.callbackYes
    end
    if data.callbackNo then
        callbackNo = data.callbackNo
    end
    local callbackData = {}
    callbackData.yes = callbackYes
    callbackData.no  = callbackNo
    --Replace variable placeholders <<1>> etc. in the question with data
    local replaceVar1
    local replaceVar2
    local replaceVar3
    local replaceVar4
    local replaceVar5
    if data.replaceVars ~= nil then
        local replVars = data.replaceVars
        for i=1, #replVars, 1 do
            if i == 1 then
                replaceVar1 = replVars[i]
            elseif i == 2 then
                replaceVar2 = replVars[i]
            elseif i == 3 then
                replaceVar3 = replVars[i]
            elseif i == 4 then
                replaceVar4 = replVars[i]
            elseif i == 5 then
                replaceVar5 = replVars[i]
            end
        end
        if     replaceVar5 ~= nil and replaceVar5 ~= "" then
            questionVar = zo_strf(questionVar, replaceVar1, replaceVar2, replaceVar3, replaceVar4, replaceVar5)
        elseif replaceVar4 ~= nil and replaceVar4 ~= "" then
            questionVar = zo_strf(questionVar, replaceVar1, replaceVar2, replaceVar3, replaceVar4)
        elseif replaceVar3 ~= nil and replaceVar3 ~= "" then
            questionVar = zo_strf(questionVar, replaceVar1, replaceVar2, replaceVar3)
        elseif replaceVar2 ~= nil and replaceVar2 ~= "" then
            questionVar = zo_strf(questionVar, replaceVar1, replaceVar2)
        elseif replaceVar1 ~= nil and replaceVar1 ~= "" then
            questionVar = zo_strf(questionVar, replaceVar1)
        end
    end
    --Show the dialog now
    ZO_Dialogs_ShowDialog("FCOIS_ASK_PROTECTION_DIALOG", {title=titleVar, question=questionVar, callbackData=callbackData})
end

--Reset preventer vars and other variables if the ZOs dialog gets closed e.g.
function FCOIS.resetZOsDialogVariables()
--d("[FCOIS]resetZOsDialogVariables")
    local prevVars = FCOIS.preventerVars
    prevVars.splitItemStackDialogActive = false
end

--Show the user a remember popup "once" to logout and backup the savedvariables
function FCOIS.ShowRememberUserAboutSavedVariablesBackupDialog()
    local locVars = FCOIS.localizationVars
    local locVars_loc = locVars.fcois_loc
    local title = locVars_loc["options_hint_backup_savedvariables_file_title"]
    local body = locVars_loc["options_hint_backup_savedvariables_file"]
    local FCOISsettings = FCOIS.settingsVars.settings
    FCOIS.ShowConfirmationDialog("ShowRememberUserAboutSavedVariablesBackupDialog", title, body,
            function() FCOIS.settingsVars.settings.remindUserAboutSavedVariablesBackup = true end,
            function() FCOIS.settingsVars.settings.remindUserAboutSavedVariablesBackup = false end
    )
end