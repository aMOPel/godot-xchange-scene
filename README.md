# godot-scene-switcher

Godot version 3.3.2.stable.official

__THIS REPO ISN'T IN A GODOT PLUGIN FORMAT__

Inspired by [this part of the godot 
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually)
I wrote a little wrapper around the ways to switch scenes.


__TL;DR__:
The scene switcher script is in `utils/scene_switcher.gd` (300 lines)
In `world.gd` you can see how to use it.  

## Features

  - high level api for manipulating scenes below a given NodePath
  - Scenes can be in these states:
    + ACTIVE `.add_child(Node)` running and visible
    + HIDDEN `Node.hide()` running and hidden
    + STOPPED `.remove_child(Node)` not running but still in memory
    + deleted `Node.free()` and no longer in memory and no longer tracked
  - all of these can be called deferred for thread safety
  - all scenes managed by this API will be tracked
  - the validity of nodes is always checked before accessed (lazily), so even if 
      you `free()` a Node somewhere else you wont get a invalid reference from 
      this API.
  - also external .hide() and .show() are checked lazily
  - in addition you can keep in sync with external additions to the tree (this 
      will be very slow when you add a lot of Nodes (10k+) below the NodePath 
      externally)



## Why not just use `get_tree().change_scene()`?

It exchanges the whole current scene against another whole scene. Only the 
AutoLoads are transferred automatically. If this doesn't cut it for you, this 
plugin might be for you.

With the commands above you can more granularly control which part of the whole 
current scene you want to change and how you want to change it. See above for 
possibilities. This is especially interesting for better control over the 
memory.

In the Godot docs is also a little section about why AutoLoads shouldn't be used 
excessively.  
https://docs.godotengine.org/en/stable/getting_started/workflow/best_practices/autoloads_versus_internal_nodes.html

## Explanation

The `utils.gd` script is an Autoload script and Singleton named "Utils". It's 
there to provide various utility classes (in theory). With 
`Utils.get_scene_switcher(NodePath)` you get an instance of a switcher for this 
specific path. It's attached to the tree under `/root/Utils` at runtime. It 
keeps track of the Nodes below `NodePath` and provides methods to manipulate the 
state of these nodes.

For deeper understanding look in `scene_switcher.gd`, read the docstring and 
look in `world.gd` for the usage.

The rest of the Nodes are basically just dummy nodes.

## Caveats

  - using the sync option might be slow if you add or remove a lot of nodes to 
      the scene tree, because it uses the `node_added` and `node_removed` 
      signals of the whole scene tree

## TODO

  - making sure the scene lists stay in sync with other changes
  - subscene support
  - wrapper for arbitrary amounts of scenes, eg add_scene([NodePath, ...])


## Attributions

Icons made by [Freepik](https://www.freepik.com) from 
[Flaticon](https://www.flaticon.com/)
