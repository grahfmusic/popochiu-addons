extends "res://addons/popochiu/engine/interfaces/i_graphic_interface.gd"

const LetterboxAPI := preload("res://addons/popochiu-addons/letterbox/letterbox_api.gd")
const LETTERBOX_SCENE := preload("res://addons/popochiu-addons/letterbox/letterbox.tscn")
const PFX_NODE_NAME := "PFX"
const DEFAULT_PROP_FADE_DURATION := 0.4
const DEFAULT_PROP_FADE_TRANSITION := Tween.TRANS_LINEAR
const DEFAULT_PROP_FADE_EASE := Tween.EASE_IN_OUT

func show_letterbox(config := {}):
	if not is_instance_valid(gui):
		return null
	if gui.has_method("show_letterbox"):
		return gui.show_letterbox(config)
	var controller := _get_letterbox_controller()
	return controller.show_letterbox(config) if controller else null

func hide_letterbox(config := {}):
	if not is_instance_valid(gui):
		return null
	if gui.has_method("hide_letterbox"):
		return gui.hide_letterbox(config)
	var controller := _get_letterbox_controller()
	return controller.hide_letterbox(config) if controller else null

func queue_show_letterbox(config := {}):
	if not is_instance_valid(gui):
		return func () -> void:
			pass
	if gui.has_method("queue_show_letterbox"):
		return gui.queue_show_letterbox(config)
	var controller := _get_letterbox_controller()
	if controller:
		return controller.queue_show_letterbox(config)
	return func () -> void:
		pass

func queue_hide_letterbox(config := {}):
        if not is_instance_valid(gui):
                return func () -> void:
                        pass
        if gui.has_method("queue_hide_letterbox"):
                return gui.queue_hide_letterbox(config)
        var controller := _get_letterbox_controller()
        if controller:
                return controller.queue_hide_letterbox(config)
        return func () -> void:
                pass

func is_letterbox_showing() -> bool:
        if not is_instance_valid(gui):
                return false
        if gui.has_method("is_letterbox_showing"):
                return gui.is_letterbox_showing()
        var controller := _get_letterbox_controller(false)
        return controller.is_showing() if controller else false

func fade_prop(prop: Variant, target_alpha: float, config := {}) -> Variant:
        var canvas_item := _resolve_prop_canvas_item(prop)
        if canvas_item == null:
                push_warning("Popochiu Addons: Unable to fade prop; CanvasItem not found.")
                return null
        var fade_config := _ensure_dictionary(config)
        var duration := float(fade_config.get("duration", DEFAULT_PROP_FADE_DURATION))
        var transition := int(fade_config.get("transition", DEFAULT_PROP_FADE_TRANSITION))
        var ease := int(fade_config.get("ease", DEFAULT_PROP_FADE_EASE))
        var delay := float(fade_config.get("delay", 0.0))
        var ensure_visible := fade_config.get("ensure_visible", target_alpha > 0.0)
        var hide_on_finish := fade_config.get("hide_on_finish", target_alpha <= 0.0)
        var blocking := fade_config.get("blocking", true)
        var from_alpha = fade_config.get("from_alpha", null)
        delay = max(delay, 0.0)
        var clamped_target := clamp(float(target_alpha), 0.0, 1.0)
        if ensure_visible and clamped_target > 0.0:
                canvas_item.visible = true
        if from_alpha != null:
                var start_color := canvas_item.modulate
                start_color.a = clamp(float(from_alpha), 0.0, 1.0)
                canvas_item.modulate = start_color
        if duration <= 0.0:
                var end_color := canvas_item.modulate
                end_color.a = clamped_target
                canvas_item.modulate = end_color
                if hide_on_finish and clamped_target <= 0.0:
                        canvas_item.visible = false
                return null
        var tween := canvas_item.create_tween()
        var property_tweener := tween.tween_property(canvas_item, "modulate:a", clamped_target, duration)
        property_tweener.set_trans(transition)
        property_tweener.set_ease(ease)
        if delay > 0.0:
                property_tweener.set_delay(delay)
        if hide_on_finish and clamped_target <= 0.0:
                var hide_callable := Callable(canvas_item, "set_visible").bind(false)
                var hide_tweener := tween.tween_callback(hide_callable)
                hide_tweener.set_delay(delay + duration)
        if blocking:
                await tween.finished
        return tween

