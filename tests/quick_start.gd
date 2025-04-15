extends SceneTree


# Example data class. Can extends any type, include Resource
class Data:
	# Supports all primitive types (String, int, float, bool, null), including @export-ed variables
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

var data := Data.new()


func _init() -> void:
	# Required: Register possible object scripts
	ObjectSerializer.register_script("Data", Data)
	ObjectSerializer.register_script("DataResource", DataResource)

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
            "._": [
                1.0,
                2.0,
                3.0
            ]
        },
        "enum_state": 1,
        "array": [
            1,
            2
        ],
        "dictionary": {
            "position": {
                "._type": "Vector2",
                "._": [
                        1.0,
                        2.0
                ]
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
