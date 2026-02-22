--[[
    ShuffleStone - Hearthstone Toy Randomizer
    UI/IconGrid.lua - Reusable icon grid component with wrapping flow layout
]]--

local AddonName, NS = ...

local ICON_SIZE = 40
local ICON_GAP = 6
local BADGE_SIZE = 14

-- Reliable texture paths (atlas names can be missing in some WoW versions)
local TEX_CHECKMARK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local TEX_LOCK = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"
local TEX_REMOVE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
local TEX_ADD = "Interface\\PaperDollInfoFrame\\Character-Plus"

-- Create a single icon button
local function CreateIconButton(parent, index)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(ICON_SIZE, ICON_SIZE)

    -- Icon texture
    btn.icon = btn:CreateTexture(nil, "ARTWORK")
    btn.icon:SetAllPoints()
    btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92) -- trim edges

    -- Border
    btn.border = btn:CreateTexture(nil, "OVERLAY")
    btn.border:SetPoint("TOPLEFT", -1, 1)
    btn.border:SetPoint("BOTTOMRIGHT", 1, -1)
    btn.border:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    btn.border:SetDrawLayer("OVERLAY", -1)

    -- Checkmark badge (bottom-right, for "in list" indicator)
    btn.checkmark = btn:CreateTexture(nil, "OVERLAY")
    btn.checkmark:SetSize(BADGE_SIZE, BADGE_SIZE)
    btn.checkmark:SetPoint("BOTTOMRIGHT", 2, -2)
    btn.checkmark:SetTexture(TEX_CHECKMARK)
    btn.checkmark:Hide()

    -- Lock badge (bottom-right, for unobtained)
    btn.lockIcon = btn:CreateTexture(nil, "OVERLAY")
    btn.lockIcon:SetSize(BADGE_SIZE, BADGE_SIZE)
    btn.lockIcon:SetPoint("BOTTOMRIGHT", 2, -2)
    btn.lockIcon:SetTexture(TEX_LOCK)
    btn.lockIcon:Hide()

    -- Hover overlay (+ or - indicator)
    btn.actionOverlay = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    btn.actionOverlay:SetSize(18, 18)
    btn.actionOverlay:SetPoint("TOPRIGHT", 2, 2)
    btn.actionOverlay:Hide()

    -- Highlight texture
    btn.highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    btn.highlight:SetAllPoints()
    btn.highlight:SetColorTexture(1, 1, 1, 0.15)

    -- State
    btn.toyID = nil
    btn.isInList = false
    btn.isOwned = false

    return btn
end

