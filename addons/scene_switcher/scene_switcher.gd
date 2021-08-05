class_name SceneSwitcher

extends Node

# high level interface to switch scenes
#
# is instanced by the SceneSwitcherManager Autoload script with SceneSwitcherManager.get_scene_switcher(path)
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
# @_scenes dict with int or string as keys and dicts as values
# eg {"scene1": {scene: Noderef, status: ACTIVE}, ..}
# Holds all scenes below @path regardless of state, which were added by this class.
# However a freed scene will be removed from scenes.
# validity check for scenes is done only when accessed (lazily)
# @_active_scenes , @_hidden_scenes , @_stopped_scenes
# hold keys of _scenes kept track of respectively to state of scenes, they are updated only when accessed (lazily)
# @flag_sync if true every tree addition will be reflected in the _scenes dictionary.
# This might be very slow when many nodes are added below @local_root externally.
# It connects to `tree_changed` signal of the whole scene tree.
# There is close to no performance penalty when adding scenes via this class.
# @flag_no_duplicate_scenes if true, when syncing new added nodes below path, it
# will make sure the same instance of a node doesn't appear twice in _scenes.
# WARNING this scales really bad with the size of _scenes because it checks the
# whole _scenes dictionary for duplicates for every externally added node
# Duplicates can eg appear when you add, remove(STOPPED), and add again externally.
# The remove wont erase the node from _scenes, but the second add will trigger the
# sync and add the node again
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
# if key is HIDDEN, makes scene visible. If key is STOPPED attaches scene. If neither throw error.
# @remove_scene(key = count, method := ACTIVE, deferred := false)
# opposite to add_scene()
# @switch_scene( key_to, key_from = null, method_from := ACTIVE, deferred := false)
# uses show_scene(key_to) and remove_scene(key_from, method_from) key_from defaults to last added _active_scenes
# @switch_new_scene( scene_to: PackedScene, key_to = count, key_from = null, method_to := ACTIVE, method_from := ACTIVE, deferred := false)
# same as switch_scene, but uses add_scene(scene_to, key_to,...) instead of show_scene

# warnings-disable

enum { ACTIVE, HIDDEN, STOPPED }

var _scenes := {} setget set_scenes, get_scenes
var _active_scenes := [] setget _set_active_scenes, get_active_scenes
var _hidden_scenes := [] setget _set_hidden_scenes, get_hidden_scenes
var _stopped_scenes := [] setget _set_hidden_scenes, get_stopped_scenes

var count := 1
var path: NodePath
var local_root: Node
var flag_sync: bool
var flag_no_duplicate_scenes: bool
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
	_check_scenes(ACTIVE)
	return _active_scenes


func _set_hidden_scenes(array: Array):
	assert(false, "do not set _hidden_scenes manually")


func get_hidden_scenes() -> Array:
	_check_scenes(HIDDEN)
	return _hidden_scenes


func _set_stopped_scenes(array: Array):
	assert(false, "do not set _stopped_scenes manually")


func get_stopped_scenes() -> Array:
	_check_scenes(STOPPED)
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
	assert(! (key in _scenes), "add_scene: key already exists")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"add_scene: invalid method value"
	)

	var s = scene.instance()
	var d = {}

	match method:
		ACTIVE:
			d.status = ACTIVE
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
			d.status = HIDDEN
			_adding_scene = true
			if deferred:
				local_root.call_deferred("add_child", s)
			else:
				local_root.add_child(s)
			_adding_scene = false
			s.hide()
		STOPPED:
			d.status = STOPPED

	d.scene = s
	_scenes[key] = d

	if key is int:
		count += 1


func show_scene(key = count, deferred := false):

	if _check_scene(key):
		var s = _scenes[key]
		assert(! (s.status == ACTIVE), "show_scene: scene already active")

		match s.status:
			HIDDEN:
				assert(
					s.scene is CanvasItem,
					"show_scene: BUG scene must inherit from CanvasItem to be shown"
				)
				s.scene.show()
			STOPPED:
				_adding_scene = true
				if deferred:
					local_root.call_deferred("add_child", s.scene)
				else:
					local_root.add_child(s.scene)
				_adding_scene = false
		s.status = ACTIVE


