extends Node

var scene1 = preload("scene1.tscn")
var scene2 = preload("scene2.tscn")
var scene3 = preload("scene3.tscn")


func _ready():
	# the basic usage
	# tutorial_basics()

	# bulk functions
	# tutorial_bulk()

	# change the default values for function calls
	tutorial_defaults()

	# details on usage of deferred argument
	# tutorial_deferred()

	# the sync feature
	# tutorial_sync()

	# the nested feature
	# tutorial_nested()

	# the pack feature
	# tutorial_pack()

	# the benchmark code that was used for the README
	# running all tests at once might take forever, i dont know why
	# tutorial_time()

	# tutorial_readme()

	pass


func tutorial_basics():
	# gives instance of XScene with x.root = $"World"
	# x adds and removes direct children of x.root
	# it takes a Node which has to be in the scenetree
	var x = XScene.new($World)

	# x is only concerned with the direct children of root.

	# x adds itself to the tree below root
	# this is good because it will be freed automatically when root is freed
	# however you have to keep in mind, that when iterating over the children of root
	# x will be among them

	# add_scene takes a PackedScene or a Node
	# it defaults to key=count, method=ACTIVE, deferred=false, recursive_owner=false
	# count is an int that is automatically incremented and starts at 1
	x.add_scene(scene1)
	# print(x.scenes)
	#  -> {1:{scene:[Node2D:1235], state:0}}
	x.add_scene(scene1, "a", x.HIDDEN)
	# print(x.scenes["a"])
	#  -> {scene:[Node2D:1239], state:1}
	x.add_scene(scene1, "stopped_s1", x.STOPPED)
	# print(x.scenes)
	#  ->
	# {1:{scene:[Node2D:1235], state:0},
	# a:{scene:[Node2D:1239], state:1},
	# stopped_s1:{scene:[Node2D:1243], state:2}}
	# get_node("/root").print_tree_pretty()
	# ┖╴root
	#    ┖╴Main
	#       ┠╴Gui
	#       ┃  ┖╴ColorRect
	#       ┠╴World
	#       ┃  ┠╴Node2D
	#       ┃  ┃  ┖╴Node2D
	#       ┃  ┃     ┖╴Node2D
	#       ┃  ┃        ┖╴icon
	#       ┃  ┠╴@@2 <- x
	#       ┃  ┠╴@Node2D@3 <- 1
	#       ┃  ┃  ┖╴Node2D
	#       ┃  ┃     ┖╴Node2D
	#       ┃  ┃        ┖╴icon
	#       ┃  ┖╴@Node2D@4 <- "a"
	#       ┃     ┖╴Node2D
	#       ┃        ┖╴Node2D
	#       ┃           ┖╴icon
	#       ┖╴Test
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
	# print(x.scenes[1])
	#  -> {scene:[Node2D:1235], state:2}
	# print(x.stopped)
	# -> [1, stopped_s1]
	for s in x.stopped:
		x.show_scene(s)
	# print(x.get_scenes()["stopped_s1"])
	# -> {stopped_s1:{scene:[Node2D:1243], state:0}
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

	# frees active "stopped_s1", and makes "a" active. before that, it was hidden
	# it uses show_scene and remove_scene under the hood
	x.x_scene("a", "stopped_s1", x.FREE)
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1235], state:0}, a:{scene:[Node2D:1239], state:0}}

	# instances scene2 as x.count which is 2 and makes it active, if key_from is null,
	# the default, the last active scene is used, in this case "a", it is freed
	# it uses add_scene and remove_scene under the hood
	x.x_add_scene(scene2, x.count, null, x.ACTIVE, x.FREE)
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1235], state:0}, 2:{scene:[Node2D:1247], state:0}}

	# hides 2 externally
	x.scenes[2].scene.hide()

	# this is a quicker and safer syntax to access ("x"ess) the scene directly
	x.x(2).hide()
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1235], state:0}, 2:{scene:[Node2D:1247], state:1}}

	# stoppes 2 externally
	$"World".remove_child(x.x(2))
	# print(x.stopped)
	# -> [2]

	# frees 1 externally
	x.x(1).free()
	# print(x.scenes)
	# -> {2:{scene:[Node2D:1247], state:2}}

	# all these external changes to indexed scenes will be (lazily) synced when
	# accessing the scenes in any way

	# this is a faster syntax to get all node references in an array
	# print(x.xs())
	# -> [[Node2D:1246]]

	# same but only for stopped scenes, also works for ACTIVE and HIDDEN
	# print(x.xs(x.STOPPED))
	# -> [[Node2D:1246]]

	# frees all scenes
	for s in x.scenes:
		x.remove_scene(s)


