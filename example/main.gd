extends Node

var scene1 = preload("scene1.tscn")
var scene2 = preload("scene2.tscn")
var scene3 = preload("scene3.tscn")


func _ready():
	# the basic usage
	tutorial_basics()

	# change the default values for function calls
	# tutorial_defaults()

	# details on usage of deferred argument
	# tutorial_deferred()

	# the sync feature
	# tutorial_sync()

	# the subscene feature / self validity check
	# tutorial_subscene()

	# the pack feature
	# tutorial_pack()

	# the benchmark code that was used for the README
	# tutorial_time()

	pass


func tutorial_basics():
	# gives instance of XScene with x.root = $"World"
	# x adds and removes scenes below x.root
	# it takes a Node 
	var x = XSceneManager.get_x_scene($"World")
	# or a NodePath
	# var x = XSceneManager.get_x_scene(@"World")
	# the Node has to be in the scenetree 

	# add_scene takes a PackedScene or a Node
	# it defaults to key=count, method=ACTIVE, deferred=false, recursive_owner=false
	# count is an int that is automatically incremented and starts at 1
	x.add_scene(scene1)
	# print(x.get_scenes()[1])
	#  -> {scene:[Node2D:1235], status:0}
	x.add_scene(scene1, "a", x.HIDDEN)
	# print(x.get_scenes().a)
	#  -> {scene:[Node2D:1239], status:1}
	x.add_scene(scene1, "stopped_s1", x.STOPPED)
	# print(x.get_scenes()["stopped_s1"])
	#  -> {scene:[Node2D:1243], status:2}
	# print(x.scenes)
	#  -> 
	# {1:{scene:[Node2D:1235], status:0},
	# a:{scene:[Node2D:1239], status:1},
	# stopped_s1:{scene:[Node2D:1243], status:2}}
	# get_node("/root").print_tree_pretty()
	# ┖╴root
	# 	┠╴XSceneManager
	# 	┃  ┖╴@@2 <- x
	# 	┖╴Main
	# 	   ┠╴Gui
	# 	   ┃  ┖╴ColorRect
	# 	   ┠╴World
	# 	   ┃  ┠╴Node2D <- was already in the tree via editor
	# 	   ┃  ┃  ┖╴Node2D
	# 	   ┃  ┃     ┖╴Node2D
	# 	   ┃  ┃        ┖╴icon
	# 	   ┃  ┠╴@Node2D@3 <- 1
	# 	   ┃  ┃  ┖╴Node2D
	# 	   ┃  ┃     ┖╴Node2D
	# 	   ┃  ┃        ┖╴icon
	# 	   ┃  ┖╴@Node2D@4 <- "a" 
	# 	   ┃     ┖╴Node2D
	# 	   ┃        ┖╴Node2D
	# 	   ┃           ┖╴icon
	# 	   ┖╴Test
	# "stopped_s1" is not in the tree
	x.remove_scene(1, x.STOPPED)
	# get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┠╴Node2D
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┖╴@Node2D@4 <- "a" still hidden but in tree
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test
	# 1 is no longer in the tree
	# print(x.get_scenes()[1])
	#  -> {scene:[Node2D:1235], status:2}
	# print(x.stopped)
	# -> [1, stopped_s1]
	for s in x.stopped:
		x.show_scene(s)
	# print(x.get_scenes()["stopped_s1"])
	# -> {stopped_s1:{scene:[Node2D:1243], status:0}
	# get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┠╴Node2D
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┠╴@Node2D@4 
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┠╴@Node2D@3 <- 1 active again
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┖╴@Node2D@5 <- "stopped_s1" active again
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test
	# frees active "stopped_s1", and makes "a" active. before, it was hidden
	# it uses show_scene and remove_scene under the hood
	x.x_scene("a", "stopped_s1", x.FREE)
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1235], status:0}, a:{scene:[Node2D:1239], status:0}}
	# instances scene2 as x.count which is 2 and makes it active, if key_from is null, 
	# the default, the last active scene is used, in this case "a", it is freed
	# it uses add_scene and remove_scene under the hood
	x.x_add_scene(scene2, x.count, null, x.ACTIVE, x.FREE)
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1235], status:0}, 2:{scene:[Node2D:1247], status:0}}
	# hides 2 externally
	# x.scenes[2].scene.hide()
	# this is a quicker syntax to access ("x"ess) the scene directly
	x.x(2).hide()
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1235], status:0}, 2:{scene:[Node2D:1247], status:1}}
	# stoppes 2 externally
	$"World".remove_child(x.x(2))
	# print(x.stopped)
	# -> [2]
	# frees 1 externally
	x.x(1).free()
	# print(x.scenes)
	# -> {2:{scene:[Node2D:1247], status:2}}
	# all these external changes to tracked scenes will be (lazily) synced when 
	# accessing the scenes in any way
	# frees all scenes
	for s in x.scenes:
		x.remove_scene(s)


