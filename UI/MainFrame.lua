--[[
    ShuffleStone - Hearthstone Toy Randomizer
    UI/MainFrame.lua - Custom floating window (Cooldown Manager style)
]]--

local AddonName, NS = ...

local WINDOW_WIDTH = 420
local WINDOW_HEIGHT = 540

local selectedListKey = "__all__"
local mainFrame = nil

-- Reusable buffer for top grid toys (avoids allocation per refresh)
local topToysBuffer = {}

-- Get current in-list set for the selected list
local function GetCurrentInListSet()
    if selectedListKey == "__all__" then return nil end
    local list = NS.GetListByName(selectedListKey)
    return list and list.toyIDs or nil
end

-- Add/remove toy from current list
local function ToggleToyInList(toyID, isInList, isTopGrid)
    if selectedListKey == "__all__" then return end

    -- Don't allow adding unobtained toys
    local info = NS.scannedToys[toyID]
    if not info or not info.owned then return end

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

-- Build dropdown values for list selector
local function GetListDropdownValues()
    local values = {}
    table.insert(values, { key = "__all__", text = "All Hearthstones" })
    for _, list in ipairs(NS.db.lists) do
        local count = 0
        for _ in pairs(list.toyIDs) do count = count + 1 end
        table.insert(values, { key = list.name, text = list.name .. " (" .. count .. ")" })
    end
    return values
end

