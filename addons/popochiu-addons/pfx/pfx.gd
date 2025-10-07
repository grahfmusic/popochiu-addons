extends Node

const CONTROLLER_SCENE := preload("res://addons/popochiu-addons/pfx/controller/postfx_controller.tscn")
const ROOM_DEFAULTS := {
	"Start": {
		"fx_enabled": true,
		"crt_enabled": true,
		"crt_use_screen_uv": true,
		"crt_resolution": Vector2(256, 192),
		"crt_scan_line_amount": 0.95,
		"crt_warp_amount": 0.18,
		"crt_noise_amount": 0.1,
		"crt_interference_amount": 0.28,
		"crt_grille_amount": 0.25,
		"crt_grille_size": 0.25,
		"crt_vignette_amount": 0.85,
		"crt_vignette_intensity": 0.85,
		"crt_aberration_amount": 0.32,
		"crt_roll_line_amount": 0.12,
		"crt_roll_speed": 0.5,
		"crt_scan_line_strength": -9.5,
		"crt_pixel_strength": -2.4
	}
}

# Example global preset (commented out). Uncomment along with the `_ready` hook to apply at startup.
# const GLOBAL_CRT_PRESET := {
# 	"fx_enabled": true,
# 	"crt_enabled": true,
# 	"crt_resolution": Vector2(320, 180),
# 	"crt_scan_line_amount": 1.0,
# 	"crt_warp_amount": 0.12,
# 	"crt_noise_amount": 0.05,
# 	"crt_interference_amount": 0.2,
# 	"crt_vignette_amount": 0.5,
# 	"crt_vignette_intensity": 0.4,
# 	"crt_aberration_amount": 0.45
# }
#
# const GLOBAL_CRT_OLD_VIDEO_PRESET := {
# 	"fx_enabled": true,
# 	"enabled": true,
# 	"resolution": Vector2(256, 192),
# 	"scan_line_amount": 0.95,
# 	"warp_amount": 0.18,
# 	"noise_amount": 0.14,
# 	"interference_amount": 0.28,
# 	"grille_amount": 0.25,
# 	"grille_size": 1.3,
# 	"vignette_amount": 0.75,
# 	"vignette_intensity": 0.55,
# 	"aberration_amount": 0.32,
# 	"roll_line_amount": 0.12,
# 	"roll_speed": 0.5,
# 	"scan_line_strength": -9.5,
# 	"pixel_strength": -2.4
# }
#

# Uncomment this if you see errors when you save a scene and you see
# compile errors, change the apply_config to whatever you have called the
# global const.

# func _ready() -> void:
# 	if Engine.is_editor_hint():
# 		return
# 	apply_config(GLOBAL_CRT_PRESET)

var _controllers := {}
var _pending_configs := {}
var _room_presets := {}
var _room_defaults := ROOM_DEFAULTS.duplicate(true)

func _ensure_controller(context: String, parent: Node = null) -> CanvasLayer:
	context = context.to_lower()
	if _controllers.has(context):
		var existing: CanvasLayer = _controllers[context]
		if is_instance_valid(existing):
			return existing
		_controllers.erase(context)
	var controller: CanvasLayer = CONTROLLER_SCENE.instantiate()
	controller.name = "PostFXController_%s" % context
	controller.context_name = context
	if parent != null:
		parent.add_child(controller)
	else:
		get_tree().root.call_deferred("add_child", controller)
	_controllers[context] = controller
	controller.tree_exited.connect(_on_controller_tree_exited.bind(context))
	return controller


func _on_controller_tree_exited(context: String) -> void:
	_controllers.erase(context)


func _on_controller_ready(context: String) -> void:
	context = context.to_lower()
	var ctrl = _controllers.get(context)
	if ctrl == null or not is_instance_valid(ctrl):
		return
	if not ctrl.has_method("apply_config"):
		return
	var pending = _pending_configs.get(context)
	if pending == null:
		pending = _room_presets.get(context)
		if pending == null:
			return
	_pending_configs.erase(context)
	ctrl.apply_config(pending.duplicate())


func apply_config(config: Dictionary, context: String = "global", parent: Node = null) -> void:
	context = context.to_lower()
	var ctrl = _controllers.get(context)
	if ctrl == null or not is_instance_valid(ctrl):
		_pending_configs[context] = config.duplicate()
		ctrl = _ensure_controller(context, parent)
	if not ctrl.has_method("apply_config"):
		return
	if ctrl.is_node_ready():
		_pending_configs.erase(context)
		ctrl.apply_config(config)
	else:
		_pending_configs[context] = config.duplicate()
		ctrl.ready.connect(_on_controller_ready.bind(context), Object.CONNECT_ONE_SHOT | Object.CONNECT_DEFERRED)