func fade_prop_in(prop: Variant, config := {}) -> Variant:
        var fade_config := _ensure_dictionary(config)
        fade_config.erase("hide_on_finish")
        fade_config["ensure_visible"] = fade_config.get("ensure_visible", true)
        return fade_prop(prop, 1.0, fade_config)

func fade_prop_out(prop: Variant, config := {}) -> Variant:
        var fade_config := _ensure_dictionary(config)
        fade_config["hide_on_finish"] = fade_config.get("hide_on_finish", true)
        return fade_prop(prop, 0.0, fade_config)

func queue_fade_prop(prop: Variant, target_alpha: float, config := {}) -> Callable:
        var fade_config := _ensure_dictionary(config)
        return func () -> void:
                var queued_config := fade_config.duplicate(true)
                queued_config["blocking"] = true
                await fade_prop(prop, target_alpha, queued_config)

func queue_fade_prop_in(prop: Variant, config := {}) -> Callable:
        return queue_fade_prop(prop, 1.0, config)

func queue_fade_prop_out(prop: Variant, config := {}) -> Callable:
        return queue_fade_prop(prop, 0.0, config)

func connect_letterbox_transition(target: Object, method: StringName, flags := 0) -> void:
	if not is_instance_valid(gui):
		return
	if gui.has_method("connect_letterbox_transition"):
		gui.connect_letterbox_transition(target, method, flags)
		return
	var controller := _get_letterbox_controller()
	if controller:
		controller.connect("transition_finished", Callable(target, method), flags)

func add_letterbox_transition_listener(callback: Callable, flags := 0) -> void:
	if not is_instance_valid(gui):
		return
	if gui.has_method("add_letterbox_transition_listener"):
		gui.add_letterbox_transition_listener(callback, flags)
		return
	var controller := _get_letterbox_controller()
	if controller:
		controller.connect("transition_finished", callback, flags)

func get_letterbox_preset(name: String) -> Dictionary:
	return LetterboxAPI.get_preset(name)

func list_letterbox_presets() -> PackedStringArray:
	return LetterboxAPI.list_presets()

func has_letterbox_preset(name: String) -> bool:
	return LetterboxAPI.has_preset(name)

func register_letterbox_preset(name: String, config: Dictionary, overwrite := false) -> void:
	if not LetterboxAPI.register_preset(name, config, overwrite):
		push_warning("Cannot overwrite built-in letterbox preset '%s' without overwrite = true" % name)

func show_letterbox_preset(name: String, overrides := {}) -> Variant:
	var config := get_letterbox_preset(name)
	config.merge(overrides, true)
	if config.is_empty():
		push_warning("Letterbox preset '%s' not found" % name)
	return show_letterbox(config)

func queue_show_letterbox_preset(name: String, overrides := {}) -> Callable:
	var config := get_letterbox_preset(name)
	config.merge(overrides, true)
	if config.is_empty():
		push_warning("Letterbox preset '%s' not found" % name)
	return queue_show_letterbox(config)

func show_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Variant:
	_apply_pfx_config(pfx_config, context)
	return show_letterbox(letterbox_config)

func hide_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Variant:
	_apply_pfx_config(pfx_config, context)
	return hide_letterbox(letterbox_config)

func queue_show_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Callable:
	var base_callable: Callable = queue_show_letterbox(letterbox_config)
	return func () -> void:
		_apply_pfx_config(pfx_config, context)
		await base_callable.call()

func queue_hide_letterbox_with_pfx(letterbox_config := {}, pfx_config := {}, context := "global") -> Callable:
	var base_callable: Callable = queue_hide_letterbox(letterbox_config)
	return func () -> void:
		_apply_pfx_config(pfx_config, context)
		await base_callable.call()

func apply_pfx_config(config: Dictionary, context := "global", parent: Node = null) -> void:
	_call_pfx("apply_config", [config, context, parent])

func merge_pfx_config(config: Dictionary, context := "global") -> void:
	_call_pfx("merge_config", [config, context])

