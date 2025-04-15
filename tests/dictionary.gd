extends SceneTree


class Data:
	# Custom handling
	var nested: Data
	var array_variant: Array[Variant]
	var array_typed: Array[int]
	var array_nested: Array[Data]
	var dictionary_variant: Dictionary[String, Variant]
	var dictionary_typed: Dictionary[String, int]
	var dictionary_nested: Dictionary[String, Data]
	# JSON types
	var string: String
	var string_name: StringName
	@export var exported: String
	var boolean: bool
	var integer: int
	var floating_point: float
	# Godot types
	var vector2: Vector2
	var vector2i: Vector2i
	var vector3: Vector3
	var vector3i: Vector3i
	var vector4: Vector4
	var vector4i: Vector4i
	var rect2: Rect2
	var rect2i: Rect2i
	var transform2d: Transform2D
	var transform3d: Transform3D
	var basis: Basis
	var plane: Plane
	var quaternion: Quaternion
	var aabb: AABB
	var projection: Projection
	var color: Color
	var packed_byte_array: PackedByteArray
	var packed_int32_array: PackedInt32Array
	var packed_int64_array: PackedInt64Array
	var packed_float32_array: PackedFloat32Array
	var packed_float64_array: PackedFloat64Array
	var packed_string_array: PackedStringArray
	var packed_vector2_array: PackedVector2Array
	var packed_vector3_array: PackedVector3Array
	var packed_vector4_array: PackedVector4Array
	var packed_color_array: PackedColorArray


func _build_data(string: String) -> Data:
	var new_data := Data.new()
	new_data.string = string
	return new_data


# Tests
var data := Data.new()


func _init() -> void:
	# Register objects
	ObjectSerializer.register_script("Data", Data)

	# Build test data
	data.nested = _build_data("nested")
	data.array_variant = [1.0, "a", Vector2(1, 2)]
	data.array_typed = [1, 2]
	data.array_nested = [_build_data("array nested")]
	data.dictionary_variant = {"float": 1.0, "vector": Vector2(1, 2)}
	data.dictionary_typed = {"int": 1}
	data.dictionary_nested = {"data": _build_data("dictionary nested")}
	data.string = "a"
	data.string_name = "b"
	data.exported = "c"
	data.boolean = true
	data.integer = 1
	data.floating_point = 2.3
	data.vector2 = Vector2(1.2, 3.4)
	data.vector2i = Vector2i(1, 2)
	data.vector3 = Vector3(1.2, 3.4, 5.6)
	data.vector3i = Vector3(1, 2, 3)
	data.vector4 = Vector4(1.2, 3.4, 5.6, 7.8)
	data.vector4i = Vector4i(1, 2, 3, 4)
	data.rect2 = Rect2(1.2, 3.4, 5.6, 7.8)
	data.rect2i = Rect2(1, 2, 3, 4)
	data.transform2d = Transform2D(Vector2(1, 2), Vector2(3, 4), Vector2(5, 6))
	data.transform3d = Transform3D(
		Vector3(1, 2, 3), Vector3(4, 5, 6), Vector3(7, 8, 9), Vector3(10, 11, 12)
	)
	data.basis = Basis(Vector3(1, 2, 3), Vector3(4, 5, 6), Vector3(7, 8, 9))
	data.plane = Plane(Vector3(1, 2, 3), Vector3(4, 5, 6), Vector3(7, 8, 9))
	data.quaternion = Quaternion(Vector3(1, 2, 3).normalized(), 2)
	data.aabb = AABB(Vector3(1, 2, 3), Vector3(4, 5, 6))
	data.projection = Projection(
		Vector4(1, 2, 3, 4), Vector4(1, 2, 3, 4), Vector4(1, 2, 3, 4), Vector4(1, 2, 3, 4)
	)
	data.color = Color(0.1, 0.2, 0.3, 0.4)
	data.packed_byte_array = PackedByteArray([1, 2, 3])
	data.packed_int32_array = PackedInt32Array([1, 2, 3])
	data.packed_int64_array = PackedInt64Array([1, 2, 3])
	data.packed_float32_array = PackedFloat32Array([1.2, 2.3])
	data.packed_float64_array = PackedFloat64Array([1.2, 2.3])
	data.packed_string_array = PackedStringArray(["a", "b"])
	data.packed_vector2_array = PackedVector2Array([Vector2(1, 2), Vector2(3, 4)])
	data.packed_vector3_array = PackedVector3Array([Vector3(1, 2, 3), Vector3(4, 5, 6)])
	data.packed_vector4_array = PackedVector4Array([Vector4(1, 2, 3, 4), Vector4(5, 6, 7, 8)])
	data.packed_color_array = PackedColorArray(
		[Color(0.1, 0.2, 0.3, 0.4), Color(0.5, 0.6, 0.7, 0.8)]
	)

	# Serialize
	var serialized: Variant = DictionarySerializer.serialize_var(data)
	var json = JSON.stringify(serialized, "\t")
	print(json)
	assert(json == DictionarySerializer.serialize_json(data, "\t"))

	# Verify after JSON serialization
	var deserialized: Data = DictionarySerializer.deserialize_var(JSON.parse_string(json))
	_assert_data(deserialized)
	_assert_data(DictionarySerializer.deserialize_json(json))


