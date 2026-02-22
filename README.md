# ShuffleStone

A World of Warcraft addon that randomizes your hearthstone toys with a shuffle-bag rotation algorithm, ensuring no repeats until all toys in your list are used.

## Features

- **No-Repeat Rotation** — Uses shuffle-bag algorithm to randomly select from a list of hearthstones without repeating until all are cycled
- **Action Bar Macro** — Create custom macros for your action bar that automatically use the next random hearthstone in your list
- **Custom Lists** — Create multiple toy lists ("Favorites", "Holiday Hearthstones", etc.) and switch between them instantly
- **32 Hearthstones Supported** — Covers all home hearthstones (not Dalaran/Garrison variants)
- **Click-to-Manage** — Visual overlay UI for adding/removing toys from lists with checkmarks and icons
- **Floating Window** — Draggable, resizable custom UI window (Cooldown Manager style)
- **Filtering** — Toggle "Show Unobtained" to see all supported toys or only the ones you own
- **Combat Safe** — Uses SecureActionButton for macro usage during combat

## Quick Start

1. Download and install ShuffleStone into your `World of Warcraft\_retail_\Interface\AddOns\` folder
2. Reload your UI (`/reload`) or restart WoW
3. Type `/ss` to open the main window
4. Select toys from the grid to add them to your current list
5. Drag the macro icon from the list editor to your action bar
6. Click your macro to use a random toy!

## Commands

| Command | Effect |
|---------|--------|
| `/ss` or `/shufflestone` | Toggle the main window |
| `/ss debug` | Toggle debug mode (verbose logging) |
| `/ss scan` | Force rescan of your toy inventory |

## Main Window

### Zone 1: Toy Selection Grid

Shows all available hearthstones (32 total). Click a toy icon to add it to the current list (green checkmark appears when selected). Use the "Show Unobtained" checkbox to filter out toys you don't own.

### Zone 2: List Editor

Displays your saved lists with:
- **Macro Icon** (left) — Drag to action bar to add the macro for this list
- **List Name** — Click to edit the name
- **Change Icon** — Open icon picker to customize the hearthstone icon texture
- **Delete** — Remove the list

### Add List Button

Click to create a new custom list with default settings. Name it and start adding toys!

### List Dropdown

Switch between your saved lists (e.g., "All Hearthstones", "Favorites"). Changing the list updates the toy grid and changes which macro is used when you press a keybind.

## Tech Stack

- **Language:** Lua (WoW addon API)
- **WoW Interface:** 120100 (The War Within)
- **UI Framework:** Raw WoW frame API (no AceGUI)
- **Templates Used:**
  - BasicFrameTemplateWithInset (floating window)
  - UIDropDownMenuTemplate (list selector)
  - UIPanelScrollFrameTemplate (scrollable lists)
  - SecureActionButtonTemplate (combat-safe macros)

## Project Structure

```
ShuffleStone/
├── ShuffleStone.toc        # Addon manifest and load order
├── Core.lua                # Main namespace, SavedVariables, event handlers
├── Data.lua                # Toy registry and constants
├── ToyEngine/
│   ├── Scanner.lua         # Toy ownership detection
│   ├── Rotation.lua        # No-repeat shuffle algorithm
│   └── Buttons.lua         # Macro and button management
├── UI/
│   ├── IconGrid.lua        # Reusable toy icon grid
│   ├── ListEditor.lua      # List management rows
│   └── MainFrame.lua       # Main window and integration
├── Libs/                   # Embedded libraries
│   ├── LibStub/
│   └── CallbackHandler-1.0/
└── build.sh                # CurseForge build script
```

## Supported Hearthstones (32 Total)

The addon supports all home hearthstones including:
- Hearthstone (original)
- Eternal Fire, Eternal Life, Eternal Frost
- Everburning Hearthstone, Eternal Wormhole
- Zenithial Beacon, Infinite Timereaver
- Illimited Diamond Vessel, Shimmering Soulstone
- And 20+ more home hearthstones

Does NOT include Dalaran, Garrison, or battle pet hearthstones.

## Creating Lists

1. Click "Add List" button
2. Enter a name for your list (e.g., "Raid Night")
3. Click on toys in the grid to add them (checkmark appears)
4. Drag the macro icon from the list row to your action bar
5. Use the macro to get random toys from that list!

## How It Works

### Shuffle-Bag Rotation

When you click your macro:
1. The addon uses a shuffle-bag algorithm to pick a random toy from your list
2. That toy is marked as "used" so it won't appear again until all toys in the list are cycled
3. Once all toys are used, the list resets and the cycle repeats
4. No toy is repeated twice in a row, ensuring variety

Example: If your list has [Hearthstone, Eternal Fire, Eternal Life]:
- Click 1: Uses Eternal Fire
- Click 2: Uses Eternal Life (never Eternal Fire again)
- Click 3: Uses Hearthstone (never Eternal Fire or Eternal Life again)
- Click 4: Cycles reset, uses any of the three again

### Macro System

ShuffleStone creates individual macros for each list you create. These macros:
- Use `SecureActionButton` for combat safety
- Can be dragged to your action bar
- Remember which list they belong to
- Don't have the 255-character macro limit (uses attributes instead)

### Persistence

All your lists, toy selections, and rotation state are saved across WoW sessions in `ShuffleStoneDB` SavedVariables.

## Troubleshooting

### The macro doesn't seem to do anything

1. Make sure the toy list has toys in it (check the grid for checkmarks)
2. Verify you own at least one of the toys (`/ss scan` to rescan)
3. Try toggling the macro again after confirming a toy cast with the `/ss debug` command

### Can't drag the macro to my action bar

- Ensure you're not in combat (`InCombatLockdown`)
- Check the macro icon displays correctly in the list editor row
- Try reloading your UI (`/reload`)

### A toy isn't in my list after reload

1. Run `/ss scan` to force a rescan of your toy inventory
2. Check that `ShuffleStoneDB` is present in your WoW SavedVariables
3. Try creating a new list and manually adding the toy again

## Version

**Current Version:** 1.0.0
**Author:** asp1d
**License:** MIT

## Contributing

Found a bug or have a feature request? Open an issue or submit a pull request on the project repository.

## License

ShuffleStone is provided as-is. Feel free to modify and redistribute under the MIT license.
