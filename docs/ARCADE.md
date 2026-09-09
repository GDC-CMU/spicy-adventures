# Native arcade support

## Engine and preparation contract

Use **Godot 4.5.2-stable**, GL Compatibility. The coordinator provisions the
engine (and matching export templates if executable exports are wanted).
Preparation never downloads runtimes, installs packages, uses SSH, publishes,
or updates the launcher's live cache.

From the repository root, using Python 3.10+ and the standard library:

```powershell
python tools/prepare_arcade.py --godot "C:\path with spaces\Godot_v4.5.2-stable_win64_console.exe" --output-dir "C:\staging\spicy-arcade"
# Optional, only after matching 4.5.2 templates have been provisioned:
python tools/prepare_arcade.py --godot "C:\path with spaces\Godot_v4.5.2-stable_win64_console.exe" --output-dir "C:\staging\spicy-arcade" --native linux --native windows
```

```bash
python3 tools/prepare_arcade.py \
  --godot "/path/to/Godot_v4.5.2-stable_linux.x86_64" \
  --output-dir "/staging/spicy-arcade" --native linux
```

The script refuses another engine version before importing. It waits for a
complete import, runs real Godot tests, exports `spicy-arcade.pck` with the
`Linux Arcade` preset and reruns the complete lifecycle suite on that pack,
from an artifact-only working directory. It writes artifact hashes and
engine details to `spicy-arcade-build.json`. Optional executable exports use
`spicy-arcade-linux/spicy-arcade.x86_64` and
`spicy-arcade-windows/spicy-arcade.exe`, each beside its matching `.pck`.
Cross-exporting an executable is **not** native execution on that platform.
Always use a candidate/staging output directory, never an installed live cache.
The coordinator promotes a candidate only after its checks; a failed command
must not be interpreted as an update to the installed game.

Equivalent engine commands (PowerShell `&` prefix, or invoke directly on Linux):

```text
GODOT --headless --path REPO --editor --import
GODOT --headless --path REPO --max-fps 120 res://tests/arcade_test.tscn -- --arcade
GODOT --headless --path REPO --export-pack "Linux Arcade" OUTPUT/spicy-arcade.pck
GODOT --headless --path REPO --export-release "Linux Arcade" OUTPUT/spicy-arcade.x86_64
GODOT --headless --path REPO --export-release "Windows Desktop" OUTPUT/spicy-arcade.exe
```

Do imports/exports at preparation time, **not** when someone presses Play.
PCK operation needs the pinned native engine but not export templates.
Copy the prepared PCK and its manifest together; do not ship `.godot/` as a
substitute for a prepared pack. Existing `Web` and `Windows Desktop` preset
blocks, paths and options have not been changed.

## Offline run

The launcher should directly supervise this argument list (no shell wrapper):

```text
[GODOT_4_5_2, "--main-pack", ABSOLUTE_PCK_PATH, "--rendering-method", "gl_compatibility"]
```

On Windows, use the actual `Godot_v4.5.2-stable_win64.exe` for supervised play;
the `_console.exe` companion is useful for preparation/test output. On Linux
use the native x86_64 engine directly. No browser, Wine or Python game wrapper.

Set `ARCADE_MODE=1` and `ARCADE_GAME_DATA_DIR` to the launcher's persistent
per-game directory. Standalone equivalent:

```powershell
& $Godot --main-pack "C:\staging\spicy-arcade\spicy-arcade.pck" --rendering-method gl_compatibility -- --arcade
# Laptop/windowed fixture (native display, not headless):
& $Godot --main-pack "C:\staging\spicy-arcade\spicy-arcade.pck" --rendering-method gl_compatibility --windowed --resolution 800x600 -- --arcade
```

Linux:

```bash
ARCADE_MODE=1 ARCADE_GAME_DATA_DIR="/persistent/spicy-adventures" \
  "$GODOT" --main-pack "/staging/spicy-arcade/spicy-arcade.pck" \
  --rendering-method gl_compatibility
```

The Linux Arcade preset also includes the `arcade` feature. Arcade mode requests
fullscreen unless `--windowed` was explicitly supplied. The 1152×648 original
canvas is scaled uniformly with aspect kept; 800×600 has letterboxing, not a
stretched world. The player camera stays at its original 0.75 zoom.

`Stats` is still the original run-local autoload. There was no gameplay save
file to migrate; the adapter does not create, erase or replace any save in
`ARCADE_GAME_DATA_DIR`. Fixtures use isolated `spicy-arcade-*` directories.

## Exact controller flow

This is a **single-player** game. Either normalized device slot can control the
same player and menus; this is not a new two-player mode.

| Physical cabinet control | Raw USB button | Normalized Godot index | Meaning |
| --- | ---: | ---: | --- |
| B | 0 | `JOY_BUTTON_B` = 1 | Pause live play; one level back in menus |
| A | 1 | `JOY_BUTTON_A` = 0 | Eat/use the oldest pepper |
| X | 2 | `JOY_BUTTON_X` = 2 | Emergency heat, after its upgrade |
| Y | 3 | `JOY_BUTTON_Y` = 3 | Discard, after its upgrade |
| Coin | 4 | `JOY_BUTTON_GUIDE` = 5 | Intentionally unbound |
| P1/menu | 5 | `JOY_BUTTON_LEFT_SHOULDER` = 9 | Pause / back |
| Select | 8 | `JOY_BUTTON_BACK` = 4 | Pause / back |
| Start | 9 | `JOY_BUTTON_START` = 6 | Confirm menus; pause live play |

