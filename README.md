# ShuffleStone

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![CurseForge](https://img.shields.io/badge/CurseForge-Download-F16436?logo=curseforge&logoColor=white)](https://www.curseforge.com/wow/addons/shufflestone-random-hearthstone)
[![Wago](https://img.shields.io/badge/Wago-Download-A34FE0)](https://addons.wago.io/addons/shufflestone-random-hearthstone)
[![Buy Me A Coffee](https://img.shields.io/badge/Buy_Me_A_Coffee-FFDD00?logo=buy-me-a-coffee&logoColor=black)](https://buymeacoffee.com/justluther)

A World of Warcraft addon that randomizes your hearthstone toys with a shuffle-bag rotation algorithm, ensuring no repeats until all toys in your list are used.

## Features

- **No-Repeat Rotation** — Uses shuffle-bag algorithm to randomly select from a list of hearthstones without repeating until all are cycled
- **Action Bar Macro** — Create custom macros for your action bar that automatically use the next random hearthstone in your list
- **Custom Lists** — Create multiple toy lists ("Favorites", "Holiday Hearthstones", etc.) and switch between them instantly
- **All Home Hearthstones Supported** — Covers every home hearthstone toy from Classic through Midnight (not Dalaran/Garrison variants)
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
| `/ss debug` | Print debug info (owned toys, lists, macros, rotation state) |

## Main Window

### Zone 1: Toy Selection Grid

Shows all available hearthstones. Click a toy icon to add it to the current list (green checkmark appears when selected). Use the "Show Unobtained" checkbox to filter out toys you don't own.

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
- **WoW Interface:** 120007 (Midnight)
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
├── Data.lua                # Toy registry (all hearthstones) and toy constants
├── Constants.lua           # Centralized UI constants, textures, colors
├── ToyEngine/
│   ├── Scanner.lua         # Toy ownership detection
│   ├── Rotation.lua        # No-repeat shuffle algorithm with anti-repeat
│   └── Buttons.lua         # Macro and button management
├── UI/
│   ├── WindowFactory.lua   # Frame template factory (inset, resizable windows)
│   ├── IconGrid.lua        # Reusable toy icon grid
│   ├── IconPicker.lua      # Icon picker for list customization
│   ├── ListEditor.lua      # List management rows
│   ├── MainFrame.lua       # Main window and integration
│   └── Settings.lua        # Settings panel configuration
├── Assets/
│   └── logo.tga            # Custom addon icon
├── Libs/                   # Embedded libraries
│   ├── LibStub/
│   └── CallbackHandler-1.0/
├── release-notes/          # Per-version release notes (one file per version)
├── .pkgmeta                # Packager config for the release workflow
├── .github/                # Release workflow + issue/PR templates
│   └── workflows/
│       └── release.yml     # CI: tag push → package + upload to CurseForge, Wago, GitHub
├── LICENSE                 # MIT
├── CONTRIBUTING.md         # How to build, test, and submit PRs
├── build.sh                # CurseForge build script
└── deploy-local.sh         # Build + install into your local WoW AddOns folder
```

## Supported Hearthstones

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
2. Verify you own at least one of the toys (`/reload` to rescan)
3. Run `/ss debug` to check macro status and rotation state

### Can't drag the macro to my action bar

- Ensure you're not in combat (`InCombatLockdown`)
- Check the macro icon displays correctly in the list editor row
- Try reloading your UI (`/reload`)

### A toy isn't in my list after reload

1. Reload your UI (`/reload`) to force a rescan of your toy inventory
2. Check that `ShuffleStoneDB` is present in your WoW SavedVariables
3. Try creating a new list and manually adding the toy again

## Version

**Current Version:** 1.0.8
**Author:** justLuther
**License:** MIT

## Releasing

Releases are built and published by GitHub Actions (`.github/workflows/release.yml`)
using the [BigWigsMods packager](https://github.com/BigWigsMods/packager), triggered
when you push a **version tag**.

To cut a release:

1. Bump `## Version` in `ShuffleStone.toc` and create `release-notes/<version>.md` with
   that version's notes — this file becomes the changelog shown on CurseForge/Wago.
2. Land the bump on `main` via pull request (direct pushes to `main` are blocked),
   then tag the merge commit and push the tag — only tags on `main` are published:
   ```bash
   git tag v1.0.8
   git push origin v1.0.8
   ```
3. The workflow packages the addon and uploads it to CurseForge, Wago, and GitHub Releases.

**One-time setup:** add the `CF_API_KEY` and `WAGO_API_KEY` repository secrets
(Settings → Secrets and variables → Actions). Both are required — if either is missing
the workflow skips the upload (with a warning) rather than publishing to only one
platform. Project IDs live in `ShuffleStone.toc` (`## X-Curse-Project-ID`, `## X-Wago-ID`).
`build.sh` remains available for manual local packaging.

## Contributing

Found a bug or have a feature request? Open an issue or submit a pull request — see [CONTRIBUTING.md](CONTRIBUTING.md) for how to build, test, and what to expect in review.

## License

ShuffleStone is released under the [MIT License](LICENSE).
