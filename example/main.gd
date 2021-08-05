extends Node

var scene1 = preload("scene1.tscn")

func _ready():
	add_child(load("test.scn").instance())
	# var p = Node2D.new()
	# add_child(p)
	# var time_begin = OS.get_ticks_usec()
	# for i in range(10000):
	# 	p.add_child(scene1.instance())
	# print(OS.get_ticks_usec() - time_begin/100000.0)
	# 
	# time_begin = OS.get_ticks_usec()
	# for i in p.get_children():
	# 	i.free()
	# print(OS.get_ticks_usec() - time_begin/100000.0)

	pass
