local _, NS = ...

NS.buttons = {}
NS.macroNames = {}

local validatePoolSet = {}

local function SafeName(listKey)
    return listKey:gsub("%s+", ""):gsub("[^%w]", "")
end

local function ClearButtonAttributes(btn)
    btn:SetAttribute("type", nil)
    btn:SetAttribute("toy", nil)
end

local function SetButtonToy(btn, toyID)
    if not toyID then return end
    btn:SetAttribute("type", "toy")
    btn:SetAttribute("toy", toyID)
end

local function PickAndApply(listKey, btn)
    local toyID = NS.PickNextToy(listKey)
    if toyID then
        SetButtonToy(btn, toyID)
        NS.UpdateMacroIcon(listKey, toyID)
    else
        ClearButtonAttributes(btn)
        NS.RebuildMacroBody(listKey)
        NS.SetMacroIcon(listKey, NS.GetListIcon(listKey))
    end
end

local function CreateSecureButton(listKey)
    local btnName = "ShuffleStone_" .. SafeName(listKey)

    if NS.buttons[listKey] then
        return NS.buttons[listKey]
    end

    local btn = CreateFrame("Button", btnName, UIParent, "SecureActionButtonTemplate")
    btn:SetAttribute("type", "toy")
    btn:RegisterForClicks("AnyDown")
    btn:SetAttribute("pressAndHoldAction", true)
    btn:SetAttribute("typerelease", "toy")
    btn:Hide()
    btn:SetSize(1, 1)
    btn.listKey = listKey

    btn:SetScript("PostClick", function(self)
        if not InCombatLockdown() then
            PickAndApply(self.listKey, self)
        end
    end)

    NS.buttons[listKey] = btn
    return btn
end

local function BuildMacroBody(listKey, toyID)
    local btnName = "ShuffleStone_" .. SafeName(listKey)
    local showtooltip = toyID and ("#showtooltip item:" .. toyID) or "#showtooltip"
    return showtooltip .. "\n/stopcasting\n/click " .. btnName
end

function NS.EnsureMacro(listKey, macroName)
    if InCombatLockdown() then return end

    NS.macroNames[listKey] = macroName

    local body = BuildMacroBody(listKey)

    local existingID = GetMacroIndexByName(macroName)
    if existingID and existingID > 0 then
        EditMacro(existingID, macroName, nil, body)
    else
        local icon = NS.DEFAULT_ICON
        local id = CreateMacro(macroName, icon, body, false)
        if not id then
            print("|cffff8800ShuffleStone|r: Could not create macro '" .. macroName .. "'. Macro limit may be reached (120).")
        end
    end
end

function NS.RebuildMacroBody(listKey)
    if InCombatLockdown() then return end
    local macroName = NS.macroNames[listKey]
    if not macroName then return end

    local existingID = GetMacroIndexByName(macroName)
    if existingID and existingID > 0 then
        local body = BuildMacroBody(listKey)
        EditMacro(existingID, macroName, nil, body)
    end
end

function NS.UpdateMacroIcon(listKey, toyID)
    if InCombatLockdown() then return end
    local toyInfo = NS.scannedToys[toyID]
    local icon = toyInfo and toyInfo.icon or NS.DEFAULT_ICON

    C_Timer.After(0, function()
        if InCombatLockdown() then return end
        local macroName = NS.macroNames[listKey]
        if not macroName then return end
        local macroID = GetMacroIndexByName(macroName)
        if not macroID or macroID == 0 then return end

        local body = BuildMacroBody(listKey, toyID)
        if NS.IsDynamicIcon(listKey) then
            EditMacro(macroID, macroName, icon, body)
        else
            EditMacro(macroID, macroName, nil, body)
        end
    end)
end

function NS.InitializeAllButtons()
    CreateSecureButton("__all__")
    NS.EnsureMacro("__all__", NS.MACRO_ALL_NAME)

    for _, list in ipairs(NS.db.lists) do
        CreateSecureButton(list.name)
        NS.EnsureMacro(list.name, NS.MacroNameForList(list.name))
    end

    NS.ValidateAllRotations()

    NS.PreSelectAllButtons()

end

