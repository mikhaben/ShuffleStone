--[[
    ShuffleStone - Hearthstone Toy Randomizer
    UI/MainFrame.lua - Custom floating window (Cooldown Manager style)
]]--

local AddonName, NS = ...

local WINDOW_WIDTH = NS.WINDOW_WIDTH
local WINDOW_HEIGHT = NS.WINDOW_HEIGHT
local SECTION_GAP = NS.SECTION_GAP

local selectedListKey = "__all__"
local mainFrame = nil

function NS.GetSelectedListKey()
    return selectedListKey
end

function NS.SetSelectedListKey(key)
    selectedListKey = key
end

-- Reusable buffers (avoids allocation per refresh/interaction)
local topToysBuffer = {}
local dropdownBuffer = {}
local iconCycleBuffer = {}

-- Get current in-list set for the selected list
local function GetCurrentInListSet()
    if selectedListKey == "__all__" then return nil end
    local list = NS.GetListByName(selectedListKey)
    return list and list.toyIDs or nil
end

-- Add/remove toy from current list
local function ToggleToyInList(toyID, isInList, isTopGrid)
    if selectedListKey == "__all__" then return end

    local list = NS.GetListByName(selectedListKey)
    if not list then return end

    if isInList or isTopGrid then
        list.toyIDs[toyID] = nil
    else
        list.toyIDs[toyID] = true
    end
    NS.RefreshListButton(selectedListKey)
    NS.RefreshMainFrame()
    PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
end

-- Build dropdown values for list selector (reuses buffer tables)
local function GetListDropdownValues()
    local idx = 0

    idx = idx + 1
    if not dropdownBuffer[idx] then dropdownBuffer[idx] = {} end
    dropdownBuffer[idx].key = "__all__"
    dropdownBuffer[idx].text = "All Hearthstones"

    for _, list in ipairs(NS.db.lists) do
        idx = idx + 1
        if not dropdownBuffer[idx] then dropdownBuffer[idx] = {} end
        dropdownBuffer[idx].key = list.name
        local count = 0
        for _ in pairs(list.toyIDs) do count = count + 1 end
        dropdownBuffer[idx].text = list.name .. " (" .. count .. ")"
    end

    for i = idx + 1, #dropdownBuffer do
        dropdownBuffer[i] = nil
    end

    return dropdownBuffer
end

-- Create the dropdown menu (WowStyle1 — modern WoW 11.0+ dropdown)
local function CreateDropdown(parent)
    local dropdown = CreateFrame("DropdownButton", "ShuffleStoneListDropdown", parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -32)
    dropdown:SetWidth(200)
    dropdown:SetDefaultText("All Hearthstones")

    local function SetupMenu(dd, rootDescription)
        local values = GetListDropdownValues()
        for _, v in ipairs(values) do
            rootDescription:CreateRadio(v.text,
                function() return v.key == selectedListKey end,
                function()
                    selectedListKey = v.key
                    dropdown:SetText(v.key == "__all__" and "All Hearthstones" or v.key)
                    NS.RefreshMainFrame()
                end,
                v.key
            )
        end
    end

    dropdown:SetupMenu(SetupMenu)
    dropdown:SetText("All Hearthstones")
    return dropdown
end

