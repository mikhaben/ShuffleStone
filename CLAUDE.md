# ShuffleStone - AI Assistant Reference Documentation

## Overview

ShuffleStone is a World of Warcraft addon that randomizes hearthstone toys using a shuffle-bag rotation algorithm. It provides an action bar macro that uses a different random hearthstone toy on each press from a selected list, with no repeats until all toys are exhausted. The addon features a custom floating UI window for managing hearthstone toy lists, selecting which list to use, and toggling toys on/off.

## Commands

- `/ss` or `/shufflestone` — Toggle the main window visibility
- `/ss debug` — Print debug info (owned toys, lists, macros, rotation state)

## Architecture Overview

ShuffleStone uses a modular architecture with six main components:

1. **Core System** (Core.lua) — Namespace initialization, SavedVariables management, event handling, slash commands
2. **Data Registry** (Data.lua) — Toy ID constants, spell IDs, toy metadata
3. **Constants Module** (Constants.lua) — Centralized UI constants, textures, colors, and shared helper functions
4. **Toy Engine** — Rotation algorithm, toy ownership scanning, secure button/macro creation
5. **UI System** — Floating window, settings panel, icon grid, list editor, dropdown selection
6. **Libraries** — LibStub and CallbackHandler for addon communication

## Project Structure

```
ShuffleStone/
├── ShuffleStone.toc          # TOC metadata: interface 120000, load order, author, version
├── Core.lua                  # Main namespace (NS), DB init, events, slash command handler
├── Data.lua                  # Toy registry (all hearthstones), toy IDs, spell IDs, metadata
├── Constants.lua             # Centralized UI constants, textures, colors, helper functions
├── ToyEngine/
│   ├── Scanner.lua           # PlayerHasToy scanning, C_ToyBox integration, owned toy detection
│   ├── Rotation.lua          # No-repeat shuffle-bag rotation with anti-repeat fix
│   └── Buttons.lua           # SecureActionButton creation, macro management, attribute binding
├── UI/
│   ├── IconGrid.lua          # Reusable icon grid, wrapping flow layout, pooling, buffers
│   ├── ListEditor.lua        # List editor row: macro icon, name edit, icon picker, delete
│   ├── MainFrame.lua         # Custom floating window, two-zone grid, dropdown, callbacks
│   └── Settings.lua          # Settings panel for addon configuration
├── Assets/
│   └── logo.tga              # Custom addon icon
├── Libs/
│   ├── LibStub/              # Stub library loader
│   │   └── LibStub.lua
│   └── CallbackHandler-1.0/  # Callback system for inter-addon communication
│       └── CallbackHandler-1.0.lua
└── build.sh                  # CurseForge build script (creates versioned zip)
```

## Configuration

### SavedVariables (ShuffleStoneDB)

The addon persists all state via SavedVariables with this structure:

```lua
ShuffleStoneDB = {
    lists = {
        {
            name = "All Hearthstones",
            icon = 134414,
            toyIDs = { 6948, 54452, 109739, ... }
        },
        {
            name = "Favorites",
            icon = 134414,
            toyIDs = { 6948, 54452 }
        }
    },
    rotationState = {
        ["__all__"] = {
            remaining = { 6948, 54452, 109739, ... },  -- Shuffle-bag state for "All Hearthstones"
            lastUsed = 54452
        },
        ["Favorites"] = {
            remaining = { 6948, 54452 },
            lastUsed = 6948
        }
    },
    windowPos = {
        point = "CENTER",
        x = 0,
        y = 0
    },
    showUnobtained = false,
    debugMode = false,
    onboardingDismissed = false
}
```

### TOC File (ShuffleStone.toc)

```
## Interface: 120000
## Title: ShuffleStone
## Notes: Randomize hearthstone toys with custom lists
## Author: justLuther
## Version: 1.0.2
## IconTexture: Interface\AddOns\ShuffleStone\Assets\logo
## SavedVariables: ShuffleStoneDB

# Libraries
Libs/LibStub/LibStub.lua
Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua

# Core
Data.lua
Constants.lua
Core.lua

# Toy Engine
ToyEngine/Scanner.lua
ToyEngine/Rotation.lua
ToyEngine/Buttons.lua

# UI
UI/IconGrid.lua
UI/ListEditor.lua
UI/MainFrame.lua
UI/Settings.lua
```