func tutorial_access():
	var x = XScene.new($World)

	x.add_scene(scene1)

	# this is the proper way to access single nodes in x.scenes,
	# it returns null if the index doesnt exist
	x.x(1)
	# this is the proper way to access multiple nodes in x.scenes,
	# it returns an empty array if no keys of the state still exist
	x.xs()
	x.xs(x.ACTIVE)  # etc

	# this is the proper way to access keys of a specific state, these are all arrays
	x.active
	x.hidden
	x.stopped
	# or all of them
	x.scenes.keys()

	# should normally not be necessary
	x.scenes

	# should be avoided, because the node at index may have been freed, and if so,
	# the dictionary entry is erased. this means you can get an access error from this
	x.scenes[1]
	# same goes for the arrays
	x.active[0]

	# there is no save way to access the state of a specific key yet, because i
	# didnt deem it necessary. if you disagree, open an issue


func tutorial_bulk():
	var x = XScene.new($World)

	# there are also convenience functions to add/show/remove multiple scenes at once,
	# this is especially useful when using x.active/x.hidden/x.stopped

	# adds 3 scenes indexed with count
	x.add_scenes([scene1, scene2, scene3])
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1249], state:0}, 2:{scene:[Node2D:1253], state:0}, 3:{scene:[Node2D:1255], state:0}}

	# frees all active scenes
	x.remove_scenes(x.active)
	# print(x.scenes)
	# -> {}

	# adds 3 stopped scenes indexed with array
	x.add_scenes([scene1, scene2, scene3], ["a", "b", "c"], x.STOPPED)
	# print(x.scenes)
	# -> {a:{scene:[Node2D:1257], state:2}, b:{scene:[Node2D:1261], state:2}, c:{scene:[Node2D:1263], state:2}}

	# show all scenes
	x.show_scenes(x.scenes.keys())
	# print(x.scenes)
	# -> {a:{scene:[Node2D:1257], state:0}, b:{scene:[Node2D:1261], state:0}, c:{scene:[Node2D:1263], state:0}}


func tutorial_defaults():
	# the defaults of add/show/remove can be changed
	var x = XScene.new($World)

	# deferred is used in add/show/remove
	# recursive_owner is only used in add
	# changing count_start will only have an effect, if passed when initializing

	# these are the actual defaults
	# you can change them all at once
	x.defaults = {
		deferred = false,
		recursive_owner = false,
		method_add = x.ACTIVE,
		method_remove = x.FREE,
		count_start = 1
	}
	# you can assign a partial dictionary, this will only override the specified keys
	# and leave the others in tact
	var d = {deferred = true, count_start = 0}
	x.defaults = d
	print(x.defaults)
	# -> {count_start:0, deferred:True, method_add:0, method_remove:3, recursive_owner:False}
	# or you can change them individually like this
	x.defaults.deferred = true
	# x.defaults["deferred"] = true

	# note that count hasnt changed though
	print(x.count)
	# -> 1


	# the only way to apply the change to count_start is this:
	# you can pass the defaults when initializing as a dictionary
	var x1 = XScene.new($World, false, d)
	print(x1.count)
	# -> 0

	# this will reset the defaults
	x1.defaults = x1._original_defaults
	print(x.defaults)
	# {count_start:1, deferred:False, method_add:0, method_remove:3, recursive_owner:False}
	# but it won't reset count

	# this will be called deferred now because we changed the default to true
	x.add_scene(scene1)
	# could also be done like this without changing the default
	# x.add_scene(scene1, x.count, x.ACTIVE, true)
	# print(x.scenes)
	# -> {}
	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], state:0}}

	# if you try to do give it wrong keys or wrong values it will throw an error directly
	# so you can catch typos and semantic mistakes early
	# these all throw errors
	# x.defaults.deferre = true # invalid key
	# x.defaults.deferred = 1 # wrong type
	# x.defaults.method_add = x.FREE # add doesnt take FREE
	# x.defaults = {method_remove = 0.0} # wrong type
	# var x2 = XScene.new($World, false, {method_remove = 0.0})



