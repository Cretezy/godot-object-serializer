# <img src="https://raw.githubusercontent.com/Cretezy/godot-object-serializer/refs/heads/main/icon.png" height="24px"> Godot Object Serializer

**Safely** serialize/deserialize objects (and built-in Godot types) to **JSON or binary** in Godot. Enables registration of scripts/classes and conversion of values to/from JSON or bytes, without any risk of code execution. Perfect for save state systems or networking.

Godot's built-in serialization (such as `var_to_bytes`/`FileAccess.store_var`/`JSON.from_native`/`JSON.to_native`) cannot safely serialize objects (without using `full_objects`/`var_to_bytes_with_objects`, which allows code execution), but this library can!

**[View in Asset Library](https://godotengine.org/asset-library/asset/3940)**

**Features:**

- **Safety**: No remote code execution, can be used for untrusted data (e.g. save state system or networking).
- **Dictionary/binary mode**: Dictionary mode can be used for JSON serialization (`JSON.stringify`/`JSON.parse_string`), while binary mode can be used with binary serialization (`var_to_bytes`/`bytes_to_var`). Provides helpers to serialize directly to JSON/binary.
- **Objects**: Objects can be serialized, including enums, inner classes, and nested values. Supports class constructors and custom serializer/deserializer.
- **Built-in types**: Supports all built-in value types (Vector2/3/4/i, Rect2/i, Transform2D/3D, Quaternion, Color, Plane, Basis, AABB, Projection, Packed\*Array, etc).
- **Efficient JSON bytes**: When serializing to JSON, `PackedByteArray`s are efficiently serialized as base64, reducing the serialized byte count by ~40%
- **Non-string JSON dictionary keys**: Supports deserializing `int`/`float`/`bool` keys from JSON

## Quick Start

Start by [installing the plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html). You can install it from the [Asset Library](https://godotengine.org/asset-library/asset/3940) (search "Godot Object Serializer" in the "AssetLib" tab of the editor), or by manually placing the [`addons/godot_object_serializer`](./addons/godot_object_serializer/) directory in your project.

```gdscript
class Data:
	var name: String
	var position: Vector2


func _init() -> void:
	# Required: Register possible object scripts
	ObjectSerializer.register_script("Data", Data)

	# Setup data
	var data := Data.new()
	data.name = "hello world"
	data.position = Vector2(1, 2)

	var json = DictionarySerializer.serialize_json(data)
	""" Output:
	{
		"._type": "Object_Data",
		"name": "hello world",
		"position": {
			"._type": "Vector2",
			"._": [1.0, 2.0]
		}
	}
	"""

	data = DictionarySerializer.deserialize_json(json)
```

**Full example:**

```gdscript
# Example data class. Can extend any type, include Resource
class Data:
	# Supports all primitive types (String, int, float, bool, null), including @export variables
	@export var string: String
	# Supports all extended built-in types (Vector2/3/4/i, Rect2/i, Transform2D/3D, Color, Packed*Array, etc)
	var vector: Vector3
	# Supports enum
	var enum_state: State
	# Supports arrays, including Array[Variant]
	var array: Array[int]
	# Supports dictionaries, including Dictionary[Variant, Variant]
	var dictionary: Dictionary[String, Vector2]
	# Supports efficient byte array serialization to base64
	var packed_byte_array: PackedByteArray
	# Supports nested data, either as a field or in array/dictionary
	var nested: DataResource

class DataResource:
	extends Resource
	var name: String

enum State { OPENED, CLOSED }


# _static_init is used to register scripts without having to instanciate the script.
# It's recommended to either place all registrations in a single script, or have each script register itself.
static func _static_init() -> void:
	# Required: Register possible object scripts
	ObjectSerializer.register_script("Data", Data)
	ObjectSerializer.register_script("DataResource", DataResource)


# Setup testing data
var data := Data.new()
func _init() -> void:
	data.string = "Lorem ipsum"
	data.vector = Vector3(1, 2, 3)
	data.enum_state = State.CLOSED
	data.array = [1, 2]
	data.dictionary = {"position": Vector2(1, 2)}
	data.packed_byte_array = PackedByteArray([1, 2, 3, 4, 5, 6, 7, 8])
	var data_resource := DataResource.new()
	data_resource.name = "dolor sit amet"
	data.nested = data_resource

	json_serialization()
	binary_serialization()


func json_serialization() -> void:
	# Serialize to JSON
	# Alternative: DictionarySerializer.serialize_json(data)
	var serialized: Variant = DictionarySerializer.serialize_var(data)
	var json := JSON.stringify(serialized, "\t")
	print(json)
	""" Output:
	{
		"._type": "Object_Data",
		"string": "Lorem ipsum",
		"vector": {
			"._type": "Vector3",
			"._": [1.0, 2.0, 3.0]
		},
		"enum_state": 1,
		"array": [1, 2],
		"dictionary": {
			"position": {
				"._type": "Vector2",
				"._": [1.0, 2.0]
			}
		},
		"packed_byte_array": {
			"._type": "PackedByteArray_Base64",
			"._": "AQIDBAUGBwg="
		},
		"nested": {
			"._type": "Object_DataResource",
			"name": "dolor sit amet"
		}
	}
	"""

	# Verify after JSON deserialization
	# Alternative: DictionarySerializer.deserialize_json(json)
	var parsed_json = JSON.parse_string(json)
	var deserialized: Data = DictionarySerializer.deserialize_var(parsed_json)
	_assert_data(deserialized)


func binary_serialization() -> void:
	# Serialize to bytes
	# Alternative: BinarySerializer.serialize_bytes(data)
	var serialized: Variant = BinarySerializer.serialize_var(data)
	var bytes := var_to_bytes(serialized)
	print(bytes)
	# Output: List of bytes

	# Verify after bytes deserialization.
	# Alternative: BinarySerializer.deserialize_bytes(bytes)
	var parsed_bytes = bytes_to_var(bytes)
	var deserialized: Data = BinarySerializer.deserialize_var(parsed_bytes)
	_assert_data(deserialized)


func _assert_data(deserialized: Data) -> void:
	assert(data.string == deserialized.string, "string is different")
	assert(data.vector == deserialized.vector, "vector is different")
	assert(data.enum_state == deserialized.enum_state, "enum_state is different")
	assert(data.array == deserialized.array, "array is different")
	assert(data.dictionary == deserialized.dictionary, "dictionary is different")
	assert(
		data.packed_byte_array == deserialized.packed_byte_array, "packed_byte_array is different"
	)
	assert(data.nested.name == deserialized.nested.name, "nested.name is different")
```

## Dictionary vs Binary Mode

This library provides 2 modes to make values serializable: dictionary/JSON and binary/bytes mode.

Both modes handle primitives (String, bool, int, float, null) the same, as well as objects (serializing into a dictionary containing a `._type` field).

The difference between the 2 modes is how it handles extended built-in types (Vector2, Vector3, Transform3D, Color, etc):

- In dictionary mode (which is targeted to be used with `JSON.stringify`), these are serialized as dictionaries containing a `._type` field and converted using `JSON.from_native`/`JSON.to_native`.
- In binary mode (which is targeted to be used with `var_to_bytes`), these are left as-is, as `var_to_bytes` natively supports these types.

This allows you to choose your preferred output format while ensuring efficient serialization. This library also provides helper functions to serialize directly to JSON or bytes.

## Why Not Built-In Alternatives?

There's multiple ways to serialize data in Godot, with only some of them safe (safe meaning no code execution from the deserialization).

### `JSON.stringify`

JSON serialization works great for data that can be represented as JSON (string, numbers, arrays, dictionary, booleans, null). This means that objects or other built-in types (e.g. Vector2) cannot be represented.

To use `JSON.stringify`, the traditional way is to manually convert data to a JSON-compatible format before serialization (see example).

<details>
<summary>Example</summary>

```gdscript
class JsonData:
	var string: String
	var vector2: Vector2

	func to_dict() -> Dictionary:
		return {
			"string": string,
			"vector2": [vector2.x, vector2.y]
		}
	static func from_dict(data: Dictionary) -> JsonData:
		var result := JsonData.new()
		result.string = data["string"]
		result.vector2 = Vector2(data["vector2"][0], data["vector2"][1])
		return result

func _init():
	var data = JsonData.new()
	data.string = "hello world"
	data.vector2 = Vector2(1, 2)
	print(JSON.stringify(data.to_dict(), "\t"))
	""" Output:
	{
		"string": "hello world",
		"vector2": [1.0, 2.0]
	}
	"""
```

</details>

This is flexible but very tedious as every object type must be manually serialized and deserialized.

### `JSON.from_native`

Godot has a built-in way to serialize more types such as Vector2, Vector3, Transform3D, etc, to a JSON representation.

By default, this does not support serializing objects, unless `full_objects` is true (second argument in `JSON.from_native(object, true)`). **This is unsafe** (can cause remote code execution) and `full_objects` should never be used with untrusted data.

Additionally, using `JSON.from_native` combined with a `to_dict` produces inefficient packing (see example).

<details>
<summary>Example</summary>

```gdscript
class JsonNativeData:
	var string: String
	var vector2: Vector2

	func to_dict() -> Dictionary:
		return {
			"string": string,
			"vector2": vector2
		}
	static func from_dict(data: Dictionary) -> JsonNativeData:
		var result := JsonNativeData.new()
		result.string = data["string"]
		result.vector2 = data["vector2"]
		return result

func _init():
	var data = JsonNativeData.new()
	data.string = "hello world"
	data.vector2 = Vector2(1, 2)
	print(JSON.stringify(JSON.from_native(data.to_dict()), "\t"))
	""" Output:
	{
		"type": "Dictionary",
		"args": [
			"s:string",
			"s:hello world",
			"s:vector2",
			{
				"type": "Vector2",
				"args": [1.0, 2.0],
			}
		]
	}
	"""
```

</details>

### `var_to_bytes` / `bytes_to_var`

Godot has a built-in way to serialize more types such as Vector2, Vector3, Transform3D, etc, to bytes.

By default, this does not support serializing objects, unless `var_to_bytes_with_objects`/`bytes_to_var_with_objects` is used. **This is unsafe** (can cause remote code execution) and `*_with_objects` should never be used with untrusted data.

Additionally, using `var_to_bytes` combined with a `to_dict` produces inefficient packing (similar to the `JSON.from_native` example above).

## Registering Scripts

Registering scripts is required for the library to know how to serialize and deserialize your objects. You can do so in 2 ways:

```gdscript
ObjectSerializer.register_script("Data", Data)

# Or, if you have multiple
ObjectSerializer.register_scripts({
	"Data": Data,
	"DataResource": DataResource,
})
```

Registration is required to have a stable mapping of class name to script. This enables changing the name of the class without breaking previously serialized data. Additionally, this serves as a security measure as only known classes will be deserialized.

## Object Serialization

During serialization, all fields are serialized. This can be overridden by implementing [`_get_property_list()`](https://docs.godotengine.org/en/stable/classes/class_object.html#class-object-private-method-get-property-list) (only properties with `PROPERTY_USAGE_SCRIPT_VARIABLE` are serialized) or [`_get_excluded_properties()`](#excluded-properties) (see below).

During deserialization, all fields are set back on the object.

### Constructors

If your class has a constructor, you must implement `_get_constructor_args(): Array` to return the arguments for your constructor:

```gdscript
class Data:
	var name: String

	func _init(init_name: String) -> void:
		name = init_name

	func _get_constructor_args() -> Array:
		return [name]
```

> Properties in the constructor will also be included as fields in the serialized data. You can [exclude](#excluded-properties) these (see below) to avoid duplication.

[View full example](./tests/constructor.gd)

### Excluded Properties

You can exclude properties from serialization by implementing `_get_excluded_properties(): Array[String]`:

```gdscript
class Data:
	var name: String
	var position: Vector2

	func _get_excluded_properties() -> Array[String]:
		# name won't be serialized/deserialized, but position will
		return ["name"]
```

[View full example](./tests/excluded_properties.gd)

### Custom Object Serializer

Classes can implement `_serializer(serialize: Callable) -> Dictionary` and `static _deserialize(data: Dictionary, deserialize: Callable) -> Variant` to customize the serialization.

Note that the type field (by default `._type`) will automatically be added after your custom serializer, and the field will be present in the deserializer's `data`. Having a custom serializer/deserializer skips constructor handling.

Use the provided `serialize`/`deserialize` Callables for nested data. This is necessary only for non-primitive types.

```gdscript
class Data:
	# No need to call `serialize`/`deserialize` for primitive
	var name: String
	# Must call `serialize`/`deserialize` for non-primitive
	var position: Vector2

	func _serialize(serialize: Callable) -> Dictionary:
		return {
			"key": name,
			"pos": serialize.call(position)
		}

	static func _deserialize(data: Dictionary, deserialize: Callable) -> Data:
		var instance = Data.new()
		instance.name = data["key"]
		instance.position = deserialize.call(data["pos"])
		return instance
```

<details>
<summary>Example output</summary>

```json
{
	"._type": "Object_Data",
	"key": "hello world",
	"pos": {
		"._type": "Vector2",
		"._": [1.0, 2.0]
	}
}
```

[View full example](./tests/custom.gd)

</details>

### Partial Custom Object Serializer

In some cases, only some fields of the class requires custom a serializer, while the rest of the fields can use the normal serialization logic. This is the case when trying to serialize one of the built-in non-value types (such as `Texture`, `BitMap`, etc).

In those cases, classes can implement `_serializer_partial(serialize: Callable) -> Dictionary` and `_deserialize_partial(data: Dictionary, deserialize: Callable) -> Dictionary` to customize the serialization. The fields returned by this will be added to the serialized/deserialized result, and will be excluded normal serialization (all other fields will be included).

It's generally recommended to prefer `_serialize_partial`/`_deserialize_partial` over `_serialize`/`_deserialize` if you only need some fields have custom serialization logic.

Use the provided `serialize`/`deserialize` Callables for nested data. This is necessary only for non-primitive types (same as `_serialize`/`_deserialize`).

```gdscript
class Data:
	# Will be serialized normally
	var name: String
	# BitMap is not a built-in value type, needs to be handled with custom serializer
	var bitmap: BitMap

	func _serialize_partial(serialize: Callable) -> Dictionary:
		return {"bitmap": _serialize_bitmap(bitmap, serialize)}

	func _deserialize_partial(data: Dictionary, deserialize: Callable) -> Dictionary:
		return {"bitmap": _deserialize_bitmap(data["bitmap"], deserialize)}
```

<details>
<summary>Example BitMap serialization functions</summary>

```gdscript
func _serialize_bitmap(bitmap: BitMap, _serialize: Callable) -> Array[Array]:
	var size := bitmap.get_size()
	var rows: Array[Array] = []
	for x in range(size.x):
		var column = []
		for y in range(size.y):
			column.append(bitmap.get_bit(x, y))

		rows.append(column)

	return rows

func _deserialize_bitmap(data: Variant, _serialize: Callable) -> BitMap:
	var bitmap := BitMap.new()
	bitmap.create(Vector2i(data.size(), data[0].size()))
	for row in range(data.size()):
		for column in range(data[row].size()):
			bitmap.set_bit(row, column, data[row][column])

	return bitmap
```

</details>

<details>
<summary>Example output</summary>

```json
{
	"._type": "Object_Data",
	"bitmap": [
		[true, false, true],
		[true, false, false]
	],
	"name": "hello world"
}
```

</details>

[View full example](./tests/custom_partial.gd)

## Glossary

- "Objects" are instances of [objects](https://docs.godotengine.org/en/stable/classes/class_object.html).
- "Scripts" refer to [scripts](https://docs.godotengine.org/en/stable/classes/class_script.html), which can be GDScript or C#.
- "Classes" refer to the classes inside of scripts. Every GDScript is a class, and can include inner class

```gdscript
# This file is the "Data" class. Extends Object by default
class_name Data

# This is an inner class which extends Resource
class DataResource:
	extends Resource

# This is an object
var data := Data.new()
```

## API

### `ObjectSerializer.register_script(name: StringName, script: Script) -> void`

Registers a script (an object type) to be serialized/deserialized. All custom types (including nested types) must be registered **before** using this library.

Name can be empty if script uses `class_name` (e.g `ObjectSerializer.register_script("", Data)`), but it's generally better to set the name.

### `ObjectSerializer.register_scripts(scripts: Dictionary[String, Script]) -> void`

Registers multiple scripts (object types) to be serialized/deserialized from a dictionary.

See `ObjectSerializer.register_script`.

### `DictionarySerializer.serialize_var(data: Variant) -> Variant`

Serialize `data` into value which can be passed to `JSON.stringify`.

### `DictionarySerializer.serialize_json(value: Variant, indent := "", sort_keys := true, full_precision := false) -> Variant`

Serialize `data` into JSON string with `DictionarySerializer.serialize_var` and `JSON.stringify`. Supports same arguments as `JSON.stringify`

### `DictionarySerializer.deserialize_var(data: Variant) -> Variant`

Deserialize `data` from `JSON.parse_string` into value.

### `DictionarySerializer.deserialize_json(data: String) -> Variant`

Deserialize JSON string `data` to value with `JSON.parse_string` and `DictionarySerializer.deserialize_var`.

### `BinarySerializer.serialize_var(data: Variant) -> Variant`

Serialize `data` to value which can be passed to `var_to_bytes`.

### `BinarySerializer.serialize_bytes(data: Variant) -> PackedByteArray`

Serialize `data` into bytes with `BinarySerializer.serialize_var` and `var_to_bytes`.

### `BinarySerializer.deserialize_var(data: Variant) -> Variant`

Deserialize `data` from `bytes_to_var` to value.

### `BinarySerializer.deserialize_bytes(data: PackedByteArray) -> Variant`

Deserialize bytes `data` to value with `bytes_to_var` and `BinarySerializer.deserialize_var`.

### Settings

It's not recommended to change these options, but they are available. Any changes to options must be done before serialization/deserialization.

#### `ObjectSerializer.require_export_storage: bool` (default: `false`)

By default, variables with `PROPERTY_USAGE_SCRIPT_VARIABLE` are serialized (all variables have this by default).
When `require_export_storage` is true, variables will also require `PROPERTY_USAGE_STORAGE` to be serialized.
This can be set on variables using `@export_storage`. Example: `@export_storage var name: String`

[View full example](./tests/export_storage.gd)

#### `ObjectSerializer.type_field: String` (default: `._type`)

The field containing the type in serialized object values. Not recommended to change.
This should be set to something unlikely to clash with keys in objects/dictionaries.
This can be changed, but must be configured before any serialization or deserialization.

#### `ObjectSerializer.args_field: String` (default: `._`)

The field containing the constructor arguments in serialized object values. Not recommended to change.
This should be set to something unlikely to clash with keys in objects.
This can be changed, but must be configured before any serialization or deserialization.

#### `ObjectSerializer.object_type_prefix: String` (default: `Object_`)

The prefix for object types stored in `ObjectSerializer.type_field`. Not recommended to change.
This should be set to something unlikely to clash with built-in type names.
This can be changed, but must be configured before any serialization or deserialization.

#### `DictionarySerializer.bytes_as_base64: bool` (default: `true`)

Controls if PackedByteArray should be serialized as base64 (instead of array of bytes as uint8)
It's highly recommended to leave this enabled as it will result to smaller serialized payloads and should be faster.
This can be changed, but must be configured before any serialization or deserialization.

#### `DictionarySerializer.bytes_to_base64_type: String` (default: `PackedByteArray_Base64`)

The type of the object for PackedByteArray when `DictionarySerializer.bytes_as_base64` is enabled.
This should be set to something unlikely to clash with built-in type names or `ObjectSerializer.object_type_prefix`.
This can be changed, but must be configured before any serialization or deserialization.

### Unsupported Types

- Callable/signal (will be empty)
- When using JSON, dictionaries without primitive (`String`/`int`/`float`/`bool`) keys (see below)

And classes/scripts that are not registered with `ObjectSerializer.register_script`.

## Edge Cases

### JSON dictionary key type conversion

Since JSON only supports strings as key, only `Dictionary[String, Variant]` can natively be parsed by `JSON.parse_string`. This library adds support for `int`/`float`/`bool` keys in dictionaries if typed. All types are supported as keys when using binary serialization.

```gdscript
class Data:
	# Supported natively by JSON
	var string_dict: Dictionary[String, Variant]
	# Supported by library
	var int_dict: Dictionary[int, Variant]
	var float_dict: Dictionary[float, Variant]
	var bool_dict: Dictionary[bool, Variant]
	# Unsupported with JSON, works with binary
	var vector_dict: Dictionary[Vector2, Variant]
```

### JSON integer to float conversion for Variants

When using JSON serialization in Godot, integer values are converted to floats if they are typed as `Variant`. This doesn't apply to typed fields or when using binary serialization.

```gdscript
class Data:
	var value_variant: Variant
	var array_variant: Array[Variant]
	var dictionary_variant: Dictionary[String, Variant]

	var value_typed: int
	var array_typed: Array[int]
	var dictionary_typed: Dictionary[String, int]


var data = Data.new()
data.value_variant = 1
data.array_variant = [1]
data.dictionary_variant.value = 1
data.value_typed = 1
data.array_typed = [1]
data.dictionary_typed.value = 1


# Serialize/deserialize through JSON
data = DictionarySerializer.deserialize_json(
	DictionarySerializer.serialize_json(data)
)


# Integers in variant become floats
assert(data.value_variant == 1.0)
assert(data.array_variant == [1.0])
assert(data.dictionary_variant.value == 1.0)
# Typed fields will be of the correct type
assert(data.value_typed == 1)
assert(data.array_typed == [1])
assert(data.dictionary_typed.value == 1)
```

## Development

You can run test scripts located in the `tests` directory for development. Example: `godot --headless --quit -s tests/dictionary.gd`
