# ShuffleStone - AI Assistant Reference Documentation

## Overview

ShuffleStone is a World of Warcraft addon that randomizes hearthstone toys using a shuffle-bag rotation algorithm. It provides an action bar macro that uses a different random hearthstone toy on each press from a selected list, with no repeats until all toys are exhausted. The addon features a custom floating UI window for managing hearthstone toy lists, selecting which list to use, and toggling toys on/off.

## Commands

- `/ss` or `/shufflestone` — Toggle the main window visibility
- `/ss debug` — Toggle debug mode for verbose logging
- `/ss scan` — Force rescan of toy ownership from the toy box

## Architecture Overview

ShuffleStone uses a modular architecture with five main components:

1. **Core System** (Core.lua) — Namespace initialization, SavedVariables management, event handling, slash commands
2. **Data Registry** (Data.lua) — Toy ID constants, default icon IDs, shared configuration
3. **Toy Engine** — Rotation algorithm, toy ownership scanning, secure button/macro creation
4. **UI System** — Floating window, icon grid, list editor, dropdown selection
5. **Libraries** — LibStub and CallbackHandler for addon communication

## Project Structure

```
ShuffleStone/
├── ShuffleStone.toc          # TOC metadata file: interface version 120100, load order
├── Core.lua                  # Main namespace (NS), DB init, events, slash command handler
├── Data.lua                  # Toy registry (32 items), constant definitions (icons, IDs)
├── ToyEngine/
│   ├── Scanner.lua           # PlayerHasToy scanning, C_ToyBox integration, ownership tracking
│   ├── Rotation.lua          # Shuffle-bag rotation engine, UNIT_SPELLCAST_SUCCEEDED handler
│   └── Buttons.lua           # SecureActionButton creation, macro management, attribute binding
├── UI/
│   ├── IconGrid.lua          # Reusable icon grid component, wrapping flow layout, pooling
│   ├── ListEditor.lua        # List editor row: macro icon, name edit, icon picker, delete
│   └── MainFrame.lua         # Custom floating window, two-zone grid, dropdown, callbacks
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
            toyIDs = { 6948, 54452, 109739, ... }  -- 32 total possible
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
## Interface: 120100
## Title: ShuffleStone
## Version: 1.0.0
## Author: asp1d
## SavedVariables: ShuffleStoneDB
## SavedVariablesPerCharacter: ShuffleStoneCharDB

Libs/LibStub/LibStub.lua
Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua
Data.lua
Core.lua
ToyEngine/Scanner.lua
ToyEngine/Rotation.lua
ToyEngine/Buttons.lua
UI/IconGrid.lua
UI/ListEditor.lua
UI/MainFrame.lua
```

## Key Constants (Data.lua)

```lua
NS.DEFAULT_ICON = 134414                    -- Hearthstone icon texture ID
NS.BASE_HEARTHSTONE_ID = 6948               -- Original hearthstone toy ID
NS.HEARTHSTONE_SPELL_ID = 8690              -- Hearthstone spell (used for UNIT_SPELLCAST_SUCCEEDED)
NS.GRID_COLUMNS = 5                         -- Icon grid layout width
NS.ICON_SIZE = 40                           -- Individual icon button size
NS.ICON_POOL_SIZE = 40                      -- Pre-allocated icon button pool
NS.MAX_HEARTHSTONES = 32                    -- Maximum supported hearthstone toys
```

The addon supports exactly 32 hearthstone toys (HOME hearthstones only, no Dalaran/Garrison variants).

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
- "debug": Toggle debug mode
- "scan": Force toy scan

### Debug Logging

When debugMode is true, the addon logs:
- List operations (create, rename, delete)
- Toy additions/removals
- Rotation state changes
- Macro creation/deletion

## Data Module (Data.lua)

Defines the complete registry of 32 supported HOME hearthstones with toy IDs, spell IDs, and item names.

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

Also exports shared constants used throughout the codebase:
- DEFAULT_ICON (hearthstone texture ID)
- BASE_HEARTHSTONE_ID
- HEARTHSTONE_SPELL_ID

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

