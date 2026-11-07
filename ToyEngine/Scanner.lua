local _, NS = ...

NS.scannedToys = {}
NS.ownedToyIDs = {}

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

function NS.GetListByName(listName)
    for _, list in ipairs(NS.db.lists) do
        if list.name == listName then
            return list
        end
    end
    return nil
end

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

function NS.GetListsContainingToy(toyID)
    wipe(listsBuffer)
    for _, list in ipairs(NS.db.lists) do
        if list.toyIDs[toyID] then
            table.insert(listsBuffer, list.name)
        end
    end
    return listsBuffer
end
