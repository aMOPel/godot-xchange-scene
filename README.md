![EXchangeScene](https://raw.githubusercontent.com/aMOPel/godot-EXchangeScene/main/crime-scene.png)


# EXchangeScene

Made with Godot version 3.3.2.stable.official

Inspired by [this part of the godot
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually)
I wrote a wrapper around the ways to __exchange scenes__.

__TL;DR__:
In the [__example/main.gd__](example/main.gd) you can see how to use it.

## Features

  - High level __interface__ for manipulating scenes below a given `NodePath`
  - Scenes can be in these __states__:
    + __ACTIVE__  `.add_child(Node)` running and visible
    + __HIDDEN__  `Node.hide()` running and hidden
    + __STOPPED__ `.remove_child(Node)` not running but still in memory
    + __FREE__    `Node.free()` and no longer in memory and no longer tracked
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
See above for possibilities. This is especially interesting for __better control over memory__.

## Installation

This repo is in a __Godot Plugin format__. You can install it over the 
__AssetLib__, or download a __.zip__ of this repo and put it in your project.

For more details, read the [godot docs on installing Plugins 
](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

__Don't forget to enable it in your project settings!__

## Usage

In the [__example/main.gd__](example/main.gd) you can see how to use it.

This plugin, while it is enabled, adds an __AutoLoad__ named `XSceneManager` to 
your project.

With `var x = XSceneManager.get_x_scene(NodePath)` you get an instance of __XScene__ (the main class), which acts below 
`NodePath`, but in the `SceneTree` it sits below the __AutoLoad__ `XSceneManager` Node, 
so it's not cluttering your scenes.

## Transistions


| from\to | ACTIVE = 0 | HIDDEN = 1 | STOPPED = 2 | FREE = 3 |
|:---:|:---:|:---:|:---:|:---:|
|__ACTIVE__|---|`remove_scene(key, HIDDEN)`|`remove_scene(key, STOPPED)`|`remove_scene(key, FREE)`|
|__HIDDEN__|`show_scene(key)`|---|`remove_scene(key, STOPPED)`|`remove_scene(key, FREE)`|
|__STOPPED__|`show_scene(key)`|---|---|`remove_scene(key, FREE)`|
|__FREE__ |`add_scene(scene, key, ACTIVE)`|`add_scene(scene, key, HIDDEN)`|`add_scene(scene, key, STOPPED)`|---|

The states are just an `enum`, so you can also use the integers, but writing out 
the names helps readability of your code.

Normally the visibility of a node (HIDDEN) and if it's in the tree or not 
(STOPPED), are unrelated. However, in this plugin it's either or. Meaning, when 
a hidden scene is stopped, its visibility will be reset to true. And when a
stopped scene happened to also be hidden, `show_scene` will reset its visibility 
to true.

NOTE: Although this plugin resembles a state machine, it isn't implemented as 
one.

## Caveats

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

Icons made by [Freepik](https://www.freepik.com) from
[Flaticon](https://www.flaticon.com/)