function NS.CreateMainFrame()
    if mainFrame then return mainFrame end

    -- Main window
    local frame = CreateFrame("Frame", "ShuffleStoneFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint(
        NS.db.windowPos.point or "CENTER",
        UIParent,
        NS.db.windowPos.point or "CENTER",
        NS.db.windowPos.x or 0,
        NS.db.windowPos.y or 0
    )
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, _, x, y = self:GetPoint()
        NS.db.windowPos.point = point
        NS.db.windowPos.x = x
        NS.db.windowPos.y = y
    end)
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("DIALOG")

    -- Add to ESC-closable frames
    tinsert(UISpecialFrames, "ShuffleStoneFrame")

    -- Title
    frame.TitleText:SetText("ShuffleStone")

    -- Hide by default
    frame:Hide()

    mainFrame = frame

    -- ==========================================
    -- HEADER: Dropdown + Show Unobtained + New List
    -- ==========================================

    local dropdown = CreateDropdown(frame)
    frame.dropdown = dropdown

    -- "+ New List" button (same row as dropdown, right-justified)
    local newListBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newListBtn:SetSize(90, 22)
    newListBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -35)
    newListBtn:SetText("+ New List")
    newListBtn:SetScript("OnClick", function()
        NS.CreateNewList()
    end)

    frame.newListBtn = newListBtn

    -- Delete list button (trash icon, header row, left of New List)
    local deleteListBtn = CreateFrame("Button", nil, frame)
    deleteListBtn:SetSize(22, 22)
    deleteListBtn:SetPoint("LEFT", dropdown, "RIGHT", 6, 0)

    deleteListBtn.icon = deleteListBtn:CreateTexture(nil, "ARTWORK")
    deleteListBtn.icon:SetAllPoints()
    deleteListBtn.icon:SetTexture(NS.TEX_TRASH_NORMAL)

    deleteListBtn:SetHighlightTexture(NS.TEX_TRASH_HIGHLIGHT)

    deleteListBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:AddLine("Delete List", unpack(NS.COLOR_RED))
        GameTooltip:Show()
    end)
    deleteListBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    deleteListBtn:SetScript("OnClick", function()
        if selectedListKey == "__all__" then return end
        if InCombatLockdown() then
            print("|cffff8800ShuffleStone|r: Cannot delete during combat.")
            return
        end

        local listName = selectedListKey
        NS.RemoveListButton(listName)
        for i, list in ipairs(NS.db.lists) do
            if list.name == listName then
                table.remove(NS.db.lists, i)
                break
            end
        end
        selectedListKey = "__all__"
        NS.RefreshMainFrame()
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    end)

    deleteListBtn:Hide()
    frame.deleteListBtn = deleteListBtn

    -- Show Unobtained checkbox (will be positioned dynamically next to bottom header)
    local showUnobtainedCB = CreateFrame("CheckButton", "ShuffleStoneShowUnobtained", frame, "UICheckButtonTemplate")
    showUnobtainedCB:SetSize(24, 24)
    showUnobtainedCB:SetChecked(NS.db.showUnobtained)
    showUnobtainedCB:Hide() -- positioned dynamically in RefreshMainFrame

    local cbLabel = showUnobtainedCB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbLabel:SetPoint("RIGHT", showUnobtainedCB, "LEFT", -2, 0)
    cbLabel:SetText("Unobtained")
    cbLabel:SetTextColor(unpack(NS.COLOR_LABEL_GRAY))

    showUnobtainedCB:SetScript("OnClick", function(self)
        NS.db.showUnobtained = self:GetChecked()
        NS.RefreshMainFrame()
    end)

    frame.showUnobtainedCB = showUnobtainedCB

    -- ==========================================
    -- LIST EDITOR ROW
    -- ==========================================

    local editor = NS.CreateListEditor(frame)
    editor:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -SECTION_GAP)
    editor:SetPoint("RIGHT", frame, "RIGHT", -10, 0)

    -- Wire callbacks
    editor.onNameChanged = function(newName)
        if not newName or newName == "" then return end
        if selectedListKey == "__all__" then return end
        if newName == selectedListKey then return end -- no change

        -- Check duplicate
        if NS.GetListByName(newName) then
            print("|cffff8800ShuffleStone|r: List '" .. newName .. "' already exists.")
            editor.nameBox:SetText(selectedListKey)
            return
        end

        if InCombatLockdown() then
            print("|cffff8800ShuffleStone|r: Cannot rename during combat.")
            editor.nameBox:SetText(selectedListKey)
            return
        end

        -- Rename the list data
        local list = NS.GetListByName(selectedListKey)
        if list then
            local oldName = list.name
            list.name = newName

            -- Destroy old button/macro, create new ones with correct frame name
            NS.RenameListButton(oldName, newName)

            selectedListKey = newName
            NS.RefreshMainFrame()
        end
    end

    editor.onChangeIcon = function()
        -- Build toy pool to cycle through (reuses buffer)
        wipe(iconCycleBuffer)
        local currentToyID

        if selectedListKey == "__all__" then
            for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
                table.insert(iconCycleBuffer, toyData.id)
            end
            currentToyID = NS.db.allIconToyID
        else
            local list = NS.GetListByName(selectedListKey)
            if not list then return end
            for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
                if list.toyIDs[toyData.id] then
                    table.insert(iconCycleBuffer, toyData.id)
                end
            end
            currentToyID = list.iconToyID
        end

        if #iconCycleBuffer == 0 then return end

        -- Find current toy's position, advance to next
        local nextIdx = 1
        if currentToyID then
            for i, toyID in ipairs(iconCycleBuffer) do
                if toyID == currentToyID then
                    nextIdx = (i % #iconCycleBuffer) + 1
                    break
                end
            end
        end

        local nextToyID = iconCycleBuffer[nextIdx]
        local nextInfo = NS.scannedToys[nextToyID]
        if nextInfo then
            if selectedListKey == "__all__" then
                NS.db.allIcon = nextInfo.icon
                NS.db.allIconToyID = nextToyID
            else
                local list = NS.GetListByName(selectedListKey)
                if list then
                    list.icon = nextInfo.icon
                    list.iconToyID = nextToyID
                end
            end

            -- Update the actual WoW macro icon when dynamic icon is off
            if not NS.IsDynamicIcon(selectedListKey) then
                NS.SetMacroIcon(selectedListKey, nextInfo.icon)
            end

            NS.RefreshMainFrame()
        end
    end

    editor.onDynamicIconToggle = function(checked)
        if selectedListKey == "__all__" then
            NS.db.dynamicIcon = checked
        else
            local list = NS.GetListByName(selectedListKey)
            if list then
                list.dynamicIcon = checked
            end
        end

        if not InCombatLockdown() then
            -- Rebuild macro body: add/remove #showtooltip
            NS.RebuildMacroBody(selectedListKey)

            -- When turning off, also reset icon to static
            if not checked then
                local icon
                if selectedListKey == "__all__" then
                    icon = NS.db.allIcon or NS.DEFAULT_ICON
                else
                    local list = NS.GetListByName(selectedListKey)
                    icon = list and list.icon or NS.DEFAULT_ICON
                end
                NS.SetMacroIcon(selectedListKey, icon)
            end
        end
    end

    frame.editor = editor

    -- ==========================================
    -- "IN THIS LIST" SECTION (top grid, shown for custom lists)
    -- ==========================================

    local topSectionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    topSectionHeader:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 2, -SECTION_GAP)
    topSectionHeader:SetTextColor(unpack(NS.COLOR_YELLOW))
    frame.topSectionHeader = topSectionHeader

    local topGrid = NS.CreateIconGrid({
        parent = frame,
        isTopGrid = true,
        getListKey = function() return selectedListKey end,
        onClick = ToggleToyInList,
    })
    topGrid:SetPoint("TOPLEFT", topSectionHeader, "BOTTOMLEFT", 0, -6)
    topGrid:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    frame.topGrid = topGrid

    -- Empty state text
    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    emptyText:SetPoint("TOPLEFT", topSectionHeader, "BOTTOMLEFT", 0, -12)
    emptyText:SetText("Click hearthstones below to add them to this list")
    emptyText:SetTextColor(unpack(NS.COLOR_GRAY))
    emptyText:Hide()
    frame.emptyText = emptyText

    -- ==========================================
    -- "ALL HEARTHSTONES" SECTION (bottom grid)
    -- ==========================================

    local bottomSectionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bottomSectionHeader:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 2, -SECTION_GAP) -- default anchor
    bottomSectionHeader:SetTextColor(unpack(NS.COLOR_YELLOW))
    frame.bottomSectionHeader = bottomSectionHeader

    -- Bottom grid (direct child of frame — no scroll)
    local bottomGrid = NS.CreateIconGrid({
        parent = frame,
        isTopGrid = false,
        getListKey = function() return selectedListKey end,
        onClick = ToggleToyInList,
    })
    bottomGrid:SetPoint("TOPLEFT", bottomSectionHeader, "BOTTOMLEFT", 0, -6)
    bottomGrid:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    frame.bottomGrid = bottomGrid

    mainFrame = frame
    return frame
