# Contributing to ShuffleStone

Thanks for your interest! Bug reports, feature requests, and pull requests are all welcome. This repo is maintained by a single maintainer — contributions land via fork-and-PR, and releases are cut by the maintainer only.

## Building locally

No toolchain needed beyond bash and zip.

```bash
./build.sh
```

creates a versioned zip in `build/` (same layout the release pipeline ships).

To install straight into your WoW folder while developing:

```bash
cp .env.example .env   # then set WOW_ADDONS_DIR to your AddOns path
./deploy-local.sh
```

`.env` is gitignored — never commit your local path.

## Testing

There is no automated test suite; testing is in-game:

1. `./deploy-local.sh`, then `/reload` in WoW (or restart the client).
2. `/ss` opens the main window — exercise the flow your change touches.
3. `/ss debug` prints owned toys, lists, macros, and rotation state — include relevant output in your PR if it helps demonstrate the fix.

## Coding style

Match the surrounding code. In particular:

- 4-space indentation, Lua, raw WoW frame API — **no external UI libraries** (no Ace); only the embedded LibStub/CallbackHandler.
- Avoid per-frame/per-refresh allocations: reuse the existing button pools and pre-allocated buffers rather than creating fresh tables.
- Anything that touches macros or secure buttons must be combat-safe: guard with `InCombatLockdown()` and defer to `PLAYER_REGEN_ENABLED` (see `ToyEngine/Buttons.lua` for the pattern).
- UI sizes, textures, and colors live in `Constants.lua` — don't hardcode them in modules.

## Pull requests

- Keep PRs small and focused — one fix or feature per PR.
- For anything non-trivial, open an issue first to discuss the approach before writing code.
- Describe what you changed, why, and how you tested it in-game.
- New toys go in `Data.lua` (id + name); these are the most common and most welcome PRs.

Releases (version bumps, tags, CurseForge/Wago uploads) are handled by the maintainer — PRs should not touch `## Version` in the TOC or add `release-notes/` files.
