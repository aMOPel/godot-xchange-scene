class_name SceneSwitcher

extends Node

# high level interface to switch scenes
#
# is instanced by the Utils Autoload script with Utils.get_scene_switcher(path)
# takes an absolute NodePath and can manipulate scenes under it
# can add/remove/show scenes and keeps track of different states of scenes
# scenes can be: 
# ACTIVE active/free (deleted from memory) 
# HIDDEN visible/hidden (still in memory and running)
# STOPPED attached to/removed from the tree (still in memory but not running)
#
# Members:
# @count is a self incrementing counter for when adding scenes without providing a name string
# @path contains the path to the scene below which scenes will be manipulated
# @local_root is the dereferenced @path
# @_scenes dict with int or string as keys and Nodes as values. 
# Holds all scenes below @path regardless of state. 
# However a freed scene will be removed from scenes.
# @_active_scenes , @_hidden_scenes , @_stopped_scenes
# hold keys of _scenes kept track of respectively to state of scenes
# @flag_sync if true every tree addition will be reflected in the _scenes dictionary.
# This might be very slow when many nodes are added to anywhere in the tree externally.
# It connects to `tree_changed` signal of the whole scene tree.
# There is close to no performance penalty when adding via this class.
# @flag_no_duplicate_scenes if true, when syncing new added nodes below path, it
# will make sure the same instance of a node doesn't appear twice in _scenes.
# WARNING this scales really bad with the size of _scenes because it checks the
# whole dictionary for duplicates for every externally added node
# Also normally it shouldn't be necessary because why would you add the same 
# instance under the path twice
# @_adding_scene will be true if a scene is added by this class, so that if sync 
# is on, it wont be added twice
#
# Methods:
# @_init(path, synchronize, sync_no_duplicates) 
# for all of the following: 
# if deferred any tree_changes will be done with call_deferred() or queue_free()
# hide()/show() only works for CanvasItems, it will throw and error otherwise
# @add_scene(scene: PackedScene, key = count, method := ACTIVE, deferred := false)
# adds scene under path using method, with key as key in _scenes dictionary. 
# @show_scene(key = count, deferred := false):
# if key in _hidden_scenes, makes scene visible. if key in _stopped_scenes attaches scene.  if neither throw error.
# @remove_scene(key = count, method := ACTIVE, deferred := false)
# opposite to add_scene()
# @switch_scene( key_to, key_from = null, method_from := ACTIVE, deferred := false)
# uses show_scene(key_to) and remove_scene(key_from, method_from) key_from defaults to last added _active_scenes
# @switch_new_scene( scene_to: PackedScene, key_to = count, key_from = null, method_to := ACTIVE, method_from := ACTIVE, deferred := false)
# same as switch_scene, but uses add_scene(scene_to, key_to,...) instead of show_scene

enum { ACTIVE, HIDDEN, STOPPED }

var _active_scenes := [] setget _set_active_scenes, get_active_scenes
var _hidden_scenes := [] setget _set_hidden_scenes, get_hidden_scenes
var _stopped_scenes := [] setget _set_hidden_scenes, get_stopped_scenes
var _scenes := {} setget set_scenes, get_scenes

var count := 1
var path: NodePath
var local_root: Node
var flag_sync: bool
var flag_no_duplicate_scenes := false
var _adding_scene := false


func _init(p: NodePath, synchronize := false, sync_no_duplicates := false):
	path = p
	flag_sync = synchronize
	flag_no_duplicate_scenes = sync_no_duplicates


func _ready():
	assert(
		get_node(path).is_inside_tree(),
		"scene_switcher: failed to initilize, given path isnt in scenetree"
	)
	local_root = get_node(path)
	# for syncing nodes that are added by something other than this class
	if flag_sync:
		get_tree().connect("node_added", self, "_on_node_added")
		# this incorporates the existing child scenes of path into the tracked lists
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


func add_scene(
	scene: PackedScene, key = count, method := ACTIVE, deferred := false
):
	assert(key is int or key is String, "add_scene: key must be int or String")
	if key is int:
		assert(key == count, "add_scene: key must be string if it isn't count")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"add_scene: invalid method value"
	)

	var s = scene.instance()

	match method:
		ACTIVE:
			_active_scenes.push_back(key)
			_adding_scene = true
			if deferred:
				local_root.call_deferred("add_child", s)
			else:
				local_root.add_child(s)
			_adding_scene = false
		HIDDEN:
			assert(
				s is CanvasItem,
				"add_scene: scene must inherit from CanvasItem to be hidden"
			)
			_hidden_scenes.push_back(key)
			_adding_scene = true
			if deferred:
				local_root.call_deferred("add_child", s)
			else:
				local_root.add_child(s)
			_adding_scene = false
			s.hide()
		STOPPED:
			_stopped_scenes.push_back(key)

	_scenes[key] = s

	if key is int:
		count += 1


func show_scene(key = count, deferred := false):
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
			_adding_scene = true
			if deferred:
				local_root.call_deferred("add_child", _scenes[key])
			else:
				local_root.add_child(_scenes[key])
			_adding_scene = false
			_stopped_scenes.erase(key)
		_active_scenes.push_back(key)


