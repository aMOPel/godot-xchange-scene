extends "res://addons/gut/test.gd"


class TestInit:
	extends "res://addons/gut/test.gd"
	var n: Node
	var a: Node
	var b: Node
	var c: Node
	var x: Node
	var d: Dictionary

	func before_each():
		n = Node.new()
		add_child(n)

	func after_each():
		if n:
			n.free()

	func test_init():
		x = XScene.new(n)
		assert_eq(x.root, n)
		assert_false(x.flag_sync)
		assert_true(n.is_a_parent_of(x))
		assert_true(x.scenes.empty())
		d = {
			deferred = false,
			recursive_owner = false,
			method_add = XScene.ACTIVE,
			method_remove = XScene.FREE,
			count_start = 1
		}
		assert_eq(x.defaults.hash(), d.hash())
		x.free()

		d = {
			deferred = true,
			recursive_owner = true,
			method_add = XScene.STOPPED,
			method_remove = XScene.STOPPED,
			count_start = 0
		}
		x = XScene.new(n, true, d)

		assert_eq(x.defaults.hash(), d.hash())
		assert_eq(x.root, n)
		assert_true(x.flag_sync)
		assert_true(n.is_a_parent_of(x))
		assert_true(x.scenes.empty())

	func test_ready_sync():
		a = Node.new()
		b = Node.new()
		c = Node.new()
		n.add_child(a)
		n.add_child(b)
		n.add_child(c)
		x = XScene.new(n, true)
		assert_connected(get_tree(), x, "node_added", "_on_node_added")
		assert_eq(x.scenes[1].scene, a)
		assert_eq(x.scenes[2].scene, b)
		assert_eq(x.scenes[3].scene, c)

	func test_sync():
		x = XScene.new(n, true)
		a = Node.new()
		b = Node2D.new()
		n.add_child(a)
		n.add_child(b)
		b.hide()
		assert_eq(x.scenes[1].scene, a)
		assert_eq(x.scenes[2].scene, b)
		assert_eq(x.active, [1])
		assert_eq(x.hidden, [2])


class TestCheckScene:
	extends "res://addons/gut/test.gd"
	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")

	func before_all():
		n = Node.new()
		add_child(n)
		gut.p("ran run setup")

	func after_all():
		n.free()
		gut.p("ran teardown")

	func before_each():
		x = XScene.new(n, false)

	func after_each():
		for s in x.scenes.values():
			s.scene.free()
		x.free()

	func test_check_scene():
		assert_false(x._check_scene(null))
		assert_false(x._check_scene(1))
		var a = Node2D.new()
		var b = Node2D.new()
		var c = Node2D.new()
		var d = {a = x.ACTIVE, b = x.HIDDEN, c = x.STOPPED}
		x.add_scene(a, "a", d.a)
		x.add_scene(b, "b", d.b)
		x.add_scene(c, "c", d.c)
		assert_true(x._check_scene("a"))
		assert_true(x._check_scene("b"))
		assert_true(x._check_scene("c"))
		assert_eq(x.scenes.a.state, d.a)
		assert_eq(x.scenes.b.state, d.b)
		assert_eq(x.scenes.c.state, d.c)
		a.hide()
		assert_eq(x.scenes.a.state, x.HIDDEN)
		a.show()
		assert_eq(x.scenes.a.state, x.ACTIVE)
		n.remove_child(a)
		assert_eq(x.scenes.a.state, x.STOPPED)
		a.queue_free()
		assert_false(x._check_scene("a"))
		b.free()
		assert_false(x._check_scene("b"))
		assert_eq(c, x.x("c"))

	func test_check_scenes():
		var a = Node2D.new()
		var b = Node2D.new()
		var c = Node2D.new()
		var d = {a = x.ACTIVE, b = x.HIDDEN, c = x.STOPPED}
		x.add_scene(a, "a", d.a)
		x.add_scene(b, "b", d.b)
		x.add_scene(c, "c", d.c)
		assert_true(x.scenes.has("a"))
		assert_true(x.scenes.has("b"))
		assert_true(x.scenes.has("c"))
		assert_eq(x.active, ["a"])
		assert_eq(x.hidden, ["b"])
		assert_eq(x.stopped, ["c"])
		assert_eq(x.xs(), [a, b, c])
		assert_eq(x.xs(x.ACTIVE), [a])
		assert_eq(x.xs(x.HIDDEN), [b])
		assert_eq(x.xs(x.STOPPED), [c])
		a.free()
		b.queue_free()
		assert_false(x.scenes.has("a"))
		assert_false(x.scenes.has("b"))
		assert_eq(x.active, [])
		assert_eq(x.hidden, [])
		assert_eq(x.stopped, ["c"])
		assert_eq(x.xs(), [c])


