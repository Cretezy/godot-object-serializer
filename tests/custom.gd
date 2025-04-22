extends SceneTree

# Example of custom serializers


class Data:
	# No need to call `serialize`/`deserialize` for primitive
	var name: String
	# Must call `serialize`/`deserialize` for non-primitive
	var position: Vector2

	func _serialize(serialize: Callable) -> Dictionary:
		return {"key": name, "pos": serialize.call(position)}

	static func _deserialize(data: Dictionary, deserialize: Callable) -> Data:
		var instance = Data.new()
		instance.name = data["key"]
		instance.position = deserialize.call(data["pos"])
		return instance


# Tests
func _init() -> void:
	# Register objects
	ObjectSerializer.register_script("Data", Data)

	# Build test data
	var data := Data.new()
	data.name = "hello world"
	data.position = Vector2(1, 2)

	# Serialize
	var serialized: Variant = DictionarySerializer.serialize_var(data)
	print(JSON.stringify(serialized, "\t"))

	# Verify after JSON serialization
	var deserialized: Data = DictionarySerializer.deserialize_var(
		JSON.parse_string(JSON.stringify(serialized))
	)

	assert(data.name == deserialized.name, "name different")
	assert(data.position == deserialized.position, "position different")