func _assert_data(deserialized: Data) -> void:
	assert(data.nested.string == deserialized.nested.string, "nested different")
	assert(data.array_variant == deserialized.array_variant, "array_variant different")
	assert(data.array_typed == deserialized.array_typed, "array_typed different")
	assert(
		data.array_nested[0].string == deserialized.array_nested[0].string, "array_nested different"
	)
	assert(
		data.dictionary_variant == deserialized.dictionary_variant, "dictionary_variant different"
	)
	assert(data.dictionary_typed == deserialized.dictionary_typed, "dictionary_typed different")
	assert(
		data.dictionary_nested["data"].string == deserialized.dictionary_nested["data"].string,
		"dictionary nested different"
	)
	assert(data.string == deserialized.string, "string different")
	assert(data.string_name == deserialized.string_name, "string_name different")
	assert(data.exported == deserialized.exported, "exported different")
	assert(data.integer == deserialized.integer, "integer different")
	assert(data.floating_point == deserialized.floating_point, "floating_point different")
	assert(data.vector2 == deserialized.vector2, "vector2 different")
	assert(data.vector2i == deserialized.vector2i, "vector2i different")
	assert(data.vector3 == deserialized.vector3, "vector3 different")
	assert(data.vector3i == deserialized.vector3i, "vector3i different")
	assert(data.vector4 == deserialized.vector4, "vector4 different")
	assert(data.vector4i == deserialized.vector4i, "vector4i different")
	assert(data.rect2 == deserialized.rect2, "rect2 different")
	assert(data.rect2i == deserialized.rect2i, "rect2i different")
	assert(data.transform2d == deserialized.transform2d, "transform2d different")
	assert(data.transform3d == deserialized.transform3d, "transform3d different")
	assert(data.basis == deserialized.basis, "basis different")
	assert(data.plane == deserialized.plane, "plane different")
	assert(data.quaternion == deserialized.quaternion, "quaternion different")
	assert(data.aabb == deserialized.aabb, "aabb different")
	assert(data.projection == deserialized.projection, "projection different")
	assert(data.color == deserialized.color, "color different")
	assert(data.packed_byte_array == deserialized.packed_byte_array, "packed_byte_array different")
	assert(
		data.packed_int32_array == deserialized.packed_int32_array, "packed_int32_array  different"
	)
	assert(
		data.packed_int64_array == deserialized.packed_int64_array, "packed_int64_array different"
	)
	assert(
		data.packed_float32_array == deserialized.packed_float32_array,
		"packed_float32_array different"
	)
	assert(
		data.packed_float64_array == deserialized.packed_float64_array,
		"packed_float64_array different"
	)
	assert(
		data.packed_string_array == deserialized.packed_string_array,
		"packed_string_array different"
	)
	assert(
		data.packed_vector2_array == deserialized.packed_vector2_array,
		"packed_vector2_array different"
	)
	assert(
		data.packed_vector3_array == deserialized.packed_vector3_array,
		"packed_vector3_array different"
	)
	assert(
		data.packed_vector4_array == deserialized.packed_vector4_array,
		"packed_vector4_array different"
	)
	assert(
		data.packed_color_array == deserialized.packed_color_array, "packed_color_array different"
	)