-- Create the dropdown menu
local function CreateDropdown(parent)
    local dropdown = CreateFrame("Frame", "ShuffleStoneListDropdown", parent, "UIDropDownMenuTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", -6, -30)

    UIDropDownMenu_SetWidth(dropdown, 180)

    UIDropDownMenu_Initialize(dropdown, function(self, level)
        local values = GetListDropdownValues()
        for _, v in ipairs(values) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = v.text
            info.value = v.key
            info.checked = (v.key == selectedListKey)
            info.func = function(btn)
                selectedListKey = btn.value
                UIDropDownMenu_SetText(dropdown, btn.value == "__all__" and "All Hearthstones" or btn.value)
                NS.RefreshMainFrame()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    UIDropDownMenu_SetText(dropdown, "All Hearthstones")
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

    -- Show Unobtained checkbox
    local showUnobtainedCB = CreateFrame("CheckButton", "ShuffleStoneShowUnobtained", frame, "UICheckButtonTemplate")
    showUnobtainedCB:SetSize(24, 24)
    showUnobtainedCB:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -12, -32)
    showUnobtainedCB:SetChecked(NS.db.showUnobtained)

    local cbLabel = showUnobtainedCB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbLabel:SetPoint("RIGHT", showUnobtainedCB, "LEFT", -2, 0)
    cbLabel:SetText("Unobtained")
    cbLabel:SetTextColor(0.8, 0.8, 0.8)

    showUnobtainedCB:SetScript("OnClick", function(self)
        NS.db.showUnobtained = self:GetChecked()
        NS.RefreshMainFrame()
    end)

    -- "+ New List" button
    local newListBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newListBtn:SetSize(90, 22)
    newListBtn:SetPoint("TOP", dropdown, "BOTTOM", 0, 2)
    newListBtn:SetText("+ New List")
    newListBtn:SetScript("OnClick", function()
        NS.CreateNewList()
    end)

    frame.newListBtn = newListBtn

    -- ==========================================
    -- LIST EDITOR ROW
    -- ==========================================

    local editor = NS.CreateListEditor(frame)
    editor:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -82)
    editor:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -82)

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

    editor.onDelete = function()
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
        print("|cff00ccffShuffleStone|r: Deleted list '" .. listName .. "'")
    end

    editor.onChangeIcon = function()
        -- Simple icon cycling through owned toy icons
        if selectedListKey == "__all__" then return end
        local list = NS.GetListByName(selectedListKey)
        if not list then return end

        local ownedToys = NS.ownedToyIDs
        if #ownedToys == 0 then return end

        local currentIcon = list.icon or NS.DEFAULT_ICON
        local nextIconIdx = 1
        for i, toyID in ipairs(ownedToys) do
            local info = NS.scannedToys[toyID]
            if info and info.icon == currentIcon then
                nextIconIdx = (i % #ownedToys) + 1
                break
            end
        end

        local nextInfo = NS.scannedToys[ownedToys[nextIconIdx]]
        if nextInfo then
            list.icon = nextInfo.icon
            NS.RefreshMainFrame()
        end
    end

    frame.editor = editor

    -- ==========================================
    -- "IN THIS LIST" SECTION (top grid, shown for custom lists)
    -- ==========================================

    local topSectionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    topSectionHeader:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 2, -10)
    topSectionHeader:SetTextColor(1, 0.82, 0)
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
    emptyText:SetTextColor(0.5, 0.5, 0.5)
    emptyText:Hide()
    frame.emptyText = emptyText

    -- ==========================================
    -- "ALL HEARTHSTONES" SECTION (bottom grid)
    -- ==========================================

    local bottomSectionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bottomSectionHeader:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 2, -10) -- default anchor
    bottomSectionHeader:SetTextColor(1, 0.82, 0)
    frame.bottomSectionHeader = bottomSectionHeader

    -- Scroll frame for bottom grid
    local scrollFrame = CreateFrame("ScrollFrame", "ShuffleStoneScrollFrame", frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", bottomSectionHeader, "BOTTOMLEFT", 0, -6) -- default anchor
    scrollFrame:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -28, 8)
    frame.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetWidth(WINDOW_WIDTH - 40)
    scrollFrame:SetScrollChild(scrollChild)
    frame.scrollChild = scrollChild

    local bottomGrid = NS.CreateIconGrid({
        parent = scrollChild,
        isTopGrid = false,
        getListKey = function() return selectedListKey end,
        onClick = ToggleToyInList,
    })
    bottomGrid:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, 0)
    bottomGrid:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
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
        UIDropDownMenu_SetText(ShuffleStoneListDropdown, "All Hearthstones")
    else
        UIDropDownMenu_SetText(ShuffleStoneListDropdown, selectedListKey)
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

        -- Position bottom section right after editor
        mainFrame.bottomSectionHeader:ClearAllPoints()
        mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.editor, "BOTTOMLEFT", 2, -10)
    else
        mainFrame.topSectionHeader:Show()
        mainFrame.topGrid:Show()

        -- Build top grid: only toys IN this list that are owned (reuse buffer)
        wipe(topToysBuffer)
        local inListCount = 0
        if inListSet then
            for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
                if inListSet[toyData.id] then
                    local info = NS.scannedToys[toyData.id]
                    if info and info.owned then
                        table.insert(topToysBuffer, toyData)
                        inListCount = inListCount + 1
                    end
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
            mainFrame.topGrid:Layout(topToysBuffer, inListSet, false, selectedListKey)
        end

        -- Position bottom section after top grid
        local topOffset = inListCount > 0 and (mainFrame.topGrid:GetHeight() + 6) or 24
        mainFrame.bottomSectionHeader:ClearAllPoints()
        mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.topSectionHeader, "BOTTOMLEFT", 0, -(topOffset + 6))
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

    -- Reposition scroll frame below bottom header
    mainFrame.scrollFrame:ClearAllPoints()
    mainFrame.scrollFrame:SetPoint("TOPLEFT", mainFrame.bottomSectionHeader, "BOTTOMLEFT", 0, -6)
    mainFrame.scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -28, 8)

    -- Update scroll child width from scroll frame
    local scrollWidth = mainFrame.scrollFrame:GetWidth()
    if scrollWidth <= 0 then scrollWidth = WINDOW_WIDTH - 40 end
    mainFrame.scrollChild:SetWidth(scrollWidth)

    -- Layout bottom grid with all toys
    mainFrame.bottomGrid:SetWidth(scrollWidth)
    mainFrame.bottomGrid:Layout(NS.HEARTHSTONE_TOYS, inListSet, showUnobtained, selectedListKey)
    mainFrame.scrollChild:SetHeight(mainFrame.bottomGrid:GetHeight() + 10)
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

    -- Create the list
    table.insert(NS.db.lists, {
        name = name,
        icon = NS.DEFAULT_ICON,
        toyIDs = {},
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

    print("|cff00ccffShuffleStone|r: Created list '" .. name .. "'. Macro 'SS: " .. name .. "' available.")
end
