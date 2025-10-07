class_name PopochiuAddonsHelper
extends Node

func fade_prop(prop: Variant, target_alpha: float, config := {}) -> Variant:
    var g := _get_g()
    if g == null:
        return null
    return g.fade_prop(prop, target_alpha, _duplicate_config(config))

func fade_prop_in(prop: Variant, config := {}) -> Variant:
    var g := _get_g()
    if g == null:
        return null
    return g.fade_prop_in(prop, _duplicate_config(config))

func fade_prop_out(prop: Variant, config := {}) -> Variant:
    var g := _get_g()
    if g == null:
        return null
    return g.fade_prop_out(prop, _duplicate_config(config))

func queue_fade_prop(prop: Variant, target_alpha: float, config := {}) -> Callable:
    var g := _get_g()
    if g == null or not g.has_method("queue_fade_prop"):
        return func () -> void:
            pass
    return g.queue_fade_prop(prop, target_alpha, _duplicate_config(config))

func queue_fade_prop_in(prop: Variant, config := {}) -> Callable:
    return queue_fade_prop(prop, 1.0, config)

func queue_fade_prop_out(prop: Variant, config := {}) -> Callable:
    return queue_fade_prop(prop, 0.0, config)

func _duplicate_config(config := {}) -> Dictionary:
    if config is Dictionary:
        return config.duplicate(true)
    return {}

func _get_g() -> Object:
    var main_loop := Engine.get_main_loop()
    if main_loop is SceneTree:
        var g_node := main_loop.root.get_node_or_null("G")
        if g_node != null:
            return g_node
    push_warning("Popochiu Addons: Unable to access G autoload from PopochiuAddonsHelper.")
    return null