func tutorial_defaults():
	# the defaults of add/show/remove can be changed
	var x = XSceneManager.get_x_scene($"World")

	# deferred is used in add/show/remove
	# recursive_owner is only used in add
	# changing count_start will only have an effect, when count wasn't incremented yet
	# for if you prefer 0-indexing
	x.defaults = {
		deferred = false,
		recursive_owner = false,
		method_add = x.ACTIVE,
		method_remove = x.FREE,
		count_start = 1
	}
	# these are the actual defaults, you can change them all at once
	# or individually like this
	x.defaults.deferred = true
	# this will be called deferred now because we changed the default to true
	x.add_scene(scene1)
	# could also be done like this without changing the default
	# x.add_scene(scene1, x.count, x.ACTIVE, true)
	# print(x.scenes)
	# -> {}
	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], status:0}}

func tutorial_deferred():
	var x = XSceneManager.get_x_scene($"World")
	# when deferred is true, every tree change will be call_deferred() or queue_free()
	# this does not include hide() and show(), these are always done immediately
	# make an issue on github if you want this changed or do it yourself
	x.defaults.deferred = true

	x.add_scene(scene1)
	# print(x.scenes)
	# -> {}
	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], status:0}}

	x.remove_scene(1, x.STOPPED)
	# despite deferred call, its status is changed immediately
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], status:2}}
	# get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┠╴Node2D
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┖╴@Node2D@3 <- still in the tree
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test

	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], status:2}}
	# get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┖╴Node2D
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test
	# not in the tree any longer


	x.show_scene(1)
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], status:2}}
	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], status:0}}

	# uses queue_free()
	x.remove_scene(1)
	# despite deferred call, it is removed from scenes immediately
	# print(x.scenes)
	# -> {}
	# get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┠╴Node2D
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┖╴@Node2D@3 <- still in the tree
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test
	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {}
	# get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┖╴Node2D
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test
	# not in the tree any longer


func tutorial_sync():
	# the sync feature can be slow, see ## Caveats in the README.md
	# the sync tracks all external additions to the tree under x.root
	var x = XSceneManager.get_x_scene($"World", true)

	# this scene was already added in the editor
	# because sync is on for this XScene Instance, it is added to scenes
	# and count is used as the key
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1227], status:0}}
	var w = x.root

	var two = scene2.instance()
	var three = scene3.instance()

	w.add_child(two)
	w.add_child(three)

	# print(x.scenes)
	# -> {1:{scene:[Node2D:1227], status:0}, 2:{scene:[Node2D:1235], status:0}, 3:{scene:[Node2D:1237], status:0}}

	# externally hide 2 and stop 3
	# for operations that can be done with remove_scene(), the sync feature
	# is not necessary. The sync is always done for tracked scenes when accessing them (lazily)
	two.hide()
	w.remove_child(three)
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1226], status:0}, 2:{scene:[Node2D:1234], status:1}, 3:{scene:[Node2D:1236], status:2}}

	# adds a child under Main, which isn't the x.root, so it's not indexed
	add_child(scene1.instance())
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1227], status:0}, 2:{scene:[Node2D:1235], status:0}, 3:{scene:[Node2D:1237], status:0}}
	# get_node("/root").print_tree_pretty()
	#┖╴root
	# 	┠╴XSceneManager
	# 	┃  ┖╴@@2
	# 	┖╴Main
	# 	   ┠╴Gui
	# 	   ┃  ┖╴ColorRect
	# 	   ┠╴World
	# 	   ┃  ┠╴Node2D <- 1
	# 	   ┃  ┃  ┖╴Node2D
	# 	   ┃  ┃     ┖╴Node2D
	# 	   ┃  ┃        ┖╴icon
	# 	   ┃  ┠╴@Node2D@3 <- 2
	# 	   ┃  ┃  ┖╴icon
	# 	   ┠╴Test
	# 	   ┖╴Node2D <- not indexed
	# 		  ┖╴Node2D
	# 			 ┖╴Node2D
	# 				┖╴icon
	# print(x._get_last_active())
	# -> 1
	x.add_scene(scene1, "internal")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1226], status:0}, 2:{scene:[Node2D:1234], status:1}, 3:{scene:[Node2D:1236], status:2}, internal:{scene:[Node2D:1242], status:0}}
	# print(x._get_last_active())
	# -> internal