Implements the shuffle-bag rotation algorithm for no-repeat toy selection.

**Key Functions:**

- `NS.Rotation:PickToy(listName)` — Returns next toy ID using shuffle-bag algorithm
  - If remaining list is empty, resets with all toys from the list
  - Performs swap-and-pop: moves selected toy to end, removes it
  - Updates rotationState[listName].remaining in-place
  - Stores lastUsed for UI feedback

- `NS.Rotation:GetRotationState(listName)` — Returns current {remaining, lastUsed} for UI

- `NS.Rotation:ResetRotation(listName)` — Clears rotation state for a list (used when list contents change)

**UNIT_SPELLCAST_SUCCEEDED Handler:**

Listens for spell ID 8690 (hearthstone) and advances rotation:
1. Confirms successful cast via UNIT_SPELLCAST_SUCCEEDED
2. Updates rotation state to mark toy as used
3. Pre-selects next toy into button attribute for next press

**Pre-Selection Pattern:**

The addon uses a two-step pattern to avoid double-consuming rotation entries:
1. Before click: Toy ID pre-selected into SecureActionButton attribute
2. After cast: Next toy queued into attribute for future click

This prevents the "PreClick" handler from advancing rotation before confirming the cast succeeded.

### Buttons (ToyEngine/Buttons.lua)

Creates and manages SecureActionButton instances for each custom list.

**Key Functions:**

- `NS.Buttons:CreateButton(macroName, toyID)` — Creates SecureActionButton with toy type
  - Sets button:SetAttribute("type", "toy")
  - Sets button:SetAttribute("toy", toyID)
  - Registers for secure updates
  - Returns button for macro icon retrieval

- `NS.Buttons:CreateMacro(listName, icon)` — Creates WoW macro linked to toy button
  - Uses CreateMacro() API
  - Stores macro name in list metadata
  - Returns macro name for action bar dragging

- `NS.Buttons:UpdateButtonToy(macroName, toyID)` — Changes toy on existing button
  - Calls button:SetAttribute("toy", toyID) to update
  - Pre-selects new toy for next press

- `NS.Buttons:DeleteMacro(macroName)` — Cleans up macro on list deletion
  - Uses DeleteMacro() API
  - Validates macro exists first

The button hybrid approach avoids the 255-character macro limit by using SecureActionButton attributes instead of embedding toy IDs in macro text.

## UI System

### Icon Grid (UI/IconGrid.lua)

Reusable component for displaying icons in a wrapping grid layout.

**Key Functions:**

- `NS.IconGrid:Create(parent, numColumns, iconSize, numIcons)` — Builds icon grid container
  - Pre-allocates numIcons buttons (pooling pattern)
  - Returns grid table with methods

- `grid:Populate(toyIDs, onClickFn)` — Populates grid with toy icons
  - Shows first len(toyIDs) buttons, hides rest
  - Attaches click handler to each button
  - Queries C_ToyBox.GetToyInfo() for icons and tooltips

- `grid:Refresh()` — Updates icon display (e.g., when ownership changes)
  - Recalculates grid dimensions
  - Re-applies icons and click handlers

**Icon Button Pool:**

40 buttons are pre-created and reused:
- Buttons 1..numRequired are shown
- Buttons numRequired+1..40 are hidden
- No buttons are destroyed or created after initialization
- Hover state managed via GameTooltip

**Zero-Allocation Pattern:**

Grid refresh uses pre-allocated buffer tables (topToysBuffer, listsBuffer) to avoid garbage collection pauses during gameplay.

### List Editor (UI/ListEditor.lua)

Row component for managing a single list within the editor.

**Components (left to right):**

1. **Macro Icon** (draggable) — Drag to action bar; visual indicator of macro
2. **List Name** — Editable text field (FontString in edit mode)
3. **Change Icon Button** — Opens icon picker dialog
4. **Delete Button** — Removes list with confirmation

**Key Functions:**

- `NS.ListEditor:CreateRow(parent, list)` — Creates styled row with BackdropTemplate
  - Returns row table with methods

