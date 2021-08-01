class_name SceneSwitcher

extends Node

# high level interface to switch scenes
# is instanced by the Utils Autoload script with Utils.get_scene_switcher(path)
# takes an absolute NodePath and can manipulate scenes under it
# can add/remove/show scenes and keeps track of different states of scenes
# scenes can be: 
# ACTIVE active/free (deleted from memory) 
# HIDDEN visible/hidden (still in memory and running)
# STOPPED removed from/attached to the tree (still in memory but not running)
# @count is a self incrementing counter for when adding scenes without providing a name string
# @path contains the path to the scene below which scenes will be manipulated
# @scenes dict with int or string as keys and Nodes as values. 
# Holds all scenes below @path regardless of state. 
# However a freed scene will be removed from scenes.
# @active_scenes , @hidden_scenes , @stopped_scenes
# hold keys of scenes kept track of respectively to state of scenes

enum { ACTIVE, HIDDEN, STOPPED }

var active_scenes := []
var hidden_scenes := []
var stopped_scenes := []
var scenes := {}

var count := 1
var path: NodePath


func _init(p: NodePath):
	path = p


func _ready():
	# this incorporates the existing child scenes of path into the tracker lists
	var children = get_node(path).get_children()
	if children:
		for s in children:
			scenes[count] = s
			if s.visible:
				active_scenes.push_back(count)
			else:
				hidden_scenes.push_back(count)
			count += 1


func add_scene(scene: PackedScene, method := ACTIVE, key = count):
	assert(key is int or key is String, "add_scene: key must be int or String")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"add_scene: invalid method value"
	)
	print(get_node(path))

	var s = scene.instance()

	match method:
		ACTIVE:
			active_scenes.push_back(key)
			get_node(path).add_child(s)
		HIDDEN:
			hidden_scenes.push_back(key)
			get_node(path).add_child(s)
			s.hide()
		STOPPED:
			stopped_scenes.push_back(key)

	scenes[key] = s

	if key is int and key == count:
		count += 1


func show_scene(key = count):
	assert(key in scenes, "show_scene: key not in scenes")
	assert(! (key in active_scenes), "show_scene: scene already visible")

	if key in hidden_scenes:
		scenes[key].show()
		hidden_scenes.erase(key)
	elif key in stopped_scenes:
		get_node(path).add_child(scenes[key])
		stopped_scenes.erase(key)

	active_scenes.push_back(key)


func remove_scene(key = count, method := ACTIVE):
	assert(key in scenes, "remove_scene: key not in scenes")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"remove_scene: invalid method value"
	)

	if key in active_scenes:
		active_scenes.erase(key)
	elif key in hidden_scenes:
		hidden_scenes.erase(key)
	elif key in stopped_scenes:
		stopped_scenes.erase(key)

	match method:
		ACTIVE:
			scenes[key].call_deferred("free")
			scenes.erase(key)
		HIDDEN:
			scenes[key].hide()
			hidden_scenes.push_back(key)
		STOPPED:
			get_node(path).call_deferred("remove_child", scenes[key])
			stopped_scenes.push_back(key)


func switch_scene(key_to, key_from := active_scenes[-1], method1 := ACTIVE):
	assert(key_from in active_scenes, "switch_scene: scene1 not active")
	assert(! (key_to in active_scenes), "switch_scene: scene2 already active")
	assert(
		key_to in hidden_scenes or key_to in stopped_scenes,
		"switch_scene: scene2 is neither hidden nor stopped"
	)
	assert(
		ACTIVE <= method1 and method1 <= STOPPED,
		"switch_scene: invalid method value"
	)

	remove_scene(key_from, method1)
	show_scene(key_to)


func switch_new_scene(
	scene_to: PackedScene,
	key_from := active_scenes[-1],
	method_to := ACTIVE,
	method_from := ACTIVE
):
	assert(key_from in active_scenes, "switch_scene: scene1 not active")
	assert(
		ACTIVE <= method_to and method_to <= STOPPED,
		"switch_scene: invalid method value"
	)
	assert(
		ACTIVE <= method_from and method_from <= STOPPED,
		"switch_scene: invalid method value"
	)

	add_scene(scene_to, method_to)
	remove_scene(key_from, method_from)


func _to_string():
	var s = ""
	s += "active: " + active_scenes as String + "\n"
	s += "hidden: " + hidden_scenes as String + "\n"
	s += "stopped: " + stopped_scenes as String + "\n"
	s += "scenes: " + scenes as String + "\n"
	s += "count: " + count as String + "\n"
	s += "path: " + path as String + "\n"
	s += get_node(path).get_children() as String + "\n"
	return s
