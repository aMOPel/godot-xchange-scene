extends Node

# can create instances of XScene below this node
# should be an AutoLoad script named XSceneManager

var x_scene := preload("res://addons/x_scene/x_scene.gd")


func get_x_scene(path, synchronize:= false):
	var sw = x_scene.new(path, synchronize)
	add_child(sw)
	return sw