class TestAdd:
	extends "res://addons/gut/test.gd"
	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")

	func before_all():
		n = Node.new()
		add_child(n)
		gut.p("ran run setup")

	func after_all():
		n.free()
		gut.p("ran teardown")

	func before_each():
		x = XScene.new(n, false)

	func after_each():
		for s in x.scenes.values():
			s.scene.free()
		x.free()

	func test_add_key():
		x.add_scene(s1)
		assert_true(1 in x.scenes)
		x.add_scene(s1, x.count)
		assert_true(2 in x.scenes)
		x.add_scene(s1, "hi")
		assert_true("hi" in x.scenes)

	func test_add_active():
		x.add_scene(s1)
		var s = x.scenes[1]
		assert_true(is_instance_valid(s.scene))
		assert_true(s.scene.is_inside_tree())
		assert_true(s.scene.visible)
		assert_eq(s.state, x.ACTIVE)
		assert_true(x.root.is_a_parent_of(s.scene))

	func test_add_hidden():
		x.add_scene(s1, x.count, x.HIDDEN)
		var s = x.scenes[1]
		assert_true(is_instance_valid(s.scene))
		assert_true(s.scene.is_inside_tree())
		assert_false(s.scene.visible)
		assert_eq(s.state, x.HIDDEN)
		assert_true(x.root.is_a_parent_of(s.scene))

	func test_add_stopped():
		x.add_scene(s1, x.count, x.STOPPED)
		var s = x.scenes[1]
		assert_true(is_instance_valid(s.scene))
		assert_false(s.scene.is_inside_tree())
		assert_eq(s.state, x.STOPPED)

	func test_add_deferred():
		x.add_scene(s1, x.count, 0, true)
		assert_true(x.scenes.empty())
		assert_eq(x.root.get_child_count(), 1)
		yield(get_tree(), "idle_frame")
		var s = x.scenes[1]
		assert_true(s.scene.is_inside_tree())
		assert_true(x.root.is_a_parent_of(s.scene))


class TestShow:
	extends "res://addons/gut/test.gd"
	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")

	func before_all():
		n = Node.new()
		add_child(n)
		gut.p("ran run setup")

	func after_all():
		n.free()
		gut.p("ran teardown")

	func before_each():
		x = XScene.new(n, false)
		x.add_scene(s1, x.count, x.HIDDEN)
		x.add_scene(s1, x.count, x.STOPPED)

	func after_each():
		for s in x.scenes.values():
			s.scene.free()
		x.free()

	func test_show_key():
		var s = x.scenes
		assert_false(s[1].scene.visible)
		x.show_scene(1)
		assert_true(s[1].scene.visible)
		assert_false(s[2].scene.is_inside_tree())
		x.show_scene(2)
		assert_true(s[2].scene.is_inside_tree())
		assert_true(x.root.is_a_parent_of(s[2].scene))

	func test_show_deferred():
		var s = x.scenes
		assert_false(s[2].scene.is_inside_tree())
		x.show_scene(2, true)
		assert_false(s[2].scene.is_inside_tree())
		yield(get_tree(), "idle_frame")
		assert_true(s[2].scene.is_inside_tree())
		assert_true(x.root.is_a_parent_of(s[2].scene))


