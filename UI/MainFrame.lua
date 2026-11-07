local _, NS = ...

local WINDOW_WIDTH = NS.WINDOW_WIDTH
local SECTION_GAP = NS.SECTION_GAP

local selectedListKey = "__all__"
local mainFrame = nil

local topToysBuffer = {}
local dropdownBuffer = {}

local function GetCurrentInListSet()
    if selectedListKey == "__all__" then return nil end
    local list = NS.GetListByName(selectedListKey)
    return list and list.toyIDs or nil
end

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

local function GetListDropdownValues()
    local idx = 0

    idx = idx + 1
    if not dropdownBuffer[idx] then dropdownBuffer[idx] = {} end
    dropdownBuffer[idx].key = "__all__"
    dropdownBuffer[idx].text = NS.ALL_DISPLAY_NAME

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

local function CreateDropdown(parent)
    local dropdown = CreateFrame("DropdownButton", "ShuffleStoneListDropdown", parent, "WowStyle1DropdownTemplate")
    dropdown:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -32)
    dropdown:SetWidth(200)
    dropdown:SetDefaultText(NS.ALL_DISPLAY_NAME)

    local function SetupMenu(_, rootDescription)
        local values = GetListDropdownValues()
        for _, v in ipairs(values) do
            rootDescription:CreateRadio(v.text,
                function() return v.key == selectedListKey end,
                function()
                    selectedListKey = v.key
                    dropdown:SetText(v.key == "__all__" and NS.ALL_DISPLAY_NAME or v.key)
                    NS.HideIconPicker()
                    NS.RefreshMainFrame()
                end,
                v.key
            )
        end
    end

    dropdown:SetupMenu(SetupMenu)
    dropdown:SetText(NS.ALL_DISPLAY_NAME)
    return dropdown
end

function NS.CreateMainFrame()
    if mainFrame then return mainFrame end

    local frame = NS.CreateWindow({
        name   = "ShuffleStoneFrame",
        title  = "ShuffleStone",
        width  = WINDOW_WIDTH,
        minH   = 350,
        maxH   = 650,
        onDragStop = function(self)
            local point, _, _, x, y = self:GetPoint()
            NS.db.windowPos.point = point
            NS.db.windowPos.x = x
            NS.db.windowPos.y = y
        end,
        onHide = function()
            NS.HideIconPicker()
            GameTooltip:Hide()
        end,
    })

    frame:ClearAllPoints()
    frame:SetPoint(
        NS.db.windowPos.point or "CENTER",
        UIParent,
        NS.db.windowPos.point or "CENTER",
        NS.db.windowPos.x or 0,
        NS.db.windowPos.y or 0
    )

    mainFrame = frame

    local dropdown = CreateDropdown(frame)
    frame.dropdown = dropdown

    local newListBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    newListBtn:SetSize(90, 22)
    newListBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -35)
    newListBtn:SetText("+ New List")
    newListBtn:SetScript("OnClick", function()
        NS.CreateNewList()
    end)

    frame.newListBtn = newListBtn

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
        NS.HideIconPicker()
        NS.RefreshMainFrame()
        PlaySound(SOUNDKIT.IG_MAINMENU_CLOSE)
    end)

    deleteListBtn:Hide()
    frame.deleteListBtn = deleteListBtn

    local showUnobtainedCB = CreateFrame("CheckButton", "ShuffleStoneShowUnobtained", frame, "UICheckButtonTemplate")
    showUnobtainedCB:SetSize(24, 24)
    showUnobtainedCB:SetChecked(NS.db.showUnobtained)
    showUnobtainedCB:Hide()

    local cbLabel = showUnobtainedCB:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cbLabel:SetPoint("RIGHT", showUnobtainedCB, "LEFT", -2, 0)
    cbLabel:SetText("Unobtained")
    cbLabel:SetTextColor(unpack(NS.COLOR_LABEL_GRAY))

    showUnobtainedCB:SetScript("OnClick", function(self)
        NS.db.showUnobtained = self:GetChecked()
        NS.RefreshMainFrame()
    end)

    frame.showUnobtainedCB = showUnobtainedCB

    local editor = NS.CreateListEditor(frame)
    editor:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -SECTION_GAP)
    editor:SetPoint("RIGHT", frame, "RIGHT", -10, 0)

    editor.onNameChanged = function(newName)
        if not newName or newName == "" then return end
        if selectedListKey == "__all__" then return end
        if newName == selectedListKey then return end

        if newName == "__all__" then
            editor.nameBox:SetText(selectedListKey)
            return
        end

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

        local list = NS.GetListByName(selectedListKey)
        if list then
            local oldName = list.name
            list.name = newName

            NS.RenameListButton(oldName, newName)

            selectedListKey = newName
            NS.RefreshMainFrame()
        end
    end

    editor.onChangeIcon = function()
        NS.ToggleIconPicker(selectedListKey, mainFrame)
    end

    editor.onDynamicIconToggle = function(checked)
        local list = selectedListKey ~= "__all__" and NS.GetListByName(selectedListKey) or nil

        if selectedListKey == "__all__" then
            NS.db.dynamicIcon = checked
        elseif list then
            list.dynamicIcon = checked
        end

        if not InCombatLockdown() then
            if checked then
                local btn = NS.buttons[selectedListKey]
                if btn then
                    local currentToy = btn:GetAttribute("toy")
                    if currentToy then
                        NS.UpdateMacroIcon(selectedListKey, currentToy)
                    end
                end
            else
                NS.RebuildMacroBody(selectedListKey)
                NS.SetMacroIcon(selectedListKey, NS.GetListIcon(selectedListKey))
            end
        end
    end

    frame.editor = editor

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

    local emptyText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    emptyText:SetPoint("TOPLEFT", topSectionHeader, "BOTTOMLEFT", 0, -12)
    emptyText:SetText("Click hearthstones below to add them to this list")
    emptyText:SetTextColor(unpack(NS.COLOR_GRAY))
    emptyText:Hide()
    frame.emptyText = emptyText

    local bottomSectionHeader = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    bottomSectionHeader:SetPoint("TOPLEFT", editor, "BOTTOMLEFT", 2, -SECTION_GAP)
    bottomSectionHeader:SetTextColor(unpack(NS.COLOR_YELLOW))
    frame.bottomSectionHeader = bottomSectionHeader

    local bottomGrid = NS.CreateIconGrid({
        parent = frame,
        isTopGrid = false,
        getListKey = function() return selectedListKey end,
        onClick = ToggleToyInList,
    })
    bottomGrid:SetPoint("TOPLEFT", bottomSectionHeader, "BOTTOMLEFT", 0, -6)
    bottomGrid:SetPoint("RIGHT", frame, "RIGHT", -14, 0)
    frame.bottomGrid = bottomGrid

    return frame
