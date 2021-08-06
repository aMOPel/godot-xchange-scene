# EXchangeScene

Made with Godot version 3.3.2.stable.official

Inspired by [this part of the godot
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually)
I wrote a wrapper around the ways to exchange scenes.

__TL;DR__:
[Here](example/world.gd) you can see how to use it.

## Why not just use `get_tree().change_scene()`?

It exchanges the whole current scene against another whole scene. Only the
AutoLoads are transferred automatically. If that doesn't cut it for you, this
plugin might be for you.

With the commands above you can more granularly control which part of the whole
current scene you want to change and how you want to change it. See above for
possibilities. This is especially interesting for better control over the
memory.

In the Godot docs is also a [little section about why AutoLoads shouldn't be 
used 
excessively.](https://docs.godotengine.org/en/stable/getting_started/workflow/best_practices/autoloads_versus_internal_nodes.html)


## Features

  - High level interface for manipulating scenes below a given NodePath
  - Scenes can be in these states:
    + ACTIVE  `.add_child(Node)` running and visible
    + HIDDEN  `Node.hide()` running and hidden
    + STOPPED `.remove_child(Node)` not running but still in memory
    + FREE    `Node.free()` and no longer in memory and no longer tracked
  - All of these can be called deferred for (thread) safety
  - All scenes managed by this interface will be tracked in a dictionary, have 'keys' 
      (identifiers) associated with them and can be accessed either one by one 
      or grouped by state.  
  - The validity of nodes is always checked before accessed (lazily), so even if 
      you `free()` a Node somewhere else you wont get a invalid reference from 
      this interface. 
  - Also external `Node.hide()` , `Node.show()` and `.remove_child(Node)` are 
      checked lazily
  - In addition you can keep in sync with external additions to the tree (this
      will be slow when you add a lot of Nodes below the NodePath
      externally)

## Installation

This repo is in a Godot Plugin format. You can install it over the AssetLib, or 
download a .zip of this repo and put it in your project.

For more details, read the [godot docs on installing Plugins 
](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html)

**Don't forget to enable it in your project settings!**

## Transistions

| from\to | FREE | ACTIVE | HIDDEN | STOPPED |
| --- | --- | --- | --- |--- |
|FREE|---|add_scene(scene, key, ACTIVE)|add_scene(scene, key, HIDDEN)|add_scene(scene, key, STOPPED)|
|ACTIVE|remove_scene(key, FREE)|---|remove_scene(key, HIDDEN)|remove_scene(key, STOPPED)|
|HIDDEN|remove_scene(key, FREE)|show_scene(key)|---|remove_scene(key, STOPPED)|
|STOPPED|remove_scene(key, FREE)|show_scene(key)|---|---|

ACTIVE and FREE are synonym, but FREE only makes sense for remove_scene().
You can also use remove_scene(key, ACTIVE) and see it as "active removal".

NOTE: Although this interface resembles a state machine, it isn't implemented as 
one.

## Usage

[Here](example/world.gd) you can see how to use it.

This plugin, while it is active, adds an AutoLoad named `XSceneManager` to your 
project.
Eg.

`var sw = XSceneManager.get_x_scene(NodePath)`

gives you an instance of XScene, which acts below `NodePath`, but in the tree it 
sits below the AutoLoad XSceneManager Node, so it's not cluttering your scenes.

## Caveats

  - this interface adds an overhead to adding and removing scenes. When you add 
      or remove in high quantities, you should consider using the built-in 
      commands if you don't have to index the scenes so thoroughly.
  - the sync feature adds more overhead and should also only be used for small 
      quantities of scenes. Mind that this feature, checks for every addition in 
      the whole tree, so if you were to have a few XScene instances with sync 
      enabled, every instances will make checks and add even more overhead

## TODO

  - subscene support
  - wrapper for arbitrary amounts of scenes, eg add_scenes([NodePath, ...])
  - owner support

## Attributions

Icons made by [Freepik](https://www.freepik.com) from
[Flaticon](https://www.flaticon.com/)
