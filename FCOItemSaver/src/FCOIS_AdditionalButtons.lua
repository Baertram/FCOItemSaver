--Global array with all data of this addon
if FCOIS == nil then FCOIS = {} end
local FCOIS = FCOIS

-- =====================================================================================================================
--  Additional inventory button functions ("flag" buttons / jump to settings button / etc.)
-- =====================================================================================================================

--Add a button to an existing parent control
local function AddButton(parent, name, callbackFunction, onMouseUpCallbackFunction, onMouseUpCallbackFunctionMouseButton, text, font, tooltipText, tooltipAlign, textureNormal, textureMouseOver, textureClicked, width, height, left, top, alignMain, alignBackup, alignControl, hideButton)
    --Abort needed?
    if  (parent == nil or name == nil or callbackFunction == nil
            or width <= 0 or height <= 0 or alignMain == nil or alignBackup == nil)
            and (textureNormal == nil or text == nil) then
        return nil
    end
    onMouseUpCallbackFunctionMouseButton = onMouseUpCallbackFunctionMouseButton or 1

    local button
    --Does the button already exist?
    button = WINDOW_MANAGER:GetControlByName(name, "")
    if button == nil then
        --Button does not exist yet and it should be hidden? Abort here!
        if hideButton == true then return nil end
        --Create the button control at the parent
        button = WINDOW_MANAGER:CreateControl(name, parent, CT_BUTTON)
    end
    --Button was created?
    if button ~= nil then
        --is the QualitySort addon active?
        if FCOIS.otherAddons.qualitySortActive then
            --The "name" sort header is moved to the left by n pixles (currently 80)
            --So adjust the offset here by this value if one of the npanels, where the offset needs to be adjusted, is given
            local adjustAdditionalFlagPanel = FCOIS.mappingVars.adjustAdditionalFlagButtonOffsetForPanel
            if adjustAdditionalFlagPanel and adjustAdditionalFlagPanel[parent] then
                left = left +  FCOIS.otherAddons.QualitySortOffsetX
            end
        end

        --Button should be hidden?
        if hideButton == false then
            --Set the button's size
            button:SetDimensions(width, height)

            --Align the button
            if alignControl == nil then
                alignControl = parent
            end

            --SetAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
            button:SetAnchor(alignMain, alignControl, alignBackup, left, top)

            --Texture or text?
            if (text ~= nil) then
                --Text
                --Set the button's font
                if font == nil then
                    button:SetFont("ZoFontGameSmall")
                else
                    button:SetFont(font)
                end

                --Set the button's text
                button:SetText(text)

            else
                --Texture
                local texture

                --Check if texture exists
                texture = WINDOW_MANAGER:GetControlByName(name .. "Texture", "")
                if texture == nil then
                    --Create the texture for the button to hold the image
                    texture = WINDOW_MANAGER:CreateControl(name .. "Texture", button, CT_TEXTURE)
                end
                texture:SetAnchorFill()

                --Set the texture for normale state now
                texture:SetTexture(textureNormal)

                --Do we have seperate textures for the button states?
                button.upTexture 	  = textureNormal
                button.downTexture 	  = textureMouseOver or textureNormal
                button.clickedTexture = textureClicked or textureNormal
            end

            if tooltipAlign == nil then tooltipAlign = TOP end

            --Set a tooltip?
            if tooltipText ~= nil then
                tooltipText = FCOIS.preChatVars.preChatTextGreen .. tooltipText
                button.tooltipText	= tooltipText
                button.tooltipAlign = tooltipAlign
                button:SetHandler("OnMouseEnter", function(self)
                    self:GetChild(1):SetTexture(self.downTexture)
                    ZO_Tooltips_ShowTextTooltip(self, self.tooltipAlign, self.tooltipText)
                end)
                button:SetHandler("OnMouseExit", function(self)
                    self:GetChild(1):SetTexture(self.upTexture)
                    ZO_Tooltips_HideTextTooltip()
                end)
            else
                button:SetHandler("OnMouseEnter", function(self)
                    self:GetChild(1):SetTexture(self.downTexture)
                end)
                button:SetHandler("OnMouseExit", function(self)
                    self:GetChild(1):SetTexture(self.upTexture)
                end)
            end
            --Set the callback function of the button
            button:SetHandler("OnClicked", function(...)
                callbackFunction(...)
            end)
            --Set the OnMouseUp callback function of the button
            if onMouseUpCallbackFunction ~= nil then
                button:SetHandler("OnMouseUp", function(butn, mouseButton, upInside)
                    if upInside then
                        if mouseButton == onMouseUpCallbackFunctionMouseButton then
                            onMouseUpCallbackFunction(butn, mouseButton, upInside)
                        end
                    end
                end)
            end
            button:SetHandler("OnMouseDown", function(butn)
                butn:GetChild(1):SetTexture(butn.clickedTexture)
            end)

            --Show the button and make it react on mouse input
            button:SetHidden(false)
            button:SetMouseEnabled(true)

            --Return the button control
            return button
        else
            --Hide the button and make it not reacting on mouse input
            button:SetHidden(true)
            button:SetMouseEnabled(false)
        end
    else
        return nil
    end
