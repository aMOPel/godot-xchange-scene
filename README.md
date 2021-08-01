# godot-scene-switcher

inspired by [this part of the godot 
docs](https://docs.godotengine.org/en/stable/tutorials/misc/change_scenes_manually.html#doc-change-scenes-manually)
I wrote a little wrapper around the ways to switch scenes.

This Repo contains this wrappes and a ready to go example of its usage.

The scene switcher script is in utils/scene_switcher.gd (160 lines)
It's managed by the Utils Autoload script.
In world.gd you can see what is happening.
The rest of the Nodes are basically just dummy nodes.

## TODO

  - making sure the scene lists stay in sync with other changes
  - subscene support
  - wrapper for arbitrary amounts of scenes, eg add_scene([NodePath, ...])


