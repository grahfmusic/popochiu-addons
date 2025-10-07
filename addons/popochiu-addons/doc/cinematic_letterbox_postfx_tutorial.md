# Cinematic Letterbox & PostFX Tutorial

## Prerequisites
- Godot 4.5 project with Popochiu 2.0 installed.
- `addons/popochiu-addons/` copied into your project and enabled in the Project Settings.
- Autoloads registered: `G` → `res://addons/popochiu-addons/wrappers/g_autoload.gd`, `PFX` → `res://addons/popochiu-addons/pfx/pfx.gd`.

## Step 1 — Verify the Plugin Boots
From your project root run the headless sanity check to catch missing resources before opening the editor:
```bash
/usr/bin/godot --path . --headless --run
```
If the command reports missing nodes or scripts, confirm the autoload paths and that `.uid` files stayed intact during import.

## Step 2 — Drop the Letterbox GUI
Attach `addons/popochiu-addons/gui/letterbox_gui.gd` to the Popochiu GUI scene (usually `res://game/gui/gui.gd`). The script auto-spawns `PopochiuAddonsLetterbox` on first use, so no extra nodes are needed in the editor. The controller exposes `transition_finished`, which the autoload forwards through `G.connect_letterbox_transition`.

## Step 3 — Script a Cinematic Beat
Use the `G` autoload inside a Popochiu room or cutscene to blend a letterbox transition with the CRT pipeline:

```gdscript
extends Node

func _ready() -> void:
	# Fade in a cinematic crop while enabling CRT noise.
	await G.queue_show_letterbox_with_pfx(
		{
			"preset": "cinematic_235",
			"duration": 0.45
		},
		{
			"fx_enabled": true,
			"crt_enabled": true,
			"crt_noise_amount": 0.08,
			"crt_scan_line_amount": 0.9
		},
		"intro"
	).call()

	# Wait for a story beat before restoring the default look.
	await get_tree().create_timer(2.0).timeout
	await G.queue_hide_letterbox_with_pfx(
		{},
		{"fx_enabled": false},
		"intro"
	).call()
```

> Tip: `queue_*` variants return callables you can await or enqueue alongside Popochiu command queues.

## Step 4 — Define Custom Presets
Keep cinematic variants reusable by registering presets during initialization:

```gdscript
func _ready() -> void:
	var presets := {
		"flashback": {
			"aspect_ratio": "4:3",
			"color": Color(0.05, 0.05, 0.1, 0.95),
			"duration": 0.6
		}
	}
	for name in presets.keys():
		G.register_letterbox_preset(name, presets[name], true)
```

Presets live entirely in memory. Use `G.list_letterbox_presets()` in the debugger to confirm registrations, and pass overrides to `G.show_letterbox_preset("flashback", {"duration": 0.3})` for scene-specific tweaks.

## Step 5 — Room-Specific PostFX
Bind CRT defaults to Popochiu rooms so each location carries its own look by responding to Popochiu’s room lifecycle:

```gdscript
func _on_room_entered() -> void:
	if Engine.is_editor_hint():
		return
	G.apply_pfx_room_config(
		self,
		G.get_pfx_room_default("start")  # or inline a config dictionary here
	)
```

Populate `PFX.ROOM_DEFAULTS` (or call `G.register_pfx_room_default()`) with lowercase room names so `G.get_pfx_room_default("start")` returns the expected preset. Controllers are created on demand and keyed by the resolved context (`room_start` in this example). Call `G.clear_pfx_room_config(self)` when a room should revert to the global preset.

## Step 6 — Drive Transitions from Popochiu Commands
Expose cinematic beats to writers by mapping Popochiu commands through the provided wrapper:

```gdscript
extends "res://addons/popochiu-addons/wrappers/gui_commands_wrapper.gd"

func execute_custom_commands(command: String, args: Dictionary) -> bool:
	match command:
		"letterbox_flashback":
			G.show_letterbox_with_pfx(
				{"preset": "flashback"},
				{"fx_enabled": true, "crt_enabled": true, "crt_aberration_amount": 0.28},
				args.get("context", "flashback")
			)
			return true
		"letterbox_clear":
			G.hide_letterbox_with_pfx(
				{},
				{"fx_enabled": false},
				args.get("context", "flashback")
			)
			return true
		_:
			return false
```

With the command registered, writers can add lines such as `@letterbox_flashback context=intro` to Popochiu scripts without touching GDScript.

## Step 7 — Bake Automated Regression Tests
Create a lightweight harness under `addons/popochiu-addons/doc/tests/` to ensure presets survive refactors:

```gdscript
extends SceneTree

func _init() -> void:
	var preset := G.get_letterbox_preset("cinematic_235")
	assert(preset.has("aspect_ratio"))
	G.show_letterbox_with_pfx({}, {"fx_enabled": true})
	assert(G.is_letterbox_showing())
	await get_tree().process_frame
	G.hide_letterbox_with_pfx({}, {"fx_enabled": false})
	quit()
```

Run it via `/usr/bin/godot --path . --headless --run addons/popochiu-addons/doc/tests/test_letterbox_pfx.gd`. Integrate this command into CI if the consuming project already runs headless checks.

## Step 8 — Debugging Checklist
- **Letterbox does not appear:** Ensure the GUI scene uses `letterbox_gui.gd` and that no other script renames the instance away from `PopochiuAddonsLetterbox`.
- **PostFX ignored:** Verify the `PFX` autoload is registered and the controller scenes (`postfx_controller.tscn`) stay in `addons/popochiu-addons/pfx/controller/`. Log `G.get_pfx_param("crt_enabled")` to confirm uniforms reach the shader.
- **UID churn:** When Godot regenerates `.uid` files, propagate them to version control; mismatched UIDs cause hidden resource lookups to fail during headless runs.
- **Queue timing issues:** Prefer the `queue_*` helpers, and await their returned callable to align with Popochiu's command scheduler. Mixing synchronous and queue-based calls can leave in-game cinematics half transitioned.

## Step 9 — Suggested Next Steps
1. Extend presets with HDR-safe colors or per-language subtitle bands.
2. Add a Popochiu dialog hook that toggles gentle letterboxing whenever a conversation starts.
3. Record a short capture of the CRT pipeline to showcase expected visuals inside PR descriptions.
