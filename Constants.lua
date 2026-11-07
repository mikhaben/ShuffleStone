local _, NS = ...

NS.MACRO_PREFIX = "SS: "
NS.MACRO_ALL_NAME = "SS: All"
NS.ALL_DISPLAY_NAME = "All Hearthstones"

function NS.MacroNameForList(listName)
    return NS.MACRO_PREFIX .. listName
end

NS.WINDOW_WIDTH = 420
NS.SECTION_GAP = 16
NS.ICON_SIZE = 40
NS.ICON_GAP = 6
NS.BADGE_SIZE = 14
NS.GRID_FALLBACK_WIDTH = 392
NS.TITLE_BAR_HEIGHT = 28
NS.PADDING = 10

NS.PICKER_COLS = 6
NS.PICKER_ICON_SIZE = 32
NS.PICKER_GAP = 5
NS.PICKER_PAD = 10
NS.PICKER_MIN_W = 150

NS.TEX_CHECKMARK = "Interface\\RaidFrame\\ReadyCheck-Ready"
NS.TEX_LOCK = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"
NS.TEX_REMOVE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
NS.TEX_ADD = "Interface\\PaperDollInfoFrame\\Character-Plus"
NS.TEX_SLOT_BORDER = "Interface\\Buttons\\UI-Quickslot2"
NS.TEX_HIGHLIGHT = "Interface\\Buttons\\ButtonHilight-Square"
NS.TEX_TRASH_NORMAL = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
NS.TEX_TRASH_HIGHLIGHT = "Interface\\Buttons\\UI-GroupLoot-Pass-Highlight"

NS.ICON_TEXCOORD = { 0.08, 0.92, 0.08, 0.92 }

NS.COLOR_GREEN = { 0.3, 1, 0.3 }
NS.COLOR_GREEN_DIM = { 0.3, 0.7, 0.3 }
NS.COLOR_GRAY = { 0.5, 0.5, 0.5 }
NS.COLOR_LABEL_GRAY = { 0.8, 0.8, 0.8 }
NS.COLOR_WHITE = { 1, 1, 1 }
NS.COLOR_YELLOW = { 1, 0.82, 0 }
NS.COLOR_RED = { 1, 0.3, 0.3 }
NS.COLOR_BLUE_INFO = { 0.27, 0.67, 1 }

function NS.IsDynamicIcon(listKey)
    if listKey == "__all__" then
        return NS.db and NS.db.dynamicIcon ~= false
    else
        local list = NS.GetListByName(listKey)
        return not list or list.dynamicIcon ~= false
    end
end

function NS.GetListIcon(listKey)
    if listKey == "__all__" then
        return NS.db.allIcon or NS.DEFAULT_ICON
    else
        local list = NS.GetListByName(listKey)
        return list and list.icon or NS.DEFAULT_ICON
    end
end

function NS.SetMacroIcon(listKey, icon)
    if InCombatLockdown() then return end
    local macroName = NS.macroNames[listKey]
    if not macroName then return end
    local macroID = GetMacroIndexByName(macroName)
    if macroID and macroID > 0 then
        EditMacro(macroID, macroName, icon)
    end
end
