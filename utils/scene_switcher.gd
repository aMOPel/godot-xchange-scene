class_name SceneSwitcher

extends Node

# high level interface to switch scenes
# is instanced by the Utils Autoload script with Utils.get_scene_switcher(path)
# takes an absolute NodePath and can manipulate scenes under it
# can add/remove/show scenes and keeps track of different states of scenes
# scenes can be: 
# ACTIVE active/free (deleted from memory) 
# HIDDEN visible/hidden (still in memory and running)
# STOPPED attached to/removed from the tree (still in memory but not running)
# @count is a self incrementing counter for when adding scenes without providing a name string
# @path contains the path to the scene below which scenes will be manipulated
# @_scenes dict with int or string as keys and Nodes as values. 
# Holds all scenes below @path regardless of state. 
# However a freed scene will be removed from scenes.
# @_active_scenes , @_hidden_scenes , @_stopped_scenes
# hold keys of _scenes kept track of respectively to state of scenes
# @flag_sync if true every tree change will be reflected in the _scenes dictionary,
# this might be very slow when many nodes are added to the tree in general

enum { ACTIVE, HIDDEN, STOPPED }

var _active_scenes := [] setget _set_active_scenes, get_active_scenes
var _hidden_scenes := [] setget _set_hidden_scenes, get_hidden_scenes
var _stopped_scenes := [] setget _set_hidden_scenes, get_stopped_scenes
var _scenes := {} setget set_scenes, get_scenes

var count := 1
var path: NodePath
onready var local_root := get_node(path)

var flag_sync: bool


func _init(p: NodePath, syncronize := false):
	path = p
	flag_sync = syncronize


func _ready():
	# these are for syncing nodes that are added or removed by something other 
	# than methods of this class
	if flag_sync:
		get_tree().connect("node_added", self, "_on_node_added")
		get_tree().connect("node_removed", self, "_on_node_removed")
		# this incorporates the existing child scenes of path into the tracker lists
		var children = local_root.get_children()
		if children:
			for s in children:
				_on_node_added(s)


func _set_active_scenes(array: Array):
	assert(false, "do not set _active_scenes manually")


func get_active_scenes() -> Array:
	_check_scenes()
	return _active_scenes


func _set_hidden_scenes(array: Array):
	assert(false, "do not set _hidden_scenes manually")


func get_hidden_scenes() -> Array:
	_check_scenes()
	return _hidden_scenes


func _set_stopped_scenes(array: Array):
	assert(false, "do not set _stopped_scenes manually")


func get_stopped_scenes() -> Array:
	_check_scenes()
	return _stopped_scenes


func set_scenes(dict: Dictionary):
	assert(false, "do not set _scenes manually")


func get_scenes() -> Dictionary:
	_check_scenes()
	return _scenes


func add_scene(scene: PackedScene, method := ACTIVE, key = count):
	assert(key is int or key is String, "add_scene: key must be int or String")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"add_scene: invalid method value"
	)

	var s = scene.instance()

	match method:
		ACTIVE:
			_active_scenes.push_back(key)
			local_root.call_deferred("add_child", "s")
		HIDDEN:
			assert(
				s is CanvasItem,
				"add_scene: scene must inherit from CanvasItem to be hidden"
			)
			_hidden_scenes.push_back(key)
			local_root.call_deferred("add_child", "s")
			s.hide()
		STOPPED:
			_stopped_scenes.push_back(key)

	_scenes[key] = s

	if key is int and key == count:
		count += 1


func show_scene(key = count):
	assert(key in _scenes, "show_scene: key not in _scenes")
	assert(! (key in _active_scenes), "show_scene: scene already visible")

	if _check_scene(key):
		if key in _hidden_scenes:
			assert(
				_scenes[key] is CanvasItem,
				"show_scene: BUG scene must inherit from CanvasItem to be shown"
			)
			_scenes[key].show()
			_hidden_scenes.erase(key)
		elif key in _stopped_scenes:
			local_root.call_deferred("add_child", "s")
			_stopped_scenes.erase(key)
		_active_scenes.push_back(key)


