--[[
    ShuffleStone - Hearthstone Toy Randomizer
    ToyEngine/Buttons.lua - SecureActionButton creation, macro management
]]--

local AddonName, NS = ...

NS.buttons = {}     -- { [listKey] = secureButton }
NS.macroNames = {}  -- { [listKey] = "SS: All" or "SS: Favorites" }

-- Reusable buffer for ValidateAllRotations
local validatePoolSet = {}

-- Sanitize list key for frame naming
local function SafeName(listKey)
    return listKey:gsub("%s+", ""):gsub("[^%w]", "")
end

-- Helper to set button attributes for a toy
local function SetButtonToy(btn, toyID)
    if not toyID then return end
    local info = NS.scannedToys[toyID]
    if info and info.isToy then
        btn:SetAttribute("type", "toy")
        btn:SetAttribute("toy", info.name)
    else
        -- Base Hearthstone is an item, not a toy
        btn:SetAttribute("type", "item")
        btn:SetAttribute("item", "item:" .. toyID)
    end
end

-- Create a hidden secure button for a list key
local function CreateSecureButton(listKey)
    local btnName = "ShuffleStone_" .. SafeName(listKey)

    -- Reuse existing button if it exists
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

    -- PostClick: after each use, queue the next random toy for the next press
    btn:SetScript("PostClick", function(self)
        if not InCombatLockdown() then
            local toyID = NS.PickNextToy(self.listKey)
            if toyID then
                SetButtonToy(self, toyID)
                NS.UpdateMacroIcon(self.listKey, toyID)
            end
        end
    end)

    NS.buttons[listKey] = btn
    return btn
end

-- Build macro body for a list key
local function BuildMacroBody(listKey)
    local btnName = "ShuffleStone_" .. SafeName(listKey)
    if NS.IsDynamicIcon(listKey) then
        return "#showtooltip\n/stopcasting\n/click " .. btnName
    else
        return "/stopcasting\n/click " .. btnName
    end
end

-- Create or update macro for a list
function NS.EnsureMacro(listKey, macroDisplayName)
    if InCombatLockdown() then return end

    local macroName = macroDisplayName
    NS.macroNames[listKey] = macroName

    local body = BuildMacroBody(listKey)

    local existingID = GetMacroIndexByName(macroName)
    if existingID and existingID > 0 then
        EditMacro(existingID, macroName, nil, body)
    else
        local icon = NS.DEFAULT_ICON
        local id = CreateMacro(macroName, icon, body, false)
        if not id then
            NS.Debug("Could not create macro '" .. macroName .. "'. Macro limit may be reached (120).")
        end
    end
end

-- Rebuild macro body (called when dynamic icon setting changes)
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

-- Update macro icon to match currently selected toy
function NS.UpdateMacroIcon(listKey, toyID)
    if not NS.IsDynamicIcon(listKey) then return end
    local toyInfo = NS.scannedToys[toyID]
    NS.SetMacroIcon(listKey, toyInfo and toyInfo.icon or NS.DEFAULT_ICON)
end

-- Initialize buttons for "__all__" and each custom list
function NS.InitializeAllButtons()
    -- "All" button
    CreateSecureButton("__all__")
    NS.EnsureMacro("__all__", NS.MACRO_ALL_NAME)

    -- Custom list buttons
    for _, list in ipairs(NS.db.lists) do
        CreateSecureButton(list.name)
        NS.EnsureMacro(list.name, NS.MacroNameForList(list.name))
    end

    -- Validate persisted rotation state against current owned toys
    NS.ValidateAllRotations()

    -- Pre-select first toy for each button
    NS.PreSelectAllButtons()

    -- Register events for re-selection
    NS.EventFrame:RegisterEvent("NEW_TOY_ADDED")
end

