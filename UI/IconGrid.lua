local _, NS = ...

local ICON_SIZE = NS.ICON_SIZE
local ICON_GAP = NS.ICON_GAP
local BADGE_SIZE = NS.BADGE_SIZE

local function CreateIconButton(parent)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ICON_SIZE, ICON_SIZE)

    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(unpack(NS.ICON_TEXCOORD))

    btn.border = btn:CreateTexture(nil, "BACKGROUND")
    btn.border:SetTexture(NS.TEX_SLOT_BORDER)
    btn.border:SetSize(ICON_SIZE + 26, ICON_SIZE + 26)
    btn.border:SetPoint("CENTER", 0, -1)

    btn.checkmark = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    btn.checkmark:SetSize(BADGE_SIZE, BADGE_SIZE)
    btn.checkmark:SetPoint("BOTTOMRIGHT", 2, -2)
    btn.checkmark:SetTexture(NS.TEX_CHECKMARK)
    btn.checkmark:Hide()

    btn.lockIcon = btn:CreateTexture(nil, "OVERLAY")
    btn.lockIcon:SetSize(BADGE_SIZE, BADGE_SIZE)
    btn.lockIcon:SetPoint("BOTTOMRIGHT", 2, -2)
    btn.lockIcon:SetTexture(NS.TEX_LOCK)
    btn.lockIcon:Hide()

    btn.actionOverlay = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    btn.actionOverlay:SetSize(18, 18)
    btn.actionOverlay:SetPoint("TOPRIGHT", 2, 2)
    btn.actionOverlay:Hide()

    btn:SetHighlightTexture(NS.TEX_HIGHLIGHT, "ADD")

    btn.toyID = nil
    btn.isInList = false
    btn.isOwned = false

    return btn
end

function NS.CreateIconGrid(opts)
    local container = CreateFrame("Frame", nil, opts.parent)
    container.buttons = {}
    container.visibleCount = 0
    container.isTopGrid = opts.isTopGrid or false

    local pool = {}
    local poolSize = #NS.HEARTHSTONE_TOYS

    for i = 1, poolSize do
        local btn = CreateIconButton(container)
        btn:Hide()

        btn:SetScript("OnEnter", function(self)
            if not self.toyID then return end
            local info = NS.scannedToys[self.toyID]
            if not info then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            GameTooltip:SetToyByItemID(self.toyID)

            GameTooltip:AddLine(" ")
            local listKey = opts.getListKey and opts.getListKey() or "__all__"

            if listKey == "__all__" then
                if not info.owned then
                    GameTooltip:AddLine("Not collected", 1, 0.3, 0.3)
                end
            elseif opts.isTopGrid or self.isInList then
                GameTooltip:AddLine("Click to remove from list", 1, 0.3, 0.3)
                if not info.owned then
                    GameTooltip:AddLine("Skipped during randomization", 0.5, 0.5, 0.5)
                end
            else
                GameTooltip:AddLine("Click to add to list", 0, 1, 0)
                if not info.owned then
                    GameTooltip:AddLine("Skipped during randomization", 0.5, 0.5, 0.5)
                end
            end

            local lists = NS.GetListsContainingToy(self.toyID)
            if #lists > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("In lists: " .. table.concat(lists, ", "), unpack(NS.COLOR_BLUE_INFO))
            end

            GameTooltip:Show()

            if listKey ~= "__all__" then
                if opts.isTopGrid or self.isInList then
                    self.actionOverlay:SetTexture(NS.TEX_REMOVE)
                    self.actionOverlay:Show()
                else
                    self.actionOverlay:SetTexture(NS.TEX_ADD)
                    self.actionOverlay:Show()
                end
            end
        end)

        btn:SetScript("OnLeave", function(self)
            GameTooltip:Hide()
            self.actionOverlay:Hide()
        end)

        btn:SetScript("OnClick", function(self)
            if not self.toyID then return end
            local listKey = opts.getListKey and opts.getListKey() or "__all__"
            if listKey == "__all__" and not opts.isTopGrid then return end

            if opts.onClick then
                opts.onClick(self.toyID, self.isInList, opts.isTopGrid)
            end
        end)

        pool[i] = btn
    end

    container.pool = pool

    function container:Layout(toyList, inListSet, showUnobtained, selectedListKey)
        local width = container:GetWidth()
        if width <= 0 then width = NS.GRID_FALLBACK_WIDTH end

        local iconsPerRow = math.floor((width + ICON_GAP) / (ICON_SIZE + ICON_GAP))
        if iconsPerRow < 1 then iconsPerRow = 1 end

        local visibleIdx = 0

        for _, entry in ipairs(toyList) do
            local toyID = entry.id or entry
            local info = NS.scannedToys[toyID]

            if info and (info.owned or showUnobtained) then
                visibleIdx = visibleIdx + 1
                if visibleIdx > poolSize then break end

                local btn = pool[visibleIdx]
                btn.toyID = toyID
                btn.isOwned = info.owned
                btn.isInList = inListSet and inListSet[toyID] or false

                btn.icon:SetTexture(info.icon)

                if info.owned then
                    btn.icon:SetDesaturated(false)
                    btn.icon:SetAlpha(1)
                    btn.lockIcon:Hide()
                else
                    btn.icon:SetDesaturated(true)
                    btn.icon:SetAlpha(0.5)
                    btn.lockIcon:Show()
                end

                if not container.isTopGrid and btn.isInList and selectedListKey ~= "__all__" then
                    btn.checkmark:Show()
                    if info.owned then
                        btn.border:SetVertexColor(unpack(NS.COLOR_GREEN))
                    else
                        btn.border:SetVertexColor(unpack(NS.COLOR_GREEN_DIM))
                    end
                elseif not info.owned then
                    btn.checkmark:Hide()
                    btn.border:SetVertexColor(unpack(NS.COLOR_GRAY))
                else
                    btn.checkmark:Hide()
                    btn.border:SetVertexColor(unpack(NS.COLOR_WHITE))
                end

                local row = math.floor((visibleIdx - 1) / iconsPerRow)
                local col = (visibleIdx - 1) % iconsPerRow
                btn:ClearAllPoints()
                btn:SetPoint("TOPLEFT", col * (ICON_SIZE + ICON_GAP), -row * (ICON_SIZE + ICON_GAP))
                btn:Show()
            end
        end

        for i = visibleIdx + 1, poolSize do
            pool[i]:Hide()
            pool[i].toyID = nil
        end

        container.visibleCount = visibleIdx

        local rows = math.ceil(visibleIdx / iconsPerRow)
        if rows < 1 then rows = 0 end
        local height = rows * (ICON_SIZE + ICON_GAP) - (rows > 0 and ICON_GAP or 0)
        container:SetHeight(math.max(height, 1))
    end

    return container
end
