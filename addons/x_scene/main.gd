tool
extends EditorPlugin


func _enter_tree():
	add_autoload_singleton(
		"XSceneManager", "res://addons/x_scene/x_scene_manager.gd"
	)


func _exit_tree():
	remove_autoload_singleton("XSceneManager")
