# __robust, high level interface__ for manipulating and indexing scenes below a given `Node`.
class_name XScene

extends Node

# warnings-disable

# enum with the scene states
# `ACTIVE` = 0 uses `add_child()`
# `HIDDEN` = 1 uses `.hide()`
# `STOPPED` = 2 uses `remove_child()`
# `FREE` = 3 uses `.free()`
enum { ACTIVE, HIDDEN, STOPPED, FREE }

# Dictionary that holds all indexed scenes and their state
# has either `count` or String as keys
# Eg. {1:{scene:[Node2D:1235], state:0}, abra:{scene:[Node2D:1239], state:1}}
var scenes := {} setget _dont_set, get_scenes
# Array of keys of active scenes
var active := [] setget _dont_set, get_active
# Array of keys of hidden scenes
var hidden := [] setget _dont_set, get_hidden
# Array of keys of stopped scenes
var stopped := [] setget _dont_set, get_stopped

# the Node below which this class will manipulate scenes
var root: Node setget _dont_set
# wether to synchronize `scenes` with external additions to the tree
# __WARNING__ this can be slow, read the __Caveats__ Section in the README.md
var flag_sync: bool setget _dont_set

# true if currently adding a scene
# this is interesting for the sync feature and deferred adding
var _adding_scene := false setget _dont_set
# true if currently removing a scene
# this is interesting for `_check_scene()` and deferred removing
var _removing_scene := false setget _dont_set

# Dictionary that hold the default values for parameters used in add/show/remove
# __WARNING__ if you change the values to something not of its original type, things will break
# `deferred` = false,
# `recursive_owner` = false,
# `method_add` = ACTIVE,
# `method_remove` = FREE,
# `count_start` = 1
var defaults := {
	deferred = false,
	recursive_owner = false,
	method_add = ACTIVE,
	method_remove = FREE,
	count_start = 1
}

# automatically incrementing counter used as key when none is provided
# starting value can be set in `defaults` and defaults to 1
var count: int = defaults.count_start setget _dont_set


# init for XScene
# `p` Node ; determines `root`
# `synchronize` bool ; default: false ; wether to synchronize `scenes` with external additions to the tree
# `parameter_defaults` Dictionary ; default: `defaults` 
func _init(p: Node, synchronize := false, parameter_defaults := defaults) -> void:
	assert(
		p.is_inside_tree(),
		"XScene._init: failed to initilize, given node isnt in scenetree"
	)
	flag_sync = synchronize
	defaults = parameter_defaults

	root = p
	p.add_child(self)


func _ready() -> void:
	# for syncing nodes that are added by something other than this class
	if flag_sync:
		get_tree().connect("node_added", self, "_on_node_added")
		# this incorporates the existing child scenes of root into the tracked lists
		var children = root.get_children()
		if children:
			for s in children:
				if s != self:
					_on_node_added(s)


func _dont_set(a) -> void:
	assert(false, "XScene: do not set anything in XScene manually")


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


# "x"ess the scene of `key`
# returns null if the scene of `key` was already freed
func x(key) -> Node:
	if _check_scene(key):
		return scenes[key].scene
	else:
		print_debug("XScene.x: key invalid")
		return null


# do multiple "x"ess"s", get Array of Nodes based on `method`
# if null return all scenes from `scenes`
# if method specified return only the scenes in the respective state
# `method` null / `ACTIVE` / `HIDDEN` / `STOPPED` ; default: null ; 
func xs(method = null) -> Array:
	_check_scenes(method)
	var a := []
	if method == null:
		for k in scenes.keys():
			a.push_back(scenes[k].scene)
	else:
		for k in scenes.keys():
			if scenes[k].state == method:
				a.push_back(scenes[k].scene)
	return a


# add a scene to the tree below `root` and to `scenes`
# `ACTIVE` uses add_child()
# `HIDDEN` uses add_child() and .hide()
# `STOPPED` only adds to `scenes` not to the tree
# `scene` Node / PackagedScene ;
# `key` XScene.count / String ; default: `count` ; the key in the Dictionary `scenes`
# `method` `ACTIVE` / `HIDDEN` / `STOPPED` ; default: `ACTIVE` 
# `deferred` bool ; default: false ; whether to use call_deferred() for tree changes
# `recursive_owner` bool ; default: false ; wether to recursively for all children of `scene` set the owner to `root`, this is useful for `pack_root()`
func add_scene(
	scene,
	key = count,
	method := defaults.method_add,
	deferred := defaults.deferred,
	recursive_owner := defaults.recursive_owner
) -> void:
	assert(
		key is int or key is String,
		"XScene.add_scene: key must be int or String"
	)
	if key is int:
		assert(
			key == count,
			"XScene.add_scene: key must be string if it isn't count"
		)
	assert(! (key in scenes), "XScene.add_scene: key already exists")
	assert(
		ACTIVE <= method and method <= STOPPED,
		"XScene.add_scene: invalid method value"
	)
	var s: Node
	if scene is PackedScene:
		s = scene.instance()
	elif scene is Node:
		s = scene
	else:
		assert(false, "XScene.add_scene: input scene must be PackedScene or Node")

	if method != STOPPED:
		_adding_scene = true
		if deferred:
			root.call_deferred("add_child", s)
			# count must be incremented before yield
			if key is int:
				count += 1
			yield(s, "tree_entered")
		else:
			root.add_child(s)
			if key is int:
				count += 1
		_adding_scene = false

		if recursive_owner:
			s.propagate_call("set_owner", [root])
		else:
			s.owner = root

		if method == HIDDEN:
			assert(
				s is CanvasItem,
				"XScene.add_scene: scene must inherit from CanvasItem to be hidden"
			)
			s.hide()

	scenes[key] = {scene = s, state = method}



