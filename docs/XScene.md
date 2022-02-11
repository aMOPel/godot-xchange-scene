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

enum with the scene state \
`ACTIVE` = 0 uses `add_child()` \
`HIDDEN` = 1 uses `.hide()` \
`STOPPED` = 2 uses `remove_child()` \
`FREE` = 3 uses `.free()`

### FREE

```gdscript
const ACTIVE: int = 0
```

enum with the scene state \
`ACTIVE` = 0 uses `add_child()` \
`HIDDEN` = 1 uses `.hide()` \
`STOPPED` = 2 uses `remove_child()` \
`FREE` = 3 uses `.free()`

### HIDDEN

```gdscript
const ACTIVE: int = 0
```

enum with the scene state \
`ACTIVE` = 0 uses `add_child()` \
`HIDDEN` = 1 uses `.hide()` \
`STOPPED` = 2 uses `remove_child()` \
`FREE` = 3 uses `.free()`

### STOPPED

```gdscript
const ACTIVE: int = 0
```

enum with the scene state \
`ACTIVE` = 0 uses `add_child()` \
`HIDDEN` = 1 uses `.hide()` \
`STOPPED` = 2 uses `remove_child()` \
`FREE` = 3 uses `.free()`

## Property Descriptions

### scenes

```gdscript
var scenes: Dictionary
```

Dictionary that holds all indexed scenes and their state \
has either `count` or String as keys \
Eg. {1:{scene:[Node2D:1235], state:0}, abra:{scene:[Node2D:1239], state:1}}

### active

```gdscript
var active: Array
```

Array of keys of active scenes

### hidden

```gdscript
var hidden: Array
```

Array of keys of hidden scenes

### stopped

```gdscript
var stopped: Array
```

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

wether to synchronize `scenes` with external additions to the tree \
__WARNING__ this can be slow, read the __Caveats__ Section in the README.md

### defaults

```gdscript
var defaults: Dictionary
```

Dictionary that hold the default values for parameters used in add/show/remove \
any invalid key or value assignment will throw an error to prevent misuse and cryptic errors \
you can assign partial dictionaries and it will override as expected, leaving the other keys alone \
eg `x.defaults = {deferred = true, method_add = 2}` \
`x.defaults = x._original_defaults` to reset
`deferred` = false, \
`recursive_owner` = false, \
`method_add` = ACTIVE, \
`method_remove` = FREE, \
`method_change` = ACTIVE, \
`count_start` = 1 | This is only applied when passing it to the `_init()` of XScene

### count

```gdscript
var count: int
```

automatically incrementing counter used as key when none is provided \
starting value can be set by passing `defaults` when initializing XScene \
defaults to 1

## Method Descriptions

### \_init

```gdscript
func _init(node: Node, synchronize: bool = false, parameter_defaults: Dictionary) -> void
```

init for XScene \
`node`: Node | determines `root` \
`synchronize`: bool | default: false | wether to synchronize `scenes` with \
external additions to the tree \
`parameter_defaults`: Dictionary | default: {} | this is the only way to change `count_start` \
you can also pass partial dictionaries \
eg `x = XScene.new($Node, false, {deferred = true, count_start = 0})`

### x

```gdscript
func x(key) -> Node
```

"x"ess the scene of `key` \
returns null, if the scene of `key` was already freed or is queued for deletion

### d

```gdscript
func d(key) -> Dictionary
```

returns the `data` Dictionary in of `key` in `scenes`
the `data` Dictionary is not used by this plugin, but can be used to associate data with a scene

### xs

```gdscript
func xs(method = null) -> Array
```

do multiple "x"ess"s", get Array of Nodes based on `method` \
if null, return all scenes(nodes) from `scenes` \
if method specified, return only the scenes(nodes) in the respective state \
`method`: null / `ACTIVE` / `HIDDEN` / `STOPPED` | default: null

### to\_node

```gdscript
func to_node(s) -> Node
```

uses PackedScene.instance() or Node.duplicate() on s

### parse\_args

```gdscript
func parse_args(args: Dictionary) -> Dictionary
```

sets undefined values to their respective values in `defaults`

### change\_scene

```gdscript
func change_scene(key, args: Dictionary) -> void
```

change state of `key` to any other state \
a wrapper around `show_scene()` and `remove_scene()` \
`args` takes `method_change` and `deferred` keys  \
these values default to their respective values in `defaults`

### add\_scene

