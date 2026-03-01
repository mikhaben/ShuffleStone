--[[
    ShuffleStone - Hearthstone Toy Randomizer
    UI/IconPicker.lua - Icon picker window (docked grid of all hearthstones)
]]--

local AddonName, NS = ...

local iconPickerFrame = nil

local PICKER_COLS = NS.PICKER_COLS
local PICKER_ICON = NS.PICKER_ICON_SIZE
local PICKER_GAP  = NS.PICKER_GAP
local PICKER_PAD  = NS.PICKER_PAD

local function CreateIconPicker(parent)
    if iconPickerFrame then return iconPickerFrame end

    local f = NS.CreateWindow({
        name   = "ShuffleStoneIconPicker",
        title  = "Choose Icon",
        width  = NS.PICKER_MIN_W,
        parent = parent,
        anchor = { frame = parent },
    })

    f.buttons = {}
    iconPickerFrame = f
    return f
end

function NS.ShowIconPicker(listKey, parentFrame)
    local picker = CreateIconPicker(parentFrame)

    -- Determine current active toyID for checkmark
    local activeToyID
    if listKey == "__all__" then
        activeToyID = NS.db.allIconToyID
    else
        local list = NS.GetListByName(listKey)
        activeToyID = list and list.iconToyID
    end

    -- Hide old buttons
    for _, btn in ipairs(picker.buttons) do
        btn:Hide()
    end

    -- Build icon list from ALL hearthstone toys
    local visibleIdx = 0

    for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
        local toyID = toyData.id
        local info = NS.scannedToys[toyID]

        visibleIdx = visibleIdx + 1
        local btn = picker.buttons[visibleIdx]

        if not btn then
            btn = CreateFrame("Button", nil, picker)
            btn:SetSize(PICKER_ICON, PICKER_ICON)

            local tex = btn:CreateTexture(nil, "ARTWORK")
            tex:SetAllPoints()
            tex:SetTexCoord(unpack(NS.ICON_TEXCOORD))
            btn.tex = tex

            local hl = btn:CreateTexture(nil, "HIGHLIGHT")
            hl:SetAllPoints()
            hl:SetTexture(NS.TEX_HIGHLIGHT)
            hl:SetBlendMode("ADD")

            local check = btn:CreateTexture(nil, "OVERLAY")
            check:SetSize(14, 14)
            check:SetPoint("BOTTOMRIGHT", 2, -2)
            check:SetTexture(NS.TEX_CHECKMARK)
            check:SetVertexColor(unpack(NS.COLOR_GREEN))
            check:Hide()
            btn.check = check

            btn:SetScript("OnEnter", function(self)
                if not self.toyID then return end
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                local toyInfo = NS.scannedToys[self.toyID]
                if toyInfo and toyInfo.isToy then
                    GameTooltip:SetToyByItemID(self.toyID)
                elseif toyInfo then
                    GameTooltip:SetItemByID(self.toyID)
                end
                GameTooltip:Show()
            end)
            btn:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)

            picker.buttons[visibleIdx] = btn
        end

        btn.toyID = toyID

        -- Set icon texture
        local icon = (info and info.icon) or NS.DEFAULT_ICON
        btn.tex:SetTexture(icon)

        -- Owned vs unobtained visual
        if info and info.owned then
            btn.tex:SetDesaturated(false)
            btn.tex:SetAlpha(1)
        else
            btn.tex:SetDesaturated(true)
            btn.tex:SetAlpha(0.5)
        end

        -- Checkmark on active icon
        btn.check:SetShown(toyID == activeToyID)

        -- Position in grid
        local col = (visibleIdx - 1) % PICKER_COLS
        local row = math.floor((visibleIdx - 1) / PICKER_COLS)
        btn:ClearAllPoints()
        btn:SetPoint("TOPLEFT", picker, "TOPLEFT",
            PICKER_PAD + col * (PICKER_ICON + PICKER_GAP),
            -(picker.contentTop + row * (PICKER_ICON + PICKER_GAP)))

        -- Click handler: select this icon
        btn:SetScript("OnClick", function(self)
            local selectedToyID = self.toyID
            local selectedInfo = NS.scannedToys[selectedToyID]
            if not selectedInfo then return end

            -- Update list icon data
            if listKey == "__all__" then
                NS.db.allIcon = selectedInfo.icon
                NS.db.allIconToyID = selectedToyID
            else
                local l = NS.GetListByName(listKey)
                if l then
                    l.icon = selectedInfo.icon
                    l.iconToyID = selectedToyID
                end
            end

            -- Update macro icon when dynamic icon is off
            if not NS.IsDynamicIcon(listKey) then
                NS.SetMacroIcon(listKey, selectedInfo.icon)
            end

            -- Update all checkmarks
            for j = 1, #picker.buttons do
                local b = picker.buttons[j]
                if b and b:IsShown() then
                    b.check:SetShown(b.toyID == selectedToyID)
                end
            end

            NS.RefreshMainFrame()
        end)

        btn:Show()
    end

    -- Size the frame to fit the grid
    local cols = math.min(visibleIdx, PICKER_COLS)
    local rows = math.ceil(visibleIdx / PICKER_COLS)
    local gridW = cols * (PICKER_ICON + PICKER_GAP) - PICKER_GAP
    local gridH = rows * (PICKER_ICON + PICKER_GAP) - PICKER_GAP
    local frameW = math.max(NS.PICKER_MIN_W, gridW + PICKER_PAD * 2 + 16)
    picker:SetWidth(frameW)
    picker:SetContentHeight(gridH + NS.PADDING + picker.contentTop)

    picker:Show()
end

function NS.HideIconPicker()
    if iconPickerFrame then
        iconPickerFrame:Hide()
    end
end

function NS.ToggleIconPicker(listKey, parentFrame)
    if iconPickerFrame and iconPickerFrame:IsShown() then
        iconPickerFrame:Hide()
    else
        NS.ShowIconPicker(listKey, parentFrame)
    end
end