**Load Order:** Libraries → Data → Constants → Core → ToyEngine → UI

The Constants module must load after Data but before Core and all UI modules so that shared constants are available throughout the addon.

## Constants Module (Constants.lua)

Centralizes all shared constants to reduce duplication across modules. Loaded after Data.lua but before Core.lua to ensure availability throughout the addon.

### Macro Naming

```lua
NS.MACRO_PREFIX = "SS: "                    -- Macro name prefix
NS.MACRO_ALL_NAME = "SS: All"               -- Default "all hearthstones" macro name
NS.MacroNameForList(listName)               -- Returns "SS: " .. listName
```

### Layout Constants

```lua
NS.WINDOW_WIDTH = 420                       -- Main window width in pixels
NS.WINDOW_HEIGHT = 480                      -- Main window height in pixels
NS.SECTION_GAP = 16                         -- Gap between window zones in pixels
NS.ICON_SIZE = 40                           -- Individual icon button size
NS.ICON_GAP = 6                             -- Gap between icon buttons
NS.BADGE_SIZE = 14                          -- Size of checkmark/lock badges
NS.GRID_FALLBACK_WIDTH = 392                -- Fallback grid width (WINDOW_WIDTH - 28)
```

### Texture Constants

```lua
NS.TEX_CHECKMARK = "Interface\\RaidFrame\\ReadyCheck-Ready"
NS.TEX_LOCK = "Interface\\LFGFrame\\UI-LFG-ICON-LOCK"
NS.TEX_REMOVE = "Interface\\RaidFrame\\ReadyCheck-NotReady"
NS.TEX_ADD = "Interface\\PaperDollInfoFrame\\Character-Plus"
NS.TEX_SLOT_BORDER = "Interface\\Buttons\\UI-Quickslot2"
NS.TEX_HIGHLIGHT = "Interface\\Buttons\\ButtonHilight-Square"
NS.TEX_TRASH_NORMAL = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
NS.TEX_TRASH_HIGHLIGHT = "Interface\\Buttons\\UI-GroupLoot-Pass-Highlight"
NS.ICON_TEXCOORD = { 0.08, 0.92, 0.08, 0.92 }  -- Texture coordinate crop
```

### Color Constants

```lua
NS.COLOR_GREEN = { 0.3, 1, 0.3 }            -- Bright green for checkmarks
NS.COLOR_GREEN_DIM = { 0.3, 0.7, 0.3 }      -- Dimmed green
NS.COLOR_GRAY = { 0.5, 0.5, 0.5 }           -- Neutral gray
NS.COLOR_LABEL_GRAY = { 0.8, 0.8, 0.8 }     -- Light gray for labels
NS.COLOR_WHITE = { 1, 1, 1 }                -- White
NS.COLOR_YELLOW = { 1, 0.82, 0 }            -- Bright yellow
NS.COLOR_RED = { 1, 0.3, 0.3 }              -- Error red
NS.COLOR_BLUE_INFO = { 0.27, 0.67, 1 }      -- Info blue
```

### Helper Functions

**`NS.IsDynamicIcon(listKey)`** — Check if a list uses dynamic icon display
- For "__all__": Returns NS.db.dynamicIcon (default true)
- For named lists: Returns list.dynamicIcon (default true)
- Used to determine if macro icon changes when list contents change

**`NS.SetMacroIcon(listKey, icon)`** — Update macro icon (combat-safe)
- No-op if in combat (InCombatLockdown)
- Looks up macro by listKey, calls EditMacro with new icon
- Used when list icon is changed or toys are added/removed

## Key Constants (Data.lua)

```lua
NS.DEFAULT_ICON = 134414                    -- Hearthstone icon texture ID
NS.BASE_HEARTHSTONE_ID = 6948               -- Original hearthstone toy ID
NS.HEARTHSTONE_SPELL_ID = 8690              -- Hearthstone spell ID (used for UNIT_SPELLCAST_SUCCEEDED)
```

The addon supports all HOME hearthstone toys (no Dalaran/Garrison variants). The list is maintained in Data.lua and updated as new hearthstones are added to the game.

### Toy Registry Structure

Each toy entry in the registry contains:
```lua
{
    toyID = 6948,                           -- Unique toy ID from WoW
    spellID = 8690,                         -- Associated spell ID for casting
    name = "Hearthstone"                    -- Display name
}
```

