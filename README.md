![EXchangeScene](https://raw.githubusercontent.com/aMOPel/godot-EXchangeScene/main/crime-scene.png)

# EXchangeScene

__Robust, high level interface__ for manipulating scenes below a given `NodePath`

__Disclaimer:__ In the following, when talking about __scenes__, often it's about the __instance__ of the scene, 
which is added as a __child scene__ to the tree, and which is also a __Node__.

Inspired by [this part of the godot
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually).

## TL;DR
Scenes can be in these __states__:

| state | function used | consequence |
|:---:|:---:|:---:|
| __ACTIVE__ |`.add_child(Node)`   |running and visible|
| __HIDDEN__ |`Node.hide()`        |running and hidden|
| __STOPPED__|`.remove_child(Node)`|not running, but still in memory|
| __FREE__   |`Node.free()`        |no longer in memory and no longer indexed|

In the [__example/main.gd__](example/main.gd) you can see all of the features in action.

Here is a first taste:

```gdscript
var scene1 = preload("scene1.tscn")
# x adds and removes scenes below World, takes Node or NodePath
var x = XSceneManager.get_x_scene($World)

# add_scene takes a PackedScene or a Node
# without a key specified it indexes automatically with integers starting at 1 (this can be changed to 0)
# default method is ACTIVE, using add_child()
x.add_scene(scene1)
# uses add_child() and .hide()
x.add_scene(scene1, "a", x.HIDDEN)
# just instances and indexes the scene
x.add_scene(scene1, "stopped_s1", x.STOPPED)

# ┖╴root
# 	┠╴XSceneManager <- AutoLoad
# 	┃  ┖╴@@2 <- x
# 	┖╴Main
# 	   ┠╴Gui
# 	   ┃  ┖╴ColorRect
# 	   ┠╴World
# 	   ┃  ┠╴Node2D <- was already in the tree via editor
# 	   ┃  ┃  ┖╴Node2D
# 	   ┃  ┃     ┖╴Node2D
# 	   ┃  ┃        ┖╴icon
# 	   ┃  ┠╴@Node2D@3 <- 1
# 	   ┃  ┃  ┖╴Node2D
# 	   ┃  ┃     ┖╴Node2D
# 	   ┃  ┃        ┖╴icon
# 	   ┃  ┖╴@Node2D@4 <- "a" hidden but in tree
# 	   ┃     ┖╴Node2D
# 	   ┃        ┖╴Node2D
# 	   ┃           ┖╴icon
#      ┃              <- "stopped_s1" not in the tree
# 	   ┖╴Test

print(x.scenes)
# {1:{scene:[Node2D:1235], status:0}, -> ACTIVE
# a:{scene:[Node2D:1239], status:1}, -> HIDDEN
# stopped_s1:{scene:[Node2D:1243], status:2}} -> STOPPED

# uses remove_child()
x.remove_scene(1, x.STOPPED)
# ┠╴World
# ┃  ┠╴Node2D
# ┃  ┃  ┖╴Node2D
# ┃  ┃     ┖╴Node2D
# ┃  ┃        ┖╴icon
# ┃  ┖╴@Node2D@4 <- "a" still hidden but in tree
# ┃     ┖╴Node2D
# ┃        ┖╴Node2D
# ┃           ┖╴icon
# ┃              <- 1 no longer in tree
# ┖╴Test

# make all STOPPED scenes ACTIVE
# mind the plural
x.show_scenes(x.stopped)
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

# exchange scene, makes "a" ACTIVE, and uses .free() on "stopped_s1"
# it defaults to FREE, the argument isn't necessary here
x.x_scene("a", "stopped_s1", x.FREE)
# ┠╴World
# ┃  ┠╴Node2D
# ┃  ┃  ┖╴Node2D
# ┃  ┃     ┖╴Node2D
# ┃  ┃        ┖╴icon
# ┃  ┠╴@Node2D@4 <- "a" no longer hidden
# ┃  ┃  ┖╴Node2D
# ┃  ┃     ┖╴Node2D
# ┃  ┃        ┖╴icon
# ┃  ┖╴@Node2D@3 <- 1
# ┃     ┖╴Node2D
# ┃        ┖╴Node2D
# ┃           ┖╴icon
# ┃              <- "stopped_s1" no longer in tree and no longer indexed
# ┖╴Test

# to access ("x"ess) the scene/node of "a" directly
x.x("a").hide()
# to access all hidden scenes directly, returns an array of nodes
x.xs(x.HIDDEN)

# put $World into a file using PackedScene.pack()
x.pack("res://example/test.scn")

# .free() everything indexed by x, remove_scene/s defaults to FREE
# mind the plural
x.remove_scenes(x.scenes.keys())
```

## Features

  - Optional __deferred calls__
    + All of the operations can be called deferred for __(thread) safety__
  - Indexing and __easy access__
    + All scenes managed by this plugin will be indexed in a dictionary, have 'keys' (identifiers) associated with them and can be accessed either one by one or grouped by state. 
  - Lazy __validity checks__ on access
    + The validity of Nodes below `NodePath` is always checked before accessed (lazily), so even if you `free()` a Node somewhere else, you wont get an invalid reference from this plugin.  Also external calls to `Node.hide()` , `Node.show()` and `.remove_child(Node)` are checked lazily
  - Active __sync__
    + You can keep in sync with __external additions__ to the tree (this can be slow, see [Caveats](#Caveats))
  - __Ownership management__ / `pack()` support
    + `Node.owner` of nodes added below `NodePath` can be set __recursively__, so you can `pack()` and save the whole created scene to file later
  - Subscene support / __self validity check__
    + Instances of the __XScene__ class will `self.queue_free()`, when `NodePath` was freed, thus preventing errors when trying to manipulating scenes below a freed Node
    + So it's good practice to have a condition `if is_instance_valid(XScene_instance):` in the beginning of every function and after every `yield` when planing to use a `XScene` instance
  - __Bulk__ functions

## Why not just use `get_tree().change_scene()`?

It exchanges the whole current scene against another whole scene. Only the
AutoLoads are transferred automatically. __If that doesn't cut it for you, this
plugin might be for you.__

With the commands from this plugin you can __more granularly control__ which 
part of the whole current scene you want to change and how you want to change it. 
[See above](#Usage) for possibilities. This is especially interesting for __better control over memory__.

## Installation

_Made with Godot version 3.3.2.stable.official_

This repo is in a __Godot Plugin format__. You can install it over the 
__AssetLib__, or download a __.zip__ of this repo and put it in your project.

For more details, read the [godot docs on installing Plugins 
](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

__Don't forget to enable it in your project settings!__

## Usage

In the [__example/main.gd__](example/main.gd) you can see how to use it.

This plugin, while it is enabled, adds an `AutoLoad` named `XSceneManager` to 
your project.

With `var x = XSceneManager.get_x_scene(NodePath)` you get an instance of `XScene` (the main class), which acts below 
`NodePath`. However in the `SceneTree` it sits below the `AutoLoad` `XSceneManager` Node, 
so it's not cluttering your scenes.

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

  - This plugin adds an __overhead__ to adding and removing scenes. When you add or remove in __high quantities__, you should consider using the __built-in commands__ if you don't have to index the scenes so thoroughly.
  - The __sync feature__ adds __more overhead__ and should also only be used for __small quantities__ of scenes. Mind that this feature, checks for every addition in the whole tree, so if you were to have a few XScene instances with sync enabled, every instances will make checks and add even more overhead

Here are some really __basic benchmarks__ taken on my mediocre personal PC.

This comes from adding (ACTIVE) and removing (FREE) __1000 instances__ of a scene 
that consists of 4 nodes below `NodePath`. Every test was done __10 times__ and the 
time was averaged.

|X|no sync|sync|
|---|---|---|
|`add_child()`|0.011148|0.020159|
|`add_scene(ACTIVE)`|0.014747|0.017216|
|`free()`|0.090902|0.098739|
|`remove_scene(FREE)`|0.098556|0.099513|

These measurements aren't exactly statistically significant, but they give a good 
idea of the __overhead__ added by this plugin, especially when using __sync__. Note that
the overhead is more or less independent of sync when removing scenes.

## TODO

  - You can open an issue if you're missing a feature

## Attributions

Icon made by [Freepik](https://www.freepik.com) from
[Flaticon](https://www.flaticon.com/)