func merge_config(config: Dictionary, context: String = "global") -> void:
	context = context.to_lower()
	var ctrl = _ensure_controller(context)
	if ctrl.has_method("merge_config"):
		ctrl.merge_config(config)


func set_feature(feature: String, enabled: bool, context: String = "global") -> void:
	context = context.to_lower()
	var ctrl = _ensure_controller(context)
	if ctrl.has_method("set_feature_enabled"):
		ctrl.set_feature_enabled(feature, enabled)


func set_param(param: String, value, context: String = "global") -> void:
	context = context.to_lower()
	var ctrl = _ensure_controller(context)
	if ctrl.has_method("set_shader_param"):
		ctrl.set_shader_param(param, value)


func adjust_param(param: String, delta, min_value = null, max_value = null, context: String = "global") -> void:
	context = context.to_lower()
	var ctrl = _ensure_controller(context)
	if ctrl.has_method("adjust_shader_param"):
		ctrl.adjust_shader_param(param, delta, min_value, max_value)


func get_param(param: String, context: String = "global"):
	context = context.to_lower()
	var ctrl = _controllers.get(context)
	if ctrl == null or not is_instance_valid(ctrl):
		return null
	return ctrl.get_shader_param(param) if ctrl.has_method("get_shader_param") else null


func get_config(context: String = "global") -> Dictionary:
	context = context.to_lower()
	var ctrl = _controllers.get(context)
	if ctrl == null or not is_instance_valid(ctrl):
		return _pending_configs.get(context, {})
	return ctrl.get_cached_config() if ctrl.has_method("get_cached_config") else {}

func clear_config(context: String = "global") -> void:
	context = context.to_lower()
	_pending_configs.erase(context)
	_room_presets.erase(context)
	var ctrl = _controllers.get(context)
	if ctrl == null or not is_instance_valid(ctrl):
		return
	if ctrl.has_method("clear_config"):
		ctrl.clear_config()
	elif ctrl.has_method("apply_config"):
		ctrl.apply_config({})


func _resolve_context(base_context: String, room: Node = null) -> String:
	var result: String = base_context
	if result.is_empty() and room != null:
		result = "room_%s" % [room.name]
	return result.to_lower()


func ensure_room_controller(room: Node, context: String = "") -> CanvasLayer:
	var resolved := _resolve_context(context, room)
	return _ensure_controller(resolved, room)


func apply_room_config(room: Node, config: Dictionary, context: String = "") -> void:
	var resolved := _resolve_context(context, room)
	_room_presets[resolved] = config.duplicate()
	apply_config(config, resolved, room)

func clear_room_config(room: Node, context: String = "") -> void:
	var resolved := _resolve_context(context, room)
	_room_presets.erase(resolved)
	clear_config(resolved)


func set_room_feature(room: Node, feature: String, enabled: bool, context: String = "") -> void:
	var resolved := _resolve_context(context, room)
	set_feature(feature, enabled, resolved)



func apply_old_video_preset(context: String = "global", parent: Node = null) -> void:
	var preset := {
		"fx_enabled": true,
		"crt_enabled": true,
		"crt_use_screen_uv": true,
		"crt_resolution": Vector2(256, 192),
		"crt_scan_line_amount": 0.92,
		"crt_warp_amount": 0.16,
		"crt_noise_amount": 0.16,
		"crt_interference_amount": 0.3,
		"crt_grille_amount": 0.22,
		"crt_grille_size": 1.25,
		"crt_vignette_amount": 0.72,
		"crt_vignette_intensity": 0.5,
		"crt_aberration_amount": 0.28,
		"crt_roll_line_amount": 0.1,
		"crt_roll_speed": 0.6,
		"crt_scan_line_strength": -9.2,
		"crt_pixel_strength": -2.3
	}
	apply_config(preset, context, parent)


func set_room_param(room: Node, param: String, value, context: String = "") -> void:
	var resolved := _resolve_context(context, room)
	set_param(param, value, resolved)


func register_room_default(script_name: String, config: Dictionary) -> void:
	_room_defaults[script_name.to_lower()] = config.duplicate(true)


func get_room_default(script_name: String) -> Dictionary:
	return _room_defaults.get(script_name.to_lower(), {})