## Core Module (Core.lua)

### Namespace & Initialization

```lua
ShuffleStone = {}
local NS = ShuffleStone
```

The namespace holds all global state and is used throughout the addon.

### SavedVariables Initialization

On first load, Core.lua initializes ShuffleStoneDB with defaults:
- Empty lists table (populated on first scan)
- Empty rotationState table
- Default window position at screen center
- showUnobtained = false
- debugMode = false
- onboardingDismissed = false

### Event Handlers

**ADDON_LOADED** — Triggers SavedVariables migration and initial toy scan
**NEW_TOY_ADDED** — Dynamic rescan when player obtains a new toy
**UNIT_SPELLCAST_SUCCEEDED** — Handled by Rotation.lua to advance rotation after successful cast

### Slash Commands

```lua
SLASH_SHUFFLESTONE1 = "/ss"
SLASH_SHUFFLESTONE2 = "/shufflestone"
```

Handler switches on subcommand:
- No args: Toggle window
- "debug": Print debug info dump (owned toys, lists, macros, rotation state)

### Debug Info (`/ss debug`)

Prints a diagnostic dump to chat:
- Addon version
- Owned hearthstone count
- Custom list details (name, toy count, owned count)
- Macro status (OK or MISSING for each)
- Secure button count
- Rotation state per list (remaining count, lastUsed)

## Data Module (Data.lua)

Defines the complete registry of all supported HOME hearthstones with toy IDs and item names. Each entry is used by Scanner.lua to validate toy ownership and by Rotation.lua to manage toy pools.

Example entries:
```lua
{
    toyID = 6948,        -- Original hearthstone
    spellID = 8690,
    name = "Hearthstone"
}
{
    toyID = 54452,       -- Eternal Fire
    spellID = 74948,
    name = "Eternal Fire"
}
```

Exports core toy system constants:
- DEFAULT_ICON (hearthstone texture ID for UI)
- BASE_HEARTHSTONE_ID (original toy ID)
- HEARTHSTONE_SPELL_ID (spell ID for rotation tracking)
- HEARTHSTONE_TOYS (master toy registry table)

## Toy Engine

### Scanner (ToyEngine/Scanner.lua)

Scans the player's toy box inventory to determine which hearthstones are obtainable.

**Key Functions:**

- `NS.Scanner:ScanHearthstones()` — Returns table of {toyID, toyID, ...} for owned toys
  - Uses `PlayerHasToy()` for quick ownership check
  - Falls back to `C_ToyBox.IsToyUsable()` for validation
  - Called on ADDON_LOADED and NEW_TOY_ADDED

- `NS.Scanner:GetToyInfo(toyID)` — Wrapper around C_ToyBox.GetToyInfo()
  - Returns name, icon, and usability status

The scanner supports both pre-Shadowlands (PlayerHasToy) and modern (C_ToyBox) APIs.

### Rotation (ToyEngine/Rotation.lua)

Implements the shuffle-bag rotation algorithm for no-repeat toy selection with anti-repeat safeguards.

**Key Functions:**

- `NS.PickNextToy(listKey)` — Returns next toy ID using shuffle-bag algorithm
  - listKey is "__all__" or a list name
  - Returns nil if no toys available
  - Returns single toy immediately if pool has only 1 toy
  - Refills rotation pool from owned toys when empty
  - Applies anti-repeat: moves lastUsed to end of array to exclude it from next pick
  - Performs swap-and-pop: removes selected toy, updates remaining in-place
  - Updates lastUsed for next cycle refill

- `NS.ResetRotation(listKey)` — Clears remaining toys for a list (used when list contents change)

- `NS.ResetAllRotations()` — Wipes all rotation state (used on fresh scans)

**Anti-Repeat Fix (Production Readiness):**

After cycle refill, lastUsed is now correctly placed at the END of the remaining array, then excluded from the random pick range via `pickMax = #state.remaining - 1`. This prevents immediate repetition when cycling back to previously used toys.

```lua
-- During refill: move lastUsed to end
if state.lastUsed and #state.remaining > 1 then
    for i, id in ipairs(state.remaining) do
        if id == state.lastUsed then
            state.remaining[i] = state.remaining[#state.remaining]
            state.remaining[#state.remaining] = id
            break
        end
    end
end

-- During pick: exclude last element if it matches lastUsed
local pickMax = #state.remaining
if pickMax > 1 and state.remaining[pickMax] == state.lastUsed then
    pickMax = pickMax - 1
end
local idx = math.random(1, pickMax)
```

