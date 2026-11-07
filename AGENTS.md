# ShuffleStone

## North star

A World of Warcraft addon that picks a random hearthstone toy from the player's own lists, without
repeats until the list is cycled, and fires it from an action-bar macro that stays safe in combat.
It stays a small, dependency-free addon (no Ace, only the embedded LibStub/CallbackHandler).

## Commands

- `luacheck .` — lint; must report 0 warnings. Config in `.luacheckrc`: a new WoW API the addon
  reads goes in `read_globals`, a global it writes goes in `globals`.
- `./build.sh` — versioned zip in `build/`.
- `./deploy-local.sh` — build and install into the local AddOns folder (`WOW_ADDONS_DIR` in the
  gitignored `.env`, template `.env.example`).
- In game: `/ss` toggles the window, `/ss debug` prints owned toys, lists, macros and rotation
  state. There is no automated test suite; changes are checked in game after `/reload`.

## Feature map

Load order is the file list in `ShuffleStone.toc`; every file shares the addon namespace `NS`.

| Feature | Where |
| --- | --- |
| Events, SavedVariables defaults and merge, slash commands, debug dump | `Core.lua` |
| Hearthstone toy registry (id, name) | `Data.lua` |
| Sizes, textures, colors, shared helpers | `Constants.lua` |
| Toy ownership scan, list lookups | `ToyEngine/Scanner.lua` |
| Shuffle-bag pick and reset per list | `ToyEngine/Rotation.lua` |
| SecureActionButtons, per-list macros, create/rename/remove | `ToyEngine/Buttons.lua` |
| Main window: dropdown, toy grids, list actions | `UI/MainFrame.lua` |
| Pooled icon grid, icon picker, list row, window frame | `UI/IconGrid.lua`, `UI/IconPicker.lua`, `UI/ListEditor.lua`, `UI/WindowFactory.lua` |
| Settings panel | `UI/Settings.lua` |
| Packaging and upload | `.github/workflows/release.yml`, `.pkgmeta` |

## Rules

- The next toy is pre-selected into the SecureActionButton's attributes, not chosen in a PreClick
  handler, so one click consumes exactly one rotation entry. Rotation advances on click, not on
  `UNIT_SPELLCAST_SUCCEEDED`.
- Combat: anything that creates, edits or deletes macros or secure buttons checks
  `InCombatLockdown()` first. User actions print "Cannot … during combat" and do nothing; internal
  calls return early. Nothing is queued for after combat, so the user retries.
- Refreshes reuse the button pools and pre-allocated buffers instead of building new tables.
- UI sizes, textures and colors come from `Constants.lua`.
- The icon picker shows every icon at full brightness on purpose: it picks a look, not a toy the
  player owns.
- New files the addon does not ship (tooling, docs) go in the `.pkgmeta` `ignore` list; `build.sh`
  copies an explicit file list.

## Saved state

`ShuffleStoneDB` holds lists (name, icon, toyIDs), per-list rotation state, window position and
settings. Each list's `remaining[]` shrinks by swap-and-pop; after a refill `lastUsed` is moved to
the end so the same toy never plays twice in a row.

- Adding or removing a toy in a list resets that list's rotation.
- `/reload` keeps rotation positions; obtaining a new toy (`NEW_TOY_ADDED`) resets every list's.
- Macros are named `SS: <listname>` and live in WoW's macro storage, so they survive sessions;
  renaming edits the macro in place to keep its action-bar slot.

## Releasing

The flow is in the header of `.github/workflows/release.yml`. A GitHub ruleset on `main` requires
a pull request (work lands on `develop`, then a `develop` → `main` PR) and restricts `v*` tags to
admins. Pushing a `v*` tag publishes to CurseForge, Wago and GitHub Releases, so never push one
unless asked.
