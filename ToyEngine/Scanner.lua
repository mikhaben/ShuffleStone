--[[
    ShuffleStone - Hearthstone Toy Randomizer
    ToyEngine/Scanner.lua - Toy ownership scanning and filtered list building
]]--

local AddonName, NS = ...

-- Runtime scan results (not persisted)
NS.scannedToys = {}   -- { [itemID] = { id, name, icon, owned, usable, quality, isToy } }
NS.ownedToyIDs = {}   -- ordered array of owned toy IDs

-- Reusable buffers (avoids allocation per call)
local listsBuffer = {}
local ownedToysBuffer = {}

function NS.ScanToys()
    wipe(NS.scannedToys)
    wipe(NS.ownedToyIDs)

    -- Resolve GetItemInfo once outside the loop
    local getItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

    for _, toyData in ipairs(NS.HEARTHSTONE_TOYS) do
        local toyID = toyData.id
        local isToy = (toyID ~= NS.BASE_HEARTHSTONE_ID)

        local toyName = toyData.name
        local icon = NS.DEFAULT_ICON
        local owned = false
        local usable = false
        local quality = 1

        if isToy then
            local _, infoName, infoIcon, _, _, infoQuality = C_ToyBox.GetToyInfo(toyID)
            if infoName then toyName = infoName end
            if infoIcon then icon = infoIcon end
            if infoQuality then quality = infoQuality end
            owned = PlayerHasToy(toyID)
            usable = owned and C_ToyBox.IsToyUsable(toyID)
        else
            -- Base Hearthstone is always owned (it's an item, not a toy)
            owned = true
            usable = true
            if getItemInfo then
                local itemName, _, itemQuality, _, _, _, _, _, _, itemIcon = getItemInfo(toyID)
                if itemName then toyName = itemName end
                if itemIcon then icon = itemIcon end
                if itemQuality then quality = itemQuality end
            end
        end

        NS.scannedToys[toyID] = {
            id = toyID,
            name = toyName,
            icon = icon,
            owned = owned,
            usable = usable,
            quality = quality,
            isToy = isToy,
        }

        if owned then
            table.insert(NS.ownedToyIDs, toyID)
        end
    end

    NS.Debugf("Scanned %d toys, %d owned", #NS.HEARTHSTONE_TOYS, #NS.ownedToyIDs)
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
function NS.GetOwnedToysForList(listKey)
    if listKey == "__all__" then
        return NS.ownedToyIDs
    end

    local list = NS.GetListByName(listKey)
    if not list then return {} end

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