end

-- Refresh the entire UI based on current state
function NS.RefreshMainFrame()
    if not mainFrame or not mainFrame:IsShown() then return end

    local isAllList = (selectedListKey == "__all__")
    local inListSet = GetCurrentInListSet()
    local showUnobtained = NS.db.showUnobtained

    -- If selected list was deleted, fall back to "__all__"
    if not isAllList and not inListSet then
        selectedListKey = "__all__"
        isAllList = true
        inListSet = nil
    end

    -- Update dropdown text
    if isAllList then
        mainFrame.dropdown:SetText("All Hearthstones")
    else
        mainFrame.dropdown:SetText(selectedListKey)
    end

    -- Show/hide delete button
    if isAllList then
        mainFrame.deleteListBtn:Hide()
    else
        mainFrame.deleteListBtn:Show()
    end

    -- Update editor
    mainFrame.editor:SetListKey(selectedListKey)

    -- ==========================================
    -- TOP GRID (In This List)
    -- ==========================================

    if isAllList then
        -- Hide top section for "All"
        mainFrame.topSectionHeader:SetText("")
        mainFrame.topSectionHeader:Hide()
        mainFrame.topGrid:Hide()
        mainFrame.emptyText:Hide()

        -- Position bottom section right after editor (+ hint below)
        mainFrame.bottomSectionHeader:ClearAllPoints()
        mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.editor, "BOTTOMLEFT", 2, -SECTION_GAP)
    else
        mainFrame.topSectionHeader:Show()
        mainFrame.topGrid:Show()

        -- Build top grid: all toys IN this list (including unobtained)
        wipe(topToysBuffer)
        local inListCount = 0
        if inListSet then
            for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
                if inListSet[toyData.id] then
                    table.insert(topToysBuffer, toyData)
                    inListCount = inListCount + 1
                end
            end
        end

        mainFrame.topSectionHeader:SetText("IN THIS LIST (" .. inListCount .. ")")

        if inListCount == 0 then
            mainFrame.emptyText:Show()
            mainFrame.topGrid:SetHeight(1)
            mainFrame.topGrid:Hide()
        else
            mainFrame.emptyText:Hide()
            mainFrame.topGrid:Show()
            mainFrame.topGrid:Layout(topToysBuffer, inListSet, true, selectedListKey)
        end

        -- Position bottom section after top grid
        mainFrame.bottomSectionHeader:ClearAllPoints()
        if inListCount > 0 then
            mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.topGrid, "BOTTOMLEFT", 0, -SECTION_GAP)
        else
            mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.emptyText, "BOTTOMLEFT", 0, -SECTION_GAP)
        end
    end

    -- ==========================================
    -- BOTTOM GRID (All Hearthstones)
    -- ==========================================

    local ownedCount = #NS.ownedToyIDs
    local headerText = "ALL HEARTHSTONES (" .. ownedCount .. " owned)"
    if isAllList then
        headerText = "YOUR HEARTHSTONES (" .. ownedCount .. " owned)"
    end
    mainFrame.bottomSectionHeader:SetText(headerText)
    mainFrame.bottomSectionHeader:Show()

    -- Position unobtained checkbox next to bottom section header (right-justified)
    mainFrame.showUnobtainedCB:ClearAllPoints()
    mainFrame.showUnobtainedCB:SetPoint("RIGHT", mainFrame, "RIGHT", -10, 0)
    mainFrame.showUnobtainedCB:SetPoint("TOP", mainFrame.bottomSectionHeader, "TOP", 0, 4)
    mainFrame.showUnobtainedCB:Show()

    -- Position and layout bottom grid directly
    mainFrame.bottomGrid:ClearAllPoints()
    mainFrame.bottomGrid:SetPoint("TOPLEFT", mainFrame.bottomSectionHeader, "BOTTOMLEFT", 0, -6)
    mainFrame.bottomGrid:SetPoint("RIGHT", mainFrame, "RIGHT", -14, 0)

    local gridWidth = mainFrame:GetWidth() - 28
    if gridWidth <= 0 then gridWidth = WINDOW_WIDTH - 28 end
    mainFrame.bottomGrid:SetWidth(gridWidth)
    mainFrame.bottomGrid:Layout(NS.HEARTHSTONE_TOYS, inListSet, showUnobtained, selectedListKey)

    -- Dynamic window height: fit content without excess empty space
    local editorBottom = mainFrame.editor:GetBottom()
    local gridHeight = mainFrame.bottomGrid:GetHeight()
    if editorBottom and gridHeight then
        local headerHeight = mainFrame:GetTop() - editorBottom
        local totalNeeded = headerHeight + gridHeight + 60
        if not isAllList then
            totalNeeded = totalNeeded + mainFrame.topGrid:GetHeight() + 40
        end
        totalNeeded = math.max(350, math.min(650, totalNeeded))
        mainFrame:SetHeight(totalNeeded)
    end
