# ShuffleStone Release Notes

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

### Commands

- `/ss` — Toggle the main window
- `/ss debug` — Print debug info (owned toys, lists, macros, rotation state)

### Compatibility

- **WoW Version:** Midnight (12.0+)
- **Interface Version:** 120000
