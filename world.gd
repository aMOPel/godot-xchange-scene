extends Node2D

var scene1 = preload("scene1.tscn")
var scene2 = preload("scene2.tscn")
var scene3 = preload("scene3.tscn")


func _ready():
	# init switcher with path of this node, /root/Main/World, switcher will manipulate child nodes 
	var sw = Utils.get_scene_switcher(get_path())
	print_debug(sw)
	# an instance of scene1 will already be in the tree and visible, as you can see in the editor,
	# it will also be tracked, it can be referred to with the integer 1

	# add instance of scene2 to tree but hide it and name it "b" for later reference
	sw.add_scene(scene2, sw.HIDDEN, "b")

	yield(get_tree().create_timer(2.0), "timeout")
	# sets hidden scene "b" to visible and frees the instance of scene1 in the tree, 
	# this instance is no longer tracked since its dead
	sw.switch_scene("b")
	print_debug(sw)

	yield(get_tree().create_timer(2.0), "timeout")
	# add scene3 to tree and hide it and name it "c"
	sw.add_scene(scene3, sw.HIDDEN, "c")
	# instance scene1 again and add it to the tree visible,
	# also remove "b" from the tree, its still in memory
	sw.switch_new_scene(scene1, "b", sw.ACTIVE, sw.STOPPED)
	print_debug(sw)

	yield(get_tree().create_timer(2.0), "timeout")
	# reattach "b" to scene tree
	sw.show_scene("b")

	# make "c" visible
	sw.show_scene("c")

	print_debug(sw)
