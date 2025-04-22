extends SceneTree

# Example of custom partial serializers


class Data:
	# Automatically serialized
	var position: Vector2
	# Requires manually serializiation
	var bitmap: BitMap

	func _serialize_partial(serialize: Callable) -> Dictionary:
		return {"bitmap": _serialize_bitmap(bitmap, serialize)}

	func _deserialize_partial(data: Dictionary, deserialize: Callable) -> Dictionary:
		return {"bitmap": _deserialize_bitmap(data["bitmap"], deserialize)}

	static func _serialize_bitmap(bitmap: BitMap, _serialize: Callable) -> Array[Array]:
		var size := bitmap.get_size()
		var rows: Array[Array] = []
		for x in range(size.x):
			var column = []
			for y in range(size.y):
				column.append(bitmap.get_bit(x, y))

			rows.append(column)

		return rows

	static func _deserialize_bitmap(data: Variant, _serialize: Callable) -> BitMap:
		var bitmap := BitMap.new()
		bitmap.create(Vector2i(data.size(), data[0].size()))
		for row in range(data.size()):
			for column in range(data[row].size()):
				bitmap.set_bit(row, column, data[row][column])

		return bitmap


# Tests
func _init() -> void:
	# Register objects
	ObjectSerializer.register_script("Data", Data)

	# Build test data
	var data := Data.new()
	data.position = Vector2(1, 2)
	var bitmap := BitMap.new()
	bitmap.create(Vector2i(2, 3))
	bitmap.set_bit(0, 0, true)
	bitmap.set_bit(1, 0, true)
	bitmap.set_bit(0, 2, true)
	data.bitmap = bitmap

	# Serialize
	var serialized: Variant = DictionarySerializer.serialize_var(data)
	print(JSON.stringify(serialized, "\t"))

	# Verify after JSON serialization
	var deserialized: Data = DictionarySerializer.deserialize_var(
		JSON.parse_string(JSON.stringify(serialized))
	)

	assert(data.position == deserialized.position, "position different")
	var size := bitmap.get_size()
	for x in range(size.x):
		for y in range(size.y):
			assert(
				data.bitmap.get_bit(x, y) == deserialized.bitmap.get_bit(x, y),
				"bitmap[%s,%s] different" % [x, y]
			)
