class_name PopochiuAddonsGUICommands
extends SimpleClickCommands
const PFX_NODE_NAME := "PFX"

func fallback() -> void:
	super()

func click_clickable() -> void:
	super()

func right_click_clickable() -> void:
	super()

func click_inventory_item() -> void:
	super()

func right_click_inventory_item() -> void:
	super()

func postfx_apply_config(config: Dictionary, context: String = "global") -> void:
	_call_pfx("apply_config", [config, context])

func postfx_set_feature(feature: String, enabled: bool, context: String = "global") -> void:
	_call_pfx("set_feature", [feature, enabled, context])

func postfx_set_param(param: String, value, context: String = "global") -> void:
	_call_pfx("set_param", [param, value, context])

func postfx_adjust_param(param: String, delta, min_value = null, max_value = null, context: String = "global") -> void:
	_call_pfx("adjust_param", [param, delta, min_value, max_value, context])

func postfx_get_param(param: String, context: String = "global"):
	return _call_pfx("get_param", [param, context])

func postfx_get_config(context: String = "global") -> Dictionary:
	var result = _call_pfx("get_config", [context])
	return result if result is Dictionary else {}

func postfx_clear_config(context: String = "global") -> void:
	_call_pfx("clear_config", [context])

func postfx_room_apply_config(room: PopochiuRoom, config: Dictionary, context: String = "") -> void:
	_call_pfx("apply_room_config", [room, config, context])

func postfx_room_set_param(room: PopochiuRoom, param: String, value, context: String = "") -> void:
	_call_pfx("set_room_param", [room, param, value, context])

func postfx_room_set_feature(room: PopochiuRoom, feature: String, enabled: bool, context: String = "") -> void:
	_call_pfx("set_room_feature", [room, feature, enabled, context])

func postfx_room_clear_config(room: PopochiuRoom, context: String = "") -> void:
	_call_pfx("clear_room_config", [room, context])

func postfx_register_room_default(script_name: String, config: Dictionary) -> void:
	_call_pfx("register_room_default", [script_name, config])

func postfx_get_room_default(script_name: String) -> Dictionary:
	var result = _call_pfx("get_room_default", [script_name])
	return result if result is Dictionary else {}

func postfx_toggle_crt(enabled: bool = true, context: String = "global") -> void:
	_call_pfx("set_feature", ["crt", enabled, context])


func _call_pfx(method: StringName, args: Array = []):
	var pfx := _get_pfx()
	if pfx == null:
		push_warning("Popochiu Addons: PFX autoload not found; skipping '%s' call." % method)
		return null
	if not pfx.has_method(method):
		push_warning("Popochiu Addons: PFX is missing method '%s'." % method)
		return null
	return pfx.callv(method, args)


func _get_pfx() -> Node:
	var main_loop := Engine.get_main_loop()
	if main_loop is SceneTree:
		return main_loop.root.get_node_or_null(PFX_NODE_NAME)
	return null
