class_name XScene

extends Node

# high level interface to exchange scenes
#
# is instanced by the XSceneManager Autoload script with XSceneManager.get_x_scene(path)
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
# @root is the dereferenced @path
# @scenes dict with int or string as keys and dicts as values
# eg {"scene1": {scene: Noderef, status: ACTIVE}, ..}
# Holds all scenes below @path regardless of state, which were added by this class.
# However a freed scene will be removed from scenes.
# validity check for scenes is done only when accessed (lazily)
# @active , @hidden , @stopped
# hold keys of scenes kept track of respectively to state of scenes, they are updated only when accessed (lazily)
# @flag_sync if true every tree addition will be reflected in the scenes dictionary.
# This might be very slow when many nodes are added below @root externally.
# It connects to `tree_changed` signal of the whole scene tree.
# There is close to no performance penalty when adding scenes via this class.
# WARNING Duplicates can eg appear when you add, remove(STOPPED), and add again externally.
# The remove wont erase the node from scenes, but the second add will trigger the
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
# adds scene under path using method, with key as key in scenes dictionary.
# @show_scene(key = count, deferred := false):
# if key is HIDDEN, makes scene visible. If key is STOPPED attaches scene. If neither throw error.
# @remove_scene(key = count, method := ACTIVE, deferred := false)
# opposite to add_scene()
# @x_scene( key_to, key_from = null, method_from := ACTIVE, deferred := false)
# uses show_scene(key_to) and remove_scene(key_from, method_from) key_from defaults to last added _activescenes
# @x_new_scene( scene_to: PackedScene, key_to = count, key_from = null, method_to := ACTIVE, method_from := ACTIVE, deferred := false)
# same as x_scene, but uses add_scene(scene_to, key_to,...) instead of show_scene

# warnings-disable

enum { ACTIVE, HIDDEN, STOPPED, FREE }

var scenes := {} setget _dont_set, get_scenes
var active := [] setget _dont_set, get_active
var hidden := [] setget _dont_set, get_hidden
var stopped := [] setget _dont_set, get_stopped

var root: Node setget _dont_set, get_root
var path: NodePath setget _dont_set
var flag_sync: bool setget _dont_set

var _adding_scene := false setget _dont_set
var _removing_scene := false setget _dont_set

var defaults := {
	deferred = false,
	recursive_owner = false,
	method_add = ACTIVE,
	method_remove = FREE,
	count_start = 1
}

var count: int = defaults.count_start setget _dont_set


func _init(p, synchronize := false):
	if p is NodePath:
		path = p
	elif p is Node:
		root = p
	else:
		assert(false, "x_scene _init: input p must be NodePath or Node")
	flag_sync = synchronize


func _ready():
	if path:
		root = get_node(path)
	elif root:
		path = root.get_path()
	assert(
		root.is_inside_tree(),
		"x_scene_ready: failed to initilize, given path isnt in scenetree"
	)
	# for syncing nodes that are added by something other than this class
	if flag_sync:
		get_tree().connect("node_added", self, "_on_node_added")
		# this incorporates the existing child scenes of path into the tracked lists
		var children = root.get_children()
		if children:
			for s in children:
				_on_node_added(s)


func _dont_set(a):
	assert(false, "do not set anything in XScene manually")


func get_active() -> Array:
	_check_scenes(ACTIVE)
	return active


func get_hidden() -> Array:
	_check_scenes(HIDDEN)
	return hidden


func get_stopped() -> Array:
	_check_scenes(STOPPED)
	return stopped


func get_scenes() -> Dictionary:
	_check_scenes()
	return scenes


func get_root() -> Node:
	if not is_instance_valid(root):
		root = null
		print_debug("root was freed, x_scene instance dead")
		self.queue_free()
	return root


func x(key):
	if _check_scene(key):
		return scenes[key].scene
	else:
		print_debug("XScene x: key invalid")


func add_scene(
	scene,
	key = count,
	method := defaults.method_add,
	deferred := defaults.deferred,
	recursive_owner := defaults.recursive_owner
):
	if self.root == null:
		return
	assert(key is int or key is String, "add_scene: key must be int or String")
	if key is int:
		assert(key == count, "add_scene: key must be string if it isn't count")
	assert(! (key in scenes), "add_scene: key already exists")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"add_scene: invalid method value"
	)
	var s: Node
	if scene is PackedScene:
		s = scene.instance()
	elif scene is Node:
		s = scene
	else:
		assert(false, "add_scene: input scene must be PackedScene or Node")

	if method != STOPPED:
		_adding_scene = true
		if deferred:
			root.call_deferred("add_child", s)
			# TODO check if this is necessary
			yield(s, "tree_entered")
		else:
			root.add_child(s)
		_adding_scene = false

		if recursive_owner:
			s.propagate_call("set_owner", [root])
		else:
			s.owner = root

		if method == HIDDEN:
			assert(
				s is CanvasItem,
				"add_scene: scene must inherit from CanvasItem to be hidden"
			)
			s.hide()

	scenes[key] = {scene = s, status = method}

	if key is int:
		count += 1


