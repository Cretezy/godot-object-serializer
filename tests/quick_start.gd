extends SceneTree


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
	var json := JSON.stringify(serialized, "\t")
	print(json)
	""" Output:
	{
        "._type": "Object_Data",
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
        "enum_state": 1,
        "nested": {
                "._type": "Object_DataResource",
                "name": "dolor sit amet"
        },
        "packed_byte_array": {
                "._type": "PackedByteArray_Base64",
                "_": "AQID"
        },
        "string": "Lorem ipsum"
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
