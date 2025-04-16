extends SceneTree


class Data:
	var name: String
	var position: Vector2

	func _get_excluded_properties() -> Array[String]:
		return ["name"]


# Tests
func _init() -> void:
	# Register objects
	ObjectSerializer.register_script("Data", Data)

	# Build test data
	var data := Data.new()
	data.name = "a"
	data.position = Vector2(1, 2)

	# Serialize
	var serialized: Variant = DictionarySerializer.serialize_var(data)
	print(JSON.stringify(serialized, "\t"))

	# Verify after JSON serialization
	var deserialized: Data = DictionarySerializer.deserialize_var(
		JSON.parse_string(JSON.stringify(serialized))
	)

	assert(deserialized.name == "", "name not excluded")

	# Verify it doesn't deserialize
	serialized.name = "b"
	print(JSON.stringify(serialized, "\t"))
	deserialized = DictionarySerializer.deserialize_var(
		JSON.parse_string(JSON.stringify(serialized))
	)

	assert(deserialized.name == "", "name not excluded")
