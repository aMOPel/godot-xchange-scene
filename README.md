# godot-scene-switcher

__THIS REPO ISN'T IN A GODOT PLUGIN FORMAT__

Inspired by [this part of the godot 
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually)
I wrote a little wrapper around the ways to switch scenes.

This Repo contains this wrapper and a ready to go example of its usage.

__TL;DR__:
The scene switcher script is in `utils/scene_switcher.gd` (160 lines)
In `world.gd` you can see how to use it.  


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

## TODO

  - making sure the scene lists stay in sync with other changes
  - subscene support
  - wrapper for arbitrary amounts of scenes, eg add_scene([NodePath, ...])


