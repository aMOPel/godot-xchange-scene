#!/bin/bash
pushd docs

docker run --rm -v $HOME/Documents/godot_projects/godot-xchange-scene:/game -v $HOME/Documents/godot_projects/godot-xchange-scene/docs:/output gdquest/gdscript-docs-maker:latest /game -o /output
fdfind -E XScene.md | xargs rm

popd
