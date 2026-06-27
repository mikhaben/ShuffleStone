# ShuffleStone Release Notes

## Version 1.0.7 - WoW 12.0.7 Compatibility

### Compatibility

- **Updated for WoW 12.0.7 (Midnight)** — Bumped the supported interface version to 120007 so the addon loads on the current patch. No functional changes: the toy, secure-button, and shuffle-rotation APIs are unaffected by the 12.0.1–12.0.7 changes.

---

## Version 1.0.6 - New Hearthstone

### Updated Toy Registry

- **Added Personal Key to the Arcantina** — Midnight quest reward (Arator's Journey) that teleports you to the Silvermoon Arcantina on a 15-minute cooldown, effectively a Silvermoon hearthstone.

---

## Version 1.0.5 - Stability & Performance

### Bug Fixes

- **Fixed rotation repeats after removing toys** — Removing a toy from a list could cause the no-repeat shuffle to break, allowing back-to-back duplicates. Now works correctly.

- **Fixed empty list showing stale icon** — Removing all toys from a list left the old toy icon on your action bar. Now properly resets to the list icon.

- **Fixed rare UI crash on login** — A timing issue could cause an error when the window resized before fully loading. Now handled gracefully.

- **Fixed macro not deleting after rename** — Deleting a list that was previously renamed could leave an orphan macro behind. Now cleaned up correctly.

- **Macro limit warning** — If you hit WoW's 120 macro limit, ShuffleStone now tells you in chat instead of failing silently.

### Improvements

- **Faster toy scanning** — When the server sends toy data in bursts (e.g. on login), multiple updates are now batched into one scan instead of rescanning repeatedly.

- **Rotation preserved on /reload** — Your position in the shuffle rotation is no longer lost on /reload if nothing changed. Previously, every reload would advance the rotation.

- **Icon picker shows all icons at full brightness** — Since you're picking a display icon, unobtained hearthstones are no longer dimmed in the picker.

- **Stale data cleanup** — Removed toys that no longer exist in the game and leftover rotation data from deleted lists are automatically cleaned up.

### Under the Hood

- Major internal code cleanup: consolidated duplicate logic, removed dead code, improved memory efficiency. No user-facing changes from these, just a cleaner codebase.

---

## Version 1.0.3 - Macro Reliability & ID-Based Tooltips

### Bug Fixes

- **Fixed macro body editing during execution** — `EditMacro` was being called from PostClick while the macro was still running, causing WoW's macro parser to lose its position and send fragments of `/click ShuffleStone_all` as chat messages. Macro body updates are now deferred to the next frame via `C_Timer.After(0, ...)`.

- **Switched toy button attributes to use IDs** — `SetAttribute("toy", ...)` now uses the numeric toy ID instead of the localized toy name, preventing breakage on non-English clients.

### Improvements

- **`#showtooltip item:<id>` on all macros** — Macros now always include `#showtooltip item:<toyID>` so the action bar displays the hearthstone cooldown and the tooltip of the next queued toy. The tooltip updates after each use to show the upcoming toy.

- **ID-based macro bodies** — All macro references (button attributes, `#showtooltip`, item references) now use numeric IDs instead of localized names, making the addon fully locale-independent.

---

## Version 1.0.2 - Production Readiness Audit

### Bug Fixes

- **Fixed NEW_TOY_ADDED handler collision** — Buttons.lua was silently overwriting Core.lua's handler, preventing the UI from refreshing when a new hearthstone toy was obtained. The handler is now consolidated in Core.lua with full scan, rotation reset, button pre-selection, and UI refresh.

### Improvements

- **Icon Picker** — Added a dedicated icon picker window for choosing list icons from all hearthstone toys, with visual checkmarks on the active selection and unobtained toy dimming.

- **Updated Toy Registry** — Added Preyseeker's Hearthstone from Midnight's Prey system.

### Code Quality

- **Removed dead code** — Eliminated unused variable capture in IconPicker.lua, redundant frame assignment in MainFrame.lua, and duplicate event handler/registration in Buttons.lua.

- **DRY improvement** — Replaced manual owned-count loop in ListEditor.lua with existing `GetOwnedToysForList()` helper, removing duplicated logic.

---

## Version 1.0.0 - Initial Release

### New Features

- **Shuffle-Bag Hearthstone Rotation** — Uses no-repeat random selection from your hearthstone list. Each toy is guaranteed unique until all toys in the list are cycled.

- **Custom Hearthstone Lists** — Create multiple saved lists ("Favorites", "Holiday Hearthstones", etc.) and switch between them. Each list has its own rotation state.

- **Action Bar Macros** — Drag macro icons from the list editor directly to your action bar. Each list gets its own draggable macro for instant list switching.

- **All Home Hearthstones Supported** — Full support for every home hearthstone toy from Classic through Midnight.

- **Custom Floating UI** — Easy-to-use floating window with two-zone layout: toy selection grid on top, list editor below.

- **Toy Grid with Click-to-Add** — Click toys in the grid to add/remove them from your list. Visual checkmarks show which toys are selected.

- **Ownership Filtering** — Toggle "Show Unobtained" checkbox to view all supported hearthstones or filter to only the ones you own.

- **List Management** — Edit list names, change hearthstone icon textures, and delete lists with one click.

- **Combat Safety** — Uses SecureActionButton for safe toy casting during raids and dungeons.

- **Persistent Storage** — All custom lists and rotation state saved across WoW sessions.