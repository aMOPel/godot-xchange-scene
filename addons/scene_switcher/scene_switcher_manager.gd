extends Node

# can create instances of SceneSwitcher below this node
# should be an AutoLoad script named SceneSwitcherManager

var scene_switcher := preload("res://addons/scene_switcher/scene_switcher.gd")


func get_scene_switcher(path: NodePath, synchronize:= false, sync_no_duplicates:= false):
	var sw = scene_switcher.new(path, synchronize, sync_no_duplicates)
	add_child(sw)
	return sw