-- Validate rotation state: remove stale toy IDs that player no longer owns
function NS.ValidateAllRotations()
    for listKey, state in pairs(NS.db.rotationState) do
        if state.remaining and #state.remaining > 0 then
            local pool = NS.GetOwnedToysForList(listKey)
            wipe(validatePoolSet)
            for _, id in ipairs(pool) do
                validatePoolSet[id] = true
            end

            -- Remove IDs from remaining that aren't in current pool (in-place)
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

        -- Validate lastUsed
        if state.lastUsed and NS.scannedToys[state.lastUsed] and not NS.scannedToys[state.lastUsed].owned then
            state.lastUsed = nil
        end
    end
end

-- Pre-select a toy for each button (sets attribute for next click)
function NS.PreSelectAllButtons()
    if InCombatLockdown() then return end

    for listKey, btn in pairs(NS.buttons) do
        local toyID = NS.PickNextToy(listKey)
        if toyID then
            SetButtonToy(btn, toyID)
            NS.UpdateMacroIcon(listKey, toyID)
        end
    end
end

-- Handle new toy added
function NS:NEW_TOY_ADDED()
    NS.ScanToys()
    NS.ResetAllRotations()
    if not InCombatLockdown() then
        NS.PreSelectAllButtons()
    end
end

-- Create button + macro for a new custom list
function NS.CreateListButton(listName)
    CreateSecureButton(listName)
    NS.EnsureMacro(listName, NS.MacroNameForList(listName))

    if not InCombatLockdown() then
        local toyID = NS.PickNextToy(listName)
        if toyID and NS.buttons[listName] then
            SetButtonToy(NS.buttons[listName], toyID)
            NS.UpdateMacroIcon(listName, toyID)
        end
    end
end

-- Remove button + macro for a deleted list
function NS.RemoveListButton(listName)
    local btn = NS.buttons[listName]
    if btn then
        if not InCombatLockdown() then
            btn:SetAttribute("type", nil)
        end
        btn:Hide()
        NS.buttons[listName] = nil
    end

    if not InCombatLockdown() then
        local macroName = NS.MacroNameForList(listName)
        local existingID = GetMacroIndexByName(macroName)
        if existingID and existingID > 0 then
            DeleteMacro(existingID)
        end
    end

    NS.macroNames[listName] = nil
    if NS.db.rotationState[listName] then
        NS.db.rotationState[listName] = nil
    end
end

-- Rename a list's button and macro (preserves action bar slot)
function NS.RenameListButton(oldName, newName)
    if InCombatLockdown() then return false end

    -- Create new secure button with new frame name (for /click target)
    CreateSecureButton(newName)

    -- Rename existing WoW macro in-place (keeps same index → action bar stays)
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

    -- Clean up old button (do NOT delete macro)
    local oldBtn = NS.buttons[oldName]
    if oldBtn then
        oldBtn:SetAttribute("type", nil)
        oldBtn:Hide()
        NS.buttons[oldName] = nil
    end
    NS.macroNames[oldName] = nil

    -- Move rotation state to new key
    if NS.db.rotationState[oldName] then
        NS.db.rotationState[newName] = NS.db.rotationState[oldName]
        NS.db.rotationState[oldName] = nil
    end

    -- Pre-select toy for new button
    local toyID = NS.PickNextToy(newName)
    if toyID and NS.buttons[newName] then
        SetButtonToy(NS.buttons[newName], toyID)
        NS.UpdateMacroIcon(newName, toyID)
    end

    return true
end

-- Refresh a single list button (after toy add/remove from list)
function NS.RefreshListButton(listKey)
    NS.ResetRotation(listKey)
    if not InCombatLockdown() and NS.buttons[listKey] then
        local toyID = NS.PickNextToy(listKey)
        if toyID then
            SetButtonToy(NS.buttons[listKey], toyID)
            NS.UpdateMacroIcon(listKey, toyID)
        else
            -- List is empty — clear button so macro does nothing
            NS.buttons[listKey]:SetAttribute("type", nil)
            NS.buttons[listKey]:SetAttribute("toy", nil)
            NS.buttons[listKey]:SetAttribute("item", nil)
        end
    end
end
