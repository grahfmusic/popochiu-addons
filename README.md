# Popochiu Addons Plugin

Add-on systems that layer cinematic presentation tools on top of Popochiu 2.0 without touching the framework core. The plugin currently bundles a letterbox overlay with queue helpers and a CRT-inspired PostFX pipeline, all packaged as a Godot 4.5 plugin ready to drop into existing adventure projects.

---

## Quick Start
1. Clone or copy this repository alongside your Popochiu project.
2. Follow `INSTALLATION.md` to copy `addons/popochiu-addons/` into your project and enable the plugin.
3. Run `/usr/bin/godot --path . --headless --run` from your project root to confirm resources and autoloads are wired correctly.
4. Call `G.show_letterbox_preset("cinematic_235")`, `G.fade_prop_in("Lamp", {"duration": 0.5})`, or `PFX.apply_config({"crt_enabled": true})` in-game to verify all systems are active.

---

## Key Modules
- **Letterbox Overlay** – Runtime controller with 26 presets, tweenable transitions, Popochiu queue helpers, and GUI blocking coordination.  
  *Entry point:* `addons/popochiu-addons/gui/letterbox_gui.gd` / `addons/popochiu-addons/letterbox/`.  
  *Reference:* `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.1).

- **PostFX Pipeline (CRT)** – CanvasLayer-based PostFX controller with configurable scanlines, noise, curvature, chromatic aberration, and room-scoped contexts.
  *Entry point:* `addons/popochiu-addons/pfx/pfx.gd` / `addons/popochiu-addons/pfx/controller/`.
  *Reference:* `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.2).

- **Prop Fade Helpers** – Popochiu-safe prop tween helpers that fade any `CanvasItem` by alpha with optional queue blocking.
  *Entry point:* `addons/popochiu-addons/api/popochiu_helper.gd` / `addons/popochiu-addons/wrappers/popochiu_helper.gd`.
  *Reference:* `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.3).

Upcoming work (tracked in `addons/popochiu-addons/doc/to-do/`) includes audio layering, lighting presets, dialogue UX upgrades, and additional cinematic helpers.

---

## Documentation Map
- `INSTALLATION.md` – Step-by-step setup checklist.
- `POPOCHIU_ADDONS_DOCUMENTATION.md` – Comprehensive technical guide covering architecture, APIs, configuration, debugging, and performance.
- `addons/popochiu-addons/doc/popochiu-addons_features.md` – Feature index for porting the plugin into new Popochiu projects.
- `addons/popochiu-addons/doc/cinematic_letterbox_postfx_tutorial.md` – Hands-on walkthrough for blending letterbox cues with the CRT PostFX stack.
- `addons/popochiu-addons/doc/to-do/letterbox_todo.md` – QA checklist and enhancement backlog.

---

## Repository Layout
```text
.
├─ addons/
│  └─ popochiu-addons/
│     ├─ api/          # Runtime APIs surfaced through autoload wrappers
│     ├─ gui/          # Drop-in GUI helpers (spawns letterbox controller)
│     ├─ letterbox/    # Letterbox scenes, presets, controllers
│     ├─ pfx/          # PostFX autoload, controllers, shader assets
│     ├─ wrappers/     # Autoload + command wrappers for Popochiu projects
│     └─ doc/          # Feature index, TODO lists, migration notes
├─ INSTALLATION.md
├─ POPOCHIU_ADDONS_DOCUMENTATION.md
└─ README.md
```

---

## Contributing
- Keep reusable code inside `addons/popochiu-addons/`; use thin wrappers in `game/` for project-specific overrides.
- Update `POPOCHIU_ADDONS_DOCUMENTATION.md` and the feature index when behaviour, APIs, or file locations change.
- Run the headless Godot sanity check before sharing merge requests to catch missing resources.
- Use Git commits/merge requests that focus on a single module (e.g., `letterbox`, `pfx`) to keep history clear.

---

## Support & Contact
Issues, feature requests, and design discussions should link to the relevant sections of `POPOCHIU_ADDONS_DOCUMENTATION.md` and the TODO lists so future maintainers can trace decisions quickly. Feel free to expand the documentation as new modules land.
