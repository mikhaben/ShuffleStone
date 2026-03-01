# ShuffleStone Release Notes

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