The cabinet reports `0300457e790000000600000010010000` with Godot 4.5's SDL
backend and `03000000790000000600000010010000` with the older backend. Both
exact GUIDs have scoped mappings in `arcade/controls.gd`, with raw stick axes
0/1 and optional hat 0.
The newer HID backend also reorders its raw buttons relative to Linux evdev:
physical B/A/X/Y/coin/P1/Select/Start correspond to SDL buttons
3/1/0/2/9/10/4/6. Its separate mapping was measured on both cabinet sticks;
copying the older GUID's button ordering would turn coin into Start.
It updates already connected matching pads and applies to matching hot-plugs.
Do not copy raw button 9 directly into an InputMap as “Start”: normalized 9 is
a shoulder button. Unknown GUIDs retain Godot's controller database mapping.
The P1/menu shoulder action is intentional for this cabinet override.

1. Release the launcher button. Root focuses **New game**.
2. Stick/arrows choose; **Start** confirms. A/X/Y do not confirm menus.
3. Play: stick moves; A eats; X heats; Y discards when those upgrades exist.
   Keyboard arrows, **Z / A / X** and mouse remain supported.
4. **B, P1, Select, Start or Esc** pauses the live run, never quits it.
   Pause focuses **Resume**; Start or fresh B/P1/Select resumes.
   **Controls** is readable while the run remains frozen.
5. Pause → **Main menu** → choose **Main menu** again to abandon the run.
   The confirmation defaults to **Keep playing**. B cancels one level.
6. Upgrades: left/right focuses the three original offers; Start selects and
   moves focus to **Take selected upgrade**. Release, then Start buys exactly
   once. Down can focus confirmation directly. Pause/back never rerolls offers.
7. Compendium: choose Peppers/Enemies, browse the original descriptions and
   live preview with the stick; X/Y scroll long text. B returns to categories,
   then root. Keyboard A/X also scroll up/down; mouse scrolling works.
8. How to play → **Enter tutorial** starts the original tutorial. Follow the
   in-game controller instructions rightwards to its green exit, or pause/menu.
9. Death or win → **Retry** / **Main menu**. B returns to main menu.
10. At the root, **Exit to gallery**, or B, opens a separate exit confirmation.
    Default is **Stay here**. Choose **Exit game**, release, then Start.
    The normal native process exit code is **0**.

Every page/run transition waits at least two neutral frames and 120 ms.
Holding Start, B, a direction or a combat button cannot start, buy, resume,
attack or quit through multiple screens. Disconnecting a pad during play
pauses the run. No joystick action maps to keyboard P's debug cheat; that cheat
is additionally disabled in arcade mode.

## Tests, diagnostics and staged acceptance

```powershell
python tools/prepare_arcade.py --godot $Godot --tests-only
& $Godot --path . --windowed --script res://tools/controller_probe.gd -- --arcade --arcade-controller-log
& $Godot --path . --windowed --max-fps 60 res://tests/arcade_visual.tscn -- --arcade --spicy-arcade-captures=C:/staging/spicy-arcade-visual
```

Headless tests instantiate the **original** main/level/player scenes, inject
normalized events for slots 0 and 1, use real queues/upgrades and check held
input, pause/frozen time, retry, tutorial, compendium, mouse/keyboard, teardown
and the actual root `quit(0)` path. They must print `SPICY_ARCADE_TESTS_PASSED`;
zero exit without that marker is not a pass.

Normal root exit stops audio, allows its stop commands to drain, then quits 0.
Do not substitute `--quit-after` for this test: in the pinned engine, forcibly
ending active title playback that way can report an embedded-MP3 resource
warning. No such warning remains on the tested controller-driven exit path.
Supervisor force-cancellation is a separate coordinator acceptance check.

For artifact tests, `tools/run_fixture.gd` loads a supplied absolute Node-fixture
path only after the pack's real autoloads initialize. Test tools are excluded
from the production Linux pack; all game resources still load from that PCK.
Example for a native visual review of the actual prepared artifact:

```powershell
& $Godot --main-pack $Pack --windowed --max-fps 60 --script "$Repo/tools/run_fixture.gd" -- --arcade "--spicy-arcade-fixture=$Repo/tests/arcade_visual.gd" "--spicy-arcade-captures=$Repo/release/spicy-arcade-visual"
```

The bounded visual script captures actual native-renderer fixture states at
800×600 and 1280×720. It refuses a headless renderer and requires an explicit
`spicy-arcade-*` output directory. These are labelled fixture images, not a
fabricated attract clip or a claim to have played a complete run.
Godot returns the rendered canvas texture: in an 800×600 letterboxed window
the PNG is 800×450. The script logs both window size and rendered-content size;
it does not fabricate letterbox pixels or capture unrelated desktop windows.

Resource-pack exports for Web and Windows are separate checks; a Web PCK alone
is not a browser HTML build or evidence that the browser version runs.

**Coordinator-only physical gate, still required:**

- Record `get_joy_guid`, device IDs and normalized events for **both** actual
  DragonRise pads using the probe. Check every physical button in the table,
  stick diagonals/neutral, both slots and reconnect/release behavior.
- Cold-start the staged native Linux pack from the launcher with network
  disconnected; verify fullscreen readability, actual GL Compatibility output
  and representative combat/upgrade/boss frame pacing.
- Perform the complete controller-only lifecycle above, including held input
  across launch/pause/results/exit, repeated child/gallery return, cancellation,
  no lingering audio/process/controller owner and normal exit code 0.
- Verify Windows native pack/executable behavior and the unchanged Web path.
- Publish/deploy only after those gates; keep the last working installed build
  and persistent data untouched on preparation failure.
