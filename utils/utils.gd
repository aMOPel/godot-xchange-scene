extends Node

# handles utility classes
# should be an AutoLoad script named Utils

var scene_switcher = load("utils/scene_switcher.gd")


func get_scene_switcher(path: NodePath, synchronize:= false, sync_no_duplicates:= false):
	var sw = scene_switcher.new(path, synchronize, sync_no_duplicates)
	add_child(sw)
	return sw
