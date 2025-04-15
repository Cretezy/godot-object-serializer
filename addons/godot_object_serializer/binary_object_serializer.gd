## Serializer to be used with Godot's built-in binary serialization (var_to_bytes and bytes_to_var).
## This serializes objects but leaves built-in Godot types as-is.
class_name BinaryObjectSerializer


## Serialize [data] into dictionary which can be passed to [var_to_bytes].
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

	return value


## Deserialize dictionary [data] from [bytes_to_var] into objects.
static func deserialize(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			if value.has(ObjectSerializer.type_field):
				var type: String = value.get(ObjectSerializer.type_field)
				if type.begins_with(ObjectSerializer.object_type_prefix):
					var entry := ObjectSerializer._get_entry(type)
					if !entry:
						assert(false, "Could not find type (%s) in registry" % type)

					return entry.deserialize(value, deserialize)

			var result := {}
			for i: Variant in value:
				result[i] = deserialize(value[i])
			return result
		TYPE_ARRAY:
			return value.map(deserialize)

	return value
