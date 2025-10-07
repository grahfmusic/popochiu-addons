# Popochiu Addons

> Cinematic extensions for Popochiu adventures, packaged for reuse and easy GitLab collaboration.
> Formerly released as the Snautchiu Feature Pack; naming now matches the in-editor plugin.

For the full technical reference, see the root-level guide: [`POPOCHIU_ADDONS_DOCUMENTATION.md`](../../POPOCHIU_ADDONS_DOCUMENTATION.md).

## Table of Contents
- [Overview](#overview)
- [Philosophy](#philosophy)
- [Quick Start](#quick-start)
- [Module Index](#module-index)
- [Roadmap](#roadmap)
- [Repository Layout](#repository-layout)
- [GitLab Workflow](#gitlab-workflow)
- [Documentation & Support](#documentation--support)

## Overview
Popochiu Addons is a modular suite of gameplay and presentation systems that layers on top of Popochiu without modifying its core. Popochiu delivers point-and-click fundamentals; Popochiu Addons adds cinematic tooling, modern interaction patterns, and a path toward richer audiovisual experiences. This README is the landing page for the feature pack inside GitLab projects and links to the deeper manuals that ship with each module.

## Philosophy
- **Additive, not invasive**: Core Popochiu Addons code ships as a Godot plugin under `addons/popochiu-addons/`, while game-specific wrappers stay thin so Popochiu updates remain painless.
- **Cinematic-first**: Focus on presentation—letterboxing, post-processing, audio, lighting—so Popochiu games feel contemporary while retaining adventure tooling.
- **Gamepad-friendly**: Interaction systems target hybrid experiences inspired by titles like *Read Only Memories* and *Policenauts*.
- **Composable**: Each module ships with docs, presets, and migration notes to drop into new projects quickly.

## Quick Start
1. Clone or fork the GitLab project that includes Popochiu Addons alongside Popochiu.
2. Enable the `Popochiu Addons` plugin (`Project > Project Settings > Plugins`).
3. Register the required autoloads (e.g. `PFX="*res://addons/popochiu-addons/pfx/pfx.gd"`) and ensure your project GUI scripts extend the provided wrappers (see Module Index).
4. Confirm `/usr/bin/godot --path . --headless --run` boots without missing resource warnings before pushing a GitLab merge request.

## Module Index
### Letterbox Overlay
- Tweened widescreen and pillarbox bars with GUI-aware blocking.
- Twenty-six presets, queue helpers, PostFX combinations, and transition signals.
- Files: `addons/popochiu-addons/letterbox/`, `addons/popochiu-addons/api/g.gd`, wrapper autoload `addons/popochiu-addons/wrappers/g_autoload.gd`, optional runtime GUI hook in `addons/popochiu-addons/gui/letterbox_gui.gd`.
- Documentation: `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.1) plus TODOs under `addons/popochiu-addons/doc/to-do/`.
- Notes: The Popochiu Addons autoload instantiates a `PopochiuAddonsLetterbox` node at runtime if the GUI scene lacks one.

### PostFX Pipeline (CRT)
- Modular autoload for CRT-style post-processing.
- Supports per-room presets, feature toggles, parameter adjustments, and Popochiu command hooks.
- Files: `addons/popochiu-addons/pfx/` (including `pfx/controller/` assets) and `addons/popochiu-addons/wrappers/gui_commands_wrapper.gd` for Popochiu command bridging.
- Documentation: `POPOCHIU_ADDONS_DOCUMENTATION.md` (§5.2).

## Roadmap
Planned modules live on the team issue board; highlights include:
1. **Audio Engine Enhancements**: Layered music cues, dynamic stingers, SFX categories, spatial mixing. Target future path `addons/popochiu-addons/audio/` with Popochiu command hooks.
2. **2D Lighting Toolkit**: Drag-and-drop lighting presets and designer-friendly controls compatible with existing Popochiu rooms.
3. **Gamepad-Driven Interaction Overhaul**: First-person navigation and hotspot handling inspired by *Policenauts* and *Read Only Memories*.
4. **Modern Dialogue System**: Icon or radial menus, timed choices, branching preview tools with gamepad support.
5. **Portrait & Speech Improvements**: Advanced portrait layering, dynamic speech bubbles, FX-driven text reveals.

Further ideas and checklists live in `addons/popochiu-addons/doc/to-do/`.

## Repository Layout
```text
addons/
  popochiu-addons/
    api/        # Runtime APIs consumed by autoload wrappers
    gui/        # Drop-in GUI scripts that spawn and manage Popochiu Addons systems
    letterbox/  # Letterbox overlay module assets and scripts
    pfx/        # PostFX pipeline (CRT) assets, controller scripts, presets
    wrappers/   # Autoload + command wrappers distributed with the plugin
    doc/        # Manuals, TODOs, and export notes for each module
```

Keep project-specific overrides in `game/` so Popochiu upgrades remain straightforward.

## GitLab Workflow
- Track module TODOs, roadmap items, and integration requests via issue tracking; link the relevant manual or TODO checklist in each ticket.
- Use scoped, imperative merge request subjects (e.g. `Add letterbox popfx bridge`) and document manual testing performed.
- Run `/usr/bin/godot --path . --headless --run` locally before sharing builds to catch missing resource warnings.
- Group roadmap work by module (`letterbox`, `pfx`, `audio`) so contributors can navigate open tasks quickly.

## Documentation & Support
- Primary references live in `POPOCHIU_ADDONS_DOCUMENTATION.md`; supplement with the TODO checklists under `addons/popochiu-addons/doc/` when sharing modules to other repositories.
- Update this README and `doc/popochiu-addons_features.md` whenever a module changes behavior or dependencies.
- For discussions, use GitLab comments so design decisions stay discoverable alongside the code history.

Happy launching cinematic adventures on Popochiu!
