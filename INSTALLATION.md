# Popochiu Addons Setup Guide

Version 1.1 · Target platforms: Godot 4.5 / Popochiu 2.0  
Maintained by the Popochiu Addons team

This document walks through dropping the Popochiu Addons plugin into an existing Popochiu project without touching the Popochiu core. Follow the steps to copy the assets, hook up the autoloads, and confirm that the letterbox and PostFX helpers are ready to use.

---

## 1. Before You Start
- Working Popochiu project built with Godot 4.5 (Popochiu 2.0 or newer).
- Awareness of the project layout (`game/autoloads`, `game/gui`, etc.).
- Ability to edit `project.godot` and relevant scripts/scenes.
- A local copy of `addons/popochiu-addons/` from this repository.

---

## 2. Expected Folder Structure
After copying the plugin, the directory tree should look like this inside your project:

```
res://addons/
  popochiu-addons/
    api/
      g.gd
      gui_commands.gd
    gui/
      letterbox_gui.gd
    letterbox/
      letterbox_controller.gd
      letterbox.tscn
      letterbox_api.gd
    pfx/
      pfx.gd
      controller/
        postfx_controller.gd
        postfx_controller.tscn
      shaders/
        postfx_pipeline.shader.gdshader
        postfx_pipeline.tres
    wrappers/
      g_autoload.gd
      gui_commands_wrapper.gd
      popochiu_helper.gd
    doc/
      to-do/
        letterbox_todo.md

res://game/
  autoloads/g.gd        (optional override that extends the wrapper)
  gui/gui.gd            (optional GUI override that extends the helper)
```

Everything the plugin references resides under `addons/popochiu-addons/`, so keeping that directory intact is the only structural requirement.

---

## 3. Installation Checklist

### 3.1 Copy the plugin
Duplicate the entire `addons/popochiu-addons/` folder into your project. Remove any existing version first to avoid outdated assets hanging around.

### 3.2 Enable the plugin
In Godot open `Project → Project Settings → Plugins` and enable **Popochiu Addons**.  
When enabled, the plugin registers these autoloads:
- `PFX="*res://addons/popochiu-addons/pfx/pfx.gd"`
- `G="*res://addons/popochiu-addons/wrappers/g_autoload.gd"`
- `PopochiuHelper="*res://addons/popochiu-addons/wrappers/popochiu_helper.gd"`

Previous autoload configurations are stored in `ProjectSettings["addons/popochiu-addons/autoload_backups"]` in case you need to revert.

### 3.3 Point your scripts at the helpers
Update your project-level scripts so they extend the plugin utilities (the helper autoload is added automatically):
- GUI script: `extends "res://addons/popochiu-addons/gui/letterbox_gui.gd"`
- Autoload override (if you manage `G` manually): `extends "res://addons/popochiu-addons/api/g.gd"`
- Helper override (if you ship a custom one): `extends "res://addons/popochiu-addons/api/popochiu_helper.gd"`
- Command script (optional): `extends "res://addons/popochiu-addons/wrappers/gui_commands_wrapper.gd"`

If you maintain custom scripts, copy the required helper logic (letterbox transitions, PostFX hooks) into your overrides.

### 3.4 Confirm scenes and resources
Open these resources in Godot to ensure the paths resolve correctly:
- `res://addons/popochiu-addons/letterbox/letterbox.tscn`
- `res://addons/popochiu-addons/pfx/controller/postfx_controller.tscn`
- `res://addons/popochiu-addons/pfx/shaders/postfx_pipeline.tres`

### 3.5 Run a quick automated check
From the project root execute:

```bash
/usr/bin/godot --path . --headless --run
```

If Godot warns about missing files, revisit the previous steps and confirm the paths and autoloads.

---

## 4. Post-Install Smoke Tests
- Call `G.show_letterbox_preset("cinematic_235")` and verify the widescreen bars animate in.
- Run `PFX.apply_config({"fx_enabled": true, "crt_enabled": true})` to confirm the CRT overlay appears.
- Ensure queued helpers (`await G.queue_hide_letterbox_preset("instant_hide")()`) complete without errors.
- Check `addons/popochiu-addons/doc/to-do/letterbox_todo.md` for extra QA pointers.

---

## 5. Removing or Rolling Back
- Disable **Popochiu Addons** in `Project Settings`.
- Update or remove the `G` and `PFX` autoload entries if you customised them.
- Delete `addons/popochiu-addons/` to remove the plugin files.

The original autoload assignments remain stored in `ProjectSettings["addons/popochiu-addons/autoload_backups"]` should you need them.

---

## 6. Quick Answers

**Can I keep only the letterbox features?**  
Yes. Leave the plugin active but skip the PostFX helper calls—the letterbox system works independently.

**How do I add new letterbox presets?**  
Use `G.register_letterbox_preset("my_preset", config_dict)` or extend `PopochiuAddonsLetterbox.PRESETS`. Examples live in `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.1).

**Where can I tweak PostFX defaults?**  
Edit `addons/popochiu-addons/pfx/pfx.gd` to adjust `ROOM_DEFAULTS`, or create custom presets and apply them with `PFX.apply_config`. See `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.2) for parameter guidance.

**Does this survive Popochiu upgrades?**  
Yes. The plugin layers functionality through autoloads and GUI extensions without touching Popochiu core files. If Popochiu changes its autoload signatures, update the plugin wrappers accordingly.
