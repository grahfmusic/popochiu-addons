# Repository Guidelines

## Project Structure & Module Organization
The Godot plugin ships inside `addons/popochiu-addons/`; keep all reusable logic there so projects can copy the folder wholesale. Key directories: `api/` exposes Popochiu-facing autoloads (`g.gd`, `gui_commands.gd`), `gui/` drives the letterbox scene, `letterbox/` hosts presets and controllers, `pfx/` holds the CRT pipeline (controller, shaders, resources), and `wrappers/` bridges Popochiu calls. Documentation lives in `POPOCHIU_ADDONS_DOCUMENTATION.md` and `addons/popochiu-addons/doc/`; update both whenever behavior or file paths change so downstream teams stay in sync.

## Build, Test, and Development Commands
Use the Godot CLI to validate assets and autoloads before opening the editor: `/usr/bin/godot --path addons/popochiu-addons --headless --run` checks for missing dependencies. From an integrated Popochiu project run `/usr/bin/godot --path . --headless --run` to smoke-test autoload registration. When iterating on shaders, reload the active scene with `/usr/bin/godot --editor --path .` to confirm visual changes.

## Coding Style & Naming Conventions
Follow Godot 4 defaults: four-space indentation, trailing commas on multiline arrays, and `snake_case.gd` filenames. Declare classes with `class_name` when the script is intended for autoload access, and keep exported presets in dedicated `.tres` files alongside their controllers. Place module-specific constants at the top of the script, then private state, then signal declarations. Preserve `.uid` companions in version control because they anchor resource references; never regenerate them unless the editor does it automatically.

## Testing Guidelines
Treat the headless command as a required pre-commit gate; it catches broken resource paths, missing autoloads, and script errors. For logic-heavy changes add temporary GDScript unit scenes under `addons/popochiu-addons/doc/tests/`, name scripts `test_<feature>.gd`, and run them headless. Visual tweaks should be captured with before/after screenshots of `letterbox` or `pfx` scenes; keep media in the PR description. Aim to exercise both `G` and `PFX` wrappers so Popochiu consumers see stable public APIs.

## Commit & Pull Request Guidelines
This repository is often distributed without bundled Git history; mirror the structure found in `readme.md` by scoping commits per module (e.g., `letterbox: add cinematic_235 preset`). Keep commit subjects under 72 characters and start them with a module tag plus imperative verb. In pull requests link to updated documentation sections, list the Godot commands executed, and embed screenshots or GIFs for GUI changes. Flag any resource UID churn so maintainers can warn downstream teams about necessary re-imports.
