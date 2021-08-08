[](crime-scene.png)


# EXchangeScene

Made with Godot version 3.3.2.stable.official

Inspired by [this part of the godot
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually)
I wrote a wrapper around the ways to exchange scenes.

__TL;DR__:
[Here](example/main.gd) you can see how to use it.

## Why not just use `get_tree().change_scene()`?

It exchanges the whole current scene against another whole scene. Only the
AutoLoads are transferred automatically. If that doesn't cut it for you, this
plugin might be for you.

With the commands from this plugin you can more granularly control which part of 
the whole
current scene you want to change and how you want to change it. See above for
possibilities. This is especially interesting for better control over memory.


## Features

  - High level interface for manipulating scenes below a given NodePath
  - Scenes can be in these states:
    + ACTIVE  `.add_child(Node)` running and visible
    + HIDDEN  `Node.hide()` running and hidden
    + STOPPED `.remove_child(Node)` not running but still in memory
    + FREE    `Node.free()` and no longer in memory and no longer tracked
  - Optional deferred calls
    + All of the operations can be called deferred for (thread) safety
  - Indexing and easy access
    + All scenes managed by this plugin will be indexed in a dictionary, have 'keys' (identifiers) associated with them and can be accessed either one by one or grouped by state. 
  - Lazy validity checks on access
    + The validity of nodes is always checked before accessed (lazily), so even if you `free()` a Node somewhere else you wont get an invalid reference from this plugin.  Also external `Node.hide()` , `Node.show()` and `.remove_child(Node)` are checked lazily
  - Active sync
    + You can keep in sync with external additions to the tree (this will be slow when you add a lot of Nodes below the NodePath externally)
  - Ownership management / pack() support
    + Node.owner of nodes added below NodePath can be set recursively, so you can `.pack(NodePath)` and save the whole created scene to file later
  - Subscene support / self validity check
    + Instances of the XScene class will `self.queue_free()`, when NodePath was freed, thus preventing errors when trying to manipulating scenes below a freed node
    + So it's good practice to have a condition `if is_instance_valid(XScene_instance):` in the beginning of every function and after every yield when planing to use a XScene instance
  - Bulk functions

## Installation

This repo is in a Godot Plugin format. You can install it over the AssetLib, or 
download a .zip of this repo and put it in your project.

For more details, read the [godot docs on installing Plugins 
](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

**Don't forget to enable it in your project settings!**

## Transistions


| from\to | ACTIVE | HIDDEN | STOPPED | FREE |
| --- | --- | --- | --- |--- |
|ACTIVE = 0|---|remove_scene(key, HIDDEN)|remove_scene(key, STOPPED)|remove_scene(key, FREE)|
|HIDDEN = 1|show_scene(key)|---|remove_scene(key, STOPPED)|remove_scene(key, FREE)|
|STOPPED = 2|show_scene(key)|---|---|remove_scene(key, FREE)|
|FREE = 3|add_scene(scene, key, ACTIVE)|add_scene(scene, key, HIDDEN)|add_scene(scene, key, STOPPED)|---|

The states are just an enum, so you can also use the integers, but writing out 
the names helps readability of your code.

Normally the visibility of a node (HIDDEN) and if it's in the tree or not 
(STOPPED), are unrelated. However, in this plugin it's either or. Meaning, when 
a hidden scene is stopped, its visibility will be reset to true. And when a
stopped scene happened to also be hidden, `show_scene` will reset its visibility 
to true.

NOTE: Although this plugin resembles a state machine, it isn't implemented as 
one.

## Usage

[Here](example/main.gd) you can see how to use it.

This plugin, while it is active, adds an AutoLoad named `XSceneManager` to your 
project.

`var x = XSceneManager.get_x_scene(NodePath)`

gives you an instance of XScene, which acts below `NodePath`, but in the tree it 
sits below the AutoLoad XSceneManager Node, so it's not cluttering your scenes.

## Caveats

  - This plugin adds an overhead to adding and removing scenes. When you add or remove in high quantities, you should consider using the built-in commands if you don't have to index the scenes so thoroughly.
  - The sync feature adds more overhead and should also only be used for small quantities of scenes. Mind that this feature, checks for every addition in the whole tree, so if you were to have a few XScene instances with sync enabled, every instances will make checks and add even more overhead

Here are some really basic benchmarks taken on my mediocre personal PC.

This comes from adding (ACTIVE) and removing (FREE) 1000 instances of a scene 
that consists of 4 nodes below NodePath. Every test was done 10 times and the 
time was averaged.

|X|no sync|sync|
|---|---|---|
|add_child()|0.011148|0.020159|
|add_scene(ACTIVE)|0.014747|0.017216|
|free()|0.090902|0.098739|
|remove_scene(FREE)|0.098556|0.099513|

These measurements aren't exactly statistically significant but they give a good 
idea of the overhead added by this plugin, especially when using sync. Note that
the overhead is more or less independent of sync when removing scenes.

## TODO

  - You can open an issue if you're missing a feature
## Attributions

Icons made by [Freepik](https://www.freepik.com) from
[Flaticon](https://www.flaticon.com/)
