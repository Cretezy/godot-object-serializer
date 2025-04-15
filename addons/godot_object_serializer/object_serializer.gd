## Main godot-object-serializer class.
class_name ObjectSerializer


# TODO: Replace with UID
# Sub-serializers
const dictionary = preload("res://addons/godot_object_serializer/dictionary_object_serializer.gd")
const binary = preload("res://addons/godot_object_serializer/dictionary_object_serializer.gd")


## The field containing the type in serialized object values. Not recommended to change.
## This should be set to something unlikely to clash with keys in objects/dictionaries.
## Can be changed but must be done before any serialization/deserizalization.
static var type_field := "._type"
## The prefix for object types stored in [type_field]. Not recommended to change.
## This should be set to something unlikely to clash with built-in type names.
## Can be changed but must be done before any serialization/deserizalization.
static var object_type_prefix := "Object_"


static var _script_registry: Dictionary[String, ScriptRegistryEntry]


static func register_script(name: StringName, script: Script) -> void:
	var script_name := _get_script_name(script, name)
	assert(script_name, "Script must have name\n" + script.source_code)
	var entry := ScriptRegistryEntry.new()
	entry.script_type = script
	entry.type = object_type_prefix + script_name
	_script_registry[entry.type] = entry


static func _get_script_name(script: Script, name: StringName = "") -> StringName:
	if name:
		return name
	if script.resource_name:
		return script.resource_name
	if script.get_global_name():
		return script.get_global_name()
	return ""


static func _get_entry(name: StringName = "", script: Script = null) -> ScriptRegistryEntry:
	if name:
		var entry: ScriptRegistryEntry = _script_registry.get(name)
		if entry:
			return entry

	if script:
		for i: String in _script_registry:
			var entry: ScriptRegistryEntry = _script_registry.get(i)
			if entry:
				if script == entry.script_type:
					return entry

	return null


class ScriptRegistryEntry:
	var type: String
	var script_type: Script

	func serialize(value: Variant, next: Callable) -> Variant:
		var result := {
			ObjectSerializer.type_field: type
		}

		for property: Dictionary in value.get_property_list():
			if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				result[property.name] = next.call(value.get(property.name))

		return result


	func deserialize(value: Variant, next: Callable) -> Variant:
		var instance: Variant = script_type.new()

		for key: String in value:
			if key == ObjectSerializer.type_field:
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
	