**Pre-Selection Pattern:**

The addon uses a two-step pattern to avoid double-consuming rotation entries:
1. Before click: Toy ID pre-selected into SecureActionButton attribute
2. After cast: Next toy queued into attribute for future click

This prevents the "PreClick" handler from advancing rotation before confirming the cast succeeded.

### Buttons (ToyEngine/Buttons.lua)

Creates and manages SecureActionButton instances and macros for each custom list.

**Key Functions:**

- `NS.Buttons:CreateButton(listKey, toyID)` — Creates SecureActionButton with toy type
  - Sets button:SetAttribute("type", "toy")
  - Sets button:SetAttribute("toy", toyID)
  - Registers for secure updates
  - Uses pooling to reuse buttons across list switches
  - Returns button for icon/texture retrieval

- `NS.Buttons:CreateMacro(listKey, icon)` — Creates WoW macro linked to toy button
  - Macro name = NS.MacroNameForList(listKey) (from Constants.lua)
  - Uses CreateMacro() API with icon texture
  - Stores macro name in NS.macroNames[listKey]
  - Returns macro name for action bar dragging

- `NS.Buttons:UpdateButtonToy(listKey, toyID)` — Changes toy on existing button
  - Calls button:SetAttribute("toy", toyID) to update
  - Pre-selects new toy for next press
  - Updates macro icon via NS.SetMacroIcon if dynamic icon enabled

- `NS.Buttons:DeleteMacro(macroName)` — Cleans up macro on list deletion
  - Uses DeleteMacro() API
  - Validates macro exists via GetMacroIndexByName first

**Button Pooling & Validation (Memory Optimization):**

Buttons maintains a pool of SecureActionButton instances reused across list switches. Validation uses an in-place filtering pattern with reusable validatePoolSet buffer to minimize allocations.

**Macro Naming Convention:**

All macros are named with prefix "SS: " (NS.MACRO_PREFIX) for easy identification:
- "__all__" list → "SS: All"
- "Favorites" list → "SS: Favorites"
- "Raid Night" list → "SS: Raid Night"

The button hybrid approach avoids the 255-character macro limit by using SecureActionButton attributes instead of embedding toy IDs in macro text.

## UI System

### Icon Grid (UI/IconGrid.lua)

Reusable component for displaying hearthstone icons in a wrapping grid layout.

**Key Functions:**

- `NS.IconGrid:Create(parent)` — Builds icon grid container
  - Uses NS.WINDOW_WIDTH and NS.GRID_FALLBACK_WIDTH from Constants.lua
  - Pre-allocates 40 icon buttons (pooling pattern for reuse)
  - Returns grid table with methods
  - Sets up texture coordinates using NS.ICON_TEXCOORD

- `grid:Populate(toyIDs, selectedToys, onClickFn)` — Populates grid with toy icons
  - Shows first len(toyIDs) buttons, hides rest
  - Marks selected toys with checkmark badge using NS.TEX_CHECKMARK
  - Marks unobtained toys with lock badge using NS.TEX_LOCK
  - Attaches click handler to each button
  - Queries C_ToyBox.GetToyInfo() for icons and tooltips

- `grid:Refresh()` — Updates icon display (e.g., when ownership changes)
  - Recalculates grid dimensions using icon size and gap from Constants
  - Re-applies icons, badges, and click handlers
  - Uses pre-allocated ownedToysBuffer to avoid allocations

**Icon Button Pool:**

40 buttons are pre-created and reused:
- Buttons 1..numRequired are shown with NS.ICON_SIZE and NS.ICON_GAP spacing
- Buttons numRequired+1..40 are hidden
- No buttons are destroyed or created after initialization
- Hover state managed via GameTooltip
- Icon size (NS.ICON_SIZE = 40) and badge size (NS.BADGE_SIZE = 14) from Constants.lua

**Zero-Allocation Pattern:**

Grid operations use pre-allocated buffer tables (ownedToysBuffer, listsBuffer, topToysBuffer) instead of creating new tables on each call. This reduces garbage collection pressure during the 40 icon button refresh loop.

### List Editor (UI/ListEditor.lua)

Row component for managing a single list within the editor. Uses Constants.lua for colors, textures, and sizing.

