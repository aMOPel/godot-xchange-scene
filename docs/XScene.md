<!-- Auto-generated from JSON by GDScript docs maker. Do not edit this document directly. -->

# XScene

**Extends:** [Node](../Node)

## Description

__robust, high level interface__ for manipulating and indexing scenes below a
given `Node`.

## Constants Descriptions

### ACTIVE

```gdscript
const ACTIVE: int = 0
```

enum with the scene states
`ACTIVE` = 0 uses `add_child()`
`HIDDEN` = 1 uses `.hide()`
`STOPPED` = 2 uses `remove_child()`
`FREE` = 3 uses `.free()`

### FREE

```gdscript
const ACTIVE: int = 0
```

enum with the scene states
`ACTIVE` = 0 uses `add_child()`
`HIDDEN` = 1 uses `.hide()`
`STOPPED` = 2 uses `remove_child()`
`FREE` = 3 uses `.free()`

### HIDDEN

```gdscript
const ACTIVE: int = 0
```

enum with the scene states
`ACTIVE` = 0 uses `add_child()`
`HIDDEN` = 1 uses `.hide()`
`STOPPED` = 2 uses `remove_child()`
`FREE` = 3 uses `.free()`

### STOPPED

```gdscript
const ACTIVE: int = 0
```

enum with the scene states
`ACTIVE` = 0 uses `add_child()`
`HIDDEN` = 1 uses `.hide()`
`STOPPED` = 2 uses `remove_child()`
`FREE` = 3 uses `.free()`

## Property Descriptions

### scenes

```gdscript
var scenes: Dictionary
```

- **Getter**: `get_scenes`

Dictionary that holds all indexed scenes and their state
has either `count` or String as keys
Eg. {1:{scene:[Node2D:1235], state:0}, abra:{scene:[Node2D:1239], state:1}}

### active

```gdscript
var active: Array
```

- **Getter**: `get_active`

Array of keys of active scenes

### hidden

```gdscript
var hidden: Array
```

- **Getter**: `get_hidden`

Array of keys of hidden scenes

### stopped

```gdscript
var stopped: Array
```

- **Getter**: `get_stopped`

Array of keys of stopped scenes

### root

```gdscript
var root: Node
```

the Node below which this class will manipulate scenes

### flag\_sync

```gdscript
var flag_sync: bool
```

wether to synchronize `scenes` with external additions to the tree
__WARNING__ this can be slow, read the __Caveats__ Section in the README.md

### defaults

```gdscript
var defaults: Dictionary
```

Dictionary that hold the default values for parameters used in add/show/remove \
__WARNING__ if you change the values to something not of its original type, \
things will break \
`deferred` = false, \
`recursive_owner` = false, \
`method_add` = ACTIVE, \
`method_remove` = FREE, \
`count_start` = 1 \

### count

```gdscript
var count: int
```

automatically incrementing counter used as key when none is provided
starting value can be set in `defaults` and defaults to 1

## Method Descriptions

### \_init

```gdscript
func _init(node: Node, synchronize: bool = false, parameter_defaults) -> void
```

init for XScene
`node`: Node | determines `root`
`synchronize`: bool | default: false | wether to synchronize `scenes` with
external additions to the tree
`parameter_defaults`: Dictionary | default: `defaults`

### get\_active

```gdscript
func get_active() -> Array
```

### get\_hidden

```gdscript
func get_hidden() -> Array
```

### get\_stopped

```gdscript
func get_stopped() -> Array
```

### get\_scenes

```gdscript
func get_scenes() -> Dictionary
```

### x

```gdscript
func x(key) -> Node
```

"x"ess the scene of `key`
returns null, if the scene of `key` was already freed or is queued for deletion

### xs

```gdscript
func xs(method = null) -> Array
```

do multiple "x"ess"s", get Array of Nodes based on `method`
if null, return all scenes(nodes) from `scenes`
if method specified, return only the scenes(nodes) in the respective state
`method`: null / `ACTIVE` / `HIDDEN` / `STOPPED` | default: null

