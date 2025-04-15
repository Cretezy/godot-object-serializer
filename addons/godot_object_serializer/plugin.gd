@tool
extends EditorPlugin

const AUTOLOAD_NAME = "ObjectSerializer"


func _enable_plugin():
	add_autoload_singleton(
		AUTOLOAD_NAME, "res://addons/godot_object_serializer/object_serializer.gd"
	)


func _disable_plugin():
	remove_autoload_singleton(AUTOLOAD_NAME)
