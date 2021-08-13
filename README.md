![xchange-scene](https://raw.githubusercontent.com/aMOPel/godot-xchange-scene/main/crime-scene.png)

# xchange-scene

Xchange-scene is a __robust, high level interface__ for manipulating child scenes below a given `Node` and indexing them.

_Disclaimer: In the following, when talking about __scenes__, often it's about the __instance__ of the scene, which is added as a __child scene__ to the tree, and which is also a __Node__._

Inspired by [this part of the godot
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually).

### TL;DR
Scenes can be in these __states__:

| state | function used | consequence |
|:---:|:---:|:---:|
| __ACTIVE__ |`.add_child(Node)`   |running and visible|
| __HIDDEN__ |`Node.hide()`        |running and hidden|
| __STOPPED__|`.remove_child(Node)`|not running, but still in memory|
| __FREE__   |`Node.free()`        |no longer in memory and no longer indexed|

In the [__example/main.gd__](example/main.gd) you can see __all of the features__ in action.

Here is a first taste:

```gdscript
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
# this can be loaded later, it includes x.root

# .free() everything indexed by x, remove_scene/s defaults to FREE
# mind the plural
x.remove_scenes(x.scenes.keys())
```

### Features

  - __Indexing and easy access__
    + All scenes managed by this plugin will be indexed in a dictionary and can be accessed either one by one or grouped by state.
  - __Lazy validity checks__ on access
    + The validity and state of indexed Nodes is always checked before accessed (lazily). This goes for external `.free()`, `.hide()` , `.show()` or `.remove_child(Node)`.
  - __Active sync__
    + You can keep in sync with __external additions__ to the tree, meaning external `add_child(Node)`. (this can be slow, see [Caveats](#Caveats))
  - __Deferred calls__
    + All of the tree changes can be called deferred for __(thread) safety__.
  - __Ownership management__ and `pack()` support
    + `Node.owner` of nodes added below `root` can be set __recursively__, so you can `pack_root()` and save the whole created scene to file for later.
  - __Nested Scenes__
    + Instances of the __XScene__ class will add themselves below `root`, thus freeing themselves when `root` is freed.
  - __Bulk functions__
    + To add/show/remove many nodes at once

### Why not just use `get_tree().change_scene()`?

See [this part of the godot
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually)

`get_tree().change_scene()` exchanges the whole current scene against another whole scene. Only the
AutoLoads are transferred automatically. __If that doesn't cut it for you, this
plugin might be for you.__

With the commands from this plugin you can __more granularly control__, which
part of the whole current scene you want to change and how you want to change it.
See [__example/main.gd__](example/main.gd) for possibilities. This is especially interesting for __better control over memory__.

### Installation

_Made with Godot version 3.3.2.stable.official_

This repo is in a __Godot Plugin format__.

You can:
- Install it via [__AssetLib__](https://godotengine.org/asset-library/asset/1018) or
- Download a __.zip__ of this repo and put it in your project

For more details, read the [godot docs on installing Plugins
](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

__Don't forget to enable it in your project settings!__

### Run examples

To run the examples yourself, you can
1. Clone this repo 
`git clone https://github.com/aMOPel/godot-xchange-scene.git xscene`
2. Run godot in it (eg. using linux and bash)
`cd xscene; godot --editor`
3. Comment and uncomment the functions in [__example/main.gd__](example/main.gd) `_ready()`
4. Run the main scene in godot

### Usage

In the [__example/main.gd__](example/main.gd) you can see how to use it. 
There are little __tutorials__ split in functions with __a lot of comments__ to explain everything in detail.

Also in [__docs/XScene.md__](docs/XScene.md) is a full markdown reference built from the docstrings.
However it is hard to read on Github because it merges the linebreaks. Either read it in an editor on read it 
["Raw" on Github](https://raw.githubusercontent.com/aMOPel/godot-xchange-scene/main/docs/XScene.md).

```gdscript
# example/main.gd

# gives an instance of XScene
# it adds itself below $World
# it doesn't index itself
x = XScene.new($World)
# ┖╴root
# 	┖╴Main
# 	   ┠╴Gui
# 	   ┃  ┖╴ColorRect
# 	   ┖╴World <- acts below World
# 	      ┖╴@@2 <- x
```

This will give you an instance of `XScene` (the main class), which acts and sits below
`World`. 

### Transistions

| from\to | ACTIVE = 0 | HIDDEN = 1 | STOPPED = 2 | FREE = 3 |
|:---:|:---:|:---:|:---:|:---:|
|__ACTIVE__|---|`remove_scene(key, HIDDEN)`|`remove_scene(key, STOPPED)`|`remove_scene(key, FREE)`|
|__HIDDEN__|`show_scene(key)`|---|`remove_scene(key, STOPPED)`|`remove_scene(key, FREE)`|
|__STOPPED__|`show_scene(key)`|---|---|`remove_scene(key, FREE)`|
|__FREE__ |`add_scene(scene, key, ACTIVE)`|`add_scene(scene, key, HIDDEN)`|`add_scene(scene, key, STOPPED)`|---|

The states are just an `enum`, so you can also use the integers, but writing out
the names helps readability of your code.

Normally the _visibility of a node (HIDDEN)_ and _if it's in the tree or not
(STOPPED)_, are unrelated. However, in this plugin it's _either or_. Meaning, when
a hidden scene is stopped, its visibility will be reset to `true`. And when a
stopped scene happened to also be hidden, `show_scene` will reset its visibility
to `true`.

__NOTE__: Although this plugin resembles a state machine, it isn't implemented as
one.

### Caveats

  - This plugin adds an __overhead__ to adding and removing scenes. When you add or remove in __high quantities__, you should consider using the __built-in commands__, if you don't have to index the scenes so thoroughly.
  - The __sync feature__ adds __more overhead__ and should also only be used for __small quantities__ of scenes. Mind that this feature checks for every addition in the whole tree. So if you were to have a few `XScene` instances with sync enabled, every instances will make checks and add even more overhead

Here are some really __basic benchmarks__ taken on my mediocre personal PC.

This benchmark comes from adding (ACTIVE) and removing (FREE) __1000 instances__ of a scene
that consists of 4 nodes below `root`. Every test was done __10 times__ and the
time was averaged. In [__example/main.gd__](example/main.gd) `test_time()` you can see the code used.

|X|no sync|sync|
|---|---|---|
|`add_child()`|0.011148|0.020159|
|`add_scene(ACTIVE)`|0.014747|0.017216|
|`free()`|0.090902|0.098739|
|`remove_scene(FREE)`|0.098556|0.099513|

These measurements aren't exactly statistically significant, but they give a good
idea of the __overhead__ added by this plugin, especially when using __sync__. Note that
the overhead is more or less independent of sync when removing scenes.

### TODO

  - You can open an issue if you're missing a feature

### Attributions

Icon made by [Freepik](https://www.freepik.com) from
[Flaticon](https://www.flaticon.com/)
