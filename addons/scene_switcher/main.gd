tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton("SceneSwitcherManager", "res://addons/scene_switcher/scene_switcher_manager.gd")


func _exit_tree():
	remove_autoload_singleton("SceneSwitcherManager")