### add\_scene

```gdscript
func add_scene(new_scene, key, method, deferred, recursive_owner) -> var
```

add a scene to the tree below `root` and to `scenes`
`ACTIVE` uses `add_child()`
`HIDDEN` uses `add_child()` and `.hide()`
`STOPPED` only adds to `scenes` not to the tree
`scene`: Node / PackagedScene
`key`: `count` / String | default: `count` | key in `scenes`
`method`: `ACTIVE` / `HIDDEN` / `STOPPED` | default: `ACTIVE`
`deferred`: bool | default: false | whether to use call_deferred() for tree
changes
`recursive_owner`: bool | default: false | wether to recursively for all
children of `scene` set the owner to `root`, this is useful for `pack_root()`

### show\_scene

```gdscript
func show_scene(key, deferred) -> var
```

make `key` visible, and update `scenes`
it uses `_check_scene` to verify that the Node is still valid
if key is `HIDDEN` it uses `.show()`
if key is `STOPPED` it uses `add_child()` and `.show()`
`key` : int / String | default: `count` | key in `scenes`
`deferred` : bool | default: false | whether to use `call_deferred()` for tree
changes

### remove\_scene

```gdscript
func remove_scene(key, method, deferred) -> var
```

remove `key` from `root` (or hide it) and update `scenes`
it uses `_check_scene` to verify that the Node is still valid
`HIDDEN` uses `.hide()`
`STOPPED` uses `remove_child()`
`FREE` uses `.free()`
`key`: int / String | default: `count` | key in `scenes`
`method`: `HIDDEN` / `STOPPED` / `FREE` | default: `FREE`
`deferred`: bool | default: false | whether to use `call_deferred()` or
`queue_free()` for tree changes

### x\_scene

```gdscript
func x_scene(key_to, key_from = null, method_from, deferred) -> void
```

use `show_scene(key_to, deferred)`
and `remove_scene(key_from, method_from, deferred)`
`key_from`: int / String | default: null | use `remove_scene()` with this key,
if null, the last active scene will be used, mind that the order of `active`
only depends on the order of `scenes`
hiding/stopping and then showing scenes won't change the order
see `show_scene()` and `remove_scene()` for other parameters

### x\_add\_scene

```gdscript
func x_add_scene(scene_to, key_to, key_from = null, method_to, method_from, deferred, recursive_owner) -> void
```

use `add_scene(scene_to, key_to, method_to, deferred, recursive_owner)`
and `remove_scene(key_from, method_from, deferred)`
`key_to`: `count` / String | default: `count` | use `add_scene()` with this key
`key_from`: int / String | default: null | use `remove_scene()` with this key,
if null, the last active scene will be used, mind that the order of `active`
only depends on the order of `scenes`
hiding/stopping and then showing scenes won't change the order
see `add_scene()` and `remove_scene()` for other parameters

### add\_scenes

```gdscript
func add_scenes(new_scenes: Array, keys, method, deferred, recursive_owner) -> void
```

adds multiple scenes with `add_scene()`
`scenes` : Array<Node> / Array<PackedScene>
`keys` : count / Array<String> | default: count | if it isn't count the Array has to be the same size as `scenes`
see `add_scene()` for other parameters

### show\_scenes

```gdscript
func show_scenes(keys: Array, deferred) -> void
```

show multiple scenes with `show_scene()`
`keys` : Array<String and/or int>
see `show_scene()` for other parameters

### remove\_scenes

```gdscript
func remove_scenes(keys: Array, method, deferred) -> void
```

removes multiple scenes with `remove_scene()`
`keys` : Array<String and/or int>
see `remove_scene()` for other parameters

### pack\_root

```gdscript
func pack_root(filepath) -> void
```

pack `root` into `filepath` using `PackedScene.pack()`
this works together with the `recursive_owner` parameter of `add_scene()`
mind that the recursive_owner parameter is only necessary for scenes
constructed from script, a scene constructed in the editor already works

### debug

```gdscript
func debug() -> void
```

print debug information