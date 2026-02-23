--[[
    ShuffleStone - Hearthstone Toy Randomizer
    Constants.lua - Shared constants, textures, colors, helpers
]]--

local AddonName, NS = ...

-- Macro naming
NS.MACRO_PREFIX = "SS: "
NS.MACRO_ALL_NAME = "SS: All"

function NS.MacroNameForList(listName)
    return NS.MACRO_PREFIX .. listName
end

-- Layout
NS.WINDOW_WIDTH = 420
NS.WINDOW_HEIGHT = 480
NS.SECTION_GAP = 16
NS.ICON_SIZE = 40
NS.ICON_GAP = 6
NS.BADGE_SIZE = 14
NS.GRID_FALLBACK_WIDTH = 392 -- WINDOW_WIDTH - 28

-- Textures
NS.TEX_CHECKMARK = "Interface\\RaidFrame\\ReadyCheck-Ready"
NS.TEX_LOCK = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"
NS.TEX_REMOVE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
NS.TEX_ADD = "Interface\\PaperDollInfoFrame\\Character-Plus"
NS.TEX_SLOT_BORDER = "Interface\\Buttons\\UI-Quickslot2"
NS.TEX_HIGHLIGHT = "Interface\\Buttons\\ButtonHilight-Square"
NS.TEX_TRASH_NORMAL = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
NS.TEX_TRASH_HIGHLIGHT = "Interface\\Buttons\\UI-GroupLoot-Pass-Highlight"

-- Icon texture coordinate crop (trim edges)
NS.ICON_TEXCOORD = { 0.08, 0.92, 0.08, 0.92 }

-- Colors {r, g, b}
NS.COLOR_GREEN = { 0.3, 1, 0.3 }
NS.COLOR_GREEN_DIM = { 0.3, 0.7, 0.3 }
NS.COLOR_GRAY = { 0.5, 0.5, 0.5 }
NS.COLOR_LABEL_GRAY = { 0.8, 0.8, 0.8 }
NS.COLOR_WHITE = { 1, 1, 1 }
NS.COLOR_YELLOW = { 1, 0.82, 0 }
NS.COLOR_RED = { 1, 0.3, 0.3 }
NS.COLOR_BLUE_INFO = { 0.27, 0.67, 1 }

-- Check if dynamic icon is enabled for a list key
function NS.IsDynamicIcon(listKey)
    if listKey == "__all__" then
        return NS.db and NS.db.dynamicIcon ~= false
    else
        local list = NS.GetListByName(listKey)
        return not list or list.dynamicIcon ~= false
    end
end

-- Set macro icon (combat-safe, no-op if in combat)
function NS.SetMacroIcon(listKey, icon)
    if InCombatLockdown() then return end
    local macroName = NS.macroNames[listKey]
    if not macroName then return end
    local macroID = GetMacroIndexByName(macroName)
    if macroID and macroID > 0 then
        EditMacro(macroID, macroName, icon)
    end
end