**Components (left to right):**

1. **Macro Icon** (draggable) — Drag to action bar; visual indicator of macro with border (NS.TEX_SLOT_BORDER)
2. **List Name** — Editable text field (FontString in edit mode) with light gray label (NS.COLOR_LABEL_GRAY)
3. **Change Icon Button** — Opens icon picker to customize hearthstone icon texture
4. **Delete Button** — Removes list with confirmation using trash icons (NS.TEX_TRASH_NORMAL/HIGHLIGHT)

**Key Functions:**

- `NS.ListEditor:CreateRow(parent, list)` — Creates styled row with BackdropTemplate
  - Uses NS.SECTION_GAP, NS.ICON_SIZE, NS.COLOR_* constants from Constants.lua
  - Returns row table with methods

- `row:UpdateMacroIcon()` — Fetches macro icon and updates display
  - Queries GetMacroInfo() by macro name (from NS.macroNames)
  - Updates texture from macro data
  - Uses NS.ICON_TEXCOORD for texture coordinates

- `row:RenameList(newName)` — Renames list
  - Validates name not in use
  - Saves rotation state before destroying old macro
  - Creates new macro using NS.MacroNameForList(newName)
  - Updates list metadata in DB

- `row:DeleteList()` — Removes list
  - Deletes associated macro
  - Removes from lists table
  - Triggers UI refresh callback

**Design Pattern:**

All destructive operations check `InCombatLockdown()` to prevent macro/button changes during combat. If called during combat, operation is queued for PLAYER_REGEN_ENABLED event.

### Main Frame (UI/MainFrame.lua)

Custom floating window with all UI components integrated. Uses Constants.lua for layout, textures, and colors.

**Components:**

1. **Header Bar** — Title "ShuffleStone" with close button, sized NS.WINDOW_WIDTH × NS.WINDOW_HEIGHT
2. **List Dropdown** — UIDropDownMenuTemplate for list selection
3. **Zone 1: Toy Grid** — Icon grid showing toys in current list (NS.IconGrid)
4. **Show Unobtained Checkbox** — Filters owned vs all toys (NS.COLOR_LABEL_GRAY text)
5. **Zone 2: Editor Grid** — List editor rows (scrollable, NS.SECTION_GAP spacing)
6. **Add List Button** — Creates new list with plus icon (NS.TEX_ADD)

**Key Functions:**

- `NS.MainFrame:Create()` — Builds main window
  - Uses BasicFrameTemplateWithInset with custom inset texture from Assets/logo
  - Applies WindowResizingTemplate for resizing capability
  - Creates grid layout with two zones separated by NS.SECTION_GAP
  - Sets initial position from SavedVariables windowPos
  - Returns frame for event binding

- `NS.GetSelectedListKey()` / `NS.SetSelectedListKey(key)` — Getter/setter for active list key
  - Exposes selectedListKey state for global access
  - Key is "__all__" or a list name

- `frame:SelectList(listKey)` — Switches active list
  - Updates dropdown display via mainFrame.dropdown:SetText()
  - Refreshes toy grid with new list's toys and selected badges
  - Updates rotation state display

- `frame:AddToyToList(toyID)` — Adds toy to current list
  - Updates rotationState (resets shuffle bag via NS.ResetRotation)
  - Refreshes grid display
  - Updates macro via NS.SetMacroIcon if dynamic icon enabled

- `frame:RemoveToyFromList(toyID)` — Removes toy
  - Resets rotation state for affected list
  - Updates grid display
  - Updates macro via NS.SetMacroIcon

- `frame:SetListIcon(newIcon)` — Changes list's hearthstone icon
  - Updates macro display via NS.SetMacroIcon
  - Persists to SavedVariables

**Global Frame Reference Fix (Production Readiness):**

Fixed reference from `ShuffleStoneListDropdown:SetText()` to `mainFrame.dropdown:SetText()` to use correct frame handle and avoid global namespace pollution.

**Callback Integration:**

Frame registers with CallbackHandler to receive toy/list change events:
- When list is renamed, grid title and macro name update
- When toy is added/removed, grid refreshes and rotation resets
- When list is deleted, dropdown updates and switches to "__all__" list

**Memory Optimization:**

Uses reusable buffer tables (dropdownBuffer, iconCycleBuffer) for dropdown and icon cycle operations to avoid allocations during frequent list switches.