func set_pfx_feature(feature: String, enabled: bool, context := "global") -> void:
	_call_pfx("set_feature", [feature, enabled, context])

func set_pfx_param(param: String, value, context := "global") -> void:
	_call_pfx("set_param", [param, value, context])

func adjust_pfx_param(param: String, delta, min_value = null, max_value = null, context := "global") -> void:
	_call_pfx("adjust_param", [param, delta, min_value, max_value, context])

func get_pfx_param(param: String, context := "global"):
	return _call_pfx("get_param", [param, context])

func get_pfx_config(context := "global") -> Dictionary:
	var result = _call_pfx("get_config", [context])
	return result if result is Dictionary else {}

func apply_pfx_room_config(room: Node, config: Dictionary, context := "") -> void:
	_call_pfx("apply_room_config", [room, config, context])

func set_pfx_room_feature(room: Node, feature: String, enabled: bool, context := "") -> void:
	_call_pfx("set_room_feature", [room, feature, enabled, context])

func set_pfx_room_param(room: Node, param: String, value, context := "") -> void:
	_call_pfx("set_room_param", [room, param, value, context])

func clear_pfx_config(context := "global") -> void:
	_call_pfx("clear_config", [context])

func clear_pfx_room_config(room: Node, context := "") -> void:
	_call_pfx("clear_room_config", [room, context])

func register_pfx_room_default(script_name: String, config: Dictionary) -> void:
        _call_pfx("register_room_default", [script_name, config])

func get_pfx_room_default(script_name: String) -> Dictionary:
        var result = _call_pfx("get_room_default", [script_name])
        return result if result is Dictionary else {}


func _get_letterbox_controller(create_if_missing := true) -> LetterboxController:
        if not is_instance_valid(gui):
                return null
	var node := gui.get_node_or_null("Letterbox")
	if node == null:
		node = gui.get_node_or_null("PopochiuAddonsLetterbox")
	if node == null and create_if_missing:
		node = LETTERBOX_SCENE.instantiate()
		node.name = "PopochiuAddonsLetterbox"
		gui.add_child(node)
		gui.move_child(node, 0)
	return node if node is LetterboxController else null


func _apply_pfx_config(pfx_config, context: String) -> void:
	if not (pfx_config is Dictionary and pfx_config.size() > 0):
		return
	var pfx := _get_pfx()
	if pfx != null and pfx.has_method("apply_config"):
		pfx.apply_config(pfx_config, context)
	else:
		push_warning("Popochiu Addons: PFX autoload not found or missing 'apply_config'. Skipping PostFX configuration.")

func _call_pfx(method: StringName, args: Array = []):
        var pfx := _get_pfx()
        if pfx == null:
                push_warning("Popochiu Addons: PFX autoload not found; skipping '%s' call." % method)
                return null
        if not pfx.has_method(method):
                push_warning("Popochiu Addons: PFX missing method '%s'." % method)
                return null
        return pfx.callv(method, args)


func _ensure_dictionary(value) -> Dictionary:
        if value is Dictionary:
                return value.duplicate(true)
        return {}


func _resolve_prop_canvas_item(prop: Variant) -> CanvasItem:
        if prop is CanvasItem:
                return prop
        if prop is Node:
                var node := prop as Node
                if node is CanvasItem:
                        return node
        if prop is Object and prop.has_method("get_node"):
                var prop_node = prop.get_node()
                if prop_node is CanvasItem:
                        return prop_node
        if prop is String or prop is StringName:
                var prop_name := String(prop)
                if has_method("get_prop"):
                        var resolved_prop = get_prop(prop_name)
                        if resolved_prop is CanvasItem:
                                return resolved_prop
                        if resolved_prop is Object and resolved_prop.has_method("get_node"):
                                var resolved_node = resolved_prop.get_node()
                                if resolved_node is CanvasItem:
                                        return resolved_node
                        if resolved_prop is Node and resolved_prop is CanvasItem:
                                return resolved_prop
                if has_method("get_prop_node"):
                        var prop_node = get_prop_node(prop_name)
                        if prop_node is CanvasItem:
                                return prop_node
        return null


static func _get_pfx() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null(PFX_NODE_NAME)
	return null