end

--Reanchor the additional inventory "flag" buttons with the x and y offsets from the settings
function FCOIS.reAnchorAdditionalInvButtons(doReAnchorControls)
    doReAnchorControls = doReAnchorControls or false
    --Add the offset X/Y from the settings to the anchor values of the additional inventory buttons
    local apiVersion = FCOIS.APIversion
    local settings = FCOIS.settingsVars.settings
    local addInvButtonOffsets = settings.FCOISAdditionalInventoriesButtonOffset
    local addInvBtnInvokers = FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker
    if addInvButtonOffsets then
        local alignMain = BOTTOM
        local alignBackup = TOP
        local anchorVarsAddInvButtons = FCOIS.anchorVars.additionalInventoryFlagButton[apiVersion]
        --Loop over the anchorVars and get each panel of the additional inv buttons (e.g. LF_INVENTORY, LF_BANK_WITHDRAW, ...)
        if anchorVarsAddInvButtons then
            for panelId, anchorData in pairs(anchorVarsAddInvButtons) do
                --panelId = e.g. LF_INVENTORY
                --anchorData = e.g. table with anchorControl, left, top offsets
                if panelId ~= nil and anchorData ~= nil then
                    --Update the left and top offsets now
                    local currentX = anchorData.left
                    local currentY = anchorData.top
                    local newX = anchorData.defaultLeft + addInvButtonOffsets.x
                    local newY = anchorData.defaultTop + addInvButtonOffsets.y
                    local changedXOrY = false
                    if currentX ~= newX or currentY ~= newY then
                        changedXOrY = true
                        anchorData.left = newX
                        anchorData.top  = newY
                    end
                    --ReAnchor the controls if they are already created?
                    if doReAnchorControls and changedXOrY then
                        local buttonData = addInvBtnInvokers[panelId]
                        if buttonData ~= nil and buttonData.addInvButton and buttonData.name ~= nil and buttonData.name ~= "" then
                            --Check if the control exists already
                            local btnName = buttonData.name
                            local invAddCntBtnCtrl = WINDOW_MANAGER:GetControlByName(btnName, "")
                            if invAddCntBtnCtrl ~= nil then
                                --Get the button's data at the panel
                                if anchorData ~= nil then
                                    --Clear the anchors and reanchor it with the updated x and y offsets
                                    invAddCntBtnCtrl:ClearAnchors()
                                    --SetAnchor(point, relativeTo, relativePoint, offsetX, offsetY)
                                    invAddCntBtnCtrl:SetAnchor(alignMain, anchorData.anchorControl, alignBackup, anchorData.left, anchorData.top)
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

