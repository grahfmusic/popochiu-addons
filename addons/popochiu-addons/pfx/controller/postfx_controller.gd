extends CanvasLayer

const FEATURE_TOGGLES := {
	"fx": "fx_enabled",
	"crt": "crt_enabled"
}
const SHADER_RESOURCE := preload("res://addons/popochiu-addons/pfx/shaders/postfx_pipeline.tres")

@export var auto_match_viewport := true
@export var context_name := "global"

@onready var overlay: ColorRect = $Overlay
var material: ShaderMaterial
var _cached_config := {}

func _ready() -> void:
	layer = 9
	if auto_match_viewport:
		_update_overlay_rect()
	_ensure_material()
	if auto_match_viewport:
		get_viewport().size_changed.connect(_on_viewport_resized)


func _on_viewport_resized() -> void:
	if not auto_match_viewport:
		return
	_update_overlay_rect()


func _update_overlay_rect() -> void:
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.offset_left = 0
	overlay.offset_top = 0
	overlay.offset_right = 0
	overlay.offset_bottom = 0
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ensure_material() -> bool:
	if material != null:
		return true
	if overlay == null:
		return false
	material = overlay.material
	if material == null:
		var shader_material := SHADER_RESOURCE.duplicate()
		shader_material.resource_local_to_scene = true
		overlay.material = shader_material
		material = shader_material
	if material != null:
		material.resource_local_to_scene = true
		if _cached_config.size() > 0:
			apply_config(_cached_config)
	return material != null



func apply_config(config: Dictionary) -> void:
	_cached_config = config.duplicate()
	if not _ensure_material():
		push_warning("PostFX: material not ready, cannot apply config")
		return
	for key in _cached_config.keys():
		material.set_shader_parameter(key, _cached_config[key])


func merge_config(config: Dictionary) -> void:
	_cached_config.merge(config, true)
	apply_config(_cached_config)


func set_feature_enabled(feature: String, enabled: bool) -> void:
	var key = FEATURE_TOGGLES.get(feature.to_lower(), null)
	if key == null:
		push_warning("PostFX: unknown feature %s" % feature)
		return
	set_shader_param(key, enabled)


func set_shader_param(param: String, value) -> void:
	if not _ensure_material():
		push_warning("PostFX: material not ready, cannot set %s" % param)
		return
	_cached_config[param] = value
	material.set_shader_parameter(param, value)


func adjust_shader_param(param: String, delta, min_value = null, max_value = null) -> void:
	if not _ensure_material():
		push_warning("PostFX: material not ready, cannot adjust %s" % param)
		return
	var current = material.get_shader_parameter(param)
	var updated = current
	match typeof(current):
		TYPE_FLOAT:
			updated = current + float(delta)
		TYPE_INT:
			updated = int(current) + int(delta)
		TYPE_BOOL:
			updated = delta if typeof(delta) == TYPE_BOOL else bool(delta)
		TYPE_VECTOR2:
			var d2 = delta if delta is Vector2 else Vector2(float(delta), float(delta))
			updated = current + d2
		TYPE_VECTOR3:
			var d3 = delta if delta is Vector3 else Vector3(float(delta), float(delta), float(delta))
			updated = current + d3
		TYPE_COLOR:
			var dcol = delta if delta is Color else Color(float(delta), float(delta), float(delta))
			updated = Color(current.r + dcol.r, current.g + dcol.g, current.b + dcol.b, current.a)
		_:
			push_warning("PostFX: adjust unsupported type for %s" % param)
			return
	if min_value != null:
		updated = _clamp_value(updated, min_value, true)
	if max_value != null:
		updated = _clamp_value(updated, max_value, false)
	_cached_config[param] = updated
	material.set_shader_parameter(param, updated)


func get_shader_param(param: String):
	if not _ensure_material():
		return null
	return material.get_shader_parameter(param)


func get_cached_config() -> Dictionary:
	return _cached_config.duplicate()


func clear_config() -> void:
	_cached_config.clear()
	if overlay == null:
		return
	var shader_material := SHADER_RESOURCE.duplicate()
	shader_material.resource_local_to_scene = true
	overlay.material = shader_material
	material = shader_material


func _clamp_value(value, bounds, is_min: bool):
	match typeof(value):
		TYPE_FLOAT, TYPE_INT:
			return _clamp_scalar(value, bounds, is_min)
		TYPE_VECTOR2:
			var bound_vec2 = bounds if bounds is Vector2 else Vector2(float(bounds), float(bounds))
			return Vector2(
				_clamp_scalar(value.x, bound_vec2.x, is_min),
				_clamp_scalar(value.y, bound_vec2.y, is_min)
			)
		TYPE_VECTOR3:
			var bound_vec3 = bounds if bounds is Vector3 else Vector3(float(bounds), float(bounds), float(bounds))
			return Vector3(
				_clamp_scalar(value.x, bound_vec3.x, is_min),
				_clamp_scalar(value.y, bound_vec3.y, is_min),
				_clamp_scalar(value.z, bound_vec3.z, is_min)
			)
		TYPE_COLOR:
			var bound_color = bounds if bounds is Color else Color(float(bounds), float(bounds), float(bounds))
			return Color(
				_clamp_scalar(value.r, bound_color.r, is_min),
				_clamp_scalar(value.g, bound_color.g, is_min),
				_clamp_scalar(value.b, bound_color.b, is_min),
				value.a
			)
		_:
			return value


func _clamp_scalar(value, bound, is_min: bool):
	return max(value, bound) if is_min else min(value, bound)