```gdscript
func add_scene(new_scene, key, args: Dictionary) -> var
```

add a scene to the tree below `root` and to `scenes` \
`ACTIVE` uses `add_child()` \
`HIDDEN` uses `add_child()` and `.hide()` \
`STOPPED` only adds to `scenes` not to the tree \
`scene`: Node / PackagedScene \
`key`: `count` / String | default: `count` | key in `scenes` \
`args.method_add`: `ACTIVE` / `HIDDEN` / `STOPPED` | default: `ACTIVE` \
`args.deferred`: bool | default: false | whether to use call_deferred() for tree
changes \
`args.recursive_owner`: bool | default: false | wether to recursively for all
children of `scene` set the owner to `root`, this is useful for `pack_root()`

### show\_scene

```gdscript
func show_scene(key, args: Dictionary) -> var
```

make `key` visible, and update `scenes` \
it uses `_check_scene` to verify that the Node is still valid \
if key is `HIDDEN` it uses `.show()` \
if key is `STOPPED` it uses `add_child()` and `.show()` \
`key` : int / String | default: `count` | key in `scenes` \
`args.deferred` : bool | default: false | whether to use `call_deferred()` for tree
changes

### remove\_scene

```gdscript
func remove_scene(key, args: Dictionary) -> var
```

remove `key` from `root` (or hide it) and update `scenes` \
it uses `_check_scene` to verify that the Node is still valid \
`HIDDEN` uses `.hide()` \
`STOPPED` uses `remove_child()` \
`FREE` uses `.free()` \
`key`: int / String | default: `count` | key in `scenes` \
`args.method_remove`: `HIDDEN` / `STOPPED` / `FREE` | default: `FREE` \
`args.deferred`: bool | default: false | whether to use `call_deferred()` or
`queue_free()` for tree changes

### x\_scene

```gdscript
func x_scene(key_to, key_from = null, args: Dictionary) -> void
```

use `show_scene(key_to, args)`
and `remove_scene(key_from, args)` \
`key_from`: int / String | default: null | use `remove_scene()` with this key, \
if null, the last active scene will be used, mind that the order of `active`
only depends on the order of `scenes`
hiding/stopping and then showing scenes won't change the order \
see `show_scene()` and `remove_scene()` for other parameters

### x\_add\_scene

```gdscript
func x_add_scene(scene_to, key_to, key_from = null, args: Dictionary) -> void
```

use `add_scene(scene_to, key_to, args)`
and `remove_scene(key_from, args)`
`key_to`: `count` / String | default: `count` | use `add_scene()` with this key \
`key_from`: int / String | default: null | use `remove_scene()` with this key, \
if null, the last active scene will be used, mind that the order of `active`
only depends on the order of `scenes`
hiding/stopping and then showing scenes won't change the order \
see `add_scene()` and `remove_scene()` for other parameters

### swap\_scene

```gdscript
func swap_scene(key_to, key_from = null) -> void
```

swap the Dictionaries in `scenes` for these two keys \
`key_from`: int / String | default: null | use `remove_scene()` with this key, \
if null, the last active scene will be used, mind that the order of `active`
only depends on the order of `scenes`
hiding/stopping and then showing scenes won't change the order

### add\_scenes

```gdscript
func add_scenes(new_scenes: Array, keys, args: Dictionary) -> void
```

adds multiple scenes with `add_scene()` \
`scenes` : Array<Node or PackedScene> \
`keys` : count / Array<String> | default: count | if it isn't count the Array has to be the same size as `scenes` \
see `add_scene()` for other parameters

### show\_scenes

```gdscript
func show_scenes(keys: Array, args: Dictionary) -> void
```

show multiple scenes with `show_scene()` \
`keys` : Array<String and/or int> \
see `show_scene()` for other parameters

### remove\_scenes

```gdscript
func remove_scenes(keys: Array, args: Dictionary) -> void
```

removes multiple scenes with `remove_scene()` \
`keys` : Array<String and/or int> \
see `remove_scene()` for other parameters

### pack\_root

```gdscript
func pack_root(filepath) -> void
```

pack `root` into `filepath` using `PackedScene.pack()` and `ResourceSaver.save()` \
this works together with the `recursive_owner` parameter of `add_scene()` \
mind that the `recursive_owner` parameter is only necessary for scenes
constructed from script, a scene constructed in the editor already works

### debug

```gdscript
func debug() -> void
```

print debug information