func tutorial_subscene():
	var x = XSceneManager.get_x_scene($"World")

	x.add_scene(scene1, "a")

	# x1.root is "a" which is below x.root
	var x1 = XSceneManager.get_x_scene(x.scenes["a"].scene)

	x1.add_scene(scene1, "aa")
	# this frees the x1.root
	x.remove_scene("a")

	# this doesn't throw an error, it calls queue_free() for x1
	x1.add_scene(scene1, "bb")
	# uncomment this to get the error, after it x1 will be freed
	# yield(get_tree(), "idle_frame") 
	# comment this unsafe call after uncommenting yield
	x1.add_scene(scene1, "cc")
	# if you check you are still safe
	if is_instance_valid(x1):
		x1.add_scene(scene1, "dd")
	else:
		print("x1 was freed but its fine")


func tutorial_pack():
	var x = XSceneManager.get_x_scene($"World")

	var n1 = Node.new()
	var n2 = Node.new()
	var n3 = Node.new()
	n1.add_child(n2)
	n2.add_child(n3)

	# the last argument passed in, makes x.root owner of every node below n1
	# this is only necessary for scenes constructed in scripts 
	# scenes made in the editor will be packed recursively without it
	x.add_scene(n1, "b", 0, false, true)
	# this packs x.root
	x.pack("res://example/test.scn")

	$"/root/Main/Test".add_child(load("res://example/test.scn").instance())


func tutorial_time():
	var time_begin
	var time_add
	var time_remove
	var x

	var p = $World
	var n = 1000
	var m = 10

	# -------------

	x = XSceneManager.get_x_scene(p, true)

	time_add = 0.0
	time_remove = 0.0

	for j in range(m):
		time_begin = OS.get_ticks_usec()
		for i in range(n):
			x.add_scene(scene1)
		time_add += (OS.get_ticks_usec() - time_begin) / 1000000.0

		time_begin = OS.get_ticks_usec()
		for i in x.scenes.keys():
			x.remove_scene(i)
		time_remove += (OS.get_ticks_usec() - time_begin) / 1000000.0

	time_add /= m
	time_remove /= m

	print("sync add in ", time_add)
	print("sync remove in ", time_remove)

	time_add = 0.0
	time_remove = 0.0

	for j in range(m):
		time_begin = OS.get_ticks_usec()
		for i in range(n):
			p.add_child(scene1.instance())
		time_add += (OS.get_ticks_usec() - time_begin) / 1000000.0

		time_begin = OS.get_ticks_usec()
		for i in p.get_children():
			i.free()
		time_remove += (OS.get_ticks_usec() - time_begin) / 1000000.0
	time_add /= m
	time_remove /= m

	print("sync add ex ", time_add)
	print("sync remove ex ", time_remove)

	x.free()

	# -------------

	time_add = 0.0
	time_remove = 0.0

	for j in range(m):
		time_begin = OS.get_ticks_usec()
		for i in range(n):
			p.add_child(scene1.instance())
		time_add += (OS.get_ticks_usec() - time_begin) / 1000000.0

		time_begin = OS.get_ticks_usec()
		for i in p.get_children():
			i.free()
		time_remove += (OS.get_ticks_usec() - time_begin) / 1000000.0
	time_add /= m
	time_remove /= m

	print("builtin add ", time_add)
	print("builtin remove ", time_remove)

	# -------------

	x = XSceneManager.get_x_scene(p)

	time_add = 0.0
	time_remove = 0.0

	for j in range(m):
		time_begin = OS.get_ticks_usec()
		for i in range(n):
			x.add_scene(scene1)
		time_add += (OS.get_ticks_usec() - time_begin) / 1000000.0

		time_begin = OS.get_ticks_usec()
		for i in x.scenes.keys():
			x.remove_scene(i)
		time_remove += (OS.get_ticks_usec() - time_begin) / 1000000.0

	x.free()

	time_add /= m
	time_remove /= m

	print("nosync add ", time_add)
	print("nosync remove ", time_remove)
