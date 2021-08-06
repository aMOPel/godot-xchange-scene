extends "res://addons/gut/test.gd"


class TestInit:
	extends "res://addons/gut/test.gd"
	var n: Node
	var c: Node
	var sw: Node

	func before_all():
		n = Node.new()
		c = Node.new()
		add_child(n)
		n.add_child(c)
		sw = SceneSwitcherManager.get_scene_switcher(n.get_path(), true, true)
		gut.p("ran run setup")

	func after_all():
		n.free()
		sw.free()
		gut.p("ran teardown")

	func test_init():
		assert_eq(sw.path, n.get_path())
		assert_true(sw.flag_sync)
		assert_true(sw.flag_no_duplicate_scenes)

	func test_ready():
		assert_eq(sw.local_root, n)
		assert_connected(get_tree(), sw, "node_added", "_on_node_added")
		assert_eq(sw._scenes[1].scene, c)


class TestAdd:
	extends "res://addons/gut/test.gd"
	var n: Node
	var sw: Node
	var s1 = load("res://example/scene1.tscn")

	func before_all():
		n = Node.new()
		add_child(n)
		gut.p("ran run setup")

	func after_all():
		n.free()
		gut.p("ran teardown")

	func before_each():
		sw = SceneSwitcherManager.get_scene_switcher(n.get_path())

	func after_each():
		for s in sw._scenes.values():
			s.scene.free()
		sw.free()

	func test_add_key():
		sw.add_scene(s1)
		assert_true(1 in sw._scenes)
		sw.add_scene(s1, sw.count)
		assert_true(2 in sw._scenes)
		sw.add_scene(s1, "hi")
		assert_true("hi" in sw._scenes)

	func test_add_active():
		sw.add_scene(s1)
		var s = sw._scenes[1]
		assert_true(is_instance_valid(s.scene))
		assert_true(s.scene.is_inside_tree())
		assert_true(s.scene.visible)
		assert_eq(s.status, sw.ACTIVE)
		assert_true(sw.local_root.is_a_parent_of(s.scene))

	func test_add_hidden():
		sw.add_scene(s1, sw.count, sw.HIDDEN)
		var s = sw._scenes[1]
		assert_true(is_instance_valid(s.scene))
		assert_true(s.scene.is_inside_tree())
		assert_false(s.scene.visible)
		assert_eq(s.status, sw.HIDDEN)
		assert_true(sw.local_root.is_a_parent_of(s.scene))

	func test_add_stopped():
		sw.add_scene(s1, sw.count, sw.STOPPED)
		var s = sw._scenes[1]
		assert_true(is_instance_valid(s.scene))
		assert_false(s.scene.is_inside_tree())
		assert_eq(s.status, sw.STOPPED)

	func test_add_deferred():
		sw.add_scene(s1, sw.count, 0, true)
		var s = sw._scenes[1]
		assert_true(is_instance_valid(s.scene))
		assert_false(s.scene.is_inside_tree())
		assert_false(sw.local_root.is_a_parent_of(s.scene))
		yield(get_tree(), "idle_frame")
		assert_true(s.scene.is_inside_tree())
		assert_true(sw.local_root.is_a_parent_of(s.scene))


class TestShow:
	extends "res://addons/gut/test.gd"
	var n: Node
	var sw: Node
	var s1 = load("res://example/scene1.tscn")

	func before_all():
		n = Node.new()
		add_child(n)
		gut.p("ran run setup")

	func after_all():
		n.free()
		gut.p("ran teardown")

	func before_each():
		sw = SceneSwitcherManager.get_scene_switcher(n.get_path())
		sw.add_scene(s1, sw.count, sw.HIDDEN)
		sw.add_scene(s1, sw.count, sw.STOPPED)

	func after_each():
		for s in sw._scenes.values():
			s.scene.free()
		sw.free()

	func test_show_key():
		var s = sw._scenes
		assert_false(s[1].scene.visible)
		sw.show_scene(1)
		assert_true(s[1].scene.visible)
		assert_false(s[2].scene.is_inside_tree())
		sw.show_scene(2)
		assert_true(s[2].scene.is_inside_tree())
		assert_true(sw.local_root.is_a_parent_of(s[2].scene))

	func test_show_deferred():
		var s = sw._scenes
		assert_false(s[2].scene.is_inside_tree())
		sw.show_scene(2, true)
		assert_false(s[2].scene.is_inside_tree())
		yield(get_tree(), "idle_frame")
		assert_true(s[2].scene.is_inside_tree())
		assert_true(sw.local_root.is_a_parent_of(s[2].scene))


class TestRemove:
	extends "res://addons/gut/test.gd"
	var n: Node
	var sw: Node
	var s1 = load("res://example/scene1.tscn")

	func before_all():
		n = Node.new()
		add_child(n)
		gut.p("ran run setup")

	func after_all():
		n.free()
		gut.p("ran teardown")

	func before_each():
		sw = SceneSwitcherManager.get_scene_switcher(n.get_path())
		sw.add_scene(s1, sw.count, sw.ACTIVE)
		sw.add_scene(s1, sw.count, sw.HIDDEN)
		sw.add_scene(s1, sw.count, sw.STOPPED)

	func after_each():
		for s in sw._scenes.values():
			s.scene.free()
		sw.free()

	func test_remove_active():
		assert_false(sw._scenes.empty())

		var s = sw._scenes[1]
		assert_true(is_instance_valid(s.scene))
		sw.remove_scene(1)
		assert_false(is_instance_valid(s.scene))

		s = sw._scenes[2]
		assert_true(is_instance_valid(s.scene))
		sw.remove_scene(1)
		assert_false(is_instance_valid(s.scene))

		s = sw._scenes[3]
		assert_true(is_instance_valid(s.scene))
		sw.remove_scene(1)
		assert_false(is_instance_valid(s.scene))

		assert_true(sw._scenes.empty())

	func test_remove_hidden():
		var s = sw._scenes[1]
		assert_true(is_instance_valid(s.scene))
		sw.remove_scene(1)
		assert_true(is_instance_valid(s.scene))
		assert_true(s.scene.is_inside_tree())
		assert_false(s.scene.visible)
		assert_eq(s.status, sw.HIDDEN)
		assert_true(sw.local_root.is_a_parent_of(s.scene))
