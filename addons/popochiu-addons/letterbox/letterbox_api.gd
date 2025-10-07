class_name PopochiuAddonsLetterbox
extends Object

const PRESETS := {
	"cinematic_235": {
		"aspect_ratio": "21:9",
		"duration": 0.5,
		"transition": Tween.TRANS_QUINT,
		"ease": Tween.EASE_OUT,
		"block_gui": true
	},
	"cinematic_soft": {
		"aspect_ratio": "2:1",
		"duration": 0.7,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_IN_OUT,
		"color": Color(0.0, 0.0, 0.0, 0.9)
	},
	"cinematic_classic_185": {
		"aspect_ratio": "37:20",
		"duration": 0.55,
		"transition": Tween.TRANS_CUBIC,
		"ease": Tween.EASE_IN_OUT,
		"block_gui": true
	},
	"cinematic_ultrawide_256": {
		"aspect_ratio": "64:25",
		"duration": 0.6,
		"transition": Tween.TRANS_QUART,
		"ease": Tween.EASE_OUT,
		"block_gui": true
	},
	"cinematic_scope_276": {
		"aspect_ratio": "69:25",
		"duration": 0.65,
		"transition": Tween.TRANS_QUINT,
		"ease": Tween.EASE_IN_OUT,
		"block_gui": true
	},
	"trailer_punch": {
		"aspect_ratio": "21:9",
		"duration": 0.35,
		"transition": Tween.TRANS_BACK,
		"ease": Tween.EASE_OUT,
		"block_gui": true
	},
	"teaser_fast": {
		"aspect_ratio": "2:1",
		"duration": 0.25,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_OUT
	},
	"dream_sequence": {
		"aspect_ratio": "2:1",
		"duration": 0.8,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_IN_OUT,
		"color": Color(0.05, 0.02, 0.08, 0.9),
		"block_gui": true
	},
	"noir_flashback": {
		"aspect_ratio": "4:3",
		"orientation": "top_bottom",
		"duration": 0.7,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_IN_OUT,
		"color": Color(0.05, 0.05, 0.05, 1.0)
	},
	"horror_focus": {
		"pixels": {"top": 64.0, "bottom": 64.0},
		"duration": 0.6,
		"transition": Tween.TRANS_ELASTIC,
		"ease": Tween.EASE_OUT,
		"color": Color(0.0, 0.0, 0.0, 0.95),
		"block_gui": true
	},
	"thriller_vertical": {
		"aspect_ratio": Vector2(9, 5),
		"orientation": "left_right",
		"duration": 0.5,
		"transition": Tween.TRANS_QUAD,
		"ease": Tween.EASE_IN_OUT,
		"color": Color(0.0, 0.0, 0.0, 0.9)
	},
	"arcade_cabinet": {
		"aspect_ratio": Vector2(4, 3),
		"orientation": "left_right",
		"duration": 0.4,
		"transition": Tween.TRANS_QUART,
		"ease": Tween.EASE_OUT,
		"color": Color(0.05, 0.05, 0.05, 1.0)
	},
	"retro_tv": {
		"pixels": {"top": 36.0, "bottom": 36.0, "left": 24.0, "right": 24.0},
		"duration": 0.45,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_OUT,
		"color": Color(0.08, 0.08, 0.08, 1.0)
	},
	"handheld_portrait": {
		"aspect_ratio": Vector2(9, 16),
		"orientation": "left_right",
		"duration": 0.4,
		"transition": Tween.TRANS_CUBIC,
		"ease": Tween.EASE_OUT,
		"color": Color(0.0, 0.0, 0.0, 0.85)
	},
	"vignette_intro": {
		"pixels": {"top": 56.0, "bottom": 56.0},
		"duration": 0.6,
		"transition": Tween.TRANS_QUINT,
		"ease": Tween.EASE_IN_OUT,
		"color": Color(0.0, 0.0, 0.0, 0.92),
		"block_gui": true
	},
	"documentary_caption": {
		"pixels": {"bottom": 72.0},
		"duration": 0.3,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_OUT,
		"color": Color(0.0, 0.0, 0.0, 0.85)
	},
	"dialogue_focus_bottom": {
		"pixels": {"bottom": 96.0},
		"duration": 0.4,
		"transition": Tween.TRANS_CUBIC,
		"ease": Tween.EASE_OUT,
		"block_gui": true
	},
	"dialogue_focus_top": {
		"pixels": {"top": 72.0},
		"duration": 0.4,
		"transition": Tween.TRANS_CUBIC,
		"ease": Tween.EASE_OUT,
		"block_gui": true
	},
	"tutorial_banner": {
		"pixels": {"top": 40.0, "bottom": 40.0},
		"duration": 0.3,
		"transition": Tween.TRANS_BACK,
		"ease": Tween.EASE_OUT
	},
	"photo_slide": {
		"aspect_ratio": "3:2",
		"duration": 0.45,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_IN_OUT,
		"color": Color(0.02, 0.02, 0.02, 0.95)
	},
	"stealth_alert": {
		"pixels": {"top": 60.0, "bottom": 60.0},
		"duration": 0.2,
		"transition": Tween.TRANS_QUAD,
		"ease": Tween.EASE_IN,
		"color": Color(0.0, 0.0, 0.0, 0.98),
		"block_gui": true
	},
	"wide_pan": {
		"aspect_ratio": "19:9",
		"duration": 0.5,
		"transition": Tween.TRANS_SINE,
		"ease": Tween.EASE_OUT
	},
	"pillarbox_169_thin": {
		"pixels": {"left": 24.0, "right": 24.0},
		"duration": 0.3,
		"transition": Tween.TRANS_CUBIC,
		"ease": Tween.EASE_IN_OUT
	},
	"title_card_center": {
		"pixels": {"top": 120.0, "bottom": 120.0},
		"duration": 0.55,
		"transition": Tween.TRANS_QUINT,
		"ease": Tween.EASE_IN_OUT,
		"block_gui": true
	},
	"inventory_focus": {
		"pixels": {"left": 80.0},
		"duration": 0.35,
		"transition": Tween.TRANS_BACK,
		"ease": Tween.EASE_OUT,
		"color": Color(0.0, 0.0, 0.0, 0.9)
	},
	"pillarbox_43": {
		"aspect_ratio": Vector2(4, 3),
		"orientation": "left_right",
		"duration": 0.45,
		"transition": Tween.TRANS_QUART,
		"ease": Tween.EASE_OUT
	},
	"top_bar_subtitle": {
		"pixels": {"top": 48.0},
		"duration": 0.25,
		"transition": Tween.TRANS_CUBIC,
		"ease": Tween.EASE_OUT
	},
	"bottom_bar_subtitle": {
		"pixels": {"bottom": 48.0},
		"duration": 0.25,
		"transition": Tween.TRANS_CUBIC,
		"ease": Tween.EASE_OUT
	},
	"instant_hide": {
		"duration": 0.0
	}
}

static var custom_presets := {}

static func get_preset(name: String) -> Dictionary:
	if custom_presets.has(name):
		return custom_presets[name].duplicate(true)
	if PRESETS.has(name):
		return PRESETS[name].duplicate(true)
	return {}

static func list_presets() -> PackedStringArray:
	var keys: Array = Array(PRESETS.keys())
	keys += Array(custom_presets.keys())
	keys.sort()
	return PackedStringArray(keys)

static func has_preset(name: String) -> bool:
	return PRESETS.has(name) or custom_presets.has(name)

static func register_preset(name: String, config: Dictionary, overwrite := false) -> bool:
	if PRESETS.has(name) and not overwrite:
		push_warning("Cannot overwrite built-in letterbox preset '%s' without overwrite = true" % name)
		return false
	custom_presets[name] = config.duplicate(true)
	return true