function NS.ValidateAllRotations()
    for _, list in ipairs(NS.db.lists) do
        local stale
        for toyID in pairs(list.toyIDs) do
            if not NS.scannedToys[toyID] then
                stale = stale or {}
                stale[#stale + 1] = toyID
            end
        end
        if stale then
            for _, id in ipairs(stale) do
                list.toyIDs[id] = nil
            end
        end
    end

    local orphans
    for listKey in pairs(NS.db.rotationState) do
        if listKey ~= "__all__" and not NS.GetListByName(listKey) then
            orphans = orphans or {}
            orphans[#orphans + 1] = listKey
        end
    end
    if orphans then
        for _, key in ipairs(orphans) do
            NS.db.rotationState[key] = nil
        end
    end

    for listKey, state in pairs(NS.db.rotationState) do
        if state.remaining and #state.remaining > 0 then
            local pool = NS.GetOwnedToysForList(listKey)
            wipe(validatePoolSet)
            for _, id in ipairs(pool) do
                validatePoolSet[id] = true
            end

            local writeIdx = 0
            for i = 1, #state.remaining do
                if validatePoolSet[state.remaining[i]] then
                    writeIdx = writeIdx + 1
                    state.remaining[writeIdx] = state.remaining[i]
                end
            end
            for i = #state.remaining, writeIdx + 1, -1 do
                state.remaining[i] = nil
            end
        end

        if state.lastUsed and (not NS.scannedToys[state.lastUsed] or not NS.scannedToys[state.lastUsed].owned) then
            state.lastUsed = nil
        end
    end
end

function NS.PreSelectAllButtons()
    if InCombatLockdown() then return end

    for listKey, btn in pairs(NS.buttons) do
        local currentToy = btn:GetAttribute("toy")
        local hasValid = currentToy and NS.scannedToys[currentToy] and NS.scannedToys[currentToy].owned
        if not hasValid then
            PickAndApply(listKey, btn)
        end
    end
end

function NS.CreateListButton(listName)
    CreateSecureButton(listName)
    NS.EnsureMacro(listName, NS.MacroNameForList(listName))

    if not InCombatLockdown() and NS.buttons[listName] then
        PickAndApply(listName, NS.buttons[listName])
    end
end

function NS.RemoveListButton(listName)
    local btn = NS.buttons[listName]
    if btn then
        if not InCombatLockdown() then
            ClearButtonAttributes(btn)
        end
        btn:Hide()
        NS.buttons[listName] = nil
    end

    if not InCombatLockdown() then
        local macroName = NS.macroNames[listName] or NS.MacroNameForList(listName)
        local existingID = GetMacroIndexByName(macroName)
        if existingID and existingID > 0 then
            DeleteMacro(existingID)
        end
    end

    NS.macroNames[listName] = nil
    NS.db.rotationState[listName] = nil
end

function NS.RenameListButton(oldName, newName)
    if InCombatLockdown() then return false end

    CreateSecureButton(newName)

    local oldMacroName = NS.macroNames[oldName]
    if oldMacroName then
        local macroID = GetMacroIndexByName(oldMacroName)
        if macroID and macroID > 0 then
            local newMacroName = NS.MacroNameForList(newName)
            local body = BuildMacroBody(newName)
            EditMacro(macroID, newMacroName, nil, body)
            NS.macroNames[newName] = newMacroName
        end
    end

    if not NS.macroNames[newName] then
        NS.EnsureMacro(newName, NS.MacroNameForList(newName))
    end

    local oldBtn = NS.buttons[oldName]
    if oldBtn then
        ClearButtonAttributes(oldBtn)
        oldBtn:Hide()
        NS.buttons[oldName] = nil
    end
    NS.macroNames[oldName] = nil

    if NS.db.rotationState[oldName] then
        NS.db.rotationState[newName] = NS.db.rotationState[oldName]
        NS.db.rotationState[oldName] = nil
    end

    if NS.buttons[newName] then
        PickAndApply(newName, NS.buttons[newName])
    end

    return true
end

function NS.RefreshListButton(listKey)
    NS.ResetRotation(listKey)
    if not InCombatLockdown() and NS.buttons[listKey] then
        PickAndApply(listKey, NS.buttons[listKey])
    end
end
