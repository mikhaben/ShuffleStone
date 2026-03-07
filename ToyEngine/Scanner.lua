--[[
    ShuffleStone - Hearthstone Toy Randomizer
    ToyEngine/Scanner.lua - Toy ownership scanning and filtered list building
]]--

local AddonName, NS = ...

-- Runtime scan results (not persisted)
NS.scannedToys = {}   -- { [itemID] = { name, icon, owned } }
NS.ownedToyIDs = {}   -- ordered array of owned toy IDs

-- Reusable buffers (avoids allocation per call)
local listsBuffer = {}
local ownedToysBuffer = {}
local EMPTY = {}

function NS.ScanToys()
    wipe(NS.scannedToys)
    wipe(NS.ownedToyIDs)

    for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
        local toyID = toyData.id

        local toyName = toyData.name
        local icon = NS.DEFAULT_ICON

        local _, infoName, infoIcon = C_ToyBox.GetToyInfo(toyID)
        if infoName then toyName = infoName end
        if infoIcon then icon = infoIcon end
        local owned = PlayerHasToy(toyID)

        NS.scannedToys[toyID] = {
            name = toyName,
            icon = icon,
            owned = owned,
        }

        if owned then
            table.insert(NS.ownedToyIDs, toyID)
        end
    end

end

-- Find a list object by name. Returns list table or nil.
function NS.GetListByName(listName)
    for _, list in ipairs(NS.db.lists) do
        if list.name == listName then
            return list
        end
    end
    return nil
end

-- Get owned toy IDs for a list key ("__all__" or list name)
-- Returns the shared ownedToyIDs for "__all__", or builds a filtered array.
-- WARNING: for custom lists, returned table is reused on next call - do not store a reference.
function NS.GetOwnedToysForList(listKey)
    if listKey == "__all__" then
        return NS.ownedToyIDs
    end

    local list = NS.GetListByName(listKey)
    if not list then return EMPTY end

    wipe(ownedToysBuffer)
    for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
        local toyID = toyData.id
        if list.toyIDs[toyID] then
            local info = NS.scannedToys[toyID]
            if info and info.owned then
                table.insert(ownedToysBuffer, toyID)
            end
        end
    end
    return ownedToysBuffer
end

-- Get all list names containing a toy. Reuses a buffer table (zero allocation).
-- WARNING: returned table is reused on next call - do not store a reference.
function NS.GetListsContainingToy(toyID)
    wipe(listsBuffer)
    for _, list in ipairs(NS.db.lists) do
        if list.toyIDs[toyID] then
            table.insert(listsBuffer, list.name)
        end
    end
    return listsBuffer
end
