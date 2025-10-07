# Popochiu Addons Technical Guide

Version 1.1 · Supports Godot 4.5 / Popochiu 2.0  
Maintainer: Popochiu Addons Team

This guide is the canonical reference for the Popochiu Addons plugin. It complements the lightweight `INSTALLATION.md` checklist and the per-module manuals found under `addons/popochiu-addons/doc/`. The goal is to explain how the plugin layers on top of Popochiu, document every exported API, outline integration and testing workflows, and provide enough context for teams to extend or debug the feature pack without guesswork.

---

## Table of Contents
1. [Scope & Goals](#1-scope--goals)  
2. [Getting Started](#2-getting-started)  
3. [Plugin Architecture](#3-plugin-architecture)  
4. [Core Runtime APIs](#4-core-runtime-apis)  
5. [Module Deep Dives](#5-module-deep-dives)  
6. [Integration Workflows](#6-integration-workflows)  
7. [Configuration Reference](#7-configuration-reference)  
8. [Testing & QA](#8-testing--qa)  
9. [Debugging & Troubleshooting](#9-debugging--troubleshooting)  
10. [Performance Notes](#10-performance-notes)  
11. [Extensibility & Roadmap](#11-extensibility--roadmap)  
12. [File Index](#12-file-index)  
13. [Appendix: Signals & Callbacks](#13-appendix-signals--callbacks)

---

## 1. Scope & Goals

Popochiu Addons packages cinematic and presentation-focused systems that overlie Popochiu without touching its core scripts. It currently includes:
- **Letterbox Overlay** – Runtime letterbox/pillarbox controller, preset catalogue, Popochiu queue helpers.
- **PostFX Pipeline (CRT)** – Configurable post-processing layer with per-room contexts and Popochiu command hooks.

The plugin stays additive—wrappers expose optional helpers so project overrides remain thin. Every module is shippable on its own, but the combined stack unlocks modern audiovisual flourishes for Popochiu adventures.

---

## 2. Getting Started

1. Follow `INSTALLATION.md` to copy `addons/popochiu-addons/` into your project and activate the plugin.  
2. Confirm Godot boots headless without missing resource warnings:  
   ```bash
   /usr/bin/godot --path . --headless --run
   ```  
3. Use the module deep dives in §5 of this guide for letterbox and PostFX specifics; `addons/popochiu-addons/doc/to-do/` houses QA checklists that remain project-specific.  
4. For a hands-on walkthrough that pairs letterbox presets with the CRT pipeline, read `addons/popochiu-addons/doc/cinematic_letterbox_postfx_tutorial.md`.  
5. Refer back here whenever you need architectural diagrams, API contracts, integration recipes, or troubleshooting tips.

---

## 3. Plugin Architecture

### 3.1 Directory Layout

```
addons/
  popochiu-addons/
    api/                # Runtime APIs exposed via autoloads and command wrappers
    gui/                # Drop-in GUI helpers that spawn controllers at runtime
    letterbox/          # Letterbox scenes, scripts, preset logic
    pfx/                # PostFX autoload, controller layer, shader + material
    wrappers/           # Autoload and command wrappers meant for projects
    doc/                # Module manuals, TODO checklists, feature notes
```

### 3.2 Runtime Relationships

```
Popochiu Project
├─ Autoload `G` -> addons/popochiu-addons/wrappers/g_autoload.gd
│    └─ Extends addons/popochiu-addons/api/g.gd
│        ├─ Delegates Letterbox calls to gui/letterbox_gui.gd + letterbox_api.gd
│        └─ Bridges PostFX helpers to autoload `PFX`
├─ Autoload `PFX` -> addons/popochiu-addons/pfx/pfx.gd
│    └─ Spawns/maintains CanvasLayer controllers per context
├─ GUI script -> extends addons/popochiu-addons/gui/letterbox_gui.gd
│    └─ Instantiates letterbox_controller.tscn on demand
└─ Optional Popochiu command script -> extends wrappers/gui_commands_wrapper.gd
     └─ Forwards command strings to the runtime APIs
```

Controllers (letterbox and PostFX) live entirely in the plugin directory. Projects typically keep their overrides in `game/` to remain upgrade-friendly.

---

## 4. Core Runtime APIs

### 4.1 `G` Autoload Highlights
- Entry point for cinematic helpers exposed to gameplay scripts.
- Provides synchronous and queue-ready versions of letterbox transitions.
- Exposes mirrored PostFX helpers so gameplay scripts rarely touch the raw `PFX` autoload.
- Persists configuration (e.g., registered presets) in memory; no project settings are written.

Key methods (full signatures in [Appendix](#13-appendix-signals--callbacks)):
- `show_letterbox(config := {})`
- `show_letterbox_preset(name: String, overrides := {})`
- `queue_show_letterbox(config := {})`
- `show_letterbox_with_pfx(letterbox_config, pfx_config, context := "global")`
- `list_letterbox_presets()` / `register_letterbox_preset()`
- `connect_letterbox_transition(target, method, flags := 0)`
- `apply_pfx_config(config := {}, context := "global", parent := null)`
- `set_pfx_feature(feature: String, enabled: bool, context := "global")`
- `get_pfx_param(param: String, context := "global")`
- `apply_pfx_room_config(room: Node, config := {}, context := "")`
- `clear_pfx_config(context := "global")` / `clear_pfx_room_config(room: Node, context := "")`
- `register_pfx_room_default(script_name: String, config := {})`
- `get_pfx_room_default(script_name: String) -> Dictionary`

### 4.2 `PFX` Autoload Highlights
- Manages a cache of PostFX controllers keyed by `context` strings (`"global"`, room-specific contexts, etc.).
- Duplicates the base material per controller to avoid mutating shared resources.
- Accepts configuration dictionaries that map directly to shader uniform names.
- Integrates with Popochiu command scripts through `gui_commands_wrapper.gd`.

Representative methods:
- `apply_config(config: Dictionary, context := "global", parent := null)`
- `merge_config(config: Dictionary, context := "global")`
- `set_feature(feature: String, enabled: bool, context := "global")`
- `set_param(param: String, value, context := "global")`
- `adjust_param(param: String, delta, min_value := null, max_value := null, context := "global")`
- `get_param(param: String, context := "global") -> Variant`
- `get_config(context := "global") -> Dictionary`
- `clear_config(context := "global")`
- `apply_room_config(room: Node, config: Dictionary, context := "")`
- `set_room_feature(room: Node, feature: String, enabled: bool, context := "")`
- `set_room_param(room: Node, param: String, value, context := "")`
- `clear_room_config(room: Node, context := "")`
- `register_room_default(script_name: String, config: Dictionary)` / `get_room_default(script_name: String) -> Dictionary`

See [Section 7](#7-configuration-reference) for config keys and value ranges.

---

## 5. Module Deep Dives

### 5.1 Letterbox Overlay

```
+----------------------------------+      +---------------------------------+
| game/gui/gui.gd                 |      | addons/popochiu-addons/wrappers/g_autoload.gd |
|  extends                        |      |  (Global Popochiu Addons interface)        |
| addons/popochiu-addons/gui/             |      |  • delegates to GUI/runtime helpers  |
| letterbox_gui.gd                |      +---------------------------------+
+----------------+----------------+
                 |
                 v instantiates
+-----------------------------------------------+
| addons/popochiu-addons/letterbox/letterbox.tscn       |
|  └─ Script: letterbox_controller.gd           |
|  • Animates four ColorRect bars               |
|  • Emits transition_finished                  |
+-----------------------------------------------+
                 |
                 v presets/utilities
+-----------------------------------------------+
| addons/popochiu-addons/letterbox/letterbox_api.gd     |
|  (PopochiuAddonsLetterbox)                         |
|  • Built-in preset catalogue (26 entries)     |
|  • Custom preset registration & helpers       |
|  • Used by autoload `G` for preset functions  |
+-----------------------------------------------+
```

**Installation & Migration**
1. Copy `addons/popochiu-addons/letterbox/`, `addons/popochiu-addons/gui/letterbox_gui.gd`, and `addons/popochiu-addons/wrappers/g_autoload.gd` into the project (or merge their helpers into existing overrides).
2. Register `G="*res://addons/popochiu-addons/wrappers/g_autoload.gd"` in `project.godot`.
3. Allow the GUI script to instantiate the controller at runtime; optional editor previews can place `letterbox.tscn` manually.
4. Run `/usr/bin/godot --path . --headless --run` and execute `G.show_letterbox_preset("cinematic_235")` to verify.

**Runtime API** (exposed via `G`)
```
G.show_letterbox(config := {}) -> Variant
G.hide_letterbox(config := {}) -> Variant
G.queue_show_letterbox(config := {}) -> Callable
G.queue_hide_letterbox(config := {}) -> Callable
G.is_letterbox_showing() -> bool
G.connect_letterbox_transition(target: Object, method: StringName, flags := 0) -> void
G.add_letterbox_transition_listener(callback: Callable, flags := 0) -> void
G.show_letterbox_preset(name: String, overrides := {}) -> Variant
G.queue_show_letterbox_preset(name: String, overrides := {}) -> Callable
G.show_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Variant
G.hide_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Variant
G.queue_show_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Callable
G.queue_hide_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Callable
G.list_letterbox_presets() -> PackedStringArray
G.get_letterbox_preset(name: String) -> Dictionary
G.has_letterbox_preset(name: String) -> bool
G.register_letterbox_preset(name: String, config: Dictionary, overwrite := false) -> void
```
`show_letterbox` / `hide_letterbox` return a tween `Signal` when animation occurs; guard awaits accordingly.

**Configuration Dictionary Keys**
- `aspect_ratio`: `float`/`Vector2`/`String` (`"21:9"`) — target ratio; overrides `pixels` when present.
- `orientation`: `"auto"` (default), `"horizontal"`, `"vertical"`, `"top_bottom"`, `"left_right"`.
- `pixels` or `pixel_amounts`: dictionary or 4-element container for explicit bar thicknesses (`top`, `bottom`, `left`, `right`).
- `duration`: seconds (default `0.45`); `0` snaps instantly.
- `speed`: optional multiplier dividing duration.
- `transition` / `ease`: `Tween.TransitionType` and `Tween.EaseType` controlling tween curves.
- `color`: bar tint (defaults to black).
- `block_gui` / `release_block`: control Popochiu GUI blocking lifetime.
- `wait` (`block_queue` alias): queue helpers await transition completion when `true`.

The controller also animates alpha; override `_schedule_alpha_tween` in `letterbox_controller.gd` for custom fades.

**Preset Catalogue**  
26 presets grouped by intent:
- *Cinematic*: `cinematic_235`, `cinematic_soft`, `cinematic_classic_185`, `cinematic_ultrawide_256`, `cinematic_scope_276`, `trailer_punch`, `teaser_fast`, `dream_sequence`.
- *Mood & Genre*: `noir_flashback`, `horror_focus`, `thriller_vertical`, `arcade_cabinet`, `retro_tv`, `handheld_portrait`, `vignette_intro`, `stealth_alert`, `wide_pan`, `pillarbox_169_thin`, `title_card_center`.
- *UI & Utility*: `pillarbox_43`, `top_bar_subtitle`, `bottom_bar_subtitle`, `documentary_caption`, `dialogue_focus_bottom`, `dialogue_focus_top`, `tutorial_banner`, `photo_slide`, `inventory_focus`, `instant_hide`.

Example customisation:
```gdscript
if not G.has_letterbox_preset("studio_custom"):
    G.register_letterbox_preset("studio_custom", {
        "aspect_ratio": "20:9",
        "duration": 0.45,
        "transition": Tween.TRANS_SINE,
        "ease": Tween.EASE_IN_OUT,
        "color": Color(0.0, 0.0, 0.0, 0.88),
        "block_gui": true
    })

G.show_letterbox_preset("studio_custom", {"duration": 0.6})
```

**Queue Integration**
```gdscript
Popochiu.queue([
    G.queue_show_letterbox({
        "aspect_ratio": Vector2(16, 9),
        "duration": 0.35,
        "wait": true,
        "block_gui": true
    }),
    func():
        G.show_system_text("Lights... Camera..."),
    G.queue_hide_letterbox({
        "duration": 0.5,
        "transition": Tween.TRANS_CUBIC,
        "ease": Tween.EASE_IN_OUT,
        "wait": true
    })
])
```

**Debugging**
- Absence of bars: ensure GUI extends `letterbox_gui.gd` and configurations specify non-zero thickness.
- GUI stuck blocked: set `release_block = true` or manually call `G.unblock()`.
- Instant transitions: use presets like `instant_hide` or set `duration = 0`.
- For verbose logging, temporarily sprinkle `print_debug()` statements inside `letterbox_controller.gd`.

**Performance**: Four `ColorRect` nodes with lightweight tweens; negligible CPU/GPU impact even on low-end devices.

---

### 5.2 PostFX Pipeline (CRT)

```
+--------------------------+         +----------------------------------+
| addons/popochiu-addons/wrappers/g_autoload.gd |         | addons/popochiu-addons/pfx/pfx.gd        |
|   (extends api/g.gd)      +-------->|  (PFX autoload facade)           |
+--------------------------+         |  _ensure_controller(context)     |
                                    |          |
                                    v          |
                         +------------------------------+
                         | CanvasLayer: PostFXController|
                         | (pfx/controller/postfx_controller.tscn)     |
                         +------------------------------+
                                    |
                                    v
                      pfx/shaders/postfx_pipeline.shader.gdshader
                                   + postfx_pipeline.tres
```

**Installation & Migration**
1. Copy `addons/popochiu-addons/pfx/` (autoload, controller, shader assets) and optional command helpers (`addons/popochiu-addons/api/gui_commands.gd`).
2. Register `PFX="*res://addons/popochiu-addons/pfx/pfx.gd"` in `project.godot` after `G`.
3. Optionally extend your Popochiu command script from `addons/popochiu-addons/wrappers/gui_commands_wrapper.gd`.
4. Verify `postfx_pipeline.tres` resolves its shader and run `godot --headless --run`.
5. For room-specific looks, call `PFX.ensure_room_controller(room)` when rooms load.

**Autoload API Highlights**
- `apply_config(config: Dictionary, context := "global", parent := null)`: create/ensure a controller, duplicate the base material, apply config immediately (queued until controller `ready` if needed).
- `merge_config(config, context := "global")`: shallow merge into cached config.
- `set_feature(feature: String, enabled: bool, context := "global")`: toggle features such as `"crt"`.
- `set_param(param: String, value, context := "global")`: assign a single uniform.
- `get_param(param: String, default := null, context := "global")`: read back a uniform.
- `clear_config(context := "global")`: reset and free the controller for a context.
- `ensure_room_controller(room: Node, context := "")`: spawn a controller under a room node (`context` defaults to `room_<RoomName>`).
- `dump_contexts() -> Dictionary`: debug utility returning cached configs and readiness.

Controllers duplicate `postfx_pipeline.tres` so direct edits to the `.tres` affect new controllers only.

**Shader Parameters (Summary)**
- *Screen sampling*: `crt_use_screen_uv`, `crt_resolution`.
- *Scanlines & grille*: `crt_scan_line_amount`, `crt_scan_line_strength`, `crt_grille_amount`, `crt_grille_size`, `crt_pixel_strength`.
- *Geometry & vignette*: `crt_warp_amount`, `crt_vignette_amount`, `crt_vignette_intensity`.
- *Noise & interference*: `crt_noise_amount`, `crt_interference_amount`.
- *Chromatic & rolling effects*: `crt_aberration_amount`, `crt_roll_line_amount`, `crt_roll_speed`.
- *Feature toggles*: `fx_enabled`, `crt_enabled`.

All keys map 1:1 with configuration dictionaries; values are documented in §7.2.

**Configuration Patterns**
```gdscript
const GLOBAL_FX := {
    "fx_enabled": true,
    "crt_enabled": true,
    "crt_resolution": Vector2(320, 180),
    "crt_scan_line_amount": 0.9,
    "crt_warp_amount": 0.15,
    "crt_noise_amount": 0.02,
    "crt_interference_amount": 0.18,
    "crt_vignette_amount": 0.55,
    "crt_vignette_intensity": 0.35,
    "crt_aberration_amount": 0.4,
    "crt_roll_line_amount": 0.12,
    "crt_roll_speed": 0.6,
    "crt_pixel_strength": -2.5
}

func _ready() -> void:
    if Engine.is_editor_hint():
        return
    PFX.apply_config(GLOBAL_FX)
```

User options:
```gdscript
func set_scanline_slider(value: float) -> void:
    PFX.set_param("crt_scan_line_amount", clampf(value, 0.0, 1.0))
```

Cutscene transitions:
```gdscript
Popochiu.queue([
    G.queue_show_letterbox_with_pfx(
        {"aspect_ratio": "21:9", "wait": true, "block_gui": true},
        {"crt_noise_amount": 0.1, "crt_vignette_amount": 0.9}
    ),
    func():
        start_cutscene_dialog(),
    G.queue_hide_letterbox_with_pfx({"wait": true}, {"crt_noise_amount": 0.03})
])
```

**Debugging**
- “Material not ready”: controller `_ready()` not complete—autoload queues configs automatically; avoid manual controller instantiation unless necessary.
- No visual change: ensure `fx_enabled`/`crt_enabled` are true and you are applying configs via the autoload rather than editing the base `.tres`.
- Shader warnings: rebuild import cache or confirm Godot 4.5 compatibility.
- Controller leaks: prefer `apply_config`/`clear_config`; controllers clean themselves when their parent exits the tree.

**Performance**
- Single-pass canvas shader; most cost driven by high `crt_resolution`, aggressive noise, or chromatic aberration.
- Disable PostFX for non-gameplay UI scenes by toggling `fx_enabled` or clearing contexts.
- Combine with letterbox system at minimal overhead—the overlay bars do not impact the shader.

**Future Enhancements**
- Parameter preset assets for alternate looks (LCD, VHS).
- Editor tooling for in-editor previews.
- Time-driven degrade curves for retro sequences.
- Cross-module sync with audio/lighting roadmaps.

---

---

## 6. Integration Workflows

### 6.1 Popochiu Queue Sequences
Leverage queue helpers for cinematic beats:
```gdscript
Popochiu.queue([
    G.queue_show_letterbox_preset("cinematic_235", {"wait": true, "block_gui": true}),
    func():
        PFX.apply_config({"crt_noise_amount": 0.15}, "global"),
    G.queue_hide_letterbox_preset("instant_hide", {"wait": true})
])
```
`wait` (alias `block_queue`) determines whether the callable awaits transition completion before proceeding.

### 6.2 Combining Letterbox & PostFX
Use the paired helpers when a transition should also tweak CRT settings:
```gdscript
G.show_letterbox_with_pfx(
    {"aspect_ratio": "21:9", "block_gui": true},
    {"crt_enabled": true, "crt_warp_amount": 0.25, "crt_noise_amount": 0.12}
)
```
Queue variants (`queue_show_letterbox_with_pfx`) return callables that you can drop into `Popochiu.queue`.

### 6.3 Custom GUI Overrides
- Extend `gui/letterbox_gui.gd` and add project-specific functionality (e.g., analytics when bars show).
- If you need editor previews, manually place `letterbox.tscn` under your GUI scene; runtime scripts detect the existing node and reuse it.

### 6.4 Per-Room PostFX Contexts
- Call `PFX.ensure_room_controller(room)` to spawn a controller as a child of a room for local effects.
- Apply room presets as rooms enter:
  ```gdscript
  func _on_room_entered(room: Node):
      PFX.apply_config(ROOM_LOOKUP.get(room.name, {}), "room_%s" % room.name)
  ```

### 6.5 Popochiu Command Hooks
- The shipped wrapper (`wrappers/gui_commands_wrapper.gd`) extends Popochiu’s command script and forwards custom commands such as `"enable_crt"` or `"letterbox_preset"`.
- Duplicate or modify the handlers to fit your command naming conventions.

---

## 7. Configuration Reference

### 7.1 Letterbox Keys
| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `aspect_ratio` | `float`/`Vector2`/`String` | `null` | Target ratio (width ÷ height). When null, retains current ratio or defers to `pixels`. |
| `orientation` | `String` (`"auto"`, `"horizontal"`, `"vertical"`, `"top_bottom"`, `"left_right"`) | `"auto"` | Overrides how the controller decides which bars animate. |
| `pixels` / `pixel_amounts` | 4-value container | `{}` | Directly set top/bottom/left/right thickness in pixels. |
| `duration` | `float` (seconds) | `0.45` | Tween length. Use `0` for instant transitions. |
| `speed` | `float` | `null` | Multiplier applied to duration (`duration /= speed`). |
| `transition` | `Tween.TransitionType` | `Tween.TRANS_QUINT` | Curve type. |
| `ease` | `Tween.EaseType` | `Tween.EASE_OUT` | Easing option. |
| `color` | `Color`/compatible | `Color.BLACK` | Tint for all bars. |
| `block_gui` | `bool` | `false` | Calls `G.block()` during show. |
| `release_block` | `bool` | `true` | Releases GUI block on hide. |
| `wait` / `block_queue` | `bool` | `false` | Queue helpers await tween completion when true. |

Preset catalogue and usage examples appear in §5.1.

### 7.2 PostFX Keys (subset)
| Key | Type | Range | Default | Notes |
|-----|------|-------|---------|-------|
| `fx_enabled` | `bool` | `{false, true}` | `true` | Master toggle; disables the controller when false. |
| `crt_enabled` | `bool` | `{false, true}` | `true` | Enables CRT-specific features. |
| `crt_resolution` | `Vector2` | > 0 | `(320, 180)` | Virtual pixel grid size. |
| `crt_scan_line_amount` | `float` | `[0, 1]` | `1.0` | Scanline intensity. |
| `crt_scan_line_strength` | `float` | `[-12, -1]` | `-8.0` | Brightness contrast for scanlines. |
| `crt_grille_amount` | `float` | `[0, 1]` | `0.1` | RGB grille strength. |
| `crt_warp_amount` | `float` | `[0, 5]` | `0.1` | Barrel distortion magnitude. |
| `crt_vignette_amount` | `float` | `[0, 2]` | `0.6` | Vignette coverage. |
| `crt_vignette_intensity` | `float` | `[0, 1]` | `0.4` | Vignette hardness. |
| `crt_noise_amount` | `float` | `[0, 0.3]` | `0.03` | Animated white noise. |
| `crt_interference_amount` | `float` | `[0, 1]` | `0.2` | Horizontal interference. |
| `crt_aberration_amount` | `float` | `[0, 1]` | `0.5` | Chromatic separation. |
| `crt_roll_line_amount` | `float` | `[0, 1]` | `0.3` | Rolling scanline strength. |
| `crt_roll_speed` | `float` | `[-8, 8]` | `1.0` | Direction & speed of roll. |
| `crt_pixel_strength` | `float` | `[-4, 0]` | `-2.0` | Pixel brightness curve. |

Section 5.2 expands on each parameter family with usage tips and code examples.

---

## 8. Testing & QA

- **Automated Sanity**:  
  `godot --path . --headless --run` catches missing resources or syntax errors introduced by custom overrides.
- **Functional Checks** (after install or feature work):  
  - `G.show_letterbox_preset("cinematic_235")` should tween bars in and emit `transition_finished`.  
  - `G.queue_hide_letterbox_preset("instant_hide", {"wait": true})` should retract instantly without errors.  
  - `PFX.apply_config({"crt_enabled": true, "crt_noise_amount": 0.1})` should update the CRT overlay live.  
  - Combined helper `G.show_letterbox_with_pfx(...)` should leave both systems in their expected states.  
- **Visual QA**: Follow `doc/to-do/letterbox_todo.md` for preset-by-preset verification and create project-specific checklists for PostFX contexts.
- **Regression Strategy**: Maintain sample cutscene scripts invoking the queue helpers; run them in editor builds to confirm transitions after plugin updates.

---

## 9. Debugging & Troubleshooting

| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
| Letterbox never appears | GUI script not extending `letterbox_gui.gd`, controller freed, or config sets zero thickness. | Confirm GUI inheritance and check preset values; ensure the controller node exists in the running scene tree. |
| GUI remains blocked after hide | `release_block = false` or manual `G.block()` without matching `G.unblock()`. | Pass `{"release_block": true}` to hide call or manually invoke `G.unblock()`. |
| PostFX parameters ignore changes | Context mismatch or `fx_enabled = false`. | Log the `context` string, verify `PFX.dump_contexts()` (see §13) lists it, and reapply config with `fx_enabled = true`. |
| Shader compilation errors | Missing shader resource or incompatible Godot version. | Ensure `postfx_pipeline.shader.gdshader` loads; reimport if necessary and confirm running on Godot 4.5+. |
| Queue hang | Helpers waiting for tween that never fires (e.g., duration zero but wait true). | For instant transitions, prefer presets like `instant_hide` or set `wait = false`. |

Add temporary `print_debug` statements inside controllers (`letterbox_controller.gd`, `postfx_controller.gd`) to inspect config dictionaries at runtime.

---

## 10. Performance Notes

- Letterbox bars are lightweight `ColorRect` nodes; transitions animate thickness and alpha only, generating minimal GC pressure.
- PostFX uses a single-pass canvas shader. Most cost comes from high `crt_resolution` values or heavy noise settings; profile on low-end hardware if you raise defaults.
- Controllers duplicate materials per context, so memory usage scales with the number of active contexts rather than frame count.
- Disable unused contexts (`PFX.clear_config("context_name")`) to free materials when leaving heavyweight scenes.

---

## 11. Extensibility & Roadmap

Known expansion areas tracked in `doc/to-do/`:
- Audio engine enhancements (layered cues, stingers, category mixing).
- 2D lighting toolkit with drag-and-drop presets.
- Gamepad-first interaction revamp inspired by *Policenauts* / *ROM: 2064*.
- Advanced dialogue UX (radial menus, timed choices, preview tooling).
- Portrait and speech FX upgrades (animated layers, text FX).

Extension tips:
- Register custom letterbox presets during project boot (`G.register_letterbox_preset(...)`).
- Fork `pfx.gd` to add new shader parameters or feature toggles; keep context cache behaviour consistent.
- Create editor scripts to preview presets or PostFX states—controllers can be instantiated in tool scripts for design tooling.

---

## 12. File Index

| Path | Purpose |
|------|---------|
| `addons/popochiu-addons/api/g.gd` | Core autoload API consumed by wrapper `G`. |
| `addons/popochiu-addons/api/gui_commands.gd` | Popochiu command helpers (forward commands to runtime). |
| `addons/popochiu-addons/gui/letterbox_gui.gd` | GUI base script instantiating the letterbox controller. |
| `addons/popochiu-addons/letterbox/letterbox_controller.gd` | Handles letterbox tweens, signals, and blocking state. |
| `addons/popochiu-addons/letterbox/letterbox_api.gd` | Preset catalogue and registration helpers. |
| `addons/popochiu-addons/pfx/pfx.gd` | PostFX autoload facade (context management + config). |
| `addons/popochiu-addons/pfx/controller/postfx_controller.gd` | CanvasLayer applying shader material per context. |
| `addons/popochiu-addons/pfx/shaders/postfx_pipeline.shader.gdshader` | CRT post-processing shader. |
| `addons/popochiu-addons/pfx/shaders/postfx_pipeline.tres` | Base material duplicated for each controller instance. |
| `addons/popochiu-addons/wrappers/g_autoload.gd` | Drop-in autoload that extends `api/g.gd`. |
| `addons/popochiu-addons/wrappers/gui_commands_wrapper.gd` | Command wrapper extending `api/gui_commands.gd`. |
| `INSTALLATION.md` | Root-level quick-start checklist for installing the plugin. |
| `POPOCHIU_ADDONS_DOCUMENTATION.md` | Comprehensive technical reference for the plugin. |
| `addons/popochiu-addons/doc/to-do/letterbox_todo.md` | QA checklist and enhancement backlog for the letterbox module. |
| `addons/popochiu-addons/doc/popochiu-addons_features.md` | Feature overview exported alongside releases. |

---

## 13. Appendix: Signals & Callbacks

### 13.1 Letterbox Signals
- `transition_finished(is_showing: bool)` emitted by `letterbox_controller.gd`.  
  Use `G.connect_letterbox_transition(target, method)` or `G.add_letterbox_transition_listener(callable)` to listen globally.

### 13.2 PostFX Hooks
- `PFX` emits controller lifecycle logs via `print_debug` when `debug_enabled` is true (toggle inside `pfx.gd`).
- Inspect context cache with `PFX.dump_contexts()` (utility method returning a dictionary of cached configs and controller readiness).

### 13.3 Queue Helpers
- `G.queue_show_letterbox(...)` / `G.queue_hide_letterbox(...)` return `Callable` objects compatible with `Popochiu.queue`.
- `_Callable`s respect the `wait` flag; when true they `await transition_finished`. For zero-duration transitions, set `wait = false` to avoid unnecessary yields.

---

Use this document as the team’s shared knowledge base when extending Popochiu Addons, onboarding new contributors, or porting the plugin into fresh Popochiu projects. Keep the guide updated alongside code changes so cinematic tooling remains discoverable and maintainable.
