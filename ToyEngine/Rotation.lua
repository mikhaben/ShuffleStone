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
        -- Anti-repeat: move lastUsed to end so it's excluded from next pick
        if state.lastUsed and #state.remaining > 1 then
            local found = false
            for i, id in ipairs(state.remaining) do
                if id == state.lastUsed then
                    state.remaining[i] = state.remaining[#state.remaining]
                    state.remaining[#state.remaining] = id
                    found = true
                    break
                end
            end
            if not found then
                state.lastUsed = nil
            end
        end
    end

    -- Swap-and-pop: exclude last element if it matches lastUsed (anti-repeat)
    local pickMax = #state.remaining
    if pickMax > 1 and state.remaining[pickMax] == state.lastUsed then
        pickMax = pickMax - 1
    end
    local idx = math.random(1, pickMax)
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
