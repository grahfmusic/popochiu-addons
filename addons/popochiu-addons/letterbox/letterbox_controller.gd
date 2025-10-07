class_name LetterboxController
extends Control

signal transition_finished(is_showing: bool)

const ORIENTATION_AUTO := "auto"
const ORIENTATION_HORIZONTAL := "horizontal"
const ORIENTATION_VERTICAL := "vertical"
const ORIENTATION_TOP_BOTTOM := "top_bottom"
const ORIENTATION_LEFT_RIGHT := "left_right"

const _BAR_KEYS := ["top", "bottom", "left", "right"]
const _EPSILON := 0.05

@onready var _top_bar: ColorRect = %TopBar
@onready var _bottom_bar: ColorRect = %BottomBar
@onready var _left_bar: ColorRect = %LeftBar
@onready var _right_bar: ColorRect = %RightBar

var _active_tween: Tween
var _is_showing := false
var _is_gui_blocked := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 4096
	z_as_relative = false
	visible = false
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	for bar: ColorRect in _get_bars():
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.color = Color.BLACK
	_apply_thickness({"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}, true)


func show_letterbox(config := {}) -> Variant:
	var options := _parse_options(config, false)
	var target := _build_target_thickness(options)
	var any_positive := _has_positive_values(target)
	if not any_positive:
		return hide_letterbox(config)
	_update_bar_colors(options["color"])
	if options["block_gui"] and not _is_gui_blocked:
		PopochiuUtils.g.block()
		_is_gui_blocked = true
	return _run_transition(target, options, false)


func hide_letterbox(config := {}) -> Variant:
	var options := _parse_options(config, true)
	var target := {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	return _run_transition(target, options, true)


func queue_show_letterbox(config := {}) -> Callable:
	return func ():
		var transition_signal = show_letterbox(config)
		if _should_wait(config) and transition_signal:
			await transition_signal


func queue_hide_letterbox(config := {}) -> Callable:
	return func ():
		var transition_signal = hide_letterbox(config)
		if _should_wait(config) and transition_signal:
			await transition_signal


func is_showing() -> bool:
	return _is_showing



func _run_transition(target: Dictionary, options: Dictionary, is_hiding: bool) -> Variant:
	_kill_active_tween()
	visible = true
	var current: Dictionary = _get_current_thickness()
	var duration: float = max(float(options["duration"]), 0.0)
	var target_alpha := 1.0 if _has_positive_values(target) else 0.0
	var needs_animation := _needs_animation(current, target)
	if not needs_animation:
		_apply_alpha(target_alpha)
		_finalize_transition(target, is_hiding, options)
		return null
	if duration <= 0.0:
		_apply_thickness(target, true)
		_apply_alpha(target_alpha)
		_finalize_transition(target, is_hiding, options)
		return null
	_active_tween = create_tween()
	_active_tween.set_parallel(true)
	_active_tween.set_trans(options["transition"])
	_active_tween.set_ease(options["ease"])
	var top_target: float = float(target.get("top", 0.0))
	var bottom_target: float = -float(target.get("bottom", 0.0))
	var left_target: float = float(target.get("left", 0.0))
	var right_target: float = -float(target.get("right", 0.0))
	for key in _BAR_KEYS:
		if target.get(key, 0.0) > _EPSILON:
			_get_bar_for_key(key).visible = true
	_schedule_bar_tween(_top_bar, "offset_bottom", _top_bar.offset_bottom, top_target, duration)
	_schedule_bar_tween(_bottom_bar, "offset_top", _bottom_bar.offset_top, bottom_target, duration)
	_schedule_bar_tween(_left_bar, "offset_right", _left_bar.offset_right, left_target, duration)
	_schedule_bar_tween(_right_bar, "offset_left", _right_bar.offset_left, right_target, duration)
	_schedule_alpha_tween(target_alpha, duration)
	_active_tween.finished.connect(_on_tween_finished.bind(target, is_hiding, options), CONNECT_ONE_SHOT)
	return _active_tween.finished


func _on_tween_finished(target: Dictionary, is_hiding: bool, options: Dictionary) -> void:
	_apply_thickness(target, false)
	_apply_alpha(1.0 if _has_positive_values(target) else 0.0)
	_finalize_transition(target, is_hiding, options)


func _finalize_transition(target: Dictionary, is_hiding: bool, options: Dictionary) -> void:
	_is_showing = _has_positive_values(target)
	_update_visibility(target)
	if is_hiding and _is_gui_blocked and options["release_block"]:
		_is_gui_blocked = false
		PopochiuUtils.g.unblock(true)
	transition_finished.emit(_is_showing)


func connect_transition_finished(target: Object, method: StringName, flags := 0) -> void:
	transition_finished.connect(Callable(target, method), flags)


func add_transition_finished_listener(callback: Callable, flags := 0) -> void:
	transition_finished.connect(callback, flags)


func _update_visibility(target: Dictionary) -> void:
	var any_positive := _has_positive_values(target)
	visible = any_positive
	for key in _BAR_KEYS:
		var bar: ColorRect = _get_bar_for_key(key)
		bar.visible = target.get(key, 0.0) > _EPSILON



func _schedule_bar_tween(bar: ColorRect, property: String, from_value: float, to_value: float, duration: float) -> void:
	if absf(from_value - to_value) <= _EPSILON:
		return
	_active_tween.tween_property(bar, property, to_value, duration)


func _schedule_alpha_tween(target_alpha: float, duration: float) -> void:
	var current_alpha := modulate.a
	if absf(current_alpha - target_alpha) <= _EPSILON:
		return
	_active_tween.tween_property(self, "modulate:a", target_alpha, duration)


func _apply_thickness(target: Dictionary, instant: bool) -> void:
	_top_bar.offset_bottom = target.get("top", 0.0)
	_bottom_bar.offset_top = -target.get("bottom", 0.0)
	_left_bar.offset_right = target.get("left", 0.0)
	_right_bar.offset_left = -target.get("right", 0.0)
	if instant:
		for bar: ColorRect in _get_bars():
			bar.queue_redraw()


func _apply_alpha(target_alpha: float) -> void:
	modulate.a = clampf(target_alpha, 0.0, 1.0)


func _get_current_thickness() -> Dictionary:
	return {
		"top": _top_bar.offset_bottom,
		"bottom": -_bottom_bar.offset_top,
		"left": _left_bar.offset_right,
		"right": -_right_bar.offset_left
	}



func _needs_animation(current: Dictionary, target: Dictionary) -> bool:
	for key in _BAR_KEYS:
		var current_value: float = float(current.get(key, 0.0))
		var target_value: float = float(target.get(key, 0.0))
		if absf(current_value - target_value) > _EPSILON:
			return true
	return false


func _has_positive_values(values: Dictionary) -> bool:
	for key in _BAR_KEYS:
		if values.get(key, 0.0) > _EPSILON:
			return true
	return false


func _should_wait(config: Dictionary) -> bool:
	if config.has("wait"):
		return bool(config["wait"])
	if config.has("block_queue"):
		return bool(config["block_queue"])
	return false


func _parse_options(config: Dictionary, is_hiding: bool) -> Dictionary:
	var options: Dictionary = {
		"duration": float(config.get("duration", 0.45)),
		"ease": int(config.get("ease", Tween.EASE_OUT)),
		"transition": int(config.get("transition", Tween.TRANS_QUINT)),
		"color": config.get("color", Color.BLACK),
		"orientation": _normalize_orientation(config.get("orientation", ORIENTATION_AUTO)),
		"aspect_ratio": _parse_aspect_ratio(config.get("aspect_ratio", null)),
		"pixels": _parse_pixel_overrides(config.get("pixels", config.get("pixel_amounts", null))),
		"block_gui": bool(config.get("block_gui", false)),
		"release_block": bool(config.get("release_block", true)) if is_hiding else true
	}
	var speed_value: Variant = config.get("speed", null)
	if speed_value != null:
		var speed_float: float = float(speed_value)
		if not is_zero_approx(speed_float):
			options["duration"] = max(float(options["duration"]) / speed_float, 0.0)
	return options



func _build_target_thickness(options: Dictionary) -> Dictionary:
	var target: Dictionary = {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	if options["aspect_ratio"] != null:
		var aspect: float = float(options["aspect_ratio"])
		var orientation: String = String(options["orientation"])
		var calculated: Dictionary = _thickness_from_aspect(aspect, orientation)
		for key in _BAR_KEYS:
			target[key] = calculated.get(key, 0.0)
	var pixels: Dictionary = options["pixels"] if options["pixels"] is Dictionary else {}
	for key in _BAR_KEYS:
		var override_value: Variant = pixels.get(key, null)
		if override_value != null:
			target[key] = max(float(override_value), 0.0)
	return target


func _thickness_from_aspect(target_ratio: float, orientation: String) -> Dictionary:
	var viewport_size: Vector2 = get_viewport_rect().size
	var viewport_ratio: float = viewport_size.x / viewport_size.y
	var result: Dictionary = {"top": 0.0, "bottom": 0.0, "left": 0.0, "right": 0.0}
	if is_zero_approx(target_ratio) or viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return result
	var use_horizontal := orientation in [ORIENTATION_HORIZONTAL, ORIENTATION_TOP_BOTTOM]
	var use_vertical := orientation in [ORIENTATION_VERTICAL, ORIENTATION_LEFT_RIGHT]
	if orientation == ORIENTATION_AUTO:
		if target_ratio > viewport_ratio + 0.001:
			use_horizontal = true
		elif target_ratio < viewport_ratio - 0.001:
			use_vertical = true
		else:
			use_horizontal = false
			use_vertical = false
	if use_horizontal:
		var target_height: float = viewport_size.x / target_ratio
		var pad: float = max((viewport_size.y - target_height) * 0.5, 0.0)
		result["top"] = pad
		result["bottom"] = pad
	elif use_vertical:
		var target_width: float = viewport_size.y * target_ratio
		var pad_vertical: float = max((viewport_size.x - target_width) * 0.5, 0.0)
		result["left"] = pad_vertical
		result["right"] = pad_vertical
	return result


func _update_bar_colors(color_value) -> void:
	if color_value == null:
		return
	var color: Color = Color.BLACK
	if color_value is Color:
		color = color_value
	else:
		color = Color(color_value)
	for bar: ColorRect in _get_bars():
		bar.color = color


func _parse_pixel_overrides(raw_value) -> Dictionary:
	var overrides: Dictionary = {}
	if raw_value == null:
		return overrides
	if raw_value is Dictionary:
		for key in _BAR_KEYS:
			if raw_value.has(key):
				overrides[key] = float(raw_value[key])
	elif raw_value is PackedFloat32Array and raw_value.size() == 4:
		overrides = _vector_to_pixels(Vector4(raw_value[0], raw_value[1], raw_value[2], raw_value[3]))
	elif raw_value is Vector4:
		overrides = _vector_to_pixels(raw_value)
	elif raw_value is Array and raw_value.size() == 4:
		overrides = _vector_to_pixels(Vector4(raw_value[0], raw_value[1], raw_value[2], raw_value[3]))
	return overrides


func _vector_to_pixels(vec: Vector4) -> Dictionary:
	return {
		"top": float(vec.x),
		"bottom": float(vec.y),
		"left": float(vec.z),
		"right": float(vec.w)
	}


func _parse_aspect_ratio(value) -> Variant:
	var ratio: float = 0.0
	var has_ratio: bool = false
	if value == null:
		return null
	if value is float:
		ratio = value
		has_ratio = true
	elif value is int:
		ratio = float(value)
		has_ratio = true
	elif value is Vector2:
		if value.y == 0:
			return null
		ratio = value.x / value.y
		has_ratio = true
	elif value is String:
		var trimmed: String = value.strip_edges()
		if trimmed.is_empty():
			return null
		if ":" in trimmed:
			var parts: PackedStringArray = trimmed.split(":")
			if parts.size() == 2:
				var numerator_text: String = parts[0].strip_edges()
				var denominator_text: String = parts[1].strip_edges()
				if not numerator_text.is_valid_float() or not denominator_text.is_valid_float():
					return null
				var numerator: float = numerator_text.to_float()
				var denominator: float = denominator_text.to_float()
				if is_zero_approx(denominator):
					return null
				ratio = numerator / denominator
				has_ratio = true
		else:
			if not trimmed.is_valid_float():
				return null
			ratio = trimmed.to_float()
			has_ratio = true
	else:
		return null
	if not has_ratio or ratio <= 0.0 or is_nan(ratio):
		return null
	return ratio


func _normalize_orientation(raw_orientation) -> String:
	var value: String = String(raw_orientation)
	value = value.strip_edges().to_lower()
	match value:
		"horizontal", "top_bottom":
			return ORIENTATION_TOP_BOTTOM
		"vertical", "left_right":
			return ORIENTATION_LEFT_RIGHT
		"auto":
			return ORIENTATION_AUTO
		_:
			return ORIENTATION_AUTO


func _get_bars() -> Array[ColorRect]:
	return [_top_bar, _bottom_bar, _left_bar, _right_bar]


func _get_bar_for_key(key: String) -> ColorRect:
	match key:
		"top":
			return _top_bar
		"bottom":
			return _bottom_bar
		"left":
			return _left_bar
		"right":
			return _right_bar
	return _top_bar


func _kill_active_tween() -> void:
	if is_instance_valid(_active_tween):
		_active_tween.kill()
		_active_tween = null
