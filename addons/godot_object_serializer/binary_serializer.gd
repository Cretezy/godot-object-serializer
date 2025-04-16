## Serializer to be used with Godot's built-in binary serialization ([method var_to_bytes] and [method bytes_to_var]).
## This serializes objects but leaves built-in Godot types as-is.
class_name BinarySerializer


## Serialize [param data] to value which can be passed to [method var_to_bytes].
static func serialize_var(value: Variant) -> Variant:
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

			return object_entry.serialize(value, serialize_var)
		TYPE_ARRAY:
			return value.map(serialize_var)
		TYPE_DICTIONARY:
			var result := {}
			for i: Variant in value:
				result[i] = serialize_var(value[i])
			return result

	return value


## Serialize [param data] into bytes with [method BinaryObjectSerializer.serialize_var] and [method var_to_bytes].
static func serialize_bytes(value: Variant) -> PackedByteArray:
	return var_to_bytes(serialize_var(value))


## Deserialize [param data] from [method bytes_to_var] to value.
static func deserialize_var(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			if value.has(ObjectSerializer.type_field):
				var type: String = value.get(ObjectSerializer.type_field)
				if type.begins_with(ObjectSerializer.object_type_prefix):
					var entry := ObjectSerializer._get_entry(type)
					if !entry:
						assert(false, "Could not find type (%s) in registry" % type)

					return entry.deserialize(value, deserialize_var)

			var result := {}
			for i: Variant in value:
				result[i] = deserialize_var(value[i])
			return result
		TYPE_ARRAY:
			return value.map(deserialize_var)

	return value


## Deserialize bytes [param data] to value with [method bytes_to_var] and [method BinaryObjectSerializer.deserialize_var].
static func deserialize_bytes(value: PackedByteArray) -> Variant:
	return deserialize_var(bytes_to_var(value))
