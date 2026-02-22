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
    lists = {
        {
            name = "Favorites",
            icon = 134414, -- NS.DEFAULT_ICON (not available yet at parse time)
            toyIDs = {},   -- set: { [itemID] = true }
        },
    },
    rotationState = {},
    windowPos = { point = "CENTER", x = 0, y = 0 },
    showUnobtained = false,
    debugMode = false,
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

    print("|cff00ccffShuffleStone|r v" .. NS.Version .. " loaded. Type |cffffd100/ss|r to open.")
end

-- Register events
eventFrame:RegisterEvent("PLAYER_LOGIN")

-- Slash commands
SLASH_SHUFFLESTONE1 = "/shufflestone"
SLASH_SHUFFLESTONE2 = "/ss"

SlashCmdList["SHUFFLESTONE"] = function(msg)
    if not NS.db then
        print("|cffff8800ShuffleStone|r: Not yet loaded. Please wait for login to complete.")
        return
    end

    msg = msg:lower():trim()

    if msg == "debug" then
        NS.db.debugMode = not NS.db.debugMode
        print("|cff00ccffShuffleStone|r: Debug mode " .. (NS.db.debugMode and "ON" or "OFF"))
    elseif msg == "scan" then
        NS.ScanToys()
        print("|cff00ccffShuffleStone|r: Toy scan complete. " .. #NS.ownedToyIDs .. " owned.")
    else
        if NS.ToggleMainFrame then
            NS.ToggleMainFrame()
        end
    end
end

-- Debug helpers
function NS.Debug(msg)
    if NS.db and NS.db.debugMode then
        print("|cff00ff00[SS]|r " .. msg)
    end
end

function NS.Debugf(fmt, ...)
    if NS.db and NS.db.debugMode then
        print("|cff00ff00[SS]|r " .. string.format(fmt, ...))
    end
end
