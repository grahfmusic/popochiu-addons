@tool
extends EditorPlugin

const AUTOLOAD_G_NAME := "G"
const AUTOLOAD_G_PATH := "res://addons/popochiu-addons/wrappers/g_autoload.gd"
const AUTOLOAD_PFX_NAME := "PFX"
const AUTOLOAD_PFX_PATH := "res://addons/popochiu-addons/pfx/pfx.gd"
const AUTOLOAD_HELPER_NAME := "PopochiuAddonsHelper"
const AUTOLOAD_HELPER_PATH := "res://addons/popochiu-addons/wrappers/popochiu_helper.gd"
const BACKUP_SETTING := "addons/popochiu-addons/autoload_backups"

func _enter_tree() -> void:
    _install_autoloads()

func _enable_plugin() -> void:
    _install_autoloads()

func _install_autoloads() -> void:
    var changed := false
    if _ensure_autoload(AUTOLOAD_PFX_NAME, AUTOLOAD_PFX_PATH, false):
        changed = true
    if _ensure_autoload(AUTOLOAD_HELPER_NAME, AUTOLOAD_HELPER_PATH, true):
        changed = true
    if _ensure_autoload(AUTOLOAD_G_NAME, AUTOLOAD_G_PATH, true):
        changed = true
    if changed:
        ProjectSettings.save()

func _ensure_autoload(name: String, path: String, store_backup: bool) -> bool:
    var key := "autoload/%s" % name
    var current := _get_autoload_setting(key)
    if _normalize_autoload(current) == path:
        return false
    if store_backup:
        _store_backup(name, current)
    if ProjectSettings.has_setting(key):
        remove_autoload_singleton(name)
    add_autoload_singleton(name, path)
    return true

func _get_autoload_setting(key: String) -> String:
    if ProjectSettings.has_setting(key):
        var value := ProjectSettings.get_setting(key)
        if value == null:
            return ""
        if value is String:
            return value
        return String(value)
    return ""

func _normalize_autoload(value: String) -> String:
    var trimmed := value.strip_edges()
    if trimmed.begins_with("*"):
        return trimmed.substr(1)
    return trimmed

func _store_backup(name: String, value: String) -> void:
    if value.is_empty():
        return
    var backups := _get_backups()
    if backups.has(name):
        return
    backups[name] = value
    ProjectSettings.set_setting(BACKUP_SETTING, backups)

func _get_backups() -> Dictionary:
    if ProjectSettings.has_setting(BACKUP_SETTING):
        var stored := ProjectSettings.get_setting(BACKUP_SETTING)
        if stored is Dictionary:
            return stored.duplicate(true)
    return {}
