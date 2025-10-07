# Popochiu Addons Feature Index

This document enumerates every custom system layered on top of Popochiu so the set can be exported and injected into a new project with minimal friction. Each section lists the files involved, public APIs, and migration notes.

## 1. Letterbox Overlay
- **Core Files**
  - `addons/popochiu-addons/letterbox/letterbox_controller.gd`
  - `addons/popochiu-addons/gui/letterbox_gui.gd` (spawns the controller at runtime and exposes helpers)
  - `game/gui/gui.gd` (project stub that extends the Popochiu Addons GUI script)
- `addons/popochiu-addons/wrappers/g_autoload.gd` (wrapper autoload extending `addons/popochiu-addons/api/g.gd`, which exposes letterbox presets/API)
  - `addons/popochiu-addons/letterbox/letterbox_api.gd` (central preset + helper module)
- Documentation: `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.1) and `addons/popochiu-addons/doc/to-do/letterbox_todo.md`
- **Key Features**
  - Tweened + faded top/bottom/left/right bars with aspect-ratio logic, pixel overrides, GUI blocking, and queue integration.
  - Transition signal (`transition_finished`) for synchronising cutscenes, analytics, or SFX.
  - Preset catalogue (26 entries) covering cinematic, mood, UI, and utility scenarios.
  - Preset management helpers: `list_letterbox_presets`, `get_letterbox_preset`, `has_letterbox_preset`, `register_letterbox_preset`.
  - PFX combo helpers (`show_letterbox_with_pfx`, queue variants) that apply PostFX presets in lockstep with letterbox transitions.
- **Porting Checklist**
  1. Copy the files listed above into the new project (`addons/popochiu-addons/letterbox`, `addons/popochiu-addons/gui`, `addons/popochiu-addons/wrappers/g_autoload.gd`, and `addons/popochiu-addons/api/g.gd`).
  2. Ensure the target GUI script extends `res://addons/popochiu-addons/gui/letterbox_gui.gd` (or merge its helpers into your own script).
  3. Change `project.godot` autoload entries so `G` points to `res://addons/popochiu-addons/wrappers/g_autoload.gd` (which extends `addons/popochiu-addons/api/g.gd`) and `PFX` points to `res://addons/popochiu-addons/pfx/pfx.gd`.
  4. Preserve the standard headless test command (`/usr/bin/godot --path . --headless --run`) in contributor docs.
  5. Run through `addons/popochiu-addons/doc/to-do/letterbox_todo.md` after integration.

## 2. PostFX Controller (PFX)
- **Core Files**
- `addons/popochiu-addons/pfx/pfx.gd` — Popochiu-safe wrapper that spawns per-context `postfx_controller.tscn` instances.
  - `addons/popochiu-addons/pfx/shaders/postfx_pipeline.shader.gdshader` + `.tres` — shared shader assets referenced by the controller.
- `addons/popochiu-addons/pfx/controller/postfx_controller.tscn` & associated shader/material assets.
  - Usage references in the command wrapper (`addons/popochiu-addons/wrappers/gui_commands_wrapper.gd`) that project scripts extend.
- Documentation cross-link: See `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.2) for PostFX details and letterbox/PostFX combos.
- **Key Features**
  - Deferred creation of PostFX controllers via `_ensure_controller` for global or room-scoped contexts.
  - Support for applying configs, merging adjustments, toggling features, and retrieving cached configs.
  - Room defaults (`ROOM_DEFAULTS`) to bootstrap per-room shaders without touching addon code.
  - Helpers for “old video” preset and easy parameter adjustments (scanlines, CRT warp, etc.).
- **Porting Checklist**
  1. Copy `addons/popochiu-addons/pfx/` (autoload, controller, shaders) and any scenes referencing them.
  2. Register `PFX` as an autoload in the new project (`project.godot` → `[autoload]` → `PFX="*res://addons/popochiu-addons/pfx/pfx.gd"`).
  3. Ensure the Popochiu `G` autoload points to the wrapper (`res://addons/popochiu-addons/wrappers/g_autoload.gd`) so the Popochiu Addons API is available alongside the letterbox helpers.
  4. Verify the plugin assets under `addons/popochiu-addons/` remain intact and Popochiu's bundled addons stay untouched.