### Settings Panel (UI/Settings.lua)

Configuration interface for addon settings, accessible via /ss settings or integrated addon menu.

**Configuration Options:**

- **Debug Mode** — Toggle verbose logging (saved to NS.db.debugMode)
- **Dynamic Icon** — Toggle whether macro icons update when list contents change (saved to NS.db.dynamicIcon)
- **Show Unobtained** — Toggle display of toys player doesn't own (saved to NS.db.showUnobtained)

**Design:**

Settings are persisted to ShuffleStoneDB SavedVariables and can be modified in-game without UI reload.

## Key Design Decisions

### No-Repeat Rotation (Shuffle-Bag Algorithm)

Uses swap-and-pop to avoid repeating toys until all are cycled:
```lua
function Rotation:PickToy(listName)
    local state = self.rotationState[listName]
    if #state.remaining == 0 then
        state.remaining = self:CopyList(list.toyIDs)
    end
    local idx = math.random(1, #state.remaining)
    local toy = state.remaining[idx]
    state.remaining[idx] = state.remaining[#state.remaining]
    table.remove(state.remaining)
    state.lastUsed = toy
    return toy
end
```

### Pre-Selection Pattern (No PreClick Handler)

Originally used PreClick handler on SecureActionButton to select toys, but this caused double-consumption of rotation entries. Current pattern:
1. Button has toy ID baked into attribute from previous click
2. After successful UNIT_SPELLCAST_SUCCEEDED, next toy is pre-loaded into attribute
3. Next click uses pre-loaded toy without triggering PreClick handler

This ensures rotation advances exactly once per successful cast.

### Centralized List Lookup

`GetListByName(name)` is used throughout to avoid duplicated linear searches through the lists table. This is especially important during dropdown population and list operations.

### Reusable Buffer Tables (Memory Optimization)

Operations use pre-allocated buffer tables to avoid garbage collection during gameplay:
- **IconGrid**: ownedToysBuffer, listsBuffer, topToysBuffer for icon refresh loops
- **Scanner**: ownedToysBuffer for toy ownership scans
- **MainFrame**: dropdownBuffer, iconCycleBuffer for dropdown and icon operations
- **Buttons**: validatePoolSet for in-place button pool validation

These reusable buffers are wiped and refilled instead of allocating new tables on each call, reducing GC pressure during the 40 icon button refresh loop and frequent list selections.

### Combat Safety

All destructive UI operations (macro creation, button updates, list deletion) are guarded with `InCombatLockdown()` checks. If called during combat, the operation is queued for the next PLAYER_REGEN_ENABLED event.

### No External Libraries for UI

Deliberately avoids AceGUI and AceConfig libraries. Instead uses raw WoW frame templates:
- BasicFrameTemplateWithInset for window chrome
- UIDropDownMenuTemplate for dropdown (standard WoW component)
- UIPanelScrollFrameTemplate for scrollable lists
- BackdropTemplate for styled editor rows
- SecureActionButtonTemplate for combat-safe buttons

This keeps the addon lightweight and removes the UI dependency chain.

## Dependencies

### WoW APIs Used

**Toy System:**
- `PlayerHasToy(toyID)` — Check if player owns toy (pre-Shadowlands)
- `C_ToyBox.IsToyUsable(toyID)` — Check if toy is usable
- `C_ToyBox.GetToyInfo(toyID)` — Fetch toy name, icon, and metadata
- `C_ToyBox.PickupToyBoxItem(toyID)` — Prepare toy for use

**Macro System:**
- `CreateMacro(name, icon, body, noReplace)` — Create new macro
- `EditMacro(index, name, icon, body, noReplace)` — Edit existing macro
- `DeleteMacro(index)` — Delete macro by index
- `GetMacroIndexByName(name)` — Find macro by name
- `PickupMacro(index)` — Prepare macro for action bar drag

**Events:**
- `ADDON_LOADED` — Addon initialized
- `NEW_TOY_ADDED` — Player obtained new toy
- `UNIT_SPELLCAST_SUCCEEDED` — Spell cast completed (toy ID 8690)
- `PLAYER_REGEN_ENABLED` — Exited combat (for queued operations)

**Secure System:**
- `SecureActionButtonTemplate` — Combat-safe button for toys
- `button:SetAttribute(key, value)` — Set button attributes
- `InCombatLockdown()` — Check if in combat

