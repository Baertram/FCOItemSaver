--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS
--Do not go on if libraries are not loaded properly
if not FCOIS.libsLoadedProperly then return end

--local debugMessage = FCOIS.debugMessage


--==========================================================================================================================================
--													FCOIS FEEDBACK functions
--==========================================================================================================================================


local addonVars = FCOIS.addonVars
--local preVars = FCOIS.preChatVars
local libFB = FCOIS.libFeedback

--Add the Feedback button to a control
function FCOIS.addFeedbackButtonToParent(parentCtrl, anchorTo, anchorBackup, offsetLeft, offsetTop)
    if parentCtrl == nil then return false end
    anchorTo = anchorTo or TOPLEFT
    anchorBackup = anchorBackup or TOPLEFT
    offsetLeft = offsetLeft or 0
    offsetTop = offsetTop or 0
    local locVars = FCOIS.localizationVars.fcois_loc
    local fbButton
    --LibFeedback:initializeFeedbackWindow(parentAddonNameSpace, parentAddonName, parentControl, mailDestination,  mailButtonPosition, buttonInfo,  messageText, feedbackWindowWidth, feedbackWindowHeight, feedbackWindowButtonWidth, feedbackWindowButtonHeight)
    -- The button is returned so you can modify the button if needed
    fbButton = libFB:initializeFeedbackWindow(FCOIS, -- namespace of the addon
        addonVars.addonNameMenu .. " - Feedback", -- The title string for the feedback window and the mails it sends
        parentCtrl, -- The parent control to anchor everything to
        { addonVars.addonAuthorDisplayNameEU, addonVars.addonAuthorDisplayNameNA, addonVars.addonAuthorDisplayNamePTS }, -- The destination for feedback (0 gold attachment) and donation mails
        { anchorTo , parentCtrl , anchorBackup , offsetLeft, offsetTop }, -- The position of the mail button icon.
        {
            -- If this parameter is no table: [1st parameter]  ///
            -- If this parameter is a table:
            -- -- [1st parameter]Integer. When >0: Gold value to send/Integer. Gold will only be send if 3rd parameter is true. / When Integer==0: Show the 2nd parameter string as button text and send ingame mail. / When String <> "": Show the 2nd parameter string as button text and open the URL from 1st parameter in Webbrowser
            -- -- [2nd parameter]String to show as button text.
            -- -- [3rd parameter]Boolean send gold. True: Send mail with attached gold value from 1st parameter/False: Send normal mail without gold attached
            [1] = { 0,                         locVars.feedbackSendNote,                  false },    -- Send ingame mail text
            [2] = { 5000,                      locVars.feedbackSendGold,                  true },     -- Send gold
            [3] = { addonVars.authorPortal,    locVars.feedbackOpenAddonAuthorWebsite,    false },    -- Open URL
            [4] = { addonVars.FAQwebsite,      locVars.feedbackOpenAddonFAQ,              false }     -- Open URL
        }, -- The button info.
        -- Can theoretically do any number of options, it *should* handle them
        locVars.feedbackInfo,   -- This will be displayed as a message below the title.
        650, -- The width of the feedback window
        150, -- The height of the feedback window
        150, -- The width of the feedback window's buttons
        28 -- The height of the feedback window's buttons
        )
    return fbButton
end

--Show/hide the feedback button toplevelcontrol
function FCOIS.toggleFeedbackButton(doShow, fromSlashCommand)
    fromSlashCommand = fromSlashCommand or false
    --Enable debug of LibFeedback
    if FCOIS.debug and FCOIS.deepDebug then
        if doShow then
            libFB:setDebug(true)
        else
            libFB:setDebug(false)
        end
    else
        libFB:setDebug(false)
    end
    --Add the Feedback button to the LAM settings panel if not created yet
    if FCOIS.feedbackWindow == nil then
        if FCOIS.FCOSettingsPanel ~= nil and FCOIS.FCOSettingsPanel.container ~= nil then
            --d("[FCOIS] LAM panel exists")
            local fbButton = FCOIS.addFeedbackButtonToParent(FCOIS.FCOSettingsPanel.container, TOPRIGHT, TOPRIGHT, 0, -75)
            if fbButton ~= nil then
                FCOIS.feedbackButton = fbButton
                --d(">Feedbackbutton was added")
            end
        end
    end
    local hideNow
    if FCOIS.feedbackWindow ~= nil then
        --Toggle?
        if doShow == nil then
            if fromSlashCommand == false then
                if FCOIS.feedbackWindow:IsHidden() and FCOIS.feedbackButton:IsHidden() then
                    FCOIS.feedbackButton:SetHidden(false)
                elseif FCOIS.feedbackWindow:IsHidden() and not FCOIS.feedbackButton:IsHidden() then
                    FCOIS.feedbackButton:SetHidden(true)
                elseif not FCOIS.feedbackWindow:IsHidden() and FCOIS.feedbackButton:IsHidden() then
                    FCOIS.feedbackWindow:SetHidden(true)
                elseif not FCOIS.feedbackWindow:IsHidden() and not FCOIS.feedbackButton:IsHidden() then
                    FCOIS.feedbackWindow:SetHidden(true)
                    FCOIS.feedbackButton:SetHidden(true)
                end
            else
                FCOIS.feedbackButton:SetHidden(true)
                if FCOIS.feedbackWindow:IsHidden() then
                    FCOIS.feedbackWindow:SetHidden(false)
                else
                    FCOIS.feedbackWindow:SetHidden(true)
                end
            end
        else
            hideNow = not doShow
            --Show/Hide the feedback button TLC now
            if fromSlashCommand == false then
                if FCOIS.feedbackWindow:IsHidden() and FCOIS.feedbackButton:IsHidden() then
                    FCOIS.feedbackButton:SetHidden(hideNow)
                else
                    FCOIS.feedbackWindow:SetHidden(hideNow)
                    FCOIS.feedbackButton:SetHidden(hideNow)
                end
            else
                FCOIS.feedbackButton:SetHidden(true)
                FCOIS.feedbackWindow:SetHidden(hideNow)
            end
        end
    end
end