--Add additonal buttons, controlled by the FCOIS settings
function FCOIS.AddAdditionalButtons(buttonName, buttonData)
    --d("FCOIS.AddAdditionalButtons - button: " .. tostring(buttonName))
    --Add all additional buttons
    if (buttonName == -1) then
        FCOIS.AddAdditionalButtons("FCOSettings")
        FCOIS.AddAdditionalButtons("FCOInventoriesContextMenuButtons")
    else
        local settings = FCOIS.settingsVars.settings

        --Add only a specific button
        --Add the main menu "open settings" button, if not the VOTAN_SETTINGS_MENU addon button is active already
        if buttonName == "FCOSettings" and buttonData == nil then
            --Add or hide a button to the main menu category bar, right to the help button, if enabled in settings
            --AddButton(ZO_MainMenuCategoryBar, "ZO_MainMenuCategoryBarButtonFCOSettings", FCOIS.ShowFCOItemSaverSettings, nil, nil, nil, nil, locVars["button_FCOIS_settings_tooltip"], RIGHT, "/esoui/art/charactercreate/rotate_right_up.dds", "/esoui/art/charactercreate/rotate_right_over.dds", "/esoui/art/charactercreate/rotate_right_down.dds", 32, 32, ZO_MainMenuCategoryBarButton15:GetWidth() + 30, 35, BOTTOM, TOP, ZO_MainMenuCategoryBarButton15, not settings.showFCOISMenuBarButton)

            local descriptor = FCOIS.addonVars.gAddonName
            local callbackFnc
            if not FCOIS.LAM then
                callbackFnc = function() SCENE_MANAGER:Show("gameMenuInGame") end
            else
                callbackFnc = function() FCOIS.ShowFCOItemSaverSettings() end
            end

            -- Add to main menu
            local categoryLayoutInfo =
            {
                binding = "FCOIS_SETTINGS_MENU",
                categoryName = SI_BINDING_NAME_FCOIS_SETTINGS_MENU,
                callback = callbackFnc,
                visible = function()
                    if settings.showFCOISMenuBarButton then
                        if VOTANS_MENU_SETTINGS and VOTANS_MENU_SETTINGS:IsMenuButtonEnabled() then
                            return false
                        else
                            return true
                        end
                    else
                        return false
                    end
                end,
                normal    = "esoui/art/charactercreate/rotate_right_up.dds",
                pressed   = "esoui/art/charactercreate/rotate_right_down.dds",
                highlight = "esoui/art/charactercreate/rotate_right_over.dds",
                disabled  = "esoui/art/charactercreate/rotate_right_disabled.dds",
            }
            FCOIS.LMM2:AddMenuItem(descriptor, categoryLayoutInfo)

            --Add all additional inventory context menu "flag icon" buttons
        elseif buttonName == "FCOInventoriesContextMenuButtons" and buttonData == nil then
            --ReAnchor the additional inventory "flag" buttons with the x and y offsets from the settings
            FCOIS.reAnchorAdditionalInvButtons(false)
            --Add all additional inventory flag buttons
            local addInvBtnInvokers = FCOIS.contextMenuVars.filterPanelIdToContextMenuButtonInvoker
            for _, buttonDataTab in pairs(addInvBtnInvokers) do
                if buttonDataTab ~= nil and buttonDataTab.addInvButton and buttonDataTab.name ~= nil and buttonDataTab.name ~= "" then
                    FCOIS.AddAdditionalButtons(nil, buttonDataTab)
                end
            end

        --AddButton(parent, name, callbackFunction, onMouseUpCallbackFunction, onMouseUpCallbackFunctionMouseButton, text, font, tooltipText, tooltipAlign, textureNormal, textureMouseOver, textureClicked, width, height, left, top, alignMain, alignBackup, alignControl, hideButton)
        --Add a single additional inventory context menu "flag icon" button
        elseif buttonName == nil and buttonData ~= nil then
            --Add or hide a button to the player inventory sort bar
            AddButton(buttonData.parent, buttonData.name, buttonData.callbackFunction, buttonData.onMouseUpCallbackFunction, buttonData.onMouseUpCallbackFunctionMouseButton, buttonData.text, buttonData.font, buttonData.tooltipText, buttonData.tooltipAlign, buttonData.textureNormal, buttonData.textureMouseOver, buttonData.textureClicked, buttonData.width, buttonData.height, buttonData.left, buttonData.top, buttonData.alignMain, buttonData.alignBackup, buttonData.alignControl, buttonData.hideButton)
        end
    end
end