**UI Tooltips:**
- `GameTooltip:SetToyByItemID(toyID)` — Show toy info
- `GameTooltip:SetItemByID(itemID)` — Show item info (for hearthstone items)

### Libraries

- **LibStub** — Addon library loader (minimal, no-op if already loaded)
- **CallbackHandler-1.0** — Event system for inter-UI component communication

These libraries are embedded in the Libs folder and loaded first in the TOC.

## Version

- **Current Version:** 1.0.2
- **WoW Interface:** 120000 (Midnight)
- **Author:** justLuther
- **Custom Icon:** Assets/logo.tga

## Build Process

```bash
./build.sh
```

Creates `build/ShuffleStone_<version>_<date>.zip` suitable for CurseForge upload. The script:
1. Reads version from ShuffleStone.toc
2. Generates timestamp
3. Copies all core files (Data.lua, Constants.lua, Core.lua, etc.)
4. Copies Assets/ directory (logo.tga)
5. Includes Libs/ folder
6. Zips all addon files (excluding build directory, .git, etc.)
7. Names output file with version and date

## Related Files

- **.toc** — Addon manifest and load order
- **SavedVariables** — ShuffleStoneDB and ShuffleStoneCharDB
- **Macro Storage** — WoW stores created macros in WTF\Account\<name>\SavedVariables\

## Common Patterns

### Checking Toy Ownership

```lua
if PlayerHasToy(toyID) then
    -- Player owns toy
end

if C_ToyBox.IsToyUsable(toyID) then
    -- Toy is usable (accounts for learned/unlearned state)
end
```

### Updating List State

When list contents change, always reset rotation:
```lua
list.toyIDs[toyID] = true
NS.Rotation:ResetRotation(listName)
NS.MainFrame:RefreshGrid()
```

### Combat-Safe Operations

```lua
if InCombatLockdown() then
    -- Queue for PLAYER_REGEN_ENABLED
    NS.pendingOps = NS.pendingOps or {}
    table.insert(NS.pendingOps, function)
else
    -- Safe to modify macros/buttons
    NS.Buttons:CreateMacro(...)
end
```

### Avoiding GC Pressure

```lua
-- Pre-allocate buffers
local listsBuffer = {}

-- Reuse in loops
for i, list in ipairs(NS.db.lists) do
    listsBuffer[i] = list.toyIDs
end
```

## File Dependency Graph

```
ShuffleStone.toc
    ↓
Libs/LibStub/LibStub.lua
Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua
    ↓
Data.lua (toy registry, toy system constants)
    ↓
Constants.lua (UI constants, textures, colors, helpers)
    ↓
Core.lua (namespace, SavedVariables, events)
    ↓
ToyEngine/
    Scanner.lua (depends on Data, Core; uses ownedToysBuffer)
    Rotation.lua (depends on Core; implements PickNextToy)
    Buttons.lua (depends on Core, Constants; macro naming, macro icons)
    ↓
UI/
    IconGrid.lua (depends on Core, Constants; layout/texture constants)
    ListEditor.lua (depends on Core, Constants, Buttons; row rendering)
    MainFrame.lua (depends on IconGrid, ListEditor, Rotation, Scanner, Buttons, Constants)
    Settings.lua (depends on Core, Constants; settings panel)
```

**Load Order Invariants:**
- Constants.lua must load after Data.lua but before Core.lua
- All UI modules must load after ToyEngine modules (they depend on Rotation, Scanner, Buttons)
- Settings.lua loads last as optional configuration UI

## Troubleshooting Notes

### Toy Not Using

If a toy doesn't consume from rotation:
1. Check UNIT_SPELLCAST_SUCCEEDED is firing (enable /ss debug)
2. Verify toy spell ID matches HEARTHSTONE_SPELL_ID in Data.lua
3. Check rotationState[listName] is not nil (try `/reload`)

### Macro Not Dragging

If macro icon can't drag to action bar:
1. Verify macro exists via GetMacroIndexByName()
2. Check macro icon texture is valid (should match list.icon)
3. Ensure not in combat (InCombatLockdown())

### List Not Persisting

If custom lists disappear on reload:
1. Check ShuffleStoneDB in SavedVariables file
2. Verify SavedVariables declaration in TOC
3. Try `/reload` to force rescan and list rebuild
