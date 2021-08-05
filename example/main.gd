extends Node

var scene1 = preload("scene1.tscn")

func _ready():
	var p = Node2D.new()
	add_child(p)
	var time_begin = OS.get_ticks_usec()
	for i in range(100):
		p.add_child(scene1.instance())
	print((OS.get_ticks_usec() - time_begin)/1000000.0)

	# time_begin = OS.get_ticks_usec()
	# for i in p.get_children():
	# 	i.free()
	# print((OS.get_ticks_usec() - time_begin)/1000000.0)

	pass
