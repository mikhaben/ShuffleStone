--[[
    ShuffleStone - Hearthstone Toy Randomizer
    ToyEngine/Buttons.lua - SecureActionButton creation, macro management
]]--

local AddonName, NS = ...

NS.buttons = {}     -- { [listKey] = secureButton }
NS.macroNames = {}  -- { [listKey] = "SS: All" or "SS: Favorites" }

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
        btn:SetAttribute("toy", toyID)
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
    btn:Hide()
    btn:SetSize(1, 1)
    btn.listKey = listKey

    -- NOTE: No PreClick handler. The toy attribute is pre-set by PreSelectAllButtons.
    -- PreClick was previously picking a NEW toy on each click, which caused the
    -- previously pre-selected toy to be consumed from rotation but never used.
    -- The correct flow is:
    --   1. PreSelectAllButtons sets attribute to toy A (consuming A from rotation)
    --   2. User clicks -> secure action uses toy A
    --   3. UNIT_SPELLCAST_SUCCEEDED -> PreSelectAllButtons picks toy B, updates icon
    --   4. User clicks -> secure action uses toy B

    NS.buttons[listKey] = btn
    return btn
end

-- Create or update macro for a list
function NS.EnsureMacro(listKey, macroDisplayName)
    if InCombatLockdown() then return end

    local btnName = "ShuffleStone_" .. SafeName(listKey)
    local macroName = macroDisplayName
    NS.macroNames[listKey] = macroName

    local body = "/click " .. btnName

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

-- Update macro icon to match currently selected toy
function NS.UpdateMacroIcon(listKey, toyID)
    if InCombatLockdown() then return end
    local macroName = NS.macroNames[listKey]
    if not macroName then return end

    local existingID = GetMacroIndexByName(macroName)
    if existingID and existingID > 0 then
        local toyInfo = NS.scannedToys[toyID]
        local icon = toyInfo and toyInfo.icon or NS.DEFAULT_ICON
        EditMacro(existingID, macroName, icon)
    end
end

-- Initialize buttons for "__all__" and each custom list
function NS.InitializeAllButtons()
    -- "All" button
    CreateSecureButton("__all__")
    NS.EnsureMacro("__all__", "SS: All")

    -- Custom list buttons
    for _, list in ipairs(NS.db.lists) do
        CreateSecureButton(list.name)
        NS.EnsureMacro(list.name, "SS: " .. list.name)
    end

    -- Validate persisted rotation state against current owned toys
    NS.ValidateAllRotations()

    -- Pre-select first toy for each button
    NS.PreSelectAllButtons()

    -- Register events for re-selection
    NS.EventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
    NS.EventFrame:RegisterEvent("NEW_TOY_ADDED")
end

-- Validate rotation state: remove stale toy IDs that player no longer owns
function NS.ValidateAllRotations()
    for listKey, state in pairs(NS.db.rotationState) do
        if state.remaining and #state.remaining > 0 then
            local pool = NS.GetOwnedToysForList(listKey)
            local poolSet = {}
            for _, id in ipairs(pool) do
                poolSet[id] = true
            end

            -- Remove IDs from remaining that aren't in current pool
            local cleaned = {}
            for _, id in ipairs(state.remaining) do
                if poolSet[id] then
                    table.insert(cleaned, id)
                end
            end
            state.remaining = cleaned
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

-- Handle spell cast to pre-select next toy
function NS:UNIT_SPELLCAST_SUCCEEDED(unit, castGUID, spellID)
    if unit ~= "player" then return end
    if spellID ~= NS.HEARTHSTONE_SPELL_ID then return end

    -- Delay slightly to avoid combat lockdown edge cases
    C_Timer.After(0.5, function()
        if not InCombatLockdown() then
            NS.PreSelectAllButtons()
        end
    end)
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
    NS.EnsureMacro(listName, "SS: " .. listName)

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
        local macroName = "SS: " .. listName
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

-- Rename a list's button and macro (destroy old, create new)
function NS.RenameListButton(oldName, newName)
    if InCombatLockdown() then return false end

    -- Save rotation state before RemoveListButton destroys it
    local savedRotation = NS.db.rotationState[oldName]

    -- Remove old button + macro
    NS.RemoveListButton(oldName)

    -- Create new button + macro with new name
    NS.CreateListButton(newName)

    -- Restore saved rotation state under new key
    if savedRotation then
        NS.db.rotationState[newName] = savedRotation
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
        end
    end
end
