# Godot Object Serializer

**Safely** serialize objects (and built-in Godot types) to dictionaries for JSON and binary serialization.

Features:

- **Safety**: No remote code execution, can be used for untrusted data
- **Dictionary/binary mode**: Dictionary mode can be used with `JSON.stringify`/`JSON.parse_string`, while binary mode can be used with `var_to_bytes``/`bytes_to_var`
- **Objects**: Objects can be serialized, including inner classes and enum values
- **Built-in types**: All built-in types (Vector2, Color, PackedInt32Array, etc) are serialized
- **Efficient bytes**: When using dictionary mode, `PackedByteArray` is efficient serialized as base64

> NOTE: This library is not yet stable! The current API is unlikely to change, but object serialization will change with more features (constructor support, field filters, and more)

## Quick Start

Start by [installing the plugin](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html).

Note: Will be added to Asset Library once stable.

```gdscript
# Example data class. Can extends any type, include Resource
class Data:
	# Supports all built-in types (String, int, float, etc)
	var string: String
	# Supports enum
	var enum_state: State
	# Supports arrays, including Array[Variant]
	var array: Array[int]
	# Supports dictionaries, including Dictionary[Variant, Variant]
	# Supports all extended built-in types (Vector2, Color, PackedInt32Array, etc)
	var dictionary: Dictionary[String, Vector2]
	# Supports efficient byte array serialization to base64
	var packed_byte_array: PackedByteArray
	# Supports nested data, either as a field or in array/dictionary
	var nested: DataResource

class DataResource extends Resource:
	var name: String

enum State { OPENED, CLOSED }


var data := Data.new()

func _init() -> void:
	# Register possible object scripts
	ObjectSerializer.register_script("Data", Data)
	ObjectSerializer.register_script("DataResource", DataResource)

	data.string = "Lorem ipsum"
	data.enum_state = State.CLOSED
	data.array = [1, 2]
	data.dictionary = { "position": Vector2(1, 2) }
	data.packed_byte_array = PackedByteArray([1, 2, 3])
	var data_resource := DataResource.new()
	data_resource.name = "dolor sit amet"
	data.nested = data_resource

	json_serialization()
	binary_serialization()


func json_serialization() -> void:
	# Serialize to JSON
	var serialized: Variant = ObjectSerializer.dictionary.serialize(data)
	var json := JSON.stringify(serialized, "  ")
	print(json)
	""" Output:
  	{
    	"._type": "Object_Data",
    	"string": "Lorem ipsum",
    	"array": [
      	1,
      	2
    	],
    	"dictionary": {
      	"position": {
        	"._type": "Vector2",
        	"_": [
          	1.0,
          	2.0
        	]
      	}
    	},
    	"packed_byte_array": {
      	"._type": "PackedByteArray_Base64",
      	"_": "AQID"
    	},
    	"nested": {
      	"._type": "Object_DataResource",
      	"name": "dolor sit amet"
    	}
  	}
	"""

	# Verify after JSON deserialization
	var parsed_json = JSON.parse_string(json)
	var deserialized: Data = ObjectSerializer.dictionary.deserialize(parsed_json)
	_assert_data(deserialized)


func binary_serialization() -> void:
	# Serialize to bytes
	var serialized: Variant = ObjectSerializer.binary.serialize(data)
	var bytes := var_to_bytes(serialized)
	print(bytes)
	# Output: List of bytes

	# Verify after bytes deserialization
	var parsed_bytes = bytes_to_var(bytes)
	var deserialized: Data = ObjectSerializer.binary.deserialize(parsed_bytes)
	_assert_data(deserialized)

func _assert_data(deserialized: Data) -> void:
	assert(data.string == deserialized.string, "string is different")
	assert(data.enum_state == deserialized.enum_state, "enum_state is different")
	assert(data.array == deserialized.array, "array is different")
	assert(data.dictionary == deserialized.dictionary, "dictionary is different")
	assert(data.packed_byte_array == deserialized.packed_byte_array, "packed_byte_array is different")
	assert(data.nested.name == deserialized.nested.name, "nested.name is different")