func tutorial_deferred():
	var x = XScene.new($World)
	# when deferred is true, every tree change will be call_deferred() or queue_free()
	# this does not include hide() and show(), these are always done immediately
	# make an issue on github if you want this changed
	x.defaults.deferred = true

	x.add_scene(scene1)
	# print(x.scenes)
	# -> {}
	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], state:0}}

	x.remove_scene(1, x.STOPPED)
	# despite deferred call, its state is changed immediately
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], state:2}}
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
	# -> {1:{scene:[Node2D:1234], state:2}}
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
	# -> {1:{scene:[Node2D:1234], state:2}}
	yield(get_tree(), "idle_frame")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1234], state:0}}

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
	# WARNING the sync feature can be slow, see ## Caveats in the README.md
	# the sync indexes all external additions to the tree under x.root
	var x = XScene.new($World, true)

	# this scene was already added in the editor
	# because sync is on for this XScene Instance, it is added to scenes
	# and count is used as the key
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1227], state:0}}
	var w = x.root

	var two = scene2.instance()
	var three = scene3.instance()

	w.add_child(two)
	w.add_child(three)

	# print(x.scenes)
	# -> {1:{scene:[Node2D:1227], state:0}, 2:{scene:[Node2D:1235], state:0}, 3:{scene:[Node2D:1237], state:0}}

	# externally hide 2 and stop 3
	# for operations that can be done with remove_scene(), the sync feature
	# is not necessary. The sync is always done for indexed scenes when accessing them (lazily)
	two.hide()
	w.remove_child(three)
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1226], state:0}, 2:{scene:[Node2D:1234], state:1}, 3:{scene:[Node2D:1236], state:2}}

	# adds a child under Main, which isn't the x.root, so it's not indexed
	add_child(scene1.instance())
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
	x.add_scene(scene1, "internal")
	# print(x.scenes)
	# -> {1:{scene:[Node2D:1226], state:0}, 2:{scene:[Node2D:1234], state:1}, 3:{scene:[Node2D:1236], state:2}, internal:{scene:[Node2D:1242], state:0}}
	# print(x.active[-1])
	# -> internal


func tutorial_nested():
	var x = XScene.new($World)

	x.add_scene(scene1, "a")

	# x1.root is "a" which is below x.root
	var x1 = XScene.new(x.x("a"))

	x1.add_scene(scene1, "aa")
	# this frees the x1.root and therefore x1 with it
	x.remove_scene("a")

	# this throws an error because x1 is null
	# x1.add_scene(scene1, "bb")

	# if you check, you are still safe
	# if x1 == null:
	# or
	if is_instance_valid(x1):
		x1.add_scene(scene1, "dd")
	else:
		print("x1 was freed but its fine")

	# GOOD PRACTICE
	# you should make this check at the beginning of every function and after every yield
	# when planning to use the XScene instance and
	# if you want to avoid getting errors for null access


func tutorial_pack():
	var x = XScene.new($World)

	var n1 = Node.new()
	var n2 = Node.new()
	var n3 = Node.new()
	n1.add_child(n2)
	n2.add_child(n3)

	# the last argument passed in, makes x.root owner of every node below n1
	# this is only necessary for scenes constructed in scripts
	# scenes made in the editor will be packed recursively without it
	x.add_scene(n1, "b", 0, false, true)
	# this packs x.root with PackedScene.pack() and saves it with ResourceSaver.save()
	x.pack_root("res://example/test.scn")

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

	x = XScene.new(p, true)

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

	x.free()

	# time_add = 0.0
	# time_remove = 0.0
	# var time_add_pre = 0.0
	#
	# for j in range(m):
	# 	x = XScene.new(p, true)
	#
	# 	time_begin = OS.get_ticks_usec()
	# 	for i in range(n):
	# 		p.add_child(scene1.instance())
	# 	time_add += (OS.get_ticks_usec() - time_begin) / 1000000.0
	#
	# 	x.free()
	#
	# 	time_begin = OS.get_ticks_usec()
	# 	x = XScene.new(p, true)
	# 	time_add_pre += (OS.get_ticks_usec() - time_begin) / 1000000.0
	#
	# 	time_begin = OS.get_ticks_usec()
	# 	for i in p.get_children():
	# 		i.free()
	# 	time_remove += (OS.get_ticks_usec() - time_begin) / 1000000.0
	#
	# time_add /= m
	# time_remove /= m
	# time_add_pre /= m
	#
	# print("sync add ex ", time_add)
	# print("sync add ex pre ", time_add_pre)
	# print("sync remove ex ", time_remove)

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

	x = XScene.new(p)

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

	# -------------

	x = XScene.new(p)

	time_add = 0.0
	time_remove = 0.0

	for j in range(m):
		var a = []
		for i in range(n):
			a.push_back(scene1)

		time_begin = OS.get_ticks_usec()
		x.add_scenes(a)
		time_add += (OS.get_ticks_usec() - time_begin) / 1000000.0

		time_begin = OS.get_ticks_usec()
		x.remove_scenes(x.active)
		time_remove += (OS.get_ticks_usec() - time_begin) / 1000000.0

	x.free()

	time_add /= m
	time_remove /= m

	print("nosync add bulk ", time_add)
	print("nosync remove bulk ", time_remove)