func remove_scene(key = count, method := ACTIVE, deferred := false):
	assert(
		ACTIVE <= method and method <= STOPPED,
		"remove_scene: invalid method value"
	)

	if _check_scene(key):
		var s = _scenes[key]

		match method:
			ACTIVE:
				if deferred:
					s.scene.queue_free()
				else:
					s.scene.free()
				_scenes.erase(key)
			HIDDEN:
				assert(
					s.scene is CanvasItem,
					"remove_scene: scene must inherit from CanvasItem to be hidden"
				)
				s.scene.hide()
				s.status = HIDDEN
			STOPPED:
				if deferred:
					local_root.call_deferred("remove_child", s.scene)
				else:
					local_root.remove_child(s.scene)
				s.status = STOPPED


func switch_scene(
	key_to, key_from = null, method_from := ACTIVE, deferred := false
):
	if key_from == null:
		key_from = _get_last_active()
		assert(key_from != null, "switch_scene: no active scene")
	else:
		assert(
			_scenes[key_from].status == ACTIVE,
			"switch_scene: scene_from not active"
		)
	assert(
		! (_scenes[key_to].status == ACTIVE),
		"switch_scene: scene_to already active"
	)

	remove_scene(key_from, method_from, deferred)
	show_scene(key_to, deferred)


func switch_add_scene(
	scene_to: PackedScene,
	key_to = count,
	key_from = null,
	method_to := ACTIVE,
	method_from := ACTIVE,
	deferred := false
):
	if key_from == null:
		key_from = _get_last_active()
		assert(key_from != null, "switch_add_scene: no active scene")
	else:
		assert(
			_scenes[key_from].status == ACTIVE,
			"switch_add_scene: scene_from not active"
		)

	add_scene(scene_to, key_to, method_to, deferred)
	remove_scene(key_from, method_from, deferred)


func _get_last_active():
	get_active_scenes()
	# unclear if order of adding of scenes is preserved in array
	return _active_scenes[-1]


func _check_scenes(method = null):
	var dead_keys = []
	if method == null:
		for k in _scenes:
			if not _check_scene(k, false):
				dead_keys.push_back(k)
	else:
		assert(
			ACTIVE <= method and method <= STOPPED,
			"remove_scene: invalid method value"
		)
		match method:
			ACTIVE:
				_active_scenes = []
			HIDDEN:
				_hidden_scenes = []
			STOPPED:
				_stopped_scenes = []
		for k in _scenes:
			if not _check_scene(k, false):
				dead_keys.push_back(k)
			else:
				if _scenes[k].status == method:
					match method:
						ACTIVE:
							_active_scenes.push_back(k)
						HIDDEN:
							_hidden_scenes.push_back(k)
						STOPPED:
							_stopped_scenes.push_back(k)
	# this is necessary because dict.erase() doesn't work while iterating over dict
	if not dead_keys.empty():
		for k in dead_keys:
			_scenes.erase(k)
		print_debug(
			"_check_scenes: these scenes were already freed: \n", dead_keys
		)


func _check_scene(key, single := true) -> bool:
	if key == null:
		return false
	if single:
		if ! (key in _scenes):
			return false

	var s = _scenes[key]

	if is_instance_valid(s.scene) and not s.scene.is_queued_for_deletion():
		if s.scene.is_inside_tree():
			if s.scene is CanvasItem:
				if s.scene.visible:
					s.status = ACTIVE
				else:
					s.status = HIDDEN
		else:
			if s.status != STOPPED:
				s.status = STOPPED
		return true
	else:
		if single:
			_scenes.erase(key)
			print_debug("_check_scene: scene ", key, " was already freed")
		return false


func _on_node_added(node: Node):
	if _adding_scene:
		return
	if node.get_parent() == local_root:
		if flag_no_duplicate_scenes:
			for s in  _scenes.values():
				if node == s.scene:
					return
		var d = {}
		d.scene = node
		if node is CanvasItem and not node.visible:
			d.status = HIDDEN
		else:
			d.status = ACTIVE
		_scenes[count] = d

		count += 1


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

# TODO Node.owner = recursive
# TODO add batch adding/removing
