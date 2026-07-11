# ShuffleStone — WoW Hearthstone Toy Randomizer

A World of Warcraft addon that rotates through hearthstone toys with a shuffle-bag algorithm (no repeats until all are cycled). Features custom floating UI for managing toy lists, drag-to-actionbar macros, and SecureActionButton integration for combat-safe casting.

## Commands & Scripts

- `/ss` or `/shufflestone` — Toggle main UI window
- `/ss debug` — Print debug info (owned toys, lists, macros, rotation state)
- `./build.sh` — Create versioned CurseForge zip (`build/ShuffleStone_<version>_<date>.zip`)
- `./deploy-local.sh` — Build + install into the local WoW AddOns folder (path from gitignored `.env`)

## Architecture

ShuffleStone follows a modular design: data registry → core state management → toy engine (rotation, scanning, buttons) → UI system. Events flow through Core.lua (`PLAYER_LOGIN`, `TOYS_UPDATED`, `NEW_TOY_ADDED`) which delegates to specialized modules.

Key pattern: Pre-selected toys queued into SecureActionButton attributes (not PreClick handler) to avoid double-consuming rotation entries.

## Project Structure

```
ShuffleStone/
├── ShuffleStone.toc           # Addon manifest (interface 120007, version 1.0.8)
├── Core.lua                   # Namespace, SavedVariables init, event handling, slash commands
├── Data.lua                   # Hearthstone toy registry (id, name pairs; 40+ toys)
├── Constants.lua              # UI constants (sizes, textures, colors), helpers
├── ToyEngine/
│   ├── Scanner.lua            # Toy ownership detection via PlayerHasToy / C_ToyBox APIs
│   ├── Rotation.lua           # Shuffle-bag rotation with anti-repeat safeguards
│   └── Buttons.lua            # SecureActionButton pool, macro creation/management
├── UI/
│   ├── WindowFactory.lua       # Frame template factory (inset, resizable windows)
│   ├── IconGrid.lua           # Wrapping icon grid with pooling (40 pre-allocated buttons)
│   ├── IconPicker.lua         # Icon picker for list customization
│   ├── ListEditor.lua         # List row: macro drag target, name edit, icon/delete
│   ├── MainFrame.lua          # Main window (dropdown, toy grid, list editor, add button)
│   └── Settings.lua           # Settings panel for addon options
├── Assets/
│   └── logo.tga               # Custom addon icon
├── Libs/
│   ├── LibStub/LibStub.lua    # Library loader
│   └── CallbackHandler-1.0/   # Event system for inter-component communication
├── release-notes/             # Per-version changelog (release-notes/<version>.md → CurseForge/Wago)
├── .pkgmeta                   # BigWigsMods packager config (manual-changelog, ignore list)
├── .github/
│   ├── workflows/
│   │   └── release.yml        # CI: on v* tag push (tag must be on main), package + upload to CurseForge/Wago/GitHub
│   ├── ISSUE_TEMPLATE/        # Bug report + feature request templates
│   └── PULL_REQUEST_TEMPLATE.md
├── LICENSE                    # MIT, copyright justLuther (ships in the release zip)
├── CONTRIBUTING.md            # Build/test/style guide for contributors (excluded from zip)
├── MARKETING.md               # CurseForge listing copy: description with badges, categories, tags
├── build.sh                   # CurseForge build script
├── deploy-local.sh            # Local dev: build + install into your WoW AddOns folder (path from .env)
└── .env.example               # Template for .env (gitignored); set WOW_ADDONS_DIR to your AddOns path
```

## Releasing

CI (`.github/workflows/release.yml`) runs the [BigWigsMods packager](https://github.com/BigWigsMods/packager) on pushed version tags (`v*`) and uploads to CurseForge, Wago, and GitHub Releases. Tag-driven because the packager refuses to package a tag reached via a branch push. The workflow only publishes tags pointing to commits on `main` (ancestry check) and the packager action is pinned to a commit SHA against supply-chain compromise. `.pkgmeta` controls zip contents — embedded Libs ship; dev/tooling files are stripped via `ignore`.

Per-version changelog: the CurseForge/Wago description comes from `release-notes/<version>.md`, copied to `CHANGELOG.md` (gitignored) by the workflow and fed to the packager via `manual-changelog`.

Release: bump `## Version`, add `release-notes/<version>.md`, land the commit on `main` via PR — a repo ruleset blocks direct pushes, force-pushes, and deletion on `main`, and restricts `v*` tag creation to admins — then `git tag vX.Y.Z && git push origin vX.Y.Z`. Requires repo secrets `CF_API_KEY` + `WAGO_API_KEY` (both, or deploy is skipped); project IDs live in the TOC (`X-Curse-Project-ID`, `X-Wago-ID`).

## SavedVariables & Configuration

ShuffleStoneDB stores lists (name, icon, toyIDs), rotation state (remaining toys per list, lastUsed), window position, and settings (showUnobtained, dynamicIcon).

Each list has a shuffle-bag state: `remaining[]` is cycled down via swap-and-pop, `lastUsed` is pinned to the end after refill to prevent back-to-back repeats.

## How Modules Connect

**Data** → constants for toy registry; **Core** registers events and manages DB; **Scanner** checks toy ownership; **Rotation** picks next toy per list; **Buttons** creates macros and SecureActionButtons (pooled, reused across list switches); **UI** reads from DB and triggers Rotation/Buttons via callbacks.

Core doesn't track UNIT_SPELLCAST_SUCCEEDED — rotation advances on button click (pre-select pattern), not on cast. This works for any toy-like item.

## Key Design Decisions

- **No external UI libs** — Uses raw WoW templates (BasicFrameTemplateWithInset, UIDropDownMenuTemplate) to keep addon lightweight
- **Reusable button pool** — 40 icon buttons pre-allocated and reused, reducing allocations during frequent list switches
- **Memory optimization** — Pre-allocated buffers (ownedToysBuffer, dropdownBuffer) refilled instead of allocating fresh tables on each refresh
- **Combat safety** — All destructive ops (macro creation, list deletion) are guarded by InCombatLockdown() and silently skipped during combat — there is no deferral queue; the operation must be retried after combat
- **Centralized constants** — Constants.lua loaded before Core/UI so all modules share textures, colors, sizing without duplication

## Non-Obvious Behaviors

- Removing a toy from a list resets that list's rotation state (prevents duplicates with fewer toys)
- Macros are named "SS: <listname>" and stored in WoW's macro system (not just in SV), so they survive across sessions
- Icon picker shows all icons at full brightness (not dimmed for unobtained toys) since it's a display choice, not ownership
- `/reload` preserves rotation position unless toys were actually added/removed (validated during rescan)
