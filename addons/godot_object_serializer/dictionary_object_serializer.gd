## Serializer to be used with dictionary/JSON serialization.
## This serializes objects and built-in Godot types.
class_name DictionaryObjectSerializer

## Controls if PackedByteArray should be serialized as base64 (instead of array of bytes as uint8)
## It's highly recommended to leave this enabled as it will result to smaller serialized payloads and should be faster.
## Can be changed but must be done before any serialization/deserizalization.
static var bytes_as_base64 := true
## The type of the object for PackedByteArray when [bytes_as_base64] is enabled.
## This should be set to something unlikely to clash with built-in type names or [ObjectSerializer.object_type_prefix].
## Can be changed but must be done before any serialization/deserizalization.
static var bytes_to_base64_type = "PackedByteArray_Base64"

# Types that can natively be represented in JSON
const _JSON_SERIALIZABLE_TYPES = [
	TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_STRING_NAME
]


## Serialize [data] into dictionary which can be passed to [JSON.stringify].
static func serialize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_OBJECT:
			var name: StringName = value.get_script().get_global_name()
			var object_entry := ObjectSerializer._get_entry(name, value.get_script())
			if !object_entry:
				assert(
					false,
					(
						"Could not find type (%s) in registry\n%s"
						% [name if name else "no name", value.get_script().source_code]
					)
				)

			return object_entry.serialize(value, serialize)

		TYPE_ARRAY:
			return value.map(serialize)

		TYPE_DICTIONARY:
			var result := {}
			for i: Variant in value:
				result[i] = serialize(value[i])
			return result

		TYPE_PACKED_BYTE_ARRAY:
			if bytes_as_base64:
				return {
					ObjectSerializer.type_field: bytes_to_base64_type,
					ObjectSerializer.args_field: Marshalls.raw_to_base64(value)
				}

	if _JSON_SERIALIZABLE_TYPES.has(typeof(value)):
		return value

	return {
		ObjectSerializer.type_field: type_string(typeof(value)),
		ObjectSerializer.args_field: JSON.from_native(value)["args"]
	}


## Deserialize dictionary [data] from [JSON.parse_string] into objects.
static func deserialize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			if value.has(ObjectSerializer.type_field):
				var type: String = value.get(ObjectSerializer.type_field)
				if bytes_as_base64 and type == bytes_to_base64_type:
					return Marshalls.base64_to_raw(value[ObjectSerializer.args_field])

				if type.begins_with(ObjectSerializer.object_type_prefix):
					var entry := ObjectSerializer._get_entry(type)
					if !entry:
						assert(false, "Could not find type (%s) in registry" % type)

					return entry.deserialize(value, deserialize)

				return JSON.to_native({"type": type, "args": value[ObjectSerializer.args_field]})

			var result := {}
			for i: Variant in value:
				result[i] = deserialize(value[i])
			return result

		TYPE_ARRAY:
			return value.map(deserialize)

	return value
