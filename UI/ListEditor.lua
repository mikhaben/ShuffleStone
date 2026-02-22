--[[
    ShuffleStone - Hearthstone Toy Randomizer
    UI/ListEditor.lua - List editor row (macro icon, name, icon picker, delete)
]]--

local AddonName, NS = ...

-- Create the list editor row
-- Returns a frame with: macroIcon, nameEditBox, changeIconBtn, deleteBtn
function NS.CreateListEditor(parent)
    local editor = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    editor:SetHeight(56)
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

    -- Macro icon button (SecureActionButton for drag-to-action-bar)
    local macroIcon = CreateFrame("Button", "ShuffleStoneEditorMacroBtn", editor, "SecureActionButtonTemplate")
    macroIcon:SetSize(42, 42)
    macroIcon:SetPoint("LEFT", 6, 0)

    macroIcon.icon = macroIcon:CreateTexture(nil, "ARTWORK")
    macroIcon.icon:SetAllPoints()
    macroIcon.icon:SetTexture(NS.DEFAULT_ICON)
    macroIcon.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    macroIcon.border = macroIcon:CreateTexture(nil, "OVERLAY")
    macroIcon.border:SetPoint("TOPLEFT", -1, 1)
    macroIcon.border:SetPoint("BOTTOMRIGHT", 1, -1)
    macroIcon.border:SetColorTexture(0.6, 0.5, 0, 0.8)
    macroIcon.border:SetDrawLayer("OVERLAY", -1)

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

    -- List name (editable)
    local nameBox = CreateFrame("EditBox", nil, editor, "InputBoxTemplate")
    nameBox:SetSize(160, 22)
    nameBox:SetPoint("LEFT", macroIcon, "RIGHT", 12, 0)
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
    nameLabel:SetText("All Hearthstones")
    nameLabel:Hide()
    editor.nameLabel = nameLabel

    -- Description (shown under name for "All")
    local descLabel = editor:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    descLabel:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 0, -2)
    descLabel:SetText("Uses all owned hearthstones randomly")
    descLabel:SetTextColor(0.5, 0.5, 0.5)
    descLabel:Hide()
    editor.descLabel = descLabel

    -- Change icon button
    local changeIconBtn = CreateFrame("Button", nil, editor)
    changeIconBtn:SetSize(24, 24)
    changeIconBtn:SetPoint("RIGHT", editor, "RIGHT", -36, 0)
    changeIconBtn:SetNormalTexture("Interface\\GossipFrame\\BinderGossipIcon")
    changeIconBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    changeIconBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Change list icon", 1, 1, 1)
        GameTooltip:Show()
    end)
    changeIconBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    changeIconBtn:SetScript("OnClick", function()
        if editor.onChangeIcon then
            editor.onChangeIcon()
        end
    end)

    editor.changeIconBtn = changeIconBtn

    -- Delete button
    local deleteBtn = CreateFrame("Button", nil, editor)
    deleteBtn:SetSize(24, 24)
    deleteBtn:SetPoint("RIGHT", editor, "RIGHT", -8, 0)
    deleteBtn:SetNormalTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
    deleteBtn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

    deleteBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Delete this list", 1, 0.3, 0.3)
        GameTooltip:Show()
    end)
    deleteBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    deleteBtn:SetScript("OnClick", function()
        if editor.onDelete then
            editor.onDelete()
        end
    end)

    editor.deleteBtn = deleteBtn

    -- Update editor state for a given list
    function editor:SetListKey(listKey)
        editor.currentListKey = listKey

        if listKey == "__all__" then
            -- "All" mode: show label, hide edit box + delete
            nameBox:Hide()
            nameLabel:SetText("All Hearthstones")
            nameLabel:Show()
            descLabel:Show()
            deleteBtn:Hide()
            changeIconBtn:Hide()

            -- Update macro icon
            macroIcon.icon:SetTexture(NS.DEFAULT_ICON)
        else
            -- Custom list mode
            nameLabel:Hide()
            descLabel:Hide()
            nameBox:SetText(listKey)
            nameBox:Show()
            deleteBtn:Show()
            changeIconBtn:Show()

            -- Find list icon
            local list = NS.GetListByName(listKey)
            if list then
                macroIcon.icon:SetTexture(list.icon or NS.DEFAULT_ICON)
            end
        end

        -- Update macro button attributes for drag
        if not InCombatLockdown() then
            local macroName = NS.macroNames[listKey]
            if macroName then
                local macroID = GetMacroIndexByName(macroName)
                if macroID and macroID > 0 then
                    macroIcon:SetAttribute("type", "macro")
                    macroIcon:SetAttribute("macro", macroID)
                end
            end
        end
    end

    return editor
end