end

-- Toggle main frame visibility
function NS.ToggleMainFrame()
    if not mainFrame then
        NS.CreateMainFrame()
    end

    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
        NS.RefreshMainFrame()
    end
end

-- Create a new list flow
function NS.CreateNewList()
    if InCombatLockdown() then
        print("|cffff8800ShuffleStone|r: Cannot create lists during combat.")
        return
    end

    -- Create with default name
    local baseName = "New List"
    local name = baseName
    local counter = 1

    -- Find unique name
    while NS.GetListByName(name) do
        counter = counter + 1
        name = baseName .. " " .. counter
    end

    -- Seed with 1 random owned hearthstone
    local seedToys = {}
    if NS.ownedToyIDs and #NS.ownedToyIDs > 0 then
        local randomID = NS.ownedToyIDs[math.random(1, #NS.ownedToyIDs)]
        seedToys[randomID] = true
    end

    -- Create the list
    table.insert(NS.db.lists, {
        name = name,
        icon = NS.DEFAULT_ICON,
        toyIDs = seedToys,
    })

    -- Create button + macro
    NS.CreateListButton(name)

    -- Select the new list
    selectedListKey = name
    NS.RefreshMainFrame()

    -- Focus the name edit box so user can rename immediately
    if mainFrame and mainFrame.editor and mainFrame.editor.nameBox then
        mainFrame.editor.nameBox:SetFocus()
        mainFrame.editor.nameBox:HighlightText()
    end

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
end
