## Main godot-object-serializer class. Stores the script registry.
class_name ObjectSerializer

## The field containing the type in serialized object values. Not recommended to change.
##
## This should be set to something unlikely to clash with keys in objects/dictionaries.
##
## This can be changed, but must be configured before any serialization or deserialization.
static var type_field := "._type"

## The field containing the constructor arguments in serialized object values. Not recommended to change.
##
## This should be set to something unlikely to clash with keys in objects.
##
## This can be changed, but must be configured before any serialization or deserialization.
static var args_field := "._"

## The prefix for object types stored in [type_field]. Not recommended to change.
##
## This should be set to something unlikely to clash with built-in type names.
##
## This can be changed, but must be configured before any serialization or deserialization.
static var object_type_prefix := "Object_"

## Registry of object types
static var _script_registry: Dictionary[String, _ScriptRegistryEntry]


## Registers a script (an object type) to be serialized/deserialized. All custom types (including nested types) must be registered _before_ using this library.
## [param name] can be empty if script uses `class_name` (e.g `ObjectSerializer.register_script("", Data)`), but it's generally better to set the name.
static func register_script(name: StringName, script: Script) -> void:
	var script_name := _get_script_name(script, name)
	assert(script_name, "Script must have name\n" + script.source_code)
	var entry := _ScriptRegistryEntry.new()
	entry.script_type = script
	entry.type = object_type_prefix + script_name
	_script_registry[entry.type] = entry


## Registers multiple scripts (object types) to be serialized/deserialized from a dictionary.
## See [method ObjectSerializer.register_script]
static func register_scripts(scripts: Dictionary[String, Script]) -> void:
	for name in scripts:
		register_script(name, scripts[name])


static func _get_script_name(script: Script, name: StringName = "") -> StringName:
	if name:
		return name
	if script.resource_name:
		return script.resource_name
	if script.get_global_name():
		return script.get_global_name()
	return ""


static func _get_entry(name: StringName = "", script: Script = null) -> _ScriptRegistryEntry:
	if name:
		var entry: _ScriptRegistryEntry = _script_registry.get(name)
		if entry:
			return entry

	if script:
		for i: String in _script_registry:
			var entry: _ScriptRegistryEntry = _script_registry.get(i)
			if entry:
				if script == entry.script_type:
					return entry

	return null


class _ScriptRegistryEntry:
	var type: String
	var script_type: Script

	func serialize(value: Variant, next: Callable) -> Variant:
		if value.has_method("_serialize"):
			var result: Dictionary = value._serialize(next)
			result[ObjectSerializer.type_field] = type
			return result

		var result := {ObjectSerializer.type_field: type}

		for property: Dictionary in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				result[property.name] = next.call(value.get(property.name))

		if value.has_method("_get_constructor_args"):
			var args: Array = value._get_constructor_args()
			result[ObjectSerializer.args_field] = args

		return result

	func deserialize(value: Variant, next: Callable) -> Variant:
		if script_type.has_method("_deserialize"):
			return script_type._deserialize(value, next)

		var instance: Variant
		if value.has(ObjectSerializer.args_field):
			instance = script_type.new.callv(value[ObjectSerializer.args_field])
		else:
			instance = script_type.new()

		for key: String in value:
			if key == ObjectSerializer.type_field || key == ObjectSerializer.args_field:
				continue
			var key_value: Variant = next.call(value[key])
			match typeof(key_value):
				TYPE_DICTIONARY:
					instance[key].assign(key_value)
				TYPE_ARRAY:
					instance[key].assign(key_value)
				_:
					instance[key] = key_value

		return instance
