extends SceneTree


class Data:
	var name: String

	func _init(init_name: String) -> void:
		name = init_name

	func _get_constructor_args() -> Array:
		return [name]


# Tests
func _init() -> void:
	# Register objects
	ObjectSerializer.register_script("Data", Data)

	# Build test data
	var data := Data.new("a")

	# Serialize
	var serialized: Variant = ObjectSerializer.dictionary.serialize_var(data)
	print(JSON.stringify(serialized, "\t"))

	# Verify after JSON serialization
	var deserialized: Data = ObjectSerializer.dictionary.deserialize_var(
		JSON.parse_string(JSON.stringify(serialized))
	)

	assert(data.name == deserialized.name, "name different")
