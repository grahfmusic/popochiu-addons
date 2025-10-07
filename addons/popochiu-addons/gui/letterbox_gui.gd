extends "res://addons/popochiu/engine/objects/gui/templates/simple_click/simple_click_gui.gd"

const LETTERBOX_SCENE := preload("res://addons/popochiu-addons/letterbox/letterbox.tscn")

var _letterbox: LetterboxController

func _ready() -> void:
	super()
	_ensure_letterbox()

func show_letterbox(config := {}) -> Variant:
	var controller := _get_letterbox()
	return controller.show_letterbox(config) if controller else null

func hide_letterbox(config := {}) -> Variant:
	var controller := _get_letterbox()
	return controller.hide_letterbox(config) if controller else null

func queue_show_letterbox(config := {}) -> Callable:
	var controller := _get_letterbox()
	return controller.queue_show_letterbox(config) if controller else func () -> void:
		pass

func queue_hide_letterbox(config := {}) -> Callable:
	var controller := _get_letterbox()
	return controller.queue_hide_letterbox(config) if controller else func () -> void:
		pass

func is_letterbox_showing() -> bool:
	var controller := _get_letterbox()
	return controller.is_showing() if controller else false

func connect_letterbox_transition(target: Object, method: StringName, flags := 0) -> void:
	var controller := _get_letterbox()
	if controller:
		controller.connect_transition_finished(target, method, flags)

func add_letterbox_transition_listener(callback: Callable, flags := 0) -> void:
	var controller := _get_letterbox()
	if controller:
		controller.add_transition_finished_listener(callback, flags)

func _ensure_letterbox() -> void:
	if is_instance_valid(_letterbox):
		return
	var node := get_node_or_null("PopochiuAddonsLetterbox")
	if node == null:
		node = get_node_or_null("Letterbox")
	if node == null:
		node = LETTERBOX_SCENE.instantiate()
		node.name = "PopochiuAddonsLetterbox"
		add_child(node)
		move_child(node, 0)
	_letterbox = node as LetterboxController
	if _letterbox == null:
		push_warning("Popochiu Addons: LetterboxController scene not available")

func _get_letterbox() -> LetterboxController:
	_ensure_letterbox()
	return _letterbox if is_instance_valid(_letterbox) else null
