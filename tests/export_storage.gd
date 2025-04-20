extends SceneTree


class Data:
	var a: String
	@export_storage var b: String


# Tests
func _init() -> void:
	ObjectSerializer.require_export_storage = true
	# Register objects
	ObjectSerializer.register_script("Data", Data)

	# Build test data
	var data := Data.new()
	data.a = "a"
	data.b = "b"

	# Serialize
	var serialized: Variant = DictionarySerializer.serialize_var(data)
	print(JSON.stringify(serialized, "\t"))

	# Verify after JSON serialization
	var deserialized: Data = DictionarySerializer.deserialize_var(
		JSON.parse_string(JSON.stringify(serialized))
	)

	assert(deserialized.a == "", "a different")
	assert(deserialized.b == "b", "b different")
