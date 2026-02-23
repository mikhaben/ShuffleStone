--[[
    ShuffleStone - Hearthstone Toy Randomizer
    UI/ListEditor.lua - List editor row (macro icon, name, controls, dynamic icon)
]]--

local AddonName, NS = ...

-- Create the list editor row
-- Returns a frame with: macroIcon, nameEditBox, changeIconBtn, dynamicIconCB, deleteBtn
function NS.CreateListEditor(parent)
    local editor = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    editor:SetHeight(80)
    editor:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    editor:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
    editor:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    -- ==========================================
    -- ROW 1: Macro icon + name input
    -- ==========================================

    -- Macro icon button (SecureActionButton for drag-to-action-bar)
    local macroIcon = CreateFrame("Button", "ShuffleStoneEditorMacroBtn", editor, "SecureActionButtonTemplate")
    macroIcon:SetSize(42, 42)
    macroIcon:SetPoint("TOPLEFT", 6, -6)

    macroIcon.icon = macroIcon:CreateTexture(nil, "ARTWORK")
    macroIcon.icon:SetAllPoints()
    macroIcon.icon:SetTexture(NS.DEFAULT_ICON)
    macroIcon.icon:SetTexCoord(unpack(NS.ICON_TEXCOORD))

    macroIcon.border = macroIcon:CreateTexture(nil, "BACKGROUND")
    macroIcon.border:SetTexture(NS.TEX_SLOT_BORDER)
    macroIcon.border:SetSize(42 + 26, 42 + 26)
    macroIcon.border:SetPoint("CENTER", 0, -1)

    -- Tooltip for macro icon
    macroIcon:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local listKey = editor.currentListKey or "__all__"
        local displayName = (listKey == "__all__") and "All Hearthstones" or listKey
        GameTooltip:AddLine("ShuffleStone: " .. displayName, 1, 1, 1)
        local count = #NS.GetOwnedToysForList(listKey)
        GameTooltip:AddLine(count .. " hearthstones in rotation", 0.7, 0.7, 0.7)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Drag to your Action Bar", 0, 1, 0)
        GameTooltip:Show()
    end)
    macroIcon:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Drag to pick up macro
    macroIcon:SetScript("OnDragStart", function(self)
        if InCombatLockdown() then return end
        local listKey = editor.currentListKey or "__all__"
        local macroName = NS.macroNames[listKey]
        if macroName then
            local macroID = GetMacroIndexByName(macroName)
            if macroID and macroID > 0 then
                PickupMacro(macroID)
            end
        end
    end)
    macroIcon:RegisterForDrag("LeftButton")

    editor.macroIcon = macroIcon

    -- List name (editable) — full width, top half of editor
    local nameBox = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    nameBox:SetHeight(22)
    nameBox:SetPoint("LEFT", macroIcon, "RIGHT", 12, 0)
    nameBox:SetPoint("TOP", editor, "TOP", 0, -8)
    nameBox:SetPoint("RIGHT", editor, "RIGHT", -8, 0)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxLetters(30)
    nameBox:SetFontObject(GameFontHighlight)

    nameBox:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        if editor.onNameChanged then
            editor.onNameChanged(self:GetText():trim())
        end
    end)
    nameBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        -- Revert to current name
        if editor.currentListKey and editor.currentListKey ~= "__all__" then
            self:SetText(editor.currentListKey)
        end
    end)

    editor.nameBox = nameBox

    -- Static label (shown for "All" list instead of edit box)
    local nameLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameLabel:SetPoint("LEFT", macroIcon, "RIGHT", 16, 0)
    nameLabel:SetPoint("TOP", editor, "TOP", 0, -10)
    nameLabel:SetText("All Hearthstones")
    nameLabel:Hide()
    editor.nameLabel = nameLabel

    -- Description (shown under name for "All")
    local descLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
    descLabel:SetText("Uses all owned hearthstones randomly")
    descLabel:SetTextColor(unpack(NS.COLOR_GRAY))
    descLabel:Hide()
    editor.descLabel = descLabel

    -- ==========================================
    -- ROW 2: Change Icon, Dynamic Icon
    -- ==========================================

    -- "Change Icon" button (Blizzard style)
    local changeIconBtn = CreateFrame("Button", nil, editor, "UIPanelButtonTemplate")
    changeIconBtn:SetSize(85, 22)
    changeIconBtn:SetPoint("TOPLEFT", nameBox, "BOTTOMLEFT", -4, -2)
    changeIconBtn:SetText("Change Icon")

    changeIconBtn:SetScript("OnClick", function()
        if editor.onChangeIcon then
            editor.onChangeIcon()
        end
    end)

    editor.changeIconBtn = changeIconBtn

    -- "Dynamic Icon" checkbox
    local dynamicIconCB = CreateFrame("CheckButton", nil, editor, "UICheckButtonTemplate")
    dynamicIconCB:SetSize(22, 22)
    dynamicIconCB:SetPoint("LEFT", changeIconBtn, "RIGHT", 4, 0)
    dynamicIconCB:SetChecked(true) -- default on

    local dynamicIconLabel = dynamicIconCB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dynamicIconLabel:SetPoint("LEFT", dynamicIconCB, "RIGHT", 0, 0)
    dynamicIconLabel:SetText("Dynamic Icon")
    dynamicIconLabel:SetTextColor(unpack(NS.COLOR_LABEL_GRAY))

    -- Tooltip for dynamic icon checkbox
    dynamicIconCB:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Dynamic Icon", 1, 1, 1)
        GameTooltip:AddLine("When enabled, the macro icon on your", 1, 0.82, 0, true)
        GameTooltip:AddLine("action bar changes to show the next", 1, 0.82, 0, true)
        GameTooltip:AddLine("hearthstone in rotation.", 1, 0.82, 0, true)
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("When disabled, the icon stays as the", 0.7, 0.7, 0.7, true)
        GameTooltip:AddLine("list icon set via 'Change Icon'.", 0.7, 0.7, 0.7, true)
        GameTooltip:Show()
    end)
    dynamicIconCB:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    dynamicIconCB:SetScript("OnClick", function(self)
        if editor.onDynamicIconToggle then
            editor.onDynamicIconToggle(self:GetChecked())
        end
    end)

    editor.dynamicIconCB = dynamicIconCB

    -- ==========================================
    -- HINT (below editor, aligned with icon left edge)
    -- ==========================================

    -- Empty list warning (yellow, anchored to bottom)
    local emptyWarning = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    emptyWarning:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 8, 6)
    emptyWarning:SetJustifyH("LEFT")
    emptyWarning:SetText("List is empty — add hearthstones below or macro won't work!")
    emptyWarning:SetTextColor(unpack(NS.COLOR_YELLOW))
    emptyWarning:Hide()
    editor.emptyWarning = emptyWarning

    -- Drag hint (above warning when visible, otherwise at bottom)
    local dragHint = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dragHint:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 8, 6)
    dragHint:SetJustifyH("LEFT")
    dragHint:SetText("Drag icon to Action Bar, or use macro 'SS: <name>' in /macro")
    dragHint:SetTextColor(1, 1, 1)
    editor.dragHint = dragHint

    -- ==========================================
    -- STATE MANAGEMENT
    -- ==========================================

    -- Update editor state for a given list
    function editor:SetListKey(listKey)
        editor.currentListKey = listKey

        if listKey == "__all__" then
            -- "All" mode: show label, hide edit box + list-specific controls
            nameBox:Hide()
            nameLabel:SetText("All Hearthstones")
            nameLabel:Show()
            descLabel:Show()
            emptyWarning:Hide()
            dragHint:SetText("Drag icon to Action Bar, or use macro 'SS: All' in /macro")

            -- Change Icon + Dynamic Icon for All
            changeIconBtn:Show()
            changeIconBtn:ClearAllPoints()
            changeIconBtn:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", -4, -14)
            dynamicIconCB:Show()
            dynamicIconCB:ClearAllPoints()
            dynamicIconCB:SetPoint("LEFT", changeIconBtn, "RIGHT", 4, 0)
            dynamicIconCB:SetChecked(NS.db.dynamicIcon ~= false)

            -- Update macro icon
            macroIcon.icon:SetTexture(NS.db.allIcon or NS.DEFAULT_ICON)
        else
            -- Custom list mode
            nameLabel:Hide()
            descLabel:Hide()
            nameBox:SetText(listKey)
            nameBox:Show()
            changeIconBtn:Show()
            dragHint:SetText("Drag icon to Action Bar, or use macro 'SS: " .. listKey .. "' in /macro")

            -- Dynamic icon checkbox — anchor back to row 2
            dynamicIconCB:Show()
            dynamicIconCB:ClearAllPoints()
            dynamicIconCB:SetPoint("LEFT", changeIconBtn, "RIGHT", 4, 0)

            -- Set checked state from list
            local list = NS.GetListByName(listKey)
            if list then
                macroIcon.icon:SetTexture(list.icon or NS.DEFAULT_ICON)
                dynamicIconCB:SetChecked(list.dynamicIcon ~= false)

                -- Show warning if list has no owned toys
                local ownedCount = 0
                for toyID in pairs(list.toyIDs) do
                    local info = NS.scannedToys[toyID]
                    if info and info.owned then
                        ownedCount = ownedCount + 1
                    end
                end
                if ownedCount == 0 then
                    emptyWarning:Show()
                else
                    emptyWarning:Hide()
                end
            end
        end

        -- Reanchor hint + adjust height based on warning
        dragHint:ClearAllPoints()
        if emptyWarning:IsShown() then
            dragHint:SetPoint("BOTTOMLEFT", emptyWarning, "TOPLEFT", 0, 0)
            editor:SetHeight(92)
        else
            dragHint:SetPoint("BOTTOMLEFT", editor, "BOTTOMLEFT", 8, 6)
            editor:SetHeight(80)
        end

        -- Re-create macro if it was deleted externally, then update drag attributes
        if not InCombatLockdown() then
            local macroName = NS.macroNames[listKey]
            if macroName then
                local macroID = GetMacroIndexByName(macroName)
                if not macroID or macroID == 0 then
                    -- Macro was deleted externally — re-create it
                    NS.EnsureMacro(listKey, macroName)
                    macroID = GetMacroIndexByName(macroName)
                end
                if macroID and macroID > 0 then
                    macroIcon:SetAttribute("type", "macro")
                    macroIcon:SetAttribute("macro", macroID)
                end
            end
        end
    end

    return editor
end