- `row:UpdateMacroIcon()` — Fetches macro icon and updates display
  - Queries GetMacroInfo() by macro name
  - Updates texture

- `row:RenameList(newName)` — Renames list
  - Validates name not in use
  - Saves rotation state before destroying old macro
  - Creates new macro with updated name
  - Updates list metadata

- `row:DeleteList()` — Removes list
  - Deletes associated macro
  - Removes from lists table
  - Triggers UI refresh

**Design Pattern:**

All destructive operations check `InCombatLockdown()` to prevent macro/button changes during combat.

### Main Frame (UI/MainFrame.lua)

Custom floating window with all UI components integrated.

**Components:**

1. **Header Bar** — Title "ShuffleStone" with close button
2. **List Dropdown** — UIDropDownMenuTemplate for list selection
3. **Zone 1: Toy Grid** — Icon grid showing toys in current list
4. **Show Unobtained Checkbox** — Filters owned vs all toys
5. **Zone 2: Editor Grid** — List editor rows (scrollable)
6. **Add List Button** — Creates new list with default settings

**Key Functions:**

- `NS.MainFrame:Create()` — Builds main window
  - Uses BasicFrameTemplateWithInset
  - Applies WindowResizingTemplate
  - Creates grid layout with two zones
  - Returns frame for event binding

- `frame:SelectList(listName)` — Switches active list
  - Updates dropdown display
  - Refreshes toy grid with new list's toys
  - Updates rotation state display

- `frame:AddToyToList(toyID)` — Adds toy to current list
  - Updates rotationState (resets shuffle bag)
  - Refreshes grid display

- `frame:RemoveToyFromList(toyID)` — Removes toy
  - Resets rotation state for affected list
  - Updates grid

- `frame:SetListIcon(newIcon)` — Changes list's hearthstone icon
  - Updates macro display
  - Persists to SavedVariables

**Callback Integration:**

Frame registers with CallbackHandler to receive toy/list change events:
- When list is renamed, grid title updates
- When toy is added/removed, grid refreshes
- When list is deleted, dropdown updates and switches to default

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

### Reusable Buffer Tables

Operations like icon grid refresh use pre-allocated tables (listsBuffer, topToysBuffer) instead of creating new tables on each call. This reduces garbage collection pressure during the 40 icon button refresh loop.

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

- **Current Version:** 1.0.0
- **WoW Interface:** 120100 (The War Within)
- **Author:** asp1d

## Build Process

```bash
./build.sh
```

Creates `build/ShuffleStone_<version>_<date>.zip` suitable for CurseForge upload. The script:
1. Reads version from ShuffleStone.toc
2. Generates timestamp
3. Zips all addon files (excluding build directory, .git, etc.)
4. Names output file with version and date

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
Data.lua (constants, toy registry)
    ↓
Core.lua (namespace, SavedVariables, events)
    ↓
ToyEngine/
    Scanner.lua (depends on Data, Core)
    Rotation.lua (depends on Data, Core)
    Buttons.lua (depends on Core)
    ↓
UI/
    IconGrid.lua (depends on Core)
    ListEditor.lua (depends on Core, Buttons)
    MainFrame.lua (depends on IconGrid, ListEditor, Rotation, Scanner, Buttons)
```

## Troubleshooting Notes

### Toy Not Using

If a toy doesn't consume from rotation:
1. Check UNIT_SPELLCAST_SUCCEEDED is firing (enable /ss debug)
2. Verify toy spell ID matches HEARTHSTONE_SPELL_ID in Data.lua
3. Check rotationState[listName] is not nil (run /ss scan)

### Macro Not Dragging

If macro icon can't drag to action bar:
1. Verify macro exists via GetMacroIndexByName()
2. Check macro icon texture is valid (should match list.icon)
3. Ensure not in combat (InCombatLockdown())

### List Not Persisting

If custom lists disappear on reload:
1. Check ShuffleStoneDB in SavedVariables file
2. Verify SavedVariables declaration in TOC
3. Run /ss scan to force rescan and list rebuild