class TestRemove:
	extends "res://addons/gut/test.gd"
	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")

	func before_all():
		n = Node.new()
		add_child(n)
		gut.p("ran run setup")

	func after_all():
		n.free()
		gut.p("ran teardown")

	func before_each():
		x = XScene.new(n, false)
		x.add_scene(s1, x.count, x.ACTIVE)
		x.add_scene(s1, x.count, x.HIDDEN)
		x.add_scene(s1, x.count, x.STOPPED)

	func after_each():
		for s in x.scenes.values():
			s.scene.free()
		x.free()

	func test_remove_key():
		pass

	func test_remove_free():
		assert_false(x.scenes.empty())

		var s

		s = x.scenes[1]
		assert_true(is_instance_valid(s.scene))
		x.remove_scene(1)
		assert_false(is_instance_valid(s.scene))

		s = x.scenes[2]
		assert_true(is_instance_valid(s.scene))
		x.remove_scene(2)
		assert_false(is_instance_valid(s.scene))

		s = x.scenes[3]
		assert_true(is_instance_valid(s.scene))
		x.remove_scene(3)
		assert_false(is_instance_valid(s.scene))

		assert_true(x.scenes.empty())

	func test_remove_hidden():
		var d = x.scenes
		assert_eq(d[1].state, x.ACTIVE)
		assert_eq(d[2].state, x.HIDDEN)
		assert_eq(d[3].state, x.STOPPED)

		var s
		s = x.scenes[1]
		assert_true(s.scene.visible)
		x.remove_scene(1, x.HIDDEN)
		assert_false(s.scene.visible)

		s = x.scenes[2]
		assert_false(s.scene.visible)
		x.remove_scene(2, x.HIDDEN)
		assert_false(s.scene.visible)

		s = x.scenes[3]
		assert_true(s.scene.visible)
		x.remove_scene(3, x.HIDDEN)
		assert_true(s.scene.visible)

		assert_eq(d[1].state, x.HIDDEN)
		assert_eq(d[2].state, x.HIDDEN)
		assert_eq(d[3].state, x.STOPPED)

	func test_remove_stopped():
		var d = x.scenes
		assert_eq(d[1].state, x.ACTIVE)
		assert_eq(d[2].state, x.HIDDEN)
		assert_eq(d[3].state, x.STOPPED)

		var s

		s = x.scenes[1]
		assert_true(s.scene.is_inside_tree())
		x.remove_scene(1, x.STOPPED)
		assert_false(s.scene.is_inside_tree())

		s = x.scenes[2]
		assert_true(s.scene.is_inside_tree())
		assert_false(s.scene.visible)
		x.remove_scene(2, x.STOPPED)
		assert_false(s.scene.is_inside_tree())
		assert_true(s.scene.visible)

		s = x.scenes[3]
		assert_false(s.scene.is_inside_tree())
		x.remove_scene(3, x.STOPPED)
		assert_false(s.scene.is_inside_tree())

		assert_eq(d[1].state, x.STOPPED)
		assert_eq(d[2].state, x.STOPPED)
		assert_eq(d[3].state, x.STOPPED)

	func test_remove_free_deferred():
		assert_false(x.scenes.empty())
		var s

		for i in range(1, 4):
			s = x.scenes[i]
			assert_true(is_instance_valid(s.scene))
			x.remove_scene(i, x.FREE, true)
			assert_true(is_instance_valid(s.scene))
			yield(get_tree(), "idle_frame")
			assert_false(is_instance_valid(s.scene))

		assert_true(x.scenes.empty())

	func test_remove_stopped_deferred():
		var d = x.scenes
		assert_eq(d[1].state, x.ACTIVE)
		assert_eq(d[2].state, x.HIDDEN)
		assert_eq(d[3].state, x.STOPPED)

		var s

		s = x.scenes[1]
		assert_true(s.scene.is_inside_tree())
		x.remove_scene(1, x.STOPPED, true)
		assert_true(s.scene.is_inside_tree())
		yield(get_tree(), "idle_frame")
		assert_false(s.scene.is_inside_tree())

		s = x.scenes[2]
		assert_true(s.scene.is_inside_tree())
		x.remove_scene(2, x.STOPPED, true)
		assert_true(s.scene.is_inside_tree())
		yield(get_tree(), "idle_frame")
		assert_false(s.scene.is_inside_tree())

		s = x.scenes[3]
		assert_false(s.scene.is_inside_tree())
		x.remove_scene(3, x.STOPPED, true)
		assert_false(s.scene.is_inside_tree())
		yield(get_tree(), "idle_frame")
		assert_false(s.scene.is_inside_tree())

		assert_eq(d[1].state, x.STOPPED)
		assert_eq(d[2].state, x.STOPPED)
		assert_eq(d[3].state, x.STOPPED)