## 3. Prop Fade Helpers
- **Core Files**
  - `addons/popochiu-addons/api/g.gd` (base autoload exposing prop fade helpers)
  - `addons/popochiu-addons/api/popochiu_helper.gd` (PopochiuAddonsHelper extension that mirrors the API)
  - `addons/popochiu-addons/wrappers/popochiu_helper.gd` (autoload wrapper installed by the plugin)
- Documentation cross-link: `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.3)
- **Key Features**
  - Tween-based fades for any Popochiu prop (`CanvasItem`) with configurable duration, transition, easing, and delay.
  - Optional queue callables (`queue_fade_prop*`) for Popochiu command sequencing with built-in blocking semantics.
  - Convenience wrappers for fade-in/out plus helper autoload access so gameplay scripts can call `PopochiuAddonsHelper.fade_prop(...)`.
- **Porting Checklist**
  1. Enable the plugin so the `PopochiuAddonsHelper` autoload is replaced with `addons/popochiu-addons/wrappers/popochiu_helper.gd`.
  2. Update any custom helper overrides to extend `res://addons/popochiu-addons/api/popochiu_helper.gd`.
  3. Confirm props you plan to fade inherit from `CanvasItem` (Sprites, Controls, etc.).
  4. Exercise both blocking (`await G.fade_prop(...)`) and non-blocking fades plus queue callables after integration.

## 4. Guidelines & Tooling Updates
- `AGENTS.md` now reminds contributors to keep Popochiu modifications outside `addons/`.
- `doc/letterbox_todo.md` keeps QA tasks visible.

## 5. Migration Strategy for New Projects
1. **Prepare Autoloads**: Copy `addons/popochiu-addons/wrappers/` (autoload + command wrappers), `addons/popochiu-addons/api/`, `addons/popochiu-addons/letterbox`, `addons/popochiu-addons/gui`, and `addons/popochiu-addons/pfx`, then register `G`/`PFX` in the target project.
2. **GUI Integration**: Point the project GUI script to extend `res://addons/popochiu-addons/gui/letterbox_gui.gd` (or merge those helpers into an existing script).
3. **Assets**: Move `addons/popochiu-addons/pfx/` directory (contains controller/shaders) and any additional textures referenced by presets.
4. **Docs**: Bring over `POPOCHIU_ADDONS_DOCUMENTATION.md`, `addons/popochiu-addons/doc/to-do/letterbox_todo.md`, and this feature index for future maintainers.
5. **Validation**: Follow the TODO checklist—exercise presets, queue helpers, and PFX combos.
6. **Packaging**: Optionally wrap the system into a Godot plugin for plug-and-play use across Popochiu projects.

## 6. Notes on Modularisation
- Popochiu's bundled addons stay untouched; all custom logic lives in `addons/popochiu-addons/` with thin wrappers in the game layer.
- Any future feature should follow the same pattern: place reusable code under `addons/popochiu-addons/`, documentation under `doc/`, and record migration notes here.
- If a change requires interacting with core Popochiu logic, consider subclassing or signal forwarding from the game layer instead of modifying the addon.

## 7. Future Work
- Build a tiny “cinematic showcase” room demonstrating letterbox + PFX combinations.
- Polish the Popochiu Addons plugin metadata and publish install instructions for external projects.
- Add automated headless tests that instantiate the controller, run a tween, and assert final bar offsets and modulate values.
- Collect SFX assets for letterbox transitions and wire them through `transition_finished` listeners.

Maintain this document as new systems land so Popochiu Addons stays a well-defined feature pack.
