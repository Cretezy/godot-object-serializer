extends SceneTree


class DataJson:
	var string_dict: Dictionary[String, Variant]
	var int_dict: Dictionary[int, Variant]
	var float_dict: Dictionary[float, Variant]
	var bool_dict: Dictionary[bool, Variant]


class DataBinary:
	var vector2_dict: Dictionary[Vector2, Variant]


# Tests
func _init() -> void:
	# Register objects
	(
		ObjectSerializer
		. register_scripts(
			{
				"DataJson": DataJson,
				"DataBinary": DataBinary,
			}
		)
	)

	# Build test data
	var data_json := DataJson.new()
	data_json.string_dict = {"a": "b"}
	data_json.int_dict = {-1: "a", 0: "b", 1: "c"}
	data_json.float_dict = {1: "a", 2.3: "b"}
	data_json.bool_dict = {true: "a", false: "b"}
	var data_binary := DataBinary.new()
	data_binary.vector2_dict = {Vector2(1, 2): "a"}

	# JSON test
	var json = DictionarySerializer.serialize_json(data_json, "\t")
	var deserialized_json: DataJson = DictionarySerializer.deserialize_json(json)

	assert(deserialized_json.string_dict["a"] == "b", "string_dict different")
	assert(deserialized_json.int_dict[-1] == "a", "int_dict[-1] different")
	assert(deserialized_json.int_dict[0] == "b", "int_dict[0] different")
	assert(deserialized_json.int_dict[1] == "c", "int_dict[1] different")
	assert(deserialized_json.float_dict[1] == "a", "float_dict[1] different")
	assert(deserialized_json.float_dict[2.3] == "b", "float_dict[2.3] different")
	assert(deserialized_json.bool_dict[true] == "a", "bool_dict[true] different")
	assert(deserialized_json.bool_dict[false] == "b", "bool_dict[false] different")

	# Binary test
	var bytes = BinarySerializer.serialize_bytes(data_binary)
	var deserialized_bytes: DataBinary = BinarySerializer.deserialize_bytes(bytes)

	assert(deserialized_bytes.vector2_dict[Vector2(1, 2)] == "a", "vector2_dict different")