```

## Dictionary vs Binary Mode

This library focuses on serializing objects and built-in types. Therfore, this library does not serialize to JSON/binary/etc on it's own.

Instead, it provides 2 modes to turn make values serializable: dictionary and binary mode.

Both modes handle primitives (String, bool, int, float, null) the same, as well as objects (serializes objects into dictionary with `._type` field).

The difference between the 2 modes is how it handles extended built-in types (Vector2, Vector3, Transform3D, Color, etc):

- In dictionary mode (which is targeted to be used with `JSON.stringify`), these are serialized as dictionaries with `._type` field and converted using `JSON.from_native`/`JSON.to_native`.
- In binary mode (which is targeted to be used with `var_to_bytes`), these are left as-is, since `var_to_bytes` natively supports these types.

## Why Not Built-In Alternatives?

There's multiple ways to serialize data in Godot, with only some of them safe (safe meaning no code execution from the deserialization).

### `JSON.stringify`

JSON serialization works great for data that can be represented as JSON (string, numbers, arrays, dictionary, booleans, null). This means that objects or other built-in types (e.g. Vector2) cannot be represented.

To use `JSON.stringify`, the traditional way is to manually serialize to a JSON-representable data before serialization:

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
    result.vector2 = Vector2(data["vector2"][0], data["vector2"][0])
    return result
```

This is very flexible but very tedious as every object type must be manually serialized.

### `JSON.from_native`

Godot has a built-in way to serialize more types such as Vector2, Vector3, Transform3D, etc, to a JSON represenation.

By default, this does not support serializing objects, unless `full_objects` is true (second argument in `JSON.from_native(object, true)`). **This is unsafe** (can cause remote code execution) and `full_objects` should never be used with untrusted data.

### `var_to_bytes` / `bytes_to_var`

Godot has a built-in way to serialize more types such as Vector2, Vector3, Transform3D, etc, to binary.

By default, this does not support serializing objects, unless `var_to_bytes_with_objects`/`bytes_to_var_with_objects` is used. **This is unsafe** (can cause remote code execution) and `*_with_objects` should never be used with untrusted data.

## How does it work?

TODO

## API

### `ObjectSerializer.register_script(name: StringName, script: Script) -> void`

Registers a script (a object type) to be serialized/deserialized.

### `ObjectSerializer.dictionary.serialize(data: Variant) -> Variant`

Serialize `data` into dictionary which can be passed to `JSON.stringify`.

### `ObjectSerializer.dictionary.deserialize(data: Variant) -> Variant`

Deserialize dictionary `data` from `JSON.parse_string` into objects.

### `ObjectSerializer.binary.serialize(data: Variant) -> Variant`

Serialize `data` into dictionary which can be passed to `var_to_bytes`.

### `ObjectSerializer.binary.deserialize(data: Variant) -> Variant`

Deserialize dictionary `data` from `bytes_to_var` into objects.

### Settings

It's not recommended to change these options, but they are available.

#### `ObjectSerializer.type_field: String` (default: `._type`)

The field containing the type in serialized object values. Not recommended to change.
This should be set to something unlikely to clash with keys in objects/dictionaries.
Can be changed but must be done before any serialization/deserizalization.

#### `ObjectSerializer.object_type_prefix: String` (default: `Object_`)

The prefix for object types stored in `ObjectSerializer.type_field`. Not recommended to change.
This should be set to something unlikely to clash with built-in type names.
Can be changed but must be done before any serialization/deserizalization.

#### `ObjectSerializer.dictionary.bytes_as_base64: bool` (default: `true`)

Controls if PackedByteArray should be serialized as base64 (instead of array of bytes as uint8)
It's highly recommended to leave this enabled as it will result to smaller serialized payloads and should be faster.
Can be changed but must be done before any serialization/deserizalization.

#### `ObjectSerializer.dictionary.bytes_to_base64_type: String` (default: `PackedByteArray_Base64`)

The type of the object for PackedByteArray when `ObjectSerializer.dictionary.bytes_as_base64` is enabled.
This should be set to something unlikely to clash with built-in type names or `ObjectSerializer.object_type_prefix`.
Can be changed but must be done before any serialization/deserizalization.

## Edge Cases

### JSON integer to float conversion for Variants

Godot's JSON serialization converts ints to floats when it's typed as `Variant`. This doesn't apply to typed fields or when using binary serialization.

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
data = ObjectSerializer.dictionary.deserialize(
  JSON.parse_string(JSON.stringify(
    ObjectSerializer.dictionary.serialize(data)
  ))
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

There's test scripts inside the `tests` directory which can be ran using: `godot --headless --quit -s tests/quick_start.gd`