-- IconGrid factory
-- opts = { parent, isTopGrid, getListKey, onClick }
function NS.CreateIconGrid(opts)
    local container = CreateFrame("Frame", nil, opts.parent)
    container.buttons = {}
    container.visibleCount = 0

    -- Create a pool of icon buttons
    local pool = {}
    local poolSize = 40 -- enough for all hearthstone toys

    for i = 1, poolSize do
        local btn = CreateIconButton(container, i)
        btn:Hide()

        btn:SetScript("OnEnter", function(self)
            if not self.toyID then return end
            local info = NS.scannedToys[self.toyID]
            if not info then return end

            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

            if info.isToy then
                GameTooltip:SetToyByItemID(self.toyID)
            else
                GameTooltip:SetItemByID(self.toyID)
            end

            -- Add action hint
            GameTooltip:AddLine(" ")
            local listKey = opts.getListKey and opts.getListKey() or "__all__"

            if not info.owned then
                GameTooltip:AddLine("Not collected", 1, 0.3, 0.3)
                GameTooltip:AddLine("Skipped during randomization", 0.5, 0.5, 0.5)
            elseif listKey == "__all__" then
                -- No add/remove action for "All" view
            elseif opts.isTopGrid or self.isInList then
                GameTooltip:AddLine("Click to remove from list", 1, 0.3, 0.3)
            else
                GameTooltip:AddLine("Click to add to list", 0, 1, 0)
            end

            -- Show list membership
            local lists = NS.GetListsContainingToy(self.toyID)
            if #lists > 0 then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("In lists: " .. table.concat(lists, ", "), 0.27, 0.67, 1)
            end

            GameTooltip:Show()

            -- Show action overlay on hover (only for owned toys, not in "All" view)
            if info.owned and listKey ~= "__all__" then
                if opts.isTopGrid or self.isInList then
                    self.actionOverlay:SetTexture(TEX_REMOVE)
                    self.actionOverlay:Show()
                else
                    self.actionOverlay:SetTexture(TEX_ADD)
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
            -- Block interaction with unobtained toys
            local info = NS.scannedToys[self.toyID]
            if not info or not info.owned then return end
            -- Block interaction in "All" view
            local listKey = opts.getListKey and opts.getListKey() or "__all__"
            if listKey == "__all__" and not opts.isTopGrid then return end

            if opts.onClick then
                opts.onClick(self.toyID, self.isInList, opts.isTopGrid)
            end
        end)

        pool[i] = btn
    end

    container.pool = pool

    -- Layout icons in a wrapping grid
    function container:Layout(toyList, inListSet, showUnobtained, selectedListKey)
        local width = container:GetWidth()
        if width <= 0 then width = 380 end

        local iconsPerRow = math.floor((width + ICON_GAP) / (ICON_SIZE + ICON_GAP))
        if iconsPerRow < 1 then iconsPerRow = 1 end

        local visibleIdx = 0

        for _, entry in ipairs(toyList) do
            local toyID = entry.id or entry
            local info = NS.scannedToys[toyID]
            if not info then goto continue end

            -- Filter unobtained if needed
            if not info.owned and not showUnobtained then
                goto continue
            end

            visibleIdx = visibleIdx + 1
            if visibleIdx > poolSize then break end

            local btn = pool[visibleIdx]
            btn.toyID = toyID
            btn.isOwned = info.owned
            btn.isInList = inListSet and inListSet[toyID] or false

            -- Icon texture
            btn.icon:SetTexture(info.icon)

            -- Owned vs unobtained visual
            if info.owned then
                btn.icon:SetDesaturated(false)
                btn.icon:SetAlpha(1)
                btn.lockIcon:Hide()
            else
                btn.icon:SetDesaturated(true)
                btn.icon:SetAlpha(0.5)
                btn.lockIcon:Show()
                btn.checkmark:Hide() -- never show checkmark on unobtained
            end

            -- Checkmark for "in list" (only on owned toys, not in "All" view)
            if info.owned and btn.isInList and selectedListKey ~= "__all__" then
                btn.checkmark:Show()
            else
                btn.checkmark:Hide()
            end

            -- Border color based on state
            if info.owned and btn.isInList and selectedListKey ~= "__all__" then
                btn.border:SetColorTexture(0, 0.8, 0, 0.6)
            elseif not info.owned then
                btn.border:SetColorTexture(0.2, 0.2, 0.2, 0.4)
            else
                btn.border:SetColorTexture(0.3, 0.3, 0.3, 0.5)
            end

            -- Position
            local row = math.floor((visibleIdx - 1) / iconsPerRow)
            local col = (visibleIdx - 1) % iconsPerRow
            btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", col * (ICON_SIZE + ICON_GAP), -row * (ICON_SIZE + ICON_GAP))
            btn:Show()

            ::continue::
        end

        -- Hide unused buttons
        for i = visibleIdx + 1, poolSize do
            pool[i]:Hide()
            pool[i].toyID = nil
        end

        container.visibleCount = visibleIdx

        -- Set container height
        local rows = math.ceil(visibleIdx / iconsPerRow)
        if rows < 1 then rows = 0 end
        local height = rows * (ICON_SIZE + ICON_GAP) - (rows > 0 and ICON_GAP or 0)
        container:SetHeight(math.max(height, 1))
    end

    return container
end