func show_scene(key = count, deferred := defaults.deferred):
	if self.root == null:
		return
	if _check_scene(key):
		var s = scenes[key]
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
					root.call_deferred("add_child", s.scene)
					yield(s.scene, "tree_entered")
				else:
					root.add_child(s.scene)
				if s.scene is CanvasItem and not s.scene.visible:
					s.scene.show()
				_adding_scene = false
		s.status = ACTIVE
	else:
		assert(false, "show_scene: key invalid")


func remove_scene(
	key = count, method := defaults.method_remove, deferred := defaults.deferred
):
	if self.root == null:
		return
	assert(
		HIDDEN <= method and method <= FREE,
		"remove_scene: invalid method value"
	)

	if _check_scene(key):
		var s = scenes[key]

		match method:
			HIDDEN:
				assert(
					s.scene is CanvasItem,
					"remove_scene: scene must inherit from CanvasItem to be hidden"
				)
				if s.status == ACTIVE:
					s.scene.hide()
					s.status = HIDDEN
			STOPPED:
				if s.status != STOPPED:
					_removing_scene = true
					if deferred:
						root.call_deferred("remove_child", s.scene)
						s.status = STOPPED
						yield(s.scene, "tree_exited")
					else:
						root.remove_child(s.scene)
						s.status = STOPPED
					if s.scene is CanvasItem and s.status == HIDDEN:
						s.scene.show()
					_removing_scene = false
			FREE:
				_removing_scene = true
				if deferred:
					s.scene.queue_free()
				else:
					s.scene.free()
				_removing_scene = false
				scenes.erase(key)
	else:
		assert(false, "remove_scene: key invalid")


func x_scene(
	key_to,
	key_from = null,
	method_from := defaults.method_remove,
	deferred := defaults.deferred
):
	if key_from == null:
		key_from = self.active[-1]
		assert(key_from != null, "x_scene: no active scene")
	else:
		assert(
			scenes[key_from].status == ACTIVE, "x_scene: scene_from not active"
		)
	assert(
		! (scenes[key_to].status == ACTIVE), "x_scene: scene_to already active"
	)

	remove_scene(key_from, method_from, deferred)
	show_scene(key_to, deferred)


func x_add_scene(
	scene_to,
	key_to = count,
	key_from = null,
	method_to := defaults.method_add,
	method_from := defaults.method_remove,
	deferred := defaults.deferred,
	recursive_owner := defaults.recursive_owner
):
	if key_from == null:
		key_from = self.active[-1]
		assert(key_from != null, "x_add_scene: no active scene")
	else:
		assert(
			scenes[key_from].status == ACTIVE,
			"x_add_scene: scene_from not active"
		)

	add_scene(scene_to, key_to, method_to, deferred, recursive_owner)
	remove_scene(key_from, method_from, deferred)


func pack(path):
	if self.root == null:
		return
	var scene = PackedScene.new()
	if scene.pack(root) == OK:
		if ResourceSaver.save(path, scene) != OK:
			push_error(
				"x_scene pack: An error occurred while saving the scene to disk."
			)


func _check_scenes(method = null):
	var dead_keys = []
	if method == null:
		for k in scenes:
			if not _check_scene(k, false):
				dead_keys.push_back(k)
	else:
		assert(
			ACTIVE <= method and method <= STOPPED,
			"remove_scene: invalid method value"
		)
		match method:
			ACTIVE:
				active = []
			HIDDEN:
				hidden = []
			STOPPED:
				stopped = []
		for k in scenes:
			if not _check_scene(k, false):
				dead_keys.push_back(k)
			else:
				if scenes[k].status == method:
					match method:
						ACTIVE:
							active.push_back(k)
						HIDDEN:
							hidden.push_back(k)
						STOPPED:
							stopped.push_back(k)
	# this is necessary because dict.erase() doesn't work while iterating over dict
	if not dead_keys.empty():
		for k in dead_keys:
			scenes.erase(k)
		print_debug(
			"_check_scenes: these scenes were already freed: \n", dead_keys
		)


func _check_scene(key, single := true) -> bool:
	if key == null:
		return false
	if single:
		if ! (key in scenes):
			return false
	if _removing_scene:
		yield(get_tree(), "idle_frame")

	var s = scenes[key]

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
			scenes.erase(key)
			print_debug("_check_scene: scene ", key, " was already freed")
		return false


func _on_node_added(node: Node):
	if _adding_scene:
		return
	if self.root == null:
		return
	if node.get_parent() == root:
		var d := {}
		d.scene = node
		if node is CanvasItem and not node.visible:
			d.status = HIDDEN
		else:
			d.status = ACTIVE
		scenes[count] = d

		count += 1


func _to_string():
	var s = "[["
	s += self.get_class() + ":"
	s += self.get_instance_id() as String + "]]"
	return s


func debug():
	var s = ""
	s += "active: " + active as String + "\n"
	s += "hidden: " + hidden as String + "\n"
	s += "stopped: " + stopped as String + "\n"
	s += "scenes: " + scenes as String + "\n"
	s += "count: " + count as String + "\n"
	s += "path: " + path as String + "\n"
	s += root.get_children() as String + "\n"
	# get_node("/root").print_stray_nodes()
	get_node("/root").print_tree_pretty()
	print(s)

# TODO add batch adding/removing