class TestPack:
	extends "res://addons/gut/test.gd"
	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")

	func before_each():
		n = Node.new()
		add_child(n)

	func after_each():
		for c in get_children():
			c.free()

	func test_pack_scene():
		x = XScene.new(n)
		x.add_scene(s1)
		x.pack_root("res://example/test.scn")
		assert_true(File.new().file_exists("res://example/test.scn"))
		var s = load("res://example/test.scn").instance()
		add_child(s)
		assert_eq(s.get_child_count(), 1)
		assert_true(s.is_class("Node"))
		assert_true(s.get_child(0).is_class("Node2D"))
		assert_true(s.get_child(0).get_child(0).is_class("Node2D"))
		assert_true(s.get_child(0).get_child(0).get_child(0).is_class("Node2D"))
		assert_true(
			s.get_child(0).get_child(0).get_child(0).get_child(0).is_class(
				"Sprite"
			)
		)

	func test_pack_node():
		x = XScene.new(n)
		var a = Node2D.new()
		var b = Node2D.new()
		var c = Node2D.new()
		var d = Sprite.new()
		a.add_child(b)
		b.add_child(c)
		c.add_child(d)
		x.add_scene(a)
		x.pack_root("res://example/test.scn")
		assert_true(File.new().file_exists("res://example/test.scn"))
		var s = load("res://example/test.scn").instance()
		add_child(s)
		assert_eq(s.get_child_count(), 1)
		assert_true(s.is_class("Node"))
		assert_true(s.get_child(0).is_class("Node2D"))
		assert_eq(s.get_child(0).get_child_count(), 0)

	func test_pack_node_recursive():
		x = XScene.new(n)
		x.defaults.recursive_owner = true
		var a = Node2D.new()
		var b = Node2D.new()
		var c = Node2D.new()
		var d = Sprite.new()
		a.add_child(b)
		b.add_child(c)
		c.add_child(d)
		x.add_scene(a)
		x.pack_root("res://example/test.scn")
		assert_true(File.new().file_exists("res://example/test.scn"))
		var s = load("res://example/test.scn").instance()
		add_child(s)
		assert_eq(s.get_child_count(), 1)
		assert_true(s.is_class("Node"))
		assert_true(s.get_child(0).is_class("Node2D"))
		assert_true(s.get_child(0).get_child(0).is_class("Node2D"))
		assert_true(s.get_child(0).get_child(0).get_child(0).is_class("Node2D"))
		assert_true(
			s.get_child(0).get_child(0).get_child(0).get_child(0).is_class(
				"Sprite"
			)
		)

	func test_pack_nodes_recursive():
		x = XScene.new(n)
		x.defaults.recursive_owner = true
		var array = []
		for i in range(3):
			var a = Node2D.new()
			var b = Node2D.new()
			var c = Node2D.new()
			var d = Sprite.new()
			a.add_child(b)
			b.add_child(c)
			c.add_child(d)
			array.push_back(a)
		x.add_scenes(array)
		x.pack_root("res://example/test.scn")
		assert_true(File.new().file_exists("res://example/test.scn"))
		var s = load("res://example/test.scn").instance()
		add_child(s)
		assert_eq(s.get_child_count(), 3)
		assert_true(s.is_class("Node"))
		assert_true(s.get_child(0).is_class("Node2D"))
		assert_true(s.get_child(0).get_child(0).is_class("Node2D"))
		assert_true(s.get_child(0).get_child(0).get_child(0).is_class("Node2D"))
		assert_true(
			s.get_child(0).get_child(0).get_child(0).get_child(0).is_class(
				"Sprite"
			)
		)


class TestBulk:
	extends "res://addons/gut/test.gd"

	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")
	var s2 = load("res://example/scene2.tscn")
	var s3 = load("res://example/scene3.tscn")

	func before_each():
		n = Node.new()
		add_child(n)

	func after_each():
		for s in x.xs():
			s.free()
		for c in get_children():
			c.free()

	func test_bulk():
		x = XScene.new(n)
		var a = [s1, s2, s3]
		x.add_scenes(a)
		assert_eq(x.active, [1, 2, 3])
		x.add_scenes(a, ["a", "b", "c"], x.HIDDEN)
		assert_eq(x.hidden, ["a", "b", "c"])
		x.remove_scenes([1, 3], x.STOPPED)
		assert_eq(x.active, [2])
		assert_eq(x.stopped, [1, 3])
		assert_eq(x.hidden, ["a", "b", "c"])
		x.show_scenes(x.hidden)
		assert_eq(x.active, [2, "a", "b", "c"])

	func test_add_deferred():
		x = XScene.new(n)
		x.defaults.deferred = true
		var a = [s1, s2, s3]
		x.add_scenes(a)
		assert_true(x.scenes.empty())
		yield(get_tree(), "idle_frame")
		assert_eq(x.active, [1, 2, 3])
		x.remove_scenes([1, 3], x.STOPPED)
		# is still inside tree but .scenes is already updated
		assert_true(x.x(1).is_inside_tree())
		assert_eq(x.active, [2])
		assert_eq(x.stopped, [1, 3])
		x.add_scenes(a, ["a", "b", "c"], x.HIDDEN)
		assert_true(x.hidden.empty())
		yield(get_tree(), "idle_frame")
		assert_eq(x.hidden, ["a", "b", "c"])
		assert_false(x.x(1).is_inside_tree())
		x.show_scenes(x.hidden)
		# happens immediately
		assert_true(x.hidden.empty())
		assert_eq(x.stopped, [1, 3])
		x.show_scenes(x.stopped)
		assert_eq(x.stopped, [1, 3])
		yield(get_tree(), "idle_frame")
		assert_true(x.stopped.empty())
		assert_eq(x.scenes.keys(), [1, 2, 3, "a", "b", "c"])
		var temp = x.x(1)
		x.remove_scenes(x.scenes.keys())
		# is queued for deletion but still valid and scenes is already updated
		assert_true(temp.is_queued_for_deletion())
		assert_true(is_instance_valid(temp))
		assert_true(x.scenes.empty())
		yield(get_tree(), "idle_frame")
		assert_false(is_instance_valid(temp))
		assert_true(x.scenes.empty())


