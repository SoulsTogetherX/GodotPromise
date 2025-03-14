@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_custom_type(
		"GodotPromise",
		"RefCounted",
		preload("res://addons/GodotPromise/src/GodotPromise.gd"),
		preload("res://addons/GodotPromise/assets/GodotPromise.svg")
	)
	add_custom_type(
		"GodotPromiseEx",
		"RefCounted",
		preload("res://addons/GodotPromise/src/GodotPromiseEx.gd"),
		preload("res://addons/GodotPromise/assets/GodotPromiseEx.svg")
	)
func _exit_tree() -> void:
	remove_custom_type("GodotPromise")
	remove_custom_type("GodotPromiseEx")