# make `key` visible, and update `scenes`
# it uses `_check_scene` to verify that the Node is still valid
# if `HIDDEN` it uses .show()
# if `STOPPED` it uses `add_child()` and `.show()`
# `key` : int / String | default: `count` | the key in the Dictionary `scenes`
# `deferred` : bool | default: false | whether to use call_deferred() for tree changes
func show_scene(key = count, deferred := defaults.deferred) -> void:
	if _check_scene(key):
		var s = scenes[key]
		assert(! (s.state == ACTIVE), "XScene.show_scene: scene already active")

		match s.state:
			HIDDEN:
				assert(
					s.scene is CanvasItem,
					"XScene.show_scene: BUG scene must inherit from CanvasItem to be shown"
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
		s.state = ACTIVE
	else:
		assert(false, "XScene.show_scene: key invalid")


# remove `key` from `root` (or hide it) and update `scenes`
# it uses `_check_scene` to verify that the Node is still valid
# `HIDDEN` uses .hide()
# `STOPPED` uses remove_child()
# `FREE` uses .free()
# `key` int / String ; default: `count` ; the key in the Dictionary `scenes`
# `method` `HIDDEN` / `STOPPED` / `FREE` ; default: `FREE`
# `deferred` bool ; default: false ; whether to use call_deferred() or queue_free() for tree changes
func remove_scene(
	key = count, method := defaults.method_remove, deferred := defaults.deferred
) -> void:
	assert(
		HIDDEN <= method and method <= FREE,
		"XScene.remove_scene: invalid method value"
	)

	if _check_scene(key):
		var s = scenes[key]

		match method:
			HIDDEN:
				assert(
					s.scene is CanvasItem,
					"XScene.remove_scene: scene must inherit from CanvasItem to be hidden"
				)
				if s.state == ACTIVE:
					s.scene.hide()
					s.state = HIDDEN
			STOPPED:
				if s.state != STOPPED:
					if s.scene is CanvasItem and s.state == HIDDEN:
						s.scene.show()
					_removing_scene = true
					if deferred:
						root.call_deferred("remove_child", s.scene)
						s.state = STOPPED
						yield(s.scene, "tree_exited")
					else:
						root.remove_child(s.scene)
						s.state = STOPPED
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
		assert(false, "XScene.remove_scene: key invalid")


# make `scenes`[key_to] visible and remove `scenes`[key_from] from `root` and update `scenes`
# it uses `show_scene()` and `remove_scene()`
# `key_to` int / String ; use `show_scene()` with this key
# `key_from` int / String ; default: null ; use `remove_scene()` with this key, if null then the last active scene will be used
# `method_from` `HIDDEN` / `STOPPED` / `FREE` ; default: `FREE`
# `deferred` bool ; default: false ; whether to use call_deferred() or queue_free() for tree changes
func x_scene(
	key_to,
	key_from = null,
	method_from := defaults.method_remove,
	deferred := defaults.deferred
) -> void:
	if key_from == null:
		key_from = self.active[-1]
		assert(key_from != null, "XScene.x_scene: no active scene")
	else:
		assert(
			scenes[key_from].state == ACTIVE, "XScene.x_scene: scene_from not active"
		)
	assert(
		! (scenes[key_to].state == ACTIVE), "XScene.x_scene: scene_to already active"
	)

	remove_scene(key_from, method_from, deferred)
	show_scene(key_to, deferred)


# add `scenes`[key_to] and remove `scenes`[key_from] from `root` and update `scenes`
# it uses `add_scene()` and `remove_scene()`
# `scene_to` Node / PackagedScene ;
# `key_to` XScene.count / String ; default: `count` ; use `add_scene()` with this key
# `key_from` int / String ; default: null ; use `remove_scene()` with this key, if null then the last active scene will be used
# `method_to` `ACTIVE` / `HIDDEN` / `STOPPED` ; default: `ACTIVE` 
# `method_from` `HIDDEN` / `STOPPED` / `FREE` ; default: `FREE`
# `deferred` bool ; default: false ; whether to use call_deferred() or queue_free() for tree changes
# `recursive_owner` bool ; default: false ; wether to recursively for all children of `scene` set the owner to `root`
func x_add_scene(
	scene_to,
	key_to = count,
	key_from = null,
	method_to := defaults.method_add,
	method_from := defaults.method_remove,
	deferred := defaults.deferred,
	recursive_owner := defaults.recursive_owner
) -> void:
	if key_from == null:
		key_from = self.active[-1]
		assert(key_from != null, "XScene.x_add_scene: no active scenes")
	else:
		assert(
			scenes[key_from].state == ACTIVE,
			"XScene.x_add_scene: scene_from not active"
		)

	add_scene(scene_to, key_to, method_to, deferred, recursive_owner)
	remove_scene(key_from, method_from, deferred)


 
# TODO write docs here and check the other ones
func add_scenes(
	scenes: Array,
	keys = count,
	method := defaults.method_add,
	deferred := defaults.deferred,
	recursive_owner := defaults.recursive_owner
) -> void:
	if keys is int:
		assert(keys == count, "XScene.add_scenes: key must be array if it isn't count")
		for s in scenes:
			add_scene(s, count, method, deferred, recursive_owner)
	elif keys is Array:
		assert(
			scenes.size() == keys.size(),
			"XScene.add_scenes: scenes and keys must be same size"
		)
		for i in range(scenes.size()):
			add_scene(scenes[i], keys[i], method, deferred, recursive_owner)


func remove_scenes(
	keys: Array, method := defaults.method_remove, deferred := defaults.deferred
) -> void:
	for k in keys:
		remove_scene(k, method, deferred)


func show_scenes(keys: Array, deferred := defaults.deferred) -> void:
	for k in keys:
		show_scene(k, deferred)


# pack `root` into `filepath` using `PackedScene.pack()`
# this works together with the `recursive_owner` parameter of `add_scene()`
func pack_root(filepath) -> void:
	var scene = PackedScene.new()
	if scene.pack(root) == OK:
		if ResourceSaver.save(filepath, scene) != OK:
			push_error(
				"XScene.pack_root: An error occurred while saving the scene to disk, using ResourceSaver.save()"
			)


# check multiple scenes with `_check_scene()`
# this gets called by the getters for `scenes`, `active`, `hidden`, `stopped` and `xs()`
# if null updates `scenes`, else update only the respective array
# `method` null / `ACTIVE` / `HIDDEN` / `STOPPED` ; default: null ;
func _check_scenes(method = null) -> void:
	var dead_keys = []
	if method == null:
		for k in scenes:
			if not _check_scene(k, false):
				dead_keys.push_back(k)
	else:
		assert(
			ACTIVE <= method and method <= STOPPED,
			"XScene._check_scenes: invalid method value"
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
				if scenes[k].state == method:
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
			"XScene._check_scenes: these scenes were already freed: \n", dead_keys
		)


# check if `key` scene is still valid and update its state in `scenes`
# if the scene is no longer valid it erases the key from `scenes`
# it waits until after `remove_scene()` is done
# `single` bool ; default: true ; has to be false when iterating over `scenes`, because you can't erase a key then
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
					s.state = ACTIVE
				else:
					s.state = HIDDEN
		else:
			if s.state != STOPPED:
				s.state = STOPPED
		return true
	else:
		if single:
			scenes.erase(key)
			print_debug("XScene._check_scene: scene ", key, " was already freed")
		return false


# add `node` to `scenes` with key = `count` if `node` is child of `root`
# if `flag_sync` is true it is connected to the `get_tree()` `node_added` signal
# also it gets called in `_ready()` to add preexisting nodes
# it is skipped when adding nodes with `add_scene()` or `show_scene()`
func _on_node_added(node: Node) -> void:
	if _adding_scene:
		return
	if node.get_parent() == root:
		scenes[count] = {
			scene = node,
			state = (
				HIDDEN
				if (node is CanvasItem and not node.visible)
				else ACTIVE
			)
		}

		count += 1


# print debug information
func debug() -> void:
	var s = ""
	s += "active: " + active as String + "\n"
	s += "hidden: " + hidden as String + "\n"
	s += "stopped: " + stopped as String + "\n"
	s += "scenes: " + scenes as String + "\n"
	s += "count: " + count as String + "\n"
	s += root.get_children() as String + "\n"
	# get_node("/root").print_stray_nodes()
	get_node("/root").print_tree_pretty()
	print(s)

# TODO self managing attached below x.root
# write tests
# write documentation