class TestExchange:
	extends "res://addons/gut/test.gd"

	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")
	var s2 = load("res://example/scene2.tscn")
	var s3 = load("res://example/scene3.tscn")

	func before_each():
		n = Node.new()
		add_child(n)

	func after_each():
		for s in x.xs():
			s.free()
		for c in get_children():
			c.free()

	func test_last_active():
		x = XScene.new(n)
		var a = [s1, s2, s3]
		x.add_scenes(a, ["a", "b", "c"])
		assert_eq(x.active[-1], "c")
		x.add_scenes(a)
		assert_eq(x.active[-1], 3)
		x.add_scenes(a, ["f", "e", "d"])
		assert_eq(x.active[-1], "d")
		x.remove_scenes(["a", "b", "c", "d", "e"], x.HIDDEN)
		assert_eq(x.active[-1], "f")
		x.remove_scene(2, x.STOPPED)
		assert_eq(x.active[-1], "f")
		# still "f" because 2 is still in scenes, and thats where
		# the order in active comes from
		x.show_scene(2)
		assert_eq(x.active[-1], "f")
		x.show_scenes(["a", "d"])
		# "a" still at index 0
		# "d" still at last index
		assert_eq(x.active[0], "a")
		assert_eq(x.active[-1], "d")
		x.remove_scene("c")
		x.add_scene(s1, "c")
		# only by removing from scenes and readding you change the order
		assert_eq(x.active[-1], "c")

	func test_x_scene():
		x = XScene.new(n)
		var a = [s1, s2, s3]
		x.add_scenes(a)
		x.add_scenes(a, ["a", "b", "c"], x.HIDDEN)
		x.x_scene("a", 1)
		assert_eq(x.active, [2, 3, "a"])
		x.x_scene("b")
		assert_eq(x.active, [2, 3, "b"])
		x.x_scene("c", 3)
		assert_eq(x.active, [2, "b", "c"])

	func test_x_add_scene():
		x = XScene.new(n)
		var a = [s1, s2, s3]
		x.add_scenes(a)
		x.x_add_scene(s1, "a", 1)
		assert_eq(x.active, [2, 3, "a"])
		x.x_add_scene(s1, "b")
		assert_eq(x.active, [2, 3, "b"])


class TestDefaults:
	extends "res://addons/gut/test.gd"

	var n: Node
	var x: Node
	var s1 = load("res://example/scene1.tscn")

	func before_each():
		n = Node.new()
		add_child(n)

	func after_each():
		for s in x.xs():
			s.free()
		for c in get_children():
			c.free()

	func test_defaults_init():
		var d = {
			count_start = 0,
			deferred = true,
			recursive_owner = true,
		}

		x = XScene.new(n, false, d)
		assert_eq(
			{
				deferred = true,
				recursive_owner = true,
				method_add = 0,
				method_remove = 3,
				count_start = 0
			}.hash(),
			x.defaults.hash()
		)
		assert_eq(x.count, 0)

	func test_defaults():
		x = XScene.new(n)
		assert_eq(x.defaults.hash(), x._original_defaults.hash())
		assert_eq(x.count, 1)

		# these have to work
		x.defaults.count_start = 100
		x.defaults.count_start = 0
		assert_eq(x.count, 1)
		x.defaults.method_add = 0
		x.defaults.method_add = 1
		x.defaults.method_add = 2
		x.defaults.method_remove = 1
		x.defaults.method_remove = 2
		x.defaults.method_remove = 3
		x.defaults.deferred = true
		x.defaults.deferred = false
		x.defaults.recursive_owner = true
		x.defaults.recursive_owner = false

		# reset
		x.defaults = x._original_defaults
		assert_eq(x.defaults.hash(), x._original_defaults.hash())

		# partial assignment
		var d = {
			count_start = 0,
			deferred = true,
			recursive_owner = true,
		}
		x.defaults = d
		assert_eq(
			{
				deferred = true,
				recursive_owner = true,
				method_add = 0,
				method_remove = 3,
				count_start = 0
			}.hash(),
			x.defaults.hash()
		)
