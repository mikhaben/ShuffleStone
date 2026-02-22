--[[
    ShuffleStone - Hearthstone Toy Randomizer
    ToyEngine/Rotation.lua - No-repeat shuffle rotation per list
]]--

local AddonName, NS = ...

-- Pick next random toy for a list key ("__all__" or list name)
-- Returns toyID or nil if no toys available
function NS.PickNextToy(listKey)
    local db = NS.db
    if not db.rotationState[listKey] then
        db.rotationState[listKey] = { remaining = {}, lastUsed = nil }
    end

    local state = db.rotationState[listKey]
    local pool = NS.GetOwnedToysForList(listKey)

    if #pool == 0 then return nil end
    if #pool == 1 then
        state.lastUsed = pool[1]
        return pool[1]
    end

    -- Refill when empty
    if #state.remaining == 0 then
        for _, id in ipairs(pool) do
            table.insert(state.remaining, id)
        end
        -- Anti-repeat: avoid same toy at cycle boundary
        if state.remaining[1] == state.lastUsed then
            local swapIdx = math.random(2, #state.remaining)
            state.remaining[1], state.remaining[swapIdx] = state.remaining[swapIdx], state.remaining[1]
        end
    end

    -- Swap-and-pop for O(1) random removal
    local idx = math.random(1, #state.remaining)
    local toyID = state.remaining[idx]
    state.remaining[idx] = state.remaining[#state.remaining]
    state.remaining[#state.remaining] = nil

    state.lastUsed = toyID
    return toyID
end

function NS.ResetRotation(listKey)
    if NS.db.rotationState[listKey] then
        wipe(NS.db.rotationState[listKey].remaining)
    end
end

function NS.ResetAllRotations()
    wipe(NS.db.rotationState)
end
