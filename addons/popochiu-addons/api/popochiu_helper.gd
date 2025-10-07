class_name PopochiuAddonsHelper
extends "res://addons/popochiu/engine/helpers/popochiu_helper.gd"

func fade_prop(prop: Variant, target_alpha: float, config := {}) -> Variant:
        return G.fade_prop(prop, target_alpha, _duplicate_config(config))

func fade_prop_in(prop: Variant, config := {}) -> Variant:
        return G.fade_prop_in(prop, _duplicate_config(config))

func fade_prop_out(prop: Variant, config := {}) -> Variant:
        return G.fade_prop_out(prop, _duplicate_config(config))

func queue_fade_prop(prop: Variant, target_alpha: float, config := {}) -> Callable:
        var duplicate := _duplicate_config(config)
        return func () -> void:
                await G.fade_prop(prop, target_alpha, _queue_config(duplicate))

func queue_fade_prop_in(prop: Variant, config := {}) -> Callable:
        return queue_fade_prop(prop, 1.0, config)

func queue_fade_prop_out(prop: Variant, config := {}) -> Callable:
        return queue_fade_prop(prop, 0.0, config)


func _duplicate_config(config := {}) -> Dictionary:
        if config is Dictionary:
                return config.duplicate(true)
        return {}

func _queue_config(config: Dictionary) -> Dictionary:
        var duplicate := config.duplicate(true)
        duplicate["blocking"] = true
        return duplicate
