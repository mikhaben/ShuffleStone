--[[
    ShuffleStone - Hearthstone Toy Randomizer
    Core.lua - Namespace, defaults, database, events, slash commands
]]--

local AddonName, NS = ...
_G.ShuffleStone = NS

-- Version info
NS.Title = C_AddOns.GetAddOnMetadata(AddonName, "Title")
NS.Version = C_AddOns.GetAddOnMetadata(AddonName, "Version")
NS.Author = C_AddOns.GetAddOnMetadata(AddonName, "Author")

-- Default saved variables structure
NS.defaults = {
    lists = {},
    rotationState = {},
    windowPos = { point = "CENTER", x = 0, y = 0 },
    showUnobtained = false,
    dynamicIcon = true,
    onboardingDismissed = false,
}

-- Deep copy
function NS.DeepCopy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for k, v in next, orig, nil do
        copy[NS.DeepCopy(k)] = NS.DeepCopy(v)
    end
    return copy
end

-- Merge saved with defaults (add missing keys)
local function MergeDefaults(saved, defaults)
    for k, v in pairs(defaults) do
        if saved[k] == nil then
            if type(v) == "table" then
                saved[k] = NS.DeepCopy(v)
            else
                saved[k] = v
            end
        elseif type(v) == "table" and type(saved[k]) == "table" then
            MergeDefaults(saved[k], v)
        end
    end
    return saved
end

-- Initialize database
local function InitializeDatabase()
    if not ShuffleStoneDB then
        ShuffleStoneDB = NS.DeepCopy(NS.defaults)
    else
        ShuffleStoneDB = MergeDefaults(ShuffleStoneDB, NS.defaults)
    end
    NS.db = ShuffleStoneDB
end

-- Event frame
local eventFrame = CreateFrame("Frame")
NS.EventFrame = eventFrame

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if NS[event] then
        NS[event](NS, ...)
    end
end)

-- PLAYER_LOGIN
function NS:PLAYER_LOGIN()
    InitializeDatabase()

    -- Scan toys
    if NS.ScanToys then
        NS.ScanToys()
    end

    -- Initialize secure buttons + macros
    if NS.InitializeAllButtons then
        NS.InitializeAllButtons()
    end

    -- Initialize UI (pre-create main frame hidden)
    if NS.CreateMainFrame then
        NS.CreateMainFrame()
        NS.Debug("UI initialized")
    end

    -- Register settings panel
    if NS.InitializeSettings then
        NS.InitializeSettings()
    end

    NS.Debug("v" .. NS.Version .. " loaded.")
end

-- Rescan toys when toy box data becomes available from the server
function NS:TOYS_UPDATED()
    if NS.ScanToys then
        NS.ScanToys()
    end
    if NS.RefreshMainFrame then
        NS.RefreshMainFrame()
    end
end

-- Rescan when player obtains a new toy
function NS:NEW_TOY_ADDED()
    if NS.ScanToys then
        NS.ScanToys()
    end
    if NS.RefreshMainFrame then
        NS.RefreshMainFrame()
    end
end

-- Register events
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("TOYS_UPDATED")
eventFrame:RegisterEvent("NEW_TOY_ADDED")

-- Slash commands
SLASH_SHUFFLESTONE1 = "/shufflestone"
SLASH_SHUFFLESTONE2 = "/ss"

SlashCmdList["SHUFFLESTONE"] = function(msg)
    if not NS.db then return end

    msg = msg:lower():trim()

    if msg == "debug" then
        NS.PrintDebugInfo()
    else
        if NS.ToggleMainFrame then
            NS.ToggleMainFrame()
        end
    end
end

-- Debug info dump (/ss debug)
function NS.PrintDebugInfo()
    local p = function(msg) print("|cff00ff00[SS]|r " .. msg) end

    p("|cff00ccffShuffleStone|r v" .. (NS.Version or "?"))
    p("Owned hearthstones: " .. (NS.ownedToyIDs and #NS.ownedToyIDs or 0))
    p("Custom lists: " .. (NS.db and #NS.db.lists or 0))

    -- List details
    if NS.db then
        for _, list in ipairs(NS.db.lists) do
            local count = 0
            local ownedCount = 0
            for toyID in pairs(list.toyIDs) do
                count = count + 1
                local info = NS.scannedToys and NS.scannedToys[toyID]
                if info and info.owned then ownedCount = ownedCount + 1 end
            end
            p("  " .. list.name .. ": " .. count .. " toys (" .. ownedCount .. " owned)")
        end
    end

    -- Macros
    p("Macros:")
    for listKey, macroName in pairs(NS.macroNames) do
        local macroID = GetMacroIndexByName(macroName)
        local status = (macroID and macroID > 0) and "|cff00ff00OK|r" or "|cffff0000MISSING|r"
        p("  " .. macroName .. " — " .. status)
    end

    -- Buttons
    local btnCount = 0
    for _ in pairs(NS.buttons) do btnCount = btnCount + 1 end
    p("Secure buttons: " .. btnCount)

    -- Rotation state
    if NS.db and NS.db.rotationState then
        for listKey, state in pairs(NS.db.rotationState) do
            local remaining = state.remaining and #state.remaining or 0
            local last = state.lastUsed or "none"
            p("  Rotation [" .. listKey .. "]: " .. remaining .. " remaining, last=" .. tostring(last))
        end
    end
end

-- No-op debug helpers (kept for compatibility)
function NS.Debug() end
function NS.Debugf() end