func remove_scene(key = count, method := ACTIVE, deferred := false):
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
				if deferred:
					_scenes[key].queue_free()
				else:
					_scenes[key].free()
				_scenes.erase(key)
			HIDDEN:
				assert(
					_scenes[key] is CanvasItem,
					"remove_scene: scene must inherit from CanvasItem to be hidden"
				)
				_scenes[key].hide()
				_hidden_scenes.push_back(key)
			STOPPED:
				if deferred:
					local_root.call_deferred("remove_child", _scenes[key])
				else:
					local_root.remove_child(_scenes[key])
				_stopped_scenes.push_back(key)


func switch_scene(
	key_to, key_from = null, method_from := ACTIVE, deferred := false
):
	assert(
		! (key_to in _active_scenes), "switch_scene: scene_to already active"
	)
	assert(
		key_to in _hidden_scenes or key_to in _stopped_scenes,
		"switch_scene: scene2 is neither hidden nor stopped"
	)
	assert(
		ACTIVE <= method_from and method_from <= STOPPED,
		"switch_scene: invalid method value"
	)
	if key_from == null:
		assert(_active_scenes.size() > 0, "switch_scene: no active scene")
		key_from = _active_scenes[-1]
	else:
		assert(
			key_from in _active_scenes, "switch_scene: scene_from not active"
		)

	remove_scene(key_from, method_from, deferred)
	show_scene(key_to, deferred)


func switch_new_scene(
	scene_to: PackedScene,
	key_to = count,
	key_from = null,
	method_to := ACTIVE,
	method_from := ACTIVE,
	deferred := false
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
	if key_from == null:
		assert(_active_scenes.size() > 0, "switch_scene: no active scene")
		key_from = _active_scenes[-1]
	else:
		assert(
			key_from in _active_scenes, "switch_scene: scene_from not active"
		)

	add_scene(scene_to, method_to, key_to, deferred)
	remove_scene(key_from, method_from, deferred)


func _check_scenes():
	var dead_keys = []
	for k in _scenes:
		if not _check_scene(k, false):
			dead_keys.push_back(k)
	# this is necessary because dict.erase() doesn't work while iterating over dict
	for k in dead_keys:
		_scenes.erase(k)
		print_debug("_check_scenes: scenes ", dead_keys, " were already freed")


func _check_scene(key, single := true) -> bool:
	assert(key in _scenes, "_check_scene: key not in _scenes")

	if (
		is_instance_valid(_scenes[key])
		and not _scenes[key].is_queued_for_deletion()
	):
		if _scenes[key].is_inside_tree():
			if _scenes[key] is CanvasItem:
				if _scenes[key].visible and key in _hidden_scenes:
					_active_scenes.push_back(key)
					_hidden_scenes.erase(key)
				elif ! _scenes[key].visible and key in _active_scenes:
					_hidden_scenes.push_back(key)
					_active_scenes.erase(key)
		else:
			if key in _active_scenes:
				_stopped_scenes.push_back(key)
				_active_scenes.erase(key)
		return true
	else:
		if single:
			_scenes.erase(key)
			print_debug("_check_scene: scene ", key, " was already freed")
		if key in _active_scenes:
			_active_scenes.erase(key)
		elif key in _hidden_scenes:
			_hidden_scenes.erase(key)
		elif key in _stopped_scenes:
			_stopped_scenes.erase(key)
		return false


func _on_node_added(node: Node):
	if _adding_scene:
		return
	if node.get_parent() == local_root:
		if flag_no_duplicate_scenes:
			if node in _scenes.values():
				return
		_scenes[count] = node
		if node is CanvasItem:
			if node.visible:
				_active_scenes.push_back(count)
			else:
				_hidden_scenes.push_back(count)
		else:
			_active_scenes.push_back(count)
		count += 1


# func _on_node_removed(node: Node):
# 	# doesnt work correctly when node.free() is called because this function is 
# 	# called before it is freed so is_instance_valid(node) is true and its not 
# 	# is_queued_for_deletion() since thats only the case when node.queue_free() 
# 	# is called
# 	if _quitting:
# 		return
# 	if _removing_scene:
# 		return
# 	if node.get_parent() == local_root:
# 		if node in _scenes.values():
# 			var k = _scenes.keys()[_scenes.values().find(node)]
# 			if is_instance_valid(node) and not node.is_queued_for_deletion():
# 				if ! (k in _stopped_scenes):
# 					_stopped_scenes.push_back(k)
# 			else:
# 				_scenes.erase(k)
# 				if k in _hidden_scenes:
# 					_hidden_scenes.erase(k)
# 				elif k in _stopped_scenes:
# 					_stopped_scenes.erase(k)
# 			if k in _active_scenes:
# 				_active_scenes.erase(k)


func _to_string():
	var s = ""
	s += "active: " + _active_scenes as String + "\n"
	s += "hidden: " + _hidden_scenes as String + "\n"
	s += "stopped: " + _stopped_scenes as String + "\n"
	s += "_scenes: " + _scenes as String + "\n"
	s += "count: " + count as String + "\n"
	s += "path: " + path as String + "\n"
	s += local_root.get_children() as String + "\n"
	# get_node("/root").print_stray_nodes()
	# get_node("/root").print_tree_pretty()
	return s

#get_tree() tree_changed to sync
#node is_inside_tree()
#node has_node(Node)
#gdscript is_instance_valid(objectq)
#Node.owner =