end

function NS.RefreshMainFrame()
    if not mainFrame or not mainFrame:IsShown() then return end

    local isAllList = (selectedListKey == "__all__")
    local inListSet = GetCurrentInListSet()
    local showUnobtained = NS.db.showUnobtained

    if not isAllList and not inListSet then
        selectedListKey = "__all__"
        isAllList = true
        inListSet = nil
    end

    if isAllList then
        mainFrame.dropdown:SetText(NS.ALL_DISPLAY_NAME)
    else
        mainFrame.dropdown:SetText(selectedListKey)
    end

    if isAllList then
        mainFrame.deleteListBtn:Hide()
    else
        mainFrame.deleteListBtn:Show()
    end

    mainFrame.editor:SetListKey(selectedListKey)

    if isAllList then
        mainFrame.topSectionHeader:SetText("")
        mainFrame.topSectionHeader:Hide()
        mainFrame.topGrid:Hide()
        mainFrame.emptyText:Hide()

        mainFrame.bottomSectionHeader:ClearAllPoints()
        mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.editor, "BOTTOMLEFT", 2, -SECTION_GAP)
    else
        mainFrame.topSectionHeader:Show()
        mainFrame.topGrid:Show()

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

        mainFrame.bottomSectionHeader:ClearAllPoints()
        if inListCount > 0 then
            mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.topGrid, "BOTTOMLEFT", 0, -SECTION_GAP)
        else
            mainFrame.bottomSectionHeader:SetPoint("TOPLEFT", mainFrame.emptyText, "BOTTOMLEFT", 0, -SECTION_GAP)
        end
    end

    local ownedCount = #NS.ownedToyIDs
    local headerText = "ALL HEARTHSTONES (" .. ownedCount .. " owned)"
    if isAllList then
        headerText = "YOUR HEARTHSTONES (" .. ownedCount .. " owned)"
    end
    mainFrame.bottomSectionHeader:SetText(headerText)
    mainFrame.bottomSectionHeader:Show()

    mainFrame.showUnobtainedCB:ClearAllPoints()
    mainFrame.showUnobtainedCB:SetPoint("RIGHT", mainFrame, "RIGHT", -10, 0)
    mainFrame.showUnobtainedCB:SetPoint("TOP", mainFrame.bottomSectionHeader, "TOP", 0, 4)
    mainFrame.showUnobtainedCB:Show()

    mainFrame.bottomGrid:ClearAllPoints()
    mainFrame.bottomGrid:SetPoint("TOPLEFT", mainFrame.bottomSectionHeader, "BOTTOMLEFT", 0, -6)
    mainFrame.bottomGrid:SetPoint("RIGHT", mainFrame, "RIGHT", -14, 0)

    local gridWidth = mainFrame:GetWidth() - 28
    if gridWidth <= 0 then gridWidth = WINDOW_WIDTH - 28 end
    mainFrame.bottomGrid:SetWidth(gridWidth)
    mainFrame.bottomGrid:Layout(NS.HEARTHSTONE_TOYS, inListSet, showUnobtained, selectedListKey)

    local editorBottom = mainFrame.editor:GetBottom()
    local gridHeight = mainFrame.bottomGrid:GetHeight()
    local frameTop = mainFrame:GetTop()
    if editorBottom and gridHeight and frameTop then
        local headerHeight = frameTop - editorBottom
        local totalNeeded = headerHeight + gridHeight + 60
        if not isAllList then
            totalNeeded = totalNeeded + mainFrame.topGrid:GetHeight() + 40
        end
        totalNeeded = math.max(350, math.min(650, totalNeeded))
        mainFrame:SetHeight(totalNeeded)
    end
end

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

function NS.CreateNewList()
    if InCombatLockdown() then
        print("|cffff8800ShuffleStone|r: Cannot create lists during combat.")
        return
    end

    local baseName = "New List"
    local name = baseName
    local counter = 1

    while NS.GetListByName(name) do
        counter = counter + 1
        name = baseName .. " " .. counter
    end

    local seedToys = {}
    if NS.ownedToyIDs and #NS.ownedToyIDs > 0 then
        local randomID = NS.ownedToyIDs[math.random(1, #NS.ownedToyIDs)]
        seedToys[randomID] = true
    end

    table.insert(NS.db.lists, {
        name = name,
        icon = NS.DEFAULT_ICON,
        toyIDs = seedToys,
    })

    NS.CreateListButton(name)

    selectedListKey = name
    NS.HideIconPicker()
    NS.RefreshMainFrame()

    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_OPEN)
end
