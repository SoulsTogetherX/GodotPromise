@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type(
		"GodotPromise",
		"RefCounted",
		preload("res://addons/GodotPromise/src/GodotPromise.gd"),
		preload("res://addons/GodotPromise/assets/GodotPromise.svg")
	)
func _exit_tree() -> void:
	remove_custom_type("GodotPromise")