func remove_scene(key = count, method := ACTIVE):
	assert(key in _scenes, "remove_scene: key not in _scenes")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"remove_scene: invalid method value"
	)

	if _check_scene(key):
		if key in _active_scenes:
			_active_scenes.erase(key)
		elif key in _hidden_scenes:
			_hidden_scenes.erase(key)
		elif key in _stopped_scenes:
			_stopped_scenes.erase(key)

		match method:
			ACTIVE:
				_scenes[key].call_deferred("free")
				_scenes.erase(key)
			HIDDEN:
				assert(
					_scenes[key] is CanvasItem,
					"remove_scene: scene must inherit from CanvasItem to be hidden"
				)
				_scenes[key].hide()
				_hidden_scenes.push_back(key)
			STOPPED:
				local_root.call_deferred("remove_child", _scenes[key])
				_stopped_scenes.push_back(key)


func switch_scene(key_to, key_from = _active_scenes[-1], method1 := ACTIVE):
	assert(key_from in _active_scenes, "switch_scene: scene_from not active")
	assert(
		! (key_to in _active_scenes), "switch_scene: scene_to already active"
	)
	assert(
		key_to in _hidden_scenes or key_to in _stopped_scenes,
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
	key_to = count,
	key_from := _active_scenes[-1],
	method_to := ACTIVE,
	method_from := ACTIVE
):
	assert(key_from in _active_scenes, "switch_scene: scene1 not active")
	assert(
		ACTIVE <= method_to and method_to <= STOPPED,
		"switch_scene: invalid method value"
	)
	assert(
		ACTIVE <= method_from and method_from <= STOPPED,
		"switch_scene: invalid method value"
	)

	add_scene(scene_to, method_to, key_to)
	remove_scene(key_from, method_from)


func _check_scenes():
	for k in _scenes:
		_check_scene(k)


func _check_scene(key) -> bool:
	assert(key in _scenes, "_check_scene: key not in _scenes")

	if (
		is_instance_valid(_scenes[key])
		and not _scenes[key].is_queued_for_deletion()
	):
		return true
	else:
		_scenes.erase(key)
		if key in _active_scenes:
			_active_scenes.erase(key)
		elif key in _hidden_scenes:
			_hidden_scenes.erase(key)
		elif key in _stopped_scenes:
			_stopped_scenes.erase(key)
		print_debug("_check_scene: scene ", key, " was already freed")
		return false


func _on_node_added(node: Node):
	if node.get_parent() == local_root:
		if ! (node in _scenes):
			_scenes[count] = node
			if node is CanvasItem:
				if node.visible:
					_active_scenes.push_back(count)
				else:
					_hidden_scenes.push_back(count)
			count += 1


func _on_node_removed(node: Node):
	# doesnt work correctly when node.free() is called because this function is 
	# called before it is freed so is_instance_valid(node) is true and its not 
	# is_queued_for_deletion() since thats only the case when node.queue_free() 
	# is called
	for k in _scenes:
		if _scenes[k] == node:
			if is_instance_valid(node) and not node.is_queued_for_deletion():
				if ! (k in _stopped_scenes):
					_stopped_scenes.push_back(k)
			else:
				_scenes.erase(k)
				if k in _hidden_scenes:
					_hidden_scenes.erase(k)
				elif k in _stopped_scenes:
					_stopped_scenes.erase(k)
			if k in _active_scenes:
				_active_scenes.erase(k)


func _to_string():
	var s = ""
	s += "active: " + _active_scenes as String + "\n"
	s += "hidden: " + _hidden_scenes as String + "\n"
	s += "stopped: " + _stopped_scenes as String + "\n"
	s += "_scenes: " + _scenes as String + "\n"
	s += "count: " + count as String + "\n"
	s += "path: " + path as String + "\n"
	s += local_root.get_children() as String + "\n"
	get_node("/root").print_stray_nodes()
	get_node("/root").print_tree_pretty()
	return s

#get_tree() tree_changed to sync
#node is_inside_tree()
#node has_node(Node)
#gdscript is_instance_valid(objectq)