func tutorial_readme():
	var scene1 = preload("scene1.tscn")
	# x adds and removes scenes below $World
	# adds itself to the tree below $World
	var x = XScene.new($World)

	# this is a reference to $World
	var r = x.root

	# add_scene takes a PackedScene or a Node
	# without a key specified it indexes automatically with integers starting at 1
	# (this can be changed to 0)
	# default method is ACTIVE, using add_child()
	x.add_scene(scene1)
	# uses add_child() and .hide()
	x.add_scene(scene1, "a", x.HIDDEN)
	# just instances and indexes the scene
	x.add_scene(scene1, "stopped_s1", x.STOPPED)

	get_node("/root").print_tree_pretty()
	# ┖╴root
	#    ┖╴Main
	#       ┠╴Gui
	#       ┃  ┖╴ColorRect
	#       ┠╴World
	#       ┃  ┠╴Node2D <- was added by the editor and isn't indexed by default
	#       ┃  ┃  ┖╴Node2D
	#       ┃  ┃     ┖╴Node2D
	#       ┃  ┃        ┖╴icon
	#       ┃  ┠╴@@2 <- x instance
	#       ┃  ┠╴@Node2D@3 <- 1
	#       ┃  ┃  ┖╴Node2D
	#       ┃  ┃     ┖╴Node2D
	#       ┃  ┃        ┖╴icon
	#       ┃  ┖╴@Node2D@4 <- "a" in the tree but hidden
	#       ┃     ┖╴Node2D
	#       ┃        ┖╴Node2D
	#       ┃           ┖╴icon
	#       ┖╴Test
	# "stopped_s1" isnt in the tree

	print(x.scenes)
	# {1:{scene:[Node2D:1227], state:0}, -> ACTIVE
	# a:{scene:[Node2D:1231], state:1}, -> HIDDEN
	# stopped_s1:{scene:[Node2D:1235], state:2}} -> STOPPED

	# uses remove_child()
	x.remove_scene(1, x.STOPPED)
	get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┠╴Node2D
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┠╴@@2
	# ┃  ┖╴@Node2D@4 <- "a" still in tree
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test
	# 1 also is no longer in the tree

	# make all STOPPED scenes ACTIVE
	# mind the plural
	x.show_scenes(x.stopped)
	get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┠╴Node2D
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┠╴@@2
	# ┃  ┠╴@Node2D@4 <- "a"
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┠╴@Node2D@3 <- 1
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┖╴@Node2D@5 <- "stopped_s1"
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test

	# exchange scene, makes "a" ACTIVE, and uses .free() on "stopped_s1"
	# it defaults to FREE, the argument isn't necessary here
	x.x_scene("a", "stopped_s1", x.FREE)
	get_node("/root").print_tree_pretty()
	# ┠╴World
	# ┃  ┠╴Node2D
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┠╴@@2
	# ┃  ┠╴@Node2D@4 <- "a" no longer hidden
	# ┃  ┃  ┖╴Node2D
	# ┃  ┃     ┖╴Node2D
	# ┃  ┃        ┖╴icon
	# ┃  ┖╴@Node2D@3 <- 1
	# ┃     ┖╴Node2D
	# ┃        ┖╴Node2D
	# ┃           ┖╴icon
	# ┖╴Test
	# "stopped_s1" was freed and is no longer indexed

	# to access ("x"ess) the scene/node of "a" directly
	x.x("a").hide()
	# to access all hidden scenes directly, returns an array of nodes
	print(x.xs(x.HIDDEN))
	# [[Node2D:1231]] <- this is the node/scene of "a" in an array
	# note that a was hidden externally and is still indexed correctly,
	# this is done lazily, only when accessing that node

	# put x.root and everything indexed into a file using PackedScene.pack() and ResourceSaver.save()
	x.pack_root("res://example/test.scn")
	# this can be loaded later, it includes x.root but not x

	# .free() everything indexed by x, remove_scene/s defaults to FREE
	# mind the plural
	x.remove_scenes(x.scenes.keys())
