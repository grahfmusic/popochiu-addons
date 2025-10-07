# Letterbox TODO

Keep this checklist close while polishing or migrating the letterbox system.

## Immediate Validation
- [ ] Run `/usr/bin/godot --path . --run` and exercise at least three cinematic presets to confirm tween + fade timing.
- [ ] Trigger `G.queue_show_letterbox_with_pfx` and `G.queue_hide_letterbox_with_pfx` inside a Popochiu queue to validate combined sequencing.
- [ ] Confirm GUI blocking/unblocking with `block_gui = true` and `release_block = true/false` across show/hide cycles.
- [ ] Add temporary debug logging around `transition_finished` to ensure listeners fire once per transition.

## Preset Quality Pass
- [ ] Review colour and opacity values for each preset on real content (bright vs. dark scenes).
- [ ] Tune durations/easing curves based on feel; document any adjustments in `LETTERBOX_PRESETS` comments.
- [ ] Create studio-specific presets via `G.register_letterbox_preset` and commit them once finalised.

## Integration Tasks
- [ ] Update cutscene scripts to subscribe via `G.connect_letterbox_transition` instead of manual timers.
- [ ] Pair letterbox presets with PopFX configs (see `doc/PFX.md`) and record the combinations used most often.
- [ ] Prototype a custom subclass of `LetterboxController` (e.g., gradient bars or soft edges) to confirm extendability.

## Tooling & Export Prep
- [ ] Write a minimal sample scene demonstrating presets, PFX combos, and signal usage.
- [ ] Draft export notes detailing which files to copy into new Popochiu projects (see `doc/letterbox_extensions.md`).
- [ ] Consider packaging presets + helpers into a Godot plugin for drop-in consumption.

## Nice-to-Haves
- [ ] Add optional SFX hooks (whoosh) tied to the transition signal.
- [ ] Build a settings menu toggle that selects default presets by context (cutscene, flashback, etc.).
- [ ] Investigate automated tests (headless scene) that assert bar offsets after tween completion.
